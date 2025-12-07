import Foundation

enum FlightCategory: String, Hashable {
  case vfr = "VFR"
  case mvfr = "MVFR"
  case ifr = "IFR"
  case lifr = "LIFR"
  case unkn = "UNKN"
  
  var icon: String {
    switch self {
    case .vfr:
      return "sun.max" // Ясная погода, потолок >3000' и видимость >5 миль
    case .mvfr:
      return "cloud.sun" // Частичная облачность, потолок 1000-3000' и/или видимость 3-5 миль
    case .ifr:
      return "cloud" // Облачно, потолок 500-999' и/или видимость 1-3 мили
    case .lifr:
      return "cloud.fog" // Туман/очень низкие облака, потолок <500' и/или видимость <1 мили
    case .unkn:
      return "questionmark.circle" // Неизвестные условия
    }
  }
  
  var description: String {
    switch self {
    case .vfr:
      return "Visual Flight Rules"
    case .mvfr:
      return "Marginal VFR"
    case .ifr:
      return "Instrument Flight Rules"
    case .lifr:
      return "Low IFR"
    case .unkn:
      return "Incomplete or expired data"
    }
  }
  
  var visibility: String {
    switch self {
    case .vfr:
      return "> 8 km"
    case .mvfr:
      return "5-8 km"
    case .ifr:
      return "1.5-5 km"
    case .lifr:
      return "< 1.5 km"
    case .unkn:
      return ""
    }
  }
  
  var ceiling: String {
    switch self {
    case .vfr:
      return "> 3,000 ft"
    case .mvfr:
      return "1,000‑3,000 ft"
    case .ifr:
      return "500‑1,000 ft"
    case .lifr:
      return "< 500 ft"
    case .unkn:
      return ""
    }
  }
  
}
