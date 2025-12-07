import Foundation

public enum MapLayer: String, CaseIterable, Sendable {
  case topographyLight
  case topographyDark
  case hypsometry

  public var sourceId: String {
    switch self {
    case .topographyLight, .topographyDark: return "topo"
    case .hypsometry: return "hypsometry"
    }
  }

  public var layerConfigURL: URL? {
    let filename: String
    switch self {
    case .topographyLight: filename = "topo-light"
    case .topographyDark: filename = "topo-dark"
    case .hypsometry: filename = "hypsometry"
    }
    return Bundle.module.url(forResource: filename, withExtension: "json", subdirectory: "Resources/layers")
  }
}
