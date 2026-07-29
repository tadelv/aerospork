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
        .library(name: "AppBundle", targets: ["AppBundle"]),
    ],
    dependencies: [
        // TOMLKit is the only remaining third-party dependency (config parsing).
        // Sockets, hotkeys, volume, ordered collections, and shell parsing are now native.
        .package(url: "https://github.com/LebJe/TOMLKit", exact: "0.6.0"),
    ],
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    targets: [
        // Exposes the prviate _AXUIElementGetWindow function to swift
        .target(
            name: "PrivateApi",
            path: "Sources/PrivateApi",
            publicHeadersPath: "include",
        ),
        .target(
            name: "Common",
        ),
        .target(
            name: "AppBundle",
            dependencies: [
                .product(name: "TOMLKit", package: "TOMLKit"),
                .target(name: "Common"),
                .target(name: "PrivateApi"),
            ],
        ),
        .executableTarget(
            name: "aerosporkApp",
            dependencies: [
                .target(name: "AppBundle"),
            ],
        ),
        .executableTarget(
            name: "Cli",
            dependencies: [
                .target(name: "Common"),
            ],
        ),
        .testTarget(
            name: "AppBundleTests",
            dependencies: [
                .target(name: "AppBundle"),
            ],
        ),
        // Common (socket codec, cmd-args parsing, TOML error formatting, string utils) is shared by
        // the app and the CLI, and used to be reachable only through AppBundle. Depending on Cli
        // too is legal since Swift 5.5 and is what lets the CLI's own generated tables be asserted
        // on -- `subcommandDescriptionsGenerated.swift` silently degraded to a single "*" row once.
        .testTarget(
            name: "CommonTests",
            dependencies: [
                .target(name: "Common"),
                .target(name: "Cli"),
            ],
        ),
    ],
)
