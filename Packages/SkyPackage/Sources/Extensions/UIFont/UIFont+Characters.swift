//
//  UIFont+Characters.swift
//  SkyPackage
//
//  Created by Igor Voynov on 8. 3. 25.
//

import UIKit.UIFont
import CoreText

extension UIFont {
  
  /// Возвращает список символов, поддерживаемых шрифтом
  func supportedCharacters() -> [(character: String, unicode: UInt32)] {
    // Создаем CTFont на основе UIFont
    let ctFont = CTFontCreateWithName(self.fontName as CFString, self.pointSize, nil)
    
    var unicodeCharacters: [(String, UInt32)] = []
    
    // Получаем информацию о наборе символов в шрифте
    let charset = CTFontCopyCharacterSet(ctFont)
    let charsetNS = charset as NSCharacterSet
    
    for plane in 0..<16 {
      if charsetNS.hasMemberInPlane(UInt8(plane)) {
        for charCode in 0x0000...0xFFFF {
          if let unicodeScalar = UnicodeScalar(charCode), charsetNS.longCharacterIsMember(UTF32Char(charCode)) {
            let character = String(unicodeScalar)
            let unicode = unicodeScalar.value
            unicodeCharacters.append((character, unicode))
          }
        }
      }
    }

    return unicodeCharacters
  }
  
}
