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
    case pendingMaterialExit(String)
    case materialExitLimitExceeded(Int)
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
        case let .pendingMaterialExit(id):
            return "mortality material exit pending for \(id)"
        case let .materialExitLimitExceeded(count):
            return "mortality material exit asset limit exceeded: \(count)"
        case .terminalResourceOverflow: return "mortality terminal resource capacity reached"
        case let .invalidState(reason): return "invalid mortality state: \(reason)"
        }
    }
}

public struct AgentMortalityConfiguration: Codable, Equatable, Sendable {
    public let maximumDeathsPerTick: Int
    public let maximumRetainedDeathRecords: Int
    public let maximumCompactedDeathSummaries: Int
    public let maximumFinalMemoryEntries: Int
    public let maximumCancelledCommitmentIDsPerDeath: Int
    public let maximumExitFrames: Int
    public let maximumMaterialExitsPerDeath: Int
    /// Requires every terminal actor to wait for an explicit Pebble-owned
    /// carried-inventory verification, even when no CIV-26 asset refers to it.
    public let requiresTerminalPhysicalCustodyVerification: Bool

    public init(
        maximumDeathsPerTick: Int = 8,
        maximumRetainedDeathRecords: Int = 32,
        maximumCompactedDeathSummaries: Int = 512,
        maximumFinalMemoryEntries: Int = 8,
        maximumCancelledCommitmentIDsPerDeath: Int = 32,
        maximumExitFrames: Int = 32,
        maximumMaterialExitsPerDeath: Int = 16,
        requiresTerminalPhysicalCustodyVerification: Bool = false
    ) throws {
        guard (1...8).contains(maximumDeathsPerTick) else {
            throw AgentMortalityError.invalidConfiguration("deaths per tick")
        }
        guard (1...64).contains(maximumRetainedDeathRecords) else {
            throw AgentMortalityError.invalidConfiguration("death records")
        }
        guard (1...4096).contains(maximumCompactedDeathSummaries) else {
            throw AgentMortalityError.invalidConfiguration(
                "compacted death summaries"
            )
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
        guard (1...16).contains(maximumMaterialExitsPerDeath) else {
            throw AgentMortalityError.invalidConfiguration("material exits per death")
        }
        self.maximumDeathsPerTick = maximumDeathsPerTick
        self.maximumRetainedDeathRecords = maximumRetainedDeathRecords
        self.maximumCompactedDeathSummaries =
            maximumCompactedDeathSummaries
        self.maximumFinalMemoryEntries = maximumFinalMemoryEntries
        self.maximumCancelledCommitmentIDsPerDeath = maximumCancelledCommitmentIDsPerDeath
        self.maximumExitFrames = maximumExitFrames
        self.maximumMaterialExitsPerDeath = maximumMaterialExitsPerDeath
        self.requiresTerminalPhysicalCustodyVerification =
            requiresTerminalPhysicalCustodyVerification
    }

    public static let live = try! AgentMortalityConfiguration()
    public static let embodiedLive = try! AgentMortalityConfiguration(
        requiresTerminalPhysicalCustodyVerification: true
    )

    private enum CodingKeys: String, CodingKey {
        case maximumDeathsPerTick
        case maximumRetainedDeathRecords
        case maximumCompactedDeathSummaries
        case maximumFinalMemoryEntries
        case maximumCancelledCommitmentIDsPerDeath
        case maximumExitFrames
        case maximumMaterialExitsPerDeath
        case requiresTerminalPhysicalCustodyVerification
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            maximumDeathsPerTick: values.decode(
                Int.self, forKey: .maximumDeathsPerTick
            ),
            maximumRetainedDeathRecords: values.decode(
                Int.self, forKey: .maximumRetainedDeathRecords
            ),
            maximumCompactedDeathSummaries: try values.decodeIfPresent(
                Int.self, forKey: .maximumCompactedDeathSummaries
            ) ?? 512,
            maximumFinalMemoryEntries: values.decode(
                Int.self, forKey: .maximumFinalMemoryEntries
            ),
            maximumCancelledCommitmentIDsPerDeath: values.decode(
                Int.self, forKey: .maximumCancelledCommitmentIDsPerDeath
            ),
            maximumExitFrames: values.decode(
                Int.self, forKey: .maximumExitFrames
            ),
            maximumMaterialExitsPerDeath: values.decode(
                Int.self, forKey: .maximumMaterialExitsPerDeath
            ),
            requiresTerminalPhysicalCustodyVerification:
                try values.decodeIfPresent(
                    Bool.self,
                    forKey: .requiresTerminalPhysicalCustodyVerification
                ) ?? false
        )
    }
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
    public let terminalPhysiologyEventID: AgentCausalEventID?
    public let pendingMaterialExitEventID: AgentCausalEventID?
    public let materialExitEventIDs: [AgentCausalEventID]
    public let physicalCustodyResolution: AgentMortalityPhysicalCustodyResolution?
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

public enum AgentMortalityPhysicalCustodyResolutionKind: String, Codable, Sendable {
    case verifiedEmpty
    case transferred
}

/// Pebble-owned evidence that the terminal actor's complete real carried
/// inventory was either empty or moved to one verified physical endpoint.
/// It conveys no ownership, claim, permission, or inheritance.
public struct AgentMortalityPhysicalCustodyResolution: Codable, Equatable, Sendable {
    public let kind: AgentMortalityPhysicalCustodyResolutionKind
    public let physicalReceiptID: String
    public let destinationHolderID: String?
    public let stackCount: Int
    public let itemCount: Int
    /// Exact read-only stack evidence captured by Pebble at the terminal
    /// custody boundary. `nil` is reserved for historical pre-CIV-33 data.
    public let physicalAssets: [AgentMaterialStackSnapshot]?
    public let verifiedAtTick: Int
    public let eventID: AgentCausalEventID
}

public struct AgentMortalityPhysicalCustodyOutcome: Codable, Equatable, Sendable {
    public let operationID: String
    public let terminalAgentID: AgentID
    public let kind: AgentMortalityPhysicalCustodyResolutionKind
    public let physicalReceiptID: String
    public let destinationHolderID: String?
    public let stackCount: Int
    public let itemCount: Int
    /// Exact bounded carried-stack evidence. It conveys physical identity and
    /// quantity only; it never creates ownership, a claim, or an inventory.
    public let physicalAssets: [AgentMaterialStackSnapshot]?
    public let verifiedAtTick: Int

    public init(
        operationID: String,
        terminalAgentID: AgentID,
        kind: AgentMortalityPhysicalCustodyResolutionKind,
        physicalReceiptID: String,
        destinationHolderID: String?,
        stackCount: Int,
        itemCount: Int,
        physicalAssets: [AgentMaterialStackSnapshot]? = nil,
        verifiedAtTick: Int
    ) {
        self.operationID = operationID
        self.terminalAgentID = terminalAgentID
        self.kind = kind
        self.physicalReceiptID = physicalReceiptID
        self.destinationHolderID = destinationHolderID
        self.stackCount = stackCount
        self.itemCount = itemCount
        self.physicalAssets = physicalAssets
        self.verifiedAtTick = verifiedAtTick
    }
}

/// A terminal civilization transition that cannot be published as a death
/// until Pebble has verified the entire physical carried inventory. CIV-26
/// asset IDs are only the social records that also require holder updates.
public struct AgentPendingMortalityTransition: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let healthBeforeLethalDamage: Int
    public let cause: AgentMortalityCause
    public let detectedAtTick: Int
    public let terminalPhysiologyEventID: AgentCausalEventID?
    public let pendingEventID: AgentCausalEventID
    public let requiredMaterialAssetIDs: [AgentMaterialAssetID]
    public internal(set) var resolvedMaterialAssetIDs: [AgentMaterialAssetID]
    public internal(set) var materialExitEventIDs: [AgentCausalEventID]
    public internal(set) var physicalCustodyResolution:
        AgentMortalityPhysicalCustodyResolution?

    public var unresolvedMaterialAssetIDs: [AgentMaterialAssetID] {
        let resolved = Set(resolvedMaterialAssetIDs)
        return requiredMaterialAssetIDs.filter { !resolved.contains($0) }
    }
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

/// Minimal, non-operational evidence retained when a full death record is
/// compacted. It cannot reopen mortality or carry estate/material state; it
/// exists only to revalidate historical facts at later causal boundaries.
public struct AgentCompactedDeathSummary: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public let version: Int
    public let deathOrdinal: Int
    public let agentID: AgentID
    public let deathID: AgentDeathID
    public let cause: AgentMortalityCause
    public let deathTick: Int
    public let demographicAgeTicks: Int?
    public let lifeStageAtDeath: AgentLifeStage?
    /// The first durable causal event at which this person had entered the
    /// terminal mortality path. Historical schemas may omit it; in that case
    /// `deathEventID` remains the conservative legacy boundary.
    public let terminalEligibilityEventID: AgentCausalEventID?
    public let deathEventID: AgentCausalEventID
    public let finalStateDigest: String
    public let evidenceDigest: String

    public init(
        deathOrdinal: Int,
        agentID: AgentID,
        deathID: AgentDeathID,
        cause: AgentMortalityCause,
        deathTick: Int,
        demographicAgeTicks: Int?,
        lifeStageAtDeath: AgentLifeStage?,
        terminalEligibilityEventID: AgentCausalEventID?,
        deathEventID: AgentCausalEventID,
        finalStateDigest: String
    ) {
        version = Self.currentVersion
        self.deathOrdinal = deathOrdinal
        self.agentID = agentID
        self.deathID = deathID
        self.cause = cause
        self.deathTick = deathTick
        self.demographicAgeTicks = demographicAgeTicks
        self.lifeStageAtDeath = lifeStageAtDeath
        self.terminalEligibilityEventID = terminalEligibilityEventID
        self.deathEventID = deathEventID
        self.finalStateDigest = finalStateDigest
        evidenceDigest = Self.digest(
            version: Self.currentVersion,
            deathOrdinal: deathOrdinal,
            agentID: agentID,
            deathID: deathID,
            cause: cause,
            deathTick: deathTick,
            demographicAgeTicks: demographicAgeTicks,
            lifeStageAtDeath: lifeStageAtDeath,
            terminalEligibilityEventID: terminalEligibilityEventID,
            deathEventID: deathEventID,
            finalStateDigest: finalStateDigest
        )
    }

    public static func digest(
        version: Int,
        deathOrdinal: Int,
        agentID: AgentID,
        deathID: AgentDeathID,
        cause: AgentMortalityCause,
        deathTick: Int,
        demographicAgeTicks: Int?,
        lifeStageAtDeath: AgentLifeStage?,
        terminalEligibilityEventID: AgentCausalEventID?,
        deathEventID: AgentCausalEventID,
        finalStateDigest: String
    ) -> String {
        var components = [
            "compacted-death-v\(version)",
            String(deathOrdinal),
            agentID.rawValue,
            deathID.rawValue,
            cause.rawValue,
            String(deathTick),
            demographicAgeTicks.map(String.init) ?? "none",
            lifeStageAtDeath?.rawValue ?? "none",
        ]
        if let terminalEligibilityEventID {
            components.append(terminalEligibilityEventID.rawValue)
        }
        components.append(deathEventID.rawValue)
        components.append(finalStateDigest)
        return AgentMortalityDigest.make(components.joined(separator: "|"))
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
    public internal(set) var pendingTransitions: [AgentPendingMortalityTransition]
    public internal(set) var evictionCounts: AgentMortalityEvictionCounts
    /// `nil` is accepted only while decoding historical checkpoint schemas.
    /// Schema 28 requires version 1 and exact evidence for every compaction.
    public internal(set) var historicalEvidenceVersion: Int?
    public internal(set) var compactedDeathSummaries:
        [AgentCompactedDeathSummary]?
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
    public let pendingTransitions: [AgentPendingMortalityTransition]
    public let evictionCounts: AgentMortalityEvictionCounts
    public let historicalEvidenceVersion: Int?
    public let compactedDeathSummaries: [AgentCompactedDeathSummary]?
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
    public let pendingDeathCount: Int
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
