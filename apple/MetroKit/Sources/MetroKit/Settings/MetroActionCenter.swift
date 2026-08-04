import SwiftUI

struct MetroActionCenterItem: Identifiable {
  var id: String { title }
  var title: String
  var glyph: MetroGlyph
  var isOn: Bool
  var action: () -> Void
}

/// WP 8.1's Action Center: drag down from the top edge, get a grid of quick-toggle
/// tiles plus notifications, dismiss by dragging back up or tapping outside it.
///
/// Brightness and torch are wired to ``MetroDeviceCapabilities`` and actually work.
/// WiFi, Bluetooth, airplane mode and rotation lock stay local `@State` — no sandboxed
/// app can touch those radios, and pretending otherwise would be the one dishonest
/// control in the whole kit.
public struct MetroActionCenter: View {
  @Environment(\.metroTheme) private var theme
  @ObservedObject private var device = MetroDeviceCapabilities.shared

  @State private var wifiOn = true
  @State private var bluetoothOn = false
  @State private var airplaneOn = false
  @State private var rotationLocked = false

  public var onOpenSettings: () -> Void

  public init(onOpenSettings: @escaping () -> Void) {
    self.onOpenSettings = onOpenSettings
  }

  private var items: [MetroActionCenterItem] {
    [
      MetroActionCenterItem(title: "wifi", glyph: .wifi, isOn: wifiOn) { wifiOn.toggle() },
      MetroActionCenterItem(title: "bluetooth", glyph: .bluetooth, isOn: bluetoothOn) { bluetoothOn.toggle() },
      MetroActionCenterItem(title: device.torchOn ? "torch: on" : "torch", glyph: .flashlight, isOn: device.torchOn) {
        device.torchOn.toggle()
      },
      MetroActionCenterItem(title: "rotation lock", glyph: .refresh, isOn: rotationLocked) { rotationLocked.toggle() },
      MetroActionCenterItem(title: "airplane mode", glyph: .airplane, isOn: airplaneOn) { airplaneOn.toggle() },
      MetroActionCenterItem(title: brightnessLabel, glyph: .sun, isOn: device.brightness > 0.6) {
        // Cycles low → high → low, the way WP's own brightness quick tile did.
        let next: Double = device.brightness > 0.66 ? 0.18 : (device.brightness > 0.33 ? 1.0 : 0.66)
        device.setBrightness(next)
      },
    ]
  }

  private var brightnessLabel: String {
    device.brightness > 0.66 ? "brightness: high" : (device.brightness > 0.33 ? "brightness: med" : "brightness: low")
  }

  public var body: some View {
    VStack(spacing: 0) {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 10) {
        ForEach(items) { item in tile(item) }
      }
      .padding(.horizontal, theme.metrics.pageMargin)
      .padding(.top, 16)

      HStack(spacing: 10) {
        MetroIcon(.settings, size: 18, color: theme.foreground)
        Text("all settings").metroText(.small)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, theme.metrics.pageMargin)
      .padding(.top, 16)
      .padding(.bottom, 12)
      .contentShape(Rectangle())
      .metroTilt { onOpenSettings() }

      Rectangle().fill(theme.border).frame(height: 1)

      Text("no notifications")
        .metroText(.small)
        .foregroundColor(theme.subtle)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.metrics.pageMargin)

      // The handle every WP action-center screenshot shows: a short bar to grab and
      // drag back up.
      Capsule()
        .fill(theme.subtle)
        .frame(width: 44, height: 4)
        .padding(.bottom, 10)
    }
    .background(theme.chrome)
  }

  private func tile(_ item: MetroActionCenterItem) -> some View {
    VStack(spacing: 6) {
      ZStack {
        Rectangle().fill(item.isOn ? theme.accentColor : Color.clear)
        if !item.isOn {
          Rectangle().strokeBorder(theme.border, lineWidth: metroBorderWidth)
        }
        MetroIcon(item.glyph, size: 22, color: item.isOn ? theme.onAccent : theme.foreground)
      }
      .aspectRatio(1, contentMode: .fit)

      Text(item.title)
        .metroText(.small, size: 10.5)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .contentShape(Rectangle())
    .metroTilt { item.action() }
  }
}
