public enum AgentCardinalDirection: String, Codable, Equatable, CaseIterable {
    case north
    case east
    case south
    case west

    public var dx: Int {
        switch self {
        case .north, .south: return 0
        case .east: return 1
        case .west: return -1
        }
    }

    public var dz: Int {
        switch self {
        case .east, .west: return 0
        case .north: return -1
        case .south: return 1
        }
    }
}

public struct AgentWorldColumnObservation: Codable, Equatable {
    public let position: AgentPosition
    public let chunkReady: Bool
    public let surfaceY: Int?
    public let height: Int?
    public let blockBelow: Int?
    public let blockAtFeet: Int?
    public let blockAtHead: Int?
    public let groundPresent: Bool
    public let feetClear: Bool
    public let headClear: Bool

    public init(
        position: AgentPosition,
        chunkReady: Bool,
        surfaceY: Int?,
        height: Int?,
        blockBelow: Int?,
        blockAtFeet: Int?,
        blockAtHead: Int?,
        groundPresent: Bool,
        feetClear: Bool,
        headClear: Bool
    ) {
        self.position = position
        self.chunkReady = chunkReady
        self.surfaceY = surfaceY
        self.height = height
        self.blockBelow = blockBelow
        self.blockAtFeet = blockAtFeet
        self.blockAtHead = blockAtHead
        self.groundPresent = groundPresent
        self.feetClear = feetClear
        self.headClear = headClear
    }
}

public struct AgentWorldNeighborObservation: Codable, Equatable {
    public let direction: AgentCardinalDirection
    public let column: AgentWorldColumnObservation
    public let stepDelta: Int?
    public let traversable: Bool
    public let dangerousDrop: Bool

    public init(
        direction: AgentCardinalDirection,
        column: AgentWorldColumnObservation,
        stepDelta: Int?,
        traversable: Bool,
        dangerousDrop: Bool
    ) {
        self.direction = direction
        self.column = column
        self.stepDelta = stepDelta
        self.traversable = traversable
        self.dangerousDrop = dangerousDrop
    }
}

public enum AgentWorldObservationError: Error, Equatable {
    case invalidNeighborCount(Int)
    case duplicateDirection(AgentCardinalDirection)
    case missingDirection(AgentCardinalDirection)
    case invalidCenterPosition
    case invalidNeighborPosition(AgentCardinalDirection)
}

public struct AgentWorldObservation: Codable, Equatable {
    public let worldTick: Int
    public let position: AgentPosition
    public let center: AgentWorldColumnObservation
    public let neighbors: [AgentWorldNeighborObservation]
    public let biomeId: Int?
    public let biomeName: String?
    public let combinedLight: Int?
    public let skyLight: Int?
    public let blockLight: Int?
    public let dayTime: Int
    public let raining: Bool
    public let thundering: Bool
    public let traversableNeighborCount: Int
    public let blockedNeighborCount: Int
    public let dangerousDropCount: Int

    public init(
        worldTick: Int,
        position: AgentPosition,
        center: AgentWorldColumnObservation,
        neighbors: [AgentWorldNeighborObservation],
        biomeId: Int?,
        biomeName: String?,
        combinedLight: Int?,
        skyLight: Int?,
        blockLight: Int?,
        dayTime: Int,
        raining: Bool,
        thundering: Bool
    ) throws {
        guard center.position == position else {
            throw AgentWorldObservationError.invalidCenterPosition
        }
        guard neighbors.count == AgentCardinalDirection.allCases.count else {
            throw AgentWorldObservationError.invalidNeighborCount(neighbors.count)
        }
        var byDirection: [String: AgentWorldNeighborObservation] = [:]
        for neighbor in neighbors {
            guard byDirection[neighbor.direction.rawValue] == nil else {
                throw AgentWorldObservationError.duplicateDirection(neighbor.direction)
            }
            let expected = AgentPosition(
                x: position.x + neighbor.direction.dx,
                y: position.y,
                z: position.z + neighbor.direction.dz
            )
            guard neighbor.column.position == expected else {
                throw AgentWorldObservationError.invalidNeighborPosition(neighbor.direction)
            }
            byDirection[neighbor.direction.rawValue] = neighbor
        }
        for direction in AgentCardinalDirection.allCases where byDirection[direction.rawValue] == nil {
            throw AgentWorldObservationError.missingDirection(direction)
        }

        let ordered = AgentCardinalDirection.allCases.compactMap { byDirection[$0.rawValue] }
        self.worldTick = worldTick
        self.position = position
        self.center = center
        self.neighbors = ordered
        self.biomeId = biomeId
        self.biomeName = biomeName
        self.combinedLight = combinedLight
        self.skyLight = skyLight
        self.blockLight = blockLight
        self.dayTime = dayTime
        self.raining = raining
        self.thundering = thundering
        traversableNeighborCount = ordered.filter(\.traversable).count
        blockedNeighborCount = ordered.filter { !$0.traversable }.count
        dangerousDropCount = ordered.filter(\.dangerousDrop).count
    }
}

public struct AgentWorldPerceptionEffect: Encodable, Equatable {
    public let safetyBefore: Double
    public let safetyAfter: Double
    public let curiosityBefore: Double
    public let curiosityAfter: Double
    public let fearBefore: Int
    public let fearAfter: Int
    public let reason: String
    public let memorySummary: String
    public let memoryImportance: Double

    public init(
        safetyBefore: Double,
        safetyAfter: Double,
        curiosityBefore: Double,
        curiosityAfter: Double,
        fearBefore: Int,
        fearAfter: Int,
        reason: String,
        memorySummary: String,
        memoryImportance: Double
    ) {
        self.safetyBefore = safetyBefore
        self.safetyAfter = safetyAfter
        self.curiosityBefore = curiosityBefore
        self.curiosityAfter = curiosityAfter
        self.fearBefore = fearBefore
        self.fearAfter = fearAfter
        self.reason = reason
        self.memorySummary = memorySummary
        self.memoryImportance = memoryImportance
    }
}

public enum AgentWorldPerceptionInterpreter {
    public static func interpret(
        agentId: String,
        tick: Int,
        observation: AgentWorldObservation,
        needs: AgentNeeds,
        fear: Int
    ) -> AgentWorldPerceptionEffect {
        let safety: Double
        let fearDelta: Int
        let curiosityDelta: Double
        let reason: String

        if !observation.center.chunkReady {
            safety = 0.20
            fearDelta = 8
            curiosityDelta = 0
            reason = "center chunk unavailable"
        } else if !observation.center.groundPresent {
            safety = 0.10
            fearDelta = 12
            curiosityDelta = 0.01
            reason = "no ground below"
        } else if !observation.center.feetClear || !observation.center.headClear {
            safety = 0.25
            fearDelta = 8
            curiosityDelta = 0
            reason = "body space blocked"
        } else if observation.dangerousDropCount >= 2 {
            safety = 0.40
            fearDelta = 5
            curiosityDelta = 0.02
            reason = "multiple nearby drops"
        } else if observation.traversableNeighborCount == 0 {
            safety = 0.35
            fearDelta = 6
            curiosityDelta = 0.01
            reason = "no traversable neighbor"
        } else if observation.dangerousDropCount == 1 {
            safety = 0.65
            fearDelta = 2
            curiosityDelta = 0.02
            reason = "nearby drop"
        } else if let light = observation.combinedLight, light <= 3 {
            safety = 0.45
            fearDelta = 4
            curiosityDelta = 0.01
            reason = "very low light"
        } else {
            safety = 1
            fearDelta = -1
            let varied = observation.neighbors.contains {
                $0.stepDelta != 0 || !$0.traversable || $0.dangerousDrop
            }
            curiosityDelta = varied ? 0.02 : 0.005
            reason = "local terrain stable"
        }

        let safetyAfter = min(1, max(0, safety))
        let fearAfter = min(100, max(0, fear + fearDelta))
        let curiosityAfter = min(1, max(0, needs.curiosity + curiosityDelta))
        let light = observation.combinedLight.map(String.init) ?? "unknown"
        let summary = "\(agentId) observed world: \(reason); traversable=\(observation.traversableNeighborCount)/4 blocked=\(observation.blockedNeighborCount) drops=\(observation.dangerousDropCount) light=\(light)"
        let importance = safetyAfter < 0.50 ? 0.50 : safetyAfter < 1 ? 0.30 : 0.20

        return AgentWorldPerceptionEffect(
            safetyBefore: needs.safety,
            safetyAfter: safetyAfter,
            curiosityBefore: needs.curiosity,
            curiosityAfter: curiosityAfter,
            fearBefore: fear,
            fearAfter: fearAfter,
            reason: reason,
            memorySummary: summary,
            memoryImportance: importance
        )
    }
}
