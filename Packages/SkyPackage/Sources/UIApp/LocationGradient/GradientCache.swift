import SwiftUI
import CoreLocation

actor GradientCache {
  static let shared = GradientCache()
  
  private final class CacheEntry {
    let gradient: GradientColors
    let expirationDate: Date
    
    init(gradient: GradientColors, expirationDate: Date) {
      self.gradient = gradient
      self.expirationDate = expirationDate
    }
  }
  
  private let cache = NSCache<NSString, CacheEntry>()
  
  private init() {
    cache.countLimit = 100
  }
  
  func get(for coordinate: CLLocationCoordinate2D) -> GradientColors? {
    let key = cacheKey(for: coordinate)
    guard let entry = cache.object(forKey: key) else { return nil }
    
    if entry.expirationDate > .now {
      return entry.gradient
    }
    
    cache.removeObject(forKey: key)
    return nil
  }
  
  func set(_ gradient: GradientColors, for coordinate: CLLocationCoordinate2D) {
    let key = cacheKey(for: coordinate)
    let expirationDate = Date.now.addingTimeInterval(60)
    let entry = CacheEntry(gradient: gradient, expirationDate: expirationDate)
    cache.setObject(entry, forKey: key)
  }
  
  private func cacheKey(for coordinate: CLLocationCoordinate2D) -> NSString {
    "\(coordinate.latitude),\(coordinate.longitude)" as NSString
  }
}
