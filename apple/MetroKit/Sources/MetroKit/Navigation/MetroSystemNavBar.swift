import SwiftUI

/// The three buttons every Windows Phone had on the bezel of every screen: Back,
/// Start, Search. This sits below the optional per-page ``MetroAppBar`` and never
/// changes — WP's own chrome, not the app's.
///
/// The visual distinction from ``MetroAppBar`` icons is deliberate: no circle, no
/// caption, no fill. On hardware these were capacitive buttons printed on the bezel,
/// not pixels the app drew — the flattest possible treatment is the honest one.
public struct MetroSystemNavBar: View {
  @Environment(\.metroTheme) private var theme

  public var onBack: () -> Void
  public var onStart: () -> Void
  public var onSearch: () -> Void

  public init(
    onBack: @escaping () -> Void,
    onStart: @escaping () -> Void,
    onSearch: @escaping () -> Void
  ) {
    self.onBack = onBack
    self.onStart = onStart
    self.onSearch = onSearch
  }

  public var body: some View {
    HStack(spacing: 0) {
      button(.back, label: "Back", action: onBack)
      button(.start, label: "Start", action: onStart)
      button(.search, label: "Search", action: onSearch)
    }
    .frame(height: 46)
    .background(theme.chrome)
  }

  private func button(_ glyph: MetroGlyph, label: String, action: @escaping () -> Void) -> some View {
    MetroIcon(glyph, size: 22, color: theme.foreground)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(Rectangle())
      .metroTilt { action() }
      .accessibilityLabel(label)
  }
}
