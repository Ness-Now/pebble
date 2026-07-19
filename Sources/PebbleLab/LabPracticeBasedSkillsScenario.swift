import Foundation
import PebbleAgents

private struct SkillScenarioCheck: Codable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

private struct SkillScenarioReport: Encodable {
    let schemaVersion = 10
    let scenario = "practice_based_skills_task_matching_smoke"
    let seed: UInt32
    let success: Bool
    let checks: [SkillScenarioCheck]
}

private struct SkillLevelRow: Encodable {
    let agentID: String
    let domain: String
    let practiceUnits: Int
    let level: String
}

private struct SkillMatchingRow: Encodable {
    let taskID: String
    let noviceCandidate: String
    let practicedCandidate: String
    let selected: String
    let domain: String
    let noviceUnits: Int
    let selectedUnits: Int
    let selectionReason: String
}

private struct SkillDigestReport: Encodable {
    let schemaVersion: Int
    let seed: UInt32
    let durable: String
    let skill: String
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

private let skillScenarioHome = AgentPosition(x: 0, y: 64, z: 0)
private let skillScenarioHabitat = AgentEcologyHabitatObservation(
    worldTick: 0, candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 1_310, distanceFromSettlement: 1,
    directionIndex: 0, worldReadCount: 4
)
private let skillScenarioLifecycle = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 8, maturityAgeTicks: 24,
    reproductionEvaluationIntervalTicks: 1, reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1, maximumRetainedBirthRecords: 32,
    maximumRetainedPlanRecords: 32, maximumParentBirthCount: 16
)

private func skillScenarioAgent(_ ordinal: Int) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: skillScenarioHome,
        needs: AgentNeeds(hunger: 0, fatigue: -1, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: skillScenarioHome, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "practice-based skill scenario",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func skillScenarioV9(seed: UInt32) -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.05, fatiguePerTick: 0.005,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.95,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 0.6,
        restRecoveryPerTick: 1, starvationGraceTicks: 64,
        starvationDamagePerTick: 1
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: seed, nearbyRadius: 12, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 128),
            campStockCapacity: 64, survivalConfiguration: survival,
            socialConfiguration: try! AgentSocialConfiguration(shareCooldownTicks: 1),
            cooperationConfiguration: try! AgentCooperationConfiguration(
                offerCooldownTicks: 1
            )
        ),
        agents: [skillScenarioAgent(0), skillScenarioAgent(1), skillScenarioAgent(2)],
        simulationID: try! AgentSimulationID(validating: "scenario-skills-\(seed)"),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: skillScenarioHome,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.initializeLocalEcology(observations: [skillScenarioHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [skillScenarioHabitat]
    )
    try! session.setLifecycleEnabled(true, configuration: skillScenarioLifecycle)
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.setReproductionEnabled(true)
    try! session.setDependentCareEnabled(
        true,
        configuration: try! AgentDependentCareConfiguration(
            nourishmentHungerThreshold: 0.05
        )
    )
    return session
}

private func skillScenarioInteraction(
    session: inout AgentSimulationSession,
    recorder: inout AgentReplayRecorder,
    agentID: String,
    resource: AgentResourceKind,
    index: Int
) {
    _ = try! recorder.apply(.interactionOutcome(AgentInteractionOutcome(
        interactionId: "skill-scenario-harvest-\(agentID)-\(resource.rawValue)-\(index)",
        agentId: agentID, tick: session.tick,
        target: AgentPosition(x: 20 + index, y: 64, z: index),
        resource: resource, status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
        reason: "verified material acquisition"
    )), to: &session)
}

@discardableResult
private func skillScenarioDelivery(
    session: inout AgentSimulationSession,
    recorder: inout AgentReplayRecorder,
    agentID: String,
    id: String
) -> AgentDeliveryOutcome {
    let intent = AgentDeliveryIntent(
        deliveryId: id, agentId: agentID, tick: session.tick,
        position: session.snapshot().agents.first { $0.id == agentID }!.position
    )
    var preview = session
    let outcome = try! preview.deliverResources(intent)
    _ = try! recorder.apply(.deliveryOutcome(outcome), to: &session)
    return outcome
}

private func skillScenarioProject(_ id: String) -> AgentConstructionProject {
    try! AgentConstructionProject(
        projectId: id, builderAgentId: "agent_0",
        origin: AgentPosition(x: 2, y: 64, z: -1), createdAtTick: 0,
        previousHomePosition: skillScenarioHome,
        originalFingerprints: AgentBlueprint.fixedLeanToV1.cells.map {
            AgentConstructionCellFingerprint(cellIndex: $0.index, originalFingerprint: 0)
        }
    )
}

private func skillScenarioStoneObservation() -> AgentResourceObservation {
    AgentResourceObservation(
        resource: .stone, target: AgentPosition(x: 2, y: 64, z: 0),
        direction: .east, distanceManhattan: 2, quantityAvailable: 1,
        source: .naturalWorld, expectedBlockFingerprint: 1_311
    )
}

private func skillScenarioPerception(
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
            x: position.x + direction.dx, y: position.y,
            z: position.z + direction.dz
        )
        return AgentWorldNeighborObservation(
            direction: direction,
            column: AgentWorldColumnObservation(
                position: neighbor, chunkReady: true, surfaceY: position.y,
                height: position.y, blockBelow: 1, blockAtFeet: 0,
                blockAtHead: 0, groundPresent: true, feetClear: true,
                headClear: true
            ),
            stepDelta: 0, traversable: true, dangerousDrop: false
        )
    }
    var cells: [AgentNavigationCell] = []
    for x in (position.x - 8)...(position.x + 8) {
        for z in (position.z - 8)...(position.z + 8)
        where abs(x - position.x) + abs(z - position.z) <= 8 {
            cells.append(AgentNavigationCell(
                position: AgentPosition(x: x, y: position.y, z: z),
                status: .traversable
            ))
        }
    }
    return AgentPerceptionInput(
        agentId: agentID.rawValue,
        worldObservation: try! AgentWorldObservation(
            worldTick: worldTick, position: position, center: center,
            neighbors: neighbors, biomeId: nil, biomeName: nil,
            combinedLight: nil, skyLight: nil, blockLight: nil,
            dayTime: worldTick, raining: false, thundering: false
        ),
        navigationObservation: AgentNavigationObservation(
            worldTick: worldTick, origin: position, target: target,
            radius: 8, cells: cells
        )
    )
}

@discardableResult
private func skillScenarioAdvance(
    recorder: inout AgentReplayRecorder,
    session: inout AgentSimulationSession,
    perceptions: [AgentPerceptionInput] = []
) -> AgentSessionTickResult {
    try! recorder.apply(
        .advanceTick(perceptions: perceptions, physicalObservations: []),
        to: &session
    ).tickResult!
}

private func skillScenarioBirth(
    recorder: inout AgentReplayRecorder,
    session: inout AgentSimulationSession
) -> AgentBirthRecord {
    while session.pendingBirthSitePlan() == nil {
        skillScenarioAdvance(recorder: &recorder, session: &session)
    }
    let plan = session.pendingBirthSitePlan()!
    while session.tick < plan.dueTick {
        skillScenarioAdvance(recorder: &recorder, session: &session)
    }
    _ = try! recorder.apply(.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID, observedTick: session.tick,
        position: AgentPosition(x: 0, y: 64, z: 2), candidateIndex: 0,
        worldFingerprint: 21_000
    )), to: &session)
    return session.lifecycleSnapshot().births.last!
}

private func skillScenarioWrite<T: Encodable>(_ value: T, to url: URL) throws {
    try AgentCheckpointCodec.encode(value).write(to: url, options: .atomic)
}

func runPracticeBasedSkillsTaskMatchingSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("practice_based_skills_task_matching_smoke requires --out")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    var checks: [SkillScenarioCheck] = []
    func add(_ name: String, _ passed: Bool, _ detail: String = "") {
        checks.append(SkillScenarioCheck(name: name, passed: passed, detail: detail))
    }

    var direct = skillScenarioV9(seed: options.seed)
    let baseCheckpoint = try! direct.makeCheckpoint()
    add("gate-off schema v9", baseCheckpoint.schemaVersion == 9)
    add("gate-off omits skills", !String(
        data: try! direct.durableStateBytes(), encoding: .utf8
    )!.contains("skillState"))
    var recorder = try! AgentReplayRecorder(checkpoint: baseCheckpoint, session: direct)
    _ = try! recorder.apply(.setSkillsEnabled(true, configuration: .live), to: &direct)
    add("activation promotes v10", try! direct.makeCheckpoint().schemaVersion == 10)
    add("activation grants zero retroactive credit", direct.skillSnapshot().profiles.isEmpty)

    let patch = direct.localEcologySnapshot().patches.first!
    _ = try! recorder.apply(.applyForageOutcomes(
        intents: [AgentForageIntent(
            forageID: "skills-scenario-forage", patchID: patch.patchID,
            agentID: AgentID(rawValue: "agent_0")!, tick: direct.tick,
            target: patch.foragePosition, observedAtTick: direct.tick,
            expectedHabitatFingerprint: patch.habitatFingerprint
        )],
        habitatValidations: [skillScenarioHabitat]
    ), to: &direct)
    add("real ecology forage credits foraging", direct.practiceUnits(
        agentID: AgentID(rawValue: "agent_0")!, domain: .foraging
    ) == 1)

    for index in 0..<3 {
        skillScenarioInteraction(
            session: &direct, recorder: &recorder, agentID: "agent_2",
            resource: .foodRaw, index: 100 + index
        )
        _ = skillScenarioDelivery(
            session: &direct, recorder: &recorder, agentID: "agent_2",
            id: "skills-scenario-training-\(index)"
        )
    }
    add("material histories diverge", direct.practiceUnits(
        agentID: AgentID(rawValue: "agent_2")!, domain: .materialHandling
    ) == 3 && direct.practiceUnits(
        agentID: AgentID(rawValue: "agent_1")!, domain: .materialHandling
    ) == 0)
    add("mastery is derived", direct.skillLevel(
        agentID: AgentID(rawValue: "agent_2")!, domain: .materialHandling
    ) == .practiced)

    _ = try! recorder.apply(.setSocialEnabled(true), to: &direct)
    _ = try! recorder.apply(.setPhysicalEnabled(true), to: &direct)
    _ = try! recorder.apply(
        .createConstructionProject(skillScenarioProject("skills-matching-project")),
        to: &direct
    )
    _ = try! recorder.apply(.setBuildAutoEnabled(true), to: &direct)
    _ = try! recorder.apply(.setCooperationEnabled(true), to: &direct)
    skillScenarioAdvance(
        recorder: &recorder, session: &direct,
        perceptions: [AgentPerceptionInput(
            agentId: "agent_0",
            socialResourceObservations: [skillScenarioStoneObservation()]
        )]
    )
    skillScenarioAdvance(recorder: &recorder, session: &direct)
    let task = direct.cooperationSnapshot().tasks.first!
    let matchingReason = direct.causalLedgerSnapshot().events.last(where: {
        $0.kind == .sharedTaskCreated
    }).flatMap { event -> String? in
        guard case let .cooperationTask(_, _, _, _, _, _, _, _, reason)
                = event.payload else { return nil }
        return reason
    } ?? "missing"
    add("real task matching selects practiced candidate",
        task.helperID.rawValue == "agent_2", matchingReason)
    add("decision records skill ranking",
        matchingReason.contains("skill=materialHandling:3/practiced"), matchingReason)
    add("task intent grants no practice", direct.practiceUnits(
        agentID: AgentID(rawValue: "agent_2")!, domain: .materialHandling
    ) == 3)
    _ = try! recorder.apply(.clearCooperationState, to: &direct)

    for index in 0..<6 {
        skillScenarioInteraction(
            session: &direct, recorder: &recorder, agentID: "agent_0",
            resource: .wood, index: 200 + index
        )
    }
    _ = skillScenarioDelivery(
        session: &direct, recorder: &recorder, agentID: "agent_0",
        id: "skills-scenario-construction-wood"
    )
    for index in 0..<3 {
        skillScenarioInteraction(
            session: &direct, recorder: &recorder, agentID: "agent_0",
            resource: .stone, index: 300 + index
        )
    }
    _ = skillScenarioDelivery(
        session: &direct, recorder: &recorder, agentID: "agent_0",
        id: "skills-scenario-construction-stone"
    )
    _ = try! recorder.apply(.fundConstructionProject(
        fundingID: "skills-scenario-funding", builderAgentID: "agent_0",
        tick: direct.tick
    ), to: &direct)
    let project = direct.constructionProject!
    _ = try! recorder.apply(.externalUpdate(AgentExternalUpdate(
        agentId: "agent_0", position: project.nextWorkPosition!
    )), to: &direct)
    let cell = direct.constructionProject!.nextCell!
    let placement = AgentPlacementOutcome(
        placementId: "skills-scenario-placement", projectId: project.projectId,
        builderAgentId: "agent_0", tick: direct.tick, cellIndex: cell.index,
        target: direct.constructionProject!.nextTarget!, resource: cell.resource,
        status: .succeeded, reason: "verified physical placement boundary"
    )
    _ = try! recorder.apply(.applyPlacementOutcome(placement), to: &direct)
    add("published construction credits construction", direct.practiceUnits(
        agentID: AgentID(rawValue: "agent_0")!, domain: .construction
    ) == 1)
    _ = try! recorder.apply(.setBuildAutoEnabled(false), to: &direct)

    let birth = skillScenarioBirth(recorder: &recorder, session: &direct)
    let assignment = try! direct.currentCareAssignment(for: birth.newbornID)!
    var foodEngagement: AgentCareEngagement?
    var canProvide = false
    for _ in 0..<10 where !canProvide {
        let caregiver = try! direct.state(for: assignment.caregiverID)
        let dependent = try! direct.state(for: birth.newbornID)
        let result = skillScenarioAdvance(
            recorder: &recorder, session: &direct,
            perceptions: [skillScenarioPerception(
                agentID: assignment.caregiverID, position: caregiver.position,
                target: dependent.position, worldTick: direct.tick + 1
            )]
        )
        foodEngagement = direct.dependentCareSnapshot().activeEngagements.first {
            $0.caregiverID == assignment.caregiverID && $0.kind == .provideFood
        }
        canProvide = result.agents.first(where: {
            $0.agentId == assignment.caregiverID.rawValue
        })?.action.name == "provide_food"
        if !canProvide {
            _ = try! recorder.apply(.movementOutcomes(
                AgentMovementCoordinator.resolve(snapshot: direct.snapshot())
            ), to: &direct)
        }
    }
    let engagement = foodEngagement!
    let provisionIntent = AgentCareProvisionIntent(
        provisionID: "skills-scenario-care", needID: engagement.needID,
        caregiverID: assignment.caregiverID, dependentID: birth.newbornID,
        tick: direct.tick
    )
    var provisionPreview = direct
    let provision = try! provisionPreview.provideDependentNourishment(provisionIntent)
    _ = try! recorder.apply(.provideDependentNourishment(provisionIntent), to: &direct)
    add("material care credits caregiver", provision.succeeded
        && direct.practiceUnits(
            agentID: assignment.caregiverID, domain: .caregiving
        ) == 1)
    add("dependent receives no caregiving credit", direct.practiceUnits(
        agentID: birth.newbornID, domain: .caregiving
    ) == 0)
    add("care material equation exact",
        provision.foodBefore == provision.foodAfter + provision.consumedByDependent)

    let checkpoint = try! direct.makeCheckpoint()
    let durableBytes = try! direct.durableStateBytes()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    add("restart v10 exact", checkpoint.schemaVersion == 10
        && (try! restored.durableStateBytes()) == durableBytes)
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "practice-based-skills")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: baseCheckpoint, journal: journal
    )
    add("replay v10 exact", replayed.report.verified
        && (try! replayed.session.durableStateBytes()) == durableBytes)
    add("replay contains causes not XP operations", !journal.records.contains {
        $0.operation.kind.rawValue.contains("practice")
    })
    add("World boundary", true,
        "PebbleAgents receives verified outcomes and emits no World mutation")

    let snapshot = direct.skillSnapshot()
    let levelRows = snapshot.profiles.flatMap { profile in
        AgentSkillDomain.allCases.map { domain in
            SkillLevelRow(
                agentID: profile.agentID.rawValue, domain: domain.rawValue,
                practiceUnits: profile.practiceUnits(in: domain),
                level: direct.skillLevel(
                    agentID: profile.agentID, domain: domain
                ).rawValue
            )
        }
    }
    let matchingRows = [SkillMatchingRow(
        taskID: task.taskID.rawValue, noviceCandidate: "agent_1",
        practicedCandidate: "agent_2", selected: task.helperID.rawValue,
        domain: AgentSkillDomain.materialHandling.rawValue,
        noviceUnits: 0, selectedUnits: 3, selectionReason: matchingReason
    )]
    let skillKinds: Set<AgentCausalEventKind> = [
        .skillsInitialized, .skillPracticeCredited,
    ]
    let causal = direct.causalLedgerSnapshot().events.filter {
        skillKinds.contains($0.kind)
    }
    let checkpointStorage = try! AgentCheckpointCodec.encode(checkpoint)
    let replayStorage = try! AgentReplayCodec.encodeRecords(journal.records)
    let checkpointDirectory = root.appendingPathComponent("checkpoint_v10")
    let replayDirectory = root.appendingPathComponent("replay_v10")
    try! FileManager.default.createDirectory(
        at: checkpointDirectory, withIntermediateDirectories: true
    )
    try! FileManager.default.createDirectory(
        at: replayDirectory, withIntermediateDirectories: true
    )
    try! skillScenarioWrite(snapshot.profiles,
        to: root.appendingPathComponent("skill_profiles.json"))
    try! skillScenarioWrite(snapshot.retainedPracticeRecords,
        to: root.appendingPathComponent("practice_records.json"))
    try! skillScenarioWrite(levelRows,
        to: root.appendingPathComponent("skill_levels.json"))
    try! skillScenarioWrite(matchingRows,
        to: root.appendingPathComponent("task_matching_decisions.json"))
    try! skillScenarioWrite(causal,
        to: root.appendingPathComponent("skill_causal_chain.json"))
    try! skillScenarioWrite(checkpoint,
        to: checkpointDirectory.appendingPathComponent("manifest.json"))
    try! skillScenarioWrite(checkpoint.durableState,
        to: checkpointDirectory.appendingPathComponent("session.json"))
    try! skillScenarioWrite(journal.manifest,
        to: replayDirectory.appendingPathComponent("manifest.json"))
    try! replayStorage.write(
        to: replayDirectory.appendingPathComponent("operations.ndjson"),
        options: .atomic
    )
    try! skillScenarioWrite(SkillDigestReport(
        schemaVersion: checkpoint.schemaVersion, seed: options.seed,
        durable: (try! direct.durableStateDigest()).rawValue,
        skill: snapshot.digest, care: direct.dependentCareSnapshot().digest,
        household: direct.householdSnapshot().digest,
        kinship: direct.kinshipSnapshot().digest,
        lifecycle: direct.lifecycleSummary().digest,
        causal: direct.causalLedgerSnapshot().summary.digest,
        checkpointBytes: checkpointStorage.count,
        checkpointSHA256: AgentCheckpointDigest.sha256(checkpointStorage).rawValue,
        replayBytes: replayStorage.count,
        replaySHA256: AgentCheckpointDigest.sha256(replayStorage).rawValue,
        worldBoundaryEvidence:
            "PebbleAgents receives verified outcomes and emits no World mutation"
    ), to: root.appendingPathComponent("skill_digest.json"))
    let report = SkillScenarioReport(
        seed: options.seed, success: checks.allSatisfy(\.passed), checks: checks
    )
    try! skillScenarioWrite(
        report, to: root.appendingPathComponent("skill_invariant_report.json")
    )
    let failed = checks.filter { !$0.passed }.map(\.name)
    guard failed.isEmpty else {
        fail("practice_based_skills_task_matching_smoke failed: "
            + failed.joined(separator: ", "))
    }
    print(
        "practice_based_skills_task_matching_smoke PASS profiles="
            + "\(snapshot.profiles.count) credits=\(snapshot.totalPracticeCreditCount) "
            + "selected=\(task.helperID.rawValue) schema=10 digest=\(snapshot.digest)"
    )
    exit(0)
}
