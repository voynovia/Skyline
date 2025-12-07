// MapLibreJS - Swift обёртка над MapLibre GL JS
// https://github.com/maplibre/maplibre-gl-js

@_exported import struct Foundation.URL
@_exported import struct Foundation.Data

// MARK: - Public Types

public typealias MapSourceProtocol = MapSource

// MARK: - Convenience initializers

extension MapServer {
  /// Создание сервера с автоматической инициализацией ресурсов
  public static func create() async throws -> MapServer {
    let resourceManager = ResourceManager()
    try await resourceManager.prepareResources()
    return MapServer(resourceManager: resourceManager)
  }
}

// MARK: - MapView convenience

extension MapView {
  /// Инициализация MapView с автозапуском сервера
  public init(
    resourceManager: ResourceManager,
    onZoomChange: ((Double) -> Void)? = nil,
    onClick: ((MapClickEvent) -> Void)? = nil
  ) {
    let server = MapServer(resourceManager: resourceManager)
    self.init(server: server, onZoomChange: onZoomChange, onClick: onClick)
  }
}
