//
//  TimeSync.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation
import Kronos

public final class TimeSync {
  // интервал ресинхронизации - 1 час
  private static let resyncInterval: TimeInterval = 3600
  
  // ключ для сохранения времени последней синхронизации
  private static let lastSyncKey = "kronos.lastSyncTime"
  
  // первичная синхронизация при запуске
  public static func initialize() async {
    await sync()
    // проверка необходимости периодической ресинхронизации
    startPeriodicSync()
  }
  
  // синхронизация с ntp серверами
  public static func sync() async {
    await withCheckedContinuation { continuation in
      Clock.sync(first: { date,_ in
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastSyncKey)
        continuation.resume()
      }, completion: { date, _ in
        if let date {
          UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastSyncKey)
        }
      })
    }
  }
  
  // проверка, нужна ли ресинхронизация
  public static var needsResync: Bool {
    guard let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? TimeInterval else {
      return true
    }
    let timeSinceLastSync = Date().timeIntervalSince1970 - lastSync
    return timeSinceLastSync > resyncInterval
  }
  
  // запуск периодической синхронизации
  private static func startPeriodicSync() {
    Task {
      while true {        
        // ждём необходимый интервал
        try await Task.sleep(for: .seconds(resyncInterval))
        // ресинхронизация
        await sync()
      }
    }
  }
}
