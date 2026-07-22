extension AgentSimulationSession {
    public var foodAuthorityMode: AgentFoodAuthorityMode {
        physicalFoodSurvivalState == nil ? .legacyAbstract : .physicalItems
    }

    public var physicalFoodSurvivalEnabled: Bool {
        physicalFoodSurvivalState != nil
    }

    public func physicalFoodSurvivalSnapshot() -> AgentPhysicalFoodSurvivalState? {
        physicalFoodSurvivalState
    }

    public mutating func setPhysicalFoodSurvivalEnabled(_ enabled: Bool) throws {
        if enabled {
            guard survivalEnabled else {
                throw AgentSessionError.physicalFoodSurvival(.survivalRequired)
            }
            guard physicalFoodSurvivalState == nil else { return }
            try prevalidateCausalAppend(count: 1)
            physicalFoodSurvivalState = AgentPhysicalFoodSurvivalState()
            _ = try recordCausalEvent(
                kind: .physicalFoodSurvivalInitialized,
                origin: .session,
                payload: .feature(name: "physicalFoodSurvival", enabled: true),
                summary: "physical food survival initialized without stock conversion"
            )
        } else {
            guard physicalFoodSurvivalState != nil else { return }
            physicalFoodSurvivalState = nil
            recordFeatureToggle(name: "physicalFoodSurvival", enabled: false)
        }
    }

    public func prevalidatePhysicalFoodConsumption(
        _ outcome: AgentValidatedPhysicalFoodConsumptionOutcome
    ) throws {
        guard let physical = physicalFoodSurvivalState else {
            throw AgentSessionError.physicalFoodSurvival(.disabled)
        }
        try requireStageCapability(.selfConsumeCarriedFood, for: outcome.agentID)
        guard survivalEnabled,
              let state = statesById[outcome.agentID.rawValue],
              state.survivalProgress != nil else {
            throw AgentSessionError.physicalFoodSurvival(.survivalRequired)
        }
        guard outcome.tick == tick,
              !outcome.consumptionID.isEmpty,
              outcome.consumptionID.count <= 256,
              outcome.physicalReceiptID == outcome.consumptionID,
              !outcome.sourceLocationID.isEmpty,
              outcome.sourceLocationID.count <= 256,
              (0..<64).contains(outcome.sourceSlot) else {
            throw AgentSessionError.physicalFoodSurvival(
                .invalidIntent(outcome.consumptionID)
            )
        }
        guard !physical.processedConsumptionIDs.contains(outcome.consumptionID) else {
            throw AgentSessionError.physicalFoodSurvival(
                .duplicateConsumption(outcome.consumptionID)
            )
        }
        guard physical.processedConsumptionIDs.count
                < AgentPhysicalFoodSurvivalState.maximumProcessedConsumptionIDs else {
            throw AgentSessionError.physicalFoodSurvival(.consumptionLimitReached)
        }
        guard state.needs.hunger > 0 else {
            throw AgentSessionError.physicalFoodSurvival(.noHungerNeed(outcome.agentID))
        }
        let validMaterial = !outcome.canonicalMaterialName.isEmpty
            && outcome.canonicalMaterialName.count <= 128
            && outcome.canonicalMaterialName.allSatisfy {
                $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "_")
            }
        let normalized = min(1, Double(outcome.coreHungerPoints) / 20.0)
        let hungerAfter = max(0, state.needs.hunger - normalized)
        guard validMaterial,
              outcome.quantityConsumed == 1,
              (1...20).contains(outcome.coreHungerPoints),
              outcome.coreSaturation.isFinite,
              outcome.coreSaturation >= 0,
              outcome.coreSaturation <= 20,
              outcome.normalizedHungerReduction == normalized,
              outcome.status == .succeeded,
              outcome.hungerBefore == state.needs.hunger,
              outcome.hungerAfter == hungerAfter else {
            throw AgentSessionError.physicalFoodSurvival(
                .invalidOutcome(outcome.consumptionID)
            )
        }
    }

    public mutating func applyValidatedPhysicalFoodConsumption(
        _ outcome: AgentValidatedPhysicalFoodConsumptionOutcome
    ) throws {
        var candidate = self
        try candidate.applyValidatedPhysicalFoodConsumptionInPlace(outcome)
        self = candidate
    }

    mutating func applyValidatedPhysicalFoodConsumptionInPlace(
        _ outcome: AgentValidatedPhysicalFoodConsumptionOutcome
    ) throws {
        try prevalidatePhysicalFoodConsumption(outcome)
        try prevalidateCausalAppend(count: 1)
        guard var physical = physicalFoodSurvivalState,
              var state = statesById[outcome.agentID.rawValue],
              var progress = state.survivalProgress else {
            throw AgentSessionError.physicalFoodSurvival(.invalidOutcome(outcome.consumptionID))
        }

        state.needs.hunger = outcome.hungerAfter
        progress.consecutiveCriticalHungerTicks = 0
        progress.foodConsumedCount = min(
            AgentSurvivalProgress.maximumEventCount,
            progress.foodConsumedCount + 1
        )
        progress.status = outcome.hungerAfter
            <= configuration.survivalConfiguration.hungerRecoveryThreshold ? .stable : .hungry
        progress.lastMemoryType = .foodConsumed
        state.survivalProgress = progress
        appendMemory(AgentMemoryEntry(
            tick: tick,
            type: AgentSurvivalMemoryType.foodConsumed.rawValue,
            summary: "\(outcome.agentID.rawValue) physically consumed 1 \(outcome.canonicalMaterialName)",
            importance: 0.50
        ), to: &state.memory)
        statesById[outcome.agentID.rawValue] = state

        physical.processedConsumptionIDs.append(outcome.consumptionID)
        physical.completedOutcomes.append(outcome)
        physical.totalConsumedQuantity += outcome.quantityConsumed
        if physical.completedOutcomes.count
            > AgentPhysicalFoodSurvivalState.maximumRetainedOutcomes {
            physical.completedOutcomes.removeFirst()
            physical.droppedOutcomeCount += 1
        }
        physicalFoodSurvivalState = physical
        recordAcceptedOperation(
            kind: .physicalFoodConsumed,
            agentId: outcome.agentID.rawValue,
            operationId: outcome.consumptionID,
            status: outcome.status.rawValue,
            detail: "material=\(outcome.canonicalMaterialName) quantity=1 coreHunger=\(outcome.coreHungerPoints) saturation=\(outcome.coreSaturation) hunger=\(outcome.hungerBefore)>\(outcome.hungerAfter) receipt=\(outcome.physicalReceiptID)"
        )
        try validatePhysicalFoodSurvivalStateIfEnabled()
    }

    func validatePhysicalFoodSurvivalStateIfEnabled() throws {
        guard let state = physicalFoodSurvivalState else { return }
        guard state.authorityMode == .physicalItems,
              state.processedConsumptionIDs.count
                <= AgentPhysicalFoodSurvivalState.maximumProcessedConsumptionIDs,
              state.processedConsumptionIDs.count
                == Set(state.processedConsumptionIDs).count,
              state.completedOutcomes.count
                <= AgentPhysicalFoodSurvivalState.maximumRetainedOutcomes,
              state.completedOutcomes.allSatisfy({
                  state.processedConsumptionIDs.contains($0.consumptionID)
              }),
              state.totalConsumedQuantity >= state.completedOutcomes.count,
              state.droppedOutcomeCount >= 0 else {
            throw AgentSessionError.physicalFoodSurvival(.invalidState("bounds or identity"))
        }
    }
}
