import SwiftUI

// MARK: - 播放控制条组件
public struct PlayerBar: View {
  @ObservedObject var vm: MusicManager
  @EnvironmentObject private var theme: ThemeManager

  public init(vm: MusicManager) {
    self.vm = vm
  }

  public var body: some View {
    VStack {
      Text(vm.currentSong?.title ?? "未在播放")
        .font(.caption).bold().foregroundColor(.primary)
      HStack(spacing: 30) {
        Button(action: {}) { Image(systemName: "backward.fill") }
        Button(action: { vm.togglePlay() }) {
          Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
            .font(.title)
        }
        Button(action: {}) { Image(systemName: "forward.fill") }
      }
      Menu {
        ForEach(
          [
            0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.7, 1.8, 1.9, 2.0, 2.1, 2.2,
            2.3, 2.4, 2.5, 3.0, 3.5, 4.0,
          ], id: \.self
        ) { rate in
          Button("\(String(format: "%.1fx", rate))") {
            vm.playbackSpeed = Float(rate)
          }
        }
      } label: {
        Text(String(format: "%.1fx", vm.playbackSpeed))
          .font(.caption).bold().foregroundColor(theme.primary)
      }
    }
    .padding()
    .background(.ultraThinMaterial)
  }
}

// MARK: - 毛玻璃背景 (跨平台支持)
#if os(iOS)
  public struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    public init(style: UIBlurEffect.Style) {
      self.style = style
    }
    public func makeUIView(context: Context) -> UIVisualEffectView {
      UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    public func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
  }
#elseif os(macOS)
  public struct BlurView: NSViewRepresentable {
    public enum Style {
      case systemUltraThinMaterial
      case titlebar
    }
    var style: Style
    public init(style: Style) {
      self.style = style
    }
    public func makeNSView(context: Context) -> NSVisualEffectView {
      let view = NSVisualEffectView()
      switch style {
      case .systemUltraThinMaterial:
        view.material = .underWindowBackground
      case .titlebar:
        view.material = .headerView
      }
      view.blendingMode = .withinWindow
      view.state = .active
      return view
    }
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
  }
#endif
