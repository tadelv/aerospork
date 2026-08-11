@testable import AppBundle
import Common
import XCTest

/// Which workspace a monitor shows when nothing has been put on it.
///
/// The rule that matters: it must be a workspace the user can reach from the keyboard. The invent-a-
/// name fallback counts up from 1 and skips every bound name, so a config binding `1-9` produced
/// `10` -- a workspace with no keybinding, sitting on a monitor in front of the user.
///
/// Scope: these cover the *fresh pick*. `getStubWorkspace` first tries the monitor's previously
/// visible workspace, then any existing workspace whose windows already belong to this monitor --
/// deliberately including occupied ones, since showing a monitor its own windows back is the point.
/// Only when neither applies does the choice below happen.
@MainActor
final class StubWorkspaceTest: XCTestCase {
  override func setUp() async throws { setUpWorkspacesForTests() }

  override func tearDown() async throws {
    testMonitors = [defaultTestMonitor]
    config.workspaceToMonitorForceAssignment = [:]
    // Hand back exactly the state `setUpWorkspacesForTests` assumes. The workspace-to-screen map
    // is keyed by screen POINT and nothing in setUp clears it, so a workspace left visible on a
    // fake second monitor stays "visible" -- and the next test's setUp cannot displace it,
    // because `setFocus` early-returns when the frozen focus already names its target.
    gcMonitors() // rebuild the map for the restored single-monitor world
    _ = mainMonitor.setActiveWorkspace(focus.workspace)
    Workspace.garbageCollectUnusedWorkspaces()
    try await super.tearDown()
  }

  func testAnIdleMonitorGetsTheLowestWorkspaceTheUserBound() {
    config.preservedWorkspaceNames = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
    assertEquals(getStubWorkspace(for: mainMonitor).name, "1")
  }

  /// Logical, not lexicographic: "2" must beat "10", and digits must beat letters.
  func testBoundNamesAreOrderedLogically() {
    config.preservedWorkspaceNames = ["A", "10", "2"]
    assertEquals(getStubWorkspace(for: mainMonitor).name, "2")
  }

  /// The reported symptom, stated directly: on the real config the two idle monitors read `10`
  /// and `11`, neither of which any binding could reach.
  func testTheChosenWorkspaceIsAlwaysOneTheUserCanReach() {
    let bound = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C"]
    config.preservedWorkspaceNames = bound
    let stub = getStubWorkspace(for: mainMonitor)
    XCTAssertTrue(bound.contains(stub.name), "idle monitor got '\(stub.name)', which has no keybinding")
  }

  /// With nothing bound there is no user intent to honour, so inventing a name is correct --
  /// and it must still be an empty one.
  func testWithNoBoundWorkspacesItStillInventsAnEmptyOne() {
    config.preservedWorkspaceNames = []
    let stub = getStubWorkspace(for: mainMonitor)
    XCTAssertFalse(stub.name.isEmpty)
    XCTAssertTrue(stub.isEffectivelyEmpty)
  }

  // MARK: - Cold start with monitor force assignments

  /// The reported symptom: a config whose workspaces `1..9` are all force-assigned to monitors
  /// used to reject every bound candidate (each had a force assignment) and invent `10` on cold
  /// start. A workspace pinned to the monitor being initialized is the best candidate there is.
  func testAssignedConfiguredWorkspaceIsSelected() {
    config.preservedWorkspaceNames = (1...9).map(String.init)
    config.workspaceToMonitorForceAssignment = ["1": [.main]]
    assertEquals(getStubWorkspace(for: mainMonitor).name, "1")
  }

  /// Workspace `1` belongs to the left monitor and `2` to the right: each monitor must get its
  /// own, not the other's -- and not an invented name either.
  func testAssignmentToAnotherMonitorIsRespected() {
    testMonitors = [panel(id: 1, x: 0), panel(id: 2, x: 1920)]
    config.preservedWorkspaceNames = ["1", "2"]
    config.workspaceToMonitorForceAssignment = [
      "1": [.sequenceNumber(1)],
      "2": [.sequenceNumber(2)]
    ]
    let left = sortedMonitors[0]
    let right = sortedMonitors[1]
    assertEquals(getStubWorkspace(for: left).name, "1")
    assertEquals(getStubWorkspace(for: right).name, "2")
  }

  /// Priority, not name order: the unassigned `1` sorts first, but the explicitly assigned `2`
  /// is what the monitor is supposed to show.
  func testAssignedWorkspaceWinsOverUnassignedCandidate() {
    config.preservedWorkspaceNames = ["1", "2"]
    config.workspaceToMonitorForceAssignment = ["2": [.main]]
    assertEquals(getStubWorkspace(for: mainMonitor).name, "2")
  }

  /// The full configured set `1..9`, every one with a valid monitor assignment: initializing
  /// both monitors must never materialize a workspace `10`.
  ///
  /// The fake monitors sit right of the origin so the focus workspace `setUpWorkspacesForTests`
  /// parked at (0,0) does not match any screen being initialized -- a real cold start begins
  /// with an empty registry, and this is the closest headless equivalent.
  func testMonitorsAreInitializedWithoutInventingAWorkspace() {
    testMonitors = [panel(id: 1, x: 1920), panel(id: 2, x: 3840)]
    config.preservedWorkspaceNames = (1...9).map(String.init)
    config.workspaceToMonitorForceAssignment = (1...9).reduce(into: [:]) { dict, n in
      dict[String(n)] = [.sequenceNumber(n <= 5 ? 1 : 2)]
    }
    resetWorkspaceToScreenStateForTests() // a real cold start shows nothing yet

    // The cold-start path: reading `activeWorkspace` for every monitor runs
    // `rearrangeWorkspacesOnMonitors`, which picks a stub per screen.
    let active = sortedMonitors.map(\.activeWorkspace)

    assertEquals(active[0].name, "1")
    assertEquals(active[1].name, "6")
    XCTAssertFalse(
      Workspace.all.contains { $0.name == "10" },
      "cold start invented workspace '10': \(Workspace.all.map(\.name))"
    )
  }

  /// An ordinary unmatched startup window lands on the visible configured workspace, not on a
  /// freshly invented one. Mirrors the decision `MacWindow.getOrRegister` makes when the
  /// workspace memory has no entry: `(rect?.center.monitorApproximation ?? mainMonitor).activeWorkspace`.
  func testStartupWindowIsAdoptedByTheVisibleConfiguredWorkspace() {
    testMonitors = [panel(id: 1, x: 1920), panel(id: 2, x: 3840)]
    config.preservedWorkspaceNames = (1...9).map(String.init)
    config.workspaceToMonitorForceAssignment = (1...9).reduce(into: [:]) { dict, n in
      dict[String(n)] = [.sequenceNumber(n <= 5 ? 1 : 2)]
    }
    resetWorkspaceToScreenStateForTests() // a real cold start shows nothing yet

    let left = sortedMonitors[0]
    let leftWorkspace = left.activeWorkspace
    assertEquals(leftWorkspace.name, "1")

    // A startup window whose AX rect sits on the left monitor.
    let rect = Rect(topLeftX: 2000, topLeftY: 100, width: 800, height: 600)
    let adoptedWorkspace = (rect.center.monitorApproximation ?? mainMonitor).activeWorkspace
    assertEquals(adoptedWorkspace.name, "1")
    XCTAssertTrue(adoptedWorkspace === leftWorkspace)

    // `.window` AX windows attach to that workspace's tiling container.
    let window = TestWindow.new(id: 7001, parent: adoptedWorkspace.rootTilingContainer)
    XCTAssertTrue(adoptedWorkspace.rootTilingContainer.children.contains(window))
    assertEquals(window.nodeWorkspace, adoptedWorkspace)
  }

  // MARK: - Helpers

  private func panel(id: Int, x: CGFloat) -> MonitorImpl {
    let rect = Rect(topLeftX: x, topLeftY: 0, width: 1920, height: 1080)
    return MonitorImpl(
      monitorAppKitNsScreenScreensId: id,
      name: "Display \(id)",
      rect: rect,
      visibleRect: rect
    )
  }
}
