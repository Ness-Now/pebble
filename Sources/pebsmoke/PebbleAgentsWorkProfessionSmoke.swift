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
}
