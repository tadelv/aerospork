import Common

/// Starts fire-and-forget work whose failures are logged rather than silently dropped.
///
/// Every caller is an event handler -- an NSWorkspace notification, an AX notification, a menu bar
/// button, a hotkey -- that has to hand off to an async refresh session and return immediately.
/// There is nothing to await the result with, so these were written as bare `Task { try await … }`.
///
/// The compiler warns about exactly that: *"unstructured throwing task … is not used, which may
/// accidentally ignore errors thrown inside the task"*. It is right. `_ = Task { … }` would silence
/// the warning while keeping the defect, so instead the two outcomes are separated:
///
///   * `CancellationError` is **expected and silent**. `runSession` begins by cancelling whatever
///     refresh is in flight, so a superseded session throwing is the normal steady state at any
///     interesting event rate -- logging it would be noise, at up to 20 Hz.
///   * anything else is a real failure that previously vanished with no trace anywhere, and is now
///     a persisted `.error` record (see `AppLog`).
///
/// `label` is a `StaticString` so a call site cannot smuggle in an expensive interpolation.
///
/// Deliberately NOT `@MainActor` itself: every caller is a nonisolated notification or event
/// handler, and the hop belongs inside, exactly as the `Task { @MainActor in … }` it replaces did.
func runDetached(_ label: StaticString, _ operation: @escaping @MainActor () async throws -> ()) {
    Task { @MainActor in
        do {
            try await operation()
        } catch is CancellationError {
            // Superseded by a newer session. Expected.
        } catch {
            AppLog.session.error("\(label, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
