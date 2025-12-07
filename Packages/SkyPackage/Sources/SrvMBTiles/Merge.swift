//
//  File.swift
//  
//
//  Created by Igor Voynov on 12. 5. 24.
//

import Foundation
import GRDB
import Gzip
import SwiftProtobuf

public struct MBTilesMerge {
  
  let group = DispatchGroup()
  let queue = DispatchQueue(label: #function+".queue", attributes: .concurrent)
  
  public init() {}
  
  public func merge(sourceUrls: [URL], destinationUrl: URL, name: String) throws  {
#if DEBUG
    let startTime = CFAbsoluteTimeGetCurrent()
    defer { print("\(#function): \(String(format: "%.5f", CFAbsoluteTimeGetCurrent() - startTime)) seconds") }
#endif
    
    let fileManager = FileManager.default
    
    let tempFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent(name+".mbtiles")
    if fileManager.fileExists(atPath: tempFileUrl.path) {
      try fileManager.removeItem(at: tempFileUrl)
    }
    
    // create destination db
    let destinationQueue = try DatabaseQueue(path: tempFileUrl.path)
    try destinationQueue.inDatabase { db in
      try db.execute(sql: """
      CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);
      CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row);
      CREATE TABLE metadata (name text, value text);
      CREATE UNIQUE INDEX name_index ON metadata (name);
      INSERT INTO metadata (name, value) VALUES ('name', ?);
      INSERT INTO metadata (name, value) VALUES ('type', 'overlay');
      INSERT INTO metadata (name, value) VALUES ('version', '2');
      INSERT INTO metadata (name, value) VALUES ('format', 'pbf');
      """, arguments: [name])
    }
    
//    var allBounds: [String] = []
    var vectorLayers: [VectorLayer] = []
    var fileNames: [String] = []
    
    for url in sourceUrls {
      fileNames.append(url.lastPathComponent)
      let sourceQueue = try DatabaseQueue(path: url.path)
//      // get bounds
//      guard let bounds = try await sourceQueue.read({ db in
//        try String.fetchOne(db, sql: "SELECT value FROM metadata WHERE name = ?;", arguments: ["bounds"])
//      }) else {
//        continue
//      }
//      allBounds.append(bounds)
      
      // get jsons
      guard let jsonStr = try sourceQueue.read({ db in
        try String.fetchOne(db, sql: "SELECT value FROM metadata WHERE name = ?;", arguments: ["json"])
      }), let data = jsonStr.data(using: .utf8) else {
        throw "no json: \(url.lastPathComponent)"
      }
      let json = try JSONDecoder().decode(Json.self, from: data)
      vectorLayers.append(contentsOf: json.vectorLayers)
      
      try destinationQueue.inDatabase { db in
        // attach source db
        try db.execute(sql: "ATTACH DATABASE ? AS fromMerge;", arguments: [sourceQueue.path])
                        
        // search for matching tiles
        let overlaps = try Tile.fetchAll(db, sql: """
        SELECT
          source.zoom_level, source.tile_column, source.tile_row,
          source.tile_data AS tile_data_source,
          destination.tile_data AS tile_data_destination
        FROM
          tiles AS destination
        JOIN
          fromMerge.tiles AS source
        ON
          source.zoom_level = destination.zoom_level
          AND source.tile_column = destination.tile_column
          AND source.tile_row = destination.tile_row
        """)
        if !overlaps.isEmpty {
          var updateQueries: [(data: Data, zoomLevel: Int, tileColumn: Int, tileRow: Int)] = []
          var errors: [Error] = []
          for tile in overlaps {
            queue.async(group: group) {
              do {
                let messageSource = try getMessage(data: tile.dataSource)
                var messageDestination = try getMessage(data: tile.dataDestination)
                var mergedLayers: [String: VectorTile_Tile.Layer] = [:]
                let layers = messageSource.layers + messageDestination.layers
                for layer in layers {
                  if var existingLayer = mergedLayers[layer.name] {
                    existingLayer.features.append(contentsOf: layer.features)
                    existingLayer.values.append(contentsOf: layer.values)
                    existingLayer.keys = Array(Set(existingLayer.keys + layer.keys))
                    mergedLayers[layer.name] = existingLayer
                  } else {
                    mergedLayers[layer.name] = layer
                  }
                }
                messageDestination.layers = Array(mergedLayers.values)
                let data = try messageDestination.serializedData()
                updateQueries.append((data: data, zoomLevel: tile.zoomLevel, tileColumn: tile.tileColumn, tileRow: tile.tileTow))
  //              try db.execute(sql: "UPDATE tiles SET tile_data = ? WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?;",
  //                             arguments: [data, tile.zoomLevel, tile.tileColumn, tile.tileTow])
              } catch {
                errors.append(error)
              }
            }
          }
          group.wait()
          if !errors.isEmpty {
            for error in errors {
              print("Error: \(error)")
            }
            throw errors[0]
          }
          if !updateQueries.isEmpty {
            var sql = ""
            var arguments = StatementArguments()
            for query in updateQueries {
              sql += "UPDATE tiles SET tile_data = ? WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?;"
              _ = arguments.append(contentsOf: [query.data, query.zoomLevel, query.tileColumn, query.tileRow])
            }
            try db.execute(sql: sql, arguments: arguments)
          }
        }
                  
        // inserting data from one table to another and detach source db
        try db.execute(sql: """
        INSERT INTO tiles (zoom_level, tile_column, tile_row, tile_data)
        SELECT zoom_level, tile_column, tile_row, tile_data
        FROM fromMerge.tiles WHERE NOT EXISTS (
          SELECT 1 FROM tiles
          WHERE tiles.zoom_level = fromMerge.tiles.zoom_level
          AND tiles.tile_column = fromMerge.tiles.tile_column
          AND tiles.tile_row = fromMerge.tiles.tile_row
        );
        DETACH DATABASE fromMerge;
        """)
      }
    }
    
    // create json
    let (mergedLayers, minzoom, maxzoom) = mergeVectorLayers(vectorLayers: vectorLayers)
    let jsonData = try JSONEncoder().encode(Json(vectorLayers: mergedLayers))
    let jsonStr = String(data: jsonData, encoding: .utf8)
    
//    let (bounds, antimeridianAdjustedBounds, center) = try getBounds(allBounds: allBounds)
    try destinationQueue.inDatabase { db in
      try db.execute(
        sql: """
        INSERT INTO metadata (name, value) VALUES ('description', ?);
        INSERT INTO metadata (name, value) VALUES ('minzoom', ?);
        INSERT INTO metadata (name, value) VALUES ('maxzoom', ?);
        INSERT INTO metadata (name, value) VALUES ('json', ?);
        ANALYZE;
        """,
        arguments: [
          fileNames.joined(separator: ","),
          minzoom,
          maxzoom,
          jsonStr
//          "bounds", bounds,
//          "antimeridian_adjusted_bounds", antimeridianAdjustedBounds,
//          "center", center,
        ]
      )
    }
    
    // переносим файл из временной папки в назначение
    if fileManager.fileExists(atPath: destinationUrl.path) {
      try fileManager.removeItem(at: destinationUrl)
    }
    try fileManager.createDirectory(at: destinationUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
    try fileManager.moveItem(at: tempFileUrl, to: destinationUrl)    
  }
  
  private func getMessage(data: Data) throws -> VectorTile_Tile {
    var dataSource = data
    if dataSource.isGzipped {
      dataSource = try dataSource.gunzipped()
    }
    return try VectorTile_Tile(serializedBytes: dataSource)
  }
  
  private func mergeVectorLayers(vectorLayers: [VectorLayer]) -> ([VectorLayer], Int, Int) {
    var minzoom = Int.max
    var maxzoom = Int.min
    var dict: [String: VectorLayer] = [:]
    for vector in vectorLayers {
      if let existingVector = dict[vector.id] {
        let minZoom = min(existingVector.minzoom, vector.minzoom)
        if minZoom < minzoom {
          minzoom = minZoom
        }
        let maxZoom = max(existingVector.maxzoom, vector.maxzoom)
        if maxZoom > maxzoom {
          maxzoom = maxZoom
        }
        dict[vector.id] = VectorLayer(id: vector.id, description: vector.description, minzoom: minZoom, maxzoom: maxZoom)
      } else {
        dict[vector.id] = vector
      }
    }
    return (Array(dict.values), minzoom, maxzoom)
  }
  
  private func getBounds(allBounds: [String]) throws -> (String, String, String) {
    var minLat = Double.infinity
    var minLon = Double.infinity
    var maxLat = -Double.infinity
    var maxLon = -Double.infinity
    for bounds in allBounds {
      let coordinates = bounds.split(separator: ",").compactMap { Double($0) }
      if coordinates.count != 4 {
        throw "wrong coordinates: \(bounds)"
      }
      minLat = min(minLat, coordinates[1], coordinates[3])
      minLon = min(minLon, coordinates[0], coordinates[2])
      maxLat = max(maxLat, coordinates[1], coordinates[3])
      maxLon = max(maxLon, coordinates[0], coordinates[2])
    }
    let bounds = "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    
    // Check if the bounds cross the antimeridian
    if minLon > maxLon {
        // Adjust the bounds to account for the antimeridian
        let temp = minLon
        minLon = maxLon
        maxLon = temp
    }
    let antimeridianAdjustedBounds = "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    
    let centerLat = (minLat + maxLat) / 2
    let centerLon = (minLon + maxLon) / 2
    let center = "\(centerLon),\(centerLat)"
    
    return (bounds, antimeridianAdjustedBounds, center)
  }
  
}

extension String: @retroactive LocalizedError {
  public var errorDescription: String? { return self }
}
