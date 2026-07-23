import Foundation
import PebbleAgents

private let integratedTeachingHome = AgentPosition(x: 0, y: 64, z: 0)

private func integratedTeachingAgent(
    _ ordinal: Int,
    position: AgentPosition,
    hunger: Double = 0,
    safety: Double = 1
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: hunger, fatigue: 0, curiosity: 0, safety: safety
        ),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "integrated teaching fixture",
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

private func integratedTeachingSession(
    _ simulationID: String,
    agents: [AgentSessionAgentState]? = nil,
    teachingConfiguration: AgentTeachingConfiguration = .live
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 103, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 128),
            campStockCapacity: 256
        ),
        agents: agents ?? [
            integratedTeachingAgent(0, position: integratedTeachingHome),
            integratedTeachingAgent(
                1, position: AgentPosition(x: 1, y: 64, z: 0)
            ),
            integratedTeachingAgent(
                2, position: AgentPosition(x: 2, y: 64, z: 0)
            ),
        ],
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 32_768)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: integratedTeachingHome,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.setLifecycleEnabled(true, configuration: .live)
    try! session.setSkillsEnabled(true)
    try! session.setTeachingEnabled(true, configuration: teachingConfiguration)
    try! session.setAutonomousActivityEnabled(true)
    for _ in 0..<AgentTeachingParticipationPolicy.reviewIntervalTicks {
        _ = try! session.advanceTick()
    }
    return session
}

@discardableResult
private func integratedTeachingPractice(
    _ session: inout AgentSimulationSession,
    agentID: AgentID,
    index: Int
) -> (source: AgentCausalEventID, skill: AgentCausalEventID) {
    try! session.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "integrated-teaching-material-\(agentID.rawValue)-\(index)",
        agentId: agentID.rawValue, tick: session.tick,
        target: AgentPosition(x: 20 + index, y: 64, z: index),
        resource: .wood, status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .wood, quantity: 1),
        reason: "bounded material fixture", source: .sandboxFixture
    ))
    var preview = session
    let delivery = try! preview.deliverResources(AgentDeliveryIntent(
        deliveryId: "integrated-teaching-delivery-\(agentID.rawValue)-\(index)",
        agentId: agentID.rawValue, tick: session.tick,
        position: try! session.state(for: agentID).position
    ))
    try! session.applyDeliveryOutcome(delivery)
    let practice = session.skillProfile(for: agentID)!.domainPractices.first {
        $0.domain == .materialHandling
    }!
    return (
        practice.lastSourceSuccessEventID,
        practice.lastSkillPracticeEventID
    )
}

private func integratedTeachingTrain(
    _ session: inout AgentSimulationSession,
    agentID: AgentID,
    count: Int,
    base: Int
) {
    for offset in 0..<count {
        _ = integratedTeachingPractice(
            &session, agentID: agentID, index: base + offset
        )
    }
}

private func integratedTeachingCandidate(
    _ session: AgentSimulationSession,
    actorID: AgentID,
    suffix: String = "work"
) -> AgentAutonomousActivityCandidate {
    let position = try! session.state(for: actorID).position
    return AgentAutonomousActivityCandidate(
        candidateID: "integrated-teaching:\(actorID.rawValue):\(suffix)",
        actorID: actorID, domain: .materialHandling,
        actionKey: "handle_material", stableReference: "local-work:\(suffix)",
        target: position, source: .opportunity, priorityBand: 30, urgency: 60,
        distance: 0, observedAtTick: session.tick
    )
}

private func integratedTeachingOpportunity(
    _ session: AgentSimulationSession,
    studentID: AgentID,
    candidates: [AgentID],
    suffix: String = "work"
) -> AgentLocalApprenticeshipOpportunity {
    AgentLocalApprenticeshipOpportunity(
        studentID: studentID, domain: .materialHandling,
        localMentorCandidateIDs: candidates,
        reason: .currentAutonomousActivity,
        contextReference: "local-work:\(suffix)",
        observedAtTick: session.tick
    )
}

private func integratedTeachingObservation(
    _ session: AgentSimulationSession,
    engagement: AgentApprenticeshipEngagement,
    source: AgentCausalEventID
) -> AgentTeachingObservation {
    let teacher = try! session.state(for: engagement.teacherID).position
    let student = try! session.state(for: engagement.studentID).position
    let distance = abs(teacher.x - student.x)
        + abs(teacher.y - student.y)
        + abs(teacher.z - student.z)
    let physical = session.configuration.physicalChannelConfiguration
    return AgentTeachingObservation(
        apprenticeshipID: engagement.apprenticeshipID,
        teacherID: engagement.teacherID, studentID: engagement.studentID,
        domain: engagement.domain, sourceSuccessEventID: source,
        teacherPosition: teacher, studentPosition: student,
        distanceManhattan: distance,
        soundClarity: physical.soundClarity(
            distanceManhattan: distance, opaqueOcclusionCount: 0
        ),
        gestureClarity: physical.gestureClarity(
            distanceManhattan: distance, lineOfSight: true
        ),
        opaqueOcclusionCount: 0, lineOfSight: true, chunksReady: true,
        observedAtTick: session.tick
    )
}

private func integratedTeachingPolicyContext(
    role: AgentTeachingParticipationRole,
    active: Bool = true,
    stage: AgentLifeStage? = .mature,
    migrating: Bool = false,
    criticalHunger: Bool = false,
    care: Bool = false,
    unsafe: Bool = false,
    urgent: Bool = false,
    capacity: Bool = true
) -> AgentTeachingParticipationContext {
    AgentTeachingParticipationContext(
        participantID: AgentID(rawValue: "agent_9")!, role: role,
        active: active, lifecycleStage: stage, migrating: migrating,
        criticalHunger: criticalHunger, urgentCarePriority: care,
        unsafe: unsafe, incompatibleUrgentResponsibility: urgent,
        teacherCapacityAvailable: capacity
    )
}

func runPebbleAgentsIntegratedTeachingInitiationSmoke() {
    section("PebbleAgents integrated local apprenticeship initiation")

    let teacher = AgentID(rawValue: "agent_0")!
    let student = AgentID(rawValue: "agent_1")!
    let alternate = AgentID(rawValue: "agent_2")!

    var normal = integratedTeachingSession("integrated-teaching-normal")
    integratedTeachingTrain(&normal, agentID: teacher, count: 3, base: 10)
    let practiceBefore = normal.practiceUnits(
        agentID: student, domain: .materialHandling
    )
    let materialBefore = normal.snapshot().conservation
    let selected = try! normal.selectAutonomousActivities([
        integratedTeachingCandidate(normal, actorID: student),
    ])
    let review = normal.autonomousTeachingReviewSnapshot()
    let engagement = normal.activeApprenticeship(
        studentID: student, domain: .materialHandling
    )
    check("normal autonomy caller starts local apprenticeship",
          selected.count == 1 && review.started >= 1 && engagement != nil)
    check("zero-practice student is eligible through real local context",
          practiceBefore == 0
            && review.attempts.contains {
                $0.opportunity.studentID == student
                    && $0.opportunity.reason == .currentAutonomousActivity
                    && $0.disposition == .started
            })
    check("initiation grants no skill or material output",
          normal.practiceUnits(agentID: student, domain: .materialHandling)
            == practiceBefore
            && normal.snapshot().conservation == materialBefore)
    check("autonomous participation decisions are explicit",
          review.attempts.contains {
              $0.disposition == .started
                && $0.studentDecision.accepts
                && $0.teacherDecisions.contains {
                    $0.participantID == teacher && $0.accepts
                }
          })

    var noMentor = integratedTeachingSession("integrated-teaching-no-mentor")
    _ = try! noMentor.selectAutonomousActivities([
        integratedTeachingCandidate(noMentor, actorID: student),
    ])
    check("no practiced local mentor creates no apprenticeship",
          noMentor.teachingSnapshot().totalApprenticeshipCount == 0
            && noMentor.autonomousTeachingReviewSnapshot().noMentor > 0)

    var distant = integratedTeachingSession(
        "integrated-teaching-distant",
        agents: [
            integratedTeachingAgent(0, position: integratedTeachingHome),
            integratedTeachingAgent(
                1, position: AgentPosition(x: 20, y: 64, z: 0)
            ),
            integratedTeachingAgent(
                2, position: AgentPosition(x: 21, y: 64, z: 0)
            ),
        ]
    )
    integratedTeachingTrain(&distant, agentID: teacher, count: 3, base: 100)
    _ = try! distant.selectAutonomousActivities([
        integratedTeachingCandidate(distant, actorID: student),
    ])
    check("distant expert is absent from bounded local discovery",
          distant.teachingSnapshot().totalApprenticeshipCount == 0
            && distant.autonomousTeachingReviewSnapshot().attempts.allSatisfy {
                !$0.opportunity.localMentorCandidateIDs.contains(teacher)
            })

    var hungryStudent = integratedTeachingSession(
        "integrated-teaching-hungry-student",
        agents: [
            integratedTeachingAgent(0, position: integratedTeachingHome),
            integratedTeachingAgent(
                1, position: AgentPosition(x: 1, y: 64, z: 0), hunger: 0.9
            ),
            integratedTeachingAgent(
                2, position: AgentPosition(x: 2, y: 64, z: 0)
            ),
        ]
    )
    integratedTeachingTrain(
        &hungryStudent, agentID: teacher, count: 3, base: 200
    )
    _ = try! hungryStudent.selectAutonomousActivities([
        integratedTeachingCandidate(hungryStudent, actorID: student),
    ])
    let hungryAttempt = hungryStudent.autonomousTeachingReviewSnapshot().attempts.first {
        $0.opportunity.studentID == student
    }
    check("critical student hunger autonomously refuses participation",
          hungryAttempt?.disposition == .studentRefused
            && hungryAttempt?.studentDecision.refusalReason == .criticalHunger
            && hungryStudent.activeApprenticeship(
                studentID: student, domain: .materialHandling
            ) == nil)

    var hungryTeacher = integratedTeachingSession(
        "integrated-teaching-hungry-teacher",
        agents: [
            integratedTeachingAgent(
                0, position: integratedTeachingHome, hunger: 0.9
            ),
            integratedTeachingAgent(
                1, position: AgentPosition(x: 1, y: 64, z: 0)
            ),
            integratedTeachingAgent(
                2, position: AgentPosition(x: 2, y: 64, z: 0)
            ),
        ]
    )
    integratedTeachingTrain(
        &hungryTeacher, agentID: teacher, count: 3, base: 300
    )
    _ = try! hungryTeacher.selectAutonomousActivities([
        integratedTeachingCandidate(hungryTeacher, actorID: student),
    ])
    let teacherDecision = hungryTeacher.autonomousTeachingReviewSnapshot().attempts
        .first { $0.opportunity.studentID == student }?
        .teacherDecisions.first { $0.participantID == teacher }
    check("critical teacher hunger autonomously refuses participation",
          teacherDecision?.accepts == false
            && teacherDecision?.refusalReason == .criticalHunger
            && hungryTeacher.teachingSnapshot().totalApprenticeshipCount == 0)

    let refusalMatrix: [(AgentTeachingParticipationContext,
        AgentTeachingParticipationRefusalReason)] = [
        (
            integratedTeachingPolicyContext(role: .student, active: false),
            .inactive
        ),
        (
            integratedTeachingPolicyContext(role: .student, stage: .newborn),
            .ineligibleLifecycleStage
        ),
        (
            integratedTeachingPolicyContext(role: .student, migrating: true),
            .migrating
        ),
        (
            integratedTeachingPolicyContext(role: .student, care: true),
            .carePriority
        ),
        (
            integratedTeachingPolicyContext(role: .student, unsafe: true),
            .unsafeContext
        ),
        (
            integratedTeachingPolicyContext(role: .student, urgent: true),
            .incompatibleUrgentResponsibility
        ),
        (
            integratedTeachingPolicyContext(role: .teacher, capacity: false),
            .teacherCapacityReached
        ),
    ]
    check("participation policy refuses lifecycle care migration safety and capacity",
          refusalMatrix.allSatisfy {
              let decision = AgentTeachingParticipationPolicy.decide($0.0)
              return !decision.accepts && decision.refusalReason == $0.1
          })
    check("participation policy accepts available mature participants",
          AgentTeachingParticipationPolicy.decide(
            integratedTeachingPolicyContext(role: .student)
          ).accepts
            && AgentTeachingParticipationPolicy.decide(
                integratedTeachingPolicyContext(role: .teacher)
            ).accepts)

    let capacityConfiguration = try! AgentTeachingConfiguration(
        maximumActiveApprenticeships: 4,
        maximumRetainedApprenticeships: 8,
        maximumApprenticesPerTeacher: 1
    )
    var capacity = integratedTeachingSession(
        "integrated-teaching-capacity",
        agents: [
            integratedTeachingAgent(0, position: integratedTeachingHome),
            integratedTeachingAgent(
                1, position: AgentPosition(x: 1, y: 64, z: 0)
            ),
            integratedTeachingAgent(
                2, position: AgentPosition(x: 2, y: 64, z: 0)
            ),
        ],
        teachingConfiguration: capacityConfiguration
    )
    integratedTeachingTrain(&capacity, agentID: teacher, count: 3, base: 400)
    _ = try! capacity.reviewLocalApprenticeshipOpportunities([
        integratedTeachingOpportunity(
            capacity, studentID: student, candidates: [teacher],
            suffix: "first"
        ),
    ])
    let countAtCapacity = capacity.teachingSnapshot().totalApprenticeshipCount
    let capacityReview = try! capacity.reviewLocalApprenticeshipOpportunities([
        integratedTeachingOpportunity(
            capacity, studentID: alternate, candidates: [teacher],
            suffix: "second"
        ),
    ])
    check("teacher capacity is honored by autonomous consent and selector",
          countAtCapacity == 1
            && capacity.teachingSnapshot().totalApprenticeshipCount == 1
            && capacityReview.refusedTeacher == 1
            && capacityReview.noMentor == 1)
    let duplicateReview = try! capacity.reviewLocalApprenticeshipOpportunities([
        integratedTeachingOpportunity(
            capacity, studentID: student, candidates: [teacher],
            suffix: "duplicate"
        ),
    ])
    check("active student-domain apprenticeship prevents duplicate initiation",
          duplicateReview.attempts.first?.disposition
            == .activeApprenticeshipExists
            && capacity.teachingSnapshot().totalApprenticeshipCount == 1)

    func ranked(_ id: String, order: [AgentID]) -> AgentID? {
        var session = integratedTeachingSession(id)
        integratedTeachingTrain(&session, agentID: teacher, count: 3, base: 500)
        integratedTeachingTrain(&session, agentID: alternate, count: 4, base: 600)
        _ = try! session.reviewLocalApprenticeshipOpportunities([
            integratedTeachingOpportunity(
                session, studentID: student, candidates: order,
                suffix: "rank"
            ),
        ])
        return session.activeApprenticeship(
            studentID: student, domain: .materialHandling
        )?.teacherID
    }
    check("existing mentor ranker prefers more practice",
          ranked(
            "integrated-teaching-rank-a", order: [teacher, alternate]
          ) == alternate)
    check("local candidate input order does not affect mentor selection",
          ranked(
            "integrated-teaching-rank-b", order: [alternate, teacher]
          ) == alternate)

    _ = try! normal.advanceTick()
    let teacherSuccess = integratedTeachingPractice(
        &normal, agentID: teacher, index: 700
    )
    let studentBeforeObservation = normal.practiceUnits(
        agentID: student, domain: .materialHandling
    )
    let materialImmediatelyBeforeObservation = normal.snapshot().conservation
    let exposure = try! normal.recordTeachingDemonstration(
        integratedTeachingObservation(
            normal, engagement: engagement!, source: teacherSuccess.source
        )
    )
    check("post-initiation real teacher success records local demonstration",
          normal.teachingSnapshot().totalDemonstrationCount == 1
            && exposure.teacherID == teacher && exposure.studentID == student)
    check("observation grants exactly zero skill and material",
          normal.practiceUnits(agentID: student, domain: .materialHandling)
            == studentBeforeObservation
            && normal.snapshot().conservation
                == materialImmediatelyBeforeObservation)
    let studentSuccess = integratedTeachingPractice(
        &normal, agentID: student, index: 701
    )
    _ = try! normal.linkGuidedPractice(
        exposureID: exposure.exposureID,
        studentSourceSuccessEventID: studentSuccess.source,
        skillPracticeEventID: studentSuccess.skill
    )
    check("student own real success grants canonical practice",
          normal.practiceUnits(agentID: student, domain: .materialHandling)
            == studentBeforeObservation + 1)
    check("guided link adds no second skill or material bonus",
          normal.teachingSnapshot().totalGuidedPracticeCount == 1
            && normal.practiceUnits(agentID: student, domain: .materialHandling)
                == studentBeforeObservation + 1)

    var persistence = integratedTeachingSession(
        "integrated-teaching-checkpoint"
    )
    integratedTeachingTrain(
        &persistence, agentID: teacher, count: 3, base: 800
    )
    let persistenceCandidate = integratedTeachingCandidate(
        persistence, actorID: student
    )
    _ = try! persistence.selectAutonomousActivities([persistenceCandidate])
    let checkpoint = try! persistence.makeCheckpoint()
    var restored = try! AgentSimulationSession.restoring(checkpoint)
    let restoredCount = restored.teachingSnapshot().totalApprenticeshipCount
    _ = try! restored.selectAutonomousActivities([
        integratedTeachingCandidate(restored, actorID: student),
    ])
    check("v18 checkpoint restores autonomous apprenticeship exactly",
          checkpoint.schemaVersion == 18
            && restored.activeApprenticeship(
                studentID: student, domain: .materialHandling
            )?.apprenticeshipID
                == persistence.activeApprenticeship(
                    studentID: student, domain: .materialHandling
                )?.apprenticeshipID)
    check("restart does not duplicate autonomous initiation",
          restored.teachingSnapshot().totalApprenticeshipCount == restoredCount
            && restored.autonomousTeachingReviewSnapshot().attempts.first {
                $0.opportunity.studentID == student
            }?.disposition == .activeApprenticeshipExists)

    var replayBase = integratedTeachingSession("integrated-teaching-replay")
    integratedTeachingTrain(&replayBase, agentID: teacher, count: 3, base: 900)
    let replayCheckpoint = try! replayBase.makeCheckpoint()
    var replayed = replayBase
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayCheckpoint, session: replayed
    )
    _ = try! recorder.apply(
        .selectAutonomousActivities([
            integratedTeachingCandidate(replayed, actorID: student),
        ]),
        to: &replayed
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "integrated-teaching-replay")!
    )
    let replayResult = try! AgentSessionReplayer.replay(
        checkpoint: replayCheckpoint, journal: journal
    )
    check("replay reproduces autonomous initiation through existing operation",
          replayResult.report.verified
            && replayResult.session.activeApprenticeship(
                studentID: student, domain: .materialHandling
            ) != nil)
    check("replayed autonomous initiation is byte deterministic",
          (try! replayResult.session.durableStateBytes())
            == (try! replayed.durableStateBytes()))

    var reengagement = integratedTeachingSession(
        "integrated-teaching-reengagement"
    )
    integratedTeachingTrain(
        &reengagement, agentID: teacher, count: 3, base: 1_000
    )
    _ = try! reengagement.reviewLocalApprenticeshipOpportunities([
        integratedTeachingOpportunity(
            reengagement, studentID: student, candidates: [teacher]
        ),
    ])
    let first = reengagement.activeApprenticeship(
        studentID: student, domain: .materialHandling
    )!
    try! reengagement.endApprenticeship(
        first.apprenticeshipID, by: student, reason: .completed
    )
    let immediate = try! reengagement.reviewLocalApprenticeshipOpportunities([
        integratedTeachingOpportunity(
            reengagement, studentID: student, candidates: [teacher],
            suffix: "immediate"
        ),
    ])
    for _ in 0..<AgentTeachingParticipationPolicy.reengagementCooldownTicks {
        _ = try! reengagement.advanceTick()
    }
    let later = try! reengagement.reviewLocalApprenticeshipOpportunities([
        integratedTeachingOpportunity(
            reengagement, studentID: student, candidates: [teacher],
            suffix: "later"
        ),
    ])
    check("terminal apprenticeship suppresses immediate restart spam",
          immediate.attempts.first?.disposition == .reengagementCooldown)
    check("bounded cooldown is not a lifetime apprenticeship ban",
          later.started == 1
            && reengagement.teachingSnapshot().totalApprenticeshipCount == 2)

    let cadence = AgentTeachingParticipationPolicy.reviewIntervalTicks
    check("initiation cadence and diagnostics are deterministic and bounded",
          cadence == 4
            && review.reviewedAtTick % cadence == 0
            && review.attempts.count == review.opportunitiesConsidered
            && review.opportunitiesConsidered
                <= AgentAutonomousActivityConfiguration.live
                    .maximumCandidatesPerDecision)
}
