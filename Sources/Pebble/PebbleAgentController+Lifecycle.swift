import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func shutdown() -> Int {
        stop(reason: "termination")
    }

    func start(world: World, player: Player) -> PebbleAgentCommandResult {
        if let candidatePhysicalHardFailure {
            return failure(
                "PebbleAgents start refused after candidate physical hard failure: "
                    + candidatePhysicalHardFailure.description
            )
        }
        guard featureEnabled else {
            trace("error disabled; set PEBBLELAB_APP_AGENTS=1")
            return failure("PebbleAgents disabled. Set PEBBLELAB_APP_AGENTS=1 before launch.")
        }
        let anchor = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        return rebuild(
            world: world,
            player: player,
            anchor: anchor,
            seed: world.seed,
            resetSpeed: true
        )
    }

    func rebuild(
        world: World,
        player: Player,
        anchor: AgentPosition,
        seed: UInt32,
        resetSpeed: Bool
    ) -> PebbleAgentCommandResult {
        if let candidatePhysicalHardFailure {
            return failure(
                "PebbleAgents restart refused after candidate physical hard failure: "
                    + candidatePhysicalHardFailure.description
            )
        }
        let preservedMovementEnabled = movementEnabled
        let preservedFocus = focusedAgentId
        let preservedFollowMode = followMode
        let preservedDemoActive = demoActive
        if session != nil || activeWorld != nil {
            _ = stop(
                reason: resetSpeed ? "restart" : "reset",
                fallbackWorld: world
            )
            guard session == nil, activeWorld == nil else {
                return failure(
                    "PebbleAgents \(resetSpeed ? "restart" : "reset") refused: "
                        + "verified cleanup failed."
                )
            }
        }
        guard constructionExecutor.cleanup(world: world) else {
            return failure("PebbleAgents rebuild refused: construction cleanup failed.")
        }
        guard interactionExecutor.cleanup(world: world) else {
            return failure("PebbleAgents rebuild refused: interaction sandbox cleanup failed.")
        }
        interactionExecutor.clearBoundaryAudit()
        naturalResourceExecutor.resetDiagnostics()
        materialCustodyGateway.reset()
        ecologicalObservationSensor.invalidateAll()
        worldReceiptAttemptSerial = 0
        livestockRuntimeEntityIDByRecord.removeAll()
        let probeCount = world.entities.compactMap { $0 as? LabCoreAgentEntity }.count
        guard clearLabCoreAgentProbes(in: world) == probeCount else {
            return failure("PebbleAgents rebuild refused: physical custody cleanup failed.")
        }
        probesByAgentId.removeAll()
        do {
            let placement = try bootstrapPlacementResolver.resolve(
                world: world,
                anchor: anchor,
                player: player,
                socialEnabled: socialFeatureEnabled
            )
            trace(
                "bootstrap placement status=accepted anchor=\(positionText(anchor)) "
                    + placement.traceSummary
            )
            let survivalConfiguration = autonomousCivilizationFeatureEnabled
                ? try AgentSurvivalConfiguration(
                    hungerPerTick: 0.0008, fatiguePerTick: 0.0006,
                    hungryThreshold: 0.40, criticalHungerThreshold: 0.80,
                    hungerRecoveryThreshold: 0.15,
                    fatigueThreshold: 0.65, fatigueRecoveryThreshold: 0.20,
                    foodNutrition: 1.0, restRecoveryPerTick: 1.0,
                    starvationGraceTicks: 2, starvationDamagePerTick: 10
                )
                : .live
            let configuration = try AgentSessionConfiguration(
                seed: seed,
                nearbyRadius: 8,
                resourceObservationRadius: 8,
                recentMemorySnapshotLimit: 6,
                memoryPolicy: .bounded(maxEntries: 128),
                survivalConfiguration: survivalConfiguration
            )
            let candidateSession = try AgentSimulationSession(
                configuration: configuration,
                agents: try initialAgentStates(
                    positionsByAgentID: placement.positionsByAgentID
                ),
                initialTick: 0,
                simulationID: try AgentSimulationID(
                    validating: "live-\(seed)-\(anchor.x)-\(anchor.y)-\(anchor.z)"
                ),
                causalLedgerPolicy: .bounded(maxEvents: 8192)
            )
            let stagedProbes = try stageInitialProbes(
                for: candidateSession.snapshot(),
                in: world
            )
            do {
                try verifyInitialBootstrap(
                    session: candidateSession,
                    probes: stagedProbes,
                    world: world,
                    player: player
                )
            } catch {
                try rollbackInitialProbes(
                    stagedProbes.values.sorted { $0.labAgentId > $1.labAgentId },
                    in: world,
                    cause: error
                )
                throw error
            }

            // This is the publication boundary: both sides have already been
            // constructed and verified, and no throwing work remains.
            session = candidateSession
            probesByAgentId = stagedProbes
            self.seed = seed
            self.anchor = anchor
            activeWorld = world
            isPaused = false
            if resetSpeed {
                if environment["PEBBLELAB_GATE_B3_ACCEPTANCE"] == "1",
                   let raw = environment["PEBBLELAB_GATE_B3_COGNITIVE_HZ"],
                   let acceptanceHz = Int(raw), (1...160).contains(acceptanceHz) {
                    cognitiveHz = acceptanceHz
                } else {
                    cognitiveHz = 4
                }
                movementEnabled = movementFeatureEnabled
            } else {
                movementEnabled = preservedMovementEnabled
            }
            movementWasEverEnabledSinceReset = movementEnabled
            lastMovementOutcomes = []
            lastInfluencedTracesByAgentId.removeAll()
            credit = 0
            lastWorldTick = world.time
            focusedAgentId = resetSpeed ? "agent_0" : (preservedFocus ?? "agent_0")
            followMode = resetSpeed ? .off : preservedFollowMode
            demoActive = resetSpeed ? false : preservedDemoActive
            passiveObserverBootstrapComplete = false
            manualProductiveCommandsAfterBootstrap = 0
            mortalityMaterialExitAttempt = 0
            passiveSocietyAudit = PebbleAgentPassiveSocietyAudit()
            workDemandRefreshAudit = PebbleAgentWorkDemandRefreshAudit()
            lastTickResult = nil
            lastError = nil
            autoInteractionEnabled = false
            lastAutoInteractionReason = "none"
            lastInteractionAttempted = false
            lastInteractionSucceeded = false
            lastInteractionBlocked = false
            economyAutoEnabled = false
            lastEconomyReason = "none"
            lastDeliverySucceeded = false
            lastConsumptionSucceeded = false
            lastSurvivalReason = "none"
            lastNaturalReason = "none"
            lastConstructionReason = "none"
            lastEcologyReason = "none"
            lastForageOutcome = nil
            lastEcologyScanDiagnostics = PebbleAgentLocalEcologyScanDiagnostics()
            lastConstructionSiteDiagnostics = PebbleAgentConstructionSiteDiagnostics()
            replayRecorder = nil
            replayBaseCheckpointName = nil
            observedGoalKinds = [AgentGoalKind.idle.rawValue]
            resetRunCounters()
            if followTargetId() == nil { followMode = .off }
            let verb = resetSpeed ? "start" : "reset"
            let weather = world.raining ? (world.thundering ? "thunder" : "rain") : "clear"
            trace(
                "bootstrap publication status=verified cognitionPhysical=exact "
                    + "sessionAgents=\(candidateSession.snapshot().agentCount) "
                    + "worldProbes=\(stagedProbes.count) rollbackRequired=0"
            )
            trace("\(verb) seed=\(seed) agents=3 tick=0 hz=\(cognitiveHz) movement=\(movementEnabled ? "on" : "off") worldTick=\(world.time) dayTime=\(world.dayTime) weather=\(weather) randomTickSpeed=\(world.randomTickSpeed) mobSpawning=\(Int(world.gameRules["doMobSpawning"] ?? -1))")
            return success(resetSpeed ? "PebbleAgents started: 3 agents at 4 Hz." : "PebbleAgents reset to tick 0.")
        } catch let error as PebbleAgentBootstrapPlacementResolver.ResolutionError {
            let reason: String
            switch error {
            case let .insufficientSafePositions(
                found, required, candidates, maximumCandidates, rejections
            ):
                reason = "insufficient_safe_positions found=\(found) required=\(required) "
                    + "candidates=\(candidates)/\(maximumCandidates) "
                    + "rejections=\(rejections)"
            }
            trace(
                "bootstrap placement status=refused anchor=\(positionText(anchor)) "
                    + "reason=\(reason) session=none probes=0"
            )
            lastError = reason
            _ = stop(reason: "start refusal", fallbackWorld: world)
            return failure("PebbleAgents start refused: \(reason)")
        } catch {
            lastError = String(describing: error)
            _ = stop(reason: "start failure", fallbackWorld: world)
            trace("error \(error)")
            return failure("PebbleAgents start failed: \(error)")
        }
    }

    func initialAgentStates(
        positionsByAgentID: [String: AgentPosition]
    ) throws -> [AgentSessionAgentState] {
        let helperFatigue = cooperationFeatureEnabled ? 0 : 0.03
        let primaryFear = autonomousCivilizationFeatureEnabled ? 10 : 80
        let specifications: [(String, Int, Double, Double)] = [
            ("agent_0", primaryFear, 0, 0.2),
            ("agent_1", 10, helperFatigue, 0.2),
            ("agent_2", 10, 0, 0.9),
        ]
        return try specifications.map { id, fear, fatigue, curiosity in
            guard let position = positionsByAgentID[id] else {
                throw ControllerError.bootstrapPlacementBoundary(
                    "missing placement for \(id)"
                )
            }
            return AgentSessionAgentState(
                id: id,
                state: "idle",
                position: position,
                needs: AgentNeeds(hunger: 0, fatigue: fatigue, curiosity: curiosity, safety: 1),
                health: 100,
                fear: fear,
                homePosition: position,
                nearbyAgents: [],
                currentGoal: AgentGoal(kind: .idle, reason: "initial goal", startedAtTick: 0, urgency: 0),
                lastAction: nil,
                lastActionEffect: nil,
                memory: [],
                tickCreated: 0,
                ticksAlive: 0,
                observationCount: 0,
                nearbyObservationCount: 0,
                goalSelectionCount: 0,
                goalChangeCount: 0,
                actionCount: 0,
                actionEffectCount: 0,
                movementCount: 0,
                totalManhattanDistanceMoved: 0,
                returnHomeMoveCount: 0,
                totalDistanceReducedTowardHome: 0
            )
        }
    }

    func stageInitialProbes(
        for snapshot: AgentSessionSnapshot,
        in world: World
    ) throws -> [String: LabCoreAgentEntity] {
        var staged: [String: LabCoreAgentEntity] = [:]
        do {
            for agent in snapshot.agents.sorted(by: { $0.id < $1.id }) {
                let probe = try createProbe(for: agent, in: world)
                staged[agent.id] = probe
                if safeBootstrapLateFailureProofEnabled, staged.count == 2 {
                    throw ControllerError.bootstrapPlacementBoundary(
                        "injected late bootstrap failure"
                    )
                }
            }
            return staged
        } catch {
            try rollbackInitialProbes(
                staged.values.sorted { $0.labAgentId > $1.labAgentId },
                in: world,
                cause: error
            )
            throw error
        }
    }

    func verifyInitialBootstrap(
        session: AgentSimulationSession,
        probes: [String: LabCoreAgentEntity],
        world: World,
        player: Player
    ) throws {
        let snapshot = session.snapshot()
        let expectedIDs = snapshot.agents.map(\.id).sorted()
        let worldProbes = world.entities.compactMap { $0 as? LabCoreAgentEntity }
        let worldIDs = worldProbes.map(\.labAgentId).sorted()
        guard probes.keys.sorted() == expectedIDs, worldIDs == expectedIDs else {
            throw ControllerError.bootstrapPlacementBoundary(
                "probe identity mismatch expected=\(expectedIDs) actual=\(worldIDs)"
            )
        }
        for agent in snapshot.agents {
            guard let probe = probes[agent.id],
                  world.entityById[probe.id] === probe else {
                throw ControllerError.bootstrapPlacementBoundary(
                    "missing World indexes for \(agent.id)"
                )
            }
            let physicalPosition = AgentPosition(
                x: Int(probe.x.rounded(.down)),
                y: Int(probe.y.rounded(.down)),
                z: Int(probe.z.rounded(.down))
            )
            guard physicalPosition == agent.position,
                  agent.homePosition == agent.position else {
                throw ControllerError.bootstrapPlacementBoundary(
                    "cognition/physical mismatch for \(agent.id)"
                )
            }
            let assessment = assessEntityPlacement(
                in: world,
                at: EntityPlacementPosition(
                    x: physicalPosition.x,
                    y: physicalPosition.y,
                    z: physicalPosition.z
                ),
                bodyWidth: probe.width,
                bodyHeight: probe.height,
                ignoringEntityIDs: [probe.id]
            )
            guard assessment.isValid else {
                throw ControllerError.bootstrapPlacementBoundary(
                    "post-placement invalid \(agent.id):"
                        + assessment.rejections.map(\.rawValue).joined(separator: ",")
                )
            }
            guard hypot(probe.x - player.x, probe.z - player.z) >= 1.5 else {
                throw ControllerError.bootstrapPlacementBoundary(
                    "player separation invalid for \(agent.id)"
                )
            }
        }
    }

    func rollbackInitialProbes(
        _ probes: [LabCoreAgentEntity],
        in world: World,
        cause: Error
    ) throws {
        var removedIDs: [String] = []
        for probe in probes {
            guard removeLabCoreAgentProbe(probe, from: world) else {
                throw ControllerError.bootstrapRollbackBoundary(
                    "failed to remove \(probe.labAgentId) after \(cause)"
                )
            }
            removedIDs.append(probe.labAgentId)
        }
        let residual = world.entities.compactMap { entity -> String? in
            guard let probe = entity as? LabCoreAgentEntity,
                  removedIDs.contains(probe.labAgentId) else { return nil }
            return probe.labAgentId
        }.sorted()
        guard residual.isEmpty else {
            throw ControllerError.bootstrapRollbackBoundary(
                "residual probes after rollback: \(residual)"
            )
        }
        trace(
            "bootstrap rollback status=verified cause="
                + "\(String(describing: cause).replacingOccurrences(of: " ", with: "_")) "
                + "probesRemoved=\(removedIDs.count) session=none residual=0"
        )
    }

    func createProbes(in world: World) throws {
        guard let session else { throw ControllerError.missingSession }
        for agent in session.snapshot().agents {
            probesByAgentId[agent.id] = try createProbe(for: agent, in: world)
        }
        let ids = world.entities.compactMap { $0 as? LabCoreAgentEntity }.map(\.labAgentId).sorted()
        let expected = session.snapshot().agents.map(\.id).sorted()
        guard ids == expected, probesByAgentId.count == expected.count else {
            throw ControllerError.invalidProbeSet(ids)
        }
    }

    func createProbe(
        for agent: AgentSnapshot,
        in world: World
    ) throws -> LabCoreAgentEntity {
        guard probesByAgentId[agent.id] == nil,
              !world.entities.contains(where: {
                  ($0 as? LabCoreAgentEntity)?.labAgentId == agent.id
              }) else {
            throw ControllerError.invalidProbeSet(probesByAgentId.keys.sorted())
        }
        let placement = EntityPlacementPosition(
            x: agent.position.x,
            y: agent.position.y,
            z: agent.position.z
        )
        let assessment = assessEntityPlacement(
            in: world,
            at: placement,
            bodyWidth: 0.6,
            bodyHeight: 1.8
        )
        guard assessment.isValid else {
            throw ControllerError.bootstrapPlacementBoundary(
                "invalid physical creation position for \(agent.id):"
                    + assessment.rejections.map(\.rawValue).joined(separator: ",")
            )
        }
        let probe = LabCoreAgentEntity(
            world: world,
            labAgentId: agent.id,
            physicalId: "pebble_app_agent_\(agent.id)"
        )
        guard !probe.shouldSaveToChunk, !probe.persistent else {
            throw ControllerError.persistableProbe(agent.id)
        }
        probe.setPos(
            Double(agent.position.x) + 0.5,
            Double(agent.position.y),
            Double(agent.position.z) + 0.5
        )
        probe.prevX = probe.x
        probe.prevY = probe.y
        probe.prevZ = probe.z
        world.addEntity(probe)
        let publishedPosition = AgentPosition(
            x: Int(probe.x.rounded(.down)),
            y: Int(probe.y.rounded(.down)),
            z: Int(probe.z.rounded(.down))
        )
        guard world.entityById[probe.id] === probe,
              world.entities.filter({ $0 === probe }).count == 1,
              publishedPosition == agent.position else {
            guard removeLabCoreAgentProbe(probe, from: world) else {
                throw ControllerError.bootstrapRollbackBoundary(
                    "probe publication rollback failed for \(agent.id)"
                )
            }
            throw ControllerError.bootstrapPlacementBoundary(
                "probe publication verification failed for \(agent.id)"
            )
        }
        return probe
    }

    func prevalidateCheckpointProbeTarget(
        for agent: AgentSnapshot,
        in world: World,
        ignoringEntityIDs: Set<Int>
    ) throws {
        let assessment = assessEntityPlacement(
            in: world,
            at: EntityPlacementPosition(
                x: agent.position.x,
                y: agent.position.y,
                z: agent.position.z
            ),
            bodyWidth: 0.6,
            bodyHeight: 1.8,
            ignoringEntityIDs: ignoringEntityIDs
        )
        guard assessment.isValid else {
            throw ControllerError.bootstrapPlacementBoundary(
                "invalid checkpoint restore position for \(agent.id):"
                    + assessment.rejections.map(\.rawValue).joined(separator: ",")
            )
        }
    }

    func restoreCheckpointProbePosition(
        _ probe: LabCoreAgentEntity,
        for agent: AgentSnapshot,
        in world: World
    ) throws {
        guard probesByAgentId[agent.id] === probe,
              probe.labAgentId == agent.id,
              probe.world === world,
              !probe.dead,
              world.entities.filter({ $0 === probe }).count == 1,
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw ControllerError.bootstrapPlacementBoundary(
                "checkpoint probe is not safely repositionable for \(agent.id)"
            )
        }
        probe.setPos(
            Double(agent.position.x) + 0.5,
            Double(agent.position.y),
            Double(agent.position.z) + 0.5
        )
        probe.vx = 0
        probe.vy = 0
        probe.vz = 0
        probe.prevYaw = probe.yaw
        probe.prevPitch = probe.pitch
        let restored = try PebbleAgentEmbodiment.resolve(
            agentID: agent.id,
            in: world,
            mappedByAgentID: probesByAgentId
        )
        guard restored.position == agent.position,
              probe.prevX == probe.x,
              probe.prevY == probe.y,
              probe.prevZ == probe.z,
              probe.vx == 0, probe.vy == 0, probe.vz == 0,
              probe.prevYaw == probe.yaw,
              probe.prevPitch == probe.pitch,
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw ControllerError.bootstrapPlacementBoundary(
                "checkpoint probe position verification failed for \(agent.id)"
            )
        }
    }

    func resetRunCounters() {
        successfulCognitiveTicks = 0
        blockedMovementOutcomeCount = 0
        runtimeErrorCount = 0
        droppedCatchUpSteps = 0
        maxObservedMemoryCount = 0
        maxObservedDistanceFromHome = 0
        kinshipLateFailureProofInjected = false
        skillLateFailureProofInjected = false
        candidateMovementLateFailureProofInjected = false
        candidateRenewableLateFailureProofInjected = false
        candidateAgricultureNavigationFailureProofInjected = false
    }

    @discardableResult
    func stop(reason: String, fallbackWorld: World? = nil) -> Int {
        let snapshot = session?.snapshot()
        let causalSummary = session?.causalLedgerSnapshot().summary
        let socialSummary = session?.socialSummary()
        let physicalSummary = session?.physicalChannelSummary()
        let cooperationSummary = session?.cooperationSummary()
        let populationSummary = session?.populationSummary()
        let settlementSummary = session?.settlementMetricsSummary()
        let mortalitySummary = session?.mortalitySummary()
        let autonomousSummary = session?.autonomousActivitySnapshot()
        let followStatus = followMode.statusText
        let wasDemo = demoActive
        let cleanupWorld = activeWorld ?? fallbackWorld
        if let cleanupWorld,
           !cleanupPassiveSocietyFixture(world: cleanupWorld) {
            runtimeErrorCount += 1
            lastError = "passive society fixture cleanup failed; session retained"
            trace("error passive society fixture cleanup failed hardFailure=1")
            return 0
        }
        if let cleanupWorld,
           !cleanupMaterialRightsProofFixture(world: cleanupWorld) {
            runtimeErrorCount += 1
            lastError = "material-rights fixture cleanup failed; session retained"
            trace("error material-rights fixture cleanup failed hardFailure=1")
            return 0
        }
        if let cleanupWorld,
           !cleanupLivestockProofFixture(world: cleanupWorld) {
            runtimeErrorCount += 1
            lastError = "livestock fixture cleanup failed; session retained"
            trace("error livestock fixture cleanup failed hardFailure=1")
            return 0
        }
        if let cleanupWorld,
           !cleanupWildSubsistenceProofFixture(world: cleanupWorld) {
            runtimeErrorCount += 1
            lastError = "wild subsistence fixture cleanup failed; session retained"
            trace("error wild subsistence fixture cleanup failed hardFailure=1")
            return 0
        }
        if let cleanupWorld,
           !cleanupAgricultureProofFixture(world: cleanupWorld) {
            runtimeErrorCount += 1
            lastError = "agriculture fixture cleanup failed; session retained"
            trace("error agriculture fixture cleanup failed hardFailure=1")
            return 0
        }
        if let cleanupWorld,
           !cleanupEcologicalObservationProofFixture(world: cleanupWorld) {
            runtimeErrorCount += 1
            lastError = "ecological observation fixture cleanup failed; session retained"
            trace("error ecological observation fixture cleanup failed hardFailure=1")
            return 0
        }
        ecologicalObservationSensor.invalidateAll()
        let constructionBeforeCleanup = constructionExecutor.state
        let constructionRestored = cleanupWorld.map {
            constructionExecutor.cleanup(world: $0)
        } ?? (constructionBeforeCleanup.projectId == nil)
        guard constructionRestored else {
            runtimeErrorCount += 1
            lastError = "construction cleanup failed; session retained"
            trace("error construction cleanup failed reason=\(reason.replacingOccurrences(of: " ", with: "_")) hardFailure=1")
            return 0
        }
        let constructionAfterCleanup = constructionExecutor.state
        let interactionBeforeCleanup = interactionExecutor.state(gateEnabled: interactionFeatureEnabled)
        let interactionRestored = cleanupWorld.map { interactionExecutor.cleanup(world: $0) }
            ?? !interactionBeforeCleanup.active
        let interactionAfterCleanup = interactionExecutor.state(gateEnabled: interactionFeatureEnabled)
        if !interactionRestored {
            runtimeErrorCount += 1
            trace("error interaction cleanup failed reason=\(reason.replacingOccurrences(of: " ", with: "_"))")
        }
        let expectedProbeRemovals = cleanupWorld?.entities.compactMap {
            $0 as? LabCoreAgentEntity
        }.count ?? 0
        let removed = cleanupWorld.map { clearLabCoreAgentProbes(in: $0) } ?? 0
        guard removed == expectedProbeRemovals else {
            runtimeErrorCount += 1
            lastError = "physical custody cleanup failed; session retained"
            trace("error physical custody cleanup failed reason=\(reason.replacingOccurrences(of: " ", with: "_")) hardFailure=1")
            return 0
        }
        if let snapshot {
            let movementCount = snapshot.agents.reduce(0) { $0 + $1.movementCount }
            let retrieved = snapshot.agents.reduce(0) { $0 + $1.memoryRetrievalCount }
            let influenced = snapshot.agents.reduce(0) { $0 + $1.memoryInfluencedDecisionCount }
            let dedup = snapshot.agents.reduce(0) { $0 + $1.feedbackMemoryDeduplicatedCount }
            let natural = naturalResourceExecutor.state
            trace("summary reason=\(reason.replacingOccurrences(of: " ", with: "_")) seed=\(seed) ticks=\(successfulCognitiveTicks) hz=\(cognitiveHz) agents=\(snapshot.agentCount) movementCount=\(movementCount) blocked=\(blockedMovementOutcomeCount) memoryMax=\(maxObservedMemoryCount) retrieved=\(retrieved) influenced=\(influenced) dedup=\(dedup) maxDistanceHome=\(maxObservedDistanceFromHome) runtimeErrors=\(runtimeErrorCount) catchupDropped=\(droppedCatchUpSteps) probesRemoved=\(removed) follow=\(followStatus) demo=\(wasDemo ? 1 : 0) interactionRestored=\(interactionRestored ? 1 : 0) interactionTarget=\(interactionBeforeCleanup.target.map(positionText) ?? "none") natural=\(snapshot.naturalResourcesEnabled ? 1 : 0) naturalHarvests=\(natural.harvestCount) naturalRollbacks=\(natural.rollbackCount) naturalRestoredAfterSuccess=0 buildProject=\(snapshot.constructionProject?.projectId ?? "none") buildPlaced=\(snapshot.constructionProject?.placedCellIndices.count ?? 0) buildRestored=\(constructionAfterCleanup.cleanupRestoredBlockCount) buildRollback=\(constructionAfterCleanup.rollbackCount) constructionRestored=1 conservation=\(snapshot.conservation.harvestedTotal):\(snapshot.conservation.carriedTotal)+\(snapshot.conservation.campStockTotal)+\(snapshot.conservation.consumedTotal)+\(snapshot.conservation.constructionEscrowTotal)+\(snapshot.conservation.constructedTotal):\(snapshot.conservation.balanced ? "exact" : "diverged") causalSim=\(causalSummary?.simulationID.rawValue ?? "none") causalTick=\(causalSummary?.currentTick.rawValue ?? 0) causalSequence=\(causalSummary?.latestSequence ?? 0) causalEvents=\(causalSummary?.retainedEventCount ?? 0) causalDropped=\(causalSummary?.droppedEventCount ?? 0) corridorObserved=\(interactionAfterCleanup.corridorObservedBlockCount) corridorChangedCleanup=\(interactionAfterCleanup.corridorChangedAfterCleanup) cleanupRestoredBlocks=\(interactionAfterCleanup.cleanupRestoredBlockCount)")
            if let autonomy = autonomousSummary, autonomy.enabled {
                let completed = autonomy.recentRecords.filter {
                    $0.outcome.lifecycle == .completed
                }
                let completedByAgent = Dictionary(grouping: completed) {
                    $0.activity.candidate.actorID.rawValue
                }
                let domains = Set(completed.map {
                    $0.activity.candidate.domain.rawValue
                }).sorted().joined(separator: ",")
                let chained = completedByAgent.filter { $0.value.count >= 2 }
                    .keys.sorted().joined(separator: ",")
                let counters = autonomy.counters
                trace(
                    "autonomous summary bootstrap=\(passiveObserverBootstrapComplete ? 1 : 0) "
                        + "manualProductive=\(manualProductiveCommandsAfterBootstrap) "
                        + "decisions=\(counters.decisionCount) candidates=\(counters.candidateCount) "
                        + "starts=\(counters.startCount) completed=\(counters.completionCount) "
                        + "blocked=\(counters.blockCount) switches=\(counters.switchCount) "
                        + "completedAgents=\(completedByAgent.count) "
                        + "domains=\(domains.isEmpty ? "none" : domains) "
                        + "chainedAgents=\(chained.isEmpty ? "none" : chained) "
                        + "active=\(autonomy.activeActivities.count) "
                        + "retained=\(autonomy.recentRecords.count) evicted=\(autonomy.evictionCount) "
                        + "idleLongest=\(counters.longestIdleTicks) "
                        + passiveSocietyAuditSummary()
                )
            }
            if let socialSummary, socialSummary.socialCausalEventCount > 0 {
                trace("social summary enabled=\(socialSummary.enabled ? 1 : 0) messages=\(socialSummary.retainedMessageCount) unverified=\(socialSummary.unverifiedBeliefCount) confirmed=\(socialSummary.confirmedBeliefCount) contradicted=\(socialSummary.contradictedBeliefCount) expired=\(socialSummary.expiredBeliefCount) trustEdges=\(socialSummary.trustEdgeCount) events=\(socialSummary.socialCausalEventCount) digest=\(socialSummary.digest)")
            }
            if let physicalSummary, physicalSummary.physicalCausalEventCount > 0 {
                trace("physical summary enabled=\(physicalSummary.enabled ? 1 : 0) signals=\(physicalSummary.retainedSignalCount) pending=\(physicalSummary.pendingSignalCount) exact=\(physicalSummary.exactCount) ambiguous=\(physicalSummary.ambiguousCount) missed=\(physicalSummary.missedCount) inconclusive=\(physicalSummary.inconclusiveCount) decoded=\(physicalSummary.decodedMessageCount) expired=\(physicalSummary.expiredCount) events=\(physicalSummary.physicalCausalEventCount) digest=\(physicalSummary.digest)")
            }
            if let cooperationSummary, cooperationSummary.cooperationCausalEventCount > 0 {
                trace("cooperation summary enabled=\(cooperationSummary.enabled ? 1 : 0) tasks=\(cooperationSummary.taskCount) offered=\(cooperationSummary.offeredCount) accepted=\(cooperationSummary.acceptedCount) active=\(cooperationSummary.activeCount) completed=\(cooperationSummary.completedCount) declined=\(cooperationSummary.declinedCount) expired=\(cooperationSummary.expiredCount) cancelled=\(cooperationSummary.cancelledCount) failed=\(cooperationSummary.failedCount) relations=\(cooperationSummary.relationCount) events=\(cooperationSummary.cooperationCausalEventCount) digest=\(cooperationSummary.digest)")
            }
            if let populationSummary, populationSummary.populationCausalEventCount > 0 {
                trace("population summary enabled=\(populationSummary.enabled ? 1 : 0) settlement=\(populationSummary.settlementID?.rawValue ?? "none") members=\(populationSummary.memberCount)/\(populationSummary.capacity) founders=\(populationSummary.founderCount) residents=\(populationSummary.residentCount) migrating=\(populationSummary.migratingCount) active=\(populationSummary.activeMigrationCount) arrived=\(populationSummary.arrivedMigrationCount) rejected=\(populationSummary.rejectedMigrationCount) failed=\(populationSummary.failedMigrationCount) nextOrdinal=\(populationSummary.nextPopulationOrdinal ?? -1) events=\(populationSummary.populationCausalEventCount) digest=\(populationSummary.digest)")
            }
            if let settlementSummary, settlementSummary.enabled {
                trace(
                    "settlement summary enabled=1 settlement=\(settlementSummary.settlementID?.rawValue ?? "none") "
                        + "microTick=\(settlementSummary.microTick) "
                        + "macroInterval=\(settlementSummary.macroIntervalTicks ?? 0) "
                        + "macroSequence=\(settlementSummary.macroSequence) "
                        + "lastPulse=\(settlementSummary.lastPulseTick ?? -1) "
                        + "nextPulse=\(settlementSummary.nextPulseTick ?? -1) "
                        + "frames=\(settlementSummary.retainedFrameCount) "
                        + "evicted=\(settlementSummary.evictedFrameCount) "
                        + "condition=\(settlementSummary.condition?.rawValue ?? "none") "
                        + "population=\(settlementSummary.population)/\(settlementSummary.capacity) "
                        + "urgent=\(settlementSummary.urgent) migrating=\(settlementSummary.migrating) "
                        + "engaged=\(settlementSummary.engaged) stable=\(settlementSummary.stable) "
                        + "movementDelta=\(settlementSummary.movementDelta) "
                        + "materialDelta=\(settlementSummary.materialActivityDelta) "
                        + "socialDelta=\(settlementSummary.socialActivityDelta) "
                        + "cooperationDelta=\(settlementSummary.cooperationActivityDelta) "
                        + "coverage=\(settlementSummary.causalCoverageComplete == true ? "complete" : "incomplete") "
                        + "digest=\(settlementSummary.digest)"
                )
            }
            if let mortalitySummary, mortalitySummary.enabled {
                trace(
                    "mortality summary enabled=1 active=\(mortalitySummary.activeAgentCount) "
                        + "deaths=\(mortalitySummary.totalDeathCount) "
                        + "retained=\(mortalitySummary.retainedDeathCount) "
                        + "evicted=\(mortalitySummary.evictedDeathCount) "
                        + "latest=\(mortalitySummary.latestDeathID?.rawValue ?? "none") "
                        + "victim=\(mortalitySummary.latestAgentID?.rawValue ?? "none") "
                        + "deathTick=\(mortalitySummary.latestDeathTick ?? -1) "
                        + "terminal=\(mortalitySummary.unrecoveredTotal) "
                        + "events=\(mortalitySummary.mortalityEventCount) "
                        + "digest=\(mortalitySummary.digest)"
                )
            }
        }
        interactionExecutor.clearBoundaryAudit()
        naturalResourceExecutor.resetDiagnostics()
        materialCustodyGateway.reset()
        session = nil
        activeWorld = nil
        probesByAgentId.removeAll()
        isPaused = false
        credit = 0
        lastWorldTick = nil
        anchor = nil
        focusedAgentId = nil
        lastTickResult = nil
        movementEnabled = false
        movementWasEverEnabledSinceReset = false
        lastMovementOutcomes = []
        lastInfluencedTracesByAgentId.removeAll()
        observedGoalKinds.removeAll()
        overlayModeByCommand = nil
        observerUIState = PebbleObserverUIState()
        followMode = .off
        demoActive = false
        passiveObserverBootstrapComplete = false
        manualProductiveCommandsAfterBootstrap = 0
        mortalityMaterialExitAttempt = 0
        passiveSocietyFixture = nil
        passiveSocietyAudit = PebbleAgentPassiveSocietyAudit()
        workDemandRefreshAudit = PebbleAgentWorkDemandRefreshAudit()
        rightsProofFixture = nil
        autoInteractionEnabled = false
        lastAutoInteractionReason = "none"
        lastInteractionAttempted = false
        lastInteractionSucceeded = false
        lastInteractionBlocked = false
        economyAutoEnabled = false
        lastEconomyReason = "none"
        lastDeliverySucceeded = false
        lastConsumptionSucceeded = false
        lastSurvivalReason = "none"
        lastNaturalReason = "none"
        lastConstructionReason = "none"
        lastEcologyReason = "none"
        lastForageOutcome = nil
        lastEcologyScanDiagnostics = PebbleAgentLocalEcologyScanDiagnostics()
        lastConstructionSiteDiagnostics = PebbleAgentConstructionSiteDiagnostics()
        replayRecorder = nil
        replayBaseCheckpointName = nil
        worldReceiptAttemptSerial = 0
        lastError = nil
        trace("stop probesRemoved=\(removed) reason=\(reason)")
        return removed
    }
}
