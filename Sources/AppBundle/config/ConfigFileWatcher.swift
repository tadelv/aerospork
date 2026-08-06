import Common
import Darwin
import Foundation

extension Notification.Name {
  /// Posted after the config was reloaded because the file changed on disk (not from a GUI save).
  static let aerosporkConfigReloadedExternally = Notification.Name("aerosporkConfigReloadedExternally")
}

/// Watches the active config file and hot-reloads on change, so edits from an external
/// editor (or the settings GUI) apply without a manual `reload-config`.
///
/// Editors typically save atomically (write a temp file, then rename over the original),
/// which invalidates the original file descriptor — so on any event we debounce a reload
/// and then re-arm the watch on whatever file now lives at `configUrl`.
@MainActor
enum ConfigFileWatcher {
  private static var source: DispatchSourceFileSystemObject?
  private static var debounceTask: Task<Void, Never>?
  private static var suppressUntil: Date?

  /// Ignore file events for a moment after the settings GUI writes the file itself. Otherwise the
  /// GUI's own `reloadConfig()` and the watcher's debounced one both fire for a single save --
  /// a double reload and, on a bad config, two error dialogs.
  static func suppressNextSelfWrite() {
    suppressUntil = Date().addingTimeInterval(0.5)
  }

  /// The file the user actually edits — deliberately NOT `configUrl`.
  ///
  /// When a broken config forces the bundled default at startup, `configUrl` points inside the
  /// app bundle. Watching that meant watching a file that can never change: the user's fix was
  /// never picked up and the app stayed on defaults until it was restarted, which is precisely
  /// the moment hot-reload matters most.
  static var watchedPath: String? {
    serverArgs.configLocation ?? findCustomConfigUrl().urlOrNil?.path
  }

  static func start() {
    source?.cancel()
    source = nil
    guard let path = watchedPath else { return } // no user config yet; `write` re-arms on first save
    guard FileManager.default.fileExists(atPath: path) else { return }
    let fd = open(path, O_EVTONLY)
    guard fd >= 0 else {
      // Silent until now: hot-reload just stopped working and nothing anywhere said why.
      AppLog.config.error("Hot-reload disabled: can't watch \(path, privacy: .public) (errno \(errno, privacy: .public))")
      return
    }
    let src = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: fd,
      eventMask: [.write, .delete, .rename, .extend],
      queue: DispatchQueue.main
    )
    src.setEventHandler {
      Task { @MainActor in scheduleReload() }
    }
    src.setCancelHandler { close(fd) }
    source = src
    src.resume()
  }

  static func stop() {
    debounceTask?.cancel()
    debounceTask = nil
    source?.cancel()
    source = nil
  }

  private static func scheduleReload() {
    debounceTask?.cancel()
    debounceTask = Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(150)) // coalesce editor write bursts
      guard !Task.isCancelled else { return }
      if let until = suppressUntil, Date() < until {
        suppressUntil = nil
        start() // still re-arm: the file may have been replaced atomically
        return
      }
      if reloadConfig() {
        runRefreshSession(.globalObserver("configFileChanged"), screenIsDefinitelyUnlocked: true)
        // An open settings window holds a snapshot of what it loaded. Without this it would
        // keep editing against stale text and could write it back over the external change.
        NotificationCenter.default.post(name: .aerosporkConfigReloadedExternally, object: nil)
      }
      start() // re-arm on the (possibly replaced) file
    }
  }
}
