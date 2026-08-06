import Common

/// The names `exec-and-forget` children see when the command had a target.
///
/// One spelling each: the upstream-branded aliases were removed, not deprecated, so a script
/// reading the old names now sees an unset variable.
let windowIdEnvVar = "AEROSPORK_WINDOW_ID"
let workspaceEnvVar = "AEROSPORK_WORKSPACE"

struct CmdEnv: ConvenienceCopyable { // todo forward env from cli to server
  var windowId: UInt32?
  var workspaceName: String?
  var pwd: String?

  static var defaultEnv: CmdEnv { CmdEnv(windowId: nil, workspaceName: nil, pwd: nil) }
  init(
    windowId: UInt32?,
    workspaceName: String?,
    pwd: String?
  ) {
    self.windowId = windowId
    self.workspaceName = workspaceName
    self.pwd = pwd
  }

  func withFocus(_ focus: LiveFocus) -> CmdEnv {
    switch focus.asLeaf {
      case .window(let wd): .defaultEnv.copy(\.windowId, wd.windowId)
      case .emptyWorkspace(let ws): .defaultEnv.copy(\.workspaceName, ws.name)
    }
  }

  @MainActor
  var asMap: [String: String] {
    var result = config.execConfig.envVariables
    if let pwd {
      result["PWD"] = pwd
    }
    if let windowId {
      result[windowIdEnvVar] = windowId.description
    }
    if let workspaceName {
      result[workspaceEnvVar] = workspaceName.description
    }
    return result
  }
}
