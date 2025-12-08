import Foundation

/// Cloud coverage amount in oktas (eighths of sky).
public enum CloudCoverage: String, Codable, Sendable {
  /// Few clouds (1-2 oktas)
  case few = "FEW"

  /// Scattered clouds (3-4 oktas)
  case scattered = "SCT"

  /// Broken clouds (5-7 oktas) - constitutes a ceiling
  case broken = "BKN"

  /// Overcast (8 oktas) - constitutes a ceiling
  case overcast = "OVC"

  /// Clear sky (US)
  case clear = "CLR"

  /// Sky clear (ICAO)
  case skyClear = "SKC"

  /// No significant cloud
  case nsc = "NSC"

  /// No cloud detected (automated)
  case ncd = "NCD"

  /// Vertical visibility (sky obscured) - constitutes a ceiling
  case verticalVisibility = "VV"
}

/// A single cloud layer with coverage, height, and optional type.
public struct CloudLayer: Codable, Sendable, Equatable {
  /// Cloud coverage amount
  public let coverage: CloudCoverage

  /// Height of cloud base in feet AGL
  public let heightFeet: Int?

  /// Cloud type (CB = cumulonimbus, TCU = towering cumulus)
  public let cloudType: String?

  /// Creates a new cloud layer.
  ///
  /// - Parameters:
  ///   - coverage: Cloud coverage amount
  ///   - heightFeet: Height in feet AGL (nil for CLR/SKC)
  ///   - cloudType: Optional cloud type (CB, TCU)
  public init(coverage: CloudCoverage, heightFeet: Int? = nil, cloudType: String? = nil) {
    self.coverage = coverage
    self.heightFeet = heightFeet
    self.cloudType = cloudType
  }
}

// MARK: - CustomStringConvertible

extension CloudLayer: CustomStringConvertible {
  /// METAR format string (e.g., "FEW020", "BKN100CB")
  public var description: String {
    var s = coverage.rawValue
    if let h = heightFeet { s += String(format: "%03d", h / 100) }
    if let t = cloudType { s += t }
    return s
  }
}
