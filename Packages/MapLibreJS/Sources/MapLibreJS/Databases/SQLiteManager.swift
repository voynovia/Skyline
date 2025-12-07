import SQLite3
import Foundation
import Synchronization

// @unchecked Sendable: NSCache is thread-safe internally
final class SQLiteManager: @unchecked Sendable {

  private let tileCache: NSCache<NSString, NSData> = {
    let cache = NSCache<NSString, NSData>()
    cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    return cache
  }()

  private let poolsMutex = Mutex<[String: DBPool]>([:])

  private func getPool(path: URL) -> DBPool? {
    let key = path.path

    if let pool = poolsMutex.withLock({ $0[key] }) {
      return pool
    }

    guard FileManager.default.fileExists(atPath: key) else {
      return nil
    }

    let pool = DBPool(dbPath: key, maxConnections: max(2, ProcessInfo().activeProcessorCount / 2))
    poolsMutex.withLock { $0[key] = pool }
    return pool
  }

  /// Получение тайла из MBTiles по пути к файлу
  func getTile(path: URL, z: Int, x: Int, y: Int) -> Data? {
    let modDate = (try? FileManager.default.attributesOfItem(atPath: path.path)[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
    let cacheKey = "\(path.path)-v\(Int(modDate))-\(z)-\(x)-\(y)" as NSString
    if let cachedTile = tileCache.object(forKey: cacheKey) as Data? {
      return cachedTile
    }

    guard let dbPool = getPool(path: path) else {
      return nil
    }
    guard let db = dbPool.getConnection() else {
      return nil
    }
    defer {
      dbPool.returnConnection(db)
    }

    let yTMS = (1 << z) - 1 - y // векторные MBTiles используют TMS-систему
    let query = "SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?"
    var stmt: OpaquePointer?
    var tileData: Data?

    if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
      sqlite3_bind_int(stmt, 1, Int32(z))
      sqlite3_bind_int(stmt, 2, Int32(x))
      sqlite3_bind_int(stmt, 3, Int32(yTMS))

      if sqlite3_step(stmt) == SQLITE_ROW {
        let bytes = sqlite3_column_blob(stmt, 0)
        let size = sqlite3_column_bytes(stmt, 0)
        if let bytes {
          tileData = Data(bytes: bytes, count: Int(size))
        }
      }
    }

    sqlite3_finalize(stmt)

    if let tileData {
      tileCache.setObject(tileData as NSData, forKey: cacheKey, cost: tileData.count)
    }

    return tileData
  }

  /// Закрытие пула для указанного пути
  func closePool(path: URL) {
    let key = path.path
    poolsMutex.withLock { _ = $0.removeValue(forKey: key) }
  }
}

// @unchecked Sendable: thread-safety через DispatchQueue с барьером
private final class DBPool: @unchecked Sendable {

  private let queue = DispatchQueue(label: "dbpool.queue", attributes: .concurrent)
  private var availableConnections: [OpaquePointer] = []
  private let maxConnections: Int
  private let dbPath: String

  init(dbPath: String, maxConnections: Int = 5) {
    self.dbPath = dbPath
    self.maxConnections = maxConnections
    initializePool()
  }

  deinit {
    queue.sync(flags: .barrier) {
      for db in availableConnections {
        sqlite3_close(db)
      }
      availableConnections.removeAll()
    }
  }

  private func initializePool() {
    queue.sync(flags: .barrier) {
      for _ in 0..<maxConnections {
        if let db = Self.openConnection(dbPath: dbPath) {
          availableConnections.append(db)
        }
      }
    }
  }

  private static func openConnection(dbPath: String) -> OpaquePointer? {
    var db: OpaquePointer?
    if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
      sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nil, nil, nil)
      return db
    }
    return nil
  }

  func getConnection() -> OpaquePointer? {
    queue.sync(flags: .barrier) {
      if !availableConnections.isEmpty {
        return availableConnections.removeFirst()
      }
      return nil
    }
  }

  func returnConnection(_ db: OpaquePointer) {
    queue.sync(flags: .barrier) {
      self.availableConnections.append(db)
    }
  }
}
