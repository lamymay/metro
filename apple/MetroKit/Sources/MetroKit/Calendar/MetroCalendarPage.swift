import SwiftUI

/// WP's Calendar: an "agenda" pivot of upcoming events plus a bare month grid — no
/// photos, no colour beyond the accent dots marking a day that has something on it.
public struct MetroCalendarPage: View {
  @Environment(\.metroTheme) private var theme
  @State private var selectedDate: Date? = nil

  public init() {}

  public var body: some View {
    MetroPivot(
      title: "calendar",
      items: [
        MetroPivotItem(header: "agenda") { agendaTab },
        MetroPivotItem(header: "year") { yearTab },
      ]
    )
  }

  // MARK: Agenda

  private var agendaTab: some View {
    let byDay = Dictionary(grouping: MetroSampleData.events) { $0.day }
    let days = byDay.keys.sorted()

    return VStack(alignment: .leading, spacing: 0) {
      ForEach(Array(days.enumerated()), id: \.element) { index, day in
        Text(dayLabel(day))
          .metroText(.groupHeader)
          .padding(.horizontal, theme.metrics.pageMargin)
          .padding(.top, index == 0 ? 4 : 18)
          .padding(.bottom, 6)

        ForEach(byDay[day] ?? []) { event in
          HStack(spacing: 12) {
            Rectangle()
              .fill(event.accent.color)
              .frame(width: 4)
            VStack(alignment: .leading, spacing: 1) {
              Text(event.title).metroText(.title3)
              Text(event.end.isEmpty ? event.start : "\(event.start)–\(event.end)")
                .metroText(.small)
            }
            Spacer(minLength: 0)
          }
          .padding(.horizontal, theme.metrics.pageMargin)
          .padding(.vertical, 6)
        }
      }
      Spacer(minLength: 40)
    }
  }

  private func dayLabel(_ day: Int) -> String {
    if day == MetroSampleData.today { return "today" }
    if day == MetroSampleData.today + 1 { return "tomorrow" }
    return "\(MetroSampleData.currentMonth) \(day)"
  }

  // MARK: Year → Month

  /// The WP "zoom out to the year, tap a month to drill in" calendar, backed by the
  /// same fixture events as the agenda tab.
  private var yearTab: some View {
    MetroYearMonthCalendarView(
      selectedDate: $selectedDate,
      dayStats: sampleDayStats,
      dayDetail: { date in eventDetail(for: date) }
    )
  }

  private var sampleDayStats: [Date: MetroCalendarDayStats] {
    let calendar = Calendar.current
    let byDay = Dictionary(grouping: MetroSampleData.events) { $0.day }
    var result: [Date: MetroCalendarDayStats] = [:]
    for (day, events) in byDay {
      guard let date = calendar.date(bySetting: .day, value: day, of: Date()) else { continue }
      result[calendar.startOfDay(for: date)] = MetroCalendarDayStats(
        total: events.count,
        highlighted: events.count > 1 ? events.count : 0
      )
    }
    return result
  }

  @ViewBuilder
  private func eventDetail(for date: Date) -> some View {
    let day = Calendar.current.component(.day, from: date)
    let dayEvents = MetroSampleData.events.filter { $0.day == day }

    VStack(alignment: .leading, spacing: 8) {
      if dayEvents.isEmpty {
        Text("nothing on this day").metroText(.subtle)
      } else {
        ForEach(dayEvents) { event in
          HStack(spacing: 10) {
            Rectangle().fill(event.accent.color).frame(width: 4)
            VStack(alignment: .leading, spacing: 1) {
              Text(event.title).metroText(.title3)
              Text(event.end.isEmpty ? event.start : "\(event.start)–\(event.end)")
                .metroText(.small)
            }
            Spacer(minLength: 0)
          }
        }
      }
    }
    .padding(12)
    .background(theme.chrome.opacity(0.5))
  }
}
