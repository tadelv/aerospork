import AppKit
import Common
import ServiceManagement

@MainActor
func syncStartAtLogin() {
    cleanupPlistFromPrevVersions()
    let service = SMAppService.mainApp
    if config.startAtLogin {
        _ = try? service.register()
    } else {
        _ = try? service.unregister()
    }
}

/// Removes launch agents written by pre-`SMAppService` builds. They are not managed by
/// `SMAppService`, so leaving one behind means the app launches at login even after the user turns
/// `start-at-login` off.
///
/// Droppable once no installation that ever wrote `com.bsmolen.aerospork.plist` or
/// `com.wbs.aerospork.plist` can still be upgraded from -- neither bundle id has been shipped since
/// the AeroSpork rename, so this is dead weight for anyone installing today.
private func cleanupPlistFromPrevVersions() {
    let launchAgentsDir = FileManager.default.homeDirectoryForCurrentUser.appending(component: "Library/LaunchAgents/")
    Result { try FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true) }.getOrDie()
    // Clean up old AeroSpork plist files
    let oldUrls: [URL] = [
        launchAgentsDir.appending(path: "com.bsmolen.aerospork.plist"),
        launchAgentsDir.appending(path: "com.wbs.aerospork.plist"),
    ]
    oldUrls.forEach { try? FileManager.default.removeItem(at: $0) }
}
