extension AgentSimulationSession {
    public var productionEnabled: Bool { productionState != nil }

    public func productionSnapshot() -> AgentProductionSnapshot {
        guard let state = productionState else {
            return AgentProductionSnapshot(
                enabled: false, configuration: nil, needs: [], opportunities: [],
                records: [], useRecords: [], totalProductionCount: 0,
                totalUseCount: 0, evictionCount: 0
            )
        }
        return AgentProductionSnapshot(
            enabled: true,
            configuration: state.configuration,
            needs: state.needs.sorted(by: productionNeedSort),
            opportunities: state.opportunities.sorted(by: productionOpportunitySort),
            records: state.records.sorted(by: productionRecordSort),
            useRecords: state.useRecords.sorted {
                $0.causalEventID < $1.causalEventID
            },
            totalProductionCount: state.totalProductionCount,
            totalUseCount: state.totalUseCount,
            evictionCount: state.evictionCount
        )
    }

    public mutating func setProductionEnabled(
        _ enabled: Bool,
        configuration: AgentProductionConfiguration = .live
    ) throws {
        if enabled {
            guard productionState == nil else { return }
            guard causalLedger.isEnabled else {
                throw AgentSessionError.production(.causalLedgerRequired)
            }
            try prevalidateCausalAppend(count: 1)
            guard let event = try recordCausalEvent(
                kind: .productionInitialized,
                origin: .productionTransition,
                payload: .feature(name: "production", enabled: true),
                summary: "production initialized without physical stock conversion"
            ) else {
                throw AgentSessionError.production(.causalLedgerRequired)
            }
            productionState = AgentProductionState(
                configuration: configuration, needs: [], opportunities: [],
                records: [], useRecords: [], processedOperationIDs: [],
                totalProductionCount: 0, totalUseCount: 0, evictionCount: 0,
                initializedEventID: event.eventID,
                lastProductionEventID: event.eventID
            )
        } else if productionState != nil {
            throw AgentSessionError.production(.unsafeDisable)
        }
    }

    public mutating func raiseProductionNeed(
        needID: AgentProductionNeedID,
        actorID: AgentID,
        reason: AgentProductionNeedReason,
        desiredOutputItemKey: String,
        quantity: Int = 1,
        priority: Int = 70
    ) throws {
        var candidate = self
        try candidate.raiseProductionNeedInPlace(
            needID: needID, actorID: actorID, reason: reason,
            desiredOutputItemKey: desiredOutputItemKey,
            quantity: quantity, priority: priority
        )
        self = candidate
    }

    mutating func raiseProductionNeedInPlace(
        needID: AgentProductionNeedID,
        actorID: AgentID,
        reason: AgentProductionNeedReason,
        desiredOutputItemKey: String,
        quantity: Int,
        priority: Int
    ) throws {
        guard var state = productionState else {
            throw AgentSessionError.production(.disabled)
        }
        guard statesById[actorID.rawValue] != nil else {
            throw AgentSessionError.production(.unknownAgent(actorID))
        }
        guard !state.needs.contains(where: { $0.needID == needID }),
              !desiredOutputItemKey.isEmpty, desiredOutputItemKey.count <= 80,
              desiredOutputItemKey.allSatisfy({
                  $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "_")
              }), (1...64).contains(quantity), (0...100).contains(priority) else {
            throw AgentSessionError.production(.invalidNeed(needID.rawValue))
        }
        guard state.needs.count < state.configuration.maximumNeeds else {
            throw AgentSessionError.production(.capacityReached("needs"))
        }
        try prevalidateCausalAppend(count: 1)
        guard let event = try recordCausalEvent(
            kind: .productionNeedRaised, origin: .productionTransition,
            actorID: actorID,
            operationID: AgentOperationID(rawValue: "need:\(needID.rawValue)"),
            causes: [state.lastProductionEventID],
            payload: .operation(
                status: "active",
                detail: "need=\(needID.rawValue) reason=\(reason.rawValue) output=\(desiredOutputItemKey) quantity=\(quantity)"
            ),
            summary: "production need raised actor=\(actorID.rawValue)"
        ) else { throw AgentSessionError.production(.causalLedgerRequired) }
        state.needs.append(AgentProductionNeed(
            needID: needID, actorID: actorID, reason: reason,
            desiredOutputItemKey: desiredOutputItemKey, quantity: quantity,
            priority: priority, createdAtTick: tick,
            causalEventID: event.eventID
        ))
        state.lastProductionEventID = event.eventID
        productionState = state
        try validateProductionStateIfEnabled()
    }

    public mutating func recordProductionOpportunity(
        _ observation: AgentProductionOpportunityObservation
    ) throws {
        var candidate = self
        try candidate.recordProductionOpportunityInPlace(observation)
        self = candidate
    }

    mutating func recordProductionOpportunityInPlace(
        _ observation: AgentProductionOpportunityObservation
    ) throws {
        guard var state = productionState else {
            throw AgentSessionError.production(.disabled)
        }
        guard let need = state.needs.first(where: {
            $0.needID == observation.needID && $0.status == .active
        }), need.actorID == observation.actorID,
              need.desiredOutputItemKey == observation.output.identity.itemKey,
              observation.observedAtTick == tick,
              observation.expiresAtTick == tick + state.configuration.opportunityLifetimeTicks,
              !observation.recipeID.isEmpty,
              observation.workshopBlockKey == "crafting_table",
              !observation.sourceLocationID.isEmpty,
              !observation.sourceCustodyFingerprint.isEmpty,
              !observation.planFingerprint.isEmpty,
              !observation.inputs.isEmpty,
              observation.inputs.allSatisfy({ validProductionStack($0) }),
              validProductionStack(observation.output),
              observation.output.count == need.quantity else {
            throw AgentSessionError.production(
                .invalidOpportunity(observation.opportunityID.rawValue)
            )
        }
        if let existing = state.opportunities.first(where: {
            $0.opportunityID == observation.opportunityID
        }) {
            guard existing.observation == observation else {
                throw AgentSessionError.production(
                    .invalidOpportunity(observation.opportunityID.rawValue)
                )
            }
            return
        }
        state.opportunities.removeAll { $0.expiresAtTick < tick }
        state.opportunities.removeAll { $0.needID == observation.needID }
        guard state.opportunities.count < state.configuration.maximumOpportunities else {
            throw AgentSessionError.production(.capacityReached("opportunities"))
        }
        try prevalidateCausalAppend(count: 1)
        guard let event = try recordCausalEvent(
            kind: .productionOpportunityObserved,
            origin: .productionTransition, actorID: observation.actorID,
            operationID: AgentOperationID(rawValue: "observe:\(observation.opportunityID.rawValue)"),
            causes: [need.causalEventID],
            payload: .operation(
                status: "observed",
                detail: "opportunity=\(observation.opportunityID.rawValue) recipe=\(observation.recipeID) workshop=\(observation.workshopBlockKey)"
            ),
            summary: "production opportunity observed actor=\(observation.actorID.rawValue)"
        ) else { throw AgentSessionError.production(.causalLedgerRequired) }
        state.opportunities.append(AgentProductionOpportunity(
            observation: observation, causalEventID: event.eventID
        ))
        state.lastProductionEventID = event.eventID
        productionState = state
        try validateProductionStateIfEnabled()
    }

    public func prevalidateVerifiedProduction(
        _ outcome: AgentVerifiedProductionOutcome
    ) throws {
        guard let state = productionState else {
            throw AgentSessionError.production(.disabled)
        }
        guard !state.processedOperationIDs.contains(outcome.operationID) else {
            throw AgentSessionError.production(.duplicateOperation(outcome.operationID))
        }
        guard let opportunity = state.opportunities.first(where: {
            $0.opportunityID == outcome.opportunityID
        }) else {
            throw AgentSessionError.production(.staleOpportunity(
                outcome.opportunityID.rawValue
            ))
        }
        guard opportunity.expiresAtTick >= tick,
              opportunity.actorID == outcome.actorID,
              opportunity.recipeID == outcome.recipeID,
              opportunity.workshopPosition == outcome.workshopPosition,
              opportunity.workshopBlockKey == outcome.workshopBlockKey,
              opportunity.sourceLocationID == outcome.sourceLocationID,
              opportunity.sourceCustodyFingerprint
                == outcome.sourceCustodyFingerprintBefore,
              opportunity.planFingerprint == outcome.planFingerprint,
              opportunity.inputs == outcome.inputsConsumed,
              opportunity.output == outcome.outputProduced,
              outcome.completedAtTick == tick,
              validProductionOperationID(outcome.operationID),
              validProductionOperationID(outcome.physicalReceiptID),
              !outcome.sourceCustodyFingerprintAfter.isEmpty,
              outcome.sourceCustodyFingerprintAfter
                != outcome.sourceCustodyFingerprintBefore else {
            throw AgentSessionError.production(.invalidOutcome(outcome.operationID))
        }
        try prevalidateCausalAppend(count: skillsEnabled ? 2 : 1)
    }

    public mutating func recordVerifiedProduction(
        _ outcome: AgentVerifiedProductionOutcome
    ) throws {
        var candidate = self
        try candidate.recordVerifiedProductionInPlace(outcome)
        self = candidate
    }

    mutating func recordVerifiedProductionInPlace(
        _ outcome: AgentVerifiedProductionOutcome
    ) throws {
        try prevalidateVerifiedProduction(outcome)
        guard var state = productionState,
              let opportunityIndex = state.opportunities.firstIndex(where: {
                  $0.opportunityID == outcome.opportunityID
              }),
              let needIndex = state.needs.firstIndex(where: {
                  $0.needID == state.opportunities[opportunityIndex].needID
                      && $0.status == .active
              }) else {
            throw AgentSessionError.production(.invalidOutcome(outcome.operationID))
        }
        let opportunity = state.opportunities[opportunityIndex]
        let need = state.needs[needIndex]
        guard let event = try recordCausalEvent(
            kind: .productionCompleted, origin: .productionTransition,
            actorID: outcome.actorID,
            operationID: AgentOperationID(rawValue: outcome.operationID),
            causes: [opportunity.causalEventID],
            payload: .operation(
                status: "succeeded",
                detail: "pebble-production: recipe=\(outcome.recipeID) workshop=\(outcome.workshopBlockKey) output=\(outcome.outputProduced.identity.itemKey):\(outcome.outputProduced.count) receipt=\(outcome.physicalReceiptID)"
            ),
            summary: "production completed actor=\(outcome.actorID.rawValue)"
        ) else { throw AgentSessionError.production(.causalLedgerRequired) }
        state.needs[needIndex].status = .fulfilled
        state.needs[needIndex].fulfilledByOperationID = outcome.operationID
        state.opportunities.remove(at: opportunityIndex)
        state.opportunities.removeAll { $0.needID == need.needID }
        state.records.append(AgentProductionRecord(
            operationID: outcome.operationID, needID: need.needID,
            actorID: outcome.actorID, reason: need.reason,
            recipeID: outcome.recipeID,
            workshopPosition: outcome.workshopPosition,
            workshopBlockKey: outcome.workshopBlockKey,
            sourceLocationID: outcome.sourceLocationID,
            inputsConsumed: outcome.inputsConsumed,
            outputProduced: outcome.outputProduced,
            physicalReceiptID: outcome.physicalReceiptID,
            completedAtTick: outcome.completedAtTick,
            causalEventID: event.eventID
        ))
        state.processedOperationIDs.append(outcome.operationID)
        state.totalProductionCount += 1
        state.lastProductionEventID = event.eventID
        evictProductionState(&state)
        productionState = state
        if skillsEnabled {
            _ = try creditPracticeAfterMaterialSuccess(
                agentID: outcome.actorID, domain: .crafting,
                sourceSuccessEventID: event.eventID
            )
        }
        try validateProductionStateIfEnabled()
    }

    public mutating func recordProducedGoodUse(
        _ outcome: AgentProducedGoodUseOutcome
    ) throws {
        var candidate = self
        try candidate.recordProducedGoodUseInPlace(outcome)
        self = candidate
    }

    mutating func recordProducedGoodUseInPlace(
        _ outcome: AgentProducedGoodUseOutcome
    ) throws {
        guard var state = productionState else {
            throw AgentSessionError.production(.disabled)
        }
        guard !state.processedOperationIDs.contains(outcome.operationID),
              let record = state.records.first(where: {
                  $0.operationID == outcome.productionOperationID
              }), record.actorID == outcome.actorID,
              record.outputProduced.identity.itemKey
                == outcome.identityBefore.identity.itemKey,
              outcome.identityBefore.count == outcome.identityAfter.count,
              outcome.identityAfter.identity.itemKey
                == outcome.identityBefore.identity.itemKey,
              outcome.identityAfter.identity.damage
                == outcome.identityBefore.identity.damage + 1,
              outcome.completedAtTick == tick,
              validProductionOperationID(outcome.operationID),
              validProductionOperationID(outcome.physicalReceiptID),
              !outcome.physicalEffect.isEmpty else {
            throw AgentSessionError.production(.invalidOutcome(outcome.operationID))
        }
        let priorIdentity = state.useRecords.last(where: {
            $0.outcome.productionOperationID == outcome.productionOperationID
        })?.outcome.identityAfter ?? record.outputProduced
        guard priorIdentity == outcome.identityBefore else {
            throw AgentSessionError.production(.invalidOutcome(outcome.operationID))
        }
        try prevalidateCausalAppend(count: 1)
        guard let event = try recordCausalEvent(
            kind: .producedGoodUsed, origin: .productionTransition,
            actorID: outcome.actorID,
            operationID: AgentOperationID(rawValue: outcome.operationID),
            causes: [record.causalEventID],
            payload: .operation(
                status: "succeeded",
                detail: "pebble-produced-use: production=\(outcome.productionOperationID) item=\(outcome.identityAfter.identity.itemKey) damage=\(outcome.identityBefore.identity.damage)>\(outcome.identityAfter.identity.damage) effect=\(outcome.physicalEffect)"
            ),
            summary: "produced good used actor=\(outcome.actorID.rawValue)"
        ) else { throw AgentSessionError.production(.causalLedgerRequired) }
        state.useRecords.append(AgentProducedGoodUseRecord(
            outcome: outcome, causalEventID: event.eventID
        ))
        state.processedOperationIDs.append(outcome.operationID)
        state.totalUseCount += 1
        state.lastProductionEventID = event.eventID
        evictProductionState(&state)
        productionState = state
        try validateProductionStateIfEnabled()
    }

    func validateProductionStateIfEnabled() throws {
        guard let state = productionState else { return }
        let needIDs = state.needs.map(\.needID)
        let opportunityIDs = state.opportunities.map(\.opportunityID)
        let operationIDs = state.records.map(\.operationID)
        let useOperationIDs = state.useRecords.map { $0.outcome.operationID }
        guard state.needs.count <= state.configuration.maximumNeeds,
              state.opportunities.count <= state.configuration.maximumOpportunities,
              state.records.count <= state.configuration.maximumRecords,
              state.useRecords.count <= state.configuration.maximumUseRecords,
              state.processedOperationIDs.count
                <= state.configuration.maximumProcessedOperations,
              needIDs.count == Set(needIDs).count,
              opportunityIDs.count == Set(opportunityIDs).count,
              operationIDs.count == Set(operationIDs).count,
              useOperationIDs.count == Set(useOperationIDs).count,
              state.processedOperationIDs.count
                == Set(state.processedOperationIDs).count,
              state.totalProductionCount >= state.records.count,
              state.totalUseCount >= state.useRecords.count,
              state.evictionCount >= 0,
              state.initializedEventID.simulationID == simulationID,
              state.lastProductionEventID.simulationID == simulationID,
              state.initializedEventID <= state.lastProductionEventID,
              state.needs.allSatisfy({ need in
                  statesById[need.actorID.rawValue] != nil
                      && need.createdAtTick <= tick && need.quantity > 0
                      && !need.desiredOutputItemKey.isEmpty
                      && need.causalEventID.simulationID == simulationID
                      && (need.status == .fulfilled)
                        == (need.fulfilledByOperationID != nil)
              }),
              state.opportunities.allSatisfy({ opportunity in
                  state.needs.contains(where: {
                      $0.needID == opportunity.needID && $0.status == .active
                  }) && opportunity.observedAtTick <= tick
                      && opportunity.expiresAtTick >= opportunity.observedAtTick
                      && opportunity.causalEventID.simulationID == simulationID
              }),
              state.records.allSatisfy({ record in
                  record.completedAtTick <= tick
                      && record.causalEventID.simulationID == simulationID
                      && validProductionStack(record.outputProduced)
                      && record.inputsConsumed.allSatisfy(validProductionStack)
              }),
              state.useRecords.allSatisfy({ use in
                  use.outcome.completedAtTick <= tick
                      && use.causalEventID.simulationID == simulationID
              }) else {
            throw AgentSessionError.production(.invalidState("bounds or references"))
        }
    }

    private func validProductionStack(_ stack: AgentMaterialStackSnapshot) -> Bool {
        !stack.identity.itemKey.isEmpty && stack.identity.itemKey.count <= 80
            && stack.count > 0 && stack.count <= 64
            && stack.identity.damage >= 0
            && stack.identity.canonicalDataJSON.count <= 16_384
    }

    private func validProductionOperationID(_ value: String) -> Bool {
        AgentOperationID(rawValue: value) != nil
    }

    private func productionNeedSort(
        _ lhs: AgentProductionNeed, _ rhs: AgentProductionNeed
    ) -> Bool {
        if lhs.status != rhs.status { return lhs.status.rawValue < rhs.status.rawValue }
        if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
        return lhs.needID < rhs.needID
    }

    private func productionOpportunitySort(
        _ lhs: AgentProductionOpportunity, _ rhs: AgentProductionOpportunity
    ) -> Bool { lhs.opportunityID < rhs.opportunityID }

    private func productionRecordSort(
        _ lhs: AgentProductionRecord, _ rhs: AgentProductionRecord
    ) -> Bool {
        if lhs.causalEventID != rhs.causalEventID {
            return lhs.causalEventID < rhs.causalEventID
        }
        return lhs.operationID < rhs.operationID
    }

    private func evictProductionState(_ state: inout AgentProductionState) {
        state.records.sort(by: productionRecordSort)
        while state.records.count > state.configuration.maximumRecords {
            state.records.removeFirst()
            state.evictionCount += 1
        }
        state.useRecords.sort { $0.causalEventID < $1.causalEventID }
        while state.useRecords.count > state.configuration.maximumUseRecords {
            state.useRecords.removeFirst()
            state.evictionCount += 1
        }
        while state.processedOperationIDs.count
                > state.configuration.maximumProcessedOperations {
            state.processedOperationIDs.removeFirst()
            state.evictionCount += 1
        }
    }
}
