extension AgentSimulationSession {
    public var barterEnabled: Bool { barterState != nil }

    public func barterSnapshot() -> AgentBarterSnapshot {
        guard let state = barterState else {
            return AgentBarterSnapshot(
                enabled: false, configuration: nil, opportunities: [], offers: [],
                records: [], totalCompletedCount: 0, pendingOfferCount: 0,
                evictionCount: 0
            )
        }
        return AgentBarterSnapshot(
            enabled: true, configuration: state.configuration,
            opportunities: state.opportunities.sorted { $0.opportunityID < $1.opportunityID },
            offers: state.offers.sorted { $0.offerID < $1.offerID },
            records: state.records.sorted { $0.causalEventID < $1.causalEventID },
            totalCompletedCount: state.totalCompletedCount,
            pendingOfferCount: state.offers.filter { $0.status.isPending }.count,
            evictionCount: state.evictionCount
        )
    }

    public mutating func setBarterEnabled(
        _ enabled: Bool,
        configuration: AgentBarterConfiguration = .live
    ) throws {
        if enabled {
            guard barterState == nil else { return }
            guard causalLedger.isEnabled else {
                throw AgentSessionError.barter(.causalLedgerRequired)
            }
            guard materialRightsState != nil else {
                throw AgentSessionError.barter(.materialRightsRequired)
            }
            guard productionState != nil else {
                throw AgentSessionError.barter(.productionRequired)
            }
            try prevalidateCausalAppend(count: 1)
            guard let event = try recordCausalEvent(
                kind: .barterInitialized, origin: .barterTransition,
                payload: .feature(name: "barter", enabled: true),
                summary: "barter initialized without moving physical goods"
            ) else { throw AgentSessionError.barter(.causalLedgerRequired) }
            barterState = AgentBarterState(
                configuration: configuration, opportunities: [], offers: [], records: [],
                processedOperationIDs: [], totalCompletedCount: 0, evictionCount: 0,
                initializedEventID: event.eventID, lastBarterEventID: event.eventID
            )
        } else if barterState != nil {
            throw AgentSessionError.barter(.unsafeDisable)
        }
    }

    /// Converts Pebble's bounded current physical pairs into economically
    /// relevant local opportunities. This is pure evaluation: it creates no
    /// offer, reservation, right or physical mutation.
    public func discoverBarterOpportunities(
        from candidates: [AgentBarterPhysicalPairObservation]
    ) throws -> [AgentBarterOpportunityObservation] {
        try discoverBarterOpportunities(
            from: candidates, acceptsAdapterRefreshedCustody: false
        )
    }

    /// Pebble-only discovery seam for observations whose exact stack authority
    /// was reacquired from the live custody gateway immediately before this
    /// call. The ordinary public discovery path continues to reject a changed
    /// custody fingerprint, so a caller cannot silently turn stale session
    /// evidence into current physical authority.
    public func discoverPhysicallyVerifiedBarterOpportunities(
        from candidates: [AgentBarterPhysicalPairObservation]
    ) throws -> [AgentBarterOpportunityObservation] {
        try discoverBarterOpportunities(
            from: candidates, acceptsAdapterRefreshedCustody: true
        )
    }

    private func discoverBarterOpportunities(
        from candidates: [AgentBarterPhysicalPairObservation],
        acceptsAdapterRefreshedCustody: Bool
    ) throws -> [AgentBarterOpportunityObservation] {
        guard let state = barterState else {
            throw AgentSessionError.barter(.disabled)
        }
        guard candidates.count
                <= state.configuration.maximumPhysicalPairCandidatesPerTick,
              Set(candidates.map(\.candidateID)).count == candidates.count else {
            throw AgentSessionError.barter(.invalidOpportunity("discovery-bounds"))
        }
        var discoveries: [AgentBarterOpportunityObservation] = []
        for candidate in candidates.sorted(by: {
            $0.candidateID < $1.candidateID
        }) {
            guard candidate.actorAID < candidate.actorBID,
                  candidate.actorAGood.holderID == candidate.actorAID,
                  candidate.actorBGood.holderID == candidate.actorBID,
                  candidate.actorAGood.assetID != candidate.actorBGood.assetID,
                  candidate.actorAGood.material.identity
                    != candidate.actorBGood.material.identity,
                  candidate.distance >= 0,
                  candidate.distance <= state.configuration.maximumLocalDistance,
                  candidate.lineOfSight, candidate.chunksReady,
                  candidate.observedAtTick == tick,
                  candidate.expiresAtTick
                    == tick + state.configuration.offerLifetimeTicks,
                  validBarterText(candidate.candidateID, maximum: 160) else {
                throw AgentSessionError.barter(
                    .invalidOpportunity(candidate.candidateID)
                )
            }
            try validateBarterLegProvenance(candidate.actorAGood)
            try validateBarterLegProvenance(candidate.actorBGood)
            guard !barterAssetReserved(candidate.actorAGood.assetID, in: state),
                  !barterAssetReserved(candidate.actorBGood.assetID, in: state),
                  !exactAssetIsEconomicallyCommitted(
                      candidate.actorAGood.assetID
                  ), !exactAssetIsEconomicallyCommitted(
                      candidate.actorBGood.assetID
                  ),
                  let actorAReason = bestBarterReason(
                    actorID: candidate.actorAID,
                    received: candidate.actorBGood.material,
                    configuration: state.configuration
                  ),
                  let actorBReason = bestBarterReason(
                    actorID: candidate.actorBID,
                    received: candidate.actorAGood.material,
                    configuration: state.configuration
                  ) else { continue }
            guard evaluateCurrentBarterMaterialUse(
                    requestID: "barter-discovery:\(candidate.candidateID):a",
                    assetID: candidate.actorAGood.assetID,
                    actorID: candidate.actorAID,
                    currentObservation: candidate.actorAGood.holderObservation,
                    acceptsAdapterRefreshedCustody:
                        acceptsAdapterRefreshedCustody
                  )?.verdict == .allowed,
                  evaluateCurrentBarterMaterialUse(
                    requestID: "barter-discovery:\(candidate.candidateID):b",
                    assetID: candidate.actorBGood.assetID,
                    actorID: candidate.actorBID,
                    currentObservation: candidate.actorBGood.holderObservation,
                    acceptsAdapterRefreshedCustody:
                        acceptsAdapterRefreshedCustody
                  )?.verdict == .allowed else { continue }
            let opportunity = AgentBarterOpportunityObservation(
                opportunityID: "barter-opportunity-"
                    + AgentAutonomousActivityDigest.make(candidate.candidateID),
                offerorID: candidate.actorAID,
                counterpartyID: candidate.actorBID,
                offered: candidate.actorAGood,
                requested: candidate.actorBGood,
                offerorReason: actorAReason,
                counterpartyReason: actorBReason,
                distance: candidate.distance,
                lineOfSight: candidate.lineOfSight,
                chunksReady: candidate.chunksReady,
                observedAtTick: candidate.observedAtTick,
                expiresAtTick: candidate.expiresAtTick
            )
            try validateBarterOpportunity(opportunity, state: state)
            discoveries.append(opportunity)
            if discoveries.count
                == state.configuration.maximumDiscoveriesPerTick { break }
        }
        return discoveries
    }

    /// Selects one current opportunity through deterministic cognition. The
    /// returned proposal is explicit offeror authority but remains social-only.
    public func nextAutonomousBarterOfferProposal() -> AgentBarterOfferProposal? {
        guard let state = barterState else { return nil }
        let candidates = state.opportunities.filter { opportunity in
            guard opportunity.observedAtTick == tick,
                  opportunity.expiresAtTick >= tick,
                  !barterAssetReserved(opportunity.offered.assetID, in: state),
                  !barterAssetReserved(opportunity.requested.assetID, in: state),
                  !exactAssetIsEconomicallyCommitted(
                      opportunity.offered.assetID
                  ), !exactAssetIsEconomicallyCommitted(
                      opportunity.requested.assetID
                  ),
                  bestBarterReason(
                    actorID: opportunity.offerorID,
                    received: opportunity.requested.material,
                    configuration: state.configuration
                  ) == opportunity.offerorReason,
                  bestBarterReason(
                    actorID: opportunity.counterpartyID,
                    received: opportunity.offered.material,
                    configuration: state.configuration
                  ) == opportunity.counterpartyReason else { return false }
            let offered = evaluateCurrentBarterMaterialUse(
                requestID: "barter-proposal:\(opportunity.opportunityID):offered",
                assetID: opportunity.offered.assetID,
                actorID: opportunity.offerorID,
                currentObservation: opportunity.offered.holderObservation,
                acceptsAdapterRefreshedCustody: true
            )
            let requested = evaluateCurrentBarterMaterialUse(
                requestID: "barter-proposal:\(opportunity.opportunityID):requested",
                assetID: opportunity.requested.assetID,
                actorID: opportunity.counterpartyID,
                currentObservation: opportunity.requested.holderObservation,
                acceptsAdapterRefreshedCustody: true
            )
            return offered?.verdict == .allowed
                && requested?.verdict == .allowed
        }.sorted { lhs, rhs in
            let lhsPriority = barterReasonPriority(lhs.offerorReason)
            let rhsPriority = barterReasonPriority(rhs.offerorReason)
            if lhsPriority != rhsPriority { return lhsPriority > rhsPriority }
            let lhsCounterparty = barterReasonPriority(lhs.counterpartyReason)
            let rhsCounterparty = barterReasonPriority(rhs.counterpartyReason)
            if lhsCounterparty != rhsCounterparty {
                return lhsCounterparty > rhsCounterparty
            }
            return lhs.opportunityID < rhs.opportunityID
        }
        guard let opportunity = candidates.first,
              let offerID = AgentBarterOfferID(
                rawValue: "barter-" + AgentAutonomousActivityDigest.make(
                    opportunity.opportunityID
                )
              ),
              !state.processedOperationIDs.contains(
                "barter-offer:\(offerID.rawValue)"
              ) else { return nil }
        return AgentBarterOfferProposal(
            offerID: offerID,
            opportunityID: opportunity.opportunityID,
            actorID: opportunity.offerorID,
            reason: "current local need values exact requested physical good"
        )
    }

    /// The counterparty re-evaluates its own current need and Pebble's current
    /// local evidence. Opportunity existence alone never implies acceptance.
    public func evaluateAutonomousBarterCounterpartyDecision(
        _ observation: AgentBarterCounterpartyDecisionObservation
    ) -> AgentBarterCounterpartyDecision? {
        guard let state = barterState,
              let offer = state.offers.first(where: {
                  $0.offerID == observation.offerID && $0.status == .open
              }), offer.opportunity.counterpartyID == observation.counterpartyID,
              observation.observedAtTick == tick else { return nil }
        let currentReason = bestBarterReason(
            actorID: observation.counterpartyID,
            received: offer.opportunity.offered.material,
            configuration: state.configuration
        )
        let needStillActive = currentReason == offer.opportunity.counterpartyReason
        let local = offer.expiresAtTick >= tick
            && observation.distance >= 0
            && observation.distance <= state.configuration.maximumLocalDistance
            && observation.lineOfSight && observation.chunksReady
        let accept = needStillActive && local
        let reason: String
        if !needStillActive {
            reason = "counterparty current need no longer values offered good"
        } else if !local {
            reason = "current bounded local evidence refuses exchange"
        } else {
            reason = "counterparty current need values exact offered physical good"
        }
        return AgentBarterCounterpartyDecision(
            offerID: offer.offerID,
            counterpartyID: observation.counterpartyID,
            accept: accept,
            reason: reason
        )
    }

    public func expiredBarterOfferIDs() -> [AgentBarterOfferID] {
        guard let state = barterState else { return [] }
        return state.offers.filter {
            $0.status.isPending && $0.expiresAtTick < tick
        }.map(\.offerID).sorted()
    }

    public mutating func recordBarterOpportunity(
        _ observation: AgentBarterOpportunityObservation
    ) throws {
        var candidate = self
        try candidate.recordBarterOpportunityInPlace(observation)
        self = candidate
    }

    mutating func recordBarterOpportunityInPlace(
        _ observation: AgentBarterOpportunityObservation
    ) throws {
        guard var state = barterState else {
            throw AgentSessionError.barter(.disabled)
        }
        try validateBarterOpportunity(observation, state: state)
        if let existing = state.opportunities.first(where: {
            $0.opportunityID == observation.opportunityID
        }) {
            guard existing == observation else {
                throw AgentSessionError.barter(.invalidOpportunity(observation.opportunityID))
            }
            return
        }
        state.opportunities.removeAll { $0.expiresAtTick < tick }
        guard state.opportunities.count < state.configuration.maximumOpportunities else {
            throw AgentSessionError.barter(.capacityReached("opportunities"))
        }
        try prevalidateCausalAppend(count: 1)
        guard let event = try recordCausalEvent(
            kind: .barterOpportunityObserved, origin: .barterTransition,
            actorID: observation.offerorID,
            operationID: AgentOperationID(rawValue: "barter-observe:\(observation.opportunityID)"),
            causes: [observation.offerorReason.causalEventID,
                     observation.counterpartyReason.causalEventID].sorted(),
            payload: .operation(
                status: "local",
                detail: "opportunity=\(observation.opportunityID) distance=\(observation.distance) offered=\(observation.offered.material.identity.itemKey):\(observation.offered.material.count) requested=\(observation.requested.material.identity.itemKey):\(observation.requested.material.count)"
            ),
            summary: "local barter opportunity observed"
        ) else { throw AgentSessionError.barter(.causalLedgerRequired) }
        state.opportunities.append(observation)
        state.opportunities.sort { $0.opportunityID < $1.opportunityID }
        state.lastBarterEventID = event.eventID
        barterState = state
        try validateBarterStateIfEnabled()
    }

    public mutating func createBarterOffer(
        offerID: AgentBarterOfferID,
        opportunityID: String,
        actorID: AgentID
    ) throws {
        var candidate = self
        try candidate.createBarterOfferInPlace(
            offerID: offerID, opportunityID: opportunityID, actorID: actorID
        )
        self = candidate
    }

    mutating func createBarterOfferInPlace(
        offerID: AgentBarterOfferID,
        opportunityID: String,
        actorID: AgentID
    ) throws {
        guard var state = barterState else { throw AgentSessionError.barter(.disabled) }
        let offerOperationID = "barter-offer:\(offerID.rawValue)"
        guard let opportunity = state.opportunities.first(where: {
            $0.opportunityID == opportunityID
        }), opportunity.expiresAtTick >= tick, opportunity.offerorID == actorID,
              !state.offers.contains(where: { $0.offerID == offerID }),
              !state.processedOperationIDs.contains(offerOperationID),
              !barterAssetReserved(opportunity.offered.assetID, in: state),
              !barterAssetReserved(opportunity.requested.assetID, in: state) else {
            throw AgentSessionError.barter(.invalidOffer(offerID.rawValue))
        }
        let logicalOperationID = "barter:\(offerID.rawValue)"
        try prevalidateNewExactAssetCommitment(
            assetID: opportunity.offered.assetID,
            logicalOperationID: logicalOperationID
        )
        try prevalidateNewExactAssetCommitment(
            assetID: opportunity.requested.assetID,
            logicalOperationID: logicalOperationID
        )
        compactTerminalBarterOffersForCapacity(state: &state)
        guard state.offers.count < state.configuration.maximumOffers else {
            throw AgentSessionError.barter(.capacityReached("offers"))
        }
        try prevalidateCausalAppend(count: 1)
        guard let event = try recordCausalEvent(
            kind: .barterOfferCreated, origin: .barterTransition,
            actorID: actorID,
            operationID: AgentOperationID(rawValue: "barter-offer:\(offerID.rawValue)"),
            causes: [state.lastBarterEventID],
            payload: .operation(
                status: "open",
                detail: "offer=\(offerID.rawValue) to=\(opportunity.counterpartyID.rawValue) offered=\(opportunity.offered.assetID.rawValue) requested=\(opportunity.requested.assetID.rawValue)"
            ),
            summary: "barter offer created; physical custody unchanged"
        ) else { throw AgentSessionError.barter(.causalLedgerRequired) }
        state.offers.append(AgentBarterOffer(
            offerID: offerID, opportunity: opportunity, offeredAtTick: tick,
            expiresAtTick: tick + state.configuration.offerLifetimeTicks,
            status: .open, offerEventID: event.eventID,
            decisionEventID: nil, terminalReason: nil
        ))
        state.offers.sort { $0.offerID < $1.offerID }
        retainProcessedBarterOperationID(offerOperationID, state: &state)
        state.lastBarterEventID = event.eventID
        barterState = state
        try validateBarterStateIfEnabled()
    }

    public mutating func decideBarterOffer(
        offerID: AgentBarterOfferID,
        counterpartyID: AgentID,
        accept: Bool,
        reason: String
    ) throws {
        var candidate = self
        try candidate.decideBarterOfferInPlace(
            offerID: offerID, counterpartyID: counterpartyID,
            accept: accept, reason: reason
        )
        self = candidate
    }

    mutating func decideBarterOfferInPlace(
        offerID: AgentBarterOfferID,
        counterpartyID: AgentID,
        accept: Bool,
        reason: String
    ) throws {
        guard var state = barterState,
              let index = state.offers.firstIndex(where: { $0.offerID == offerID }),
              state.offers[index].status == .open,
              state.offers[index].opportunity.counterpartyID == counterpartyID,
              !reason.isEmpty, reason.utf8.count <= 256 else {
            throw AgentSessionError.barter(.invalidDecision(offerID.rawValue))
        }
        if state.offers[index].expiresAtTick < tick {
            try terminalizeBarterOffer(
                at: index, status: .expired, actorID: counterpartyID,
                reason: "offer expired before decision", state: &state
            )
            barterState = state
            throw AgentSessionError.barter(.staleOffer(offerID.rawValue))
        }
        let status: AgentBarterOfferStatus = accept ? .accepted : .rejected
        try terminalizeBarterOffer(
            at: index, status: status, actorID: counterpartyID,
            reason: reason, state: &state
        )
        barterState = state
        try validateBarterStateIfEnabled()
    }

    public mutating func withdrawBarterOffer(
        offerID: AgentBarterOfferID,
        actorID: AgentID,
        reason: String = "withdrawn by offeror"
    ) throws {
        guard var state = barterState,
              let index = state.offers.firstIndex(where: { $0.offerID == offerID }),
              state.offers[index].status == .open,
              state.offers[index].opportunity.offerorID == actorID else {
            throw AgentSessionError.barter(.invalidDecision(offerID.rawValue))
        }
        try terminalizeBarterOffer(
            at: index, status: .withdrawn, actorID: actorID,
            reason: reason, state: &state
        )
        barterState = state
        try validateBarterStateIfEnabled()
    }

    public func prevalidateVerifiedBarter(
        _ outcome: AgentVerifiedBarterOutcome
    ) throws {
        guard let state = barterState,
              let offer = state.offers.first(where: { $0.offerID == outcome.offerID }),
              offer.status == .accepted else {
            throw AgentSessionError.barter(.staleOffer(outcome.offerID.rawValue))
        }
        try prevalidateAcceptedBarterCommitment(offerID: outcome.offerID)
        guard !state.processedOperationIDs.contains(outcome.operationID),
              outcome.completedAtTick == tick,
              validBarterText(outcome.operationID, maximum: 256),
              validBarterText(outcome.offeredLeg.physicalReceiptID, maximum: 256),
              validBarterText(outcome.requestedLeg.physicalReceiptID, maximum: 256),
              outcome.offeredLeg.assetID == offer.opportunity.offered.assetID,
              outcome.requestedLeg.assetID == offer.opportunity.requested.assetID,
              outcome.offeredLeg.sourceObservation
                == offer.opportunity.offered.holderObservation,
              outcome.requestedLeg.sourceObservation
                == offer.opportunity.requested.holderObservation,
              outcome.offeredLeg.destinationObservation.holder
                == .agent(offer.opportunity.counterpartyID),
              outcome.requestedLeg.destinationObservation.holder
                == .agent(offer.opportunity.offerorID),
              outcome.offeredLeg.destinationObservation.materialIdentity
                == offer.opportunity.offered.material.identity,
              outcome.requestedLeg.destinationObservation.materialIdentity
                == offer.opportunity.requested.material.identity,
              outcome.offeredLeg.destinationObservation.quantity
                == offer.opportunity.offered.material.count,
              outcome.requestedLeg.destinationObservation.quantity
                == offer.opportunity.requested.material.count else {
            throw AgentSessionError.barter(.invalidOutcome(outcome.operationID))
        }
        guard evaluateCurrentBarterMaterialUse(
                requestID: "barter:\(offer.offerID.rawValue):offered",
                assetID: offer.opportunity.offered.assetID,
                actorID: offer.opportunity.offerorID,
                currentObservation: offer.opportunity.offered.holderObservation,
                acceptsAdapterRefreshedCustody: true
              )?.verdict == .allowed,
              evaluateCurrentBarterMaterialUse(
                requestID: "barter:\(offer.offerID.rawValue):requested",
                assetID: offer.opportunity.requested.assetID,
                actorID: offer.opportunity.counterpartyID,
                currentObservation: offer.opportunity.requested.holderObservation,
                acceptsAdapterRefreshedCustody: true
              )?.verdict == .allowed else {
            throw AgentSessionError.barter(.unauthorized(
                "current exact-asset disposition"
            ))
        }
        try prevalidateCausalAppend(count: 3)
    }

    public mutating func recordVerifiedBarter(
        _ outcome: AgentVerifiedBarterOutcome
    ) throws {
        var candidate = self
        try candidate.recordVerifiedBarterInPlace(outcome)
        self = candidate
    }

    mutating func recordVerifiedBarterInPlace(
        _ outcome: AgentVerifiedBarterOutcome
    ) throws {
        try prevalidateVerifiedBarter(outcome)
        guard var state = barterState,
              var rights = materialRightsState,
              let offerIndex = state.offers.firstIndex(where: {
                  $0.offerID == outcome.offerID
              }) else { throw AgentSessionError.barter(.invalidOutcome(outcome.operationID)) }
        let offerBefore = state.offers[offerIndex]
        let rightsOperationIDs = [
            outcome.operationID + ":rights:offered",
            outcome.operationID + ":rights:requested",
        ]
        guard rightsOperationIDs.allSatisfy({
            !rights.processedOperationIDs.contains($0)
        }) else {
            throw AgentSessionError.barter(.duplicateOperation(outcome.operationID))
        }
        try transferVoluntaryBarterRights(
            leg: outcome.offeredLeg,
            from: offerBefore.opportunity.offerorID,
            to: offerBefore.opportunity.counterpartyID,
            offerID: outcome.offerID,
            rights: &rights
        )
        try transferVoluntaryBarterRights(
            leg: outcome.requestedLeg,
            from: offerBefore.opportunity.counterpartyID,
            to: offerBefore.opportunity.offerorID,
            offerID: outcome.offerID,
            rights: &rights
        )
        guard let event = try recordCausalEvent(
            kind: .barterCompleted, origin: .barterTransition,
            actorID: offerBefore.opportunity.offerorID,
            operationID: AgentOperationID(rawValue: outcome.operationID),
            causes: [offerBefore.decisionEventID ?? offerBefore.offerEventID],
            payload: .operation(
                status: "completed",
                detail: "offer=\(outcome.offerID.rawValue) offeredReceipt=\(outcome.offeredLeg.physicalReceiptID) requestedReceipt=\(outcome.requestedLeg.physicalReceiptID)"
            ),
            summary: "two-sided physical barter verified and published"
        ) else { throw AgentSessionError.barter(.causalLedgerRequired) }
        let rightsPublications = [
            (rightsOperationIDs[0], outcome.offeredLeg,
                offerBefore.opportunity.counterpartyID),
            (rightsOperationIDs[1], outcome.requestedLeg,
                offerBefore.opportunity.offerorID),
        ]
        for (operationID, leg, receiverID) in rightsPublications {
            guard let rightsEvent = try recordCausalEvent(
                kind: .materialPhysicalCustodyObserved,
                origin: .materialRightsTransition,
                actorID: receiverID,
                operationID: AgentOperationID(rawValue: operationID),
                causes: [event.eventID],
                payload: .operation(
                    status: "succeeded",
                    detail: "asset=\(leg.assetID.rawValue) holder=\(receiverID.rawValue) owner=\(receiverID.rawValue)"
                ),
                summary: "verified barter rights transfer asset=\(leg.assetID.rawValue)"
            ) else { throw AgentSessionError.barter(.causalLedgerRequired) }
            rights.processedOperationIDs.append(operationID)
            if rights.processedOperationIDs.count
                > rights.configuration.maximumProcessedOperationIDs {
                rights.processedOperationIDs.removeFirst()
                rights.droppedOperationIDCount += 1
            }
            rights.recentTransitions.append(AgentMaterialRightsTransition(
                operationID: operationID,
                kind: .physicalTransfer,
                assetID: leg.assetID,
                status: "succeeded",
                reason: "verified voluntary barter custody and ownership exchange",
                eventID: rightsEvent.eventID
            ))
            if rights.recentTransitions.count
                > rights.configuration.maximumRetainedTransitions {
                rights.recentTransitions.removeFirst()
                rights.droppedTransitionCount += 1
            }
        }
        state.offers[offerIndex].status = .completed
        state.offers[offerIndex].terminalReason = "two physical legs verified"
        state.offers[offerIndex].decisionEventID = event.eventID
        let completedOffer = state.offers[offerIndex]
        state.records.append(AgentBarterRecord(
            offer: completedOffer, outcome: outcome, causalEventID: event.eventID
        ))
        if state.records.count > state.configuration.maximumRecords {
            state.records.removeFirst()
            state.evictionCount += 1
        }
        retainProcessedBarterOperationID(outcome.operationID, state: &state)
        state.totalCompletedCount += 1
        state.lastBarterEventID = event.eventID
        materialRightsState = rights
        barterState = state
        fulfillProductionNeedFromVerifiedReceipt(
            offerBefore.opportunity.offerorReason.needID,
            received: offerBefore.opportunity.requested.material,
            operationID: outcome.operationID
        )
        fulfillProductionNeedFromVerifiedReceipt(
            offerBefore.opportunity.counterpartyReason.needID,
            received: offerBefore.opportunity.offered.material,
            operationID: outcome.operationID
        )
        try validateMaterialRightsStateIfEnabled()
        try validateBarterStateIfEnabled()
    }

    public mutating func markBarterOfferFailed(
        offerID: AgentBarterOfferID,
        status: AgentBarterOfferStatus = .stale,
        reason: String
    ) throws {
        guard status == .stale || status == .failed || status == .expired,
              var state = barterState,
              let index = state.offers.firstIndex(where: { $0.offerID == offerID }),
              state.offers[index].status.isPending else {
            throw AgentSessionError.barter(.invalidDecision(offerID.rawValue))
        }
        try terminalizeBarterOffer(
            at: index, status: status,
            actorID: state.offers[index].opportunity.offerorID,
            reason: reason, state: &state
        )
        barterState = state
        try validateBarterStateIfEnabled()
    }

    func validateBarterStateIfEnabled() throws {
        guard let state = barterState else { return }
        guard state.opportunities.count <= state.configuration.maximumOpportunities,
              state.offers.count <= state.configuration.maximumOffers,
              state.records.count <= state.configuration.maximumRecords,
              state.processedOperationIDs.count
                <= state.configuration.maximumProcessedOperations,
              Set(state.opportunities.map(\.opportunityID)).count
                == state.opportunities.count,
              Set(state.offers.map(\.offerID)).count == state.offers.count,
              Set(state.processedOperationIDs).count
                == state.processedOperationIDs.count else {
            throw AgentSessionError.barter(.invalidState("global bounds"))
        }
        var reserved: Set<AgentMaterialAssetID> = []
        for offer in state.offers where offer.status.isPending {
            guard reserved.insert(offer.opportunity.offered.assetID).inserted,
                  reserved.insert(offer.opportunity.requested.assetID).inserted,
                  offer.opportunity.offerorID != offer.opportunity.counterpartyID,
                  offer.opportunity.offered.assetID
                    != offer.opportunity.requested.assetID else {
                throw AgentSessionError.barter(.invalidState("duplicate reservation"))
            }
        }
        guard state.records.allSatisfy({
            $0.offer.status == .completed
                && $0.outcome.offerID == $0.offer.offerID
        }) else { throw AgentSessionError.barter(.invalidState("record")) }
        try validateComposedExactAssetCommitments()
    }

    private func validateBarterOpportunity(
        _ observation: AgentBarterOpportunityObservation,
        state: AgentBarterState
    ) throws {
        guard statesById[observation.offerorID.rawValue] != nil else {
            throw AgentSessionError.barter(.unknownAgent(observation.offerorID))
        }
        guard statesById[observation.counterpartyID.rawValue] != nil else {
            throw AgentSessionError.barter(.unknownAgent(observation.counterpartyID))
        }
        guard observation.offerorID != observation.counterpartyID,
              observation.offered.holderID == observation.offerorID,
              observation.requested.holderID == observation.counterpartyID,
              observation.offered.assetID != observation.requested.assetID,
              observation.offered.material.count > 0,
              observation.requested.material.count > 0,
              observation.offered.holderObservation.holder
                == .agent(observation.offerorID),
              observation.requested.holderObservation.holder
                == .agent(observation.counterpartyID),
              observation.offered.holderObservation.materialIdentity
                == observation.offered.material.identity,
              observation.requested.holderObservation.materialIdentity
                == observation.requested.material.identity,
              observation.offered.holderObservation.quantity
                == observation.offered.material.count,
              observation.requested.holderObservation.quantity
                == observation.requested.material.count,
              observation.offered.holderObservation.observedAtTick == tick,
              observation.requested.holderObservation.observedAtTick == tick,
              observation.distance >= 0,
              observation.distance <= state.configuration.maximumLocalDistance,
              observation.lineOfSight, observation.chunksReady,
              observation.observedAtTick == tick,
              observation.expiresAtTick == tick + state.configuration.offerLifetimeTicks,
              validBarterText(observation.opportunityID, maximum: 160) else {
            throw AgentSessionError.barter(.invalidOpportunity(observation.opportunityID))
        }
        try validateBarterReason(
            observation.offerorReason, actorID: observation.offerorID,
            received: observation.requested.material
        )
        try validateBarterReason(
            observation.counterpartyReason, actorID: observation.counterpartyID,
            received: observation.offered.material
        )
        try validateBarterLegProvenance(observation.offered)
        try validateBarterLegProvenance(observation.requested)
    }

    private func validateBarterReason(
        _ reason: AgentBarterValueReason,
        actorID: AgentID,
        received: AgentMaterialStackSnapshot
    ) throws {
        guard let need = productionState?.needs.first(where: {
            $0.needID == reason.needID && $0.status == .active
        }), need.actorID == actorID,
              reason == AgentBarterValueReason(need: need),
              reason.desiredItemKey == received.identity.itemKey,
              reason.quantity == received.count else {
            throw AgentSessionError.barter(.invalidOpportunity(reason.needID.rawValue))
        }
    }

    private func validateBarterLegProvenance(_ leg: AgentBarterLeg) throws {
        guard materialProductionProvenanceMatches(
            assetID: leg.assetID,
            material: leg.material,
            operationIDs: leg.productionOperationIDs
        ) else {
            throw AgentSessionError.barter(.invalidOpportunity(leg.assetID.rawValue))
        }
    }

    /// Material Rights remains the social constraint while Pebble supplies a
    /// fresh full-custody fingerprint as immediate physical authority. An
    /// unrelated slot change may replace the historical fingerprint only for
    /// the same exact asset, holder, identity, and quantity. Discovery binds
    /// the observation to the current tick; once an offer is published, that
    /// bounded observation remains immutable until physical prevalidation.
    public func evaluateCurrentBarterMaterialUse(
        requestID: String,
        assetID: AgentMaterialAssetID,
        actorID: AgentID,
        currentObservation: AgentMaterialHolderObservation,
        acceptsAdapterRefreshedCustody: Bool = false
    ) -> AgentMaterialUseDecision? {
        guard let record = materialRightsState?.records.first(where: {
                  $0.asset.assetID == assetID
              }), record.lastVerifiedHolder.holder == .agent(actorID),
              currentObservation.holder == record.lastVerifiedHolder.holder,
              currentObservation.materialIdentity
                == record.lastVerifiedHolder.materialIdentity,
              currentObservation.quantity == record.lastVerifiedHolder.quantity,
              acceptsAdapterRefreshedCustody || (
                currentObservation.custodyFingerprint
                    == record.lastVerifiedHolder.custodyFingerprint
                    && currentObservation.physicalReceiptID
                        == record.lastVerifiedHolder.physicalReceiptID
              )
        else { return nil }
        return evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: requestID, assetID: assetID, actorID: actorID,
            use: .transferCustody,
            verifiedHolder: record.lastVerifiedHolder
        ))
    }

    private func barterAssetReserved(
        _ assetID: AgentMaterialAssetID,
        in state: AgentBarterState
    ) -> Bool {
        state.offers.contains {
            $0.status.isPending
                && ($0.opportunity.offered.assetID == assetID
                    || $0.opportunity.requested.assetID == assetID)
        }
    }

    private func bestBarterReason(
        actorID: AgentID,
        received: AgentMaterialStackSnapshot,
        configuration: AgentBarterConfiguration
    ) -> AgentBarterValueReason? {
        productionState?.needs.filter {
            $0.actorID == actorID && $0.status == .active
        }.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            if lhs.createdAtTick != rhs.createdAtTick {
                return lhs.createdAtTick < rhs.createdAtTick
            }
            return lhs.needID < rhs.needID
        }.prefix(configuration.maximumActiveNeedsPerAgent).first {
            $0.desiredOutputItemKey == received.identity.itemKey
                && $0.quantity == received.count
        }.map(AgentBarterValueReason.init(need:))
    }

    private func barterReasonPriority(_ reason: AgentBarterValueReason) -> Int {
        productionState?.needs.first(where: {
            $0.needID == reason.needID
        })?.priority ?? -1
    }

    /// Oldest terminal projection goes first. Open and accepted offers are
    /// reservation authority and are never eligible for capacity eviction.
    private func compactTerminalBarterOffersForCapacity(
        state: inout AgentBarterState
    ) {
        while state.offers.count >= state.configuration.maximumOffers {
            let terminal = state.offers.indices.filter {
                !state.offers[$0].status.isPending
            }.min { lhs, rhs in
                let left = state.offers[lhs]
                let right = state.offers[rhs]
                let leftSequence = (left.decisionEventID ?? left.offerEventID)
                    .sequence.rawValue
                let rightSequence = (right.decisionEventID ?? right.offerEventID)
                    .sequence.rawValue
                if leftSequence != rightSequence {
                    return leftSequence < rightSequence
                }
                return left.offerID < right.offerID
            }
            guard let terminal else { return }
            state.offers.remove(at: terminal)
            state.evictionCount += 1
        }
    }

    private func retainProcessedBarterOperationID(
        _ operationID: String,
        state: inout AgentBarterState
    ) {
        state.processedOperationIDs.append(operationID)
        if state.processedOperationIDs.count
            > state.configuration.maximumProcessedOperations {
            state.processedOperationIDs.removeFirst()
            state.evictionCount += 1
        }
    }

    private mutating func terminalizeBarterOffer(
        at index: Int,
        status: AgentBarterOfferStatus,
        actorID: AgentID,
        reason: String,
        state: inout AgentBarterState
    ) throws {
        let offer = state.offers[index]
        let isAcceptance = status == .accepted
        try prevalidateCausalAppend(count: 1)
        guard let event = try recordCausalEvent(
            kind: isAcceptance ? .barterOfferAccepted : .barterOfferClosed,
            origin: .barterTransition, actorID: actorID,
            operationID: AgentOperationID(
                rawValue: "barter-decision:\(offer.offerID.rawValue):\(status.rawValue)"
            ),
            causes: [offer.offerEventID],
            payload: .operation(
                status: status.rawValue,
                detail: "offer=\(offer.offerID.rawValue) reason=\(String(reason.prefix(256)))"
            ),
            summary: "barter offer \(status.rawValue); physical custody unchanged"
        ) else { throw AgentSessionError.barter(.causalLedgerRequired) }
        state.offers[index].status = status
        state.offers[index].decisionEventID = event.eventID
        state.offers[index].terminalReason = String(reason.prefix(256))
        state.lastBarterEventID = event.eventID
    }

    private func transferVoluntaryBarterRights(
        leg: AgentVerifiedBarterLeg,
        from: AgentID,
        to: AgentID,
        offerID: AgentBarterOfferID,
        rights: inout AgentMaterialRightsState
    ) throws {
        guard let index = rights.records.firstIndex(where: {
            $0.asset.assetID == leg.assetID
        }), rights.records[index].lastVerifiedHolder.holder
                == leg.sourceObservation.holder,
              rights.records[index].lastVerifiedHolder.materialIdentity
                == leg.sourceObservation.materialIdentity,
              rights.records[index].lastVerifiedHolder.quantity
                == leg.sourceObservation.quantity,
              rights.records[index].recognizedOwnership?.ownerID == from,
              rights.records[index].claims.count
                < rights.configuration.maximumClaimsPerAsset else {
            throw AgentSessionError.barter(.unauthorized(leg.assetID.rawValue))
        }
        let oldRecognizedClaim = rights.records[index].recognizedOwnership?.claimID
        rights.records[index].claims.removeAll {
            $0.claimID == oldRecognizedClaim && $0.claimantID == from
        }
        guard let claimID = AgentMaterialClaimID(
            rawValue: "barter:\(offerID.rawValue):received:\(leg.assetID.rawValue)"
        ) else { throw AgentSessionError.barter(.invalidOutcome(offerID.rawValue)) }
        rights.records[index].claims.append(AgentMaterialClaim(
            claimID: claimID, claimantID: to, basis: .received,
            assertedAtTick: tick
        ))
        rights.records[index].claims.sort { $0.claimID < $1.claimID }
        rights.records[index].recognizedOwnership = AgentMaterialRecognizedOwnership(
            claimID: claimID, ownerID: to,
            recognizingAgentIDs: [from, to].sorted(), recognizedAtTick: tick
        )
        rights.records[index].custodianID = to
        rights.records[index].permissions.removeAll()
        rights.records[index].lastVerifiedHolder = leg.destinationObservation
    }

    private func validBarterText(_ text: String, maximum: Int) -> Bool {
        !text.isEmpty && text.utf8.count <= maximum && !text.contains("\n")
    }
}
