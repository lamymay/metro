import Foundation
import PlayerEngine
import GRDB

public class PlayerSQLiteStore {
  internal var dbQueue: DatabaseQueue

  public static let shared: PlayerSQLiteStore? = {
    do {
      return try PlayerSQLiteStore()
    } catch {
      print("❌ 数据库初始化失败: \(error)")
      return nil
    }
  }()

  public init() throws {
    let fileManager = FileManager.default
    let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .first!
    if !fileManager.fileExists(atPath: appSupportURL.path) {
      try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
    }
    let dbURL = appSupportURL.appendingPathComponent("player.sqlite")

    // 强制重置：如果需要彻底清空旧数据，取消下面一行的注释
    // try? fileManager.removeItem(at: dbURL)

    self.dbQueue = try DatabaseQueue(path: dbURL.path)
    try setupDatabase()
  }

  private func setupDatabase() throws {
    try dbQueue.write { db in
      // 1. AudioEntity (核心曲库表)
      try db.create(table: "audioEntity", ifNotExists: true) { t in
        t.column("id", .text).primaryKey()
        t.column("url", .text).notNull()
        t.column("title", .text).notNull()
        t.column("artist", .text).notNull()
        t.column("album", .text)
        t.column("genre", .text)
        t.column("duration", .double).notNull().defaults(to: 0)
        t.column("play_count", .integer).notNull().defaults(to: 0)
        t.column("last_played_at", .double)
        t.column("added_at", .double).notNull()
      }

      // 2. ImportedFolder (信任目录表)
      try db.create(table: "importedFolderEntity", ifNotExists: true) { t in
        t.column("path", .text).primaryKey()
        t.column("added_at", .double).notNull()
        t.column("bookmark_data", .blob)
      }

      // 3. Playlist (歌单主表)
      try db.create(table: "playlistEntity", ifNotExists: true) { t in
        t.column("id", .text).primaryKey()
        t.column("name", .text).notNull()
        t.column("created_at", .double).notNull()
        t.column("updated_at", .double).notNull()
        t.column("song_ids", .text).notNull().defaults(to: "[]")
      }

      // 4. PlaybackQueue (播放队列表)
      try db.create(table: "playbackQueueEntity", ifNotExists: true) { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("audio_id", .text).references("audioEntity", onDelete: .cascade)
        t.column("sort_order", .integer).notNull()
        t.column("is_played", .integer).notNull().defaults(to: 0)
        t.column("source_type", .text).notNull()
        t.column("source_id", .text)
      }

      // 5. PlaybackStatus (播放状态表)
      try db.create(table: "playbackStatus", ifNotExists: true) { t in
        t.column("id", .integer).primaryKey().defaults(to: 1)
        t.column("current_audio_id", .text).references("audioEntity", onDelete: .setNull)
        t.column("position", .double).notNull().defaults(to: 0)
        t.column("playback_speed", .double).notNull().defaults(to: 1.0)
        t.column("shuffle_mode", .integer).notNull().defaults(to: 0)
        t.column("repeat_mode", .integer).notNull().defaults(to: 0)
        t.column("volume", .double).notNull().defaults(to: 1.0)
        t.column("is_playing", .boolean).notNull().defaults(to: false)
        t.column("last_updated", .double).notNull()
        t.column("ab_point_a", .double)
        t.column("ab_point_b", .double)
        t.column("ab_mode", .integer)
      }
    }
    print("✅ 数据库表结构校验/创建完成")
  }
}

// MARK: - Audio Library DAO
extension PlayerSQLiteStore {
  public func saveAudioEntities(_ entities: [AudioEntity]) {
    do {
      try dbQueue.write { db in
        for entity in entities {
          try entity.insert(db, onConflict: .replace)
        }
      }
      print("✅ 成功存入 \(entities.count) 条歌曲数据到数据库")
    } catch {
      print("❌ 存入歌曲数据失败: \(error)")
    }
  }

  public func fetchAllAudio() -> [AudioEntity] {
    do {
      return try dbQueue.read { db in
        try AudioEntity.fetchAll(db)
      }
    } catch {
      print("❌ 读取曲库失败: \(error)")
      return []
    }
  }

  public func deleteSongsByURLs(_ urls: [String]) {
    try? dbQueue.write { db in
      try db.execute(
        sql:
          "DELETE FROM audioEntity WHERE url IN (\(urls.map { _ in "?" }.joined(separator: ",")))",
        arguments: StatementArguments(urls))
    }
  }

  public func incrementPlayCount(audioId: String) {
    try? dbQueue.write { db in
      if var audio = try AudioEntity.fetchOne(db, key: audioId) {
        audio.playCount += 1
        audio.lastPlayedAt = Date().timeIntervalSince1970
        try audio.update(db)
      }
    }
  }
}

// MARK: - Imported Folder DAO
extension PlayerSQLiteStore {
  public func saveImportedFolder(path: String, bookmarkData: Data?) {
    try? dbQueue.write { db in
      let folder = ImportedFolderEntity(
        path: path, added_at: Date().timeIntervalSince1970, bookmarkData: bookmarkData)
      try folder.insert(db, onConflict: .replace)
    }
  }

  public func loadImportedFolders() -> [ImportedFolderEntity] {
    return
      (try? dbQueue.read { db in
        try ImportedFolderEntity.fetchAll(db)
      }) ?? []
  }

  public func removeImportedFolder(path: String) {
    try? dbQueue.write { db in
      try db.execute(sql: "DELETE FROM importedFolderEntity WHERE path = ?", arguments: [path])
    }
  }
}

// MARK: - Playlist DAO
extension PlayerSQLiteStore {
  public func savePlaylist(_ playlist: Playlist) {
    try? dbQueue.write { db in
      let now = Date().timeIntervalSince1970
      let ids = playlist.songs.map { $0.id }
      let songIdsJSON =
        (try? JSONEncoder().encode(ids)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

      let entity = PlaylistEntity(
        id: playlist.id.uuidString,
        name: playlist.name,
        createdAt: now,
        updatedAt: now,
        songIds: songIdsJSON
      )
      try entity.insert(db, onConflict: .replace)
    }
  }

  public func loadPlaylists() -> [Playlist] {
    return
      (try? dbQueue.read { db in
        let entities = try PlaylistEntity.fetchAll(db)
        var playlists: [Playlist] = []

        for entity in entities {
          let ids =
            (try? JSONDecoder().decode(
              [String].self, from: entity.songIds.data(using: .utf8) ?? Data())) ?? []

          var songs: [SongItem] = []
          for id in ids {
            if let audio = try AudioEntity.fetchOne(db, key: id) {
              songs.append(audio.toSongItem())
            }
          }

          if let uuid = UUID(uuidString: entity.id) {
            playlists.append(Playlist(id: uuid, name: entity.name, songs: songs))
          }
        }
        return playlists
      }) ?? []
  }

  public func deletePlaylist(id: String) {
    try? dbQueue.write { db in
      try db.execute(sql: "DELETE FROM playlistEntity WHERE id = ?", arguments: [id])
    }
  }

  public func ensureFavoritesPlaylist() -> String {
    let id = "favorites"
    try? dbQueue.write { db in
      let now = Date().timeIntervalSince1970
      let playlist = PlaylistEntity(
        id: id, name: "我的收藏", createdAt: now, updatedAt: now, songIds: "[]")
      try playlist.insert(db, onConflict: .ignore)
    }
    return id
  }
}

// MARK: - Playback Queue DAO
extension PlayerSQLiteStore {
  /// 更新队列逻辑
  /// - Parameters:
  ///   - newSongs: 要插入的候选歌曲列表（通常是用户选中的歌单或全部歌曲）
  ///   - activeSongId: 当前点击要播放的歌曲 ID
  ///   - sourceType: 来源类型
  ///   - sourceId: 来源 ID
  ///   - shuffle: 是否开启随机模式
  public func updateQueue(
    newSongs: [AudioEntity], activeSongId: String, sourceType: String, sourceId: String?,
    shuffle: Bool
  ) {
    print("📥 PlayerSQLiteStore: 开始更新队列, 歌曲数: \(newSongs.count), 当前 ID: \(activeSongId)")
    do {
      try dbQueue.write { db in
        // 1. 彻底清空当前队列，重新建立上下文
        try db.execute(sql: "DELETE FROM playbackQueueEntity")

        var songsToInsert = newSongs
        if shuffle {
          // 如果是随机模式，确保 activeSongId 在第一位，其余随机
          if let activeIdx = songsToInsert.firstIndex(where: { $0.id == activeSongId }) {
            let activeSong = songsToInsert.remove(at: activeIdx)
            songsToInsert.shuffle()
            songsToInsert.insert(activeSong, at: 0)
          } else {
            songsToInsert.shuffle()
          }
        }

        // 2. 插入新队列
        var foundActive = false
        for (index, song) in songsToInsert.enumerated() {
          let currentIsActive = (song.id == activeSongId)
          let item = PlaybackQueueEntity(
            id: nil,
            audioId: song.id,
            sortOrder: index,
            isPlayed: foundActive ? 0 : 1,  // 还没遇到 active 或者是 active 本身，都算“已处理”
            sourceType: sourceType,
            sourceId: sourceId
          )
          try item.insert(db)

          if currentIsActive {
            foundActive = true
          }
        }
      }
      print("✅ PlayerSQLiteStore: 播放队列更新成功, 已插入 \(newSongs.count) 条记录")
    } catch {
      print("❌ PlayerSQLiteStore: 更新播放队列失败: \(error)")
    }
  }

  /// 当用户在播放过程中切换随机模式时，仅重新排序“尚未播放”的队列
  public func resortRemainingQueue(shuffle: Bool) {
    try? dbQueue.write { db in
      let status = try PlaybackStatusEntity.fetchOne(db, key: 1)
      guard let currentId = status?.currentAudioId else { return }

      // 获取当前歌曲的 sort_order
      guard
        let currentItem = try PlaybackQueueEntity.filter(Column("audio_id") == currentId).fetchOne(
          db)
      else { return }
      let currentOrder = currentItem.sortOrder

      // 获取所有排在当前歌曲之后的未播放项
      var remainingItems =
        try PlaybackQueueEntity
        .filter(Column("sort_order") > currentOrder)
        .filter(Column("is_played") == 0)
        .fetchAll(db)

      guard !remainingItems.isEmpty else { return }

      // 重新排序
      if shuffle {
        remainingItems.shuffle()
      } else {
        // 如果切换回顺序，理论上应该按原始来源排序。
        // 暂且按 ID 排序作为保底，或者不做动作。
        remainingItems.sort { $0.audioId < $1.audioId }
      }

      // 写回新的排序
      for (index, var item) in remainingItems.enumerated() {
        item.sortOrder = currentOrder + 1 + index
        try item.update(db)
      }
    }
  }

  public func fetchQueue() -> [SongItem] {
    do {
      return try dbQueue.read { db in
        // 使用 LEFT JOIN 调试，看是否是因为 audioEntity 缺失导致 JOIN 失败
        let sql = """
          SELECT q.audio_id as q_audio_id, q.is_played as queue_is_played, a.*
          FROM playbackQueueEntity q
          LEFT JOIN audioEntity a ON a.id = q.audio_id
          ORDER BY q.sort_order ASC
          """
        let rows = try Row.fetchAll(db, sql: sql)
        print("🔍 PlayerSQLiteStore: fetchQueue 原始行数: \(rows.count)")

        let items = rows.compactMap { row -> SongItem? in
          let qId = row["q_audio_id"] as? String ?? "unknown"
          guard let entity = try? AudioEntity(row: row) else {
            print("⚠️ PlayerSQLiteStore: 发现队列项但缺少曲库实体, ID: \(qId)")
            return nil
          }
          let isPlayed = (row["queue_is_played"] as? Int ?? 0) == 1
          return entity.toSongItem(isPlayedInQueue: isPlayed)
        }
        print("📖 PlayerSQLiteStore: 最终成功解析队列歌曲数: \(items.count)")
        return items
      }
    } catch {
      print("❌ PlayerSQLiteStore: 读取播放队列失败: \(error)")
      return []
    }
  }

  public func markAsPlayed(audioId: String) {
    try? dbQueue.write { db in
      // 1. 更新队列中的播放状态
      try db.execute(
        sql: "UPDATE playbackQueueEntity SET is_played = 1 WHERE audio_id = ?", arguments: [audioId]
      )

      // 2. 同步增加曲库主表中的播放次数 (对应您的 playcount 要求)
      if var audio = try AudioEntity.fetchOne(db, key: audioId) {
        audio.playCount += 1
        audio.lastPlayedAt = Date().timeIntervalSince1970
        try audio.update(db)
        print("📈 已更新歌曲播放次数: \(audio.title), 当前次数: \(audio.playCount)")
      }
    }
  }
}

// MARK: - Playback Status DAO
extension PlayerSQLiteStore {
  public func saveStatus(_ status: PlaybackStatusEntity) {
    try? dbQueue.write { db in
      var s = status
      s.id = 1
      s.lastUpdated = Date().timeIntervalSince1970
      try s.insert(db, onConflict: .replace)
    }
  }

  public func loadStatus() -> PlaybackStatusEntity? {
    return try? dbQueue.read { db in
      try PlaybackStatusEntity.fetchOne(db, key: 1)
    }
  }
}
