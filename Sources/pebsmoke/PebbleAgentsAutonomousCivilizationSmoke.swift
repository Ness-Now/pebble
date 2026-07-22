import Foundation
import PebbleAgents

private func autonomousAgent(_ id: String, x: Int, hunger: Double = 0) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(hunger: hunger, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(kind: .idle, reason: "fixture", startedAtTick: 0, urgency: 0),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func autonomousSession(_ id: String) -> AgentSimulationSession {
    try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: [autonomousAgent("agent_0", x: 0), autonomousAgent("agent_1", x: 4)],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
}

private func hungryAutonomousSession(_ id: String) -> AgentSimulationSession {
    try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: [autonomousAgent("agent_0", x: 0, hunger: 0.9)],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
}

private func autonomousCandidate(
    id: String,
    actor: String = "agent_0",
    domain: AgentAutonomousActivityDomain = .agriculture,
    source: AgentAutonomousActivitySource = .opportunity,
    band: Int = 30,
    urgency: Int = 60,
    distance: Int = 1,
    tick: Int = 0
) -> AgentAutonomousActivityCandidate {
    AgentAutonomousActivityCandidate(
        candidateID: id, actorID: AgentID(rawValue: actor)!, domain: domain,
        actionKey: "work", stableReference: "stable-\(id)",
        target: AgentPosition(x: distance, y: 64, z: 0), source: source,
        priorityBand: band, urgency: urgency, distance: distance,
        observedAtTick: tick
    )
}

func runPebbleAgentsAutonomousCivilizationSmoke() {
    section("PebbleAgents autonomous Civilization orchestration")

    var session = autonomousSession("autonomous-selection")
    try! session.setAutonomousActivityEnabled(true)
    let agriculture = autonomousCandidate(id: "agriculture", urgency: 90)
    let care = autonomousCandidate(
        id: "care", domain: .dependentCare, source: .responsibility,
        band: 0, urgency: 100
    )
    let selected = try! session.selectAutonomousActivities([agriculture, care])
    check("autonomy selects one physical intent per actor", selected.count == 1)
    check("explicit band gives urgent care precedence", selected.first?.candidate.candidateID == "care")
    check("selected lifecycle is bounded and ready", selected.first?.lifecycle == .ready)
    check("selection counters retain candidate evidence", session.autonomousActivitySnapshot().counters.candidateCount == 2)

    var hungerPriority = hungryAutonomousSession("autonomous-hunger")
    hungerPriority.setSurvivalEnabled(true)
    try! hungerPriority.setAutonomousActivityEnabled(true)
    _ = try! hungerPriority.selectAutonomousActivities([
        autonomousCandidate(id: "ordinary-work", urgency: 100)
    ])
    let hungerTick = try! hungerPriority.advanceTick()
    check("critical hunger preempts ordinary activity", hungerTick.agents[0].snapshot.currentGoal.kind == .satisfyHunger)

    var commitmentPriority = autonomousSession("autonomous-commitment")
    try! commitmentPriority.setAutonomousActivityEnabled(true)
    let committed = autonomousCandidate(
        id: "committed", source: .commitment, band: 20, urgency: 60
    )
    let exploration = autonomousCandidate(id: "exploration", band: 35, urgency: 100)
    let commitmentSelection = try! commitmentPriority.selectAutonomousActivities([
        exploration, committed,
    ])
    check("valid commitment outranks arbitrary exploration", commitmentSelection[0].candidate.candidateID == "committed")

    var multiAgent = autonomousSession("autonomous-multi-agent")
    try! multiAgent.setAutonomousActivityEnabled(true)
    let multiSelection = try! multiAgent.selectAutonomousActivities([
        autonomousCandidate(id: "gather", actor: "agent_0", domain: .wildGathering),
        autonomousCandidate(id: "livestock", actor: "agent_1", domain: .livestock),
    ])
    check("different agents select different valid activities", multiSelection.count == 2 && Set(multiSelection.map { $0.candidate.domain }) == [.wildGathering, .livestock])

    var orderingA = autonomousSession("autonomous-ordering")
    var orderingB = autonomousSession("autonomous-ordering")
    try! orderingA.setAutonomousActivityEnabled(true)
    try! orderingB.setAutonomousActivityEnabled(true)
    let tieA = autonomousCandidate(id: "a", urgency: 70)
    let tieB = autonomousCandidate(id: "b", urgency: 70)
    let firstOrdering = try! orderingA.selectAutonomousActivities([tieB, tieA])
    let secondOrdering = try! orderingB.selectAutonomousActivities([tieA, tieB])
    check("input order does not affect deterministic arbitration", firstOrdering == secondOrdering)
    check("same seed and semantic input produce exact state", try! orderingA.durableStateBytes() == orderingB.durableStateBytes())

    var replanning = autonomousSession("autonomous-replan")
    let replanConfiguration = try! AgentAutonomousActivityConfiguration(
        maximumCandidatesPerDecision: 2, maximumActiveActivities: 2,
        maximumRetainedRecords: 4, maximumCooldowns: 2, blockedCooldownTicks: 4
    )
    try! replanning.setAutonomousActivityEnabled(true, configuration: replanConfiguration)
    let blockedCandidate = autonomousCandidate(id: "missing-tool")
    let blockedActivity = try! replanning.selectAutonomousActivities([blockedCandidate])[0]
    _ = try! replanning.recordAutonomousActivityOutcome(AgentAutonomousActivityOutcome(
        activityID: blockedActivity.activityID, actorID: blockedActivity.candidate.actorID,
        lifecycle: .blocked, completedAtTick: replanning.tick,
        reason: "real tool missing"
    ))
    check("blocked physical prerequisite is recorded", replanning.autonomousActivitySnapshot().counters.blockCount == 1)
    check("blocked candidate enters bounded cooldown", replanning.autonomousActivitySnapshot().cooldowns.count == 1)
    check("blocked activity is not retried every tick", try! replanning.selectAutonomousActivities([blockedCandidate]).isEmpty)
    let alternative = try! replanning.selectAutonomousActivities([
        autonomousCandidate(id: "valid-alternative", domain: .wildGathering)
    ])
    check("new eligible activity can replan during cooldown", alternative.first?.candidate.candidateID == "valid-alternative")
    _ = try! replanning.recordAutonomousActivityOutcome(AgentAutonomousActivityOutcome(
        activityID: alternative[0].activityID, actorID: alternative[0].candidate.actorID,
        lifecycle: .completed, completedAtTick: replanning.tick,
        reason: "validated physical alternative"
    ))
    let chained = try! replanning.selectAutonomousActivities([
        autonomousCandidate(id: "next-decision", domain: .livestock)
    ])
    check("completed outcome permits a new normal decision", chained.first?.candidate.candidateID == "next-decision")

    let longID = String(repeating: "x", count: 200)
    var boundedIdentity = autonomousSession("autonomous-id-bound")
    try! boundedIdentity.setAutonomousActivityEnabled(true)
    let boundedIDActivity = try! boundedIdentity.selectAutonomousActivities([
        autonomousCandidate(id: longID)
    ])[0]
    check("durable activity identity is explicitly bounded", boundedIDActivity.activityID.count == 160)

    let beforeLimit = try! replanning.durableStateDigest()
    let tooManyRejected = (try? replanning.selectAutonomousActivities([
        autonomousCandidate(id: "limit-0", actor: "agent_0"),
        autonomousCandidate(id: "limit-1", actor: "agent_1"),
        autonomousCandidate(id: "limit-2", actor: "agent_0"),
    ])) == nil
    check("candidate budget fails closed", tooManyRejected)
    check("candidate budget rejection is transactional", try! replanning.durableStateDigest() == beforeLimit)

    let tick = try! session.advanceTick()
    check("existing cognition owns activity goal", tick.agents.first { $0.agentId == "agent_0" }?.snapshot.currentGoal.kind == .civilizationActivity)
    check("existing action decider publishes activity action", tick.agents.first { $0.agentId == "agent_0" }?.action.name == "execute_autonomous_activity")

    var navigation = autonomousSession("autonomous-navigation")
    try! navigation.setAutonomousActivityEnabled(true)
    _ = try! navigation.selectAutonomousActivities([
        autonomousCandidate(id: "route", distance: 3)
    ])
    let routeTick = try! navigation.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_0",
            navigationObservation: AgentNavigationObservation(
                worldTick: 0,
                origin: AgentPosition(x: 0, y: 64, z: 0),
                target: AgentPosition(x: 3, y: 64, z: 0),
                cells: [
                    AgentNavigationCell(
                        position: AgentPosition(x: 0, y: 64, z: 0),
                        status: .traversable
                    ),
                    AgentNavigationCell(
                        position: AgentPosition(x: 1, y: 64, z: 0),
                        status: .traversable
                    ),
                    AgentNavigationCell(
                        position: AgentPosition(x: 2, y: 64, z: 0),
                        status: .traversable
                    ),
                    AgentNavigationCell(
                        position: AgentPosition(x: 3, y: 64, z: 0),
                        status: .blocked
                    ),
                ]
            )
        )
    ])
    let routed = routeTick.agents.first { $0.agentId == "agent_0" }!
    check("civilization activity reuses bounded navigation", routed.snapshot.navigationProgress.route?.purpose == .civilizationActivity)
    check("bounded activity route publishes a physical step", routed.action.name == "approach_activity" && routed.action.dx == 1)

    let activity = session.activeAutonomousActivity(for: AgentID(rawValue: "agent_0")!)!
    let completion = AgentAutonomousActivityOutcome(
        activityID: activity.activityID, actorID: activity.candidate.actorID,
        lifecycle: .completed, completedAtTick: session.tick,
        physicalReceiptID: "stable-receipt-1", reason: "verified fixture boundary"
    )
    _ = try! session.recordAutonomousActivityOutcome(completion)
    check("validated outcome ends active activity", session.autonomousActivitySnapshot().activeActivities.isEmpty)
    check("completion counter advances once", session.autonomousActivitySnapshot().counters.completionCount == 1)

    let beforeDuplicate = try! session.durableStateDigest()
    let duplicateRejected = (try? session.selectAutonomousActivities([
        autonomousCandidate(id: "duplicate", tick: session.tick),
        autonomousCandidate(id: "duplicate", tick: session.tick),
    ])) == nil
    check("duplicate candidate IDs are rejected", duplicateRejected)
    check("rejected decision is transactional", try! session.durableStateDigest() == beforeDuplicate)

    var bounded = autonomousSession("autonomous-bounded")
    let boundedConfiguration = try! AgentAutonomousActivityConfiguration(
        maximumCandidatesPerDecision: 8, maximumActiveActivities: 2,
        maximumRetainedRecords: 16, maximumCooldowns: 8, blockedCooldownTicks: 1
    )
    try! bounded.setAutonomousActivityEnabled(true, configuration: boundedConfiguration)
    for index in 0..<600 {
        let candidate = autonomousCandidate(id: "bounded-\(index)")
        let activity = try! bounded.selectAutonomousActivities([candidate])[0]
        _ = try! bounded.recordAutonomousActivityOutcome(AgentAutonomousActivityOutcome(
            activityID: activity.activityID, actorID: activity.candidate.actorID,
            lifecycle: .completed, completedAtTick: bounded.tick,
            physicalReceiptID: "receipt-\(index)", reason: "verified"
        ))
    }
    let boundedSnapshot = bounded.autonomousActivitySnapshot()
    check("autonomy accepts 600 lifetime operations", boundedSnapshot.counters.completionCount == 600)
    check("retained activity history is bounded", boundedSnapshot.recentRecords.count == 16)
    check("bounded history reports exact eviction", boundedSnapshot.evictionCount == 584)
    check("no terminal lifetime operation cap", boundedSnapshot.counters.startCount == 600)

    let checkpoint = try! bounded.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("autonomy checkpoint schema is v18", checkpoint.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion)
    check("checkpoint restores exact bounded state", restored.autonomousActivitySnapshot() == boundedSnapshot)
    check("checkpoint bytes are deterministic", try! restored.durableStateBytes() == bounded.durableStateBytes())
    let durableText = String(data: try! bounded.durableStateBytes(), encoding: .utf8)!
    check("durable activity state has no runtime entity identity", !durableText.contains("runtimeEntity") && !durableText.contains("World object"))

    var replayedDirect = autonomousSession("autonomous-replay")
    let replayBase = try! replayedDirect.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(checkpoint: replayBase, session: replayedDirect)
    _ = try! recorder.apply(
        .setAutonomousActivityEnabled(true, configuration: .live), to: &replayedDirect
    )
    let replayCandidate = autonomousCandidate(id: "replay")
    _ = try! recorder.apply(.selectAutonomousActivities([replayCandidate]), to: &replayedDirect)
    let replayActivity = replayedDirect.activeAutonomousActivity(
        for: AgentID(rawValue: "agent_0")!
    )!
    _ = try! recorder.apply(.autonomousActivityOutcome(AgentAutonomousActivityOutcome(
        activityID: replayActivity.activityID, actorID: replayActivity.candidate.actorID,
        lifecycle: .completed, completedAtTick: replayedDirect.tick,
        physicalReceiptID: "replay-receipt", reason: "verified"
    )), to: &replayedDirect)
    let journal = try! recorder.journal(named: AgentCheckpointName(rawValue: "autonomy")!)
    let replayed = try! AgentSessionReplayer.replay(checkpoint: replayBase, journal: journal)
    check("autonomy replay schema is v18", journal.manifest.schemaVersion == AgentReplaySchema.autonomousActivityVersion)
    check("replay reproduces selection and completion", replayed.report.verified && replayed.report.recordsApplied == 3)
    check("replay final bytes are exact", try! replayed.session.durableStateBytes() == replayedDirect.durableStateBytes())
}
