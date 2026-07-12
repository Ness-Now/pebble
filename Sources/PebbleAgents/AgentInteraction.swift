public enum AgentResourceKind: String, Codable, Equatable {
    case sandboxResource
}

public struct AgentResourceInventory: Encodable, Equatable {
    public let capacity: Int
    public private(set) var sandboxResourceCount: Int

    public var totalCount: Int { sandboxResourceCount }
    public var isEmpty: Bool { totalCount == 0 }

    public init(capacity: Int = 8) {
        self.capacity = max(1, capacity)
        sandboxResourceCount = 0
    }

    public func count(of resource: AgentResourceKind) -> Int {
        switch resource {
        case .sandboxResource: return sandboxResourceCount
        }
    }

    public func canAdd(_ resource: AgentResourceKind, quantity: Int = 1) -> Bool {
        quantity > 0 && totalCount <= capacity - quantity
    }

    @discardableResult
    public mutating func add(_ resource: AgentResourceKind, quantity: Int = 1) -> Bool {
        guard canAdd(resource, quantity: quantity) else { return false }
        switch resource {
        case .sandboxResource:
            sandboxResourceCount += quantity
        }
        return true
    }
}

public struct AgentInteractionIntent: Equatable {
    public let interactionId: String
    public let agentId: String
    public let tick: Int
    public let target: AgentPosition
    public let resource: AgentResourceKind
    public let quantity: Int

    public init(
        interactionId: String,
        agentId: String,
        tick: Int,
        target: AgentPosition,
        resource: AgentResourceKind,
        quantity: Int = 1
    ) {
        self.interactionId = interactionId
        self.agentId = agentId
        self.tick = tick
        self.target = target
        self.resource = resource
        self.quantity = quantity
    }
}

public enum AgentInteractionStatus: String, Codable, Equatable {
    case succeeded
    case blocked
    case inventoryFull
}

public struct AgentInventoryDelta: Encodable, Equatable {
    public let resource: AgentResourceKind
    public let quantity: Int

    public init(resource: AgentResourceKind, quantity: Int) {
        self.resource = resource
        self.quantity = quantity
    }
}

public struct AgentInteractionOutcome: Encodable, Equatable {
    public let interactionId: String
    public let agentId: String
    public let tick: Int
    public let target: AgentPosition
    public let resource: AgentResourceKind
    public let status: AgentInteractionStatus
    public let inventoryDelta: AgentInventoryDelta
    public let reason: String

    public init(
        interactionId: String,
        agentId: String,
        tick: Int,
        target: AgentPosition,
        resource: AgentResourceKind,
        status: AgentInteractionStatus,
        inventoryDelta: AgentInventoryDelta,
        reason: String
    ) {
        self.interactionId = interactionId
        self.agentId = agentId
        self.tick = tick
        self.target = target
        self.resource = resource
        self.status = status
        self.inventoryDelta = inventoryDelta
        self.reason = reason
    }
}

public enum AgentInteractionSandbox {
    public static func contains(
        target: AgentPosition,
        anchor: AgentPosition,
        horizontalRadius: Int
    ) -> Bool {
        horizontalRadius >= 0
            && abs(target.x - anchor.x) <= horizontalRadius
            && abs(target.z - anchor.z) <= horizontalRadius
    }

    public static func isCardinalAdjacent(target: AgentPosition, actor: AgentPosition) -> Bool {
        target.y == actor.y
            && abs(target.x - actor.x) + abs(target.z - actor.z) == 1
    }
}
