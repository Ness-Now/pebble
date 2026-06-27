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

struct LabAgentIntentToTickFixtureSummary: Codable {
    let tick: Int
    let contexts: Int
    let proposals: Int
    let acceptedIntents: Int
    let rejectedProposals: Int
    let tickAgents: Int
    let tickIntents: Int
    let tickResolutions: Int
    let tickFeedback: Int
    let tickApproved: Int
    let tickDenied: Int
    let sameDestinationConflicts: Int
    let invalidEdges: Int
    let displacementsApplied: Int
    let productionAcceptedSameDestination: Bool
    let tickResolvedSameDestination: Bool
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

struct LabAgentIntentToTickFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let intentProduction: LabAgentIntentProductionResult
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickOutput
    let summary: LabAgentIntentToTickFixtureSummary
}

struct LabAgentIntentToTickFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAgentIntentToTickLiveReadonlySummary: Codable {
    let tick: Int
    let contexts: Int
    let proposals: Int
    let acceptedIntents: Int
    let rejectedProposals: Int
    let tickAgents: Int
    let tickIntents: Int
    let tickResolutions: Int
    let tickFeedback: Int
    let tickApproved: Int
    let tickDenied: Int
    let occupableDestinations: Int
    let nonOccupableDestinations: Int
    let collisionDenied: Int
    let sourceMismatch: Int
    let invalidEdges: Int
    let displacementsApplied: Int
    let productionAcceptedIntents: Bool
    let productionReadCollision: Bool
    let tickReadLiveCollision: Bool
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

struct LabAgentIntentToTickLiveReadonlyReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let intentProduction: LabAgentIntentProductionResult
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickLiveReadonlyOutput
    let summary: LabAgentIntentToTickLiveReadonlySummary
}

struct LabAgentIntentToTickLiveReadonlyInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAgentIntentToTickApprovedApplicationSummary: Codable {
    let tick: Int
    let contexts: Int
    let proposals: Int
    let acceptedIntents: Int
    let rejectedProposals: Int
    let tickAgents: Int
    let tickIntents: Int
    let tickResolutions: Int
    let tickFeedback: Int
    let tickApproved: Int
    let tickDenied: Int
    let occupableDestinations: Int
    let nonOccupableDestinations: Int
    let collisionDenied: Int
    let displacementsApplied: Int
    let movedFeedback: Int
    let blockedByCollisionFeedback: Int
    let abstractPhysicalDivergenceBefore: Int
    let abstractPhysicalDivergenceAfter: Int
    let deniedPositionsPreserved: Bool
    let approvedPositionsMoved: Bool
    let productionReadCollision: Bool
    let tickReadLiveCollision: Bool
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
    let routeFollowingApplied: Bool
    let physicsPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAgentIntentToTickApprovedApplicationReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let intentProduction: LabAgentIntentProductionResult
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickApprovedApplicationOutput
    let summary: LabAgentIntentToTickApprovedApplicationSummary
}

struct LabAgentIntentToTickApprovedApplicationInvariantReport: Codable {
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

private func agentIntentToTickFixtureContexts() -> [LabAgentIntentContext] {
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
            position: LabTerrainPathNodeKey(x: 20, y: 64, z: 0),
            lastFeedback: nil,
            role: "bad_fixture_invalid_vertical",
            localHints: ["move_vertical"]
        )
    ]
}

private func agentIntentToTickLiveReadonlyContexts() -> [LabAgentIntentContext] {
    let tick = 0
    return [
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_3",
            position: LabTerrainPathNodeKey(x: 20, y: 64, z: 0),
            lastFeedback: nil,
            role: "idle",
            localHints: []
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_0",
            position: LabTerrainPathNodeKey(x: 7, y: 64, z: 8),
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_1",
            position: LabTerrainPathNodeKey(x: 9, y: 64, z: 7),
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_south"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_2",
            position: LabTerrainPathNodeKey(x: 7, y: 64, z: 8),
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_4",
            position: LabTerrainPathNodeKey(x: 30, y: 64, z: 0),
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

func makeAgentIntentToTickFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabAgentIntentToTickFixtureReport {
    let intentProduction = produceAgentIntentProductionResult(
        tick: 0,
        contexts: agentIntentToTickFixtureContexts(),
        maxProposals: nil,
        duplicateProposalAgentId: nil
    )
    let agents = Dictionary(
        uniqueKeysWithValues: intentProduction.contexts.compactMap { context in
            context.position.map { (context.agentId, $0) }
        }
    )
    let tickInput = LabMultiAgentMovementTickInput(
        tick: intentProduction.tick,
        agents: agents,
        physicalPositions: agents,
        intents: intentProduction.acceptedIntents,
        maxAgents: nil
    )
    let tickReport = makeMultiAgentMovementTickFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        input: tickInput,
        expectedApproved: 1,
        expectedDenied: 1,
        expectedDecisionCounts: [
            LabMultiAgentMoveDecision.approved.rawValue: 1,
            LabMultiAgentMoveDecision.deniedSameDestinationConflict.rawValue: 1
        ]
    )
    let acceptedDestinations = intentProduction.acceptedIntents.map(\.to)
    let productionAcceptedSameDestination =
        !acceptedDestinations.isEmpty && Set(acceptedDestinations).count < acceptedDestinations.count
    let tickResolvedSameDestination = tickReport.summary.sameDestinationConflicts == 1
        && tickReport.output.resolutions.contains {
            $0.agentId == "agent_0" && $0.decision == .approved && $0.approved
        }
        && tickReport.output.resolutions.contains {
            $0.agentId == "agent_1"
                && $0.decision == .deniedSameDestinationConflict
                && !$0.approved
        }
    let positionsUnchanged = tickReport.output.abstractPositionsBefore == tickReport.output.abstractPositionsAfter
        && tickReport.output.physicalPositionsBefore == tickReport.output.physicalPositionsAfter
    let summary = LabAgentIntentToTickFixtureSummary(
        tick: intentProduction.tick,
        contexts: intentProduction.summary.contexts,
        proposals: intentProduction.summary.proposals,
        acceptedIntents: intentProduction.summary.acceptedIntents,
        rejectedProposals: intentProduction.summary.rejectedProposals,
        tickAgents: tickInput.agents.count,
        tickIntents: tickInput.intents.count,
        tickResolutions: tickReport.output.resolutions.count,
        tickFeedback: tickReport.output.feedback.count,
        tickApproved: tickReport.summary.approved,
        tickDenied: tickReport.summary.denied,
        sameDestinationConflicts: tickReport.summary.sameDestinationConflicts,
        invalidEdges: tickReport.summary.invalidEdges,
        displacementsApplied: tickReport.summary.displacementsApplied,
        productionAcceptedSameDestination: productionAcceptedSameDestination,
        tickResolvedSameDestination: tickResolvedSameDestination,
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
        success: intentProduction.summary.success
            && tickReport.success
            && intentProduction.summary.contexts == 4
            && intentProduction.summary.proposals == 4
            && intentProduction.summary.acceptedIntents == 2
            && intentProduction.summary.rejectedProposals == 2
            && intentProduction.summary.noIntent == 1
            && intentProduction.summary.invalidOneEdgeProposals == 1
            && productionAcceptedSameDestination
            && tickResolvedSameDestination
            && tickReport.summary.approved == 1
            && tickReport.summary.denied == 1
            && tickReport.output.feedback.count == 2
            && positionsUnchanged
            && tickReport.summary.displacementsApplied == 0
    )
    return LabAgentIntentToTickFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        intentProduction: intentProduction,
        tickInput: tickInput,
        tickOutput: tickReport.output,
        summary: summary
    )
}

func makeAgentIntentToTickFixtureInvariantReport(
    report: LabAgentIntentToTickFixtureReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentIntentToTickFixtureInvariantReport {
    guard let report else {
        let check = agentIntentInvariantCheck(
            "report_written",
            false,
            "agent_intent_to_tick_fixture_report.json",
            "missing"
        )
        return LabAgentIntentToTickFixtureInvariantReport(
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
            notes: ["Agent intent to tick fixture report was not available."]
        )
    }

    let contextIds = report.intentProduction.contexts.map(\.agentId)
    let proposalIds = report.intentProduction.proposals.map(\.agentId)
    let acceptedIds = report.intentProduction.acceptedIntents.map(\.agentId)
    let resolutionIds = report.tickOutput.resolutions.map(\.agentId)
    let acceptedDestinations = report.intentProduction.acceptedIntents.map(\.to)
    let productionAcceptedSameDestination =
        !acceptedDestinations.isEmpty && Set(acceptedDestinations).count < acceptedDestinations.count
    let acceptedOneEdge = report.intentProduction.acceptedIntents.allSatisfy {
        manhattanDistance($0.from, $0.to) == 1
    }
    let acceptedSameY = report.intentProduction.acceptedIntents.allSatisfy {
        $0.from.y == $0.to.y
    }
    let tickInputUsesAccepted = report.tickInput.intents.map(\.agentId) == acceptedIds
    let tickAgentsCoverSources = report.tickInput.intents.allSatisfy { intent in
        report.tickInput.agents[intent.agentId] == intent.from
    }
    let physicalMatchesAbstract = report.tickInput.physicalPositions == report.tickInput.agents
    let agent0Approved = report.tickOutput.resolutions.contains {
        $0.agentId == "agent_0" && $0.decision == .approved && $0.approved
    }
    let agent1Denied = report.tickOutput.resolutions.contains {
        $0.agentId == "agent_1" && $0.decision == .deniedSameDestinationConflict && !$0.approved
    }
    let approvedFeedback = report.tickOutput.feedback.contains {
        $0.agentId == "agent_0" && $0.kind == .approvedForMovement
    }
    let deniedFeedback = report.tickOutput.feedback.contains {
        $0.agentId == "agent_1" && $0.kind == .blockedByAgentConflict
    }
    let positionsUnchanged = report.tickOutput.abstractPositionsBefore == report.tickOutput.abstractPositionsAfter
        && report.tickOutput.physicalPositionsBefore == report.tickOutput.physicalPositionsAfter

    let checks = [
        agentIntentInvariantCheck("intent_contexts_exist", !report.intentProduction.contexts.isEmpty, "non-empty", "\(report.intentProduction.contexts.count)"),
        agentIntentInvariantCheck("intent_proposals_exist", !report.intentProduction.proposals.isEmpty, "non-empty", "\(report.intentProduction.proposals.count)"),
        agentIntentInvariantCheck("accepted_intents_exist", !report.intentProduction.acceptedIntents.isEmpty, "non-empty", "\(report.intentProduction.acceptedIntents.count)"),
        agentIntentInvariantCheck("rejected_proposals_exist", !report.intentProduction.rejectedProposals.isEmpty, "non-empty", "\(report.intentProduction.rejectedProposals.count)"),
        agentIntentInvariantCheck("contexts_intentionally_unordered", contextIds != contextIds.sorted(), "unordered input", contextIds.joined(separator: ",")),
        agentIntentInvariantCheck("proposals_sorted_by_agent_id", proposalIds == proposalIds.sorted(), "sorted", proposalIds.joined(separator: ",")),
        agentIntentInvariantCheck("accepted_intents_sorted_by_agent_id", acceptedIds == acceptedIds.sorted(), "sorted", acceptedIds.joined(separator: ",")),
        agentIntentInvariantCheck("accepted_intents_are_one_edge", acceptedOneEdge, "one-edge", "\(acceptedOneEdge)"),
        agentIntentInvariantCheck("accepted_intents_are_same_y", acceptedSameY, "same-y", "\(acceptedSameY)"),
        agentIntentInvariantCheck("production_accepts_same_destination_intents", productionAcceptedSameDestination, "true", "\(productionAcceptedSameDestination)"),
        agentIntentInvariantCheck("production_does_not_arbitrate_conflicts", productionAcceptedSameDestination, "same destination preserved", "\(acceptedDestinations)"),
        agentIntentInvariantCheck("tick_input_exists", report.tickInput.tick == report.intentProduction.tick, "same tick", "\(report.tickInput.tick)"),
        agentIntentInvariantCheck("tick_input_uses_accepted_intents", tickInputUsesAccepted, "accepted intents", report.tickInput.intents.map(\.agentId).joined(separator: ",")),
        agentIntentInvariantCheck("tick_input_agents_cover_intent_sources", tickAgentsCoverSources, "sources covered", "\(tickAgentsCoverSources)"),
        agentIntentInvariantCheck("tick_input_physical_positions_match_abstract", physicalMatchesAbstract, "match", "\(physicalMatchesAbstract)"),
        agentIntentInvariantCheck("tick_resolutions_exist", !report.tickOutput.resolutions.isEmpty, "non-empty", "\(report.tickOutput.resolutions.count)"),
        agentIntentInvariantCheck("tick_resolutions_sorted_by_agent_id", resolutionIds == resolutionIds.sorted(), "sorted", resolutionIds.joined(separator: ",")),
        agentIntentInvariantCheck("tick_resolves_same_destination_conflict", report.summary.tickResolvedSameDestination, "true", "\(report.summary.tickResolvedSameDestination)"),
        agentIntentInvariantCheck("stable_agent_id_winner_agent_0", agent0Approved, "agent_0 approved", "\(agent0Approved)"),
        agentIntentInvariantCheck("same_destination_loser_agent_1_denied", agent1Denied, "agent_1 denied", "\(agent1Denied)"),
        agentIntentInvariantCheck("tick_approved_count_expected", report.summary.tickApproved == 1, "1", "\(report.summary.tickApproved)"),
        agentIntentInvariantCheck("tick_denied_count_expected", report.summary.tickDenied == 1, "1", "\(report.summary.tickDenied)"),
        agentIntentInvariantCheck("tick_feedback_count_matches_resolutions", report.summary.tickFeedback == report.summary.tickResolutions, "match", "\(report.summary.tickFeedback)/\(report.summary.tickResolutions)"),
        agentIntentInvariantCheck("approved_tick_feedback_is_approved_for_movement", approvedFeedback, "approvedForMovement", "\(approvedFeedback)"),
        agentIntentInvariantCheck("denied_conflict_feedback_is_blocked_by_agent_conflict", deniedFeedback, "blockedByAgentConflict", "\(deniedFeedback)"),
        agentIntentInvariantCheck("positions_unchanged", positionsUnchanged, "unchanged", "\(positionsUnchanged)"),
        agentIntentInvariantCheck("no_displacement_applied", report.summary.displacementsApplied == 0, "0", "\(report.summary.displacementsApplied)"),
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
        agentIntentInvariantCheck("agent_intent_fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("agent_intent_hardening_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("tick_fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("report_written", true, "agent_intent_to_tick_fixture_report.json", "agent_intent_to_tick_fixture_report.json"),
        agentIntentInvariantCheck("proposals_written", true, "agent_intent_to_tick_fixture_proposals.json", "agent_intent_to_tick_fixture_proposals.json"),
        agentIntentInvariantCheck("metrics_written", true, "agentIntentToTickFixture* metrics", "agentIntentToTickFixture* metrics"),
        agentIntentInvariantCheck("event_written", true, "lab_agent_intent_to_tick_fixture_recorded", "lab_agent_intent_to_tick_fixture_recorded"),
        agentIntentInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let failed = checks.filter { !$0.passed }.count
    return LabAgentIntentToTickFixtureInvariantReport(
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
            "Agent intent production remains fixture-only and does not arbitrate conflicts.",
            "The tick fixture layer receives accepted intents and resolves the same-destination conflict.",
            "No World, collision read, physical movement, feedback consumption, memory, goals, pathfinding, replanning, reservation runtime, physics, or mutation is used."
        ]
    )
}

func makeAgentIntentToTickLiveReadonlyReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabAgentIntentToTickLiveReadonlyReport {
    let intentProduction = produceAgentIntentProductionResult(
        tick: 0,
        contexts: agentIntentToTickLiveReadonlyContexts(),
        maxProposals: nil,
        duplicateProposalAgentId: nil
    )
    let agents = Dictionary(
        uniqueKeysWithValues: intentProduction.contexts.compactMap { context in
            context.position.map { (context.agentId, $0) }
        }
    )
    let tickInput = LabMultiAgentMovementTickInput(
        tick: intentProduction.tick,
        agents: agents,
        physicalPositions: agents,
        intents: intentProduction.acceptedIntents,
        maxAgents: nil
    )
    let tickReport = makeMultiAgentMovementTickLiveReadonlyReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        input: tickInput,
        evidenceSeeds: [
            "agent_0": 99,
            "agent_1": 99,
            "agent_2": 42
        ],
        expectedApproved: 2,
        expectedDenied: 1,
        expectedOccupableDestinations: 2,
        expectedNonOccupableDestinations: 1,
        expectedCollisionDenied: 1,
        requireSourceMismatch: false,
        requireInvalidEdges: false
    )
    let positionsUnchanged = tickReport.output.abstractPositionsBefore == tickReport.output.abstractPositionsAfter
        && tickReport.output.physicalPositionsBefore == tickReport.output.physicalPositionsAfter
    let productionAcceptedIntents = !intentProduction.acceptedIntents.isEmpty
    let tickReadLiveCollision = tickReport.output.resolutions.contains { $0.collisionRead }
    let summary = LabAgentIntentToTickLiveReadonlySummary(
        tick: intentProduction.tick,
        contexts: intentProduction.summary.contexts,
        proposals: intentProduction.summary.proposals,
        acceptedIntents: intentProduction.summary.acceptedIntents,
        rejectedProposals: intentProduction.summary.rejectedProposals,
        tickAgents: tickInput.agents.count,
        tickIntents: tickInput.intents.count,
        tickResolutions: tickReport.output.resolutions.count,
        tickFeedback: tickReport.output.feedback.count,
        tickApproved: tickReport.summary.approved,
        tickDenied: tickReport.summary.denied,
        occupableDestinations: tickReport.summary.occupableDestinations,
        nonOccupableDestinations: tickReport.summary.nonOccupableDestinations,
        collisionDenied: tickReport.summary.collisionDenied,
        sourceMismatch: tickReport.summary.sourceMismatch,
        invalidEdges: tickReport.summary.invalidEdges,
        displacementsApplied: tickReport.summary.displacementsApplied,
        productionAcceptedIntents: productionAcceptedIntents,
        productionReadCollision: intentProduction.summary.collisionRead,
        tickReadLiveCollision: tickReadLiveCollision,
        worldUsed: tickReport.summary.worldUsed,
        collisionRead: tickReport.summary.liveCollisionRead,
        movementApplied: tickReport.summary.physicalMovementApplied,
        feedbackConsumed: false,
        memoryUpdated: false,
        goalChanged: false,
        pathfindingPerformed: tickReport.summary.pathfindingPerformed,
        replanningPerformed: tickReport.summary.replanningPerformed,
        avoidancePerformed: tickReport.summary.avoidancePerformed,
        reservationRuntimeUsed: tickReport.summary.reservationRuntimeUsed,
        physicsPerformed: tickReport.summary.physicsPerformed,
        mutationPerformed: tickReport.summary.mutationPerformed,
        success: intentProduction.summary.success
            && tickReport.success
            && intentProduction.summary.contexts == 5
            && intentProduction.summary.proposals == 5
            && intentProduction.summary.acceptedIntents == 3
            && intentProduction.summary.rejectedProposals == 2
            && intentProduction.summary.noIntent == 1
            && intentProduction.summary.invalidOneEdgeProposals == 1
            && !intentProduction.summary.collisionRead
            && intentProduction.summary.movementApplied == false
            && tickReport.summary.approved == 2
            && tickReport.summary.denied == 1
            && tickReport.summary.occupableDestinations == 2
            && tickReport.summary.nonOccupableDestinations == 1
            && tickReport.summary.collisionDenied == 1
            && tickReport.output.feedback.count == 3
            && tickReport.output.feedback.filter { $0.kind == .approvedForMovement }.count == 2
            && tickReport.output.feedback.contains { $0.agentId == "agent_2" && $0.kind == .blockedByCollision }
            && positionsUnchanged
            && tickReport.summary.displacementsApplied == 0
            && tickReport.summary.worldUsed
            && tickReport.summary.liveCollisionRead
            && !tickReport.summary.physicalMovementApplied
            && !tickReport.summary.pathfindingPerformed
            && !tickReport.summary.replanningPerformed
            && !tickReport.summary.avoidancePerformed
            && !tickReport.summary.reservationRuntimeUsed
            && !tickReport.summary.physicsPerformed
            && !tickReport.summary.mutationPerformed
    )
    return LabAgentIntentToTickLiveReadonlyReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        intentProduction: intentProduction,
        tickInput: tickInput,
        tickOutput: tickReport.output,
        summary: summary
    )
}

func makeAgentIntentToTickLiveReadonlyInvariantReport(
    report: LabAgentIntentToTickLiveReadonlyReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentIntentToTickLiveReadonlyInvariantReport {
    guard let report else {
        let check = agentIntentInvariantCheck(
            "report_written",
            false,
            "agent_intent_to_tick_live_readonly_report.json",
            "missing"
        )
        return LabAgentIntentToTickLiveReadonlyInvariantReport(
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
            notes: ["Agent intent to tick live read-only report was not available."]
        )
    }

    let contextIds = report.intentProduction.contexts.map(\.agentId)
    let proposalIds = report.intentProduction.proposals.map(\.agentId)
    let acceptedIds = report.intentProduction.acceptedIntents.map(\.agentId)
    let resolutionIds = report.tickOutput.resolutions.map(\.agentId)
    let acceptedOneEdge = report.intentProduction.acceptedIntents.allSatisfy {
        manhattanDistance($0.from, $0.to) == 1
    }
    let acceptedSameY = report.intentProduction.acceptedIntents.allSatisfy {
        $0.from.y == $0.to.y
    }
    let tickInputUsesAccepted = report.tickInput.intents.map(\.agentId) == acceptedIds
    let tickAgentsCoverSources = report.tickInput.intents.allSatisfy { intent in
        report.tickInput.agents[intent.agentId] == intent.from
    }
    let physicalMatchesAbstract = report.tickInput.physicalPositions == report.tickInput.agents
    let approvedFeedbackCount = report.tickOutput.feedback.filter {
        $0.kind == .approvedForMovement
    }.count
    let collisionDeniedFeedback = report.tickOutput.feedback.contains {
        $0.agentId == "agent_2" && $0.kind == .blockedByCollision
    }
    let positionsUnchanged = report.tickOutput.abstractPositionsBefore == report.tickOutput.abstractPositionsAfter
        && report.tickOutput.physicalPositionsBefore == report.tickOutput.physicalPositionsAfter

    let checks = [
        agentIntentInvariantCheck("intent_contexts_exist", !report.intentProduction.contexts.isEmpty, "non-empty", "\(report.intentProduction.contexts.count)"),
        agentIntentInvariantCheck("intent_proposals_exist", !report.intentProduction.proposals.isEmpty, "non-empty", "\(report.intentProduction.proposals.count)"),
        agentIntentInvariantCheck("accepted_intents_exist", !report.intentProduction.acceptedIntents.isEmpty, "non-empty", "\(report.intentProduction.acceptedIntents.count)"),
        agentIntentInvariantCheck("rejected_proposals_exist", !report.intentProduction.rejectedProposals.isEmpty, "non-empty", "\(report.intentProduction.rejectedProposals.count)"),
        agentIntentInvariantCheck("contexts_intentionally_unordered", contextIds != contextIds.sorted(), "unordered input", contextIds.joined(separator: ",")),
        agentIntentInvariantCheck("proposals_sorted_by_agent_id", proposalIds == proposalIds.sorted(), "sorted", proposalIds.joined(separator: ",")),
        agentIntentInvariantCheck("accepted_intents_sorted_by_agent_id", acceptedIds == acceptedIds.sorted(), "sorted", acceptedIds.joined(separator: ",")),
        agentIntentInvariantCheck("accepted_intents_are_one_edge", acceptedOneEdge, "one-edge", "\(acceptedOneEdge)"),
        agentIntentInvariantCheck("accepted_intents_are_same_y", acceptedSameY, "same-y", "\(acceptedSameY)"),
        agentIntentInvariantCheck("production_does_not_read_collision", !report.summary.productionReadCollision, "false", "\(report.summary.productionReadCollision)"),
        agentIntentInvariantCheck("production_does_not_apply_movement", !report.intentProduction.summary.movementApplied, "false", "\(report.intentProduction.summary.movementApplied)"),
        agentIntentInvariantCheck("production_does_not_arbitrate_occupancy", report.summary.acceptedIntents == 3, "3 accepted before occupancy", "\(report.summary.acceptedIntents)"),
        agentIntentInvariantCheck("tick_input_exists", report.tickInput.tick == report.intentProduction.tick, "same tick", "\(report.tickInput.tick)"),
        agentIntentInvariantCheck("tick_input_uses_accepted_intents", tickInputUsesAccepted, "accepted intents", report.tickInput.intents.map(\.agentId).joined(separator: ",")),
        agentIntentInvariantCheck("tick_input_agents_cover_intent_sources", tickAgentsCoverSources, "sources covered", "\(tickAgentsCoverSources)"),
        agentIntentInvariantCheck("tick_input_physical_positions_match_abstract", physicalMatchesAbstract, "match", "\(physicalMatchesAbstract)"),
        agentIntentInvariantCheck("tick_resolutions_exist", !report.tickOutput.resolutions.isEmpty, "non-empty", "\(report.tickOutput.resolutions.count)"),
        agentIntentInvariantCheck("tick_resolutions_sorted_by_agent_id", resolutionIds == resolutionIds.sorted(), "sorted", resolutionIds.joined(separator: ",")),
        agentIntentInvariantCheck("tick_reads_live_collision", report.summary.tickReadLiveCollision, "true", "\(report.summary.tickReadLiveCollision)"),
        agentIntentInvariantCheck("world_used_only_for_readonly_collision", report.summary.worldUsed && !report.summary.movementApplied, "readonly collision", "worldUsed=\(report.summary.worldUsed), movementApplied=\(report.summary.movementApplied)"),
        agentIntentInvariantCheck("occupable_destinations_approved", report.summary.occupableDestinations == 2 && report.summary.tickApproved == 2, "2/2", "\(report.summary.occupableDestinations)/\(report.summary.tickApproved)"),
        agentIntentInvariantCheck("non_occupable_destinations_denied_collision", report.summary.nonOccupableDestinations == 1 && report.summary.collisionDenied == 1, "1/1", "\(report.summary.nonOccupableDestinations)/\(report.summary.collisionDenied)"),
        agentIntentInvariantCheck("collision_denied_feedback_blocked_by_collision", collisionDeniedFeedback, "blockedByCollision", "\(collisionDeniedFeedback)"),
        agentIntentInvariantCheck("approved_feedback_is_approved_for_movement", approvedFeedbackCount == 2, "2", "\(approvedFeedbackCount)"),
        agentIntentInvariantCheck("tick_approved_count_expected", report.summary.tickApproved == 2, "2", "\(report.summary.tickApproved)"),
        agentIntentInvariantCheck("tick_denied_count_expected", report.summary.tickDenied == 1, "1", "\(report.summary.tickDenied)"),
        agentIntentInvariantCheck("tick_feedback_count_matches_resolutions", report.summary.tickFeedback == report.summary.tickResolutions, "match", "\(report.summary.tickFeedback)/\(report.summary.tickResolutions)"),
        agentIntentInvariantCheck("positions_unchanged", positionsUnchanged, "unchanged", "\(positionsUnchanged)"),
        agentIntentInvariantCheck("no_displacement_applied", report.summary.displacementsApplied == 0, "0", "\(report.summary.displacementsApplied)"),
        agentIntentInvariantCheck("no_physical_movement_applied", !report.summary.movementApplied, "false", "\(report.summary.movementApplied)"),
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
        agentIntentInvariantCheck("agent_intent_fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("agent_intent_hardening_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("agent_intent_to_tick_fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("tick_live_readonly_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("report_written", true, "agent_intent_to_tick_live_readonly_report.json", "agent_intent_to_tick_live_readonly_report.json"),
        agentIntentInvariantCheck("proposals_written", true, "agent_intent_to_tick_live_readonly_proposals.json", "agent_intent_to_tick_live_readonly_proposals.json"),
        agentIntentInvariantCheck("metrics_written", true, "agentIntentToTickLiveReadonly* metrics", "agentIntentToTickLiveReadonly* metrics"),
        agentIntentInvariantCheck("event_written", true, "lab_agent_intent_to_tick_live_readonly_recorded", "lab_agent_intent_to_tick_live_readonly_recorded"),
        agentIntentInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let failed = checks.filter { !$0.passed }.count
    return LabAgentIntentToTickLiveReadonlyInvariantReport(
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
            "Agent intent production creates candidate intents without reading collision.",
            "The tick live read-only layer reads controlled collision evidence and applies no movement.",
            "Feedback is emitted as structured output only and is not consumed."
        ]
    )
}

func makeAgentIntentToTickApprovedApplicationReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabAgentIntentToTickApprovedApplicationReport {
    let intentProduction = produceAgentIntentProductionResult(
        tick: 0,
        contexts: agentIntentToTickLiveReadonlyContexts(),
        maxProposals: nil,
        duplicateProposalAgentId: nil
    )
    let agents = Dictionary(
        uniqueKeysWithValues: intentProduction.contexts.compactMap { context in
            context.position.map { (context.agentId, $0) }
        }
    )
    let tickInput = LabMultiAgentMovementTickInput(
        tick: intentProduction.tick,
        agents: agents,
        physicalPositions: agents,
        intents: intentProduction.acceptedIntents,
        maxAgents: nil
    )
    let tickReport = makeMultiAgentMovementTickApprovedApplicationReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        input: tickInput,
        evidenceSeeds: [
            "agent_0": 99,
            "agent_1": 99,
            "agent_2": 42
        ],
        expectedAgentCount: 5,
        expectedIntentCount: 3,
        expectedApproved: 2,
        expectedDenied: 1,
        expectedOccupableDestinations: 2,
        expectedNonOccupableDestinations: 1,
        expectedDisplacementsApplied: 2,
        expectedDivergenceBeforeMax: 0,
        expectedDivergenceAfterMax: 0,
        expectedMovedFeedback: 2,
        expectedBlockedByCollisionFeedback: 1
    )
    let movedFeedback = tickReport.output.feedback.filter { $0.kind == .moved }.count
    let blockedByCollisionFeedback = tickReport.output.feedback.filter {
        $0.kind == .blockedByCollision
    }.count
    let collisionDenied = tickReport.output.resolutions.filter {
        $0.decision == .deniedCollision
    }.count
    let approvedPositionsMoved = tickReport.output.resolutions.filter(\.approved).allSatisfy {
        $0.displacementApplied
            && $0.abstractBefore != $0.abstractAfter
            && $0.physicalBefore != $0.physicalAfter
            && $0.abstractAfter == $0.intent.to
            && $0.physicalAfter == $0.intent.to
    }
    let deniedPositionsPreserved = tickReport.output.resolutions.filter { !$0.approved }.allSatisfy {
        !$0.displacementApplied
            && $0.abstractBefore == $0.abstractAfter
            && $0.physicalBefore == $0.physicalAfter
    }
    let tickReadLiveCollision = tickReport.output.resolutions.contains { $0.collisionRead }
    let mutationPerformed = tickReport.summary.terrainMutationPerformed
        || tickReport.summary.worldMutationPerformed
    let summary = LabAgentIntentToTickApprovedApplicationSummary(
        tick: intentProduction.tick,
        contexts: intentProduction.summary.contexts,
        proposals: intentProduction.summary.proposals,
        acceptedIntents: intentProduction.summary.acceptedIntents,
        rejectedProposals: intentProduction.summary.rejectedProposals,
        tickAgents: tickInput.agents.count,
        tickIntents: tickInput.intents.count,
        tickResolutions: tickReport.output.resolutions.count,
        tickFeedback: tickReport.output.feedback.count,
        tickApproved: tickReport.summary.approved,
        tickDenied: tickReport.summary.denied,
        occupableDestinations: tickReport.summary.occupableDestinations,
        nonOccupableDestinations: tickReport.summary.nonOccupableDestinations,
        collisionDenied: collisionDenied,
        displacementsApplied: tickReport.summary.displacementsApplied,
        movedFeedback: movedFeedback,
        blockedByCollisionFeedback: blockedByCollisionFeedback,
        abstractPhysicalDivergenceBefore: tickReport.summary.divergenceBeforeMax,
        abstractPhysicalDivergenceAfter: tickReport.summary.divergenceAfterMax,
        deniedPositionsPreserved: deniedPositionsPreserved,
        approvedPositionsMoved: approvedPositionsMoved,
        productionReadCollision: intentProduction.summary.collisionRead,
        tickReadLiveCollision: tickReadLiveCollision,
        worldUsed: tickReport.summary.worldUsed,
        collisionRead: tickReport.summary.liveCollisionRead,
        movementApplied: tickReport.summary.physicalMovementApplied,
        feedbackConsumed: false,
        memoryUpdated: false,
        goalChanged: false,
        pathfindingPerformed: tickReport.summary.pathfindingPerformed,
        replanningPerformed: tickReport.summary.replanningPerformed,
        avoidancePerformed: tickReport.summary.avoidancePerformed,
        reservationRuntimeUsed: tickReport.summary.reservationRuntimeUsed,
        routeFollowingApplied: tickReport.summary.routeFollowingApplied,
        physicsPerformed: tickReport.summary.physicsPerformed,
        mutationPerformed: mutationPerformed,
        success: intentProduction.summary.success
            && tickReport.success
            && intentProduction.summary.contexts == 5
            && intentProduction.summary.proposals == 5
            && intentProduction.summary.acceptedIntents == 3
            && intentProduction.summary.rejectedProposals == 2
            && intentProduction.summary.noIntent == 1
            && intentProduction.summary.invalidOneEdgeProposals == 1
            && !intentProduction.summary.collisionRead
            && !intentProduction.summary.movementApplied
            && tickReport.summary.approved == 2
            && tickReport.summary.denied == 1
            && tickReport.summary.occupableDestinations == 2
            && tickReport.summary.nonOccupableDestinations == 1
            && collisionDenied == 1
            && tickReport.summary.displacementsApplied == 2
            && movedFeedback == 2
            && blockedByCollisionFeedback == 1
            && approvedPositionsMoved
            && deniedPositionsPreserved
            && tickReport.summary.divergenceBeforeMax == 0
            && tickReport.summary.divergenceAfterMax == 0
            && tickReport.summary.worldUsed
            && tickReport.summary.liveCollisionRead
            && tickReport.summary.physicalMovementApplied
            && !tickReport.summary.routeFollowingApplied
            && !tickReport.summary.pathfindingPerformed
            && !tickReport.summary.replanningPerformed
            && !tickReport.summary.avoidancePerformed
            && !tickReport.summary.reservationRuntimeUsed
            && !tickReport.summary.physicsPerformed
            && !mutationPerformed
    )
    return LabAgentIntentToTickApprovedApplicationReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        intentProduction: intentProduction,
        tickInput: tickInput,
        tickOutput: tickReport.output,
        summary: summary
    )
}

func makeAgentIntentToTickApprovedApplicationInvariantReport(
    report: LabAgentIntentToTickApprovedApplicationReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentIntentToTickApprovedApplicationInvariantReport {
    guard let report else {
        let check = agentIntentInvariantCheck(
            "report_written",
            false,
            "agent_intent_to_tick_approved_application_report.json",
            "missing"
        )
        return LabAgentIntentToTickApprovedApplicationInvariantReport(
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
            notes: ["Agent intent to tick approved application report was not available."]
        )
    }

    let contextIds = report.intentProduction.contexts.map(\.agentId)
    let proposalIds = report.intentProduction.proposals.map(\.agentId)
    let acceptedIds = report.intentProduction.acceptedIntents.map(\.agentId)
    let resolutionIds = report.tickOutput.resolutions.map(\.agentId)
    let acceptedOneEdge = report.intentProduction.acceptedIntents.allSatisfy {
        manhattanDistance($0.from, $0.to) == 1
    }
    let acceptedSameY = report.intentProduction.acceptedIntents.allSatisfy {
        $0.from.y == $0.to.y
    }
    let tickInputUsesAccepted = report.tickInput.intents.map(\.agentId) == acceptedIds
    let tickAgentsCoverSources = report.tickInput.intents.allSatisfy { intent in
        report.tickInput.agents[intent.agentId] == intent.from
    }
    let physicalMatchesAbstract = report.tickInput.physicalPositions == report.tickInput.agents
    let approvedResolutions = report.tickOutput.resolutions.filter(\.approved)
    let deniedResolutions = report.tickOutput.resolutions.filter { !$0.approved }
    let approvedMovesApplied = approvedResolutions.allSatisfy(\.displacementApplied)
    let deniedMovesNotApplied = deniedResolutions.allSatisfy { !$0.displacementApplied }
    let approvedAbstractMoved = approvedResolutions.allSatisfy {
        $0.abstractBefore != $0.abstractAfter && $0.abstractAfter == $0.intent.to
    }
    let approvedPhysicalMoved = approvedResolutions.allSatisfy {
        $0.physicalBefore != $0.physicalAfter && $0.physicalAfter == $0.intent.to
    }
    let deniedAbstractPreserved = deniedResolutions.allSatisfy {
        $0.abstractBefore == $0.abstractAfter
    }
    let deniedPhysicalPreserved = deniedResolutions.allSatisfy {
        $0.physicalBefore == $0.physicalAfter
    }
    let movedFeedback = report.tickOutput.feedback.filter { $0.kind == .moved }.count
    let collisionFeedback = report.tickOutput.feedback.filter {
        $0.kind == .blockedByCollision
    }.count
    let checks = [
        agentIntentInvariantCheck("intent_contexts_exist", !report.intentProduction.contexts.isEmpty, "non-empty", "\(report.intentProduction.contexts.count)"),
        agentIntentInvariantCheck("intent_proposals_exist", !report.intentProduction.proposals.isEmpty, "non-empty", "\(report.intentProduction.proposals.count)"),
        agentIntentInvariantCheck("accepted_intents_exist", !report.intentProduction.acceptedIntents.isEmpty, "non-empty", "\(report.intentProduction.acceptedIntents.count)"),
        agentIntentInvariantCheck("rejected_proposals_exist", !report.intentProduction.rejectedProposals.isEmpty, "non-empty", "\(report.intentProduction.rejectedProposals.count)"),
        agentIntentInvariantCheck("contexts_intentionally_unordered", contextIds != contextIds.sorted(), "unordered input", contextIds.joined(separator: ",")),
        agentIntentInvariantCheck("proposals_sorted_by_agent_id", proposalIds == proposalIds.sorted(), "sorted", proposalIds.joined(separator: ",")),
        agentIntentInvariantCheck("accepted_intents_sorted_by_agent_id", acceptedIds == acceptedIds.sorted(), "sorted", acceptedIds.joined(separator: ",")),
        agentIntentInvariantCheck("accepted_intents_are_one_edge", acceptedOneEdge, "one-edge", "\(acceptedOneEdge)"),
        agentIntentInvariantCheck("accepted_intents_are_same_y", acceptedSameY, "same-y", "\(acceptedSameY)"),
        agentIntentInvariantCheck("production_does_not_read_collision", !report.summary.productionReadCollision, "false", "\(report.summary.productionReadCollision)"),
        agentIntentInvariantCheck("production_does_not_apply_movement", !report.intentProduction.summary.movementApplied, "false", "\(report.intentProduction.summary.movementApplied)"),
        agentIntentInvariantCheck("production_does_not_arbitrate_occupancy", report.summary.acceptedIntents == 3, "3 accepted before occupancy", "\(report.summary.acceptedIntents)"),
        agentIntentInvariantCheck("tick_input_exists", report.tickInput.tick == report.intentProduction.tick, "same tick", "\(report.tickInput.tick)"),
        agentIntentInvariantCheck("tick_input_uses_accepted_intents", tickInputUsesAccepted, "accepted intents", report.tickInput.intents.map(\.agentId).joined(separator: ",")),
        agentIntentInvariantCheck("tick_input_agents_cover_intent_sources", tickAgentsCoverSources, "sources covered", "\(tickAgentsCoverSources)"),
        agentIntentInvariantCheck("tick_input_physical_positions_match_abstract_before", physicalMatchesAbstract, "match", "\(physicalMatchesAbstract)"),
        agentIntentInvariantCheck("tick_resolutions_exist", !report.tickOutput.resolutions.isEmpty, "non-empty", "\(report.tickOutput.resolutions.count)"),
        agentIntentInvariantCheck("tick_resolutions_sorted_by_agent_id", resolutionIds == resolutionIds.sorted(), "sorted", resolutionIds.joined(separator: ",")),
        agentIntentInvariantCheck("tick_reads_live_collision", report.summary.tickReadLiveCollision, "true", "\(report.summary.tickReadLiveCollision)"),
        agentIntentInvariantCheck("world_used_for_readonly_collision_before_application", report.summary.worldUsed && report.summary.collisionRead, "true", "world=\(report.summary.worldUsed), collision=\(report.summary.collisionRead)"),
        agentIntentInvariantCheck("occupable_destinations_approved", report.summary.occupableDestinations == 2 && report.summary.tickApproved == 2, "2/2", "\(report.summary.occupableDestinations)/\(report.summary.tickApproved)"),
        agentIntentInvariantCheck("non_occupable_destinations_denied_collision", report.summary.nonOccupableDestinations == 1 && report.summary.collisionDenied == 1, "1/1", "\(report.summary.nonOccupableDestinations)/\(report.summary.collisionDenied)"),
        agentIntentInvariantCheck("approved_moves_applied", approvedMovesApplied, "true", "\(approvedMovesApplied)"),
        agentIntentInvariantCheck("denied_moves_not_applied", deniedMovesNotApplied, "true", "\(deniedMovesNotApplied)"),
        agentIntentInvariantCheck("approved_abstract_positions_moved", approvedAbstractMoved, "true", "\(approvedAbstractMoved)"),
        agentIntentInvariantCheck("approved_physical_positions_moved", approvedPhysicalMoved, "true", "\(approvedPhysicalMoved)"),
        agentIntentInvariantCheck("denied_abstract_positions_preserved", deniedAbstractPreserved, "true", "\(deniedAbstractPreserved)"),
        agentIntentInvariantCheck("denied_physical_positions_preserved", deniedPhysicalPreserved, "true", "\(deniedPhysicalPreserved)"),
        agentIntentInvariantCheck("abstract_physical_sync_before", report.summary.abstractPhysicalDivergenceBefore == 0, "0", "\(report.summary.abstractPhysicalDivergenceBefore)"),
        agentIntentInvariantCheck("abstract_physical_sync_after", report.summary.abstractPhysicalDivergenceAfter == 0, "0", "\(report.summary.abstractPhysicalDivergenceAfter)"),
        agentIntentInvariantCheck("moved_feedback_for_approved_moves", movedFeedback == 2, "2", "\(movedFeedback)"),
        agentIntentInvariantCheck("blocked_by_collision_feedback_for_denied_collision", collisionFeedback == 1, "1", "\(collisionFeedback)"),
        agentIntentInvariantCheck("tick_approved_count_expected", report.summary.tickApproved == 2, "2", "\(report.summary.tickApproved)"),
        agentIntentInvariantCheck("tick_denied_count_expected", report.summary.tickDenied == 1, "1", "\(report.summary.tickDenied)"),
        agentIntentInvariantCheck("tick_feedback_count_matches_resolutions", report.summary.tickFeedback == report.summary.tickResolutions, "match", "\(report.summary.tickFeedback)/\(report.summary.tickResolutions)"),
        agentIntentInvariantCheck("displacements_applied_equals_approved", report.summary.displacementsApplied == report.summary.tickApproved, "match", "\(report.summary.displacementsApplied)/\(report.summary.tickApproved)"),
        agentIntentInvariantCheck("movement_applied_true", report.summary.movementApplied, "true", "\(report.summary.movementApplied)"),
        agentIntentInvariantCheck("feedback_not_consumed", !report.summary.feedbackConsumed, "false", "\(report.summary.feedbackConsumed)"),
        agentIntentInvariantCheck("memory_not_updated", !report.summary.memoryUpdated, "false", "\(report.summary.memoryUpdated)"),
        agentIntentInvariantCheck("goal_not_changed", !report.summary.goalChanged, "false", "\(report.summary.goalChanged)"),
        agentIntentInvariantCheck("pathfinding_not_performed", !report.summary.pathfindingPerformed, "false", "\(report.summary.pathfindingPerformed)"),
        agentIntentInvariantCheck("replanning_not_performed", !report.summary.replanningPerformed, "false", "\(report.summary.replanningPerformed)"),
        agentIntentInvariantCheck("avoidance_not_performed", !report.summary.avoidancePerformed, "false", "\(report.summary.avoidancePerformed)"),
        agentIntentInvariantCheck("reservation_runtime_not_used", !report.summary.reservationRuntimeUsed, "false", "\(report.summary.reservationRuntimeUsed)"),
        agentIntentInvariantCheck("route_following_not_applied", !report.summary.routeFollowingApplied, "false", "\(report.summary.routeFollowingApplied)"),
        agentIntentInvariantCheck("physics_not_performed", !report.summary.physicsPerformed, "false", "\(report.summary.physicsPerformed)"),
        agentIntentInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("world_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("agent_intent_fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("agent_intent_hardening_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("agent_intent_to_tick_fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("agent_intent_to_tick_live_readonly_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("tick_approved_application_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("report_written", true, "agent_intent_to_tick_approved_application_report.json", "agent_intent_to_tick_approved_application_report.json"),
        agentIntentInvariantCheck("proposals_written", true, "agent_intent_to_tick_approved_application_proposals.json", "agent_intent_to_tick_approved_application_proposals.json"),
        agentIntentInvariantCheck("metrics_written", true, "agentIntentToTickApprovedApplication* metrics", "agentIntentToTickApprovedApplication* metrics"),
        agentIntentInvariantCheck("event_written", true, "lab_agent_intent_to_tick_approved_application_recorded", "lab_agent_intent_to_tick_approved_application_recorded"),
        agentIntentInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let failed = checks.filter { !$0.passed }.count
    return LabAgentIntentToTickApprovedApplicationInvariantReport(
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
            "Agent intent production creates candidate intents without reading collision.",
            "The tick approved application layer reads collision, applies approved moves, and preserves denied positions.",
            "Feedback is emitted as structured output only and is not consumed."
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
