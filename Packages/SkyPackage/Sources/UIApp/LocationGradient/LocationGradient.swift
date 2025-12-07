import SwiftUI
import CoreLocation
import Extensions


struct LocationGradient {
  
  private let gradientCache = GradientCache.shared
  
  func getGradient(for coordinate: CLLocationCoordinate2D) async throws -> GradientColors {
    if let cached = await gradientCache.get(for: coordinate) {
      return cached
    }
    let tz = try await TimeZone.byCoordinate(coordinate)
    let sun = Sun(location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), timeZone: tz)
    let colors = getColors(for: sun)
    guard let first = colors.first, let last = colors.last else {
      throw "colors"
    }
    let middle = interpolateColor(from: first, to: last, progress: 0.5)
    let gradient = GradientColors([first, middle, last])
    await gradientCache.set(gradient, for: coordinate)
    return gradient
  }
  
  private func getColors(for sun: Sun) -> [Color] {
    // Утро
    if sun.isMorningGoldenHour {
      // если до sunriseTime то интреполяция цветов (первый с первым и второй со вторым) night к sunrise, если после, то от sunrise к day
      if sun.date < sun.sunrise {
        let progress = calculateProgress(
          from: sun.morningGoldenHourStart,
          to: sun.sunrise,
          current: sun.date
        )
        return interpolateGradients(from: PeriodColors.night, to: PeriodColors.sunrise, progress: progress)
      } else {
        let progress = calculateProgress(
          from: sun.sunrise,
          to: sun.morningGoldenHourEnd,
          current: sun.date
        )
        return interpolateGradients(from: PeriodColors.sunrise, to: PeriodColors.day, progress: progress)
      }
    }
    // День
    if sun.date >= sun.morningGoldenHourEnd && sun.date < sun.eveningGoldenHourStart {
      return PeriodColors.day
    }
    // Вечер
    if sun.isEveningGoldenHour {
      // если до sunsetTime то интреполяция цветов (первый с первым и второй со вторым) day к sunset, если после, то от sunset к night
      if sun.date < sun.sunset {
        let progress = calculateProgress(
          from: sun.eveningGoldenHourStart,
          to: sun.sunset,
          current: sun.date
        )
        return interpolateGradients(from: PeriodColors.day, to: PeriodColors.sunset, progress: progress)
      } else {
        let progress = calculateProgress(
          from: sun.sunset,
          to: sun.eveningGoldenHourEnd,
          current: sun.date
        )
        return interpolateGradients(from: PeriodColors.sunset, to: PeriodColors.night, progress: progress)
      }
    }
    // Ночь
    return PeriodColors.night
  }
 
  private func calculateProgress(
    from startDate: Date,
    to endDate: Date,
    current: Date
  ) -> Double {
    let totalInterval = endDate.timeIntervalSince(startDate)
    let currentInterval = current.timeIntervalSince(startDate)
    return min(max(currentInterval / totalInterval, 0), 1)
  }
  
  private func interpolateGradients(
    from: [Color],
    to: [Color],
    progress: Double
  ) -> [Color] {
    guard from.count == to.count else {
      return progress < 0.5 ? from : to
    }
    let interpolatedColors = zip(from, to).map { fromColor, toColor in
      interpolateColor(from: fromColor, to: toColor, progress: progress)
    }
    return interpolatedColors
  }

  private func interpolateColor(
    from: Color,
    to: Color,
    progress: Double
  ) -> Color {
    Color(
      red: lerp(from.cgColor!.components![0], to.cgColor!.components![0], t: progress),
      green: lerp(from.cgColor!.components![1], to.cgColor!.components![1], t: progress),
      blue: lerp(from.cgColor!.components![2], to.cgColor!.components![2], t: progress)
    )
  }

  private func lerp(_ a: Double, _ b: Double, t: Double) -> Double {
    a + (b - a) * t
  }
  
}
