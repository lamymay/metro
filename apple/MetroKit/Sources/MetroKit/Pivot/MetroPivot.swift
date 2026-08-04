import SwiftUI

public struct MetroPivotItem: Identifiable {
  public var id: String
  public var header: String
  public var content: AnyView

  public init<Content: View>(id: String? = nil, header: String, @ViewBuilder content: () -> Content) {
    self.id = id ?? header
    self.header = header
    self.content = AnyView(content())
  }
}

/// The WP pivot: a carousel of oversized header words with the content sliding beneath.
///
/// The detail that makes it a pivot rather than a tab bar is that the header and the
/// content move at *different times* — the header leads, the content follows a beat
/// later. `pivotContentDelay` is that beat.
///
/// Known simplification: WP's pivot wrapped past the last item. This one clamps.
public struct MetroPivot: View {
  @Environment(\.metroTheme) private var theme
  @Environment(\.metroMotion) private var motion

  public var title: String?
  public var items: [MetroPivotItem]

  /// Continuous item positions, in item units. Dragging writes both directly, which is
  /// what keeps the release from jumping.
  @State private var headerPos: Double = 0
  @State private var contentPos: Double = 0
  @State private var dragStart: Double = 0
  @State private var isDragging = false
  @State private var headerWidths: [Int: CGFloat] = [:]

  private let headerSpacing: CGFloat = 24

  public init(title: String? = nil, items: [MetroPivotItem]) {
    self.title = title
    self.items = items
  }

  public var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width

      VStack(alignment: .leading, spacing: 0) {
        if let title {
          MetroApplicationTitle(title)
            .padding(.leading, theme.metrics.pageMargin)
            .padding(.top, 14)
        }

        headerRow
          .padding(.top, 6)
          .padding(.bottom, 10)

        contentRow(width: width)
      }
      .frame(width: width, height: proxy.size.height, alignment: .topLeading)
      .contentShape(Rectangle())
      .gesture(dragGesture(width: width))
    }
    .onPreferenceChange(MetroHeaderWidthsKey.self) { headerWidths = $0 }
  }

  // MARK: Headers

  private var headerRow: some View {
    HStack(alignment: .firstTextBaseline, spacing: headerSpacing) {
      ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
        Text(item.header)
          .metroText(.pivotHeader)
          .foregroundColor(theme.foreground)
          // Neighbours dim rather than disappear; that is how a pivot advertises that
          // there is more to the left and right.
          .opacity(headerOpacity(for: index))
          .fixedSize()
          .background(
            GeometryReader { p in
              Color.clear.preference(key: MetroHeaderWidthsKey.self, value: [index: p.size.width])
            }
          )
          .contentShape(Rectangle())
          .metroTilt { go(to: index) }
      }
    }
    .padding(.leading, theme.metrics.pageMargin)
    .offset(x: -interpolatedHeaderOffset(headerPos))
    .frame(maxWidth: .infinity, alignment: .leading)
    .clipped()
  }

  private func headerOpacity(for index: Int) -> Double {
    let distance = abs(Double(index) - headerPos)
    return distance < 0.001 ? 1 : max(0.4, 1 - distance * 0.55)
  }

  /// Cumulative x of header `index` within the row.
  private func headerOffset(_ index: Int) -> CGFloat {
    guard index > 0 else { return 0 }
    return (0..<index).reduce(CGFloat(0)) { $0 + (headerWidths[$1] ?? 80) + headerSpacing }
  }

  private func interpolatedHeaderOffset(_ position: Double) -> CGFloat {
    let low = Int(position.rounded(.down))
    let high = low + 1
    let t = CGFloat(position - Double(low))
    let a = headerOffset(min(max(low, 0), max(items.count - 1, 0)))
    let b = headerOffset(min(max(high, 0), max(items.count - 1, 0)))
    return a + (b - a) * t
  }

  // MARK: Content

  private func contentRow(width: CGFloat) -> some View {
    HStack(spacing: 0) {
      ForEach(items) { item in
        item.content
          .frame(width: width, alignment: .topLeading)
      }
    }
    .frame(width: width * CGFloat(items.count), alignment: .leading)
    .offset(x: -CGFloat(contentPos) * width)
    .frame(maxWidth: .infinity, alignment: .leading)
    .clipped()
  }

  // MARK: Gesture

  private func dragGesture(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 10)
      .onChanged { value in
        guard width > 0 else { return }
        if !isDragging {
          isDragging = true
          dragStart = contentPos
        }
        // Rubber-band a little past both ends rather than hard-stopping.
        let raw = dragStart - Double(value.translation.width / width)
        let clamped = min(max(raw, -0.35), Double(items.count - 1) + 0.35)
        headerPos = clamped
        contentPos = clamped
      }
      .onEnded { value in
        guard width > 0 else { return }
        isDragging = false
        let predicted = dragStart - Double(value.predictedEndTranslation.width / width)
        go(to: Int(predicted.rounded()))
      }
  }

  private func go(to rawIndex: Int) {
    let target = Double(min(max(rawIndex, 0), max(items.count - 1, 0)))
    withAnimation(motion.animation(.wpIn, motion.pivotHeaderDuration)) {
      headerPos = target
    }
    withAnimation(
      motion.animation(.wpIn, motion.pivotContentDuration)
        .delay(motion.duration(motion.pivotContentDelay))
    ) {
      contentPos = target
    }
  }
}

struct MetroHeaderWidthsKey: PreferenceKey {
  static let defaultValue: [Int: CGFloat] = [:]
  static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
    value.merge(nextValue()) { _, new in new }
  }
}
