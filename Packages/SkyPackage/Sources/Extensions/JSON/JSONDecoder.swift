import Foundation

extension JSONDecoder {

  public static func withStrategy(
    date: DateDecodingStrategy = .deferredToDate,
    key: KeyDecodingStrategy = .useDefaultKeys
  ) -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = date
    decoder.keyDecodingStrategy = key
    return decoder
  }

  public func readJSONFilesConcurrently<T: Decodable & Sendable>(filePaths: [String]) async -> [T] {
    let validPaths = filePaths.filter { FileManager.default.fileExists(atPath: $0) }
    var results = [T]()
    await withTaskGroup(of: T?.self) { group in
      for path in validPaths {
        group.addTask {
          do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return try self.decode(T.self, from: data)
          } catch {
            print("Failed to read or decode file: \(path), error: \(error)")
            return nil
          }
        }
      }
      for await result in group {
        if let decoded = result {
          results.append(decoded)
        }
      }
    }
    return results
  }

}
