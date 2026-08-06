@testable import AppBundle
import Common
import XCTest

@MainActor
final class ServerProtocolTest: XCTestCase {
  private func answer(_ command: String) -> ServerAnswer? {
    let (cmd, help, err) = parseCommand(command).unwrap()
    return nonRunningAnswer(command: cmd, help: help, err: err)
  }

  func testExitCodesAreDistinct() {
    let all = [ExitCode.success, ExitCode.failure, ExitCode.badArgs, ExitCode.serverUnreachable]
    assertEquals(Set(all).count, all.count)
  }

  func testMalformedArgsGetBadArgs() {
    assertEquals(answer("list-workspaces --all --focused")?.exitCode, ExitCode.badArgs)
    assertEquals(answer("no-such-subcommand")?.exitCode, ExitCode.badArgs)
  }

  func testExecOverSocketGetsBadArgs() {
    assertEquals(answer("exec-and-forget echo hi")?.exitCode, ExitCode.badArgs)
  }

  func testHelpSucceeds() {
    let ans = answer("list-workspaces --help")
    assertEquals(ans?.exitCode, ExitCode.success)
    assertTrue(!(ans?.stdout ?? "").isEmpty)
  }

  func testRunnableCommandIsNotAnsweredEarly() {
    assertNil(answer("list-workspaces --all"))
  }

  func testVersionMismatchIsReportedRegardlessOfSuccess() {
    assertNil(versionMismatchWarning(client: "1.0 abc", server: "1.0 abc"))
    let warning = versionMismatchWarning(client: "1.0 abc", server: "1.1 def")
    assertNotNil(warning)
    assertTrue(warning?.contains("1.1 def") == true)
  }

  func testReleaseSocketPathUsesThisProjectsBundleId() {
    // The fork inherited the upstream project's bundle id in this socket name.
    assertEquals(releaseServerSocketPath, "/tmp/com.wbs.aerospork-\(unixUserName).sock")
  }
}
