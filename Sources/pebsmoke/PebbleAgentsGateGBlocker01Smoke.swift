import Foundation
import PebbleAgents

private let dialectInnovator = AgentID(rawValue: "dialect_innovator")!
private let dialectLearner = AgentID(rawValue: "dialect_learner")!
private let dialectWitness = AgentID(rawValue: "dialect_witness")!
private let dialectRemote = AgentID(rawValue: "dialect_remote")!
private let dialectWoodSense = AgentLanguageSenseID(
    rawValue: "value.resource.wood"
)!
private let dialectSenseIDs = [
    AgentLanguageSenseID(rawValue: "referent.worldCell")!,
    AgentLanguageSenseID(
        rawValue: "predicate.world.resource.presence"
    )!,
    dialectWoodSense,
]

private func dialectAgent(
    _ id: AgentID,
    x: Int,
    lethalWhenEnabled: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id.rawValue,
        state: "idle",
        position: position,
        needs: AgentNeeds(
            hunger: lethalWhenEnabled ? 1 : -10,
            fatigue: 0,
            curiosity: 0,
            safety: 1
        ),
        health: lethalWhenEnabled ? 10 : 100,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "Gate G Blocker 01 fixture",
            startedAtTick: 0,
            urgency: 0
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
        totalDistanceReducedTowardHome: 0,
        survivalProgress: lethalWhenEnabled ? AgentSurvivalProgress(
            status: .starving,
            consecutiveCriticalHungerTicks: 2
        ) : nil
    )
}

private func dialectObservation(_ observerID: AgentID)
    -> AgentPerceptionInput {
    AgentPerceptionInput(
        agentId: observerID.rawValue,
        socialResourceObservations: [AgentResourceObservation(
            resource: .wood,
            target: AgentPosition(x: 2, y: 64, z: 0),
            direction: observerID == dialectRemote ? .west : .east,
            distanceManhattan: observerID == dialectRemote ? 4 : 2,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: 47_001
        )]
    )
}

private func dialectPrepared(
    id: String,
    maximumAssociations: Int = 64,
    maximumCommunications: Int = 64,
    maximumOralTransmissions: Int = 32,
    causalMaximumEvents: Int = 16_384,
    lethalInnovator: Bool = false
) -> (AgentSimulationSession, AgentKnowledgePropositionID) {
    let social = try! AgentSocialConfiguration(
        communicationRadius: 2,
        minimumTrustToVerify: -100,
        claimLifetimeTicks: 64,
        messageLifetimeTicks: 48,
        maximumFactsPerAgent: 8,
        maximumBeliefsPerAgent: 8,
        maximumTrustRelations: 32,
        maximumRetainedMessages: 32,
        shareCooldownTicks: 1
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 4_701,
            nearbyRadius: 16,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            socialConfiguration: social
        ),
        agents: [
            dialectAgent(
                dialectInnovator,
                x: 0,
                lethalWhenEnabled: lethalInnovator
            ),
            dialectAgent(dialectLearner, x: 1),
            dialectAgent(dialectWitness, x: -1),
            dialectAgent(dialectRemote, x: 6),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: causalMaximumEvents)
    )
    try! session.setSocialEnabled(true)
    try! session.setKnowledgeGraphEnabled(true)
    _ = try! session.advanceTick(perceptions: [
        dialectObservation(dialectInnovator),
        dialectObservation(dialectRemote),
    ])
    let beliefs = session.knowledgeSnapshot().beliefs
    let local = beliefs.first {
        $0.ownerID == dialectInnovator && $0.stance == .accepted
    }!
    let remote = beliefs.first {
        $0.ownerID == dialectRemote && $0.stance == .accepted
    }!
    precondition(
        local.propositionID == remote.propositionID,
        "dialect fixture must share semantic authority"
    )
    try! session.setLanguageEnabled(
        true,
        configuration: try! AgentLanguageConfiguration(
            maximumLexicalAssociations: maximumAssociations,
            maximumLexicalAssociationsPerAgent: 16,
            maximumCommunicationRecords: maximumCommunications,
            exposuresRequiredForLearning: 1
        ),
        pack: .frenchReference
    )
    try! session.setOralTransmissionEnabled(
        true,
        configuration: try! AgentOralConfiguration(
            maximumTransmissionRecords: maximumOralTransmissions,
            maximumFaithfulDistance: 2
        )
    )
    for agentID in [
        dialectInnovator, dialectLearner, dialectWitness, dialectRemote,
    ] {
        try! session.seedLanguagePrior(
            for: agentID,
            senseIDs: dialectSenseIDs
        )
    }
    return (session, local.propositionID)
}

private func establishDialectInnovationSupports(
    session: inout AgentSimulationSession,
    propositionID: AgentKnowledgePropositionID
) {
    _ = try! session.transmitOralClaim(
        speakerID: dialectInnovator,
        recipientID: dialectLearner,
        propositionID: propositionID,
        renderingMode: .deterministicCompositional
    )
    _ = try! session.transmitOralClaim(
        speakerID: dialectInnovator,
        recipientID: dialectWitness,
        propositionID: propositionID,
        renderingMode: .deterministicCompositional
    )
}

private func dialectMortalityPrepared() -> (
    AgentSimulationSession,
    AgentKnowledgePropositionID,
    AgentID,
    AgentID,
    AgentID
) {
    let origin = AgentID(rawValue: "agent_0")!
    let learner = AgentID(rawValue: "agent_1")!
    let witness = AgentID(rawValue: "agent_2")!
    let social = try! AgentSocialConfiguration(
        communicationRadius: 2,
        minimumTrustToVerify: -100,
        claimLifetimeTicks: 64,
        messageLifetimeTicks: 48,
        maximumFactsPerAgent: 8,
        maximumBeliefsPerAgent: 8,
        maximumTrustRelations: 32,
        maximumRetainedMessages: 32,
        shareCooldownTicks: 1
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 4_702,
            nearbyRadius: 16,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            socialConfiguration: social
        ),
        agents: [
            dialectAgent(origin, x: 0, lethalWhenEnabled: true),
            dialectAgent(learner, x: 1),
            dialectAgent(witness, x: 2),
        ],
        simulationID: try! AgentSimulationID(
            validating: "gate-g-blocker-01-mortality"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.setSocialEnabled(true)
    try! session.setKnowledgeGraphEnabled(true)
    _ = try! session.advanceTick(perceptions: [dialectObservation(origin)])
    let propositionID = session.knowledgeSnapshot().beliefs.first {
        $0.ownerID == origin && $0.stance == .accepted
    }!.propositionID
    try! session.setLanguageEnabled(
        true,
        configuration: try! AgentLanguageConfiguration(
            maximumLexicalAssociations: 64,
            maximumLexicalAssociationsPerAgent: 16,
            maximumCommunicationRecords: 64,
            exposuresRequiredForLearning: 1
        ),
        pack: .frenchReference
    )
    try! session.setOralTransmissionEnabled(
        true,
        configuration: try! AgentOralConfiguration(
            maximumTransmissionRecords: 32,
            maximumFaithfulDistance: 2
        )
    )
    for agentID in [origin, learner, witness] {
        try! session.seedLanguagePrior(
            for: agentID,
            senseIDs: dialectSenseIDs
        )
    }
    _ = try! session.transmitOralClaim(
        speakerID: origin,
        recipientID: learner,
        propositionID: propositionID,
        renderingMode: .deterministicCompositional
    )
    _ = try! session.transmitOralClaim(
        speakerID: origin,
        recipientID: witness,
        propositionID: propositionID,
        renderingMode: .deterministicCompositional
    )
    return (session, propositionID, origin, learner, witness)
}

private func dialectResignedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutateLanguage: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    var language = durable["languageState"] as! [String: Any]
    mutateLanguage(&language)
    durable["languageState"] = language
    let mutatedBytes = try! JSONSerialization.data(
        withJSONObject: durable,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let mutatedState = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self,
        from: mutatedBytes
    )
    let canonicalBytes = try! AgentCheckpointCodec.encode(mutatedState)
    let canonical = try! JSONSerialization.jsonObject(
        with: canonicalBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let digest = AgentCheckpointDigest.sha256(canonicalBytes)
    let simulationDigest = AgentCheckpointDigest.sha256(
        Data(simulationID.utf8)
    )
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] =
        "checkpoint-\(simulationDigest.rawValue.prefix(12))"
        + "-t\(tick)-\(digest.rawValue.prefix(16))"
    return try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func dialectRestoreRefusal(
    _ checkpoint: AgentSessionCheckpoint
) -> String? {
    do {
        _ = try AgentSimulationSession.restoring(checkpoint)
        return nil
    } catch {
        return String(describing: error)
    }
}

private func dialectJournal(
    manifest: AgentReplayJournalManifest,
    records: [AgentReplayRecord]
) -> AgentReplayJournal {
    let bytes = try! AgentReplayCodec.encodeRecords(records)
    return AgentReplayJournal(
        manifest: AgentReplayJournalManifest(
            schemaVersion: manifest.schemaVersion,
            name: manifest.name,
            baseCheckpointID: manifest.baseCheckpointID,
            baseCheckpointDigest: manifest.baseCheckpointDigest,
            simulationID: manifest.simulationID,
            initialTick: manifest.initialTick,
            recordCount: records.count,
            droppedRecordCount: manifest.droppedRecordCount,
            replayable: manifest.replayable,
            nonReplayableReason: manifest.nonReplayableReason,
            operationsStorageDigest: AgentCheckpointDigest.sha256(bytes),
            operationsByteLength: bytes.count
        ),
        records: records
    )
}

private func applyDialectCarrierStep(
    session: inout AgentSimulationSession,
    carrierID: AgentID,
    dx: Int
) {
    let movements = session.snapshot().agents.sorted {
        $0.id < $1.id
    }.map { agent -> AgentVerifiedPhysicalMovement in
        let moving = agent.id == carrierID.rawValue
        let destination = moving ? AgentPosition(
            x: agent.position.x + dx,
            y: agent.position.y,
            z: agent.position.z
        ) : agent.position
        let before = abs(agent.position.x - agent.homePosition.x)
            + abs(agent.position.y - agent.homePosition.y)
            + abs(agent.position.z - agent.homePosition.z)
        let after = abs(destination.x - agent.homePosition.x)
            + abs(destination.y - agent.homePosition.y)
            + abs(destination.z - agent.homePosition.z)
        return AgentVerifiedPhysicalMovement(
            kind: .reconciliation,
            outcome: AgentMovementOutcome(
                agentId: agent.id,
                tick: session.tick,
                status: moving ? .moved : .notRequested,
                fromPosition: agent.position,
                toPosition: destination,
                requestedDirection: nil,
                requestedDX: 0,
                requestedDY: 0,
                requestedDZ: 0,
                appliedDX: moving ? dx : 0,
                appliedDY: 0,
                appliedDZ: 0,
                goalKind: agent.currentGoal.kind,
                actionReason: "verified dialect carrier step",
                resolutionReason: moving
                    ? "accepted verified dialect carrier step"
                    : "no accepted movement",
                worldTickObserved: session.tick,
                distanceFromHomeBefore: before,
                distanceFromHomeAfter: after,
                distanceReducedTowardHome: max(0, before - after)
            )
        )
    }
    try! session.applyVerifiedPhysicalMovements(movements)
}

func runPebbleAgentsGateGBlocker01Smoke() {
    section("Gate G Blocker 01 causal dialect divergence")

    var (base, propositionID) = dialectPrepared(
        id: "gate-g-blocker-01",
        causalMaximumEvents: 128
    )
    let initialWood = base.languageSnapshot().lexicalAssociations.filter {
        $0.senseID == dialectWoodSense && $0.competence == .known
    }
    check(
        "one seed pack begins every relevant individual on one convention",
        initialWood.count == 4
            && Set(initialWood.map(\.form)) == ["bois"]
            && base.languageSnapshot().lexicalInnovations.isEmpty
    )
    establishDialectInnovationSupports(
        session: &base,
        propositionID: propositionID
    )
    let replayBase = try! base.makeCheckpoint()
    var recorded = base
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayBase,
        session: recorded
    )
    let innovationResult = try! recorder.apply(
        .innovateLanguageLexicalForm(
            agentID: dialectInnovator,
            senseID: dialectWoodSense,
            acceptedEffect: nil
        ),
        to: &recorded
    )
    let innovation = innovationResult.languageLexicalInnovationResult!
    check(
        "product logic derives a non-pack form from exact local use history",
        innovation.sourceForm == "bois"
            && innovation.evolvedForm != innovation.sourceForm
            && innovation.supportingTransmissionIDs.count == 2
            && !innovation.evolvedForm.contains("fixture")
    )
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &recorded
    )
    _ = try! recorder.apply(
        .transmitOralClaim(
            speakerID: dialectInnovator,
            recipientID: dialectLearner,
            propositionID: propositionID,
            renderingMode: .deterministicCompositional,
            acceptedEffect: nil
        ),
        to: &recorded
    )

    let innovatorSurface = try! recorded.realizeLanguageSemanticContent(
        for: dialectInnovator,
        propositionID: propositionID
    )
    let learnerSurface = try! recorded.realizeLanguageSemanticContent(
        for: dialectLearner,
        propositionID: propositionID
    )
    let remoteSurface = try! recorded.realizeLanguageSemanticContent(
        for: dialectRemote,
        propositionID: propositionID
    )
    let innovatorWood = innovatorSurface.lexicalUses.first {
        $0.senseID == dialectWoodSense
    }!
    let learnerWood = learnerSurface.lexicalUses.first {
        $0.senseID == dialectWoodSense
    }!
    let remoteWood = remoteSurface.lexicalUses.first {
        $0.senseID == dialectWoodSense
    }!
    check(
        "legitimate local exposure teaches the evolved convention",
        learnerWood.form == innovation.evolvedForm
            && learnerWood.innovationID == innovation.innovationID
    )
    let separatedPopulationDiverges =
        innovatorWood.form == learnerWood.form
            && remoteWood.form == "bois"
            && remoteWood.innovationID == nil
    let sharedSemantics = innovatorSurface.semanticContent.senses
        == remoteSurface.semanticContent.senses
    let distinctSurfaces = innovatorSurface.rendering.text
        != remoteSurface.rendering.text
    check(
        "separated population retains the original form for the same sense",
        separatedPopulationDiverges && sharedSemantics && distinctSurfaces
    )

    var (
        cultural, culturalPropositionID, culturalOrigin,
        _, culturalWitness
    ) = dialectMortalityPrepared()
    _ = try! cultural.innovateLanguageLexicalForm(
        for: culturalOrigin,
        senseID: dialectWoodSense
    )
    let culturalLanguageBefore = cultural.languageSnapshot()
    try! cultural.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 1)
    )
    try! cultural.setDistributedCultureEnabled(true)
    let culturalRoot = try! cultural.originateCulturalPractice(
        operationID: "gate-g-unrelated-root",
        originatorID: culturalWitness,
        form: .ritual(try! AgentCultureRitualPattern(
            context: .remembrance,
            orderedSteps: [.assemble, .speakNames, .disperse],
            minimumParticipants: 1
        ))
    )
    _ = try! cultural.createCulturalVariation(
        operationID: "gate-g-unrelated-variation",
        creatorID: culturalWitness,
        parentPracticeID: culturalRoot.practice.practiceID,
        form: .ritual(try! AgentCultureRitualPattern(
            context: .remembrance,
            orderedSteps: [
                .assemble, .exchangeToken, .speakNames, .disperse,
            ],
            minimumParticipants: 1
        ))
    )
    let remoteAfterCulture = try! cultural.realizeLanguageSemanticContent(
        for: culturalWitness,
        propositionID: culturalPropositionID
    ).lexicalUses.first { $0.senseID == dialectWoodSense }
    let culturalCheckpoint = try! cultural.makeCheckpoint()
    let culturalRestored = try! AgentSimulationSession.restoring(
        culturalCheckpoint
    )
    check(
        "unrelated CIV-47 variation grants no lexical variation",
        cultural.distributedCultureSnapshot().individuals.contains {
            $0.agentID == culturalWitness && $0.stances.count == 2
        }
            && remoteAfterCulture?.form == "bois"
            && remoteAfterCulture?.innovationID == nil
            && cultural.languageSnapshot() == culturalLanguageBefore
            && culturalCheckpoint.schemaVersion
                == AgentCheckpointSchema.lexicalDivergenceVersion
            && (try! culturalRestored.durableStateBytes())
                == (try! cultural.durableStateBytes())
    )

    var forbiddenRemote = recorded
    let remoteBefore = try! forbiddenRemote.durableStateBytes()
    let remoteRefused: Bool
    do {
        _ = try forbiddenRemote.communicateLanguageSemanticContent(
            speakerID: dialectInnovator,
            recipientID: dialectRemote,
            propositionID: propositionID,
            renderingMode: .deterministicCompositional
        )
        remoteRefused = false
    } catch {
        remoteRefused = true
    }
    check(
        "generic remote communication cannot grant evolved competence",
        remoteRefused
            && (try! forbiddenRemote.durableStateBytes()) == remoteBefore
            && forbiddenRemote.languageSnapshot().lexicalAssociations
                .filter { $0.ownerID == dialectRemote }
                .allSatisfy { $0.innovationID == nil }
    )

    var transported = recorded
    try! transported.setAutonomousActivityEnabled(true)
    try! transported.setLongDistanceCommunicationEnabled(true)
    let transport = try! transported.beginLongDistanceCommunication(
        authorID: dialectInnovator,
        carrierID: dialectLearner,
        destinationID: dialectRemote,
        propositionID: propositionID,
        renderingMode: .deterministicCompositional
    )
    for _ in 0..<16 {
        let current = transported.longDistanceCommunicationSnapshot()
            .transports.first { $0.transportID == transport.transportID }!
        if current.status != .inTransit { break }
        applyDialectCarrierStep(
            session: &transported,
            carrierID: dialectLearner,
            dx: 1
        )
    }
    let arrived = transported.longDistanceCommunicationSnapshot()
        .transports.first { $0.transportID == transport.transportID }!
    _ = try! transported.deliverLongDistanceCommunication(
        transportID: transport.transportID,
        renderingMode: .deterministicCompositional
    )
    let transportedRemote = try! transported
        .realizeLanguageSemanticContent(
            for: dialectRemote,
            propositionID: propositionID
        ).lexicalUses.first { $0.senseID == dialectWoodSense }
    let transportedCheckpoint = try! transported.makeCheckpoint()
    let transportedRestored = try! AgentSimulationSession.restoring(
        transportedCheckpoint
    )
    check(
        "embodied CIV-44 carrier can legitimately deliver the evolved form",
        arrived.status == .arrived
            && transportedRemote?.form == innovation.evolvedForm
            && transportedRemote?.innovationID == innovation.innovationID
            && (try! transportedRestored.durableStateBytes())
                == (try! transported.durableStateBytes())
    )

    var written = recorded
    try! written.setWritingEnabled(true, worldID: "gate-g-world")
    try! written.seedWritingEducationalPrior(for: dialectInnovator)
    let writingCell = written.snapshot().agents.first {
        $0.id == dialectInnovator.rawValue
    }!.position
    let writingPlan = try! written.prepareWriting(
        authorID: dialectInnovator,
        propositionID: propositionID,
        materialID: 47_001,
        dimension: "overworld",
        cell: writingCell
    )
    let writingReceipt = AgentWritingPhysicalReceipt(
        worldID: writingPlan.worldID,
        dimension: writingPlan.dimension,
        cell: writingPlan.cell,
        blockKey: "oak_sign",
        artifactID: writingPlan.artifactID,
        materialID: writingPlan.materialID,
        contentDigest: writingPlan.contentDigest,
        lines: writingPlan.lines,
        actorID: dialectInnovator,
        actorPosition: writingCell,
        observedAtTick: written.tick
    )
    let artifact = try! written.acceptWriting(
        writingPlan,
        receipt: writingReceipt
    )
    let writtenWood = artifact.plan.realization.lexicalUses.first {
        $0.senseID == dialectWoodSense
    }
    let writtenCheckpoint = try! written.makeCheckpoint()
    let writtenRestored = try! AgentSimulationSession.restoring(
        writtenCheckpoint
    )
    check(
        "CIV-45 material writing preserves the evolved lexical authority",
        writtenWood?.form == innovation.evolvedForm
            && writtenWood?.innovationID == innovation.innovationID
            && (try! writtenRestored.durableStateBytes())
                == (try! written.durableStateBytes())
            && writtenRestored.languageSnapshot().lexicalInnovations
                == [innovation]
    )

    let duplicateBefore = try! recorded.durableStateBytes()
    let duplicate = try! recorded.innovateLanguageLexicalForm(
        for: dialectInnovator,
        senseID: dialectWoodSense
    )
    check(
        "duplicate retry returns one authority without publication",
        duplicate == innovation
            && (try! recorded.durableStateBytes()) == duplicateBefore
            && recorded.languageSnapshot().lexicalInnovations.count == 1
    )

    let checkpoint = try! recorded.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check(
        "schema-43 checkpoint preserves exact divergent language state",
        checkpoint.schemaVersion
            == AgentCheckpointSchema.lexicalDivergenceVersion
            && restored.languageSnapshot() == recorded.languageSnapshot()
            && (try! restored.durableStateBytes())
                == (try! recorded.durableStateBytes())
    )

    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "gate-g-blocker-01")!
    )
    let replayedA = try! AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: journal
    )
    let replayedB = try! AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: journal
    )
    let recordedEffectPresent: Bool
    if case let .innovateLanguageLexicalForm(_, _, effect?) =
        journal.records.first?.operation {
        recordedEffectPresent = effect.evolvedForm == innovation.evolvedForm
            && effect.decisionDigest == innovation.decisionDigest
    } else {
        recordedEffectPresent = false
    }
    check(
        "recorded-effect replay verifies and reproduces the exact variant",
        journal.manifest.schemaVersion
            == AgentReplaySchema.lexicalDivergenceVersion
            && recordedEffectPresent
            && replayedA.report.verified
            && replayedB.report.verified
            && (try! replayedA.session.durableStateBytes())
                == (try! recorded.durableStateBytes())
            && replayedA.session.languageSnapshot()
                == replayedB.session.languageSnapshot()
    )

    let firstRecord = journal.records[0]
    let forgedEffect = AgentLanguageLexicalInnovationAcceptedEffect(
        evolvedForm: "fixture-selected-final-form",
        decisionDigest: innovation.decisionDigest
    )
    let forgedRecord = AgentReplayRecord(
        schemaVersion: firstRecord.schemaVersion,
        simulationID: firstRecord.simulationID,
        recordSequence: firstRecord.recordSequence,
        operation: .innovateLanguageLexicalForm(
            agentID: dialectInnovator,
            senseID: dialectWoodSense,
            acceptedEffect: forgedEffect
        ),
        expectedTickBefore: firstRecord.expectedTickBefore,
        preStateSemanticDigest: firstRecord.preStateSemanticDigest,
        postStateSemanticDigest: firstRecord.postStateSemanticDigest,
        causalSequenceBefore: firstRecord.causalSequenceBefore,
        causalSequenceAfter: firstRecord.causalSequenceAfter,
        causalDigestAfter: firstRecord.causalDigestAfter
    )
    let forgedJournal = dialectJournal(
        manifest: journal.manifest,
        records: [forgedRecord] + Array(journal.records.dropFirst())
    )
    let forgedReplay = try! AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: forgedJournal
    )
    check(
        "a harness-selected final form is rejected before replay publication",
        !forgedReplay.report.verified
            && forgedReplay.report.recordsApplied == 0
            && (forgedReplay.report.divergence?.reason.contains(
                "replayEffectMismatch"
            ) ?? false)
    )

    let noAuthority = dialectResignedCheckpoint(checkpoint) { language in
        var evolution = language["lexicalEvolution"] as! [String: Any]
        evolution["innovations"] = []
        evolution["evictedInnovationCount"] = 1
        language["lexicalEvolution"] = evolution
    }
    let rebound = dialectResignedCheckpoint(checkpoint) { language in
        var evolution = language["lexicalEvolution"] as! [String: Any]
        var innovations = evolution["innovations"] as! [[String: Any]]
        innovations[0]["senseID"] = "value.resource.stone"
        evolution["innovations"] = innovations
        language["lexicalEvolution"] = evolution
    }
    let stale = dialectResignedCheckpoint(checkpoint) { language in
        var evolution = language["lexicalEvolution"] as! [String: Any]
        var innovations = evolution["innovations"] as! [[String: Any]]
        let supports = innovations[0]["supports"]
            as! [[String: Any]]
        innovations[0]["supports"] = Array(supports.reversed())
        evolution["innovations"] = innovations
        language["lexicalEvolution"] = evolution
    }
    let substitutedCarrier = dialectResignedCheckpoint(checkpoint) {
        language in
        var receipts = language["exposureReceipts"] as! [[String: Any]]
        let index = receipts.firstIndex {
            $0["localOralAuthority"] != nil
        }!
        var authority = receipts[index]["localOralAuthority"]
            as! [String: Any]
        authority["oralProvenanceDigest"] = String(repeating: "0", count: 64)
        receipts[index]["localOralAuthority"] = authority
        language["exposureReceipts"] = receipts
    }
    check(
        "restore rejects fabricated alternatives without retained authority",
        dialectRestoreRefusal(noAuthority) != nil
    )
    check(
        "restore rejects rebinding a valid form to another semantic sense",
        dialectRestoreRefusal(rebound) != nil
    )
    check(
        "restore rejects stale or substituted innovation provenance",
        dialectRestoreRefusal(stale) != nil
    )
    check(
        "restore rejects substituted local carrier authority",
        dialectRestoreRefusal(substitutedCarrier) != nil
    )

    var (bounded, boundedPropositionID) = dialectPrepared(
        id: "gate-g-blocker-01-bounds",
        maximumAssociations: 12
    )
    establishDialectInnovationSupports(
        session: &bounded,
        propositionID: boundedPropositionID
    )
    let boundedBefore = try! bounded.durableStateBytes()
    let boundedRefused: Bool
    do {
        _ = try bounded.innovateLanguageLexicalForm(
            for: dialectInnovator,
            senseID: dialectWoodSense
        )
        boundedRefused = false
    } catch {
        boundedRefused = true
    }
    check(
        "lexical bound refuses atomically before innovation authority",
        boundedRefused
            && (try! bounded.durableStateBytes()) == boundedBefore
            && bounded.languageSnapshot().lexicalInnovations.isEmpty
    )

    var compacted = recorded
    for _ in 0..<256 {
        _ = try! compacted.advanceTick()
    }
    let compactedCheckpoint = try! compacted.makeCheckpoint()
    let compactedRestored = try! AgentSimulationSession.restoring(
        compactedCheckpoint
    )
    let compactedLedger = compacted.causalLedgerSnapshot().summary
    check(
        "causal compaction preserves rather than self-authorizes divergence",
        compactedLedger.droppedEventCount > 0
            && compactedRestored.languageSnapshot()
                == compacted.languageSnapshot()
            && compactedRestored.languageSnapshot().lexicalInnovations
                == [innovation]
    )

    var (supportCompacted, supportCompactionPropositionID) = dialectPrepared(
        id: "gate-g-blocker-01-support-compaction",
        maximumCommunications: 8,
        maximumOralTransmissions: 4
    )
    establishDialectInnovationSupports(
        session: &supportCompacted,
        propositionID: supportCompactionPropositionID
    )
    let supportCompactionInnovation = try! supportCompacted
        .innovateLanguageLexicalForm(
            for: dialectInnovator,
            senseID: dialectWoodSense
        )
    for ordinal in 0..<12 {
        _ = try! supportCompacted.transmitOralClaim(
            speakerID: dialectInnovator,
            recipientID: ordinal.isMultiple(of: 2)
                ? dialectLearner : dialectWitness,
            propositionID: supportCompactionPropositionID,
            renderingMode: .deterministicCompositional
        )
    }
    let supportCompactedLanguage = supportCompacted.languageSnapshot()
    let supportCompactedOral = supportCompacted.oralTransmissionSnapshot()
    let supportTransmissionIDs = Set(
        supportCompactionInnovation.supports.map(\.transmissionID)
    )
    let supportCommunicationIDs = Set(
        supportCompactionInnovation.supports.map(
            \.languageCommunicationID
        )
    )
    let supportCompactionCheckpoint = try! supportCompacted.makeCheckpoint()
    let supportCompactionRestored = try! AgentSimulationSession.restoring(
        supportCompactionCheckpoint
    )
    check(
        "bounded support receipts survive legitimate carrier-row compaction",
        supportCompactedOral.evictedTransmissionCount > 0
            && supportCompactedLanguage.evictedCommunicationCount > 0
            && supportCompactedOral.transmissions.allSatisfy {
                !supportTransmissionIDs.contains($0.transmissionID)
            }
            && supportCompactedLanguage.communications.allSatisfy {
                !supportCommunicationIDs.contains($0.communicationID)
            }
            && supportCompactedLanguage.lexicalInnovations
                == [supportCompactionInnovation]
            && supportCompactionRestored.languageSnapshot()
                == supportCompactedLanguage
            && supportCompactionRestored.oralTransmissionSnapshot()
                == supportCompactedOral
    )
    let selfAuthorizingCompacted = dialectResignedCheckpoint(
        supportCompactionCheckpoint
    ) { language in
        var evolution = language["lexicalEvolution"] as! [String: Any]
        var innovations = evolution["innovations"] as! [[String: Any]]
        innovations[0]["supports"] = []
        evolution["innovations"] = innovations
        language["lexicalEvolution"] = evolution
    }
    check(
        "dropped carrier rows cannot make current state self-authorizing",
        dialectRestoreRefusal(selfAuthorizingCompacted) != nil
    )

    var (
        mortality, mortalityPropositionID, mortalityOrigin,
        mortalityLearner, mortalityWitness
    ) = dialectMortalityPrepared()
    let mortalityInnovation = try! mortality.innovateLanguageLexicalForm(
        for: mortalityOrigin,
        senseID: dialectWoodSense
    )
    _ = try! mortality.transmitOralClaim(
        speakerID: mortalityOrigin,
        recipientID: mortalityLearner,
        propositionID: mortalityPropositionID,
        renderingMode: .deterministicCompositional
    )
    let historyBeforeDeath = mortality.languageSnapshot().communications
    try! mortality.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    mortality.setSurvivalEnabled(true)
    try! mortality.setMortalityEnabled(true)
    for _ in 0..<64 where mortality.snapshot().agents.contains(where: {
        $0.id == mortalityOrigin.rawValue
    }) {
        _ = try! mortality.advanceTick()
    }
    let afterDeath = mortality.languageSnapshot()
    check(
        "mortality retires competence without magical transfer or history rewrite",
        !mortality.snapshot().agents.contains {
            $0.id == mortalityOrigin.rawValue
        }
            && !afterDeath.lexicalAssociations.contains {
                $0.ownerID == mortalityOrigin
            }
            && afterDeath.lexicalAssociations.contains {
                $0.ownerID == mortalityLearner
                    && $0.innovationID == mortalityInnovation.innovationID
            }
            && afterDeath.lexicalAssociations.filter {
                $0.ownerID == mortalityWitness
            }.allSatisfy { $0.innovationID == nil }
            && afterDeath.communications == historyBeforeDeath
            && afterDeath.lexicalInnovations == [mortalityInnovation]
    )
    let mortalityCheckpoint = try! mortality.makeCheckpoint()
    check(
        "post-mortality schema-43 history restores exactly",
        (try! AgentSimulationSession.restoring(mortalityCheckpoint))
            .languageSnapshot() == afterDeath
    )

    check(
        "causal ledger identifies lexical innovation as a CIV-42 transition",
        recorded.causalLedgerSnapshot().events.contains {
            $0.kind == .languageLexicalInnovated
                && $0.origin == .languageTransition
                && $0.actorID == dialectInnovator
        }
    )
    print(
        "  GATE_G_BLOCKER_01_DECISIVE sense=\(dialectWoodSense.rawValue)"
            + " original=bois evolved=\(innovation.evolvedForm)"
            + " learner=\(learnerWood.form) remote=\(remoteWood.form)"
    )
    print(
        "  GATE_G_BLOCKER_01_DURABLE schema=\(checkpoint.schemaVersion)"
            + " replaySchema=\(journal.manifest.schemaVersion)"
            + " replayRecords=\(journal.records.count)"
            + " dropped=\(compactedLedger.droppedEventCount)"
            + " oralEvicted=\(supportCompactedOral.evictedTransmissionCount)"
            + " languageEvicted="
            + "\(supportCompactedLanguage.evictedCommunicationCount)"
    )
    print(
        "  GATE_G_BLOCKER_01_HOSTILE fabricated=REJECTED"
            + " rebound=REJECTED stale=REJECTED carrier=REJECTED"
            + " compactedSelfAuthority=REJECTED replayInjection=REJECTED"
    )
}
