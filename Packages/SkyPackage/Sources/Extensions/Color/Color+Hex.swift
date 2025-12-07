//
//  Color+Hex.swift
//  SkyPackage
//
//  Created by Igor Voynov on 14. 4. 25.
//

import SwiftUI

extension Color {
  init(light: Color, dark: Color) {
    self = Color(UIColor { traitCollection in
      return traitCollection.userInterfaceStyle == .dark
      ? UIColor(dark)
      : UIColor(light)
    })
  }
  
  init(hex: String) {
    let scanner = Scanner(string: hex)
    _ = scanner.scanString("#")
    var rgb: UInt64 = 0
    scanner.scanHexInt64(&rgb)
    let r = Double((rgb >> 16) & 0xFF) / 255.0
    let g = Double((rgb >> 8) & 0xFF) / 255.0
    let b = Double(rgb & 0xFF) / 255.0
    self = Color(red: r, green: g, blue: b)
  }
}
