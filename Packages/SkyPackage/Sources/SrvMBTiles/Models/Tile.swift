//
//  Tile.swift
//  geojsonMerge
//
//  Created by Igor Voynov on 7. 5. 24.
//

import Foundation
import GRDB

struct Tile: Codable, FetchableRecord, PersistableRecord {
  var zoomLevel: Int
  var tileColumn: Int
  var tileTow: Int
  
  var dataSource: Data
  var dataDestination: Data
  
  enum CodingKeys: String, CodingKey {
    case zoomLevel = "zoom_level"
    case tileColumn = "tile_column"
    case tileTow = "tile_row"
    
    case dataSource = "tile_data_source"
    case dataDestination = "tile_data_destination"
  }
}

struct TileId: Hashable {
  var zoomLevel: Int
  var tileColumn: Int
  var tileTow: Int
}
