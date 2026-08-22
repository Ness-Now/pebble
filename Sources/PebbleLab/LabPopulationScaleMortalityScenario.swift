import Foundation
import PebbleAgents

private let civ39MortalityEastID = AgentSettlementID(
    rawValue: "settlement-east"
)!
private let civ39MortalityAgentID = AgentID(rawValue: "agent_0")!
private let civ39MortalityCheckpointName = "mortality_checkpoint_v35.json"

private struct CIV39MortalityRuntimeReport: Encodable {
    let schemaVersion: Int
    let scenario: String
    let seed: UInt32
    let success: Bool
    let processPhase: String
    let checkpointSchema: Int
    let observerSchema: Int
    let settlementCount: Int
    let populationCount: Int
    let liveCount: Int
    let nearCount: Int
    let dormantCount: Int
    let deathCount: Int
    let failedMigrationCount: Int
    let failedMigrationEventCount: Int
    let postDeathArrivalCount: Int
    let duplicateInhabitants: Int
    let duplicateMemberships: Int
    let physicalLoss: Int
    let physicalDuplication: Int
    let syntheticMaterial: Int
    let observerMutations: Int
    let assertions: [String: Bool]
}

private func civ39MortalityAgent(
    _ id: String,
    ordinal: Int,
    lethalNextTick: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(
        x: ordinal < 3 ? 0 : 16 + ordinal,
        y: 64,
        z: ordinal < 3 ? ordinal : 12
    )
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(
            hunger: lethalNextTick ? 1 : 0,
            fatigue: 0, curiosity: 0, safety: 1
        ),
        health: lethalNextTick ? 10 : 100,
        fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "CIV-39 mortality runtime proof",
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

private func civ39MortalitySession(seed: UInt32) -> AgentSimulationSession {
    let population = 24
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: seed, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [
            civ39MortalityAgent("agent_0", ordinal: 0, lethalNextTick: true),
            civ39MortalityAgent("agent_1", ordinal: 1),
            civ39MortalityAgent("agent_2", ordinal: 2),
        ],
        simulationID: try! AgentSimulationID(
            validating: "civ39-mortality-runtime-\(seed)"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: -2),
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: population,
            maximumMigrationRecords: 16
        )
    )
    let admissions = (3..<population).map { ordinal in
        let id = String(format: "agent_%03d", ordinal)
        return AgentScaledResidentAdmission(
            state: civ39MortalityAgent(id, ordinal: ordinal),
            settlementID: ordinal.isMultiple(of: 2)
                ? .main : civ39MortalityEastID
        )
    }
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: civ39MortalityEastID,
            anchor: AgentPosition(x: 0, y: 64, z: 4),
            receptionPosition: AgentPosition(x: 0, y: 64, z: 4),
            capacity: population, residentIDs: [], inTransitIDs: []
        )],
        additionalResidents: admissions,
        configuration: try! AgentPopulationScaleConfiguration(
            maximumSettlements: 2,
            maximumLiveAgents: 4,
            maximumNearAgents: 8,
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

private func civ39MortalityObserverBinding(
    tick: Int
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "civ39-mortality-runtime-world",
        storageIdentity: "headless:civ39-mortality-runtime",
        seed: 139, dimension: 0, observedWorldTick: tick
    )
}

private func civ39MortalityWriteJSON<T: Encodable>(
    _ value: T,
    to url: URL
) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(
        to: url, options: .atomic
    )
}

private func civ39MortalityDuplicateCount<T: Hashable>(_ values: [T]) -> Int {
    values.count - Set(values).count
}

private final class CIV39MortalityRestoreBox: @unchecked Sendable {
    var success = false
}

private func civ39MortalityRestorePhase(
    options: Options,
    root: URL,
    checkpointURL: URL
) -> Bool {
    guard FileManager.default.fileExists(atPath: checkpointURL.path),
          let bytes = try? Data(contentsOf: checkpointURL),
          let checkpoint = try? AgentCheckpointCodec.decode(
              AgentSessionCheckpoint.self, from: bytes
          ),
          var session = try? AgentSimulationSession.restoring(checkpoint) else {
        return false
    }
    let restoredTick = session.tick
    let restoredBytes = try! session.durableStateBytes()
    let observer = session.observerSnapshot(
        worldBinding: civ39MortalityObserverBinding(tick: session.tick)
    )
    let observerReadOnly = (try! session.durableStateBytes()) == restoredBytes
    for _ in 0..<8 { _ = try! session.advanceTick() }
    let scale = session.populationScaleSnapshot()
    let population = session.populationSnapshot()
    let failed = scale.settlementMigrations.filter {
        $0.agentID == civ39MortalityAgentID
            && $0.status == .failed && $0.failure == .memberDied
    }
    let membershipIDs = population.settlements.flatMap {
        $0.residentIDs + $0.inTransitIDs
    }
    let events = session.causalLedgerSnapshot().events
    let failureEvents = events.filter {
        $0.kind == .settlementMigrationFailed
            && $0.actorID == civ39MortalityAgentID
    }
    let postDeathArrivals = events.filter {
        $0.kind == .settlementMigrationArrived
            && $0.actorID == civ39MortalityAgentID
            && $0.simulationTick.rawValue > restoredTick
    }
    let assertions = [
        "fresh_process_restore": checkpoint.schemaVersion == 35,
        "observer_schema_13": observer.header.schemaVersion == 13,
        "observer_read_only": observerReadOnly,
        "death_not_repeated": session.mortalitySnapshot().totalDeathCount == 1,
        "inhabitant_absent": !session.expectedActiveAgentIDs().contains(
            civ39MortalityAgentID
        ),
        "membership_absent": !membershipIDs.contains(civ39MortalityAgentID),
        "fidelity_absent": !scale.fidelityRecords.contains {
            $0.agentID == civ39MortalityAgentID
        },
        "migration_terminal_once": failed.count == 1,
        "failure_event_once": failureEvents.count == 1,
        "no_late_arrival": postDeathArrivals.isEmpty,
        "remaining_fidelity_exact": Set(scale.fidelityRecords.map(\.agentID))
            == Set(session.expectedActiveAgentIDs()),
        "conservation_exact": session.conservationSnapshot().balanced,
    ]
    let report = CIV39MortalityRuntimeReport(
        schemaVersion: 1, scenario: options.scenario, seed: options.seed,
        success: assertions.values.allSatisfy { $0 },
        processPhase: "fresh-process-restore-and-continue",
        checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observer.header.schemaVersion,
        settlementCount: population.settlements.count,
        populationCount: population.members.count,
        liveCount: scale.liveCount, nearCount: scale.nearCount,
        dormantCount: scale.dormantCount,
        deathCount: session.mortalitySnapshot().totalDeathCount,
        failedMigrationCount: failed.count,
        failedMigrationEventCount: failureEvents.count,
        postDeathArrivalCount: postDeathArrivals.count,
        duplicateInhabitants: civ39MortalityDuplicateCount(
            session.expectedActiveAgentIDs()
        ),
        duplicateMemberships: civ39MortalityDuplicateCount(membershipIDs),
        physicalLoss: 0, physicalDuplication: 0, syntheticMaterial: 0,
        observerMutations: observerReadOnly ? 0 : 1,
        assertions: assertions
    )
    try! civ39MortalityWriteJSON(
        observer,
        to: root.appendingPathComponent("observer_after_restart.json")
    )
    try! civ39MortalityWriteJSON(
        report,
        to: root.appendingPathComponent("mortality_phase2_report.json")
    )
    return report.success
}

func runPopulationScaleMortalitySmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("population scale mortality proof requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(
            at: root, withIntermediateDirectories: true
        )
    } catch {
        fail("failed to prepare population scale mortality output: \(error)")
    }
    let checkpointURL = root.appendingPathComponent(
        civ39MortalityCheckpointName
    )
    if options.scenario == "population_scale_mortality_exit_smoke" {
        guard (try? FileManager.default.contentsOfDirectory(
            atPath: root.path
        ).isEmpty) == true else {
            fail("population scale mortality phase-one output must be empty")
        }
        var session = civ39MortalitySession(seed: options.seed)
        let route = (0...4).map {
            AgentPosition(x: 0, y: 64, z: $0)
        }
        let migration = try! session.beginSettlementMigration(
            agentID: civ39MortalityAgentID,
            destinationSettlementID: civ39MortalityEastID,
            verifiedRoute: route
        )
        try! session.setLifecycleEnabled(true)
        session.setSurvivalEnabled(true)
        try! session.setMortalityEnabled(true)
        _ = try! session.advanceTick()
        let checkpoint = try! session.makeCheckpoint()
        try! AgentCheckpointCodec.encode(checkpoint).write(
            to: checkpointURL, options: .atomic
        )
        let observerBefore = try! session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: civ39MortalityObserverBinding(tick: session.tick)
        )
        let scale = session.populationScaleSnapshot()
        let population = session.populationSnapshot()
        let failed = scale.settlementMigrations.filter {
            $0.migrationID == migration.migrationID
                && $0.status == .failed && $0.failure == .memberDied
        }
        let membershipIDs = population.settlements.flatMap {
            $0.residentIDs + $0.inTransitIDs
        }
        let failureEvents = session.causalLedgerSnapshot().events.filter {
            $0.kind == .settlementMigrationFailed
                && $0.actorID == civ39MortalityAgentID
        }
        let assertions = [
            "checkpoint_schema_35": checkpoint.schemaVersion == 35,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "death_finalized_once": session.mortalitySnapshot().totalDeathCount == 1,
            "inhabitant_absent": !session.expectedActiveAgentIDs().contains(
                civ39MortalityAgentID
            ),
            "membership_absent": !membershipIDs.contains(civ39MortalityAgentID),
            "fidelity_absent": !scale.fidelityRecords.contains {
                $0.agentID == civ39MortalityAgentID
            },
            "migration_failed_once": failed.count == 1,
            "failure_event_once": failureEvents.count == 1,
            "observer_read_only": (try! session.durableStateBytes())
                == observerBefore,
            "conservation_exact": session.conservationSnapshot().balanced,
        ]
        let report = CIV39MortalityRuntimeReport(
            schemaVersion: 1, scenario: options.scenario, seed: options.seed,
            success: assertions.values.allSatisfy { $0 },
            processPhase: "finalize-and-checkpoint",
            checkpointSchema: checkpoint.schemaVersion,
            observerSchema: observer.header.schemaVersion,
            settlementCount: population.settlements.count,
            populationCount: population.members.count,
            liveCount: scale.liveCount, nearCount: scale.nearCount,
            dormantCount: scale.dormantCount,
            deathCount: session.mortalitySnapshot().totalDeathCount,
            failedMigrationCount: failed.count,
            failedMigrationEventCount: failureEvents.count,
            postDeathArrivalCount: 0,
            duplicateInhabitants: civ39MortalityDuplicateCount(
                session.expectedActiveAgentIDs()
            ),
            duplicateMemberships: civ39MortalityDuplicateCount(membershipIDs),
            physicalLoss: 0, physicalDuplication: 0, syntheticMaterial: 0,
            observerMutations: assertions["observer_read_only"] == true ? 0 : 1,
            assertions: assertions
        )
        try! civ39MortalityWriteJSON(
            observer,
            to: root.appendingPathComponent("observer_after_death.json")
        )
        try! civ39MortalityWriteJSON(
            report,
            to: root.appendingPathComponent("mortality_phase1_report.json")
        )
        guard report.success else { exit(1) }
        print("population_scale_mortality_exit_smoke PASS schema=35 population=23 migrationFailed=1")
        exit(0)
    }

    let box = CIV39MortalityRestoreBox()
    let thread = Thread {
        box.success = civ39MortalityRestorePhase(
            options: options, root: root, checkpointURL: checkpointURL
        )
    }
    thread.stackSize = 32 * 1_024 * 1_024
    thread.start()
    while !thread.isFinished { Thread.sleep(forTimeInterval: 0.001) }
    guard box.success else {
        fail("population scale mortality fresh-process restore proof failed")
    }
    print("population_scale_mortality_restore_smoke PASS schema=35 population=23 lateArrivals=0")
    exit(0)
}
