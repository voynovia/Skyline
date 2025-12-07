//
//  AnyValue.swift
//  SkyPackage
//
//  Created by Igor Voynov on 9. 3. 25.
//

import Foundation

// Создаем обертку для поддержки декодирования динамических значений
public enum AnyValue: Codable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case array([AnyValue])
  case dictionary([String: AnyValue])
  case null
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    
    if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode(Int.self) {
      self = .int(value)
    } else if let value = try? container.decode(Double.self) {
      self = .double(value)
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode([AnyValue].self) {
      self = .array(value)
    } else if let value = try? container.decode([String: AnyValue].self) {
      self = .dictionary(value)
    } else if container.decodeNil() {
      self = .null
    } else {
      throw DecodingError.typeMismatch(AnyValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    
    switch self {
    case .string(let value):
      try container.encode(value)
    case .int(let value):
      try container.encode(value)
    case .double(let value):
      try container.encode(value)
    case .bool(let value):
      try container.encode(value)
    case .array(let value):
      try container.encode(value)
    case .dictionary(let value):
      try container.encode(value)
    case .null:
      try container.encodeNil()
    }
  }
}

// Расширение для удобного преобразования AnyValue
public extension AnyValue {
  
  var arrayValue: [AnyValue]? {
    switch self {
    case .array(let value): return value
    default: return nil
    }
  }
  
  var stringValue: String? {
    switch self {
    case .string(let value): return value
    default: return nil
    }
  }
  
  var doubleValue: Double? {
    switch self {
    case .double(let value): return value
    case .int(let value): return Double(value)
    case .string(let value): return Double(value)
    default: return nil
    }
  }
}
