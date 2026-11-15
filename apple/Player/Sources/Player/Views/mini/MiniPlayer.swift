import SwiftUI

// MARK: - 迷你播放器组件
public struct MiniPlayer: View {
  @ObservedObject var vm: MusicManager
  @EnvironmentObject private var theme: ThemeManager
  let onOpen: () -> Void

  public init(vm: MusicManager, onOpen: @escaping () -> Void) {
    self.vm = vm
    self.onOpen = onOpen
  }

  public var body: some View {
    VStack(spacing: 0) {
      Divider()

      HStack(spacing: 12) {
        // 非按键区域：点击这里打开全屏播放页
        Button(action: onOpen) {
          HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
              .fill(
                LinearGradient(
                  colors: [theme.primary, .indigo], startPoint: .topLeading,
                  endPoint: .bottomTrailing)
              )
              .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
              Text(vm.currentSong?.title ?? "未在播放")
                .foregroundColor(.primary)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
              Text(vm.currentSong?.artist ?? "点击选择一首歌")
                .foregroundColor(.secondary)
                .font(.caption)
                .lineLimit(1)
            }

            Spacer(minLength: 8)
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(vm.currentSong == nil)

        HStack(spacing: 14) {
          Button(action: { vm.playPrevious() }) {
            Image(systemName: "backward.fill")
              .font(.title3.weight(.semibold))
              .foregroundColor(.primary)
              .frame(width: 34, height: 34)
          }
          .buttonStyle(.plain)
          .disabled(vm.currentSong == nil)

          Button(action: { vm.togglePlay() }) {
            Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
              .font(.title2.weight(.semibold))
              .foregroundColor(.primary)
              .frame(width: 38, height: 38)
          }
          .buttonStyle(.plain)
          .disabled(vm.currentSong == nil)

          Button(action: { vm.playNext() }) {
            Image(systemName: "forward.fill")
              .font(.title3.weight(.semibold))
              .foregroundColor(.primary)
              .frame(width: 34, height: 34)
          }
          .buttonStyle(.plain)
          .disabled(vm.currentSong == nil)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background(.ultraThinMaterial)
    }
  }
}
