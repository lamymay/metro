import SwiftUI
import PlayerEngine

public struct PlaybackQueueView: View {
  @ObservedObject var vm: MusicManager
  @EnvironmentObject private var theme: ThemeManager
  @Environment(\.dismiss) private var dismiss

  public init(vm: MusicManager) {
    self.vm = vm
  }

  public var body: some View {
    NavigationStack {
      List {
        ForEach(vm.allSongs) { song in
          Button(action: {
            vm.play(song: song)
          }) {
            HStack(spacing: 12) {
              VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                  .foregroundColor(.primary)
                  .font(.subheadline.weight(.semibold))
                  .lineLimit(1)
                Text(song.artist)
                  .foregroundColor(.secondary)
                  .font(.caption)
                  .lineLimit(1)
              }
              Spacer()
              if isCurrent(song) {
                Image(systemName: "speaker.wave.2.fill")
                  .foregroundColor(theme.primary)
              }
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
      .listStyle(.plain)
      .navigationTitle("播放队列")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("完成") { dismiss() }
        }
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        MiniPlayer(vm: vm, onOpen: { dismiss() })
      }
    }
  }

  private func isCurrent(_ song: SongItem) -> Bool {
    guard let current = vm.currentSong else { return false }
    if let a = song.persistentID, let b = current.persistentID { return a == b }
    if let a = song.url, let b = current.url { return a == b }
    return song.title == current.title && song.artist == current.artist
      && song.album == current.album
  }
}
