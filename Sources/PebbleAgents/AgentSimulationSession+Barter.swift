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
        guard let opportunity = state.opportunities.first(where: {
            $0.opportunityID == opportunityID
        }), opportunity.expiresAtTick >= tick, opportunity.offerorID == actorID,
              !state.offers.contains(where: { $0.offerID == offerID }),
              !barterAssetReserved(opportunity.offered.assetID, in: state),
              !barterAssetReserved(opportunity.requested.assetID, in: state) else {
            throw AgentSessionError.barter(.invalidOffer(offerID.rawValue))
        }
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
        let offeredDecision = evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: "barter:\(offer.offerID.rawValue):offered",
            assetID: offer.opportunity.offered.assetID,
            actorID: offer.opportunity.offerorID,
            use: .transferCustody,
            verifiedHolder: offer.opportunity.offered.holderObservation
        ))
        let requestedDecision = evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: "barter:\(offer.offerID.rawValue):requested",
            assetID: offer.opportunity.requested.assetID,
            actorID: offer.opportunity.counterpartyID,
            use: .transferCustody,
            verifiedHolder: offer.opportunity.requested.holderObservation
        ))
        guard offeredDecision.verdict == .allowed,
              requestedDecision.verdict == .allowed else {
            throw AgentSessionError.barter(.unauthorized(
                "offered=\(offeredDecision.reason.rawValue) requested=\(requestedDecision.reason.rawValue)"
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
        state.processedOperationIDs.append(outcome.operationID)
        if state.processedOperationIDs.count
            > state.configuration.maximumProcessedOperations {
            state.processedOperationIDs.removeFirst()
            state.evictionCount += 1
        }
        state.totalCompletedCount += 1
        state.lastBarterEventID = event.eventID
        materialRightsState = rights
        barterState = state
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
        guard !observation.offered.productionOperationIDs.isEmpty
                || !observation.requested.productionOperationIDs.isEmpty else {
            throw AgentSessionError.barter(.invalidOpportunity(observation.opportunityID))
        }
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
        guard leg.productionOperationIDs == Array(Set(leg.productionOperationIDs)).sorted()
        else { throw AgentSessionError.barter(.invalidOpportunity(leg.assetID.rawValue)) }
        if leg.productionOperationIDs.isEmpty { return }
        let records = productionState?.records.filter {
            leg.productionOperationIDs.contains($0.operationID)
        } ?? []
        guard records.count == leg.productionOperationIDs.count,
              records.allSatisfy({
                  $0.actorID == leg.holderID
                    && $0.outputProduced.identity == leg.material.identity
              }), records.reduce(0, { $0 + $1.outputProduced.count })
                == leg.material.count else {
            throw AgentSessionError.barter(.invalidOpportunity(leg.assetID.rawValue))
        }
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
        }), rights.records[index].lastVerifiedHolder == leg.sourceObservation,
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
