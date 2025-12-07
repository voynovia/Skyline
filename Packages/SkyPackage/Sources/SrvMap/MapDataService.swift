import Foundation
import ZIPFoundation

public actor MapDataService {
  public static let shared = MapDataService()

  private let topoURL = URL(string: "https://cdn.aeromap.app/map/Topography/20240118174606-99991231235959.zip")!
  private let hypsometryURL = URL(string: "https://cdn.aeromap.app/map/Hypsometry/20220609000000-99991231235959.zip")!

  private var onStatusUpdate: (@Sendable (String) -> Void)?

  private init() {}

  public func setStatusHandler(_ handler: @escaping @Sendable (String) -> Void) {
    onStatusUpdate = handler
  }

  public func ensureTopography() async throws -> URL {
    try await ensureMBTiles(zipURL: topoURL, filename: "topo.mbtiles", displayName: "топографии")
  }

  public func ensureHypsometry() async throws -> URL {
    try await ensureMBTiles(zipURL: hypsometryURL, filename: "hypsometry.mbtiles", displayName: "рельефа")
  }

  private func ensureMBTiles(zipURL: URL, filename: String, displayName: String) async throws -> URL {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let mbtilesPath = documentsURL.appendingPathComponent(filename)

    if FileManager.default.fileExists(atPath: mbtilesPath.path) {
      return mbtilesPath
    }

    onStatusUpdate?("Загрузка \(displayName)...")
    let (zipData, _) = try await URLSession.shared.data(from: zipURL)

    let tempZipPath = documentsURL.appendingPathComponent("\(filename)_temp.zip")
    try zipData.write(to: tempZipPath)

    onStatusUpdate?("Распаковка \(displayName)...")
    try FileManager.default.unzipItem(at: tempZipPath, to: documentsURL)

    try? FileManager.default.removeItem(at: tempZipPath)

    guard FileManager.default.fileExists(atPath: mbtilesPath.path) else {
      throw MapDataError.fileNotFoundInArchive(filename)
    }

    return mbtilesPath
  }
}

public enum MapDataError: LocalizedError {
  case fileNotFoundInArchive(String)

  public var errorDescription: String? {
    switch self {
    case .fileNotFoundInArchive(let filename):
      return "\(filename) не найден в архиве"
    }
  }
}
