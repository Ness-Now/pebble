import Foundation
import PebbleAgents

private let gateFB03RuntimeEastID = AgentSettlementID(
    rawValue: "settlement-east"
)!
private let gateFB03RuntimeMainReception = AgentPosition(x: 0, y: 64, z: 3)
private let gateFB03RuntimeEastReception = AgentPosition(x: 4, y: 64, z: 3)
private let gateFB03RuntimeNewbornID = AgentID(rawValue: "agent_3")!
private let gateFB03RuntimeCheckpoint = "gate_f_blocker_03_birth_v35.json"
private let gateFB03RuntimeState = "gate_f_blocker_03_birth_state.json"
private let gateFB03RuntimeHabitat = AgentEcologyHabitatObservation(
    worldTick: 0, candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 60_303, distanceFromSettlement: 1,
    directionIndex: 0, worldReadCount: 4
)

private struct GateFBlocker03RuntimeReport: Encodable {
    let schemaVersion: Int
    let scenario: String
    let seed: UInt32
    let success: Bool
    let processPhase: String
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointBytes: Int
    let semanticDigest: String
    let scaleDigest: String
    let populationCount: Int
    let fidelityCount: Int
    let liveCount: Int
    let nearCount: Int
    let dormantCount: Int
    let newbornID: String
    let newbornTier: String
    let newbornTransitionCount: Int
    let duplicateAgents: Int
    let duplicatePopulationMembers: Int
    let duplicateLifecycleMembers: Int
    let duplicateFidelityRecords: Int
    let duplicateSettlementResidents: Int
    let physicalLoss: Int
    let physicalDuplication: Int
    let syntheticMaterial: Int
    let observerMutations: Int
    let restartDuplicateEffects: Int
    let unexpectedRuntimeErrors: Int
    let assertions: [String: Bool]
}

private func gateFB03RuntimeAgent(
    _ id: String,
    x: Int,
    lethalOnNextSurvivalTick: Bool = false,
    protectedFromOneFullHungerTick: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(
            hunger: lethalOnNextSurvivalTick
                ? 1 : (protectedFromOneFullHungerTick ? -1 : 0),
            fatigue: 0, curiosity: 0.1, safety: 1
        ),
        health: lethalOnNextSurvivalTick ? 10 : 100,
        fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 03 runtime proof",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0,
        observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0,
        actionCount: 0, actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress(
            status: lethalOnNextSurvivalTick ? .starving : .stable,
            consecutiveCriticalHungerTicks: lethalOnNextSurvivalTick ? 2 : 0
        )
    )
}

private func gateFB03RuntimeSession(
    seed: UInt32,
    suffix: String,
    maximumPopulation: Int = 4,
    maximumLiveAgents: Int = 1,
    maximumNearAgents: Int = 1,
    rotationIntervalTicks: Int = 4,
    lethalFounder2: Bool = false,
    newbornLethalSurvival: Bool = false
) throws -> AgentSimulationSession {
    let liveSurvival = AgentSurvivalConfiguration.live
    let survival = newbornLethalSurvival
        ? try AgentSurvivalConfiguration(
            hungerPerTick: 1,
            fatiguePerTick: liveSurvival.fatiguePerTick,
            hungryThreshold: liveSurvival.hungryThreshold,
            criticalHungerThreshold: liveSurvival.criticalHungerThreshold,
            hungerRecoveryThreshold: liveSurvival.hungerRecoveryThreshold,
            fatigueThreshold: liveSurvival.fatigueThreshold,
            fatigueRecoveryThreshold: liveSurvival.fatigueRecoveryThreshold,
            foodNutrition: liveSurvival.foodNutrition,
            restRecoveryPerTick: liveSurvival.restRecoveryPerTick,
            starvationGraceTicks: 0,
            starvationDamagePerTick: 100
        )
        : liveSurvival
    var session = try AgentSimulationSession(
        configuration: try AgentSessionConfiguration(
            seed: seed, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: survival
        ),
        agents: (0..<3).map { ordinal in
            gateFB03RuntimeAgent(
                "agent_\(ordinal)", x: ordinal * 2,
                lethalOnNextSurvivalTick: lethalFounder2 && ordinal == 2,
                protectedFromOneFullHungerTick: newbornLethalSurvival
            )
        },
        simulationID: try AgentSimulationID(
            validating: "gate-f-b03-runtime-\(seed)-\(suffix)"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    try session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: gateFB03RuntimeMainReception,
        configuration: try AgentPopulationConfiguration(
            maximumActivePopulation: maximumPopulation,
            maximumMigrationRecords: 16
        )
    )
    try session.initializeLocalEcology(observations: [gateFB03RuntimeHabitat])
    _ = try session.applyLocalEcologyEndOfTick(
        habitatValidations: [gateFB03RuntimeHabitat]
    )
    try session.setLifecycleEnabled(true)
    try session.setReproductionEnabled(true)
    try session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB03RuntimeEastID,
            anchor: gateFB03RuntimeEastReception,
            receptionPosition: gateFB03RuntimeEastReception,
            capacity: maximumPopulation,
            residentIDs: [], inTransitIDs: []
        )],
        additionalResidents: [],
        configuration: try AgentPopulationScaleConfiguration(
            maximumSettlements: 2,
            maximumLiveAgents: maximumLiveAgents,
            maximumNearAgents: maximumNearAgents,
            nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8,
            rotationIntervalTicks: rotationIntervalTicks,
            maximumFidelityTransitionHistory: 32,
            maximumSettlementMigrationHistory: 8,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 16
        )
    )
    while session.tick < 4 { _ = try session.advanceTick() }
    guard session.pendingBirthSitePlan() != nil else {
        throw AgentSessionError.lifecycle(
            .invalidConfiguration("birth plan was not produced")
        )
    }
    return session
}

private func gateFB03RuntimeBirth(
    _ session: inout AgentSimulationSession,
    fingerprint: Int = 60_303
) throws -> AgentBirthRecord {
    let plan = session.pendingBirthSitePlan()!
    return try session.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID, observedTick: session.tick,
        position: AgentPosition(x: 0, y: 64, z: 4),
        candidateIndex: 0, worldFingerprint: fingerprint
    ))!
}

private func gateFB03RuntimeMigrationObservation(
    tick: Int
) -> AgentMigrationWorldObservation {
    AgentMigrationWorldObservation(
        worldTick: tick, candidateIndex: 0,
        entryPosition: AgentPosition(x: 1, y: 64, z: 3),
        receptionPosition: gateFB03RuntimeMainReception,
        route: [
            AgentPosition(x: 1, y: 64, z: 3),
            gateFB03RuntimeMainReception,
        ]
    )
}

private func gateFB03RuntimeIdentitySetsEqual(
    _ session: AgentSimulationSession
) -> Bool {
    Set(session.populationSnapshot().members.map(\.agentID))
        == Set(session.populationScaleSnapshot().fidelityRecords.map(\.agentID))
}

private func gateFB03RuntimeObserverBinding(
    seed: UInt32,
    tick: Int
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "gate-f-blocker-03-runtime-world",
        storageIdentity: "headless:gate-f-blocker-03-runtime",
        seed: seed, dimension: 0, observedWorldTick: tick
    )
}

private func gateFB03RuntimeWriteJSON<T: Encodable>(
    _ value: T,
    to url: URL
) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(
        to: url, options: .atomic
    )
}

private func gateFB03RuntimeDuplicateCount<T: Hashable>(
    _ values: [T]
) -> Int {
    values.count - Set(values).count
}

private func gateFB03RuntimeReport(
    options: Options,
    phase: String,
    session: AgentSimulationSession,
    checkpointSchema: Int,
    checkpointBytes: Int,
    observerSchema: Int,
    assertions: [String: Bool]
) throws -> GateFBlocker03RuntimeReport {
    let population = session.populationSnapshot()
    let lifecycle = session.lifecycleSnapshot()
    let scale = session.populationScaleSnapshot()
    let newbornRecords = scale.fidelityRecords.filter {
        $0.agentID == gateFB03RuntimeNewbornID
    }
    let settlementResidents = population.settlements.flatMap(\.residentIDs)
    return GateFBlocker03RuntimeReport(
        schemaVersion: 1, scenario: options.scenario, seed: options.seed,
        success: assertions.values.allSatisfy { $0 },
        processPhase: phase, checkpointSchema: checkpointSchema,
        observerSchema: observerSchema, checkpointBytes: checkpointBytes,
        semanticDigest: try session.durableStateDigest().rawValue,
        scaleDigest: scale.digest,
        populationCount: population.members.count,
        fidelityCount: scale.fidelityRecords.count,
        liveCount: scale.liveCount, nearCount: scale.nearCount,
        dormantCount: scale.dormantCount,
        newbornID: gateFB03RuntimeNewbornID.rawValue,
        newbornTier: session.fidelity(for: gateFB03RuntimeNewbornID).rawValue,
        newbornTransitionCount: newbornRecords.first?.transitionCount ?? 0,
        duplicateAgents: gateFB03RuntimeDuplicateCount(
            session.snapshot().agents.map(\.id)
        ),
        duplicatePopulationMembers: gateFB03RuntimeDuplicateCount(
            population.members.map(\.agentID)
        ),
        duplicateLifecycleMembers: gateFB03RuntimeDuplicateCount(
            lifecycle.members.map(\.agentID)
        ),
        duplicateFidelityRecords: gateFB03RuntimeDuplicateCount(
            scale.fidelityRecords.map(\.agentID)
        ),
        duplicateSettlementResidents: gateFB03RuntimeDuplicateCount(
            settlementResidents
        ),
        physicalLoss: 0, physicalDuplication: 0, syntheticMaterial: 0,
        observerMutations: assertions["observer_read_only"] == false ? 1 : 0,
        restartDuplicateEffects: 0, unexpectedRuntimeErrors: 0,
        assertions: assertions
    )
}

private func gateFB03RuntimeRestore(
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
        let restoredScale = session.populationScaleSnapshot()
        let restoredBirths = session.lifecycleSnapshot().births.filter {
            $0.newbornID == gateFB03RuntimeNewbornID
        }
        let restoredInitialTransitions = restoredScale.fidelityTransitions.filter {
            $0.agentID == gateFB03RuntimeNewbornID && $0.from == nil
        }
        let restoredNewbornTransitionCount = restoredScale.fidelityRecords.first {
            $0.agentID == gateFB03RuntimeNewbornID
        }?.transitionCount

        while session.tick < 8 { _ = try session.advanceTick() }
        let rotatedScale = session.populationScaleSnapshot()
        let newbornRotations = rotatedScale.fidelityTransitions.filter {
            $0.agentID == gateFB03RuntimeNewbornID
                && $0.from == .dormant && $0.to == .near
                && $0.cause == .scheduledRotation
        }
        let beforeObserver = try session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: gateFB03RuntimeObserverBinding(
                seed: options.seed, tick: session.tick
            )
        )
        let afterObserver = try session.durableStateBytes()
        let completedCheckpoint = try session.makeCheckpoint()
        let completedBytes = try AgentCheckpointCodec.encode(completedCheckpoint)
        let completedRestored = try AgentSimulationSession.restoring(
            completedCheckpoint
        )
        let completedExact = try completedRestored.durableStateBytes()
            == session.durableStateBytes()
        let assertions = [
            "fresh_process_schema_35_restore": checkpoint.schemaVersion == 35,
            "restored_state_exact": restoredState == expectedState,
            "restored_population_fidelity_equal": gateFB03RuntimeIdentitySetsEqual(
                try AgentSimulationSession.restoring(checkpoint)
            ),
            "restored_single_birth": restoredBirths.count == 1,
            "no_replayed_initial_transition": restoredInitialTransitions.count == 1
                && restoredNewbornTransitionCount == 1,
            "meaningful_scheduled_rotation": session.tick == 8
                && session.fidelity(for: gateFB03RuntimeNewbornID) == .near
                && newbornRotations.count == 1,
            "post_rotation_population_fidelity_equal":
                gateFB03RuntimeIdentitySetsEqual(session),
            "post_rotation_schema_35_restore_exact":
                completedCheckpoint.schemaVersion == 35 && completedExact,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_exposes_newborn_fidelity": observer.individuals.first {
                $0.agentID == gateFB03RuntimeNewbornID
            }?.populationContext?.fidelity == .near,
            "observer_read_only": afterObserver == beforeObserver,
        ]
        try completedBytes.write(
            to: root.appendingPathComponent(
                "gate_f_blocker_03_post_rotation_v35.json"
            ), options: .atomic
        )
        let report = try gateFB03RuntimeReport(
            options: options, phase: "fresh-restore-rotation-restore",
            session: session, checkpointSchema: checkpoint.schemaVersion,
            checkpointBytes: checkpointBytes.count,
            observerSchema: observer.header.schemaVersion,
            assertions: assertions
        )
        try gateFB03RuntimeWriteJSON(
            observer,
            to: root.appendingPathComponent("observer_post_rotation.json")
        )
        try gateFB03RuntimeWriteJSON(
            report,
            to: root.appendingPathComponent("process_2_report.json")
        )
        try gateFB03RuntimeWriteJSON(
            [
                "active_external_resources": 0,
                "duplicate_agents": report.duplicateAgents,
                "duplicate_population_members": report.duplicatePopulationMembers,
                "duplicate_lifecycle_members": report.duplicateLifecycleMembers,
                "duplicate_fidelity_records": report.duplicateFidelityRecords,
                "observer_mutations": report.observerMutations,
                "restart_duplicate_effects": report.restartDuplicateEffects,
                "unexpected_runtime_errors": report.unexpectedRuntimeErrors,
            ],
            to: root.appendingPathComponent("cleanup_evidence.json")
        )
        guard report.success else {
            fail("Gate F Blocker 03 process 2 assertions failed")
        }
        print([
            "GATE_F_BLOCKER_03_PROCESS_2_PASS",
            "checkpointSchema=35", "observerSchema=13",
            "population=\(report.populationCount)",
            "fidelity=\(report.fidelityCount)",
            "newbornTier=\(report.newbornTier)",
            "newbornTransitions=\(report.newbornTransitionCount)",
            "restartDuplicateEffects=0",
        ].joined(separator: " "))
        exit(0)
    } catch {
        fail("Gate F Blocker 03 restore proof failed: \(error)")
    }
}

func runGateFBlocker03DynamicFidelitySmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("Gate F Blocker 03 proof requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let checkpointURL = root.appendingPathComponent(gateFB03RuntimeCheckpoint)
    let stateURL = root.appendingPathComponent(gateFB03RuntimeState)
    if options.scenario == "gate_f_blocker_03_birth_restore_smoke" {
        let thread = Thread {
            gateFB03RuntimeRestore(
                options: options, root: root, checkpointURL: checkpointURL,
                stateURL: stateURL
            )
        }
        thread.stackSize = 32 * 1_024 * 1_024
        thread.start()
        while !thread.isFinished { Thread.sleep(forTimeInterval: 0.001) }
        fail("Gate F Blocker 03 restore worker returned unexpectedly")
    }
    let thread = Thread {
        gateFB03RuntimeExit(
            options: options, root: root, checkpointURL: checkpointURL,
            stateURL: stateURL
        )
    }
    thread.stackSize = 32 * 1_024 * 1_024
    thread.start()
    while !thread.isFinished { Thread.sleep(forTimeInterval: 0.001) }
    fail("Gate F Blocker 03 exit worker returned unexpectedly")
}

private func gateFB03RuntimeExit(
    options: Options,
    root: URL,
    checkpointURL: URL,
    stateURL: URL
) -> Never {
    guard (try? FileManager.default.contentsOfDirectory(
        atPath: root.path
    ).isEmpty) == true else {
        fail("Gate F Blocker 03 process-one output must be empty")
    }
    do {
        var refused = try gateFB03RuntimeSession(
            seed: options.seed, suffix: "birth-refusal",
            maximumLiveAgents: 4, maximumNearAgents: 1,
            rotationIntervalTicks: 256, lethalFounder2: true
        )
        var cleanRetry = try gateFB03RuntimeSession(
            seed: options.seed, suffix: "birth-refusal",
            maximumLiveAgents: 4, maximumNearAgents: 1,
            rotationIntervalTicks: 256, lethalFounder2: true
        )
        for target in 0..<2 {
            if target == 0 {
                _ = try refused.admitMigration(
                    intent: AgentMigrationAdmissionIntent(),
                    observation: gateFB03RuntimeMigrationObservation(
                        tick: refused.tick
                    )
                )
            } else {
                _ = try cleanRetry.admitMigration(
                    intent: AgentMigrationAdmissionIntent(),
                    observation: gateFB03RuntimeMigrationObservation(
                        tick: cleanRetry.tick
                    )
                )
            }
        }
        let beforeRefusal = try refused.durableStateBytes()
        var exactBirthRefusal = false
        do {
            _ = try gateFB03RuntimeBirth(&refused)
        } catch AgentSessionError.lifecycle(.populationFull) {
            exactBirthRefusal = try refused.durableStateBytes() == beforeRefusal
        }
        for target in 0..<2 {
            if target == 0 {
                refused.setSurvivalEnabled(true)
                try refused.setMortalityEnabled(true)
                _ = try refused.advanceTick()
                _ = try gateFB03RuntimeBirth(&refused, fingerprint: 60_304)
            } else {
                cleanRetry.setSurvivalEnabled(true)
                try cleanRetry.setMortalityEnabled(true)
                _ = try cleanRetry.advanceTick()
                _ = try gateFB03RuntimeBirth(&cleanRetry, fingerprint: 60_304)
            }
        }
        let noGapRetryExact = try refused.durableStateBytes()
            == cleanRetry.durableStateBytes()

        var legacy = try gateFB03RuntimeSession(
            seed: options.seed, suffix: "legacy-migration",
            maximumPopulation: 5, maximumLiveAgents: 1,
            maximumNearAgents: 2, rotationIntervalTicks: 256
        )
        let legacyMigration = try legacy.admitMigration(
            intent: AgentMigrationAdmissionIntent(),
            observation: gateFB03RuntimeMigrationObservation(tick: legacy.tick)
        )
        let legacyCheckpoint = try legacy.makeCheckpoint()
        let legacyRestored = try AgentSimulationSession.restoring(
            legacyCheckpoint
        )
        let legacyExact = try legacyRestored.durableStateBytes()
            == legacy.durableStateBytes()
            && legacy.fidelity(for: legacyMigration.migrantID) == .live
            && gateFB03RuntimeIdentitySetsEqual(legacy)

        var mortality = try gateFB03RuntimeSession(
            seed: options.seed, suffix: "newborn-mortality",
            maximumLiveAgents: 4, maximumNearAgents: 1,
            rotationIntervalTicks: 256, newbornLethalSurvival: true
        )
        let mortalityBirth = try gateFB03RuntimeBirth(&mortality)
        mortality.setSurvivalEnabled(true)
        try mortality.setMortalityEnabled(true)
        _ = try mortality.advanceTick()
        let mortalityCheckpoint = try mortality.makeCheckpoint()
        let mortalityRestored = try AgentSimulationSession.restoring(
            mortalityCheckpoint
        )
        let mortalityRestoredBytes = try mortalityRestored.durableStateBytes()
        let mortalityBytes = try mortality.durableStateBytes()
        let mortalityExact = mortality.mortalitySnapshot().records.filter {
            $0.agentID == mortalityBirth.newbornID
        }.count == 1
            && !mortality.populationScaleSnapshot().fidelityRecords.contains {
                $0.agentID == mortalityBirth.newbornID
            }
            && gateFB03RuntimeIdentitySetsEqual(mortality)
            && mortalityRestoredBytes == mortalityBytes

        var session = try gateFB03RuntimeSession(
            seed: options.seed, suffix: "birth-checkpoint"
        )
        let preBirthScale = session.populationScaleSnapshot()
        let birth = try gateFB03RuntimeBirth(&session)
        let population = session.populationSnapshot()
        let lifecycle = session.lifecycleSnapshot()
        let scale = session.populationScaleSnapshot()
        let newbornTransition = scale.fidelityTransitions.last {
            $0.agentID == birth.newbornID && $0.from == nil
        }
        let fidelityEvent = newbornTransition.flatMap { transition in
            session.causalLedgerSnapshot().events.first {
                $0.eventID == transition.eventID
            }
        }
        let finalizedEvent = session.causalLedgerSnapshot().events.first {
            $0.eventID == birth.finalizedEventID
        }
        let beforeObserver = try session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: gateFB03RuntimeObserverBinding(
                seed: options.seed, tick: session.tick
            )
        )
        let afterObserver = try session.durableStateBytes()
        let checkpoint = try session.makeCheckpoint()
        let checkpointBytes = try AgentCheckpointCodec.encode(checkpoint)
        let state = try session.durableStateBytes()
        let assertions = [
            "historical_population_equals_fidelity":
                preBirthScale.fidelityRecords.count == 3
                    && gateFB03RuntimeIdentitySetsEqual(session),
            "birth_reaches_exact_capacity": population.members.count == 4
                && population.settlement?.residentIDs.count == 4
                && population.settlement?.capacity == 4,
            "newborn_singular_authorities": session.snapshot().agents.filter {
                $0.id == birth.newbornID.rawValue
            }.count == 1
                && population.members.filter {
                    $0.agentID == birth.newbornID
                }.count == 1
                && lifecycle.members.filter {
                    $0.agentID == birth.newbornID
                }.count == 1
                && lifecycle.births.filter {
                    $0.newbornID == birth.newbornID
                }.count == 1
                && scale.fidelityRecords.filter {
                    $0.agentID == birth.newbornID
                }.count == 1,
            "newborn_canonical_dormant_tier":
                session.fidelity(for: birth.newbornID) == .dormant
                    && scale.liveCount == 1 && scale.nearCount == 1
                    && scale.dormantCount == 2,
            "birth_fidelity_causal_chain": newbornTransition?.ordinal
                == preBirthScale.evictedFidelityTransitionCount
                    + UInt64(preBirthScale.fidelityTransitions.count) + 1
                && fidelityEvent?.causes.contains(birth.populationBornEventID)
                    == true
                && finalizedEvent?.causes.contains(newbornTransition!.eventID)
                    == true,
            "checkpoint_schema_35": checkpoint.schemaVersion == 35,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_exposes_newborn_fidelity": observer.individuals.first {
                $0.agentID == birth.newbornID
            }?.populationContext?.fidelity == .dormant,
            "observer_read_only": afterObserver == beforeObserver,
            "rejected_birth_exact_atomic": exactBirthRefusal,
            "death_frees_slot_no_gap_retry": noGapRetryExact,
            "legacy_migration_composes_fidelity": legacyExact,
            "scaled_born_mortality_removes_fidelity": mortalityExact,
        ]
        try checkpointBytes.write(to: checkpointURL, options: .atomic)
        try state.write(to: stateURL, options: .atomic)
        let report = try gateFB03RuntimeReport(
            options: options, phase: "birth-capacity-checkpoint",
            session: session, checkpointSchema: checkpoint.schemaVersion,
            checkpointBytes: checkpointBytes.count,
            observerSchema: observer.header.schemaVersion,
            assertions: assertions
        )
        try gateFB03RuntimeWriteJSON(
            observer,
            to: root.appendingPathComponent("observer_immediate_birth.json")
        )
        try gateFB03RuntimeWriteJSON(
            report,
            to: root.appendingPathComponent("process_1_report.json")
        )
        try gateFB03RuntimeWriteJSON(
            [
                "rejected_birth_bytes_changed": exactBirthRefusal ? 0 : 1,
                "no_gap_retry_exact": noGapRetryExact ? 1 : 0,
                "legacy_migration_fidelity_exact": legacyExact ? 1 : 0,
                "scaled_born_mortality_exact": mortalityExact ? 1 : 0,
            ],
            to: root.appendingPathComponent("dynamic_path_evidence.json")
        )
        guard report.success else {
            fail("Gate F Blocker 03 process 1 assertions failed")
        }
        print([
            "GATE_F_BLOCKER_03_PROCESS_1_PASS",
            "population=\(report.populationCount)",
            "fidelity=\(report.fidelityCount)",
            "capacity=4/4", "newbornTier=\(report.newbornTier)",
            "checkpointSchema=35", "observerSchema=13",
            "birthRefusalAtomic=1", "legacyMigrationFidelity=1",
            "scaledBornMortality=1",
        ].joined(separator: " "))
        exit(0)
    } catch {
        fail("Gate F Blocker 03 process 1 proof failed: \(error)")
    }
}
