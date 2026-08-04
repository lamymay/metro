# Metro

A from-scratch reconstruction of Windows Phone 8 / Metro's visual language and motion,
built twice — once native on each platform — so the two implementations can be compared
side by side rather than one being a port of the other's abstractions.

```
AppleMetro/     iOS + macOS. SwiftUI. MetroKit is the SPM library; MetroLab is the
                thin app shell that presents it.
AndroidMetro/   Android, minSdk 16. Kotlin, framework View/Canvas, no AndroidX, no
                Compose — deliberately, since 4.1 rules both out and that constraint is
                closer to how WP itself was actually built (Silverlight storyboards
                over a retained visual tree).
```

Each has its own README with the full breakdown of what's implemented — theme/accent
system, easing curves and tilt-press geometry, the tile packer, page transitions,
panorama/pivot, app list semantic zoom, and so on:

- [`AppleMetro/README.md`](AppleMetro/README.md)
- [`AndroidMetro/README.md`](AndroidMetro/README.md)

## What's currently running

Both apps' start screens are presently a dedicated, close recreation of one specific
Lumia Icon ("Denim", Verizon) WP8.1 press photo — fixed 4-column tile grid, matched
colours/glyphs/labels/badges — rather than the generic placeholder tile set the
underlying design systems ship with. That recreation lives outside the reusable
libraries (`AppleMetro/MetroLab/MetroLab/LumiaStartScreen.swift` and
`AndroidMetro/app/.../lumia/LumiaStartScreen.kt`) precisely so the libraries themselves
stay generic.

MetroKit also carries a WP-style year → month calendar (`MetroYearMonthCalendarView`)
under `AppleMetro/MetroKit/Sources/MetroKit/Calendar/` — a year page of twelve mini
month grids that zooms into a full month grid on tap, built to be dropped into any
SwiftUI app as a local or remote Swift package dependency.

## Building

```bash
# iOS — open in Xcode, or:
cd AppleMetro/MetroKit && swift build && swift test
cd AppleMetro/MetroLab && xcodebuild -scheme MetroLab -sdk iphonesimulator build

# Android
cd AndroidMetro && ./gradlew :app:assembleDebug
```
