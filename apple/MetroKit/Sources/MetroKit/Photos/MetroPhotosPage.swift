import SwiftUI

/// WP's Photos hub: a dense square grid of everything, and a pivot over to Albums.
/// There is no photo library here, so every thumbnail is generated art — the same
/// technique the music player uses for album covers, just with a different seed per
/// tile so the grid doesn't repeat.
public struct MetroPhotosPage: View {
  @Environment(\.metroTheme) private var theme
  @State private var opened: Int?

  public init() {}

  public var body: some View {
    ZStack {
      MetroPivot(
        title: "photos",
        items: [
          MetroPivotItem(header: "all") { grid },
          MetroPivotItem(header: "albums") { albumsTab },
        ]
      )

      if let opened {
        detail(index: opened)
          .transition(.opacity.combined(with: .scale(scale: 0.94)))
      }
    }
  }

  private var grid: some View {
    let accents = MetroSampleData.photoAccents
    let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 4)

    return ScrollView {
      LazyVGrid(columns: columns, spacing: 3) {
        ForEach(Array(accents.enumerated()), id: \.offset) { index, accent in
          MetroAlbumArt(accent: accent, size: 90)
            .metroTilt { withAnimation(.easeOut(duration: 0.2)) { opened = index } }
        }
      }
    }
  }

  private var albumsTab: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(Array(MetroSampleData.albums.enumerated()), id: \.offset) { index, album in
        HStack(spacing: 14) {
          MetroAlbumArt(accent: album.accent, size: 52)
          VStack(alignment: .leading, spacing: 1) {
            Text(album.name).metroText(.title3)
            Text("\(album.count) photos").metroText(.small)
          }
          Spacer(minLength: 0)
        }
        .padding(.horizontal, theme.metrics.pageMargin)
        .padding(.vertical, 8)
        .metroFeather(order: index)
      }
      Spacer(minLength: 0)
    }
  }

  private func detail(index: Int) -> some View {
    ZStack {
      Color.black.ignoresSafeArea()
      GeometryReader { proxy in
        MetroAlbumArt(
          accent: MetroSampleData.photoAccents[index % MetroSampleData.photoAccents.count],
          size: min(proxy.size.width, proxy.size.height)
        )
        .frame(width: proxy.size.width, height: proxy.size.height)
      }
    }
    .contentShape(Rectangle())
    .onTapGesture { withAnimation(.easeIn(duration: 0.18)) { opened = nil } }
  }
}
