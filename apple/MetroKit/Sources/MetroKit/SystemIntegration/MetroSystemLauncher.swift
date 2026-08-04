import SwiftUI

#if os(iOS)
  import UIKit
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
  /// opens a blank draft — genuinely safe, nothing sends itself.
  public static func openMailCompose(to: String = "", subject: String = "") {
    #if os(iOS)
      var components = URLComponents()
      components.scheme = "mailto"
      components.path = to
      var query: [String] = []
      if !subject.isEmpty {
        query.append("subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
      }
      if !query.isEmpty { components.query = query.joined(separator: "&") }
      guard let url = components.url else { return }
      UIApplication.shared.open(url)
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

  #if os(iOS)
    public static var cameraAvailable: Bool {
      UIImagePickerController.isSourceTypeAvailable(.camera)
    }
  #endif
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
