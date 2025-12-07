//
//  DatabaseApp.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation
import GRDB
import Extensions

public final class DatabaseApp: Sendable {
  
  public static let shared = DatabaseApp()
  
  internal let dbWriter: any DatabaseWriter
  
  private init() {
    do {
      let url = try URL.custom(.databases).appendingPathComponent("app.sqlite")
      print(url)
      dbWriter = try DatabaseQueue(path: url.path)
      try setup()
    } catch {
      fatalError(error.localizedDescription)
    }
  }
  
  private func setup() throws {
    var migrator = DatabaseMigrator()
#if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
#endif
    createNotamTable(migrator: &migrator)
    try migrator.migrate(dbWriter)
  }
  
  private func createNotamTable(migrator: inout DatabaseMigrator) {
    let tableName = DatabaseApp.Notam.databaseTableName
    migrator.registerMigration(#function) { db in
      try db.create(table: tableName) { t in
        t.column("number", .text).primaryKey()
        t.column("icao", .text).notNull()
        t.column("fromDate", .datetime).notNull()
        t.column("toDate", .datetime)
        t.column("toString", .text)
        t.column("schedule", .text)
        t.column("eCode", .text).notNull()
        t.column("lowerLimit", .text)
        t.column("upperLimit", .text)
        t.column("fir", .text)
        t.column("qCode", .text).notNull()
        t.column("fromLevel", .integer)
        t.column("toLevel", .integer)
        
        t.column("sphere", .text).notNull()
        t.column("format", .text).notNull()
        t.column("text", .text).notNull()
        t.column("type", .text).notNull()
        t.column("provider", .text).notNull()
        t.column("uniformAbbreviation", .text).notNull()
        t.column("validTime", .datetime).notNull()
      }
      try db.create(indexOn: tableName, columns: ["icao"])
    }
    
  }
}
