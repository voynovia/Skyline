//
//  UTCTime.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation

internal struct UTCTime {
  // григорианский календарь для всех операций с датами
  static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    calendar.locale = Locale(identifier: "en_US_POSIX")
    TimeZone.ReferenceType.default = calendar.timeZone
    return calendar
  }()
}
