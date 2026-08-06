/// `aeroSporkAppId` is an identifier — it names the bundle, the unified-log subsystem and the CLI
/// socket, and must stay lowercase. `aeroSporkAppName` is the opposite: it is *display* text,
/// interpolated into the menu bar's Quit item, the "server is disabled" error and the version
/// string a user pastes into a bug report. Nothing resolves it as a path.
///
/// So it is stylized the way the product is written everywhere else: **AeroSpork**. It used to be
/// `"aerospork"`, which made the app contradict itself — the crash dialog said `AeroSpork` while
/// the menu bar said "Quit aerospork".
#if DEBUG
  public let aeroSporkAppId: String = "com.wbs.aerospork.debug"
  public let aeroSporkAppName: String = "AeroSpork-Debug"
#else
  public let aeroSporkAppId: String = "com.wbs.aerospork"
  public let aeroSporkAppName: String = "AeroSpork"
#endif
