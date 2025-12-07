import Foundation

extension JSONEncoder {

  public static func withStrategy(
    date: DateEncodingStrategy = .deferredToDate,
    key: KeyEncodingStrategy = .useDefaultKeys
  ) -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = date
    encoder.keyEncodingStrategy = key
    return encoder
  }

  public struct PathObject<T: Encodable> {
    let filePath: String
    let object: T
  }

  public func writeJSONFilesConcurrently<T: Encodable & Sendable>(
    pathObjects: [PathObject<T>]
  ) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
      for pair in pathObjects {
        // Capture immutable copies
        let filePath = pair.filePath
        let object = pair.object
        group.addTask {
          let encoder = JSONEncoder()  // Create encoder in task
          let data = try encoder.encode(object)
          let url = URL(fileURLWithPath: filePath)
          try data.write(to: url)
        }
      }
      try await group.waitForAll()
    }
  }

}
