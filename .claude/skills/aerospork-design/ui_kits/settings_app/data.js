// Mock state for the AeroSpork Settings recreation. Values match the shipped default config.
window.AS_DATA = {
  // Gaps pane: whether any of the six gaps currently carries a per-monitor rule in Raw TOML.
  // Off by default so the common (flat-numbers) case shows no extra chrome.
  gapsHavePerMonitorOverrides: false,
  // `rect` is topLeftX/topLeftY/width/height in points, same shape and units as
  // Sources/AppBundle/model/Monitor.swift's `rect` — what MonitorArrangement draws to scale.
  // This arrangement (bottom-aligned, the laptop propped lower than the two externals) is a
  // realistic one, not an idealized row of equal-height rectangles, on purpose: it's the case
  // "Position 2" as a bare number hides and a diagram doesn't.
  monitors: [
    { id: 'm1', name: 'Built-in Retina Display', resolution: '1728 × 1117 pt', uuid: 'BBBBBBBB-0000-4000-8000-000000000002', isMain: true, rect: { x: 0, y: 323, width: 1728, height: 1117 } },
    { id: 'm2', name: 'DELL U2720Q', resolution: '2560 × 1440 pt', uuid: 'AAAAAAAA-0000-4000-8000-000000000001', rect: { x: 1728, y: 0, width: 2560, height: 1440 } },
    { id: 'm3', name: 'DisplayLink Monitor', resolution: '1920 × 1080 pt', uuid: 'CCCCCCCC-0000-4000-8000-000000000003', rect: { x: 4288, y: 360, width: 1920, height: 1080 } },
  ],
  // What `workspaces = [...]` defines after range expansion — the pin menu offers the unpinned ones.
  workspaces: ['1', '2', '3', 'web', 'media', 'chat'],
  assignments: [
    { id: 'a1', workspace: '1', monitor: 'main' },
    { id: 'a2', workspace: 'web', monitor: 'AAAAAAAA-0000-4000-8000-000000000001' },
    { id: 'a3', workspace: 'media', monitor: 'DELL U2720Q', complex: true },
  ],
  bindings: {
    main: [
      { id: 'g1', key: 'alt-h', command: 'focus left', origin: 'generated' },
      { id: 'g2', key: 'alt-j', command: 'focus down', origin: 'generated' },
      { id: 'g3', key: 'alt-k', command: 'focus up', origin: 'generated' },
      { id: 'g4', key: 'alt-l', command: 'focus right', origin: 'generated' },
      { id: 'g5', key: 'alt-shift-h', command: 'move left', origin: 'generated' },
      { id: 'g6', key: 'alt-minus', command: 'resize smart -50', origin: 'generated' },
      { id: 'g7', key: 'alt-slash', command: 'layout tiles horizontal vertical', origin: 'generated' },
      { id: 'g8', key: 'alt-tab', command: 'workspace-back-and-forth', origin: 'generated' },
      { id: 'e1', key: 'alt-shift-semicolon', command: 'mode service', origin: 'explicit' },
      { id: 'e2', key: 'alt-enter', command: 'exec-and-forget open -na Ghostty', origin: 'explicit' },
    ],
    service: [
      { id: 's1', key: 'esc', command: 'reload-config ; mode main', origin: 'explicit' },
      { id: 's2', key: 'r', command: 'flatten-workspace-tree ; mode main', origin: 'explicit' },
      { id: 's3', key: 'f', command: 'layout floating tiling ; mode main', origin: 'explicit' },
      { id: 's4', key: 'backspace', command: 'close-all-windows-but-current ; mode main', origin: 'explicit' },
    ],
    // A small, single-category mode (all "Mode & system") — demonstrates Change A's flat-list
    // path, and its 'esc'/Ghostty overlap with main and service demonstrates Change B/C's
    // multi-mode branches (2+ other modes matching a search or a recorded key).
    apps: [
      { id: 'p1', key: 'esc', command: 'mode main', origin: 'explicit' },
      { id: 'p2', key: 'o', command: 'exec-and-forget open -na Ghostty', origin: 'explicit' },
      { id: 'p3', key: 's', command: 'exec-and-forget open -na Safari', origin: 'explicit' },
    ],
  },
  // r1-r3 are known sample apps (AppIcon.jsx's SAMPLE_APPS) so their rows carry a real glyph.
  // r4 has no app-id matcher at all ("any app") and r5 names an app outside the sample set, so
  // between them the mock demonstrates every AppIcon fallback: known glyph, generic "any app",
  // and a monogram for an app nobody hardcoded an icon for.
  rules: [
    { id: 'r1', appId: 'com.apple.mail', appNameRegex: '', windowTitleRegex: '', workspace: '', run: 'move-node-to-workspace 3', checkFurther: false, duringStartup: false },
    { id: 'r2', appId: 'com.apple.systempreferences', appNameRegex: '', windowTitleRegex: '', workspace: '', run: 'layout floating', checkFurther: false, duringStartup: false },
    { id: 'r3', appId: 'com.spotify.client', appNameRegex: '', windowTitleRegex: '', workspace: '', run: 'move-node-to-workspace media', checkFurther: false, duringStartup: true },
    { id: 'r4', appId: '', appNameRegex: '', windowTitleRegex: 'Picture[- ]in[- ]Picture', workspace: '', run: 'layout floating', checkFurther: true, duringStartup: undefined },
    { id: 'r5', appId: 'org.mozilla.firefox', appNameRegex: '', windowTitleRegex: '', workspace: '', run: 'layout floating ; move-node-to-workspace web', checkFurther: false, duringStartup: undefined },
  ],
  events: {
    afterStartup: ['exec-and-forget sketchybar --reload'],
    workspaceChanged: ['move-mouse window-lazy-center'],
    monitorChanged: [],
    focusChanged: [],
  },
  env: [{ id: 'v1', name: 'PATH', value: '/opt/homebrew/bin:/usr/bin:/bin' }],
  toml: [
    '# AeroSpork — tiling window manager for macOS',
    '',
    'mod = "alt"',
    'workspaces = "1-9"',
    '',
    '[gaps]',
    'inner = 8',
    'outer = { top = 32, bottom = 8, left = 8, right = 8 }',
    '',
    '[keys]',
    'alt-shift-semicolon = "mode service"',
    'alt-enter = "exec-and-forget open -na Ghostty"',
    '',
    '[keys.service]',
    'esc = ["reload-config", "mode main"]',
    'r = ["flatten-workspace-tree", "mode main"]',
    '',
    '[monitors]',
    '1 = "main"',
    'web = { uuid = "AAAAAAAA-0000-4000-8000-000000000001" }',
    '',
    '[on-window]',
    '"com.apple.mail" = "move-node-to-workspace 3"',
  ].join('\n'),
};
