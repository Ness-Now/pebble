public enum AgentMarketError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration
    case causalLedgerRequired
    case materialRightsRequired
    case productionRequired
    case disabled
    case unsafeDisable
    case unknownAgent(AgentID)
    case unknownMarket(AgentMarketID)
    case invalidMarket(String)
    case invalidOpportunity(String)
    case invalidDeposit(String)
    case invalidListing(String)
    case invalidProposal(String)
    case invalidOutcome(String)
    case staleAuthority(String)
    case unauthorized(String)
    case duplicateOperation(String)
    case capacityReached(String)
    case invalidState(String)

    public var description: String {
        switch self {
        case .invalidConfiguration: return "invalid market configuration"
        case .causalLedgerRequired: return "markets require causal ledger"
        case .materialRightsRequired: return "markets require Material Rights"
        case .productionRequired: return "markets require current material needs"
        case .disabled: return "markets disabled"
        case .unsafeDisable: return "market disable refused while durable state exists"
        case let .unknownAgent(id): return "unknown market agent \(id.rawValue)"
        case let .unknownMarket(id): return "unknown market \(id.rawValue)"
        case let .invalidMarket(id): return "invalid market \(id)"
        case let .invalidOpportunity(id): return "invalid market opportunity \(id)"
        case let .invalidDeposit(id): return "invalid market deposit \(id)"
        case let .invalidListing(id): return "invalid market listing \(id)"
        case let .invalidProposal(id): return "invalid market proposal \(id)"
        case let .invalidOutcome(id): return "invalid market outcome \(id)"
        case let .staleAuthority(id): return "stale market authority \(id)"
        case let .unauthorized(reason): return "unauthorized market operation: \(reason)"
        case let .duplicateOperation(id): return "duplicate market operation \(id)"
        case let .capacityReached(kind): return "market capacity reached \(kind)"
        case let .invalidState(reason): return "invalid market state \(reason)"
        }
    }
}

public protocol AgentMarketStringID: RawRepresentable, Codable, Hashable,
    Comparable, Sendable where RawValue == String {}

public extension AgentMarketStringID {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

private func validAgentMarketID(_ rawValue: String) -> Bool {
    (1...160).contains(rawValue.count)
        && rawValue.allSatisfy {
            $0.isASCII && ($0.isLetter || $0.isNumber || "-_:.".contains($0))
        }
}

public struct AgentMarketID: AgentMarketStringID {
    public let rawValue: String
    public init?(rawValue: String) {
        guard validAgentMarketID(rawValue) else { return nil }
        self.rawValue = rawValue
    }
}

public struct AgentMarketDepositID: AgentMarketStringID {
    public let rawValue: String
    public init?(rawValue: String) {
        guard validAgentMarketID(rawValue) else { return nil }
        self.rawValue = rawValue
    }
}

public struct AgentMarketListingID: AgentMarketStringID {
    public let rawValue: String
    public init?(rawValue: String) {
        guard validAgentMarketID(rawValue) else { return nil }
        self.rawValue = rawValue
    }
}

public struct AgentMarketProposalID: AgentMarketStringID {
    public let rawValue: String
    public init?(rawValue: String) {
        guard validAgentMarketID(rawValue) else { return nil }
        self.rawValue = rawValue
    }
}

public struct AgentMarketTradeID: AgentMarketStringID {
    public let rawValue: String
    public init?(rawValue: String) {
        guard validAgentMarketID(rawValue) else { return nil }
        self.rawValue = rawValue
    }
}

public struct AgentMarketConfiguration: Codable, Equatable, Sendable {
    public let maximumMarkets: Int
    public let maximumDepositOpportunities: Int
    public let maximumDeposits: Int
    public let maximumListings: Int
    public let maximumProposals: Int
    public let maximumTradeRecords: Int
    public let maximumPriceHistoryRows: Int
    public let maximumWithdrawals: Int
    public let maximumProcessedOperations: Int
    public let listingLifetimeTicks: Int
    public let maximumLocalDistance: Int

    public init(
        maximumMarkets: Int = 4,
        maximumDepositOpportunities: Int = 32,
        maximumDeposits: Int = 32,
        maximumListings: Int = 32,
        maximumProposals: Int = 64,
        maximumTradeRecords: Int = 128,
        maximumPriceHistoryRows: Int = 64,
        maximumWithdrawals: Int = 128,
        maximumProcessedOperations: Int = 512,
        listingLifetimeTicks: Int = 4,
        maximumLocalDistance: Int = 8
    ) throws {
        guard (1...16).contains(maximumMarkets),
              (1...256).contains(maximumDepositOpportunities),
              (1...256).contains(maximumDeposits),
              (1...256).contains(maximumListings),
              (1...512).contains(maximumProposals),
              (1...1024).contains(maximumTradeRecords),
              (1...1024).contains(maximumPriceHistoryRows),
              (1...1024).contains(maximumWithdrawals),
              (1...4096).contains(maximumProcessedOperations),
              (2...32).contains(listingLifetimeTicks),
              (1...32).contains(maximumLocalDistance) else {
            throw AgentMarketError.invalidConfiguration
        }
        self.maximumMarkets = maximumMarkets
        self.maximumDepositOpportunities = maximumDepositOpportunities
        self.maximumDeposits = maximumDeposits
        self.maximumListings = maximumListings
        self.maximumProposals = maximumProposals
        self.maximumTradeRecords = maximumTradeRecords
        self.maximumPriceHistoryRows = maximumPriceHistoryRows
        self.maximumWithdrawals = maximumWithdrawals
        self.maximumProcessedOperations = maximumProcessedOperations
        self.listingLifetimeTicks = listingLifetimeTicks
        self.maximumLocalDistance = maximumLocalDistance
    }

    public static let live = try! AgentMarketConfiguration()
    public var maximumDiscoveryAgents: Int { min(8, maximumDepositOpportunities) }
    public var maximumPhysicalGoodsPerAgent: Int { min(4, maximumDeposits) }
    public var maximumDepositDiscoveriesPerTick: Int {
        min(4, maximumDepositOpportunities)
    }
    public var maximumBuyerObservationsPerTick: Int { min(16, maximumProposals) }
}

public enum AgentMarketPlaceStatus: String, Codable, CaseIterable, Sendable {
    case active
    case stale
}

public struct AgentMarketPlace: Codable, Equatable, Sendable {
    public let marketID: AgentMarketID
    public let position: AgentPosition
    public let containerLocationID: String
    public let containerBlockFingerprint: Int
    public let interactionRadius: Int
    public let physicalSlotCapacity: Int
    public let registeredAtTick: Int
    public internal(set) var status: AgentMarketPlaceStatus
    public let causalEventID: AgentCausalEventID
}

public struct AgentMarketDepositOpportunity: Codable, Equatable, Sendable {
    public let opportunityID: String
    public let marketID: AgentMarketID
    public let sellerID: AgentID
    public let offered: AgentBarterLeg
    public let quoteReason: AgentBarterValueReason
    public let marketPosition: AgentPosition
    public let containerLocationID: String
    public let currentContainerFingerprint: String
    public let physicalSlotCapacity: Int
    public let physicalOccupiedSlots: Int
    public let distance: Int
    public let chunksReady: Bool
    public let observedAtTick: Int
    public let expiresAtTick: Int

    public init(
        opportunityID: String, marketID: AgentMarketID, sellerID: AgentID,
        offered: AgentBarterLeg, quoteReason: AgentBarterValueReason,
        marketPosition: AgentPosition, containerLocationID: String,
        currentContainerFingerprint: String, physicalSlotCapacity: Int,
        physicalOccupiedSlots: Int, distance: Int, chunksReady: Bool,
        observedAtTick: Int, expiresAtTick: Int
    ) {
        self.opportunityID = opportunityID
        self.marketID = marketID
        self.sellerID = sellerID
        self.offered = offered
        self.quoteReason = quoteReason
        self.marketPosition = marketPosition
        self.containerLocationID = containerLocationID
        self.currentContainerFingerprint = currentContainerFingerprint
        self.physicalSlotCapacity = physicalSlotCapacity
        self.physicalOccupiedSlots = physicalOccupiedSlots
        self.distance = distance
        self.chunksReady = chunksReady
        self.observedAtTick = observedAtTick
        self.expiresAtTick = expiresAtTick
    }
}

public struct AgentMarketDepositProposal: Codable, Equatable, Sendable {
    public let depositID: AgentMarketDepositID
    public let opportunityID: String
    public let sellerID: AgentID
    public let reason: String

    public init(
        depositID: AgentMarketDepositID, opportunityID: String,
        sellerID: AgentID, reason: String
    ) {
        self.depositID = depositID
        self.opportunityID = opportunityID
        self.sellerID = sellerID
        self.reason = reason
    }
}

public enum AgentMarketDepositStatus: String, Codable, CaseIterable, Sendable {
    case deposited
    case listed
    case reserved
    case cancelled
    case expired
    case sold
    case withdrawn
    case stale

    public var isPhysicalInMarket: Bool {
        switch self {
        case .deposited, .listed, .reserved, .cancelled, .expired: return true
        case .sold, .withdrawn, .stale: return false
        }
    }

    public var isTerminal: Bool { self == .sold || self == .withdrawn || self == .stale }
}

public struct AgentVerifiedMarketDeposit: Codable, Equatable, Sendable {
    public let operationID: String
    public let depositID: AgentMarketDepositID
    public let opportunityID: String
    public let marketID: AgentMarketID
    public let sellerID: AgentID
    public let assetID: AgentMaterialAssetID
    public let material: AgentMaterialStackSnapshot
    public let sourceObservation: AgentMaterialHolderObservation
    public let marketObservation: AgentMaterialHolderObservation
    public let physicalReceiptID: String
    public let completedAtTick: Int

    public init(
        operationID: String, depositID: AgentMarketDepositID,
        opportunityID: String, marketID: AgentMarketID, sellerID: AgentID,
        assetID: AgentMaterialAssetID, material: AgentMaterialStackSnapshot,
        sourceObservation: AgentMaterialHolderObservation,
        marketObservation: AgentMaterialHolderObservation,
        physicalReceiptID: String, completedAtTick: Int
    ) {
        self.operationID = operationID
        self.depositID = depositID
        self.opportunityID = opportunityID
        self.marketID = marketID
        self.sellerID = sellerID
        self.assetID = assetID
        self.material = material
        self.sourceObservation = sourceObservation
        self.marketObservation = marketObservation
        self.physicalReceiptID = physicalReceiptID
        self.completedAtTick = completedAtTick
    }
}

public struct AgentMarketDeposit: Codable, Equatable, Sendable {
    public let depositID: AgentMarketDepositID
    public let marketID: AgentMarketID
    public let sellerID: AgentID
    public let assetID: AgentMaterialAssetID
    public let material: AgentMaterialStackSnapshot
    public let quoteReason: AgentBarterValueReason
    public let depositedAtTick: Int
    public let depositReceiptID: String
    public internal(set) var lastMarketObservation: AgentMaterialHolderObservation
    public internal(set) var status: AgentMarketDepositStatus
    public internal(set) var listingID: AgentMarketListingID?
    public internal(set) var terminalEventID: AgentCausalEventID?
    public let causalEventID: AgentCausalEventID
}

/// Explicit rational orientation. Base and quote are never silently inverted.
public struct AgentMarketPriceTerms: Codable, Equatable, Sendable {
    public let baseItemKey: String
    public let quoteItemKey: String
    public let baseQuantity: Int
    public let quoteQuantity: Int

    public init(
        baseItemKey: String,
        quoteItemKey: String,
        baseQuantity: Int,
        quoteQuantity: Int
    ) {
        self.baseItemKey = baseItemKey
        self.quoteItemKey = quoteItemKey
        self.baseQuantity = baseQuantity
        self.quoteQuantity = quoteQuantity
    }
}

public enum AgentMarketListingStatus: String, Codable, CaseIterable, Sendable {
    case open
    case reserved
    case completed
    case cancelled
    case expired
    case stale

    public var isPending: Bool { self == .open || self == .reserved }
    public var isTerminal: Bool { !isPending }
}

public struct AgentMarketListingProposal: Codable, Equatable, Sendable {
    public let listingID: AgentMarketListingID
    public let depositID: AgentMarketDepositID
    public let sellerID: AgentID
    public let terms: AgentMarketPriceTerms
    public let historyTradeIDs: [AgentMarketTradeID]
    public let reason: String

    public init(
        listingID: AgentMarketListingID,
        depositID: AgentMarketDepositID, sellerID: AgentID,
        terms: AgentMarketPriceTerms,
        historyTradeIDs: [AgentMarketTradeID], reason: String
    ) {
        self.listingID = listingID
        self.depositID = depositID
        self.sellerID = sellerID
        self.terms = terms
        self.historyTradeIDs = historyTradeIDs.sorted()
        self.reason = reason
    }
}

public struct AgentMarketListing: Codable, Equatable, Sendable {
    public let listingID: AgentMarketListingID
    public let depositID: AgentMarketDepositID
    public let marketID: AgentMarketID
    public let sellerID: AgentID
    public let initialTerms: AgentMarketPriceTerms
    public internal(set) var currentTerms: AgentMarketPriceTerms
    public let historyTradeIDs: [AgentMarketTradeID]
    public let historyInformed: Bool
    public let createdAtTick: Int
    public let expiresAtTick: Int
    public internal(set) var status: AgentMarketListingStatus
    public internal(set) var revisionCount: Int
    public let listingEventID: AgentCausalEventID
    public internal(set) var terminalEventID: AgentCausalEventID?
}

public struct AgentMarketBuyerObservation: Codable, Equatable, Sendable {
    public let observationID: String
    public let listingID: AgentMarketListingID
    public let buyerID: AgentID
    public let consideration: AgentBarterLeg
    public let buyerReason: AgentBarterValueReason
    public let distance: Int
    public let chunksReady: Bool
    public let observedAtTick: Int

    public init(
        observationID: String, listingID: AgentMarketListingID,
        buyerID: AgentID, consideration: AgentBarterLeg,
        buyerReason: AgentBarterValueReason, distance: Int,
        chunksReady: Bool, observedAtTick: Int
    ) {
        self.observationID = observationID
        self.listingID = listingID
        self.buyerID = buyerID
        self.consideration = consideration
        self.buyerReason = buyerReason
        self.distance = distance
        self.chunksReady = chunksReady
        self.observedAtTick = observedAtTick
    }
}

public struct AgentMarketBuyerProposal: Codable, Equatable, Sendable {
    public let proposalID: AgentMarketProposalID
    public let observation: AgentMarketBuyerObservation
    public let terms: AgentMarketPriceTerms
    public let rejectedAsk: Bool
    public let reason: String

    public init(
        proposalID: AgentMarketProposalID,
        observation: AgentMarketBuyerObservation,
        terms: AgentMarketPriceTerms, rejectedAsk: Bool, reason: String
    ) {
        self.proposalID = proposalID
        self.observation = observation
        self.terms = terms
        self.rejectedAsk = rejectedAsk
        self.reason = reason
    }
}

/// Current Pebble-owned physical evidence for one participant at a market.
///
/// This is deliberately separate from proposal observations: a proposal is
/// durable social authority, while this evidence is a same-tick report from
/// the live World boundary. PebbleAgents validates it but never reads World
/// state directly.
public struct AgentMarketParticipantLocality: Codable, Equatable, Sendable {
    public let marketID: AgentMarketID
    public let participantID: AgentID
    public let participantPhysicalID: String
    public let participantPosition: AgentPosition
    public let marketPosition: AgentPosition
    public let participantAlive: Bool
    public let participantChunkReady: Bool
    public let marketChunkReady: Bool
    public let marketContainerValid: Bool
    public let observedAtTick: Int

    public init(
        marketID: AgentMarketID, participantID: AgentID,
        participantPhysicalID: String, participantPosition: AgentPosition,
        marketPosition: AgentPosition, participantAlive: Bool,
        participantChunkReady: Bool, marketChunkReady: Bool,
        marketContainerValid: Bool, observedAtTick: Int
    ) {
        self.marketID = marketID
        self.participantID = participantID
        self.participantPhysicalID = participantPhysicalID
        self.participantPosition = participantPosition
        self.marketPosition = marketPosition
        self.participantAlive = participantAlive
        self.participantChunkReady = participantChunkReady
        self.marketChunkReady = marketChunkReady
        self.marketContainerValid = marketContainerValid
        self.observedAtTick = observedAtTick
    }
}

/// Same-tick current World evidence for both parties at a decisive market
/// boundary. Seller cognition and physical settlement each require a freshly
/// constructed value; the earlier buyer proposal is never reused as presence.
public struct AgentMarketCurrentLocalityEvidence:
    Codable, Equatable, Sendable {
    public let seller: AgentMarketParticipantLocality
    public let buyer: AgentMarketParticipantLocality

    public init(
        seller: AgentMarketParticipantLocality,
        buyer: AgentMarketParticipantLocality
    ) {
        self.seller = seller
        self.buyer = buyer
    }
}

public enum AgentMarketProposalStatus: String, Codable, CaseIterable, Sendable {
    case proposed
    case accepted
    case rejected
    case stale

    public var isPending: Bool { self == .proposed || self == .accepted }
}

public struct AgentMarketProposal: Codable, Equatable, Sendable {
    public let proposalID: AgentMarketProposalID
    public let listingID: AgentMarketListingID
    public let buyerID: AgentID
    public let consideration: AgentBarterLeg
    public let buyerReason: AgentBarterValueReason
    public let proposedTerms: AgentMarketPriceTerms
    public let rejectedAsk: Bool
    public let proposedAtTick: Int
    public internal(set) var status: AgentMarketProposalStatus
    public let proposalEventID: AgentCausalEventID
    public internal(set) var decisionEventID: AgentCausalEventID?
    public internal(set) var decisionReason: String?
}

public struct AgentMarketSellerDecision: Codable, Equatable, Sendable {
    public let proposalID: AgentMarketProposalID
    public let sellerID: AgentID
    public let accept: Bool
    public let reason: String
    /// Optional only for additive schema-34 decoding compatibility. New
    /// seller decisions are invalid unless this same-tick evidence is present.
    public let currentLocality: AgentMarketCurrentLocalityEvidence?

    public init(
        proposalID: AgentMarketProposalID, sellerID: AgentID,
        accept: Bool, reason: String,
        currentLocality: AgentMarketCurrentLocalityEvidence? = nil
    ) {
        self.proposalID = proposalID
        self.sellerID = sellerID
        self.accept = accept
        self.reason = reason
        self.currentLocality = currentLocality
    }
}

public struct AgentVerifiedMarketTradeLeg: Codable, Equatable, Sendable {
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

public struct AgentVerifiedMarketTrade: Codable, Equatable, Sendable {
    public let operationID: String
    public let tradeID: AgentMarketTradeID
    public let marketID: AgentMarketID
    public let listingID: AgentMarketListingID
    public let proposalID: AgentMarketProposalID
    public let sellerID: AgentID
    public let buyerID: AgentID
    public let terms: AgentMarketPriceTerms
    public let offeredLeg: AgentVerifiedMarketTradeLeg
    public let considerationLeg: AgentVerifiedMarketTradeLeg
    public let completedAtTick: Int

    public init(
        operationID: String, tradeID: AgentMarketTradeID,
        marketID: AgentMarketID, listingID: AgentMarketListingID,
        proposalID: AgentMarketProposalID, sellerID: AgentID,
        buyerID: AgentID, terms: AgentMarketPriceTerms,
        offeredLeg: AgentVerifiedMarketTradeLeg,
        considerationLeg: AgentVerifiedMarketTradeLeg,
        completedAtTick: Int
    ) {
        self.operationID = operationID
        self.tradeID = tradeID
        self.marketID = marketID
        self.listingID = listingID
        self.proposalID = proposalID
        self.sellerID = sellerID
        self.buyerID = buyerID
        self.terms = terms
        self.offeredLeg = offeredLeg
        self.considerationLeg = considerationLeg
        self.completedAtTick = completedAtTick
    }
}

public struct AgentMarketTradeRecord: Codable, Equatable, Sendable {
    public let trade: AgentVerifiedMarketTrade
    public let listing: AgentMarketListing
    public let proposal: AgentMarketProposal
    public let causalEventID: AgentCausalEventID
}

public struct AgentMarketPriceObservation: Codable, Equatable, Sendable {
    public let marketID: AgentMarketID
    public let tradeID: AgentMarketTradeID
    public let terms: AgentMarketPriceTerms
    public let sellerID: AgentID
    public let buyerID: AgentID
    public let completedAtTick: Int
    public let physicalReceiptIDs: [String]
    public let causalEventID: AgentCausalEventID
}

public struct AgentVerifiedMarketWithdrawal: Codable, Equatable, Sendable {
    public let operationID: String
    public let depositID: AgentMarketDepositID
    public let marketID: AgentMarketID
    public let sellerID: AgentID
    public let assetID: AgentMaterialAssetID
    public let sourceObservation: AgentMaterialHolderObservation
    public let destinationObservation: AgentMaterialHolderObservation
    public let physicalReceiptID: String
    public let completedAtTick: Int

    public init(
        operationID: String, depositID: AgentMarketDepositID,
        marketID: AgentMarketID, sellerID: AgentID,
        assetID: AgentMaterialAssetID,
        sourceObservation: AgentMaterialHolderObservation,
        destinationObservation: AgentMaterialHolderObservation,
        physicalReceiptID: String, completedAtTick: Int
    ) {
        self.operationID = operationID
        self.depositID = depositID
        self.marketID = marketID
        self.sellerID = sellerID
        self.assetID = assetID
        self.sourceObservation = sourceObservation
        self.destinationObservation = destinationObservation
        self.physicalReceiptID = physicalReceiptID
        self.completedAtTick = completedAtTick
    }
}

public struct AgentMarketWithdrawalRecord: Codable, Equatable, Sendable {
    public let outcome: AgentVerifiedMarketWithdrawal
    public let causalEventID: AgentCausalEventID
}

public struct AgentMarketState: Codable, Equatable, Sendable {
    public let configuration: AgentMarketConfiguration
    public internal(set) var markets: [AgentMarketPlace]
    public internal(set) var depositOpportunities: [AgentMarketDepositOpportunity]
    public internal(set) var deposits: [AgentMarketDeposit]
    public internal(set) var listings: [AgentMarketListing]
    public internal(set) var proposals: [AgentMarketProposal]
    public internal(set) var tradeRecords: [AgentMarketTradeRecord]
    public internal(set) var priceHistory: [AgentMarketPriceObservation]
    public internal(set) var withdrawals: [AgentMarketWithdrawalRecord]
    public internal(set) var processedOperationIDs: [String]
    public internal(set) var totalDepositCount: Int
    public internal(set) var totalTradeCount: Int
    public internal(set) var totalWithdrawalCount: Int
    public internal(set) var evictionCount: Int
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastMarketEventID: AgentCausalEventID
}

public struct AgentMarketSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentMarketConfiguration?
    public let markets: [AgentMarketPlace]
    public let depositOpportunities: [AgentMarketDepositOpportunity]
    public let deposits: [AgentMarketDeposit]
    public let listings: [AgentMarketListing]
    public let proposals: [AgentMarketProposal]
    public let tradeRecords: [AgentMarketTradeRecord]
    public let priceHistory: [AgentMarketPriceObservation]
    public let withdrawals: [AgentMarketWithdrawalRecord]
    public let totalDepositCount: Int
    public let totalTradeCount: Int
    public let totalWithdrawalCount: Int
    public let evictionCount: Int
}
