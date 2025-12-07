import SwiftUI
import Horizon

@Equatable
struct WindRoseView: View {
  var degrees: Double
  var direction: Int?
  var speed: Int
  
  private let size: CGFloat = 80
  
  var body: some View {
    VStack {
      // Compass
      ZStack(alignment: .center) {
        Group {
          // Markers
          ForEach(CompassMarker.markers(), id: \.self) { marker in
            CompassMarkerView(marker: marker, compassDegrees: degrees)
          }
          // Runway
//          if let rw = viewModel.currentRunway {
            ZStack {
              Rectangle()
                .fill(.secondary)
//                .border(Color.white)
                .frame(maxHeight: .infinity)
//              VStack {
//                Group {
//                  Text("28R").rotationEffect(Angle(degrees: 180))
//                  Spacer()
//                  Text("10L")
//                }
//                .font(.system(size: 4))
//                .foregroundColor(Color.white)
//              }
            }
            .frame(width: 8, height: size*2/3)
            .rotationEffect(Angle(degrees: 280))
//          }
          // Speed
          Text("\(speed)")
            .font(.largeTitle)
          // Arrow
          if let direction {
            Group {
              Triangle().frame(width: 8, height: 16).position(x: size/2, y: size) // height и y должны быть одинаковы
//              Capsule().frame(width: 2, height: 60)
            }
            .foregroundColor(.white)
            .rotationEffect(Angle(degrees: Double(direction)))
          }
        }
        .frame(width: size, height: size)
//        .frame(maxWidth: .infinity)
        .rotationEffect(Angle(degrees: degrees))
      }
      
    }
  }
}

public struct Triangle: Shape {
  
  public init() {}
  
  public func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
    return path
  }
  
}
