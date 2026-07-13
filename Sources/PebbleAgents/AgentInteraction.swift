public enum AgentResourceKind: String, Codable, Equatable {
    case sandboxResource
}

public enum AgentResourceObservationSource: String, Codable, Equatable {
    case sandboxFixture
}

public struct AgentResourceObservation: Codable, Equatable {
    public let resource: AgentResourceKind
    public let target: AgentPosition
    public let direction: AgentCardinalDirection
    public let quantityAvailable: Int
    public let source: AgentResourceObservationSource

    public init(
        resource: AgentResourceKind,
        target: AgentPosition,
        direction: AgentCardinalDirection,
        quantityAvailable: Int,
        source: AgentResourceObservationSource
    ) {
        self.resource = resource
        self.target = target
        self.direction = direction
        self.quantityAvailable = quantityAvailable
        self.source = source
    }
}

public enum AgentResourceObservationError: Error, Equatable {
    case tooManyObservations(Int)
    case nonPositiveQuantity(AgentPosition)
    case nonAdjacentTarget(AgentPosition)
    case directionMismatch(AgentPosition)
    case duplicateTarget(AgentPosition)
}

public enum AgentResourcePerception {
    public static let maximumObservationCount = AgentCardinalDirection.allCases.count

    public static func normalize(
        observerPosition: AgentPosition,
        observations: [AgentResourceObservation]
    ) throws -> [AgentResourceObservation] {
        guard observations.count <= maximumObservationCount else {
            throw AgentResourceObservationError.tooManyObservations(observations.count)
        }
        var targets = Set<String>()
        for observation in observations {
            guard observation.quantityAvailable > 0 else {
                throw AgentResourceObservationError.nonPositiveQuantity(observation.target)
            }
            guard AgentInteractionSandbox.isCardinalAdjacent(
                target: observation.target,
                actor: observerPosition
            ) else {
                throw AgentResourceObservationError.nonAdjacentTarget(observation.target)
            }
            let expectedTarget = AgentPosition(
                x: observerPosition.x + observation.direction.dx,
                y: observerPosition.y,
                z: observerPosition.z + observation.direction.dz
            )
            guard observation.target == expectedTarget else {
                throw AgentResourceObservationError.directionMismatch(observation.target)
            }
            let key = positionKey(observation.target)
            guard targets.insert(key).inserted else {
                throw AgentResourceObservationError.duplicateTarget(observation.target)
            }
        }
        return observations.sorted {
            let lhsDirection = directionIndex($0.direction)
            let rhsDirection = directionIndex($1.direction)
            if lhsDirection != rhsDirection { return lhsDirection < rhsDirection }
            if $0.target.x != $1.target.x { return $0.target.x < $1.target.x }
            if $0.target.y != $1.target.y { return $0.target.y < $1.target.y }
            if $0.target.z != $1.target.z { return $0.target.z < $1.target.z }
            if $0.resource.rawValue != $1.resource.rawValue {
                return $0.resource.rawValue < $1.resource.rawValue
            }
            return $0.source.rawValue < $1.source.rawValue
        }
    }

    private static func directionIndex(_ direction: AgentCardinalDirection) -> Int {
        AgentCardinalDirection.allCases.firstIndex(of: direction) ?? 0
    }

    private static func positionKey(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }
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
