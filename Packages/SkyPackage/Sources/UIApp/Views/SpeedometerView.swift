import SwiftUI

struct SpeedometerView: View {
  let minValue: Double
  let maxValue: Double
  let value1: Double
  let value2: Double
  let unit: String

  private let startAngle: Angle = .degrees(90)
  private let endAngle: Angle = .degrees(270)

  var body: some View {
    GeometryReader { geometry in
      let size = geometry.size.height
      let radius = size / 2
      let center = CGPoint(
        x: geometry.size.width / 2,
        y: geometry.size.height / 2
      )

      ZStack {
        tickMarks(center: center, radius: radius)
        //        labels(center: center, radius: radius)
        //        unitLabel(center: center, radius: radius)
        needle(
          center: center,
          radius: radius,
          value: value1,
          color: .white.opacity(0.9)
        )
        needle(
          center: center,
          radius: radius,
          value: value2,
          color: .white.opacity(0.7)
        )
      }.offset(x: 60)
    }
    //    .aspectRatio(2, contentMode: .fit)
  }

  private func tickMarks(center: CGPoint, radius: CGFloat) -> some View {
    let totalAngle = endAngle.degrees - startAngle.degrees
    let majorTickCount = 10
    let minorTicksPerMajor = 5

    return ZStack {
      ForEach(0..<(majorTickCount * minorTicksPerMajor), id: \.self) { index in
        let isMajor = index % minorTicksPerMajor == 0
        let progress = Double(index) / Double(majorTickCount * minorTicksPerMajor - 1)
        let angle = startAngle.degrees + totalAngle * progress

        tick(
          center: center,
          radius: radius,
          angle: angle,
          length: isMajor ? 8 : 0,
          width: isMajor ? 2 : 0
        )
      }
    }
  }

  private func tick(
    center: CGPoint,
    radius: CGFloat,
    angle: Double,
    length: CGFloat,
    width: CGFloat
  ) -> some View {
    let angleRad = angle * .pi / 180
    let startRadius = radius * 0.85
    let endRadius = startRadius - length

    let startX = center.x + cos(angleRad) * startRadius
    let startY = center.y + sin(angleRad) * startRadius
    let endX = center.x + cos(angleRad) * endRadius
    let endY = center.y + sin(angleRad) * endRadius

    return Path { path in
      path.move(to: CGPoint(x: startX, y: startY))
      path.addLine(to: CGPoint(x: endX, y: endY))
    }
    .stroke(Color.primary.opacity(0.6), lineWidth: width)
  }

  private func labels(center: CGPoint, radius: CGFloat) -> some View {
    let totalAngle = endAngle.degrees - startAngle.degrees
    let majorTickCount = 10
    let labelRadius = radius * 0.65

    return ZStack {
      ForEach(0..<majorTickCount, id: \.self) { index in
        let progress = Double(index) / Double(majorTickCount - 1)
        let angle = startAngle.degrees + totalAngle * progress
        let value = minValue + (maxValue - minValue) * progress

        label(
          text: "\(Int(value))",
          center: center,
          radius: labelRadius,
          angle: angle
        )
      }
    }
  }

  private func label(
    text: String,
    center: CGPoint,
    radius: CGFloat,
    angle: Double
  ) -> some View {
    let angleRad = angle * .pi / 180
    let x = center.x + cos(angleRad) * radius
    let y = center.y + sin(angleRad) * radius

    return Text(text)
      .font(.system(size: 22, weight: .light, design: .rounded))
      .foregroundStyle(.white.opacity(0.9))
      .position(x: x, y: y)
  }

  private func unitLabel(center: CGPoint, radius: CGFloat) -> some View {
    Text(unit)
      .font(.system(size: 32, weight: .medium, design: .rounded))
      .foregroundStyle(.white.opacity(0.7))
      .position(x: center.x + radius * 0.35, y: center.y - radius * 0.45)
  }

  private func needle(
    center: CGPoint,
    radius: CGFloat,
    value: Double,
    color: Color
  ) -> some View {
    let clampedValue = min(max(value, minValue), maxValue)
    let progress = (clampedValue - minValue) / (maxValue - minValue)
    let totalAngle = endAngle.degrees - startAngle.degrees
    let angle = startAngle.degrees + totalAngle * progress
    let angleRad = angle * .pi / 180

    let needleLength = radius * 0.75
    let needleWidth: CGFloat = 8
    // let hubRadius: CGFloat = 12

    let tipX = center.x + cos(angleRad) * needleLength
    let tipY = center.y + sin(angleRad) * needleLength

    return ZStack {
      Path { path in
        let perpAngle = angleRad + .pi / 2
        let halfWidth = needleWidth / 2

        let baseLeft = CGPoint(
          x: center.x + cos(perpAngle) * halfWidth,
          y: center.y + sin(perpAngle) * halfWidth
        )
        let baseRight = CGPoint(
          x: center.x - cos(perpAngle) * halfWidth,
          y: center.y - sin(perpAngle) * halfWidth
        )
        let tip = CGPoint(x: tipX, y: tipY)

        path.move(to: baseLeft)
        path.addLine(to: tip)
        path.addLine(to: baseRight)
        path.closeSubpath()
      }
      .fill(color)

      //      Circle()
      //        .fill(color.opacity(0.9))
      //        .frame(width: hubRadius * 2, height: hubRadius * 2)
      //        .position(center)
    }
  }
}
