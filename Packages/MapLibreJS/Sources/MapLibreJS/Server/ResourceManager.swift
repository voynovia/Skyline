import Foundation
import ZIPFoundation

/// Менеджер ресурсов карты (распаковка ZIP, пути к ресурсам)
public actor ResourceManager {
  private let bundle: Bundle
  private var _resourcesPath: URL?
  private var _wwwPath: URL?

  /// Менеджер JavaScript библиотек (MapLibre GL, PMTiles)
  public let libraryManager = LibraryManager()

  /// Путь к распакованным ресурсам (глифы, спрайты, стили)
  public var resourcesPath: URL {
    get async {
      if let path = _resourcesPath {
        return path
      }
      let path = try? await prepareResources()
      return path ?? applicationSupportPath.appendingPathComponent("resources")
    }
  }

  /// Путь к www файлам (HTML, JS, CSS)
  public var wwwPath: URL {
    get async {
      if let path = _wwwPath {
        return path
      }
      _ = await resourcesPath
      return _wwwPath ?? bundleWWWPath
    }
  }

  private var applicationSupportPath: URL {
    let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    let appSupport = paths[0].appendingPathComponent("MapLibreJS")
    try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
    return appSupport
  }

  private var bundleWWWPath: URL {
    bundle.bundleURL
      .appendingPathComponent("Contents")
      .appendingPathComponent("Resources")
      .appendingPathComponent("www")
  }

  private var bundleResourcesZipPath: URL? {
    bundle.url(forResource: "resources", withExtension: "zip")
  }

  private var versionFilePath: URL {
    applicationSupportPath.appendingPathComponent("resources_version.txt")
  }

  /// Инициализация с указанием бандла
  public init(bundle: Bundle? = nil) {
    self.bundle = bundle ?? Bundle.module
  }

  /// Подготовка ресурсов (распаковка ZIP если нужно, загрузка библиотек)
  @discardableResult
  public func prepareResources() async throws -> URL {
    _wwwPath = findWWWPath()

    // загрузка JavaScript библиотек с CDN
    try await libraryManager.ensureLibraries()

    let targetPath = applicationSupportPath.appendingPathComponent("resources")

    let currentVersion = bundleResourcesVersion()
    let installedVersion = installedResourcesVersion()

    if currentVersion == installedVersion,
       FileManager.default.fileExists(atPath: targetPath.path) {
      _resourcesPath = targetPath
      return targetPath
    }

    guard let zipPath = bundleResourcesZipPath else {
      let bundleResources = findBundleResourcesPath()
      _resourcesPath = bundleResources
      return bundleResources
    }

    if FileManager.default.fileExists(atPath: targetPath.path) {
      try FileManager.default.removeItem(at: targetPath)
    }

    try FileManager.default.createDirectory(at: targetPath, withIntermediateDirectories: true)
    try FileManager.default.unzipItem(at: zipPath, to: targetPath)

    try currentVersion.write(to: versionFilePath, atomically: true, encoding: .utf8)

    _resourcesPath = targetPath
    return targetPath
  }

  // MARK: - Private

  private func findWWWPath() -> URL {
    let possiblePaths = [
      bundle.resourceURL?.appendingPathComponent("www"),
      bundle.bundleURL.appendingPathComponent("www"),
      bundle.bundleURL.appendingPathComponent("Contents/Resources/www"),
      Bundle.main.resourceURL?.appendingPathComponent("MapLibreJS_MapLibreJS.bundle/Contents/Resources/www")
    ]

    for path in possiblePaths {
      if let path, FileManager.default.fileExists(atPath: path.path) {
        return path
      }
    }

    return bundle.bundleURL.appendingPathComponent("www")
  }

  private func findBundleResourcesPath() -> URL {
    let possiblePaths = [
      bundle.resourceURL?.appendingPathComponent("resources"),
      bundle.bundleURL.appendingPathComponent("resources"),
      bundle.bundleURL.appendingPathComponent("Contents/Resources/resources")
    ]

    for path in possiblePaths {
      if let path, FileManager.default.fileExists(atPath: path.path) {
        return path
      }
    }

    return applicationSupportPath.appendingPathComponent("resources")
  }

  private func bundleResourcesVersion() -> String {
    guard let zipPath = bundleResourcesZipPath else {
      return "no-zip"
    }

    let attributes = try? FileManager.default.attributesOfItem(atPath: zipPath.path)
    if let modDate = attributes?[.modificationDate] as? Date {
      return String(modDate.timeIntervalSince1970)
    }

    return "unknown"
  }

  private func installedResourcesVersion() -> String {
    guard let version = try? String(contentsOf: versionFilePath, encoding: .utf8) else {
      return ""
    }
    return version.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

/// Ошибки менеджера ресурсов
public enum ResourceManagerError: Error {
  case resourcesNotFound
  case unzipFailed
}
