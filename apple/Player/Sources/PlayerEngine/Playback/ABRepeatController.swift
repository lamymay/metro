import Combine
import Foundation

public enum ABRepeatMode: Int, Codable {
  case off = 0
  case settingA = 1
  case settingB = 2
  case repeatAB = 3
}

public final class ABRepeatController: ObservableObject {
  @Published public var pointA: Double?
  @Published public var pointB: Double?

  public init() {}

  // 通过时间点状态间接推断当前模式
  public var mode: ABRepeatMode {
    if pointA != nil, pointB != nil {
      return .repeatAB
    } else if pointA != nil {
      return .settingB
    } else {
      return .off
    }
  }

  public func set(mode: ABRepeatMode, pointA: Double?, pointB: Double?) {
    // 忽略传入的 mode 参数，直接通过设置 A/B 点来改变状态
    self.pointA = pointA
    self.pointB = pointB
  }

  private var lastSeekAt: Date = .distantPast

  private let minimumRange: Double = 0.25
  private let minimumSeekInterval: TimeInterval = 0.6

  public func cycle(currentTime: Double, duration: Double) {
    let t = max(0, currentTime)
    let d = max(0, duration)

    switch mode {
    case .off:
      // 当前是关闭的，点击后开始记录 A 点，进入设置 B 的阶段
      pointA = t
      pointB = nil

    case .settingA:
      // 实际上逻辑中不会主动进入此状态，但为了 switch 完备性处理
      pointA = t
      pointB = nil

    case .settingB:
      // 已经有 A 点了，点击后记录 B 点
      let a0 = pointA ?? t
      let b0 = t
      let a = min(a0, b0)
      var b = max(a0, b0)

      if b <= a + minimumRange {
        b = min(d > 0 ? d : b, a + 5.0)
      }

      pointA = a
      pointB = b

    case .repeatAB:
      // 已经在循环了，点击后清除所有点，回到关闭状态
      clear()
    }
  }

  public func clear() {
    pointA = nil
    pointB = nil
    lastSeekAt = .distantPast
  }

  public func seekTargetIfNeeded(currentTime: Double, duration: Double) -> Double? {
    guard mode == .repeatAB else { return nil }
    guard let a = pointA, let b = pointB else { return nil }
    guard b - a >= minimumRange else { return nil }
    guard currentTime >= b else { return nil }

    let now = Date()
    guard now.timeIntervalSince(lastSeekAt) >= minimumSeekInterval else { return nil }
    lastSeekAt = now

    return min(max(0, a), max(0, duration))
  }
}
