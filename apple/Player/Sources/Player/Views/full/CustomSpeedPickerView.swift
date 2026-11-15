import SwiftUI

#if os(iOS)
  import UIKit
#endif

// MARK: - MX 风格：刻度尺 + 中心指示线 + 预设按钮
public struct CustomSpeedPickerView: View {
  @Binding var speed: Double
  @Environment(\.dismiss) var dismiss

  private let minSpeed: Double = 0.5
  private let maxSpeed: Double = 3.5
  private let step: Double = 0.1
  private let quickSpeeds: [Double] = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5]

  public init(speed: Binding<Double>) {
    self._speed = speed
  }

  public var body: some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(Color.white.opacity(0.06))
        .frame(height: 1)

      Spacer(minLength: 18)

      Text(String(format: "%.1f 倍速", normalizedSpeed(speed)))
        .font(.system(size: 44, weight: .black, design: .rounded))
        .foregroundColor(.white)
        .padding(.bottom, 14)

      SpeedRuler(
        speed: Binding(
          get: { normalizedSpeed(speed) },
          set: { speed = $0 }
        ),
        minSpeed: minSpeed,
        maxSpeed: maxSpeed,
        step: step
      )
      .padding(.top, 2)
      .padding(.horizontal, 18)
      .padding(.bottom, 22)

      presetRow
        .padding(.horizontal, 18)
        .padding(.bottom, 26)

      Spacer(minLength: 0)
    }
    .background(Color.black.opacity(0.92))
    .preferredColorScheme(.dark)
    .onAppear { speed = normalizedSpeed(speed) }
    .onChange(of: speed) {
      speed = normalizedSpeed(speed)
    }
  }

  private var presetRow: some View {
    HStack(spacing: 14) {
      ForEach(quickSpeeds, id: \.self) { s in
        let selected = abs(normalizedSpeed(speed) - s) < 0.0001
        Button(action: {
          withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
            speed = s
          }
          HapticHelper.trigger(.medium)
        }) {
          Text(s == 1.0 ? "1" : String(format: "%.1f", s))
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(Color.white.opacity(selected ? 0.22 : 0.12))
            .overlay(
              Circle()
                .stroke(Color.green.opacity(selected ? 1.0 : 0.0), lineWidth: 2)
            )
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
      }
    }
  }

  private func normalizedSpeed(_ raw: Double) -> Double {
    let clamped = min(maxSpeed, max(minSpeed, raw))
    let steps = (clamped - minSpeed) / step
    let snapped = (round(steps) * step) + minSpeed
    return (snapped * 10).rounded() / 10
  }
}

private struct SpeedRuler: View {
  @Binding var speed: Double
  let minSpeed: Double
  let maxSpeed: Double
  let step: Double

  private let tickSpacing: CGFloat = 30

  @State private var dragStartSpeed: Double = 1.0
  @State private var lastHapticIndex: Int = -1
  @State private var isDragging = false

  private var values: [Double] {
    Array(stride(from: minSpeed, through: maxSpeed, by: step)).map {
      (round($0 * 10) / 10.0)
    }
  }

  var body: some View {
    GeometryReader { geo in
      let width = geo.size.width
      let centerX = width / 2

      ZStack {
        Canvas { context, size in
          let visibleMinX: CGFloat = -40
          let visibleMaxX: CGFloat = size.width + 40

          for v in values {
            let dx = CGFloat((v - speed) / step) * tickSpacing
            let x = centerX + dx
            if x < visibleMinX || x > visibleMaxX { continue }

            let major = isMajor(v)
            let tickH: CGFloat = major ? 34 : 22
            let tickTopY: CGFloat = 18
            let tickBottomY: CGFloat = tickTopY + tickH

            var tick = Path()
            tick.move(to: CGPoint(x: x, y: tickTopY))
            tick.addLine(to: CGPoint(x: x, y: tickBottomY))
            context.stroke(
              tick,
              with: .color(.white.opacity(0.32)),
              style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )

            if major {
              let text = Text(String(format: "%.1f", v))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(abs(v - speed) < 0.0001 ? .white : Color.white.opacity(0.35))

              context.draw(text, at: CGPoint(x: x, y: 72), anchor: .top)
            }
          }
        }
        .animation(
          isDragging ? nil : .interactiveSpring(response: 0.22, dampingFraction: 0.9),
          value: speed
        )

        VStack(spacing: 0) {
          Image(systemName: "arrowtriangle.down.fill")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.green)
            .padding(.bottom, 4)

          Rectangle()
            .fill(Color.green)
            .frame(width: 3, height: 38)
            .cornerRadius(1.5)
        }
        .offset(y: -6)
      }
      .frame(width: width, height: geo.size.height)
      .contentShape(Rectangle())
      .onTapGesture { location in
        isDragging = false
        let deltaSteps = Double((location.x - centerX) / tickSpacing)
        let newSpeed = snap(speed + deltaSteps * step)
        if abs(newSpeed - speed) > 0.0001 {
          speed = newSpeed
          HapticHelper.selectionChanged()
        }
      }
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if !isDragging {
              isDragging = true
              dragStartSpeed = speed
              lastHapticIndex = indexForSpeed(speed)
            }

            let deltaSteps = -Double(value.translation.width / tickSpacing)
            let snapped = snap(dragStartSpeed + deltaSteps * step)
            speed = snapped

            let i = indexForSpeed(snapped)
            if i != lastHapticIndex {
              lastHapticIndex = i
              HapticHelper.selectionChanged()
            }
          }
          .onEnded { _ in
            isDragging = false
            withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
              speed = snap(speed)
            }
          }
      )
    }
    .frame(height: 110)
    .clipped()
  }

  private func isMajor(_ v: Double) -> Bool {
    let n = Int(round(v * 10))
    return n % 5 == 0  // 0.5
  }

  private func indexForSpeed(_ v: Double) -> Int {
    Int(round((v - minSpeed) / step))
  }

  private func snap(_ raw: Double) -> Double {
    let clamped = min(maxSpeed, max(minSpeed, raw))
    let steps = (clamped - minSpeed) / step
    let snapped = (round(steps) * step) + minSpeed
    return (snapped * 10).rounded() / 10
  }
}
