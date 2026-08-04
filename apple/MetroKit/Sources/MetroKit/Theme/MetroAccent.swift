import SwiftUI

/// The twenty stock accent colours that shipped with Windows Phone 8, with their
/// original hex values. WP only ever tinted with a flat accent — no gradients, no
/// tints of a tint — so everything in MetroKit resolves back to one of these.
public enum MetroAccent: String, CaseIterable, Identifiable, Sendable {
  case lime, green, emerald, teal, cyan, cobalt, indigo, violet, pink, magenta
  case crimson, red, orange, amber, yellow, brown, olive, steel, mauve, taupe

  public var id: String { rawValue }

  public var hex: UInt32 {
    switch self {
    case .lime: return 0xA4C400
    case .green: return 0x60A917
    case .emerald: return 0x008A00
    case .teal: return 0x00ABA9
    case .cyan: return 0x1BA1E2
    case .cobalt: return 0x0050EF
    case .indigo: return 0x6A00FF
    case .violet: return 0xAA00FF
    case .pink: return 0xF472D0
    case .magenta: return 0xD80073
    case .crimson: return 0xA20025
    case .red: return 0xE51400
    case .orange: return 0xFA6800
    case .amber: return 0xF0A30A
    case .yellow: return 0xE3C800
    case .brown: return 0x825A2C
    case .olive: return 0x6D8764
    case .steel: return 0x647687
    case .mauve: return 0x76608A
    case .taupe: return 0x87794E
    }
  }

  public var color: Color { Color(metroHex: hex) }

  public var displayName: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

  /// WP shipped `cobalt` as the out-of-box accent on most hardware.
  public static let `default`: MetroAccent = .cobalt
}

extension Color {
  /// 0xRRGGBB.
  public init(metroHex hex: UInt32) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: 1
    )
  }
}
