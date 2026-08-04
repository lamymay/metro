import SwiftUI

/// Where one tile ended up, in small-tile units.
public struct MetroTilePlacement: Identifiable, Equatable, Sendable {
  public var model: MetroTileModel
  public var column: Int
  public var row: Int
  /// Position in reading order, which is the order the feather uses.
  public var order: Int

  public var id: String { model.id }
}

/// First-fit packer, which is how the WP start screen actually behaved: a tile drops
/// into the first hole big enough for it, scanning left-to-right then down. That is why
/// a wide tile could leave a pair of small holes above it that later small tiles filled.
public enum MetroTilePacker {
  public static func pack(_ tiles: [MetroTileModel], columns: Int) -> (placements: [MetroTilePlacement], rows: Int) {
    guard columns > 0 else { return ([], 0) }
    var occupied: [[Bool]] = []
    var placements: [MetroTilePlacement] = []

    func ensureRows(_ count: Int) {
      while occupied.count < count {
        occupied.append(Array(repeating: false, count: columns))
      }
    }

    func fits(row: Int, column: Int, width: Int, height: Int) -> Bool {
      guard column + width <= columns else { return false }
      ensureRows(row + height)
      for r in row..<(row + height) {
        for c in column..<(column + width) where occupied[r][c] {
          return false
        }
      }
      return true
    }

    for (index, tile) in tiles.enumerated() {
      let w = min(tile.size.columns, columns)
      let h = tile.size.rows
      var placed = false
      var row = 0

      while !placed {
        ensureRows(row + h)
        for column in 0...(columns - w) where fits(row: row, column: column, width: w, height: h) {
          for r in row..<(row + h) {
            for c in column..<(column + w) { occupied[r][c] = true }
          }
          placements.append(
            MetroTilePlacement(model: tile, column: column, row: row, order: index)
          )
          placed = true
          break
        }
        if !placed { row += 1 }
      }
    }

    // Renumber into reading order so the feather runs top-left to bottom-right rather
    // than in whatever order the caller happened to supply.
    let sorted = placements.sorted { ($0.row, $0.column) < ($1.row, $1.column) }
    var byID: [String: Int] = [:]
    for (i, p) in sorted.enumerated() { byID[p.id] = i }
    let renumbered = placements.map { p -> MetroTilePlacement in
      var copy = p
      copy.order = byID[p.id] ?? p.order
      return copy
    }

    let usedRows = occupied.enumerated().reduce(0) { acc, entry in
      entry.element.contains(true) ? entry.offset + 1 : acc
    }
    return (renumbered, usedRows)
  }
}

/// The WP start screen: a packed tile grid that swings in on appear.
public struct MetroTileGrid: View {
  @Environment(\.metroTheme) private var theme

  public var tiles: [MetroTileModel]
  /// Bump to replay the entrance.
  public var cascadeToken: Int
  public var onSelect: ((MetroTileModel) -> Void)?

  public init(
    tiles: [MetroTileModel],
    cascadeToken: Int = 0,
    onSelect: ((MetroTileModel) -> Void)? = nil
  ) {
    self.tiles = tiles
    self.cascadeToken = cascadeToken
    self.onSelect = onSelect
  }

  public var body: some View {
    GeometryReader { proxy in
      let metrics = theme.metrics
      let unit = metrics.unit(forWidth: proxy.size.width)
      let packed = MetroTilePacker.pack(tiles, columns: metrics.columns)
      let step = unit + metrics.gap

      ZStack(alignment: .topLeading) {
        ForEach(packed.placements) { placement in
          MetroTile(
            model: placement.model,
            unit: unit,
            gap: metrics.gap,
            onSelect: onSelect
          )
          .metroFeather(order: placement.order)
          .offset(
            x: metrics.leadingMargin + CGFloat(placement.column) * step,
            y: CGFloat(placement.row) * step
          )
        }
      }
      .frame(width: proxy.size.width, alignment: .topLeading)
      .id(cascadeToken)
    }
    .frame(height: gridHeight)
  }

  /// The grid has to report an intrinsic height so it can live inside a `ScrollView`,
  /// and that height only depends on the packing, not on the measured width.
  private var gridHeight: CGFloat {
    let metrics = theme.metrics
    let rows = MetroTilePacker.pack(tiles, columns: metrics.columns).rows
    // Resolved against the nominal unit; the GeometryReader corrects the real layout.
    let unit = metrics.unit(forWidth: nominalWidth)
    return CGFloat(rows) * unit + CGFloat(max(rows - 1, 0)) * metrics.gap
  }

  @Environment(\.metroContainerWidth) private var nominalWidth
}

// MARK: - Container width

/// `MetroTileGrid` needs its own width before layout in order to report a height. The
/// page chrome publishes it here rather than the grid guessing.
private struct MetroContainerWidthKey: EnvironmentKey {
  static let defaultValue: CGFloat = 390
}

extension EnvironmentValues {
  public var metroContainerWidth: CGFloat {
    get { self[MetroContainerWidthKey.self] }
    set { self[MetroContainerWidthKey.self] = newValue }
  }
}

extension View {
  /// Publishes the usable width so height-reporting children (the tile grid) can size
  /// themselves. Apply it once, high up.
  public func metroContainerWidth(_ width: CGFloat) -> some View {
    environment(\.metroContainerWidth, width)
  }
}
