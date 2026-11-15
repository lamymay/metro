import SwiftUI
import PlayerEngine

public struct ContentView: View {
  @ObservedObject var vm: MusicManager
  @EnvironmentObject private var theme: ThemeManager
  @State private var showingPlaylistPicker = false
  @State private var selectedSongForPlaylist: SongItem?
  @State private var showFullPlayer = false
  @State private var showingSideMenu = false
  @State private var showSearch = false
  @AppStorage("library.selectedTab") private var tabRaw: String = LibraryTab.playlists.rawValue
  @FocusState private var isSearchFieldFocused: Bool
  @Namespace private var tabNamespace

  public init(vm: MusicManager) {
    self.vm = vm
  }

  private var tab: LibraryTab {
    get { LibraryTab(rawValue: tabRaw) ?? .playlists }
    set { tabRaw = newValue.rawValue }
  }

  public var body: some View {
    #if os(macOS)
      EmptyView()  // macOS 使用 MacContentView
    #else
      NavigationStack {
        VStack(spacing: 0) {
          topBar

          tabBar
          Divider()

          Group {
            switch tab {
            case .playlists:
              playlistsSection
            case .artists:
              artistsSection
            case .albums:
              albumsSection
            case .songs:
              songsSection
            case .genres:
              genresSection
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.systemBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
          MiniPlayer(vm: vm, onOpen: { showFullPlayer = true })
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .onChange(of: tabRaw) {
          if tab != .songs {
            vm.clearSelection()
          }
        }
      }
      .sheet(isPresented: $showingPlaylistPicker) {
        PlaylistPicker(
          vm: vm, song: selectedSongForPlaylist,
          songs: vm.isMultiSelectMode ? vm.selectedSongs : nil
        )
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(32)
      }
      .sheet(isPresented: $showingSideMenu) {
        SideMenuView(
          vm: vm,
          refreshAction: { vm.fetchMusic() },
          dismissAction: { showingSideMenu = false }
        )
      }
      .fullScreenCover(isPresented: $showFullPlayer) {
        FullPlayerView(vm: vm)  // 在这里可以调整播放倍速
      }
      .onAppear {
        vm.fetchMusic()
        // 预热键盘：延迟稍长一点以避开媒体库加载的 CPU 峰值
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
          prewarmKeyboardSilently()
        }
      }
    #endif
  }

  private var topBar: some View {
    HStack(spacing: 12) {
      if showSearch {
        // 搜索模式：搜索框直接替换标题栏，实现“浑然一体”
        HStack(spacing: 10) {
          Image(systemName: "magnifyingglass")
            .font(.subheadline)
            .foregroundColor(.secondary)

          TextField("搜索歌曲、艺术家、专辑...", text: $vm.searchText)
            .focused($isSearchFieldFocused)
            .foregroundColor(.primary)
            .submitLabel(.done)
            .onSubmit { isSearchFieldFocused = false }

          if !vm.searchText.isEmpty {
            Button(action: { vm.searchText = "" }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
            }
          }

          Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
              showSearch = false
              vm.searchText = ""
              isSearchFieldFocused = false
            }
          }) {
            Text("取消")
              .font(.body)
              .foregroundColor(theme.primary)
          }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondarySystemBackground)
        .cornerRadius(12)
        .transition(
          .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)))
      } else {
        // 普通模式
        HStack {
          Button(action: { showingSideMenu = true }) {
            Image(systemName: "line.3.horizontal")
              .font(.title3.weight(.semibold))
              .foregroundColor(.primary)
              .frame(width: 40, height: 40)
              .background(Color.systemBackground)
              .cornerRadius(10)
              .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
          }
          .buttonStyle(.plain)

          Spacer()

          Text("我的媒体库")
            .font(.headline.weight(.semibold))
            .foregroundColor(.primary)

          Spacer()

          Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
              showSearch = true
            }
            // 核心修复：默认不再把焦点放在输入框中
          }) {
            Image(systemName: "magnifyingglass")
              .font(.title3.weight(.semibold))
              .foregroundColor(.primary)
              .frame(width: 40, height: 40)
              .background(Color.systemBackground)
              .cornerRadius(10)
              .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
          }
          .buttonStyle(.plain)
        }
        .transition(
          .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)))
      }
    }
    .padding(.horizontal, 12)
    .padding(.top, 0)
    .padding(.bottom, 8)
  }

  private var tabBar: some View {
    HStack(spacing: 0) {
      ForEach(LibraryTab.allCases) { t in
        Button(action: {
          withAnimation(.spring(response: 0.25, dampingFraction: 0.92)) {
            tabRaw = t.rawValue
          }
        }) {
          VStack(spacing: 8) {
            Text(t.title)
              .font(.subheadline.weight(tab == t ? .semibold : .regular))
              .foregroundColor(tab == t ? .primary : .secondary)
              .lineLimit(1)
              .frame(maxWidth: .infinity)

            ZStack {
              if tab == t {
                Rectangle()
                  .fill(theme.primary)
                  .matchedGeometryEffect(id: "underline", in: tabNamespace)
              } else {
                Rectangle().fill(Color.clear)
              }
            }
            .frame(height: 3)
          }
          .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
      }
    }
    .padding(.horizontal, 8)
    .background(Color.systemBackground)
  }

  private var playlistsSection: some View {
    let playlists: [Playlist] = {
      if vm.searchText.isEmpty {
        return vm.playlists
      }
      return vm.playlists.filter { $0.name.localizedCaseInsensitiveContains(vm.searchText) }
    }()

    return List {
      if !vm.recentSongs.isEmpty, vm.searchText.isEmpty {
        Section("最近播放") {
          ForEach(Array(vm.recentSongs.prefix(12))) { song in
            SongRow(song: song, isCurrent: vm.currentSong == song) {
              vm.play(song: song)
            }
            .listRowBackground(Color.clear)
          }
        }
      }

      ForEach(playlists) { playlist in
        NavigationLink {
          PlaylistDetailView(vm: vm, playlistId: playlist.id)
        } label: {
          HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
              .fill(
                LinearGradient(
                  colors: coverPalette(seed: playlist.name), startPoint: .topLeading,
                  endPoint: .bottomTrailing)
              )
              .frame(width: 52, height: 52)
              .overlay(Image(systemName: "music.note.list").foregroundColor(.white.opacity(0.95)))

            VStack(alignment: .leading, spacing: 4) {
              Text(playlist.name).foregroundColor(.primary).font(.headline)
              Text("\(playlist.songs.count) 首歌曲").foregroundColor(.secondary).font(.caption)
            }

            Spacer()
            Image(systemName: "ellipsis")
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 6)
        }
        .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.systemBackground)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var artistsSection: some View {
    List {
      ForEach(vm.filteredArtists, id: \.self) { artist in
        NavigationLink {
          ArtistDetailView(vm: vm, artist: artist)
        } label: {
          HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
              .fill(
                LinearGradient(
                  colors: coverPalette(seed: artist), startPoint: .topLeading,
                  endPoint: .bottomTrailing)
              )
              .frame(width: 52, height: 52)
              .overlay(Image(systemName: "person.2.fill").foregroundColor(.white.opacity(0.95)))

            VStack(alignment: .leading, spacing: 4) {
              Text(artist).foregroundColor(.primary).font(.headline)
              Text("\(vm.groupedArtists[artist]?.count ?? 0) 首歌曲").foregroundColor(.secondary).font(
                .caption)
            }

            Spacer()
            Image(systemName: "ellipsis")
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 6)
        }
        .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.systemBackground)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var albumsSection: some View {
    List {
      ForEach(vm.filteredAlbums, id: \.self) { album in
        NavigationLink {
          AlbumDetailView(vm: vm, album: album)
        } label: {
          HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
              .fill(
                LinearGradient(
                  colors: coverPalette(seed: album), startPoint: .topLeading,
                  endPoint: .bottomTrailing)
              )
              .frame(width: 52, height: 52)
              .overlay(Image(systemName: "square.stack.fill").foregroundColor(.white.opacity(0.95)))

            VStack(alignment: .leading, spacing: 4) {
              Text(album).foregroundColor(.primary).font(.headline)
              Text("\(vm.groupedAlbums[album]?.count ?? 0) 首歌曲").foregroundColor(.secondary).font(
                .caption)
            }

            Spacer()
            Image(systemName: "ellipsis")
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 6)
        }
        .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.systemBackground)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var songsSection: some View {
    List(selection: $vm.selectedSongs) {
      ForEach(vm.filteredSongs) { song in
        SongRow(song: song, isCurrent: vm.currentSong == song) {
          vm.play(song: song)
        }
        .tag(song.id as String)
        .listRowBackground(Color.clear)
        .onLongPressGesture(minimumDuration: 0.5) {
          if !vm.isMultiSelectMode {
            handleLongPress(for: song)
          }
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.systemBackground)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    #if os(iOS)
      .environment(\.editMode, .constant(vm.isMultiSelectMode ? .active : .inactive))
    #endif
  }

  private var genresSection: some View {
    List {
      ForEach(vm.filteredGenres, id: \.self) { genre in
        NavigationLink {
          GenreDetailView(vm: vm, genre: genre)
        } label: {
          HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
              .fill(
                LinearGradient(
                  colors: coverPalette(seed: genre), startPoint: .topLeading,
                  endPoint: .bottomTrailing)
              )
              .frame(width: 52, height: 52)
              .overlay(Image(systemName: "guitars").foregroundColor(.white.opacity(0.95)))

            VStack(alignment: .leading, spacing: 4) {
              Text(genre).foregroundColor(.primary).font(.headline)
              Text("\(vm.groupedGenres[genre]?.count ?? 0) 首歌曲").foregroundColor(.secondary).font(
                .caption)
            }

            Spacer()
            Image(systemName: "ellipsis")
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 6)
        }
        .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.systemBackground)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func handleLongPress(for song: SongItem) {
    HapticHelper.trigger(.medium)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
      self.selectedSongForPlaylist = song
      withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
        self.showingPlaylistPicker = true
      }
    }
  }
}

private enum LibraryTab: String, CaseIterable, Identifiable {
  case playlists
  case artists
  case albums
  case songs
  case genres

  var id: String { rawValue }

  var title: String {
    switch self {
    case .playlists: return "播放列表"
    case .artists: return "艺术家"
    case .albums: return "专辑"
    case .songs: return "曲目"
    case .genres: return "流派"
    }
  }
}

private func coverPalette(seed: String) -> [Color] {
  let palettes: [[Color]] = [
    [.blue, .indigo],
    [.teal, .green],
    [.orange, .red],
    [.pink, .purple],
    [.yellow, .orange],
    [.mint, .teal],
    [.cyan, .blue],
  ]

  var h = 0
  for s in seed.unicodeScalars {
    h = (h &* 31) &+ Int(s.value)
  }
  let idx = abs(h) % palettes.count
  return palettes[idx]
}

private struct PlaylistDetailView: View {
  @ObservedObject var vm: MusicManager
  let playlistId: UUID
  @EnvironmentObject private var theme: ThemeManager

  private var playlist: Playlist? {
    vm.playlists.first(where: { $0.id == playlistId })
  }

  var body: some View {
    ZStack {
      Color.systemBackground.ignoresSafeArea()
      List {
        if let playlist {
          ForEach(playlist.songs) { song in
            SongRow(song: song, isCurrent: vm.currentSong == song) { vm.play(song: song) }
              .listRowBackground(Color.clear)
          }
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
    }
    .navigationTitle(playlist?.name ?? "播放列表")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}

private struct ArtistDetailView: View {
  @ObservedObject var vm: MusicManager
  let artist: String
  @EnvironmentObject private var theme: ThemeManager

  private var songs: [SongItem] {
    (vm.groupedArtists[artist] ?? [])
      .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
  }

  var body: some View {
    ZStack {
      Color.systemBackground.ignoresSafeArea()
      List {
        ForEach(songs) { song in
          SongRow(song: song, isCurrent: vm.currentSong == song) { vm.play(song: song) }
            .listRowBackground(Color.clear)
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
    }
    .navigationTitle(artist)
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}

private struct AlbumDetailView: View {
  @ObservedObject var vm: MusicManager
  let album: String
  @EnvironmentObject private var theme: ThemeManager

  private var songs: [SongItem] {
    (vm.groupedAlbums[album] ?? [])
      .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
  }

  var body: some View {
    ZStack {
      Color.systemBackground.ignoresSafeArea()
      List {
        ForEach(songs) { song in
          SongRow(song: song, isCurrent: vm.currentSong == song) { vm.play(song: song) }
            .listRowBackground(Color.clear)
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
    }
    .navigationTitle(album)
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}

private struct GenreDetailView: View {
  @ObservedObject var vm: MusicManager
  let genre: String
  @EnvironmentObject private var theme: ThemeManager

  private var songs: [SongItem] {
    (vm.groupedGenres[genre] ?? [])
      .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
  }

  var body: some View {
    ZStack {
      Color.systemBackground.ignoresSafeArea()
      List {
        ForEach(songs) { song in
          SongRow(song: song, isCurrent: vm.currentSong == song) { vm.play(song: song) }
            .listRowBackground(Color.clear)
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
    }
    .navigationTitle(genre)
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}

private struct SideMenuView: View {
  @ObservedObject var vm: MusicManager
  let refreshAction: () -> Void
  let dismissAction: () -> Void
  @EnvironmentObject private var theme: ThemeManager

  var body: some View {
    NavigationStack {
      List {
        #if os(macOS)
          if vm.isImporting {
            Section("正在添加到媒体库媒体库") {
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Text("正在扫描文件...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                  Spacer()
                  Text("\(Int(vm.importProgress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(theme.primary)
                }
                ProgressView(value: vm.importProgress)
                  .tint(theme.primary)
              }
              .padding(.vertical, 4)
            }
          }
        #endif

        Button(action: refreshAction) {
          Label("刷新曲库", systemImage: "arrow.clockwise")
        }
        NavigationLink {
          SettingsView()
        } label: {
          Label("设置", systemImage: "gearshape")
        }
        Button(action: {}) {
          Label("关于", systemImage: "info.circle")
        }
      }
      .navigationTitle("菜单")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .tint(theme.primary)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(action: dismissAction) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.secondary)
          }
        }
      }
    }
  }
}

// MARK: - 键盘预热逻辑 (修复报错与闪烁)
#if os(iOS)
  private var prewarmWindow: UIWindow?

  func prewarmKeyboardSilently() {
    let scenes = UIApplication.shared.connectedScenes
    guard let windowScene = scenes.first as? UIWindowScene else { return }

    // 1. 创建离屏窗口
    prewarmWindow = UIWindow(windowScene: windowScene)
    // 修复：将窗口放置在屏幕可视范围之外
    prewarmWindow?.frame = CGRect(x: -1000, y: -1000, width: 1, height: 1)

    // 修复报错：UIWindow.Level 没有 .background，改用 .normal 或显式指定极低数值
    prewarmWindow?.windowLevel = UIWindow.Level(rawValue: -1)
    prewarmWindow?.isHidden = false

    let controller = UIViewController()
    let textField = UITextField()

    // 设置 alpha 为 0 确保双重保险不显示
    textField.alpha = 0
    controller.view.addSubview(textField)
    prewarmWindow?.rootViewController = controller

    // 2. 激活键盘
    textField.becomeFirstResponder()

    // 3. 异步收起并销毁
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      textField.resignFirstResponder()
      prewarmWindow?.isHidden = true
      prewarmWindow = nil
      print("✅ iPhone 16 Pro 键盘热备已就绪")
    }
  }
#else
  func prewarmKeyboardSilently() {}
#endif
