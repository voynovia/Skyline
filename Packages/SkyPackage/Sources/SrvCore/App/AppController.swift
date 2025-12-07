//
//  AppController.swift
//  SkyPackage
//
//  Created by Igor Voynov on 9. 3. 25.
//

import UIKit
import DeviceKit
import Extensions

@MainActor
public struct AppController {
  
  public init() {}
  
  public var name: String {
    let name = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)
    ?? (Bundle.main.infoDictionary?["CFBundleName"] as? String)
    ?? "Application"
    return name
  }
  
  public var version: String? {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  }
  
  public var build: String? {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String
  }
  
  public var fullVersion: String {
    guard let bundleVer = version, let bundleBuild = build else { return "unknown" }
    return "\(bundleVer).\(bundleBuild)"
  }
  
  public var info: (version: String, date: String)? {
    guard let bundleVer = version, let bundleBuild = build else { return nil }
    return ("\(bundleVer) (\(bundleBuild))", compileDateString(.ddmmyy))
  }
  
  public var description: String? {
    guard let bundleVer = version, let bundleBuild = build else { return nil }
    return "manage_help_version"//.localized()
    + " \(bundleVer).\(bundleBuild) "
    + "manage_help_released"//.localized()
    + " \(compileDateString(.dmmmmyyyy))"
  }
  
  public enum DateFormat: String {
    case ddmmyy = "dd.MM.yy"
    case dmmmmyyyy = "d MMMM yyyy"
  }
  
  public func compileDateString(_ format: DateFormat) -> String {
    let dateFormatter = DateFormatter()
    let lang = Locale.current.currentLanguage?.rawValue ?? "en"
    dateFormatter.locale = Locale(identifier: "\(lang)_US_POSIX")
    dateFormatter.dateFormat = format.rawValue
    return dateFormatter.string(from: compileDate)
  }
  
  public var identifier: String? {
    if let name = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
      return name.deletingSuffix("Main")
    }
    return nil
  }
  
  public var os: String {
    UIDevice.current.systemName
  }
  
  public var osVersion: String {
    UIDevice.current.systemVersion
  }
  
  public var deviceName: String {
    UIDevice.current.name
  }
  
  public var deviceModel: String {
    Device.current.description
  }
  
  public var diagonal: Double {
    Device.current.diagonal
  }
  
  public var identifierForVendor: String {
    UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
  }
  
  public enum UpdateStatus {
    case needUpdate, upToDate, testFlight
  }
  
//  public var compareWithAppStore: UpdateStatus {
//    guard
//      let appStore = self.getIntVersion(version: SkySettings.iTunesVersion),
//      let current = self.getIntVersion(version: version)
//    else {
//      return .upToDate
//    }
//    if appStore > current {
//      return .needUpdate
//    }
//    if appStore < current {
//      return .testFlight
//    }
//    return .upToDate
//  }

  // MARK: - Private
  
  private var compileDate: Date {
    let bundleName = Bundle.main.infoDictionary!["CFBundleName"] as? String ?? "Info.plist"
    if let infoPath = Bundle.main.path(forResource: bundleName, ofType: nil),
       let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
       let infoDate = infoAttr[FileAttributeKey.creationDate] as? Date {
      return infoDate
    }
    return Date()
  }
  
  private func getIntVersion(version: String?) -> Int? {
    guard var array = version?.split(separator: "."), array.count == 3 else { return nil }
    for index in 0..<array.count {
      while array[index].count < 2 {
        array[index] = "0" + array[index]
      }
    }
    guard let digit = Int(array.joined(separator: "")) else { return nil }
    return digit
  }
  
}
