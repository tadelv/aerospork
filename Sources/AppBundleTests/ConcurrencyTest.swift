@testable import AppBundle
import Common
import XCTest

/// A window whose macOS-native state answers are scripted, so a test can make the answer change
/// between the prefetch pass and the mutation pass of `normalizeLayoutReason`.
/// The last element of a script is sticky (repeats forever).
final class ScriptedWindow: Window {
  private var fullscreenAnswers: [Bool]
  private var minimizedAnswers: [Bool]

  @MainActor
  init(id: UInt32, parent: NonLeafTreeNodeObject, fullscreen: [Bool] = [false], minimized: [Bool] = [false]) {
    self.fullscreenAnswers = fullscreen
    self.minimizedAnswers = minimized
    super.init(id: id, TestApp.shared, lastFloatingSize: nil, parent: parent, adaptiveWeight: 1, index: INDEX_BIND_LAST)
  }

  private func next(_ answers: inout [Bool]) -> Bool { answers.count > 1 ? answers.removeFirst() : answers[0] }

  @MainActor override var isMacosFullscreen: Bool { get async throws { next(&fullscreenAnswers) } }
  @MainActor override var isMacosMinimized: Bool { get async throws { next(&minimizedAnswers) } }
}

@MainActor
final class ConcurrencyNormalizeLayoutReasonTest: XCTestCase {
  override func setUp() async throws {
    setUpWorkspacesForTests()
    // ScriptedWindow is not a MacWindow, so `macAppUnsafe` would trap. The hidden-app branch is
    // not what these tests are about.
    config.automaticallyUnhideMacosHiddenApps = true
  }

  /// The prefetch says "fullscreen", the window leaves fullscreen before the mutation loop reaches
  /// it. Without the re-read, the window is bound into macOsNativeFullscreenWindowsContainer on
  /// the stale answer -- and nothing in this pass puts it back.
  func testStaleSnapshotDoesNotBindAWindowThatLeftFullscreen() async throws {
    let root = Workspace.get(byName: name).rootTilingContainer
    let window = ScriptedWindow(id: 1, parent: root, fullscreen: [true, false])

    try await normalizeLayoutReason()

    assertTrue(window.parent === root)
    assertEquals(window.layoutReason, .standard)
  }

  /// A window that really is fullscreen still gets moved -- the re-read must not break the
  /// feature it guards.
  func testGenuinelyFullscreenWindowIsStillMoved() async throws {
    let workspace = Workspace.get(byName: name)
    let window = ScriptedWindow(id: 2, parent: workspace.rootTilingContainer, fullscreen: [true])

    try await normalizeLayoutReason()

    assertTrue(window.parent === workspace.macOsNativeFullscreenWindowsContainer)
  }

  /// The `.standard` branch is fully synchronous, so without a per-window cancellation check a
  /// cancelled refresh rebinds the whole tree instead of stopping.
  func testCancelledRefreshDoesNotMutateTheTree() async throws {
    let root = Workspace.get(byName: name).rootTilingContainer
    let window = ScriptedWindow(id: 3, parent: root, fullscreen: [true])

    // We are on the main actor and do not suspend before cancel(), so the task starts cancelled.
    let task = Task { @MainActor in try await normalizeLayoutReason() }
    task.cancel()

    do {
      try await task.value
      XCTFail("normalizeLayoutReason must stop on cancellation")
    } catch is CancellationError {}
    assertTrue(window.parent === root)
  }
}

@MainActor
final class ConcurrencyMacAppRegistrationTest: XCTestCase {
  /// A pid that is not in `wipPids` is, by construction, a pid whose registration already
  /// published and already drained its waiters. Parking on it would hang forever -- which is
  /// exactly what a future suspension point between `wipPids.insert(pid)` and the continuation
  /// install would cause.
  func testAwaitRegistrationDoesNotHangWhenRegistrationAlreadyPublished() async {
    let returned = expectation(description: "awaitRegistration returned")
    Task { @MainActor in
      await MacApp.awaitRegistration(of: 999999) // never in flight
      returned.fulfill()
    }
    await fulfillment(of: [returned], timeout: 2)
  }

  /// A waiter parked on a genuinely in-flight registration must unpark when its Task is
  /// cancelled, instead of holding the whole refresh task group until the AX timeout expires.
  func testAwaitRegistrationUnparksOnCancellation() async throws {
    let pid: pid_t = 999998
    MacApp.wipPids.insert(pid)
    defer { MacApp.wipPids.remove(pid) }

    let unparked = expectation(description: "awaitRegistration unparked")
    let parked = Task { @MainActor in
      await MacApp.awaitRegistration(of: pid)
      unparked.fulfill()
    }
    try await Task.sleep(for: .milliseconds(50)) // let it actually park
    parked.cancel()
    await fulfillment(of: [unparked], timeout: 2)
  }
}

@MainActor
final class ConcurrencyFocusCallbacksTest: XCTestCase {
  override func setUp() async throws { setUpWorkspacesForTests() }

  /// Locks in what terminates focus-callback recursion now that the (dead) recursion flag is
  /// gone: `_lastKnownFocus` is updated before any callback runs, so re-entering with unchanged
  /// focus is a no-op.
  func testReentryWithUnchangedFocusIsANoOp() {
    let root = Workspace.get(byName: name).rootTilingContainer
    let window1 = TestWindow.new(id: 101, parent: root)
    let window2 = TestWindow.new(id: 102, parent: root)

    assertTrue(window1.focusWindow())
    checkOnFocusChangedCallbacks()
    assertTrue(window2.focusWindow())
    checkOnFocusChangedCallbacks()

    let prevFocusAfterChange = _prevFocus
    assertEquals(prevFocusAfterChange?.windowId, 101)
    checkOnFocusChangedCallbacks() // re-entry, focus unchanged
    assertEquals(_prevFocus, prevFocusAfterChange)
  }
}
