# Settings redesign v3

This directory records the mock-first redesign that is implemented in `Sources/AppBundle/ui/`.
`foundation.md` is the decision record: a native macOS pane toolbar, compact system layouts, and no
hand-painted imitation of current OS materials. The Swift implementation remains the source of truth
for behavior, accessibility, and deployment compatibility.

## Reviewed mock matrix

The four checked contact sheets under `mockups/` cover every pane at the ideal 880×620 and compact
780×520 window sizes in both system appearances:

- `light-ideal.png`
- `dark-ideal.png`
- `light-compact.png`
- `dark-compact.png`

They are rendered from `.claude/skills/aerospork-design/ui_kits/settings_app/`, whose entry point also
accepts `tab`, `appearance`, `width`, `height`, and `banner` query parameters for individual states.

## Production mapping

- Navigation and window behavior: `ConfigurationWindow.swift`
- Shared controls and AppKit code editor: `SettingsChrome.swift`
- Pane implementations: `ConfigurationTabs/`
- Config projection and debounced persistence: `ConfigurationViewModel.swift`
- Comment-preserving writes and exact diagnostics: `config/ConfigurationWriter.swift`

Automated coverage lives in `UIRenderSmokeTest`, `UISettingsTest`, `UIChromeConsistencyTest`, the
pane-specific UI tests, and `ConfigTest`. The complete gate is `./run-tests.sh`; visual judgment of
the approved mock matrix remains a review step because headless SwiftUI rendering cannot prove native
control pixels.
