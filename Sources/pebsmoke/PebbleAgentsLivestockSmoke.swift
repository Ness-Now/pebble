import Foundation
import PebbleAgents

private let livestockOrigin = AgentPosition(x: 0, y: 64, z: 0)

private func livestockAgent(_ index: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: index, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(index)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0.4, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(kind: .idle, reason: "livestock fixture", startedAtTick: 0, urgency: 0),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func livestockBase(_ id: String) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(seed: 46, memoryPolicy: .bounded(maxEntries: 128)),
        agents: (0..<3).map(livestockAgent),
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.initializePopulationRegistry(settlementAnchor: livestockOrigin, receptionPosition: livestockOrigin)
    try! session.setLifecycleEnabled(true, configuration: try! AgentLifecycleConfiguration(
        newbornDurationTicks: 8, maturityAgeTicks: 24,
        reproductionEvaluationIntervalTicks: 1, reproductionPlanDelayTicks: 1,
        reproductionCooldownTicks: 1, maximumRetainedBirthRecords: 32,
        maximumRetainedPlanRecords: 32, maximumParentBirthCount: 16
    ))
    try! session.setSkillsEnabled(true)
    try! session.setEcologicalObservationEnabled(true)
    return session
}

private func livestockObservation(_ session: AgentSimulationSession) -> AgentEcologicalObservation {
    let config = session.ecologicalObservationSnapshot().configuration!
    return AgentEcologicalObservation(
        observerID: AgentID(rawValue: "agent_0")!, origin: livestockOrigin,
        worldContextKey: "world-seed-46", dimensionKey: "overworld",
        observedAtSimulationTick: session.tick, physicalWorldTick: 100,
        civilDate: session.civilDate()!,
        biome: AgentBiomeObservation(biomeKey: "plains", position: livestockOrigin),
        water: [], soils: [], crops: [], plants: [],
        animals: [
            AgentAnimalObservation(speciesKey: "sheep", position: AgentPosition(x: 2, y: 64, z: 0), count: 1, lifeStage: .adult, breedableAffordanceObservable: true),
            AgentAnimalObservation(speciesKey: "sheep", position: AgentPosition(x: 3, y: 64, z: 0), count: 1, lifeStage: .adult, breedableAffordanceObservable: true),
            AgentAnimalObservation(speciesKey: "chicken", position: AgentPosition(x: 4, y: 64, z: 0), count: 1, lifeStage: .adult, breedableAffordanceObservable: false)
        ],
        fishing: [], weather: AgentWeatherObservation(kind: .clear, raining: false, thundering: false),
        physicalTime: AgentPhysicalWorldTimeObservation(worldTick: 100, dayTime: 100, timeOfDay: .day, daylightCycleEnabled: true),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: 4, cellsConsidered: 405, worldReads: 405, chunksTouched: 1,
            chunksUnavailable: 0, entitiesConsidered: 3, resultsEmitted: 6,
            cacheHits: 0, cacheMisses: 1, completion: .complete
        ),
        expiresAtSimulationTick: session.tick + config.dynamicFreshnessTicks
    )
}

private func livestockMaterial(_ key: String, count: Int = 1) -> AgentMaterialStackSnapshot {
    AgentMaterialStackSnapshot(
        identity: AgentMaterialIdentitySnapshot(
            itemKey: key, damage: 0, enchantments: [], label: nil,
            canonicalDataJSON: "{}"
        ), count: count
    )
}

func runPebbleAgentsLivestockSmoke() {
    section("PebbleAgents Livestock and animal capital")
    let actor = AgentID(rawValue: "agent_0")!
    let herdID = AgentLivestockHerdID(rawValue: "herd-sheep-1")!
    let firstID = AgentManagedAnimalRecordID(rawValue: "managed-sheep-1")!
    let secondID = AgentManagedAnimalRecordID(rawValue: "managed-sheep-2")!
    let childID = AgentManagedAnimalRecordID(rawValue: "managed-sheep-3")!
    let area = AgentLivestockManagementArea(
        minimum: AgentPosition(x: 0, y: 62, z: -2),
        maximum: AgentPosition(x: 8, y: 68, z: 4)
    )
    var session = livestockBase("livestock-agents-smoke")
    let coarseBefore = session.snapshot()
    let preEnable = session.livestockSnapshot()
    try! session.setLivestockEnabled(true)
    check("Livestock defaults off and activation creates no retroactive animals",
          !preEnable.enabled && session.livestockSnapshot().managedAnimals.isEmpty)
    _ = try! session.recordEcologicalObservation(livestockObservation(session))
    let observationEvent = session.ecologicalObservationSnapshot().observations.last!.causalEventID
    try! session.applyLivestockOperation(.establishHerd(
        herdID: herdID, speciesKey: "sheep", managementArea: area,
        responsibleAgentIDs: [actor]
    ))
    try! session.applyLivestockOperation(.admitObservedAnimal(
        recordID: firstID, herdID: herdID, actorID: actor, speciesKey: "sheep",
        position: AgentPosition(x: 2, y: 64, z: 0), lifeStage: .adult,
        sourceObservationEventID: observationEvent, compatibleFeedAvailable: true
    ))
    try! session.applyLivestockOperation(.admitObservedAnimal(
        recordID: secondID, herdID: herdID, actorID: actor, speciesKey: "sheep",
        position: AgentPosition(x: 3, y: 64, z: 0), lifeStage: .adult,
        sourceObservationEventID: observationEvent, compatibleFeedAvailable: true
    ))
    check("fresh local observation admits only explicit managed animals",
          session.livestockCapitalSnapshot().resolvedLivingCount == 2)
    let duplicateAdmissionBytes = try! session.durableStateBytes()
    do {
        try session.applyLivestockOperation(.admitObservedAnimal(
            recordID: AgentManagedAnimalRecordID(rawValue: "managed-sheep-duplicate")!,
            herdID: herdID, actorID: actor, speciesKey: "sheep",
            position: AgentPosition(x: 2, y: 64, z: 0), lifeStage: .adult,
            sourceObservationEventID: observationEvent, compatibleFeedAvailable: true
        ))
        check("same observed animal cannot be admitted twice", false)
    } catch AgentSessionError.livestock(.invalidAnimal) {
        check("same observed animal cannot be admitted twice",
              (try! session.durableStateBytes()) == duplicateAdmissionBytes)
    } catch { check("same observed animal cannot be admitted twice", false, "\(error)") }

    try! session.setWildSubsistenceEnabled(true)
    let huntingChoices = try! session.eligibleSubsistenceStrategies(
        AgentSubsistenceDecisionContext(
            actorID: actor, fishingRodAvailable: false,
            huntingWeaponAvailable: true, agricultureAvailable: false,
            maximumDistance: 8, subsistencePressure: 80
        )
    )
    check("resolved managed livestock is excluded from normal WildSubsistence hunting",
          huntingChoices.count == 1
            && huntingChoices[0].targetKey.contains("animal:chicken@"))

    let feedTask = AgentLivestockTaskID(rawValue: "task-feed-1")!
    try! session.applyLivestockOperation(.queueTask(AgentLivestockTaskRequest(
        taskID: feedTask, herdID: herdID, kind: .feed,
        primaryAnimalRecordID: firstID, responsibleAgentID: actor,
        targetPosition: AgentPosition(x: 2, y: 64, z: 0)
    )))
    let feedAction = AgentLivestockActionID(rawValue: "action-feed-1")!
    let feed = AgentLivestockValidatedOutcome(
        actionID: feedAction, taskID: feedTask, actorID: actor, kind: .feed,
        status: .succeeded, primaryAnimalRecordID: firstID,
        physicalCausalIDs: [101], consumedItems: [livestockMaterial("wheat")],
        attribution: "core-animal-feed", completedAtTick: session.tick
    )
    try! session.applyLivestockOperation(.recordOutcome(feed))
    check("successful real feed conserves one item and credits husbandry once",
          session.livestockCapitalSnapshot().feedInputsObserved == 1
            && session.practiceUnits(agentID: actor, domain: .husbandry) == 1)
    do {
        try session.applyLivestockOperation(.recordOutcome(feed))
        check("duplicate livestock action is rejected", false)
    } catch AgentSessionError.livestock(.duplicateAction) {
        check("duplicate livestock action is rejected", true)
    } catch { check("duplicate livestock action is rejected", false, "\(error)") }

    try! session.applyLivestockOperation(.recordBreedingDecision(
        actionID: AgentLivestockActionID(rawValue: "breed-deferred")!, herdID: herdID,
        actorID: actor, parentRecordIDs: [firstID, secondID],
        compatibleFeedQuantity: 3, reservedPlantingQuantity: 2
    ))
    check("seed reserve defers breeding under compatible-feed shortage",
          session.livestockSnapshot().breedingDecisions.last?.status == .deferredFeedShortage)

    let breedTask = AgentLivestockTaskID(rawValue: "task-breed-1")!
    try! session.applyLivestockOperation(.queueTask(AgentLivestockTaskRequest(
        taskID: breedTask, herdID: herdID, kind: .breed,
        primaryAnimalRecordID: firstID, secondaryAnimalRecordID: secondID,
        responsibleAgentID: actor, targetPosition: AgentPosition(x: 2, y: 64, z: 0)
    )))
    try! session.applyLivestockOperation(.recordOutcome(AgentLivestockValidatedOutcome(
        actionID: AgentLivestockActionID(rawValue: "action-breed-1")!,
        taskID: breedTask, actorID: actor, kind: .breedingObserved,
        status: .succeeded, primaryAnimalRecordID: firstID,
        secondaryAnimalRecordID: secondID, physicalCausalIDs: [201],
        offspring: AgentLivestockOffspringSnapshot(
            recordID: childID, speciesKey: "sheep",
            position: AgentPosition(x: 2, y: 64, z: 1), lifeStage: .juvenile
        ), attribution: "core-breed-goal-birth", completedAtTick: session.tick
    )))
    check("observed Core offspring increases current capital without double XP",
          session.livestockCapitalSnapshot().youngCount == 1
            && session.practiceUnits(agentID: actor, domain: .husbandry) == 1)

    let productTask = AgentLivestockTaskID(rawValue: "task-product-1")!
    try! session.applyLivestockOperation(.queueTask(AgentLivestockTaskRequest(
        taskID: productTask, herdID: herdID, kind: .collectProduct,
        primaryAnimalRecordID: firstID, responsibleAgentID: actor,
        targetPosition: AgentPosition(x: 2, y: 64, z: 0)
    )))
    try! session.applyLivestockOperation(.recordOutcome(AgentLivestockValidatedOutcome(
        actionID: AgentLivestockActionID(rawValue: "action-product-1")!,
        taskID: productTask, actorID: actor, kind: .collectProduct,
        status: .succeeded, primaryAnimalRecordID: firstID,
        physicalCausalIDs: [301, 302], acquiredItems: [livestockMaterial("white_wool", count: 2)],
        custodyFingerprint: "agent-custody-after-wool", attribution: "core-sheep-shear",
        completedAtTick: session.tick
    )))
    check("real product custody is non-spendable capital history",
          session.livestockCapitalSnapshot().recentPhysicalOutputs == 2
            && session.practiceUnits(agentID: actor, domain: .husbandry) == 2)

    let herdTask = AgentLivestockTaskID(rawValue: "task-herd-1")!
    try! session.applyLivestockOperation(.queueTask(AgentLivestockTaskRequest(
        taskID: herdTask, herdID: herdID, kind: .herdMove,
        primaryAnimalRecordID: firstID, responsibleAgentID: actor,
        targetPosition: AgentPosition(x: 4, y: 64, z: 1)
    )))
    try! session.applyLivestockOperation(.recordOutcome(AgentLivestockValidatedOutcome(
        actionID: AgentLivestockActionID(rawValue: "action-herd-1")!,
        taskID: herdTask, actorID: actor, kind: .herdMove,
        status: .succeeded, primaryAnimalRecordID: firstID,
        physicalCausalIDs: [401], finalPosition: AgentPosition(x: 4, y: 64, z: 1),
        attribution: "core-leash-physics", completedAtTick: session.tick
    )))
    check("physically completed herding credits exactly one practice unit",
          session.practiceUnits(agentID: actor, domain: .husbandry) == 3)

    try! session.setTeachingEnabled(true)
    let student = AgentID(rawValue: "agent_1")!
    let engagement = try! session.selectMentorAndStartApprenticeship(
        AgentMentorSelectionRequest(
            requestID: "husbandry-apprenticeship", studentID: student,
            domain: .husbandry, studentAccepts: true,
            candidates: [AgentMentorCandidateConsent(teacherID: actor, accepts: true)],
            requestedAtTick: session.tick
        )
    )!
    _ = try! session.advanceTick()
    let teacherFeedTask = AgentLivestockTaskID(rawValue: "task-teaching-feed")!
    try! session.applyLivestockOperation(.queueTask(AgentLivestockTaskRequest(
        taskID: teacherFeedTask, herdID: herdID, kind: .feed,
        primaryAnimalRecordID: secondID, responsibleAgentID: actor,
        targetPosition: AgentPosition(x: 3, y: 64, z: 0)
    )))
    let teacherFeedAction = AgentLivestockActionID(rawValue: "action-teaching-feed")!
    try! session.applyLivestockOperation(.recordOutcome(AgentLivestockValidatedOutcome(
        actionID: teacherFeedAction, taskID: teacherFeedTask, actorID: actor,
        kind: .feed, status: .succeeded, primaryAnimalRecordID: secondID,
        physicalCausalIDs: [402], consumedItems: [livestockMaterial("wheat")],
        attribution: "core-animal-feed", completedAtTick: session.tick
    )))
    let teacherSource = session.causalLedgerSnapshot().events.last {
        $0.kind == .animalFed && $0.operationID?.rawValue == teacherFeedAction.rawValue
    }!.eventID
    let teacherPosition = try! session.state(for: actor).position
    let studentPosition = try! session.state(for: student).position
    let channel = session.configuration.physicalChannelConfiguration
    let studentBeforeExposure = session.practiceUnits(agentID: student, domain: .husbandry)
    _ = try! session.recordTeachingDemonstration(AgentTeachingObservation(
        apprenticeshipID: engagement.apprenticeshipID,
        teacherID: actor, studentID: student, domain: .husbandry,
        sourceSuccessEventID: teacherSource,
        teacherPosition: teacherPosition, studentPosition: studentPosition,
        distanceManhattan: 1,
        soundClarity: channel.soundClarity(distanceManhattan: 1, opaqueOcclusionCount: 0),
        gestureClarity: channel.gestureClarity(distanceManhattan: 1, lineOfSight: true),
        opaqueOcclusionCount: 0, lineOfSight: true, chunksReady: true,
        observedAtTick: session.tick
    ))
    check("husbandry Teaching exposure grants no free skill",
          session.practiceUnits(agentID: student, domain: .husbandry)
            == studentBeforeExposure)

    let studentTask = AgentLivestockTaskID(rawValue: "task-student-feed")!
    try! session.applyLivestockOperation(.queueTask(AgentLivestockTaskRequest(
        taskID: studentTask, herdID: herdID, kind: .feed,
        primaryAnimalRecordID: secondID, responsibleAgentID: student,
        targetPosition: AgentPosition(x: 3, y: 64, z: 0)
    )))
    try! session.applyLivestockOperation(.recordOutcome(AgentLivestockValidatedOutcome(
        actionID: AgentLivestockActionID(rawValue: "action-student-feed")!,
        taskID: studentTask, actorID: student, kind: .feed,
        status: .succeeded, primaryAnimalRecordID: secondID,
        physicalCausalIDs: [403], consumedItems: [livestockMaterial("wheat")],
        attribution: "core-animal-feed", completedAtTick: session.tick
    )))
    check("student own husbandry success grants exactly one practice unit",
          session.practiceUnits(agentID: student, domain: .husbandry)
            == studentBeforeExposure + 1)

    let failedPracticeBefore = session.practiceUnits(agentID: actor, domain: .husbandry)
    let failedFeedInputsBefore = session.livestockCapitalSnapshot().feedInputsObserved
    let missingFeedTask = AgentLivestockTaskID(rawValue: "task-missing-feed")!
    try! session.applyLivestockOperation(.queueTask(AgentLivestockTaskRequest(
        taskID: missingFeedTask, herdID: herdID, kind: .feed,
        primaryAnimalRecordID: firstID, responsibleAgentID: actor,
        targetPosition: AgentPosition(x: 4, y: 64, z: 1)
    )))
    try! session.applyLivestockOperation(.recordOutcome(AgentLivestockValidatedOutcome(
        actionID: AgentLivestockActionID(rawValue: "action-missing-feed")!,
        taskID: missingFeedTask, actorID: actor, kind: .feed,
        status: .failed, primaryAnimalRecordID: firstID,
        attribution: "missing-real-feed", completedAtTick: session.tick
    )))
    check("missing-feed failure grants no input, capital, or husbandry credit",
          session.practiceUnits(agentID: actor, domain: .husbandry) == failedPracticeBefore
            && session.livestockCapitalSnapshot().feedInputsObserved
                == failedFeedInputsBefore)

    for index in 0..<80 {
        try! session.applyLivestockOperation(.recordBreedingDecision(
            actionID: AgentLivestockActionID(rawValue: "long-run-shortage-\(index)")!,
            herdID: herdID, actorID: actor,
            parentRecordIDs: [firstID, secondID],
            compatibleFeedQuantity: 1, reservedPlantingQuantity: 1
        ))
        _ = try! session.advanceTick()
    }
    let bounded = session.livestockSnapshot()
    check("80-tick feed shortage keeps history bounded with no invented offspring",
          bounded.breedingDecisions.count == 64
            && bounded.evictionCounts.breedingDecisions == 17
            && bounded.activeTasks.isEmpty && bounded.reservations.isEmpty
            && bounded.capital.recentBirths == 1
            && session.livestockFeedPressure(
                compatibleFeedQuantity: 1, reservedPlantingQuantity: 1
            ).level == .high)

    try! session.applyLivestockOperation(.reconcile([
        AgentManagedAnimalResolution(recordID: firstID, kind: .resolvedLiving,
            speciesKey: "sheep", position: AgentPosition(x: 2, y: 64, z: 0),
            lifeStage: .adult, productReady: false, reason: "exact binding", observedAtTick: session.tick),
        AgentManagedAnimalResolution(recordID: secondID, kind: .ambiguous,
            speciesKey: "sheep", reason: "two matching sheep after restart", observedAtTick: session.tick),
        AgentManagedAnimalResolution(recordID: childID, kind: .missing,
            speciesKey: "sheep", reason: "not found in bounded scan", observedAtTick: session.tick)
    ]))
    let reconciled = session.livestockCapitalSnapshot()
    check("ambiguous identity remains unresolved and missing animal becomes visible loss",
          reconciled.resolvedLivingCount == 1 && reconciled.unresolvedCount == 1
            && reconciled.missingCount == 1 && reconciled.recentLosses == 1)

    let coarse = session.snapshot()
    check("livestock creates no ghost CampStock, ResourceInventory, or LocalEcology credit",
          coarse.campStock == coarseBefore.campStock
            && coarse.agents.map(\.resourceInventory)
                == coarseBefore.agents.map(\.resourceInventory)
            && !session.localEcologyEnabled)

    let checkpoint = try! session.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("v15 checkpoint restores management records but no physical animals",
          checkpoint.schemaVersion == 15
            && restored.livestockSnapshot().digest == session.livestockSnapshot().digest
            && (try! restored.durableStateBytes()) == (try! session.durableStateBytes()))

    var replayBase = livestockBase("livestock-replay-smoke")
    _ = try! replayBase.recordEcologicalObservation(livestockObservation(replayBase))
    let replayObservation = replayBase.ecologicalObservationSnapshot().observations.last!.causalEventID
    let v14 = try! replayBase.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(checkpoint: v14, session: replayBase)
    _ = try! recorder.apply(.setLivestockEnabled(true, configuration: .live), to: &replayBase)
    _ = try! recorder.apply(.applyLivestockOperation(.establishHerd(
        herdID: herdID, speciesKey: "sheep", managementArea: area,
        responsibleAgentIDs: [actor]
    )), to: &replayBase)
    _ = try! recorder.apply(.applyLivestockOperation(.admitObservedAnimal(
        recordID: firstID, herdID: herdID, actorID: actor, speciesKey: "sheep",
        position: AgentPosition(x: 2, y: 64, z: 0), lifeStage: .adult,
        sourceObservationEventID: replayObservation, compatibleFeedAvailable: true
    )), to: &replayBase)
    let journal = try! recorder.journal(named: AgentCheckpointName(rawValue: "livestock-replay")!)
    let replay = try! AgentSessionReplayer.replay(checkpoint: v14, journal: journal)
    check("v15 replay reproduces livestock state and causal digest",
          replay.report.verified && replay.report.schemaVersion == 15
            && (try! replay.session.durableStateBytes()) == (try! replayBase.durableStateBytes()))
}
