//
//  String+Subscript.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation

public extension String {
  
  subscript (i: Int) -> String {
    return self[i ..< i + 1]
  }
  
  subscript (r: Range<Int>) -> String {
    let range = Range(uncheckedBounds: (lower: max(0, min(count, r.lowerBound)),
                                        upper: min(count, max(0, r.upperBound))))
    let start = index(startIndex, offsetBy: range.lowerBound)
    let end = index(start, offsetBy: range.upperBound - range.lowerBound)
    return String(self[start ..< end])
  }
  
  subscript(value: CountableClosedRange<Int>) -> Substring {
    return self[index(at: value.lowerBound)...index(at: value.upperBound)]
  }
  
  subscript(value: CountableRange<Int>) -> Substring {
    return self[index(at: value.lowerBound)..<index(at: value.upperBound)]
  }
  
  subscript(value: PartialRangeUpTo<Int>) -> Substring {
    return self[..<index(at: value.upperBound)]
  }
  
  subscript(value: PartialRangeThrough<Int>) -> Substring {
    return self[...index(at: value.upperBound)]
  }
  
  subscript(value: PartialRangeFrom<Int>) -> Substring {
    return self[index(at: value.lowerBound)...]
  }
  
  private func index(at offset: Int) -> String.Index {
    return index(startIndex, offsetBy: offset)
  }

}
