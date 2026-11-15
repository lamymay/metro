import SwiftUI

#if os(iOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

extension Color {
  static var systemBackground: Color {
    #if os(iOS)
      return Color(UIColor.systemBackground)
    #elseif os(macOS)
      return Color(NSColor.windowBackgroundColor)
    #else
      return Color.white
    #endif
  }

  static var secondarySystemBackground: Color {
    #if os(iOS)
      return Color(UIColor.secondarySystemBackground)
    #elseif os(macOS)
      return Color(NSColor.controlBackgroundColor)
    #else
      return Color.gray.opacity(0.1)
    #endif
  }

  static var systemGray6: Color {
    #if os(iOS)
      return Color(UIColor.systemGray6)
    #elseif os(macOS)
      return Color(NSColor.quaternaryLabelColor)  // macOS equivalent for light background
    #else
      return Color.gray.opacity(0.15)
    #endif
  }
}
