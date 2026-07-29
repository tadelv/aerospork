@testable import AppBundle
import Common
import XCTest

/// What a command says when it cannot do what was asked. A CLI that fails without naming a next
/// step is the same as one that fails silently.
@MainActor
final class CmdUserFeedbackTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    /// The tip is advice, and advice you have already taken is noise -- worse, "Tip: use
    /// --fail-if-noop" printed in response to `--fail-if-noop` reads like the flag was ignored.
    func testNoopTipIsOmittedOnceTheUserHasTakenIt() {
        assertEquals(noopMessage("Nothing to do.", failIfNoop: false), "Nothing to do. \(noopTip)")
        assertEquals(noopMessage("Nothing to do.", failIfNoop: true), "Nothing to do.")
    }

    /// `workspace-back-and-forth` was `prevFocusedWorkspace?.focusWorkspace() != nil`, which is a
    /// test that a previous workspace *exists*. With none -- the state right after launch, when a
    /// user first tries the keybinding -- it returned false and printed nothing at all.
    func testWorkspaceBackAndForthSaysWhyItDidNothing() async throws {
        _prevFocusedWorkspaceName = nil

        let io = CmdIo(stdin: .emptyStdin)
        let succ = WorkspaceBackAndForthCommand(args: WorkspaceBackAndForthCmdArgs(rawArgs: [])).run(.defaultEnv, io)

        XCTAssertFalse(succ)
        assertEquals(io.stderr.count, 1)
        XCTAssertTrue(io.stderr.first?.contains("switch workspaces at least once") == true, io.stderr.description)
    }
}
