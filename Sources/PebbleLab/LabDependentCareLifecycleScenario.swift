import Foundation
import PebbleAgents

private struct CareScenarioCheck: Codable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

private struct CareScenarioReport: Encodable {
    let schemaVersion = 9
    let scenario = "dependent_care_lifecycle_smoke"
    let seed: UInt32
    let success: Bool
    let checks: [CareScenarioCheck]
}

private struct CareCapabilityRow: Encodable {
    let stage: String
    let allowed: [String]
    let denied: [String]
}

private struct CareConservationReport: Encodable {
    let providerID: String
    let consumerID: String
    let source: String
    let foodBefore: Int
    let foodAfter: Int
    let consumedByDependent: Int
    let equationBalanced: Bool
    let hungerBefore: Double
    let hungerAfter: Double
    let materialLedgerBalanced: Bool
}

private struct CareDigestReport: Encodable {
    let schemaVersion: Int
    let seed: UInt32
    let durable: String
    let care: String
    let household: String
    let kinship: String
    let lifecycle: String
    let causal: String
    let checkpointBytes: Int
    let checkpointSHA256: String
    let replayBytes: Int
    let replaySHA256: String
    let worldBoundaryEvidence: String
}

private let careScenarioHabitat = AgentEcologyHabitatObservation(
    worldTick: 0,
    candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 1_209,
    distanceFromSettlement: 1,
    directionIndex: 0,
    worldReadCount: 4
)

private let careScenarioLifecycle = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 8,
    maturityAgeTicks: 24,
    reproductionEvaluationIntervalTicks: 1,
    reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1,
    maximumRetainedBirthRecords: 32,
    maximumRetainedPlanRecords: 32,
    maximumParentBirthCount: 16
)

private func careScenarioAgent(_ ordinal: Int, home: AgentPosition) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: home,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100, fear: 0, homePosition: home, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "dependent care scenario", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func careScenarioBase(seed: UInt32) -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.05, fatiguePerTick: 0.005,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.95,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 0.6,
        restRecoveryPerTick: 1, starvationGraceTicks: 64,
        starvationDamagePerTick: 1
    )
    let homeA = AgentPosition(x: 0, y: 64, z: 0)
    let homeB = AgentPosition(x: 5, y: 64, z: 0)
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: seed, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: survival
        ),
        agents: [
            careScenarioAgent(0, home: homeA), careScenarioAgent(1, home: homeA),
            careScenarioAgent(2, home: homeB),
        ],
        simulationID: try! AgentSimulationID(validating: "scenario-care-\(seed)"),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: homeA,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.initializeLocalEcology(observations: [careScenarioHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [careScenarioHabitat]
    )
    try! session.setLifecycleEnabled(true, configuration: careScenarioLifecycle)
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.setReproductionEnabled(true)
    return session
}

private func careScenarioPerception(
    agentID: AgentID,
    position: AgentPosition,
    target: AgentPosition,
    worldTick: Int
) -> AgentPerceptionInput {
    let center = AgentWorldColumnObservation(
        position: position, chunkReady: true, surfaceY: position.y,
        height: position.y, blockBelow: 1, blockAtFeet: 0, blockAtHead: 0,
        groundPresent: true, feetClear: true, headClear: true
    )
    let neighbors = AgentCardinalDirection.allCases.map { direction in
        let neighbor = AgentPosition(
            x: position.x + direction.dx, y: position.y, z: position.z + direction.dz
        )
        return AgentWorldNeighborObservation(
            direction: direction,
            column: AgentWorldColumnObservation(
                position: neighbor, chunkReady: true, surfaceY: position.y,
                height: position.y, blockBelow: 1, blockAtFeet: 0, blockAtHead: 0,
                groundPresent: true, feetClear: true, headClear: true
            ),
            stepDelta: 0, traversable: true, dangerousDrop: false
        )
    }
    let world = try! AgentWorldObservation(
        worldTick: worldTick, position: position, center: center, neighbors: neighbors,
        biomeId: nil, biomeName: nil, combinedLight: nil, skyLight: nil,
        blockLight: nil, dayTime: worldTick, raining: false, thundering: false
    )
    var cells: [AgentNavigationCell] = []
    for x in (position.x - 8)...(position.x + 8) {
        for z in (position.z - 8)...(position.z + 8)
        where abs(x - position.x) + abs(z - position.z) <= 8 {
            cells.append(AgentNavigationCell(
                position: AgentPosition(x: x, y: position.y, z: z), status: .traversable
            ))
        }
    }
    return AgentPerceptionInput(
        agentId: agentID.rawValue, worldObservation: world,
        navigationObservation: AgentNavigationObservation(
            worldTick: worldTick, origin: position, target: target, radius: 8, cells: cells
        )
    )
}

@discardableResult
private func careScenarioAdvance(
    recorder: inout AgentReplayRecorder,
    session: inout AgentSimulationSession,
    perceptions: [AgentPerceptionInput] = []
) -> AgentSessionTickResult {
    try! recorder.apply(
        .advanceTick(perceptions: perceptions, physicalObservations: []), to: &session
    ).tickResult!
}

private func careScenarioBirth(
    recorder: inout AgentReplayRecorder,
    session: inout AgentSimulationSession
) -> AgentBirthRecord {
    while session.pendingBirthSitePlan() == nil {
        careScenarioAdvance(recorder: &recorder, session: &session)
    }
    let plan = session.pendingBirthSitePlan()!
    while session.tick < plan.dueTick {
        careScenarioAdvance(recorder: &recorder, session: &session)
    }
    _ = try! recorder.apply(.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID, observedTick: session.tick,
        position: AgentPosition(x: 0, y: 64, z: 2), candidateIndex: 0,
        worldFingerprint: 19_000
    )), to: &session)
    return session.lifecycleSnapshot().births.last!
}

private func careScenarioWrite<T: Encodable>(_ value: T, to url: URL) throws {
    try AgentCheckpointCodec.encode(value).write(to: url, options: .atomic)
}

func runDependentCareLifecycleSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("dependent_care_lifecycle_smoke requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    } catch {
        fail("cannot create dependent care output directory: \(error)")
    }
    var checks: [CareScenarioCheck] = []
    func add(_ name: String, _ passed: Bool, _ detail: String = "") {
        checks.append(CareScenarioCheck(name: name, passed: passed, detail: detail))
    }

    var direct = careScenarioBase(seed: options.seed)
    let v8Checkpoint = try! direct.makeCheckpoint()
    let v8Bytes = try! direct.durableStateBytes()
    add("gate-off schema v8", v8Checkpoint.schemaVersion == 8)
    add("gate-off omits care", !String(data: v8Bytes, encoding: .utf8)!
        .contains("dependentCareState"))
    var recorder = try! AgentReplayRecorder(checkpoint: v8Checkpoint, session: direct)
    _ = try! recorder.apply(.setDependentCareEnabled(
        true, configuration: try! AgentDependentCareConfiguration(
            nourishmentHungerThreshold: 0.05
        )
    ), to: &direct)
    add("activation promotes v9", try! direct.makeCheckpoint().schemaVersion == 9)

    let patch = direct.localEcologySnapshot().patches.first!
    _ = try! recorder.apply(.applyForageOutcomes(
        intents: [AgentForageIntent(
            forageID: "care-scenario-food", patchID: patch.patchID,
            agentID: AgentID(rawValue: "agent_0")!, tick: direct.tick,
            target: patch.foragePosition, observedAtTick: direct.tick,
            expectedHabitatFingerprint: patch.habitatFingerprint
        )],
        habitatValidations: [careScenarioHabitat]
    ), to: &direct)
    add("real food acquired", direct.snapshot().agents.first { $0.id == "agent_0" }?
        .resourceInventory.count(of: .foodRaw) == 1)

    let birth = careScenarioBirth(recorder: &recorder, session: &direct)
    let assignment = try! direct.currentCareAssignment(for: birth.newbornID)!
    add("newborn assigned to parent", birth.progenitorIDs.contains(assignment.caregiverID))
    add("newborn joins caregiver household", try! direct.currentMembership(
        of: birth.newbornID
    )?.householdID == assignment.householdID)
    let newbornBefore = try! direct.state(for: birth.newbornID)
    var caregiverMoved = false
    var careAction: AgentSessionTickResult?
    for _ in 0..<8 where careAction == nil {
        let caregiver = try! direct.state(for: assignment.caregiverID)
        let dependent = try! direct.state(for: birth.newbornID)
        let result = careScenarioAdvance(
            recorder: &recorder, session: &direct,
            perceptions: [careScenarioPerception(
                agentID: assignment.caregiverID, position: caregiver.position,
                target: dependent.position, worldTick: direct.tick + 1
            )]
        )
        if result.agents.first(where: {
            $0.agentId == assignment.caregiverID.rawValue
        })?.action.name == "provide_food" {
            careAction = result
        } else {
            let before = try! direct.state(for: assignment.caregiverID).position
            _ = try! recorder.apply(
                .movementOutcomes(AgentMovementCoordinator.resolve(snapshot: direct.snapshot())),
                to: &direct
            )
            caregiverMoved = caregiverMoved
                || (try! direct.state(for: assignment.caregiverID).position) != before
        }
    }
    let engagementProof = direct.dependentCareSnapshot().activeEngagements
    let duringEngagement = try! direct.makeCheckpoint()
    add("restart during engagement exact", (try! AgentSimulationSession.restoring(
        duringEngagement
    ).durableStateBytes()) == (try! direct.durableStateBytes()))
    let newbornAfterCareTick = try! direct.state(for: birth.newbornID)
    add("newborn passive", newbornAfterCareTick.goalSelectionCount
        == newbornBefore.goalSelectionCount
        && newbornAfterCareTick.actionCount == newbornBefore.actionCount
        && newbornAfterCareTick.movementCount == newbornBefore.movementCount)
    add("caregiver approaches physically", caregiverMoved)
    add("care overrides adult action", careAction?.agents.contains {
        $0.agentId == assignment.caregiverID.rawValue && $0.action.name == "provide_food"
    } == true)

    let foodEngagement = direct.dependentCareSnapshot().activeEngagements.first {
        $0.caregiverID == assignment.caregiverID && $0.kind == .provideFood
    }!
    let provisionIntent = AgentCareProvisionIntent(
        provisionID: "care-scenario-provision", needID: foodEngagement.needID,
        caregiverID: assignment.caregiverID, dependentID: birth.newbornID,
        tick: direct.tick
    )
    var provisionPreview = direct
    let provision = try! provisionPreview.provideDependentNourishment(provisionIntent)
    _ = try! recorder.apply(.provideDependentNourishment(provisionIntent), to: &direct)
    add("food conservation", provision.succeeded
        && provision.foodBefore == provision.foodAfter + provision.consumedByDependent
        && provision.consumedByDependent == 1 && direct.conservationSnapshot().balanced)
    add("hunger reduced once", provision.hungerAfter < provision.hungerBefore)

    _ = try! recorder.apply(.formHousehold(
        memberIDs: [birth.newbornID, AgentID(rawValue: "agent_2")!],
        residenceAnchor: AgentPosition(x: 5, y: 64, z: 0)
    ), to: &direct)
    let nonParent = try! direct.currentCareAssignment(for: birth.newbornID)!
    add("non-parent co-resident selected", nonParent.caregiverID
        == AgentID(rawValue: "agent_2")! && !birth.progenitorIDs.contains(nonParent.caregiverID))
    _ = try! recorder.apply(.formHousehold(
        memberIDs: [birth.newbornID],
        residenceAnchor: AgentPosition(x: 9, y: 64, z: 0)
    ), to: &direct)
    let parentElsewhere = try! direct.currentCareAssignment(for: birth.newbornID)!
    add("parent elsewhere moves dependent", birth.progenitorIDs.contains(
        parentElsewhere.caregiverID
    ) && (try! direct.currentMembership(of: birth.newbornID))?.householdID
        == parentElsewhere.householdID)

    while direct.lifecycleSnapshot().members.first(where: {
        $0.agentID == birth.newbornID
    })?.currentStage == .newborn {
        careScenarioAdvance(recorder: &recorder, session: &direct)
    }
    let juvenile = try! direct.stageCapabilityPolicy(for: birth.newbornID)
    add("juvenile capabilities bounded", juvenile.permits(.returnHome)
        && juvenile.permits(.selfConsumeCarriedFood) && !juvenile.permits(.harvest)
        && !juvenile.permits(.build) && !juvenile.permits(.reproduce))

    let checkpoint = try! direct.makeCheckpoint()
    let durableBytes = try! direct.durableStateBytes()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    add("restart after outcome exact", checkpoint.schemaVersion == 9
        && (try! restored.durableStateBytes()) == durableBytes)
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "dependent-care-lifecycle")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: v8Checkpoint, journal: journal
    )
    add("replay v9 exact", journal.manifest.schemaVersion == 9
        && replayed.report.verified
        && (try! replayed.session.durableStateBytes()) == durableBytes)
    add("World boundary", true,
        "PebbleAgents has no World import; no block or World mutation event is emitted")

    let snapshot = direct.dependentCareSnapshot()
    let careKinds: Set<AgentCausalEventKind> = [
        .dependentCareInitialized, .careAssignmentStarted, .careAssignmentEnded,
        .careNeedRaised, .careEngagementStarted, .consumption, .careProvided,
        .careNeedResolved, .careNeedUnmet,
    ]
    let causal = direct.causalLedgerSnapshot().events.filter {
        careKinds.contains($0.kind)
    }
    let checkpointStorage = try! AgentCheckpointCodec.encode(checkpoint)
    let replayStorage = try! AgentReplayCodec.encodeRecords(journal.records)
    let checkpointDirectory = root.appendingPathComponent("checkpoint_v9")
    let replayDirectory = root.appendingPathComponent("replay_v9")
    try! FileManager.default.createDirectory(
        at: checkpointDirectory, withIntermediateDirectories: true
    )
    try! FileManager.default.createDirectory(
        at: replayDirectory, withIntermediateDirectories: true
    )
    try! careScenarioWrite(snapshot.assignments,
        to: root.appendingPathComponent("care_assignments.json"))
    try! careScenarioWrite(snapshot.activeNeeds,
        to: root.appendingPathComponent("care_needs.json"))
    try! careScenarioWrite(engagementProof,
        to: root.appendingPathComponent("care_engagements.json"))
    try! careScenarioWrite(snapshot.terminalOutcomes,
        to: root.appendingPathComponent("care_outcomes.json"))
    let capabilities = AgentLifeStage.allCases.map { stage -> CareCapabilityRow in
        let policy = AgentStageCapabilityPolicy.policy(for: stage)
        return CareCapabilityRow(
            stage: stage.rawValue,
            allowed: policy.allowed.map(\.rawValue).sorted(),
            denied: AgentStageCapability.allCases.filter { !policy.permits($0) }
                .map(\.rawValue).sorted()
        )
    }
    try! careScenarioWrite(capabilities,
        to: root.appendingPathComponent("capability_matrix.json"))
    try! careScenarioWrite(CareConservationReport(
        providerID: provision.caregiverID.rawValue,
        consumerID: provision.dependentID.rawValue,
        source: provision.foodSource.rawValue,
        foodBefore: provision.foodBefore, foodAfter: provision.foodAfter,
        consumedByDependent: provision.consumedByDependent,
        equationBalanced: provision.foodBefore
            == provision.foodAfter + provision.consumedByDependent,
        hungerBefore: provision.hungerBefore, hungerAfter: provision.hungerAfter,
        materialLedgerBalanced: direct.conservationSnapshot().balanced
    ), to: root.appendingPathComponent("care_resource_conservation.json"))
    try! careScenarioWrite(causal,
        to: root.appendingPathComponent("care_causal_chain.json"))
    try! careScenarioWrite(checkpoint,
        to: checkpointDirectory.appendingPathComponent("manifest.json"))
    try! careScenarioWrite(checkpoint.durableState,
        to: checkpointDirectory.appendingPathComponent("session.json"))
    try! careScenarioWrite(journal.manifest,
        to: replayDirectory.appendingPathComponent("manifest.json"))
    try! replayStorage.write(
        to: replayDirectory.appendingPathComponent("operations.ndjson"), options: .atomic
    )
    try! careScenarioWrite(CareDigestReport(
        schemaVersion: checkpoint.schemaVersion, seed: options.seed,
        durable: (try! direct.durableStateDigest()).rawValue,
        care: snapshot.digest, household: direct.householdSnapshot().digest,
        kinship: direct.kinshipSnapshot().digest,
        lifecycle: direct.lifecycleSummary().digest,
        causal: direct.causalLedgerSnapshot().summary.digest,
        checkpointBytes: checkpointStorage.count,
        checkpointSHA256: AgentCheckpointDigest.sha256(checkpointStorage).rawValue,
        replayBytes: replayStorage.count,
        replaySHA256: AgentCheckpointDigest.sha256(replayStorage).rawValue,
        worldBoundaryEvidence: "PebbleAgents has no World import; no block or World mutation event is emitted"
    ), to: root.appendingPathComponent("care_digest.json"))
    let report = CareScenarioReport(
        seed: options.seed, success: checks.allSatisfy(\.passed), checks: checks
    )
    try! careScenarioWrite(
        report, to: root.appendingPathComponent("care_invariant_report.json")
    )
    let failed = checks.filter { !$0.passed }.map(\.name)
    guard failed.isEmpty else {
        fail("dependent_care_lifecycle_smoke failed: \(failed.joined(separator: ", "))")
    }
    print(
        "dependent_care_lifecycle_smoke PASS assignments=\(snapshot.assignments.count) "
            + "outcomes=\(snapshot.terminalOutcomes.count) schema=9 digest=\(snapshot.digest)"
    )
    exit(0)
}
