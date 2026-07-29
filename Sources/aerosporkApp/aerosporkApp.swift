import AppBundle
import SwiftUI

// This file is shared between SPM and xcode project

@MainActor // macOS 13
@main
struct aerosporkApp: App {
    @MainActor // macOS 13
    @StateObject var viewModel = TrayMenuModel.shared

    init() {
        initAppBundle()
    }

    @MainActor // macOS 13
    var body: some Scene {
        menuBar(viewModel: viewModel)

        // A `Settings` scene, not a WindowGroup: it is a singleton, so two settings windows can no
        // longer race each other writing the config file, and it gets Command-, for free.
        Settings {
            AppBundle.ConfigurationWindow()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {} // Remove default About menu
        }
    }
}
