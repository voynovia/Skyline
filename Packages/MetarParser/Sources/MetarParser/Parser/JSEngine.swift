import Foundation
import JavaScriptCore

/// JavaScript engine wrapper for executing METAR/TAF parser.
///
/// Encapsulates JSContext with thread-safe access via NSLock.
/// Marked as `@unchecked Sendable` because thread safety is manually managed.
final class JSEngine: @unchecked Sendable {
  /// JavaScriptCore context for script execution
  private let context: JSContext

  /// Lock for thread-safe access to JSContext
  private let lock = NSLock()

  /// Creates a new JSEngine and loads the parser script.
  ///
  /// - Throws: ParserError.jsContextInitFailed if JSContext creation fails
  /// - Throws: ParserError.parserScriptNotFound if metar-parser.js not found
  init() throws {
    guard let ctx = JSContext() else {
      throw ParserError.jsContextInitFailed
    }
    context = ctx

    // log JS exceptions to console for debugging
    context.exceptionHandler = { _, exception in
      if let exc = exception {
        print("[JSEngine] Exception: \(exc)")
      }
    }

    try loadParserScript()
  }

  /// Loads metar-parser.js from bundle resources.
  private func loadParserScript() throws {
    guard let scriptURL = Bundle.module.url(
      forResource: "metar-parser",
      withExtension: "js"
    ) else {
      throw ParserError.parserScriptNotFound
    }

    let script = try String(contentsOf: scriptURL, encoding: .utf8)
    context.evaluateScript(script, withSourceURL: scriptURL)

    if let exception = context.exception {
      throw ParserError.jsExecutionError(exception.toString())
    }
  }

  /// Calls a JavaScript function with arguments.
  ///
  /// Thread-safe via NSLock.
  ///
  /// - Parameters:
  ///   - name: Function name (e.g., "parseMetar", "parseTaf")
  ///   - arguments: Arguments to pass to the function
  /// - Returns: JSValue result from function call
  /// - Throws: ParserError.jsExecutionError if function not found or execution fails
  func callFunction(_ name: String, arguments: [Any]) throws -> JSValue {
    lock.lock()
    defer { lock.unlock() }

    guard let function = context.objectForKeyedSubscript(name),
          !function.isUndefined
    else {
      throw ParserError.jsExecutionError("Function '\(name)' not found")
    }

    let result = function.call(withArguments: arguments)

    if let exception = context.exception {
      context.exception = nil
      throw ParserError.jsExecutionError(exception.toString())
    }

    return result ?? JSValue(undefinedIn: context)
  }

  /// Converts JSValue to JSON string using JSON.stringify.
  ///
  /// Thread-safe via NSLock.
  ///
  /// - Parameter value: JSValue to serialize
  /// - Returns: JSON string representation
  /// - Throws: ParserError.jsExecutionError on failure
  func toJSONString(_ value: JSValue) throws -> String {
    lock.lock()
    defer { lock.unlock() }

    guard let json = context.objectForKeyedSubscript("JSON"),
          let stringify = json.objectForKeyedSubscript("stringify"),
          let result = stringify.call(withArguments: [value])
    else {
      throw ParserError.jsExecutionError("Failed to stringify result")
    }

    if result.isUndefined || result.isNull {
      throw ParserError.jsExecutionError("Stringify returned null/undefined")
    }

    return result.toString()
  }
}
