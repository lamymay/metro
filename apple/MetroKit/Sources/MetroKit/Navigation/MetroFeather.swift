import SwiftUI

/// The turnstile-feather entrance: each element swings in about its own left edge,
/// staggered by a fixed step down the reading order.
///
/// WP applied this to start-screen tiles, list rows and pivot content. It is what makes
/// a Metro screen "unroll" instead of sliding in as a slab, and the 50 ms step is the
/// whole reason it reads as one gesture rather than as N separate animations.
private struct MetroFeatherModifier: ViewModifier {
  @Environment(\.metroMotion) private var motion
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.metroAnimationsEnabled) private var animationsEnabled

  let order: Int
  let backward: Bool

  @State private var shown = false

  func body(content: Content) -> some View {
    // The entrance is the only thing standing between the user and the content, so
    // Reduce Motion skips it outright rather than shortening it. This is also the hook
    // snapshot tooling uses, since `onAppear` never fires under `ImageRenderer`.
    if reduceMotion || !animationsEnabled {
      content
    } else {
      animated(content)
    }
  }

  @ViewBuilder private func animated(_ content: Content) -> some View {
    let delay = motion.featherDelay(forIndex: order)
    let angle = backward ? motion.turnstileBackwardInAngle : motion.turnstileForwardInAngle

    content
      // WP ramped opacity over 0.001s at the start of the storyboard — the element is
      // simply present, it does not fade. Keeping that separate from the rotation
      // matters: a cross-fade here reads as iOS, not as Metro.
      .opacity(shown ? 1 : 0)
      .animation(.linear(duration: 0.001).delay(delay), value: shown)
      .rotation3DEffect(
        .degrees(shown ? 0 : angle),
        axis: (x: 0, y: 1, z: 0),
        anchor: .leading,
        perspective: motion.turnstilePerspective
      )
      .onAppear {
        withAnimation(motion.animation(.wpIn, motion.turnstileInDuration).delay(delay)) {
          shown = true
        }
      }
  }
}

extension View {
  /// Swings the view in about its left edge, delayed by its position in the reading
  /// order. Re-triggers whenever the view is rebuilt, so pair it with `.id(token)` if
  /// you want to replay it on demand.
  public func metroFeather(order: Int, backward: Bool = false) -> some View {
    modifier(MetroFeatherModifier(order: order, backward: backward))
  }
}
