import Foundation

/// Per-day activity summary for the calendar's heatmap cells. Deliberately generic —
/// "highlighted" and "added" carry no domain meaning here; a host app maps its own
/// data (words due for review, tasks completed, whatever) onto these three counts.
public struct MetroCalendarDayStats: Equatable, Sendable {
  /// Everything that happened on this day.
  public var total: Int
  /// The subset worth calling out with the accent colour (e.g. "needs attention").
  public var highlighted: Int
  /// The subset worth a small "+N" badge (e.g. "new").
  public var added: Int

  public init(total: Int = 0, highlighted: Int = 0, added: Int = 0) {
    self.total = total
    self.highlighted = highlighted
    self.added = added
  }

  public var isEmpty: Bool { total == 0 }
}

/// Which of the calendar's two zoom levels is showing.
public enum MetroCalendarViewMode: Sendable {
  case year
  case month
}
