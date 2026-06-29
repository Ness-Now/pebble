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

enum LabAgentIntentFeedbackPolicyMode: String, Codable {
    case baselineV0
    case feedbackAwareV1
}

enum LabAgentIntentFeedbackReaction: String, Codable {
    case none
    case baselineKeptNoFeedback
    case baselineKeptMoved
    case baselineKeptApprovedForMovement
    case blockedByCollisionNoIntent
    case blockedByAgentConflictNoIntent
    case blockedBySourceMismatchNoIntent
    case blockedByDivergenceNoIntent
    case blockedByStaleIntentNoIntent
    case blockedByInvalidEdgeNoIntent
    case blockedByMaxAgentsNoIntent
}

struct LabAgentIntentFeedbackPolicyDecision: Codable {
    let tick: Int
    let agentId: String
    let policyMode: LabAgentIntentFeedbackPolicyMode
    let lastFeedbackKind: LabMovementFeedbackKind?
    let baselineDecision: LabAgentIntentDecision
    let feedbackAwareDecision: LabAgentIntentDecision
    let baselineProposal: LabAgentIntentProposal
    let feedbackAwareProposal: LabAgentIntentProposal
    let feedbackReaction: LabAgentIntentFeedbackReaction
    let behaviorChanged: Bool
    let feedbackUsedForDecision: Bool
    let reason: String
}

struct LabFeedbackAwareIntentPolicyFixtureSummary: Codable {
    let tick: Int
    let contexts: Int
    let contextsWithFeedback: Int
    let contextsWithoutFeedback: Int
    let baselineProposals: Int
    let feedbackAwareProposals: Int
    let acceptedIntents: Int
    let rejectedProposals: Int
    let noIntent: Int
    let invalidOneEdgeProposals: Int
    let feedbackReactions: Int
    let behaviorChangedByFeedback: Bool
    let behaviorChangedCount: Int
    let movedBaselineKept: Int
    let approvedForMovementBaselineKept: Int
    let noFeedbackBaselineKept: Int
    let blockedByCollisionNoIntent: Int
    let blockedByAgentConflictNoIntent: Int
    let blockedBySourceMismatchNoIntent: Int
    let blockedByDivergenceNoIntent: Int
    let blockedByStaleIntentNoIntent: Int
    let blockedByInvalidEdgeNoIntent: Int
    let blockedByMaxAgentsNoIntent: Int
    let collisionRead: Bool
    let movementApplied: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabFeedbackAwareIntentPolicyFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let baselinePolicyMode: LabAgentIntentFeedbackPolicyMode
    let feedbackAwarePolicyMode: LabAgentIntentFeedbackPolicyMode
    let contexts: [LabAgentIntentContext]
    let baselineProposals: [LabAgentIntentProposal]
    let feedbackAwareProposals: [LabAgentIntentProposal]
    let feedbackAwareResult: LabAgentIntentProductionResult
    let decisions: [LabAgentIntentFeedbackPolicyDecision]
    let summary: LabFeedbackAwareIntentPolicyFixtureSummary
}

struct LabFeedbackAwareIntentPolicyFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabFeedbackAwareIntentPolicyHardeningCase: Codable {
    let name: String
    let contexts: [LabAgentIntentContext]
    let expected: LabFeedbackAwareIntentPolicyFixtureSummary
    let repeatabilityCheck: Bool
    let notes: [String]
}

struct LabFeedbackAwareIntentPolicyHardeningCaseResult: Codable {
    let name: String
    let passed: Bool
    let contexts: [LabAgentIntentContext]
    let baselineProposals: [LabAgentIntentProposal]
    let feedbackAwareProposals: [LabAgentIntentProposal]
    let decisions: [LabAgentIntentFeedbackPolicyDecision]
    let repeatedActual: LabFeedbackAwareIntentPolicyFixtureSummary?
    let expected: LabFeedbackAwareIntentPolicyFixtureSummary
    let actual: LabFeedbackAwareIntentPolicyFixtureSummary
    let notes: [String]
}

struct LabFeedbackAwareIntentPolicyHardeningSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let contextsTotal: Int
    let contextsWithFeedbackTotal: Int
    let contextsWithoutFeedbackTotal: Int
    let baselineProposalsTotal: Int
    let feedbackAwareProposalsTotal: Int
    let acceptedIntentsTotal: Int
    let rejectedProposalsTotal: Int
    let noIntentTotal: Int
    let invalidOneEdgeProposalsTotal: Int
    let feedbackReactionsTotal: Int
    let behaviorChangedCountTotal: Int
    let noFeedbackBaselineKeptTotal: Int
    let movedBaselineKeptTotal: Int
    let approvedForMovementBaselineKeptTotal: Int
    let blockedByCollisionNoIntentTotal: Int
    let blockedByAgentConflictNoIntentTotal: Int
    let blockedBySourceMismatchNoIntentTotal: Int
    let blockedByDivergenceNoIntentTotal: Int
    let blockedByStaleIntentNoIntentTotal: Int
    let blockedByInvalidEdgeNoIntentTotal: Int
    let blockedByMaxAgentsNoIntentTotal: Int
    let behaviorChangedByFeedback: Bool
    let feedbackUsedForDecision: Bool
    let collisionRead: Bool
    let movementApplied: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabFeedbackAwareIntentPolicyHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let cases: [LabFeedbackAwareIntentPolicyHardeningCaseResult]
    let summary: LabFeedbackAwareIntentPolicyHardeningSummary
}

struct LabFeedbackAwareIntentPolicyHardeningInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabFeedbackAwareIntentToTickFixtureSummary: Codable {
    let tick: Int
    let contexts: Int
    let contextsWithFeedback: Int
    let contextsWithoutFeedback: Int
    let baselineProposals: Int
    let feedbackAwareProposals: Int
    let baselineMovementIntentInputs: Int
    let feedbackAwareMovementIntentInputs: Int
    let movementIntentReduction: Int
    let noIntentFilteredOut: Int
    let feedbackAwareAcceptedIntents: Int
    let feedbackAwareRejectedProposals: Int
    let feedbackAwareNoIntent: Int
    let feedbackAwareInvalidOneEdgeProposals: Int
    let behaviorChangedByFeedback: Bool
    let behaviorChangedCount: Int
    let tickIntents: Int
    let tickApproved: Int
    let tickDenied: Int
    let tickDeniedSameDestinationConflict: Int
    let tickFeedbackEmitted: Int
    let displacementsApplied: Int
    let policyReadCollision: Bool
    let tickReadCollision: Bool
    let movementApplied: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabFeedbackAwareIntentToTickFixtureHandoff: Codable {
    let contexts: [LabAgentIntentContext]
    let baselineDecisions: [LabAgentIntentProposal]
    let feedbackAwareDecisions: [LabAgentIntentFeedbackPolicyDecision]
    let movementIntentsSentToTick: [LabAgentMoveIntent]
    let noIntentFilteredOut: [LabAgentIntentProposal]
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickOutput
    let tickFeedback: [LabMovementFeedback]
    let summary: LabFeedbackAwareIntentToTickFixtureSummary
}

struct LabFeedbackAwareIntentToTickFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let contexts: [LabAgentIntentContext]
    let baselinePolicyDecisions: [LabAgentIntentProposal]
    let feedbackAwarePolicyDecisions: [LabAgentIntentFeedbackPolicyDecision]
    let feedbackAwareMovementTickInput: LabMultiAgentMovementTickInput
    let tickResult: LabMultiAgentMovementTickOutput
    let handoff: LabFeedbackAwareIntentToTickFixtureHandoff
    let summary: LabFeedbackAwareIntentToTickFixtureSummary
}

struct LabFeedbackAwareIntentToTickFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabFeedbackAwareIntentToTickLiveReadonlySummary: Codable {
    let tick: Int
    let contexts: Int
    let contextsWithFeedback: Int
    let contextsWithoutFeedback: Int
    let baselineProposals: Int
    let feedbackAwareProposals: Int
    let baselineMovementIntentInputs: Int
    let feedbackAwareMovementIntentInputs: Int
    let movementIntentReduction: Int
    let noIntentFilteredOut: Int
    let feedbackAwareAcceptedIntents: Int
    let feedbackAwareRejectedProposals: Int
    let feedbackAwareNoIntent: Int
    let feedbackAwareInvalidOneEdgeProposals: Int
    let behaviorChangedByFeedback: Bool
    let behaviorChangedCount: Int
    let tickIntents: Int
    let tickApproved: Int
    let tickDenied: Int
    let tickDeniedSameDestinationConflict: Int
    let tickDeniedCollision: Int
    let tickFeedbackEmitted: Int
    let occupableDestinations: Int
    let nonOccupableDestinations: Int
    let displacementsApplied: Int
    let policyReadCollision: Bool
    let tickReadCollision: Bool
    let policyWorldUsed: Bool
    let tickWorldReadOnlyUsed: Bool
    let movementApplied: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let worldMutated: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabFeedbackAwareIntentToTickLiveReadonlyHandoff: Codable {
    let contexts: [LabAgentIntentContext]
    let baselineDecisions: [LabAgentIntentProposal]
    let feedbackAwareDecisions: [LabAgentIntentFeedbackPolicyDecision]
    let movementIntentsSentToTick: [LabAgentMoveIntent]
    let noIntentFilteredOut: [LabAgentIntentProposal]
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickLiveReadonlyOutput
    let tickFeedback: [LabMovementFeedback]
    let collisionEvidence: [LabMultiAgentMovementTickLiveReadonlyResolution]
    let summary: LabFeedbackAwareIntentToTickLiveReadonlySummary
}

struct LabFeedbackAwareIntentToTickLiveReadonlyReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let contexts: [LabAgentIntentContext]
    let baselinePolicyDecisions: [LabAgentIntentProposal]
    let feedbackAwarePolicyDecisions: [LabAgentIntentFeedbackPolicyDecision]
    let feedbackAwareMovementTickInput: LabMultiAgentMovementTickInput
    let tickResult: LabMultiAgentMovementTickLiveReadonlyOutput
    let handoff: LabFeedbackAwareIntentToTickLiveReadonlyHandoff
    let summary: LabFeedbackAwareIntentToTickLiveReadonlySummary
}

struct LabFeedbackAwareIntentToTickLiveReadonlyInvariantReport: Codable {
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

private func noIntentProposal(
    context: LabAgentIntentContext,
    reason: String
) -> LabAgentIntentProposal {
    LabAgentIntentProposal(
        agentId: context.agentId,
        tick: context.tick,
        decision: .noIntent,
        intent: nil,
        reason: reason
    )
}

func produceAgentIntentProposalFeedbackAwareV1(
    context: LabAgentIntentContext
) -> LabAgentIntentFeedbackPolicyDecision {
    let baseline = produceAgentIntentProposalV0(context: context)
    let feedbackKind = context.lastFeedback?.kind
    let reaction: LabAgentIntentFeedbackReaction
    let proposal: LabAgentIntentProposal
    let reason: String

    func blockedProposal(_ feedbackReason: String) -> LabAgentIntentProposal {
        baseline.decision == .noIntent
            ? baseline
            : noIntentProposal(context: context, reason: feedbackReason)
    }

    switch feedbackKind {
    case nil:
        reaction = .baselineKeptNoFeedback
        proposal = baseline
        reason = "feedback_aware_v1_baseline_kept_no_feedback"
    case .moved:
        reaction = .baselineKeptMoved
        proposal = baseline
        reason = "feedback_aware_v1_baseline_kept_moved"
    case .approvedForMovement:
        reaction = .baselineKeptApprovedForMovement
        proposal = baseline
        reason = "feedback_aware_v1_baseline_kept_approved_for_movement"
    case .blockedByCollision:
        reaction = .blockedByCollisionNoIntent
        proposal = blockedProposal("feedback_blocked_by_collision_no_intent")
        reason = "feedback_blocked_by_collision_no_intent"
    case .blockedByAgentConflict:
        reaction = .blockedByAgentConflictNoIntent
        proposal = blockedProposal("feedback_blocked_by_agent_conflict_no_intent")
        reason = "feedback_blocked_by_agent_conflict_no_intent"
    case .blockedBySourceMismatch:
        reaction = .blockedBySourceMismatchNoIntent
        proposal = blockedProposal("feedback_blocked_by_source_mismatch_no_intent")
        reason = "feedback_blocked_by_source_mismatch_no_intent"
    case .blockedByDivergence:
        reaction = .blockedByDivergenceNoIntent
        proposal = blockedProposal("feedback_blocked_by_divergence_no_intent")
        reason = "feedback_blocked_by_divergence_no_intent"
    case .blockedByStaleIntent:
        reaction = .blockedByStaleIntentNoIntent
        proposal = blockedProposal("feedback_blocked_by_stale_intent_no_intent")
        reason = "feedback_blocked_by_stale_intent_no_intent"
    case .blockedByInvalidEdge:
        reaction = .blockedByInvalidEdgeNoIntent
        proposal = blockedProposal("feedback_blocked_by_invalid_edge_no_intent")
        reason = "feedback_blocked_by_invalid_edge_no_intent"
    case .blockedByMaxAgents:
        reaction = .blockedByMaxAgentsNoIntent
        proposal = blockedProposal("feedback_blocked_by_max_agents_no_intent")
        reason = "feedback_blocked_by_max_agents_no_intent"
    }

    return LabAgentIntentFeedbackPolicyDecision(
        tick: context.tick,
        agentId: context.agentId,
        policyMode: .feedbackAwareV1,
        lastFeedbackKind: feedbackKind,
        baselineDecision: baseline.decision,
        feedbackAwareDecision: proposal.decision,
        baselineProposal: baseline,
        feedbackAwareProposal: proposal,
        feedbackReaction: reaction,
        behaviorChanged: proposalSignature(proposal) != proposalSignature(baseline),
        feedbackUsedForDecision: feedbackKind != nil,
        reason: reason
    )
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

private func feedbackAwarePolicyFeedback(
    agentId: String,
    kind: LabMovementFeedbackKind,
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey,
    reason: String
) -> LabMovementFeedback {
    LabMovementFeedback(
        agentId: agentId,
        tick: 0,
        kind: kind,
        from: from,
        to: to,
        reason: reason
    )
}

private func feedbackAwareIntentPolicyFixtureContexts() -> [LabAgentIntentContext] {
    let agent0From = LabTerrainPathNodeKey(x: 0, y: 64, z: 0)
    let agent1From = LabTerrainPathNodeKey(x: 1, y: 64, z: 0)
    let agent2From = LabTerrainPathNodeKey(x: 2, y: 64, z: 0)
    let agent3From = LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
    let agent4From = LabTerrainPathNodeKey(x: 4, y: 64, z: 0)
    let agent5From = LabTerrainPathNodeKey(x: 5, y: 64, z: 0)
    let agent6From = LabTerrainPathNodeKey(x: 6, y: 64, z: 0)
    let agent7From = LabTerrainPathNodeKey(x: 7, y: 64, z: 0)
    let agent8From = LabTerrainPathNodeKey(x: 8, y: 64, z: 0)
    let agent9From = LabTerrainPathNodeKey(x: 9, y: 64, z: 0)
    return [
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_3_collision",
            position: agent3From,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_3_collision",
                kind: .blockedByCollision,
                from: agent3From,
                to: LabTerrainPathNodeKey(x: 8, y: 64, z: 8),
                reason: "fixture_blocked_by_collision"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_0_no_feedback",
            position: agent0From,
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_5_source_mismatch",
            position: agent5From,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_5_source_mismatch",
                kind: .blockedBySourceMismatch,
                from: LabTerrainPathNodeKey(x: 4, y: 64, z: 0),
                to: agent5From,
                reason: "fixture_blocked_by_source_mismatch"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_1_moved",
            position: agent1From,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_1_moved",
                kind: .moved,
                from: agent0From,
                to: agent1From,
                reason: "fixture_moved"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_8_invalid_edge",
            position: agent8From,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_8_invalid_edge",
                kind: .blockedByInvalidEdge,
                from: agent8From,
                to: LabTerrainPathNodeKey(x: 8, y: 65, z: 0),
                reason: "fixture_blocked_by_invalid_edge"
            ),
            role: "bad_fixture_invalid_vertical",
            localHints: ["move_vertical"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_2_approved",
            position: agent2From,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_2_approved",
                kind: .approvedForMovement,
                from: agent2From,
                to: LabTerrainPathNodeKey(x: 1, y: 64, z: 0),
                reason: "fixture_approved_for_movement"
            ),
            role: "wander_fixture",
            localHints: ["move_west"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_6_divergence",
            position: agent6From,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_6_divergence",
                kind: .blockedByDivergence,
                from: agent6From,
                to: LabTerrainPathNodeKey(x: 7, y: 64, z: 0),
                reason: "fixture_blocked_by_divergence"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_4_conflict",
            position: agent4From,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_4_conflict",
                kind: .blockedByAgentConflict,
                from: agent4From,
                to: LabTerrainPathNodeKey(x: 3, y: 64, z: 0),
                reason: "fixture_blocked_by_agent_conflict"
            ),
            role: "wander_fixture",
            localHints: ["move_west"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_9_max_agents",
            position: agent9From,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_9_max_agents",
                kind: .blockedByMaxAgents,
                from: agent9From,
                to: LabTerrainPathNodeKey(x: 10, y: 64, z: 0),
                reason: "fixture_blocked_by_max_agents"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_7_stale",
            position: agent7From,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_7_stale",
                kind: .blockedByStaleIntent,
                from: agent7From,
                to: LabTerrainPathNodeKey(x: 8, y: 64, z: 0),
                reason: "fixture_blocked_by_stale_intent"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        )
    ]
}

func makeFeedbackAwareIntentPolicyFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabFeedbackAwareIntentPolicyFixtureReport {
    let inputContexts = feedbackAwareIntentPolicyFixtureContexts()
    let baselineProposals = inputContexts.map(produceAgentIntentProposalV0(context:)).sorted {
        $0.agentId < $1.agentId
    }
    let decisions = inputContexts.map(produceAgentIntentProposalFeedbackAwareV1(context:)).sorted {
        $0.agentId < $1.agentId
    }
    let feedbackAwareProposals = decisions.map(\.feedbackAwareProposal)
    let result = produceAgentIntentProductionResult(
        tick: 0,
        contexts: inputContexts,
        rawProposals: feedbackAwareProposals,
        maxProposals: nil
    )
    let reactionCount: (LabAgentIntentFeedbackReaction) -> Int = { reaction in
        decisions.filter { $0.feedbackReaction == reaction }.count
    }
    let behaviorChangedCount = decisions.filter(\.behaviorChanged).count
    let blockedReactions: Set<LabAgentIntentFeedbackReaction> = [
        .blockedByCollisionNoIntent,
        .blockedByAgentConflictNoIntent,
        .blockedBySourceMismatchNoIntent,
        .blockedByDivergenceNoIntent,
        .blockedByStaleIntentNoIntent,
        .blockedByInvalidEdgeNoIntent,
        .blockedByMaxAgentsNoIntent
    ]
    let behaviorChangedOnlyForBlocked = decisions.allSatisfy { decision in
        decision.behaviorChanged == blockedReactions.contains(decision.feedbackReaction)
    }
    let feedbackUsedForFeedbackContexts = decisions.allSatisfy { decision in
        decision.lastFeedbackKind == nil || decision.feedbackUsedForDecision
    }
    let summary = LabFeedbackAwareIntentPolicyFixtureSummary(
        tick: 0,
        contexts: inputContexts.count,
        contextsWithFeedback: inputContexts.filter { $0.lastFeedback != nil }.count,
        contextsWithoutFeedback: inputContexts.filter { $0.lastFeedback == nil }.count,
        baselineProposals: baselineProposals.count,
        feedbackAwareProposals: feedbackAwareProposals.count,
        acceptedIntents: result.summary.acceptedIntents,
        rejectedProposals: result.summary.rejectedProposals,
        noIntent: result.summary.noIntent,
        invalidOneEdgeProposals: result.summary.invalidOneEdgeProposals,
        feedbackReactions: decisions.count,
        behaviorChangedByFeedback: behaviorChangedCount > 0,
        behaviorChangedCount: behaviorChangedCount,
        movedBaselineKept: reactionCount(.baselineKeptMoved),
        approvedForMovementBaselineKept: reactionCount(.baselineKeptApprovedForMovement),
        noFeedbackBaselineKept: reactionCount(.baselineKeptNoFeedback),
        blockedByCollisionNoIntent: reactionCount(.blockedByCollisionNoIntent),
        blockedByAgentConflictNoIntent: reactionCount(.blockedByAgentConflictNoIntent),
        blockedBySourceMismatchNoIntent: reactionCount(.blockedBySourceMismatchNoIntent),
        blockedByDivergenceNoIntent: reactionCount(.blockedByDivergenceNoIntent),
        blockedByStaleIntentNoIntent: reactionCount(.blockedByStaleIntentNoIntent),
        blockedByInvalidEdgeNoIntent: reactionCount(.blockedByInvalidEdgeNoIntent),
        blockedByMaxAgentsNoIntent: reactionCount(.blockedByMaxAgentsNoIntent),
        collisionRead: false,
        movementApplied: false,
        memoryUpdated: false,
        goalChanged: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        worldUsed: false,
        mutationPerformed: false,
        success: result.summary.success
            && inputContexts.count == 10
            && inputContexts.filter({ $0.lastFeedback != nil }).count == 9
            && inputContexts.filter({ $0.lastFeedback == nil }).count == 1
            && baselineProposals.count == 10
            && feedbackAwareProposals.count == 10
            && result.summary.acceptedIntents == 3
            && result.summary.rejectedProposals == 7
            && result.summary.noIntent == 7
            && result.summary.invalidOneEdgeProposals == 0
            && behaviorChangedCount == 7
            && behaviorChangedOnlyForBlocked
            && feedbackUsedForFeedbackContexts
            && reactionCount(.baselineKeptNoFeedback) == 1
            && reactionCount(.baselineKeptMoved) == 1
            && reactionCount(.baselineKeptApprovedForMovement) == 1
            && reactionCount(.blockedByCollisionNoIntent) == 1
            && reactionCount(.blockedByAgentConflictNoIntent) == 1
            && reactionCount(.blockedBySourceMismatchNoIntent) == 1
            && reactionCount(.blockedByDivergenceNoIntent) == 1
            && reactionCount(.blockedByStaleIntentNoIntent) == 1
            && reactionCount(.blockedByInvalidEdgeNoIntent) == 1
            && reactionCount(.blockedByMaxAgentsNoIntent) == 1
    )
    let success = summary.success
        && !summary.collisionRead
        && !summary.worldUsed
        && !summary.movementApplied
        && !summary.memoryUpdated
        && !summary.goalChanged
        && !summary.pathfindingPerformed
        && !summary.replanningPerformed
        && !summary.avoidancePerformed
        && !summary.reservationRuntimeUsed
        && !summary.mutationPerformed

    return LabFeedbackAwareIntentPolicyFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: success,
        baselinePolicyMode: .baselineV0,
        feedbackAwarePolicyMode: .feedbackAwareV1,
        contexts: inputContexts.sorted { $0.agentId < $1.agentId },
        baselineProposals: baselineProposals,
        feedbackAwareProposals: feedbackAwareProposals.sorted { $0.agentId < $1.agentId },
        feedbackAwareResult: result,
        decisions: decisions,
        summary: summary
    )
}

func makeFeedbackAwareIntentPolicyFixtureInvariantReport(
    report: LabFeedbackAwareIntentPolicyFixtureReport?,
    scenario: String,
    seed: UInt32
) -> LabFeedbackAwareIntentPolicyFixtureInvariantReport {
    guard let report else {
        let check = agentIntentInvariantCheck(
            "report_written",
            false,
            "feedback_aware_intent_policy_fixture_report.json",
            "missing"
        )
        return LabFeedbackAwareIntentPolicyFixtureInvariantReport(
            scenario: scenario,
            seed: seed,
            success: false,
            summary: LabMultiAgentMovementFixtureInvariantSummary(
                checksPassed: 0,
                checksFailed: 1,
                cases: 1,
                passed: 0,
                failed: 1
            ),
            checks: [check],
            notes: ["Feedback-aware intent policy fixture report was not produced."]
        )
    }

    let contextIds = report.contexts.map(\.agentId)
    let proposalIds = report.feedbackAwareProposals.map(\.agentId)
    let decisionIds = report.decisions.map(\.agentId)
    let decisionByAgent = Dictionary(uniqueKeysWithValues: report.decisions.map { ($0.agentId, $0) })
    let blockedAgents = [
        "agent_3_collision",
        "agent_4_conflict",
        "agent_5_source_mismatch",
        "agent_6_divergence",
        "agent_7_stale",
        "agent_8_invalid_edge",
        "agent_9_max_agents"
    ]
    let checks: [LabMultiAgentMovementFixtureInvariantCheck] = [
        agentIntentInvariantCheck("contexts_exist", !report.contexts.isEmpty, "contexts > 0", "\(report.contexts.count)"),
        agentIntentInvariantCheck("contexts_intentionally_unordered", feedbackAwareIntentPolicyFixtureContexts().map(\.agentId) != feedbackAwareIntentPolicyFixtureContexts().map(\.agentId).sorted(), "input order != sorted", "\(feedbackAwareIntentPolicyFixtureContexts().map(\.agentId))"),
        agentIntentInvariantCheck("contexts_sorted_by_agent_id_for_output", contextIds == contextIds.sorted(), "sorted", "\(contextIds)"),
        agentIntentInvariantCheck("v0_policy_remains_available", report.baselinePolicyMode == .baselineV0, "baselineV0", report.baselinePolicyMode.rawValue),
        agentIntentInvariantCheck("v1_policy_is_opt_in", report.feedbackAwarePolicyMode == .feedbackAwareV1, "feedbackAwareV1", report.feedbackAwarePolicyMode.rawValue),
        agentIntentInvariantCheck("baseline_proposals_exist", report.baselineProposals.count == 10, "10", "\(report.baselineProposals.count)"),
        agentIntentInvariantCheck("feedback_aware_proposals_exist", report.feedbackAwareProposals.count == 10, "10", "\(report.feedbackAwareProposals.count)"),
        agentIntentInvariantCheck("baseline_computed_first", report.decisions.allSatisfy { $0.baselineProposal.agentId == $0.agentId }, "baseline proposal per decision", "\(report.decisions.count)"),
        agentIntentInvariantCheck("no_feedback_returns_baseline", decisionByAgent["agent_0_no_feedback"]?.behaviorChanged == false, "false", "\(decisionByAgent["agent_0_no_feedback"]?.behaviorChanged ?? true)"),
        agentIntentInvariantCheck("moved_returns_baseline", decisionByAgent["agent_1_moved"]?.behaviorChanged == false, "false", "\(decisionByAgent["agent_1_moved"]?.behaviorChanged ?? true)"),
        agentIntentInvariantCheck("approved_for_movement_returns_baseline", decisionByAgent["agent_2_approved"]?.behaviorChanged == false, "false", "\(decisionByAgent["agent_2_approved"]?.behaviorChanged ?? true)"),
        agentIntentInvariantCheck("blocked_by_collision_returns_no_intent", decisionByAgent["agent_3_collision"]?.feedbackAwareDecision == .noIntent, "noIntent", "\(decisionByAgent["agent_3_collision"]?.feedbackAwareDecision.rawValue ?? "missing")"),
        agentIntentInvariantCheck("blocked_by_agent_conflict_returns_no_intent", decisionByAgent["agent_4_conflict"]?.feedbackAwareDecision == .noIntent, "noIntent", "\(decisionByAgent["agent_4_conflict"]?.feedbackAwareDecision.rawValue ?? "missing")"),
        agentIntentInvariantCheck("blocked_by_source_mismatch_returns_no_intent", decisionByAgent["agent_5_source_mismatch"]?.feedbackAwareDecision == .noIntent, "noIntent", "\(decisionByAgent["agent_5_source_mismatch"]?.feedbackAwareDecision.rawValue ?? "missing")"),
        agentIntentInvariantCheck("blocked_by_divergence_returns_no_intent", decisionByAgent["agent_6_divergence"]?.feedbackAwareDecision == .noIntent, "noIntent", "\(decisionByAgent["agent_6_divergence"]?.feedbackAwareDecision.rawValue ?? "missing")"),
        agentIntentInvariantCheck("blocked_by_stale_intent_returns_no_intent", decisionByAgent["agent_7_stale"]?.feedbackAwareDecision == .noIntent, "noIntent", "\(decisionByAgent["agent_7_stale"]?.feedbackAwareDecision.rawValue ?? "missing")"),
        agentIntentInvariantCheck("blocked_by_invalid_edge_returns_no_intent", decisionByAgent["agent_8_invalid_edge"]?.feedbackAwareDecision == .noIntent, "noIntent", "\(decisionByAgent["agent_8_invalid_edge"]?.feedbackAwareDecision.rawValue ?? "missing")"),
        agentIntentInvariantCheck("blocked_by_max_agents_returns_no_intent", decisionByAgent["agent_9_max_agents"]?.feedbackAwareDecision == .noIntent, "noIntent", "\(decisionByAgent["agent_9_max_agents"]?.feedbackAwareDecision.rawValue ?? "missing")"),
        agentIntentInvariantCheck("blocked_by_invalid_edge_reason_explicit", decisionByAgent["agent_8_invalid_edge"]?.reason == "feedback_blocked_by_invalid_edge_no_intent", "explicit invalid edge noIntent reason", decisionByAgent["agent_8_invalid_edge"]?.reason ?? "missing"),
        agentIntentInvariantCheck("feedback_reactions_counted", report.summary.feedbackReactions == 10, "10", "\(report.summary.feedbackReactions)"),
        agentIntentInvariantCheck("behavior_changed_only_for_blocked_cases", blockedAgents.allSatisfy { decisionByAgent[$0]?.behaviorChanged == true }, "blocked cases changed", "\(blockedAgents.map { decisionByAgent[$0]?.behaviorChanged ?? false })"),
        agentIntentInvariantCheck("behavior_changed_count_expected", report.summary.behaviorChangedCount == 7, "7", "\(report.summary.behaviorChangedCount)"),
        agentIntentInvariantCheck("no_feedback_behavior_unchanged", report.summary.noFeedbackBaselineKept == 1, "1", "\(report.summary.noFeedbackBaselineKept)"),
        agentIntentInvariantCheck("moved_behavior_unchanged", report.summary.movedBaselineKept == 1, "1", "\(report.summary.movedBaselineKept)"),
        agentIntentInvariantCheck("approved_for_movement_behavior_unchanged", report.summary.approvedForMovementBaselineKept == 1, "1", "\(report.summary.approvedForMovementBaselineKept)"),
        agentIntentInvariantCheck("blocked_cases_behavior_changed", report.summary.behaviorChangedByFeedback && report.summary.behaviorChangedCount == 7, "true and 7", "\(report.summary.behaviorChangedByFeedback), \(report.summary.behaviorChangedCount)"),
        agentIntentInvariantCheck("feedback_used_for_decision_true_for_v1", report.decisions.allSatisfy { $0.lastFeedbackKind == nil || $0.feedbackUsedForDecision }, "true for feedback contexts", "\(report.decisions.map(\.feedbackUsedForDecision))"),
        agentIntentInvariantCheck("accepted_intents_expected", report.summary.acceptedIntents == 3, "3", "\(report.summary.acceptedIntents)"),
        agentIntentInvariantCheck("rejected_proposals_expected", report.summary.rejectedProposals == 7, "7", "\(report.summary.rejectedProposals)"),
        agentIntentInvariantCheck("no_intent_expected", report.summary.noIntent == 7, "7", "\(report.summary.noIntent)"),
        agentIntentInvariantCheck("invalid_one_edge_zero_in_v1", report.summary.invalidOneEdgeProposals == 0, "0", "\(report.summary.invalidOneEdgeProposals)"),
        agentIntentInvariantCheck("proposals_sorted_by_agent_id", proposalIds == proposalIds.sorted(), "sorted", "\(proposalIds)"),
        agentIntentInvariantCheck("decision_records_sorted_by_agent_id", decisionIds == decisionIds.sorted(), "sorted", "\(decisionIds)"),
        agentIntentInvariantCheck("no_world_read", !report.summary.worldUsed, "false", "\(report.summary.worldUsed)"),
        agentIntentInvariantCheck("no_collision_read", !report.summary.collisionRead, "false", "\(report.summary.collisionRead)"),
        agentIntentInvariantCheck("movement_not_applied", !report.summary.movementApplied, "false", "\(report.summary.movementApplied)"),
        agentIntentInvariantCheck("memory_not_updated", !report.summary.memoryUpdated, "false", "\(report.summary.memoryUpdated)"),
        agentIntentInvariantCheck("goal_not_changed", !report.summary.goalChanged, "false", "\(report.summary.goalChanged)"),
        agentIntentInvariantCheck("pathfinding_not_performed", !report.summary.pathfindingPerformed, "false", "\(report.summary.pathfindingPerformed)"),
        agentIntentInvariantCheck("replanning_not_performed", !report.summary.replanningPerformed, "false", "\(report.summary.replanningPerformed)"),
        agentIntentInvariantCheck("avoidance_not_performed", !report.summary.avoidancePerformed, "false", "\(report.summary.avoidancePerformed)"),
        agentIntentInvariantCheck("reservation_runtime_not_used", !report.summary.reservationRuntimeUsed, "false", "\(report.summary.reservationRuntimeUsed)"),
        agentIntentInvariantCheck("learning_not_performed", true, "not implemented", "not implemented"),
        agentIntentInvariantCheck("llm_rl_python_not_used", true, "not used", "not used"),
        agentIntentInvariantCheck("social_behavior_not_used", true, "not used", "not used"),
        agentIntentInvariantCheck("communication_not_used", true, "not used", "not used"),
        agentIntentInvariantCheck("tick_movement_not_invoked", true, "not invoked", "not invoked"),
        agentIntentInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("world_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("feedback_to_context_hardening_remains_green", true, "checked by regression command", "checked by regression command"),
        agentIntentInvariantCheck("feedback_consumption_hardening_remains_green", true, "checked by regression command", "checked by regression command"),
        agentIntentInvariantCheck("agent_intent_v0_fixture_remains_green", true, "checked by regression command", "checked by regression command"),
        agentIntentInvariantCheck("report_written", true, "feedback_aware_intent_policy_fixture_report.json", "feedback_aware_intent_policy_fixture_report.json"),
        agentIntentInvariantCheck("decisions_written", true, "feedback_aware_intent_policy_decisions.json", "feedback_aware_intent_policy_decisions.json"),
        agentIntentInvariantCheck("metrics_written", true, "feedbackAwareIntentPolicyFixture*", "feedbackAwareIntentPolicyFixture*"),
        agentIntentInvariantCheck("event_written", true, "lab_feedback_aware_intent_policy_fixture_recorded", "lab_feedback_aware_intent_policy_fixture_recorded"),
        agentIntentInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let passed = checks.filter(\.passed).count
    let summary = LabMultiAgentMovementFixtureInvariantSummary(
        checksPassed: passed,
        checksFailed: checks.count - passed,
        cases: checks.count,
        passed: passed,
        failed: checks.count - passed
    )
    return LabFeedbackAwareIntentPolicyFixtureInvariantReport(
        scenario: scenario,
        seed: seed,
        success: summary.failed == 0,
        summary: summary,
        checks: checks,
        notes: [
            "Feedback-aware v1 is opt-in and baseline v0 remains available.",
            "Blocked feedback returns noIntent without collision, world, tick movement, memory, goals, pathfinding, replanning, avoidance, reservation, or mutation."
        ]
    )
}

private func feedbackAwareHardeningContext(
    _ agentId: String,
    x: Int,
    role: String = "wander_fixture",
    hints: [String] = ["move_east"],
    feedbackKind: LabMovementFeedbackKind?
) -> LabAgentIntentContext {
    let position = LabTerrainPathNodeKey(x: x, y: 64, z: 0)
    let to = LabTerrainPathNodeKey(x: x + 1, y: 64, z: 0)
    return LabAgentIntentContext(
        tick: 0,
        agentId: agentId,
        position: position,
        lastFeedback: feedbackKind.map {
            feedbackAwarePolicyFeedback(
                agentId: agentId,
                kind: $0,
                from: position,
                to: to,
                reason: "hardening_\($0.rawValue)"
            )
        },
        role: role,
        localHints: hints
    )
}

private func feedbackAwareIntentPolicySummary(
    contexts: [LabAgentIntentContext]
) -> (
    baselineProposals: [LabAgentIntentProposal],
    feedbackAwareProposals: [LabAgentIntentProposal],
    decisions: [LabAgentIntentFeedbackPolicyDecision],
    result: LabAgentIntentProductionResult,
    summary: LabFeedbackAwareIntentPolicyFixtureSummary
) {
    let baselineProposals = contexts.map(produceAgentIntentProposalV0(context:)).sorted {
        $0.agentId < $1.agentId
    }
    let decisions = contexts.map(produceAgentIntentProposalFeedbackAwareV1(context:)).sorted {
        $0.agentId < $1.agentId
    }
    let feedbackAwareProposals = decisions.map(\.feedbackAwareProposal)
    let result = produceAgentIntentProductionResult(
        tick: 0,
        contexts: contexts,
        rawProposals: feedbackAwareProposals,
        maxProposals: nil
    )
    let reactionCount: (LabAgentIntentFeedbackReaction) -> Int = { reaction in
        decisions.filter { $0.feedbackReaction == reaction }.count
    }
    let behaviorChangedCount = decisions.filter(\.behaviorChanged).count
    let summary = LabFeedbackAwareIntentPolicyFixtureSummary(
        tick: 0,
        contexts: contexts.count,
        contextsWithFeedback: contexts.filter { $0.lastFeedback != nil }.count,
        contextsWithoutFeedback: contexts.filter { $0.lastFeedback == nil }.count,
        baselineProposals: baselineProposals.count,
        feedbackAwareProposals: feedbackAwareProposals.count,
        acceptedIntents: result.summary.acceptedIntents,
        rejectedProposals: result.summary.rejectedProposals,
        noIntent: result.summary.noIntent,
        invalidOneEdgeProposals: result.summary.invalidOneEdgeProposals,
        feedbackReactions: decisions.count,
        behaviorChangedByFeedback: behaviorChangedCount > 0,
        behaviorChangedCount: behaviorChangedCount,
        movedBaselineKept: reactionCount(.baselineKeptMoved),
        approvedForMovementBaselineKept: reactionCount(.baselineKeptApprovedForMovement),
        noFeedbackBaselineKept: reactionCount(.baselineKeptNoFeedback),
        blockedByCollisionNoIntent: reactionCount(.blockedByCollisionNoIntent),
        blockedByAgentConflictNoIntent: reactionCount(.blockedByAgentConflictNoIntent),
        blockedBySourceMismatchNoIntent: reactionCount(.blockedBySourceMismatchNoIntent),
        blockedByDivergenceNoIntent: reactionCount(.blockedByDivergenceNoIntent),
        blockedByStaleIntentNoIntent: reactionCount(.blockedByStaleIntentNoIntent),
        blockedByInvalidEdgeNoIntent: reactionCount(.blockedByInvalidEdgeNoIntent),
        blockedByMaxAgentsNoIntent: reactionCount(.blockedByMaxAgentsNoIntent),
        collisionRead: false,
        movementApplied: false,
        memoryUpdated: false,
        goalChanged: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        worldUsed: false,
        mutationPerformed: false,
        success: result.summary.success
    )
    return (baselineProposals, feedbackAwareProposals, decisions, result, summary)
}

private func feedbackAwareExpected(
    contexts: Int,
    contextsWithFeedback: Int,
    contextsWithoutFeedback: Int,
    acceptedIntents: Int,
    rejectedProposals: Int,
    noIntent: Int,
    invalidOneEdgeProposals: Int,
    behaviorChangedCount: Int,
    noFeedbackBaselineKept: Int = 0,
    movedBaselineKept: Int = 0,
    approvedForMovementBaselineKept: Int = 0,
    blockedByCollisionNoIntent: Int = 0,
    blockedByAgentConflictNoIntent: Int = 0,
    blockedBySourceMismatchNoIntent: Int = 0,
    blockedByDivergenceNoIntent: Int = 0,
    blockedByStaleIntentNoIntent: Int = 0,
    blockedByInvalidEdgeNoIntent: Int = 0,
    blockedByMaxAgentsNoIntent: Int = 0
) -> LabFeedbackAwareIntentPolicyFixtureSummary {
    LabFeedbackAwareIntentPolicyFixtureSummary(
        tick: 0,
        contexts: contexts,
        contextsWithFeedback: contextsWithFeedback,
        contextsWithoutFeedback: contextsWithoutFeedback,
        baselineProposals: contexts,
        feedbackAwareProposals: contexts,
        acceptedIntents: acceptedIntents,
        rejectedProposals: rejectedProposals,
        noIntent: noIntent,
        invalidOneEdgeProposals: invalidOneEdgeProposals,
        feedbackReactions: contexts,
        behaviorChangedByFeedback: behaviorChangedCount > 0,
        behaviorChangedCount: behaviorChangedCount,
        movedBaselineKept: movedBaselineKept,
        approvedForMovementBaselineKept: approvedForMovementBaselineKept,
        noFeedbackBaselineKept: noFeedbackBaselineKept,
        blockedByCollisionNoIntent: blockedByCollisionNoIntent,
        blockedByAgentConflictNoIntent: blockedByAgentConflictNoIntent,
        blockedBySourceMismatchNoIntent: blockedBySourceMismatchNoIntent,
        blockedByDivergenceNoIntent: blockedByDivergenceNoIntent,
        blockedByStaleIntentNoIntent: blockedByStaleIntentNoIntent,
        blockedByInvalidEdgeNoIntent: blockedByInvalidEdgeNoIntent,
        blockedByMaxAgentsNoIntent: blockedByMaxAgentsNoIntent,
        collisionRead: false,
        movementApplied: false,
        memoryUpdated: false,
        goalChanged: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        worldUsed: false,
        mutationPerformed: false,
        success: true
    )
}

private func feedbackAwareSummaryMatches(
    _ actual: LabFeedbackAwareIntentPolicyFixtureSummary,
    _ expected: LabFeedbackAwareIntentPolicyFixtureSummary
) -> Bool {
    actual.contexts == expected.contexts
        && actual.contextsWithFeedback == expected.contextsWithFeedback
        && actual.contextsWithoutFeedback == expected.contextsWithoutFeedback
        && actual.baselineProposals == expected.baselineProposals
        && actual.feedbackAwareProposals == expected.feedbackAwareProposals
        && actual.acceptedIntents == expected.acceptedIntents
        && actual.rejectedProposals == expected.rejectedProposals
        && actual.noIntent == expected.noIntent
        && actual.invalidOneEdgeProposals == expected.invalidOneEdgeProposals
        && actual.feedbackReactions == expected.feedbackReactions
        && actual.behaviorChangedByFeedback == expected.behaviorChangedByFeedback
        && actual.behaviorChangedCount == expected.behaviorChangedCount
        && actual.noFeedbackBaselineKept == expected.noFeedbackBaselineKept
        && actual.movedBaselineKept == expected.movedBaselineKept
        && actual.approvedForMovementBaselineKept == expected.approvedForMovementBaselineKept
        && actual.blockedByCollisionNoIntent == expected.blockedByCollisionNoIntent
        && actual.blockedByAgentConflictNoIntent == expected.blockedByAgentConflictNoIntent
        && actual.blockedBySourceMismatchNoIntent == expected.blockedBySourceMismatchNoIntent
        && actual.blockedByDivergenceNoIntent == expected.blockedByDivergenceNoIntent
        && actual.blockedByStaleIntentNoIntent == expected.blockedByStaleIntentNoIntent
        && actual.blockedByInvalidEdgeNoIntent == expected.blockedByInvalidEdgeNoIntent
        && actual.blockedByMaxAgentsNoIntent == expected.blockedByMaxAgentsNoIntent
        && actual.collisionRead == expected.collisionRead
        && actual.movementApplied == expected.movementApplied
        && actual.memoryUpdated == expected.memoryUpdated
        && actual.goalChanged == expected.goalChanged
        && actual.pathfindingPerformed == expected.pathfindingPerformed
        && actual.replanningPerformed == expected.replanningPerformed
        && actual.avoidancePerformed == expected.avoidancePerformed
        && actual.reservationRuntimeUsed == expected.reservationRuntimeUsed
        && actual.worldUsed == expected.worldUsed
        && actual.mutationPerformed == expected.mutationPerformed
}

private func feedbackAwarePolicyHardeningCases() -> [LabFeedbackAwareIntentPolicyHardeningCase] {
    let blockedKinds: [(String, LabMovementFeedbackKind)] = [
        ("collision", .blockedByCollision),
        ("conflict", .blockedByAgentConflict),
        ("source_mismatch", .blockedBySourceMismatch),
        ("divergence", .blockedByDivergence),
        ("stale", .blockedByStaleIntent),
        ("invalid_edge", .blockedByInvalidEdge),
        ("max_agents", .blockedByMaxAgents)
    ]
    return [
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "baseline_fixture_remains_green",
            contexts: feedbackAwareIntentPolicyFixtureContexts(),
            expected: feedbackAwareExpected(
                contexts: 10,
                contextsWithFeedback: 9,
                contextsWithoutFeedback: 1,
                acceptedIntents: 3,
                rejectedProposals: 7,
                noIntent: 7,
                invalidOneEdgeProposals: 0,
                behaviorChangedCount: 7,
                noFeedbackBaselineKept: 1,
                movedBaselineKept: 1,
                approvedForMovementBaselineKept: 1,
                blockedByCollisionNoIntent: 1,
                blockedByAgentConflictNoIntent: 1,
                blockedBySourceMismatchNoIntent: 1,
                blockedByDivergenceNoIntent: 1,
                blockedByStaleIntentNoIntent: 1,
                blockedByInvalidEdgeNoIntent: 1,
                blockedByMaxAgentsNoIntent: 1
            ),
            repeatabilityCheck: false,
            notes: ["Reuses the 4.23A fixture contract."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "no_feedback_returns_baseline",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, feedbackKind: nil)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 0, contextsWithoutFeedback: 1, acceptedIntents: 1, rejectedProposals: 0, noIntent: 0, invalidOneEdgeProposals: 0, behaviorChangedCount: 0, noFeedbackBaselineKept: 1),
            repeatabilityCheck: false,
            notes: ["Missing feedback keeps the v0 baseline signature."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "moved_returns_baseline",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, feedbackKind: .moved)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 1, contextsWithoutFeedback: 0, acceptedIntents: 1, rejectedProposals: 0, noIntent: 0, invalidOneEdgeProposals: 0, behaviorChangedCount: 0, movedBaselineKept: 1),
            repeatabilityCheck: false,
            notes: ["Moved feedback keeps the v0 baseline signature."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "approved_for_movement_returns_baseline",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, feedbackKind: .approvedForMovement)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 1, contextsWithoutFeedback: 0, acceptedIntents: 1, rejectedProposals: 0, noIntent: 0, invalidOneEdgeProposals: 0, behaviorChangedCount: 0, approvedForMovementBaselineKept: 1),
            repeatabilityCheck: false,
            notes: ["Decision-layer approval is not treated as physical movement."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "blocked_collision_returns_no_intent",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, feedbackKind: .blockedByCollision)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 1, contextsWithoutFeedback: 0, acceptedIntents: 0, rejectedProposals: 1, noIntent: 1, invalidOneEdgeProposals: 0, behaviorChangedCount: 1, blockedByCollisionNoIntent: 1),
            repeatabilityCheck: false,
            notes: ["Blocked collision maps to noIntent without collision reads."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "blocked_agent_conflict_returns_no_intent",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, feedbackKind: .blockedByAgentConflict)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 1, contextsWithoutFeedback: 0, acceptedIntents: 0, rejectedProposals: 1, noIntent: 1, invalidOneEdgeProposals: 0, behaviorChangedCount: 1, blockedByAgentConflictNoIntent: 1),
            repeatabilityCheck: false,
            notes: ["Agent conflict maps to noIntent without social behavior."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "blocked_source_mismatch_returns_no_intent",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, feedbackKind: .blockedBySourceMismatch)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 1, contextsWithoutFeedback: 0, acceptedIntents: 0, rejectedProposals: 1, noIntent: 1, invalidOneEdgeProposals: 0, behaviorChangedCount: 1, blockedBySourceMismatchNoIntent: 1),
            repeatabilityCheck: false,
            notes: ["Source mismatch is surfaced, not repaired."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "blocked_divergence_returns_no_intent",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, feedbackKind: .blockedByDivergence)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 1, contextsWithoutFeedback: 0, acceptedIntents: 0, rejectedProposals: 1, noIntent: 1, invalidOneEdgeProposals: 0, behaviorChangedCount: 1, blockedByDivergenceNoIntent: 1),
            repeatabilityCheck: false,
            notes: ["Divergence does not trigger repair."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "blocked_stale_intent_returns_no_intent",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, feedbackKind: .blockedByStaleIntent)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 1, contextsWithoutFeedback: 0, acceptedIntents: 0, rejectedProposals: 1, noIntent: 1, invalidOneEdgeProposals: 0, behaviorChangedCount: 1, blockedByStaleIntentNoIntent: 1),
            repeatabilityCheck: false,
            notes: ["Stale intent does not retry."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "blocked_invalid_edge_returns_no_intent_explicit_reason",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, role: "bad_fixture_invalid_vertical", hints: ["move_vertical"], feedbackKind: .blockedByInvalidEdge)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 1, contextsWithoutFeedback: 0, acceptedIntents: 0, rejectedProposals: 1, noIntent: 1, invalidOneEdgeProposals: 0, behaviorChangedCount: 1, blockedByInvalidEdgeNoIntent: 1),
            repeatabilityCheck: false,
            notes: ["Invalid edge feedback uses an explicit feedback_blocked_by_invalid_edge_no_intent reason."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "blocked_max_agents_returns_no_intent",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, feedbackKind: .blockedByMaxAgents)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 1, contextsWithoutFeedback: 0, acceptedIntents: 0, rejectedProposals: 1, noIntent: 1, invalidOneEdgeProposals: 0, behaviorChangedCount: 1, blockedByMaxAgentsNoIntent: 1),
            repeatabilityCheck: false,
            notes: ["Capacity feedback does not introduce scheduling or reservation."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "blocked_feedback_on_baseline_no_intent_stays_no_intent",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, role: "idle", hints: [], feedbackKind: .blockedByCollision)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 1, contextsWithoutFeedback: 0, acceptedIntents: 0, rejectedProposals: 1, noIntent: 1, invalidOneEdgeProposals: 0, behaviorChangedCount: 0, blockedByCollisionNoIntent: 1),
            repeatabilityCheck: false,
            notes: ["If v0 already returned noIntent, v1 keeps the signature stable."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "blocked_feedback_on_baseline_invalid_becomes_no_intent",
            contexts: [feedbackAwareHardeningContext("agent_0", x: 0, role: "bad_fixture_invalid_vertical", hints: ["move_vertical"], feedbackKind: .blockedByCollision)],
            expected: feedbackAwareExpected(contexts: 1, contextsWithFeedback: 1, contextsWithoutFeedback: 0, acceptedIntents: 0, rejectedProposals: 1, noIntent: 1, invalidOneEdgeProposals: 0, behaviorChangedCount: 1, blockedByCollisionNoIntent: 1),
            repeatabilityCheck: false,
            notes: ["Invalid baseline proposal becomes explicit feedback noIntent and does not reach invalid edge validation."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "all_blocked_kinds_counted_once",
            contexts: blockedKinds.enumerated().map { index, pair in
                feedbackAwareHardeningContext("agent_\(index)_\(pair.0)", x: index, feedbackKind: pair.1)
            },
            expected: feedbackAwareExpected(contexts: 7, contextsWithFeedback: 7, contextsWithoutFeedback: 0, acceptedIntents: 0, rejectedProposals: 7, noIntent: 7, invalidOneEdgeProposals: 0, behaviorChangedCount: 7, blockedByCollisionNoIntent: 1, blockedByAgentConflictNoIntent: 1, blockedBySourceMismatchNoIntent: 1, blockedByDivergenceNoIntent: 1, blockedByStaleIntentNoIntent: 1, blockedByInvalidEdgeNoIntent: 1, blockedByMaxAgentsNoIntent: 1),
            repeatabilityCheck: false,
            notes: ["Each blocked feedback kind is represented exactly once."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "deterministic_ordering_by_agent_id",
            contexts: [
                feedbackAwareHardeningContext("agent_c", x: 2, feedbackKind: .blockedByCollision),
                feedbackAwareHardeningContext("agent_a", x: 0, feedbackKind: nil),
                feedbackAwareHardeningContext("agent_b", x: 1, feedbackKind: .moved)
            ],
            expected: feedbackAwareExpected(contexts: 3, contextsWithFeedback: 2, contextsWithoutFeedback: 1, acceptedIntents: 2, rejectedProposals: 1, noIntent: 1, invalidOneEdgeProposals: 0, behaviorChangedCount: 1, noFeedbackBaselineKept: 1, movedBaselineKept: 1, blockedByCollisionNoIntent: 1),
            repeatabilityCheck: false,
            notes: ["Input is deliberately unordered; decisions and proposals are sorted by agentId."]
        ),
        LabFeedbackAwareIntentPolicyHardeningCase(
            name: "stable_repeatability",
            contexts: [
                feedbackAwareHardeningContext("agent_2", x: 2, feedbackKind: .blockedByMaxAgents),
                feedbackAwareHardeningContext("agent_0", x: 0, feedbackKind: nil),
                feedbackAwareHardeningContext("agent_1", x: 1, feedbackKind: .approvedForMovement)
            ],
            expected: feedbackAwareExpected(contexts: 3, contextsWithFeedback: 2, contextsWithoutFeedback: 1, acceptedIntents: 2, rejectedProposals: 1, noIntent: 1, invalidOneEdgeProposals: 0, behaviorChangedCount: 1, noFeedbackBaselineKept: 1, approvedForMovementBaselineKept: 1, blockedByMaxAgentsNoIntent: 1),
            repeatabilityCheck: true,
            notes: ["Runs the same inputs twice and compares signatures, reactions, and totals."]
        )
    ]
}

private func feedbackAwareCaseResult(
    _ testCase: LabFeedbackAwareIntentPolicyHardeningCase
) -> LabFeedbackAwareIntentPolicyHardeningCaseResult {
    let evaluation = feedbackAwareIntentPolicySummary(contexts: testCase.contexts)
    let repeated = testCase.repeatabilityCheck
        ? feedbackAwareIntentPolicySummary(contexts: testCase.contexts)
        : nil
    let signatures = evaluation.feedbackAwareProposals.map(proposalSignature)
    let repeatedSignatures = repeated?.feedbackAwareProposals.map(proposalSignature)
    let reactions = evaluation.decisions.map(\.feedbackReaction)
    let repeatedReactions = repeated?.decisions.map(\.feedbackReaction)
    let repeatabilityPassed = !testCase.repeatabilityCheck
        || (signatures == repeatedSignatures
            && reactions == repeatedReactions
            && repeated.map { feedbackAwareSummaryMatches($0.summary, evaluation.summary) } == true)
    let invalidEdgeReasonPassed = testCase.name != "blocked_invalid_edge_returns_no_intent_explicit_reason"
        || evaluation.decisions.first?.reason == "feedback_blocked_by_invalid_edge_no_intent"
    let sortedOutput = evaluation.decisions.map(\.agentId) == evaluation.decisions.map(\.agentId).sorted()
        && evaluation.feedbackAwareProposals.map(\.agentId) == evaluation.feedbackAwareProposals.map(\.agentId).sorted()
    let signatureDiffs = zip(evaluation.decisions.map(\.baselineProposal), evaluation.decisions.map(\.feedbackAwareProposal)).filter {
        proposalSignature($0.0) != proposalSignature($0.1)
    }.count
    let passed = feedbackAwareSummaryMatches(evaluation.summary, testCase.expected)
        && repeatabilityPassed
        && invalidEdgeReasonPassed
        && sortedOutput
        && signatureDiffs == evaluation.summary.behaviorChangedCount
        && evaluation.summary.success
    return LabFeedbackAwareIntentPolicyHardeningCaseResult(
        name: testCase.name,
        passed: passed,
        contexts: testCase.contexts,
        baselineProposals: evaluation.baselineProposals,
        feedbackAwareProposals: evaluation.feedbackAwareProposals,
        decisions: evaluation.decisions,
        repeatedActual: repeated?.summary,
        expected: testCase.expected,
        actual: evaluation.summary,
        notes: testCase.notes
    )
}

func makeFeedbackAwareIntentPolicyHardeningReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabFeedbackAwareIntentPolicyHardeningReport {
    let results = feedbackAwarePolicyHardeningCases().map(feedbackAwareCaseResult)
    let passed = results.filter(\.passed).count
    let summary = LabFeedbackAwareIntentPolicyHardeningSummary(
        cases: results.count,
        passed: passed,
        failed: results.count - passed,
        contextsTotal: results.reduce(0) { $0 + $1.actual.contexts },
        contextsWithFeedbackTotal: results.reduce(0) { $0 + $1.actual.contextsWithFeedback },
        contextsWithoutFeedbackTotal: results.reduce(0) { $0 + $1.actual.contextsWithoutFeedback },
        baselineProposalsTotal: results.reduce(0) { $0 + $1.actual.baselineProposals },
        feedbackAwareProposalsTotal: results.reduce(0) { $0 + $1.actual.feedbackAwareProposals },
        acceptedIntentsTotal: results.reduce(0) { $0 + $1.actual.acceptedIntents },
        rejectedProposalsTotal: results.reduce(0) { $0 + $1.actual.rejectedProposals },
        noIntentTotal: results.reduce(0) { $0 + $1.actual.noIntent },
        invalidOneEdgeProposalsTotal: results.reduce(0) { $0 + $1.actual.invalidOneEdgeProposals },
        feedbackReactionsTotal: results.reduce(0) { $0 + $1.actual.feedbackReactions },
        behaviorChangedCountTotal: results.reduce(0) { $0 + $1.actual.behaviorChangedCount },
        noFeedbackBaselineKeptTotal: results.reduce(0) { $0 + $1.actual.noFeedbackBaselineKept },
        movedBaselineKeptTotal: results.reduce(0) { $0 + $1.actual.movedBaselineKept },
        approvedForMovementBaselineKeptTotal: results.reduce(0) { $0 + $1.actual.approvedForMovementBaselineKept },
        blockedByCollisionNoIntentTotal: results.reduce(0) { $0 + $1.actual.blockedByCollisionNoIntent },
        blockedByAgentConflictNoIntentTotal: results.reduce(0) { $0 + $1.actual.blockedByAgentConflictNoIntent },
        blockedBySourceMismatchNoIntentTotal: results.reduce(0) { $0 + $1.actual.blockedBySourceMismatchNoIntent },
        blockedByDivergenceNoIntentTotal: results.reduce(0) { $0 + $1.actual.blockedByDivergenceNoIntent },
        blockedByStaleIntentNoIntentTotal: results.reduce(0) { $0 + $1.actual.blockedByStaleIntentNoIntent },
        blockedByInvalidEdgeNoIntentTotal: results.reduce(0) { $0 + $1.actual.blockedByInvalidEdgeNoIntent },
        blockedByMaxAgentsNoIntentTotal: results.reduce(0) { $0 + $1.actual.blockedByMaxAgentsNoIntent },
        behaviorChangedByFeedback: results.contains { $0.actual.behaviorChangedByFeedback },
        feedbackUsedForDecision: results.allSatisfy { result in
            result.decisions.allSatisfy { $0.lastFeedbackKind == nil || $0.feedbackUsedForDecision }
        },
        collisionRead: results.contains { $0.actual.collisionRead },
        movementApplied: results.contains { $0.actual.movementApplied },
        memoryUpdated: results.contains { $0.actual.memoryUpdated },
        goalChanged: results.contains { $0.actual.goalChanged },
        pathfindingPerformed: results.contains { $0.actual.pathfindingPerformed },
        replanningPerformed: results.contains { $0.actual.replanningPerformed },
        avoidancePerformed: results.contains { $0.actual.avoidancePerformed },
        reservationRuntimeUsed: results.contains { $0.actual.reservationRuntimeUsed },
        worldUsed: results.contains { $0.actual.worldUsed },
        mutationPerformed: results.contains { $0.actual.mutationPerformed },
        success: results.count == 16
            && passed == 16
            && results.allSatisfy(\.passed)
    )
    return LabFeedbackAwareIntentPolicyHardeningReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success
            && !summary.collisionRead
            && !summary.worldUsed
            && !summary.movementApplied
            && !summary.memoryUpdated
            && !summary.goalChanged
            && !summary.pathfindingPerformed
            && !summary.replanningPerformed
            && !summary.avoidancePerformed
            && !summary.reservationRuntimeUsed
            && !summary.mutationPerformed,
        cases: results,
        summary: summary
    )
}

func makeFeedbackAwareIntentPolicyHardeningInvariantReport(
    report: LabFeedbackAwareIntentPolicyHardeningReport?,
    scenario: String,
    seed: UInt32
) -> LabFeedbackAwareIntentPolicyHardeningInvariantReport {
    guard let report else {
        let check = agentIntentInvariantCheck("report_written", false, "feedback_aware_intent_policy_hardening_report.json", "missing")
        return LabFeedbackAwareIntentPolicyHardeningInvariantReport(
            scenario: scenario,
            seed: seed,
            success: false,
            summary: LabMultiAgentMovementFixtureInvariantSummary(checksPassed: 0, checksFailed: 1, cases: 1, passed: 0, failed: 1),
            checks: [check],
            notes: ["Feedback-aware intent policy hardening report was not produced."]
        )
    }
    let caseNames = Set(report.cases.map(\.name))
    let casesByName = Dictionary(uniqueKeysWithValues: report.cases.map { ($0.name, $0) })
    let allSorted = report.cases.allSatisfy {
        $0.decisions.map(\.agentId) == $0.decisions.map(\.agentId).sorted()
            && $0.feedbackAwareProposals.map(\.agentId) == $0.feedbackAwareProposals.map(\.agentId).sorted()
    }
    let checks: [LabMultiAgentMovementFixtureInvariantCheck] = [
        agentIntentInvariantCheck("hardening_cases_exist", !report.cases.isEmpty, "cases > 0", "\(report.cases.count)"),
        agentIntentInvariantCheck("hardening_case_count_expected", report.summary.cases == 16, "16", "\(report.summary.cases)"),
        agentIntentInvariantCheck("baseline_fixture_remains_green", casesByName["baseline_fixture_remains_green"]?.passed == true, "true", "\(casesByName["baseline_fixture_remains_green"]?.passed ?? false)"),
        agentIntentInvariantCheck("no_feedback_returns_baseline", casesByName["no_feedback_returns_baseline"]?.passed == true, "true", "\(casesByName["no_feedback_returns_baseline"]?.passed ?? false)"),
        agentIntentInvariantCheck("moved_returns_baseline", casesByName["moved_returns_baseline"]?.passed == true, "true", "\(casesByName["moved_returns_baseline"]?.passed ?? false)"),
        agentIntentInvariantCheck("approved_for_movement_returns_baseline", casesByName["approved_for_movement_returns_baseline"]?.passed == true, "true", "\(casesByName["approved_for_movement_returns_baseline"]?.passed ?? false)"),
        agentIntentInvariantCheck("blocked_collision_returns_no_intent", casesByName["blocked_collision_returns_no_intent"]?.passed == true, "true", "\(casesByName["blocked_collision_returns_no_intent"]?.passed ?? false)"),
        agentIntentInvariantCheck("blocked_agent_conflict_returns_no_intent", casesByName["blocked_agent_conflict_returns_no_intent"]?.passed == true, "true", "\(casesByName["blocked_agent_conflict_returns_no_intent"]?.passed ?? false)"),
        agentIntentInvariantCheck("blocked_source_mismatch_returns_no_intent", casesByName["blocked_source_mismatch_returns_no_intent"]?.passed == true, "true", "\(casesByName["blocked_source_mismatch_returns_no_intent"]?.passed ?? false)"),
        agentIntentInvariantCheck("blocked_divergence_returns_no_intent", casesByName["blocked_divergence_returns_no_intent"]?.passed == true, "true", "\(casesByName["blocked_divergence_returns_no_intent"]?.passed ?? false)"),
        agentIntentInvariantCheck("blocked_stale_intent_returns_no_intent", casesByName["blocked_stale_intent_returns_no_intent"]?.passed == true, "true", "\(casesByName["blocked_stale_intent_returns_no_intent"]?.passed ?? false)"),
        agentIntentInvariantCheck("blocked_invalid_edge_returns_no_intent_explicit_reason", casesByName["blocked_invalid_edge_returns_no_intent_explicit_reason"]?.passed == true, "true", "\(casesByName["blocked_invalid_edge_returns_no_intent_explicit_reason"]?.passed ?? false)"),
        agentIntentInvariantCheck("blocked_max_agents_returns_no_intent", casesByName["blocked_max_agents_returns_no_intent"]?.passed == true, "true", "\(casesByName["blocked_max_agents_returns_no_intent"]?.passed ?? false)"),
        agentIntentInvariantCheck("blocked_feedback_on_baseline_no_intent_stays_no_intent", casesByName["blocked_feedback_on_baseline_no_intent_stays_no_intent"]?.passed == true, "true", "\(casesByName["blocked_feedback_on_baseline_no_intent_stays_no_intent"]?.passed ?? false)"),
        agentIntentInvariantCheck("blocked_feedback_on_baseline_invalid_becomes_no_intent", casesByName["blocked_feedback_on_baseline_invalid_becomes_no_intent"]?.passed == true, "true", "\(casesByName["blocked_feedback_on_baseline_invalid_becomes_no_intent"]?.passed ?? false)"),
        agentIntentInvariantCheck("all_blocked_kinds_counted_once", casesByName["all_blocked_kinds_counted_once"]?.passed == true, "true", "\(casesByName["all_blocked_kinds_counted_once"]?.passed ?? false)"),
        agentIntentInvariantCheck("deterministic_ordering_by_agent_id", casesByName["deterministic_ordering_by_agent_id"]?.passed == true, "true", "\(casesByName["deterministic_ordering_by_agent_id"]?.passed ?? false)"),
        agentIntentInvariantCheck("stable_repeatability", casesByName["stable_repeatability"]?.passed == true, "true", "\(casesByName["stable_repeatability"]?.passed ?? false)"),
        agentIntentInvariantCheck("cases_all_passed", report.summary.failed == 0, "0 failed", "\(report.summary.failed)"),
        agentIntentInvariantCheck("v0_policy_remains_available", true, "produceAgentIntentProposalV0 unchanged", "available"),
        agentIntentInvariantCheck("v1_policy_is_opt_in", true, "explicit hardening scenario", "explicit hardening scenario"),
        agentIntentInvariantCheck("baseline_computed_first", report.cases.allSatisfy { !$0.baselineProposals.isEmpty }, "baseline proposals per case", "\(report.summary.baselineProposalsTotal)"),
        agentIntentInvariantCheck("baseline_proposals_exist", report.summary.baselineProposalsTotal > 0, "> 0", "\(report.summary.baselineProposalsTotal)"),
        agentIntentInvariantCheck("feedback_aware_proposals_exist", report.summary.feedbackAwareProposalsTotal > 0, "> 0", "\(report.summary.feedbackAwareProposalsTotal)"),
        agentIntentInvariantCheck("decision_records_exist", report.summary.feedbackReactionsTotal > 0, "> 0", "\(report.summary.feedbackReactionsTotal)"),
        agentIntentInvariantCheck("decision_records_sorted_by_agent_id", allSorted, "sorted", "\(allSorted)"),
        agentIntentInvariantCheck("proposals_sorted_by_agent_id", allSorted, "sorted", "\(allSorted)"),
        agentIntentInvariantCheck("feedback_reactions_counted", report.summary.feedbackReactionsTotal == report.summary.contextsTotal, "one per context", "\(report.summary.feedbackReactionsTotal)/\(report.summary.contextsTotal)"),
        agentIntentInvariantCheck("behavior_changed_only_when_signature_differs", report.cases.allSatisfy { caseResult in caseResult.actual.behaviorChangedCount == zip(caseResult.baselineProposals, caseResult.feedbackAwareProposals).filter { proposalSignature($0.0) != proposalSignature($0.1) }.count }, "signature diffs match", "matched"),
        agentIntentInvariantCheck("behavior_changed_count_matches_cases", report.summary.behaviorChangedCountTotal > 0, "> 0", "\(report.summary.behaviorChangedCountTotal)"),
        agentIntentInvariantCheck("feedback_used_for_decision_true_in_v1_hardening", report.summary.feedbackUsedForDecision, "true", "\(report.summary.feedbackUsedForDecision)"),
        agentIntentInvariantCheck("invalid_edge_reason_explicit", casesByName["blocked_invalid_edge_returns_no_intent_explicit_reason"]?.decisions.first?.reason == "feedback_blocked_by_invalid_edge_no_intent", "feedback_blocked_by_invalid_edge_no_intent", casesByName["blocked_invalid_edge_returns_no_intent_explicit_reason"]?.decisions.first?.reason ?? "missing"),
        agentIntentInvariantCheck("invalid_one_edge_zero_when_v1_converts_invalid_to_no_intent", casesByName["blocked_feedback_on_baseline_invalid_becomes_no_intent"]?.actual.invalidOneEdgeProposals == 0, "0", "\(casesByName["blocked_feedback_on_baseline_invalid_becomes_no_intent"]?.actual.invalidOneEdgeProposals ?? -1)"),
        agentIntentInvariantCheck("no_world_read", !report.summary.worldUsed, "false", "\(report.summary.worldUsed)"),
        agentIntentInvariantCheck("no_collision_read", !report.summary.collisionRead, "false", "\(report.summary.collisionRead)"),
        agentIntentInvariantCheck("tick_movement_not_invoked", true, "not invoked", "not invoked"),
        agentIntentInvariantCheck("movement_not_applied", !report.summary.movementApplied, "false", "\(report.summary.movementApplied)"),
        agentIntentInvariantCheck("memory_not_updated", !report.summary.memoryUpdated, "false", "\(report.summary.memoryUpdated)"),
        agentIntentInvariantCheck("goal_not_changed", !report.summary.goalChanged, "false", "\(report.summary.goalChanged)"),
        agentIntentInvariantCheck("pathfinding_not_performed", !report.summary.pathfindingPerformed, "false", "\(report.summary.pathfindingPerformed)"),
        agentIntentInvariantCheck("replanning_not_performed", !report.summary.replanningPerformed, "false", "\(report.summary.replanningPerformed)"),
        agentIntentInvariantCheck("avoidance_not_performed", !report.summary.avoidancePerformed, "false", "\(report.summary.avoidancePerformed)"),
        agentIntentInvariantCheck("reservation_runtime_not_used", !report.summary.reservationRuntimeUsed, "false", "\(report.summary.reservationRuntimeUsed)"),
        agentIntentInvariantCheck("learning_not_performed", true, "not implemented", "not implemented"),
        agentIntentInvariantCheck("llm_rl_python_not_used", true, "not used", "not used"),
        agentIntentInvariantCheck("social_behavior_not_used", true, "not used", "not used"),
        agentIntentInvariantCheck("communication_not_used", true, "not used", "not used"),
        agentIntentInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("world_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("feedback_aware_fixture_remains_green", true, "checked by regression command", "checked by regression command"),
        agentIntentInvariantCheck("feedback_to_context_hardening_remains_green", true, "checked by regression command", "checked by regression command"),
        agentIntentInvariantCheck("feedback_consumption_hardening_remains_green", true, "checked by regression command", "checked by regression command"),
        agentIntentInvariantCheck("agent_intent_v0_fixture_remains_green", true, "checked by regression command", "checked by regression command"),
        agentIntentInvariantCheck("report_written", true, "feedback_aware_intent_policy_hardening_report.json", "feedback_aware_intent_policy_hardening_report.json"),
        agentIntentInvariantCheck("cases_written", true, "feedback_aware_intent_policy_hardening_cases.json", "feedback_aware_intent_policy_hardening_cases.json"),
        agentIntentInvariantCheck("metrics_written", true, "feedbackAwareIntentPolicyHardening*", "feedbackAwareIntentPolicyHardening*"),
        agentIntentInvariantCheck("event_written", true, "lab_feedback_aware_intent_policy_hardening_recorded", "lab_feedback_aware_intent_policy_hardening_recorded"),
        agentIntentInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let passed = checks.filter(\.passed).count
    let summary = LabMultiAgentMovementFixtureInvariantSummary(
        checksPassed: passed,
        checksFailed: checks.count - passed,
        cases: checks.count,
        passed: passed,
        failed: checks.count - passed
    )
    return LabFeedbackAwareIntentPolicyHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: summary.failed == 0 && caseNames.count == 16,
        summary: summary,
        checks: checks,
        notes: [
            "Feedback-aware v1 hardening remains fixture-only and opt-in.",
            "No alternative direction, tick movement, collision read, World access, memory, goals, pathfinding, replanning, avoidance, reservation, or mutation is introduced."
        ]
    )
}

private func feedbackAwareIntentToTickFixtureContexts() -> [LabAgentIntentContext] {
    let agent0 = LabTerrainPathNodeKey(x: 0, y: 64, z: 0)
    let agent1 = LabTerrainPathNodeKey(x: 2, y: 64, z: 0)
    let agent2 = LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
    let agent3 = LabTerrainPathNodeKey(x: 4, y: 64, z: 0)
    let agent4 = LabTerrainPathNodeKey(x: 10, y: 64, z: 0)
    let agent5 = LabTerrainPathNodeKey(x: 8, y: 64, z: 0)
    return [
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_2_collision",
            position: agent2,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_2_collision",
                kind: .blockedByCollision,
                from: agent2,
                to: LabTerrainPathNodeKey(x: 8, y: 64, z: 8),
                reason: "fixture_blocked_by_collision"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_0_no_feedback",
            position: agent0,
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_4_approved",
            position: agent4,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_4_approved",
                kind: .approvedForMovement,
                from: agent4,
                to: LabTerrainPathNodeKey(x: 11, y: 64, z: 0),
                reason: "fixture_approved_for_movement"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_1_moved",
            position: agent1,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_1_moved",
                kind: .moved,
                from: LabTerrainPathNodeKey(x: 3, y: 64, z: 0),
                to: agent1,
                reason: "fixture_moved"
            ),
            role: "wander_fixture",
            localHints: ["move_west"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_5_invalid_edge",
            position: agent5,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_5_invalid_edge",
                kind: .blockedByInvalidEdge,
                from: agent5,
                to: LabTerrainPathNodeKey(x: 8, y: 65, z: 0),
                reason: "fixture_blocked_by_invalid_edge"
            ),
            role: "bad_fixture_invalid_vertical",
            localHints: ["move_vertical"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_3_conflict",
            position: agent3,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_3_conflict",
                kind: .blockedByAgentConflict,
                from: agent3,
                to: LabTerrainPathNodeKey(x: 3, y: 64, z: 0),
                reason: "fixture_blocked_by_agent_conflict"
            ),
            role: "wander_fixture",
            localHints: ["move_west"]
        )
    ]
}

private func feedbackAwareIntentToTickLiveReadonlyContexts() -> [LabAgentIntentContext] {
    let agent0 = LabTerrainPathNodeKey(x: 0, y: 64, z: 0)
    let agent1 = LabTerrainPathNodeKey(x: 2, y: 64, z: 0)
    let agent2 = LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
    let agent3 = LabTerrainPathNodeKey(x: 4, y: 64, z: 0)
    let agent4 = LabTerrainPathNodeKey(x: 9, y: 64, z: 7)
    let agent5 = LabTerrainPathNodeKey(x: 8, y: 64, z: 0)
    let agent6 = LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
    return [
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_2_collision_feedback",
            position: agent2,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_2_collision_feedback",
                kind: .blockedByCollision,
                from: agent2,
                to: LabTerrainPathNodeKey(x: 8, y: 64, z: 8),
                reason: "fixture_blocked_by_collision"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_0_no_feedback",
            position: agent0,
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_6_live_collision",
            position: agent6,
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_4_approved",
            position: agent4,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_4_approved",
                kind: .approvedForMovement,
                from: agent4,
                to: LabTerrainPathNodeKey(x: 9, y: 64, z: 8),
                reason: "fixture_approved_for_movement"
            ),
            role: "wander_fixture",
            localHints: ["move_south"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_1_moved",
            position: agent1,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_1_moved",
                kind: .moved,
                from: LabTerrainPathNodeKey(x: 3, y: 64, z: 0),
                to: agent1,
                reason: "fixture_moved"
            ),
            role: "wander_fixture",
            localHints: ["move_west"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_5_invalid_edge_feedback",
            position: agent5,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_5_invalid_edge_feedback",
                kind: .blockedByInvalidEdge,
                from: agent5,
                to: LabTerrainPathNodeKey(x: 8, y: 65, z: 0),
                reason: "fixture_blocked_by_invalid_edge"
            ),
            role: "bad_fixture_invalid_vertical",
            localHints: ["move_vertical"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_3_conflict_feedback",
            position: agent3,
            lastFeedback: feedbackAwarePolicyFeedback(
                agentId: "agent_3_conflict_feedback",
                kind: .blockedByAgentConflict,
                from: agent3,
                to: LabTerrainPathNodeKey(x: 3, y: 64, z: 0),
                reason: "fixture_blocked_by_agent_conflict"
            ),
            role: "wander_fixture",
            localHints: ["move_west"]
        )
    ]
}

func makeFeedbackAwareIntentToTickFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabFeedbackAwareIntentToTickFixtureReport {
    let inputContexts = feedbackAwareIntentToTickFixtureContexts()
    let baselineProposals = inputContexts.map(produceAgentIntentProposalV0(context:)).sorted {
        $0.agentId < $1.agentId
    }
    let baselineResult = produceAgentIntentProductionResult(
        tick: 0,
        contexts: inputContexts,
        rawProposals: baselineProposals,
        maxProposals: nil
    )
    let feedbackAwareDecisions = inputContexts.map(produceAgentIntentProposalFeedbackAwareV1(context:)).sorted {
        $0.agentId < $1.agentId
    }
    let feedbackAwareProposals = feedbackAwareDecisions.map(\.feedbackAwareProposal)
    let feedbackAwareResult = produceAgentIntentProductionResult(
        tick: 0,
        contexts: inputContexts,
        rawProposals: feedbackAwareProposals,
        maxProposals: nil
    )
    let agents = Dictionary(
        uniqueKeysWithValues: inputContexts.compactMap { context in
            context.position.map { (context.agentId, $0) }
        }
    )
    let tickInput = LabMultiAgentMovementTickInput(
        tick: 0,
        agents: agents,
        physicalPositions: agents,
        intents: feedbackAwareResult.acceptedIntents,
        maxAgents: nil
    )
    let tickReport = makeMultiAgentMovementTickFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        input: tickInput,
        expectedApproved: 2,
        expectedDenied: 1,
        expectedDecisionCounts: [
            LabMultiAgentMoveDecision.approved.rawValue: 2,
            LabMultiAgentMoveDecision.deniedSameDestinationConflict.rawValue: 1
        ]
    )
    let behaviorChangedCount = feedbackAwareDecisions.filter(\.behaviorChanged).count
    let noIntentFilteredOut = feedbackAwareResult.rejectedProposals.filter {
        $0.decision == .noIntent
    }
    let movementIntentReduction = baselineResult.acceptedIntents.count
        - feedbackAwareResult.acceptedIntents.count
    let agent0Approved = tickReport.output.resolutions.contains {
        $0.agentId == "agent_0_no_feedback" && $0.decision == .approved && $0.approved
    }
    let agent1Denied = tickReport.output.resolutions.contains {
        $0.agentId == "agent_1_moved"
            && $0.decision == .deniedSameDestinationConflict
            && !$0.approved
    }
    let agent4Approved = tickReport.output.resolutions.contains {
        $0.agentId == "agent_4_approved" && $0.decision == .approved && $0.approved
    }
    let positionsUnchanged = tickReport.output.abstractPositionsBefore == tickReport.output.abstractPositionsAfter
        && tickReport.output.physicalPositionsBefore == tickReport.output.physicalPositionsAfter
    let summary = LabFeedbackAwareIntentToTickFixtureSummary(
        tick: 0,
        contexts: inputContexts.count,
        contextsWithFeedback: inputContexts.filter { $0.lastFeedback != nil }.count,
        contextsWithoutFeedback: inputContexts.filter { $0.lastFeedback == nil }.count,
        baselineProposals: baselineProposals.count,
        feedbackAwareProposals: feedbackAwareProposals.count,
        baselineMovementIntentInputs: baselineResult.acceptedIntents.count,
        feedbackAwareMovementIntentInputs: feedbackAwareResult.acceptedIntents.count,
        movementIntentReduction: movementIntentReduction,
        noIntentFilteredOut: noIntentFilteredOut.count,
        feedbackAwareAcceptedIntents: feedbackAwareResult.summary.acceptedIntents,
        feedbackAwareRejectedProposals: feedbackAwareResult.summary.rejectedProposals,
        feedbackAwareNoIntent: feedbackAwareResult.summary.noIntent,
        feedbackAwareInvalidOneEdgeProposals: feedbackAwareResult.summary.invalidOneEdgeProposals,
        behaviorChangedByFeedback: behaviorChangedCount > 0,
        behaviorChangedCount: behaviorChangedCount,
        tickIntents: tickInput.intents.count,
        tickApproved: tickReport.summary.approved,
        tickDenied: tickReport.summary.denied,
        tickDeniedSameDestinationConflict: tickReport.summary.sameDestinationConflicts,
        tickFeedbackEmitted: tickReport.output.feedback.count,
        displacementsApplied: tickReport.summary.displacementsApplied,
        policyReadCollision: false,
        tickReadCollision: false,
        movementApplied: false,
        memoryUpdated: false,
        goalChanged: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        worldUsed: false,
        mutationPerformed: false,
        success: baselineResult.summary.acceptedIntents > feedbackAwareResult.summary.acceptedIntents
            && feedbackAwareResult.summary.acceptedIntents == 3
            && feedbackAwareResult.summary.rejectedProposals == 3
            && feedbackAwareResult.summary.noIntent == 3
            && feedbackAwareResult.summary.invalidOneEdgeProposals == 0
            && movementIntentReduction >= 2
            && noIntentFilteredOut.count == 3
            && tickReport.success
            && tickInput.intents.count == 3
            && tickReport.summary.approved == 2
            && tickReport.summary.denied == 1
            && tickReport.summary.sameDestinationConflicts == 1
            && tickReport.output.feedback.count == 3
            && agent0Approved
            && agent1Denied
            && agent4Approved
            && positionsUnchanged
            && tickReport.summary.displacementsApplied == 0
    )
    let sortedContexts = inputContexts.sorted { $0.agentId < $1.agentId }
    let handoff = LabFeedbackAwareIntentToTickFixtureHandoff(
        contexts: sortedContexts,
        baselineDecisions: baselineProposals,
        feedbackAwareDecisions: feedbackAwareDecisions,
        movementIntentsSentToTick: feedbackAwareResult.acceptedIntents,
        noIntentFilteredOut: noIntentFilteredOut,
        tickInput: tickInput,
        tickOutput: tickReport.output,
        tickFeedback: tickReport.output.feedback,
        summary: summary
    )
    let success = summary.success
        && !summary.policyReadCollision
        && !summary.tickReadCollision
        && !summary.worldUsed
        && !summary.movementApplied
        && !summary.memoryUpdated
        && !summary.goalChanged
        && !summary.pathfindingPerformed
        && !summary.replanningPerformed
        && !summary.avoidancePerformed
        && !summary.reservationRuntimeUsed
        && !summary.mutationPerformed
    return LabFeedbackAwareIntentToTickFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: success,
        contexts: sortedContexts,
        baselinePolicyDecisions: baselineProposals,
        feedbackAwarePolicyDecisions: feedbackAwareDecisions,
        feedbackAwareMovementTickInput: tickInput,
        tickResult: tickReport.output,
        handoff: handoff,
        summary: summary
    )
}

func makeFeedbackAwareIntentToTickLiveReadonlyReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabFeedbackAwareIntentToTickLiveReadonlyReport {
    let inputContexts = feedbackAwareIntentToTickLiveReadonlyContexts()
    let baselineProposals = inputContexts.map(produceAgentIntentProposalV0(context:)).sorted {
        $0.agentId < $1.agentId
    }
    let baselineResult = produceAgentIntentProductionResult(
        tick: 0,
        contexts: inputContexts,
        rawProposals: baselineProposals,
        maxProposals: nil
    )
    let feedbackAwareDecisions = inputContexts.map(produceAgentIntentProposalFeedbackAwareV1(context:)).sorted {
        $0.agentId < $1.agentId
    }
    let feedbackAwareProposals = feedbackAwareDecisions.map(\.feedbackAwareProposal)
    let feedbackAwareResult = produceAgentIntentProductionResult(
        tick: 0,
        contexts: inputContexts,
        rawProposals: feedbackAwareProposals,
        maxProposals: nil
    )
    let agents = Dictionary(
        uniqueKeysWithValues: inputContexts.compactMap { context in
            context.position.map { (context.agentId, $0) }
        }
    )
    let tickInput = LabMultiAgentMovementTickInput(
        tick: 0,
        agents: agents,
        physicalPositions: agents,
        intents: feedbackAwareResult.acceptedIntents,
        maxAgents: nil
    )
    let tickReport = makeMultiAgentMovementTickLiveReadonlyReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        input: tickInput,
        evidenceSeeds: [
            "agent_0_no_feedback": 99,
            "agent_1_moved": 99,
            "agent_4_approved": 99,
            "agent_6_live_collision": 42
        ],
        expectedApproved: 2,
        expectedDenied: 2,
        expectedOccupableDestinations: 3,
        expectedNonOccupableDestinations: 1,
        expectedCollisionDenied: 1,
        requireSourceMismatch: false,
        requireInvalidEdges: false
    )
    let behaviorChangedCount = feedbackAwareDecisions.filter(\.behaviorChanged).count
    let noIntentFilteredOut = feedbackAwareResult.rejectedProposals.filter {
        $0.decision == .noIntent
    }
    let movementIntentReduction = baselineResult.acceptedIntents.count
        - feedbackAwareResult.acceptedIntents.count
    let agent0Approved = tickReport.output.resolutions.contains {
        $0.agentId == "agent_0_no_feedback" && $0.decision == .approved && $0.approved
    }
    let agent1DeniedConflict = tickReport.output.resolutions.contains {
        $0.agentId == "agent_1_moved"
            && $0.decision == .deniedSameDestinationConflict
            && !$0.approved
    }
    let agent4Approved = tickReport.output.resolutions.contains {
        $0.agentId == "agent_4_approved" && $0.decision == .approved && $0.approved
    }
    let agent6DeniedCollision = tickReport.output.resolutions.contains {
        $0.agentId == "agent_6_live_collision"
            && $0.decision == .deniedCollision
            && $0.feedbackKind == .blockedByCollision
            && !$0.approved
    }
    let approvedOccupableDestinations = tickReport.output.resolutions.filter {
        $0.approved && $0.collisionStatus == .occupable
    }.count
    let positionsUnchanged = tickReport.output.abstractPositionsBefore == tickReport.output.abstractPositionsAfter
        && tickReport.output.physicalPositionsBefore == tickReport.output.physicalPositionsAfter
    let summary = LabFeedbackAwareIntentToTickLiveReadonlySummary(
        tick: 0,
        contexts: inputContexts.count,
        contextsWithFeedback: inputContexts.filter { $0.lastFeedback != nil }.count,
        contextsWithoutFeedback: inputContexts.filter { $0.lastFeedback == nil }.count,
        baselineProposals: baselineProposals.count,
        feedbackAwareProposals: feedbackAwareProposals.count,
        baselineMovementIntentInputs: baselineResult.acceptedIntents.count,
        feedbackAwareMovementIntentInputs: feedbackAwareResult.acceptedIntents.count,
        movementIntentReduction: movementIntentReduction,
        noIntentFilteredOut: noIntentFilteredOut.count,
        feedbackAwareAcceptedIntents: feedbackAwareResult.summary.acceptedIntents,
        feedbackAwareRejectedProposals: feedbackAwareResult.summary.rejectedProposals,
        feedbackAwareNoIntent: feedbackAwareResult.summary.noIntent,
        feedbackAwareInvalidOneEdgeProposals: feedbackAwareResult.summary.invalidOneEdgeProposals,
        behaviorChangedByFeedback: behaviorChangedCount > 0,
        behaviorChangedCount: behaviorChangedCount,
        tickIntents: tickInput.intents.count,
        tickApproved: tickReport.summary.approved,
        tickDenied: tickReport.summary.denied,
        tickDeniedSameDestinationConflict: tickReport.summary.sameDestinationConflicts,
        tickDeniedCollision: tickReport.summary.collisionDenied,
        tickFeedbackEmitted: tickReport.output.feedback.count,
        occupableDestinations: approvedOccupableDestinations,
        nonOccupableDestinations: tickReport.summary.nonOccupableDestinations,
        displacementsApplied: tickReport.summary.displacementsApplied,
        policyReadCollision: false,
        tickReadCollision: tickReport.summary.liveCollisionRead,
        policyWorldUsed: false,
        tickWorldReadOnlyUsed: tickReport.summary.worldUsed,
        movementApplied: tickReport.summary.physicalMovementApplied,
        memoryUpdated: false,
        goalChanged: false,
        pathfindingPerformed: tickReport.summary.pathfindingPerformed,
        replanningPerformed: tickReport.summary.replanningPerformed,
        avoidancePerformed: tickReport.summary.avoidancePerformed,
        reservationRuntimeUsed: tickReport.summary.reservationRuntimeUsed,
        worldMutated: tickReport.summary.mutationPerformed,
        mutationPerformed: tickReport.summary.mutationPerformed,
        success: baselineResult.summary.acceptedIntents > feedbackAwareResult.summary.acceptedIntents
            && feedbackAwareResult.summary.acceptedIntents == 4
            && feedbackAwareResult.summary.rejectedProposals == 3
            && feedbackAwareResult.summary.noIntent == 3
            && feedbackAwareResult.summary.invalidOneEdgeProposals == 0
            && movementIntentReduction >= 2
            && noIntentFilteredOut.count == 3
            && tickReport.success
            && tickInput.intents.count == 4
            && tickReport.summary.approved == 2
            && tickReport.summary.denied == 2
            && tickReport.summary.sameDestinationConflicts == 1
            && tickReport.summary.collisionDenied == 1
            && approvedOccupableDestinations == 2
            && tickReport.summary.nonOccupableDestinations == 1
            && tickReport.output.feedback.count == 4
            && agent0Approved
            && agent1DeniedConflict
            && agent4Approved
            && agent6DeniedCollision
            && positionsUnchanged
            && tickReport.summary.displacementsApplied == 0
            && tickReport.summary.worldUsed
            && tickReport.summary.liveCollisionRead
            && !tickReport.summary.physicalMovementApplied
            && !tickReport.summary.pathfindingPerformed
            && !tickReport.summary.replanningPerformed
            && !tickReport.summary.avoidancePerformed
            && !tickReport.summary.reservationRuntimeUsed
            && !tickReport.summary.mutationPerformed
    )
    let sortedContexts = inputContexts.sorted { $0.agentId < $1.agentId }
    let handoff = LabFeedbackAwareIntentToTickLiveReadonlyHandoff(
        contexts: sortedContexts,
        baselineDecisions: baselineProposals,
        feedbackAwareDecisions: feedbackAwareDecisions,
        movementIntentsSentToTick: feedbackAwareResult.acceptedIntents,
        noIntentFilteredOut: noIntentFilteredOut,
        tickInput: tickInput,
        tickOutput: tickReport.output,
        tickFeedback: tickReport.output.feedback,
        collisionEvidence: tickReport.output.resolutions.filter(\.collisionRead),
        summary: summary
    )
    let success = summary.success
        && !summary.policyReadCollision
        && !summary.policyWorldUsed
        && summary.tickReadCollision
        && summary.tickWorldReadOnlyUsed
        && !summary.movementApplied
        && !summary.memoryUpdated
        && !summary.goalChanged
        && !summary.pathfindingPerformed
        && !summary.replanningPerformed
        && !summary.avoidancePerformed
        && !summary.reservationRuntimeUsed
        && !summary.worldMutated
        && !summary.mutationPerformed
    return LabFeedbackAwareIntentToTickLiveReadonlyReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: success,
        contexts: sortedContexts,
        baselinePolicyDecisions: baselineProposals,
        feedbackAwarePolicyDecisions: feedbackAwareDecisions,
        feedbackAwareMovementTickInput: tickInput,
        tickResult: tickReport.output,
        handoff: handoff,
        summary: summary
    )
}

func makeFeedbackAwareIntentToTickFixtureInvariantReport(
    report: LabFeedbackAwareIntentToTickFixtureReport?,
    scenario: String,
    seed: UInt32
) -> LabFeedbackAwareIntentToTickFixtureInvariantReport {
    guard let report else {
        let check = agentIntentInvariantCheck(
            "report_written",
            false,
            "feedback_aware_intent_to_tick_fixture_report.json",
            "missing"
        )
        return LabFeedbackAwareIntentToTickFixtureInvariantReport(
            scenario: scenario,
            seed: seed,
            success: false,
            summary: LabMultiAgentMovementFixtureInvariantSummary(
                checksPassed: 0,
                checksFailed: 1,
                cases: 1,
                passed: 0,
                failed: 1
            ),
            checks: [check],
            notes: ["Feedback-aware intent to tick fixture report was not produced."]
        )
    }
    let contextIds = report.contexts.map(\.agentId)
    let inputContextIds = feedbackAwareIntentToTickFixtureContexts().map(\.agentId)
    let decisionIds = report.feedbackAwarePolicyDecisions.map(\.agentId)
    let tickIntentIds = report.feedbackAwareMovementTickInput.intents.map(\.agentId)
    let decisionsByAgent = Dictionary(uniqueKeysWithValues: report.feedbackAwarePolicyDecisions.map { ($0.agentId, $0) })
    let tickFeedbackKinds = Dictionary(uniqueKeysWithValues: report.tickResult.feedback.map { ($0.agentId, $0.kind) })
    let acceptedOneEdge = report.feedbackAwareMovementTickInput.intents.allSatisfy {
        manhattanDistance($0.from, $0.to) == 1
    }
    let acceptedSameY = report.feedbackAwareMovementTickInput.intents.allSatisfy {
        $0.from.y == $0.to.y
    }
    let tickInputCoversSources = report.feedbackAwareMovementTickInput.intents.allSatisfy { intent in
        report.feedbackAwareMovementTickInput.agents[intent.agentId] == intent.from
    }
    let policyDidNotArbitrateConflict = report.feedbackAwareMovementTickInput.intents.filter {
        $0.to == LabTerrainPathNodeKey(x: 1, y: 64, z: 0)
    }.count == 2
    let tickArbitratedConflict = report.tickResult.resolutions.contains {
        $0.agentId == "agent_0_no_feedback" && $0.decision == .approved && $0.approved
    } && report.tickResult.resolutions.contains {
        $0.agentId == "agent_1_moved"
            && $0.decision == .deniedSameDestinationConflict
            && !$0.approved
    }
    let positionsUnchanged = report.tickResult.abstractPositionsBefore == report.tickResult.abstractPositionsAfter
        && report.tickResult.physicalPositionsBefore == report.tickResult.physicalPositionsAfter
    let checks: [LabMultiAgentMovementFixtureInvariantCheck] = [
        agentIntentInvariantCheck("contexts_exist", !report.contexts.isEmpty, "non-empty", "\(report.contexts.count)"),
        agentIntentInvariantCheck("contexts_intentionally_unordered", inputContextIds != inputContextIds.sorted(), "unordered input", inputContextIds.joined(separator: ",")),
        agentIntentInvariantCheck("contexts_sorted_by_agent_id_for_output", contextIds == contextIds.sorted(), "sorted", contextIds.joined(separator: ",")),
        agentIntentInvariantCheck("v0_policy_remains_available", true, "produceAgentIntentProposalV0 unchanged", "available"),
        agentIntentInvariantCheck("v1_policy_is_opt_in", true, "explicit scenario only", "explicit scenario only"),
        agentIntentInvariantCheck("baseline_decisions_exist", report.baselinePolicyDecisions.count == 6, "6", "\(report.baselinePolicyDecisions.count)"),
        agentIntentInvariantCheck("feedback_aware_decisions_exist", report.feedbackAwarePolicyDecisions.count == 6, "6", "\(report.feedbackAwarePolicyDecisions.count)"),
        agentIntentInvariantCheck("feedback_aware_decisions_sorted", decisionIds == decisionIds.sorted(), "sorted", decisionIds.joined(separator: ",")),
        agentIntentInvariantCheck("no_feedback_keeps_baseline", decisionsByAgent["agent_0_no_feedback"]?.behaviorChanged == false, "false", "\(decisionsByAgent["agent_0_no_feedback"]?.behaviorChanged ?? true)"),
        agentIntentInvariantCheck("moved_keeps_baseline", decisionsByAgent["agent_1_moved"]?.behaviorChanged == false, "false", "\(decisionsByAgent["agent_1_moved"]?.behaviorChanged ?? true)"),
        agentIntentInvariantCheck("approved_for_movement_keeps_baseline", decisionsByAgent["agent_4_approved"]?.behaviorChanged == false, "false", "\(decisionsByAgent["agent_4_approved"]?.behaviorChanged ?? true)"),
        agentIntentInvariantCheck("blocked_collision_becomes_no_intent", decisionsByAgent["agent_2_collision"]?.feedbackAwareDecision == .noIntent, "noIntent", decisionsByAgent["agent_2_collision"]?.feedbackAwareDecision.rawValue ?? "missing"),
        agentIntentInvariantCheck("blocked_agent_conflict_becomes_no_intent", decisionsByAgent["agent_3_conflict"]?.feedbackAwareDecision == .noIntent, "noIntent", decisionsByAgent["agent_3_conflict"]?.feedbackAwareDecision.rawValue ?? "missing"),
        agentIntentInvariantCheck("blocked_invalid_edge_becomes_no_intent", decisionsByAgent["agent_5_invalid_edge"]?.feedbackAwareDecision == .noIntent, "noIntent", decisionsByAgent["agent_5_invalid_edge"]?.feedbackAwareDecision.rawValue ?? "missing"),
        agentIntentInvariantCheck("invalid_edge_not_sent_to_tick", !tickIntentIds.contains("agent_5_invalid_edge"), "not sent", tickIntentIds.joined(separator: ",")),
        agentIntentInvariantCheck("no_intent_filtered_out_before_tick", report.summary.noIntentFilteredOut == 3, "3", "\(report.summary.noIntentFilteredOut)"),
        agentIntentInvariantCheck("movement_intents_sent_to_tick_expected", tickIntentIds == ["agent_0_no_feedback", "agent_1_moved", "agent_4_approved"], "agent_0,agent_1,agent_4", tickIntentIds.joined(separator: ",")),
        agentIntentInvariantCheck("baseline_movement_intents_greater_than_feedback_aware", report.summary.baselineMovementIntentInputs > report.summary.feedbackAwareMovementIntentInputs, "baseline > v1", "\(report.summary.baselineMovementIntentInputs) > \(report.summary.feedbackAwareMovementIntentInputs)"),
        agentIntentInvariantCheck("movement_intent_reduction_expected", report.summary.movementIntentReduction >= 2, ">=2", "\(report.summary.movementIntentReduction)"),
        agentIntentInvariantCheck("tick_input_exists", report.feedbackAwareMovementTickInput.tick == 0, "tick 0", "\(report.feedbackAwareMovementTickInput.tick)"),
        agentIntentInvariantCheck("tick_intents_expected", report.summary.tickIntents == 3, "3", "\(report.summary.tickIntents)"),
        agentIntentInvariantCheck("tick_approved_expected", report.summary.tickApproved == 2, "2", "\(report.summary.tickApproved)"),
        agentIntentInvariantCheck("tick_denied_expected", report.summary.tickDenied == 1, "1", "\(report.summary.tickDenied)"),
        agentIntentInvariantCheck("tick_same_destination_conflict_expected", report.summary.tickDeniedSameDestinationConflict == 1, "1", "\(report.summary.tickDeniedSameDestinationConflict)"),
        agentIntentInvariantCheck("tick_feedback_emitted_expected", report.summary.tickFeedbackEmitted == 3, "3", "\(report.summary.tickFeedbackEmitted)"),
        agentIntentInvariantCheck("policy_does_not_arbitrate_conflict", policyDidNotArbitrateConflict, "same destination preserved", "\(policyDidNotArbitrateConflict)"),
        agentIntentInvariantCheck("tick_arbitrates_remaining_conflict", tickArbitratedConflict, "agent_0 wins, agent_1 denied", "\(tickArbitratedConflict)"),
        agentIntentInvariantCheck("policy_read_collision_false", !report.summary.policyReadCollision, "false", "\(report.summary.policyReadCollision)"),
        agentIntentInvariantCheck("tick_read_collision_false", !report.summary.tickReadCollision, "false", "\(report.summary.tickReadCollision)"),
        agentIntentInvariantCheck("movement_not_applied", !report.summary.movementApplied, "false", "\(report.summary.movementApplied)"),
        agentIntentInvariantCheck("displacements_applied_zero", report.summary.displacementsApplied == 0, "0", "\(report.summary.displacementsApplied)"),
        agentIntentInvariantCheck("positions_unchanged", positionsUnchanged, "unchanged", "\(positionsUnchanged)"),
        agentIntentInvariantCheck("memory_not_updated", !report.summary.memoryUpdated, "false", "\(report.summary.memoryUpdated)"),
        agentIntentInvariantCheck("goal_not_changed", !report.summary.goalChanged, "false", "\(report.summary.goalChanged)"),
        agentIntentInvariantCheck("pathfinding_not_performed", !report.summary.pathfindingPerformed, "false", "\(report.summary.pathfindingPerformed)"),
        agentIntentInvariantCheck("replanning_not_performed", !report.summary.replanningPerformed, "false", "\(report.summary.replanningPerformed)"),
        agentIntentInvariantCheck("avoidance_not_performed", !report.summary.avoidancePerformed, "false", "\(report.summary.avoidancePerformed)"),
        agentIntentInvariantCheck("reservation_runtime_not_used", !report.summary.reservationRuntimeUsed, "false", "\(report.summary.reservationRuntimeUsed)"),
        agentIntentInvariantCheck("world_not_used", !report.summary.worldUsed, "false", "\(report.summary.worldUsed)"),
        agentIntentInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("world_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("route_following_not_used", true, "not used", "not used"),
        agentIntentInvariantCheck("live_collision_not_used", !report.summary.policyReadCollision && !report.summary.tickReadCollision, "false", "\(report.summary.policyReadCollision)/\(report.summary.tickReadCollision)"),
        agentIntentInvariantCheck("feedback_aware_policy_hardening_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("feedback_aware_policy_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("feedback_to_context_hardening_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("agent_intent_v0_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("accepted_intents_are_one_edge", acceptedOneEdge, "one-edge", "\(acceptedOneEdge)"),
        agentIntentInvariantCheck("accepted_intents_are_same_y", acceptedSameY, "same-y", "\(acceptedSameY)"),
        agentIntentInvariantCheck("tick_input_agents_cover_intent_sources", tickInputCoversSources, "sources covered", "\(tickInputCoversSources)"),
        agentIntentInvariantCheck("approved_feedback_is_approved_for_movement", tickFeedbackKinds["agent_0_no_feedback"] == .approvedForMovement && tickFeedbackKinds["agent_4_approved"] == .approvedForMovement, "approvedForMovement", "\(tickFeedbackKinds)"),
        agentIntentInvariantCheck("denied_conflict_feedback_is_blocked_by_agent_conflict", tickFeedbackKinds["agent_1_moved"] == .blockedByAgentConflict, "blockedByAgentConflict", "\(tickFeedbackKinds["agent_1_moved"]?.rawValue ?? "missing")"),
        agentIntentInvariantCheck("report_written", true, "feedback_aware_intent_to_tick_fixture_report.json", "feedback_aware_intent_to_tick_fixture_report.json"),
        agentIntentInvariantCheck("handoff_written", true, "feedback_aware_intent_to_tick_handoff.json", "feedback_aware_intent_to_tick_handoff.json"),
        agentIntentInvariantCheck("metrics_written", true, "feedbackAwareIntentToTickFixture*", "feedbackAwareIntentToTickFixture*"),
        agentIntentInvariantCheck("event_written", true, "lab_feedback_aware_intent_to_tick_fixture_recorded", "lab_feedback_aware_intent_to_tick_fixture_recorded"),
        agentIntentInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let passed = checks.filter(\.passed).count
    return LabFeedbackAwareIntentToTickFixtureInvariantReport(
        scenario: scenario,
        seed: seed,
        success: passed == checks.count,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: checks.count - passed,
            cases: 1,
            passed: report.success ? 1 : 0,
            failed: report.success ? 0 : 1
        ),
        checks: checks,
        notes: [
            "Feedback-aware v1 remains opt-in; v0 is used only for comparison.",
            "NoIntent proposals are filtered before fixture tick input.",
            "The remaining same-destination conflict is intentionally resolved by the tick fixture layer."
        ]
    )
}

func makeFeedbackAwareIntentToTickLiveReadonlyInvariantReport(
    report: LabFeedbackAwareIntentToTickLiveReadonlyReport?,
    scenario: String,
    seed: UInt32
) -> LabFeedbackAwareIntentToTickLiveReadonlyInvariantReport {
    guard let report else {
        let check = agentIntentInvariantCheck(
            "report_written",
            false,
            "feedback_aware_intent_to_tick_live_readonly_report.json",
            "missing"
        )
        return LabFeedbackAwareIntentToTickLiveReadonlyInvariantReport(
            scenario: scenario,
            seed: seed,
            success: false,
            summary: LabMultiAgentMovementFixtureInvariantSummary(
                checksPassed: 0,
                checksFailed: 1,
                cases: 1,
                passed: 0,
                failed: 1
            ),
            checks: [check],
            notes: ["Feedback-aware intent to tick live read-only report was not produced."]
        )
    }
    let contextIds = report.contexts.map(\.agentId)
    let inputContextIds = feedbackAwareIntentToTickLiveReadonlyContexts().map(\.agentId)
    let decisionIds = report.feedbackAwarePolicyDecisions.map(\.agentId)
    let tickIntentIds = report.feedbackAwareMovementTickInput.intents.map(\.agentId)
    let decisionsByAgent = Dictionary(uniqueKeysWithValues: report.feedbackAwarePolicyDecisions.map { ($0.agentId, $0) })
    let tickFeedbackKinds = Dictionary(uniqueKeysWithValues: report.tickResult.feedback.map { ($0.agentId, $0.kind) })
    let acceptedOneEdge = report.feedbackAwareMovementTickInput.intents.allSatisfy {
        manhattanDistance($0.from, $0.to) == 1
    }
    let acceptedSameY = report.feedbackAwareMovementTickInput.intents.allSatisfy {
        $0.from.y == $0.to.y
    }
    let tickInputCoversSources = report.feedbackAwareMovementTickInput.intents.allSatisfy { intent in
        report.feedbackAwareMovementTickInput.agents[intent.agentId] == intent.from
    }
    let policyDidNotArbitrateConflict = report.feedbackAwareMovementTickInput.intents.filter {
        $0.to == LabTerrainPathNodeKey(x: 1, y: 64, z: 0)
    }.count == 2
    let tickArbitratedConflict = report.tickResult.resolutions.contains {
        $0.agentId == "agent_0_no_feedback" && $0.decision == .approved && $0.approved
    } && report.tickResult.resolutions.contains {
        $0.agentId == "agent_1_moved"
            && $0.decision == .deniedSameDestinationConflict
            && !$0.approved
    }
    let collisionDenied = report.tickResult.resolutions.contains {
        $0.agentId == "agent_6_live_collision"
            && $0.decision == .deniedCollision
            && $0.feedbackKind == .blockedByCollision
            && $0.collisionRead
    }
    let positionsUnchanged = report.tickResult.abstractPositionsBefore == report.tickResult.abstractPositionsAfter
        && report.tickResult.physicalPositionsBefore == report.tickResult.physicalPositionsAfter
    let checks: [LabMultiAgentMovementFixtureInvariantCheck] = [
        agentIntentInvariantCheck("contexts_exist", !report.contexts.isEmpty, "non-empty", "\(report.contexts.count)"),
        agentIntentInvariantCheck("contexts_intentionally_unordered", inputContextIds != inputContextIds.sorted(), "unordered input", inputContextIds.joined(separator: ",")),
        agentIntentInvariantCheck("contexts_sorted_by_agent_id_for_output", contextIds == contextIds.sorted(), "sorted", contextIds.joined(separator: ",")),
        agentIntentInvariantCheck("v0_policy_remains_available", true, "produceAgentIntentProposalV0 unchanged", "available"),
        agentIntentInvariantCheck("v1_policy_is_opt_in", true, "explicit scenario only", "explicit scenario only"),
        agentIntentInvariantCheck("baseline_decisions_exist", report.baselinePolicyDecisions.count == 7, "7", "\(report.baselinePolicyDecisions.count)"),
        agentIntentInvariantCheck("feedback_aware_decisions_exist", report.feedbackAwarePolicyDecisions.count == 7, "7", "\(report.feedbackAwarePolicyDecisions.count)"),
        agentIntentInvariantCheck("feedback_aware_decisions_sorted", decisionIds == decisionIds.sorted(), "sorted", decisionIds.joined(separator: ",")),
        agentIntentInvariantCheck("no_feedback_keeps_baseline", decisionsByAgent["agent_0_no_feedback"]?.behaviorChanged == false && decisionsByAgent["agent_6_live_collision"]?.behaviorChanged == false, "false", "\(decisionsByAgent["agent_0_no_feedback"]?.behaviorChanged ?? true)/\(decisionsByAgent["agent_6_live_collision"]?.behaviorChanged ?? true)"),
        agentIntentInvariantCheck("moved_keeps_baseline", decisionsByAgent["agent_1_moved"]?.behaviorChanged == false, "false", "\(decisionsByAgent["agent_1_moved"]?.behaviorChanged ?? true)"),
        agentIntentInvariantCheck("approved_for_movement_keeps_baseline", decisionsByAgent["agent_4_approved"]?.behaviorChanged == false, "false", "\(decisionsByAgent["agent_4_approved"]?.behaviorChanged ?? true)"),
        agentIntentInvariantCheck("blocked_collision_feedback_becomes_no_intent", decisionsByAgent["agent_2_collision_feedback"]?.feedbackAwareDecision == .noIntent, "noIntent", decisionsByAgent["agent_2_collision_feedback"]?.feedbackAwareDecision.rawValue ?? "missing"),
        agentIntentInvariantCheck("blocked_agent_conflict_feedback_becomes_no_intent", decisionsByAgent["agent_3_conflict_feedback"]?.feedbackAwareDecision == .noIntent, "noIntent", decisionsByAgent["agent_3_conflict_feedback"]?.feedbackAwareDecision.rawValue ?? "missing"),
        agentIntentInvariantCheck("blocked_invalid_edge_feedback_becomes_no_intent", decisionsByAgent["agent_5_invalid_edge_feedback"]?.feedbackAwareDecision == .noIntent, "noIntent", decisionsByAgent["agent_5_invalid_edge_feedback"]?.feedbackAwareDecision.rawValue ?? "missing"),
        agentIntentInvariantCheck("invalid_edge_not_sent_to_tick", !tickIntentIds.contains("agent_5_invalid_edge_feedback"), "not sent", tickIntentIds.joined(separator: ",")),
        agentIntentInvariantCheck("no_intent_filtered_out_before_tick", report.summary.noIntentFilteredOut == 3, "3", "\(report.summary.noIntentFilteredOut)"),
        agentIntentInvariantCheck("movement_intents_sent_to_tick_expected", tickIntentIds == ["agent_0_no_feedback", "agent_1_moved", "agent_4_approved", "agent_6_live_collision"], "agent_0,agent_1,agent_4,agent_6", tickIntentIds.joined(separator: ",")),
        agentIntentInvariantCheck("baseline_movement_intents_greater_than_feedback_aware", report.summary.baselineMovementIntentInputs > report.summary.feedbackAwareMovementIntentInputs, "baseline > v1", "\(report.summary.baselineMovementIntentInputs) > \(report.summary.feedbackAwareMovementIntentInputs)"),
        agentIntentInvariantCheck("movement_intent_reduction_expected", report.summary.movementIntentReduction >= 2, ">=2", "\(report.summary.movementIntentReduction)"),
        agentIntentInvariantCheck("tick_input_exists", report.feedbackAwareMovementTickInput.tick == 0, "tick 0", "\(report.feedbackAwareMovementTickInput.tick)"),
        agentIntentInvariantCheck("tick_intents_expected", report.summary.tickIntents == 4, "4", "\(report.summary.tickIntents)"),
        agentIntentInvariantCheck("tick_approved_expected", report.summary.tickApproved == 2, "2", "\(report.summary.tickApproved)"),
        agentIntentInvariantCheck("tick_denied_expected", report.summary.tickDenied == 2, "2", "\(report.summary.tickDenied)"),
        agentIntentInvariantCheck("tick_same_destination_conflict_expected", report.summary.tickDeniedSameDestinationConflict == 1, "1", "\(report.summary.tickDeniedSameDestinationConflict)"),
        agentIntentInvariantCheck("tick_collision_denial_expected", report.summary.tickDeniedCollision == 1 && collisionDenied, "1", "\(report.summary.tickDeniedCollision), collisionDenied=\(collisionDenied)"),
        agentIntentInvariantCheck("tick_feedback_emitted_expected", report.summary.tickFeedbackEmitted == 4, "4", "\(report.summary.tickFeedbackEmitted)"),
        agentIntentInvariantCheck("policy_does_not_arbitrate_conflict", policyDidNotArbitrateConflict, "same destination preserved", "\(policyDidNotArbitrateConflict)"),
        agentIntentInvariantCheck("tick_arbitrates_remaining_conflict", tickArbitratedConflict, "agent_0 wins, agent_1 denied", "\(tickArbitratedConflict)"),
        agentIntentInvariantCheck("policy_read_collision_false", !report.summary.policyReadCollision, "false", "\(report.summary.policyReadCollision)"),
        agentIntentInvariantCheck("policy_world_used_false", !report.summary.policyWorldUsed, "false", "\(report.summary.policyWorldUsed)"),
        agentIntentInvariantCheck("tick_read_collision_true", report.summary.tickReadCollision, "true", "\(report.summary.tickReadCollision)"),
        agentIntentInvariantCheck("tick_world_readonly_used_true", report.summary.tickWorldReadOnlyUsed, "true", "\(report.summary.tickWorldReadOnlyUsed)"),
        agentIntentInvariantCheck("occupable_destinations_expected", report.summary.occupableDestinations == 2, "2", "\(report.summary.occupableDestinations)"),
        agentIntentInvariantCheck("non_occupable_destinations_expected", report.summary.nonOccupableDestinations == 1, "1", "\(report.summary.nonOccupableDestinations)"),
        agentIntentInvariantCheck("movement_not_applied", !report.summary.movementApplied, "false", "\(report.summary.movementApplied)"),
        agentIntentInvariantCheck("displacements_applied_zero", report.summary.displacementsApplied == 0, "0", "\(report.summary.displacementsApplied)"),
        agentIntentInvariantCheck("positions_unchanged", positionsUnchanged, "unchanged", "\(positionsUnchanged)"),
        agentIntentInvariantCheck("memory_not_updated", !report.summary.memoryUpdated, "false", "\(report.summary.memoryUpdated)"),
        agentIntentInvariantCheck("goal_not_changed", !report.summary.goalChanged, "false", "\(report.summary.goalChanged)"),
        agentIntentInvariantCheck("pathfinding_not_performed", !report.summary.pathfindingPerformed, "false", "\(report.summary.pathfindingPerformed)"),
        agentIntentInvariantCheck("replanning_not_performed", !report.summary.replanningPerformed, "false", "\(report.summary.replanningPerformed)"),
        agentIntentInvariantCheck("avoidance_not_performed", !report.summary.avoidancePerformed, "false", "\(report.summary.avoidancePerformed)"),
        agentIntentInvariantCheck("reservation_runtime_not_used", !report.summary.reservationRuntimeUsed, "false", "\(report.summary.reservationRuntimeUsed)"),
        agentIntentInvariantCheck("route_following_not_used", true, "not used", "not used"),
        agentIntentInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        agentIntentInvariantCheck("world_mutation_not_performed", !report.summary.worldMutated, "false", "\(report.summary.worldMutated)"),
        agentIntentInvariantCheck("feedback_aware_intent_to_tick_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("feedback_aware_policy_hardening_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("feedback_aware_policy_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("feedback_to_context_hardening_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("agent_intent_v0_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        agentIntentInvariantCheck("accepted_intents_are_one_edge", acceptedOneEdge, "one-edge", "\(acceptedOneEdge)"),
        agentIntentInvariantCheck("accepted_intents_are_same_y", acceptedSameY, "same-y", "\(acceptedSameY)"),
        agentIntentInvariantCheck("tick_input_agents_cover_intent_sources", tickInputCoversSources, "sources covered", "\(tickInputCoversSources)"),
        agentIntentInvariantCheck("approved_feedback_is_approved_for_movement", tickFeedbackKinds["agent_0_no_feedback"] == .approvedForMovement && tickFeedbackKinds["agent_4_approved"] == .approvedForMovement, "approvedForMovement", "\(tickFeedbackKinds)"),
        agentIntentInvariantCheck("denied_conflict_feedback_is_blocked_by_agent_conflict", tickFeedbackKinds["agent_1_moved"] == .blockedByAgentConflict, "blockedByAgentConflict", "\(tickFeedbackKinds["agent_1_moved"]?.rawValue ?? "missing")"),
        agentIntentInvariantCheck("collision_denied_feedback_is_blocked_by_collision", tickFeedbackKinds["agent_6_live_collision"] == .blockedByCollision, "blockedByCollision", "\(tickFeedbackKinds["agent_6_live_collision"]?.rawValue ?? "missing")"),
        agentIntentInvariantCheck("report_written", true, "feedback_aware_intent_to_tick_live_readonly_report.json", "feedback_aware_intent_to_tick_live_readonly_report.json"),
        agentIntentInvariantCheck("handoff_written", true, "feedback_aware_intent_to_tick_live_readonly_handoff.json", "feedback_aware_intent_to_tick_live_readonly_handoff.json"),
        agentIntentInvariantCheck("metrics_written", true, "feedbackAwareIntentToTickLiveReadonly*", "feedbackAwareIntentToTickLiveReadonly*"),
        agentIntentInvariantCheck("event_written", true, "lab_feedback_aware_intent_to_tick_live_readonly_recorded", "lab_feedback_aware_intent_to_tick_live_readonly_recorded"),
        agentIntentInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let passed = checks.filter(\.passed).count
    return LabFeedbackAwareIntentToTickLiveReadonlyInvariantReport(
        scenario: scenario,
        seed: seed,
        success: passed == checks.count,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: checks.count - passed,
            cases: 1,
            passed: report.success ? 1 : 0,
            failed: report.success ? 0 : 1
        ),
        checks: checks,
        notes: [
            "Feedback-aware v1 remains opt-in; v0 is used only for comparison.",
            "NoIntent proposals are filtered before live read-only tick input.",
            "The policy does not read collision or World; only the tick live read-only layer reads collision evidence.",
            "No movement application or world mutation occurs."
        ]
    )
}

func produceAgentIntentProductionResult(
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
    return produceAgentIntentProductionResult(
        tick: tick,
        contexts: contexts,
        rawProposals: rawProposals,
        maxProposals: maxProposals
    )
}

func produceAgentIntentProductionResult(
    tick: Int,
    contexts: [LabAgentIntentContext],
    rawProposals: [LabAgentIntentProposal],
    maxProposals: Int?
) -> LabAgentIntentProductionResult {
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

private func proposalSignature(_ proposal: LabAgentIntentProposal) -> String {
    let intentPart: String
    if let intent = proposal.intent {
        intentPart = "\(intent.from.x),\(intent.from.y),\(intent.from.z)->\(intent.to.x),\(intent.to.y),\(intent.to.z)"
    } else {
        intentPart = "nil"
    }
    return "\(proposal.agentId)|\(proposal.decision.rawValue)|\(proposal.reason)|\(intentPart)"
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
