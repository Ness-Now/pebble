import Foundation
import CoreFoundation

/// Only the typed payloads historically passed through entity/Player sanitation.
/// Normalize only after strict typed decoding fails, never on a whole save.
enum LegacyBooleanSchema {
    case entityData, itemStack, itemStacks, effects, tradeOffers
}

private func legacyBooleanFields(_ object: [String: Any], keys: [String]) -> [String: Any]? {
    var replacement: [String: Any]?
    for key in keys {
        guard let number = object[key] as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID() else { continue }
        let boolean: Bool
        if number.compare(NSNumber(value: 0)) == .orderedSame { boolean = false }
        else if number.compare(NSNumber(value: 1)) == .orderedSame { boolean = true }
        else { continue }
        if replacement == nil { replacement = object }
        replacement![key] = boolean
    }
    // Unsupported values remain unchanged for the existing corruption policy.
    // Numeric siblings are never inspected.
    return replacement
}

/// nil means no legacy token changed. Current payloads keep their original
/// collections; a copy is made only along a path containing a converted flag.
private func legacyBooleanReplacement(_ raw: Any, schema: LegacyBooleanSchema) -> Any? {
    switch schema {
    case .entityData:
        guard let object = raw as? [String: Any] else { return nil }
        return legacyBooleanFields(object, keys: [
            "puffed", "grazing", "baby", "brown", "sheared", "charged",
            "captain", "cold", "hanging", "aiming", "airborne", "crossed",
            "leatherBoots", "persistent"
        ])
    case .itemStack:
        guard let stack = raw as? [String: Any], let data = stack["data"] as? [String: Any] else { return nil }
        var bag = legacyBooleanFields(data, keys: ["charged"])
        if let contents = data["contents"],
           let replacement = legacyBooleanReplacement(contents, schema: .itemStacks) {
            if bag == nil { bag = data }
            bag!["contents"] = replacement
        }
        guard let bag else { return nil }
        var replacement = stack; replacement["data"] = bag
        return replacement
    case .itemStacks, .effects, .tradeOffers:
        guard let array = raw as? [Any] else { return nil }
        var replacement: [Any]?
        for (index, value) in array.enumerated() {
            let changed: Any?
            switch schema {
            case .itemStacks:
                changed = legacyBooleanReplacement(value, schema: .itemStack)
            case .effects:
                changed = (value as? [String: Any]).flatMap {
                    legacyBooleanFields($0, keys: ["ambient", "showParticles"])
                }
            case .tradeOffers:
                guard let offer = value as? [String: Any] else { continue }
                var changedOffer: [String: Any]?
                for key in ["buyA", "buyB", "sell"] {
                    if let stack = offer[key], let changed = legacyBooleanReplacement(stack, schema: .itemStack) {
                        if changedOffer == nil { changedOffer = offer }
                        changedOffer![key] = changed
                    }
                }
                changed = changedOffer
            default: preconditionFailure("Non-array schema")
            }
            if let changed {
                if replacement == nil { replacement = array }
                replacement![index] = changed
            }
        }
        return replacement
    }
}

func decodeLegacyBooleanJSON<T: Decodable>(
    _ type: T.Type, from raw: Any, schema: LegacyBooleanSchema,
    options: JSONSerialization.WritingOptions = []
) -> T? {
    guard let bytes = try? JSONSerialization.data(withJSONObject: raw, options: options) else { return nil }
    if let current = try? JSONDecoder().decode(type, from: bytes) { return current }
    guard let normalized = legacyBooleanReplacement(raw, schema: schema),
          let legacyBytes = try? JSONSerialization.data(withJSONObject: normalized, options: options)
    else { return nil }
    return try? JSONDecoder().decode(type, from: legacyBytes)
}
