//
//  URL+Custom.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation

public extension URL {
  static func custom(_ folder: Folder) throws -> URL {
    return try folder.getUrl()
  }
}

public enum Folder {
  
  case value(_ value: String)
  case baseDirectory // system folder

  case databases

  public func getUrl() throws -> URL {
    let fileManager = FileManager.default
    var folder = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

    switch self {
    case .baseDirectory: break
    case .value(let value): folder.appendPathComponent(value)
    case .databases: folder.appendPathComponent("Databases")
    }
    
    if !fileManager.fileExists(atPath: folder.path) {
      try fileManager.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
    }
    return folder
  }
  
}
