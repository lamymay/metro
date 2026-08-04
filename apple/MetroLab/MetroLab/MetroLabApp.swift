import SwiftUI
import MetroKit

/// The whole app. The MetroKit design system still lives here for later reuse, but the
/// running app is a dedicated, pixel-matched recreation of one specific Lumia Icon
/// start-screen photo — see `LumiaStartScreen.swift`.
@main
struct MetroLabApp: App {
  var body: some Scene {
    WindowGroup {
      LumiaStartScreen()
        // The Metro dark theme is pure black; matching the system chrome to it keeps
        // the status bar and title bar from breaking the edge-to-edge fill.
        .preferredColorScheme(.dark)
    }
  }
}

#Preview {
  LumiaStartScreen()
}
