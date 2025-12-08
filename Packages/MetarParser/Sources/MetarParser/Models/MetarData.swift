import Foundation

/// Parsed METAR (Meteorological Aerodrome Report) data.
///
/// Contains all fields extracted from a METAR message including wind, visibility,
/// clouds, temperature, pressure, and computed properties like flight category.
public struct MetarData: Codable, Sendable, Equatable {
  /// ICAO airport code (e.g., "KJFK", "EGLL")
  public let station: String

  /// Raw timestamp from METAR (DDHHMMz format)
  public let rawTimestamp: String?

  /// Whether this is a correction (COR)
  public let isCorrection: Bool

  /// Whether this is an automated report (AUTO)
  public let isAuto: Bool

  /// Wind direction in degrees (nil if variable)
  public let windDirection: Int?

  /// Whether wind direction is variable (VRB)
  public let isWindVariable: Bool

  /// Wind speed in knots
  public let windSpeedKt: Int?

  /// Wind gust speed in knots (nil if no gusts)
  public let windGustKt: Int?

  /// Visibility in meters (ICAO format)
  public let visibilityMeters: Int?

  /// Visibility in statute miles (US format)
  public let visibilityMiles: Double?

  /// CAVOK (Ceiling And Visibility OK) - visibility >10km, no significant clouds/weather
  public let isCavok: Bool

  /// Cloud layers from lowest to highest
  public let clouds: [CloudLayer]

  /// Temperature in Celsius
  public let temperatureC: Int?

  /// Dewpoint in Celsius
  public let dewpointC: Int?

  /// Altimeter setting in hectopascals (QNH)
  public let altimeterHpa: Int?

  /// Altimeter setting in inches of mercury (US)
  public let altimeterInHg: Double?

  /// Weather phenomena (rain, snow, fog, etc.)
  public let weather: [WeatherPhenomenon]

  /// Remarks section (RMK)
  public let remarks: String?

  /// Original raw METAR string
  public let raw: String

  // MARK: - Computed Properties

  /// Relative humidity percentage calculated from temperature and dewpoint.
  ///
  /// Uses Magnus-Tetens approximation formula.
  public var relativeHumidity: Int? {
    guard let temp = temperatureC, let dew = dewpointC else { return nil }
    let rh = 100.0 * exp((17.625 * Double(dew)) / (243.04 + Double(dew))) /
      exp((17.625 * Double(temp)) / (243.04 + Double(temp)))
    return Int(rh.rounded())
  }

  /// Temperature converted to Fahrenheit.
  public var temperatureF: Int? {
    guard let c = temperatureC else { return nil }
    return Int((Double(c) * 9.0 / 5.0 + 32.0).rounded())
  }

  /// Dewpoint converted to Fahrenheit.
  public var dewpointF: Int? {
    guard let c = dewpointC else { return nil }
    return Int((Double(c) * 9.0 / 5.0 + 32.0).rounded())
  }

  /// Height of the lowest cloud layer in feet (any coverage).
  public var lowestCloudLayerFeet: Int? {
    clouds.compactMap(\.heightFeet).min()
  }

  /// Ceiling height in feet - lowest BKN/OVC/VV layer.
  ///
  /// Ceiling is defined as the lowest layer covering more than half the sky
  /// (broken = 5-7 oktas, overcast = 8 oktas, or vertical visibility).
  public var ceilingFeet: Int? {
    clouds
      .filter { $0.coverage == .broken || $0.coverage == .overcast || $0.coverage == .verticalVisibility }
      .compactMap(\.heightFeet)
      .min()
  }

  /// Visibility converted to statute miles.
  ///
  /// Returns visibilityMiles if available, otherwise converts visibilityMeters.
  /// 1 statute mile = 1609.344 meters
  public var visibilityStatuteMiles: Double? {
    if let miles = visibilityMiles { return miles }
    if let meters = visibilityMeters { return Double(meters) / 1609.344 }
    return nil
  }

  /// Flight category based on FAA criteria.
  ///
  /// Determined by the worse of ceiling or visibility:
  /// - VFR: ceiling > 3000 ft AND visibility > 5 SM
  /// - MVFR: ceiling 1000-3000 ft OR visibility 3-5 SM
  /// - IFR: ceiling 500-1000 ft OR visibility 1-3 SM
  /// - LIFR: ceiling < 500 ft OR visibility < 1 SM
  public var flightCategory: FlightCategory {
    let vis = visibilityStatuteMiles ?? 10
    let ceil = ceilingFeet ?? 99999

    if ceil < 500 || vis < 1 { return .lifr }
    if ceil < 1000 || vis < 3 { return .ifr }
    if ceil <= 3000 || vis <= 5 { return .mvfr }
    return .vfr
  }
}

// MARK: - CustomStringConvertible

extension MetarData: CustomStringConvertible {
  /// Human-readable multi-line description of the METAR.
  public var description: String {
    var lines: [String] = []
    lines.append("METAR \(station)")
    if let ts = rawTimestamp { lines.append("  Time: \(ts)") }

    var wind = "  Wind: "
    if isWindVariable { wind += "VRB" }
    else if let dir = windDirection { wind += "\(dir)°" }
    if let spd = windSpeedKt { wind += " \(spd)kt" }
    if let gust = windGustKt { wind += " G\(gust)kt" }
    lines.append(wind)

    if isCavok {
      lines.append("  Visibility: CAVOK")
    } else if let sm = visibilityStatuteMiles {
      let formatted = String(format: "%.1f", sm)
      if let m = visibilityMeters {
        lines.append("  Visibility: \(m)m (\(formatted) SM)")
      } else {
        lines.append("  Visibility: \(formatted) SM")
      }
    }

    lines.append("  Flight Category: \(flightCategory.rawValue)")

    if !clouds.isEmpty {
      lines.append("  Clouds: \(clouds.map(\.description).joined(separator: ", "))")
      if let lowest = lowestCloudLayerFeet {
        lines.append("  Lowest: \(lowest) ft")
      }
      if let ceiling = ceilingFeet {
        lines.append("  Ceiling: \(ceiling) ft")
      }
    }

    if !weather.isEmpty {
      lines.append("  Weather: \(weather.map(\.description).joined(separator: ", "))")
    }

    if let tC = temperatureC, let dC = dewpointC, let tF = temperatureF, let dF = dewpointF {
      lines.append("  Temp/Dew: \(tC)°C (\(tF)°F) / \(dC)°C (\(dF)°F)")
    }
    if let rh = relativeHumidity { lines.append("  RH: \(rh)%") }

    if let hpa = altimeterHpa { lines.append("  QNH: \(hpa) hPa") }
    if let inHg = altimeterInHg { lines.append("  Altimeter: \(inHg) inHg") }

    if let rmk = remarks { lines.append("  Remarks: \(rmk)") }

    return lines.joined(separator: "\n")
  }
}
