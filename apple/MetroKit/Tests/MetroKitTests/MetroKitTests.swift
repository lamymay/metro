import XCTest
import SwiftUI
@testable import MetroKit

final class MetroEaseTests: XCTestCase {
  func testEndpointsAreExact() {
    for kind in [MetroEase.Kind.linear, .exponential(exponent: 6), .power(exponent: 3), .circle, .sine] {
      for mode in MetroEase.Mode.allCases {
        let ease = MetroEase(kind, mode)
        XCTAssertEqual(ease.progress(0), 0, accuracy: 1e-9, "\(ease.displayName) at 0")
        XCTAssertEqual(ease.progress(1), 1, accuracy: 1e-9, "\(ease.displayName) at 1")
      }
    }
  }

  func testProgressIsClampedOutsideUnitInterval() {
    let ease = MetroEase.wpIn
    XCTAssertEqual(ease.progress(-3), 0, accuracy: 1e-9)
    XCTAssertEqual(ease.progress(9), 1, accuracy: 1e-9)
  }

  func testExponentialEaseOutIsFrontLoaded() {
    // The WP arrival curve covers most of its distance in the first tenth of its
    // duration; that is what makes a turnstile feel like it snaps into place.
    XCTAssertGreaterThan(MetroEase.wpIn.progress(0.1), 0.4)
    XCTAssertGreaterThan(MetroEase.wpIn.progress(0.5), 0.9)
  }

  func testEaseOutIsTheMirrorOfEaseIn() {
    let easeIn = MetroEase(.exponential(exponent: 6), .easeIn)
    let easeOut = MetroEase(.exponential(exponent: 6), .easeOut)
    for step in 0...10 {
      let t = Double(step) / 10
      XCTAssertEqual(easeOut.progress(t), 1 - easeIn.progress(1 - t), accuracy: 1e-9)
    }
  }

  func testMonotonic() {
    let ease = MetroEase(.exponential(exponent: 6), .easeInOut)
    var previous = -1.0
    for step in 0...100 {
      let value = ease.progress(Double(step) / 100)
      XCTAssertGreaterThanOrEqual(value, previous)
      previous = value
    }
  }

  func testZeroExponentDegradesToLinear() {
    let ease = MetroEase(.exponential(exponent: 0), .easeIn)
    XCTAssertEqual(ease.progress(0.37), 0.37, accuracy: 1e-9)
  }
}

final class MetroTiltTests: XCTestCase {
  func testCentrePressDoesNotRotate() {
    let state = MetroTiltState(normalized: CGPoint(x: 0, y: 0))
    XCTAssertEqual(state.rotationX(maxAngle: 0.3), 0, accuracy: 1e-9)
    XCTAssertEqual(state.rotationY(maxAngle: 0.3), 0, accuracy: 1e-9)
  }

  func testCentrePressDepressesTheMost() {
    let centre = MetroTiltState(normalized: CGPoint(x: 0, y: 0))
    let corner = MetroTiltState(normalized: CGPoint(x: 0.5, y: 0.5))
    XCTAssertEqual(centre.scale(maxDepression: 0.06), 0.94, accuracy: 1e-9)
    XCTAssertEqual(corner.scale(maxDepression: 0.06), 1.0, accuracy: 1e-9)
  }

  func testCornerPressReachesMaxAngle() {
    let corner = MetroTiltState(normalized: CGPoint(x: 0.5, y: 0.5))
    let total = abs(corner.rotationX(maxAngle: 0.3)) + abs(corner.rotationY(maxAngle: 0.3))
    XCTAssertEqual(total, 0.3 * 180 / .pi, accuracy: 1e-6)
  }

  func testPressingTheRightEdgePushesItAway() {
    // Positive rotation about SwiftUI's y axis sends +x away from the viewer.
    let right = MetroTiltState(normalized: CGPoint(x: 0.5, y: 0))
    XCTAssertGreaterThan(right.rotationY(maxAngle: 0.3), 0)
    XCTAssertEqual(right.rotationX(maxAngle: 0.3), 0, accuracy: 1e-9)
  }

  func testPressingTheBottomEdgePushesItAway() {
    // Negative rotation about the x axis sends +y (down the screen) away.
    let bottom = MetroTiltState(normalized: CGPoint(x: 0, y: 0.5))
    XCTAssertLessThan(bottom.rotationX(maxAngle: 0.3), 0)
    XCTAssertEqual(bottom.rotationY(maxAngle: 0.3), 0, accuracy: 1e-9)
  }

  func testReleasedStateIsIdentity() {
    let released = MetroTiltState()
    XCTAssertFalse(released.isPressed)
    XCTAssertEqual(released.scale(maxDepression: 0.2), 1, accuracy: 1e-9)
  }
}

final class MetroTilePackerTests: XCTestCase {
  private func tile(_ id: String, _ size: MetroTileSize) -> MetroTileModel {
    MetroTileModel(id: id, title: id, glyph: .mail, size: size)
  }

  func testMediumTilesPairUpOnAFourColumnGrid() {
    let packed = MetroTilePacker.pack([tile("a", .medium), tile("b", .medium)], columns: 4)
    XCTAssertEqual(packed.rows, 2)
    XCTAssertEqual(packed.placements.map(\.column), [0, 2])
    XCTAssertEqual(packed.placements.map(\.row), [0, 0])
  }

  func testSmallTilesBackfillTheHoleLeftByAWideTile() {
    // wide takes the whole first band; the two smalls then land on the next row.
    let packed = MetroTilePacker.pack(
      [tile("wide", .wide), tile("s1", .small), tile("s2", .small)],
      columns: 4
    )
    let byID = Dictionary(uniqueKeysWithValues: packed.placements.map { ($0.id, $0) })
    XCTAssertEqual(byID["wide"]?.row, 0)
    XCTAssertEqual(byID["s1"]?.row, 2)
    XCTAssertEqual(byID["s1"]?.column, 0)
    XCTAssertEqual(byID["s2"]?.column, 1)
  }

  func testFirstFitDropsALaterSmallTileIntoAnEarlierGap() {
    // small, medium, small: the medium cannot fit beside the first small on a
    // 4-column grid without leaving a 1-wide gap, and the third tile fills it.
    let packed = MetroTilePacker.pack(
      [tile("s1", .small), tile("m", .medium), tile("s2", .small)],
      columns: 4
    )
    let byID = Dictionary(uniqueKeysWithValues: packed.placements.map { ($0.id, $0) })
    XCTAssertEqual(byID["s1"]?.column, 0)
    XCTAssertEqual(byID["m"]?.column, 1)
    XCTAssertEqual(byID["s2"]?.column, 3)
    XCTAssertEqual(byID["s2"]?.row, 0)
  }

  func testWideTileIsClampedToNarrowGrids() {
    let packed = MetroTilePacker.pack([tile("wide", .wide)], columns: 2)
    XCTAssertEqual(packed.placements.first?.column, 0)
    XCTAssertEqual(packed.rows, 2)
  }

  func testOrderIsRenumberedIntoReadingOrder() {
    let packed = MetroTilePacker.pack(
      [tile("wide", .wide), tile("s1", .small), tile("s2", .small)],
      columns: 4
    )
    let byID = Dictionary(uniqueKeysWithValues: packed.placements.map { ($0.id, $0.order) })
    XCTAssertEqual(byID["wide"], 0)
    XCTAssertEqual(byID["s1"], 1)
    XCTAssertEqual(byID["s2"], 2)
  }

  func testEmptyInput() {
    let packed = MetroTilePacker.pack([], columns: 4)
    XCTAssertTrue(packed.placements.isEmpty)
    XCTAssertEqual(packed.rows, 0)
  }
}

final class MetroMetricsTests: XCTestCase {
  func testUnitSolvesForTheGapsAndMargins() {
    let metrics = MetroMetrics(columns: 4, gap: 12, leadingMargin: 12, trailingGutter: 0)
    let unit = metrics.unit(forWidth: 390)
    // 12 margin + 4u + 3×12 gap = 390
    XCTAssertEqual(unit * 4 + 36 + 12, 390, accuracy: 1e-6)
  }

  func testSpanIncludesInteriorGaps() {
    let metrics = MetroMetrics(gap: 12)
    XCTAssertEqual(metrics.span(2, unit: 70), 152)
    XCTAssertEqual(metrics.span(4, unit: 70), 316)
  }

  func testNarrowContainersStillProduceAUsableUnit() {
    let metrics = MetroMetrics(columns: 6, gap: 12, leadingMargin: 12)
    XCTAssertGreaterThanOrEqual(metrics.unit(forWidth: 40), 24)
  }
}

final class MetroThemeTests: XCTestCase {
  func testAllTwentyAccentsAreDistinct() {
    let hexes = Set(MetroAccent.allCases.map(\.hex))
    XCTAssertEqual(MetroAccent.allCases.count, 20)
    XCTAssertEqual(hexes.count, 20)
  }

  func testShippingAccentValues() {
    XCTAssertEqual(MetroAccent.cobalt.hex, 0x0050EF)
    XCTAssertEqual(MetroAccent.lime.hex, 0xA4C400)
    XCTAssertEqual(MetroAccent.magenta.hex, 0xD80073)
  }

  func testTypeRampScalesTheWPPixelValues() {
    let ramp = MetroTypeRamp(scale: 0.8)
    XCTAssertEqual(ramp.size(.normal), (20 * 0.8).rounded())
    XCTAssertEqual(ramp.size(.applicationTitle), (18.667 * 0.8).rounded())
  }

  func testMotionSpeedScalesDurationsAndFeather() {
    var config = MetroMotionConfig()
    config.speed = 2
    XCTAssertEqual(config.duration(0.5), 0.25, accuracy: 1e-9)
    XCTAssertEqual(config.featherDelay(forIndex: 4), 4 * 0.05 / 2, accuracy: 1e-9)
  }

  func testFeatherDelayIsCappedSoLongListsStillFinish() {
    let config = MetroMotionConfig()
    XCTAssertEqual(
      config.featherDelay(forIndex: 500),
      config.featherDelay(forIndex: config.featherMaxSteps),
      accuracy: 1e-9
    )
  }
}
