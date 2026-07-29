@testable import AppBundle
import Common
import Foundation
import XCTest

/// `updateFocusCache` is the one place macOS is allowed to overwrite the model's idea of focus.
/// That is correct for a user clicking a window, and wrong for the echo of a focus request we just
/// issued ourselves -- the two arrive through the same channel and used to be indistinguishable.
@MainActor
final class FocusCacheTest: XCTestCase {
    override func setUp() async throws {
        setUpWorkspacesForTests()
        resetFocusCacheForTests()
    }

    /// The reported bug. Switching to a workspace landed focus -- and therefore the active
    /// workspace, and therefore `move-mouse` -- on a different monitor entirely.
    ///
    /// `MacApp.nativeFocus` raises the target window and activates its app asynchronously, and
    /// `runSession` starts another refresh straight after. In that gap an app can still report its
    /// PREVIOUS frontmost window as focused. If that window lives on another workspace, adopting it
    /// undoes the switch. Only reproducible when both workspaces hold windows of the same app,
    /// which is why it looked intermittent rather than broken.
    func testAnAppEchoingItsOldWindowDoesNotUndoAWorkspaceSwitch() {
        let target = TestWindow.new(id: 1, parent: Workspace.get(byName: "target").rootTilingContainer)
        let stale = TestWindow.new(id: 2, parent: Workspace.get(byName: "elsewhere").rootTilingContainer)

        XCTAssertTrue(target.focusWindow())
        expectNativeFocus(target.windowId) // what MacApp.nativeFocus records before issuing the AX calls

        updateFocusCache(stale) // the app answers with its own, older window
        assertEquals(focus.windowOrNil?.windowId, target.windowId, additionalMsg: "the in-flight focus request was overridden")
        assertEquals(focus.workspace.name, "target")
    }

    /// ...and once macOS agrees, a real user focus change is honoured again. Without this the guard
    /// would be a focus lock rather than a race fix.
    func testFocusFollowsMacOsAgainOnceTheRequestIsAcknowledged() {
        let target = TestWindow.new(id: 1, parent: Workspace.get(byName: "target").rootTilingContainer)
        let other = TestWindow.new(id: 2, parent: Workspace.get(byName: "elsewhere").rootTilingContainer)

        XCTAssertTrue(target.focusWindow())
        expectNativeFocus(target.windowId)
        updateFocusCache(target) // macOS catches up

        updateFocusCache(other) // now the user clicks a window on the other workspace
        assertEquals(focus.windowOrNil?.windowId, other.windowId)
        assertEquals(focus.workspace.name, "elsewhere")
    }

    /// The safety valve. A request macOS silently drops must not wedge focus tracking forever, so
    /// the guard expires and control returns to macOS -- the pre-fix behaviour, which is the right
    /// thing to fall back to.
    func testAnUnacknowledgedRequestExpiresInsteadOfLockingFocus() {
        let target = TestWindow.new(id: 1, parent: Workspace.get(byName: "target").rootTilingContainer)
        let other = TestWindow.new(id: 2, parent: Workspace.get(byName: "elsewhere").rootTilingContainer)

        XCTAssertTrue(target.focusWindow())
        expectNativeFocus(target.windowId, deadline: Date().addingTimeInterval(-1)) // already expired

        updateFocusCache(other)
        assertEquals(focus.windowOrNil?.windowId, other.windowId, additionalMsg: "focus stayed locked after the grace period")
    }
}
