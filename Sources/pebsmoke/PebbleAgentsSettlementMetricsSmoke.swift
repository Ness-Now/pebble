import Foundation
import PebbleAgents

private let settlementAnchor = AgentPosition(x: 0, y: 64, z: 0)
private let settlementReception = AgentPosition(x: 20, y: 64, z: 0)
private let settlementRoute = (20...27).reversed().map {
    AgentPosition(x: $0, y: 64, z: 0)
}

private func settlementAgent(
    _ id: String,
    x: Int,
    health: Int = 100,
    curiosity: Double = 0.2
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: curiosity, safety: 1),
        health: health,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(kind: .idle, reason: "initial", startedAtTick: 0, urgency: 0),
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

private func settlementSession(
    id: String,
    ledgerEvents: Int = 8192,
    firstAgentHealth: Int = 100,
    firstAgentCuriosity: Double = 0.2
) -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.001,
        fatiguePerTick: 0.001,
        hungryThreshold: 0.40,
        criticalHungerThreshold: 0.80,
        hungerRecoveryThreshold: 0.15,
        fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.20,
        foodNutrition: 1,
        restRecoveryPerTick: 1,
        starvationGraceTicks: 2,
        starvationDamagePerTick: 10
    )
    let configuration = try! AgentSessionConfiguration(
        seed: 46,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 128),
        survivalConfiguration: survival
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            settlementAgent(
                "agent_0",
                x: -30,
                health: firstAgentHealth,
                curiosity: firstAgentCuriosity
            ),
            settlementAgent("agent_1", x: -15),
            settlementAgent("agent_2", x: 0),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: ledgerEvents)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: settlementAnchor,
        receptionPosition: settlementReception
    )
    return session
}

private func settlementMigrationObservation() -> AgentMigrationWorldObservation {
    AgentMigrationWorldObservation(
        worldTick: 0,
        candidateIndex: 0,
        entryPosition: settlementRoute[0],
        receptionPosition: settlementReception,
        route: settlementRoute,
        entryChunkReady: true,
        entrySafe: true,
        entryUnoccupied: true,
        receptionChunkReady: true,
        receptionSafe: true,
        receptionUnoccupied: true
    )
}

private func settlementColumn(_ position: AgentPosition) -> AgentWorldColumnObservation {
    AgentWorldColumnObservation(
        position: position,
        chunkReady: true,
        surfaceY: position.y,
        height: position.y,
        blockBelow: 1,
        blockAtFeet: 0,
        blockAtHead: 0,
        groundPresent: true,
        feetClear: true,
        headClear: true
    )
}

private func settlementPerception(
    position: AgentPosition,
    worldTick: Int
) -> AgentPerceptionInput {
    let neighbors = AgentCardinalDirection.allCases.map { direction in
        let target = AgentPosition(
            x: position.x + direction.dx,
            y: position.y,
            z: position.z + direction.dz
        )
        return AgentWorldNeighborObservation(
            direction: direction,
            column: settlementColumn(target),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
    }
    let world = try! AgentWorldObservation(
        worldTick: worldTick,
        position: position,
        center: settlementColumn(position),
        neighbors: neighbors,
        biomeId: 1,
        biomeName: "plains",
        combinedLight: 15,
        skyLight: 15,
        blockLight: 0,
        dayTime: 1000,
        raining: false,
        thundering: false
    )
    return AgentPerceptionInput(
        agentId: "agent_3",
        worldObservation: world,
        navigationObservation: AgentNavigationObservation(
            worldTick: worldTick,
            origin: position,
            target: settlementReception,
            radius: 8,
            cells: settlementRoute.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

private func settlementResidentPerception(
    agentId: String,
    position: AgentPosition,
    worldTick: Int
) -> AgentPerceptionInput {
    let neighbors = AgentCardinalDirection.allCases.map { direction in
        let target = AgentPosition(
            x: position.x + direction.dx,
            y: position.y,
            z: position.z + direction.dz
        )
        return AgentWorldNeighborObservation(
            direction: direction,
            column: settlementColumn(target),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
    }
    return AgentPerceptionInput(
        agentId: agentId,
        worldObservation: try! AgentWorldObservation(
            worldTick: worldTick,
            position: position,
            center: settlementColumn(position),
            neighbors: neighbors,
            biomeId: 1,
            biomeName: "plains",
            combinedLight: 15,
            skyLight: 15,
            blockLight: 0,
            dayTime: 1000,
            raining: false,
            thundering: false
        )
    )
}

@discardableResult
private func advanceSettlementTick(
    _ session: inout AgentSimulationSession,
    recorder: inout AgentReplayRecorder?
) throws -> [AgentMovementOutcome] {
    let migrant = session.snapshot().agents.first { $0.id == "agent_3" }
    let migrating = session.migrationSnapshot().migrations.contains {
        $0.status == .admitted || $0.status == .inTransit
    }
    let perceptions = migrating && migrant != nil
        ? [settlementPerception(position: migrant!.position, worldTick: session.tick + 1)]
        : []
    if recorder != nil {
        _ = try recorder!.apply(
            .advanceTick(perceptions: perceptions, physicalObservations: []),
            to: &session
        )
    } else {
        _ = try session.advanceTick(perceptions: perceptions)
    }
    let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
    if recorder != nil {
        _ = try recorder!.apply(.movementOutcomes(outcomes), to: &session)
    } else {
        try session.applyMovementOutcomes(outcomes)
    }
    return outcomes
}

private func settlementBehaviorDigest(_ session: AgentSimulationSession) -> String {
    let snapshot = session.snapshot()
    let agents = snapshot.agents.map {
        [
            $0.id,
            "\($0.position.x),\($0.position.y),\($0.position.z)",
            $0.currentGoal.kind.rawValue,
            $0.lastAction?.name ?? "none",
            "\($0.needs.hunger),\($0.needs.fatigue),\($0.needs.curiosity),\($0.needs.safety)",
            "\($0.movementCount)",
            "\($0.navigationProgress.routeIndex)",
            "\($0.resourceInventory.totalCount)",
        ].joined(separator: ":")
    }.joined(separator: ";")
    let population = session.populationSnapshot()
    let members = population.members.map {
        "\($0.agentID.rawValue):\($0.ordinal.rawValue):\($0.status.rawValue)"
    }.joined(separator: ";")
    let migrations = population.migrations.map {
        "\($0.migrationID.rawValue):\($0.status.rawValue):\($0.routeCursor):"
            + "\($0.arrivedTick.map(String.init) ?? "none")"
    }.joined(separator: ";")
    let conservation = session.conservationSnapshot()
    return AgentSettlementMetricsDigest.make(
        "\(session.tick)|\(agents)|\(members)|\(migrations)|"
            + "\(conservation.harvestedTotal)|\(conservation.carriedTotal)|"
            + "\(conservation.campStockTotal)|\(conservation.consumedTotal)|"
            + "\(conservation.constructionEscrowTotal)|\(conservation.constructedTotal)"
    )
}

func runPebbleAgentsSettlementMetricsSmoke() {
    section("PebbleAgents bounded settlement metrics and multi-scale view")

    check("settlement checkpoint schema v3",
          AgentCheckpointSchema.settlementMetricsVersion == 3)
    check("settlement replay schema v3", AgentReplaySchema.settlementMetricsVersion == 3)
    let live = AgentSettlementMetricsConfiguration.live
    check("settlement macro interval", live.macroIntervalTicks == 4)
    check("settlement frame history bound", live.maximumMetricFrames == 16)
    check("settlement classification bound", live.maximumAgentClassifications == 8)
    check("settlement causal window bound", live.maximumCausalEventsPerWindow == 4096)
    check("settlement fixed-point scale", live.fixedPointScale == 1_000_000)
    check("settlement configuration Codable", try! JSONDecoder().decode(
        AgentSettlementMetricsConfiguration.self,
        from: JSONEncoder().encode(live)
    ) == live)
    check("settlement invalid interval rejected", {
        do {
            _ = try AgentSettlementMetricsConfiguration(macroIntervalTicks: 1)
            return false
        } catch { return true }
    }())
    check("settlement invalid history rejected", {
        do {
            _ = try AgentSettlementMetricsConfiguration(maximumMetricFrames: 0)
            return false
        } catch { return true }
    }())
    check("settlement invalid classification bound rejected", {
        do {
            _ = try AgentSettlementMetricsConfiguration(maximumAgentClassifications: 7)
            return false
        } catch { return true }
    }())
    check("settlement fixed-point positive half away", try! AgentMetricFixedPoint(
        value: 0.0000005
    ).rawValue == 1)
    check("settlement fixed-point negative half away", try! AgentMetricFixedPoint(
        value: -0.0000005
    ).rawValue == -1)
    check("settlement fixed-point overflow rejected", {
        do {
            _ = try AgentMetricFixedPoint(value: Double.greatestFiniteMagnitude)
            return false
        } catch { return true }
    }())

    let noPopulationConfiguration = try! AgentSessionConfiguration(
        seed: 46,
        memoryPolicy: .bounded(maxEntries: 16)
    )
    var noPopulation = try! AgentSimulationSession(
        configuration: noPopulationConfiguration,
        agents: [settlementAgent("agent_0", x: 0)],
        simulationID: try! AgentSimulationID(validating: "settlement-no-population"),
        causalLedgerPolicy: .bounded(maxEvents: 32)
    )
    check("settlement metrics require population", {
        do {
            try noPopulation.setSettlementMetricsEnabled(true)
            return false
        } catch AgentSessionError.settlementMetrics(.populationRequired) {
            return true
        } catch { return false }
    }())

    var session = settlementSession(id: "settlement-metrics-smoke")
    try! session.setSettlementMetricsEnabled(true)
    check("settlement enabled at tick zero", session.settlementMetricsEnabled)
    check("settlement no retroactive frame", session.settlementMetricsSnapshot().frames.isEmpty)
    check("settlement macro sequence starts zero",
          session.settlementMetricsSummary().macroSequence == 0)
    check("settlement next pulse four", session.settlementMetricsSummary().nextPulseTick == 4)
    check("settlement duplicate enable rejected", {
        do {
            try session.setSettlementMetricsEnabled(true)
            return false
        } catch AgentSessionError.settlementMetrics(.alreadyEnabled) {
            return true
        } catch { return false }
    }())
    check("settlement early pulse absent", try! session.applySettlementMetricsPulseIfDue() == nil)

    _ = try! session.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: settlementMigrationObservation()
    )
    var noRecorder: AgentReplayRecorder?
    var firstMovementTicks: [Int] = []
    for _ in 0..<4 {
        let outcomes = try! advanceSettlementTick(&session, recorder: &noRecorder)
        if outcomes.contains(where: { $0.agentId == "agent_3" && $0.status == .moved }) {
            firstMovementTicks.append(session.tick)
        }
    }
    let frame1 = session.settlementMetricsSnapshot().frames[0]
    check("settlement first pulse boundary", frame1.toTickInclusive == 4
        && frame1.fromTickExclusive == 0)
    check("settlement first macro sequence", frame1.macroSequence.rawValue == 1)
    check("settlement first frame ID",
          frame1.frameID.rawValue == "settlement-main/frame-00000001-t4")
    check("settlement migration movement delta", frame1.throughput.movementDelta == 4)
    check("settlement migration population four", frame1.population.members == 4
        && frame1.population.residents == 3 && frame1.population.migrants == 1)
    check("settlement migration classification", frame1.activity.migratingCount == 1)
    check("settlement classifications exhaustive",
          frame1.activity.classifications.count == 4
            && frame1.activity.urgentCount + frame1.activity.migratingCount
                + frame1.activity.engagedCount + frame1.activity.stableCount == 4)
    check("settlement classifications sorted", frame1.activity.classifications.map {
        $0.agentID
    } == frame1.activity.classifications.map { $0.agentID }.sorted())
    check("settlement frame one transitioning", frame1.condition == .transitioning)
    check("settlement causal coverage complete", frame1.causalCoverageComplete)
    check("settlement movement ticks exact", firstMovementTicks == [1, 2, 3, 4])
    check("settlement agent snapshot hides collective frames", session
        .settlementMetricsSnapshot(for: AgentID(rawValue: "agent_3")!)
        .classification?.agentID.rawValue == "agent_3")

    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    check("settlement checkpoint uses v3", checkpoint.schemaVersion == 3)
    check("settlement checkpoint includes metrics", String(
        data: checkpointBytes,
        encoding: .utf8
    )!.contains("settlementMetricsState"))
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("settlement restore exact bytes", try! restored.durableStateBytes()
        == session.durableStateBytes())
    check("settlement restore no tick advance", restored.tick == 4)
    check("settlement restore pulse clock", restored.settlementMetricsSummary().macroSequence == 1
        && restored.settlementMetricsSummary().lastPulseTick == 4
        && restored.settlementMetricsSummary().nextPulseTick == 8)

    var direct = restored
    var recorder: AgentReplayRecorder? = try! AgentReplayRecorder(
        checkpoint: checkpoint,
        session: direct
    )
    for _ in 4..<12 {
        _ = try! advanceSettlementTick(&direct, recorder: &recorder)
    }
    let frames = direct.settlementMetricsSnapshot().frames
    check("settlement three deterministic pulses",
          frames.map(\.toTickInclusive) == [4, 8, 12])
    check("settlement sequence monotone",
          frames.map { $0.macroSequence.rawValue } == [1, 2, 3])
    check("settlement arrival in frame two", frames[1].population.arrivalDelta == 1
        && frames[1].population.residents == 4 && frames[1].population.migrants == 0)
    check("settlement frame two transitioning", frames[1].condition == .transitioning)
    check(
        "settlement frame three stable",
        frames[2].condition == .stable,
        "condition=\(frames[2].condition.rawValue) reason=\(frames[2].reasonCode)"
    )
    check("settlement frame three no movement", frames[2].throughput.movementDelta == 0)
    check(
        "settlement frame three four stable",
        frames[2].activity.stableCount == 4,
        "tiers=\(frames[2].activity.classifications.map { $0.tier.rawValue }.joined(separator: ","))"
    )
    check("settlement conservation exact", frames.allSatisfy {
        $0.material.conservationBalanced
    })

    var active = settlementSession(
        id: "settlement-active",
        firstAgentCuriosity: 0.8
    )
    try! active.setSettlementMetricsEnabled(true)
    for _ in 0..<4 {
        let agent = active.snapshot().agents.first { $0.id == "agent_0" }!
        _ = try! active.advanceTick(perceptions: [
            settlementResidentPerception(
                agentId: agent.id,
                position: agent.position,
                worldTick: active.tick + 1
            ),
        ])
        try! active.applyMovementOutcomes(
            AgentMovementCoordinator.resolve(snapshot: active.snapshot())
        )
    }
    let activeFrame = active.settlementMetricsSnapshot().frames[0]
    check(
        "settlement active condition",
        activeFrame.condition == .active
            && activeFrame.reasonCode == "accepted_window_activity",
        "condition=\(activeFrame.condition.rawValue) reason=\(activeFrame.reasonCode)"
    )
    check("settlement active movement delta", activeFrame.throughput.movementDelta > 0)
    check("settlement active no urgency", activeFrame.activity.urgentCount == 0)
    check("settlement active no population transition",
          activeFrame.activity.migratingCount == 0
            && activeFrame.population.admissionDelta == 0
            && activeFrame.population.arrivalDelta == 0
            && activeFrame.populationEventDelta == 0)
    check("settlement active conservation exact",
          activeFrame.material.conservationBalanced
            && activeFrame.throughput.materialActivityDelta == 0)

    var strained = settlementSession(
        id: "settlement-strained",
        firstAgentHealth: 25
    )
    try! strained.setSettlementMetricsEnabled(true)
    for _ in 0..<4 {
        _ = try! advanceSettlementTick(&strained, recorder: &noRecorder)
    }
    let strainedFrame = strained.settlementMetricsSnapshot().frames[0]
    check(
        "settlement strained condition",
        strainedFrame.condition == .strained
            && strainedFrame.reasonCode == "urgent_agents",
        "condition=\(strainedFrame.condition.rawValue) reason=\(strainedFrame.reasonCode)"
    )
    check("settlement strained true classifier",
          strainedFrame.activity.urgentCount == 1
            && strainedFrame.activity.classifications.first?.tier == .microUrgent
            && strainedFrame.activity.classifications.first?.reason == "safety"
            && strainedFrame.welfare.minimumHealth == 25)

    let journal = try! recorder!.journal(
        named: AgentCheckpointName(rawValue: "settlement-continuation")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: checkpoint,
        journal: journal
    )
    check("settlement replay schema v3", journal.manifest.schemaVersion == 3)
    check("settlement replay verified", replayed.report.verified)
    check("settlement replay exact durable bytes", try! replayed.session.durableStateBytes()
        == direct.durableStateBytes())
    check("settlement replay same frames", replayed.session.settlementMetricsSnapshot().frames
        == direct.settlementMetricsSnapshot().frames)
    check("settlement replay same causal digest", replayed.report.finalCausalDigest
        == direct.causalLedgerSnapshot().summary.digest)

    var activation = settlementSession(id: "settlement-replay-activation")
    let activationBase = try! activation.makeCheckpoint()
    var activationRecorder = try! AgentReplayRecorder(
        checkpoint: activationBase,
        session: activation
    )
    _ = try! activationRecorder.apply(
        .setSettlementMetricsEnabled(true, configuration: .live),
        to: &activation
    )
    let activationJournal = try! activationRecorder.journal(
        named: AgentCheckpointName(rawValue: "settlement-activation")!
    )
    let activationReplay = try! AgentSessionReplayer.replay(
        checkpoint: activationBase,
        journal: activationJournal
    )
    check("settlement activation upgrades replay to v3",
          activationJournal.manifest.schemaVersion == 3)
    check("settlement activation replay verified", activationReplay.report.verified)
    check("settlement activation replay exact", try! activationReplay.session.durableStateBytes()
        == activation.durableStateBytes())

    var off = settlementSession(id: "settlement-behavior-ab")
    var on = settlementSession(id: "settlement-behavior-ab")
    try! on.setSettlementMetricsEnabled(true)
    _ = try! off.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: settlementMigrationObservation()
    )
    _ = try! on.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: settlementMigrationObservation()
    )
    for _ in 0..<12 {
        let offOutcomes = try! advanceSettlementTick(&off, recorder: &noRecorder)
        let onOutcomes = try! advanceSettlementTick(&on, recorder: &noRecorder)
        check("settlement A/B movement outcomes tick \(off.tick)",
              offOutcomes.map { "\($0.agentId):\($0.status.rawValue):\($0.toPosition)" }
                == onOutcomes.map { "\($0.agentId):\($0.status.rawValue):\($0.toPosition)" })
    }
    check("settlement A/B agent snapshots identical",
          off.snapshot().agents == on.snapshot().agents)
    check("settlement A/B behavioral digest identical",
          settlementBehaviorDigest(off) == settlementBehaviorDigest(on))
    check("settlement A/B population material identity",
          off.populationSummary().memberCount == on.populationSummary().memberCount
            && off.conservationSnapshot() == on.conservationSnapshot())

    let v1Configuration = try! AgentSessionConfiguration(
        seed: 46,
        memoryPolicy: .bounded(maxEntries: 16)
    )
    let v1 = try! AgentSimulationSession(
        configuration: v1Configuration,
        agents: [settlementAgent("agent_0", x: 0)],
        simulationID: try! AgentSimulationID(validating: "settlement-v1"),
        causalLedgerPolicy: .bounded(maxEvents: 64)
    )
    let v1Checkpoint = try! v1.makeCheckpoint()
    check("settlement off population off remains v1", v1Checkpoint.schemaVersion == 1)
    check("settlement v1 omits metrics", !String(
        data: try! AgentCheckpointCodec.encode(v1Checkpoint),
        encoding: .utf8
    )!.contains("settlementMetricsState"))
    let v2 = settlementSession(id: "settlement-v2")
    let v2Checkpoint = try! v2.makeCheckpoint()
    check("settlement off population on remains v2", v2Checkpoint.schemaVersion == 2)
    check("settlement v2 omits metrics", !String(
        data: try! AgentCheckpointCodec.encode(v2Checkpoint),
        encoding: .utf8
    )!.contains("settlementMetricsState"))

    var bounded = settlementSession(id: "settlement-history")
    let boundedConfiguration = try! AgentSettlementMetricsConfiguration(
        macroIntervalTicks: 2,
        maximumMetricFrames: 1
    )
    try! bounded.setSettlementMetricsEnabled(true, configuration: boundedConfiguration)
    for _ in 0..<4 {
        _ = try! advanceSettlementTick(&bounded, recorder: &noRecorder)
    }
    check("settlement history retained bound",
          bounded.settlementMetricsSnapshot().frames.count == 1)
    check("settlement history evicts oldest",
          bounded.settlementMetricsSnapshot().evictionCounts.frames == 1
            && bounded.settlementMetricsSummary().macroSequence == 2)
    try! bounded.clearSettlementMetrics()
    check("settlement clear retains feature", bounded.settlementMetricsEnabled)
    check("settlement clear resets history", bounded.settlementMetricsSnapshot().frames.isEmpty
        && bounded.settlementMetricsSnapshot().evictionCounts.frames == 0)
    check("settlement clear preserves sequence",
          bounded.settlementMetricsSummary().macroSequence == 2)
    try! bounded.setSettlementMetricsEnabled(false)
    check("settlement disable removes active state", !bounded.settlementMetricsEnabled)
    check("settlement disable returns checkpoint v2", try! bounded.makeCheckpoint().schemaVersion == 2)

    var incomplete = settlementSession(id: "settlement-incomplete", ledgerEvents: 10)
    try! incomplete.setSettlementMetricsEnabled(true)
    for _ in 0..<4 {
        _ = try! advanceSettlementTick(&incomplete, recorder: &noRecorder)
    }
    let incompleteFrame = incomplete.settlementMetricsSnapshot().frames[0]
    check("settlement incomplete ledger coverage", !incompleteFrame.causalCoverageComplete)
    check("settlement incomplete condition", incompleteFrame.condition == .incomplete
        && incompleteFrame.reasonCode == "causal_window_incomplete")
    check("settlement events excluded from activity", incompleteFrame.social.eventDelta == 0
        && incompleteFrame.physical.eventDelta == 0
        && incompleteFrame.cooperation.eventDelta == 0)
    let observedConditions = Set(
        [frame1.condition, frames[1].condition, frames[2].condition,
         activeFrame.condition, strainedFrame.condition, incompleteFrame.condition]
    )
    check("settlement classifier covers five fixture conditions",
          observedConditions == Set(AgentSettlementCondition.allCases))
}
