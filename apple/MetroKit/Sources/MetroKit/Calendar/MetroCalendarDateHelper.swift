import Foundation

/// Date arithmetic shared by the year and month grids. Not public — a host app hands
/// the calendar `Date`s and gets `Date`s back; it never needs to build a grid itself.
enum MetroCalendarDateHelper {
  static func monthName(_ month: Int) -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "MMMM"
    fmt.locale = Locale(identifier: "en_US")
    let date = Calendar.current.date(from: DateComponents(month: month)) ?? Date()
    return fmt.string(from: date).lowercased()
  }

  /// One month's grid cells, Monday-first, with leading `nil`s standing in for the
  /// days before the 1st that still need to occupy a column.
  static func daysInMonth(month: Int? = nil, for anchorDate: Date) -> [Date?] {
    let cal = Calendar.current
    var targetDate = anchorDate
    if let month {
      targetDate =
        cal.date(
          from: DateComponents(
            year: cal.component(.year, from: anchorDate), month: month, day: 1)
        ) ?? anchorDate
    }

    guard let monthInterval = cal.dateInterval(of: .month, for: targetDate),
      let totalDays = cal.range(of: .day, in: .month, for: targetDate)?.count
    else { return [] }

    let firstDay = monthInterval.start
    let weekday = cal.component(.weekday, from: firstDay)
    let offset = (weekday + 5) % 7  // Monday as the first column.

    var days: [Date?] = Array(repeating: nil, count: offset)
    for i in 0..<totalDays {
      days.append(cal.date(byAdding: .day, value: i, to: firstDay))
    }
    return days
  }
}
