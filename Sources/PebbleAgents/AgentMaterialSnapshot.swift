/// Stable, PebbleCore-free observation of one enchantment carried by a material stack.
///
/// This is descriptive data only. It grants no custody, ownership, or right to
/// mutate a physical inventory.
public struct AgentMaterialEnchantmentSnapshot: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let level: Int

    public init(id: String, level: Int) {
        self.id = id
        self.level = level
    }
}

/// Stack-relevant material identity normalized by a Pebble adapter.
///
/// `itemKey` is a canonical Pebble registry key rather than a runtime registry
/// index. `canonicalDataJSON` is the deterministic, bounded encoding of the
/// Pebble stack-data payload supported by the bridge. Count is deliberately not
/// part of identity; fungible units remain fungible.
public struct AgentMaterialIdentitySnapshot: Codable, Equatable, Hashable, Sendable {
    public let itemKey: String
    public let damage: Int
    public let enchantments: [AgentMaterialEnchantmentSnapshot]
    public let label: String?
    public let canonicalDataJSON: String

    public init(
        itemKey: String,
        damage: Int,
        enchantments: [AgentMaterialEnchantmentSnapshot],
        label: String?,
        canonicalDataJSON: String
    ) {
        self.itemKey = itemKey
        self.damage = damage
        self.enchantments = enchantments
        self.label = label
        self.canonicalDataJSON = canonicalDataJSON
    }
}

/// Read-only Civilization projection of a real Pebble `ItemStack`.
///
/// The physical stack remains authoritative. This value has no insertion,
/// extraction, or consumption behavior and must never be treated as a second
/// live inventory.
public struct AgentMaterialStackSnapshot: Codable, Equatable, Hashable, Sendable {
    public let identity: AgentMaterialIdentitySnapshot
    public let count: Int

    public init(identity: AgentMaterialIdentitySnapshot, count: Int) {
        self.identity = identity
        self.count = count
    }
}

/// Ordered, read-only observation of one physical custody location.
///
/// Slot order is significant and deterministic. `locationID` identifies where
/// physical custody was observed; it does not express social ownership.
public struct AgentMaterialCustodySnapshot: Codable, Equatable, Sendable {
    public let locationID: String
    public let slots: [AgentMaterialStackSnapshot?]

    public init(locationID: String, slots: [AgentMaterialStackSnapshot?]) {
        self.locationID = locationID
        self.slots = slots
    }
}
