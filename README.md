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
建议以本文为准更新这两篇，或直接标注为历史版本。

Player (existing, from the other app)  ─┐
├──► MetroMusic  ─┐
MetroKit  (磁贴 + 主题/动效/图标/控件/导航/Pivot)──┼──► MetroPhotos ─┼──► MetroLab (app)
= 核心框架 + 主入口                      └──► MetroCalendar┘




意图说明：MetroLab= apple软件的壳子（ 核心框架 + 主入口   ）

平级的模块是：
1  MetroKit （SPM） (主要UI框架：磁贴 + 主题/动效/图标/控件/导航/Pivot/设置（todo，之前好像写过这个占位功能）)
2 Player （SPM）已新写完成
3 MetroMusic（SPM）
4 MetroPhotos（SPM）
5 MetroCalendar（SPM） （年月周 的WP风格日历，包含有日程安排记录功能）



apple 文件夹中的 ‘YearCalendar’ 是抽取出来的SPM 模块吗， apple中的 各个功能 我都SPM来做（仿WP都磁贴功能=SPM模块 也是app的主入口和核心框架 ，player =来自另外app功能页面UI拷贝过来做成的SPM 模块，新实现的仿WP 音乐播放器=新的SPM “音乐”模块，仿WP的相册=SPM “相册”模块



