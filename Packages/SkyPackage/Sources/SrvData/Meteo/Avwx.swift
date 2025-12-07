import Foundation

public struct AvwxMetar: Decodable, Equatable {
  public let data: AvwxMetarData
  public let translations: AvwxMetarTranslations
  public let units: AvwxUnits
}

public struct AvwxMetarData: Decodable, Equatable {
  public let altimeter: AvwxValue?
  public let clouds: [AvwxCloud]?
  public let dewpoint: AvwxValue?
  public let flight_rules: String
  public let relative_humidity: Double?
  public let remarks: String?
  public let remarks_info: AvwxRemarksInfo?
  public let station: String
  public let temperature: AvwxValue?
  public let time: AvwxTime
  public let visibility: AvwxValue?
  public let wind_direction: AvwxValue?
  public let wind_speed: AvwxValue?
}

public struct AvwxValue: Decodable, Equatable {
  public let repr: String
  public let spoken: String?
  public let value: Double?
}


public struct AvwxCloud: Decodable, Hashable, Equatable {
  public let repr: String
  public let base: Int?
  public let type: String?
  public let modifier: String?
  public let top: String?
  public let spoken: String?
  public let altitude: Int?
}

public struct AvwxRemarksInfo: Decodable, Equatable {
  public let codes: [AvwxWxCodes]?
  public let dewpoint_decimal: AvwxValue?
  public let maximum_temperature_24: AvwxValue?
  public let maximum_temperature_6: AvwxValue?
  public let minimum_temperature_24: AvwxValue?
  public let minimum_temperature_6: AvwxValue?
  public let precip_24_hours: AvwxValue?
  public let precip_36_hours: AvwxValue?
  public let precip_hourly: AvwxValue?
  public let pressure_tendency: AvwxValue?
  public let sea_level_pressure: AvwxValue?
  public let snow_depth: AvwxValue?
  public let sunshine_minutes: AvwxValue?
  public let temperature_decimal: AvwxValue?
}

public struct AvwxWxCodes: Decodable, Equatable {
  public let repr: String
  public let value: String
}

public struct AvwxMetarTranslations: Decodable, Hashable, Equatable {
  public let altimeter: String?
  public let clouds: String?
  public let icing: String?
  public let turbulence: String?
  public let ceiling: Int?
  public let dewpoint: String?
  public let temperature: String?
  public let visibility: String?
  public let wind: String?
  public let wind_shear: String?
  public let remarks: [String: String]?
  public let wx_codes: String?
}

public struct AvwxUnits: Decodable, Equatable {
  public let accumulation: String
  public let altimeter: String
  public let altitude: String
  public let temperature: String
  public let visibility: String
  public let wind_speed: String
}

public struct AvwxTime: Decodable, Equatable {
  public let repr: String
  public let dt: Date
}
