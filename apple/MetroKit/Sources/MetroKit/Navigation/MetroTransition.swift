import SwiftUI

public enum MetroNavDirection: String, Sendable {
  case forward, backward
}

/// The page transitions from `Microsoft.Phone.Controls.Toolkit`.
public enum MetroTransitionKind: String, CaseIterable, Identifiable, Sendable {
  /// The default. Pages swing about their left edge like a revolving door.
  case turnstile
  /// `SlideTransition` — vertical translate with a fade.
  case slide
  /// `SwivelTransition` — tips about the horizontal axis. WP used it for dialogs and
  /// for navigating *within* a hub.
  case swivel
  /// An approximation of `ContinuumTransition`, which handed the tapped list item off
  /// to the next page's title. Without a shared element this reduces to a rise + scale.
  case continuum
  case none

  public var id: String { rawValue }
  public var displayName: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
}

/// Drives both halves of a page transition from a single 0…1 clock.
///
/// WP ran the outgoing storyboard, waited for it, then ran the incoming one. Rather
/// than chaining two SwiftUI animations and hoping the seam lands, this animates one
/// `progress` linearly across the whole sequence and applies the real exponential
/// easing *inside* the body — so the curve is exact and the handover is exact.
struct MetroTransitionStage<Content: View>: View, Animatable {
  var progress: Double
  var kind: MetroTransitionKind
  var direction: MetroNavDirection
  var config: MetroMotionConfig
  var outgoing: Content
  var incoming: Content

  var animatableData: Double {
    get { progress }
    set { progress = newValue }
  }

  private var split: Double {
    let total = config.turnstileOutDuration + config.turnstileInDuration
    return total > 0 ? config.turnstileOutDuration / total : 0.5
  }

  var body: some View {
    if progress < split {
      let t = split > 0 ? min(progress / split, 1) : 1
      leaving(MetroEase.wpOut.progress(t))
    } else {
      let t = min((progress - split) / max(1 - split, 0.0001), 1)
      arriving(MetroEase.wpIn.progress(t), linear: t)
    }
  }

  // MARK: Leaving

  @ViewBuilder private func leaving(_ e: Double) -> some View {
    switch kind {
    case .turnstile:
      let angle = direction == .forward
        ? config.turnstileForwardOutAngle
        : config.turnstileBackwardOutAngle
      outgoing
        .rotation3DEffect(
          .degrees(angle * e), axis: (x: 0, y: 1, z: 0),
          anchor: .leading, perspective: config.turnstilePerspective
        )
        .opacity(1 - e)

    case .slide:
      outgoing
        .offset(y: e * (direction == .forward ? -180 : 180))
        .opacity(1 - e)

    case .swivel:
      outgoing
        .rotation3DEffect(
          .degrees(45 * e * (direction == .forward ? 1 : -1)),
          axis: (x: 1, y: 0, z: 0), anchor: .center,
          perspective: config.turnstilePerspective
        )
        .opacity(1 - e)

    case .continuum:
      outgoing
        .scaleEffect(1 - 0.12 * e, anchor: .top)
        .offset(y: -60 * e)
        .opacity(1 - e)

    case .none:
      outgoing.opacity(0)
    }
  }

  // MARK: Arriving

  @ViewBuilder private func arriving(_ e: Double, linear: Double) -> some View {
    // WP ramped the incoming page's opacity over 0.001s — it is present from frame one
    // and only the transform animates. A cross-fade here is the classic tell.
    let appear = min(linear * 40, 1)

    switch kind {
    case .turnstile:
      let angle = direction == .forward
        ? config.turnstileForwardInAngle
        : config.turnstileBackwardInAngle
      incoming
        .rotation3DEffect(
          .degrees(angle * (1 - e)), axis: (x: 0, y: 1, z: 0),
          anchor: .leading, perspective: config.turnstilePerspective
        )
        .opacity(appear)

    case .slide:
      incoming
        .offset(y: (1 - e) * (direction == .forward ? 220 : -220))
        .opacity(appear)

    case .swivel:
      incoming
        .rotation3DEffect(
          .degrees(-30 * (1 - e) * (direction == .forward ? 1 : -1)),
          axis: (x: 1, y: 0, z: 0), anchor: .center,
          perspective: config.turnstilePerspective
        )
        .opacity(appear)

    case .continuum:
      incoming
        .scaleEffect(0.88 + 0.12 * e, anchor: .bottom)
        .offset(y: (1 - e) * 90)
        .opacity(appear)

    case .none:
      incoming
    }
  }
}
