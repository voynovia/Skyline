//
//  DateFormat.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation

public enum DateFormat: String {
  case yyyyMMddHHmmss = "yyyyMMddHHmmss"
  case yyyy_MM_dd = "yyyy-MM-dd"
  case HHmm = "HH:mm"
  case dMMM = "d MMM"
  case peopleDate = "MMM d, yyyy"
  case dayWithTime = "dd  MMMM  HH:mm"
  case DDMMYY = "ddMMYY"
  case hoursAndMinutes = "HHmm"
  case timeDate = "HH:mm ddMMMyyyy"
  case ddMMMyyyy = "dd MMM yyyy"
  case MMMd = "MMM d"
  case yyyyMMdd = "yyyyMMdd"
  case timeMonthDate = "HH:mm MMM d"
  
  case rfc3339 = "yyyy-MM-dd'T'HH:mm:ssZ"
}
