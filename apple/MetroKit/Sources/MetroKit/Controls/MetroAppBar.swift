import SwiftUI

public struct MetroAppBarItem: Identifiable {
  public var id: String
  public var glyph: MetroGlyph
  public var label: String
  public var action: () -> Void

  public init(id: String? = nil, glyph: MetroGlyph, label: String, action: @escaping () -> Void) {
    self.id = id ?? label
    self.glyph = glyph
    self.label = label
    self.action = action
  }
}

public struct MetroAppBarMenuItem: Identifiable {
  public var id: String
  public var title: String
  public var action: () -> Void

  public init(id: String? = nil, title: String, action: @escaping () -> Void) {
    self.id = id ?? title
    self.title = title
    self.action = action
  }
}

/// The WP application bar: up to four circled icons, an ellipsis, and a menu that
/// slides the whole bar upward when opened. Icon labels only appear once it is open —
/// that reveal is the point of the control.
public struct MetroAppBar: View {
  @Environment(\.metroTheme) private var theme
  @Environment(\.metroMotion) private var motion

  public var items: [MetroAppBarItem]
  public var menuItems: [MetroAppBarMenuItem]
  /// WP could tint the bar with the accent instead of the neutral chrome brush.
  public var usesAccent: Bool

  @State private var isOpen = false

  public init(
    items: [MetroAppBarItem],
    menuItems: [MetroAppBarMenuItem] = [],
    usesAccent: Bool = false
  ) {
    self.items = Array(items.prefix(4))
    self.menuItems = menuItems
    self.usesAccent = usesAccent
  }

  private var barColor: Color { usesAccent ? theme.accentColor : theme.chrome }
  private var tint: Color { usesAccent ? theme.onAccent : theme.foreground }

  public var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        ForEach(items) { item in
          VStack(spacing: 6) {
            MetroAppBarIcon(item.glyph, diameter: 44, color: tint)
            if isOpen {
              Text(item.label)
                .metroText(.small, size: theme.type.size(.small) * 0.85)
                .foregroundColor(tint)
                .lineLimit(1)
            }
          }
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
          .metroTilt { item.action() }
        }

        if !menuItems.isEmpty {
          MetroIcon(.ellipsis, size: 22, color: tint)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .metroTilt {
              withAnimation(motion.animation(.wpIn, 0.28)) { isOpen.toggle() }
            }
            .accessibilityLabel("More")
        }
      }
      .padding(.horizontal, 10)
      .frame(height: theme.metrics.appBarHeight)

      if isOpen {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(Array(menuItems.enumerated()), id: \.element.id) { index, item in
            Text(item.title)
              .metroText(.normal)
              .foregroundColor(tint)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.vertical, 11)
              .padding(.horizontal, 16)
              .contentShape(Rectangle())
              .metroTilt {
                item.action()
                withAnimation(motion.animation(.wpIn, 0.28)) { isOpen = false }
              }
              .metroFeather(order: index)
          }
        }
        .padding(.bottom, 8)
      }
    }
    .frame(maxWidth: .infinity)
    .background(barColor)
  }
}
