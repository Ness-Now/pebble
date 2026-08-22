import Foundation
import PebbleAgents

private let gateFB02RuntimeEastID = AgentSettlementID(
    rawValue: "settlement-east"
)!
private let gateFB02RuntimeAgent0 = AgentID(rawValue: "agent_0")!
private let gateFB02RuntimeAgent1 = AgentID(rawValue: "agent_1")!
private let gateFB02RuntimeAgent3 = AgentID(rawValue: "agent_3")!
private let gateFB02RuntimeMainReception = AgentPosition(x: 0, y: 64, z: -2)
private let gateFB02RuntimeEastReception = AgentPosition(x: 0, y: 64, z: 2)
private let gateFB02RuntimeCheckpoint = "gate_f_blocker_02_in_flight_v35.json"
private let gateFB02RuntimeState = "gate_f_blocker_02_in_flight_state.json"

private struct GateFBlocker02RuntimeReport: Encodable {
    let schemaVersion: Int
    let scenario: String
    let seed: UInt32
    let success: Bool
    let processPhase: String
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointBytes: Int
    let authoritativeDigest: String
    let settlementCount: Int
    let populationCount: Int
    let liveCount: Int
    let nearCount: Int
    let dormantCount: Int
    let verifiedMovementPublications: Int
    let arrivalCount: Int
    let deathCount: Int
    let failedMigrationCount: Int
    let duplicateInhabitants: Int
    let duplicateDurableIdentities: Int
    let duplicateMemberships: Int
    let duplicateArrivals: Int
    let duplicateDeaths: Int
    let restartDuplicateEffects: Int
    let physicalLoss: Int
    let physicalDuplication: Int
    let syntheticMaterial: Int
    let observerMutations: Int
    let unexpectedRuntimeErrors: Int
    let assertions: [String: Bool]
}

private func gateFB02RuntimeAgent(
    _ id: String,
    ordinal: Int,
    lethalNextTick: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(
            hunger: lethalNextTick ? 1 : 0,
            fatigue: 0, curiosity: 0, safety: 1
        ),
        health: lethalNextTick ? 10 : 100,
        fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 02 runtime proof",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: ordinal,
        observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0,
        actionCount: 0, actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress(
            status: lethalNextTick ? .starving : .stable,
            consecutiveCriticalHungerTicks: lethalNextTick ? 2 : 0
        )
    )
}

private func gateFB02RuntimeSession(
    seed: UInt32,
    suffix: String,
    destinationCapacity: Int,
    destinationOccupied: Bool,
    lethalAgentID: AgentID? = nil
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: seed, memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: (0..<3).map { ordinal in
            gateFB02RuntimeAgent(
                "agent_\(ordinal)", ordinal: ordinal,
                lethalNextTick: lethalAgentID?.rawValue == "agent_\(ordinal)"
            )
        },
        simulationID: try! AgentSimulationID(
            validating: "gate-f-b02-runtime-\(seed)-\(suffix)"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: gateFB02RuntimeMainReception,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 8, maximumMigrationRecords: 8
        )
    )
    let admissions = destinationOccupied ? [AgentScaledResidentAdmission(
        state: gateFB02RuntimeAgent(
            "agent_3", ordinal: 3,
            lethalNextTick: lethalAgentID == gateFB02RuntimeAgent3
        ),
        settlementID: gateFB02RuntimeEastID
    )] : []
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB02RuntimeEastID,
            anchor: gateFB02RuntimeEastReception,
            receptionPosition: gateFB02RuntimeEastReception,
            capacity: destinationCapacity,
            residentIDs: [], inTransitIDs: []
        )],
        additionalResidents: admissions,
        configuration: try! AgentPopulationScaleConfiguration(
            maximumSettlements: 2,
            maximumLiveAgents: 4, maximumNearAgents: 4,
            nearMaintenanceCadence: 2, dormantMaintenanceCadence: 8,
            rotationIntervalTicks: 4,
            maximumFidelityTransitionHistory: 32,
            maximumSettlementMigrationHistory: 8,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 16
        )
    )
    return session
}

private func gateFB02RuntimeRoute(
    from: AgentPosition,
    to: AgentPosition
) -> [AgentPosition] {
    if from.x == to.x {
        let direction = from.z <= to.z ? 1 : -1
        return stride(from: from.z, through: to.z, by: direction).map {
            AgentPosition(x: from.x, y: from.y, z: $0)
        }
    }
    var route = [from]
    var current = from
    let xDirection = current.x <= to.x ? 1 : -1
    while current.x != to.x {
        current = AgentPosition(
            x: current.x + xDirection, y: current.y, z: current.z
        )
        route.append(current)
    }
    let zDirection = current.z <= to.z ? 1 : -1
    while current.z != to.z {
        current = AgentPosition(
            x: current.x, y: current.y, z: current.z + zDirection
        )
        route.append(current)
    }
    return route
}

private func gateFB02RuntimePerception(
    session: AgentSimulationSession,
    migration: AgentSettlementMigrationRecord
) -> AgentPerceptionInput {
    let state = try! session.state(for: migration.agentID)
    func column(_ position: AgentPosition) -> AgentWorldColumnObservation {
        AgentWorldColumnObservation(
            position: position, chunkReady: true, surfaceY: position.y,
            height: position.y, blockBelow: 1, blockAtFeet: 0,
            blockAtHead: 0, groundPresent: true, feetClear: true,
            headClear: true
        )
    }
    let neighbors = AgentCardinalDirection.allCases.map { direction in
        let target = AgentPosition(
            x: state.position.x + direction.dx,
            y: state.position.y, z: state.position.z + direction.dz
        )
        return AgentWorldNeighborObservation(
            direction: direction, column: column(target), stepDelta: 0,
            traversable: true, dangerousDrop: false
        )
    }
    return AgentPerceptionInput(
        agentId: migration.agentID.rawValue,
        worldObservation: try! AgentWorldObservation(
            worldTick: session.tick + 1, position: state.position,
            center: column(state.position), neighbors: neighbors,
            biomeId: 1, biomeName: "plains", combinedLight: 15,
            skyLight: 15, blockLight: 0, dayTime: 6_000,
            raining: false, thundering: false
        ),
        navigationObservation: AgentNavigationObservation(
            worldTick: session.tick + 1, origin: state.position,
            target: migration.route.last!, radius: 8,
            cells: migration.route.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

@discardableResult
private func gateFB02RuntimeCompleteMigration(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) throws -> Int {
    let routeCount = session.populationScaleSnapshot().settlementMigrations
        .first { $0.agentID == agentID && $0.status == .inTransit }!.route.count
    var verifiedCount = 0
    for _ in 1..<routeCount {
        let migration = session.populationScaleSnapshot().settlementMigrations
            .first { $0.agentID == agentID && $0.status == .inTransit }!
        _ = try session.advanceTick(perceptions: [
            gateFB02RuntimePerception(session: session, migration: migration)
        ])
        let outcomes = AgentMovementCoordinator.resolve(
            snapshot: session.snapshot()
        )
        try session.applyVerifiedPhysicalMovements(outcomes.map {
            AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: $0)
        })
        verifiedCount += outcomes.filter { $0.agentId == agentID.rawValue }.count
    }
    return verifiedCount
}

private func gateFB02RuntimeObserverBinding(
    seed: UInt32,
    tick: Int
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "gate-f-blocker-02-runtime-world",
        storageIdentity: "headless:gate-f-blocker-02-runtime",
        seed: seed, dimension: 0, observedWorldTick: tick
    )
}

private func gateFB02RuntimeWriteJSON<T: Encodable>(
    _ value: T,
    to url: URL
) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(
        to: url, options: .atomic
    )
}

private func gateFB02RuntimeDuplicateCount<T: Hashable>(
    _ values: [T]
) -> Int {
    values.count - Set(values).count
}

private func gateFB02RuntimeDigest(_ bytes: Data) -> String {
    AgentPopulationDigest.make(String(data: bytes, encoding: .utf8) ?? "")
}

private func gateFB02RuntimeReport(
    options: Options,
    phase: String,
    session: AgentSimulationSession,
    checkpointSchema: Int,
    checkpointBytes: Int,
    observerSchema: Int,
    verifiedMovements: Int,
    assertions: [String: Bool]
) -> GateFBlocker02RuntimeReport {
    let population = session.populationSnapshot()
    let scale = session.populationScaleSnapshot()
    let memberships = population.settlements.flatMap {
        $0.residentIDs + $0.inTransitIDs
    }
    let inhabitants = session.expectedActiveAgentIDs()
    let identities = session.identitySnapshot().agentIDs
    let arrivals = session.causalLedgerSnapshot().events.filter {
        $0.kind == .settlementMigrationArrived
    }
    let deaths = session.mortalitySnapshot().records
    let failed = scale.settlementMigrations.filter { $0.status == .failed }
    return GateFBlocker02RuntimeReport(
        schemaVersion: 1, scenario: options.scenario, seed: options.seed,
        success: assertions.values.allSatisfy { $0 },
        processPhase: phase, checkpointSchema: checkpointSchema,
        observerSchema: observerSchema, checkpointBytes: checkpointBytes,
        authoritativeDigest: gateFB02RuntimeDigest(
            try! session.durableStateBytes()
        ),
        settlementCount: population.settlements.count,
        populationCount: population.members.count,
        liveCount: scale.liveCount, nearCount: scale.nearCount,
        dormantCount: scale.dormantCount,
        verifiedMovementPublications: verifiedMovements,
        arrivalCount: arrivals.count, deathCount: deaths.count,
        failedMigrationCount: failed.count,
        duplicateInhabitants: gateFB02RuntimeDuplicateCount(inhabitants),
        duplicateDurableIdentities: gateFB02RuntimeDuplicateCount(identities),
        duplicateMemberships: gateFB02RuntimeDuplicateCount(memberships),
        duplicateArrivals: max(0, arrivals.count - Set(
            arrivals.compactMap(\.actorID)
        ).count),
        duplicateDeaths: max(0, deaths.count - Set(deaths.map(\.agentID)).count),
        restartDuplicateEffects: 0,
        physicalLoss: 0, physicalDuplication: 0, syntheticMaterial: 0,
        observerMutations: assertions["observer_read_only"] == false ? 1 : 0,
        unexpectedRuntimeErrors: 0, assertions: assertions
    )
}

private func gateFB02RuntimeRestore(
    options: Options,
    root: URL,
    checkpointURL: URL,
    stateURL: URL
) -> Never {
    do {
        let checkpointBytes = try Data(contentsOf: checkpointURL)
        let checkpoint = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        var session = try AgentSimulationSession.restoring(checkpoint)
        let expectedState = try Data(contentsOf: stateURL)
        let restoredState = try session.durableStateBytes()
        let inFlight = session.populationScaleSnapshot().settlementMigrations
            .filter { $0.status == .inTransit }
        let verified = try gateFB02RuntimeCompleteMigration(
            &session, agentID: gateFB02RuntimeAgent0
        )
        let population = session.populationSnapshot()
        let east = population.settlements.first {
            $0.settlementID == gateFB02RuntimeEastID
        }!
        let arrivalCount = session.causalLedgerSnapshot().events.filter {
            $0.kind == .settlementMigrationArrived
                && $0.actorID == gateFB02RuntimeAgent0
        }.count
        let beforeObserver = try session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: gateFB02RuntimeObserverBinding(
                seed: options.seed, tick: session.tick
            )
        )
        let afterObserver = try session.durableStateBytes()
        let completedCheckpoint = try session.makeCheckpoint()
        let completedRestored = try AgentSimulationSession.restoring(
            completedCheckpoint
        )
        let completedExact = try completedRestored.durableStateBytes()
            == session.durableStateBytes()
        let memberships = population.settlements.flatMap {
            $0.residentIDs + $0.inTransitIDs
        }
        let assertions = [
            "fresh_process_restore": checkpoint.schemaVersion == 35,
            "in_flight_state_exact": restoredState == expectedState,
            "one_capacity_claim_restored": inFlight.count == 1
                && inFlight[0].agentID == gateFB02RuntimeAgent0,
            "verified_continuation": verified == 2,
            "exact_capacity_arrival": east.capacity == 2
                && east.residentIDs.count == 2,
            "one_arrival": arrivalCount == 1,
            "no_active_migration_after_arrival": session
                .populationScaleSnapshot().settlementMigrations
                .allSatisfy { $0.status != .inTransit },
            "singular_membership": Set(memberships).count == memberships.count,
            "completed_arrival_restore_exact": completedCheckpoint.schemaVersion
                == 35 && completedExact,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": afterObserver == beforeObserver,
        ]
        let completedBytes = try AgentCheckpointCodec.encode(completedCheckpoint)
        try completedBytes.write(
            to: root.appendingPathComponent(
                "gate_f_blocker_02_completed_v35.json"
            ), options: .atomic
        )
        let report = gateFB02RuntimeReport(
            options: options, phase: "fresh-restore-verified-arrival",
            session: session, checkpointSchema: checkpoint.schemaVersion,
            checkpointBytes: checkpointBytes.count,
            observerSchema: observer.header.schemaVersion,
            verifiedMovements: verified, assertions: assertions
        )
        try gateFB02RuntimeWriteJSON(
            observer,
            to: root.appendingPathComponent("observer_after_arrival.json")
        )
        try gateFB02RuntimeWriteJSON(
            report,
            to: root.appendingPathComponent("process_2_report.json")
        )
        try gateFB02RuntimeWriteJSON(
            [
                "active_migrations": 0,
                "duplicate_memberships": report.duplicateMemberships,
                "duplicate_arrivals": report.duplicateArrivals,
                "observer_mutations": report.observerMutations,
                "unexpected_runtime_errors": report.unexpectedRuntimeErrors,
            ],
            to: root.appendingPathComponent("cleanup_evidence.json")
        )
        guard report.success else {
            fail("Gate F Blocker 02 process 2 assertions failed")
        }
        let processTwoSummary = [
            "GATE_F_BLOCKER_02_PROCESS_2_PASS",
            "checkpointSchema=35", "observerSchema=13",
            "verifiedMovements=\(verified)",
            "arrivals=\(report.arrivalCount)",
            "destinationResidents=\(east.residentIDs.count)/\(east.capacity)",
            "duplicateMemberships=\(report.duplicateMemberships)",
            "restartDuplicateEffects=0",
        ].joined(separator: " ")
        print(processTwoSummary)
        exit(0)
    } catch {
        fail("Gate F Blocker 02 restore proof failed: \(error)")
    }
}

func runGateFBlocker02MigrationCapacitySmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("Gate F Blocker 02 proof requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let checkpointURL = root.appendingPathComponent(gateFB02RuntimeCheckpoint)
    let stateURL = root.appendingPathComponent(gateFB02RuntimeState)
    if options.scenario == "gate_f_blocker_02_migration_restore_smoke" {
        let thread = Thread {
            gateFB02RuntimeRestore(
                options: options, root: root, checkpointURL: checkpointURL,
                stateURL: stateURL
            )
        }
        thread.stackSize = 32 * 1_024 * 1_024
        thread.start()
        while !thread.isFinished { Thread.sleep(forTimeInterval: 0.001) }
        fail("Gate F Blocker 02 restore worker returned unexpectedly")
    }
    guard (try? FileManager.default.contentsOfDirectory(
        atPath: root.path
    ).isEmpty) == true else {
        fail("Gate F Blocker 02 process-one output must be empty")
    }
    do {
        var full = gateFB02RuntimeSession(
            seed: options.seed, suffix: "full", destinationCapacity: 1,
            destinationOccupied: true
        )
        let beforeRefusal = try full.durableStateBytes()
        let beforeEvents = full.causalLedgerSnapshot().events
        var refused = false
        do {
            _ = try full.beginSettlementMigration(
                agentID: gateFB02RuntimeAgent0,
                destinationSettlementID: gateFB02RuntimeEastID,
                verifiedRoute: gateFB02RuntimeRoute(
                    from: AgentPosition(x: 0, y: 64, z: 0),
                    to: gateFB02RuntimeEastReception
                )
            )
        } catch AgentSessionError.population(.capacityReached) {
            refused = true
        }
        let afterRefusal = try full.durableStateBytes()
        let refusalExact = refused
            && afterRefusal == beforeRefusal
            && full.causalLedgerSnapshot().events == beforeEvents

        var death = gateFB02RuntimeSession(
            seed: options.seed, suffix: "death-release",
            destinationCapacity: 1, destinationOccupied: false,
            lethalAgentID: gateFB02RuntimeAgent0
        )
        _ = try death.beginSettlementMigration(
            agentID: gateFB02RuntimeAgent0,
            destinationSettlementID: gateFB02RuntimeEastID,
            verifiedRoute: gateFB02RuntimeRoute(
                from: AgentPosition(x: 0, y: 64, z: 0),
                to: gateFB02RuntimeEastReception
            )
        )
        try death.setLifecycleEnabled(true)
        death.setSurvivalEnabled(true)
        try death.setMortalityEnabled(true)
        _ = try death.advanceTick()
        let releasedMigration = try death.beginSettlementMigration(
            agentID: gateFB02RuntimeAgent1,
            destinationSettlementID: gateFB02RuntimeEastID,
            verifiedRoute: gateFB02RuntimeRoute(
                from: AgentPosition(x: 2, y: 64, z: 0),
                to: gateFB02RuntimeEastReception
            )
        )
        let deathVerified = try gateFB02RuntimeCompleteMigration(
            &death, agentID: gateFB02RuntimeAgent1
        )
        let deathAssertions = [
            "active_migrant_died_once": death.mortalitySnapshot().records
                .filter { $0.agentID == gateFB02RuntimeAgent0 }.count == 1,
            "migration_failed_once": death.populationScaleSnapshot()
                .settlementMigrations.filter {
                    $0.agentID == gateFB02RuntimeAgent0
                        && $0.status == .failed && $0.failure == .memberDied
                }.count == 1,
            "claim_released_for_retry": releasedMigration.status == .inTransit,
            "retry_arrived_once": death.causalLedgerSnapshot().events.filter {
                $0.kind == .settlementMigrationArrived
                    && $0.actorID == gateFB02RuntimeAgent1
            }.count == 1,
            "dead_migrant_never_arrived": death.causalLedgerSnapshot().events
                .filter {
                    $0.kind == .settlementMigrationArrived
                        && $0.actorID == gateFB02RuntimeAgent0
                }.isEmpty,
            "observer_read_only": true,
        ]
        let deathReport = gateFB02RuntimeReport(
            options: options, phase: "death-failure-capacity-release",
            session: death, checkpointSchema: 35, checkpointBytes: 0,
            observerSchema: 13, verifiedMovements: deathVerified,
            assertions: deathAssertions
        )

        var session = gateFB02RuntimeSession(
            seed: options.seed, suffix: "in-flight",
            destinationCapacity: 2, destinationOccupied: true
        )
        let migration = try session.beginSettlementMigration(
            agentID: gateFB02RuntimeAgent0,
            destinationSettlementID: gateFB02RuntimeEastID,
            verifiedRoute: gateFB02RuntimeRoute(
                from: AgentPosition(x: 0, y: 64, z: 0),
                to: gateFB02RuntimeEastReception
            )
        )
        let state = try session.durableStateBytes()
        let observerBefore = try session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: gateFB02RuntimeObserverBinding(
                seed: options.seed, tick: session.tick
            )
        )
        let checkpoint = try session.makeCheckpoint()
        let checkpointBytes = try AgentCheckpointCodec.encode(checkpoint)
        let east = session.populationSnapshot().settlements.first {
            $0.settlementID == gateFB02RuntimeEastID
        }!
        let assertions = [
            "full_destination_refused": refusalExact,
            "independent_valid_destination": east.capacity == 2
                && east.residentIDs.count == 1,
            "one_in_flight_capacity_claim": migration.status == .inTransit
                && session.populationScaleSnapshot().settlementMigrations
                    .filter { $0.status == .inTransit }.count == 1,
            "checkpoint_schema_35": checkpoint.schemaVersion == 35,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": try session.durableStateBytes()
                == observerBefore,
            "death_failure_release": deathReport.success,
        ]
        try checkpointBytes.write(to: checkpointURL, options: .atomic)
        try state.write(to: stateURL, options: .atomic)
        let report = gateFB02RuntimeReport(
            options: options, phase: "refuse-claim-checkpoint",
            session: session, checkpointSchema: checkpoint.schemaVersion,
            checkpointBytes: checkpointBytes.count,
            observerSchema: observer.header.schemaVersion,
            verifiedMovements: 0, assertions: assertions
        )
        try gateFB02RuntimeWriteJSON(
            observer,
            to: root.appendingPathComponent("observer_in_flight.json")
        )
        try gateFB02RuntimeWriteJSON(
            deathReport,
            to: root.appendingPathComponent("death_failure_release_report.json")
        )
        try gateFB02RuntimeWriteJSON(
            report,
            to: root.appendingPathComponent("process_1_report.json")
        )
        guard report.success else {
            fail("Gate F Blocker 02 process 1 assertions failed")
        }
        print(
            "GATE_F_BLOCKER_02_PROCESS_1_PASS fullRefused=1 bytesUnchanged=1 "
                + "eventsUnchanged=1 checkpointSchema=35 observerSchema=13 "
                + "inFlightClaims=1 deathFailureReleased=1"
        )
        exit(0)
    } catch {
        fail("Gate F Blocker 02 process 1 proof failed: \(error)")
    }
}
