import Foundation
import PebbleAgents
import PebbleCore

enum PebbleAgentMaterialBridgeError: Error, Equatable {
    case invalidItemID(Int)
    case unknownItemKey(String)
    case invalidCount(Int)
    case invalidDamage(Int)
    case invalidEnchantment
    case stateTooLarge
    case unsupportedNestedInventory
    case invalidStackData
    case nonCanonicalStackData
    case invalidLocationID
    case tooManySlots(Int)
}

/// Converts between physical Pebble stacks and deterministic Civilization
/// observations. The bridge owns no inventory and never mutates a stack.
struct PebbleAgentMaterialSnapshotBridge {
    static let maximumSnapshotSlots = 54
    static let maximumEnchantments = 32
    static let maximumLabelLength = 256
    static let maximumCanonicalDataBytes = 4096

    func snapshot(of stack: ItemStack) throws -> AgentMaterialStackSnapshot {
        guard stack.id >= 0, stack.id < itemDefs.count else {
            throw PebbleAgentMaterialBridgeError.invalidItemID(stack.id)
        }
        let definition = itemDef(stack.id)
        guard stack.count > 0, stack.count <= definition.maxStack else {
            throw PebbleAgentMaterialBridgeError.invalidCount(stack.count)
        }
        let maximumDamage = maxDamageOf(stack)
        guard stack.damage >= 0,
              maximumDamage > 0 ? stack.damage < maximumDamage : stack.damage == 0 else {
            throw PebbleAgentMaterialBridgeError.invalidDamage(stack.damage)
        }
        guard stack.ench.count <= Self.maximumEnchantments,
              stack.ench.allSatisfy({
                  !$0.id.isEmpty && $0.id.count <= 128 && $0.lvl > 0
              }) else {
            throw PebbleAgentMaterialBridgeError.invalidEnchantment
        }
        guard (stack.label?.count ?? 0) <= Self.maximumLabelLength else {
            throw PebbleAgentMaterialBridgeError.stateTooLarge
        }
        guard stack.data.contents == nil else {
            throw PebbleAgentMaterialBridgeError.unsupportedNestedInventory
        }
        let canonicalDataJSON = try encodeCanonicalData(stack.data)
        return AgentMaterialStackSnapshot(
            identity: AgentMaterialIdentitySnapshot(
                itemKey: definition.name,
                damage: stack.damage,
                enchantments: stack.ench.map {
                    AgentMaterialEnchantmentSnapshot(id: $0.id, level: $0.lvl)
                },
                label: stack.label,
                canonicalDataJSON: canonicalDataJSON
            ),
            count: stack.count
        )
    }

    func itemStack(from snapshot: AgentMaterialStackSnapshot) throws -> ItemStack {
        guard let id = iidOpt(snapshot.identity.itemKey) else {
            throw PebbleAgentMaterialBridgeError.unknownItemKey(snapshot.identity.itemKey)
        }
        guard snapshot.identity.enchantments.count <= Self.maximumEnchantments,
              snapshot.identity.enchantments.allSatisfy({
                  !$0.id.isEmpty && $0.id.count <= 128 && $0.level > 0
              }) else {
            throw PebbleAgentMaterialBridgeError.invalidEnchantment
        }
        guard (snapshot.identity.label?.count ?? 0) <= Self.maximumLabelLength else {
            throw PebbleAgentMaterialBridgeError.stateTooLarge
        }
        let data = try decodeCanonicalData(snapshot.identity.canonicalDataJSON)
        guard data.contents == nil else {
            throw PebbleAgentMaterialBridgeError.unsupportedNestedInventory
        }
        let stack = ItemStack(
            id,
            snapshot.count,
            damage: snapshot.identity.damage,
            ench: snapshot.identity.enchantments.map { EnchInstance($0.id, $0.level) },
            label: snapshot.identity.label,
            data: data
        )
        guard try self.snapshot(of: stack) == snapshot else {
            throw PebbleAgentMaterialBridgeError.nonCanonicalStackData
        }
        return stack
    }

    func custodySnapshot(
        locationID: String,
        slots: [ItemStack?]
    ) throws -> AgentMaterialCustodySnapshot {
        guard !locationID.isEmpty, locationID.count <= 256 else {
            throw PebbleAgentMaterialBridgeError.invalidLocationID
        }
        guard slots.count <= Self.maximumSnapshotSlots else {
            throw PebbleAgentMaterialBridgeError.tooManySlots(slots.count)
        }
        return AgentMaterialCustodySnapshot(
            locationID: locationID,
            slots: try slots.map { stack in
                try stack.map(snapshot(of:))
            }
        )
    }

    func canonicalBytes(of snapshot: AgentMaterialStackSnapshot) throws -> Data {
        try canonicalEncoder().encode(snapshot)
    }

    func canonicalBytes(of snapshot: AgentMaterialCustodySnapshot) throws -> Data {
        try canonicalEncoder().encode(snapshot)
    }

    func fingerprint(of snapshot: AgentMaterialCustodySnapshot) throws -> String {
        String(decoding: try canonicalBytes(of: snapshot), as: UTF8.self)
    }

    func normalizedTotals(
        in snapshot: AgentMaterialCustodySnapshot
    ) -> [AgentMaterialStackSnapshot] {
        var totals: [AgentMaterialStackSnapshot] = []
        for stack in snapshot.slots.compactMap({ $0 }) {
            if let index = totals.firstIndex(where: { $0.identity == stack.identity }) {
                totals[index] = AgentMaterialStackSnapshot(
                    identity: stack.identity,
                    count: totals[index].count + stack.count
                )
            } else {
                totals.append(stack)
            }
        }
        return totals.sorted { lhs, rhs in
            identitySortKey(lhs.identity) < identitySortKey(rhs.identity)
        }
    }

    private func encodeCanonicalData(_ data: StackData) throws -> String {
        let bytes = try canonicalEncoder().encode(data)
        guard bytes.count <= Self.maximumCanonicalDataBytes else {
            throw PebbleAgentMaterialBridgeError.stateTooLarge
        }
        return String(decoding: bytes, as: UTF8.self)
    }

    private func decodeCanonicalData(_ text: String) throws -> StackData {
        guard let bytes = text.data(using: .utf8),
              bytes.count <= Self.maximumCanonicalDataBytes,
              let data = try? JSONDecoder().decode(StackData.self, from: bytes) else {
            throw PebbleAgentMaterialBridgeError.invalidStackData
        }
        guard try encodeCanonicalData(data) == text else {
            throw PebbleAgentMaterialBridgeError.nonCanonicalStackData
        }
        return data
    }

    private func canonicalEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private func identitySortKey(_ identity: AgentMaterialIdentitySnapshot) -> String {
        let snapshot = AgentMaterialStackSnapshot(identity: identity, count: 1)
        return (try? String(decoding: canonicalBytes(of: snapshot), as: UTF8.self)) ?? ""
    }
}
