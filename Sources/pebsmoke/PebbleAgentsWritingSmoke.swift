import Foundation
@_spi(Testing) import PebbleAgents
import PebbleCore

private let writingAuthor = AgentID(rawValue: "agent_0")!
private let writingReader = AgentID(rawValue: "agent_1")!
private let writingRemote = AgentID(rawValue: "agent_2")!
private let writingCell = AgentPosition(x: 1, y: 64, z: 0)

private func writingAgent(
    _ id: AgentID,
    x: Int,
    lethal: Bool = false,
    health: Int? = nil
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id.rawValue,
        state: "idle",
        position: position,
        needs: AgentNeeds(
            hunger: lethal ? 0.39 : -10,
            fatigue: 0,
            curiosity: 0,
            safety: 1
        ),
        health: health ?? (lethal ? 26 : 100),
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "CIV-45 fixture",
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


private func writingPrepared(reversed: Bool = false, maximumArtifacts: Int = 4,
    maximumReadings: Int = 8, maximumLiteracyRecords: Int = 4,
    knowledgeConfiguration: AgentKnowledgeConfiguration = .live,
    languageConfiguration: AgentLanguageConfiguration = .live, readerVocabulary: Bool = true,
    writingEnabled: Bool = true, lethalID: AgentID? = nil,
    starvationDamage: Int = 100, readerHealth: Int? = nil) throws -> (AgentSimulationSession, AgentKnowledgePropositionID) {
    let survival = lethalID == nil ? AgentSurvivalConfiguration.live : try!
        AgentSurvivalConfiguration(
            hungerPerTick: 1,
            fatiguePerTick: AgentSurvivalConfiguration.live.fatiguePerTick,
            hungryThreshold: AgentSurvivalConfiguration.live.hungryThreshold,
            criticalHungerThreshold:
                AgentSurvivalConfiguration.live.criticalHungerThreshold,
            hungerRecoveryThreshold:
                AgentSurvivalConfiguration.live.hungerRecoveryThreshold,
            fatigueThreshold:
                AgentSurvivalConfiguration.live.fatigueThreshold,
            fatigueRecoveryThreshold:
                AgentSurvivalConfiguration.live.fatigueRecoveryThreshold,
            foodNutrition: AgentSurvivalConfiguration.live.foodNutrition,
            restRecoveryPerTick:
                AgentSurvivalConfiguration.live.restRecoveryPerTick,
            starvationGraceTicks: 0,
            starvationDamagePerTick: starvationDamage
        )
    let agents = [writingAgent(writingAuthor, x: 0, lethal: lethalID == writingAuthor),
                  writingAgent(writingReader, x: 2, lethal: lethalID == writingReader, health: readerHealth),
                  writingAgent(writingRemote, x: 10)]
    var session = try AgentSimulationSession(configuration: try AgentSessionConfiguration(
        seed: 45, nearbyRadius: 16, resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 64),
        survivalConfiguration: survival),
        agents: reversed ? Array(agents.reversed()) : agents,
        simulationID: try AgentSimulationID(validating: "civ45-writing"),
        causalLedgerPolicy: .bounded(maxEvents: 64))
    try session.setSocialEnabled(true)
    try session.setKnowledgeGraphEnabled(true, configuration: knowledgeConfiguration)
    _ = try session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: writingAuthor.rawValue, socialResourceObservations: [AgentResourceObservation(
            resource: .wood, target: AgentPosition(x: 3, y: 64, z: 0), direction: .east,
            distanceManhattan: 3, quantityAvailable: 1, source: .naturalWorld,
            expectedBlockFingerprint: Int(bid("oak_log")) << 4)])])
    let proposition = session.knowledgeSnapshot().beliefs.first { $0.ownerID == writingAuthor }!.propositionID
    try session.setLanguageEnabled(true, configuration: languageConfiguration)
    let senses = AgentLanguagePack.frenchReference.entries.map(\.senseID)
    try session.seedLanguagePrior(for: writingAuthor, senseIDs: senses)
    if readerVocabulary { try session.seedLanguagePrior(for: writingReader, senseIDs: senses) }
    if writingEnabled { try session.setWritingEnabled(true, worldID: "civ45-world",
        configuration: try AgentWritingConfiguration(maximumArtifacts: maximumArtifacts,
            maximumReadings: maximumReadings, maximumLiteracyRecords: maximumLiteracyRecords)) }
    return (session, proposition)
}

private func writingReceipt(_ plan: AgentWritingPlan, actorID: AgentID, tick: Int) -> AgentWritingPhysicalReceipt {
    AgentWritingPhysicalReceipt(worldID: plan.worldID, dimension: plan.dimension,
        cell: plan.cell, blockKey: "oak_sign", artifactID: plan.artifactID, materialID: plan.materialID,
        contentDigest: plan.contentDigest, lines: plan.lines, actorID: actorID,
        actorPosition: AgentPosition(x: actorID == writingAuthor ? 0 : actorID == writingReader ? 2 : 10,
                                     y: 64, z: 0), observedAtTick: tick)
}

private func writingRefusal(_ name: String, session: AgentSimulationSession,
    operation: (inout AgentSimulationSession) throws -> Void) {
    var candidate = session
    let before = try! candidate.durableStateBytes()
    do { try operation(&candidate); check(name, false, "unexpected success") }
    catch { check(name, true, "\(error)") }
    check(name + " atomic", try! candidate.durableStateBytes() == before)
}

private func writingResignedCheckpoint(
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


private func writingRestoreRefuses(_ name: String, checkpoint: AgentSessionCheckpoint,
    mutation: (inout [String: Any]) -> Void) {
    let hostile = writingResignedCheckpoint(checkpoint, mutateDurable: mutation)
    do { _ = try AgentSimulationSession.restoring(hostile); check(name, false, "accepted signed malformed state") }
    catch { check(name, true, "\(error)") }
}

func runPebbleAgentsWritingSmoke() {
    let originalPhysicalCounter = peekNextEntityId()
    defer { resetEntityIds(originalPhysicalCounter) }
    section("CIV-45 writing, material identity and literacy")
    do {
        var (session, proposition) = try writingPrepared()
        writingRefusal("oral vocabulary alone cannot write", session: session) {
            _ = try $0.prepareWriting(authorID: writingAuthor, propositionID: proposition, materialID: peekNextEntityId(), dimension: "0", cell: writingCell)
        }
        try session.seedWritingEducationalPrior(for: writingAuthor)
        writingRefusal("uninformed author cannot invent source belief", session: session) {
            _ = try $0.prepareWriting(authorID: writingReader, propositionID: proposition, materialID: peekNextEntityId(), dimension: "0", cell: writingCell)
        }
        let plan = try session.prepareWriting(authorID: writingAuthor, propositionID: proposition,
            materialID: peekNextEntityId(), dimension: "0", cell: writingCell,
            assertion: .deliberateCounterAssertion(.resource(kind: .stone, fingerprint: nil)))
        let authorBeliefs = session.knowledgeSnapshot().beliefs
        let evidence = session.knowledgeSnapshot().evidence
        let world = World(dim: .overworld, seed: 45)
        let chunk = Chunk(cx: 0, cz: 0, minY: GEN_MIN_Y, height: WORLD_H)
        world.setChunk(chunk)
        world.setBlock(1, 63, 0, Int(bid("stone")) << 4, SET_SILENT)
        world.setBlock(1, 64, 0, Int(bid("oak_sign")) << 4, SET_SILENT)
        world.setBlockEntity(makeSignBE(1, 64, 0))
        world.setBlock(3, 64, 0, Int(bid("oak_log")) << 4, SET_SILENT)
        let stamp = try SignInscription(artifactID: plan.artifactID, materialID: plan.materialID, contentDigest: plan.contentDigest,
            worldID: plan.worldID, dimension: 0, x: 1, y: 64, z: 0, lines: plan.lines)
        try world.inscribeSign(stamp)
        let artifact = try session.acceptWriting(plan, receipt: writingReceipt(plan, actorID: writingAuthor, tick: session.tick))
        check("explicit false assertion does not change author's private belief",
              session.knowledgeSnapshot().beliefs == authorBeliefs)
        check("real Core sign holds assertion and identity", try world.inspectSignInscription(at: 1, 64, 0) == stamp)
        check("asserted stone contradicts real unchanged oak log", plan.lines.first == "pierre" && world.getBlock(3, 64, 0) == Int(bid("oak_log")) << 4)
        writingRefusal("duplicate inscription refused", session: session) {
            _ = try $0.acceptWriting(plan, receipt: writingReceipt(plan, actorID: writingAuthor, tick: $0.tick))
        }
        writingRefusal("oral vocabulary alone cannot read", session: session) {
            _ = try $0.readWriting(artifactID: artifact.artifactID, readerID: writingReader,
                                  receipt: writingReceipt(plan, actorID: writingReader, tick: $0.tick))
        }
        let beforeLearning = session.knowledgeSnapshot()
        try session.practiceWritingNotation(artifactID: artifact.artifactID, teacherID: writingAuthor,
            learnerID: writingReader, teacherReceipt: writingReceipt(plan, actorID: writingAuthor, tick: session.tick),
            learnerReceipt: writingReceipt(plan, actorID: writingReader, tick: session.tick))
        check("one guided use does not grant notation", !session.canUseWritingNotation(writingReader))
        writingRefusal("same-tick lesson cannot be counted twice", session: session) {
            try $0.practiceWritingNotation(artifactID: artifact.artifactID, teacherID: writingAuthor,
                learnerID: writingReader, teacherReceipt: writingReceipt(plan, actorID: writingAuthor, tick: $0.tick),
                learnerReceipt: writingReceipt(plan, actorID: writingReader, tick: $0.tick))
        }
        check("first notation practice creates no belief", session.knowledgeSnapshot().beliefs == beforeLearning.beliefs)
        _ = try session.advanceTick(perceptions: [])
        let beforeSecondLesson = session.knowledgeSnapshot().beliefs
        try session.practiceWritingNotation(artifactID: artifact.artifactID, teacherID: writingAuthor,
            learnerID: writingReader, teacherReceipt: writingReceipt(plan, actorID: writingAuthor, tick: session.tick),
            learnerReceipt: writingReceipt(plan, actorID: writingReader, tick: session.tick))
        check("two distinct local guided uses teach notation", session.canUseWritingNotation(writingReader))
        check("notation practice never creates reader belief", session.knowledgeSnapshot().beliefs == beforeSecondLesson)
        let checkpoint = try session.makeCheckpoint()
        let bytes = try AgentCheckpointCodec.encode(checkpoint)
        session = try AgentSimulationSession.restoring(checkpoint)
        check("learned notation and inscription restart byte-exact", try AgentCheckpointCodec.encode(session.makeCheckpoint()) == bytes)
        check("checkpoint schema 40", checkpoint.schemaVersion == 40)
        var recorder = try AgentReplayRecorder(checkpoint: checkpoint, session: session)
        let otherAuthorities = try writingOtherAuthorities(session)
        _ = try recorder.apply(.readWriting(artifactID: artifact.artifactID, readerID: writingReader,
            receipt: writingReceipt(plan, actorID: writingReader, tick: session.tick)), to: &session)
        let reading = session.writingState!.readings.last!
        check("reading grants no authority outside knowledge language writing", try writingOtherAuthorities(session) == otherAuthorities)
        check("reading creates attributed CIV-41 written claim", session.knowledgeSnapshot().claims.contains {
            $0.claimID == reading.claimID && $0.writtenSource?.artifactID == artifact.artifactID
                && $0.sourceAgentID == writingAuthor && $0.sourceEvidenceID == nil
        })
        check("reader belief follows assertion without changing evidence", session.knowledgeSnapshot().beliefs.contains {
            $0.ownerID == writingReader && $0.propositionID == plan.assertedProposition.propositionID
        } && session.knowledgeSnapshot().evidence == evidence)
        check("remote agent gains no cognition", !session.knowledgeSnapshot().beliefs.contains { $0.ownerID == writingRemote })
        check("World remains wood after false reading", world.getBlock(3, 64, 0) == Int(bid("oak_log")) << 4)
        let journal = try recorder.journal(named: AgentCheckpointName(rawValue: "civ45-replay")!)
        let replay = try AgentSessionReplayer.replay(checkpoint: checkpoint, journal: journal)
        check("recorded reading replay exact", try replay.session.durableStateBytes() == session.durableStateBytes())
        writingRefusal("duplicate reading does not reaffirm", session: session) {
            _ = try $0.readWriting(artifactID: artifact.artifactID, readerID: writingReader,
                                  receipt: writingReceipt(plan, actorID: writingReader, tick: $0.tick))
        }
        writingRefusal("remote material access refuses", session: session) {
            _ = try $0.readWriting(artifactID: artifact.artifactID, readerID: writingRemote,
                                  receipt: writingReceipt(plan, actorID: writingRemote, tick: $0.tick))
        }
        for _ in 0..<120 { _ = try session.advanceTick(perceptions: []) }
        let compacted = try session.makeCheckpoint()
        let restored = try AgentSimulationSession.restoring(compacted)
        check("causal FIFO compaction preserves inscription and reading authority",
              try session.causalLedgerSnapshot().summary.droppedEventCount > 0 && (try restored.durableStateBytes() == session.durableStateBytes()))
        for (label, key) in [("duplicate artifact", "artifacts"), ("duplicate reading", "readings"), ("duplicate literacy", "literacyRecords")] {
            writingRestoreRefuses(label, checkpoint: compacted) { state in
                var writing = state["writingState"] as! [String: Any]
                var rows = writing[key] as! [[String: Any]]; rows.append(rows[0]); writing[key] = rows
                state["writingState"] = writing
            }
        }
        writingRestoreRefuses("missing historical authority", checkpoint: compacted) { state in
            var knowledge = state["knowledgeGraphState"] as! [String: Any]
            knowledge["historicalBeliefAuthorities"] = []; state["knowledgeGraphState"] = knowledge
        }
        writingRestoreRefuses("impossible ordinal", checkpoint: compacted) { state in
            var writing = state["writingState"] as! [String: Any]
            writing["nextArtifactOrdinal"] = 0; state["writingState"] = writing
        }
        writingRestoreRefuses("fabricated content after compaction", checkpoint: compacted) { state in
            var writing = state["writingState"] as! [String: Any]
            var rows = writing["artifacts"] as! [[String: Any]]
            var plan = rows[0]["plan"] as! [String: Any]; plan["lines"] = ["forged", "text", "at", "0"]
            rows[0]["plan"] = plan; writing["artifacts"] = rows; state["writingState"] = writing
        }
        let beBytes = try JSONEncoder().encode(world.getBlockEntity(1, 64, 0)!)
        let loadedBE = try JSONDecoder().decode(BlockEntityData.self, from: beBytes)
        world.setBlockEntity(loadedBE)
        check("Core persisted material identity roundtrip", try world.inspectSignInscription(at: 1, 64, 0) == stamp)
        loadedBE.lines = ["changed", "", "", ""]
        check("normal line edit invalidates physical identity", loadedBE.signInscription == nil)
        loadedBE.lines = plan.lines
        check("retyping old content cannot resurrect identity", loadedBE.signInscription == nil)
        world.setBlock(1, 64, 0, 0, SET_SILENT)
        world.setBlock(1, 64, 0, Int(bid("oak_sign")) << 4, SET_SILENT)
        world.setBlockEntity(makeSignBE(1, 64, 0))
        do { _ = try world.inspectSignInscription(at: 1, 64, 0); check("replacement cannot resurrect", false) }
        catch { check("replacement cannot resurrect", true) }
        let replacementPlan = try session.prepareWriting(authorID: writingAuthor, propositionID: proposition,
            materialID: peekNextEntityId(), dimension: "0", cell: writingCell)
        check("same site new inscription has different identity", replacementPlan.artifactID != plan.artifactID)
        var (newCivilization, newSource) = try writingPrepared()
        try newCivilization.seedWritingEducationalPrior(for: writingAuthor)
        let newPlan = try newCivilization.prepareWriting(authorID: writingAuthor, propositionID: newSource,
            materialID: peekNextEntityId(), dimension: "0", cell: writingCell, assertion: plan.assertion)
        let newStamp = try SignInscription(artifactID: newPlan.artifactID, materialID: newPlan.materialID,
            contentDigest: newPlan.contentDigest, worldID: newPlan.worldID, dimension: 0,
            x: 1, y: 64, z: 0, lines: newPlan.lines)
        try world.inscribeSign(newStamp)
        _ = try newCivilization.acceptWriting(newPlan, receipt: writingReceipt(newPlan, actorID: writingAuthor, tick: newCivilization.tick))
        let observedReplacement = try world.inspectSignInscription(at: 1, 64, 0)
        check("recreated session same ordinal same site same text has new Core identity",
            newPlan.ordinal == plan.ordinal && newPlan.lines == plan.lines && newPlan.cell == plan.cell
            && newPlan.materialID != plan.materialID && newPlan.artifactID != plan.artifactID
            && observedReplacement == newStamp)
        writingRefusal("new-session material cannot resurrect old historical authority", session: session) {
            _ = try $0.readWriting(artifactID: plan.artifactID, readerID: writingReader,
                receipt: writingReceipt(newPlan, actorID: writingReader, tick: $0.tick))
        }
        var (bounded, boundedProposition) = try writingPrepared(maximumArtifacts: 1, maximumReadings: 1)
        try bounded.seedWritingEducationalPrior(for: writingAuthor)
        let boundedPlan = try bounded.prepareWriting(authorID: writingAuthor, propositionID: boundedProposition, materialID: peekNextEntityId(), dimension: "0", cell: writingCell)
        _ = try bounded.acceptWriting(boundedPlan, receipt: writingReceipt(boundedPlan, actorID: writingAuthor, tick: bounded.tick))
        writingRefusal("artifact capacity refuses without evicting content", session: bounded) {
            _ = try $0.prepareWriting(authorID: writingAuthor, propositionID: boundedProposition, materialID: peekNextEntityId(), dimension: "0", cell: writingCell)
        }
        try bounded.seedWritingEducationalPrior(for: writingReader)
        _ = try bounded.readWriting(artifactID: boundedPlan.artifactID, readerID: writingReader,
                                    receipt: writingReceipt(boundedPlan, actorID: writingReader, tick: bounded.tick))
        _ = try bounded.advanceTick(perceptions: [])
        writingRefusal("reading capacity refuses without evicting accepted history", session: bounded) {
            _ = try $0.readWriting(artifactID: boundedPlan.artifactID, readerID: writingReader,
                                   receipt: writingReceipt(boundedPlan, actorID: writingReader, tick: $0.tick))
        }
        check("saturated artifact and reading state restores byte-exact", try AgentSimulationSession.restoring(bounded.makeCheckpoint())
            .durableStateBytes() == bounded.durableStateBytes())
        for deceased in [writingAuthor, writingReader] {
            var (mortal, known) = try writingPrepared(lethalID: deceased)
            try mortal.seedWritingEducationalPrior(for: writingAuthor)
            try mortal.seedWritingEducationalPrior(for: writingReader)
            let mortalPlan = try mortal.prepareWriting(authorID: writingAuthor, propositionID: known,
                materialID: peekNextEntityId(), dimension: "0", cell: writingCell)
            _ = try mortal.acceptWriting(mortalPlan, receipt: writingReceipt(mortalPlan, actorID: writingAuthor, tick: mortal.tick))
            _ = try mortal.readWriting(artifactID: mortalPlan.artifactID, readerID: writingReader,
                receipt: writingReceipt(mortalPlan, actorID: writingReader, tick: mortal.tick))
            try mortal.initializePopulationRegistry(settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
                receptionPosition: AgentPosition(x: 0, y: 64, z: 0))
            let mortalityBase = try mortal.makeCheckpoint()
            var mortalityRecorder = try AgentReplayRecorder(checkpoint: mortalityBase, session: mortal)
            _ = try mortalityRecorder.apply(.setSurvivalEnabled(true), to: &mortal)
            _ = try mortalityRecorder.apply(.setMortalityEnabled(true, configuration: .live), to: &mortal)
            _ = try mortalityRecorder.apply(.advanceTick(perceptions: [], physicalObservations: []), to: &mortal)
            check("finalized death removes current literacy capability \(deceased.rawValue)",
                !mortal.snapshot().agents.contains { $0.id == deceased.rawValue } && !mortal.canUseWritingNotation(deceased))
            check("death preserves accepted material inscription history \(deceased.rawValue)", mortal.writingState!.artifacts.count == 1)
            let afterDeath = try AgentSimulationSession.restoring(mortal.makeCheckpoint())
            check("death restore exact without cognitive resurrection \(deceased.rawValue)", try afterDeath.durableStateBytes() == mortal.durableStateBytes())
            let mortalityJournal = try mortalityRecorder.journal(named: AgentCheckpointName(rawValue: "civ45-mortality")!)
            let deathReplay = try AgentSessionReplayer.replay(checkpoint: mortalityBase, journal: mortalityJournal)
            check("mortality replay exact \(deceased.rawValue)", try deathReplay.report.verified && deathReplay.session.durableStateBytes() == mortal.durableStateBytes())
            if deceased == writingAuthor {
                _ = try mortal.readWriting(artifactID: mortalPlan.artifactID, readerID: writingReader,
                    receipt: writingReceipt(mortalPlan, actorID: writingReader, tick: mortal.tick))
                check("dead author historical content remains locally readable", mortal.writingState!.readings.count == 2)
            }
        }
        var (ordered, _) = try writingPrepared(reversed: true)
        try ordered.seedWritingEducationalPrior(for: writingAuthor)
        let orderedPlan = try ordered.prepareWriting(authorID: writingAuthor, propositionID: proposition,
            materialID: plan.materialID, dimension: "0", cell: writingCell, assertion: plan.assertion)
        check("registration-order independent writing plan", orderedPlan == plan)
        try writingExtendedProofs(compacted: compacted, plan: plan, beBytes: beBytes)
        print("CIV45_DECISIVE artifact=\(artifact.artifactID) assertion=stone world=wood authorBelief=wood readerBelief=stone schema=40 dropped=\(session.causalLedgerSnapshot().summary.droppedEventCount)")
    } catch { check("CIV-45 scenario completes", false, "\(error)") }
}

private func writingExtendedProofs(compacted: AgentSessionCheckpoint, plan: AgentWritingPlan, beBytes: Data) throws {
    section("CIV-45 activation replay, bounded retention and hostile inputs")
    var (replayed, proposition) = try writingPrepared(writingEnabled: false)
    let oldCheckpoint = try replayed.makeCheckpoint()
    check("pre-writing checkpoint retains version 37", oldCheckpoint.schemaVersion == 37)
    check("old cognition restores with no implicit writing capability",
          try AgentSimulationSession.restoring(oldCheckpoint).writingState == nil)
    var recorder = try AgentReplayRecorder(checkpoint: oldCheckpoint, session: replayed)
    _ = try recorder.apply(.setWritingEnabled(enabled: true, worldID: "civ45-world", configuration: .live), to: &replayed)
    _ = try recorder.apply(.seedWritingEducationalPrior(ownerID: writingAuthor), to: &replayed)
    let prepared = try replayed.prepareWriting(authorID: writingAuthor, propositionID: proposition,
        materialID: peekNextEntityId(), dimension: "0", cell: writingCell, assertion: plan.assertion)
    _ = try recorder.apply(.acceptWriting(plan: prepared, receipt: writingReceipt(prepared, actorID: writingAuthor, tick: replayed.tick)), to: &replayed)
    for lesson in 0..<2 {
        if lesson > 0 { _ = try recorder.apply(.advanceTick(perceptions: [], physicalObservations: []), to: &replayed) }
        _ = try recorder.apply(.practiceWritingNotation(artifactID: prepared.artifactID, teacherID: writingAuthor,
            learnerID: writingReader, teacherReceipt: writingReceipt(prepared, actorID: writingAuthor, tick: replayed.tick),
            learnerReceipt: writingReceipt(prepared, actorID: writingReader, tick: replayed.tick)), to: &replayed)
    }
    _ = try recorder.apply(.readWriting(artifactID: prepared.artifactID, readerID: writingReader,
        receipt: writingReceipt(prepared, actorID: writingReader, tick: replayed.tick)), to: &replayed)
    let journal = try recorder.journal(named: AgentCheckpointName(rawValue: "civ45-whole-chain")!)
    let restoredReplay = try AgentSessionReplayer.replay(checkpoint: oldCheckpoint, journal: journal)
    check("full activation inscription lessons reading replay exact", try restoredReplay.report.verified
        && restoredReplay.session.durableStateBytes() == replayed.durableStateBytes())
    writingRefusal("stale accepted plan cannot reroll historical content", session: replayed) {
        _ = try $0.acceptWriting(prepared, receipt: writingReceipt(prepared, actorID: writingAuthor, tick: $0.tick))
    }
    writingRefusal("extreme local coordinates refuse without overflow", session: replayed) {
        _ = try $0.prepareWriting(authorID: writingAuthor, propositionID: proposition,
            materialID: peekNextEntityId(), dimension: "0", cell: AgentPosition(x: Int.min, y: Int.max, z: 0))
    }
    writingRefusal("current source cannot invent fingerprinted physical evidence", session: replayed) {
        _ = try $0.prepareWriting(authorID: writingAuthor, propositionID: proposition,
            materialID: peekNextEntityId() + 1, dimension: "0", cell: writingCell,
            assertion: .deliberateCounterAssertion(.resource(kind: .stone, fingerprint: 123)))
    }
    writingRefusal("CIV-41 dependency cannot be removed", session: replayed) { try $0.setKnowledgeGraphEnabled(false) }
    writingRefusal("CIV-42 dependency cannot be removed", session: replayed) { try $0.setLanguageEnabled(false) }
    let unavailableReceipt = AgentWritingPhysicalReceipt(worldID: "another-world", dimension: prepared.dimension,
        cell: prepared.cell, blockKey: "oak_sign", artifactID: prepared.artifactID, materialID: prepared.materialID,
        contentDigest: prepared.contentDigest, lines: prepared.lines, actorID: writingReader,
        actorPosition: AgentPosition(x: 2, y: 64, z: 0), observedAtTick: replayed.tick + 1)
    _ = try replayed.advanceTick(perceptions: [])
    writingRefusal("different World receipt cannot authorize historical record", session: replayed) {
        _ = try $0.readWriting(artifactID: prepared.artifactID, readerID: writingReader, receipt: unavailableReceipt)
    }
    var (bounded, _) = try writingPrepared(maximumLiteracyRecords: 1)
    try bounded.seedWritingEducationalPrior(for: writingAuthor)
    bounded = try AgentSimulationSession.restoring(bounded.makeCheckpoint())
    writingRefusal("saturated literacy restores then refuses admission", session: bounded) {
        try $0.seedWritingEducationalPrior(for: writingReader)
    }
    var (authorityBound, known) = try writingPrepared(knowledgeConfiguration: try AgentKnowledgeConfiguration(maximumRevisions: 1))
    try authorityBound.seedWritingEducationalPrior(for: writingAuthor)
    try authorityBound.seedWritingEducationalPrior(for: writingReader)
    let boundPlan = try authorityBound.prepareWriting(authorID: writingAuthor, propositionID: known, materialID: peekNextEntityId(), dimension: "0", cell: writingCell)
    _ = try authorityBound.acceptWriting(boundPlan, receipt: writingReceipt(boundPlan, actorID: writingAuthor, tick: authorityBound.tick))
    writingRefusal("CIV-41 historical capacity refuses reading atomically", session: authorityBound) {
        _ = try $0.readWriting(artifactID: boundPlan.artifactID, readerID: writingReader,
            receipt: writingReceipt(boundPlan, actorID: writingReader, tick: $0.tick))
    }
    check("saturated historical authority restart exact", try AgentSimulationSession.restoring(authorityBound.makeCheckpoint())
        .durableStateBytes() == authorityBound.durableStateBytes())
    var (withoutWords, lexicalSource) = try writingPrepared(readerVocabulary: false)
    try withoutWords.seedWritingEducationalPrior(for: writingAuthor)
    try withoutWords.seedWritingEducationalPrior(for: writingReader)
    let lexicalPlan = try withoutWords.prepareWriting(authorID: writingAuthor, propositionID: lexicalSource,
        materialID: peekNextEntityId(), dimension: "0", cell: writingCell)
    _ = try withoutWords.acceptWriting(lexicalPlan, receipt: writingReceipt(lexicalPlan, actorID: writingAuthor, tick: withoutWords.tick))
    writingRefusal("notation alone cannot bypass CIV-42 lexical learning", session: withoutWords) {
        _ = try $0.readWriting(artifactID: lexicalPlan.artifactID, readerID: writingReader,
            receipt: writingReceipt(lexicalPlan, actorID: writingReader, tick: $0.tick))
    }
    var (languagePressure, lexicalProposition) = try writingPrepared(
        languageConfiguration: try AgentLanguageConfiguration(maximumCommunicationRecords: 2))
    try languagePressure.seedWritingEducationalPrior(for: writingAuthor)
    let languagePlan = try languagePressure.prepareWriting(authorID: writingAuthor, propositionID: lexicalProposition,
        materialID: peekNextEntityId(), dimension: "0", cell: writingCell)
    _ = try languagePressure.acceptWriting(languagePlan, receipt: writingReceipt(languagePlan, actorID: writingAuthor, tick: languagePressure.tick))
    for _ in 0..<6 {
        _ = try languagePressure.communicateLanguageSemanticContent(speakerID: writingAuthor,
            recipientID: writingReader, propositionID: lexicalProposition, renderingMode: .deterministicCompositional)
    }
    check("CIV-42 communication compaction does not erase written content",
        try languagePressure.languageState!.evictedCommunicationCount > 0
        && AgentSimulationSession.restoring(languagePressure.makeCheckpoint()).durableStateBytes() == languagePressure.durableStateBytes())
    var (coexistence, _) = try writingPrepared()
    try coexistence.setOralTransmissionEnabled(true)
    try coexistence.setAutonomousActivityEnabled(true)
    try coexistence.setLongDistanceCommunicationEnabled(true)
    for _ in 0..<40 { _ = try coexistence.advanceTick(perceptions: []) }
    check("CIV-41 through CIV-45 coexist with schema-40 retained boundaries",
        try AgentSimulationSession.restoring(coexistence.makeCheckpoint()).durableStateBytes() == coexistence.durableStateBytes())
    for field in ["boundary", "literacyRecords"] {
        writingRestoreRefuses("signed missing writing \(field)", checkpoint: compacted) { durable in
            var writing = durable["writingState"] as! [String: Any]
            if field == "boundary" { writing.removeValue(forKey: field) } else { writing[field] = [] }
            durable["writingState"] = writing
        }
    }
    for field in ["authorID", "artifactID", "sourceAuthorityID", "recipientAuthorityID"] {
        writingRestoreRefuses("signed substituted \(field)", checkpoint: compacted) { durable in
            var writing = durable["writingState"] as! [String: Any]
            let key = field == "recipientAuthorityID" ? "readings" : "artifacts"
            var rows = writing[key] as! [[String: Any]]
            if field == "authorID" || field == "artifactID" {
                var p = rows[0]["plan"] as! [String: Any]
                p[field] = field == "authorID" ? writingRemote.rawValue : "inscription-" + String(repeating: "0", count: 64)
                rows[0]["plan"] = p
            } else { rows[0][field] = "historical-belief-authority-" + String(repeating: "0", count: 64) }
            writing[key] = rows; durable["writingState"] = writing
        }
    }
    // Decode genuine pre-feature shapes: no new mandatory Core field or migration.
    let legacyBytes = Data(#"{"type":"sign","x":1,"y":64,"z":0,"lines":["old","sign","text",""],"glowing":true,"color":"red"}"#.utf8)
    let legacy = try JSONDecoder().decode(BlockEntityData.self, from: legacyBytes)
    check("legacy sign decodes without inscription identity", legacy.signInscription == nil
        && legacy.lines == ["old", "sign", "text", ""] && legacy.glowing == true && legacy.color == "red")
    let legacyRoundtrip = try JSONDecoder().decode(BlockEntityData.self, from: JSONEncoder().encode(legacy))
    check("legacy sign roundtrip preserves original fields", legacyRoundtrip.lines == legacy.lines
        && legacyRoundtrip.color == legacy.color && legacyRoundtrip.signInscription == nil)
    for type in ["container", "furnace", "hopper", "brewing", "spawner", "piston"] {
        let be = BlockEntityData(type: type, x: 1, y: 64, z: 0)
        be.items = [nil, nil]; be.cooldown = 3; be.burnTime = 4; be.mob = "pig"; be.progress = 0.25
        let data = try JSONEncoder().encode(be)
        let restored = try JSONDecoder().decode(BlockEntityData.self, from: data)
        check("non-sign block entity compatibility \(type)", restored.type == type && restored.items?.count == 2
            && restored.cooldown == 3 && restored.burnTime == 4 && restored.mob == "pig"
            && restored.progress == 0.25 && restored.signInscription == nil)
    }
    let world = World(dim: .overworld, seed: 45)
    world.setChunk(Chunk(cx: 0, cz: 0, minY: GEN_MIN_Y, height: WORLD_H))
    world.setBlock(1, 64, 0, Int(bid("oak_sign")) << 4, SET_SILENT)
    world.setBlockEntity(legacy)
    do { _ = try world.inspectSignInscription(at: 1, 64, 0); check("legacy arbitrary text confers no CIV-45 identity", false) }
    catch { check("legacy arbitrary text confers no CIV-45 identity", true) }
    let existing = try JSONDecoder().decode(BlockEntityData.self, from: beBytes)
    world.setBlockEntity(existing)
    world.setBlock(1, 64, 0, 0, SET_SILENT)
    world.setBlock(1, 64, 0, Int(bid("oak_sign")) << 4, SET_SILENT)
    let replacement = makeSignBE(1, 64, 0); replacement.lines = plan.lines
    world.setBlockEntity(replacement)
    do { _ = try world.inspectSignInscription(at: 1, 64, 0); check("destroy A replace B same position same text no identity", false) }
    catch { check("destroy A replace B same position same text no identity", replacement.signInscription == nil) }
    world.setBlockEntity(existing)
    var duplicateJSON = try JSONSerialization.jsonObject(with: beBytes) as! [String: Any]
    duplicateJSON["x"] = 2
    var duplicateStamp = duplicateJSON["signInscription"] as! [String: Any]
    duplicateStamp["x"] = 2
    duplicateJSON["signInscription"] = duplicateStamp
    let duplicate = try JSONDecoder().decode(BlockEntityData.self,
        from: JSONSerialization.data(withJSONObject: duplicateJSON))
    world.setBlock(2, 64, 0, Int(bid("oak_sign")) << 4, SET_SILENT)
    world.setBlockEntity(duplicate)
    do { _ = try world.inspectSignInscription(at: 2, 64, 0); check("persisted copied identity at different site rejected", false) }
    catch { check("persisted copied identity at different site rejected", true) }
    do { _ = try world.inspectSignInscription(at: 1, 64, 0); check("persisted original identity also fails closed while duplicated", false) }
    catch { check("persisted original identity also fails closed while duplicated", true) }
    world.setBlock(2, 64, 0, 0, SET_SILENT)
    var malformed = try JSONSerialization.jsonObject(with: beBytes) as! [String: Any]
    var stamp = malformed["signInscription"] as! [String: Any]; stamp["contentDigest"] = "invalid"; malformed["signInscription"] = stamp
    world.setBlockEntity(try JSONDecoder().decode(BlockEntityData.self, from: JSONSerialization.data(withJSONObject: malformed)))
    do { _ = try world.inspectSignInscription(at: 1, 64, 0); check("decodable malformed Core stamp fails closed on access", false) }
    catch { check("decodable malformed Core stamp fails closed on access", true) }
    try writingTerminalPressureProof()
}

private func writingOtherAuthorities(_ session: AgentSimulationSession) throws -> Data {
    var fields = try JSONSerialization.jsonObject(with: session.durableStateBytes()) as! [String: Any]
    for key in ["knowledgeGraphState", "languageState", "writingState", "causalLedger"] { fields.removeValue(forKey: key) }
    return try JSONSerialization.data(withJSONObject: fields, options: [.sortedKeys, .withoutEscapingSlashes])
}

private func writingTerminalPressureProof() throws {
    var (session, proposition) = try writingPrepared(knowledgeConfiguration: try AgentKnowledgeConfiguration(maximumBeliefs: 1),
        lethalID: writingAuthor, starvationDamage: 25, readerHealth: 26)
    try session.setSocialEnabled(false)
    try session.seedWritingEducationalPrior(for: writingAuthor)
    try session.seedWritingEducationalPrior(for: writingReader)
    let plan = try session.prepareWriting(authorID: writingAuthor, propositionID: proposition, materialID: peekNextEntityId(), dimension: "0", cell: writingCell)
    _ = try session.acceptWriting(plan, receipt: writingReceipt(plan, actorID: writingAuthor, tick: session.tick))
    try session.initializePopulationRegistry(settlementAnchor: writingCell, receptionPosition: writingCell)
    session.setSurvivalEnabled(true)
    try session.setMortalityEnabled(true)
    for _ in 0..<5 where session.snapshot().agents.contains(where: { $0.id == writingAuthor.rawValue }) {
        _ = try session.advanceTick(perceptions: [])
    }
    check("terminal pressure retains departed author belief", session.knowledgeSnapshot().departedBeliefs.count == 1)
    _ = try session.readWriting(artifactID: plan.artifactID, readerID: writingReader,
        receipt: writingReceipt(plan, actorID: writingReader, tick: session.tick))
    for _ in 0..<5 where session.snapshot().agents.contains(where: { $0.id == writingReader.rawValue }) {
        _ = try session.advanceTick(perceptions: [])
    }
    print("CIV45_TERMINAL survivors=\(session.snapshot().agents.map(\.id).joined(separator: ","))")
    for _ in 0..<40 {
        try session.setWritingEnabled(false, worldID: "civ45-world", configuration: session.writingState!.configuration)
        try session.setWritingEnabled(true, worldID: "civ45-world", configuration: session.writingState!.configuration)
    }
    let snapshot = session.knowledgeSnapshot()
    check("terminal compaction actually evicts historical beliefs", snapshot.departedBeliefEvictionCount > 0
        && snapshot.departedBeliefs.count == 1)
    check("written authority survives terminal and causal compaction", try AgentSimulationSession.restoring(session.makeCheckpoint())
        .durableStateBytes() == session.durableStateBytes() && session.writingState!.artifacts.count == 1
        && session.writingState!.readings.count == 1 && !session.canUseWritingNotation(writingReader))
}
