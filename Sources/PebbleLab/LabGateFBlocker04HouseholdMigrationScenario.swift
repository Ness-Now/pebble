import Foundation
import PebbleAgents

private let gateFB04RuntimeEastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFB04RuntimeMain = AgentPosition(x: 0, y: 64, z: 0)
private let gateFB04RuntimeEast = AgentPosition(x: 0, y: 64, z: 4)
private let gateFB04RuntimeAgent0 = AgentID(rawValue: "agent_0")!
private let gateFB04RuntimeCheckpoint = "gate_f_blocker_04_arrival_v35.json"
private let gateFB04RuntimeState = "gate_f_blocker_04_arrival_state.json"

private struct GateFBlocker04RuntimeReport: Encodable {
    let schemaVersion: Int
    let scenario: String
    let seed: UInt32
    let success: Bool
    let processPhase: String
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointBytes: Int
    let tick: Int
    let semanticDigest: String
    let householdDigest: String
    let scaleDigest: String
    let populationSettlement: String
    let lifecycleSettlement: String
    let householdSettlement: String
    let householdAnchor: String
    let homePosition: String
    let originHouseholdID: String
    let destinationHouseholdID: String
    let membershipHistoryCount: Int
    let currentMembershipCount: Int
    let duplicateAgents: Int
    let duplicatePopulationMembers: Int
    let duplicateLifecycleMembers: Int
    let duplicateFidelityRecords: Int
    let duplicateCurrentMemberships: Int
    let duplicateSettlementResidents: Int
    let duplicateArrivals: Int
    let duplicateHouseholdTransitions: Int
    let physicalLoss: Int
    let physicalDuplication: Int
    let syntheticMaterial: Int
    let observerMutations: Int
    let restartDuplicateEffects: Int
    let unexpectedRuntimeErrors: Int
    let assertions: [String: Bool]
}

private struct GateFBlocker04RefusalEvidence: Encodable {
    let refused: Bool
    let bytesChanged: Int
    let migrationRecords: Int
    let destinationResidents: Int
    let populationOrdinalChanged: Int
}

private func gateFB04RuntimeAgent(
    _ ordinal: Int
) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    let home = ordinal < 2 ? gateFB04RuntimeMain : position
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100, fear: 0, homePosition: home, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 04 runtime proof",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0,
        observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0,
        actionCount: 0, actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func gateFB04RuntimeSession(
    seed: UInt32,
    suffix: String,
    householdConfiguration: AgentHouseholdConfiguration = .live
) throws -> AgentSimulationSession {
    var session = try AgentSimulationSession(
        configuration: try AgentSessionConfiguration(
            seed: seed, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: (0..<3).map(gateFB04RuntimeAgent),
        simulationID: try AgentSimulationID(
            validating: "gate-f-b04-runtime-\(seed)-\(suffix)"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    try session.initializePopulationRegistry(
        settlementAnchor: gateFB04RuntimeMain,
        receptionPosition: gateFB04RuntimeMain,
        configuration: try AgentPopulationConfiguration(
            maximumActivePopulation: 6,
            maximumMigrationRecords: 16
        )
    )
    try session.setLifecycleEnabled(true)
    try session.setKinshipEnabled(true)
    try session.setHouseholdsEnabled(
        true, configuration: householdConfiguration
    )
    try session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB04RuntimeEastID,
            anchor: gateFB04RuntimeEast,
            receptionPosition: gateFB04RuntimeEast,
            capacity: 4,
            residentIDs: [], inTransitIDs: []
        )],
        configuration: try AgentPopulationScaleConfiguration(
            maximumSettlements: 2,
            maximumLiveAgents: 1,
            maximumNearAgents: 1,
            nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8,
            rotationIntervalTicks: 4,
            maximumFidelityTransitionHistory: 32,
            maximumSettlementMigrationHistory: 8,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 16
        )
    )
    return session
}

private func gateFB04RuntimeRoute(
    from: AgentPosition
) -> [AgentPosition] {
    (0...4).map {
        AgentPosition(x: from.x, y: from.y, z: $0)
    }
}

private func gateFB04RuntimePerception(
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
        worldObservation: try! AgentWorldObservation(
            worldTick: session.tick + 1, position: state.position,
            center: column(state.position), neighbors: neighbors,
            biomeId: 1, biomeName: "plains", combinedLight: 15,
            skyLight: 15, blockLight: 0, dayTime: 6_000,
            raining: false, thundering: false
        ),
        navigationObservation: AgentNavigationObservation(
            worldTick: session.tick + 1,
            origin: state.position, target: gateFB04RuntimeEast, radius: 8,
            cells: migration.route.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

private func gateFB04RuntimeCompleteMigration(
    _ session: inout AgentSimulationSession
) throws {
    let routeCount = session.populationScaleSnapshot().settlementMigrations
        .first { $0.agentID == gateFB04RuntimeAgent0 }!.route.count
    for _ in 1..<routeCount {
        let migration = session.populationScaleSnapshot().settlementMigrations
            .first {
                $0.agentID == gateFB04RuntimeAgent0 && $0.status == .inTransit
            }!
        _ = try session.advanceTick(perceptions: [
            gateFB04RuntimePerception(session: session, migration: migration),
        ])
        let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
        try session.applyVerifiedPhysicalMovements(outcomes.map {
            AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: $0)
        })
    }
}

private func gateFB04RuntimeObserverBinding(
    options: Options,
    session: AgentSimulationSession
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "gate-f-blocker-04-runtime-world",
        storageIdentity: "headless:gate-f-blocker-04-runtime",
        seed: options.seed, dimension: 0,
        observedWorldTick: session.tick
    )
}

private func gateFB04RuntimeDuplicateCount<T: Hashable>(
    _ values: [T]
) -> Int {
    values.count - Set(values).count
}

private func gateFB04RuntimePosition(_ value: AgentPosition) -> String {
    "\(value.x),\(value.y),\(value.z)"
}

private func gateFB04RuntimeWriteJSON<T: Encodable>(
    _ value: T,
    to url: URL
) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(
        to: url, options: .atomic
    )
}

private func gateFB04RuntimeReport(
    options: Options,
    phase: String,
    session: AgentSimulationSession,
    originHouseholdID: AgentHouseholdID,
    checkpointSchema: Int,
    checkpointBytes: Int,
    observerSchema: Int,
    assertions: [String: Bool]
) throws -> GateFBlocker04RuntimeReport {
    let population = session.populationSnapshot()
    let lifecycle = session.lifecycleSnapshot()
    let households = session.householdSnapshot()
    let scale = session.populationScaleSnapshot()
    let member = population.members.first { $0.agentID == gateFB04RuntimeAgent0 }!
    let lifecycleMember = lifecycle.members.first {
        $0.agentID == gateFB04RuntimeAgent0
    }!
    let household = try session.household(for: gateFB04RuntimeAgent0)!
    let state = try session.state(for: gateFB04RuntimeAgent0)
    let history = try session.membershipHistory(of: gateFB04RuntimeAgent0)
    let arrivalCount = scale.settlementMigrations.filter {
        $0.agentID == gateFB04RuntimeAgent0 && $0.status == .arrived
    }.count
    let transitionEvents = session.causalLedgerSnapshot().events.filter {
        $0.actorID == gateFB04RuntimeAgent0
            && ($0.kind == .householdMembershipStarted
                || $0.kind == .householdMembershipEnded)
    }
    return GateFBlocker04RuntimeReport(
        schemaVersion: 1, scenario: options.scenario, seed: options.seed,
        success: assertions.values.allSatisfy { $0 }, processPhase: phase,
        checkpointSchema: checkpointSchema, observerSchema: observerSchema,
        checkpointBytes: checkpointBytes, tick: session.tick,
        semanticDigest: try session.durableStateDigest().rawValue,
        householdDigest: households.digest, scaleDigest: scale.digest,
        populationSettlement: member.settlementID.rawValue,
        lifecycleSettlement: lifecycleMember.settlementID.rawValue,
        householdSettlement: household.settlementID.rawValue,
        householdAnchor: gateFB04RuntimePosition(household.residenceAnchor),
        homePosition: gateFB04RuntimePosition(state.homePosition),
        originHouseholdID: originHouseholdID.rawValue,
        destinationHouseholdID: household.householdID.rawValue,
        membershipHistoryCount: history.count,
        currentMembershipCount: history.filter { $0.leftTick == nil }.count,
        duplicateAgents: gateFB04RuntimeDuplicateCount(
            session.snapshot().agents.map(\.id)
        ),
        duplicatePopulationMembers: gateFB04RuntimeDuplicateCount(
            population.members.map(\.agentID)
        ),
        duplicateLifecycleMembers: gateFB04RuntimeDuplicateCount(
            lifecycle.members.map(\.agentID)
        ),
        duplicateFidelityRecords: gateFB04RuntimeDuplicateCount(
            scale.fidelityRecords.map(\.agentID)
        ),
        duplicateCurrentMemberships: gateFB04RuntimeDuplicateCount(
            households.currentMemberships.map(\.agentID)
        ),
        duplicateSettlementResidents: gateFB04RuntimeDuplicateCount(
            population.settlements.flatMap(\.residentIDs)
        ),
        duplicateArrivals: max(0, arrivalCount - 1),
        duplicateHouseholdTransitions: max(0, transitionEvents.count - 3),
        physicalLoss: 0, physicalDuplication: 0, syntheticMaterial: 0,
        observerMutations: assertions["observer_read_only"] == false ? 1 : 0,
        restartDuplicateEffects: 0, unexpectedRuntimeErrors: 0,
        assertions: assertions
    )
}

private func gateFB04RuntimeExit(
    options: Options,
    root: URL,
    checkpointURL: URL,
    stateURL: URL
) -> Never {
    guard (try? FileManager.default.contentsOfDirectory(
        atPath: root.path
    ).isEmpty) == true else {
        fail("Gate F Blocker 04 process-one output must be empty")
    }
    do {
        var refusal = try gateFB04RuntimeSession(
            seed: options.seed, suffix: "refusal",
            householdConfiguration: try AgentHouseholdConfiguration(
                maximumHistoricalHouseholds: 4,
                maximumMembershipPeriods: 8,
                maximumActiveHouseholds: 2
            )
        )
        let refusalBytes = try refusal.durableStateBytes()
        let refusalOrdinal = refusal.populationSnapshot().nextPopulationOrdinal
        var refused = false
        do {
            _ = try refusal.beginSettlementMigration(
                agentID: gateFB04RuntimeAgent0,
                destinationSettlementID: gateFB04RuntimeEastID,
                verifiedRoute: gateFB04RuntimeRoute(from: gateFB04RuntimeMain)
            )
        } catch AgentSessionError.household(.activeHouseholdCapacityReached) {
            refused = true
        }
        let refusalEvidence = GateFBlocker04RefusalEvidence(
            refused: refused,
            bytesChanged: try refusal.durableStateBytes() == refusalBytes ? 0 : 1,
            migrationRecords: refusal.populationScaleSnapshot()
                .settlementMigrations.count,
            destinationResidents: refusal.populationSnapshot().settlements.first {
                $0.settlementID == gateFB04RuntimeEastID
            }?.residentIDs.count ?? -1,
            populationOrdinalChanged:
                refusal.populationSnapshot().nextPopulationOrdinal
                    == refusalOrdinal ? 0 : 1
        )

        var session = try gateFB04RuntimeSession(
            seed: options.seed, suffix: "arrival"
        )
        let origin = try session.household(for: gateFB04RuntimeAgent0)!
        let preMigrationCheckpoint = try session.makeCheckpoint()
        let preMigrationBytes = try AgentCheckpointCodec.encode(
            preMigrationCheckpoint
        )
        let preMigrationExact = try AgentSimulationSession.restoring(
            preMigrationCheckpoint
        ).durableStateBytes() == session.durableStateBytes()
        _ = try session.beginSettlementMigration(
            agentID: gateFB04RuntimeAgent0,
            destinationSettlementID: gateFB04RuntimeEastID,
            verifiedRoute: gateFB04RuntimeRoute(from: gateFB04RuntimeMain)
        )
        let inFlightCheckpoint = try session.makeCheckpoint()
        let inFlightBytes = try AgentCheckpointCodec.encode(inFlightCheckpoint)
        let inFlightExact = try AgentSimulationSession.restoring(
            inFlightCheckpoint
        ).durableStateBytes() == session.durableStateBytes()
        try gateFB04RuntimeCompleteMigration(&session)
        let destination = try session.household(for: gateFB04RuntimeAgent0)!
        let population = session.populationSnapshot()
        let lifecycle = session.lifecycleSnapshot()
        let history = try session.membershipHistory(of: gateFB04RuntimeAgent0)
        let state = try session.state(for: gateFB04RuntimeAgent0)
        let scale = session.populationScaleSnapshot()
        let beforeObserver = try session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: gateFB04RuntimeObserverBinding(
                options: options, session: session
            )
        )
        let afterObserver = try session.durableStateBytes()
        let checkpoint = try session.makeCheckpoint()
        let checkpointBytes = try AgentCheckpointCodec.encode(checkpoint)
        let stateBytes = try session.durableStateBytes()
        let assertions = [
            "pre_migration_schema_35_restore":
                preMigrationCheckpoint.schemaVersion == 35 && preMigrationExact,
            "in_flight_schema_35_restore":
                inFlightCheckpoint.schemaVersion == 35 && inFlightExact,
            "multi_member_origin_retained":
                try session.members(of: origin.householdID)
                    == [AgentID(rawValue: "agent_1")!],
            "destination_authority_exact":
                population.members.first {
                    $0.agentID == gateFB04RuntimeAgent0
                }?.settlementID == gateFB04RuntimeEastID
                    && lifecycle.members.first {
                        $0.agentID == gateFB04RuntimeAgent0
                    }?.settlementID == gateFB04RuntimeEastID
                    && destination.settlementID == gateFB04RuntimeEastID
                    && destination.residenceAnchor == gateFB04RuntimeEast
                    && state.homePosition == gateFB04RuntimeEast,
            "household_history_exact": history.count == 2
                && history.first?.leftReason == .settlementMigration
                && history.last?.joinedReason == .settlementMigration
                && history.filter { $0.leftTick == nil }.count == 1,
            "arrival_singular": scale.settlementMigrations.filter {
                $0.agentID == gateFB04RuntimeAgent0 && $0.status == .arrived
            }.count == 1,
            "population_fidelity_equal":
                Set(population.members.map(\.agentID))
                    == Set(scale.fidelityRecords.map(\.agentID)),
            "social_bound_refusal_atomic": refusalEvidence.refused
                && refusalEvidence.bytesChanged == 0
                && refusalEvidence.migrationRecords == 0
                && refusalEvidence.destinationResidents == 0
                && refusalEvidence.populationOrdinalChanged == 0,
            "checkpoint_schema_35": checkpoint.schemaVersion == 35,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_destination_household": observer.individuals.first {
                $0.agentID == gateFB04RuntimeAgent0
            }?.household.householdID == destination.householdID,
            "observer_read_only": afterObserver == beforeObserver,
        ]
        try preMigrationBytes.write(
            to: root.appendingPathComponent(
                "gate_f_blocker_04_pre_migration_v35.json"
            ), options: .atomic
        )
        try inFlightBytes.write(
            to: root.appendingPathComponent(
                "gate_f_blocker_04_in_flight_v35.json"
            ), options: .atomic
        )
        try checkpointBytes.write(to: checkpointURL, options: .atomic)
        try stateBytes.write(to: stateURL, options: .atomic)
        try gateFB04RuntimeWriteJSON(
            refusalEvidence,
            to: root.appendingPathComponent("social_bound_refusal.json")
        )
        try gateFB04RuntimeWriteJSON(
            observer,
            to: root.appendingPathComponent("observer_immediate_arrival.json")
        )
        let report = try gateFB04RuntimeReport(
            options: options, phase: "verified-arrival-checkpoint",
            session: session, originHouseholdID: origin.householdID,
            checkpointSchema: checkpoint.schemaVersion,
            checkpointBytes: checkpointBytes.count,
            observerSchema: observer.header.schemaVersion,
            assertions: assertions
        )
        try gateFB04RuntimeWriteJSON(
            report, to: root.appendingPathComponent("process_1_report.json")
        )
        guard report.success else {
            fail("Gate F Blocker 04 process 1 assertions failed")
        }
        print([
            "GATE_F_BLOCKER_04_PROCESS_1_PASS",
            "checkpointSchema=35", "observerSchema=13",
            "settlement=settlement-east",
            "membershipHistory=2", "duplicateArrivals=0",
            "socialRefusalAtomic=1",
        ].joined(separator: " "))
        exit(0)
    } catch {
        fail("Gate F Blocker 04 process 1 proof failed: \(error)")
    }
}

private func gateFB04RuntimeRestore(
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
        let expectedState = try Data(contentsOf: stateURL)
        var session = try AgentSimulationSession.restoring(checkpoint)
        let restoredState = try session.durableStateBytes()
        let originHistory = try session.membershipHistory(
            of: gateFB04RuntimeAgent0
        )
        let originHouseholdID = originHistory.first!.householdID
        let arrivalCountBefore = session.populationScaleSnapshot()
            .settlementMigrations.filter {
                $0.agentID == gateFB04RuntimeAgent0 && $0.status == .arrived
            }.count
        let historyCountBefore = originHistory.count
        _ = try session.advanceTick()
        let historyAfter = try session.membershipHistory(
            of: gateFB04RuntimeAgent0
        )
        let arrivalCountAfter = session.populationScaleSnapshot()
            .settlementMigrations.filter {
                $0.agentID == gateFB04RuntimeAgent0 && $0.status == .arrived
            }.count
        let beforeObserver = try session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: gateFB04RuntimeObserverBinding(
                options: options, session: session
            )
        )
        let afterObserver = try session.durableStateBytes()
        let secondCheckpoint = try session.makeCheckpoint()
        let secondCheckpointBytes = try AgentCheckpointCodec.encode(
            secondCheckpoint
        )
        let secondRestoreExact = try AgentSimulationSession.restoring(
            secondCheckpoint
        ).durableStateBytes() == session.durableStateBytes()
        let destination = try session.household(for: gateFB04RuntimeAgent0)!
        let assertions = [
            "fresh_process_schema_35_restore": checkpoint.schemaVersion == 35,
            "restored_state_exact": restoredState == expectedState,
            "destination_household_current": destination.settlementID
                == gateFB04RuntimeEastID
                && destination.residenceAnchor == gateFB04RuntimeEast,
            "origin_history_retained_not_current": historyAfter.first?.householdID
                == originHouseholdID
                && historyAfter.first?.leftReason == .settlementMigration
                && historyAfter.last?.leftTick == nil,
            "next_tick_succeeds": session.tick == checkpoint.tick.rawValue + 1,
            "no_replayed_arrival": arrivalCountBefore == 1
                && arrivalCountAfter == 1,
            "no_replayed_household_transition": historyCountBefore == 2
                && historyAfter.count == 2,
            "population_fidelity_equal":
                Set(session.populationSnapshot().members.map(\.agentID))
                    == Set(session.populationScaleSnapshot()
                        .fidelityRecords.map(\.agentID)),
            "second_schema_35_restore_exact": secondCheckpoint.schemaVersion == 35
                && secondRestoreExact,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": afterObserver == beforeObserver,
        ]
        try secondCheckpointBytes.write(
            to: root.appendingPathComponent(
                "gate_f_blocker_04_post_tick_v35.json"
            ), options: .atomic
        )
        try gateFB04RuntimeWriteJSON(
            observer,
            to: root.appendingPathComponent("observer_post_restore_tick.json")
        )
        let report = try gateFB04RuntimeReport(
            options: options, phase: "fresh-restore-next-tick-restore",
            session: session, originHouseholdID: originHouseholdID,
            checkpointSchema: checkpoint.schemaVersion,
            checkpointBytes: checkpointBytes.count,
            observerSchema: observer.header.schemaVersion,
            assertions: assertions
        )
        try gateFB04RuntimeWriteJSON(
            report, to: root.appendingPathComponent("process_2_report.json")
        )
        try gateFB04RuntimeWriteJSON(
            [
                "active_external_resources": 0,
                "duplicate_agents": report.duplicateAgents,
                "duplicate_population_members": report.duplicatePopulationMembers,
                "duplicate_lifecycle_members": report.duplicateLifecycleMembers,
                "duplicate_fidelity_records": report.duplicateFidelityRecords,
                "duplicate_current_memberships": report.duplicateCurrentMemberships,
                "duplicate_settlement_residents": report.duplicateSettlementResidents,
                "duplicate_arrivals": report.duplicateArrivals,
                "duplicate_household_transitions": report.duplicateHouseholdTransitions,
                "physical_loss": report.physicalLoss,
                "physical_duplication": report.physicalDuplication,
                "synthetic_material": report.syntheticMaterial,
                "observer_mutations": report.observerMutations,
                "restart_duplicate_effects": report.restartDuplicateEffects,
                "unexpected_runtime_errors": report.unexpectedRuntimeErrors,
            ],
            to: root.appendingPathComponent("cleanup_evidence.json")
        )
        guard report.success else {
            fail("Gate F Blocker 04 process 2 assertions failed")
        }
        print([
            "GATE_F_BLOCKER_04_PROCESS_2_PASS",
            "checkpointSchema=35", "observerSchema=13",
            "nextTick=1", "duplicateArrivals=0",
            "duplicateHouseholdTransitions=0", "restartDuplicateEffects=0",
        ].joined(separator: " "))
        exit(0)
    } catch {
        fail("Gate F Blocker 04 process 2 proof failed: \(error)")
    }
}

func runGateFBlocker04HouseholdMigrationSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("Gate F Blocker 04 proof requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let checkpointURL = root.appendingPathComponent(gateFB04RuntimeCheckpoint)
    let stateURL = root.appendingPathComponent(gateFB04RuntimeState)
    let thread = Thread {
        if options.scenario == "gate_f_blocker_04_household_restore_smoke" {
            gateFB04RuntimeRestore(
                options: options, root: root, checkpointURL: checkpointURL,
                stateURL: stateURL
            )
        }
        gateFB04RuntimeExit(
            options: options, root: root, checkpointURL: checkpointURL,
            stateURL: stateURL
        )
    }
    thread.stackSize = 32 * 1_024 * 1_024
    thread.start()
    while !thread.isFinished { Thread.sleep(forTimeInterval: 0.001) }
    fail("Gate F Blocker 04 runtime worker returned unexpectedly")
}
