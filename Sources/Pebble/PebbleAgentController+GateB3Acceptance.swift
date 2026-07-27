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
        let autonomyBefore = session.autonomousActivitySnapshot().counters
        let workBefore = session.workCommitmentSnapshot()
        let careBefore = session.dependentCareSnapshot()
        let baseline = "tick=\(session.tick) "
            + "completionsBefore=\(autonomyBefore.completionCount) "
            + "workEvidenceBefore=\(workBefore.totalEvidenceCount)"
        switch kind {
        case "material-reactivation-berry":
            let actors = session.snapshot().agents.filter { $0.health > 0 }
                .sorted { $0.id < $1.id }
            guard let actor = actors.first else {
                trace(
                    "GATE_B_MATERIAL_REACTIVATION tick=\(session.tick) "
                        + "applied=0 reason=no_living_observer"
                )
                return
            }
            let offsets = [
                (1, 0), (0, 1), (-1, 0), (0, -1),
                (1, 1), (-1, 1), (-1, -1), (1, -1),
            ]
            let target = offsets.lazy.compactMap { dx, dz -> PhysicalBlockPosition? in
                let value = PhysicalBlockPosition(
                    x: actor.position.x + dx,
                    y: actor.position.y,
                    z: actor.position.z + dz
                )
                guard world.getBlock(value.x, value.y, value.z) == 0 else {
                    return nil
                }
                return value
            }.first
            guard let target else {
                trace(
                    "GATE_B_MATERIAL_REACTIVATION tick=\(session.tick) "
                        + "applied=0 reason=no_local_physical_site actor=\(actor.id)"
                )
                return
            }
            let before = world.getBlock(target.x, target.y, target.z)
            world.setBlock(
                target.x, target.y, target.z,
                Int(cell(B.sweet_berry_bush, 3)), SET_NO_NEIGHBORS
            )
            let expected = Int(cell(B.sweet_berry_bush, 3))
            guard world.getBlock(target.x, target.y, target.z) == expected else {
                world.setBlock(
                    target.x, target.y, target.z, before, SET_NO_NEIGHBORS
                )
                precondition(
                    world.getBlock(target.x, target.y, target.z) == before,
                    "Gate B material reactivation rollback failed"
                )
                trace(
                    "GATE_B_MATERIAL_REACTIVATION tick=\(session.tick) "
                        + "applied=0 reason=physical_verification_failed "
                        + "rollback=verified"
                )
                return
            }
            trace(
                "GATE_B_MATERIAL_REACTIVATION tick=\(session.tick) "
                    + "applied=1 actor=\(actor.id) source=sweet_berry_bush "
                    + "position=\(target.x),\(target.y),\(target.z) "
                    + "candidateInjected=0 opportunityInjected=0 "
                    + "activityInjected=0 successInjected=0 "
                    + "observation=normal_local_sensor"
            )
        case "worker-care":
            let active = session.activeWorkCommitments()
                .filter { $0.status == .active }
                .sorted {
                    if $0.startedAtTick != $1.startedAtTick {
                        return $0.startedAtTick < $1.startedAtTick
                    }
                    return $0.commitmentID < $1.commitmentID
                }
            let activeCaregiverIDs = Set(careBefore.assignments.filter {
                $0.status == .active
            }.map(\.caregiverID))
            let actorID = active.first(where: {
                activeCaregiverIDs.contains($0.workerID)
            })?.workerID.rawValue
                ?? active.first?.workerID.rawValue
                ?? passiveSocietyAudit.completionsByAgent.sorted {
                    if $0.value != $1.value { return $0.value > $1.value }
                    return $0.key < $1.key
                }.first?.key
            guard let actorID, let probe = probesByAgentId[actorID],
                  probe.world === world, !probe.dead else {
                trace(
                    "GATE_B3_SHOCK kind=worker-care applied=0 \(baseline) "
                        + "reason=no_available_productive_worker "
                        + "carePressureBefore=\(careBefore.activeNeeds.count) "
                        + "replacementInjected=0 foodInjected=0"
                )
                return
            }
            // The shock removes the selected incumbent's physical availability.
            // It does not suspend, replace, heal, or assign anybody.
            probe.dead = true
            trace(
                "GATE_B3_SHOCK kind=worker-care applied=1 \(baseline) "
                    + "actor=\(actorID) removedWorker=1 "
                    + "selection=oldest_active_commitment_or_observed_productivity "
                    + "physicalAvailable=0 replacementInjected=0 foodInjected=0 "
                    + "carePressureBefore=\(careBefore.activeNeeds.count) "
                    + "careAssignmentsBefore=\(activeCaregiverIDs.count)"
            )
        case "tool-feed":
            let removable = Set([
                "iron_hoe", "wheat", "wheat_seeds", "fishing_rod", "shears",
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
            if let fixture = passiveSocietyFixture,
               var containerItems = fixture.container.items {
                for index in containerItems.indices {
                    guard let stack = containerItems[index] else { continue }
                    let name = itemDef(stack.id).name
                    guard removable.contains(name) else { continue }
                    removed[name, default: 0] += stack.count
                    containerItems[index] = nil
                }
                fixture.container.items = containerItems
            }
            let summary = removed.keys.sorted().map {
                "\($0):\(removed[$0]!)"
            }.joined(separator: ",")
            let removedQuantity = removed.values.reduce(0, +)
            let livestockDisruption =
                (removed["wheat"] ?? 0) + (removed["shears"] ?? 0) > 0
            let wildDisruption = (removed["fishing_rod"] ?? 0) > 0
            trace(
                "GATE_B3_SHOCK kind=tool-feed "
                    + "applied=\(removedQuantity > 0 ? 1 : 0) \(baseline) "
                    + "removed=\(summary.isEmpty ? "none" : summary) "
                    + "removedQuantity=\(removedQuantity) "
                    + "livestockDisruption=\(livestockDisruption ? 1 : 0) "
                    + "wildDisruption=\(wildDisruption ? 1 : 0) "
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
        let productiveSources = session.productiveSourceSnapshot()
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
        traceGateBFiniteWorldSnapshot(
            session: session,
            autonomy: autonomy,
            sources: productiveSources,
            activeWorkCommitments: activeCommitments
        )
    }

    private func traceGateBFiniteWorldSnapshot(
        session: AgentSimulationSession,
        autonomy: AgentAutonomousActivitySnapshot,
        sources: AgentProductiveSourceSnapshot,
        activeWorkCommitments: Int
    ) {
        let viable = sources.sources.filter(\.viability.eligible)
        let temporary = sources.sources.filter {
            $0.viability == .temporarilyUnavailable
        }
        let depleted = sources.sources.filter { $0.viability == .depleted }
        let withdrawn = sources.sources.filter { $0.viability == .withdrawn }
        let activeCooldowns = autonomy.cooldowns.filter {
            $0.untilTick >= session.tick
        }.count
        let expiredCooldowns = autonomy.cooldowns.count - activeCooldowns
        let generated = (session.tick - passiveSocietyAudit.lastDecisionTick) <= 1
            ? passiveSocietyAudit.lastGeneratedCandidateCount : -1
        let state: String
        let contradiction: String
        if generated > 0 || !autonomy.activeActivities.isEmpty {
            state = "PRODUCTIVE"
            contradiction = "none"
        } else if !viable.isEmpty {
            state = "FALSE_QUIESCENCE"
            contradiction = "viable_source_without_candidate"
        } else if activeWorkCommitments > 0 {
            state = "FALSE_QUIESCENCE"
            contradiction = "active_work_without_candidate"
        } else {
            state = "QUIESCENT_NO_EXECUTABLE_SOURCE"
            contradiction = "none"
        }
        let domains = AgentAutonomousActivityDomain.allCases.map { domain in
            let values = sources.sources.filter { $0.domain == domain }
            let candidateCount = passiveSocietyAudit
                .lastGeneratedCandidatesByDomain[domain.rawValue, default: 0]
            return "\(domain.rawValue):"
                + "o\(values.count)"
                + "v\(values.filter { $0.viability.eligible }.count)"
                + "t\(values.filter { $0.viability == .temporarilyUnavailable }.count)"
                + "d\(values.filter { $0.viability == .depleted }.count)"
                + "w\(values.filter { $0.viability == .withdrawn }.count)"
                + "c\(candidateCount)"
        }.joined(separator: ",")
        trace(
            "GATE_B_FINITE_WORLD tick=\(session.tick) state=\(state) "
                + "contradiction=\(contradiction) "
                + "sourcesObserved=\(sources.sources.count) "
                + "sourcesViable=\(viable.count) "
                + "sourcesTemporary=\(temporary.count) "
                + "sourcesDepleted=\(depleted.count) "
                + "sourcesWithdrawn=\(withdrawn.count) "
                + "candidatesGenerated=\(generated) "
                + "activitiesActive=\(autonomy.activeActivities.count) "
                + "workExecutable=\(activeWorkCommitments) "
                + "cooldownsActive=\(activeCooldowns) "
                + "cooldownsExpired=\(expiredCooldowns) "
                + "domains=\(domains)"
        )
    }
}
