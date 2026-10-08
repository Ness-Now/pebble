extension AgentSimulationSession {
    public var normalPhysicalReproductionEnabled: Bool {
        lifecycleState?.normalPhysicalReproductionEventID != nil
    }

    /// Prospective normal-founder composition. Historical sessions keep their
    /// legacy prerequisites; loading a checkpoint never invokes this operation.
    public mutating func initializeNormalPhysicalReproduction() throws {
        var candidate = self
        guard candidate.tick == 0,
              candidate.legacyTemporalSchemaVersionOverride == nil,
              candidate.legacyPathReadinessSchemaVersionOverride == nil,
              var lifecycle = candidate.lifecycleState,
              lifecycle.normalPhysicalReproductionEventID == nil,
              lifecycle.plans.isEmpty, lifecycle.totalBirthCount == 0,
              candidate.physicalFoodSurvivalEnabled,
              candidate.dependentCareEnabled, candidate.kinshipEnabled,
              candidate.geneticsEnabled, candidate.homeostasisEnabled else {
            throw AgentSessionError.lifecycle(.invalidConfiguration(
                "normal physical reproduction requires fresh founder authorities"
            ))
        }
        try candidate.setReproductionEnabled(true)
        lifecycle = candidate.lifecycleState!
        lifecycle.normalPhysicalReproductionEventID = lifecycle.lastLifecycleEventID
        candidate.lifecycleState = lifecycle
        self = candidate
    }

    /// Real nourishment must still support the parents' current needs. A
    /// bootstrap's initial zero hunger is insufficient, and each subsequent
    /// birth needs newer meals. Neither reserves nor unrelated residents vote.
    func normalReproductiveEvidence(
        for pair: [AgentLifecycleMember],
        pinned: AgentReproductiveSubsistenceEvidence? = nil
    ) -> AgentReproductiveSubsistenceEvidence? {
        guard physicalFoodSurvivalState != nil, pair.count == 2 else { return nil }
        var meals: [AgentValidatedPhysicalFoodConsumptionOutcome] = []
        for member in pair.sorted(by: { $0.agentID < $1.agentID }) {
            guard let state = statesById[member.agentID.rawValue],
                  state.health > 0, !isPhysiologicallyIncapacitated(member.agentID),
                  state.needs.hunger < configuration.survivalConfiguration.hungryThreshold,
                  let meal = (pinned?.meals ?? physicalFoodSurvivalState!.completedOutcomes)
                    .last(where: { $0.agentID == member.agentID }),
                  meal.tick <= tick,
                  member.lastCompletedBirthTick.map({ meal.tick > $0 }) ?? true else {
                return nil
            }
            meals.append(meal)
        }
        do {
            guard try prevalidateDependentCareBirth(parentIDs: pair.map(\.agentID).sorted()) != nil else {
                return nil
            }
        } catch { return nil }
        return AgentReproductiveSubsistenceEvidence(meals: meals)
    }

    static func validateNormalReproductionEvidence(
        lifecycle: AgentLifecycleState, physical: AgentPhysicalFoodSurvivalState?,
        clock: AgentSimulationClock, causal: AgentCausalLedgerDurableState
    ) throws {
        guard let activation = lifecycle.normalPhysicalReproductionEventID else { return }
        guard let physical, activation.simulationID == clock.simulationID,
              activation.sequence.rawValue <= causal.latestSequence else {
            throw AgentCheckpointError.invalidBound("normal reproduction activation")
        }
        for plan in lifecycle.plans {
            guard plan.pressureAtPlanning == nil, let evidence = plan.physicalSubsistenceEvidence,
                  evidence.meals.map(\.agentID) == plan.progenitorIDs,
                  evidence.meals.count == 2,
                  plan.createdEventID.simulationID == clock.simulationID else {
                throw AgentCheckpointError.invalidBound("normal reproduction plan evidence")
            }
            for meal in evidence.meals {
                let normalized = min(1, Double(meal.coreHungerPoints) / 20)
                guard meal.consumptionSequence < plan.createdEventID.sequence,
                      meal.tick <= plan.createdTick, meal.tick >= 0,
                      meal.quantityConsumed == 1, (1...20).contains(meal.coreHungerPoints),
                      meal.coreSaturation.isFinite, (0...20).contains(meal.coreSaturation),
                      meal.hungerBefore.isFinite, (0...1).contains(meal.hungerBefore),
                      meal.hungerAfter == max(0, meal.hungerBefore - normalized),
                      meal.normalizedHungerReduction == normalized,
                      meal.sourceKind == .agentCarriedInventory, (0..<64).contains(meal.sourceSlot),
                      meal.physicalReceiptID == meal.consumptionID,
                      meal.consumptionID == AgentPhysicalFoodConsumptionIntent.canonicalConsumptionID(
                        simulationID: clock.simulationID, agentID: meal.agentID,
                        sequence: meal.consumptionSequence),
                      !meal.canonicalMaterialName.isEmpty, meal.canonicalMaterialName.count <= 128,
                      meal.canonicalMaterialName.allSatisfy({
                          $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "_")
                      }),
                      physical.completedOutcomes.first(where: {
                          $0.consumptionID == meal.consumptionID
                      }).map({ $0 == meal }) ?? true else {
                    throw AgentCheckpointError.invalidBound("normal reproduction nourishment receipt")
                }
                let mealID = AgentCausalEventID(simulationID: clock.simulationID,
                                               sequence: meal.consumptionSequence)
                if let event = causal.events.first(where: { $0.eventID == mealID }) {
                    guard event.kind == .physicalFoodConsumed, event.actorID == meal.agentID,
                          event.operationID?.rawValue == meal.consumptionID else {
                        throw AgentCheckpointError.invalidBound("normal reproduction meal cause")
                    }
                }
                if let event = causal.events.first(where: { $0.eventID == plan.createdEventID }) {
                    guard event.kind == .reproductionPlanCreated, event.causes.contains(mealID) else {
                        throw AgentCheckpointError.invalidBound("normal reproduction plan cause")
                    }
                }
            }
        }
    }
}
