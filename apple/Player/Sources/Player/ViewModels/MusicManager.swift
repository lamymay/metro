import Combine
import PlayerEngine
import Foundation
import SwiftUI

#if os(iOS)
  import AVFoundation
  import MediaPlayer
  import UIKit
#endif

@MainActor
public class MusicManager: ObservableObject {
  // 播放交给系统音频服务（system library -> MPMusicPlayerController，本地文件 -> AVPlayer）
  public let playback = PlaybackCoordinator()
  private let abRepeat = ABRepeatController()
  private var abRepeatCancellable: AnyCancellable?
  private let store = PlayerSQLiteStore.shared
  private var appObservers: [NSObjectProtocol] = []

  // 节流写入控制
  private let persistQueue = DispatchQueue(label: "MusicManager.persist")
  private var lastPersistTime: Date = .distantPast
  private let persistInterval: TimeInterval = 5.0  // 每 5 秒自动落盘一次，保护进度
  private var isInitialLoading = true

  // MARK: - 发布属性
  @Published public var isPlaying = false
  @Published public var allSongs: [SongItem] = [] {
    didSet { updateGroupedCollections() }
  }
  @Published public var currentSong: SongItem?
  @Published public var currentTime: Double = 0
  @Published public var duration: Double = 0

  // 与多选状态
  @Published public var searchText: String = ""
  @Published public var isMultiSelectMode: Bool = false
  @Published public var selectedSongs: Set<String> = []

  // 缓存的分组与过滤结果，避免在 View 中重复计算
  @Published public var filteredSongs: [SongItem] = []
  @Published public var groupedArtists: [String: [SongItem]] = [:]
  @Published public var groupedAlbums: [String: [SongItem]] = [:]
  @Published public var groupedGenres: [String: [SongItem]] = [:]

  @Published public var filteredArtists: [String] = []
  @Published public var filteredAlbums: [String] = []
  @Published public var filteredGenres: [String] = []

  // 排序状态
  @Published public var sortKey: String = "title"
  @Published public var sortAscending: Bool = true

  // MARK: - UI 状态 (macOS)
  @Published public var showPlaybackQueue: Bool = false

  // 播放列表数据
  @Published public var playlists: [Playlist] = [
    Playlist(name: "我的收藏", songs: [])
  ]

  // 播放设置
  @Published public var playbackSpeed: Float = 1.0 {
    didSet {
      playback.setRate(playbackSpeed)
      persistPlaybackState(force: true)
    }
  }

  // MARK: - macOS 导入状态
  @Published public var importProgress: Double = 0
  @Published public var isImporting: Bool = false
  @Published public var importedFolders: [ImportedFolderEntity] = []

  @Published public var shuffleEnabled: Bool = false {
    didSet {
      playback.setShuffle(shuffleEnabled)
      // 核心修复：当切换随机按钮时，立即重排数据库中的后续队列
      if let store = PlayerSQLiteStore.shared {
        store.resortRemainingQueue(shuffle: shuffleEnabled)
        // 立即从数据库拉取最新排序的队列到内存
        let newQueue = store.fetchQueue()
        DispatchQueue.main.async {
          self.playbackQueue = newQueue
          print(
            "🔀 随机模式已\(self.shuffleEnabled ? "开启" : "关闭")，队列已重新排序，当前队列数: \(self.playbackQueue.count)"
          )
        }
      }
      persistPlaybackState(force: true)
    }
  }

  @Published public var repeatOneEnabled: Bool = false {
    didSet {
      playback.setRepeatOne(repeatOneEnabled)
      persistPlaybackState(force: true)
    }
  }

  // MARK: - A-B 循环（MX Player 风格）
  public var abRepeatMode: ABRepeatMode { abRepeat.mode }
  public var abRepeatPointA: Double? { abRepeat.pointA }
  public var abRepeatPointB: Double? { abRepeat.pointB }

  // MARK: - 最近播放（Sony 风格）
  @Published public var recentSongs: [SongItem] = []

  // MARK: - 播放队列
  @Published public var playbackQueue: [SongItem] = []

  private func updateGroupedCollections() {
    // 在后台线程进行分组计算
    let songs = allSongs
    DispatchQueue.global(qos: .userInitiated).async {
      let artists = Dictionary(grouping: songs) { $0.artist.isEmpty ? "" : $0.artist }
      let albums = Dictionary(grouping: songs) {
        ($0.album?.isEmpty == false) ? ($0.album ?? "") : ""
      }
      let genres = Dictionary(grouping: songs) {
        let g = ($0.genre ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return g.isEmpty ? "" : g
      }

      DispatchQueue.main.async {
        self.groupedArtists = artists
        self.groupedAlbums = albums
        self.groupedGenres = genres
        self.updateFilteredCollections()
      }
    }
  }

  private func updateFilteredCollections() {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    // 1. 过滤曲目
    var result: [SongItem]
    if query.isEmpty {
      result = allSongs
    } else {
      result = allSongs.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    // 1.5 应用排序
    result.sort { a, b in
      let comparison: Bool
      switch sortKey {
      case "title":
        comparison = a.title.localizedStandardCompare(b.title) == .orderedAscending
      case "duration":
        comparison = a.duration < b.duration
      case "artist":
        comparison = a.artist.localizedStandardCompare(b.artist) == .orderedAscending
      case "album":
        let aa = a.album ?? ""
        let ab = b.album ?? ""
        comparison = aa.localizedStandardCompare(ab) == .orderedAscending
      default:
        comparison = true
      }
      return sortAscending ? comparison : !comparison
    }
    filteredSongs = result

    // 2. 过滤艺术家
    let artists = groupedArtists.keys.sorted {
      $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
    }
    filteredArtists =
      query.isEmpty ? artists : artists.filter { $0.localizedCaseInsensitiveContains(query) }

    // 3. 过滤专辑
    let albums = groupedAlbums.keys.sorted {
      $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
    }
    filteredAlbums =
      query.isEmpty ? albums : albums.filter { $0.localizedCaseInsensitiveContains(query) }

    // 4. 过滤流派
    let genres = groupedGenres.keys.sorted {
      $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
    }
    filteredGenres =
      query.isEmpty ? genres : genres.filter { $0.localizedCaseInsensitiveContains(query) }
  }

  private var cancellables = Set<AnyCancellable>()

  public init() {
    abRepeatCancellable = abRepeat.objectWillChange.sink { [weak self] _ in
      self?.objectWillChange.send()
    }

    // 设置去抖动（Debounce）
    $searchText
      .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
      .removeDuplicates()
      .sink { [weak self] _ in
        self?.updateFilteredCollections()
      }
      .store(in: &cancellables)

    loadStateFromStore()

    #if os(iOS)
      let nc = NotificationCenter.default
      appObservers.append(
        nc.addObserver(
          forName: UIApplication.didEnterBackgroundNotification,
          object: nil,
          queue: .main
        ) { [weak self] _ in
          Task { @MainActor in
            self?.persistPlaybackState(force: true)
          }
        }
      )
      appObservers.append(
        nc.addObserver(
          forName: UIApplication.willTerminateNotification,
          object: nil,
          queue: .main
        ) { [weak self] _ in
          Task { @MainActor in
            self?.persistPlaybackState(force: true)
          }
        }
      )
    #elseif os(macOS)
      let nc = NotificationCenter.default
      appObservers.append(
        nc.addObserver(
          forName: NSApplication.willTerminateNotification,
          object: nil,
          queue: .main
        ) { [weak self] _ in
          print("🖥️ macOS: App 即将退出，正在强制落盘...")
          Task { @MainActor in
            self?.persistPlaybackState(force: true)
          }
        }
      )
      appObservers.append(
        nc.addObserver(
          forName: NSApplication.didResignActiveNotification,
          object: nil,
          queue: .main
        ) { [weak self] _ in
          print("🖥️ macOS: App 失去焦点，正在强制落盘...")
          Task { @MainActor in
            self?.persistPlaybackState(force: true)
          }
        }
      )
      appObservers.append(
        nc.addObserver(
          forName: NSApplication.willResignActiveNotification,
          object: nil,
          queue: .main
        ) { [weak self] _ in
          Task { @MainActor in
            self?.persistPlaybackState(force: true)
          }
        }
      )
    #endif

    #if os(iOS)
      appObservers.append(
        nc.addObserver(
          forName: AVAudioSession.interruptionNotification,
          object: AVAudioSession.sharedInstance(),
          queue: .main
        ) { [weak self] notification in
          guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
          else {
            return
          }

          if type == .began {
            print("📞 iOS: 监听到音频中断（电话/闹钟等），正在强制落盘...")
            Task { @MainActor in
              self?.persistPlaybackState(force: true)
              // 自动挂起播放
              self?.isPlaying = false
            }
          } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
              let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
              if options.contains(.shouldResume) {
                print("📞 iOS: 中断结束，尝试恢复播放...")
                Task { @MainActor in
                  self?.togglePlay()
                }
              }
            }
          }
        }
      )

      // 监听音频路由变化（耳机/蓝牙断开暂停）
      appObservers.append(
        nc.addObserver(
          forName: AVAudioSession.routeChangeNotification,
          object: AVAudioSession.sharedInstance(),
          queue: .main
        ) { [weak self] notification in
          guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
          else {
            return
          }

          switch reason {
          case .oldDeviceUnavailable:  // 旧设备不可用（如拔出耳机、断开蓝牙）
            print("🎧 iOS: 音频设备断开（拔出耳机/蓝牙断连），立即暂停以避免尴尬...")
            Task { @MainActor in
              // 只有在正在播放时才需要暂停
              if self?.isPlaying == true {
                self?.togglePlay()
              }
            }
          case .newDeviceAvailable:  // 新设备可用（如插入耳机、连接蓝牙）
            print("🎧 iOS: 新音频设备已连接，继续播放...")
            Task { @MainActor in
              // 如果当前由于某种原因没在播放（且不是手动暂停），可以尝试恢复
              if self?.isPlaying == false && self?.currentSong != nil {
                self?.togglePlay()
              }
            }
          default:
            break
          }
        }
      )
    #endif

    playback.onIsPlayingChanged = { [weak self] playing in
      DispatchQueue.main.async {
        self?.isPlaying = playing
        if !playing {
          self?.persistPlaybackState(force: true)
        }
      }
    }

    playback.onTimeChanged = { [weak self] current, duration in
      guard let self else { return }
      DispatchQueue.main.async {
        self.currentTime = current
        self.duration = duration

        if let target = self.abRepeat.seekTargetIfNeeded(currentTime: current, duration: duration) {
          self.seek(to: target)
        }

        // 节流保存进度
        self.persistPlaybackState()
      }
    }

    playback.onDidFinish = { [weak self] in
      DispatchQueue.main.async {
        print("🎵 MusicManager: 歌曲播放结束，准备切换下一首...")
        self?.playNext()
      }
    }

    playback.onSystemNowPlayingChanged = { [weak self] pid, title, artist in
      guard let self else { return }
      DispatchQueue.main.async {
        self.abRepeat.clear()
        if let match = self.allSongs.first(where: { $0.persistentID == pid }) {
          self.currentSong = match
          self.persistPlaybackState(force: true)
        } else {
          self.currentSong = SongItem(
            title: title ?? "",
            artist: artist ?? "",
            album: nil,
            genre: nil,
            url: nil,
            duration: 0,
            persistentID: pid
          )
          self.persistPlaybackState(force: true)
        }
      }
    }

    playback.setRate(playbackSpeed)
    playback.setShuffle(shuffleEnabled)
    playback.setRepeatOne(repeatOneEnabled)

    // 初始化时更新一次分组
    updateGroupedCollections()
  }

  public func sort(by key: String, ascending: Bool) {
    self.sortKey = key
    self.sortAscending = ascending
    self.updateFilteredCollections()
  }

  // MARK: - 媒体库交互
  public func fetchMusic() {
    #if os(iOS)
      let status = MPMediaLibrary.authorizationStatus()
      if status == .authorized {
        loadSongsFromSystemLibrary()
        return
      }

      MPMediaLibrary.requestAuthorization { [weak self] newStatus in
        guard let self else { return }
        if newStatus == .authorized {
          Task { @MainActor in
            self.loadSongsFromSystemLibrary()
          }
        } else {
          print("媒体库访问被拒绝: \(newStatus.rawValue)")
        }
      }
    #elseif os(macOS)
      loadLocalSongsFromStore()
      loadImportedFoldersFromStore()
    // resolveLastPlayedIfPossible 移入 loadLocalSongsFromStore 的主线程回调中，确保 allSongs 已就绪
    #endif
  }

  private func loadPlaybackStatus() {
    guard let store = PlayerSQLiteStore.shared, let state = store.loadStatus() else { return }

    if let currentAudioId = state.currentAudioId,
      let audio = store.fetchAllAudio().first(where: { $0.id == currentAudioId })
    {
      let song = audio.toSongItem()
      print("📖 从数据库恢复状态: \(song.title)")
      self.currentSong = song
      self.duration = song.duration
    }

    self.playbackSpeed = state.playbackSpeed
    self.shuffleEnabled = (state.shuffleMode == 1)
    self.repeatOneEnabled = (state.repeatMode == 1)

    if let abModeInt = state.abMode, let abMode = ABRepeatMode(rawValue: abModeInt) {
      self.abRepeat.set(mode: abMode, pointA: state.abPointA, pointB: state.abPointB)
    }

    self.initialResumePosition = state.position
    self.currentTime = state.position
    print("📖 恢复进度: \(state.position)")
  }

  #if os(macOS)
    private func loadLocalSongsFromStore() {
      let audioEntities = PlayerSQLiteStore.shared?.fetchAllAudio() ?? []
      let songs = audioEntities.map { $0.toSongItem() }
      DispatchQueue.main.async {
        self.allSongs = songs
        print("成功从本地数据库获取歌曲数量: \(self.allSongs.count)")
        // 核心修复：确保歌曲加载后，尝试恢复上次播放状态
        self.loadPlaybackStatus()
        self.resolveLastPlayedIfPossible()
      }
    }

    private func loadImportedFoldersFromStore() {
      let folders = PlayerSQLiteStore.shared?.loadImportedFolders() ?? []
      DispatchQueue.main.async {
        self.importedFolders = folders
      }
    }

    public func removeImportedFolder(_ folder: ImportedFolderEntity) {
      PlayerSQLiteStore.shared?.removeImportedFolder(path: folder.path)
      loadLocalSongsFromStore()
      loadImportedFoldersFromStore()
    }

    /// 批量删除曲目
    /// - Parameters:
    ///   - songs: 要删除的曲目列表
    ///   - deleteFiles: 是否同时删除磁盘上的原始文件
    public func deleteSongs(_ songs: [SongItem], deleteFiles: Bool = false) {
      guard !songs.isEmpty else { return }

      // 1. 如果需要删除文件，执行文件删除
      if deleteFiles {
        for song in songs {
          if let url = song.url {
            try? FileManager.default.removeItem(at: url)
          }
        }
      }

      // 2. 从数据库中删除 (通过 URL 匹配或指纹，由于 SongItem 结构，我们通过 URL 或 Meta 推断指纹)
      // 在这里我们简化逻辑，如果是本地导入的，其 ID 是以 url: 开头的
      let localSongURLs = songs.compactMap { song -> String? in
        if song.id.hasPrefix("url:") {
          return song.url?.absoluteString
        }
        return nil
      }

      if !localSongURLs.isEmpty {
        PlayerSQLiteStore.shared?.deleteSongsByURLs(localSongURLs)
      }

      // 3. 刷新界面
      loadLocalSongsFromStore()
    }

    public func importLocalFolder() {
      MacFolderImporter.shared.selectItems { [weak self] urls in
        guard let self = self, !urls.isEmpty else { return }

        DispatchQueue.main.async {
          self.isImporting = true
          self.importProgress = 0
        }

        MacFolderImporter.shared.processSelectedItems(
          urls,
          progress: { p in
            Task { @MainActor in
              self.importProgress = p
            }
          }
        ) { results in
          // 1. 保存文件夹权限和路径
          for url in urls {
            let bookmarkData = try? url.bookmarkData(
              options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            PlayerSQLiteStore.shared?.saveImportedFolder(path: url.path, bookmarkData: bookmarkData)
          }

          // 2. 保存歌曲信息 (不再强制要求每首歌都带 bookmarkData，因为文件夹已经授权)
          let entities = results.map { info in
            AudioEntity(
              id: "url:\(info.url.absoluteString)",
              url: info.url.absoluteString,
              title: info.title,
              artist: info.artist,
              album: info.album,
              genre: info.genre,
              duration: info.duration,
              playCount: 0,
              lastPlayedAt: nil,
              addedAt: Date().timeIntervalSince1970
                // bookmarkData: nil
            )
          }

          PlayerSQLiteStore.shared?.saveAudioEntities(entities)
          Task { @MainActor in
            self.loadLocalSongsFromStore()
            self.loadImportedFoldersFromStore()
            self.isImporting = false
          }
        }
      }
    }
  #endif

  #if os(iOS)
    private func loadSongsFromSystemLibrary() {
      DispatchQueue.global(qos: .userInitiated).async {
        let query = MPMediaQuery.songs()
        let items = query.items ?? []
        let mapped = items.map { item in
          SongItem(
            title: item.title ?? "",
            artist: item.artist ?? "",
            album: item.albumTitle ?? "",
            genre: item.genre ?? "",
            url: item.assetURL,
            duration: item.playbackDuration,
            persistentID: item.persistentID,
            bookmarkData: nil
          )
        }

        DispatchQueue.main.async {
          self.allSongs = mapped
          // updateGroupedCollections() will be called by didSet of allSongs
          self.resolveLastPlayedIfPossible()
          print("成功获取歌曲数量: \(self.allSongs.count)")
        }
      }
    }
  #endif

  // MusicManager.swift

  public func play(song: SongItem, context: [SongItem]? = nil) {
    // 1. 获取授权后的 URL
    guard let finalURL = resolveAuthorizedURL(for: song) else {
      print("❌ 无法获取可播放的 URL")
      return
    }

    // 2. 开启沙盒访问资源
    let canAccess = finalURL.startAccessingSecurityScopedResource()
    print("📂 资源访问状态: \(canAccess) 路径: \(finalURL.path)")

    // 3. 更新 UI 和执行播放
    DispatchQueue.main.async {
      self.objectWillChange.send()
      self.currentSong = song
      self.playback.play(song: song)
      self.isPlaying = true
      self.abRepeat.clear()
      self.persistPlaybackState(force: true)
      print("✅ MusicManager: 正在播放 -> \(song.title)")
    }

    // 4. 异步构建并持久化“播放清单”
    let queueContext = context ?? (self.filteredSongs.contains(song) ? self.filteredSongs : [song])
    let currentShuffle = self.shuffleEnabled

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self, let store = PlayerSQLiteStore.shared else { return }
      let entities = queueContext.map { AudioEntity.from(songItem: $0) }
      store.saveAudioEntities(entities)
      store.updateQueue(
        newSongs: entities,
        activeSongId: song.id,
        sourceType: "dynamic_context",
        sourceId: nil,
        shuffle: currentShuffle
      )

      let updatedQueue = store.fetchQueue()
      DispatchQueue.main.async {
        self.playbackQueue = updatedQueue
        self.objectWillChange.send()
      }
    }
  }

  public func togglePlay() {
    if playback.isIdle() {
      guard let song = currentSong else { return }
      playback.play(song: song)
      let resume = initialResumePosition ?? 0
      if resume > 0.5 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
          self?.seek(to: resume)
          // 恢复进度后清除一次性标记
          self?.initialResumePosition = nil
        }
      }
      return
    }
    playback.togglePlayPause()
  }

  public func seek(to seconds: Double) {
    // 先乐观更新 UI，避免“点了但要等 0.5s 才跳”的体感延迟。
    let clamped = min(max(0, seconds), duration)
    currentTime = clamped
    playback.seek(to: clamped)
  }

  public func playNext() {
    guard !playbackQueue.isEmpty else { return }
    let next = neighborSongInQueue(direction: 1) ?? playbackQueue.first
    if let next { play(song: next) }
  }

  public func playPrevious() {
    guard !playbackQueue.isEmpty else { return }
    let prev = neighborSongInQueue(direction: -1) ?? playbackQueue.last
    if let prev { play(song: prev) }
  }

  private func neighborSongInQueue(direction: Int) -> SongItem? {
    guard !playbackQueue.isEmpty else { return nil }
    guard let currentSong else { return nil }

    let idx = playbackQueue.firstIndex(where: { isSameSong($0, currentSong) })
    guard let idx else { return nil }

    let n = playbackQueue.count
    let newIndex = (idx + direction % n + n) % n
    return playbackQueue[newIndex]
  }

  private func neighborSong(direction: Int) -> SongItem? {
    guard !allSongs.isEmpty else { return nil }
    guard let currentSong else { return nil }

    let idx: Int? = {
      if let pid = currentSong.persistentID {
        return allSongs.firstIndex(where: { $0.persistentID == pid })
      }
      if let url = currentSong.url {
        return allSongs.firstIndex(where: { $0.url == url })
      }
      // 兜底：标题+歌手匹配
      return allSongs.firstIndex(where: {
        $0.title == currentSong.title && $0.artist == currentSong.artist
      })
    }()

    guard let idx else { return nil }
    let n = allSongs.count
    let newIndex = (idx + direction % n + n) % n
    return allSongs[newIndex]
  }

  private func randomSong(excluding current: SongItem?) -> SongItem? {
    guard !allSongs.isEmpty else { return nil }
    if allSongs.count == 1 { return allSongs.first }

    // 尽量避免随机到同一首
    for _ in 0..<6 {
      if let s = allSongs.randomElement(), !isSameSong(s, current) {
        return s
      }
    }
    return allSongs.randomElement()
  }

  public func isFavorite(_ song: SongItem?) -> Bool {
    guard let song else { return false }
    guard let fav = playlists.first else { return false }
    return fav.songs.contains(where: { isSameSong($0, song) })
  }

  public func toggleFavorite() {
    guard let song = currentSong else { return }
    guard !playlists.isEmpty else { return }

    if isFavorite(song) {
      playlists[0].songs.removeAll(where: { self.isSameSong($0, song) })
    } else {
      playlists[0].songs.append(song)
    }
    // 保存播放列表状态
    PlayerSQLiteStore.shared?.savePlaylist(playlists[0])
  }

  private func isSameSong(_ a: SongItem, _ b: SongItem?) -> Bool {
    guard let b else { return false }
    if let ap = a.persistentID, let bp = b.persistentID, ap != 0, bp != 0 {
      return ap == bp
    }
    if let au = a.url, let bu = b.url {
      return au == bu
    }
    return a.title == b.title && a.artist == b.artist
  }

  // MARK: - 播放列表操作逻辑 (macOS & iOS 共用)
  public func createPlaylist(name: String) {
    let newPlaylist = Playlist(name: name, songs: [])
    playlists.append(newPlaylist)
    // 同步到数据库
    PlayerSQLiteStore.shared?.savePlaylist(newPlaylist)
  }

  public func addToPlaylist(playlistId: UUID, songsToAdd: [SongItem]) {
    guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }

    for song in songsToAdd {
      // 避免重复添加同一首歌
      if !playlists[index].songs.contains(where: { $0.id == song.id }) {
        playlists[index].songs.append(song)
      }
    }

    // 同步到数据库
    PlayerSQLiteStore.shared?.savePlaylist(playlists[index])

    // 批量添加完成后，自动清理选择状态并退出多选模式
    clearSelection()
  }

  public func addToPlaylist(playlistId: UUID, song: SongItem) {
    addToPlaylist(playlistId: playlistId, songsToAdd: [song])
  }

  public func clearSelection() {
    selectedSongs.removeAll()
    isMultiSelectMode = false
  }

  public func clearABRepeat() {
    abRepeat.clear()
    persistPlaybackState(force: true)
  }

  public func cycleABRepeat() {
    abRepeat.cycle(currentTime: currentTime, duration: duration)
    persistPlaybackState(force: true)
  }

  private func loadStateFromStore() {
    guard let store = PlayerSQLiteStore.shared else { return }
    isInitialLoading = true
    defer { isInitialLoading = false }

    // 0. 加载本地媒体库歌曲 (macOS 专属)
    #if os(macOS)
      loadLocalSongsFromStore()
      loadImportedFoldersFromStore()
    #endif

    // 1. 加载播放列表
    let savedPlaylists = store.loadPlaylists()
    if !savedPlaylists.isEmpty {
      self.playlists = savedPlaylists
    } else {
      // 如果为空，确保“我的收藏”存在
      _ = store.ensureFavoritesPlaylist()
      self.playlists = store.loadPlaylists()
    }

    // 2. 加载最近播放 (从 AudioEntity 中获取最后播放时间倒序的项目)
    let audioEntities = store.fetchAllAudio().sorted {
      ($0.lastPlayedAt ?? 0) > ($1.lastPlayedAt ?? 0)
    }
    self.recentSongs = audioEntities.prefix(50).map { $0.toSongItem() }

    // 3. 加载持久化状态 (macOS 在 loadLocalSongsFromStore 中异步加载，这里主要针对 iOS)
    #if os(iOS)
      loadPlaybackStatus()
    #endif

    // 4. 加载播放队列
    let queue = store.fetchQueue()
    self.playbackQueue = queue
    print("📖 已从数据库加载播放队列，数量: \(queue.count)")
  }

  private var initialResumePosition: Double?

  private func resolveAuthorizedURL(for song: SongItem) -> URL? {
    #if os(macOS)
      if let songURL = song.url {
        // 1. 检查所属文件夹授权
        if let folder = self.importedFolders.first(where: { songURL.path.hasPrefix($0.path) }),
          let data = folder.bookmarkData
        {
          var isStale = false
          let folderURL = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale)

          if let fURL = folderURL, fURL.startAccessingSecurityScopedResource() {
            return songURL
          }
        }
      }
    #endif

    // 2. 尝试歌曲自身的书签
    if let data = song.bookmarkData {
      var isStale = false
      #if os(macOS)
        let options = URL.BookmarkResolutionOptions.withSecurityScope
      #else
        let options = URL.BookmarkResolutionOptions()
      #endif

      return try? URL(
        resolvingBookmarkData: data,
        options: options,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale)
    }
    return song.url
  }

  private func resolveLastPlayedIfPossible() {
    guard let current = currentSong else { return }

    // 在 allSongs 中寻找匹配项
    if let matchedSong = allSongs.first(where: { isSameSong($0, current) }) {
      self.currentSong = matchedSong
    }

    // 恢复进度
    if let pos = initialResumePosition {
      self.currentTime = pos

      // 核心修复：确保恢复时也处理安全作用域授权
      if resolveAuthorizedURL(for: current) != nil {
        self.playback.prepare(song: current, shouldPlay: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
          self?.playback.seek(to: pos)
        }
      }
    }
  }

  private func persistPlaybackState(force: Bool = false) {
    guard let store = PlayerSQLiteStore.shared else { return }
    if isInitialLoading { return }

    let now = Date()
    if !force && now.timeIntervalSince(lastPersistTime) < persistInterval {
      return
    }

    lastPersistTime = now
    // 如果没有正在播放的歌曲，也要保存状态（比如清除当前播放）
    let currentAudioId = currentSong?.id

    #if os(iOS)
      let taskID = UIApplication.shared.beginBackgroundTask(withName: "PersistPlaybackState") {}
      defer { UIApplication.shared.endBackgroundTask(taskID) }
    #endif

    let status = PlaybackStatusEntity(
      id: 1,
      currentAudioId: currentAudioId,
      position: currentTime,
      playbackSpeed: playbackSpeed,
      shuffleMode: shuffleEnabled ? 1 : 0,
      repeatMode: repeatOneEnabled ? 1 : 0,
      volume: 1.0,  // Should be actual volume
      isPlaying: isPlaying,
      lastUpdated: now.timeIntervalSince1970,
      abPointA: abRepeatPointA,
      abPointB: abRepeatPointB,
      abMode: abRepeatMode.rawValue
    )

    store.saveStatus(status)

    if let storageKey = currentAudioId {
      store.incrementPlayCount(audioId: storageKey)
      store.markAsPlayed(audioId: storageKey)

      // 同步更新内存中的最近播放列表
      DispatchQueue.main.async {
        if !self.recentSongs.contains(where: { self.isSameSong($0, self.currentSong!) }) {
          self.recentSongs.insert(self.currentSong!, at: 0)
          if self.recentSongs.count > 50 {
            self.recentSongs.removeLast()
          }
        } else {
          if let index = self.recentSongs.firstIndex(where: {
            self.isSameSong($0, self.currentSong!)
          }) {
            let item = self.recentSongs.remove(at: index)
            self.recentSongs.insert(item, at: 0)
          }
        }
      }
    }
  }

  deinit {
    #if os(iOS)
      let nc = NotificationCenter.default
      for token in appObservers {
        nc.removeObserver(token)
      }
      appObservers.removeAll()
    #endif
    playback.shutdown()
  }
}
