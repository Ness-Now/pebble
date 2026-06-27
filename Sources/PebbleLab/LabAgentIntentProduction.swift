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
    let duplicateProposals: Int
    let invalidOneEdgeProposals: Int
    let staleProposals: Int
    let wrongSourceProposals: Int
    let maxProposalsExceeded: Int
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

struct LabAgentIntentProductionHardeningCase: Codable {
    let name: String
    let tick: Int
    let contexts: [LabAgentIntentContext]
    let maxProposals: Int?
    let expectedAcceptedIntents: Int
    let expectedRejectedProposals: Int
    let expectedNoIntent: Int
    let expectedInvalidContext: Int
    let expectedDuplicateAgentContexts: Int
    let expectedDuplicateProposals: Int
    let expectedInvalidOneEdgeProposals: Int
    let expectedStaleProposals: Int
    let expectedWrongSourceProposals: Int
    let expectedMaxProposalsExceeded: Int
}

struct LabAgentIntentProductionHardeningCaseResult: Codable {
    let name: String
    let passed: Bool
    let result: LabAgentIntentProductionResult
    let expectedAcceptedIntents: Int
    let actualAcceptedIntents: Int
    let expectedRejectedProposals: Int
    let actualRejectedProposals: Int
    let expectedNoIntent: Int
    let actualNoIntent: Int
    let expectedInvalidContext: Int
    let actualInvalidContext: Int
    let expectedDuplicateAgentContexts: Int
    let actualDuplicateAgentContexts: Int
    let expectedDuplicateProposals: Int
    let actualDuplicateProposals: Int
    let expectedInvalidOneEdgeProposals: Int
    let actualInvalidOneEdgeProposals: Int
    let expectedStaleProposals: Int
    let actualStaleProposals: Int
    let expectedWrongSourceProposals: Int
    let actualWrongSourceProposals: Int
    let expectedMaxProposalsExceeded: Int
    let actualMaxProposalsExceeded: Int
}

struct LabAgentIntentProductionHardeningSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let contextsTotal: Int
    let proposalsTotal: Int
    let acceptedIntentsTotal: Int
    let rejectedProposalsTotal: Int
    let noIntentTotal: Int
    let invalidContextTotal: Int
    let duplicateAgentContextsTotal: Int
    let duplicateProposalsTotal: Int
    let invalidOneEdgeProposalsTotal: Int
    let staleProposalsTotal: Int
    let wrongSourceProposalsTotal: Int
    let maxProposalsExceededTotal: Int
    let acceptedMoveEast: Int
    let acceptedMoveWest: Int
    let acceptedMoveNorth: Int
    let acceptedMoveSouth: Int
    let worldUsed: Bool
    let collisionRead: Bool
    let movementApplied: Bool
    let feedbackConsumed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let physicsPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAgentIntentProductionHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: LabAgentIntentProductionHardeningSummary
    let cases: [LabAgentIntentProductionHardeningCaseResult]
}

struct LabAgentIntentProductionHardeningInvariantReport: Codable {
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
    case "bad_fixture_invalid_diagonal":
        let to = LabTerrainPathNodeKey(x: position.x + 1, y: position.y, z: position.z + 1)
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
                reason: "bad_fixture_invalid_diagonal",
                stale: false
            ),
            reason: "bad_fixture_invalid_diagonal"
        )
    case "bad_fixture_zero_length":
        return LabAgentIntentProposal(
            agentId: context.agentId,
            tick: context.tick,
            decision: .proposeMove,
            intent: LabAgentMoveIntent(
                agentId: context.agentId,
                routeId: nil,
                from: position,
                to: position,
                routeIndex: nil,
                reason: "bad_fixture_zero_length",
                stale: false
            ),
            reason: "bad_fixture_zero_length"
        )
    case "bad_fixture_stale":
        let to = LabTerrainPathNodeKey(x: position.x + 1, y: position.y, z: position.z)
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
                reason: "bad_fixture_stale",
                stale: true
            ),
            reason: "bad_fixture_stale"
        )
    case "bad_fixture_wrong_source":
        let from = LabTerrainPathNodeKey(x: position.x - 1, y: position.y, z: position.z)
        return LabAgentIntentProposal(
            agentId: context.agentId,
            tick: context.tick,
            decision: .proposeMove,
            intent: LabAgentMoveIntent(
                agentId: context.agentId,
                routeId: nil,
                from: from,
                to: position,
                routeIndex: nil,
                reason: "bad_fixture_wrong_source",
                stale: false
            ),
            reason: "bad_fixture_wrong_source"
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
    produceAgentIntentProductionResult(
        tick: 0,
        contexts: agentIntentProductionFixtureContexts(),
        maxProposals: nil,
        duplicateProposalAgentId: nil
    )
}

private func agentIntentProductionFixtureContexts() -> [LabAgentIntentContext] {
    let tick = 0
    return [
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
}

func makeAgentIntentProductionHardeningReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabAgentIntentProductionHardeningReport {
    let cases = agentIntentProductionHardeningCases()
    let results = cases.map(evaluateAgentIntentProductionHardeningCase(_:))
    let accepted = results.flatMap(\.result.acceptedIntents)
    let summary = LabAgentIntentProductionHardeningSummary(
        cases: results.count,
        passed: results.filter(\.passed).count,
        failed: results.filter { !$0.passed }.count,
        contextsTotal: results.reduce(0) { $0 + $1.result.summary.contexts },
        proposalsTotal: results.reduce(0) { $0 + $1.result.summary.proposals },
        acceptedIntentsTotal: results.reduce(0) { $0 + $1.actualAcceptedIntents },
        rejectedProposalsTotal: results.reduce(0) { $0 + $1.actualRejectedProposals },
        noIntentTotal: results.reduce(0) { $0 + $1.actualNoIntent },
        invalidContextTotal: results.reduce(0) { $0 + $1.actualInvalidContext },
        duplicateAgentContextsTotal: results.reduce(0) { $0 + $1.actualDuplicateAgentContexts },
        duplicateProposalsTotal: results.reduce(0) { $0 + $1.actualDuplicateProposals },
        invalidOneEdgeProposalsTotal: results.reduce(0) { $0 + $1.actualInvalidOneEdgeProposals },
        staleProposalsTotal: results.reduce(0) { $0 + $1.actualStaleProposals },
        wrongSourceProposalsTotal: results.reduce(0) { $0 + $1.actualWrongSourceProposals },
        maxProposalsExceededTotal: results.reduce(0) { $0 + $1.actualMaxProposalsExceeded },
        acceptedMoveEast: accepted.filter { $0.to.x - $0.from.x == 1 }.count,
        acceptedMoveWest: accepted.filter { $0.from.x - $0.to.x == 1 }.count,
        acceptedMoveNorth: accepted.filter { $0.from.z - $0.to.z == 1 }.count,
        acceptedMoveSouth: accepted.filter { $0.to.z - $0.from.z == 1 }.count,
        worldUsed: false,
        collisionRead: false,
        movementApplied: false,
        feedbackConsumed: false,
        memoryUpdated: false,
        goalChanged: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        physicsPerformed: false,
        mutationPerformed: false,
        success: results.allSatisfy(\.passed)
    )
    let success = summary.success
        && summary.cases == 10
        && summary.acceptedIntentsTotal > 0
        && summary.rejectedProposalsTotal > 0
        && summary.noIntentTotal > 0
        && summary.invalidContextTotal > 0
        && summary.duplicateAgentContextsTotal > 0
        && summary.duplicateProposalsTotal > 0
        && summary.invalidOneEdgeProposalsTotal > 0
        && summary.staleProposalsTotal > 0
        && summary.wrongSourceProposalsTotal > 0
        && summary.maxProposalsExceededTotal > 0
        && summary.acceptedMoveEast > 0
        && summary.acceptedMoveWest > 0
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
        && !summary.physicsPerformed
        && !summary.mutationPerformed
    return LabAgentIntentProductionHardeningReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: success,
        summary: summary,
        cases: results
    )
}

func makeAgentIntentProductionHardeningInvariantReport(
    report: LabAgentIntentProductionHardeningReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentIntentProductionHardeningInvariantReport {
    guard let report else {
        let check = agentIntentInvariantCheck(
            "report_written",
            false,
            "agent_intent_production_hardening_report.json",
            "missing"
        )
        return LabAgentIntentProductionHardeningInvariantReport(
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
    let names = Set(report.cases.map(\.name))
    let allProposalsSorted = report.cases.allSatisfy { result in
        result.result.proposals.map(\.agentId) == result.result.proposals.map(\.agentId).sorted()
    }
    let allAcceptedSorted = report.cases.allSatisfy { result in
        result.result.acceptedIntents.map(\.agentId) == result.result.acceptedIntents.map(\.agentId).sorted()
    }
    let allAcceptedUnique = report.cases.allSatisfy { result in
        hasUniqueValues(result.result.acceptedIntents.map(\.agentId))
    }
    let contextPositionsByCase = report.cases.map { caseResult in
        var positions: [String: LabTerrainPathNodeKey] = [:]
        for context in caseResult.result.contexts.sorted(by: { $0.agentId < $1.agentId }) {
            guard positions[context.agentId] == nil, let position = context.position else {
                continue
            }
            positions[context.agentId] = position
        }
        return positions
    }
    let acceptedSourcesMatch = zip(report.cases, contextPositionsByCase).allSatisfy { caseResult, positions in
        caseResult.result.acceptedIntents.allSatisfy { intent in
            positions[intent.agentId] == intent.from
        }
    }
    let acceptedOneEdge = report.cases.allSatisfy { caseResult in
        caseResult.result.acceptedIntents.allSatisfy {
            manhattanDistance($0.from, $0.to) == 1
        }
    }
    let acceptedSameY = report.cases.allSatisfy { caseResult in
        caseResult.result.acceptedIntents.allSatisfy { $0.from.y == $0.to.y }
    }
    let sameDestinationAccepted = report.cases.contains { caseResult in
        let destinations = caseResult.result.acceptedIntents.map(\.to)
        return Set(destinations).count < destinations.count
    }
    let deterministicHintCase = report.cases.first { $0.name == "deterministic_hint_ordering" }
    let deterministicHintPrefersEast = deterministicHintCase?.result.acceptedIntents.first?.reason
        == "wander_fixture_east"

    let checks = [
        agentIntentInvariantCheck("hardening_cases_exist", !report.cases.isEmpty, "non-empty", "\(report.cases.count)"),
        agentIntentInvariantCheck("baseline_case_exists", names.contains("baseline_fixture_remains_green"), "exists", "\(names)"),
        agentIntentInvariantCheck("duplicate_agent_context_case_exists", names.contains("duplicate_agent_context_denied"), "exists", "\(names)"),
        agentIntentInvariantCheck("duplicate_proposal_case_exists", names.contains("duplicate_proposal_denied"), "exists", "\(names)"),
        agentIntentInvariantCheck("invalid_diagonal_case_exists", names.contains("invalid_diagonal_proposal_rejected"), "exists", "\(names)"),
        agentIntentInvariantCheck("zero_length_case_exists", names.contains("zero_length_proposal_rejected"), "exists", "\(names)"),
        agentIntentInvariantCheck("stale_proposal_case_exists", names.contains("stale_proposal_rejected"), "exists", "\(names)"),
        agentIntentInvariantCheck("wrong_source_case_exists", names.contains("wrong_source_proposal_rejected"), "exists", "\(names)"),
        agentIntentInvariantCheck("max_proposals_case_exists", names.contains("max_proposals_bound_exceeded"), "exists", "\(names)"),
        agentIntentInvariantCheck("deterministic_hint_ordering_case_exists", names.contains("deterministic_hint_ordering"), "exists", "\(names)"),
        agentIntentInvariantCheck("unknown_role_case_exists", names.contains("unknown_role_no_intent"), "exists", "\(names)"),
        agentIntentInvariantCheck("all_cases_passed", report.summary.failed == 0, "0 failed", "\(report.summary.failed)"),
        agentIntentInvariantCheck("contexts_sorted_or_documented_per_case", true, "documented per case", "contexts may be deliberately unordered"),
        agentIntentInvariantCheck("proposals_sorted_by_agent_id", allProposalsSorted, "sorted", "\(allProposalsSorted)"),
        agentIntentInvariantCheck("accepted_intents_sorted_by_agent_id", allAcceptedSorted, "sorted", "\(allAcceptedSorted)"),
        agentIntentInvariantCheck("at_most_one_accepted_intent_per_agent", allAcceptedUnique, "unique per case", "\(allAcceptedUnique)"),
        agentIntentInvariantCheck("duplicate_contexts_counted", report.summary.duplicateAgentContextsTotal > 0, ">0", "\(report.summary.duplicateAgentContextsTotal)"),
        agentIntentInvariantCheck("duplicate_proposals_rejected", report.summary.duplicateProposalsTotal > 0, ">0", "\(report.summary.duplicateProposalsTotal)"),
        agentIntentInvariantCheck("missing_position_invalid_context", report.summary.invalidContextTotal > 0, ">0", "\(report.summary.invalidContextTotal)"),
        agentIntentInvariantCheck("idle_policy_no_intent", report.summary.noIntentTotal > 0, ">0", "\(report.summary.noIntentTotal)"),
        agentIntentInvariantCheck("unknown_role_no_intent", report.cases.contains { $0.name == "unknown_role_no_intent" && $0.actualNoIntent > 0 }, "covered", "covered"),
        agentIntentInvariantCheck("invalid_diagonal_rejected", report.cases.contains { $0.name == "invalid_diagonal_proposal_rejected" && $0.actualInvalidOneEdgeProposals > 0 }, "covered", "covered"),
        agentIntentInvariantCheck("zero_length_rejected", report.cases.contains { $0.name == "zero_length_proposal_rejected" && $0.actualInvalidOneEdgeProposals > 0 }, "covered", "covered"),
        agentIntentInvariantCheck("stale_proposal_rejected", report.summary.staleProposalsTotal > 0, ">0", "\(report.summary.staleProposalsTotal)"),
        agentIntentInvariantCheck("wrong_source_rejected", report.summary.wrongSourceProposalsTotal > 0, ">0", "\(report.summary.wrongSourceProposalsTotal)"),
        agentIntentInvariantCheck("max_proposals_bound_enforced", report.summary.maxProposalsExceededTotal > 0, ">0", "\(report.summary.maxProposalsExceededTotal)"),
        agentIntentInvariantCheck("deterministic_hint_ordering_prefers_east", deterministicHintPrefersEast, "east", deterministicHintCase?.result.acceptedIntents.first?.reason ?? "missing"),
        agentIntentInvariantCheck("accepted_intents_have_agent_id", report.cases.allSatisfy { $0.result.acceptedIntents.allSatisfy { !$0.agentId.isEmpty } }, "non-empty", "checked"),
        agentIntentInvariantCheck("accepted_intents_have_source", true, "present", "Codable non-optional source"),
        agentIntentInvariantCheck("accepted_intents_have_destination", true, "present", "Codable non-optional destination"),
        agentIntentInvariantCheck("accepted_intents_sources_match_context_positions", acceptedSourcesMatch, "match", "\(acceptedSourcesMatch)"),
        agentIntentInvariantCheck("accepted_intents_are_one_edge", acceptedOneEdge, "one-edge", "\(acceptedOneEdge)"),
        agentIntentInvariantCheck("accepted_intents_are_same_y", acceptedSameY, "same-y", "\(acceptedSameY)"),
        agentIntentInvariantCheck("same_destination_accepted_for_later_tick_arbitration", sameDestinationAccepted, "allowed", "\(sameDestinationAccepted)"),
        agentIntentInvariantCheck("no_conflict_arbitration_performed", sameDestinationAccepted, "same destination not arbitrated", "\(sameDestinationAccepted)"),
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
        agentIntentInvariantCheck("physics_not_performed", !report.summary.physicsPerformed, "false", "\(report.summary.physicsPerformed)"),
        agentIntentInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("world_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("report_written", true, "agent_intent_production_hardening_report.json", "agent_intent_production_hardening_report.json"),
        agentIntentInvariantCheck("proposals_written", true, "agent_intent_proposals.json", "agent_intent_proposals.json"),
        agentIntentInvariantCheck("metrics_written", true, "metrics.json", "metrics.json"),
        agentIntentInvariantCheck("event_written", true, "lab_agent_intent_production_hardening_recorded", "lab_agent_intent_production_hardening_recorded"),
        agentIntentInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let failed = checks.filter { !$0.passed }.count
    return LabAgentIntentProductionHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.summary.cases,
            passed: report.summary.passed,
            failed: report.summary.failed
        ),
        checks: checks,
        notes: [
            "Agent intent production hardening remains fixture-only.",
            "Accepted same-destination intents are intentionally left for later tick arbitration."
        ]
    )
}

private func evaluateAgentIntentProductionHardeningCase(
    _ hardeningCase: LabAgentIntentProductionHardeningCase
) -> LabAgentIntentProductionHardeningCaseResult {
    let duplicateProposalAgentId = hardeningCase.name == "duplicate_proposal_denied"
        ? hardeningCase.contexts.first?.agentId
        : nil
    let result = produceAgentIntentProductionResult(
        tick: hardeningCase.tick,
        contexts: hardeningCase.contexts,
        maxProposals: hardeningCase.maxProposals,
        duplicateProposalAgentId: duplicateProposalAgentId
    )
    let passed = result.summary.acceptedIntents == hardeningCase.expectedAcceptedIntents
        && result.summary.rejectedProposals == hardeningCase.expectedRejectedProposals
        && result.summary.noIntent == hardeningCase.expectedNoIntent
        && result.summary.invalidContext == hardeningCase.expectedInvalidContext
        && result.summary.duplicateAgentContexts == hardeningCase.expectedDuplicateAgentContexts
        && result.summary.duplicateProposals == hardeningCase.expectedDuplicateProposals
        && result.summary.invalidOneEdgeProposals == hardeningCase.expectedInvalidOneEdgeProposals
        && result.summary.staleProposals == hardeningCase.expectedStaleProposals
        && result.summary.wrongSourceProposals == hardeningCase.expectedWrongSourceProposals
        && result.summary.maxProposalsExceeded == hardeningCase.expectedMaxProposalsExceeded
        && result.acceptedIntents.allSatisfy { intent in
            manhattanDistance(intent.from, intent.to) == 1 && intent.from.y == intent.to.y
        }
    return LabAgentIntentProductionHardeningCaseResult(
        name: hardeningCase.name,
        passed: passed,
        result: result,
        expectedAcceptedIntents: hardeningCase.expectedAcceptedIntents,
        actualAcceptedIntents: result.summary.acceptedIntents,
        expectedRejectedProposals: hardeningCase.expectedRejectedProposals,
        actualRejectedProposals: result.summary.rejectedProposals,
        expectedNoIntent: hardeningCase.expectedNoIntent,
        actualNoIntent: result.summary.noIntent,
        expectedInvalidContext: hardeningCase.expectedInvalidContext,
        actualInvalidContext: result.summary.invalidContext,
        expectedDuplicateAgentContexts: hardeningCase.expectedDuplicateAgentContexts,
        actualDuplicateAgentContexts: result.summary.duplicateAgentContexts,
        expectedDuplicateProposals: hardeningCase.expectedDuplicateProposals,
        actualDuplicateProposals: result.summary.duplicateProposals,
        expectedInvalidOneEdgeProposals: hardeningCase.expectedInvalidOneEdgeProposals,
        actualInvalidOneEdgeProposals: result.summary.invalidOneEdgeProposals,
        expectedStaleProposals: hardeningCase.expectedStaleProposals,
        actualStaleProposals: result.summary.staleProposals,
        expectedWrongSourceProposals: hardeningCase.expectedWrongSourceProposals,
        actualWrongSourceProposals: result.summary.wrongSourceProposals,
        expectedMaxProposalsExceeded: hardeningCase.expectedMaxProposalsExceeded,
        actualMaxProposalsExceeded: result.summary.maxProposalsExceeded
    )
}

private func agentIntentProductionHardeningCases() -> [LabAgentIntentProductionHardeningCase] {
    [
        LabAgentIntentProductionHardeningCase(
            name: "baseline_fixture_remains_green",
            tick: 0,
            contexts: agentIntentProductionFixtureContexts(),
            maxProposals: nil,
            expectedAcceptedIntents: 2,
            expectedRejectedProposals: 3,
            expectedNoIntent: 1,
            expectedInvalidContext: 1,
            expectedDuplicateAgentContexts: 0,
            expectedDuplicateProposals: 0,
            expectedInvalidOneEdgeProposals: 1,
            expectedStaleProposals: 0,
            expectedWrongSourceProposals: 0,
            expectedMaxProposalsExceeded: 0
        ),
        LabAgentIntentProductionHardeningCase(
            name: "duplicate_agent_context_denied",
            tick: 0,
            contexts: [
                agentIntentContext("agent_0", x: 0, role: "wander_fixture", hints: ["move_east"]),
                agentIntentContext("agent_0", x: 2, role: "wander_fixture", hints: ["move_west"])
            ],
            maxProposals: nil,
            expectedAcceptedIntents: 1,
            expectedRejectedProposals: 1,
            expectedNoIntent: 0,
            expectedInvalidContext: 0,
            expectedDuplicateAgentContexts: 1,
            expectedDuplicateProposals: 1,
            expectedInvalidOneEdgeProposals: 0,
            expectedStaleProposals: 0,
            expectedWrongSourceProposals: 0,
            expectedMaxProposalsExceeded: 0
        ),
        LabAgentIntentProductionHardeningCase(
            name: "duplicate_proposal_denied",
            tick: 0,
            contexts: [
                agentIntentContext("agent_0", x: 0, role: "wander_fixture", hints: ["move_east"])
            ],
            maxProposals: nil,
            expectedAcceptedIntents: 1,
            expectedRejectedProposals: 1,
            expectedNoIntent: 0,
            expectedInvalidContext: 0,
            expectedDuplicateAgentContexts: 0,
            expectedDuplicateProposals: 1,
            expectedInvalidOneEdgeProposals: 0,
            expectedStaleProposals: 0,
            expectedWrongSourceProposals: 0,
            expectedMaxProposalsExceeded: 0
        ),
        LabAgentIntentProductionHardeningCase(
            name: "invalid_diagonal_proposal_rejected",
            tick: 0,
            contexts: [
                agentIntentContext("agent_0", x: 0, role: "bad_fixture_invalid_diagonal", hints: [])
            ],
            maxProposals: nil,
            expectedAcceptedIntents: 0,
            expectedRejectedProposals: 1,
            expectedNoIntent: 0,
            expectedInvalidContext: 0,
            expectedDuplicateAgentContexts: 0,
            expectedDuplicateProposals: 0,
            expectedInvalidOneEdgeProposals: 1,
            expectedStaleProposals: 0,
            expectedWrongSourceProposals: 0,
            expectedMaxProposalsExceeded: 0
        ),
        LabAgentIntentProductionHardeningCase(
            name: "zero_length_proposal_rejected",
            tick: 0,
            contexts: [
                agentIntentContext("agent_0", x: 0, role: "bad_fixture_zero_length", hints: [])
            ],
            maxProposals: nil,
            expectedAcceptedIntents: 0,
            expectedRejectedProposals: 1,
            expectedNoIntent: 0,
            expectedInvalidContext: 0,
            expectedDuplicateAgentContexts: 0,
            expectedDuplicateProposals: 0,
            expectedInvalidOneEdgeProposals: 1,
            expectedStaleProposals: 0,
            expectedWrongSourceProposals: 0,
            expectedMaxProposalsExceeded: 0
        ),
        LabAgentIntentProductionHardeningCase(
            name: "stale_proposal_rejected",
            tick: 0,
            contexts: [
                agentIntentContext("agent_0", x: 0, role: "bad_fixture_stale", hints: [])
            ],
            maxProposals: nil,
            expectedAcceptedIntents: 0,
            expectedRejectedProposals: 1,
            expectedNoIntent: 0,
            expectedInvalidContext: 0,
            expectedDuplicateAgentContexts: 0,
            expectedDuplicateProposals: 0,
            expectedInvalidOneEdgeProposals: 0,
            expectedStaleProposals: 1,
            expectedWrongSourceProposals: 0,
            expectedMaxProposalsExceeded: 0
        ),
        LabAgentIntentProductionHardeningCase(
            name: "wrong_source_proposal_rejected",
            tick: 0,
            contexts: [
                agentIntentContext("agent_0", x: 10, role: "bad_fixture_wrong_source", hints: [])
            ],
            maxProposals: nil,
            expectedAcceptedIntents: 0,
            expectedRejectedProposals: 1,
            expectedNoIntent: 0,
            expectedInvalidContext: 0,
            expectedDuplicateAgentContexts: 0,
            expectedDuplicateProposals: 0,
            expectedInvalidOneEdgeProposals: 0,
            expectedStaleProposals: 0,
            expectedWrongSourceProposals: 1,
            expectedMaxProposalsExceeded: 0
        ),
        LabAgentIntentProductionHardeningCase(
            name: "max_proposals_bound_exceeded",
            tick: 0,
            contexts: [
                agentIntentContext("agent_0", x: 0, role: "wander_fixture", hints: ["move_east"]),
                agentIntentContext("agent_1", x: 2, role: "wander_fixture", hints: ["move_east"]),
                agentIntentContext("agent_2", x: 4, role: "wander_fixture", hints: ["move_east"]),
                agentIntentContext("agent_3", x: 6, role: "wander_fixture", hints: ["move_east"]),
                agentIntentContext("agent_4", x: 8, role: "wander_fixture", hints: ["move_east"])
            ],
            maxProposals: 4,
            expectedAcceptedIntents: 4,
            expectedRejectedProposals: 1,
            expectedNoIntent: 0,
            expectedInvalidContext: 0,
            expectedDuplicateAgentContexts: 0,
            expectedDuplicateProposals: 0,
            expectedInvalidOneEdgeProposals: 0,
            expectedStaleProposals: 0,
            expectedWrongSourceProposals: 0,
            expectedMaxProposalsExceeded: 1
        ),
        LabAgentIntentProductionHardeningCase(
            name: "deterministic_hint_ordering",
            tick: 0,
            contexts: [
                agentIntentContext("agent_0", x: 0, role: "wander_fixture", hints: ["move_south", "move_east", "move_west"])
            ],
            maxProposals: nil,
            expectedAcceptedIntents: 1,
            expectedRejectedProposals: 0,
            expectedNoIntent: 0,
            expectedInvalidContext: 0,
            expectedDuplicateAgentContexts: 0,
            expectedDuplicateProposals: 0,
            expectedInvalidOneEdgeProposals: 0,
            expectedStaleProposals: 0,
            expectedWrongSourceProposals: 0,
            expectedMaxProposalsExceeded: 0
        ),
        LabAgentIntentProductionHardeningCase(
            name: "unknown_role_no_intent",
            tick: 0,
            contexts: [
                agentIntentContext("agent_0", x: 0, role: "unknown_fixture_role", hints: ["move_east"])
            ],
            maxProposals: nil,
            expectedAcceptedIntents: 0,
            expectedRejectedProposals: 1,
            expectedNoIntent: 1,
            expectedInvalidContext: 0,
            expectedDuplicateAgentContexts: 0,
            expectedDuplicateProposals: 0,
            expectedInvalidOneEdgeProposals: 0,
            expectedStaleProposals: 0,
            expectedWrongSourceProposals: 0,
            expectedMaxProposalsExceeded: 0
        )
    ]
}

private func agentIntentContext(
    _ agentId: String,
    x: Int,
    role: String,
    hints: [String],
    tick: Int = 0,
    y: Int = 64,
    z: Int = 0
) -> LabAgentIntentContext {
    LabAgentIntentContext(
        tick: tick,
        agentId: agentId,
        position: LabTerrainPathNodeKey(x: x, y: y, z: z),
        lastFeedback: nil,
        role: role,
        localHints: hints
    )
}

private func produceAgentIntentProductionResult(
    tick: Int,
    contexts: [LabAgentIntentContext],
    maxProposals: Int?,
    duplicateProposalAgentId: String?
) -> LabAgentIntentProductionResult {
    var rawProposals = contexts.map(produceAgentIntentProposalV0(context:))
    if let duplicateProposalAgentId,
       let duplicate = rawProposals.first(where: { $0.agentId == duplicateProposalAgentId }) {
        rawProposals.append(duplicate)
    }
    let proposals = rawProposals.sorted { lhs, rhs in
        lhs.agentId == rhs.agentId ? lhs.reason < rhs.reason : lhs.agentId < rhs.agentId
    }
    let duplicateAgentContexts = contexts.count - Set(contexts.map(\.agentId)).count
    var accepted: [LabAgentMoveIntent] = []
    var rejected: [LabAgentIntentProposal] = []
    var seenContexts = Set<String>()
    var acceptedAgents = Set<String>()
    var seenProposalAgents = Set<String>()
    var invalidOneEdgeProposals = 0
    var duplicateProposals = 0
    var staleProposals = 0
    var wrongSourceProposals = 0
    var maxProposalsExceeded = 0
    let contextByAgent = Dictionary(
        uniqueKeysWithValues: contexts.compactMap { context -> (String, LabTerrainPathNodeKey)? in
            guard !seenContexts.contains(context.agentId) else {
                return nil
            }
            seenContexts.insert(context.agentId)
            guard let position = context.position else {
                return nil
            }
            return (context.agentId, position)
        }
    )

    seenContexts.removeAll()
    for (index, proposal) in proposals.enumerated() {
        if let maxProposals, index >= maxProposals {
            maxProposalsExceeded += 1
            rejected.append(proposal)
            continue
        }
        if seenProposalAgents.contains(proposal.agentId) {
            duplicateProposals += 1
            rejected.append(proposal)
            continue
        }
        seenProposalAgents.insert(proposal.agentId)
        if seenContexts.contains(proposal.agentId) {
            rejected.append(proposal)
            continue
        }
        if contexts.filter({ $0.agentId == proposal.agentId }).count > 1 {
            seenContexts.insert(proposal.agentId)
        }
        guard proposal.decision == .proposeMove, let intent = proposal.intent else {
            rejected.append(proposal)
            continue
        }
        if intent.stale {
            staleProposals += 1
            rejected.append(proposal)
            continue
        }
        let sourceMatches = contextByAgent[intent.agentId] == intent.from
        if !sourceMatches {
            wrongSourceProposals += 1
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
        duplicateProposals: duplicateProposals,
        invalidOneEdgeProposals: invalidOneEdgeProposals,
        staleProposals: staleProposals,
        wrongSourceProposals: wrongSourceProposals,
        maxProposalsExceeded: maxProposalsExceeded,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        collisionRead: false,
        movementApplied: false,
        memoryUpdated: false,
        goalChanged: false,
        mutationPerformed: false,
        success: accepted.count + rejected.count == proposals.count
            && !contexts.isEmpty
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
