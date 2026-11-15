import Foundation
import MediaPlayer

/// 系统控制中心 / 锁屏「正在播放」与远程控制命令。
@MainActor
public final class NowPlayingCenter {
  public var onPlay: (() -> Void)?
  public var onPause: (() -> Void)?
  public var onTogglePlayPause: (() -> Void)?
  public var onNext: (() -> Void)?
  public var onPrevious: (() -> Void)?
  public var onSeek: ((Double) -> Void)?

  /// 「正在播放」里艺人一栏为空时的兜底文案。
  private let fallbackArtist: String
  private var commandsConfigured = false

  public init(fallbackArtist: String = "") {
    self.fallbackArtist = fallbackArtist
  }

  public func activateCommandsIfNeeded() {
    guard !commandsConfigured else { return }
    commandsConfigured = true

    let center = MPRemoteCommandCenter.shared()
    center.playCommand.isEnabled = true
    center.pauseCommand.isEnabled = true
    center.togglePlayPauseCommand.isEnabled = true
    center.nextTrackCommand.isEnabled = true
    center.previousTrackCommand.isEnabled = true
    center.changePlaybackPositionCommand.isEnabled = true

    center.playCommand.addTarget { [weak self] _ in
      self?.onPlay?()
      return .success
    }
    center.pauseCommand.addTarget { [weak self] _ in
      self?.onPause?()
      return .success
    }
    center.togglePlayPauseCommand.addTarget { [weak self] _ in
      self?.onTogglePlayPause?()
      return .success
    }
    center.nextTrackCommand.addTarget { [weak self] _ in
      self?.onNext?()
      return .success
    }
    center.previousTrackCommand.addTarget { [weak self] _ in
      self?.onPrevious?()
      return .success
    }
    center.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
      self?.onSeek?(event.positionTime)
      return .success
    }
  }

  public func update(
    title: String,
    subtitle: String,
    duration: Double,
    elapsed: Double,
    isPlaying: Bool,
    playbackRate: Float
  ) {
    var info: [String: Any] = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: subtitle.isEmpty ? fallbackArtist : subtitle,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: max(0, elapsed),
      MPMediaItemPropertyPlaybackDuration: max(0, duration),
      MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(playbackRate) : 0,
    ]
    if duration <= 0 {
      info.removeValue(forKey: MPMediaItemPropertyPlaybackDuration)
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
  }

  public func setSkipAvailability(hasPrevious: Bool, hasNext: Bool) {
    let center = MPRemoteCommandCenter.shared()
    center.previousTrackCommand.isEnabled = hasPrevious
    center.nextTrackCommand.isEnabled = hasNext
  }

  public func clear() {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    MPNowPlayingInfoCenter.default().playbackState = .stopped
  }
}
