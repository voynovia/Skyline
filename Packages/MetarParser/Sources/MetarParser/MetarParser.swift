// MetarParser - METAR/TAF message parser using JavaScriptCore

@_exported import struct Foundation.Date

/// Alias for MetarData for convenience
public typealias Metar = MetarData

/// Alias for TafData for convenience
public typealias Taf = TafData

/// Shared parser instance for global functions
private let sharedParser: MetarJSParser? = try? MetarJSParser()

/// Parses a single METAR message string.
///
/// - Parameter raw: Raw METAR string (e.g., "METAR KJFK 081256Z 32010KT...")
/// - Returns: Parsed MetarData structure
/// - Throws: ParserError if parsing fails
///
/// Example:
/// ```swift
/// let metar = try parseMetar("METAR KJFK 081256Z 32010KT 10SM FEW020 22/16 A3012")
/// print(metar.station)  // "KJFK"
/// ```
public func parseMetar(_ raw: String) throws -> MetarData {
  guard let parser = sharedParser else {
    throw ParserError.jsContextInitFailed
  }
  return try parser.parseMetar(raw)
}

/// Parses a single TAF message string.
///
/// - Parameter raw: Raw TAF string (e.g., "TAF KJFK 081130Z 0812/0918...")
/// - Returns: Parsed TafData structure
/// - Throws: ParserError if parsing fails
///
/// Example:
/// ```swift
/// let taf = try parseTaf("TAF KJFK 081130Z 0812/0918 32015KT 9999 SKC")
/// print(taf.station)  // "KJFK"
/// ```
public func parseTaf(_ raw: String) throws -> TafData {
  guard let parser = sharedParser else {
    throw ParserError.jsContextInitFailed
  }
  return try parser.parseTaf(raw)
}

/// Parses multiple METAR messages.
///
/// - Parameter raws: Array of raw METAR strings
/// - Returns: Array of parsed MetarData
/// - Throws: ParserError if any message fails to parse
///
/// Example:
/// ```swift
/// let metars = try parseMetars(["METAR KJFK...", "METAR EGLL..."])
/// ```
public func parseMetars(_ raws: [String]) throws -> [MetarData] {
  guard let parser = sharedParser else {
    throw ParserError.jsContextInitFailed
  }
  return try parser.parseMetars(raws)
}

/// Parses multiple TAF messages.
///
/// - Parameter raws: Array of raw TAF strings
/// - Returns: Array of parsed TafData
/// - Throws: ParserError if any message fails to parse
public func parseTafs(_ raws: [String]) throws -> [TafData] {
  guard let parser = sharedParser else {
    throw ParserError.jsContextInitFailed
  }
  return try parser.parseTafs(raws)
}
