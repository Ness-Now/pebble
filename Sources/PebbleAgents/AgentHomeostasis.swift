public enum AgentVitalStatus: String, Codable, CaseIterable, Sendable {
    case alive
    case incapacitated
    case dead
}

public enum AgentHealthCondition: String, Codable, CaseIterable, Sendable {
    case stable
    case strained
    case impaired
    case critical
    case incapacitated
    case dead
}

public enum AgentHealthTrend: String, Codable, CaseIterable, Sendable {
    case stable
    case worsening
    case recovering
}

public enum AgentPhysiologicalFactorCode: String, Codable, CaseIterable, Sendable {
    case hunger
    case fatigue
    case compoundedDeprivation
    case ageVulnerability
    case nourishment
    case rest
    case phenotypeExpression
}

public enum AgentPhysiologicalAgeBand: String, Codable, CaseIterable, Sendable {
    case dependent
    case juvenile
    case prime
    case laterLife
}

public enum AgentHomeostasisError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case survivalRequired
    case mortalityRequired
    case lifecycleRequired
    case populationRequired
    case alreadyEnabled
    case disabled
    case unsafeDisable
    case unknownAgent(AgentID)
    case profileLimitReached
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason):
            return "invalid homeostasis configuration: \(reason)"
        case .causalLedgerRequired: return "homeostasis requires the causal ledger"
        case .survivalRequired: return "homeostasis requires survival"
        case .mortalityRequired: return "homeostasis requires mortality"
        case .lifecycleRequired: return "homeostasis requires lifecycle"
        case .populationRequired: return "homeostasis requires population"
        case .alreadyEnabled: return "homeostasis already enabled"
        case .disabled: return "homeostasis disabled"
        case .unsafeDisable: return "homeostasis disable refused after durable state"
        case let .unknownAgent(id): return "unknown homeostasis agent \(id.rawValue)"
        case .profileLimitReached: return "homeostasis profile limit reached"
        case let .invalidState(reason): return "invalid homeostasis state: \(reason)"
        }
    }
}

public struct AgentHomeostasisConfiguration: Codable, Equatable, Sendable {
    public let maximumProfiles: Int
    public let maximumFactorsPerProfile: Int
    public let maximumEpisodesPerProfile: Int
    public let maximumRetainedTransitions: Int
    public let ageVulnerabilityStartTicks: Int
    public let ageVulnerabilityPerTickBasisPoints: Int
    public let maximumAgeVulnerabilityBasisPoints: Int
    public let recoveryPerTick: Int
    public let stressRecoveryPerTick: Int
    public let baseHealthDamagePerTick: Int
    public let healthRecoveryPerTick: Int
    public let incapacityHealthThreshold: Int

    public init(
        maximumProfiles: Int = 256,
        maximumFactorsPerProfile: Int = 6,
        maximumEpisodesPerProfile: Int = 16,
        maximumRetainedTransitions: Int = 256,
        ageVulnerabilityStartTicks: Int = 16,
        ageVulnerabilityPerTickBasisPoints: Int = 250,
        maximumAgeVulnerabilityBasisPoints: Int = 5_000,
        recoveryPerTick: Int = 1_200,
        stressRecoveryPerTick: Int = 1_000,
        baseHealthDamagePerTick: Int = 8,
        healthRecoveryPerTick: Int = 3,
        incapacityHealthThreshold: Int = 20
    ) throws {
        guard (1...512).contains(maximumProfiles) else {
            throw AgentHomeostasisError.invalidConfiguration("profiles")
        }
        guard (1...AgentPhysiologicalFactorCode.allCases.count).contains(
            maximumFactorsPerProfile
        ) else {
            throw AgentHomeostasisError.invalidConfiguration("factors")
        }
        guard (1...64).contains(maximumEpisodesPerProfile) else {
            throw AgentHomeostasisError.invalidConfiguration("episodes")
        }
        guard (1...1024).contains(maximumRetainedTransitions) else {
            throw AgentHomeostasisError.invalidConfiguration("transitions")
        }
        guard (1...1_000_000).contains(ageVulnerabilityStartTicks),
              (1...2_000).contains(ageVulnerabilityPerTickBasisPoints),
              (0...10_000).contains(maximumAgeVulnerabilityBasisPoints) else {
            throw AgentHomeostasisError.invalidConfiguration("age vulnerability")
        }
        guard (1...5_000).contains(recoveryPerTick),
              (1...5_000).contains(stressRecoveryPerTick),
              (1...100).contains(baseHealthDamagePerTick),
              (1...25).contains(healthRecoveryPerTick),
              (1...99).contains(incapacityHealthThreshold) else {
            throw AgentHomeostasisError.invalidConfiguration("rates")
        }
        self.maximumProfiles = maximumProfiles
        self.maximumFactorsPerProfile = maximumFactorsPerProfile
        self.maximumEpisodesPerProfile = maximumEpisodesPerProfile
        self.maximumRetainedTransitions = maximumRetainedTransitions
        self.ageVulnerabilityStartTicks = ageVulnerabilityStartTicks
        self.ageVulnerabilityPerTickBasisPoints = ageVulnerabilityPerTickBasisPoints
        self.maximumAgeVulnerabilityBasisPoints = maximumAgeVulnerabilityBasisPoints
        self.recoveryPerTick = recoveryPerTick
        self.stressRecoveryPerTick = stressRecoveryPerTick
        self.baseHealthDamagePerTick = baseHealthDamagePerTick
        self.healthRecoveryPerTick = healthRecoveryPerTick
        self.incapacityHealthThreshold = incapacityHealthThreshold
    }

    public static let live = try! AgentHomeostasisConfiguration()
}

public struct AgentPhysiologicalFactor: Codable, Equatable, Sendable {
    public let code: AgentPhysiologicalFactorCode
    public let severityBasisPoints: Int
    public let harmful: Bool
    public let source: String

    public init(
        code: AgentPhysiologicalFactorCode,
        severityBasisPoints: Int,
        harmful: Bool,
        source: String
    ) {
        self.code = code
        self.severityBasisPoints = min(10_000, max(0, severityBasisPoints))
        self.harmful = harmful
        self.source = String(source.prefix(160))
    }
}

public struct AgentHealthEpisode: Codable, Equatable, Sendable {
    public let episodeID: String
    public let cause: AgentPhysiologicalFactorCode
    public let startedAtTick: Int
    public internal(set) var endedAtTick: Int?
    public internal(set) var lastUpdatedTick: Int
    public internal(set) var worstCondition: AgentHealthCondition
    public internal(set) var trend: AgentHealthTrend
    public internal(set) var lastEventID: AgentCausalEventID
}

public struct AgentHomeostasisProfile: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public internal(set) var vitalStatus: AgentVitalStatus
    public internal(set) var condition: AgentHealthCondition
    public internal(set) var trend: AgentHealthTrend
    public internal(set) var energyReserveBasisPoints: Int
    public internal(set) var stressBasisPoints: Int
    public internal(set) var recoveryCapacityBasisPoints: Int
    public internal(set) var ageTicks: Int
    public internal(set) var lifeStage: AgentLifeStage
    public internal(set) var ageBand: AgentPhysiologicalAgeBand
    public internal(set) var ageVulnerabilityBasisPoints: Int
    public internal(set) var activeFactors: [AgentPhysiologicalFactor]
    public internal(set) var recentEpisodes: [AgentHealthEpisode]
    public internal(set) var episodeEvictionCount: Int
    public internal(set) var lastUpdatedTick: Int
    public internal(set) var lastEventID: AgentCausalEventID
}

public struct AgentHomeostasisTransition: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let tick: Int
    public let conditionBefore: AgentHealthCondition
    public let conditionAfter: AgentHealthCondition
    public let trend: AgentHealthTrend
    public let vitalStatus: AgentVitalStatus
    public let healthBefore: Int
    public let healthAfter: Int
    public let energyReserveBasisPoints: Int
    public let stressBasisPoints: Int
    public let dominantFactor: AgentPhysiologicalFactorCode?
    public let reason: String
    public let eventID: AgentCausalEventID
}

public struct AgentHomeostasisState: Codable, Equatable, Sendable {
    public let configuration: AgentHomeostasisConfiguration
    public internal(set) var profiles: [AgentHomeostasisProfile]
    public internal(set) var recentTransitions: [AgentHomeostasisTransition]
    public internal(set) var totalTransitionCount: Int
    public internal(set) var transitionEvictionCount: Int
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastEventID: AgentCausalEventID
}

public struct AgentHomeostasisSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentHomeostasisConfiguration?
    public let profiles: [AgentHomeostasisProfile]
    public let recentTransitions: [AgentHomeostasisTransition]
    public let totalTransitionCount: Int
    public let transitionEvictionCount: Int
    public let digest: String
}

public enum AgentHomeostasisDigest {
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
