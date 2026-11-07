import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Which physical family backs the ramp.
///
/// Segoe WP cannot be redistributed, so the default is a system-font stand-in that
/// matches the *weights* of the original. If you drop the real `SegoeWP-*.ttf` files
/// into `Sources/MetroKit/Resources/Fonts/` and register them, switch to `.segoeWP`
/// and the whole kit re-renders with the shipping typeface.
public enum MetroFontFamily: Equatable, Sendable {
  /// SF Pro at Metro's weights. Available everywhere, no install step.
  case system
  /// Grotesque stand-in — closer to Segoe's tight spacing at display sizes.
  case helveticaNeue
  /// The real thing, if you have installed it.
  case segoeWP
  /// Anything else, by PostScript family name.
  case custom(String)

  func postScriptName(for weight: MetroFontWeight) -> String? {
    switch self {
    case .system:
      return nil
    case .helveticaNeue:
      switch weight {
      case .light: return "HelveticaNeue-UltraLight"
      case .semiLight: return "HelveticaNeue-Thin"
      case .normal: return "HelveticaNeue"
      case .semiBold: return "HelveticaNeue-Medium"
      case .bold: return "HelveticaNeue-Bold"
      }
    case .segoeWP:
      switch weight {
      case .light: return "SegoeWP-Light"
      case .semiLight: return "SegoeWP-SemiLight"
      case .normal: return "SegoeWP"
      case .semiBold: return "SegoeWP-Semibold"
      case .bold: return "SegoeWP-Bold"
      }
    case .custom(let name):
      return name
    }
  }
}

/// Segoe WP shipped in exactly these cuts, and WP's styles only ever referenced them.
public enum MetroFontWeight: Sendable {
  case light, semiLight, normal, semiBold, bold

  var systemWeight: Font.Weight {
    switch self {
    case .light: return .thin
    case .semiLight: return .light
    case .normal: return .regular
    case .semiBold: return .semibold
    case .bold: return .bold
    }
  }
}

/// The WP text styles, by their original `PhoneTextXxxStyle` names.
public enum MetroTextRole: String, CaseIterable, Identifiable, Sendable {
  /// Segoe WP Semibold, tracked out and upper-cased in the page header.
  case applicationTitle
  /// The lowercase page header under the application title.
  case pageTitle
  /// A pivot's header item. Bigger than a page title, and the reason a pivot reads as
  /// a carousel of words rather than as a tab bar.
  case pivotHeader
  /// The oversized panorama title, which is allowed to bleed off the right edge.
  case panoramaTitle
  case title1, title2, title3
  case normal
  case subtle
  case small
  case groupHeader
  case large
  case extraLarge
  /// Panorama title. Deliberately oversized and allowed to bleed off-screen.
  case huge
  /// Numeric badge on a live tile.
  case tileBadge
  /// Tile caption, bottom-left.
  case tileTitle

  public var id: String { rawValue }

  var weight: MetroFontWeight {
    switch self {
    case .applicationTitle, .groupHeader: return .semiBold
    case .panoramaTitle, .huge: return .light
    case .pageTitle, .pivotHeader, .large, .extraLarge, .title1, .title2, .title3: return .semiLight
    case .tileBadge: return .light
    case .normal, .subtle, .small, .tileTitle: return .normal
    }
  }

  /// Raw Windows Phone point sizes, in WVGA (480×800, scale 1.0) pixels. Public so a
  /// host can show the shipping value a role derives from — the Type Ramp screen
  /// prints it beside the resolved point size.
  public var wpSize: CGFloat {
    switch self {
    case .applicationTitle: return 18.667
    // `PhoneTextTitle1Style` was 32; WP apps in practice pushed their page headers a
    // little past it, and 40 is what reads correctly at modern pixel densities.
    case .pageTitle: return 40
    case .pivotHeader: return 48
    case .panoramaTitle: return 120
    case .huge: return 186.667
    case .extraLarge: return 34.667
    case .large: return 32
    case .title1: return 32
    case .title2: return 25.333
    case .title3: return 22.667
    case .normal, .subtle: return 20
    case .small, .groupHeader: return 18.667
    case .tileBadge: return 46
    case .tileTitle: return 18.667
    }
  }

  var isSubtle: Bool {
    switch self {
    case .subtle, .small, .groupHeader: return true
    default: return false
    }
  }

  /// WP tracked the application title out by ~0.05em and left everything else alone.
  var tracking: CGFloat {
    self == .applicationTitle ? 1.5 : 0
  }

  var isUppercased: Bool { self == .applicationTitle }
}

/// The full type ramp, expressed in WP's own units with one scale factor to bring it
/// onto an Apple screen. A WVGA phone was 480 units wide across roughly the same
/// physical width as a modern 390pt iPhone, so 0.8 lands close to 1:1 apparent size.
public struct MetroTypeRamp: Sendable {
  public var family: MetroFontFamily
  public var scale: CGFloat

  public init(family: MetroFontFamily = .system, scale: CGFloat = 0.8) {
    self.family = family
    self.scale = scale
  }

  public func size(_ role: MetroTextRole) -> CGFloat {
    (role.wpSize * scale).rounded()
  }

  public func font(_ role: MetroTextRole) -> Font {
    font(role, size: size(role))
  }

  public func font(_ role: MetroTextRole, size: CGFloat) -> Font {
    if let name = family.postScriptName(for: role.weight), Self.fontExists(name) {
      return .custom(name, fixedSize: size)
    }
    return .system(size: size, weight: role.weight.systemWeight, design: .default)
  }

  private static func fontExists(_ name: String) -> Bool {
    #if canImport(UIKit)
      return UIFont(name: name, size: 12) != nil
    #elseif canImport(AppKit)
      return NSFont(name: name, size: 12) != nil
    #else
      return false
    #endif
  }
}

// MARK: - Applying a role

extension View {
  /// Applies a WP text style: font, tracking, casing rule and subtle-brush colour.
  public func metroText(_ role: MetroTextRole) -> some View {
    modifier(MetroTextModifier(role: role, sizeOverride: nil))
  }

  /// Same, but with the point size forced — used by the panorama title, which scales
  /// with its container rather than the ramp.
  public func metroText(_ role: MetroTextRole, size: CGFloat) -> some View {
    modifier(MetroTextModifier(role: role, sizeOverride: size))
  }
}

private struct MetroTextModifier: ViewModifier {
  @Environment(\.metroTheme) private var theme
  let role: MetroTextRole
  let sizeOverride: CGFloat?

  func body(content: Content) -> some View {
    content
      .font(sizeOverride.map { theme.type.font(role, size: $0) } ?? theme.type.font(role))
      .textCase(role.isUppercased ? .uppercase : nil)
      .foregroundColor(role.isSubtle ? theme.subtle : theme.foreground)
  }
}

/// The tracked-out application title.
///
/// `View.tracking` and `View.kerning` are both iOS 16+, so the letter-spacing goes on
/// an `AttributedString` instead — which is the one place in the kit that needs it.
public struct MetroApplicationTitle: View {
  @Environment(\.metroTheme) private var theme
  public let text: String

  public init(_ text: String) {
    self.text = text
  }

  public var body: some View {
    var attributed = AttributedString(text.uppercased())
    attributed.kern = MetroTextRole.applicationTitle.tracking
    return Text(attributed)
      .font(theme.type.font(.applicationTitle))
      .foregroundColor(theme.foreground)
  }
}
