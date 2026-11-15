import Foundation

public struct SongItem: Identifiable, Equatable {
  public var id: String {
    if let pid = persistentID, pid != 0 {
      return "pid:\(pid)"
    }
    if let url = url {
      return "url:\(url.absoluteString)"
    }
    return "meta:\(title)-\(artist)-\(album ?? "")"
  }
  public let title: String
  public let artist: String
  public let album: String?
  public let genre: String?
  public let url: URL?
  public let duration: Double
  // iOS 系统音乐库条目的标识。很多系统曲目（尤其 Apple Music/DRM/云端）没有可用的 assetURL，
  // 必须用 persistentID + MPMusicPlayerController 才能可靠播放。
  public let persistentID: UInt64?
  public var bookmarkData: Data? = nil

  // 仅在内存中使用的属性，用于 UI 区分
  public var isPlayedInQueue: Bool = false

  public static func == (lhs: SongItem, rhs: SongItem) -> Bool {
    if let lp = lhs.persistentID, let rp = rhs.persistentID, lp != 0, rp != 0 {
      return lp == rp
    }
    if let lu = lhs.url, let ru = rhs.url {
      return lu == ru
    }
    return lhs.title == rhs.title && lhs.artist == rhs.artist && lhs.album == rhs.album
  }

  public init(
    title: String, artist: String, album: String?, genre: String?, url: URL?, duration: Double = 0,
    persistentID: UInt64?, bookmarkData: Data? = nil, isPlayedInQueue: Bool = false
  ) {
    self.title = title
    self.artist = artist
    self.album = album
    self.genre = genre
    self.url = url
    self.duration = duration
    self.persistentID = persistentID
    self.bookmarkData = bookmarkData
    self.isPlayedInQueue = isPlayedInQueue
  }

  // 建议增加一个计算属性，方便判断是否是外部导入的文件
  public var isExternalFile: Bool {
    return bookmarkData != nil
  }
}

public struct Playlist: Identifiable {
  public let id: UUID
  public var name: String
  public var songs: [SongItem]

  public init(id: UUID = UUID(), name: String, songs: [SongItem]) {
    self.id = id
    self.name = name
    self.songs = songs
  }
}
