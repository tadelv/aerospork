import Foundation

@MainActor private var lastKnownNativeFocusedWindowId: UInt32? = nil

/// The window we asked macOS to focus, and how long we are willing to wait for it to agree.
@MainActor private var pendingNativeFocus: (windowId: UInt32, deadline: Date)? = nil

/// How long a focus request stays authoritative. Long enough for an app to answer an activate
/// (Chromium-family apps are the slow ones), short enough that a request macOS silently drops
/// cannot wedge focus tracking. If it expires we go back to trusting macOS, which is the correct
/// failure mode: worst case the user gets today's behaviour.
private let nativeFocusGrace: TimeInterval = 1.0

/// Both globals survive for the lifetime of the process, which is right for the app and wrong for a
/// test suite: `lastKnownNativeFocusedWindowId` left over from one test suppresses the adopt in the
/// next, so the tests would pass or fail depending on their order.
@MainActor func resetFocusCacheForTests() {
    lastKnownNativeFocusedWindowId = nil
    pendingNativeFocus = nil
}

/// Called by `MacApp.nativeFocus`. Until macOS reports this window focused, reports of *other*
/// windows are treated as our own request still in flight rather than as a user focus change.
@MainActor func expectNativeFocus(_ windowId: UInt32, deadline: Date = Date().addingTimeInterval(nativeFocusGrace)) {
    pendingNativeFocus = (windowId, deadline)
}

/// The data should flow (from nativeFocused to focused) and
///                      (from nativeFocused to lastKnownNativeFocusedWindowId)
/// Alternative names: takeFocusFromMacOs, syncFocusFromMacOs
@MainActor func updateFocusCache(_ nativeFocused: Window?) {
    // A focus request we issued is still in flight. `MacApp.nativeFocus` raises the target window
    // and then calls `nsApp.activate`, both asynchronously on the app's thread; `runSession` starts
    // another refresh immediately afterwards. In that window an app can report a DIFFERENT window
    // of its own as focused -- typically its previous frontmost one -- and this function used to
    // adopt that as a genuine user focus change and move the model's focus to it.
    //
    // The visible symptom: `workspace 1` (two Edge windows) would land focus on the workspace
    // holding a THIRD Edge window, because activating Edge briefly reported that one. Focus, the
    // active workspace, and therefore `move-mouse` all followed it to the wrong monitor. Only
    // reproducible when the source and target workspaces share an app, which is why it read as
    // intermittent.
    if let pending = pendingNativeFocus {
        if nativeFocused?.windowId == pending.windowId {
            pendingNativeFocus = nil // macOS agreed; resume trusting it
        } else if Date() < pending.deadline {
            return // still in flight -- do not adopt, and do not record it as last known either
        } else {
            pendingNativeFocus = nil // gave up waiting; macOS wins
        }
    }
    if nativeFocused?.windowId != lastKnownNativeFocusedWindowId {
        _ = nativeFocused?.focusWindow()
        lastKnownNativeFocusedWindowId = nativeFocused?.windowId
    }
}
