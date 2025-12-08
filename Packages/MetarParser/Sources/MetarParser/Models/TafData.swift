import Foundation

/// Parsed TAF (Terminal Aerodrome Forecast) data.
///
/// Contains forecast information for an airport including base forecast
/// and any change groups (TEMPO, BECMG, FM, PROB).
public struct TafData: Codable, Sendable, Equatable {
  /// ICAO airport code (e.g., "KJFK", "EGLL")
  public let station: String

  /// Raw issue time from TAF (DDHHMMz format)
  public let rawIssueTime: String?

  /// Raw validity start (DDHH format)
  public let rawValidFrom: String?

  /// Raw validity end (DDHH format)
  public let rawValidTo: String?

  /// Whether this is an amended TAF (AMD)
  public let isAmended: Bool

  /// Whether this is a corrected TAF (COR)
  public let isCorrected: Bool

  /// Base forecast conditions
  public let forecast: TafForecast

  /// Change groups (TEMPO, BECMG, FM, PROB)
  public let changes: [TafChange]

  /// Original raw TAF string
  public let raw: String
}

/// Forecast conditions in a TAF.
///
/// Used for both base forecast and change groups.
public struct TafForecast: Codable, Sendable, Equatable {
  /// Wind direction in degrees (nil if variable)
  public let windDirection: Int?

  /// Whether wind direction is variable (VRB)
  public let isWindVariable: Bool

  /// Wind speed in knots
  public let windSpeedKt: Int?

  /// Wind gust speed in knots (nil if no gusts)
  public let windGustKt: Int?

  /// Visibility in meters
  public let visibilityMeters: Int?

  /// CAVOK conditions
  public let isCavok: Bool

  /// Cloud layers
  public let clouds: [CloudLayer]

  /// Weather phenomena
  public let weather: [WeatherPhenomenon]
}

/// Type of TAF change group.
public enum TafChangeType: String, Codable, Sendable {
  /// Temporary fluctuations (usually < 1 hour)
  case tempo = "TEMPO"

  /// Gradual change expected
  case becoming = "BECMG"

  /// From specific time
  case from = "FM"

  /// 30% probability
  case probability30 = "PROB30"

  /// 40% probability
  case probability40 = "PROB40"
}

/// A change group within a TAF.
///
/// Describes temporary or permanent changes to forecast conditions.
public struct TafChange: Codable, Sendable, Equatable {
  /// Type of change (TEMPO, BECMG, FM, PROB)
  public let type: TafChangeType

  /// Start time of change period (DDHH format)
  public let rawFrom: String?

  /// End time of change period (DDHH format)
  public let rawTo: String?

  /// Forecast conditions during/after change
  public let forecast: TafForecast
}
