import Common

final class ThreadGuardedValue<Value>: Sendable {
    private nonisolated(unsafe) var _threadGuarded: Value?
    private let threadToken: AxAppThreadToken = axTaskLocalAppThreadToken ?? dieT("axTaskLocalAppThreadToken is not initialized")
    init(_ value: Value) { self._threadGuarded = value }
    var threadGuarded: Value {
        get {
            threadToken.checkEquals(axTaskLocalAppThreadToken)
            return _threadGuarded ?? dieT("Value is already destroyed")
        }
        set(newValue) {
            threadToken.checkEquals(axTaskLocalAppThreadToken)
            _threadGuarded = newValue
        }
    }
    func destroy() {
        threadToken.checkEquals(axTaskLocalAppThreadToken)
        _threadGuarded = nil
    }
    deinit {
        // Was a `check`, i.e. fatal. The value SHOULD have been destroyed on its own thread by
        // `MacApp.destroy()`, but that submits its work with `perform(...waitUntilDone: false)`,
        // which is silently dropped if the app's thread has already left its run loop -- exactly
        // what happens when the app we were observing terminated. Leaking a CFType is a far smaller
        // problem than killing the window manager whenever an app exits at an awkward moment.
        if _threadGuarded != nil {
            debugLog("ThreadGuardedValue<\(Value.self)> deinited without being destroyed on its thread")
        }
    }
}
