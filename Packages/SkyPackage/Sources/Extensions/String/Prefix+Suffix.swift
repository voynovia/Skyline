import Foundation

public extension String {
  
  func getSuffixAfter(_ separator: String) -> String? {
    if let range = self.range(of: separator) {
      return String(self[range.upperBound...])
    }
    return nil
  }
  
  func deletingPrefix(_ prefix: String) -> String {
    guard self.hasPrefix(prefix) else { return self }
    return String(self.dropFirst(prefix.count))
  }
  
  func deletingSuffix(_ suffix: String) -> String {
    guard self.hasSuffix(suffix) else { return self }
    return String(self.dropLast(suffix.count))
  }

}
