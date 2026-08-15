extension AgentSimulationSession {
    public var marketEnabled: Bool { marketState != nil }

    public func marketSnapshot() -> AgentMarketSnapshot {
        guard let state = marketState else {
            return AgentMarketSnapshot(
                enabled: false, configuration: nil, markets: [],
                depositOpportunities: [], deposits: [], listings: [], proposals: [],
                tradeRecords: [], priceHistory: [], withdrawals: [],
                totalDepositCount: 0, totalTradeCount: 0,
                totalWithdrawalCount: 0, evictionCount: 0
            )
        }
        return AgentMarketSnapshot(
            enabled: true, configuration: state.configuration,
            markets: state.markets.sorted { $0.marketID < $1.marketID },
            depositOpportunities: state.depositOpportunities.sorted {
                $0.opportunityID < $1.opportunityID
            },
            deposits: state.deposits.sorted { $0.depositID < $1.depositID },
            listings: state.listings.sorted { $0.listingID < $1.listingID },
            proposals: state.proposals.sorted { $0.proposalID < $1.proposalID },
            tradeRecords: state.tradeRecords.sorted {
                $0.trade.tradeID < $1.trade.tradeID
            },
            priceHistory: state.priceHistory.sorted {
                if $0.completedAtTick != $1.completedAtTick {
                    return $0.completedAtTick < $1.completedAtTick
                }
                return $0.tradeID < $1.tradeID
            },
            withdrawals: state.withdrawals.sorted {
                $0.outcome.depositID < $1.outcome.depositID
            },
            totalDepositCount: state.totalDepositCount,
            totalTradeCount: state.totalTradeCount,
            totalWithdrawalCount: state.totalWithdrawalCount,
            evictionCount: state.evictionCount
        )
    }

    public mutating func setMarketEnabled(
        _ enabled: Bool,
        configuration: AgentMarketConfiguration = .live
    ) throws {
        if enabled {
            guard marketState == nil else { return }
            guard causalLedger.isEnabled else {
                throw AgentSessionError.market(.causalLedgerRequired)
            }
            guard materialRightsState != nil else {
                throw AgentSessionError.market(.materialRightsRequired)
            }
            guard productionState != nil else {
                throw AgentSessionError.market(.productionRequired)
            }
            try prevalidateCausalAppend(count: 1)
            guard let event = try recordCausalEvent(
                kind: .marketsInitialized, origin: .marketTransition,
                payload: .feature(name: "physicalMarkets", enabled: true),
                summary: "physical markets initialized without creating goods or prices"
            ) else { throw AgentSessionError.market(.causalLedgerRequired) }
            marketState = AgentMarketState(
                configuration: configuration, markets: [],
                depositOpportunities: [], deposits: [], listings: [], proposals: [],
                tradeRecords: [], priceHistory: [], withdrawals: [],
                processedOperationIDs: [], totalDepositCount: 0,
                totalTradeCount: 0, totalWithdrawalCount: 0, evictionCount: 0,
                initializedEventID: event.eventID, lastMarketEventID: event.eventID
            )
        } else if marketState != nil {
            throw AgentSessionError.market(.unsafeDisable)
        }
    }

    public mutating func registerMarketPlace(
        operationID: String,
        marketID: AgentMarketID,
        position: AgentPosition,
        containerLocationID: String,
        containerBlockFingerprint: Int,
        interactionRadius: Int,
        physicalSlotCapacity: Int
    ) throws {
        try marketTransaction { session, state in
            if state.processedOperationIDs.contains(operationID) { return }
            guard session.validMarketText(operationID, maximum: 256),
                  session.validMarketText(containerLocationID, maximum: 256),
                  containerBlockFingerprint != 0,
                  (1...state.configuration.maximumLocalDistance)
                    .contains(interactionRadius),
                  (1...256).contains(physicalSlotCapacity),
                  !state.markets.contains(where: { $0.marketID == marketID }),
                  !state.markets.contains(where: {
                      $0.containerLocationID == containerLocationID
                  }) else {
                throw AgentSessionError.market(.invalidMarket(marketID.rawValue))
            }
            guard state.markets.count < state.configuration.maximumMarkets else {
                throw AgentSessionError.market(.capacityReached("markets"))
            }
            let event = try session.requiredMarketEvent(
                kind: .marketRegistered, actorID: nil,
                detail: "registered:\(marketID.rawValue):\(containerLocationID)",
                summary: "physical market registered id=\(marketID.rawValue) container=\(containerLocationID)"
            )
            state.markets.append(AgentMarketPlace(
                marketID: marketID, position: position,
                containerLocationID: containerLocationID,
                containerBlockFingerprint: containerBlockFingerprint,
                interactionRadius: interactionRadius,
                physicalSlotCapacity: physicalSlotCapacity,
                registeredAtTick: session.tick, status: .active,
                causalEventID: event.eventID
            ))
            session.retainMarketOperationID(operationID, state: &state)
            state.lastMarketEventID = event.eventID
        }
    }

    /// Accepts only bounded, current physical observations. It reserves no
    /// goods and makes no listing or price.
    public mutating func recordMarketDepositOpportunities(
        _ observations: [AgentMarketDepositOpportunity]
    ) throws {
        try marketTransaction { session, state in
            guard observations.count
                    <= state.configuration.maximumDepositDiscoveriesPerTick,
                  Set(observations.map(\.opportunityID)).count
                    == observations.count else {
                throw AgentSessionError.market(.invalidOpportunity("bounds"))
            }
            for value in observations.sorted(by: {
                $0.opportunityID < $1.opportunityID
            }) {
                try session.validateMarketDepositOpportunity(value, state: state)
                if let index = state.depositOpportunities.firstIndex(where: {
                    $0.opportunityID == value.opportunityID
                }) {
                    state.depositOpportunities[index] = value
                } else {
                    session.compactMarketOpportunities(state: &state)
                    guard state.depositOpportunities.count
                            < state.configuration.maximumDepositOpportunities else {
                        throw AgentSessionError.market(.capacityReached("opportunities"))
                    }
                    state.depositOpportunities.append(value)
                }
                let event = try session.requiredMarketEvent(
                    kind: .marketDepositObserved, actorID: value.sellerID,
                    detail: "observed:\(value.opportunityID)",
                    summary: "local market deposit observed seller=\(value.sellerID.rawValue) market=\(value.marketID.rawValue)"
                )
                state.lastMarketEventID = event.eventID
            }
        }
    }

    public func nextAutonomousMarketDepositProposal()
        -> AgentMarketDepositProposal? {
        guard let state = marketState else { return nil }
        return state.depositOpportunities.filter { opportunity in
            opportunity.observedAtTick == tick
                && opportunity.expiresAtTick >= tick
                && !opportunity.offered.assetID.isReservedInMarket(state)
        }.sorted {
            if $0.offered.assetID != $1.offered.assetID {
                return $0.offered.assetID < $1.offered.assetID
            }
            return $0.opportunityID < $1.opportunityID
        }.first.flatMap { opportunity in
            AgentMarketDepositID(rawValue: "deposit-" +
                AgentAutonomousActivityDigest.make(opportunity.opportunityID)).map {
                AgentMarketDepositProposal(
                    depositID: $0, opportunityID: opportunity.opportunityID,
                    sellerID: opportunity.sellerID,
                    reason: "current surplus offered against active local need"
                )
            }
        }
    }

    public mutating func applyVerifiedMarketDeposit(
        _ outcome: AgentVerifiedMarketDeposit
    ) throws {
        try marketTransaction { session, state in
            if state.processedOperationIDs.contains(outcome.operationID) { return }
            guard let opportunity = state.depositOpportunities.first(where: {
                $0.opportunityID == outcome.opportunityID
            }), opportunity.marketID == outcome.marketID,
                  opportunity.sellerID == outcome.sellerID,
                  opportunity.offered.assetID == outcome.assetID,
                  opportunity.offered.material == outcome.material,
                  (opportunity.observedAtTick == session.tick
                    || opportunity.observedAtTick + 1 == session.tick),
                  opportunity.expiresAtTick >= session.tick,
                  outcome.completedAtTick == session.tick,
                  outcome.sourceObservation
                    == opportunity.offered.holderObservation,
                  outcome.marketObservation.holder
                    == .container(opportunity.containerLocationID),
                  outcome.marketObservation.materialIdentity
                    == outcome.sourceObservation.materialIdentity,
                  outcome.marketObservation.quantity
                    == outcome.sourceObservation.quantity,
                  outcome.marketObservation.physicalReceiptID
                    == outcome.physicalReceiptID,
                  !state.deposits.contains(where: {
                      $0.depositID == outcome.depositID || $0.assetID == outcome.assetID
                  }) else {
                throw AgentSessionError.market(.invalidDeposit(
                    outcome.depositID.rawValue
                ))
            }
            session.compactTerminalMarketState(state: &state)
            guard state.deposits.count < state.configuration.maximumDeposits else {
                throw AgentSessionError.market(.capacityReached("deposits"))
            }
            try session.requireMarketAsset(
                outcome.assetID, owner: outcome.sellerID,
                current: outcome.sourceObservation
            )
            session.updateMarketAssetHolder(
                outcome.assetID, from: outcome.sourceObservation,
                to: outcome.marketObservation
            )
            let event = try session.requiredMarketEvent(
                kind: .marketDepositCompleted, actorID: outcome.sellerID,
                detail: "deposited:\(outcome.depositID.rawValue):\(outcome.physicalReceiptID)",
                summary: "physical market deposit completed id=\(outcome.depositID.rawValue) custody=market ownership=seller"
            )
            state.deposits.append(AgentMarketDeposit(
                depositID: outcome.depositID, marketID: outcome.marketID,
                sellerID: outcome.sellerID, assetID: outcome.assetID,
                material: outcome.material, quoteReason: opportunity.quoteReason,
                depositedAtTick: session.tick,
                depositReceiptID: outcome.physicalReceiptID,
                lastMarketObservation: outcome.marketObservation,
                status: .deposited, listingID: nil, terminalEventID: nil,
                causalEventID: event.eventID
            ))
            state.totalDepositCount += 1
            session.retainMarketOperationID(outcome.operationID, state: &state)
            state.lastMarketEventID = event.eventID
        }
    }

    public func nextAutonomousMarketListingProposal()
        -> AgentMarketListingProposal? {
        guard let state = marketState else { return nil }
        return state.deposits.filter { $0.status == .deposited }.sorted {
            $0.depositID < $1.depositID
        }.first.flatMap { deposit in
            let history = state.priceHistory.filter {
                $0.marketID == deposit.marketID
                    && $0.terms.baseItemKey == deposit.material.identity.itemKey
                    && $0.terms.quoteItemKey == deposit.quoteReason.desiredItemKey
            }.sorted {
                if $0.completedAtTick != $1.completedAtTick {
                    return $0.completedAtTick > $1.completedAtTick
                }
                return $0.tradeID > $1.tradeID
            }
            let terms = history.first?.terms ?? AgentMarketPriceTerms(
                baseItemKey: deposit.material.identity.itemKey,
                quoteItemKey: deposit.quoteReason.desiredItemKey,
                baseQuantity: deposit.material.count,
                quoteQuantity: deposit.quoteReason.quantity
            )
            return AgentMarketListingID(rawValue: "listing-" +
                AgentAutonomousActivityDigest.make(deposit.depositID.rawValue)).map {
                AgentMarketListingProposal(
                    listingID: $0, depositID: deposit.depositID,
                    sellerID: deposit.sellerID, terms: terms,
                    historyTradeIDs: history.prefix(8).map(\.tradeID).sorted(),
                    reason: history.isEmpty
                        ? "verified local deposit authorizes automatic posting; active need establishes initial local ask"
                        : "verified local deposit authorizes automatic posting; restored completed local trades inform comparable ask"
                )
            }
        }
    }

    /// Generic deterministic seller cognition. It consumes the current
    /// proposal, initial/current listing terms, the seller's current reason,
    /// same-market completed-price evidence and fresh World locality evidence.
    /// Callers do not supply acceptance authority.
    public func nextAutonomousMarketSellerDecision(
        proposalID: AgentMarketProposalID,
        currentLocality: AgentMarketCurrentLocalityEvidence
    ) throws -> AgentMarketSellerDecision {
        guard let state = marketState,
              let proposal = state.proposals.first(where: {
                  $0.proposalID == proposalID && $0.status == .proposed
              }), let listing = state.listings.first(where: {
                  $0.listingID == proposal.listingID && $0.status == .open
              }), let deposit = state.deposits.first(where: {
                  $0.depositID == listing.depositID
              }) else {
            throw AgentSessionError.market(.invalidProposal(proposalID.rawValue))
        }
        return try evaluateMarketSellerDecision(
            proposal: proposal, listing: listing, deposit: deposit,
            currentLocality: currentLocality, state: state
        )
    }

    /// Current locality is an immediate physical precondition, not a durable
    /// reservation capability. Refusal is non-mutating and the reservation
    /// remains retryable until its existing bounded expiry.
    public func prevalidateMarketSettlementLocality(
        proposalID: AgentMarketProposalID,
        currentLocality: AgentMarketCurrentLocalityEvidence
    ) throws {
        guard let state = marketState,
              let proposal = state.proposals.first(where: {
                  $0.proposalID == proposalID && $0.status == .accepted
              }), let listing = state.listings.first(where: {
                  $0.listingID == proposal.listingID && $0.status == .reserved
              }) else {
            throw AgentSessionError.market(.invalidProposal(proposalID.rawValue))
        }
        try validateMarketCurrentLocality(
            currentLocality, proposal: proposal, listing: listing, state: state
        )
    }

    public mutating func createMarketListing(
        operationID: String,
        proposal: AgentMarketListingProposal
    ) throws {
        // Listing is not a second remote seller act in V1. Only the exact
        // deterministic posting authorized by the verified local deposit and
        // its still-current reason can be published.
        let depositAuthorizedProposal = nextAutonomousMarketListingProposal()
        try marketTransaction { session, state in
            if state.processedOperationIDs.contains(operationID) { return }
            session.compactTerminalMarketState(state: &state)
            guard proposal == depositAuthorizedProposal,
                  let depositIndex = state.deposits.firstIndex(where: {
                $0.depositID == proposal.depositID
            }), state.deposits[depositIndex].status == .deposited,
                  state.deposits[depositIndex].sellerID == proposal.sellerID,
                  !state.listings.contains(where: {
                      $0.listingID == proposal.listingID
                  }) else {
                throw AgentSessionError.market(.invalidListing(
                    proposal.listingID.rawValue
                ))
            }
            let deposit = state.deposits[depositIndex]
            try session.validateMarketTerms(proposal.terms, deposit: deposit)
            let expectedHistory = state.priceHistory.filter {
                proposal.historyTradeIDs.contains($0.tradeID)
                    && $0.marketID == deposit.marketID
                    && $0.terms.baseItemKey == proposal.terms.baseItemKey
                    && $0.terms.quoteItemKey == proposal.terms.quoteItemKey
            }
            guard expectedHistory.count == proposal.historyTradeIDs.count else {
                throw AgentSessionError.market(.invalidListing("foreign-history"))
            }
            guard state.listings.count < state.configuration.maximumListings else {
                throw AgentSessionError.market(.capacityReached("listings"))
            }
            let event = try session.requiredMarketEvent(
                kind: .marketListingCreated, actorID: proposal.sellerID,
                detail: "listed:\(proposal.listingID.rawValue):history=\(!proposal.historyTradeIDs.isEmpty)",
                summary: "local listing created id=\(proposal.listingID.rawValue) price=\(proposal.terms.quoteQuantity)/\(proposal.terms.baseQuantity) history=\(!proposal.historyTradeIDs.isEmpty)"
            )
            state.listings.append(AgentMarketListing(
                listingID: proposal.listingID, depositID: proposal.depositID,
                marketID: deposit.marketID, sellerID: proposal.sellerID,
                initialTerms: proposal.terms, currentTerms: proposal.terms,
                historyTradeIDs: proposal.historyTradeIDs.sorted(),
                historyInformed: !proposal.historyTradeIDs.isEmpty,
                createdAtTick: session.tick,
                expiresAtTick: session.tick
                    + state.configuration.listingLifetimeTicks,
                status: .open, revisionCount: 0,
                listingEventID: event.eventID, terminalEventID: nil
            ))
            state.deposits[depositIndex].status = .listed
            state.deposits[depositIndex].listingID = proposal.listingID
            session.retainMarketOperationID(operationID, state: &state)
            state.lastMarketEventID = event.eventID
        }
    }

    public mutating func proposeMarketPurchase(
        operationID: String,
        proposal: AgentMarketBuyerProposal
    ) throws {
        try marketTransaction { session, state in
            if state.processedOperationIDs.contains(operationID) { return }
            let observation = proposal.observation
            guard let listingIndex = state.listings.firstIndex(where: {
                $0.listingID == observation.listingID
            }), state.listings[listingIndex].status == .open,
                  state.listings[listingIndex].expiresAtTick >= session.tick,
                  observation.observedAtTick == session.tick,
                  observation.chunksReady,
                  observation.distance >= 0,
                  observation.distance <= state.configuration.maximumLocalDistance,
                  observation.buyerID != state.listings[listingIndex].sellerID,
                  proposal.terms.baseItemKey
                    == state.listings[listingIndex].currentTerms.baseItemKey,
                  proposal.terms.quoteItemKey
                    == state.listings[listingIndex].currentTerms.quoteItemKey,
                  proposal.terms.baseQuantity
                    == state.listings[listingIndex].currentTerms.baseQuantity,
                  proposal.terms.quoteQuantity
                    == observation.consideration.material.count,
                  observation.consideration.holderID == observation.buyerID,
                  observation.consideration.material.identity.itemKey
                    == proposal.terms.quoteItemKey,
                  proposal.rejectedAsk
                    == (proposal.terms
                        != state.listings[listingIndex].currentTerms),
                  !state.proposals.contains(where: {
                      $0.proposalID == proposal.proposalID
                  }) else {
                throw AgentSessionError.market(.invalidProposal(
                    proposal.proposalID.rawValue
                ))
            }
            try session.requireActiveMarketReason(
                observation.buyerReason, actor: observation.buyerID,
                desiredItem: proposal.terms.baseItemKey
            )
            try session.requireMarketAsset(
                observation.consideration.assetID, owner: observation.buyerID,
                current: observation.consideration.holderObservation
            )
            session.compactTerminalMarketState(state: &state)
            guard state.proposals.count < state.configuration.maximumProposals else {
                throw AgentSessionError.market(.capacityReached("proposals"))
            }
            let event = try session.requiredMarketEvent(
                kind: .marketProposalCreated, actorID: observation.buyerID,
                detail: "proposed:\(proposal.proposalID.rawValue):rejectedAsk=\(proposal.rejectedAsk)",
                summary: "local buyer proposal id=\(proposal.proposalID.rawValue) quote=\(proposal.terms.quoteQuantity) rejectedAsk=\(proposal.rejectedAsk)"
            )
            state.proposals.append(AgentMarketProposal(
                proposalID: proposal.proposalID,
                listingID: observation.listingID,
                buyerID: observation.buyerID,
                consideration: observation.consideration,
                buyerReason: observation.buyerReason,
                proposedTerms: proposal.terms,
                rejectedAsk: proposal.rejectedAsk,
                proposedAtTick: session.tick, status: .proposed,
                proposalEventID: event.eventID, decisionEventID: nil,
                decisionReason: nil
            ))
            session.retainMarketOperationID(operationID, state: &state)
            state.lastMarketEventID = event.eventID
        }
    }

    public mutating func decideMarketProposal(
        operationID: String,
        decision: AgentMarketSellerDecision
    ) throws {
        try marketTransaction { session, state in
            if state.processedOperationIDs.contains(operationID) { return }
            guard let proposalIndex = state.proposals.firstIndex(where: {
                $0.proposalID == decision.proposalID
            }), state.proposals[proposalIndex].status == .proposed,
                  let listingIndex = state.listings.firstIndex(where: {
                      $0.listingID == state.proposals[proposalIndex].listingID
                  }), state.listings[listingIndex].status == .open,
                  state.listings[listingIndex].sellerID == decision.sellerID,
                  let depositIndex = state.deposits.firstIndex(where: {
                      $0.depositID == state.listings[listingIndex].depositID
                  }) else {
                throw AgentSessionError.market(.invalidProposal(
                    decision.proposalID.rawValue
                ))
            }
            let deposit = state.deposits[depositIndex]
            guard let currentLocality = decision.currentLocality else {
                throw AgentSessionError.market(.unauthorized(
                    "seller decision requires current World locality"
                ))
            }
            let expected = try session.evaluateMarketSellerDecision(
                proposal: state.proposals[proposalIndex],
                listing: state.listings[listingIndex], deposit: deposit,
                currentLocality: currentLocality, state: state
            )
            guard decision == expected else {
                throw AgentSessionError.market(.unauthorized(
                    "seller decision must equal normal deterministic cognition"
                ))
            }
            let event = try session.requiredMarketEvent(
                kind: .marketProposalDecided, actorID: decision.sellerID,
                detail: "decision:\(decision.proposalID.rawValue):\(decision.accept ? "accepted" : "rejected")",
                summary: "seller decision proposal=\(decision.proposalID.rawValue) accepted=\(decision.accept)"
            )
            state.proposals[proposalIndex].status = decision.accept
                ? .accepted : .rejected
            state.proposals[proposalIndex].decisionEventID = event.eventID
            state.proposals[proposalIndex].decisionReason = decision.reason
            if decision.accept {
                state.listings[listingIndex].status = .reserved
                state.listings[listingIndex].currentTerms =
                    state.proposals[proposalIndex].proposedTerms
                state.listings[listingIndex].revisionCount +=
                    state.listings[listingIndex].initialTerms
                        == state.proposals[proposalIndex].proposedTerms ? 0 : 1
                state.deposits[depositIndex].status = .reserved
            }
            session.retainMarketOperationID(operationID, state: &state)
            state.lastMarketEventID = event.eventID
        }
    }

    public mutating func completeVerifiedMarketTrade(
        _ outcome: AgentVerifiedMarketTrade
    ) throws {
        try marketTransaction { session, state in
            if state.processedOperationIDs.contains(outcome.operationID) { return }
            guard outcome.completedAtTick == session.tick,
                  let listingIndex = state.listings.firstIndex(where: {
                      $0.listingID == outcome.listingID
                  }), state.listings[listingIndex].status == .reserved,
                  let proposalIndex = state.proposals.firstIndex(where: {
                      $0.proposalID == outcome.proposalID
                  }), state.proposals[proposalIndex].status == .accepted,
                  state.proposals[proposalIndex].listingID == outcome.listingID,
                  let depositIndex = state.deposits.firstIndex(where: {
                      $0.depositID == state.listings[listingIndex].depositID
                  }), state.deposits[depositIndex].status == .reserved,
                  outcome.marketID == state.listings[listingIndex].marketID,
                  outcome.sellerID == state.listings[listingIndex].sellerID,
                  outcome.buyerID == state.proposals[proposalIndex].buyerID,
                  outcome.sellerID != outcome.buyerID,
                  outcome.terms == state.proposals[proposalIndex].proposedTerms,
                  outcome.offeredLeg.assetID == state.deposits[depositIndex].assetID,
                  outcome.considerationLeg.assetID
                    == state.proposals[proposalIndex].consideration.assetID,
                  outcome.offeredLeg.sourceObservation.holder
                    == state.deposits[depositIndex].lastMarketObservation.holder,
                  outcome.offeredLeg.sourceObservation.materialIdentity
                    == state.deposits[depositIndex].material.identity,
                  outcome.offeredLeg.sourceObservation.quantity
                    == state.deposits[depositIndex].material.count,
                  outcome.offeredLeg.sourceObservation.holder
                    == .container(state.markets.first(where: {
                        $0.marketID == outcome.marketID
                    })?.containerLocationID ?? ""),
                  outcome.offeredLeg.destinationObservation.holder
                    == .agent(outcome.buyerID),
                  outcome.considerationLeg.sourceObservation.holder
                    == .agent(outcome.buyerID),
                  outcome.considerationLeg.sourceObservation.materialIdentity
                    == state.proposals[proposalIndex]
                        .consideration.material.identity,
                  outcome.considerationLeg.sourceObservation.quantity
                    == state.proposals[proposalIndex]
                        .consideration.material.count,
                  outcome.considerationLeg.destinationObservation.holder
                    == .agent(outcome.sellerID),
                  Set([outcome.offeredLeg.physicalReceiptID,
                       outcome.considerationLeg.physicalReceiptID]).count == 2,
                  outcome.offeredLeg.destinationObservation.physicalReceiptID
                    == outcome.offeredLeg.physicalReceiptID,
                  outcome.considerationLeg.destinationObservation.physicalReceiptID
                    == outcome.considerationLeg.physicalReceiptID,
                  !state.tradeRecords.contains(where: {
                      $0.trade.tradeID == outcome.tradeID
                  }) else {
                throw AgentSessionError.market(.invalidOutcome(
                    outcome.tradeID.rawValue
                ))
            }
            try session.requireMarketAsset(
                outcome.offeredLeg.assetID, owner: outcome.sellerID,
                current: outcome.offeredLeg.sourceObservation
            )
            try session.requireMarketAsset(
                outcome.considerationLeg.assetID, owner: outcome.buyerID,
                current: outcome.considerationLeg.sourceObservation
            )
            try session.prevalidateMarketOwnershipTransfer(
                assetID: outcome.offeredLeg.assetID, newOwner: outcome.buyerID,
                tradeID: outcome.tradeID
            )
            try session.prevalidateMarketOwnershipTransfer(
                assetID: outcome.considerationLeg.assetID,
                newOwner: outcome.sellerID, tradeID: outcome.tradeID
            )
            session.transferMarketAsset(
                outcome.offeredLeg.assetID,
                from: outcome.offeredLeg.sourceObservation,
                to: outcome.offeredLeg.destinationObservation,
                newOwner: outcome.buyerID, tradeID: outcome.tradeID
            )
            session.transferMarketAsset(
                outcome.considerationLeg.assetID,
                from: outcome.considerationLeg.sourceObservation,
                to: outcome.considerationLeg.destinationObservation,
                newOwner: outcome.sellerID, tradeID: outcome.tradeID
            )
            let event = try session.requiredMarketEvent(
                kind: .marketTradeCompleted, actorID: outcome.buyerID,
                detail: "completed:\(outcome.tradeID.rawValue):\(outcome.offeredLeg.physicalReceiptID):\(outcome.considerationLeg.physicalReceiptID)",
                summary: "physical local market trade completed id=\(outcome.tradeID.rawValue) price=\(outcome.terms.quoteQuantity)/\(outcome.terms.baseQuantity)"
            )
            state.listings[listingIndex].status = .completed
            state.listings[listingIndex].terminalEventID = event.eventID
            state.proposals[proposalIndex].status = .accepted
            state.deposits[depositIndex].status = .sold
            state.deposits[depositIndex].terminalEventID = event.eventID
            let listing = state.listings[listingIndex]
            let proposal = state.proposals[proposalIndex]
            state.tradeRecords.append(AgentMarketTradeRecord(
                trade: outcome, listing: listing, proposal: proposal,
                causalEventID: event.eventID
            ))
            state.priceHistory.append(AgentMarketPriceObservation(
                marketID: outcome.marketID, tradeID: outcome.tradeID,
                terms: outcome.terms, sellerID: outcome.sellerID,
                buyerID: outcome.buyerID, completedAtTick: session.tick,
                physicalReceiptIDs: [outcome.offeredLeg.physicalReceiptID,
                    outcome.considerationLeg.physicalReceiptID].sorted(),
                causalEventID: event.eventID
            ))
            session.fulfillMarketNeed(
                state.deposits[depositIndex].quoteReason.needID,
                received: outcome.considerationLeg.destinationObservation,
                operationID: outcome.operationID
            )
            session.fulfillMarketNeed(
                state.proposals[proposalIndex].buyerReason.needID,
                received: outcome.offeredLeg.destinationObservation,
                operationID: outcome.operationID
            )
            state.totalTradeCount += 1
            session.retainMarketOperationID(outcome.operationID, state: &state)
            session.compactTerminalMarketState(state: &state)
            state.lastMarketEventID = event.eventID
        }
    }

    /// Expiry/cancellation releases social reservation only. Physical goods
    /// remain in the market container until a separately verified withdrawal.
    public mutating func closeMarketListing(
        operationID: String,
        listingID: AgentMarketListingID,
        reason: AgentMarketListingStatus
    ) throws {
        try marketTransaction { session, state in
            if state.processedOperationIDs.contains(operationID) { return }
            guard reason == .expired || reason == .cancelled || reason == .stale,
                  let listingIndex = state.listings.firstIndex(where: {
                      $0.listingID == listingID
                  }), state.listings[listingIndex].status.isPending,
                  reason != .expired
                    || state.listings[listingIndex].expiresAtTick <= session.tick,
                  let depositIndex = state.deposits.firstIndex(where: {
                      $0.depositID == state.listings[listingIndex].depositID
                  }) else {
                throw AgentSessionError.market(.invalidListing(listingID.rawValue))
            }
            let event = try session.requiredMarketEvent(
                kind: .marketListingClosed,
                actorID: state.listings[listingIndex].sellerID,
                detail: "closed:\(listingID.rawValue):\(reason.rawValue)",
                summary: "local market listing closed id=\(listingID.rawValue) reason=\(reason.rawValue)"
            )
            state.listings[listingIndex].status = reason
            state.listings[listingIndex].terminalEventID = event.eventID
            state.deposits[depositIndex].status = reason == .stale
                ? .stale : (reason == .expired ? .expired : .cancelled)
            for index in state.proposals.indices where
                state.proposals[index].listingID == listingID
                    && state.proposals[index].status.isPending {
                state.proposals[index].status = .stale
                state.proposals[index].decisionEventID = event.eventID
                state.proposals[index].decisionReason = reason.rawValue
            }
            session.retainMarketOperationID(operationID, state: &state)
            state.lastMarketEventID = event.eventID
        }
    }

    public mutating func completeVerifiedMarketWithdrawal(
        _ outcome: AgentVerifiedMarketWithdrawal
    ) throws {
        try marketTransaction { session, state in
            if state.processedOperationIDs.contains(outcome.operationID) { return }
            guard outcome.completedAtTick == session.tick,
                  let depositIndex = state.deposits.firstIndex(where: {
                      $0.depositID == outcome.depositID
                  }), [.cancelled, .expired].contains(
                    state.deposits[depositIndex].status
                  ), state.deposits[depositIndex].marketID == outcome.marketID,
                  state.deposits[depositIndex].sellerID == outcome.sellerID,
                  state.deposits[depositIndex].assetID == outcome.assetID,
                  outcome.sourceObservation.holder
                    == state.deposits[depositIndex].lastMarketObservation.holder,
                  outcome.sourceObservation.materialIdentity
                    == state.deposits[depositIndex].material.identity,
                  outcome.sourceObservation.quantity
                    == state.deposits[depositIndex].material.count,
                  outcome.sourceObservation.observedAtTick == session.tick,
                  outcome.destinationObservation.holder == .agent(outcome.sellerID),
                  outcome.destinationObservation.physicalReceiptID
                    == outcome.physicalReceiptID else {
                throw AgentSessionError.market(.invalidOutcome(
                    outcome.depositID.rawValue
                ))
            }
            try session.requireMarketAsset(
                outcome.assetID, owner: outcome.sellerID,
                current: outcome.sourceObservation
            )
            session.updateMarketAssetHolder(
                outcome.assetID, from: outcome.sourceObservation,
                to: outcome.destinationObservation
            )
            let event = try session.requiredMarketEvent(
                kind: .marketWithdrawalCompleted, actorID: outcome.sellerID,
                detail: "withdrawn:\(outcome.depositID.rawValue):\(outcome.physicalReceiptID)",
                summary: "unsold physical market goods withdrawn deposit=\(outcome.depositID.rawValue)"
            )
            state.deposits[depositIndex].status = .withdrawn
            state.deposits[depositIndex].terminalEventID = event.eventID
            state.withdrawals.append(AgentMarketWithdrawalRecord(
                outcome: outcome, causalEventID: event.eventID
            ))
            state.totalWithdrawalCount += 1
            session.retainMarketOperationID(outcome.operationID, state: &state)
            session.compactTerminalMarketState(state: &state)
            state.lastMarketEventID = event.eventID
        }
    }

    func validateMarketStateIfEnabled() throws {
        guard let state = marketState else { return }
        guard state.markets.count <= state.configuration.maximumMarkets,
              state.depositOpportunities.count
                <= state.configuration.maximumDepositOpportunities,
              state.deposits.count <= state.configuration.maximumDeposits,
              state.listings.count <= state.configuration.maximumListings,
              state.proposals.count <= state.configuration.maximumProposals,
              state.tradeRecords.count <= state.configuration.maximumTradeRecords,
              state.priceHistory.count
                <= state.configuration.maximumPriceHistoryRows,
              state.withdrawals.count <= state.configuration.maximumWithdrawals,
              state.processedOperationIDs.count
                <= state.configuration.maximumProcessedOperations,
              Set(state.markets.map(\.marketID)).count == state.markets.count,
              Set(state.markets.map(\.containerLocationID)).count
                == state.markets.count,
              Set(state.deposits.map(\.depositID)).count == state.deposits.count,
              Set(state.deposits.map(\.assetID)).count == state.deposits.count,
              Set(state.listings.map(\.listingID)).count == state.listings.count,
              Set(state.proposals.map(\.proposalID)).count == state.proposals.count,
              Set(state.tradeRecords.map { $0.trade.tradeID }).count
                == state.tradeRecords.count,
              Set(state.priceHistory.map(\.tradeID)).count
                == state.priceHistory.count,
              Set(state.processedOperationIDs).count
                == state.processedOperationIDs.count else {
            throw AgentSessionError.market(.invalidState("global bounds/identity"))
        }
        for deposit in state.deposits {
            guard state.markets.contains(where: { $0.marketID == deposit.marketID }),
                  deposit.material.count > 0,
                  deposit.lastMarketObservation.quantity == deposit.material.count,
                  deposit.lastMarketObservation.materialIdentity
                    == deposit.material.identity,
                  deposit.listingID == nil || state.listings.contains(where: {
                      $0.listingID == deposit.listingID
                        && $0.depositID == deposit.depositID
                  }) else {
                throw AgentSessionError.market(.invalidState("deposit"))
            }
        }
        for listing in state.listings {
            guard let deposit = state.deposits.first(where: {
                $0.depositID == listing.depositID
            }), listing.marketID == deposit.marketID,
                  listing.sellerID == deposit.sellerID,
                  listing.expiresAtTick > listing.createdAtTick else {
                throw AgentSessionError.market(.invalidState("listing"))
            }
            try validateMarketTerms(listing.currentTerms, deposit: deposit)
        }
        let reservedListings = state.listings.filter { $0.status == .reserved }
        guard reservedListings.allSatisfy({ listing in
            state.proposals.filter {
                $0.listingID == listing.listingID && $0.status == .accepted
            }.count == 1
        }) else {
            throw AgentSessionError.market(.invalidState("reservation"))
        }
        for price in state.priceHistory {
            guard let record = state.tradeRecords.first(where: {
                $0.trade.tradeID == price.tradeID
            }), record.trade.marketID == price.marketID,
                  record.trade.terms == price.terms,
                  record.causalEventID == price.causalEventID,
                  price.physicalReceiptIDs == [
                    record.trade.offeredLeg.physicalReceiptID,
                    record.trade.considerationLeg.physicalReceiptID,
                  ].sorted() else {
                throw AgentSessionError.market(.invalidState("price provenance"))
            }
        }
    }

    private mutating func marketTransaction(
        _ body: (inout AgentSimulationSession, inout AgentMarketState) throws -> Void
    ) throws {
        guard marketState != nil else {
            throw AgentSessionError.market(.disabled)
        }
        var candidate = self
        var state = candidate.marketState!
        try body(&candidate, &state)
        candidate.marketState = state
        try candidate.validateMarketStateIfEnabled()
        try candidate.validateMaterialRightsStateIfEnabled()
        self = candidate
    }

    private mutating func requiredMarketEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID?,
        detail: String,
        summary: String
    ) throws -> AgentCausalEvent {
        try prevalidateCausalAppend(count: 1)
        guard let event = try recordCausalEvent(
            kind: kind, origin: .marketTransition, actorID: actorID,
            subjectID: actorID, payload: .operation(status: "applied", detail: detail),
            summary: summary
        ) else { throw AgentSessionError.market(.causalLedgerRequired) }
        return event
    }

    private func validateMarketDepositOpportunity(
        _ value: AgentMarketDepositOpportunity,
        state: AgentMarketState
    ) throws {
        guard validMarketText(value.opportunityID, maximum: 160),
              let market = state.markets.first(where: {
                  $0.marketID == value.marketID && $0.status == .active
              }), market.position == value.marketPosition,
              market.containerLocationID == value.containerLocationID,
              market.physicalSlotCapacity == value.physicalSlotCapacity,
              value.sellerID == value.offered.holderID,
              value.offered.holderObservation.holder == .agent(value.sellerID),
              value.offered.holderObservation.materialIdentity
                == value.offered.material.identity,
              value.offered.holderObservation.quantity
                == value.offered.material.count,
              value.physicalOccupiedSlots >= 0,
              value.physicalOccupiedSlots < value.physicalSlotCapacity,
              value.distance >= 0, value.distance <= market.interactionRadius,
              value.chunksReady, value.observedAtTick == tick,
              value.expiresAtTick >= tick else {
            throw AgentSessionError.market(.invalidOpportunity(value.opportunityID))
        }
        try requireActiveMarketReason(
            value.quoteReason, actor: value.sellerID,
            desiredItem: value.quoteReason.desiredItemKey
        )
        try requireMarketAsset(
            value.offered.assetID, owner: value.sellerID,
            current: value.offered.holderObservation
        )
    }

    private func validateMarketTerms(
        _ terms: AgentMarketPriceTerms,
        deposit: AgentMarketDeposit
    ) throws {
        guard validMarketText(terms.baseItemKey, maximum: 128),
              validMarketText(terms.quoteItemKey, maximum: 128),
              terms.baseItemKey != terms.quoteItemKey,
              terms.baseItemKey == deposit.material.identity.itemKey,
              terms.quoteItemKey == deposit.quoteReason.desiredItemKey,
              terms.baseQuantity == deposit.material.count,
              (1...4096).contains(terms.baseQuantity),
              (1...4096).contains(terms.quoteQuantity) else {
            throw AgentSessionError.market(.invalidListing("price-terms"))
        }
    }

    private func requireActiveMarketReason(
        _ reason: AgentBarterValueReason,
        actor: AgentID,
        desiredItem: String
    ) throws {
        guard statesById[actor.rawValue] != nil,
              let need = productionState?.needs.first(where: {
                  $0.needID == reason.needID && $0.status == .active
              }), need.actorID == actor,
              AgentBarterValueReason(need: need) == reason,
              reason.desiredItemKey == desiredItem else {
            throw AgentSessionError.market(.unauthorized("inactive material reason"))
        }
    }

    private func requireMarketAsset(
        _ assetID: AgentMaterialAssetID,
        owner: AgentID,
        current: AgentMaterialHolderObservation
    ) throws {
        guard let record = materialRightsState?.records.first(where: {
            $0.asset.assetID == assetID
        }), record.lastVerifiedHolder.holder == current.holder,
              record.lastVerifiedHolder.materialIdentity.itemKey
                == current.materialIdentity.itemKey,
              record.lastVerifiedHolder.quantity == current.quantity,
              record.recognizedOwnership?.ownerID == owner,
              record.asset.quantity == current.quantity,
              record.asset.permitsCurrentIdentity(current.materialIdentity) else {
            throw AgentSessionError.market(.staleAuthority(assetID.rawValue))
        }
    }

    private mutating func updateMarketAssetHolder(
        _ assetID: AgentMaterialAssetID,
        from source: AgentMaterialHolderObservation,
        to destination: AgentMaterialHolderObservation
    ) {
        let index = materialRightsState!.records.firstIndex {
            $0.asset.assetID == assetID
        }!
        precondition(
            materialRightsState!.records[index].lastVerifiedHolder.holder
                == source.holder
                && materialRightsState!.records[index]
                    .lastVerifiedHolder.quantity == source.quantity
        )
        materialRightsState!.records[index].lastVerifiedHolder = destination
    }

    private func prevalidateMarketOwnershipTransfer(
        assetID: AgentMaterialAssetID,
        newOwner: AgentID,
        tradeID: AgentMarketTradeID
    ) throws {
        guard statesById[newOwner.rawValue] != nil,
              let record = materialRightsState?.records.first(where: {
                  $0.asset.assetID == assetID
              }), record.claims.count
                < (materialRightsState?.configuration.maximumClaimsPerAsset ?? 0),
              AgentMaterialClaimID(rawValue:
                "market-received:\(tradeID.rawValue):\(assetID.rawValue)") != nil else {
            throw AgentSessionError.market(.capacityReached("ownership-claims"))
        }
    }

    private mutating func transferMarketAsset(
        _ assetID: AgentMaterialAssetID,
        from source: AgentMaterialHolderObservation,
        to destination: AgentMaterialHolderObservation,
        newOwner: AgentID,
        tradeID: AgentMarketTradeID
    ) {
        let index = materialRightsState!.records.firstIndex {
            $0.asset.assetID == assetID
        }!
        let claimID = AgentMaterialClaimID(rawValue:
            "market-received:\(tradeID.rawValue):\(assetID.rawValue)")!
        materialRightsState!.records[index].lastVerifiedHolder = destination
        materialRightsState!.records[index].custodianID = newOwner
        materialRightsState!.records[index].claims.append(AgentMaterialClaim(
            claimID: claimID, claimantID: newOwner, basis: .received,
            assertedAtTick: tick
        ))
        materialRightsState!.records[index].claims.sort { $0.claimID < $1.claimID }
        materialRightsState!.records[index].recognizedOwnership =
            AgentMaterialRecognizedOwnership(
                claimID: claimID, ownerID: newOwner,
                recognizingAgentIDs: [newOwner], recognizedAtTick: tick
            )
    }

    private mutating func fulfillMarketNeed(
        _ needID: AgentProductionNeedID,
        received: AgentMaterialHolderObservation,
        operationID: String
    ) {
        guard let index = productionState?.needs.firstIndex(where: {
            $0.needID == needID && $0.status == .active
        }), productionState!.needs[index].desiredOutputItemKey
                == received.materialIdentity.itemKey,
              received.quantity >= productionState!.needs[index].quantity else {
            // V1 does not invent partial-need accounting. A verified trade may
            // advance a motive without falsely fulfilling a larger need.
            return
        }
        productionState!.needs[index].status = .fulfilled
        productionState!.needs[index].fulfilledByOperationID = operationID
    }

    private func evaluateMarketSellerDecision(
        proposal: AgentMarketProposal,
        listing: AgentMarketListing,
        deposit: AgentMarketDeposit,
        currentLocality: AgentMarketCurrentLocalityEvidence,
        state: AgentMarketState
    ) throws -> AgentMarketSellerDecision {
        try validateMarketCurrentLocality(
            currentLocality, proposal: proposal, listing: listing, state: state
        )
        try requireActiveMarketReason(
            deposit.quoteReason, actor: listing.sellerID,
            desiredItem: proposal.proposedTerms.quoteItemKey
        )
        let termsMatch = proposal.proposedTerms.baseItemKey
                == listing.initialTerms.baseItemKey
            && proposal.proposedTerms.quoteItemKey
                == listing.initialTerms.quoteItemKey
            && proposal.proposedTerms.baseQuantity
                == listing.initialTerms.baseQuantity
            && proposal.proposedTerms.quoteQuantity
                == proposal.consideration.material.count
        let reasonQuantity = deposit.quoteReason.quantity
        let autonomousConcessionFloor = max(
            1, min(listing.initialTerms.quoteQuantity, reasonQuantity) - 1
        )
        let minimumQuote = listing.historyInformed
            ? listing.currentTerms.quoteQuantity : autonomousConcessionFloor
        let accept = termsMatch
            && proposal.proposedTerms.quoteQuantity >= minimumQuote
        let result = accept ? "accept" : "reject"
        let reason = "normal-cognition requested=\(proposal.proposedTerms.quoteItemKey):\(proposal.proposedTerms.quoteQuantity) initial=\(listing.initialTerms.quoteItemKey):\(listing.initialTerms.quoteQuantity) current=\(listing.currentTerms.quoteItemKey):\(listing.currentTerms.quoteQuantity) sellerReason=\(deposit.quoteReason.desiredItemKey):\(reasonQuantity) localHistory=\(listing.historyInformed ? 1 : 0) minimum=\(minimumQuote) result=\(result)"
        return AgentMarketSellerDecision(
            proposalID: proposal.proposalID, sellerID: listing.sellerID,
            accept: accept, reason: reason,
            currentLocality: currentLocality
        )
    }

    private func validateMarketCurrentLocality(
        _ evidence: AgentMarketCurrentLocalityEvidence,
        proposal: AgentMarketProposal,
        listing: AgentMarketListing,
        state: AgentMarketState
    ) throws {
        guard let market = state.markets.first(where: {
            $0.marketID == listing.marketID && $0.status == .active
        }), evidence.seller.marketID == market.marketID,
              evidence.buyer.marketID == market.marketID,
              evidence.seller.participantID == listing.sellerID,
              evidence.buyer.participantID == proposal.buyerID,
              evidence.seller.participantID != evidence.buyer.participantID,
              statesById[evidence.seller.participantID.rawValue] != nil,
              statesById[evidence.buyer.participantID.rawValue] != nil,
              validMarketText(
                  evidence.seller.participantPhysicalID, maximum: 160
              ), validMarketText(
                  evidence.buyer.participantPhysicalID, maximum: 160
              ), evidence.seller.participantPhysicalID
                != evidence.buyer.participantPhysicalID,
              evidence.seller.marketPosition == market.position,
              evidence.buyer.marketPosition == market.position,
              evidence.seller.participantAlive,
              evidence.buyer.participantAlive,
              evidence.seller.participantChunkReady,
              evidence.buyer.participantChunkReady,
              evidence.seller.marketChunkReady,
              evidence.buyer.marketChunkReady,
              evidence.seller.marketContainerValid,
              evidence.buyer.marketContainerValid,
              evidence.seller.observedAtTick == tick,
              evidence.buyer.observedAtTick == tick,
              marketDistance(
                  evidence.seller.participantPosition, market.position
              ) <= market.interactionRadius,
              marketDistance(
                  evidence.buyer.participantPosition, market.position
              ) <= market.interactionRadius else {
            throw AgentSessionError.market(.unauthorized(
                "current seller/buyer market locality"
            ))
        }
    }

    private func marketDistance(
        _ lhs: AgentPosition, _ rhs: AgentPosition
    ) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }

    private func validMarketText(_ text: String, maximum: Int) -> Bool {
        !text.isEmpty && text.utf8.count <= maximum && !text.contains("\n")
    }

    private func retainMarketOperationID(
        _ operationID: String,
        state: inout AgentMarketState
    ) {
        state.processedOperationIDs.append(operationID)
        if state.processedOperationIDs.count
            > state.configuration.maximumProcessedOperations {
            state.processedOperationIDs.removeFirst()
            state.evictionCount += 1
        }
    }

    private func compactMarketOpportunities(state: inout AgentMarketState) {
        state.depositOpportunities.removeAll { $0.expiresAtTick < tick }
    }

    /// Only terminal projections are compacted. Active deposits, listings and
    /// reservations are physical/cognitive authority and never capacity victims.
    private func compactTerminalMarketState(state: inout AgentMarketState) {
        compactMarketOpportunities(state: &state)
        func removeTerminalDeposit(at index: Int) {
            let listingID = state.deposits[index].listingID
            if let listingID {
                state.proposals.removeAll { $0.listingID == listingID }
                state.listings.removeAll { $0.listingID == listingID }
            }
            state.deposits.remove(at: index)
            state.evictionCount += 1
        }
        while state.deposits.count >= state.configuration.maximumDeposits,
              let index = state.deposits.indices.filter({
                  state.deposits[$0].status.isTerminal
              }).min(by: {
                  state.deposits[$0].depositedAtTick
                    < state.deposits[$1].depositedAtTick
              }) {
            removeTerminalDeposit(at: index)
        }
        while state.listings.count >= state.configuration.maximumListings,
              let index = state.listings.indices.filter({
                  let listing = state.listings[$0]
                  return listing.status.isTerminal
                    && state.deposits.contains {
                        $0.depositID == listing.depositID && $0.status.isTerminal
                    }
              }).min(by: {
                  state.listings[$0].createdAtTick
                    < state.listings[$1].createdAtTick
              }) {
            let depositID = state.listings[index].depositID
            removeTerminalDeposit(at: state.deposits.firstIndex {
                $0.depositID == depositID
            }!)
        }
        while state.proposals.count >= state.configuration.maximumProposals,
              let index = state.proposals.indices.first(where: { index in
                  let proposal = state.proposals[index]
                  return !proposal.status.isPending
                    || state.listings.first {
                        $0.listingID == proposal.listingID
                    }?.status.isTerminal == true
              }) {
            state.proposals.remove(at: index)
            state.evictionCount += 1
        }
        while state.tradeRecords.count
                > state.configuration.maximumTradeRecords {
            let tradeID = state.tradeRecords.removeFirst().trade.tradeID
            state.priceHistory.removeAll { $0.tradeID == tradeID }
            state.evictionCount += 1
        }
        while state.priceHistory.count
                > state.configuration.maximumPriceHistoryRows {
            state.priceHistory.removeFirst()
            state.evictionCount += 1
        }
        while state.withdrawals.count > state.configuration.maximumWithdrawals {
            state.withdrawals.removeFirst()
            state.evictionCount += 1
        }
    }
}

private extension AgentMaterialAssetID {
    func isReservedInMarket(_ state: AgentMarketState) -> Bool {
        state.deposits.contains { $0.assetID == self && !$0.status.isTerminal }
            || state.proposals.contains {
                $0.consideration.assetID == self && $0.status.isPending
            }
    }
}
