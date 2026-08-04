import SwiftUI

/// A hand-drawn stand-in for the Segoe UI Symbol glyphs WP used on tiles and app bars.
///
/// Metro icons are geometric outlines on a fixed optical grid — thin, open, never
/// filled, never rounded except where the object genuinely is round. Drawing them as
/// paths rather than shipping a font keeps the kit redistributable and lets the stroke
/// weight track the theme.
public enum MetroGlyph: String, CaseIterable, Identifiable, Sendable {
  case phone, mail, message, people, camera, calendar, music, store, settings
  case search, back, close, check, plus, pin, globe, clock, photo, folder
  case star, heart, wifi, sun, ellipsis, chevronRight, chevronDown, refresh
  /// The system Start button's glyph. WP printed this on the bezel of every phone,
  /// distinct from any app's own icons — this is a stylised four-petal pinwheel in the
  /// same spirit rather than a reproduction of Microsoft's mark.
  case start
  /// Transport controls, for the music player's now-playing screen.
  case play, pause, skipNext, skipPrevious
  /// Action Center / Settings glyphs.
  case airplane, bluetooth, flashlight

  public var id: String { rawValue }

  /// Builds the glyph inside `rect`, drawn on a unit grid so it stays on the optical
  /// centre at any size.
  public func path(in rect: CGRect) -> Path {
    var p = Path()
    let s = min(rect.width, rect.height)
    let ox = rect.midX - s / 2
    let oy = rect.midY - s / 2
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
    func line(_ a: (CGFloat, CGFloat), _ b: (CGFloat, CGFloat)) {
      p.move(to: pt(a.0, a.1))
      p.addLine(to: pt(b.0, b.1))
    }
    func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
      p.addEllipse(in: CGRect(x: ox + (cx - r) * s, y: oy + (cy - r) * s, width: 2 * r * s, height: 2 * r * s))
    }
    func arc(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ from: CGFloat, _ to: CGFloat) {
      // `addArc` joins the arc to whatever point the path is already at, which turns a
      // set of concentric arcs into a filled blob. Start each one on its own subpath.
      let start = CGPoint(
        x: ox + (cx + cos(from * .pi / 180) * r) * s,
        y: oy + (cy + sin(from * .pi / 180) * r) * s
      )
      p.move(to: start)
      p.addArc(
        center: pt(cx, cy), radius: r * s,
        startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false
      )
    }
    func poly(_ points: [(CGFloat, CGFloat)], closed: Bool = true) {
      guard let first = points.first else { return }
      p.move(to: pt(first.0, first.1))
      for q in points.dropFirst() { p.addLine(to: pt(q.0, q.1)) }
      if closed { p.closeSubpath() }
    }
    func rectangle(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
      p.addRect(CGRect(x: ox + x * s, y: oy + y * s, width: w * s, height: h * s))
    }

    switch self {
    case .phone:
      // Handset: two rounded ends joined by a waist, drawn as a single outline.
      p.move(to: pt(0.18, 0.30))
      p.addQuadCurve(to: pt(0.34, 0.22), control: pt(0.24, 0.20))
      p.addQuadCurve(to: pt(0.40, 0.36), control: pt(0.44, 0.28))
      p.addQuadCurve(to: pt(0.64, 0.60), control: pt(0.50, 0.50))
      p.addQuadCurve(to: pt(0.78, 0.66), control: pt(0.72, 0.56))
      p.addQuadCurve(to: pt(0.70, 0.82), control: pt(0.80, 0.76))
      p.addQuadCurve(to: pt(0.18, 0.30), control: pt(0.20, 0.80))

    case .mail:
      rectangle(0.14, 0.28, 0.72, 0.44)
      poly([(0.14, 0.28), (0.50, 0.55), (0.86, 0.28)], closed: false)

    case .message:
      p.move(to: pt(0.14, 0.24))
      p.addLine(to: pt(0.86, 0.24))
      p.addLine(to: pt(0.86, 0.66))
      p.addLine(to: pt(0.42, 0.66))
      p.addLine(to: pt(0.26, 0.82))
      p.addLine(to: pt(0.26, 0.66))
      p.addLine(to: pt(0.14, 0.66))
      p.closeSubpath()

    case .people:
      circle(0.36, 0.34, 0.14)
      arc(0.36, 0.76, 0.24, 180, 360)
      circle(0.68, 0.36, 0.11)
      arc(0.70, 0.74, 0.19, 200, 340)

    case .camera:
      rectangle(0.10, 0.30, 0.80, 0.44)
      poly([(0.34, 0.30), (0.40, 0.20), (0.60, 0.20), (0.66, 0.30)], closed: false)
      circle(0.50, 0.52, 0.15)

    case .calendar:
      rectangle(0.14, 0.22, 0.72, 0.62)
      line((0.14, 0.38), (0.86, 0.38))
      line((0.32, 0.16), (0.32, 0.28))
      line((0.68, 0.16), (0.68, 0.28))
      for row in 0..<2 {
        for col in 0..<3 {
          let x = 0.26 + CGFloat(col) * 0.20
          let y = 0.50 + CGFloat(row) * 0.18
          rectangle(x, y, 0.08, 0.08)
        }
      }

    case .music:
      line((0.42, 0.72), (0.42, 0.20))
      line((0.42, 0.20), (0.78, 0.12))
      line((0.78, 0.12), (0.78, 0.62))
      circle(0.32, 0.74, 0.11)
      circle(0.68, 0.64, 0.11)

    case .store:
      poly([(0.18, 0.36), (0.82, 0.36), (0.76, 0.84), (0.24, 0.84)])
      arc(0.50, 0.36, 0.18, 180, 360)

    case .settings:
      // A real toothed gear. A circle with radiating spokes reads as a sun, which is
      // the mistake to avoid when `sun` is also in the set.
      let teeth = 8
      let outer: CGFloat = 0.44
      let root: CGFloat = 0.33
      let half: CGFloat = .pi / CGFloat(teeth) * 0.45
      var gear: [(CGFloat, CGFloat)] = []
      for i in 0..<teeth {
        let centre = CGFloat(i) * 2 * .pi / CGFloat(teeth)
        let next = CGFloat(i + 1) * 2 * .pi / CGFloat(teeth)
        gear.append((0.50 + cos(centre - half) * outer, 0.50 + sin(centre - half) * outer))
        gear.append((0.50 + cos(centre + half) * outer, 0.50 + sin(centre + half) * outer))
        gear.append((0.50 + cos(centre + half * 1.6) * root, 0.50 + sin(centre + half * 1.6) * root))
        gear.append((0.50 + cos(next - half * 1.6) * root, 0.50 + sin(next - half * 1.6) * root))
      }
      poly(gear)
      circle(0.50, 0.50, 0.14)

    case .search:
      circle(0.44, 0.44, 0.24)
      line((0.62, 0.62), (0.84, 0.84))

    case .back:
      line((0.16, 0.50), (0.84, 0.50))
      poly([(0.42, 0.26), (0.16, 0.50), (0.42, 0.74)], closed: false)

    case .close:
      line((0.22, 0.22), (0.78, 0.78))
      line((0.78, 0.22), (0.22, 0.78))

    case .check:
      poly([(0.18, 0.52), (0.40, 0.74), (0.84, 0.26)], closed: false)

    case .plus:
      line((0.50, 0.18), (0.50, 0.82))
      line((0.18, 0.50), (0.82, 0.50))

    case .pin:
      // Map pin: round head over a teardrop point.
      circle(0.50, 0.38, 0.20)
      line((0.335, 0.49), (0.50, 0.88))
      line((0.665, 0.49), (0.50, 0.88))

    case .globe:
      circle(0.50, 0.50, 0.36)
      line((0.14, 0.50), (0.86, 0.50))
      p.move(to: pt(0.50, 0.14))
      p.addQuadCurve(to: pt(0.50, 0.86), control: pt(0.20, 0.50))
      p.move(to: pt(0.50, 0.14))
      p.addQuadCurve(to: pt(0.50, 0.86), control: pt(0.80, 0.50))

    case .clock:
      circle(0.50, 0.50, 0.36)
      line((0.50, 0.50), (0.50, 0.26))
      line((0.50, 0.50), (0.68, 0.60))

    case .photo:
      rectangle(0.12, 0.24, 0.76, 0.52)
      poly([(0.12, 0.68), (0.36, 0.44), (0.56, 0.62), (0.68, 0.52), (0.88, 0.70)], closed: false)
      circle(0.68, 0.36, 0.07)

    case .folder:
      poly([(0.12, 0.76), (0.12, 0.26), (0.42, 0.26), (0.50, 0.36), (0.88, 0.36), (0.88, 0.76)])

    case .star:
      var points: [(CGFloat, CGFloat)] = []
      for i in 0..<10 {
        let r: CGFloat = i.isMultiple(of: 2) ? 0.38 : 0.16
        let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
        points.append((0.50 + cos(a) * r, 0.50 + sin(a) * r))
      }
      poly(points)

    case .heart:
      p.move(to: pt(0.50, 0.82))
      p.addCurve(to: pt(0.12, 0.40), control1: pt(0.24, 0.66), control2: pt(0.12, 0.54))
      p.addArc(center: pt(0.31, 0.40), radius: 0.19 * s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
      p.addArc(center: pt(0.69, 0.40), radius: 0.19 * s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
      p.addCurve(to: pt(0.50, 0.82), control1: pt(0.88, 0.54), control2: pt(0.76, 0.66))

    case .wifi:
      circle(0.50, 0.76, 0.05)
      arc(0.50, 0.78, 0.20, 210, 330)
      arc(0.50, 0.78, 0.34, 213, 327)
      arc(0.50, 0.78, 0.48, 216, 324)

    case .sun:
      circle(0.50, 0.50, 0.18)
      for i in 0..<8 {
        let a = CGFloat(i) * .pi / 4
        line(
          (0.50 + cos(a) * 0.28, 0.50 + sin(a) * 0.28),
          (0.50 + cos(a) * 0.42, 0.50 + sin(a) * 0.42)
        )
      }

    case .ellipsis:
      for i in 0..<3 {
        circle(0.26 + CGFloat(i) * 0.24, 0.50, 0.055)
      }

    case .chevronRight:
      poly([(0.38, 0.20), (0.66, 0.50), (0.38, 0.80)], closed: false)

    case .chevronDown:
      poly([(0.20, 0.38), (0.50, 0.66), (0.80, 0.38)], closed: false)

    case .refresh:
      // Open arc with a barb on the free end, so the direction of travel is legible.
      arc(0.50, 0.50, 0.34, -60, 200)
      poly([(0.58, 0.11), (0.67, 0.21), (0.79, 0.17)], closed: false)

    case .start:
      // The four-pane Windows mark: a plain 2×2 grid of filled squares with a visible
      // gap between them — the same glyph WP printed on its own Start button, and a
      // nice echo of the tile grid this button takes you back to.
      rectangle(0.07, 0.07, 0.38, 0.38)
      rectangle(0.55, 0.07, 0.38, 0.38)
      rectangle(0.07, 0.55, 0.38, 0.38)
      rectangle(0.55, 0.55, 0.38, 0.38)

    case .play:
      poly([(0.32, 0.20), (0.32, 0.80), (0.82, 0.50)])

    case .pause:
      rectangle(0.28, 0.20, 0.16, 0.60)
      rectangle(0.56, 0.20, 0.16, 0.60)

    case .skipNext:
      poly([(0.22, 0.22), (0.22, 0.78), (0.62, 0.50)])
      rectangle(0.68, 0.22, 0.12, 0.56)

    case .skipPrevious:
      rectangle(0.20, 0.22, 0.12, 0.56)
      poly([(0.78, 0.22), (0.78, 0.78), (0.38, 0.50)])

    case .airplane:
      poly([(0.10, 0.55), (0.90, 0.20), (0.55, 0.90), (0.48, 0.58)], closed: false)
      line((0.48, 0.58), (0.10, 0.55))
      line((0.48, 0.58), (0.90, 0.20))

    case .bluetooth:
      line((0.50, 0.12), (0.50, 0.88))
      line((0.50, 0.12), (0.74, 0.30))
      line((0.74, 0.30), (0.50, 0.50))
      line((0.50, 0.50), (0.74, 0.70))
      line((0.74, 0.70), (0.50, 0.88))
      line((0.50, 0.50), (0.26, 0.30))
      line((0.50, 0.50), (0.26, 0.70))

    case .flashlight:
      poly([(0.34, 0.40), (0.66, 0.40), (0.58, 0.16), (0.42, 0.16)])
      rectangle(0.38, 0.40, 0.24, 0.46)
    }

    return p
  }

  /// Glyphs whose shape reads better filled than stroked.
  var prefersFill: Bool {
    switch self {
    case .phone, .ellipsis, .start, .play, .pause, .skipNext, .skipPrevious, .flashlight: return true
    default: return false
    }
  }
}

/// Renders a ``MetroGlyph`` at a given size and colour.
public struct MetroIcon: View {
  public let glyph: MetroGlyph
  public var size: CGFloat
  public var color: Color?
  /// Stroke weight relative to the glyph box. WP's icons sat around 1/24.
  public var weight: CGFloat

  @Environment(\.metroTheme) private var theme

  public init(_ glyph: MetroGlyph, size: CGFloat = 28, color: Color? = nil, weight: CGFloat = 1.0 / 22) {
    self.glyph = glyph
    self.size = size
    self.color = color
    self.weight = weight
  }

  public var body: some View {
    let tint = color ?? theme.foreground
    Canvas { context, canvasSize in
      let rect = CGRect(origin: .zero, size: canvasSize)
      let path = glyph.path(in: rect)
      if glyph.prefersFill {
        context.fill(path, with: .color(tint))
      } else {
        context.stroke(
          path,
          with: .color(tint),
          style: StrokeStyle(lineWidth: max(1, size * weight), lineCap: .butt, lineJoin: .miter)
        )
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

/// The circled icon used on a WP application bar.
public struct MetroAppBarIcon: View {
  public let glyph: MetroGlyph
  public var diameter: CGFloat
  public var color: Color?

  @Environment(\.metroTheme) private var theme

  public init(_ glyph: MetroGlyph, diameter: CGFloat = 48, color: Color? = nil) {
    self.glyph = glyph
    self.diameter = diameter
    self.color = color
  }

  public var body: some View {
    let tint = color ?? theme.foreground
    ZStack {
      Circle().strokeBorder(tint, lineWidth: max(1, diameter / 24))
      MetroIcon(glyph, size: diameter * 0.52, color: tint, weight: 1.0 / 16)
    }
    .frame(width: diameter, height: diameter)
  }
}
