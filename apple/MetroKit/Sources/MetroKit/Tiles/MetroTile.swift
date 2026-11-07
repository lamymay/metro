import SwiftUI

/// A single live tile: fill, face, caption, badge, tilt and its own turn timer.
///
/// Sized from `unit` — the side of a *small* tile — so every tile on a start screen is
/// laid out from one number, exactly as WP's grid was.
public struct MetroTile: View {
  @Environment(\.metroTheme) private var theme
  @Environment(\.metroMotion) private var motion
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.metroAnimationsEnabled) private var animationsEnabled

  public let model: MetroTileModel
  public var unit: CGFloat
  public var gap: CGFloat
  public var onSelect: ((MetroTileModel) -> Void)?

  @State private var turn: Double = 0

  public init(
    model: MetroTileModel,
    unit: CGFloat,
    gap: CGFloat = 12,
    onSelect: ((MetroTileModel) -> Void)? = nil
  ) {
    self.model = model
    self.unit = unit
    self.gap = gap
    self.onSelect = onSelect
  }

  public var width: CGFloat { unit * CGFloat(model.size.columns) + gap * CGFloat(model.size.columns - 1) }
  public var height: CGFloat { unit * CGFloat(model.size.rows) + gap * CGFloat(model.size.rows - 1) }

  private var isLive: Bool { model.behaviour != .static && model.faces.count > 1 }

  public var body: some View {
    ZStack {
      model.fill(in: theme)
      deck
    }
    .frame(width: width, height: height)
    .overlay {
      if model.style == .transparent {
        Rectangle().strokeBorder(theme.foreground.opacity(0.18), lineWidth: 1)
      }
    }
    .clipped()
    .metroTilt { onSelect?(model) }
    .task(id: liveTaskID) { await runLiveLoop() }
  }

  @ViewBuilder private var deck: some View {
    switch model.behaviour {
    case .static:
      face(at: 0)
    case .flip:
      MetroFlipDeck(
        progress: turn,
        perspective: motion.turnstilePerspective,
        faceCount: model.faces.count
      ) { face(at: $0) }
    case .slide:
      MetroSlideDeck(
        progress: turn,
        height: height,
        faceCount: model.faces.count
      ) { face(at: $0) }
    }
  }

  private func face(at index: Int) -> some View {
    MetroTileFaceView(
      face: model.faces[min(max(index, 0), model.faces.count - 1)],
      model: model,
      unit: unit
    )
    .frame(width: width, height: height)
  }

  // MARK: Live loop

  private var liveTaskID: String { "\(model.id)-\(model.behaviour.rawValue)-\(model.faces.count)" }

  private func runLiveLoop() async {
    // A wall of tiles turning on their own is exactly what Reduce Motion is for.
    guard isLive, !reduceMotion, animationsEnabled else { return }
    // Deterministic per-tile offset. A wall of tiles beating in lockstep is the single
    // most obvious way to get a live start screen wrong.
    let jitter = Double(abs(model.id.hashValue) % 1000) / 1000 * motion.tileDwellJitter
    try? await Task.sleep(nanoseconds: UInt64(max(0, jitter) * 1_000_000_000))

    while !Task.isCancelled {
      let dwell = motion.duration(motion.tileDwell)
      try? await Task.sleep(nanoseconds: UInt64(max(0.05, dwell) * 1_000_000_000))
      guard !Task.isCancelled else { return }

      let base = model.behaviour == .flip ? motion.tileFlipDuration : motion.tileSlideDuration
      withAnimation(motion.animation(.wpIn, base)) {
        turn += 1
      }
    }
  }
}

// MARK: - Faces

/// Renders one face. The caption and badge live on the *resting* face rather than on
/// the tile, because in WP they turn away with it when the tile flips.
struct MetroTileFaceView: View {
  @Environment(\.metroTheme) private var theme

  let face: MetroTileFace
  let model: MetroTileModel
  let unit: CGFloat

  private var tint: Color { model.foreground(in: theme) }
  private var padding: CGFloat { max(7, unit * 0.09) }

  var body: some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder private var content: some View {
    switch face {
    case .iconic:
      restingFace(model.glyph)

    case .glyph(let glyph):
      MetroIcon(glyph, size: glyphSize, color: tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    case .headline(let text):
      Text(text)
        .metroText(.title2, size: unit * 0.20)
        .foregroundColor(tint)
        .lineLimit(4)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(padding)

    case .message(let from, let body):
      VStack(alignment: .leading, spacing: unit * 0.04) {
        Text(from)
          .metroText(.groupHeader, size: unit * 0.145)
          .foregroundColor(tint)
          .lineLimit(1)
        Text(body)
          .metroText(.small, size: unit * 0.135)
          .foregroundColor(tint.opacity(0.85))
          .lineLimit(3)
          .multilineTextAlignment(.leading)
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(padding)

    case .counter(let value, let caption):
      VStack(alignment: .leading, spacing: 0) {
        Spacer(minLength: 0)
        Text("\(value)")
          .metroText(.pageTitle, size: unit * 0.68)
          .foregroundColor(tint)
          .lineLimit(1)
        Text(caption)
          .metroText(.small, size: unit * 0.145)
          .foregroundColor(tint.opacity(0.85))
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
      .padding(padding)

    case .initials(let letters):
      Text(letters.uppercased())
        .metroText(.pageTitle, size: unit * 0.72)
        .foregroundColor(tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    case .photo:
      // Fills whatever the tile's own aspect ratio is (small/medium/wide all differ),
      // unlike MetroAlbumArt which is always square for the music player.
      LinearGradient(
        colors: [(model.accent ?? .cobalt).color, (model.accent ?? .cobalt).color.opacity(0.4), .black.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private func restingFace(_ glyph: MetroGlyph) -> some View {
    ZStack {
      // WP sat the glyph slightly above centre so the caption did not crowd it, and
      // pushed it to the left edge on a wide tile rather than growing it.
      MetroIcon(glyph, size: glyphSize, color: tint)
        .offset(y: model.size.showsTitle ? -unit * 0.09 : 0)
        .frame(
          maxWidth: .infinity, maxHeight: .infinity,
          alignment: model.size.glyphIsLeading ? .leading : .center
        )
        .padding(.leading, model.size.glyphIsLeading ? padding * 1.4 : 0)

      if model.size.showsTitle {
        Text(model.title)
          .metroText(.tileTitle)
          .foregroundColor(tint)
          .lineLimit(1)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
          .padding(.leading, padding)
          .padding(.bottom, padding * 0.7)
      }

      if let badge = model.badge, badge > 0 {
        Text(badge > 99 ? "99+" : "\(badge)")
          .metroText(.tileBadge, size: theme.type.size(.tileBadge) * (model.size == .small ? 0.55 : 1))
          .foregroundColor(tint)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
          .padding(.trailing, padding)
          .padding(.top, padding * 0.3)
      }
    }
  }

  /// The glyph does not track the footprint one-for-one — a wide tile shows the same
  /// icon as a medium one, just further left. Large is the exception: at 4×4 a
  /// medium-sized glyph reads as a mistake, so it scales with the tile.
  private var glyphSize: CGFloat {
    switch model.size {
    case .small: return unit * 0.50
    case .medium, .wide: return unit * 0.62
    case .large: return unit * 1.15
    }
  }
}
