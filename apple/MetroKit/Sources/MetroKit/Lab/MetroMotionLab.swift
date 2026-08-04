import SwiftUI

/// The tuning bench. Every number that drives the kit is on a slider here, and the
/// preview at the top is a live tile you can press while you drag them.
public struct MetroMotionLab: View {
  @Environment(\.metroTheme) private var theme
  @ObservedObject var store: MetroMotionStore

  @State private var curveKind = 0
  @State private var curveMode = MetroEase.Mode.easeOut
  @State private var exponent: Double = 6

  public init(store: MetroMotionStore) {
    self.store = store
  }

  private var curve: MetroEase {
    let kinds: [MetroEase.Kind] = [
      .exponential(exponent: exponent),
      .power(exponent: exponent),
      .circle,
      .back(amplitude: 1),
      .sine,
      .linear,
    ]
    return MetroEase(kinds[min(curveKind, kinds.count - 1)], curveMode)
  }

  public var body: some View {
    MetroPage(applicationTitle: "metrokit", title: "motion") {
      ScrollView {
        VStack(alignment: .leading, spacing: 26) {
          preview
          curveInspector

          group("global") {
            MetroSlider("speed", value: $store.config.speed, in: 0.1...2) { String(format: "%.2f×", $0) }
          }

          group("tilt") {
            MetroSlider("max angle (rad)", value: $store.config.tiltMaxAngle, in: 0...0.8)
            MetroSlider("depression", value: $store.config.tiltMaxDepression, in: 0...0.25)
            MetroSlider("perspective", value: $store.config.tiltPerspective, in: 0.05...1.5)
            MetroSlider("press (s)", value: $store.config.tiltPressDuration, in: 0...0.5)
            MetroSlider("release (s)", value: $store.config.tiltReleaseDuration, in: 0...0.6)
          }

          group("turnstile") {
            MetroSlider("forward out (°)", value: $store.config.turnstileForwardOutAngle, in: -120...0) { String(format: "%.0f°", $0) }
            MetroSlider("forward in (°)", value: $store.config.turnstileForwardInAngle, in: 0...120) { String(format: "%.0f°", $0) }
            MetroSlider("backward out (°)", value: $store.config.turnstileBackwardOutAngle, in: 0...120) { String(format: "%.0f°", $0) }
            MetroSlider("backward in (°)", value: $store.config.turnstileBackwardInAngle, in: -120...0) { String(format: "%.0f°", $0) }
            MetroSlider("in (s)", value: $store.config.turnstileInDuration, in: 0.05...1.2)
            MetroSlider("out (s)", value: $store.config.turnstileOutDuration, in: 0.05...1.2)
            MetroSlider("perspective", value: $store.config.turnstilePerspective, in: 0.05...1.5)
          }

          group("feather") {
            MetroSlider("step (s)", value: $store.config.featherDelay, in: 0...0.3) { String(format: "%.0f ms", $0 * 1000) }
            MetroSlider(
              "max steps",
              value: Binding(
                get: { Double(store.config.featherMaxSteps) },
                set: { store.config.featherMaxSteps = Int($0.rounded()) }
              ),
              in: 1...40
            ) { String(format: "%.0f", $0) }
          }

          group("live tiles") {
            MetroSlider("flip (s)", value: $store.config.tileFlipDuration, in: 0.1...1.5)
            MetroSlider("slide (s)", value: $store.config.tileSlideDuration, in: 0.1...1.5)
            MetroSlider("dwell (s)", value: $store.config.tileDwell, in: 0.5...12)
            MetroSlider("dwell jitter (s)", value: $store.config.tileDwellJitter, in: 0...4)
          }

          group("panorama & pivot") {
            MetroSlider("background parallax", value: $store.config.panoramaParallax, in: 0...1)
            MetroSlider("title parallax", value: $store.config.panoramaTitleParallax, in: 0...1)
            MetroSlider("snap (s)", value: $store.config.panoramaSnapDuration, in: 0.1...1.2)
            MetroSlider("pivot header (s)", value: $store.config.pivotHeaderDuration, in: 0.05...1)
            MetroSlider("pivot content (s)", value: $store.config.pivotContentDuration, in: 0.05...1)
            MetroSlider("pivot lag (s)", value: $store.config.pivotContentDelay, in: 0...0.5) { String(format: "%.0f ms", $0 * 1000) }
          }

          group("progress") {
            MetroSlider("dot period (s)", value: $store.config.progressDotPeriod, in: 0.5...6)
            MetroProgressBar()
          }

          MetroButton("reset to WP defaults") { store.reset() }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, theme.metrics.pageMargin)
      }
    }
  }

  // MARK: Preview strip

  private var preview: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("press the tiles while you tune")
        .metroText(.small)
      HStack(spacing: theme.metrics.gap) {
        MetroTile(
          model: MetroTileModel(
            id: "lab-flip", title: "flip", glyph: .mail, accent: .cobalt,
            size: .medium, badge: 3, behaviour: .flip,
            faces: [.iconic, .counter(3, caption: "unread")]
          ),
          unit: 62, gap: theme.metrics.gap
        )
        MetroTile(
          model: MetroTileModel(
            id: "lab-slide", title: "slide", glyph: .music, accent: .crimson,
            size: .medium, behaviour: .slide,
            faces: [.iconic, .headline("Dayvan Cowboy")]
          ),
          unit: 62, gap: theme.metrics.gap
        )
      }
    }
  }

  // MARK: Curve inspector

  private var curveInspector: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("easing").metroText(.groupHeader)

      TimelineView(.animation) { timeline in
        let now = timeline.date.timeIntervalSinceReferenceDate
        let t = (now.truncatingRemainder(dividingBy: 2.4)) / 2.4
        let clamped = min(max(t, 0), 1)

        Canvas { context, size in
          let inset: CGFloat = 6
          let w = size.width - inset * 2
          let h = size.height - inset * 2

          var grid = Path()
          for i in 0...4 {
            let y = inset + h * CGFloat(i) / 4
            grid.move(to: CGPoint(x: inset, y: y))
            grid.addLine(to: CGPoint(x: inset + w, y: y))
          }
          context.stroke(grid, with: .color(theme.foreground.opacity(0.12)), lineWidth: 1)

          var path = Path()
          let steps = 120
          for i in 0...steps {
            let x = Double(i) / Double(steps)
            let y = curve.progress(x)
            let point = CGPoint(x: inset + w * CGFloat(x), y: inset + h * (1 - CGFloat(y)))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
          }
          context.stroke(path, with: .color(theme.accentColor), lineWidth: 2)

          // Marker running the curve in real time — the fastest way to feel whether a
          // curve is front-loaded or back-loaded.
          let y = curve.progress(clamped)
          let dot = CGRect(
            x: inset + w * CGFloat(clamped) - 4,
            y: inset + h * (1 - CGFloat(y)) - 4,
            width: 8, height: 8
          )
          context.fill(Path(ellipseIn: dot), with: .color(theme.foreground))
        }
        .frame(height: 150)
        .background(theme.mode == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.03))
      }

      HStack(spacing: 8) {
        ForEach(Array(["exp", "pow", "circ", "back", "sine", "lin"].enumerated()), id: \.offset) { index, label in
          Text(label)
            .metroText(.small)
            .foregroundColor(curveKind == index ? theme.onAccent : theme.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(curveKind == index ? theme.accentColor : Color.clear)
            .overlay(Rectangle().strokeBorder(theme.border, lineWidth: curveKind == index ? 0 : 1))
            .contentShape(Rectangle())
            .metroTilt { curveKind = index }
        }
      }

      HStack(spacing: 8) {
        ForEach(MetroEase.Mode.allCases) { mode in
          Text(mode.rawValue)
            .metroText(.small)
            .foregroundColor(curveMode == mode ? theme.onAccent : theme.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(curveMode == mode ? theme.accentColor : Color.clear)
            .overlay(Rectangle().strokeBorder(theme.border, lineWidth: curveMode == mode ? 0 : 1))
            .contentShape(Rectangle())
            .metroTilt { curveMode = mode }
        }
      }

      MetroSlider("exponent", value: $exponent, in: 0.5...10) { String(format: "%.1f", $0) }
      Text(curve.displayName).metroText(.small)
    }
  }

  // MARK: Helpers

  @ViewBuilder private func group<Content: View>(
    _ title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title).metroText(.groupHeader)
      content()
    }
  }
}
