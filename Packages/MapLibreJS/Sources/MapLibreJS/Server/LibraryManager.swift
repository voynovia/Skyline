import Foundation

/// Конфигурация версий библиотек
public struct LibraryVersions: Codable, Sendable {
  public var maplibreGL: String
  public var pmtiles: String

  public static let `default` = LibraryVersions(
    maplibreGL: "5.14.0",
    pmtiles: "4.3.0"
  )
}

/// Менеджер загрузки JavaScript библиотек
public actor LibraryManager {
  private let configPath: URL

  /// Текущие версии библиотек
  public private(set) var versions: LibraryVersions

  private var libsPath: URL {
    configPath.appendingPathComponent("libs")
  }

  private var versionsFilePath: URL {
    configPath.appendingPathComponent("current_versions.json")
  }

  public init() {
    let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    configPath = paths[0].appendingPathComponent("MapLibreJS")
    try? FileManager.default.createDirectory(at: configPath, withIntermediateDirectories: true)

    if let data = try? Data(contentsOf: configPath.appendingPathComponent("current_versions.json")),
       let saved = try? JSONDecoder().decode(LibraryVersions.self, from: data) {
      versions = saved
    } else {
      versions = .default
    }
  }

  /// Проверить и скачать библиотеки если нужно
  public func ensureLibraries() async throws(LibraryManagerError) {
    try await ensureMaplibreGL()
    try await ensurePMTiles()
    try saveVersions()
  }

  /// Путь к файлу библиотеки MapLibre GL
  public func maplibreGLPath(file: String) -> URL {
    libsPath
      .appendingPathComponent("maplibre-gl")
      .appendingPathComponent(versions.maplibreGL)
      .appendingPathComponent(file)
  }

  /// Путь к файлу библиотеки PMTiles
  public func pmtilesPath(file: String) -> URL {
    libsPath
      .appendingPathComponent("pmtiles")
      .appendingPathComponent(versions.pmtiles)
      .appendingPathComponent(file)
  }

  /// Обновить версию MapLibre GL
  public func updateMaplibreGL(to version: String) async throws(LibraryManagerError) {
    versions.maplibreGL = version
    try await ensureMaplibreGL()
    try saveVersions()
  }

  /// Обновить версию PMTiles
  public func updatePMTiles(to version: String) async throws(LibraryManagerError) {
    versions.pmtiles = version
    try await ensurePMTiles()
    try saveVersions()
  }

  // MARK: - Private

  private func ensureMaplibreGL() async throws(LibraryManagerError) {
    let version = versions.maplibreGL
    let versionPath = libsPath
      .appendingPathComponent("maplibre-gl")
      .appendingPathComponent(version)

    let jsPath = versionPath.appendingPathComponent("maplibre-gl.js")
    let cssPath = versionPath.appendingPathComponent("maplibre-gl.css")

    if FileManager.default.fileExists(atPath: jsPath.path),
       FileManager.default.fileExists(atPath: cssPath.path) {
      return
    }

    do {
      try FileManager.default.createDirectory(at: versionPath, withIntermediateDirectories: true)
    } catch {
      throw .directoryCreationFailed
    }

    let jsURL = URL(string: "https://unpkg.com/maplibre-gl@\(version)/dist/maplibre-gl.js")!
    let cssURL = URL(string: "https://unpkg.com/maplibre-gl@\(version)/dist/maplibre-gl.css")!

    try await download(from: jsURL, to: jsPath)
    try await download(from: cssURL, to: cssPath)
  }

  private func ensurePMTiles() async throws(LibraryManagerError) {
    let version = versions.pmtiles
    let versionPath = libsPath
      .appendingPathComponent("pmtiles")
      .appendingPathComponent(version)

    let jsPath = versionPath.appendingPathComponent("pmtiles.js")

    if FileManager.default.fileExists(atPath: jsPath.path) {
      return
    }

    do {
      try FileManager.default.createDirectory(at: versionPath, withIntermediateDirectories: true)
    } catch {
      throw .directoryCreationFailed
    }

    let jsURL = URL(string: "https://unpkg.com/pmtiles@\(version)/dist/pmtiles.js")!
    try await download(from: jsURL, to: jsPath)
  }

  private func download(from url: URL, to destination: URL) async throws(LibraryManagerError) {
    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await URLSession.shared.data(from: url)
    } catch {
      throw .downloadFailed(url: url)
    }

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
      throw .downloadFailed(url: url)
    }

    do {
      try data.write(to: destination)
    } catch {
      throw .writeFailed
    }
  }

  private func saveVersions() throws(LibraryManagerError) {
    do {
      let data = try JSONEncoder().encode(versions)
      try data.write(to: versionsFilePath)
    } catch {
      throw .writeFailed
    }
  }
}

/// Ошибки менеджера библиотек
public enum LibraryManagerError: Error, LocalizedError {
  case downloadFailed(url: URL)
  case libraryNotFound(name: String)
  case directoryCreationFailed
  case writeFailed

  public var errorDescription: String? {
    switch self {
    case .downloadFailed(let url):
      return "Не удалось скачать библиотеку: \(url)"
    case .libraryNotFound(let name):
      return "Библиотека не найдена: \(name). Требуется подключение к интернету."
    case .directoryCreationFailed:
      return "Не удалось создать директорию для библиотек"
    case .writeFailed:
      return "Не удалось сохранить файл"
    }
  }
}
