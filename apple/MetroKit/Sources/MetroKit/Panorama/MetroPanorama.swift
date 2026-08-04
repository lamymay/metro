import SwiftUI

public struct MetroPanoramaSection: Identifiable {
  public var id: String
  public var title: String
  public var content: AnyView

  public init<Content: View>(id: String? = nil, title: String, @ViewBuilder content: () -> Content) {
    self.id = id ?? title
    self.title = title
    self.content = AnyView(content())
  }
}

/// The WP panorama: one long canvas seen through a phone-sized window, with three
/// layers moving at three different rates.
///
/// The layering is the whole idea — background slowest, title next, sections at 1:1 —
/// and the sections are deliberately *narrower* than the screen so the next one always
/// peeks in from the right. Get the peek wrong and it stops reading as a panorama.
///
/// Known simplification: WP's panorama wrapped infinitely. This one clamps at both ends.
public struct MetroPanorama<Background: View>: View {
  @Environment(\.metroTheme) private var theme
  @Environment(\.metroMotion) private var motion

  public var title: String
  public var sections: [MetroPanoramaSection]
  public var peek: CGFloat
  public var background: Background

  @State private var scrollX: CGFloat = 0
  @GestureState private var drag: CGFloat = 0

  public init(
    title: String,
    sections: [MetroPanoramaSection],
    peek: CGFloat = 56,
    @ViewBuilder background: () -> Background
  ) {
    self.title = title
    self.sections = sections
    self.peek = peek
    self.background = background()
  }

  public var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let sectionWidth = max(width - peek, 120)
      let maxScroll = max(CGFloat(sections.count - 1) * sectionWidth, 0)
      let offset = min(max(scrollX - drag, 0), maxScroll)

      ZStack(alignment: .topLeading) {
        // Layer 1 — background. Oversized so it never runs out while panning.
        background
          .frame(width: width + maxScroll * CGFloat(motion.panoramaParallax) + 80)
          .offset(x: -offset * CGFloat(motion.panoramaParallax))
          .clipped()

        VStack(alignment: .leading, spacing: 0) {
          // Layer 2 — title. Oversized and allowed to run off the right edge.
          Text(title)
            .metroText(.panoramaTitle)
            .foregroundColor(theme.foreground)
            .lineLimit(1)
            .fixedSize()
            .padding(.leading, theme.metrics.pageMargin)
            .offset(x: -offset * CGFloat(motion.panoramaTitleParallax))
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()

          // Layer 3 — sections, 1:1 with the finger.
          HStack(alignment: .top, spacing: 0) {
            ForEach(sections) { section in
              VStack(alignment: .leading, spacing: 10) {
                Text(section.title)
                  .metroText(.title2)
                  .padding(.leading, theme.metrics.pageMargin)
                section.content
                  .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
              }
              .frame(width: sectionWidth, alignment: .topLeading)
            }
          }
          .frame(width: CGFloat(sections.count) * sectionWidth, alignment: .leading)
          .offset(x: -offset)
          .frame(maxWidth: .infinity, alignment: .leading)
          .clipped()
        }
        .padding(.top, 18)
      }
      .frame(width: width, height: proxy.size.height, alignment: .topLeading)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 8)
          .updating($drag) { value, state, _ in state = value.translation.width }
          .onEnded { value in
            // Predict where the flick was heading, then snap to the nearest section.
            let predicted = scrollX - value.predictedEndTranslation.width
            let index = (predicted / sectionWidth).rounded()
            let target = min(max(index, 0), CGFloat(sections.count - 1)) * sectionWidth
            withAnimation(motion.animation(.wpIn, motion.panoramaSnapDuration)) {
              scrollX = target
            }
          }
      )
    }
  }
}

extension MetroPanorama where Background == MetroPanoramaBackground {
  public init(title: String, sections: [MetroPanoramaSection], peek: CGFloat = 56) {
    self.init(title: title, sections: sections, peek: peek) { MetroPanoramaBackground() }
  }
}

/// A stand-in for the photographic backgrounds WP panoramas shipped with: an accent
/// wash plus a sparse grid, drawn rather than bundled so the kit stays asset-free.
public struct MetroPanoramaBackground: View {
  @Environment(\.metroTheme) private var theme

  public init() {}

  public var body: some View {
    Canvas { context, size in
      let base = theme.mode == .dark ? Color.black : Color.white
      context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(base))
      context.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .linearGradient(
          Gradient(colors: [theme.accentColor.opacity(0.55), theme.accentColor.opacity(0.04)]),
          startPoint: .zero,
          endPoint: CGPoint(x: size.width, y: size.height)
        )
      )

      let step: CGFloat = 64
      var path = Path()
      var x: CGFloat = 0
      while x < size.width {
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: size.height))
        x += step
      }
      var y: CGFloat = 0
      while y < size.height {
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: size.width, y: y))
        y += step
      }
      context.stroke(path, with: .color(theme.foreground.opacity(0.06)), lineWidth: 1)
    }
  }
}
