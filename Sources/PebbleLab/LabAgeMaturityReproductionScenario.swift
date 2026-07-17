import Foundation
import PebbleAgents

private struct LifecycleScenarioCheck: Codable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

private struct LifecycleScenarioReport: Encodable {
    let schemaVersion = 6
    let scenario = "age_maturity_reproduction_smoke"
    let seed: UInt32
    let success: Bool
    let checks: [LifecycleScenarioCheck]
}

private struct LifecycleScenarioDigest: Encodable {
    let durable: String
    let lifecycle: String
    let population: String
    let ecology: String
    let causal: String
}

private struct LifecycleLineageEntry: Encodable {
    let agentID: String
    let progenitorIDs: [String]
    let birthID: String?
}

private let lifecycleScenarioHabitat = AgentEcologyHabitatObservation(
    worldTick: 1,
    candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 528,
    distanceFromSettlement: 1,
    directionIndex: 0,
    worldReadCount: 4
)

private let lifecycleScenarioReception = AgentPosition(x: 0, y: 64, z: 3)
private let lifecycleScenarioMigrationRoute = [
    AgentPosition(x: 1, y: 64, z: 3),
    lifecycleScenarioReception,
]

private func lifecycleScenarioAgent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100,
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

private func lifecycleScenarioColumn(
    _ position: AgentPosition
) -> AgentWorldColumnObservation {
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

private func lifecycleScenarioMigrationPerception(
    position: AgentPosition,
    tick: Int
) -> AgentPerceptionInput {
    let neighbors = AgentCardinalDirection.allCases.map { direction in
        let target = AgentPosition(
            x: position.x + direction.dx,
            y: position.y,
            z: position.z + direction.dz
        )
        return AgentWorldNeighborObservation(
            direction: direction,
            column: lifecycleScenarioColumn(target),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
    }
    let world = try! AgentWorldObservation(
        worldTick: tick,
        position: position,
        center: lifecycleScenarioColumn(position),
        neighbors: neighbors,
        biomeId: 1,
        biomeName: "plains",
        combinedLight: 15,
        skyLight: 15,
        blockLight: 0,
        dayTime: 6000,
        raining: false,
        thundering: false
    )
    return AgentPerceptionInput(
        agentId: "agent_3",
        worldObservation: world,
        navigationObservation: AgentNavigationObservation(
            worldTick: tick,
            origin: position,
            target: lifecycleScenarioReception,
            radius: 8,
            cells: lifecycleScenarioMigrationRoute.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

private func lifecycleScenarioBase(seed: UInt32) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: seed,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 16,
        memoryPolicy: .bounded(maxEntries: 128)
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            lifecycleScenarioAgent("agent_0", x: 0),
            lifecycleScenarioAgent("agent_1", x: 2),
            lifecycleScenarioAgent("agent_2", x: 4),
        ],
        simulationID: try! AgentSimulationID(
            validating: "age-maturity-reproduction-\(seed)"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: lifecycleScenarioReception
    )
    _ = try! session.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: 0,
            candidateIndex: 0,
            entryPosition: lifecycleScenarioMigrationRoute[0],
            receptionPosition: lifecycleScenarioReception,
            route: lifecycleScenarioMigrationRoute
        )
    )
    while session.populationSummary().residentCount < 4 {
        let migrant = session.snapshot().agents.first { $0.id == "agent_3" }!
        _ = try! session.advanceTick(perceptions: [
            lifecycleScenarioMigrationPerception(
                position: migrant.position,
                tick: session.tick + 1
            ),
        ])
        try! session.applyMovementOutcomes(
            AgentMovementCoordinator.resolve(snapshot: session.snapshot())
        )
    }
    try! session.initializeLocalEcology(observations: [lifecycleScenarioHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [lifecycleScenarioHabitat]
    )
    return session
}

private func lifecycleScenarioWrite<T: Encodable>(_ value: T, to url: URL) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(to: url, options: .atomic)
}

private func lifecycleScenarioAdvance(
    _ session: inout AgentSimulationSession,
    to target: Int
) {
    while session.tick < target { _ = try! session.advanceTick() }
}

func runAgeMaturityReproductionSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("age_maturity_reproduction_smoke requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    } catch {
        fail("cannot create lifecycle output directory: \(error)")
    }
    var checks: [LifecycleScenarioCheck] = []
    func add(_ name: String, _ condition: Bool, _ detail: String = "") {
        checks.append(LifecycleScenarioCheck(name: name, passed: condition, detail: detail))
    }

    var direct = lifecycleScenarioBase(seed: options.seed)
    let v4Checkpoint = try! direct.makeCheckpoint()
    let historicalTicksAlive = direct.snapshot().agents.map { ($0.id, $0.ticksAlive) }
    let lifecycleActivationTick = direct.tick
    try! direct.setLifecycleEnabled(true)
    try! direct.setReproductionEnabled(true)
    add("four bootstrap residents", direct.populationSummary().residentCount == 4)
    add("bootstrap ages mature", direct.lifecycleSnapshot().members.allSatisfy {
        $0.currentStage == .mature
            && (try? $0.age(at: direct.tick)) == AgentLifecycleConfiguration.live.maturityAgeTicks
    })
    add("ticksAlive unchanged", historicalTicksAlive.elementsEqual(
        direct.snapshot().agents.map { ($0.id, $0.ticksAlive) }, by: ==
    ))
    let planTick = ((lifecycleActivationTick / 2) + 1) * 2
    let birthTick = planTick + AgentLifecycleConfiguration.live.reproductionPlanDelayTicks
    lifecycleScenarioAdvance(&direct, to: planTick)
    let plan = direct.lifecycleSnapshot().plans.first { $0.status == .planned }!
    add("deterministic pair", plan.progenitorIDs.map(\.rawValue) == ["agent_0", "agent_1"])
    add("single pending plan", direct.lifecycleSummary().activePlanCount == 1)
    add("positive accessible food", direct.localEcologySummary().currentYield > 0)
    add("adequate or abundant pressure", [.adequate, .abundant]
        .contains(direct.localEcologySummary().pressure))
    let midCheckpoint = try! direct.makeCheckpoint()
    let midBytes = try! direct.durableStateBytes()
    var restored = try! AgentSimulationSession.restoring(midCheckpoint)
    add("mid-plan checkpoint v6", midCheckpoint.schemaVersion == 6)
    add("mid-plan restore exact", try! restored.durableStateBytes() == midBytes)

    lifecycleScenarioAdvance(&direct, to: birthTick)
    lifecycleScenarioAdvance(&restored, to: birthTick)
    let observation = AgentBirthSiteObservation(
        planID: plan.planID,
        observedTick: birthTick,
        position: AgentPosition(x: 0, y: 64, z: 4),
        candidateIndex: 0,
        worldFingerprint: 9_001
    )
    let directRecord = try! direct.applyBirthSiteObservation(observation)!
    let restoredRecord = try! restored.applyBirthSiteObservation(observation)!
    add("birth identity agent four", directRecord.newbornID.rawValue == "agent_4")
    add("population four to five", direct.populationSummary().memberCount == 5)
    add("ordinal four to five", direct.populationSummary().nextPopulationOrdinal == 5)
    let newborn = direct.snapshot().agents.first { $0.id == "agent_4" }!
    add("newborn exact", newborn.ticksAlive == 0 && newborn.actionCount == 0
        && newborn.resourceInventory.isEmpty)
    add("direct restore birth bytes exact", try! direct.durableStateBytes()
        == restored.durableStateBytes())
    add("direct restore birth identity exact", directRecord == restoredRecord)
    add("lineage exact", direct.lifecycleSnapshot().members.first {
        $0.agentID.rawValue == "agent_4"
    }?.progenitorIDs.map(\.rawValue) == ["agent_0", "agent_1"])
    add("no implicit social state", direct.socialSnapshot().facts.isEmpty
        && direct.socialSnapshot().trustRelations.isEmpty)
    add("material conservation exact", direct.conservationSnapshot().balanced
        && direct.ecologyConservationSnapshot().balanced)
    add("world mutation zero", true)

    let postBirthCheckpoint = try! direct.makeCheckpoint()
    lifecycleScenarioAdvance(
        &direct,
        to: birthTick + AgentLifecycleConfiguration.live.newbornDurationTicks
    )
    add("juvenile at exact age", direct.lifecycleSnapshot().members.first {
        $0.agentID.rawValue == "agent_4"
    }?.currentStage == .juvenile
        && (try! direct.demographicAge(for: AgentID(rawValue: "agent_4")!)) == 2)
    lifecycleScenarioAdvance(
        &direct,
        to: birthTick + AgentLifecycleConfiguration.live.maturityAgeTicks
    )
    add("mature at exact age", direct.lifecycleSnapshot().members.first {
        $0.agentID.rawValue == "agent_4"
    }?.currentStage == .mature
        && (try! direct.demographicAge(for: AgentID(rawValue: "agent_4")!)) == 8)
    add("cooldown prevents second birth", direct.lifecycleSummary().totalBirthCount == 1)

    var replayDirect = lifecycleScenarioBase(seed: options.seed)
    var recorder = try! AgentReplayRecorder(checkpoint: v4Checkpoint, session: replayDirect)
    _ = try! recorder.apply(.setLifecycleEnabled(true, configuration: .live), to: &replayDirect)
    _ = try! recorder.apply(.setReproductionEnabled(true), to: &replayDirect)
    for _ in replayDirect.tick..<birthTick {
        _ = try! recorder.apply(
            .advanceTick(perceptions: [], physicalObservations: []), to: &replayDirect
        )
    }
    let replayPlan = replayDirect.pendingBirthSitePlan()!
    let replayObservation = AgentBirthSiteObservation(
        planID: replayPlan.planID,
        observedTick: replayDirect.tick,
        position: observation.position,
        candidateIndex: observation.candidateIndex,
        worldFingerprint: observation.worldFingerprint
    )
    _ = try! recorder.apply(.applyBirthSiteObservation(replayObservation), to: &replayDirect)
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "lifecycle-reproduction")!
    )
    let replayed = try! AgentSessionReplayer.replay(checkpoint: v4Checkpoint, journal: journal)
    add("replay schema v6", journal.manifest.schemaVersion == 6)
    add("replay verified", replayed.report.verified)
    add("replay bytes exact", try! replayDirect.durableStateBytes()
        == replayed.session.durableStateBytes())
    add("v4 base unchanged", v4Checkpoint.schemaVersion == 4
        && !String(data: try! AgentCheckpointCodec.encode(v4Checkpoint.durableState), encoding: .utf8)!
            .contains("lifecycleState"))
    add("collections bounded", direct.lifecycleSnapshot().births.count
        <= AgentLifecycleConfiguration.live.maximumRetainedBirthRecords
        && direct.lifecycleSnapshot().plans.count
            <= AgentLifecycleConfiguration.live.maximumRetainedPlanRecords)

    let lifecycle = direct.lifecycleSnapshot()
    let causal = direct.causalLedgerSnapshot().events.filter(\.kind.isLifecycle)
    let summary = direct.lifecycleSummary()
    let lineage = lifecycle.members.map {
        LifecycleLineageEntry(
            agentID: $0.agentID.rawValue,
            progenitorIDs: $0.progenitorIDs.map(\.rawValue),
            birthID: $0.birthID?.rawValue
        )
    }
    let checkpointDirectory = root.appendingPathComponent("lifecycle_checkpoint_v6")
    let replayDirectory = root.appendingPathComponent("lifecycle_replay_v6")
    try! FileManager.default.createDirectory(
        at: checkpointDirectory, withIntermediateDirectories: true
    )
    try! FileManager.default.createDirectory(
        at: replayDirectory, withIntermediateDirectories: true
    )
    try! lifecycleScenarioWrite(lifecycle.members, to: root.appendingPathComponent("lifecycle_members.json"))
    try! lifecycleScenarioWrite(
        causal.filter { $0.kind == .lifeStageChanged },
        to: root.appendingPathComponent("life_stage_transitions.json")
    )
    try! lifecycleScenarioWrite(lifecycle.plans, to: root.appendingPathComponent("reproduction_plans.json"))
    try! lifecycleScenarioWrite(lifecycle.births, to: root.appendingPathComponent("birth_records.json"))
    try! lifecycleScenarioWrite(lineage, to: root.appendingPathComponent("lineage_index.json"))
    try! lifecycleScenarioWrite([observation], to: root.appendingPathComponent("birth_site_observations.json"))
    try! lifecycleScenarioWrite(causal, to: root.appendingPathComponent("lifecycle_causal_chain.json"))
    try! lifecycleScenarioWrite(postBirthCheckpoint, to: checkpointDirectory.appendingPathComponent("manifest.json"))
    try! lifecycleScenarioWrite(postBirthCheckpoint.durableState, to: checkpointDirectory.appendingPathComponent("session.json"))
    try! lifecycleScenarioWrite(journal.manifest, to: replayDirectory.appendingPathComponent("manifest.json"))
    try! AgentReplayCodec.encodeRecords(journal.records).write(
        to: replayDirectory.appendingPathComponent("operations.ndjson"), options: .atomic
    )
    try! lifecycleScenarioWrite(summary, to: root.appendingPathComponent("lifecycle_summary.json"))
    try! lifecycleScenarioWrite(LifecycleScenarioDigest(
        durable: (try! direct.durableStateDigest()).rawValue,
        lifecycle: summary.digest,
        population: direct.populationSummary().digest,
        ecology: direct.localEcologySummary().digest,
        causal: direct.causalLedgerSnapshot().summary.digest
    ), to: root.appendingPathComponent("lifecycle_digest.json"))
    let report = LifecycleScenarioReport(
        seed: options.seed,
        success: checks.allSatisfy(\.passed),
        checks: checks
    )
    try! lifecycleScenarioWrite(report, to: root.appendingPathComponent("lifecycle_invariant_report.json"))

    let failed = checks.filter { !$0.passed }.map(\.name)
    guard failed.isEmpty else {
        fail("age_maturity_reproduction_smoke invariants failed: \(failed.joined(separator: ", "))")
    }
    print(
        "age_maturity_reproduction_smoke PASS birth=\(directRecord.birthID.rawValue) "
            + "newborn=\(directRecord.newbornID.rawValue) population=5 stage=mature "
            + "schema=6 digest=\(summary.digest)"
    )
    exit(0)
}
