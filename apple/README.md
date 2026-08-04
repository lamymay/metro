# MetroKit / MetroLab

A from-scratch reconstruction of Windows Phone 8 / Metro's visual language and motion —
not a UIKit/SwiftUI skin, but the actual mechanics: the tilt press, the turnstile page
transition, the feathered entrance, the panorama's three-layer parallax, the pivot's
lagged content, live tiles that flip and slide.

```
MetroKit/     SPM library. iOS 15+, macOS 15+. Everything lives here.
MetroLab/     Thin Xcode app shell — one file, presents MetroKit's lab UI.
```

Open `MetroLab/MetroLab.xcodeproj` in Xcode; it resolves `MetroKit` as a local package
dependency. `swift test` from `MetroKit/` runs the unit tests (easing curves, the tile
packer, tilt geometry) without touching a simulator.

## Layout

- **Theme** — the 20 stock WP8 accents at their shipping hex values, the WP type ramp
  (`MetroTextRole`), light/dark, and `MetroMetrics` (the grid solves for one tile's side
  against whatever width it's given).
- **Motion** — `MetroEase` is an exact port of Silverlight's easing functions (not a
  bezier approximation) plus a bezier *fit* for driving SwiftUI's animation system.
  `MetroMotion` holds every timing constant as a live, mutable config. `TiltEffect.swift`
  is the WP tilt press, geometrically exact (corner press = full angle on both axes,
  centre press = depression only, no rotation).
- **Tiles** — `MetroTile` + `MetroTileGrid` + `MetroTilePacker` (first-fit packer, same
  algorithm the WP start screen used — a wide tile can leave holes small tiles fill
  later).
- **Navigation** — `MetroPage`, `MetroNavigationView` (turnstile/slide/swivel/continuum
  transitions, driven off a route stack), `MetroFeather` (the staggered entrance).
- **Panorama / Pivot** — three-speed parallax; header-leads-content lag.
- **Controls / AppBar / AppList** — buttons, toggle, slider, text box, the WP app bar
  (icons + overflow menu), and the app list's semantic-zoom letter grid.
- **Lab** — `MetroLabRoot` is the whole demo app: a start screen whose pinned tiles open
  motion/type/accent/transition/panorama/pivot pages, all editable live via sliders in
  the Motion page.

## Known simplifications

- Panorama and pivot clamp at both ends; WP wrapped infinitely.
- `MetroTransitionKind.continuum` has no shared-element handoff (no source item to
  animate from) — it's a rise + scale approximation.
- Segoe WP itself isn't bundled (non-redistributable). `MetroFontFamily.system` is the
  default; drop the real files into `Sources/MetroKit/Resources/Fonts` and switch to
  `.segoeWP` to get the shipping typeface — the kit checks for it and falls back cleanly
  if it isn't installed.

See also: `../android/` — the same catalogue, ported to Kotlin/Android views for
minSdk 16, so the two apps compare side by side.
