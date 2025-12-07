import SwiftUI

struct GradientColors {
  let colors: [Color]
  let startPoint: UnitPoint
  let endPoint: UnitPoint
  
  init(_ colors: [Color], from start: UnitPoint = .top, to end: UnitPoint = .bottom) {
    self.colors = colors
    self.startPoint = start
    self.endPoint = end
  }
  
  
}
