// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "aerosporkPackage",
  // Runtime support for parameterized protocol types is only available in macOS 13.0.0 or newer
  // And it specifies deploymentTarget for CLI
  platforms: [.macOS(.v13)],
  // Products define the executables and libraries a package produces, making them visible to other packages.
  products: [
    .executable(name: "aerospork", targets: ["Cli"]),
    // Don't use this build for release, use xcode instead
    .executable(name: "aerosporkApp", targets: ["aerosporkApp"]),
    // We only need to expose this as a product for xcode
    .library(name: "AppBundle", targets: ["AppBundle"])
  ],
  dependencies: [
    // Two third-party dependencies, both pinned exactly.
    //
    // TOMLKit parses the config. Sockets, hotkeys, volume, ordered collections and shell
    // parsing are all native.
    .package(url: "https://github.com/LebJe/TOMLKit", exact: "0.6.0"),
    // Sparkle delivers in-app updates. The App Store cannot distribute this app (the
    // Accessibility APIs it is built on do not work sandboxed), so there is no store update
    // mechanism to inherit, and a window manager that silently goes stale is worse than one
    // that asks. Ships as a prebuilt XCFramework, hence the extra signing steps in
    // build-release.sh.
    .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.9.4")
  ],
  // Targets are the basic building blocks of a package, defining a module or a test suite.
  // Targets can depend on other targets in this package and products from dependencies.
  targets: [
    // Exposes the prviate _AXUIElementGetWindow function to swift
    .target(
      name: "PrivateApi",
      path: "Sources/PrivateApi",
      publicHeadersPath: "include"
    ),
    .target(
      name: "Common"
    ),
    .target(
      name: "AppBundle",
      dependencies: [
        .product(name: "TOMLKit", package: "TOMLKit"),
        .product(name: "Sparkle", package: "Sparkle"),
        .target(name: "Common"),
        .target(name: "PrivateApi")
      ]
    ),
    .executableTarget(
      name: "aerosporkApp",
      dependencies: [
        .target(name: "AppBundle")
      ]
    ),
    .executableTarget(
      name: "Cli",
      dependencies: [
        .target(name: "Common")
      ]
    ),
    .testTarget(
      name: "AppBundleTests",
      dependencies: [
        .target(name: "AppBundle")
      ],
      // AppBundle links Sparkle, so the test bundle inherits that link. Without a runpath
      // pointing at SwiftPM's PackageFrameworks directory, dyld cannot find
      // Sparkle.framework when the test host launches and the whole bundle dies with signal
      // 5 before a single test runs -- which looked like "53 tests passed" because only
      // CommonTests survived.
      linkerSettings: [
        .unsafeFlags([
          // The test binary sits at Products/<config>/AppBundleTests.xctest/Contents/
          // MacOS/, and SwiftPM copies Sparkle.framework to Products/<config>/, so the
          // framework is exactly three directories up.
          "-Xlinker", "-rpath", "-Xlinker", "@loader_path/../../.."
        ])
      ]
    ),
    // Common (socket codec, cmd-args parsing, TOML error formatting, string utils) is shared by
    // the app and the CLI, and used to be reachable only through AppBundle. Depending on Cli
    // too is legal since Swift 5.5 and is what lets the CLI's own generated tables be asserted
    // on -- `subcommandDescriptionsGenerated.swift` silently degraded to a single "*" row once.
    .testTarget(
      name: "CommonTests",
      dependencies: [
        .target(name: "Common"),
        .target(name: "Cli")
      ]
    )
  ]
)
