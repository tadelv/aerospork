# App icon

The mark is the **layout**, not a letter: one focused pane left, three stacked panes right. Inherited
verbatim from the repo's `generate-app-icon.py`, including the two constraints that shaped it:

- It must read at 16pt in the Finder sidebar. Few, large shapes and generous gaps — the icon before
  it drew a 3×3 line grid, which turned to mush below 32pt.
- macOS icons are squircles with a ~22% corner ratio, and the artwork is **inset**, not full-bleed.
  Here: 5.5% canvas inset, corner radius 22.5% of the plate.

## Layers (Icon Composer order, bottom to top)

| Layer | What it is |
|---|---|
| 1 — Plate | Vertical gradient `#1C202C → #10121A`, squircle, inset 5.5% |
| 2 — Top light | Radial white 20% from 28% / −10%, fading by 62% — the light source |
| 3 — Panes | Focused pane: `#82B7FF → #3D80EA → #2F6ED6` at 170°, plus a top specular wash and a 1px white inner top edge. Dimmed panes: white 17% → 7.5% glass with a white 16% inner border |
| 4 — Rim / bevel | Inset ring: white 14% all round, white 22% top edge, black 50% bottom edge |

Geometry inside the plate: 20% padding, 6.2% gaps, tile radius 4.5% of the plate; the focused pane
takes 56% of the usable width and full height.

## Variants

| File | Use |
|---|---|
| `aerospork-icon-1024.png` | Default (dark plate) — the app icon |
| `aerospork-icon-light-1024.png` | Light plate — for dark documentation backgrounds and light-mode marketing |
| `aerospork-icon-mono-1024.png` | Monochrome / tinted — macOS tinted-icon appearance, print, favicons |
| `AppIcon.appiconset/` | Xcode asset catalog, 16→512 @1x/@2x, generated from the 1024 default |

## Rebuilding

`AppIcon.html` is the specimen (all three variants). `render.html` renders each variant at 1024px
with no outer shadow and a transparent canvas — screenshot `#r-default` / `#r-light` / `#r-mono` at
scale 1, then downsample to the asset-catalog sizes.

**Caveat:** the catalog PNGs are downsampled from 1024. Below 32px the glass detail stops
contributing; if you ship this, redraw 16 and 32 with the specular and rim layers removed. Filenames
use Apple's `@2x` convention and `Contents.json` matches, so the set drops straight into
`resources/Assets.xcassets/`.

## Other brand artwork here

- `Banner.html` → `readme-banner-1280x640.png` — GitHub README / social header.
- `AppStoreHero.html` → `appstore-hero-1440x900.png` — App Store / landing hero, with a schematic
  tiled desktop rather than a real screenshot (App Store screenshots should be real captures; frame
  them with `WindowChrome`).
