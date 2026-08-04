import SwiftUI

/// The year page: twelve mini month grids, laid out to fill whatever width they're
/// given (one column on a phone, several on an iPad or a wide Mac window). Tapping a
/// month jumps into the month grid for it — the same "zoom out, tap to zoom in" idea
/// as the app list's semantic-zoom letter grid.
public struct MetroYearCalendarView: View {
  let displayYear: Date
  @Binding var currentMonth: Date
  @Binding var viewMode: MetroCalendarViewMode
  let dayStats: [Date: MetroCalendarDayStats]

  @Environment(\.metroTheme) private var theme

  public init(
    displayYear: Date,
    currentMonth: Binding<Date>,
    viewMode: Binding<MetroCalendarViewMode>,
    dayStats: [Date: MetroCalendarDayStats] = [:]
  ) {
    self.displayYear = displayYear
    self._currentMonth = currentMonth
    self._viewMode = viewMode
    self.dayStats = dayStats
  }

  public var body: some View {
    ScrollView(showsIndicators: false) {
      GeometryReader { proxy in
        let horizontalPadding: CGFloat = 16
        let columnSpacing: CGFloat = 8
        let availableWidth = max(0, proxy.size.width - horizontalPadding)
        let minBlockWidth = MetroMiniMonthGrid.minimumGridWidth
        let rawColumnCount = Int((availableWidth + columnSpacing) / (minBlockWidth + columnSpacing))
        let columnCount = max(1, rawColumnCount)
        let itemWidth = floor(
          (availableWidth - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount))
        let columns = Array(
          repeating: GridItem(
            .flexible(minimum: 0, maximum: .infinity), spacing: columnSpacing, alignment: .top),
          count: columnCount
        )

        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
          ForEach(1...12, id: \.self) { month in
            VStack(alignment: .leading, spacing: 4) {
              Text(MetroCalendarDateHelper.monthName(month))
                .metroText(.small)
                .frame(width: itemWidth, alignment: .leading)
                .frame(height: 18, alignment: .topLeading)

              MetroMiniMonthGrid(
                month: month,
                yearDate: displayYear,
                dayStats: dayStats,
                monthWidth: itemWidth
              )
            }
            .frame(width: itemWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { jump(to: month) }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 12)
      }
      .frame(minHeight: 720)
    }
  }

  private func jump(to month: Int) {
    guard
      let target = Calendar.current.date(
        from: DateComponents(
          year: Calendar.current.component(.year, from: displayYear), month: month, day: 1))
    else { return }
    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
      currentMonth = target
      viewMode = .month
    }
  }
}
