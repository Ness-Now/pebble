public enum AgentAutonomousActivityError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case disabled
    case unknownAgent(AgentID)
    case invalidCandidate(String)
    case candidateLimitReached
    case noActiveActivity(AgentID)
    case activityMismatch(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason):
            return "invalid autonomous activity configuration: \(reason)"
        case .disabled: return "autonomous activity orchestration disabled"
        case let .unknownAgent(id): return "unknown autonomous activity agent \(id.rawValue)"
        case let .invalidCandidate(reason): return "invalid autonomous activity candidate: \(reason)"
        case .candidateLimitReached: return "autonomous activity candidate limit reached"
        case let .noActiveActivity(id): return "no active autonomous activity for \(id.rawValue)"
        case let .activityMismatch(id): return "autonomous activity mismatch \(id)"
        }
    }
}

public enum AgentAutonomousActivityDomain: String, Codable, CaseIterable, Sendable {
    case agriculture
    case fishing
    case hunting
    case wildGathering
    case livestock
    case dependentCare
    case teaching
    case construction
    case materialHandling

    public var skillDomain: AgentSkillDomain? {
        switch self {
        case .agriculture: return .cultivation
        case .fishing: return .fishing
        case .hunting: return .hunting
        case .wildGathering: return .foraging
        case .livestock: return .husbandry
        case .dependentCare: return .caregiving
        case .construction: return .construction
        case .materialHandling: return .materialHandling
        case .teaching: return nil
        }
    }
}

public enum AgentAutonomousActivitySource: String, Codable, CaseIterable, Sendable {
    case need
    case opportunity
    case commitment
    case responsibility
}

public enum AgentAutonomousActivityLifecycle: String, Codable, CaseIterable, Sendable {
    case selected
    case traveling
    case ready
    case executing
    case completed
    case blocked
    case stale
    case interrupted

    public var isTerminal: Bool {
        self == .completed || self == .blocked || self == .stale || self == .interrupted
    }
}

public struct AgentAutonomousActivityConfiguration: Codable, Equatable, Sendable {
    public let maximumCandidatesPerDecision: Int
    public let maximumActiveActivities: Int
    public let maximumRetainedRecords: Int
    public let maximumCooldowns: Int
    public let blockedCooldownTicks: Int

    public init(
        maximumCandidatesPerDecision: Int = 128,
        maximumActiveActivities: Int = 64,
        maximumRetainedRecords: Int = 256,
        maximumCooldowns: Int = 128,
        blockedCooldownTicks: Int = 4
    ) throws {
        guard (1...512).contains(maximumCandidatesPerDecision) else {
            throw AgentAutonomousActivityError.invalidConfiguration("candidates")
        }
        guard (1...512).contains(maximumActiveActivities) else {
            throw AgentAutonomousActivityError.invalidConfiguration("active activities")
        }
        guard (1...4096).contains(maximumRetainedRecords) else {
            throw AgentAutonomousActivityError.invalidConfiguration("retained records")
        }
        guard (1...2048).contains(maximumCooldowns), (1...128).contains(blockedCooldownTicks) else {
            throw AgentAutonomousActivityError.invalidConfiguration("cooldowns")
        }
        self.maximumCandidatesPerDecision = maximumCandidatesPerDecision
        self.maximumActiveActivities = maximumActiveActivities
        self.maximumRetainedRecords = maximumRetainedRecords
        self.maximumCooldowns = maximumCooldowns
        self.blockedCooldownTicks = blockedCooldownTicks
    }

    public static let live = try! AgentAutonomousActivityConfiguration()
}

public enum AgentAutonomousActivityDigest {
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

/// A pure cognition input. It may contain stable registry names and positions,
/// but never a World, Entity, ItemStack, registry number, pointer, or closure.
public struct AgentAutonomousActivityCandidate: Codable, Equatable, Sendable {
    public let candidateID: String
    public let actorID: AgentID
    public let domain: AgentAutonomousActivityDomain
    public let actionKey: String
    public let stableReference: String
    public let target: AgentPosition?
    public let logicalTargetKey: String
    public let physicalTarget: AgentPosition?
    public let approachPosition: AgentPosition?
    public let materialFingerprint: String
    public let source: AgentAutonomousActivitySource
    public let priorityBand: Int
    public let urgency: Int
    public let continuity: Bool
    public let distance: Int
    public let commitmentID: AgentWorkCommitmentID?
    public let observedAtTick: Int

    public init(
        candidateID: String,
        actorID: AgentID,
        domain: AgentAutonomousActivityDomain,
        actionKey: String,
        stableReference: String,
        target: AgentPosition? = nil,
        logicalTargetKey: String? = nil,
        physicalTarget: AgentPosition? = nil,
        approachPosition: AgentPosition? = nil,
        materialFingerprint: String = "legacy",
        source: AgentAutonomousActivitySource,
        priorityBand: Int,
        urgency: Int,
        continuity: Bool = false,
        distance: Int,
        commitmentID: AgentWorkCommitmentID? = nil,
        observedAtTick: Int
    ) {
        self.candidateID = String(candidateID.prefix(160))
        self.actorID = actorID
        self.domain = domain
        self.actionKey = String(actionKey.prefix(80))
        self.stableReference = String(stableReference.prefix(160))
        self.target = target
        self.logicalTargetKey = String(
            (logicalTargetKey ?? stableReference).prefix(160)
        )
        self.physicalTarget = physicalTarget ?? target
        self.approachPosition = approachPosition
        self.materialFingerprint = String(materialFingerprint.prefix(80))
        self.source = source
        self.priorityBand = max(0, min(100, priorityBand))
        self.urgency = max(0, min(100, urgency))
        self.continuity = continuity
        self.distance = max(0, distance)
        self.commitmentID = commitmentID
        self.observedAtTick = observedAtTick
    }

    public var logicalActivityKey: String {
        AgentAutonomousActivityDigest.make([
            actorID.rawValue,
            domain.rawValue,
            actionKey,
            logicalTargetKey,
        ].joined(separator: "|"))
    }

    public var physicalAttemptFingerprint: String {
        func position(_ value: AgentPosition?) -> String {
            value.map { "\($0.x),\($0.y),\($0.z)" } ?? "none"
        }
        return AgentAutonomousActivityDigest.make([
            logicalActivityKey,
            position(physicalTarget),
            position(approachPosition),
            materialFingerprint,
        ].joined(separator: "|"))
    }

    public func cooldownFailureFingerprint(
        failureCategory: String
    ) -> String {
        AgentAutonomousActivityDigest.make(
            "\(physicalAttemptFingerprint)|\(failureCategory)"
        )
    }

    public func representsSameLogicalActivity(
        as other: AgentAutonomousActivityCandidate
    ) -> Bool {
        logicalActivityKey == other.logicalActivityKey
            && actorID == other.actorID
            && domain == other.domain
            && actionKey == other.actionKey
            && logicalTargetKey == other.logicalTargetKey
    }

    public func representsSamePhysicalAttempt(
        as other: AgentAutonomousActivityCandidate
    ) -> Bool {
        physicalAttemptFingerprint == other.physicalAttemptFingerprint
            && physicalTarget == other.physicalTarget
            && approachPosition == other.approachPosition
            && materialFingerprint == other.materialFingerprint
    }

    public func withContinuity(_ continuity: Bool) -> Self {
        Self(
            candidateID: candidateID,
            actorID: actorID,
            domain: domain,
            actionKey: actionKey,
            stableReference: stableReference,
            target: target,
            logicalTargetKey: logicalTargetKey,
            physicalTarget: physicalTarget,
            approachPosition: approachPosition,
            materialFingerprint: materialFingerprint,
            source: source,
            priorityBand: priorityBand,
            urgency: urgency,
            continuity: continuity,
            distance: distance,
            commitmentID: commitmentID,
            observedAtTick: observedAtTick
        )
    }

    private enum CodingKeys: String, CodingKey {
        case candidateID
        case actorID
        case domain
        case actionKey
        case stableReference
        case target
        case logicalTargetKey
        case physicalTarget
        case approachPosition
        case materialFingerprint
        case source
        case priorityBand
        case urgency
        case continuity
        case distance
        case commitmentID
        case observedAtTick
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let stableReference = try values.decode(
            String.self, forKey: .stableReference
        )
        let target = try values.decodeIfPresent(
            AgentPosition.self, forKey: .target
        )
        self.init(
            candidateID: try values.decode(String.self, forKey: .candidateID),
            actorID: try values.decode(AgentID.self, forKey: .actorID),
            domain: try values.decode(
                AgentAutonomousActivityDomain.self, forKey: .domain
            ),
            actionKey: try values.decode(String.self, forKey: .actionKey),
            stableReference: stableReference,
            target: target,
            logicalTargetKey: try values.decodeIfPresent(
                String.self, forKey: .logicalTargetKey
            ) ?? stableReference,
            physicalTarget: try values.decodeIfPresent(
                AgentPosition.self, forKey: .physicalTarget
            ) ?? target,
            approachPosition: try values.decodeIfPresent(
                AgentPosition.self, forKey: .approachPosition
            ),
            materialFingerprint: try values.decodeIfPresent(
                String.self, forKey: .materialFingerprint
            ) ?? "legacy",
            source: try values.decode(
                AgentAutonomousActivitySource.self, forKey: .source
            ),
            priorityBand: try values.decode(Int.self, forKey: .priorityBand),
            urgency: try values.decode(Int.self, forKey: .urgency),
            continuity: try values.decode(Bool.self, forKey: .continuity),
            distance: try values.decode(Int.self, forKey: .distance),
            commitmentID: try values.decodeIfPresent(
                AgentWorkCommitmentID.self, forKey: .commitmentID
            ),
            observedAtTick: try values.decode(Int.self, forKey: .observedAtTick)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(candidateID, forKey: .candidateID)
        try values.encode(actorID, forKey: .actorID)
        try values.encode(domain, forKey: .domain)
        try values.encode(actionKey, forKey: .actionKey)
        try values.encode(stableReference, forKey: .stableReference)
        try values.encodeIfPresent(target, forKey: .target)
        try values.encode(logicalTargetKey, forKey: .logicalTargetKey)
        try values.encodeIfPresent(physicalTarget, forKey: .physicalTarget)
        try values.encodeIfPresent(approachPosition, forKey: .approachPosition)
        try values.encode(materialFingerprint, forKey: .materialFingerprint)
        try values.encode(source, forKey: .source)
        try values.encode(priorityBand, forKey: .priorityBand)
        try values.encode(urgency, forKey: .urgency)
        try values.encode(continuity, forKey: .continuity)
        try values.encode(distance, forKey: .distance)
        try values.encodeIfPresent(commitmentID, forKey: .commitmentID)
        try values.encode(observedAtTick, forKey: .observedAtTick)
    }
}

public struct AgentAutonomousActivity: Codable, Equatable, Sendable {
    public let activityID: String
    public let candidate: AgentAutonomousActivityCandidate
    public let selectedAtTick: Int
    public internal(set) var updatedAtTick: Int
    public internal(set) var lifecycle: AgentAutonomousActivityLifecycle
}

public struct AgentAutonomousActivityOutcome: Codable, Equatable, Sendable {
    public let activityID: String
    public let actorID: AgentID
    public let lifecycle: AgentAutonomousActivityLifecycle
    public let completedAtTick: Int
    public let physicalReceiptID: String?
    public let sourceEventID: AgentCausalEventID?
    public let reason: String

    public init(
        activityID: String,
        actorID: AgentID,
        lifecycle: AgentAutonomousActivityLifecycle,
        completedAtTick: Int,
        physicalReceiptID: String? = nil,
        sourceEventID: AgentCausalEventID? = nil,
        reason: String
    ) {
        self.activityID = String(activityID.prefix(160))
        self.actorID = actorID
        self.lifecycle = lifecycle
        self.completedAtTick = completedAtTick
        self.physicalReceiptID = physicalReceiptID.map { String($0.prefix(160)) }
        self.sourceEventID = sourceEventID
        self.reason = String(reason.prefix(240))
    }
}

public struct AgentAutonomousActivityRecord: Codable, Equatable, Sendable {
    public let activity: AgentAutonomousActivity
    public let outcome: AgentAutonomousActivityOutcome
}

public struct AgentAutonomousActivityCooldown: Codable, Equatable, Sendable {
    public let actorID: AgentID
    public let candidateID: String
    public let logicalActivityKey: String
    public let physicalAttemptFingerprint: String
    public let failureFingerprint: String
    public let failureCategory: String
    public let untilTick: Int

    public init(
        actorID: AgentID,
        candidateID: String,
        logicalActivityKey: String = "",
        physicalAttemptFingerprint: String = "",
        failureFingerprint: String = "",
        failureCategory: String = "legacy",
        untilTick: Int
    ) {
        self.actorID = actorID
        self.candidateID = String(candidateID.prefix(160))
        self.logicalActivityKey = String(logicalActivityKey.prefix(80))
        self.physicalAttemptFingerprint = String(
            physicalAttemptFingerprint.prefix(80)
        )
        self.failureFingerprint = String(failureFingerprint.prefix(80))
        self.failureCategory = String(failureCategory.prefix(120))
        self.untilTick = untilTick
    }

    private enum CodingKeys: String, CodingKey {
        case actorID
        case candidateID
        case logicalActivityKey
        case physicalAttemptFingerprint
        case failureFingerprint
        case failureCategory
        case untilTick
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            actorID: try values.decode(AgentID.self, forKey: .actorID),
            candidateID: try values.decode(String.self, forKey: .candidateID),
            logicalActivityKey: try values.decodeIfPresent(
                String.self, forKey: .logicalActivityKey
            ) ?? "",
            physicalAttemptFingerprint: try values.decodeIfPresent(
                String.self, forKey: .physicalAttemptFingerprint
            ) ?? "",
            failureFingerprint: try values.decodeIfPresent(
                String.self, forKey: .failureFingerprint
            ) ?? "",
            failureCategory: try values.decodeIfPresent(
                String.self, forKey: .failureCategory
            ) ?? "legacy",
            untilTick: try values.decode(Int.self, forKey: .untilTick)
        )
    }
}

public struct AgentAutonomousActivityCounters: Codable, Equatable, Sendable {
    public internal(set) var decisionCount = 0
    public internal(set) var candidateCount = 0
    public internal(set) var startCount = 0
    public internal(set) var completionCount = 0
    public internal(set) var blockCount = 0
    public internal(set) var switchCount = 0
    public internal(set) var commitmentSelectionCount = 0
    public internal(set) var needSelectionCount = 0
    public internal(set) var careSelectionCount = 0
    public internal(set) var replacementSelectionCount = 0
    public internal(set) var manualProductiveTriggerCount = 0
    public internal(set) var currentIdleTicks = 0
    public internal(set) var longestIdleTicks = 0

    public init() {}
}

public struct AgentAutonomousActivityState: Codable, Equatable, Sendable {
    public let configuration: AgentAutonomousActivityConfiguration
    public internal(set) var activeActivities: [AgentAutonomousActivity]
    public internal(set) var recentRecords: [AgentAutonomousActivityRecord]
    public internal(set) var cooldowns: [AgentAutonomousActivityCooldown]
    public internal(set) var counters: AgentAutonomousActivityCounters
    public internal(set) var evictionCount: Int
    public internal(set) var productiveSourceState: AgentProductiveSourceState?

    public init(configuration: AgentAutonomousActivityConfiguration) {
        self.configuration = configuration
        activeActivities = []
        recentRecords = []
        cooldowns = []
        counters = AgentAutonomousActivityCounters()
        evictionCount = 0
        productiveSourceState = nil
    }

    private enum CodingKeys: String, CodingKey {
        case configuration
        case activeActivities
        case recentRecords
        case cooldowns
        case counters
        case evictionCount
        case productiveSourceState
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        configuration = try values.decode(
            AgentAutonomousActivityConfiguration.self,
            forKey: .configuration
        )
        activeActivities = try values.decode(
            [AgentAutonomousActivity].self, forKey: .activeActivities
        )
        recentRecords = try values.decode(
            [AgentAutonomousActivityRecord].self, forKey: .recentRecords
        )
        cooldowns = try values.decode(
            [AgentAutonomousActivityCooldown].self, forKey: .cooldowns
        )
        counters = try values.decode(
            AgentAutonomousActivityCounters.self, forKey: .counters
        )
        evictionCount = try values.decode(Int.self, forKey: .evictionCount)
        productiveSourceState = try values.decodeIfPresent(
            AgentProductiveSourceState.self, forKey: .productiveSourceState
        )
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(configuration, forKey: .configuration)
        try values.encode(activeActivities, forKey: .activeActivities)
        try values.encode(recentRecords, forKey: .recentRecords)
        try values.encode(cooldowns, forKey: .cooldowns)
        try values.encode(counters, forKey: .counters)
        try values.encode(evictionCount, forKey: .evictionCount)
        try values.encodeIfPresent(
            productiveSourceState, forKey: .productiveSourceState
        )
    }
}

public struct AgentAutonomousActivitySnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let activeActivities: [AgentAutonomousActivity]
    public let recentRecords: [AgentAutonomousActivityRecord]
    public let cooldowns: [AgentAutonomousActivityCooldown]
    public let counters: AgentAutonomousActivityCounters
    public let evictionCount: Int
}
