public enum AgentMortalityCause: String, Codable, CaseIterable, Sendable {
    case starvation
    case deprivation
    case exhaustion
    case compoundedHomeostaticFailure
}

public struct AgentDeathID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.utf8.count),
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0)
                      || (48...57).contains($0) || $0 == 45 || $0 == 95
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentDeathID, rhs: AgentDeathID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentMortalityError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case survivalRequired
    case populationRequired
    case invalidSettlement
    case alreadyEnabled
    case disabled
    case unsafeDisable
    case nonLivingAgent(String)
    case unknownAgent(String)
    case invalidLethalTransition(String)
    case duplicateDeath(String)
    case deathsPerTickExceeded(Int)
    case terminalResourceOverflow
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason):
            return "invalid mortality configuration: \(reason)"
        case .causalLedgerRequired: return "mortality requires the causal ledger"
        case .survivalRequired: return "mortality requires survival"
        case .populationRequired: return "mortality requires the population registry"
        case .invalidSettlement: return "mortality requires a valid settlement"
        case .alreadyEnabled: return "mortality already enabled"
        case .disabled: return "mortality disabled"
        case .unsafeDisable: return "mortality disable refused after durable mortality state"
        case let .nonLivingAgent(id): return "mortality activation refused for non-living agent \(id)"
        case let .unknownAgent(id): return "unknown mortality agent \(id)"
        case let .invalidLethalTransition(id): return "invalid lethal transition for \(id)"
        case let .duplicateDeath(id): return "duplicate mortality transition for \(id)"
        case let .deathsPerTickExceeded(count): return "mortality deaths per tick exceeded: \(count)"
        case .terminalResourceOverflow: return "mortality terminal resource capacity reached"
        case let .invalidState(reason): return "invalid mortality state: \(reason)"
        }
    }
}

public struct AgentMortalityConfiguration: Codable, Equatable, Sendable {
    public let maximumDeathsPerTick: Int
    public let maximumRetainedDeathRecords: Int
    public let maximumFinalMemoryEntries: Int
    public let maximumCancelledCommitmentIDsPerDeath: Int
    public let maximumExitFrames: Int

    public init(
        maximumDeathsPerTick: Int = 8,
        maximumRetainedDeathRecords: Int = 32,
        maximumFinalMemoryEntries: Int = 8,
        maximumCancelledCommitmentIDsPerDeath: Int = 32,
        maximumExitFrames: Int = 32
    ) throws {
        guard (1...8).contains(maximumDeathsPerTick) else {
            throw AgentMortalityError.invalidConfiguration("deaths per tick")
        }
        guard (1...64).contains(maximumRetainedDeathRecords) else {
            throw AgentMortalityError.invalidConfiguration("death records")
        }
        guard (0...16).contains(maximumFinalMemoryEntries) else {
            throw AgentMortalityError.invalidConfiguration("final memory entries")
        }
        guard (0...64).contains(maximumCancelledCommitmentIDsPerDeath) else {
            throw AgentMortalityError.invalidConfiguration("commitment IDs")
        }
        guard (1...64).contains(maximumExitFrames) else {
            throw AgentMortalityError.invalidConfiguration("exit frames")
        }
        self.maximumDeathsPerTick = maximumDeathsPerTick
        self.maximumRetainedDeathRecords = maximumRetainedDeathRecords
        self.maximumFinalMemoryEntries = maximumFinalMemoryEntries
        self.maximumCancelledCommitmentIDsPerDeath = maximumCancelledCommitmentIDsPerDeath
        self.maximumExitFrames = maximumExitFrames
    }

    public static let live = try! AgentMortalityConfiguration()
}

public struct AgentMortalityCleanupCounts: Codable, Equatable, Sendable {
    public let reservations: Int
    public let socialVerifications: Int
    public let physicalSignals: Int
    public let physicalPresentations: Int
    public let cooperationTasks: Int
    public let cooperationOffers: Int
    public let constructionProjects: Int
    public let activePointers: Int

    public init(
        reservations: Int = 0,
        socialVerifications: Int = 0,
        physicalSignals: Int = 0,
        physicalPresentations: Int = 0,
        cooperationTasks: Int = 0,
        cooperationOffers: Int = 0,
        constructionProjects: Int = 0,
        activePointers: Int = 0
    ) {
        self.reservations = reservations
        self.socialVerifications = socialVerifications
        self.physicalSignals = physicalSignals
        self.physicalPresentations = physicalPresentations
        self.cooperationTasks = cooperationTasks
        self.cooperationOffers = cooperationOffers
        self.constructionProjects = constructionProjects
        self.activePointers = activePointers
    }

    public var total: Int {
        reservations + socialVerifications + physicalSignals + physicalPresentations
            + cooperationTasks + cooperationOffers + constructionProjects + activePointers
    }
}

public struct AgentTerminalActivitySnapshot: Codable, Equatable, Sendable {
    public let observationCount: Int
    public let nearbyObservationCount: Int
    public let goalSelectionCount: Int
    public let goalChangeCount: Int
    public let actionCount: Int
    public let actionEffectCount: Int
    public let movementCount: Int
    public let totalManhattanDistanceMoved: Int
    public let returnHomeMoveCount: Int
    public let foodConsumedCount: Int
    public let ticksAlive: Int
    public let lastGoal: AgentGoalKind
    public let lastAction: AgentAction?
    public let lastActionEffect: AgentActionEffect?
    public let lastMovementOutcomeStatus: AgentMovementStatus?
    public let lastInteractionOutcomeStatus: AgentInteractionStatus?
    public let lastDeliveryOutcomeStatus: AgentDeliveryStatus?
    public let lastConsumptionOutcomeStatus: AgentConsumptionStatus?

    init(state: AgentSessionAgentState) {
        observationCount = state.observationCount
        nearbyObservationCount = state.nearbyObservationCount
        goalSelectionCount = state.goalSelectionCount
        goalChangeCount = state.goalChangeCount
        actionCount = state.actionCount
        actionEffectCount = state.actionEffectCount
        movementCount = state.movementCount
        totalManhattanDistanceMoved = state.totalManhattanDistanceMoved
        returnHomeMoveCount = state.returnHomeMoveCount
        foodConsumedCount = state.survivalProgress?.foodConsumedCount ?? 0
        ticksAlive = state.ticksAlive
        lastGoal = state.currentGoal.kind
        lastAction = state.lastAction
        lastActionEffect = state.lastActionEffect
        lastMovementOutcomeStatus = state.lastMovementOutcome?.status
        lastInteractionOutcomeStatus = state.lastInteractionOutcome?.status
        lastDeliveryOutcomeStatus = state.lastDeliveryOutcome?.status
        lastConsumptionOutcomeStatus = state.survivalProgress?.lastConsumptionOutcome?.status
    }

    var canonicalText: String {
        let actionText = lastAction.map { action in
            let dx = action.dx.map(String.init) ?? "nil"
            let dy = action.dy.map(String.init) ?? "nil"
            let dz = action.dz.map(String.init) ?? "nil"
            return "\(action.name):\(action.tick):\(dx):\(dy):\(dz)"
        } ?? "nil"
        let effectText = lastActionEffect.map { effect in
            "\(effect.action):\(effect.effect):\(effect.tick)"
        } ?? "nil"
        return [
            String(observationCount),
            String(nearbyObservationCount),
            String(goalSelectionCount),
            String(goalChangeCount),
            String(actionCount),
            String(actionEffectCount),
            String(movementCount),
            String(totalManhattanDistanceMoved),
            String(returnHomeMoveCount),
            String(foodConsumedCount),
            String(ticksAlive),
            lastGoal.rawValue,
            actionText,
            effectText,
            lastMovementOutcomeStatus?.rawValue ?? "nil",
            lastInteractionOutcomeStatus?.rawValue ?? "nil",
            lastDeliveryOutcomeStatus?.rawValue ?? "nil",
            lastConsumptionOutcomeStatus?.rawValue ?? "nil",
        ].joined(separator: ",")
    }
}

public struct AgentMortalityRecord: Codable, Equatable, Sendable {
    public let deathID: AgentDeathID
    public let agentID: AgentID
    public let populationOrdinal: AgentPopulationOrdinal
    public let founder: Bool
    public let settlementID: AgentSettlementID
    public let membershipStatus: AgentPopulationMembershipStatus
    public let migrationID: AgentMigrationID?
    public let cause: AgentMortalityCause
    public let deathTick: Int
    public let finalPosition: AgentPosition
    public let finalHome: AgentPosition
    public let healthBeforeLethalDamage: Int
    public let finalHealth: Int
    public let finalHunger: Double
    public let finalFatigue: Double
    public let finalFear: Int
    public let starvationDamageTotal: Int
    public let ticksAlive: Int
    public let lastGoal: AgentGoalKind
    public let lastAction: AgentAction?
    public let terminalActivity: AgentTerminalActivitySnapshot
    public let carriedInventory: [AgentResourceAmount]
    public let finalMemory: [AgentMemoryEntry]
    public let finalStateDigest: String
    public let registrationEventID: AgentCausalEventID
    public let arrivalEventID: AgentCausalEventID?
    public let lethalDamageEventID: AgentCausalEventID
    public let deathEventID: AgentCausalEventID
    public let populationExitEventID: AgentCausalEventID
    public let resourcesRetiredEventID: AgentCausalEventID
    public let commitmentsResolvedEventID: AgentCausalEventID
    public let cancelledCommitmentIDs: [String]
    public let cleanupCounts: AgentMortalityCleanupCounts
    public let finalVitalStatus: AgentVitalStatus?
    public let finalHomeostasis: AgentHomeostasisProfile?
    public let demographicAgeTicks: Int?
    public let lifeStage: AgentLifeStage?
}

public struct AgentPopulationExitFrame: Codable, Equatable, Sendable {
    public let deathID: AgentDeathID
    public let agentID: AgentID
    public let tick: Int
    public let populationBefore: Int
    public let populationAfter: Int
    public let residentCountAfter: Int
    public let migrantCountAfter: Int
    public let carriedRetired: Int
    public let populationExitEventID: AgentCausalEventID
}

public struct AgentMortalityEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var deathRecords: Int
    public internal(set) var exitFrames: Int

    public init(deathRecords: Int = 0, exitFrames: Int = 0) {
        self.deathRecords = deathRecords
        self.exitFrames = exitFrames
    }
}

public struct AgentMortalityState: Codable, Equatable {
    public let configuration: AgentMortalityConfiguration
    public internal(set) var records: [AgentMortalityRecord]
    public internal(set) var totalDeathCount: Int
    public internal(set) var processedDeathIDs: [AgentDeathID]
    public internal(set) var unrecoveredAtDeath: AgentCampStock
    public internal(set) var terminalStarvationDamageTotal: Int
    public internal(set) var exitFrames: [AgentPopulationExitFrame]
    public internal(set) var evictionCounts: AgentMortalityEvictionCounts
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastMortalityEventID: AgentCausalEventID
}

public struct AgentMortalitySnapshot: Codable, Equatable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentMortalityConfiguration?
    public let records: [AgentMortalityRecord]
    public let totalDeathCount: Int
    public let processedDeathIDs: [AgentDeathID]
    public let unrecoveredAtDeath: [AgentResourceAmount]
    public let terminalStarvationDamageTotal: Int
    public let exitFrames: [AgentPopulationExitFrame]
    public let evictionCounts: AgentMortalityEvictionCounts
    public let rollingDigest: String
    public let lastMortalityEventID: AgentCausalEventID?
    public let digest: String
}

public struct AgentMortalitySummary: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let activeAgentCount: Int
    public let totalDeathCount: Int
    public let retainedDeathCount: Int
    public let evictedDeathCount: Int
    public let latestDeathID: AgentDeathID?
    public let latestAgentID: AgentID?
    public let latestCause: AgentMortalityCause?
    public let latestDeathTick: Int?
    public let unrecoveredTotal: Int
    public let mortalityEventCount: Int
    public let digest: String
}

public enum AgentMortalityDigest {
    public static func make(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        let digits = String(value, radix: 16, uppercase: false)
        return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
    }
}
