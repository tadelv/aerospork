import AppKit
import Common

/// Substrings that mark an env var name as credential-shaped. Matching on the name over-matches by
/// design (MONKEY_BUSINESS gets redacted too) — over-redacting costs a `--show-secrets` rerun,
/// under-redacting leaks an API key into a bug report or a screen share.
private let secretNameMarkers = ["KEY", "TOKEN", "SECRET", "PASSWORD", "PASSWD", "CREDENTIAL", "AUTH", "PRIVATE"]

func looksSecret(_ name: String) -> Bool {
  let upper = name.uppercased()
  return secretNameMarkers.contains { upper.contains($0) }
}

struct ListExecEnvVarsCommand: Command {
  let args: ListExecEnvVarsCmdArgs

  func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
    for (key, value) in config.execConfig.envVariables {
      // exec env vars are inherited from the whole process environment by default, so this
      // command otherwise dumps every credential the app was launched with.
      io.out("\(key)=\(args.showSecrets || !looksSecret(key) ? value : "<redacted>")")
    }
    return true
  }
}
