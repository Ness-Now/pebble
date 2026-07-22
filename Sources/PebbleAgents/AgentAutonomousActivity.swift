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

/// A pure cognition input. It may contain stable registry names and positions,
/// but never a World, Entity, ItemStack, registry number, pointer, or closure.
public struct AgentAutonomousActivityCandidate: Codable, Equatable, Sendable {
    public let candidateID: String
    public let actorID: AgentID
    public let domain: AgentAutonomousActivityDomain
    public let actionKey: String
    public let stableReference: String
    public let target: AgentPosition?
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
        self.source = source
        self.priorityBand = max(0, min(100, priorityBand))
        self.urgency = max(0, min(100, urgency))
        self.continuity = continuity
        self.distance = max(0, distance)
        self.commitmentID = commitmentID
        self.observedAtTick = observedAtTick
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
    public let untilTick: Int
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

    public init(configuration: AgentAutonomousActivityConfiguration) {
        self.configuration = configuration
        activeActivities = []
        recentRecords = []
        cooldowns = []
        counters = AgentAutonomousActivityCounters()
        evictionCount = 0
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
