import SwiftUI

/// One day cell in the month grid: the day number, a hairline activity stripe on the
/// trailing edge, and — if the day has stats — a big ultralight number readout in the
/// WP type-ramp style. Selection is a soft accent wash rather than a filled circle, so
/// the underlying numbers stay legible.
public struct MetroCalendarDayCell: View {
  let date: Date
  let isSelected: Bool
  let stats: MetroCalendarDayStats

  @Environment(\.metroTheme) private var theme
  private var calendar: Calendar { .current }
  private var dayNumber: Int { calendar.component(.day, from: date) }
  private var hasActivity: Bool { stats.total > 0 }
  private var hasHighlight: Bool { stats.highlighted > 0 }
  private var hasAdded: Bool { stats.added > 0 }

  public init(date: Date, isSelected: Bool, stats: MetroCalendarDayStats) {
    self.date = date
    self.isSelected = isSelected
    self.stats = stats
  }

  public var body: some View {
    ZStack(alignment: .topLeading) {
      cellBackground

      if hasActivity {
        activityStripe
      }

      VStack(alignment: .leading, spacing: 0) {
        dayHeader
        Spacer(minLength: 0)
        if hasActivity {
          metricsBlock
        }
      }
      .padding(.horizontal, 9)
      .padding(.vertical, 8)
    }
    .frame(height: 88)
    .contentShape(Rectangle())
    .overlay(Rectangle().stroke(theme.foreground.opacity(0.1), lineWidth: 0.5))
    .scaleEffect(isSelected ? 1.015 : 1)
    .animation(.spring(response: 0.28, dampingFraction: 0.86), value: isSelected)
  }

  @ViewBuilder
  private var cellBackground: some View {
    if isSelected {
      theme.accentColor.opacity(0.16)
    } else {
      Color.clear
    }
  }

  private var activityStripe: some View {
    HStack(spacing: 0) {
      Spacer(minLength: 0)
      Rectangle()
        .fill(stripeColor)
        .frame(width: 3)
        .padding(.vertical, 6)
    }
  }

  private var dayHeader: some View {
    HStack(alignment: .firstTextBaseline, spacing: 5) {
      Text("\(dayNumber)")
        .font(.system(size: 15, weight: .light))
        .monospacedDigit()
        .foregroundStyle(dayInk)

      if hasActivity {
        Capsule(style: .continuous)
          .fill(stripeColor.opacity(isSelected ? 0.9 : 0.82))
          .frame(width: 14, height: 2)
          .offset(y: -1)
      }

      Spacer(minLength: 0)
    }
  }

  private var metricsBlock: some View {
    VStack(alignment: .leading, spacing: 4) {
      if hasAdded {
        Text("+\(stats.added)")
          .font(.system(size: 10, weight: .semibold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(theme.accentColor)
          .padding(.horizontal, 5)
          .padding(.vertical, 1)
          .background(
            Capsule(style: .continuous)
              .fill(theme.accentColor.opacity(isSelected ? 0.18 : 0.12))
          )
      }

      if hasHighlight {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
          Text("\(stats.highlighted)")
            .font(.system(size: 22, weight: .ultraLight, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(theme.accentColor.opacity(isSelected ? 1 : 0.92))
            .lineLimit(1)
            .minimumScaleFactor(0.7)

          Text("/\(stats.total)")
            .font(.system(size: 11, weight: .regular, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(theme.subtle)
            .lineLimit(1)
        }
      } else {
        Text("\(stats.total)")
          .font(.system(size: 20, weight: .ultraLight, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(dayInk)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var stripeColor: Color {
    if isSelected { return theme.accentColor }
    if hasHighlight { return theme.accentColor.opacity(0.88) }
    return theme.subtle.opacity(0.7)
  }

  private var dayInk: Color {
    if isSelected { return theme.accentColor }
    if hasActivity { return theme.foreground }
    return theme.subtle.opacity(0.5)
  }
}
