import Combine
import Foundation
import SwiftUI

public enum ThemeColor: String, CaseIterable, Identifiable {
  case orange
  case blue
  case green
  case teal
  case indigo
  case purple
  case pink
  case red
  case yellow

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .orange: return "橙色"
    case .blue: return "蓝色"
    case .green: return "绿色"
    case .teal: return "青色"
    case .indigo: return "靛蓝"
    case .purple: return "紫色"
    case .pink: return "粉色"
    case .red: return "红色"
    case .yellow: return "黄色"
    }
  }

  public var color: Color {
    switch self {
    case .orange: return .orange
    case .blue: return .blue
    case .green: return .green
    case .teal: return .teal
    case .indigo: return .indigo
    case .purple: return .purple
    case .pink: return .pink
    case .red: return .red
    case .yellow: return .yellow
    }
  }
}

public enum AppAppearance: String, CaseIterable, Identifiable {
  case system
  case light
  case dark

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .system: return "跟随系统"
    case .light: return "浅色"
    case .dark: return "深色"
    }
  }

  public var preferredColorScheme: ColorScheme? {
    switch self {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
  }
}

@MainActor
public final class ThemeManager: ObservableObject {
  public let objectWillChange = ObservableObjectPublisher()

  @AppStorage("theme.primary") private var primaryRaw: String = ThemeColor.orange.rawValue {
    didSet { objectWillChange.send() }
  }

  @AppStorage("theme.appearance") private var appearanceRaw: String = AppAppearance.system.rawValue
  {
    didSet { objectWillChange.send() }
  }

  public init() {}

  public var primarySelection: ThemeColor {
    get { ThemeColor(rawValue: primaryRaw) ?? .orange }
    set { primaryRaw = newValue.rawValue }
  }

  public var primary: Color {
    primarySelection.color
  }

  public var appearanceSelection: AppAppearance {
    get { AppAppearance(rawValue: appearanceRaw) ?? .system }
    set { appearanceRaw = newValue.rawValue }
  }

  public var preferredColorScheme: ColorScheme? {
    appearanceSelection.preferredColorScheme
  }
}
