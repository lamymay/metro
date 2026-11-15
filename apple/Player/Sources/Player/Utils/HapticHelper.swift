import SwiftUI

#if os(iOS)
  import UIKit
#endif

public struct HapticHelper {
  public static func trigger(_ style: HapticStyle = .medium) {
    #if os(iOS)
      let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
      switch style {
      case .light: uiStyle = .light
      case .medium: uiStyle = .medium
      case .heavy: uiStyle = .heavy
      }
      UIImpactFeedbackGenerator(style: uiStyle).impactOccurred()
    #endif
  }

  public static func selectionChanged() {
    #if os(iOS)
      UISelectionFeedbackGenerator().selectionChanged()
    #endif
  }

  public enum HapticStyle {
    case light, medium, heavy
  }
}
