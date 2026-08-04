import SwiftUI

/// A WP list row: title, optional subtitle, no separator, no chevron, no inset. The
/// absence of chrome is the design — the tilt on press is the only affordance.
public struct MetroListRow: View {
  @Environment(\.metroTheme) private var theme

  public var title: String
  public var subtitle: String?
  public var glyph: MetroGlyph?
  public var accessory: String?
  public var action: (() -> Void)?

  public init(
    title: String,
    subtitle: String? = nil,
    glyph: MetroGlyph? = nil,
    accessory: String? = nil,
    action: (() -> Void)? = nil
  ) {
    self.title = title
    self.subtitle = subtitle
    self.glyph = glyph
    self.accessory = accessory
    self.action = action
  }

  public var body: some View {
    HStack(alignment: .center, spacing: 14) {
      if let glyph {
        MetroIcon(glyph, size: 30, color: theme.foreground)
      }
      VStack(alignment: .leading, spacing: 1) {
        Text(title).metroText(.title3).lineLimit(1)
        if let subtitle {
          Text(subtitle).metroText(.small).lineLimit(1)
        }
      }
      Spacer(minLength: 8)
      if let accessory {
        Text(accessory).metroText(.small)
      }
    }
    .padding(.vertical, 9)
    .padding(.horizontal, theme.metrics.pageMargin)
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
    .metroTilt(isEnabled: action != nil) { action?() }
  }
}

/// A group header — WP's `LongListSelector` drew these as an accent square with the
/// group's letter in it, tappable to enter the semantic zoom.
public struct MetroGroupHeader: View {
  @Environment(\.metroTheme) private var theme

  public var text: String
  public var isEnabled: Bool
  public var action: (() -> Void)?

  public init(_ text: String, isEnabled: Bool = true, action: (() -> Void)? = nil) {
    self.text = text
    self.isEnabled = isEnabled
    self.action = action
  }

  public var body: some View {
    HStack {
      Text(text.uppercased())
        .metroText(.title3)
        .foregroundColor(isEnabled ? theme.onAccent : theme.disabled)
        .frame(width: 46, height: 46)
        .background(isEnabled ? theme.accentColor : Color.clear)
        .overlay {
          if !isEnabled {
            Rectangle().strokeBorder(theme.disabled, lineWidth: metroBorderWidth)
          }
        }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, theme.metrics.pageMargin)
    .padding(.top, 14)
    .padding(.bottom, 4)
    .contentShape(Rectangle())
    .metroTilt(isEnabled: isEnabled && action != nil) { action?() }
  }
}
