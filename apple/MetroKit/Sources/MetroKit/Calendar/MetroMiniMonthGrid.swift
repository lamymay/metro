import SwiftUI

/// One month's worth of tiny day cells — the building block of the year page. Each
/// cell is just a number and, if the day has activity, a hairline underline in the
/// accent (or subtle, if nothing about the day is worth calling out).
struct MetroMiniMonthGrid: View {
  static let baseCellWidth: CGFloat = 26
  static let baseCellHeight: CGFloat = 22
  static let columnCount: CGFloat = 7
  static let minimumGridWidth: CGFloat = baseCellWidth * columnCount
  static let cellAspectRatio: CGFloat = baseCellHeight / baseCellWidth

  let month: Int
  let yearDate: Date
  let dayStats: [Date: MetroCalendarDayStats]
  let monthWidth: CGFloat

  @Environment(\.metroTheme) private var theme
  private var calendar: Calendar { .current }

  var body: some View {
    let anchor =
      calendar.date(
        from: DateComponents(
          year: calendar.component(.year, from: yearDate), month: month, day: 1)
      ) ?? Date()
    let days = MetroCalendarDateHelper.daysInMonth(for: anchor)

    let cellWidth = max(18, floor(monthWidth / Self.columnCount))
    let cellHeight = max(18, floor(cellWidth * Self.cellAspectRatio))
    let columns = Array(
      repeating: GridItem(.fixed(cellWidth), spacing: 0), count: Int(Self.columnCount))

    LazyVGrid(columns: columns, spacing: 0) {
      ForEach(0..<days.count, id: \.self) { i in
        if let date = days[i] {
          let stats = dayStats[calendar.startOfDay(for: date)] ?? MetroCalendarDayStats()
          let hasActivity = stats.total > 0
          let hasHighlight = stats.highlighted > 0

          Text("\(calendar.component(.day, from: date))")
            .font(.system(size: 10, weight: hasActivity ? .semibold : .regular, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(dayInk(hasActivity: hasActivity, hasHighlight: hasHighlight))
            .frame(width: cellWidth, height: cellHeight, alignment: .center)
            .background(alignment: .bottom) {
              if hasActivity {
                Rectangle()
                  .fill(hasHighlight ? theme.accentColor.opacity(0.85) : theme.subtle.opacity(0.55))
                  .frame(height: 2)
              }
            }
            .overlay(Rectangle().stroke(theme.foreground.opacity(0.08), lineWidth: 0.5))
        } else {
          Color.clear
            .frame(width: cellWidth, height: cellHeight)
            .overlay(Rectangle().stroke(theme.foreground.opacity(0.05), lineWidth: 0.5))
        }
      }
    }
    .frame(width: cellWidth * Self.columnCount, alignment: .leading)
  }

  private func dayInk(hasActivity: Bool, hasHighlight: Bool) -> Color {
    if hasHighlight { return theme.accentColor }
    if hasActivity { return theme.foreground }
    return theme.subtle.opacity(0.6)
  }
}
