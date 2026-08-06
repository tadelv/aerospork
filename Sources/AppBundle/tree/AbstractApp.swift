import Common

protocol AbstractApp: AnyObject, Hashable, AeroAny {
  var pid: Int32 { get }
  var bundleId: String? { get }

  @MainActor func getFocusedWindow() async throws -> Window?
  var name: String? { get }
  var execPath: String? { get }
  var bundlePath: String? { get }
}

extension AbstractApp {
  /// By identity, not by pid.
  ///
  /// This used to assert that the two agree (`check(lhs === rhs)` when the pids match, and the
  /// converse otherwise) -- a fatal assertion that `MacApp.allAppsMap` interning is never broken.
  /// pid reuse breaks it: `destroy()` drops an app from the map while its windows still hold it,
  /// and the OS is free to hand the same pid to a brand new process (the `failedPids` cache
  /// already tracks `launchDate` for exactly this reason). Identity is also the answer we want in
  /// that race -- each `MacApp` owns its own thread and AX connection, so a stale one is genuinely
  /// not the new one, and treating them as equal would attribute live windows to a dead app whose
  /// thread has already stopped. Same-pid-different-object is now a plain hash collision.
  static func == (lhs: Self, rhs: Self) -> Bool { lhs === rhs }

  func hash(into hasher: inout Hasher) {
    hasher.combine(pid)
  }
}

extension Window {
  var macAppUnsafe: MacApp { app as! MacApp }
}
