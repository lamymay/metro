import SwiftUI

/// WP had exactly two themes — dark and light — and they were pure black and pure
/// white, not "almost black". That flatness is load-bearing for the look: tiles read
/// as floating colour because there is no surface behind them.
public enum MetroThemeMode: String, CaseIterable, Identifiable, Sendable {
  case dark, light
  public var id: String { rawValue }
  public var displayName: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
}

/// Resolved colour + type + metric set handed down the view tree.
public struct MetroTheme: Sendable {
  public var mode: MetroThemeMode
  public var accent: MetroAccent
  public var type: MetroTypeRamp
  public var metrics: MetroMetrics

  public init(
    mode: MetroThemeMode = .dark,
    accent: MetroAccent = .default,
    type: MetroTypeRamp = MetroTypeRamp(),
    metrics: MetroMetrics = MetroMetrics()
  ) {
    self.mode = mode
    self.accent = accent
    self.type = type
    self.metrics = metrics
  }

  // MARK: Brushes (named after their PhoneXxxBrush originals)

  public var background: Color { mode == .dark ? .black : .white }
  public var foreground: Color { mode == .dark ? .white : .black }
  public var accentColor: Color { accent.color }

  /// PhoneChromeBrush — the app bar / chrome fill.
  public var chrome: Color {
    mode == .dark ? Color(metroHex: 0x1F1F1F) : Color(metroHex: 0xDDDDDD)
  }

  /// PhoneDisabledBrush.
  public var disabled: Color {
    mode == .dark ? Color(metroHex: 0x666666) : Color(metroHex: 0xA6A6A6)
  }

  /// PhoneSubtleBrush — secondary text, the "…" glyphs, list subtitles.
  public var subtle: Color {
    mode == .dark ? Color(metroHex: 0x999999) : Color(metroHex: 0x666666)
  }

  /// PhoneBorderBrush — 2px hairlines around text boxes and checkboxes.
  public var border: Color { foreground.opacity(mode == .dark ? 0.55 : 0.65) }

  /// The fill of an unpinned/neutral tile when it has no accent of its own.
  public var tileNeutral: Color {
    mode == .dark ? Color(metroHex: 0x1F1F1F) : Color(metroHex: 0xE6E6E6)
  }

  /// Text drawn *on* an accent fill. WP always used white here, in both themes.
  public var onAccent: Color { .white }

  public func with(mode: MetroThemeMode) -> MetroTheme {
    var copy = self
    copy.mode = mode
    return copy
  }

  public func with(accent: MetroAccent) -> MetroTheme {
    var copy = self
    copy.accent = accent
    return copy
  }
}

// MARK: - Environment

private struct MetroThemeKey: EnvironmentKey {
  static let defaultValue = MetroTheme()
}

extension EnvironmentValues {
  public var metroTheme: MetroTheme {
    get { self[MetroThemeKey.self] }
    set { self[MetroThemeKey.self] = newValue }
  }
}

extension View {
  /// Installs a theme and paints the Metro background behind the content.
  public func metroTheme(_ theme: MetroTheme) -> some View {
    self
      .environment(\.metroTheme, theme)
      .background(theme.background.ignoresSafeArea())
      .foregroundColor(theme.foreground)
      .tint(theme.accentColor)
  }
}
