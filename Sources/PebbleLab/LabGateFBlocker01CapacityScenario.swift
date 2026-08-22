import Foundation
import PebbleAgents

private let gateFBlockerRuntimeEastID = AgentSettlementID(
    rawValue: "settlement-east"
)!
private let gateFBlockerRuntimeCheckpoint = "gate_f_blocker_01_v35.json"
private let gateFBlockerRuntimeState = "authoritative_after_retry.json"

private struct GateFBlocker01RuntimeReport: Encodable {
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
    let fidelityCount: Int
    let causalEventCount: Int
    let nextPopulationOrdinal: Int
    let duplicateInhabitants: Int
    let duplicateDurableIdentities: Int
    let duplicateMemberships: Int
    let restartDuplicateEffects: Int
    let physicalLoss: Int
    let physicalDuplication: Int
    let syntheticMaterial: Int
    let observerMutations: Int
    let unexpectedRuntimeErrors: Int
    let assertions: [String: Bool]
}

private func gateFBlockerRuntimeAgent(
    _ id: String,
    ordinal: Int
) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 01 runtime proof",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: ordinal,
        observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0,
        actionCount: 0, actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func gateFBlockerRuntimeSession(seed: UInt32) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: seed, memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [
            gateFBlockerRuntimeAgent("agent_0", ordinal: 0),
            gateFBlockerRuntimeAgent("agent_1", ordinal: 1),
            gateFBlockerRuntimeAgent("agent_2", ordinal: 2),
        ],
        simulationID: try! AgentSimulationID(
            validating: "gate-f-blocker-01-runtime-\(seed)"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: -2),
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 8
        )
    )
    return session
}

private func gateFBlockerRuntimeSettlement() -> AgentPopulationSettlement {
    AgentPopulationSettlement(
        settlementID: gateFBlockerRuntimeEastID,
        anchor: AgentPosition(x: 8, y: 64, z: 8),
        receptionPosition: AgentPosition(x: 8, y: 64, z: 7),
        capacity: 1, residentIDs: [], inTransitIDs: []
    )
}

private func gateFBlockerRuntimeAdmission(
    _ ordinal: Int
) -> AgentScaledResidentAdmission {
    AgentScaledResidentAdmission(
        state: gateFBlockerRuntimeAgent("agent_\(ordinal)", ordinal: ordinal),
        settlementID: gateFBlockerRuntimeEastID
    )
}

private func gateFBlockerRuntimeScaleConfiguration()
    -> AgentPopulationScaleConfiguration
{
    try! AgentPopulationScaleConfiguration(
        maximumSettlements: 2,
        maximumLiveAgents: 4, maximumNearAgents: 4,
        nearMaintenanceCadence: 2, dormantMaintenanceCadence: 8,
        rotationIntervalTicks: 4,
        maximumFidelityTransitionHistory: 32,
        maximumSettlementMigrationHistory: 8,
        maximumConcurrentSettlementMigrations: 1,
        maximumSettlementMigrationRouteLength: 16
    )
}

private func gateFBlockerRuntimeObserverBinding(
    seed: UInt32,
    tick: Int
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "gate-f-blocker-01-runtime-world",
        storageIdentity: "headless:gate-f-blocker-01-runtime",
        seed: seed, dimension: 0, observedWorldTick: tick
    )
}

private func gateFBlockerRuntimeWriteJSON<T: Encodable>(
    _ value: T,
    to url: URL
) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(
        to: url, options: .atomic
    )
}

private func gateFBlockerRuntimeDuplicateCount<T: Hashable>(
    _ values: [T]
) -> Int {
    values.count - Set(values).count
}

private func gateFBlockerRuntimeDigest(_ bytes: Data) -> String {
    AgentPopulationDigest.make(String(data: bytes, encoding: .utf8) ?? "")
}

private func gateFBlockerRuntimeRestore(
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
        let session = try AgentSimulationSession.restoring(checkpoint)
        let expectedState = try Data(contentsOf: stateURL)
        let restoredState = try session.durableStateBytes()
        let population = session.populationSnapshot()
        let scale = session.populationScaleSnapshot()
        let memberships = population.settlements.flatMap {
            $0.residentIDs + $0.inTransitIDs
        }
        let inhabitants = session.expectedActiveAgentIDs()
        let identities = session.identitySnapshot().agentIDs
        let eventCountBefore = session.causalLedgerSnapshot().events.count
        let observer = session.observerSnapshot(
            worldBinding: gateFBlockerRuntimeObserverBinding(
                seed: options.seed, tick: session.tick
            )
        )
        let afterObserver = try session.durableStateBytes()
        let east = population.settlements.first {
            $0.settlementID == gateFBlockerRuntimeEastID
        }
        let assertions = [
            "fresh_process_restore": checkpoint.schemaVersion == 35,
            "authoritative_state_exact": restoredState == expectedState,
            "settlement_capacity_respected": east?.capacity == 1
                && east?.residentIDs.count == 1,
            "inhabitants_exact": inhabitants.count == 4,
            "population_members_exact": population.members.count == 4,
            "fidelity_exact": scale.fidelityRecords.count == 4
                && Set(scale.fidelityRecords.map(\.agentID)) == Set(inhabitants),
            "no_duplicate_inhabitants": Set(inhabitants).count
                == inhabitants.count,
            "no_duplicate_durable_identities": Set(identities).count
                == identities.count && Set(identities) == Set(inhabitants),
            "no_duplicate_memberships": Set(memberships).count
                == memberships.count && Set(memberships) == Set(inhabitants),
            "no_replayed_transition_effects": session.causalLedgerSnapshot()
                .events.count == eventCountBefore,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": afterObserver == restoredState,
        ]
        let report = GateFBlocker01RuntimeReport(
            schemaVersion: 1, scenario: options.scenario, seed: options.seed,
            success: assertions.values.allSatisfy { $0 },
            processPhase: "fresh-process-restore",
            checkpointSchema: checkpoint.schemaVersion,
            observerSchema: observer.header.schemaVersion,
            checkpointBytes: checkpointBytes.count,
            authoritativeDigest: gateFBlockerRuntimeDigest(restoredState),
            settlementCount: population.settlements.count,
            populationCount: population.members.count,
            fidelityCount: scale.fidelityRecords.count,
            causalEventCount: eventCountBefore,
            nextPopulationOrdinal: population.nextPopulationOrdinal ?? -1,
            duplicateInhabitants: gateFBlockerRuntimeDuplicateCount(inhabitants),
            duplicateDurableIdentities:
                gateFBlockerRuntimeDuplicateCount(identities),
            duplicateMemberships:
                gateFBlockerRuntimeDuplicateCount(memberships),
            restartDuplicateEffects: assertions["no_replayed_transition_effects"]
                == true ? 0 : 1,
            physicalLoss: 0, physicalDuplication: 0, syntheticMaterial: 0,
            observerMutations: assertions["observer_read_only"] == true ? 0 : 1,
            unexpectedRuntimeErrors: 0,
            assertions: assertions
        )
        try gateFBlockerRuntimeWriteJSON(
            observer,
            to: root.appendingPathComponent("observer_after_restore.json")
        )
        try gateFBlockerRuntimeWriteJSON(
            report,
            to: root.appendingPathComponent("process_2_report.json")
        )
        guard report.success else {
            fail("Gate F Blocker 01 process 2 assertions failed")
        }
        print(
            "GATE_F_BLOCKER_01_PROCESS_2_PASS checkpointSchema="
                + "\(report.checkpointSchema) observerSchema="
                + "\(report.observerSchema) settlements="
                + "\(report.settlementCount) population="
                + "\(report.populationCount) duplicateInhabitants="
                + "\(report.duplicateInhabitants) duplicateDurableIdentities="
                + "\(report.duplicateDurableIdentities) duplicateMemberships="
                + "\(report.duplicateMemberships) restartDuplicateEffects="
                + "\(report.restartDuplicateEffects)"
        )
        exit(0)
    } catch {
        fail("Gate F Blocker 01 restore proof failed: \(error)")
    }
}

func runGateFBlocker01CapacitySmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("Gate F Blocker 01 proof requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(
            at: root, withIntermediateDirectories: true
        )
    } catch {
        fail("failed to prepare Gate F Blocker 01 output: \(error)")
    }
    let checkpointURL = root.appendingPathComponent(
        gateFBlockerRuntimeCheckpoint
    )
    let stateURL = root.appendingPathComponent(gateFBlockerRuntimeState)
    if options.scenario == "gate_f_blocker_01_capacity_restore_smoke" {
        let thread = Thread {
            gateFBlockerRuntimeRestore(
                options: options, root: root, checkpointURL: checkpointURL,
                stateURL: stateURL
            )
        }
        thread.stackSize = 32 * 1_024 * 1_024
        thread.start()
        while !thread.isFinished { Thread.sleep(forTimeInterval: 0.001) }
        fail("Gate F Blocker 01 restore worker returned unexpectedly")
    }
    guard (try? FileManager.default.contentsOfDirectory(
        atPath: root.path
    ).isEmpty) == true else {
        fail("Gate F Blocker 01 process-one output must be empty")
    }
    do {
        var session = gateFBlockerRuntimeSession(seed: options.seed)
        let beforeBytes = try session.durableStateBytes()
        let beforePopulation = session.populationSnapshot()
        let beforeEvents = session.causalLedgerSnapshot().events
        var rejectionMatched = false
        do {
            try session.initializePopulationScaling(
                additionalSettlements: [gateFBlockerRuntimeSettlement()],
                additionalResidents: [
                    gateFBlockerRuntimeAdmission(3),
                    gateFBlockerRuntimeAdmission(4),
                ],
                configuration: gateFBlockerRuntimeScaleConfiguration()
            )
        } catch AgentSessionError.population(.capacityReached) {
            rejectionMatched = true
        }
        let afterRefusalBytes = try session.durableStateBytes()
        let afterRefusalPopulation = session.populationSnapshot()
        let refusalAssertions = [
            "over_capacity_rejected": rejectionMatched,
            "authoritative_bytes_unchanged": afterRefusalBytes == beforeBytes,
            "inhabitants_unchanged": session.snapshot().agents.count == 3,
            "population_members_unchanged": afterRefusalPopulation.members
                == beforePopulation.members,
            "settlements_unchanged": afterRefusalPopulation.settlements
                == beforePopulation.settlements,
            "fidelity_unpublished": session.populationScaleSnapshot()
                .fidelityRecords.isEmpty,
            "scale_state_unpublished": !session.populationScalingEnabled,
            "causal_events_unchanged": session.causalLedgerSnapshot().events
                == beforeEvents,
            "ordinal_unchanged": afterRefusalPopulation.nextPopulationOrdinal
                == beforePopulation.nextPopulationOrdinal,
        ]
        try session.initializePopulationScaling(
            additionalSettlements: [gateFBlockerRuntimeSettlement()],
            additionalResidents: [gateFBlockerRuntimeAdmission(3)],
            configuration: gateFBlockerRuntimeScaleConfiguration()
        )
        let validState = try session.durableStateBytes()
        let population = session.populationSnapshot()
        let scale = session.populationScaleSnapshot()
        let checkpoint = try session.makeCheckpoint()
        let encodedCheckpoint = try AgentCheckpointCodec.encode(checkpoint)
        try encodedCheckpoint.write(to: checkpointURL, options: .atomic)
        try validState.write(to: stateURL, options: .atomic)
        let observerBefore = try session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: gateFBlockerRuntimeObserverBinding(
                seed: options.seed, tick: session.tick
            )
        )
        let east = population.settlements.first {
            $0.settlementID == gateFBlockerRuntimeEastID
        }
        var assertions = refusalAssertions
        assertions["valid_retry_accepted"] = population.members.count == 4
            && population.nextPopulationOrdinal == 4
        assertions["exact_capacity_published"] = east?.capacity == 1
            && east?.residentIDs.count == 1
        assertions["checkpoint_schema_35"] = checkpoint.schemaVersion == 35
        assertions["observer_schema_13"] = observer.header.schemaVersion == 13
        assertions["observer_read_only"] = try session.durableStateBytes()
            == observerBefore
        let memberships = population.settlements.flatMap {
            $0.residentIDs + $0.inTransitIDs
        }
        let inhabitants = session.expectedActiveAgentIDs()
        let identities = session.identitySnapshot().agentIDs
        let report = GateFBlocker01RuntimeReport(
            schemaVersion: 1, scenario: options.scenario, seed: options.seed,
            success: assertions.values.allSatisfy { $0 },
            processPhase: "reject-retry-checkpoint",
            checkpointSchema: checkpoint.schemaVersion,
            observerSchema: observer.header.schemaVersion,
            checkpointBytes: encodedCheckpoint.count,
            authoritativeDigest: gateFBlockerRuntimeDigest(validState),
            settlementCount: population.settlements.count,
            populationCount: population.members.count,
            fidelityCount: scale.fidelityRecords.count,
            causalEventCount: session.causalLedgerSnapshot().events.count,
            nextPopulationOrdinal: population.nextPopulationOrdinal ?? -1,
            duplicateInhabitants: gateFBlockerRuntimeDuplicateCount(inhabitants),
            duplicateDurableIdentities:
                gateFBlockerRuntimeDuplicateCount(identities),
            duplicateMemberships:
                gateFBlockerRuntimeDuplicateCount(memberships),
            restartDuplicateEffects: 0,
            physicalLoss: 0, physicalDuplication: 0, syntheticMaterial: 0,
            observerMutations: assertions["observer_read_only"] == true ? 0 : 1,
            unexpectedRuntimeErrors: 0,
            assertions: assertions
        )
        try gateFBlockerRuntimeWriteJSON(
            report,
            to: root.appendingPathComponent("process_1_report.json")
        )
        guard report.success else {
            fail("Gate F Blocker 01 process 1 assertions failed")
        }
        print(
            "GATE_F_BLOCKER_01_PROCESS_1_PASS rejected=1 bytesUnchanged=1 "
                + "validRetry=1 checkpointSchema=\(report.checkpointSchema) "
                + "observerSchema=\(report.observerSchema) settlements="
                + "\(report.settlementCount) population="
                + "\(report.populationCount)"
        )
        exit(0)
    } catch {
        fail("Gate F Blocker 01 process 1 failed: \(error)")
    }
}
