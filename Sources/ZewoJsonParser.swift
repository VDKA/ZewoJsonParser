
import C7
import StructuredData
import GenericJsonParser

public struct JSONParser {

  static func toObject(_ input: [(String, StructuredData)]) -> StructuredData {

    var dict: [String: StructuredData] = [:]
    for (key, value) in input {
      dict[key] = value
    }
    return .dictionary(dict)
  }

  static func toArray(_ input: [StructuredData]) -> StructuredData {
    return .array(input)
  }

  static func toNull() -> StructuredData {
    return .null
  }

  static func toBool(_ input: Bool) -> StructuredData {
    return .bool(input)
  }

  static func toString(_ input: String) -> StructuredData {

    return .string(input)
  }

  static func toNumber(_ input: Number) -> StructuredData {

    switch input {
    case .integer(let i):
      return .int(Int(i))
    case .double(let d):
      return .double(d)
    }
  }

  public typealias Option = GenericJsonParser.Option
  typealias Number = GenericJsonParser.Number

  public static func parse(_ data: Data, options: Option = []) throws -> StructuredData {

    var bytes = data.bytes

    return try GenericJsonParser.parse(
      data: &bytes,
      options: options,
      onObject: toObject,
      onArray: toArray,
      onNull: toNull,
      onBool: toBool,
      onString: toString,
      onNumber: toNumber
    )
  }

  public static func parse(_ data: inout Data, options: Option = []) throws -> StructuredData {

    return try GenericJsonParser.parse(
      data: &data.bytes,
      options: options,
      onObject: toObject,
      onArray: toArray,
      onNull: toNull,
      onBool: toBool,
      onString: toString,
      onNumber: toNumber
    )
  }

  public static func parse(_ bytes: [UInt8], options: Option = []) throws -> StructuredData {

    var bytes = bytes

    return try GenericJsonParser.parse(
      data: &bytes,
      options: options,
      onObject: toObject,
      onArray: toArray,
      onNull: toNull,
      onBool: toBool,
      onString: toString,
      onNumber: toNumber
    )
  }

  public static func parse(_ bytes: inout [UInt8], options: Option = []) throws -> StructuredData {

    return try GenericJsonParser.parse(
      data: &bytes,
      options: options,
      onObject: toObject,
      onArray: toArray,
      onNull: toNull,
      onBool: toBool,
      onString: toString,
      onNumber: toNumber
    )
  }
}

