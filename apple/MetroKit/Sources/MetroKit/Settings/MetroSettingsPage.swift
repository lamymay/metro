import SwiftUI

/// The settings list, split into WP's own "system" / "application" pivot. Every row
/// exists; only a few open something real — the rest are placeholders, same as most of
/// a real phone's settings would be for a UI clone with no device entitlements.
public struct MetroSettingsPage: View {
  public var onSelect: (String) -> Void

  public init(onSelect: @escaping (String) -> Void) {
    self.onSelect = onSelect
  }

  public var body: some View {
    MetroPivot(
      title: "settings",
      items: [
        MetroPivotItem(header: "system") { list(MetroSettingsData.system) },
        MetroPivotItem(header: "application") { list(MetroSettingsData.applications) },
      ]
    )
  }

  private func list(_ items: [MetroSettingsItem]) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
          MetroListRow(title: item.title, subtitle: item.subtitle, glyph: item.glyph) {
            onSelect(item.key)
          }
          .metroFeather(order: index)
        }
      }
      .padding(.bottom, 32)
    }
  }
}

/// Dispatches a settings key to either a real, working control or an honest
/// placeholder. `theme` is threaded through so "start+theme" can drive the same accent
/// picker the rest of the lab uses — it is the one settings screen that was already
/// real everywhere else in the app.
public struct MetroSettingsDetailPage: View {
  @Environment(\.metroTheme) private var envTheme
  @Binding var theme: MetroTheme
  let key: String

  @ObservedObject private var device = MetroDeviceCapabilities.shared
  @State private var cosmeticToggle = false

  public init(key: String, theme: Binding<MetroTheme>) {
    self.key = key
    self._theme = theme
  }

  public var body: some View {
    switch key {
    case "theme":
      MetroAccentLab(theme: $theme)
    case "lockscreen":
      lockScreenPage
    case "brightness":
      brightnessPage
    case "battery":
      batteryPage
    default:
      placeholderPage
    }
  }

  // MARK: Real pages

  private var lockScreenPage: some View {
    MetroPage(applicationTitle: "settings", title: "lock screen") {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text("WP put a screen-timeout picker here. A sandboxed app can't change the system timeout, but it can hold the screen awake itself while this page is open.")
            .metroText(.small)

          MetroToggleSwitch("keep screen on", isOn: Binding(
            get: { device.keepAwake },
            set: { device.keepAwake = $0 }
          ))

          if device.torchAvailable {
            Text("flashlight")
              .metroText(.groupHeader)
              .padding(.top, 8)
            MetroToggleSwitch("torch", isOn: Binding(
              get: { device.torchOn },
              set: { device.torchOn = $0 }
            ))
          }
        }
        .padding(.horizontal, envTheme.metrics.pageMargin)
        .padding(.top, 12)
      }
    }
  }

  private var brightnessPage: some View {
    MetroPage(applicationTitle: "settings", title: "brightness") {
      VStack(alignment: .leading, spacing: 16) {
        Text("This one is real — drag it and the screen changes with it.")
          .metroText(.small)
        MetroSlider(
          "screen brightness",
          value: Binding(
            get: { device.brightness },
            set: { device.setBrightness($0) }
          ),
          in: 0...1,
          format: { String(format: "%.0f%%", $0 * 100) }
        )
      }
      .padding(.horizontal, envTheme.metrics.pageMargin)
      .padding(.top, 12)
    }
  }

  private var batteryPage: some View {
    MetroPage(applicationTitle: "settings", title: "battery saver") {
      VStack(alignment: .leading, spacing: 12) {
        if device.batteryLevel < 0 {
          Text("Battery level isn't available in this environment (the Simulator usually reports -1). On a real device this reads live.")
            .metroText(.small)
        } else {
          Text("\(Int(device.batteryLevel * 100))%")
            .metroText(.huge, size: envTheme.type.size(.title1) * 1.6)
          Text(device.batteryStateDescription)
            .metroText(.small)
        }
      }
      .padding(.horizontal, envTheme.metrics.pageMargin)
      .padding(.top, 12)
    }
  }

  // MARK: Placeholder

  private var placeholderPage: some View {
    let item = MetroSettingsData.item(for: key)
    return MetroPage(applicationTitle: "settings", title: item?.title ?? key) {
      VStack(alignment: .leading, spacing: 20) {
        Text(item?.subtitle ?? "")
          .metroText(.normal)
        Text("WP put a real control here, backed by a system radio (WiFi/Bluetooth/cellular) or a permission (contacts, accounts) this kit has no access to. The toggle below is cosmetic — it remembers its state for this session and nothing else.")
          .metroText(.small)
        MetroToggleSwitch(item?.title ?? "enabled", isOn: $cosmeticToggle)
      }
      .padding(.horizontal, envTheme.metrics.pageMargin)
      .padding(.top, 12)
    }
  }
}
