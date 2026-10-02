@testable import AppBundle
import XCTest

/// AeroSpork must never register itself as a managed app.
///
/// Its own windows -- the Settings window, SwiftUI's MenuBarExtra panel -- are ordinary NSWindows in
/// our own process, so they appear in our own AX window list. Laying one out sends an AX write that
/// targets our own process, AppKit serves it in-process on the app's AX thread, and
/// `-[NSWMWindowCoordinator performTransactionUsingBlock:]` asserts "Must only be used from the main
/// thread". The app dies with SIGTRAP and leaves its socket file behind, which the CLI reports as
/// "Is AeroSpork.app running?".
///
/// Pinned by reading the source, for the reason `OpenSettingsTest` documents: there is no
/// behavioural test to write. `NSRunningApplication(processIdentifier: getpid())` returns nil for an
/// xctest process, and `getOrRegister` takes an `NSRunningApplication`, so there is nothing to hand
/// it. That makes this test the only thing standing between the guard and silent deletion -- and it
/// has to read *lines*, not substrings: commenting the guard out leaves the text in place, so a
/// substring search passes on a guard that no longer runs. Verified by commenting it out.
@MainActor
final class NeverManageOurOwnWindowsTest: XCTestCase {
  func testOurOwnPidIsRejectedBeforeAnyThreadIsSpawned() throws {
    let source = try String(
      contentsOf: projectRoot.appending(path: "Sources/AppBundle/tree/MacApp.swift"),
      encoding: .utf8
    )
    let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
    let ownPidGuard = try XCTUnwrap(
      lines.firstIndex { line in
        // The whole line, `return nil` included: a guard that only *mentions* our pid is not a guard.
        let code = line.trimmingCharacters(in: .whitespaces)
        return code.hasPrefix("if nsApp.processIdentifier == ProcessInfo.processInfo.processIdentifier")
          && code.contains("return nil")
      },
      "getOrRegister must reject our own process"
    )
    let threadSpawn = try XCTUnwrap(lines.firstIndex {
      $0.trimmingCharacters(in: .whitespaces).hasPrefix("wipPids.insert(pid)")
    })
    XCTAssertLessThan(
      ownPidGuard, threadSpawn,
      """
      Rejecting our own pid has to happen before the AX thread is created: that thread is what
      performs the AX writes that crash the process when their target is ourselves.
      """
    )
  }
}
