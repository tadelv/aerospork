import AppKit
import Common

/// Per-element AX message timeout, in seconds.
///
/// The AX default is 6s. A single wedged app therefore blocked a refresh -- and every task parked
/// behind its registration -- for 6s, i.e. 120 debounce windows. `AXUIElementSetMessagingTimeout`
/// is per-object (only the system-wide element sets a process-wide default), so it is applied to
/// both the app element and every window element we hold on to.
///
/// 1s is chosen as ~100x a healthy AX round trip (single-digit ms even for slow Electron apps), so
/// it cannot fail a responsive app, while bounding a wedged one to 1s instead of 6s.
private let axMessagingTimeout: Float = 1.0

// Potential alternative implementation
// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0392-custom-actor-executors.md
// (only available since macOS 14)
final class MacApp: AbstractApp {
  /*conforms*/ let pid: Int32
  /*conforms*/ let bundleId: String?
  let nsApp: NSRunningApplication
  let isZoom: Bool
  private let axApp: ThreadGuardedValue<AXUIElement>
  private let appAxSubscriptions: ThreadGuardedValue<[AxSubscription]> // keep subscriptions in memory
  private let windows: ThreadGuardedValue<[UInt32: AxWindow]> = .init([:])
  /// AX window id -> the managed window it belongs to. See `tabGroups`.
  private let tabOwner: ThreadGuardedValue<[UInt32: UInt32]> = .init([:])
  /// The AX window id that represents a managed window right now. See `tabGroups`.
  private let tabSelected: ThreadGuardedValue<[UInt32: UInt32]> = .init([:])
  private var thread: Thread?
  private var setFrameJobs: [UInt32: RunLoopJob] = [:]
  @MainActor private static var focusJob: RunLoopJob? = nil

  /*conforms*/ var name: String? { nsApp.localizedName }
  /*conforms*/ var execPath: String? { nsApp.executableURL?.path }
  /*conforms*/ var bundlePath: String? { nsApp.bundleURL?.path }

  // todo think if it's possible to fold this global mutable state into the tree
  //      and make deinitialization automatic in deinit
  @MainActor static var allAppsMap: [pid_t: MacApp] = [:]
  /// Registrations currently in flight. Not private: the tests drive the park/unpark paths of
  /// `awaitRegistration` through it, without needing a real app.
  @MainActor static var wipPids: Set<pid_t> = []
  /// Callers parked waiting on an in-flight registration for a pid, resumed when it publishes
  /// into `allAppsMap`. Carries no payload: `MacApp` is not Sendable, so waiters re-read the map
  /// on the main actor after waking. Keyed by waiter id so a cancelled waiter can remove exactly
  /// its own continuation and nobody else's.
  @MainActor private static var registrationWaiters: [pid_t: [Int: CheckedContinuation<Void, Never>]] = [:]
  @MainActor private static var nextWaiterId = 0

  /// Negative cache for pids whose `bulkSubscribe` came back empty.
  ///
  /// `refreshAllAndGetAliveWindowIds` calls `getOrRegister` for every `.regular` running app on
  /// every refresh, and a failed registration leaves nothing behind in `allAppsMap` -- so an app
  /// we cannot subscribe to used to cost a fresh `Thread` + `AXUIElementCreateApplication` +
  /// `AXObserverCreate` on every single refresh, forever.
  ///
  /// Never-retrying would be wrong: an app that is still launching becomes subscribable a moment
  /// later. Hence backoff -- first retry after 1s (short enough that a window of a just-launched
  /// app is tiled before the user notices), doubling to a 30s ceiling for apps that simply have
  /// no usable AX interface. At the ceiling that is ~1 probe/30s instead of ~20/s under the 50ms
  /// refresh debounce.
  ///
  /// Internal (not private) so the prune regression test can seed it -- same deal as `wipPids`.
  @MainActor static var failedPids: [pid_t: (nextAttempt: Date, backoff: TimeInterval, launchDate: Date?)] = [:]
  private static let registrationRetryMinDelay: TimeInterval = 1
  private static let registrationRetryMaxDelay: TimeInterval = 30

  /// Park until the in-flight registration for `pid` completes, or until the calling Task is
  /// cancelled.
  ///
  /// Cancellation matters: `bulkSubscribe` talks to an app that may be wedged, and every refresh
  /// parks a `withThrowingTaskGroup` child here per app. Without unparking on cancel, a cancelled
  /// refresh Task stayed alive -- holding its entire child set -- until the AX timeout expired,
  /// so cancelled refreshes piled up and were released as a thundering herd.
  @MainActor static func awaitRegistration(of pid: pid_t) async {
    let id = nextWaiterId
    nextWaiterId &+= 1
    await withTaskCancellationHandler {
      await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
        registrationWaiters[pid, default: [:]][id] = cont
        // Two ways this park could never be woken. Both are handled right here rather than
        // by the fragile "there must be no suspension point between `wipPids.insert(pid)`
        // and this line" invariant the previous version relied on:
        //   1. the registration already published -- its waiter drain ran before our
        //      continuation existed. `wipPids` is cleared in that same drain, so
        //      "not in flight" is exactly "already published".
        //   2. cancellation landed before `onCancel` below was installed, so the handler
        //      already ran and found nothing to remove.
        // Resuming from inside the continuation body is legal; it returns without parking.
        if !wipPids.contains(pid) || Task.isCancelled {
          resumeRegistrationWaiter(pid, id)
        }
      }
    } onCancel: {
      // `onCancel` is non-isolated, so it has to hop. Both removal sites run on the main
      // actor and resume only what they removed, so the continuation resumes exactly once.
      Task { @MainActor in resumeRegistrationWaiter(pid, id) }
    }
  }

  @MainActor private static func resumeRegistrationWaiter(_ pid: pid_t, _ id: Int) {
    registrationWaiters[pid]?.removeValue(forKey: id)?.resume()
    if registrationWaiters[pid]?.isEmpty == true { registrationWaiters.removeValue(forKey: pid) }
  }

  private init(_ nsApp: NSRunningApplication, _ axApp: AXUIElement, _ axSubscriptions: [AxSubscription], _ thread: Thread) {
    self.nsApp = nsApp
    self.axApp = .init(axApp)
    self.isZoom = nsApp.bundleIdentifier == "us.zoom.xos"
    self.pid = nsApp.processIdentifier
    self.bundleId = nsApp.bundleIdentifier
    assert(!axSubscriptions.isEmpty)
    self.appAxSubscriptions = .init(axSubscriptions)
    self.thread = thread
  }

  @MainActor
  @discardableResult
  static func getOrRegister(_ nsApp: NSRunningApplication) async throws -> MacApp? {
    // Never manage our own windows.
    //
    // The Settings window and SwiftUI's MenuBarExtra panel are ordinary windows in our own process,
    // so they show up in our own AX window list. Laying one out sends an AX write whose target is
    // our own process, and AppKit serves that *in-process* -- on the app's AX thread rather than the
    // main thread -- where `-[NSWMWindowCoordinator performTransactionUsingBlock:]` asserts "Must
    // only be used from the main thread". SIGTRAP on the first layout pass that moves one of our own
    // windows (it does not need to be visible), leaving the socket file behind, which is why the CLI
    // then reports "Is AeroSpork.app running?" for an app that is simply gone.
    if nsApp.processIdentifier == ProcessInfo.processInfo.processIdentifier { return nil }
    // Don't perceive any of the lock screen windows as real windows
    // Otherwise, false positive ax notifications might trigger that lead to gcWindows
    if nsApp.bundleIdentifier == lockScreenAppBundleId { return nil }
    let pid = nsApp.processIdentifier

    if let existing = allAppsMap[pid] { return existing }
    try checkCancellation()
    // Someone else is already registering this pid -- park instead of polling for them.
    if wipPids.contains(pid) {
      await awaitRegistration(of: pid)
      try checkCancellation()
      return allAppsMap[pid]
    }
    if let failure = failedPids[pid] {
      if failure.launchDate != nsApp.launchDate {
        // pid reuse. Otherwise a brand new process would inherit the dead one's backoff
        // and stay invisible to us for up to 30s.
        failedPids.removeValue(forKey: pid)
      } else if Date.now < failure.nextAttempt {
        return nil
      }
    }
    let launchDate = nsApp.launchDate

    // This used to be a `while true` that slept 100ms per iteration waiting for the spawned
    // thread to publish into allAppsMap. Because the publish happens in a hopped
    // `Task { @MainActor }`, the first re-poll always lost the race, so registering a single
    // app cost 100ms minimum and 200ms typically. getNativeFocusedWindow() calls this at the
    // top of every session, which made it the largest single cost of a workspace switch --
    // far larger than the AX traffic. Now registration wakes its waiters directly.
    //
    // Keep this insert and the `awaitRegistration` below in the same synchronous run if you
    // can -- but correctness no longer depends on it: `awaitRegistration` re-checks `wipPids`
    // after installing its continuation and unparks itself if the publish already happened.
    wipPids.insert(pid)
    let thread = Thread {
      $axTaskLocalAppThreadToken.withValue(AxAppThreadToken(pid: pid, idForDebug: nsApp.idForDebug)) {
        let axApp = AXUIElementCreateApplication(nsApp.processIdentifier)
        _ = AXUIElementSetMessagingTimeout(axApp, axMessagingTimeout)
        let handlers: HandlerToNotifKeyMapping = [
          (refreshObs, [kAXWindowCreatedNotification, kAXFocusedWindowChangedNotification])
        ]
        let job = RunLoopJob()
        let subscriptions = (try? AxSubscription.bulkSubscribe(nsApp, axApp, job, handlers)) ?? []
        let isGood = !subscriptions.isEmpty
        let app = isGood ? MacApp(nsApp, axApp, subscriptions, Thread.current) : nil
        Task { @MainActor in
          allAppsMap[pid] = app // nil removes the key -- a failed registration publishes nothing
          if isGood {
            failedPids.removeValue(forKey: pid)
          } else {
            let backoff = failedPids[pid].map { min($0.backoff*2, registrationRetryMaxDelay) } ?? registrationRetryMinDelay
            failedPids[pid] = (nextAttempt: .now + backoff, backoff: backoff, launchDate: launchDate)
          }
          wipPids.remove(pid)
          for (id, _) in registrationWaiters[pid] ?? [:] { resumeRegistrationWaiter(pid, id) }
        }
        // Must come after the publish above: this parks the thread for its lifetime.
        if isGood {
          CFRunLoopRun()
        }
      }
    }
    thread.name = "AxAppThread \(nsApp.idForDebug)"
    thread.start()
    await awaitRegistration(of: pid)
    try checkCancellation()
    return allAppsMap[pid]
  }

  @MainActor
  func closeAndUnregisterAxWindow(_ windowId: UInt32) {
    cancelAndRemoveFrameJob(windowId)
    _ = withWindowAsync(windowId) { [windows] window, job in
      guard let closeButton = window.get(Ax.closeButtonAttr) else { return }
      guard let castedCloseButton = closeButton.cast else { return }
      if AXUIElementPerformAction(castedCloseButton, kAXPressAction as CFString) == .success {
        windows.threadGuarded.removeValue(forKey: windowId)
      }
    }
  }

  /// Cancel and drop the per-window geometry/native-state job for `windowId`.
  ///
  /// Called from `MacWindow.garbageCollect` -- the centralized window-lifecycle teardown -- so
  /// windows closed externally (not just through AeroSpork's own close command) stop
  /// accumulating `setFrameJobs` entries for the life of the app. WindowServer window IDs are
  /// unique within a session and never reused, so a cancelled job can never clobber a newer job
  /// for the same ID.
  ///
  /// Takes the map as `inout` so the regression test can exercise the churn semantics without a
  /// real `MacApp` (its init needs live AX subscriptions).
  @MainActor
  static func cancelAndRemoveFrameJob(_ windowId: UInt32, from jobs: inout [UInt32: RunLoopJob]) {
    jobs.removeValue(forKey: windowId)?.cancel()
  }

  @MainActor
  func cancelAndRemoveFrameJob(_ windowId: UInt32) {
    Self.cancelAndRemoveFrameJob(windowId, from: &setFrameJobs)
  }

  @MainActor
  func getAxSize(_ windowId: UInt32) async throws -> CGSize? {
    try await withWindow(windowId) { window, job in
      window.get(Ax.sizeAttr)
    }
  }

  // todo merge together with detectNewWindows
  @MainActor
  func getFocusedWindow() async throws -> Window? {
    let windowId = try await thread?.runInLoop { [nsApp, axApp, windows, tabOwner] job in
      let axWindow = try axApp.threadGuarded.get(Ax.focusedWindowAttr)
        .flatMap {
          guard let casted = $0.ax.cast else { return nil as AxWindow? }
          return try windows.threadGuarded.getOrRegisterAxWindow(windowId: $0.windowId, casted, nsApp, job)
        }
      // The focused AX window is a *tab* when the window has native tabs. Resolving it to the id
      // AeroSpork manages is what keeps switching tabs from looking like a window that closed and
      // another that opened -- the tree would drop one node, create another, and move focus.
      return axWindow.map { tabOwner.threadGuarded[$0.windowId] ?? $0.windowId }
    }
    guard let windowId else { return nil }
    return try await MacWindow.getOrRegister(windowId: windowId, macApp: self)
  }

  @MainActor func nativeFocus(_ windowId: UInt32) {
    // Declare the request BEFORE issuing it: the AX calls below run on the app's thread, and
    // `runSession` kicks off another refresh as soon as this returns. Without this, that refresh
    // can read a half-applied focus out of the app and adopt it. See `updateFocusCache`.
    expectNativeFocus(windowId)
    MacApp.focusJob?.cancel()
    MacApp.focusJob = withWindowAsync(windowId) { [nsApp] window, job in
      // Point the APP at this window before touching order or activation. `isMain` and
      // `kAXRaiseAction` only reorder windows -- neither updates `kAXFocusedWindowAttribute`,
      // which is exactly what `getNativeFocusedWindow` reads back. Without that write, focusing
      // a window of an app that also has windows on another workspace left the app still
      // reporting the old one, and the next refresh adopted that and undid the switch.
      setAxFocus(window)
      // Raise so that by the time we activate the app, the window is already on top
      AXUIElementPerformAction(window, kAXRaiseAction as CFString)
      nsApp.activate(options: .activateIgnoringOtherApps)
    }
  }

  func setAxFrame(_ windowId: UInt32, _ topLeft: CGPoint?, _ size: CGSize?) {
    setFrameJobs.removeValue(forKey: windowId)?.cancel()
    setFrameJobs[windowId] = withWindowAsync(windowId) { [axApp, windows, tabOwner] window, job in
      // Sync before the no-op check: the selected tab can already be at the target frame while the
      // rest of the group is not. See `spreadFrameToTabMembers`.
      spreadFrameToTabMembers(windowId, windows, tabOwner, topLeft, size)
      if isFrameSatisfied(window, topLeft, size) { return }
      disableAnimations(app: axApp.threadGuarded) {
        setFrame(window, topLeft, size)
      }
    }
  }

  @MainActor
  func setAxFrameBlocking(_ windowId: UInt32, _ topLeft: CGPoint?, _ size: CGSize?) async throws {
    setFrameJobs.removeValue(forKey: windowId)?.cancel()
    setFrameJobs[windowId] = nil
    try await withWindow(windowId) { [axApp, windows, tabOwner] window, job in
      spreadFrameToTabMembers(windowId, windows, tabOwner, topLeft, size)
      if isFrameSatisfied(window, topLeft, size) { return }
      disableAnimations(app: axApp.threadGuarded) {
        setFrame(window, topLeft, size)
      }
    }
  }

  func setAxSize(_ windowId: UInt32, _ size: CGSize) {
    setFrameJobs.removeValue(forKey: windowId)?.cancel()
    setFrameJobs[windowId] = withWindowAsync(windowId) { [axApp] window, job in
      disableAnimations(app: axApp.threadGuarded) {
        _ = window.set(Ax.sizeAttr, size)
      }
    }
  }

  func setAxTopLeftCorner(_ windowId: UInt32, _ point: CGPoint) {
    setFrameJobs.removeValue(forKey: windowId)?.cancel()
    setFrameJobs[windowId] = withWindowAsync(windowId) { [axApp, windows, tabOwner] window, job in
      spreadFrameToTabMembers(windowId, windows, tabOwner, point, nil)
      // Same no-op guard as setAxFrame. This one matters because hideInCorner calls it for
      // every window of every invisible workspace on every refresh -- previously an
      // unconditional AX position write per hidden window, forever.
      if isFrameSatisfied(window, point, nil) { return }
      disableAnimations(app: axApp.threadGuarded) {
        _ = window.set(Ax.topLeftCornerAttr, point)
      }
    }
  }

  @MainActor
  func getAxWindowsCount() async throws -> Int? {
    try await thread?.runInLoop { [axApp] job in
      axApp.threadGuarded.get(Ax.windowsAttr)?.count
    }
  }

  @MainActor
  func getAxTopLeftCorner(_ windowId: UInt32) async throws -> CGPoint? {
    try await withWindow(windowId) { window, job in
      window.get(Ax.topLeftCornerAttr)
    }
  }

  @MainActor
  func getAxRect(_ windowId: UInt32) async throws -> Rect? {
    try await withWindow(windowId) { window, job in
      guard let topLeftCorner = window.get(Ax.topLeftCornerAttr) else { return nil }
      guard let size = window.get(Ax.sizeAttr) else { return nil }
      return Rect(topLeftX: topLeftCorner.x, topLeftY: topLeftCorner.y, width: size.width, height: size.height)
    }
  }

  @MainActor
  func isWindowHeuristic(_ windowId: UInt32) async throws -> Bool {
    try await withWindow(windowId) { [axApp, bundleId] window, job in
      window.isWindowHeuristic(axApp: axApp.threadGuarded, appBundleId: bundleId)
    } == true
  }

  @MainActor
  func getAxUiElementWindowType(_ windowId: UInt32) async throws -> AxUiElementWindowType {
    try await withWindow(windowId) { [axApp, bundleId] window, job in
      window.getWindowType(axApp: axApp.threadGuarded, appBundleId: bundleId)
    } ?? .window
  }

  @MainActor
  func isDialogHeuristic(_ windowId: UInt32) async throws -> Bool {
    try await withWindow(windowId) { [nsApp] window, job in
      window.isDialogHeuristic(appBundleId: nsApp.bundleIdentifier)
    } == true
  }

  func setNativeFullscreen(_ windowId: UInt32, _ value: Bool) {
    setFrameJobs.removeValue(forKey: windowId)?.cancel()
    setFrameJobs[windowId] = withWindowAsync(windowId) { window, job in
      window.set(Ax.isFullscreenAttr, value)
    }
  }

  func setNativeMinimized(_ windowId: UInt32, _ value: Bool) {
    setFrameJobs.removeValue(forKey: windowId)?.cancel()
    setFrameJobs[windowId] = withWindowAsync(windowId) { window, job in
      window.set(Ax.minimizedAttr, value)
    }
  }

  @MainActor
  func dumpWindowAxInfo(windowId: UInt32) async throws -> [String: Json] {
    try await withWindow(windowId) { window, job in
      dumpAxRecursive(window, .window)
    } ?? [:]
  }

  @MainActor
  func dumpAppAxInfo() async throws -> [String: Json] {
    try await thread?.runInLoop { [axApp] job in
      dumpAxRecursive(axApp.threadGuarded, .app)
    } ?? [:]
  }

  @MainActor
  func getAxTitle(_ windowId: UInt32) async throws -> String? {
    try await withWindow(windowId) { window, job in
      window.get(Ax.titleAttr)
    }
  }

  @MainActor
  func isMacosNativeFullscreen(_ windowId: UInt32) async throws -> Bool? {
    try await withWindow(windowId) { window, job in
      window.get(Ax.isFullscreenAttr)
    }
  }

  @MainActor
  func isMacosNativeMinimized(_ windowId: UInt32) async throws -> Bool? {
    try await withWindow(windowId) { window, job in
      window.get(Ax.minimizedAttr)
    }
  }

  /// Both native-state flags in ONE hop to the app's thread.
  ///
  /// `normalizeLayoutReason` needs the pair for every window of every workspace on every refresh,
  /// and asking through `isMacosNativeFullscreen` + `isMacosNativeMinimized` costs two separate
  /// `runInLoop` round trips per window -- two suspensions, two continuations, twice the
  /// opportunity for the refresh to be cancelled mid-window and start over.
  ///
  /// The short-circuit is preserved exactly: `minimized` is not read at all when the window is
  /// fullscreen, because a fullscreen window cannot be minimized and the read is an IPC to a
  /// possibly-wedged app.
  @MainActor
  func macosNativeState(_ windowId: UInt32) async throws -> (fullscreen: Bool, minimized: Bool)? {
    try await withWindow(windowId) { window, job in
      readMacosNativeState(window)
    }
  }

  /// Drop failed-registration entries whose process is no longer running.
  ///
  /// A failed app never reaches `allAppsMap`, so the dead-app GC that iterates that map cannot
  /// clean this cache, and nothing else revisits a dead pid until macOS happens to reuse it.
  /// Pruning against the live process list once per refresh bounds the cache by real lifecycle
  /// instead of by pid reuse: a failed app that exits leaves at most one entry, for at most one
  /// refresh window (an in-flight retry may re-add it; the next refresh prunes it again).
  ///
  /// Live entries keep their backoff untouched -- a still-running failed app keeps probing at
  /// its exponential schedule instead of returning to per-refresh attempts.
  @MainActor
  static func pruneFailedPids(livePids: Set<pid_t>) {
    failedPids = failedPids.filter { livePids.contains($0.key) }
  }

  /// Refreshes every app and returns, per app, one entry per window the user can see -- plus the
  /// mapping from the raw AX window ids of a native tab group to the single id AeroSpork manages for
  /// it. See `tabGroups`.
  @MainActor
  static func refreshAllAndGetAliveWindowIds(frontmostAppBundleId: String?) async throws -> [MacApp: TabGroups] {
    // GC the negative registration cache as well as live apps. A failed app that exits would
    // otherwise stay cached until macOS reuses its pid.
    pruneFailedPids(livePids: Set(NSWorkspace.shared.runningApplications.map(\.processIdentifier)))
    for (_, app) in MacApp.allAppsMap { // gc dead apps
      try checkCancellation()
      if app.nsApp.isTerminated {
        app.destroy()
      }
    }
    // Read once per refresh, not once per app, and read before anything is garbage collected:
    // these only steer how a tab group is recognised. See `tabGroups`.
    let tabInput = TabGroupInputs(
      windowServerRects: windowServerRects(),
      // An id the last refresh managed. Preferring it keeps the group's tree node alive across tab
      // switches, new tabs and closed siblings.
      alreadyManaged: Set(MacWindow.allWindowsMap.keys),
      // Windows AeroSpork parked itself: same-sized windows of one app land on the same corner
      // rect on purpose, which is not the same thing as a tab group. See `tabGroups`.
      parkedInCorner: Set(MacWindow.allWindows.lazy.filter { $0.isHiddenInCorner }.map(\.windowId)),
      // A floating window's size is its own; see `tabGroups`.
      floatingWindowIds: Set(MacWindow.allWindows.lazy.filter { $0.isFloating }.map(\.windowId)),
      // Read before this refresh rebuilds it: a group must keep the id it had last time.
      previousOwner: MacWindow.tabOwners
    )
    return try await withThrowingTaskGroup(of: (pid_t, TabGroups).self, returning: [MacApp: TabGroups].self) { group in
      func refreshTheApp(_ nsApp: NSRunningApplication) {
        group.addTask { @Sendable @MainActor in
          guard let app = try await getOrRegister(nsApp) else { return (nsApp.processIdentifier, TabGroups()) }
          return (nsApp.processIdentifier, try await app.refreshAndGetAliveWindowIds(frontmostAppBundleId: frontmostAppBundleId, tabInput: tabInput))
        }
      }
      // Register new apps
      for nsApp in NSWorkspace.shared.runningApplications {
        try checkCancellation()
        if nsApp.activationPolicy == .regular {
          refreshTheApp(nsApp)
        }
      }
      for (_, app) in MacApp.allAppsMap {
        try checkCancellation()
        // "About this Mac" window, TouchID, and a lot of other utility windows
        // We don't monitor them actively as we do for regular apps, but if a window of one of those utility
        // apps got focused it will end up in allAppsMap
        if app.nsApp.activationPolicy != .regular {
          refreshTheApp(app.nsApp)
        }
      }
      var result: [MacApp: TabGroups] = [:]
      for try await (pid, groups) in group {
        if let app = allAppsMap[pid] {
          result[app] = groups
        }
      }
      return result
    }
  }

  @MainActor
  private func refreshAndGetAliveWindowIds(frontmostAppBundleId: String?, tabInput: TabGroupInputs) async throws -> TabGroups {
    if nsApp.isTerminated {
      destroy()
      return TabGroups()
    }
    guard let thread else { return TabGroups() }
    return try await thread.runInLoop { [nsApp, windows, axApp, tabOwner, tabSelected] (job) -> TabGroups in
      var result: [UInt32: AxWindow] = windows.threadGuarded
      // Second line of defence against lock screen. See the first line of defence: closedWindowsCache
      // Second and third lines of defence are technically needed only to avoid potential flickering
      if frontmostAppBundleId != lockScreenAppBundleId {
        result = try result.filter {
          try job.checkCancellation()
          return $0.value.ax.containingWindowId() != nil
        }
      }

      for (id, window) in axApp.threadGuarded.get(Ax.windowsAttr) ?? [] {
        try job.checkCancellation()
        try result.getOrRegisterAxWindow(windowId: id, window, nsApp, job)
      }

      windows.threadGuarded = result
      // One id per window the user sees. The tab maps are rebuilt from scratch every refresh, so a
      // closed tab drops out of them without any extra bookkeeping.
      let groups = tabGroups(of: result.mapValues { $0.ax }, in: tabInput)
      tabOwner.threadGuarded = groups.owner
      tabSelected.threadGuarded = groups.selected
      return groups
    }
  }

  @MainActor
  private func destroy() {
    MacApp.allAppsMap.removeValue(forKey: pid)
    for (_, job) in setFrameJobs {
      job.cancel()
    }
    setFrameJobs = [:]
    thread?.runInLoopAsync { [windows, appAxSubscriptions, axApp, tabOwner, tabSelected] job in
      appAxSubscriptions.destroy() // Destroy AX objects in reverse order of their creation
      windows.destroy()
      tabOwner.destroy()
      tabSelected.destroy()
      axApp.destroy()
      CFRunLoopStop(CFRunLoopGetCurrent())
    }
    thread = nil // Disallow all future job submissions
  }

  @MainActor
  // Both of these route an id AeroSpork manages to the AX window that represents it *now*: for a
  // window with native tabs that is the visible tab, because AppKit makes a window key when it is
  // focused, so writing to a background tab would switch the user's tab.
  private func withWindow<T>(_ windowId: UInt32, _ body: @Sendable @escaping (AXUIElement, RunLoopJob) throws -> T?) async throws -> T? {
    try await thread?.runInLoop { [windows, tabSelected] job in
      guard let window = windows.threadGuarded[tabSelected.threadGuarded[windowId] ?? windowId] else { return nil }
      return try body(window.ax, job)
    }
  }

  private func withWindowAsync(_ windowId: UInt32, _ body: @Sendable @escaping (AXUIElement, RunLoopJob) -> ()) -> RunLoopJob {
    thread?.runInLoopAsync { [windows, tabSelected] job in
      guard let window = windows.threadGuarded[tabSelected.threadGuarded[windowId] ?? windowId] else { return }
      body(window.ax, job)
    } ?? .cancelled
  }
}

private class AxWindow {
  let windowId: UInt32
  let ax: AXUIElement
  private let axSubscriptions: [AxSubscription] // keep subscriptions in memory

  private init(windowId: UInt32, _ ax: AXUIElement, _ axSubscriptions: [AxSubscription]) {
    self.windowId = windowId
    self.ax = ax
    assert(!axSubscriptions.isEmpty)
    self.axSubscriptions = axSubscriptions
  }

  static func new(windowId: UInt32, _ ax: AXUIElement, _ nsApp: NSRunningApplication, _ job: RunLoopJob) throws -> AxWindow? {
    let handlers: HandlerToNotifKeyMapping = [
      (refreshObs, [kAXUIElementDestroyedNotification, kAXWindowDeminiaturizedNotification, kAXWindowMiniaturizedNotification]),
      (movedObs, [kAXMovedNotification]),
      (resizedObs, [kAXResizedNotification])
    ]
    _ = AXUIElementSetMessagingTimeout(ax, axMessagingTimeout)
    let subscriptions = try AxSubscription.bulkSubscribe(nsApp, ax, job, handlers)
    return !subscriptions.isEmpty ? AxWindow(windowId: windowId, ax, subscriptions) : nil
  }
}

extension [UInt32: AxWindow] {
  @discardableResult
  fileprivate mutating func getOrRegisterAxWindow(windowId id: UInt32, _ axWindow: AXUIElement, _ nsApp: NSRunningApplication, _ job: RunLoopJob) throws -> AxWindow? {
    if let existing = self[id] { return existing }
    // Delay new window detection if mouse is down
    // It helps with apps that allow dragging their tabs out to create new windows
    // https://github.com/wbsmolen/aerospork/issues/1001
    if isLeftMouseButtonDown { return nil }

    if let window = try AxWindow.new(windowId: id, axWindow, nsApp, job) {
      self[id] = window
      return window
    } else {
      return nil
    }
  }
}

/// Everything tab-group detection needs from outside the app's AX thread.
///
/// The top level owns the tree -- which windows AeroSpork manages, which ones it parked off screen
/// -- while the AX thread only ever sees ids and rectangles. So it is handed that state as data.
struct TabGroupInputs: Sendable {
  /// Every window WindowServer composites, front to back. See `windowServerRects`.
  var windowServerRects: [(windowId: UInt32, rect: WindowServerRect, isDrawn: Bool)] = []
  /// Ids the previous refresh managed. See `tabGroups`.
  var alreadyManaged: Set<UInt32> = []
  /// Ids AeroSpork parked in a corner because their workspace is hidden. See `tabGroups`.
  var parkedInCorner: Set<UInt32> = []
  /// Ids bound directly to their workspace instead of to a container. See `tabGroups`.
  var floatingWindowIds: Set<UInt32> = []
  /// The previous refresh's tab id -> managed id mapping. See `tabGroups`.
  var previousOwner: [UInt32: UInt32] = [:]
}

/// A window rectangle exactly as WindowServer reports it.
///
/// Only ever compared for equality, so the coordinate space (Quartz, top-left origin) never has to
/// be converted. It is not `CGRect`: that is not `Hashable` before macOS 15, and this app supports
/// macOS 13.
struct WindowServerRect: Hashable {
  var x: CGFloat
  var y: CGFloat
  var width: CGFloat
  var height: CGFloat

  init(_ rect: CGRect) {
    x = rect.minX
    y = rect.minY
    width = rect.width
    height = rect.height
  }
}

/// The AX window ids AeroSpork manages: one per window the user can see. See `tabGroups`.
struct TabGroups {
  var managed: [UInt32] = []
  /// Tab -> the managed window it belongs to. Absent for a window that is not a tab.
  var owner: [UInt32: UInt32] = [:]
  /// Managed window -> the AX window id that represents it right now.
  var selected: [UInt32: UInt32] = [:]
}

/// Every window WindowServer composites, front to back.
///
/// "Which AX windows does the user see in one place" is geometry, and WindowServer is the authority
/// on it: one query, against two AX round trips per window to read frames. It also answers two
/// questions AX cannot: whether a window is *drawn* at all -- every tab of a *native* tab group
/// except the selected one is not composited -- and, by order, which of several windows is in front.
func windowServerRects() -> [(windowId: UInt32, rect: WindowServerRect, isDrawn: Bool)] {
  let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] ?? []
  return list.compactMap { info in
    guard let windowId = (info[kCGWindowNumber as String] as? Int).flatMap({ UInt32(exactly: $0) }),
          let bounds = info[kCGWindowBounds as String] as? [String: CGFloat],
          let x = bounds["X"], let y = bounds["Y"], let width = bounds["Width"], let height = bounds["Height"],
          // A window WindowServer reports without a real rect shares that non-rect with every other
          // such window, which would read as "all in one place" and merge unrelated windows.
          width > 0, height > 0
    else { return nil }
    return (
      windowId,
      WindowServerRect(CGRect(x: x, y: y, width: width, height: height)),
      (info[kCGWindowIsOnscreen as String] as? Bool) == true
    )
  }
}

/// Collapse the AX windows that are really one window with native tabs.
///
/// macOS reports a window with native tabs as one AX window per tab. Every tab carries the group's
/// frame, so they are indistinguishable from N windows stacked exactly on top of each other, and
/// only the selected one is visible. Managing them all lays a window out against itself: the tabs
/// fight over one rectangle, and the window the user is looking at ends up the size of a single tile
/// instead of the size of its workspace.
///
/// A window may also match a *nearly* identical rectangle instead of an exactly identical one, but
/// only when either side is not drawn -- the signature of a *native* tab group, where just the
/// selected tab is composited -- or when both are floating, since a floating window's size belongs
/// to the window and not to the layout, so a duplicate node left behind by this very bug can carry a
/// slightly different frame than its twin. Two *drawn*, non-floating windows get no such allowance:
/// a container lays its children out itself and an accordion deliberately overlaps them, so nearly
/// identical tiled rectangles really are two windows.
///
/// So AX windows of one app at an identical WindowServer rectangle are one window -- unless
///   - they are not all ordinary windows. A panel is *placed* exactly over its own window on
///     purpose (`AXDialog` and friends), and that is not a tab; or
///   - more than one of them is a window AeroSpork itself parked in a corner. `hideInCorner` gives
///     same-sized hidden windows of one app the very same rect, and merging those would drop a
///     window out of the layout.
///
/// Rectangles are read at the START of a refresh, but frames are written at the END of it, so the
/// members of a group legitimately disagree for exactly one refresh: moving a workspace to another
/// monitor lays the visible tab out at its new frame while its siblings are still where the old one
/// left them, and a screen wake reports them wherever they were. Geometry alone therefore takes such
/// a group apart, and nothing puts it back -- a window that has become a node of its own is no
/// longer a tab, so the next refresh cannot tell it ever was one. What survives that refresh is the
/// membership the previous refresh already knew, which is what `retainingKnownTabGroups` reunites
/// on.
///
/// Known limit: creating or closing tabs faster than a refresh can observe them can leave a tab as
/// its own node -- it is recognised by a rectangle it shares with the group, and a burst of tab
/// churn moves the windows between refreshes. The next tab event puts them back on one rectangle.
///
/// The managed id outlives the tab it was taken from. A tree node cannot change the `windowId` it
/// was created with, so if closing a tab made the group adopt a different id, every layout would
/// destroy and re-create the node -- which is a window that jumps to another tile and its workspace
/// re-flowing around it, the very symptom this grouping exists to remove. So a group keeps the id
/// the previous refresh managed (that is how a *closed* tab's id survives: the surviving tabs still
/// point at it, and AX reads and writes reach the drawn one through `selected`). Only a brand new
/// group picks a member: the tab furthest from the front, since `Cmd+W` closes the visible one.
/// What AX reads and writes target is the opposite end -- the tab that is drawn, i.e. the one the
/// user is looking at.
func tabGroups(of windows: [UInt32: any AxUiElementMock], in inputs: TabGroupInputs) -> TabGroups {
  var drawn: [UInt32: Bool] = [:]
  var buckets: [[UInt32]] = []
  var bucketRects: [WindowServerRect] = []
  for (windowId, rect, isDrawn) in inputs.windowServerRects where windows[windowId] != nil {
    drawn[windowId] = isDrawn
    if let index = bucketRects.firstIndex(of: rect) {
      buckets[index].append(windowId) // front to back within the bucket
      continue
    }
    // See the doc comment: an undrawn window or a floating window may match a nearly identical rect.
    let allowsLooseMatch = { (index: Int) -> Bool in
      if isDrawn != true || buckets[index].contains(where: { drawn[$0] != true }) { return true }
      return inputs.floatingWindowIds.contains(windowId) && buckets[index].allSatisfy { inputs.floatingWindowIds.contains($0) }
    }
    if let index = bucketRects.firstIndex(where: { isNearlyTheSameRect($0, rect) }), allowsLooseMatch(index) {
      buckets[index].append(windowId)
      continue
    }
    buckets.append([windowId])
    bucketRects.append(rect)
  }
  // Geometry finds a group, membership keeps it. See `retainingKnownTabGroups`.
  buckets = retainingKnownTabGroups(buckets, drawn, inputs.previousOwner)
  var result = TabGroups()
  var tabs: Set<UInt32> = []
  for tabsInGroup in buckets where tabsInGroup.count > 1 {
    if tabsInGroup.count(where: { inputs.parkedInCorner.contains($0) }) > 1 { continue }
    guard tabsInGroup.allSatisfy({ windows[$0]?.get(Ax.subroleAttr) == kAXStandardWindowSubrole }) else { continue }
    let managed = tabsInGroup.lazy.compactMap { inputs.previousOwner[$0] }.first
      ?? tabsInGroup.first { inputs.alreadyManaged.contains($0) } // a duplicate node: keep the node that exists
      ?? tabsInGroup.last.orDie()
    if !inputs.alreadyManaged.contains(managed) { // a group is logged once, when it is first recognised
      debugLog("TAB GROUP: collapsed \(tabsInGroup.count) AX windows into \(managed); visible tab \(tabsInGroup.first.orDie())")
    }
    tabs.formUnion(tabsInGroup)
    result.managed.append(managed)
    // AX reads and writes follow the tab the user is looking at: the one WindowServer draws, else
    // the one in front.
    result.selected[managed] = tabsInGroup.first(where: { drawn[$0] == true }) ?? tabsInGroup.first.orDie()
    for id in tabsInGroup { result.owner[id] = managed }
  }
  for id in windows.keys where !tabs.contains(id) {
    result.managed.append(id)
    result.selected[id] = id
  }
  return result
}

/// Reunites the buckets of a group the previous refresh already recognised, whatever their
/// rectangles say now. See `tabGroups` for why geometry alone cannot hold a group together.
///
/// The merge key is the managed id the previous refresh assigned, so this can only put back a group
/// that existed -- two different windows cannot be merged into one, however they are placed.
/// The case it must not undo is a tab the user dragged out into a window of its own: that window is
/// drawn at a rectangle of its own, and it is meant to have one. So only a bucket with no drawn
/// member is reunited with a drawn one.
///
/// Takes the geometric buckets, each in WindowServer's front-to-back order.
private func retainingKnownTabGroups(
  _ buckets: [[UInt32]],
  _ drawn: [UInt32: Bool],
  _ previousOwner: [UInt32: UInt32]
) -> [[UInt32]] {
  var groupOfOwner: [UInt32: Int] = [:]
  var groups: [[UInt32]] = []
  var groupIsDrawn: [Bool] = []
  for bucket in buckets {
    let owners = bucket.compactMap { previousOwner[$0] }
    let isDrawn = bucket.contains { drawn[$0] == true }
    if let index = owners.lazy.compactMap({ groupOfOwner[$0] }).first(where: { !(isDrawn && groupIsDrawn[$0]) }) {
      groups[index] += bucket
      groupIsDrawn[index] = groupIsDrawn[index] || isDrawn
      for owner in owners { groupOfOwner[owner] = index }
    } else {
      groups.append(bucket)
      groupIsDrawn.append(isDrawn)
      for owner in owners { groupOfOwner[owner] = groups.count - 1 }
    }
  }
  return groups
}

/// True when two rectangles cover nearly the same area -- within 10% of the smaller one. See
/// `tabGroups` for when that is allowed to mean "the same window".
func isNearlyTheSameRect(_ a: WindowServerRect, _ b: WindowServerRect) -> Bool {
  let overlapWidth = min(a.x + a.width, b.x + b.width) - max(a.x, b.x)
  let overlapHeight = min(a.y + a.height, b.y + b.height) - max(a.y, b.y)
  guard overlapWidth > 0, overlapHeight > 0 else { return false }
  return overlapWidth*overlapHeight >= min(a.width*a.height, b.width*b.height)*0.9
}

/// Writes the frame to the rest of a window's native tabs. See `tabGroups`.
///
/// Without this the very next layout pass takes the group apart again: the tile goes to the selected
/// tab alone, the other tabs keep the frames they had, and the next refresh sees windows that no
/// longer share a rectangle -- which is one tree node per tab, the bug this whole change fixes. It is
/// also what stops switching tabs from moving the window: every tab already holds the group's frame.
/// Call on the app's AX thread.
private func spreadFrameToTabMembers(
  _ owner: UInt32,
  _ windows: ThreadGuardedValue<[UInt32: AxWindow]>,
  _ tabOwner: ThreadGuardedValue<[UInt32: UInt32]>,
  _ topLeft: CGPoint?,
  _ size: CGSize?
) {
  for (id, member) in windows.threadGuarded where id != owner && tabOwner.threadGuarded[id] == owner {
    if isFrameSatisfied(member.ax, topLeft, size) { continue }
    setFrame(member.ax, topLeft, size)
  }
}

/// No-op guard: true when the window is already at the target frame, so no AX write is needed.
///
/// AX position/size WRITES are what cost us over DisplayLink/USB (each forces a framebuffer
/// repaint), and layout re-issues them on every refresh even when nothing moved. The reads here hit
/// the app's AX tree (not the display), so they're cheap over USB — and comparing against the
/// window's ACTUAL frame, rather than a cached intended rect, still corrects windows the app or OS
/// moved on their own.
///
/// Callers must check this *before* entering `disableAnimations`: that helper costs a read plus two
/// writes on the app element, so paying it for a frame we then skip defeats the point of the guard.
///
/// Takes `some AxUiElementMock` rather than `AXUIElement` purely so the tests can drive it against
/// an app that ignores, clamps or times out its writes. Every caller passes a concrete
/// `AXUIElement`, so the generic specializes to exactly the previous code.
func isFrameSatisfied(_ window: some AxUiElementMock, _ topLeft: CGPoint?, _ size: CGSize?) -> Bool {
  let tolerance = 1.0
  // Bail on the first disagreement. Each `get` is a cross-thread AX round trip, and the two used
  // to be evaluated unconditionally before being `&&`ed -- so every window that actually needed
  // moving (i.e. every window on the workspace you just switched to) paid a position read whose
  // answer could not change the outcome. See AxWriteTest.testGuardStopsReadingAtFirstDisagreement.
  if let size {
    guard let actual = window.get(Ax.sizeAttr),
          abs(actual.width - size.width) < tolerance, abs(actual.height - size.height) < tolerance
    else { return false }
  }
  if let topLeft {
    guard let actual = window.get(Ax.topLeftCornerAttr),
          abs(actual.x - topLeft.x) < tolerance, abs(actual.y - topLeft.y) < tolerance
    else { return false }
  }
  return true
}

/// The AX writes that hand focus to a window. Extracted from `MacApp.nativeFocus` so the sequence is
/// assertable -- the raise action and `nsApp.activate` around it need a real app thread.
///
/// `kAXFocusedAttribute` first, and it is the load-bearing one: it is what
/// `kAXFocusedWindowAttribute` reports back, which is what `getNativeFocusedWindow` reads. `isMain`
/// only changes which window the app considers primary for ordering.
/// The two AX reads behind `macosNativeState`, over the mockable element seam.
///
/// Extracted so the *read pattern* is assertable: that both flags come from one traversal, and that
/// a fullscreen window is never asked whether it is minimized.
func readMacosNativeState(_ window: some AxUiElementMock) -> (fullscreen: Bool, minimized: Bool) {
  let fullscreen = window.get(Ax.isFullscreenAttr) == true
  // Short-circuit: a fullscreen window is never minimized, and this read is an IPC.
  return (fullscreen, fullscreen ? false : window.get(Ax.minimizedAttr) == true)
}

func setAxFocus(_ window: some AxUiElementMock) {
  window.set(Ax.isFocused, true)
  window.set(Ax.isMainAttr, true)
}

func setFrame(_ window: some AxUiElementMock, _ topLeft: CGPoint?, _ size: CGSize?) {
  // Set size and then the position. The order is important https://github.com/wbsmolen/aerospork/issues/143
  //                                                        https://github.com/wbsmolen/aerospork/issues/335
  if let size { window.set(Ax.sizeAttr, size) }
  if let topLeft { window.set(Ax.topLeftCornerAttr, topLeft) } else { return }
  if let size { window.set(Ax.sizeAttr, size) }
}

// Some undocumented magic
// References: https://github.com/koekeishiya/yabai/commit/3fe4c77b001e1a4f613c26f01ea68c0f09327f3a
//             https://github.com/rxhanson/Rectangle/pull/285
func disableAnimations<T>(app: some AxUiElementMock, _ body: () -> T) -> T {
  let wasEnabled = app.get(Ax.enhancedUserInterfaceAttr) == true
  if wasEnabled {
    app.set(Ax.enhancedUserInterfaceAttr, false)
  }
  defer {
    if wasEnabled {
      app.set(Ax.enhancedUserInterfaceAttr, true)
    }
  }
  return body()
}
