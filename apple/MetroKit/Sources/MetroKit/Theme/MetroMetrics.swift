import SwiftUI

/// Layout constants. Everything on a WP start screen derives from one number — the
/// side of a *small* tile — so this type only stores the gap and the column count and
/// solves for the unit against whatever width it is given. That is what keeps the grid
/// honest on a 390pt iPhone, a 1024pt iPad and a resizable Mac window.
public struct MetroMetrics: Sendable {
  /// Number of small-tile columns. WP shipped 4 on WVGA and 6 on 720p "more tiles".
  public var columns: Int
  /// Gap between tiles. WP used 12 WVGA px; scaled here the same way type is.
  public var gap: CGFloat
  /// Left gutter before the first tile.
  public var leadingMargin: CGFloat
  /// WP left a dead zone on the right of the WVGA start screen. Set to 0 for a
  /// full-bleed grid.
  public var trailingGutter: CGFloat
  /// Page content gutter, outside the start screen.
  public var pageMargin: CGFloat
  /// App bar height when collapsed to its icon row.
  public var appBarHeight: CGFloat

  public init(
    columns: Int = 4,
    // WP packed tiles far tighter than a typical iOS grid — reference hardware photos
    // show barely any daylight between tiles, closer to a hairline than a real gutter.
    gap: CGFloat = 5,
    leadingMargin: CGFloat = 5,
    trailingGutter: CGFloat = 5,
    pageMargin: CGFloat = 20,
    appBarHeight: CGFloat = 72
  ) {
    self.columns = columns
    self.gap = gap
    self.leadingMargin = leadingMargin
    self.trailingGutter = trailingGutter
    self.pageMargin = pageMargin
    self.appBarHeight = appBarHeight
  }

  /// Side of one small tile for a container of the given width.
  public func unit(forWidth width: CGFloat) -> CGFloat {
    let usable = width - leadingMargin - trailingGutter - gap * CGFloat(columns - 1)
    return max(24, usable / CGFloat(columns))
  }

  /// Width occupied by `span` small columns, including the gaps between them.
  public func span(_ span: Int, unit: CGFloat) -> CGFloat {
    CGFloat(span) * unit + CGFloat(span - 1) * gap
  }
}
