import SwiftUI

public struct SettingsView: View {
  @EnvironmentObject private var theme: ThemeManager
  @AppStorage("playback.seekInterval") private var seekInterval: Double = 5.0

  private let columns = [
    GridItem(.adaptive(minimum: 72), spacing: 14)
  ]

  public init() {}

  public var body: some View {
    ZStack {
      Color.systemBackground.ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          // MARK: - 播放设置
          Text("播放")
            .font(.title3.bold())
            .foregroundColor(.primary)

          HStack {
            Text("快进/快退间隔")
            Spacer()
            Stepper(value: $seekInterval, in: 1...60, step: 1) {
              Text("\(Int(seekInterval)) 秒")
                .monospacedDigit()
            }
          }
          .padding()
          .background(Color.secondarySystemBackground)
          .clipShape(RoundedRectangle(cornerRadius: 12))

          Divider().padding(.vertical, 8)

          // MARK: - 外观设置
          Text("外观")
            .font(.title3.bold())
            .foregroundColor(.primary)

          Picker(
            "外观",
            selection: Binding(
              get: { theme.appearanceSelection }, set: { theme.appearanceSelection = $0 })
          ) {
            ForEach(AppAppearance.allCases) { option in
              Text(option.title).tag(option)
            }
          }
          .pickerStyle(.segmented)
          .tint(theme.primary)

          Text("主体颜色")
            .font(.title3.bold())
            .foregroundColor(.primary)

          LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
            ForEach(ThemeColor.allCases) { option in
              Button(action: { theme.primarySelection = option }) {
                VStack(spacing: 10) {
                  ZStack {
                    Circle()
                      .fill(option.color)
                      .frame(width: 42, height: 42)

                    if theme.primarySelection == option {
                      Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 3)
                        .frame(width: 52, height: 52)
                    } else {
                      Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        .frame(width: 52, height: 52)
                    }
                  }

                  Text(option.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.secondarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(16)
      }
    }
    .navigationTitle("设置")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}
