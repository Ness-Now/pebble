import CryptoKit
import Foundation

public enum AgentCheckpointSchema {
    public static let currentVersion = 1
    public static let populationVersion = 2
    public static let settlementMetricsVersion = 3

    public static func supports(_ version: Int) -> Bool {
        version == currentVersion || version == populationVersion
            || version == settlementMetricsVersion
    }
}

public enum AgentCheckpointLimits {
    public static let maximumCheckpointsPerWorld = 8
    public static let maximumCheckpointBytes = 16 * 1024 * 1024
    public static let maximumReplayRecords = 4096
    public static let maximumReplayBytes = 64 * 1024 * 1024
    public static let maximumBoundWorldCells = 256
    public static let maximumProcessedOperationIDs = 4096
}

public struct AgentCheckpointID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard !rawValue.isEmpty, rawValue.count <= 160,
              rawValue.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0)) }) else {
            return nil
        }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentCheckpointID, rhs: AgentCheckpointID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentCheckpointDigest: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue.count == 64,
              rawValue.allSatisfy({ $0.isNumber || ("a"..."f").contains(String($0)) }) else {
            return nil
        }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentCheckpointDigest, rhs: AgentCheckpointDigest) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static func sha256(_ data: Data) -> AgentCheckpointDigest {
        let value = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return AgentCheckpointDigest(rawValue: value)!
    }
}

public struct AgentCheckpointName: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...48).contains(rawValue.count),
              rawValue.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-") }) else {
            return nil
        }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentCheckpointName, rhs: AgentCheckpointName) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentCheckpointStringIntEntry: Codable, Equatable, Sendable {
    public let key: String
    public let value: Int

    public init(key: String, value: Int) {
        self.key = key
        self.value = value
    }
}

public struct AgentCheckpointSocialVerificationEntry: Codable, Equatable {
    public let agentID: String
    public let beliefID: AgentSocialBeliefID

    public init(agentID: String, beliefID: AgentSocialBeliefID) {
        self.agentID = agentID
        self.beliefID = beliefID
    }
}

public struct AgentCheckpointFailedTargetEntry: Codable, Equatable, Sendable {
    public let agentID: String
    public let targetKeys: [String]

    public init(agentID: String, targetKeys: [String]) {
        self.agentID = agentID
        self.targetKeys = targetKeys
    }
}

public struct AgentCheckpointCausalPointer: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let eventID: AgentCausalEventID

    public init(agentID: AgentID, eventID: AgentCausalEventID) {
        self.agentID = agentID
        self.eventID = eventID
    }
}

public struct AgentCausalLedgerDurableState: Codable, Equatable, Sendable {
    public let policy: AgentCausalLedgerPolicy
    public let events: [AgentCausalEvent]
    public let latestSequence: UInt64
    public let droppedEventCount: UInt64
    public let rollingDigest: String

    public init(
        policy: AgentCausalLedgerPolicy,
        events: [AgentCausalEvent],
        latestSequence: UInt64,
        droppedEventCount: UInt64,
        rollingDigest: String
    ) {
        self.policy = policy
        self.events = events
        self.latestSequence = latestSequence
        self.droppedEventCount = droppedEventCount
        self.rollingDigest = rollingDigest
    }
}

public struct AgentSessionDurableState: Codable {
    public let schemaVersion: Int
    public let configuration: AgentSessionConfiguration
    public let clock: AgentSimulationClock
    public let agents: [AgentSessionAgentState]
    public let processedInteractionIDs: [String]
    public let creditedResourceKeys: [String]
    public let reservations: [AgentResourceReservation]
    public let failedNaturalResourceTargets: [AgentCheckpointFailedTargetEntry]
    public let economyEnabled: Bool
    public let naturalResourcesEnabled: Bool
    public let campStock: AgentCampStock
    public let harvestedResourceTotals: AgentCampStock
    public let processedDeliveryIDs: [String]
    public let survivalEnabled: Bool
    public let consumedResourceTotals: AgentCampStock
    public let processedConsumptionIDs: [String]
    public let buildAutoEnabled: Bool
    public let constructionProject: AgentConstructionProject?
    public let processedConstructionFundingIDs: [String]
    public let processedConstructionPlacementIDs: [String]
    public let processedConstructionFailureIDs: [String]
    public let lastConstructionPlacementTick: Int?
    public let causalLedger: AgentCausalLedgerDurableState
    public let lastPerceptionEvents: [AgentCheckpointCausalPointer]
    public let lastDecisionEvents: [AgentCheckpointCausalPointer]
    public let lastOutcomeEvents: [AgentCheckpointCausalPointer]
    public let lastConstructionEventID: AgentCausalEventID?
    public let socialEnabled: Bool
    public let socialFacts: [AgentSocialFact]
    public let socialMessages: [AgentSocialMessage]
    public let socialBeliefs: [AgentSocialBelief]
    public let socialTrustRelations: [AgentTrustRelation]
    public let activeSocialVerifications: [AgentCheckpointSocialVerificationEntry]
    public let lastSocialShareTicks: [AgentCheckpointStringIntEntry]
    public let socialEvictionCounts: AgentSocialEvictionCounts
    public let physicalEnabled: Bool
    public let physicalSignals: [AgentPhysicalSignal]
    public let physicalPerceptions: [AgentPhysicalPerception]
    public let physicalPresentationRequests: [AgentPhysicalPresentationRequest]
    public let physicalEvictionCounts: AgentPhysicalEvictionCounts
    public let cooperationEnabled: Bool
    public let sharedTasks: [AgentSharedTask]
    public let sharedTaskOffers: [AgentSharedTaskOffer]
    public let cooperationRelations: [AgentCooperationRelation]
    public let cooperationEvictionCounts: AgentCooperationEvictionCounts
    public let lastCooperationOfferTicks: [AgentCheckpointStringIntEntry]
    public let populationRegistry: AgentPopulationRegistry?
    public let settlementMetricsState: AgentSettlementMetricsState?

    init(session: AgentSimulationSession) {
        if session.settlementMetricsState != nil {
            schemaVersion = AgentCheckpointSchema.settlementMetricsVersion
        } else if session.populationRegistry != nil {
            schemaVersion = AgentCheckpointSchema.populationVersion
        } else {
            schemaVersion = AgentCheckpointSchema.currentVersion
        }
        configuration = session.configuration
        clock = session.clock
        agents = session.statesById.values.sorted { $0.agentID < $1.agentID }
        processedInteractionIDs = session.processedInteractionIds.sorted()
        creditedResourceKeys = session.creditedResourceKeys.sorted()
        reservations = Array(session.reservationsByTarget.values).sorted(by: session.reservationSort)
        failedNaturalResourceTargets = session.failedNaturalResourceTargetKeysByAgentId.keys.sorted().map {
            AgentCheckpointFailedTargetEntry(
                agentID: $0,
                targetKeys: session.failedNaturalResourceTargetKeysByAgentId[$0] ?? []
            )
        }
        economyEnabled = session.economyEnabled
        naturalResourcesEnabled = session.naturalResourcesEnabled
        campStock = session.campStock
        harvestedResourceTotals = session.harvestedResourceTotals
        processedDeliveryIDs = session.processedDeliveryIds.sorted()
        survivalEnabled = session.survivalEnabled
        consumedResourceTotals = session.consumedResourceTotals
        processedConsumptionIDs = session.processedConsumptionIds.sorted()
        buildAutoEnabled = session.buildAutoEnabled
        constructionProject = session.constructionProject
        processedConstructionFundingIDs = session.processedConstructionFundingIds.sorted()
        processedConstructionPlacementIDs = session.processedConstructionPlacementIds.sorted()
        processedConstructionFailureIDs = session.processedConstructionFailureIds.sorted()
        lastConstructionPlacementTick = session.lastConstructionPlacementTick
        causalLedger = AgentCausalLedgerDurableState(
            policy: session.causalLedger.policy,
            events: session.causalLedger.events,
            latestSequence: session.causalLedger.latestSequence,
            droppedEventCount: session.causalLedger.droppedEventCount,
            rollingDigest: session.causalLedger.rollingDigest
        )
        func pointers(_ values: [AgentID: AgentCausalEventID]) -> [AgentCheckpointCausalPointer] {
            values.keys.sorted().compactMap { id in
                values[id].map { AgentCheckpointCausalPointer(agentID: id, eventID: $0) }
            }
        }
        lastPerceptionEvents = pointers(session.lastPerceptionEventByAgentID)
        lastDecisionEvents = pointers(session.lastDecisionEventByAgentID)
        lastOutcomeEvents = pointers(session.lastOutcomeEventByAgentID)
        lastConstructionEventID = session.lastConstructionEventID
        socialEnabled = session.socialEnabled
        socialFacts = session.socialFacts
        socialMessages = session.socialMessages
        socialBeliefs = session.socialBeliefs
        socialTrustRelations = session.socialTrustRelations
        activeSocialVerifications = session.activeSocialVerificationByAgentId.keys.sorted().compactMap { id in
            session.activeSocialVerificationByAgentId[id].map {
                AgentCheckpointSocialVerificationEntry(agentID: id, beliefID: $0)
            }
        }
        lastSocialShareTicks = session.lastSocialShareTickByAgentId.keys.sorted().compactMap { id in
            session.lastSocialShareTickByAgentId[id].map {
                AgentCheckpointStringIntEntry(key: id, value: $0)
            }
        }
        socialEvictionCounts = session.socialEvictionCounts
        physicalEnabled = session.physicalEnabled
        physicalSignals = session.physicalSignals
        physicalPerceptions = session.physicalPerceptions
        physicalPresentationRequests = session.physicalPresentationRequests
        physicalEvictionCounts = session.physicalEvictionCounts
        cooperationEnabled = session.cooperationEnabled
        sharedTasks = session.sharedTasks
        sharedTaskOffers = session.sharedTaskOffers
        cooperationRelations = session.cooperationRelations
        cooperationEvictionCounts = session.cooperationEvictionCounts
        lastCooperationOfferTicks = session.lastCooperationOfferTickByIssuerID.keys.sorted().compactMap { id in
            session.lastCooperationOfferTickByIssuerID[id].map {
                AgentCheckpointStringIntEntry(key: id, value: $0)
            }
        }
        populationRegistry = session.populationRegistry
        settlementMetricsState = session.settlementMetricsState
    }
}

public struct AgentSessionCheckpoint: Codable {
    public let schemaVersion: Int
    public let checkpointID: AgentCheckpointID
    public let simulationID: AgentSimulationID
    public let tick: AgentSimulationTick
    public let semanticDigest: AgentCheckpointDigest
    public let durableState: AgentSessionDurableState

    init(durableState: AgentSessionDurableState) throws {
        let bytes = try AgentCheckpointCodec.encodeDurableState(durableState)
        let digest = AgentCheckpointDigest.sha256(bytes)
        let simulationDigest = AgentCheckpointDigest.sha256(
            Data(durableState.clock.simulationID.rawValue.utf8)
        )
        let idText = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(durableState.clock.tick.rawValue)-\(digest.rawValue.prefix(16))"
        guard let checkpointID = AgentCheckpointID(rawValue: idText) else {
            throw AgentCheckpointError.invalidCheckpointID(idText)
        }
        schemaVersion = durableState.schemaVersion
        self.checkpointID = checkpointID
        simulationID = durableState.clock.simulationID
        tick = durableState.clock.tick
        semanticDigest = digest
        self.durableState = durableState
    }
}

public struct AgentCheckpointWorldCell: Codable, Equatable, Sendable {
    public let position: AgentPosition
    public let blockFingerprint: Int

    public init(position: AgentPosition, blockFingerprint: Int) {
        self.position = position
        self.blockFingerprint = blockFingerprint
    }
}

public struct AgentCheckpointWorldBinding: Codable, Equatable, Sendable {
    public let worldID: String
    public let storageIdentity: String
    public let seed: UInt32
    public let dimension: Int
    public let anchor: AgentPosition
    public let simulationID: AgentSimulationID
    public let checkpointTick: AgentSimulationTick
    public let cells: [AgentCheckpointWorldCell]
    public let compatibilityDigest: AgentCheckpointDigest

    public init(
        worldID: String,
        storageIdentity: String,
        seed: UInt32,
        dimension: Int,
        anchor: AgentPosition,
        simulationID: AgentSimulationID,
        checkpointTick: AgentSimulationTick,
        cells: [AgentCheckpointWorldCell]
    ) throws {
        guard !worldID.isEmpty, !storageIdentity.isEmpty,
              cells.count <= AgentCheckpointLimits.maximumBoundWorldCells,
              Set(cells.map(\.position)).count == cells.count else {
            throw AgentCheckpointError.invalidWorldBinding
        }
        let ordered = cells.sorted {
            if $0.position.x != $1.position.x { return $0.position.x < $1.position.x }
            if $0.position.y != $1.position.y { return $0.position.y < $1.position.y }
            return $0.position.z < $1.position.z
        }
        let canonical = [
            worldID, storageIdentity, String(seed), String(dimension),
            "\(anchor.x),\(anchor.y),\(anchor.z)", simulationID.rawValue,
            String(checkpointTick.rawValue),
            ordered.map { "\($0.position.x),\($0.position.y),\($0.position.z)=\($0.blockFingerprint)" }
                .joined(separator: ";"),
        ].joined(separator: "|")
        self.worldID = worldID
        self.storageIdentity = storageIdentity
        self.seed = seed
        self.dimension = dimension
        self.anchor = anchor
        self.simulationID = simulationID
        self.checkpointTick = checkpointTick
        self.cells = ordered
        compatibilityDigest = AgentCheckpointDigest.sha256(Data(canonical.utf8))
    }
}

public struct AgentCheckpointLiveOrchestration: Codable, Equatable, Sendable {
    public let cognitiveHz: Int
    public let wasPaused: Bool
    public let movementEnabled: Bool
    public let autoInteractionEnabled: Bool
    public let economyAutoEnabled: Bool
    public let focusedAgentID: String?
    public let naturalResourceScanDiagnostics: AgentNaturalResourceScanDiagnostics?

    public init(
        cognitiveHz: Int,
        wasPaused: Bool,
        movementEnabled: Bool,
        autoInteractionEnabled: Bool,
        economyAutoEnabled: Bool,
        focusedAgentID: String? = nil,
        naturalResourceScanDiagnostics: AgentNaturalResourceScanDiagnostics? = nil
    ) {
        self.cognitiveHz = cognitiveHz
        self.wasPaused = wasPaused
        self.movementEnabled = movementEnabled
        self.autoInteractionEnabled = autoInteractionEnabled
        self.economyAutoEnabled = economyAutoEnabled
        self.focusedAgentID = focusedAgentID
        self.naturalResourceScanDiagnostics = naturalResourceScanDiagnostics
    }
}

public struct AgentCheckpointManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let name: AgentCheckpointName
    public let checkpointID: AgentCheckpointID
    public let semanticDigest: AgentCheckpointDigest
    public let storageDigest: AgentCheckpointDigest
    public let byteLength: Int
    public let restartSafe: Bool
    public let restartSafetyReason: String
    public let worldBinding: AgentCheckpointWorldBinding
    public let orchestration: AgentCheckpointLiveOrchestration

    public init(
        name: AgentCheckpointName,
        checkpoint: AgentSessionCheckpoint,
        storageDigest: AgentCheckpointDigest,
        byteLength: Int,
        restartSafe: Bool,
        restartSafetyReason: String,
        worldBinding: AgentCheckpointWorldBinding,
        orchestration: AgentCheckpointLiveOrchestration
    ) {
        schemaVersion = checkpoint.schemaVersion
        self.name = name
        checkpointID = checkpoint.checkpointID
        semanticDigest = checkpoint.semanticDigest
        self.storageDigest = storageDigest
        self.byteLength = byteLength
        self.restartSafe = restartSafe
        self.restartSafetyReason = restartSafetyReason
        self.worldBinding = worldBinding
        self.orchestration = orchestration
    }
}

public struct AgentCheckpointReadiness: Codable, Equatable, Sendable {
    public let ready: Bool
    public let blockingReasons: [String]
    public let tick: Int
    public let pendingOperationCount: Int
    public let conservationBalanced: Bool
    public let replayRecordingStatus: String

    public init(
        ready: Bool,
        blockingReasons: [String],
        tick: Int,
        pendingOperationCount: Int,
        conservationBalanced: Bool,
        replayRecordingStatus: String
    ) {
        self.ready = ready
        self.blockingReasons = blockingReasons
        self.tick = tick
        self.pendingOperationCount = pendingOperationCount
        self.conservationBalanced = conservationBalanced
        self.replayRecordingStatus = replayRecordingStatus
    }
}

public struct AgentCheckpointValidationReport: Codable, Equatable, Sendable {
    public let valid: Bool
    public let checkpointID: AgentCheckpointID
    public let semanticDigest: AgentCheckpointDigest
    public let tick: Int
    public let causalSequence: UInt64
    public let causalDigest: String

    public init(
        valid: Bool,
        checkpointID: AgentCheckpointID,
        semanticDigest: AgentCheckpointDigest,
        tick: Int,
        causalSequence: UInt64,
        causalDigest: String
    ) {
        self.valid = valid
        self.checkpointID = checkpointID
        self.semanticDigest = semanticDigest
        self.tick = tick
        self.causalSequence = causalSequence
        self.causalDigest = causalDigest
    }
}

public enum AgentCheckpointError: Error, Equatable, CustomStringConvertible {
    case unsupportedSchema(Int)
    case invalidCheckpointID(String)
    case semanticDigestMismatch
    case invalidConfiguration
    case invalidClock
    case duplicateAgent(String)
    case invalidAgent(String)
    case invalidReference(String)
    case invalidBound(String)
    case invalidConservation
    case invalidCausalState
    case invalidWorldBinding
    case worldBindingMismatch(String)
    case oversizedCheckpoint(Int)

    public var description: String {
        switch self {
        case let .unsupportedSchema(version): return "unsupported checkpoint schema \(version)"
        case let .invalidCheckpointID(id): return "invalid checkpoint ID \(id)"
        case .semanticDigestMismatch: return "checkpoint semantic digest mismatch"
        case .invalidConfiguration: return "invalid checkpoint configuration"
        case .invalidClock: return "invalid checkpoint clock"
        case let .duplicateAgent(id): return "duplicate checkpoint agent \(id)"
        case let .invalidAgent(id): return "invalid checkpoint agent \(id)"
        case let .invalidReference(value): return "invalid checkpoint reference \(value)"
        case let .invalidBound(value): return "checkpoint bound exceeded: \(value)"
        case .invalidConservation: return "checkpoint conservation diverged"
        case .invalidCausalState: return "checkpoint causal state invalid"
        case .invalidWorldBinding: return "checkpoint World binding invalid"
        case let .worldBindingMismatch(reason): return "checkpoint World binding mismatch: \(reason)"
        case let .oversizedCheckpoint(bytes): return "checkpoint size \(bytes) exceeds limit"
        }
    }
}

public enum AgentCheckpointCodec {
    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    public static func decoder() -> JSONDecoder { JSONDecoder() }

    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder().encode(value)
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder().decode(type, from: data)
    }

    static func encodeDurableState(_ state: AgentSessionDurableState) throws -> Data {
        try encode(state)
    }
}

extension AgentSimulationSession {
    public func checkpointReadiness(
        pendingOperationCount: Int = 0,
        replayRecordingStatus: String = "inactive"
    ) -> AgentCheckpointReadiness {
        var reasons: [String] = []
        let conservation = conservationSnapshot().balanced
        if !conservation { reasons.append("material conservation is not exact") }
        if pendingOperationCount != 0 { reasons.append("pending operations: \(pendingOperationCount)") }
        let ledger = causalLedgerSnapshot().summary
        if ledger.currentTick.rawValue != tick { reasons.append("causal clock differs from session clock") }
        return AgentCheckpointReadiness(
            ready: reasons.isEmpty,
            blockingReasons: reasons,
            tick: tick,
            pendingOperationCount: pendingOperationCount,
            conservationBalanced: conservation,
            replayRecordingStatus: replayRecordingStatus
        )
    }

    public func durableState() -> AgentSessionDurableState {
        AgentSessionDurableState(session: self)
    }

    public func durableStateBytes() throws -> Data {
        try AgentCheckpointCodec.encodeDurableState(durableState())
    }

    public func durableStateDigest() throws -> AgentCheckpointDigest {
        AgentCheckpointDigest.sha256(try durableStateBytes())
    }

    public func makeCheckpoint() throws -> AgentSessionCheckpoint {
        let readiness = checkpointReadiness()
        guard readiness.ready else { throw AgentCheckpointError.invalidConservation }
        return try AgentSessionCheckpoint(durableState: durableState())
    }

    public static func restoring(_ checkpoint: AgentSessionCheckpoint) throws -> AgentSimulationSession {
        let report = try validate(checkpoint)
        guard report.valid else { throw AgentCheckpointError.semanticDigestMismatch }
        return try AgentSimulationSession(restoring: checkpoint.durableState)
    }

    public static func validate(
        _ checkpoint: AgentSessionCheckpoint
    ) throws -> AgentCheckpointValidationReport {
        guard AgentCheckpointSchema.supports(checkpoint.schemaVersion),
              checkpoint.durableState.schemaVersion == checkpoint.schemaVersion else {
            throw AgentCheckpointError.unsupportedSchema(checkpoint.schemaVersion)
        }
        guard checkpoint.simulationID == checkpoint.durableState.clock.simulationID,
              checkpoint.tick == checkpoint.durableState.clock.tick else {
            throw AgentCheckpointError.invalidClock
        }
        let bytes = try AgentCheckpointCodec.encodeDurableState(checkpoint.durableState)
        let digest = AgentCheckpointDigest.sha256(bytes)
        guard digest == checkpoint.semanticDigest else {
            throw AgentCheckpointError.semanticDigestMismatch
        }
        let expectedID = try AgentSessionCheckpoint(durableState: checkpoint.durableState).checkpointID
        guard expectedID == checkpoint.checkpointID else {
            throw AgentCheckpointError.invalidCheckpointID(checkpoint.checkpointID.rawValue)
        }
        let candidate = try AgentSimulationSession(restoring: checkpoint.durableState)
        guard try candidate.durableStateDigest() == checkpoint.semanticDigest else {
            throw AgentCheckpointError.semanticDigestMismatch
        }
        let causal = candidate.causalLedgerSnapshot().summary
        return AgentCheckpointValidationReport(
            valid: true,
            checkpointID: checkpoint.checkpointID,
            semanticDigest: checkpoint.semanticDigest,
            tick: candidate.tick,
            causalSequence: causal.latestSequence,
            causalDigest: causal.digest
        )
    }

    init(restoring state: AgentSessionDurableState) throws {
        try Self.validateDurableState(state)
        configuration = state.configuration
        clock = state.clock
        var store = AgentStateStore()
        for agent in state.agents { store[agent.id] = agent }
        statesById = store
        processedInteractionIds = Set(state.processedInteractionIDs)
        creditedResourceKeys = Set(state.creditedResourceKeys)
        reservationsByTarget = Dictionary(uniqueKeysWithValues: state.reservations.map {
            (AgentResourceIdentity(
                source: $0.source,
                position: $0.target,
                resource: $0.resource,
                expectedBlockFingerprint: $0.expectedBlockFingerprint
            ).stableKey, $0)
        })
        failedNaturalResourceTargetKeysByAgentId = Dictionary(uniqueKeysWithValues:
            state.failedNaturalResourceTargets.map { ($0.agentID, $0.targetKeys) }
        )
        economyEnabled = state.economyEnabled
        naturalResourcesEnabled = state.naturalResourcesEnabled
        campStock = state.campStock
        harvestedResourceTotals = state.harvestedResourceTotals
        processedDeliveryIds = Set(state.processedDeliveryIDs)
        survivalEnabled = state.survivalEnabled
        consumedResourceTotals = state.consumedResourceTotals
        processedConsumptionIds = Set(state.processedConsumptionIDs)
        buildAutoEnabled = state.buildAutoEnabled
        constructionProject = state.constructionProject
        processedConstructionFundingIds = Set(state.processedConstructionFundingIDs)
        processedConstructionPlacementIds = Set(state.processedConstructionPlacementIDs)
        processedConstructionFailureIds = Set(state.processedConstructionFailureIDs)
        lastConstructionPlacementTick = state.lastConstructionPlacementTick
        causalLedger = try AgentCausalLedger(restoring: state.causalLedger)
        lastPerceptionEventByAgentID = Dictionary(uniqueKeysWithValues:
            state.lastPerceptionEvents.map { ($0.agentID, $0.eventID) }
        )
        lastDecisionEventByAgentID = Dictionary(uniqueKeysWithValues:
            state.lastDecisionEvents.map { ($0.agentID, $0.eventID) }
        )
        lastOutcomeEventByAgentID = Dictionary(uniqueKeysWithValues:
            state.lastOutcomeEvents.map { ($0.agentID, $0.eventID) }
        )
        lastConstructionEventID = state.lastConstructionEventID
        socialEnabled = state.socialEnabled
        socialFacts = state.socialFacts
        socialMessages = state.socialMessages
        socialBeliefs = state.socialBeliefs
        socialTrustRelations = state.socialTrustRelations
        activeSocialVerificationByAgentId = Dictionary(uniqueKeysWithValues:
            state.activeSocialVerifications.map { ($0.agentID, $0.beliefID) }
        )
        lastSocialShareTickByAgentId = Dictionary(uniqueKeysWithValues:
            state.lastSocialShareTicks.map { ($0.key, $0.value) }
        )
        socialEvictionCounts = state.socialEvictionCounts
        physicalEnabled = state.physicalEnabled
        physicalSignals = state.physicalSignals
        physicalPerceptions = state.physicalPerceptions
        physicalPresentationRequests = state.physicalPresentationRequests
        physicalEvictionCounts = state.physicalEvictionCounts
        cooperationEnabled = state.cooperationEnabled
        sharedTasks = state.sharedTasks
        sharedTaskOffers = state.sharedTaskOffers
        cooperationRelations = state.cooperationRelations
        cooperationEvictionCounts = state.cooperationEvictionCounts
        lastCooperationOfferTickByIssuerID = Dictionary(uniqueKeysWithValues:
            state.lastCooperationOfferTicks.map { ($0.key, $0.value) }
        )
        populationRegistry = state.populationRegistry
        settlementMetricsState = state.settlementMetricsState
        if let settlementMetricsState {
            try validateSettlementMetricsState(settlementMetricsState)
        }
        guard conservationSnapshot().balanced else { throw AgentCheckpointError.invalidConservation }
    }

    static func validateDurableState(_ state: AgentSessionDurableState) throws {
        guard AgentCheckpointSchema.supports(state.schemaVersion) else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard (state.schemaVersion == AgentCheckpointSchema.currentVersion
                && state.populationRegistry == nil && state.settlementMetricsState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.populationVersion
                    && state.populationRegistry != nil && state.settlementMetricsState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.settlementMetricsVersion
                    && state.populationRegistry != nil
                    && state.settlementMetricsState != nil) else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard state.clock.tick.rawValue >= 0,
              AgentSimulationID(rawValue: state.clock.simulationID.rawValue) != nil else {
            throw AgentCheckpointError.invalidClock
        }
        do {
            _ = try AgentSessionConfiguration(
                seed: state.configuration.seed,
                nearbyRadius: state.configuration.nearbyRadius,
                resourceObservationRadius: state.configuration.resourceObservationRadius,
                recentMemorySnapshotLimit: state.configuration.recentMemorySnapshotLimit,
                memoryPolicy: state.configuration.memoryPolicy,
                feedbackLoopConfiguration: state.configuration.feedbackLoopConfiguration,
                navigationMaxReplans: state.configuration.navigationMaxReplans,
                navigationReplanCooldownTicks: state.configuration.navigationReplanCooldownTicks,
                reservationLifetimeTicks: state.configuration.reservationLifetimeTicks,
                deliveryQuota: state.configuration.deliveryQuota,
                campStockCapacity: state.configuration.campStockCapacity,
                survivalConfiguration: state.configuration.survivalConfiguration,
                socialConfiguration: state.configuration.socialConfiguration,
                physicalChannelConfiguration: state.configuration.physicalChannelConfiguration,
                cooperationConfiguration: state.configuration.cooperationConfiguration
            )
        } catch {
            throw AgentCheckpointError.invalidConfiguration
        }
        guard !state.agents.isEmpty else { throw AgentCheckpointError.invalidAgent("empty") }
        var agentIDs = Set<AgentID>()
        for agent in state.agents {
            guard AgentID(rawValue: agent.id) != nil, agentIDs.insert(agent.agentID).inserted else {
                throw AgentCheckpointError.duplicateAgent(agent.id)
            }
            let counters = [
                agent.tickCreated, agent.ticksAlive, agent.observationCount,
                agent.nearbyObservationCount, agent.goalSelectionCount, agent.goalChangeCount,
                agent.actionCount, agent.actionEffectCount, agent.movementCount,
                agent.totalManhattanDistanceMoved, agent.returnHomeMoveCount,
                agent.totalDistanceReducedTowardHome, agent.feedbackMemoryWriteCount,
                agent.feedbackMemoryDeduplicatedCount, agent.memoryRetrievalCount,
                agent.memoryInfluencedDecisionCount,
            ]
            guard counters.allSatisfy({ $0 >= 0 }), agent.tickCreated <= state.clock.tick.rawValue,
                  agent.memory.allSatisfy({ $0.tick >= 0 && $0.tick <= state.clock.tick.rawValue }),
                  agent.needs.hunger.isFinite, agent.needs.fatigue.isFinite,
                  agent.needs.curiosity.isFinite, agent.needs.safety.isFinite,
                  validInventory(agent.resourceInventory) else {
                throw AgentCheckpointError.invalidAgent(agent.id)
            }
            if case let .bounded(maxEntries) = state.configuration.memoryPolicy,
               agent.memory.count > maxEntries {
                throw AgentCheckpointError.invalidBound("memory for \(agent.id)")
            }
        }
        func unique(_ values: [String], _ label: String) throws {
            guard values.count == Set(values).count,
                  values.count <= AgentCheckpointLimits.maximumProcessedOperationIDs else {
                throw AgentCheckpointError.invalidBound(label)
            }
        }
        try unique(state.processedInteractionIDs, "interaction IDs")
        try unique(state.creditedResourceKeys, "resource credits")
        try unique(state.processedDeliveryIDs, "delivery IDs")
        try unique(state.processedConsumptionIDs, "consumption IDs")
        try unique(state.processedConstructionFundingIDs, "funding IDs")
        try unique(state.processedConstructionPlacementIDs, "placement IDs")
        try unique(state.processedConstructionFailureIDs, "failure IDs")
        guard validStock(state.campStock), validStock(state.harvestedResourceTotals),
              validStock(state.consumedResourceTotals) else {
            throw AgentCheckpointError.invalidBound("resource totals")
        }
        for reservation in state.reservations {
            guard let reservationAgentID = AgentID(rawValue: reservation.agentId),
                  agentIDs.contains(reservationAgentID) else {
                throw AgentCheckpointError.invalidReference(reservation.agentId)
            }
        }
        let reservationKeys = state.reservations.map {
            AgentResourceIdentity(
                source: $0.source,
                position: $0.target,
                resource: $0.resource,
                expectedBlockFingerprint: $0.expectedBlockFingerprint
            ).stableKey
        }
        guard reservationKeys.count == Set(reservationKeys).count,
              state.failedNaturalResourceTargets.map(\.agentID).count
                == Set(state.failedNaturalResourceTargets.map(\.agentID)).count,
              state.lastPerceptionEvents.map(\.agentID).count
                == Set(state.lastPerceptionEvents.map(\.agentID)).count,
              state.lastDecisionEvents.map(\.agentID).count
                == Set(state.lastDecisionEvents.map(\.agentID)).count,
              state.lastOutcomeEvents.map(\.agentID).count
                == Set(state.lastOutcomeEvents.map(\.agentID)).count,
              state.activeSocialVerifications.map(\.agentID).count
                == Set(state.activeSocialVerifications.map(\.agentID)).count,
              state.lastSocialShareTicks.map(\.key).count
                == Set(state.lastSocialShareTicks.map(\.key)).count,
              state.lastCooperationOfferTicks.map(\.key).count
                == Set(state.lastCooperationOfferTicks.map(\.key)).count else {
            throw AgentCheckpointError.invalidBound("duplicate keyed state")
        }
        for entry in state.failedNaturalResourceTargets {
            guard agentIDs.contains(AgentID(rawValue: entry.agentID) ?? AgentID(rawValue: "invalid")!),
                  entry.targetKeys.count <= maximumFailedNaturalResourceTargetsPerAgent,
                  entry.targetKeys.count == Set(entry.targetKeys).count else {
                throw AgentCheckpointError.invalidReference(entry.agentID)
            }
        }
        if let project = state.constructionProject,
           !agentIDs.contains(AgentID(rawValue: project.builderAgentId) ?? AgentID(rawValue: "invalid")!) {
            throw AgentCheckpointError.invalidReference(project.builderAgentId)
        }
        try validateCausalState(state.causalLedger, simulationID: state.clock.simulationID, tick: state.clock.tick)
        let constructionPointers = state.lastConstructionEventID.map {
            [AgentCheckpointCausalPointer(agentID: state.agents[0].agentID, eventID: $0)]
        } ?? []
        let pointers = state.lastPerceptionEvents + state.lastDecisionEvents
            + state.lastOutcomeEvents + constructionPointers
        for pointer in pointers {
            guard agentIDs.contains(pointer.agentID),
                  pointer.eventID.simulationID == state.clock.simulationID,
                  pointer.eventID.sequence.rawValue <= state.causalLedger.latestSequence else {
                throw AgentCheckpointError.invalidCausalState
            }
        }
        guard state.socialEvictionCounts.facts >= 0,
              state.socialEvictionCounts.messages >= 0,
              state.socialEvictionCounts.beliefs >= 0,
              state.socialEvictionCounts.trustRelations >= 0,
              state.physicalEvictionCounts.signals >= 0,
              state.physicalEvictionCounts.perceptions >= 0,
              state.physicalEvictionCounts.presentations >= 0,
              state.cooperationEvictionCounts.tasks >= 0,
              state.cooperationEvictionCounts.offers >= 0,
              state.cooperationEvictionCounts.relations >= 0 else {
            throw AgentCheckpointError.invalidBound("eviction counts")
        }
        for task in state.sharedTasks {
            guard agentIDs.contains(task.issuerID), agentIDs.contains(task.helperID),
                  task.requestedQuantity > 0,
                  (0...task.requestedQuantity).contains(task.contributedQuantity) else {
                throw AgentCheckpointError.invalidReference(task.taskID.rawValue)
            }
        }
        if let populationRegistry = state.populationRegistry {
            try validatePopulationRegistry(
                populationRegistry,
                agents: state.agents,
                clock: state.clock
            )
        }
        if let metrics = state.settlementMetricsState {
            guard metrics.settlementID == state.populationRegistry?.settlement.settlementID,
                  metrics.configuration.maximumAgentClassifications
                    >= (state.populationRegistry?.configuration.maximumActivePopulation ?? Int.max),
                  metrics.lastPulseTick >= 0,
                  metrics.lastPulseTick <= state.clock.tick.rawValue,
                  metrics.nextPulseTick
                    == metrics.lastPulseTick + metrics.configuration.macroIntervalTicks,
                  metrics.nextPulseTick > state.clock.tick.rawValue,
                  metrics.baseline.tick == metrics.lastPulseTick,
                  metrics.baseline.causalSequence <= state.causalLedger.latestSequence,
                  metrics.frames.count <= metrics.configuration.maximumMetricFrames,
                  metrics.evictionCounts.frames >= 0,
                  metrics.initializedEventID.simulationID == state.clock.simulationID,
                  metrics.lastSettlementEventID.simulationID == state.clock.simulationID,
                  metrics.initializedEventID.sequence <= metrics.lastSettlementEventID.sequence,
                  metrics.lastSettlementEventID.sequence.rawValue
                    <= state.causalLedger.latestSequence else {
                throw AgentCheckpointError.invalidBound("settlement metrics")
            }
            do {
                _ = try AgentSettlementMetricsConfiguration(
                    macroIntervalTicks: metrics.configuration.macroIntervalTicks,
                    maximumMetricFrames: metrics.configuration.maximumMetricFrames,
                    maximumAgentClassifications:
                        metrics.configuration.maximumAgentClassifications,
                    maximumCausalEventsPerWindow:
                        metrics.configuration.maximumCausalEventsPerWindow,
                    fixedPointScale: metrics.configuration.fixedPointScale
                )
            } catch {
                throw AgentCheckpointError.invalidConfiguration
            }
        }
        for relation in state.socialTrustRelations {
            guard agentIDs.contains(relation.sourceID), agentIDs.contains(relation.targetID),
                  relation.score >= state.configuration.socialConfiguration.minimumTrust,
                  relation.score <= state.configuration.socialConfiguration.maximumTrust else {
                throw AgentCheckpointError.invalidReference(relation.relationID.rawValue)
            }
        }
        for relation in state.cooperationRelations {
            guard agentIDs.contains(relation.issuerID), agentIDs.contains(relation.helperID),
                  relation.reliabilityScore >= state.configuration.cooperationConfiguration.minimumReliability,
                  relation.reliabilityScore <= state.configuration.cooperationConfiguration.maximumReliability else {
                throw AgentCheckpointError.invalidReference(relation.relationID.rawValue)
            }
        }
    }

    static func validateCausalState(
        _ ledger: AgentCausalLedgerDurableState,
        simulationID: AgentSimulationID,
        tick: AgentSimulationTick
    ) throws {
        if case let .bounded(maxEvents) = ledger.policy {
            guard maxEvents > 0, ledger.events.count <= maxEvents else {
                throw AgentCheckpointError.invalidCausalState
            }
        } else if !ledger.events.isEmpty || ledger.latestSequence != 0 || ledger.droppedEventCount != 0 {
            throw AgentCheckpointError.invalidCausalState
        }
        var previous: UInt64 = 0
        for event in ledger.events {
            guard event.schemaVersion == 1, event.simulationID == simulationID,
                  event.eventID.simulationID == simulationID,
                  event.sequence == event.eventID.sequence,
                  event.sequence.rawValue > previous,
                  event.sequence.rawValue <= ledger.latestSequence,
                  event.simulationTick <= tick,
                  event.causes.allSatisfy({
                      $0.simulationID == simulationID && $0.sequence < event.sequence
                  }) else {
                throw AgentCheckpointError.invalidCausalState
            }
            do {
                let rebuilt = try AgentCausalEvent(
                    id: event.eventID,
                    instant: event.instant,
                    kind: event.kind,
                    origin: event.origin,
                    actorID: event.actorID,
                    subjectID: event.subjectID,
                    operationID: event.operationID,
                    causes: event.causes,
                    payload: event.payload,
                    summary: event.summary
                )
                guard rebuilt.digest == event.digest else {
                    throw AgentCheckpointError.invalidCausalState
                }
            } catch {
                throw AgentCheckpointError.invalidCausalState
            }
            previous = event.sequence.rawValue
        }
        guard ledger.events.last?.sequence.rawValue == ledger.latestSequence || ledger.latestSequence == 0,
              !ledger.rollingDigest.isEmpty else {
            throw AgentCheckpointError.invalidCausalState
        }
        if ledger.droppedEventCount == 0 {
            var rolling = AgentCausalEvent.digest("")
            for event in ledger.events {
                rolling = AgentCausalEvent.digest("\(rolling)|\(event.digest)")
            }
            guard rolling == ledger.rollingDigest else {
                throw AgentCheckpointError.invalidCausalState
            }
        }
    }

    static func validInventory(_ inventory: AgentResourceInventory) -> Bool {
        inventory.capacity > 0 && inventory.totalCount <= inventory.capacity
            && inventory.amounts.allSatisfy { $0.quantity > 0 }
    }

    static func validStock(_ stock: AgentCampStock) -> Bool {
        stock.capacity > 0 && stock.totalCount <= stock.capacity
            && stock.amounts.allSatisfy { $0.quantity > 0 }
    }
}
