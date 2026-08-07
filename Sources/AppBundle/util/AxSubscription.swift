import AppKit
import Common

/// The subscription is active as long as you keep this class in memory
class AxSubscription {
  let obs: AXObserver
  let ax: AXUIElement
  let axThreadToken: AxAppThreadToken = axTaskLocalAppThreadToken ?? dieT("axTaskLocalAppThreadToken is not initialized")
  var notifKeys: Set<String> = []

  // Not private: the headless tests construct subscriptions directly with a real AXObserver +
  // AXUIElement (creation needs no Accessibility permission) to exercise the teardown paths.
  init(obs: AXObserver, ax: AXUIElement) {
    axThreadToken.checkEquals(axTaskLocalAppThreadToken)
    self.obs = obs
    self.ax = ax
  }

  private func subscribe(_ key: String, _ job: RunLoopJob) throws -> Bool {
    axThreadToken.checkEquals(axTaskLocalAppThreadToken)
    if AXObserverAddNotification(obs, ax, key as CFString, nil) == .success {
      notifKeys.insert(key)
      return true
    } else {
      return false
    }
  }

  static func bulkSubscribe(_ nsApp: NSRunningApplication, _ ax: AXUIElement, _ job: RunLoopJob, _ handlerToNotifKeyMapping: HandlerToNotifKeyMapping) throws -> [AxSubscription] {
    var result: [AxSubscription] = []
    var visitedNotifKeys: Set<String> = []
    for (handler, notifKeys) in handlerToNotifKeyMapping {
      try job.checkCancellation()
      guard let obs = AXObserver.new(nsApp.processIdentifier, handler) else { return [] }
      let subscription = AxSubscription(obs: obs, ax: ax)
      for key: String in notifKeys {
        try job.checkCancellation()
        assert(visitedNotifKeys.insert(key).inserted)
        if try !subscription.subscribe(key, job) { return [] }
      }
      CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(obs), .defaultMode)
      result.append(subscription)
    }
    return result
  }

  deinit {
    // Normally we are released on the owning AX thread: `MacApp.destroy()`'s run-loop block
    // calls `ThreadGuardedValue.destroy()`, dropping the last strong reference here, on this
    // thread. But that block is submitted with `perform(...waitUntilDone: false)` and is
    // silently dropped when the app's thread has already left its run loop -- exactly what
    // happens when the observed app terminated. The wrapper is then released wherever the
    // final reference happens to die (usually the main actor), so this deinit can run on a
    // foreign thread.
    //
    // `CFRunLoopRemoveSource` is thread-bound, so tearing down from a foreign thread is not
    // safe. Degrade instead of die, the same call `ThreadGuardedValue.deinit` made: log and
    // leak the CF objects. Killing the window manager because the user quit an app at an
    // awkward moment is a far bigger problem than a handful of leaked CF objects.
    guard axThreadToken == axTaskLocalAppThreadToken else {
      debugLog("AxSubscription deinited off its AX thread (owning run loop gone); CF objects intentionally leaked")
      return
    }
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(obs), .defaultMode)
    for notifKey in notifKeys {
      AXObserverRemoveNotification(obs, ax, notifKey as CFString)
    }
  }
}

typealias HandlerToNotifKeyMapping = [(AXObserverCallback, [String])]
