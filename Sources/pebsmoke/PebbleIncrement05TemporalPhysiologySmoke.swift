import Foundation
@_spi(Testing) import PebbleAgents
import PebbleCore

private func temporalPhysiologyAgent(
    hunger: Double = 0,
    fatigue: Double = 0,
    goal: AgentGoalKind = .idle,
    lastActionName: String? = nil
) -> AgentSessionAgentState {
    let position = AgentPosition(x: 0, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "temporal_agent", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: hunger, fatigue: fatigue, curiosity: 0, safety: 1
        ),
        health: 100, fear: 0, homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: goal, reason: "temporal fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: lastActionName.map {
            AgentAction(name: $0, reason: "temporal fixture", tick: 0)
        },
        lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0
    )
}

private func temporalRestSession() -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.01,
        fatiguePerTick: AgentSurvivalConfiguration.live.fatiguePerTick,
        hungryThreshold: AgentSurvivalConfiguration.live.hungryThreshold,
        criticalHungerThreshold:
            AgentSurvivalConfiguration.live.criticalHungerThreshold,
        hungerRecoveryThreshold:
            AgentSurvivalConfiguration.live.hungerRecoveryThreshold,
        fatigueThreshold: AgentSurvivalConfiguration.live.fatigueThreshold,
        fatigueRecoveryThreshold:
            AgentSurvivalConfiguration.live.fatigueRecoveryThreshold,
        foodNutrition: AgentSurvivalConfiguration.live.foodNutrition,
        restRecoveryPerTick:
            AgentSurvivalConfiguration.live.restRecoveryPerTick,
        starvationGraceTicks:
            AgentSurvivalConfiguration.live.starvationGraceTicks,
        starvationDamagePerTick:
            AgentSurvivalConfiguration.live.starvationDamagePerTick
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 5,
            memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: survival
        ),
        agents: [temporalPhysiologyAgent(
            fatigue: 0.66, goal: .rest, lastActionName: "rest"
        )]
    )
    session.setSurvivalEnabled(true)
    try! session.rebasePhysiologicalTime(toWorldTick: 0)
    return session
}

private func runTemporalRestFrequency(_ hz: Int) -> AgentSimulationSession {
    var session = temporalRestSession()
    var credit = 0
    for worldTick in 1...1_200 {
        try! session.advancePhysiologicalTime(toWorldTick: worldTick)
        credit += hz
        while credit >= 20 {
            _ = try! session.advanceTick()
            credit -= 20
        }
    }
    return session
}

private func temporalPhysiologySession() -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 5,
            memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [temporalPhysiologyAgent()]
    )
    session.setSurvivalEnabled(true)
    try! session.rebasePhysiologicalTime(toWorldTick: 0)
    return session
}

private func temporalFounderSession() -> AgentSimulationSession {
    let population = try! AgentPopulationConfiguration(
        maximumActivePopulation: 3
    )
    let specification = try! AgentFounderSpecification(
        count: 1,
        populationConfiguration: population
    )
    let position = AgentPosition(x: 0, y: 64, z: 0)
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 5,
            memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: try! specification.initialStates(
            positionsByAgentID: ["agent_0": position]
        ),
        simulationID: AgentSimulationID(
            validating: "increment-05-temporal-founder"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 512)
    )
    try! session.initializeFounderAuthorities(
        specification: specification,
        settlementAnchor: position,
        receptionPosition: AgentPosition(x: -2, y: 64, z: 0),
        populationConfiguration: population,
        householdConfiguration: try! AgentHouseholdConfiguration(
            maximumHouseholdTransitionsPerTick: 3
        )
    )
    try! session.rebasePhysiologicalTime(toWorldTick: 0)
    return session
}

private struct TemporalPhysiologyEvidence: Equatable {
    let hunger: Double
    let fatigue: Double
    let health: Int
    let physiological: AgentPhysiologicalTimeState
}

private func temporalEvidence(
    _ session: AgentSimulationSession
) -> TemporalPhysiologyEvidence {
    let agent = try! session.state(for: "temporal_agent")
    return TemporalPhysiologyEvidence(
        hunger: agent.needs.hunger,
        fatigue: agent.needs.fatigue,
        health: agent.health,
        physiological: session.physiologicalTimeSnapshot()
    )
}

private func runTemporalFrequency(_ hz: Int) -> AgentSimulationSession {
    var session = temporalPhysiologySession()
    var credit = 0
    for worldTick in 1...1_200 {
        try! session.advancePhysiologicalTime(toWorldTick: worldTick)
        credit += hz
        while credit >= 20 {
            _ = try! session.advanceTick()
            credit -= 20
        }
    }
    return session
}

private func advanceTemporal(
    _ session: inout AgentSimulationSession,
    deltas: [Int]
) {
    var worldTick = session.physiologicalTimeSnapshot()
        .lastReconciledWorldTick ?? 0
    for delta in deltas {
        worldTick += delta
        try! session.advancePhysiologicalTime(toWorldTick: worldTick)
    }
}

private func advanceTemporalBoundaries(
    _ session: inout AgentSimulationSession,
    count: Int
) {
    for _ in 0..<count {
        let current = session.physiologicalTimeSnapshot()
            .lastReconciledWorldTick ?? 0
        try! session.advancePhysiologicalTime(
            toWorldTick: current
                + AgentPhysiologicalTimeConfiguration.live.boundaryWorldTicks
        )
        _ = try! session.advanceTick()
    }
}

private func temporalReplayName(_ value: String) -> AgentCheckpointName {
    AgentCheckpointName(rawValue: value)!
}

private func removingTemporalWorldTickKey(_ value: Any) -> Any {
    if let dictionary = value as? [String: Any] {
        return Dictionary(uniqueKeysWithValues: dictionary.compactMap {
            key, nested in
            key == "physiologicalWorldTick" ? nil
                : (key, removingTemporalWorldTickKey(nested))
        })
    }
    if let array = value as? [Any] {
        return array.map(removingTemporalWorldTickKey)
    }
    return value
}

private func replayTick(
    _ session: inout AgentSimulationSession,
    recorder: inout AgentReplayRecorder,
    worldTick: Int?
) -> AgentSessionTickResult {
    try! recorder.apply(
        .advanceTick(
            physiologicalWorldTick: worldTick,
            perceptions: [],
            physicalObservations: []
        ),
        to: &session
    ).tickResult!
}

private func verifyTemporalReplay(
    checkpoint: AgentSessionCheckpoint,
    recorder: AgentReplayRecorder,
    live: AgentSimulationSession,
    name: String
) -> (AgentReplayJournal, AgentReplayResult) {
    let journal = try! recorder.journal(named: temporalReplayName(name))
    let result = try! AgentSessionReplayer.replay(
        checkpoint: checkpoint,
        journal: journal
    )
    check(
        "\(name) replay converges exactly",
        result.report.verified
            && (try! result.session.durableStateBytes())
                == (try! live.durableStateBytes())
    )
    return (journal, result)
}

private struct TemporalFrequencyReplayEvidence {
    let live: AgentSimulationSession
    let journal: AgentReplayJournal
}

private struct TemporalFailedFrequencyEvidence {
    let evidence: TemporalPhysiologyEvidence
    let tick: Int
    let recordCount: Int
    let replayVerified: Bool
    let containsOnlyPhysiologicalRecords: Bool
}

@inline(never)
private func replayTemporalFailedAttempts(
    _ hz: Int,
    name: String
) -> TemporalFailedFrequencyEvidence {
    var live = temporalPhysiologySession()
    let checkpoint = try! live.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: checkpoint,
        session: live
    )
    let attempts = hz * 60
    for attempt in 1...attempts {
        let worldTick = attempt * 1_200 / attempts
        try! recorder.apply(
            .reconcilePhysiologicalTime(
                mode: .advanceAndApplyEligibleBiology,
                worldTick: worldTick
            ),
            to: &live
        )
    }
    let (journal, replay) = verifyTemporalReplay(
        checkpoint: checkpoint,
        recorder: recorder,
        live: live,
        name: name
    )
    return TemporalFailedFrequencyEvidence(
        evidence: temporalEvidence(live),
        tick: live.tick,
        recordCount: journal.records.count,
        replayVerified: replay.report.verified,
        containsOnlyPhysiologicalRecords: journal.records.allSatisfy {
            $0.operationKind == .physiologicalTime
        }
    )
}

private func replayTemporalFrequency(
    _ hz: Int,
    name: String
) -> TemporalFrequencyReplayEvidence {
    var live = temporalPhysiologySession()
    let checkpoint = try! live.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: checkpoint,
        session: live
    )
    let cognitiveTicks = hz * 60
    for step in 1...cognitiveTicks {
        let worldTick = step * 1_200 / cognitiveTicks
        _ = replayTick(
            &live,
            recorder: &recorder,
            worldTick: worldTick
        )
    }
    let (journal, _) = verifyTemporalReplay(
        checkpoint: checkpoint,
        recorder: recorder,
        live: live,
        name: name
    )
    return TemporalFrequencyReplayEvidence(live: live, journal: journal)
}

private func temporalPhysicalFoodSession() -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 5,
            memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: [temporalPhysiologyAgent(hunger: 0.8)],
        simulationID: AgentSimulationID(
            validating: "increment-05-temporal-food"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 512)
    )
    session.setSurvivalEnabled(true)
    try! session.setPhysicalFoodSurvivalEnabled(true)
    try! session.rebasePhysiologicalTime(toWorldTick: 0)
    return session
}

private func temporalBerryOutcome(
    _ session: AgentSimulationSession
) -> AgentValidatedPhysicalFoodConsumptionOutcome {
    let agentID = AgentID(rawValue: "temporal_agent")!
    let actor = try! session.state(for: agentID)
    let intent = try! session.nextPhysicalFoodConsumptionIntent(for: agentID)
    return AgentValidatedPhysicalFoodConsumptionOutcome(
        consumptionID: intent.consumptionID,
        consumptionSequence: intent.consumptionSequence,
        agentID: agentID,
        tick: session.tick,
        canonicalMaterialName: "sweet_berries",
        quantityConsumed: 1,
        coreHungerPoints: 2,
        coreSaturation: 0.4,
        normalizedHungerReduction: 0.1,
        status: .succeeded,
        physicalReceiptID: intent.consumptionID,
        sourceKind: .agentCarriedInventory,
        sourceSlot: 0,
        hungerBefore: actor.needs.hunger,
        hungerAfter: actor.needs.hunger - 0.1
    )
}

private func temporalMortalityAgent(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: 1, fatigue: 1, curiosity: 0, safety: 1
        ),
        health: 1, fear: 0, homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "temporal mortality fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress()
    )
}

private func temporalMortalitySession() -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 5,
            memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: (0..<3).map(temporalMortalityAgent),
        simulationID: AgentSimulationID(
            validating: "increment-05-temporal-mortality"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 2_048)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! session.setMortalityEnabled(true)
    try! session.setLifecycleEnabled(true)
    try! session.setHomeostasisEnabled(
        true,
        configuration: try! AgentHomeostasisConfiguration(
            baseHealthDamagePerTick: 25
        )
    )
    try! session.rebasePhysiologicalTime(toWorldTick: 0)
    return session
}

private func temporalLegacySession() -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 5,
            memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [temporalPhysiologyAgent()],
        simulationID: AgentSimulationID(
            validating: "increment-05-temporal-legacy"
        )
    )
    session.setSurvivalEnabled(true)
    try! session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.currentVersion
    )
    return session
}

@inline(never)
private func runTemporalShallowAdvanceTickStackProof() {
    var session = temporalPhysiologySession()
    var stackSentinel = 0
    let stackAddressBefore = withUnsafePointer(to: &stackSentinel) {
        UInt(bitPattern: $0)
    }
    for step in 1...512 {
        try! session.advancePhysiologicalTime(toWorldTick: step * 5)
        _ = try! session.advanceTick()
    }
    let stackAddressAfter = withUnsafePointer(to: &stackSentinel) {
        UInt(bitPattern: $0)
    }
    let physiological = session.physiologicalTimeSnapshot()
    check(
        "shallow transactional advanceTick returns every frame",
        session.tick == 512
            && stackAddressAfter == stackAddressBefore
            && physiological.totalElapsedWorldTicks == 2_560
            && physiological.appliedBoundaryCount == 2
            && physiological.remainderWorldTicks == 160
            && temporalEvidence(session).hunger == 0.10
            && temporalEvidence(session).fatigue == 0.12
    )
}

@inline(never)
private func runTemporalThresholdAndRestProof() {
    var thresholdSession = temporalPhysiologySession()
    advanceTemporalBoundaries(&thresholdSession, count: 7)
    let preHungry = try! thresholdSession.state(for: "temporal_agent")
    advanceTemporalBoundaries(&thresholdSession, count: 1)
    let hungry = try! thresholdSession.state(for: "temporal_agent")
    advanceTemporalBoundaries(&thresholdSession, count: 7)
    let preCritical = try! thresholdSession.state(for: "temporal_agent")
    advanceTemporalBoundaries(&thresholdSession, count: 1)
    let criticalGraceOne = try! thresholdSession.state(
        for: "temporal_agent"
    )
    advanceTemporalBoundaries(&thresholdSession, count: 1)
    let criticalGraceTwo = try! thresholdSession.state(
        for: "temporal_agent"
    )
    advanceTemporalBoundaries(&thresholdSession, count: 1)
    let starvationDamage = try! thresholdSession.state(
        for: "temporal_agent"
    )
    check(
        "hunger thresholds use World-derived boundaries",
        preHungry.needs.hunger == 0.35
            && preHungry.survivalProgress?.status == .stable
            && hungry.needs.hunger == 0.40
            && hungry.survivalProgress?.status == .hungry
            && preCritical.needs.hunger == 0.75
            && preCritical.survivalProgress?.status == .hungry
            && criticalGraceOne.needs.hunger == 0.80
            && criticalGraceOne.survivalProgress?.status == .starving
    )
    check(
        "starvation grace and damage occur once per due boundary",
        criticalGraceOne.survivalProgress?
            .consecutiveCriticalHungerTicks == 1
            && criticalGraceOne.health == 100
            && criticalGraceTwo.survivalProgress?
                .consecutiveCriticalHungerTicks == 2
            && criticalGraceTwo.health == 100
            && starvationDamage.survivalProgress?
                .consecutiveCriticalHungerTicks == 3
            && starvationDamage.survivalProgress?
                .starvationDamageTaken == 10
            && starvationDamage.health == 90
    )

    let restRates = [1, 2, 4, 8].map(runTemporalRestFrequency)
    let restStates = restRates.map {
        try! $0.state(for: "temporal_agent")
    }
    check(
        "rest recovery is invariant at 1/2/4/8 Hz",
        Set(restStates.map { $0.needs.fatigue }) == [0]
            && Set(restStates.map {
                $0.survivalProgress?.restTicks ?? -1
            }) == [1]
            && restRates.map(\.tick) == [60, 120, 240, 480]
    )
    var restNoWorld = temporalRestSession()
    for _ in 0..<32 { _ = try! restNoWorld.advanceTick() }
    let restNoWorldState = try! restNoWorld.state(for: "temporal_agent")
    check(
        "cognitive rest grants no recovery without World time",
        restNoWorldState.needs.fatigue == 0.66
            && restNoWorldState.survivalProgress?.restTicks == 0
    )
}

@inline(never)
private func runTemporalCheckpointMatrixProof() {
    let checkpointZero = temporalPhysiologySession()
    var checkpointMinusOne = temporalPhysiologySession()
    try! checkpointMinusOne.advancePhysiologicalTime(
        toWorldTick: 1_199
    )
    var checkpointExact = temporalPhysiologySession()
    try! checkpointExact.advancePhysiologicalTime(toWorldTick: 1_200)
    var checkpointAfter = temporalPhysiologySession()
    try! checkpointAfter.advancePhysiologicalTime(toWorldTick: 1_200)
    _ = try! checkpointAfter.advanceTick()
    try! checkpointAfter.advancePhysiologicalTime(toWorldTick: 1_201)
    let checkpointBoundaryCases: [
        (String, AgentSimulationSession, Int)
    ] = [
        ("zero", checkpointZero, 1_200),
        ("minus-one", checkpointMinusOne, 1_200),
        ("exact", checkpointExact, 1_200),
        ("plus-one", checkpointAfter, 2_400),
    ]
    var checkpointBoundaryConverged = true
    for (_, base, targetWorldTick) in checkpointBoundaryCases {
        var live = base
        var replayed = try! AgentSimulationSession.restoring(
            base.makeCheckpoint()
        )
        let currentWorldTick = live.physiologicalTimeSnapshot()
            .lastReconciledWorldTick ?? 0
        if targetWorldTick > currentWorldTick {
            try! live.advancePhysiologicalTime(
                toWorldTick: targetWorldTick
            )
            try! replayed.advancePhysiologicalTime(
                toWorldTick: targetWorldTick
            )
        }
        _ = try! live.advanceTick()
        _ = try! replayed.advanceTick()
        checkpointBoundaryConverged = checkpointBoundaryConverged
            && (try! live.durableStateBytes())
                == (try! replayed.durableStateBytes())
    }
    check(
        "checkpoint matrix converges at zero, boundary -1, exact, and +1",
        checkpointBoundaryConverged
            && checkpointMinusOne.physiologicalTimeSnapshot()
                .remainderWorldTicks == 1_199
            && checkpointExact.physiologicalTimeSnapshot()
                .pendingBoundaryCount == 1
            && checkpointAfter.physiologicalTimeSnapshot()
                .remainderWorldTicks == 1
    )

    var survivalCheckpointMatrixConverged = true
    for boundaryCount in [8, 16, 17, 18] {
        var base = temporalPhysiologySession()
        advanceTemporalBoundaries(&base, count: boundaryCount)
        var live = base
        var replayed = try! AgentSimulationSession.restoring(
            base.makeCheckpoint()
        )
        advanceTemporalBoundaries(&live, count: 1)
        advanceTemporalBoundaries(&replayed, count: 1)
        survivalCheckpointMatrixConverged =
            survivalCheckpointMatrixConverged
                && (try! live.durableStateBytes())
                    == (try! replayed.durableStateBytes())
    }
    check(
        "hungry critical grace and damage checkpoints converge",
        survivalCheckpointMatrixConverged
    )
}

@inline(never)
private func runTemporalFailedCandidateReplayProof() {
    let frequencies = [1, 2, 4, 8].map {
        replayTemporalFailedAttempts(
            $0,
            name: "temporal-failed-\($0)hz"
        )
    }
    let evidence = frequencies.map(\.evidence)
    check(
        "failed cognition preserves 1/2/4/8 Hz physiology",
        Set(evidence.map(\.hunger)) == [0.05]
            && Set(evidence.map(\.fatigue)) == [0.06]
            && Set(evidence.map { $0.physiological.appliedBoundaryCount })
                == [1]
            && Set(evidence.map { $0.physiological.remainderWorldTicks })
                == [0]
            && frequencies.map(\.tick) == [0, 0, 0, 0]
            && frequencies.allSatisfy(\.replayVerified)
    )
    check(
        "failed cognition replay is bounded by scheduled attempts",
        frequencies.map(\.recordCount)
            == [60, 120, 240, 480]
            && frequencies.allSatisfy(\.containsOnlyPhysiologicalRecords)
    )

    let partitionSchedules = [
        Array(repeating: 5, count: 240),
        Array(repeating: 10, count: 120),
        Array(repeating: 20, count: 60),
    ]
    let partitions = partitionSchedules.enumerated().map {
        index, deltas -> AgentSimulationSession in
        var live = temporalPhysiologySession()
        let checkpoint = try! live.makeCheckpoint()
        var recorder = try! AgentReplayRecorder(
            checkpoint: checkpoint,
            session: live
        )
        var worldTick = 0
        for delta in deltas {
            worldTick += delta
            try! recorder.apply(
                .reconcilePhysiologicalTime(
                    mode: .advanceAndApplyEligibleBiology,
                    worldTick: worldTick
                ),
                to: &live
            )
        }
        _ = verifyTemporalReplay(
            checkpoint: checkpoint,
            recorder: recorder,
            live: live,
            name: "temporal-failed-partition-\(index)"
        )
        return live
    }
    check(
        "failed-attempt temporal partition converges exactly",
        (try! partitions[0].durableStateBytes())
            == (try! partitions[1].durableStateBytes())
            && (try! partitions[1].durableStateBytes())
                == (try! partitions[2].durableStateBytes())
    )

    var checkpointLive = temporalPhysiologySession()
    let checkpointBase = try! checkpointLive.makeCheckpoint()
    var checkpointRecorder = try! AgentReplayRecorder(
        checkpoint: checkpointBase,
        session: checkpointLive
    )
    for worldTick in stride(from: 5, through: 1_195, by: 5) {
        try! checkpointRecorder.apply(
            .reconcilePhysiologicalTime(
                mode: .advanceAndApplyEligibleBiology,
                worldTick: worldTick
            ),
            to: &checkpointLive
        )
    }
    try! checkpointRecorder.apply(
        .reconcilePhysiologicalTime(
            mode: .advanceAndApplyEligibleBiology,
            worldTick: 1_199
        ),
        to: &checkpointLive
    )
    let stalledCheckpoint = try! checkpointLive.makeCheckpoint()
    var restored = try! AgentSimulationSession.restoring(stalledCheckpoint)
    let directOperation = AgentReplayOperation.reconcilePhysiologicalTime(
        mode: .advanceAndApplyEligibleBiology,
        worldTick: 1_200
    )
    _ = try! checkpointLive.applyReplayOperation(directOperation)
    _ = try! restored.applyReplayOperation(directOperation)
    check(
        "schema 45 checkpoint during failed-cognition stall preserves temporal remainder",
        stalledCheckpoint.schemaVersion
            == AgentCheckpointSchema.pathReadinessLivenessVersion
            && (try! checkpointLive.durableStateBytes())
                == (try! restored.durableStateBytes())
            && checkpointLive.tick == 0
            && temporalEvidence(checkpointLive).hunger == 0.05
    )

    var food = temporalPhysicalFoodSession()
    try! food.applyValidatedPhysicalFoodConsumption(
        temporalBerryOutcome(food)
    )
    _ = try! food.applyReplayOperation(
        .reconcilePhysiologicalTime(
            mode: .advanceAndApplyEligibleBiology,
            worldTick: 1_200
        )
    )
    check(
        "published physical food precedes failed-cognition passive hunger",
        food.tick == 0
            && (try! food.state(for: "temporal_agent")).needs.hunger
                == 0.75
            && food.physicalFoodSurvivalSnapshot()?
                .totalConsumedQuantity == 1
    )

    var rest = temporalRestSession()
    _ = try! rest.applyReplayOperation(
        .reconcilePhysiologicalTime(
            mode: .advanceAndApplyEligibleBiology,
            worldTick: 1_200
        )
    )
    let rested = try! rest.state(for: "temporal_agent")
    check(
        "already-published rest recovers during failed cognition",
        rest.tick == 0
            && rested.needs.fatigue == 0
            && rested.survivalProgress?.restTicks == 1
    )

    var mortality = temporalMortalitySession()
    let mortalityCheckpoint = try! mortality.makeCheckpoint()
    var mortalityRecorder = try! AgentReplayRecorder(
        checkpoint: mortalityCheckpoint,
        session: mortality
    )
    try! mortalityRecorder.apply(
        .reconcilePhysiologicalTime(
            mode: .advanceAndApplyEligibleBiology,
            worldTick: 3_600
        ),
        to: &mortality
    )
    let (_, mortalityReplay) = verifyTemporalReplay(
        checkpoint: mortalityCheckpoint,
        recorder: mortalityRecorder,
        live: mortality,
        name: "temporal-failed-mortality"
    )
    check(
        "failed-cognition temporal mortality is exact and cognitive-free",
        mortality.tick == 0
            && mortality.snapshot().agents.isEmpty
            && mortality.mortalitySnapshot().totalDeathCount == 3
            && mortalityReplay.session.snapshot().agents.isEmpty
            && mortalityReplay.session.mortalitySnapshot()
                .totalDeathCount == 3
    )
}

/// Kept at a real function boundary from the already-large original temporal
/// suite so debug builds do not reserve both independent proof aggregates on
/// one stack at the same time.
@inline(never)
func runPebbleIncrement05TemporalRollbackSmoke() {
    section("PS01 Increment 05 rollback-time physiology focused")
    runTemporalFailedCandidateReplayProof()
}

func runPebbleIncrement05TemporalPhysiologySmoke() {
    section("PS01 Increment 05 temporal physiology focused")

    runTemporalShallowAdvanceTickStackProof()

    var copyOriginal = temporalPhysiologySession()
    var copyMutated = copyOriginal
    try! copyMutated.advancePhysiologicalTime(toWorldTick: 1_199)
    check(
        "temporal session copy mutation leaves original independent",
        copyOriginal.physiologicalTimeSnapshot().totalElapsedWorldTicks == 0
            && copyOriginal.physiologicalTimeSnapshot()
                .remainderWorldTicks == 0
            && copyMutated.physiologicalTimeSnapshot()
                .totalElapsedWorldTicks == 1_199
            && copyMutated.physiologicalTimeSnapshot()
                .remainderWorldTicks == 1_199
    )
    try! copyOriginal.advancePhysiologicalTime(toWorldTick: 600)
    check(
        "temporal session original mutation leaves copy independent",
        copyOriginal.physiologicalTimeSnapshot().totalElapsedWorldTicks == 600
            && copyOriginal.physiologicalTimeSnapshot()
                .remainderWorldTicks == 600
            && copyMutated.physiologicalTimeSnapshot()
                .totalElapsedWorldTicks == 1_199
            && copyMutated.physiologicalTimeSnapshot()
                .remainderWorldTicks == 1_199
    )
    let copyOriginalBytesA = try! copyOriginal.durableStateBytes()
    let copyOriginalBytesB = try! copyOriginal.durableStateBytes()
    let copyRoundTrip = try! AgentSimulationSession.restoring(
        copyOriginal.makeCheckpoint()
    )
    check(
        "temporal state has canonical durable value representation",
        copyOriginalBytesA == copyOriginalBytesB
            && copyRoundTrip.physiologicalTimeSnapshot()
                == copyOriginal.physiologicalTimeSnapshot()
            && (try! copyRoundTrip.durableStateDigest())
                == (try! copyOriginal.durableStateDigest())
    )

    let rates = [1, 2, 4, 8].map(runTemporalFrequency)
    let evidence = rates.map(temporalEvidence)
    check(
        "temporal physiology invariant at 1/2/4/8 Hz",
        Set(evidence.map(\.hunger)).count == 1
            && Set(evidence.map(\.fatigue)).count == 1
            && Set(evidence.map(\.health)).count == 1
            && Set(evidence.map { $0.physiological.appliedBoundaryCount })
                == [1]
            && rates.map(\.tick) == [60, 120, 240, 480]
    )
    checkD("V1 hunger is 0.05 per boundary", evidence[0].hunger, 0.05)
    checkD("V1 fatigue is 0.06 per boundary", evidence[0].fatigue, 0.06)

    var cognitiveOnly = temporalPhysiologySession()
    for _ in 0..<32 { _ = try! cognitiveOnly.advanceTick() }
    let cognitiveOnlyEvidence = temporalEvidence(cognitiveOnly)
    check(
        "cognitive steps grant zero elapsed biology",
        cognitiveOnly.tick == 32
            && cognitiveOnlyEvidence.hunger == 0
            && cognitiveOnlyEvidence.fatigue == 0
            && cognitiveOnlyEvidence.physiological.appliedBoundaryCount == 0
    )

    runTemporalThresholdAndRestProof()
    var partitionA = temporalPhysiologySession()
    advanceTemporal(&partitionA, deltas: Array(repeating: 5, count: 240))
    _ = try! partitionA.advanceTick()
    var partitionB = temporalPhysiologySession()
    advanceTemporal(&partitionB, deltas: Array(repeating: 10, count: 120))
    _ = try! partitionB.advanceTick()
    var partitionC = temporalPhysiologySession()
    advanceTemporal(&partitionC, deltas: Array(repeating: 20, count: 60))
    _ = try! partitionC.advanceTick()
    check(
        "World-time delivery partition is invariant",
        temporalEvidence(partitionA) == temporalEvidence(partitionB)
            && temporalEvidence(partitionB) == temporalEvidence(partitionC)
    )

    var founder = temporalFounderSession()
    let initialAge = try! founder.demographicAge(
        for: AgentID(rawValue: "agent_0")!
    )
    for _ in 0..<32 { _ = try! founder.advanceTick() }
    let cognitiveOnlyAge = try! founder.demographicAge(
        for: AgentID(rawValue: "agent_0")!
    )
    advanceTemporal(&founder, deltas: Array(repeating: 20, count: 60))
    _ = try! founder.advanceTick()
    let boundaryAge = try! founder.demographicAge(
        for: AgentID(rawValue: "agent_0")!
    )
    let boundaryProfile = founder.homeostasisSnapshot().profiles[0]
    check(
        "physiological age and homeostasis use the World-time boundary",
        cognitiveOnlyAge == initialAge
            && boundaryAge == initialAge + 1
            && boundaryProfile.ageTicks == boundaryAge
            && founder.physiologicalTimeSnapshot().appliedBoundaryCount == 1
    )

    var direct = temporalPhysiologySession()
    advanceTemporal(
        &direct,
        deltas: Array(repeating: 109, count: 11) + [0]
    )
    // The preceding schedule reaches 1,199 World ticks exactly.
    let checkpoint = try! direct.makeCheckpoint()
    var restored = try! AgentSimulationSession.restoring(checkpoint)
    check(
        "schema 45 checkpoint retains Increment 05 nonzero temporal remainder",
        checkpoint.schemaVersion
            == AgentCheckpointSchema.pathReadinessLivenessVersion
            && restored.physiologicalTimeSnapshot().remainderWorldTicks == 1_199
    )
    try! direct.advancePhysiologicalTime(toWorldTick: 1_200)
    try! restored.advancePhysiologicalTime(toWorldTick: 1_200)
    _ = try! direct.advanceTick()
    _ = try! restored.advanceTick()
    check(
        "direct and restored temporal continuation converge",
        temporalEvidence(direct) == temporalEvidence(restored)
    )

    runTemporalCheckpointMatrixProof()

    var backward = temporalPhysiologySession()
    try! backward.advancePhysiologicalTime(toWorldTick: 100)
    do {
        try backward.advancePhysiologicalTime(toWorldTick: 99)
        check("backward World time fails closed", false)
    } catch AgentPhysiologicalTimeError.worldTickMovedBackward {
        check("backward World time fails closed", true)
    } catch {
        check("backward World time fails closed", false, "\(error)")
    }

    var oversized = temporalPhysiologySession()
    do {
        try oversized.advancePhysiologicalTime(toWorldTick: 9_601)
        check("oversized temporal input fails closed", false)
    } catch AgentPhysiologicalTimeError.elapsedWorldTickLimitExceeded(9_601) {
        check("oversized temporal input fails closed", true)
    } catch {
        check("oversized temporal input fails closed", false, "\(error)")
    }

    var remainderBase = temporalPhysiologySession()
    advanceTemporal(&remainderBase, deltas: [1_199])
    let remainderCheckpoint = try! remainderBase.makeCheckpoint()
    var remainderLive = remainderBase
    var remainderRecorder = try! AgentReplayRecorder(
        checkpoint: remainderCheckpoint,
        session: remainderLive
    )
    _ = replayTick(
        &remainderLive,
        recorder: &remainderRecorder,
        worldTick: 1_200
    )
    let (remainderJournal, _) = verifyTemporalReplay(
        checkpoint: remainderCheckpoint,
        recorder: remainderRecorder,
        live: remainderLive,
        name: "temporal-remainder"
    )
    check(
        "nonzero remainder crosses one replayed boundary",
        remainderJournal.records.count == 1
            && remainderLive.physiologicalTimeSnapshot()
                .remainderWorldTicks == 0
            && remainderLive.physiologicalTimeSnapshot()
                .appliedBoundaryCount == 1
            && temporalEvidence(remainderLive).hunger == 0.05
    )

    var pauseLive = temporalPhysiologySession()
    let pauseCheckpoint = try! pauseLive.makeCheckpoint()
    var pauseRecorder = try! AgentReplayRecorder(
        checkpoint: pauseCheckpoint,
        session: pauseLive
    )
    _ = replayTick(
        &pauseLive, recorder: &pauseRecorder, worldTick: 600
    )
    let causalBeforePause = pauseLive.causalLedgerSnapshot().summary
    try! pauseRecorder.apply(
        .reconcilePhysiologicalTime(mode: .advance, worldTick: 700),
        to: &pauseLive
    )
    let causalAfterPause = pauseLive.causalLedgerSnapshot().summary
    try! pauseRecorder.apply(
        .reconcilePhysiologicalTime(mode: .rebase, worldTick: 2_000),
        to: &pauseLive
    )
    let causalAfterResume = pauseLive.causalLedgerSnapshot().summary
    _ = replayTick(
        &pauseLive, recorder: &pauseRecorder, worldTick: 2_500
    )
    let (pauseJournal, _) = verifyTemporalReplay(
        checkpoint: pauseCheckpoint,
        recorder: pauseRecorder,
        live: pauseLive,
        name: "temporal-pause-rebase"
    )
    check(
        "pause and resume rebases exclude suspended World time",
        pauseLive.physiologicalTimeSnapshot().totalElapsedWorldTicks
            == 1_200
            && pauseLive.physiologicalTimeSnapshot().appliedBoundaryCount
                == 1
            && causalBeforePause == causalAfterPause
            && causalAfterPause == causalAfterResume
            && pauseJournal.records.filter {
                $0.operationKind == .physiologicalTime
            }.count == 2
    )

    let partitionSchedules = [
        [400, 800, 1_200],
        [200, 1_000, 1_200],
        [1, 1_199, 1_200],
    ]
    let replayPartitions = partitionSchedules.enumerated().map {
        index, schedule -> AgentSimulationSession in
        var live = temporalPhysiologySession()
        let checkpoint = try! live.makeCheckpoint()
        var recorder = try! AgentReplayRecorder(
            checkpoint: checkpoint,
            session: live
        )
        for worldTick in schedule {
            _ = replayTick(
                &live, recorder: &recorder, worldTick: worldTick
            )
        }
        _ = verifyTemporalReplay(
            checkpoint: checkpoint,
            recorder: recorder,
            live: live,
            name: "temporal-partition-\(index)"
        )
        return live
    }
    check(
        "recorded temporal input partition converges semantically",
        (try! replayPartitions[0].durableStateDigest())
            == (try! replayPartitions[1].durableStateDigest())
            && (try! replayPartitions[1].durableStateDigest())
                == (try! replayPartitions[2].durableStateDigest())
    )

    var stepLive = temporalPhysiologySession()
    let stepCheckpoint = try! stepLive.makeCheckpoint()
    var stepRecorder = try! AgentReplayRecorder(
        checkpoint: stepCheckpoint,
        session: stepLive
    )
    for _ in 0..<32 {
        _ = replayTick(&stepLive, recorder: &stepRecorder, worldTick: nil)
    }
    let (stepJournal, _) = verifyTemporalReplay(
        checkpoint: stepCheckpoint,
        recorder: stepRecorder,
        live: stepLive,
        name: "temporal-lab-step"
    )
    check(
        "replayed cognitive-only steps grant no biology",
        stepJournal.records.count == 32
            && stepLive.tick == 32
            && temporalEvidence(stepLive).hunger == 0
            && temporalEvidence(stepLive).fatigue == 0
            && stepLive.physiologicalTimeSnapshot()
                .totalElapsedWorldTicks == 0
    )

    let frequencyReplays = [1, 2, 4, 8].map {
        replayTemporalFrequency($0, name: "temporal-\($0)hz")
    }
    let frequencyPhysiology = frequencyReplays.map {
        temporalEvidence($0.live)
    }
    check(
        "recorded 1/2/4/8 Hz physiology is invariant",
        Set(frequencyPhysiology.map(\.hunger)).count == 1
            && Set(frequencyPhysiology.map(\.fatigue)).count == 1
            && Set(frequencyPhysiology.map {
                $0.physiological.appliedBoundaryCount
            }) == [1]
            && frequencyReplays.map { $0.journal.records.count }
                == [60, 120, 240, 480]
            && frequencyReplays.allSatisfy {
                !$0.journal.records.contains {
                    $0.operationKind == .physiologicalTime
                }
            }
    )

    var speedLive = temporalPhysiologySession()
    let speedCheckpoint = try! speedLive.makeCheckpoint()
    var speedRecorder = try! AgentReplayRecorder(
        checkpoint: speedCheckpoint,
        session: speedLive
    )
    var speedWorldTick = 0
    for (hz, worldTicks) in [(4, 300), (8, 300), (2, 300), (4, 300)] {
        let steps = hz * worldTicks / 20
        let start = speedWorldTick
        for step in 1...steps {
            speedWorldTick = start + step * worldTicks / steps
            _ = replayTick(
                &speedLive,
                recorder: &speedRecorder,
                worldTick: speedWorldTick
            )
        }
    }
    let (speedJournal, _) = verifyTemporalReplay(
        checkpoint: speedCheckpoint,
        recorder: speedRecorder,
        live: speedLive,
        name: "temporal-speed-change"
    )
    check(
        "mid-run cognitive speed changes preserve physiology",
        speedWorldTick == 1_200
            && temporalEvidence(speedLive).hunger == 0.05
            && temporalEvidence(speedLive).fatigue == 0.06
            && speedJournal.records.count == 270
    )

    var carried: [ItemStack?] = [ItemStack(iid("sweet_berries"), 2)]
    let debited = extractItemStack(
        matching: ItemStack(iid("sweet_berries"), 1),
        quantity: 1,
        from: &carried,
        slotFilter: { $0 == 0 }
    )
    var foodLive = temporalPhysicalFoodSession()
    let foodCheckpoint = try! foodLive.makeCheckpoint()
    var foodRecorder = try! AgentReplayRecorder(
        checkpoint: foodCheckpoint,
        session: foodLive
    )
    let berry = temporalBerryOutcome(foodLive)
    try! foodRecorder.apply(
        .validatedPhysicalFoodConsumption(berry),
        to: &foodLive
    )
    _ = replayTick(&foodLive, recorder: &foodRecorder, worldTick: 600)
    _ = replayTick(&foodLive, recorder: &foodRecorder, worldTick: 1_200)
    let (_, foodReplay) = verifyTemporalReplay(
        checkpoint: foodCheckpoint,
        recorder: foodRecorder,
        live: foodLive,
        name: "temporal-physical-food"
    )
    check(
        "physical berry debit precedes replayed passive hunger",
        debited?.count == 1 && carried[0]?.count == 1
            && (try! foodLive.state(for: "temporal_agent")).needs.hunger
                == 0.75
            && foodLive.physicalFoodSurvivalSnapshot()?
                .totalConsumedQuantity == 1
            && foodReplay.session.physicalFoodSurvivalSnapshot()?
                .totalConsumedQuantity == 1
    )
    var foodDirect = foodLive
    var foodRestored = try! AgentSimulationSession.restoring(
        foodLive.makeCheckpoint()
    )
    try! foodDirect.advancePhysiologicalTime(toWorldTick: 2_400)
    try! foodRestored.advancePhysiologicalTime(toWorldTick: 2_400)
    _ = try! foodDirect.advanceTick()
    _ = try! foodRestored.advanceTick()
    check(
        "post-consumption checkpoint preserves remainder and future hunger",
        (try! foodDirect.durableStateBytes())
            == (try! foodRestored.durableStateBytes())
            && (try! foodDirect.state(for: "temporal_agent"))
                .needs.hunger == 0.80
            && foodDirect.physicalFoodSurvivalSnapshot()?
                .totalConsumedQuantity == 1
    )

    var mortalityLive = temporalMortalitySession()
    let mortalityCheckpoint = try! mortalityLive.makeCheckpoint()
    var mortalityRecorder = try! AgentReplayRecorder(
        checkpoint: mortalityCheckpoint,
        session: mortalityLive
    )
    let mortalityTick = replayTick(
        &mortalityLive,
        recorder: &mortalityRecorder,
        worldTick: 3_600
    )
    let (_, mortalityReplay) = verifyTemporalReplay(
        checkpoint: mortalityCheckpoint,
        recorder: mortalityRecorder,
        live: mortalityLive,
        name: "temporal-mortality"
    )
    check(
        "physiological mortality precedes cognition exactly once",
        mortalityTick.agents.isEmpty
            && mortalityLive.snapshot().agents.isEmpty
            && mortalityLive.mortalitySnapshot().totalDeathCount == 3
            && mortalityReplay.session.mortalitySnapshot()
                .totalDeathCount == 3,
        "tickAgents=\(mortalityTick.agents.count) "
            + "liveAgents=\(mortalityLive.snapshot().agents.count) "
            + "liveDeaths=\(mortalityLive.mortalitySnapshot().totalDeathCount) "
            + "replayDeaths="
            + "\(mortalityReplay.session.mortalitySnapshot().totalDeathCount)"
    )
    let terminalCheckpoint = try! mortalityLive.makeCheckpoint()
    let terminalRestored = try! AgentSimulationSession.restoring(
        terminalCheckpoint
    )
    check(
        "terminal mortality checkpoint restores without resurrection",
        terminalRestored.snapshot().agents.isEmpty
            && terminalRestored.mortalitySnapshot().totalDeathCount == 3
            && (try! terminalRestored.durableStateBytes())
                == (try! mortalityLive.durableStateBytes())
    )

    var legacyLive = temporalLegacySession()
    let legacyCheckpoint = try! legacyLive.makeCheckpoint()
    var legacyRecorder = try! AgentReplayRecorder(
        checkpoint: legacyCheckpoint,
        session: legacyLive
    )
    _ = replayTick(
        &legacyLive, recorder: &legacyRecorder, worldTick: nil
    )
    let (legacyJournal, _) = verifyTemporalReplay(
        checkpoint: legacyCheckpoint,
        recorder: legacyRecorder,
        live: legacyLive,
        name: "temporal-legacy-exact"
    )
    check(
        "historical replay retains cognitive-tick physiology",
        legacyCheckpoint.schemaVersion
            == AgentCheckpointSchema.currentVersion
            && legacyJournal.manifest.schemaVersion
                == AgentReplaySchema.currentVersion
            && temporalEvidence(legacyLive).hunger == 0.05
            && temporalEvidence(legacyLive).fatigue == 0.06
    )
    let encodedLegacyRecord = try! AgentCheckpointCodec.encode(
        legacyJournal.records[0]
    )
    let legacyObject = try! JSONSerialization.jsonObject(
        with: encodedLegacyRecord
    )
    let historicalShape = removingTemporalWorldTickKey(legacyObject)
    let historicalBytes = try! JSONSerialization.data(
        withJSONObject: historicalShape,
        options: [.sortedKeys]
    )
    let historicalRecord = try? AgentCheckpointCodec.decode(
        AgentReplayRecord.self,
        from: historicalBytes
    )
    check(
        "pre-v44 advanceTick payload decodes without World-time field",
        historicalRecord?.operationKind == .advanceTick
    )

    var refusedMigration = try! AgentSimulationSession.restoring(
        legacyCheckpoint
    )
    var refusedMigrationRecorder = try! AgentReplayRecorder(
        checkpoint: legacyCheckpoint,
        session: refusedMigration
    )
    let refusedMigrationBytes = try! refusedMigration.durableStateBytes()
    check(
        "legacy base refuses implicit World-time reinterpretation",
        (try? refusedMigrationRecorder.apply(
            .advanceTick(
                physiologicalWorldTick: 1_200,
                perceptions: [],
                physicalObservations: []
            ),
            to: &refusedMigration
        )) == nil
            && refusedMigrationRecorder.records.isEmpty
            && refusedMigrationRecorder.schemaVersion
                == AgentReplaySchema.currentVersion
            && (try! refusedMigration.durableStateBytes())
                == refusedMigrationBytes
    )

    var migratedLive = try! AgentSimulationSession.restoring(
        legacyCheckpoint
    )
    var migratedRecorder = try! AgentReplayRecorder(
        checkpoint: legacyCheckpoint,
        session: migratedLive
    )
    try! migratedRecorder.apply(
        .reconcilePhysiologicalTime(mode: .rebase, worldTick: 100),
        to: &migratedLive
    )
    _ = replayTick(
        &migratedLive,
        recorder: &migratedRecorder,
        worldTick: 1_300
    )
    let (migratedJournal, _) = verifyTemporalReplay(
        checkpoint: legacyCheckpoint,
        recorder: migratedRecorder,
        live: migratedLive,
        name: "temporal-legacy-migration"
    )
    check(
        "legacy base migrates only at explicit v44 rebase",
        migratedJournal.manifest.schemaVersion
            == AgentReplaySchema.temporalPhysiologyVersion
            && migratedJournal.records.first?.operationKind
                == .physiologicalTime
            && temporalEvidence(migratedLive).hunger == 0.05
            && migratedLive.physiologicalTimeSnapshot()
                .appliedBoundaryCount == 1
    )

    print(
        "  INCREMENT_05_TEMPORAL_FOCUSED hunger=\(evidence[0].hunger) "
            + "fatigue=\(evidence[0].fatigue) boundary="
            + "\(evidence[0].physiological.appliedBoundaryCount) "
            + "schema=\(checkpoint.schemaVersion) replaySchema="
            + "\(remainderJournal.manifest.schemaVersion) "
            + "recordProof=1200/240/0/240"
    )
}
