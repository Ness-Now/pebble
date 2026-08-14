public enum AgentContractError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration
    case causalLedgerRequired
    case materialRightsRequired
    case productionRequired
    case disabled
    case unsafeDisable
    case unknownAgent(AgentID)
    case invalidOpportunity(String)
    case invalidProposal(String)
    case invalidDecision(String)
    case invalidObligation(String)
    case invalidOutcome(String)
    case staleAuthority(String)
    case unauthorized(String)
    case duplicateOperation(String)
    case capacityReached(String)
    case invalidState(String)

    public var description: String {
        switch self {
        case .invalidConfiguration: return "invalid contract configuration"
        case .causalLedgerRequired: return "contracts require causal ledger"
        case .materialRightsRequired: return "contracts require material rights"
        case .productionRequired: return "contracts require production"
        case .disabled: return "contracts disabled"
        case .unsafeDisable: return "contract disable refused while durable state exists"
        case let .unknownAgent(id): return "unknown contract agent \(id.rawValue)"
        case let .invalidOpportunity(id): return "invalid contract opportunity \(id)"
        case let .invalidProposal(id): return "invalid promise proposal \(id)"
        case let .invalidDecision(id): return "invalid promise decision \(id)"
        case let .invalidObligation(id): return "invalid obligation \(id)"
        case let .invalidOutcome(id): return "invalid contract outcome \(id)"
        case let .staleAuthority(id): return "stale contract authority \(id)"
        case let .unauthorized(reason): return "unauthorized contract transition: \(reason)"
        case let .duplicateOperation(id): return "duplicate contract operation \(id)"
        case let .capacityReached(kind): return "contract capacity reached \(kind)"
        case let .invalidState(reason): return "invalid contract state \(reason)"
        }
    }
}

public struct AgentPromiseProposalID: RawRepresentable, Codable, Hashable,
    Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_:.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentContractObligationID: RawRepresentable, Codable, Hashable,
    Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_:.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentContractConfiguration: Codable, Equatable, Sendable {
    public let maximumOpportunities: Int
    public let maximumProposals: Int
    public let maximumObligations: Int
    public let maximumProcessedOperations: Int
    public let proposalLifetimeTicks: Int
    public let performanceDueTicks: Int
    public let maximumLocalDistance: Int

    public init(
        maximumOpportunities: Int = 32,
        maximumProposals: Int = 32,
        maximumObligations: Int = 64,
        maximumProcessedOperations: Int = 512,
        proposalLifetimeTicks: Int = 4,
        performanceDueTicks: Int = 8,
        maximumLocalDistance: Int = 8
    ) throws {
        guard (1...256).contains(maximumOpportunities),
              (1...256).contains(maximumProposals),
              (1...1024).contains(maximumObligations),
              (1...4096).contains(maximumProcessedOperations),
              (1...32).contains(proposalLifetimeTicks),
              (1...4096).contains(performanceDueTicks),
              (1...32).contains(maximumLocalDistance) else {
            throw AgentContractError.invalidConfiguration
        }
        self.maximumOpportunities = maximumOpportunities
        self.maximumProposals = maximumProposals
        self.maximumObligations = maximumObligations
        self.maximumProcessedOperations = maximumProcessedOperations
        self.proposalLifetimeTicks = proposalLifetimeTicks
        self.performanceDueTicks = performanceDueTicks
        self.maximumLocalDistance = maximumLocalDistance
    }

    public static let live = try! AgentContractConfiguration()
    public var maximumDiscoveryAgents: Int { min(8, maximumOpportunities) }
    public var maximumNearbyCounterpartiesPerAgent: Int {
        min(4, maximumDiscoveryAgents - 1)
    }
    public var maximumConsiderationGoodsPerAgent: Int { 4 }
    public var maximumDiscoveriesPerTick: Int { min(4, maximumOpportunities) }
}

/// V1 supports one deliberately narrow promise language: deliver the complete
/// quantity of one exact material identity. It is a semantic term, never stock.
public struct AgentContractPerformanceTerms: Codable, Equatable, Sendable {
    public let material: AgentMaterialStackSnapshot
    public let fullPerformanceRequired: Bool

    public init(material: AgentMaterialStackSnapshot) {
        self.material = material
        fullPerformanceRequired = true
    }
}

/// A local reasoned opportunity supplied from current Pebble observations.
/// The consideration is a current exact asset; the promised performance is
/// deliberately future-facing and carries no current custody assertion.
public struct AgentContractOpportunityObservation: Codable, Equatable, Sendable {
    public let opportunityID: String
    public let promisorID: AgentID
    public let promiseeID: AgentID
    public let consideration: AgentBarterLeg
    public let promisorReason: AgentBarterValueReason
    public let promiseeReason: AgentBarterValueReason
    public let promisedPerformance: AgentContractPerformanceTerms
    public let distance: Int
    public let lineOfSight: Bool
    public let chunksReady: Bool
    public let observedAtTick: Int
    public let expiresAtTick: Int

    public init(
        opportunityID: String,
        promisorID: AgentID,
        promiseeID: AgentID,
        consideration: AgentBarterLeg,
        promisorReason: AgentBarterValueReason,
        promiseeReason: AgentBarterValueReason,
        promisedPerformance: AgentContractPerformanceTerms,
        distance: Int,
        lineOfSight: Bool,
        chunksReady: Bool,
        observedAtTick: Int,
        expiresAtTick: Int
    ) {
        self.opportunityID = String(opportunityID.prefix(160))
        self.promisorID = promisorID
        self.promiseeID = promiseeID
        self.consideration = consideration
        self.promisorReason = promisorReason
        self.promiseeReason = promiseeReason
        self.promisedPerformance = promisedPerformance
        self.distance = distance
        self.lineOfSight = lineOfSight
        self.chunksReady = chunksReady
        self.observedAtTick = observedAtTick
        self.expiresAtTick = expiresAtTick
    }
}

public struct AgentPromiseProposalDecision: Equatable, Sendable {
    public let proposalID: AgentPromiseProposalID
    public let opportunityID: String
    public let promisorID: AgentID
    public let reason: String
}

public struct AgentPromiseAcceptanceObservation: Equatable, Sendable {
    public let proposalID: AgentPromiseProposalID
    public let promiseeID: AgentID
    public let distance: Int
    public let lineOfSight: Bool
    public let chunksReady: Bool
    public let observedAtTick: Int

    public init(
        proposalID: AgentPromiseProposalID,
        promiseeID: AgentID,
        distance: Int,
        lineOfSight: Bool,
        chunksReady: Bool,
        observedAtTick: Int
    ) {
        self.proposalID = proposalID
        self.promiseeID = promiseeID
        self.distance = distance
        self.lineOfSight = lineOfSight
        self.chunksReady = chunksReady
        self.observedAtTick = observedAtTick
    }
}

public struct AgentPromiseAcceptanceDecision: Equatable, Sendable {
    public let proposalID: AgentPromiseProposalID
    public let promiseeID: AgentID
    public let accept: Bool
    public let reason: String
}

public enum AgentPromiseProposalStatus: String, Codable, CaseIterable, Sendable {
    case open
    case accepted
    case rejected
    case withdrawn
    case expired

    public var isPending: Bool { self == .open }
}

public struct AgentPromiseProposal: Codable, Equatable, Sendable {
    public let proposalID: AgentPromiseProposalID
    public let opportunity: AgentContractOpportunityObservation
    public let proposedAtTick: Int
    public let expiresAtTick: Int
    public internal(set) var status: AgentPromiseProposalStatus
    public let proposalEventID: AgentCausalEventID
    public internal(set) var decisionEventID: AgentCausalEventID?
    public internal(set) var terminalReason: String?
}

public enum AgentContractObligationStatus: String, Codable, CaseIterable, Sendable {
    case awaitingConsideration
    case outstanding
    case overdue
    case fulfilled
    case blockedParticipantDeath

    public var isActive: Bool {
        self == .awaitingConsideration || self == .outstanding || self == .overdue
    }
    public var isDebtLike: Bool { self == .outstanding || self == .overdue }
    public var isTerminal: Bool { self == .fulfilled || self == .blockedParticipantDeath }
}

public struct AgentVerifiedContractTransfer: Codable, Equatable, Sendable {
    public let assetID: AgentMaterialAssetID
    public let sourceObservation: AgentMaterialHolderObservation
    public let destinationObservation: AgentMaterialHolderObservation
    public let physicalReceiptID: String
    public let productionOperationIDs: [String]

    public init(
        assetID: AgentMaterialAssetID,
        sourceObservation: AgentMaterialHolderObservation,
        destinationObservation: AgentMaterialHolderObservation,
        physicalReceiptID: String,
        productionOperationIDs: [String] = []
    ) {
        self.assetID = assetID
        self.sourceObservation = sourceObservation
        self.destinationObservation = destinationObservation
        self.physicalReceiptID = physicalReceiptID
        self.productionOperationIDs = productionOperationIDs.sorted()
    }
}

public struct AgentVerifiedContractConsiderationOutcome: Codable, Equatable, Sendable {
    public let operationID: String
    public let obligationID: AgentContractObligationID
    public let transfer: AgentVerifiedContractTransfer
    public let completedAtTick: Int

    public init(
        operationID: String,
        obligationID: AgentContractObligationID,
        transfer: AgentVerifiedContractTransfer,
        completedAtTick: Int
    ) {
        self.operationID = operationID
        self.obligationID = obligationID
        self.transfer = transfer
        self.completedAtTick = completedAtTick
    }
}

public struct AgentVerifiedContractFulfillmentOutcome: Codable, Equatable, Sendable {
    public let operationID: String
    public let obligationID: AgentContractObligationID
    public let transfer: AgentVerifiedContractTransfer
    public let completedAtTick: Int

    public init(
        operationID: String,
        obligationID: AgentContractObligationID,
        transfer: AgentVerifiedContractTransfer,
        completedAtTick: Int
    ) {
        self.operationID = operationID
        self.obligationID = obligationID
        self.transfer = transfer
        self.completedAtTick = completedAtTick
    }
}

public struct AgentDurableContractObligation: Codable, Equatable, Sendable {
    public let obligationID: AgentContractObligationID
    public let proposalID: AgentPromiseProposalID
    public let promisorID: AgentID
    public let promiseeID: AgentID
    public let promisedPerformance: AgentContractPerformanceTerms
    public let promisorReason: AgentBarterValueReason
    public let promiseeReason: AgentBarterValueReason
    public let acceptedAtTick: Int
    public let dueTick: Int
    public let acceptanceEventID: AgentCausalEventID
    public let obligationEventID: AgentCausalEventID
    public internal(set) var status: AgentContractObligationStatus
    public internal(set) var considerationOutcome:
        AgentVerifiedContractConsiderationOutcome?
    public internal(set) var considerationEventID: AgentCausalEventID?
    public internal(set) var fulfillmentOutcome:
        AgentVerifiedContractFulfillmentOutcome?
    public internal(set) var fulfillmentEventID: AgentCausalEventID?
    public internal(set) var terminalReason: String?
}

public struct AgentContractState: Codable, Equatable, Sendable {
    public let configuration: AgentContractConfiguration
    public internal(set) var opportunities: [AgentContractOpportunityObservation]
    public internal(set) var proposals: [AgentPromiseProposal]
    public internal(set) var obligations: [AgentDurableContractObligation]
    public internal(set) var processedOperationIDs: [String]
    public internal(set) var totalObligationCount: Int
    public internal(set) var totalFulfilledCount: Int
    public internal(set) var evictionCount: Int
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastContractEventID: AgentCausalEventID
}

public struct AgentContractSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentContractConfiguration?
    public let opportunities: [AgentContractOpportunityObservation]
    public let proposals: [AgentPromiseProposal]
    public let obligations: [AgentDurableContractObligation]
    public let totalObligationCount: Int
    public let totalFulfilledCount: Int
    public let activeObligationCount: Int
    public let outstandingDebtCount: Int
    public let evictionCount: Int
}
