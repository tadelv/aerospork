# Redesign v3 — native macOS foundation

## Decision

AeroSpork Settings remains a compact, resizable preferences window with a persistent pane toolbar.
It does not become a System Settings-style sidebar. General, Gaps, Keys, Monitors, Events, Window
Rules, and Raw TOML are peer destinations represented by an SF Symbol above a short label, using a
native `TabView`. The selected pane is remembered and its title becomes the window title.

This is the established macOS settings-window pattern for a small, fixed set of preference panes.
A sidebar would spend 180 points permanently on seven destinations, force a 20% wider minimum, and
make the app look like a document browser despite having no hierarchy. The pane toolbar preserves
the approved 880×620 ideal and 780×520 minimum sizes.

## Materials and hierarchy

Liquid Glass belongs to controls and navigation chrome supplied by the system. It is not a content
background. In production the toolbar, path bar, and action bars use native system materials and
controls; forms, tables, and editors stay opaque and readable. The mock kit approximates these
materials only so browser captures communicate hierarchy.

Content uses grouped forms, inset tables, hairline separators, semantic system colours, continuous
corners, and SF Symbols. Cards have no decorative drop shadow. Pane-level display titles were
removed because the selected toolbar item and window title already provide that hierarchy. General
stays a single scrolling form rather than a two-column dashboard.

The UI should remain visually at home on macOS 13 through 27. Newer system rendering is inherited
from native SwiftUI/AppKit controls at runtime; no availability-specific imitation of Liquid Glass
is painted on older releases.

## Interaction model

- Structured settings save after the existing 600 ms debounce. There is no global Save button.
- Lists use native selection, deletion commands, and one shared icon-button accessibility contract.
- Empty panes teach the feature and provide the next action.
- Compact height scrolls content while navigation and action bars remain available.
- Raw TOML is the explicit escape hatch: it validates after typing settles, supports native Find,
  shows line numbers and cursor position, provides restrained quote-aware syntax highlighting and
  section navigation, and marks and jumps to a parser diagnostic.
- Every addition preserves config spellings the structured editor cannot represent; such values are
  marked as generated, complex, custom, or per-monitor rather than silently flattened.

## Pane changes

- **General:** clearer startup, layout, and menu bar/Dock consequences.
- **Gaps:** linked inner/outer controls, a live schematic, and a warning before a structured edit
  replaces per-monitor values.
- **Keys:** category browsing, global cross-mode search, duplicate/override actions, and conflict
  awareness in the composer.
- **Monitors:** a true-to-arrangement schematic, left-to-right positions, the main-display state,
  position/name/exact-display picker options, and an explicit complex-value marker.
  *Revised after live 4-monitor use:* the schematic is now the monitor selector (click to select,
  detail strip with UUID copy and pinned-workspace chips, a "Pin a workspace here" menu), the
  redundant monitor list is gone, and the assignments table is the single scroll authority. The
  contact sheets below predate this revision for the Monitors pane; the kit's `MonitorsTab.jsx`
  is its current reference.
- **Events:** execution order, real command examples, inherited-environment consequences, and the
  documented PATH example.
- **Window Rules:** an application chooser, all three startup timing states, guided layout/workspace
  actions, and an exact-command fallback for custom rules.
- **Raw TOML:** native code-editor behavior, section navigation, and actionable diagnostics without
  a third chrome strip.

## Mock verification

The browser kit accepts `tab`, `appearance`, `width`, and `height` query parameters. Every pane is
checked in light and dark appearances at 880×620 and 780×520. The compact state is a constraint
test, not a scaled-down composition: content scrolls rather than clipping fixed chrome.

The checked contact sheets are `mockups/{light,dark}-{ideal,compact}.png`. They are the approved
pre-implementation reference; production stays authoritative for behavior and accessibility.

Resizability shipped later than this document first claimed: a SwiftUI `Settings` scene defaults
to locking the window at its ideal size, so until `.windowResizability(.contentMinSize)` was added
to the scene, the 780×520 minimum was theoretical. Settings windows do not autosave their frame —
the window reopens at the 880×620 ideal — and macOS 13.0–13.2 resizability behavior is untested.
