import Foundation
import SrvCore
import SrvDatabase

public struct NotamService {

  public enum Sphere: String, CaseIterable {
    case arp, fir
  }

  public enum Format: String {
    case notam, snowtam
  }

  public init() {}

  public func fromDatabase(list: [String], sphere: Sphere) async throws -> [DatabaseApp.Notam] {
    if list.isEmpty {
      return []
    }
    let formats: [Format] = sphere == .fir ? [.notam] : [.notam, .snowtam]
    let result: [DatabaseApp.Notam] = try await DatabaseApp.shared.getNotams(
      icaoList: list,
      sphere: sphere.rawValue,
      formats: formats.map({ $0.rawValue })
    )
    return result
  }

  public func fromServer(
    list: [String],
    sphere: Sphere,
    validTime: Date = Date()
  ) async throws -> [DatabaseApp.Notam] {
    if list.isEmpty { return [] }

    var notams: [DatabaseApp.Notam] = []

    let formats: [Format] = sphere == .fir ? [.notam] : [.notam, .snowtam]
    for format: NotamService.Format in formats {
      let body: NotamRequestBody = NotamRequestBody(
        list: list,
        type: sphere.rawValue,
        format: format.rawValue
      )
      let response: [NotamDictResponse] = try await request(body: body)
      for item: NotamDictResponse in response {
        let translated: [DatabaseApp.Notam] = translate(
          objects: item.notams,
          sphere: sphere,
          format: format,
          validTime: validTime
        )
        notams.append(contentsOf: translated)
      }
    }

    if !notams.isEmpty {
      try DatabaseApp.shared.saveNotams(notams: notams, list: list, sphere: sphere.rawValue)
    }
    return notams
  }

  private func request(body: NotamRequestBody) async throws -> [NotamDictResponse] {
    // собираем запрос
    let url: URL = URL(string: "https://api.aeromap.app")!.appendingPathComponent("notam")
    var request: URLRequest = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder.withStrategy(date: .iso8601).encode(body)
    let result: [NotamDictResponse] = try await Network().post(request: request, isCrypted: true)
    return result
  }

  private func translate(objects: [NotamResponse], sphere: Sphere, format: Format, validTime: Date)
    -> [DatabaseApp.Notam]
  {
    var notams: [DatabaseApp.Notam] = []
    for ob: NotamResponse in objects {
      guard let fromdate: Date = Date.fromString(ob.fromDate, format: .rfc3339) else {
        print("notam \(ob.number) translation error: \(ob.fromDate)")
        continue
      }
      let toDate: Date? = Date.fromString(ob.toDate, format: .rfc3339)
      let number: String = ob.series + ob.number + "/" + String(ob.year)
      let notam: DatabaseApp.Notam = DatabaseApp.Notam(
        sphere: sphere.rawValue, format: format.rawValue, text: ob.text, provider: ob.provider,
        uniformAbbreviation: "", validTime: validTime,
        // header
        number: number,
        // A-SECTION
        icao: ob.icao,
        // B-SECTION
        fromDate: fromdate,
        // C-SECTION
        toDate: toDate, toString: ob.toDate,
        // D-SECTION & E-SECTION
        schedule: ob.schedule, eCode: ob.eCode,
        // F-SECTION & G-SECTION
        lowerLimit: ob.lowerLimit, upperLimit: ob.upperLimit,
        // Q-SECTION
        fir: ob.fir, qCode: ob.qCode, fromLevel: ob.fromLevel, toLevel: ob.toLevel)
      notams.append(notam)
    }
    return notams
  }

}

// MARK: - Request

private struct NotamRequestBody: Encodable {
  let client: String
  let list: [String]
  let type: String
  let format: String
  //    let šifriraj: Bool

  init(list: [String], type: String, format: String) {
    self.client = "1b90b36c-79c9-4f61-9831-244200130e7a"
    self.list = list
    self.type = type
    self.format = format
    //      self.šifriraj = false
  }
}

// MARK: - Response

private struct NotamDictResponse: Decodable {
  let icao: String
  var notams: [NotamResponse]
}

private struct NotamResponse: Decodable {
  let text: String
  let provider: String
  // header
  let series: String
  let number: String
  let year: Int
  let type: String?
  let typeTranslations: String?
  let codeBack: String?
  // Q-SECTION
  let fir: String
  let qCode: String
  let traffic: String?
  let trafficTranslations: String?
  let aim: String?
  let aimTranslations: String?
  let scope: String?
  let scopeTranslations: String?
  let fromLevel: Int?
  let toLevel: Int?
  // A-SECTION
  let icao: String
  // B-SECTION
  let fromDate: String
  // C-SECTION
  let toDate: String?
  // D-SECTION
  let schedule: String?
  // E-SECTION
  let eCode: String
  // F-SECTION
  let lowerLimit: String?
  // G-SECTION
  let upperLimit: String?
}
