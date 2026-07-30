import Foundation

public enum AgentFamilyError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case lifecycleRequired
    case kinshipRequired
    case householdsRequired
    case childhoodRequired
    case alreadyEnabled
    case unsafeDisable
    case disabled
    case unknownPerson(AgentID)
    case unavailablePerson(AgentID)
    case immaturePerson(AgentID)
    case invalidInteraction(String)
    case duplicateInteraction(String)
    case proposalCapacityReached
    case unionCapacityReached
    case invalidProposal(AgentUnionProposalID)
    case wrongProposalRecipient(AgentID)
    case prohibitedUnion(AgentID, AgentID)
    case activeUnionExists(AgentID)
    case invalidUnion(AgentUnionID)
    case lineageCapacityReached
    case duplicateLineageRoot(AgentID)
    case invalidLineageRoot(AgentID)
    case houseCapacityReached
    case membershipCapacityReached
    case invalidHouse(AgentHouseID)
    case invalidHouseFoundation
    case duplicateHouseMembership(AgentID, AgentHouseID)
    case missingHouseMembership(AgentID, AgentHouseID)
    case invalidHouseMembershipBasis
    case transitionCapacityReached
    case invalidState(String)
    case invalidCausalReference(AgentCausalEventID)

    public var description: String {
        switch self {
        case let .invalidConfiguration(value): return "invalid family configuration: \(value)"
        case .causalLedgerRequired: return "family V1 requires the causal ledger"
        case .populationRequired: return "family V1 requires population"
        case .lifecycleRequired: return "family V1 requires lifecycle"
        case .kinshipRequired: return "family V1 requires kinship"
        case .householdsRequired: return "family V1 requires households"
        case .childhoodRequired: return "family V1 requires childhood V2"
        case .alreadyEnabled: return "family V1 already enabled"
        case .unsafeDisable: return "family V1 disable refused while durable state exists"
        case .disabled: return "family V1 is disabled"
        case let .unknownPerson(id): return "unknown family person \(id.rawValue)"
        case let .unavailablePerson(id): return "unavailable family person \(id.rawValue)"
        case let .immaturePerson(id): return "immature family person \(id.rawValue)"
        case let .invalidInteraction(value): return "invalid family interaction: \(value)"
        case let .duplicateInteraction(value): return "duplicate family interaction \(value)"
        case .proposalCapacityReached: return "family proposal capacity reached"
        case .unionCapacityReached: return "family union capacity reached"
        case let .invalidProposal(id): return "invalid union proposal \(id.rawValue)"
        case let .wrongProposalRecipient(id):
            return "wrong union proposal recipient \(id.rawValue)"
        case let .prohibitedUnion(lhs, rhs):
            return "prohibited union \(lhs.rawValue)/\(rhs.rawValue)"
        case let .activeUnionExists(id): return "active union already exists for \(id.rawValue)"
        case let .invalidUnion(id): return "invalid union \(id.rawValue)"
        case .lineageCapacityReached: return "lineage capacity reached"
        case let .duplicateLineageRoot(id): return "duplicate lineage root \(id.rawValue)"
        case let .invalidLineageRoot(id): return "invalid lineage root \(id.rawValue)"
        case .houseCapacityReached: return "house capacity reached"
        case .membershipCapacityReached: return "house membership capacity reached"
        case let .invalidHouse(id): return "invalid house \(id.rawValue)"
        case .invalidHouseFoundation: return "invalid house foundation"
        case let .duplicateHouseMembership(agentID, houseID):
            return "duplicate house membership \(agentID.rawValue)/\(houseID.rawValue)"
        case let .missingHouseMembership(agentID, houseID):
            return "missing house membership \(agentID.rawValue)/\(houseID.rawValue)"
        case .invalidHouseMembershipBasis: return "invalid house membership basis"
        case .transitionCapacityReached: return "family transitions per tick capacity reached"
        case let .invalidState(value): return "invalid family state: \(value)"
        case let .invalidCausalReference(id):
            return "invalid family causal reference \(id.rawValue)"
        }
    }
}

public struct AgentUnionProposalID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable
{
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentUnionID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...96).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentLineageID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...96).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentHouseID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...96).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentFamilyInteractionKind: String, Codable, CaseIterable, Sendable {
    case unionProposal
    case unionAcceptance
    case unionSeparation
    case houseCoFoundation
    case houseJoinRequest
    case houseJoinAcceptance
}

/// A boundary receipt. Pebble creates it only after observing both live probes
/// at the current session tick. PebbleAgents verifies the immutable positions,
/// range, roles and one-use semantics without reading a World.
public struct AgentFamilyInteractionReceipt: Codable, Equatable, Sendable {
    public let receiptID: String
    public let kind: AgentFamilyInteractionKind
    public let actorID: AgentID
    public let counterpartyID: AgentID
    public let observedTick: Int
    public let actorPosition: AgentPosition
    public let counterpartyPosition: AgentPosition
    public let communicationVerified: Bool

    public init(
        receiptID: String,
        kind: AgentFamilyInteractionKind,
        actorID: AgentID,
        counterpartyID: AgentID,
        observedTick: Int,
        actorPosition: AgentPosition,
        counterpartyPosition: AgentPosition,
        communicationVerified: Bool
    ) {
        self.receiptID = receiptID
        self.kind = kind
        self.actorID = actorID
        self.counterpartyID = counterpartyID
        self.observedTick = observedTick
        self.actorPosition = actorPosition
        self.counterpartyPosition = counterpartyPosition
        self.communicationVerified = communicationVerified
    }
}

public struct AgentFamilyInteractionProof: Codable, Equatable, Sendable {
    public let eventID: AgentCausalEventID
    public let operationID: String
    public let kind: AgentFamilyInteractionKind
    public let actorID: AgentID
    public let counterpartyID: AgentID
    public let tick: Int
}

public struct AgentHouseJoinConsent: Codable, Equatable, Sendable {
    public let acceptedByID: AgentID
    public let joiningMatureSinceTick: Int
    public let request: AgentFamilyInteractionProof
    public let acceptance: AgentFamilyInteractionProof
}

public struct AgentFamilyConfiguration: Codable, Equatable, Sendable {
    public let maximumPendingProposals: Int
    public let maximumUnionHistory: Int
    public let maximumActiveUnionsPerAgent: Int
    public let maximumLineages: Int
    public let maximumLineageFoundationsPerPerson: Int
    public let maximumProjectedAncestryDepth: Int
    public let maximumHouses: Int
    public let maximumFoundersPerHouse: Int
    public let maximumMembersPerHouse: Int
    public let maximumHouseMembershipHistory: Int
    public let maximumTransitionsPerTick: Int
    public let maximumInteractionDistance: Int
    public let maximumProjectedRelationsPerPerson: Int

    public init(
        maximumPendingProposals: Int = 64,
        maximumUnionHistory: Int = 256,
        maximumActiveUnionsPerAgent: Int = 1,
        maximumLineages: Int = 512,
        maximumLineageFoundationsPerPerson: Int = 1,
        maximumProjectedAncestryDepth: Int = 4,
        maximumHouses: Int = 256,
        maximumFoundersPerHouse: Int = 2,
        maximumMembersPerHouse: Int = 256,
        maximumHouseMembershipHistory: Int = 1024,
        maximumTransitionsPerTick: Int = 64,
        maximumInteractionDistance: Int = 3,
        maximumProjectedRelationsPerPerson: Int = 256
    ) throws {
        guard (1...512).contains(maximumPendingProposals) else {
            throw AgentFamilyError.invalidConfiguration("pending proposals")
        }
        guard (1...2048).contains(maximumUnionHistory) else {
            throw AgentFamilyError.invalidConfiguration("union history")
        }
        guard maximumActiveUnionsPerAgent == 1 else {
            throw AgentFamilyError.invalidConfiguration("active unions per agent")
        }
        guard (1...4096).contains(maximumLineages) else {
            throw AgentFamilyError.invalidConfiguration("lineages")
        }
        guard maximumLineageFoundationsPerPerson == 1 else {
            throw AgentFamilyError.invalidConfiguration("lineage roots per person")
        }
        guard (1...32).contains(maximumProjectedAncestryDepth) else {
            throw AgentFamilyError.invalidConfiguration("projected ancestry depth")
        }
        guard (1...2048).contains(maximumHouses) else {
            throw AgentFamilyError.invalidConfiguration("houses")
        }
        guard (1...2).contains(maximumFoundersPerHouse) else {
            throw AgentFamilyError.invalidConfiguration("founders per house")
        }
        guard (1...4096).contains(maximumMembersPerHouse) else {
            throw AgentFamilyError.invalidConfiguration("members per house")
        }
        guard (1...8192).contains(maximumHouseMembershipHistory) else {
            throw AgentFamilyError.invalidConfiguration("house membership history")
        }
        guard (1...256).contains(maximumTransitionsPerTick) else {
            throw AgentFamilyError.invalidConfiguration("transitions per tick")
        }
        guard (1...16).contains(maximumInteractionDistance) else {
            throw AgentFamilyError.invalidConfiguration("interaction distance")
        }
        guard (1...2048).contains(maximumProjectedRelationsPerPerson) else {
            throw AgentFamilyError.invalidConfiguration("projected relations")
        }
        self.maximumPendingProposals = maximumPendingProposals
        self.maximumUnionHistory = maximumUnionHistory
        self.maximumActiveUnionsPerAgent = maximumActiveUnionsPerAgent
        self.maximumLineages = maximumLineages
        self.maximumLineageFoundationsPerPerson = maximumLineageFoundationsPerPerson
        self.maximumProjectedAncestryDepth = maximumProjectedAncestryDepth
        self.maximumHouses = maximumHouses
        self.maximumFoundersPerHouse = maximumFoundersPerHouse
        self.maximumMembersPerHouse = maximumMembersPerHouse
        self.maximumHouseMembershipHistory = maximumHouseMembershipHistory
        self.maximumTransitionsPerTick = maximumTransitionsPerTick
        self.maximumInteractionDistance = maximumInteractionDistance
        self.maximumProjectedRelationsPerPerson = maximumProjectedRelationsPerPerson
    }

    public static let live = try! AgentFamilyConfiguration()
}

public enum AgentUnionProposalStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case accepted
}

public struct AgentUnionProposal: Codable, Equatable, Sendable {
    public let proposalID: AgentUnionProposalID
    public let proposerID: AgentID
    public let recipientID: AgentID
    public let proposedTick: Int
    public let proposalReceiptID: String
    public let proposedEventID: AgentCausalEventID
    public internal(set) var status: AgentUnionProposalStatus
    public internal(set) var acceptanceTick: Int?
    public internal(set) var acceptanceReceiptID: String?
    public internal(set) var acceptedEventID: AgentCausalEventID?
    public internal(set) var unionID: AgentUnionID?
}

public enum AgentUnionStatus: String, Codable, CaseIterable, Sendable {
    case active
    case ended
}

public enum AgentUnionTerminationReason: String, Codable, CaseIterable, Sendable {
    case unilateralSeparation
    case partnerDeath
}

public struct AgentUnionRecord: Codable, Equatable, Sendable {
    public let unionID: AgentUnionID
    public let partnerIDs: [AgentID]
    public let proposalID: AgentUnionProposalID
    public let proposalTick: Int
    public let proposalEventID: AgentCausalEventID
    public let acceptanceTick: Int
    public let acceptanceEventID: AgentCausalEventID
    public let activationTick: Int
    public let activationEventID: AgentCausalEventID
    public internal(set) var status: AgentUnionStatus
    public internal(set) var terminationTick: Int?
    public internal(set) var terminationEventID: AgentCausalEventID?
    public internal(set) var terminationReason: AgentUnionTerminationReason?
    public let version: Int
}

public enum AgentLineageStatus: String, Codable, CaseIterable, Sendable {
    case historical
}

public struct AgentLineageFoundation: Codable, Equatable, Sendable {
    public let lineageID: AgentLineageID
    public let rootPersonID: AgentID
    public let foundationTick: Int
    public let foundationEventID: AgentCausalEventID
    public let status: AgentLineageStatus
    public let version: Int
}

public enum AgentHouseStatus: String, Codable, CaseIterable, Sendable {
    case active
    case inactiveHistorical
}

public enum AgentHouseMembershipBasis: String, Codable, CaseIterable, Sendable {
    case founder
    case sharedParentHouseAtBirth
    case explicitAdultJoin
}

public enum AgentHouseMembershipEndReason: String, Codable, CaseIterable, Sendable {
    case explicitAdultLeave
    case memberDeath
}

public struct AgentHouseRecord: Codable, Equatable, Sendable {
    public let houseID: AgentHouseID
    public let founderIDs: [AgentID]
    public let foundationTick: Int
    public let foundationPosition: AgentPosition
    public let foundationEventID: AgentCausalEventID
    public let cofoundingInteractionProofs: [AgentFamilyInteractionProof]?
    public internal(set) var status: AgentHouseStatus
    public internal(set) var lastEventID: AgentCausalEventID
    public let version: Int
}

public struct AgentHouseMembershipPeriod: Codable, Equatable, Sendable {
    public let houseID: AgentHouseID
    public let agentID: AgentID
    public let basis: AgentHouseMembershipBasis
    public let joinedTick: Int
    public let joinedEventID: AgentCausalEventID
    public let explicitJoinConsent: AgentHouseJoinConsent?
    public internal(set) var leftTick: Int?
    public internal(set) var leftEventID: AgentCausalEventID?
    public internal(set) var endReason: AgentHouseMembershipEndReason?
}

public struct AgentFamilyState: Codable, Equatable, Sendable {
    public let configuration: AgentFamilyConfiguration
    public internal(set) var proposals: [AgentUnionProposal]
    public internal(set) var unions: [AgentUnionRecord]
    public internal(set) var lineages: [AgentLineageFoundation]
    public internal(set) var houses: [AgentHouseRecord]
    public internal(set) var houseMembershipPeriods: [AgentHouseMembershipPeriod]
    public internal(set) var processedInteractionReceiptIDs: [String]
    public internal(set) var nextUnionOrdinal: Int
    public internal(set) var nextLineageOrdinal: Int
    public internal(set) var nextHouseOrdinal: Int
    public internal(set) var transitionTick: Int
    public internal(set) var transitionsAtTick: Int
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastFamilyEventID: AgentCausalEventID
}

public enum AgentFamilyRelationKind: String, Codable, CaseIterable, Sendable {
    case parent
    case child
    case fullSibling
    case halfSibling
    case grandparent
    case grandchild
    case ancestor
    case descendant
    case unionPartner
    case formerUnionPartner
    case coParent
}

public enum AgentFamilyRelationSource: String, Codable, CaseIterable, Sendable {
    case canonicalParentage
    case sharedCanonicalParent
    case ancestryPath
    case activeUnion
    case endedUnion
    case sharedChild
}

public struct AgentFamilyRelation: Codable, Equatable, Sendable {
    public let kind: AgentFamilyRelationKind
    public let personID: AgentID
    public let relatedPersonID: AgentID
    public let source: AgentFamilyRelationSource
    public let sourceEventID: AgentCausalEventID
    public let depth: Int?
}

public struct AgentFamilyRelationProjection: Codable, Equatable, Sendable {
    public let personID: AgentID
    public let relations: [AgentFamilyRelation]
    public let totalRelationCount: Int
    public let maximumAncestryDepthApplied: Int
    public let truncated: Bool
}

public struct AgentLineageProjection: Codable, Equatable, Sendable {
    public let lineage: AgentLineageFoundation
    public let memberIDs: [AgentID]
    public let totalDescendantCount: Int
    public let maximumDepthApplied: Int
    public let truncated: Bool
}

public struct AgentHouseProjection: Codable, Equatable, Sendable {
    public let house: AgentHouseRecord
    public let activeMemberships: [AgentHouseMembershipPeriod]
    public let livingMemberCount: Int
    public let householdIDs: [AgentHouseholdID]
}

public struct AgentFamilySnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentFamilyConfiguration?
    public let proposals: [AgentUnionProposal]
    public let unions: [AgentUnionRecord]
    public let lineages: [AgentLineageFoundation]
    public let houses: [AgentHouseRecord]
    public let houseMembershipPeriods: [AgentHouseMembershipPeriod]
    public let digest: String
}

public enum AgentFamilyDigest {
    public static func make(_ text: String) -> String {
        AgentKinshipDigest.make(text)
    }
}
