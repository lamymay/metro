import AVFoundation
import Foundation

/// 远程音频播放会话：队列、连播、控制中心、倍速、AB 循环。
///
/// 与服务端无关 —— 鉴权、地址解析、缓存与预取全部通过 `RemoteAudioAssetProviding`
/// 注入。这样同一套队列编排可以给任意后端复用，而不是每个 App 各写一份。
@MainActor
public final class RemoteAudioSession: ObservableObject {
  @Published public private(set) var isPlaying = false
  @Published public private(set) var isBuffering = true
  @Published public private(set) var currentTime: Double = 0
  @Published public private(set) var duration: Double = 0
  @Published public private(set) var playbackSpeed: Float = 1.0
  @Published public private(set) var volume: Float = 1.0
  @Published public private(set) var repeatOneEnabled = false
  @Published public private(set) var activeTrackCode: String?
  @Published public private(set) var lastError: String?

  public private(set) var abRepeatMode: ABRepeatMode = .off
  public private(set) var abRepeatPointA: Double?
  public private(set) var abRepeatPointB: Double?

  /// 控制中心切歌时通知 UI 同步选中项。
  public var onActiveTrackChanged: ((String) -> Void)?

  private let engine: RemoteAudioEngine
  private let nowPlaying: NowPlayingCenter
  private let abRepeat = ABRepeatController()
  private var provider: RemoteAudioAssetProviding

  private var queue: [RemoteAudioTrack] = []
  private var queueIndex = 0
  private var userPaused = false
  private var audioSessionActive = false
  /// 加载竞态守卫：切歌很快时，先发的异步解析结果不能覆盖后发的。
  private var loadGeneration = 0
  private let forwardBufferDuration: Double

  public init(
    provider: RemoteAudioAssetProviding = DefaultRemoteAudioAssetProvider(),
    fallbackArtist: String = "",
    forwardBufferDuration: Double = 8
  ) {
    self.provider = provider
    self.forwardBufferDuration = forwardBufferDuration
    engine = RemoteAudioEngine(assetProvider: provider)
    nowPlaying = NowPlayingCenter(fallbackArtist: fallbackArtist)
    wireEngine()
    wireNowPlayingCommands()
  }

  /// 更换鉴权/缓存策略（例如切换了服务器）。
  public func updateProvider(_ provider: RemoteAudioAssetProviding) {
    self.provider = provider
    engine.updateAssetProvider(provider)
  }

  // MARK: - 队列

  public func playQueue(
    _ tracks: [RemoteAudioTrack],
    startingAt index: Int,
    autoplay: Bool = true
  ) {
    guard !tracks.isEmpty else { return }
    let newIndex = min(max(0, index), tracks.count - 1)
    let newTrack = tracks[newIndex]
    // 同一首歌重复点按不打断播放
    if queue == tracks, queueIndex == newIndex, activeTrackCode == newTrack.code { return }
    queue = tracks
    queueIndex = newIndex
    if autoplay { userPaused = false }
    loadCurrentTrack(shouldPlay: autoplay)
  }

  /// 外部（如列表选中）切到某首，队列不变。
  public func syncToTrack(code: String, in tracks: [RemoteAudioTrack]) {
    guard let idx = tracks.firstIndex(where: { $0.code == code }) else { return }
    if queue == tracks, queueIndex == idx, activeTrackCode == code { return }
    queue = tracks
    queueIndex = idx
    userPaused = false
    loadCurrentTrack(shouldPlay: true)
  }

  // MARK: - 传输控制

  public func togglePlayPause() {
    userPaused = isPlaying
    engine.togglePlayPause()
  }

  public func seek(to seconds: Double) { engine.seek(to: seconds) }

  public func skipBackward(_ seconds: Double = 15) {
    seek(to: max(0, currentTime - seconds))
  }

  public func skipForward(_ seconds: Double = 15) {
    seek(to: min(duration, currentTime + seconds))
  }

  public func setPlaybackSpeed(_ speed: Float) {
    playbackSpeed = speed
    engine.setRate(speed)
    publishNowPlaying()
  }

  public func setVolume(_ volume: Float) {
    let clamped = min(1, max(0, volume))
    self.volume = clamped
    engine.volume = clamped
  }

  public func setRepeatOne(_ enabled: Bool) {
    repeatOneEnabled = enabled
    engine.setRepeatOne(enabled)
  }

  public func cycleABRepeat() {
    abRepeat.cycle(currentTime: currentTime, duration: duration)
    syncABState()
  }

  public func clearABRepeat() {
    abRepeat.clear()
    syncABState()
  }

  /// 仅在用户明确停止时调用；关闭预览层不该 stop。
  public func stopByUser() {
    userPaused = true
    engine.stop()
    nowPlaying.clear()
    queue = []
    queueIndex = 0
    activeTrackCode = nil
    abRepeat.clear()
    syncABState()
  }

  // MARK: - 内部

  private func wireEngine() {
    engine.onIsPlayingChanged = { [weak self] playing in
      guard let self else { return }
      self.isPlaying = playing
      if playing { self.userPaused = false }
      self.publishNowPlaying()
    }
    engine.onBufferingChanged = { [weak self] buffering in
      self?.isBuffering = buffering
    }
    engine.onPlaybackFailed = { [weak self] message in
      guard let self else { return }
      self.isBuffering = false
      self.lastError = message
      self.publishNowPlaying()
    }
    engine.onTimeChanged = { [weak self] current, dur in
      guard let self else { return }
      self.currentTime = current
      self.duration = dur
      // AB 循环命中就跳回 A 点，不再往下发布进度
      if let target = self.abRepeat.seekTargetIfNeeded(currentTime: current, duration: dur) {
        self.seek(to: target)
        return
      }
      self.publishNowPlaying()
    }
    engine.onDidFinish = { [weak self] in
      self?.handleTrackFinished()
    }
  }

  private func wireNowPlayingCommands() {
    nowPlaying.onPlay = { [weak self] in
      self?.userPaused = false
      self?.engine.togglePlayPause()
    }
    nowPlaying.onPause = { [weak self] in
      guard let self else { return }
      self.userPaused = true
      if self.isPlaying { self.engine.togglePlayPause() }
    }
    nowPlaying.onTogglePlayPause = { [weak self] in self?.togglePlayPause() }
    nowPlaying.onNext = { [weak self] in self?.playNextTrack(userInitiated: true) }
    nowPlaying.onPrevious = { [weak self] in self?.playPreviousTrack(userInitiated: true) }
    nowPlaying.onSeek = { [weak self] seconds in self?.seek(to: seconds) }
  }

  private func loadCurrentTrack(shouldPlay: Bool) {
    guard queue.indices.contains(queueIndex) else { return }
    let track = queue[queueIndex]
    activeTrackCode = track.code
    lastError = nil
    onActiveTrackChanged?(track.code)

    activateAudioSessionIfNeeded()
    nowPlaying.activateCommandsIfNeeded()
    nowPlaying.setSkipAvailability(
      hasPrevious: queueIndex > 0,
      hasNext: queueIndex + 1 < queue.count
    )

    isBuffering = true
    engine.setRepeatOne(repeatOneEnabled)
    loadGeneration += 1
    let generation = loadGeneration
    let play = shouldPlay && !userPaused
    let upcoming = Array(queue.dropFirst(queueIndex + 1))

    Task { @MainActor in
      let url = await provider.resolvePlayableURL(for: track)
      // 期间又切歌了就丢弃这次结果
      guard generation == loadGeneration, activeTrackCode == track.code else { return }
      engine.prepare(
        url: url,
        rate: playbackSpeed,
        forwardBufferDuration: forwardBufferDuration,
        shouldPlay: play
      )
      publishNowPlaying(title: track.title, subtitle: track.subtitle)
      await provider.trackDidBeginLoading(track, upcoming: upcoming)
    }
  }

  private func handleTrackFinished() {
    if repeatOneEnabled { return }
    if userPaused { return }
    if playNextTrack(userInitiated: false) { return }
    publishNowPlaying()
  }

  @discardableResult
  private func playNextTrack(userInitiated: Bool) -> Bool {
    guard queueIndex + 1 < queue.count else { return false }
    queueIndex += 1
    if userInitiated { userPaused = false }
    loadCurrentTrack(shouldPlay: !userPaused)
    return true
  }

  private func playPreviousTrack(userInitiated: Bool) {
    // 播放超过 3 秒时，「上一首」先回到本曲开头（与系统播放器一致）
    if currentTime > 3, userInitiated {
      seek(to: 0)
      return
    }
    guard queueIndex > 0 else {
      if userInitiated { seek(to: 0) }
      return
    }
    queueIndex -= 1
    if userInitiated { userPaused = false }
    loadCurrentTrack(shouldPlay: !userPaused)
  }

  private func activateAudioSessionIfNeeded() {
    #if os(iOS)
      guard !audioSessionActive else { return }
      let session = AVAudioSession.sharedInstance()
      try? session.setCategory(.playback, mode: .default, options: [])
      try? session.setActive(true)
      audioSessionActive = true
    #endif
  }

  private func publishNowPlaying(title: String? = nil, subtitle: String? = nil) {
    guard queue.indices.contains(queueIndex) else { return }
    let track = queue[queueIndex]
    nowPlaying.update(
      title: title ?? track.title,
      subtitle: subtitle ?? track.subtitle,
      duration: duration,
      elapsed: currentTime,
      isPlaying: isPlaying,
      playbackRate: playbackSpeed
    )
  }

  private func syncABState() {
    abRepeatMode = abRepeat.mode
    abRepeatPointA = abRepeat.pointA
    abRepeatPointB = abRepeat.pointB
  }
}
