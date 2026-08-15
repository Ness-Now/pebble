import PebbleAgents
import PebbleCore

struct PebbleAgentPassiveSocietyFixture {
    struct OriginalCell {
        let position: PhysicalBlockPosition
        let cell: Int
    }

    struct OriginalActor {
        let agentID: String
        let carriedItems: [ItemStack?]
    }

    let originalCells: [OriginalCell]
    let originalActors: [OriginalActor]
    let entityIDsBefore: Set<Int>
    let container: BlockEntityData
}

struct PebbleAgentPassiveSocietyAudit {
    var currentIdleByAgent: [String: Int] = [:]
    var longestIdleByAgent: [String: Int] = [:]
    var idleReasonsByAgent: [String: [String: Int]] = [:]
    var idleWhileEligibleViolations = 0
    var lastCompletedFamilyByAgent: [String: String] = [:]
    var sameFamilyContinuations = 0
    var crossFamilySwitches = 0
    var completionsByAgent: [String: Int] = [:]
    var completionsByFamily: [String: Int] = [:]
    var lastDecisionCandidateByAgent: [String: String] = [:]
    var lastDecisionTick = -1
    var lastGeneratedCandidateCount = 0
    var lastGeneratedCandidatesByDomain: [String: Int] = [:]

    mutating func reset(agentIDs: [String]) {
        self = PebbleAgentPassiveSocietyAudit()
        for id in agentIDs.sorted() {
            currentIdleByAgent[id] = 0
            longestIdleByAgent[id] = 0
            idleReasonsByAgent[id] = [:]
            completionsByAgent[id] = 0
        }
    }
}

struct PebblePassiveProductProofSnapshot {
    let bootstrapComplete: Bool
    let simulationTick: Int
    let decisions: Int
    let completions: Int
    let runtimeErrors: Int
    let aliveAgents: Int
    let movementEnabled: Bool
    let movementEverEnabled: Bool
}

extension PebbleAgentController {
    func preparePassiveSocietySlice(
        world: World,
        session published: inout AgentSimulationSession,
        recorder publishedRecorder: inout AgentReplayRecorder?
    ) throws {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              agricultureFeatureEnabled, wildSubsistenceFeatureEnabled,
              livestockFeatureEnabled, materialFeatureEnabled,
              ecologicalObservationFeatureEnabled, isPaused, !movementEnabled else {
            throw ControllerError.feedbackBoundary(
                "passive society requires disposable World, composite gates, pause, and movement off"
            )
        }
        guard published.populationEnabled, published.lifecycleEnabled,
              published.skillsEnabled, published.ecologicalObservationEnabled,
              cleanupPassiveSocietyFixture(world: world), let anchor else {
            throw ControllerError.feedbackBoundary(
                "passive society requires population, lifecycle, skills, observation, and clean fixture"
            )
        }

        let snapshots = published.snapshot().agents.sorted { $0.id < $1.id }
        guard snapshots.count >= 3 else {
            throw ControllerError.feedbackBoundary("passive society requires at least three agents")
        }
        let fieldCenter = AgentPosition(
            x: anchor.x + 4, y: anchor.y, z: anchor.z - 5
        )
        let penCenter = AgentPosition(x: anchor.x + 7, y: anchor.y, z: anchor.z + 1)
        let wildPosition = AgentPosition(x: anchor.x + 1, y: anchor.y, z: anchor.z)
        let secondWildPosition = AgentPosition(
            x: anchor.x + 1, y: anchor.y, z: anchor.z - 3
        )
        let integratedTeachingProof =
            environment["PEBBLELAB_INTEGRATED_TEACHING_PROOF"] == "1"
        // The plot belongs to the physical settlement layout, not to a chosen
        // future farmer. Every inhabitant receives the same finite starter
        // custody below; fresh local observation and product arbitration decide
        // whether anyone plans or works this site after bootstrap.
        let fieldPositions = [
            AgentPosition(
                x: fieldCenter.x, y: anchor.y - 1, z: fieldCenter.z + 1
            ),
            AgentPosition(
                x: fieldCenter.x + 1, y: anchor.y - 1, z: fieldCenter.z + 1
            ),
            AgentPosition(
                x: fieldCenter.x, y: anchor.y - 1, z: fieldCenter.z
            ),
        ]
        let actorIDs = snapshots.map(\.id)
        let embodiments = try PebbleAgentEmbodiment.resolveAll(
            agentIDs: actorIDs, in: world, mappedByAgentID: probesByAgentId
        )

        let minimumX = anchor.x - 4
        let maximumX = anchor.x + 13
        let minimumZ = anchor.z - 10
        let maximumZ = anchor.z + 7
        var originalCells: [PebbleAgentPassiveSocietyFixture.OriginalCell] = []
        for x in minimumX...maximumX {
            for z in minimumZ...maximumZ {
                guard world.isChunkReady(x >> 4, z >> 4) else {
                    throw ControllerError.feedbackBoundary("passive society fixture chunk unavailable")
                }
                for y in (anchor.y - 2)...(anchor.y + 4) {
                    guard world.getBlockEntity(x, y, z) == nil else {
                        throw ControllerError.feedbackBoundary("passive society fixture overlaps block entity")
                    }
                    originalCells.append(.init(
                        position: PhysicalBlockPosition(x: x, y: y, z: z),
                        cell: world.getBlock(x, y, z)
                    ))
                }
            }
        }
        let originalActors = actorIDs.map { id in
            PebbleAgentPassiveSocietyFixture.OriginalActor(
                agentID: id,
                carriedItems: copyItemInventory(embodiments[id]!.carriedItems)
            )
        }
        let entityIDsBefore = Set(world.entities.map(\.id))

        for original in originalCells {
            let position = original.position
            let replacement = position.y <= anchor.y - 1 ? Int(cell(B.stone)) : 0
            world.setBlock(
                position.x, position.y, position.z, replacement, SET_NO_NEIGHBORS
            )
        }
        for position in fieldPositions {
            world.setBlock(
                position.x, position.y, position.z, Int(cell(B.dirt)), SET_NO_NEIGHBORS
            )
        }
        let fieldWater = PhysicalBlockPosition(
            x: anchor.x + 3, y: anchor.y - 1, z: anchor.z - 3
        )
        world.setBlock(
            fieldWater.x, fieldWater.y, fieldWater.z, Int(cell(B.water)), SET_NO_NEIGHBORS
        )
        let containerPosition = PhysicalBlockPosition(
            x: anchor.x + 6, y: anchor.y, z: anchor.z - 5
        )
        world.setBlock(
            containerPosition.x, containerPosition.y, containerPosition.z,
            Int(cell(B.chest)), SET_NO_NEIGHBORS
        )
        let container = makeContainerBE(
            containerPosition.x, containerPosition.y, containerPosition.z, 27
        )
        world.setBlockEntity(container)

        let fenceID = UInt16(bid("oak_fence"))
        for x in (penCenter.x - 3)...(penCenter.x + 3) {
            for z in (penCenter.z - 3)...(penCenter.z + 3)
                where x == penCenter.x - 3 || x == penCenter.x + 3
                    || z == penCenter.z - 3 || z == penCenter.z + 3 {
                world.setBlock(x, penCenter.y, z, Int(cell(fenceID)), SET_NO_NEIGHBORS)
            }
        }
        world.setBlock(
            penCenter.x - 3, penCenter.y, penCenter.z, 0, SET_NO_NEIGHBORS
        )
        world.setBlock(
            penCenter.x - 1, penCenter.y, penCenter.z - 3, 0, SET_NO_NEIGHBORS
        )
        world.setBlock(
            penCenter.x, penCenter.y, penCenter.z - 3, 0, SET_NO_NEIGHBORS
        )
        world.setBlock(
            penCenter.x - 3, penCenter.y, penCenter.z - 2, 0, SET_NO_NEIGHBORS
        )
        for z in (anchor.z - 3)...(anchor.z - 2) {
            world.setBlock(
                anchor.x + 4, anchor.y - 1, z,
                Int(cell(B.water)), SET_NO_NEIGHBORS
            )
        }
        var berryPositions = integratedTeachingProof
            ? [] : [wildPosition, secondWildPosition]
        if integratedTeachingProof {
            // The disposable proof supplies repeated real opportunities, never
            // skill, Teaching state, or a designated teacher/student. Existing
            // agriculture, livestock, equipment, distance, and arbitration
            // determine which inhabitant becomes practiced first.
            for xOffset in [-1, 1, 3, 5] {
                for zOffset in [-8, -6, -4, -2, 0] {
                    if xOffset == 5 && zOffset >= -2 { continue }
                    berryPositions.append(AgentPosition(
                        x: anchor.x + xOffset,
                        y: anchor.y,
                        z: anchor.z + zOffset
                    ))
                }
            }
        }
        for position in berryPositions {
            world.setBlock(
                position.x, position.y, position.z,
                Int(cell(B.sweet_berry_bush, 3)), SET_NO_NEIGHBORS
            )
        }

        let firstSheep = spawnMob(
            world, "sheep", Double(penCenter.x) + 0.5, Double(penCenter.y),
            Double(penCenter.z - 3) + 0.5, SpawnOpts()
        ) as! Sheep
        let secondSheep = spawnMob(
            world, "sheep", Double(penCenter.x - 2) + 0.5, Double(penCenter.y),
            Double(penCenter.z - 2) + 0.5, SpawnOpts()
        ) as! Sheep
        firstSheep.persistent = true
        secondSheep.persistent = true

        passiveSocietyFixture = PebbleAgentPassiveSocietyFixture(
            originalCells: originalCells, originalActors: originalActors,
            entityIDsBefore: entityIDsBefore, container: container
        )

        do {
            var candidate = published
            var recorder = publishedRecorder
            if !candidate.agricultureEnabled {
                if try applyRecordedOperationIfActive(
                    .setAgricultureEnabled(true, configuration: .live),
                    session: &candidate, recorder: &recorder
                ) == nil { try candidate.setAgricultureEnabled(true) }
            }
            if !candidate.wildSubsistenceEnabled {
                if try applyRecordedOperationIfActive(
                    .setWildSubsistenceEnabled(true, configuration: .live),
                    session: &candidate, recorder: &recorder
                ) == nil { try candidate.setWildSubsistenceEnabled(true) }
            }
            if !candidate.livestockEnabled {
                if try applyRecordedOperationIfActive(
                    .setLivestockEnabled(true, configuration: .live),
                    session: &candidate, recorder: &recorder
                ) == nil { try candidate.setLivestockEnabled(true) }
            }

            for id in actorIDs {
                embodiments[id]!.carriedItems = Array(
                    repeating: nil, count: LabCoreAgentEntity.carriedItemSlotCount
                )
                embodiments[id]!.carriedItems[0] = ItemStack(iid("iron_hoe"), 1)
                embodiments[id]!.carriedItems[1] = ItemStack(iid("wheat_seeds"), 4)
                embodiments[id]!.carriedItems[2] = ItemStack(iid("wheat"), 3)
                embodiments[id]!.carriedItems[3] = ItemStack(
                    iid("fishing_rod"), 1, damage: 63
                )
                embodiments[id]!.carriedItems[4] = ItemStack(iid("shears"), 1)
            }
            ecologicalObservationSensor.invalidateAll()
            let roleNeutralAudit = AgentRoleNeutralBootstrapAudit(
                assignedPlanner: 0,
                assignedLivestockWorkers: 0,
                assignedWildWorker: 0,
                prequeuedProductiveTasks:
                    candidate.livestockSnapshot().activeTasks.count,
                prestartedAgriculturePlans:
                    candidate.agricultureSnapshot().plots.count,
                prestartedApprenticeships:
                    candidate.teachingSnapshot().apprenticeships.count,
                preloadedSkills: candidate.skillSnapshot().profiles.count,
                preloadedProfessions:
                    candidate.workCommitmentSnapshot().professionProfiles.count
            )
            guard roleNeutralAudit.isRoleNeutral else {
                throw ControllerError.feedbackBoundary(
                    "passive society bootstrap assigned cognitive work"
                )
            }

            published = candidate
            publishedRecorder = recorder
            passiveSocietyAudit.reset(agentIDs: actorIDs)
            for snapshot in snapshots {
                trace(
                    "passive visual identity actor=\(snapshot.id) variant="
                        + "\(PebbleAgentVisualIdentity.variant(for: snapshot.id) ?? "none") "
                        + "marker=stableAgentID position=\(positionText(snapshot.position))"
                )
            }
            trace(
                "passive composite bootstrap world=one session=one settlement=one "
                    + "agents=\(actorIDs.count) field=real storage=real water=real "
                    + "livestockPhysical=2 food=real commandsProductive=0 "
                    + "starterKits=\(actorIDs.count) kitHoe=1 kitSeeds=4 kitWheat=3 "
                    + "kitFishingRod=1 kitShears=1 custody=physical_identical_bounded "
                    + "assignedPlanner=\(roleNeutralAudit.assignedPlanner) "
                    + "assignedLivestockWorkers=\(roleNeutralAudit.assignedLivestockWorkers) "
                    + "assignedWildWorker=\(roleNeutralAudit.assignedWildWorker) "
                    + "prequeuedProductiveTasks=\(roleNeutralAudit.prequeuedProductiveTasks) "
                    + "prestartedAgriculturePlans=\(roleNeutralAudit.prestartedAgriculturePlans) "
                    + "prestartedApprenticeships=\(roleNeutralAudit.prestartedApprenticeships) "
                    + "preloadedSkills=\(roleNeutralAudit.preloadedSkills) "
                    + "preloadedProfessions=\(roleNeutralAudit.preloadedProfessions)"
            )
            if integratedTeachingProof {
                trace(
                    "integrated teaching bootstrap resources=real_sweet_berry_bushes:"
                        + "\(berryPositions.count) assignedRoles=0 fakeSkill=0 "
                        + "fakePracticeHistory=0 activeApprenticeships=0"
                )
            }
        } catch {
            _ = cleanupPassiveSocietyFixture(world: world)
            throw error
        }
    }

    func recordPassiveSocietyDecisionAudit(
        candidates: [AgentAutonomousActivityCandidate],
        session: AgentSimulationSession
    ) {
        guard passiveObserverBootstrapComplete else { return }
        passiveSocietyAudit.lastDecisionTick = session.tick
        passiveSocietyAudit.lastGeneratedCandidateCount = candidates.count
        passiveSocietyAudit.lastGeneratedCandidatesByDomain = Dictionary(
            grouping: candidates, by: { $0.domain.rawValue }
        ).mapValues(\.count)
        let autonomy = session.autonomousActivitySnapshot()
        let activeByAgent = Dictionary(uniqueKeysWithValues: autonomy.activeActivities.map {
            ($0.candidate.actorID.rawValue, $0)
        })
        let cooldowns = autonomy.cooldowns
        for agent in session.snapshot().agents.sorted(by: { $0.id < $1.id }) {
            if let active = activeByAgent[agent.id] {
                passiveSocietyAudit.currentIdleByAgent[agent.id] = 0
                if focusedAgentId == agent.id,
                   passiveSocietyAudit.lastDecisionCandidateByAgent[agent.id]
                    != active.candidate.candidateID {
                    passiveSocietyAudit.lastDecisionCandidateByAgent[agent.id]
                        = active.candidate.candidateID
                    trace(
                        "passive focus decision tick=\(session.tick) actor=\(agent.id) "
                            + "variant=\(PebbleAgentVisualIdentity.variant(for: agent.id) ?? "none") "
                            + "position=\(positionText(agent.position)) goal=\(agent.currentGoal.kind.rawValue) "
                            + "activity=\(passiveActivityFamily(active.candidate.domain))/\(active.candidate.actionKey) "
                            + "movement=\(active.lifecycle.rawValue) next=physical_executor"
                    )
                }
                continue
            }
            let observed = candidates.filter { $0.actorID.rawValue == agent.id }
            let eligible = observed.filter { candidate in
                !cooldowns.contains {
                    $0.actorID == candidate.actorID && $0.candidateID == candidate.candidateID
                        && $0.untilTick >= session.tick
                }
            }
            let reason: String
            if !eligible.isEmpty {
                reason = "eligible_candidate_unselected"
                passiveSocietyAudit.idleWhileEligibleViolations += 1
            } else if !observed.isEmpty {
                reason = "cooldown"
            } else if agent.currentGoal.kind == .satisfyHunger {
                reason = "survival_transition"
            } else {
                reason = "no_observed_opportunity"
            }
            let current = passiveSocietyAudit.currentIdleByAgent[agent.id, default: 0] + 1
            passiveSocietyAudit.currentIdleByAgent[agent.id] = current
            passiveSocietyAudit.longestIdleByAgent[agent.id] = max(
                passiveSocietyAudit.longestIdleByAgent[agent.id, default: 0], current
            )
            passiveSocietyAudit.idleReasonsByAgent[agent.id, default: [:]][reason, default: 0] += 1
        }
    }

    func recordPassiveSocietyCompletion(
        actorID: AgentID,
        family: String,
        action: String,
        receipt: String,
        session: AgentSimulationSession
    ) {
        guard passiveObserverBootstrapComplete else { return }
        let id = actorID.rawValue
        if let previous = passiveSocietyAudit.lastCompletedFamilyByAgent[id] {
            if previous == family {
                passiveSocietyAudit.sameFamilyContinuations += 1
            } else {
                passiveSocietyAudit.crossFamilySwitches += 1
                trace(
                    "passive cross-family switch actor=\(id) from=\(previous) to=\(family) "
                        + "tick=\(session.tick) cause=autonomous_completed_then_new_eligible_activity"
                )
            }
        }
        passiveSocietyAudit.lastCompletedFamilyByAgent[id] = family
        passiveSocietyAudit.completionsByAgent[id, default: 0] += 1
        passiveSocietyAudit.completionsByFamily[family, default: 0] += 1
        if focusedAgentId == id, let agent = session.snapshot().agents.first(where: { $0.id == id }) {
            trace(
                "passive focus outcome tick=\(session.tick) actor=\(id) "
                    + "variant=\(PebbleAgentVisualIdentity.variant(for: id) ?? "none") "
                    + "position=\(positionText(agent.position)) activity=\(family)/\(action) "
                    + "physicalOutcome=completed receipt=\(receipt) nextDecision=pending"
            )
        }
    }

    func passiveSocietyAuditSummary() -> String {
        let idle = passiveSocietyAudit.longestIdleByAgent.keys.sorted().map {
            "\($0):\(passiveSocietyAudit.longestIdleByAgent[$0, default: 0])"
        }.joined(separator: ",")
        let reasons = passiveSocietyAudit.idleReasonsByAgent.keys.sorted().flatMap { id in
            passiveSocietyAudit.idleReasonsByAgent[id, default: [:]].keys.sorted().map {
                "\(id).\($0):\(passiveSocietyAudit.idleReasonsByAgent[id]![$0]!)"
            }
        }.joined(separator: ",")
        let families = passiveSocietyAudit.completionsByFamily.keys.sorted().map {
            "\($0):\(passiveSocietyAudit.completionsByFamily[$0, default: 0])"
        }.joined(separator: ",")
        return "sameFamilyContinuations=\(passiveSocietyAudit.sameFamilyContinuations) "
            + "crossFamilySwitches=\(passiveSocietyAudit.crossFamilySwitches) "
            + "families=\(families.isEmpty ? "none" : families) "
            + "idleByAgent=\(idle.isEmpty ? "none" : idle) "
            + "idleReasons=\(reasons.isEmpty ? "none" : reasons) "
            + "idleEligibleViolations=\(passiveSocietyAudit.idleWhileEligibleViolations)"
    }

    func passiveProductProofSnapshot() -> PebblePassiveProductProofSnapshot? {
        guard passiveObserverBootstrapComplete, let session else { return nil }
        let counters = session.autonomousActivitySnapshot().counters
        let snapshot = session.snapshot()
        return PebblePassiveProductProofSnapshot(
            bootstrapComplete: true, simulationTick: session.tick,
            decisions: counters.decisionCount, completions: counters.completionCount,
            runtimeErrors: runtimeErrorCount,
            aliveAgents: snapshot.agents.filter(\.isAlive).count,
            movementEnabled: movementEnabled,
            movementEverEnabled: movementWasEverEnabledSinceReset
        )
    }

    func cleanupPassiveSocietyFixture(world: World) -> Bool {
        guard let fixture = passiveSocietyFixture else { return true }
        fixture.container.items = Array(repeating: nil, count: 27)
        for entity in world.entities where !fixture.entityIDsBefore.contains(entity.id) {
            world.removeEntity(entity)
        }
        for original in fixture.originalCells.reversed() {
            world.setBlock(
                original.position.x, original.position.y, original.position.z,
                original.cell, SET_NO_NEIGHBORS
            )
        }
        for original in fixture.originalActors {
            guard let probe = probesByAgentId[original.agentID], probe.world === world else {
                return false
            }
            probe.carriedItems = copyItemInventory(original.carriedItems)
        }
        let cellsRestored = fixture.originalCells.allSatisfy {
            world.getBlock($0.position.x, $0.position.y, $0.position.z) == $0.cell
                && world.getBlockEntity($0.position.x, $0.position.y, $0.position.z) == nil
        }
        let actorsRestored = fixture.originalActors.allSatisfy {
            probesByAgentId[$0.agentID]?.carriedItems == $0.carriedItems
        }
        let entitiesRestored = world.entities.allSatisfy {
            fixture.entityIDsBefore.contains($0.id)
        }
        guard cellsRestored, actorsRestored, entitiesRestored else { return false }
        passiveSocietyFixture = nil
        livestockRuntimeEntityIDByRecord.removeAll()
        ecologicalObservationSensor.invalidateAll()
        trace("passive society cleanup cells=exact entities=exact custody=exact")
        return true
    }

    func passiveActivityFamily(_ domain: AgentAutonomousActivityDomain) -> String {
        switch domain {
        case .agriculture: return "agriculture"
        case .fishing, .hunting, .wildGathering: return "wildSubsistence"
        case .livestock: return "livestock"
        case .dependentCare: return "care"
        case .teaching: return "teaching"
        case .construction, .materialHandling: return "materialWork"
        case .production: return "production"
        case .barter: return "barter"
        case .contract: return "contract"
        case .market: return "market"
        }
    }
}
