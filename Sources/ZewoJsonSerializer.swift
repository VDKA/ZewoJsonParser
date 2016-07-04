
import StructuredData

public struct JSONSerializer {

  public struct Option: OptionSet {
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public let rawValue: UInt8

    /// Serialize `JSON.null` instead of skipping it
    public static let skipNull = Option(rawValue: 0b0001)
    /// Serialize with formatting for user readability
    public static let prettyPrint = Option(rawValue: 0b0010)
    /// Use windows style newlines for formatting. Boo. Implies `.prettyPrint`
    public static let windowsLineEndings = Option(rawValue: 0b0110)
  }

  init(json: StructuredData, options: Option = []) {
    self.skipNull = options.contains(.skipNull)
    self.prettyPrint = options.contains(.prettyPrint)
    self.useWindowsLineEndings = options.contains(.windowsLineEndings)
  }

  let skipNull: Bool
  let prettyPrint: Bool
  let useWindowsLineEndings: Bool
}

extension JSONSerializer {
  public static func serialize<O: OutputStream>(_ json: StructuredData, to stream: inout O, options: Option) throws {
    let writer = JSONSerializer(json: json, options: options)
    try writer.writeValue(json, to: &stream)
  }

  public static func serialize(_ json: StructuredData, options: Option = []) throws -> String {
    var s = ""
    let writer = JSONSerializer(json: json, options: options)
    try writer.writeValue(json, to: &s)
    return s
  }
}

extension JSONSerializer {
  func writeValue<O: OutputStream>(_ value: StructuredData, to stream: inout O, indentLevel: Int = 0) throws {
    switch value {
    case .array(let a):
      try writeArray(a, to: &stream, indentLevel: indentLevel)

    case .bool(let b):
      writeBool(b, to: &stream)

    case .double(let d):
      try writeDouble(d, to: &stream)

    case .int(let i):
      writeInteger(i, to: &stream)

    case .null where !skipNull:
      writeNull(to: &stream)

    case .string(let s):
      writeString(s, to: &stream)

    case .data(_):
      throw Error.dataNotSupportedInJSON

    case .dictionary(let o):
      try writeObject(o, to: &stream, indentLevel: indentLevel)

    default: break
    }
  }
}

extension JSONSerializer {

  func writeNewlineIfNeeded<O: OutputStream>(to stream: inout O) {
    guard prettyPrint else { return }
    stream.write("\n")
  }

  func writeIndentIfNeeded<O: OutputStream>(_ indentLevel: Int, to stream: inout O) {
    guard prettyPrint else { return }

    // TODO: Look into a more effective way of adding to a string.

    for _ in 0..<indentLevel {
      stream.write("    ")
    }
  }
}

extension JSONSerializer {

  func writeArray<O: OutputStream>(_ a: [StructuredData], to stream: inout O, indentLevel: Int = 0) throws {
    if a.isEmpty {
      stream.write("[]")
      return
    }

    stream.write("[")
    writeNewlineIfNeeded(to: &stream)
    var i = 0
    var nullsFound = 0
    for v in a {
      defer { i += 1 }
      if skipNull && v == .null {
        nullsFound += 1
        continue
      }
      if i != nullsFound { // check we have seen non null values
        stream.write(",")
        writeNewlineIfNeeded(to: &stream)
      }
      writeIndentIfNeeded(indentLevel + 1, to: &stream)
      try writeValue(v, to: &stream, indentLevel: indentLevel + 1)
    }
    writeNewlineIfNeeded(to: &stream)
    writeIndentIfNeeded(indentLevel, to: &stream)
    stream.write("]")
  }

  func writeObject<O: OutputStream>(_ o: [String: StructuredData], to stream: inout O, indentLevel: Int = 0) throws {
    if o.isEmpty {
      stream.write("{}")
      return
    }

    stream.write("{")
    writeNewlineIfNeeded(to: &stream)
    var i = 0
    var nullsFound = 0
    for (key, value) in o {
      defer { i += 1 }
      if skipNull && value == .null {
        nullsFound += 1
        continue
      }
      if i != nullsFound { // check we have seen non null values
        stream.write(",")
        writeNewlineIfNeeded(to: &stream)
      }
      writeIndentIfNeeded(indentLevel + 1, to: &stream)
      writeString(key, to: &stream)
      stream.write(prettyPrint ? ": " : ":")
      try writeValue(value, to: &stream, indentLevel: indentLevel + 1)
    }
    writeNewlineIfNeeded(to: &stream)
    writeIndentIfNeeded(indentLevel, to: &stream)
    stream.write("}")
  }

  func writeBool<O: OutputStream>(_ b: Bool, to stream: inout O) {
    switch b {
    case true:
      stream.write("true")

    case false:
      stream.write("false")
    }
  }

  func writeNull<O: OutputStream>(to stream: inout O) {
    stream.write("null")
  }

  func writeInteger<O: OutputStream>(_ i: Int, to stream: inout O) {
    stream.write(i.description)
  }

  func writeDouble<O: OutputStream>(_ d: Double, to stream: inout O) throws {
    guard d.isFinite else { throw Error.invalidNumber }
    stream.write(d.description)
  }

  func writeString<O: OutputStream>(_ s: String, to stream: inout O) {
    stream.write("\"")
    stream.write(s)
    stream.write("\"")
  }
}

extension JSONSerializer {
  public enum Error: String, ErrorProtocol {
    case invalidNumber
    // TODO(vdka): add option to serialize as a Base64 String
    case dataNotSupportedInJSON
  }
}

