import SwiftUI

/// Fixture content for the lab. Kept in the library rather than the app shell so the
/// same start screen renders in an Xcode preview, on iOS and on the Mac.
public enum MetroSampleData {

  /// A denser, more varied start screen — closer to how an actual, well-used Lumia
  /// looked than the sparse first pass was. Real phones don't have four empty rows.
  public static let startTiles: [MetroTileModel] = [
    MetroTileModel(
      id: "phone", title: "phone", glyph: .phone, accent: .emerald,
      size: .medium, badge: 2, behaviour: .flip,
      faces: [.iconic, .counter(2, caption: "missed calls")]
    ),
    MetroTileModel(
      id: "messaging", title: "messaging", glyph: .message,
      size: .medium, badge: 7, behaviour: .flip,
      faces: [
        .iconic,
        .message(from: "Kaori", body: "見た？ タイルの動きが完全に WP なんだけど"),
      ]
    ),
    MetroTileModel(id: "search", title: "search", glyph: .search, accent: .steel, size: .small),
    MetroTileModel(id: "store", title: "store", glyph: .store, accent: .magenta, size: .small),
    MetroTileModel(id: "settings", title: "settings", glyph: .settings, style: .neutral, size: .small),
    MetroTileModel(id: "camera", title: "camera", glyph: .camera, accent: .taupe, size: .small),
    MetroTileModel(
      id: "people", title: "people", glyph: .people, accent: .violet,
      size: .wide, behaviour: .slide,
      faces: [.iconic, .initials("KM"), .initials("TS"), .initials("AY")]
    ),
    MetroTileModel(
      id: "mail", title: "outlook", glyph: .mail, accent: .cobalt,
      size: .medium, badge: 14, behaviour: .flip,
      faces: [
        .iconic,
        .message(from: "build@ci", body: "MetroKit — 6 targets green"),
        .counter(14, caption: "unread"),
      ]
    ),
    MetroTileModel(
      id: "photo-memories", title: "photos", glyph: .photo, accent: .amber,
      size: .medium, behaviour: .slide,
      faces: [.photo, .photo, .photo]
    ),
    MetroTileModel(
      id: "calendar", title: "calendar", glyph: .calendar, accent: .orange,
      size: .medium, behaviour: .slide,
      faces: [.iconic, .headline("14:30\nDesign review")]
    ),
    MetroTileModel(
      id: "music", title: "music", glyph: .music, accent: .crimson,
      size: .wide, behaviour: .flip,
      faces: [.iconic, .headline("Boards of Canada — Dayvan Cowboy")]
    ),
    MetroTileModel(id: "weather", title: "weather", glyph: .sun, accent: .amber, size: .small),
    MetroTileModel(id: "clock", title: "alarms", glyph: .clock, accent: .indigo, size: .small),
    MetroTileModel(id: "ie", title: "browser", glyph: .globe, accent: .cyan, size: .small),
    MetroTileModel(id: "files", title: "files", glyph: .folder, style: .neutral, size: .small),
    MetroTileModel(
      id: "wallet", title: "wallet", glyph: .star, accent: .olive,
      size: .medium, behaviour: .flip,
      faces: [.iconic, .counter(3, caption: "cards")]
    ),
    MetroTileModel(id: "maps", title: "maps", glyph: .pin, accent: .red, size: .small),
    MetroTileModel(id: "translator", title: "translator", glyph: .globe, accent: .mauve, size: .small),
    MetroTileModel(id: "health", title: "health", glyph: .heart, accent: .pink, size: .small),
    MetroTileModel(id: "notes", title: "notes", glyph: .folder, accent: .brown, size: .small),
    MetroTileModel(
      id: "podcasts", title: "podcasts", glyph: .music, accent: .teal,
      size: .medium, behaviour: .slide,
      faces: [.iconic, .headline("New: Turnstile Timing, ep. 12")]
    ),
    MetroTileModel(id: "xbox", title: "xbox", glyph: .star, accent: .emerald, size: .small),
    MetroTileModel(id: "voice-recorder", title: "voice recorder", glyph: .music, style: .neutral, size: .small),
  ]

  /// Ordinary "installed apps" — tapping any of these opens a generic mail-style
  /// placeholder page, same as a real phone's rarely-used apps would show you nothing
  /// interesting either.
  public static let appNames: [String] = [
    "Alarms", "Amazon", "Battery Saver", "Bing", "Calculator", "Camera",
    "Contacts", "Data Sense", "Documents", "Email", "Facebook", "Files", "FM Radio",
    "Games", "Groove Music", "Health", "Here Drive", "Here Maps", "IE Mobile",
    "Instagram", "Kids Corner", "Lenses", "Lumia Camera", "Maps", "Messaging",
    "Money", "MSN News", "Nokia Care", "Notes", "OneDrive", "OneNote", "Office",
    "Outlook", "People", "Phone", "Podcasts", "Reading List",
    "Skype", "Sport", "Store", "Translator", "Travel", "Twitter", "Video",
    "Voice Recorder", "Wallet", "Weather", "WhatsApp", "Word", "Xbox", "1Password",
    "2Do", "微信", "百度地图",
  ]

  /// Every lab/demo screen, listed the way a real installed app would be — this is the
  /// only way to reach them once the debug app bar is gone. `name` doubles as the App
  /// List entry; `route` is resolved by the caller (MetroLabRoot owns MetroLabRoute).
  public static let labApps: [(name: String, routeKey: String)] = [
    ("Motion Lab", "motion"),
    ("Tile Playground", "tiles"),
    ("Page Transitions", "transitions"),
    ("Panorama Demo", "panorama"),
    ("Pivot Demo", "pivot"),
    ("Controls Demo", "controls"),
    ("Type Ramp", "typography"),
    ("Accent Picker", "accent"),
  ]

  public static let mailPreviews: [(String, String, String)] = [
    ("Kaori Mizuki", "Re: tile feather timing", "50 ms でいいと思う。100 は遅すぎ"),
    ("build@ci", "MetroKit — all green", "6 targets, 0 warnings"),
    ("Tomo Sasaki", "Turnstile exponent", "Exponent 6 の EaseOut で合ってる"),
    ("Store Review", "Submission received", "We'll be in touch within 48 hours."),
    ("Aya Yamada", "パノラマの背景", "画像なしで grid だけのほうが Metro っぽい"),
    ("noreply@github", "3 new pull requests", "wp/apple, wp/android"),
  ]

  // MARK: Calendar

  public struct MetroEvent: Identifiable {
    public var id: String { title + start }
    public var title: String
    public var start: String
    public var end: String
    public var accent: MetroAccent
    public var day: Int // 1-based day-of-month, for the month grid dot
  }

  public static let currentMonth = "August"
  public static let today = 2

  public static let events: [MetroEvent] = [
    MetroEvent(title: "Design review", start: "14:30", end: "15:15", accent: .cobalt, day: 2),
    MetroEvent(title: "1:1 with Tomo", start: "16:00", end: "16:30", accent: .violet, day: 2),
    MetroEvent(title: "Ship wp/apple", start: "09:00", end: "10:00", accent: .emerald, day: 3),
    MetroEvent(title: "Kaori — motion review", start: "11:00", end: "12:00", accent: .crimson, day: 5),
    MetroEvent(title: "Store submission window", start: "All day", end: "", accent: .amber, day: 8),
    MetroEvent(title: "Aya — panorama assets", start: "13:00", end: "13:30", accent: .teal, day: 12),
  ]

  // MARK: Photos

  /// Each "photo" is just an accent + a seed for the generated art, since the kit has
  /// no real image assets.
  public static let photoAccents: [MetroAccent] = [
    .cobalt, .crimson, .teal, .amber, .violet, .emerald, .magenta, .steel,
    .orange, .indigo, .olive, .taupe, .pink, .cyan, .mauve, .lime,
  ]

  public static let albums: [(name: String, count: Int, accent: MetroAccent)] = [
    ("Camera Roll", 16, .cobalt),
    ("Screenshots", 9, .steel),
    ("wp/apple", 6, .crimson),
    ("Metro Sessions", 4, .violet),
  ]
}
