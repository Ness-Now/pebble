import Foundation
import PebbleAgents

private let oralA = AgentID(rawValue: "agent_0")!
private let oralB = AgentID(rawValue: "agent_1")!
private let oralC = AgentID(rawValue: "agent_2")!
private let oralD = AgentID(rawValue: "agent_3")!

private let oralWoodSenseIDs = [
    AgentLanguageSenseID(rawValue: "referent.worldCell")!,
    AgentLanguageSenseID(
        rawValue: "predicate.world.resource.presence"
    )!,
    AgentLanguageSenseID(rawValue: "value.resource.wood")!,
]

private let oralSmokeConfiguration = try! AgentOralConfiguration(
    maximumTransmissionRecords: 32,
    maximumFaithfulDistance: 1
)

private func oralSmokeAgent(
    _ id: AgentID,
    x: Int,
    lethalWhenEnabled: Bool = false,
    initialHunger: Double? = nil,
    initialHealth: Int? = nil
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id.rawValue,
        state: "idle",
        position: position,
        needs: AgentNeeds(
            hunger: initialHunger ?? (lethalWhenEnabled ? 0.39 : -10),
            fatigue: 0,
            curiosity: 0,
            safety: 1
        ),
        health: initialHealth ?? (lethalWhenEnabled ? 26 : 100),
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "CIV-43 fixture",
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
        survivalProgress: nil
    )
}

private func oralResourceObservation(
    _ observerID: AgentID,
    resource: AgentResourceKind
)
    -> AgentPerceptionInput {
    AgentPerceptionInput(
        agentId: observerID.rawValue,
        socialResourceObservations: [AgentResourceObservation(
            resource: resource,
            target: AgentPosition(x: 2, y: 64, z: 0),
            direction: observerID == oralA ? .east : .west,
            distanceManhattan: observerID == oralA ? 2 : 1,
            quantityAvailable: 1,
            source: resource == .sandboxResource
                ? .sandboxFixture : .naturalWorld,
            expectedBlockFingerprint: resource == .sandboxResource
                ? nil : 43_001
        )]
    )
}

private func oralSmokePrepared(
    id: String,
    reversed: Bool = false,
    oralConfiguration: AgentOralConfiguration = oralSmokeConfiguration,
    causalMaximumEvents: Int = 16_384,
    sourceResource: AgentResourceKind = .wood,
    lethalID: AgentID? = nil,
    minimumTrustToVerify: Int = -100
) -> (AgentSimulationSession, AgentKnowledgePropositionID) {
    let agents = [
        oralSmokeAgent(oralA, x: 0, lethalWhenEnabled: lethalID == oralA),
        oralSmokeAgent(oralB, x: 1, lethalWhenEnabled: lethalID == oralB),
        oralSmokeAgent(oralC, x: 3, lethalWhenEnabled: lethalID == oralC),
    ]
    let social = try! AgentSocialConfiguration(
        communicationRadius: 2,
        minimumTrustToVerify: minimumTrustToVerify,
        claimLifetimeTicks: 64,
        messageLifetimeTicks: 48,
        maximumFactsPerAgent: 8,
        maximumBeliefsPerAgent: 8,
        maximumTrustRelations: 32,
        maximumRetainedMessages: 32,
        shareCooldownTicks: 1
    )
    let survival = lethalID == nil ? AgentSurvivalConfiguration.live : try!
        AgentSurvivalConfiguration(
            hungerPerTick: 1,
            fatiguePerTick: AgentSurvivalConfiguration.live.fatiguePerTick,
            hungryThreshold: AgentSurvivalConfiguration.live.hungryThreshold,
            criticalHungerThreshold:
                AgentSurvivalConfiguration.live.criticalHungerThreshold,
            hungerRecoveryThreshold:
                AgentSurvivalConfiguration.live.hungerRecoveryThreshold,
            fatigueThreshold: AgentSurvivalConfiguration.live.fatigueThreshold,
            fatigueRecoveryThreshold:
                AgentSurvivalConfiguration.live.fatigueRecoveryThreshold,
            foodNutrition: AgentSurvivalConfiguration.live.foodNutrition,
            restRecoveryPerTick:
                AgentSurvivalConfiguration.live.restRecoveryPerTick,
            starvationGraceTicks: 0,
            starvationDamagePerTick: 100
        )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 143,
            nearbyRadius: 16,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: survival,
            socialConfiguration: social
        ),
        agents: reversed ? Array(agents.reversed()) : agents,
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: causalMaximumEvents)
    )
    try! session.setSocialEnabled(true)
    try! session.setKnowledgeGraphEnabled(true)
    _ = try! session.advanceTick(perceptions: [
        oralResourceObservation(oralA, resource: sourceResource),
        oralResourceObservation(oralC, resource: sourceResource),
    ])
    let before = session.knowledgeSnapshot()
    let source = before.beliefs.first {
        $0.ownerID == oralA && $0.stance == .accepted
    }!
    precondition(
        !before.beliefs.contains { $0.ownerID == oralB },
        "CIV-43 fixture accidentally pre-acquired B's belief"
    )
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
        true, configuration: oralConfiguration
    )
    try! session.seedLanguagePrior(
        for: oralA, senseIDs: oralWoodSenseIDs
    )
    return (session, source.propositionID)
}

private func oralSmokeChain(
    id: String,
    reversed: Bool = false,
    oralConfiguration: AgentOralConfiguration = oralSmokeConfiguration,
    causalMaximumEvents: Int = 16_384
) -> (
    AgentSimulationSession,
    AgentOralTransmission,
    AgentOralTransmission,
    AgentKnowledgePropositionID
) {
    var (session, sourceID) = oralSmokePrepared(
        id: id,
        reversed: reversed,
        oralConfiguration: oralConfiguration,
        causalMaximumEvents: causalMaximumEvents
    )
    let hop1 = try! session.transmitOralClaim(
        speakerID: oralA,
        recipientID: oralB,
        propositionID: sourceID,
        renderingMode: .deterministicCompositional
    )
    let bBelief = session.knowledgeSnapshot().beliefs.first {
        $0.ownerID == oralB
    }!
    let hop2 = try! session.transmitOralClaim(
        speakerID: oralB,
        recipientID: oralC,
        propositionID: bBelief.propositionID,
        renderingMode: .deterministicCompositional
    )
    return (session, hop1, hop2, sourceID)
}

private func oralSmokeResignedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutateDurable: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutateDurable(&durable)
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

private func oralSmokeJSONEventID(_ value: Any) -> String {
    let event = value as! [String: Any]
    let sequence = (event["sequence"] as! NSNumber).uint64Value
    return "\(event["simulationID"] as! String)/event-"
        + String(format: "%020llu", sequence)
}

private func oralSmokeJSONEventSequence(_ value: Any) -> UInt64 {
    let event = value as! [String: Any]
    return (event["sequence"] as! NSNumber).uint64Value
}

private func oralSmokeJSONPosition(_ value: Any) -> String {
    let position = value as! [String: Any]
    return "\(position["x"] as! Int),\(position["y"] as! Int),"
        + "\(position["z"] as! Int)"
}

private func oralSmokeJSONReplacing(
    _ value: Any,
    replacements: [String: String]
) -> Any {
    if let text = value as? String {
        return replacements[text] ?? text
    }
    if let values = value as? [Any] {
        return values.map {
            oralSmokeJSONReplacing($0, replacements: replacements)
        }
    }
    if let values = value as? [String: Any] {
        return Dictionary(uniqueKeysWithValues: values.map { key, item in
            (
                key,
                oralSmokeJSONReplacing(item, replacements: replacements)
            )
        })
    }
    return value
}

private func oralSmokeJSONEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    let left = try! JSONSerialization.data(
        withJSONObject: lhs,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let right = try! JSONSerialization.data(
        withJSONObject: rhs,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    return left == right
}

private func oralSmokeJSONProvenanceDigest(
    _ row: [String: Any]
) -> String {
    let transmitted = row["transmittedSemanticContent"] as! [String: Any]
    let interpreted = row["interpretedSemanticContent"] as! [String: Any]
    let locality = row["locality"] as! [String: Any]
    let text = [
        "oral-transmission-provenance-v1",
        row["transmissionID"] as! String,
        row["speakerID"] as! String,
        row["recipientID"] as! String,
        row["sourceBeliefID"] as! String,
        oralSmokeJSONEventID(row["sourceBeliefRevisionEventID"]!),
        row["sourceAuthorityID"] as! String,
        row["languageCommunicationID"] as! String,
        oralSmokeJSONEventID(row["languageCommunicationEventID"]!),
        transmitted["digest"] as! String,
        interpreted["digest"] as! String,
        row["outcome"] as! String,
        row["decisionDigest"] as! String,
        oralSmokeJSONPosition(locality["speakerPosition"]!),
        oralSmokeJSONPosition(locality["recipientPosition"]!),
        String(locality["distance"] as! Int),
        String(locality["authorizedRadius"] as! Int),
        String(locality["observedAtTick"] as! Int),
        oralSmokeJSONEventID(row["receiptEventID"]!),
        row["recipientClaimID"] as! String,
        oralSmokeJSONEventID(row["recipientClaimEventID"]!),
        row["recipientUnderstandingID"] as! String,
        row["recipientBeliefID"] as! String,
        oralSmokeJSONEventID(row["recipientBeliefRevisionEventID"]!),
        String(row["transmittedAtTick"] as! Int),
    ].joined(separator: "|")
    return AgentCheckpointDigest.sha256(Data(text.utf8)).rawValue
}

private func oralSmokeJSONCanonicalTransmission(
    _ row: [String: Any]
) -> String {
    let transmitted = row["transmittedSemanticContent"] as! [String: Any]
    let interpreted = row["interpretedSemanticContent"] as! [String: Any]
    let locality = row["locality"] as! [String: Any]
    return [
        row["transmissionID"] as! String,
        row["speakerID"] as! String,
        row["recipientID"] as! String,
        row["sourceBeliefID"] as! String,
        oralSmokeJSONEventID(row["sourceBeliefRevisionEventID"]!),
        row["sourceAuthorityID"] as! String,
        row["languageCommunicationID"] as! String,
        oralSmokeJSONEventID(row["languageCommunicationEventID"]!),
        transmitted["digest"] as! String,
        interpreted["digest"] as! String,
        row["outcome"] as! String,
        row["decisionDigest"] as! String,
        oralSmokeJSONPosition(locality["speakerPosition"]!),
        oralSmokeJSONPosition(locality["recipientPosition"]!),
        String(locality["distance"] as! Int),
        String(locality["authorizedRadius"] as! Int),
        String(locality["observedAtTick"] as! Int),
        oralSmokeJSONEventID(row["receiptEventID"]!),
        row["recipientClaimID"] as! String,
        oralSmokeJSONEventID(row["recipientClaimEventID"]!),
        row["recipientUnderstandingID"] as! String,
        row["recipientBeliefID"] as! String,
        oralSmokeJSONEventID(row["recipientBeliefRevisionEventID"]!),
        String(row["transmittedAtTick"] as! Int),
        row["provenanceDigest"] as! String,
    ].joined(separator: "|")
}

private func oralSmokeJSONBoundaryDigest(
    rows: [[String: Any]], evicted: Int
) -> String {
    let body = rows.sorted {
        ($0["transmissionID"] as! String)
            < ($1["transmissionID"] as! String)
    }.map(oralSmokeJSONCanonicalTransmission).joined(separator: ";")
    return AgentCheckpointDigest.sha256(Data(
        ("oral-provenance-boundary-v1|" + body
            + "|evicted=\(evicted)").utf8
    )).rawValue
}

private func oralSmokeRestoreError(
    _ checkpoint: AgentSessionCheckpoint
) -> String? {
    do {
        _ = try AgentSimulationSession.restoring(checkpoint)
        return nil
    } catch AgentSessionError.oral(.invalidState(let reason)) {
        return "oral:\(reason)"
    } catch AgentSessionError.knowledge(.invalidState(let reason)) {
        return "knowledge:\(reason)"
    } catch AgentSessionError.language(.invalidState(let reason)) {
        return "language:\(reason)"
    } catch {
        return "unexpected:\(error)"
    }
}

private func oralSmokeRefusal(
    _ name: String,
    session: AgentSimulationSession,
    operation: (inout AgentSimulationSession) throws -> Void,
    matches: (Error) -> Bool
) {
    let before = try! session.durableStateDigest()
    var candidate = session
    do {
        try operation(&candidate)
        check(name, false, "accepted")
    } catch {
        check(name, matches(error), "\(error)")
    }
    check(
        "\(name) is an exact atomic no-op",
        try! candidate.durableStateDigest() == before
    )
}

private func oralSmokeJournal(
    from manifest: AgentReplayJournalManifest,
    records: [AgentReplayRecord],
    schemaVersion: Int? = nil
) -> AgentReplayJournal {
    let bytes = try! AgentReplayCodec.encodeRecords(records)
    return AgentReplayJournal(
        manifest: AgentReplayJournalManifest(
            schemaVersion: schemaVersion ?? manifest.schemaVersion,
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

private func oralSmokeReplayHostileProof(
    checkpoint: AgentSessionCheckpoint,
    journal: AgentReplayJournal
) {
    guard journal.records.count == 2,
          case let .transmitOralClaim(
            _, _, _, _, firstEffect?
          ) = journal.records[0].operation,
          case let .transmitOralClaim(
            speakerID, recipientID, propositionID, renderingMode, _
          ) = journal.records[1].operation else {
        preconditionFailure("CIV-43 replay fixture shape")
    }
    let original = journal.records[1]
    let forged = AgentReplayRecord(
        schemaVersion: original.schemaVersion,
        simulationID: original.simulationID,
        recordSequence: original.recordSequence,
        operation: .transmitOralClaim(
            speakerID: speakerID,
            recipientID: recipientID,
            propositionID: propositionID,
            renderingMode: renderingMode,
            acceptedEffect: firstEffect
        ),
        expectedTickBefore: original.expectedTickBefore,
        preStateSemanticDigest: original.preStateSemanticDigest,
        postStateSemanticDigest: original.postStateSemanticDigest,
        causalSequenceBefore: original.causalSequenceBefore,
        causalSequenceAfter: original.causalSequenceAfter,
        causalDigestAfter: original.causalDigestAfter
    )
    let mutated = oralSmokeJournal(
        from: journal.manifest,
        records: [journal.records[0], forged]
    )
    let result = try! AgentSessionReplayer.replay(
        checkpoint: checkpoint, journal: mutated
    )
    check("re-signed replay cannot reroll or replace accepted distortion",
        !result.report.verified
            && result.report.recordsApplied == 1
            && (result.report.divergence?.reason.contains(
                "replayEffectMismatch"
            ) ?? false))

    let future = oralSmokeJournal(
        from: journal.manifest,
        records: journal.records,
        schemaVersion: AgentReplaySchema.oralTransmissionVersion + 1
    )
    let futureRejected: Bool
    do {
        _ = try AgentSessionReplayer.replay(
            checkpoint: checkpoint, journal: future
        )
        futureRejected = false
    } catch AgentReplayError.unsupportedSchema(let version) {
        futureRejected = version
            == AgentReplaySchema.oralTransmissionVersion + 1
    } catch {
        futureRejected = false
    }
    check("future replay schema 39 is refused", futureRejected)
}

func runPebbleAgentsOralTransmissionSmoke() {
    section("CIV-43 oral transmission and distortion V1")

    let (session, hop1, hop2, sourceID) = oralSmokeChain(
        id: "civ43-decisive-chain"
    )
    let knowledge = session.knowledgeSnapshot()
    let language = session.languageSnapshot()
    let oral = session.oralTransmissionSnapshot()
    let bBelief = knowledge.beliefs.first { $0.ownerID == oralB }!
    let cBelief = knowledge.beliefs.first { $0.ownerID == oralC }!
    let cRevision = knowledge.revisions.first {
        $0.ownerID == oralC
            && $0.revisionEventID == cBelief.lastRevisionEventID
    }!
    let bClaim = knowledge.claims.first {
        $0.claimID == hop1.recipientClaimID
    }!
    let cClaim = knowledge.claims.first {
        $0.claimID == hop2.recipientClaimID
    }!

    check("checkpoint schema advances to 38", try! session.makeCheckpoint()
        .schemaVersion == AgentCheckpointSchema.oralTransmissionVersion)
    check("faithful first hop preserves semantic content",
        hop1.outcome == .faithful
            && hop1.transmittedSemanticContent
                == hop1.interpretedSemanticContent)
    check("first hop creates genuine B acquisition",
        bBelief.propositionID == sourceID
            && bBelief.basisUnderstandingID
                == hop1.recipientUnderstandingID)
    check("first hop attributes immediate speaker A",
        bClaim.sourceAgentID == oralA
            && bClaim.recipientID == oralB
            && bClaim.oralTransmissionID == hop1.transmissionID)
    check("B retransmits from B's own current CIV-41 belief",
        hop2.speakerID == oralB
            && hop2.sourceBeliefID == bBelief.beliefID
            && hop2.sourceBeliefRevisionEventID
                == bBelief.lastRevisionEventID)
    check("second hop genuinely distorts semantic content",
        hop2.outcome == .distanceDistorted
            && hop2.transmittedSemanticContent
                != hop2.interpretedSemanticContent)
    check("second hop attributes immediate speaker B, never A",
        cClaim.sourceAgentID == oralB
            && cClaim.sourceAgentID != oralA
            && cClaim.recipientID == oralC)
    check("C undergoes a real CIV-41 proposition revision",
        cRevision.previousPropositionID == sourceID
            && cRevision.propositionID == cBelief.propositionID
            && cBelief.propositionID
                == hop2.interpretedSemanticContent.sourcePropositionID
            && cBelief.revisionCount == 2,
        "previous=\(cRevision.previousPropositionID?.rawValue ?? "nil") current=\(cRevision.propositionID.rawValue) belief=\(cBelief.propositionID.rawValue) count=\(cBelief.revisionCount)")
    check("oral misinformation leaves authoritative observation intact",
        knowledge.evidence.filter {
            $0.observerID == oralA || $0.observerID == oralC
        }.allSatisfy { $0.propositionID == sourceID })
    check("lexical learning and epistemic acquisition are distinct",
        language.lexicalAssociations.contains {
            $0.ownerID == oralB
                && $0.source == .exposure
                && $0.competence == .known
        }
            && bClaim.acquisitionEventID
                != language.communications[0].communicationEventID)
    check("oral provenance is bounded and boundary-authenticated",
        oral.transmissions.count == 2
            && oral.provenanceBoundary != nil)
    oralSmokeDistortionRuleProof()

    let ordered = oralSmokeChain(id: "civ43-order", reversed: false).0
    let reversed = oralSmokeChain(id: "civ43-order", reversed: true).0
    check("registration order does not change oral history",
        ordered.oralTransmissionSnapshot().digest
            == reversed.oralTransmissionSnapshot().digest
            && ordered.knowledgeSnapshot().digest
                == reversed.knowledgeSnapshot().digest)

    let checkpoint = try! session.makeCheckpoint()
    let bytes = try! AgentCheckpointCodec.encode(checkpoint)
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("schema-38 exact restart preserves oral graph",
        restored.oralTransmissionSnapshot() == oral)
    check("schema-38 restart remains byte exact",
        try! AgentCheckpointCodec.encode(restored.makeCheckpoint()) == bytes)

    var replaySession = oralSmokePrepared(id: "civ43-replay").0
    let replayBase = try! replaySession.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayBase, session: replaySession
    )
    let replayHop1 = try! recorder.apply(.transmitOralClaim(
        speakerID: oralA,
        recipientID: oralB,
        propositionID: sourceIDFor(session: replaySession, ownerID: oralA),
        renderingMode: .deterministicCompositional,
        acceptedEffect: nil
    ), to: &replaySession).oralTransmissionResult!
    let replayB = replaySession.knowledgeSnapshot().beliefs.first {
        $0.ownerID == oralB
    }!
    _ = try! recorder.apply(.transmitOralClaim(
        speakerID: oralB,
        recipientID: oralC,
        propositionID: replayB.propositionID,
        renderingMode: .deterministicCompositional,
        acceptedEffect: nil
    ), to: &replaySession)
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "civ43-replay")!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: journal
    )
    check("replay schema advances to 38",
        journal.manifest.schemaVersion
            == AgentReplaySchema.oralTransmissionVersion)
    check("journal stores accepted distortion effect",
        journal.records.allSatisfy { record in
            if case let .transmitOralClaim(_, _, _, _, effect) =
                record.operation { return effect != nil }
            return true
        })
    check("replay applies recorded effects to exact durable state",
        replay.report.verified
            && replay.report.finalSemanticDigest
                == (try! replaySession.durableStateDigest()))
    check("repeated replay duplicates no oral state",
        try! AgentSessionReplayer.replay(
            checkpoint: replayBase, journal: journal
        ).report.finalSemanticDigest == replay.report.finalSemanticDigest)
    oralSmokeReplayHostileProof(checkpoint: replayBase, journal: journal)
    _ = replayHop1

    oralSmokeAdversarialProof(session: session, checkpoint: checkpoint)
    oralSmokeNegativeProof()
    oralSmokeCompactionProof()
    oralSmokeMortalityProof()
    oralSmokeTerminalCompactionProof()

    print(
        "  CIV43_HOP1 speaker=\(hop1.speakerID.rawValue) source=\(hop1.transmittedSemanticContent.sourcePropositionID.rawValue) transmitted=\(hop1.transmittedSemanticContent.digest) interpreted=\(hop1.interpretedSemanticContent.digest) recipientBelief=\(bBelief.propositionID.rawValue) claim=\(hop1.recipientClaimID.rawValue) event=\(hop1.receiptEventID.rawValue) outcome=\(hop1.outcome.rawValue)"
    )
    print(
        "  CIV43_HOP2 speaker=\(hop2.speakerID.rawValue) sourceBelief=\(hop2.sourceBeliefID.rawValue) source=\(hop2.transmittedSemanticContent.sourcePropositionID.rawValue) transmitted=\(hop2.transmittedSemanticContent.digest) interpreted=\(hop2.interpretedSemanticContent.digest) recipientBelief=\(cBelief.propositionID.rawValue) previous=\(sourceID.rawValue) claim=\(hop2.recipientClaimID.rawValue) event=\(hop2.receiptEventID.rawValue) outcome=\(hop2.outcome.rawValue)"
    )
    print(
        "  CIV43_RESTART schema=\(checkpoint.schemaVersion) digest=\(checkpoint.semanticDigest.rawValue) oral=\(oral.digest)"
    )
    print(
        "  CIV43_REPLAY records=\(journal.records.count) schema=\(journal.manifest.schemaVersion) verified=\(replay.report.verified)"
    )
}

private func sourceIDFor(
    session: AgentSimulationSession,
    ownerID: AgentID
) -> AgentKnowledgePropositionID {
    session.knowledgeSnapshot().beliefs.first {
        $0.ownerID == ownerID && $0.stance == .accepted
    }!.propositionID
}

private func oralSmokeDistortionRuleProof() {
    func distorted(
        id: String,
        resource: AgentResourceKind
    ) -> (AgentOralTransmission, String) {
        var (candidate, sourceID) = oralSmokePrepared(
            id: id, sourceResource: resource
        )
        _ = try! candidate.transmitOralClaim(
            speakerID: oralA,
            recipientID: oralB,
            propositionID: sourceID,
            renderingMode: .noRendering
        )
        let bSource = sourceIDFor(session: candidate, ownerID: oralB)
        let hop = try! candidate.transmitOralClaim(
            speakerID: oralB,
            recipientID: oralC,
            propositionID: bSource,
            renderingMode: .noRendering
        )
        let proposition = candidate.knowledgeSnapshot().propositions.first {
            $0.propositionID
                == hop.interpretedSemanticContent.sourcePropositionID
        }!
        let result: String
        switch proposition.value {
        case .absent: result = "absent"
        case let .resource(kind, _): result = kind.rawValue
        default: result = "unsupported"
        }
        return (hop, result)
    }

    let sameA = distorted(id: "civ43-rule-repeat", resource: .stone)
    let sameB = distorted(id: "civ43-rule-repeat", resource: .stone)
    check("identical distortion inputs reproduce the accepted effect",
        sameA.0.decisionDigest == sameB.0.decisionDigest
            && sameA.0.interpretedSemanticContent
                == sameB.0.interpretedSemanticContent)

    var outcomes: [String] = []
    var everyResultChangedAndSupported = true
    for ordinal in 0..<8 {
        let source: AgentResourceKind = ordinal.isMultiple(of: 2)
            ? .wood : .stone
        let result = distorted(
            id: "civ43-rule-variation-\(ordinal)",
            resource: source
        )
        outcomes.append(result.1)
        everyResultChangedAndSupported =
            everyResultChangedAndSupported
                && result.0.outcome == .distanceDistorted
                && result.1 != source.rawValue
                && ["absent", "wood", "stone"].contains(result.1)
    }
    check("general distortion excludes every source value",
        everyResultChangedAndSupported)
    check("different legitimate inputs exercise varied deterministic outputs",
        Set(outcomes).count >= 2)
    print(
        "  CIV43_DISTORTION_VARIATION inputs=wood,stone outputs=\(outcomes.joined(separator: ",")) repeat=\(sameA.1) digest=\(sameA.0.decisionDigest)"
    )
}

private func oralSmokeAdversarialProof(
    session: AgentSimulationSession,
    checkpoint: AgentSessionCheckpoint
) {
    let fabricated = oralSmokeResignedCheckpoint(checkpoint) { durable in
        var knowledge = durable["knowledgeGraphState"] as! [String: Any]
        var claims = knowledge["claims"] as! [[String: Any]]
        claims.removeFirst()
        knowledge["claims"] = claims
        durable["knowledgeGraphState"] = knowledge
    }
    check("Attack 1: re-signed acquisition without CIV-41 claim is rejected",
        oralSmokeRestoreError(fabricated) != nil)

    let changedResult = oralSmokeResignedCheckpoint(checkpoint) { durable in
        var oral = durable["oralTransmissionState"] as! [String: Any]
        var rows = oral["transmissions"] as! [[String: Any]]
        var semantic = rows[1]["interpretedSemanticContent"]
            as! [String: Any]
        let sourceSemantic = rows[0]["transmittedSemanticContent"]
            as! [String: Any]
        semantic["sourcePropositionID"] =
            sourceSemantic["sourcePropositionID"]
        rows[1]["interpretedSemanticContent"] = semantic
        oral["transmissions"] = rows
        durable["oralTransmissionState"] = oral
    }
    check("Attack 2: re-signed changed distortion result is rejected",
        oralSmokeRestoreError(changedResult) != nil)

    let forgedSpeaker = oralSmokeResignedCheckpoint(checkpoint) { durable in
        var oral = durable["oralTransmissionState"] as! [String: Any]
        var rows = oral["transmissions"] as! [[String: Any]]
        rows[1]["speakerID"] = oralA.rawValue
        oral["transmissions"] = rows
        durable["oralTransmissionState"] = oral
    }
    check("Attack 3: forged immediate-speaker attribution is rejected",
        oralSmokeRestoreError(forgedSpeaker) != nil)

    let mismatchedAuthority = oralSmokeResignedCheckpoint(checkpoint) {
        durable in
        var oral = durable["oralTransmissionState"] as! [String: Any]
        var rows = oral["transmissions"] as! [[String: Any]]
        rows[1]["sourceAuthorityID"] = rows[0]["sourceAuthorityID"]
        oral["transmissions"] = rows
        durable["oralTransmissionState"] = oral
    }
    check("Attack 4: mismatched CIV-41 source authority is rejected",
        oralSmokeRestoreError(mismatchedAuthority) != nil)

    check("valid re-signed control still restores",
        oralSmokeRestoreError(oralSmokeResignedCheckpoint(checkpoint) { _ in })
            == nil)

    let unsupportedFuture = oralSmokeResignedCheckpoint(checkpoint) {
        durable in
        durable["schemaVersion"] =
            AgentCheckpointSchema.oralTransmissionVersion + 1
    }
    let futureRejected: Bool
    do {
        _ = try AgentSimulationSession.restoring(unsupportedFuture)
        futureRejected = false
    } catch AgentCheckpointError.unsupportedSchema(let version) {
        futureRejected = version
            == AgentCheckpointSchema.oralTransmissionVersion + 1
    } catch {
        futureRejected = false
    }
    check("future checkpoint schema 39 is refused", futureRejected)
    _ = session
}

private func oralSmokeNegativeProof() {
    var (prepared, sourceID) = oralSmokePrepared(id: "civ43-negative")
    let noAuthorityID = sourceIDFor(session: prepared, ownerID: oralC)
    oralSmokeRefusal(
        "speaker lacking accepted CIV-41 authority is refused",
        session: prepared,
        operation: {
            _ = try $0.transmitOralClaim(
                speakerID: oralB,
                recipientID: oralC,
                propositionID: noAuthorityID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.language(.missingBeliefAuthority) = $0 {
                return true
            }
            return false
        }
    )
    oralSmokeRefusal(
        "unknown speaker is refused",
        session: prepared,
        operation: {
            _ = try $0.transmitOralClaim(
                speakerID: AgentID(rawValue: "oral-missing")!,
                recipientID: oralB,
                propositionID: sourceID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.oral(.unknownAgent) = $0 { return true }
            return false
        }
    )
    oralSmokeRefusal(
        "unknown recipient is refused",
        session: prepared,
        operation: {
            _ = try $0.transmitOralClaim(
                speakerID: oralA,
                recipientID: AgentID(rawValue: "oral-missing")!,
                propositionID: sourceID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.oral(.unknownAgent) = $0 { return true }
            return false
        }
    )
    oralSmokeRefusal(
        "self-transmission is refused",
        session: prepared,
        operation: {
            _ = try $0.transmitOralClaim(
                speakerID: oralA,
                recipientID: oralA,
                propositionID: sourceID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.oral(.invalidParticipant) = $0 {
                return true
            }
            return false
        }
    )
    oralSmokeRefusal(
        "non-local long-distance oral transmission is refused",
        session: prepared,
        operation: {
            _ = try $0.transmitOralClaim(
                speakerID: oralA,
                recipientID: oralC,
                propositionID: sourceID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.oral(.nonLocal) = $0 { return true }
            return false
        }
    )
    let (trustRefused, trustSourceID) = oralSmokePrepared(
        id: "civ43-local-authority-refused",
        minimumTrustToVerify: 1
    )
    oralSmokeRefusal(
        "in-radius oral transmission still requires Social authority",
        session: trustRefused,
        operation: {
            _ = try $0.transmitOralClaim(
                speakerID: oralA,
                recipientID: oralB,
                propositionID: trustSourceID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.oral(.localAuthorityRefused) = $0 {
                return true
            }
            return false
        }
    )

    let unsupportedID = AgentKnowledgePropositionID(
        rawValue: "proposition-unsupported-civ43-domain"
    )!
    oralSmokeRefusal(
        "unknown/unsupported oral semantic proposition is refused",
        session: prepared,
        operation: {
            _ = try $0.transmitOralClaim(
                speakerID: oralA,
                recipientID: oralB,
                propositionID: unsupportedID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.language(.unknownProposition) = $0 {
                return true
            }
            return false
        }
    )

    _ = try! prepared.transmitOralClaim(
        speakerID: oralA,
        recipientID: oralB,
        propositionID: sourceID,
        renderingMode: .noRendering
    )
    oralSmokeRefusal(
        "CIV-43 refuses removal of its social locality dependency",
        session: prepared,
        operation: { try $0.setSocialEnabled(false) },
        matches: {
            if case AgentSessionError.oral(.socialRequired) = $0 {
                return true
            }
            return false
        }
    )
    oralSmokeRefusal(
        "CIV-43 refuses removal of its CIV-41 dependency",
        session: prepared,
        operation: { try $0.setKnowledgeGraphEnabled(false) },
        matches: {
            if case AgentSessionError.oral(.knowledgeRequired) = $0 {
                return true
            }
            return false
        }
    )
    oralSmokeRefusal(
        "CIV-43 refuses removal of its CIV-42 dependency",
        session: prepared,
        operation: { try $0.setLanguageEnabled(false) },
        matches: {
            if case AgentSessionError.oral(.languageRequired) = $0 {
                return true
            }
            return false
        }
    )

    let social = try! AgentSocialConfiguration(
        communicationRadius: 2,
        minimumTrustToVerify: -100
    )
    var missingKnowledge = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 143,
            nearbyRadius: 8,
            resourceObservationRadius: 4,
            recentMemorySnapshotLimit: 4,
            memoryPolicy: .bounded(maxEntries: 16),
            socialConfiguration: social
        ),
        agents: [oralSmokeAgent(oralA, x: 0), oralSmokeAgent(oralB, x: 1)],
        simulationID: try! AgentSimulationID(
            validating: "civ43-missing-initialization"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 256)
    )
    try! missingKnowledge.setSocialEnabled(true)
    oralSmokeRefusal(
        "oral initialization without CIV-41 is refused",
        session: missingKnowledge,
        operation: {
            try $0.setOralTransmissionEnabled(true)
        },
        matches: {
            if case AgentSessionError.oral(.knowledgeRequired) = $0 {
                return true
            }
            return false
        }
    )
    try! missingKnowledge.setKnowledgeGraphEnabled(true)
    oralSmokeRefusal(
        "oral initialization without CIV-42 is refused",
        session: missingKnowledge,
        operation: {
            try $0.setOralTransmissionEnabled(true)
        },
        matches: {
            if case AgentSessionError.oral(.languageRequired) = $0 {
                return true
            }
            return false
        }
    )
}

private func oralSmokeTerminalCompactionPrepared(
    id: String
) -> (AgentSimulationSession, AgentKnowledgePropositionID) {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.1,
        fatiguePerTick: AgentSurvivalConfiguration.live.fatiguePerTick,
        hungryThreshold: 0.1,
        criticalHungerThreshold: 0.2,
        hungerRecoveryThreshold: 0.05,
        fatigueThreshold: AgentSurvivalConfiguration.live.fatigueThreshold,
        fatigueRecoveryThreshold:
            AgentSurvivalConfiguration.live.fatigueRecoveryThreshold,
        foodNutrition: AgentSurvivalConfiguration.live.foodNutrition,
        restRecoveryPerTick:
            AgentSurvivalConfiguration.live.restRecoveryPerTick,
        starvationGraceTicks: 0,
        starvationDamagePerTick: 25
    )
    let social = try! AgentSocialConfiguration(
        communicationRadius: 8,
        minimumTrustToVerify: -100,
        claimLifetimeTicks: 64,
        messageLifetimeTicks: 48,
        maximumFactsPerAgent: 8,
        maximumBeliefsPerAgent: 8,
        maximumTrustRelations: 32,
        maximumRetainedMessages: 32,
        shareCooldownTicks: 1
    )
    let agents = [
        oralSmokeAgent(
            oralA, x: 0, initialHunger: 0, initialHealth: 100
        ),
        oralSmokeAgent(
            oralB, x: 1, initialHunger: 0, initialHealth: 26
        ),
        oralSmokeAgent(
            oralC, x: 1, initialHunger: 0, initialHealth: 76
        ),
    ]
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 143,
            nearbyRadius: 16,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: survival,
            socialConfiguration: social
        ),
        agents: agents,
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 96)
    )
    try! session.setSocialEnabled(true)
    try! session.setKnowledgeGraphEnabled(
        true,
        configuration: try! AgentKnowledgeConfiguration(
            maximumPropositions: 8,
            maximumEvidence: 8,
            maximumClaims: 8,
            maximumUnderstandings: 8,
            maximumBeliefs: 3,
            maximumRevisions: 8,
            maximumEvidencePerAgent: 4,
            maximumClaimsPerAgent: 4,
            maximumUnderstandingsPerAgent: 4,
            maximumBeliefsPerAgent: 2,
            maximumRevisionsPerAgent: 4
        )
    )
    _ = try! session.advanceTick(perceptions: [
        oralResourceObservation(oralA, resource: .wood),
    ])
    let sourceID = sourceIDFor(session: session, ownerID: oralA)
    let bPosition = session.snapshot().agents.first {
        $0.id == oralB.rawValue
    }!.position
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: oralB.rawValue,
        socialResourceObservations: [AgentResourceObservation(
            resource: .stone,
            target: AgentPosition(
                x: bPosition.x + 3, y: bPosition.y, z: bPosition.z
            ),
            direction: .east,
            distanceManhattan: 3,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: 43_002
        )]
    )])
    try! session.setLanguageEnabled(
        true,
        configuration: try! AgentLanguageConfiguration(
            maximumLexicalAssociations: 32,
            maximumLexicalAssociationsPerAgent: 8,
            maximumCommunicationRecords: 16,
            exposuresRequiredForLearning: 1
        ),
        pack: .frenchReference
    )
    try! session.setOralTransmissionEnabled(
        true,
        configuration: try! AgentOralConfiguration(
            maximumTransmissionRecords: 8,
            maximumFaithfulDistance: 1
        )
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0),
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 8,
            maximumMigrationRecords: 8
        )
    )
    let aPosition = session.snapshot().agents.first {
        $0.id == oralA.rawValue
    }!.position
    try! session.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "civ43-terminal-source-food",
        agentId: oralA.rawValue,
        tick: session.tick,
        target: AgentPosition(
            x: aPosition.x, y: aPosition.y, z: aPosition.z + 1
        ),
        resource: .foodRaw,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .foodRaw, quantity: 1),
        reason: "bounded lifecycle fixture"
    ))
    return (session, sourceID)
}

private func oralSmokeTerminalCompactionOperations(
    sourceID: AgentKnowledgePropositionID
) -> [AgentReplayOperation] {
    [
        .transmitOralClaim(
            speakerID: oralA, recipientID: oralB,
            propositionID: sourceID, renderingMode: .noRendering,
            acceptedEffect: nil
        ),
        .setSurvivalEnabled(true),
        .setMortalityEnabled(true, configuration: .live),
        .advanceTick(perceptions: [], physicalObservations: []),
        .advanceTick(perceptions: [], physicalObservations: []),
        .advanceTick(perceptions: [], physicalObservations: []),
    ]
}

private func oralSmokeTerminalCompactionProof() {
    let id = "civ43-terminal-compaction"
    var (session, sourceID) = oralSmokeTerminalCompactionPrepared(id: id)
    let base = try! session.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: base, session: session
    )
    var controlBoundaryID = "none"
    var controlBoundaryDigest = "none"
    var controlBoundary: AgentOralProvenanceBoundary?
    var controlCheckpoint: AgentSessionCheckpoint?
    var controlOralDepartedBeliefID: AgentKnowledgeBeliefID?
    let operations = oralSmokeTerminalCompactionOperations(sourceID: sourceID)
    for (index, operation) in operations.enumerated() {
        _ = try! recorder.apply(operation, to: &session)
        if index == 5 {
            let controlKnowledge = session.knowledgeSnapshot()
            let controlOral = session.oralTransmissionSnapshot()
            if let boundary = controlOral.provenanceBoundary {
                controlBoundaryID = boundary.eventID.rawValue
                controlBoundaryDigest = boundary.digest
                controlBoundary = boundary
            }
            controlOralDepartedBeliefID = controlKnowledge.departedBeliefs
                .first { departed in
                    guard departed.ownerID == oralB else { return false }
                    if case .oralSourceClaim = departed.basis { return true }
                    return false
                }?.beliefID
            controlCheckpoint = try! session.makeCheckpoint()
            let controlBytes = try! AgentCheckpointCodec.encode(
                controlCheckpoint!
            )
            let controlRestored = try! AgentSimulationSession.restoring(
                controlCheckpoint!
            )
            check("terminal proof remains while within CIV-41 capacity",
                controlKnowledge.departedBeliefs.count == 2
                    && controlKnowledge.departedBeliefEvictionCount == 0
                    && controlKnowledge.departedBeliefs.allSatisfy {
                        $0.ownerID == oralB
                    }
                    && controlKnowledge.departedBeliefs.contains {
                        if case .oralSourceClaim = $0.basis { return true }
                        return false
                    }
                    && controlOral.transmissions.count == 1
                    && controlOral.transmissions[0].recipientID == oralB)
            check("within-capacity terminal oral control restarts exactly",
                try! AgentCheckpointCodec.encode(
                    controlRestored.makeCheckpoint()
                ) == controlBytes
                    && controlRestored.oralTransmissionSnapshot()
                        == controlOral)
        }
    }

    let cPosition = session.snapshot().agents.first {
        $0.id == oralC.rawValue
    }!.position
    let cObservation = AgentPerceptionInput(
        agentId: oralC.rawValue,
        socialResourceObservations: [
            AgentResourceObservation(
                resource: .wood,
                target: AgentPosition(
                    x: cPosition.x + 1, y: cPosition.y, z: cPosition.z
                ),
                direction: .east,
                distanceManhattan: 1,
                quantityAvailable: 1,
                source: .naturalWorld,
                expectedBlockFingerprint: 43_003
            ),
            AgentResourceObservation(
                resource: .stone,
                target: AgentPosition(
                    x: cPosition.x - 1, y: cPosition.y, z: cPosition.z
                ),
                direction: .west,
                distanceManhattan: 1,
                quantityAvailable: 1,
                source: .naturalWorld,
                expectedBlockFingerprint: 43_004
            ),
        ]
    )
    _ = try! recorder.apply(
        .advanceTick(
            perceptions: [cObservation], physicalObservations: []
        ),
        to: &session
    )
    let aHunger = session.snapshot().agents.first {
        $0.id == oralA.rawValue
    }!.needs.hunger
    _ = try! recorder.apply(
        .consumptionOutcome(AgentConsumptionOutcome(
            consumptionId: "civ43-terminal-source-survival",
            agentId: oralA.rawValue,
            tick: session.tick,
            resource: .foodRaw,
            quantity: 1,
            status: .succeeded,
            hungerBefore: aHunger,
            hungerAfter: 0,
            reason: "bounded lifecycle fixture"
        )),
        to: &session
    )
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &session
    )

    let knowledge = session.knowledgeSnapshot()
    let oral = session.oralTransmissionSnapshot()
    let mortality = session.mortalitySnapshot()
    let oldBoundary = controlBoundary!
    let emptyBoundary = oral.provenanceBoundary!
    let retainedCausalEvents = session.causalLedgerSnapshot().events
    let emptyBoundaryEvent = retainedCausalEvents.first {
        $0.eventID == emptyBoundary.eventID
    }!
    let newBoundaryStillRetained = retainedCausalEvents.contains {
        $0.eventID == emptyBoundary.eventID
    }
    check("terminal pressure finalizes both legitimate deaths",
        mortality.totalDeathCount == 2
            && session.snapshot().agents.map(\.id) == [oralA.rawValue])
    check("CIV-41 terminal bound performs a real deterministic eviction",
        knowledge.departedBeliefs.count == 3
            && knowledge.departedBeliefEvictionCount == 1
            && !knowledge.departedBeliefs.contains {
                if case .oralSourceClaim = $0.basis {
                    return $0.ownerID == oralB
                }
                return false
            }
            && Set(knowledge.departedBeliefs.map(\.ownerID))
                == Set([oralB, oralC]))
    check("terminal pressure never resurrects current cognition",
        knowledge.beliefs.count == 1
            && knowledge.beliefs[0].ownerID == oralA
            && !session.languageSnapshot().lexicalAssociations.contains {
                [oralB, oralC].contains($0.ownerID)
            })
    check("CIV-43 removes only the hop whose terminal proof disappeared",
        oral.transmissions.isEmpty
            && oral.evictedTransmissionCount == 1
            && !oral.transmissions.contains { $0.recipientID == oralB })
    check("mortality remains authoritative under oral historical pressure",
        mortality.records.count == 2
            && emptyBoundary.digest == oralSmokeJSONBoundaryDigest(
                rows: [], evicted: oral.evictedTransmissionCount
            )
            && emptyBoundaryEvent.causes.contains(oldBoundary.eventID))

    let checkpoint = try! session.makeCheckpoint()
    let bytes = try! AgentCheckpointCodec.encode(checkpoint)
    let controlRoot = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(controlCheckpoint!)
    ) as! [String: Any]
    let controlDurable = controlRoot["durableState"] as! [String: Any]
    let controlOralJSON = controlDurable["oralTransmissionState"]
        as! [String: Any]
    let controlKnowledgeJSON = controlDurable["knowledgeGraphState"]
        as! [String: Any]
    let controlDeparted = controlKnowledgeJSON["departedBeliefs"]
        as! [[String: Any]]
    let oldOralDepartedJSON = controlDeparted.first {
        ($0["beliefID"] as! String)
            == controlOralDepartedBeliefID!.rawValue
    }!
    let controlOralRows = controlOralJSON["transmissions"]
        as! [[String: Any]]
    let controlOralEvicted = controlOralJSON["evictedTransmissionCount"]
        as! Int
    let controlBoundaryJSON = controlOralJSON["provenanceBoundary"]
        as! [String: Any]
    let oldBoundaryStillRetained = retainedCausalEvents.contains {
        $0.eventID == oldBoundary.eventID
            && $0.kind == .oralProvenanceBoundary
            && $0.origin == .oralTransition
            && $0.payload == .oral(
                transmissionID: "oral-provenance",
                sourcePropositionID: nil,
                receivedPropositionID: nil,
                status: "provenanceBoundary",
                reason: oldBoundary.digest
            )
    }
    let resurrectionStructurallyCoherent =
        controlOralRows.count == 1
            && controlOralEvicted == 0
            && oralSmokeJSONBoundaryDigest(
                rows: controlOralRows, evicted: controlOralEvicted
            ) == controlBoundaryJSON["digest"] as! String
            && controlBoundaryJSON["digest"] as! String
                == oldBoundary.digest
            && oldOralDepartedJSON["ownerID"] as! String
                == oralB.rawValue
            && knowledge.departedBeliefs.count
                == knowledge.configuration!.maximumDepartedBeliefs
    let staleResurrection = oralSmokeResignedCheckpoint(checkpoint) {
        durable in
        durable["oralTransmissionState"] = controlOralJSON
        var forgedKnowledge = durable["knowledgeGraphState"]
            as! [String: Any]
        var departed = forgedKnowledge["departedBeliefs"]
            as! [[String: Any]]
        let replacement = departed.indices.last {
            departed[$0]["ownerID"] as! String == oralC.rawValue
        }!
        departed.remove(at: replacement)
        departed.append(oldOralDepartedJSON)
        departed.sort { left, right in
            let leftTick = left["departedAtTick"] as! Int
            let rightTick = right["departedAtTick"] as! Int
            if leftTick != rightTick { return leftTick < rightTick }
            let leftDeath = left["deathID"] as! String
            let rightDeath = right["deathID"] as! String
            if leftDeath != rightDeath { return leftDeath < rightDeath }
            return (left["beliefID"] as! String)
                < (right["beliefID"] as! String)
        }
        forgedKnowledge["departedBeliefs"] = departed
        durable["knowledgeGraphState"] = forgedKnowledge
    }
    let staleResurrectionError = oralSmokeRestoreError(staleResurrection)
    check(
        "formerly authentic oral boundary cannot resurrect a compacted route",
        oldBoundaryStillRetained
            && newBoundaryStillRetained
            && resurrectionStructurallyCoherent
            && staleResurrectionError
                == "oral:stale oral provenance boundary",
        "oldRetained=\(oldBoundaryStillRetained) "
            + "coherent=\(resurrectionStructurallyCoherent) "
            + "error=\(staleResurrectionError ?? "accepted")"
    )
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("terminal-compacted schema-38 checkpoint restarts byte exactly",
        checkpoint.schemaVersion == AgentCheckpointSchema.oralTransmissionVersion
            && (try! AgentCheckpointCodec.encode(restored.makeCheckpoint()))
                == bytes)
    check("restart recreates neither evicted epistemic nor oral history",
        !restored.knowledgeSnapshot().departedBeliefs.contains { departed in
            guard departed.ownerID == oralB else { return false }
            if case .oralSourceClaim = departed.basis { return true }
            return false
        }
            && !restored.oralTransmissionSnapshot().transmissions.contains {
                $0.recipientID == oralB
            }
            && restored.knowledgeSnapshot().departedBeliefEvictionCount == 1
            && restored.oralTransmissionSummary()
                .evictedTransmissionCount == 1)

    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "civ43-terminal-compaction")!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: base, journal: journal
    )
    check("replay preserves terminal epistemic and oral compaction",
        replay.report.verified
            && replay.report.finalSemanticDigest
                == (try! session.durableStateDigest())
            && !replay.session.knowledgeSnapshot().departedBeliefs.contains {
                departed in
                guard departed.ownerID == oralB else { return false }
                if case .oralSourceClaim = departed.basis { return true }
                return false
            }
            && !replay.session.oralTransmissionSnapshot().transmissions
                .contains { $0.recipientID == oralB })

    var (repeatSession, _) =
        oralSmokeTerminalCompactionPrepared(id: id)
    let repeatBase = try! repeatSession.makeCheckpoint()
    var repeatRecorder = try! AgentReplayRecorder(
        checkpoint: repeatBase, session: repeatSession
    )
    for record in journal.records {
        _ = try! repeatRecorder.apply(record.operation, to: &repeatSession)
    }
    check("terminal compaction repeats with exact final digests",
        session.knowledgeSnapshot().digest
            == repeatSession.knowledgeSnapshot().digest
            && session.oralTransmissionSnapshot().digest
                == repeatSession.oralTransmissionSnapshot().digest
            && session.mortalitySnapshot().digest
                == repeatSession.mortalitySnapshot().digest
            && (try! AgentCheckpointCodec.encode(
                repeatSession.makeCheckpoint()
            )) == bytes)

    var refreshSession = restored
    let droppedBeforeRefresh = refreshSession.causalLedgerSnapshot().summary
        .droppedEventCount
    let tombstoneBeforeRefresh = refreshSession.oralTransmissionSnapshot()
        .provenanceBoundary!
    for ordinal in 0..<128 where refreshSession
        .oralTransmissionSnapshot().provenanceBoundary?.eventID
            == tombstoneBeforeRefresh.eventID {
        let hunger = refreshSession.snapshot().agents.first {
            $0.id == oralA.rawValue
        }!.needs.hunger
        try! refreshSession.applyConsumptionOutcome(AgentConsumptionOutcome(
            consumptionId: "civ43-empty-boundary-refresh-\(ordinal)",
            agentId: oralA.rawValue,
            tick: refreshSession.tick,
            resource: .foodRaw,
            quantity: 1,
            status: .blocked,
            hungerBefore: hunger,
            hungerAfter: hunger,
            reason: "bounded empty-boundary refresh fixture"
        ))
    }
    let refreshedOral = refreshSession.oralTransmissionSnapshot()
    let refreshedBoundary = refreshedOral.provenanceBoundary!
    let refreshedBoundaryEvent = refreshSession.causalLedgerSnapshot().events
        .first { $0.eventID == refreshedBoundary.eventID }!
    let oldTombstoneDropped = !refreshSession.causalLedgerSnapshot().events
        .contains { $0.eventID == tombstoneBeforeRefresh.eventID }
    check("empty oral provenance authority refreshes before FIFO eviction",
        refreshedBoundary.eventID != tombstoneBeforeRefresh.eventID
            && refreshedOral.transmissions.isEmpty
            && refreshedOral.evictedTransmissionCount == 1
            && refreshedBoundary.digest == tombstoneBeforeRefresh.digest
            && oldTombstoneDropped
            && refreshedBoundaryEvent.causes.contains(
                tombstoneBeforeRefresh.eventID
            ))
    let refreshCheckpoint = try! refreshSession.makeCheckpoint()
    let refreshRestartExact = try! AgentCheckpointCodec.encode(
        AgentSimulationSession.restoring(refreshCheckpoint)
            .makeCheckpoint()
    ) == (try! AgentCheckpointCodec.encode(refreshCheckpoint))
    check("refreshed empty oral boundary restarts byte exactly",
        refreshRestartExact)

    print(
        "  CIV43_TERMINAL_COMPACTION departed=\(knowledge.departedBeliefs.count)/3 departedEvicted=\(knowledge.departedBeliefEvictionCount) oral=\(oral.transmissions.count) oralEvicted=\(oral.evictedTransmissionCount) deaths=\(mortality.totalDeathCount) causalDropped=\(session.causalLedgerSnapshot().summary.droppedEventCount) currentBoundary=\(emptyBoundary.eventID.rawValue) boundaryDigest=\(emptyBoundary.digest) controlBoundary=\(controlBoundaryID) controlBoundaryDigest=\(controlBoundaryDigest) replay=\(replay.report.verified)"
    )
    print(
        "  CIV43_STALE_BOUNDARY oldBoundary=\(oldBoundary.eventID.rawValue) newBoundary=\(emptyBoundary.eventID.rawValue) oldBoundaryStillRetained=\(oldBoundaryStillRetained) newBoundaryStillRetained=\(newBoundaryStillRetained) resurrectionStructurallyCoherent=\(resurrectionStructurallyCoherent) ordinaryDigestsResigned=true rejection=\(staleResurrectionError ?? "accepted")"
    )
    print(
        "  CIV43_EMPTY_BOUNDARY_REFRESH previousBoundary=\(tombstoneBeforeRefresh.eventID.rawValue) replacementBoundary=\(refreshedBoundary.eventID.rawValue) digest=\(refreshedBoundary.digest) causeLinked=\(refreshedBoundaryEvent.causes.contains(tombstoneBeforeRefresh.eventID)) oldBoundaryDropped=\(oldTombstoneDropped) droppedBefore=\(droppedBeforeRefresh) droppedAfter=\(refreshSession.causalLedgerSnapshot().summary.droppedEventCount) restartExact=\(refreshRestartExact)"
    )
}

private func oralSmokeMortalityProof() {
    var (mortality, sourceID) = oralSmokePrepared(
        id: "civ43-mortality",
        lethalID: oralB
    )
    _ = try! mortality.transmitOralClaim(
        speakerID: oralA,
        recipientID: oralB,
        propositionID: sourceID,
        renderingMode: .deterministicCompositional
    )
    try! mortality.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    mortality.setSurvivalEnabled(true)
    try! mortality.setMortalityEnabled(true)
    for _ in 0..<64 where mortality.snapshot().agents.contains(where: {
        $0.id == oralB.rawValue
    }) {
        _ = try! mortality.advanceTick()
    }
    let historicalCount = mortality.oralTransmissionSummary()
        .transmissionCount
    check("mortality finalized the informed oral participant",
        !mortality.snapshot().agents.contains { $0.id == oralB.rawValue })
    check("death retires current belief and lexical competence only",
        !mortality.knowledgeSnapshot().beliefs.contains {
            $0.ownerID == oralB
        }
            && !mortality.languageSnapshot().lexicalAssociations.contains {
                $0.ownerID == oralB
            }
            && historicalCount == 1)
    oralSmokeRefusal(
        "finalized-dead speaker cannot transmit",
        session: mortality,
        operation: {
            _ = try $0.transmitOralClaim(
                speakerID: oralB,
                recipientID: oralA,
                propositionID: sourceID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.oral(.unknownAgent) = $0 { return true }
            return false
        }
    )
    oralSmokeRefusal(
        "finalized-dead recipient cannot acquire",
        session: mortality,
        operation: {
            _ = try $0.transmitOralClaim(
                speakerID: oralA,
                recipientID: oralB,
                propositionID: sourceID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.oral(.unknownAgent) = $0 { return true }
            return false
        }
    )
    let checkpoint = try! mortality.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("restart does not resurrect dead oral cognition",
        !restored.snapshot().agents.contains { $0.id == oralB.rawValue }
            && !restored.knowledgeSnapshot().beliefs.contains {
                $0.ownerID == oralB
            }
            && !restored.languageSnapshot().lexicalAssociations.contains {
                $0.ownerID == oralB
            }
            && restored.oralTransmissionSummary().transmissionCount
                == historicalCount)
    print(
        "  CIV43_LIFECYCLE dead=\(oralB.rawValue) historical=\(historicalCount) currentBeliefs=\(restored.knowledgeSummary().currentBeliefCount)"
    )
}

private func oralSmokeCompactionProof() {
    // The two-hop chain is intentionally pinned by B and C's current beliefs.
    // A third row therefore fails at a bound of two without partial mutation.
    let config = try! AgentOralConfiguration(
        maximumTransmissionRecords: 2,
        maximumFaithfulDistance: 1
    )
    let (bounded, _, _, sourceID) = oralSmokeChain(
        id: "civ43-bounded",
        oralConfiguration: config,
        causalMaximumEvents: 24
    )
    oralSmokeRefusal(
        "pinned oral capacity fails closed",
        session: bounded,
        operation: {
            _ = try $0.transmitOralClaim(
                speakerID: oralB,
                recipientID: oralA,
                propositionID: sourceID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.oral(.capacityReached) = $0 {
                return true
            }
            return false
        }
    )
    let preEvictionCheckpoint = try! bounded.makeCheckpoint()
    let preEvictionRoot = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(preEvictionCheckpoint)
    ) as! [String: Any]
    let preEvictionDurable = preEvictionRoot["durableState"]
        as! [String: Any]
    var compacted = bounded
    _ = try! compacted.transmitOralClaim(
        speakerID: oralA,
        recipientID: oralB,
        propositionID: sourceID,
        renderingMode: .noRendering
    )
    check("superseded oral basis compacts deterministically",
        compacted.oralTransmissionSummary().transmissionCount == 2
            && compacted.oralTransmissionSummary()
                .evictedTransmissionCount == 1)
    let preOral = preEvictionDurable["oralTransmissionState"]
        as! [String: Any]
    let preRows = preOral["transmissions"] as! [[String: Any]]
    let retainedIDs = Set(compacted.oralTransmissionSnapshot()
        .transmissions.map { $0.transmissionID.rawValue })
    let evictedTemplate = preRows.first {
        !retainedIDs.contains($0["transmissionID"] as! String)
    }!
    let forgedRouteLastSequence = [
        evictedTemplate["sourceBeliefRevisionEventID"]!,
        evictedTemplate["languageCommunicationEventID"]!,
        evictedTemplate["receiptEventID"]!,
        evictedTemplate["recipientClaimEventID"]!,
        evictedTemplate["recipientBeliefRevisionEventID"]!,
    ].map(oralSmokeJSONEventSequence).max()!
    for _ in 0..<32 where compacted.causalLedgerSnapshot().summary
        .droppedEventCount < forgedRouteLastSequence {
        _ = try! compacted.advanceTick()
    }
    let checkpoint = try! compacted.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("bounded compacted causal prefix preserves oral chain",
        compacted.causalLedgerSnapshot().summary.droppedEventCount > 0
            && restored.oralTransmissionSnapshot()
                == compacted.oralTransmissionSnapshot())
    check("compacted oral chain restarts byte exactly",
        try! AgentCheckpointCodec.encode(restored.makeCheckpoint())
            == (try! AgentCheckpointCodec.encode(checkpoint)))
    let droppedCount = compacted.causalLedgerSnapshot().summary
        .droppedEventCount
    let forgedRouteUsesDroppedPrefix = forgedRouteLastSequence
        <= UInt64(droppedCount)
    let mutuallyCoherentForgery = oralSmokeResignedCheckpoint(checkpoint) {
        durable in
        var oral = durable["oralTransmissionState"] as! [String: Any]
        var rows = oral["transmissions"] as! [[String: Any]]
        let authenticRows = rows
        let evicted = oral["evictedTransmissionCount"] as! Int
        let authenticBoundary = oral["provenanceBoundary"]
            as! [String: Any]
        precondition(
            oralSmokeJSONBoundaryDigest(rows: rows, evicted: evicted)
                == authenticBoundary["digest"] as! String,
            "CIV-43 hostile boundary recomputation fixture"
        )
        let originalTransmissionID = evictedTemplate["transmissionID"]
            as! String
        let originalClaimID = evictedTemplate["recipientClaimID"] as! String
        let originalUnderstandingID = evictedTemplate[
            "recipientUnderstandingID"
        ] as! String
        let forgedTransmissionID =
            "oral-transmission-forged-separate-dropped-prefix"
        let forgedClaimID = "claim-forged-separate-dropped-prefix"
        let forgedUnderstandingID =
            "understanding-forged-separate-dropped-prefix"
        let forgedRevisionID = "revision-forged-separate-dropped-prefix"
        let replacements = [
            originalTransmissionID: forgedTransmissionID,
            originalClaimID: forgedClaimID,
            originalUnderstandingID: forgedUnderstandingID,
        ]
        var forged = oralSmokeJSONReplacing(
            evictedTemplate,
            replacements: replacements
        ) as! [String: Any]
        forged["provenanceDigest"] = oralSmokeJSONProvenanceDigest(forged)
        rows.append(forged)
        rows.sort {
            ($0["transmissionID"] as! String)
                < ($1["transmissionID"] as! String)
        }
        oral["transmissions"] = rows
        var oralConfiguration = oral["configuration"] as! [String: Any]
        oralConfiguration["maximumTransmissionRecords"] = rows.count
        oral["configuration"] = oralConfiguration
        oral["nextTransmissionOrdinal"] = 10_000
        var boundary = oral["provenanceBoundary"] as! [String: Any]
        boundary["digest"] = oralSmokeJSONBoundaryDigest(
            rows: rows, evicted: evicted
        )
        oral["provenanceBoundary"] = boundary
        durable["oralTransmissionState"] = oral

        var knowledge = durable["knowledgeGraphState"] as! [String: Any]
        var claims = knowledge["claims"] as! [[String: Any]]
        var understandings = knowledge["understandings"]
            as! [[String: Any]]
        var revisions = knowledge["revisions"] as! [[String: Any]]
        let preKnowledge = preEvictionDurable["knowledgeGraphState"]
            as! [String: Any]
        let preClaims = preKnowledge["claims"] as! [[String: Any]]
        let preUnderstandings = preKnowledge["understandings"]
            as! [[String: Any]]
        let preRevisions = preKnowledge["revisions"]
            as! [[String: Any]]
        let claimTemplate = preClaims.first {
            ($0["claimID"] as! String) == originalClaimID
        }!
        let understandingTemplate = preUnderstandings.first {
            ($0["understandingID"] as! String) == originalUnderstandingID
        }!
        var revisionTemplate = preRevisions.first {
            oralSmokeJSONEventID($0["revisionEventID"]!)
                == oralSmokeJSONEventID(
                    evictedTemplate["recipientBeliefRevisionEventID"]!
                )
        }!
        revisionTemplate["revisionID"] = forgedRevisionID
        let forgedClaim = oralSmokeJSONReplacing(
            claimTemplate,
            replacements: replacements
        ) as! [String: Any]
        let forgedUnderstanding = oralSmokeJSONReplacing(
            understandingTemplate,
            replacements: replacements
        ) as! [String: Any]
        revisionTemplate = oralSmokeJSONReplacing(
            revisionTemplate,
            replacements: replacements
        ) as! [String: Any]
        claims.append(forgedClaim)
        understandings.append(forgedUnderstanding)
        revisions.append(revisionTemplate)
        claims.sort {
            ($0["claimID"] as! String) < ($1["claimID"] as! String)
        }
        understandings.sort {
            ($0["understandingID"] as! String)
                < ($1["understandingID"] as! String)
        }
        revisions.sort {
            ($0["revisionID"] as! String)
                < ($1["revisionID"] as! String)
        }
        knowledge["claims"] = claims
        knowledge["understandings"] = understandings
        knowledge["revisions"] = revisions
        var evictionCounts = knowledge["evictionCounts"]
            as! [String: Any]
        for key in ["claims", "understandings", "revisions"] {
            let count = evictionCounts[key] as! Int
            precondition(count > 0, "forged route eviction accounting")
            evictionCounts[key] = count - 1
        }
        knowledge["evictionCounts"] = evictionCounts
        durable["knowledgeGraphState"] = knowledge

        let rowsByID = Dictionary(uniqueKeysWithValues: rows.map {
            ($0["transmissionID"] as! String, $0)
        })
        precondition(authenticRows.allSatisfy { authentic in
            let id = authentic["transmissionID"] as! String
            return oralSmokeJSONEqual(rowsByID[id]!, authentic)
        }, "CIV-43 hostile fixture changed an authentic oral row")
    }
    let forgeryError = oralSmokeRestoreError(mutuallyCoherentForgery)
    check(
        "separate mutually coherent dropped-prefix forgery is rejected by authentic oral boundary",
        forgedRouteUsesDroppedPrefix
            && forgeryError == "oral:oral provenance boundary",
        "droppedRoute=\(forgedRouteUsesDroppedPrefix) error=\(forgeryError ?? "accepted")"
    )
    print(
        "  CIV43_FORGERY separateRoute=true authenticRowsUnchanged=true droppedRoute=\(forgedRouteUsesDroppedPrefix) ordinaryDigestsResigned=true rejection=\(forgeryError ?? "accepted")"
    )
    var retransmitting = restored
    let currentB = sourceIDFor(session: retransmitting, ownerID: oralB)
    _ = try! retransmitting.transmitOralClaim(
        speakerID: oralB,
        recipientID: oralC,
        propositionID: currentB,
        renderingMode: .noRendering
    )
    check("B can retransmit current belief after legitimate compaction",
        retransmitting.oralTransmissionSummary().transmissionCount == 2
            && retransmitting.oralTransmissionSummary()
                .evictedTransmissionCount == 2)
    print(
        "  CIV43_BOUNDS retained=\(compacted.oralTransmissionSummary().transmissionCount)/2 evicted=\(compacted.oralTransmissionSummary().evictedTransmissionCount) dropped=\(compacted.causalLedgerSnapshot().summary.droppedEventCount) boundary=\(compacted.oralTransmissionSnapshot().provenanceBoundary!.eventID.rawValue) currentBeliefs=\(compacted.knowledgeSummary().currentBeliefCount) retransmitEvicted=\(retransmitting.oralTransmissionSummary().evictedTransmissionCount)"
    )
}

func runPebbleAgentsOralTransmissionRestartWriteSmoke() {
    let path = ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV43_CHECKPOINT_PATH"
    ]!
    let session = oralSmokeChain(id: "civ43-fresh-process").0
    let bytes = try! AgentCheckpointCodec.encode(session.makeCheckpoint())
    try! bytes.write(to: URL(fileURLWithPath: path), options: .atomic)
    check("CIV-43 fresh-process checkpoint write", !bytes.isEmpty)
}

func runPebbleAgentsOralTransmissionRestartReadSmoke() {
    let path = ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV43_CHECKPOINT_PATH"
    ]!
    let bytes = try! Data(contentsOf: URL(fileURLWithPath: path))
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: bytes
    )
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("CIV-43 fresh-process schema is 38",
        checkpoint.schemaVersion
            == AgentCheckpointSchema.oralTransmissionVersion)
    check("CIV-43 fresh-process chain survives",
        restored.oralTransmissionSummary().transmissionCount == 2
            && restored.oralTransmissionSummary().distortedCount == 1)
    check("CIV-43 fresh-process bytes remain exact",
        try! AgentCheckpointCodec.encode(restored.makeCheckpoint()) == bytes)
}
