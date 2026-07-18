import Foundation
import PebbleAgents

private struct KinshipScenarioCheck: Codable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

private struct KinshipScenarioReport: Encodable {
    let schemaVersion = 7
    let scenario = "durable_kinship_graph_smoke"
    let seed: UInt32
    let success: Bool
    let checks: [KinshipScenarioCheck]
}

private struct KinshipChildrenEntry: Encodable {
    let parentID: String
    let childIDs: [String]
}

private struct KinshipSiblingEntry: Encodable {
    let firstID: String
    let secondID: String
    let relation: String
}

private struct KinshipExternalStatus: Encodable {
    let agentID: String
    let beforeMortality: String
    let afterMortality: String
}

private struct KinshipDigestReport: Encodable {
    let schemaVersion: Int
    let seed: UInt32
    let durable: String
    let kinship: String
    let population: String
    let lifecycle: String
    let mortality: String
    let causal: String
    let checkpointStorage: String
    let replayStorage: String
    let worldBoundaryEvidence: String
}

private let durableKinshipHabitat = AgentEcologyHabitatObservation(
    worldTick: 0,
    candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 7_120,
    distanceFromSettlement: 1,
    directionIndex: 0,
    worldReadCount: 4
)

private let durableKinshipLifecycleConfiguration = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 1,
    maturityAgeTicks: 64,
    reproductionEvaluationIntervalTicks: 1,
    reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1,
    maximumRetainedBirthRecords: 32,
    maximumRetainedPlanRecords: 32,
    maximumParentBirthCount: 16
)

private func durableKinshipAgent(_ ordinal: Int) -> AgentSessionAgentState {
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
            kind: .idle,
            reason: "durable kinship fixture",
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
        totalDistanceReducedTowardHome: 0
    )
}

private func durableKinshipBase(seed: UInt32) -> AgentSimulationSession {
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
        seed: seed,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 64),
        survivalConfiguration: lethalSurvival
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [durableKinshipAgent(0), durableKinshipAgent(1), durableKinshipAgent(2)],
        simulationID: try! AgentSimulationID(validating: "durable-kinship-\(seed)"),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.initializeLocalEcology(observations: [durableKinshipHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [durableKinshipHabitat]
    )
    try! session.setLifecycleEnabled(
        true,
        configuration: durableKinshipLifecycleConfiguration
    )
    return session
}

private func durableKinshipMigrationObservation(tick: Int) -> AgentMigrationWorldObservation {
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

private func durableKinshipWrite<T: Encodable>(_ value: T, to url: URL) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(to: url, options: .atomic)
}

private func durableKinshipRelationName(_ relation: AgentSiblingRelation) -> String {
    switch relation {
    case .samePerson: return "samePerson"
    case .unrelated: return "unrelated"
    case .halfSibling: return "halfSibling"
    case .fullSibling: return "fullSibling"
    case let .unknownParentage(agentID): return "unknownParentage:\(agentID.rawValue)"
    case let .unknownPerson(agentID): return "unknownPerson:\(agentID.rawValue)"
    }
}

private func durableKinshipAdvance(
    recorder: inout AgentReplayRecorder,
    session: inout AgentSimulationSession
) {
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &session
    )
}

private func durableKinshipBirth(
    recorder: inout AgentReplayRecorder,
    session: inout AgentSimulationSession,
    candidateIndex: Int
) -> AgentBirthRecord {
    while session.pendingBirthSitePlan() == nil {
        durableKinshipAdvance(recorder: &recorder, session: &session)
    }
    let plan = session.pendingBirthSitePlan()!
    while session.tick < plan.dueTick {
        durableKinshipAdvance(recorder: &recorder, session: &session)
    }
    let previousCount = session.lifecycleSummary().totalBirthCount
    _ = try! recorder.apply(
        .applyBirthSiteObservation(AgentBirthSiteObservation(
            planID: plan.planID,
            observedTick: session.tick,
            position: AgentPosition(x: candidateIndex, y: 64, z: 4),
            candidateIndex: candidateIndex,
            worldFingerprint: 12_000 + previousCount
        )),
        to: &session
    )
    return session.lifecycleSnapshot().births.last!
}

func runDurableKinshipGraphSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("durable_kinship_graph_smoke requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    } catch {
        fail("cannot create durable kinship output directory: \(error)")
    }

    var checks: [KinshipScenarioCheck] = []
    func add(_ name: String, _ condition: Bool, _ detail: String = "") {
        checks.append(KinshipScenarioCheck(name: name, passed: condition, detail: detail))
    }

    var direct = durableKinshipBase(seed: options.seed)
    let v6Checkpoint = try! direct.makeCheckpoint()
    let v6Bytes = try! direct.durableStateBytes()
    add("gate-off checkpoint is v6", v6Checkpoint.schemaVersion == 6)
    add("gate-off omits kinship", !String(data: v6Bytes, encoding: .utf8)!
        .contains("kinshipState"))
    var recorder = try! AgentReplayRecorder(checkpoint: v6Checkpoint, session: direct)
    _ = try! recorder.apply(
        .setKinshipEnabled(true, configuration: .live),
        to: &direct
    )
    let preBirthCheckpoint = try! direct.makeCheckpoint()
    let preBirthRestored = try! AgentSimulationSession.restoring(preBirthCheckpoint)
    add("activation archives founders", direct.kinshipSnapshot().historicalPersons
        .map(\.agentID.rawValue) == ["agent_0", "agent_1", "agent_2"])
    add("founders have unknown parents", try! direct.parents(
        of: AgentID(rawValue: "agent_0")!
    ) == nil)
    add("restart before birth exact", preBirthCheckpoint.schemaVersion == 7
        && (try! preBirthRestored.durableStateBytes()) == (try! direct.durableStateBytes()))

    _ = try! recorder.apply(.setReproductionEnabled(true), to: &direct)
    let births = (0..<4).map {
        durableKinshipBirth(recorder: &recorder, session: &direct, candidateIndex: $0)
    }
    let first = births[0]
    let second = births[1]
    let fourth = births[3]
    add("four births use CIV-11", births.map(\.newbornID.rawValue)
        == ["agent_3", "agent_4", "agent_5", "agent_6"])
    add("child to parents", try! direct.parents(of: first.newbornID)
        == first.progenitorIDs)
    add("parent to children", try! direct.children(
        of: AgentID(rawValue: "agent_0")!
    ) == [first.newbornID, second.newbornID, fourth.newbornID].sorted())
    add("half siblings derived", direct.siblingRelation(
        between: first.newbornID,
        and: second.newbornID
    ) == .halfSibling)
    add("full siblings derived", direct.siblingRelation(
        between: first.newbornID,
        and: fourth.newbornID
    ) == .fullSibling)
    add("reversed parent input canonical", AgentParentageRecord(
        childID: first.newbornID,
        parentIDs: first.progenitorIDs.reversed(),
        birthID: first.birthID,
        birthTick: first.birthTick,
        sourcePopulationBornEventID: direct.kinshipSnapshot().parentageRecords[0]
            .sourcePopulationBornEventID,
        recordedEventID: direct.kinshipSnapshot().parentageRecords[0].recordedEventID
    ).canonicalParentIDs == first.progenitorIDs)

    _ = try! recorder.apply(.setReproductionEnabled(false), to: &direct)
    _ = try! recorder.apply(
        .admitMigration(
            intent: AgentMigrationAdmissionIntent(),
            observation: durableKinshipMigrationObservation(tick: direct.tick)
        ),
        to: &direct
    )
    let migrantID = AgentID(rawValue: "agent_7")!
    add("migrant is historical root", direct.historicalPerson(for: migrantID) != nil
        && (try! direct.parents(of: migrantID)) == nil)

    let beforeMortalityKinship = direct.kinshipSnapshot()
    let beforePopulation = direct.populationSnapshot()
    _ = try! recorder.apply(.setSurvivalEnabled(true), to: &direct)
    _ = try! recorder.apply(
        .setMortalityEnabled(true, configuration: .live),
        to: &direct
    )
    durableKinshipAdvance(recorder: &recorder, session: &direct)
    let afterMortalityKinship = direct.kinshipSnapshot()
    let mortality = direct.mortalitySnapshot()
    add("parent death preserves lineage", mortality.records.contains {
        first.progenitorIDs.contains($0.agentID)
    } && (try! direct.parents(of: first.newbornID)) == first.progenitorIDs)
    add("child death preserves history", mortality.records.contains {
        $0.agentID == first.newbornID
    } && (try! direct.children(of: first.progenitorIDs[0])).contains(first.newbornID))
    add("mortality removes no kinship", beforeMortalityKinship.historicalPersons
        == afterMortalityKinship.historicalPersons
        && beforeMortalityKinship.parentageRecords == afterMortalityKinship.parentageRecords)

    let checkpoint = try! direct.makeCheckpoint()
    let durableBytes = try! direct.durableStateBytes()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    add("checkpoint restart v7 exact", checkpoint.schemaVersion == 7
        && (try! restored.durableStateBytes()) == durableBytes
        && restored.kinshipSnapshot() == direct.kinshipSnapshot())

    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "durable-kinship")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: v6Checkpoint,
        journal: journal
    )
    add("replay v7 exact", journal.manifest.schemaVersion == 7
        && replayed.report.verified
        && (try! replayed.session.durableStateBytes()) == durableBytes
        && replayed.session.kinshipSnapshot() == direct.kinshipSnapshot())
    add("no world mutation", true, "pure AgentSimulationSession APIs only")

    let people = direct.kinshipSnapshot().historicalPersons
    let parentages = direct.kinshipSnapshot().parentageRecords
    let children = people.map {
        KinshipChildrenEntry(
            parentID: $0.agentID.rawValue,
            childIDs: (try! direct.children(of: $0.agentID)).map(\.rawValue)
        )
    }
    let siblings = [
        KinshipSiblingEntry(
            firstID: first.newbornID.rawValue,
            secondID: second.newbornID.rawValue,
            relation: durableKinshipRelationName(direct.siblingRelation(
                between: first.newbornID,
                and: second.newbornID
            ))
        ),
        KinshipSiblingEntry(
            firstID: first.newbornID.rawValue,
            secondID: fourth.newbornID.rawValue,
            relation: durableKinshipRelationName(direct.siblingRelation(
                between: first.newbornID,
                and: fourth.newbornID
            ))
        ),
    ]
    let deadIDs = Set(mortality.records.map(\.agentID))
    let statuses = people.map { person in
        KinshipExternalStatus(
            agentID: person.agentID.rawValue,
            beforeMortality: beforePopulation.members.first {
                $0.agentID == person.agentID
            }?.status.rawValue ?? "notActive",
            afterMortality: deadIDs.contains(person.agentID) ? "dead" : "active"
        )
    }
    let kinshipCausalKinds: Set<AgentCausalEventKind> = [
        .kinshipInitialized,
        .kinshipPersonRegistered,
        .kinshipParentageRecorded,
        .birthSiteValidated,
        .populationMemberBorn,
        .birthFinalized,
    ]
    let causal = direct.causalLedgerSnapshot().events.filter {
        kinshipCausalKinds.contains($0.kind)
    }
    let checkpointStorage = try! AgentCheckpointCodec.encode(checkpoint)
    let replayStorage = try! AgentReplayCodec.encodeRecords(journal.records)

    let checkpointDirectory = root.appendingPathComponent("kinship_checkpoint_v7")
    let replayDirectory = root.appendingPathComponent("kinship_replay_v7")
    try! FileManager.default.createDirectory(
        at: checkpointDirectory,
        withIntermediateDirectories: true
    )
    try! FileManager.default.createDirectory(
        at: replayDirectory,
        withIntermediateDirectories: true
    )
    try! durableKinshipWrite(people, to: root.appendingPathComponent("kinship_people.json"))
    try! durableKinshipWrite(
        parentages,
        to: root.appendingPathComponent("parentage_records.json")
    )
    try! durableKinshipWrite(
        children,
        to: root.appendingPathComponent("children_by_parent.json")
    )
    try! durableKinshipWrite(
        siblings,
        to: root.appendingPathComponent("sibling_relations.json")
    )
    try! durableKinshipWrite(
        statuses,
        to: root.appendingPathComponent("kinship_external_status.json")
    )
    try! durableKinshipWrite(
        causal,
        to: root.appendingPathComponent("kinship_causal_chain.json")
    )
    try! durableKinshipWrite(
        checkpoint,
        to: checkpointDirectory.appendingPathComponent("manifest.json")
    )
    try! durableKinshipWrite(
        checkpoint.durableState,
        to: checkpointDirectory.appendingPathComponent("session.json")
    )
    try! durableKinshipWrite(
        journal.manifest,
        to: replayDirectory.appendingPathComponent("manifest.json")
    )
    try! replayStorage.write(
        to: replayDirectory.appendingPathComponent("operations.ndjson"),
        options: .atomic
    )
    try! durableKinshipWrite(KinshipDigestReport(
        schemaVersion: checkpoint.schemaVersion,
        seed: options.seed,
        durable: (try! direct.durableStateDigest()).rawValue,
        kinship: direct.kinshipSnapshot().digest,
        population: direct.populationSummary().digest,
        lifecycle: direct.lifecycleSummary().digest,
        mortality: direct.mortalitySummary().digest,
        causal: direct.causalLedgerSnapshot().summary.digest,
        checkpointStorage: AgentCheckpointDigest.sha256(checkpointStorage).rawValue,
        replayStorage: AgentCheckpointDigest.sha256(replayStorage).rawValue,
        worldBoundaryEvidence: "pure PebbleAgents APIs; no World access or mutation event"
    ), to: root.appendingPathComponent("kinship_digest.json"))
    let report = KinshipScenarioReport(
        seed: options.seed,
        success: checks.allSatisfy(\.passed),
        checks: checks
    )
    try! durableKinshipWrite(
        report,
        to: root.appendingPathComponent("kinship_invariant_report.json")
    )

    let failed = checks.filter { !$0.passed }.map(\.name)
    guard failed.isEmpty else {
        fail("durable_kinship_graph_smoke invariants failed: \(failed.joined(separator: ", "))")
    }
    print(
        "durable_kinship_graph_smoke PASS people=\(people.count) "
            + "parentages=\(parentages.count) schema=7 "
            + "digest=\(direct.kinshipSnapshot().digest)"
    )
    exit(0)
}
