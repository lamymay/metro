import SwiftUI

/// The signature Windows Phone press interaction: the element tips in 3D *toward the
/// finger*, and recedes if you press it dead centre.
///
/// This is a port of `Microsoft.Phone.Controls.TiltEffect`. The original normalises the
/// touch point into -0.5…0.5, sums the two magnitudes to get a total angle, then splits
/// that angle between the X and Y rotations in proportion to how far off-axis the touch
/// was. A corner press therefore hits the full `MaxAngle` and tips on both axes; an
/// edge-centre press tips on one axis only; a dead-centre press does not tip at all and
/// only depresses.
public struct MetroTiltState: Equatable, Sendable {
  /// Touch position normalised to -0.5…0.5, origin at the element centre.
  public var normalized: CGPoint?

  public init(normalized: CGPoint? = nil) {
    self.normalized = normalized
  }

  public var isPressed: Bool { normalized != nil }

  /// Total tip, 0…1, where 1 is a corner press.
  public func angleMagnitude() -> Double {
    guard let n = normalized else { return 0 }
    return min(abs(Double(n.x)) + abs(Double(n.y)), 1)
  }

  /// Share of the tip that belongs to the Y (left/right) axis.
  private func xContribution() -> Double {
    guard let n = normalized else { return 0 }
    let x = abs(Double(n.x))
    let y = abs(Double(n.y))
    return x + y > 0 ? x / (x + y) : 0
  }

  /// Degrees about the vertical axis. Positive pushes the right edge away.
  public func rotationY(maxAngle: Double) -> Double {
    guard let n = normalized else { return 0 }
    let degrees = angleMagnitude() * maxAngle * 180 / .pi
    return degrees * xContribution() * (n.x < 0 ? -1 : 1)
  }

  /// Degrees about the horizontal axis. Negative pushes the bottom edge away.
  public func rotationX(maxAngle: Double) -> Double {
    guard let n = normalized else { return 0 }
    let degrees = angleMagnitude() * maxAngle * 180 / .pi
    return -degrees * (1 - xContribution()) * (n.y < 0 ? -1 : 1)
  }

  /// Uniform scale standing in for `GlobalOffsetZ`. Full at the centre, nil at a corner.
  public func scale(maxDepression: Double) -> Double {
    guard normalized != nil else { return 1 }
    return 1 - maxDepression * (1 - angleMagnitude())
  }
}

private struct MetroTiltModifier: ViewModifier {
  @Environment(\.metroMotion) private var motion

  let isEnabled: Bool
  let onTap: (() -> Void)?

  @State private var size: CGSize = .zero
  @State private var state = MetroTiltState()

  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { proxy in
          Color.clear.preference(key: MetroSizeKey.self, value: proxy.size)
        }
      )
      .onPreferenceChange(MetroSizeKey.self) { size = $0 }
      .scaleEffect(state.scale(maxDepression: motion.tiltMaxDepression))
      .rotation3DEffect(
        .degrees(state.rotationX(maxAngle: motion.tiltMaxAngle)),
        axis: (x: 1, y: 0, z: 0),
        perspective: motion.tiltPerspective
      )
      .rotation3DEffect(
        .degrees(state.rotationY(maxAngle: motion.tiltMaxAngle)),
        axis: (x: 0, y: 1, z: 0),
        perspective: motion.tiltPerspective
      )
      .contentShape(Rectangle())
      // `.gesture` claims the touch exclusively, which — with a zero-minimum-distance
      // DragGesture on every tile/row/button in the kit — silently ate every ScrollView
      // in the app: nothing overlaid by a tilt-enabled view could ever scroll, because
      // the ScrollView's own pan recognizer never got a turn. `.simultaneousGesture`
      // lets both run: the tile still tilts toward the finger, but a vertical drag also
      // reaches the ScrollView above it. The tile's own `contains(value.location)` check
      // already resets the tilt once the finger leaves its bounds, so a real scroll
      // still settles the tile back to neutral rather than leaving it stuck tilted.
      .simultaneousGesture(gesture, including: isEnabled ? .all : .subviews)
  }

  private var gesture: some Gesture {
    DragGesture(minimumDistance: 0, coordinateSpace: .local)
      .onChanged { value in
        guard isEnabled, size.width > 0, size.height > 0 else { return }
        // Dragging off the element cancels the press, exactly as WP did.
        guard contains(value.location) else {
          if state.isPressed { release() }
          return
        }
        let next = MetroTiltState(normalized: normalize(value.location))
        if state.isPressed {
          state = next
        } else {
          withAnimation(motion.animation(motion.tiltEase, motion.tiltPressDuration)) {
            state = next
          }
        }
      }
      .onEnded { value in
        guard isEnabled else { return }
        let wasInside = contains(value.location)
        release()
        if wasInside { onTap?() }
      }
  }

  private func contains(_ point: CGPoint) -> Bool {
    point.x >= 0 && point.y >= 0 && point.x <= size.width && point.y <= size.height
  }

  private func normalize(_ point: CGPoint) -> CGPoint {
    CGPoint(
      x: min(max(point.x / size.width, 0), 1) - 0.5,
      y: min(max(point.y / size.height, 0), 1) - 0.5
    )
  }

  private func release() {
    withAnimation(motion.animation(motion.tiltEase, motion.tiltReleaseDuration)) {
      state = MetroTiltState()
    }
  }
}

struct MetroSizeKey: PreferenceKey {
  static let defaultValue = CGSize.zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
    let next = nextValue()
    if next != .zero { value = next }
  }
}

extension View {
  /// Makes the view tilt under a press, and fires `onTap` if the finger lifts inside it.
  public func metroTilt(isEnabled: Bool = true, onTap: (() -> Void)? = nil) -> some View {
    modifier(MetroTiltModifier(isEnabled: isEnabled, onTap: onTap))
  }
}
