import Foundation
import PebbleAgents

private let wildOrigin = AgentPosition(x: 0, y: 64, z: 0)
private let wildLifecycle = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 8, maturityAgeTicks: 24,
    reproductionEvaluationIntervalTicks: 1, reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1, maximumRetainedBirthRecords: 32,
    maximumRetainedPlanRecords: 32, maximumParentBirthCount: 16
)

private func wildAgent(_ index: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: index, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(index)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0.5, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(kind: .idle, reason: "wild subsistence fixture", startedAtTick: 0, urgency: 0),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func wildBase(_ id: String) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(seed: 46, memoryPolicy: .bounded(maxEntries: 128)),
        agents: (0..<3).map(wildAgent),
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.initializePopulationRegistry(settlementAnchor: wildOrigin, receptionPosition: wildOrigin)
    try! session.setLifecycleEnabled(true, configuration: wildLifecycle)
    try! session.setSkillsEnabled(true)
    try! session.setEcologicalObservationEnabled(true)
    return session
}

private func wildObservation(
    _ session: AgentSimulationSession,
    observer: String = "agent_0",
    fishing: Bool = true,
    hunting: Bool = true,
    gathering: Bool = true
) -> AgentEcologicalObservation {
    let configuration = session.ecologicalObservationSnapshot().configuration!
    let origin = AgentPosition(x: observer == "agent_0" ? 0 : 1, y: 64, z: 0)
    let plants = gathering ? [AgentPlantObservation(
        plantKey: "sweet_berry_bush", position: AgentPosition(x: 1, y: 64, z: 0),
        renewability: .knownRenewable
    )] : []
    let animals = hunting ? [AgentAnimalObservation(
        speciesKey: "chicken", position: AgentPosition(x: 2, y: 64, z: 0),
        count: 1, lifeStage: .adult, breedableAffordanceObservable: false
    )] : []
    let fishingValues = fishing ? [AgentFishingAffordance(
        position: AgentPosition(x: 1, y: 63, z: 0), waterKey: "water", candidate: true
    )] : []
    return AgentEcologicalObservation(
        observerID: AgentID(rawValue: observer)!, origin: origin,
        worldContextKey: "world-seed-46", dimensionKey: "overworld",
        observedAtSimulationTick: session.tick, physicalWorldTick: 120,
        civilDate: session.civilDate()!,
        biome: AgentBiomeObservation(biomeKey: "plains", position: origin),
        water: fishingValues.map { AgentWaterAffordance(fluidKey: "water", position: $0.position, sourceBlock: true) },
        soils: [], crops: [], plants: plants, animals: animals, fishing: fishingValues,
        weather: AgentWeatherObservation(kind: .clear, raining: false, thundering: false),
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: 120, dayTime: 120, timeOfDay: .day, daylightCycleEnabled: true
        ),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: 4, cellsConsidered: 405, worldReads: 405, chunksTouched: 1,
            chunksUnavailable: 0, entitiesConsidered: animals.count,
            resultsEmitted: 3 + fishingValues.count + plants.count
                + animals.count + fishingValues.count,
            cacheHits: 0, cacheMisses: 1, completion: .complete
        ),
        expiresAtSimulationTick: session.tick + configuration.dynamicFreshnessTicks
    )
}

private func wildMaterial(_ key: String, count: Int = 1) -> AgentMaterialStackSnapshot {
    AgentMaterialStackSnapshot(
        identity: AgentMaterialIdentitySnapshot(
            itemKey: key, damage: 0, enchantments: [], label: nil, canonicalDataJSON: "{}"
        ),
        count: count
    )
}

private func wildOutcome(
    _ session: AgentSimulationSession,
    opportunity: AgentSubsistenceOpportunity,
    suffix: String,
    status: AgentSubsistenceOutcomeStatus = .succeeded,
    item: String = "cod"
) -> AgentSubsistenceOutcome {
    AgentSubsistenceOutcome(
        attemptID: AgentSubsistenceAttemptID(rawValue: "wild-attempt-\(suffix)")!,
        opportunityID: opportunity.opportunityID, actorID: opportunity.actorID,
        strategy: opportunity.strategy, targetKey: opportunity.targetKey,
        targetPosition: opportunity.lastObservedPosition,
        sourceObservationEventID: opportunity.sourceObservationEventID,
        status: status,
        physicalCausalIDs: status == .succeeded ? [100 + suffix.count] : [],
        acquiredItems: status == .succeeded ? [wildMaterial(item)] : [],
        custodyFingerprint: status == .succeeded ? "agent-after-\(suffix)" : nil,
        attribution: status == .succeeded ? "core-physical-\(suffix)" : nil,
        completedAtTick: session.tick
    )
}

func runPebbleAgentsWildSubsistenceSmoke() {
    section("PebbleAgents bounded wild subsistence")

    check(
        "wild source viability shares the canonical gatherable plant policy",
        AgentWildSubsistenceMaterialPolicy.isGatherablePlant(
            "sweet_berry_bush"
        ) && AgentWildSubsistenceMaterialPolicy.isGatherablePlant("pumpkin")
    )
    check(
        "locally observed non-gatherable flora is not an executable source",
        !AgentWildSubsistenceMaterialPolicy.isGatherablePlant("dandelion")
            && !AgentWildSubsistenceMaterialPolicy.isGatherablePlant("oak_sapling")
    )
    check("WildSubsistence gate is default off", !wildBase("wild-off").wildSubsistenceEnabled)
    check("activation dependencies are atomic", {
        var noObservation = try! AgentSimulationSession(
            configuration: try! AgentSessionConfiguration(
                seed: 46, memoryPolicy: .bounded(maxEntries: 128)
            ),
            agents: (0..<3).map(wildAgent), simulationID: AgentSimulationID(rawValue: "wild-deps")!,
            causalLedgerPolicy: .bounded(maxEvents: 2048)
        )
        try! noObservation.initializePopulationRegistry(settlementAnchor: wildOrigin, receptionPosition: wildOrigin)
        try! noObservation.setLifecycleEnabled(true, configuration: wildLifecycle)
        try! noObservation.setSkillsEnabled(true)
        let before = try! noObservation.durableStateBytes()
        do {
            try noObservation.setWildSubsistenceEnabled(true)
            return false
        } catch AgentSessionError.wildSubsistence(.ecologicalObservationRequired) {
            return !noObservation.wildSubsistenceEnabled && (try! noObservation.durableStateBytes()) == before
        } catch { return false }
    }())

    var session = wildBase("wild-contract")
    _ = try! session.recordEcologicalObservation(wildObservation(session))
    try! session.setAgricultureEnabled(true)
    let v13 = try! session.makeCheckpoint()
    let v13Restored = try! AgentSimulationSession.restoring(v13)
    check("schema 30 loads with no retroactive wild history",
          v13.schemaVersion
            == AgentCheckpointSchema.independentEcologicalReceiptVersion
            && !v13Restored.wildSubsistenceEnabled
            && (try! v13Restored.durableStateBytes()) == (try! session.durableStateBytes()))
    let coarseBefore = session.snapshot()
    try! session.setWildSubsistenceEnabled(true)
    check("schema 30 activation starts empty and agriculture is not an activation dependency",
          session.durableState().schemaVersion
            == AgentCheckpointSchema.independentEcologicalReceiptVersion
            && session.wildSubsistenceSnapshot().opportunities.isEmpty
            && session.wildSubsistenceSnapshot().retainedOutcomes.isEmpty)

    let actor0 = AgentID(rawValue: "agent_0")!
    let noRod = try! session.eligibleSubsistenceStrategies(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: false, huntingWeaponAvailable: false,
        agricultureAvailable: false, subsistencePressure: 50
    ))
    check("equipment ablation removes fishing and hunting",
          noRod.map(\.strategy) == [.wildGathering])
    let multi = try! session.eligibleSubsistenceStrategies(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: true, huntingWeaponAvailable: true,
        agricultureAvailable: true, subsistencePressure: 50
    ))
    check("fresh local evidence makes four distinct strategies comparable",
          Set(multi.map(\.strategy)) == Set(AgentSubsistenceStrategy.allCases))
    check("deterministic local scoring selects a cause-backed strategy",
          multi.first?.strategy == .agriculture && multi.first?.reason.contains("managed plot") == true)

    let fishContext = AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: true, huntingWeaponAvailable: false,
        agricultureAvailable: false, subsistencePressure: 80
    )
    let fishing = try! session.selectWildSubsistenceOpportunity(fishContext)
    let observationPractice = session.practiceUnits(agentID: actor0, domain: .fishing)
    check("selection/casting intent grants zero practice", observationPractice == 0 && fishing.strategy == .fishing)
    let fishRecord = try! session.recordWildSubsistenceOutcome(wildOutcome(
        session, opportunity: fishing, suffix: "fish", item: "cod"
    ))
    check("real acquired fishing result grants exactly one fishing practice",
          fishRecord.skillPracticeEventID != nil
            && session.practiceUnits(agentID: actor0, domain: .fishing) == observationPractice + 1)
    let duplicateBytes = try! session.durableStateBytes()
    do {
        _ = try session.recordWildSubsistenceOutcome(wildOutcome(
            session, opportunity: fishing, suffix: "fish", item: "cod"
        ))
        check("duplicate fishing result is idempotent", false)
    } catch AgentSessionError.wildSubsistence(.duplicateAttempt) {
        check("duplicate fishing result is idempotent", (try! session.durableStateBytes()) == duplicateBytes)
    } catch { check("duplicate fishing result is idempotent", false, "\(error)") }

    _ = try! session.recordEcologicalObservation(wildObservation(session, fishing: false, hunting: true, gathering: false))
    let hunt = try! session.selectWildSubsistenceOpportunity(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: false, huntingWeaponAvailable: true,
        agricultureAvailable: false, subsistencePressure: 60
    ))
    _ = try! session.recordWildSubsistenceOutcome(wildOutcome(
        session, opportunity: hunt, suffix: "hunt", item: "chicken"
    ))
    check("attributed material hunt grants exactly one hunting practice",
          hunt.strategy == .hunting && session.practiceUnits(agentID: actor0, domain: .hunting) == 1)

    _ = try! session.recordEcologicalObservation(wildObservation(session, fishing: false, hunting: false, gathering: true))
    let gather = try! session.selectWildSubsistenceOpportunity(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: false, huntingWeaponAvailable: false,
        agricultureAvailable: false, subsistencePressure: 60
    ))
    let forageBefore = session.practiceUnits(agentID: actor0, domain: .foraging)
    _ = try! session.recordWildSubsistenceOutcome(wildOutcome(
        session, opportunity: gather, suffix: "gather", item: "sweet_berries"
    ))
    check("physical wild gather reuses foraging and grants one practice",
          gather.strategy == .wildGathering
            && session.practiceUnits(agentID: actor0, domain: .foraging) == forageBefore + 1)

    _ = try! session.recordEcologicalObservation(wildObservation(session, fishing: false, hunting: true, gathering: false))
    let failedHunt = try! session.selectWildSubsistenceOpportunity(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: false, huntingWeaponAvailable: true,
        agricultureAvailable: false
    ))
    let huntPractice = session.practiceUnits(agentID: actor0, domain: .hunting)
    _ = try! session.recordWildSubsistenceOutcome(wildOutcome(
        session, opportunity: failedHunt, suffix: "failed-hunt", status: .failed
    ))
    check("failed physical hunt grants zero practice",
          session.practiceUnits(agentID: actor0, domain: .hunting) == huntPractice)

    _ = try! session.recordEcologicalObservation(wildObservation(
        session, fishing: false, hunting: false, gathering: true
    ))
    _ = try! session.recordEcologicalObservation(wildObservation(
        session, observer: "agent_1", fishing: false, hunting: false, gathering: true
    ))
    let actor1 = AgentID(rawValue: "agent_1")!
    let reservedBy0 = try! session.selectWildSubsistenceOpportunity(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: false, huntingWeaponAvailable: false,
        agricultureAvailable: false
    ))
    let actor1Choices = try! session.eligibleSubsistenceStrategies(AgentSubsistenceDecisionContext(
        actorID: actor1, fishingRodAvailable: false, huntingWeaponAvailable: false,
        agricultureAvailable: false
    ))
    check("one-shot wild target reservation prevents duplicate claims",
          reservedBy0.strategy == .wildGathering && actor1Choices.allSatisfy { $0.strategy != .wildGathering })

    var teaching = wildBase("wild-teaching")
    try! teaching.setWildSubsistenceEnabled(true)
    var latestTeacherSuccess: AgentCausalEventID?
    for index in 0..<3 {
        _ = try! teaching.recordEcologicalObservation(wildObservation(
            teaching, fishing: true, hunting: false, gathering: false
        ))
        let opportunity = try! teaching.selectWildSubsistenceOpportunity(
            AgentSubsistenceDecisionContext(
                actorID: actor0, fishingRodAvailable: true,
                huntingWeaponAvailable: false, agricultureAvailable: false
            )
        )
        let record = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
            teaching, opportunity: opportunity, suffix: "teacher-fish-\(index)", item: "cod"
        ))
        latestTeacherSuccess = record.subsistenceEventID
    }
    try! teaching.setTeachingEnabled(true)
    let engagement = try! teaching.selectMentorAndStartApprenticeship(
        AgentMentorSelectionRequest(
            requestID: "wild-fishing-apprenticeship", studentID: actor1,
            domain: .fishing, studentAccepts: true,
            candidates: [AgentMentorCandidateConsent(teacherID: actor0, accepts: true)],
            requestedAtTick: teaching.tick
        )
    )!
    _ = try! teaching.advanceTick()
    _ = try! teaching.recordEcologicalObservation(wildObservation(
        teaching, fishing: true, hunting: false, gathering: false
    ))
    let demonstratedFishing = try! teaching.selectWildSubsistenceOpportunity(
        AgentSubsistenceDecisionContext(
            actorID: actor0, fishingRodAvailable: true,
            huntingWeaponAvailable: false, agricultureAvailable: false
        )
    )
    latestTeacherSuccess = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
        teaching, opportunity: demonstratedFishing,
        suffix: "teacher-fish-demonstrated", item: "cod"
    )).subsistenceEventID
    let teacherPosition = try! teaching.state(for: actor0).position
    let studentPosition = try! teaching.state(for: actor1).position
    let distance = abs(teacherPosition.x - studentPosition.x)
        + abs(teacherPosition.y - studentPosition.y)
        + abs(teacherPosition.z - studentPosition.z)
    let physical = teaching.configuration.physicalChannelConfiguration
    let studentBeforeExposure = teaching.practiceUnits(agentID: actor1, domain: .fishing)
    _ = try! teaching.recordTeachingDemonstration(AgentTeachingObservation(
        apprenticeshipID: engagement.apprenticeshipID,
        teacherID: actor0, studentID: actor1, domain: .fishing,
        sourceSuccessEventID: latestTeacherSuccess!,
        teacherPosition: teacherPosition, studentPosition: studentPosition,
        distanceManhattan: distance,
        soundClarity: physical.soundClarity(
            distanceManhattan: distance, opaqueOcclusionCount: 0
        ),
        gestureClarity: physical.gestureClarity(
            distanceManhattan: distance, lineOfSight: true
        ),
        opaqueOcclusionCount: 0, lineOfSight: true, chunksReady: true,
        observedAtTick: teaching.tick
    ))
    check("fishing Teaching exposure grants zero free skill",
          teaching.practiceUnits(agentID: actor1, domain: .fishing) == studentBeforeExposure)
    _ = try! teaching.recordEcologicalObservation(wildObservation(
        teaching, observer: "agent_1", fishing: true, hunting: false, gathering: false
    ))
    let studentFishing = try! teaching.selectWildSubsistenceOpportunity(
        AgentSubsistenceDecisionContext(
            actorID: actor1, fishingRodAvailable: true,
            huntingWeaponAvailable: false, agricultureAvailable: false
        )
    )
    _ = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
        teaching, opportunity: studentFishing, suffix: "student-fish", item: "cod"
    ))
    check("student own material fishing success grants exactly one practice",
          teaching.practiceUnits(agentID: actor1, domain: .fishing) == studentBeforeExposure + 1)

    var latestHuntSuccess: AgentCausalEventID?
    for index in 0..<3 {
        _ = try! teaching.recordEcologicalObservation(wildObservation(
            teaching, fishing: false, hunting: true, gathering: false
        ))
        let opportunity = try! teaching.selectWildSubsistenceOpportunity(
            AgentSubsistenceDecisionContext(
                actorID: actor0, fishingRodAvailable: false,
                huntingWeaponAvailable: true, agricultureAvailable: false
            )
        )
        let record = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
            teaching, opportunity: opportunity, suffix: "teacher-hunt-\(index)", item: "chicken"
        ))
        latestHuntSuccess = record.subsistenceEventID
    }
    let huntingEngagement = try! teaching.selectMentorAndStartApprenticeship(
        AgentMentorSelectionRequest(
            requestID: "wild-hunting-apprenticeship", studentID: actor1,
            domain: .hunting, studentAccepts: true,
            candidates: [AgentMentorCandidateConsent(teacherID: actor0, accepts: true)],
            requestedAtTick: teaching.tick
        )
    )!
    _ = try! teaching.advanceTick()
    _ = try! teaching.recordEcologicalObservation(wildObservation(
        teaching, fishing: false, hunting: true, gathering: false
    ))
    let demonstratedHunting = try! teaching.selectWildSubsistenceOpportunity(
        AgentSubsistenceDecisionContext(
            actorID: actor0, fishingRodAvailable: false,
            huntingWeaponAvailable: true, agricultureAvailable: false
        )
    )
    latestHuntSuccess = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
        teaching, opportunity: demonstratedHunting,
        suffix: "teacher-hunt-demonstrated", item: "chicken"
    )).subsistenceEventID
    let studentHuntingBeforeExposure = teaching.practiceUnits(agentID: actor1, domain: .hunting)
    _ = try! teaching.recordTeachingDemonstration(AgentTeachingObservation(
        apprenticeshipID: huntingEngagement.apprenticeshipID,
        teacherID: actor0, studentID: actor1, domain: .hunting,
        sourceSuccessEventID: latestHuntSuccess!,
        teacherPosition: teacherPosition, studentPosition: studentPosition,
        distanceManhattan: distance,
        soundClarity: physical.soundClarity(
            distanceManhattan: distance, opaqueOcclusionCount: 0
        ),
        gestureClarity: physical.gestureClarity(
            distanceManhattan: distance, lineOfSight: true
        ),
        opaqueOcclusionCount: 0, lineOfSight: true, chunksReady: true,
        observedAtTick: teaching.tick
    ))
    check("hunting Teaching exposure grants zero free skill",
          teaching.practiceUnits(agentID: actor1, domain: .hunting)
            == studentHuntingBeforeExposure)
    _ = try! teaching.recordEcologicalObservation(wildObservation(
        teaching, observer: "agent_1", fishing: false, hunting: true, gathering: false
    ))
    let studentHunting = try! teaching.selectWildSubsistenceOpportunity(
        AgentSubsistenceDecisionContext(
            actorID: actor1, fishingRodAvailable: false,
            huntingWeaponAvailable: true, agricultureAvailable: false
        )
    )
    _ = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
        teaching, opportunity: studentHunting, suffix: "student-hunt", item: "chicken"
    ))
    check("student own attributed hunt grants exactly one practice",
          teaching.practiceUnits(agentID: actor1, domain: .hunting)
            == studentHuntingBeforeExposure + 1)

    check("live wild outcomes create zero coarse inventory credit",
          session.snapshot().campStock == coarseBefore.campStock
            && session.snapshot().agents.map(\.resourceInventory)
                == coarseBefore.agents.map(\.resourceInventory)
            && !session.localEcologyEnabled)
    check("completed outcomes are bounded non-spendable history",
          session.wildSubsistenceSnapshot().retainedOutcomes.count == 4
            && session.wildSubsistenceSnapshot().retainedOutcomes.allSatisfy {
                $0.outcome.acquiredItems.isEmpty || $0.outcome.custodyFingerprint != nil
            })

    let checkpoint = try! session.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("schema 30 completed history checkpoint is byte exact",
          checkpoint.schemaVersion
            == AgentCheckpointSchema.independentEcologicalReceiptVersion
            && (try! restored.durableStateBytes()) == (try! session.durableStateBytes()))
    let encodedCheckpoint = try! AgentCheckpointCodec.encode(checkpoint)
    let decodedCheckpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: encodedCheckpoint
    )
    let decodedReport = try! AgentSimulationSession.validate(decodedCheckpoint)
    let decodedRestored = try! AgentSimulationSession.restoring(decodedCheckpoint)
    check("multi-strategy wild success counts survive checkpoint codec byte exactly",
          decodedReport.valid
            && decodedRestored.wildSubsistenceSnapshot().successfulCounts
                == session.wildSubsistenceSnapshot().successfulCounts
            && (try! decodedRestored.durableStateBytes())
                == (try! session.durableStateBytes()))

    var replayed = try! AgentSimulationSession.restoring(v13)
    var recorder = try! AgentReplayRecorder(checkpoint: v13, session: replayed)
    _ = try! recorder.apply(.setWildSubsistenceEnabled(true, configuration: .live), to: &replayed)
    _ = try! recorder.apply(.selectWildSubsistenceOpportunity(fishContext), to: &replayed)
    let replayOpportunity = replayed.wildSubsistenceSnapshot().opportunities.last!
    _ = try! recorder.apply(.recordWildSubsistenceOutcome(wildOutcome(
        replayed, opportunity: replayOpportunity, suffix: "replay-fish", item: "cod"
    )), to: &replayed)
    let journal = try! recorder.journal(named: AgentCheckpointName(rawValue: "wild-replay")!)
    let replay = try! AgentSessionReplayer.replay(checkpoint: v13, journal: journal)
    check("schema 30 replay reproduces wild state, causal ledger, skills, and digest",
          replay.report.verified
            && replay.report.schemaVersion
                == AgentReplaySchema.independentEcologicalReceiptVersion
            && (try! replay.session.durableStateBytes()) == (try! replayed.durableStateBytes())
            && replay.session.wildSubsistenceSnapshot().digest == replayed.wildSubsistenceSnapshot().digest)
}
