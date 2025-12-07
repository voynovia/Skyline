import Foundation
import Synchronization

/// Источник данных из PMTiles файла (используется протокол pmtiles:// в браузере)
public final class PMTilesSource: MapSource, Sendable {
  public let id: String
  public let sourceType: MapSourceType

  private let urlMutex: Mutex<URL>

  /// Текущий URL к файлу PMTiles
  public var url: URL {
    urlMutex.withLock { $0 }
  }

  /// Инициализация источника PMTiles
  /// - Parameters:
  ///   - id: уникальный идентификатор источника
  ///   - url: URL к файлу .pmtiles (локальный или удалённый)
  ///   - isRaster: true для растровых тайлов, false для векторных
  public init(id: String, url: URL, isRaster: Bool = false) {
    self.id = id
    self.urlMutex = Mutex(url)
    self.sourceType = isRaster ? .raster : .vector
  }

  /// Обновление URL к файлу
  public func updateURL(_ newURL: URL) {
    urlMutex.withLock { $0 = newURL }
  }

  public var configuration: [String: Any] {
    configuration(serverPort: nil)
  }

  /// Конфигурация с опциональным портом сервера для локальных файлов
  /// - Parameter serverPort: порт HTTP сервера для локальных файлов
  public func configuration(serverPort: Int?) -> [String: Any] {
    let currentURL = url
    let pmtilesURL: String
    if currentURL.isFileURL {
      if let port = serverPort {
        pmtilesURL = "pmtiles://http://localhost:\(port)/pmtiles/\(id).pmtiles"
      } else {
        pmtilesURL = "pmtiles://http://localhost:{port}/pmtiles/\(id).pmtiles"
      }
    } else {
      pmtilesURL = "pmtiles://\(currentURL.absoluteString)"
    }

    return [
      "type": sourceType == .raster ? "raster" : "vector",
      "url": pmtilesURL
    ]
  }
}
