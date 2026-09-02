import Foundation
import PebbleAgents

private let languageSmokeSenseIDs = [
    AgentLanguageSenseID(rawValue: "referent.worldCell")!,
    AgentLanguageSenseID(rawValue: "predicate.world.resource.presence")!,
    AgentLanguageSenseID(rawValue: "value.resource.wood")!,
]

private func languageSmokeAgent(
    _ id: String,
    x: Int,
    lethalWhenEnabled: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
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
            reason: "CIV-42 fixture",
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

private func languageSmokePerception(
    agentID: String = "teacher"
) -> AgentPerceptionInput {
    AgentPerceptionInput(
        agentId: agentID,
        socialResourceObservations: [AgentResourceObservation(
            resource: .wood,
            target: AgentPosition(x: 2, y: 64, z: 0),
            direction: .east,
            distanceManhattan: 2,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: 42_001
        )]
    )
}

private func languageSmokeKnowledgeSession(
    id: String,
    agents: [AgentSessionAgentState],
    teacherID: String = "teacher",
    learnerID: String = "learner",
    causalMaximumEvents: Int = 16_384
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
            seed: 142,
            nearbyRadius: 16,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            socialConfiguration: social
        ),
        agents: agents,
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: causalMaximumEvents)
    )
    try! session.setSocialEnabled(true)
    try! session.setKnowledgeGraphEnabled(true)
    _ = try! session.advanceTick(perceptions: [
        languageSmokePerception(agentID: teacherID),
    ])
    for _ in 0..<64 where !session.knowledgeSnapshot().beliefs.contains(where: {
        $0.ownerID.rawValue == learnerID
    }) {
        _ = try! session.advanceTick()
    }
    let graph = session.knowledgeSnapshot()
    let teacher = graph.beliefs.first {
        $0.ownerID.rawValue == teacherID && $0.stance == .accepted
    }
    let learner = graph.beliefs.first {
        $0.ownerID.rawValue == learnerID && $0.stance == .accepted
    }
    precondition(
        teacher != nil && learner?.propositionID == teacher?.propositionID,
        "CIV-41 source and recipient authority were not established for \(id)"
    )
    return (session, teacher!.propositionID)
}

private func languageSmokePrepared(
    id: String,
    pack: AgentLanguagePack = .frenchReference,
    configuration: AgentLanguageConfiguration = .live,
    agents: [AgentSessionAgentState]? = nil,
    teacherID: String = "teacher",
    learnerID: String = "learner",
    causalMaximumEvents: Int = 16_384
) -> (AgentSimulationSession, AgentKnowledgePropositionID) {
    var (session, propositionID) = languageSmokeKnowledgeSession(
        id: id,
        agents: agents ?? [
            languageSmokeAgent("teacher", x: 0),
            languageSmokeAgent("learner", x: 1),
            languageSmokeAgent("remote", x: 30),
        ],
        teacherID: teacherID,
        learnerID: learnerID,
        causalMaximumEvents: causalMaximumEvents
    )
    try! session.setLanguageEnabled(
        true,
        configuration: configuration,
        pack: pack
    )
    return (session, propositionID)
}

private func languageSmokeLearn(
    session: inout AgentSimulationSession,
    propositionID: AgentKnowledgePropositionID,
    teacherID: String = "teacher",
    learnerID: String = "learner"
) -> (AgentLanguageCommunication, AgentLanguageCommunication) {
    try! session.seedLanguagePrior(
        for: AgentID(rawValue: teacherID)!,
        senseIDs: languageSmokeSenseIDs
    )
    let first = try! session.communicateLanguageSemanticContent(
        speakerID: AgentID(rawValue: teacherID)!,
        recipientID: AgentID(rawValue: learnerID)!,
        propositionID: propositionID,
        renderingMode: .deterministicCompositional
    )
    _ = try! session.advanceTick()
    let second = try! session.communicateLanguageSemanticContent(
        speakerID: AgentID(rawValue: teacherID)!,
        recipientID: AgentID(rawValue: learnerID)!,
        propositionID: propositionID,
        renderingMode: .deterministicCompositional
    )
    return (first, second)
}

private func languageSmokeRestartCandidate() -> AgentSimulationSession {
    var (session, propositionID) = languageSmokePrepared(
        id: "civ42-fresh-process"
    )
    _ = try! session.communicateLanguageSemanticContent(
        speakerID: AgentID(rawValue: "teacher")!,
        recipientID: AgentID(rawValue: "learner")!,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    _ = languageSmokeLearn(session: &session, propositionID: propositionID)
    return session
}

private func languageSmokeDeterministicRun(
    reversed: Bool
) -> AgentLanguageSnapshot {
    let agents = [
        languageSmokeAgent("teacher", x: 0),
        languageSmokeAgent("learner", x: 1),
        languageSmokeAgent("remote", x: 30),
    ]
    var (session, propositionID) = languageSmokePrepared(
        id: "civ42-registration-order",
        agents: reversed ? Array(agents.reversed()) : agents
    )
    _ = try! session.communicateLanguageSemanticContent(
        speakerID: AgentID(rawValue: "teacher")!,
        recipientID: AgentID(rawValue: "learner")!,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    _ = languageSmokeLearn(session: &session, propositionID: propositionID)
    return session.languageSnapshot()
}

private func languageSmokeSHA256(_ text: String) -> String {
    AgentCheckpointDigest.sha256(Data(text.utf8)).rawValue
}

private func languageSmokeAssociationID(
    ownerID: String,
    packID: String,
    senseID: String,
    form: String
) -> String {
    "language-association-" + languageSmokeSHA256(
        "\(ownerID)|\(packID)|\(senseID)|\(form)"
    )
}

private func languageSmokeEventIDText(_ value: [String: Any]) -> String {
    let simulationID = value["simulationID"] as! String
    let sequence = value["sequence"] as! UInt64
    let digits = String(sequence)
    return "\(simulationID)/event-"
        + String(repeating: "0", count: max(0, 20 - digits.count))
        + digits
}

private func languageSmokeResignedCheckpoint(
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

private func languageSmokeInvalidLanguageReason(
    _ checkpoint: AgentSessionCheckpoint
) -> String? {
    do {
        _ = try AgentSimulationSession.restoring(checkpoint)
        return nil
    } catch AgentSessionError.language(.invalidState(let reason)) {
        return reason
    } catch {
        return "unexpected: \(error)"
    }
}

private func languageSmokeInvalidKnowledgeReason(
    _ checkpoint: AgentSessionCheckpoint
) -> String? {
    do {
        _ = try AgentSimulationSession.restoring(checkpoint)
        return nil
    } catch AgentSessionError.knowledge(.invalidState(let reason)) {
        return reason
    } catch {
        return "unexpected: \(error)"
    }
}

private func languageSmokeMutateSemanticReferent(
    _ durable: inout [String: Any]
) {
    var language = durable["languageState"] as! [String: Any]
    var communications = language["communications"] as! [[String: Any]]
    var semantic = communications[0]["semanticContent"]
        as! [String: Any]
    var referent = semantic["referent"] as! [String: Any]
    referent["key"] = "cell:9,64,9"
    semantic["referent"] = referent
    let propositionID = semantic["sourcePropositionID"] as! String
    let senses = semantic["senses"] as! [[String: Any]]
    let canonicalSenses = senses.map {
        "\($0["role"] as! String):\($0["senseID"] as! String)"
    }.joined(separator: ",")
    semantic["digest"] = languageSmokeSHA256(
        "\(propositionID)|worldCell:cell:9,64,9|\(canonicalSenses)"
    )
    communications[0]["semanticContent"] = semantic
    language["communications"] = communications
    durable["languageState"] = language
}

private func languageSmokeMutateAssociationToUngrant(
    _ durable: inout [String: Any],
    ownerID: String,
    source: String
) {
    var language = durable["languageState"] as! [String: Any]
    var associations = language["lexicalAssociations"]
        as! [[String: Any]]
    let index = associations.firstIndex {
        $0["ownerID"] as? String == ownerID
            && $0["source"] as? String == source
    }!
    let packID = associations[index]["packID"] as! String
    associations[index]["senseID"] = "value.resource.stone"
    associations[index]["form"] = "pierre"
    associations[index]["associationID"] = languageSmokeAssociationID(
        ownerID: ownerID,
        packID: packID,
        senseID: "value.resource.stone",
        form: "pierre"
    )
    language["lexicalAssociations"] = associations
    durable["languageState"] = language
}

private func languageSmokeExposureDigest(
    communicationID: String,
    speakerID: String,
    recipientID: String,
    sourceBeliefID: String,
    sourceBeliefRevisionEventID: String,
    sourcePropositionID: String,
    semanticAuthorityID: String,
    semanticContentDigest: String,
    lexicalUses: [[String: Any]],
    exposedAssociationIDs: [String],
    communicatedAtTick: Int
) -> String {
    let uses = lexicalUses.map {
        "\($0["role"] as! String):\($0["senseID"] as! String):"
            + ($0["form"] as! String)
    }.joined(separator: ",")
    return languageSmokeSHA256([
        "linguistic-exposure",
        communicationID,
        speakerID,
        recipientID,
        sourceBeliefID,
        sourceBeliefRevisionEventID,
        sourcePropositionID,
        semanticAuthorityID,
        semanticContentDigest,
        uses,
        exposedAssociationIDs.joined(separator: ","),
        String(communicatedAtTick),
    ].joined(separator: "|"))
}

private func languageSmokeFabricateSeedReceiptAndAssociation(
    _ durable: inout [String: Any]
) {
    var language = durable["languageState"] as! [String: Any]
    let pack = language["pack"] as! [String: Any]
    let packID = pack["packID"] as! String
    var associations = language["lexicalAssociations"]
        as! [[String: Any]]
    var receipts = language["priorSeedReceipts"] as! [[String: Any]]
    let templateAssociation = associations.first {
        $0["source"] as? String == "seededPrior"
    }!
    let templateReceipt = receipts[0]
    let ownerID = "remote"
    let senseID = "value.resource.stone"
    let form = "pierre"
    let associationID = languageSmokeAssociationID(
        ownerID: ownerID,
        packID: packID,
        senseID: senseID,
        form: form
    )
    let seededAtTick = templateReceipt["seededAtTick"] as! Int
    let digest = languageSmokeSHA256([
        "prior-seed",
        ownerID,
        packID,
        associationID,
        String(seededAtTick),
    ].joined(separator: "|"))
    let seedID = "language-seed-" + digest
    let droppedEventJSON = templateReceipt["seedEventID"]
        as! [String: Any]

    var association = templateAssociation
    association["associationID"] = associationID
    association["ownerID"] = ownerID
    association["senseID"] = senseID
    association["form"] = form
    association["competence"] = "known"
    association["exposureCount"] = 0
    association["firstAcquiredAtTick"] = seededAtTick
    association["lastExposedAtTick"] = seededAtTick
    association["lastEventID"] = droppedEventJSON
    association["priorSeedID"] = seedID
    association["learningCommunicationIDs"] = [String]()
    association.removeValue(forKey: "lastExposureCommunicationID")
    associations.append(association)

    var receipt = templateReceipt
    receipt["seedID"] = seedID
    receipt["ownerID"] = ownerID
    receipt["packID"] = packID
    receipt["grantedAssociationIDs"] = [associationID]
    receipt["seededAtTick"] = seededAtTick
    receipt["seedEventID"] = droppedEventJSON
    receipt["digest"] = digest
    receipts.append(receipt)

    language["lexicalAssociations"] = associations
    language["priorSeedReceipts"] = receipts
    durable["languageState"] = language
}

private func languageSmokeFabricateExposureReceiptsAndCompetence(
    _ durable: inout [String: Any]
) {
    var language = durable["languageState"] as! [String: Any]
    let pack = language["pack"] as! [String: Any]
    let packID = pack["packID"] as! String
    var associations = language["lexicalAssociations"]
        as! [[String: Any]]
    var receipts = language["exposureReceipts"] as! [[String: Any]]
    let templates = receipts.sorted {
        ($0["communicatedAtTick"] as! Int)
            < ($1["communicatedAtTick"] as! Int)
    }
    let ownerID = "remote"
    let senseID = "value.resource.stone"
    let form = "pierre"
    let associationID = languageSmokeAssociationID(
        ownerID: ownerID,
        packID: packID,
        senseID: senseID,
        form: form
    )
    let lexicalUses: [[String: Any]] = [[
        "role": "value",
        "senseID": senseID,
        "form": form,
    ]]
    var fabricatedReceipts: [[String: Any]] = []
    var communicationIDs: [String] = []
    for index in 0..<2 {
        var receipt = templates[index]
        let communicationID = "language-communication-fabricated-\(index + 1)"
        let tick = receipt["communicatedAtTick"] as! Int
        let sourceBeliefID = receipt["sourceBeliefID"] as! String
        let revisionEventID = languageSmokeEventIDText(receipt[
            "sourceBeliefRevisionEventID"
        ] as! [String: Any])
        let propositionID = receipt["sourcePropositionID"] as! String
        let authorityID = receipt["semanticAuthorityID"] as! String
        let semanticDigest = receipt["semanticContentDigest"] as! String
        receipt["communicationID"] = communicationID
        receipt["recipientID"] = ownerID
        receipt["lexicalUses"] = lexicalUses
        receipt["exposedAssociationIDs"] = [associationID]
        receipt["digest"] = languageSmokeExposureDigest(
            communicationID: communicationID,
            speakerID: receipt["speakerID"] as! String,
            recipientID: ownerID,
            sourceBeliefID: sourceBeliefID,
            sourceBeliefRevisionEventID: revisionEventID,
            sourcePropositionID: propositionID,
            semanticAuthorityID: authorityID,
            semanticContentDigest: semanticDigest,
            lexicalUses: lexicalUses,
            exposedAssociationIDs: [associationID],
            communicatedAtTick: tick
        )
        fabricatedReceipts.append(receipt)
        communicationIDs.append(communicationID)
    }
    receipts.append(contentsOf: fabricatedReceipts)

    var association = associations.first {
        $0["ownerID"] as? String == "learner"
            && $0["source"] as? String == "exposure"
    }!
    association["associationID"] = associationID
    association["ownerID"] = ownerID
    association["senseID"] = senseID
    association["form"] = form
    association["competence"] = "known"
    association["exposureCount"] = 2
    association["firstAcquiredAtTick"] = fabricatedReceipts[0][
        "communicatedAtTick"
    ] as! Int
    association["lastExposedAtTick"] = fabricatedReceipts[1][
        "communicatedAtTick"
    ] as! Int
    association["lastEventID"] = fabricatedReceipts[1][
        "communicationEventID"
    ] as! [String: Any]
    association.removeValue(forKey: "priorSeedID")
    association["learningCommunicationIDs"] = communicationIDs
    association["lastExposureCommunicationID"] = communicationIDs[1]
    associations.append(association)

    language["lexicalAssociations"] = associations
    language["exposureReceipts"] = receipts
    durable["languageState"] = language
}

private func languageSmokeFabricateHistoricalAuthorityReference(
    _ durable: inout [String: Any]
) {
    var language = durable["languageState"] as! [String: Any]
    var communications = language["communications"] as! [[String: Any]]
    var communication = communications[0]
    let fakeAuthorityID = "historical-belief-authority-"
        + languageSmokeSHA256("fabricated-language-authority")
    var authority = communication["semanticAuthority"] as! [String: Any]
    authority["authorityID"] = fakeAuthorityID
    communication["semanticAuthority"] = authority

    var semantic = communication["semanticContent"] as! [String: Any]
    var referent = semantic["referent"] as! [String: Any]
    referent["key"] = "cell:9,64,9"
    semantic["referent"] = referent
    let fakePropositionID = "proposition-"
        + languageSmokeSHA256("fabricated-language-proposition")
    semantic["sourcePropositionID"] = fakePropositionID
    let senses = semantic["senses"] as! [[String: Any]]
    let canonicalSenses = senses.map {
        "\($0["role"] as! String):\($0["senseID"] as! String)"
    }.joined(separator: ",")
    let semanticDigest = languageSmokeSHA256(
        "\(fakePropositionID)|worldCell:cell:9,64,9|\(canonicalSenses)"
    )
    semantic["digest"] = semanticDigest
    communication["semanticContent"] = semantic
    communication["provenanceDigest"] = languageSmokeExposureDigest(
        communicationID: communication["communicationID"] as! String,
        speakerID: communication["speakerID"] as! String,
        recipientID: communication["recipientID"] as! String,
        sourceBeliefID: communication["sourceBeliefID"] as! String,
        sourceBeliefRevisionEventID: languageSmokeEventIDText(
            communication["sourceBeliefRevisionEventID"] as! [String: Any]
        ),
        sourcePropositionID: fakePropositionID,
        semanticAuthorityID: fakeAuthorityID,
        semanticContentDigest: semanticDigest,
        lexicalUses: communication["lexicalUses"] as! [[String: Any]],
        exposedAssociationIDs:
            communication["exposedAssociationIDs"] as! [String],
        communicatedAtTick: communication["communicatedAtTick"] as! Int
    )
    communications[0] = communication
    language["communications"] = communications
    durable["languageState"] = language
}

private func languageSmokeCompactedFixture() -> AgentSimulationSession {
    let configuration = try! AgentLanguageConfiguration(
        maximumLexicalAssociations: 16,
        maximumLexicalAssociationsPerAgent: 8,
        maximumCommunicationRecords: 1,
        exposuresRequiredForLearning: 2
    )
    var (session, propositionID) = languageSmokePrepared(
        id: "civ42-hostile-compaction",
        configuration: configuration,
        causalMaximumEvents: 32
    )
    _ = languageSmokeLearn(
        session: &session,
        propositionID: propositionID
    )
    let retained = try! session.communicateLanguageSemanticContent(
        speakerID: AgentID(rawValue: "teacher")!,
        recipientID: AgentID(rawValue: "learner")!,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    for _ in 0..<512 where session.causalLedgerSnapshot().summary
        .droppedEventCount < retained.communicationEventID.sequence.rawValue {
        _ = try! session.advanceTick()
    }
    return session
}

func runPebbleAgentsLanguageRestartWriteSmoke() {
    section("CIV-42 schema-37 fresh-process checkpoint writer")
    guard let path = ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV42_CHECKPOINT_PATH"
    ], !path.isEmpty else {
        check("CIV-42 writer receives checkpoint path", false)
        return
    }
    let session = languageSmokeRestartCandidate()
    let snapshot = session.languageSnapshot()
    let checkpoint = try! session.makeCheckpoint()
    let bytes = try! AgentCheckpointCodec.encode(checkpoint)
    try! bytes.write(to: URL(fileURLWithPath: path), options: .atomic)
    check("CIV-42 writer emits schema 37", checkpoint.schemaVersion == 37)
    check("CIV-42 writer persists learned lexical history",
          snapshot.lexicalAssociations.filter {
              $0.ownerID.rawValue == "learner" && $0.competence == .known
          }.count == 3
            && snapshot.communications.count == 3)
    check("CIV-42 writer persists nonempty checkpoint", !bytes.isEmpty)
    print("  CIV42_RESTART_WRITE bytes=\(bytes.count) schema=\(checkpoint.schemaVersion) digest=\(checkpoint.semanticDigest.rawValue) language=\(snapshot.digest)")
}

func runPebbleAgentsLanguageRestartReadSmoke() {
    section("CIV-42 schema-37 fresh-process checkpoint reader")
    guard let path = ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV42_CHECKPOINT_PATH"
    ], !path.isEmpty else {
        check("CIV-42 reader receives checkpoint path", false)
        return
    }
    let bytes = try! Data(contentsOf: URL(fileURLWithPath: path))
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: bytes
    )
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    let reencoded = try! AgentCheckpointCodec.encode(
        restored.makeCheckpoint()
    )
    let snapshot = restored.languageSnapshot()
    check("CIV-42 reader decodes schema 37", checkpoint.schemaVersion == 37)
    check("CIV-42 reader preserves exact checkpoint bytes", reencoded == bytes)
    check("CIV-42 reader retains French pack as non-authoritative seed data",
          snapshot.pack?.packID == AgentLanguagePack.frenchReference.packID
            && snapshot.pack?.provenance.contains("project-authored") == true)
    check("CIV-42 reader retains sparse learned competence",
          snapshot.lexicalAssociations.count == 6
            && snapshot.lexicalAssociations.filter {
                $0.ownerID.rawValue == "learner" && $0.competence == .known
            }.count == 3)
    check("CIV-42 reader duplicates no language history",
          snapshot.communications.count == 3
            && snapshot.evictedCommunicationCount == 0)
    print("  CIV42_RESTART_READ bytes=\(bytes.count) schema=\(checkpoint.schemaVersion) digest=\(checkpoint.semanticDigest.rawValue) language=\(snapshot.digest)")
}

func runPebbleAgentsLanguageSmoke() {
    section("CIV-42 learned language foundations V1")

    check("checkpoint schema advances to 37",
          AgentCheckpointSchema.languageVersion == 37)
    check("replay schema advances to 37",
          AgentReplaySchema.languageVersion == 37)
    check("language defaults are globally and individually bounded",
          AgentLanguageConfiguration.live.maximumLexicalAssociations == 4_096
            && AgentLanguageConfiguration.live
                .maximumLexicalAssociationsPerAgent == 32
            && AgentLanguageConfiguration.live
                .maximumCommunicationRecords == 4_096)
    check("language configuration rejects zero capacity",
          (try? AgentLanguageConfiguration(
            maximumCommunicationRecords: 0
          )) == nil)
    check("French reference pack is project-authored replaceable data",
          AgentLanguagePack.frenchReference.languageTag == "fr"
            && AgentLanguagePack.frenchReference.entries.count == 5
            && AgentLanguagePack.frenchReference.provenance
                .contains("project-authored")
            && AgentLanguagePack.frenchReference.license
                .contains("no external dataset"))

    var noKnowledge = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 1,
            memoryPolicy: .bounded(maxEntries: 4)
        ),
        agents: [languageSmokeAgent("teacher", x: 0)],
        simulationID: try! AgentSimulationID(validating: "civ42-no-knowledge"),
        causalLedgerPolicy: .bounded(maxEvents: 64)
    )
    let noKnowledgeBytes = try! noKnowledge.durableStateBytes()
    var knowledgeRequired = false
    do { try noKnowledge.setLanguageEnabled(true) }
    catch AgentSessionError.language(.knowledgeRequired) {
        knowledgeRequired = true
    } catch {}
    check("language activation requires CIV-41 authority", knowledgeRequired)
    check("refused activation is an exact atomic no-op",
          try! noKnowledge.durableStateBytes() == noKnowledgeBytes)

    var (session, propositionID) = languageSmokePrepared(id: "civ42-decisive")
    try! session.setKnowledgeGraphEnabled(false)
    let knowledgeBeforeLanguage = session.knowledgeSnapshot()
    let noRendering = try! session.communicateLanguageSemanticContent(
        speakerID: AgentID(rawValue: "teacher")!,
        recipientID: AgentID(rawValue: "learner")!,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    check("NO_RENDERING retains complete semantic reference",
          noRendering.rendering == .noRendering
            && noRendering.semanticContent.sourcePropositionID == propositionID
            && noRendering.semanticContent.senses.count == 3
            && !noRendering.semanticContent.digest.isEmpty)
    check("NO_RENDERING creates no accidental lexical exposure",
          noRendering.lexicalUses.isEmpty
            && session.languageSnapshot().lexicalAssociations.isEmpty)
    let knowledgeAfterSemanticCommunication = session.knowledgeSnapshot()
    check("semantic communication mutates no CIV-41 cognition",
          knowledgeAfterSemanticCommunication.propositions
            == knowledgeBeforeLanguage.propositions
            && knowledgeAfterSemanticCommunication.evidence
                == knowledgeBeforeLanguage.evidence
            && knowledgeAfterSemanticCommunication.claims
                == knowledgeBeforeLanguage.claims
            && knowledgeAfterSemanticCommunication.understandings
                == knowledgeBeforeLanguage.understandings
            && knowledgeAfterSemanticCommunication.beliefs
                == knowledgeBeforeLanguage.beliefs
            && knowledgeAfterSemanticCommunication.revisions
                == knowledgeBeforeLanguage.revisions
            && knowledgeAfterSemanticCommunication.departedBeliefs
                == knowledgeBeforeLanguage.departedBeliefs)
    check("semantic communication references CIV-41-owned history",
          knowledgeAfterSemanticCommunication
            .historicalBeliefAuthorities.count == 1
            && knowledgeAfterSemanticCommunication
                .historicalBeliefAuthorityBoundary != nil
            && knowledgeAfterSemanticCommunication
                .historicalBeliefAuthorities[0].authorityID
                == noRendering.semanticAuthority.authorityID)

    var unavailableBeforeLearning = false
    do {
        _ = try session.realizeLanguageSemanticContent(
            for: AgentID(rawValue: "learner")!,
            propositionID: propositionID
        )
    } catch AgentSessionError.language(.missingLexicalKnowledge) {
        unavailableBeforeLearning = true
    } catch {}
    check("unexposed individual refuses unavailable lexical knowledge",
          unavailableBeforeLearning)

    var (lexiconWithoutAuthority, authorityPropositionID) =
        languageSmokePrepared(id: "civ42-lexicon-is-not-belief")
    let authorityKnowledgeBefore = lexiconWithoutAuthority.knowledgeSnapshot()
    try! lexiconWithoutAuthority.seedLanguagePrior(
        for: AgentID(rawValue: "remote")!,
        senseIDs: languageSmokeSenseIDs
    )
    let authorityRefusalBytes = try! lexiconWithoutAuthority.durableStateBytes()
    var missingBeliefAuthority = false
    do {
        _ = try lexiconWithoutAuthority.communicateLanguageSemanticContent(
            speakerID: AgentID(rawValue: "remote")!,
            recipientID: AgentID(rawValue: "learner")!,
            propositionID: authorityPropositionID,
            renderingMode: .deterministicCompositional
        )
    } catch AgentSessionError.language(.missingBeliefAuthority) {
        missingBeliefAuthority = true
    } catch {}
    check("lexical competence does not grant CIV-41 belief authority",
          missingBeliefAuthority)
    check("missing belief authority refusal is an exact atomic no-op",
          try! lexiconWithoutAuthority.durableStateBytes()
            == authorityRefusalBytes)
    check("seeding and refusal never mutate CIV-41 epistemic state",
          lexiconWithoutAuthority.knowledgeSnapshot()
            == authorityKnowledgeBefore)

    try! session.seedLanguagePrior(
        for: AgentID(rawValue: "teacher")!,
        senseIDs: languageSmokeSenseIDs
    )
    let seeded = session.languageSnapshot()
    check("shared pack does not grant a global dictionary",
          seeded.lexicalAssociations.count == 3
            && Set(seeded.lexicalAssociations.map(\.ownerID.rawValue))
                == ["teacher"]
            && !seeded.lexicalAssociations.contains {
                $0.ownerID.rawValue == "remote"
            })
    let teacherRealization = try! session.realizeLanguageSemanticContent(
        for: AgentID(rawValue: "teacher")!,
        propositionID: propositionID
    )
    check("French provider-off realization is compositional",
          teacherRealization.rendering.text
            == "bois est présent à cellule 2,64,0"
            && teacherRealization.lexicalUses.count == 3)

    let firstExposure = try! session.communicateLanguageSemanticContent(
        speakerID: AgentID(rawValue: "teacher")!,
        recipientID: AgentID(rawValue: "learner")!,
        propositionID: propositionID,
        renderingMode: .deterministicCompositional
    )
    let afterFirst = session.languageSnapshot()
    check("first real exposure creates only acquiring lexical state",
          firstExposure.newlyLearnedSenseIDs.isEmpty
            && afterFirst.lexicalAssociations.filter {
                $0.ownerID.rawValue == "learner"
                    && $0.competence == .acquiring
                    && $0.exposureCount == 1
            }.count == 3)
    var unavailableAfterOneExposure = false
    do {
        _ = try session.realizeLanguageSemanticContent(
            for: AgentID(rawValue: "learner")!,
            propositionID: propositionID
        )
    } catch AgentSessionError.language(.missingLexicalKnowledge) {
        unavailableAfterOneExposure = true
    } catch {}
    check("one exposure does not inject final learned state",
          unavailableAfterOneExposure)

    _ = try! session.advanceTick()
    let secondExposure = try! session.communicateLanguageSemanticContent(
        speakerID: AgentID(rawValue: "teacher")!,
        recipientID: AgentID(rawValue: "learner")!,
        propositionID: propositionID,
        renderingMode: .deterministicCompositional
    )
    let afterSecond = session.languageSnapshot()
    let learnerRealization = try! session.realizeLanguageSemanticContent(
        for: AgentID(rawValue: "learner")!,
        propositionID: propositionID
    )
    check("second historical exposure crosses deterministic learning threshold",
          secondExposure.newlyLearnedSenseIDs.count == 3
            && afterSecond.lexicalAssociations.filter {
                $0.ownerID.rawValue == "learner"
                    && $0.competence == .known
                    && $0.exposureCount == 2
            }.count == 3)
    check("learned lexical history changes realization competence",
          learnerRealization == teacherRealization)
    check("equivalent provider-off realization repeats exactly",
          try! session.realizeLanguageSemanticContent(
            for: AgentID(rawValue: "learner")!,
            propositionID: propositionID
          ) == learnerRealization)
    let knowledgeAfterLearning = session.knowledgeSnapshot()
    check("rendering and exposure leave CIV-41 epistemic rows unchanged",
          knowledgeAfterLearning.propositions
                == knowledgeBeforeLanguage.propositions
            && knowledgeAfterLearning.evidence
                == knowledgeBeforeLanguage.evidence
            && knowledgeAfterLearning.claims
                == knowledgeBeforeLanguage.claims
            && knowledgeAfterLearning.understandings
                == knowledgeBeforeLanguage.understandings
            && knowledgeAfterLearning.beliefs == knowledgeBeforeLanguage.beliefs
            && knowledgeAfterLearning.revisions
                == knowledgeBeforeLanguage.revisions
            && knowledgeAfterLearning.departedBeliefs
                == knowledgeBeforeLanguage.departedBeliefs)

    var (semanticOnly, semanticOnlyPropositionID) = languageSmokePrepared(
        id: "civ42-semantic-only",
        pack: .semanticOnly
    )
    let semanticOnlyRecord = try! semanticOnly
        .communicateLanguageSemanticContent(
            speakerID: AgentID(rawValue: "teacher")!,
            recipientID: AgentID(rawValue: "learner")!,
            propositionID: semanticOnlyPropositionID,
            renderingMode: .noRendering
        )
    check("language-independent semantics do not depend on French strings",
          semanticOnlyRecord.semanticContent == noRendering.semanticContent
            && semanticOnly.languageSnapshot().pack?.languageTag == "und")
    let semanticOnlyBytes = try! semanticOnly.durableStateBytes()
    var semanticOnlyRefusedLexicon = false
    do {
        try semanticOnly.seedLanguagePrior(
            for: AgentID(rawValue: "teacher")!,
            senseIDs: languageSmokeSenseIDs
        )
    } catch AgentSessionError.language(.missingLexicalKnowledge) {
        semanticOnlyRefusedLexicon = true
    } catch {}
    check("unsupported seed refuses instead of inventing lexical knowledge",
          semanticOnlyRefusedLexicon)
    check("unsupported lexical refusal is atomic",
          try! semanticOnly.durableStateBytes() == semanticOnlyBytes)

    let tightConfiguration = try! AgentLanguageConfiguration(
        maximumLexicalAssociations: 4,
        maximumLexicalAssociationsPerAgent: 2,
        maximumCommunicationRecords: 4,
        exposuresRequiredForLearning: 2
    )
    var (tight, _) = languageSmokePrepared(
        id: "civ42-capacity-refusal",
        configuration: tightConfiguration
    )
    let tightBytes = try! tight.durableStateBytes()
    var capacityRefused = false
    do {
        try tight.seedLanguagePrior(
            for: AgentID(rawValue: "teacher")!,
            senseIDs: languageSmokeSenseIDs
        )
    } catch AgentSessionError.language(.capacityReached) {
        capacityRefused = true
    } catch {}
    check("sparse lexical capacity fails closed", capacityRefused)
    check("capacity refusal is an exact atomic no-op",
          try! tight.durableStateBytes() == tightBytes)

    let boundedConfiguration = try! AgentLanguageConfiguration(
        maximumLexicalAssociations: 16,
        maximumLexicalAssociationsPerAgent: 8,
        maximumCommunicationRecords: 4,
        exposuresRequiredForLearning: 2
    )
    var (bounded, boundedPropositionID) = languageSmokePrepared(
        id: "civ42-bounds",
        configuration: boundedConfiguration
    )
    _ = languageSmokeLearn(
        session: &bounded,
        propositionID: boundedPropositionID
    )
    for _ in 0..<10 {
        _ = try! bounded.communicateLanguageSemanticContent(
            speakerID: AgentID(rawValue: "teacher")!,
            recipientID: AgentID(rawValue: "learner")!,
            propositionID: boundedPropositionID,
            renderingMode: .deterministicCompositional
        )
    }
    let boundedSnapshot = bounded.languageSnapshot()
    check("repeated exposure stays sparse under bounded history compaction",
          boundedSnapshot.lexicalAssociations.count == 6
            && boundedSnapshot.communications.count == 4
            && boundedSnapshot.evictedCommunicationCount == 8)
    check("exposure counts compact at the learning threshold",
          boundedSnapshot.lexicalAssociations.filter {
              $0.ownerID.rawValue == "learner"
          }.allSatisfy {
              $0.exposureCount
                == boundedConfiguration.exposuresRequiredForLearning
          })
    check("repeated use creates no agent-agent or concept matrix",
          Set(boundedSnapshot.lexicalAssociations.map(\.ownerID.rawValue))
            == ["teacher", "learner"])

    let deterministicA = languageSmokeDeterministicRun(reversed: false)
    let deterministicB = languageSmokeDeterministicRun(reversed: true)
    check("language history is independent of registration order",
          deterministicA == deterministicB)

    let sameProcessCheckpoint = try! session.makeCheckpoint()
    let sameProcessRestored = try! AgentSimulationSession.restoring(
        sameProcessCheckpoint
    )
    check("CIV-42 checkpoint uses schema 37",
          sameProcessCheckpoint.schemaVersion == 37)
    check("same-process restore preserves language state exactly",
          sameProcessRestored.languageSnapshot() == session.languageSnapshot())
    check("same-process restore preserves exact durable bytes",
          try! sameProcessRestored.durableStateBytes()
            == session.durableStateBytes())

    let semanticMismatchCheckpoint = languageSmokeResignedCheckpoint(
        sameProcessCheckpoint,
        mutateDurable: languageSmokeMutateSemanticReferent
    )
    let semanticMismatchReason = languageSmokeInvalidLanguageReason(
        semanticMismatchCheckpoint
    )
    check("Attack A: re-signed semantic/source mismatch is rejected",
          semanticMismatchReason == "semantic authority mismatch")

    let seededFabricationCheckpoint = languageSmokeResignedCheckpoint(
        sameProcessCheckpoint
    ) { durable in
        languageSmokeMutateAssociationToUngrant(
            &durable,
            ownerID: "teacher",
            source: "seededPrior"
        )
    }
    let seededFabricationReason = languageSmokeInvalidLanguageReason(
        seededFabricationCheckpoint
    )
    check("Attack B: re-signed fabricated seeded competence is rejected",
          seededFabricationReason == "seeded lexical acquisition")

    let exposureFabricationCheckpoint = languageSmokeResignedCheckpoint(
        sameProcessCheckpoint
    ) { durable in
        languageSmokeMutateAssociationToUngrant(
            &durable,
            ownerID: "learner",
            source: "exposure"
        )
    }
    let exposureFabricationReason = languageSmokeInvalidLanguageReason(
        exposureFabricationCheckpoint
    )
    check("Attack C: re-signed fabricated exposure competence is rejected",
          exposureFabricationReason == "lexical acquisition history")

    let compactedHostile = languageSmokeCompactedFixture()
    let compactedSnapshot = compactedHostile.languageSnapshot()
    let compactedLedger = compactedHostile.causalLedgerSnapshot().summary
    let compactedCheckpoint = try! compactedHostile.makeCheckpoint()
    let compactedRestored = try! AgentSimulationSession.restoring(
        compactedCheckpoint
    )
    check("legitimate causal and communication compaction retains bounded proofs",
          compactedSnapshot.communications.count == 1
            && compactedSnapshot.evictedCommunicationCount == 2
            && compactedSnapshot.exposureReceipts.count == 2
            && compactedLedger.droppedEventCount
                >= compactedSnapshot.communications[0]
                    .communicationEventID.sequence.rawValue)
    check("legitimate compacted schema-37 state restarts byte exactly",
          try! compactedRestored.durableStateBytes()
            == compactedHostile.durableStateBytes())

    let compactedSemanticCheckpoint = languageSmokeResignedCheckpoint(
        compactedCheckpoint,
        mutateDurable: languageSmokeMutateSemanticReferent
    )
    let compactedSemanticReason = languageSmokeInvalidLanguageReason(
        compactedSemanticCheckpoint
    )
    check("Attack A compacted: semantic/source mismatch remains rejected",
          compactedSemanticReason == "semantic authority mismatch")

    let compactedFabricationCheckpoint = languageSmokeResignedCheckpoint(
        compactedCheckpoint
    ) { durable in
        languageSmokeMutateAssociationToUngrant(
            &durable,
            ownerID: "learner",
            source: "exposure"
        )
    }
    let compactedFabricationReason = languageSmokeInvalidLanguageReason(
        compactedFabricationCheckpoint
    )
    check("Attack D: compacted provenance cannot fabricate competence",
          compactedFabricationReason == "lexical acquisition history")

    let fabricatedSeedCheckpoint = languageSmokeResignedCheckpoint(
        compactedCheckpoint,
        mutateDurable: languageSmokeFabricateSeedReceiptAndAssociation
    )
    let fabricatedSeedReason = languageSmokeInvalidLanguageReason(
        fabricatedSeedCheckpoint
    )
    check("Attack E: fabricated seed receipt plus competence is rejected",
          fabricatedSeedReason == "language provenance boundary")

    let fabricatedExposureCheckpoint = languageSmokeResignedCheckpoint(
        compactedCheckpoint,
        mutateDurable:
            languageSmokeFabricateExposureReceiptsAndCompetence
    )
    let fabricatedExposureReason = languageSmokeInvalidLanguageReason(
        fabricatedExposureCheckpoint
    )
    check("Attack F: fabricated exposure receipts plus competence are rejected",
          fabricatedExposureReason == "language provenance boundary")

    let fabricatedAuthorityCheckpoint = languageSmokeResignedCheckpoint(
        compactedCheckpoint,
        mutateDurable: languageSmokeFabricateHistoricalAuthorityReference
    )
    let fabricatedAuthorityReason = languageSmokeInvalidKnowledgeReason(
        fabricatedAuthorityCheckpoint
    )
    let compactedKnowledge = compactedHostile.knowledgeSnapshot()
    check("Attack G: language cannot manufacture CIV-41 historical authority",
          fabricatedAuthorityReason
            == "historical authority bound or reference"
            && compactedKnowledge.historicalBeliefAuthorities.count == 1
            && compactedKnowledge.historicalBeliefAuthorityBoundary != nil)
    check("valid compacted control preserves authentic learned competence",
          compactedSnapshot.lexicalAssociations.filter {
              $0.ownerID.rawValue == "learner"
                    && $0.competence == .known
          }.count == 3
            && compactedSnapshot.provenanceBoundary != nil)

    let (schema36Session, _) = languageSmokeKnowledgeSession(
        id: "civ42-schema36-compatibility",
        agents: [
            languageSmokeAgent("teacher", x: 0),
            languageSmokeAgent("learner", x: 1),
        ]
    )
    let schema36Checkpoint = try! schema36Session.makeCheckpoint()
    let schema36Bytes = try! AgentCheckpointCodec.encode(schema36Checkpoint)
    let schema36Restored = try! AgentSimulationSession.restoring(
        AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: schema36Bytes
        )
    )
    check("published schema-36 state restores without fabricated language",
          schema36Checkpoint.schemaVersion == 36
            && !schema36Restored.languageEnabled
            && schema36Restored.languageSnapshot().communications.isEmpty)
    check("schema-36 compatibility round trip remains byte exact",
          try! AgentCheckpointCodec.encode(schema36Restored.makeCheckpoint())
            == schema36Bytes)

    var (replaySession, replayPropositionID) = languageSmokeKnowledgeSession(
        id: "civ42-replay",
        agents: [
            languageSmokeAgent("teacher", x: 0),
            languageSmokeAgent("learner", x: 1),
        ]
    )
    let replayBase = try! replaySession.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayBase,
        session: replaySession
    )
    _ = try! recorder.apply(
        .setLanguageEnabled(
            true,
            configuration: .live,
            pack: .frenchReference
        ),
        to: &replaySession
    )
    _ = try! recorder.apply(
        .seedLanguagePrior(
            agentID: AgentID(rawValue: "teacher")!,
            senseIDs: languageSmokeSenseIDs
        ),
        to: &replaySession
    )
    for _ in 0..<2 {
        _ = try! recorder.apply(
            .communicateLanguageSemanticContent(
                speakerID: AgentID(rawValue: "teacher")!,
                recipientID: AgentID(rawValue: "learner")!,
                propositionID: replayPropositionID,
                renderingMode: .deterministicCompositional
            ),
            to: &replaySession
        )
    }
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "civ42-replay")!
    )
    let replayedA = try! AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: journal
    )
    let replayedB = try! AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: journal
    )
    check("replay journal upgrades honestly to schema 37",
          journal.manifest.schemaVersion == 37)
    let replayedBytes = try! replayedA.session.durableStateBytes()
    let recordedBytes = try! replaySession.durableStateBytes()
    check("replay reproduces exact CIV-42 durable state",
          replayedA.report.verified
            && replayedBytes == recordedBytes)
    check("repeated replay duplicates no lexical or communication state",
          replayedA.session.languageSnapshot()
            == replayedB.session.languageSnapshot()
            && replayedA.session.languageSummary()
                == replaySession.languageSummary())

    let scaleAgents = (0..<24).map { index in
        if index == 0 { return languageSmokeAgent("teacher", x: 0) }
        if index == 1 { return languageSmokeAgent("learner", x: 1) }
        return languageSmokeAgent(
            String(format: "scale_%02d", index),
            x: 100 + index * 3
        )
    }
    var (scale, scalePropositionID) = languageSmokePrepared(
        id: "civ42-scale",
        agents: scaleAgents
    )
    _ = languageSmokeLearn(
        session: &scale,
        propositionID: scalePropositionID
    )
    let scaleSnapshot = scale.languageSnapshot()
    check("24-agent language state remains local to causal participants",
          scaleSnapshot.lexicalAssociations.count == 6
            && Set(scaleSnapshot.lexicalAssociations.map(\.ownerID.rawValue))
                == ["teacher", "learner"])

    var (mortality, mortalityPropositionID) = languageSmokePrepared(
        id: "civ42-mortality",
        agents: [
            languageSmokeAgent("agent_0", x: 0),
            languageSmokeAgent("agent_1", x: 1),
            languageSmokeAgent("agent_2", x: 30, lethalWhenEnabled: true),
        ],
        teacherID: "agent_0",
        learnerID: "agent_1"
    )
    try! mortality.seedLanguagePrior(
        for: AgentID(rawValue: "agent_2")!,
        senseIDs: languageSmokeSenseIDs
    )
    _ = languageSmokeLearn(
        session: &mortality,
        propositionID: mortalityPropositionID,
        teacherID: "agent_0",
        learnerID: "agent_1"
    )
    try! mortality.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    mortality.setSurvivalEnabled(true)
    try! mortality.setMortalityEnabled(true)
    for _ in 0..<64 where mortality.snapshot().agents.contains(where: {
        $0.id == "agent_2"
    }) {
        _ = try! mortality.advanceTick()
    }
    let mortalityLanguage = mortality.languageSnapshot()
    check("finalized mortality retires departed current lexical competence",
          !mortality.snapshot().agents.contains { $0.id == "agent_2" }
            && !mortalityLanguage.lexicalAssociations.contains {
                $0.ownerID.rawValue == "agent_2"
            }
            && mortalityLanguage.lexicalAssociations.count == 6
            && mortalityLanguage.retiredLexicalAssociationCount == 3)
    check("bounded semantic history survives unrelated lexical-owner death",
          mortalityLanguage.communications.count == 2
            && mortality.knowledgeSnapshot().beliefs.contains {
                $0.ownerID.rawValue == "agent_0"
            })
    let mortalityCheckpoint = try! mortality.makeCheckpoint()
    let mortalityRestored = try! AgentSimulationSession.restoring(
        mortalityCheckpoint
    )
    check("post-mortality schema-37 restart preserves lifecycle composition",
          mortalityCheckpoint.schemaVersion == 37
            && mortalityRestored.languageSnapshot() == mortalityLanguage)

    let languageKinds = Set(
        session.causalLedgerSnapshot().events.map(\.kind)
    )
    check("causal ledger distinguishes language transitions", [
        AgentCausalEventKind.languageInitialized,
        .languagePriorSeeded,
        .languageSemanticCommunicated,
    ].allSatisfy { languageKinds.contains($0) })

    print("  CIV42_DECISIVE semantic=\(noRendering.semanticContent.digest) first=\(firstExposure.newlyLearnedSenseIDs.count) second=\(secondExposure.newlyLearnedSenseIDs.count) text=\(learnerRealization.rendering.text ?? "NO_RENDERING") language=\(afterSecond.digest)")
    print("  CIV42_BOUNDS associations=\(boundedSnapshot.lexicalAssociations.count)/\(boundedConfiguration.maximumLexicalAssociations) communications=\(boundedSnapshot.communications.count)/\(boundedConfiguration.maximumCommunicationRecords) evicted=\(boundedSnapshot.evictedCommunicationCount)")
    print("  CIV42_RESTART schema=\(sameProcessCheckpoint.schemaVersion) digest=\(sameProcessCheckpoint.semanticDigest.rawValue) language=\(sameProcessRestored.languageSnapshot().digest)")
    print("  CIV42_REPLAY records=\(journal.records.count) schema=\(journal.manifest.schemaVersion) verified=\(replayedA.report.verified)")
    print("  CIV42_LIFECYCLE retired=\(mortalityLanguage.retiredLexicalAssociationCount) current=\(mortalityLanguage.lexicalAssociations.count) communications=\(mortalityLanguage.communications.count)")
    print("  CIV42_HOSTILE A=\(semanticMismatchReason ?? "accepted") A_compacted=\(compactedSemanticReason ?? "accepted") B=\(seededFabricationReason ?? "accepted") C=\(exposureFabricationReason ?? "accepted") D=\(compactedFabricationReason ?? "accepted") E=\(fabricatedSeedReason ?? "accepted") F=\(fabricatedExposureReason ?? "accepted") G=\(fabricatedAuthorityReason ?? "accepted") dropped=\(compactedLedger.droppedEventCount) receipts=\(compactedSnapshot.exposureReceipts.count) knowledgeAuthorities=\(compactedKnowledge.historicalBeliefAuthorities.count)")
}
