import SwiftUI

public enum MetroLabRoute: Hashable {
  case appList
  case tiles
  case motion
  case typography
  case accent
  case controls
  case transitions
  case panorama
  case pivot
  case musicPlayer
  case settings
  case settingsDetail(String)
  case calendar
  case photos
  case detail(String)
}

/// The whole lab in one view. The app shells on both platforms do nothing but present
/// this, so anything that renders here renders identically everywhere.
///
/// There is deliberately no persistent "debug" chrome — no theme toggle, no jump menu.
/// A real Windows Phone Start screen carried nothing but tiles and the three system
/// buttons; every lab/demo screen this kit ships is reached the same way a real app
/// would be, by pinning it to Start or finding it in the app list.
public struct MetroLabRoot: View {
  @StateObject private var motionStore = MetroMotionStore()
  @StateObject private var musicPlayer = MetroMusicPlayer()

  @State private var theme = MetroTheme()
  @State private var path: [MetroLabRoute] = []
  @State private var transition: MetroTransitionKind = .turnstile
  @State private var actionCenterOpen = false
  @State private var showingCamera = false

  public init() {}

  public var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .top) {
        VStack(spacing: 0) {
          MetroNavigationView(path: $path, transition: transition) { route in
            screen(for: route)
          }
          .frame(maxHeight: .infinity)

          if musicPlayer.isPlaying && path.last != .musicPlayer {
            MetroMiniPlayerBar(player: musicPlayer) {
              path.append(.musicPlayer)
            }
          }

          MetroSystemNavBar(
            onBack: { if !path.isEmpty { path.removeLast() } },
            onStart: { path.removeAll() },
            onSearch: { if path.last != .appList { path.append(.appList) } }
          )
        }

        // A thin strip at the very top edge is the pull tab for the Action Center —
        // WP 8.1's own drag-down gesture never needed more than that to grab.
        Color.clear
          .frame(height: 28)
          .contentShape(Rectangle())
          .gesture(
            DragGesture(minimumDistance: 12)
              .onEnded { value in
                if value.translation.height > 40 {
                  withAnimation(motionStore.config.animation(.wpIn, 0.3)) { actionCenterOpen = true }
                }
              }
          )

        if actionCenterOpen {
          Color.black.opacity(0.001)
            .ignoresSafeArea()
            .onTapGesture {
              withAnimation(motionStore.config.animation(.wpOut, 0.25)) { actionCenterOpen = false }
            }

          MetroActionCenter {
            withAnimation(motionStore.config.animation(.wpOut, 0.25)) { actionCenterOpen = false }
            path = [.settings]
          }
          .transition(.move(edge: .top).combined(with: .opacity))
          .gesture(
            DragGesture(minimumDistance: 12)
              .onEnded { value in
                if value.translation.height < -30 {
                  withAnimation(motionStore.config.animation(.wpOut, 0.25)) { actionCenterOpen = false }
                }
              }
          )
        }
      }
      .metroContainerWidth(proxy.size.width)
    }
    .metroMotion(motionStore.config)
    .metroTheme(theme)
    #if os(iOS)
      .fullScreenCover(isPresented: $showingCamera) {
        MetroCameraCapture(
          onCapture: { _ in showingCamera = false },
          onCancel: { showingCamera = false }
        )
        .ignoresSafeArea()
      }
    #endif
    #if os(macOS)
      .frame(minWidth: 420, minHeight: 720)
    #endif
  }

  // MARK: Screens

  @ViewBuilder private func screen(for route: MetroLabRoute?) -> some View {
    switch route {
    case .none:
      startScreen
    case .appList:
      MetroPage(applicationTitle: "metrokit", title: "apps") {
        MetroAppList(entries: appListEntries) { name in handleAppListSelect(name) }
      }
    case .tiles:
      MetroTileLab()
    case .motion:
      MetroMotionLab(store: motionStore)
    case .typography:
      MetroTypographyLab(theme: $theme)
    case .accent:
      MetroAccentLab(theme: $theme)
    case .controls:
      MetroControlsLab()
    case .transitions:
      MetroTransitionLab(transition: $transition) { path.append(.detail("Transition target")) }
    case .panorama:
      MetroPanoramaLab()
    case .pivot:
      MetroPivotLab()
    case .musicPlayer:
      MetroMusicPage(player: musicPlayer)
    case .settings:
      MetroSettingsPage { key in path.append(.settingsDetail(key)) }
    case .settingsDetail(let key):
      MetroSettingsDetailPage(key: key, theme: $theme)
    case .calendar:
      MetroCalendarPage()
    case .photos:
      MetroPhotosPage()
    case .detail(let name):
      MetroDetailLab(name: name)
    }
  }

  // MARK: Start

  private var startScreen: some View {
    ScrollView {
      MetroTileGrid(tiles: MetroSampleData.startTiles) { tile in
        handleTileTap(tile)
      }
      .padding(.top, 8)
      .padding(.bottom, 24)
    }
  }

  private func handleTileTap(_ tile: MetroTileModel) {
    switch tile.id {
    case "phone":
      MetroSystemLauncher.openPhoneDialer()
    case "mail":
      MetroSystemLauncher.openMailCompose()
    case "camera":
      presentCamera(fallbackName: "Camera")
    case "settings":
      path.append(.settings)
    case "search":
      path.append(.appList)
    case "calendar":
      path.append(.calendar)
    case "photo-memories":
      path.append(.photos)
    case "music":
      path.append(.musicPlayer)
    default:
      path.append(.detail(tile.title))
    }
  }

  private func presentCamera(fallbackName: String) {
    #if os(iOS)
      if MetroSystemLauncher.cameraAvailable {
        showingCamera = true
        return
      }
    #endif
    path.append(.detail(fallbackName))
  }

  // MARK: App List

  private var appListEntries: [String] {
    MetroSampleData.appNames + MetroSampleData.labApps.map(\.name) + ["Calendar", "Photos"]
  }

  private func handleAppListSelect(_ name: String) {
    if let lab = MetroSampleData.labApps.first(where: { $0.name == name }) {
      path.append(routeForLabKey(lab.routeKey))
      return
    }
    switch name {
    case "Calendar":
      path.append(.calendar)
    case "Photos":
      path.append(.photos)
    case "Phone":
      MetroSystemLauncher.openPhoneDialer()
    case "Email", "Outlook":
      MetroSystemLauncher.openMailCompose()
    case "Camera", "Lumia Camera":
      presentCamera(fallbackName: name)
    default:
      path.append(.detail(name))
    }
  }

  private func routeForLabKey(_ key: String) -> MetroLabRoute {
    switch key {
    case "motion": return .motion
    case "tiles": return .tiles
    case "transitions": return .transitions
    case "panorama": return .panorama
    case "pivot": return .pivot
    case "controls": return .controls
    case "typography": return .typography
    case "accent": return .accent
    default: return .detail(key)
    }
  }
}

/// A leaf page, used as the far side of a navigation so the transition has somewhere
/// to land.
struct MetroDetailLab: View {
  @Environment(\.metroTheme) private var theme
  let name: String

  var body: some View {
    MetroPage(applicationTitle: "metrokit", title: name.lowercased()) {
      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(MetroSampleData.mailPreviews.enumerated()), id: \.offset) { index, item in
          MetroListRow(title: item.0, subtitle: item.2, accessory: "\(index + 1)") {}
            .metroFeather(order: index)
        }
        Spacer(minLength: 0)
      }
    }
  }
}
