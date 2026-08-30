import Foundation
import PebbleAgents

private let gateFB11Origin = AgentPosition(x: 0, y: 64, z: 0)
private let gateFB11East = AgentPosition(x: 16, y: 64, z: 0)
private let gateFB11EastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFB11TerminalID = AgentID(rawValue: "agent_2")!
private let gateFB11NewHome = AgentPosition(x: 8, y: 64, z: 0)

private func gateFB11Agent(_ ordinal: Int, terminal: Bool) -> AgentSessionAgentState {
    let position = ordinal == 2
        ? AgentPosition(x: 4, y: 64, z: 0) : gateFB11Origin
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: terminal ? 0.80 : 0, fatigue: 0,
            curiosity: 0.1, safety: 1
        ),
        health: terminal ? 1 : 100, fear: 0, homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 11 public fixture",
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

private func gateFB11Habitat(_ ordinal: Int) -> AgentEcologyHabitatObservation {
    AgentEcologyHabitatObservation(
        worldTick: 0, candidateIndex: ordinal,
        habitatPosition: AgentPosition(x: ordinal * 2 + 1, y: 63, z: 0),
        foragePosition: AgentPosition(x: ordinal * 2 + 1, y: 64, z: 0),
        habitatFingerprint: 111_100 + ordinal,
        distanceFromSettlement: ordinal * 2 + 1,
        directionIndex: ordinal, worldReadCount: 4
    )
}

private func gateFB11Session(
    _ simulationID: String,
    terminalAgentOrdinal: Int? = 2,
    households: Bool = true,
    embodiedMortality: Bool = true
) -> AgentSimulationSession {
    let habitats = (0..<3).map(gateFB11Habitat)
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 11_011, nearbyRadius: 8, resourceObservationRadius: 8,
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
            gateFB11Agent($0, terminal: terminalAgentOrdinal == $0)
        },
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: gateFB11Origin,
        receptionPosition: gateFB11Origin,
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
    try! session.setLifecycleEnabled(true)
    try! session.setKinshipEnabled(true)
    if households { try! session.setHouseholdsEnabled(true) }
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB11EastID,
            anchor: gateFB11East, receptionPosition: gateFB11East,
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
    if households {
        try! session.setDependentCareEnabled(true)
        try! session.setChildhoodV2Enabled(true)
        try! session.setFamilyV1Enabled(true)
    }
    try! session.setMaterialRightsEnabled(true)
    try! session.setMortalityEnabled(
        true, configuration: embodiedMortality ? .embodiedLive : .live
    )
    if embodiedMortality && households { try! session.setEstatesEnabled(true) }
    return session
}

private func gateFB11StagePending(
    _ simulationID: String,
    households: Bool = true
) -> AgentSimulationSession {
    var session = gateFB11Session(simulationID, households: households)
    for _ in 0..<8 where !session.pendingMortalityTransitions().contains(
        where: { $0.agentID == gateFB11TerminalID }
    ) {
        _ = try! session.advanceTick()
    }
    precondition(session.pendingMortalityTransitions().contains {
        $0.agentID == gateFB11TerminalID
    })
    return session
}

private func gateFB11ResolveEmptyCustody(
    _ session: inout AgentSimulationSession,
    suffix: String
) {
    _ = try! session.applyMortalityPhysicalCustodyOutcome(
        AgentMortalityPhysicalCustodyOutcome(
            operationID: "gate-f-b11-empty-\(suffix)",
            terminalAgentID: gateFB11TerminalID, kind: .verifiedEmpty,
            physicalReceiptID: "gate-f-b11-empty-receipt-\(suffix)",
            destinationHolderID: nil, stackCount: 0, itemCount: 0,
            physicalAssets: [], verifiedAtTick: session.tick
        )
    )
}

private func gateFB11Route(from start: AgentPosition) -> [AgentPosition] {
    (start.x...gateFB11East.x).map {
        AgentPosition(x: $0, y: 64, z: 0)
    }
}

private struct GateFB11Ordinals: Codable, Equatable {
    let population: Int
    let fidelity: UInt64
    let migration: UInt64
    let household: Int
    let householdPeriods: Int
    let householdTransitions: Int
    let union: Int
    let lineage: Int
    let house: Int
    let careAssignments: Int
    let careNeeds: Int
    let guardianships: Int
    let materialRecords: Int
    let materialTransitions: Int
    let deaths: Int
    let estates: Int
}

private func gateFB11Ordinals(_ session: AgentSimulationSession) -> GateFB11Ordinals {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    let family = durable.familyState!
    let care = durable.dependentCareState!
    let rights = durable.materialRightsState!
    return GateFB11Ordinals(
        population: population.nextPopulationOrdinal.rawValue,
        fidelity: scale.nextFidelityTransitionOrdinal,
        migration: scale.nextSettlementMigrationOrdinal,
        household: household.nextHouseholdOrdinal.rawValue,
        householdPeriods: household.membershipPeriods.count,
        householdTransitions: household.transitionsAtTick,
        union: family.nextUnionOrdinal,
        lineage: family.nextLineageOrdinal,
        house: family.nextHouseOrdinal,
        careAssignments: care.assignments.count,
        careNeeds: care.activeNeeds.count,
        guardianships: care.childhoodV2!.guardianships.count,
        materialRecords: rights.records.count,
        materialTransitions: rights.recentTransitions.count,
        deaths: durable.mortalityState!.totalDeathCount,
        estates: durable.estateState!.totalEstateCount
    )
}

private struct GateFB11Authority: Codable, Equatable {
    let tick: Int
    let health: Int?
    let pendingSequence: UInt64?
    let currentHousehold: String?
    let joinedSequence: UInt64?
    let home: AgentPosition?
    let navigation: AgentNavigationProgress?
    let residentCount: Int
    let inTransitCount: Int
    let fidelityOwnerCount: Int
    let activeMigrationCount: Int
    let activeAgent: Bool
    let populationMember: Bool
    let unionCount: Int
    let familyHouseCount: Int
    let caregiverCount: Int
    let guardianCount: Int
    let materialRecordCount: Int
    let deathCount: Int
    let estateCount: Int
}

private func gateFB11Authority(_ session: AgentSimulationSession) -> GateFB11Authority {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    let family = durable.familyState!
    let care = durable.dependentCareState!
    let pending = durable.mortalityState!.pendingTransitions.first {
        $0.agentID == gateFB11TerminalID
    }
    let membership = household.membershipPeriods.first {
        $0.agentID == gateFB11TerminalID && $0.leftTick == nil
    }
    let agent = try? session.state(for: gateFB11TerminalID)
    return GateFB11Authority(
        tick: session.tick, health: agent?.health,
        pendingSequence: pending?.pendingEventID.sequence.rawValue,
        currentHousehold: membership?.householdID.rawValue,
        joinedSequence: membership?.joinedEventID.sequence.rawValue,
        home: agent?.homePosition, navigation: agent?.navigationProgress,
        residentCount: population.settlements.filter {
            $0.residentIDs.contains(gateFB11TerminalID)
        }.count,
        inTransitCount: population.settlements.filter {
            $0.inTransitIDs.contains(gateFB11TerminalID)
        }.count,
        fidelityOwnerCount: scale.fidelityRecords.filter {
            $0.agentID == gateFB11TerminalID
        }.count,
        activeMigrationCount: scale.settlementMigrations.filter {
            $0.agentID == gateFB11TerminalID && $0.status == .inTransit
        }.count,
        activeAgent: durable.agents.contains { $0.agentID == gateFB11TerminalID },
        populationMember: population.members.contains {
            $0.agentID == gateFB11TerminalID
        },
        unionCount: family.unions.filter {
            $0.status == .active && $0.partnerIDs.contains(gateFB11TerminalID)
        }.count,
        familyHouseCount: family.houseMembershipPeriods.filter {
            $0.agentID == gateFB11TerminalID && $0.leftTick == nil
        }.count,
        caregiverCount: care.assignments.filter {
            $0.status == .active && $0.caregiverID == gateFB11TerminalID
        }.count,
        guardianCount: care.childhoodV2!.guardianships.filter {
            $0.status == .active && $0.guardianID == gateFB11TerminalID
        }.count,
        materialRecordCount: durable.materialRightsState!.records.count,
        deathCount: durable.mortalityState!.records.filter {
            $0.agentID == gateFB11TerminalID
        }.count,
        estateCount: durable.estateState!.estates.filter {
            $0.decedentID == gateFB11TerminalID
        }.count
    )
}

private struct GateFB11HouseholdEvents: Codable, Equatable {
    let created: Int
    let ended: Int
    let started: Int
    let dissolved: Int
}

private func gateFB11HouseholdEvents(
    _ session: AgentSimulationSession,
    after sequence: UInt64
) -> GateFB11HouseholdEvents {
    let events = session.causalLedgerSnapshot().events.filter {
        $0.sequence.rawValue > sequence
    }
    return GateFB11HouseholdEvents(
        created: events.filter { $0.kind == .householdCreated }.count,
        ended: events.filter { $0.kind == .householdMembershipEnded }.count,
        started: events.filter { $0.kind == .householdMembershipStarted }.count,
        dissolved: events.filter { $0.kind == .householdDissolved }.count
    )
}

private func gateFB11PendingRefusal(
    _ body: () throws -> Void
) -> Bool {
    do {
        try body()
        return false
    } catch AgentSessionError.mortality(.pendingMaterialExit(
        gateFB11TerminalID.rawValue
    )) {
        return true
    } catch {
        return false
    }
}

private func gateFB11Observer(
    _ session: AgentSimulationSession
) -> (schema: Int, mutations: Int) {
    let before = try! session.durableStateBytes()
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "gate-f-b11-world",
            storageIdentity: "memory:gate-f-b11",
            seed: 11_011, dimension: 0,
            observedWorldTick: session.tick
        )
    )
    return (
        observer.header.schemaVersion,
        (try! session.durableStateBytes()) == before ? 0 : 1
    )
}

private struct GateFB11FreshReport: Codable {
    let schemaVersion: Int
    let phase: String
    let checkpointSchema: Int
    let observerSchema: Int
    let observerMutations: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let authority: GateFB11Authority
    let ordinals: GateFB11Ordinals
    let householdEvents: GateFB11HouseholdEvents
    let assertions: [String: Bool]
}

private func gateFB11Write<T: Encodable>(_ value: T, to url: URL) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try! encoder.encode(value).write(to: url, options: .atomic)
}

private func gateFB11FreshReport(
    phase: String,
    session: AgentSimulationSession,
    checkpointBytes: Data,
    durableBytes: Data,
    after sequence: UInt64,
    assertions: [String: Bool]
) -> GateFB11FreshReport {
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    let observer = gateFB11Observer(session)
    return GateFB11FreshReport(
        schemaVersion: 1, phase: phase,
        checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observer.schema, observerMutations: observer.mutations,
        checkpointSHA256: AgentCheckpointDigest.sha256(checkpointBytes).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        authority: gateFB11Authority(session),
        ordinals: gateFB11Ordinals(session),
        householdEvents: gateFB11HouseholdEvents(session, after: sequence),
        assertions: assertions
    )
}

private func gateFB11FreshProcessIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment["PEBBLELAB_GATE_F_B11_PHASE"] else {
        return false
    }
    let phases = [
        "pending-write", "pending-restore-finalize", "pending-restore-verify",
        "inverse-write", "inverse-restore-finalize", "inverse-restore-verify",
    ]
    guard phases.contains(phase),
          let output = environment["PEBBLELAB_GATE_F_B11_OUT"] else {
        preconditionFailure("invalid Gate F Blocker 11 fresh-process environment")
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let prefix = phase.hasPrefix("pending") ? "pending" : "inverse"
    let initialCheckpointURL = root.appendingPathComponent(
        "\(prefix)_initial_checkpoint_v35.json"
    )
    let initialDurableURL = root.appendingPathComponent(
        "\(prefix)_initial_durable_state.json"
    )
    let finalCheckpointURL = root.appendingPathComponent(
        "\(prefix)_final_checkpoint_v35.json"
    )
    let finalDurableURL = root.appendingPathComponent(
        "\(prefix)_final_durable_state.json"
    )
    let reportURL = root.appendingPathComponent("\(phase)_report.json")

    if phase == "pending-write" {
        let session = gateFB11StagePending("gate-f-b11-fresh-pending")
        let pending = session.pendingMortalityTransitions().first {
            $0.agentID == gateFB11TerminalID
        }!
        let checkpointBytes = try! AgentCheckpointCodec.encode(
            try! session.makeCheckpoint()
        )
        let durableBytes = try! session.durableStateBytes()
        try! checkpointBytes.write(to: initialCheckpointURL, options: .atomic)
        try! durableBytes.write(to: initialDurableURL, options: .atomic)
        let report = gateFB11FreshReport(
            phase: phase, session: session,
            checkpointBytes: checkpointBytes, durableBytes: durableBytes,
            after: pending.pendingEventID.sequence.rawValue,
            assertions: [
                "pending_e58": pending.pendingEventID.sequence.rawValue == 58,
                "household_1_current": gateFB11Authority(session).currentHousehold
                    == "household_1",
                "household_ordinal_2": gateFB11Ordinals(session).household == 2,
                "schema_35": (try! session.makeCheckpoint()).schemaVersion == 35,
            ]
        )
        gateFB11Write(report, to: reportURL)
        check("B11 fresh pending writer freezes pre-request authority",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "pending-restore-finalize" {
        let initialCheckpointBytes = try! Data(contentsOf: initialCheckpointURL)
        let initialDurableBytes = try! Data(contentsOf: initialDurableURL)
        var session = try! AgentSimulationSession.restoring(
            AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self, from: initialCheckpointBytes
            )
        )
        let pending = session.pendingMortalityTransitions().first {
            $0.agentID == gateFB11TerminalID
        }!
        let before = gateFB11Authority(session)
        let beforeOrdinals = gateFB11Ordinals(session)
        let refused = gateFB11PendingRefusal {
            _ = try session.createSingletonHousehold(
                for: gateFB11TerminalID, residenceAnchor: gateFB11NewHome,
                reason: .formedHousehold
            )
        }
        let afterCheckpointBytes = try! AgentCheckpointCodec.encode(
            try! session.makeCheckpoint()
        )
        let atomic = refused
            && (try! session.durableStateBytes()) == initialDurableBytes
            && afterCheckpointBytes == initialCheckpointBytes
            && gateFB11Authority(session) == before
            && gateFB11Ordinals(session) == beforeOrdinals
            && gateFB11HouseholdEvents(
                session, after: pending.pendingEventID.sequence.rawValue
            ) == GateFB11HouseholdEvents(created: 0, ended: 0, started: 0, dissolved: 0)
        gateFB11ResolveEmptyCustody(&session, suffix: "fresh-pending")
        _ = try! session.finalizePendingMortality(for: gateFB11TerminalID)
        let finalCheckpointBytes = try! AgentCheckpointCodec.encode(
            try! session.makeCheckpoint()
        )
        let finalDurableBytes = try! session.durableStateBytes()
        try! finalCheckpointBytes.write(to: finalCheckpointURL, options: .atomic)
        try! finalDurableBytes.write(to: finalDurableURL, options: .atomic)
        let authority = gateFB11Authority(session)
        let report = gateFB11FreshReport(
            phase: phase, session: session,
            checkpointBytes: finalCheckpointBytes, durableBytes: finalDurableBytes,
            after: pending.pendingEventID.sequence.rawValue,
            assertions: [
                "restore_exact": atomic,
                "death_once": authority.deathCount == 1,
                "estate_once": authority.estateCount == 1,
                "cleanup_removed_current_authority": !authority.activeAgent
                    && !authority.populationMember
                    && authority.currentHousehold == nil,
                "schema_35": (try! session.makeCheckpoint()).schemaVersion == 35,
            ]
        )
        gateFB11Write(report, to: reportURL)
        check("B11 fresh pending reader refuses atomically then finalizes once",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "pending-restore-verify" {
        let checkpointBytes = try! Data(contentsOf: finalCheckpointURL)
        let durableBytes = try! Data(contentsOf: finalDurableURL)
        let session = try! AgentSimulationSession.restoring(
            AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self, from: checkpointBytes
            )
        )
        let authority = gateFB11Authority(session)
        let report = gateFB11FreshReport(
            phase: phase, session: session,
            checkpointBytes: checkpointBytes, durableBytes: durableBytes,
            after: 58,
            assertions: [
                "final_restore_exact": (try! session.durableStateBytes()) == durableBytes,
                "zero_death_replay": authority.deathCount == 1,
                "zero_estate_replay": authority.estateCount == 1,
                "zero_household_resurrection": authority.currentHousehold == nil,
                "dead_not_current": !authority.activeAgent
                    && !authority.populationMember,
            ]
        )
        gateFB11Write(report, to: reportURL)
        check("B11 fresh pending verifier restores without replay",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "inverse-write" {
        var session = gateFB11Session("gate-f-b11-fresh-inverse")
        let household = try! session.createSingletonHousehold(
            for: gateFB11TerminalID, residenceAnchor: gateFB11NewHome,
            reason: .formedHousehold
        )
        let checkpointBytes = try! AgentCheckpointCodec.encode(
            try! session.makeCheckpoint()
        )
        let durableBytes = try! session.durableStateBytes()
        try! checkpointBytes.write(to: initialCheckpointURL, options: .atomic)
        try! durableBytes.write(to: initialDurableURL, options: .atomic)
        let authority = gateFB11Authority(session)
        let report = gateFB11FreshReport(
            phase: phase, session: session,
            checkpointBytes: checkpointBytes, durableBytes: durableBytes,
            after: 0,
            assertions: [
                "healthy_household_accepted": household.householdID.rawValue
                    == "household_2" && authority.currentHousehold == "household_2",
                "membership_e36": authority.joinedSequence == 36,
                "mortality_not_pending": authority.pendingSequence == nil,
                "schema_35": (try! session.makeCheckpoint()).schemaVersion == 35,
            ]
        )
        gateFB11Write(report, to: reportURL)
        check("B11 fresh inverse writer creates healthy authority",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "inverse-restore-finalize" {
        let initialCheckpointBytes = try! Data(contentsOf: initialCheckpointURL)
        let initialDurableBytes = try! Data(contentsOf: initialDurableURL)
        var session = try! AgentSimulationSession.restoring(
            AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self, from: initialCheckpointBytes
            )
        )
        let restoredExact = (try! session.durableStateBytes()) == initialDurableBytes
        for _ in 0..<8 where !session.pendingMortalityTransitions().contains(
            where: { $0.agentID == gateFB11TerminalID }
        ) {
            _ = try! session.advanceTick()
        }
        let pending = session.pendingMortalityTransitions().first {
            $0.agentID == gateFB11TerminalID
        }!
        gateFB11ResolveEmptyCustody(&session, suffix: "fresh-inverse")
        _ = try! session.finalizePendingMortality(for: gateFB11TerminalID)
        let finalCheckpointBytes = try! AgentCheckpointCodec.encode(
            try! session.makeCheckpoint()
        )
        let finalDurableBytes = try! session.durableStateBytes()
        try! finalCheckpointBytes.write(to: finalCheckpointURL, options: .atomic)
        try! finalDurableBytes.write(to: finalDurableURL, options: .atomic)
        let authority = gateFB11Authority(session)
        let events = session.causalLedgerSnapshot().events
        let ended = events.first {
            $0.kind == .householdMembershipEnded
                && $0.subjectID == gateFB11TerminalID
                && $0.sequence > pending.pendingEventID.sequence
        }
        let death = events.first {
            $0.kind == .agentDeathFinalized && $0.subjectID == gateFB11TerminalID
        }
        let report = gateFB11FreshReport(
            phase: phase, session: session,
            checkpointBytes: finalCheckpointBytes, durableBytes: finalDurableBytes,
            after: pending.pendingEventID.sequence.rawValue,
            assertions: [
                "restore_exact": restoredExact,
                "pending_after_existing_authority": pending.pendingEventID.sequence.rawValue
                    > 36,
                "cleanup_before_death": ended != nil && death != nil
                    && ended!.sequence < death!.sequence,
                "death_once": authority.deathCount == 1,
                "estate_once": authority.estateCount == 1,
                "no_stranded_household": authority.currentHousehold == nil,
            ]
        )
        gateFB11Write(report, to: reportURL)
        check("B11 fresh inverse reader cleans up existing authority",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    let checkpointBytes = try! Data(contentsOf: finalCheckpointURL)
    let durableBytes = try! Data(contentsOf: finalDurableURL)
    let session = try! AgentSimulationSession.restoring(
        AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
    )
    let authority = gateFB11Authority(session)
    let report = gateFB11FreshReport(
        phase: phase, session: session,
        checkpointBytes: checkpointBytes, durableBytes: durableBytes,
        after: 36,
        assertions: [
            "final_restore_exact": (try! session.durableStateBytes()) == durableBytes,
            "zero_death_replay": authority.deathCount == 1,
            "zero_estate_replay": authority.estateCount == 1,
            "zero_household_resurrection": authority.currentHousehold == nil,
            "dead_not_current": !authority.activeAgent && !authority.populationMember,
        ]
    )
    gateFB11Write(report, to: reportURL)
    check("B11 fresh inverse verifier restores without replay",
          report.assertions.values.allSatisfy { $0 })
    return true
}

// Evaluation 12 Attack 07 composes the published B10 and B11 guards over a
// schema-35 restart. This bridge only builds supported public pebsmoke seeds;
// refusal and cleanup are exercised by the independent Attack 07 harness.
func gateFE12A7BuildSeed(
    _ simulationID: String,
    inverse: Bool
) -> GateFE12A7Seed {
    if !inverse {
        let session = gateFB11StagePending(simulationID)
        let pending = session.pendingMortalityTransitions().first {
            $0.agentID == gateFB11TerminalID
        }!
        let membership = session.durableState().householdState!
            .membershipPeriods.first {
                $0.agentID == gateFB11TerminalID && $0.leftTick == nil
            }!
        return GateFE12A7Seed(
            session: session, scenario: "pending-before-new-authority",
            causal: [
                "existingHousehold": membership.joinedEventID.sequence.rawValue,
                "mortalityPending": pending.pendingEventID.sequence.rawValue,
            ]
        )
    }

    var session = gateFB11Session(simulationID)
    _ = try! session.createSingletonHousehold(
        for: gateFB11TerminalID, residenceAnchor: gateFB11NewHome,
        reason: .formedHousehold
    )
    let membership = session.durableState().householdState!
        .membershipPeriods.first {
            $0.agentID == gateFB11TerminalID && $0.leftTick == nil
        }!
    let migration = try! session.beginSettlementMigration(
        agentID: gateFB11TerminalID,
        destinationSettlementID: gateFB11EastID,
        verifiedRoute: gateFB11Route(
            from: try! session.state(for: gateFB11TerminalID).position
        )
    )
    for _ in 0..<8 where !session.pendingMortalityTransitions().contains(
        where: { $0.agentID == gateFB11TerminalID }
    ) {
        _ = try! session.advanceTick()
    }
    let pending = session.pendingMortalityTransitions().first {
        $0.agentID == gateFB11TerminalID
    }!
    precondition(
        membership.joinedEventID.sequence < migration.startedEventID.sequence
            && migration.startedEventID.sequence < pending.pendingEventID.sequence
    )
    return GateFE12A7Seed(
        session: session, scenario: "authority-before-pending",
        causal: [
            "householdEstablished": membership.joinedEventID.sequence.rawValue,
            "migrationStarted": migration.startedEventID.sequence.rawValue,
            "mortalityPending": pending.pendingEventID.sequence.rawValue,
        ]
    )
}

func runPebbleAgentsGateFBlocker11Smoke() {
    section("Gate F Blocker 11 terminal mortality household admission")
    if gateFB11FreshProcessIfRequested() { return }

    var exact = gateFB11StagePending("gate-f-b11-exact-evaluation-11")
    let pending = exact.pendingMortalityTransitions().first {
        $0.agentID == gateFB11TerminalID
    }!
    let beforeBytes = try! exact.durableStateBytes()
    let beforeCheckpoint = try! AgentCheckpointCodec.encode(
        try! exact.makeCheckpoint()
    )
    let beforeOrdinals = gateFB11Ordinals(exact)
    let beforeAuthority = gateFB11Authority(exact)
    let singletonRefused = gateFB11PendingRefusal {
        _ = try exact.createSingletonHousehold(
            for: gateFB11TerminalID, residenceAnchor: gateFB11NewHome,
            reason: .formedHousehold
        )
    }
    let afterBytes = try! exact.durableStateBytes()
    let afterCheckpoint = try! AgentCheckpointCodec.encode(
        try! exact.makeCheckpoint()
    )
    let afterOrdinals = gateFB11Ordinals(exact)
    let afterAuthority = gateFB11Authority(exact)
    let refusedEvents = gateFB11HouseholdEvents(
        exact, after: pending.pendingEventID.sequence.rawValue
    )

    check("B11 exact fixture reaches authoritative pending e58",
          pending.pendingEventID.sequence.rawValue == 58
            && beforeAuthority.health == 0)
    check("B11 exact singleton acquisition refuses",
          singletonRefused)
    check("B11 exact singleton refusal publishes no household event",
          refusedEvents == GateFB11HouseholdEvents(
            created: 0, ended: 0, started: 0, dissolved: 0
          ))
    check("B11 exact singleton refusal conserves household identity and periods",
          beforeOrdinals.household == 2 && afterOrdinals == beforeOrdinals)
    check("B11 exact singleton refusal preserves current household and home",
          beforeAuthority.currentHousehold == "household_1"
            && afterAuthority == beforeAuthority
            && afterAuthority.home == AgentPosition(x: 4, y: 64, z: 0))
    check("B11 exact singleton refusal is durable and checkpoint byte-atomic",
          afterBytes == beforeBytes && afterCheckpoint == beforeCheckpoint)
    check("B11 exact singleton refusal preserves navigation",
          beforeAuthority.navigation == afterAuthority.navigation)
    check("B11 exact singleton refusal preserves population migration fidelity",
          afterAuthority.residentCount == 1
            && afterAuthority.inTransitCount == 0
            && afterAuthority.fidelityOwnerCount == 1
            && afterAuthority.activeMigrationCount == 0)
    check("B11 exact singleton refusal preserves Family care and Material Rights",
          afterAuthority.unionCount == beforeAuthority.unionCount
            && afterAuthority.familyHouseCount == beforeAuthority.familyHouseCount
            && afterAuthority.caregiverCount == beforeAuthority.caregiverCount
            && afterAuthority.guardianCount == beforeAuthority.guardianCount
            && afterAuthority.materialRecordCount == beforeAuthority.materialRecordCount)
    check("B11 exact singleton refusal preserves pending Mortality",
          afterAuthority.pendingSequence == 58
            && afterAuthority.deathCount == 0 && afterAuthority.estateCount == 0)

    let birthReasonRefused = gateFB11PendingRefusal {
        _ = try exact.createSingletonHousehold(
            for: gateFB11TerminalID, residenceAnchor: gateFB11NewHome,
            reason: .birth
        )
    }
    let migrationReasonRefused = gateFB11PendingRefusal {
        _ = try exact.createSingletonHousehold(
            for: gateFB11TerminalID, residenceAnchor: gateFB11NewHome,
            reason: .migrationAdmission
        )
    }
    check("B11 existing terminal actor cannot bypass guard by reason",
          birthReasonRefused && migrationReasonRefused
            && (try! exact.durableStateBytes()) == beforeBytes)

    var move = gateFB11StagePending("gate-f-b11-move-existing")
    let moveBeforeBytes = try! move.durableStateBytes()
    let moveBeforeCheckpoint = try! AgentCheckpointCodec.encode(
        try! move.makeCheckpoint()
    )
    let moveBefore = gateFB11Authority(move)
    let target = try! move.currentMembership(
        of: AgentID(rawValue: "agent_0")!
    )!.householdID
    let moveRefused = gateFB11PendingRefusal {
        try move.moveMembers(memberIDs: [gateFB11TerminalID], to: target)
    }
    check("B11 pending actor move to existing household refuses",
          moveRefused)
    check("B11 move refusal is fully byte-atomic",
          (try! move.durableStateBytes()) == moveBeforeBytes
            && (try! AgentCheckpointCodec.encode(try! move.makeCheckpoint()))
                == moveBeforeCheckpoint
            && gateFB11Authority(move) == moveBefore)

    var multi = gateFB11StagePending("gate-f-b11-multi-member")
    let multiBeforeBytes = try! multi.durableStateBytes()
    let healthyMember = AgentID(rawValue: "agent_0")!
    let multiRefused = gateFB11PendingRefusal {
        _ = try multi.formHousehold(
            memberIDs: [healthyMember, gateFB11TerminalID],
            residenceAnchor: gateFB11NewHome
        )
    }
    check("B11 terminal member refuses whole multi-member formation",
          multiRefused)
    check("B11 multi-member refusal leaves healthy member untouched",
          (try! multi.durableStateBytes()) == multiBeforeBytes
            && gateFB11Ordinals(multi).household == 2)

    var initialization = gateFB11StagePending(
        "gate-f-b11-late-household-initialization", households: false
    )
    let initializationBytes = try! initialization.durableStateBytes()
    let initializationRefused = gateFB11PendingRefusal {
        try initialization.setHouseholdsEnabled(true)
    }
    check("B11 late Household initialization refuses existing pending actor",
          initializationRefused
            && !initialization.householdsEnabled
            && (try! initialization.durableStateBytes()) == initializationBytes)

    var healthy = gateFB11Session(
        "gate-f-b11-healthy", terminalAgentOrdinal: nil
    )
    let healthyOrdinal = gateFB11Ordinals(healthy).household
    let healthyHousehold = try! healthy.createSingletonHousehold(
        for: gateFB11TerminalID, residenceAnchor: gateFB11NewHome,
        reason: .formedHousehold
    )
    check("B11 healthy singleton acquisition accepts normally",
          healthyHousehold.householdID.rawValue == "household_2"
            && gateFB11Authority(healthy).currentHousehold == "household_2"
            && gateFB11Ordinals(healthy).household == healthyOrdinal + 1)

    var inverse = gateFB11Session("gate-f-b11-inverse-order")
    let inverseHousehold = try! inverse.createSingletonHousehold(
        for: gateFB11TerminalID, residenceAnchor: gateFB11NewHome,
        reason: .formedHousehold
    )
    let inverseJoined = gateFB11Authority(inverse).joinedSequence!
    for _ in 0..<8 where !inverse.pendingMortalityTransitions().contains(
        where: { $0.agentID == gateFB11TerminalID }
    ) {
        _ = try! inverse.advanceTick()
    }
    let inversePending = inverse.pendingMortalityTransitions().first {
        $0.agentID == gateFB11TerminalID
    }!
    gateFB11ResolveEmptyCustody(&inverse, suffix: "focused-inverse")
    _ = try! inverse.finalizePendingMortality(for: gateFB11TerminalID)
    let inverseEvents = inverse.causalLedgerSnapshot().events
    let inverseEnded = inverseEvents.first {
        $0.kind == .householdMembershipEnded
            && $0.subjectID == gateFB11TerminalID
            && $0.sequence > inversePending.pendingEventID.sequence
    }!
    let inverseDeath = inverseEvents.first {
        $0.kind == .agentDeathFinalized && $0.subjectID == gateFB11TerminalID
    }!
    let inverseFinal = gateFB11Authority(inverse)
    check("B11 Household-before-Mortality remains supported",
          inverseHousehold.householdID.rawValue == "household_2"
            && inverseJoined < inversePending.pendingEventID.sequence.rawValue)
    check("B11 terminal cleanup closes Household before death",
          inverseEnded.sequence < inverseDeath.sequence)
    check("B11 inverse finalizes death and Estate exactly once",
          inverseFinal.deathCount == 1 && inverseFinal.estateCount == 1)
    check("B11 inverse leaves no dead current authority",
          !inverseFinal.activeAgent && !inverseFinal.populationMember
            && inverseFinal.currentHousehold == nil
            && inverseFinal.residentCount == 0
            && inverseFinal.inTransitCount == 0
            && inverseFinal.fidelityOwnerCount == 0)

    let finalizedBytes = try! inverse.durableStateBytes()
    var finalizedRefused = false
    do {
        _ = try inverse.createSingletonHousehold(
            for: gateFB11TerminalID, residenceAnchor: gateFB11NewHome,
            reason: .formedHousehold
        )
    } catch { finalizedRefused = true }
    check("B11 finalized dead actor cannot acquire Household authority",
          finalizedRefused && (try! inverse.durableStateBytes()) == finalizedBytes)

    var previousTick = gateFB11StagePending("gate-f-b11-previous-tick")
    let previousTickValue = previousTick.tick
    let previousBytes = try! previousTick.durableStateBytes()
    let tickRefused = gateFB11PendingRefusal {
        _ = try previousTick.advanceTick()
    }
    let previousHouseholdRefused = gateFB11PendingRefusal {
        _ = try previousTick.createSingletonHousehold(
            for: gateFB11TerminalID, residenceAnchor: gateFB11NewHome,
            reason: .formedHousehold
        )
    }
    check("B11 unresolved pending cannot cross a tick boundary",
          tickRefused && previousTick.tick == previousTickValue)
    check("B11 Household remains refused after tick-boundary refusal",
          previousHouseholdRefused
            && (try! previousTick.durableStateBytes()) == previousBytes)

    let migrationBytes = try! exact.durableStateBytes()
    let migrationRefused = gateFB11PendingRefusal {
        _ = try exact.beginSettlementMigration(
            agentID: gateFB11TerminalID,
            destinationSettlementID: gateFB11EastID,
            verifiedRoute: gateFB11Route(from: AgentPosition(x: 4, y: 64, z: 0))
        )
    }
    check("B11 preserves B10 pending-before-migration refusal",
          migrationRefused && (try! exact.durableStateBytes()) == migrationBytes)

    let restored = try! AgentSimulationSession.restoring(exact.makeCheckpoint())
    check("B11 schema 35 restore preserves exact refusal",
          (try! exact.makeCheckpoint()).schemaVersion == 35
            && (try! restored.durableStateBytes()) == beforeBytes)
    check("B11 Observer 13 remains read-only",
          gateFB11Observer(exact) == (13, 0))

    print(
        "GATE_F_BLOCKER_11_CAUSAL tick=\(exact.tick) "
            + "pendingKind=mortalityMaterialExitPending "
            + "pendingSequence=\(pending.pendingEventID.sequence.rawValue) "
            + "householdPublication=0 accepted=0"
    )
    print(
        "GATE_F_BLOCKER_11_IDENTITY agent=\(gateFB11TerminalID.rawValue) "
            + "refusedHousehold=household_2 consumed=0 "
            + "nextHouseholdBefore=\(beforeOrdinals.household) "
            + "nextHouseholdAfter=\(afterOrdinals.household) "
            + "membershipPeriods=\(afterOrdinals.householdPeriods) "
            + "nextPopulation=\(afterOrdinals.population) "
            + "nextFidelity=\(afterOrdinals.fidelity) "
            + "nextMigration=\(afterOrdinals.migration)"
    )
    print(
        "GATE_F_BLOCKER_11_CONTROL householdStart=\(inverseJoined) "
            + "pending=\(inversePending.pendingEventID.sequence.rawValue) "
            + "householdEnded=\(inverseEnded.sequence.rawValue) "
            + "deathFinal=\(inverseDeath.sequence.rawValue)"
    )
    print(
        "GATE_F_BLOCKER_11_PASS checkpointSchema=35 observerSchema=13 "
            + "terminalPendingHousehold=refused ordinalConsumed=0 "
            + "durableByteAtomic=1 householdBeforeMortality=supported "
            + "restartDuplicateDeaths=0 restartDuplicateEstates=0"
    )
}
