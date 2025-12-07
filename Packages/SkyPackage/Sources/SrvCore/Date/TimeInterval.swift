//
//  Intervals.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation

private enum Interval: TimeInterval {
  case second = 1
  case minute = 60
  case hour = 3600
  case day = 86400
  case week = 604800
}

public extension TimeInterval {
  static var second: TimeInterval { Interval.second.rawValue }
  static var minute: TimeInterval { Interval.minute.rawValue }
  static var hour: TimeInterval { Interval.hour.rawValue }
  static var day: TimeInterval { Interval.day.rawValue }
  static var week: TimeInterval { Interval.week.rawValue }
}

