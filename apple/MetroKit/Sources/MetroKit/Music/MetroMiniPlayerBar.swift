import SwiftUI

/// The compact "something is playing" band WP showed above its chrome whenever you'd
/// left the Music app with a track still going. Tapping it jumps back to the full
/// now-playing screen; the play/pause glyph works right where it is.
public struct MetroMiniPlayerBar: View {
  @Environment(\.metroTheme) private var theme
  @ObservedObject var player: MetroMusicPlayer
  public var onTap: () -> Void

  public init(player: MetroMusicPlayer, onTap: @escaping () -> Void) {
    self.player = player
    self.onTap = onTap
  }

  public var body: some View {
    HStack(spacing: 12) {
      Rectangle()
        .fill(player.currentSong.accent.color)
        .frame(width: 4)

      VStack(alignment: .leading, spacing: 0) {
        // `.small` is one of the roles that defaults to the dim/subtle brush, which
        // reads fine for the artist line but leaves the title indistinguishable from
        // it — force the title back to full foreground.
        Text(player.currentSong.title)
          .metroText(.small)
          .foregroundColor(theme.foreground)
          .lineLimit(1)
        Text(player.currentSong.artist)
          .metroText(.small)
          .foregroundColor(theme.subtle)
          .lineLimit(1)
      }

      Spacer(minLength: 8)

      MetroIcon(player.isPlaying ? .pause : .play, size: 20, color: theme.foreground)
        .frame(width: 36, height: 36)
        .contentShape(Rectangle())
        .metroTilt { player.togglePlayPause() }
    }
    .padding(.horizontal, 12)
    .frame(height: 40)
    .background(theme.chrome)
    .contentShape(Rectangle())
    .onTapGesture { onTap() }
  }
}
