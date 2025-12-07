//import SwiftUI
//import WeatherKit
//import CoreLocation
//
//struct Gradient {
//  
//  private let weatherService = WeatherKit.WeatherService()
//  private let locationManager = CLLocationManager()
//  
//  func get() async throws -> [Color] {
//    let location = CLLocation(latitude: 59.9311, longitude: 30.3609)
//    let weather = try await weatherService.weather(for: location)
//    
//    // получаем времена восхода и заката
//    let sunrise = weather.dailyForecast.first?.sun.sunrise ?? Date()
//    let sunset = weather.dailyForecast.first?.sun.sunset ?? Date()
//    
//    let period = timePeriod(for: Date(), sunrise: sunrise, sunset: sunset)
//    let colors = gradientForTimePeriod(period)
//    return [colors.top, colors.bottom]
//  }
//  
//  func timePeriod(for date: Date, sunrise: Date, sunset: Date) -> TimePeriod {
//    let calendar = Calendar.current
//    let hour = calendar.component(.hour, from: date)
//    let minute = calendar.component(.minute, from: date)
//    let totalMins = hour * 60 + minute
//    let sunriseMins = calendar.component(.hour, from: sunrise) * 60 + calendar.component(.minute, from: sunrise)
//    let sunsetMins = calendar.component(.hour, from: sunset) * 60 + calendar.component(.minute, from: sunset)
//    
//    switch totalMins {
//    case 0..<sunriseMins-60: return .night
//    case sunriseMins-60..<sunriseMins+60: return .sunrise
//    case sunriseMins+60..<sunsetMins-60: return .day
//    case sunsetMins-60..<sunsetMins+60: return .sunset
//    case sunsetMins+60..<1380: return .evening  // 1380 = 23:00
//    default: return .night
//    }
//  }
//
//  func gradientForTimePeriod(_ period: TimePeriod) -> GradientColors {
//    switch period {
//    case .night:
//      return GradientColors(
//        top: Color(red: 0.07, green: 0.09, blue: 0.20),
//        bottom: Color(red: 0.12, green: 0.15, blue: 0.25)
//      )
//    case .sunrise:
//      return GradientColors(
//        top: Color(red: 0.92, green: 0.65, blue: 0.42),
//        bottom: Color(red: 0.47, green: 0.43, blue: 0.71)
//      )
//    case .morning: // необязательный этап
//      return GradientColors(
//        top: Color(red: 0.60, green: 0.77, blue: 1.0),
//        bottom: Color(red: 0.96, green: 0.96, blue: 0.8)
//      )
//    case .day:
//      return GradientColors(
//        top: Color(red: 0.35, green: 0.68, blue: 0.96),
//        bottom: Color(red: 0.71, green: 0.93, blue: 1.0)
//      )
//    case .sunset:
//      return GradientColors(
//        top: Color(red: 0.95, green: 0.46, blue: 0.34),
//        bottom: Color(red: 0.67, green: 0.35, blue: 0.71)
//      )
//    case .evening:
//      return GradientColors(
//        top: Color(red: 0.18, green: 0.13, blue: 0.29),
//        bottom: Color(red: 0.41, green: 0.21, blue: 0.37)
//      )
//    }
//  }
//}
//
//enum TimePeriod: CaseIterable {
//  case night
//  case sunrise
//  case morning
//  case day
//  case sunset
//  case evening
//}
//
//struct GradientColors {
//  let top: Color
//  let bottom: Color
//}
//
