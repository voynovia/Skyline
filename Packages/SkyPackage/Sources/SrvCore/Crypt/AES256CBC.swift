//
//  AES256CBC.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation
import CommonCrypto

public struct AES256CBC {
  
  let encryptionKey = "BpLnfgDsc2WD8F2qNfHK5a84jjJkwzDk" // ключ для шифровки
  let decryptionKey = "AAyAiiGZ2pvqW7xS0etDDVprCdOiWAyT" // ключ для расшифровки
  
  public init() {}
  
  // размер блока aes
  static let blockSize = kCCBlockSizeAES128
  
  public func decryptedData(_ str: String) throws -> Data {
    // извлекаем iv из начала строки
    let iv = String(str.prefix(Self.blockSize))
    let encrypted = String(str.dropFirst(Self.blockSize))
    
    // декодируем base64
    guard let encryptedData = Data(base64Encoded: encrypted) else {
      throw AESError.invalidBase64
    }
    
    // расшифровываем
    guard let decrypted = aesOperation(
      data: encryptedData,
      key: decryptionKey,
      iv: iv,
      operation: CCOperation(kCCDecrypt)
    ) else {
      throw AESError.decryptionFailed
    }
    
    return decrypted
  }
  
  private func encryptedBase64(_ jsonString: String) throws -> String {
    // генерируем случайный iv
    let iv = Self.randomText(Self.blockSize)
    
    // преобразуем строку в данные
    guard let data = jsonString.data(using: .utf8) else {
      throw AESError.invalidInput
    }
    
    // шифруем
    guard let encrypted = aesOperation(
      data: data,
      key: encryptionKey,
      iv: iv,
      operation: CCOperation(kCCEncrypt)
    ) else {
      throw AESError.encryptionFailed
    }
    
    // возвращаем iv + зашифрованные данные в base64
    return iv + encrypted.base64EncodedString()
  }
  
  // основная функция для шифрования/расшифровки
  private func aesOperation(
    data: Data,
    key: String,
    iv: String,
    operation: CCOperation
  ) -> Data? {
    // проверяем длину ключа (должна быть 32 байта для aes-256)
    guard key.count == kCCKeySizeAES256 else { return nil }
    
    // преобразуем ключ и iv в данные
    guard let keyData = key.data(using: .utf8),
          let ivData = iv.data(using: .utf8) else { return nil }
    
    // размер буфера для результата
    let bufferSize = data.count + kCCBlockSizeAES128
    var buffer = Data(count: bufferSize)
    var numBytesProcessed: size_t = 0
    
    // выполняем операцию
    let status = buffer.withUnsafeMutableBytes { bufferBytes in
      data.withUnsafeBytes { dataBytes in
        keyData.withUnsafeBytes { keyBytes in
          ivData.withUnsafeBytes { ivBytes in
            CCCrypt(
              operation,                              // шифрование или расшифровка
              CCAlgorithm(kCCAlgorithmAES),          // алгоритм aes
              CCOptions(kCCOptionPKCS7Padding),       // pkcs7 padding
              keyBytes.baseAddress,                   // ключ
              kCCKeySizeAES256,                      // размер ключа
              ivBytes.baseAddress,                    // вектор инициализации
              dataBytes.baseAddress,                  // входные данные
              data.count,                            // размер входных данных
              bufferBytes.baseAddress,               // выходной буфер
              bufferSize,                            // размер выходного буфера
              &numBytesProcessed                     // количество обработанных байт
            )
          }
        }
      }
    }
    
    // проверяем статус операции
    guard status == kCCSuccess else { return nil }
    
    // обрезаем буфер до фактического размера
    buffer.removeSubrange(numBytesProcessed..<buffer.count)
    return buffer
  }
  
  static func randomText(_ length: Int) -> String {
    let letters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return String((0..<length).map { _ in letters.randomElement()! })
  }
}

// расширение для статического метода
extension AES256CBC {
  /// возвращает опциональную зашифрованную строку через aes-256-cbc
  /// автоматически генерирует и помещает случайный iv в первые 16 символов
  /// пароль должен быть ровно 32 символа для aes-256
  static func encryptString(_ str: String, password: String) -> String? {
    guard !str.isEmpty,
          password.count == kCCKeySizeAES256,
          let data = str.data(using: .utf8) else {
      return nil
    }
    
    let iv = randomText(blockSize)
    guard let ivData = iv.data(using: .utf8),
          let keyData = password.data(using: .utf8) else {
      return nil
    }
    
    let bufferSize = data.count + kCCBlockSizeAES128
    var buffer = Data(count: bufferSize)
    var numBytesProcessed: size_t = 0
    
    let status = buffer.withUnsafeMutableBytes { bufferBytes in
      data.withUnsafeBytes { dataBytes in
        keyData.withUnsafeBytes { keyBytes in
          ivData.withUnsafeBytes { ivBytes in
            CCCrypt(
              CCOperation(kCCEncrypt),
              CCAlgorithm(kCCAlgorithmAES),
              CCOptions(kCCOptionPKCS7Padding),
              keyBytes.baseAddress,
              kCCKeySizeAES256,
              ivBytes.baseAddress,
              dataBytes.baseAddress,
              data.count,
              bufferBytes.baseAddress,
              bufferSize,
              &numBytesProcessed
            )
          }
        }
      }
    }
    
    guard status == kCCSuccess else { return nil }
    
    buffer.removeSubrange(numBytesProcessed..<buffer.count)
    return iv + buffer.base64EncodedString()
  }
}

// enum для ошибок
enum AESError: LocalizedError {
  case invalidBase64
  case invalidInput
  case encryptionFailed
  case decryptionFailed
  
  var errorDescription: String? {
    switch self {
    case .invalidBase64:
      return "Cannot decode base64 data to string"
    case .invalidInput:
      return "Invalid input data"
    case .encryptionFailed:
      return "Encryption failed"
    case .decryptionFailed:
      return "Decryption failed"
    }
  }
}
