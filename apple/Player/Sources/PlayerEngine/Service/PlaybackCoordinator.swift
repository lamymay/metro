import AVFoundation
import Foundation

public final class PlaybackCoordinator {
  enum Source {
    case none
    case systemLibrary
    case file
  }

  private let queue = DispatchQueue(label: "PlaybackCoordinator.queue")
  private var source: Source = .none
  private var playbackRate: Float = 1.0
  private var audioSessionConfigured = false

  private let filePlayer = FileAudioPlayer()

  #if os(iOS)
    private lazy var systemPlayer = SystemMusicPlayer()
  #endif

  public var onIsPlayingChanged: (@Sendable (Bool) -> Void)?
  public var onSystemNowPlayingChanged:
    (@Sendable (_ persistentID: UInt64, _ title: String?, _ artist: String?) -> Void)?
  public var onTimeChanged: (@Sendable (_ current: Double, _ duration: Double) -> Void)?
  public var onDidFinish: (@Sendable () -> Void)?

  public init() {
    filePlayer.onIsPlayingChanged = { [weak self] isPlaying in
      guard let self else { return }
      self.onIsPlayingChanged?(isPlaying)
    }
    filePlayer.onTimeChanged = { [weak self] current, duration in
      guard let self else { return }
      self.onTimeChanged?(current, duration)
    }
    filePlayer.onDidFinish = { [weak self] in
      guard let self else { return }
      self.onDidFinish?()
    }

    #if os(iOS)
      systemPlayer.onIsPlayingChanged = { [weak self] isPlaying in
        guard let self else { return }
        self.onIsPlayingChanged?(isPlaying)
      }
      systemPlayer.onNowPlayingChanged = { [weak self] pid, title, artist in
        guard let self else { return }
        self.onSystemNowPlayingChanged?(pid, title, artist)
      }
      systemPlayer.onTimeChanged = { [weak self] current, duration in
        guard let self else { return }
        self.onTimeChanged?(current, duration)
      }
    #endif
  }

  public func isIdle() -> Bool {
    queue.sync { source == .none }
  }

  public func setRate(_ rate: Float) {
    queue.async { [weak self] in
      guard let self else { return }
      self.playbackRate = rate
      self.filePlayer.setRate(rate)
      #if os(iOS)
        if self.source == .systemLibrary {
          self.ensureAudioSessionActiveLocked()
          self.systemPlayer.setRate(rate)
        }
      #endif
    }
  }

  public func prepare(song: SongItem, shouldPlay: Bool = true) {
    queue.async { [weak self] in
      guard let self else { return }
      self.ensureAudioSessionActiveLocked()

      #if os(iOS)
        if let pid = song.persistentID {
          self.source = .systemLibrary
          self.filePlayer.stop()
          if shouldPlay {
            self.systemPlayer.play(persistentID: pid, rate: self.playbackRate)
          } else {
            // System player doesn't have a good "prepare" for PID without playing
            // but we can at least set the source
          }
          return
        }
      #endif

      guard let url = song.url else { return }
      self.source = .file
      #if os(iOS)
        self.systemPlayer.stop()
      #endif
      self.filePlayer.prepare(url: url, rate: self.playbackRate, shouldPlay: shouldPlay)
    }
  }

  public func play(song: SongItem) {
    prepare(song: song, shouldPlay: true)
  }

  public func togglePlayPause() {
    queue.async { [weak self] in
      guard let self else { return }
      self.ensureAudioSessionActiveLocked()
      switch self.source {
      case .none:
        return
      case .file:
        self.filePlayer.togglePlayPause()
      case .systemLibrary:
        #if os(iOS)
          self.systemPlayer.togglePlayPause()
        #endif
      }
    }
  }

  public func seek(to seconds: Double) {
    queue.async { [weak self] in
      guard let self else { return }
      self.ensureAudioSessionActiveLocked()
      switch self.source {
      case .none:
        return
      case .file:
        self.filePlayer.seek(to: seconds)
      case .systemLibrary:
        #if os(iOS)
          self.systemPlayer.seek(to: seconds)
        #endif
      }
    }
  }

  public func setShuffle(_ enabled: Bool) {
    queue.async { [weak self] in
      guard let self else { return }
      #if os(iOS)
        if self.source == .systemLibrary {
          self.ensureAudioSessionActiveLocked()
          self.systemPlayer.setShuffle(enabled)
        }
      #endif
    }
  }

  public func setRepeatOne(_ enabled: Bool) {
    queue.async { [weak self] in
      guard let self else { return }
      self.filePlayer.setRepeatOne(enabled)
      #if os(iOS)
        if self.source == .systemLibrary {
          self.ensureAudioSessionActiveLocked()
          self.systemPlayer.setRepeatOne(enabled)
        }
      #endif
    }
  }

  public func stop() {
    queue.async { [weak self] in
      guard let self else { return }
      self.source = .none
      self.filePlayer.stop()
      #if os(iOS)
        self.systemPlayer.stop()
      #endif
    }
  }

  public func shutdown() {
    stop()
    filePlayer.shutdown()
    #if os(iOS)
      systemPlayer.shutdown()
    #endif
  }

  public var volume: Float {
    get { filePlayer.volume }
    set { filePlayer.volume = newValue }
  }

  public func setVolume(_ volume: Float) {
    self.volume = volume
  }

  private func ensureAudioSessionActiveLocked() {
    #if os(iOS)
      let session = AVAudioSession.sharedInstance()
      do {
        if !audioSessionConfigured {
          // 配置为播放类别，并允许与其他通知音混合（Ducking）
          // .duckOthers: 当其他应用（如导航）说话时，我们的声音变小
          try session.setCategory(.playback, mode: .default, options: [])
          audioSessionConfigured = true
        }
        try session.setActive(true, options: .notifyOthersOnDeactivation)
      } catch {
        print("音频会话配置失败: \(error.localizedDescription)")
      }
    #endif
  }
}
