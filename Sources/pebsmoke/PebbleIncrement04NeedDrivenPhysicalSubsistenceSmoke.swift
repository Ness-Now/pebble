import Foundation
import PebbleAgents
import PebbleCore

private let increment04Origin = AgentPosition(x: 0, y: 64, z: 0)
private let increment04Lifecycle = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 8,
    maturityAgeTicks: 24,
    reproductionEvaluationIntervalTicks: 1,
    reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1,
    maximumRetainedBirthRecords: 64,
    maximumRetainedPlanRecords: 64,
    maximumParentBirthCount: 16
)

private func increment04Agent(
    _ id: String = "agent_0",
    hunger: Double,
    goal: AgentGoalKind = .idle
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: id,
        state: "idle",
        position: increment04Origin,
        needs: AgentNeeds(hunger: hunger, fatigue: 0, curiosity: 0, safety: 1),
        health: 100,
        fear: 0,
        homePosition: increment04Origin,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: goal,
            reason: "increment 04 focused fixture",
            startedAtTick: 0,
            urgency: 0
        ),
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

private func increment04Session(
    _ id: String,
    hunger: Double,
    goal: AgentGoalKind = .idle,
    survival: AgentSurvivalConfiguration = .live
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival
        ),
        agents: [increment04Agent(hunger: hunger, goal: goal)],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: increment04Origin,
        receptionPosition: increment04Origin
    )
    try! session.setLifecycleEnabled(true, configuration: increment04Lifecycle)
    try! session.setSkillsEnabled(true)
    try! session.setEcologicalObservationEnabled(true)
    try! session.setWildSubsistenceEnabled(true)
    session.setSurvivalEnabled(true)
    try! session.setPhysicalFoodSurvivalEnabled(true)
    try! session.setAutonomousActivityEnabled(true)
    return session
}

private func increment04Evidence(
    material: String = "sweet_berries",
    fingerprint: String = "source-fingerprint-stage-3"
) -> AgentObservedEdibleSourceEvidence {
    AgentObservedEdibleSourceEvidence(
        canonicalMaterialName: material,
        physicalSourceFingerprint: fingerprint
    )
}

private func increment04Observation(
    _ session: AgentSimulationSession,
    observerID: String = "agent_0",
    origin: AgentPosition = increment04Origin,
    target: AgentPosition = AgentPosition(x: 1, y: 64, z: 0),
    evidence: AgentObservedEdibleSourceEvidence? = increment04Evidence(),
    completion: AgentEcologicalScanCompletion = .complete,
    expiresAtTick: Int? = nil,
    plantKey: String = "sweet_berry_bush"
) -> AgentEcologicalObservation {
    let configuration = session.ecologicalObservationSnapshot().configuration!
    return AgentEcologicalObservation(
        observerID: AgentID(rawValue: observerID)!,
        origin: origin,
        worldContextKey: "world-seed-46",
        dimensionKey: "overworld",
        observedAtSimulationTick: session.tick,
        physicalWorldTick: 120,
        civilDate: session.civilDate()!,
        biome: AgentBiomeObservation(
            biomeKey: "taiga",
            position: origin
        ),
        water: [],
        soils: [],
        crops: [],
        plants: [AgentPlantObservation(
            plantKey: plantKey,
            position: target,
            renewability: .conditional,
            edibleSourceEvidence: evidence
        )],
        animals: [],
        fishing: [],
        weather: AgentWeatherObservation(
            kind: .clear,
            raining: false,
            thundering: false
        ),
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: 120,
            dayTime: 120,
            timeOfDay: .day,
            daylightCycleEnabled: true
        ),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: configuration.radius,
            cellsConsidered: 405,
            worldReads: 405,
            chunksTouched: 1,
            chunksUnavailable: completion == .chunkUnavailable ? 1 : 0,
            entitiesConsidered: 0,
            resultsEmitted: 4,
            cacheHits: 0,
            cacheMisses: 1,
            completion: completion
        ),
        expiresAtSimulationTick: expiresAtTick
            ?? session.tick + configuration.dynamicFreshnessTicks
    )
}

private func increment04Decision(
    _ actorID: AgentID = AgentID(rawValue: "agent_0")!
) -> AgentSubsistenceDecisionContext {
    AgentSubsistenceDecisionContext(
        actorID: actorID,
        fishingRodAvailable: false,
        huntingWeaponAvailable: false,
        agricultureAvailable: false,
        maximumDistance: 16,
        subsistencePressure: 40,
        requiredEdibleMaterialName: "sweet_berries"
    )
}

private func increment04ReadyWorld(seed: UInt32 = 46) -> World {
    let world = World(dim: .overworld, seed: seed)
    let chunk = Chunk(cx: 0, cz: 0, minY: world.info.minY, height: world.info.height)
    chunk.status = .lit
    world.setChunk(chunk)
    return world
}

private struct Increment04BreakEvidence: Equatable {
    let digest: String
    let finalCell: Int
    let material: String
    let quantity: Int
    let entityCount: Int
    let outerRestored: Bool
}

private func increment04StableDigest(_ values: [String]) -> String {
    var digest: UInt64 = 1_469_598_103_934_665_603
    for byte in values.joined(separator: "|").utf8 {
        digest ^= UInt64(byte)
        digest &*= 1_099_511_628_211
    }
    return String(format: "%016llx", digest)
}

private func increment04ScopedBerryBreak(
    cameraChunkX: Int,
    cameraChunkZ: Int,
    cameraVisitedFarFirst: Bool,
    outerPerturbations: Int
) -> Increment04BreakEvidence {
    resetEntityIds(400)
    let world = increment04ReadyWorld()
    world.time = 320
    if cameraVisitedFarFirst {
        world.simCenterX = 32
        world.simCenterZ = 32
    }
    world.simCenterX = cameraChunkX
    world.simCenterZ = cameraChunkZ
    world.setBlock(1, 64, 1, Int(cell(B.sweet_berry_bush, 3)), SET_SILENT)
    gameRng = RandomX(0x1234_5678)
    for _ in 0..<outerPerturbations { _ = gameRng.next() }
    let outerBefore = gameRng
    let result = world.withDirectPhysicalActionRandomness(
        operationDomain: 0x5042_4741,
        x: 1,
        y: 64,
        z: 1,
        stableAttemptID: "focused-direct-berry"
    ) {
        executeBlockBreak(
            BlockBreakRuleContext(
                world: world,
                heldItem: nil,
                isCreative: false,
                itemEntityBobOffsetRandom: { gameRng.nextFloat() }
            ),
            1,
            64,
            1
        )
    }
    let entities = world.entities.compactMap { $0 as? ItemEntity }
        .filter { result.spawnedItemEntityIDs.contains($0.id) }
        .sorted { $0.id < $1.id }
    let material = entities.first.map { itemDef($0.stack.id).name } ?? "none"
    let quantity = entities.reduce(0) { $0 + $1.stack.count }
    let entityDigest = entities.map { entity in
        [
            String(entity.id),
            itemDef(entity.stack.id).name,
            String(entity.stack.count),
            String(entity.x.bitPattern),
            String(entity.y.bitPattern),
            String(entity.z.bitPattern),
            String(entity.vx.bitPattern),
            String(entity.vy.bitPattern),
            String(entity.vz.bitPattern),
            String(entity.bobOffset.bitPattern),
        ].joined(separator: ":")
    }.joined(separator: ",")
    let fields = [
        "cell=\(result.originalCell)->\(result.finalCell)",
        "ids=\(result.spawnedItemEntityIDs.map(String.init).joined(separator: ","))",
        "entities=\(entityDigest)",
    ]
    return Increment04BreakEvidence(
        digest: increment04StableDigest(fields),
        finalCell: result.finalCell,
        material: material,
        quantity: quantity,
        entityCount: entities.count,
        outerRestored: gameRng == outerBefore
    )
}

private func runIncrement04NeedCausality() {
    section("PS01 Increment 04 need causality")

    let live = AgentSurvivalConfiguration.live
    var below = increment04Session(
        "increment04-below-hunger",
        hunger: live.hungryThreshold.nextDown
    )
    _ = try! below.recordEcologicalObservation(increment04Observation(below))
    let belowBytes = try! below.durableStateBytes()
    check(
        "below meaningful hunger does not authorize physical food acquisition",
        !below.needsPhysicalFoodAcquisition(for: AgentID(rawValue: "agent_0")!)
            && below.wildSubsistenceSnapshot().opportunities.isEmpty
            && below.autonomousActivitySnapshot().activeActivities.isEmpty
            && (try! below.durableStateBytes()) == belowBytes
    )

    var threshold = increment04Session(
        "increment04-threshold-hunger",
        hunger: live.hungryThreshold
    )
    _ = try! threshold.recordEcologicalObservation(increment04Observation(threshold))
    let eligible = try! threshold.eligibleSubsistenceStrategies(increment04Decision())
    let selected = try! threshold.selectWildSubsistenceOpportunity(increment04Decision())
    check(
        "authoritative hunger threshold authorizes fresh berry evidence",
        threshold.configuration.survivalConfiguration.hungryThreshold
            == live.hungryThreshold
            && threshold.needsPhysicalFoodAcquisition(
                for: AgentID(rawValue: "agent_0")!
            )
            && eligible.map(\.strategy) == [.wildGathering]
            && selected.edibleSourceEvidence == increment04Evidence()
    )
    check(
        "selected opportunity records hunger as motive and neutral provenance",
        selected.reason.contains("hunger need pressure=")
            && selected.reason.contains("sweet_berries")
            && !selected.reason.contains("1-3")
            && !selected.reason.contains("sourceCell")
    )

    let customSurvival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.03,
        fatiguePerTick: 0.04,
        hungryThreshold: 0.43,
        criticalHungerThreshold: 0.79,
        hungerRecoveryThreshold: 0.17,
        fatigueThreshold: 0.66,
        fatigueRecoveryThreshold: 0.21,
        foodNutrition: 0.2,
        restRecoveryPerTick: 0.1,
        starvationGraceTicks: 3,
        starvationDamagePerTick: 9
    )
    let committed = increment04Session(
        "increment04-recovery-committed",
        hunger: customSurvival.hungerRecoveryThreshold.nextUp,
        goal: .satisfyHunger,
        survival: customSurvival
    )
    let recovered = increment04Session(
        "increment04-recovery-complete",
        hunger: customSurvival.hungerRecoveryThreshold,
        goal: .satisfyHunger,
        survival: customSurvival
    )
    check(
        "hunger recovery hysteresis comes from the session configuration",
        committed.configuration.survivalConfiguration == customSurvival
            && committed.needsPhysicalFoodAcquisition(
                for: AgentID(rawValue: "agent_0")!
            )
            && !recovered.needsPhysicalFoodAcquisition(
                for: AgentID(rawValue: "agent_0")!
            )
    )
}

private func runIncrement04Qualification() {
    section("PS01 Increment 04 food qualification")

    func qualification(_ stage: Int) -> [EdibleBlockBreakDropQualification] {
        edibleBlockBreakDropQualifications(
            for: Int(cell(B.sweet_berry_bush, stage)),
            heldItem: nil
        )
    }
    check("sweet berry stage 0 is not food-qualified", qualification(0).isEmpty)
    check("sweet berry stage 1 is not food-qualified", qualification(1).isEmpty)
    check(
        "sweet berry stage 2 is physically food-qualified",
        qualification(2).map(\.canonicalMaterialName) == ["sweet_berries"]
    )
    check(
        "sweet berry stage 3 is physically food-qualified",
        qualification(3).map(\.canonicalMaterialName) == ["sweet_berries"]
    )
    check(
        "unrelated gatherable block is not food-qualified",
        edibleBlockBreakDropQualifications(
            for: Int(cell(B.pumpkin)), heldItem: nil
        ).isEmpty
    )

    var noMature = increment04Session("increment04-no-mature", hunger: 0.8)
    _ = try! noMature.recordEcologicalObservation(increment04Observation(
        noMature,
        evidence: nil,
        plantKey: "fern"
    ))
    check(
        "complete bounded observation without mature berry has no food candidate",
        (try! noMature.eligibleSubsistenceStrategies(
            increment04Decision()
        )).isEmpty
    )

    var immature = increment04Session("increment04-immature-only", hunger: 0.8)
    _ = try! immature.recordEcologicalObservation(increment04Observation(
        immature,
        evidence: nil,
        plantKey: "sweet_berry_bush"
    ))
    check(
        "immature berry observation has no food candidate",
        (try! immature.eligibleSubsistenceStrategies(
            increment04Decision()
        )).isEmpty
    )

    var outside = increment04Session("increment04-outside-bound", hunger: 0.8)
    _ = try! outside.recordEcologicalObservation(increment04Observation(
        outside,
        target: AgentPosition(x: 17, y: 64, z: 0)
    ))
    check(
        "qualified berry outside the decision bound has no food candidate",
        (try! outside.eligibleSubsistenceStrategies(
            increment04Decision()
        )).isEmpty
    )

    var expired = increment04Session("increment04-expired", hunger: 0.8)
    _ = try! expired.recordEcologicalObservation(increment04Observation(
        expired,
        expiresAtTick: expired.tick
    ))
    _ = try! expired.advanceTick()
    check(
        "expired edible evidence cannot select an opportunity",
        (try! expired.eligibleSubsistenceStrategies(increment04Decision())).isEmpty
    )

    let evidence = increment04Evidence()
    let encoded = try! JSONEncoder().encode(evidence)
    let encodedText = String(decoding: encoded, as: UTF8.self)
    check(
        "cognitive edible evidence contains no Core numeric identity or yield",
        encodedText.contains("sweet_berries")
            && encodedText.contains("physicalSourceFingerprint")
            && !encodedText.contains("sourceCell")
            && !encodedText.contains("blockID")
            && !encodedText.contains("itemID")
            && !encodedText.contains("countMin")
            && !encodedText.contains("countMax")
            && !encodedText.contains("hungerPoints")
            && !encodedText.contains("saturation")
    )
}

private func runIncrement04DirectActionRandomness() {
    section("PS01 Increment 04 direct physical-action RNG")

    let near = increment04ScopedBerryBreak(
        cameraChunkX: 0,
        cameraChunkZ: 0,
        cameraVisitedFarFirst: false,
        outerPerturbations: 0
    )
    let far = increment04ScopedBerryBreak(
        cameraChunkX: 32,
        cameraChunkZ: 32,
        cameraVisitedFarFirst: false,
        outerPerturbations: 0
    )
    let returned = increment04ScopedBerryBreak(
        cameraChunkX: 0,
        cameraChunkZ: 0,
        cameraVisitedFarFirst: true,
        outerPerturbations: 0
    )
    let perturbed = increment04ScopedBerryBreak(
        cameraChunkX: 0,
        cameraChunkZ: 0,
        cameraVisitedFarFirst: false,
        outerPerturbations: 37
    )
    check(
        "scoped canonical berry break produces real bounded physical food",
        near.finalCell == 0
            && near.material == "sweet_berries"
            && (1...3).contains(near.quantity)
            && near.entityCount == 1
    )
    check(
        "near far returned and perturbed outer RNG have one exact action digest",
        Set([near.digest, far.digest, returned.digest, perturbed.digest]).count == 1,
        "near=\(near.digest) far=\(far.digest) returned=\(returned.digest) perturbed=\(perturbed.digest)"
    )
    check(
        "successful scoped actions restore unrelated outer RNG",
        near.outerRestored && far.outerRestored
            && returned.outerRestored && perturbed.outerRestored
    )

    let refusedWorld = increment04ReadyWorld()
    refusedWorld.time = 320
    gameRng = RandomX(0x9988_7766)
    let refusedBefore = gameRng
    let refused = refusedWorld.withDirectPhysicalActionRandomness(
        operationDomain: 0x5042_4741,
        x: 1,
        y: 64,
        z: 1,
        stableAttemptID: "focused-direct-refusal"
    ) {
        executeBlockBreak(
            BlockBreakRuleContext(
                world: refusedWorld,
                heldItem: nil,
                isCreative: false,
                itemEntityBobOffsetRandom: { gameRng.nextFloat() }
            ),
            1,
            64,
            1
        )
    }
    check(
        "refused scoped action restores outer RNG",
        refused.status == .noTarget && gameRng == refusedBefore
    )

    resetEntityIds(700)
    let legacyWorld = increment04ReadyWorld()
    legacyWorld.setBlock(1, 64, 1, Int(cell(B.sweet_berry_bush, 3)), SET_SILENT)
    gameRng = RandomX(0x0bad_cafe)
    var expectedLegacyRNG = gameRng
    _ = expectedLegacyRNG.nextInt(3)
    _ = expectedLegacyRNG.nextFloat()
    _ = expectedLegacyRNG.nextFloat()
    let legacy = executeBlockBreak(
        BlockBreakRuleContext(
            world: legacyWorld,
            heldItem: nil,
            isCreative: false
        ),
        1,
        64,
        1
    )
    check(
        "legacy player-style break retains global sequential RNG semantics",
        legacy.status == .succeeded && gameRng == expectedLegacyRNG
    )

    print(
        "  direct-action-digests near=\(near.digest) far=\(far.digest) "
            + "returned=\(returned.digest) perturbed=\(perturbed.digest) "
            + "quantity=\(near.quantity)"
    )
}

private func increment04PopulationSession(
    count: Int = 20
) -> AgentSimulationSession {
    let agents = (0..<count).map { index in
        increment04Agent(
            "agent_\(index)",
            hunger: 0.8
        )
    }
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46,
            memoryPolicy: .bounded(maxEntries: 256),
            survivalConfiguration: .live
        ),
        agents: agents,
        simulationID: AgentSimulationID(rawValue: "increment04-capacity")!,
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: increment04Origin,
        receptionPosition: increment04Origin,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 30
        )
    )
    try! session.setLifecycleEnabled(true, configuration: increment04Lifecycle)
    try! session.setSkillsEnabled(true)
    try! session.setEcologicalObservationEnabled(true)
    try! session.setWildSubsistenceEnabled(true)
    session.setSurvivalEnabled(true)
    try! session.setPhysicalFoodSurvivalEnabled(true)
    try! session.setAutonomousActivityEnabled(true)
    return session
}

private func increment04Decision(
    actor: String,
    pressure: Int = 80
) -> AgentSubsistenceDecisionContext {
    AgentSubsistenceDecisionContext(
        actorID: AgentID(rawValue: actor)!,
        fishingRodAvailable: false,
        huntingWeaponAvailable: false,
        agricultureAvailable: false,
        maximumDistance: 16,
        subsistencePressure: pressure,
        requiredEdibleMaterialName: "sweet_berries"
    )
}

private func runIncrement04CapacityContentionAndScarcity() {
    section("PS01 Increment 04 contention, capacity, and scarcity")

    var contention = increment04PopulationSession(count: 2)
    let shared = AgentPosition(x: 1, y: 64, z: 0)
    for index in 0..<2 {
        let id = "agent_\(index)"
        _ = try! contention.recordEcologicalObservation(
            increment04Observation(
                contention,
                observerID: id,
                origin: increment04Origin,
                target: shared,
                evidence: increment04Evidence(
                    fingerprint: "shared-stage-3"
                )
            )
        )
    }
    let winner = try! contention.selectWildSubsistenceOpportunity(
        increment04Decision(actor: "agent_0")
    )
    let contenderRefused: Bool
    do {
        _ = try contention.selectWildSubsistenceOpportunity(
            increment04Decision(actor: "agent_1")
        )
        contenderRefused = false
    } catch AgentSessionError.wildSubsistence(.noEligibleStrategy) {
        contenderRefused = true
    } catch {
        contenderRefused = false
    }
    check(
        "one observed physical source has one cognitive mutation contender",
        winner.targetKey == "plant:sweet_berry_bush@1,64,0"
            && contenderRefused
            && contention.wildSubsistenceSnapshot().opportunities.count == 1
    )

    var capacity = increment04PopulationSession()
    for index in 0..<20 {
        let id = "agent_\(index)"
        let origin = AgentPosition(x: index * 8, y: 64, z: 0)
        let target = AgentPosition(x: index * 8 + 1, y: 64, z: 0)
        _ = try! capacity.recordEcologicalObservation(
            increment04Observation(
                capacity,
                observerID: id,
                origin: origin,
                target: target,
                evidence: increment04Evidence(
                    fingerprint: "stage-3-source-\(index)"
                )
            )
        )
    }
    var admission: [String] = []
    for index in 0..<16 {
        let id = "agent_\(index)"
        _ = try! capacity.selectWildSubsistenceOpportunity(
            increment04Decision(actor: id, pressure: 100 - index)
        )
        admission.append(id)
    }
    let deferred: Bool
    do {
        _ = try capacity.selectWildSubsistenceOpportunity(
            increment04Decision(actor: "agent_16", pressure: 40)
        )
        deferred = false
    } catch AgentSessionError.wildSubsistence(.opportunityCapacityReached) {
        deferred = true
    } catch {
        deferred = false
    }
    let first = capacity.wildSubsistenceSnapshot().opportunities.first {
        $0.actorID.rawValue == "agent_0" && $0.status == .selected
    }!
    _ = try! capacity.recordWildSubsistenceOutcome(
        AgentSubsistenceOutcome(
            attemptID: AgentSubsistenceAttemptID(
                rawValue: "capacity-release-agent-0"
            )!,
            opportunityID: first.opportunityID,
            actorID: first.actorID,
            strategy: first.strategy,
            targetKey: first.targetKey,
            targetPosition: first.lastObservedPosition,
            sourceObservationEventID: first.sourceObservationEventID,
            status: .failed,
            attribution: "focused-capacity-slot-release",
            completedAtTick: capacity.tick
        )
    )
    let reused = try! capacity.selectWildSubsistenceOpportunity(
        increment04Decision(actor: "agent_16", pressure: 40)
    )
    let active = capacity.wildSubsistenceSnapshot().opportunities.filter {
        $0.status == .selected
    }
    check(
        "sixteen-opportunity saturation is bounded and nonfatal",
        capacity.wildSubsistenceSnapshot().configuration?
            .maximumActiveOpportunities == 16
            && deferred
            && active.count == 16
            && admission == (0..<16).map { "agent_\($0)" }
    )
    check(
        "a released slot admits a previously deferred founder",
        reused.actorID.rawValue == "agent_16"
            && active.contains { $0.actorID.rawValue == "agent_16" }
            && !active.contains { $0.actorID.rawValue == "agent_0" }
    )

    var scarcity = increment04Session("increment04-scarcity", hunger: 0.8)
    _ = try! scarcity.recordEcologicalObservation(
        increment04Observation(
            scarcity,
            evidence: nil,
            completion: .chunkUnavailable,
            plantKey: "sweet_berry_bush"
        )
    )
    let unavailableRecord = scarcity.ecologicalObservations(
        for: AgentID(rawValue: "agent_0")!
    ).first
    check(
        "coverage-unavailable observation is retained as incomplete, not absence",
        unavailableRecord?.observation.diagnostics.completion
            == .chunkUnavailable
            && (try! scarcity.eligibleSubsistenceStrategies(
                increment04Decision()
            )).isEmpty
            && scarcity.causalLedgerSnapshot().events.contains {
                $0.kind == .ecologicalObservationRecorded
            }
    )
}

private func runIncrement04CheckpointAndReplayBoundaries() {
    section("PS01 Increment 04 checkpoint and replay boundaries")

    func exactRestore(_ session: AgentSimulationSession) -> Bool {
        guard let checkpoint = try? session.makeCheckpoint(),
              let restored = try? AgentSimulationSession.restoring(checkpoint),
              let before = try? session.durableStateBytes(),
              let after = try? restored.durableStateBytes() else { return false }
        return before == after
            && checkpoint.semanticDigest
                == (try? restored.makeCheckpoint().semanticDigest)
    }

    var beforeOpportunity = increment04Session(
        "increment04-checkpoint-before-opportunity",
        hunger: 0.8
    )
    _ = try! beforeOpportunity.recordEcologicalObservation(
        increment04Observation(beforeOpportunity)
    )
    check(
        "checkpoint is exact before an eligible opportunity",
        exactRestore(beforeOpportunity)
    )

    var afterSelection = beforeOpportunity
    let opportunity = try! afterSelection.selectWildSubsistenceOpportunity(
        increment04Decision()
    )
    check(
        "checkpoint is exact after opportunity selection",
        exactRestore(afterSelection)
    )

    var afterAcquisition = afterSelection
    let acquired = AgentMaterialStackSnapshot(
        identity: AgentMaterialIdentitySnapshot(
            itemKey: "sweet_berries",
            damage: 0,
            enchantments: [],
            label: nil,
            canonicalDataJSON: "{}"
        ),
        count: 3
    )
    _ = try! afterAcquisition.recordWildSubsistenceOutcome(
        AgentSubsistenceOutcome(
            attemptID: AgentSubsistenceAttemptID(
                rawValue: "checkpoint-acquisition"
            )!,
            opportunityID: opportunity.opportunityID,
            actorID: opportunity.actorID,
            strategy: opportunity.strategy,
            targetKey: opportunity.targetKey,
            targetPosition: opportunity.lastObservedPosition,
            sourceObservationEventID: opportunity.sourceObservationEventID,
            status: .succeeded,
            physicalCausalIDs: [901],
            acquiredItems: [acquired],
            custodyFingerprint: "agent-carried:sweet-berries:3",
            attribution: "core-canonical-block-break",
            completedAtTick: afterAcquisition.tick
        )
    )
    check(
        "checkpoint is exact after verified acquisition publication",
        exactRestore(afterAcquisition)
    )

    var afterConsumption = afterAcquisition
    let intent = try! afterConsumption.nextPhysicalFoodConsumptionIntent(
        for: AgentID(rawValue: "agent_0")!
    )
    let hungerBefore = try! afterConsumption.state(
        for: AgentID(rawValue: "agent_0")!
    ).needs.hunger
    try! afterConsumption.applyValidatedPhysicalFoodConsumption(
        AgentValidatedPhysicalFoodConsumptionOutcome(
            consumptionID: intent.consumptionID,
            consumptionSequence: intent.consumptionSequence,
            agentID: intent.agentID,
            tick: intent.tick,
            canonicalMaterialName: "sweet_berries",
            quantityConsumed: 1,
            coreHungerPoints: 2,
            coreSaturation: 0.4,
            normalizedHungerReduction: 0.1,
            status: .succeeded,
            physicalReceiptID: intent.consumptionID,
            sourceKind: .agentCarriedInventory,
            sourceSlot: 0,
            hungerBefore: hungerBefore,
            hungerAfter: hungerBefore - 0.1
        )
    )
    check(
        "checkpoint is exact after physical consumption publication",
        exactRestore(afterConsumption)
            && afterConsumption.physicalFoodSurvivalSnapshot()?
                .totalConsumedQuantity == 1
    )

    let freshnessCheckpoint = try! beforeOpportunity.makeCheckpoint()
    var freshnessRestored = try! AgentSimulationSession.restoring(
        freshnessCheckpoint
    )
    let freshness = freshnessRestored.ecologicalObservationSnapshot()
        .configuration!.dynamicFreshnessTicks
    for _ in 0...freshness { _ = try! freshnessRestored.advanceTick() }
    check(
        "restored dynamic edible evidence expires at the durable tick boundary",
        (try! freshnessRestored.eligibleSubsistenceStrategies(
            increment04Decision()
        )).isEmpty
    )

    var replayBase = increment04Session(
        "increment04-replay",
        hunger: 0.8
    )
    let replayCheckpoint = try! replayBase.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayCheckpoint,
        session: replayBase
    )
    let observation = increment04Observation(replayBase)
    _ = try! recorder.apply(
        .recordEcologicalObservation(observation),
        to: &replayBase
    )
    _ = try! recorder.apply(
        .selectWildSubsistenceOpportunity(increment04Decision()),
        to: &replayBase
    )
    let replayOpportunity = replayBase.wildSubsistenceSnapshot()
        .opportunities.last!
    let replayOutcome = AgentSubsistenceOutcome(
        attemptID: AgentSubsistenceAttemptID(rawValue: "replay-acquisition")!,
        opportunityID: replayOpportunity.opportunityID,
        actorID: replayOpportunity.actorID,
        strategy: replayOpportunity.strategy,
        targetKey: replayOpportunity.targetKey,
        targetPosition: replayOpportunity.lastObservedPosition,
        sourceObservationEventID: replayOpportunity.sourceObservationEventID,
        status: .succeeded,
        physicalCausalIDs: [902],
        acquiredItems: [acquired],
        custodyFingerprint: "replay-agent-carried:sweet-berries:3",
        attribution: "core-canonical-block-break",
        completedAtTick: replayBase.tick
    )
    _ = try! recorder.apply(
        .recordWildSubsistenceOutcome(replayOutcome),
        to: &replayBase
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "increment04-replay")!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: replayCheckpoint,
        journal: journal
    )
    check(
        "neutral edible evidence and acquisition replay byte exactly",
        replay.report.verified
            && (try! replay.session.durableStateBytes())
                == (try! replayBase.durableStateBytes())
    )

    let batchBase = increment04Session(
        "increment04-observation-batch-replay",
        hunger: 0.8
    )
    let batchBindings = [
        AgentEcologicalObservationReceiptBinding(
            observation: increment04Observation(batchBase),
            physicalReceiptID: AgentPhysicalObservationReceiptID(
                rawValue: "increment04-batch-receipt-a"
            )!
        ),
        AgentEcologicalObservationReceiptBinding(
            observation: increment04Observation(
                batchBase,
                target: AgentPosition(x: 2, y: 64, z: 0),
                evidence: increment04Evidence(
                    fingerprint: "source-fingerprint-stage-3-b"
                )
            ),
            physicalReceiptID: AgentPhysicalObservationReceiptID(
                rawValue: "increment04-batch-receipt-b"
            )!
        ),
    ]
    var sequentialBatch = batchBase
    for binding in batchBindings {
        _ = try! sequentialBatch.recordEcologicalObservation(
            binding.observation,
            physicalReceiptID: binding.physicalReceiptID
        )
    }
    var atomicBatch = batchBase
    let atomicRecords = try! atomicBatch.recordEcologicalObservations(
        batchBindings
    )
    check(
        "batched ecological publication preserves sequential durable semantics",
        atomicRecords.count == batchBindings.count
            && (try! atomicBatch.durableStateBytes())
                == (try! sequentialBatch.durableStateBytes())
    )

    let batchCheckpoint = try! batchBase.makeCheckpoint()
    var batchRecorder = try! AgentReplayRecorder(
        checkpoint: batchCheckpoint,
        session: batchBase
    )
    var replayedBatchSource = batchBase
    _ = try! batchRecorder.apply(
        .recordEcologicalObservationBatchWithPhysicalReceipts(batchBindings),
        to: &replayedBatchSource
    )
    let batchJournal = try! batchRecorder.journal(
        named: AgentCheckpointName(rawValue: "increment04-batch-replay")!
    )
    let batchReplay = try! AgentSessionReplayer.replay(
        checkpoint: batchCheckpoint,
        journal: batchJournal
    )
    check(
        "batched ecological replay retains each receipt and replays byte exactly",
        batchJournal.records.count == 1
            && batchReplay.report.verified
            && (try! batchReplay.session.durableStateBytes())
                == (try! replayedBatchSource.durableStateBytes())
            && (try! replayedBatchSource.durableStateBytes())
                == (try! atomicBatch.durableStateBytes())
    )
}

private func runIncrement04ObserverProjection() {
    section("PS01 Increment 04 read-only Observer projection")

    var session = increment04Session(
        "increment04-observer",
        hunger: 0.8
    )
    _ = try! session.recordEcologicalObservation(
        increment04Observation(session)
    )
    let opportunity = try! session.selectWildSubsistenceOpportunity(
        increment04Decision()
    )
    _ = try! session.selectAutonomousActivities([
        AgentAutonomousActivityCandidate(
            candidateID: "increment04-observer-gather",
            actorID: opportunity.actorID,
            domain: .wildGathering,
            actionKey: "gather",
            stableReference: opportunity.opportunityID.rawValue,
            target: opportunity.lastObservedPosition,
            logicalTargetKey: opportunity.targetKey,
            physicalTarget: opportunity.lastObservedPosition,
            approachPosition: increment04Origin,
            materialFingerprint: opportunity.edibleSourceEvidence!
                .physicalSourceFingerprint,
            source: .need,
            priorityBand: 8,
            urgency: 80,
            distance: 1,
            observedAtTick: session.tick
        ),
    ])
    let worldNear = try! AgentObserverWorldBinding(
        worldID: "increment04-observer-world",
        storageIdentity: "increment04-observer-storage",
        seed: 46,
        dimension: 0,
        observedWorldTick: 120
    )
    let worldFar = try! AgentObserverWorldBinding(
        worldID: "increment04-observer-world",
        storageIdentity: "increment04-observer-storage",
        seed: 46,
        dimension: 0,
        observedWorldTick: 121
    )
    let bytesBefore = try! session.durableStateBytes()
    let activeBefore = session.autonomousActivitySnapshot().activeActivities
    let near = session.observerSnapshot(worldBinding: worldNear)
    let far = session.observerSnapshot(worldBinding: worldFar)
    let bytesAfter = try! session.durableStateBytes()
    let activeAfter = session.autonomousActivitySnapshot().activeActivities
    let projection = near.individual(opportunity.actorID)!
    let data = Dictionary(
        uniqueKeysWithValues: projection.activity.reason.presentationData.map {
            ($0.key, $0.value)
        }
    )
    check(
        "Observer projects hunger-selected edible target and provenance",
        projection.activity.action == "gather"
            && data["selectionReason"] == opportunity.reason
            && data["target"] == opportunity.targetKey
            && data["edibleMaterial"] == "sweet_berries"
            && data["sourceEvidence"]
                == opportunity.edibleSourceEvidence?.physicalSourceFingerprint
    )
    check(
        "Observer and changed World-view binding cannot feed back into selection",
        bytesBefore == bytesAfter
            && activeBefore == activeAfter
            && near.individual(opportunity.actorID)?.activity
                == far.individual(opportunity.actorID)?.activity
            && near.header.worldBinding.observedWorldTick
                != far.header.worldBinding.observedWorldTick
    )
}

func runPebbleIncrement04FocusedSmoke() {
    runIncrement04NeedCausality()
    runIncrement04Qualification()
    runIncrement04DirectActionRandomness()
    runIncrement04CapacityContentionAndScarcity()
    runIncrement04CheckpointAndReplayBoundaries()
    runIncrement04ObserverProjection()
}
