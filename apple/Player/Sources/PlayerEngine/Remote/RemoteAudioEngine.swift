import AVFoundation
import Foundation

/// 远程 / 本地文件音频播放引擎。
///
/// 与包内 `FileAudioPlayer` 的区别：本引擎面向网络流，额外提供缓冲态与失败回调，
/// 并通过 `RemoteAudioAssetProviding` 支持鉴权头。AVPlayer 必须在主线程操作，
/// 因此整体 `@MainActor` 隔离。
@MainActor
public final class RemoteAudioEngine {
  private var player: AVPlayer?
  private var timeControlStatusObservation: NSKeyValueObservation?
  private var itemStatusObservation: NSKeyValueObservation?
  private var likelyToKeepUpObservation: NSKeyValueObservation?
  private var bufferEmptyObservation: NSKeyValueObservation?
  private var didPlayToEndObserver: NSObjectProtocol?
  private var timeObserverToken: Any?
  private var playbackRate: Float = 1.0
  private var playbackVolume: Float = 1.0
  private var repeatOne = false

  private var assetProvider: RemoteAudioAssetProviding

  public var onIsPlayingChanged: (@MainActor (Bool) -> Void)?
  public var onBufferingChanged: (@MainActor (Bool) -> Void)?
  public var onTimeChanged: (@MainActor (_ current: Double, _ duration: Double) -> Void)?
  public var onDidFinish: (@MainActor () -> Void)?
  public var onPlaybackFailed: (@MainActor (String) -> Void)?

  public init(assetProvider: RemoteAudioAssetProviding = DefaultRemoteAudioAssetProvider()) {
    self.assetProvider = assetProvider
  }

  /// 切换鉴权/缓存策略（例如换了服务器）。只影响之后新建的播放条目。
  public func updateAssetProvider(_ provider: RemoteAudioAssetProviding) {
    assetProvider = provider
  }

  public var volume: Float {
    get { player?.volume ?? playbackVolume }
    set {
      playbackVolume = min(1, max(0, newValue))
      player?.volume = playbackVolume
    }
  }

  public func prepare(url: URL, rate: Float, forwardBufferDuration: Double, shouldPlay: Bool = true) {
    playbackRate = rate
    stopInternal(emitEvents: false)

    let isLocalFile = url.isFileURL
    let buffer = isLocalFile ? 0 : forwardBufferDuration
    let item: AVPlayerItem
    if isLocalFile {
      item = AVPlayerItem(url: url)
    } else {
      item = assetProvider.makePlayerItem(url: url, forwardBufferDuration: buffer)
    }
    item.audioTimePitchAlgorithm = .timeDomain
    if buffer > 0 {
      item.preferredForwardBufferDuration = buffer
    }

    let player = AVPlayer(playerItem: item)
    player.volume = playbackVolume
    player.automaticallyWaitsToMinimizeStalling = isLocalFile
      ? false
      : assetProvider.automaticallyWaitsToMinimizeStalling
    attachObservers(to: player, item: item)
    self.player = player

    if shouldPlay {
      startPlayback(on: player)
    } else {
      emitIsPlaying(false)
    }
  }

  public func togglePlayPause() {
    guard let player else { return }
    if Self.isActivePlayback(player.timeControlStatus) {
      player.pause()
    } else {
      startPlayback(on: player)
    }
  }

  public func stop() {
    stopInternal(emitEvents: true)
  }

  public func setRate(_ rate: Float) {
    playbackRate = rate
    guard let player, Self.isActivePlayback(player.timeControlStatus) else { return }
    player.rate = rate
  }

  public func seek(to seconds: Double) {
    guard let player else { return }
    let cm = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
    let tol = CMTime(seconds: 0.15, preferredTimescale: 600)
    player.seek(to: cm, toleranceBefore: tol, toleranceAfter: tol) { [weak self] _ in
      Task { @MainActor in self?.emitTimeSnapshot() }
    }
  }

  public func setRepeatOne(_ enabled: Bool) {
    repeatOne = enabled
  }

  private func stopInternal(emitEvents: Bool) {
    player?.pause()
    detachObservers()
    player = nil
    if emitEvents {
      emitIsPlaying(false)
      emitTime(current: 0, duration: 0)
    }
  }

  private func startPlayback(on player: AVPlayer) {
    player.play()
    if abs(playbackRate - 1.0) >= 0.0001 {
      player.rate = playbackRate
    }
  }

  private static func isActivePlayback(_ status: AVPlayer.TimeControlStatus) -> Bool {
    status == .playing || status == .waitingToPlayAtSpecifiedRate
  }

  private func attachObservers(to player: AVPlayer, item: AVPlayerItem) {
    detachObservers()

    timeControlStatusObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) {
      [weak self] p, _ in
      Task { @MainActor in
        self?.emitIsPlaying(Self.isActivePlayback(p.timeControlStatus))
        if let item = p.currentItem {
          self?.emitBuffering(player: p, item: item)
        }
      }
    }

    itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
      Task { @MainActor in
        guard let self else { return }
        switch item.status {
        case .failed:
          let msg = item.error?.localizedDescription ?? "无法播放该音频"
          self.onPlaybackFailed?(msg)
          self.emitIsPlaying(false)
          self.onBufferingChanged?(false)
        case .readyToPlay:
          self.emitTimeSnapshot()
          if let player = self.player {
            self.emitBuffering(player: player, item: item)
          }
        default:
          self.onBufferingChanged?(true)
        }
      }
    }

    likelyToKeepUpObservation = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) {
      [weak self] item, _ in
      Task { @MainActor in
        guard let self, let player = self.player else { return }
        self.emitBuffering(player: player, item: item)
      }
    }

    bufferEmptyObservation = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
      Task { @MainActor in
        guard let self, let player = self.player else { return }
        self.emitBuffering(player: player, item: item)
      }
    }

    timeObserverToken = player.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.2, preferredTimescale: 600),
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in self?.emitTimeSnapshot() }
    }

    didPlayToEndObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }
        if self.repeatOne, let p = self.player {
          p.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            Task { @MainActor in
              self.startPlayback(on: p)
              self.emitIsPlaying(true)
            }
          }
        } else {
          self.emitIsPlaying(false)
          self.onDidFinish?()
        }
      }
    }
  }

  private func detachObservers() {
    timeControlStatusObservation?.invalidate()
    timeControlStatusObservation = nil
    itemStatusObservation?.invalidate()
    itemStatusObservation = nil
    likelyToKeepUpObservation?.invalidate()
    likelyToKeepUpObservation = nil
    bufferEmptyObservation?.invalidate()
    bufferEmptyObservation = nil
    if let token = timeObserverToken, let player {
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
    emitTime(
      current: current.isFinite ? current : 0,
      duration: duration.isFinite ? duration : 0
    )
  }

  private func emitTime(current: Double, duration: Double) {
    onTimeChanged?(max(0, current), max(0, duration))
  }

  private func emitBuffering(player: AVPlayer, item: AVPlayerItem) {
    let buffering: Bool
    switch item.status {
    case .unknown:
      buffering = true
    case .failed:
      buffering = false
    case .readyToPlay:
      buffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
        && !item.isPlaybackLikelyToKeepUp
    @unknown default:
      buffering = false
    }
    onBufferingChanged?(buffering)
  }
}
