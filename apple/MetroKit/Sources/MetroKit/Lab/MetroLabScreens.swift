import SwiftUI

// MARK: - Tiles

/// Every tile permutation on one page: footprint, style, behaviour and accent, with a
/// live preview you can press.
struct MetroTileLab: View {
  @Environment(\.metroTheme) private var theme

  @State private var size = MetroTileSize.medium
  @State private var style = MetroTileStyle.accent
  @State private var behaviour = MetroTileBehaviour.flip
  @State private var accent = MetroAccent.cobalt
  @State private var badge = true

  private var model: MetroTileModel {
    MetroTileModel(
      id: "playground-\(size.rawValue)-\(behaviour.rawValue)",
      title: "playground",
      glyph: .mail,
      accent: accent,
      style: style,
      size: size,
      badge: badge ? 12 : nil,
      behaviour: behaviour,
      faces: [
        .iconic,
        .message(from: "Kaori", body: "タイルの裏面はキャプションを出さない"),
        .counter(12, caption: "unread"),
      ]
    )
  }

  var body: some View {
    MetroPage(applicationTitle: "metrokit", title: "tiles") {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          HStack {
            Spacer(minLength: 0)
            MetroTile(model: model, unit: 74, gap: theme.metrics.gap)
              .id(model.id)
            Spacer(minLength: 0)
          }
          .frame(height: 190)

          picker("footprint", MetroTileSize.allCases, selection: $size) { $0.displayName }
          picker("style", MetroTileStyle.allCases, selection: $style) { $0.displayName }
          picker("behaviour", MetroTileBehaviour.allCases, selection: $behaviour) { $0.displayName }
          MetroCheckBox("badge", isOn: $badge)

          Text("accent").metroText(.groupHeader)
          MetroAccentSwatches(selection: $accent)

          Text("packing").metroText(.groupHeader)
          Text("first-fit, left to right then down — a wide tile can leave holes above it that later small tiles drop into")
            .metroText(.small)
          MetroTileGrid(tiles: MetroSampleData.startTiles)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, theme.metrics.pageMargin)
      }
    }
  }

  @ViewBuilder private func picker<T: Hashable & Identifiable>(
    _ title: String,
    _ options: [T],
    selection: Binding<T>,
    label: @escaping (T) -> String
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).metroText(.groupHeader)
      HStack(spacing: 8) {
        ForEach(options) { option in
          MetroChip(label(option), isSelected: selection.wrappedValue == option) {
            selection.wrappedValue = option
          }
        }
        Spacer(minLength: 0)
      }
    }
  }
}

// MARK: - Typography

struct MetroTypographyLab: View {
  @Binding var theme: MetroTheme

  private let families: [(String, MetroFontFamily)] = [
    ("system", .system), ("helvetica", .helveticaNeue), ("segoe wp", .segoeWP),
  ]

  var body: some View {
    MetroPage(applicationTitle: "metrokit", title: "type ramp") {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          MetroSlider(
            "ramp scale",
            value: Binding(
              get: { Double(theme.type.scale) },
              set: { theme.type.scale = CGFloat($0) }
            ),
            in: 0.5...1.2
          ) { String(format: "%.2f", $0) }
          Text("WP sizes are WVGA pixels. 0.80 puts them at the same apparent size on a 390pt phone.")
            .metroText(.small)

          HStack(spacing: 8) {
            ForEach(Array(families.enumerated()), id: \.offset) { _, entry in
              MetroChip(entry.0, isSelected: theme.type.family == entry.1) {
                theme.type.family = entry.1
              }
            }
            Spacer(minLength: 0)
          }
          Text("segoe wp falls back to the system font unless the family is installed")
            .metroText(.small)

          ForEach(MetroTextRole.allCases) { role in
            VStack(alignment: .leading, spacing: 2) {
              Text("\(role.rawValue) · \(Int(role.wpSize))px → \(Int(theme.type.size(role)))pt")
                .metroText(.small)
              Text(sample(for: role))
                .metroText(role)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
            }
          }
          Spacer(minLength: 40)
        }
        .padding(.horizontal, theme.metrics.pageMargin)
      }
    }
  }

  private func sample(for role: MetroTextRole) -> String {
    switch role {
    case .applicationTitle: return "metrokit"
    case .pageTitle, .pivotHeader: return "page title"
    case .panoramaTitle, .huge: return "panorama"
    case .tileBadge: return "12"
    default: return "The quick brown fox 日本語 123"
    }
  }
}

// MARK: - Accents

struct MetroAccentLab: View {
  @Binding var theme: MetroTheme

  var body: some View {
    MetroPage(applicationTitle: "metrokit", title: "accents") {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          HStack(spacing: 8) {
            MetroChip("dark", isSelected: theme.mode == .dark) { theme.mode = .dark }
            MetroChip("light", isSelected: theme.mode == .light) { theme.mode = .light }
            Spacer(minLength: 0)
          }
          Text("the twenty stock WP8 accents, at their shipping hex values")
            .metroText(.small)
          MetroAccentSwatches(selection: $theme.accent)
          Spacer(minLength: 40)
        }
        .padding(.horizontal, theme.metrics.pageMargin)
      }
    }
  }
}

struct MetroAccentSwatches: View {
  @Environment(\.metroTheme) private var theme
  @Binding var selection: MetroAccent

  var body: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: theme.metrics.gap), count: 4),
      spacing: theme.metrics.gap
    ) {
      ForEach(MetroAccent.allCases) { accent in
        ZStack(alignment: .bottomLeading) {
          Rectangle().fill(accent.color)
          Text(accent.displayName)
            .metroText(.small, size: 11)
            .foregroundColor(.white)
            .padding(6)
        }
        .frame(height: 66)
        .overlay {
          if selection == accent {
            Rectangle().strokeBorder(theme.foreground, lineWidth: 3)
          }
        }
        .contentShape(Rectangle())
        .metroTilt { selection = accent }
      }
    }
  }
}

// MARK: - Controls

struct MetroControlsLab: View {
  @Environment(\.metroTheme) private var theme

  @State private var toggle = true
  @State private var check = false
  @State private var radio = 1
  @State private var slider = 0.4
  @State private var text = ""
  @State private var progress = 0.35

  var body: some View {
    MetroPage(applicationTitle: "metrokit", title: "controls") {
      ScrollView {
        VStack(alignment: .leading, spacing: 26) {
          section("button") {
            HStack(spacing: 12) {
              MetroButton("accept") {}
              MetroButton("cancel") {}
              MetroButton("disabled") {}.disabled(true)
            }
          }
          section("toggle") { MetroToggleSwitch("notifications", isOn: $toggle) }
          section("check box") {
            VStack(alignment: .leading, spacing: 10) {
              MetroCheckBox("show on lock screen", isOn: $check)
              MetroCheckBox("always on", isOn: .constant(true))
            }
          }
          section("radio") {
            VStack(alignment: .leading, spacing: 10) {
              ForEach(0..<3, id: \.self) { index in
                MetroRadioButton(["never", "when charging", "always"][index], isSelected: radio == index) {
                  radio = index
                }
              }
            }
          }
          section("slider") { MetroSlider("brightness", value: $slider, in: 0...1) }
          section("text box") { MetroTextBox("search apps", text: $text) }
          section("progress") {
            VStack(alignment: .leading, spacing: 16) {
              MetroProgressBar()
              MetroProgressBar(value: progress)
              MetroSlider("value", value: $progress, in: 0...1)
              HStack { Spacer(); MetroProgressRing(diameter: 64); Spacer() }
            }
          }
          section("list") {
            VStack(alignment: .leading, spacing: 0) {
              ForEach(Array(MetroSampleData.mailPreviews.enumerated()), id: \.offset) { index, item in
                MetroListRow(title: item.0, subtitle: item.1, glyph: .mail) {}
                  .metroFeather(order: index)
              }
            }
            .padding(.horizontal, -theme.metrics.pageMargin)
          }
          Spacer(minLength: 40)
        }
        .padding(.horizontal, theme.metrics.pageMargin)
      }
    }
  }

  @ViewBuilder private func section<Content: View>(
    _ title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title).metroText(.groupHeader)
      content()
    }
  }
}

// MARK: - Transitions

struct MetroTransitionLab: View {
  @Environment(\.metroTheme) private var theme
  @Binding var transition: MetroTransitionKind
  var navigate: () -> Void

  var body: some View {
    MetroPage(applicationTitle: "metrokit", title: "transitions") {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text("the picker changes the transition used by the whole lab — including the back button")
            .metroText(.small)

          VStack(alignment: .leading, spacing: 10) {
            ForEach(MetroTransitionKind.allCases) { kind in
              MetroRadioButton(kind.displayName, isSelected: transition == kind) {
                transition = kind
              }
            }
          }

          MetroButton("navigate forward") { navigate() }

          Text("turnstile · what WP actually shipped")
            .metroText(.groupHeader)
          Text("out: rotate about the left edge to -80°, 250 ms, exponential ease-in (exponent 6)\nin: -80° back to 0, 350 ms, exponential ease-out\nopacity is a step, not a fade — the page is present from frame one")
            .metroText(.small)

          Spacer(minLength: 40)
        }
        .padding(.horizontal, theme.metrics.pageMargin)
      }
    }
  }
}

// MARK: - Panorama / pivot

struct MetroPanoramaLab: View {
  @Environment(\.metroTheme) private var theme

  var body: some View {
    MetroPanorama(
      title: "metro",
      sections: [
        MetroPanoramaSection(title: "start") {
          MetroTileGrid(tiles: Array(MetroSampleData.startTiles.prefix(6)))
        },
        MetroPanoramaSection(title: "recent") {
          VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(MetroSampleData.mailPreviews.prefix(5).enumerated()), id: \.offset) { index, item in
              MetroListRow(title: item.0, subtitle: item.1) {}
                .metroFeather(order: index)
            }
          }
        },
        MetroPanoramaSection(title: "what's new") {
          VStack(alignment: .leading, spacing: 12) {
            Text("drag sideways — three layers move at three rates")
              .metroText(.normal)
            Text("background · title · sections")
              .metroText(.small)
            MetroProgressBar()
          }
          .padding(.horizontal, theme.metrics.pageMargin)
        },
      ]
    )
  }
}

struct MetroPivotLab: View {
  var body: some View {
    MetroPivot(
      title: "metrokit",
      items: [
        MetroPivotItem(header: "inbox") {
          VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(MetroSampleData.mailPreviews.enumerated()), id: \.offset) { index, item in
              MetroListRow(title: item.0, subtitle: item.1, accessory: "now") {}
                .metroFeather(order: index)
            }
          }
        },
        MetroPivotItem(header: "unread") {
          VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(MetroSampleData.mailPreviews.prefix(3).enumerated()), id: \.offset) { index, item in
              MetroListRow(title: item.0, subtitle: item.2) {}
                .metroFeather(order: index)
            }
          }
        },
        MetroPivotItem(header: "flagged") {
          MetroListRow(title: "Nothing flagged", subtitle: "swipe back to the inbox")
        },
        MetroPivotItem(header: "urgent") {
          MetroListRow(title: "Nothing urgent", subtitle: "the header leads, the content follows")
        },
      ]
    )
  }
}

// MARK: - Shared bits

struct MetroChip: View {
  @Environment(\.metroTheme) private var theme

  let title: String
  let isSelected: Bool
  let action: () -> Void

  init(_ title: String, isSelected: Bool, action: @escaping () -> Void) {
    self.title = title
    self.isSelected = isSelected
    self.action = action
  }

  var body: some View {
    Text(title)
      .metroText(.small)
      .foregroundColor(isSelected ? theme.onAccent : theme.foreground)
      .padding(.horizontal, 12)
      .padding(.vertical, 7)
      .background(isSelected ? theme.accentColor : Color.clear)
      .overlay(Rectangle().strokeBorder(theme.border, lineWidth: isSelected ? 0 : 1))
      .contentShape(Rectangle())
      .metroTilt { action() }
  }
}
