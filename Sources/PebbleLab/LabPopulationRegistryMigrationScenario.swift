import Foundation
import PebbleAgents

private struct PopulationScenarioCheck: Codable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

private struct PopulationScenarioInvariantReport: Encodable, Equatable {
    let schemaVersion = 2
    let scenario: String
    let seed: UInt32
    let success: Bool
    let checks: [PopulationScenarioCheck]
}

private struct PopulationScenarioSummary: Encodable, Equatable {
    let schemaVersion = 2
    let scenario: String
    let seed: UInt32
    let simulationID: String
    let settlementID: String
    let capacity: Int
    let founders: Int
    let residents: Int
    let members: Int
    let migrantID: String
    let migrationID: String
    let entry: AgentPosition
    let reception: AgentPosition
    let movementTicks: [Int]
    let arrivalTick: Int
    let nextPopulationOrdinal: Int
    let checkpointSchema: Int
    let checkpointTick: Int
    let checkpointRouteCursor: Int
    let replaySchema: Int
    let replayRecords: Int
    let finalCausalSequence: UInt64
    let finalCausalDigest: String
    let durableDigest: String
    let populationDigest: String
    let noWorldMutation: Bool
}

private struct PopulationRouteReport: Codable, Equatable {
    let migrationID: AgentMigrationID
    let positions: [AgentPosition]
    let movementTicks: [Int]
    let cursorAtCheckpoint: Int
    let finalCursor: Int
}

private struct PopulationDigestReport: Codable, Equatable {
    let population: String
    let migration: String
    let durable: String
    let causal: String
}

private let populationScenarioReception = AgentPosition(x: 0, y: 64, z: 3)
private let populationScenarioEntry = AgentPosition(x: 4, y: 64, z: 3)
private let populationScenarioRoute = [
    AgentPosition(x: 4, y: 64, z: 3),
    AgentPosition(x: 3, y: 64, z: 3),
    AgentPosition(x: 2, y: 64, z: 3),
    AgentPosition(x: 1, y: 64, z: 3),
    AgentPosition(x: 0, y: 64, z: 3),
]

private func populationScenarioAgent(_ id: String, x: Int) -> AgentSessionAgentState {
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

private func populationScenarioSession(
    seed: UInt32,
    id: String,
    populationConfiguration: AgentPopulationConfiguration = .live
) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: seed,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 128)
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            populationScenarioAgent("agent_0", x: 0),
            populationScenarioAgent("agent_1", x: 2),
            populationScenarioAgent("agent_2", x: 4),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: populationScenarioReception,
        configuration: populationConfiguration
    )
    return session
}

private func populationScenarioAdmissionObservation(
    entryChunkReady: Bool = true,
    entryUnoccupied: Bool = true,
    receptionUnoccupied: Bool = true,
    route: [AgentPosition] = populationScenarioRoute
) -> AgentMigrationWorldObservation {
    AgentMigrationWorldObservation(
        worldTick: 0,
        candidateIndex: 0,
        entryPosition: populationScenarioEntry,
        receptionPosition: populationScenarioReception,
        route: route,
        entryChunkReady: entryChunkReady,
        entrySafe: true,
        entryUnoccupied: entryUnoccupied,
        receptionChunkReady: true,
        receptionSafe: true,
        receptionUnoccupied: receptionUnoccupied
    )
}

private func populationScenarioColumn(
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

private func populationScenarioPerception(
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
            column: populationScenarioColumn(target),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
    }
    let world = try! AgentWorldObservation(
        worldTick: tick,
        position: position,
        center: populationScenarioColumn(position),
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
            target: populationScenarioReception,
            radius: 8,
            cells: populationScenarioRoute.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

@discardableResult
private func populationScenarioStep(
    session: inout AgentSimulationSession,
    recorder: inout AgentReplayRecorder?
) throws -> AgentMovementOutcome {
    let position = session.snapshot().agents.first { $0.id == "agent_3" }!.position
    let perception = populationScenarioPerception(position: position, tick: session.tick + 1)
    if recorder != nil {
        _ = try recorder!.apply(
            .advanceTick(perceptions: [perception], physicalObservations: []),
            to: &session
        )
    } else {
        _ = try session.advanceTick(perceptions: [perception])
    }
    let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
    let migrant = outcomes.first { $0.agentId == "agent_3" }!
    if recorder != nil {
        _ = try recorder!.apply(.movementOutcomes(outcomes), to: &session)
    } else {
        try session.applyMovementOutcomes(outcomes)
    }
    return migrant
}

private func populationScenarioBinding(
    seed: UInt32,
    checkpoint: AgentSessionCheckpoint
) -> AgentCheckpointWorldBinding {
    let routeCells = Set(
        populationScenarioRoute
            + checkpoint.durableState.agents.map(\.position)
            + checkpoint.durableState.agents.map(\.homePosition)
    )
    return try! AgentCheckpointWorldBinding(
        worldID: "headless-population-\(seed)",
        storageIdentity: "headless-population-storage-\(seed)",
        seed: seed,
        dimension: 0,
        anchor: AgentPosition(x: 0, y: 64, z: 0),
        simulationID: checkpoint.simulationID,
        checkpointTick: checkpoint.tick,
        cells: routeCells.map {
            AgentCheckpointWorldCell(position: $0, blockFingerprint: 0)
        }
    )
}

private func populationScenarioManifest(
    seed: UInt32,
    checkpoint: AgentSessionCheckpoint,
    bytes: Data
) -> AgentCheckpointManifest {
    try! AgentCheckpointManifest(
        name: AgentCheckpointName(rawValue: "migration-mid-route")!,
        checkpoint: checkpoint,
        storageDigest: AgentCheckpointDigest.sha256(bytes),
        byteLength: bytes.count,
        restartSafe: true,
        restartSafetyReason: "migration contains agent movement only; no World mutation receipts",
        worldBinding: populationScenarioBinding(seed: seed, checkpoint: checkpoint),
        orchestration: AgentCheckpointLiveOrchestration(
            cognitiveHz: 4,
            wasPaused: true,
            movementEnabled: true,
            autoInteractionEnabled: false,
            economyAutoEnabled: false,
            focusedAgentID: "agent_0"
        )
    )
}

private func writePopulationScenarioJSON<T: Encodable>(
    _ value: T,
    to url: URL
) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(
        to: url,
        options: .atomic
    )
}

private func writePopulationCheckpoint(
    root: URL,
    manifest: AgentCheckpointManifest,
    bytes: Data
) throws {
    let directory = root.appendingPathComponent(
        "population_checkpoint_v2",
        isDirectory: true
    )
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: false
    )
    try bytes.write(to: directory.appendingPathComponent("session.json"), options: .atomic)
    try writePopulationScenarioJSON(
        manifest,
        to: directory.appendingPathComponent("manifest.json")
    )
}

private func writePopulationReplay(
    root: URL,
    journal: AgentReplayJournal
) throws {
    let directory = root.appendingPathComponent("population_replay", isDirectory: true)
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: false
    )
    try AgentReplayCodec.encodeRecords(journal.records).write(
        to: directory.appendingPathComponent("operations.ndjson"),
        options: .atomic
    )
    try writePopulationScenarioJSON(
        journal.manifest,
        to: directory.appendingPathComponent("manifest.json")
    )
}

func runPopulationRegistryMigrationSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("population_registry_migration_smoke requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        guard (try FileManager.default.contentsOfDirectory(atPath: root.path)).isEmpty else {
            fail("population migration output directory must be empty: \(outPath)")
        }
    } catch {
        fail("failed to prepare population migration output: \(error)")
    }

    var direct = populationScenarioSession(
        seed: options.seed,
        id: "population-registry-migration-\(options.seed)"
    )
    let bootstrap = direct.populationSnapshot()
    let baseCheckpoint = try! direct.makeCheckpoint()
    var recorder: AgentReplayRecorder? = try! AgentReplayRecorder(
        checkpoint: baseCheckpoint,
        session: direct
    )
    _ = try! recorder!.apply(
        .admitMigration(
            intent: AgentMigrationAdmissionIntent(),
            observation: populationScenarioAdmissionObservation()
        ),
        to: &direct
    )
    var movementTicks: [Int] = []
    for _ in 0..<2 {
        movementTicks.append(
            try! populationScenarioStep(session: &direct, recorder: &recorder).tick
        )
    }
    let midCheckpoint = try! direct.makeCheckpoint()
    let midCheckpointBytes = try! AgentCheckpointCodec.encode(midCheckpoint)
    let midManifest = populationScenarioManifest(
        seed: options.seed,
        checkpoint: midCheckpoint,
        bytes: midCheckpointBytes
    )
    let midCursor = direct.migrationSnapshot().migrations.first!.routeCursor

    var restoredContinuation = try! AgentSimulationSession.restoring(midCheckpoint)
    var noRecorder: AgentReplayRecorder?
    for _ in 0..<2 {
        _ = try! populationScenarioStep(
            session: &restoredContinuation,
            recorder: &noRecorder
        )
    }
    for _ in 0..<2 {
        movementTicks.append(
            try! populationScenarioStep(session: &direct, recorder: &recorder).tick
        )
    }
    let journal = try! recorder!.journal(
        named: AgentCheckpointName(rawValue: "population-continuation")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: baseCheckpoint,
        journal: journal
    )

    let finalPopulation = direct.populationSnapshot()
    let finalMigration = direct.migrationSnapshot()
    let finalSession = direct.snapshot()
    let finalMigrant = finalSession.agents.first { $0.id == "agent_3" }!
    let finalRecord = finalMigration.migrations.first!
    let causal = direct.causalLedgerSnapshot()
    let durableDigest = try! direct.durableStateDigest()
    let v1 = try! AgentSimulationSession(
        configuration: direct.configuration,
        agents: [
            populationScenarioAgent("agent_0", x: 0),
            populationScenarioAgent("agent_1", x: 2),
            populationScenarioAgent("agent_2", x: 4),
        ],
        simulationID: try! AgentSimulationID(validating: "population-v1-\(options.seed)"),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    let v1Checkpoint = try! v1.makeCheckpoint()
    let v1BytesA = try! AgentCheckpointCodec.encode(v1Checkpoint)
    let v1BytesB = try! AgentCheckpointCodec.encode(try! v1.makeCheckpoint())

    var checks: [PopulationScenarioCheck] = []
    func add(_ name: String, _ passed: Bool, _ detail: String = "") {
        checks.append(PopulationScenarioCheck(name: name, passed: passed, detail: detail))
    }
    add("founders_exact", bootstrap.members.map(\.agentID.rawValue)
        == ["agent_0", "agent_1", "agent_2"])
    add("founders_resident", bootstrap.members.allSatisfy {
        $0.founder && $0.status == .founderResident
    })
    add("dynamic_id_stable", finalRecord.migrantID.rawValue == "agent_3")
    add("ordinal_monotone", finalPopulation.nextPopulationOrdinal == 4)
    add("capacity_bounded", finalPopulation.members.count == 4
        && finalPopulation.settlement?.capacity == 8)
    add("one_active_migration", finalPopulation.migrations.filter {
        $0.status == .admitted || $0.status == .inTransit
    }.count == 0)
    add("valid_route", finalRecord.route == populationScenarioRoute)
    add("no_teleport", movementTicks == [1, 2, 3, 4]
        && finalMigrant.movementCount == 4)
    add("arrival_exact", finalMigrant.position == populationScenarioReception
        && finalRecord.status == .arrived)
    add("resident_after_arrival", finalPopulation.members.first {
        $0.agentID.rawValue == "agent_3"
    }?.status == .resident)
    add("home_after_arrival", finalMigrant.homePosition == populationScenarioReception)
    add("no_implicit_trust", direct.trustSnapshot().relations.isEmpty)
    add("no_implicit_task", direct.cooperationSnapshot().tasks.isEmpty)
    add("no_world_mutation", finalSession.conservation.harvestedTotal == 0
        && finalSession.conservation.constructedTotal == 0)
    add("dynamic_probes_contract", direct.expectedActiveAgentIDs().map(\.rawValue)
        == ["agent_0", "agent_1", "agent_2", "agent_3"])
    add("v1_checkpoint_compatibility", v1Checkpoint.schemaVersion == 1
        && v1BytesA == v1BytesB
        && !String(data: v1BytesA, encoding: .utf8)!.contains("populationRegistry"))
    add("v2_checkpoint", midCheckpoint.schemaVersion == 2
        && midManifest.schemaVersion == 2)
    add("mid_route_checkpoint", midCheckpoint.tick.rawValue == 2 && midCursor == 2)
    add("v2_restore_exact", try! AgentSimulationSession.restoring(midCheckpoint)
        .durableStateBytes() == midCheckpoint.durableStateBytesForScenario)
    add("restart_continuation_exact", try! restoredContinuation.durableStateBytes()
        == direct.durableStateBytes())
    add("replay_schema_v2", journal.manifest.schemaVersion == 2)
    add("replay_equivalence", replayed.report.verified
        && (try! replayed.session.durableStateBytes()) == (try! direct.durableStateBytes()))
    add("deterministic_bytes", midCheckpointBytes
        == (try! AgentCheckpointCodec.encode(midCheckpoint)))
    add("collections_bounded", finalPopulation.migrations.count
        <= AgentPopulationConfiguration.live.maximumMigrationRecords)

    let summary = PopulationScenarioSummary(
        scenario: options.scenario,
        seed: options.seed,
        simulationID: direct.simulationID.rawValue,
        settlementID: finalPopulation.settlement!.settlementID.rawValue,
        capacity: finalPopulation.settlement!.capacity,
        founders: finalPopulation.members.filter(\.founder).count,
        residents: finalPopulation.members.filter {
            $0.status == .founderResident || $0.status == .resident
        }.count,
        members: finalPopulation.members.count,
        migrantID: finalRecord.migrantID.rawValue,
        migrationID: finalRecord.migrationID.rawValue,
        entry: finalRecord.entryPosition,
        reception: finalRecord.receptionPosition,
        movementTicks: movementTicks,
        arrivalTick: finalRecord.arrivedTick!,
        nextPopulationOrdinal: finalPopulation.nextPopulationOrdinal!,
        checkpointSchema: midCheckpoint.schemaVersion,
        checkpointTick: midCheckpoint.tick.rawValue,
        checkpointRouteCursor: midCursor,
        replaySchema: journal.manifest.schemaVersion,
        replayRecords: journal.records.count,
        finalCausalSequence: causal.summary.latestSequence,
        finalCausalDigest: causal.summary.digest,
        durableDigest: durableDigest.rawValue,
        populationDigest: finalPopulation.digest,
        noWorldMutation: true
    )
    let invariant = PopulationScenarioInvariantReport(
        scenario: options.scenario,
        seed: options.seed,
        success: checks.allSatisfy(\.passed),
        checks: checks
    )
    let populationKinds = Set([
        "populationRegistryInitialized", "populationMemberRegistered",
        "migrationProposed", "migrationAdmitted", "migrationStarted",
        "migrationArrived", "migrationRejected", "migrationCancelled",
        "migrationFailed", "populationStateCleared",
    ])
    let chain = causal.events.filter {
        populationKinds.contains($0.kind.rawValue) || (
            $0.kind == .movement && $0.actorID?.rawValue == "agent_3"
        )
    }

    do {
        try writePopulationScenarioJSON(
            finalPopulation,
            to: root.appendingPathComponent("population_registry.json")
        )
        try writePopulationScenarioJSON(
            finalPopulation.members,
            to: root.appendingPathComponent("population_members.json")
        )
        try writePopulationScenarioJSON(
            finalPopulation.migrations,
            to: root.appendingPathComponent("migration_records.json")
        )
        try writePopulationScenarioJSON(
            PopulationRouteReport(
                migrationID: finalRecord.migrationID,
                positions: finalRecord.route,
                movementTicks: movementTicks,
                cursorAtCheckpoint: midCursor,
                finalCursor: finalRecord.routeCursor
            ),
            to: root.appendingPathComponent("migration_route.json")
        )
        try writePopulationScenarioJSON(
            chain,
            to: root.appendingPathComponent("migration_causal_chain.json")
        )
        try writePopulationCheckpoint(
            root: root,
            manifest: midManifest,
            bytes: midCheckpointBytes
        )
        try writePopulationReplay(root: root, journal: journal)
        try writePopulationScenarioJSON(
            summary,
            to: root.appendingPathComponent("population_summary.json")
        )
        try writePopulationScenarioJSON(
            PopulationDigestReport(
                population: finalPopulation.digest,
                migration: finalMigration.digest,
                durable: durableDigest.rawValue,
                causal: causal.summary.digest
            ),
            to: root.appendingPathComponent("population_digest.json")
        )
        try writePopulationScenarioJSON(
            invariant,
            to: root.appendingPathComponent("population_invariant_report.json")
        )
    } catch {
        fail("failed to write population migration outputs: \(error)")
    }

    guard invariant.success else {
        for check in checks where !check.passed {
            print("FAIL \(check.name): \(check.detail)")
        }
        exit(1)
    }
    print(
        "population_registry_migration_smoke PASS members=\(summary.members) "
            + "migrant=\(summary.migrantID) migration=\(summary.migrationID) "
            + "arrivalTick=\(summary.arrivalTick) digest=\(summary.populationDigest)"
    )
    exit(0)
}

private extension AgentSessionCheckpoint {
    var durableStateBytesForScenario: Data {
        try! AgentCheckpointCodec.encode(durableState)
    }
}
