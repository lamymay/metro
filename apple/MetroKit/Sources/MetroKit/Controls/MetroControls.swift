import SwiftUI

/// WP's `PhoneBorderThickness` was 3 device pixels at WVGA. Everything bordered in the
/// system used it, and using anything thinner immediately reads as iOS.
public let metroBorderWidth: CGFloat = 2.5

// MARK: - Button

/// Transparent, bordered, and inverted while pressed — the WP `Button` template
/// swapped `Background` to `PhoneForegroundBrush` and `Foreground` to
/// `PhoneBackgroundBrush` rather than dimming.
public struct MetroButton: View {
  @Environment(\.metroTheme) private var theme
  @Environment(\.metroMotion) private var motion
  @Environment(\.isEnabled) private var isEnabled

  public var title: String
  public var action: () -> Void

  @State private var isPressed = false

  public init(_ title: String, action: @escaping () -> Void) {
    self.title = title
    self.action = action
  }

  public var body: some View {
    let border = isEnabled ? theme.foreground : theme.disabled
    Text(title)
      .metroText(.normal)
      .foregroundColor(isPressed ? theme.background : border)
      .padding(.horizontal, 20)
      .frame(minWidth: 100, minHeight: 46)
      .background(isPressed ? theme.foreground : .clear)
      .overlay(Rectangle().strokeBorder(isPressed ? theme.foreground : border, lineWidth: metroBorderWidth))
      .contentShape(Rectangle())
      .metroTilt(isEnabled: isEnabled) { action() }
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in if isEnabled { isPressed = true } }
          .onEnded { _ in isPressed = false }
      )
      .animation(motion.animation(.wpIn, 0.06), value: isPressed)
      .opacity(isEnabled ? 1 : 0.6)
  }
}

// MARK: - Toggle

/// WP's `ToggleSwitch`: a rectangular track with a rectangular thumb and an On/Off
/// caption. No rounded corners anywhere, and the "on" state is the accent, flat.
public struct MetroToggleSwitch: View {
  @Environment(\.metroTheme) private var theme
  @Environment(\.metroMotion) private var motion

  public var title: String?
  @Binding public var isOn: Bool

  private let trackWidth: CGFloat = 84
  private let trackHeight: CGFloat = 32
  private let thumbWidth: CGFloat = 22

  public init(_ title: String? = nil, isOn: Binding<Bool>) {
    self.title = title
    self._isOn = isOn
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let title {
        Text(title).metroText(.small).foregroundColor(theme.subtle)
      }
      HStack(spacing: 14) {
        ZStack(alignment: isOn ? .trailing : .leading) {
          Rectangle()
            .fill(isOn ? theme.accentColor : Color.clear)
            .overlay(Rectangle().strokeBorder(isOn ? theme.accentColor : theme.border, lineWidth: metroBorderWidth))
            .frame(width: trackWidth, height: trackHeight)
          Rectangle()
            .fill(theme.foreground)
            .frame(width: thumbWidth, height: trackHeight - 8)
            .padding(.horizontal, 4)
        }
        .frame(width: trackWidth, height: trackHeight)
        .contentShape(Rectangle())
        .metroTilt { isOn.toggle() }

        Text(isOn ? "On" : "Off")
          .metroText(.normal)
          .foregroundColor(theme.foreground)
      }
      .animation(motion.animation(.wpIn, 0.18), value: isOn)
    }
  }
}

// MARK: - Check box / radio

public struct MetroCheckBox: View {
  @Environment(\.metroTheme) private var theme

  public var title: String
  @Binding public var isOn: Bool

  public init(_ title: String, isOn: Binding<Bool>) {
    self.title = title
    self._isOn = isOn
  }

  public var body: some View {
    HStack(spacing: 14) {
      ZStack {
        Rectangle()
          .fill(isOn ? theme.accentColor : Color.clear)
          .overlay(Rectangle().strokeBorder(isOn ? theme.accentColor : theme.border, lineWidth: metroBorderWidth))
          .frame(width: 30, height: 30)
        if isOn {
          MetroIcon(.check, size: 20, color: theme.onAccent, weight: 1.0 / 9)
        }
      }
      Text(title).metroText(.normal)
      Spacer(minLength: 0)
    }
    .contentShape(Rectangle())
    .metroTilt { isOn.toggle() }
  }
}

public struct MetroRadioButton: View {
  @Environment(\.metroTheme) private var theme

  public var title: String
  public var isSelected: Bool
  public var action: () -> Void

  public init(_ title: String, isSelected: Bool, action: @escaping () -> Void) {
    self.title = title
    self.isSelected = isSelected
    self.action = action
  }

  public var body: some View {
    HStack(spacing: 14) {
      ZStack {
        Circle()
          .strokeBorder(isSelected ? theme.accentColor : theme.border, lineWidth: metroBorderWidth)
          .frame(width: 30, height: 30)
        if isSelected {
          Circle().fill(theme.accentColor).frame(width: 15, height: 15)
        }
      }
      Text(title).metroText(.normal)
      Spacer(minLength: 0)
    }
    .contentShape(Rectangle())
    .metroTilt { action() }
  }
}

// MARK: - Slider

/// Accent for the filled run, `PhoneDisabledBrush` for the rest, and a hard rectangular
/// thumb. WP's slider had no track rounding and no shadow.
public struct MetroSlider: View {
  @Environment(\.metroTheme) private var theme

  public var title: String?
  @Binding public var value: Double
  public var range: ClosedRange<Double>
  /// Rendered to the right of the title. Handy for a motion inspector.
  public var format: (Double) -> String

  public init(
    _ title: String? = nil,
    value: Binding<Double>,
    in range: ClosedRange<Double>,
    format: @escaping (Double) -> String = { String(format: "%.2f", $0) }
  ) {
    self.title = title
    self._value = value
    self.range = range
    self.format = format
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let title {
        HStack {
          Text(title).metroText(.small).foregroundColor(theme.subtle)
          Spacer(minLength: 8)
          Text(format(value)).metroText(.small).foregroundColor(theme.accentColor)
        }
      }
      GeometryReader { proxy in
        let width = proxy.size.width
        let fraction = normalized
        ZStack(alignment: .leading) {
          Rectangle().fill(theme.disabled).frame(height: 5)
          Rectangle().fill(theme.accentColor).frame(width: width * fraction, height: 5)
          Rectangle()
            .fill(theme.foreground)
            .frame(width: 12, height: 30)
            .offset(x: min(max(width * fraction - 6, 0), width - 12))
        }
        .frame(height: 34)
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { drag in
              let f = min(max(drag.location.x / max(width, 1), 0), 1)
              value = range.lowerBound + f * (range.upperBound - range.lowerBound)
            }
        )
      }
      .frame(height: 34)
    }
  }

  private var normalized: CGFloat {
    let span = range.upperBound - range.lowerBound
    guard span > 0 else { return 0 }
    return CGFloat(min(max((value - range.lowerBound) / span, 0), 1))
  }
}

// MARK: - Text box

/// WP text boxes were light in both themes — white fill, dark text, thick border.
public struct MetroTextBox: View {
  @Environment(\.metroTheme) private var theme

  public var placeholder: String
  @Binding public var text: String

  @FocusState private var focused: Bool

  public init(_ placeholder: String, text: Binding<String>) {
    self.placeholder = placeholder
    self._text = text
  }

  public var body: some View {
    ZStack(alignment: .leading) {
      Rectangle()
        .fill(Color.white)
        .overlay(
          Rectangle().strokeBorder(focused ? theme.accentColor : Color(metroHex: 0x8C8C8C), lineWidth: metroBorderWidth)
        )
      if text.isEmpty {
        Text(placeholder)
          .metroText(.normal)
          .foregroundColor(Color(metroHex: 0x8C8C8C))
          .padding(.horizontal, 12)
          .allowsHitTesting(false)
      }
      TextField("", text: $text)
        .textFieldStyle(.plain)
        .font(theme.type.font(.normal))
        .foregroundColor(.black)
        .focused($focused)
        .padding(.horizontal, 12)
    }
    .frame(height: 48)
  }
}
