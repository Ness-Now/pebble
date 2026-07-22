public enum AgentWorkCommitmentError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case lifecycleRequired
    case skillsRequired
    case alreadyEnabled
    case disabled
    case unsafeDisable
    case unknownDemand(AgentWorkDemandID)
    case inactiveDemand(AgentWorkDemandID)
    case unknownCommitment(AgentWorkCommitmentID)
    case invalidTransition(String)
    case noEligibleWorker(AgentWorkDemandID)
    case invalidCandidate(AgentID)
    case invalidOutcome(String)
    case duplicateSourceEvent(AgentCausalEventID)
    case capacityReached(String)
    case transitionsPerTickReached
    case invalidCausalReference(AgentCausalEventID)
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason): return "invalid work configuration: \(reason)"
        case .causalLedgerRequired: return "work commitments require the causal ledger"
        case .populationRequired: return "work commitments require population"
        case .lifecycleRequired: return "work commitments require lifecycle"
        case .skillsRequired: return "work commitments require skills"
        case .alreadyEnabled: return "work commitments already enabled"
        case .disabled: return "work commitments disabled"
        case .unsafeDisable: return "work commitments cannot be disabled after durable state exists"
        case let .unknownDemand(id): return "unknown work demand \(id.rawValue)"
        case let .inactiveDemand(id): return "inactive work demand \(id.rawValue)"
        case let .unknownCommitment(id): return "unknown work commitment \(id.rawValue)"
        case let .invalidTransition(reason): return "invalid work transition: \(reason)"
        case let .noEligibleWorker(id): return "no eligible worker for \(id.rawValue)"
        case let .invalidCandidate(id): return "invalid work candidate \(id.rawValue)"
        case let .invalidOutcome(reason): return "invalid work outcome: \(reason)"
        case let .duplicateSourceEvent(id): return "work source already normalized \(id.rawValue)"
        case let .capacityReached(kind): return "work capacity reached: \(kind)"
        case .transitionsPerTickReached: return "work transitions per tick reached"
        case let .invalidCausalReference(id): return "invalid work causal reference \(id.rawValue)"
        case let .invalidState(reason): return "invalid work state: \(reason)"
        }
    }
}

public struct AgentWorkCommitmentConfiguration: Codable, Equatable, Sendable {
    public let maximumActiveDemands: Int
    public let maximumRetainedCommitments: Int
    public let maximumRetainedEvidence: Int
    public let maximumEvidencePerAgent: Int
    public let maximumReputationEntries: Int
    public let maximumRetainedMatchingAttempts: Int
    public let maximumConcurrentCommitmentsPerAgent: Int
    public let maximumTransitionsPerTick: Int
    public let demandLifetimeTicks: Int
    public let commitmentLifetimeTicks: Int
    public let reviewIntervalTicks: Int
    public let recentHistoryWindowTicks: Int

    public init(
        maximumActiveDemands: Int = 64,
        maximumRetainedCommitments: Int = 256,
        maximumRetainedEvidence: Int = 512,
        maximumEvidencePerAgent: Int = 128,
        maximumReputationEntries: Int = 512,
        maximumRetainedMatchingAttempts: Int = 256,
        maximumConcurrentCommitmentsPerAgent: Int = 3,
        maximumTransitionsPerTick: Int = 64,
        demandLifetimeTicks: Int = 8,
        commitmentLifetimeTicks: Int = 32,
        reviewIntervalTicks: Int = 4,
        recentHistoryWindowTicks: Int = 32
    ) throws {
        guard (1...512).contains(maximumActiveDemands) else {
            throw AgentWorkCommitmentError.invalidConfiguration("active demands")
        }
        guard (1...4096).contains(maximumRetainedCommitments) else {
            throw AgentWorkCommitmentError.invalidConfiguration("retained commitments")
        }
        guard (1...8192).contains(maximumRetainedEvidence),
              (1...maximumRetainedEvidence).contains(maximumEvidencePerAgent) else {
            throw AgentWorkCommitmentError.invalidConfiguration("evidence bounds")
        }
        guard (1...4096).contains(maximumReputationEntries),
              (1...4096).contains(maximumRetainedMatchingAttempts),
              (1...8).contains(maximumConcurrentCommitmentsPerAgent),
              (1...256).contains(maximumTransitionsPerTick) else {
            throw AgentWorkCommitmentError.invalidConfiguration("state bounds")
        }
        guard (1...128).contains(demandLifetimeTicks),
              (2...512).contains(commitmentLifetimeTicks),
              (1...commitmentLifetimeTicks).contains(reviewIntervalTicks),
              (1...512).contains(recentHistoryWindowTicks) else {
            throw AgentWorkCommitmentError.invalidConfiguration("time bounds")
        }
        self.maximumActiveDemands = maximumActiveDemands
        self.maximumRetainedCommitments = maximumRetainedCommitments
        self.maximumRetainedEvidence = maximumRetainedEvidence
        self.maximumEvidencePerAgent = maximumEvidencePerAgent
        self.maximumReputationEntries = maximumReputationEntries
        self.maximumRetainedMatchingAttempts = maximumRetainedMatchingAttempts
        self.maximumConcurrentCommitmentsPerAgent = maximumConcurrentCommitmentsPerAgent
        self.maximumTransitionsPerTick = maximumTransitionsPerTick
        self.demandLifetimeTicks = demandLifetimeTicks
        self.commitmentLifetimeTicks = commitmentLifetimeTicks
        self.reviewIntervalTicks = reviewIntervalTicks
        self.recentHistoryWindowTicks = recentHistoryWindowTicks
    }

    public static let live = try! AgentWorkCommitmentConfiguration()
}

public struct AgentWorkDemandID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard rawValue.hasPrefix("work-demand-"), (13...160).contains(rawValue.count),
              rawValue.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0)) }) else {
            return nil
        }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentWorkCommitmentID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard rawValue.hasPrefix("work-commitment-"), (17...160).contains(rawValue.count),
              rawValue.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0)) }) else {
            return nil
        }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentWorkDemandSource: String, Codable, CaseIterable, Comparable, Sendable {
    case agriculture
    case wildSubsistence
    case livestock
    case construction
    case dependentCare
    case cooperation
    case material
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentWorkDemandStatus: String, Codable, CaseIterable, Sendable {
    case active
    case fulfilled
    case withdrawn
    case expired
    public var isActive: Bool { self == .active }
}

/// A bounded projection of an existing domain need. It is not a scheduler and
/// carries no permission to execute the referenced physical work.
public struct AgentWorkDemandSignal: Codable, Equatable, Sendable {
    public let demandID: AgentWorkDemandID
    public let source: AgentWorkDemandSource
    public let sourceKey: String
    public let sourceEventID: AgentCausalEventID
    public let observerID: AgentID
    public let suggestedWorkerID: AgentID?
    public let domain: AgentSkillDomain
    public let targetPosition: AgentPosition?
    public let requiredToolKeys: [String]
    public let requiredResourceKeys: [String]
    public let urgency: Int
    public let quantity: Int
    public let cadenceTicks: Int
    public let createdAtTick: Int
    public internal(set) var refreshedAtTick: Int
    public internal(set) var expiresAtTick: Int
    public internal(set) var status: AgentWorkDemandStatus
    public internal(set) var terminalEventID: AgentCausalEventID?

    public init(
        demandID: AgentWorkDemandID,
        source: AgentWorkDemandSource,
        sourceKey: String,
        sourceEventID: AgentCausalEventID,
        observerID: AgentID,
        suggestedWorkerID: AgentID? = nil,
        domain: AgentSkillDomain,
        targetPosition: AgentPosition? = nil,
        requiredToolKeys: [String] = [],
        requiredResourceKeys: [String] = [],
        urgency: Int,
        quantity: Int = 1,
        cadenceTicks: Int,
        createdAtTick: Int,
        expiresAtTick: Int
    ) {
        self.demandID = demandID
        self.source = source
        self.sourceKey = String(sourceKey.prefix(160))
        self.sourceEventID = sourceEventID
        self.observerID = observerID
        self.suggestedWorkerID = suggestedWorkerID
        self.domain = domain
        self.targetPosition = targetPosition
        self.requiredToolKeys = Array(Set(requiredToolKeys.map { String($0.prefix(80)) })).sorted()
        self.requiredResourceKeys = Array(Set(requiredResourceKeys.map { String($0.prefix(80)) })).sorted()
        self.urgency = max(0, min(100, urgency))
        self.quantity = max(1, quantity)
        self.cadenceTicks = max(1, cadenceTicks)
        self.createdAtTick = createdAtTick
        refreshedAtTick = createdAtTick
        self.expiresAtTick = expiresAtTick
        status = .active
        terminalEventID = nil
    }
}

public enum AgentWorkCommitmentStatus: String, Codable, CaseIterable, Sendable {
    case active
    case suspended
    case fulfilled
    case ended
    case expired
    case reassigned
    public var isOpen: Bool { self == .active || self == .suspended }
}

public enum AgentWorkSuspensionReason: String, Codable, CaseIterable, Sendable {
    case dependentCare
    case crisis
    case unavailable
    case physicalBlock
}

public enum AgentWorkEndReason: String, Codable, CaseIterable, Sendable {
    case completed
    case demandWithdrawn
    case expired
    case workerDied
    case replacement
    case voluntary
}

public struct AgentWorkCommitment: Codable, Equatable, Sendable {
    public let commitmentID: AgentWorkCommitmentID
    public let demandID: AgentWorkDemandID
    public let workerID: AgentID
    public let observerID: AgentID
    public let domain: AgentSkillDomain
    public let startedAtTick: Int
    public let startedEventID: AgentCausalEventID
    public internal(set) var reviewAtTick: Int
    public internal(set) var expiresAtTick: Int
    public internal(set) var status: AgentWorkCommitmentStatus
    public internal(set) var suspensionReason: AgentWorkSuspensionReason?
    public internal(set) var outcomeCount: Int
    public internal(set) var successfulOutcomeCount: Int
    public internal(set) var lastOutcomeEventID: AgentCausalEventID?
    public internal(set) var terminalTick: Int?
    public internal(set) var terminalEventID: AgentCausalEventID?
    public internal(set) var replacementCommitmentID: AgentWorkCommitmentID?
}

public struct AgentWorkCandidateContext: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let capable: Bool
    public let physicallyAvailable: Bool
    public let toolsAvailable: Bool
    public let resourcesAvailable: Bool
    public let distance: Int
    public let externalWorkload: Int
    public let obligationPenalty: Int

    public init(
        agentID: AgentID,
        capable: Bool = true,
        physicallyAvailable: Bool = true,
        toolsAvailable: Bool = true,
        resourcesAvailable: Bool = true,
        distance: Int,
        externalWorkload: Int = 0,
        obligationPenalty: Int = 0
    ) {
        self.agentID = agentID
        self.capable = capable
        self.physicallyAvailable = physicallyAvailable
        self.toolsAvailable = toolsAvailable
        self.resourcesAvailable = resourcesAvailable
        self.distance = max(0, distance)
        self.externalWorkload = max(0, externalWorkload)
        self.obligationPenalty = max(0, min(100, obligationPenalty))
    }
}

public struct AgentWorkMatchScore: Codable, Equatable, Sendable {
    public let capability: Int
    public let skillAndPractice: Int
    public let continuity: Int
    public let localReputation: Int
    public let trust: Int
    public let proximity: Int
    public let availability: Int
    public let obligations: Int
    public let toolsAndResources: Int
    public let urgency: Int
    public var total: Int {
        capability + skillAndPractice + continuity + localReputation + trust
            + proximity + availability + obligations + toolsAndResources + urgency
    }
}

public struct AgentWorkMatchingAttempt: Codable, Equatable, Sendable {
    public let demandID: AgentWorkDemandID
    public let selectedWorkerID: AgentID?
    public let eligibleWorkerIDs: [AgentID]
    public let rejectedWorkerIDs: [AgentID]
    public let selectedScore: AgentWorkMatchScore?
    public let attemptedAtTick: Int
    public let causalEventID: AgentCausalEventID?
}

public enum AgentWorkOutcomeStatus: String, Codable, CaseIterable, Sendable {
    case succeeded
    case failed
    case blocked
    case interrupted
}

/// Normalized evidence references an already-published domain event. It never
/// creates, retries, or substitutes the physical outcome.
public struct AgentValidatedWorkOutcome: Codable, Equatable, Sendable {
    public let commitmentID: AgentWorkCommitmentID
    public let workerID: AgentID
    public let domain: AgentSkillDomain
    public let sourceSuccessEventID: AgentCausalEventID
    public let status: AgentWorkOutcomeStatus
    public let observerIDs: [AgentID]
    public let quantity: Int

    public init(
        commitmentID: AgentWorkCommitmentID,
        workerID: AgentID,
        domain: AgentSkillDomain,
        sourceSuccessEventID: AgentCausalEventID,
        status: AgentWorkOutcomeStatus,
        observerIDs: [AgentID],
        quantity: Int = 1
    ) {
        self.commitmentID = commitmentID
        self.workerID = workerID
        self.domain = domain
        self.sourceSuccessEventID = sourceSuccessEventID
        self.status = status
        self.observerIDs = Array(Set(observerIDs)).sorted()
        self.quantity = max(1, quantity)
    }
}

public struct AgentWorkEvidence: Codable, Equatable, Sendable {
    public let commitmentID: AgentWorkCommitmentID
    public let demandID: AgentWorkDemandID
    public let workerID: AgentID
    public let domain: AgentSkillDomain
    public let sourceEventID: AgentCausalEventID
    public let sourceKind: AgentCausalEventKind
    public let status: AgentWorkOutcomeStatus
    public let quantity: Int
    public let observedBy: [AgentID]
    public let recordedAtTick: Int
    public let workEventID: AgentCausalEventID
    public let digest: String
}

public struct AgentLocalWorkReputation: Codable, Equatable, Sendable {
    public let observerID: AgentID
    public let workerID: AgentID
    public let domain: AgentSkillDomain
    public internal(set) var score: Int
    public internal(set) var successCount: Int
    public internal(set) var failureCount: Int
    public internal(set) var blockedCount: Int
    public internal(set) var interruptionCount: Int
    public internal(set) var lastEvidenceEventID: AgentCausalEventID
    public internal(set) var lastChangedAtTick: Int
}

public struct AgentWorkDomainHistory: Codable, Equatable, Sendable {
    public let workerID: AgentID
    public let domain: AgentSkillDomain
    public internal(set) var outcomeCount: Int
    public internal(set) var successCount: Int
    public internal(set) var failureCount: Int
    public internal(set) var blockedCount: Int
    public internal(set) var interruptionCount: Int
    public internal(set) var completedCommitmentCount: Int
    public internal(set) var firstWorkTick: Int
    public internal(set) var lastWorkTick: Int
}

public struct AgentWorkEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var demands = 0
    public internal(set) var commitments = 0
    public internal(set) var evidence = 0
    public internal(set) var reputations = 0
    public internal(set) var matchingAttempts = 0
    public internal(set) var processedSourceEventIDs = 0
    public init() {}
}

public struct AgentWorkCommitmentState: Codable, Equatable, Sendable {
    public let configuration: AgentWorkCommitmentConfiguration
    public internal(set) var demands: [AgentWorkDemandSignal]
    public internal(set) var commitments: [AgentWorkCommitment]
    public internal(set) var retainedEvidence: [AgentWorkEvidence]
    public internal(set) var localReputations: [AgentLocalWorkReputation]
    public internal(set) var domainHistories: [AgentWorkDomainHistory]
    public internal(set) var matchingAttempts: [AgentWorkMatchingAttempt]
    public internal(set) var processedSourceEventIDs: [AgentCausalEventID]
    /// Monotonic causal high-water mark. Retained source IDs may be evicted,
    /// but an older physical event can still never be credited again.
    public internal(set) var lastProcessedSourceEventID: AgentCausalEventID?
    public internal(set) var totalDemandCount: Int
    public internal(set) var totalCommitmentCount: Int
    public internal(set) var totalEvidenceCount: Int
    public internal(set) var totalReassignmentCount: Int
    public internal(set) var evictionCounts: AgentWorkEvictionCounts
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastWorkEventID: AgentCausalEventID
    public internal(set) var transitionTick: Int
    public internal(set) var transitionsAtTick: Int
}

public struct AgentWorkCommitmentSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let demands: [AgentWorkDemandSignal]
    public let commitments: [AgentWorkCommitment]
    public let evidence: [AgentWorkEvidence]
    public let localReputations: [AgentLocalWorkReputation]
    public let matchingAttempts: [AgentWorkMatchingAttempt]
    public let totalDemandCount: Int
    public let totalCommitmentCount: Int
    public let totalEvidenceCount: Int
    public let totalReassignmentCount: Int
    public let evictionCounts: AgentWorkEvictionCounts
    public let digest: String
}

public enum AgentWorkCommitmentOperation: Codable, Equatable, Sendable {
    case refreshDemands
    case start(demandID: AgentWorkDemandID, candidates: [AgentWorkCandidateContext])
    case renew(commitmentID: AgentWorkCommitmentID)
    case suspend(commitmentID: AgentWorkCommitmentID, reason: AgentWorkSuspensionReason)
    case resume(commitmentID: AgentWorkCommitmentID)
    case end(commitmentID: AgentWorkCommitmentID, reason: AgentWorkEndReason)
    case replace(commitmentID: AgentWorkCommitmentID, candidates: [AgentWorkCandidateContext])
    case recordOutcome(AgentValidatedWorkOutcome)
    case review
}

public enum AgentWorkDigest {
    public static func make(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 { value ^= UInt64(byte); value &*= 1_099_511_628_211 }
        let digits = String(value, radix: 16)
        return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
    }
}
