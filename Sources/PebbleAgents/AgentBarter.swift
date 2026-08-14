public enum AgentBarterError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration
    case causalLedgerRequired
    case materialRightsRequired
    case productionRequired
    case disabled
    case unsafeDisable
    case unknownAgent(AgentID)
    case invalidOpportunity(String)
    case invalidOffer(String)
    case invalidDecision(String)
    case invalidOutcome(String)
    case staleOffer(String)
    case unauthorized(String)
    case duplicateOperation(String)
    case capacityReached(String)
    case invalidState(String)

    public var description: String {
        switch self {
        case .invalidConfiguration: return "invalid barter configuration"
        case .causalLedgerRequired: return "barter requires causal ledger"
        case .materialRightsRequired: return "barter requires material rights"
        case .productionRequired: return "barter requires production provenance"
        case .disabled: return "barter disabled"
        case .unsafeDisable: return "barter disable refused while durable state exists"
        case let .unknownAgent(id): return "unknown barter agent \(id.rawValue)"
        case let .invalidOpportunity(id): return "invalid barter opportunity \(id)"
        case let .invalidOffer(id): return "invalid barter offer \(id)"
        case let .invalidDecision(id): return "invalid barter decision \(id)"
        case let .invalidOutcome(id): return "invalid barter outcome \(id)"
        case let .staleOffer(id): return "stale barter offer \(id)"
        case let .unauthorized(reason): return "unauthorized barter: \(reason)"
        case let .duplicateOperation(id): return "duplicate barter operation \(id)"
        case let .capacityReached(kind): return "barter capacity reached \(kind)"
        case let .invalidState(reason): return "invalid barter state \(reason)"
        }
    }
}

public struct AgentBarterOfferID: RawRepresentable, Codable, Hashable,
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

public struct AgentBarterConfiguration: Codable, Equatable, Sendable {
    public let maximumOpportunities: Int
    public let maximumOffers: Int
    public let maximumRecords: Int
    public let maximumProcessedOperations: Int
    public let offerLifetimeTicks: Int
    public let maximumLocalDistance: Int

    public init(
        maximumOpportunities: Int = 32,
        maximumOffers: Int = 32,
        maximumRecords: Int = 256,
        maximumProcessedOperations: Int = 512,
        offerLifetimeTicks: Int = 4,
        maximumLocalDistance: Int = 8
    ) throws {
        guard (1...256).contains(maximumOpportunities),
              (1...256).contains(maximumOffers),
              (1...4096).contains(maximumRecords),
              (1...4096).contains(maximumProcessedOperations),
              (1...32).contains(offerLifetimeTicks),
              (1...32).contains(maximumLocalDistance) else {
            throw AgentBarterError.invalidConfiguration
        }
        self.maximumOpportunities = maximumOpportunities
        self.maximumOffers = maximumOffers
        self.maximumRecords = maximumRecords
        self.maximumProcessedOperations = maximumProcessedOperations
        self.offerLifetimeTicks = offerLifetimeTicks
        self.maximumLocalDistance = maximumLocalDistance
    }

    public static let live = try! AgentBarterConfiguration()
}

/// Binds a proposed side to a current Pebble observation. It is a description
/// and reservation key only; it is never an inventory or a transfer authority.
public struct AgentBarterLeg: Codable, Equatable, Sendable {
    public let assetID: AgentMaterialAssetID
    public let holderID: AgentID
    public let material: AgentMaterialStackSnapshot
    public let holderObservation: AgentMaterialHolderObservation
    public let productionOperationIDs: [String]

    public init(
        assetID: AgentMaterialAssetID,
        holderID: AgentID,
        material: AgentMaterialStackSnapshot,
        holderObservation: AgentMaterialHolderObservation,
        productionOperationIDs: [String] = []
    ) {
        self.assetID = assetID
        self.holderID = holderID
        self.material = material
        self.holderObservation = holderObservation
        self.productionOperationIDs = productionOperationIDs.sorted()
    }
}

public struct AgentBarterValueReason: Codable, Equatable, Sendable {
    public let needID: AgentProductionNeedID
    public let reason: AgentProductionNeedReason
    public let desiredItemKey: String
    public let quantity: Int
    public let causalEventID: AgentCausalEventID

    public init(need: AgentProductionNeed) {
        needID = need.needID
        reason = need.reason
        desiredItemKey = need.desiredOutputItemKey
        quantity = need.quantity
        causalEventID = need.causalEventID
    }
}

/// Bounded, co-located observation supplied by Pebble. No settlement scan or
/// global price is represented here.
public struct AgentBarterOpportunityObservation: Codable, Equatable, Sendable {
    public let opportunityID: String
    public let offerorID: AgentID
    public let counterpartyID: AgentID
    public let offered: AgentBarterLeg
    public let requested: AgentBarterLeg
    public let offerorReason: AgentBarterValueReason
    public let counterpartyReason: AgentBarterValueReason
    public let distance: Int
    public let lineOfSight: Bool
    public let chunksReady: Bool
    public let observedAtTick: Int
    public let expiresAtTick: Int

    public init(
        opportunityID: String,
        offerorID: AgentID,
        counterpartyID: AgentID,
        offered: AgentBarterLeg,
        requested: AgentBarterLeg,
        offerorReason: AgentBarterValueReason,
        counterpartyReason: AgentBarterValueReason,
        distance: Int,
        lineOfSight: Bool,
        chunksReady: Bool,
        observedAtTick: Int,
        expiresAtTick: Int
    ) {
        self.opportunityID = String(opportunityID.prefix(160))
        self.offerorID = offerorID
        self.counterpartyID = counterpartyID
        self.offered = offered
        self.requested = requested
        self.offerorReason = offerorReason
        self.counterpartyReason = counterpartyReason
        self.distance = distance
        self.lineOfSight = lineOfSight
        self.chunksReady = chunksReady
        self.observedAtTick = observedAtTick
        self.expiresAtTick = expiresAtTick
    }
}

public enum AgentBarterOfferStatus: String, Codable, CaseIterable, Sendable {
    case open
    case accepted
    case rejected
    case withdrawn
    case expired
    case stale
    case failed
    case completed

    public var isPending: Bool { self == .open || self == .accepted }
}

public struct AgentBarterOffer: Codable, Equatable, Sendable {
    public let offerID: AgentBarterOfferID
    public let opportunity: AgentBarterOpportunityObservation
    public let offeredAtTick: Int
    public let expiresAtTick: Int
    public internal(set) var status: AgentBarterOfferStatus
    public let offerEventID: AgentCausalEventID
    public internal(set) var decisionEventID: AgentCausalEventID?
    public internal(set) var terminalReason: String?
}

public struct AgentVerifiedBarterLeg: Codable, Equatable, Sendable {
    public let assetID: AgentMaterialAssetID
    public let sourceObservation: AgentMaterialHolderObservation
    public let destinationObservation: AgentMaterialHolderObservation
    public let physicalReceiptID: String

    public init(
        assetID: AgentMaterialAssetID,
        sourceObservation: AgentMaterialHolderObservation,
        destinationObservation: AgentMaterialHolderObservation,
        physicalReceiptID: String
    ) {
        self.assetID = assetID
        self.sourceObservation = sourceObservation
        self.destinationObservation = destinationObservation
        self.physicalReceiptID = physicalReceiptID
    }
}

public struct AgentVerifiedBarterOutcome: Codable, Equatable, Sendable {
    public let operationID: String
    public let offerID: AgentBarterOfferID
    public let offeredLeg: AgentVerifiedBarterLeg
    public let requestedLeg: AgentVerifiedBarterLeg
    public let completedAtTick: Int

    public init(
        operationID: String,
        offerID: AgentBarterOfferID,
        offeredLeg: AgentVerifiedBarterLeg,
        requestedLeg: AgentVerifiedBarterLeg,
        completedAtTick: Int
    ) {
        self.operationID = operationID
        self.offerID = offerID
        self.offeredLeg = offeredLeg
        self.requestedLeg = requestedLeg
        self.completedAtTick = completedAtTick
    }
}

public struct AgentBarterRecord: Codable, Equatable, Sendable {
    public let offer: AgentBarterOffer
    public let outcome: AgentVerifiedBarterOutcome
    public let causalEventID: AgentCausalEventID
}

public struct AgentBarterState: Codable, Equatable, Sendable {
    public let configuration: AgentBarterConfiguration
    public internal(set) var opportunities: [AgentBarterOpportunityObservation]
    public internal(set) var offers: [AgentBarterOffer]
    public internal(set) var records: [AgentBarterRecord]
    public internal(set) var processedOperationIDs: [String]
    public internal(set) var totalCompletedCount: Int
    public internal(set) var evictionCount: Int
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastBarterEventID: AgentCausalEventID
}

public struct AgentBarterSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentBarterConfiguration?
    public let opportunities: [AgentBarterOpportunityObservation]
    public let offers: [AgentBarterOffer]
    public let records: [AgentBarterRecord]
    public let totalCompletedCount: Int
    public let pendingOfferCount: Int
    public let evictionCount: Int
}
