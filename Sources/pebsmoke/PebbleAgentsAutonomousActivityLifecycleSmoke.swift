import PebbleAgents

private func lifecycleAgent() -> AgentSessionAgentState {
    let position = AgentPosition(x: 0, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_0", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "lifecycle fixture", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func lifecycleSession(_ id: String) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 32)
        ),
        agents: [lifecycleAgent()],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 256)
    )
    try! session.setAutonomousActivityEnabled(
        true,
        configuration: try! AgentAutonomousActivityConfiguration(
            maximumCandidatesPerDecision: 16,
            maximumActiveActivities: 4,
            maximumRetainedRecords: 32,
            maximumCooldowns: 8,
            blockedCooldownTicks: 2
        )
    )
    return session
}

private func lifecycleCandidate(
    id: String,
    logicalTarget: String = "plant:sweet_berry_bush@2,64,0",
    approach: AgentPosition = AgentPosition(x: 1, y: 64, z: 0),
    material: String = "sweet_berry_bush:ripe",
    source: AgentAutonomousActivitySource = .opportunity,
    commitmentID: AgentWorkCommitmentID? = nil,
    tick: Int = 0
) -> AgentAutonomousActivityCandidate {
    AgentAutonomousActivityCandidate(
        candidateID: id,
        actorID: AgentID(rawValue: "agent_0")!,
        domain: .wildGathering,
        actionKey: "wildGathering",
        stableReference: "ephemeral:\(id)",
        target: approach,
        logicalTargetKey: logicalTarget,
        physicalTarget: AgentPosition(x: 2, y: 64, z: 0),
        approachPosition: approach,
        materialFingerprint: AgentAutonomousActivityDigest.make(material),
        source: source,
        priorityBand: 30,
        urgency: 70,
        distance: 1,
        commitmentID: commitmentID,
        observedAtTick: tick
    )
}

func runPebbleAgentsAutonomousActivityLifecycleSmoke() {
    section("PebbleAgents bounded autonomous activity lifecycle")

    let instanceA = lifecycleCandidate(id: "opportunity-A")
    let instanceB = lifecycleCandidate(id: "opportunity-B")
    check(
        "candidate instance is distinct from logical activity identity",
        instanceA.candidateID != instanceB.candidateID
            && instanceA.logicalActivityKey == instanceB.logicalActivityKey
    )
    check(
        "ephemeral opportunity identity does not fragment a physical attempt",
        instanceA.stableReference != instanceB.stableReference
            && instanceA.physicalAttemptFingerprint
                == instanceB.physicalAttemptFingerprint
    )

    var continuity = lifecycleSession("activity-lifecycle-continuity")
    let activeA = try! continuity.selectAutonomousActivities([instanceA])[0]
    _ = try! continuity.advanceTick()
    let activeB = try! continuity.selectAutonomousActivities([
        lifecycleCandidate(id: "opportunity-B", tick: continuity.tick)
    ])[0]
    let continuityState = continuity.autonomousActivitySnapshot()
    check(
        "renewed candidate preserves active logical execution",
        activeB.activityID == activeA.activityID
            && activeB.selectedAtTick == activeA.selectedAtTick
            && activeB.candidate.candidateID == "opportunity-B"
    )
    check(
        "logical renewal creates no terminal record or new start",
        continuityState.recentRecords.isEmpty
            && continuityState.counters.startCount == 1
            && continuityState.counters.switchCount == 0
    )

    let movedApproach = lifecycleCandidate(
        id: "opportunity-C",
        approach: AgentPosition(x: 2, y: 64, z: 1),
        tick: continuity.tick
    )
    let activeC = try! continuity.selectAutonomousActivities([movedApproach])[0]
    check(
        "changed approach is a new physical attempt inside one activity",
        movedApproach.logicalActivityKey == activeB.candidate.logicalActivityKey
            && movedApproach.physicalAttemptFingerprint
                != activeB.candidate.physicalAttemptFingerprint
            && activeC.activityID == activeA.activityID
            && activeC.selectedAtTick == activeA.selectedAtTick
    )
    check(
        "physical replan preserves logical start and switch counters",
        continuity.autonomousActivitySnapshot().counters.startCount == 1
            && continuity.autonomousActivitySnapshot().counters.switchCount == 0
    )

    let commitmentA = AgentWorkCommitmentID(rawValue: "work-commitment-A")!
    let commitmentB = AgentWorkCommitmentID(rawValue: "work-commitment-B")!
    var obligation = lifecycleSession("activity-lifecycle-obligation")
    let obligationA = lifecycleCandidate(
        id: "commitment-instance-A", source: .commitment,
        commitmentID: commitmentA
    )
    let obligationActiveA = try! obligation.selectAutonomousActivities([
        obligationA
    ])[0]
    let obligationB = lifecycleCandidate(
        id: "commitment-instance-B", source: .commitment,
        commitmentID: commitmentB
    )
    let obligationActiveB = try! obligation.selectAutonomousActivities([
        obligationB
    ])[0]
    check(
        "renewed commitment ID preserves the stable business obligation",
        obligationActiveB.activityID == obligationActiveA.activityID
            && obligationActiveB.candidate.commitmentID == commitmentB
    )

    let differentObligation = lifecycleCandidate(
        id: "commitment-other",
        logicalTarget: "plant:sweet_berry_bush@3,64,0",
        source: .commitment,
        commitmentID: commitmentB
    )
    let obligationActiveC = try! obligation.selectAutonomousActivities([
        differentObligation
    ])[0]
    check(
        "different logical target starts a new activity",
        obligationActiveC.activityID != obligationActiveB.activityID
            && obligation.autonomousActivitySnapshot()
                .recentRecords.last?.outcome.lifecycle == .interrupted
    )

    var cooldown = lifecycleSession("activity-lifecycle-cooldown")
    let blocked = lifecycleCandidate(id: "blocked-A")
    let blockedActivity = try! cooldown.selectAutonomousActivities([blocked])[0]
    _ = try! cooldown.recordAutonomousActivityOutcome(
        AgentAutonomousActivityOutcome(
            activityID: blockedActivity.activityID,
            actorID: blockedActivity.candidate.actorID,
            lifecycle: .blocked,
            completedAtTick: cooldown.tick,
            reason: "approachUnavailable"
        )
    )
    let renewedBlocked = lifecycleCandidate(id: "blocked-B")
    check(
        "new ephemeral ID cannot bypass active physical cooldown",
        try! cooldown.selectAutonomousActivities([renewedBlocked]).isEmpty
    )
    _ = try! cooldown.advanceTick()
    _ = try! cooldown.advanceTick()
    let expiryBoundary = try! cooldown.selectAutonomousActivities([
        lifecycleCandidate(id: "blocked-C", tick: cooldown.tick)
    ])
    check(
        "cooldown is still active at its exclusive boundary",
        expiryBoundary.isEmpty
    )
    _ = try! cooldown.advanceTick()
    let reopened = try! cooldown.selectAutonomousActivities([
        lifecycleCandidate(id: "blocked-D", tick: cooldown.tick)
    ])
    check(
        "physical cooldown really expires after untilTick",
        reopened.count == 1
    )
    check(
        "expired cooldown retains bounded logical failure history",
        cooldown.autonomousActivitySnapshot().cooldowns.count == 1
    )

    var materialChange = lifecycleSession("activity-lifecycle-material-change")
    let original = lifecycleCandidate(id: "material-A")
    let originalActivity = try! materialChange.selectAutonomousActivities([
        original
    ])[0]
    _ = try! materialChange.recordAutonomousActivityOutcome(
        AgentAutonomousActivityOutcome(
            activityID: originalActivity.activityID,
            actorID: originalActivity.candidate.actorID,
            lifecycle: .blocked,
            completedAtTick: materialChange.tick,
            reason: "targetDepleted"
        )
    )
    let materiallyRenewed = lifecycleCandidate(
        id: "material-B", material: "sweet_berry_bush:renewed"
    )
    check(
        "material change creates a different physical attempt",
        materiallyRenewed.logicalActivityKey == original.logicalActivityKey
            && materiallyRenewed.physicalAttemptFingerprint
                != original.physicalAttemptFingerprint
    )
    check(
        "changed physical reality can progress within the logical bound",
        try! materialChange.selectAutonomousActivities([materiallyRenewed])
            .first?.candidate.candidateID == "material-B"
    )

    var boundedFailure = lifecycleSession("activity-lifecycle-bounded-failure")
    for index in 0..<4 {
        let attempt = lifecycleCandidate(
            id: "attempt-\(index)",
            material: "physical-state-\(index)",
            tick: boundedFailure.tick
        )
        let activity = try! boundedFailure.selectAutonomousActivities([
            attempt
        ])[0]
        _ = try! boundedFailure.recordAutonomousActivityOutcome(
            AgentAutonomousActivityOutcome(
                activityID: activity.activityID,
                actorID: activity.candidate.actorID,
                lifecycle: .blocked,
                completedAtTick: boundedFailure.tick,
                reason: "approachUnavailable"
            )
        )
        for _ in 0..<3 { _ = try! boundedFailure.advanceTick() }
    }
    let exhausted = try! boundedFailure.selectAutonomousActivities([
        lifecycleCandidate(
            id: "attempt-exhausted",
            material: "physical-state-new",
            tick: boundedFailure.tick
        )
    ])
    check(
        "logical failure history is bounded by the physical replan budget",
        boundedFailure.autonomousActivitySnapshot().cooldowns.count == 4
            && exhausted.isEmpty
    )

    var successReset = lifecycleSession("activity-lifecycle-success-reset")
    let failedBeforeSuccess = lifecycleCandidate(id: "before-success")
    let failedActivity = try! successReset.selectAutonomousActivities([
        failedBeforeSuccess
    ])[0]
    _ = try! successReset.recordAutonomousActivityOutcome(
        AgentAutonomousActivityOutcome(
            activityID: failedActivity.activityID,
            actorID: failedActivity.candidate.actorID,
            lifecycle: .blocked,
            completedAtTick: successReset.tick,
            reason: "targetTemporarilyUnavailable"
        )
    )
    let recovered = lifecycleCandidate(
        id: "verified-success", material: "sweet_berry_bush:ripe-again"
    )
    let recoveredActivity = try! successReset.selectAutonomousActivities([
        recovered
    ])[0]
    _ = try! successReset.recordAutonomousActivityOutcome(
        AgentAutonomousActivityOutcome(
            activityID: recoveredActivity.activityID,
            actorID: recoveredActivity.candidate.actorID,
            lifecycle: .completed,
            completedAtTick: successReset.tick,
            physicalReceiptID: "physical-receipt-1",
            reason: "verified physical success"
        )
    )
    check(
        "verified physical success clears the logical failure history",
        successReset.autonomousActivitySnapshot().cooldowns.isEmpty
    )

    let checkpoint = try! materialChange.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check(
        "checkpoint v18 preserves logical and physical activity identities",
        checkpoint.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion
            && restored.autonomousActivitySnapshot()
                == materialChange.autonomousActivitySnapshot()
            && (try! restored.durableStateDigest())
                == (try! materialChange.durableStateDigest())
    )
}
