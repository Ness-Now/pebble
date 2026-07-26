public enum AgentWildSubsistenceError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case lifecycleRequired
    case skillsRequired
    case ecologicalObservationRequired
    case alreadyEnabled
    case disabled
    case unsafeDisable
    case unknownAgent(AgentID)
    case incapableAgent(AgentID)
    case noEligibleStrategy
    case opportunityCapacityReached
    case invalidOpportunity(String)
    case unknownOpportunity(AgentSubsistenceOpportunityID)
    case invalidOutcome(String)
    case duplicateAttempt(AgentSubsistenceAttemptID)
    case attemptsPerTickReached
    case invalidCausalReference(AgentCausalEventID)
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason): return "invalid wild subsistence configuration: \(reason)"
        case .causalLedgerRequired: return "wild subsistence requires the causal ledger"
        case .populationRequired: return "wild subsistence requires population"
        case .lifecycleRequired: return "wild subsistence requires lifecycle"
        case .skillsRequired: return "wild subsistence requires skills"
        case .ecologicalObservationRequired: return "wild subsistence requires ecological observation"
        case .alreadyEnabled: return "wild subsistence already enabled"
        case .disabled: return "wild subsistence disabled"
        case .unsafeDisable: return "wild subsistence disable refused while durable state exists"
        case let .unknownAgent(id): return "unknown wild subsistence agent \(id.rawValue)"
        case let .incapableAgent(id): return "wild subsistence capability refused for \(id.rawValue)"
        case .noEligibleStrategy: return "no locally observed subsistence strategy is eligible"
        case .opportunityCapacityReached: return "wild subsistence opportunity capacity reached"
        case let .invalidOpportunity(reason): return "invalid wild subsistence opportunity: \(reason)"
        case let .unknownOpportunity(id): return "unknown wild subsistence opportunity \(id.rawValue)"
        case let .invalidOutcome(reason): return "invalid wild subsistence outcome: \(reason)"
        case let .duplicateAttempt(id): return "duplicate wild subsistence attempt \(id.rawValue)"
        case .attemptsPerTickReached: return "wild subsistence attempts per tick reached"
        case let .invalidCausalReference(id): return "invalid wild subsistence causal reference \(id.rawValue)"
        case let .invalidState(reason): return "invalid wild subsistence state: \(reason)"
        }
    }
}

public struct AgentWildSubsistenceConfiguration: Codable, Equatable, Sendable {
    public let maximumActiveOpportunities: Int
    public let opportunityLifetimeTicks: Int
    public let maximumRetainedOutcomes: Int
    public let maximumProcessedAttemptIDs: Int
    public let maximumAttemptsPerTick: Int
    public let maximumPhysicalCausalIDsPerOutcome: Int
    public let maximumAcquiredItemKindsPerOutcome: Int

    public init(
        maximumActiveOpportunities: Int = 16,
        opportunityLifetimeTicks: Int = 4,
        maximumRetainedOutcomes: Int = 96,
        maximumProcessedAttemptIDs: Int = 1024,
        maximumAttemptsPerTick: Int = 8,
        maximumPhysicalCausalIDsPerOutcome: Int = 64,
        maximumAcquiredItemKindsPerOutcome: Int = 16
    ) throws {
        guard (1...128).contains(maximumActiveOpportunities) else {
            throw AgentWildSubsistenceError.invalidConfiguration("active opportunities")
        }
        guard (1...64).contains(opportunityLifetimeTicks) else {
            throw AgentWildSubsistenceError.invalidConfiguration("opportunity lifetime")
        }
        guard (1...2048).contains(maximumRetainedOutcomes) else {
            throw AgentWildSubsistenceError.invalidConfiguration("retained outcomes")
        }
        guard (maximumRetainedOutcomes...16_384).contains(maximumProcessedAttemptIDs) else {
            throw AgentWildSubsistenceError.invalidConfiguration("processed attempts")
        }
        guard (1...128).contains(maximumAttemptsPerTick) else {
            throw AgentWildSubsistenceError.invalidConfiguration("attempts per tick")
        }
        guard (1...64).contains(maximumPhysicalCausalIDsPerOutcome) else {
            throw AgentWildSubsistenceError.invalidConfiguration("physical causal IDs")
        }
        guard (1...64).contains(maximumAcquiredItemKindsPerOutcome) else {
            throw AgentWildSubsistenceError.invalidConfiguration("acquired item kinds")
        }
        self.maximumActiveOpportunities = maximumActiveOpportunities
        self.opportunityLifetimeTicks = opportunityLifetimeTicks
        self.maximumRetainedOutcomes = maximumRetainedOutcomes
        self.maximumProcessedAttemptIDs = maximumProcessedAttemptIDs
        self.maximumAttemptsPerTick = maximumAttemptsPerTick
        self.maximumPhysicalCausalIDsPerOutcome = maximumPhysicalCausalIDsPerOutcome
        self.maximumAcquiredItemKindsPerOutcome = maximumAcquiredItemKindsPerOutcome
    }

    public static let live = try! AgentWildSubsistenceConfiguration()
}

public struct AgentSubsistenceOpportunityID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "-_.:".contains($0)) }) else {
            return nil
        }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentSubsistenceAttemptID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "-_.:".contains($0)) }) else {
            return nil
        }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Agriculture participates only in the local strategy comparison. Its plan,
/// execution, and history remain owned by the separate CIV-22 domain.
public enum AgentSubsistenceStrategy: String, Codable, CaseIterable, Comparable, Sendable {
    case agriculture
    case fishing
    case hunting
    case wildGathering

    public var isWild: Bool { self != .agriculture }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentSubsistenceOpportunityStatus: String, Codable, CaseIterable, Sendable {
    case selected
    case completed
    case failed
    case interrupted
    case expired

    public var isTerminal: Bool { self != .selected }
}

public enum AgentSubsistenceOutcomeStatus: String, Codable, CaseIterable, Sendable {
    case succeeded
    case failed
    case interrupted
    case reconciled

    public var isMaterialSuccess: Bool { self == .succeeded }
}

public struct AgentSubsistenceDecisionContext: Codable, Equatable, Sendable {
    public let actorID: AgentID
    public let fishingRodAvailable: Bool
    public let huntingWeaponAvailable: Bool
    public let agricultureAvailable: Bool
    public let maximumDistance: Int
    public let subsistencePressure: Int

    public init(
        actorID: AgentID,
        fishingRodAvailable: Bool,
        huntingWeaponAvailable: Bool,
        agricultureAvailable: Bool,
        maximumDistance: Int = 16,
        subsistencePressure: Int = 50
    ) {
        self.actorID = actorID
        self.fishingRodAvailable = fishingRodAvailable
        self.huntingWeaponAvailable = huntingWeaponAvailable
        self.agricultureAvailable = agricultureAvailable
        self.maximumDistance = maximumDistance
        self.subsistencePressure = subsistencePressure
    }
}

public struct AgentSubsistenceStrategyCandidate: Codable, Equatable, Sendable {
    public let strategy: AgentSubsistenceStrategy
    public let targetKey: String
    public let targetPosition: AgentPosition
    public let sourceObservationEventID: AgentCausalEventID?
    public let distance: Int
    public let score: Int
    public let reason: String
}

public struct AgentSubsistenceOpportunity: Codable, Equatable, Sendable {
    public let opportunityID: AgentSubsistenceOpportunityID
    public let actorID: AgentID
    public let strategy: AgentSubsistenceStrategy
    public let targetKey: String
    public let lastObservedPosition: AgentPosition
    public let sourceObservationEventID: AgentCausalEventID?
    public let selectedAtTick: Int
    public let expiresAtTick: Int
    public let score: Int
    public let reason: String
    public internal(set) var status: AgentSubsistenceOpportunityStatus
    public let selectedEventID: AgentCausalEventID
    public internal(set) var terminalEventID: AgentCausalEventID?
}

/// Verified history only. Acquired summaries are deliberately non-spendable;
/// current availability must be re-read from real custody or a real container.
public struct AgentSubsistenceOutcome: Codable, Equatable, Sendable {
    public let attemptID: AgentSubsistenceAttemptID
    public let opportunityID: AgentSubsistenceOpportunityID
    public let actorID: AgentID
    public let strategy: AgentSubsistenceStrategy
    public let targetKey: String
    public let targetPosition: AgentPosition
    public let sourceObservationEventID: AgentCausalEventID?
    public let status: AgentSubsistenceOutcomeStatus
    public let physicalCausalIDs: [Int]
    public let acquiredItems: [AgentMaterialStackSnapshot]
    public let custodyFingerprint: String?
    public let attribution: String?
    public let completedAtTick: Int

    public init(
        attemptID: AgentSubsistenceAttemptID,
        opportunityID: AgentSubsistenceOpportunityID,
        actorID: AgentID,
        strategy: AgentSubsistenceStrategy,
        targetKey: String,
        targetPosition: AgentPosition,
        sourceObservationEventID: AgentCausalEventID?,
        status: AgentSubsistenceOutcomeStatus,
        physicalCausalIDs: [Int] = [],
        acquiredItems: [AgentMaterialStackSnapshot] = [],
        custodyFingerprint: String? = nil,
        attribution: String? = nil,
        completedAtTick: Int
    ) {
        self.attemptID = attemptID
        self.opportunityID = opportunityID
        self.actorID = actorID
        self.strategy = strategy
        self.targetKey = targetKey
        self.targetPosition = targetPosition
        self.sourceObservationEventID = sourceObservationEventID
        self.status = status
        self.physicalCausalIDs = physicalCausalIDs
        self.acquiredItems = acquiredItems.sorted { lhs, rhs in
            if lhs.identity.itemKey != rhs.identity.itemKey {
                return lhs.identity.itemKey < rhs.identity.itemKey
            }
            if lhs.identity.damage != rhs.identity.damage {
                return lhs.identity.damage < rhs.identity.damage
            }
            return lhs.count < rhs.count
        }
        self.custodyFingerprint = custodyFingerprint
        self.attribution = attribution
        self.completedAtTick = completedAtTick
    }

    public var acquiredQuantity: Int { acquiredItems.reduce(0) { $0 + $1.count } }
}

public struct AgentSubsistenceOutcomeRecord: Codable, Equatable, Sendable {
    public let outcome: AgentSubsistenceOutcome
    public let subsistenceEventID: AgentCausalEventID
    public let skillPracticeEventID: AgentCausalEventID?
    public let digest: String
}

public struct AgentWildSubsistenceEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var opportunities: Int
    public internal(set) var outcomes: Int
    public internal(set) var processedAttemptIDs: Int

    public init(opportunities: Int = 0, outcomes: Int = 0, processedAttemptIDs: Int = 0) {
        self.opportunities = opportunities
        self.outcomes = outcomes
        self.processedAttemptIDs = processedAttemptIDs
    }
}

public struct AgentWildSubsistenceState: Equatable, Sendable {
    public let configuration: AgentWildSubsistenceConfiguration
    public internal(set) var opportunities: [AgentSubsistenceOpportunity]
    public internal(set) var retainedOutcomes: [AgentSubsistenceOutcomeRecord]
    public internal(set) var processedAttemptIDs: [AgentSubsistenceAttemptID]
    public internal(set) var totalOpportunityCount: Int
    public internal(set) var totalAttemptCount: Int
    public internal(set) var successfulCounts: [AgentSubsistenceStrategy: Int]
    public internal(set) var evictionCounts: AgentWildSubsistenceEvictionCounts
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastSubsistenceEventID: AgentCausalEventID
    public internal(set) var transitionTick: Int
    public internal(set) var attemptsAtTick: Int
}

extension AgentWildSubsistenceState: Codable {
    private enum CodingKeys: String, CodingKey {
        case configuration
        case opportunities
        case retainedOutcomes
        case processedAttemptIDs
        case totalOpportunityCount
        case totalAttemptCount
        case successfulCounts
        case evictionCounts
        case rollingDigest
        case initializedEventID
        case lastSubsistenceEventID
        case transitionTick
        case attemptsAtTick
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        configuration = try values.decode(
            AgentWildSubsistenceConfiguration.self,
            forKey: .configuration
        )
        opportunities = try values.decode(
            [AgentSubsistenceOpportunity].self,
            forKey: .opportunities
        )
        retainedOutcomes = try values.decode(
            [AgentSubsistenceOutcomeRecord].self,
            forKey: .retainedOutcomes
        )
        processedAttemptIDs = try values.decode(
            [AgentSubsistenceAttemptID].self,
            forKey: .processedAttemptIDs
        )
        totalOpportunityCount = try values.decode(
            Int.self,
            forKey: .totalOpportunityCount
        )
        totalAttemptCount = try values.decode(
            Int.self,
            forKey: .totalAttemptCount
        )
        var successfulCountValues = try values.nestedUnkeyedContainer(
            forKey: .successfulCounts
        )
        var decodedSuccessfulCounts: [AgentSubsistenceStrategy: Int] = [:]
        while !successfulCountValues.isAtEnd {
            let strategy = try successfulCountValues.decode(
                AgentSubsistenceStrategy.self
            )
            let count = try successfulCountValues.decode(Int.self)
            guard decodedSuccessfulCounts[strategy] == nil else {
                throw DecodingError.dataCorruptedError(
                    in: successfulCountValues,
                    debugDescription: "duplicate wild subsistence success strategy"
                )
            }
            decodedSuccessfulCounts[strategy] = count
        }
        successfulCounts = decodedSuccessfulCounts
        evictionCounts = try values.decode(
            AgentWildSubsistenceEvictionCounts.self,
            forKey: .evictionCounts
        )
        rollingDigest = try values.decode(String.self, forKey: .rollingDigest)
        initializedEventID = try values.decode(
            AgentCausalEventID.self,
            forKey: .initializedEventID
        )
        lastSubsistenceEventID = try values.decode(
            AgentCausalEventID.self,
            forKey: .lastSubsistenceEventID
        )
        transitionTick = try values.decode(Int.self, forKey: .transitionTick)
        attemptsAtTick = try values.decode(Int.self, forKey: .attemptsAtTick)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(configuration, forKey: .configuration)
        try values.encode(opportunities, forKey: .opportunities)
        try values.encode(retainedOutcomes, forKey: .retainedOutcomes)
        try values.encode(processedAttemptIDs, forKey: .processedAttemptIDs)
        try values.encode(totalOpportunityCount, forKey: .totalOpportunityCount)
        try values.encode(totalAttemptCount, forKey: .totalAttemptCount)
        var successfulCountValues = values.nestedUnkeyedContainer(
            forKey: .successfulCounts
        )
        for strategy in successfulCounts.keys.sorted() {
            try successfulCountValues.encode(strategy)
            try successfulCountValues.encode(successfulCounts[strategy]!)
        }
        try values.encode(evictionCounts, forKey: .evictionCounts)
        try values.encode(rollingDigest, forKey: .rollingDigest)
        try values.encode(initializedEventID, forKey: .initializedEventID)
        try values.encode(lastSubsistenceEventID, forKey: .lastSubsistenceEventID)
        try values.encode(transitionTick, forKey: .transitionTick)
        try values.encode(attemptsAtTick, forKey: .attemptsAtTick)
    }
}

public struct AgentWildSubsistenceSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentWildSubsistenceConfiguration?
    public let opportunities: [AgentSubsistenceOpportunity]
    public let retainedOutcomes: [AgentSubsistenceOutcomeRecord]
    public let totalOpportunityCount: Int
    public let totalAttemptCount: Int
    public let successfulCounts: [AgentSubsistenceStrategy: Int]
    public let evictionCounts: AgentWildSubsistenceEvictionCounts
    public let digest: String
}

public enum AgentWildSubsistenceDigest {
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
