import AVFoundation
import Foundation

/// 远程音频资源的构建策略。
///
/// Player 包本身不认识任何具体服务端，宿主 App（如 NAS 客户端）通过实现本协议
/// 注入鉴权头、缓冲时长等策略；本地文件不走这里。
public protocol RemoteAudioAssetProviding: Sendable {
  /// Whether a remote player should intentionally wait to build a larger
  /// buffer before beginning playback.
  var automaticallyWaitsToMinimizeStalling: Bool { get }

  /// 为远程 URL 构建播放条目。`forwardBufferDuration <= 0` 表示不限定预缓冲。
  func makePlayerItem(url: URL, forwardBufferDuration: Double) -> AVPlayerItem

  /// 每首歌加载前解析真正可播放的地址（可返回本地缓存文件）。默认原样返回。
  func resolvePlayableURL(for track: RemoteAudioTrack) async -> URL

  /// 某首歌开始加载后的回调，供宿主记录播放历史 / 预取后续曲目。默认不做事。
  func trackDidBeginLoading(_ track: RemoteAudioTrack, upcoming: [RemoteAudioTrack]) async
}

extension RemoteAudioAssetProviding {
  public var automaticallyWaitsToMinimizeStalling: Bool { true }

  public func resolvePlayableURL(for track: RemoteAudioTrack) async -> URL { track.url }

  public func trackDidBeginLoading(_ track: RemoteAudioTrack, upcoming: [RemoteAudioTrack]) async {}
}

/// 无鉴权的默认实现：直连 URL。
public struct DefaultRemoteAudioAssetProvider: RemoteAudioAssetProviding {
  public init() {}

  public func makePlayerItem(url: URL, forwardBufferDuration: Double) -> AVPlayerItem {
    let item = AVPlayerItem(url: url)
    if forwardBufferDuration > 0 {
      item.preferredForwardBufferDuration = forwardBufferDuration
      item.canUseNetworkResourcesForLiveStreamingWhilePaused = forwardBufferDuration >= 4
    }
    return item
  }
}

/// 播放队列中的一首远程曲目。
public struct RemoteAudioTrack: Equatable, Sendable, Identifiable {
  public let code: String
  public let title: String
  public let subtitle: String
  public let url: URL

  public var id: String { code }

  public init(code: String, title: String, subtitle: String, url: URL) {
    self.code = code
    self.title = title
    self.subtitle = subtitle
    self.url = url
  }
}
