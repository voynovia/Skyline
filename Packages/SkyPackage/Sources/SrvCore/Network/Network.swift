//
//  Network.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Extensions
import Foundation
import Gzip

public struct Network {

  public init() {}

  public func post<T: Decodable>(request: URLRequest, isCrypted: Bool) async throws -> T {
    // запрашиваем данные
    var (data, _) = try await URLSession.shared.data(for: request)
    // обрабатываем ответ
    let response = try JSONDecoder().decode(EncryptedResponse.self, from: data)
    guard response.success, let payload = response.payload else {
      throw response.errorMessage ?? response.message ?? "Unknown error"
    }
    // расшифровываем
    if isCrypted {
      data = try AES256CBC().decryptedData(payload)
    }
    // если данные сжаты, то распаковываем
    if data.isGzipped {
      data = try data.gunzipped()
    }
    // декодируем
    let result = try JSONDecoder.withStrategy(date: .iso8601).decode(T.self, from: data)
    return result
  }

}

private struct EncryptedResponse: Decodable {
  public let success: Bool
  public let message: String?
  public let payload: String?
  public let errorMessage: String?
}
