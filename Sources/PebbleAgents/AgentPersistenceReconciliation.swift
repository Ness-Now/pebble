import Foundation

/// Plain, bounded identity supplied by Pebble after its real World has loaded.
/// It is a binding fact, not a second World record.
public struct AgentPersistenceWorldIdentity: Codable, Equatable, Sendable {
    public let worldID: String
    public let storageIdentity: String
    public let seed: UInt32
    public let dimension: Int

    public init(
        worldID: String,
        storageIdentity: String,
        seed: UInt32,
        dimension: Int
    ) {
        self.worldID = worldID
        self.storageIdentity = storageIdentity
        self.seed = seed
        self.dimension = dimension
    }
}

/// A checkpoint declares only the physical references which Pebble must
/// observe again. Candidate holders are finite and deterministic; V1 never
/// scans a World without a bound.
public struct AgentPersistenceAssetExpectation: Codable, Equatable, Sendable {
    public let asset: AgentMaterialAssetReference
    public let savedObservation: AgentMaterialHolderObservation
    public let candidateHolders: [AgentMaterialPhysicalHolder]

    public init(
        asset: AgentMaterialAssetReference,
        savedObservation: AgentMaterialHolderObservation,
        candidateHolders: [AgentMaterialPhysicalHolder]
    ) {
        self.asset = asset
        self.savedObservation = savedObservation
        self.candidateHolders = Array(Set(candidateHolders))
            .sorted { $0.stableText < $1.stableText }
    }
}

public struct AgentPersistenceReconciliationBinding: Codable, Equatable, Sendable {
    public let world: AgentPersistenceWorldIdentity
    public let checkpointID: AgentCheckpointID
    public let simulationID: AgentSimulationID
    public let checkpointTick: AgentSimulationTick
    public let causalSequence: UInt64
    public let assets: [AgentPersistenceAssetExpectation]

    public init(
        world: AgentPersistenceWorldIdentity,
        checkpointID: AgentCheckpointID,
        simulationID: AgentSimulationID,
        checkpointTick: AgentSimulationTick,
        causalSequence: UInt64,
        assets: [AgentPersistenceAssetExpectation]
    ) {
        self.world = world
        self.checkpointID = checkpointID
        self.simulationID = simulationID
        self.checkpointTick = checkpointTick
        self.causalSequence = causalSequence
        self.assets = assets.sorted { $0.asset.assetID < $1.asset.assetID }
    }
}

public enum AgentPersistenceReconciliationOutcome: String, Codable, CaseIterable, Sendable {
    case matched
    case changedButReconcilable
    case missing
    case ambiguous
    case duplicatedOrConflicting
    case invalid

    public var isPublishable: Bool {
        self == .matched || self == .changedButReconcilable || self == .missing
    }

    public var hasVerifiedPhysicalAsset: Bool {
        self == .matched || self == .changedButReconcilable
    }
}

public struct AgentPersistenceAssetObservationSet: Codable, Equatable, Sendable {
    public let assetID: AgentMaterialAssetID
    public let observations: [AgentMaterialHolderObservation]

    public init(
        assetID: AgentMaterialAssetID,
        observations: [AgentMaterialHolderObservation]
    ) {
        self.assetID = assetID
        self.observations = observations.sorted {
            if $0.holder.stableText != $1.holder.stableText {
                return $0.holder.stableText < $1.holder.stableText
            }
            if $0.custodyFingerprint != $1.custodyFingerprint {
                return $0.custodyFingerprint < $1.custodyFingerprint
            }
            return $0.physicalReceiptID < $1.physicalReceiptID
        }
    }
}

public enum AgentPersistenceInterruptedActivityPolicy: String, Codable, CaseIterable, Sendable {
    case resume
    case revalidateThenResume
    case replan
    case rollback
    case cancelWithCausalReason

    public var keepsActivityActive: Bool {
        self == .resume || self == .revalidateThenResume
    }
}

public struct AgentPersistenceActivityResolution: Codable, Equatable, Sendable {
    public let activityID: String
    public let actorID: AgentID
    public let policy: AgentPersistenceInterruptedActivityPolicy
    public let reason: String

    public init(
        activityID: String,
        actorID: AgentID,
        policy: AgentPersistenceInterruptedActivityPolicy,
        reason: String
    ) {
        self.activityID = String(activityID.prefix(160))
        self.actorID = actorID
        self.policy = policy
        self.reason = String(reason.prefix(240))
    }
}

public struct AgentPersistenceReconciliationRequest: Codable, Equatable, Sendable {
    public let runID: String
    public let binding: AgentPersistenceReconciliationBinding
    public let restoredWorld: AgentPersistenceWorldIdentity
    public let observedWorldTick: Int
    public let assetObservations: [AgentPersistenceAssetObservationSet]
    public let activityResolutions: [AgentPersistenceActivityResolution]

    public init(
        runID: String,
        binding: AgentPersistenceReconciliationBinding,
        restoredWorld: AgentPersistenceWorldIdentity,
        observedWorldTick: Int,
        assetObservations: [AgentPersistenceAssetObservationSet],
        activityResolutions: [AgentPersistenceActivityResolution]
    ) {
        self.runID = runID
        self.binding = binding
        self.restoredWorld = restoredWorld
        self.observedWorldTick = observedWorldTick
        self.assetObservations = assetObservations.sorted { $0.assetID < $1.assetID }
        self.activityResolutions = activityResolutions.sorted {
            if $0.actorID != $1.actorID { return $0.actorID < $1.actorID }
            return $0.activityID < $1.activityID
        }
    }
}

public struct AgentPersistenceAssetReconciliationResult: Codable, Equatable, Sendable {
    public let assetID: AgentMaterialAssetID
    public let outcome: AgentPersistenceReconciliationOutcome
    public let savedHolder: AgentMaterialPhysicalHolder
    public let restoredHolder: AgentMaterialPhysicalHolder?
    public let observation: AgentMaterialHolderObservation?
    public let reason: String
    public let eventID: AgentCausalEventID?

    public init(
        assetID: AgentMaterialAssetID,
        outcome: AgentPersistenceReconciliationOutcome,
        savedHolder: AgentMaterialPhysicalHolder,
        restoredHolder: AgentMaterialPhysicalHolder?,
        observation: AgentMaterialHolderObservation?,
        reason: String,
        eventID: AgentCausalEventID?
    ) {
        self.assetID = assetID
        self.outcome = outcome
        self.savedHolder = savedHolder
        self.restoredHolder = restoredHolder
        self.observation = observation
        self.reason = String(reason.prefix(240))
        self.eventID = eventID
    }
}

public struct AgentPersistenceActivityReconciliationResult: Codable, Equatable, Sendable {
    public let activityID: String
    public let actorID: AgentID
    public let policy: AgentPersistenceInterruptedActivityPolicy
    public let reason: String
    public let eventID: AgentCausalEventID?
}

public struct AgentPersistenceReconciliationRun: Codable, Equatable, Sendable {
    public let runID: String
    public let checkpointID: AgentCheckpointID
    public let world: AgentPersistenceWorldIdentity
    public let checkpointTick: Int
    public let observedWorldTick: Int
    public let causalSequenceBefore: UInt64
    public let causalSequenceAfter: UInt64
    public let assetResults: [AgentPersistenceAssetReconciliationResult]
    public let activityResults: [AgentPersistenceActivityReconciliationResult]
    public let duplicationCount: Int

    public init(
        runID: String,
        checkpointID: AgentCheckpointID,
        world: AgentPersistenceWorldIdentity,
        checkpointTick: Int,
        observedWorldTick: Int,
        causalSequenceBefore: UInt64,
        causalSequenceAfter: UInt64,
        assetResults: [AgentPersistenceAssetReconciliationResult],
        activityResults: [AgentPersistenceActivityReconciliationResult],
        duplicationCount: Int
    ) {
        self.runID = runID
        self.checkpointID = checkpointID
        self.world = world
        self.checkpointTick = checkpointTick
        self.observedWorldTick = observedWorldTick
        self.causalSequenceBefore = causalSequenceBefore
        self.causalSequenceAfter = causalSequenceAfter
        self.assetResults = assetResults
        self.activityResults = activityResults
        self.duplicationCount = duplicationCount
    }
}

public enum AgentPersistenceReconciliationApplicationStatus: String, Codable, Sendable {
    case applied
    case duplicate
}

public struct AgentPersistenceReconciliationReport: Codable, Equatable, Sendable {
    public let status: AgentPersistenceReconciliationApplicationStatus
    public let run: AgentPersistenceReconciliationRun

    public var publishable: Bool {
        run.duplicationCount == 0
            && run.assetResults.allSatisfy { $0.outcome.isPublishable }
    }
}

public struct AgentPersistenceReconciliationConfiguration: Codable, Equatable, Sendable {
    public let maximumAssetReferences: Int
    public let maximumObservationsPerAsset: Int
    public let maximumActivityResolutions: Int
    public let maximumRetainedResults: Int
    public let maximumRetainedRuns: Int
    public let maximumProcessedRunIDs: Int

    public init(
        maximumAssetReferences: Int = 128,
        maximumObservationsPerAsset: Int = 8,
        maximumActivityResolutions: Int = 64,
        maximumRetainedResults: Int = 256,
        maximumRetainedRuns: Int = 128,
        maximumProcessedRunIDs: Int = 128
    ) throws {
        guard (1...512).contains(maximumAssetReferences),
              (1...32).contains(maximumObservationsPerAsset),
              (1...512).contains(maximumActivityResolutions),
              (1...4096).contains(maximumRetainedResults),
              (1...256).contains(maximumRetainedRuns),
              (1...4096).contains(maximumProcessedRunIDs),
              maximumProcessedRunIDs <= maximumRetainedRuns else {
            throw AgentPersistenceReconciliationError.invalidConfiguration
        }
        self.maximumAssetReferences = maximumAssetReferences
        self.maximumObservationsPerAsset = maximumObservationsPerAsset
        self.maximumActivityResolutions = maximumActivityResolutions
        self.maximumRetainedResults = maximumRetainedResults
        self.maximumRetainedRuns = maximumRetainedRuns
        self.maximumProcessedRunIDs = maximumProcessedRunIDs
    }

    public static let live = try! AgentPersistenceReconciliationConfiguration()
}

public struct AgentPersistenceReconciliationState: Codable, Equatable, Sendable {
    public let configuration: AgentPersistenceReconciliationConfiguration
    public internal(set) var latestResults: [AgentPersistenceAssetReconciliationResult]
    public internal(set) var recentRuns: [AgentPersistenceReconciliationRun]
    public internal(set) var processedRunIDs: [String]
    public internal(set) var droppedResultCount: UInt64
    public internal(set) var droppedRunCount: UInt64
    public internal(set) var droppedRunIDCount: UInt64

    public init(
        configuration: AgentPersistenceReconciliationConfiguration = .live,
        latestResults: [AgentPersistenceAssetReconciliationResult] = [],
        recentRuns: [AgentPersistenceReconciliationRun] = [],
        processedRunIDs: [String] = [],
        droppedResultCount: UInt64 = 0,
        droppedRunCount: UInt64 = 0,
        droppedRunIDCount: UInt64 = 0
    ) {
        self.configuration = configuration
        self.latestResults = latestResults.sorted { $0.assetID < $1.assetID }
        self.recentRuns = recentRuns
        self.processedRunIDs = processedRunIDs
        self.droppedResultCount = droppedResultCount
        self.droppedRunCount = droppedRunCount
        self.droppedRunIDCount = droppedRunIDCount
    }
}

public struct AgentPersistenceReconciliationSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let latestResults: [AgentPersistenceAssetReconciliationResult]
    public let recentRuns: [AgentPersistenceReconciliationRun]
    public let droppedResultCount: UInt64
    public let droppedRunCount: UInt64

    public init(state: AgentPersistenceReconciliationState?) {
        enabled = state != nil
        latestResults = state?.latestResults ?? []
        recentRuns = state?.recentRuns ?? []
        droppedResultCount = state?.droppedResultCount ?? 0
        droppedRunCount = state?.droppedRunCount ?? 0
    }
}

public enum AgentPersistenceReconciliationError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration
    case disabled
    case causalLedgerRequired
    case invalidRequest(String)
    case worldMismatch(String)
    case checkpointMismatch(String)
    case assetReferenceMismatch
    case invalidObservation(AgentMaterialAssetID)
    case ambiguousAsset(AgentMaterialAssetID)
    case duplicatedOrConflictingAsset(AgentMaterialAssetID)
    case activityResolutionMismatch(String)
    case invalidState(String)

    public var description: String {
        switch self {
        case .invalidConfiguration: return "invalid persistence-reconciliation configuration"
        case .disabled: return "persistence reconciliation disabled"
        case .causalLedgerRequired: return "persistence reconciliation requires causal ledger"
        case let .invalidRequest(reason): return "invalid reconciliation request: \(reason)"
        case let .worldMismatch(reason): return "restored World mismatch: \(reason)"
        case let .checkpointMismatch(reason): return "checkpoint mismatch: \(reason)"
        case .assetReferenceMismatch: return "physical asset reference set mismatch"
        case let .invalidObservation(id): return "invalid physical observation for \(id.rawValue)"
        case let .ambiguousAsset(id): return "ambiguous physical asset \(id.rawValue)"
        case let .duplicatedOrConflictingAsset(id):
            return "duplicated or conflicting physical asset \(id.rawValue)"
        case let .activityResolutionMismatch(id):
            return "interrupted activity resolution mismatch \(id)"
        case let .invalidState(reason): return "invalid reconciliation state: \(reason)"
        }
    }
}
