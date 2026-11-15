import SwiftUI
import PlayerEngine

public struct FullPlayerView: View {
  @ObservedObject var vm: MusicManager
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject private var theme: ThemeManager

  @State private var isScrubbing = false
  @State private var scrubTime: Double = 0
  @State private var showSpeedPanel = false
  @State private var showEqualizerPanel = false
  @State private var showMoreActions = false
  @State private var showPlaybackQueue = false
  @State private var dragOffsetY: CGFloat = 0

  public init(vm: MusicManager) {
    self.vm = vm
  }

  public var body: some View {
    ZStack {
      background.ignoresSafeArea()

      VStack(spacing: 0) {
        dragHandle

        VStack(spacing: 24) {
          albumCard

          // 歌名歌手：居中
          VStack(spacing: 6) {
            Text(vm.currentSong?.title ?? "未在播放")
              .font(.title2.weight(.bold))
            Text(vm.currentSong?.artist ?? "")
              .font(.headline).foregroundColor(.secondary)
          }
          .multilineTextAlignment(.center)

          // 功能按钮行 (无背景圆弧)
          mxFunctionalityRow
            .padding(.top, 10)

          Spacer()

          progressSection

          // 五键控制栏
          mainControlRow
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 28)
      }
    }
    .offset(y: dragOffsetY)
    .sheet(isPresented: $showSpeedPanel) {
      CustomSpeedPickerView(
        speed: Binding(
          get: { Double(vm.playbackSpeed) },
          set: { vm.playbackSpeed = Float($0) }
        )
      )
      #if os(iOS)
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
      #endif
    }
    .sheet(isPresented: $showEqualizerPanel) {
      EqualizerSheetView()
        #if os(iOS)
          .presentationDetents([.height(280)])
          .presentationDragIndicator(.visible)
        #endif
    }
    .confirmationDialog("更多", isPresented: $showMoreActions, titleVisibility: .visible) {
      if vm.abRepeatMode != .off {
        Button("关闭 A-B 循环", role: .destructive) { vm.clearABRepeat() }
      }
      Button("取消", role: .cancel) {}
    }
    .sheet(isPresented: $showPlaybackQueue) {
      PlaybackQueueView(vm: vm)
        #if os(iOS)
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
        #endif
    }
  }

  private var dragHandle: some View {
    // 顶部 iOS 标准横杠（支持下拉缩回到迷你播放器）
    Capsule()
      .fill(Color.secondary.opacity(0.5))
      .frame(width: 36, height: 5)
      .padding(.top, 12)
      .padding(.bottom, 20)
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 4)
          .onChanged { value in
            dragOffsetY = max(0, value.translation.height)
          }
          .onEnded { value in
            let shouldDismiss =
              value.translation.height > 120
              || value.predictedEndTranslation.height > 180
            if shouldDismiss {
              dismiss()
            } else {
              withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                dragOffsetY = 0
              }
            }
          }
      )
      .onTapGesture { dismiss() }
  }

  private var mxFunctionalityRow: some View {
    HStack {
      funcButton("slider.vertical.3") {
        showEqualizerPanel = true
        HapticHelper.trigger(.light)
      }
      Spacer()
      Button(action: {
        vm.cycleABRepeat()
        HapticHelper.trigger(.light)
      }) {
        ABRepeatIcon(mode: vm.abRepeatMode)
          .foregroundColor(vm.abRepeatMode == .off ? .secondary : theme.primary)
          .frame(width: 44, height: 44)
      }
      .buttonStyle(.plain)
      Spacer()
      // 耳机（倍速/音效入口）
      Button(action: {
        showSpeedPanel = true
        HapticHelper.trigger(.light)
      }) {
        VStack(spacing: 2) {
          Image(systemName: "speedometer")
            .font(.system(size: 18, weight: .semibold))
          Text(String(format: "%.1fx", vm.playbackSpeed))
            .font(.system(size: 10, weight: .bold, design: .monospaced))
        }
        .foregroundColor(vm.playbackSpeed != 1.0 ? theme.primary : .secondary)
        .frame(width: 44, height: 44)
      }
      .buttonStyle(.plain)
      Spacer()
      funcButton(
        vm.isFavorite(vm.currentSong) ? "heart.fill" : "heart",
        active: vm.isFavorite(vm.currentSong)
      ) {
        vm.toggleFavorite()
      }
      Spacer()
      Button(action: {
        showPlaybackQueue = true
        HapticHelper.trigger(.light)
      }) {
        PlaybackQueueIcon()
          .foregroundColor(.secondary)
          .frame(width: 44, height: 44)
      }
      .buttonStyle(.plain)
      Spacer()
      funcButton("ellipsis") {
        showMoreActions = true
        HapticHelper.trigger(.light)
      }
    }
  }

  private var mainControlRow: some View {
    HStack(alignment: .center) {
      smallControlButton("shuffle", active: vm.shuffleEnabled) { vm.shuffleEnabled.toggle() }
      smallControlButton("backward.end.fill", size: 26, color: theme.primary) { vm.playPrevious() }
      Button(action: {
        vm.togglePlay()
        HapticHelper.trigger(.medium)
      }) {
        ZStack {
          Circle()
            .stroke(theme.primary.opacity(0.55), lineWidth: 3)
            .frame(width: 86, height: 86)

          Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 34, weight: .bold))
            .foregroundColor(theme.primary)
            .offset(x: vm.isPlaying ? 0 : 2)
        }
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity)
      smallControlButton("forward.end.fill", size: 26, color: theme.primary) { vm.playNext() }
      smallControlButton(vm.repeatOneEnabled ? "repeat.1" : "repeat", active: vm.repeatOneEnabled) {
        vm.repeatOneEnabled.toggle()
      }
    }
  }

  private func funcButton(_ icon: String, active: Bool = false, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      Image(systemName: icon).font(.system(size: 20, weight: .semibold))
        .foregroundColor(active ? theme.primary : .secondary).frame(width: 44, height: 44)
    }
    .buttonStyle(.plain)
  }

  private func smallControlButton(
    _ icon: String, size: CGFloat = 22, color: Color? = nil, active: Bool = false,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: icon).font(.system(size: size, weight: .semibold))
        .foregroundColor(color ?? (active ? theme.primary : .primary))
        .frame(width: 44, height: 44)
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.plain)
  }

  private var progressSection: some View {
    VStack(spacing: 8) {
      ProgressScrubber(
        value: Binding(
          get: { isScrubbing ? scrubTime : vm.currentTime },
          set: { scrubTime = $0 }
        ),
        duration: vm.duration,
        tint: theme.primary,
        isScrubbing: $isScrubbing,
        onSeek: { t in vm.seek(to: t) }
      )
      HStack {
        Text(formatTime(isScrubbing ? scrubTime : vm.currentTime))
        Spacer()
        Text(vm.duration > 0 ? formatTime(vm.duration) : "--:--")
      }.font(.caption.monospacedDigit()).foregroundColor(.secondary)
    }
  }

  private var albumCard: some View {
    GeometryReader { geo in
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(albumGradient)
        .overlay(
          Image(systemName: "music.note").font(.system(size: 60)).foregroundColor(
            .white.opacity(0.8)))
    }
    .aspectRatio(1, contentMode: .fit)
  }

  private var background: some View {
    LinearGradient(
      colors: [theme.primary.opacity(0.15), Color.systemBackground], startPoint: .top,
      endPoint: .bottom)
  }

  private var albumGradient: LinearGradient {
    LinearGradient(
      colors: [theme.primary, theme.primary.opacity(0.7)], startPoint: .topLeading,
      endPoint: .bottomTrailing)
  }

  private func formatTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let m = Int(seconds) / 60
    let s = Int(seconds) % 60
    return String(format: "%d:%02d", m, s)
  }
}

private struct ABRepeatIcon: View {
  let mode: ABRepeatMode

  var body: some View {
    VStack(spacing: 1) {
      HStack(spacing: 2) {
        Text("A")
        Image(systemName: "arrow.right")
      }
      HStack(spacing: 2) {
        Image(systemName: "arrow.left")
        Text("B")
      }
    }
    .font(.system(size: 11, weight: .bold, design: .monospaced))
    .opacity(mode == .settingB ? 1.0 : 0.92)
  }
}

private struct EqualizerSheetView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 14) {
      Capsule()
        .fill(Color.secondary.opacity(0.5))
        .frame(width: 36, height: 5)
        .padding(.top, 12)

      Text("均衡器")
        .font(.headline.weight(.semibold))

      Text("这里先放一个入口。后续如果需要真正的 EQ，需要用 AVAudioEngine 对音频做处理（系统音乐库播放器不提供系统级 EQ 接口）。")
        .font(.footnote)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 18)

      Button("知道了") { dismiss() }
        .buttonStyle(.borderedProminent)

      Spacer(minLength: 0)
    }
    .padding(.bottom, 18)
  }
}

private struct PlaybackQueueIcon: View {
  var body: some View {
    ZStack {
      PlaybackQueueLines()
        .stroke(style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
      PlaybackQueueTriangle()
        .fill(style: FillStyle(eoFill: true))
    }
    .aspectRatio(1, contentMode: .fit)
  }
}

private struct PlaybackQueueTriangle: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let w = rect.width
    let h = rect.height
    let triW = w * 0.28
    let triH = h * 0.22
    let triX = w * 0.18
    let triY = h * 0.50
    p.move(to: CGPoint(x: triX - triW * 0.35, y: triY - triH))
    p.addLine(to: CGPoint(x: triX - triW * 0.35, y: triY + triH))
    p.addLine(to: CGPoint(x: triX + triW * 0.55, y: triY))
    p.closeSubpath()
    return p
  }
}

private struct PlaybackQueueLines: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let w = rect.width
    let h = rect.height

    // 三条队列线
    let lineX0 = w * 0.40
    let lineX1 = w * 0.86
    let lineX1Mid = w * 0.78
    let y1 = h * 0.36
    let y2 = h * 0.50
    let y3 = h * 0.64
    p.move(to: CGPoint(x: lineX0, y: y1))
    p.addLine(to: CGPoint(x: lineX1, y: y1))
    p.move(to: CGPoint(x: lineX0, y: y2))
    p.addLine(to: CGPoint(x: lineX1Mid, y: y2))
    p.move(to: CGPoint(x: lineX0, y: y3))
    p.addLine(to: CGPoint(x: lineX1, y: y3))

    return p
  }
}

private struct ProgressScrubber: View {
  @Binding var value: Double
  let duration: Double
  let tint: Color
  @Binding var isScrubbing: Bool
  let onSeek: (Double) -> Void

  @State private var lastSeekAt: Date = .distantPast

  var body: some View {
    GeometryReader { geo in
      let w = max(1, geo.size.width)
      let d = max(0.001, duration)
      let clamped = min(max(0, value), d)
      let progress = CGFloat(clamped / d)
      let x = progress * w

      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.secondary.opacity(0.18))
          .frame(height: 4)

        Capsule()
          .fill(tint)
          .frame(width: max(0, x), height: 4)

        Circle()
          .fill(Color.white)
          .frame(width: 26, height: 26)
          .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
          .offset(x: max(0, min(w - 26, x - 13)))
      }
      .frame(height: 32)
      .contentShape(Rectangle())
      .onTapGesture { location in
        let newValue = positionToValue(location.x, width: w, duration: d)
        value = newValue
        onSeek(newValue)
        HapticHelper.trigger(.light)
      }
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { g in
            if !isScrubbing {
              isScrubbing = true
            }
            let newValue = positionToValue(g.location.x, width: w, duration: d)
            value = newValue

            // 让拖动更跟手：节流式预览 seek
            let now = Date()
            if now.timeIntervalSince(lastSeekAt) > 0.12 {
              lastSeekAt = now
              onSeek(newValue)
            }
          }
          .onEnded { g in
            let newValue = positionToValue(g.location.x, width: w, duration: d)
            value = newValue
            onSeek(newValue)
            isScrubbing = false
          }
      )
    }
    .frame(height: 32)
  }

  private func positionToValue(_ x: CGFloat, width: CGFloat, duration: Double) -> Double {
    let p = min(max(0, x / max(1, width)), 1)
    return Double(p) * duration
  }
}
