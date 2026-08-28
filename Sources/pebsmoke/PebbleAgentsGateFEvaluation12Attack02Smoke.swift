import Foundation
import PebbleAgents

private let gateFE12A2Main = AgentSettlementID.main
private let gateFE12A2East = AgentSettlementID(rawValue: "settlement-east")!
private let gateFE12A2MainAnchor = AgentPosition(x: 0, y: 64, z: 0)
private let gateFE12A2MainReception = AgentPosition(x: 0, y: 64, z: 8)
private let gateFE12A2EastReception = AgentPosition(x: 4, y: 64, z: 0)
private let gateFE12A2TerminalParent = AgentID(rawValue: "agent_0")!
private let gateFE12A2Newborn = AgentID(rawValue: "agent_3")!

private let gateFE12A2Habitats: [AgentEcologyHabitatObservation] = (0..<3).map {
    ordinal in
    let forage = AgentPosition(x: 1, y: 64, z: ordinal * 2)
    return AgentEcologyHabitatObservation(
        worldTick: 0, candidateIndex: ordinal,
        habitatPosition: AgentPosition(x: forage.x, y: 63, z: forage.z),
        foragePosition: forage, habitatFingerprint: 122_100 + ordinal,
        distanceFromSettlement: abs(forage.x) + abs(forage.z),
        directionIndex: ordinal, worldReadCount: 4
    )
}

private func gateFE12A2Founder(
    _ ordinal: Int,
    terminalSeed: Bool
) -> AgentSessionAgentState {
    let position = AgentPosition(x: 0, y: 64, z: ordinal * 2)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: terminalSeed && ordinal == 0 ? 0.3 : 0,
            fatigue: 0, curiosity: 0.1, safety: 1
        ),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Evaluation 12 Attack 02",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress()
    )
}

private func gateFE12A2Session(
    _ simulationID: String,
    terminalSeed: Bool
) -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.3, fatiguePerTick: 0.001,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.9,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 1,
        restRecoveryPerTick: 1, starvationGraceTicks: 1,
        starvationDamagePerTick: 100
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 1_222, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival
        ),
        agents: (0..<3).map {
            gateFE12A2Founder($0, terminalSeed: terminalSeed)
        },
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 256)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: gateFE12A2MainAnchor,
        receptionPosition: gateFE12A2MainReception,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 7, maximumMigrationRecords: 16
        )
    )
    try! session.initializeLocalEcology(
        observations: gateFE12A2Habitats,
        configuration: try! AgentLocalEcologyConfiguration(
            maximumPatches: 3, maximumHabitatCandidates: 3,
            observationRadius: 8, patchCapacity: 4, initialYield: 4,
            regenerationIntervalTicks: 2, regenerationQuantity: 4,
            maximumForageIntentsPerTick: 8, maximumForageHistory: 64,
            maximumPressureFrames: 32, maximumHabitatReadsPerScan: 32
        )
    )
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: gateFE12A2Habitats
    )
    try! session.setLifecycleEnabled(
        true,
        configuration: try! AgentLifecycleConfiguration(
            newbornDurationTicks: 1, maturityAgeTicks: 16,
            reproductionEvaluationIntervalTicks: 1,
            reproductionPlanDelayTicks: 1, reproductionCooldownTicks: 2,
            maximumRetainedBirthRecords: 32,
            maximumRetainedPlanRecords: 32,
            maximumParentBirthCount: 8
        )
    )
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFE12A2East,
            anchor: gateFE12A2EastReception,
            receptionPosition: gateFE12A2EastReception,
            capacity: 4, residentIDs: [], inTransitIDs: []
        )],
        configuration: try! AgentPopulationScaleConfiguration(
            maximumSettlements: 2, maximumLiveAgents: 7,
            maximumNearAgents: 3, nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8, rotationIntervalTicks: 4,
            maximumFidelityTransitionHistory: 32,
            maximumSettlementMigrationHistory: 8,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 16
        )
    )
    try! session.setDependentCareEnabled(true)
    try! session.setChildhoodV2Enabled(true)
    try! session.setFamilyV1Enabled(true)
    try! session.setMaterialRightsEnabled(true)
    try! session.setMortalityEnabled(true, configuration: .embodiedLive)
    try! session.setEstatesEnabled(true)
    try! session.setReproductionEnabled(true)
    return session
}

private func gateFE12A2Route(
    from: AgentPosition,
    to: AgentPosition
) -> [AgentPosition] {
    var route = [from]
    var cursor = from
    while cursor.z != to.z {
        cursor = AgentPosition(
            x: cursor.x, y: cursor.y,
            z: cursor.z + (cursor.z < to.z ? 1 : -1)
        )
        route.append(cursor)
    }
    while cursor.x != to.x {
        cursor = AgentPosition(
            x: cursor.x + (cursor.x < to.x ? 1 : -1),
            y: cursor.y, z: cursor.z
        )
        route.append(cursor)
    }
    return route
}

private func gateFE12A2Perception(
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
    return AgentPerceptionInput(
        agentId: migration.agentID.rawValue,
        worldObservation: try! AgentWorldObservation(
            worldTick: session.tick + 1, position: state.position,
            center: column(state.position),
            neighbors: AgentCardinalDirection.allCases.map { direction in
                let target = AgentPosition(
                    x: state.position.x + direction.dx,
                    y: state.position.y,
                    z: state.position.z + direction.dz
                )
                return AgentWorldNeighborObservation(
                    direction: direction, column: column(target), stepDelta: 0,
                    traversable: true, dangerousDrop: false
                )
            },
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

private func gateFE12A2Advance(
    _ session: inout AgentSimulationSession,
    applyEcology: Bool = true
) {
    let migration = session.populationScaleSnapshot().settlementMigrations
        .first { $0.status == .inTransit }
    if let migration {
        _ = try! session.advanceTick(perceptions: [
            gateFE12A2Perception(session: session, migration: migration),
        ])
        if session.populationScaleSnapshot().settlementMigrations.contains(
            where: { $0.status == .inTransit }
        ) {
            let outcomes = AgentMovementCoordinator.resolve(
                snapshot: session.snapshot()
            )
            try! session.applyVerifiedPhysicalMovements(outcomes.map {
                AgentVerifiedPhysicalMovement(
                    kind: .navigationStep, outcome: $0
                )
            })
        }
    } else {
        _ = try! session.advanceTick()
    }
    if applyEcology {
        _ = try! session.applyLocalEcologyEndOfTick(
            habitatValidations: gateFE12A2Habitats
        )
    }
}

private func gateFE12A2Birth(
    _ session: inout AgentSimulationSession,
    fingerprint: Int,
    position: AgentPosition
) -> AgentBirthRecord? {
    let plan = session.pendingBirthSitePlan()!
    return try! session.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID, observedTick: session.tick,
        position: position, candidateIndex: 0,
        worldFingerprint: fingerprint
    ))
}

private func gateFE12A2Feed(
    _ session: inout AgentSimulationSession,
    ordinals: [Int],
    purpose: String
) {
    for ordinal in ordinals {
        let id = AgentID(rawValue: "agent_\(ordinal)")!
        let habitat = gateFE12A2Habitats[ordinal]
        let outcomes = try! session.applyForageIntents([
            AgentForageIntent(
                forageID: "e12-a2-\(purpose)-agent_\(ordinal)-t\(session.tick)",
                patchID: habitat.patchID, agentID: id, tick: session.tick,
                target: habitat.foragePosition, observedAtTick: session.tick,
                expectedHabitatFingerprint: habitat.habitatFingerprint
            ),
        ], habitatValidations: gateFE12A2Habitats)
        precondition(outcomes.first?.status == .succeeded)
        let consumed = try! session.consumeFood(AgentConsumptionIntent(
            consumptionId: "e12-a2-\(purpose)-consume-agent_\(ordinal)-t\(session.tick)",
            agentId: id.rawValue, tick: session.tick,
            resource: .foodRaw, quantity: 1
        ))
        precondition(consumed.status == .succeeded)
    }
}

private func gateFE12A2ResolveEmptyCustody(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) {
    _ = try! session.applyMortalityPhysicalCustodyOutcome(
        AgentMortalityPhysicalCustodyOutcome(
            operationID: "e12-a2-empty-\(agentID.rawValue)-t\(session.tick)",
            terminalAgentID: agentID, kind: .verifiedEmpty,
            physicalReceiptID: "e12-a2-empty-receipt-\(agentID.rawValue)-t\(session.tick)",
            destinationHolderID: nil, stackCount: 0, itemCount: 0,
            physicalAssets: [], verifiedAtTick: session.tick
        )
    )
}

private struct GateFE12A2ControlEvidence: Codable, Equatable {
    let birthEvent: UInt64
    let guardianID: String
    let migrationOrdinalBefore: UInt64
    let migrationOrdinalAfter: UInt64
    let durableByteAtomic: Bool
    let refused: Bool
}

private struct GateFE12A2CausalEvidence: Codable, Equatable {
    let migrationStart: UInt64
    let refusedPlanCreated: UInt64
    let refusedPlanTerminal: UInt64
    let mortalityPending: UInt64
    let acceptedPlanCreated: UInt64
    let birthBorn: UInt64
    let parentageRecorded: UInt64
    let guardianStarted: UInt64
    let migrationFailure: UInt64?
    let deathFinal: UInt64?
}

private struct GateFE12A2IdentityEvidence: Codable, Equatable {
    let nextPopulationOrdinal: Int
    let nextFidelityOrdinal: UInt64
    let nextMigrationOrdinal: UInt64
    let nextHouseholdOrdinal: Int
    let membershipPeriodCount: Int
    let birthCount: Int
    let deathCount: Int
    let estateCount: Int
}

private struct GateFE12A2Report: Codable, Equatable {
    let phase: String
    let tick: Int
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let control: GateFE12A2ControlEvidence
    let causal: GateFE12A2CausalEvidence
    let identities: GateFE12A2IdentityEvidence
    let activeMigrationCount: Int
    let failedMigrationCount: Int
    let pendingMortalityCount: Int
    let currentHouseholdCountForTerminalParent: Int
    let newbornResidentCount: Int
    let newbornFidelityCount: Int
    let newbornHouseholdCount: Int
    let newbornGuardianCount: Int
    let replayedBirths: Int
    let replayedDeaths: Int
    let replayedEstates: Int
    let observerMutationCount: Int
    let assertions: [String: Bool]
}

private struct GateFE12A2Fixture {
    var session: AgentSimulationSession
    let control: GateFE12A2ControlEvidence
    let causal: GateFE12A2CausalEvidence
}

private func gateFE12A2Control(
    _ simulationID: String
) -> GateFE12A2ControlEvidence {
    var session = gateFE12A2Session(simulationID, terminalSeed: false)
    gateFE12A2Advance(&session)
    gateFE12A2Advance(&session)
    let birth = gateFE12A2Birth(
        &session, fingerprint: 122_201,
        position: AgentPosition(x: 1, y: 64, z: 1)
    )!
    let guardian = try! session.currentGuardian(for: birth.newbornID)!
    let beforeOrdinal = session.durableState().populationRegistry!.scaleState!
        .nextSettlementMigrationOrdinal
    let beforeBytes = try! session.durableStateBytes()
    let guardianState = try! session.state(for: guardian.guardianID)
    var refused = false
    do {
        _ = try session.beginSettlementMigration(
            agentID: guardian.guardianID,
            destinationSettlementID: gateFE12A2East,
            verifiedRoute: gateFE12A2Route(
                from: guardianState.position, to: gateFE12A2EastReception
            )
        )
    } catch {
        refused = true
    }
    return GateFE12A2ControlEvidence(
        birthEvent: birth.populationBornEventID.sequence.rawValue,
        guardianID: guardian.guardianID.rawValue,
        migrationOrdinalBefore: beforeOrdinal,
        migrationOrdinalAfter: session.durableState().populationRegistry!
            .scaleState!.nextSettlementMigrationOrdinal,
        durableByteAtomic: (try! session.durableStateBytes()) == beforeBytes,
        refused: refused
    )
}

private func gateFE12A2Fixture(
    _ simulationID: String
) -> GateFE12A2Fixture {
    let control = gateFE12A2Control("\(simulationID)-control")
    var session = gateFE12A2Session(simulationID, terminalSeed: true)
    gateFE12A2Advance(&session)
    let refusedPlan = session.lifecycleSnapshot().plans.first {
        $0.status == .planned
    }!
    let terminalState = try! session.state(for: gateFE12A2TerminalParent)
    let migration = try! session.beginSettlementMigration(
        agentID: gateFE12A2TerminalParent,
        destinationSettlementID: gateFE12A2East,
        verifiedRoute: gateFE12A2Route(
            from: terminalState.position, to: gateFE12A2EastReception
        )
    )
    gateFE12A2Advance(&session)
    let populationBeforeRefusal = session.populationSnapshot()
        .nextPopulationOrdinal!
    let fidelityBeforeRefusal = session.durableState().populationRegistry!
        .scaleState!.nextFidelityTransitionOrdinal
    let refusedBirth = gateFE12A2Birth(
        &session, fingerprint: 122_202,
        position: AgentPosition(x: 1, y: 64, z: 1)
    )
    precondition(refusedBirth == nil)
    precondition(
        session.populationSnapshot().nextPopulationOrdinal
            == populationBeforeRefusal
            && session.durableState().populationRegistry!.scaleState!
                .nextFidelityTransitionOrdinal == fidelityBeforeRefusal
    )
    let refusedPlanAfter = session.lifecycleSnapshot().plans.first {
        $0.planID == refusedPlan.planID
    }!
    precondition(
        refusedPlanAfter.reason == .parentMigrating
            && refusedPlanAfter.terminalEventID != nil
    )
    gateFE12A2Feed(&session, ordinals: [1, 2], purpose: "mid")
    gateFE12A2Advance(&session)
    let acceptedPlan = session.lifecycleSnapshot().plans.first {
        $0.status == .planned
    }!
    gateFE12A2Advance(&session, applyEcology: false)
    let pending = session.pendingMortalityTransitions().first {
        $0.agentID == gateFE12A2TerminalParent
    }!
    let birthResult = gateFE12A2Birth(
        &session, fingerprint: 122_203,
        position: AgentPosition(x: 1, y: 64, z: 3)
    )
    precondition(
        birthResult != nil,
        "Attack 02 unrelated birth refused plan=\(acceptedPlan)"
    )
    let birth = birthResult!
    precondition(birth.newbornID == gateFE12A2Newborn)
    gateFE12A2Feed(&session, ordinals: [1, 2], purpose: "writer")
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: gateFE12A2Habitats
    )
    let parentage = session.kinshipSnapshot().parentageRecords.first {
        $0.childID == gateFE12A2Newborn
    }!
    let guardian = try! session.currentGuardian(for: gateFE12A2Newborn)!
    return GateFE12A2Fixture(
        session: session, control: control,
        causal: GateFE12A2CausalEvidence(
            migrationStart: migration.startedEventID.sequence.rawValue,
            refusedPlanCreated: refusedPlan.createdEventID.sequence.rawValue,
            refusedPlanTerminal:
                refusedPlanAfter.terminalEventID!.sequence.rawValue,
            mortalityPending: pending.pendingEventID.sequence.rawValue,
            acceptedPlanCreated: acceptedPlan.createdEventID.sequence.rawValue,
            birthBorn: birth.populationBornEventID.sequence.rawValue,
            parentageRecorded: parentage.recordedEventID.sequence.rawValue,
            guardianStarted: guardian.startedEventID.sequence.rawValue,
            migrationFailure: nil, deathFinal: nil
        )
    )
}

private func gateFE12A2DeadAuthorityAbsent(
    _ session: AgentSimulationSession
) -> Bool {
    let durable = session.durableState()
    let registry = durable.populationRegistry!
    let scale = registry.scaleState!
    return !durable.agents.contains {
        $0.agentID == gateFE12A2TerminalParent
    } && !registry.members.contains {
        $0.agentID == gateFE12A2TerminalParent
    } && !registry.settlements.contains {
        $0.residentIDs.contains(gateFE12A2TerminalParent)
            || $0.inTransitIDs.contains(gateFE12A2TerminalParent)
    } && !scale.fidelityRecords.contains {
        $0.agentID == gateFE12A2TerminalParent
    } && !(durable.householdState?.membershipPeriods.contains {
        $0.agentID == gateFE12A2TerminalParent && $0.leftTick == nil
    } ?? false)
}

private func gateFE12A2Report(
    phase: String,
    session: inout AgentSimulationSession,
    control: GateFE12A2ControlEvidence,
    causal: GateFE12A2CausalEvidence,
    finalized: Bool,
    replayedBirths: Int = 0,
    replayedDeaths: Int = 0,
    replayedEstates: Int = 0,
    observerSchema: Int = 13,
    observerMutationCount: Int = 0
) -> GateFE12A2Report {
    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let durableBytes = try! session.durableStateBytes()
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    let migrations = scale.settlementMigrations
    let newbornResidentCount = population.settlements.filter {
        $0.residentIDs.contains(gateFE12A2Newborn)
    }.count
    let newbornFidelityCount = scale.fidelityRecords.filter {
        $0.agentID == gateFE12A2Newborn
    }.count
    let newbornHouseholdCount = household.membershipPeriods.filter {
        $0.agentID == gateFE12A2Newborn && $0.leftTick == nil
    }.count
    let newbornGuardianCount = durable.dependentCareState?.childhoodV2?
        .guardianships.filter {
            $0.dependentID == gateFE12A2Newborn && $0.status == .active
        }.count ?? 0
    let terminalHouseholds = household.membershipPeriods.filter {
        $0.agentID == gateFE12A2TerminalParent && $0.leftTick == nil
    }.count
    let identities = GateFE12A2IdentityEvidence(
        nextPopulationOrdinal: population.nextPopulationOrdinal.rawValue,
        nextFidelityOrdinal: scale.nextFidelityTransitionOrdinal,
        nextMigrationOrdinal: scale.nextSettlementMigrationOrdinal,
        nextHouseholdOrdinal: household.nextHouseholdOrdinal.rawValue,
        membershipPeriodCount: household.membershipPeriods.count,
        birthCount: session.lifecycleSnapshot().totalBirthCount,
        deathCount: session.mortalitySnapshot().totalDeathCount,
        estateCount: session.estateSnapshot().totalEstateCount
    )
    let newbornIDs = session.lifecycleSnapshot().births.map(\.newbornID)
    var assertions: [String: Bool] = [
        "checkpoint_schema_35": checkpoint.schemaVersion == 35,
        "control_birth_before_migration_refuses_atomically": control.refused
            && control.durableByteAtomic
            && control.migrationOrdinalBefore == control.migrationOrdinalAfter,
        "migration_before_birth_refuses_without_identity":
            causal.migrationStart < causal.refusedPlanTerminal
                && identities.nextPopulationOrdinal == 4,
        "terminal_pending_precedes_unrelated_birth":
            causal.mortalityPending < causal.birthBorn
                && causal.birthBorn < causal.parentageRecorded
                && causal.parentageRecorded < causal.guardianStarted,
        "newborn_identity_exactly_once": newbornIDs == [gateFE12A2Newborn]
            && Set(newbornIDs).count == newbornIDs.count,
        "newborn_current_authority_coherent": newbornResidentCount == 1
            && newbornFidelityCount == 1 && newbornHouseholdCount == 1
            && newbornGuardianCount == 1,
        "ordinals_monotonic": identities.nextPopulationOrdinal == 4
            && identities.nextFidelityOrdinal == 5
            && identities.nextMigrationOrdinal == 2,
        "migration_history_exact": migrations.count == 1,
        "observer_read_only": observerMutationCount == 0,
        "zero_replay": replayedBirths == 0 && replayedDeaths == 0
            && replayedEstates == 0,
    ]
    if finalized {
        assertions["terminal_cleanup_exact"] = identities.deathCount == 1
            && identities.estateCount == 1
            && migrations.first?.status == .failed
            && migrations.first?.failure == .memberDied
            && gateFE12A2DeadAuthorityAbsent(session)
            && terminalHouseholds == 0
    } else {
        assertions["pending_composition_exact"] = identities.deathCount == 0
            && identities.estateCount == 0
            && session.pendingMortalityTransitions().count == 1
            && migrations.first?.status == .inTransit
            && terminalHouseholds == 1
    }
    return GateFE12A2Report(
        phase: phase, tick: session.tick,
        checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observerSchema,
        checkpointSHA256: AgentCheckpointDigest.sha256(checkpointBytes).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        control: control, causal: causal, identities: identities,
        activeMigrationCount: migrations.filter { $0.status == .inTransit }.count,
        failedMigrationCount: migrations.filter { $0.status == .failed }.count,
        pendingMortalityCount: session.pendingMortalityTransitions().count,
        currentHouseholdCountForTerminalParent: terminalHouseholds,
        newbornResidentCount: newbornResidentCount,
        newbornFidelityCount: newbornFidelityCount,
        newbornHouseholdCount: newbornHouseholdCount,
        newbornGuardianCount: newbornGuardianCount,
        replayedBirths: replayedBirths, replayedDeaths: replayedDeaths,
        replayedEstates: replayedEstates,
        observerMutationCount: observerMutationCount,
        assertions: assertions
    )
}

private func gateFE12A2Write<T: Encodable>(_ value: T, to url: URL) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try! encoder.encode(value).write(to: url, options: .atomic)
}

private func gateFE12A2FreshIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment["PEBBLELAB_GATE_F_E12_A2_PHASE"] else {
        return false
    }
    guard ["write-pending", "restore-finalize", "restore-verify"].contains(phase),
          let output = environment["PEBBLELAB_GATE_F_E12_A2_OUT"] else {
        preconditionFailure("invalid Evaluation 12 Attack 02 environment")
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let pendingCheckpoint = root.appendingPathComponent("pending_checkpoint_v35.json")
    let pendingDurable = root.appendingPathComponent("pending_durable_state.json")
    let finalCheckpoint = root.appendingPathComponent("final_checkpoint_v35.json")
    let finalDurable = root.appendingPathComponent("final_durable_state.json")
    let writerReport = root.appendingPathComponent("process_1_report.json")
    let readerReport = root.appendingPathComponent("process_2_report.json")

    if phase == "write-pending" {
        var fixture = gateFE12A2Fixture("gate-f-e12-a2-fresh")
        let report = gateFE12A2Report(
            phase: phase, session: &fixture.session,
            control: fixture.control, causal: fixture.causal, finalized: false
        )
        let checkpointBytes = try! AgentCheckpointCodec.encode(
            fixture.session.makeCheckpoint()
        )
        let durableBytes = try! fixture.session.durableStateBytes()
        try! checkpointBytes.write(to: pendingCheckpoint, options: .atomic)
        try! durableBytes.write(to: pendingDurable, options: .atomic)
        gateFE12A2Write(report, to: writerReport)
        check("Attack 02 writer composes pending mortality with unrelated birth",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "restore-finalize" {
        let checkpointBytes = try! Data(contentsOf: pendingCheckpoint)
        let durableBytes = try! Data(contentsOf: pendingDurable)
        let previous = try! JSONDecoder().decode(
            GateFE12A2Report.self, from: Data(contentsOf: writerReport)
        )
        let checkpoint = try! AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        var session = try! AgentSimulationSession.restoring(checkpoint)
        let restoredDurable = try! session.durableStateBytes()
        let birthsBefore = session.lifecycleSnapshot().totalBirthCount
        let deathsBefore = session.mortalitySnapshot().totalDeathCount
        let estatesBefore = session.estateSnapshot().totalEstateCount
        let observerBefore = try! session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: try! AgentObserverWorldBinding(
                worldID: "gate-f-e12-a2-world",
                storageIdentity: "memory:gate-f-e12-a2", seed: 1_222,
                dimension: 0, observedWorldTick: session.tick
            )
        )
        let observerMutations = (try! session.durableStateBytes())
            == observerBefore ? 0 : 1
        gateFE12A2ResolveEmptyCustody(
            &session, agentID: gateFE12A2TerminalParent
        )
        let death = try! session.finalizePendingMortality(
            for: gateFE12A2TerminalParent
        )
        let migration = session.populationScaleSnapshot().settlementMigrations.first!
        let causal = GateFE12A2CausalEvidence(
            migrationStart: previous.causal.migrationStart,
            refusedPlanCreated: previous.causal.refusedPlanCreated,
            refusedPlanTerminal: previous.causal.refusedPlanTerminal,
            mortalityPending: previous.causal.mortalityPending,
            acceptedPlanCreated: previous.causal.acceptedPlanCreated,
            birthBorn: previous.causal.birthBorn,
            parentageRecorded: previous.causal.parentageRecorded,
            guardianStarted: previous.causal.guardianStarted,
            migrationFailure: migration.failureEventID?.sequence.rawValue,
            deathFinal: death.deathEventID.sequence.rawValue
        )
        var report = gateFE12A2Report(
            phase: phase, session: &session, control: previous.control,
            causal: causal, finalized: true,
            replayedBirths: session.lifecycleSnapshot().totalBirthCount - birthsBefore,
            replayedDeaths: session.mortalitySnapshot().totalDeathCount - deathsBefore - 1,
            replayedEstates: session.estateSnapshot().totalEstateCount - estatesBefore - 1,
            observerSchema: observer.header.schemaVersion,
            observerMutationCount: observerMutations
        )
        var assertions = report.assertions
        assertions["pending_checkpoint_reencodes_exactly"] =
            (try? AgentCheckpointCodec.encode(checkpoint)) == checkpointBytes
        assertions["pending_durable_restores_exactly"] = restoredDurable == durableBytes
        assertions["observer_schema_13"] = observer.header.schemaVersion == 13
        assertions["migration_failure_after_birth"] =
            causal.birthBorn < (causal.migrationFailure ?? 0)
                && (causal.migrationFailure ?? UInt64.max)
                    < (causal.deathFinal ?? 0)
        report = GateFE12A2Report(
            phase: report.phase, tick: report.tick,
            checkpointSchema: report.checkpointSchema,
            observerSchema: report.observerSchema,
            checkpointSHA256: report.checkpointSHA256,
            durableSHA256: report.durableSHA256, control: report.control,
            causal: report.causal, identities: report.identities,
            activeMigrationCount: report.activeMigrationCount,
            failedMigrationCount: report.failedMigrationCount,
            pendingMortalityCount: report.pendingMortalityCount,
            currentHouseholdCountForTerminalParent:
                report.currentHouseholdCountForTerminalParent,
            newbornResidentCount: report.newbornResidentCount,
            newbornFidelityCount: report.newbornFidelityCount,
            newbornHouseholdCount: report.newbornHouseholdCount,
            newbornGuardianCount: report.newbornGuardianCount,
            replayedBirths: report.replayedBirths,
            replayedDeaths: report.replayedDeaths,
            replayedEstates: report.replayedEstates,
            observerMutationCount: report.observerMutationCount,
            assertions: assertions
        )
        let finalCheckpointBytes = try! AgentCheckpointCodec.encode(
            session.makeCheckpoint()
        )
        let finalDurableBytes = try! session.durableStateBytes()
        try! finalCheckpointBytes.write(to: finalCheckpoint, options: .atomic)
        try! finalDurableBytes.write(to: finalDurable, options: .atomic)
        gateFE12A2Write(report, to: readerReport)
        check("Attack 02 fresh restore finalizes terminal parent exactly once",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    let checkpointBytes = try! Data(contentsOf: finalCheckpoint)
    let durableBytes = try! Data(contentsOf: finalDurable)
    let previous = try! JSONDecoder().decode(
        GateFE12A2Report.self, from: Data(contentsOf: readerReport)
    )
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    var session = try! AgentSimulationSession.restoring(checkpoint)
    let restoredDurable = try! session.durableStateBytes()
    let birthsBefore = session.lifecycleSnapshot().totalBirthCount
    let deathsBefore = session.mortalitySnapshot().totalDeathCount
    let estatesBefore = session.estateSnapshot().totalEstateCount
    gateFE12A2Advance(&session)
    var report = gateFE12A2Report(
        phase: phase, session: &session, control: previous.control,
        causal: previous.causal, finalized: true,
        replayedBirths: session.lifecycleSnapshot().totalBirthCount - birthsBefore,
        replayedDeaths: session.mortalitySnapshot().totalDeathCount - deathsBefore,
        replayedEstates: session.estateSnapshot().totalEstateCount - estatesBefore
    )
    var assertions = report.assertions
    assertions["final_checkpoint_reencodes_exactly"] =
        (try? AgentCheckpointCodec.encode(checkpoint)) == checkpointBytes
    assertions["final_durable_restores_exactly"] = restoredDurable == durableBytes
    report = GateFE12A2Report(
        phase: report.phase, tick: report.tick,
        checkpointSchema: report.checkpointSchema,
        observerSchema: report.observerSchema,
        checkpointSHA256: report.checkpointSHA256,
        durableSHA256: report.durableSHA256, control: report.control,
        causal: report.causal, identities: report.identities,
        activeMigrationCount: report.activeMigrationCount,
        failedMigrationCount: report.failedMigrationCount,
        pendingMortalityCount: report.pendingMortalityCount,
        currentHouseholdCountForTerminalParent:
            report.currentHouseholdCountForTerminalParent,
        newbornResidentCount: report.newbornResidentCount,
        newbornFidelityCount: report.newbornFidelityCount,
        newbornHouseholdCount: report.newbornHouseholdCount,
        newbornGuardianCount: report.newbornGuardianCount,
        replayedBirths: report.replayedBirths,
        replayedDeaths: report.replayedDeaths,
        replayedEstates: report.replayedEstates,
        observerMutationCount: report.observerMutationCount,
        assertions: assertions
    )
    gateFE12A2Write(
        report, to: root.appendingPathComponent("process_3_report.json")
    )
    check("Attack 02 second restore continues without replay or identity reuse",
          report.assertions.values.allSatisfy { $0 })
    return true
}

func runPebbleAgentsGateFEvaluation12Attack02Smoke() {
    if gateFE12A2FreshIfRequested() { return }
    var fixture = gateFE12A2Fixture("gate-f-e12-a2-focused")
    let report = gateFE12A2Report(
        phase: "focused", session: &fixture.session,
        control: fixture.control, causal: fixture.causal, finalized: false
    )
    section("Gate F Evaluation 12 Attack 02 — birth death migration scale")
    for key in report.assertions.keys.sorted() {
        check("Attack 02 \(key)", report.assertions[key]!)
    }
    print(
        "GATE_F_E12_ATTACK_02_CAUSAL migration=\(report.causal.migrationStart) "
            + "refusal=\(report.causal.refusedPlanTerminal) "
            + "pending=\(report.causal.mortalityPending) "
            + "birth=\(report.causal.birthBorn) "
            + "parentage=\(report.causal.parentageRecorded) "
            + "guardian=\(report.causal.guardianStarted)"
    )
    print(
        "GATE_F_E12_ATTACK_02_AUTHORITY tick=\(report.tick) "
            + "activeMigration=\(report.activeMigrationCount) "
            + "pending=\(report.pendingMortalityCount) "
            + "terminalHousehold=\(report.currentHouseholdCountForTerminalParent) "
            + "newborn=resident\(report.newbornResidentCount)/fidelity"
            + "\(report.newbornFidelityCount)/household"
            + "\(report.newbornHouseholdCount)/guardian"
            + "\(report.newbornGuardianCount)"
    )
    print(
        "GATE_F_E12_ATTACK_02_IDENTITY population="
            + "\(report.identities.nextPopulationOrdinal) fidelity="
            + "\(report.identities.nextFidelityOrdinal) migration="
            + "\(report.identities.nextMigrationOrdinal) household="
            + "\(report.identities.nextHouseholdOrdinal) periods="
            + "\(report.identities.membershipPeriodCount)"
    )
    print(
        "GATE_F_E12_ATTACK_02_DIGEST checkpoint=\(report.checkpointSHA256) "
            + "durable=\(report.durableSHA256) schema="
            + "\(report.checkpointSchema) observer=\(report.observerSchema)"
    )
}
