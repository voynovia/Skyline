import Foundation
import FlyingFox

/// HTTP сервер для раздачи ресурсов карты
public actor MapServer {
  private var server: HTTPServer?
  private let resourceManager: ResourceManager
  private let sqliteManager: SQLiteManager

  private var mbTilesSources: [String: MBTilesSource] = [:]
  private var pmTilesSources: [String: PMTilesSource] = [:]
  private var geoJSONSources: [String: GeoJSONSource] = [:]

  private var pendingTileRequests: [String: Task<Data?, Never>] = [:]

  /// Текущий порт сервера (nil если не запущен)
  public private(set) var port: Int?

  /// URL базы сервера
  public var baseURL: URL? {
    guard let port else { return nil }
    return URL(string: "http://localhost:\(port)")
  }

  public init(resourceManager: ResourceManager) {
    self.resourceManager = resourceManager
    self.sqliteManager = SQLiteManager()
  }

  /// Запуск сервера на свободном порту
  public func start() async throws(MapServerError) {
    let foundPort = try await findAvailablePort()
    self.port = foundPort

    let server = HTTPServer(address: .loopback(port: UInt16(foundPort)))
    self.server = server

    await setupRoutes(server: server)

    Task {
      try? await server.run()
    }

    do {
      try await Task.sleep(for: .milliseconds(100))
    } catch {
      throw .serverNotRunning
    }
  }

  /// Остановка сервера
  public func stop() async {
    await server?.stop()
    server = nil
    port = nil
  }

  // MARK: - Sources Management

  /// Регистрация MBTiles источника
  public func register(_ source: MBTilesSource) {
    mbTilesSources[source.id] = source
  }

  /// Регистрация PMTiles источника
  public func register(_ source: PMTilesSource) {
    pmTilesSources[source.id] = source
  }

  /// Регистрация GeoJSON источника
  public func register(_ source: GeoJSONSource) {
    geoJSONSources[source.id] = source
  }

  /// Удаление источника по ID
  public func unregister(sourceId: String) {
    if let source = mbTilesSources.removeValue(forKey: sourceId) {
      sqliteManager.closePool(path: source.path)
    }
    pmTilesSources.removeValue(forKey: sourceId)
    geoJSONSources.removeValue(forKey: sourceId)
  }

  /// Получение MBTiles источника по ID
  public func getMBTilesSource(_ id: String) -> MBTilesSource? {
    mbTilesSources[id]
  }

  /// Получение конфигурации источника для JS (с подставленным портом)
  /// Возвращает JSON Data для безопасной передачи через границу actor
  public func sourceConfigurationData(for sourceId: String) -> Data? {
    guard let port else { return nil }

    let config: [String: Any]?
    if let source = mbTilesSources[sourceId] {
      config = source.configuration(port: port)
    } else if let source = pmTilesSources[sourceId] {
      config = source.configuration(serverPort: port)
    } else if let source = geoJSONSources[sourceId] {
      config = source.configuration(serverPort: port)
    } else {
      config = nil
    }

    guard let config else { return nil }
    return try? JSONSerialization.data(withJSONObject: config)
  }

  // MARK: - Private

  private func setupRoutes(server: HTTPServer) async {
    let handler = RequestHandler(mapServer: self)

    await server.appendRoute("GET /index.html", to: handler)
    await server.appendRoute("GET /maplibre-gl.js", to: handler)
    await server.appendRoute("GET /maplibre-gl.css", to: handler)
    await server.appendRoute("GET /pmtiles.js", to: handler)
    await server.appendRoute("GET /map.js", to: handler)
    await server.appendRoute("GET /functions.js", to: handler)
    await server.appendRoute("GET /base.json", to: handler)
    await server.appendRoute("GET /glyphs/*", to: handler)
    await server.appendRoute("GET /sprites/*", to: handler)
    await server.appendRoute("GET /tiles/*", to: handler)
    await server.appendRoute("GET /geojson/*", to: handler)
    await server.appendRoute("GET /pmtiles/*", to: handler)
    await server.appendRoute("GET /layers/*", to: handler)
    await server.appendRoute("GET /assets/*", to: handler)
  }

  // MARK: - Handler methods

  func handleStaticFile(path: String) async throws -> HTTPResponse {
    let filename = path.hasPrefix("/") ? String(path.dropFirst()) : path

    // библиотеки загружаются через LibraryManager
    if let libraryPath = await libraryFilePath(for: filename) {
      guard FileManager.default.fileExists(atPath: libraryPath.path) else {
        return HTTPResponse(statusCode: .notFound)
      }
      let data = try Data(contentsOf: libraryPath)
      let contentType = mimeType(for: filename)
      return HTTPResponse(
        statusCode: .ok,
        headers: [.contentType: contentType],
        body: data
      )
    }

    // остальные файлы из www
    let wwwPath = await resourceManager.wwwPath
    let filePath = wwwPath.appendingPathComponent(filename)

    guard FileManager.default.fileExists(atPath: filePath.path) else {
      return HTTPResponse(statusCode: .notFound)
    }

    let data = try Data(contentsOf: filePath)
    let contentType = mimeType(for: filename)
    return HTTPResponse(
      statusCode: .ok,
      headers: [.contentType: contentType],
      body: data
    )
  }

  private func libraryFilePath(for filename: String) async -> URL? {
    let libraryManager = resourceManager.libraryManager
    switch filename {
    case "maplibre-gl.js":
      return await libraryManager.maplibreGLPath(file: "maplibre-gl.js")
    case "maplibre-gl.css":
      return await libraryManager.maplibreGLPath(file: "maplibre-gl.css")
    case "pmtiles.js":
      return await libraryManager.pmtilesPath(file: "pmtiles.js")
    default:
      return nil
    }
  }

  func handleStyle() async throws -> HTTPResponse {
    let wwwPath = await resourceManager.wwwPath
    let filePath = wwwPath.deletingLastPathComponent().appendingPathComponent("base.json")

    guard FileManager.default.fileExists(atPath: filePath.path) else {
      return HTTPResponse(statusCode: .notFound)
    }

    var data = try Data(contentsOf: filePath)

    if let port,
       var jsonString = String(data: data, encoding: .utf8) {
      jsonString = jsonString.replacingOccurrences(of: "localhost:8080", with: "localhost:\(port)")
      if let modifiedData = jsonString.data(using: .utf8) {
        data = modifiedData
      }
    }

    return HTTPResponse(
      statusCode: .ok,
      headers: [.contentType: "application/json"],
      body: data
    )
  }

  func handleGlyphs(path: String) async throws -> HTTPResponse {
    let components = path.split(separator: "/").map(String.init)
    guard components.count >= 3 else {
      return HTTPResponse(statusCode: .badRequest)
    }

    let fontstack = components[1...components.count - 2].joined(separator: "/")
    let range = components.last ?? ""

    let resourcesPath = await resourceManager.resourcesPath
    let glyphPath = resourcesPath
      .appendingPathComponent("glyphs")
      .appendingPathComponent(fontstack)
      .appendingPathComponent(range)

    guard FileManager.default.fileExists(atPath: glyphPath.path) else {
      return HTTPResponse(statusCode: .notFound)
    }

    let data = try Data(contentsOf: glyphPath)
    return HTTPResponse(
      statusCode: .ok,
      headers: [.contentType: "application/x-protobuf"],
      body: data
    )
  }

  func handleSprites(path: String) async throws -> HTTPResponse {
    let filename = path.replacingOccurrences(of: "/sprites/", with: "")

    let resourcesPath = await resourceManager.resourcesPath
    let spritePath = resourcesPath
      .appendingPathComponent("sprites")
      .appendingPathComponent(filename)

    guard FileManager.default.fileExists(atPath: spritePath.path) else {
      return HTTPResponse(statusCode: .notFound)
    }

    let data = try Data(contentsOf: spritePath)
    let contentType = mimeType(for: filename)
    return HTTPResponse(
      statusCode: .ok,
      headers: [.contentType: contentType],
      body: data
    )
  }

  func handleTiles(path: String) async throws -> HTTPResponse {
    let components = path.split(separator: "/").map(String.init)
    guard components.count == 5,
          let z = Int(components[2]),
          let x = Int(components[3]),
          let yWithExt = components[4].split(separator: ".").first,
          let y = Int(yWithExt) else {
      return HTTPResponse(statusCode: .badRequest)
    }

    let sourceId = components[1]

    guard let source = mbTilesSources[sourceId] else {
      return HTTPResponse(statusCode: .notFound)
    }

    guard let tileData = await getTileDedup(source: source, z: z, x: x, y: y) else {
      return HTTPResponse(statusCode: .notFound)
    }

    return HTTPResponse(
      statusCode: .ok,
      headers: [
        .contentType: "application/x-protobuf",
        .contentEncoding: "gzip"
      ],
      body: tileData
    )
  }

  private func getTileDedup(source: MBTilesSource, z: Int, x: Int, y: Int) async -> Data? {
    let key = "\(source.id)-\(z)-\(x)-\(y)"

    if let existingTask = pendingTileRequests[key] {
      return await existingTask.value
    }

    let task = Task<Data?, Never> { [sqliteManager, path = source.path] in
      sqliteManager.getTile(path: path, z: z, x: x, y: y)
    }

    pendingTileRequests[key] = task
    let result = await task.value
    pendingTileRequests.removeValue(forKey: key)

    return result
  }

  func handleGeoJSON(path: String) async throws -> HTTPResponse {
    let filename = path.replacingOccurrences(of: "/geojson/", with: "")
    let sourceId = filename.replacingOccurrences(of: ".json", with: "")

    guard let source = geoJSONSources[sourceId] else {
      return HTTPResponse(statusCode: .notFound)
    }

    do {
      let data = try source.getDataBytes()
      return HTTPResponse(
        statusCode: .ok,
        headers: [.contentType: "application/json"],
        body: data
      )
    } catch {
      return HTTPResponse(statusCode: .internalServerError)
    }
  }

  func handlePMTiles(path: String) async throws -> HTTPResponse {
    let filename = path.replacingOccurrences(of: "/pmtiles/", with: "")
    let sourceId = filename.replacingOccurrences(of: ".pmtiles", with: "")

    guard let source = pmTilesSources[sourceId],
          source.url.isFileURL else {
      return HTTPResponse(statusCode: .notFound)
    }

    guard FileManager.default.fileExists(atPath: source.url.path) else {
      return HTTPResponse(statusCode: .notFound)
    }

    let data = try Data(contentsOf: source.url)
    return HTTPResponse(
      statusCode: .ok,
      headers: [.contentType: "application/octet-stream"],
      body: data
    )
  }

  func handleLayers(path: String) async throws -> HTTPResponse {
    let filename = path.replacingOccurrences(of: "/layers/", with: "")

    let wwwPath = await resourceManager.wwwPath
    let layersPath = wwwPath
      .deletingLastPathComponent()
      .appendingPathComponent("layers")
      .appendingPathComponent(filename)

    guard FileManager.default.fileExists(atPath: layersPath.path) else {
      return HTTPResponse(statusCode: .notFound)
    }

    let data = try Data(contentsOf: layersPath)
    return HTTPResponse(
      statusCode: .ok,
      headers: [.contentType: "application/json"],
      body: data
    )
  }

  func handleAssets(path: String) async throws -> HTTPResponse {
    let filename = path.replacingOccurrences(of: "/assets/", with: "")

    let wwwPath = await resourceManager.wwwPath
    let assetsPath = wwwPath
      .appendingPathComponent("images")
      .appendingPathComponent(filename)

    guard FileManager.default.fileExists(atPath: assetsPath.path) else {
      return HTTPResponse(statusCode: .notFound)
    }

    let data = try Data(contentsOf: assetsPath)
    let contentType = mimeType(for: filename)
    return HTTPResponse(
      statusCode: .ok,
      headers: [.contentType: contentType],
      body: data
    )
  }

  // MARK: - Helpers

  private func findAvailablePort() async throws(MapServerError) -> Int {
    for port in 8080...8180 {
      if await isPortAvailable(port) {
        return port
      }
    }
    throw .noAvailablePort
  }

  private func isPortAvailable(_ port: Int) async -> Bool {
    let sock = socket(AF_INET, SOCK_STREAM, 0)
    guard sock >= 0 else { return false }
    defer { close(sock) }

    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = in_port_t(port).bigEndian
    addr.sin_addr.s_addr = INADDR_LOOPBACK.bigEndian

    let result = withUnsafePointer(to: &addr) { ptr in
      ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
        bind(sock, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
      }
    }

    return result == 0
  }

  private nonisolated func mimeType(for filename: String) -> String {
    let ext = (filename as NSString).pathExtension.lowercased()
    switch ext {
    case "html": return "text/html"
    case "css": return "text/css"
    case "js": return "application/javascript"
    case "json": return "application/json"
    case "png": return "image/png"
    case "jpg", "jpeg": return "image/jpeg"
    case "svg": return "image/svg+xml"
    case "pbf": return "application/x-protobuf"
    default: return "application/octet-stream"
    }
  }
}

/// Ошибки сервера
public enum MapServerError: Error {
  case noAvailablePort
  case serverNotRunning
}

// MARK: - Request Handler

private final class RequestHandler: HTTPHandler, @unchecked Sendable {
  private let mapServer: MapServer

  init(mapServer: MapServer) {
    self.mapServer = mapServer
  }

  func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
    let path = request.path

    if path == "/base.json" {
      return try await mapServer.handleStyle()
    }

    if path.hasPrefix("/glyphs/") {
      return try await mapServer.handleGlyphs(path: path)
    }

    if path.hasPrefix("/sprites/") {
      return try await mapServer.handleSprites(path: path)
    }

    if path.hasPrefix("/tiles/") {
      return try await mapServer.handleTiles(path: path)
    }

    if path.hasPrefix("/geojson/") {
      return try await mapServer.handleGeoJSON(path: path)
    }

    if path.hasPrefix("/pmtiles/") {
      return try await mapServer.handlePMTiles(path: path)
    }

    if path.hasPrefix("/layers/") {
      return try await mapServer.handleLayers(path: path)
    }

    if path.hasPrefix("/assets/") {
      return try await mapServer.handleAssets(path: path)
    }

    // static files
    return try await mapServer.handleStaticFile(path: path)
  }
}
