import SwiftUI

#if os(iOS)
  import UIKit
  import AVFoundation
#elseif os(macOS)
  import AppKit
#endif

/// The three system hand-offs a sandboxed app can make honestly: dial the phone,
/// compose mail in the default client, and capture a photo with the real camera UI.
/// There is no public API to switch to the separate Phone or Camera *apps* — dialling
/// and photo capture are done by presenting the same system-provided UI in place,
/// which is the sanctioned equivalent and is what every third-party app actually does.
public enum MetroSystemLauncher {
  /// Opens the system dialer pre-filled with a reserved, non-working number (the
  /// North American "555" block) — this kit has no real contact to call, and iOS
  /// always shows its own Cancel/Call confirmation before anything dials.
  public static func openPhoneDialer(number: String = "18005550100") {
    #if os(iOS)
      guard let url = URL(string: "tel://\(number)") else { return }
      UIApplication.shared.open(url)
    #endif
  }

  /// Opens the default mail client's compose sheet. `mailto:` with no recipient just
  /// opens a blank draft — genuinely safe, nothing sends itself. On macOS this hands
  /// the same `mailto:` URL to `NSWorkspace`, which routes it to whatever app is set
  /// as the system default (Mail.app unless the user changed it).
  public static func openMailCompose(to: String = "", subject: String = "") {
    var components = URLComponents()
    components.scheme = "mailto"
    components.path = to
    var query: [String] = []
    if !subject.isEmpty {
      query.append("subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
    }
    if !query.isEmpty { components.query = query.joined(separator: "&") }
    guard let url = components.url else { return }
    #if os(iOS)
      UIApplication.shared.open(url)
    #elseif os(macOS)
      NSWorkspace.shared.open(url)
    #endif
  }

  /// Opens the default Messages app via the `sms:` scheme — same idea as
  /// ``openMailCompose(to:subject:)``, just no compose-window equivalent to prefill.
  public static func openMessages(to: String = "") {
    #if os(iOS)
      guard let url = URL(string: "sms:\(to)") else { return }
      UIApplication.shared.open(url)
    #endif
  }

  /// Opens Apple Maps. iOS has no public API to enumerate or prompt between installed
  /// navigation apps the way Android's implicit-intent chooser does — that's a genuine
  /// platform gap, not a shortcut taken here; a real chooser would need every
  /// competing app's scheme declared in `LSApplicationQueriesSchemes` up front.
  public static func openMaps() {
    #if os(iOS)
      guard let url = URL(string: "http://maps.apple.com/") else { return }
      UIApplication.shared.open(url)
    #endif
  }

  /// Opens the system Photos app via its (undocumented but long-stable) redirect
  /// scheme, falling back to the in-kit Photos hub if that ever stops resolving.
  public static func openPhotos(fallback: @escaping () -> Void) {
    #if os(iOS)
      guard let url = URL(string: "photos-redirect://") else {
        fallback()
        return
      }
      UIApplication.shared.open(url, options: [:]) { ok in
        if !ok { fallback() }
      }
    #else
      fallback()
    #endif
  }

  /// Opens the system default music player app (Apple Music, via its stable
  /// `music://` redirect scheme) — the third of Metro's three music player systems,
  /// alongside the WP-recreation player and the ``Player`` package's own native UI.
  public static func openSystemMusicPlayer() {
    #if os(iOS)
      guard let url = URL(string: "music://") else { return }
      UIApplication.shared.open(url)
    #endif
  }

  /// Whether the system can present a real camera-capture UI in place. Always false
  /// off iOS — macOS/iPadOS-as-Mac-Catalyst-less builds have no `UIImagePickerController`
  /// equivalent here, so callers should treat `false` as "fall back to a placeholder",
  /// not as an error.
  ///
  /// This only reports whether the *hardware* exists — it says nothing about
  /// permission. `UIImagePickerController` doesn't ask for camera access itself and
  /// silently shows a blank screen if access was previously denied, so callers must
  /// go through ``requestCameraAccess(completion:)`` before presenting it.
  public static var cameraAvailable: Bool {
    #if os(iOS)
      UIImagePickerController.isSourceTypeAvailable(.camera)
    #else
      false
    #endif
  }

  /// Resolves camera permission before a caller presents ``MetroCameraCapture``.
  /// `.authorized` means it's safe to present now; `.notDetermined` means the system
  /// prompt was just shown and the completion fires once the person answers it;
  /// `.denied`/`.restricted` means presenting the picker would just show a blank
  /// screen, so the caller should route to Settings instead.
  public enum CameraAccess { case authorized, denied }

  public static func requestCameraAccess(completion: @escaping (CameraAccess) -> Void) {
    #if os(iOS)
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
        completion(.authorized)
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          DispatchQueue.main.async { completion(granted ? .authorized : .denied) }
        }
      case .denied, .restricted:
        completion(.denied)
      @unknown default:
        completion(.denied)
      }
    #else
      completion(.denied)
    #endif
  }

  /// Opens this app's page in the system Settings app — the only way to recover from
  /// a previously-denied camera prompt, since re-presenting the picker won't ask again.
  public static func openAppSettings() {
    #if os(iOS)
      guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
      UIApplication.shared.open(url)
    #endif
  }
}

#if os(iOS)
  /// Wraps `UIImagePickerController(sourceType: .camera)` — the real, system-provided
  /// capture screen (shutter, flash toggle, front/back swap), not a redrawn stand-in.
  public struct MetroCameraCapture: UIViewControllerRepresentable {
    public var onCapture: (UIImage?) -> Void
    public var onCancel: () -> Void

    public init(onCapture: @escaping (UIImage?) -> Void, onCancel: @escaping () -> Void) {
      self.onCapture = onCapture
      self.onCancel = onCancel
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
      let picker = UIImagePickerController()
      picker.sourceType = .camera
      picker.delegate = context.coordinator
      return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator { Coordinator(self) }

    public final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
      let parent: MetroCameraCapture
      init(_ parent: MetroCameraCapture) { self.parent = parent }

      public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
      ) {
        parent.onCapture(info[.originalImage] as? UIImage)
      }

      public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        parent.onCancel()
      }
    }
  }
#endif
