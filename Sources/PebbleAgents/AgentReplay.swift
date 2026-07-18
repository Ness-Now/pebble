import Foundation

public enum AgentReplaySchema {
    public static let currentVersion = 1
    public static let populationVersion = 2
    public static let settlementMetricsVersion = 3
    public static let localEcologyVersion = 4
    public static let mortalityVersion = 5
    public static let lifecycleVersion = 6
    public static let kinshipVersion = 7
    public static let householdVersion = 8

    public static func supports(_ version: Int) -> Bool {
        version == currentVersion || version == populationVersion
            || version == settlementMetricsVersion || version == localEcologyVersion
            || version == mortalityVersion || version == lifecycleVersion
            || version == kinshipVersion || version == householdVersion
    }
}

public struct AgentReplayRecordSequence: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: UInt64

    public init?(rawValue: UInt64) {
        guard rawValue > 0 else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentReplayRecordSequence, rhs: AgentReplayRecordSequence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentReplayOperationKind: String, Codable, CaseIterable, Sendable {
    case advanceTick
    case externalUpdate
    case movementOutcomes
    case interactionOutcome
    case deliveryOutcome
    case consumptionOutcome
    case economyFeature
    case naturalResourcesFeature
    case survivalFeature
    case constructionFeature
    case socialFeature
    case physicalFeature
    case cooperationFeature
    case constructionProjectCreation
    case constructionFunding
    case constructionPlacement
    case constructionFailure
    case constructionCompletion
    case constructionClear
    case socialVerification
    case socialClear
    case physicalPresentationClaim
    case physicalClear
    case cooperationClear
    case populationFeature
    case populationRegistryInitialization
    case migrationAdmission
    case populationClear
    case settlementMetricsFeature
    case settlementMetricsClear
    case settlementPulseBoundary
    case localEcologyFeature
    case localEcologyInitialization
    case ecologyHabitatValidation
    case ecologyForageOutcomes
    case ecologyClear
    case mortalityFeature
    case mortalityClear
    case lifecycleFeature
    case reproductionFeature
    case birthSiteObservation
    case lifecycleClear
    case kinshipFeature
    case householdFeature
    case householdFormation
    case householdMove
}

public enum AgentReplayOperation: Codable {
    case advanceTick(
        perceptions: [AgentPerceptionInput],
        physicalObservations: [AgentPhysicalSignalObservation]
    )
    case externalUpdate(AgentExternalUpdate)
    case movementOutcomes([AgentMovementOutcome])
    case interactionOutcome(AgentInteractionOutcome)
    case deliveryOutcome(AgentDeliveryOutcome)
    case consumptionOutcome(AgentConsumptionOutcome)
    case setEconomyEnabled(Bool)
    case setNaturalResourcesEnabled(Bool)
    case setSurvivalEnabled(Bool)
    case setBuildAutoEnabled(Bool)
    case setSocialEnabled(Bool)
    case setPhysicalEnabled(Bool)
    case setCooperationEnabled(Bool)
    case createConstructionProject(AgentConstructionProject)
    case fundConstructionProject(fundingID: String, builderAgentID: String, tick: Int)
    case applyPlacementOutcome(AgentPlacementOutcome)
    case recordConstructionFailure(
        failureID: String,
        projectID: String,
        builderAgentID: String,
        failure: AgentConstructionFailure,
        reason: String
    )
    case completeConstructionProject(projectID: String, tick: Int)
    case clearConstructionProject(projectID: String)
    case applySocialVerification(AgentSocialVerificationObservation)
    case clearSocialState
    case claimPhysicalPresentationRequests
    case clearPhysicalState
    case clearCooperationState
    case setPopulationEnabled(
        Bool,
        settlementAnchor: AgentPosition?,
        receptionPosition: AgentPosition?,
        configuration: AgentPopulationConfiguration
    )
    case initializePopulationRegistry(
        settlementAnchor: AgentPosition,
        receptionPosition: AgentPosition,
        configuration: AgentPopulationConfiguration
    )
    case admitMigration(
        intent: AgentMigrationAdmissionIntent,
        observation: AgentMigrationWorldObservation
    )
    case clearPopulationDiagnostics
    case setSettlementMetricsEnabled(Bool, configuration: AgentSettlementMetricsConfiguration)
    case clearSettlementMetrics
    case settlementPulseBoundary
    case setLocalEcologyEnabled(Bool)
    case initializeLocalEcology(
        observations: [AgentEcologyHabitatObservation],
        configuration: AgentLocalEcologyConfiguration
    )
    case applyHabitatValidation([AgentEcologyHabitatObservation])
    case applyForageOutcomes(
        intents: [AgentForageIntent],
        habitatValidations: [AgentEcologyHabitatObservation]
    )
    case clearEcologyDiagnostics
    case setMortalityEnabled(Bool, configuration: AgentMortalityConfiguration)
    case clearMortalityDiagnostics
    case setLifecycleEnabled(Bool, configuration: AgentLifecycleConfiguration)
    case setReproductionEnabled(Bool)
    case applyBirthSiteObservation(AgentBirthSiteObservation)
    case clearLifecycleDiagnostics
    case setKinshipEnabled(Bool, configuration: AgentKinshipConfiguration)
    case setHouseholdsEnabled(Bool, configuration: AgentHouseholdConfiguration)
    case formHousehold(memberIDs: [AgentID], residenceAnchor: AgentPosition)
    case moveHouseholdMembers(memberIDs: [AgentID], householdID: AgentHouseholdID)

    public var kind: AgentReplayOperationKind {
        switch self {
        case .advanceTick: return .advanceTick
        case .externalUpdate: return .externalUpdate
        case .movementOutcomes: return .movementOutcomes
        case .interactionOutcome: return .interactionOutcome
        case .deliveryOutcome: return .deliveryOutcome
        case .consumptionOutcome: return .consumptionOutcome
        case .setEconomyEnabled: return .economyFeature
        case .setNaturalResourcesEnabled: return .naturalResourcesFeature
        case .setSurvivalEnabled: return .survivalFeature
        case .setBuildAutoEnabled: return .constructionFeature
        case .setSocialEnabled: return .socialFeature
        case .setPhysicalEnabled: return .physicalFeature
        case .setCooperationEnabled: return .cooperationFeature
        case .createConstructionProject: return .constructionProjectCreation
        case .fundConstructionProject: return .constructionFunding
        case .applyPlacementOutcome: return .constructionPlacement
        case .recordConstructionFailure: return .constructionFailure
        case .completeConstructionProject: return .constructionCompletion
        case .clearConstructionProject: return .constructionClear
        case .applySocialVerification: return .socialVerification
        case .clearSocialState: return .socialClear
        case .claimPhysicalPresentationRequests: return .physicalPresentationClaim
        case .clearPhysicalState: return .physicalClear
        case .clearCooperationState: return .cooperationClear
        case .setPopulationEnabled: return .populationFeature
        case .initializePopulationRegistry: return .populationRegistryInitialization
        case .admitMigration: return .migrationAdmission
        case .clearPopulationDiagnostics: return .populationClear
        case .setSettlementMetricsEnabled: return .settlementMetricsFeature
        case .clearSettlementMetrics: return .settlementMetricsClear
        case .settlementPulseBoundary: return .settlementPulseBoundary
        case .setLocalEcologyEnabled: return .localEcologyFeature
        case .initializeLocalEcology: return .localEcologyInitialization
        case .applyHabitatValidation: return .ecologyHabitatValidation
        case .applyForageOutcomes: return .ecologyForageOutcomes
        case .clearEcologyDiagnostics: return .ecologyClear
        case .setMortalityEnabled: return .mortalityFeature
        case .clearMortalityDiagnostics: return .mortalityClear
        case .setLifecycleEnabled: return .lifecycleFeature
        case .setReproductionEnabled: return .reproductionFeature
        case .applyBirthSiteObservation: return .birthSiteObservation
        case .clearLifecycleDiagnostics: return .lifecycleClear
        case .setKinshipEnabled: return .kinshipFeature
        case .setHouseholdsEnabled: return .householdFeature
        case .formHousehold: return .householdFormation
        case .moveHouseholdMembers: return .householdMove
        }
    }

    public var operationID: AgentOperationID? {
        let raw: String?
        switch self {
        case let .interactionOutcome(outcome): raw = outcome.interactionId
        case let .deliveryOutcome(outcome): raw = outcome.deliveryId
        case let .consumptionOutcome(outcome): raw = outcome.consumptionId
        case let .fundConstructionProject(fundingID, _, _): raw = fundingID
        case let .applyPlacementOutcome(outcome): raw = outcome.placementId
        case let .recordConstructionFailure(failureID, _, _, _, _): raw = failureID
        case let .completeConstructionProject(projectID, tick): raw = "\(projectID):completion:\(tick)"
        case let .clearConstructionProject(projectID): raw = "\(projectID):clear"
        case let .applySocialVerification(observation): raw = "social-verification:\(observation.beliefID.rawValue)"
        case let .applyBirthSiteObservation(observation):
            raw = "birth-site:\(observation.planID.rawValue):\(observation.observedTick)"
        default: raw = nil
        }
        return raw.flatMap(AgentOperationID.init(rawValue:))
    }
}

public struct AgentReplayApplicationResult {
    public let tick: Int
    public let causalSequence: UInt64
    public let causalDigest: String
    public let tickResult: AgentSessionTickResult?
    public let socialVerificationResult: AgentSocialVerificationResult?
    public let claimedPhysicalPresentations: [AgentPhysicalPresentationRequest]

    init(
        tick: Int,
        causalSequence: UInt64,
        causalDigest: String,
        tickResult: AgentSessionTickResult? = nil,
        socialVerificationResult: AgentSocialVerificationResult? = nil,
        claimedPhysicalPresentations: [AgentPhysicalPresentationRequest] = []
    ) {
        self.tick = tick
        self.causalSequence = causalSequence
        self.causalDigest = causalDigest
        self.tickResult = tickResult
        self.socialVerificationResult = socialVerificationResult
        self.claimedPhysicalPresentations = claimedPhysicalPresentations
    }
}

public struct AgentReplayRecord: Codable {
    public let schemaVersion: Int
    public let simulationID: AgentSimulationID
    public let recordSequence: AgentReplayRecordSequence
    public let operationKind: AgentReplayOperationKind
    public let operation: AgentReplayOperation
    public let expectedTickBefore: Int
    public let preStateSemanticDigest: AgentCheckpointDigest
    public let postStateSemanticDigest: AgentCheckpointDigest
    public let causalSequenceBefore: UInt64
    public let causalSequenceAfter: UInt64
    public let causalDigestAfter: String
    public let operationID: AgentOperationID?

    public init(
        schemaVersion: Int = AgentReplaySchema.currentVersion,
        simulationID: AgentSimulationID,
        recordSequence: AgentReplayRecordSequence,
        operation: AgentReplayOperation,
        expectedTickBefore: Int,
        preStateSemanticDigest: AgentCheckpointDigest,
        postStateSemanticDigest: AgentCheckpointDigest,
        causalSequenceBefore: UInt64,
        causalSequenceAfter: UInt64,
        causalDigestAfter: String
    ) {
        self.schemaVersion = schemaVersion
        self.simulationID = simulationID
        self.recordSequence = recordSequence
        operationKind = operation.kind
        self.operation = operation
        self.expectedTickBefore = expectedTickBefore
        self.preStateSemanticDigest = preStateSemanticDigest
        self.postStateSemanticDigest = postStateSemanticDigest
        self.causalSequenceBefore = causalSequenceBefore
        self.causalSequenceAfter = causalSequenceAfter
        self.causalDigestAfter = causalDigestAfter
        operationID = operation.operationID
    }
}

public struct AgentReplayJournalManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let name: AgentCheckpointName
    public let baseCheckpointID: AgentCheckpointID
    public let baseCheckpointDigest: AgentCheckpointDigest
    public let simulationID: AgentSimulationID
    public let initialTick: Int
    public let recordCount: Int
    public let droppedRecordCount: Int
    public let replayable: Bool
    public let nonReplayableReason: String?
    public let operationsStorageDigest: AgentCheckpointDigest
    public let operationsByteLength: Int

    public init(
        schemaVersion: Int = AgentReplaySchema.currentVersion,
        name: AgentCheckpointName,
        baseCheckpointID: AgentCheckpointID,
        baseCheckpointDigest: AgentCheckpointDigest,
        simulationID: AgentSimulationID,
        initialTick: Int,
        recordCount: Int,
        droppedRecordCount: Int,
        replayable: Bool,
        nonReplayableReason: String?,
        operationsStorageDigest: AgentCheckpointDigest,
        operationsByteLength: Int
    ) {
        self.schemaVersion = schemaVersion
        self.name = name
        self.baseCheckpointID = baseCheckpointID
        self.baseCheckpointDigest = baseCheckpointDigest
        self.simulationID = simulationID
        self.initialTick = initialTick
        self.recordCount = recordCount
        self.droppedRecordCount = droppedRecordCount
        self.replayable = replayable
        self.nonReplayableReason = nonReplayableReason
        self.operationsStorageDigest = operationsStorageDigest
        self.operationsByteLength = operationsByteLength
    }
}

public struct AgentReplayJournal {
    public let manifest: AgentReplayJournalManifest
    public let records: [AgentReplayRecord]

    public init(manifest: AgentReplayJournalManifest, records: [AgentReplayRecord]) {
        self.manifest = manifest
        self.records = records
    }
}

public struct AgentReplayDivergence: Codable, Equatable, Sendable {
    public let recordSequence: UInt64
    public let operationKind: AgentReplayOperationKind
    public let operationID: AgentOperationID?
    public let reason: String
    public let expectedDigest: AgentCheckpointDigest?
    public let actualDigest: AgentCheckpointDigest?
    public let expectedTick: Int?
    public let actualTick: Int?
    public let expectedCausalSequence: UInt64?
    public let actualCausalSequence: UInt64?

    public init(
        recordSequence: UInt64,
        operationKind: AgentReplayOperationKind,
        operationID: AgentOperationID?,
        reason: String,
        expectedDigest: AgentCheckpointDigest? = nil,
        actualDigest: AgentCheckpointDigest? = nil,
        expectedTick: Int? = nil,
        actualTick: Int? = nil,
        expectedCausalSequence: UInt64? = nil,
        actualCausalSequence: UInt64? = nil
    ) {
        self.recordSequence = recordSequence
        self.operationKind = operationKind
        self.operationID = operationID
        self.reason = reason
        self.expectedDigest = expectedDigest
        self.actualDigest = actualDigest
        self.expectedTick = expectedTick
        self.actualTick = actualTick
        self.expectedCausalSequence = expectedCausalSequence
        self.actualCausalSequence = actualCausalSequence
    }
}

public struct AgentReplayReport: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let verified: Bool
    public let baseCheckpointID: AgentCheckpointID
    public let simulationID: AgentSimulationID
    public let recordsApplied: Int
    public let finalTick: Int
    public let finalSemanticDigest: AgentCheckpointDigest
    public let finalCausalSequence: UInt64
    public let finalCausalDigest: String
    public let divergence: AgentReplayDivergence?

    init(
        schemaVersion: Int = AgentReplaySchema.currentVersion,
        verified: Bool,
        baseCheckpointID: AgentCheckpointID,
        simulationID: AgentSimulationID,
        recordsApplied: Int,
        finalTick: Int,
        finalSemanticDigest: AgentCheckpointDigest,
        finalCausalSequence: UInt64,
        finalCausalDigest: String,
        divergence: AgentReplayDivergence?
    ) {
        self.schemaVersion = schemaVersion
        self.verified = verified
        self.baseCheckpointID = baseCheckpointID
        self.simulationID = simulationID
        self.recordsApplied = recordsApplied
        self.finalTick = finalTick
        self.finalSemanticDigest = finalSemanticDigest
        self.finalCausalSequence = finalCausalSequence
        self.finalCausalDigest = finalCausalDigest
        self.divergence = divergence
    }
}

public struct AgentReplayResult {
    public let report: AgentReplayReport
    public let session: AgentSimulationSession

    init(report: AgentReplayReport, session: AgentSimulationSession) {
        self.report = report
        self.session = session
    }
}

public enum AgentReplayError: Error, Equatable, CustomStringConvertible {
    case unsupportedSchema(Int)
    case baseCheckpointMismatch
    case currentStateMismatch
    case capacityReached(Int)
    case byteLimitReached(Int)
    case recordSequenceOverflow
    case invalidJournal(String)

    public var description: String {
        switch self {
        case let .unsupportedSchema(version): return "unsupported replay schema \(version)"
        case .baseCheckpointMismatch: return "replay base checkpoint mismatch"
        case .currentStateMismatch: return "replay current state differs from base checkpoint"
        case let .capacityReached(count): return "replay record capacity reached at \(count)"
        case let .byteLimitReached(bytes): return "replay byte limit reached at \(bytes)"
        case .recordSequenceOverflow: return "replay record sequence overflow"
        case let .invalidJournal(reason): return "invalid replay journal: \(reason)"
        }
    }
}

public struct AgentReplayRecorder {
    public let baseCheckpointID: AgentCheckpointID
    public let baseCheckpointDigest: AgentCheckpointDigest
    public let simulationID: AgentSimulationID
    public let initialTick: Int
    public private(set) var schemaVersion: Int
    public private(set) var records: [AgentReplayRecord]
    public private(set) var droppedRecordCount: Int
    public private(set) var nonReplayableReason: String?

    public var isReplayable: Bool {
        droppedRecordCount == 0 && nonReplayableReason == nil
    }

    public init(checkpoint: AgentSessionCheckpoint, session: AgentSimulationSession) throws {
        _ = try AgentSimulationSession.validate(checkpoint)
        let currentDigest = try session.durableStateDigest()
        guard checkpoint.simulationID == session.simulationID,
              checkpoint.tick.rawValue == session.tick,
              checkpoint.semanticDigest == currentDigest else {
            throw AgentReplayError.currentStateMismatch
        }
        baseCheckpointID = checkpoint.checkpointID
        baseCheckpointDigest = checkpoint.semanticDigest
        simulationID = checkpoint.simulationID
        initialTick = checkpoint.tick.rawValue
        schemaVersion = checkpoint.schemaVersion
        records = []
        droppedRecordCount = 0
        nonReplayableReason = nil
    }

    @discardableResult
    public mutating func apply(
        _ operation: AgentReplayOperation,
        to session: inout AgentSimulationSession
    ) throws -> AgentReplayApplicationResult {
        guard isReplayable else {
            throw AgentReplayError.invalidJournal(nonReplayableReason ?? "records dropped")
        }
        guard records.count < AgentCheckpointLimits.maximumReplayRecords else {
            throw AgentReplayError.capacityReached(records.count)
        }
        if case let .setSettlementMetricsEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.settlementMetricsVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "settlement metrics activation must be the first v3 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.settlementMetricsVersion
        }
        if case .initializeLocalEcology = operation,
           schemaVersion < AgentReplaySchema.localEcologyVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "local ecology initialization must be the first v4 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.localEcologyVersion
        }
        if case let .setMortalityEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.mortalityVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "mortality activation must be the first v5 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.mortalityVersion
        }
        if case let .setLifecycleEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.lifecycleVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "lifecycle activation must be the first v6 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.lifecycleVersion
        }
        if case let .setKinshipEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.kinshipVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "kinship activation must be the first v7 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.kinshipVersion
        }
        if case let .setHouseholdsEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.householdVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "household activation must be the first v8 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.householdVersion
        }
        guard session.simulationID == simulationID else { throw AgentReplayError.currentStateMismatch }
        let preDigest = try session.durableStateDigest()
        let tickBefore = session.tick
        let causalBefore = session.causalLedgerSnapshot().summary
        var candidate = session
        let result = try candidate.applyReplayOperation(operation)
        let postDigest = try candidate.durableStateDigest()
        let causalAfter = candidate.causalLedgerSnapshot().summary
        let record = AgentReplayRecord(
            schemaVersion: schemaVersion,
            simulationID: simulationID,
            recordSequence: AgentReplayRecordSequence(rawValue: UInt64(records.count + 1))!,
            operation: operation,
            expectedTickBefore: tickBefore,
            preStateSemanticDigest: preDigest,
            postStateSemanticDigest: postDigest,
            causalSequenceBefore: causalBefore.latestSequence,
            causalSequenceAfter: causalAfter.latestSequence,
            causalDigestAfter: causalAfter.digest
        )
        let prospective = try AgentReplayCodec.encodeRecords(records + [record])
        guard prospective.count <= AgentCheckpointLimits.maximumReplayBytes else {
            throw AgentReplayError.byteLimitReached(prospective.count)
        }
        session = candidate
        records.append(record)
        return result
    }

    public mutating func markNonReplayable(_ reason: String) {
        if nonReplayableReason == nil { nonReplayableReason = reason }
    }

    public func journal(named name: AgentCheckpointName) throws -> AgentReplayJournal {
        let bytes = try AgentReplayCodec.encodeRecords(records)
        let manifest = AgentReplayJournalManifest(
            schemaVersion: schemaVersion,
            name: name,
            baseCheckpointID: baseCheckpointID,
            baseCheckpointDigest: baseCheckpointDigest,
            simulationID: simulationID,
            initialTick: initialTick,
            recordCount: records.count,
            droppedRecordCount: droppedRecordCount,
            replayable: isReplayable,
            nonReplayableReason: nonReplayableReason,
            operationsStorageDigest: AgentCheckpointDigest.sha256(bytes),
            operationsByteLength: bytes.count
        )
        return AgentReplayJournal(manifest: manifest, records: records)
    }
}

public enum AgentReplayCodec {
    public static func encodeRecords(_ records: [AgentReplayRecord]) throws -> Data {
        guard records.count <= AgentCheckpointLimits.maximumReplayRecords else {
            throw AgentReplayError.capacityReached(records.count)
        }
        var data = Data()
        for record in records {
            data.append(try AgentCheckpointCodec.encode(record))
            data.append(0x0a)
            guard data.count <= AgentCheckpointLimits.maximumReplayBytes else {
                throw AgentReplayError.byteLimitReached(data.count)
            }
        }
        return data
    }

    public static func decodeRecords(_ data: Data) throws -> [AgentReplayRecord] {
        guard data.count <= AgentCheckpointLimits.maximumReplayBytes else {
            throw AgentReplayError.byteLimitReached(data.count)
        }
        guard data.isEmpty || data.last == 0x0a else {
            throw AgentReplayError.invalidJournal("truncated NDJSON")
        }
        let lines = data.split(separator: 0x0a, omittingEmptySubsequences: true)
        guard lines.count <= AgentCheckpointLimits.maximumReplayRecords else {
            throw AgentReplayError.capacityReached(lines.count)
        }
        return try lines.map {
            try AgentCheckpointCodec.decode(AgentReplayRecord.self, from: Data($0))
        }
    }
}

public enum AgentSessionReplayer {
    public static func replay(
        checkpoint: AgentSessionCheckpoint,
        journal: AgentReplayJournal
    ) throws -> AgentReplayResult {
        try validateJournalEnvelope(checkpoint: checkpoint, journal: journal)
        var candidate = try AgentSimulationSession.restoring(checkpoint)
        for (index, record) in journal.records.enumerated() {
            let expectedRecordSequence = UInt64(index + 1)
            let actualDigest = try candidate.durableStateDigest()
            let causalBefore = candidate.causalLedgerSnapshot().summary
            if record.schemaVersion != journal.manifest.schemaVersion
                || record.recordSequence.rawValue != expectedRecordSequence
                || record.operationKind != record.operation.kind
                || record.operationID != record.operation.operationID
                || record.simulationID != candidate.simulationID
                || record.expectedTickBefore != candidate.tick
                || record.preStateSemanticDigest != actualDigest
                || record.causalSequenceBefore != causalBefore.latestSequence {
                return try divergentResult(
                    checkpoint: checkpoint,
                    candidate: candidate,
                    record: record,
                    recordsApplied: index,
                    reason: "pre-state or record envelope mismatch",
                    actualDigest: actualDigest,
                    actualCausalSequence: causalBefore.latestSequence
                )
            }
            do {
                _ = try candidate.applyReplayOperation(record.operation)
            } catch {
                return try divergentResult(
                    checkpoint: checkpoint,
                    candidate: candidate,
                    record: record,
                    recordsApplied: index,
                    reason: "operation rejected: \(error)",
                    actualDigest: try candidate.durableStateDigest(),
                    actualCausalSequence: candidate.causalLedgerSnapshot().summary.latestSequence
                )
            }
            let postDigest = try candidate.durableStateDigest()
            let causalAfter = candidate.causalLedgerSnapshot().summary
            if postDigest != record.postStateSemanticDigest
                || causalAfter.latestSequence != record.causalSequenceAfter
                || causalAfter.digest != record.causalDigestAfter {
                return try divergentResult(
                    checkpoint: checkpoint,
                    candidate: candidate,
                    record: record,
                    recordsApplied: index,
                    reason: "post-state mismatch",
                    actualDigest: postDigest,
                    actualCausalSequence: causalAfter.latestSequence
                )
            }
        }
        let digest = try candidate.durableStateDigest()
        let causal = candidate.causalLedgerSnapshot().summary
        return AgentReplayResult(
            report: AgentReplayReport(
                schemaVersion: journal.manifest.schemaVersion,
                verified: true,
                baseCheckpointID: checkpoint.checkpointID,
                simulationID: candidate.simulationID,
                recordsApplied: journal.records.count,
                finalTick: candidate.tick,
                finalSemanticDigest: digest,
                finalCausalSequence: causal.latestSequence,
                finalCausalDigest: causal.digest,
                divergence: nil
            ),
            session: candidate
        )
    }

    static func validateJournalEnvelope(
        checkpoint: AgentSessionCheckpoint,
        journal: AgentReplayJournal
    ) throws {
        let manifest = journal.manifest
        guard AgentReplaySchema.supports(manifest.schemaVersion) else {
            throw AgentReplayError.unsupportedSchema(manifest.schemaVersion)
        }
        let compatibleSchema = manifest.schemaVersion == checkpoint.schemaVersion
            || (manifest.schemaVersion == AgentReplaySchema.settlementMetricsVersion
                && checkpoint.schemaVersion == AgentCheckpointSchema.populationVersion)
            || (manifest.schemaVersion == AgentReplaySchema.localEcologyVersion
                && (checkpoint.schemaVersion == AgentCheckpointSchema.populationVersion
                    || checkpoint.schemaVersion == AgentCheckpointSchema.settlementMetricsVersion))
            || (manifest.schemaVersion == AgentReplaySchema.mortalityVersion
                && (checkpoint.schemaVersion == AgentCheckpointSchema.populationVersion
                    || checkpoint.schemaVersion == AgentCheckpointSchema.settlementMetricsVersion
                    || checkpoint.schemaVersion == AgentCheckpointSchema.localEcologyVersion))
            || (manifest.schemaVersion == AgentReplaySchema.lifecycleVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.mortalityVersion)
            || (manifest.schemaVersion == AgentReplaySchema.kinshipVersion
                && checkpoint.schemaVersion == AgentCheckpointSchema.lifecycleVersion)
            || (manifest.schemaVersion == AgentReplaySchema.householdVersion
                && checkpoint.schemaVersion == AgentCheckpointSchema.kinshipVersion)
        guard manifest.baseCheckpointID == checkpoint.checkpointID,
              manifest.baseCheckpointDigest == checkpoint.semanticDigest,
              manifest.simulationID == checkpoint.simulationID,
              manifest.initialTick == checkpoint.tick.rawValue,
              compatibleSchema else {
            throw AgentReplayError.baseCheckpointMismatch
        }
        guard manifest.replayable, manifest.droppedRecordCount == 0,
              manifest.recordCount == journal.records.count else {
            throw AgentReplayError.invalidJournal("manifest counts or replayable flag")
        }
        let bytes = try AgentReplayCodec.encodeRecords(journal.records)
        guard bytes.count == manifest.operationsByteLength,
              AgentCheckpointDigest.sha256(bytes) == manifest.operationsStorageDigest else {
            throw AgentReplayError.invalidJournal("operations storage digest")
        }
    }

    static func divergentResult(
        checkpoint: AgentSessionCheckpoint,
        candidate: AgentSimulationSession,
        record: AgentReplayRecord,
        recordsApplied: Int,
        reason: String,
        actualDigest: AgentCheckpointDigest,
        actualCausalSequence: UInt64
    ) throws -> AgentReplayResult {
        let causal = candidate.causalLedgerSnapshot().summary
        let divergence = AgentReplayDivergence(
            recordSequence: record.recordSequence.rawValue,
            operationKind: record.operationKind,
            operationID: record.operationID,
            reason: reason,
            expectedDigest: reason.hasPrefix("pre")
                ? record.preStateSemanticDigest : record.postStateSemanticDigest,
            actualDigest: actualDigest,
            expectedTick: record.expectedTickBefore,
            actualTick: candidate.tick,
            expectedCausalSequence: reason.hasPrefix("pre")
                ? record.causalSequenceBefore : record.causalSequenceAfter,
            actualCausalSequence: actualCausalSequence
        )
        return AgentReplayResult(
            report: AgentReplayReport(
                schemaVersion: record.schemaVersion,
                verified: false,
                baseCheckpointID: checkpoint.checkpointID,
                simulationID: candidate.simulationID,
                recordsApplied: recordsApplied,
                finalTick: candidate.tick,
                finalSemanticDigest: actualDigest,
                finalCausalSequence: causal.latestSequence,
                finalCausalDigest: causal.digest,
                divergence: divergence
            ),
            session: candidate
        )
    }
}

extension AgentSimulationSession {
    @discardableResult
    public mutating func applyReplayOperation(
        _ operation: AgentReplayOperation
    ) throws -> AgentReplayApplicationResult {
        var candidate = self
        var claimed: [AgentPhysicalPresentationRequest] = []
        var tickResult: AgentSessionTickResult?
        var socialVerificationResult: AgentSocialVerificationResult?
        switch operation {
        case let .advanceTick(perceptions, physicalObservations):
            tickResult = try candidate.advanceTick(
                perceptions: perceptions,
                physicalObservations: physicalObservations
            )
        case let .externalUpdate(update):
            try candidate.applyExternalUpdate(update)
        case let .movementOutcomes(outcomes):
            try candidate.applyMovementOutcomes(outcomes)
        case let .interactionOutcome(outcome):
            try candidate.applyInteractionOutcome(outcome)
        case let .deliveryOutcome(outcome):
            try candidate.applyDeliveryOutcome(outcome)
        case let .consumptionOutcome(outcome):
            try candidate.applyConsumptionOutcome(outcome)
        case let .setEconomyEnabled(enabled):
            candidate.setEconomyEnabled(enabled)
        case let .setNaturalResourcesEnabled(enabled):
            candidate.setNaturalResourcesEnabled(enabled)
        case let .setSurvivalEnabled(enabled):
            candidate.setSurvivalEnabled(enabled)
        case let .setBuildAutoEnabled(enabled):
            try candidate.setBuildAutoEnabled(enabled)
        case let .setSocialEnabled(enabled):
            try candidate.setSocialEnabled(enabled)
        case let .setPhysicalEnabled(enabled):
            try candidate.setPhysicalEnabled(enabled)
        case let .setCooperationEnabled(enabled):
            try candidate.setCooperationEnabled(enabled)
        case let .createConstructionProject(project):
            try candidate.createConstructionProject(project)
        case let .fundConstructionProject(fundingID, builderAgentID, tick):
            _ = try candidate.fundConstructionProject(
                fundingId: fundingID,
                builderAgentId: builderAgentID,
                fundingTick: tick
            )
        case let .applyPlacementOutcome(outcome):
            try candidate.applyPlacementOutcome(outcome)
        case let .recordConstructionFailure(failureID, projectID, builderAgentID, failure, reason):
            try candidate.recordConstructionFailure(
                failureId: failureID,
                projectId: projectID,
                builderAgentId: builderAgentID,
                failure: failure,
                reason: reason
            )
        case let .completeConstructionProject(projectID, tick):
            try candidate.completeConstructionProject(projectId: projectID, completionTick: tick)
        case let .clearConstructionProject(projectID):
            try candidate.clearConstructionProject(projectId: projectID)
        case let .applySocialVerification(observation):
            socialVerificationResult = try candidate.applySocialVerification(observation)
        case .clearSocialState:
            try candidate.clearSocialState()
        case .claimPhysicalPresentationRequests:
            claimed = candidate.claimPhysicalPresentationRequests()
        case .clearPhysicalState:
            try candidate.clearPhysicalState()
        case .clearCooperationState:
            try candidate.clearCooperationState()
        case let .setPopulationEnabled(
            enabled, settlementAnchor, receptionPosition, configuration
        ):
            try candidate.setPopulationEnabled(
                enabled,
                settlementAnchor: settlementAnchor,
                receptionPosition: receptionPosition,
                configuration: configuration
            )
        case let .initializePopulationRegistry(
            settlementAnchor, receptionPosition, configuration
        ):
            try candidate.initializePopulationRegistry(
                settlementAnchor: settlementAnchor,
                receptionPosition: receptionPosition,
                configuration: configuration
            )
        case let .admitMigration(intent, observation):
            _ = try candidate.admitMigration(intent: intent, observation: observation)
        case .clearPopulationDiagnostics:
            try candidate.clearPopulationDiagnostics()
        case let .setSettlementMetricsEnabled(enabled, configuration):
            try candidate.setSettlementMetricsEnabled(enabled, configuration: configuration)
        case .clearSettlementMetrics:
            try candidate.clearSettlementMetrics()
        case .settlementPulseBoundary:
            _ = try candidate.applySettlementMetricsPulseIfDue()
        case let .setLocalEcologyEnabled(enabled):
            try candidate.setLocalEcologyEnabled(enabled)
        case let .initializeLocalEcology(observations, configuration):
            try candidate.initializeLocalEcology(
                observations: observations,
                configuration: configuration
            )
        case let .applyHabitatValidation(observations):
            _ = try candidate.applyLocalEcologyEndOfTick(habitatValidations: observations)
        case let .applyForageOutcomes(intents, habitatValidations):
            _ = try candidate.applyForageIntents(
                intents,
                habitatValidations: habitatValidations
            )
        case .clearEcologyDiagnostics:
            try candidate.clearLocalEcologyDiagnostics()
        case let .setMortalityEnabled(enabled, configuration):
            try candidate.setMortalityEnabled(enabled, configuration: configuration)
        case .clearMortalityDiagnostics:
            try candidate.clearMortalityDiagnostics()
        case let .setLifecycleEnabled(enabled, configuration):
            try candidate.setLifecycleEnabled(enabled, configuration: configuration)
        case let .setReproductionEnabled(enabled):
            try candidate.setReproductionEnabled(enabled)
        case let .applyBirthSiteObservation(observation):
            _ = try candidate.applyBirthSiteObservation(observation)
        case .clearLifecycleDiagnostics:
            try candidate.clearLifecycleDiagnostics()
        case let .setKinshipEnabled(enabled, configuration):
            try candidate.setKinshipEnabled(enabled, configuration: configuration)
        case let .setHouseholdsEnabled(enabled, configuration):
            try candidate.setHouseholdsEnabled(enabled, configuration: configuration)
        case let .formHousehold(memberIDs, residenceAnchor):
            _ = try candidate.formHousehold(
                memberIDs: memberIDs,
                residenceAnchor: residenceAnchor
            )
        case let .moveHouseholdMembers(memberIDs, householdID):
            try candidate.moveMembers(memberIDs: memberIDs, to: householdID)
        }
        self = candidate
        let causal = causalLedgerSnapshot().summary
        return AgentReplayApplicationResult(
            tick: tick,
            causalSequence: causal.latestSequence,
            causalDigest: causal.digest,
            tickResult: tickResult,
            socialVerificationResult: socialVerificationResult,
            claimedPhysicalPresentations: claimed
        )
    }
}
