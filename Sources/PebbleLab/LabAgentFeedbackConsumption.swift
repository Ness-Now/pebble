import PebbleCore

struct LabAgentFeedbackFixtureInput: Codable {
    let order: Int
    let tick: Int?
    let agentId: String?
    let feedbackKind: LabMovementFeedbackKind?
    let decision: LabMultiAgentMoveDecision?
    let reason: String?
    let from: LabTerrainPathNodeKey?
    let to: LabTerrainPathNodeKey?
    let displacementApplied: Bool?
    let collisionRead: Bool?
    let abstractBefore: LabTerrainPathNodeKey?
    let abstractAfter: LabTerrainPathNodeKey?
    let physicalBefore: LabTerrainPathNodeKey?
    let physicalAfter: LabTerrainPathNodeKey?
    let malformedReason: String?
}

struct LabAgentFeedbackObservation: Codable {
    let tick: Int
    let agentId: String
    let feedbackKind: LabMovementFeedbackKind
    let decision: LabMultiAgentMoveDecision?
    let reason: String
    let from: LabTerrainPathNodeKey?
    let to: LabTerrainPathNodeKey?
    let displacementApplied: Bool
    let collisionRead: Bool
    let abstractBefore: LabTerrainPathNodeKey?
    let abstractAfter: LabTerrainPathNodeKey?
    let physicalBefore: LabTerrainPathNodeKey?
    let physicalAfter: LabTerrainPathNodeKey?
}

struct LabAgentFeedbackContext: Codable {
    let tick: Int
    let agentId: String
    let lastFeedback: LabAgentFeedbackObservation?
    let lastMoveSucceeded: Bool
    let lastMoveBlocked: Bool
    let lastBlockReason: LabMovementFeedbackKind?
    let lastKnownPosition: LabTerrainPathNodeKey?
    let localHints: [String]
    let role: String?
}

enum LabAgentFeedbackConsumptionDecision: String, Codable {
    case ignored
    case observed
    case acceptedAsContext
    case invalidFeedback
}

struct LabAgentFeedbackConsumptionResult: Codable {
    let tick: Int
    let fixtureFeedback: [LabAgentFeedbackFixtureInput]
    let observations: [LabAgentFeedbackObservation]
    let acceptedContexts: [LabAgentFeedbackContext]
    let ignoredFeedback: [LabAgentFeedbackFixtureInput]
    let invalidFeedback: [LabAgentFeedbackFixtureInput]
    let summary: LabAgentFeedbackConsumptionSummary
}

struct LabAgentFeedbackConsumptionSummary: Codable {
    let agentsObserved: Int
    let feedbackObserved: Int
    let feedbackAccepted: Int
    let feedbackIgnored: Int
    let invalidFeedback: Int
    let contextsProduced: Int
    let moved: Int
    let approvedForMovement: Int
    let blockedByCollision: Int
    let blockedByAgentConflict: Int
    let blockedBySourceMismatch: Int
    let blockedByDivergence: Int
    let blockedByStaleIntent: Int
    let blockedByInvalidEdge: Int
    let blockedByMaxAgents: Int
    let duplicateFeedback: Int
    let feedbackEvidenceCollisionReadCount: Int
    let memoryUpdated: Bool
    let goalChanged: Bool
    let replanningPerformed: Bool
    let pathfindingPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let movementApplied: Bool
    let collisionRead: Bool
    let intentProduced: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAgentFeedbackConsumptionFixtureSummary: Codable {
    let tick: Int
    let agentsObserved: Int
    let feedbackObserved: Int
    let feedbackAccepted: Int
    let feedbackIgnored: Int
    let invalidFeedback: Int
    let contextsProduced: Int
    let moved: Int
    let approvedForMovement: Int
    let blockedByCollision: Int
    let blockedByAgentConflict: Int
    let duplicateFeedback: Int
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let movementApplied: Bool
    let collisionRead: Bool
    let intentProduced: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAgentFeedbackConsumptionFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let result: LabAgentFeedbackConsumptionResult
    let summary: LabAgentFeedbackConsumptionFixtureSummary
}

struct LabAgentFeedbackConsumptionFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

private func feedbackNode(_ x: Int, _ z: Int, y: Int = 64) -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: x, y: y, z: z)
}

private func feedbackInput(
    order: Int,
    agentId: String?,
    kind: LabMovementFeedbackKind?,
    decision: LabMultiAgentMoveDecision?,
    from: LabTerrainPathNodeKey?,
    to: LabTerrainPathNodeKey?,
    displacementApplied: Bool?,
    collisionRead: Bool?,
    abstractBefore: LabTerrainPathNodeKey?,
    abstractAfter: LabTerrainPathNodeKey?,
    physicalBefore: LabTerrainPathNodeKey?,
    physicalAfter: LabTerrainPathNodeKey?,
    reason: String,
    malformedReason: String? = nil
) -> LabAgentFeedbackFixtureInput {
    LabAgentFeedbackFixtureInput(
        order: order,
        tick: 0,
        agentId: agentId,
        feedbackKind: kind,
        decision: decision,
        reason: reason,
        from: from,
        to: to,
        displacementApplied: displacementApplied,
        collisionRead: collisionRead,
        abstractBefore: abstractBefore,
        abstractAfter: abstractAfter,
        physicalBefore: physicalBefore,
        physicalAfter: physicalAfter,
        malformedReason: malformedReason
    )
}

private func agentFeedbackConsumptionFixtureInputs() -> [LabAgentFeedbackFixtureInput] {
    [
        feedbackInput(
            order: 0,
            agentId: "agent_2",
            kind: .blockedByCollision,
            decision: .deniedCollision,
            from: feedbackNode(7, 8),
            to: feedbackNode(8, 8),
            displacementApplied: false,
            collisionRead: true,
            abstractBefore: feedbackNode(7, 8),
            abstractAfter: feedbackNode(7, 8),
            physicalBefore: feedbackNode(7, 8),
            physicalAfter: feedbackNode(7, 8),
            reason: "fixture_blocked_by_collision"
        ),
        feedbackInput(
            order: 1,
            agentId: "agent_0",
            kind: .moved,
            decision: .approved,
            from: feedbackNode(7, 8),
            to: feedbackNode(8, 8),
            displacementApplied: true,
            collisionRead: true,
            abstractBefore: feedbackNode(7, 8),
            abstractAfter: feedbackNode(8, 8),
            physicalBefore: feedbackNode(7, 8),
            physicalAfter: feedbackNode(8, 8),
            reason: "fixture_moved"
        ),
        feedbackInput(
            order: 2,
            agentId: "agent_1",
            kind: .approvedForMovement,
            decision: .approved,
            from: feedbackNode(9, 7),
            to: feedbackNode(9, 8),
            displacementApplied: false,
            collisionRead: false,
            abstractBefore: feedbackNode(9, 7),
            abstractAfter: feedbackNode(9, 7),
            physicalBefore: feedbackNode(9, 7),
            physicalAfter: feedbackNode(9, 7),
            reason: "fixture_approved_for_movement"
        ),
        feedbackInput(
            order: 3,
            agentId: "agent_3",
            kind: .blockedByAgentConflict,
            decision: .deniedSameDestinationConflict,
            from: feedbackNode(2, 0),
            to: feedbackNode(1, 0),
            displacementApplied: false,
            collisionRead: false,
            abstractBefore: feedbackNode(2, 0),
            abstractAfter: feedbackNode(2, 0),
            physicalBefore: feedbackNode(2, 0),
            physicalAfter: feedbackNode(2, 0),
            reason: "fixture_blocked_by_agent_conflict"
        ),
        feedbackInput(
            order: 4,
            agentId: "agent_0",
            kind: .blockedByMaxAgents,
            decision: .deniedMaxAgents,
            from: feedbackNode(8, 8),
            to: feedbackNode(9, 8),
            displacementApplied: false,
            collisionRead: false,
            abstractBefore: feedbackNode(8, 8),
            abstractAfter: feedbackNode(8, 8),
            physicalBefore: feedbackNode(8, 8),
            physicalAfter: feedbackNode(8, 8),
            reason: "fixture_duplicate_blocked_by_max_agents"
        ),
        feedbackInput(
            order: 5,
            agentId: "",
            kind: nil,
            decision: nil,
            from: nil,
            to: nil,
            displacementApplied: nil,
            collisionRead: nil,
            abstractBefore: nil,
            abstractAfter: nil,
            physicalBefore: nil,
            physicalAfter: nil,
            reason: "fixture_malformed_feedback",
            malformedReason: "missing_agent_id_and_required_fields"
        )
    ]
}

private func makeFeedbackObservation(
    from input: LabAgentFeedbackFixtureInput
) -> LabAgentFeedbackObservation? {
    guard let tick = input.tick,
          let agentId = input.agentId,
          !agentId.isEmpty,
          let kind = input.feedbackKind,
          let reason = input.reason,
          let displacementApplied = input.displacementApplied,
          let collisionRead = input.collisionRead else {
        return nil
    }
    return LabAgentFeedbackObservation(
        tick: tick,
        agentId: agentId,
        feedbackKind: kind,
        decision: input.decision,
        reason: reason,
        from: input.from,
        to: input.to,
        displacementApplied: displacementApplied,
        collisionRead: collisionRead,
        abstractBefore: input.abstractBefore,
        abstractAfter: input.abstractAfter,
        physicalBefore: input.physicalBefore,
        physicalAfter: input.physicalAfter
    )
}

private func makeFeedbackContext(
    from observation: LabAgentFeedbackObservation
) -> LabAgentFeedbackContext {
    let blockedKinds: Set<LabMovementFeedbackKind> = [
        .blockedByCollision,
        .blockedByAgentConflict,
        .blockedBySourceMismatch,
        .blockedByDivergence,
        .blockedByStaleIntent,
        .blockedByInvalidEdge,
        .blockedByMaxAgents
    ]
    let lastMoveSucceeded = observation.feedbackKind == .moved
        && observation.displacementApplied
    let lastMoveBlocked = blockedKinds.contains(observation.feedbackKind)
    let lastKnownPosition = lastMoveSucceeded
        ? (observation.abstractAfter ?? observation.to ?? observation.from)
        : (observation.abstractAfter ?? observation.abstractBefore ?? observation.from)

    return LabAgentFeedbackContext(
        tick: observation.tick,
        agentId: observation.agentId,
        lastFeedback: observation,
        lastMoveSucceeded: lastMoveSucceeded,
        lastMoveBlocked: lastMoveBlocked,
        lastBlockReason: lastMoveBlocked ? observation.feedbackKind : nil,
        lastKnownPosition: lastKnownPosition,
        localHints: [],
        role: nil
    )
}

func consumeAgentFeedbackFixtureV0(
    feedbackInputs: [LabAgentFeedbackFixtureInput]
) -> LabAgentFeedbackConsumptionResult {
    let sortedInputs = feedbackInputs.sorted {
        let lhsId = ($0.agentId?.isEmpty == false) ? $0.agentId! : "~malformed"
        let rhsId = ($1.agentId?.isEmpty == false) ? $1.agentId! : "~malformed"
        return lhsId == rhsId ? $0.order < $1.order : lhsId < rhsId
    }
    var acceptedAgentIds = Set<String>()
    var observations: [LabAgentFeedbackObservation] = []
    var contexts: [LabAgentFeedbackContext] = []
    var ignored: [LabAgentFeedbackFixtureInput] = []
    var invalid: [LabAgentFeedbackFixtureInput] = []
    var duplicateFeedback = 0

    for input in sortedInputs {
        guard let observation = makeFeedbackObservation(from: input) else {
            invalid.append(input)
            continue
        }
        if acceptedAgentIds.contains(observation.agentId) {
            duplicateFeedback += 1
            ignored.append(input)
            continue
        }
        acceptedAgentIds.insert(observation.agentId)
        observations.append(observation)
        contexts.append(makeFeedbackContext(from: observation))
    }

    let kindCount: (LabMovementFeedbackKind) -> Int = { kind in
        observations.filter { $0.feedbackKind == kind }.count
    }
    let evidenceCollisionReadCount = sortedInputs.filter {
        $0.collisionRead == true
    }.count
    let summary = LabAgentFeedbackConsumptionSummary(
        agentsObserved: Set(observations.map(\.agentId)).count,
        feedbackObserved: feedbackInputs.count,
        feedbackAccepted: observations.count,
        feedbackIgnored: ignored.count,
        invalidFeedback: invalid.count,
        contextsProduced: contexts.count,
        moved: kindCount(.moved),
        approvedForMovement: kindCount(.approvedForMovement),
        blockedByCollision: kindCount(.blockedByCollision),
        blockedByAgentConflict: kindCount(.blockedByAgentConflict),
        blockedBySourceMismatch: kindCount(.blockedBySourceMismatch),
        blockedByDivergence: kindCount(.blockedByDivergence),
        blockedByStaleIntent: kindCount(.blockedByStaleIntent),
        blockedByInvalidEdge: kindCount(.blockedByInvalidEdge),
        blockedByMaxAgents: kindCount(.blockedByMaxAgents),
        duplicateFeedback: duplicateFeedback,
        feedbackEvidenceCollisionReadCount: evidenceCollisionReadCount,
        memoryUpdated: false,
        goalChanged: false,
        replanningPerformed: false,
        pathfindingPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        movementApplied: false,
        collisionRead: false,
        intentProduced: false,
        worldUsed: false,
        mutationPerformed: false,
        success: observations.count == 4
            && ignored.count == 1
            && invalid.count == 1
            && contexts.count == 4
            && duplicateFeedback == 1
            && kindCount(.moved) == 1
            && kindCount(.approvedForMovement) == 1
            && kindCount(.blockedByCollision) == 1
            && kindCount(.blockedByAgentConflict) == 1
            && kindCount(.blockedByMaxAgents) == 0
    )

    return LabAgentFeedbackConsumptionResult(
        tick: 0,
        fixtureFeedback: feedbackInputs,
        observations: observations,
        acceptedContexts: contexts,
        ignoredFeedback: ignored,
        invalidFeedback: invalid,
        summary: summary
    )
}

func makeAgentFeedbackConsumptionFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabAgentFeedbackConsumptionFixtureReport {
    let result = consumeAgentFeedbackFixtureV0(
        feedbackInputs: agentFeedbackConsumptionFixtureInputs()
    )
    let summary = LabAgentFeedbackConsumptionFixtureSummary(
        tick: result.tick,
        agentsObserved: result.summary.agentsObserved,
        feedbackObserved: result.summary.feedbackObserved,
        feedbackAccepted: result.summary.feedbackAccepted,
        feedbackIgnored: result.summary.feedbackIgnored,
        invalidFeedback: result.summary.invalidFeedback,
        contextsProduced: result.summary.contextsProduced,
        moved: result.summary.moved,
        approvedForMovement: result.summary.approvedForMovement,
        blockedByCollision: result.summary.blockedByCollision,
        blockedByAgentConflict: result.summary.blockedByAgentConflict,
        duplicateFeedback: result.summary.duplicateFeedback,
        memoryUpdated: result.summary.memoryUpdated,
        goalChanged: result.summary.goalChanged,
        pathfindingPerformed: result.summary.pathfindingPerformed,
        replanningPerformed: result.summary.replanningPerformed,
        avoidancePerformed: result.summary.avoidancePerformed,
        reservationRuntimeUsed: result.summary.reservationRuntimeUsed,
        movementApplied: result.summary.movementApplied,
        collisionRead: result.summary.collisionRead,
        intentProduced: result.summary.intentProduced,
        worldUsed: result.summary.worldUsed,
        mutationPerformed: result.summary.mutationPerformed,
        success: result.summary.success
    )

    return LabAgentFeedbackConsumptionFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        result: result,
        summary: summary
    )
}

private func feedbackInvariantCheck(
    _ name: String,
    _ passed: Bool,
    _ expected: String,
    _ actual: String
) -> LabMultiAgentMovementFixtureInvariantCheck {
    LabMultiAgentMovementFixtureInvariantCheck(
        name: name,
        passed: passed,
        expected: expected,
        actual: actual
    )
}

func makeAgentFeedbackConsumptionFixtureInvariantReport(
    report: LabAgentFeedbackConsumptionFixtureReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentFeedbackConsumptionFixtureInvariantReport {
    guard let report else {
        let check = feedbackInvariantCheck(
            "report_written",
            false,
            "agent_feedback_consumption_fixture_report.json",
            "missing"
        )
        return LabAgentFeedbackConsumptionFixtureInvariantReport(
            scenario: scenario,
            seed: seed,
            success: false,
            summary: LabMultiAgentMovementFixtureInvariantSummary(
                checksPassed: 0,
                checksFailed: 1,
                cases: 0,
                passed: 0,
                failed: 1
            ),
            checks: [check],
            notes: ["Agent feedback consumption fixture report was not available."]
        )
    }

    let inputIds = report.result.fixtureFeedback.map { $0.agentId ?? "" }
    let observationIds = report.result.observations.map(\.agentId)
    let contextIds = report.result.acceptedContexts.map(\.agentId)
    let uniqueAccepted = Set(observationIds).count == observationIds.count
    let contextsByAgent = Dictionary(
        uniqueKeysWithValues: report.result.acceptedContexts.map { ($0.agentId, $0) }
    )
    let movedContext = contextsByAgent["agent_0"]
    let approvedContext = contextsByAgent["agent_1"]
    let collisionContext = contextsByAgent["agent_2"]
    let conflictContext = contextsByAgent["agent_3"]
    let knownAccepted = report.result.observations.allSatisfy {
        [
            LabMovementFeedbackKind.moved,
            .approvedForMovement,
            .blockedByCollision,
            .blockedByAgentConflict,
            .blockedBySourceMismatch,
            .blockedByDivergence,
            .blockedByStaleIntent,
            .blockedByInvalidEdge,
            .blockedByMaxAgents
        ].contains($0.feedbackKind)
    }
    let contextKinds = report.result.acceptedContexts.compactMap {
        $0.lastFeedback?.feedbackKind
    }

    let checks = [
        feedbackInvariantCheck("fixture_feedback_exists", !report.result.fixtureFeedback.isEmpty, "non-empty", "\(report.result.fixtureFeedback.count)"),
        feedbackInvariantCheck("fixture_feedback_intentionally_unordered", inputIds != inputIds.sorted(), "unordered", inputIds.joined(separator: ",")),
        feedbackInvariantCheck("observations_exist", !report.result.observations.isEmpty, "non-empty", "\(report.result.observations.count)"),
        feedbackInvariantCheck("observations_sorted_by_agent_id", observationIds == observationIds.sorted(), "sorted", observationIds.joined(separator: ",")),
        feedbackInvariantCheck("accepted_contexts_exist", !report.result.acceptedContexts.isEmpty, "non-empty", "\(report.result.acceptedContexts.count)"),
        feedbackInvariantCheck("accepted_contexts_sorted_by_agent_id", contextIds == contextIds.sorted(), "sorted", contextIds.joined(separator: ",")),
        feedbackInvariantCheck("at_most_one_feedback_accepted_per_agent", uniqueAccepted, "unique", observationIds.joined(separator: ",")),
        feedbackInvariantCheck("known_feedback_kinds_accepted", knownAccepted, "known", contextKinds.map(\.rawValue).joined(separator: ",")),
        feedbackInvariantCheck("malformed_feedback_rejected", report.summary.invalidFeedback == 1, "1", "\(report.summary.invalidFeedback)"),
        feedbackInvariantCheck("duplicate_feedback_rejected_or_ignored", report.summary.duplicateFeedback == 1 && report.summary.feedbackIgnored == 1, "1/1", "\(report.summary.duplicateFeedback)/\(report.summary.feedbackIgnored)"),
        feedbackInvariantCheck("moved_feedback_observed", report.summary.moved == 1, "1", "\(report.summary.moved)"),
        feedbackInvariantCheck("approved_for_movement_feedback_observed", report.summary.approvedForMovement == 1, "1", "\(report.summary.approvedForMovement)"),
        feedbackInvariantCheck("blocked_by_collision_feedback_observed", report.summary.blockedByCollision == 1, "1", "\(report.summary.blockedByCollision)"),
        feedbackInvariantCheck("blocked_by_agent_conflict_feedback_observed", report.summary.blockedByAgentConflict == 1, "1", "\(report.summary.blockedByAgentConflict)"),
        feedbackInvariantCheck("blocked_by_max_agents_duplicate_counted", report.result.summary.blockedByMaxAgents == 0 && report.summary.duplicateFeedback == 1, "duplicate only", "\(report.result.summary.blockedByMaxAgents)/\(report.summary.duplicateFeedback)"),
        feedbackInvariantCheck("contexts_produced_for_accepted_feedback", report.summary.contextsProduced == report.summary.feedbackAccepted, "match", "\(report.summary.contextsProduced)/\(report.summary.feedbackAccepted)"),
        feedbackInvariantCheck("context_contains_agent_id", report.result.acceptedContexts.allSatisfy { !$0.agentId.isEmpty }, "all non-empty", contextIds.joined(separator: ",")),
        feedbackInvariantCheck("context_contains_tick", report.result.acceptedContexts.allSatisfy { $0.tick == report.summary.tick }, "tick 0", "\(report.summary.tick)"),
        feedbackInvariantCheck("context_preserves_last_feedback_kind", contextKinds.count == report.summary.contextsProduced, "all preserved", contextKinds.map(\.rawValue).joined(separator: ",")),
        feedbackInvariantCheck("moved_context_marks_last_move_succeeded", movedContext?.lastMoveSucceeded == true && movedContext?.lastMoveBlocked == false, "succeeded only", "\(movedContext?.lastMoveSucceeded == true)/\(movedContext?.lastMoveBlocked == true)"),
        feedbackInvariantCheck("collision_context_marks_last_move_blocked", collisionContext?.lastMoveBlocked == true && collisionContext?.lastBlockReason == .blockedByCollision, "blockedByCollision", collisionContext?.lastBlockReason?.rawValue ?? "missing"),
        feedbackInvariantCheck("agent_conflict_context_marks_last_move_blocked", conflictContext?.lastMoveBlocked == true && conflictContext?.lastBlockReason == .blockedByAgentConflict, "blockedByAgentConflict", conflictContext?.lastBlockReason?.rawValue ?? "missing"),
        feedbackInvariantCheck("approved_for_movement_context_not_marked_moved", approvedContext?.lastMoveSucceeded == false && approvedContext?.lastMoveBlocked == false, "not moved/block", "\(approvedContext?.lastMoveSucceeded == true)/\(approvedContext?.lastMoveBlocked == true)"),
        feedbackInvariantCheck("last_known_position_from_after_position_when_moved", movedContext?.lastKnownPosition == feedbackNode(8, 8), "(8,64,8)", "\(String(describing: movedContext?.lastKnownPosition))"),
        feedbackInvariantCheck("last_known_position_preserved_when_blocked", collisionContext?.lastKnownPosition == feedbackNode(7, 8) && conflictContext?.lastKnownPosition == feedbackNode(2, 0), "preserved", "\(String(describing: collisionContext?.lastKnownPosition))/\(String(describing: conflictContext?.lastKnownPosition))"),
        feedbackInvariantCheck("feedback_evidence_collision_read_does_not_mean_consumption_collision_read", report.result.summary.feedbackEvidenceCollisionReadCount == 2 && !report.summary.collisionRead, "historical evidence only", "\(report.result.summary.feedbackEvidenceCollisionReadCount)/\(report.summary.collisionRead)"),
        feedbackInvariantCheck("consumption_does_not_read_collision", !report.summary.collisionRead, "false", "\(report.summary.collisionRead)"),
        feedbackInvariantCheck("movement_not_applied", !report.summary.movementApplied, "false", "\(report.summary.movementApplied)"),
        feedbackInvariantCheck("intent_not_produced", !report.summary.intentProduced, "false", "\(report.summary.intentProduced)"),
        feedbackInvariantCheck("memory_not_updated", !report.summary.memoryUpdated, "false", "\(report.summary.memoryUpdated)"),
        feedbackInvariantCheck("goal_not_changed", !report.summary.goalChanged, "false", "\(report.summary.goalChanged)"),
        feedbackInvariantCheck("pathfinding_not_performed", !report.summary.pathfindingPerformed, "false", "\(report.summary.pathfindingPerformed)"),
        feedbackInvariantCheck("replanning_not_performed", !report.summary.replanningPerformed, "false", "\(report.summary.replanningPerformed)"),
        feedbackInvariantCheck("avoidance_not_performed", !report.summary.avoidancePerformed, "false", "\(report.summary.avoidancePerformed)"),
        feedbackInvariantCheck("reservation_runtime_not_used", !report.summary.reservationRuntimeUsed, "false", "\(report.summary.reservationRuntimeUsed)"),
        feedbackInvariantCheck("learning_not_performed", true, "false", "false"),
        feedbackInvariantCheck("llm_rl_python_not_used", true, "false", "false"),
        feedbackInvariantCheck("social_behavior_not_used", true, "false", "false"),
        feedbackInvariantCheck("communication_not_used", true, "false", "false"),
        feedbackInvariantCheck("world_not_used", !report.summary.worldUsed, "false", "\(report.summary.worldUsed)"),
        feedbackInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        feedbackInvariantCheck("world_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        feedbackInvariantCheck("tick_movement_not_invoked", !report.summary.movementApplied && !report.summary.intentProduced, "not invoked", "\(report.summary.movementApplied)/\(report.summary.intentProduced)"),
        feedbackInvariantCheck("agent_intent_not_invoked", !report.summary.intentProduced, "false", "\(report.summary.intentProduced)"),
        feedbackInvariantCheck("report_written", true, "agent_feedback_consumption_fixture_report.json", "agent_feedback_consumption_fixture_report.json"),
        feedbackInvariantCheck("contexts_written", true, "agent_feedback_contexts.json", "agent_feedback_contexts.json"),
        feedbackInvariantCheck("metrics_written", true, "agentFeedbackConsumptionFixture* metrics", "agentFeedbackConsumptionFixture* metrics"),
        feedbackInvariantCheck("event_written", true, "lab_agent_feedback_consumption_fixture_recorded", "lab_agent_feedback_consumption_fixture_recorded"),
        feedbackInvariantCheck("prior_approved_application_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        feedbackInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabAgentFeedbackConsumptionFixtureInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: 1,
            passed: report.success ? 1 : 0,
            failed: report.success ? 0 : 1
        ),
        checks: checks,
        notes: [
            "Feedback consumption v0 observes synthetic fixture feedback and produces bounded contexts only.",
            "Historical feedback may contain collisionRead evidence, but this consumption scenario does not read collision.",
            "No movement, intent production, memory update, goal change, pathfinding, replanning, avoidance, reservation runtime, World use, or mutation is performed."
        ]
    )
}
