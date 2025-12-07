import Foundation
import Synchronization

/// Источник данных из MBTiles файла (векторные тайлы через SQLite)
public final class MBTilesSource: MapSource, Sendable {
  public let id: String
  public let sourceType: MapSourceType = .vector

  private let pathMutex: Mutex<URL>

  /// Текущий путь к файлу MBTiles
  public var path: URL {
    pathMutex.withLock { $0 }
  }

  /// Инициализация источника MBTiles
  /// - Parameters:
  ///   - id: уникальный идентификатор источника
  ///   - path: путь к файлу .mbtiles
  public init(id: String, path: URL) throws {
    guard FileManager.default.fileExists(atPath: path.path) else {
      throw MapSourceError.fileNotFound(path.path)
    }
    self.id = id
    self.pathMutex = Mutex(path)
  }

  /// Обновление пути к файлу
  public func updatePath(_ newPath: URL) throws {
    guard FileManager.default.fileExists(atPath: newPath.path) else {
      throw MapSourceError.fileNotFound(newPath.path)
    }
    pathMutex.withLock { $0 = newPath }
  }

  public var configuration: [String: Any] {
    [
      "type": "vector",
      "tiles": ["http://localhost:{port}/tiles/\(id)/{z}/{x}/{y}.pbf"]
    ]
  }

  /// Конфигурация с подставленным портом
  public func configuration(port: Int) -> [String: Any] {
    [
      "type": "vector",
      "tiles": ["http://localhost:\(port)/tiles/\(id)/{z}/{x}/{y}.pbf"]
    ]
  }
}
