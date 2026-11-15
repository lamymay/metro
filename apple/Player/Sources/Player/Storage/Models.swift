import Foundation
import PlayerEngine
import GRDB

// MARK: - 1. 核心曲库表 (audioEntity)
public struct AudioEntity: Codable, FetchableRecord, PersistableRecord {
  public static var databaseTable: String { "audioEntity" }
  public var id: String
  public var url: String
  public var title: String
  public var artist: String
  public var album: String?
  public var genre: String?
  public var duration: Double
  public var playCount: Int
  public var lastPlayedAt: Double?
  public var addedAt: Double

  enum CodingKeys: String, CodingKey {
    case id, url, title, artist, album, genre, duration
    case playCount = "play_count"
    case lastPlayedAt = "last_played_at"
    case addedAt = "added_at"
  }

  public init(
    id: String, url: String, title: String, artist: String, album: String?, genre: String?,
    duration: Double, playCount: Int, lastPlayedAt: Double?, addedAt: Double
  ) {
    self.id = id
    self.url = url
    self.title = title
    self.artist = artist
    self.album = album
    self.genre = genre
    self.duration = duration
    self.playCount = playCount
    self.lastPlayedAt = lastPlayedAt
    self.addedAt = addedAt
  }
}

extension AudioEntity {
  public func toSongItem(isPlayedInQueue: Bool = false) -> SongItem {
    SongItem(
      title: title, artist: artist, album: album, genre: genre,
      url: URL(string: url), duration: duration,
      persistentID: id.hasPrefix("pid:")
        ? UInt64(id.replacingOccurrences(of: "pid:", with: "")) : nil,
      bookmarkData: nil,
      isPlayedInQueue: isPlayedInQueue
    )
  }

  public static func from(songItem: SongItem) -> AudioEntity {
    return AudioEntity(
      id: songItem.id,
      url: songItem.url?.absoluteString ?? "",
      title: songItem.title, artist: songItem.artist, album: songItem.album, genre: songItem.genre,
      duration: songItem.duration, playCount: 0, lastPlayedAt: nil,
      addedAt: Date().timeIntervalSince1970
    )
  }
}

// MARK: - 2. 信任目录表 (importedFolderEntity)
public struct ImportedFolderEntity: Codable, FetchableRecord, PersistableRecord, Hashable, Identifiable {
  public static var databaseTable: String { "importedFolderEntity" }
  public var id: String { path }  // 使用路径作为 ID
  public var path: String
  public var added_at: Double
  public var bookmarkData: Data?

  enum CodingKeys: String, CodingKey {
    case path, added_at
    case bookmarkData = "bookmark_data"
  }

  public init(path: String, added_at: Double, bookmarkData: Data?) {
    self.path = path
    self.added_at = added_at
    self.bookmarkData = bookmarkData
  }
}

// MARK: - 3. 歌单主表 (playlistEntity)
public struct PlaylistEntity: Codable, FetchableRecord, PersistableRecord {
  public static var databaseTable: String { "playlistEntity" }
  public var id: String
  public var name: String
  public var createdAt: Double
  public var updatedAt: Double
  // 冗余存储歌曲 ID 列表，用逗号分隔，避免使用关联表
  public var songIds: String

  enum CodingKeys: String, CodingKey {
    case id, name
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case songIds = "song_ids"
  }

  public init(id: String, name: String, createdAt: Double, updatedAt: Double, songIds: String) {
    self.id = id
    self.name = name
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.songIds = songIds
  }
}

// MARK: - 5. 播放队列表 (playbackQueueEntity)
public struct PlaybackQueueEntity: Codable, FetchableRecord, PersistableRecord {
  public static var databaseTable: String { "playbackQueueEntity" }
  public var id: Int64?
  public var audioId: String
  public var sortOrder: Int
  public var isPlayed: Int
  public var sourceType: String
  public var sourceId: String?

  enum CodingKeys: String, CodingKey {
    case id
    case audioId = "audio_id"
    case sortOrder = "sort_order"
    case isPlayed = "is_played"
    case sourceType = "source_type"
    case sourceId = "source_id"
  }

  public init(
    id: Int64?, audioId: String, sortOrder: Int, isPlayed: Int, sourceType: String,
    sourceId: String?
  ) {
    self.id = id
    self.audioId = audioId
    self.sortOrder = sortOrder
    self.isPlayed = isPlayed
    self.sourceType = sourceType
    self.sourceId = sourceId
  }
}

// MARK: - 6. 播放状态表 (playbackStatus)
public struct PlaybackStatusEntity: Codable, FetchableRecord, PersistableRecord {
  public static var databaseTable: String { "playbackStatus" }
  public var id: Int = 1
  public var currentAudioId: String?
  public var position: Double
  public var playbackSpeed: Float
  public var shuffleMode: Int
  public var repeatMode: Int
  public var volume: Double
  public var isPlaying: Bool
  public var lastUpdated: Double
  public var abPointA: Double?
  public var abPointB: Double?
  public var abMode: Int?

  enum CodingKeys: String, CodingKey {
    case id
    case currentAudioId = "current_audio_id"
    case position
    case playbackSpeed = "playback_speed"
    case shuffleMode = "shuffle_mode"
    case repeatMode = "repeat_mode"
    case volume
    case isPlaying = "is_playing"
    case lastUpdated = "last_updated"
    case abPointA = "ab_point_a"
    case abPointB = "ab_point_b"
    case abMode = "ab_mode"
  }

  public init(
    id: Int = 1, currentAudioId: String?, position: Double, playbackSpeed: Float,
    shuffleMode: Int, repeatMode: Int, volume: Double, isPlaying: Bool, lastUpdated: Double,
    abPointA: Double?, abPointB: Double?, abMode: Int?
  ) {
    self.id = id
    self.currentAudioId = currentAudioId
    self.position = position
    self.playbackSpeed = playbackSpeed
    self.shuffleMode = shuffleMode
    self.repeatMode = repeatMode
    self.volume = volume
    self.isPlaying = isPlaying
    self.lastUpdated = lastUpdated
    self.abPointA = abPointA
    self.abPointB = abPointB
    self.abMode = abMode
  }
}
