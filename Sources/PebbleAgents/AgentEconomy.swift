public struct AgentResourceAmount: Codable, Equatable {
    public let resource: AgentResourceKind
    public let quantity: Int

    public init(resource: AgentResourceKind, quantity: Int) {
        self.resource = resource
        self.quantity = quantity
    }
}

public enum AgentResourceAmounts {
    public static func normalize(_ amounts: [AgentResourceAmount]) -> [AgentResourceAmount] {
        AgentResourceKind.allCases.compactMap { resource in
            let total = amounts.filter { $0.resource == resource }.reduce(0) { $0 + max(0, $1.quantity) }
            return total > 0 ? AgentResourceAmount(resource: resource, quantity: total) : nil
        }
    }
}

public struct AgentCampStock: Encodable, Equatable {
    public let capacity: Int
    public private(set) var sandboxResourceCount: Int
    public private(set) var foodRawCount: Int
    public private(set) var woodCount: Int
    public private(set) var stoneCount: Int

    public var totalCount: Int {
        sandboxResourceCount + foodRawCount + woodCount + stoneCount
    }
    public var isEmpty: Bool { totalCount == 0 }
    public var amounts: [AgentResourceAmount] {
        AgentResourceKind.allCases.compactMap { resource in
            let quantity = count(of: resource)
            return quantity > 0 ? AgentResourceAmount(resource: resource, quantity: quantity) : nil
        }
    }

    public init(capacity: Int = 64) {
        self.capacity = max(1, capacity)
        sandboxResourceCount = 0
        foodRawCount = 0
        woodCount = 0
        stoneCount = 0
    }

    public func count(of resource: AgentResourceKind) -> Int {
        switch resource {
        case .sandboxResource: return sandboxResourceCount
        case .foodRaw: return foodRawCount
        case .wood: return woodCount
        case .stone: return stoneCount
        }
    }

    public func canAdd(_ resource: AgentResourceKind, quantity: Int = 1) -> Bool {
        quantity > 0 && quantity <= capacity - totalCount
    }

    public func canAdd(_ amounts: [AgentResourceAmount]) -> Bool {
        let normalized = AgentResourceAmounts.normalize(amounts)
        return !normalized.isEmpty
            && normalized.allSatisfy { $0.quantity > 0 }
            && normalized.reduce(totalCount) { $0 + $1.quantity } <= capacity
    }

    public func canRemove(_ resource: AgentResourceKind, quantity: Int = 1) -> Bool {
        quantity > 0 && count(of: resource) >= quantity
    }

    public func canRemove(_ amounts: [AgentResourceAmount]) -> Bool {
        let normalized = AgentResourceAmounts.normalize(amounts)
        return !normalized.isEmpty && normalized.allSatisfy {
            canRemove($0.resource, quantity: $0.quantity)
        }
    }

    @discardableResult
    public mutating func add(_ resource: AgentResourceKind, quantity: Int = 1) -> Bool {
        guard canAdd(resource, quantity: quantity) else { return false }
        switch resource {
        case .sandboxResource: sandboxResourceCount += quantity
        case .foodRaw: foodRawCount += quantity
        case .wood: woodCount += quantity
        case .stone: stoneCount += quantity
        }
        return true
    }

    @discardableResult
    public mutating func add(_ amounts: [AgentResourceAmount]) -> Bool {
        let normalized = AgentResourceAmounts.normalize(amounts)
        guard canAdd(normalized) else { return false }
        for amount in normalized {
            guard add(amount.resource, quantity: amount.quantity) else { return false }
        }
        return true
    }

    @discardableResult
    public mutating func remove(_ resource: AgentResourceKind, quantity: Int = 1) -> Bool {
        guard canRemove(resource, quantity: quantity) else { return false }
        switch resource {
        case .sandboxResource: sandboxResourceCount -= quantity
        case .foodRaw: foodRawCount -= quantity
        case .wood: woodCount -= quantity
        case .stone: stoneCount -= quantity
        }
        return true
    }

    @discardableResult
    public mutating func remove(_ amounts: [AgentResourceAmount]) -> Bool {
        let normalized = AgentResourceAmounts.normalize(amounts)
        guard canRemove(normalized) else { return false }
        for amount in normalized {
            guard remove(amount.resource, quantity: amount.quantity) else { return false }
        }
        return true
    }

    private enum CodingKeys: String, CodingKey {
        case capacity, sandboxResourceCount, foodRawCount, woodCount, stoneCount
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(capacity, forKey: .capacity)
        try container.encode(sandboxResourceCount, forKey: .sandboxResourceCount)
        try container.encode(foodRawCount, forKey: .foodRawCount)
        try container.encode(woodCount, forKey: .woodCount)
        try container.encode(stoneCount, forKey: .stoneCount)
    }
}

public struct AgentDeliveryIntent: Equatable {
    public let deliveryId: String
    public let agentId: String
    public let tick: Int
    public let position: AgentPosition

    public init(deliveryId: String, agentId: String, tick: Int, position: AgentPosition) {
        self.deliveryId = deliveryId
        self.agentId = agentId
        self.tick = tick
        self.position = position
    }
}

public enum AgentDeliveryStatus: String, Codable, Equatable {
    case succeeded
    case blocked
    case campStockFull
}

public struct AgentDeliveryOutcome: Encodable, Equatable {
    public let deliveryId: String
    public let agentId: String
    public let tick: Int
    public let status: AgentDeliveryStatus
    public let transferred: [AgentResourceAmount]
    public let reason: String

    public init(
        deliveryId: String,
        agentId: String,
        tick: Int,
        status: AgentDeliveryStatus,
        transferred: [AgentResourceAmount],
        reason: String
    ) {
        self.deliveryId = deliveryId
        self.agentId = agentId
        self.tick = tick
        self.status = status
        self.transferred = AgentResourceAmounts.normalize(transferred)
        self.reason = reason
    }
}

public struct AgentResourceConservationSnapshot: Encodable, Equatable {
    public let harvested: [AgentResourceAmount]
    public let carried: [AgentResourceAmount]
    public let campStock: [AgentResourceAmount]
    public let consumed: [AgentResourceAmount]
    public let constructionEscrow: [AgentResourceAmount]
    public let constructed: [AgentResourceAmount]
    public let harvestedTotal: Int
    public let carriedTotal: Int
    public let campStockTotal: Int
    public let consumedTotal: Int
    public let constructionEscrowTotal: Int
    public let constructedTotal: Int
    public let balanced: Bool

    public init(
        harvested: [AgentResourceAmount],
        carried: [AgentResourceAmount],
        campStock: [AgentResourceAmount],
        consumed: [AgentResourceAmount] = [],
        constructionEscrow: [AgentResourceAmount] = [],
        constructed: [AgentResourceAmount] = []
    ) {
        let normalizedHarvested = AgentResourceAmounts.normalize(harvested)
        let normalizedCarried = AgentResourceAmounts.normalize(carried)
        let normalizedCampStock = AgentResourceAmounts.normalize(campStock)
        let normalizedConsumed = AgentResourceAmounts.normalize(consumed)
        let normalizedEscrow = AgentResourceAmounts.normalize(constructionEscrow)
        let normalizedConstructed = AgentResourceAmounts.normalize(constructed)
        self.harvested = normalizedHarvested
        self.carried = normalizedCarried
        self.campStock = normalizedCampStock
        self.consumed = normalizedConsumed
        self.constructionEscrow = normalizedEscrow
        self.constructed = normalizedConstructed
        harvestedTotal = normalizedHarvested.reduce(0) { $0 + $1.quantity }
        carriedTotal = normalizedCarried.reduce(0) { $0 + $1.quantity }
        campStockTotal = normalizedCampStock.reduce(0) { $0 + $1.quantity }
        consumedTotal = normalizedConsumed.reduce(0) { $0 + $1.quantity }
        constructionEscrowTotal = normalizedEscrow.reduce(0) { $0 + $1.quantity }
        constructedTotal = normalizedConstructed.reduce(0) { $0 + $1.quantity }
        balanced = AgentResourceKind.allCases.allSatisfy { resource in
            let produced = normalizedHarvested.first { $0.resource == resource }?.quantity ?? 0
            let carried = normalizedCarried.first { $0.resource == resource }?.quantity ?? 0
            let stocked = normalizedCampStock.first { $0.resource == resource }?.quantity ?? 0
            let consumed = normalizedConsumed.first { $0.resource == resource }?.quantity ?? 0
            let escrow = normalizedEscrow.first { $0.resource == resource }?.quantity ?? 0
            let built = normalizedConstructed.first { $0.resource == resource }?.quantity ?? 0
            return produced == carried + stocked + consumed + escrow + built
        }
    }

    private enum CodingKeys: String, CodingKey {
        case harvested, carried, campStock, consumed, constructionEscrow, constructed
        case harvestedTotal, carriedTotal, campStockTotal, consumedTotal
        case constructionEscrowTotal, constructedTotal, balanced
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(harvested, forKey: .harvested)
        try container.encode(carried, forKey: .carried)
        try container.encode(campStock, forKey: .campStock)
        try container.encode(consumed, forKey: .consumed)
        try container.encode(harvestedTotal, forKey: .harvestedTotal)
        try container.encode(carriedTotal, forKey: .carriedTotal)
        try container.encode(campStockTotal, forKey: .campStockTotal)
        try container.encode(consumedTotal, forKey: .consumedTotal)
        if constructionEscrowTotal > 0 || constructedTotal > 0 {
            try container.encode(constructionEscrow, forKey: .constructionEscrow)
            try container.encode(constructed, forKey: .constructed)
            try container.encode(constructionEscrowTotal, forKey: .constructionEscrowTotal)
            try container.encode(constructedTotal, forKey: .constructedTotal)
        }
        try container.encode(balanced, forKey: .balanced)
    }
}
