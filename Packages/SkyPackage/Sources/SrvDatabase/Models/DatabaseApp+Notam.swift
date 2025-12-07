//
//  DatabaseApp+Notam.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation
import GRDB
import Extensions

public extension DatabaseApp {
 
  struct Notam: Codable, Equatable, FetchableRecord, PersistableRecord, Sendable {
    public let sphere: String
    public let format: String
    public let type: String
    public let text: String
    public let provider: String
    public let uniformAbbreviation: String
    public let validTime: Date
    
    public var ago: String {
      Date().timeIntervalSince(fromDate).ago
    }
    
    // header
    public let number: String
    // A-SECTION
    public let icao: String
    // B-SECTION
    public let fromDate: Date
    // C-SECTION
    public let toDate: Date?
    public let toString: String?
    // D-SECTION
    public let schedule: String?
    // E-SECTION
    public let eCode: String
    // F-SECTION
    public let lowerLimit: String?
    // G-SECTION
    public let upperLimit: String?
    // Q-SECTION
    public let fir: String
    public let qCode: String
    public let fromLevel: Int?
    public let toLevel: Int?
    
    public init(sphere: String, format: String, text: String, provider: String, uniformAbbreviation: String, validTime: Date, number: String, icao: String, fromDate: Date, toDate: Date?, toString: String?, schedule: String?, eCode: String, lowerLimit: String?, upperLimit: String?, fir: String, qCode: String, fromLevel: Int?, toLevel: Int?) {
      self.sphere = sphere
      self.format = format
      self.type = number[0]
      self.text = text
      self.provider = provider
      self.uniformAbbreviation = uniformAbbreviation
      self.validTime = validTime
      self.number = number
      self.icao = icao
      self.fromDate = fromDate
      self.toDate = toDate
      self.toString = toString
      self.schedule = schedule
      self.eCode = eCode
      self.lowerLimit = lowerLimit
      self.upperLimit = upperLimit
      self.fir = fir
      self.qCode = qCode
      self.fromLevel = fromLevel
      self.toLevel = toLevel
    }
  }
  
  func saveNotams(notams: [Notam], list: [String], sphere: String) throws {
    try self.dbWriter.write { db in
      try DatabaseApp.Notam.filter(
        sql: "icao IN (?) AND sphere = ?",
        arguments: [list.joined(separator: ","), sphere]
      )
      .deleteAll(db)
      try notams.forEach({ try $0.save(db) })
    }
  }
  
  func getNotamIcaoList(sphere: String) throws -> [String] {
    return try self.dbWriter.read { db in
      return try String.fetchAll(db, sql: "SELECT icao FROM notam WHERE sphere = ?", arguments: [sphere])
    }
  }
  
  func getNotams(icaoList: [String], sphere: String, formats: [String]) async throws -> [Notam] {
    return try await self.dbWriter.read { db in
      let sql = """
      SELECT * FROM notam WHERE icao IN (\(icaoList.unique().sql)) AND format IN (\(formats.sql)) AND sphere = '\(sphere)'
      """
      return try Notam.fetchAll(db, sql: sql)
    }
  }
  
}
