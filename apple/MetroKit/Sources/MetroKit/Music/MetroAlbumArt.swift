import SwiftUI

/// A stand-in for album art: an accent gradient plus a couple of soft translucent
/// circles for texture, since the kit ships no images. Square, like WP's own art tiles.
public struct MetroAlbumArt: View {
  public var accent: MetroAccent
  public var size: CGFloat

  public init(accent: MetroAccent, size: CGFloat) {
    self.accent = accent
    self.size = size
  }

  public var body: some View {
    Canvas { context, canvasSize in
      let rect = CGRect(origin: .zero, size: canvasSize)
      context.fill(
        Path(rect),
        with: .linearGradient(
          Gradient(colors: [accent.color, accent.color.opacity(0.45), .black.opacity(0.65)]),
          startPoint: .zero,
          endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)
        )
      )
      context.fill(
        Path(ellipseIn: CGRect(x: canvasSize.width * 0.55, y: -canvasSize.height * 0.2, width: canvasSize.width * 0.7, height: canvasSize.width * 0.7)),
        with: .color(.white.opacity(0.10))
      )
      context.fill(
        Path(ellipseIn: CGRect(x: -canvasSize.width * 0.25, y: canvasSize.height * 0.55, width: canvasSize.width * 0.55, height: canvasSize.width * 0.55)),
        with: .color(.black.opacity(0.18))
      )
    }
    .frame(width: size, height: size)
    .clipped()
  }
}
