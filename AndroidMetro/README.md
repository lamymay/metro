# Metro Lab (Android)

A from-scratch reconstruction of Windows Phone 8 / Metro's visual language and motion on
Android — minSdk 16 (Android 4.1), Kotlin, no AndroidX, no Compose. That's not nostalgia
for its own sake: 4.1 forces every screen to be built out of framework `View`/`Canvas`
and `ViewPropertyAnimator`, which is a closer match to how WP itself was built (Silverlight
storyboards driving plain visual-tree properties) than any modern declarative toolkit
would be.

```
app/src/main/java/com/rakukura/metrolab/
  theme/      MetroTheme, MetroAccent (WP8's 20 stock accents), MetroRole (type ramp)
  motion/     MetroEase (exact easing-function port), MetroMotion (live tunable config),
              TiltController (the WP tilt press), MetroFeather (staggered entrance)
  glyph/      MetroGlyphs — 27 hand-drawn Path-based icons, no font/asset dependency
  tile/       TileModel/TilePacker (first-fit, same algorithm as WP's start screen),
              TileView (Canvas-drawn tile incl. flip/slide via a Camera transform),
              StartScreenView (the packed grid, a custom ViewGroup)
  nav/        PageHost — back stack with turnstile/slide/swivel/continuum transitions
  pivot/      PivotView — header leads, content lags (that offset is the whole trick)
  panorama/   PanoramaView — three-layer parallax (background/title/sections)
  applist/    AppListView — alphabetical list with semantic-zoom letter grid
  widget/     Buttons, toggle, slider, text box, app bar, list row, progress dots/ring
  lab/        The pages that make up the demo app + shared sample data
```

## Building

```bash
./gradlew :app:assembleDebug
```

Needs a JDK 17 (AGP 8 requirement) — `gradle.properties` points `org.gradle.java.home`
at a bundled JBR; Android Studio ignores that line and uses its own. `minSdk 16` /
`compileSdk 34` / `targetSdk 34`, Kotlin 1.9, AGP 8.3.

No runtime dependencies beyond the Kotlin stdlib — there is nothing in `dependencies {}`
in `app/build.gradle.kts`. That's the direct consequence of minSdk 16: Compose needs 21+,
current AndroidX artifacts are 21+, so the only way to genuinely support 4.1 is to not
depend on either.

## Design notes

- **Why no AndroidX/Compose**: the two things are the same decision. Given "must run on
  4.1", Canvas + View is not a compromise — it's also the mechanically honest way to
  reproduce a UI language built on retained-mode visual trees and storyboard easing
  functions rather than a modern recomposition model.
- **TiltController** (`motion/TiltController.kt`) ports `Microsoft.Phone.Controls.TiltEffect`
  exactly: touch position normalises to -0.5…0.5, the two magnitudes split the total tip
  angle between the axes, a dead-centre press produces depression with zero rotation.
  Attach it to any `View` and the view needs no touch code of its own.
- **PageHost** (`nav/PageHost.kt`) chains an exit animation into an entry animation rather
  than cross-fading — WP ran the outgoing storyboard, waited, then ran the incoming one,
  and the incoming page's opacity is a hard step to 1, not a fade. Cross-fading is the
  fastest way to make this read as an Android activity transition instead of Metro.
- **TilePacker** (`tile/Tile.kt`) is first-fit over a 2D occupancy grid, scanning
  left-to-right then down — the same algorithm the WP start screen used, which is why a
  wide tile can leave a pair of small holes that later small tiles backfill.

## Known simplifications

- Panorama and pivot clamp at both ends; WP wrapped infinitely.
- `MetroTransition.CONTINUUM` has no shared-element handoff — it's a rise + scale
  approximation, same as the iOS side.
- Segoe WP itself isn't bundled (non-redistributable); `sans-serif-light` stands in for
  the light/semilight cuts, which is available from API 16 onward.

See also: `../apple/` — the same catalogue, in SwiftUI for iOS 15+/macOS 15+, so the two
apps compare side by side.
