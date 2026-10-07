import Foundation
import CoreFoundation

/// Materialize the existing dictionary/array representation using the standard
/// decoder's numeric semantics. JSONSerialization can produce NSDecimalNumber
/// values whose doubleValue differs from the number in the original JSON, and
/// can materialize integer-form -0 as unsigned zero.
///
/// This temporary decoding box returns only existing Swift/Foundation values;
/// it does not retain another JSON tree or parse numeric tokens itself.
private struct PersistenceJSONObject: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let boolean = try? container.decode(Bool.self) {
            value = boolean
        } else if let integer = try? container.decode(Int.self), integer != 0 {
            value = integer
        } else if let number = try? container.decode(Double.self) {
            // Decode zero as Double so that -0 keeps its sign. Nonzero Int
            // values retain integer semantics for the existing integer owners.
            value = number
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([PersistenceJSONObject].self) {
            value = array.map(\.value)
        } else {
            value = try container.decode([String: PersistenceJSONObject].self)
                .mapValues(\.value)
        }
    }
}

func decodePersistenceJSON(_ bytes: Data) throws -> Any {
    try JSONDecoder().decode(PersistenceJSONObject.self, from: bytes).value
}

/// Read a schema-owned Double without treating CFBoolean as a number or using
/// NSDecimalNumber.doubleValue. Direct native Doubles need no conversion; other
/// numeric objects re-enter the standard decoder through their JSON bytes.
/// Missing and malformed values remain the individual owner's fallback choice.
func persistedDouble(_ value: Any?) -> Double? {
    guard let value else { return nil }
    if type(of: value) == Double.self { return value as? Double }
    guard let number = value as? NSNumber,
          CFGetTypeID(number) != CFBooleanGetTypeID(),
          let bytes = try? JSONSerialization.data(
            withJSONObject: number, options: [.fragmentsAllowed]
          ) else { return nil }
    return try? JSONDecoder().decode(Double.self, from: bytes)
}
