import Foundation
import PebbleAgents

private let gateFB10Origin = AgentPosition(x: 0, y: 64, z: 0)
private let gateFB10East = AgentPosition(x: 16, y: 64, z: 0)
private let gateFB10EastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFB10MigrantID = AgentID(rawValue: "agent_2")!

private func gateFB10Agent(
    _ ordinal: Int,
    terminal: Bool
) -> AgentSessionAgentState {
    let position = ordinal == 2
        ? AgentPosition(x: 4, y: 64, z: 0) : gateFB10Origin
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: terminal ? 0.80 : 0, fatigue: 0,
            curiosity: 0.1, safety: 1
        ),
        health: terminal ? 1 : 100, fear: 0, homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 10 public fixture",
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

private func gateFB10Habitat(_ ordinal: Int) -> AgentEcologyHabitatObservation {
    AgentEcologyHabitatObservation(
        worldTick: 0, candidateIndex: ordinal,
        habitatPosition: AgentPosition(x: ordinal * 2 + 1, y: 63, z: 0),
        foragePosition: AgentPosition(x: ordinal * 2 + 1, y: 64, z: 0),
        habitatFingerprint: 110_010 + ordinal,
        distanceFromSettlement: ordinal * 2 + 1,
        directionIndex: ordinal, worldReadCount: 4
    )
}

private func gateFB10Session(
    _ simulationID: String,
    terminalAgentOrdinal: Int? = 2,
    embodiedMortality: Bool = true
) -> AgentSimulationSession {
    let habitats = (0..<3).map(gateFB10Habitat)
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 10_010, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: try! AgentSurvivalConfiguration(
                hungerPerTick: 0.05, fatiguePerTick: 0.001,
                hungryThreshold: 0.4, criticalHungerThreshold: 0.99,
                hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
                fatigueRecoveryThreshold: 0.2, foodNutrition: 1,
                restRecoveryPerTick: 1, starvationGraceTicks: 0,
                starvationDamagePerTick: 1
            )
        ),
        agents: (0..<3).map {
            gateFB10Agent($0, terminal: terminalAgentOrdinal == $0)
        },
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: gateFB10Origin,
        receptionPosition: gateFB10Origin,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 5, maximumMigrationRecords: 16
        )
    )
    try! session.initializeLocalEcology(
        observations: habitats,
        configuration: try! AgentLocalEcologyConfiguration(
            maximumPatches: 3, maximumHabitatCandidates: 8,
            observationRadius: 8, patchCapacity: 4, initialYield: 4,
            regenerationIntervalTicks: 8, regenerationQuantity: 1,
            maximumForageIntentsPerTick: 8, maximumForageHistory: 64,
            maximumPressureFrames: 32, maximumHabitatReadsPerScan: 64
        )
    )
    _ = try! session.applyLocalEcologyEndOfTick(habitatValidations: habitats)
    try! session.setLifecycleEnabled(
        true,
        configuration: try! AgentLifecycleConfiguration(
            newbornDurationTicks: 8, maturityAgeTicks: 64,
            reproductionEvaluationIntervalTicks: 1,
            reproductionPlanDelayTicks: 1,
            reproductionCooldownTicks: 1,
            maximumRetainedBirthRecords: 32,
            maximumRetainedPlanRecords: 32,
            maximumParentBirthCount: 16
        )
    )
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB10EastID,
            anchor: gateFB10East, receptionPosition: gateFB10East,
            capacity: 1, residentIDs: [], inTransitIDs: []
        )],
        configuration: try! AgentPopulationScaleConfiguration(
            maximumSettlements: 2, maximumLiveAgents: 5,
            maximumNearAgents: 2, nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8, rotationIntervalTicks: 4,
            maximumFidelityTransitionHistory: 32,
            maximumSettlementMigrationHistory: 8,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 32
        )
    )
    try! session.setDependentCareEnabled(true)
    try! session.setChildhoodV2Enabled(true)
    try! session.setFamilyV1Enabled(true)
    try! session.setMaterialRightsEnabled(true)
    try! session.setMortalityEnabled(
        true, configuration: embodiedMortality ? .embodiedLive : .live
    )
    if embodiedMortality {
        try! session.setEstatesEnabled(true)
    }
    try! session.setReproductionEnabled(true)
    return session
}

private func gateFB10Birth(
    _ session: inout AgentSimulationSession,
    fingerprint: Int
) -> AgentBirthRecord {
    for _ in 0..<8 where session.pendingBirthSitePlan() == nil {
        _ = try! session.advanceTick()
    }
    let plan = session.pendingBirthSitePlan()!
    for _ in 0..<8 where session.tick < plan.dueTick {
        _ = try! session.advanceTick()
    }
    return try! session.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID, observedTick: session.tick,
        position: AgentPosition(x: 1, y: 64, z: 1),
        candidateIndex: 0, worldFingerprint: fingerprint
    ))!
}

private func gateFB10Route(from start: AgentPosition) -> [AgentPosition] {
    if start.x <= gateFB10East.x {
        return (start.x...gateFB10East.x).map {
            AgentPosition(x: $0, y: 64, z: 0)
        }
    }
    return stride(from: start.x, through: gateFB10East.x, by: -1).map {
        AgentPosition(x: $0, y: 64, z: 0)
    }
}

private func gateFB10StagePending(
    _ simulationID: String,
    fingerprint: Int
) -> (session: AgentSimulationSession, childID: AgentID) {
    var session = gateFB10Session(simulationID)
    let birth = gateFB10Birth(&session, fingerprint: fingerprint)
    for _ in 0..<8 where !session.pendingMortalityTransitions().contains(
        where: { $0.agentID == gateFB10MigrantID }
    ) {
        _ = try! session.advanceTick()
    }
    precondition(session.pendingMortalityTransitions().contains {
        $0.agentID == gateFB10MigrantID
    })
    return (session, birth.newbornID)
}

private func gateFB10ResolveEmptyCustody(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) {
    _ = try! session.applyMortalityPhysicalCustodyOutcome(
        AgentMortalityPhysicalCustodyOutcome(
            operationID: "gate-f-b10-empty-\(agentID.rawValue)-t\(session.tick)",
            terminalAgentID: agentID, kind: .verifiedEmpty,
            physicalReceiptID:
                "gate-f-b10-empty-receipt-\(agentID.rawValue)-t\(session.tick)",
            destinationHolderID: nil, stackCount: 0, itemCount: 0,
            physicalAssets: [], verifiedAtTick: session.tick
        )
    )
}

private struct GateFB10Ordinals: Codable, Equatable {
    let population: Int
    let fidelity: UInt64
    let migration: UInt64
    let household: Int
    let union: Int
    let lineage: Int
    let house: Int
    let deaths: Int
    let estates: Int
    let careAssignments: Int
    let guardianships: Int
}

private func gateFB10Ordinals(
    _ session: AgentSimulationSession
) -> GateFB10Ordinals {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    return GateFB10Ordinals(
        population: population.nextPopulationOrdinal.rawValue,
        fidelity: scale.nextFidelityTransitionOrdinal,
        migration: scale.nextSettlementMigrationOrdinal,
        household: durable.householdState!.nextHouseholdOrdinal.rawValue,
        union: durable.familyState!.nextUnionOrdinal,
        lineage: durable.familyState!.nextLineageOrdinal,
        house: durable.familyState!.nextHouseOrdinal,
        deaths: durable.mortalityState!.totalDeathCount,
        estates: durable.estateState!.totalEstateCount,
        careAssignments: durable.dependentCareState!.assignments.count,
        guardianships:
            durable.dependentCareState!.childhoodV2!.guardianships.count
    )
}

private struct GateFB10Authority: Codable, Equatable {
    let stage: String
    let tick: Int
    let health: Int?
    let activeAgent: Bool
    let populationMember: Bool
    let membershipStatus: String?
    let memberSettlement: String?
    let originResident: Bool
    let originInTransit: Bool
    let destinationResident: Bool
    let destinationInTransit: Bool
    let activeMigrationCount: Int
    let fidelityOwnerCount: Int
    let currentHousehold: String?
    let familyRelationCount: Int
    let careAsDependent: Int
    let careAsCaregiver: Int
    let guardianshipAsDependent: Int
    let guardianshipAsGuardian: Int
    let mortalityPending: Bool
    let mortalityPendingSequence: UInt64?
    let deathID: String?
    let estateCount: Int
}

private func gateFB10Authority(
    _ session: AgentSimulationSession,
    agentID: AgentID = gateFB10MigrantID,
    stage: String
) -> GateFB10Authority {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let member = population.members.first { $0.agentID == agentID }
    let origin = population.settlements.first { $0.settlementID == .main }!
    let destination = population.settlements.first {
        $0.settlementID == gateFB10EastID
    }!
    let pending = durable.mortalityState!.pendingTransitions.first {
        $0.agentID == agentID
    }
    let death = durable.mortalityState!.records.first {
        $0.agentID == agentID
    }
    let membership = durable.householdState!.membershipPeriods.first {
        $0.agentID == agentID && $0.leftTick == nil
    }
    let care = durable.dependentCareState!
    return GateFB10Authority(
        stage: stage, tick: session.tick,
        health: try? session.state(for: agentID).health,
        activeAgent: durable.agents.contains { $0.agentID == agentID },
        populationMember: member != nil,
        membershipStatus: member?.status.rawValue,
        memberSettlement: member?.settlementID.rawValue,
        originResident: origin.residentIDs.contains(agentID),
        originInTransit: origin.inTransitIDs.contains(agentID),
        destinationResident: destination.residentIDs.contains(agentID),
        destinationInTransit: destination.inTransitIDs.contains(agentID),
        activeMigrationCount: scale.settlementMigrations.filter {
            $0.agentID == agentID && $0.status == .inTransit
        }.count,
        fidelityOwnerCount: scale.fidelityRecords.filter {
            $0.agentID == agentID
        }.count,
        currentHousehold: membership?.householdID.rawValue,
        familyRelationCount: (try? session.familyRelations(of: agentID).count) ?? 0,
        careAsDependent: care.assignments.filter {
            $0.status == .active && $0.dependentID == agentID
        }.count,
        careAsCaregiver: care.assignments.filter {
            $0.status == .active && $0.caregiverID == agentID
        }.count,
        guardianshipAsDependent: care.childhoodV2!.guardianships.filter {
            $0.status == .active && $0.dependentID == agentID
        }.count,
        guardianshipAsGuardian: care.childhoodV2!.guardianships.filter {
            $0.status == .active && $0.guardianID == agentID
        }.count,
        mortalityPending: pending != nil,
        mortalityPendingSequence: pending?.pendingEventID.sequence.rawValue,
        deathID: death?.deathID.rawValue,
        estateCount: durable.estateState!.estates.filter {
            $0.decedentID == agentID
        }.count
    )
}

private func gateFB10CurrentAuthorityIsSingular(
    _ session: AgentSimulationSession
) -> Bool {
    let durable = session.durableState()
    guard let population = durable.populationRegistry,
          let scale = population.scaleState else { return false }
    let current = population.settlements.flatMap {
        $0.residentIDs + $0.inTransitIDs
    }
    guard current.count == Set(current).count,
          scale.fidelityRecords.count
            == Set(scale.fidelityRecords.map(\.agentID)).count else {
        return false
    }
    let activeIDs = Set(durable.agents.map(\.agentID))
    return Set(current) == activeIDs
        && Set(scale.fidelityRecords.map(\.agentID)) == activeIDs
        && scale.settlementMigrations.filter { $0.status == .inTransit }
            .allSatisfy { activeIDs.contains($0.agentID) }
}

private func gateFB10AttemptMigration(
    _ session: inout AgentSimulationSession,
    agentID: AgentID = gateFB10MigrantID
) -> Bool {
    let start = (try? session.state(for: agentID).position)
        ?? AgentPosition(x: 4, y: 64, z: 0)
    do {
        _ = try session.beginSettlementMigration(
            agentID: agentID, destinationSettlementID: gateFB10EastID,
            verifiedRoute: gateFB10Route(from: start)
        )
        return true
    } catch {
        return false
    }
}

private func gateFB10Observer(
    _ session: AgentSimulationSession
) -> (schema: Int, mutations: Int) {
    let before = try! session.durableStateBytes()
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "gate-f-b10-world",
            storageIdentity: "memory:gate-f-b10",
            seed: 10_010, dimension: 0,
            observedWorldTick: session.tick
        )
    )
    return (
        observer.header.schemaVersion,
        (try! session.durableStateBytes()) == before ? 0 : 1
    )
}

private struct GateFB10FreshReport: Codable {
    let schemaVersion: Int
    let phase: String
    let tick: Int
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let pendingSequence: UInt64?
    let migrationStartSequence: UInt64?
    let migrationFailureSequence: UInt64?
    let deathFinalSequence: UInt64?
    let migrationAccepted: Bool?
    let replayedDeaths: Int
    let replayedEstates: Int
    let observerMutations: Int
    let ordinals: GateFB10Ordinals
    let authority: [GateFB10Authority]
    let assertions: [String: Bool]
}

private func gateFB10WriteJSON<T: Encodable>(_ value: T, to url: URL) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try! encoder.encode(value).write(to: url, options: .atomic)
}

private func gateFB10Report(
    phase: String,
    session: AgentSimulationSession,
    checkpointBytes: Data,
    durableBytes: Data,
    pendingSequence: UInt64? = nil,
    migrationStartSequence: UInt64? = nil,
    migrationFailureSequence: UInt64? = nil,
    deathFinalSequence: UInt64? = nil,
    migrationAccepted: Bool? = nil,
    replayedDeaths: Int = 0,
    replayedEstates: Int = 0,
    authority: [GateFB10Authority],
    assertions: [String: Bool]
) -> GateFB10FreshReport {
    let observer = gateFB10Observer(session)
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    return GateFB10FreshReport(
        schemaVersion: 1, phase: phase, tick: session.tick,
        checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observer.schema,
        checkpointSHA256:
            AgentCheckpointDigest.sha256(checkpointBytes).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        pendingSequence: pendingSequence,
        migrationStartSequence: migrationStartSequence,
        migrationFailureSequence: migrationFailureSequence,
        deathFinalSequence: deathFinalSequence,
        migrationAccepted: migrationAccepted,
        replayedDeaths: replayedDeaths, replayedEstates: replayedEstates,
        observerMutations: observer.mutations,
        ordinals: gateFB10Ordinals(session), authority: authority,
        assertions: assertions
    )
}

private func gateFB10FreshProcessIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment["PEBBLELAB_GATE_F_BLOCKER_10_PHASE"] else {
        return false
    }
    let valid = [
        "pending-write", "pending-restore-refuse-finalize",
        "pending-restore-verify", "migration-write",
        "migration-restore-mortality", "migration-restore-verify",
    ]
    guard valid.contains(phase),
          let output = environment["PEBBLELAB_GATE_F_BLOCKER_10_OUT"] else {
        preconditionFailure("invalid Gate F Blocker 10 fresh-process environment")
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let prefix = phase.hasPrefix("pending") ? "pending" : "migration"
    let preCheckpointURL = root.appendingPathComponent(
        "\(prefix)_pre_checkpoint_v35.json"
    )
    let preDurableURL = root.appendingPathComponent(
        "\(prefix)_pre_durable_state.json"
    )
    let postCheckpointURL = root.appendingPathComponent(
        "\(prefix)_post_checkpoint_v35.json"
    )
    let postDurableURL = root.appendingPathComponent(
        "\(prefix)_post_durable_state.json"
    )
    let reportURL = root.appendingPathComponent("\(phase)_report.json")

    if phase == "pending-write" {
        let fixture = gateFB10StagePending(
            "gate-f-b10-pending-fresh", fingerprint: 110_101
        )
        let session = fixture.session
        let pending = session.pendingMortalityTransitions().first {
            $0.agentID == gateFB10MigrantID
        }!
        let checkpointBytes = try! AgentCheckpointCodec.encode(
            try! session.makeCheckpoint()
        )
        let durableBytes = try! session.durableStateBytes()
        try! checkpointBytes.write(to: preCheckpointURL, options: .atomic)
        try! durableBytes.write(to: preDurableURL, options: .atomic)
        let authority = gateFB10Authority(
            session, stage: "pending-process-1"
        )
        let report = gateFB10Report(
            phase: phase, session: session,
            checkpointBytes: checkpointBytes, durableBytes: durableBytes,
            pendingSequence: pending.pendingEventID.sequence.rawValue,
            authority: [authority], assertions: [
                "schema_35": (try! session.makeCheckpoint()).schemaVersion == 35,
                "terminal_pending": authority.mortalityPending,
                "health_zero": authority.health == 0,
                "origin_resident": authority.originResident,
                "no_migration": authority.activeMigrationCount == 0,
                "next_migration_one": gateFB10Ordinals(session).migration == 1,
                "singular_authority": gateFB10CurrentAuthorityIsSingular(session),
            ]
        )
        gateFB10WriteJSON(report, to: reportURL)
        check("B10 fresh pending process 1 writes terminal checkpoint",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "pending-restore-refuse-finalize" {
        let checkpointBytes = try! Data(contentsOf: preCheckpointURL)
        let durableBytes = try! Data(contentsOf: preDurableURL)
        let checkpoint = try! AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        var session = try! AgentSimulationSession.restoring(checkpoint)
        let restoredExact = (try! session.durableStateBytes()) == durableBytes
        let before = try! session.durableStateBytes()
        let beforeOrdinals = gateFB10Ordinals(session)
        let beforeAuthority = gateFB10Authority(
            session, stage: "pending-process-2-before-refusal"
        )
        let accepted = gateFB10AttemptMigration(&session)
        let afterRefusal = try! session.durableStateBytes()
        let afterOrdinals = gateFB10Ordinals(session)
        let afterAuthority = gateFB10Authority(
            session, stage: "pending-process-2-after-refusal"
        )
        let pendingSequence = session.pendingMortalityTransitions().first {
            $0.agentID == gateFB10MigrantID
        }!.pendingEventID.sequence.rawValue
        gateFB10ResolveEmptyCustody(&session, agentID: gateFB10MigrantID)
        _ = try! session.finalizePendingMortality(for: gateFB10MigrantID)
        let events = session.causalLedgerSnapshot().events
        let deathFinal = events.first {
            $0.kind == .agentDeathFinalized && $0.subjectID == gateFB10MigrantID
        }!
        let postCheckpointBytes = try! AgentCheckpointCodec.encode(
            try! session.makeCheckpoint()
        )
        let postDurableBytes = try! session.durableStateBytes()
        try! postCheckpointBytes.write(to: postCheckpointURL, options: .atomic)
        try! postDurableBytes.write(to: postDurableURL, options: .atomic)
        let finalAuthority = gateFB10Authority(
            session, stage: "pending-process-2-finalized"
        )
        let report = gateFB10Report(
            phase: phase, session: session,
            checkpointBytes: postCheckpointBytes,
            durableBytes: postDurableBytes,
            pendingSequence: pendingSequence,
            deathFinalSequence: deathFinal.sequence.rawValue,
            migrationAccepted: accepted,
            authority: [beforeAuthority, afterAuthority, finalAuthority],
            assertions: [
                "restore_byte_exact": restoredExact,
                "migration_refused": !accepted,
                "refusal_durable_byte_exact": before == afterRefusal,
                "all_ordinals_conserved": beforeOrdinals == afterOrdinals,
                "pending_preserved": afterAuthority.mortalityPending,
                "no_migration_authority": afterAuthority.activeMigrationCount == 0,
                "death_finalized_once": session.mortalitySnapshot().totalDeathCount == 1,
                "no_current_authority_after_death": gateFB10CurrentAuthorityIsSingular(session),
                "schema_35": (try! session.makeCheckpoint()).schemaVersion == 35,
            ]
        )
        gateFB10WriteJSON(report, to: reportURL)
        check("B10 fresh pending process 2 refuses and finalizes",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "pending-restore-verify" {
        let checkpointBytes = try! Data(contentsOf: postCheckpointURL)
        let durableBytes = try! Data(contentsOf: postDurableURL)
        let checkpoint = try! AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        let session = try! AgentSimulationSession.restoring(checkpoint)
        let deaths = session.mortalitySnapshot().totalDeathCount
        let estates = session.estateSnapshot().totalEstateCount
        let authority = gateFB10Authority(
            session, stage: "pending-process-3-restored"
        )
        let report = gateFB10Report(
            phase: phase, session: session,
            checkpointBytes: checkpointBytes, durableBytes: durableBytes,
            replayedDeaths: Int(session.mortalitySnapshot().totalDeathCount - deaths),
            replayedEstates: Int(session.estateSnapshot().totalEstateCount - estates),
            authority: [authority], assertions: [
                "restore_byte_exact": (try! session.durableStateBytes()) == durableBytes,
                "zero_death_replay": session.mortalitySnapshot().totalDeathCount == deaths,
                "zero_estate_replay": session.estateSnapshot().totalEstateCount == estates,
                "no_migration_resurrection": authority.activeMigrationCount == 0,
                "dead_not_current": !authority.activeAgent,
                "singular_authority": gateFB10CurrentAuthorityIsSingular(session),
            ]
        )
        gateFB10WriteJSON(report, to: reportURL)
        check("B10 fresh pending process 3 restores without replay",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "migration-write" {
        var session = gateFB10Session("gate-f-b10-migration-fresh")
        _ = gateFB10Birth(&session, fingerprint: 110_102)
        let before = gateFB10Authority(session, stage: "migration-process-1-before")
        let migration = try! session.beginSettlementMigration(
            agentID: gateFB10MigrantID,
            destinationSettlementID: gateFB10EastID,
            verifiedRoute: gateFB10Route(from: AgentPosition(x: 4, y: 64, z: 0))
        )
        let after = gateFB10Authority(session, stage: "migration-process-1-after")
        let checkpointBytes = try! AgentCheckpointCodec.encode(
            try! session.makeCheckpoint()
        )
        let durableBytes = try! session.durableStateBytes()
        try! checkpointBytes.write(to: preCheckpointURL, options: .atomic)
        try! durableBytes.write(to: preDurableURL, options: .atomic)
        let report = gateFB10Report(
            phase: phase, session: session,
            checkpointBytes: checkpointBytes, durableBytes: durableBytes,
            migrationStartSequence: migration.startedEventID.sequence.rawValue,
            migrationAccepted: true, authority: [before, after], assertions: [
                "healthy_before_migration": before.health == 1 && !before.mortalityPending,
                "migration_accepted": after.activeMigrationCount == 1,
                "origin_transit_only": !after.originResident && after.originInTransit
                    && !after.destinationResident && !after.destinationInTransit,
                "migration_ordinal_consumed_once": gateFB10Ordinals(session).migration == 2,
                "schema_35": (try! session.makeCheckpoint()).schemaVersion == 35,
                "singular_authority": gateFB10CurrentAuthorityIsSingular(session),
            ]
        )
        gateFB10WriteJSON(report, to: reportURL)
        check("B10 fresh migration process 1 preserves inverse order",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "migration-restore-mortality" {
        let checkpointBytes = try! Data(contentsOf: preCheckpointURL)
        let durableBytes = try! Data(contentsOf: preDurableURL)
        let checkpoint = try! AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        var session = try! AgentSimulationSession.restoring(checkpoint)
        let restoredExact = (try! session.durableStateBytes()) == durableBytes
        let migration = session.populationScaleSnapshot().settlementMigrations.first {
            $0.agentID == gateFB10MigrantID && $0.status == .inTransit
        }!
        for _ in 0..<8 where !session.pendingMortalityTransitions().contains(
            where: { $0.agentID == gateFB10MigrantID }
        ) {
            _ = try! session.advanceTick()
        }
        let pending = session.pendingMortalityTransitions().first {
            $0.agentID == gateFB10MigrantID
        }!
        gateFB10ResolveEmptyCustody(&session, agentID: gateFB10MigrantID)
        _ = try! session.finalizePendingMortality(for: gateFB10MigrantID)
        let finalMigration = session.populationScaleSnapshot()
            .settlementMigrations.first { $0.migrationID == migration.migrationID }!
        let events = session.causalLedgerSnapshot().events
        let failure = events.first {
            $0.kind == .settlementMigrationFailed
                && $0.subjectID == gateFB10MigrantID
        }!
        let death = events.first {
            $0.kind == .agentDeathFinalized && $0.subjectID == gateFB10MigrantID
        }!
        let postCheckpointBytes = try! AgentCheckpointCodec.encode(
            try! session.makeCheckpoint()
        )
        let postDurableBytes = try! session.durableStateBytes()
        try! postCheckpointBytes.write(to: postCheckpointURL, options: .atomic)
        try! postDurableBytes.write(to: postDurableURL, options: .atomic)
        let authority = gateFB10Authority(
            session, stage: "migration-process-2-finalized"
        )
        let report = gateFB10Report(
            phase: phase, session: session,
            checkpointBytes: postCheckpointBytes,
            durableBytes: postDurableBytes,
            pendingSequence: pending.pendingEventID.sequence.rawValue,
            migrationStartSequence: migration.startedEventID.sequence.rawValue,
            migrationFailureSequence: failure.sequence.rawValue,
            deathFinalSequence: death.sequence.rawValue,
            migrationAccepted: true, authority: [authority], assertions: [
                "restore_byte_exact": restoredExact,
                "migration_precedes_pending": migration.startedEventID.sequence
                    < pending.pendingEventID.sequence,
                "member_died_cleanup": finalMigration.status == .failed
                    && finalMigration.failure == .memberDied,
                "cleanup_precedes_death": failure.sequence < death.sequence,
                "death_finalized_once": session.mortalitySnapshot().totalDeathCount == 1,
                "no_stranded_migration": authority.activeMigrationCount == 0,
                "singular_authority": gateFB10CurrentAuthorityIsSingular(session),
            ]
        )
        gateFB10WriteJSON(report, to: reportURL)
        check("B10 fresh migration process 2 closes migration on death",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    let checkpointBytes = try! Data(contentsOf: postCheckpointURL)
    let durableBytes = try! Data(contentsOf: postDurableURL)
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    let session = try! AgentSimulationSession.restoring(checkpoint)
    let deaths = session.mortalitySnapshot().totalDeathCount
    let estates = session.estateSnapshot().totalEstateCount
    let authority = gateFB10Authority(
        session, stage: "migration-process-3-restored"
    )
    let report = gateFB10Report(
        phase: phase, session: session,
        checkpointBytes: checkpointBytes, durableBytes: durableBytes,
        replayedDeaths: Int(session.mortalitySnapshot().totalDeathCount - deaths),
        replayedEstates: Int(session.estateSnapshot().totalEstateCount - estates),
        authority: [authority], assertions: [
            "restore_byte_exact": (try! session.durableStateBytes()) == durableBytes,
            "zero_death_replay": session.mortalitySnapshot().totalDeathCount == deaths,
            "zero_estate_replay": session.estateSnapshot().totalEstateCount == estates,
            "no_migration_resurrection": authority.activeMigrationCount == 0,
            "dead_not_current": !authority.activeAgent,
            "singular_authority": gateFB10CurrentAuthorityIsSingular(session),
        ]
    )
    gateFB10WriteJSON(report, to: reportURL)
    check("B10 fresh migration process 3 restores without replay",
          report.assertions.values.allSatisfy { $0 })
    return true
}

func runPebbleAgentsGateFBlocker10Smoke() {
    section("Gate F Blocker 10 terminal mortality migration admission")
    if gateFB10FreshProcessIfRequested() { return }

    var exact = gateFB10StagePending(
        "gate-f-b10-exact-evaluation-10", fingerprint: 110_201
    ).session
    let pending = exact.pendingMortalityTransitions().first {
        $0.agentID == gateFB10MigrantID
    }!
    let beforeBytes = try! exact.durableStateBytes()
    let beforeCheckpointBytes = try! AgentCheckpointCodec.encode(
        try! exact.makeCheckpoint()
    )
    let beforeOrdinals = gateFB10Ordinals(exact)
    let beforeAuthority = gateFB10Authority(exact, stage: "before-refusal")
    let accepted = gateFB10AttemptMigration(&exact)
    let afterBytes = try! exact.durableStateBytes()
    let afterCheckpointBytes = try! AgentCheckpointCodec.encode(
        try! exact.makeCheckpoint()
    )
    let afterOrdinals = gateFB10Ordinals(exact)
    let afterAuthority = gateFB10Authority(exact, stage: "after-refusal")
    let migrationEvents = exact.causalLedgerSnapshot().events.filter {
        $0.kind == .settlementMigrationStarted
            && $0.subjectID == gateFB10MigrantID
            && $0.sequence > pending.pendingEventID.sequence
    }

    check("B10 exact Eval10 terminal pending migration refuses", !accepted)
    check("B10 exact refusal publishes no migration event", migrationEvents.isEmpty)
    check("B10 exact refusal creates no migration record",
          afterAuthority.activeMigrationCount == 0)
    check("B10 exact refusal consumes no migration identity",
          beforeOrdinals.migration == 1 && afterOrdinals.migration == 1)
    check("B10 exact refusal conserves every tracked ordinal and identity",
          beforeOrdinals == afterOrdinals)
    check("B10 exact refusal is durable byte-atomic",
          beforeBytes == afterBytes && beforeCheckpointBytes == afterCheckpointBytes)
    check("B10 exact refusal preserves terminal mortality authority",
          beforeAuthority.health == 0 && beforeAuthority.mortalityPending
            && afterAuthority.mortalityPending
            && beforeAuthority.mortalityPendingSequence
                == afterAuthority.mortalityPendingSequence)
    check("B10 exact refusal preserves current settlement authority",
          beforeAuthority == GateFB10Authority(
            stage: "before-refusal", tick: afterAuthority.tick,
            health: afterAuthority.health,
            activeAgent: afterAuthority.activeAgent,
            populationMember: afterAuthority.populationMember,
            membershipStatus: afterAuthority.membershipStatus,
            memberSettlement: afterAuthority.memberSettlement,
            originResident: afterAuthority.originResident,
            originInTransit: afterAuthority.originInTransit,
            destinationResident: afterAuthority.destinationResident,
            destinationInTransit: afterAuthority.destinationInTransit,
            activeMigrationCount: afterAuthority.activeMigrationCount,
            fidelityOwnerCount: afterAuthority.fidelityOwnerCount,
            currentHousehold: afterAuthority.currentHousehold,
            familyRelationCount: afterAuthority.familyRelationCount,
            careAsDependent: afterAuthority.careAsDependent,
            careAsCaregiver: afterAuthority.careAsCaregiver,
            guardianshipAsDependent: afterAuthority.guardianshipAsDependent,
            guardianshipAsGuardian: afterAuthority.guardianshipAsGuardian,
            mortalityPending: afterAuthority.mortalityPending,
            mortalityPendingSequence: afterAuthority.mortalityPendingSequence,
            deathID: afterAuthority.deathID,
            estateCount: afterAuthority.estateCount
          ))
    check("B10 exact authority remains resident-only and singular",
          afterAuthority.originResident && !afterAuthority.originInTransit
            && !afterAuthority.destinationResident
            && !afterAuthority.destinationInTransit
            && gateFB10CurrentAuthorityIsSingular(exact))

    var previousTick = gateFB10StagePending(
        "gate-f-b10-previous-tick", fingerprint: 110_202
    ).session
    let previousPendingTick = previousTick.tick
    let previousBytes = try! previousTick.durableStateBytes()
    var tickAdvanceRefused = false
    do {
        _ = try previousTick.advanceTick()
    } catch AgentSessionError.mortality(.pendingMaterialExit(
        gateFB10MigrantID.rawValue
    )) {
        tickAdvanceRefused = true
    } catch {}
    let tickRefusalExact = (try! previousTick.durableStateBytes())
        == previousBytes
    let previousOrdinals = gateFB10Ordinals(previousTick)
    let previousAccepted = gateFB10AttemptMigration(&previousTick)
    check("B10 unresolved pending cannot cross a public tick boundary",
          tickAdvanceRefused && previousTick.tick == previousPendingTick
            && tickRefusalExact)
    check("B10 pending migration still refuses after tick-boundary refusal",
          !previousAccepted
            && (try! previousTick.durableStateBytes()) == previousBytes
            && gateFB10Ordinals(previousTick) == previousOrdinals)

    var healthy = gateFB10Session(
        "gate-f-b10-healthy", terminalAgentOrdinal: nil
    )
    _ = gateFB10Birth(&healthy, fingerprint: 110_203)
    let healthyBefore = gateFB10Authority(healthy, stage: "healthy-before")
    let healthyMigration = try! healthy.beginSettlementMigration(
        agentID: gateFB10MigrantID,
        destinationSettlementID: gateFB10EastID,
        verifiedRoute: gateFB10Route(from: AgentPosition(x: 4, y: 64, z: 0))
    )
    let healthyAfter = gateFB10Authority(healthy, stage: "healthy-after")
    check("B10 healthy non-terminal migration accepts normally",
          healthyBefore.health == 100 && !healthyBefore.mortalityPending
            && healthyMigration.status == .inTransit
            && healthyAfter.activeMigrationCount == 1
            && gateFB10Ordinals(healthy).migration == 2)

    var inverse = gateFB10Session("gate-f-b10-inverse-order")
    _ = gateFB10Birth(&inverse, fingerprint: 110_204)
    let inverseHealthAtAdmission = try! inverse.state(for: gateFB10MigrantID).health
    let inverseMigration = try! inverse.beginSettlementMigration(
        agentID: gateFB10MigrantID,
        destinationSettlementID: gateFB10EastID,
        verifiedRoute: gateFB10Route(from: AgentPosition(x: 4, y: 64, z: 0))
    )
    for _ in 0..<8 where !inverse.pendingMortalityTransitions().contains(
        where: { $0.agentID == gateFB10MigrantID }
    ) {
        _ = try! inverse.advanceTick()
    }
    let inversePending = inverse.pendingMortalityTransitions().first {
        $0.agentID == gateFB10MigrantID
    }!
    gateFB10ResolveEmptyCustody(&inverse, agentID: gateFB10MigrantID)
    _ = try! inverse.finalizePendingMortality(for: gateFB10MigrantID)
    let inverseFinal = inverse.populationScaleSnapshot()
        .settlementMigrations.first {
            $0.migrationID == inverseMigration.migrationID
        }!
    let inverseEvents = inverse.causalLedgerSnapshot().events
    let inverseFailure = inverseEvents.first {
        $0.kind == .settlementMigrationFailed
            && $0.subjectID == gateFB10MigrantID
    }!
    let inverseDeath = inverseEvents.first {
        $0.kind == .agentDeathFinalized && $0.subjectID == gateFB10MigrantID
    }!
    check("B10 migration-before-mortality remains supported",
          inverseHealthAtAdmission == 1
            && inverseMigration.startedEventID.sequence
                < inversePending.pendingEventID.sequence)
    check("B10 inverse order fails memberDied and finalizes exactly once",
          inverseFinal.status == .failed && inverseFinal.failure == .memberDied
            && inverseFailure.sequence < inverseDeath.sequence
            && inverse.mortalitySnapshot().totalDeathCount == 1
            && inverse.estateSnapshot().totalEstateCount == 1
            && gateFB10CurrentAuthorityIsSingular(inverse))

    var protected = gateFB10Session(
        "gate-f-b10-care-protected", terminalAgentOrdinal: nil
    )
    let protectedBirth = gateFB10Birth(&protected, fingerprint: 110_205)
    let guardian = try! protected.currentGuardian(for: protectedBirth.newbornID)!
    let protectedBytes = try! protected.durableStateBytes()
    let protectedOrdinals = gateFB10Ordinals(protected)
    let guardianAccepted = gateFB10AttemptMigration(
        &protected, agentID: guardian.guardianID
    )
    check("B10 care-protected guardian refusal remains atomic",
          !guardianAccepted
            && (try! protected.durableStateBytes()) == protectedBytes
            && gateFB10Ordinals(protected) == protectedOrdinals)

    var finalized = gateFB10StagePending(
        "gate-f-b10-finalized", fingerprint: 110_206
    ).session
    gateFB10ResolveEmptyCustody(&finalized, agentID: gateFB10MigrantID)
    _ = try! finalized.finalizePendingMortality(for: gateFB10MigrantID)
    let finalizedBytes = try! finalized.durableStateBytes()
    let finalizedOrdinals = gateFB10Ordinals(finalized)
    let finalizedAccepted = gateFB10AttemptMigration(&finalized)
    check("B10 finalized dead agent cannot acquire migration authority",
          !finalizedAccepted
            && (try! finalized.durableStateBytes()) == finalizedBytes
            && gateFB10Ordinals(finalized) == finalizedOrdinals
            && !gateFB10Authority(
                finalized, stage: "finalized-control"
            ).activeAgent)

    var immediate = gateFB10Session(
        "gate-f-b10-immediate", embodiedMortality: false
    )
    _ = gateFB10Birth(&immediate, fingerprint: 110_207)
    for _ in 0..<8 where immediate.snapshot().agents.contains(
        where: { $0.id == gateFB10MigrantID.rawValue }
    ) {
        _ = try! immediate.advanceTick()
    }
    let immediateBytes = try! immediate.durableStateBytes()
    let immediateAccepted = gateFB10AttemptMigration(&immediate)
    check("B10 immediate terminal path has no public admission gap",
          immediate.pendingMortalityTransitions().allSatisfy {
            $0.agentID != gateFB10MigrantID
          } && !immediateAccepted
            && (try! immediate.durableStateBytes()) == immediateBytes)

    let checkpoint = try! exact.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    let observer = gateFB10Observer(exact)
    check("B10 schema 35 restore preserves atomic refusal exactly",
          checkpoint.schemaVersion == 35
            && (try! restored.durableStateBytes()) == afterBytes)
    check("B10 Observer 13 remains read-only",
          observer.schema == 13 && observer.mutations == 0)
    check("B10 refusal leaves household Family care and fidelity unchanged",
          beforeAuthority.currentHousehold == afterAuthority.currentHousehold
            && beforeAuthority.familyRelationCount
                == afterAuthority.familyRelationCount
            && beforeAuthority.careAsDependent == afterAuthority.careAsDependent
            && beforeAuthority.careAsCaregiver == afterAuthority.careAsCaregiver
            && beforeAuthority.guardianshipAsDependent
                == afterAuthority.guardianshipAsDependent
            && beforeAuthority.guardianshipAsGuardian
                == afterAuthority.guardianshipAsGuardian
            && beforeAuthority.fidelityOwnerCount
                == afterAuthority.fidelityOwnerCount)

    print(
        "GATE_F_BLOCKER_10_CAUSAL tick=\(exact.tick) "
            + "pendingKind=mortalityMaterialExitPending "
            + "pendingSequence=\(pending.pendingEventID.sequence.rawValue) "
            + "health=\(afterAuthority.health ?? -1) "
            + "migrationPublication=none migrationAccepted=0"
    )
    print(
        "GATE_F_BLOCKER_10_IDENTITY agent=\(gateFB10MigrantID.rawValue) "
            + "refusedMigrationID=settlement-migration-00000001 "
            + "consumed=0 nextMigrationBefore=\(beforeOrdinals.migration) "
            + "nextMigrationAfter=\(afterOrdinals.migration) "
            + "nextPopulation=\(afterOrdinals.population) "
            + "nextFidelity=\(afterOrdinals.fidelity) "
            + "nextHousehold=\(afterOrdinals.household) "
            + "nextUnion=\(afterOrdinals.union) nextHouse=\(afterOrdinals.house)"
    )
    print(
        "GATE_F_BLOCKER_10_CONTROL migrationStart="
            + "\(inverseMigration.startedEventID.sequence.rawValue) "
            + "pending=\(inversePending.pendingEventID.sequence.rawValue) "
            + "failure=\(inverseFailure.sequence.rawValue) "
            + "deathFinal=\(inverseDeath.sequence.rawValue)"
    )
    print(
        "GATE_F_BLOCKER_10_PASS checkpointSchema=35 observerSchema=13 "
            + "terminalPendingAdmission=refused ordinalConsumed=0 "
            + "durableByteAtomic=1 migrationBeforeMortality=supported "
            + "restartDuplicateDeaths=0 restartDuplicateEstates=0"
    )
}
