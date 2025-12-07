//
//  UIFont+Register.swift
//  SkyPackage
//
//  Created by Igor Voynov on 8. 3. 25.
//

import UIKit.UIFont

public extension UIFont {
  
  static func register(from url: URL) {
    guard let fontDataProvider = CGDataProvider(url: url as CFURL) else {
      print("could not get reference to font data provider")
      return
    }
    guard let font = CGFont(fontDataProvider) else {
      print("could not get font from coregraphics")
      return
    }
    var error: Unmanaged<CFError>?
    guard CTFontManagerRegisterGraphicsFont(font, &error) else {
      print("error registering font: \(error.debugDescription)")
      return
    }
  }
  
}
