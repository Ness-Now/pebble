import Foundation
import PebbleAgents

private func persistenceSmokeAgent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.2, safety: 1),
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

private func persistenceSmokeSession(_ id: String = "persistence-contracts") -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: 46,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 6,
        memoryPolicy: .bounded(maxEntries: 128)
    )
    return try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            persistenceSmokeAgent("agent_0", x: 0),
            persistenceSmokeAgent("agent_1", x: 1),
            persistenceSmokeAgent("agent_2", x: 2),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
}

private func persistenceReplayJournal(
    name: String,
    checkpoint: AgentSessionCheckpoint,
    records: [AgentReplayRecord],
    replayable: Bool = true,
    dropped: Int = 0
) -> AgentReplayJournal {
    let bytes = try! AgentReplayCodec.encodeRecords(records)
    return AgentReplayJournal(
        manifest: AgentReplayJournalManifest(
            name: AgentCheckpointName(rawValue: name)!,
            baseCheckpointID: checkpoint.checkpointID,
            baseCheckpointDigest: checkpoint.semanticDigest,
            simulationID: checkpoint.simulationID,
            initialTick: checkpoint.tick.rawValue,
            recordCount: records.count,
            droppedRecordCount: dropped,
            replayable: replayable,
            nonReplayableReason: replayable ? nil : "test refusal",
            operationsStorageDigest: AgentCheckpointDigest.sha256(bytes),
            operationsByteLength: bytes.count
        ),
        records: records
    )
}

private func persistenceReplayRecord(
    from record: AgentReplayRecord,
    simulationID: AgentSimulationID? = nil,
    sequence: UInt64? = nil,
    preDigest: AgentCheckpointDigest? = nil,
    postDigest: AgentCheckpointDigest? = nil
) -> AgentReplayRecord {
    AgentReplayRecord(
        simulationID: simulationID ?? record.simulationID,
        recordSequence: AgentReplayRecordSequence(rawValue: sequence ?? record.recordSequence.rawValue)!,
        operation: record.operation,
        expectedTickBefore: record.expectedTickBefore,
        preStateSemanticDigest: preDigest ?? record.preStateSemanticDigest,
        postStateSemanticDigest: postDigest ?? record.postStateSemanticDigest,
        causalSequenceBefore: record.causalSequenceBefore,
        causalSequenceAfter: record.causalSequenceAfter,
        causalDigestAfter: record.causalDigestAfter
    )
}

func runPebbleAgentsPersistenceReplaySmoke() {
    section("PebbleAgents persistence and replay")

    check("checkpoint schema v1", AgentCheckpointSchema.currentVersion == 1)
    check("checkpoint safe name accepted", AgentCheckpointName(rawValue: "accepted-task_1") != nil)
    check("checkpoint empty name refused", AgentCheckpointName(rawValue: "") == nil)
    check("checkpoint traversal name refused", AgentCheckpointName(rawValue: "../escape") == nil)
    check("checkpoint slash name refused", AgentCheckpointName(rawValue: "a/b") == nil)
    check("checkpoint long name refused", AgentCheckpointName(rawValue: String(repeating: "a", count: 49)) == nil)
    check("checkpoint count bound", AgentCheckpointLimits.maximumCheckpointsPerWorld == 8)
    check("checkpoint byte bound", AgentCheckpointLimits.maximumCheckpointBytes == 16 * 1024 * 1024)
    check("replay record bound", AgentCheckpointLimits.maximumReplayRecords == 4096)
    check("World binding cell bound", AgentCheckpointLimits.maximumBoundWorldCells == 256)

    var session = persistenceSmokeSession()
    session.setEconomyEnabled(true)
    session.setNaturalResourcesEnabled(true)
    session.setSurvivalEnabled(true)
    _ = try! session.advanceTick()
    let beforeLedger = session.causalLedgerSnapshot().summary
    let readiness = session.checkpointReadiness()
    check("checkpoint readiness stable", readiness.ready)
    check("checkpoint readiness conservation", readiness.conservationBalanced)

    let checkpointA = try! session.makeCheckpoint()
    let checkpointB = try! session.makeCheckpoint()
    let bytesA = try! AgentCheckpointCodec.encode(checkpointA)
    let bytesB = try! AgentCheckpointCodec.encode(checkpointB)
    check("checkpoint repeated bytes deterministic", bytesA == bytesB)
    check("checkpoint repeated ID deterministic", checkpointA.checkpointID == checkpointB.checkpointID)
    check("checkpoint semantic digest stable", checkpointA.semanticDigest == checkpointB.semanticDigest)
    check("checkpoint ID contains no wall-clock identity", !checkpointA.checkpointID.rawValue.contains("UUID"))

    let decoded = try! AgentCheckpointCodec.decode(AgentSessionCheckpoint.self, from: bytesA)
    let report = try! AgentSimulationSession.validate(decoded)
    check("checkpoint Codable round-trip validates", report.valid)
    var restored = try! AgentSimulationSession.restoring(decoded)
    let afterLedger = restored.causalLedgerSnapshot().summary
    check("checkpoint restore simulation ID exact", restored.simulationID == session.simulationID)
    check("checkpoint restore tick exact", restored.tick == session.tick)
    check("checkpoint restore causal sequence exact", afterLedger.latestSequence == beforeLedger.latestSequence)
    check("checkpoint restore causal digest exact", afterLedger.digest == beforeLedger.digest)
    check("checkpoint restore adds no lifecycle event", restored.causalLedgerSnapshot().events.count == session.causalLedgerSnapshot().events.count)
    check("checkpoint restore durable bytes exact", try! restored.durableStateBytes() == session.durableStateBytes())
    check("checkpoint restore public snapshot exact", try! AgentCheckpointCodec.encode(restored.snapshot()) == AgentCheckpointCodec.encode(session.snapshot()))

    let restoredCheckpoint = try! restored.makeCheckpoint()
    check("checkpoint repeated restore digest exact", restoredCheckpoint.semanticDigest == checkpointA.semanticDigest)
    restored.setEconomyEnabled(false)
    check("checkpoint digest covers hidden feature state", try! restored.durableStateDigest() != checkpointA.semanticDigest)

    let binding = try! AgentCheckpointWorldBinding(
        worldID: "world-1",
        storageIdentity: "pebble-db-world-1",
        seed: 46,
        dimension: 0,
        anchor: AgentPosition(x: 0, y: 64, z: 0),
        simulationID: checkpointA.simulationID,
        checkpointTick: checkpointA.tick,
        cells: [AgentCheckpointWorldCell(
            position: AgentPosition(x: 0, y: 64, z: 0),
            blockFingerprint: 3
        )]
    )
    let bindingAgain = try! AgentCheckpointWorldBinding(
        worldID: "world-1",
        storageIdentity: "pebble-db-world-1",
        seed: 46,
        dimension: 0,
        anchor: AgentPosition(x: 0, y: 64, z: 0),
        simulationID: checkpointA.simulationID,
        checkpointTick: checkpointA.tick,
        cells: [AgentCheckpointWorldCell(
            position: AgentPosition(x: 0, y: 64, z: 0),
            blockFingerprint: 3
        )]
    )
    check("World binding digest deterministic", binding.compatibilityDigest == bindingAgain.compatibilityDigest)

    var replayDirect = persistenceSmokeSession("persistence-replay")
    let replayBase = try! replayDirect.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(checkpoint: replayBase, session: replayDirect)
    _ = try! recorder.apply(.setEconomyEnabled(true), to: &replayDirect)
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &replayDirect
    )
    _ = try! recorder.apply(.externalUpdate(AgentExternalUpdate(
        agentId: "agent_0",
        memoryEntries: [AgentMemoryEntry(
            tick: replayDirect.tick,
            type: "replay_fixture",
            summary: "typed external update",
            importance: 0.4
        )]
    )), to: &replayDirect)
    _ = try! recorder.apply(.setSurvivalEnabled(true), to: &replayDirect)
    let journal = try! recorder.journal(named: AgentCheckpointName(rawValue: "continuation")!)
    check("replay records every accepted mutation", journal.records.count == 4)
    check("replay records contiguous sequence", journal.records.map(\.recordSequence.rawValue) == [1, 2, 3, 4])
    check("replay records typed operation kinds", journal.records.map(\.operationKind) == [
        .economyFeature, .advanceTick, .externalUpdate, .survivalFeature,
    ])
    check("replay manifest has no dropped records", journal.manifest.droppedRecordCount == 0)
    check("replay manifest is replayable", journal.manifest.replayable)
    let journalBytesA = try! AgentReplayCodec.encodeRecords(journal.records)
    let journalBytesB = try! AgentReplayCodec.encodeRecords(journal.records)
    check("replay NDJSON bytes deterministic", journalBytesA == journalBytesB)
    let decodedRecords = try! AgentReplayCodec.decodeRecords(journalBytesA)
    check("replay NDJSON round-trip count", decodedRecords.count == journal.records.count)

    let replayed = try! AgentSessionReplayer.replay(checkpoint: replayBase, journal: journal)
    check("replay verifies exact continuation", replayed.report.verified)
    check("replay applies all records", replayed.report.recordsApplied == journal.records.count)
    check("replay final digest exact", replayed.report.finalSemanticDigest == (try! replayDirect.durableStateDigest()))
    check("replay final durable bytes exact", try! replayed.session.durableStateBytes() == replayDirect.durableStateBytes())
    check("replay final causal sequence exact", replayed.report.finalCausalSequence == replayDirect.causalLedgerSnapshot().summary.latestSequence)
    check("replay final causal digest exact", replayed.report.finalCausalDigest == replayDirect.causalLedgerSnapshot().summary.digest)

    var refusedSession = try! AgentSimulationSession.restoring(replayBase)
    var refusedRecorder = try! AgentReplayRecorder(checkpoint: replayBase, session: refusedSession)
    let refusedBefore = try! refusedSession.durableStateDigest()
    let invalidDelivery = AgentDeliveryOutcome(
        deliveryId: "invalid-delivery",
        agentId: "missing-agent",
        tick: refusedSession.tick,
        status: .blocked,
        transferred: [],
        reason: "negative test"
    )
    let refused = (try? refusedRecorder.apply(
        .deliveryOutcome(invalidDelivery),
        to: &refusedSession
    )) == nil
    check("replay refused mutation produces no record", refused && refusedRecorder.records.isEmpty)
    check("replay refused mutation preserves state", try! refusedSession.durableStateDigest() == refusedBefore)

    let zeroDigest = AgentCheckpointDigest(rawValue: String(repeating: "0", count: 64))!
    let badPostRecord = persistenceReplayRecord(from: journal.records[0], postDigest: zeroDigest)
    let badPost = try! AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: persistenceReplayJournal(
            name: "bad-post",
            checkpoint: replayBase,
            records: [badPostRecord]
        )
    )
    check("replay reports post-digest divergence", !badPost.report.verified && badPost.report.divergence?.recordSequence == 1)
    check("replay reports first divergent operation", badPost.report.divergence?.operationKind == .economyFeature)

    let badPreRecord = persistenceReplayRecord(from: journal.records[0], preDigest: zeroDigest)
    let badPre = try! AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: persistenceReplayJournal(
            name: "bad-pre",
            checkpoint: replayBase,
            records: [badPreRecord]
        )
    )
    check("replay reports pre-digest divergence", !badPre.report.verified && badPre.report.recordsApplied == 0)

    let gapRecord = persistenceReplayRecord(from: journal.records[0], sequence: 2)
    let gap = try! AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: persistenceReplayJournal(
            name: "record-gap",
            checkpoint: replayBase,
            records: [gapRecord]
        )
    )
    check("replay rejects record sequence gap", !gap.report.verified && gap.report.divergence?.recordSequence == 2)

    let otherSimulation = try! AgentSimulationID(validating: "wrong-simulation")
    let crossSimulationRecord = persistenceReplayRecord(
        from: journal.records[0],
        simulationID: otherSimulation
    )
    let crossSimulation = try! AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: persistenceReplayJournal(
            name: "cross-simulation",
            checkpoint: replayBase,
            records: [crossSimulationRecord]
        )
    )
    check("replay rejects cross-simulation record", !crossSimulation.report.verified)
    check("replay rejects truncated NDJSON", (try? AgentReplayCodec.decodeRecords(Data(journalBytesA.dropLast()))) == nil)

    let nonReplayable = persistenceReplayJournal(
        name: "not-replayable",
        checkpoint: replayBase,
        records: [],
        replayable: false,
        dropped: 1
    )
    check("replay rejects dropped-record journal", (try? AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: nonReplayable
    )) == nil)
}
