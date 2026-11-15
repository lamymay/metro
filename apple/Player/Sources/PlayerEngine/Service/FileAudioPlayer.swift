import AVFoundation
import Foundation

final class FileAudioPlayer {
  private let queue = DispatchQueue(label: "FileAudioPlayer.queue")
  private var player: AVPlayer?
  private var timeControlStatusObservation: NSKeyValueObservation?
  private var didPlayToEndObserver: NSObjectProtocol?
  private var timeObserverToken: Any?
  private var playbackRate: Float = 1.0
  private var repeatOne: Bool = false

  var onIsPlayingChanged: (@Sendable (Bool) -> Void)?
  var onTimeChanged: (@Sendable (_ current: Double, _ duration: Double) -> Void)?
  var onDidFinish: (@Sendable () -> Void)?

  var volume: Float {
    get { player?.volume ?? 1.0 }
    set { player?.volume = newValue }
  }

  func prepare(url: URL, rate: Float, shouldPlay: Bool = true) {
    print("🎵 FileAudioPlayer: 准备\(shouldPlay ? "并播放" : "") URL: \(url.absoluteString)")
    // 在主线程初始化 AVPlayer，确保观察者和 UI 状态同步
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.playbackRate = rate

      let item = AVPlayerItem(url: url)
      if #available(iOS 9.0, macOS 10.11, *) {
        item.audioTimePitchAlgorithm = .timeDomain
      }

      // 监听错误
      NotificationCenter.default.addObserver(
        forName: .AVPlayerItemFailedToPlayToEndTime,
        object: item,
        queue: .main
      ) { notification in
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
          print("❌ FileAudioPlayer 播放失败: \(error.localizedDescription)")
        }
      }

      // 停止之前的播放
      self.player?.pause()

      let player = AVPlayer(playerItem: item)
      self.attachObservers(to: player)
      self.player = player

      if shouldPlay {
        player.play()
        if abs(rate - 1.0) >= 0.0001 {
          player.rate = rate
        }
      }

      print(
        "🎵 FileAudioPlayer: 已在主线程调用 \(shouldPlay ? "play()" : "prepare()"), 当前状态: \(player.timeControlStatus.rawValue)"
      )
    }
  }

  func play(url: URL, rate: Float) {
    prepare(url: url, rate: rate, shouldPlay: true)
  }

  func togglePlayPause() {
    queue.async { [weak self] in
      guard let self, let player = self.player else { return }
      if player.timeControlStatus == .playing {
        player.pause()
      } else {
        player.play()
        // 恢复播放后显式设置一次倍速
        player.rate = self.playbackRate
      }
    }
  }

  func stop() {
    queue.async { [weak self] in
      guard let self else { return }
      self.player?.pause()
      self.detachObservers()
      self.player = nil
      self.emitIsPlaying(false)
      self.emitTime(current: 0, duration: 0)
    }
  }

  func setRate(_ rate: Float) {
    queue.async { [weak self] in
      guard let self else { return }
      self.playbackRate = rate

      guard let player = self.player else { return }
      guard player.timeControlStatus == .playing else { return }
      player.rate = rate
    }
  }

  func seek(to seconds: Double) {
    queue.async { [weak self] in
      guard let self, let player = self.player else { return }
      let cm = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
      // 对音频来说，强行 0 容差可能导致明显卡顿（需要更精确的寻址）。
      // 用小容差换取更快的响应，更贴近“点哪播哪”的手感。
      let tol = CMTime(seconds: 0.15, preferredTimescale: 600)
      player.seek(to: cm, toleranceBefore: tol, toleranceAfter: tol) { [weak self] _ in
        guard let self else { return }
        self.emitTimeSnapshot()
      }
    }
  }

  func setRepeatOne(_ enabled: Bool) {
    queue.async { [weak self] in
      self?.repeatOne = enabled
    }
  }

  func shutdown() {
    stop()
  }

  private func attachObservers(to player: AVPlayer) {
    detachObservers()

    timeControlStatusObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) {
      [weak self] p, _ in
      guard let self else { return }
      self.emitIsPlaying(p.timeControlStatus == .playing)
    }

    // 进度更新：频率稍高一点，让拖动/点选进度更跟手。
    timeObserverToken = player.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.2, preferredTimescale: 600),
      queue: .main
    ) { [weak self] _ in
      self?.emitTimeSnapshot()
    }

    didPlayToEndObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: player.currentItem,
      queue: nil
    ) { [weak self] _ in
      guard let self else { return }
      if self.repeatOne {
        self.queue.async { [weak self] in
          guard let self, let p = self.player else { return }
          p.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self else { return }
            p.play()
            if abs(self.playbackRate - 1.0) >= 0.0001 {
              p.rate = self.playbackRate
            }
            self.emitIsPlaying(true)
          }
        }
      } else {
        self.emitIsPlaying(false)
        self.onDidFinish?()
      }
    }
  }

  private func detachObservers() {
    timeControlStatusObservation?.invalidate()
    timeControlStatusObservation = nil

    if let token = timeObserverToken, let player = player {
      player.removeTimeObserver(token)
    }
    timeObserverToken = nil

    if let token = didPlayToEndObserver {
      NotificationCenter.default.removeObserver(token)
      didPlayToEndObserver = nil
    }
  }

  private func emitIsPlaying(_ isPlaying: Bool) {
    onIsPlayingChanged?(isPlaying)
  }

  private func emitTimeSnapshot() {
    guard let player else { return }
    let current = player.currentTime().seconds
    let duration = player.currentItem?.duration.seconds ?? 0
    emitTime(current: current.isFinite ? current : 0, duration: duration.isFinite ? duration : 0)
  }

  private func emitTime(current: Double, duration: Double) {
    onTimeChanged?(max(0, current), max(0, duration))
  }
}
