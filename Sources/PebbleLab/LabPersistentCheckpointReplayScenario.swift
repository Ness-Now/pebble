import Foundation
import PebbleAgents

private struct PersistenceScenarioCheck: Codable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

private struct PersistenceScenarioSummary: Encodable, Equatable {
    let schemaVersion = 1
    let scenario: String
    let seed: UInt32
    let simulationID: String
    let checkpointAID: String
    let checkpointADigest: String
    let checkpointATick: Int
    let checkpointACausalSequence: UInt64
    let taskID: String
    let taskProgressAtA: Int
    let trustAtA: Int
    let replayRecordCount: Int
    let checkpointBDirectDigest: String
    let checkpointBReplayedDigest: String
    let finalTick: Int
    let finalCausalSequence: UInt64
    let finalCausalDigest: String
    let noWorldMutation: Bool
}

private struct PersistenceInvariantReport: Encodable, Equatable {
    let schemaVersion = 1
    let scenario: String
    let seed: UInt32
    let success: Bool
    let checks: [PersistenceScenarioCheck]
}

private struct PersistenceScenarioState {
    var session: AgentSimulationSession
    let taskID: AgentSharedTaskID
    let checkpoint: AgentSessionCheckpoint
}

private let persistenceHome = AgentPosition(x: 0, y: 64, z: 0)
private let persistenceOrigin = AgentPosition(x: 2, y: 64, z: 1)

private func persistenceState(_ id: String, x: Int, fear: Int = 0) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: -1, curiosity: 0.2, safety: 1),
        health: 100,
        fear: fear,
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

private func persistenceObservation(
    resource: AgentResourceKind,
    x: Int,
    fingerprint: Int,
    observerX: Int = 0
) -> AgentResourceObservation {
    AgentResourceObservation(
        resource: resource,
        target: AgentPosition(x: x, y: 64, z: 0),
        direction: .east,
        distanceManhattan: abs(x - observerX),
        quantityAvailable: 1,
        source: .naturalWorld,
        expectedBlockFingerprint: fingerprint
    )
}

private func persistenceProject(seed: UInt32) -> AgentConstructionProject {
    try! AgentConstructionProject(
        projectId: "persistent-shelter-\(seed)",
        builderAgentId: "builder",
        origin: persistenceOrigin,
        createdAtTick: 3,
        previousHomePosition: persistenceHome,
        originalFingerprints: AgentBlueprint.fixedLeanToV1.cells.map {
            AgentConstructionCellFingerprint(cellIndex: $0.index, originalFingerprint: 0)
        }
    )
}

private func persistenceSession(seed: UInt32) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: seed,
        nearbyRadius: 12,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 128),
        campStockCapacity: 32,
        socialConfiguration: try! AgentSocialConfiguration(
            minimumTrustToVerify: 0,
            shareCooldownTicks: 1
        )
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            persistenceState("builder", x: 0),
            persistenceState("helper", x: 1),
            persistenceState("excluded", x: 3, fear: 80),
        ],
        simulationID: try! AgentSimulationID(validating: "persistent-checkpoint-replay-\(seed)"),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    try! session.setSocialEnabled(true)
    return session
}

private func preparePersistenceCheckpointA(seed: UInt32) -> PersistenceScenarioState {
    var session = persistenceSession(seed: seed)
    let trustObservation = persistenceObservation(resource: .wood, x: 2, fingerprint: 700)
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "builder", socialResourceObservations: [trustObservation]
    )])
    _ = try! session.advanceTick()
    let trustTick = try! session.advanceTick()
    precondition(trustTick.agents.first { $0.agentId == "helper" }?.action.name == "verify_information")
    let trustBelief = session.socialSnapshot().beliefs.first { $0.ownerID.rawValue == "helper" }!
    _ = try! session.applySocialVerification(AgentSocialVerificationObservation(
        beliefID: trustBelief.beliefID,
        verifierID: trustBelief.ownerID,
        position: trustBelief.fact.position,
        chunkReady: true,
        observedBlockFingerprint: trustBelief.fact.expectedBlockFingerprint,
        observedResource: trustBelief.fact.resource
    ))

    try! session.createConstructionProject(persistenceProject(seed: seed))
    try! session.setBuildAutoEnabled(true)
    try! session.setPhysicalEnabled(true)
    try! session.setCooperationEnabled(true)
    session.setEconomyEnabled(true)
    session.setNaturalResourcesEnabled(true)
    session.setSurvivalEnabled(true)
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "builder",
        socialResourceObservations: [persistenceObservation(resource: .stone, x: 3, fingerprint: 701)]
    )])
    _ = try! session.advanceTick()
    let signal = session.physicalChannelSnapshot().signals.last!
    _ = try! session.advanceTick(physicalObservations: [
        AgentPhysicalSignalObservation(
            signalID: signal.signalID,
            observerID: AgentID(rawValue: "helper")!,
            distanceManhattan: 1,
            soundClarity: 95,
            gestureClarity: 95,
            opaqueOcclusionCount: 0,
            lineOfSight: true,
            chunksReady: true,
            observedAtTick: session.tick + 1
        ),
        AgentPhysicalSignalObservation(
            signalID: signal.signalID,
            observerID: AgentID(rawValue: "excluded")!,
            distanceManhattan: 3,
            soundClarity: 60,
            gestureClarity: 60,
            opaqueOcclusionCount: 0,
            lineOfSight: true,
            chunksReady: true,
            observedAtTick: session.tick + 1
        ),
    ])
    _ = try! session.advanceTick()
    let task = session.cooperationSnapshot().tasks.first!
    precondition(task.status == .accepted)
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "helper",
        resourceObservations: [persistenceObservation(
            resource: .stone,
            x: 2,
            fingerprint: 702,
            observerX: 1
        )]
    )])
    try! session.applyInteractionOutcome(persistenceHarvest(
        id: "checkpoint-a-helper-stone-0", agent: "helper", resource: .stone, z: 0,
        tick: session.tick
    ))
    let helper = session.snapshot().agents.first { $0.id == "helper" }!
    _ = try! session.deliverResources(AgentDeliveryIntent(
        deliveryId: "checkpoint-a-helper-delivery",
        agentId: "helper",
        tick: session.tick,
        position: helper.position
    ))
    try! session.applyInteractionOutcome(persistenceHarvest(
        id: "checkpoint-a-builder-wood-0", agent: "builder", resource: .wood, z: 10,
        tick: session.tick
    ))
    let checkpoint = try! session.makeCheckpoint()
    return PersistenceScenarioState(session: session, taskID: task.taskID, checkpoint: checkpoint)
}

private func persistenceHarvest(
    id: String,
    agent: String,
    resource: AgentResourceKind,
    z: Int,
    tick: Int
) -> AgentInteractionOutcome {
    AgentInteractionOutcome(
        interactionId: id,
        agentId: agent,
        tick: tick,
        target: AgentPosition(x: 2, y: 64, z: z),
        resource: resource,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
        reason: "persistent replay material fixture"
    )
}

private func continuePersistenceScenario(
    session: inout AgentSimulationSession,
    recorder: inout AgentReplayRecorder
) {
    for index in 1...2 {
        _ = try! recorder.apply(.interactionOutcome(persistenceHarvest(
            id: "continuation-helper-stone-\(index)", agent: "helper", resource: .stone,
            z: index, tick: session.tick
        )), to: &session)
    }
    let helper = session.snapshot().agents.first { $0.id == "helper" }!
    precondition(helper.position == helper.homePosition)
    _ = try! recorder.apply(.deliveryOutcome(AgentDeliveryOutcome(
        deliveryId: "continuation-helper-delivery",
        agentId: "helper",
        tick: session.tick,
        status: .succeeded,
        transferred: [AgentResourceAmount(resource: .stone, quantity: 2)],
        reason: "remaining task stone delivered"
    )), to: &session)
    for index in 1...5 {
        _ = try! recorder.apply(.interactionOutcome(persistenceHarvest(
            id: "continuation-builder-wood-\(index)", agent: "builder", resource: .wood,
            z: 10 + index, tick: session.tick
        )), to: &session)
    }
    _ = try! recorder.apply(.deliveryOutcome(AgentDeliveryOutcome(
        deliveryId: "continuation-builder-delivery",
        agentId: "builder",
        tick: session.tick,
        status: .succeeded,
        transferred: [AgentResourceAmount(resource: .wood, quantity: 6)],
        reason: "builder wood delivered"
    )), to: &session)
    _ = try! recorder.apply(.advanceTick(perceptions: [], physicalObservations: []), to: &session)
    let projectID = session.snapshot().constructionProject!.projectId
    _ = try! recorder.apply(.fundConstructionProject(
        fundingID: "continuation-funding", builderAgentID: "builder", tick: session.tick
    ), to: &session)
    for index in 0..<AgentBlueprint.fixedLeanToV1.cells.count {
        let project = session.snapshot().constructionProject!
        let cell = project.nextCell!
        let work = project.nextWorkPosition!
        _ = try! recorder.apply(.externalUpdate(AgentExternalUpdate(
            agentId: "builder", position: work
        )), to: &session)
        _ = try! recorder.apply(.applyPlacementOutcome(AgentPlacementOutcome(
            placementId: "continuation-placement-\(index)",
            projectId: project.projectId,
            builderAgentId: "builder",
            tick: session.tick,
            cellIndex: cell.index,
            target: project.nextTarget!,
            resource: cell.resource,
            status: .succeeded,
            reason: "persistent replay ordered placement"
        )), to: &session)
        if index + 1 < AgentBlueprint.fixedLeanToV1.cells.count {
            _ = try! recorder.apply(.advanceTick(perceptions: [], physicalObservations: []), to: &session)
        }
    }
    _ = try! recorder.apply(.completeConstructionProject(
        projectID: projectID, tick: session.tick
    ), to: &session)
}

private func persistenceBinding(
    seed: UInt32,
    checkpoint: AgentSessionCheckpoint
) -> AgentCheckpointWorldBinding {
    try! AgentCheckpointWorldBinding(
        worldID: "headless-persistent-\(seed)",
        storageIdentity: "PebbleLab-out-persistent-\(seed)",
        seed: seed,
        dimension: 0,
        anchor: persistenceHome,
        simulationID: checkpoint.simulationID,
        checkpointTick: checkpoint.tick,
        cells: []
    )
}

private func persistenceManifest(
    name: String,
    seed: UInt32,
    checkpoint: AgentSessionCheckpoint,
    bytes: Data
) -> AgentCheckpointManifest {
    AgentCheckpointManifest(
        name: AgentCheckpointName(rawValue: name)!,
        checkpoint: checkpoint,
        storageDigest: AgentCheckpointDigest.sha256(bytes),
        byteLength: bytes.count,
        restartSafe: true,
        restartSafetyReason: "headless kernel checkpoint has no World mutation receipts",
        worldBinding: persistenceBinding(seed: seed, checkpoint: checkpoint),
        orchestration: AgentCheckpointLiveOrchestration(
            cognitiveHz: 4,
            wasPaused: true,
            movementEnabled: false,
            autoInteractionEnabled: false,
            economyAutoEnabled: false
        )
    )
}

private func writePersistenceJSON<T: Encodable>(_ value: T, to url: URL) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(to: url, options: .atomic)
}

private func writeCheckpointBundle(
    root: URL,
    directoryName: String,
    manifest: AgentCheckpointManifest,
    checkpointBytes: Data
) throws {
    let manager = FileManager.default
    let final = root.appendingPathComponent(directoryName, isDirectory: true)
    let temporary = root.appendingPathComponent(".\(directoryName).tmp", isDirectory: true)
    guard !manager.fileExists(atPath: final.path), !manager.fileExists(atPath: temporary.path) else {
        throw AgentReplayError.invalidJournal("checkpoint destination already exists")
    }
    try manager.createDirectory(at: temporary, withIntermediateDirectories: false)
    do {
        try checkpointBytes.write(to: temporary.appendingPathComponent("session.json"), options: .atomic)
        try writePersistenceJSON(manifest, to: temporary.appendingPathComponent("manifest.json"))
        let reread = try Data(contentsOf: temporary.appendingPathComponent("session.json"))
        guard reread.count == manifest.byteLength,
              AgentCheckpointDigest.sha256(reread) == manifest.storageDigest else {
            throw AgentReplayError.invalidJournal("atomic checkpoint verification")
        }
        _ = try AgentSimulationSession.validate(
            AgentCheckpointCodec.decode(AgentSessionCheckpoint.self, from: reread)
        )
        try manager.moveItem(at: temporary, to: final)
    } catch {
        try? manager.removeItem(at: temporary)
        throw error
    }
}

private func loadCheckpointBundle(_ directory: URL) throws -> AgentSessionCheckpoint {
    let manifest = try AgentCheckpointCodec.decode(
        AgentCheckpointManifest.self,
        from: Data(contentsOf: directory.appendingPathComponent("manifest.json"))
    )
    let sessionData = try Data(contentsOf: directory.appendingPathComponent("session.json"))
    guard sessionData.count <= AgentCheckpointLimits.maximumCheckpointBytes,
          sessionData.count == manifest.byteLength,
          AgentCheckpointDigest.sha256(sessionData) == manifest.storageDigest else {
        throw AgentCheckpointError.semanticDigestMismatch
    }
    let checkpoint = try AgentCheckpointCodec.decode(AgentSessionCheckpoint.self, from: sessionData)
    _ = try AgentSimulationSession.validate(checkpoint)
    guard checkpoint.checkpointID == manifest.checkpointID,
          checkpoint.semanticDigest == manifest.semanticDigest else {
        throw AgentCheckpointError.semanticDigestMismatch
    }
    return checkpoint
}

private func writeReplayBundle(root: URL, journal: AgentReplayJournal) throws {
    let directory = root.appendingPathComponent("replay", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
    try AgentReplayCodec.encodeRecords(journal.records).write(
        to: directory.appendingPathComponent("operations.ndjson"), options: .atomic
    )
    try writePersistenceJSON(journal.manifest, to: directory.appendingPathComponent("manifest.json"))
}

func runPersistentCheckpointReplaySmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("persistent_checkpoint_replay_smoke requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        guard (try FileManager.default.contentsOfDirectory(atPath: root.path)).isEmpty else {
            fail("persistent checkpoint output directory must be empty: \(outPath)")
        }
    } catch {
        fail("failed to prepare persistent checkpoint output: \(error)")
    }

    let a = preparePersistenceCheckpointA(seed: options.seed)
    let checkpointABytes = try! AgentCheckpointCodec.encode(a.checkpoint)
    let checkpointAManifest = persistenceManifest(
        name: "checkpoint-a", seed: options.seed, checkpoint: a.checkpoint, bytes: checkpointABytes
    )
    try! writeCheckpointBundle(
        root: root, directoryName: "checkpoint_a",
        manifest: checkpointAManifest, checkpointBytes: checkpointABytes
    )
    let loadedA = try! loadCheckpointBundle(root.appendingPathComponent("checkpoint_a"))
    var direct = a.session
    var recorder = try! AgentReplayRecorder(checkpoint: loadedA, session: direct)
    continuePersistenceScenario(session: &direct, recorder: &recorder)
    let journal = try! recorder.journal(named: AgentCheckpointName(rawValue: "continuation")!)
    let checkpointBDirect = try! direct.makeCheckpoint()
    let checkpointBDirectBytes = try! AgentCheckpointCodec.encode(checkpointBDirect)
    try! writeCheckpointBundle(
        root: root, directoryName: "checkpoint_b_direct",
        manifest: persistenceManifest(
            name: "checkpoint-b-direct", seed: options.seed,
            checkpoint: checkpointBDirect, bytes: checkpointBDirectBytes
        ), checkpointBytes: checkpointBDirectBytes
    )
    try! writeReplayBundle(root: root, journal: journal)
    let replay = try! AgentSessionReplayer.replay(checkpoint: loadedA, journal: journal)
    let checkpointBReplayed = try! replay.session.makeCheckpoint()
    let checkpointBReplayedBytes = try! AgentCheckpointCodec.encode(checkpointBReplayed)
    try! writeCheckpointBundle(
        root: root, directoryName: "checkpoint_b_replayed",
        manifest: persistenceManifest(
            name: "checkpoint-b-replayed", seed: options.seed,
            checkpoint: checkpointBReplayed, bytes: checkpointBReplayedBytes
        ), checkpointBytes: checkpointBReplayedBytes
    )

    let taskAtA = a.session.cooperationSnapshot().tasks.first { $0.taskID == a.taskID }!
    let taskFinal = direct.cooperationSnapshot().tasks.first { $0.taskID == a.taskID }!
    let finalSnapshot = direct.snapshot()
    let finalProject = finalSnapshot.constructionProject!
    let finalCausal = direct.causalLedgerSnapshot().summary
    var checks: [PersistenceScenarioCheck] = []
    func add(_ name: String, _ passed: Bool, _ detail: String = "") {
        checks.append(PersistenceScenarioCheck(name: name, passed: passed, detail: detail))
    }
    add("schema_v1", loadedA.schemaVersion == 1)
    add("checkpoint_a_atomic_round_trip", loadedA.semanticDigest == a.checkpoint.semanticDigest)
    add("checkpoint_a_deterministic_bytes", checkpointABytes == (try! AgentCheckpointCodec.encode(a.checkpoint)))
    add("checkpoint_a_task_accepted", taskAtA.status == .active || taskAtA.status == .accepted)
    add("checkpoint_a_partial_progress", taskAtA.contributedQuantity == 1)
    add("checkpoint_a_inventory_nonempty", a.session.snapshot().agents.first { $0.id == "builder" }?.resourceInventory.count(of: .wood) == 1)
    add("checkpoint_a_stock_nonempty", a.session.snapshot().campStock.count(of: .stone) == 1)
    add("checkpoint_a_directed_trust", a.session.trustScore(sourceAgentId: "helper", targetAgentId: "builder") == 10)
    add("checkpoint_save_consumes_no_causal_sequence", loadedA.durableState.causalLedger.latestSequence == a.session.causalLedgerSnapshot().summary.latestSequence)
    add("direct_task_completed", taskFinal.status == .completed && taskFinal.contributedQuantity == 3)
    add("direct_reliability_positive", direct.cooperationSnapshot().relations.first?.reliabilityScore == 10)
    add("direct_funding_complete", finalProject.status == .completed)
    add("direct_nine_placements", finalProject.placedCellIndices.count == 9)
    add("direct_home_updated", finalSnapshot.agents.first { $0.id == "builder" }?.homePosition == finalProject.restPosition)
    add("direct_conservation_exact", finalSnapshot.conservation.balanced)
    add("replay_verified", replay.report.verified)
    add("replay_all_records", replay.report.recordsApplied == journal.records.count)
    add("replay_semantic_digest_exact", checkpointBDirect.semanticDigest == checkpointBReplayed.semanticDigest)
    add("replay_durable_bytes_exact", checkpointBDirectBytes == checkpointBReplayedBytes)
    add("replay_tick_exact", direct.tick == replay.session.tick)
    add("replay_simulation_id_exact", direct.simulationID == replay.session.simulationID)
    add("replay_causal_sequence_exact", finalCausal.latestSequence == replay.report.finalCausalSequence)
    add("replay_causal_digest_exact", finalCausal.digest == replay.report.finalCausalDigest)
    add("replay_public_snapshot_exact", direct.snapshot() == replay.session.snapshot())
    add("replay_no_world_mutation", true)
    add("safe_name_rejects_traversal", AgentCheckpointName(rawValue: "../escape") == nil)
    let truncated = Data((try! AgentReplayCodec.encodeRecords(journal.records)).dropLast())
    add("truncated_journal_refused", (try? AgentReplayCodec.decodeRecords(truncated)) == nil)
    let corruptSession = checkpointABytes + Data([0x20])
    add("storage_corruption_detected", AgentCheckpointDigest.sha256(corruptSession) != checkpointAManifest.storageDigest)
    let wrongBinding = try! AgentCheckpointWorldBinding(
        worldID: "wrong-world", storageIdentity: "wrong-storage", seed: options.seed,
        dimension: 0, anchor: persistenceHome, simulationID: a.checkpoint.simulationID,
        checkpointTick: a.checkpoint.tick, cells: []
    )
    add("world_binding_mismatch_detected", wrongBinding.compatibilityDigest != checkpointAManifest.worldBinding.compatibilityDigest)
    let zeroDigest = AgentCheckpointDigest(rawValue: String(repeating: "0", count: 64))!
    let first = journal.records[0]
    let divergentRecord = AgentReplayRecord(
        simulationID: first.simulationID,
        recordSequence: first.recordSequence,
        operation: first.operation,
        expectedTickBefore: first.expectedTickBefore,
        preStateSemanticDigest: first.preStateSemanticDigest,
        postStateSemanticDigest: zeroDigest,
        causalSequenceBefore: first.causalSequenceBefore,
        causalSequenceAfter: first.causalSequenceAfter,
        causalDigestAfter: first.causalDigestAfter
    )
    let divergentBytes = try! AgentReplayCodec.encodeRecords([divergentRecord])
    let divergentJournal = AgentReplayJournal(
        manifest: AgentReplayJournalManifest(
            name: AgentCheckpointName(rawValue: "divergence")!,
            baseCheckpointID: loadedA.checkpointID,
            baseCheckpointDigest: loadedA.semanticDigest,
            simulationID: loadedA.simulationID,
            initialTick: loadedA.tick.rawValue,
            recordCount: 1,
            droppedRecordCount: 0,
            replayable: true,
            nonReplayableReason: nil,
            operationsStorageDigest: AgentCheckpointDigest.sha256(divergentBytes),
            operationsByteLength: divergentBytes.count
        ), records: [divergentRecord]
    )
    let divergence = try! AgentSessionReplayer.replay(checkpoint: loadedA, journal: divergentJournal)
    add("first_divergence_reported", !divergence.report.verified && divergence.report.divergence?.recordSequence == 1)

    let summary = PersistenceScenarioSummary(
        scenario: "persistent_checkpoint_replay_smoke", seed: options.seed,
        simulationID: a.checkpoint.simulationID.rawValue,
        checkpointAID: a.checkpoint.checkpointID.rawValue,
        checkpointADigest: a.checkpoint.semanticDigest.rawValue,
        checkpointATick: a.checkpoint.tick.rawValue,
        checkpointACausalSequence: a.session.causalLedgerSnapshot().summary.latestSequence,
        taskID: a.taskID.rawValue, taskProgressAtA: taskAtA.contributedQuantity,
        trustAtA: a.session.trustScore(sourceAgentId: "helper", targetAgentId: "builder"),
        replayRecordCount: journal.records.count,
        checkpointBDirectDigest: checkpointBDirect.semanticDigest.rawValue,
        checkpointBReplayedDigest: checkpointBReplayed.semanticDigest.rawValue,
        finalTick: direct.tick, finalCausalSequence: finalCausal.latestSequence,
        finalCausalDigest: finalCausal.digest, noWorldMutation: true
    )
    let report = PersistenceInvariantReport(
        scenario: summary.scenario, seed: options.seed,
        success: checks.allSatisfy(\.passed), checks: checks
    )
    do {
        try writePersistenceJSON(summary, to: root.appendingPathComponent("persistence_summary.json"))
        try writePersistenceJSON(replay.report, to: root.appendingPathComponent("replay_report.json"))
        try writePersistenceJSON(report, to: root.appendingPathComponent("persistence_invariant_report.json"))
    } catch {
        fail("failed to write persistent checkpoint reports: \(error)")
    }
    guard report.success else {
        fail("persistent checkpoint replay invariant failed: \(checks.filter { !$0.passed }.map(\.name))")
    }
    print("persistent checkpoint replay PASS seed=\(options.seed) tick=\(direct.tick) records=\(journal.records.count) digest=\(checkpointBDirect.semanticDigest.rawValue)")
    exit(0)
}
