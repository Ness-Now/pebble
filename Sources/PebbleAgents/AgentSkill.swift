public enum AgentSkillError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case lifecycleRequired
    case alreadyEnabled
    case unsafeDisable
    case unknownAgent(AgentID)
    case inactiveAgent(AgentID)
    case invalidPracticeUnits(Int)
    case invalidSourceEvent(AgentCausalEventID)
    case duplicateSourceEvent(AgentCausalEventID)
    case profileCapacityReached
    case creditsPerTickReached
    case invalidCausalReference(AgentCausalEventID)
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason): return "invalid skill configuration: \(reason)"
        case .causalLedgerRequired: return "skills require the causal ledger"
        case .populationRequired: return "skills require population"
        case .lifecycleRequired: return "skills require lifecycle"
        case .alreadyEnabled: return "skills already enabled"
        case .unsafeDisable: return "skill disable refused while durable state exists"
        case let .unknownAgent(id): return "unknown skill agent \(id.rawValue)"
        case let .inactiveAgent(id): return "inactive skill agent \(id.rawValue)"
        case let .invalidPracticeUnits(units): return "invalid practice units \(units)"
        case let .invalidSourceEvent(id): return "invalid skill source event \(id.rawValue)"
        case let .duplicateSourceEvent(id): return "skill source already credited \(id.rawValue)"
        case .profileCapacityReached: return "skill profile capacity reached"
        case .creditsPerTickReached: return "skill practice credits per tick reached"
        case let .invalidCausalReference(id): return "invalid skill causal reference \(id.rawValue)"
        case let .invalidState(reason): return "invalid skill state: \(reason)"
        }
    }
}

public enum AgentSkillDomain: String, Codable, CaseIterable, Comparable, Sendable {
    case foraging
    case materialHandling
    case construction
    case caregiving

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentSkillLevel: String, Codable, CaseIterable, Comparable, Sendable {
    case untrained
    case novice
    case practiced
    case skilled

    public init(practiceUnits: Int) {
        switch practiceUnits {
        case ...0: self = .untrained
        case 1...2: self = .novice
        case 3...5: self = .practiced
        default: self = .skilled
        }
    }

    private var rank: Int {
        switch self {
        case .untrained: return 0
        case .novice: return 1
        case .practiced: return 2
        case .skilled: return 3
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rank < rhs.rank }
}

public struct AgentSkillConfiguration: Codable, Equatable, Sendable {
    public let maximumProfiles: Int
    public let maximumRetainedPracticeRecords: Int
    public let maximumPracticeRecordsPerAgent: Int
    public let maximumPracticeCreditsPerTick: Int
    public let maximumPracticeUnitsPerCredit: Int

    public init(
        maximumProfiles: Int = 512,
        maximumRetainedPracticeRecords: Int = 1024,
        maximumPracticeRecordsPerAgent: Int = 128,
        maximumPracticeCreditsPerTick: Int = 32,
        maximumPracticeUnitsPerCredit: Int = 4
    ) throws {
        guard (1...4096).contains(maximumProfiles) else {
            throw AgentSkillError.invalidConfiguration("profiles")
        }
        guard (1...16_384).contains(maximumRetainedPracticeRecords) else {
            throw AgentSkillError.invalidConfiguration("retained practice records")
        }
        guard (1...2048).contains(maximumPracticeRecordsPerAgent),
              maximumPracticeRecordsPerAgent <= maximumRetainedPracticeRecords else {
            throw AgentSkillError.invalidConfiguration("practice records per agent")
        }
        guard (1...512).contains(maximumPracticeCreditsPerTick) else {
            throw AgentSkillError.invalidConfiguration("practice credits per tick")
        }
        guard (1...16).contains(maximumPracticeUnitsPerCredit) else {
            throw AgentSkillError.invalidConfiguration("practice units per credit")
        }
        self.maximumProfiles = maximumProfiles
        self.maximumRetainedPracticeRecords = maximumRetainedPracticeRecords
        self.maximumPracticeRecordsPerAgent = maximumPracticeRecordsPerAgent
        self.maximumPracticeCreditsPerTick = maximumPracticeCreditsPerTick
        self.maximumPracticeUnitsPerCredit = maximumPracticeUnitsPerCredit
    }

    public static let live = try! AgentSkillConfiguration()
}

public struct AgentSkillDomainPractice: Codable, Equatable, Sendable {
    public let domain: AgentSkillDomain
    public internal(set) var practiceUnits: Int
    public internal(set) var lastPracticeTick: Int
    public internal(set) var lastSourceSuccessEventID: AgentCausalEventID
    public internal(set) var lastSkillPracticeEventID: AgentCausalEventID
}

public struct AgentSkillProfile: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public internal(set) var domainPractices: [AgentSkillDomainPractice]

    public func practiceUnits(in domain: AgentSkillDomain) -> Int {
        domainPractices.first { $0.domain == domain }?.practiceUnits ?? 0
    }
}

public struct AgentSkillPracticeRecord: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let domain: AgentSkillDomain
    public let practiceUnits: Int
    public let cumulativePracticeUnits: Int
    public let tick: Int
    public let sourceSuccessEventID: AgentCausalEventID
    public let skillPracticeEventID: AgentCausalEventID
    public let sourceKind: AgentCausalEventKind
    public let sourceStatus: String
}

public struct AgentSkillEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var practiceRecords: Int

    public init(practiceRecords: Int = 0) {
        self.practiceRecords = practiceRecords
    }
}

public struct AgentSkillState: Codable, Equatable, Sendable {
    public let configuration: AgentSkillConfiguration
    public internal(set) var profiles: [AgentSkillProfile]
    public internal(set) var retainedPracticeRecords: [AgentSkillPracticeRecord]
    public internal(set) var totalPracticeCreditCount: Int
    public internal(set) var totalPracticeUnits: Int
    public internal(set) var evictionCounts: AgentSkillEvictionCounts
    public internal(set) var evictedPracticeDigest: String
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastSkillEventID: AgentCausalEventID
    public internal(set) var lastCreditedSourceEventID: AgentCausalEventID?
    public internal(set) var transitionTick: Int
    public internal(set) var creditsAtTick: Int
}

public struct AgentSkillSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentSkillConfiguration?
    public let profiles: [AgentSkillProfile]
    public let retainedPracticeRecords: [AgentSkillPracticeRecord]
    public let totalPracticeCreditCount: Int
    public let totalPracticeUnits: Int
    public let evictionCounts: AgentSkillEvictionCounts
    public let evictedPracticeDigest: String
    public let digest: String
}

public enum AgentSkillDigest {
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
