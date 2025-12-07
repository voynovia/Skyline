import MapKit
import CoreLocation

public extension TimeZone {
  
  enum TimeZoneError: Error {
    case invalidCoordinates
    case notFound
  }
  
  static func byCoordinate(_ coordinate: CLLocationCoordinate2D) async throws -> TimeZone {
    let location = CLLocation(
      latitude: coordinate.latitude,
      longitude: coordinate.longitude
    )
    guard let request = MKReverseGeocodingRequest(location: location) else {
      throw TimeZoneError.invalidCoordinates
    }
    
//    request.getMapItems { items, error in
//      
//    }
    let mapItems = try await request.mapItems
    guard
      let mapItem = mapItems.first,
      let timeZone = mapItem.timeZone
    else {
      throw TimeZoneError.notFound
    }
    return timeZone
  }
  
}
