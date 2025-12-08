import Foundation

/// Errors that can occur during METAR/TAF parsing.
public enum ParserError: Error, Sendable {
  /// JavaScript parser script file not found in bundle
  case parserScriptNotFound

  /// Failed to create JavaScript context
  case jsContextInitFailed

  /// JavaScript execution error with message
  case jsExecutionError(String)

  /// Invalid METAR/TAF format
  case invalidFormat(String)

  /// Failed to decode JSON result to Swift struct
  case decodingError(String)

  /// Empty input string provided
  case emptyInput
}

// MARK: - LocalizedError

extension ParserError: LocalizedError {
  /// Human-readable error description
  public var errorDescription: String? {
    switch self {
    case .parserScriptNotFound:
      "JavaScript parser script not found in bundle"
    case .jsContextInitFailed:
      "Failed to initialize JavaScript context"
    case .jsExecutionError(let message):
      "JavaScript execution error: \(message)"
    case .invalidFormat(let message):
      "Invalid METAR/TAF format: \(message)"
    case .decodingError(let message):
      "Failed to decode parser result: \(message)"
    case .emptyInput:
      "Empty input string"
    }
  }
}
