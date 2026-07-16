import Foundation
import PebbleAgents

private let populationReception = AgentPosition(x: 0, y: 64, z: 3)
private let populationEntry = AgentPosition(x: 4, y: 64, z: 3)
private let populationRoute = [
    AgentPosition(x: 4, y: 64, z: 3),
    AgentPosition(x: 3, y: 64, z: 3),
    AgentPosition(x: 2, y: 64, z: 3),
    AgentPosition(x: 1, y: 64, z: 3),
    AgentPosition(x: 0, y: 64, z: 3),
]

private func populationAgent(_ id: String, x: Int) -> AgentSessionAgentState {
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

private func populationSession(
    id: String = "population-migration-smoke",
    configuration: AgentPopulationConfiguration = .live
) -> AgentSimulationSession {
    let sessionConfiguration = try! AgentSessionConfiguration(
        seed: 46,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 128)
    )
    var session = try! AgentSimulationSession(
        configuration: sessionConfiguration,
        agents: [
            populationAgent("agent_0", x: 0),
            populationAgent("agent_1", x: 2),
            populationAgent("agent_2", x: 4),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: populationReception,
        configuration: configuration
    )
    return session
}

private func populationObservation(
    entryChunkReady: Bool = true,
    entrySafe: Bool = true,
    entryUnoccupied: Bool = true,
    receptionChunkReady: Bool = true,
    receptionSafe: Bool = true,
    receptionUnoccupied: Bool = true,
    route: [AgentPosition] = populationRoute,
    candidateIndex: Int = 0
) -> AgentMigrationWorldObservation {
    AgentMigrationWorldObservation(
        worldTick: 0,
        candidateIndex: candidateIndex,
        entryPosition: populationEntry,
        receptionPosition: populationReception,
        route: route,
        entryChunkReady: entryChunkReady,
        entrySafe: entrySafe,
        entryUnoccupied: entryUnoccupied,
        receptionChunkReady: receptionChunkReady,
        receptionSafe: receptionSafe,
        receptionUnoccupied: receptionUnoccupied
    )
}

private func populationColumn(_ position: AgentPosition) -> AgentWorldColumnObservation {
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

private func populationPerception(
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
            column: populationColumn(target),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
    }
    let world = try! AgentWorldObservation(
        worldTick: worldTick,
        position: position,
        center: populationColumn(position),
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
    let cells = populationRoute.map {
        AgentNavigationCell(position: $0, status: .traversable)
    }
    return AgentPerceptionInput(
        agentId: "agent_3",
        worldObservation: world,
        navigationObservation: AgentNavigationObservation(
            worldTick: worldTick,
            origin: position,
            target: populationReception,
            radius: 8,
            cells: cells
        )
    )
}

@discardableResult
private func advancePopulationMigration(
    _ session: inout AgentSimulationSession,
    recorder: inout AgentReplayRecorder?
) throws -> AgentMovementOutcome {
    let position = session.snapshot().agents.first { $0.id == "agent_3" }!.position
    let perception = populationPerception(position: position, worldTick: session.tick + 1)
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

func runPebbleAgentsPopulationMigrationSmoke() {
    section("PebbleAgents population registry and bounded migration")

    check("population checkpoint schema v2", AgentCheckpointSchema.populationVersion == 2)
    check("population replay schema v2", AgentReplaySchema.populationVersion == 2)
    check("population capacity default", AgentPopulationConfiguration.live.maximumActivePopulation == 8)
    check("population one active migration", AgentPopulationConfiguration.live.maximumConcurrentMigrations == 1)
    check("population route bound", AgentPopulationConfiguration.live.maximumRouteLength == 32)
    check("population candidate bound", AgentPopulationConfiguration.live.maximumEntryCandidates == 16)
    check("population invalid capacity refused", (try? AgentPopulationConfiguration(
        maximumActivePopulation: 2
    )) == nil)
    check("population invalid concurrency refused", (try? AgentPopulationConfiguration(
        maximumConcurrentMigrations: 2
    )) == nil)
    let configurationBytes = try! AgentCheckpointCodec.encode(AgentPopulationConfiguration.live)
    check("population configuration Codable", try! AgentCheckpointCodec.decode(
        AgentPopulationConfiguration.self,
        from: configurationBytes
    ) == .live)

    var session = populationSession()
    let bootstrap = session.populationSnapshot()
    check("population registry enabled", bootstrap.enabled)
    check("population founders exact", bootstrap.members.map(\.agentID.rawValue) == [
        "agent_0", "agent_1", "agent_2",
    ])
    check("population founders resident", bootstrap.members.allSatisfy {
        $0.founder && $0.status == .founderResident
    })
    check("population next ordinal three", bootstrap.nextPopulationOrdinal == 3)
    check("population founder states unchanged", session.snapshot().agents.map(\.position) == [
        AgentPosition(x: 0, y: 64, z: 0),
        AgentPosition(x: 2, y: 64, z: 0),
        AgentPosition(x: 4, y: 64, z: 0),
    ])
    check("population expected probe IDs founders", session.expectedActiveAgentIDs().map(\.rawValue) == [
        "agent_0", "agent_1", "agent_2",
    ])

    let migration = try! session.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: populationObservation()
    )
    let admitted = session.populationSnapshot()
    let migrant = session.snapshot().agents.first { $0.id == "agent_3" }!
    check("population first dynamic ID agent_3", migration.migrantID.rawValue == "agent_3")
    check("population migration ID deterministic", migration.migrationID.rawValue == "migration-00000003")
    check("population ordinal consumed after admission", admitted.nextPopulationOrdinal == 4)
    check("population member count four", admitted.members.count == 4)
    check("population migration in transit", migration.status == .inTransit)
    check("population migrant canonical state", migrant.state == "migrating"
        && migrant.position == populationEntry
        && migrant.currentGoal.kind == .migrateToSettlement)
    check("population migrant empty inventory and memory", migrant.resourceInventory.isEmpty
        && migrant.memoryCount == 0)
    check("population dynamic expected probe IDs", session.expectedActiveAgentIDs().map(\.rawValue) == [
        "agent_0", "agent_1", "agent_2", "agent_3",
    ])
    check("population no implicit trust", session.trustSnapshot().relations.isEmpty)
    check("population no implicit cooperation", session.cooperationSnapshot().tasks.isEmpty)
    check("population own snapshot bounded", session.populationSnapshot(
        for: AgentID(rawValue: "agent_3")!
    ).members.count == 1)

    let beforeDuplicate = try! session.durableStateBytes()
    do {
        _ = try session.admitMigration(
            intent: AgentMigrationAdmissionIntent(),
            observation: populationObservation()
        )
        check("population duplicate admission refused", false)
    } catch AgentSessionError.population(.admission(.duplicateAdmission)) {
        check("population duplicate admission refused", true)
    } catch {
        check("population duplicate admission refused", false, "unexpected \(error)")
    }
    check("population duplicate leaves bytes unchanged", try! session.durableStateBytes() == beforeDuplicate)

    var activeRefusal = session
    let differentObservation = AgentMigrationWorldObservation(
        worldTick: 0,
        candidateIndex: 1,
        entryPosition: AgentPosition(x: 4, y: 64, z: 4),
        receptionPosition: populationReception,
        route: [
            AgentPosition(x: 4, y: 64, z: 4),
            AgentPosition(x: 3, y: 64, z: 4),
            AgentPosition(x: 2, y: 64, z: 4),
            AgentPosition(x: 1, y: 64, z: 4),
            AgentPosition(x: 0, y: 64, z: 4),
            populationReception,
        ]
    )
    do {
        _ = try activeRefusal.admitMigration(
            intent: AgentMigrationAdmissionIntent(),
            observation: differentObservation
        )
        check("population active migration refusal", false)
    } catch AgentSessionError.population(.admission(.migrationAlreadyActive)) {
        check("population active migration refusal", true)
    } catch {
        check("population active migration refusal", false, "unexpected \(error)")
    }

    var noRecorder: AgentReplayRecorder?
    var movementTicks: [Int] = []
    for _ in 0..<4 {
        let outcome = try! advancePopulationMigration(&session, recorder: &noRecorder)
        check("population movement physical cardinal", outcome.status == .moved
            && abs(outcome.appliedDX) + abs(outcome.appliedDZ) == 1)
        movementTicks.append(outcome.tick)
    }
    let arrived = session.populationSnapshot()
    let arrivedMigrant = session.snapshot().agents.first { $0.id == "agent_3" }!
    check("population movement one step per tick", movementTicks == [1, 2, 3, 4])
    check("population exact arrival", arrivedMigrant.position == populationReception)
    check("population migration arrived", arrived.migrations.first?.status == .arrived)
    check("population member resident", arrived.members.first {
        $0.agentID.rawValue == "agent_3"
    }?.status == .resident)
    check("population home assigned at arrival", arrivedMigrant.homePosition == populationReception)
    check("population route cursor completed", arrived.migrations.first?.routeCursor == 4)
    check("population remains four", arrived.members.count == 4)
    check("population no material creation", session.conservationSnapshot().harvestedTotal == 0
        && session.conservationSnapshot().constructedTotal == 0)
    check("population arrival causal references movement", arrived.migrations.first?.lastMovementEventID != nil
        && arrived.migrations.first?.arrivedEventID != nil)

    let v2Checkpoint = try! session.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(v2Checkpoint)
    check("population checkpoint uses v2", v2Checkpoint.schemaVersion == 2)
    check("population checkpoint restore exact", try! restored.durableStateBytes()
        == session.durableStateBytes())
    check("population restore has four active IDs", restored.expectedActiveAgentIDs().count == 4)

    let historical = try! AgentSimulationSession(
        configuration: session.configuration,
        agents: [
            populationAgent("agent_0", x: 0),
            populationAgent("agent_1", x: 2),
            populationAgent("agent_2", x: 4),
        ],
        simulationID: try! AgentSimulationID(validating: "population-v1-compatibility"),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    let historicalCheckpoint = try! historical.makeCheckpoint()
    let historicalBytes = try! AgentCheckpointCodec.encode(historicalCheckpoint)
    check("population off checkpoint remains v1", historicalCheckpoint.schemaVersion == 1)
    check("population off checkpoint omits registry", !String(
        data: historicalBytes,
        encoding: .utf8
    )!.contains("populationRegistry"))

    var midRoute = populationSession(id: "population-mid-route")
    _ = try! midRoute.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: populationObservation()
    )
    _ = try! advancePopulationMigration(&midRoute, recorder: &noRecorder)
    _ = try! advancePopulationMigration(&midRoute, recorder: &noRecorder)
    let midCheckpoint = try! midRoute.makeCheckpoint()
    let midRestored = try! AgentSimulationSession.restoring(midCheckpoint)
    check("population mid-route cursor restored", midRestored.migrationSnapshot()
        .migrations.first?.routeCursor == 2)
    check("population mid-route no tick advance", midRestored.tick == midRoute.tick)
    check("population mid-route no lifecycle event", midRestored.causalLedgerSnapshot()
        .summary.latestSequence == midRoute.causalLedgerSnapshot().summary.latestSequence)

    var replayDirect = populationSession(id: "population-replay")
    let replayBase = try! replayDirect.makeCheckpoint()
    var recorder: AgentReplayRecorder? = try! AgentReplayRecorder(
        checkpoint: replayBase,
        session: replayDirect
    )
    _ = try! recorder!.apply(
        .admitMigration(
            intent: AgentMigrationAdmissionIntent(),
            observation: populationObservation()
        ),
        to: &replayDirect
    )
    for _ in 0..<4 {
        _ = try! advancePopulationMigration(&replayDirect, recorder: &recorder)
    }
    let journal = try! recorder!.journal(named: AgentCheckpointName(rawValue: "population")!)
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: journal
    )
    check("population replay schema v2", journal.manifest.schemaVersion == 2)
    check("population replay verified", replayed.report.verified)
    check("population replay exact final bytes", try! replayed.session.durableStateBytes()
        == replayDirect.durableStateBytes())
    check("population replay exact causal sequence", replayed.report.finalCausalSequence
        == replayDirect.causalLedgerSnapshot().summary.latestSequence)

    let maxThree = try! AgentPopulationConfiguration(maximumActivePopulation: 3)
    var full = populationSession(id: "population-full", configuration: maxThree)
    let fullBefore = try! full.durableStateBytes()
    do {
        _ = try full.admitMigration(
            intent: AgentMigrationAdmissionIntent(),
            observation: populationObservation()
        )
        check("population full refusal", false)
    } catch AgentSessionError.population(.admission(.populationFull)) {
        check("population full refusal", true)
    } catch {
        check("population full refusal", false, "unexpected \(error)")
    }
    check("population full does not consume ordinal", full.populationSummary()
        .nextPopulationOrdinal == 3)
    check("population full leaves session unchanged", try! full.durableStateBytes() == fullBefore)

    let invalidCases: [(String, AgentMigrationWorldObservation, AgentMigrationFailure)] = [
        ("chunk", populationObservation(entryChunkReady: false), .entryChunkUnavailable),
        ("occupied", populationObservation(entryUnoccupied: false), .entryOccupied),
        ("route", populationObservation(route: [populationEntry, populationReception]), .routeUnavailable),
        ("reception", populationObservation(receptionUnoccupied: false), .receptionUnavailable),
    ]
    for (label, observation, expected) in invalidCases {
        var candidate = populationSession(id: "population-invalid-\(label)")
        let before = try! candidate.durableStateBytes()
        do {
            _ = try candidate.admitMigration(
                intent: AgentMigrationAdmissionIntent(),
                observation: observation
            )
            check("population invalid \(label) refused", false)
        } catch AgentSessionError.population(.admission(let failure)) {
            check("population invalid \(label) refused", failure == expected)
        } catch {
            check("population invalid \(label) refused", false, "unexpected \(error)")
        }
        check("population invalid \(label) unchanged", try! candidate.durableStateBytes() == before)
    }

    do {
        try session.setPopulationEnabled(false)
        check("population unsafe disable refused", false)
    } catch AgentSessionError.population(.unsafeDisable) {
        check("population unsafe disable refused", true)
    } catch {
        check("population unsafe disable refused", false, "unexpected \(error)")
    }
}
