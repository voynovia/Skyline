import Foundation
import SwiftUI
import Horizon

@Equatable
struct CompassMarkerView: View {
  let marker: CompassMarker
  let compassDegrees: Double
  
  private var capsuleWidth: CGFloat {
    marker.degrees == 0 ? 3 : 2
  }
  
  private var capsuleHeight: CGFloat {
    let height: Double = marker.isShort ? 4 : 8
    return height // marker.degrees == 0 ? 10 : height
  }
  
  private var capsuleColor: Color {
    return .white
//    marker.degrees == 0 ? .red : .gray
  }
  
  private var font: Font {
    return .system(size: 8)
//    marker.label == nil ? .headline : .title
  }
  
  private var fontWeight: Font.Weight {
    marker.label == nil ? .light : .bold
  }
  
  private var textColor: Color {
    marker.label == nil ? .gray : .white
  }
  
  private var textAngle: SwiftUICore.Angle {
    SwiftUICore.Angle(degrees: -compassDegrees - marker.degrees)
  }
  
  var body: some View {
    VStack {
//      Text(marker.label ?? " ")
//        .font(font)
//        .fontWeight(fontWeight)
//        .foregroundColor(textColor)
//        .rotationEffect(textAngle)
      
      Capsule()
        .fill(.foreground)
        .frame(width: capsuleWidth, height: capsuleHeight)
//        .foregroundColor(capsuleColor)
      
      Spacer(minLength: 40)
    }
    .rotationEffect(SwiftUICore.Angle(degrees: marker.degrees))
  }
}

struct CompassMarker: Hashable {
  let degrees: Double
  var text: String?
  let label: String?
  let isShort: Bool
  
  init(degrees: Double, text: String? = nil, label: String? = nil, isShort: Bool = false) {
    self.degrees = degrees
    self.text = text
    self.label = label
    self.isShort = isShort
  }
  
  static func markers() -> [CompassMarker] {
    var result: [CompassMarker] = []
    for degree in stride(from: 0, to: 360.0, by: 22.5) {
      switch degree {
      case 0: result.append(.init(degrees: degree, label: "N"))
      case 45: result.append(.init(degrees: degree, label: "NE"))
      case 90: result.append(.init(degrees: degree, label: "E"))
      case 135: result.append(.init(degrees: degree, label: "SE"))
      case 180: result.append(.init(degrees: degree, label: "S"))
      case 225: result.append(.init(degrees: degree, label: "SW"))
      case 270: result.append(.init(degrees: degree, label: "W"))
      case 315: result.append(.init(degrees: degree, label: "NW"))
      default:
        var marker = CompassMarker(degrees: degree, isShort: true)
        if degree.truncatingRemainder(dividingBy: 22.5) == 0 {
          marker.text = String(format: "%.1f", degree)
        }
        result.append(marker)
      }
    }
    return result
  }
  
}
