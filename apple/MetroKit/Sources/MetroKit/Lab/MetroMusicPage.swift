import SwiftUI

/// A working stand-in for Xbox Music's now-playing pivot: real transport controls over
/// synthesised audio, a collection list, and a "get music" promo grid — the three tabs
/// visible in the reference screenshots.
public struct MetroMusicPage: View {
  @Environment(\.metroTheme) private var theme
  @ObservedObject var player: MetroMusicPlayer

  /// Shared with the rest of the app so playback survives navigating away — WP kept
  /// music running in the background and showed a mini "now playing" band elsewhere;
  /// that only works if there is exactly one player instance, owned above this page.
  public init(player: MetroMusicPlayer) {
    self.player = player
  }

  public var body: some View {
    ZStack {
      backgroundArt
      MetroPivot(
        title: "music",
        items: [
          MetroPivotItem(header: "now playing") { nowPlayingTab },
          MetroPivotItem(header: "collection") { collectionTab },
          MetroPivotItem(header: "get music") { getMusicTab },
        ]
      )
    }
  }

  // MARK: Background

  /// Xbox Music's now-playing pivot sat over a blurred wash of the current album art
  /// rather than flat black — the one page in the whole lab that breaks that rule, on
  /// purpose, because the reference does too.
  private var backgroundArt: some View {
    ZStack {
      LinearGradient(
        colors: [player.currentSong.accent.color.opacity(0.5), Color.black],
        startPoint: .top,
        endPoint: .bottom
      )
      Color.black.opacity(0.4)
    }
    .ignoresSafeArea()
    .animation(.easeInOut(duration: 0.4), value: player.currentSong.id)
  }

  // MARK: Now playing

  private var nowPlayingTab: some View {
    VStack(spacing: 0) {
      Spacer(minLength: 12)

      MetroAlbumArt(accent: player.currentSong.accent, size: 220)
        .id(player.currentSong.id)
        .frame(maxWidth: .infinity)

      VStack(alignment: .leading, spacing: 2) {
        Text(player.currentSong.title)
          .metroText(.title2)
          .lineLimit(1)
        Text(player.currentSong.artist)
          .metroText(.normal)
          .foregroundColor(theme.subtle)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, theme.metrics.pageMargin)
      .padding(.top, 20)

      VStack(spacing: 4) {
        MetroSlider(
          value: Binding(
            get: { player.currentTime },
            set: { player.seek(to: $0) }
          ),
          in: 0...max(player.currentSong.duration, 0.1),
          format: { _ in "" }
        )
        HStack {
          Text(Self.format(player.currentTime)).metroText(.small)
          Spacer()
          Text(Self.format(player.currentSong.duration)).metroText(.small)
        }
      }
      .padding(.horizontal, theme.metrics.pageMargin)
      .padding(.top, 8)

      HStack(spacing: 56) {
        transportButton(.skipPrevious, size: 26) { player.previous() }
        transportButton(player.isPlaying ? .pause : .play, size: 34) { player.togglePlayPause() }
        transportButton(.skipNext, size: 26) { player.next() }
      }
      .padding(.top, 24)

      Spacer(minLength: 12)

      MetroAppBar(items: [
        MetroAppBarItem(glyph: .pin, label: "pin") {},
        MetroAppBarItem(glyph: .search, label: "find") {},
      ])
    }
  }

  private func transportButton(_ glyph: MetroGlyph, size: CGFloat, action: @escaping () -> Void) -> some View {
    MetroIcon(glyph, size: size, color: theme.foreground)
      .frame(width: 56, height: 56)
      .contentShape(Rectangle())
      .metroTilt { action() }
  }

  private static func format(_ time: TimeInterval) -> String {
    let t = max(0, Int(time.rounded()))
    return String(format: "%d:%02d", t / 60, t % 60)
  }

  // MARK: Collection

  private var collectionTab: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(Array(collectionCategories.enumerated()), id: \.offset) { index, category in
        MetroListRow(title: category) {}
          .metroFeather(order: index)
      }
      Spacer(minLength: 0)
    }
  }

  private let collectionCategories = ["artists", "albums", "songs", "genres", "playlists", "radio"]

  // MARK: Get music

  private var getMusicTab: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: theme.metrics.gap) {
          promoTile("Top music")
          promoTile("Browse by genre")
        }

        Text("\(player.playlist.count) downloads")
          .metroText(.small)
          .padding(.top, 6)

        VStack(alignment: .leading, spacing: 0) {
          ForEach(Array(player.playlist.enumerated()), id: \.offset) { index, song in
            MetroListRow(title: song.title, subtitle: song.artist) {}
              .metroFeather(order: index)
          }
        }
      }
      .padding(.horizontal, theme.metrics.pageMargin)
      .padding(.bottom, 32)
    }
  }

  private func promoTile(_ title: String) -> some View {
    ZStack(alignment: .bottomLeading) {
      MetroAccent.emerald.color
      Text(title)
        .metroText(.title3)
        .foregroundColor(.white)
        .padding(10)
    }
    .frame(height: 110)
    .frame(maxWidth: .infinity)
    .metroTilt {}
  }
}
