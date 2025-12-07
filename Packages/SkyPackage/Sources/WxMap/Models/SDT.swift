import Foundation

struct SDT {
  let speed: Int
  let direction: Int
  let temperature: Int
}

extension SDT: Equatable, Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.speed == rhs.speed &&
    lhs.direction == rhs.direction &&
    lhs.temperature == rhs.temperature
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(speed)
    hasher.combine(direction)
    hasher.combine(temperature)
  }
}
