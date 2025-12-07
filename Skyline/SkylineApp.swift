//
//  SkylineApp.swift
//  Skyline
//
//  Created by Igor Voynov on 8. 3. 25.
//

import SwiftUI
import UIApp

@main
struct SkylineApp: SwiftUI.App {
  
  @UIApplicationDelegateAdaptor var delegate: AppDelegate
  
  var body: some Scene {
    WindowGroup {
      ContentView()
//        .preferredColorScheme(.dark) // постоянная темная тема
    }
  }
  
}
