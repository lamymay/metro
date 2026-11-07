import SwiftUI
import MetroKit
import MetroMusic
import MetroCalendar
import MetroPhotos

/// The whole app: a dedicated, standalone recreation of a specific Windows Phone 8.1
/// (Lumia Icon, "Denim", Verizon) start-screen photo, wired into MetroKit's existing
/// navigation shell — system nav bar (back/start/search), the pull-down Action Center,
/// and the calendar/settings/music/app-list screens the kit already ships. The tile
/// grid itself is hand-placed rather than built on MetroKit's tile-packing engine
/// (that engine auto-packs by size class; this one photo needs fixed coordinates), but
/// everything a tile hands off to — dialer, mail, camera, calendar, music — is the
/// same MetroKit plumbing the rest of the lab uses.
public struct LumiaStartScreen: View {
  @StateObject private var motionStore = MetroMotionStore()
  @StateObject private var musicPlayer = MetroMusicPlayer()
  @State private var theme = MetroTheme()
  @State private var path: [LumiaRoute] = []
  @State private var actionCenterOpen = false
  @State private var showingCamera = false
  @State private var showingCameraAccessAlert = false

  public init() {}

  public var body: some View {
    ZStack(alignment: .top) {
      VStack(spacing: 0) {
        MetroNavigationView(path: $path, transition: .turnstile) { route in
          screen(for: route)
        }
        .frame(maxHeight: .infinity)

        if musicPlayer.isPlaying && path.last != .musicPlayer {
          MetroMiniPlayerBar(player: musicPlayer) { path.append(.musicPlayer) }
        }

        MetroSystemNavBar(
          onBack: { if !path.isEmpty { path.removeLast() } },
          onStart: { path.removeAll() },
          onSearch: { if path.last != .appList { path.append(.appList) } }
        )
      }

      // Pull-down tab for the Action Center — same drag-to-reveal WP 8.1 used.
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
      .alert("Camera access needed", isPresented: $showingCameraAccessAlert) {
        Button("Open Settings") { MetroSystemLauncher.openAppSettings() }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Turn on camera access for this app in Settings to use it.")
      }
    #endif
  }

  // MARK: Routes

  @ViewBuilder private func screen(for route: LumiaRoute?) -> some View {
    switch route {
    case .none:
      lumiaGrid
    case .appList:
      MetroPage(applicationTitle: "metro", title: "apps") {
        MetroAppList(entries: appListEntries) { name in handleAppListSelect(name) }
      }
    case .calendar:
      MetroCalendarPage()
    case .settings:
      MetroSettingsPage { key in path.append(.settingsDetail(key)) }
    case .settingsDetail(let key):
      MetroSettingsDetailPage(key: key, theme: $theme)
    case .musicPlayer:
      MetroMusicPage(player: musicPlayer)
    case .player:
      MetroPlayerHostView(player: musicPlayer)
    case .photos:
      MetroPhotosPage()
    case .detail(let name):
      MetroPage(applicationTitle: "metro", title: name.lowercased()) {
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

  // Metro's three music player systems get three distinctly named entries: "音乐" is
  // the WP-recreation player, "music" hands off to the platform's own default player
  // (Music.app on iOS/macOS), and "player" mounts the extracted Player package's UI.
  private var appListEntries: [String] {
    ["Calendar", "音乐", "music", "player", "照片", "photos", "Camera", "Settings", "Games", "Office", "Voicemail", "Twitter"]
  }

  private func handleAppListSelect(_ name: String) {
    switch name {
    case "Calendar": path.append(.calendar)
    case "音乐": path.append(.musicPlayer)
    case "music": MetroSystemLauncher.openSystemMusicPlayer()
    case "player": path.append(.player)
    case "照片": path.append(.photos)
    case "photos": MetroSystemLauncher.openPhotos { path.append(.photos) }
    case "Camera": presentCamera()
    case "Settings": path.append(.settings)
    default: path.append(.detail(name))
    }
  }

  // MARK: Tile taps

  private func handleTileTap(_ id: String) {
    switch id {
    case "phone":
      MetroSystemLauncher.openPhoneDialer()
    case "messaging":
      MetroSystemLauncher.openMessages()
    case "mail-small", "google-mail", "mail-7":
      MetroSystemLauncher.openMailCompose()
    case "camera":
      presentCamera()
    case "calendar":
      path.append(.calendar)
    case "here-drive":
      MetroSystemLauncher.openMaps()
    case "music":
      path.append(.musicPlayer)
    case "photos":
      path.append(.photos)
    case "player":
      path.append(.player)
    case "games":
      path.append(.detail("Games"))
    case "twitter":
      path.append(.detail("Twitter"))
    case "office":
      path.append(.detail("Office"))
    case "voicemail":
      path.append(.detail("Voicemail"))
    default:
      break
    }
  }

  private func presentCamera() {
    guard MetroSystemLauncher.cameraAvailable else {
      path.append(.detail("Camera"))
      return
    }
    MetroSystemLauncher.requestCameraAccess { access in
      switch access {
      case .authorized: showingCamera = true
      case .denied: showingCameraAccessAlert = true
      }
    }
  }

  // MARK: - The tile grid itself

  private let columns = 4
  private let gap: CGFloat = 4
  private let leadingMargin: CGFloat = 4

  private var lumiaGrid: some View {
    GeometryReader { proxy in
      let unit = ((proxy.size.width - leadingMargin * 2) - gap * CGFloat(columns - 1)) / CGFloat(columns)

      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 0) {
          Spacer(minLength: 44)  // status bar clearance

          ZStack(alignment: .topLeading) {
            ForEach(LumiaTile.startScreen) { tile in
              LumiaTileView(tile: tile) { handleTileTap(tile.id) }
                .frame(
                  width: span(tile.colSpan, unit: unit),
                  height: span(tile.rowSpan, unit: unit),
                  alignment: .topLeading
                )
                .offset(
                  x: CGFloat(tile.col - 1) * (unit + gap),
                  y: CGFloat(tile.row - 1) * (unit + gap)
                )
            }
          }
          .frame(
            width: proxy.size.width - leadingMargin * 2,
            height: span(LumiaTile.rowCount, unit: unit),
            alignment: .topLeading
          )
          .padding(.leading, leadingMargin)

          Spacer(minLength: 60)
        }
      }
      .background(Color.black.ignoresSafeArea())
    }
  }

  /// Width/height spanned by `n` tile-units, including the interior gaps.
  private func span(_ n: Int, unit: CGFloat) -> CGFloat {
    CGFloat(n) * unit + CGFloat(max(0, n - 1)) * gap
  }
}

// MARK: - Routes

private enum LumiaRoute: Hashable {
  case appList
  case calendar
  case settings
  case settingsDetail(String)
  case musicPlayer
  case player
  case photos
  case detail(String)
}

// MARK: - Tile model

/// Footprints come straight from MetroKit's ``MetroTileSize`` rather than being
/// redefined here — the WP 8.1 rules (four sizes, no vertical rectangle, no label on
/// a small tile) belong to the design system, not to this one screen.
extension MetroTileSize {
  /// Glyph point size for this hand-drawn grid. `MetroTile` derives its own from the
  /// unit; this screen draws its tiles directly, so it needs absolute values.
  var lumiaGlyphSize: CGFloat {
    switch self {
    case .small: return 22
    case .medium: return 30
    case .wide: return 34
    case .large: return 44
    }
  }
}

private struct LumiaTile: Identifiable {
  var id: String
  var col: Int
  var row: Int
  var size: MetroTileSize
  var color: Color
  var badge: String? = nil
  var caption: String? = nil
  var alignCaption: Alignment = .bottomLeading
  @ViewBuilder var glyph: () -> AnyView

  var colSpan: Int { size.columns }
  var rowSpan: Int { size.rows }

  static let rowCount = 10

  /// Laid out in small-tile units on a 4-column grid, using only the four legal WP
  /// sizes. The reference photo's proportions are preserved where they were already
  /// legal (the phone/games/camera mediums, the full-width calendar); the tiles that
  /// were drawn as vertical rectangles or half-height strips are re-cut into the
  /// nearest real size rather than kept as shapes WP could not produce.
  static let startScreen: [LumiaTile] = [
    // Rows 1–2: a medium beside a 2×2 block of four smalls.
    LumiaTile(
      id: "phone", col: 1, row: 1, size: .medium, color: Color(hex: 0xE51400),
      caption: "Verizon Wireless"
    ) { AnyView(Image(systemName: "phone.fill")) },

    LumiaTile(
      id: "messaging", col: 3, row: 1, size: .small, color: Color(hex: 0x1BA1E2)
    ) { AnyView(Image(systemName: "message.fill")) },

    LumiaTile(
      id: "mail-small", col: 4, row: 1, size: .small, color: Color(hex: 0xA200FF),
      badge: "15"
    ) { AnyView(Image(systemName: "envelope.fill")) },

    LumiaTile(
      id: "twitter", col: 3, row: 2, size: .small, color: Color(hex: 0x1BA1E2)
    ) { AnyView(LumiaBirdGlyph()) },

    // The WP-recreation music player.
    LumiaTile(
      id: "music", col: 4, row: 2, size: .small, color: Color(hex: 0x1BA1E2)
    ) { AnyView(Image(systemName: "music.note")) },

    // Rows 3–4: two mediums.
    LumiaTile(
      id: "games", col: 1, row: 3, size: .medium, color: Color(hex: 0x60A917)
    ) { AnyView(Image(systemName: "gamecontroller.fill")) },

    LumiaTile(
      id: "google-mail", col: 3, row: 3, size: .medium, color: Color(hex: 0xE51400),
      badge: "23", caption: "Google Mail"
    ) { AnyView(Image(systemName: "envelope.fill")) },

    // Rows 5–6: a medium beside another 2×2 block of smalls.
    LumiaTile(
      id: "camera", col: 1, row: 5, size: .medium, color: Color(hex: 0x6A00FF),
      caption: "Nokia Camera"
    ) { AnyView(Image(systemName: "camera.fill")) },

    LumiaTile(
      id: "mail-7", col: 3, row: 5, size: .small, color: Color(hex: 0xE51400),
      badge: "7"
    ) { AnyView(Image(systemName: "envelope.fill")) },

    // Player's own native UI, sharing its library with the "music" tile.
    LumiaTile(
      id: "player", col: 4, row: 5, size: .small, color: Color(hex: 0xA200FF)
    ) { AnyView(Image(systemName: "waveform")) },

    LumiaTile(
      id: "photos", col: 3, row: 6, size: .small, color: Color(hex: 0x1F1F1F)
    ) { AnyView(LumiaPhotoStripGlyph()) },

    LumiaTile(
      id: "office", col: 4, row: 6, size: .small, color: Color(hex: 0xD24726)
    ) { AnyView(Image(systemName: "doc.text.fill")) },

    // Rows 7–8: the one wide tile, full width — as in the photo.
    LumiaTile(
      id: "calendar", col: 1, row: 7, size: .wide, color: Color(hex: 0xE51400),
      caption: "Calendar"
    ) { AnyView(LumiaCalendarGlyph()) },

    // Rows 9–10: two mediums.
    LumiaTile(
      id: "here-drive", col: 1, row: 9, size: .medium, color: Color(hex: 0x1D7DD4),
      caption: "HERE Drive+"
    ) { AnyView(Image(systemName: "location.north.fill")) },

    LumiaTile(
      id: "voicemail", col: 3, row: 9, size: .medium, color: Color(hex: 0xE51400),
      caption: "Voicemail"
    ) { AnyView(Image(systemName: "voicemail")) },
  ]
}

// MARK: - Tile rendering

private struct LumiaTileView: View {
  let tile: LumiaTile
  var onTap: () -> Void

  /// The three mail tiles get a right-click (macOS) / long-press (iOS) shortcut
  /// straight to the system default mail client — the same hand-off the tile's own
  /// tap already does, just reachable the way a Mac user expects to reach it.
  private var isMailTile: Bool {
    tile.id == "mail-small" || tile.id == "google-mail" || tile.id == "mail-7"
  }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      tile.color

      tile.glyph()
        .font(.system(size: tile.size.lumiaGlyphSize, weight: .light))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

      if let badge = tile.badge {
        Text(badge)
          .font(.system(size: tile.size == .small ? 18 : 26, weight: .light, design: .rounded))
          .foregroundColor(.white)
          .padding(.top, tile.size == .small ? 3 : 6)
          .padding(.trailing, tile.size == .small ? 5 : 8)
      }

      // Small tiles are icon-and-badge only on WP — there is no room for a label and
      // the system never drew one.
      if let caption = tile.caption, tile.size.showsTitle {
        Text(caption)
          .font(.system(size: 12, weight: .regular))
          .foregroundColor(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .padding(6)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: tile.alignCaption)
      }
    }
    .clipped()
    .contentShape(Rectangle())
    .onTapGesture(perform: onTap)
    .modifier(MailTileContextMenu(isEnabled: isMailTile))
  }
}

private struct MailTileContextMenu: ViewModifier {
  let isEnabled: Bool

  func body(content: Content) -> some View {
    if isEnabled {
      content.contextMenu {
        Button("Open in Mail") { MetroSystemLauncher.openMailCompose() }
      }
    } else {
      content
    }
  }
}

// MARK: - Custom glyphs not covered by SF Symbols

private struct LumiaCalendarGlyph: View {
  var body: some View {
    VStack(spacing: 2) {
      Text("Mon 14")
        .font(.system(size: 34, weight: .light))
        .foregroundColor(.white)
    }
  }
}

private struct LumiaBirdGlyph: View {
  var body: some View {
    Image(systemName: "bird.fill")
  }
}

private struct LumiaPhotoStripGlyph: View {
  var body: some View {
    HStack(spacing: 2) {
      Rectangle().fill(Color(hex: 0xE51400))
      Rectangle().fill(Color.white)
      Rectangle().fill(Color(hex: 0x1BA1E2))
    }
    .frame(width: 60, height: 34)
  }
}

// MARK: - Color helper

extension Color {
  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255
    )
  }
}

#Preview {
  LumiaStartScreen()
}
