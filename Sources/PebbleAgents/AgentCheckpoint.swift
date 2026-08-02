import CryptoKit
import Foundation

public enum AgentCheckpointSchema {
    public static let currentVersion = 1
    public static let populationVersion = 2
    public static let settlementMetricsVersion = 3
    public static let localEcologyVersion = 4
    public static let mortalityVersion = 5
    public static let lifecycleVersion = 6
    public static let kinshipVersion = 7
    public static let householdVersion = 8
    public static let dependentCareVersion = 9
    public static let skillVersion = 10
    public static let teachingVersion = 11
    public static let ecologicalObservationVersion = 12
    public static let agricultureVersion = 13
    public static let wildSubsistenceVersion = 14
    public static let livestockVersion = 15
    public static let workCommitmentVersion = 16
    public static let physicalFoodSurvivalVersion = 17
    public static let autonomousActivityVersion = 18
    public static let materialRightsVersion = 19
    public static let persistenceReconciliationVersion = 20
    public static let homeostasisVersion = 21
    public static let geneticsVersion = 22
    public static let childhoodVersion = 23
    public static let verifiedSupervisionVersion = 24
    public static let familyVersion = 25
    public static let durableHouseConsentVersion = 26
    public static let legacyEstateVersion = 27
    public static let estateVersion = 28
    public static let renewableSubsistenceVersion = 29
    public static let independentEcologicalReceiptVersion = 30

    public static func supports(_ version: Int) -> Bool {
        version == currentVersion || version == populationVersion
            || version == settlementMetricsVersion || version == localEcologyVersion
            || version == mortalityVersion || version == lifecycleVersion
            || version == kinshipVersion || version == householdVersion
            || version == dependentCareVersion || version == skillVersion
            || version == teachingVersion || version == ecologicalObservationVersion
            || version == agricultureVersion || version == wildSubsistenceVersion
            || version == livestockVersion || version == workCommitmentVersion
            || version == physicalFoodSurvivalVersion || version == autonomousActivityVersion
            || version == materialRightsVersion || version == persistenceReconciliationVersion
            || version == homeostasisVersion || version == geneticsVersion
            || version == childhoodVersion || version == verifiedSupervisionVersion
            || version == familyVersion || version == durableHouseConsentVersion
            || version == legacyEstateVersion || version == estateVersion
            || version == renewableSubsistenceVersion
            || version == independentEcologicalReceiptVersion
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
    public let localEcologyState: AgentLocalEcologyState?
    public let mortalityState: AgentMortalityState?
    public let lifecycleState: AgentLifecycleState?
    public let kinshipState: AgentKinshipState?
    public let householdState: AgentHouseholdState?
    public let dependentCareState: AgentDependentCareState?
    public let skillState: AgentSkillState?
    public let teachingState: AgentTeachingState?
    public let ecologicalObservationState: AgentEcologicalObservationState?
    public let agricultureState: AgentAgricultureState?
    public let wildSubsistenceState: AgentWildSubsistenceState?
    public let livestockState: AgentLivestockState?
    public let workCommitmentState: AgentWorkCommitmentState?
    public let physicalFoodSurvivalState: AgentPhysicalFoodSurvivalState?
    public let autonomousActivityState: AgentAutonomousActivityState?
    public let materialRightsState: AgentMaterialRightsState?
    public let persistenceReconciliationState: AgentPersistenceReconciliationState?
    public let homeostasisState: AgentHomeostasisState?
    public let geneticsState: AgentGeneticsState?
    public let familyState: AgentFamilyState?
    public let estateState: AgentEstateState?

    init(session: AgentSimulationSession) {
        if session.ecologicalObservationState?.observations.isEmpty == false
            || session.agricultureState?.plots.isEmpty == false {
            schemaVersion = AgentCheckpointSchema
                .independentEcologicalReceiptVersion
        } else if session.agricultureState?.plots.contains(where: {
            $0.cycleOrdinal > 1 && $0.renewalEvidence != nil
        }) == true {
            schemaVersion = AgentCheckpointSchema.renewableSubsistenceVersion
        } else if let estate = session.estateState {
            schemaVersion = estate.estates.allSatisfy({
                $0.successorPlanProof != nil
            }) ? AgentCheckpointSchema.estateVersion
                : AgentCheckpointSchema.legacyEstateVersion
        } else if session.familyState != nil,
           session.durableSchemaVersionOverride
            == AgentCheckpointSchema.familyVersion {
            schemaVersion = AgentCheckpointSchema.familyVersion
        } else if session.familyState != nil {
            schemaVersion = AgentCheckpointSchema.durableHouseConsentVersion
        } else if let override = session.durableSchemaVersionOverride,
           session.dependentCareState?.childhoodV2 != nil {
            schemaVersion = override
        } else if session.dependentCareState?.childhoodV2 != nil {
            schemaVersion = AgentCheckpointSchema.verifiedSupervisionVersion
        } else if session.geneticsState != nil {
            schemaVersion = AgentCheckpointSchema.geneticsVersion
        } else if session.homeostasisState != nil {
            schemaVersion = AgentCheckpointSchema.homeostasisVersion
        } else if session.persistenceReconciliationState != nil {
            schemaVersion = AgentCheckpointSchema.persistenceReconciliationVersion
        } else if session.materialRightsState != nil {
            schemaVersion = AgentCheckpointSchema.materialRightsVersion
        } else if session.autonomousActivityState != nil {
            schemaVersion = AgentCheckpointSchema.autonomousActivityVersion
        } else if session.physicalFoodSurvivalState != nil {
            schemaVersion = AgentCheckpointSchema.physicalFoodSurvivalVersion
        } else if session.workCommitmentState != nil {
            schemaVersion = AgentCheckpointSchema.workCommitmentVersion
        } else if session.livestockState != nil {
            schemaVersion = AgentCheckpointSchema.livestockVersion
        } else if session.wildSubsistenceState != nil {
            schemaVersion = AgentCheckpointSchema.wildSubsistenceVersion
        } else if session.agricultureState != nil {
            schemaVersion = AgentCheckpointSchema.agricultureVersion
        } else if session.ecologicalObservationState != nil {
            schemaVersion = AgentCheckpointSchema.ecologicalObservationVersion
        } else if session.teachingState != nil {
            schemaVersion = AgentCheckpointSchema.teachingVersion
        } else if session.skillState != nil {
            schemaVersion = AgentCheckpointSchema.skillVersion
        } else if session.dependentCareState != nil {
            schemaVersion = AgentCheckpointSchema.dependentCareVersion
        } else if session.householdState != nil {
            schemaVersion = AgentCheckpointSchema.householdVersion
        } else if session.kinshipState != nil {
            schemaVersion = AgentCheckpointSchema.kinshipVersion
        } else if session.lifecycleState != nil {
            schemaVersion = AgentCheckpointSchema.lifecycleVersion
        } else if session.mortalityState != nil {
            schemaVersion = AgentCheckpointSchema.mortalityVersion
        } else if session.localEcologyState != nil {
            schemaVersion = AgentCheckpointSchema.localEcologyVersion
        } else if session.settlementMetricsState != nil {
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
        localEcologyState = session.localEcologyState
        mortalityState = session.mortalityState
        lifecycleState = session.lifecycleState
        kinshipState = session.kinshipState
        householdState = session.householdState
        dependentCareState = session.dependentCareState
        skillState = session.skillState
        teachingState = session.teachingState
        ecologicalObservationState = session.ecologicalObservationState
        agricultureState = session.agricultureState
        wildSubsistenceState = session.wildSubsistenceState
        livestockState = session.livestockState
        workCommitmentState = session.workCommitmentState
        physicalFoodSurvivalState = session.physicalFoodSurvivalState
        autonomousActivityState = session.autonomousActivityState
        materialRightsState = session.materialRightsState
        persistenceReconciliationState = session.persistenceReconciliationState
        homeostasisState = session.homeostasisState
        geneticsState = session.geneticsState
        familyState = session.familyState
        estateState = session.estateState
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
    public let verifiedEmptyProbeAgentIDsAtSave: [String]?

    public init(
        cognitiveHz: Int,
        wasPaused: Bool,
        movementEnabled: Bool,
        autoInteractionEnabled: Bool,
        economyAutoEnabled: Bool,
        focusedAgentID: String? = nil,
        naturalResourceScanDiagnostics: AgentNaturalResourceScanDiagnostics? = nil,
        verifiedEmptyProbeAgentIDsAtSave: [String]? = nil
    ) {
        self.cognitiveHz = cognitiveHz
        self.wasPaused = wasPaused
        self.movementEnabled = movementEnabled
        self.autoInteractionEnabled = autoInteractionEnabled
        self.economyAutoEnabled = economyAutoEnabled
        self.focusedAgentID = focusedAgentID
        self.naturalResourceScanDiagnostics = naturalResourceScanDiagnostics
        self.verifiedEmptyProbeAgentIDsAtSave =
            verifiedEmptyProbeAgentIDsAtSave
    }
}

private struct AgentCheckpointManifestIntegrityPayload: Encodable {
    let integrityVersion: Int
    let schemaVersion: Int
    let name: AgentCheckpointName
    let checkpointID: AgentCheckpointID
    let semanticDigest: AgentCheckpointDigest
    let storageDigest: AgentCheckpointDigest
    let byteLength: Int
    let restartSafe: Bool
    let restartSafetyReason: String
    let worldBinding: AgentCheckpointWorldBinding
    let orchestration: AgentCheckpointLiveOrchestration
    let reconciliationBinding: AgentPersistenceReconciliationBinding?
}

public struct AgentCheckpointManifest: Codable, Equatable, Sendable {
    public static let currentIntegrityVersion = 1

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
    public let reconciliationBinding: AgentPersistenceReconciliationBinding?
    public let manifestIntegrityVersion: Int?
    public let manifestIntegrityDigest: AgentCheckpointDigest?

    public init(
        name: AgentCheckpointName,
        checkpoint: AgentSessionCheckpoint,
        storageDigest: AgentCheckpointDigest,
        byteLength: Int,
        restartSafe: Bool,
        restartSafetyReason: String,
        worldBinding: AgentCheckpointWorldBinding,
        orchestration: AgentCheckpointLiveOrchestration,
        reconciliationBinding: AgentPersistenceReconciliationBinding? = nil
    ) throws {
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
        self.reconciliationBinding = reconciliationBinding
        if checkpoint.schemaVersion >= AgentCheckpointSchema.geneticsVersion {
            manifestIntegrityVersion = Self.currentIntegrityVersion
            manifestIntegrityDigest = try Self.integrityDigest(
                integrityVersion: Self.currentIntegrityVersion,
                schemaVersion: checkpoint.schemaVersion,
                name: name,
                checkpointID: checkpoint.checkpointID,
                semanticDigest: checkpoint.semanticDigest,
                storageDigest: storageDigest,
                byteLength: byteLength,
                restartSafe: restartSafe,
                restartSafetyReason: restartSafetyReason,
                worldBinding: worldBinding,
                orchestration: orchestration,
                reconciliationBinding: reconciliationBinding
            )
        } else {
            manifestIntegrityVersion = nil
            manifestIntegrityDigest = nil
        }
    }

    public func validateIntegrityDigest() throws {
        if schemaVersion >= AgentCheckpointSchema.geneticsVersion {
            guard manifestIntegrityVersion == Self.currentIntegrityVersion,
                  let manifestIntegrityDigest else {
                throw AgentCheckpointError.missingManifestIntegrity
            }
            guard try manifestIntegrityDigest == Self.integrityDigest(
                integrityVersion: Self.currentIntegrityVersion,
                schemaVersion: schemaVersion,
                name: name,
                checkpointID: checkpointID,
                semanticDigest: semanticDigest,
                storageDigest: storageDigest,
                byteLength: byteLength,
                restartSafe: restartSafe,
                restartSafetyReason: restartSafetyReason,
                worldBinding: worldBinding,
                orchestration: orchestration,
                reconciliationBinding: reconciliationBinding
            ) else {
                throw AgentCheckpointError.manifestIntegrityMismatch
            }
            return
        }
        guard manifestIntegrityVersion == nil,
              manifestIntegrityDigest == nil else {
            throw AgentCheckpointError.manifestIntegrityMismatch
        }
    }

    public func protectedVerifiedEmptyProbeAgentIDs(
        for checkpoint: AgentSessionCheckpoint
    ) throws -> [String] {
        try validateIntegrityDigest()
        guard checkpoint.schemaVersion == schemaVersion else {
            throw AgentCheckpointError.invalidPhysicalAttestation
        }
        guard schemaVersion >= AgentCheckpointSchema.geneticsVersion else {
            return []
        }
        guard let values = orchestration.verifiedEmptyProbeAgentIDsAtSave,
              values == values.sorted(),
              values.count == Set(values).count,
              values.allSatisfy({ AgentID(rawValue: $0) != nil }),
              values.count <= (
                  checkpoint.durableState.geneticsState?
                    .configuration.maximumProfiles ?? 512
              ),
              values.count <= checkpoint.durableState.agents.count,
              Set(values).isSubset(of: Set(
                  checkpoint.durableState.agents.map(\.agentID.rawValue)
              )) else {
            throw AgentCheckpointError.invalidPhysicalAttestation
        }
        return values
    }

    public func validateProbeRestoration(
        restoredAgentIDs: [String],
        for checkpoint: AgentSessionCheckpoint
    ) throws -> [String] {
        let protectedAgentIDs = try protectedVerifiedEmptyProbeAgentIDs(
            for: checkpoint
        )
        guard restoredAgentIDs == restoredAgentIDs.sorted(),
              restoredAgentIDs.count == Set(restoredAgentIDs).count,
              restoredAgentIDs.allSatisfy({
                  AgentID(rawValue: $0) != nil
              }),
              Set(restoredAgentIDs).isSubset(of: Set(protectedAgentIDs)) else {
            throw AgentCheckpointError.invalidPhysicalAttestation
        }
        return protectedAgentIDs
    }

    private static func integrityDigest(
        integrityVersion: Int,
        schemaVersion: Int,
        name: AgentCheckpointName,
        checkpointID: AgentCheckpointID,
        semanticDigest: AgentCheckpointDigest,
        storageDigest: AgentCheckpointDigest,
        byteLength: Int,
        restartSafe: Bool,
        restartSafetyReason: String,
        worldBinding: AgentCheckpointWorldBinding,
        orchestration: AgentCheckpointLiveOrchestration,
        reconciliationBinding: AgentPersistenceReconciliationBinding?
    ) throws -> AgentCheckpointDigest {
        AgentCheckpointDigest.sha256(try AgentCheckpointCodec.encode(
            AgentCheckpointManifestIntegrityPayload(
                integrityVersion: integrityVersion,
                schemaVersion: schemaVersion,
                name: name,
                checkpointID: checkpointID,
                semanticDigest: semanticDigest,
                storageDigest: storageDigest,
                byteLength: byteLength,
                restartSafe: restartSafe,
                restartSafetyReason: restartSafetyReason,
                worldBinding: worldBinding,
                orchestration: orchestration,
                reconciliationBinding: reconciliationBinding
            )
        ))
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
    case missingManifestIntegrity
    case manifestIntegrityMismatch
    case invalidPhysicalAttestation
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
        case .missingManifestIntegrity:
            return "checkpoint manifest integrity proof missing"
        case .manifestIntegrityMismatch:
            return "checkpoint manifest integrity mismatch"
        case .invalidPhysicalAttestation:
            return "checkpoint physical attestation invalid"
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
        if localEcologyState != nil, !ecologyConservationSnapshot().balanced {
            reasons.append("ecology conservation is not exact")
        }
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
                expectedBlockFingerprint: $0.expectedBlockFingerprint,
                ecologyPatchID: $0.ecologyPatchID
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
        localEcologyState = state.localEcologyState
        mortalityState = state.mortalityState
        lifecycleState = state.lifecycleState
        kinshipState = state.kinshipState
        householdState = state.householdState
        dependentCareState = state.dependentCareState
        skillState = state.skillState
        teachingState = state.teachingState
        ecologicalObservationState = state.ecologicalObservationState
        agricultureState = state.agricultureState
        wildSubsistenceState = state.wildSubsistenceState
        livestockState = state.livestockState
        workCommitmentState = state.workCommitmentState
        physicalFoodSurvivalState = state.physicalFoodSurvivalState
        autonomousActivityState = state.autonomousActivityState
        materialRightsState = state.materialRightsState
        persistenceReconciliationState = state.persistenceReconciliationState
        homeostasisState = state.homeostasisState
        geneticsState = state.geneticsState
        familyState = state.familyState
        estateState = state.estateState
        latestAutonomousTeachingReview = nil
        durableSchemaVersionOverride =
            state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || state.schemaVersion == AgentCheckpointSchema.familyVersion
                ? state.schemaVersion : nil
        try validateEcologicalObservationStateIfEnabled()
        try validateAgricultureStateIfEnabled()
        try validateWildSubsistenceStateIfEnabled()
        try validateLivestockStateIfEnabled()
        try validateWorkCommitmentStateIfEnabled()
        try validatePhysicalFoodSurvivalStateIfEnabled()
        try validateMaterialRightsStateIfEnabled()
        try validatePersistenceReconciliationStateIfEnabled()
        if let settlementMetricsState {
            try validateSettlementMetricsState(settlementMetricsState)
        }
        guard conservationSnapshot().balanced,
              localEcologyState == nil || ecologyConservationSnapshot().balanced else {
            throw AgentCheckpointError.invalidConservation
        }
    }

    static func validateDurableState(_ state: AgentSessionDurableState) throws {
        guard AgentCheckpointSchema.supports(state.schemaVersion) else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        let independentReceiptSchema = state.schemaVersion
            == AgentCheckpointSchema.independentEcologicalReceiptVersion
        let renewableSchema = state.schemaVersion
            == AgentCheckpointSchema.renewableSubsistenceVersion
        let latestSchema = renewableSchema || independentReceiptSchema
        let estateSchema =
            state.schemaVersion == AgentCheckpointSchema.legacyEstateVersion
            || state.schemaVersion == AgentCheckpointSchema.estateVersion
            || (latestSchema && state.estateState != nil)
        guard state.schemaVersion == AgentCheckpointSchema.familyVersion
                || state.schemaVersion
                    == AgentCheckpointSchema.durableHouseConsentVersion
                || latestSchema
                || estateSchema
                || state.familyState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        if state.schemaVersion == AgentCheckpointSchema.verifiedSupervisionVersion
            || state.schemaVersion == AgentCheckpointSchema.familyVersion
            || state.schemaVersion
                == AgentCheckpointSchema.durableHouseConsentVersion
            || estateSchema {
            guard state.populationRegistry != nil,
                  state.lifecycleState != nil,
                  state.kinshipState != nil,
                  state.householdState != nil,
                  state.dependentCareState?.childhoodV2 != nil,
                  (state.schemaVersion != AgentCheckpointSchema.familyVersion
                      && state.schemaVersion
                        != AgentCheckpointSchema.durableHouseConsentVersion
                      && !estateSchema)
                    || state.familyState != nil else {
                throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
            }
            if estateSchema {
                guard state.estateState != nil,
                      state.mortalityState != nil,
                      state.materialRightsState != nil else {
                    throw AgentCheckpointError.unsupportedSchema(
                        state.schemaVersion
                    )
                }
            } else if state.estateState != nil {
                throw AgentCheckpointError.unsupportedSchema(
                    state.schemaVersion
                )
            }
        } else {
            guard state.schemaVersion == AgentCheckpointSchema.ecologicalObservationVersion
                || state.schemaVersion == AgentCheckpointSchema.agricultureVersion
                || state.schemaVersion == AgentCheckpointSchema.wildSubsistenceVersion
                || state.schemaVersion == AgentCheckpointSchema.livestockVersion
                || state.schemaVersion == AgentCheckpointSchema.workCommitmentVersion
                || state.schemaVersion == AgentCheckpointSchema.physicalFoodSurvivalVersion
                || state.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion
                || state.schemaVersion == AgentCheckpointSchema.materialRightsVersion
                || state.schemaVersion == AgentCheckpointSchema.persistenceReconciliationVersion
                || state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                || state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || latestSchema
                || state.ecologicalObservationState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard state.schemaVersion == AgentCheckpointSchema.agricultureVersion
                || state.schemaVersion == AgentCheckpointSchema.wildSubsistenceVersion
                || state.schemaVersion == AgentCheckpointSchema.livestockVersion
                || state.schemaVersion == AgentCheckpointSchema.workCommitmentVersion
                || state.schemaVersion == AgentCheckpointSchema.physicalFoodSurvivalVersion
                || state.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion
                || state.schemaVersion == AgentCheckpointSchema.materialRightsVersion
                || state.schemaVersion == AgentCheckpointSchema.persistenceReconciliationVersion
                || state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                || state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || latestSchema
                || state.agricultureState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard state.schemaVersion == AgentCheckpointSchema.wildSubsistenceVersion
                || state.schemaVersion == AgentCheckpointSchema.livestockVersion
                || state.schemaVersion == AgentCheckpointSchema.workCommitmentVersion
                || state.schemaVersion == AgentCheckpointSchema.physicalFoodSurvivalVersion
                || state.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion
                || state.schemaVersion == AgentCheckpointSchema.materialRightsVersion
                || state.schemaVersion == AgentCheckpointSchema.persistenceReconciliationVersion
                || state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                || state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || latestSchema
                || state.wildSubsistenceState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard state.schemaVersion == AgentCheckpointSchema.livestockVersion
                || state.schemaVersion == AgentCheckpointSchema.workCommitmentVersion
                || state.schemaVersion == AgentCheckpointSchema.physicalFoodSurvivalVersion
                || state.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion
                || state.schemaVersion == AgentCheckpointSchema.materialRightsVersion
                || state.schemaVersion == AgentCheckpointSchema.persistenceReconciliationVersion
                || state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                || state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || latestSchema
                || state.livestockState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard state.schemaVersion == AgentCheckpointSchema.workCommitmentVersion
                || state.schemaVersion == AgentCheckpointSchema.physicalFoodSurvivalVersion
                || state.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion
                || state.schemaVersion == AgentCheckpointSchema.materialRightsVersion
                || state.schemaVersion == AgentCheckpointSchema.persistenceReconciliationVersion
                || state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                || state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || latestSchema
                || state.workCommitmentState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard state.schemaVersion == AgentCheckpointSchema.physicalFoodSurvivalVersion
                || state.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion
                || state.schemaVersion == AgentCheckpointSchema.materialRightsVersion
                || state.schemaVersion == AgentCheckpointSchema.persistenceReconciliationVersion
                || state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                || state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || latestSchema
                || state.physicalFoodSurvivalState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard state.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion
                || state.schemaVersion == AgentCheckpointSchema.materialRightsVersion
                || state.schemaVersion == AgentCheckpointSchema.persistenceReconciliationVersion
                || state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                || state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || latestSchema
                || state.autonomousActivityState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard state.schemaVersion == AgentCheckpointSchema.materialRightsVersion
                || state.schemaVersion == AgentCheckpointSchema.persistenceReconciliationVersion
                || state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                || state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || latestSchema
                || state.materialRightsState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard state.schemaVersion == AgentCheckpointSchema.persistenceReconciliationVersion
                || state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                || state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || latestSchema
                || state.persistenceReconciliationState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                || state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || latestSchema
                || state.homeostasisState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                || latestSchema
                || state.geneticsState == nil else {
            throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
        }
        guard (state.schemaVersion == AgentCheckpointSchema.currentVersion
                && state.populationRegistry == nil && state.settlementMetricsState == nil
                && state.mortalityState == nil && state.lifecycleState == nil
                && state.kinshipState == nil && state.householdState == nil
                && state.dependentCareState == nil && state.skillState == nil
                && state.teachingState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.populationVersion
                    && state.populationRegistry != nil && state.settlementMetricsState == nil
                    && state.mortalityState == nil && state.lifecycleState == nil
                    && state.kinshipState == nil && state.householdState == nil
                    && state.dependentCareState == nil && state.skillState == nil
                    && state.teachingState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.settlementMetricsVersion
                    && state.populationRegistry != nil
                    && state.settlementMetricsState != nil
                    && state.localEcologyState == nil
                    && state.mortalityState == nil && state.lifecycleState == nil
                    && state.kinshipState == nil && state.householdState == nil
                    && state.dependentCareState == nil && state.skillState == nil
                    && state.teachingState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.localEcologyVersion
                    && state.populationRegistry != nil
                    && state.localEcologyState != nil
                    && state.mortalityState == nil && state.lifecycleState == nil
                    && state.kinshipState == nil && state.householdState == nil
                    && state.dependentCareState == nil && state.skillState == nil
                    && state.teachingState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.mortalityVersion
                    && state.populationRegistry != nil
                    && state.mortalityState != nil
                    && state.lifecycleState == nil && state.kinshipState == nil
                    && state.householdState == nil && state.dependentCareState == nil
                    && state.skillState == nil && state.teachingState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.lifecycleVersion
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil && state.kinshipState == nil
                    && state.householdState == nil && state.dependentCareState == nil
                    && state.skillState == nil && state.teachingState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.kinshipVersion
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil && state.kinshipState != nil
                    && state.householdState == nil && state.dependentCareState == nil
                    && state.skillState == nil && state.teachingState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.householdVersion
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil && state.kinshipState != nil
                    && state.householdState != nil && state.dependentCareState == nil
                    && state.skillState == nil && state.teachingState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.dependentCareVersion
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil && state.kinshipState != nil
                    && state.householdState != nil && state.dependentCareState != nil
                    && state.skillState == nil && state.teachingState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.skillVersion
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil && state.skillState != nil
                    && state.teachingState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.teachingVersion
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil && state.skillState != nil
                    && state.teachingState != nil)
                || (state.schemaVersion == AgentCheckpointSchema.ecologicalObservationVersion
                    && state.populationRegistry != nil
                    && state.ecologicalObservationState != nil
                    && state.agricultureState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.agricultureVersion
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil && state.skillState != nil
                    && state.ecologicalObservationState != nil
                    && state.agricultureState != nil
                    && state.wildSubsistenceState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.wildSubsistenceVersion
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil && state.skillState != nil
                    && state.ecologicalObservationState != nil
                    && state.wildSubsistenceState != nil
                    && state.livestockState == nil)
                || (state.schemaVersion == AgentCheckpointSchema.livestockVersion
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil && state.skillState != nil
                    && state.ecologicalObservationState != nil
                    && state.livestockState != nil)
                || (state.schemaVersion == AgentCheckpointSchema.workCommitmentVersion
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil && state.skillState != nil
                    && state.workCommitmentState != nil)
                || (state.schemaVersion == AgentCheckpointSchema.physicalFoodSurvivalVersion
                    && state.survivalEnabled
                    && state.physicalFoodSurvivalState != nil)
                || (state.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion
                    && state.autonomousActivityState != nil)
                || (state.schemaVersion == AgentCheckpointSchema.materialRightsVersion
                    && state.materialRightsState != nil)
                || (state.schemaVersion
                        == AgentCheckpointSchema.persistenceReconciliationVersion
                    && state.persistenceReconciliationState != nil)
                || (state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                    && state.homeostasisState != nil
                    && state.populationRegistry != nil
                    && state.mortalityState != nil
                    && state.lifecycleState != nil)
                || (state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                    && state.geneticsState != nil
                    && state.homeostasisState != nil
                    && state.populationRegistry != nil
                    && state.mortalityState != nil
                    && state.lifecycleState != nil)
                || (state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil
                    && state.kinshipState != nil
                    && state.householdState != nil
                    && state.dependentCareState?.childhoodV2 != nil)
                || (renewableSchema
                    && state.populationRegistry != nil
                    && state.lifecycleState != nil
                    && state.skillState != nil
                    && state.ecologicalObservationState != nil
                    && state.agricultureState?.plots.contains(where: {
                        $0.cycleOrdinal > 1 && $0.renewalEvidence != nil
                    }) == true)
                || (independentReceiptSchema
                    && state.populationRegistry != nil
                    && state.ecologicalObservationState != nil
                    && state.ecologicalObservationState?.observations
                        .allSatisfy({
                            $0.physicalObservationReceiptID != nil
                        }) == true) else {
                throw AgentCheckpointError.unsupportedSchema(state.schemaVersion)
            }
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
        guard !state.agents.isEmpty
                || ((state.schemaVersion == AgentCheckpointSchema.mortalityVersion
                        || state.schemaVersion == AgentCheckpointSchema.lifecycleVersion
                        || state.schemaVersion == AgentCheckpointSchema.kinshipVersion
                        || state.schemaVersion == AgentCheckpointSchema.householdVersion
                        || state.schemaVersion == AgentCheckpointSchema.dependentCareVersion
                        || state.schemaVersion == AgentCheckpointSchema.skillVersion
                        || state.schemaVersion == AgentCheckpointSchema.workCommitmentVersion
                        || state.schemaVersion == AgentCheckpointSchema.physicalFoodSurvivalVersion
                        || state.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion
                        || state.schemaVersion == AgentCheckpointSchema.materialRightsVersion
                        || state.schemaVersion
                            == AgentCheckpointSchema.persistenceReconciliationVersion
                        || state.schemaVersion == AgentCheckpointSchema.homeostasisVersion
                        || state.schemaVersion == AgentCheckpointSchema.geneticsVersion
                        || state.schemaVersion == AgentCheckpointSchema.childhoodVersion
                        || state.schemaVersion
                            == AgentCheckpointSchema.verifiedSupervisionVersion
                        || state.schemaVersion == AgentCheckpointSchema.familyVersion
                        || state.schemaVersion
                            == AgentCheckpointSchema.durableHouseConsentVersion
                        || estateSchema)
                    && (state.mortalityState?.totalDeathCount ?? 0) > 0) else {
            throw AgentCheckpointError.invalidAgent("empty")
        }
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
            let pendingTerminalAgentIDs = Set(
                state.mortalityState?.pendingTransitions.map(\.agentID) ?? []
            )
            if state.mortalityState != nil, agent.health <= 0,
               !pendingTerminalAgentIDs.contains(agent.agentID) {
                throw AgentCheckpointError.invalidAgent(agent.id)
            }
            if case let .bounded(maxEntries) = state.configuration.memoryPolicy,
               agent.memory.count > maxEntries {
                throw AgentCheckpointError.invalidBound("memory for \(agent.id)")
            }
        }
        if let autonomy = state.autonomousActivityState {
            do {
                _ = try AgentAutonomousActivityConfiguration(
                    maximumCandidatesPerDecision:
                        autonomy.configuration.maximumCandidatesPerDecision,
                    maximumActiveActivities:
                        autonomy.configuration.maximumActiveActivities,
                    maximumRetainedRecords:
                        autonomy.configuration.maximumRetainedRecords,
                    maximumCooldowns: autonomy.configuration.maximumCooldowns,
                    blockedCooldownTicks: autonomy.configuration.blockedCooldownTicks
                )
            } catch {
                throw AgentCheckpointError.invalidConfiguration
            }
            let activeActors = autonomy.activeActivities.map { $0.candidate.actorID }
            let counters = autonomy.counters
            guard autonomy.activeActivities.count
                    <= autonomy.configuration.maximumActiveActivities,
                  autonomy.recentRecords.count
                    <= autonomy.configuration.maximumRetainedRecords,
                  autonomy.cooldowns.count <= autonomy.configuration.maximumCooldowns,
                  Set(activeActors).count == activeActors.count,
                  activeActors.allSatisfy(agentIDs.contains),
                  autonomy.cooldowns.allSatisfy({ agentIDs.contains($0.actorID) }),
                  counters.decisionCount >= 0, counters.candidateCount >= 0,
                  counters.startCount >= 0, counters.completionCount >= 0,
                  counters.blockCount >= 0, counters.switchCount >= 0,
                  counters.currentIdleTicks >= 0, counters.longestIdleTicks >= 0,
                  autonomy.evictionCount >= 0 else {
                throw AgentCheckpointError.invalidBound("autonomous activity")
            }
            if let sources = autonomy.productiveSourceState {
                do {
                    _ = try AgentProductiveSourceConfiguration(
                        maximumSources: sources.configuration.maximumSources,
                        maximumTransitions:
                            sources.configuration.maximumTransitions,
                        maximumObservationAgeTicks:
                            sources.configuration.maximumObservationAgeTicks
                    )
                } catch {
                    throw AgentCheckpointError.invalidConfiguration
                }
                let sourceKeys = sources.sources.map(\.sourceKey)
                guard sources.sources.count
                        <= sources.configuration.maximumSources,
                      sources.transitions.count
                        <= sources.configuration.maximumTransitions,
                      sourceKeys.count == Set(sourceKeys).count,
                      sources.sources.allSatisfy({
                          !$0.sourceKey.isEmpty
                              && !$0.materialFingerprint.isEmpty
                              && agentIDs.contains($0.observerID)
                              && $0.firstObservedTick >= 0
                              && $0.firstObservedTick <= $0.lastObservedTick
                              && $0.lastObservedTick <= state.clock.tick.rawValue + 1
                              && $0.observationCount > 0
                              && $0.renewalCount >= 0
                      }),
                      sources.transitions.allSatisfy({
                          !$0.sourceKey.isEmpty
                              && !$0.materialFingerprint.isEmpty
                              && $0.tick >= 0
                              && $0.tick <= state.clock.tick.rawValue + 1
                      }),
                      sources.counters.observationCount >= 0,
                      sources.counters.renewedCount >= 0,
                      sources.counters.physicalSuccessCount >= 0,
                      sources.evictionCount >= 0 else {
                    throw AgentCheckpointError.invalidBound(
                        "productive sources"
                    )
                }
            }
        }
        if let homeostasis = state.homeostasisState {
            try validateHomeostasisState(
                homeostasis,
                agents: state.agents,
                lifecycle: state.lifecycleState,
                autonomy: state.autonomousActivityState,
                pendingMortalityAgentIDs: Set(
                    state.mortalityState?.pendingTransitions.map(\.agentID) ?? []
                ),
                clock: state.clock,
                causalLatestSequence: state.causalLedger.latestSequence
            )
        }
        if let genetics = state.geneticsState {
            try validateGeneticsState(
                genetics,
                agents: state.agents,
                lifecycle: state.lifecycleState,
                mortality: state.mortalityState,
                clock: state.clock,
                causalLatestSequence: state.causalLedger.latestSequence,
                causalDroppedEventCount:
                    state.causalLedger.droppedEventCount,
                causalEvents: state.causalLedger.events
            )
        }
        if let family = state.familyState {
            guard let population = state.populationRegistry,
                  let lifecycle = state.lifecycleState,
                  let kinship = state.kinshipState,
                  let households = state.householdState else {
                throw AgentCheckpointError.invalidBound("family dependencies")
            }
            try validateFamilyState(
                family, population: population, lifecycle: lifecycle,
                kinship: kinship, households: households,
                agents: state.agents, mortality: state.mortalityState,
                schemaVersion: state.schemaVersion,
                clock: state.clock,
                causalLatestSequence: state.causalLedger.latestSequence,
                causalDroppedEventCount: state.causalLedger.droppedEventCount,
                causalEvents: state.causalLedger.events
            )
        }
        if let estate = state.estateState {
            guard let mortality = state.mortalityState,
                  let rights = state.materialRightsState,
                  let lifecycle = state.lifecycleState,
                  let kinship = state.kinshipState,
                  let households = state.householdState,
                  let childhood = state.dependentCareState?.childhoodV2,
                  let family = state.familyState,
                  let population = state.populationRegistry else {
                throw AgentCheckpointError.invalidBound("estate dependencies")
            }
            var activeStore = AgentStateStore()
            for agent in state.agents {
                activeStore[agent.id] = agent
            }
            try validateEstateState(
                estate,
                mortality: mortality,
                materialRights: rights,
                lifecycle: lifecycle,
                kinship: kinship,
                household: households,
                childhood: childhood,
                family: family,
                population: population,
                activeStates: activeStore,
                homeostasis: state.homeostasisState,
                causalLedger: try AgentCausalLedger(
                    restoring: state.causalLedger
                ),
                simulationID: state.clock.simulationID,
                currentTick: state.clock.tick.rawValue,
                schemaVersion: state.schemaVersion
            )
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
                expectedBlockFingerprint: $0.expectedBlockFingerprint,
                ecologyPatchID: $0.ecologyPatchID
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
        let historicalPopulationIDs = Set((0..<(state.populationRegistry?
            .nextPopulationOrdinal.rawValue ?? 0)).compactMap {
                AgentID(rawValue: "agent_\($0)")
            })
        let retainedDepartedIDs = Set(state.mortalityState?.records.map(\.agentID) ?? [])
        let departedIDs = Set((state.populationRegistry?.migrations ?? []).compactMap { migration in
            migration.failure == .memberDied ? migration.migrantID : nil
        }).union(retainedDepartedIDs).union(historicalPopulationIDs.subtracting(agentIDs))
        let knownPopulationIDs = agentIDs.union(departedIDs).union(historicalPopulationIDs)
        if let project = state.constructionProject,
           !agentIDs.contains(AgentID(rawValue: project.builderAgentId) ?? AgentID(rawValue: "invalid")!) {
            guard project.status == .blocked, project.lastFailure == .builderDied,
                  departedIDs.contains(AgentID(rawValue: project.builderAgentId)
                    ?? AgentID(rawValue: "invalid")!) else {
                throw AgentCheckpointError.invalidReference(project.builderAgentId)
            }
        }
        try validateCausalState(state.causalLedger, simulationID: state.clock.simulationID, tick: state.clock.tick)
        let pointers = state.lastPerceptionEvents + state.lastDecisionEvents
            + state.lastOutcomeEvents
        for pointer in pointers {
            guard agentIDs.contains(pointer.agentID),
                  pointer.eventID.simulationID == state.clock.simulationID,
                  pointer.eventID.sequence.rawValue <= state.causalLedger.latestSequence else {
                throw AgentCheckpointError.invalidCausalState
            }
        }
        if let constructionEventID = state.lastConstructionEventID,
           constructionEventID.simulationID != state.clock.simulationID
            || constructionEventID.sequence.rawValue > state.causalLedger.latestSequence {
            throw AgentCheckpointError.invalidCausalState
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
            let participantsActive = agentIDs.contains(task.issuerID)
                && agentIDs.contains(task.helperID)
            let participantDied = task.status.isTerminal && task.reason == "participantDied"
                && (departedIDs.contains(task.issuerID) || departedIDs.contains(task.helperID))
            guard (participantsActive || participantDied), task.requestedQuantity > 0,
                  (0...task.requestedQuantity).contains(task.contributedQuantity) else {
                throw AgentCheckpointError.invalidReference(task.taskID.rawValue)
            }
        }
        if let populationRegistry = state.populationRegistry {
            try validatePopulationRegistry(
                populationRegistry,
                agents: state.agents,
                clock: state.clock,
                departedAgentIDs: departedIDs
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
        if let ecology = state.localEcologyState {
            do {
                _ = try AgentLocalEcologyConfiguration(
                    maximumPatches: ecology.configuration.maximumPatches,
                    maximumHabitatCandidates: ecology.configuration.maximumHabitatCandidates,
                    observationRadius: ecology.configuration.observationRadius,
                    patchCapacity: ecology.configuration.patchCapacity,
                    initialYield: ecology.configuration.initialYield,
                    regenerationIntervalTicks: ecology.configuration.regenerationIntervalTicks,
                    regenerationQuantity: ecology.configuration.regenerationQuantity,
                    maximumForageIntentsPerTick: ecology.configuration.maximumForageIntentsPerTick,
                    maximumForageHistory: ecology.configuration.maximumForageHistory,
                    maximumPressureFrames: ecology.configuration.maximumPressureFrames,
                    maximumHabitatReadsPerScan: ecology.configuration.maximumHabitatReadsPerScan
                )
            } catch {
                throw AgentCheckpointError.invalidConfiguration
            }
            let patchIDs = ecology.patches.map(\.patchID)
            let forageIDs = ecology.processedForageIDs
            let initial = ecology.patches.reduce(0) { $0 + $1.initialYield }
            let regenerated = ecology.patches.reduce(0) { $0 + $1.regeneratedTotal }
            let current = ecology.patches.reduce(0) { $0 + $1.currentYield }
            let harvested = ecology.patches.reduce(0) { $0 + $1.harvestedTotal }
            guard ecology.settlementID == state.populationRegistry?.settlement.settlementID,
                  !ecology.patches.isEmpty,
                  ecology.patches.count <= ecology.configuration.maximumPatches,
                  patchIDs == patchIDs.sorted(),
                  patchIDs.count == Set(patchIDs).count,
                  forageIDs.count == Set(forageIDs).count,
                  forageIDs.count <= ecology.configuration.maximumForageHistory,
                  ecology.forageHistory.count <= ecology.configuration.maximumForageHistory,
                  ecology.pressureFrames.count <= ecology.configuration.maximumPressureFrames,
                  ecology.pressureFrames.map(\.sequence)
                    == ecology.pressureFrames.map(\.sequence).sorted(),
                  ecology.pressureSequence >= (ecology.pressureFrames.last?.sequence ?? 0),
                  ecology.evictionCounts.forageHistory >= 0,
                  ecology.evictionCounts.pressureFrames >= 0,
                  ecology.initializedEventID.simulationID == state.clock.simulationID,
                  ecology.lastEcologyEventID.simulationID == state.clock.simulationID,
                  ecology.lastEcologyEventID.sequence.rawValue <= state.causalLedger.latestSequence,
                  ecology.patches.allSatisfy({ patch in
                      patch.settlementID == ecology.settlementID
                          && (0...patch.capacity).contains(patch.currentYield)
                          && patch.capacity == ecology.configuration.patchCapacity
                          && patch.initialYield == ecology.configuration.initialYield
                          && patch.regeneratedTotal >= 0 && patch.harvestedTotal >= 0
                          && patch.registeredTick >= 0 && patch.registeredTick <= state.clock.tick.rawValue
                          && patch.lastRegenerationTick >= patch.registeredTick
                          && patch.lastRegenerationTick <= state.clock.tick.rawValue
                          && patch.registrationEventID.simulationID == state.clock.simulationID
                          && patch.lastEcologyEventID.simulationID == state.clock.simulationID
                  }),
                  initial + regenerated == current + harvested else {
                throw AgentCheckpointError.invalidBound("local ecology")
            }
        }
        if let mortality = state.mortalityState {
            do {
                _ = try AgentMortalityConfiguration(
                    maximumDeathsPerTick: mortality.configuration.maximumDeathsPerTick,
                    maximumRetainedDeathRecords:
                        mortality.configuration.maximumRetainedDeathRecords,
                    maximumCompactedDeathSummaries:
                        mortality.configuration
                            .maximumCompactedDeathSummaries,
                    maximumFinalMemoryEntries:
                        mortality.configuration.maximumFinalMemoryEntries,
                    maximumCancelledCommitmentIDsPerDeath:
                        mortality.configuration.maximumCancelledCommitmentIDsPerDeath,
                    maximumExitFrames: mortality.configuration.maximumExitFrames,
                    maximumMaterialExitsPerDeath:
                        mortality.configuration.maximumMaterialExitsPerDeath,
                    requiresTerminalPhysicalCustodyVerification:
                        mortality.configuration
                            .requiresTerminalPhysicalCustodyVerification
                )
            } catch {
                throw AgentCheckpointError.invalidConfiguration
            }
            let recordIDs = mortality.records.map(\.deathID)
            let recordAgents = mortality.records.map(\.agentID)
            let processed = mortality.processedDeathIDs
            let pendingAgents = mortality.pendingTransitions.map(\.agentID)
            guard mortality.records.count
                    <= mortality.configuration.maximumRetainedDeathRecords,
                  mortality.pendingTransitions.count
                    <= mortality.configuration.maximumDeathsPerTick,
                  pendingAgents.count == Set(pendingAgents).count,
                  Set(pendingAgents).isSubset(of: agentIDs),
                  mortality.exitFrames.count <= mortality.configuration.maximumExitFrames,
                  mortality.totalDeathCount >= mortality.records.count,
                  mortality.totalDeathCount
                    == mortality.records.count + mortality.evictionCounts.deathRecords,
                  recordIDs.count == Set(recordIDs).count,
                  recordAgents.count == Set(recordAgents).count,
                  processed.count == Set(processed).count,
                  Set(recordIDs).isSubset(of: Set(processed)),
                  recordAgents.allSatisfy({ !agentIDs.contains($0) }),
                  mortality.records == mortality.records.sorted(by: {
                      if $0.deathTick != $1.deathTick { return $0.deathTick < $1.deathTick }
                      if $0.agentID != $1.agentID { return $0.agentID < $1.agentID }
                      return $0.deathID < $1.deathID
                  }),
                  mortality.records.allSatisfy({ record in
                      var validCause: Bool
                      if record.cause == .starvation {
                          validCause = record.finalVitalStatus == nil
                              || record.finalVitalStatus == .dead
                          validCause = validCause
                              && record.terminalPhysiologyEventID == nil
                      } else {
                          validCause = state.schemaVersion
                                  >= AgentCheckpointSchema.homeostasisVersion
                              && record.finalVitalStatus == .dead
                              && record.finalHomeostasis?.vitalStatus == .dead
                              && record.finalHomeostasis?.condition == .dead
                              && record.terminalPhysiologyEventID != nil
                              && (record.demographicAgeTicks ?? -1) >= 0
                              && record.lifeStage != nil
                      }
                      return validCause && record.finalHealth == 0
                          && record.healthBeforeLethalDamage > 0
                          && record.deathTick <= state.clock.tick.rawValue
                          && record.terminalActivity.ticksAlive == record.ticksAlive
                          && record.terminalActivity.lastGoal == record.lastGoal
                          && record.terminalActivity.lastAction == record.lastAction
                          && [
                              record.terminalActivity.observationCount,
                              record.terminalActivity.nearbyObservationCount,
                              record.terminalActivity.goalSelectionCount,
                              record.terminalActivity.goalChangeCount,
                              record.terminalActivity.actionCount,
                              record.terminalActivity.actionEffectCount,
                              record.terminalActivity.movementCount,
                              record.terminalActivity.totalManhattanDistanceMoved,
                              record.terminalActivity.returnHomeMoveCount,
                              record.terminalActivity.foodConsumedCount,
                              record.terminalActivity.ticksAlive,
                          ].allSatisfy({ $0 >= 0 })
                          && record.finalMemory.count
                            <= mortality.configuration.maximumFinalMemoryEntries
                          && record.cancelledCommitmentIDs.count
                            <= mortality.configuration.maximumCancelledCommitmentIDsPerDeath
                          && record.deathEventID.simulationID == state.clock.simulationID
                          && record.populationExitEventID.simulationID == state.clock.simulationID
                          && record.materialExitEventIDs.count
                            <= mortality.configuration.maximumMaterialExitsPerDeath
                          && record.materialExitEventIDs
                            == record.materialExitEventIDs.sorted()
                          && (record.pendingMaterialExitEventID != nil
                            || (record.materialExitEventIDs.isEmpty
                                && record.physicalCustodyResolution == nil))
                          && (record.physicalCustodyResolution == nil
                            || record.pendingMaterialExitEventID != nil)
                          && (!mortality.configuration
                                .requiresTerminalPhysicalCustodyVerification
                            || record.physicalCustodyResolution != nil)
                          && record.physicalCustodyResolution.map {
                              $0.verifiedAtTick == record.deathTick
                                  && (0...mortality.configuration
                                    .maximumMaterialExitsPerDeath)
                                    .contains($0.stackCount)
                                  && $0.itemCount >= $0.stackCount
                                  && $0.eventID.simulationID
                                    == state.clock.simulationID
                                  && (($0.kind == .verifiedEmpty
                                        && $0.stackCount == 0
                                        && $0.itemCount == 0
                                        && $0.destinationHolderID == nil)
                                    || ($0.kind == .transferred
                                        && $0.stackCount > 0
                                        && $0.itemCount > 0
                                        && ($0.destinationHolderID?
                                            .hasPrefix("container:") == true)))
                          } ?? true
                  }),
                  mortality.evictionCounts.deathRecords >= 0,
                  mortality.evictionCounts.exitFrames >= 0,
                  mortality.unrecoveredAtDeath.capacity == 4096,
                  mortality.terminalStarvationDamageTotal >= 0,
                  !mortality.rollingDigest.isEmpty,
                  mortality.initializedEventID.simulationID == state.clock.simulationID,
                  mortality.lastMortalityEventID.simulationID == state.clock.simulationID,
                  mortality.lastMortalityEventID.sequence.rawValue
                    <= state.causalLedger.latestSequence else {
                throw AgentCheckpointError.invalidBound("mortality")
            }
            let summaries = mortality.compactedDeathSummaries ?? []
            if state.schemaVersion == AgentCheckpointSchema.estateVersion
                || state.schemaVersion
                    == AgentCheckpointSchema.renewableSubsistenceVersion
                || state.schemaVersion
                    == AgentCheckpointSchema
                        .independentEcologicalReceiptVersion {
                guard mortality.historicalEvidenceVersion
                        == AgentCompactedDeathSummary.currentVersion,
                      mortality.compactedDeathSummaries != nil else {
                    throw AgentCheckpointError.invalidBound(
                        "mortality historical evidence"
                    )
                }
            }
            if mortality.historicalEvidenceVersion != nil
                || mortality.compactedDeathSummaries != nil {
                let summaryDeathIDs = summaries.map(\.deathID)
                let summaryAgentIDs = summaries.map(\.agentID)
                let retainedDeathIDs = Set(recordIDs)
                let retainedAgentIDs = Set(recordAgents)
                guard mortality.historicalEvidenceVersion
                        == AgentCompactedDeathSummary.currentVersion,
                      summaries.count
                        == mortality.evictionCounts.deathRecords,
                      summaries.count
                        <= mortality.configuration
                            .maximumCompactedDeathSummaries,
                      summaries.map(\.deathOrdinal)
                        == summaries.indices.map({ $0 + 1 }),
                      summaryDeathIDs.count == Set(summaryDeathIDs).count,
                      summaryAgentIDs.count == Set(summaryAgentIDs).count,
                      retainedDeathIDs.isDisjoint(with: summaryDeathIDs),
                      retainedAgentIDs.isDisjoint(with: summaryAgentIDs),
                      summaryAgentIDs.allSatisfy({ !agentIDs.contains($0) })
                else {
                    throw AgentCheckpointError.invalidBound(
                        "compacted death summaries"
                    )
                }
                if let kinship = state.kinshipState {
                    let known = Set(kinship.historicalPersons.map(\.agentID))
                    guard summaries.count
                            <= kinship.configuration.maximumHistoricalPersons,
                          Set(summaryAgentIDs).isSubset(of: known) else {
                        throw AgentCheckpointError.invalidBound(
                            "compacted death identities"
                        )
                    }
                }
                for summary in summaries {
                    let deathDigest = AgentMortalityDigest.make(
                        "\(state.clock.simulationID.rawValue)|"
                            + "\(summary.agentID.rawValue)|"
                            + "\(summary.deathTick)|"
                            + "\(summary.cause.rawValue)|"
                            + "\(summary.deathOrdinal)"
                    )
                    let expectedDeathID = AgentDeathID(
                        rawValue: "death-\(summary.agentID.rawValue)-"
                            + "t\(summary.deathTick)-\(deathDigest)"
                    )!
                    let expectedEvidenceDigest =
                        AgentCompactedDeathSummary.digest(
                            version: summary.version,
                            deathOrdinal: summary.deathOrdinal,
                            agentID: summary.agentID,
                            deathID: summary.deathID,
                            cause: summary.cause,
                            deathTick: summary.deathTick,
                            demographicAgeTicks:
                                summary.demographicAgeTicks,
                            lifeStageAtDeath: summary.lifeStageAtDeath,
                            deathEventID: summary.deathEventID,
                            finalStateDigest: summary.finalStateDigest
                        )
                    guard summary.version
                            == AgentCompactedDeathSummary.currentVersion,
                          summary.deathID == expectedDeathID,
                          summary.deathTick <= state.clock.tick.rawValue,
                          (summary.demographicAgeTicks ?? 0) >= 0,
                          summary.deathEventID.simulationID
                            == state.clock.simulationID,
                          !summary.finalStateDigest.isEmpty,
                          summary.evidenceDigest == expectedEvidenceDigest
                    else {
                        throw AgentCheckpointError.invalidBound(
                            "compacted death evidence"
                        )
                    }
                    if let age = summary.demographicAgeTicks,
                       let stage = summary.lifeStageAtDeath,
                       let lifecycle = state.lifecycleState {
                        let expectedStage: AgentLifeStage
                        if age
                            >= lifecycle.configuration.maturityAgeTicks {
                            expectedStage = .mature
                        } else if age >= lifecycle.configuration
                            .newbornDurationTicks {
                            expectedStage = .juvenile
                        } else {
                            expectedStage = .newborn
                        }
                        guard stage == expectedStage else {
                            throw AgentCheckpointError.invalidBound(
                                "compacted death life stage"
                            )
                        }
                    }
                    if let event = state.causalLedger.events.first(where: {
                        $0.eventID == summary.deathEventID
                    }) {
                        guard event.kind == .agentDeathFinalized,
                              event.origin == .mortalityTransition,
                              event.actorID == summary.agentID,
                              event.subjectID == summary.agentID,
                              event.simulationTick.rawValue
                                == summary.deathTick else {
                            throw AgentCheckpointError.invalidBound(
                                "compacted death causal binding"
                            )
                        }
                    }
                }
                if state.estateState != nil {
                    guard summaries.allSatisfy({
                        $0.demographicAgeTicks != nil
                            && $0.lifeStageAtDeath != nil
                    }) else {
                        throw AgentCheckpointError.invalidBound(
                            "estate historical demographics"
                        )
                    }
                }
            }
            for pending in mortality.pendingTransitions {
                let required = pending.requiredMaterialAssetIDs
                let resolved = pending.resolvedMaterialAssetIDs
                let unresolved = pending.unresolvedMaterialAssetIDs
                let rights = state.materialRightsState?.records ?? []
                let pendingEvent = state.causalLedger.events.first {
                    $0.eventID == pending.pendingEventID
                }
                let terminalEvent = pending.terminalPhysiologyEventID.flatMap { id in
                    state.causalLedger.events.first { $0.eventID == id }
                }
                let physicalEvent = pending.physicalCustodyResolution.flatMap {
                    resolution in
                    state.causalLedger.events.first {
                        $0.eventID == resolution.eventID
                    }
                }
                guard pending.detectedAtTick == state.clock.tick.rawValue,
                      pending.healthBeforeLethalDamage > 0,
                      (required.count > 0
                        || mortality.configuration
                            .requiresTerminalPhysicalCustodyVerification),
                      required.count
                        <= mortality.configuration.maximumMaterialExitsPerDeath,
                      required == required.sorted(),
                      required.count == Set(required).count,
                      resolved == resolved.sorted(),
                      resolved.count == Set(resolved).count,
                      Set(resolved).isSubset(of: Set(required)),
                      pending.materialExitEventIDs.count == resolved.count,
                      pending.materialExitEventIDs
                        == pending.materialExitEventIDs.sorted(),
                      pending.materialExitEventIDs.enumerated().allSatisfy({
                          index, eventID in
                          guard let event = state.causalLedger.events.first(
                              where: { $0.eventID == eventID }
                          ) else { return false }
                          let expected = Array(Set([
                              pending.pendingEventID,
                              index > 0
                                ? pending.materialExitEventIDs[index - 1] : nil,
                          ].compactMap { $0 })).sorted()
                          return event.kind == .materialPhysicalCustodyObserved
                              && event.actorID == pending.agentID
                              && event.causes == expected
                      }),
                      pendingEvent?.kind == .mortalityMaterialExitPending,
                      pendingEvent?.actorID == pending.agentID,
                      pendingEvent?.subjectID == pending.agentID,
                      pendingEvent?.simulationTick.rawValue == pending.detectedAtTick,
                      (pending.physicalCustodyResolution.map { resolution in
                          let expectedCauses = Array(Set(
                              [pending.pendingEventID]
                                + pending.materialExitEventIDs.suffix(1)
                          )).sorted()
                          return unresolved.isEmpty
                              && required == resolved
                              && resolution.verifiedAtTick
                                  == pending.detectedAtTick
                              && (0...mortality.configuration
                                .maximumMaterialExitsPerDeath)
                                .contains(resolution.stackCount)
                              && resolution.itemCount >= resolution.stackCount
                              && resolution.eventID.simulationID
                                == state.clock.simulationID
                              && physicalEvent?.kind
                                == .mortalityPhysicalCustodyResolved
                              && physicalEvent?.actorID == pending.agentID
                              && physicalEvent?.subjectID == pending.agentID
                              && physicalEvent?.simulationTick.rawValue
                                == pending.detectedAtTick
                              && physicalEvent?.causes == expectedCauses
                              && ((resolution.kind == .verifiedEmpty
                                    && resolution.stackCount == 0
                                    && resolution.itemCount == 0
                                    && resolution.destinationHolderID == nil)
                                || (resolution.kind == .transferred
                                    && resolution.stackCount > 0
                                    && resolution.itemCount > 0
                                    && (resolution.destinationHolderID?
                                        .hasPrefix("container:") == true)))
                      } ?? true),
                      state.agents.first(where: {
                          $0.agentID == pending.agentID
                      })?.health == 0,
                      unresolved.allSatisfy({ assetID in
                          rights.contains(where: {
                              $0.asset.assetID == assetID
                                  && $0.lastVerifiedHolder.holder
                                      == .agent(pending.agentID)
                          })
                      }),
                      resolved.allSatisfy({ assetID in
                          rights.contains(where: {
                              $0.asset.assetID == assetID
                                  && $0.lastVerifiedHolder.holder
                                      != .agent(pending.agentID)
                          })
                      }) else {
                    throw AgentCheckpointError.invalidBound(
                        "pending mortality material exit"
                    )
                }
                if state.homeostasisState != nil {
                    guard pending.cause != .starvation,
                          terminalEvent?.kind == .homeostasisChanged,
                          terminalEvent?.actorID == pending.agentID,
                          terminalEvent?.subjectID == pending.agentID,
                          terminalEvent?.simulationTick.rawValue
                            == pending.detectedAtTick,
                          pendingEvent?.causes.contains(
                              pending.terminalPhysiologyEventID!
                          ) == true else {
                        throw AgentCheckpointError.invalidBound(
                            "pending mortality physiology"
                        )
                    }
                } else if pending.terminalPhysiologyEventID != nil {
                    throw AgentCheckpointError.invalidBound(
                        "legacy pending mortality physiology"
                    )
                }
            }
            for record in mortality.records {
                let event: (AgentCausalEventID) -> AgentCausalEvent? = { eventID in
                    state.causalLedger.events.first { $0.eventID == eventID }
                }
                let mortalityEventIDs = [
                    record.lethalDamageEventID,
                    record.resourcesRetiredEventID,
                    record.commitmentsResolvedEventID,
                    record.populationExitEventID,
                    record.deathEventID,
                ]
                let retained = mortalityEventIDs.compactMap(event)
                if retained.count != mortalityEventIDs.count {
                    guard state.causalLedger.droppedEventCount > 0,
                          let firstRetained = state.causalLedger.events.first?.sequence,
                          zip(mortalityEventIDs, mortalityEventIDs.map(event)).allSatisfy({
                              $0.1 != nil || $0.0.sequence < firstRetained
                          }) else {
                        throw AgentCheckpointError.invalidBound("mortality causal chain")
                    }
                    continue
                }
                let lethal = retained[0]
                let resources = retained[1]
                let commitments = retained[2]
                let exit = retained[3]
                let finalized = retained[4]
                let terminalPhysiology = record.terminalPhysiologyEventID.flatMap(event)
                let pendingMaterialExit = record.pendingMaterialExitEventID.flatMap(event)
                let materialExits = record.materialExitEventIDs.compactMap(event)
                let physicalResolution = record.physicalCustodyResolution
                    .flatMap { event($0.eventID) }
                let estateOpeningID = state.estateState?.estates.first {
                    $0.deathID == record.deathID
                }?.openingEventID
                let estateOpening = estateOpeningID.flatMap(event)
                let migrationFailure = state.causalLedger.events.first {
                    $0.kind == .migrationFailed && $0.actorID == record.agentID
                        && $0.sequence > commitments.sequence && $0.sequence < exit.sequence
                }
                let careExit = exit.causes.compactMap { causeID in
                    event(causeID)
                }.filter {
                    $0.origin == .dependentCareTransition
                }.map(\.eventID).max()
                let householdPeriod = state.householdState?.membershipPeriods.first {
                    $0.agentID == record.agentID
                        && $0.leftTick == record.deathTick
                        && $0.leftReason == .death
                }
                let householdRecord = householdPeriod.flatMap { period in
                    state.householdState?.households.first {
                        $0.householdID == period.householdID
                    }
                }
                let householdExit = householdRecord.flatMap { household in
                    household.dissolvedTick == record.deathTick
                        && household.lastHouseholdEventID.sequence < exit.sequence
                        ? household.lastHouseholdEventID : householdPeriod?.leftEventID
                } ?? householdPeriod?.leftEventID
                let familyExit = ([
                    state.familyState?.unions.compactMap { union in
                        union.terminationReason == .partnerDeath
                            && union.partnerIDs.contains(record.agentID)
                            && union.terminationTick == record.deathTick
                            ? union.terminationEventID : nil
                    }.max(),
                    state.familyState?.houseMembershipPeriods.compactMap {
                        period in
                        period.agentID == record.agentID
                            && period.endReason == .memberDeath
                            && period.leftTick == record.deathTick
                            ? period.leftEventID : nil
                    }.max(),
                ].compactMap { $0 }).max()
                if let terminalID = record.terminalPhysiologyEventID {
                    guard lethal.causes.contains(terminalID),
                          terminalPhysiology.map({
                              $0.kind == .homeostasisChanged
                                  && $0.actorID == record.agentID
                                  && $0.subjectID == record.agentID
                                  && $0.simulationTick.rawValue == record.deathTick
                          }) ?? (state.causalLedger.droppedEventCount > 0) else {
                        throw AgentCheckpointError.invalidBound(
                            "mortality terminal physiology cause"
                        )
                    }
                }
                if let pendingID = record.pendingMaterialExitEventID {
                    let expectedLethalCauses = Array(Set([
                        record.terminalPhysiologyEventID,
                        pendingID,
                        record.materialExitEventIDs.last,
                        record.physicalCustodyResolution?.eventID,
                    ].compactMap { $0 })).sorted()
                    guard pendingMaterialExit.map({ pendingEvent in
                        pendingEvent.kind == .mortalityMaterialExitPending
                            && pendingEvent.actorID == record.agentID
                            && pendingEvent.subjectID == record.agentID
                            && pendingEvent.simulationTick.rawValue == record.deathTick
                            && (record.terminalPhysiologyEventID.map { terminalID in
                                pendingEvent.causes.contains(terminalID)
                            } ?? true)
                    }) ?? (state.causalLedger.droppedEventCount > 0),
                          lethal.causes == expectedLethalCauses,
                          materialExits.count == record.materialExitEventIDs.count
                              || state.causalLedger.droppedEventCount > 0 else {
                        throw AgentCheckpointError.invalidBound(
                            "mortality material exit chain"
                        )
                    }
                    for (index, eventID) in record.materialExitEventIDs.enumerated() {
                        guard let materialEvent = event(eventID) else { continue }
                        let expectedCauses = Array(Set([
                            pendingID,
                            index > 0 ? record.materialExitEventIDs[index - 1] : nil,
                        ].compactMap { $0 })).sorted()
                        guard materialEvent.kind == .materialPhysicalCustodyObserved,
                              materialEvent.actorID == record.agentID,
                              materialEvent.causes == expectedCauses else {
                            throw AgentCheckpointError.invalidBound(
                                "mortality material exit event"
                            )
                        }
                    }
                    if let resolution = record.physicalCustodyResolution {
                        let expectedCauses = Array(Set(
                            [pendingID] + record.materialExitEventIDs.suffix(1)
                        )).sorted()
                        guard physicalResolution.map({
                            $0.kind == .mortalityPhysicalCustodyResolved
                                && $0.actorID == record.agentID
                                && $0.subjectID == record.agentID
                                && $0.simulationTick.rawValue == record.deathTick
                                && $0.causes == expectedCauses
                        }) ?? (state.causalLedger.droppedEventCount > 0),
                              lethal.causes.contains(resolution.eventID) else {
                            throw AgentCheckpointError.invalidBound(
                                "mortality physical custody resolution"
                            )
                        }
                    } else if mortality.configuration
                        .requiresTerminalPhysicalCustodyVerification {
                        throw AgentCheckpointError.invalidBound(
                            "mortality physical custody missing"
                        )
                    }
                }
                guard
                      [lethal.kind, resources.kind, commitments.kind, exit.kind, finalized.kind]
                        == [
                            .lethalHealthDepletion,
                            .mortalityResourcesRetired,
                            .mortalityCommitmentsResolved,
                            .populationMemberExited,
                            .agentDeathFinalized,
                        ],
                      lethal.actorID == record.agentID,
                      lethal.subjectID == record.agentID,
                      resources.causes == [lethal.eventID],
                      commitments.causes == (
                        [lethal.eventID]
                            + (estateSchema
                                ? [estateOpeningID].compactMap { $0 }
                                : [])
                      ).sorted(),
                      exit.causes == [
                          lethal.eventID,
                          resources.eventID,
                          commitments.eventID,
                          migrationFailure?.eventID,
                          careExit,
                          familyExit,
                          householdExit,
                      ].compactMap({ $0 }).sorted(),
                      finalized.causes == [exit.eventID],
                      lethal.sequence < resources.sequence,
                      resources.sequence < commitments.sequence,
                      (estateOpening == nil
                        || estateOpening!.sequence < commitments.sequence),
                      commitments.sequence < exit.sequence,
                      exit.sequence < finalized.sequence,
                      !state.causalLedger.events.contains(where: {
                          $0.sequence > finalized.sequence && $0.kind.isMortality
                              && ($0.actorID == record.agentID || $0.subjectID == record.agentID)
                      }) else {
                    throw AgentCheckpointError.invalidBound("mortality causal chain")
                }
            }
        }
        if let lifecycle = state.lifecycleState, let population = state.populationRegistry {
            try validateLifecycleState(
                lifecycle,
                population: population,
                agents: state.agents,
                clock: state.clock,
                causalLatestSequence: state.causalLedger.latestSequence
            )
        }
        if let kinship = state.kinshipState, let population = state.populationRegistry,
           let lifecycle = state.lifecycleState {
            do {
                try validateKinshipState(
                    kinship,
                    population: population,
                    lifecycle: lifecycle,
                    clock: state.clock,
                    causalLatestSequence: state.causalLedger.latestSequence,
                    causalDroppedEventCount: state.causalLedger.droppedEventCount,
                    causalEvents: state.causalLedger.events
                )
            } catch {
                throw AgentCheckpointError.invalidBound("kinship")
            }
        }
        if let household = state.householdState, let population = state.populationRegistry,
           let kinship = state.kinshipState {
            do {
                try validateHouseholdState(
                    household,
                    population: population,
                    agents: state.agents,
                    kinship: kinship,
                    clock: state.clock,
                    causalLatestSequence: state.causalLedger.latestSequence,
                    causalDroppedEventCount: state.causalLedger.droppedEventCount,
                    causalEvents: state.causalLedger.events
                )
            } catch {
                throw AgentCheckpointError.invalidBound("household")
            }
        }
        if let care = state.dependentCareState,
           let population = state.populationRegistry,
           let lifecycle = state.lifecycleState,
           let kinship = state.kinshipState,
           let households = state.householdState {
            do {
                if state.schemaVersion
                    == AgentCheckpointSchema.childhoodVersion {
                    guard care.activeEngagements.allSatisfy({
                        $0.verifiedEngagedTicks == 0
                            && $0.lastVerifiedTick == nil
                            && $0.lastEvaluatedTick == nil
                            && $0.lastVerifiedCaregiverPosition == nil
                            && $0.lastVerifiedDependentPosition == nil
                            && $0.interruptedTicks == 0
                            && $0.lastInterruptedTick == nil
                    }) else {
                        throw AgentDependentCareError.invalidState(
                            "schema 23 supervision progress"
                        )
                    }
                }
                try validateDependentCareState(
                    care, population: population, lifecycle: lifecycle,
                    kinship: kinship, households: households,
                    mortality: state.mortalityState,
                    homeostasis: state.homeostasisState,
                    agents: state.agents,
                    clock: state.clock,
                    causalLatestSequence: state.causalLedger.latestSequence,
                    causalDroppedEventCount: state.causalLedger.droppedEventCount,
                    causalEvents: state.causalLedger.events
                )
            } catch {
                throw AgentCheckpointError.invalidBound("dependent care")
            }
        }
        if let skills = state.skillState,
           let population = state.populationRegistry,
           let lifecycle = state.lifecycleState {
            do {
                var historicalIDs = Set(state.agents.map(\.agentID))
                historicalIDs.formUnion(lifecycle.members.map(\.agentID))
                historicalIDs.formUnion(
                    state.kinshipState?.historicalPersons.map(\.agentID) ?? []
                )
                historicalIDs.formUnion(
                    state.mortalityState?.records.map(\.agentID) ?? []
                )
                try validateSkillState(
                    skills, population: population, lifecycle: lifecycle,
                    historicalAgentIDs: historicalIDs, clock: state.clock,
                    causalLatestSequence: state.causalLedger.latestSequence,
                    causalDroppedEventCount: state.causalLedger.droppedEventCount,
                    causalEvents: state.causalLedger.events
                )
            } catch {
                throw AgentCheckpointError.invalidBound("skills")
            }
        }
        if let teaching = state.teachingState {
            do {
                var historicalIDs = Set(state.agents.map(\.agentID))
                historicalIDs.formUnion(state.lifecycleState?.members.map(\.agentID) ?? [])
                historicalIDs.formUnion(
                    state.kinshipState?.historicalPersons.map(\.agentID) ?? []
                )
                historicalIDs.formUnion(
                    state.mortalityState?.records.map(\.agentID) ?? []
                )
                try validateTeachingState(
                    teaching, historicalAgentIDs: historicalIDs,
                    activeAgentIDs: Set(state.agents.map(\.agentID)), clock: state.clock,
                    physicalConfiguration: state.configuration.physicalChannelConfiguration,
                    causalLatestSequence: state.causalLedger.latestSequence,
                    causalDroppedEventCount: state.causalLedger.droppedEventCount,
                    causalEvents: state.causalLedger.events
                )
            } catch {
                throw AgentCheckpointError.invalidBound("teaching")
            }
        }
        if let observations = state.ecologicalObservationState {
            do {
                if independentReceiptSchema {
                    let receiptIDs = observations.observations.compactMap(
                        \.physicalObservationReceiptID
                    )
                    guard receiptIDs.count == observations.observations.count,
                          receiptIDs.count == Set(receiptIDs).count else {
                        throw AgentEcologicalObservationError.invalidState(
                            "schema 30 physical receipt reference"
                        )
                    }
                } else {
                    guard observations.observations.isEmpty else {
                        throw AgentEcologicalObservationError.invalidState(
                            "legacy schema lacks independent physical receipt"
                        )
                    }
                }
                _ = try validateEcologicalObservationState(
                    observations,
                    activeAgents: state.agents,
                    population: state.populationRegistry,
                    mortality: state.mortalityState,
                    agriculture: state.agricultureState,
                    clock: state.clock,
                    causalLatestSequence: state.causalLedger.latestSequence,
                    causalDroppedEventCount:
                        state.causalLedger.droppedEventCount,
                    causalEvents: state.causalLedger.events
                )
            } catch {
                throw AgentCheckpointError.invalidBound("ecological observation")
            }
        }
        if let agriculture = state.agricultureState {
            do {
                if independentReceiptSchema {
                    guard agriculture.plots.allSatisfy({
                        $0.sourceObservationReceiptID != nil
                            && ($0.renewalEvidence == nil
                                || $0.renewalEvidence?
                                    .sourceObservationReceiptID != nil)
                    }) else {
                        throw AgentAgricultureError.invalidState(
                            "schema 30 source observation receipt"
                        )
                    }
                } else {
                    guard agriculture.plots.isEmpty else {
                        throw AgentAgricultureError.invalidState(
                            "legacy schema lacks physical foundation receipt"
                        )
                    }
                }
                try validateAgricultureState(
                    agriculture,
                    activeAgents: state.agents,
                    population: state.populationRegistry,
                    mortality: state.mortalityState,
                    clock: state.clock,
                    causalLatestSequence: state.causalLedger.latestSequence,
                    causalDroppedEventCount: state.causalLedger.droppedEventCount,
                    causalEvents: state.causalLedger.events
                )
            } catch {
                throw AgentCheckpointError.invalidBound("agriculture")
            }
        }
        if let wildSubsistence = state.wildSubsistenceState {
            do {
                try validateWildSubsistenceState(
                    wildSubsistence,
                    agents: Set(state.agents.map(\.agentID)),
                    clock: state.clock,
                    causalLatestSequence: state.causalLedger.latestSequence,
                    causalDroppedEventCount: state.causalLedger.droppedEventCount,
                    causalEvents: state.causalLedger.events
                )
            } catch {
                throw AgentCheckpointError.invalidBound("wild subsistence")
            }
        }
        if let livestock = state.livestockState {
            guard livestock.herds.count <= livestock.configuration.maximumHerds,
                  livestock.activeTasks.count <= livestock.configuration.maximumActiveTasks,
                  livestock.reservations.count <= livestock.configuration.maximumReservations,
                  Set(livestock.herds.map(\.herdID)).count == livestock.herds.count,
                  Set(livestock.managedAnimals.map(\.recordID)).count == livestock.managedAnimals.count,
                  Set(livestock.activeTasks.map(\.taskID)).count == livestock.activeTasks.count,
                  Set(livestock.processedActionIDs).count == livestock.processedActionIDs.count else {
                throw AgentCheckpointError.invalidBound("livestock")
            }
        }
        if let work = state.workCommitmentState {
            guard work.demands.filter(\.status.isActive).count
                    <= work.configuration.maximumActiveDemands,
                  work.commitments.count <= work.configuration.maximumRetainedCommitments,
                  work.retainedEvidence.count <= work.configuration.maximumRetainedEvidence,
                  work.localReputations.count <= work.configuration.maximumReputationEntries,
                  Set(work.demands.map(\.demandID)).count == work.demands.count,
                  Set(work.commitments.map(\.commitmentID)).count == work.commitments.count,
                  Set(work.retainedEvidence.map(\.sourceEventID)).count
                    == work.retainedEvidence.count,
                  work.totalEvidenceCount
                    == work.retainedEvidence.count + work.evictionCounts.evidence else {
                throw AgentCheckpointError.invalidBound("work commitments")
            }
        }
        for relation in state.socialTrustRelations {
            guard knownPopulationIDs.contains(relation.sourceID),
                  knownPopulationIDs.contains(relation.targetID),
                  relation.score >= state.configuration.socialConfiguration.minimumTrust,
                  relation.score <= state.configuration.socialConfiguration.maximumTrust else {
                throw AgentCheckpointError.invalidReference(relation.relationID.rawValue)
            }
        }
        for relation in state.cooperationRelations {
            guard knownPopulationIDs.contains(relation.issuerID),
                  knownPopulationIDs.contains(relation.helperID),
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
