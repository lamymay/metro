import SwiftUI

/// The five-dot indeterminate bar. WP staggered five identical dots along one eased
/// path, which is why they bunch through the middle and thin out at the ends — there is
/// no separate "bunching" animation, it falls out of the curve.
public struct MetroProgressBar: View {
  @Environment(\.metroTheme) private var theme
  @Environment(\.metroMotion) private var motion

  /// `nil` runs the indeterminate five-dot sweep; a value in 0…1 draws a solid bar.
  public var value: Double?

  private let dotCount = 5
  private let dotSize: CGFloat = 5
  /// Fraction of the cycle one dot spends crossing. The remainder is the gap before
  /// the train comes round again.
  private let travelFraction: Double = 0.62
  private let stagger: Double = 0.055

  public init(value: Double? = nil) {
    self.value = value
  }

  public var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      if let value {
        ZStack(alignment: .leading) {
          Rectangle().fill(theme.disabled).frame(height: 4)
          Rectangle()
            .fill(theme.accentColor)
            .frame(width: width * CGFloat(min(max(value, 0), 1)), height: 4)
        }
        .frame(maxHeight: .infinity)
      } else {
        TimelineView(.animation) { timeline in
          let period = motion.duration(motion.progressDotPeriod)
          let now = timeline.date.timeIntervalSinceReferenceDate
          let cycle = period > 0 ? now.truncatingRemainder(dividingBy: period) / period : 0

          ZStack(alignment: .leading) {
            ForEach(0..<dotCount, id: \.self) { index in
              let local = phase(cycle: cycle, index: index)
              if let local {
                Circle()
                  .fill(theme.accentColor)
                  .frame(width: dotSize, height: dotSize)
                  .offset(x: CGFloat(MetroEase(.power(exponent: 2), .easeInOut).progress(local)) * (width - dotSize))
              }
            }
          }
          .frame(maxHeight: .infinity)
        }
      }
    }
    .frame(height: 20)
  }

  /// Where dot `index` is in its own crossing, or `nil` if it is currently off-stage.
  private func phase(cycle: Double, index: Int) -> Double? {
    var local = cycle - Double(index) * stagger
    if local < 0 { local += 1 }
    guard local <= travelFraction else { return nil }
    return local / travelFraction
  }
}

/// WP 8.1's `ProgressRing`: the same five dots, bent round a circle.
public struct MetroProgressRing: View {
  @Environment(\.metroTheme) private var theme
  @Environment(\.metroMotion) private var motion

  public var diameter: CGFloat

  private let dotCount = 5
  private let stagger: Double = 0.08

  public init(diameter: CGFloat = 56) {
    self.diameter = diameter
  }

  public var body: some View {
    TimelineView(.animation) { timeline in
      let period = motion.duration(motion.progressDotPeriod * 0.75)
      let now = timeline.date.timeIntervalSinceReferenceDate
      let cycle = period > 0 ? now.truncatingRemainder(dividingBy: period) / period : 0
      let dot = max(4, diameter * 0.11)
      let radius = (diameter - dot) / 2

      ZStack {
        ForEach(0..<dotCount, id: \.self) { index in
          let angle = self.angle(cycle: cycle, index: index)
          Circle()
            .fill(theme.accentColor)
            .frame(width: dot, height: dot)
            .offset(x: CGFloat(cos(angle)) * radius, y: CGFloat(sin(angle)) * radius)
        }
      }
      .frame(width: diameter, height: diameter)
    }
  }

  /// Orbital angle of dot `index`, in radians, with 12 o'clock at zero.
  private func angle(cycle: Double, index: Int) -> Double {
    var local = cycle - Double(index) * stagger
    if local < 0 { local += 1 }
    let eased = MetroEase(.power(exponent: 1.7), .easeInOut).progress(local)
    return eased * 2 * .pi - .pi / 2
  }
}
