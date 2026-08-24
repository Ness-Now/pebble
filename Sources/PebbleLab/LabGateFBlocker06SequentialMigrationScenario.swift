import Foundation
import PebbleAgents

private let gateFB06RuntimeMain = AgentPosition(x: 0, y: 64, z: 0)
private let gateFB06RuntimeEast = AgentPosition(x: 0, y: 64, z: 4)
private let gateFB06RuntimeEastID = AgentSettlementID(
    rawValue: "settlement-east"
)!
private let gateFB06RuntimeAgentID = AgentID(rawValue: "agent_0")!
private let gateFB06RuntimeCheckpoint =
    "gate_f_blocker_06_second_intransit_v35.json"
private let gateFB06RuntimeDurable =
    "gate_f_blocker_06_second_intransit_durable.json"
private let gateFB06RuntimeMalformed =
    "gate_f_blocker_06_malformed_chain_v35.json"

private struct GateFBlocker06RuntimeReport: Encodable {
    let schemaVersion: Int
    let scenario: String
    let seed: UInt32
    let success: Bool
    let processPhase: String
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointBytes: Int
    let durableStateBytes: Int
    let tick: Int
    let semanticDigest: String
    let continuationDigest: String?
    let scaleDigest: String
    let migrationStatuses: [String]
    let nextMigrationOrdinal: UInt64
    let population: Int
    let settlements: Int
    let householdMembershipPeriods: Int
    let arrivals: Int
    let duplicateAgents: Int
    let duplicatePopulationMembers: Int
    let duplicateLifecycleMembers: Int
    let duplicateFidelityRecords: Int
    let duplicateCurrentHouseholdMemberships: Int
    let duplicateSettlementAuthority: Int
    let duplicateArrivals: Int
    let observerMutations: Int
    let restartDuplicateEffects: Int
    let malformedChainRejected: Int
    let unexpectedRuntimeErrors: Int
    let physicalLoss: Int
    let physicalDuplication: Int
    let syntheticMaterial: Int
    let assertions: [String: Bool]
}

private func gateFB06RuntimeAgent(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1
        ),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 06 runtime proof",
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

private func gateFB06RuntimeSession(seed: UInt32) throws
    -> AgentSimulationSession
{
    var session = try AgentSimulationSession(
        configuration: try AgentSessionConfiguration(
            seed: seed, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: (0..<3).map(gateFB06RuntimeAgent),
        simulationID: try AgentSimulationID(
            validating: "gate-f-b06-runtime-\(seed)"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    try session.initializePopulationRegistry(
        settlementAnchor: gateFB06RuntimeMain,
        receptionPosition: gateFB06RuntimeMain,
        configuration: try AgentPopulationConfiguration(
            maximumActivePopulation: 6, maximumMigrationRecords: 16
        )
    )
    try session.setLifecycleEnabled(true)
    try session.setKinshipEnabled(true)
    try session.setHouseholdsEnabled(true)
    try session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB06RuntimeEastID,
            anchor: gateFB06RuntimeEast,
            receptionPosition: gateFB06RuntimeEast,
            capacity: 4, residentIDs: [], inTransitIDs: []
        )],
        configuration: try AgentPopulationScaleConfiguration(
            maximumSettlements: 2, maximumLiveAgents: 3,
            maximumNearAgents: 1, nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8, rotationIntervalTicks: 8,
            maximumFidelityTransitionHistory: 64,
            maximumSettlementMigrationHistory: 4,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 16
        )
    )
    return session
}

private func gateFB06RuntimeRoute(
    from: AgentPosition, to: AgentPosition
) -> [AgentPosition] {
    var route = [from]
    var current = from
    while current.x != to.x {
        current = AgentPosition(
            x: current.x + (current.x < to.x ? 1 : -1),
            y: current.y, z: current.z
        )
        route.append(current)
    }
    while current.z != to.z {
        current = AgentPosition(
            x: current.x, y: current.y,
            z: current.z + (current.z < to.z ? 1 : -1)
        )
        route.append(current)
    }
    return route
}

private func gateFB06RuntimePerception(
    session: AgentSimulationSession,
    migration: AgentSettlementMigrationRecord
) throws -> AgentPerceptionInput {
    let state = try session.state(for: migration.agentID)
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
            x: state.position.x + direction.dx, y: state.position.y,
            z: state.position.z + direction.dz
        )
        return AgentWorldNeighborObservation(
            direction: direction, column: column(target), stepDelta: 0,
            traversable: true, dangerousDrop: false
        )
    }
    return AgentPerceptionInput(
        agentId: migration.agentID.rawValue,
        worldObservation: try AgentWorldObservation(
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

private func gateFB06RuntimeComplete(
    _ session: inout AgentSimulationSession
) throws {
    var attempts = 0
    while let migration = session.populationScaleSnapshot()
        .settlementMigrations.first(where: {
            $0.agentID == gateFB06RuntimeAgentID && $0.status == .inTransit
        })
    {
        guard attempts < 16 else {
            throw AgentSessionError.population(
                .invalidMigration("Gate F Blocker 06 runtime completion bound")
            )
        }
        attempts += 1
        _ = try session.advanceTick(perceptions: [
            try gateFB06RuntimePerception(
                session: session, migration: migration
            ),
        ])
        let outcomes = AgentMovementCoordinator.resolve(
            snapshot: session.snapshot()
        )
        try session.applyVerifiedPhysicalMovements(outcomes.map {
            AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: $0)
        })
    }
}

private func gateFB06RuntimeDuplicateCount<T: Hashable>(_ values: [T]) -> Int {
    values.count - Set(values).count
}

private func gateFB06RuntimeObserverBinding(
    options: Options, session: AgentSimulationSession
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "gate-f-blocker-06-runtime-world",
        storageIdentity: "headless:gate-f-blocker-06-runtime",
        seed: options.seed, dimension: 0,
        observedWorldTick: session.tick
    )
}

private func gateFB06RuntimeCurrentAuthority(
    _ session: AgentSimulationSession,
    settlementID: AgentSettlementID,
    inTransit: Bool
) -> Bool {
    let population = session.populationSnapshot()
    let scale = session.populationScaleSnapshot()
    let household = try? session.household(for: gateFB06RuntimeAgentID)
    let currentSettlement = population.settlements.first {
        $0.settlementID == settlementID
    }
    return population.members.first {
        $0.agentID == gateFB06RuntimeAgentID
    }?.settlementID == settlementID
        && session.lifecycleSnapshot().members.first {
            $0.agentID == gateFB06RuntimeAgentID
        }?.settlementID == settlementID
        && household?.settlementID == settlementID
        && scale.fidelityRecords.filter {
            $0.agentID == gateFB06RuntimeAgentID
        }.count == 1
        && (inTransit
            ? currentSettlement?.inTransitIDs == [gateFB06RuntimeAgentID]
                && currentSettlement?.residentIDs.contains(
                    gateFB06RuntimeAgentID
                ) == false
                && session.fidelity(for: gateFB06RuntimeAgentID) == .live
            : currentSettlement?.residentIDs.contains(
                gateFB06RuntimeAgentID
            ) == true
                && currentSettlement?.inTransitIDs.contains(
                    gateFB06RuntimeAgentID
                ) == false)
}

private func gateFB06RuntimeWriteJSON<T: Encodable>(
    _ value: T, to url: URL
) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(
        to: url, options: .atomic
    )
}

private func gateFB06RuntimeMalformedChain(
    _ checkpoint: AgentSessionCheckpoint
) throws -> AgentSessionCheckpoint {
    var root = try JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    var registry = durable["populationRegistry"] as! [String: Any]
    var scale = registry["scaleState"] as! [String: Any]
    var migrations = scale["settlementMigrations"] as! [[String: Any]]
    migrations[0]["destinationSettlementID"] = AgentSettlementID.main.rawValue
    scale["settlementMigrations"] = migrations
    registry["scaleState"] = scale
    durable["populationRegistry"] = registry
    let provisionalBytes = try JSONSerialization.data(
        withJSONObject: durable, options: [.sortedKeys]
    )
    let provisional = try AgentCheckpointCodec.decode(
        AgentSessionDurableState.self, from: provisionalBytes
    )
    let durableBytes = try AgentCheckpointCodec.encode(provisional)
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let canonical = try JSONSerialization.jsonObject(
        with: durableBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let simulationDigest = AgentCheckpointDigest.sha256(Data(simulationID.utf8))
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(tick)-\(digest.rawValue.prefix(16))"
    return try AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    )
}

private func gateFB06RuntimeReport(
    options: Options,
    phase: String,
    session: AgentSimulationSession,
    checkpointSchema: Int,
    checkpointBytes: Int,
    durableStateBytes: Int,
    semanticDigest: String,
    continuationDigest: String?,
    observerSchema: Int,
    observerMutations: Int,
    restartDuplicateEffects: Int,
    malformedChainRejected: Int,
    assertions: [String: Bool]
) -> GateFBlocker06RuntimeReport {
    let population = session.populationSnapshot()
    let lifecycle = session.lifecycleSnapshot()
    let scale = session.populationScaleSnapshot()
    let households = session.householdSnapshot()
    let durableScale = session.durableState().populationRegistry!.scaleState!
    let arrivals = scale.settlementMigrations.filter { $0.status == .arrived }
    return GateFBlocker06RuntimeReport(
        schemaVersion: 1, scenario: options.scenario, seed: options.seed,
        success: assertions.values.allSatisfy { $0 }, processPhase: phase,
        checkpointSchema: checkpointSchema, observerSchema: observerSchema,
        checkpointBytes: checkpointBytes, durableStateBytes: durableStateBytes,
        tick: session.tick, semanticDigest: semanticDigest,
        continuationDigest: continuationDigest, scaleDigest: scale.digest,
        migrationStatuses: scale.settlementMigrations.map { $0.status.rawValue },
        nextMigrationOrdinal: durableScale.nextSettlementMigrationOrdinal,
        population: population.members.count, settlements: scale.settlements.count,
        householdMembershipPeriods: households.membershipPeriods.count,
        arrivals: arrivals.count,
        duplicateAgents: gateFB06RuntimeDuplicateCount(
            session.snapshot().agents.map(\.id)
        ),
        duplicatePopulationMembers: gateFB06RuntimeDuplicateCount(
            population.members.map(\.agentID)
        ),
        duplicateLifecycleMembers: gateFB06RuntimeDuplicateCount(
            lifecycle.members.map(\.agentID)
        ),
        duplicateFidelityRecords: gateFB06RuntimeDuplicateCount(
            scale.fidelityRecords.map(\.agentID)
        ),
        duplicateCurrentHouseholdMemberships: gateFB06RuntimeDuplicateCount(
            households.currentMemberships.map(\.agentID)
        ),
        duplicateSettlementAuthority: gateFB06RuntimeDuplicateCount(
            scale.settlements.flatMap { $0.residentIDs + $0.inTransitIDs }
        ),
        duplicateArrivals: arrivals.count - Set(arrivals.map(\.migrationID)).count,
        observerMutations: observerMutations,
        restartDuplicateEffects: restartDuplicateEffects,
        malformedChainRejected: malformedChainRejected,
        unexpectedRuntimeErrors: 0, physicalLoss: 0,
        physicalDuplication: 0, syntheticMaterial: 0,
        assertions: assertions
    )
}

private func gateFB06RuntimeExit(
    options: Options, root: URL, checkpointURL: URL,
    durableURL: URL, malformedURL: URL
) -> Never {
    guard (try? FileManager.default.contentsOfDirectory(
        atPath: root.path
    ).isEmpty) == true else {
        fail("Gate F Blocker 06 process-one output must be empty")
    }
    do {
        var session = try gateFB06RuntimeSession(seed: options.seed)
        _ = try session.beginSettlementMigration(
            agentID: gateFB06RuntimeAgentID,
            destinationSettlementID: gateFB06RuntimeEastID,
            verifiedRoute: gateFB06RuntimeRoute(
                from: try session.state(for: gateFB06RuntimeAgentID).position,
                to: gateFB06RuntimeEast
            )
        )
        try gateFB06RuntimeComplete(&session)
        let migration1Checkpoint = try session.makeCheckpoint()
        session = try AgentSimulationSession.restoring(migration1Checkpoint)
        _ = try session.advanceTick()
        _ = try session.beginSettlementMigration(
            agentID: gateFB06RuntimeAgentID,
            destinationSettlementID: .main,
            verifiedRoute: gateFB06RuntimeRoute(
                from: try session.state(for: gateFB06RuntimeAgentID).position,
                to: gateFB06RuntimeMain
            )
        )
        let beforeObserver = try session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: gateFB06RuntimeObserverBinding(
                options: options, session: session
            )
        )
        let observerReadOnly = try session.durableStateBytes() == beforeObserver
        let checkpoint = try session.makeCheckpoint()
        let checkpointBytes = try AgentCheckpointCodec.encode(checkpoint)
        let checkpointDurableBytes = try AgentCheckpointCodec.encode(
            checkpoint.durableState
        )
        let malformed = try gateFB06RuntimeMalformedChain(checkpoint)
        let malformedBytes = try AgentCheckpointCodec.encode(malformed)
        let scale = session.populationScaleSnapshot()
        let assertions = [
            "checkpoint_schema_35": checkpoint.schemaVersion == 35,
            "durable_bytes_exact": checkpointDurableBytes == beforeObserver,
            "migration_1_historical": scale.settlementMigrations.first?.status
                == .arrived,
            "migration_2_current": scale.settlementMigrations.last?.status
                == .inTransit,
            "two_record_chain": scale.settlementMigrations.count == 2
                && scale.settlementMigrations[0].destinationSettlementID
                    == scale.settlementMigrations[1].originSettlementID,
            "next_ordinal_3": session.durableState().populationRegistry!
                .scaleState!.nextSettlementMigrationOrdinal == 3,
            "current_authority_east": gateFB06RuntimeCurrentAuthority(
                session, settlementID: gateFB06RuntimeEastID, inTransit: true
            ),
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": observerReadOnly,
        ]
        let report = gateFB06RuntimeReport(
            options: options, phase: "second-intransit-checkpoint-exit",
            session: session, checkpointSchema: checkpoint.schemaVersion,
            checkpointBytes: checkpointBytes.count,
            durableStateBytes: beforeObserver.count,
            semanticDigest: checkpoint.semanticDigest.rawValue,
            continuationDigest: nil, observerSchema: observer.header.schemaVersion,
            observerMutations: observerReadOnly ? 0 : 1,
            restartDuplicateEffects: 0, malformedChainRejected: 0,
            assertions: assertions
        )
        try checkpointBytes.write(to: checkpointURL, options: .atomic)
        try beforeObserver.write(to: durableURL, options: .atomic)
        try malformedBytes.write(to: malformedURL, options: .atomic)
        try gateFB06RuntimeWriteJSON(
            report, to: root.appendingPathComponent("process_1_report.json")
        )
        try gateFB06RuntimeWriteJSON(
            observer, to: root.appendingPathComponent("observer_process_1.json")
        )
        guard report.success, report.duplicateAgents == 0,
              report.duplicatePopulationMembers == 0,
              report.duplicateLifecycleMembers == 0,
              report.duplicateFidelityRecords == 0,
              report.duplicateCurrentHouseholdMemberships == 0,
              report.duplicateSettlementAuthority == 0 else {
            fail("Gate F Blocker 06 process 1 assertions failed")
        }
        print("GATE_F_BLOCKER_06_PROCESS_1_PASS checkpointSchema=35 observerSchema=13 migration1=historical migration2=current nextMigrationOrdinal=3 durableIdentity=exact semanticDigest=\(checkpoint.semanticDigest.rawValue) duplicateAuthority=0")
        exit(0)
    } catch {
        fail("Gate F Blocker 06 process 1 proof failed: \(error)")
    }
}

private func gateFB06RuntimeRestore(
    options: Options, root: URL, checkpointURL: URL,
    durableURL: URL, malformedURL: URL
) -> Never {
    do {
        let checkpointBytes = try Data(contentsOf: checkpointURL)
        let expectedDurable = try Data(contentsOf: durableURL)
        let checkpoint = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        let malformedBytes = try Data(contentsOf: malformedURL)
        let malformed = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: malformedBytes
        )
        let malformedRejected: Bool
        do { _ = try AgentSimulationSession.restoring(malformed); malformedRejected = false }
        catch { malformedRejected = true }
        var session = try AgentSimulationSession.restoring(checkpoint)
        let restoredBytes = try session.durableStateBytes()
        let arrivalsBefore = session.causalLedgerSnapshot().events.filter {
            $0.kind == .settlementMigrationArrived
                && $0.actorID == gateFB06RuntimeAgentID
        }.count
        let membershipsBefore = session.householdSnapshot().membershipPeriods.count
        try gateFB06RuntimeComplete(&session)
        let arrivalsAfterCompletion = session.causalLedgerSnapshot().events.filter {
            $0.kind == .settlementMigrationArrived
                && $0.actorID == gateFB06RuntimeAgentID
        }.count
        let beforeObserver = try session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: gateFB06RuntimeObserverBinding(
                options: options, session: session
            )
        )
        let observerReadOnly = try session.durableStateBytes() == beforeObserver
        _ = try session.advanceTick()
        let arrivalsAfterTick = session.causalLedgerSnapshot().events.filter {
            $0.kind == .settlementMigrationArrived
                && $0.actorID == gateFB06RuntimeAgentID
        }.count
        let continuation = try session.makeCheckpoint()
        let continuationBytes = try AgentCheckpointCodec.encode(continuation)
        let continuationRestored = try AgentSimulationSession.restoring(
            continuation
        )
        let continuationExact = try continuationRestored.durableStateBytes()
            == session.durableStateBytes()
        let replayedEffects = max(
            0, arrivalsAfterTick - arrivalsAfterCompletion
        )
        let assertions = [
            "fresh_restore_exact": restoredBytes == expectedDurable,
            "malformed_chain_rejected": malformedRejected,
            "migration_2_arrived_once": arrivalsAfterCompletion
                == arrivalsBefore + 1,
            "historical_and_current_arrived": session.populationScaleSnapshot()
                .settlementMigrations.map(\.status) == [.arrived, .arrived],
            "current_authority_main": gateFB06RuntimeCurrentAuthority(
                session, settlementID: .main, inTransit: false
            ),
            "household_transition_once": session.householdSnapshot()
                .membershipPeriods.count == membershipsBefore + 1,
            "next_ordinal_3": session.durableState().populationRegistry!
                .scaleState!.nextSettlementMigrationOrdinal == 3,
            "post_restore_tick": arrivalsAfterTick == arrivalsAfterCompletion,
            "continuation_schema_35_exact": continuation.schemaVersion == 35
                && continuationExact,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": observerReadOnly,
        ]
        let report = gateFB06RuntimeReport(
            options: options,
            phase: "fresh-restore-second-arrival-continuation",
            session: session, checkpointSchema: checkpoint.schemaVersion,
            checkpointBytes: checkpointBytes.count,
            durableStateBytes: restoredBytes.count,
            semanticDigest: checkpoint.semanticDigest.rawValue,
            continuationDigest: continuation.semanticDigest.rawValue,
            observerSchema: observer.header.schemaVersion,
            observerMutations: observerReadOnly ? 0 : 1,
            restartDuplicateEffects: replayedEffects,
            malformedChainRejected: malformedRejected ? 1 : 0,
            assertions: assertions
        )
        try continuationBytes.write(
            to: root.appendingPathComponent(
                "gate_f_blocker_06_second_arrival_v35.json"
            ), options: .atomic
        )
        try gateFB06RuntimeWriteJSON(
            observer, to: root.appendingPathComponent("observer_process_2.json")
        )
        try gateFB06RuntimeWriteJSON(
            report, to: root.appendingPathComponent("process_2_report.json")
        )
        try gateFB06RuntimeWriteJSON(
            [
                "active_external_resources": 0,
                "duplicate_agents": report.duplicateAgents,
                "duplicate_population_members": report.duplicatePopulationMembers,
                "duplicate_lifecycle_members": report.duplicateLifecycleMembers,
                "duplicate_fidelity_records": report.duplicateFidelityRecords,
                "duplicate_current_household_memberships":
                    report.duplicateCurrentHouseholdMemberships,
                "duplicate_settlement_authority":
                    report.duplicateSettlementAuthority,
                "duplicate_arrivals": report.duplicateArrivals,
                "observer_mutations": report.observerMutations,
                "restart_duplicate_effects": report.restartDuplicateEffects,
                "unexpected_runtime_errors": report.unexpectedRuntimeErrors,
                "physical_loss": report.physicalLoss,
                "physical_duplication": report.physicalDuplication,
                "synthetic_material": report.syntheticMaterial,
            ],
            to: root.appendingPathComponent("cleanup_evidence.json")
        )
        guard report.success, report.duplicateAgents == 0,
              report.duplicatePopulationMembers == 0,
              report.duplicateLifecycleMembers == 0,
              report.duplicateFidelityRecords == 0,
              report.duplicateCurrentHouseholdMemberships == 0,
              report.duplicateSettlementAuthority == 0,
              report.duplicateArrivals == 0 else {
            fail("Gate F Blocker 06 process 2 assertions failed")
        }
        print("GATE_F_BLOCKER_06_PROCESS_2_PASS checkpointSchema=35 observerSchema=13 freshRestoreExact=1 migration2Arrival=1 continuationTicks=1 malformedChainRejected=1 restartDuplicateEffects=0 nextMigrationOrdinal=3 semanticDigest=\(checkpoint.semanticDigest.rawValue) continuationDigest=\(continuation.semanticDigest.rawValue) duplicateAuthority=0")
        exit(0)
    } catch {
        fail("Gate F Blocker 06 process 2 proof failed: \(error)")
    }
}

func runGateFBlocker06SequentialMigrationSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("Gate F Blocker 06 proof requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let checkpointURL = root.appendingPathComponent(gateFB06RuntimeCheckpoint)
    let durableURL = root.appendingPathComponent(gateFB06RuntimeDurable)
    let malformedURL = root.appendingPathComponent(gateFB06RuntimeMalformed)
    let thread = Thread {
        if options.scenario
            == "gate_f_blocker_06_sequential_restore_smoke" {
            gateFB06RuntimeRestore(
                options: options, root: root, checkpointURL: checkpointURL,
                durableURL: durableURL, malformedURL: malformedURL
            )
        }
        gateFB06RuntimeExit(
            options: options, root: root, checkpointURL: checkpointURL,
            durableURL: durableURL, malformedURL: malformedURL
        )
    }
    thread.stackSize = 32 * 1_024 * 1_024
    thread.start()
    while !thread.isFinished { Thread.sleep(forTimeInterval: 0.001) }
    fail("Gate F Blocker 06 runtime worker returned unexpectedly")
}
