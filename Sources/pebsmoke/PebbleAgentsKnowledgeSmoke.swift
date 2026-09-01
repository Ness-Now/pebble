import Foundation
import PebbleAgents

private func knowledgeSmokeAgent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "CIV-41 fixture", startedAtTick: 0, urgency: 0
        ),
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

private func knowledgeSmokeSession(
    id: String,
    agents: [AgentSessionAgentState],
    knowledgeConfiguration: AgentKnowledgeConfiguration = .live,
    socialConfiguration: AgentSocialConfiguration? = nil,
    enableKnowledge: Bool = true
) -> AgentSimulationSession {
    let social = socialConfiguration ?? (try! AgentSocialConfiguration(
        communicationRadius: 2,
        minimumTrustToVerify: -100,
        claimLifetimeTicks: 64,
        messageLifetimeTicks: 48,
        maximumFactsPerAgent: 8,
        maximumBeliefsPerAgent: 8,
        maximumTrustRelations: 32,
        maximumRetainedMessages: 32,
        shareCooldownTicks: 1
    ))
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 141,
            nearbyRadius: 16,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            socialConfiguration: social
        ),
        agents: agents,
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.setSocialEnabled(true)
    if enableKnowledge {
        try! session.setKnowledgeGraphEnabled(
            true, configuration: knowledgeConfiguration
        )
    }
    return session
}

private func knowledgeSmokePerception(
    observerID: String,
    observerX: Int,
    targetX: Int,
    resource: AgentResourceKind,
    fingerprint: Int
) -> AgentPerceptionInput {
    AgentPerceptionInput(
        agentId: observerID,
        socialResourceObservations: [AgentResourceObservation(
            resource: resource,
            target: AgentPosition(x: targetX, y: 64, z: 0),
            direction: targetX < observerX ? .west : .east,
            distanceManhattan: abs(targetX - observerX),
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: fingerprint
        )]
    )
}

@discardableResult
private func knowledgeSmokeDirectMessage(
    session: inout AgentSimulationSession,
    senderID: String,
    senderX: Int,
    recipientID: String,
    targetX: Int,
    resource: AgentResourceKind,
    fingerprint: Int
) -> AgentSocialBelief {
    let messageCount = session.socialSnapshot().messages.count
    _ = try! session.advanceTick(perceptions: [knowledgeSmokePerception(
        observerID: senderID,
        observerX: senderX,
        targetX: targetX,
        resource: resource,
        fingerprint: fingerprint
    )])
    for _ in 0..<8 where session.socialSnapshot().messages.count == messageCount {
        _ = try! session.advanceTick()
    }
    let belief = session.socialSnapshot().beliefs.filter {
        $0.senderID.rawValue == senderID
            && $0.ownerID.rawValue == recipientID
            && $0.fact.expectedBlockFingerprint == fingerprint
    }.max {
        if $0.receivedAtTick != $1.receivedAtTick {
            return $0.receivedAtTick < $1.receivedAtTick
        }
        return $0.beliefID < $1.beliefID
    }
    precondition(belief != nil, "real local message was not delivered")
    return belief!
}

@discardableResult
private func knowledgeSmokeVerify(
    session: inout AgentSimulationSession,
    belief: AgentSocialBelief,
    resource: AgentResourceKind?,
    fingerprint: Int?
) -> AgentSocialVerificationResult {
    let result = try! session.advanceTick()
    let action = result.agents.first {
        $0.agentId == belief.ownerID.rawValue
    }?.action
    precondition(action?.name == "verify_information")
    return try! session.applySocialVerification(
        AgentSocialVerificationObservation(
            beliefID: belief.beliefID,
            verifierID: belief.ownerID,
            position: belief.fact.position,
            chunkReady: true,
            observedBlockFingerprint: fingerprint,
            observedResource: resource
        )
    )
}

private func knowledgeSmokeBelief(
    ownerID: String,
    snapshot: AgentKnowledgeSnapshot
) -> AgentKnowledgeBelief? {
    snapshot.beliefs.first { $0.ownerID.rawValue == ownerID }
}

private func knowledgeSmokeUnderstanding(
    belief: AgentKnowledgeBelief,
    snapshot: AgentKnowledgeSnapshot
) -> AgentKnowledgeUnderstanding? {
    snapshot.understandings.first {
        $0.understandingID == belief.basisUnderstandingID
    }
}

private func knowledgeBoundRun(reversed: Bool) -> AgentKnowledgeSnapshot {
    let configuration = try! AgentKnowledgeConfiguration(
        maximumPropositions: 8,
        maximumEvidence: 8,
        maximumClaims: 2,
        maximumUnderstandings: 4,
        maximumBeliefs: 4,
        maximumRevisions: 2,
        maximumEvidencePerAgent: 4,
        maximumClaimsPerAgent: 2,
        maximumUnderstandingsPerAgent: 2,
        maximumBeliefsPerAgent: 2,
        maximumRevisionsPerAgent: 1
    )
    let states = [
        knowledgeSmokeAgent("agent_a", x: 0),
        knowledgeSmokeAgent("agent_b", x: 1),
    ]
    var session = knowledgeSmokeSession(
        id: "civ41-bounds",
        agents: reversed ? Array(states.reversed()) : states,
        knowledgeConfiguration: configuration
    )
    for index in 0..<4 {
        let belief = knowledgeSmokeDirectMessage(
            session: &session,
            senderID: "agent_a", senderX: 0,
            recipientID: "agent_b", targetX: 2,
            resource: .wood, fingerprint: 1_000 + index
        )
        _ = knowledgeSmokeVerify(
            session: &session,
            belief: belief,
            resource: .stone,
            fingerprint: 2_000 + index
        )
    }
    return session.knowledgeSnapshot()
}

private func knowledgeRestartCandidate() -> AgentSimulationSession {
    var session = knowledgeSmokeSession(
        id: "civ41-fresh-process",
        agents: [
            knowledgeSmokeAgent("agent_a", x: 0),
            knowledgeSmokeAgent("agent_b", x: 1),
        ]
    )
    let hearsay = knowledgeSmokeDirectMessage(
        session: &session,
        senderID: "agent_a", senderX: 0,
        recipientID: "agent_b", targetX: 2,
        resource: .wood, fingerprint: 4_100
    )
    _ = knowledgeSmokeVerify(
        session: &session,
        belief: hearsay,
        resource: .stone,
        fingerprint: 4_200
    )
    return session
}

func runPebbleAgentsKnowledgeRestartWriteSmoke() {
    section("CIV-41 schema-36 fresh-process checkpoint writer")
    guard let path = ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV41_CHECKPOINT_PATH"
    ], !path.isEmpty else {
        check("fresh-process writer receives checkpoint path", false)
        return
    }
    let session = knowledgeRestartCandidate()
    let graph = session.knowledgeSnapshot()
    let checkpoint = try! session.makeCheckpoint()
    let bytes = try! AgentCheckpointCodec.encode(checkpoint)
    try! bytes.write(to: URL(fileURLWithPath: path), options: .atomic)
    check("fresh-process writer emits schema 36", checkpoint.schemaVersion == 36)
    check("fresh-process writer traverses real claim and revision paths",
          graph.evidence.count == 2
            && graph.claims.count == 1
            && graph.understandings.count == 3
            && graph.beliefs.count == 2
            && graph.revisions.count == 3)
    check("fresh-process writer persists nonempty checkpoint", !bytes.isEmpty)
    print("  CIV41_RESTART_WRITE bytes=\(bytes.count) schema=\(checkpoint.schemaVersion) digest=\(checkpoint.semanticDigest.rawValue) graph=\(graph.digest)")
}

func runPebbleAgentsKnowledgeRestartReadSmoke() {
    section("CIV-41 schema-36 fresh-process checkpoint reader")
    guard let path = ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV41_CHECKPOINT_PATH"
    ], !path.isEmpty else {
        check("fresh-process reader receives checkpoint path", false)
        return
    }
    let bytes = try! Data(contentsOf: URL(fileURLWithPath: path))
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: bytes
    )
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    let graph = restored.knowledgeSnapshot()
    let reencoded = try! AgentCheckpointCodec.encode(restored.makeCheckpoint())
    check("fresh process decodes schema 36", checkpoint.schemaVersion == 36)
    check("fresh process preserves exact checkpoint bytes", reencoded == bytes)
    check("fresh process retains direct and attributed authority",
          Set(graph.evidence.map(\.authority)) == [
            .validatedWorldObservation, .validatedSocialVerification,
          ] && graph.claims.count == 1)
    check("fresh process retains current belief provenance",
          graph.beliefs.allSatisfy { belief in
            graph.understandings.contains {
                $0.understandingID == belief.basisUnderstandingID
            }
          })
    check("fresh process duplicates no graph records",
          graph.evidence.count == 2
            && graph.claims.count == 1
            && graph.understandings.count == 3
            && graph.beliefs.count == 2
            && graph.revisions.count == 3)
    print("  CIV41_RESTART_READ bytes=\(bytes.count) schema=\(checkpoint.schemaVersion) digest=\(checkpoint.semanticDigest.rawValue) graph=\(graph.digest)")
}

func runPebbleAgentsKnowledgeSmoke() {
    section("CIV-41 structured knowledge and belief graph V1")

    check("checkpoint schema advances to 36", AgentCheckpointSchema.knowledgeVersion == 36)
    check("replay schema advances to 36", AgentReplaySchema.knowledgeVersion == 36)
    check("knowledge graph defaults are globally bounded", AgentKnowledgeConfiguration.live.maximumPropositions == 4_096 && AgentKnowledgeConfiguration.live.maximumBeliefs == 4_096)
    check("knowledge graph defaults are bounded per agent", AgentKnowledgeConfiguration.live.maximumEvidencePerAgent == 16 && AgentKnowledgeConfiguration.live.maximumBeliefsPerAgent == 16)
    check("knowledge graph rejects a zero capacity", (try? AgentKnowledgeConfiguration(maximumClaims: 0)) == nil)
    check("knowledge proposition ID rejects whitespace", AgentKnowledgePropositionID(rawValue: "bad id") == nil)

    let noLedger = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 1, memoryPolicy: .bounded(maxEntries: 4)
        ),
        agents: [knowledgeSmokeAgent("agent_a", x: 0)]
    )
    var noLedgerCandidate = noLedger
    var ledgerRequired = false
    do { try noLedgerCandidate.setKnowledgeGraphEnabled(true) }
    catch AgentSessionError.knowledge(.causalLedgerRequired) { ledgerRequired = true }
    catch {}
    check("knowledge activation requires causal ledger", ledgerRequired && !noLedgerCandidate.knowledgeGraphEnabled)

    var noSocial = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 2, memoryPolicy: .bounded(maxEntries: 4)
        ),
        agents: [knowledgeSmokeAgent("agent_a", x: 0)],
        simulationID: try! AgentSimulationID(validating: "civ41-no-social"),
        causalLedgerPolicy: .bounded(maxEvents: 32)
    )
    let noSocialSequence = noSocial.causalLedgerSnapshot().summary.latestSequence
    var socialRequired = false
    do { try noSocial.setKnowledgeGraphEnabled(true) }
    catch AgentSessionError.knowledge(.socialRequired) { socialRequired = true }
    catch {}
    check("knowledge activation requires local social carrier", socialRequired && !noSocial.knowledgeGraphEnabled)
    check("refused activation is atomic", noSocial.causalLedgerSnapshot().summary.latestSequence == noSocialSequence)

    let refusalConfiguration = try! AgentKnowledgeConfiguration(
        maximumPropositions: 4,
        maximumEvidence: 4,
        maximumClaims: 4,
        maximumUnderstandings: 4,
        maximumBeliefs: 2,
        maximumRevisions: 4,
        maximumEvidencePerAgent: 2,
        maximumClaimsPerAgent: 2,
        maximumUnderstandingsPerAgent: 2,
        maximumBeliefsPerAgent: 1,
        maximumRevisionsPerAgent: 2
    )
    var capacityRefusal = knowledgeSmokeSession(
        id: "civ41-capacity-refusal",
        agents: [
            knowledgeSmokeAgent("agent_a", x: 0),
            knowledgeSmokeAgent("agent_b", x: 1),
            knowledgeSmokeAgent("agent_c", x: 20),
        ],
        knowledgeConfiguration: refusalConfiguration
    )
    _ = knowledgeSmokeDirectMessage(
        session: &capacityRefusal,
        senderID: "agent_a", senderX: 0,
        recipientID: "agent_b", targetX: 2,
        resource: .wood, fingerprint: 90
    )
    let capacityBytesBefore = try! capacityRefusal.durableStateBytes()
    var capacityWasRefused = false
    do {
        _ = try capacityRefusal.advanceTick(perceptions: [
            knowledgeSmokePerception(
                observerID: "agent_c", observerX: 20, targetX: 21,
                resource: .stone, fingerprint: 91
            )
        ])
    } catch AgentSessionError.knowledge(.capacityReached("beliefs")) {
        capacityWasRefused = true
    } catch {}
    check("pinned belief capacity fails closed", capacityWasRefused)
    check("capacity refusal is an exact atomic no-op",
          try! capacityRefusal.durableStateBytes() == capacityBytesBefore)

    let agents = [
        knowledgeSmokeAgent("agent_a", x: 0),
        knowledgeSmokeAgent("agent_b", x: 1),
        knowledgeSmokeAgent("agent_c", x: 10),
        knowledgeSmokeAgent("agent_d", x: 11),
        knowledgeSmokeAgent("agent_e", x: 30),
    ]
    var session = knowledgeSmokeSession(id: "civ41-decisive", agents: agents)
    let physicalBaseline = session.snapshot()
    let hearsay = knowledgeSmokeDirectMessage(
        session: &session,
        senderID: "agent_a", senderX: 0,
        recipientID: "agent_b", targetX: 2,
        resource: .wood, fingerprint: 100
    )
    var graph = session.knowledgeSnapshot()
    let directBelief = knowledgeSmokeBelief(ownerID: "agent_a", snapshot: graph)!
    let hearsayBelief = knowledgeSmokeBelief(ownerID: "agent_b", snapshot: graph)!
    let directUnderstanding = knowledgeSmokeUnderstanding(
        belief: directBelief, snapshot: graph
    )!
    let hearsayUnderstanding = knowledgeSmokeUnderstanding(
        belief: hearsayBelief, snapshot: graph
    )!
    if case .evidence = directUnderstanding.basis {
        check("direct evidence forms evidence-based understanding", true)
    } else {
        check("direct evidence forms evidence-based understanding", false)
    }
    if case .sourceClaim = hearsayUnderstanding.basis {
        check("hearsay forms attributed-claim understanding", true)
    } else {
        check("hearsay forms attributed-claim understanding", false)
    }
    check("direct evidence and hearsay retain distinct authority", directUnderstanding.basis != hearsayUnderstanding.basis && graph.evidence.count == 1 && graph.claims.count == 1)
    check("claim retains original source and recipient", graph.claims[0].sourceAgentID.rawValue == "agent_a" && graph.claims[0].recipientID.rawValue == "agent_b")
    check("repetition does not erase source evidence", graph.claims[0].sourceEvidenceID == graph.evidence[0].evidenceID)
    check("unreached agent has no magical knowledge", !graph.evidence.contains { $0.observerID.rawValue == "agent_e" } && !graph.claims.contains { $0.recipientID.rawValue == "agent_e" } && knowledgeSmokeBelief(ownerID: "agent_e", snapshot: graph) == nil)

    _ = knowledgeSmokeDirectMessage(
        session: &session,
        senderID: "agent_c", senderX: 10,
        recipientID: "agent_d", targetX: 2,
        resource: .stone, fingerprint: 200
    )
    graph = session.knowledgeSnapshot()
    let aBeforeRevision = knowledgeSmokeBelief(ownerID: "agent_a", snapshot: graph)!
    let bBeforeRevision = knowledgeSmokeBelief(ownerID: "agent_b", snapshot: graph)!
    let cBelief = knowledgeSmokeBelief(ownerID: "agent_c", snapshot: graph)!
    check("individuals can disagree on one structured question", aBeforeRevision.questionKey == cBelief.questionKey && aBeforeRevision.propositionID != cBelief.propositionID && !graph.disagreements.isEmpty)
    check("fallible hearsay remains accepted beside contradictory direct evidence", bBeforeRevision.stance == .accepted && bBeforeRevision.propositionID != cBelief.propositionID)
    check("new direct evidence does not overwrite unrelated agents", aBeforeRevision.propositionID == directBelief.propositionID && knowledgeSmokeBelief(ownerID: "agent_e", snapshot: graph) == nil)
    check("knowledge path cannot mutate physical authority", session.snapshot().conservation == physicalBaseline.conservation && session.snapshot().agents.map(\.resourceInventory) == physicalBaseline.agents.map(\.resourceInventory))

    let revisionResult = knowledgeSmokeVerify(
        session: &session,
        belief: hearsay,
        resource: .stone,
        fingerprint: 200
    )
    graph = session.knowledgeSnapshot()
    let bAfterRevision = knowledgeSmokeBelief(ownerID: "agent_b", snapshot: graph)!
    let bRevisionUnderstanding = knowledgeSmokeUnderstanding(
        belief: bAfterRevision, snapshot: graph
    )!
    check("legitimate direct check revises one individual", revisionResult == .contradicted && bAfterRevision.propositionID == cBelief.propositionID && bAfterRevision.revisionCount == 2)
    check("revision is attributed to contradictory observation", bRevisionUnderstanding.interpretation == .revisedByContradictoryObservation)
    check("revision leaves source and remote individual unchanged", knowledgeSmokeBelief(ownerID: "agent_a", snapshot: graph)?.propositionID == aBeforeRevision.propositionID && knowledgeSmokeBelief(ownerID: "agent_e", snapshot: graph) == nil)
    check("current belief retains complete live provenance chain", {
        guard case let .evidence(evidenceID) = bRevisionUnderstanding.basis else {
            return false
        }
        return graph.evidence.contains { $0.evidenceID == evidenceID && $0.authority == .validatedSocialVerification }
    }())

    let knowledgeKinds = Set(session.causalLedgerSnapshot().events.map(\.kind))
    check("causal ledger distinguishes CIV-41 transition layers", [
        AgentCausalEventKind.knowledgeGraphInitialized,
        .knowledgeEvidenceAcquired,
        .knowledgeClaimReceived,
        .knowledgeUnderstandingFormed,
        .knowledgeBeliefRevised,
    ].allSatisfy { knowledgeKinds.contains($0) })

    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let decoded = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    let restored = try! AgentSimulationSession.restoring(decoded)
    check("CIV-41 checkpoint uses schema 36", checkpoint.schemaVersion == 36)
    check("same-process codec restore preserves graph exactly", restored.knowledgeSnapshot() == graph)
    check("restore duplicates no claims understandings beliefs or revisions", restored.knowledgeSummary() == session.knowledgeSummary())
    check("restored durable bytes are exact", try! restored.durableStateBytes() == session.durableStateBytes())

    let legacyCheckpoint = civ39PublishedSchema35CompatibilityCheckpoint()
    let legacyBytes = try! AgentCheckpointCodec.encode(legacyCheckpoint)
    let decodedLegacy = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: legacyBytes
    )
    let restoredLegacy = try! AgentSimulationSession.restoring(decodedLegacy)
    check("published schema-35 checkpoint still validates and restores", decodedLegacy.schemaVersion == 35 && restoredLegacy.populationScaleSnapshot().enabled)
    check("schema-35 restore fabricates no knowledge provenance", !restoredLegacy.knowledgeGraphEnabled && restoredLegacy.knowledgeSnapshot().evidence.isEmpty && restoredLegacy.knowledgeSnapshot().claims.isEmpty)
    check("schema-35 round trip remains byte exact", try! AgentCheckpointCodec.encode(try! restoredLegacy.makeCheckpoint()) == legacyBytes)

    var replaySession = knowledgeSmokeSession(
        id: "civ41-replay",
        agents: [
            knowledgeSmokeAgent("agent_a", x: 0),
            knowledgeSmokeAgent("agent_b", x: 1),
        ],
        enableKnowledge: false
    )
    let replayBase = try! replaySession.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayBase, session: replaySession
    )
    _ = try! recorder.apply(
        .setKnowledgeGraphEnabled(true, configuration: .live),
        to: &replaySession
    )
    _ = try! recorder.apply(.advanceTick(
        perceptions: [knowledgeSmokePerception(
            observerID: "agent_a", observerX: 0, targetX: 2,
            resource: .wood, fingerprint: 700
        )],
        physicalObservations: []
    ), to: &replaySession)
    for _ in 0..<8 where replaySession.knowledgeSnapshot().claims.isEmpty {
        _ = try! recorder.apply(
            .advanceTick(perceptions: [], physicalObservations: []),
            to: &replaySession
        )
    }
    let replayJournal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "civ41-replay")!
    )
    let replayedA = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: replayJournal
    )
    let replayedB = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: replayJournal
    )
    check("replay journal upgrades honestly to schema 36", replayJournal.manifest.schemaVersion == 36)
    let replayedBytes = try! replayedA.session.durableStateBytes()
    let directReplayBytes = try! replaySession.durableStateBytes()
    check("replay reproduces exact CIV-41 durable state", replayedA.report.verified && replayedBytes == directReplayBytes)
    check("repeated replay duplicates no graph record", replayedA.session.knowledgeSnapshot() == replayedB.session.knowledgeSnapshot() && replayedA.session.knowledgeSummary() == replaySession.knowledgeSummary())

    let boundedA = knowledgeBoundRun(reversed: false)
    let boundedB = knowledgeBoundRun(reversed: true)
    check("deterministic compaction exercises every historical bound", boundedA.evictionCounts.claims > 0 && boundedA.evictionCounts.understandings > 0 && boundedA.evictionCounts.revisions > 0)
    check("compaction preserves current belief provenance", boundedA.beliefs.allSatisfy { belief in
        boundedA.understandings.contains {
            $0.understandingID == belief.basisUnderstandingID
        }
    })
    check("compaction does not promote claims into evidence", boundedA.claims.allSatisfy { claim in
        boundedA.evidence.contains { $0.evidenceID == claim.sourceEvidenceID }
    } && boundedA.evidence.allSatisfy { $0.authority != .canonicalCivilizationState })
    check("compaction is independent of registration order", boundedA == boundedB)

    let scaleAgents = (0..<24).map { index in
        knowledgeSmokeAgent(
            String(format: "scale_%02d", index),
            x: index < 2 ? index : 100 + index * 3
        )
    }
    var scale = knowledgeSmokeSession(id: "civ41-scale", agents: scaleAgents)
    _ = knowledgeSmokeDirectMessage(
        session: &scale,
        senderID: "scale_00", senderX: 0,
        recipientID: "scale_01", targetX: 2,
        resource: .wood, fingerprint: 901
    )
    let scaleGraph = scale.knowledgeSnapshot()
    let scaleOwners = Set(scaleGraph.beliefs.map(\.ownerID.rawValue))
    check("24-agent scale path remains local to causal pair", scaleOwners == ["scale_00", "scale_01"] && scaleGraph.claims.count == 1 && scaleGraph.evidence.count == 1)
    check("scale path creates no agents-times-agents state", scaleGraph.beliefs.count == 2 && scaleGraph.understandings.count == 2 && scaleGraph.claims.count < scale.snapshot().agents.count)

    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "civ41-world",
            storageIdentity: "civ41-test-storage",
            seed: 141,
            dimension: 0,
            observedWorldTick: session.tick
        )
    )
    check("Observer advances to schema 14 for knowledge", observer.header.schemaVersion == 14)
    check("Observer exposes read-only owner source and disagreement state", observer.knowledge == graph && observer.knowledge?.claims.first?.sourceAgentID.rawValue == "agent_a" && observer.knowledge?.beliefs.contains { $0.ownerID.rawValue == "agent_b" } == true)
    check("Observer capture mutates no cognitive authority", session.knowledgeSnapshot() == graph)

    var disabled = session
    try! disabled.setKnowledgeGraphEnabled(false)
    let disabledGraph = disabled.knowledgeSnapshot()
    let disabledObserver = disabled.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "civ41-world",
            storageIdentity: "civ41-test-storage",
            seed: 141,
            dimension: 0,
            observedWorldTick: disabled.tick
        )
    )
    check("disabled graph retains durable current cognitive state",
          !disabledGraph.enabled
            && disabledGraph.beliefs == graph.beliefs
            && (try! disabled.makeCheckpoint()).schemaVersion == 36)
    check("Observer keeps initialized disabled graph inspectable",
          disabledObserver.header.schemaVersion == 14
            && disabledObserver.knowledge == disabledGraph)

    print("  CIV41_DECISIVE direct=\(graph.evidence.count) claims=\(graph.claims.count) beliefs=\(graph.beliefs.count) disagreements=\(graph.disagreements.count) revisions=\(graph.revisions.count) digest=\(graph.digest)")
    print("  CIV41_BOUNDS propositions=\(boundedA.propositions.count)/\(boundedA.configuration!.maximumPropositions) evidence=\(boundedA.evidence.count)/\(boundedA.configuration!.maximumEvidence) claims=\(boundedA.claims.count)/\(boundedA.configuration!.maximumClaims) understandings=\(boundedA.understandings.count)/\(boundedA.configuration!.maximumUnderstandings) revisions=\(boundedA.revisions.count)/\(boundedA.configuration!.maximumRevisions) evicted=\(boundedA.evictionCounts)")
    print("  CIV41_SCALE agents=\(scale.snapshot().agents.count) informed=\(scaleOwners.count) evidence=\(scaleGraph.evidence.count) claims=\(scaleGraph.claims.count)")
    print("  CIV41_RESTART schema=\(checkpoint.schemaVersion) digest=\(checkpoint.semanticDigest.rawValue) graph=\(restored.knowledgeSnapshot().digest)")
    print("  CIV41_REPLAY records=\(replayJournal.records.count) schema=\(replayJournal.manifest.schemaVersion) verified=\(replayedA.report.verified)")
}
