import Foundation
import CoreLocation
import WeatherKit

//extension CLLocationCoordinate2D: @retroactive Equatable, @retroactive Hashable {
//  static func == (lhs: Self, rhs: Self) -> Bool {
//    lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
//  }
//  public func hash(into hasher: inout Hasher) {
//    hasher.combine(latitude)
//    hasher.combine(longitude)
//  }
//}


struct Arp: Identifiable, Hashable {
  let id = UUID()
  let name: String
  let icao: String
  let iata: String?
  let category: FlightCategory
  let condition: WeatherCondition
  let temperature: Int // C
  let dewpoint: Int
  let windSpeed: Int
  let windDirection: Int? // "Variable"
  let visibility: Int
  let ceiling: Int? // "None"
  let qnh: Int
  
//  let location: CLLocationCoordinate2D
  
  var weatherIcon: String {
    switch condition {
    case .blizzard, .blowingSnow: return "wind.snow"
    case .blowingDust: return "sun.dust.fill"
    case .breezy, .windy: return "wind"
    case .clear, .mostlyClear: return "sun.max.fill"
    case .cloudy: return "cloud.fill"
    case .drizzle: return "cloud.drizzle.fill"
    case .foggy: return "cloud.fog.fill"
    case .freezingDrizzle: return "cloud.sleet.fill"
    case .freezingRain: return "cloud.sleet.fill"
    case .frigid: return "thermometer.snowflake"
    case .hail: return "cloud.hail.fill"
    case .haze: return "sun.haze.fill"
    case .heavyRain: return "cloud.heavyrain.fill"
    case .hot: return "thermometer.sun.fill"
    case .hurricane, .tropicalStorm: return "hurricane"
    case .isolatedThunderstorms: return "cloud.bolt.fill"
    case .mostlyCloudy: return "cloud.sun.fill"
    case .partlyCloudy: return "cloud.sun.fill"
    case .rain: return "cloud.rain.fill"
    case .scatteredThunderstorms: return "cloud.bolt.rain.fill"
    case .sleet, .wintryMix: return "cloud.sleet.fill"
    case .smoky: return "smoke.fill"
    case .snow, .heavySnow, .flurries: return "cloud.snow.fill"
    case .strongStorms, .thunderstorms: return "cloud.bolt.rain.fill"
    case .sunFlurries: return "sun.snow.fill"
    case .sunShowers: return "sun.rain.fill"
    @unknown default: return "questionmark"
    }
  }
}

extension Arp {
  static let sampleCities: [Arp] = [
    Arp(
      name: "Maribor",
      icao: "LJMB",
      iata: "MBX",
      category: .vfr,
      condition: .rain,
      temperature: 9,
      dewpoint: 7,
      windSpeed: 5,
      windDirection: 230,
      visibility: 10,
      ceiling: 6200,
      qnh: 1015,
//      location: CLLocationCoordinate2D(latitude: 46.48, longitude: 15.686111)
    ),
    Arp(
      name: "Pulkovo",
      icao: "ULLI",
      iata: "LED",
      category: .vfr,
      condition: .cloudy,
      temperature: 11,
      dewpoint: 8,
      windSpeed: 10,
      windDirection: 120,
      visibility: 10,
      ceiling: nil,
      qnh: 1005,
//      location: CLLocationCoordinate2D(latitude: 59.800278, longitude: 30.262497)
    ),
    Arp(
      name: "Bratsk",
      icao: "UIBB",
      iata: "BTK",
      category: .vfr,
      condition: .clear,
      temperature: -2,
      dewpoint: -2,
      windSpeed: 2,
      windDirection: nil,
      visibility: 10,
      ceiling: nil,
      qnh: 1021,
//      location: CLLocationCoordinate2D(latitude: 56.370556, longitude: 101.698608)
    ),
    Arp(
      name: "MISAWA",
      icao: "RJSM",
      iata: "MSJ",
      category: .mvfr,
      condition: .mostlyCloudy,
      temperature: 20,
      dewpoint: 15,
      windSpeed: 5,
      windDirection: 300,
      visibility: 10,
      ceiling: 3000,
      qnh: 1010,
//      location: CLLocationCoordinate2D(latitude: 40.703056, longitude: 141.368333)
    )
  ]
}

