public enum AgentKinshipError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case lifecycleRequired
    case alreadyEnabled
    case unsafeDisable
    case incompleteBirthHistory
    case historicalPersonCapacityReached
    case parentageCapacityReached
    case childrenPerParentCapacityReached(AgentID)
    case unknownPerson(AgentID)
    case duplicatePerson(AgentID)
    case duplicateOrdinal(AgentPopulationOrdinal)
    case invalidIdentityOrdinal(AgentID, AgentPopulationOrdinal)
    case invalidParentage(AgentID)
    case duplicateParentage(AgentID)
    case parentageRewrite(AgentID)
    case ancestryCycle(AgentID)
    case ancestryDepthLimitReached
    case projectionMismatch(AgentID)
    case invalidCausalReference(AgentCausalEventID)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason): return "invalid kinship configuration: \(reason)"
        case .causalLedgerRequired: return "kinship requires the causal ledger"
        case .populationRequired: return "kinship requires the population registry"
        case .lifecycleRequired: return "kinship requires lifecycle"
        case .alreadyEnabled: return "kinship already enabled"
        case .unsafeDisable: return "kinship disable refused while durable kinship state exists"
        case .incompleteBirthHistory: return "kinship activation requires complete birth history"
        case .historicalPersonCapacityReached: return "kinship historical person capacity reached"
        case .parentageCapacityReached: return "kinship parentage capacity reached"
        case let .childrenPerParentCapacityReached(id):
            return "kinship child capacity reached for \(id.rawValue)"
        case let .unknownPerson(id): return "unknown historical person \(id.rawValue)"
        case let .duplicatePerson(id): return "duplicate historical person \(id.rawValue)"
        case let .duplicateOrdinal(ordinal): return "duplicate historical ordinal \(ordinal.rawValue)"
        case let .invalidIdentityOrdinal(id, ordinal):
            return "invalid historical identity/ordinal \(id.rawValue)/\(ordinal.rawValue)"
        case let .invalidParentage(id): return "invalid parentage for \(id.rawValue)"
        case let .duplicateParentage(id): return "duplicate parentage for \(id.rawValue)"
        case let .parentageRewrite(id): return "parentage rewrite refused for \(id.rawValue)"
        case let .ancestryCycle(id): return "ancestry cycle through \(id.rawValue)"
        case .ancestryDepthLimitReached: return "kinship ancestry depth limit reached"
        case let .projectionMismatch(id): return "kinship projection mismatch for \(id.rawValue)"
        case let .invalidCausalReference(id): return "invalid kinship causal reference \(id.rawValue)"
        }
    }
}

public struct AgentKinshipConfiguration: Codable, Equatable, Sendable {
    public let maximumHistoricalPersons: Int
    public let maximumParentageRecords: Int
    public let maximumChildrenPerParent: Int
    public let maximumAncestryDepth: Int

    public init(
        maximumHistoricalPersons: Int = 512,
        maximumParentageRecords: Int = 256,
        maximumChildrenPerParent: Int = 16,
        maximumAncestryDepth: Int = 32
    ) throws {
        guard (3...4096).contains(maximumHistoricalPersons) else {
            throw AgentKinshipError.invalidConfiguration("historical persons")
        }
        guard (1...2048).contains(maximumParentageRecords),
              maximumParentageRecords <= maximumHistoricalPersons else {
            throw AgentKinshipError.invalidConfiguration("parentage records")
        }
        guard (1...64).contains(maximumChildrenPerParent) else {
            throw AgentKinshipError.invalidConfiguration("children per parent")
        }
        guard (1...128).contains(maximumAncestryDepth) else {
            throw AgentKinshipError.invalidConfiguration("ancestry depth")
        }
        self.maximumHistoricalPersons = maximumHistoricalPersons
        self.maximumParentageRecords = maximumParentageRecords
        self.maximumChildrenPerParent = maximumChildrenPerParent
        self.maximumAncestryDepth = maximumAncestryDepth
    }

    public static let live = try! AgentKinshipConfiguration()
}

public struct AgentHistoricalPerson: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let ordinal: AgentPopulationOrdinal

    public init(agentID: AgentID, ordinal: AgentPopulationOrdinal) {
        self.agentID = agentID
        self.ordinal = ordinal
    }
}

public struct AgentParentageRecord: Codable, Equatable, Sendable {
    public let childID: AgentID
    public let canonicalParentIDs: [AgentID]
    public let birthID: AgentBirthID
    public let birthTick: Int
    public let sourcePopulationBornEventID: AgentCausalEventID
    public let recordedEventID: AgentCausalEventID

    public init(
        childID: AgentID,
        parentIDs: [AgentID],
        birthID: AgentBirthID,
        birthTick: Int,
        sourcePopulationBornEventID: AgentCausalEventID,
        recordedEventID: AgentCausalEventID
    ) {
        self.childID = childID
        canonicalParentIDs = parentIDs.sorted()
        self.birthID = birthID
        self.birthTick = birthTick
        self.sourcePopulationBornEventID = sourcePopulationBornEventID
        self.recordedEventID = recordedEventID
    }
}

public struct AgentKinshipState: Codable, Equatable, Sendable {
    public let configuration: AgentKinshipConfiguration
    public internal(set) var historicalPersons: [AgentHistoricalPerson]
    public internal(set) var parentageRecords: [AgentParentageRecord]
    public internal(set) var totalHistoricalPersonCount: Int
    public internal(set) var totalParentageRecordCount: Int
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastKinshipEventID: AgentCausalEventID
}

public struct AgentKinshipSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentKinshipConfiguration?
    public let historicalPersons: [AgentHistoricalPerson]
    public let parentageRecords: [AgentParentageRecord]
    public let totalHistoricalPersonCount: Int
    public let totalParentageRecordCount: Int
    public let digest: String
}

public enum AgentSiblingRelation: Codable, Equatable, Sendable {
    case samePerson
    case unrelated
    case halfSibling
    case fullSibling
    case unknownParentage(AgentID)
    case unknownPerson(AgentID)
}

public enum AgentAncestryResult: Codable, Equatable, Sendable {
    case ancestor
    case notAncestor
    case depthLimitReached
    case unknownPerson(AgentID)
}

public enum AgentKinshipDigest {
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
