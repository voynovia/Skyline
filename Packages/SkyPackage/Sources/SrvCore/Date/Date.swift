//
//  Date.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation
import Kronos

public extension Date {
    
  // получение текущего синхронизированного времени
  static var synchronized: Date {
    // проверяем, нужна ли ресинхронизация
    if TimeSync.needsResync {
      Task {
        await TimeSync.sync()
      }
    }
    return Clock.now ?? Date()
  }
  
  // проверка, синхронизировано ли время
  static var isSynchronized: Bool {
    Clock.now != nil
  }
  
  // MARK: - Calendar
  
  // компоненты даты в григорианском календаре utc
  func componentsUTC() -> DateComponents {
    UTCTime.calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second, .nanosecond],
      from: self
    )
  }
  
  // год в григорианском календаре
  var yearUTC: Int {
    UTCTime.calendar.component(.year, from: self)
  }
  
  // месяц в григорианском календаре
  var monthUTC: Int {
    UTCTime.calendar.component(.month, from: self)
  }
  
  // день в григорианском календаре
  var dayUTC: Int {
    UTCTime.calendar.component(.day, from: self)
  }
  
  // создание даты из компонентов в григорианском календаре utc
  static func fromUTC(year: Int, month: Int, day: Int,
                      hour: Int = 0, minute: Int = 0, second: Int = 0) -> Date? {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    return UTCTime.calendar.date(from: components)
  }
  
  // MARK: - Formatters
  
  private static func utcFormatter(format: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = UTCTime.calendar
    formatter.timeZone = UTCTime.calendar.timeZone
    formatter.locale = UTCTime.calendar.locale
    formatter.dateFormat = format
    return formatter
  }
  
  static func fromString(_ str: String?, format: DateFormat) -> Date? {
    if let str {
      return utcFormatter(format: format.rawValue).date(from: str)
    }
    return nil
  }
  
  var rfc3339: String {
    Self.utcFormatter(format: DateFormat.rfc3339.rawValue).string(from: self)
  }

}
