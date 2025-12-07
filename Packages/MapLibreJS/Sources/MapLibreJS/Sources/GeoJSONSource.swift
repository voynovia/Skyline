import Foundation
import Synchronization

/// Источник данных GeoJSON
public final class GeoJSONSource: MapSource, Sendable {
  public let id: String
  public let sourceType: MapSourceType = .geojson

  private let dataMutex: Mutex<GeoJSONData>

  /// Тип данных GeoJSON (все варианты Sendable)
  public enum GeoJSONData: Sendable {
    case url(URL)
    case data(Data)

    var isFile: Bool {
      if case .url(let url) = self {
        return url.isFileURL
      }
      return false
    }
  }

  /// Текущие данные GeoJSON
  public var data: GeoJSONData {
    dataMutex.withLock { $0 }
  }

  /// Инициализация источника GeoJSON из URL
  public init(id: String, url: URL) {
    self.id = id
    self.dataMutex = Mutex(.url(url))
  }

  /// Инициализация источника GeoJSON из Data
  public init(id: String, data: Data) {
    self.id = id
    self.dataMutex = Mutex(.data(data))
  }

  /// Инициализация источника GeoJSON из словаря (конвертируется в Data)
  public init(id: String, dictionary: [String: Any]) throws {
    self.id = id
    let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
    self.dataMutex = Mutex(.data(jsonData))
  }

  /// Обновление данных GeoJSON
  public func updateData(_ newData: GeoJSONData) {
    dataMutex.withLock { $0 = newData }
  }

  public var configuration: [String: Any] {
    configuration(serverPort: nil)
  }

  /// Конфигурация с портом сервера
  public func configuration(serverPort: Int?) -> [String: Any] {
    let currentData = data
    switch currentData {
    case .url(let url):
      if url.isFileURL, let port = serverPort {
        return [
          "type": "geojson",
          "data": "http://localhost:\(port)/geojson/\(id).json"
        ]
      }
      return [
        "type": "geojson",
        "data": url.absoluteString
      ]
    case .data:
      if let port = serverPort {
        return [
          "type": "geojson",
          "data": "http://localhost:\(port)/geojson/\(id).json"
        ]
      }
      return ["type": "geojson", "data": [:]]
    }
  }

  /// Получение данных GeoJSON как Data
  public func getDataBytes() throws -> Data {
    let currentData = data
    switch currentData {
    case .url(let url):
      return try Data(contentsOf: url)
    case .data(let data):
      return data
    }
  }
}
