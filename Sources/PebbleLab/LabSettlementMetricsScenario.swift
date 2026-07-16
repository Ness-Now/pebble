import Foundation
import PebbleAgents

private struct SettlementScenarioCheck: Codable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

private struct SettlementScenarioInvariantReport: Encodable, Equatable {
    let schemaVersion = 3
    let scenario: String
    let seed: UInt32
    let success: Bool
    let checks: [SettlementScenarioCheck]
}

private struct SettlementScenarioSummary: Encodable, Equatable {
    let schemaVersion = 3
    let scenario: String
    let seed: UInt32
    let simulationID: String
    let settlementID: String
    let macroInterval: Int
    let macroSequence: UInt64
    let pulseTicks: [Int]
    let frameIDs: [String]
    let conditions: [String]
    let population: Int
    let residents: Int
    let arrivalTick: Int
    let movementTicks: [Int]
    let checkpointSchema: Int
    let checkpointTick: Int
    let replaySchema: Int
    let replayRecords: Int
    let behavioralDigest: String
    let settlementDigest: String
    let populationDigest: String
    let durableDigest: String
    let causalDigest: String
}

private struct SettlementBehaviorABReport: Codable, Equatable {
    let seed: UInt32
    let ticks: Int
    let metricsOffDigest: String
    let metricsOnDigest: String
    let equal: Bool
    let agentSnapshotsEqual: Bool
    let movementTicksEqual: Bool
    let arrivalTickEqual: Bool
    let populationEqual: Bool
    let conservationEqual: Bool
}

private struct SettlementDigestReport: Codable, Equatable {
    let behavior: String
    let settlement: String
    let population: String
    let durable: String
    let causal: String
}

private struct SettlementCheckpointManifest: Codable, Equatable {
    let schemaVersion: Int
    let checkpointID: String
    let simulationID: String
    let tick: Int
    let semanticDigest: String
    let storageDigest: String
    let byteLength: Int
}

private let metricsAnchor = AgentPosition(x: 0, y: 64, z: 0)
private let metricsReception = AgentPosition(x: 20, y: 64, z: 0)
private let metricsRoute = (20...27).reversed().map {
    AgentPosition(x: $0, y: 64, z: 0)
}

private func metricsAgent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.2, safety: 1),
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

private func metricsSession(
    seed: UInt32,
    id: String,
    metricsEnabled: Bool
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
        seed: seed,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 128),
        survivalConfiguration: survival
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            metricsAgent("agent_0", x: -30),
            metricsAgent("agent_1", x: -15),
            metricsAgent("agent_2", x: 0),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: metricsAnchor,
        receptionPosition: metricsReception
    )
    if metricsEnabled {
        try! session.setSettlementMetricsEnabled(true)
    }
    return session
}

private func metricsAdmissionObservation() -> AgentMigrationWorldObservation {
    AgentMigrationWorldObservation(
        worldTick: 0,
        candidateIndex: 0,
        entryPosition: metricsRoute[0],
        receptionPosition: metricsReception,
        route: metricsRoute,
        entryChunkReady: true,
        entrySafe: true,
        entryUnoccupied: true,
        receptionChunkReady: true,
        receptionSafe: true,
        receptionUnoccupied: true
    )
}

private func metricsColumn(_ position: AgentPosition) -> AgentWorldColumnObservation {
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

private func metricsPerception(
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
            column: metricsColumn(target),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
    }
    let world = try! AgentWorldObservation(
        worldTick: worldTick,
        position: position,
        center: metricsColumn(position),
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
            target: metricsReception,
            radius: 8,
            cells: metricsRoute.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

@discardableResult
private func metricsStep(
    session: inout AgentSimulationSession,
    recorder: inout AgentReplayRecorder?
) throws -> [AgentMovementOutcome] {
    let migrant = session.snapshot().agents.first { $0.id == "agent_3" }
    let migrationActive = session.migrationSnapshot().migrations.contains {
        $0.status == .admitted || $0.status == .inTransit
    }
    let perceptions = migrationActive && migrant != nil
        ? [metricsPerception(position: migrant!.position, worldTick: session.tick + 1)]
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

private func metricsBehaviorDigest(_ session: AgentSimulationSession) -> String {
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
            "\($0.memoryCount)",
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

private func writeMetricsJSON<T: Encodable>(_ value: T, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    var data = try encoder.encode(value)
    data.append(0x0a)
    try data.write(to: url, options: .atomic)
}

func runSettlementMetricsMultiscaleSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("settlement_metrics_multiscale_smoke requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        guard (try FileManager.default.contentsOfDirectory(atPath: root.path)).isEmpty else {
            fail("settlement metrics output directory must be empty: \(outPath)")
        }
    } catch {
        fail("failed to prepare settlement metrics output: \(error)")
    }

    var direct = metricsSession(
        seed: options.seed,
        id: "settlement-metrics-\(options.seed)",
        metricsEnabled: true
    )
    _ = try! direct.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: metricsAdmissionObservation()
    )
    var noRecorder: AgentReplayRecorder?
    var movementTicks: [Int] = []
    for _ in 0..<4 {
        let outcomes = try! metricsStep(session: &direct, recorder: &noRecorder)
        if outcomes.contains(where: { $0.agentId == "agent_3" && $0.status == .moved }) {
            movementTicks.append(direct.tick)
        }
    }
    let checkpoint = try! direct.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let checkpointStorageDigest = AgentCheckpointDigest.sha256(checkpointBytes)
    var recorder: AgentReplayRecorder? = try! AgentReplayRecorder(
        checkpoint: checkpoint,
        session: direct
    )
    for _ in 4..<12 {
        let outcomes = try! metricsStep(session: &direct, recorder: &recorder)
        if outcomes.contains(where: { $0.agentId == "agent_3" && $0.status == .moved }) {
            movementTicks.append(direct.tick)
        }
    }
    let journal = try! recorder!.journal(
        named: AgentCheckpointName(rawValue: "settlement-continuation")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: checkpoint,
        journal: journal
    )

    var metricsOff = metricsSession(
        seed: options.seed,
        id: "settlement-behavior-ab-\(options.seed)",
        metricsEnabled: false
    )
    var metricsOn = metricsSession(
        seed: options.seed,
        id: "settlement-behavior-ab-\(options.seed)",
        metricsEnabled: true
    )
    _ = try! metricsOff.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: metricsAdmissionObservation()
    )
    _ = try! metricsOn.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: metricsAdmissionObservation()
    )
    var offMovementTicks: [Int] = []
    var onMovementTicks: [Int] = []
    for _ in 0..<12 {
        let offOutcomes = try! metricsStep(session: &metricsOff, recorder: &noRecorder)
        let onOutcomes = try! metricsStep(session: &metricsOn, recorder: &noRecorder)
        if offOutcomes.contains(where: { $0.agentId == "agent_3" && $0.status == .moved }) {
            offMovementTicks.append(metricsOff.tick)
        }
        if onOutcomes.contains(where: { $0.agentId == "agent_3" && $0.status == .moved }) {
            onMovementTicks.append(metricsOn.tick)
        }
    }
    let offBehavior = metricsBehaviorDigest(metricsOff)
    let onBehavior = metricsBehaviorDigest(metricsOn)
    let offPopulation = metricsOff.populationSnapshot()
    let onPopulation = metricsOn.populationSnapshot()
    let behaviorReport = SettlementBehaviorABReport(
        seed: options.seed,
        ticks: 12,
        metricsOffDigest: offBehavior,
        metricsOnDigest: onBehavior,
        equal: offBehavior == onBehavior,
        agentSnapshotsEqual: metricsOff.snapshot().agents == metricsOn.snapshot().agents,
        movementTicksEqual: offMovementTicks == onMovementTicks,
        arrivalTickEqual: offPopulation.migrations.first?.arrivedTick
            == onPopulation.migrations.first?.arrivedTick,
        populationEqual: offPopulation.members.map { "\($0.agentID.rawValue):\($0.status.rawValue)" }
            == onPopulation.members.map { "\($0.agentID.rawValue):\($0.status.rawValue)" },
        conservationEqual: metricsOff.conservationSnapshot() == metricsOn.conservationSnapshot()
    )

    let metrics = direct.settlementMetricsSnapshot()
    let frames = metrics.frames
    let population = direct.populationSnapshot()
    let migration = population.migrations.first!
    let causal = direct.causalLedgerSnapshot()
    let durableDigest = try! direct.durableStateDigest()

    let v1Configuration = try! AgentSessionConfiguration(
        seed: options.seed,
        memoryPolicy: .bounded(maxEntries: 16)
    )
    let v1 = try! AgentSimulationSession(
        configuration: v1Configuration,
        agents: [metricsAgent("agent_0", x: 0)],
        simulationID: try! AgentSimulationID(validating: "settlement-v1-\(options.seed)"),
        causalLedgerPolicy: .bounded(maxEvents: 64)
    )
    let v1Checkpoint = try! v1.makeCheckpoint()
    let v1BytesA = try! AgentCheckpointCodec.encode(v1Checkpoint)
    let v1BytesB = try! AgentCheckpointCodec.encode(try! v1.makeCheckpoint())
    let v2 = metricsSession(
        seed: options.seed,
        id: "settlement-v2-\(options.seed)",
        metricsEnabled: false
    )
    let v2Checkpoint = try! v2.makeCheckpoint()
    let v2BytesA = try! AgentCheckpointCodec.encode(v2Checkpoint)
    let v2BytesB = try! AgentCheckpointCodec.encode(try! v2.makeCheckpoint())

    var checks: [SettlementScenarioCheck] = []
    func add(_ name: String, _ passed: Bool, _ detail: String = "") {
        checks.append(SettlementScenarioCheck(name: name, passed: passed, detail: detail))
    }
    add("macro_interval", metrics.configuration?.macroIntervalTicks == 4)
    add("pulse_boundaries", frames.map(\.toTickInclusive) == [4, 8, 12])
    add("macro_sequence", frames.map { $0.macroSequence.rawValue } == [1, 2, 3])
    add("frame_ids", frames.map(\.frameID.rawValue) == [
        "settlement-main/frame-00000001-t4",
        "settlement-main/frame-00000002-t8",
        "settlement-main/frame-00000003-t12",
    ])
    add("classification_exhaustive", frames.allSatisfy {
        $0.activity.classifications.count == $0.population.members
            && $0.activity.urgentCount + $0.activity.migratingCount
                + $0.activity.engagedCount + $0.activity.stableCount
                == $0.population.members
    })
    add("classification_sorted", frames.allSatisfy {
        $0.activity.classifications.map(\.agentID)
            == $0.activity.classifications.map(\.agentID).sorted()
    })
    add("fixed_point_stable", frames.allSatisfy {
        $0.welfare.hunger.count == 4 && $0.welfare.fatigue.count == 4
    })
    add("frame_one_transitioning", frames[0].condition == .transitioning
        && frames[0].population.migrants == 1
        && frames[0].throughput.movementDelta == 4)
    add("frame_two_arrival", frames[1].condition == .transitioning
        && frames[1].population.arrivalDelta == 1
        && frames[1].population.residents == 4)
    add("frame_three_stable", frames[2].condition == .stable
        && frames[2].activity.stableCount == 4
        && frames[2].throughput.movementDelta == 0)
    add("causal_coverage", frames.allSatisfy(\.causalCoverageComplete))
    add("no_feedback", behaviorReport.equal && behaviorReport.agentSnapshotsEqual)
    add("world_material_unchanged", direct.conservationSnapshot().harvestedTotal == 0
        && direct.conservationSnapshot().constructedTotal == 0)
    add("checkpoint_v3", checkpoint.schemaVersion == 3
        && checkpoint.tick.rawValue == 4
        && checkpoint.durableState.populationRegistry != nil
        && checkpoint.durableState.settlementMetricsState != nil)
    add("checkpoint_deterministic", checkpointBytes
        == (try! AgentCheckpointCodec.encode(checkpoint)))
    add("restore_v3", try! AgentSimulationSession.restoring(checkpoint)
        .durableStateBytes() == checkpoint.durableStateBytesForMetricsScenario)
    add("replay_v3", journal.manifest.schemaVersion == 3
        && replayed.report.verified)
    add("replay_exact", try! replayed.session.durableStateBytes()
        == direct.durableStateBytes())
    add("history_bounded", metrics.frames.count <= 16)
    add("v1_byte_compatibility", v1Checkpoint.schemaVersion == 1
        && v1BytesA == v1BytesB
        && !String(data: v1BytesA, encoding: .utf8)!.contains("settlementMetricsState"))
    add("v2_byte_compatibility", v2Checkpoint.schemaVersion == 2
        && v2BytesA == v2BytesB
        && !String(data: v2BytesA, encoding: .utf8)!.contains("settlementMetricsState"))
    add("behavior_ab", behaviorReport.equal
        && behaviorReport.movementTicksEqual
        && behaviorReport.arrivalTickEqual
        && behaviorReport.populationEqual
        && behaviorReport.conservationEqual)

    let summary = SettlementScenarioSummary(
        scenario: options.scenario,
        seed: options.seed,
        simulationID: direct.simulationID.rawValue,
        settlementID: metrics.settlementID!.rawValue,
        macroInterval: metrics.configuration!.macroIntervalTicks,
        macroSequence: metrics.macroSequence.rawValue,
        pulseTicks: frames.map(\.toTickInclusive),
        frameIDs: frames.map(\.frameID.rawValue),
        conditions: frames.map(\.condition.rawValue),
        population: population.members.count,
        residents: population.members.filter {
            $0.status == .founderResident || $0.status == .resident
        }.count,
        arrivalTick: migration.arrivedTick!,
        movementTicks: movementTicks,
        checkpointSchema: checkpoint.schemaVersion,
        checkpointTick: checkpoint.tick.rawValue,
        replaySchema: journal.manifest.schemaVersion,
        replayRecords: journal.records.count,
        behavioralDigest: onBehavior,
        settlementDigest: metrics.digest,
        populationDigest: population.digest,
        durableDigest: durableDigest.rawValue,
        causalDigest: causal.summary.digest
    )
    let invariant = SettlementScenarioInvariantReport(
        scenario: options.scenario,
        seed: options.seed,
        success: checks.allSatisfy(\.passed),
        checks: checks
    )
    let settlementChain = causal.events.filter { event in
        [
            AgentCausalEventKind.settlementMetricsInitialized,
            .settlementMacroPulse,
            .settlementMetricsCleared,
            .settlementMetricsDisabled,
        ].contains(event.kind)
    }
    let classifications = frames.flatMap(\.activity.classifications)

    do {
        try writeMetricsJSON(
            metrics,
            to: root.appendingPathComponent("settlement_metrics_state.json")
        )
        try writeMetricsJSON(
            frames,
            to: root.appendingPathComponent("settlement_metric_frames.json")
        )
        try writeMetricsJSON(
            classifications,
            to: root.appendingPathComponent("settlement_agent_classifications.json")
        )
        try writeMetricsJSON(
            settlementChain,
            to: root.appendingPathComponent("settlement_macro_causal_chain.json")
        )
        try writeMetricsJSON(
            behaviorReport,
            to: root.appendingPathComponent("settlement_behavior_ab.json")
        )
        let checkpointDirectory = root.appendingPathComponent(
            "settlement_checkpoint_v3",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: checkpointDirectory,
            withIntermediateDirectories: true
        )
        try writeMetricsJSON(
            SettlementCheckpointManifest(
                schemaVersion: checkpoint.schemaVersion,
                checkpointID: checkpoint.checkpointID.rawValue,
                simulationID: checkpoint.simulationID.rawValue,
                tick: checkpoint.tick.rawValue,
                semanticDigest: checkpoint.semanticDigest.rawValue,
                storageDigest: checkpointStorageDigest.rawValue,
                byteLength: checkpointBytes.count
            ),
            to: checkpointDirectory.appendingPathComponent("manifest.json")
        )
        try AgentCheckpointCodec.encode(checkpoint.durableState).write(
            to: checkpointDirectory.appendingPathComponent("session.json"),
            options: .atomic
        )
        let replayDirectory = root.appendingPathComponent(
            "settlement_replay_v3",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: replayDirectory,
            withIntermediateDirectories: true
        )
        try writeMetricsJSON(
            journal.manifest,
            to: replayDirectory.appendingPathComponent("manifest.json")
        )
        try AgentReplayCodec.encodeRecords(journal.records).write(
            to: replayDirectory.appendingPathComponent("operations.ndjson"),
            options: .atomic
        )
        try writeMetricsJSON(
            summary,
            to: root.appendingPathComponent("settlement_metrics_summary.json")
        )
        try writeMetricsJSON(
            SettlementDigestReport(
                behavior: summary.behavioralDigest,
                settlement: summary.settlementDigest,
                population: summary.populationDigest,
                durable: summary.durableDigest,
                causal: summary.causalDigest
            ),
            to: root.appendingPathComponent("settlement_metrics_digest.json")
        )
        try writeMetricsJSON(
            invariant,
            to: root.appendingPathComponent("settlement_metrics_invariant_report.json")
        )
    } catch {
        fail("failed to write settlement metrics outputs: \(error)")
    }

    guard invariant.success else {
        for check in checks where !check.passed {
            print("FAIL \(check.name): \(check.detail)")
        }
        exit(1)
    }
    print(
        "settlement_metrics_multiscale_smoke PASS macro=\(summary.macroSequence) "
            + "pulses=\(summary.pulseTicks.map(String.init).joined(separator: ",")) "
            + "population=\(summary.population) digest=\(summary.settlementDigest)"
    )
    exit(0)
}

private extension AgentSessionCheckpoint {
    var durableStateBytesForMetricsScenario: Data {
        try! AgentCheckpointCodec.encode(durableState)
    }
}
