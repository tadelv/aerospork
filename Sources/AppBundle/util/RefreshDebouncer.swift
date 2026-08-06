import AppKit
import Common

/// Coalesces bursts of accessibility events into a single refresh after a short fixed delay.
/// A window manager sees rapid-fire AX notifications (app activate, window move, space change);
/// debouncing at 50ms collapses them so we lay out once instead of per-event.
///
/// Two-tier model (issue #1): the debounce delay only gates the START of work. Once a refresh is
/// running, ordinary events never cancel it -- they mark the coordinator dirty, and the running
/// refresh runs exactly one follow-up with the latest event when it finishes. That closes the
/// starvation window where events slower than the 50ms debounce but faster than a refresh (~380ms
/// p90 on real hardware) kept cancelling the in-flight refresh before it completed. Explicit
/// sessions still preempt (`cancelRunning`), and the non-debounced path (`refreshImmediately`)
/// cancels a running refresh rather than overlapping it, so at most one refresh worker exists at
/// any time.
@MainActor
final class RefreshDebouncer {
  private var pendingTask: Task<Void, Never>?
  private var activeRefreshTask: Task<Void, Never>?
  /// Set while a refresh is running and a newer event arrived; the running refresh runs one
  /// follow-up with the latest `pendingEvent` when it finishes.
  private var isDirty = false
  private var pendingEvent: RefreshSessionEvent?
  private var pendingOptimisticPreLayout = false
  private var pendingUnlockReset = false
  private let delay: TimeInterval
  private let worker: @MainActor (RefreshSessionEvent, Bool) async throws -> Void

  init(
    delay: TimeInterval = 0.05, // 50ms
    worker: @escaping @MainActor (RefreshSessionEvent, Bool) async throws -> Void = { event, optimistic in
      try await runRefreshSessionBlocking(event, optimisticallyPreLayoutWorkspaces: optimistic)
    }
  ) {
    self.delay = delay
    self.worker = worker
  }

  func debounce(
    event: RefreshSessionEvent,
    screenIsDefinitelyUnlocked: Bool,
    optimisticallyPreLayoutWorkspaces: Bool = false
  ) {
    remember(event, optimisticallyPreLayoutWorkspaces: optimisticallyPreLayoutWorkspaces, screenIsDefinitelyUnlocked: screenIsDefinitelyUnlocked)
    pendingTask?.cancel()
    pendingTask = Task { @MainActor in
      try? await Task.sleep(for: .seconds(delay))
      guard !Task.isCancelled else { return }
      startIfIdle() // never cancels a running refresh; that unconditional cancel is what starved it (issue #1)
    }
  }

  /// Explicit non-debounced refresh (commands, critical paths). Runs now; if a debounced refresh
  /// is in flight it cancels it instead of overlapping, and the cancelled worker's completion
  /// starts this one with the latest remembered event.
  func refreshImmediately(
    event: RefreshSessionEvent,
    screenIsDefinitelyUnlocked: Bool,
    optimisticallyPreLayoutWorkspaces: Bool = false
  ) {
    remember(event, optimisticallyPreLayoutWorkspaces: optimisticallyPreLayoutWorkspaces, screenIsDefinitelyUnlocked: screenIsDefinitelyUnlocked)
    pendingTask?.cancel()
    if activeRefreshTask == nil {
      startWorker()
    } else {
      activeRefreshTask?.cancel()
      isDirty = true
    }
  }

  /// Called by `runSession`: a critical session takes over, so the pending debounce and any
  /// in-flight refresh are dropped. No follow-up runs -- the session's own body lays out instead.
  func cancelRunning() {
    pendingTask?.cancel()
    activeRefreshTask?.cancel()
    activeRefreshTask = nil
    isDirty = false
  }

  private func remember(_ event: RefreshSessionEvent, optimisticallyPreLayoutWorkspaces: Bool, screenIsDefinitelyUnlocked: Bool) {
    pendingEvent = event // latest event wins; bursts faster than `delay` coalesce here
    pendingOptimisticPreLayout = optimisticallyPreLayoutWorkspaces
    pendingUnlockReset = screenIsDefinitelyUnlocked
  }

  private func startIfIdle() {
    guard activeRefreshTask == nil else {
      isDirty = true // a refresh is running; it will run the follow-up when it finishes
      return
    }
    startWorker()
  }

  private func startWorker() {
    guard let event = pendingEvent else { return }
    pendingEvent = nil
    let optimistic = pendingOptimisticPreLayout
    pendingOptimisticPreLayout = false
    if pendingUnlockReset {
      pendingUnlockReset = false
      resetClosedWindowsCache()
    }
    activeRefreshTask = Task { @MainActor in
      _ = try? await worker(event, optimistic)
      activeRefreshTask = nil
      if isDirty {
        isDirty = false
        startWorker() // exactly one follow-up, with the latest event
      }
    }
  }
}
