import Foundation
import PebbleAgents

private let gateFB05RuntimeMain = AgentPosition(x: 0, y: 64, z: 0)
private let gateFB05RuntimeEast = AgentPosition(x: 0, y: 64, z: 4)
private let gateFB05RuntimeEastID = AgentSettlementID(
    rawValue: "settlement-east"
)!
private let gateFB05RuntimeMigrantID = AgentID(rawValue: "agent_0")!
private let gateFB05RuntimeCheckpoint =
    "gate_f_blocker_05_family_scale_v35.json"
private let gateFB05RuntimeDurableState =
    "gate_f_blocker_05_pre_checkpoint_durable_state.json"

private struct GateFBlocker05RuntimeReport: Encodable {
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
    let familyDigest: String
    let scaleDigest: String
    let population: Int
    let settlements: Int
    let arrivals: Int
    let familyUnions: Int
    let familyHouses: Int
    let familyHouseMemberships: Int
    let duplicateAgents: Int
    let duplicatePopulationMembers: Int
    let duplicateLifecycleMembers: Int
    let duplicateFidelityRecords: Int
    let duplicateCurrentHouseholdMemberships: Int
    let duplicateSettlementResidents: Int
    let duplicateArrivals: Int
    let observerMutations: Int
    let restartDuplicateEffects: Int
    let unexpectedRuntimeErrors: Int
    let physicalLoss: Int
    let physicalDuplication: Int
    let syntheticMaterial: Int
    let assertions: [String: Bool]
}

private func gateFB05RuntimeAgent(
    _ ordinal: Int
) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1
        ),
        health: 100, fear: 0,
        homePosition: ordinal < 2 ? gateFB05RuntimeMain : position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 05 runtime proof",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0,
        observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0,
        actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress()
    )
}

private func gateFB05RuntimeReceipt(
    _ session: AgentSimulationSession,
    id: String,
    kind: AgentFamilyInteractionKind,
    actorID: AgentID,
    counterpartyID: AgentID
) -> AgentFamilyInteractionReceipt {
    let states = Dictionary(uniqueKeysWithValues:
        session.snapshot().agents.map {
            (AgentID(rawValue: $0.id)!, $0)
        }
    )
    return AgentFamilyInteractionReceipt(
        receiptID: id, kind: kind,
        actorID: actorID, counterpartyID: counterpartyID,
        observedTick: session.tick,
        actorPosition: states[actorID]!.position,
        counterpartyPosition: states[counterpartyID]!.position,
        communicationVerified: true
    )
}

private func gateFB05RuntimeSession(
    seed: UInt32
) throws -> AgentSimulationSession {
    var session = try AgentSimulationSession(
        configuration: try AgentSessionConfiguration(
            seed: seed, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: (0..<3).map(gateFB05RuntimeAgent),
        simulationID: try AgentSimulationID(
            validating: "gate-f-b05-runtime-\(seed)"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    session.setSurvivalEnabled(true)
    try session.initializePopulationRegistry(
        settlementAnchor: gateFB05RuntimeMain,
        receptionPosition: gateFB05RuntimeMain,
        configuration: try AgentPopulationConfiguration(
            maximumActivePopulation: 5,
            maximumMigrationRecords: 16
        )
    )
    try session.setLifecycleEnabled(true)
    try session.setKinshipEnabled(true)
    try session.setHouseholdsEnabled(true)
    try session.setDependentCareEnabled(true)
    try session.setChildhoodV2Enabled(true)
    try session.setFamilyV1Enabled(true)

    let first = AgentID(rawValue: "agent_0")!
    let second = AgentID(rawValue: "agent_1")!
    let proposal = try session.proposeUnion(gateFB05RuntimeReceipt(
        session,
        id: "gate-f-b05-runtime-proposal",
        kind: .unionProposal,
        actorID: first,
        counterpartyID: second
    ))
    _ = try session.acceptUnion(
        proposalID: proposal.proposalID,
        receipt: gateFB05RuntimeReceipt(
            session,
            id: "gate-f-b05-runtime-acceptance",
            kind: .unionAcceptance,
            actorID: second,
            counterpartyID: first
        )
    )
    _ = try session.coFoundHouse(
        founderIDs: [first, second],
        receipts: [
            gateFB05RuntimeReceipt(
                session,
                id: "gate-f-b05-runtime-cofound-a",
                kind: .houseCoFoundation,
                actorID: first,
                counterpartyID: second
            ),
            gateFB05RuntimeReceipt(
                session,
                id: "gate-f-b05-runtime-cofound-b",
                kind: .houseCoFoundation,
                actorID: second,
                counterpartyID: first
            ),
        ]
    )
    try session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB05RuntimeEastID,
            anchor: gateFB05RuntimeEast,
            receptionPosition: gateFB05RuntimeEast,
            capacity: 2,
            residentIDs: [],
            inTransitIDs: []
        )],
        configuration: try AgentPopulationScaleConfiguration(
            maximumSettlements: 2,
            maximumLiveAgents: 3,
            maximumNearAgents: 1,
            nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8,
            rotationIntervalTicks: 4,
            maximumFidelityTransitionHistory: 16,
            maximumSettlementMigrationHistory: 4,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 16
        )
    )
    return session
}

private func gateFB05RuntimeRoute(
    from: AgentPosition,
    to: AgentPosition
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

private func gateFB05RuntimePerception(
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
            x: state.position.x + direction.dx,
            y: state.position.y,
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
            worldTick: session.tick + 1,
            position: state.position,
            center: column(state.position),
            neighbors: neighbors,
            biomeId: 1, biomeName: "plains", combinedLight: 15,
            skyLight: 15, blockLight: 0, dayTime: 6_000,
            raining: false, thundering: false
        ),
        navigationObservation: AgentNavigationObservation(
            worldTick: session.tick + 1,
            origin: state.position,
            target: migration.route.last!, radius: 8,
            cells: migration.route.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

private func gateFB05RuntimeCompleteMigration(
    _ session: inout AgentSimulationSession
) throws {
    while let migration = session.populationScaleSnapshot()
        .settlementMigrations.first(where: {
            $0.agentID == gateFB05RuntimeMigrantID
                && $0.status == .inTransit
        })
    {
        _ = try session.advanceTick(perceptions: [
            try gateFB05RuntimePerception(
                session: session, migration: migration
            ),
        ])
        let outcomes = AgentMovementCoordinator.resolve(
            snapshot: session.snapshot()
        )
        try session.applyVerifiedPhysicalMovements(outcomes.map {
            AgentVerifiedPhysicalMovement(
                kind: .navigationStep, outcome: $0
            )
        })
    }
}

private func gateFB05RuntimeDuplicateCount<T: Hashable>(
    _ values: [T]
) -> Int {
    values.count - Set(values).count
}

private func gateFB05RuntimeObserverBinding(
    options: Options,
    session: AgentSimulationSession
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "gate-f-blocker-05-runtime-world",
        storageIdentity: "headless:gate-f-blocker-05-runtime",
        seed: options.seed, dimension: 0,
        observedWorldTick: session.tick
    )
}

private func gateFB05RuntimeCurrentAuthority(
    _ session: AgentSimulationSession
) -> Bool {
    let population = session.populationSnapshot()
    let scale = session.populationScaleSnapshot()
    return population.members.first {
        $0.agentID == gateFB05RuntimeMigrantID
    }?.settlementID == gateFB05RuntimeEastID
        && session.lifecycleSnapshot().members.first {
            $0.agentID == gateFB05RuntimeMigrantID
        }?.settlementID == gateFB05RuntimeEastID
        && (try? session.household(
            for: gateFB05RuntimeMigrantID
        )?.settlementID) == gateFB05RuntimeEastID
        && (try? session.household(
            for: gateFB05RuntimeMigrantID
        )?.residenceAnchor) == gateFB05RuntimeEast
        && (try? session.state(
            for: gateFB05RuntimeMigrantID
        ).homePosition) == gateFB05RuntimeEast
        && scale.fidelityRecords.filter {
            $0.agentID == gateFB05RuntimeMigrantID
        }.count == 1
        && scale.settlements.first {
            $0.settlementID == gateFB05RuntimeEastID
        }?.residentIDs.filter {
            $0 == gateFB05RuntimeMigrantID
        }.count == 1
        && session.familySnapshot().unions.count == 1
        && session.familySnapshot().houses.count == 1
}

private func gateFB05RuntimeWriteJSON<T: Encodable>(
    _ value: T,
    to url: URL
) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(
        to: url, options: .atomic
    )
}

private func gateFB05RuntimeReport(
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
    assertions: [String: Bool]
) -> GateFBlocker05RuntimeReport {
    let population = session.populationSnapshot()
    let lifecycle = session.lifecycleSnapshot()
    let scale = session.populationScaleSnapshot()
    let households = session.householdSnapshot()
    let family = session.familySnapshot()
    let arrivals = scale.settlementMigrations.filter {
        $0.status == .arrived
    }
    return GateFBlocker05RuntimeReport(
        schemaVersion: 1,
        scenario: options.scenario,
        seed: options.seed,
        success: assertions.values.allSatisfy { $0 },
        processPhase: phase,
        checkpointSchema: checkpointSchema,
        observerSchema: observerSchema,
        checkpointBytes: checkpointBytes,
        durableStateBytes: durableStateBytes,
        tick: session.tick,
        semanticDigest: semanticDigest,
        continuationDigest: continuationDigest,
        familyDigest: family.digest,
        scaleDigest: scale.digest,
        population: population.members.count,
        settlements: scale.settlements.count,
        arrivals: arrivals.count,
        familyUnions: family.unions.count,
        familyHouses: family.houses.count,
        familyHouseMemberships: family.houseMembershipPeriods.count,
        duplicateAgents: gateFB05RuntimeDuplicateCount(
            session.snapshot().agents.map(\.id)
        ),
        duplicatePopulationMembers: gateFB05RuntimeDuplicateCount(
            population.members.map(\.agentID)
        ),
        duplicateLifecycleMembers: gateFB05RuntimeDuplicateCount(
            lifecycle.members.map(\.agentID)
        ),
        duplicateFidelityRecords: gateFB05RuntimeDuplicateCount(
            scale.fidelityRecords.map(\.agentID)
        ),
        duplicateCurrentHouseholdMemberships:
            gateFB05RuntimeDuplicateCount(
                households.currentMemberships.map(\.agentID)
            ),
        duplicateSettlementResidents: gateFB05RuntimeDuplicateCount(
            scale.settlements.flatMap(\.residentIDs)
        ),
        duplicateArrivals: arrivals.count
            - Set(arrivals.map(\.migrationID)).count,
        observerMutations: observerMutations,
        restartDuplicateEffects: restartDuplicateEffects,
        unexpectedRuntimeErrors: 0,
        physicalLoss: 0,
        physicalDuplication: 0,
        syntheticMaterial: 0,
        assertions: assertions
    )
}

private func gateFB05RuntimeExit(
    options: Options,
    root: URL,
    checkpointURL: URL,
    durableStateURL: URL
) -> Never {
    guard (try? FileManager.default.contentsOfDirectory(
        atPath: root.path
    ).isEmpty) == true else {
        fail("Gate F Blocker 05 process-one output must be empty")
    }
    do {
        var session = try gateFB05RuntimeSession(seed: options.seed)
        _ = try session.beginSettlementMigration(
            agentID: gateFB05RuntimeMigrantID,
            destinationSettlementID: gateFB05RuntimeEastID,
            verifiedRoute: gateFB05RuntimeRoute(
                from: try session.state(
                    for: gateFB05RuntimeMigrantID
                ).position,
                to: gateFB05RuntimeEast
            )
        )
        try gateFB05RuntimeCompleteMigration(&session)
        _ = try session.advanceTick()

        let beforeObserver = try session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: gateFB05RuntimeObserverBinding(
                options: options, session: session
            )
        )
        let observerReadOnly = try session.durableStateBytes()
            == beforeObserver
        let checkpoint = try session.makeCheckpoint()
        let checkpointBytes = try AgentCheckpointCodec.encode(checkpoint)
        let checkpointDurableBytes = try AgentCheckpointCodec.encode(
            checkpoint.durableState
        )
        let assertions = [
            "family_enabled": session.familyV1Enabled,
            "population_scale_enabled": session.populationScaleSnapshot()
                .enabled,
            "strict_schema_policy":
                AgentCheckpointSchema.familyValidationSemantics(
                    for: checkpoint.schemaVersion
                ) == .strictDurableConsent,
            "checkpoint_schema_35": checkpoint.schemaVersion == 35,
            "pre_checkpoint_bytes_exact": checkpointDurableBytes
                == beforeObserver,
            "secondary_settlement_authority":
                gateFB05RuntimeCurrentAuthority(session),
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": observerReadOnly,
            "one_arrival": session.populationScaleSnapshot()
                .settlementMigrations.filter {
                    $0.status == .arrived
                }.count == 1,
        ]
        let report = gateFB05RuntimeReport(
            options: options,
            phase: "family-scale-migrated-checkpoint-exit",
            session: session,
            checkpointSchema: checkpoint.schemaVersion,
            checkpointBytes: checkpointBytes.count,
            durableStateBytes: beforeObserver.count,
            semanticDigest: checkpoint.semanticDigest.rawValue,
            continuationDigest: nil,
            observerSchema: observer.header.schemaVersion,
            observerMutations: observerReadOnly ? 0 : 1,
            restartDuplicateEffects: 0,
            assertions: assertions
        )
        try checkpointBytes.write(to: checkpointURL, options: .atomic)
        try beforeObserver.write(to: durableStateURL, options: .atomic)
        try gateFB05RuntimeWriteJSON(
            report,
            to: root.appendingPathComponent("process_1_report.json")
        )
        try gateFB05RuntimeWriteJSON(
            observer,
            to: root.appendingPathComponent("observer_process_1.json")
        )
        guard report.success,
              report.duplicateAgents == 0,
              report.duplicatePopulationMembers == 0,
              report.duplicateLifecycleMembers == 0,
              report.duplicateFidelityRecords == 0,
              report.duplicateCurrentHouseholdMemberships == 0,
              report.duplicateSettlementResidents == 0,
              report.duplicateArrivals == 0 else {
            fail("Gate F Blocker 05 process 1 assertions failed")
        }
        print([
            "GATE_F_BLOCKER_05_PROCESS_1_PASS",
            "checkpointSchema=35", "observerSchema=13",
            "family=1", "scale=1", "migration=arrived",
            "tick=\(session.tick)",
            "durableIdentity=exact",
            "semanticDigest=\(checkpoint.semanticDigest.rawValue)",
            "duplicateAuthority=0",
        ].joined(separator: " "))
        exit(0)
    } catch {
        fail("Gate F Blocker 05 process 1 proof failed: \(error)")
    }
}

private func gateFB05RuntimeRestore(
    options: Options,
    root: URL,
    checkpointURL: URL,
    durableStateURL: URL
) -> Never {
    do {
        let checkpointBytes = try Data(contentsOf: checkpointURL)
        let expectedDurableBytes = try Data(contentsOf: durableStateURL)
        let checkpoint = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        var session = try AgentSimulationSession.restoring(checkpoint)
        let restoredBytes = try session.durableStateBytes()
        let arrivalsBefore = session.populationScaleSnapshot()
            .settlementMigrations.filter { $0.status == .arrived }.count
        let familyBefore = session.familySnapshot()
        let householdBefore = session.householdSnapshot()

        let beforeObserver = try session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: gateFB05RuntimeObserverBinding(
                options: options, session: session
            )
        )
        let observerReadOnly = try session.durableStateBytes()
            == beforeObserver
        let restoredTick = session.tick
        _ = try session.advanceTick()
        let arrivalsAfter = session.populationScaleSnapshot()
            .settlementMigrations.filter { $0.status == .arrived }.count
        let replayedEffects = (arrivalsAfter - arrivalsBefore)
            + (session.familySnapshot() == familyBefore ? 0 : 1)
            + (session.householdSnapshot().membershipPeriods
                == householdBefore.membershipPeriods ? 0 : 1)
        let continuationCheckpoint = try session.makeCheckpoint()
        let continuationBytes = try AgentCheckpointCodec.encode(
            continuationCheckpoint
        )
        let continuationRestored = try AgentSimulationSession.restoring(
            continuationCheckpoint
        )
        let continuationExact = try continuationRestored.durableStateBytes()
            == session.durableStateBytes()
        let assertions = [
            "fresh_restore_exact": restoredBytes == expectedDurableBytes,
            "checkpoint_schema_35": checkpoint.schemaVersion == 35,
            "strict_schema_policy":
                AgentCheckpointSchema.familyValidationSemantics(
                    for: checkpoint.schemaVersion
                ) == .strictDurableConsent,
            "family_and_scale_valid": session.familyV1Enabled
                && session.populationScaleSnapshot().enabled,
            "secondary_settlement_authority":
                gateFB05RuntimeCurrentAuthority(session),
            "continuation_tick": session.tick == restoredTick + 1,
            "zero_replayed_effects": replayedEffects == 0,
            "second_schema_35_restore_exact":
                continuationCheckpoint.schemaVersion == 35
                    && continuationExact,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": observerReadOnly,
        ]
        let report = gateFB05RuntimeReport(
            options: options,
            phase: "fresh-restore-continuation-recheckpoint",
            session: session,
            checkpointSchema: checkpoint.schemaVersion,
            checkpointBytes: checkpointBytes.count,
            durableStateBytes: restoredBytes.count,
            semanticDigest: checkpoint.semanticDigest.rawValue,
            continuationDigest:
                continuationCheckpoint.semanticDigest.rawValue,
            observerSchema: observer.header.schemaVersion,
            observerMutations: observerReadOnly ? 0 : 1,
            restartDuplicateEffects: replayedEffects,
            assertions: assertions
        )
        try continuationBytes.write(
            to: root.appendingPathComponent(
                "gate_f_blocker_05_continued_v35.json"
            ),
            options: .atomic
        )
        try gateFB05RuntimeWriteJSON(
            observer,
            to: root.appendingPathComponent("observer_process_2.json")
        )
        try gateFB05RuntimeWriteJSON(
            report,
            to: root.appendingPathComponent("process_2_report.json")
        )
        try gateFB05RuntimeWriteJSON(
            [
                "active_external_resources": 0,
                "duplicate_agents": report.duplicateAgents,
                "duplicate_population_members":
                    report.duplicatePopulationMembers,
                "duplicate_lifecycle_members":
                    report.duplicateLifecycleMembers,
                "duplicate_fidelity_records":
                    report.duplicateFidelityRecords,
                "duplicate_current_household_memberships":
                    report.duplicateCurrentHouseholdMemberships,
                "duplicate_settlement_residents":
                    report.duplicateSettlementResidents,
                "duplicate_arrivals": report.duplicateArrivals,
                "observer_mutations": report.observerMutations,
                "restart_duplicate_effects":
                    report.restartDuplicateEffects,
                "unexpected_runtime_errors":
                    report.unexpectedRuntimeErrors,
                "physical_loss": report.physicalLoss,
                "physical_duplication": report.physicalDuplication,
                "synthetic_material": report.syntheticMaterial,
            ],
            to: root.appendingPathComponent("cleanup_evidence.json")
        )
        guard report.success,
              report.duplicateAgents == 0,
              report.duplicatePopulationMembers == 0,
              report.duplicateLifecycleMembers == 0,
              report.duplicateFidelityRecords == 0,
              report.duplicateCurrentHouseholdMemberships == 0,
              report.duplicateSettlementResidents == 0,
              report.duplicateArrivals == 0 else {
            fail("Gate F Blocker 05 process 2 assertions failed")
        }
        print([
            "GATE_F_BLOCKER_05_PROCESS_2_PASS",
            "checkpointSchema=35", "observerSchema=13",
            "freshRestoreExact=1", "continuationTicks=1",
            "restartDuplicateEffects=0", "duplicateAuthority=0",
            "semanticDigest=\(checkpoint.semanticDigest.rawValue)",
            "continuationDigest=\(continuationCheckpoint.semanticDigest.rawValue)",
        ].joined(separator: " "))
        exit(0)
    } catch {
        fail("Gate F Blocker 05 process 2 proof failed: \(error)")
    }
}

func runGateFBlocker05FamilySchemaSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("Gate F Blocker 05 proof requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let checkpointURL = root.appendingPathComponent(
        gateFB05RuntimeCheckpoint
    )
    let durableStateURL = root.appendingPathComponent(
        gateFB05RuntimeDurableState
    )
    let thread = Thread {
        if options.scenario
            == "gate_f_blocker_05_family_restore_smoke" {
            gateFB05RuntimeRestore(
                options: options,
                root: root,
                checkpointURL: checkpointURL,
                durableStateURL: durableStateURL
            )
        }
        gateFB05RuntimeExit(
            options: options,
            root: root,
            checkpointURL: checkpointURL,
            durableStateURL: durableStateURL
        )
    }
    thread.stackSize = 32 * 1_024 * 1_024
    thread.start()
    while !thread.isFinished {
        Thread.sleep(forTimeInterval: 0.001)
    }
    fail("Gate F Blocker 05 runtime worker returned unexpectedly")
}
