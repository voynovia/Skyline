import Foundation

struct PNG {

  enum PNGError: Error {
    case invalidFile
    case unexpectedEOF
  }

  func readTEXT(data: Data) throws -> [String: String] {
    var offset: Int = 0

    // Validate PNG header
    let pngHeader: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    let headerData: Data = readBytes(data, count: 8, at: &offset)
    if headerData != Data(pngHeader) {
      throw PNGError.invalidFile
    }

    var metadata: [String: String] = [:]

    while offset < data.count {
      guard data.count - offset >= 8 else { throw PNGError.unexpectedEOF }

      // Read chunk length and type
      let length: UInt32 = readUInt32(data, at: &offset)
      let chunkType: Data = readBytes(data, count: 4, at: &offset)

      guard data.count - offset >= length + 4 else { throw PNGError.unexpectedEOF }

      // Read chunk data and CRC
      let chunkData: Data = readBytes(data, count: Int(length), at: &offset)
      let _ = readBytes(data, count: 4, at: &offset)  // CRC

      // Process tEXt chunks
      if chunkType == Data("tEXt".utf8),
        let separatorIndex: Data.Index = chunkData.firstIndex(of: 0),
        let key: String = String(data: chunkData[..<separatorIndex], encoding: .isoLatin1),
        let value: String = String(data: chunkData[(separatorIndex + 1)...], encoding: .isoLatin1)
      {
        metadata[key] = value
      }
    }

    return metadata
  }

  private func readUInt32(_ data: Data, at offset: inout Int) -> UInt32 {
    let subdata: Data = data.subdata(in: offset..<offset + 4)
    offset += 4
    return UInt32(bigEndian: subdata.withUnsafeBytes { $0.load(as: UInt32.self) })
  }

  private func readBytes(_ data: Data, count: Int, at offset: inout Int) -> Data {
    let range: Range<Int> = offset..<offset + count
    let subData: Data = data.subdata(in: range)
    offset += count
    return subData
  }

}
