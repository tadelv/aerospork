// The CLI <-> server contract beyond the wire format itself (see util/UnixSocket.swift for framing).

/// Exit codes of the `aerospork` CLI, so scripts can branch on the *class* of failure instead of
/// treating every non-zero code as "something went wrong".
/// Deliberately tiny: a new code earns its place only when a script would plausibly react to it
/// differently. Everything else stays `failure`.
public enum ExitCode {
  /// The command ran and did what was asked.
  public static let success: Int32 = 0
  /// The command was understood but failed at runtime (no such window, server disabled, ...).
  public static let failure: Int32 = 1
  /// The request was malformed: unknown subcommand, bad flag, undecodable/oversized frame.
  public static let badArgs: Int32 = 2
  /// Client-side only: AeroSpork.app isn't running, or the connection died mid-request.
  public static let serverUnreachable: Int32 = 3
}

/// Warning to print when the CLI and the running server were built from different sources; nil when
/// they match. Only a warning: failing hard would break every script on the machine the moment the
/// app updates but the running server hasn't been restarted, which is worse than the mismatch.
public func versionMismatchWarning(client: String, server: String) -> String? {
  if client == server { return nil }
  return """
    Warning: AeroSpork client/server versions don't match
        - AeroSpork CLI client version: \(client)
        - AeroSpork.app server version: \(server)
        Possible fixes:
        - Restart AeroSpork.app (server restart is required after each update)
        - Reinstall and restart AeroSpork (corrupted installation)
    """
}
