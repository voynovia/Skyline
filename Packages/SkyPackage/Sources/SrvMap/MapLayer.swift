import Foundation

public enum MapLayer: String, CaseIterable, Sendable {
  case topography
  case hypsometry

  public var sourceId: String {
    switch self {
    case .topography: return "topo"
    case .hypsometry: return "hypsometry"
    }
  }

  public var layerConfigURL: URL? {
    let filename: String
    switch self {
    case .topography: filename = "topo"
    case .hypsometry: filename = "hypsometry"
    }
    return Bundle.module.url(forResource: filename, withExtension: "json", subdirectory: "Resources/layers")
  }
}
