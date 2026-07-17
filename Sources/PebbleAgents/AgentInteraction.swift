public enum AgentResourceKind: String, Codable, Equatable, CaseIterable, Sendable {
    case sandboxResource
    case foodRaw
    case wood
    case stone

    public static let economyFixtureOrder: [AgentResourceKind] = [.foodRaw, .wood, .stone]

    fileprivate var selectionPriority: Int {
        switch self {
        case .foodRaw: return 0
        case .wood: return 1
        case .stone: return 2
        case .sandboxResource: return 3
        }
    }
}

public enum AgentResourceObservationSource: String, Codable, Equatable, CaseIterable, Sendable {
    case sandboxFixture
    case naturalWorld
    case localEcology

    fileprivate var selectionPriority: Int {
        switch self {
        case .sandboxFixture: return 0
        case .naturalWorld: return 1
        case .localEcology: return 2
        }
    }
}

public struct AgentResourceIdentity: Codable, Equatable, Hashable {
    public let source: AgentResourceObservationSource
    public let position: AgentPosition
    public let resource: AgentResourceKind
    public let expectedBlockFingerprint: Int?
    public let ecologyPatchID: AgentEcologyPatchID?

    public init(
        source: AgentResourceObservationSource,
        position: AgentPosition,
        resource: AgentResourceKind,
        expectedBlockFingerprint: Int? = nil,
        ecologyPatchID: AgentEcologyPatchID? = nil
    ) {
        self.source = source
        self.position = position
        self.resource = resource
        self.expectedBlockFingerprint = expectedBlockFingerprint
        self.ecologyPatchID = ecologyPatchID
    }

    public var stableKey: String {
        let fingerprint = expectedBlockFingerprint.map(String.init) ?? "fixture"
        let historical = "\(source.rawValue):\(resource.rawValue):\(position.x),\(position.y),\(position.z):\(fingerprint)"
        return ecologyPatchID.map { "\(historical):\($0.rawValue)" } ?? historical
    }
}

public struct AgentResourceObservation: Codable, Equatable {
    public let resource: AgentResourceKind
    public let target: AgentPosition
    public let direction: AgentCardinalDirection
    public let distanceManhattan: Int
    public let quantityAvailable: Int
    public let source: AgentResourceObservationSource
    public let expectedBlockFingerprint: Int?
    public let ecologyPatchID: AgentEcologyPatchID?
    public let observationTick: Int?

    public var identity: AgentResourceIdentity {
        AgentResourceIdentity(
            source: source,
            position: target,
            resource: resource,
            expectedBlockFingerprint: expectedBlockFingerprint,
            ecologyPatchID: ecologyPatchID
        )
    }

    public init(
        resource: AgentResourceKind,
        target: AgentPosition,
        direction: AgentCardinalDirection,
        distanceManhattan: Int = 1,
        quantityAvailable: Int,
        source: AgentResourceObservationSource,
        expectedBlockFingerprint: Int? = nil,
        ecologyPatchID: AgentEcologyPatchID? = nil,
        observationTick: Int? = nil
    ) {
        self.resource = resource
        self.target = target
        self.direction = direction
        self.distanceManhattan = distanceManhattan
        self.quantityAvailable = quantityAvailable
        self.source = source
        self.expectedBlockFingerprint = expectedBlockFingerprint
        self.ecologyPatchID = ecologyPatchID
        self.observationTick = observationTick
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
    case missingNaturalFingerprint(AgentPosition)
    case unexpectedFixtureFingerprint(AgentPosition)
    case invalidEcologyObservation(AgentPosition)
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
            if observation.source == .sandboxFixture,
               observation.target.y != observerPosition.y {
                throw AgentResourceObservationError.verticalDifference(observation.target)
            }
            let distance = abs(observation.target.x - observerPosition.x)
                + abs(observation.target.y - observerPosition.y)
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
            switch observation.source {
            case .sandboxFixture:
                guard observation.expectedBlockFingerprint == nil,
                      observation.ecologyPatchID == nil,
                      observation.observationTick == nil else {
                    throw AgentResourceObservationError.unexpectedFixtureFingerprint(observation.target)
                }
            case .naturalWorld:
                guard observation.expectedBlockFingerprint != nil,
                      observation.ecologyPatchID == nil,
                      observation.observationTick == nil,
                      observation.resource == .wood || observation.resource == .stone else {
                    throw AgentResourceObservationError.missingNaturalFingerprint(observation.target)
                }
            case .localEcology:
                guard observation.expectedBlockFingerprint != nil,
                      observation.ecologyPatchID != nil,
                      observation.observationTick != nil,
                      observation.resource == .foodRaw else {
                    throw AgentResourceObservationError.invalidEcologyObservation(observation.target)
                }
            }
            let key = positionKey(observation.target)
            guard targets.insert(key).inserted else {
                throw AgentResourceObservationError.duplicateTarget(observation.target)
            }
        }
        return observations.sorted(by: sortsBefore)
    }

    public static func sortsBefore(
        _ lhs: AgentResourceObservation,
        _ rhs: AgentResourceObservation
    ) -> Bool {
        if lhs.resource.selectionPriority != rhs.resource.selectionPriority {
            return lhs.resource.selectionPriority < rhs.resource.selectionPriority
        }
        if lhs.source.selectionPriority != rhs.source.selectionPriority {
            return lhs.source.selectionPriority < rhs.source.selectionPriority
        }
        if lhs.distanceManhattan != rhs.distanceManhattan {
            return lhs.distanceManhattan < rhs.distanceManhattan
        }
        let lhsDirection = directionIndex(lhs.direction)
        let rhsDirection = directionIndex(rhs.direction)
        if lhsDirection != rhsDirection { return lhsDirection < rhsDirection }
        if lhs.target.x != rhs.target.x { return lhs.target.x < rhs.target.x }
        if lhs.target.y != rhs.target.y { return lhs.target.y < rhs.target.y }
        if lhs.target.z != rhs.target.z { return lhs.target.z < rhs.target.z }
        let lhsFingerprint = lhs.expectedBlockFingerprint ?? -1
        let rhsFingerprint = rhs.expectedBlockFingerprint ?? -1
        if lhsFingerprint != rhsFingerprint { return lhsFingerprint < rhsFingerprint }
        let lhsPatch = lhs.ecologyPatchID?.rawValue ?? ""
        let rhsPatch = rhs.ecologyPatchID?.rawValue ?? ""
        if lhsPatch != rhsPatch { return lhsPatch < rhsPatch }
        return (lhs.observationTick ?? -1) < (rhs.observationTick ?? -1)
    }

    public static func direction(
        observerPosition: AgentPosition,
        target: AgentPosition
    ) -> AgentCardinalDirection? {
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
    public let expectedBlockFingerprint: Int?
    public let ecologyPatchID: AgentEcologyPatchID?
    public let observationTick: Int?

    public var identity: AgentResourceIdentity {
        AgentResourceIdentity(
            source: source,
            position: target,
            resource: resource,
            expectedBlockFingerprint: expectedBlockFingerprint,
            ecologyPatchID: ecologyPatchID
        )
    }

    public init(
        resource: AgentResourceKind,
        target: AgentPosition,
        source: AgentResourceObservationSource,
        distanceManhattan: Int,
        selectedAtTick: Int,
        lastSeenAtTick: Int,
        expectedBlockFingerprint: Int? = nil,
        ecologyPatchID: AgentEcologyPatchID? = nil,
        observationTick: Int? = nil
    ) {
        self.resource = resource
        self.target = target
        self.source = source
        self.distanceManhattan = distanceManhattan
        self.selectedAtTick = selectedAtTick
        self.lastSeenAtTick = lastSeenAtTick
        self.expectedBlockFingerprint = expectedBlockFingerprint
        self.ecologyPatchID = ecologyPatchID
        self.observationTick = observationTick
    }
}

public enum AgentResourceTargeting {
    public static func select(
        current: AgentResourceTarget?,
        observations: [AgentResourceObservation],
        inventory: AgentResourceInventory,
        tick: Int,
        eligibleResources: [AgentResourceKind]? = nil
    ) -> AgentResourceTarget? {
        let eligible = eligibleResources
        if let current,
           eligible?.contains(current.resource) != false,
           inventory.canAdd(current.resource),
           let retained = observations.first(where: {
               $0.target == current.target
                   && $0.resource == current.resource
                   && $0.source == current.source
                   && $0.expectedBlockFingerprint == current.expectedBlockFingerprint
                   && $0.ecologyPatchID == current.ecologyPatchID
           }) {
            return AgentResourceTarget(
                resource: retained.resource,
                target: retained.target,
                source: retained.source,
                distanceManhattan: retained.distanceManhattan,
                selectedAtTick: current.selectedAtTick,
                lastSeenAtTick: tick,
                expectedBlockFingerprint: retained.expectedBlockFingerprint,
                ecologyPatchID: retained.ecologyPatchID,
                observationTick: retained.observationTick
            )
        }
        let eligibleObservations = observations.filter {
            eligible?.contains($0.resource) != false
        }
        guard let selected = eligibleObservations.sorted(by: { lhs, rhs in
            let lhsCarried = inventory.count(of: lhs.resource)
            let rhsCarried = inventory.count(of: rhs.resource)
            if lhsCarried != rhsCarried { return lhsCarried < rhsCarried }
            return AgentResourcePerception.sortsBefore(lhs, rhs)
        })
            .first(where: { inventory.canAdd($0.resource) }) else {
            return nil
        }
        return AgentResourceTarget(
            resource: selected.resource,
            target: selected.target,
            source: selected.source,
            distanceManhattan: selected.distanceManhattan,
            selectedAtTick: tick,
            lastSeenAtTick: tick,
            expectedBlockFingerprint: selected.expectedBlockFingerprint,
            ecologyPatchID: selected.ecologyPatchID,
            observationTick: selected.observationTick
        )
    }
}

public struct AgentResourceInventory: Codable, Equatable {
    public let capacity: Int
    public private(set) var sandboxResourceCount: Int
    public private(set) var foodRawCount: Int
    public private(set) var woodCount: Int
    public private(set) var stoneCount: Int

    public var totalCount: Int {
        sandboxResourceCount + foodRawCount + woodCount + stoneCount
    }
    public var isEmpty: Bool { totalCount == 0 }
    public var isFull: Bool { totalCount >= capacity }
    public var amounts: [AgentResourceAmount] {
        AgentResourceKind.allCases.compactMap { resource in
            let quantity = count(of: resource)
            return quantity > 0 ? AgentResourceAmount(resource: resource, quantity: quantity) : nil
        }
    }

    public init(capacity: Int = 8) {
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

    @discardableResult
    public mutating func add(_ resource: AgentResourceKind, quantity: Int = 1) -> Bool {
        guard canAdd(resource, quantity: quantity) else { return false }
        switch resource {
        case .sandboxResource:
            sandboxResourceCount += quantity
        case .foodRaw:
            foodRawCount += quantity
        case .wood:
            woodCount += quantity
        case .stone:
            stoneCount += quantity
        }
        return true
    }

    public func canRemove(_ resource: AgentResourceKind, quantity: Int = 1) -> Bool {
        quantity > 0 && count(of: resource) >= quantity
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
    public mutating func removeAll(_ amounts: [AgentResourceAmount]) -> Bool {
        let normalized = AgentResourceAmounts.normalize(amounts)
        guard normalized.allSatisfy({ canRemove($0.resource, quantity: $0.quantity) }) else {
            return false
        }
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
        if foodRawCount != 0 { try container.encode(foodRawCount, forKey: .foodRawCount) }
        if woodCount != 0 { try container.encode(woodCount, forKey: .woodCount) }
        if stoneCount != 0 { try container.encode(stoneCount, forKey: .stoneCount) }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        capacity = try container.decode(Int.self, forKey: .capacity)
        sandboxResourceCount = try container.decode(Int.self, forKey: .sandboxResourceCount)
        foodRawCount = try container.decodeIfPresent(Int.self, forKey: .foodRawCount) ?? 0
        woodCount = try container.decodeIfPresent(Int.self, forKey: .woodCount) ?? 0
        stoneCount = try container.decodeIfPresent(Int.self, forKey: .stoneCount) ?? 0
    }
}

public struct AgentInteractionIntent: Equatable {
    public let interactionId: String
    public let agentId: String
    public let tick: Int
    public let target: AgentPosition
    public let resource: AgentResourceKind
    public let quantity: Int
    public let source: AgentResourceObservationSource
    public let expectedBlockFingerprint: Int?

    public init(
        interactionId: String,
        agentId: String,
        tick: Int,
        target: AgentPosition,
        resource: AgentResourceKind,
        quantity: Int = 1,
        source: AgentResourceObservationSource = .sandboxFixture,
        expectedBlockFingerprint: Int? = nil
    ) {
        self.interactionId = interactionId
        self.agentId = agentId
        self.tick = tick
        self.target = target
        self.resource = resource
        self.quantity = quantity
        self.source = source
        self.expectedBlockFingerprint = expectedBlockFingerprint
    }
}

public enum AgentInteractionStatus: String, Codable, Equatable, Sendable {
    case succeeded
    case blocked
    case inventoryFull
}

public struct AgentInventoryDelta: Codable, Equatable {
    public let resource: AgentResourceKind
    public let quantity: Int

    public init(resource: AgentResourceKind, quantity: Int) {
        self.resource = resource
        self.quantity = quantity
    }
}

public struct AgentInteractionOutcome: Codable, Equatable {
    public let interactionId: String
    public let agentId: String
    public let tick: Int
    public let target: AgentPosition
    public let resource: AgentResourceKind
    public let status: AgentInteractionStatus
    public let inventoryDelta: AgentInventoryDelta
    public let reason: String
    public let source: AgentResourceObservationSource
    public let expectedBlockFingerprint: Int?

    public init(
        interactionId: String,
        agentId: String,
        tick: Int,
        target: AgentPosition,
        resource: AgentResourceKind,
        status: AgentInteractionStatus,
        inventoryDelta: AgentInventoryDelta,
        reason: String,
        source: AgentResourceObservationSource = .sandboxFixture,
        expectedBlockFingerprint: Int? = nil
    ) {
        self.interactionId = interactionId
        self.agentId = agentId
        self.tick = tick
        self.target = target
        self.resource = resource
        self.status = status
        self.inventoryDelta = inventoryDelta
        self.reason = reason
        self.source = source
        self.expectedBlockFingerprint = expectedBlockFingerprint
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

public struct AgentNaturalResourceMutationBoundary: Codable, Equatable {
    public let identity: AgentResourceIdentity

    public var permittedPositions: [AgentPosition] { [identity.position] }

    public var isValid: Bool {
        identity.source == .naturalWorld
            && identity.expectedBlockFingerprint != nil
            && (identity.resource == .wood || identity.resource == .stone)
    }

    public init(identity: AgentResourceIdentity) {
        self.identity = identity
    }

    public func permits(_ position: AgentPosition) -> Bool {
        isValid && position == identity.position
    }
}

public struct AgentSandboxFixtureSetMutationBoundary: Codable, Equatable {
    public static let maximumFixtureCount = 3
    public let permittedPositions: [AgentPosition]

    public var isValid: Bool {
        !permittedPositions.isEmpty
            && permittedPositions.count <= Self.maximumFixtureCount
            && Set(permittedPositions).count == permittedPositions.count
    }

    public init(targets: [AgentPosition]) {
        permittedPositions = targets.sorted {
            if $0.x != $1.x { return $0.x < $1.x }
            if $0.y != $1.y { return $0.y < $1.y }
            return $0.z < $1.z
        }
    }

    public func permits(_ position: AgentPosition) -> Bool {
        isValid && permittedPositions.contains(position)
    }
}
