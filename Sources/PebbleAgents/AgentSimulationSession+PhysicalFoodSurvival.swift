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

    /// Pure need policy used by Pebble before presenting a physical edible
    /// opportunity. A committed hunger recovery remains a need until the
    /// configured recovery threshold is reached.
    public func needsPhysicalFoodAcquisition(for agentID: AgentID) -> Bool {
        guard physicalFoodSurvivalState != nil, survivalEnabled,
              let state = statesById[agentID.rawValue], state.health > 0 else {
            return false
        }
        return state.needs.hunger >= configuration.survivalConfiguration.hungryThreshold
            || (state.currentGoal.kind == .satisfyHunger
                && state.needs.hunger
                    > configuration.survivalConfiguration.hungerRecoveryThreshold)
            || (state.lastWorldObservation?.hungerDiscoveryProgress != nil
                && state.needs.hunger
                    > configuration.survivalConfiguration.hungerRecoveryThreshold)
    }

    /// All durable search memory stays in the existing prospective local
    /// observation boundary. A missing custody input cannot mean empty food.
    func hungerDiscoveryDecision(
        state: inout AgentSessionAgentState, hasFreshPerception: Bool,
        forcedCareGoal: AgentGoalKind?, occupiedPositions: [AgentPosition],
        tick decisionTick: Int
    ) -> (search: Bool, yields: Bool) {
        guard physicalFoodSurvivalEnabled, survivalEnabled, wildSubsistenceEnabled,
              autonomousActivityEnabled,
              var world = state.lastWorldObservation,
              let custody = world.physicalFoodCustody, custody.version == 1,
              hasFreshPerception, custody.worldTick == world.worldTick,
              world.position == state.position else { return (false, false) }
        let recovery = configuration.survivalConfiguration.hungerRecoveryThreshold
        if custody.hasEligibleFood || state.needs.hunger <= recovery {
            world.hungerDiscoveryProgress = nil
            state.lastWorldObservation = world
            return (false, false)
        }
        let need = state.needs.hunger >= configuration.survivalConfiguration.hungryThreshold
            || state.currentGoal.kind == .satisfyHunger
            || world.hungerDiscoveryProgress != nil
        guard need, state.health > 0,
              lifecycleState?.members.first(where: { $0.agentID == state.agentID })?
                .currentStage == .mature else { return (false, false) }
        // Reuse the normal eligible-source owner, including reservations and
        // edible fingerprints. No source positions are discovered here.
        let sourceFresh = ecologicalObservations(for: state.agentID).first?
            .observation.isFresh(atSimulationTick: decisionTick) == true
        let context = AgentSubsistenceDecisionContext(actorID: state.agentID,
            fishingRodAvailable: false, huntingWeaponAvailable: false,
            agricultureAvailable: false, maximumDistance: 16,
            subsistencePressure: max(0, min(100, Int(state.needs.hunger * 100))),
            requiredEdibleMaterialName: "sweet_berries")
        if sourceFresh, (try? eligibleSubsistenceStrategies(context).isEmpty) == false {
            return (false, false)
        }
        var progress = world.hungerDiscoveryProgress
            ?? AgentHungerDiscoveryProgress(startedAtTick: decisionTick)
        if let outcome = state.lastMovementOutcome,
           outcome.tick == progress.lastAttemptTick,
           outcome.tick != progress.lastEvaluatedOutcomeTick {
            progress.lastEvaluatedOutcomeTick = outcome.tick
            if outcome.status == .blocked {
                progress.failures = min(AgentHungerDiscoveryProgress.maximumFailures,
                    progress.failures + 1)
                progress.cooldownUntilTick = decisionTick + AgentHungerDiscoveryProgress.cooldownTicks
            }
        }
        defer {
            world.hungerDiscoveryProgress = progress
            state.lastWorldObservation = world
        }
        guard forcedCareGoal == nil, state.health > 25, state.fear < 70,
              state.needs.safety >= 0.5, !isMigratingAgent(state.id) else {
            return (false, true)
        }
        guard !progress.exhausted else { return (false, true) }
        if let until = progress.cooldownUntilTick {
            guard decisionTick >= until else { return (false, true) }
            progress.cooldownUntilTick = nil
            progress.attemptsInBurst = 0
        }
        // Unknown coverage suspends search; it neither proves physical absence
        // nor refreshes any refusal/budget.
        guard world.physicalMovementAssessmentVersion == 1,
              world.center.chunkReady else { return (false, true) }
        let legal = AgentFeedbackLoop.permittedExplorationDirections(
            position: state.position, home: state.homePosition,
            observation: world, occupiedPositions: occupiedPositions,
            configuration: configuration.feedbackLoopConfiguration)
        guard !legal.isEmpty else {
            let localOccupancy = occupiedPositions.filter {
                manhattanDistance($0, state.position) <= 2
            }.map { positionKey($0) }.sorted().joined(separator: ";")
            let refusal = AgentAutonomousActivityDigest.make(
                world.physicalReadinessContextDigest + "|" + localOccupancy)
            if !progress.refusedContexts.contains(refusal),
               progress.refusedContexts.count < AgentHungerDiscoveryProgress.maximumFailures {
                progress.refusedContexts.append(refusal)
                progress.failures = min(AgentHungerDiscoveryProgress.maximumFailures,
                    progress.failures + 1)
                progress.cooldownUntilTick = decisionTick + AgentHungerDiscoveryProgress.cooldownTicks
            }
            return (false, true)
        }
        return (true, false)
    }

    func recordHungerDiscoveryAttempt(
        state: inout AgentSessionAgentState, action: AgentAction, searching: Bool
    ) {
        guard searching, state.currentGoal.kind == .explore,
              action.name == "move_abstract",
              var world = state.lastWorldObservation,
              var progress = world.hungerDiscoveryProgress, !progress.exhausted else { return }
        progress.attempts += 1
        progress.attemptsInBurst += 1
        progress.lastAttemptTick = action.tick
        if progress.attemptsInBurst == AgentHungerDiscoveryProgress.burstAttempts {
            progress.cooldownUntilTick = action.tick + AgentHungerDiscoveryProgress.cooldownTicks
        }
        world.hungerDiscoveryProgress = progress
        state.lastWorldObservation = world
    }

    public mutating func setPhysicalFoodSurvivalEnabled(_ enabled: Bool) throws {
        if enabled {
            guard survivalEnabled else {
                throw AgentSessionError.physicalFoodSurvival(.survivalRequired)
            }
            guard causalLedger.isEnabled else {
                throw AgentSessionError.physicalFoodSurvival(.causalLedgerRequired)
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
            guard !normalPhysicalReproductionEnabled else {
                throw AgentSessionError.physicalFoodSurvival(.invalidState("normal reproduction owns physical prerequisite semantics"))
            }
            physicalFoodSurvivalState = nil
            recordFeatureToggle(name: "physicalFoodSurvival", enabled: false)
        }
    }

    /// Reserves no state. The returned identity is valid only while the causal
    /// high-water mark remains unchanged; publication enforces exact adjacency.
    public func nextPhysicalFoodConsumptionIntent(
        for agentID: AgentID
    ) throws -> AgentPhysicalFoodConsumptionIntent {
        guard physicalFoodSurvivalState != nil else {
            throw AgentSessionError.physicalFoodSurvival(.disabled)
        }
        guard causalLedger.isEnabled,
              causalLedger.latestSequence < UInt64.max,
              let sequence = AgentCausalSequence(rawValue: causalLedger.latestSequence + 1) else {
            throw AgentSessionError.physicalFoodSurvival(.causalLedgerRequired)
        }
        return AgentPhysicalFoodConsumptionIntent(
            consumptionID: AgentPhysicalFoodConsumptionIntent.canonicalConsumptionID(
                simulationID: simulationID,
                agentID: agentID,
                sequence: sequence
            ),
            consumptionSequence: sequence,
            agentID: agentID,
            tick: tick
        )
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
        let acceptedThrough = causalLedger.latestSequence
        guard outcome.consumptionSequence.rawValue > acceptedThrough else {
            throw AgentSessionError.physicalFoodSurvival(
                .duplicateConsumption(outcome.consumptionID)
            )
        }
        guard acceptedThrough < UInt64.max,
              outcome.consumptionSequence.rawValue == acceptedThrough + 1,
              outcome.consumptionID == AgentPhysicalFoodConsumptionIntent.canonicalConsumptionID(
                  simulationID: simulationID,
                  agentID: outcome.agentID,
                  sequence: outcome.consumptionSequence
              ),
              outcome.tick == tick,
              !outcome.consumptionID.isEmpty,
              outcome.consumptionID.count <= 256,
              outcome.physicalReceiptID == outcome.consumptionID,
              outcome.sourceKind == .agentCarriedInventory,
              (0..<64).contains(outcome.sourceSlot) else {
            throw AgentSessionError.physicalFoodSurvival(
                .invalidIntent(outcome.consumptionID)
            )
        }
        guard !physical.recentConsumptionIDs.contains(outcome.consumptionID) else {
            throw AgentSessionError.physicalFoodSurvival(
                .duplicateConsumption(outcome.consumptionID)
            )
        }
        try prevalidateCausalAppend(count: 1)
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

        physical.recentConsumptionIDs.append(outcome.consumptionID)
        physical.completedOutcomes.append(outcome)
        physical.totalConsumedQuantity += UInt64(outcome.quantityConsumed)
        if physical.recentConsumptionIDs.count
            > AgentPhysicalFoodSurvivalState.maximumRetainedConsumptionIDs {
            physical.recentConsumptionIDs.removeFirst()
            physical.droppedConsumptionIDCount += 1
        }
        if physical.completedOutcomes.count
            > AgentPhysicalFoodSurvivalState.maximumRetainedOutcomes {
            physical.completedOutcomes.removeFirst()
            physical.droppedOutcomeCount += 1
        }
        guard let eventID = recordAcceptedOperation(
            kind: .physicalFoodConsumed,
            agentId: outcome.agentID.rawValue,
            operationId: outcome.consumptionID,
            status: outcome.status.rawValue,
            detail: "sequence=\(outcome.consumptionSequence.rawValue) material=\(outcome.canonicalMaterialName) quantity=1 coreHunger=\(outcome.coreHungerPoints) saturation=\(outcome.coreSaturation) hunger=\(outcome.hungerBefore)>\(outcome.hungerAfter) receipt=\(outcome.physicalReceiptID)"
        ), eventID.sequence == outcome.consumptionSequence else {
            throw AgentSessionError.physicalFoodSurvival(.invalidState("causal sequence publication"))
        }
        physical.latestAcceptedConsumptionSequence = eventID.sequence
        physicalFoodSurvivalState = physical
        try validatePhysicalFoodSurvivalStateIfEnabled()
    }

    func validatePhysicalFoodSurvivalStateIfEnabled() throws {
        guard let state = physicalFoodSurvivalState else { return }
        guard state.authorityMode == .physicalItems,
              state.recentConsumptionIDs.count
                <= AgentPhysicalFoodSurvivalState.maximumRetainedConsumptionIDs,
              state.recentConsumptionIDs.count
                == Set(state.recentConsumptionIDs).count,
              state.completedOutcomes.count
                <= AgentPhysicalFoodSurvivalState.maximumRetainedOutcomes,
              state.completedOutcomes.map(\.consumptionID) == state.recentConsumptionIDs,
              state.completedOutcomes.allSatisfy({ outcome in
                  outcome.sourceKind == .agentCarriedInventory
                      && outcome.physicalReceiptID == outcome.consumptionID
                      && outcome.consumptionID
                          == AgentPhysicalFoodConsumptionIntent.canonicalConsumptionID(
                              simulationID: simulationID,
                              agentID: outcome.agentID,
                              sequence: outcome.consumptionSequence
                          )
              }),
              state.totalConsumedQuantity
                == state.droppedConsumptionIDCount + UInt64(state.recentConsumptionIDs.count),
              state.totalConsumedQuantity
                == state.droppedOutcomeCount + UInt64(state.completedOutcomes.count),
              (state.totalConsumedQuantity == 0)
                == (state.latestAcceptedConsumptionSequence == nil),
              state.latestAcceptedConsumptionSequence?.rawValue
                == state.completedOutcomes.last?.consumptionSequence.rawValue,
              (state.latestAcceptedConsumptionSequence?.rawValue ?? 0)
                <= causalLedger.latestSequence else {
            throw AgentSessionError.physicalFoodSurvival(.invalidState("bounds or identity"))
        }
    }
}
