//
//  Sequence+SQL.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation

public extension Sequence where Iterator.Element: StringProtocol {
  var sql: String {
    return map({ "'\($0)'" }).joined(separator: ", ")
  }  
}
