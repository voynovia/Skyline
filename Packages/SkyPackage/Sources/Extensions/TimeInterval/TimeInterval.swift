//
//  TimeInterval.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation

public extension TimeInterval {
 
  var ago: String {
    let endingDate = Date()
    let startingDate = endingDate.addingTimeInterval(-self)
    let calendar = Calendar.current
    
    let componentsNow = calendar.dateComponents([.hour, .minute, .second], from: startingDate, to: endingDate)
    
    var result = ""
    if let hour = componentsNow.hour, hour > 0 {
      result += String(hour) + "h"
//      result += "\(String(format: "%02d", hour))h"
    }
    if let minute = componentsNow.minute {
      if !result.isEmpty {
        result += " "
      }
      result += String(minute) + "m"
    }
    
    if result.isEmpty, let second = componentsNow.second {
      result += String(second) + "s"
    }
    return result + " ago"
  }
  
}
