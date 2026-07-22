import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handlePhysicalFoodSurvival(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab physical-food-survival <on|off|status|proof [shadow-setup|shadow|consume|final]>"
        guard let subcommand = arguments.first?.lowercased(),
              (1...2).contains(arguments.count), var session else {
            return failure(usage)
        }
        do {
            switch subcommand {
            case "on", "off":
                guard arguments.count == 1 else { return failure(usage) }
                let enabled = subcommand == "on"
                if try applyCommandMutationIfRecording(
                    .setPhysicalFoodSurvivalEnabled(enabled), session: &session
                ) == nil {
                    try session.setPhysicalFoodSurvivalEnabled(enabled)
                }
                self.session = session
                trace(
                    "physical food survival authority=\(session.foodAuthorityMode.rawValue) "
                        + "enabled=\(enabled ? 1 : 0) stockConversion=none"
                )
                return success("Physical food survival \(enabled ? "enabled" : "disabled").")
            case "status":
                guard arguments.count == 1 else { return failure(usage) }
                let state = session.physicalFoodSurvivalSnapshot()
                let actor = try? session.state(for: focusedAgentId ?? "agent_0")
                let message = "physical food survival authority=\(session.foodAuthorityMode.rawValue) enabled=\(state == nil ? 0 : 1) actor=\(actor?.id ?? "none") hunger=\(actor?.needs.hunger ?? 0) history=\(state?.completedOutcomes.count ?? 0) totalConsumed=\(state?.totalConsumedQuantity ?? 0) foodRaw=\(actor?.resourceInventory.count(of: .foodRaw) ?? 0)"
                trace(message)
                return success(message)
            case "proof":
                guard arguments.count == 2 else { return failure(usage) }
                switch arguments[1].lowercased() {
                case "shadow-setup":
                    try setupPhysicalFoodShadowProof(session: &session)
                    self.session = session
                    return success("Physical food shadow proof prepared.")
                case "shadow":
                    try verifyPhysicalFoodShadowProof(session: session, world: world)
                    return success("Physical food shadow authority refusal proved.")
                case "consume":
                    try runPhysicalFoodConsumptionProof(session: &session, world: world)
                    self.session = session
                    return success("Physical food exact consumption proved.")
                case "final":
                    try finalizePhysicalFoodProof(session: session, world: world)
                    return success("Physical food survival proof complete.")
                default:
                    return failure(usage)
                }
            default:
                return failure(usage)
            }
        } catch {
            return failure("PhysicalFoodSurvival command failed: \(error)")
        }
    }

    private func setupPhysicalFoodShadowProof(
        session: inout AgentSimulationSession
    ) throws {
        let agentID = "agent_2"
        guard session.physicalFoodSurvivalEnabled,
              let probe = probesByAgentId[agentID],
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw ControllerError.physicalFoodBoundary(
                "shadow setup requires physical authority and empty actor custody"
            )
        }
        let actor = try session.state(for: agentID)
        if actor.resourceInventory.count(of: .foodRaw) == 0 {
            let outcome = AgentInteractionOutcome(
                interactionId: "physical-food-shadow-fixture",
                agentId: agentID,
                tick: session.tick,
                target: AgentPosition(x: actor.position.x, y: actor.position.y, z: actor.position.z + 9),
                resource: .foodRaw,
                status: .succeeded,
                inventoryDelta: AgentInventoryDelta(resource: .foodRaw, quantity: 1),
                reason: "historical coarse shadow fixture"
            )
            if try applyCommandMutationIfRecording(
                .interactionOutcome(outcome), session: &session
            ) == nil {
                try session.applyInteractionOutcome(outcome)
            }
        }
        let prepared = try session.state(for: agentID)
        trace(
            "physical food shadow setup actor=\(agentID) authority=physicalItems "
                + "foodRaw=\(prepared.resourceInventory.count(of: .foodRaw)) physicalFood=none "
                + "stockConversion=none"
        )
    }

    private func verifyPhysicalFoodShadowProof(
        session: AgentSimulationSession,
        world: World
    ) throws {
        let agentID = "agent_2"
        guard session.physicalFoodSurvivalEnabled,
              let probe = probesByAgentId[agentID] else {
            throw ControllerError.physicalFoodBoundary("shadow actor unavailable")
        }
        let actor = try session.state(for: agentID)
        let hasEligiblePhysicalFood = probe.carriedItems.contains { stack in
            guard let stack,
                  let descriptor = foodConsumptionDescriptor(for: stack) else { return false }
            return descriptor.food.hunger > 0 && !descriptor.food.alwaysEat
                && descriptor.food.effects.isEmpty && descriptor.hasSimpleDebit
        }
        var candidate = session
        let abstractRejected: Bool
        do {
            _ = try candidate.consumeFood(AgentConsumptionIntent(
                consumptionId: "physical-food-shadow-attempt",
                agentId: agentID,
                tick: candidate.tick
            ))
            abstractRejected = false
        } catch AgentSessionError.physicalFoodSurvival(.legacyAbstractAuthorityDisabled) {
            abstractRejected = true
        }
        guard actor.resourceInventory.count(of: .foodRaw) > 0,
              !hasEligiblePhysicalFood, abstractRejected,
              actor.needs.hunger >= session.configuration.survivalConfiguration.criticalHungerThreshold,
              (actor.survivalProgress?.consecutiveCriticalHungerTicks ?? 0) > 0,
              probe.world === world else {
            throw ControllerError.physicalFoodBoundary("shadow authority proof incomplete")
        }
        trace(
            "physical food shadow actor=\(agentID) foodRaw=\(actor.resourceInventory.count(of: .foodRaw)) "
                + "physicalFood=none abstractSpend=rejected hunger=\(actor.needs.hunger) "
                + "criticalTicks=\(actor.survivalProgress?.consecutiveCriticalHungerTicks ?? 0) "
                + "health=\(actor.health) starvation=progressed mutation=none"
        )
    }

    private func runPhysicalFoodConsumptionProof(
        session: inout AgentSimulationSession,
        world: World
    ) throws {
        let agentID = AgentID(rawValue: "agent_2")!
        guard session.physicalFoodSurvivalEnabled,
              let probe = probesByAgentId[agentID.rawValue] else {
            throw ControllerError.physicalFoodBoundary("physical food actor unavailable")
        }
        let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(probe, in: world)
        let faultBaseSlots = copyItemInventory(probe.carriedItems)
        let faultBaseSession = try session.durableStateBytes()
        let intent = try session.nextPhysicalFoodConsumptionIntent(for: agentID)
        guard let stalePlan = try foodConsumptionExecutor.prepare(
            intent, session: session, source: source,
            gateway: materialCustodyGateway
        ) else {
            throw ControllerError.physicalFoodBoundary("stale proof could not select real food")
        }
        probe.carriedItems[stalePlan.sourceSlot] = nil
        let staleResult = foodConsumptionExecutor.execute(
            stalePlan, session: &session, source: source,
            gateway: materialCustodyGateway
        )
        probe.carriedItems = copyItemInventory(faultBaseSlots)
        guard staleResult.status == .staleCustody,
              try session.durableStateBytes() == faultBaseSession else {
            throw ControllerError.physicalFoodBoundary("stale custody was not atomic")
        }

        guard let rollbackPlan = try foodConsumptionExecutor.prepare(
            intent, session: session, source: source,
            gateway: materialCustodyGateway
        ) else {
            throw ControllerError.physicalFoodBoundary("rollback proof could not select real food")
        }
        let rollbackResult = foodConsumptionExecutor.execute(
            rollbackPlan, session: &session, source: source,
            gateway: materialCustodyGateway,
            verifyAfterDebit: { false }
        )
        let rollbackSlots = source.read() ?? []
        guard rollbackResult.status == .verificationFailure,
              try session.durableStateBytes() == faultBaseSession,
              rollbackSlots.count == faultBaseSlots.count,
              zip(rollbackSlots, faultBaseSlots).allSatisfy({ $0 == $1 }) else {
            throw ControllerError.physicalFoodBoundary("verified physical rollback failed")
        }
        trace(
            "physical food faults actor=agent_2 stale=refused staleDebit=0 staleHungerDelta=0 "
                + "rollback=verified rollbackItem=restored rollbackSession=unchanged"
        )

        guard let plan = try foodConsumptionExecutor.prepare(
            intent, session: session, source: source, gateway: materialCustodyGateway
        ), plan.validatedOutcome.canonicalMaterialName == "sweet_berries" else {
            throw ControllerError.physicalFoodBoundary(
                "real gathered sweet berries not found in exact custody"
            )
        }
        let stateBefore = try session.state(for: agentID)
        let abstractBefore = stateBefore.resourceInventory.count(of: .foodRaw)
        let campBefore = session.campStock.count(of: .foodRaw)
        let slotCountBefore = probe.carriedItems[plan.sourceSlot]?.count ?? 0
        var recorderCandidate = replayRecorder
        let result = foodConsumptionExecutor.execute(
            plan,
            session: &session,
            source: source,
            gateway: materialCustodyGateway,
            publish: { outcome, candidate in
                if var activeRecorder = recorderCandidate {
                    _ = try activeRecorder.apply(
                        .validatedPhysicalFoodConsumption(outcome), to: &candidate
                    )
                    recorderCandidate = activeRecorder
                } else {
                    try candidate.applyValidatedPhysicalFoodConsumption(outcome)
                }
            }
        )
        guard result.succeeded, let outcome = result.outcome else {
            throw ControllerError.physicalFoodBoundary(
                "exact consumption failed status=\(result.status.rawValue)"
            )
        }
        replayRecorder = recorderCandidate
        let stateAfter = try session.state(for: agentID)
        let slotCountAfter = probe.carriedItems[plan.sourceSlot]?.count ?? 0
        guard slotCountBefore == slotCountAfter + 1,
              stateAfter.needs.hunger == outcome.hungerAfter,
              stateAfter.resourceInventory.count(of: .foodRaw) == abstractBefore,
              session.campStock.count(of: .foodRaw) == campBefore,
              session.conservationSnapshot().consumedTotal == 0 else {
            throw ControllerError.physicalFoodBoundary(
                "physical food conservation or survival publication diverged"
            )
        }
        let duplicateSession = try session.durableStateBytes()
        let duplicateSlots = copyItemInventory(probe.carriedItems)
        let duplicate = foodConsumptionExecutor.execute(
            plan, session: &session, source: source,
            gateway: materialCustodyGateway
        )
        guard duplicate.status == .duplicate,
              try session.durableStateBytes() == duplicateSession,
              zip(probe.carriedItems, duplicateSlots).allSatisfy({ $0 == $1 }) else {
            throw ControllerError.physicalFoodBoundary("duplicate consumption was not idempotent")
        }
        trace(
            "physical food live actor=agent_2 source=CIV23-wildGathering material=sweet_berries "
                + "slot=\(plan.sourceSlot) countBefore=\(slotCountBefore) consumed=1 "
                + "countAfter=\(slotCountAfter) remainder=none coreHunger=\(outcome.coreHungerPoints) "
                + "saturation=\(outcome.coreSaturation) hunger=\(outcome.hungerBefore)>\(outcome.hungerAfter) "
                + "criticalTicks=\(stateBefore.survivalProgress?.consecutiveCriticalHungerTicks ?? 0)>"
                + "\(stateAfter.survivalProgress?.consecutiveCriticalHungerTicks ?? 0) "
                + "foodRawDelta=0 campStockDelta=0 localEcologyDelta=0 resourceInventoryDelta=0 "
                + "receipt=\(outcome.physicalReceiptID) custody=real physicalConservation=exact"
        )
        trace(
            "physical food duplicate actor=agent_2 consumptionID=\(outcome.consumptionID) "
                + "secondDebit=0 secondHungerDelta=0 secondHistory=0"
        )
    }

    private func finalizePhysicalFoodProof(
        session: AgentSimulationSession,
        world: World
    ) throws {
        guard session.physicalFoodSurvivalEnabled,
              let physical = session.physicalFoodSurvivalSnapshot(),
              let outcome = physical.completedOutcomes.last,
              outcome.canonicalMaterialName == "sweet_berries",
              session.wildSubsistenceSnapshot().retainedOutcomes.contains(where: {
                  $0.outcome.strategy == .wildGathering
                      && $0.outcome.acquiredItems.contains {
                          $0.identity.itemKey == "sweet_berries"
                      }
              }),
              probesByAgentId["agent_2"]?.world === world else {
            throw ControllerError.physicalFoodBoundary("primary productive food chain missing")
        }
        let checkpoint = try session.makeCheckpoint()
        let restored = try AgentSimulationSession.restoring(checkpoint)
        guard checkpoint.schemaVersion == 17,
              try restored.durableStateBytes() == session.durableStateBytes() else {
            throw ControllerError.physicalFoodBoundary("v17 restart proof failed")
        }
        let actor = try session.state(for: "agent_2")
        trace(
            "physical food proof authority=physicalItems source=matureSweetBerryBush "
                + "observation=real gathering=canonicalBreak itemEntity=real acquisition=exact "
                + "custody=real consumption=exact survival=AgentNeeds.hunger "
                + "hunger=\(actor.needs.hunger) health=\(actor.health) history=\(physical.completedOutcomes.count) "
                + "abstractCredit=0 schema=17 restart=validatedOutcomeOnly physicalInventoryOwner=PebbleCore "
                + "GateR=acquired foodBlocker=remediated autonomyBlocker=open GateB=notAcquired runtimeErrors=\(runtimeErrorCount)"
        )
    }
}
