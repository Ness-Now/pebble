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
    public let distanceManhattan: Int
    public let quantityAvailable: Int
    public let source: AgentResourceObservationSource

    public init(
        resource: AgentResourceKind,
        target: AgentPosition,
        direction: AgentCardinalDirection,
        distanceManhattan: Int = 1,
        quantityAvailable: Int,
        source: AgentResourceObservationSource
    ) {
        self.resource = resource
        self.target = target
        self.direction = direction
        self.distanceManhattan = distanceManhattan
        self.quantityAvailable = quantityAvailable
        self.source = source
    }
}

public enum AgentResourceObservationError: Error, Equatable {
    case invalidMaximumDistance(Int)
    case tooManyObservations(Int)
    case nonPositiveQuantity(AgentPosition)
    case targetMatchesObserver(AgentPosition)
    case verticalDifference(AgentPosition)
    case targetOutsideRadius(AgentPosition)
    case distanceMismatch(AgentPosition)
    case directionMismatch(AgentPosition)
    case duplicateTarget(AgentPosition)
}

public enum AgentResourcePerception {
    public static let maximumObservationCount = 8
    public static let maximumDistance = 8

    public static func normalize(
        observerPosition: AgentPosition,
        observations: [AgentResourceObservation],
        maximumDistance: Int = 1
    ) throws -> [AgentResourceObservation] {
        guard (1...Self.maximumDistance).contains(maximumDistance) else {
            throw AgentResourceObservationError.invalidMaximumDistance(maximumDistance)
        }
        guard observations.count <= maximumObservationCount else {
            throw AgentResourceObservationError.tooManyObservations(observations.count)
        }
        var targets = Set<String>()
        for observation in observations {
            guard observation.quantityAvailable > 0 else {
                throw AgentResourceObservationError.nonPositiveQuantity(observation.target)
            }
            guard observation.target != observerPosition else {
                throw AgentResourceObservationError.targetMatchesObserver(observation.target)
            }
            guard observation.target.y == observerPosition.y else {
                throw AgentResourceObservationError.verticalDifference(observation.target)
            }
            let distance = abs(observation.target.x - observerPosition.x)
                + abs(observation.target.z - observerPosition.z)
            guard distance <= maximumDistance else {
                throw AgentResourceObservationError.targetOutsideRadius(observation.target)
            }
            guard observation.distanceManhattan == distance else {
                throw AgentResourceObservationError.distanceMismatch(observation.target)
            }
            guard direction(observerPosition: observerPosition, target: observation.target)
                    == observation.direction else {
                throw AgentResourceObservationError.directionMismatch(observation.target)
            }
            let key = positionKey(observation.target)
            guard targets.insert(key).inserted else {
                throw AgentResourceObservationError.duplicateTarget(observation.target)
            }
        }
        return observations.sorted(by: sortsBefore)
    }

    fileprivate static func sortsBefore(
        _ lhs: AgentResourceObservation,
        _ rhs: AgentResourceObservation
    ) -> Bool {
        if lhs.distanceManhattan != rhs.distanceManhattan {
            return lhs.distanceManhattan < rhs.distanceManhattan
        }
        let lhsDirection = directionIndex(lhs.direction)
        let rhsDirection = directionIndex(rhs.direction)
        if lhsDirection != rhsDirection { return lhsDirection < rhsDirection }
        if lhs.target.x != rhs.target.x { return lhs.target.x < rhs.target.x }
        if lhs.target.y != rhs.target.y { return lhs.target.y < rhs.target.y }
        if lhs.target.z != rhs.target.z { return lhs.target.z < rhs.target.z }
        if lhs.resource.rawValue != rhs.resource.rawValue {
            return lhs.resource.rawValue < rhs.resource.rawValue
        }
        return lhs.source.rawValue < rhs.source.rawValue
    }

    public static func direction(
        observerPosition: AgentPosition,
        target: AgentPosition
    ) -> AgentCardinalDirection? {
        guard observerPosition.y == target.y else { return nil }
        let dx = target.x - observerPosition.x
        let dz = target.z - observerPosition.z
        guard dx != 0 || dz != 0 else { return nil }
        if abs(dx) >= abs(dz), dx != 0 {
            return dx > 0 ? .east : .west
        }
        return dz > 0 ? .south : .north
    }

    private static func directionIndex(_ direction: AgentCardinalDirection) -> Int {
        AgentCardinalDirection.allCases.firstIndex(of: direction) ?? 0
    }

    private static func positionKey(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }
}

public struct AgentResourceTarget: Codable, Equatable {
    public let resource: AgentResourceKind
    public let target: AgentPosition
    public let source: AgentResourceObservationSource
    public let distanceManhattan: Int
    public let selectedAtTick: Int
    public let lastSeenAtTick: Int

    public init(
        resource: AgentResourceKind,
        target: AgentPosition,
        source: AgentResourceObservationSource,
        distanceManhattan: Int,
        selectedAtTick: Int,
        lastSeenAtTick: Int
    ) {
        self.resource = resource
        self.target = target
        self.source = source
        self.distanceManhattan = distanceManhattan
        self.selectedAtTick = selectedAtTick
        self.lastSeenAtTick = lastSeenAtTick
    }
}

public enum AgentResourceTargeting {
    public static func select(
        current: AgentResourceTarget?,
        observations: [AgentResourceObservation],
        inventory: AgentResourceInventory,
        tick: Int
    ) -> AgentResourceTarget? {
        if let current,
           inventory.canAdd(current.resource),
           let retained = observations.first(where: {
               $0.target == current.target
                   && $0.resource == current.resource
                   && $0.source == current.source
           }) {
            return AgentResourceTarget(
                resource: retained.resource,
                target: retained.target,
                source: retained.source,
                distanceManhattan: retained.distanceManhattan,
                selectedAtTick: current.selectedAtTick,
                lastSeenAtTick: tick
            )
        }
        guard let selected = observations.sorted(by: AgentResourcePerception.sortsBefore)
            .first(where: { inventory.canAdd($0.resource) }) else {
            return nil
        }
        return AgentResourceTarget(
            resource: selected.resource,
            target: selected.target,
            source: selected.source,
            distanceManhattan: selected.distanceManhattan,
            selectedAtTick: tick,
            lastSeenAtTick: tick
        )
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

public struct AgentSandboxFixtureMutationBoundary: Codable, Equatable {
    public let target: AgentPosition

    public var permittedPositions: [AgentPosition] { [target] }

    public init(target: AgentPosition) {
        self.target = target
    }

    public func permits(_ position: AgentPosition) -> Bool {
        position == target
    }
}
