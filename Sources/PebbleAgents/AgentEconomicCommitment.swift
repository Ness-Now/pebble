public enum AgentEconomicCommitmentError: Error, Equatable,
    CustomStringConvertible, Sendable {
    case incompatibleLiveCommitment(
        assetID: AgentMaterialAssetID,
        existingLogicalOperationIDs: [String],
        attemptedLogicalOperationID: String
    )
    case invalidContinuation(
        assetID: AgentMaterialAssetID,
        logicalOperationID: String
    )
    case invalidDerivedState(
        assetID: AgentMaterialAssetID,
        logicalOperationIDs: [String]
    )

    public var description: String {
        switch self {
        case let .incompatibleLiveCommitment(assetID, existing, attempted):
            return "exact asset \(assetID.rawValue) already committed by "
                + "\(existing.joined(separator: ",")); refused \(attempted)"
        case let .invalidContinuation(assetID, operationID):
            return "exact asset \(assetID.rawValue) is not exclusively committed "
                + "to continuation \(operationID)"
        case let .invalidDerivedState(assetID, operationIDs):
            return "exact asset \(assetID.rawValue) has incompatible live "
                + "commitments \(operationIDs.joined(separator: ","))"
        }
    }
}

public enum AgentEconomicCommitmentDomain: String, Codable, Equatable,
    Comparable, Sendable {
    case barter
    case contract
    case market

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentEconomicCommitmentRole: String, Codable, Equatable,
    Comparable, Sendable {
    case barterOffered
    case barterRequested
    case contractConsideration
    case marketOfferedDeposit
    case marketBuyerConsideration

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A bounded projection derived from canonical live economic state.
///
/// This is civilization authority only: it can refuse a conflicting economic
/// publication, but it cannot establish physical custody or authorize a World
/// mutation. Pebble must still supply current exact physical evidence and
/// Material Rights must still allow the requested disposition.
public struct AgentExactAssetCommitment: Codable, Equatable, Sendable {
    public let assetID: AgentMaterialAssetID
    public let domain: AgentEconomicCommitmentDomain
    public let logicalOperationID: String
    public let role: AgentEconomicCommitmentRole

    public init(
        assetID: AgentMaterialAssetID,
        domain: AgentEconomicCommitmentDomain,
        logicalOperationID: String,
        role: AgentEconomicCommitmentRole
    ) {
        self.assetID = assetID
        self.domain = domain
        self.logicalOperationID = logicalOperationID
        self.role = role
    }
}

extension AgentSimulationSession {
    /// One deterministic, bounded answer across the currently implemented
    /// Gate E exact-asset domains. No redundant commitment state is persisted.
    public func exactAssetCommitmentSnapshot()
        -> [AgentExactAssetCommitment] {
        var result: [AgentExactAssetCommitment] = []

        if let state = barterState {
            for offer in state.offers where offer.status.isPending {
                let operationID = "barter:\(offer.offerID.rawValue)"
                result.append(AgentExactAssetCommitment(
                    assetID: offer.opportunity.offered.assetID,
                    domain: .barter, logicalOperationID: operationID,
                    role: .barterOffered
                ))
                result.append(AgentExactAssetCommitment(
                    assetID: offer.opportunity.requested.assetID,
                    domain: .barter, logicalOperationID: operationID,
                    role: .barterRequested
                ))
            }
        }

        if let state = contractState {
            for proposal in state.proposals where proposal.status == .open {
                result.append(AgentExactAssetCommitment(
                    assetID: proposal.opportunity.consideration.assetID,
                    domain: .contract,
                    logicalOperationID: "contract:\(proposal.proposalID.rawValue)",
                    role: .contractConsideration
                ))
            }
            for obligation in state.obligations where
                obligation.status == .awaitingConsideration {
                guard let proposal = state.proposals.first(where: {
                    $0.proposalID == obligation.proposalID
                }) else { continue }
                result.append(AgentExactAssetCommitment(
                    assetID: proposal.opportunity.consideration.assetID,
                    domain: .contract,
                    logicalOperationID: "contract:\(proposal.proposalID.rawValue)",
                    role: .contractConsideration
                ))
            }
        }

        if let state = marketState {
            for deposit in state.deposits where !deposit.status.isTerminal {
                result.append(AgentExactAssetCommitment(
                    assetID: deposit.assetID, domain: .market,
                    logicalOperationID: "market-deposit:\(deposit.depositID.rawValue)",
                    role: .marketOfferedDeposit
                ))
            }
            for proposal in state.proposals {
                guard let listing = state.listings.first(where: {
                    $0.listingID == proposal.listingID
                }), let deposit = state.deposits.first(where: {
                    $0.depositID == listing.depositID
                }) else { continue }
                let live: Bool
                switch proposal.status {
                case .proposed:
                    live = listing.status == .open && deposit.status == .listed
                case .accepted:
                    live = listing.status == .reserved
                        && deposit.status == .reserved
                case .rejected, .stale:
                    live = false
                }
                if live {
                    result.append(AgentExactAssetCommitment(
                        assetID: proposal.consideration.assetID,
                        domain: .market,
                        logicalOperationID:
                            "market-proposal:\(proposal.proposalID.rawValue)",
                        role: .marketBuyerConsideration
                    ))
                }
            }
        }

        return result.sorted { lhs, rhs in
            if lhs.assetID != rhs.assetID { return lhs.assetID < rhs.assetID }
            if lhs.domain != rhs.domain { return lhs.domain < rhs.domain }
            if lhs.logicalOperationID != rhs.logicalOperationID {
                return lhs.logicalOperationID < rhs.logicalOperationID
            }
            return lhs.role < rhs.role
        }
    }

    public func exactAssetIsEconomicallyCommitted(
        _ assetID: AgentMaterialAssetID
    ) -> Bool {
        exactAssetCommitmentSnapshot().contains { $0.assetID == assetID }
    }

    func prevalidateNewExactAssetCommitment(
        assetID: AgentMaterialAssetID,
        logicalOperationID: String
    ) throws {
        let existing = exactAssetCommitmentSnapshot().filter {
            $0.assetID == assetID
        }.map(\.logicalOperationID)
        guard existing.isEmpty else {
            throw AgentSessionError.economicCommitment(
                .incompatibleLiveCommitment(
                    assetID: assetID,
                    existingLogicalOperationIDs: Array(Set(existing)).sorted(),
                    attemptedLogicalOperationID: logicalOperationID
                )
            )
        }
    }

    func prevalidateExactAssetCommitmentContinuation(
        assetID: AgentMaterialAssetID,
        logicalOperationID: String
    ) throws {
        let existing = exactAssetCommitmentSnapshot().filter {
            $0.assetID == assetID
        }
        guard !existing.isEmpty,
              existing.allSatisfy({
                  $0.logicalOperationID == logicalOperationID
              }) else {
            throw AgentSessionError.economicCommitment(
                .invalidContinuation(
                    assetID: assetID,
                    logicalOperationID: logicalOperationID
                )
            )
        }
    }

    func validateComposedExactAssetCommitments() throws {
        let grouped = Dictionary(grouping: exactAssetCommitmentSnapshot()) {
            $0.assetID
        }
        for assetID in grouped.keys.sorted() {
            let operationIDs = Array(Set(
                grouped[assetID, default: []].map(\.logicalOperationID)
            )).sorted()
            guard operationIDs.count <= 1 else {
                throw AgentSessionError.economicCommitment(
                    .invalidDerivedState(
                        assetID: assetID,
                        logicalOperationIDs: operationIDs
                    )
                )
            }
        }
    }

    public func prevalidateAcceptedBarterCommitment(
        offerID: AgentBarterOfferID
    ) throws {
        guard let offer = barterState?.offers.first(where: {
            $0.offerID == offerID && $0.status == .accepted
        }) else {
            throw AgentSessionError.barter(.staleOffer(offerID.rawValue))
        }
        let operationID = "barter:\(offerID.rawValue)"
        try prevalidateExactAssetCommitmentContinuation(
            assetID: offer.opportunity.offered.assetID,
            logicalOperationID: operationID
        )
        try prevalidateExactAssetCommitmentContinuation(
            assetID: offer.opportunity.requested.assetID,
            logicalOperationID: operationID
        )
    }

    public func prevalidateMarketWithdrawalCommitment(
        depositID: AgentMarketDepositID
    ) throws {
        guard let deposit = marketState?.deposits.first(where: {
            $0.depositID == depositID
                && ($0.status == .cancelled || $0.status == .expired)
        }) else {
            throw AgentSessionError.market(.invalidDeposit(depositID.rawValue))
        }
        try prevalidateExactAssetCommitmentContinuation(
            assetID: deposit.assetID,
            logicalOperationID: "market-deposit:\(depositID.rawValue)"
        )
    }
}
