public enum AgentHouseholdError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case lifecycleRequired
    case kinshipRequired
    case alreadyEnabled
    case unsafeDisable
    case invalidResident(AgentID)
    case unknownAgent(AgentID)
    case unknownHousehold(AgentHouseholdID)
    case dissolvedHousehold(AgentHouseholdID)
    case emptyMemberList
    case duplicateMember(AgentID)
    case noOp
    case householdCapacityReached
    case activeHouseholdCapacityReached
    case memberCapacityReached(AgentHouseholdID)
    case membershipPeriodCapacityReached
    case transitionCapacityReached
    case ordinalOverflow
    case duplicateHousehold(AgentHouseholdID)
    case duplicateOrdinal(AgentHouseholdOrdinal)
    case overlappingMembership(AgentID)
    case invalidMembership(AgentID)
    case projectionMismatch(AgentID)
    case invalidCausalReference(AgentCausalEventID)
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason): return "invalid household configuration: \(reason)"
        case .causalLedgerRequired: return "households require the causal ledger"
        case .populationRequired: return "households require population"
        case .lifecycleRequired: return "households require lifecycle"
        case .kinshipRequired: return "households require kinship"
        case .alreadyEnabled: return "households already enabled"
        case .unsafeDisable: return "household disable refused while durable state exists"
        case let .invalidResident(id): return "invalid household resident \(id.rawValue)"
        case let .unknownAgent(id): return "unknown household agent \(id.rawValue)"
        case let .unknownHousehold(id): return "unknown household \(id.rawValue)"
        case let .dissolvedHousehold(id): return "dissolved household \(id.rawValue)"
        case .emptyMemberList: return "household member list is empty"
        case let .duplicateMember(id): return "duplicate household member \(id.rawValue)"
        case .noOp: return "household transition is a no-op"
        case .householdCapacityReached: return "historical household capacity reached"
        case .activeHouseholdCapacityReached: return "active household capacity reached"
        case let .memberCapacityReached(id): return "household member capacity reached for \(id.rawValue)"
        case .membershipPeriodCapacityReached: return "membership period capacity reached"
        case .transitionCapacityReached: return "household transition capacity reached"
        case .ordinalOverflow: return "household ordinal overflow"
        case let .duplicateHousehold(id): return "duplicate household \(id.rawValue)"
        case let .duplicateOrdinal(ordinal): return "duplicate household ordinal \(ordinal.rawValue)"
        case let .overlappingMembership(id): return "overlapping household membership for \(id.rawValue)"
        case let .invalidMembership(id): return "invalid household membership for \(id.rawValue)"
        case let .projectionMismatch(id): return "household home projection mismatch for \(id.rawValue)"
        case let .invalidCausalReference(id): return "invalid household causal reference \(id.rawValue)"
        case let .invalidState(reason): return "invalid household state: \(reason)"
        }
    }
}

public struct AgentHouseholdID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue.hasPrefix("household_"), rawValue.utf8.count <= 64,
              let suffix = Int(rawValue.dropFirst("household_".count)), suffix >= 0,
              rawValue == "household_\(suffix)" else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentHouseholdID, rhs: AgentHouseholdID) -> Bool {
        let left = Int(lhs.rawValue.dropFirst("household_".count))!
        let right = Int(rhs.rawValue.dropFirst("household_".count))!
        return left < right
    }
}

public struct AgentHouseholdOrdinal: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: Int

    public init?(rawValue: Int) {
        guard rawValue >= 0 else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentHouseholdOrdinal, rhs: AgentHouseholdOrdinal) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentHouseholdStatus: String, Codable, CaseIterable, Sendable {
    case active
    case dissolved
}

public enum AgentHouseholdMembershipReason: String, Codable, CaseIterable, Sendable {
    case initialization
    case formedHousehold
    case joinedHousehold
    case birth
    case migrationAdmission
    case leftForNewHousehold
    case death
    case householdDissolution
}

public struct AgentHouseholdConfiguration: Codable, Equatable, Sendable {
    public let maximumHistoricalHouseholds: Int
    public let maximumMembershipPeriods: Int
    public let maximumActiveHouseholds: Int
    public let maximumMembersPerHousehold: Int
    public let maximumHouseholdTransitionsPerTick: Int

    public init(
        maximumHistoricalHouseholds: Int = 256,
        maximumMembershipPeriods: Int = 2048,
        maximumActiveHouseholds: Int = 64,
        maximumMembersPerHousehold: Int = 16,
        maximumHouseholdTransitionsPerTick: Int = 16
    ) throws {
        guard (1...4096).contains(maximumHistoricalHouseholds) else {
            throw AgentHouseholdError.invalidConfiguration("historical households")
        }
        guard (1...32_768).contains(maximumMembershipPeriods) else {
            throw AgentHouseholdError.invalidConfiguration("membership periods")
        }
        guard (1...512).contains(maximumActiveHouseholds),
              maximumActiveHouseholds <= maximumHistoricalHouseholds else {
            throw AgentHouseholdError.invalidConfiguration("active households")
        }
        guard (1...64).contains(maximumMembersPerHousehold) else {
            throw AgentHouseholdError.invalidConfiguration("members per household")
        }
        guard (1...256).contains(maximumHouseholdTransitionsPerTick) else {
            throw AgentHouseholdError.invalidConfiguration("transitions per tick")
        }
        self.maximumHistoricalHouseholds = maximumHistoricalHouseholds
        self.maximumMembershipPeriods = maximumMembershipPeriods
        self.maximumActiveHouseholds = maximumActiveHouseholds
        self.maximumMembersPerHousehold = maximumMembersPerHousehold
        self.maximumHouseholdTransitionsPerTick = maximumHouseholdTransitionsPerTick
    }

    public static let live = try! AgentHouseholdConfiguration()
}

public struct AgentHouseholdRecord: Codable, Equatable, Sendable {
    public let householdID: AgentHouseholdID
    public let ordinal: AgentHouseholdOrdinal
    public let settlementID: AgentSettlementID
    public let residenceAnchor: AgentPosition
    public let createdTick: Int
    public let createdEventID: AgentCausalEventID
    public internal(set) var status: AgentHouseholdStatus
    public internal(set) var dissolvedTick: Int?
    public internal(set) var lastHouseholdEventID: AgentCausalEventID
}

public struct AgentHouseholdMembershipPeriod: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let householdID: AgentHouseholdID
    public let joinedTick: Int
    public let joinedEventID: AgentCausalEventID
    public let joinedReason: AgentHouseholdMembershipReason
    public internal(set) var leftTick: Int?
    public internal(set) var leftEventID: AgentCausalEventID?
    public internal(set) var leftReason: AgentHouseholdMembershipReason?
}

public struct AgentHouseholdState: Codable, Equatable, Sendable {
    public let configuration: AgentHouseholdConfiguration
    public internal(set) var households: [AgentHouseholdRecord]
    public internal(set) var membershipPeriods: [AgentHouseholdMembershipPeriod]
    public internal(set) var nextHouseholdOrdinal: AgentHouseholdOrdinal
    public internal(set) var totalHistoricalHouseholdCount: Int
    public internal(set) var totalMembershipPeriodCount: Int
    public internal(set) var transitionTick: Int
    public internal(set) var transitionsAtTick: Int
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastHouseholdEventID: AgentCausalEventID
}

public struct AgentCurrentHouseholdMembership: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let householdID: AgentHouseholdID
    public let residenceAnchor: AgentPosition
    public let joinedTick: Int
    public let joinedReason: AgentHouseholdMembershipReason
}

public struct AgentHouseholdSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentHouseholdConfiguration?
    public let households: [AgentHouseholdRecord]
    public let membershipPeriods: [AgentHouseholdMembershipPeriod]
    public let currentMemberships: [AgentCurrentHouseholdMembership]
    public let nextHouseholdOrdinal: Int?
    public let totalHistoricalHouseholdCount: Int
    public let totalMembershipPeriodCount: Int
    public let digest: String
}

public enum AgentHouseholdDigest {
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
