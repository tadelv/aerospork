extension Optional {
    public func orDie(
        _ message: String = "",
        file: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        function: String = #function,
    ) -> Wrapped {
        self ?? dieT("orDie: " + message, file: file, line: line, column: column, function: function)
    }

    public func orFailure<F: Error>(_ or: @autoclosure () -> F) -> Result<Wrapped, F> {
        if let ok = self {
            return .success(ok)
        } else {
            return .failure(or())
        }
    }

    /// Spelled out with `@MainActor` on both the function and the closure, rather than reusing a
    /// non-isolated generic: a non-isolated generic cannot accept an isolated closure, so it would
    /// demand every caller's body be `nonisolated`, which none of them are. Collapsible once
    /// `isolated (any Actor)? = #isolation` can be applied to a *closure parameter* rather than only
    /// to the function. (The non-isolated twins this used to sit beside had no callers and are gone.)
    @MainActor
    public func flatMapAsyncMainActor<E, U>(_ transform: @MainActor (Wrapped) async throws(E) -> U?) async throws(E) -> U? where E: Error, U: ~Copyable {
        if let ok = self {
            return try await transform(ok)
        } else {
            return nil
        }
    }

    public func asList() -> [Wrapped] {
        if let ok = self {
            return [ok]
        } else {
            return []
        }
    }

    public var prettyDescription: String {
        if let unwrapped = self {
            return String(describing: unwrapped)
        }
        return "nil"
    }
}
