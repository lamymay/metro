import SwiftUI
import Combine

/// Every timing number in the kit, in one place, so the Motion lab can drive them all
/// from sliders while the rest of the app is running.
///
/// Defaults are the shipping Windows Phone values wherever a shipping value exists;
/// those are called out individually.
public struct MetroMotionConfig: Equatable, Sendable {

  // MARK: Global

  /// Playback multiplier. 0.25 gives you the quarter-speed view the WP design team
  /// used to check feathering; 1 is real time.
  public var speed: Double = 1

  // MARK: Tilt (Microsoft.Phone.Controls.TiltEffect)

  /// `TiltEffect.MaxAngle` — 0.3 rad ≈ 17.2°.
  public var tiltMaxAngle: Double = 0.3
  /// Apparent shrink on a dead-centre press, as a fraction of size. WP expressed this
  /// as `TiltEffect.MaxDepression = 0.2` in `PlaneProjection` Z-units against a fixed
  /// camera; on a tile that lands at roughly a 6% recede, which is what is stored here.
  /// A corner press produces no depression at all — the tip is doing the work.
  public var tiltMaxDepression: Double = 0.06
  /// SwiftUI's `rotation3DEffect` perspective. WP's `PlaneProjection` sat at a fixed
  /// virtual camera distance; 0.55 reads closest on phone-sized tiles.
  public var tiltPerspective: Double = 0.55
  public var tiltPressDuration: Double = 0.1
  public var tiltReleaseDuration: Double = 0.14
  public var tiltEase = MetroEase(.power(exponent: 2), .easeOut)

  // MARK: Turnstile page transition

  /// Degrees the outgoing page swings to on a forward navigation.
  public var turnstileForwardOutAngle: Double = -80
  /// Degrees the incoming page starts from on a forward navigation.
  public var turnstileForwardInAngle: Double = 80
  public var turnstileBackwardOutAngle: Double = 50
  public var turnstileBackwardInAngle: Double = -50
  public var turnstileInDuration: Double = 0.35
  public var turnstileOutDuration: Double = 0.25
  public var turnstilePerspective: Double = 0.6

  // MARK: Feathering
  //
  // WP staggered list rows and start-screen tiles rather than moving them as a block.
  // The 50 ms step is what makes a Metro list "unroll" instead of "slide".

  public var featherDelay: Double = 0.05
  /// Rows past this index all use the same delay, so a long list still finishes.
  public var featherMaxSteps: Int = 12

  // MARK: Live tiles

  public var tileFlipDuration: Double = 0.5
  /// How long a face is held before the tile turns again.
  public var tileDwell: Double = 4.0
  public var tileSlideDuration: Double = 0.45
  /// Extra randomness added to each tile's dwell so a wall of tiles never beats in
  /// lockstep. WP jittered by roughly a second.
  public var tileDwellJitter: Double = 1.0

  // MARK: Panorama

  /// How far the background moves relative to the content. WP's panorama background
  /// was wider than the content and tracked it at a fraction of the speed.
  public var panoramaParallax: Double = 0.32
  /// The title moves faster than the background but slower than the sections.
  public var panoramaTitleParallax: Double = 0.62
  public var panoramaSnapDuration: Double = 0.4

  // MARK: Pivot

  public var pivotHeaderDuration: Double = 0.25
  public var pivotContentDuration: Double = 0.3
  /// The pivot's content lags its header — that offset is the whole trick.
  public var pivotContentDelay: Double = 0.08

  // MARK: Progress

  /// One full sweep of the five-dot indeterminate bar.
  public var progressDotPeriod: Double = 2.4

  public init() {}

  // MARK: Helpers

  /// Scales a duration by ``speed``.
  public func duration(_ base: Double) -> Double {
    base / max(speed, 0.01)
  }

  public func animation(_ ease: MetroEase, _ base: Double) -> Animation {
    ease.animation(duration: duration(base))
  }

  /// Feather delay for the item at `index`, already speed-scaled.
  public func featherDelay(forIndex index: Int) -> Double {
    duration(Double(min(index, featherMaxSteps)) * featherDelay)
  }
}

/// Observable wrapper so a control panel can mutate the config live.
public final class MetroMotionStore: ObservableObject {
  @Published public var config: MetroMotionConfig

  public init(config: MetroMotionConfig = MetroMotionConfig()) {
    self.config = config
  }

  public func reset() {
    config = MetroMotionConfig()
  }
}

// MARK: - Environment

private struct MetroMotionKey: EnvironmentKey {
  static let defaultValue = MetroMotionConfig()
}

extension EnvironmentValues {
  public var metroMotion: MetroMotionConfig {
    get { self[MetroMotionKey.self] }
    set { self[MetroMotionKey.self] = newValue }
  }
}

/// Master switch for the self-starting animations — the feather entrance and the live
/// tiles' turn timer. Off means "render the settled state".
///
/// `accessibilityReduceMotion` covers the user-facing case, but it is read-only, so
/// snapshot tooling and Xcode previews (where `onAppear` never fires and a feathered
/// view would render at zero opacity) need a switch they can actually set.
private struct MetroAnimationsEnabledKey: EnvironmentKey {
  static let defaultValue = true
}

extension EnvironmentValues {
  public var metroAnimationsEnabled: Bool {
    get { self[MetroAnimationsEnabledKey.self] }
    set { self[MetroAnimationsEnabledKey.self] = newValue }
  }
}

extension View {
  public func metroMotion(_ config: MetroMotionConfig) -> some View {
    environment(\.metroMotion, config)
  }

  public func metroAnimationsEnabled(_ enabled: Bool) -> some View {
    environment(\.metroAnimationsEnabled, enabled)
  }
}
