import CoreGraphics
import CoreLocation
import Foundation
import ImageIO
import Turf

enum WxMapError: Error {
  case invalidMetadata
  case invalidUVT
  case unknownType
}

public struct WxMap {

  public init() {}

  public func get() throws {
    guard
      let url: URL = Bundle.module.url(forResource: "uvt", withExtension: "webp"),
      FileManager.default.fileExists(atPath: url.path())
    else {
      throw NSError(domain: "file not found", code: 404)
    }
    let data: WebpData = try WebpReader().read(url: url)

    guard
      let rMin = data.metadata["rMin"], let rMax = data.metadata["rMax"],
      let gMin = data.metadata["gMin"], let gMax = data.metadata["gMax"],
      let bMin = data.metadata["bMin"], let bMax = data.metadata["bMax"]
    else {
      throw WxMapError.invalidMetadata
    }
    
    let filename = url.deletingPathExtension().lastPathComponent
    
    let destinationUrl = FileManager.default.temporaryDirectory
      .appending(component: filename)
      .appendingPathExtension("geojson")
    
    switch filename {
    case "uvt":
      guard
        let uMin = Double(rMin), let uMax = Double(rMax),
        let vMin = Double(gMin), let vMax = Double(gMax),
        let tMin = Double(bMin), let tMax = Double(bMax)
      else {
        throw WxMapError.invalidUVT
      }
      try handleUVT(url: destinationUrl, data: data, uMin: uMin, uMax: uMax, vMin: vMin, vMax: vMax, tMin: tMin, tMax: tMax)
    default:
      // если файлов будет много, то со всех файлов собираем массив фич с типом "точка",
      // потом со всех файлов делаем [JSONObject: [LocationCoordinate2D]]
      // и создаем мультипоинт фичи, то есть собираем вместе точки где одинаковые проперти
      // так мы очень сильно выйграем во времени создания и размере геожсон файла
      throw WxMapError.unknownType
    }

  }
  
  private func handleUVT(
    url: URL, data: WebpData,
    uMin: Double, uMax: Double,
    vMin: Double, vMax: Double,
    tMin: Double, tMax: Double
  ) throws {
    
#if DEBUG
    let startTime = CFAbsoluteTimeGetCurrent()
    defer { print("\(#function): \(String(format: "%.5f", CFAbsoluteTimeGetCurrent() - startTime)) seconds") }
#endif
    
    let prec: Double = 360 / Double(data.width)
    let uScale = (uMax - uMin) / 255
    let vScale = (vMax - vMin) / 255
    let tScale = (tMax - tMin) / 255
    
    // координата: свойства
    //    var dict: [LocationCoordinate2D: JSONObject] = [:]
    
    // свойства: координаты
    var obDict: [JSONObject: [LocationCoordinate2D]] = [:]
    
    for x: Int in 0..<data.width {
      for y: Int in 0..<data.height {
        let pixel: WebpData.Pixel = data.pixelAt(x: x, y: y)
        
        let lat = Double(pixel.y) * prec - 90
        let lon = Double(pixel.x) * prec - 180
        
        let uValue = Double(pixel.rgba[0]) * uScale + uMin
        let vValue = Double(pixel.rgba[1]) * vScale + vMin
        let tValue = Double(pixel.rgba[3]) * tScale + tMin
        
        let sdt = decomposeUVT(u: uValue, v: vValue, t: tValue)
        let loc = LocationCoordinate2D(latitude: lat, longitude: lon)
        let properties: JSONObject = [
          "speed": .number(Double(sdt.speed)),
          "direction": .number(Double(sdt.direction)),
          "temperature": .number(Double(sdt.temperature))
        ]
//        dict[loc] = properties
        obDict[properties, default: []].append(loc)
      }
    }
    
//    let features = dict.map { key, value -> Feature in
//      let point = Point(key)
//      var feature = Feature(geometry: .point(point))
//      feature.properties = value
//      return feature
//    }
    
    let features = obDict.map { key, value -> Feature in
      let multiPoint = MultiPoint(value)
      var feature = Feature(geometry: .multiPoint(multiPoint))
      feature.properties = key
      return feature
    }

    let collection = FeatureCollection(features: features)
    let data = try JSONEncoder().encode(collection)
    try data.write(to: url)
  }

  private func decomposeUVT(u: Double, v: Double, t: Double) -> SDT {
    let s = sqrt(u*u + v*v) // скорость
    let d = atan2(u, v) * (180 / .pi) + 180 // направление
    let speed = Int(round(s / 5) * 5) // округляем до 5
    let direction = Int(round(d / 5) * 5) // округляем до 5
    let temperature = Int(t - 273.15) // Kelvin to Celsius
    return .init(speed: speed, direction: direction, temperature: temperature)
  }
  
}

extension LocationCoordinate2D: @retroactive Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(latitude)
    hasher.combine(longitude)
  }
}
