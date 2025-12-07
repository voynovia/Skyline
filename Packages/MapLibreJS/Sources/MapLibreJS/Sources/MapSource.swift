import Foundation

/// Тип источника данных для карты
public enum MapSourceType: String, Sendable {
  case vector
  case raster
  case geojson
}

/// Протокол для источников данных карты
public protocol MapSource: Sendable {
  /// Уникальный идентификатор источника
  var id: String { get }

  /// Тип источника
  var sourceType: MapSourceType { get }

  /// Конфигурация источника для передачи в MapLibre GL JS
  var configuration: [String: Any] { get }
}

/// Расширение для сериализации конфигурации в JSON
extension MapSource {
  public func configurationJSON() throws -> String {
    let data = try JSONSerialization.data(withJSONObject: configuration)
    guard let json = String(data: data, encoding: .utf8) else {
      throw MapSourceError.serializationFailed
    }
    return json
  }
}

/// Ошибки работы с источниками
public enum MapSourceError: Error, Sendable {
  case fileNotFound(String)
  case invalidPath
  case serializationFailed
  case invalidData
}
