public struct ListExecEnvVarsCmdArgs: CmdArgs {
  public let rawArgs: EquatableNoop<[String]>
  public init(rawArgs: [String]) { self.rawArgs = .init(rawArgs) }
  public static let parser: CmdParser<Self> = cmdParser(
    kind: .listExecEnvVars,
    allowInConfig: true,
    help: list_exec_env_vars_help_generated,
    options: [
      "--show-secrets": trueBoolFlag(\.showSecrets)
    ],
    arguments: []
  )

  /*conforms*/ public var windowId: UInt32?
  /*conforms*/ public var workspaceName: WorkspaceName?
  /// Values of credential-shaped var names are redacted unless this is passed.
  public var showSecrets: Bool = false
}
