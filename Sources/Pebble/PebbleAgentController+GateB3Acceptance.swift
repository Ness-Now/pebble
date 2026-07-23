import PebbleAgents
import PebbleCore

/// Read-only and subtractive instrumentation used only by the explicitly
/// gated Gate B re-evaluation harness. It never selects an activity, creates a
/// material outcome, or publishes Civilization state.
extension PebbleAgentController {
    func applyGateB3AcceptanceShock(_ kind: String, world: World) {
        guard environment["PEBBLELAB_GATE_B3_ACCEPTANCE"] == "1",
              activeWorld === world, let session else {
            trace("GATE_B3_SHOCK refused reason=acceptance_gate_or_session")
            return
        }
        switch kind {
        case "worker-care":
            let active = session.activeWorkCommitments()
                .filter { $0.status == .active }
                .sorted {
                    if $0.startedAtTick != $1.startedAtTick {
                        return $0.startedAtTick < $1.startedAtTick
                    }
                    return $0.commitmentID < $1.commitmentID
                }
            let actorID = active.first?.workerID.rawValue
                ?? passiveSocietyAudit.completionsByAgent.sorted {
                    if $0.value != $1.value { return $0.value > $1.value }
                    return $0.key < $1.key
                }.first?.key
            guard let actorID, let probe = probesByAgentId[actorID],
                  probe.world === world, !probe.dead else {
                trace(
                    "GATE_B3_SHOCK kind=worker-care applied=0 "
                        + "reason=no_available_productive_worker carePressure=not_injected"
                )
                return
            }
            // The shock removes the selected incumbent's physical availability.
            // It does not suspend, replace, heal, or assign anybody.
            probe.dead = true
            trace(
                "GATE_B3_SHOCK kind=worker-care applied=1 actor=\(actorID) "
                    + "selection=oldest_active_commitment_or_observed_productivity "
                    + "physicalAvailable=0 replacementInjected=0 foodInjected=0 "
                    + "carePressure=not_injected"
            )
        case "tool-feed":
            let removable = Set([
                "iron_hoe", "wheat", "wheat_seeds", "fishing_rod",
            ])
            var removed: [String: Int] = [:]
            for key in probesByAgentId.keys.sorted() {
                guard let probe = probesByAgentId[key], probe.world === world else { continue }
                for index in probe.carriedItems.indices {
                    guard let stack = probe.carriedItems[index] else { continue }
                    let name = itemDef(stack.id).name
                    guard removable.contains(name) else { continue }
                    removed[name, default: 0] += stack.count
                    probe.carriedItems[index] = nil
                }
            }
            let summary = removed.keys.sorted().map {
                "\($0):\(removed[$0]!)"
            }.joined(separator: ",")
            trace(
                "GATE_B3_SHOCK kind=tool-feed applied=\(removed.isEmpty ? 0 : 1) "
                    + "removed=\(summary.isEmpty ? "none" : summary) "
                    + "replacementToolInjected=0 replacementFeedInjected=0 "
                    + "successInjected=0"
            )
        default:
            trace("GATE_B3_SHOCK refused reason=unknown_kind kind=\(kind)")
        }
    }

    func traceGateB3AcceptanceSnapshot(world: World) {
        guard environment["PEBBLELAB_GATE_B3_ACCEPTANCE"] == "1",
              activeWorld === world, let session else {
            trace("GATE_B3_ACCEPTANCE_SNAPSHOT unavailable=1")
            return
        }
        let snapshot = session.snapshot()
        let autonomy = session.autonomousActivitySnapshot()
        let agriculture = session.agricultureSnapshot()
        let wild = session.wildSubsistenceSnapshot()
        let livestock = session.livestockSnapshot()
        let care = session.dependentCareSnapshot()
        let teaching = session.teachingSnapshot()
        let work = session.workCommitmentSnapshot()
        let causal = session.causalLedgerSnapshot().summary
        let physicalFood = session.physicalFoodSurvivalSnapshot()
        let durableDigest = (try? session.durableStateDigest().rawValue) ?? "unavailable"

        var physicalItems: [String: Int] = [:]
        for key in probesByAgentId.keys.sorted() {
            guard let probe = probesByAgentId[key], probe.world === world else { continue }
            for stack in probe.carriedItems.compactMap({ $0 }) {
                physicalItems[itemDef(stack.id).name, default: 0] += stack.count
            }
        }
        if let fixture = passiveSocietyFixture,
           let containerItems = fixture.container.items {
            for stack in containerItems.compactMap({ $0 }) {
                physicalItems[itemDef(stack.id).name, default: 0] += stack.count
            }
        }
        let physicalStock = physicalItems.keys.sorted().map {
            "\($0):\(physicalItems[$0]!)"
        }.joined(separator: ",")
        let genericResourceUnits = snapshot.agents.reduce(0) { partial, agent in
            partial + agent.resourceInventory.amounts.reduce(0) { $0 + $1.quantity }
        }
        let campStockUnits = snapshot.campStock.amounts.reduce(0) { $0 + $1.quantity }
        let localEcologyYield = session.localEcologyEnabled
            ? session.localEcologySnapshot().patches.reduce(0) { $0 + $1.currentYield }
            : 0
        let wildCounts = AgentSubsistenceStrategy.allCases.map {
            "\($0.rawValue):\(wild.successfulCounts[$0, default: 0])"
        }.joined(separator: ",")
        let activeCommitments = work.commitments.filter { $0.status == .active }.count
        let completedCare = care.terminalOutcomes.filter { $0.status == .resolved }.count
        let living = snapshot.agents.filter { $0.health > 0 }.count
        let dead = snapshot.agentCount - living
        let movementCount = snapshot.agents.reduce(0) { $0 + $1.movementCount }

        trace(
            "GATE_B3_ACCEPTANCE_SNAPSHOT seed=\(seed) tick=\(session.tick) "
                + "agents=\(snapshot.agentCount) alive=\(living) dead=\(dead) "
                + "worldEntities=\(world.entities.count) runtimeErrors=\(runtimeErrorCount) "
                + "manualProductive=\(manualProductiveCommandsAfterBootstrap) "
                + "movementEnabled=\(movementEnabled ? 1 : 0) "
                + "movementEverEnabled=\(movementWasEverEnabledSinceReset ? 1 : 0) "
                + "movementOperations=\(movementCount) "
                + "movementBlocks=\(blockedMovementOutcomeCount) "
                + "maxDistanceHome=\(maxObservedDistanceFromHome) "
                + "successfulCognitiveTicks=\(successfulCognitiveTicks) "
                + "decisions=\(autonomy.counters.decisionCount) "
                + "candidates=\(autonomy.counters.candidateCount) "
                + "starts=\(autonomy.counters.startCount) "
                + "completed=\(autonomy.counters.completionCount) "
                + "blocked=\(autonomy.counters.blockCount) "
                + "switches=\(autonomy.counters.switchCount) "
                + "agricultureActions=\(agriculture.totalActionCount) "
                + "agricultureCycles=\(agriculture.completedCycleCount) "
                + "wildAttempts=\(wild.totalAttemptCount) wildSuccess=\(wildCounts) "
                + "livestockAnimals=\(livestock.managedAnimals.count) "
                + "livestockRecords=\(livestock.retainedTaskRecords.count) "
                + "livestockProducts=\(livestock.productRecords.count) "
                + "livestockBreeding=\(livestock.breedingDecisions.count) "
                + "careNeeds=\(care.totalNeedCount) careOutcomes=\(care.totalOutcomeCount) "
                + "careResolved=\(completedCare) "
                + "teachingApprenticeships=\(teaching.totalApprenticeshipCount) "
                + "teachingDemonstrations=\(teaching.totalDemonstrationCount) "
                + "teachingGuided=\(teaching.totalGuidedPracticeCount) "
                + "workDemands=\(work.totalDemandCount) "
                + "workCommitments=\(work.totalCommitmentCount) "
                + "workActive=\(activeCommitments) "
                + "workEvidence=\(work.totalEvidenceCount) "
                + "workReassignments=\(work.totalReassignmentCount) "
                + "profiles=\(work.professionProfiles.count) "
                + "workRefreshAttempts=\(workDemandRefreshAudit.attempts) "
                + "workHeartbeats=\(workDemandRefreshAudit.sameProvenanceHeartbeats) "
                + "workMeaningfulRefreshes=\(workDemandRefreshAudit.meaningfulRefreshes) "
                + "workNewDemands=\(workDemandRefreshAudit.newLogicalDemands) "
                + "workWithdrawals=\(workDemandRefreshAudit.withdrawals) "
                + "workReactivations=\(workDemandRefreshAudit.reactivations) "
                + "workCommitmentsPreserved=\(workDemandRefreshAudit.commitmentsPreserved) "
                + "workRefreshEvents=\(workDemandRefreshAudit.workDemandRefreshedEvents) "
                + "workIdentityRejects=\(workDemandRefreshAudit.actualIdentityRejections) "
                + "workStaleRejects=\(workDemandRefreshAudit.staleProvenanceRejections) "
                + "physicalFoodTotal=\(physicalFood?.totalConsumedQuantity ?? 0) "
                + "physicalFoodRetainedIDs=\(physicalFood?.recentConsumptionIDs.count ?? 0) "
                + "physicalFoodDroppedIDs=\(physicalFood?.droppedConsumptionIDCount ?? 0) "
                + "physicalStock=\(physicalStock.isEmpty ? "none" : physicalStock) "
                + "campStockUnits=\(campStockUnits) "
                + "genericResourceUnits=\(genericResourceUnits) "
                + "localEcologyYield=\(localEcologyYield) "
                + "autonomyRetained=\(autonomy.recentRecords.count) "
                + "autonomyEvicted=\(autonomy.evictionCount) "
                + "causalRetained=\(causal.retainedEventCount) "
                + "causalDropped=\(causal.droppedEventCount) "
                + "digest=\(durableDigest) "
                + passiveSocietyAuditSummary()
        )
    }
}
