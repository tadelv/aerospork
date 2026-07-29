<div align="center">

<img src="docs/assets/readme-banner.png" alt="AeroSpork — an i3-like tiling window manager for macOS" width="820">

<p>
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-000?logo=apple&logoColor=white">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="legal/LICENSE.txt"><img alt="MIT" src="https://img.shields.io/badge/license-MIT-blue"></a>
</p>

</div>

AeroSpork is an i3-style tiling window manager for macOS. Windows are leaves of a layout tree,
workspaces are emulated rather than mapped onto native Spaces, and nothing requires disabling System
Integrity Protection. It is configured in TOML, driven from a CLI, and ships a settings GUI.

It is a fork of [AeroSpace](https://github.com/nikitabobko/AeroSpace) by Nikita Bobko, which is
where the tree model, the workspace emulation and most of the command surface come from. Both are
MIT licensed; see [`legal/`](legal/).

<div align="center">
  <img src="docs/assets/layout-modes.png" alt="Tiles layout beside accordion layout" width="820">
</div>

## Why this fork exists

On 2025-07-07 the author opened
[nikitabobko/AeroSpace#1526](https://github.com/nikitabobko/AeroSpace/pull/1526) ("Major
Enhancements"): 4,515 added lines across 41 files, proposing two things: hardware-based monitor
fingerprinting for persistent workspace assignment, and a set of performance optimizations. It was
closed on 2025-07-08 with no review comment. AeroSpork is the fork that followed.

Monitor identity is still the fork's main concern: hardware matching that holds up across USB docks
and identical panels. A configuration surface that does not require memorizing a schema came later,
and the PR did not propose it.

## Tech stack

| Concern | Implementation |
|---|---|
| Language | Swift, 6.0 language mode (`Package.swift`); `.swift-version` pins toolchain 6.4 |
| Minimum OS | macOS 13.0 (Ventura) |
| UI | SwiftUI: a `MenuBarExtra` and a `Settings` scene |
| Third-party dependencies | TOMLKit (config parsing) and Sparkle (in-app updates) |
| CLI/app IPC | POSIX `AF_UNIX` stream socket, length-prefixed framing (`Sources/Common/util/UnixSocket.swift`) |
| Global hotkeys | Carbon `RegisterEventHotKey` (`config/HotkeyBinding.swift`) |
| Volume control | CoreAudio (`util/SystemVolume.swift`) |
| Display identity | CoreGraphics `CGDisplayCreateUUIDFromDisplayID`, `CGDisplayVendorNumber`, `CGDisplayModelNumber`, `CGDisplaySerialNumber` |
| Window IDs | C shim over the private `_AXUIElementGetWindow` (`Sources/PrivateApi/`) |
| Build | SwiftPM for the CLI and debug builds; XcodeGen plus `xcodebuild` for the `.app`, since SwiftPM cannot produce a bundle |

Relative to the fork point, BlueSocket, HotKey, ISSoundAdditions, swift-collections and the
ANTLR-generated shell grammar are gone; see [`legal/`](legal/) for the full list.
`exec-and-forget` hands its string to `/bin/bash -c`.

```
Sources/
├── aerosporkApp/    # app entry point (@main)
├── AppBundle/       # the window manager: tree/, layout/, command/, config/, model/, mouse/, ui/
├── Cli/             # command-line client
├── Common/          # shared with the CLI, incl. the socket implementation
└── PrivateApi/      # C shim for _AXUIElementGetWindow
```

## Differences from AeroSpace

The tree model, virtual workspaces, SIP-free operation, TOML config and the CLI are inherited and
behave the same way. Only the deltas are listed.

| | AeroSpace | AeroSpork |
|---|:---:|:---:|
| Monitor matching by hardware UUID / EDID | ❌ &nbsp;name, regex or number only | ✅ &nbsp;also pins DisplayLink panels |
| Settings GUI | ❌ &nbsp;"will never provide a GUI for configuration" | ✅ &nbsp;7 tabs |
| Notarized builds | ❌ | ✅ &nbsp;signed, notarized, stapled |
| Third-party dependencies | 4 | **2** |
| Config schema | one syntax | v2 shorthand, older syntax still parses |
| Command surface | **larger** | smaller |
| Maturity | **public beta, larger community** | younger fork |

<sub>Upstream column checked against
<a href="https://github.com/nikitabobko/AeroSpace">nikitabobko/AeroSpace</a> <code>main</code> on 2026-07-29: its README
says AeroSpace "will never provide a GUI for configuration" and that "it's not notarized", its
<code>Package.swift</code> declares four dependencies, and its guide documents monitor patterns as
main/secondary/number/regex only.</sub>

**Monitor identity.** A display is matched on, in order of reliability, the stable per-display UUID,
then EDID vendor/model/serial read from CoreGraphics, then the localized name, then size. DisplayLink
panels expose no EDID at all, so the UUID is the only key that can distinguish two identical ones.
Screen reconfiguration is debounced, because a DisplayLink dock connects in several stages.

**Config schema.** `mod` plus `workspaces` generates the usual i3 keymap, and `[keys]`, `[monitors]`
and `[on-window]` replace the longer upstream spellings. An existing config is migrated once on
first launch, and only when the result is proven to parse to the same effective configuration;
otherwise the file is left alone. The original is kept beside it as `*.pre-v2`.

**Settings GUI.** Seven tabs over a comment-preserving writer that only rewrites the keys you
changed, so opening Settings and changing nothing leaves the file byte-identical and editing one
section never rewrites another. A raw TOML tab validates against the same parser the app uses at
startup, so no config key is unreachable from the GUI.

**Performance.** Two structural changes: accessibility events are coalesced by a fixed 50ms debounce
(`util/RefreshDebouncer.swift`) into a single layout pass, and AX position/size writes are skipped
for a window already at its target frame, which matters over DisplayLink where every write repaints a
framebuffer. No speedup percentages are claimed for either; `dev-docs/performance.md` records which
measurements exist and why the available benchmark could not resolve the rest.

### Coming from AeroSpace

A fork, not a drop-in replacement. Configs and scripts need small edits.

- `AEROSPACE_*` environment variables are gone and not aliased. A script reading
  `$AEROSPACE_FOCUSED_WORKSPACE` gets an empty string with no error. The names are
  `AEROSPORK_FOCUSED_WORKSPACE`, `AEROSPORK_PREV_WORKSPACE`, `AEROSPORK_WINDOW_ID` and
  `AEROSPORK_WORKSPACE`.
- `if.during-aerospace-startup` is spelled `if.during-aerospork-startup`. Unknown keys are fatal, so
  the old spelling fails at startup and names the line.
- Feature parity is a non-goal. The fork carries less surface area than upstream.

## Installation

Download the notarized universal (arm64 + x86_64) build from the
[releases page](https://github.com/wbsmolen/aerospork/releases), move `AeroSpork.app` to
`/Applications`, and grant Accessibility permission when prompted. A Homebrew cask is published at
[`wbsmolen/tap`](https://github.com/wbsmolen/homebrew-tap):

```bash
brew install --cask wbsmolen/tap/aerospork
```

Both repositories are private during early release, so the cask and the release download both
require an account with access.

## Configuration

AeroSpork reads whichever of these exists, and reports an error at startup if both do:
`~/.aerospork.toml` or `${XDG_CONFIG_HOME}/aerospork/aerospork.toml` (`XDG_CONFIG_HOME` defaults to
`~/.config`). With neither, it falls back to a complete default bundled in the app, also checked in
as [`docs/config-examples/default-config.toml`](docs/config-examples/default-config.toml). Saved
changes hot-reload, so you never need to run `reload-config` by hand.

```toml
mod = "alt"                 # generates the i3 keymap: alt-h/j/k/l, alt-shift-h/j/k/l, ...
workspaces = "1-9"          # alt-1..9 to switch, alt-shift-1..9 to move a window

[gaps]
inner = 8
outer = 8

[keys]                      # anything here overrides a generated binding
alt-enter = "exec-and-forget open -na Ghostty"

[monitors]                  # pin a workspace to a screen
1 = "main"
2 = { uuid = "AAAAAAAA-0000-4000-8000-000000000001" }

[on-window]                 # where a window goes when it appears
"com.apple.mail" = "move-node-to-workspace 3"
```

Run `aerospork list-monitors --format '%{monitor-fingerprint}'` to get the values to paste into
`[monitors]`. Open the GUI from the menu bar icon, with **⌘,** while AeroSpork is frontmost, or via
`aerospork open-settings`, which is also valid in config and so bindable. Structured tabs apply live
on a 600ms debounce; the raw TOML tab has an explicit Apply, because half-typed TOML is invalid most
of the time.

## CLI

36 subcommands, with man pages and bash/fish/zsh completion. `exec-and-forget` is documented as a
37th command but is config-only.

```bash
aerospork focus left                        # focus the window to the left
aerospork workspace 1                       # switch workspace
aerospork move-node-to-workspace 2          # move the focused window
aerospork layout tiles horizontal vertical  # cycle layout
aerospork list-monitors                     # connected displays and how they are identified
aerospork --help
```

Troubleshooting: `aerospork config --config-path` prints the file actually loaded. A path inside the
`.app` bundle means no user config is loaded, either because you have none or because yours failed to
parse; `aerospork reload-config --dry-run` says which.
`aerospork reload-config --dry-run` parses without applying and says why not, and `aerospork
--version` reports both client and server. Logs go to the unified log, with no files and nothing to
enable:

```bash
log show --last 1h --predicate 'subsystem == "com.wbs.aerospork"' --style compact
```

Use `com.wbs.aerospork.debug` for a debug build and add `AND category == "config"` to narrow.
`AEROSPORK_DEBUG_LOG=1` adds a verbose per-refresh trace, which goes to stderr rather than the
unified log, so run the binary directly to read it. See *Troubleshooting and bug reports* in
[the guide](docs/guide.adoc) for what to attach to a report.

## Development

```bash
./build-debug.sh     # SwiftPM debug build into .debug/ (uses ~/.aerospork-debug.toml)
./build-release.sh   # signed release; needs a Developer ID Application certificate
./run-tests.sh       # tests, format and lint
./build-docs.sh      # man pages and docs site
```

The suite is headless, using a fake window tree and a mocked Accessibility layer, so it needs no real
windows and no Accessibility permission. `Package.swift` uses SE-0439 trailing commas, so the floor is
Swift 6.1 (Xcode 16.3); `.swift-version` pins 6.4 for reproducibility.

[`.claude/skills/aerospork-design/`](.claude/skills/aerospork-design/) holds the design system:
tokens, components, three click-through UI kits and the brand artwork. It is derived from
`Sources/AppBundle/ui/`, so the Swift is the source of truth. Read it before adding a settings
surface. `UIChromeConsistencyTest` enforces the two rules that matter: shared controls live in
[`SettingsChrome.swift`](Sources/AppBundle/ui/SettingsChrome.swift) and a tab never grows its own
copy, and status symbols come from `StatusLabel.Kind` rather than string literals.

[`CONTRIBUTING.md`](CONTRIBUTING.md) covers the gate and the invariants the tests enforce.
[`dev-docs/`](dev-docs/) has architecture notes, contributor setup including code signing, testing
strategy and performance measurement.

## License

MIT. The original AeroSpace copyright is retained alongside the fork's in
[`legal/LICENSE.txt`](legal/LICENSE.txt). Active development; features and configuration may still
change.
