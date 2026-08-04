import SwiftUI

/// A single month, full-size: weekday header plus a 7-column grid of
/// ``MetroCalendarDayCell``. Tapping a day toggles `selectedDate`; the host decides
/// what (if anything) to show for the selection.
public struct MetroMonthCalendarView: View {
  let displayMonth: Date
  @Binding var selectedDate: Date?
  let dayStats: [Date: MetroCalendarDayStats]

  @Environment(\.metroTheme) private var theme
  private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

  public init(
    displayMonth: Date,
    selectedDate: Binding<Date?>,
    dayStats: [Date: MetroCalendarDayStats] = [:]
  ) {
    self.displayMonth = displayMonth
    self._selectedDate = selectedDate
    self.dayStats = dayStats
  }

  public var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        ForEach(["mon", "tue", "wed", "thu", "fri", "sat", "sun"], id: \.self) { d in
          Text(d)
            .metroText(.small)
            .frame(maxWidth: .infinity)
        }
      }
      .padding(.bottom, 10)

      Rectangle().frame(height: 0.5).foregroundColor(theme.foreground.opacity(0.15))

      let days = MetroCalendarDateHelper.daysInMonth(for: displayMonth)
      LazyVGrid(columns: columns, spacing: 0) {
        ForEach(Array(days.enumerated()), id: \.offset) { _, date in
          if let date {
            let dayKey = Calendar.current.startOfDay(for: date)
            MetroCalendarDayCell(
              date: date,
              isSelected: isSelected(date),
              stats: dayStats[dayKey] ?? MetroCalendarDayStats()
            )
            .onTapGesture {
              withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                selectedDate = isSelected(date) ? nil : date
              }
            }
          } else {
            Color.clear.frame(height: 88)
          }
        }
      }
    }
    .padding(.horizontal, 10)
  }

  private func isSelected(_ d: Date) -> Bool {
    selectedDate.map { Calendar.current.isDate($0, inSameDayAs: d) } ?? false
  }
}
