import CoreLocation
import Extensions
import SwiftUI

@MainActor
@Observable
final class WeatherService {
  private let locationManager = CLLocationManager()

  //  var currentGradient: GradientColors = PeriodColors.day
  var isLoading = false

  let coordinate: CLLocationCoordinate2D
  init(coordinate: CLLocationCoordinate2D) {
    self.coordinate = coordinate
  }

  func loadWeatherData() async throws {
    isLoading = true
    defer { isLoading = false }
    print(#function)
    //    currentGradient = try await LocationGradient().getGradient(for: coordinate)
  }

}
