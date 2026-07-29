public struct OpenSettingsCmdArgs: CmdArgs {
    public let rawArgs: EquatableNoop<[String]>
    public init(rawArgs: [String]) { self.rawArgs = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .openSettings,
        // Allowed in config so it can be bound to a key. The GUI was previously reachable only from
        // the menu bar, which is awkward for a keyboard-first window manager.
        allowInConfig: true,
        help: open_settings_help_generated,
        options: [:],
        arguments: [],
    )

    /*conforms*/ public var windowId: UInt32?
    /*conforms*/ public var workspaceName: WorkspaceName?
}
