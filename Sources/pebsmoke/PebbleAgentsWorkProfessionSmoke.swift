import Foundation
import PebbleAgents

private let workHome = AgentPosition(x: 0, y: 64, z: 0)

private func workAgent(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
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

private func workBase(_ id: String) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, nearbyRadius: 12, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: [workAgent(0), workAgent(1), workAgent(2)],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: workHome,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! session.setLifecycleEnabled(true)
    try! session.setSkillsEnabled(true)
    return session
}

private func workProject(_ session: AgentSimulationSession, id: String) -> AgentConstructionProject {
    try! AgentConstructionProject(
        projectId: id, builderAgentId: "agent_0",
        origin: AgentPosition(x: 2, y: 64, z: -1),
        createdAtTick: session.tick, previousHomePosition: workHome,
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
    try! session.setWorkCommitmentsEnabled(true)
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

private func workWildSession(_ id: String) -> AgentSimulationSession {
    var session = workBase(id)
    try! session.setEcologicalObservationEnabled(true)
    try! session.setWildSubsistenceEnabled(true)
    try! session.setWorkCommitmentsEnabled(true)
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
    try! empty.setWorkCommitmentsEnabled(true)
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
