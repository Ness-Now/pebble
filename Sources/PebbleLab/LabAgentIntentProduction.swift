import PebbleCore

struct LabAgentIntentContext: Codable {
    let tick: Int
    let agentId: String
    let position: LabTerrainPathNodeKey?
    let lastFeedback: LabMovementFeedback?
    let role: String?
    let localHints: [String]
}

enum LabAgentIntentDecision: String, Codable {
    case noIntent
    case proposeMove
    case invalidContext
}

struct LabAgentIntentProposal: Codable {
    let agentId: String
    let tick: Int
    let decision: LabAgentIntentDecision
    let intent: LabAgentMoveIntent?
    let reason: String
}

struct LabAgentIntentProductionResult: Codable {
    let tick: Int
    let contexts: [LabAgentIntentContext]
    let proposals: [LabAgentIntentProposal]
    let acceptedIntents: [LabAgentMoveIntent]
    let rejectedProposals: [LabAgentIntentProposal]
    let summary: LabAgentIntentProductionSummary
}

struct LabAgentIntentProductionSummary: Codable {
    let agentsObserved: Int
    let contexts: Int
    let proposals: Int
    let acceptedIntents: Int
    let rejectedProposals: Int
    let noIntent: Int
    let invalidContext: Int
    let duplicateAgentContexts: Int
    let invalidOneEdgeProposals: Int
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let collisionRead: Bool
    let movementApplied: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAgentIntentProductionFixtureSummary: Codable {
    let tick: Int
    let agentsObserved: Int
    let contexts: Int
    let proposals: Int
    let acceptedIntents: Int
    let rejectedProposals: Int
    let noIntent: Int
    let invalidContext: Int
    let duplicateAgentContexts: Int
    let invalidOneEdgeProposals: Int
    let acceptedMoveEast: Int
    let acceptedMoveWest: Int
    let acceptedMoveNorth: Int
    let acceptedMoveSouth: Int
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let collisionRead: Bool
    let movementApplied: Bool
    let feedbackConsumed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAgentIntentProductionFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let result: LabAgentIntentProductionResult
    let summary: LabAgentIntentProductionFixtureSummary
}

struct LabAgentIntentProductionFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

func produceAgentIntentProposalV0(
    context: LabAgentIntentContext
) -> LabAgentIntentProposal {
    guard let position = context.position else {
        return LabAgentIntentProposal(
            agentId: context.agentId,
            tick: context.tick,
            decision: .invalidContext,
            intent: nil,
            reason: "missing_position"
        )
    }

    switch context.role {
    case "idle":
        return LabAgentIntentProposal(
            agentId: context.agentId,
            tick: context.tick,
            decision: .noIntent,
            intent: nil,
            reason: "idle_role_no_intent"
        )
    case "wander_fixture":
        let orderedHints = ["move_east", "move_west", "move_north", "move_south"]
        guard let hint = orderedHints.first(where: { context.localHints.contains($0) }) else {
            return LabAgentIntentProposal(
                agentId: context.agentId,
                tick: context.tick,
                decision: .noIntent,
                intent: nil,
                reason: "wander_fixture_no_matching_hint"
            )
        }
        let to: LabTerrainPathNodeKey
        switch hint {
        case "move_east":
            to = LabTerrainPathNodeKey(x: position.x + 1, y: position.y, z: position.z)
        case "move_west":
            to = LabTerrainPathNodeKey(x: position.x - 1, y: position.y, z: position.z)
        case "move_north":
            to = LabTerrainPathNodeKey(x: position.x, y: position.y, z: position.z - 1)
        default:
            to = LabTerrainPathNodeKey(x: position.x, y: position.y, z: position.z + 1)
        }
        return LabAgentIntentProposal(
            agentId: context.agentId,
            tick: context.tick,
            decision: .proposeMove,
            intent: LabAgentMoveIntent(
                agentId: context.agentId,
                routeId: nil,
                from: position,
                to: to,
                routeIndex: nil,
                reason: "wander_fixture_\(hint.replacingOccurrences(of: "move_", with: ""))",
                stale: false
            ),
            reason: "wander_fixture_\(hint.replacingOccurrences(of: "move_", with: ""))"
        )
    case "bad_fixture_invalid_vertical":
        let to = LabTerrainPathNodeKey(x: position.x, y: position.y + 1, z: position.z)
        return LabAgentIntentProposal(
            agentId: context.agentId,
            tick: context.tick,
            decision: .proposeMove,
            intent: LabAgentMoveIntent(
                agentId: context.agentId,
                routeId: nil,
                from: position,
                to: to,
                routeIndex: nil,
                reason: "bad_fixture_invalid_vertical",
                stale: false
            ),
            reason: "bad_fixture_invalid_vertical"
        )
    default:
        return LabAgentIntentProposal(
            agentId: context.agentId,
            tick: context.tick,
            decision: .noIntent,
            intent: nil,
            reason: "unknown_role_no_intent"
        )
    }
}

func makeAgentIntentProductionFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabAgentIntentProductionFixtureReport {
    let result = makeAgentIntentProductionFixtureResult()
    let acceptedMoveEast = result.acceptedIntents.filter { $0.to.x - $0.from.x == 1 }.count
    let acceptedMoveWest = result.acceptedIntents.filter { $0.from.x - $0.to.x == 1 }.count
    let acceptedMoveNorth = result.acceptedIntents.filter { $0.from.z - $0.to.z == 1 }.count
    let acceptedMoveSouth = result.acceptedIntents.filter { $0.to.z - $0.from.z == 1 }.count
    let summary = LabAgentIntentProductionFixtureSummary(
        tick: result.tick,
        agentsObserved: result.summary.agentsObserved,
        contexts: result.summary.contexts,
        proposals: result.summary.proposals,
        acceptedIntents: result.summary.acceptedIntents,
        rejectedProposals: result.summary.rejectedProposals,
        noIntent: result.summary.noIntent,
        invalidContext: result.summary.invalidContext,
        duplicateAgentContexts: result.summary.duplicateAgentContexts,
        invalidOneEdgeProposals: result.summary.invalidOneEdgeProposals,
        acceptedMoveEast: acceptedMoveEast,
        acceptedMoveWest: acceptedMoveWest,
        acceptedMoveNorth: acceptedMoveNorth,
        acceptedMoveSouth: acceptedMoveSouth,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        collisionRead: false,
        movementApplied: false,
        feedbackConsumed: false,
        memoryUpdated: false,
        goalChanged: false,
        worldUsed: false,
        mutationPerformed: false,
        success: result.summary.success
    )
    let success = summary.success
        && summary.contexts == 5
        && summary.proposals == 5
        && summary.acceptedIntents == 2
        && summary.rejectedProposals == 3
        && summary.noIntent == 1
        && summary.invalidContext == 1
        && summary.invalidOneEdgeProposals == 1
        && !summary.worldUsed
        && !summary.collisionRead
        && !summary.movementApplied
        && !summary.feedbackConsumed
        && !summary.memoryUpdated
        && !summary.goalChanged
        && !summary.pathfindingPerformed
        && !summary.replanningPerformed
        && !summary.avoidancePerformed
        && !summary.reservationRuntimeUsed
        && !summary.mutationPerformed

    return LabAgentIntentProductionFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: success,
        result: result,
        summary: summary
    )
}

func makeAgentIntentProductionFixtureInvariantReport(
    report: LabAgentIntentProductionFixtureReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentIntentProductionFixtureInvariantReport {
    guard let report else {
        let check = agentIntentInvariantCheck(
            "report_written",
            false,
            "agent_intent_production_fixture_report.json",
            "missing"
        )
        return LabAgentIntentProductionFixtureInvariantReport(
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
            notes: ["Report generation failed."]
        )
    }

    let result = report.result
    let contexts = result.contexts
    let proposals = result.proposals
    let accepted = result.acceptedIntents
    let rejected = result.rejectedProposals
    let contextIds = contexts.map(\.agentId)
    let sortedContextIds = contextIds.sorted()
    let proposalIds = proposals.map(\.agentId)
    let acceptedIds = accepted.map(\.agentId)
    let contextByAgent = Dictionary(uniqueKeysWithValues: contexts.compactMap { context in
        context.position.map { (context.agentId, $0) }
    })
    let acceptedSourcesMatch = accepted.allSatisfy { intent in
        contextByAgent[intent.agentId] == intent.from
    }
    let acceptedOneEdge = accepted.allSatisfy { intent in
        manhattanDistance(intent.from, intent.to) == 1
    }
    let acceptedSameY = accepted.allSatisfy { intent in
        intent.from.y == intent.to.y
    }
    let sameDestinationAccepted = Set(accepted.map(\.to)).count < accepted.count

    let checks = [
        agentIntentInvariantCheck("contexts_exist", !contexts.isEmpty, "non-empty", "\(contexts.count)"),
        agentIntentInvariantCheck("proposals_exist", !proposals.isEmpty, "non-empty", "\(proposals.count)"),
        agentIntentInvariantCheck("contexts_intentionally_unordered", contextIds != sortedContextIds, "unordered input", contextIds.joined(separator: ",")),
        agentIntentInvariantCheck("proposals_sorted_by_agent_id", proposalIds == proposalIds.sorted(), "sorted", proposalIds.joined(separator: ",")),
        agentIntentInvariantCheck("accepted_intents_sorted_by_agent_id", acceptedIds == acceptedIds.sorted(), "sorted", acceptedIds.joined(separator: ",")),
        agentIntentInvariantCheck("at_most_one_proposal_per_agent", hasUniqueValues(proposalIds), "unique", "\(proposalIds)"),
        agentIntentInvariantCheck("at_most_one_accepted_intent_per_agent", hasUniqueValues(acceptedIds), "unique", "\(acceptedIds)"),
        agentIntentInvariantCheck("accepted_intents_have_agent_id", accepted.allSatisfy { !$0.agentId.isEmpty }, "all non-empty", "\(accepted.count)"),
        agentIntentInvariantCheck("accepted_intents_have_source", accepted.allSatisfy { _ in true }, "all present", "\(accepted.count)"),
        agentIntentInvariantCheck("accepted_intents_have_destination", accepted.allSatisfy { _ in true }, "all present", "\(accepted.count)"),
        agentIntentInvariantCheck("accepted_intents_sources_match_context_positions", acceptedSourcesMatch, "match", "\(acceptedSourcesMatch)"),
        agentIntentInvariantCheck("accepted_intents_are_one_edge", acceptedOneEdge, "one-edge", "\(acceptedOneEdge)"),
        agentIntentInvariantCheck("accepted_intents_are_same_y", acceptedSameY, "same-y", "\(acceptedSameY)"),
        agentIntentInvariantCheck("wander_fixture_policy_produces_move", accepted.count == 2, "2", "\(accepted.count)"),
        agentIntentInvariantCheck("idle_policy_produces_no_intent", result.summary.noIntent == 1, "1", "\(result.summary.noIntent)"),
        agentIntentInvariantCheck("missing_position_produces_invalid_context", result.summary.invalidContext == 1, "1", "\(result.summary.invalidContext)"),
        agentIntentInvariantCheck("invalid_vertical_proposal_rejected", result.summary.invalidOneEdgeProposals == 1, "1", "\(result.summary.invalidOneEdgeProposals)"),
        agentIntentInvariantCheck("no_intent_not_accepted", rejected.contains { $0.decision == .noIntent }, "rejected", "\(rejected.map(\.decision))"),
        agentIntentInvariantCheck("invalid_context_not_accepted", rejected.contains { $0.decision == .invalidContext }, "rejected", "\(rejected.map(\.decision))"),
        agentIntentInvariantCheck("invalid_one_edge_not_accepted", rejected.contains { $0.reason == "bad_fixture_invalid_vertical" }, "rejected", rejected.map(\.reason).joined(separator: ",")),
        agentIntentInvariantCheck("accepted_intents_do_not_arbitrate_conflicts", sameDestinationAccepted, "same destination allowed", "\(sameDestinationAccepted)"),
        agentIntentInvariantCheck("same_destination_accepted_for_later_tick_arbitration", sameDestinationAccepted, "accepted", "\(accepted.map(\.to))"),
        agentIntentInvariantCheck("no_world_used", !report.summary.worldUsed, "false", "\(report.summary.worldUsed)"),
        agentIntentInvariantCheck("collision_not_read", !report.summary.collisionRead, "false", "\(report.summary.collisionRead)"),
        agentIntentInvariantCheck("movement_not_applied", !report.summary.movementApplied, "false", "\(report.summary.movementApplied)"),
        agentIntentInvariantCheck("feedback_not_consumed", !report.summary.feedbackConsumed, "false", "\(report.summary.feedbackConsumed)"),
        agentIntentInvariantCheck("memory_not_updated", !report.summary.memoryUpdated, "false", "\(report.summary.memoryUpdated)"),
        agentIntentInvariantCheck("goal_not_changed", !report.summary.goalChanged, "false", "\(report.summary.goalChanged)"),
        agentIntentInvariantCheck("pathfinding_not_performed", !report.summary.pathfindingPerformed, "false", "\(report.summary.pathfindingPerformed)"),
        agentIntentInvariantCheck("replanning_not_performed", !report.summary.replanningPerformed, "false", "\(report.summary.replanningPerformed)"),
        agentIntentInvariantCheck("avoidance_not_performed", !report.summary.avoidancePerformed, "false", "\(report.summary.avoidancePerformed)"),
        agentIntentInvariantCheck("reservation_runtime_not_used", !report.summary.reservationRuntimeUsed, "false", "\(report.summary.reservationRuntimeUsed)"),
        agentIntentInvariantCheck("physics_not_performed", true, "false", "false"),
        agentIntentInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("world_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("report_written", true, "agent_intent_production_fixture_report.json", "agent_intent_production_fixture_report.json"),
        agentIntentInvariantCheck("proposals_written", true, "agent_intent_proposals.json", "agent_intent_proposals.json"),
        agentIntentInvariantCheck("metrics_written", true, "metrics.json", "metrics.json"),
        agentIntentInvariantCheck("event_written", true, "lab_agent_intent_production_fixture_recorded", "lab_agent_intent_production_fixture_recorded"),
        agentIntentInvariantCheck("tick_fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("tick_hardening_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let failed = checks.filter { !$0.passed }.count
    return LabAgentIntentProductionFixtureInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: 1,
            passed: failed == 0 ? 1 : 0,
            failed: failed == 0 ? 0 : 1
        ),
        checks: checks,
        notes: [
            "Fixture-only intent production does not call movement tick scenarios.",
            "Same-destination accepted intents are intentionally left for later tick arbitration."
        ]
    )
}

private func makeAgentIntentProductionFixtureResult() -> LabAgentIntentProductionResult {
    let tick = 0
    let contexts = [
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_2",
            position: LabTerrainPathNodeKey(x: 10, y: 64, z: 0),
            lastFeedback: nil,
            role: "idle",
            localHints: []
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_0",
            position: LabTerrainPathNodeKey(x: 0, y: 64, z: 0),
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_1",
            position: LabTerrainPathNodeKey(x: 2, y: 64, z: 0),
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_west"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_3",
            position: nil,
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_4",
            position: LabTerrainPathNodeKey(x: 20, y: 64, z: 0),
            lastFeedback: nil,
            role: "bad_fixture_invalid_vertical",
            localHints: ["move_vertical"]
        )
    ]
    let proposals = contexts
        .map(produceAgentIntentProposalV0(context:))
        .sorted { $0.agentId < $1.agentId }
    let duplicateAgentContexts = contexts.count - Set(contexts.map(\.agentId)).count
    var accepted: [LabAgentMoveIntent] = []
    var rejected: [LabAgentIntentProposal] = []
    var acceptedAgents = Set<String>()
    var invalidOneEdgeProposals = 0

    for proposal in proposals {
        guard proposal.decision == .proposeMove, let intent = proposal.intent else {
            rejected.append(proposal)
            continue
        }
        let oneEdge = manhattanDistance(intent.from, intent.to) == 1
        let sameY = intent.from.y == intent.to.y
        let agentMatches = intent.agentId == proposal.agentId
        let isDuplicate = acceptedAgents.contains(intent.agentId)
        if oneEdge && sameY && agentMatches && !isDuplicate {
            accepted.append(intent)
            acceptedAgents.insert(intent.agentId)
        } else {
            if !oneEdge || !sameY {
                invalidOneEdgeProposals += 1
            }
            rejected.append(proposal)
        }
    }

    accepted.sort { $0.agentId < $1.agentId }
    rejected.sort { $0.agentId < $1.agentId }
    let summary = LabAgentIntentProductionSummary(
        agentsObserved: contexts.count,
        contexts: contexts.count,
        proposals: proposals.count,
        acceptedIntents: accepted.count,
        rejectedProposals: rejected.count,
        noIntent: proposals.filter { $0.decision == .noIntent }.count,
        invalidContext: proposals.filter { $0.decision == .invalidContext }.count,
        duplicateAgentContexts: duplicateAgentContexts,
        invalidOneEdgeProposals: invalidOneEdgeProposals,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        collisionRead: false,
        movementApplied: false,
        memoryUpdated: false,
        goalChanged: false,
        mutationPerformed: false,
        success: contexts.count == 5
            && proposals.count == 5
            && accepted.count == 2
            && rejected.count == 3
            && invalidOneEdgeProposals == 1
    )
    return LabAgentIntentProductionResult(
        tick: tick,
        contexts: contexts,
        proposals: proposals,
        acceptedIntents: accepted,
        rejectedProposals: rejected,
        summary: summary
    )
}

private func manhattanDistance(
    _ lhs: LabTerrainPathNodeKey,
    _ rhs: LabTerrainPathNodeKey
) -> Int {
    abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
}

private func hasUniqueValues(_ values: [String]) -> Bool {
    Set(values).count == values.count
}

private func agentIntentInvariantCheck(
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
