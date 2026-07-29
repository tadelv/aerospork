import AppKit
import Common

/// Coalesces bursts of accessibility events into a single refresh after a short fixed delay.
/// A window manager sees rapid-fire AX notifications (app activate, window move, space change);
/// debouncing at 50ms collapses them so we lay out once instead of per-event.
@MainActor
final class RefreshDebouncer {
    private var pendingTask: Task<Void, Never>?
    private let delay: TimeInterval

    init(delay: TimeInterval = 0.05) { // 50ms
        self.delay = delay
    }

    // A `maxWait` ceiling was tried here and REVERTED. The intent was to stop a sustained event
    // stream from starving the refresh, but it made things strictly worse: every time the ceiling
    // fired it hit `activeRefreshTask?.cancel()` below and killed a refresh that was still running.
    // Measured with a 400ms refresh under a 10ms event stream: 12 refreshes started, ZERO
    // completed, versus the plain debounce's "no work during the burst, then one correct layout".
    // p90 refresh on real hardware is ~380ms, so this was reachable, not theoretical. It also
    // risked leaving partial layout behind, since a cancelled refresh may already have issued
    // some setFrame writes. Do not re-add without first fixing the unconditional cancel, and
    // without a measurement showing starvation actually happens.
    func debounce(
        event: RefreshSessionEvent,
        screenIsDefinitelyUnlocked: Bool,
        optimisticallyPreLayoutWorkspaces: Bool = false,
    ) {
        pendingTask?.cancel()
        pendingTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }

            activeRefreshTask?.cancel()
            activeRefreshTask = Task { @MainActor in
                try checkCancellation()
                try await runRefreshSessionBlocking(event, optimisticallyPreLayoutWorkspaces: optimisticallyPreLayoutWorkspaces)
            }

            if screenIsDefinitelyUnlocked {
                resetClosedWindowsCache()
            }
        }
    }

    // A `cancelPending()` counterpart used to live here with zero call sites. Deleted rather than
    // wired up: the only plausible caller is termination, and cancelling a 50ms debounce while the
    // process is exiting buys nothing. Add it back when something actually needs it.
}
