import SwiftUI

/// Windows Phone's easing functions, ported from the Silverlight easing classes that
/// the WP toolkit's storyboards referenced by name.
///
/// Two representations are kept deliberately:
///
/// * ``progress(_:)`` is the *exact* function. Use it when a value is being driven by
///   hand (a `TimelineView`, a drag, the curve inspector) and fidelity matters.
/// * ``animation(duration:)`` is a cubic-bézier fit for SwiftUI's animation system,
///   which cannot take an arbitrary timing function. The fit is close but it is a fit.
///
/// The single most important entry is `.exponential(6)`, which is what
/// `TurnstileTransition`, `SlideTransition` and most of the WP page animations used.
public struct MetroEase: Equatable, Sendable {
  public enum Kind: Equatable, Sendable {
    case linear
    case exponential(exponent: Double)
    case power(exponent: Double)
    case circle
    case back(amplitude: Double)
    case sine
  }

  public enum Mode: String, CaseIterable, Identifiable, Sendable {
    case easeIn, easeOut, easeInOut
    public var id: String { rawValue }
  }

  public var kind: Kind
  public var mode: Mode

  public init(_ kind: Kind, _ mode: Mode) {
    self.kind = kind
    self.mode = mode
  }

  // MARK: Stock curves

  /// `ExponentialEase { EasingMode = EaseOut, Exponent = 6 }` — the WP "arrive" curve.
  public static let wpIn = MetroEase(.exponential(exponent: 6), .easeOut)
  /// `ExponentialEase { EasingMode = EaseIn, Exponent = 6 }` — the WP "leave" curve.
  public static let wpOut = MetroEase(.exponential(exponent: 6), .easeIn)
  public static let linear = MetroEase(.linear, .easeInOut)

  // MARK: Exact evaluation

  /// Eased progress for a normalised time in `0...1`.
  public func progress(_ t: Double) -> Double {
    let t = min(max(t, 0), 1)
    switch mode {
    case .easeIn:
      return easeIn(t)
    case .easeOut:
      return 1 - easeIn(1 - t)
    case .easeInOut:
      return t < 0.5 ? easeIn(t * 2) / 2 : 1 - easeIn((1 - t) * 2) / 2
    }
  }

  /// The `EaseIn` form of the underlying function; the other two modes are derived
  /// from it exactly the way Silverlight's `EasingFunctionBase` derived them.
  private func easeIn(_ t: Double) -> Double {
    switch kind {
    case .linear:
      return t
    case .exponential(let exponent):
      guard abs(exponent) > .ulpOfOne else { return t }
      return (exp(exponent * t) - 1) / (exp(exponent) - 1)
    case .power(let exponent):
      return pow(t, max(exponent, 0))
    case .circle:
      return 1 - sqrt(1 - t * t)
    case .back(let amplitude):
      return pow(t, 3) - t * max(amplitude, 0) * sin(.pi * t)
    case .sine:
      return 1 - sin(.pi / 2 * (1 - t))
    }
  }

  // MARK: SwiftUI fit

  /// Cubic-bézier control points of the `easeOut` form. The other modes are mirrors of
  /// it, so only this one table has to be maintained.
  private var easeOutControlPoints: (Double, Double, Double, Double) {
    switch kind {
    case .linear:
      return (0, 0, 1, 1)
    case .exponential(let exponent):
      // Fitted against `progress(_:)` at t = 0.1 / 0.25 / 0.5. Sharper exponents pull
      // the first control point further toward the origin.
      let k = min(max(exponent / 6, 0.2), 2)
      return (0.02 / k, min(0.35 * k, 0.95), 0.15 / k, 1)
    case .power(let exponent):
      switch exponent {
      case ..<2.5: return (0.5, 1, 0.89, 1)
      case ..<3.5: return (0.33, 1, 0.68, 1)
      case ..<4.5: return (0.25, 1, 0.5, 1)
      default: return (0.22, 1, 0.36, 1)
      }
    case .circle:
      return (0, 0.55, 0.45, 1)
    case .back:
      return (0.34, 1.56, 0.64, 1)
    case .sine:
      return (0.61, 1, 0.88, 1)
    }
  }

  private var controlPoints: (Double, Double, Double, Double) {
    let (x1, y1, x2, y2) = easeOutControlPoints
    switch mode {
    case .easeOut:
      return (x1, y1, x2, y2)
    case .easeIn:
      // Point-reflect the easeOut curve through (0.5, 0.5).
      return (1 - x2, 1 - y2, 1 - x1, 1 - y1)
    case .easeInOut:
      return ((1 - x2) / 2, (1 - y2) / 2, 0.5 + x2 / 2, 0.5 + y2 / 2)
    }
  }

  public func animation(duration: Double) -> Animation {
    if case .linear = kind { return .linear(duration: duration) }
    let (x1, y1, x2, y2) = controlPoints
    return .timingCurve(x1, y1, x2, y2, duration: duration)
  }

  public var displayName: String {
    let base: String
    switch kind {
    case .linear: base = "Linear"
    case .exponential(let e): base = "Exponential \(Int(e))"
    case .power(let e): base = "Power \(Int(e))"
    case .circle: base = "Circle"
    case .back: base = "Back"
    case .sine: base = "Sine"
    }
    if case .linear = kind { return base }
    return "\(base) · \(mode.rawValue)"
  }
}
