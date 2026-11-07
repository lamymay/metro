# MetroKit / MetroLab

A from-scratch reconstruction of Windows Phone 8 / Metro's visual language and motion —
not a UIKit/SwiftUI skin, but the actual mechanics: the tilt press, the turnstile page
transition, the feathered entrance, the panorama's three-layer parallax, the pivot's
lagged content, live tiles that flip and slide.

## Modules

Five sibling SPM packages plus the app shell. iOS 17+, macOS 14+.

```
MetroLab/        Xcode app shell — the main entry (LumiaStartScreen) and the lab screens.
├── MetroKit/       UI framework: tiles, theme, motion, icons, controls,
│                   navigation, pivot/panorama, app list, settings. No dependencies.
├── MetroMusic/     WP-recreation music player.        -> MetroKit, Player
├── MetroPhotos/    WP-recreation photos hub.          -> MetroKit
├── MetroCalendar/  WP-recreation year/month calendar. -> MetroKit
└── Player/         Native player UI ported from the sibling `player` app. -> GRDB
```

`MetroKit` is the base every feature module builds on; feature modules never depend on
each other. Anything two of them need (the album-art generator, `MetroDateHelper`)
lives in `MetroKit` rather than being cross-imported — that rule is what keeps the
graph a tree.

Open `MetroLab/MetroLab.xcodeproj` in Xcode; it resolves all five as local package
dependencies. `swift build`/`swift test` works inside any package on its own —
`MetroKit/` carries the unit tests (easing curves, the tile packer, tilt geometry) and
runs without touching a simulator.

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
- **Settings** — the WP settings list, the pull-down Action Center, and the accent/type
  picker (`MetroAccentLab`) that Settings → theme routes to.
- **Lab** (in the app shell, not the kit) — `MetroLabRoot` is a developer start screen
  whose pinned tiles open motion/type/accent/transition/panorama/pivot pages, all
  editable live via sliders in the Motion page. It lives in `MetroLab/` because it
  references every feature module; keeping it in `MetroKit` would invert the graph.

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
