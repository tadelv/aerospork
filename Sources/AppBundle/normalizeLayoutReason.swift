@MainActor
func normalizeLayoutReason() async throws {
  for workspace in Workspace.all {
    try checkCancellation()
    let windows: [Window] = workspace.allLeafWindowsRecursive
    try await _normalizeLayoutReason(workspace: workspace, windows: windows)
  }
  try await _normalizeLayoutReason(workspace: focus.workspace, windows: macosMinimizedWindowsContainer.children.filterIsInstance(of: Window.self))
  try await validateStillPopups()
}

@MainActor
private func validateStillPopups() async throws {
  for node in macosPopupWindowsContainer.children {
    let popup = (node as! MacWindow)
    if try await popup.isWindowHeuristic() {
      try await popup.relayoutWindow(on: focus.workspace)
      try await tryOnWindowDetected(popup)
    }
  }
}

@MainActor
private func _normalizeLayoutReason(workspace: Workspace, windows: [Window]) async throws {
  // Prefetch both AX reads for every window concurrently. These used to be two sequential
  // `await`s inside the mutation loop, i.e. 2 serialized MainActor<->app-thread round trips per
  // window per refresh, over every window of every workspace -- the dominant cost of a refresh,
  // and enough on its own to exceed the 50ms debounce and cause refresh cancellation thrash.
  // Same fan-out pattern as MacApp.refreshAllAndGetAliveWindowIds. The loop below stays serial
  // because it rebinds tree nodes.
  let states: [(full: Bool, mini: Bool)] = try await withThrowingTaskGroup(of: (Int, Bool, Bool).self) { group in
    for (i, window) in windows.enumerated() {
      group.addTask { @Sendable @MainActor in
        // One hop per window, not two. `macosNativeState` reads both flags inside a single
        // `runInLoop` and keeps the same short-circuit (a fullscreen window is never asked
        // whether it is minimized).
        let state = try await window.macosNativeState()
        return (i, state.fullscreen, state.minimized)
      }
    }
    var result = [(full: Bool, mini: Bool)](repeating: (false, false), count: windows.count)
    for try await (i, full, mini) in group { result[i] = (full, mini) }
    return result
  }

  for (i, window) in windows.enumerated() {
    // The `.standard` branch below is entirely synchronous, so without this a cancelled
    // refresh rebound the whole tree instead of stopping at the first window.
    try checkCancellation()
    // An earlier iteration's await may have let a concurrent session garbage collect this
    // window; binding it below would resurrect a dead node.
    guard window.parent != nil else { continue }

    // Does the prefetched snapshot say we are about to move this window? Everything else is a
    // no-op, and in steady state that is essentially every window -- which is what keeps the
    // re-read below off the hot path. `||` short-circuits, so `macAppUnsafe` is still only
    // touched when the window is neither fullscreen nor minimized, same as before.
    let snapshotIsUnconventional = states[i].full || states[i].mini ||
      (!config.automaticallyUnhideMacosHiddenApps && window.macAppUnsafe.nsApp.isHidden)
    let willMutate = switch window.layoutReason {
      case .standard: snapshotIsUnconventional
      case .macos: !snapshotIsUnconventional
    }
    if !willMutate { continue }

    // Re-read before acting. The snapshot was taken before the loop and the loop releases the
    // main actor on every await (exitMacOsNativeUnconventionalState -> relayoutWindow), so a
    // window can be un-minimized or un-fullscreened underneath us -- and acting on the stale
    // answer binds a now-visible window into the minimized/fullscreen container.
    let fresh = try await window.macosNativeState()
    let isMacosFullscreen = fresh.fullscreen
    let isMacosMinimized = fresh.minimized
    let isMacosWindowOfHiddenApp = !isMacosFullscreen && !isMacosMinimized &&
      !config.automaticallyUnhideMacosHiddenApps && window.macAppUnsafe.nsApp.isHidden
    switch window.layoutReason {
      case .standard:
        guard let parent = window.parent else { continue }
        if isMacosFullscreen {
          window.layoutReason = .macos(prevParentKind: parent.kind)
          window.bind(to: workspace.macOsNativeFullscreenWindowsContainer, adaptiveWeight: WEIGHT_DOESNT_MATTER, index: INDEX_BIND_LAST)
        } else if isMacosMinimized {
          window.layoutReason = .macos(prevParentKind: parent.kind)
          window.bind(to: macosMinimizedWindowsContainer, adaptiveWeight: 1, index: INDEX_BIND_LAST)
        } else if isMacosWindowOfHiddenApp {
          window.layoutReason = .macos(prevParentKind: parent.kind)
          window.bind(to: workspace.macOsNativeHiddenAppsWindowsContainer, adaptiveWeight: WEIGHT_DOESNT_MATTER, index: INDEX_BIND_LAST)
        }
      case .macos(let prevParentKind):
        if !isMacosFullscreen && !isMacosMinimized && !isMacosWindowOfHiddenApp {
          try await exitMacOsNativeUnconventionalState(window: window, prevParentKind: prevParentKind, workspace: workspace)
        }
    }
  }
}

@MainActor
func exitMacOsNativeUnconventionalState(window: Window, prevParentKind: NonLeafTreeNodeKind, workspace: Workspace) async throws {
  window.layoutReason = .standard
  switch prevParentKind {
    case .workspace:
      window.bindAsFloatingWindow(to: workspace)
    case .tilingContainer:
      try await window.relayoutWindow(on: workspace, forceTile: true)
    case .macosPopupWindowsContainer: // Since the window was minimized/fullscreened it was mistakenly detected as popup. Relayout the window
      try await window.relayoutWindow(on: workspace)
    case .macosMinimizedWindowsContainer, .macosFullscreenWindowsContainer, .macosHiddenAppsWindowsContainer: // wtf case, should never be possible. But If encounter it, let's just re-layout window
      try await window.relayoutWindow(on: workspace)
  }
}
