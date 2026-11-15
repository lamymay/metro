import SwiftUI
import PlayerEngine

public struct PlaylistPicker: View {
  @ObservedObject var vm: MusicManager
  let song: SongItem?
  let songs: Set<String>?
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject private var theme: ThemeManager

  @State private var newPlaylistName = ""
  @FocusState private var isTextFieldFocused: Bool

  public init(vm: MusicManager, song: SongItem?, songs: Set<String>?) {
    self.vm = vm
    self.song = song
    self.songs = songs
  }

  public var body: some View {
    VStack(spacing: 0) {
      // 顶部标题栏保持简洁以减少渲染开销
      ZStack {
        Text("添加到播放列表").font(.system(size: 17, weight: .bold))
        HStack {
          Spacer()
          Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.gray.opacity(0.4))
              .font(.title2)
          }
        }
      }
      .padding()

      List {
        HStack(spacing: 16) {
          // 按钮部分保持不变
          Button(action: handleCreate) {
            ZStack {
              RoundedRectangle(cornerRadius: 12)
                .fill(theme.primary.opacity(0.12))
                .frame(width: 52, height: 52)
              Image(systemName: "plus").foregroundColor(theme.primary).font(.title3)
            }
          }.buttonStyle(.plain)

          // 这个输入框因为键盘已经“预热”，点击或激活时会快得多
          TextField("创建新播放列表", text: $newPlaylistName)
            .font(.body)
            .focused($isTextFieldFocused)
            .onSubmit(handleCreate)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)

        ForEach(vm.playlists) { playlist in
          Button(action: {
            autoreleasepool {
              if vm.isMultiSelectMode, songs != nil {
                let selectedSongsToAdd = vm.allSongs.filter { vm.selectedSongs.contains($0.id) }
                vm.addToPlaylist(playlistId: playlist.id, songsToAdd: selectedSongsToAdd)
              } else if let s = song {
                vm.addToPlaylist(playlistId: playlist.id, song: s)
              }
            }
            dismiss()
          }) {
            HStack(spacing: 16) {
              RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)).frame(
                width: 52, height: 52
              )
              .overlay(Image(systemName: "music.note").foregroundColor(.gray))
              VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name).font(.system(size: 16, weight: .medium))
                Text("\(playlist.songs.count) 首歌曲").font(.caption).foregroundColor(.secondary)
              }
            }
          }
          .listRowBackground(Color.clear)
        }
      }
      .listStyle(.plain)
    }
    .background(Color.systemBackground)
    .onAppear {
      // 重点：由于键盘已预热，我们只需要一个极短的微秒级延迟避开 Sheet 切换
      // 0.1秒的延迟用户几乎感知不到，但足以让 iPhone 16 Pro 顺滑切换
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        isTextFieldFocused = true
      }
    }
  }

  private func handleCreate() {
    guard !newPlaylistName.isEmpty else { return }
    vm.createPlaylist(name: newPlaylistName)
    newPlaylistName = ""
    isTextFieldFocused = false
  }
}
