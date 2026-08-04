import SwiftUI

/// Tile footprints, in small-tile units. WP shipped exactly these three.
public enum MetroTileSize: String, CaseIterable, Identifiable, Sendable {
  case small, medium, wide

  public var id: String { rawValue }

  /// Width in small-tile columns.
  public var columns: Int {
    switch self {
    case .small: return 1
    case .medium: return 2
    case .wide: return 4
    }
  }

  /// Height in small-tile rows.
  public var rows: Int {
    switch self {
    case .small: return 1
    case .medium, .wide: return 2
    }
  }

  public var displayName: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

  /// A small tile has no room for a caption — WP dropped it rather than shrinking it.
  public var showsTitle: Bool { self != .small }
}

public enum MetroTileStyle: String, CaseIterable, Identifiable, Sendable {
  /// Solid accent fill. The default, and the one the theme picker repaints.
  case accent
  /// The dark/light neutral fill used for tiles the user has not accented.
  case neutral
  /// WP 8.1's transparent tiles: only the glyph and caption, wallpaper behind.
  case transparent

  public var id: String { rawValue }
  public var displayName: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
}

/// What a tile does when it is left alone.
public enum MetroTileBehaviour: String, CaseIterable, Identifiable, Sendable {
  case `static`
  /// Turns about its horizontal axis between faces.
  case flip
  /// Pushes the next face up from below.
  case slide

  public var id: String { rawValue }
  public var displayName: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
}

/// One side of a live tile.
public enum MetroTileFace: Equatable, Sendable {
  /// Glyph plus the tile's caption — the resting face of every WP tile.
  case iconic
  case glyph(MetroGlyph)
  /// A single line of large light text, bled to the tile edge.
  case headline(String)
  /// The mail/messaging template: sender in accent-on-white, body beneath.
  case message(from: String, body: String)
  /// A number with a caption under it.
  case counter(Int, caption: String)
  /// The people tile: two letters, oversized.
  case initials(String)
  /// A "personal photo" tile — WP let you pin an actual photo as a tile face. There is
  /// no real photo library here, so this renders the same generated art as the music
  /// player's album covers.
  case photo
}

public struct MetroTileModel: Identifiable, Equatable, Sendable {
  public var id: String
  public var title: String
  public var glyph: MetroGlyph
  /// `nil` follows the theme accent, which is how most WP tiles behaved.
  public var accent: MetroAccent?
  public var style: MetroTileStyle
  public var size: MetroTileSize
  public var badge: Int?
  public var behaviour: MetroTileBehaviour
  public var faces: [MetroTileFace]

  public init(
    id: String,
    title: String,
    glyph: MetroGlyph,
    accent: MetroAccent? = nil,
    style: MetroTileStyle = .accent,
    size: MetroTileSize = .medium,
    badge: Int? = nil,
    behaviour: MetroTileBehaviour = .static,
    faces: [MetroTileFace] = [.iconic]
  ) {
    self.id = id
    self.title = title
    self.glyph = glyph
    self.accent = accent
    self.style = style
    self.size = size
    self.badge = badge
    self.behaviour = behaviour
    self.faces = faces.isEmpty ? [.iconic] : faces
  }

  func fill(in theme: MetroTheme) -> Color {
    switch style {
    case .accent: return (accent ?? theme.accent).color
    case .neutral: return theme.tileNeutral
    case .transparent: return .clear
    }
  }

  func foreground(in theme: MetroTheme) -> Color {
    style == .accent ? theme.onAccent : theme.foreground
  }
}
