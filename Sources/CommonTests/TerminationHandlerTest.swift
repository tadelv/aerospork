@testable import Common
import Foundation
import XCTest

/// A handler that never finishes. Stands in for the real one, which is `@MainActor` and therefore
/// *cannot* finish while `die()` blocks the main actor waiting for it.
private struct HangingTerminationHandler: TerminationHandler {
    func beforeTermination() async throws { try await Task.sleep(nanoseconds: 60 * 1_000_000_000) }
}

/// `die()` must fail fast. It used to block on an unbounded `DispatchSemaphore`, so a `die()` on the
/// main actor -- which is where nearly all of them are -- deadlocked instead of reporting. A bundled
/// default config that didn't parse turned into a silent forever-hang at 100% CPU.
@MainActor
final class TerminationHandlerTest: XCTestCase {
    private var saved: TerminationHandler = EmptyTerminationHandler()

    override func setUp() async throws {
        saved = terminationHandler
        terminationHandler = HangingTerminationHandler()
    }

    override func tearDown() async throws {
        terminationHandler = saved
    }

    /// Without the timeout this call never returns and the whole suite hangs.
    func testWaitIsBounded() {
        let start = Date()
        XCTAssertFalse(awaitTerminationHandler(timeout: .milliseconds(200)))
        XCTAssertLessThan(Date().timeIntervalSince(start), 5)
    }

    /// Headlessly -- unit test, CLI, CI -- there is no dialog to keep alive and no windows to
    /// un-hide, so there is nothing to wait for at all.
    func testNilTimeoutDoesNotWait() {
        let start = Date()
        XCTAssertFalse(awaitTerminationHandler(timeout: nil))
        XCTAssertLessThan(Date().timeIntervalSince(start), 0.5)
    }
}
