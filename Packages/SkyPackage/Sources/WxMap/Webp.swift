import Foundation
import ImageIO

struct WebpData {
  struct Pixel {
    public let x, y: Int
    public let rgba: [UInt8]
  }
  
  let array: [UInt8]
  let width: Int
  let height: Int
  let metadata: [String: String]
  
  func pixelAt(x: Int, y: Int) -> Pixel {
    let offset: Int = (y * width + x) * 4
    let rgba: [UInt8] = Array(array[offset..<offset + 4])
    return Pixel(x: x, y: y, rgba: rgba)
  }
}

final class WebpReader: NSObject {
  private let xmpNamespace = "http://ns.adobe.com/xap/1.0/"
  
  func read(url: URL) throws -> WebpData {
#if DEBUG
    let startTime = CFAbsoluteTimeGetCurrent()
    defer { print("\(#function): \(String(format: "%.5f", CFAbsoluteTimeGetCurrent() - startTime)) seconds") }
#endif
    
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
      throw WebpReaderError.createSource
    }
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
      throw WebpReaderError.createImage
    }
//    if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
//       let width = properties[kCGImagePropertyPixelWidth] as? Int,
//       let height = properties[kCGImagePropertyPixelHeight] as? Int {
//        print("Image size: \(width) x \(height)")
//    }
    guard let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) else {
      throw WebpReaderError.copyMetadata
    }
    guard let xmpData = CGImageMetadataCreateXMPData(metadata, nil) else {
      throw WebpReaderError.createXMPData
    }
    
    let width = image.width
    let height = image.height
    let bytesPerRow = width * 4
    let totalBytes = bytesPerRow * height
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let rawData: [UInt8] = [UInt8](unsafeUninitializedCapacity: totalBytes) { buffer, count in
      guard let context = CGContext(
        data: buffer.baseAddress,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue  //premultipliedLast для RGBA, noneSkipLast для NRGBA
      ) else {
        count = 0
        return
      }
      context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
      count = totalBytes
    }
    
    let context = ParsingContext(namespace: xmpNamespace)
    let parser = XMLParser(data: xmpData as Data)
    parser.delegate = context
    parser.shouldProcessNamespaces = true // ключевая настройка
    guard parser.parse() else {
      throw parser.parserError ?? WebpReaderError.unknown
    }
    
    return WebpData(array: rawData, width: width, height: height, metadata: context.metadata)
  }
}

fileprivate final class ParsingContext: NSObject, XMLParserDelegate {
  let targetNamespace: String
  var metadata: [String: String] = [:]
  var currentValue = ""
  
  init(namespace: String) {
    self.targetNamespace = namespace
    super.init()
  }
  
  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String] = [:]
  ) {
    currentValue = ""
    // для атрибутов используем qualifiedName и проверяем вручную
    // XMLParser не предоставляет namespace для атрибутов напрямую
    for (key, value) in attributeDict {
      let localName = key.split(separator: ":").last.map(String.init) ?? key
      if key.contains(":") {
        metadata[localName] = value
      }
    }
  }
  
  func parser(_ parser: XMLParser, foundCharacters string: String) {
    currentValue += string
  }
  
  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    guard namespaceURI == targetNamespace else {
      currentValue = ""
      return
    }
    let trimmedValue = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedValue.isEmpty {
      metadata[elementName] = trimmedValue
    }
    currentValue = ""
  }
}

enum WebpReaderError: Error {
  case invalidEncoding
  case unknown
  case createSource
  case copyMetadata
  case createXMPData
  case createImage
}
