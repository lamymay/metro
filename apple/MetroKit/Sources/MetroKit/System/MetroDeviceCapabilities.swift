import Foundation

#if os(iOS)
  import UIKit
  import AVFoundation
#endif

/// The handful of Settings/Action Center toggles that a sandboxed app can *actually*
/// touch. WiFi, Bluetooth, airplane mode and rotation lock all require entitlements an
/// ordinary app can never hold — those stay purely visual, like the rest of the lab.
/// Brightness, torch, battery status and the idle timer do not, so those are wired for
/// real: dragging the brightness tile here changes the actual screen brightness.
@MainActor
public final class MetroDeviceCapabilities: ObservableObject {
  public static let shared = MetroDeviceCapabilities()

  @Published public var brightness: Double
  @Published public var torchOn: Bool = false {
    didSet { applyTorch() }
  }
  /// Mirrors `UIApplication.isIdleTimerDisabled` — "on" keeps the screen from sleeping,
  /// same as WP's own screen-timeout override while charging.
  @Published public var keepAwake: Bool = false {
    didSet {
      #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = keepAwake
      #endif
    }
  }

  @Published public private(set) var batteryLevel: Float = -1
  @Published public private(set) var batteryStateDescription: String = "unknown"
  public var torchAvailable: Bool {
    #if os(iOS)
      return AVCaptureDevice.default(for: .video)?.hasTorch ?? false
    #else
      return false
    #endif
  }

  private init() {
    #if os(iOS)
      brightness = Double(UIScreen.main.brightness)
      UIDevice.current.isBatteryMonitoringEnabled = true
      refreshBattery()
      for name in [UIDevice.batteryLevelDidChangeNotification, UIDevice.batteryStateDidChangeNotification] {
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
          self?.refreshBattery()
        }
      }
    #else
      brightness = 0.8
    #endif
  }

  public func setBrightness(_ value: Double) {
    brightness = value
    #if os(iOS)
      UIScreen.main.brightness = CGFloat(value)
    #endif
  }

  private func refreshBattery() {
    #if os(iOS)
      batteryLevel = UIDevice.current.batteryLevel
      switch UIDevice.current.batteryState {
      case .charging: batteryStateDescription = "charging"
      case .full: batteryStateDescription = "full"
      case .unplugged: batteryStateDescription = "on battery"
      case .unknown: batteryStateDescription = "unknown"
      @unknown default: batteryStateDescription = "unknown"
      }
    #endif
  }

  private func applyTorch() {
    #if os(iOS)
      guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
      do {
        try device.lockForConfiguration()
        device.torchMode = torchOn ? .on : .off
        device.unlockForConfiguration()
      } catch {
        // No permission or no torch on this build target (e.g. Simulator) — leave the
        // toggle in whatever state the UI shows; there is nothing useful to recover.
      }
    #endif
  }
}
