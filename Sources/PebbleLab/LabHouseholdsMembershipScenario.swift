import Foundation
import PebbleAgents

private struct HouseholdScenarioCheck: Codable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

private struct HouseholdScenarioReport: Encodable {
    let schemaVersion = 8
    let scenario = "households_and_membership_smoke"
    let seed: UInt32
    let success: Bool
    let checks: [HouseholdScenarioCheck]
}

private struct HouseholdDigestReport: Encodable {
    let schemaVersion: Int
    let seed: UInt32
    let durable: String
    let households: String
    let kinship: String
    let population: String
    let lifecycle: String
    let mortality: String
    let causal: String
    let checkpointBytes: Int
    let checkpointSHA256: String
    let replayBytes: Int
    let replaySHA256: String
    let worldBoundaryEvidence: String
}

private struct HouseholdExternalProjection: Encodable {
    let agentID: String
    let activeStatus: String
    let home: AgentPosition?
    let currentHouseholdID: String?
}

private let householdScenarioHabitat = AgentEcologyHabitatObservation(
    worldTick: 0,
    candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 912,
    distanceFromSettlement: 1,
    directionIndex: 0,
    worldReadCount: 4
)

private let householdScenarioLifecycle = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 1,
    maturityAgeTicks: 64,
    reproductionEvaluationIntervalTicks: 1,
    reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1,
    maximumRetainedBirthRecords: 32,
    maximumRetainedPlanRecords: 32,
    maximumParentBirthCount: 16
)

private func householdScenarioAgent(
    _ ordinal: Int,
    home: AgentPosition
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: "agent_\(ordinal)",
        state: "idle",
        position: home,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100,
        fear: 0,
        homePosition: home,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "household scenario", startedAtTick: 0, urgency: 0
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

private func householdScenarioBase(seed: UInt32) -> AgentSimulationSession {
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
    let homeA = AgentPosition(x: 0, y: 64, z: 0)
    let homeB = AgentPosition(x: 4, y: 64, z: 0)
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: seed,
            nearbyRadius: 8,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: lethalSurvival
        ),
        agents: [
            householdScenarioAgent(0, home: homeA),
            householdScenarioAgent(1, home: homeA),
            householdScenarioAgent(2, home: homeB),
        ],
        simulationID: try! AgentSimulationID(
            validating: "scenario-households-\(seed)"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: homeA,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.initializeLocalEcology(observations: [householdScenarioHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [householdScenarioHabitat]
    )
    try! session.setLifecycleEnabled(true, configuration: householdScenarioLifecycle)
    try! session.setKinshipEnabled(true)
    return session
}

private func householdScenarioAdvance(
    recorder: inout AgentReplayRecorder,
    session: inout AgentSimulationSession
) {
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []), to: &session
    )
}

private func householdScenarioBirth(
    recorder: inout AgentReplayRecorder,
    session: inout AgentSimulationSession,
    position: AgentPosition,
    candidateIndex: Int
) -> AgentBirthRecord {
    while session.pendingBirthSitePlan() == nil {
        householdScenarioAdvance(recorder: &recorder, session: &session)
    }
    let plan = session.pendingBirthSitePlan()!
    while session.tick < plan.dueTick {
        householdScenarioAdvance(recorder: &recorder, session: &session)
    }
    _ = try! recorder.apply(.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID,
        observedTick: session.tick,
        position: position,
        candidateIndex: candidateIndex,
        worldFingerprint: 15_000 + candidateIndex
    )), to: &session)
    return session.lifecycleSnapshot().births.last!
}

private func householdScenarioMigration(tick: Int) -> AgentMigrationWorldObservation {
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

private func householdScenarioWrite<T: Encodable>(_ value: T, to url: URL) throws {
    try AgentCheckpointCodec.encode(value).write(to: url, options: .atomic)
}

func runHouseholdsAndMembershipSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("households_and_membership_smoke requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    } catch {
        fail("cannot create household output directory: \(error)")
    }

    var checks: [HouseholdScenarioCheck] = []
    func add(_ name: String, _ passed: Bool, _ detail: String = "") {
        checks.append(HouseholdScenarioCheck(name: name, passed: passed, detail: detail))
    }

    var direct = householdScenarioBase(seed: options.seed)
    let v7Checkpoint = try! direct.makeCheckpoint()
    let v7Bytes = try! direct.durableStateBytes()
    add("gate-off schema v7", v7Checkpoint.schemaVersion == 7)
    add("gate-off omits household", !String(data: v7Bytes, encoding: .utf8)!
        .contains("householdState"))
    var recorder = try! AgentReplayRecorder(checkpoint: v7Checkpoint, session: direct)
    _ = try! recorder.apply(
        .setHouseholdsEnabled(true, configuration: .live), to: &direct
    )
    let activationSnapshot = direct.householdSnapshot()
    add("activation groups shared homes", activationSnapshot.households.count == 2
        && activationSnapshot.currentMemberships.count == 3)
    let preTransitionCheckpoint = try! direct.makeCheckpoint()
    add("restart before transition exact", (try! AgentSimulationSession.restoring(
        preTransitionCheckpoint
    ).durableStateBytes()) == (try! direct.durableStateBytes()))

    let formedAnchor = AgentPosition(x: 8, y: 64, z: 0)
    _ = try! recorder.apply(.formHousehold(
        memberIDs: [AgentID(rawValue: "agent_2")!, AgentID(rawValue: "agent_1")!],
        residenceAnchor: formedAnchor
    ), to: &direct)
    let formedID = AgentHouseholdID(rawValue: "household_2")!
    add("formation", try! direct.members(of: formedID)
        == [AgentID(rawValue: "agent_1")!, AgentID(rawValue: "agent_2")!])
    add("formation updates home", (try! direct.state(for: AgentID(rawValue: "agent_1")!))
        .homePosition == formedAnchor)
    add("empty household dissolves", direct.householdSnapshot().households.first {
        $0.householdID == AgentHouseholdID(rawValue: "household_1")!
    }?.status == .dissolved)
    add("unrelated cohabit", direct.siblingRelation(
        between: AgentID(rawValue: "agent_1")!, and: AgentID(rawValue: "agent_2")!
    ) == .unknownParentage(AgentID(rawValue: "agent_1")!))

    _ = try! recorder.apply(.moveHouseholdMembers(
        memberIDs: [AgentID(rawValue: "agent_1")!],
        householdID: AgentHouseholdID(rawValue: "household_0")!
    ), to: &direct)
    add("member move", try! direct.currentMembership(
        of: AgentID(rawValue: "agent_1")!
    )?.householdID == AgentHouseholdID(rawValue: "household_0")!)
    add("membership history", try! direct.membershipHistory(
        of: AgentID(rawValue: "agent_1")!
    ).count == 3)

    _ = try! recorder.apply(.setReproductionEnabled(true), to: &direct)
    let sharedBirth = householdScenarioBirth(
        recorder: &recorder, session: &direct,
        position: AgentPosition(x: 2, y: 64, z: 4), candidateIndex: 0
    )
    add("shared-parent birth joins household", try! direct.currentMembership(
        of: sharedBirth.newbornID
    )?.householdID == AgentHouseholdID(rawValue: "household_0")!)
    add("shared-parent newborn home", (try! direct.state(for: sharedBirth.newbornID))
        .homePosition == AgentPosition(x: 0, y: 64, z: 0))
    _ = try! recorder.apply(.moveHouseholdMembers(
        memberIDs: [sharedBirth.progenitorIDs[1]], householdID: formedID
    ), to: &direct)
    let splitBirth = householdScenarioBirth(
        recorder: &recorder, session: &direct,
        position: AgentPosition(x: 3, y: 64, z: 4), candidateIndex: 1
    )
    let splitMembership = try! direct.currentMembership(of: splitBirth.newbornID)!
    add("split-parent birth singleton", (try! direct.members(
        of: splitMembership.householdID
    )) == [splitBirth.newbornID])
    add("split-parent home birth position", splitMembership.residenceAnchor
        == splitBirth.position)

    _ = try! recorder.apply(.setReproductionEnabled(false), to: &direct)
    _ = try! recorder.apply(.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: householdScenarioMigration(tick: direct.tick)
    ), to: &direct)
    let migrantID = AgentID(rawValue: "agent_5")!
    let migrantMembership = try! direct.currentMembership(of: migrantID)!
    add("migrant singleton", try! direct.members(of: migrantMembership.householdID)
        == [migrantID])
    add("migrant root", try! direct.parents(of: migrantID) == nil)

    let beforeDeathKinship = direct.kinshipSnapshot()
    _ = try! recorder.apply(.setSurvivalEnabled(true), to: &direct)
    _ = try! recorder.apply(
        .setMortalityEnabled(true, configuration: .live), to: &direct
    )
    householdScenarioAdvance(recorder: &recorder, session: &direct)
    add("death closes memberships", direct.householdSnapshot().currentMemberships.isEmpty)
    add("death dissolves empty households", direct.householdSnapshot().households
        .allSatisfy { $0.status == .dissolved })
    add("death preserves household history", direct.householdSnapshot().membershipPeriods.count
        == direct.householdSnapshot().totalMembershipPeriodCount)
    add("death preserves kinship", direct.kinshipSnapshot().historicalPersons
        == beforeDeathKinship.historicalPersons
        && direct.kinshipSnapshot().parentageRecords == beforeDeathKinship.parentageRecords)

    let checkpoint = try! direct.makeCheckpoint()
    let durableBytes = try! direct.durableStateBytes()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    add("checkpoint restart v8 exact", checkpoint.schemaVersion == 8
        && (try! restored.durableStateBytes()) == durableBytes
        && restored.householdSnapshot() == direct.householdSnapshot())
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "household-membership")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: v7Checkpoint, journal: journal
    )
    add("replay v8 exact", journal.manifest.schemaVersion == 8
        && replayed.report.verified
        && (try! replayed.session.durableStateBytes()) == durableBytes
        && replayed.session.householdSnapshot() == direct.householdSnapshot())
    add("IDs monotone and never reused", direct.householdSnapshot().households
        .map(\.householdID.rawValue) == (0..<direct.householdSnapshot().households.count)
            .map { "household_\($0)" })
    add("World boundary", true,
        "pure PebbleAgents APIs; no World access or mutation event")

    let snapshot = direct.householdSnapshot()
    let householdKinds: Set<AgentCausalEventKind> = [
        .householdsInitialized, .householdCreated, .householdMembershipStarted,
        .householdMembershipEnded, .householdDissolved,
        .birthSiteValidated, .populationMemberBorn, .kinshipParentageRecorded,
        .birthFinalized, .populationMemberExited, .agentDeathFinalized,
    ]
    let causal = direct.causalLedgerSnapshot().events.filter {
        householdKinds.contains($0.kind)
    }
    let activeIDs = Set(direct.populationSnapshot().members.map(\.agentID))
    let projections = snapshot.membershipPeriods.map(\.agentID).reduce(into: Set<AgentID>()) {
        $0.insert($1)
    }.sorted().map { agentID in
        HouseholdExternalProjection(
            agentID: agentID.rawValue,
            activeStatus: activeIDs.contains(agentID) ? "active" : "dead",
            home: (try? direct.state(for: agentID).homePosition),
            currentHouseholdID: ((try? direct.currentMembership(of: agentID)) ?? nil)?
                .householdID.rawValue
        )
    }
    let checkpointStorage = try! AgentCheckpointCodec.encode(checkpoint)
    let replayStorage = try! AgentReplayCodec.encodeRecords(journal.records)
    let checkpointDirectory = root.appendingPathComponent("household_checkpoint_v8")
    let replayDirectory = root.appendingPathComponent("household_replay_v8")
    try! FileManager.default.createDirectory(
        at: checkpointDirectory, withIntermediateDirectories: true
    )
    try! FileManager.default.createDirectory(
        at: replayDirectory, withIntermediateDirectories: true
    )
    try! householdScenarioWrite(snapshot.households,
        to: root.appendingPathComponent("households.json"))
    try! householdScenarioWrite(snapshot.membershipPeriods,
        to: root.appendingPathComponent("membership_periods.json"))
    try! householdScenarioWrite(snapshot.currentMemberships,
        to: root.appendingPathComponent("current_memberships.json"))
    try! householdScenarioWrite(projections,
        to: root.appendingPathComponent("household_external_projections.json"))
    try! householdScenarioWrite(causal,
        to: root.appendingPathComponent("household_transitions.json"))
    try! householdScenarioWrite(causal,
        to: root.appendingPathComponent("household_causal_chain.json"))
    try! householdScenarioWrite(checkpoint,
        to: checkpointDirectory.appendingPathComponent("manifest.json"))
    try! householdScenarioWrite(checkpoint.durableState,
        to: checkpointDirectory.appendingPathComponent("session.json"))
    try! householdScenarioWrite(journal.manifest,
        to: replayDirectory.appendingPathComponent("manifest.json"))
    try! replayStorage.write(
        to: replayDirectory.appendingPathComponent("operations.ndjson"), options: .atomic
    )
    try! householdScenarioWrite(HouseholdDigestReport(
        schemaVersion: checkpoint.schemaVersion,
        seed: options.seed,
        durable: (try! direct.durableStateDigest()).rawValue,
        households: snapshot.digest,
        kinship: direct.kinshipSnapshot().digest,
        population: direct.populationSummary().digest,
        lifecycle: direct.lifecycleSummary().digest,
        mortality: direct.mortalitySummary().digest,
        causal: direct.causalLedgerSnapshot().summary.digest,
        checkpointBytes: checkpointStorage.count,
        checkpointSHA256: AgentCheckpointDigest.sha256(checkpointStorage).rawValue,
        replayBytes: replayStorage.count,
        replaySHA256: AgentCheckpointDigest.sha256(replayStorage).rawValue,
        worldBoundaryEvidence: "pure PebbleAgents APIs; no World access or mutation event"
    ), to: root.appendingPathComponent("household_digest.json"))
    let report = HouseholdScenarioReport(
        seed: options.seed,
        success: checks.allSatisfy(\.passed),
        checks: checks
    )
    try! householdScenarioWrite(
        report, to: root.appendingPathComponent("household_invariant_report.json")
    )
    let failed = checks.filter { !$0.passed }.map(\.name)
    guard failed.isEmpty else {
        fail("households_and_membership_smoke failed: \(failed.joined(separator: ", "))")
    }
    print(
        "households_and_membership_smoke PASS households=\(snapshot.households.count) "
            + "periods=\(snapshot.membershipPeriods.count) schema=8 digest=\(snapshot.digest)"
    )
    exit(0)
}
