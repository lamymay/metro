import SwiftUI
import PlayerEngine

public struct SongRow: View {
  let song: SongItem
  let isCurrent: Bool
  let action: () -> Void
  @EnvironmentObject private var theme: ThemeManager

  public init(song: SongItem, isCurrent: Bool, action: @escaping () -> Void) {
    self.song = song
    self.isCurrent = isCurrent
    self.action = action
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(song.title)
          .foregroundColor(isCurrent ? theme.primary : .primary)
        Text(song.artist)
          .foregroundColor(.secondary).font(.caption)
      }
      Spacer()
      // 播放图标仅仅是装饰，点击事件由 List 的 row 处理或放在 Button 里
      Image(systemName: "play.circle").foregroundColor(theme.primary)
    }
    .contentShape(Rectangle())  // 让整行可点击
    .onTapGesture { action() }  // 单击整行立即播放，参考 Sony Music 等主流播放器的交互
  }
}
