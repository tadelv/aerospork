import AppKit
import Common

struct OpenSettingsCommand: Command {
    let args: OpenSettingsCmdArgs

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        // The settings window is a `Settings` scene, so AppKit owns opening it. The selector was
        // renamed in Sonoma; this app supports Ventura, hence the branch.
        NSApplication.shared.activate(ignoringOtherApps: true)
        let selector = if #available(macOS 14, *) {
            Selector(("showSettingsWindow:"))
        } else {
            Selector(("showPreferencesWindow:"))
        }
        guard NSApp.sendAction(selector, to: nil, from: nil) else {
            return io.err("Couldn't open the settings window")
        }
        return true
    }
}
