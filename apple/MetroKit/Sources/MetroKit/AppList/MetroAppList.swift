import SwiftUI

/// The WP app list: an alphabetically grouped list whose group headers zoom out to a
/// grid of letters. `LongListSelector` called this semantic zoom, and it is the reason
/// a 200-app phone never needed a scrollbar.
public struct MetroAppList: View {
  @Environment(\.metroTheme) private var theme
  @Environment(\.metroMotion) private var motion

  public var entries: [String]
  public var onSelect: ((String) -> Void)?

  @State private var zoomedOut = false

  /// The magnifying-glass icon at the top right and the text field it expands into —
  /// WP's app bar search: no dedicated search page, the list filters itself in place.
  @State private var searchActive = false
  @State private var searchText = ""

  public init(entries: [String], onSelect: ((String) -> Void)? = nil) {
    self.entries = entries
    self.onSelect = onSelect
  }

  /// `#` collects everything that does not start with a Latin letter, which is what WP
  /// did for numerals and CJK.
  private static let letters: [String] = ["#"] + (65...90).map { String(UnicodeScalar($0)!) }

  private var filteredEntries: [String] {
    guard searchActive, !searchText.isEmpty else { return entries }
    return entries.filter { $0.localizedCaseInsensitiveContains(searchText) }
  }

  private var grouped: [String: [String]] {
    Dictionary(grouping: filteredEntries) { name in
      guard let first = name.uppercased().first, first.isLetter, first.isASCII else { return "#" }
      return String(first)
    }
  }

  public var body: some View {
    VStack(spacing: 0) {
      searchBar

      ZStack {
        if zoomedOut {
          letterGrid
            .transition(.scale(scale: 1.15).combined(with: .opacity))
        } else {
          list
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
      }
    }
  }

  // MARK: Search

  private var searchBar: some View {
    HStack(spacing: 10) {
      if searchActive {
        MetroIcon(.search, size: 18, color: theme.subtle, weight: 1 / 12)
          .frame(width: 22, height: 22)

        TextField("", text: $searchText)
          .metroText(.normal)
          .autocorrectionDisabled(true)
          #if os(iOS)
            .textInputAutocapitalization(.never)
          #endif

        Spacer(minLength: 0)

        Button {
          withAnimation(motion.animation(.wpOut, 0.2)) {
            searchActive = false
            searchText = ""
          }
        } label: {
          MetroIcon(.close, size: 16, color: theme.subtle, weight: 1 / 12)
            .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
      } else {
        Spacer(minLength: 0)

        MetroIcon(.search, size: 20, color: theme.foreground, weight: 1 / 12)
          .frame(width: 36, height: 36)
          .contentShape(Rectangle())
          .metroTilt {
            withAnimation(motion.animation(.wpIn, 0.2)) { searchActive = true }
          }
      }
    }
    .frame(height: 44)
    .padding(.horizontal, theme.metrics.pageMargin)
  }

  // MARK: List

  private var list: some View {
    let groups = grouped
    return ScrollViewReader { scroller in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(Self.letters.filter { groups[$0]?.isEmpty == false }, id: \.self) { letter in
            MetroGroupHeader(letter) {
              withAnimation(motion.animation(.wpIn, 0.3)) { zoomedOut = true }
            }
            .id(letter)

            // A plain `.sorted()` is case-sensitive on Unicode scalar value — "M" (0x4D)
            // sorts before "a" (0x61), so "FM Radio" would land before "Facebook". WP's
            // list was alphabetised case-insensitively; match that.
            let sorted = (groups[letter] ?? []).sorted {
              $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }
            ForEach(Array(sorted.enumerated()), id: \.element) { index, name in
              appRow(name) { onSelect?(name) }
                .metroFeather(order: index)
            }
          }
        }
        .padding(.bottom, 40)
      }
      // The jump happens while the list is being re-inserted, so the target is stashed
      // before the zoom and consumed here once there is something to scroll.
      .task(id: pendingScroll) { consumePendingScroll(scroller) }
    }
  }

  /// WP's app list row was never bare text — every entry carried the app's own small
  /// tile icon on the left. We have no real app icons to draw from, so each name gets a
  /// deterministic glyph (by keyword) and accent (by hash), which is enough to read as
  /// "a wall of distinct apps" rather than a plain text list.
  private func appRow(_ name: String, action: @escaping () -> Void) -> some View {
    HStack(spacing: 14) {
      ZStack {
        Rectangle().fill(Self.accent(for: name).color)
        MetroIcon(Self.glyph(for: name), size: 20, color: .white, weight: 1 / 14)
      }
      .frame(width: 36, height: 36)

      Text(name)
        .metroText(.title3)
        .lineLimit(1)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, theme.metrics.pageMargin)
    .contentShape(Rectangle())
    .metroTilt { action() }
  }

  private static func glyph(for name: String) -> MetroGlyph {
    let n = name.lowercased()
    let table: [(String, MetroGlyph)] = [
      ("phone", .phone), ("nokia care", .phone),
      ("mail", .mail), ("outlook", .mail), ("email", .mail),
      ("message", .message), ("whatsapp", .message), ("微信", .message),
      ("people", .people), ("contact", .people), ("kids corner", .people),
      ("camera", .camera), ("lens", .camera),
      ("calendar", .calendar),
      ("music", .music), ("radio", .music), ("podcast", .music), ("voice recorder", .music),
      ("store", .store), ("amazon", .store),
      ("settings", .settings), ("battery", .settings), ("data sense", .settings),
      ("bing", .search), ("search", .search),
      ("weather", .sun),
      ("alarm", .clock), ("clock", .clock),
      ("photo", .photo), ("video", .photo),
      ("file", .folder), ("document", .folder), ("onedrive", .folder),
      ("office", .folder), ("word", .folder), ("onenote", .folder),
      ("note", .folder), ("reading list", .folder),
      ("map", .globe), ("drive", .globe), ("travel", .globe), ("translator", .globe),
      ("百度地图", .globe),
      ("wallet", .star), ("1password", .star), ("game", .star), ("xbox", .star), ("sport", .star),
      ("health", .heart),
      ("news", .globe),
      ("facebook", .message), ("twitter", .message), ("instagram", .camera),
    ]
    for (key, glyph) in table where n.contains(key) { return glyph }
    return .folder
  }

  private static func accent(for name: String) -> MetroAccent {
    let all = MetroAccent.allCases
    var hash = 0
    for scalar in name.unicodeScalars { hash = (hash &* 31 &+ Int(scalar.value)) & 0x7FFFFFFF }
    return all[hash % all.count]
  }

  private func consumePendingScroll(_ scroller: ScrollViewProxy) {
    guard let target = pendingScroll else { return }
    DispatchQueue.main.async {
      scroller.scrollTo(target, anchor: .top)
      pendingScroll = nil
    }
  }

  @State private var pendingScroll: String?

  // MARK: Semantic zoom

  private var letterGrid: some View {
    let groups = grouped
    return GeometryReader { proxy in
      let columns = 4
      let gap = theme.metrics.gap
      let side = (proxy.size.width - theme.metrics.pageMargin * 2 - gap * CGFloat(columns - 1)) / CGFloat(columns)

      ScrollView {
        LazyVGrid(
          columns: Array(repeating: GridItem(.fixed(side), spacing: gap), count: columns),
          spacing: gap
        ) {
          ForEach(Array(Self.letters.enumerated()), id: \.element) { index, letter in
            let enabled = groups[letter]?.isEmpty == false
            ZStack(alignment: .bottomLeading) {
              Rectangle().fill(enabled ? theme.accentColor : Color.clear)
              Text(letter.lowercased())
                .metroText(.title1)
                .foregroundColor(enabled ? theme.onAccent : theme.disabled)
                .padding(.leading, 8)
                .padding(.bottom, 4)
            }
              .frame(width: side, height: side)
              .overlay {
                if !enabled {
                  Rectangle().strokeBorder(theme.disabled.opacity(0.5), lineWidth: 1)
                }
              }
              .contentShape(Rectangle())
              .metroTilt(isEnabled: enabled) {
                pendingScroll = letter
                withAnimation(motion.animation(.wpIn, 0.3)) { zoomedOut = false }
              }
              .metroFeather(order: index)
          }
        }
        .padding(.horizontal, theme.metrics.pageMargin)
        .padding(.top, 8)
      }
    }
  }
}
