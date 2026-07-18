import Foundation
import PebbleAgents

private let kinshipHabitat = AgentEcologyHabitatObservation(
    worldTick: 0,
    candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 712,
    distanceFromSettlement: 1,
    directionIndex: 0,
    worldReadCount: 4
)

private func kinshipAgent(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)",
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "kinship fixture", startedAtTick: 0, urgency: 0
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

private let kinshipLifecycleConfiguration = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 1,
    maturityAgeTicks: 64,
    reproductionEvaluationIntervalTicks: 1,
    reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1,
    maximumRetainedBirthRecords: 32,
    maximumRetainedPlanRecords: 32,
    maximumParentBirthCount: 16
)

private func kinshipBase(
    _ simulationID: String,
    lifecycleConfiguration: AgentLifecycleConfiguration = kinshipLifecycleConfiguration,
    enableLifecycle: Bool = true,
    maximumCausalEvents: Int = 8192
) -> AgentSimulationSession {
    let lethalSurvival = try! AgentSurvivalConfiguration(
        hungerPerTick: 1,
        fatiguePerTick: 0.005,
        hungryThreshold: 0.4,
        criticalHungerThreshold: 0.8,
        hungerRecoveryThreshold: 0.15,
        fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2,
        foodNutrition: 1,
        restRecoveryPerTick: 1,
        starvationGraceTicks: 0,
        starvationDamagePerTick: 100
    )
    let configuration = try! AgentSessionConfiguration(
        seed: 47,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 64),
        survivalConfiguration: lethalSurvival
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [kinshipAgent(0), kinshipAgent(1), kinshipAgent(2)],
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: maximumCausalEvents)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.initializeLocalEcology(observations: [kinshipHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(habitatValidations: [kinshipHabitat])
    if enableLifecycle {
        try! session.setLifecycleEnabled(true, configuration: lifecycleConfiguration)
    }
    return session
}

private func kinshipAdvance(_ session: inout AgentSimulationSession, to tick: Int) {
    while session.tick < tick { _ = try! session.advanceTick() }
}

@discardableResult
private func kinshipBirth(
    _ session: inout AgentSimulationSession,
    position: AgentPosition
) -> AgentBirthRecord {
    while session.pendingBirthSitePlan() == nil { _ = try! session.advanceTick() }
    let plan = session.pendingBirthSitePlan()!
    if session.tick < plan.dueTick { kinshipAdvance(&session, to: plan.dueTick) }
    return try! session.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID,
        observedTick: session.tick,
        position: position,
        candidateIndex: 0,
        worldFingerprint: 12_000 + session.lifecycleSummary().totalBirthCount
    ))!
}

private func kinshipMigrationObservation(tick: Int) -> AgentMigrationWorldObservation {
    AgentMigrationWorldObservation(
        worldTick: tick,
        candidateIndex: 0,
        entryPosition: AgentPosition(x: 0, y: 64, z: 5),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        route: [
            AgentPosition(x: 0, y: 64, z: 5),
            AgentPosition(x: 0, y: 64, z: 4),
            AgentPosition(x: 0, y: 64, z: 3),
        ]
    )
}

private func kinshipMutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
    let mutatedJSON = try! JSONSerialization.data(
        withJSONObject: durable,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let mutatedState = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self,
        from: mutatedJSON
    )
    let durableBytes = try! AgentCheckpointCodec.encode(mutatedState)
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let canonicalDurable = try! JSONSerialization.jsonObject(
        with: durableBytes
    ) as! [String: Any]
    let clock = canonicalDurable["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let simulationDigest = AgentCheckpointDigest.sha256(Data(simulationID.utf8))
    root["durableState"] = canonicalDurable
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(tick)-\(digest.rawValue.prefix(16))"
    let bytes = try! JSONSerialization.data(
        withJSONObject: root,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    return try! AgentCheckpointCodec.decode(AgentSessionCheckpoint.self, from: bytes)
}

private func kinshipRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(
            kinshipMutatedCheckpoint(checkpoint, mutate: mutate)
        )
        return false
    } catch {
        return true
    }
}

private func kinshipCausalDigest(_ text: String) -> String {
    var value: UInt64 = 14_695_981_039_346_656_037
    for byte in text.utf8 {
        value ^= UInt64(byte)
        value &*= 1_099_511_628_211
    }
    let digits = String(value, radix: 16, uppercase: false)
    return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
}

private func kinshipEventIDText(_ value: [String: Any]) -> String {
    let simulationID = value["simulationID"] as! String
    let sequence = value["sequence"] as! UInt64
    let digits = String(sequence)
    return "\(simulationID)/event-\(String(repeating: "0", count: max(0, 20 - digits.count)))\(digits)"
}

private func kinshipPayloadText(_ payload: [String: Any]) -> String {
    if let birth = payload["birth"] as? [String: Any] {
        let position = birth["position"] as! [String: Any]
        return "birth|\(birth["birthID"] as! String)|\(birth["planID"] as! String)|"
            + "\(birth["newbornID"] as! String)|\(birth["ordinal"] as! Int)|"
            + "\((birth["progenitorIDs"] as! [String]).joined(separator: ","))|"
            + "\(position["x"] as! Int),\(position["y"] as! Int),\(position["z"] as! Int)|"
            + "\(birth["fingerprint"] as! Int)|\(birth["status"] as! String)"
    }
    let kinship = payload["kinship"] as! [String: Any]
    return "kinship|\(kinship["childID"] as? String ?? "none")|"
        + "\(kinship["birthID"] as? String ?? "none")|"
        + "\((kinship["parentIDs"] as! [String]).joined(separator: ","))|"
        + "\(kinship["personCount"] as! Int)|\(kinship["parentageCount"] as! Int)|"
        + "\(kinship["digest"] as! String)|\(kinship["status"] as! String)"
}

private func kinshipRepairEventDigest(_ event: inout [String: Any]) {
    let eventID = kinshipEventIDText(event["eventID"] as! [String: Any])
    let instant = event["instant"] as! [String: Any]
    let causes = (event["causes"] as! [[String: Any]]).map(kinshipEventIDText).joined(separator: ",")
    let text = "\(eventID)|\(instant["tick"] as! Int)|\(event["kind"] as! String)|"
        + "\(event["origin"] as! String)|\(event["actorID"] as? String ?? "-")|"
        + "\(event["subjectID"] as? String ?? "-")|\(event["operationID"] as? String ?? "-")|"
        + "\(causes)|\(kinshipPayloadText(event["payload"] as! [String: Any]))|"
        + "\(event["summary"] as! String)"
    event["digest"] = kinshipCausalDigest(text)
}

private func kinshipRecomputeCausalRollingDigest(_ durable: inout [String: Any]) {
    var ledger = durable["causalLedger"] as! [String: Any]
    let events = ledger["events"] as! [[String: Any]]
    var rolling = kinshipCausalDigest("")
    for event in events {
        rolling = kinshipCausalDigest("\(rolling)|\(event["digest"] as! String)")
    }
    ledger["rollingDigest"] = rolling
    durable["causalLedger"] = ledger
}

private func kinshipSemanticCausalMutation(
    _ checkpoint: AgentSessionCheckpoint,
    eventID: AgentCausalEventID,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    kinshipMutatedCheckpoint(checkpoint) { durable in
        var ledger = durable["causalLedger"] as! [String: Any]
        var events = ledger["events"] as! [[String: Any]]
        let index = events.firstIndex {
            let id = $0["eventID"] as! [String: Any]
            return id["simulationID"] as? String == eventID.simulationID.rawValue
                && id["sequence"] as? UInt64 == eventID.sequence.rawValue
        }!
        mutate(&events[index])
        kinshipRepairEventDigest(&events[index])
        ledger["events"] = events
        durable["causalLedger"] = ledger
        kinshipRecomputeCausalRollingDigest(&durable)
    }
}

private func kinshipSemanticCausalRemoval(
    _ checkpoint: AgentSessionCheckpoint,
    eventID: AgentCausalEventID
) -> AgentSessionCheckpoint {
    kinshipMutatedCheckpoint(checkpoint) { durable in
        var ledger = durable["causalLedger"] as! [String: Any]
        var events = ledger["events"] as! [[String: Any]]
        events.removeAll {
            let id = $0["eventID"] as! [String: Any]
            return id["simulationID"] as? String == eventID.simulationID.rawValue
                && id["sequence"] as? UInt64 == eventID.sequence.rawValue
        }
        ledger["events"] = events
        durable["causalLedger"] = ledger
        kinshipRecomputeCausalRollingDigest(&durable)
    }
}

private func kinshipCheckpointRefused(_ checkpoint: AgentSessionCheckpoint) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(checkpoint)
        return false
    } catch {
        return true
    }
}

func runPebbleAgentsDurableKinshipSmoke() {
    section("pebble agents durable kinship graph")

    let live = AgentKinshipConfiguration.live
    check("kinship live bounds", live.maximumHistoricalPersons == 512
        && live.maximumParentageRecords == 256
        && live.maximumChildrenPerParent == 16
        && live.maximumAncestryDepth == 32)
    check("kinship configuration Codable", (try? AgentCheckpointCodec.decode(
        AgentKinshipConfiguration.self,
        from: AgentCheckpointCodec.encode(live)
    )) == live)
    check("kinship rejects historical underflow", {
        do { _ = try AgentKinshipConfiguration(maximumHistoricalPersons: 2); return false }
        catch AgentKinshipError.invalidConfiguration("historical persons") { return true }
        catch { return false }
    }())
    check("kinship rejects parentage above persons", {
        do {
            _ = try AgentKinshipConfiguration(
                maximumHistoricalPersons: 3, maximumParentageRecords: 4
            )
            return false
        } catch AgentKinshipError.invalidConfiguration("parentage records") { return true }
        catch { return false }
    }())
    check("kinship rejects ancestry overflow", {
        do { _ = try AgentKinshipConfiguration(maximumAncestryDepth: 129); return false }
        catch AgentKinshipError.invalidConfiguration("ancestry depth") { return true }
        catch { return false }
    }())

    var noPopulation = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(seed: 47, memoryPolicy: .bounded(maxEntries: 8)),
        agents: [kinshipAgent(0), kinshipAgent(1), kinshipAgent(2)],
        simulationID: try! AgentSimulationID(validating: "sim-kinship-no-population"),
        causalLedgerPolicy: .bounded(maxEvents: 64)
    )
    let noPopulationBytes = try! noPopulation.durableStateBytes()
    check("kinship activation without population refused atomically", {
        do { try noPopulation.setKinshipEnabled(true); return false }
        catch AgentSessionError.kinship(.populationRequired) {
            return (try! noPopulation.durableStateBytes()) == noPopulationBytes
        } catch { return false }
    }())
    var noLifecycle = kinshipBase("sim-kinship-no-lifecycle", enableLifecycle: false)
    let noLifecycleBytes = try! noLifecycle.durableStateBytes()
    check("kinship activation without lifecycle refused atomically", {
        do { try noLifecycle.setKinshipEnabled(true); return false }
        catch AgentSessionError.kinship(.lifecycleRequired) {
            return (try! noLifecycle.durableStateBytes()) == noLifecycleBytes
        } catch { return false }
    }())

    var historicalActivation = kinshipBase("sim-kinship-historical-activation")
    try! historicalActivation.setReproductionEnabled(true)
    let historicalBirth = kinshipBirth(
        &historicalActivation,
        position: AgentPosition(x: 0, y: 64, z: 4)
    )
    try! historicalActivation.setReproductionEnabled(false)
    let historicalMigrant = try! historicalActivation.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: kinshipMigrationObservation(tick: historicalActivation.tick)
    )
    historicalActivation.setSurvivalEnabled(true)
    try! historicalActivation.setMortalityEnabled(true)
    _ = try! historicalActivation.advanceTick()
    let historicalV6 = try! historicalActivation.makeCheckpoint()
    try! historicalActivation.setKinshipEnabled(true)
    check("kinship v6 activation reconstructs dead allocations", historicalV6.schemaVersion == 6
        && historicalActivation.kinshipSnapshot().historicalPersons.map(\.agentID.rawValue)
            == ["agent_0", "agent_1", "agent_2", "agent_3", "agent_4"]
        && (try! historicalActivation.parents(of: historicalBirth.newbornID))
            == historicalBirth.progenitorIDs
        && (try! historicalActivation.parents(of: historicalMigrant.migrantID)) == nil)

    var session = kinshipBase("sim-kinship-durable")
    let v6Bytes = try! session.durableStateBytes()
    let v6Checkpoint = try! session.makeCheckpoint()
    check("kinship gate off remains schema v6", v6Checkpoint.schemaVersion == 6)
    check("kinship gate off omits durable state", !String(data: v6Bytes, encoding: .utf8)!
        .contains("kinshipState"))
    try! session.setKinshipEnabled(true)
    let initialized = session.kinshipSnapshot()
    check("kinship activation archives founders", initialized.historicalPersons.map(\.agentID.rawValue)
        == ["agent_0", "agent_1", "agent_2"])
    check("kinship founders are roots with unknown parentage", try! session.parents(
        of: AgentID(rawValue: "agent_0")!
    ) == nil)
    check("kinship activation emits one initialization", session.causalLedgerSnapshot().events.filter {
        $0.kind == .kinshipInitialized
    }.count == 1)
    let preBirthCheckpoint = try! session.makeCheckpoint()
    let preBirthBytes = try! session.durableStateBytes()
    let preBirthRestored = try! AgentSimulationSession.restoring(preBirthCheckpoint)
    check("kinship restart before birth exact", preBirthCheckpoint.schemaVersion == 7
        && (try! preBirthRestored.durableStateBytes()) == preBirthBytes)

    let draftChild = AgentID(rawValue: "agent_3")!
    let draftOrdinal = AgentPopulationOrdinal(rawValue: 3)!
    check("kinship parent order inversion accepted", {
        do {
            try session.validateKinshipParentageDraft(
                childID: draftChild,
                ordinal: draftOrdinal,
                parentIDs: [AgentID(rawValue: "agent_1")!, AgentID(rawValue: "agent_0")!]
            )
            return true
        } catch { return false }
    }())
    check("kinship duplicate parent refused", {
        do {
            try session.validateKinshipParentageDraft(
                childID: draftChild, ordinal: draftOrdinal,
                parentIDs: [AgentID(rawValue: "agent_0")!, AgentID(rawValue: "agent_0")!]
            )
            return false
        } catch AgentSessionError.kinship(.invalidParentage(draftChild)) { return true }
        catch { return false }
    }())
    check("kinship self parent refused", {
        do {
            try session.validateKinshipParentageDraft(
                childID: draftChild, ordinal: draftOrdinal,
                parentIDs: [draftChild, AgentID(rawValue: "agent_0")!]
            )
            return false
        } catch AgentSessionError.kinship(.invalidParentage(draftChild)) { return true }
        catch { return false }
    }())
    let unknown = AgentID(rawValue: "agent_99")!
    check("kinship unknown parent refused", {
        do {
            try session.validateKinshipParentageDraft(
                childID: draftChild, ordinal: draftOrdinal,
                parentIDs: [unknown, AgentID(rawValue: "agent_0")!]
            )
            return false
        } catch AgentSessionError.kinship(.unknownPerson(unknown)) { return true }
        catch { return false }
    }())
    check("kinship unknown child query explicit", {
        do { _ = try session.parents(of: unknown); return false }
        catch AgentSessionError.kinship(.unknownPerson(unknown)) { return true }
        catch { return false }
    }())
    check("kinship unknown sibling explicit", session.siblingRelation(
        between: AgentID(rawValue: "agent_0")!, and: unknown
    ) == .unknownPerson(unknown))
    check("kinship depth zero explicit", session.isAncestor(
        AgentID(rawValue: "agent_0")!, of: AgentID(rawValue: "agent_1")!, maximumDepth: 0
    ) == .depthLimitReached)

    try! session.setReproductionEnabled(true)
    let first = kinshipBirth(&session, position: AgentPosition(x: 0, y: 64, z: 4))
    let second = kinshipBirth(&session, position: AgentPosition(x: 1, y: 64, z: 4))
    let third = kinshipBirth(&session, position: AgentPosition(x: 2, y: 64, z: 4))
    let fourth = kinshipBirth(&session, position: AgentPosition(x: 3, y: 64, z: 4))
    check("kinship four births use true transaction", [first, second, third, fourth]
        .map(\.newbornID.rawValue) == ["agent_3", "agent_4", "agent_5", "agent_6"])
    check("kinship child to parents", try! session.parents(of: first.newbornID)
        == first.progenitorIDs)
    check("kinship parents canonical", first.progenitorIDs
        == first.progenitorIDs.sorted())
    check("kinship parent to children", try! session.children(
        of: AgentID(rawValue: "agent_0")!
    ) == [first.newbornID, second.newbornID, fourth.newbornID].sorted())
    check("kinship half siblings derived", session.siblingRelation(
        between: first.newbornID, and: second.newbornID
    ) == .halfSibling)
    check("kinship full siblings derived", session.siblingRelation(
        between: first.newbornID, and: fourth.newbornID
    ) == .fullSibling)
    check("kinship unknown founder parentage explicit", session.siblingRelation(
        between: first.newbornID, and: AgentID(rawValue: "agent_2")!
    ) == .unknownParentage(AgentID(rawValue: "agent_2")!))
    check("kinship same person explicit", session.siblingRelation(
        between: first.newbornID, and: first.newbornID
    ) == .samePerson)
    check("kinship unknown same person remains unknown", session.siblingRelation(
        between: unknown, and: unknown
    ) == .unknownPerson(unknown))
    check("kinship ancestor query", session.isAncestor(
        AgentID(rawValue: "agent_0")!, of: first.newbornID
    ) == .ancestor)
    check("kinship child is not ancestor of parent", session.isAncestor(
        first.newbornID, of: AgentID(rawValue: "agent_0")!
    ) == .notAncestor)
    check("kinship duplicate parentage identical refused", {
        do {
            try session.validateKinshipParentageDraft(
                childID: first.newbornID, ordinal: first.ordinal,
                parentIDs: first.progenitorIDs
            )
            return false
        } catch AgentSessionError.kinship(.duplicateParentage(first.newbornID)) { return true }
        catch { return false }
    }())
    check("kinship parentage rewrite refused", {
        do {
            try session.validateKinshipParentageDraft(
                childID: first.newbornID, ordinal: first.ordinal,
                parentIDs: [AgentID(rawValue: "agent_1")!, AgentID(rawValue: "agent_2")!]
            )
            return false
        } catch AgentSessionError.kinship(.parentageRewrite(first.newbornID)) { return true }
        catch { return false }
    }())
    let birthEvents = session.causalLedgerSnapshot().events.filter {
        $0.subjectID == first.newbornID && [
            AgentCausalEventKind.birthSiteValidated,
            .populationMemberBorn,
            .kinshipParentageRecorded,
            .birthFinalized,
        ].contains($0.kind)
    }
    check("kinship birth causal order exact", birthEvents.map(\.kind) == [
        .birthSiteValidated, .populationMemberBorn, .kinshipParentageRecorded, .birthFinalized,
    ] && birthEvents[2].actorID == nil
        && birthEvents[2].causes == [birthEvents[1].eventID]
        && birthEvents[3].causes == [birthEvents[2].eventID])

    try! session.setReproductionEnabled(false)
    let migration = try! session.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: kinshipMigrationObservation(tick: session.tick)
    )
    check("kinship migrant archived as root", migration.migrantID.rawValue == "agent_7"
        && session.historicalPerson(for: migration.migrantID) != nil
        && (try! session.parents(of: migration.migrantID)) == nil)
    let beforeDeath = session.kinshipSnapshot()
    let beforeDeathCheckpoint = try! session.makeCheckpoint()
    session.setSurvivalEnabled(true)
    try! session.setMortalityEnabled(true)
    _ = try! session.advanceTick()
    let afterDeath = session.kinshipSnapshot()
    let parentsAfterDeath = try! session.parents(of: first.newbornID)
    let childrenAfterDeath = try! session.children(of: first.progenitorIDs[0])
    check("kinship parent death preserves graph", session.mortalitySnapshot().records.contains {
        first.progenitorIDs.contains($0.agentID)
    } && parentsAfterDeath == first.progenitorIDs)
    check("kinship child death preserves graph", session.mortalitySnapshot().records.contains {
        $0.agentID == first.newbornID
    } && childrenAfterDeath.contains(first.newbornID))
    check("kinship mortality removes no history", beforeDeath.historicalPersons
        == afterDeath.historicalPersons && beforeDeath.parentageRecords == afterDeath.parentageRecords)
    let postDeathCheckpoint = try! session.makeCheckpoint()
    let postDeathBytes = try! session.durableStateBytes()
    let postDeathRestored = try! AgentSimulationSession.restoring(postDeathCheckpoint)
    check("kinship checkpoint v7", postDeathCheckpoint.schemaVersion == 7)
    check("kinship restart after death exact", try! postDeathRestored.durableStateBytes()
        == postDeathBytes && postDeathRestored.kinshipSnapshot() == afterDeath)

    var replaySession = kinshipBase("sim-kinship-replay")
    let replayBase = try! replaySession.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(checkpoint: replayBase, session: replaySession)
    _ = try! recorder.apply(
        .setKinshipEnabled(true, configuration: .live), to: &replaySession
    )
    _ = try! recorder.apply(.setReproductionEnabled(true), to: &replaySession)
    while replaySession.pendingBirthSitePlan() == nil {
        _ = try! recorder.apply(
            .advanceTick(perceptions: [], physicalObservations: []), to: &replaySession
        )
    }
    let replayPlan = replaySession.pendingBirthSitePlan()!
    while replaySession.tick < replayPlan.dueTick {
        _ = try! recorder.apply(
            .advanceTick(perceptions: [], physicalObservations: []), to: &replaySession
        )
    }
    _ = try! recorder.apply(.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: replayPlan.planID,
        observedTick: replaySession.tick,
        position: AgentPosition(x: 0, y: 64, z: 4),
        candidateIndex: 0,
        worldFingerprint: 12_000
    )), to: &replaySession)
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "kinship-replay")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: journal
    )
    check("kinship replay schema v7", journal.manifest.schemaVersion == 7)
    let replayDirectBytes = try! replaySession.durableStateBytes()
    let replayedBytes = try! replayed.session.durableStateBytes()
    check("kinship replay exact", replayed.report.verified
        && replayedBytes == replayDirectBytes
        && replayed.session.kinshipSnapshot() == replaySession.kinshipSnapshot())

    var historyEvicted = kinshipBase(
        "sim-kinship-evicted",
        lifecycleConfiguration: try! AgentLifecycleConfiguration(
            newbornDurationTicks: 1,
            maturityAgeTicks: 64,
            reproductionEvaluationIntervalTicks: 1,
            reproductionPlanDelayTicks: 1,
            reproductionCooldownTicks: 1,
            maximumRetainedBirthRecords: 1,
            maximumRetainedPlanRecords: 8
        )
    )
    try! historyEvicted.setReproductionEnabled(true)
    _ = kinshipBirth(&historyEvicted, position: AgentPosition(x: 0, y: 64, z: 4))
    _ = kinshipBirth(&historyEvicted, position: AgentPosition(x: 1, y: 64, z: 4))
    let historyEvictedBytes = try! historyEvicted.durableStateBytes()
    check("kinship v6 activation after birth eviction refused", {
        do { try historyEvicted.setKinshipEnabled(true); return false }
        catch AgentSessionError.kinship(.incompleteBirthHistory) {
            return (try! historyEvicted.durableStateBytes()) == historyEvictedBytes
        } catch { return false }
    }())

    var personBound = kinshipBase("sim-kinship-person-bound")
    try! personBound.setKinshipEnabled(true, configuration: try! AgentKinshipConfiguration(
        maximumHistoricalPersons: 3,
        maximumParentageRecords: 3,
        maximumChildrenPerParent: 2,
        maximumAncestryDepth: 8
    ))
    let personBoundBytes = try! personBound.durableStateBytes()
    let personBoundOrdinal = personBound.populationSummary().nextPopulationOrdinal
    let personBoundEvents = personBound.causalLedgerSnapshot().summary.latestSequence
    check("kinship migrant capacity fail closed", {
        do {
            _ = try personBound.admitMigration(
                intent: AgentMigrationAdmissionIntent(),
                observation: kinshipMigrationObservation(tick: personBound.tick)
            )
            return false
        } catch AgentSessionError.kinship(.historicalPersonCapacityReached) {
            return (try! personBound.durableStateBytes()) == personBoundBytes
                && personBound.populationSummary().nextPopulationOrdinal == personBoundOrdinal
                && personBound.causalLedgerSnapshot().summary.latestSequence == personBoundEvents
        } catch { return false }
    }())

    var parentageBound = kinshipBase("sim-kinship-parentage-bound")
    try! parentageBound.setKinshipEnabled(true, configuration: try! AgentKinshipConfiguration(
        maximumHistoricalPersons: 8,
        maximumParentageRecords: 1,
        maximumChildrenPerParent: 4,
        maximumAncestryDepth: 8
    ))
    try! parentageBound.setReproductionEnabled(true)
    _ = kinshipBirth(&parentageBound, position: AgentPosition(x: 0, y: 64, z: 4))
    while parentageBound.pendingBirthSitePlan() == nil { _ = try! parentageBound.advanceTick() }
    let boundedPlan = parentageBound.pendingBirthSitePlan()!
    kinshipAdvance(&parentageBound, to: boundedPlan.dueTick)
    let parentageBoundBytes = try! parentageBound.durableStateBytes()
    let parentageBoundOrdinal = parentageBound.populationSummary().nextPopulationOrdinal
    check("kinship parentage capacity birth atomic", {
        do {
            _ = try parentageBound.applyBirthSiteObservation(AgentBirthSiteObservation(
                planID: boundedPlan.planID,
                observedTick: parentageBound.tick,
                position: AgentPosition(x: 1, y: 64, z: 4),
                candidateIndex: 0,
                worldFingerprint: 12_001
            ))
            return false
        } catch AgentSessionError.kinship(.parentageCapacityReached) {
            return (try! parentageBound.durableStateBytes()) == parentageBoundBytes
                && parentageBound.populationSummary().nextPopulationOrdinal == parentageBoundOrdinal
        } catch { return false }
    }())

    var childBound = kinshipBase("sim-kinship-child-bound")
    try! childBound.setKinshipEnabled(true, configuration: try! AgentKinshipConfiguration(
        maximumHistoricalPersons: 8,
        maximumParentageRecords: 5,
        maximumChildrenPerParent: 1,
        maximumAncestryDepth: 8
    ))
    try! childBound.setReproductionEnabled(true)
    _ = kinshipBirth(&childBound, position: AgentPosition(x: 0, y: 64, z: 4))
    while childBound.pendingBirthSitePlan() == nil { _ = try! childBound.advanceTick() }
    let childBoundPlan = childBound.pendingBirthSitePlan()!
    kinshipAdvance(&childBound, to: childBoundPlan.dueTick)
    let childBoundBytes = try! childBound.durableStateBytes()
    check("kinship children per parent capacity atomic", {
        do {
            _ = try childBound.applyBirthSiteObservation(AgentBirthSiteObservation(
                planID: childBoundPlan.planID,
                observedTick: childBound.tick,
                position: AgentPosition(x: 1, y: 64, z: 4),
                candidateIndex: 0,
                worldFingerprint: 12_001
            ))
            return false
        } catch AgentSessionError.kinship(.childrenPerParentCapacityReached(
            AgentID(rawValue: "agent_0")!
        )) {
            return (try! childBound.durableStateBytes()) == childBoundBytes
        } catch { return false }
    }())

    check("kinship indirect cycle checkpoint refused", kinshipRestoreRefused(
        beforeDeathCheckpoint
    ) { durable in
        var kinship = durable["kinshipState"] as! [String: Any]
        var records = kinship["parentageRecords"] as! [[String: Any]]
        records[0]["canonicalParentIDs"] = ["agent_1", "agent_4"]
        records[1]["canonicalParentIDs"] = ["agent_2", "agent_3"]
        kinship["parentageRecords"] = records
        durable["kinshipState"] = kinship
    })
    check("kinship ancestry depth checkpoint refused", kinshipRestoreRefused(
        beforeDeathCheckpoint
    ) { durable in
        var kinship = durable["kinshipState"] as! [String: Any]
        var configuration = kinship["configuration"] as! [String: Any]
        configuration["maximumAncestryDepth"] = 1
        kinship["configuration"] = configuration
        var records = kinship["parentageRecords"] as! [[String: Any]]
        records[1]["canonicalParentIDs"] = ["agent_2", "agent_3"]
        kinship["parentageRecords"] = records
        durable["kinshipState"] = kinship
    })
    check("kinship lifecycle projection checkpoint refused", kinshipRestoreRefused(
        beforeDeathCheckpoint
    ) { durable in
        var lifecycle = durable["lifecycleState"] as! [String: Any]
        var members = lifecycle["members"] as! [[String: Any]]
        let index = members.firstIndex { $0["agentID"] as? String == "agent_3" }!
        members[index]["progenitorIDs"] = ["agent_1", "agent_2"]
        lifecycle["members"] = members
        durable["lifecycleState"] = lifecycle
    })
    check("kinship birth projection checkpoint refused", kinshipRestoreRefused(
        beforeDeathCheckpoint
    ) { durable in
        var lifecycle = durable["lifecycleState"] as! [String: Any]
        var births = lifecycle["births"] as! [[String: Any]]
        births[0]["progenitorIDs"] = ["agent_1", "agent_2"]
        lifecycle["births"] = births
        durable["lifecycleState"] = lifecycle
    })
    check("kinship foreign causal event checkpoint refused", kinshipRestoreRefused(
        beforeDeathCheckpoint
    ) { durable in
        var kinship = durable["kinshipState"] as! [String: Any]
        var records = kinship["parentageRecords"] as! [[String: Any]]
        var eventID = records[0]["recordedEventID"] as! [String: Any]
        eventID["simulationID"] = "foreign-simulation"
        records[0]["recordedEventID"] = eventID
        kinship["parentageRecords"] = records
        durable["kinshipState"] = kinship
    })

    let causalRecord = beforeDeath.parentageRecords[0]
    let causalEvents = session.causalLedgerSnapshot().events
    let sourceEvent = causalEvents.first {
        $0.eventID == causalRecord.sourcePopulationBornEventID
    }!
    let siteEventID = sourceEvent.causes[0]
    check("kinship missing recorded event in retained window refused", kinshipCheckpointRefused(
        kinshipSemanticCausalRemoval(
            beforeDeathCheckpoint, eventID: causalRecord.recordedEventID
        )
    ))
    check("kinship missing source event in retained window refused", kinshipCheckpointRefused(
        kinshipSemanticCausalRemoval(
            beforeDeathCheckpoint, eventID: causalRecord.sourcePopulationBornEventID
        )
    ))
    check("kinship retained source event wrong kind refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.sourcePopulationBornEventID
        ) { $0["kind"] = "birthSiteValidated" }
    ))
    check("kinship retained source event wrong simulation refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.sourcePopulationBornEventID
        ) { $0["simulationID"] = "foreign-simulation" }
    ))
    check("kinship retained source event wrong tick refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.sourcePopulationBornEventID
        ) { event in
            var instant = event["instant"] as! [String: Any]
            instant["tick"] = causalRecord.birthTick + 1
            event["instant"] = instant
            event["simulationTick"] = causalRecord.birthTick + 1
        }
    ))
    check("kinship retained source event wrong actor refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.sourcePopulationBornEventID
        ) { $0["actorID"] = causalRecord.canonicalParentIDs[1].rawValue }
    ))
    check("kinship retained source event wrong subject refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.sourcePopulationBornEventID
        ) { $0["subjectID"] = causalRecord.canonicalParentIDs[0].rawValue }
    ))
    check("kinship retained source event wrong cause refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.sourcePopulationBornEventID
        ) { event in
            event["causes"] = [[
                "simulationID": causalRecord.recordedEventID.simulationID.rawValue,
                "sequence": causalRecord.recordedEventID.sequence.rawValue,
            ]]
        }
    ))
    check("kinship retained source event wrong birth refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.sourcePopulationBornEventID
        ) { event in
            var payload = event["payload"] as! [String: Any]
            var birth = payload["birth"] as! [String: Any]
            birth["birthID"] = "birth-99999999"
            payload["birth"] = birth
            event["payload"] = payload
        }
    ))
    check("kinship retained source event wrong child refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.sourcePopulationBornEventID
        ) { event in
            var payload = event["payload"] as! [String: Any]
            var birth = payload["birth"] as! [String: Any]
            birth["newbornID"] = causalRecord.canonicalParentIDs[0].rawValue
            payload["birth"] = birth
            event["payload"] = payload
        }
    ))
    check("kinship retained source event wrong parents refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.sourcePopulationBornEventID
        ) { event in
            var payload = event["payload"] as! [String: Any]
            var birth = payload["birth"] as! [String: Any]
            birth["progenitorIDs"] = ["agent_1", "agent_2"]
            payload["birth"] = birth
            event["payload"] = payload
        }
    ))
    check("kinship retained source event wrong status refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.sourcePopulationBornEventID
        ) { event in
            var payload = event["payload"] as! [String: Any]
            var birth = payload["birth"] as! [String: Any]
            birth["status"] = "siteValidated"
            payload["birth"] = birth
            event["payload"] = payload
        }
    ))
    check("kinship retained recorded event wrong kind refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.recordedEventID
        ) { $0["kind"] = "kinshipPersonRegistered" }
    ))
    check("kinship retained recorded event wrong simulation refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.recordedEventID
        ) { $0["simulationID"] = "foreign-simulation" }
    ))
    check("kinship retained recorded event wrong tick refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.recordedEventID
        ) { event in
            var instant = event["instant"] as! [String: Any]
            instant["tick"] = causalRecord.birthTick + 1
            event["instant"] = instant
            event["simulationTick"] = causalRecord.birthTick + 1
        }
    ))
    check("kinship retained recorded event wrong actor refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.recordedEventID
        ) { $0["actorID"] = causalRecord.canonicalParentIDs[0].rawValue }
    ))
    check("kinship retained recorded event wrong subject refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.recordedEventID
        ) { $0["subjectID"] = causalRecord.canonicalParentIDs[0].rawValue }
    ))
    check("kinship retained recorded event wrong cause refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.recordedEventID
        ) { event in
            event["causes"] = [[
                "simulationID": siteEventID.simulationID.rawValue,
                "sequence": siteEventID.sequence.rawValue,
            ]]
        }
    ))
    check("kinship retained recorded event wrong birth refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.recordedEventID
        ) { event in
            var payload = event["payload"] as! [String: Any]
            var kinship = payload["kinship"] as! [String: Any]
            kinship["birthID"] = "birth-99999999"
            payload["kinship"] = kinship
            event["payload"] = payload
        }
    ))
    check("kinship retained recorded event wrong child refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.recordedEventID
        ) { event in
            var payload = event["payload"] as! [String: Any]
            var kinship = payload["kinship"] as! [String: Any]
            kinship["childID"] = causalRecord.canonicalParentIDs[0].rawValue
            payload["kinship"] = kinship
            event["payload"] = payload
        }
    ))
    check("kinship retained recorded event wrong parents refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.recordedEventID
        ) { event in
            var payload = event["payload"] as! [String: Any]
            var kinship = payload["kinship"] as! [String: Any]
            kinship["parentIDs"] = ["agent_1", "agent_2"]
            payload["kinship"] = kinship
            event["payload"] = payload
        }
    ))
    check("kinship retained recorded event wrong status refused", kinshipCheckpointRefused(
        kinshipSemanticCausalMutation(
            beforeDeathCheckpoint, eventID: causalRecord.recordedEventID
        ) { event in
            var payload = event["payload"] as! [String: Any]
            var kinship = payload["kinship"] as! [String: Any]
            kinship["status"] = "rootRegistered"
            payload["kinship"] = kinship
            event["payload"] = payload
        }
    ))
    check("kinship missing initialized event in retained window refused", kinshipCheckpointRefused(
        kinshipSemanticCausalRemoval(
            beforeDeathCheckpoint, eventID: beforeDeathCheckpoint.durableState.kinshipState!.initializedEventID
        )
    ))
    check("kinship missing last event in retained window refused", kinshipCheckpointRefused(
        kinshipSemanticCausalRemoval(
            beforeDeathCheckpoint, eventID: beforeDeathCheckpoint.durableState.kinshipState!.lastKinshipEventID
        )
    ))

    var retainedBoundary = kinshipBase(
        "sim-kinship-retained-boundary", maximumCausalEvents: 8
    )
    try! retainedBoundary.setKinshipEnabled(true)
    try! retainedBoundary.setReproductionEnabled(true)
    let retainedBirth = kinshipBirth(
        &retainedBoundary, position: AgentPosition(x: 0, y: 64, z: 4)
    )
    try! retainedBoundary.setReproductionEnabled(false)
    for _ in 0..<10 { _ = try! retainedBoundary.advanceTick() }
    let retainedSnapshot = retainedBoundary.causalLedgerSnapshot()
    let retainedCheckpoint = try! retainedBoundary.makeCheckpoint()
    let retainedRestored = try! AgentSimulationSession.restoring(retainedCheckpoint)
    check("kinship causal references before retained frontier restore", {
        let dropped = retainedSnapshot.summary.droppedEventCount
        return dropped > 0
            && retainedBirth.populationBornEventID.sequence.rawValue <= dropped
            && retainedBoundary.kinshipSnapshot().parentageRecords[0]
                .recordedEventID.sequence.rawValue <= dropped
            && (try! retainedRestored.durableStateBytes())
                == (try! retainedBoundary.durableStateBytes())
    }())

    let checkpointData = try! AgentCheckpointCodec.encode(postDeathCheckpoint)
    var corruptedText = String(data: checkpointData, encoding: .utf8)!
    if let range = corruptedText.range(of: "agent_0") {
        corruptedText.replaceSubrange(range, with: "agent_6")
    }
    let corruptedData = Data(corruptedText.utf8)
    check("kinship corrupted v7 checkpoint refused", {
        do {
            let corrupted = try AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self, from: corruptedData
            )
            _ = try AgentSimulationSession.restoring(corrupted)
            return false
        } catch { return true }
    }())
    let unknownVersionData = Data(String(data: checkpointData, encoding: .utf8)!
        .replacingOccurrences(of: "\"schemaVersion\":7", with: "\"schemaVersion\":99").utf8)
    check("kinship unknown checkpoint version refused", {
        do {
            let unknownVersion = try AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self, from: unknownVersionData
            )
            _ = try AgentSimulationSession.restoring(unknownVersion)
            return false
        } catch AgentCheckpointError.unsupportedSchema(99) { return true }
        catch { return false }
    }())
}
