import SwiftUI

/// The WP year → month calendar. A year page of twelve mini grids and a month page
/// reached by tapping one of them, swapped in place with a scale/opacity cross-fade —
/// the same "zoom" pattern as the app list's semantic zoom, not a pushed screen.
///
/// The header mirrors WP's own calendar: the year sits above a horizontally-scrolling
/// row of oversized month names, the current month picked out in full contrast and
/// everything else dimmed to `subtle`. Tapping the year returns to the year page;
/// tapping a month name jumps straight to it.
public struct MetroYearMonthCalendarView<DayDetail: View>: View {
  @State private var viewMode: MetroCalendarViewMode
  @State private var displayMonth: Date
  @Binding var selectedDate: Date?

  let dayStats: [Date: MetroCalendarDayStats]
  let dayDetail: (Date) -> DayDetail

  @Environment(\.metroTheme) private var theme
  private var calendar: Calendar { .current }

  public init(
    initialDate: Date = Date(),
    selectedDate: Binding<Date?> = .constant(nil),
    dayStats: [Date: MetroCalendarDayStats] = [:],
    @ViewBuilder dayDetail: @escaping (Date) -> DayDetail = { _ in EmptyView() }
  ) {
    self._viewMode = State(initialValue: .year)
    self._displayMonth = State(initialValue: initialDate)
    self._selectedDate = selectedDate
    self.dayStats = dayStats
    self.dayDetail = dayDetail
  }

  public var body: some View {
    VStack(spacing: 0) {
      header
      Divider().opacity(0.15)

      Group {
        if viewMode == .year {
          MetroYearCalendarView(
            displayYear: displayMonth,
            currentMonth: $displayMonth,
            viewMode: $viewMode,
            dayStats: dayStats
          )
          .transition(.opacity.combined(with: .scale(scale: 1.03)))
        } else {
          ScrollView {
            VStack(spacing: 0) {
              MetroMonthCalendarView(
                displayMonth: displayMonth, selectedDate: $selectedDate, dayStats: dayStats)

              if let selectedDate {
                dayDetail(selectedDate)
                  .padding(.horizontal, 14)
                  .padding(.top, 12)
                  .padding(.bottom, 16)
                  .transition(.move(edge: .top).combined(with: .opacity))
              }
            }
          }
          .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
      }
      .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewMode)
      .animation(.spring(response: 0.35, dampingFraction: 0.86), value: selectedDate)
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: -15) {
      Text(String(calendar.component(.year, from: displayMonth)))
        .font(.system(size: 24, weight: .light))
        .foregroundStyle(viewMode == .year ? theme.foreground : theme.subtle)
        .padding(.horizontal, 25)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.001))  // keeps the whole label hit-testable
        .onTapGesture {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { viewMode = .year }
        }
        .zIndex(10)

      ScrollViewReader { proxy in
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(alignment: .firstTextBaseline, spacing: 30) {
            ForEach(1...12, id: \.self) { m in
              Text(MetroCalendarDateHelper.monthName(m))
                .font(.system(size: 60, weight: .ultraLight, design: .rounded))
                .foregroundStyle(isCurrent(m) ? theme.foreground : theme.subtle.opacity(0.32))
                .id(m)
                .onTapGesture {
                  jump(to: m)
                  withAnimation { viewMode = .month }
                }
            }
          }
          .padding(.horizontal, 25)
        }
        .onChange(of: displayMonth) { newMonth in
          proxy.scrollTo(calendar.component(.month, from: newMonth), anchor: .leading)
        }
      }
    }
    .padding(.top, 20)
  }

  private func isCurrent(_ m: Int) -> Bool {
    calendar.component(.month, from: displayMonth) == m && viewMode == .month
  }

  private func jump(to m: Int) {
    guard
      let d = calendar.date(
        from: DateComponents(year: calendar.component(.year, from: displayMonth), month: m, day: 1))
    else { return }
    displayMonth = d
  }
}
