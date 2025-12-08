import Foundation

/// Intensity of weather phenomenon.
public enum WeatherIntensity: String, Codable, Sendable {
  /// Light intensity (-)
  case light = "-"

  /// Moderate intensity (no prefix)
  case moderate = ""

  /// Heavy intensity (+)
  case heavy = "+"

  /// In vicinity (VC) - within 5-10 miles
  case vicinity = "VC"
}

/// A weather phenomenon from METAR/TAF.
///
/// Examples: -RA (light rain), +TSRA (heavy thunderstorm with rain),
/// BR (mist), FG (fog), SN (snow)
public struct WeatherPhenomenon: Codable, Sendable, Equatable {
  /// Intensity prefix (-, +, VC, or none)
  public let intensity: WeatherIntensity

  /// Descriptor (TS=thunderstorm, SH=showers, FZ=freezing, etc.)
  public let descriptor: String?

  /// Main phenomenon (RA=rain, SN=snow, FG=fog, BR=mist, etc.)
  public let phenomenon: String

  /// Original raw weather string
  public let raw: String

  /// Creates a new weather phenomenon.
  ///
  /// - Parameters:
  ///   - intensity: Intensity level
  ///   - descriptor: Optional descriptor (TS, SH, FZ, etc.)
  ///   - phenomenon: Main phenomenon code
  ///   - raw: Original string
  public init(
    intensity: WeatherIntensity = .moderate,
    descriptor: String? = nil,
    phenomenon: String,
    raw: String
  ) {
    self.intensity = intensity
    self.descriptor = descriptor
    self.phenomenon = phenomenon
    self.raw = raw
  }
}

// MARK: - CustomStringConvertible

extension WeatherPhenomenon: CustomStringConvertible {
  /// Original raw weather string
  public var description: String { raw }
}
