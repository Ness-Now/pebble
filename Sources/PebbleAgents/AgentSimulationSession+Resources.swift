extension AgentSimulationSession {
    public func conservationSnapshot() -> AgentResourceConservationSnapshot {
        let carried = AgentResourceKind.allCases.map { resource in
            AgentResourceAmount(
                resource: resource,
                quantity: statesById.values.reduce(0) {
                    $0 + $1.resourceInventory.count(of: resource)
                }
            )
        }
        return AgentResourceConservationSnapshot(
            harvested: harvestedResourceTotals.amounts,
            carried: carried,
            campStock: campStock.amounts,
            consumed: consumedResourceTotals.amounts,
            constructionEscrow: constructionProject?.materialEscrow.amounts ?? [],
            constructed: constructionProject?.placedMaterialTotals.amounts ?? [],
            unrecoveredAtDeath: mortalityState?.unrecoveredAtDeath.amounts ?? []
        )
    }

    public func prevalidateDelivery(_ intent: AgentDeliveryIntent) throws {
        if let id = AgentID(rawValue: intent.agentId) {
            try requireStageCapability(.deliver, for: id)
        }
        guard let state = statesById[intent.agentId] else {
            throw AgentSessionError.unknownAgentId(intent.agentId)
        }
        guard intent.tick == tick else {
            throw AgentSessionError.deliveryTickMismatch(intent.deliveryId)
        }
        guard !processedDeliveryIds.contains(intent.deliveryId) else {
            throw AgentSessionError.duplicateDelivery(intent.deliveryId)
        }
        guard intent.position == state.position, state.position == state.homePosition else {
            throw AgentSessionError.deliveryAwayFromHome(intent.agentId)
        }
        guard !state.resourceInventory.isEmpty else {
            throw AgentSessionError.emptyDelivery(intent.agentId)
        }
    }

    @discardableResult
    public mutating func deliverResources(_ intent: AgentDeliveryIntent) throws -> AgentDeliveryOutcome {
        try prevalidateDelivery(intent)
        guard let state = statesById[intent.agentId] else {
            throw AgentSessionError.unknownAgentId(intent.agentId)
        }
        let transferred = state.resourceInventory.amounts
        let outcome = AgentDeliveryOutcome(
            deliveryId: intent.deliveryId,
            agentId: intent.agentId,
            tick: tick,
            status: campStock.canAdd(transferred) ? .succeeded : .campStockFull,
            transferred: campStock.canAdd(transferred) ? transferred : [],
            reason: campStock.canAdd(transferred)
                ? "inventory delivered atomically to camp stock"
                : "camp stock capacity reached"
        )
        try applyDeliveryOutcome(outcome)
        return outcome
    }

    public mutating func applyDeliveryOutcome(_ outcome: AgentDeliveryOutcome) throws {
        var candidate = self
        try candidate.applyDeliveryOutcomeInPlace(outcome)
        self = candidate
    }

    mutating func applyDeliveryOutcomeInPlace(_ outcome: AgentDeliveryOutcome) throws {
        try prevalidateCausalAppend(
            count: (cooperationEnabled ? 4 : 1) + (skillsEnabled ? 1 : 0)
        )
        guard var state = statesById[outcome.agentId] else {
            throw AgentSessionError.unknownAgentId(outcome.agentId)
        }
        guard outcome.tick == tick else {
            throw AgentSessionError.deliveryTickMismatch(outcome.deliveryId)
        }
        guard !processedDeliveryIds.contains(outcome.deliveryId) else {
            throw AgentSessionError.duplicateDelivery(outcome.deliveryId)
        }

        let memory: AgentMemoryEntry
        switch outcome.status {
        case .succeeded:
            let expected = state.resourceInventory.amounts
            guard state.position == state.homePosition,
                  !expected.isEmpty,
                  outcome.transferred == expected,
                  campStock.canAdd(expected) else {
                throw AgentSessionError.invalidDeliveryOutcome(outcome.deliveryId)
            }
            guard state.resourceInventory.removeAll(expected), campStock.add(expected) else {
                throw AgentSessionError.invalidDeliveryOutcome(outcome.deliveryId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "resource_delivered",
                summary: "\(outcome.agentId) delivered \(expected.reduce(0) { $0 + $1.quantity }) resources",
                importance: 0.45
            )
            state.navigationProgress = AgentNavigationProgress(lastInvalidation: .delivered)
        case .blocked:
            guard outcome.transferred.isEmpty else {
                throw AgentSessionError.invalidDeliveryOutcome(outcome.deliveryId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "delivery_blocked",
                summary: "\(outcome.agentId) delivery blocked: \(outcome.reason)",
                importance: 0.25
            )
        case .campStockFull:
            guard outcome.transferred.isEmpty, !campStock.canAdd(state.resourceInventory.amounts) else {
                throw AgentSessionError.invalidDeliveryOutcome(outcome.deliveryId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "camp_stock_full",
                summary: "\(outcome.agentId) camp stock full",
                importance: 0.30
            )
        }
        appendMemory(memory, to: &state.memory)
        state.lastDeliveryOutcome = outcome
        statesById[outcome.agentId] = state
        processedDeliveryIds.insert(outcome.deliveryId)
        let deliveryEventID = recordAcceptedOperation(
            kind: .delivery,
            agentId: outcome.agentId,
            operationId: outcome.deliveryId,
            status: outcome.status.rawValue,
            detail: outcome.reason
        )
        if let deliveryEventID {
            let skillEventID = outcome.status == .succeeded
                ? try creditPracticeAfterMaterialSuccess(
                    agentID: state.agentID,
                    domain: .materialHandling,
                    sourceSuccessEventID: deliveryEventID
                ) : nil
            try applyCooperationDeliveryProgress(
                outcome: outcome,
                deliveryEventID: skillEventID ?? deliveryEventID
            )
        }
    }

    public func prevalidateInteraction(_ intent: AgentInteractionIntent) throws {
        if let id = AgentID(rawValue: intent.agentId) {
            try requireStageCapability(.harvest, for: id)
        }
        guard let state = statesById[intent.agentId] else {
            throw AgentSessionError.unknownAgentId(intent.agentId)
        }
        guard intent.tick == tick else {
            throw AgentSessionError.interactionTickMismatch(intent.interactionId)
        }
        guard intent.quantity == 1 else {
            throw AgentSessionError.invalidInteractionQuantity(intent.interactionId)
        }
        guard !processedInteractionIds.contains(intent.interactionId) else {
            throw AgentSessionError.duplicateInteraction(intent.interactionId)
        }
        guard state.resourceInventory.canAdd(intent.resource, quantity: intent.quantity) else {
            throw AgentSessionError.inventoryFull(intent.agentId)
        }
        switch intent.source {
        case .sandboxFixture:
            guard intent.expectedBlockFingerprint == nil else {
                throw AgentSessionError.invalidNaturalResourceIdentity(intent.interactionId)
            }
        case .naturalWorld:
            guard naturalResourcesEnabled,
                  let fingerprint = intent.expectedBlockFingerprint,
                  intent.resource == .wood || intent.resource == .stone,
                  state.activeResourceTarget?.identity == AgentResourceIdentity(
                      source: .naturalWorld,
                      position: intent.target,
                      resource: intent.resource,
                      expectedBlockFingerprint: fingerprint
                  ),
                  reservation(for: state)?.agentId == intent.agentId else {
                throw AgentSessionError.invalidNaturalResourceIdentity(intent.interactionId)
            }
        case .localEcology:
            throw AgentSessionError.invalidNaturalResourceIdentity(intent.interactionId)
        }
    }

    public mutating func applyInteractionOutcome(_ outcome: AgentInteractionOutcome) throws {
        if let id = AgentID(rawValue: outcome.agentId) {
            try requireStageCapability(.harvest, for: id)
        }
        try prevalidateCausalAppend(count: 1)
        guard var state = statesById[outcome.agentId] else {
            throw AgentSessionError.unknownAgentId(outcome.agentId)
        }
        guard outcome.tick == tick else {
            throw AgentSessionError.interactionTickMismatch(outcome.interactionId)
        }
        guard !processedInteractionIds.contains(outcome.interactionId) else {
            throw AgentSessionError.duplicateInteraction(outcome.interactionId)
        }

        let memory: AgentMemoryEntry
        switch outcome.status {
        case .succeeded:
            switch outcome.source {
            case .sandboxFixture:
                guard outcome.expectedBlockFingerprint == nil else {
                    throw AgentSessionError.invalidInteractionOutcome(outcome.interactionId)
                }
            case .naturalWorld:
                guard naturalResourcesEnabled,
                      outcome.expectedBlockFingerprint != nil,
                      outcome.resource == .wood || outcome.resource == .stone else {
                    throw AgentSessionError.invalidInteractionOutcome(outcome.interactionId)
                }
            case .localEcology:
                throw AgentSessionError.invalidInteractionOutcome(outcome.interactionId)
            }
            let creditKey = reservationKey(
                target: outcome.target,
                resource: outcome.resource,
                source: outcome.source,
                expectedBlockFingerprint: outcome.expectedBlockFingerprint
            )
            guard !creditedResourceKeys.contains(creditKey) else {
                throw AgentSessionError.duplicateResourceCredit(creditKey)
            }
            var nextInventory = state.resourceInventory
            var nextHarvestedTotals = harvestedResourceTotals
            guard outcome.inventoryDelta.resource == outcome.resource,
                  outcome.inventoryDelta.quantity == 1,
                  nextInventory.add(outcome.resource, quantity: 1),
                  nextHarvestedTotals.add(outcome.resource, quantity: 1) else {
                throw AgentSessionError.invalidInteractionOutcome(outcome.interactionId)
            }
            state.resourceInventory = nextInventory
            harvestedResourceTotals = nextHarvestedTotals
            memory = AgentMemoryEntry(
                tick: tick,
                type: "resource_harvested",
                summary: "\(outcome.agentId) harvested 1 \(outcome.resource.rawValue)",
                importance: 0.40
            )
            reservationsByTarget.removeValue(forKey: reservationKey(
                target: outcome.target,
                resource: outcome.resource,
                source: outcome.source,
                expectedBlockFingerprint: outcome.expectedBlockFingerprint
            ))
            state.activeResourceTarget = nil
            state.navigationProgress = AgentNavigationProgress(
                lastInvalidation: .harvested
            )
            creditedResourceKeys.insert(creditKey)
        case .blocked:
            guard outcome.inventoryDelta.quantity == 0 else {
                throw AgentSessionError.invalidInteractionOutcome(outcome.interactionId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "interaction_blocked",
                summary: "\(outcome.agentId) interaction blocked: \(outcome.reason)",
                importance: 0.25
            )
        case .inventoryFull:
            guard outcome.inventoryDelta.quantity == 0,
                  !state.resourceInventory.canAdd(outcome.resource) else {
                throw AgentSessionError.invalidInteractionOutcome(outcome.interactionId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "inventory_full",
                summary: "\(outcome.agentId) inventory full for \(outcome.resource.rawValue)",
                importance: 0.30
            )
        }

        appendMemory(memory, to: &state.memory)
        state.lastInteractionOutcome = outcome
        statesById[outcome.agentId] = state
        processedInteractionIds.insert(outcome.interactionId)
        recordAcceptedOperation(
            kind: .interaction,
            agentId: outcome.agentId,
            operationId: outcome.interactionId,
            status: outcome.status.rawValue,
            detail: outcome.reason
        )
    }

    func shouldDeliverResources(_ state: AgentSessionAgentState) -> Bool {
        guard economyEnabled, !state.resourceInventory.isEmpty else { return false }
        if cooperationDeliveryIsCommitted(state) { return true }
        if state.currentGoal.kind == .deliverResources
            || state.resourceInventory.totalCount >= configuration.deliveryQuota
            || state.resourceInventory.isFull {
            return true
        }
        guard buildAutoEnabled,
              let project = constructionProject,
              project.builderAgentId == state.id,
              project.status == .acquiringMaterials || project.status == .readyToFund else {
            return false
        }
        return project.missingMaterials(
            campStock: campStock,
            builderInventory: state.resourceInventory
        ).isEmpty
    }

}
