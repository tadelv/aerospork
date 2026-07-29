---
name: aerospork-design
description: Use this skill to generate well-branded interfaces and assets for AeroSpork, either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for protoyping.
user-invocable: true
---

Start with **`readme.md`** in this directory — it carries the content fundamentals (voice, casing,
error copy) and the visual foundations, and it is the part worth matching before any pixel. Then
explore the rest; `_ds_manifest.json` indexes every component, card and token.

Note the filename case: `readme.md` here is lowercase, while the per-directory `README.md` files
under `assets/icon/` and `ui_kits/*/` are uppercase.

## Which half of this you need

**Prototypes, mocks, slides, marketing.** Work in the web layer. Copy assets out and write static
HTML; `styles.css` pulls in every token, and `_ds_bundle.js` exposes the components on
`window.AeroSporkDesignSystem_078bd7`. Serve over HTTP rather than opening `file://` — the UI kits
load their `.jsx` through Babel, and a `file://` origin blocks that fetch, leaving a blank page.

**Production code.** The web components are a *recreation* of the shipping SwiftUI, not a source of
truth for it. The real product is:

| This skill | Production |
|---|---|
| `components/{controls,layout,feedback}/*` | `Sources/AppBundle/ui/SettingsChrome.swift` |
| `ui_kits/settings_app/*Tab.jsx` | `Sources/AppBundle/ui/ConfigurationTabs/*.swift` |
| `components/brand/WorkspaceChips.jsx` | `Sources/AppBundle/ui/MenuBarLabel.swift` |
| `components/layout/MenuPanel.jsx` | `Sources/AppBundle/ui/MenuBar.swift` |
| `assets/icon/AppIcon.appiconset/` | `resources/Assets.xcassets/AppIcon.appiconset/` |

Two rules hold on the Swift side, and `UIChromeConsistencyTest` enforces them:

- **Shared chrome lives in `SettingsChrome.swift`.** If a tab needs a badge, a status readout, a
  hint, a +/- strip or an empty state, it uses the one that is already there. Growing a local copy
  is how the window previously ended up with two badges at two different paddings.
- **Status symbols and tints come from `StatusLabel.Kind` / `Banner.Kind`**, never as string
  literals in a tab. Red and green are the most confusable pair on screen, so which symbol carries
  which meaning is decided once.

Use SF Symbol names in Swift. The `Icon` component's Lucide shapes are a substitution for the web
only — SF Symbols cannot be redistributed, and a few (`display.2`, `rectangle.inset.filled`) are
loose matches.

If the user invokes this skill with no other guidance, ask what they want to build, then act as an
expert designer who outputs either HTML artifacts or production code, depending on the need.
