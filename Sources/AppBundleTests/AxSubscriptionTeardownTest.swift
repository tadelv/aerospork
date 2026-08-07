@testable import AppBundle
import Common
import XCTest

/// Issue #2: `MacApp.destroy()` submits its AX cleanup with `perform(...waitUntilDone: false)`,
/// which is silently dropped when the app's run-loop thread has already exited (the observed app
/// terminated). The `ThreadGuardedValue` wrappers are then released wherever the final reference
/// happens to die -- usually the main actor -- and the subscriptions deinit off their AX thread.
/// `AxSubscription.deinit` used to make that a fatal thread-token check.
final class AxSubscriptionTeardownTest: XCTestCase {
  /// The exact dropped-cleanup path: subscriptions live inside a `ThreadGuardedValue`, the
  /// destroy() block never runs, and the wrapper is released on the main actor. Reaching the end
  /// of the test is the assertion -- the old code died in `AxSubscription.deinit`.
  @MainActor
  func testDroppedCleanupReleaseOnMainActorDoesNotCrash() {
    let token = AxAppThreadToken(pid: getpid(), idForDebug: "test-ax-thread")
    var holder: ThreadGuardedValue<[AxSubscription]>? = nil
    $axTaskLocalAppThreadToken.withValue(token) {
      guard let obs = AXObserver.new(getpid(), { _, _, _, _ in }) else { die() }
      let subscription = AxSubscription(obs: obs, ax: AXUIElementCreateSystemWide())
      holder = ThreadGuardedValue([subscription]) // what MacApp.appAxSubscriptions does
    }
    holder = nil // the queued cleanup was dropped, so this release lands on the main actor
  }

  /// Normal teardown is untouched: releasing a subscription on its owning thread still removes
  /// the run-loop source.
  func testOnThreadReleaseStillRemovesRunLoopSource() {
    let token = AxAppThreadToken(pid: getpid(), idForDebug: "test-ax-thread")
    $axTaskLocalAppThreadToken.withValue(token) {
      guard let obs = AXObserver.new(getpid(), { _, _, _, _ in }) else { die() }
      let source = AXObserverGetRunLoopSource(obs)
      CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
      assertTrue(CFRunLoopContainsSource(CFRunLoopGetCurrent(), source, .defaultMode))

      var subscription: AxSubscription? = AxSubscription(obs: obs, ax: AXUIElementCreateSystemWide())
      subscription = nil // deinit on the owning thread must tear the source down

      assertFalse(CFRunLoopContainsSource(CFRunLoopGetCurrent(), source, .defaultMode))
    }
  }
}
