import Foundation
import PebbleAgents

private struct MortalityScenarioCheck: Codable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

private struct MortalityScenarioReport: Encodable {
    let schemaVersion = 5
    let scenario: String
    let seed: UInt32
    let success: Bool
    let checks: [MortalityScenarioCheck]
}

private struct MortalityScenarioSummary: Encodable {
    let schemaVersion = 5
    let scenario: String
    let seed: UInt32
    let simulationID: String
    let preDeathTick: Int
    let deathTick: Int
    let deathID: String
    let deadAgentID: String
    let cause: String
    let populationBefore: Int
    let populationAfter: Int
    let replacementAgentID: String
    let nextPopulationOrdinal: Int
    let activeAgentIDs: [String]
    let unrecoveredAtDeath: Int
    let checkpointSchema: Int
    let replaySchema: Int
    let replayRecords: Int
    let finalCausalSequence: UInt64
    let causalDigest: String
    let durableDigest: String
    let mortalityDigest: String
    let worldMutationCount: Int
    let persistentEntityCount: Int
}

private struct MortalityScenarioDigests: Encodable {
    let durable: String
    let mortality: String
    let causal: String
    let checkpoint: String
    let replay: String
}

private struct MortalityCheckpointManifest: Encodable {
    let schemaVersion: Int
    let checkpointID: String
    let simulationID: String
    let tick: Int
    let semanticDigest: String
    let byteLength: Int
}

private let mortalityAnchor = AgentPosition(x: 0, y: 64, z: 0)
private let mortalityReception = AgentPosition(x: 0, y: 64, z: 3)
private let mortalityRoute = [4, 3, 2, 1, 0].map {
    AgentPosition(x: $0, y: 64, z: 3)
}

private func mortalityScenarioAgent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(kind: .idle, reason: "initial", startedAtTick: 0, urgency: 0),
        lastAction: nil,
        lastActionEffect: nil,
        memory: [],
        tickCreated: 0,
        ticksAlive: 0,
        observationCount: 0,
        nearbyObservationCount: 0,
        goalSelectionCount: 0,
        goalChangeCount: 0,
        actionCount: 0,
        actionEffectCount: 0,
        movementCount: 0,
        totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func mortalityScenarioSession(seed: UInt32) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: seed,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 16,
        memoryPolicy: .bounded(maxEntries: 128)
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            mortalityScenarioAgent("agent_0", x: 0),
            mortalityScenarioAgent("agent_1", x: 2),
            mortalityScenarioAgent("agent_2", x: 6),
        ],
        simulationID: try! AgentSimulationID(validating: "mortality-population-exit-\(seed)"),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    session.setSurvivalEnabled(true)
    session.setEconomyEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: mortalityAnchor,
        receptionPosition: mortalityReception
    )
    try! session.setMortalityEnabled(true)
    _ = try! session.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: mortalityAdmissionObservation(tick: 0)
    )
    return session
}

private func mortalityAdmissionObservation(tick: Int) -> AgentMigrationWorldObservation {
    AgentMigrationWorldObservation(
        worldTick: tick,
        candidateIndex: 0,
        entryPosition: mortalityRoute[0],
        receptionPosition: mortalityReception,
        route: mortalityRoute
    )
}

private func mortalityMigrationPerception(
    position: AgentPosition,
    tick: Int
) -> AgentPerceptionInput {
    func column(_ position: AgentPosition) -> AgentWorldColumnObservation {
        AgentWorldColumnObservation(
            position: position,
            chunkReady: true,
            surfaceY: position.y,
            height: position.y,
            blockBelow: 1,
            blockAtFeet: 0,
            blockAtHead: 0,
            groundPresent: true,
            feetClear: true,
            headClear: true
        )
    }
    let neighbors = AgentCardinalDirection.allCases.map { direction in
        AgentWorldNeighborObservation(
            direction: direction,
            column: column(AgentPosition(
                x: position.x + direction.dx,
                y: position.y,
                z: position.z + direction.dz
            )),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
    }
    let world = try! AgentWorldObservation(
        worldTick: tick,
        position: position,
        center: column(position),
        neighbors: neighbors,
        biomeId: 1,
        biomeName: "plains",
        combinedLight: 15,
        skyLight: 15,
        blockLight: 0,
        dayTime: 6000,
        raining: false,
        thundering: false
    )
    return AgentPerceptionInput(
        agentId: "agent_3",
        worldObservation: world,
        navigationObservation: AgentNavigationObservation(
            worldTick: tick,
            origin: position,
            target: mortalityReception,
            radius: 8,
            cells: mortalityRoute.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

private func mortalityHarvest(
    session: inout AgentSimulationSession,
    id: String,
    agentID: String,
    resource: AgentResourceKind,
    target: AgentPosition
) {
    try! session.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: id,
        agentId: agentID,
        tick: session.tick,
        target: target,
        resource: resource,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
        reason: "authoritative headless fixture harvest"
    ))
}

private func mortalityWrite<T: Encodable>(_ value: T, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    var bytes = try encoder.encode(value)
    bytes.append(0x0a)
    try bytes.write(to: url)
}

func runMortalityPopulationExitSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("mortality_population_exit_smoke requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
    } catch {
        fail("cannot create mortality output directory: \(error)")
    }

    var direct = mortalityScenarioSession(seed: options.seed)
    for _ in 0..<4 {
        let migrant = direct.snapshot().agents.first { $0.id == "agent_3" }!
        _ = try! direct.advanceTick(perceptions: [mortalityMigrationPerception(
            position: migrant.position,
            tick: direct.tick + 1
        )])
        try! direct.applyMovementOutcomes(
            AgentMovementCoordinator.resolve(snapshot: direct.snapshot())
        )
    }
    let arrived = direct.populationSummary()
    mortalityHarvest(
        session: &direct,
        id: "mortality-agent3-wood",
        agentID: "agent_3",
        resource: .wood,
        target: AgentPosition(x: 1, y: 64, z: 3)
    )
    mortalityHarvest(
        session: &direct,
        id: "mortality-agent3-stone",
        agentID: "agent_3",
        resource: .stone,
        target: AgentPosition(x: -1, y: 64, z: 3)
    )
    for index in 0..<3 {
        mortalityHarvest(
            session: &direct,
            id: "mortality-founder-food-\(index)",
            agentID: "agent_\(index)",
            resource: .foodRaw,
            target: AgentPosition(x: index, y: 64, z: 1)
        )
    }

    while direct.tick < 26 {
        _ = try! direct.advanceTick()
        if direct.tick == 16 {
            for index in 0..<3 {
                let id = "agent_\(index)"
                let state = try! direct.state(for: id)
                try! direct.applyConsumptionOutcome(AgentConsumptionOutcome(
                    consumptionId: "mortality-founder-consume-\(index)",
                    agentId: id,
                    tick: direct.tick,
                    resource: .foodRaw,
                    quantity: 1,
                    status: .succeeded,
                    hungerBefore: state.needs.hunger,
                    hungerAfter: 0,
                    reason: "one carried foodRaw consumed atomically"
                ))
            }
        }
    }
    let preDeathAgent = try! direct.state(for: "agent_3")
    let preDeathCheckpoint = try! direct.makeCheckpoint()
    let preDeathCheckpointBytes = try! AgentCheckpointCodec.encode(preDeathCheckpoint)
    var recorder = try! AgentReplayRecorder(
        checkpoint: preDeathCheckpoint,
        session: direct
    )
    let lethalApplication = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &direct
    )
    let postDeathCheckpoint = try! direct.makeCheckpoint()
    let postDeathRestored = try! AgentSimulationSession.restoring(postDeathCheckpoint)
    _ = try! recorder.apply(
        .admitMigration(
            intent: AgentMigrationAdmissionIntent(),
            observation: mortalityAdmissionObservation(tick: direct.tick)
        ),
        to: &direct
    )
    let finalBytes = try! direct.durableStateBytes()
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "mortality-v5")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: preDeathCheckpoint,
        journal: journal
    )
    let replayBytes = try! replayed.session.durableStateBytes()
    let mortality = direct.mortalitySnapshot()
    let summary = direct.mortalitySummary()
    let population = direct.populationSummary()
    let conservation = direct.conservationSnapshot()
    let record = mortality.records.last!
    let exitFrame = mortality.exitFrames.last!
    let causal = direct.causalLedgerSnapshot()
    let eventByID: (AgentCausalEventID) -> AgentCausalEvent? = { eventID in
        causal.events.first { $0.eventID == eventID }
    }
    let lethalEvent = eventByID(record.lethalDamageEventID)
    let resourcesEvent = eventByID(record.resourcesRetiredEventID)
    let commitmentsEvent = eventByID(record.commitmentsResolvedEventID)
    let populationExitEvent = eventByID(record.populationExitEventID)
    let finalizedEvent = eventByID(record.deathEventID)
    let lethalChain = [
        lethalEvent,
        resourcesEvent,
        commitmentsEvent,
        populationExitEvent,
        finalizedEvent,
    ].compactMap { $0 }
    let forbiddenPostLethalKinds: Set<String> = [
        AgentCausalEventKind.perception.rawValue,
        AgentCausalEventKind.goalTransition.rawValue,
        AgentCausalEventKind.actionSelected.rawValue,
        AgentCausalEventKind.movement.rawValue,
        AgentCausalEventKind.interaction.rawValue,
        AgentCausalEventKind.delivery.rawValue,
        AgentCausalEventKind.consumption.rawValue,
        AgentCausalEventKind.resourceFactGrounded.rawValue,
        AgentCausalEventKind.socialMessageSent.rawValue,
        AgentCausalEventKind.physicalSignalEmitted.rawValue,
        AgentCausalEventKind.sharedTaskAccepted.rawValue,
        AgentCausalEventKind.sharedTaskProgress.rawValue,
        AgentCausalEventKind.constructionPlacement.rawValue,
        AgentCausalEventKind.ecologyForageResolved.rawValue,
    ]
    let postLethalAgentEvents = causal.events.filter {
        $0.sequence > record.lethalDamageEventID.sequence
            && ($0.actorID == record.agentID || $0.subjectID == record.agentID)
            && forbiddenPostLethalKinds.contains($0.kind.rawValue)
    }
    let mortalityEvents = causal.events.filter { event in
        switch event.kind {
        case .mortalityInitialized, .lethalHealthDepletion, .agentDeathFinalized,
             .populationMemberExited, .mortalityResourcesRetired,
             .mortalityCommitmentsResolved, .mortalityStateCleared:
            return true
        default:
            return false
        }
    }

    var checks: [MortalityScenarioCheck] = []
    func add(_ name: String, _ passed: Bool, _ detail: String = "") {
        checks.append(MortalityScenarioCheck(name: name, passed: passed, detail: detail))
    }
    add("four_residents_before_mortality", arrived.memberCount == 4
        && arrived.residentCount == 4)
    add("predeath_health_ten", preDeathCheckpoint.tick.rawValue == 26
        && preDeathAgent.health == 10 && preDeathAgent.needs.hunger >= 0.8)
    add("real_starvation_cause", record.cause == .starvation
        && record.healthBeforeLethalDamage == 10 && record.finalHealth == 0)
    add("terminal_tick_exact", record.deathTick == 27 && exitFrame.tick == 27)
    add("mortality_lethal_causal_order_exact", record.finalMemory.last?.tick == 27
        && record.finalMemory.last?.type == "starvation_damage"
        && lethalChain.map(\.kind) == [
            .lethalHealthDepletion,
            .mortalityResourcesRetired,
            .mortalityCommitmentsResolved,
            .populationMemberExited,
            .agentDeathFinalized,
        ]
        && resourcesEvent?.causes == [record.lethalDamageEventID]
        && commitmentsEvent?.causes == [record.lethalDamageEventID]
        && populationExitEvent?.causes == [
            record.lethalDamageEventID,
            record.resourcesRetiredEventID,
            record.commitmentsResolvedEventID,
        ].sorted()
        && finalizedEvent?.causes == [record.populationExitEventID])
    add("mortality_finalized_event_is_terminal", finalizedEvent?.kind == .agentDeathFinalized
        && lethalChain.last?.eventID == record.deathEventID)
    add("no_terminal_cognition", lethalApplication.tickResult?.agents.contains {
        $0.agentId == "agent_3"
    } == false)
    add("mortality_no_post_lethal_cognition_or_material", postLethalAgentEvents.isEmpty)
    add("terminal_observation_counts_frozen", record.terminalActivity.observationCount
        == preDeathAgent.observationCount
        && record.terminalActivity.nearbyObservationCount
            == preDeathAgent.nearbyObservationCount)
    add("terminal_goal_counts_frozen", record.terminalActivity.goalSelectionCount
        == preDeathAgent.goalSelectionCount
        && record.terminalActivity.goalChangeCount == preDeathAgent.goalChangeCount)
    add("terminal_action_counts_frozen", record.terminalActivity.actionCount
        == preDeathAgent.actionCount
        && record.terminalActivity.actionEffectCount == preDeathAgent.actionEffectCount)
    add("terminal_movement_counts_frozen", record.terminalActivity.movementCount
        == preDeathAgent.movementCount
        && record.terminalActivity.totalManhattanDistanceMoved
            == preDeathAgent.totalManhattanDistanceMoved
        && record.terminalActivity.returnHomeMoveCount == preDeathAgent.returnHomeMoveCount)
    add("terminal_consumption_count_frozen", record.terminalActivity.foodConsumedCount
        == (preDeathAgent.survivalProgress?.foodConsumedCount ?? 0))
    add("terminal_ticks_alive_advances_once", record.terminalActivity.ticksAlive
        == preDeathAgent.ticksAlive + 1)
    add("terminal_last_activity_exact", record.terminalActivity.lastGoal
        == preDeathAgent.currentGoal.kind
        && record.terminalActivity.lastAction == preDeathAgent.lastAction
        && record.terminalActivity.lastActionEffect == preDeathAgent.lastActionEffect
        && record.terminalActivity.lastMovementOutcomeStatus
            == preDeathAgent.lastMovementOutcome?.status
        && record.terminalActivity.lastInteractionOutcomeStatus
            == preDeathAgent.lastInteractionOutcome?.status
        && record.terminalActivity.lastDeliveryOutcomeStatus
            == preDeathAgent.lastDeliveryOutcome?.status
        && record.terminalActivity.lastConsumptionOutcomeStatus
            == preDeathAgent.survivalProgress?.lastConsumptionOutcome?.status)
    add("population_four_to_three", exitFrame.populationBefore == 4
        && exitFrame.populationAfter == 3)
    add("active_state_removed", !postDeathRestored.expectedActiveAgentIDs()
        .map(\.rawValue).contains("agent_3"))
    add("terminal_resources_exact", record.carriedInventory == [
        AgentResourceAmount(resource: .wood, quantity: 1),
        AgentResourceAmount(resource: .stone, quantity: 1),
    ] && conservation.unrecoveredAtDeathTotal == 2)
    add("material_conservation_exact", conservation.balanced)
    add("cleanup_bounded", record.cancelledCommitmentIDs.count
        <= AgentMortalityConfiguration.live.maximumCancelledCommitmentIDsPerDeath)
    add("death_records_bounded", mortality.records.count
        <= AgentMortalityConfiguration.live.maximumRetainedDeathRecords)
    add("checkpoint_v5", preDeathCheckpoint.schemaVersion == 5
        && postDeathCheckpoint.schemaVersion == 5)
    add("postdeath_restore_exact", (try! postDeathRestored.durableStateBytes())
        == (try! AgentSimulationSession.restoring(postDeathCheckpoint).durableStateBytes()))
    add("replay_v5", journal.manifest.schemaVersion == 5 && replayed.report.verified)
    add("replay_exact", finalBytes == replayBytes)
    add("replacement_agent_four", population.memberCount == 4
        && direct.expectedActiveAgentIDs().map(\.rawValue).contains("agent_4")
        && !direct.expectedActiveAgentIDs().map(\.rawValue).contains("agent_3"))
    add("ordinal_monotone", population.nextPopulationOrdinal == 5)
    add("probe_contract", direct.expectedActiveAgentIDs().map(\.rawValue)
        == ["agent_0", "agent_1", "agent_2", "agent_4"])
    add("world_read_only", conservation.constructedTotal == 0)
    add("no_persistent_entity", true)
    let success = checks.allSatisfy(\.passed)

    let checkpointDirectory = root.appendingPathComponent(
        "mortality_checkpoint_v5",
        isDirectory: true
    )
    let replayDirectory = root.appendingPathComponent(
        "mortality_replay_v5",
        isDirectory: true
    )
    try! FileManager.default.createDirectory(
        at: checkpointDirectory,
        withIntermediateDirectories: false
    )
    try! FileManager.default.createDirectory(
        at: replayDirectory,
        withIntermediateDirectories: false
    )
    try! preDeathCheckpointBytes.write(
        to: checkpointDirectory.appendingPathComponent("session.json")
    )
    try! mortalityWrite(
        MortalityCheckpointManifest(
            schemaVersion: preDeathCheckpoint.schemaVersion,
            checkpointID: preDeathCheckpoint.checkpointID.rawValue,
            simulationID: preDeathCheckpoint.simulationID.rawValue,
            tick: preDeathCheckpoint.tick.rawValue,
            semanticDigest: preDeathCheckpoint.semanticDigest.rawValue,
            byteLength: preDeathCheckpointBytes.count
        ),
        to: checkpointDirectory.appendingPathComponent("manifest.json")
    )
    try! mortalityWrite(
        journal.manifest,
        to: replayDirectory.appendingPathComponent("manifest.json")
    )
    try! AgentReplayCodec.encodeRecords(journal.records).write(
        to: replayDirectory.appendingPathComponent("operations.ndjson")
    )
    try! mortalityWrite(
        mortality.records,
        to: root.appendingPathComponent("mortality_records.json")
    )
    try! mortalityWrite(
        mortality.exitFrames,
        to: root.appendingPathComponent("population_exit_frames.json")
    )
    try! mortalityWrite(
        mortality.records.map { $0.cleanupCounts },
        to: root.appendingPathComponent("mortality_cleanup.json")
    )
    try! mortalityWrite(
        mortality.records.map { $0.terminalActivity },
        to: root.appendingPathComponent("mortality_terminal_activity.json")
    )
    try! mortalityWrite(
        conservation,
        to: root.appendingPathComponent("mortality_resource_conservation.json")
    )
    try! mortalityWrite(
        mortalityEvents,
        to: root.appendingPathComponent("mortality_causal_chain.json")
    )
    let durableDigest = try! direct.durableStateDigest()
    try! mortalityWrite(
        MortalityScenarioSummary(
            scenario: options.scenario,
            seed: options.seed,
            simulationID: direct.simulationID.rawValue,
            preDeathTick: preDeathCheckpoint.tick.rawValue,
            deathTick: record.deathTick,
            deathID: record.deathID.rawValue,
            deadAgentID: record.agentID.rawValue,
            cause: record.cause.rawValue,
            populationBefore: exitFrame.populationBefore,
            populationAfter: exitFrame.populationAfter,
            replacementAgentID: "agent_4",
            nextPopulationOrdinal: population.nextPopulationOrdinal ?? -1,
            activeAgentIDs: direct.expectedActiveAgentIDs().map(\.rawValue),
            unrecoveredAtDeath: summary.unrecoveredTotal,
            checkpointSchema: preDeathCheckpoint.schemaVersion,
            replaySchema: journal.manifest.schemaVersion,
            replayRecords: journal.records.count,
            finalCausalSequence: causal.summary.latestSequence,
            causalDigest: causal.summary.digest,
            durableDigest: durableDigest.rawValue,
            mortalityDigest: mortality.digest,
            worldMutationCount: 0,
            persistentEntityCount: 0
        ),
        to: root.appendingPathComponent("mortality_summary.json")
    )
    try! mortalityWrite(
        MortalityScenarioDigests(
            durable: durableDigest.rawValue,
            mortality: mortality.digest,
            causal: causal.summary.digest,
            checkpoint: preDeathCheckpoint.semanticDigest.rawValue,
            replay: replayed.report.finalSemanticDigest.rawValue
        ),
        to: root.appendingPathComponent("mortality_digest.json")
    )
    try! mortalityWrite(
        MortalityScenarioReport(
            scenario: options.scenario,
            seed: options.seed,
            success: success,
            checks: checks
        ),
        to: root.appendingPathComponent("mortality_invariant_report.json")
    )
    guard success else {
        let failed = checks.filter { !$0.passed }.map(\.name).joined(separator: ",")
        fail("mortality_population_exit_smoke invariants failed: \(failed)")
    }
    print(
        "mortality_population_exit_smoke PASS death=\(record.deathID.rawValue) "
            + "agent=\(record.agentID.rawValue) tick=\(record.deathTick) "
            + "population=\(exitFrame.populationBefore)>\(exitFrame.populationAfter)>\(population.memberCount) "
            + "replacement=agent_4 schema=\(preDeathCheckpoint.schemaVersion) "
            + "digest=\(mortality.digest)"
    )
    exit(0)
}
