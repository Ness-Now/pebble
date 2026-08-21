extension AgentSimulationSession {
    public var contractsEnabled: Bool { contractState != nil }

    public func contractSnapshot() -> AgentContractSnapshot {
        guard let state = contractState else {
            return AgentContractSnapshot(
                enabled: false, configuration: nil, opportunities: [], proposals: [],
                obligations: [], totalObligationCount: 0, totalFulfilledCount: 0,
                activeObligationCount: 0, outstandingDebtCount: 0,
                evictionCount: 0
            )
        }
        return AgentContractSnapshot(
            enabled: true, configuration: state.configuration,
            opportunities: state.opportunities.sorted {
                $0.opportunityID < $1.opportunityID
            },
            proposals: state.proposals.sorted { $0.proposalID < $1.proposalID },
            obligations: state.obligations.sorted { $0.obligationID < $1.obligationID },
            totalObligationCount: state.totalObligationCount,
            totalFulfilledCount: state.totalFulfilledCount,
            activeObligationCount: state.obligations.filter(\.status.isActive).count,
            outstandingDebtCount: state.obligations.filter(\.status.isDebtLike).count,
            evictionCount: state.evictionCount
        )
    }

    public mutating func setContractsEnabled(
        _ enabled: Bool,
        configuration: AgentContractConfiguration = .live
    ) throws {
        if enabled {
            guard contractState == nil else { return }
            guard causalLedger.isEnabled else {
                throw AgentSessionError.contract(.causalLedgerRequired)
            }
            guard materialRightsState != nil else {
                throw AgentSessionError.contract(.materialRightsRequired)
            }
            guard productionState != nil else {
                throw AgentSessionError.contract(.productionRequired)
            }
            try prevalidateCausalAppend(count: 1)
            guard let event = try recordCausalEvent(
                kind: .contractsInitialized, origin: .contractTransition,
                payload: .feature(name: "contracts", enabled: true),
                summary: "durable contracts initialized without creating matter"
            ) else { throw AgentSessionError.contract(.causalLedgerRequired) }
            contractState = AgentContractState(
                configuration: configuration, opportunities: [], proposals: [],
                obligations: [], processedOperationIDs: [], totalObligationCount: 0,
                totalFulfilledCount: 0, evictionCount: 0,
                initializedEventID: event.eventID,
                lastContractEventID: event.eventID
            )
        } else if contractState != nil {
            throw AgentSessionError.contract(.unsafeDisable)
        }
    }

    /// Pure cognition over bounded current local facts. A returned opportunity
    /// promises future performance and therefore does not require or imply that
    /// the promisor currently holds the promised material.
    public func discoverContractOpportunities(
        from candidates: [AgentContractOpportunityObservation]
    ) throws -> [AgentContractOpportunityObservation] {
        guard let state = contractState else {
            throw AgentSessionError.contract(.disabled)
        }
        guard candidates.count <= state.configuration.maximumOpportunities,
              Set(candidates.map(\.opportunityID)).count == candidates.count else {
            throw AgentSessionError.contract(.invalidOpportunity("discovery-bounds"))
        }
        var discoveries: [AgentContractOpportunityObservation] = []
        for candidate in candidates.sorted(by: {
            $0.opportunityID < $1.opportunityID
        }) {
            try validateContractOpportunity(candidate, state: state)
            guard !contractConsiderationReserved(
                candidate.consideration.assetID, in: state
            ), !exactAssetIsEconomicallyCommitted(
                candidate.consideration.assetID
            ), !state.obligations.contains(where: {
                $0.status.isActive
                    && $0.promisorID == candidate.promisorID
                    && $0.promiseeID == candidate.promiseeID
                    && $0.promisedPerformance == candidate.promisedPerformance
            }), !contractReasonExchangeAlreadyNegotiated(
                candidate, in: state
            ) else { continue }
            discoveries.append(candidate)
            if discoveries.count == state.configuration.maximumDiscoveriesPerTick {
                break
            }
        }
        return discoveries
    }

    public mutating func recordContractOpportunity(
        _ observation: AgentContractOpportunityObservation
    ) throws {
        var candidate = self
        try candidate.recordContractOpportunityInPlace(observation)
        self = candidate
    }

    mutating func recordContractOpportunityInPlace(
        _ observation: AgentContractOpportunityObservation
    ) throws {
        guard var state = contractState else {
            throw AgentSessionError.contract(.disabled)
        }
        try validateContractOpportunity(observation, state: state)
        if let existing = state.opportunities.first(where: {
            $0.opportunityID == observation.opportunityID
        }) {
            guard existing == observation else {
                throw AgentSessionError.contract(
                    .invalidOpportunity(observation.opportunityID)
                )
            }
            return
        }
        guard !contractReasonExchangeAlreadyNegotiated(
            observation, in: state
        ) else {
            throw AgentSessionError.contract(
                .invalidOpportunity(observation.opportunityID)
            )
        }
        state.opportunities.removeAll { $0.expiresAtTick < tick }
        guard state.opportunities.count < state.configuration.maximumOpportunities else {
            throw AgentSessionError.contract(.capacityReached("opportunities"))
        }
        try prevalidateCausalAppend(count: 1)
        guard let event = try recordCausalEvent(
            kind: .contractOpportunityObserved, origin: .contractTransition,
            actorID: observation.promisorID,
            subjectID: observation.promiseeID,
            operationID: AgentOperationID(
                rawValue: "contract-observe:\(observation.opportunityID)"
            ),
            causes: [observation.promisorReason.causalEventID,
                     observation.promiseeReason.causalEventID].sorted(),
            payload: .operation(
                status: "local-future-performance",
                detail: "opportunity=\(observation.opportunityID) consideration=\(observation.consideration.assetID.rawValue) promised=\(observation.promisedPerformance.material.identity.itemKey):\(observation.promisedPerformance.material.count)"
            ),
            summary: "local future-performance contract opportunity observed"
        ) else { throw AgentSessionError.contract(.causalLedgerRequired) }
        state.opportunities.append(observation)
        state.opportunities.sort { $0.opportunityID < $1.opportunityID }
        state.lastContractEventID = event.eventID
        contractState = state
        try validateContractStateIfEnabled()
    }

    public func nextAutonomousPromiseProposal() -> AgentPromiseProposalDecision? {
        guard let state = contractState else { return nil }
        let opportunity = state.opportunities.filter {
            $0.observedAtTick == tick && $0.expiresAtTick >= tick
                && !contractConsiderationReserved($0.consideration.assetID, in: state)
                && !exactAssetIsEconomicallyCommitted(
                    $0.consideration.assetID
                )
                && currentContractReason(
                    $0.promisorReason, actorID: $0.promisorID,
                    received: $0.consideration.material
                )
                && currentContractReason(
                    $0.promiseeReason, actorID: $0.promiseeID,
                    received: $0.promisedPerformance.material
                )
        }.sorted { lhs, rhs in
            let left = contractReasonPriority(lhs.promisorReason)
            let right = contractReasonPriority(rhs.promisorReason)
            if left != right { return left > right }
            let leftPromisee = contractReasonPriority(lhs.promiseeReason)
            let rightPromisee = contractReasonPriority(rhs.promiseeReason)
            if leftPromisee != rightPromisee { return leftPromisee > rightPromisee }
            return lhs.opportunityID < rhs.opportunityID
        }.first
        guard let opportunity,
              let proposalID = AgentPromiseProposalID(
                  rawValue: "promise-"
                    + AgentAutonomousActivityDigest.make(opportunity.opportunityID)
              ), !state.processedOperationIDs.contains(
                  "promise-propose:\(proposalID.rawValue)"
              ) else { return nil }
        return AgentPromiseProposalDecision(
            proposalID: proposalID, opportunityID: opportunity.opportunityID,
            promisorID: opportunity.promisorID,
            reason: "promisor needs current consideration and commits exact future material"
        )
    }

    public mutating func createPromiseProposal(
        proposalID: AgentPromiseProposalID,
        opportunityID: String,
        promisorID: AgentID
    ) throws {
        var candidate = self
        try candidate.createPromiseProposalInPlace(
            proposalID: proposalID, opportunityID: opportunityID,
            promisorID: promisorID
        )
        self = candidate
    }

    mutating func createPromiseProposalInPlace(
        proposalID: AgentPromiseProposalID,
        opportunityID: String,
        promisorID: AgentID
    ) throws {
        guard var state = contractState else {
            throw AgentSessionError.contract(.disabled)
        }
        let operationID = "promise-propose:\(proposalID.rawValue)"
        guard let opportunity = state.opportunities.first(where: {
            $0.opportunityID == opportunityID
        }), opportunity.promisorID == promisorID,
              opportunity.expiresAtTick >= tick,
              !state.proposals.contains(where: { $0.proposalID == proposalID }),
              !state.processedOperationIDs.contains(operationID),
              !contractConsiderationReserved(
                  opportunity.consideration.assetID, in: state
              ) else {
            throw AgentSessionError.contract(.invalidProposal(proposalID.rawValue))
        }
        try prevalidateNewExactAssetCommitment(
            assetID: opportunity.consideration.assetID,
            logicalOperationID: "contract:\(proposalID.rawValue)"
        )
        compactContractProposalsForCapacity(state: &state)
        guard state.proposals.count < state.configuration.maximumProposals else {
            throw AgentSessionError.contract(.capacityReached("proposals"))
        }
        try prevalidateCausalAppend(count: 1)
        guard let event = try recordCausalEvent(
            kind: .promiseProposed, origin: .contractTransition,
            actorID: promisorID, subjectID: opportunity.promiseeID,
            operationID: AgentOperationID(rawValue: operationID),
            causes: [state.lastContractEventID],
            payload: .operation(
                status: "open",
                detail: "proposal=\(proposalID.rawValue) promisee=\(opportunity.promiseeID.rawValue) promised=\(opportunity.promisedPerformance.material.identity.itemKey):\(opportunity.promisedPerformance.material.count)"
            ),
            summary: "explicit future promise proposed; physical custody unchanged"
        ) else { throw AgentSessionError.contract(.causalLedgerRequired) }
        state.proposals.append(AgentPromiseProposal(
            proposalID: proposalID, opportunity: opportunity,
            proposedAtTick: tick,
            expiresAtTick: tick + state.configuration.proposalLifetimeTicks,
            status: .open, proposalEventID: event.eventID,
            decisionEventID: nil, terminalReason: nil
        ))
        state.proposals.sort { $0.proposalID < $1.proposalID }
        retainContractOperation(operationID, state: &state)
        state.lastContractEventID = event.eventID
        contractState = state
        try validateContractStateIfEnabled()
    }

    public func evaluateAutonomousPromiseAcceptance(
        _ observation: AgentPromiseAcceptanceObservation
    ) -> AgentPromiseAcceptanceDecision? {
        guard let state = contractState,
              let proposal = state.proposals.first(where: {
                  $0.proposalID == observation.proposalID && $0.status == .open
              }), proposal.opportunity.promiseeID == observation.promiseeID,
              observation.observedAtTick == tick else { return nil }
        let reasonCurrent = currentContractReason(
            proposal.opportunity.promiseeReason,
            actorID: observation.promiseeID,
            received: proposal.opportunity.promisedPerformance.material
        )
        let local = proposal.expiresAtTick >= tick
            && observation.distance >= 0
            && observation.distance <= state.configuration.maximumLocalDistance
            && observation.lineOfSight && observation.chunksReady
        let accept = reasonCurrent && local
        return AgentPromiseAcceptanceDecision(
            proposalID: proposal.proposalID,
            promiseeID: observation.promiseeID,
            accept: accept,
            reason: accept
                ? "promisee independently accepts exact future material terms"
                : (reasonCurrent
                    ? "current local evidence refuses acceptance"
                    : "promisee reason is no longer current")
        )
    }

    public mutating func decidePromiseProposal(
        proposalID: AgentPromiseProposalID,
        promiseeID: AgentID,
        accept: Bool,
        reason: String
    ) throws {
        var candidate = self
        try candidate.decidePromiseProposalInPlace(
            proposalID: proposalID, promiseeID: promiseeID,
            accept: accept, reason: reason
        )
        self = candidate
    }

    mutating func decidePromiseProposalInPlace(
        proposalID: AgentPromiseProposalID,
        promiseeID: AgentID,
        accept: Bool,
        reason: String
    ) throws {
        guard var state = contractState,
              let index = state.proposals.firstIndex(where: {
                  $0.proposalID == proposalID
              }), state.proposals[index].status == .open,
              state.proposals[index].opportunity.promiseeID == promiseeID,
              !reason.isEmpty, reason.utf8.count <= 256 else {
            throw AgentSessionError.contract(.invalidDecision(proposalID.rawValue))
        }
        if state.proposals[index].expiresAtTick < tick {
            try closePromiseProposal(
                at: index, status: .expired, actorID: promiseeID,
                reason: "proposal expired before acceptance", state: &state
            )
            contractState = state
            throw AgentSessionError.contract(.staleAuthority(proposalID.rawValue))
        }
        if !accept {
            try closePromiseProposal(
                at: index, status: .rejected, actorID: promiseeID,
                reason: reason, state: &state
            )
            contractState = state
            try validateContractStateIfEnabled()
            return
        }
        compactContractObligationsForCapacity(state: &state)
        guard state.obligations.count < state.configuration.maximumObligations,
              tick <= Int.max - state.configuration.performanceDueTicks else {
            throw AgentSessionError.contract(.capacityReached("obligations"))
        }
        let proposal = state.proposals[index]
        let obligationID = AgentContractObligationID(
            rawValue: "obligation-"
                + AgentAutonomousActivityDigest.make(proposalID.rawValue)
        )!
        guard !state.obligations.contains(where: {
            $0.obligationID == obligationID
        }) else {
            throw AgentSessionError.contract(.invalidObligation(obligationID.rawValue))
        }
        try prevalidateCausalAppend(count: 2)
        guard let acceptance = try recordCausalEvent(
            kind: .promiseAccepted, origin: .contractTransition,
            actorID: promiseeID, subjectID: proposal.opportunity.promisorID,
            operationID: AgentOperationID(
                rawValue: "promise-accept:\(proposalID.rawValue)"
            ), causes: [proposal.proposalEventID],
            payload: .operation(
                status: "accepted",
                detail: "proposal=\(proposalID.rawValue) reason=\(String(reason.prefix(256)))"
            ),
            summary: "promise independently accepted; physical custody unchanged"
        ), let obligationEvent = try recordCausalEvent(
            kind: .contractObligationCreated, origin: .contractTransition,
            actorID: proposal.opportunity.promisorID, subjectID: promiseeID,
            operationID: AgentOperationID(
                rawValue: "obligation-create:\(obligationID.rawValue)"
            ), causes: [acceptance.eventID],
            payload: .operation(
                status: "awaiting-consideration",
                detail: "obligation=\(obligationID.rawValue) due=\(tick + state.configuration.performanceDueTicks)"
            ),
            summary: "durable accepted contract published; debt not yet outstanding"
        ) else { throw AgentSessionError.contract(.causalLedgerRequired) }
        state.proposals[index].status = .accepted
        state.proposals[index].decisionEventID = acceptance.eventID
        state.proposals[index].terminalReason = String(reason.prefix(256))
        state.obligations.append(AgentDurableContractObligation(
            obligationID: obligationID, proposalID: proposalID,
            promisorID: proposal.opportunity.promisorID,
            promiseeID: promiseeID,
            promisedPerformance: proposal.opportunity.promisedPerformance,
            promisorReason: proposal.opportunity.promisorReason,
            promiseeReason: proposal.opportunity.promiseeReason,
            acceptedAtTick: tick,
            dueTick: tick + state.configuration.performanceDueTicks,
            acceptanceEventID: acceptance.eventID,
            obligationEventID: obligationEvent.eventID,
            status: .awaitingConsideration,
            considerationOutcome: nil, considerationEventID: nil,
            fulfillmentOutcome: nil, fulfillmentEventID: nil,
            terminalReason: nil
        ))
        state.obligations.sort { $0.obligationID < $1.obligationID }
        state.totalObligationCount += 1
        retainContractOperation(
            "promise-accept:\(proposalID.rawValue)", state: &state
        )
        state.lastContractEventID = obligationEvent.eventID
        contractState = state
        try validateContractStateIfEnabled()
    }

    public mutating func withdrawPromiseProposal(
        proposalID: AgentPromiseProposalID,
        promisorID: AgentID,
        reason: String = "withdrawn before acceptance"
    ) throws {
        guard var state = contractState,
              let index = state.proposals.firstIndex(where: {
                  $0.proposalID == proposalID
              }), state.proposals[index].status == .open,
              state.proposals[index].opportunity.promisorID == promisorID else {
            throw AgentSessionError.contract(.invalidDecision(proposalID.rawValue))
        }
        try closePromiseProposal(
            at: index, status: .withdrawn, actorID: promisorID,
            reason: reason, state: &state
        )
        contractState = state
        try validateContractStateIfEnabled()
    }

    public func expiredPromiseProposalIDs() -> [AgentPromiseProposalID] {
        guard let state = contractState else { return [] }
        return state.proposals.filter {
            $0.status == .open && $0.expiresAtTick < tick
        }.map(\.proposalID).sorted()
    }

    public mutating func expirePromiseProposal(
        proposalID: AgentPromiseProposalID
    ) throws {
        guard var state = contractState,
              let index = state.proposals.firstIndex(where: {
                  $0.proposalID == proposalID
              }), state.proposals[index].status == .open,
              state.proposals[index].expiresAtTick < tick else {
            throw AgentSessionError.contract(.invalidDecision(proposalID.rawValue))
        }
        try closePromiseProposal(
            at: index, status: .expired,
            actorID: state.proposals[index].opportunity.promisorID,
            reason: "bounded promise proposal expired", state: &state
        )
        contractState = state
        try validateContractStateIfEnabled()
    }

    public func prevalidateVerifiedContractConsideration(
        _ outcome: AgentVerifiedContractConsiderationOutcome
    ) throws {
        var candidate = self
        try candidate.recordVerifiedContractConsiderationInPlace(outcome)
    }

    private func validateVerifiedContractConsideration(
        _ outcome: AgentVerifiedContractConsiderationOutcome
    ) throws {
        guard let state = contractState,
              let obligation = state.obligations.first(where: {
                  $0.obligationID == outcome.obligationID
              }), obligation.status == .awaitingConsideration,
              let proposal = state.proposals.first(where: {
                  $0.proposalID == obligation.proposalID
              }) else {
            throw AgentSessionError.contract(
                .staleAuthority(outcome.obligationID.rawValue)
            )
        }
        let expected = proposal.opportunity.consideration
        try prevalidateExactAssetCommitmentContinuation(
            assetID: expected.assetID,
            logicalOperationID: "contract:\(proposal.proposalID.rawValue)"
        )
        guard !state.processedOperationIDs.contains(outcome.operationID),
              validContractText(outcome.operationID, maximum: 256),
              validContractText(outcome.transfer.physicalReceiptID, maximum: 256),
              outcome.completedAtTick == tick,
              outcome.transfer.assetID == expected.assetID,
              outcome.transfer.destinationObservation.holder
                == .agent(obligation.promisorID),
              outcome.transfer.destinationObservation.materialIdentity
                == expected.material.identity,
              outcome.transfer.destinationObservation.quantity
                == expected.material.count,
              outcome.transfer.destinationObservation.physicalReceiptID
                == outcome.transfer.physicalReceiptID,
              outcome.transfer.productionOperationIDs
                == expected.productionOperationIDs else {
            throw AgentSessionError.contract(.invalidOutcome(outcome.operationID))
        }
        try validateCurrentContractSourceAuthority(
            assetID: expected.assetID,
            actorID: obligation.promiseeID,
            historicalObservation: expected.holderObservation,
            currentObservation: outcome.transfer.sourceObservation
        )
        let needID = contractPerformanceNeedID(obligation.obligationID)
        guard productionState?.needs.contains(where: {
            $0.needID == needID
        }) == false else {
            throw AgentSessionError.contract(.duplicateOperation(needID.rawValue))
        }
        try prevalidateCausalAppend(count: 3)
    }

    public mutating func recordVerifiedContractConsideration(
        _ outcome: AgentVerifiedContractConsiderationOutcome
    ) throws {
        var candidate = self
        try candidate.recordVerifiedContractConsiderationInPlace(outcome)
        self = candidate
    }

    mutating func recordVerifiedContractConsiderationInPlace(
        _ outcome: AgentVerifiedContractConsiderationOutcome
    ) throws {
        try validateVerifiedContractConsideration(outcome)
        guard var state = contractState,
              let index = state.obligations.firstIndex(where: {
                  $0.obligationID == outcome.obligationID
              }) else {
            throw AgentSessionError.contract(.invalidOutcome(outcome.operationID))
        }
        let obligation = state.obligations[index]
        guard let event = try recordCausalEvent(
            kind: .contractConsiderationVerified,
            origin: .contractTransition,
            actorID: obligation.promiseeID,
            subjectID: obligation.promisorID,
            operationID: AgentOperationID(rawValue: outcome.operationID),
            causes: [obligation.obligationEventID],
            payload: .operation(
                status: "verified",
                detail: "obligation=\(obligation.obligationID.rawValue) receipt=\(outcome.transfer.physicalReceiptID)"
            ),
            summary: "real current consideration transferred and verified"
        ) else { throw AgentSessionError.contract(.causalLedgerRequired) }
        try transferContractRights(
            transfer: outcome.transfer, from: obligation.promiseeID,
            to: obligation.promisorID,
            operationPrefix: outcome.operationID,
            cause: event.eventID
        )
        state.obligations[index].status = .outstanding
        state.obligations[index].considerationOutcome = outcome
        state.obligations[index].considerationEventID = event.eventID
        state.lastContractEventID = event.eventID
        retainContractOperation(outcome.operationID, state: &state)
        contractState = state
        fulfillProductionNeedFromVerifiedReceipt(
            obligation.promisorReason.needID,
            received: AgentMaterialStackSnapshot(
                identity: outcome.transfer.destinationObservation.materialIdentity,
                count: outcome.transfer.destinationObservation.quantity
            ),
            operationID: outcome.operationID
        )
        try raiseProductionNeedInPlace(
            needID: contractPerformanceNeedID(obligation.obligationID),
            actorID: obligation.promisorID, reason: .materialWork,
            desiredOutputItemKey:
                obligation.promisedPerformance.material.identity.itemKey,
            quantity: obligation.promisedPerformance.material.count,
            priority: 98
        )
        try validateContractStateIfEnabled()
    }

    public func prevalidateVerifiedContractFulfillment(
        _ outcome: AgentVerifiedContractFulfillmentOutcome
    ) throws {
        var candidate = self
        try candidate.recordVerifiedContractFulfillmentInPlace(outcome)
    }

    private func validateVerifiedContractFulfillment(
        _ outcome: AgentVerifiedContractFulfillmentOutcome
    ) throws {
        guard let state = contractState,
              let obligation = state.obligations.first(where: {
                  $0.obligationID == outcome.obligationID
              }), obligation.status == .outstanding || obligation.status == .overdue,
              obligation.considerationOutcome != nil,
              obligation.fulfillmentOutcome == nil else {
            throw AgentSessionError.contract(
                .staleAuthority(outcome.obligationID.rawValue)
            )
        }
        let terms = obligation.promisedPerformance.material
        try prevalidateNewExactAssetCommitment(
            assetID: outcome.transfer.assetID,
            logicalOperationID:
                "contract-fulfillment:\(obligation.obligationID.rawValue)"
        )
        guard !state.processedOperationIDs.contains(outcome.operationID),
              validContractText(outcome.operationID, maximum: 256),
              validContractText(outcome.transfer.physicalReceiptID, maximum: 256),
              outcome.completedAtTick == tick,
              outcome.transfer.sourceObservation.holder
                == .agent(obligation.promisorID),
              outcome.transfer.sourceObservation.materialIdentity == terms.identity,
              outcome.transfer.sourceObservation.quantity == terms.count,
              outcome.transfer.destinationObservation.holder
                == .agent(obligation.promiseeID),
              outcome.transfer.destinationObservation.materialIdentity == terms.identity,
              outcome.transfer.destinationObservation.quantity == terms.count,
              outcome.transfer.destinationObservation.physicalReceiptID
                == outcome.transfer.physicalReceiptID,
              outcome.transfer.productionOperationIDs
                == Array(Set(outcome.transfer.productionOperationIDs)).sorted()
        else { throw AgentSessionError.contract(.invalidOutcome(outcome.operationID)) }
        try validateCurrentContractSourceAuthority(
            assetID: outcome.transfer.assetID,
            actorID: obligation.promisorID,
            historicalObservation: nil,
            currentObservation: outcome.transfer.sourceObservation
        )
        guard materialProductionProvenanceMatches(
            assetID: outcome.transfer.assetID,
            material: terms,
            operationIDs: outcome.transfer.productionOperationIDs
        ) else {
            throw AgentSessionError.contract(.invalidOutcome(outcome.operationID))
        }
        try prevalidateCausalAppend(count: 2)
    }

    public mutating func recordVerifiedContractFulfillment(
        _ outcome: AgentVerifiedContractFulfillmentOutcome
    ) throws {
        var candidate = self
        try candidate.recordVerifiedContractFulfillmentInPlace(outcome)
        self = candidate
    }

    mutating func recordVerifiedContractFulfillmentInPlace(
        _ outcome: AgentVerifiedContractFulfillmentOutcome
    ) throws {
        try validateVerifiedContractFulfillment(outcome)
        guard var state = contractState,
              let index = state.obligations.firstIndex(where: {
                  $0.obligationID == outcome.obligationID
              }) else {
            throw AgentSessionError.contract(.invalidOutcome(outcome.operationID))
        }
        let obligation = state.obligations[index]
        guard let event = try recordCausalEvent(
            kind: .contractFulfilled, origin: .contractTransition,
            actorID: obligation.promisorID, subjectID: obligation.promiseeID,
            operationID: AgentOperationID(rawValue: outcome.operationID),
            causes: ([obligation.considerationEventID ?? obligation.obligationEventID]
                + materialProductionCausalEventIDs(
                    assetID: outcome.transfer.assetID,
                    operationIDs: outcome.transfer.productionOperationIDs
                )).sorted(),
            payload: .operation(
                status: "fulfilled",
                detail: "obligation=\(obligation.obligationID.rawValue) receipt=\(outcome.transfer.physicalReceiptID)"
            ),
            summary: "real physical performance verified; obligation fulfilled exactly once"
        ) else { throw AgentSessionError.contract(.causalLedgerRequired) }
        try transferContractRights(
            transfer: outcome.transfer, from: obligation.promisorID,
            to: obligation.promiseeID,
            operationPrefix: outcome.operationID,
            cause: event.eventID
        )
        state.obligations[index].status = .fulfilled
        state.obligations[index].fulfillmentOutcome = outcome
        state.obligations[index].fulfillmentEventID = event.eventID
        state.obligations[index].terminalReason = "full verified physical performance"
        state.totalFulfilledCount += 1
        state.lastContractEventID = event.eventID
        retainContractOperation(outcome.operationID, state: &state)
        contractState = state
        fulfillProductionNeedFromVerifiedReceipt(
            obligation.promiseeReason.needID,
            received: AgentMaterialStackSnapshot(
                identity: outcome.transfer.destinationObservation.materialIdentity,
                count: outcome.transfer.destinationObservation.quantity
            ),
            operationID: outcome.operationID
        )
        try validateContractStateIfEnabled()
    }

    public mutating func reviewContractDueBoundaries() throws {
        var candidate = self
        try candidate.reviewContractDueBoundariesInPlace()
        self = candidate
    }

    mutating func reviewContractDueBoundariesInPlace() throws {
        guard var state = contractState else { return }
        let due = state.obligations.indices.filter {
            state.obligations[$0].status == .outstanding
                && tick > state.obligations[$0].dueTick
        }.sorted { state.obligations[$0].obligationID
            < state.obligations[$1].obligationID }
        try prevalidateCausalAppend(count: due.count)
        for index in due {
            let obligation = state.obligations[index]
            guard let event = try recordCausalEvent(
                kind: .contractOverdue, origin: .contractTransition,
                actorID: obligation.promisorID,
                subjectID: obligation.promiseeID,
                operationID: AgentOperationID(
                    rawValue: "contract-overdue:\(obligation.obligationID.rawValue)"
                ), causes: [obligation.considerationEventID
                    ?? obligation.obligationEventID],
                payload: .operation(
                    status: "overdue",
                    detail: "obligation=\(obligation.obligationID.rawValue) due=\(obligation.dueTick)"
                ),
                summary: "due boundary passed; debt retained without enforcement"
            ) else { throw AgentSessionError.contract(.causalLedgerRequired) }
            state.obligations[index].status = .overdue
            state.lastContractEventID = event.eventID
        }
        contractState = state
        try validateContractStateIfEnabled()
    }

    /// V1 has no inheritance of general contracts. Participant death blocks
    /// the obligation once and moves no property or debt to an heir.
    public mutating func reviewContractParticipantContinuity() throws {
        var candidate = self
        try candidate.reviewContractParticipantContinuityInPlace()
        self = candidate
    }

    mutating func reviewContractParticipantContinuityInPlace() throws {
        guard var state = contractState else { return }
        let blocked = state.obligations.indices.filter {
            state.obligations[$0].status.isActive
                && (statesById[state.obligations[$0].promisorID.rawValue] == nil
                    || statesById[state.obligations[$0].promiseeID.rawValue] == nil)
        }.sorted { state.obligations[$0].obligationID
            < state.obligations[$1].obligationID }
        try prevalidateCausalAppend(count: blocked.count)
        for index in blocked {
            let obligation = state.obligations[index]
            guard let event = try recordCausalEvent(
                kind: .contractParticipantDeathBlocked,
                origin: .contractTransition,
                actorID: obligation.promisorID,
                subjectID: obligation.promiseeID,
                operationID: AgentOperationID(
                    rawValue: "contract-death-block:\(obligation.obligationID.rawValue)"
                ), causes: [obligation.fulfillmentEventID
                    ?? obligation.considerationEventID
                    ?? obligation.obligationEventID],
                payload: .operation(
                    status: "blocked-participant-death",
                    detail: "obligation=\(obligation.obligationID.rawValue) inheritance=none"
                ),
                summary: "participant death blocks V1 contract without inheritance"
            ) else { throw AgentSessionError.contract(.causalLedgerRequired) }
            state.obligations[index].status = .blockedParticipantDeath
            state.obligations[index].terminalReason =
                "participant death; V1 defines no contract inheritance"
            state.lastContractEventID = event.eventID
        }
        contractState = state
        try validateContractStateIfEnabled()
    }

    func validateContractStateIfEnabled() throws {
        guard let state = contractState else { return }
        guard state.opportunities.count <= state.configuration.maximumOpportunities,
              state.proposals.count <= state.configuration.maximumProposals,
              state.obligations.count <= state.configuration.maximumObligations,
              state.processedOperationIDs.count
                <= state.configuration.maximumProcessedOperations,
              Set(state.opportunities.map(\.opportunityID)).count
                == state.opportunities.count,
              Set(state.proposals.map(\.proposalID)).count == state.proposals.count,
              Set(state.obligations.map(\.obligationID)).count
                == state.obligations.count,
              Set(state.processedOperationIDs).count
                == state.processedOperationIDs.count,
              state.totalObligationCount >= state.obligations.count,
              state.totalFulfilledCount <= state.totalObligationCount,
              state.totalFulfilledCount >= state.obligations.filter({
                  $0.status == .fulfilled
              }).count,
              state.evictionCount >= 0,
              state.initializedEventID.simulationID == simulationID,
              state.lastContractEventID.simulationID == simulationID else {
            throw AgentSessionError.contract(.invalidState("global bounds"))
        }
        let activeObligations = Dictionary(uniqueKeysWithValues:
            state.obligations.filter(\.status.isActive).map {
                ($0.proposalID, $0)
            }
        )
        var reservedConsideration: Set<AgentMaterialAssetID> = []
        for proposal in state.proposals where proposal.status == .open {
            guard reservedConsideration.insert(
                proposal.opportunity.consideration.assetID
            ).inserted else {
                throw AgentSessionError.contract(
                    .invalidState("duplicate consideration reservation")
                )
            }
        }
        for obligation in state.obligations {
            let participantsPresent =
                statesById[obligation.promisorID.rawValue] != nil
                && statesById[obligation.promiseeID.rawValue] != nil
            guard obligation.promisorID != obligation.promiseeID,
                  obligation.acceptedAtTick <= tick,
                  obligation.dueTick >= obligation.acceptedAtTick,
                  obligation.acceptanceEventID.simulationID == simulationID,
                  obligation.obligationEventID.simulationID == simulationID,
                  !obligation.promisedPerformance.material.identity.itemKey.isEmpty,
                  obligation.promisedPerformance.material.count > 0,
                  obligation.promisedPerformance.fullPerformanceRequired,
                  participantsPresent
                    || obligation.status == .blockedParticipantDeath else {
                throw AgentSessionError.contract(
                    .invalidState("obligation semantics")
                )
            }
            switch obligation.status {
            case .awaitingConsideration:
                guard let proposal = state.proposals.first(where: {
                          $0.proposalID == obligation.proposalID
                      }),
                      obligation.considerationOutcome == nil,
                      obligation.fulfillmentOutcome == nil,
                      reservedConsideration.insert(
                          proposal.opportunity.consideration.assetID
                      ).inserted else {
                    throw AgentSessionError.contract(
                        .invalidState("awaiting consideration")
                    )
                }
            case .outstanding, .overdue:
                guard obligation.considerationOutcome != nil,
                      obligation.considerationEventID != nil,
                      obligation.fulfillmentOutcome == nil,
                      obligation.fulfillmentEventID == nil else {
                    throw AgentSessionError.contract(
                        .invalidState("open debt evidence")
                    )
                }
            case .fulfilled:
                guard obligation.considerationOutcome != nil,
                      obligation.considerationEventID != nil,
                      obligation.fulfillmentOutcome != nil,
                      obligation.fulfillmentEventID != nil else {
                    throw AgentSessionError.contract(
                        .invalidState("fulfilled without proof")
                    )
                }
            case .blockedParticipantDeath:
                guard obligation.fulfillmentOutcome == nil,
                      obligation.fulfillmentEventID == nil else {
                    throw AgentSessionError.contract(
                        .invalidState("blocked with fulfillment")
                    )
                }
            }
            if obligation.status.isActive {
                guard activeObligations[obligation.proposalID] != nil,
                      state.proposals.contains(where: {
                          $0.proposalID == obligation.proposalID
                            && $0.status == .accepted
                      }) else {
                    throw AgentSessionError.contract(
                        .invalidState("active obligation lost accepted proposal")
                    )
                }
            }
        }
        try validateComposedExactAssetCommitments()
    }

    private func validateContractOpportunity(
        _ observation: AgentContractOpportunityObservation,
        state: AgentContractState
    ) throws {
        guard statesById[observation.promisorID.rawValue] != nil else {
            throw AgentSessionError.contract(.unknownAgent(observation.promisorID))
        }
        guard statesById[observation.promiseeID.rawValue] != nil else {
            throw AgentSessionError.contract(.unknownAgent(observation.promiseeID))
        }
        let consideration = observation.consideration
        let promised = observation.promisedPerformance.material
        guard observation.promisorID != observation.promiseeID,
              consideration.holderID == observation.promiseeID,
              consideration.holderObservation.holder
                == .agent(observation.promiseeID),
              consideration.holderObservation.materialIdentity
                == consideration.material.identity,
              consideration.holderObservation.quantity
                == consideration.material.count,
              consideration.material.count > 0,
              promised.count > 0,
              observation.promisedPerformance.fullPerformanceRequired,
              observation.distance >= 0,
              observation.distance <= state.configuration.maximumLocalDistance,
              observation.lineOfSight, observation.chunksReady,
              observation.observedAtTick == tick,
              observation.expiresAtTick
                == tick + state.configuration.proposalLifetimeTicks,
              validContractText(observation.opportunityID, maximum: 160)
        else {
            throw AgentSessionError.contract(
                .invalidOpportunity(observation.opportunityID)
            )
        }
        guard currentContractReason(
            observation.promisorReason, actorID: observation.promisorID,
            received: consideration.material
        ), currentContractReason(
            observation.promiseeReason, actorID: observation.promiseeID,
            received: promised
        ) else {
            throw AgentSessionError.contract(
                .invalidOpportunity(observation.opportunityID)
            )
        }
        try validateContractLegProvenance(consideration)
        let decision = evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: "contract-observe:\(observation.opportunityID)",
            assetID: consideration.assetID,
            actorID: observation.promiseeID,
            use: .transferCustody,
            verifiedHolder: consideration.holderObservation
        ))
        guard decision.verdict == .allowed else {
            throw AgentSessionError.contract(
                .unauthorized(decision.reason.rawValue)
            )
        }
    }

    private func currentContractReason(
        _ reason: AgentBarterValueReason,
        actorID: AgentID,
        received: AgentMaterialStackSnapshot
    ) -> Bool {
        productionState?.needs.contains {
            $0.needID == reason.needID && $0.status == .active
                && $0.actorID == actorID
                && reason == AgentBarterValueReason(need: $0)
                && $0.desiredOutputItemKey == received.identity.itemKey
                && $0.quantity == received.count
        } == true
    }

    private func contractReasonPriority(_ reason: AgentBarterValueReason) -> Int {
        productionState?.needs.first { $0.needID == reason.needID }?.priority ?? -1
    }

    /// A durable proposal consumes one negotiation scenario even after the
    /// resulting obligation closes. This prevents the same two unsatisfied
    /// reasons from immediately regenerating as a reverse-direction promise
    /// after the consideration and performance assets change hands.
    private func contractReasonExchangeAlreadyNegotiated(
        _ observation: AgentContractOpportunityObservation,
        in state: AgentContractState
    ) -> Bool {
        state.proposals.contains { proposal in
            let prior = proposal.opportunity
            let sameDirection = prior.promisorID == observation.promisorID
                && prior.promiseeID == observation.promiseeID
                && prior.promisorReason.needID
                    == observation.promisorReason.needID
                && prior.promiseeReason.needID
                    == observation.promiseeReason.needID
            let reversed = prior.promisorID == observation.promiseeID
                && prior.promiseeID == observation.promisorID
                && prior.promisorReason.needID
                    == observation.promiseeReason.needID
                && prior.promiseeReason.needID
                    == observation.promisorReason.needID
            return sameDirection || reversed
        }
    }

    private func validateContractLegProvenance(_ leg: AgentBarterLeg) throws {
        guard materialProductionProvenanceMatches(
            assetID: leg.assetID,
            material: leg.material,
            operationIDs: leg.productionOperationIDs
        ) else {
            throw AgentSessionError.contract(
                .invalidOpportunity(leg.assetID.rawValue)
            )
        }
    }

    private func contractConsiderationReserved(
        _ assetID: AgentMaterialAssetID,
        in state: AgentContractState
    ) -> Bool {
        if state.proposals.contains(where: {
            $0.status == .open
                && $0.opportunity.consideration.assetID == assetID
        }) { return true }
        return state.obligations.contains { obligation in
            guard obligation.status == .awaitingConsideration else { return false }
            return state.proposals.first(where: {
                $0.proposalID == obligation.proposalID
            })?.opportunity.consideration.assetID == assetID
        }
    }

    private func contractPerformanceNeedID(
        _ obligationID: AgentContractObligationID
    ) -> AgentProductionNeedID {
        AgentProductionNeedID(
            rawValue: "contract:\(obligationID.rawValue):perform"
        )!
    }

    private mutating func closePromiseProposal(
        at index: Int,
        status: AgentPromiseProposalStatus,
        actorID: AgentID,
        reason: String,
        state: inout AgentContractState
    ) throws {
        guard status == .rejected || status == .withdrawn || status == .expired
        else {
            throw AgentSessionError.contract(
                .invalidDecision(state.proposals[index].proposalID.rawValue)
            )
        }
        let proposal = state.proposals[index]
        try prevalidateCausalAppend(count: 1)
        guard let event = try recordCausalEvent(
            kind: .promiseClosed, origin: .contractTransition,
            actorID: actorID,
            subjectID: actorID == proposal.opportunity.promisorID
                ? proposal.opportunity.promiseeID
                : proposal.opportunity.promisorID,
            operationID: AgentOperationID(
                rawValue: "promise-close:\(proposal.proposalID.rawValue):\(status.rawValue)"
            ), causes: [proposal.proposalEventID],
            payload: .operation(
                status: status.rawValue,
                detail: "proposal=\(proposal.proposalID.rawValue) reason=\(String(reason.prefix(256)))"
            ),
            summary: "promise proposal \(status.rawValue); no obligation created"
        ) else { throw AgentSessionError.contract(.causalLedgerRequired) }
        state.proposals[index].status = status
        state.proposals[index].decisionEventID = event.eventID
        state.proposals[index].terminalReason = String(reason.prefix(256))
        state.lastContractEventID = event.eventID
    }

    private mutating func transferContractRights(
        transfer: AgentVerifiedContractTransfer,
        from: AgentID,
        to: AgentID,
        operationPrefix: String,
        cause: AgentCausalEventID
    ) throws {
        try validateCurrentContractSourceAuthority(
            assetID: transfer.assetID,
            actorID: from,
            historicalObservation: nil,
            currentObservation: transfer.sourceObservation
        )
        guard var rights = materialRightsState,
              let index = rights.records.firstIndex(where: {
                  $0.asset.assetID == transfer.assetID
              }), rights.records[index].lastVerifiedHolder.holder
                == transfer.sourceObservation.holder,
              rights.records[index].lastVerifiedHolder.materialIdentity
                == transfer.sourceObservation.materialIdentity,
              rights.records[index].lastVerifiedHolder.quantity
                == transfer.sourceObservation.quantity,
              rights.records[index].recognizedOwnership?.ownerID == from,
              rights.records[index].claims.count
                < rights.configuration.maximumClaimsPerAsset else {
            throw AgentSessionError.contract(
                .unauthorized(transfer.assetID.rawValue)
            )
        }
        let rightsOperationID = operationPrefix + ":rights"
        guard !rights.processedOperationIDs.contains(rightsOperationID),
              let claimID = AgentMaterialClaimID(
                  rawValue: "contract:\(AgentAutonomousActivityDigest.make(operationPrefix)):received"
              ) else {
            throw AgentSessionError.contract(.duplicateOperation(rightsOperationID))
        }
        let oldClaim = rights.records[index].recognizedOwnership?.claimID
        rights.records[index].claims.removeAll {
            $0.claimID == oldClaim && $0.claimantID == from
        }
        rights.records[index].claims.append(AgentMaterialClaim(
            claimID: claimID, claimantID: to, basis: .received,
            assertedAtTick: tick
        ))
        rights.records[index].claims.sort { $0.claimID < $1.claimID }
        rights.records[index].recognizedOwnership =
            AgentMaterialRecognizedOwnership(
                claimID: claimID, ownerID: to,
                recognizingAgentIDs: [from, to].sorted(),
                recognizedAtTick: tick
            )
        rights.records[index].custodianID = to
        rights.records[index].permissions.removeAll()
        rights.records[index].lastVerifiedHolder = transfer.destinationObservation
        guard let event = try recordCausalEvent(
            kind: .materialPhysicalCustodyObserved,
            origin: .materialRightsTransition,
            actorID: to,
            operationID: AgentOperationID(rawValue: rightsOperationID),
            causes: [cause],
            payload: .operation(
                status: "succeeded",
                detail: "asset=\(transfer.assetID.rawValue) holder=\(to.rawValue) owner=\(to.rawValue) receipt=\(transfer.physicalReceiptID)"
            ),
            summary: "verified contract transfer reconciled custody and ownership"
        ) else { throw AgentSessionError.contract(.causalLedgerRequired) }
        rights.processedOperationIDs.append(rightsOperationID)
        if rights.processedOperationIDs.count
            > rights.configuration.maximumProcessedOperationIDs {
            rights.processedOperationIDs.removeFirst()
            rights.droppedOperationIDCount += 1
        }
        rights.recentTransitions.append(AgentMaterialRightsTransition(
            operationID: rightsOperationID, kind: .physicalTransfer,
            assetID: transfer.assetID, status: "succeeded",
            reason: "verified voluntary contract performance",
            eventID: event.eventID
        ))
        if rights.recentTransitions.count
            > rights.configuration.maximumRetainedTransitions {
            rights.recentTransitions.removeFirst()
            rights.droppedTransitionCount += 1
        }
        materialRightsState = rights
        try validateMaterialRightsStateIfEnabled()
    }

    /// Material Rights remains the social constraint while Pebble supplies the
    /// immediate physical authority. A current observation may replace an old
    /// full-custody fingerprint only for the same exact asset at the same
    /// holder and quantity. It is published only as part of the verified
    /// transfer and never becomes physical authority by itself.
    private func validateCurrentContractSourceAuthority(
        assetID: AgentMaterialAssetID,
        actorID: AgentID,
        historicalObservation: AgentMaterialHolderObservation?,
        currentObservation: AgentMaterialHolderObservation
    ) throws {
        guard let record = materialRightsState?.records.first(where: {
                  $0.asset.assetID == assetID
              }), historicalObservation.map({ historical in
                  historical.holder == record.lastVerifiedHolder.holder
                    && historical.materialIdentity
                        == record.lastVerifiedHolder.materialIdentity
                    && historical.quantity
                        == record.lastVerifiedHolder.quantity
              }) ?? true,
              record.lastVerifiedHolder.holder == .agent(actorID),
              currentObservation.holder == record.lastVerifiedHolder.holder,
              currentObservation.materialIdentity
                == record.lastVerifiedHolder.materialIdentity,
              currentObservation.quantity == record.lastVerifiedHolder.quantity,
              currentObservation.observedAtTick == tick,
              validContractText(
                  currentObservation.custodyFingerprint, maximum: 8192
              ),
              validContractText(
                  currentObservation.physicalReceiptID, maximum: 256
              ) else {
            throw AgentSessionError.contract(.staleAuthority(assetID.rawValue))
        }
        let decision = evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: "contract-current-authority:\(assetID.rawValue)",
            assetID: assetID, actorID: actorID, use: .transferCustody,
            verifiedHolder: record.lastVerifiedHolder
        ))
        guard decision.verdict == .allowed else {
            throw AgentSessionError.contract(
                .unauthorized(decision.reason.rawValue)
            )
        }
    }

    private func compactContractProposalsForCapacity(
        state: inout AgentContractState
    ) {
        while state.proposals.count >= state.configuration.maximumProposals {
            let protected = Set(state.obligations.filter {
                $0.status.isActive
            }.map(\.proposalID))
            let removable = state.proposals.indices.filter {
                state.proposals[$0].status != .open
                    && !protected.contains(state.proposals[$0].proposalID)
            }.min { lhs, rhs in
                let left = state.proposals[lhs]
                let right = state.proposals[rhs]
                let leftSequence = (left.decisionEventID ?? left.proposalEventID)
                    .sequence.rawValue
                let rightSequence = (right.decisionEventID ?? right.proposalEventID)
                    .sequence.rawValue
                if leftSequence != rightSequence { return leftSequence < rightSequence }
                return left.proposalID < right.proposalID
            }
            guard let removable else { return }
            state.proposals.remove(at: removable)
            state.evictionCount += 1
        }
    }

    private func compactContractObligationsForCapacity(
        state: inout AgentContractState
    ) {
        while state.obligations.count >= state.configuration.maximumObligations {
            let removable = state.obligations.indices.filter {
                state.obligations[$0].status.isTerminal
            }.min { lhs, rhs in
                let left = state.obligations[lhs]
                let right = state.obligations[rhs]
                let leftSequence = (left.fulfillmentEventID
                    ?? left.considerationEventID
                    ?? left.obligationEventID).sequence.rawValue
                let rightSequence = (right.fulfillmentEventID
                    ?? right.considerationEventID
                    ?? right.obligationEventID).sequence.rawValue
                if leftSequence != rightSequence { return leftSequence < rightSequence }
                return left.obligationID < right.obligationID
            }
            guard let removable else { return }
            let proposalID = state.obligations[removable].proposalID
            state.obligations.remove(at: removable)
            if let proposalIndex = state.proposals.firstIndex(where: {
                $0.proposalID == proposalID && $0.status != .open
            }) {
                state.proposals.remove(at: proposalIndex)
            }
            state.evictionCount += 1
        }
    }

    private func retainContractOperation(
        _ operationID: String,
        state: inout AgentContractState
    ) {
        state.processedOperationIDs.append(operationID)
        if state.processedOperationIDs.count
            > state.configuration.maximumProcessedOperations {
            state.processedOperationIDs.removeFirst()
            state.evictionCount += 1
        }
    }

    private func validContractText(_ text: String, maximum: Int) -> Bool {
        !text.isEmpty && text.utf8.count <= maximum && !text.contains("\n")
    }
}
