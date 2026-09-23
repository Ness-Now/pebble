import Foundation
@_spi(Testing) import PebbleAgents

private let workHome = AgentPosition(x: 0, y: 64, z: 0)

private func workResignedCheckpoint(
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
        AgentSessionDurableState.self, from: mutatedBytes
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

private func workRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(checkpoint)
        return false
    } catch {
        return true
    }
}

private func workAgent(
    _ ordinal: Int,
    hunger: Double = 0
) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(hunger: hunger, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "work fixture", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func workBase(
    _ id: String,
    survivalConfiguration: AgentSurvivalConfiguration = .live,
    hungerByAgentID: [String: Double] = [:]
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, nearbyRadius: 12, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survivalConfiguration
        ),
        agents: (0..<3).map { ordinal in
            workAgent(
                ordinal,
                hunger: hungerByAgentID["agent_\(ordinal)"] ?? 0
            )
        },
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: workHome,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! session.setLifecycleEnabled(true)
    try! session.setSkillsEnabled(true)
    try! session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.skillVersion
    )
    return session
}

private func workEnableCommitments(
    _ session: inout AgentSimulationSession,
    configuration: AgentWorkCommitmentConfiguration = .live
) throws {
    try session.setWorkCommitmentsEnabled(true, configuration: configuration)
    try session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.workCommitmentVersion
    )
}

private func workProject(
    _ session: AgentSimulationSession,
    id: String,
    builderAgentID: String = "agent_0"
) -> AgentConstructionProject {
    try! AgentConstructionProject(
        projectId: id, builderAgentId: builderAgentID,
        origin: AgentPosition(x: 2, y: 64, z: -1),
        createdAtTick: session.tick,
        previousHomePosition: try! session.state(for: AgentID(rawValue: builderAgentID)!)
            .homePosition,
        originalFingerprints: AgentBlueprint.fixedLeanToV1.cells.map {
            AgentConstructionCellFingerprint(cellIndex: $0.index, originalFingerprint: 0)
        },
        materialAuthority: .physicalCustody
    )
}

@discardableResult
private func workPlaceNext(
    _ session: inout AgentSimulationSession,
    suffix: String,
    recorder: inout AgentReplayRecorder?
) -> AgentCausalEventID {
    let active = session.snapshot().constructionProject!
    let cell = active.nextCell!
    let intent = AgentPlacementIntent(
        placementId: "work-placement-\(suffix)", projectId: active.projectId,
        builderAgentId: active.builderAgentId, tick: session.tick,
        cellIndex: cell.index, target: active.nextTarget!,
        workPosition: active.nextWorkPosition!, resource: cell.resource
    )
    let update = AgentExternalUpdate(
        agentId: active.builderAgentId, position: intent.workPosition
    )
    if recorder != nil {
        _ = try! recorder!.apply(.externalUpdate(update), to: &session)
    } else {
        try! session.applyExternalUpdate(update)
    }
    let outcome = AgentPlacementOutcome(
        placementId: intent.placementId, projectId: intent.projectId,
        builderAgentId: intent.builderAgentId, tick: intent.tick,
        cellIndex: intent.cellIndex, target: intent.target, resource: intent.resource,
        status: .succeeded, reason: "verified real placement"
    )
    if recorder != nil {
        _ = try! recorder!.apply(.applyPlacementOutcome(outcome), to: &session)
    } else {
        try! session.applyPlacementOutcome(outcome)
    }
    return session.causalLedgerSnapshot().events.last {
        $0.kind == .constructionPlacement
            && $0.operationID?.rawValue == outcome.placementId
    }!.eventID
}

private func workContexts(
    unavailableAgent0: Bool = false
) -> [AgentWorkCandidateContext] {
    [
        AgentWorkCandidateContext(
            agentID: AgentID(rawValue: "agent_0")!,
            physicallyAvailable: !unavailableAgent0,
            toolsAvailable: !unavailableAgent0,
            distance: 2
        ),
        AgentWorkCandidateContext(
            agentID: AgentID(rawValue: "agent_1")!, distance: 2
        ),
        AgentWorkCandidateContext(
            agentID: AgentID(rawValue: "agent_2")!, distance: 2
        ),
    ]
}

private func preparedWorkSession(_ id: String) -> AgentSimulationSession {
    var session = workBase(id)
    try! session.createConstructionProject(workProject(session, id: "shelter-\(id)"))
    try! session.setBuildAutoEnabled(true)
    var recorder: AgentReplayRecorder?
    _ = workPlaceNext(&session, suffix: "practice", recorder: &recorder)
    _ = try! session.advanceTick()
    try! workEnableCommitments(&session)
    _ = try! session.applyWorkCommitmentOperation(.refreshDemands)
    return session
}

private func workWildObservation(
    _ session: AgentSimulationSession,
    actor: AgentID,
    strategy: AgentSubsistenceStrategy
) -> AgentEcologicalObservation {
    let origin = AgentPosition(
        x: Int(actor.rawValue.split(separator: "_").last!)!, y: 64, z: 0
    )
    let fishing = strategy == .fishing ? [AgentFishingAffordance(
        position: AgentPosition(x: origin.x + 1, y: 63, z: 0),
        waterKey: "water", candidate: true
    )] : []
    let animals = strategy == .hunting ? [AgentAnimalObservation(
        speciesKey: "chicken", position: AgentPosition(x: origin.x + 1, y: 64, z: 0),
        count: 1, lifeStage: .adult, breedableAffordanceObservable: false
    )] : []
    let plants = strategy == .wildGathering ? [AgentPlantObservation(
        plantKey: "sweet_berry_bush",
        position: AgentPosition(x: origin.x + 1, y: 64, z: 0),
        renewability: .knownRenewable
    )] : []
    let configuration = session.ecologicalObservationSnapshot().configuration!
    return AgentEcologicalObservation(
        observerID: actor, origin: origin, worldContextKey: "world-seed-46",
        dimensionKey: "overworld", observedAtSimulationTick: session.tick,
        physicalWorldTick: session.tick + 120, civilDate: session.civilDate()!,
        biome: AgentBiomeObservation(biomeKey: "plains", position: origin),
        water: fishing.map {
            AgentWaterAffordance(
                fluidKey: "water", position: $0.position, sourceBlock: true
            )
        },
        soils: [], crops: [], plants: plants, animals: animals, fishing: fishing,
        weather: AgentWeatherObservation(kind: .clear, raining: false, thundering: false),
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: session.tick + 120, dayTime: 120, timeOfDay: .day,
            daylightCycleEnabled: true
        ),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: 4, cellsConsidered: 405, worldReads: 405, chunksTouched: 1,
            chunksUnavailable: 0, entitiesConsidered: animals.count,
            resultsEmitted: 3 + fishing.count * 2 + plants.count + animals.count,
            cacheHits: 0, cacheMisses: 1, completion: .complete
        ),
        expiresAtSimulationTick: session.tick + configuration.dynamicFreshnessTicks
    )
}

private func workWildSession(
    _ id: String,
    survivalConfiguration: AgentSurvivalConfiguration = .live,
    hungerByAgentID: [String: Double] = [:]
) -> AgentSimulationSession {
    var session = workBase(
        id,
        survivalConfiguration: survivalConfiguration,
        hungerByAgentID: hungerByAgentID
    )
    try! session.setEcologicalObservationEnabled(true)
    try! session.setWildSubsistenceEnabled(true)
    try! workEnableCommitments(&session)
    try! session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.independentEcologicalReceiptVersion
    )
    return session
}

@discardableResult
private func performCommittedWildWork(
    _ session: inout AgentSimulationSession,
    actor: AgentID,
    strategy: AgentSubsistenceStrategy,
    ordinal: Int
) -> AgentWorkCommitment {
    _ = try! session.recordEcologicalObservation(
        workWildObservation(session, actor: actor, strategy: strategy)
    )
    let context = AgentSubsistenceDecisionContext(
        actorID: actor,
        fishingRodAvailable: strategy == .fishing,
        huntingWeaponAvailable: strategy == .hunting,
        agricultureAvailable: false, subsistencePressure: 80
    )
    let opportunity = try! session.selectWildSubsistenceOpportunity(context)
    try! session.applyWorkCommitmentOperation(.refreshDemands)
    let demand = session.activeWorkDemands().first {
        $0.source == .wildSubsistence
            && $0.sourceKey == opportunity.opportunityID.rawValue
    }!
    let commitment = try! session.applyWorkCommitmentOperation(.start(
        demandID: demand.demandID,
        candidates: [AgentWorkCandidateContext(
            agentID: actor, toolsAvailable: true, resourcesAvailable: true, distance: 1
        )]
    ))!
    let acquiredKey: String
    switch strategy {
    case .fishing: acquiredKey = "cod"
    case .hunting: acquiredKey = "chicken"
    case .wildGathering: acquiredKey = "sweet_berries"
    case .agriculture: acquiredKey = "wheat"
    }
    let physicalStack = AgentMaterialStackSnapshot(
        identity: AgentMaterialIdentitySnapshot(
            itemKey: acquiredKey, damage: 0, enchantments: [], label: nil,
            canonicalDataJSON: "{}"
        ), count: 1
    )
    let outcome = AgentSubsistenceOutcome(
        attemptID: AgentSubsistenceAttemptID(
            rawValue: "wild-attempt-work-\(ordinal)-\(actor.rawValue)"
        )!,
        opportunityID: opportunity.opportunityID, actorID: actor,
        strategy: strategy, targetKey: opportunity.targetKey,
        targetPosition: opportunity.lastObservedPosition,
        sourceObservationEventID: opportunity.sourceObservationEventID,
        status: .succeeded, physicalCausalIDs: [10_000 + ordinal],
        acquiredItems: [physicalStack], custodyFingerprint: "custody-work-\(ordinal)",
        attribution: "core-physical-work-\(ordinal)", completedAtTick: session.tick
    )
    let record = try! session.recordWildSubsistenceOutcome(outcome)
    _ = try! session.applyWorkCommitmentOperation(.recordOutcome(
        AgentValidatedWorkOutcome(
            commitmentID: commitment.commitmentID, workerID: actor,
            domain: demand.domain, sourceSuccessEventID: record.subsistenceEventID,
            status: .succeeded, observerIDs: [actor]
        )
    ))
    _ = try! session.advanceTick()
    return commitment
}

func runPebbleAgentsWorkProfessionSmoke() {
    section("pebble agents durable work commitments")

    var empty = workBase("work-empty")
    check("work commitments default off", !empty.workCommitmentsEnabled)
    let oldCheckpoint = try! empty.makeCheckpoint()
    check("pre-CIV-25 checkpoint remains v10", oldCheckpoint.schemaVersion == 10)
    try! workEnableCommitments(&empty)
    check("work activation is explicit v16 without retrocredit",
          empty.workCommitmentSnapshot().enabled
            && empty.workCommitmentSnapshot().demands.isEmpty
            && empty.workCommitmentSnapshot().evidence.isEmpty
            && (try! empty.makeCheckpoint()).schemaVersion == 16)
    _ = try! empty.applyWorkCommitmentOperation(.refreshDemands)
    check("no source demand creates no commitment",
          empty.activeWorkDemands().isEmpty
            && empty.activeWorkCommitments().isEmpty)
    let oldRestored = try! AgentSimulationSession.restoring(oldCheckpoint)
    check("v10 restores with CIV-25 empty and off",
          !oldRestored.workCommitmentsEnabled
            && oldRestored.workCommitmentSnapshot().commitments.isEmpty)

    var session = preparedWorkSession("work-main")
    let demand = session.activeWorkDemands().first!
    check("construction projects derive bounded real demand",
          demand.source == .construction && demand.domain == .construction
            && demand.sourceEventID.simulationID == session.simulationID)
    let score0 = session.matchingScore(
        for: demand.demandID, candidate: workContexts()[0]
    )!
    let score1 = session.matchingScore(
        for: demand.demandID, candidate: workContexts()[1]
    )!
    check("matching score exposes skill and continuity independently",
          score0.skillAndPractice > score1.skillAndPractice
            && score0.continuity > score1.continuity
            && score0.total > score1.total)
    let commitment = try! session.applyWorkCommitmentOperation(
        .start(demandID: demand.demandID, candidates: workContexts())
    )!
    check("matching starts one durable responsibility",
          commitment.workerID.rawValue == "agent_0"
            && commitment.status == .active
            && commitment.expiresAtTick > commitment.reviewAtTick)
    let renewed = try! session.applyWorkCommitmentOperation(
        .renew(commitmentID: commitment.commitmentID)
    )!
    check("commitment renewal preserves identity and cadence",
          renewed.commitmentID == commitment.commitmentID
            && renewed.status == .active)
    var noRecorder: AgentReplayRecorder?
    let source = workPlaceNext(&session, suffix: "committed", recorder: &noRecorder)
    let workOutcome = AgentValidatedWorkOutcome(
        commitmentID: commitment.commitmentID,
        workerID: commitment.workerID, domain: .construction,
        sourceSuccessEventID: source, status: .succeeded,
        observerIDs: [AgentID(rawValue: "agent_0")!, AgentID(rawValue: "agent_1")!]
    )
    _ = try! session.applyWorkCommitmentOperation(.recordOutcome(workOutcome))
    let finished = session.workCommitmentSnapshot()
    check("real source is normalized once and fulfills responsibility",
          finished.evidence.count == 1
            && finished.commitments.first?.status == .fulfilled
            && finished.demands.first?.status == .fulfilled)
    check("work reputation is local and distinct from trust",
          session.localWorkReputation(
            observerID: AgentID(rawValue: "agent_0")!,
            workerID: commitment.workerID, domain: .construction
          )?.score == 10
            && session.localWorkReputation(
                observerID: AgentID(rawValue: "agent_1")!,
                workerID: commitment.workerID, domain: .construction
            )?.score == 10
            && session.localWorkReputation(
                observerID: AgentID(rawValue: "agent_2")!,
                workerID: commitment.workerID, domain: .construction
            ) == nil
            && session.trustScore(sourceAgentId: "agent_0", targetAgentId: "agent_0") == 0)
    let committedBytes = try! session.durableStateBytes()
    check("one physical source can never create two work credits", {
        do {
            _ = try session.applyWorkCommitmentOperation(.recordOutcome(workOutcome))
            return false
        } catch AgentSessionError.workCommitment(.duplicateSourceEvent) {
            return (try! session.durableStateBytes()) == committedBytes
        } catch { return false }
    }())
    let checkpoint = try! session.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("v16 checkpoint restores byte-identical work state",
          checkpoint.schemaVersion == 16
            && restored.workCommitmentSnapshot() == session.workCommitmentSnapshot()
            && (try! restored.durableStateBytes()) == (try! session.durableStateBytes()))

    var crisis = preparedWorkSession("work-crisis")
    let crisisDemand = crisis.activeWorkDemands().first!
    let original = try! crisis.applyWorkCommitmentOperation(
        .start(demandID: crisisDemand.demandID, candidates: workContexts())
    )!
    let suspended = try! crisis.applyWorkCommitmentOperation(
        .suspend(commitmentID: original.commitmentID, reason: .crisis)
    )!
    let replacement = try! crisis.applyWorkCommitmentOperation(
        .replace(commitmentID: suspended.commitmentID, candidates: workContexts())
    )!
    check("crisis suspension permits deterministic replacement",
          replacement.workerID.rawValue == "agent_1"
            && crisis.workCommitmentSnapshot().totalReassignmentCount == 1
            && crisis.workCommitmentSnapshot().commitments.first?.status == .reassigned)
    check("unprofiled capable replacement remains eligible",
          crisis.practiceUnits(agentID: replacement.workerID, domain: .construction) == 0
            && replacement.status == .active)

    var expiration = preparedWorkSession("work-expiration")
    let expiringDemand = expiration.activeWorkDemands().first!
    let expiring = try! expiration.applyWorkCommitmentOperation(
        .start(demandID: expiringDemand.demandID, candidates: workContexts())
    )!
    for _ in 0...expiration.workCommitmentSnapshot().configuration!.commitmentLifetimeTicks {
        _ = try! expiration.advanceTick()
    }
    _ = try! expiration.applyWorkCommitmentOperation(.review)
    check("unfulfilled durable responsibility expires after its bounded lifetime",
          expiration.workCommitmentSnapshot().commitments.first {
              $0.commitmentID == expiring.commitmentID
          }?.status == .expired)

    var contextualTrust = workBase("work-contextual-trust")
    try! contextualTrust.setSocialEnabled(true)
    let trustBelief = socialSmokeDirectMessage(
        session: &contextualTrust, fingerprint: 25_001,
        observerX: 0, observerID: "agent_0"
    )
    _ = socialSmokeVerify(
        session: &contextualTrust, belief: trustBelief,
        fingerprint: 25_001, resource: .wood
    )
    try! contextualTrust.createConstructionProject(workProject(
        contextualTrust, id: "trust-shelter", builderAgentID: "agent_1"
    ))
    try! contextualTrust.setBuildAutoEnabled(true)
    var trustPreparationRecorder: AgentReplayRecorder?
    _ = workPlaceNext(
        &contextualTrust, suffix: "trust-practice", recorder: &trustPreparationRecorder
    )
    _ = try! contextualTrust.advanceTick()
    try! workEnableCommitments(&contextualTrust)
    _ = try! contextualTrust.applyWorkCommitmentOperation(.refreshDemands)
    let trustDemand = contextualTrust.activeWorkDemands().first!
    let trustedScore = contextualTrust.matchingScore(
        for: trustDemand.demandID, candidate: workContexts()[0]
    )!
    let neutralScore = contextualTrust.matchingScore(
        for: trustDemand.demandID, candidate: workContexts()[2]
    )!
    check("requester-local trust breaks an otherwise equal work match",
          contextualTrust.trustScore(
              sourceAgentId: trustDemand.observerID.rawValue,
              targetAgentId: "agent_0"
          ) > 0
            && trustedScore.trust > neutralScore.trust
            && trustedScore.total > neutralScore.total)

    var carePreemption = careBase("work-care-preemption")
    try! carePreemption.setSkillsEnabled(true)
    try! carePreemption.createConstructionProject(
        workProject(carePreemption, id: "care-preemption-shelter")
    )
    try! carePreemption.setBuildAutoEnabled(true)
    var carePreparationRecorder: AgentReplayRecorder?
    _ = workPlaceNext(
        &carePreemption, suffix: "care-practice", recorder: &carePreparationRecorder
    )
    _ = try! carePreemption.advanceTick()
    try! workEnableCommitments(&carePreemption)
    _ = try! carePreemption.applyWorkCommitmentOperation(.refreshDemands)
    let productiveDemand = carePreemption.activeWorkDemands().first!
    let productive = try! carePreemption.applyWorkCommitmentOperation(.start(
        demandID: productiveDemand.demandID, candidates: workContexts()
    ))!
    try! carePreemption.setReproductionEnabled(true)
    try! carePreemption.setDependentCareEnabled(
        true,
        configuration: try! AgentDependentCareConfiguration(
            nourishmentHungerThreshold: 0.05
        )
    )
    var careRecorder = try! AgentReplayRecorder(
        checkpoint: try! carePreemption.makeCheckpoint(), session: carePreemption
    )
    let dependent = careBirth(
        &careRecorder, &carePreemption,
        position: AgentPosition(x: 0, y: 64, z: 2), candidateIndex: 0
    )
    for _ in 0..<8 where carePreemption.careTarget(for: productive.workerID) == nil {
        _ = try! careRecorder.apply(
            .advanceTick(perceptions: [], physicalObservations: []),
            to: &carePreemption
        )
    }
    let assignedCare = try! carePreemption.currentCareAssignment(for: dependent.newbornID)
    _ = try! carePreemption.applyWorkCommitmentOperation(.review)
    let careSuspended = carePreemption.workCommitmentSnapshot().commitments.first {
        $0.commitmentID == productive.commitmentID
    }
    let careReplacement = try! carePreemption.applyWorkCommitmentOperation(.replace(
        commitmentID: productive.commitmentID, candidates: workContexts()
    ))!
    check("critical dependent care suspends productive work and permits replacement",
          assignedCare?.caregiverID == productive.workerID
            && careSuspended?.status == .suspended
            && careSuspended?.suspensionReason == .dependentCare
            && careReplacement.workerID != productive.workerID)

    var replay = workBase("work-replay")
    try! replay.createConstructionProject(workProject(replay, id: "replay-shelter"))
    try! replay.setBuildAutoEnabled(true)
    var replayPreparationRecorder: AgentReplayRecorder?
    _ = workPlaceNext(
        &replay, suffix: "replay-practice", recorder: &replayPreparationRecorder
    )
    _ = try! replay.advanceTick()
    let base = try! replay.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(checkpoint: base, session: replay)
    _ = try! recorder.apply(
        .setWorkCommitmentsEnabled(true, configuration: .live), to: &replay
    )
    _ = try! recorder.apply(
        .applyWorkCommitmentOperation(.refreshDemands), to: &replay
    )
    let replayDemand = replay.activeWorkDemands().first!
    _ = try! recorder.apply(
        .applyWorkCommitmentOperation(
            .start(demandID: replayDemand.demandID, candidates: workContexts())
        ), to: &replay
    )
    let replayCommitment = replay.activeWorkCommitments().first!
    var recorderOptional: AgentReplayRecorder? = recorder
    let replaySource = workPlaceNext(
        &replay, suffix: "replay", recorder: &recorderOptional
    )
    recorder = recorderOptional!
    _ = try! recorder.apply(
        .applyWorkCommitmentOperation(.recordOutcome(AgentValidatedWorkOutcome(
            commitmentID: replayCommitment.commitmentID,
            workerID: replayCommitment.workerID, domain: .construction,
            sourceSuccessEventID: replaySource, status: .succeeded,
            observerIDs: [AgentID(rawValue: "agent_0")!]
        ))), to: &replay
    )
    let journal = try! recorder.journal(named: AgentCheckpointName(rawValue: "work-v16")!)
    let replayed = try! AgentSessionReplayer.replay(checkpoint: base, journal: journal)
    check("v16 activation and work transitions replay deterministically",
          replayed.report.verified
            && replayed.report.schemaVersion == 16
            && replayed.session.workCommitmentSnapshot() == replay.workCommitmentSnapshot()
            && (try! replayed.session.durableStateBytes()) == (try! replay.durableStateBytes()))

    var specialization = workWildSession("work-specialization")
    let agents = (0..<3).map { AgentID(rawValue: "agent_\($0)")! }
    let domains: [AgentSubsistenceStrategy] = [.fishing, .hunting, .wildGathering]
    var ordinal = 0
    for (agent, strategy) in zip(agents, domains) {
        for _ in 0..<2 {
            _ = performCommittedWildWork(
                &specialization, actor: agent, strategy: strategy, ordinal: ordinal
            )
            ordinal += 1
        }
    }
    let profiles = specialization.professionProfiles()
    check("three agents derive three different profiles without assignment",
          profiles.count == 3
            && profiles.map(\.primaryWorkDomain) == [.fishing, .hunting, .foraging]
            && profiles.allSatisfy {
                $0.specializationStrengthBasisPoints == 10_000
                    && $0.commitmentContinuity == 2
            })
    check("snapshot exposes bounded profiles and specialization components",
          specialization.workCommitmentSnapshot().professionProfiles == profiles
            && specialization.workCommitmentSnapshot().specializationMetrics.count == 3
            && specialization.workCommitmentSnapshot().configuration != nil)
    check("derived profiles add no physical yield multiplier",
          specialization.wildSubsistenceSnapshot().retainedOutcomes.allSatisfy {
              $0.outcome.acquiredQuantity == 1
          })
    _ = try! specialization.recordEcologicalObservation(
        workWildObservation(
            specialization, actor: agents[0], strategy: .fishing
        )
    )
    let permissionOpportunity = try! specialization.selectWildSubsistenceOpportunity(
        AgentSubsistenceDecisionContext(
            actorID: agents[0], fishingRodAvailable: true,
            huntingWeaponAvailable: false, agricultureAvailable: false,
            subsistencePressure: 90
        )
    )
    _ = try! specialization.applyWorkCommitmentOperation(.refreshDemands)
    let permissionDemand = specialization.activeWorkDemands().first {
        $0.sourceKey == permissionOpportunity.opportunityID.rawValue
    }!
    check("a strong profile grants no physical tool permission",
          specialization.matchingScore(
            for: permissionDemand.demandID,
            candidate: AgentWorkCandidateContext(
                agentID: agents[0], toolsAvailable: false, distance: 1
            )
          ) == nil)
    let crossDomainWorker = try! specialization.applyWorkCommitmentOperation(.start(
        demandID: permissionDemand.demandID,
        candidates: [AgentWorkCandidateContext(agentID: agents[1], distance: 1)]
    ))!
    check("a worker without the matching profile remains eligible",
          profiles.first { $0.agentID == crossDomainWorker.workerID }?.primaryWorkDomain
            == .hunting && crossDomainWorker.domain == .fishing)

    var dependency = workWildSession("work-dependency")
    let dependentActor = agents[0]
    _ = try! dependency.recordEcologicalObservation(
        workWildObservation(dependency, actor: dependentActor, strategy: .fishing)
    )
    let dependencyOpportunity = try! dependency.selectWildSubsistenceOpportunity(
        AgentSubsistenceDecisionContext(
            actorID: dependentActor, fishingRodAvailable: true,
            huntingWeaponAvailable: false, agricultureAvailable: false,
            subsistencePressure: 90
        )
    )
    _ = try! dependency.applyWorkCommitmentOperation(.refreshDemands)
    let dependencyDemand = dependency.activeWorkDemands().first {
        $0.sourceKey == dependencyOpportunity.opportunityID.rawValue
    }!
    _ = try! dependency.applyWorkCommitmentOperation(.start(
        demandID: dependencyDemand.demandID,
        candidates: [AgentWorkCandidateContext(agentID: dependentActor, distance: 1)]
    ))
    let dependencyMetric = dependency.workDependencyMetrics().first!
    check("dependency components expose single worker and replacement depth",
          dependencyMetric.domain == .fishing
            && dependencyMetric.committedWorkerIDs == [dependentActor]
            && dependencyMetric.singleWorkerDependency
            && dependencyMetric.knownCapableWorkerCount == 3
            && dependencyMetric.replacementDepth == 2)
    check("coordination metrics expose covered recurring demand",
          dependency.workCoordinationMetrics().coveredDemandCount == 1
            && dependency.workCoordinationMetrics().uncoveredDemandCount == 0)
    var reconversion = workWildSession("work-reconversion")
    for index in 0..<3 {
        _ = performCommittedWildWork(
            &reconversion, actor: agents[0], strategy: .fishing, ordinal: index
        )
    }
    let fishingProfile = reconversion.professionProfile(for: agents[0])!
    _ = performCommittedWildWork(
        &reconversion, actor: agents[0], strategy: .wildGathering, ordinal: 20
    )
    let oneNewAction = reconversion.professionProfile(for: agents[0])!
    for index in 21...23 {
        _ = performCommittedWildWork(
            &reconversion, actor: agents[0], strategy: .wildGathering, ordinal: index
        )
    }
    let converted = reconversion.professionProfile(for: agents[0])!
    check("one different action cannot instantly rewrite a work identity",
          fishingProfile.primaryWorkDomain == .fishing
            && oneNewAction.primaryWorkDomain == .fishing)
    check("repeated changed demand produces reversible reconversion",
          converted.primaryWorkDomain == .foraging
            && converted.secondaryDomains.contains(.fishing)
            && converted.domainActivity.first {
                $0.domain == .fishing
            }?.lifetimeWorkUnits ?? 0 > 0)
    let profileCheckpoint = try! reconversion.makeCheckpoint()
    let profileRestored = try! AgentSimulationSession.restoring(profileCheckpoint)
    check("derived profiles reproduce exactly after v16 restore",
          profileRestored.professionProfiles() == reconversion.professionProfiles()
            && profileRestored.workCommitmentSnapshot().digest
                == reconversion.workCommitmentSnapshot().digest)
}

func runPebbleAgentsTerminalCohortWorkSmoke() {
    let survival = try! AgentSurvivalConfiguration(
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
    let terminalWorker = AgentID(rawValue: "agent_0")!
    let survivingDemandOwner = AgentID(rawValue: "agent_1")!
    var session = workWildSession(
        "ps01-terminal-work-commitments",
        survivalConfiguration: survival,
        hungerByAgentID: [
            terminalWorker.rawValue: 0.39,
            "agent_1": -10,
            "agent_2": -10,
        ]
    )
    let strategies: [AgentSubsistenceStrategy] = [
        .fishing,
        .hunting,
        .wildGathering,
    ]
    for (ordinal, strategy) in strategies.enumerated() {
        _ = try! session.recordEcologicalObservation(
            workWildObservation(
                session,
                actor: survivingDemandOwner,
                strategy: strategy
            )
        )
        let opportunity = try! session.selectWildSubsistenceOpportunity(
            AgentSubsistenceDecisionContext(
                actorID: survivingDemandOwner,
                fishingRodAvailable: strategy == .fishing,
                huntingWeaponAvailable: strategy == .hunting,
                agricultureAvailable: false,
                subsistencePressure: 90
            )
        )
        _ = try! session.applyWorkCommitmentOperation(.refreshDemands)
        let demand = session.activeWorkDemands().first {
            $0.source == .wildSubsistence
                && $0.sourceKey == opportunity.opportunityID.rawValue
        }!
        _ = try! session.applyWorkCommitmentOperation(.start(
            demandID: demand.demandID,
            candidates: [AgentWorkCandidateContext(
                agentID: terminalWorker,
                toolsAvailable: true,
                resourcesAvailable: true,
                distance: 1
            )]
        ))
        // The selected opportunity is only a real demand source for this
        // work fixture. Close that source explicitly while leaving the
        // separately owned durable commitment open for the mortality attack.
        _ = try! session.recordWildSubsistenceOutcome(
            AgentSubsistenceOutcome(
                attemptID: AgentSubsistenceAttemptID(
                    rawValue: "wild-attempt-terminal-work-\(ordinal)"
                )!,
                opportunityID: opportunity.opportunityID,
                actorID: survivingDemandOwner,
                strategy: opportunity.strategy,
                targetKey: opportunity.targetKey,
                targetPosition: opportunity.lastObservedPosition,
                sourceObservationEventID:
                    opportunity.sourceObservationEventID,
                status: .failed,
                completedAtTick: session.tick
            )
        )
    }
    _ = try! session.applyWorkCommitmentOperation(.refreshDemands)
    check("terminal worker holds the real per-agent commitment maximum",
          session.activeWorkCommitments(for: terminalWorker).count
            == session.workCommitmentSnapshot().configuration?
                .maximumConcurrentCommitmentsPerAgent)

    session.setSurvivalEnabled(true)
    try! session.setMortalityEnabled(
        true,
        configuration: .embodiedPopulationBounded(
            maximumActivePopulation: 8
        )
    )
    try! session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.independentEcologicalReceiptVersion
    )
    let result = try! session.advanceTick()
    let pending = session.pendingMortalityTransitions()
    check("multi-commitment worker enters terminal barrier before new work",
          result.agents.isEmpty
            && pending.map(\.agentID) == [terminalWorker]
            && session.activeWorkCommitments(for: terminalWorker).count == 3)
    let transition = pending[0]
    _ = try! session.applyMortalityPhysicalCustodyOutcome(
        AgentMortalityPhysicalCustodyOutcome(
            operationID: "ps01-work-empty-" + terminalWorker.rawValue,
            terminalAgentID: terminalWorker,
            kind: .verifiedEmpty,
            physicalReceiptID: "ps01-work-empty-receipt",
            destinationHolderID: nil,
            stackCount: 0,
            itemCount: 0,
            verifiedAtTick: session.tick
        )
    )
    _ = try! session.finalizePendingMortality(for: terminalWorker)
    let work = session.workCommitmentSnapshot()
    let ended = work.commitments.filter {
        $0.workerID == terminalWorker && $0.status == .ended
    }
    check("all terminal work commitments close once with causal evidence",
          ended.count == 3
            && ended.allSatisfy {
                $0.terminalTick == transition.detectedAtTick
                    && $0.terminalEventID != nil
            }
            && session.activeWorkCommitments(for: terminalWorker).isEmpty
            && session.causalLedgerSnapshot().events.filter {
                $0.kind == .workCommitmentEnded
                    && $0.actorID == terminalWorker
                    && $0.summary.contains("reason=workerDied")
            }.count == 3
            && session.mortalitySnapshot().totalDeathCount == 1)
    let restored = try! AgentSimulationSession.restoring(
        session.makeCheckpoint()
    )
    check("terminal work cleanup restores without commitment resurrection",
          restored.activeWorkCommitments(for: terminalWorker).isEmpty
            && restored.workCommitmentSnapshot().commitments.filter {
                $0.workerID == terminalWorker && $0.status == .ended
            }.count == 3
            && restored.mortalitySnapshot().totalDeathCount == 1)

    let terminalCheckpoint = try! session.makeCheckpoint()
    let reopenedDeadCommitment = workResignedCheckpoint(
        terminalCheckpoint
    ) { durable in
        var work = durable["workCommitmentState"] as! [String: Any]
        var commitments = work["commitments"] as! [[String: Any]]
        let index = commitments.firstIndex {
            $0["workerID"] as? String == terminalWorker.rawValue
        }!
        commitments[index]["status"] = "active"
        work["commitments"] = commitments
        durable["workCommitmentState"] = work
    }
    check("active commitment to deceased worker is refused",
          workRestoreRefused(reopenedDeadCommitment))

    let provenanceFreeEndedCommitment = workResignedCheckpoint(
        terminalCheckpoint
    ) { durable in
        var work = durable["workCommitmentState"] as! [String: Any]
        var commitments = work["commitments"] as! [[String: Any]]
        let index = commitments.firstIndex {
            $0["workerID"] as? String == terminalWorker.rawValue
        }!
        commitments[index].removeValue(forKey: "terminalEventID")
        work["commitments"] = commitments
        durable["workCommitmentState"] = work
    }
    check("ended dead-worker commitment without terminal provenance is refused",
          workRestoreRefused(provenanceFreeEndedCommitment))
}
