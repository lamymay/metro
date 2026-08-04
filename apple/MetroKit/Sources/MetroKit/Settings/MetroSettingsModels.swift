import Foundation

/// One row in the Settings list. `kind` decides whether tapping it opens a real page
/// or a generic placeholder — most of WP's own settings surface needs entitlements an
/// ordinary app can never hold, so those stay honestly cosmetic.
public struct MetroSettingsItem: Identifiable, Hashable {
  public var id: String { key }
  public var key: String
  public var title: String
  public var subtitle: String
  public var glyph: MetroGlyph

  public init(key: String, title: String, subtitle: String, glyph: MetroGlyph) {
    self.key = key
    self.title = title
    self.subtitle = subtitle
    self.glyph = glyph
  }
}

public enum MetroSettingsData {
  public static let system: [MetroSettingsItem] = [
    MetroSettingsItem(key: "theme", title: "start+theme", subtitle: "accent colour, dark/light", glyph: .start),
    MetroSettingsItem(key: "ringtones", title: "ringtones+sounds", subtitle: "Nostalgia", glyph: .music),
    MetroSettingsItem(key: "accounts", title: "email+accounts", subtitle: "set up email, contacts and others", glyph: .mail),
    MetroSettingsItem(key: "lockscreen", title: "lock screen", subtitle: "screen timeout, keep awake", glyph: .clock),
    MetroSettingsItem(key: "brightness", title: "brightness", subtitle: "adjusts the real screen", glyph: .sun),
    MetroSettingsItem(key: "notifications", title: "notifications+actions", subtitle: "manage action centre", glyph: .message),
    MetroSettingsItem(key: "wifi", title: "WiFi", subtitle: "not connected", glyph: .wifi),
    MetroSettingsItem(key: "flightmode", title: "flight mode", subtitle: "off", glyph: .airplane),
    MetroSettingsItem(key: "bluetooth", title: "bluetooth", subtitle: "off", glyph: .bluetooth),
    MetroSettingsItem(key: "cellular", title: "cellular+SIM", subtitle: "no SIM", glyph: .phone),
    MetroSettingsItem(key: "nfc", title: "NFC", subtitle: "off", glyph: .pin),
    MetroSettingsItem(key: "sharing", title: "network sharing", subtitle: "off", glyph: .globe),
    MetroSettingsItem(key: "battery", title: "battery saver", subtitle: "reads the real battery", glyph: .heart),
  ]

  public static let applications: [MetroSettingsItem] = [
    MetroSettingsItem(key: "app-music", title: "music+videos", subtitle: "playback, downloads", glyph: .music),
    MetroSettingsItem(key: "app-store", title: "store", subtitle: "updates, payment", glyph: .store),
    MetroSettingsItem(key: "app-maps", title: "maps", subtitle: "offline maps", glyph: .globe),
    MetroSettingsItem(key: "app-camera", title: "camera", subtitle: "grid lines, shutter sound", glyph: .camera),
  ]

  public static func item(for key: String) -> MetroSettingsItem? {
    (system + applications).first { $0.key == key }
  }
}
