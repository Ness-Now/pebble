extension AgentSimulationSession {
    public func prevalidateConsumption(_ intent: AgentConsumptionIntent) throws {
        guard let state = statesById[intent.agentId] else {
            throw AgentSessionError.unknownAgentId(intent.agentId)
        }
        guard survivalEnabled else {
            throw AgentSessionError.survivalDisabled(intent.agentId)
        }
        guard intent.tick == tick else {
            throw AgentSessionError.consumptionTickMismatch(intent.consumptionId)
        }
        guard !processedConsumptionIds.contains(intent.consumptionId) else {
            throw AgentSessionError.duplicateConsumption(intent.consumptionId)
        }
        guard processedConsumptionIds.count < Self.maximumConsumptionCount else {
            throw AgentSessionError.consumptionLimitReached
        }
        guard intent.resource == .foodRaw else {
            throw AgentSessionError.invalidConsumptionResource(intent.consumptionId)
        }
        guard intent.quantity == 1 else {
            throw AgentSessionError.invalidConsumptionQuantity(intent.consumptionId)
        }
        guard state.survivalProgress != nil else {
            throw AgentSessionError.survivalDisabled(intent.agentId)
        }
    }

    @discardableResult
    public mutating func consumeFood(_ intent: AgentConsumptionIntent) throws -> AgentConsumptionOutcome {
        try prevalidateConsumption(intent)
        guard let state = statesById[intent.agentId] else {
            throw AgentSessionError.unknownAgentId(intent.agentId)
        }
        let hasFood = state.resourceInventory.count(of: .foodRaw) >= intent.quantity
        let hungerAfter = hasFood
            ? max(0, state.needs.hunger - configuration.survivalConfiguration.foodNutrition)
            : state.needs.hunger
        let outcome = AgentConsumptionOutcome(
            consumptionId: intent.consumptionId,
            agentId: intent.agentId,
            tick: tick,
            resource: intent.resource,
            quantity: intent.quantity,
            status: hasFood ? .succeeded : .foodUnavailable,
            hungerBefore: state.needs.hunger,
            hungerAfter: hungerAfter,
            reason: hasFood
                ? "one carried foodRaw consumed atomically"
                : "no carried foodRaw available"
        )
        try applyConsumptionOutcome(outcome)
        return outcome
    }

    public mutating func applyConsumptionOutcome(_ outcome: AgentConsumptionOutcome) throws {
        var candidate = self
        try candidate.applyConsumptionOutcomeInPlace(outcome)
        self = candidate
    }

    mutating func applyConsumptionOutcomeInPlace(
        _ outcome: AgentConsumptionOutcome
    ) throws {
        guard var state = statesById[outcome.agentId],
              var progress = state.survivalProgress else {
            throw AgentSessionError.unknownAgentId(outcome.agentId)
        }
        guard survivalEnabled else {
            throw AgentSessionError.survivalDisabled(outcome.agentId)
        }
        guard outcome.tick == tick else {
            throw AgentSessionError.consumptionTickMismatch(outcome.consumptionId)
        }
        guard !processedConsumptionIds.contains(outcome.consumptionId) else {
            throw AgentSessionError.duplicateConsumption(outcome.consumptionId)
        }
        guard processedConsumptionIds.count < Self.maximumConsumptionCount else {
            throw AgentSessionError.consumptionLimitReached
        }
        guard outcome.resource == .foodRaw else {
            throw AgentSessionError.invalidConsumptionResource(outcome.consumptionId)
        }
        guard outcome.quantity == 1 else {
            throw AgentSessionError.invalidConsumptionQuantity(outcome.consumptionId)
        }

        let memory: AgentMemoryEntry
        switch outcome.status {
        case .succeeded:
            let expectedHunger = max(
                0,
                state.needs.hunger - configuration.survivalConfiguration.foodNutrition
            )
            var inventory = state.resourceInventory
            var consumed = consumedResourceTotals
            guard outcome.hungerBefore == state.needs.hunger,
                  outcome.hungerAfter == expectedHunger,
                  inventory.remove(.foodRaw, quantity: 1),
                  consumed.add(.foodRaw, quantity: 1) else {
                throw AgentSessionError.invalidConsumptionOutcome(outcome.consumptionId)
            }
            state.resourceInventory = inventory
            state.needs.hunger = expectedHunger
            consumedResourceTotals = consumed
            progress.consecutiveCriticalHungerTicks = 0
            progress.foodConsumedCount = min(
                AgentSurvivalProgress.maximumEventCount,
                progress.foodConsumedCount + 1
            )
            progress.status = expectedHunger <= configuration.survivalConfiguration.hungerRecoveryThreshold
                ? .stable
                : .hungry
            memory = AgentMemoryEntry(
                tick: tick,
                type: "food_consumed",
                summary: "\(outcome.agentId) consumed 1 foodRaw",
                importance: 0.50
            )
        case .blocked, .foodUnavailable:
            guard outcome.hungerBefore == state.needs.hunger,
                  outcome.hungerAfter == state.needs.hunger else {
                throw AgentSessionError.invalidConsumptionOutcome(outcome.consumptionId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "consumption_blocked",
                summary: "\(outcome.agentId) consumption blocked: \(outcome.reason)",
                importance: 0.30
            )
        }
        progress.lastConsumptionOutcome = outcome
        progress.lastMemoryType = AgentSurvivalMemoryType(rawValue: memory.type)
        state.survivalProgress = progress
        appendMemory(memory, to: &state.memory)
        statesById[outcome.agentId] = state
        processedConsumptionIds.insert(outcome.consumptionId)
        guard conservationSnapshot().balanced else {
            throw AgentSessionError.invalidConsumptionOutcome(outcome.consumptionId)
        }
    }

    func shouldSatisfyHunger(
        _ state: AgentSessionAgentState,
        projectedToNextTick: Bool = false
    ) -> Bool {
        guard survivalEnabled else { return false }
        let added = projectedToNextTick ? configuration.survivalConfiguration.hungerPerTick : 0
        let hunger = min(1, max(0, state.needs.hunger + added))
        if state.currentGoal.kind == .satisfyHunger {
            return hunger > configuration.survivalConfiguration.hungerRecoveryThreshold
        }
        return hunger >= configuration.survivalConfiguration.hungryThreshold
    }

    func shouldRest(
        _ state: AgentSessionAgentState,
        projectedToNextTick: Bool = false
    ) -> Bool {
        guard survivalEnabled else { return false }
        let added = projectedToNextTick ? configuration.survivalConfiguration.fatiguePerTick : 0
        let fatigue = min(1, max(0, state.needs.fatigue + added))
        if state.currentGoal.kind == .rest {
            return fatigue > configuration.survivalConfiguration.fatigueRecoveryThreshold
        }
        return fatigue >= configuration.survivalConfiguration.fatigueThreshold
    }

    func applySurvivalTick(
        to state: inout AgentSessionAgentState,
        tick survivalTick: Int
    ) -> AgentMemoryEntry? {
        let survival = configuration.survivalConfiguration
        state.needs.hunger = min(1, max(0, state.needs.hunger + survival.hungerPerTick))
        state.needs.fatigue = min(1, max(0, state.needs.fatigue + survival.fatiguePerTick))
        state.needs.curiosity = min(1, max(0, state.needs.curiosity))
        state.needs.safety = min(1, max(0, state.needs.safety))
        state.health = min(100, max(0, state.health))
        state.state = "idle"
        var progress = state.survivalProgress ?? AgentSurvivalProgress()
        var memory: AgentMemoryEntry?
        if state.needs.hunger >= survival.criticalHungerThreshold {
            progress.consecutiveCriticalHungerTicks = min(
                survival.starvationGraceTicks + 1,
                progress.consecutiveCriticalHungerTicks + 1
            )
            if progress.consecutiveCriticalHungerTicks > survival.starvationGraceTicks,
               state.health > 0 {
                let damage = min(state.health, survival.starvationDamagePerTick)
                state.health -= damage
                progress.starvationDamageTaken = min(
                    100,
                    progress.starvationDamageTaken + damage
                )
                memory = AgentMemoryEntry(
                    tick: survivalTick,
                    type: "starvation_damage",
                    summary: "\(state.id) took \(damage) starvation damage",
                    importance: 0.70
                )
                progress.lastMemoryType = .starvationDamage
            }
        } else {
            progress.consecutiveCriticalHungerTicks = 0
        }
        progress.status = state.needs.hunger >= survival.criticalHungerThreshold
            ? .starving
            : state.needs.hunger >= survival.hungryThreshold
                ? .hungry
                : state.needs.fatigue >= survival.fatigueThreshold
                    ? .exhausted
                    : .stable
        state.survivalProgress = progress
        return memory
    }

    func updateSurvivalProgress(
        for state: inout AgentSessionAgentState,
        action: AgentAction
    ) {
        guard var progress = state.survivalProgress else { return }
        let survival = configuration.survivalConfiguration
        if action.name == "rest", state.position == state.homePosition {
            progress.restTicks = min(
                AgentSurvivalProgress.maximumEventCount,
                progress.restTicks + 1
            )
            progress.status = state.needs.fatigue <= survival.fatigueRecoveryThreshold
                ? .stable
                : .recovering
        } else if state.currentGoal.kind == .rest {
            progress.status = .exhausted
        } else if state.needs.hunger >= survival.criticalHungerThreshold {
            progress.status = .starving
        } else if state.currentGoal.kind == .satisfyHunger {
            progress.status = .hungry
        } else if state.needs.fatigue >= survival.fatigueThreshold {
            progress.status = .exhausted
        } else {
            progress.status = .stable
        }
        state.survivalProgress = progress
    }

}
