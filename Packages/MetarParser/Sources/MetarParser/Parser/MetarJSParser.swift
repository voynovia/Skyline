import Foundation
import JavaScriptCore

/// Main parser class for METAR/TAF messages.
///
/// Uses JavaScriptCore to execute JavaScript parser and decode results into Swift structures.
/// Thread-safe via NSLock in JSEngine.
public final class MetarJSParser: Sendable {
  /// JS engine for parsing
  private let engine: JSEngine

  /// JSON decoder for converting JS results to Swift
  private let decoder: JSONDecoder

  /// Creates a new parser instance.
  ///
  /// Initializes JSEngine with loaded JavaScript parser script.
  /// Performs warmup to avoid cold start penalty on first call.
  /// - Throws: ParserError.jsContextInitFailed or ParserError.parserScriptNotFound
  public init() throws {
    engine = try JSEngine()
    decoder = JSONDecoder()

    // warmup: run full parsing path with complex METAR to trigger all regex paths
    _ = try? parseMetar("METAR XXXX 010000Z 32010G20KT 9999 -RA BR FEW010 SCT020 BKN040 OVC100 M05/M10 Q1013 NOSIG RMK AO2")
    _ = try? parseMetar("METAR XXXX 010000Z VRB02KT 0800 +TSRA FG VV001 10/09 A2992")
  }

  // MARK: - Single Message Parsing

  /// Parses a single METAR message.
  ///
  /// - Parameter raw: Raw METAR string
  /// - Returns: Parsed MetarData
  /// - Throws: ParserError on failure
  public func parseMetar(_ raw: String) throws -> MetarData {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw ParserError.emptyInput
    }

    let result = try engine.callFunction("parseMetar", arguments: [trimmed])

    if result.isUndefined || result.isNull {
      throw ParserError.invalidFormat("Parser returned null for: \(trimmed)")
    }

    let jsonString = try engine.toJSONString(result)

    do {
      let data = Data(jsonString.utf8)
      return try decoder.decode(MetarData.self, from: data)
    } catch {
      throw ParserError.decodingError("\(error)")
    }
  }

  /// Parses a single TAF message.
  ///
  /// - Parameter raw: Raw TAF string
  /// - Returns: Parsed TafData
  /// - Throws: ParserError on failure
  public func parseTaf(_ raw: String) throws -> TafData {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw ParserError.emptyInput
    }

    let result = try engine.callFunction("parseTaf", arguments: [trimmed])

    if result.isUndefined || result.isNull {
      throw ParserError.invalidFormat("Parser returned null for: \(trimmed)")
    }

    let jsonString = try engine.toJSONString(result)

    do {
      let data = Data(jsonString.utf8)
      return try decoder.decode(TafData.self, from: data)
    } catch {
      throw ParserError.decodingError("\(error)")
    }
  }

  // MARK: - Batch Parsing

  /// Parses multiple METAR messages.
  ///
  /// - Parameter raws: Array of raw METAR strings
  /// - Returns: Array of parsed MetarData
  /// - Throws: ParserError if any message fails to parse
  public func parseMetars(_ raws: [String]) throws -> [MetarData] {
    try raws.map { try parseMetar($0) }
  }

  /// Parses multiple TAF messages.
  ///
  /// - Parameter raws: Array of raw TAF strings
  /// - Returns: Array of parsed TafData
  /// - Throws: ParserError if any message fails to parse
  public func parseTafs(_ raws: [String]) throws -> [TafData] {
    try raws.map { try parseTaf($0) }
  }
}
