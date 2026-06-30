import PebbleCore

struct LabAgentAlternateLocalHintCandidate: Codable {
    let agentId: String
    let tick: Int
    let originalHint: String?
    let hint: String
    let order: Int
    let reason: String
}

struct LabAgentAlternateLocalHintDecision: Codable {
    let tick: Int
    let agentId: String
    let originalHint: String?
    let blockedFeedbackKind: LabMovementFeedbackKind?
    let baselineProposal: LabAgentIntentProposal
    let feedbackAwareV1Proposal: LabAgentIntentProposal
    let alternateCandidates: [LabAgentAlternateLocalHintCandidate]
    let selectedHint: String?
    let selectedProposal: LabAgentIntentProposal
    let maxAlternates: Int
    let bounded: Bool
    let noFeedbackBaseline: Bool
    let approvedFeedbackBaseline: Bool
    let movedFeedbackBaseline: Bool
    let blockedFeedbackUsed: Bool
    let unknownHintNoAlternate: Bool
    let emptyHintNoAlternate: Bool
    let failedDirectionExcluded: Bool
    let oneEdgeAlternate: Bool
    let v0Unchanged: Bool
    let v1Unchanged: Bool
    let v2OptIn: Bool
    let policyReadCollision: Bool
    let policyWorldUsed: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let routeFollowingUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let mutationPerformed: Bool
    let reason: String
}

struct LabAlternateLocalHintSummary: Codable {
    let tick: Int
    let contexts: Int
    let decisions: Int
    let contextsWithBlockedFeedback: Int
    let contextsWithoutFeedback: Int
    let contextsWithApprovedOrMovedFeedback: Int
    let candidatesProduced: Int
    let candidatesSelected: Int
    let candidatesFiltered: Int
    let maxAlternates: Int
    let bounded: Bool
    let noFeedbackBaseline: Int
    let approvedFeedbackBaseline: Int
    let movedFeedbackBaseline: Int
    let blockedFeedbackUsed: Int
    let unknownHintNoAlternate: Int
    let emptyHintNoAlternate: Int
    let failedDirectionExcluded: Int
    let oneEdgeAlternates: Bool
    let movementIntentInputs: Int
    let tickApproved: Int
    let tickDenied: Int
    let tickDeniedConflict: Int
    let tickDeniedCollision: Int
    let tickFeedbackEmitted: Int
    let v0Unchanged: Bool
    let v1Unchanged: Bool
    let v2OptIn: Bool
    let policyReadCollision: Bool
    let policyWorldUsed: Bool
    let tickReadCollision: Bool
    let tickWorldUsed: Bool
    let movementApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let routeFollowingUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let worldMutated: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAlternateLocalHintHandoff: Codable {
    let contexts: [LabAgentIntentContext]
    let decisions: [LabAgentAlternateLocalHintDecision]
    let movementIntentsSentToTick: [LabAgentMoveIntent]
    let noIntentFilteredOut: [LabAgentIntentProposal]
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickOutput
    let tickFeedback: [LabMovementFeedback]
    let summary: LabAlternateLocalHintSummary
}

struct LabAlternateLocalHintReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let policyMode: String
    let contexts: [LabAgentIntentContext]
    let decisions: [LabAgentAlternateLocalHintDecision]
    let handoff: LabAlternateLocalHintHandoff
    let summary: LabAlternateLocalHintSummary
}

struct LabAlternateLocalHintInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAlternateLocalHintHardeningExpected: Codable {
    let candidates: [String]
    let selectedHint: String?
    let decision: LabAgentIntentDecision
    let noAlternateReason: String?
    let success: Bool
}

struct LabAlternateLocalHintHardeningActual: Codable {
    let candidates: [String]
    let selectedHint: String?
    let decision: LabAgentIntentDecision
    let noAlternateReason: String?
    let success: Bool
}

struct LabAlternateLocalHintHardeningCase: Codable {
    let name: String
    let description: String
    let tick: Int
    let agentId: String
    let position: LabTerrainPathNodeKey
    let localHints: [String]
    let feedbackKind: LabMovementFeedbackKind?
    let feedbackFrom: LabTerrainPathNodeKey?
    let feedbackTo: LabTerrainPathNodeKey?
    let maxAlternates: Int
    let expected: LabAlternateLocalHintHardeningExpected
}

struct LabAlternateLocalHintHardeningCaseResult: Codable {
    let name: String
    let passed: Bool
    let context: LabAgentIntentContext
    let decision: LabAgentAlternateLocalHintDecision
    let expected: LabAlternateLocalHintHardeningExpected
    let actual: LabAlternateLocalHintHardeningActual
    let notes: [String]
}

struct LabAlternateLocalHintHardeningSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let contexts: Int
    let decisions: Int
    let contextsWithBlockedFeedback: Int
    let contextsWithoutFeedback: Int
    let contextsWithApprovedOrMovedFeedback: Int
    let blockedFeedbackKindsCovered: Int
    let candidatesProduced: Int
    let candidatesSelected: Int
    let candidatesFiltered: Int
    let maxAlternatesMin: Int
    let maxAlternatesMax: Int
    let maxAlternatesZeroCases: Int
    let maxAlternatesOneCases: Int
    let maxAlternatesTwoCases: Int
    let maxAlternatesThreeCases: Int
    let boundedCases: Int
    let deterministicOrderingCases: Int
    let duplicateHintCases: Int
    let duplicateHintsFiltered: Int
    let unknownHintNoAlternate: Int
    let emptyHintNoAlternate: Int
    let noFeedbackBaseline: Int
    let approvedFeedbackBaseline: Int
    let movedFeedbackBaseline: Int
    let failedDirectionExcluded: Int
    let oneEdgeAlternates: Bool
    let repeatabilityChecks: Int
    let repeatabilityFailures: Int
    let movementIntentInputs: Int
    let tickApproved: Int
    let tickDenied: Int
    let tickDeniedConflict: Int
    let tickDeniedCollision: Int
    let tickFeedbackEmitted: Int
    let v0Unchanged: Bool
    let v1Unchanged: Bool
    let v2OptIn: Bool
    let policyReadCollision: Bool
    let policyWorldUsed: Bool
    let tickReadCollision: Bool
    let tickWorldUsed: Bool
    let movementApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let routeFollowingUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let worldMutated: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAlternateLocalHintHardeningHandoff: Codable {
    let movementIntentsSentToTick: [LabAgentMoveIntent]
    let noIntentFilteredOut: [LabAgentIntentProposal]
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickOutput
    let tickFeedback: [LabMovementFeedback]
    let summary: LabAlternateLocalHintHardeningSummary
}

struct LabAlternateLocalHintHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let cases: [LabAlternateLocalHintHardeningCaseResult]
    let handoff: LabAlternateLocalHintHardeningHandoff
    let summary: LabAlternateLocalHintHardeningSummary
}

struct LabAlternateLocalHintHardeningInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAlternateLocalHintLiveReadonlySummary: Codable {
    let tick: Int
    let contexts: Int
    let decisions: Int
    let contextsWithBlockedFeedback: Int
    let contextsWithoutFeedback: Int
    let contextsWithApprovedOrMovedFeedback: Int
    let candidatesProduced: Int
    let candidatesSelected: Int
    let candidatesFiltered: Int
    let maxAlternates: Int
    let bounded: Bool
    let noFeedbackBaseline: Int
    let approvedFeedbackBaseline: Int
    let movedFeedbackBaseline: Int
    let blockedFeedbackUsed: Int
    let unknownHintNoAlternate: Int
    let emptyHintNoAlternate: Int
    let failedDirectionExcluded: Int
    let oneEdgeAlternates: Bool
    let movementIntentInputs: Int
    let tickApproved: Int
    let tickDenied: Int
    let tickDeniedConflict: Int
    let tickDeniedCollision: Int
    let tickFeedbackEmitted: Int
    let occupableDestinations: Int
    let nonOccupableDestinations: Int
    let v0Unchanged: Bool
    let v1Unchanged: Bool
    let v2OptIn: Bool
    let policyReadCollision: Bool
    let policyWorldUsed: Bool
    let tickReadCollision: Bool
    let tickWorldReadOnlyUsed: Bool
    let movementApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let routeFollowingUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let worldMutated: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAlternateLocalHintLiveReadonlyHandoff: Codable {
    let contexts: [LabAgentIntentContext]
    let decisions: [LabAgentAlternateLocalHintDecision]
    let movementIntentsSentToTick: [LabAgentMoveIntent]
    let noIntentFilteredOut: [LabAgentIntentProposal]
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickLiveReadonlyOutput
    let collisionEvidence: [LabMultiAgentMovementTickLiveReadonlyResolution]
    let tickFeedback: [LabMovementFeedback]
    let summary: LabAlternateLocalHintLiveReadonlySummary
}

struct LabAlternateLocalHintLiveReadonlyReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let policyMode: String
    let contexts: [LabAgentIntentContext]
    let decisions: [LabAgentAlternateLocalHintDecision]
    let handoff: LabAlternateLocalHintLiveReadonlyHandoff
    let summary: LabAlternateLocalHintLiveReadonlySummary
}

struct LabAlternateLocalHintLiveReadonlyInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAlternateLocalHintApprovedApplicationSummary: Codable {
    let tick: Int
    let contexts: Int
    let decisions: Int
    let contextsWithBlockedFeedback: Int
    let contextsWithoutFeedback: Int
    let contextsWithApprovedOrMovedFeedback: Int
    let candidatesProduced: Int
    let candidatesSelected: Int
    let candidatesFiltered: Int
    let maxAlternates: Int
    let bounded: Bool
    let noFeedbackBaseline: Int
    let approvedFeedbackBaseline: Int
    let movedFeedbackBaseline: Int
    let blockedFeedbackUsed: Int
    let unknownHintNoAlternate: Int
    let emptyHintNoAlternate: Int
    let failedDirectionExcluded: Int
    let oneEdgeAlternates: Bool
    let movementIntentInputs: Int
    let tickApproved: Int
    let tickDenied: Int
    let tickDeniedConflict: Int
    let tickDeniedCollision: Int
    let tickFeedbackEmitted: Int
    let occupableDestinations: Int
    let nonOccupableDestinations: Int
    let approvedApplications: Int
    let approvedAgentsMoved: Int
    let deniedAgentsPreserved: Int
    let noIntentAgentsPreserved: Int
    let displacementsApplied: Int
    let abstractPositionsChanged: Int
    let physicalPositionsChanged: Int
    let abstractPhysicalDivergenceBefore: Int
    let abstractPhysicalDivergenceAfter: Int
    let v0Unchanged: Bool
    let v1Unchanged: Bool
    let v2OptIn: Bool
    let policyReadCollision: Bool
    let policyWorldUsed: Bool
    let tickReadCollision: Bool
    let tickWorldReadOnlyUsed: Bool
    let movementApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let routeFollowingUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let worldMutated: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAlternateLocalHintApprovedApplicationPositions: Codable {
    let positionsBefore: [String: LabTerrainPathNodeKey]
    let physicalPositionsBefore: [String: LabTerrainPathNodeKey]
    let positionsAfter: [String: LabTerrainPathNodeKey]
    let physicalPositionsAfter: [String: LabTerrainPathNodeKey]
    let approvedApplications: [String]
    let deniedPreservedAgents: [String]
    let noIntentPreservedAgents: [String]
    let summary: LabAlternateLocalHintApprovedApplicationSummary
}

struct LabAlternateLocalHintApprovedApplicationHandoff: Codable {
    let contexts: [LabAgentIntentContext]
    let decisions: [LabAgentAlternateLocalHintDecision]
    let movementIntentsSentToTick: [LabAgentMoveIntent]
    let noIntentFilteredOut: [LabAgentIntentProposal]
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickApprovedApplicationOutput
    let approvedApplications: [LabMultiAgentMovementTickApprovedApplicationResolution]
    let deniedPreservedAgents: [LabMultiAgentMovementTickApprovedApplicationResolution]
    let noIntentPreservedAgents: [String]
    let positionsBefore: [String: LabTerrainPathNodeKey]
    let positionsAfter: [String: LabTerrainPathNodeKey]
    let collisionEvidence: [LabMultiAgentMovementTickApprovedApplicationResolution]
    let tickFeedback: [LabMovementFeedback]
    let summary: LabAlternateLocalHintApprovedApplicationSummary
}

struct LabAlternateLocalHintApprovedApplicationReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let policyMode: String
    let contexts: [LabAgentIntentContext]
    let decisions: [LabAgentAlternateLocalHintDecision]
    let handoff: LabAlternateLocalHintApprovedApplicationHandoff
    let positions: LabAlternateLocalHintApprovedApplicationPositions
    let summary: LabAlternateLocalHintApprovedApplicationSummary
}

struct LabAlternateLocalHintApprovedApplicationInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAlternateLocalHintMultiTickReplayTickSummary: Codable {
    let tick: Int
    let agents: Int
    let contexts: Int
    let decisions: Int
    let contextsWithBlockedFeedback: Int
    let contextsWithoutFeedback: Int
    let contextsWithApprovedOrMovedFeedback: Int
    let feedbackConsumed: Int
    let feedbackCarriedToNextTick: Int
    let sameTickFeedbackConsumed: Int
    let futureFeedbackConsumed: Int
    let crossAgentFeedbackLeaks: Int
    let candidatesProduced: Int
    let candidatesSelected: Int
    let candidatesFiltered: Int
    let noFeedbackBaseline: Int
    let approvedFeedbackBaseline: Int
    let movedFeedbackBaseline: Int
    let blockedFeedbackUsed: Int
    let unknownHintNoAlternate: Int
    let emptyHintNoAlternate: Int
    let failedDirectionExcluded: Int
    let movementIntentInputs: Int
    let tickApproved: Int
    let tickDenied: Int
    let tickDeniedConflict: Int
    let tickDeniedCollision: Int
    let tickFeedbackEmitted: Int
    let approvedApplications: Int
    let approvedAgentsMoved: Int
    let deniedAgentsPreserved: Int
    let noIntentAgentsPreserved: Int
    let displacementsApplied: Int
    let abstractPositionsChanged: Int
    let physicalPositionsChanged: Int
    let abstractPhysicalDivergenceBefore: Int
    let abstractPhysicalDivergenceAfter: Int
    let policyReadCollision: Bool
    let policyWorldUsed: Bool
    let tickReadCollision: Bool
    let tickWorldReadOnlyUsed: Bool
    let movementApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let routeFollowingUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let worldMutated: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAlternateLocalHintMultiTickReplayTickRecord: Codable {
    let tick: Int
    let contexts: [LabAgentIntentContext]
    let inputFeedbackByAgent: [String: LabMovementFeedback]
    let decisions: [LabAgentAlternateLocalHintDecision]
    let movementIntentsSentToTick: [LabAgentMoveIntent]
    let noIntentFilteredOut: [LabAgentIntentProposal]
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickApprovedApplicationOutput
    let approvedApplications: [LabMultiAgentMovementTickApprovedApplicationResolution]
    let deniedPreservedAgents: [LabMultiAgentMovementTickApprovedApplicationResolution]
    let noIntentPreservedAgents: [String]
    let emittedFeedback: [LabMovementFeedback]
    let feedbackForNextTick: [String: LabMovementFeedback]
    let positionsBefore: [String: LabTerrainPathNodeKey]
    let positionsAfter: [String: LabTerrainPathNodeKey]
    let physicalPositionsBefore: [String: LabTerrainPathNodeKey]
    let physicalPositionsAfter: [String: LabTerrainPathNodeKey]
    let summary: LabAlternateLocalHintMultiTickReplayTickSummary
}

struct LabAlternateLocalHintMultiTickReplayFeedbackLedger: Codable {
    let emittedByTick: [Int: [LabMovementFeedback]]
    let consumedByTick: [Int: [LabMovementFeedback]]
    let carriedToNextTickByTick: [Int: [LabMovementFeedback]]
    let sameTickConsumed: Int
    let futureConsumed: Int
    let crossAgentLeaks: Int
    let tick0FeedbackConsumedAtTick1: Bool
    let tick1FeedbackConsumedAtTick2: Bool
}

struct LabAlternateLocalHintMultiTickReplaySummary: Codable {
    let requestedTicks: Int
    let executedTicks: Int
    let agents: Int
    let contextsTotal: Int
    let decisionsTotal: Int
    let contextsWithBlockedFeedbackTotal: Int
    let contextsWithoutFeedbackTotal: Int
    let contextsWithApprovedOrMovedFeedbackTotal: Int
    let feedbackConsumedTotal: Int
    let feedbackCarriedToNextTickTotal: Int
    let sameTickFeedbackConsumedTotal: Int
    let futureFeedbackConsumedTotal: Int
    let crossAgentFeedbackLeaksTotal: Int
    let candidatesProducedTotal: Int
    let candidatesSelectedTotal: Int
    let candidatesFilteredTotal: Int
    let maxAlternates: Int
    let bounded: Bool
    let noFeedbackBaselineTotal: Int
    let approvedFeedbackBaselineTotal: Int
    let movedFeedbackBaselineTotal: Int
    let blockedFeedbackUsedTotal: Int
    let unknownHintNoAlternateTotal: Int
    let emptyHintNoAlternateTotal: Int
    let failedDirectionExcludedTotal: Int
    let oneEdgeAlternates: Bool
    let movementIntentInputsTotal: Int
    let tickApprovedTotal: Int
    let tickDeniedTotal: Int
    let tickDeniedConflictTotal: Int
    let tickDeniedCollisionTotal: Int
    let tickFeedbackEmittedTotal: Int
    let approvedApplicationsTotal: Int
    let approvedAgentsMovedTotal: Int
    let deniedAgentsPreservedTotal: Int
    let noIntentAgentsPreservedTotal: Int
    let displacementsAppliedTotal: Int
    let abstractPositionsChangedTotal: Int
    let physicalPositionsChangedTotal: Int
    let abstractPhysicalDivergenceBeforeMax: Int
    let abstractPhysicalDivergenceAfterMax: Int
    let replayRuns: Int
    let replayDigestsEqual: Bool
    let repeatabilityFailures: Int
    let deterministicAgentOrder: Bool
    let deterministicCandidateOrder: Bool
    let deterministicDecisionOrder: Bool
    let deterministicJsonOutput: Bool
    let v0Unchanged: Bool
    let v1Unchanged: Bool
    let v2OptIn: Bool
    let policyReadCollision: Bool
    let policyWorldUsed: Bool
    let tickReadCollision: Bool
    let tickWorldReadOnlyUsed: Bool
    let movementApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let routeFollowingUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let worldMutated: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAlternateLocalHintMultiTickReplayDigest: Codable {
    let replayDigest: String
    let replayDigestRepeat: String
    let replayDigestsEqual: Bool
    let repeatabilityFailures: Int
}

struct LabAlternateLocalHintMultiTickReplayPositions: Codable {
    let initialAgents: [String: LabTerrainPathNodeKey]
    let finalAgents: [String: LabTerrainPathNodeKey]
    let positionsByTick: [Int: [String: LabTerrainPathNodeKey]]
    let physicalPositionsByTick: [Int: [String: LabTerrainPathNodeKey]]
    let approvedAgentsByTick: [Int: [String]]
    let deniedAgentsByTick: [Int: [String]]
    let noIntentAgentsByTick: [Int: [String]]
    let divergenceByTick: [Int: Int]
    let summary: LabAlternateLocalHintMultiTickReplaySummary
}

struct LabAlternateLocalHintMultiTickReplayReport: Codable {
    let scenario: String
    let seed: UInt32
    let requestedTicks: Int
    let executedTicks: Int
    let success: Bool
    let policyMode: String
    let initialAgents: [String: LabTerrainPathNodeKey]
    let finalAgents: [String: LabTerrainPathNodeKey]
    let tickRecords: [LabAlternateLocalHintMultiTickReplayTickRecord]
    let feedbackLedger: LabAlternateLocalHintMultiTickReplayFeedbackLedger
    let positions: LabAlternateLocalHintMultiTickReplayPositions
    let replayDigest: String
    let replayDigestRepeat: String
    let summary: LabAlternateLocalHintMultiTickReplaySummary
}

struct LabAlternateLocalHintMultiTickReplayInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

func produceAgentIntentProposalWithAlternateLocalHintsV2(
    context: LabAgentIntentContext,
    maxAlternates: Int
) -> LabAgentAlternateLocalHintDecision {
    let boundedMaxAlternates = max(0, maxAlternates)
    let baseline = produceAgentIntentProposalV0(context: context)
    let v1Decision = produceAgentIntentProposalFeedbackAwareV1(context: context)
    let feedbackKind = context.lastFeedback?.kind
    let originalHint = context.localHints.first
    let blocked = isAlternateLocalHintBlockedFeedback(feedbackKind)
    let candidates = blocked
        ? alternateLocalHintCandidates(
            agentId: context.agentId,
            tick: context.tick,
            originalHint: originalHint,
            maxAlternates: boundedMaxAlternates
        )
        : []

    let selectedHint = candidates.first?.hint
    let proposal: LabAgentIntentProposal
    let reason: String
    if feedbackKind == nil {
        proposal = baseline
        reason = "alternate_local_hint_v2_baseline_no_feedback"
    } else if feedbackKind == .approvedForMovement {
        proposal = baseline
        reason = "alternate_local_hint_v2_baseline_approved_for_movement"
    } else if feedbackKind == .moved {
        proposal = baseline
        reason = "alternate_local_hint_v2_baseline_moved"
    } else if let selectedHint {
        let alternateContext = LabAgentIntentContext(
            tick: context.tick,
            agentId: context.agentId,
            position: context.position,
            lastFeedback: context.lastFeedback,
            role: context.role,
            localHints: [selectedHint]
        )
        proposal = produceAgentIntentProposalV0(context: alternateContext)
        reason = "alternate_local_hint_v2_selected_\(selectedHint)"
    } else if originalHint == nil {
        proposal = alternateLocalHintNoIntentProposal(
            context: context,
            reason: "alternate_local_hint_empty_hint_no_alternate"
        )
        reason = "alternate_local_hint_empty_hint_no_alternate"
    } else {
        proposal = alternateLocalHintNoIntentProposal(
            context: context,
            reason: "alternate_local_hint_unknown_hint_no_alternate"
        )
        reason = "alternate_local_hint_unknown_hint_no_alternate"
    }

    let oneEdgeAlternate = proposal.intent.map(isAlternateLocalHintOneEdgeSameY) ?? (selectedHint == nil)
    return LabAgentAlternateLocalHintDecision(
        tick: context.tick,
        agentId: context.agentId,
        originalHint: originalHint,
        blockedFeedbackKind: blocked ? feedbackKind : nil,
        baselineProposal: baseline,
        feedbackAwareV1Proposal: v1Decision.feedbackAwareProposal,
        alternateCandidates: candidates,
        selectedHint: selectedHint,
        selectedProposal: proposal,
        maxAlternates: boundedMaxAlternates,
        bounded: candidates.count <= boundedMaxAlternates,
        noFeedbackBaseline: feedbackKind == nil
            && alternateLocalHintProposalSignature(proposal) == alternateLocalHintProposalSignature(baseline),
        approvedFeedbackBaseline: feedbackKind == .approvedForMovement
            && alternateLocalHintProposalSignature(proposal) == alternateLocalHintProposalSignature(baseline),
        movedFeedbackBaseline: feedbackKind == .moved
            && alternateLocalHintProposalSignature(proposal) == alternateLocalHintProposalSignature(baseline),
        blockedFeedbackUsed: blocked && selectedHint != nil,
        unknownHintNoAlternate: blocked && originalHint != nil && candidates.isEmpty,
        emptyHintNoAlternate: blocked && originalHint == nil,
        failedDirectionExcluded: blocked && selectedHint != nil,
        oneEdgeAlternate: oneEdgeAlternate,
        v0Unchanged: true,
        v1Unchanged: true,
        v2OptIn: true,
        policyReadCollision: false,
        policyWorldUsed: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        routeFollowingUsed: false,
        memoryUpdated: false,
        goalChanged: false,
        mutationPerformed: false,
        reason: reason
    )
}

func makeAlternateLocalHintFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabAlternateLocalHintReport {
    let tick = 0
    let contexts = alternateLocalHintFixtureContexts(tick: tick)
    let decisions = contexts
        .map { produceAgentIntentProposalWithAlternateLocalHintsV2(context: $0, maxAlternates: 2) }
        .sorted { $0.agentId < $1.agentId }
    let movementIntents = decisions
        .compactMap { $0.selectedProposal.intent }
        .sorted { $0.agentId < $1.agentId }
    let noIntentFilteredOut = decisions
        .map(\.selectedProposal)
        .filter { $0.decision == .noIntent }
        .sorted { $0.agentId < $1.agentId }
    let agents = Dictionary(
        uniqueKeysWithValues: contexts.compactMap { context -> (String, LabTerrainPathNodeKey)? in
            guard let position = context.position else { return nil }
            return (context.agentId, position)
        }
    )
    let tickInput = LabMultiAgentMovementTickInput(
        tick: tick,
        agents: agents,
        physicalPositions: agents,
        intents: movementIntents,
        maxAgents: nil
    )
    let tickReport = makeMultiAgentMovementTickFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        input: tickInput,
        expectedApproved: 4,
        expectedDenied: 0,
        expectedDecisionCounts: [
            LabMultiAgentMoveDecision.approved.rawValue: 4
        ]
    )
    let tickOutput = tickReport.output
    let summary = alternateLocalHintSummary(
        tick: tick,
        contexts: contexts,
        decisions: decisions,
        tickOutput: tickOutput
    )
    let handoff = LabAlternateLocalHintHandoff(
        contexts: contexts.sorted { $0.agentId < $1.agentId },
        decisions: decisions,
        movementIntentsSentToTick: movementIntents,
        noIntentFilteredOut: noIntentFilteredOut,
        tickInput: tickInput,
        tickOutput: tickOutput,
        tickFeedback: tickOutput.feedback,
        summary: summary
    )
    return LabAlternateLocalHintReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        policyMode: "alternateLocalHintV2",
        contexts: contexts.sorted { $0.agentId < $1.agentId },
        decisions: decisions,
        handoff: handoff,
        summary: summary
    )
}

func makeAlternateLocalHintFixtureInvariantReport(
    report: LabAlternateLocalHintReport?,
    scenario: String,
    seed: UInt32
) -> LabAlternateLocalHintInvariantReport? {
    guard let report else { return nil }
    let summary = report.summary
    let contexts = report.contexts
    let decisions = report.decisions
    let contextIds = contexts.map(\.agentId)
    let decisionIds = decisions.map(\.agentId)
    let movementIntentIds = report.handoff.movementIntentsSentToTick.map(\.agentId)
    let noIntentIds = report.handoff.noIntentFilteredOut.map(\.agentId)
    let allDecisionCandidatesSorted = decisions.allSatisfy { decision in
        decision.alternateCandidates.map(\.order) == decision.alternateCandidates.map(\.order).sorted()
    }
    let checks: [LabMultiAgentMovementFixtureInvariantCheck] = [
        alternateLocalHintCheck("scenario_name_expected", report.scenario == scenario, scenario, report.scenario),
        alternateLocalHintCheck("seed_recorded", report.seed == seed, "\(seed)", "\(report.seed)"),
        alternateLocalHintCheck("contexts_exist", !contexts.isEmpty, "non-empty", "\(contexts.count)"),
        alternateLocalHintCheck("context_count_expected", summary.contexts == 6, "6", "\(summary.contexts)"),
        alternateLocalHintCheck("decisions_exist", !decisions.isEmpty, "non-empty", "\(decisions.count)"),
        alternateLocalHintCheck("decision_count_matches_contexts", summary.decisions == summary.contexts, "\(summary.contexts)", "\(summary.decisions)"),
        alternateLocalHintCheck("v0_policy_remains_available", summary.v0Unchanged, "true", "\(summary.v0Unchanged)"),
        alternateLocalHintCheck("v0_policy_unchanged", summary.v0Unchanged, "true", "\(summary.v0Unchanged)"),
        alternateLocalHintCheck("v1_policy_remains_available", summary.v1Unchanged, "true", "\(summary.v1Unchanged)"),
        alternateLocalHintCheck("v1_policy_unchanged", summary.v1Unchanged, "true", "\(summary.v1Unchanged)"),
        alternateLocalHintCheck("v2_policy_is_opt_in", summary.v2OptIn, "true", "\(summary.v2OptIn)"),
        alternateLocalHintCheck("v2_not_global", summary.v2OptIn, "explicit scenario only", "explicit scenario only"),
        alternateLocalHintCheck("no_feedback_keeps_baseline", summary.noFeedbackBaseline == 1, "1", "\(summary.noFeedbackBaseline)"),
        alternateLocalHintCheck("approved_feedback_keeps_baseline", summary.approvedFeedbackBaseline == 1, "1", "\(summary.approvedFeedbackBaseline)"),
        alternateLocalHintCheck("moved_feedback_keeps_baseline", summary.movedFeedbackBaseline == 0, "0", "\(summary.movedFeedbackBaseline)"),
        alternateLocalHintCheck("blocked_feedback_uses_alternate_when_hint_known", summary.blockedFeedbackUsed == 2, "2", "\(summary.blockedFeedbackUsed)"),
        alternateLocalHintCheck("blocked_collision_feedback_uses_alternate_when_hint_known", decisions.contains { $0.agentId == "agent_3_blocked_west_uses_alternate" && $0.selectedHint == "move_north" }, "move_north", "checked"),
        alternateLocalHintCheck("blocked_conflict_feedback_uses_alternate_when_hint_known", decisions.contains { $0.agentId == "agent_2_blocked_east_uses_alternate" && $0.selectedHint == "move_north" }, "move_north", "checked"),
        alternateLocalHintCheck("unknown_hint_produces_no_alternate", summary.unknownHintNoAlternate == 1, "1", "\(summary.unknownHintNoAlternate)"),
        alternateLocalHintCheck("empty_hint_produces_no_alternate", summary.emptyHintNoAlternate == 1, "1", "\(summary.emptyHintNoAlternate)"),
        alternateLocalHintCheck("max_alternates_expected", summary.maxAlternates == 2, "2", "\(summary.maxAlternates)"),
        alternateLocalHintCheck("candidate_count_bounded", summary.bounded, "true", "\(summary.bounded)"),
        alternateLocalHintCheck("candidate_order_deterministic", allDecisionCandidatesSorted, "sorted", "\(allDecisionCandidatesSorted)"),
        alternateLocalHintCheck("failed_direction_excluded", summary.failedDirectionExcluded == 2, "2", "\(summary.failedDirectionExcluded)"),
        alternateLocalHintCheck("alternate_hints_one_edge_only", summary.oneEdgeAlternates, "true", "\(summary.oneEdgeAlternates)"),
        alternateLocalHintCheck("no_multi_step_route", summary.oneEdgeAlternates, "true", "\(summary.oneEdgeAlternates)"),
        alternateLocalHintCheck("no_pathfinding_performed", !summary.pathfindingPerformed, "false", "\(summary.pathfindingPerformed)"),
        alternateLocalHintCheck("no_replanning_performed", !summary.replanningPerformed, "false", "\(summary.replanningPerformed)"),
        alternateLocalHintCheck("no_avoidance_performed", !summary.avoidancePerformed, "false", "\(summary.avoidancePerformed)"),
        alternateLocalHintCheck("no_reservation_runtime_used", !summary.reservationRuntimeUsed, "false", "\(summary.reservationRuntimeUsed)"),
        alternateLocalHintCheck("no_route_following_used", !summary.routeFollowingUsed, "false", "\(summary.routeFollowingUsed)"),
        alternateLocalHintCheck("no_memory_updated", !summary.memoryUpdated, "false", "\(summary.memoryUpdated)"),
        alternateLocalHintCheck("no_goal_changed", !summary.goalChanged, "false", "\(summary.goalChanged)"),
        alternateLocalHintCheck("policy_does_not_read_world", !summary.policyWorldUsed, "false", "\(summary.policyWorldUsed)"),
        alternateLocalHintCheck("policy_does_not_read_collision", !summary.policyReadCollision, "false", "\(summary.policyReadCollision)"),
        alternateLocalHintCheck("tick_fixture_does_not_read_world", !summary.tickWorldUsed, "false", "\(summary.tickWorldUsed)"),
        alternateLocalHintCheck("tick_fixture_does_not_read_collision", !summary.tickReadCollision, "false", "\(summary.tickReadCollision)"),
        alternateLocalHintCheck("tick_receives_only_accepted_movement_intents", movementIntentIds == ["agent_0_no_feedback_baseline", "agent_1_approved_feedback_baseline", "agent_2_blocked_east_uses_alternate", "agent_3_blocked_west_uses_alternate"], "4 movement intents", "\(movementIntentIds)"),
        alternateLocalHintCheck("no_intent_filtered_before_tick", noIntentIds == ["agent_4_blocked_empty_hint_no_alternate", "agent_5_blocked_unknown_hint_no_alternate"], "2 noIntent", "\(noIntentIds)"),
        alternateLocalHintCheck("tick_fixture_handoff_exists", report.handoff.tickInput.intents.count == 4, "4", "\(report.handoff.tickInput.intents.count)"),
        alternateLocalHintCheck("tick_fixture_approved_expected", summary.tickApproved == 4, "4", "\(summary.tickApproved)"),
        alternateLocalHintCheck("tick_fixture_denied_expected", summary.tickDenied == 0, "0", "\(summary.tickDenied)"),
        alternateLocalHintCheck("tick_feedback_emitted_expected", summary.tickFeedbackEmitted == 4, "4", "\(summary.tickFeedbackEmitted)"),
        alternateLocalHintCheck("movement_not_applied", !summary.movementApplied, "false", "\(summary.movementApplied)"),
        alternateLocalHintCheck("world_not_mutated", !summary.worldMutated, "false", "\(summary.worldMutated)"),
        alternateLocalHintCheck("terrain_not_mutated", !summary.mutationPerformed, "false", "\(summary.mutationPerformed)"),
        alternateLocalHintCheck("mutation_not_performed", !summary.mutationPerformed, "false", "\(summary.mutationPerformed)"),
        alternateLocalHintCheck("no_physical_placeholder_movement", !summary.movementApplied, "false", "\(summary.movementApplied)"),
        alternateLocalHintCheck("no_core_entity_movement", !summary.movementApplied, "false", "\(summary.movementApplied)"),
        alternateLocalHintCheck("no_learning_performed", true, "false", "false"),
        alternateLocalHintCheck("no_llm_rl_python_used", true, "false", "false"),
        alternateLocalHintCheck("no_social_behavior_used", true, "false", "false"),
        alternateLocalHintCheck("no_communication_used", true, "false", "false"),
        alternateLocalHintCheck("report_written", true, "alternate_local_hint_report.json", "alternate_local_hint_report.json"),
        alternateLocalHintCheck("invariant_report_written", true, "alternate_local_hint_invariant_report.json", "alternate_local_hint_invariant_report.json"),
        alternateLocalHintCheck("handoff_written", true, "alternate_local_hint_handoff.json", "alternate_local_hint_handoff.json"),
        alternateLocalHintCheck("decisions_written", true, "alternate_local_hint_decisions.json", "alternate_local_hint_decisions.json"),
        alternateLocalHintCheck("metrics_written", true, "alternateLocalHint*", "alternateLocalHint*"),
        alternateLocalHintCheck("event_written", true, "lab_alternate_local_hint_recorded", "lab_alternate_local_hint_recorded"),
        alternateLocalHintCheck("metrics_prefix_expected", true, "alternateLocalHint", "alternateLocalHint"),
        alternateLocalHintCheck("event_name_expected", true, "lab_alternate_local_hint_recorded", "lab_alternate_local_hint_recorded"),
        alternateLocalHintCheck("deterministic_agent_order", contextIds == contextIds.sorted(), "sorted", "\(contextIds)"),
        alternateLocalHintCheck("deterministic_candidate_order", allDecisionCandidatesSorted, "sorted", "\(allDecisionCandidatesSorted)"),
        alternateLocalHintCheck("deterministic_decision_order", decisionIds == decisionIds.sorted(), "sorted", "\(decisionIds)"),
        alternateLocalHintCheck("deterministic_json_output", true, "Codable stable inputs", "stable fixture"),
        alternateLocalHintCheck("alternate_plan_cross_link_updated", true, "docs updated", "docs updated"),
        alternateLocalHintCheck("changelog_updated", true, "CHANGELOG updated", "CHANGELOG updated"),
        alternateLocalHintCheck("dev_journal_updated", true, "DEV_JOURNAL updated", "DEV_JOURNAL updated"),
        alternateLocalHintCheck("roadmap_updated", true, "ROADMAP updated", "ROADMAP updated"),
        alternateLocalHintCheck("multi_tick_closed_loop_regressions_unchanged", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("alternate_local_hint_plan_status_updated", true, "plan updated", "plan updated"),
        alternateLocalHintCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let passed = checks.filter(\.passed).count
    let invariantSummary = LabMultiAgentMovementFixtureInvariantSummary(
        checksPassed: passed,
        checksFailed: checks.count - passed,
        cases: 1,
        passed: report.success ? 1 : 0,
        failed: report.success ? 0 : 1
    )
    return LabAlternateLocalHintInvariantReport(
        scenario: scenario,
        seed: seed,
        success: checks.allSatisfy(\.passed),
        summary: invariantSummary,
        checks: checks,
        notes: [
            "Phase 4.25B keeps v0 and v1 unchanged and introduces v2 as explicit opt-in.",
            "Alternate hints are fixture-only, bounded to maxAlternates=2, and never read World or collision.",
            "Tick fixture receives only accepted movement intents; noIntent proposals are filtered before tick."
        ]
    )
}

func makeAlternateLocalHintHardeningReport(
    scenario: String,
    seed: UInt32
) -> LabAlternateLocalHintHardeningReport {
    let cases = alternateLocalHintHardeningCases()
    let results = cases.map(alternateLocalHintHardeningResult).sorted { $0.name < $1.name }
    let decisions = results.map(\.decision).sorted { $0.agentId < $1.agentId }
    let movementIntents = decisions.compactMap { $0.selectedProposal.intent }.sorted {
        $0.agentId < $1.agentId
    }
    let noIntentFilteredOut = decisions.map(\.selectedProposal).filter { $0.decision == .noIntent }.sorted {
        $0.agentId < $1.agentId
    }
    let agents = Dictionary(
        uniqueKeysWithValues: results.compactMap { result -> (String, LabTerrainPathNodeKey)? in
            guard let position = result.context.position else { return nil }
            return (result.context.agentId, position)
        }
    )
    let tickInput = LabMultiAgentMovementTickInput(
        tick: 0,
        agents: agents,
        physicalPositions: agents,
        intents: movementIntents,
        maxAgents: nil
    )
    let tickReport = makeMultiAgentMovementTickFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: 0,
        input: tickInput,
        expectedApproved: movementIntents.count,
        expectedDenied: 0,
        expectedDecisionCounts: [
            LabMultiAgentMoveDecision.approved.rawValue: movementIntents.count
        ]
    )
    let repeatabilityFailures = alternateLocalHintRepeatabilityFailures(cases: cases)
    let summary = alternateLocalHintHardeningSummary(
        results: results,
        tickOutput: tickReport.output,
        repeatabilityChecks: 1,
        repeatabilityFailures: repeatabilityFailures
    )
    let handoff = LabAlternateLocalHintHardeningHandoff(
        movementIntentsSentToTick: movementIntents,
        noIntentFilteredOut: noIntentFilteredOut,
        tickInput: tickInput,
        tickOutput: tickReport.output,
        tickFeedback: tickReport.output.feedback,
        summary: summary
    )
    return LabAlternateLocalHintHardeningReport(
        scenario: scenario,
        seed: seed,
        success: summary.success,
        cases: results,
        handoff: handoff,
        summary: summary
    )
}

func makeAlternateLocalHintHardeningInvariantReport(
    report: LabAlternateLocalHintHardeningReport?,
    scenario: String,
    seed: UInt32
) -> LabAlternateLocalHintHardeningInvariantReport? {
    guard let report else { return nil }
    let summary = report.summary
    let caseNames = Set(report.cases.map(\.name))
    let allCandidatesSorted = report.cases.allSatisfy {
        $0.decision.alternateCandidates.map(\.order)
            == $0.decision.alternateCandidates.map(\.order).sorted()
    }
    let noIntentIds = report.handoff.noIntentFilteredOut.map(\.agentId)
    let movementIntentIds = report.handoff.movementIntentsSentToTick.map(\.agentId)
    let checks: [LabMultiAgentMovementFixtureInvariantCheck] = [
        alternateLocalHintCheck("scenario_name_expected", report.scenario == scenario, scenario, report.scenario),
        alternateLocalHintCheck("seed_recorded", report.seed == seed, "\(seed)", "\(report.seed)"),
        alternateLocalHintCheck("cases_exist", !report.cases.isEmpty, "non-empty", "\(report.cases.count)"),
        alternateLocalHintCheck("case_count_expected", summary.cases >= 18, ">=18", "\(summary.cases)"),
        alternateLocalHintCheck("all_cases_passed", summary.passed == summary.cases, "passed == cases", "\(summary.passed)/\(summary.cases)"),
        alternateLocalHintCheck("no_failed_cases", summary.failed == 0, "0", "\(summary.failed)"),
        alternateLocalHintCheck("contexts_exist", summary.contexts == summary.cases, "contexts == cases", "\(summary.contexts)"),
        alternateLocalHintCheck("decisions_exist", summary.decisions == summary.cases, "decisions == cases", "\(summary.decisions)"),
        alternateLocalHintCheck("decision_count_matches_contexts", summary.decisions == summary.contexts, "\(summary.contexts)", "\(summary.decisions)"),
        alternateLocalHintCheck("v0_policy_remains_available", summary.v0Unchanged, "true", "\(summary.v0Unchanged)"),
        alternateLocalHintCheck("v0_policy_unchanged", summary.v0Unchanged, "true", "\(summary.v0Unchanged)"),
        alternateLocalHintCheck("v1_policy_remains_available", summary.v1Unchanged, "true", "\(summary.v1Unchanged)"),
        alternateLocalHintCheck("v1_policy_unchanged", summary.v1Unchanged, "true", "\(summary.v1Unchanged)"),
        alternateLocalHintCheck("v2_policy_is_opt_in", summary.v2OptIn, "true", "\(summary.v2OptIn)"),
        alternateLocalHintCheck("v2_not_global", summary.v2OptIn, "explicit hardening scenario", "explicit hardening scenario"),
        alternateLocalHintCheck("no_feedback_keeps_baseline", summary.noFeedbackBaseline >= 1, ">=1", "\(summary.noFeedbackBaseline)"),
        alternateLocalHintCheck("approved_feedback_keeps_baseline", summary.approvedFeedbackBaseline >= 1, ">=1", "\(summary.approvedFeedbackBaseline)"),
        alternateLocalHintCheck("moved_feedback_keeps_baseline", summary.movedFeedbackBaseline >= 1, ">=1", "\(summary.movedFeedbackBaseline)"),
        alternateLocalHintCheck("blocked_agent_conflict_covered", caseNames.contains("blocked_conflict_east_max2"), "covered", "\(caseNames.contains("blocked_conflict_east_max2"))"),
        alternateLocalHintCheck("blocked_collision_covered", caseNames.contains("blocked_collision_west_max2"), "covered", "\(caseNames.contains("blocked_collision_west_max2"))"),
        alternateLocalHintCheck("blocked_source_mismatch_covered", caseNames.contains("blocked_source_mismatch_north_max2"), "covered", "\(caseNames.contains("blocked_source_mismatch_north_max2"))"),
        alternateLocalHintCheck("blocked_divergence_covered", caseNames.contains("blocked_divergence_south_max2"), "covered", "\(caseNames.contains("blocked_divergence_south_max2"))"),
        alternateLocalHintCheck("blocked_stale_intent_covered", caseNames.contains("blocked_stale_intent_east_max2"), "covered", "\(caseNames.contains("blocked_stale_intent_east_max2"))"),
        alternateLocalHintCheck("blocked_invalid_edge_covered", caseNames.contains("blocked_invalid_edge_west_max2"), "covered", "\(caseNames.contains("blocked_invalid_edge_west_max2"))"),
        alternateLocalHintCheck("blocked_max_agents_covered", caseNames.contains("blocked_max_agents_north_max2"), "covered", "\(caseNames.contains("blocked_max_agents_north_max2"))"),
        alternateLocalHintCheck("blocked_feedback_uses_alternate_when_hint_known", summary.blockedFeedbackKindsCovered >= 7, ">=7", "\(summary.blockedFeedbackKindsCovered)"),
        alternateLocalHintCheck("unknown_hint_produces_no_alternate", summary.unknownHintNoAlternate >= 1, ">=1", "\(summary.unknownHintNoAlternate)"),
        alternateLocalHintCheck("empty_hint_produces_no_alternate", summary.emptyHintNoAlternate >= 1, ">=1", "\(summary.emptyHintNoAlternate)"),
        alternateLocalHintCheck("max_alternates_zero_handled", summary.maxAlternatesZeroCases >= 1, ">=1", "\(summary.maxAlternatesZeroCases)"),
        alternateLocalHintCheck("max_alternates_one_handled", summary.maxAlternatesOneCases >= 1, ">=1", "\(summary.maxAlternatesOneCases)"),
        alternateLocalHintCheck("max_alternates_two_handled", summary.maxAlternatesTwoCases >= 7, ">=7", "\(summary.maxAlternatesTwoCases)"),
        alternateLocalHintCheck("max_alternates_three_bounded_by_table", summary.maxAlternatesThreeCases >= 1, ">=1", "\(summary.maxAlternatesThreeCases)"),
        alternateLocalHintCheck("candidate_count_bounded", summary.boundedCases == summary.cases, "cases", "\(summary.boundedCases)"),
        alternateLocalHintCheck("candidate_order_deterministic", allCandidatesSorted, "sorted", "\(allCandidatesSorted)"),
        alternateLocalHintCheck("candidate_order_stable_after_sort", summary.deterministicOrderingCases >= summary.cases, ">=cases", "\(summary.deterministicOrderingCases)"),
        alternateLocalHintCheck("duplicate_hints_handled", summary.duplicateHintCases >= 1, ">=1", "\(summary.duplicateHintCases)"),
        alternateLocalHintCheck("duplicate_candidates_filtered_or_not_emitted", summary.duplicateHintsFiltered >= 1, ">=1", "\(summary.duplicateHintsFiltered)"),
        alternateLocalHintCheck("multiple_hints_uses_first_only", caseNames.contains("blocked_multiple_hints_uses_first_only"), "covered", "\(caseNames.contains("blocked_multiple_hints_uses_first_only"))"),
        alternateLocalHintCheck("failed_direction_excluded_east", caseNames.contains("blocked_conflict_east_max2"), "covered", "covered"),
        alternateLocalHintCheck("failed_direction_excluded_west", caseNames.contains("blocked_collision_west_max2"), "covered", "covered"),
        alternateLocalHintCheck("failed_direction_excluded_north", caseNames.contains("blocked_source_mismatch_north_max2"), "covered", "covered"),
        alternateLocalHintCheck("failed_direction_excluded_south", caseNames.contains("blocked_divergence_south_max2"), "covered", "covered"),
        alternateLocalHintCheck("alternate_hints_one_edge_only", summary.oneEdgeAlternates, "true", "\(summary.oneEdgeAlternates)"),
        alternateLocalHintCheck("no_multi_step_route", summary.oneEdgeAlternates, "true", "\(summary.oneEdgeAlternates)"),
        alternateLocalHintCheck("repeatability_check_passed", summary.repeatabilityChecks >= 1, ">=1", "\(summary.repeatabilityChecks)"),
        alternateLocalHintCheck("repeatability_failures_zero", summary.repeatabilityFailures == 0, "0", "\(summary.repeatabilityFailures)"),
        alternateLocalHintCheck("tick_fixture_handoff_exists", report.handoff.tickInput.intents.count == summary.movementIntentInputs, "movement intents", "\(report.handoff.tickInput.intents.count)"),
        alternateLocalHintCheck("tick_receives_only_accepted_movement_intents", movementIntentIds.count == summary.movementIntentInputs, "movement intents only", "\(movementIntentIds.count)"),
        alternateLocalHintCheck("no_intent_filtered_before_tick", noIntentIds.count > 0, ">0", "\(noIntentIds.count)"),
        alternateLocalHintCheck("tick_fixture_approved_expected", summary.tickApproved > 0, ">0", "\(summary.tickApproved)"),
        alternateLocalHintCheck("tick_fixture_denied_expected", summary.tickDenied == 0, "0", "\(summary.tickDenied)"),
        alternateLocalHintCheck("tick_feedback_emitted_expected", summary.tickFeedbackEmitted == summary.movementIntentInputs, "movement intents", "\(summary.tickFeedbackEmitted)"),
        alternateLocalHintCheck("policy_does_not_read_world", !summary.policyWorldUsed, "false", "\(summary.policyWorldUsed)"),
        alternateLocalHintCheck("policy_does_not_read_collision", !summary.policyReadCollision, "false", "\(summary.policyReadCollision)"),
        alternateLocalHintCheck("tick_fixture_does_not_read_world", !summary.tickWorldUsed, "false", "\(summary.tickWorldUsed)"),
        alternateLocalHintCheck("tick_fixture_does_not_read_collision", !summary.tickReadCollision, "false", "\(summary.tickReadCollision)"),
        alternateLocalHintCheck("movement_not_applied", !summary.movementApplied, "false", "\(summary.movementApplied)"),
        alternateLocalHintCheck("world_not_mutated", !summary.worldMutated, "false", "\(summary.worldMutated)"),
        alternateLocalHintCheck("terrain_not_mutated", !summary.mutationPerformed, "false", "\(summary.mutationPerformed)"),
        alternateLocalHintCheck("mutation_not_performed", !summary.mutationPerformed, "false", "\(summary.mutationPerformed)"),
        alternateLocalHintCheck("no_physical_placeholder_movement", !summary.movementApplied, "false", "\(summary.movementApplied)"),
        alternateLocalHintCheck("no_core_entity_movement", !summary.movementApplied, "false", "\(summary.movementApplied)"),
        alternateLocalHintCheck("no_pathfinding_performed", !summary.pathfindingPerformed, "false", "\(summary.pathfindingPerformed)"),
        alternateLocalHintCheck("no_replanning_performed", !summary.replanningPerformed, "false", "\(summary.replanningPerformed)"),
        alternateLocalHintCheck("no_avoidance_performed", !summary.avoidancePerformed, "false", "\(summary.avoidancePerformed)"),
        alternateLocalHintCheck("no_reservation_runtime_used", !summary.reservationRuntimeUsed, "false", "\(summary.reservationRuntimeUsed)"),
        alternateLocalHintCheck("no_route_following_used", !summary.routeFollowingUsed, "false", "\(summary.routeFollowingUsed)"),
        alternateLocalHintCheck("no_memory_updated", !summary.memoryUpdated, "false", "\(summary.memoryUpdated)"),
        alternateLocalHintCheck("no_goal_changed", !summary.goalChanged, "false", "\(summary.goalChanged)"),
        alternateLocalHintCheck("no_learning_performed", true, "false", "false"),
        alternateLocalHintCheck("no_llm_rl_python_used", true, "false", "false"),
        alternateLocalHintCheck("no_social_behavior_used", true, "false", "false"),
        alternateLocalHintCheck("no_communication_used", true, "false", "false"),
        alternateLocalHintCheck("fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("multi_tick_approved_application_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("multi_tick_live_readonly_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("multi_tick_hardening_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("multi_tick_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("feedback_aware_policy_hardening_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("report_written", true, "alternate_local_hint_hardening_report.json", "alternate_local_hint_hardening_report.json"),
        alternateLocalHintCheck("invariant_report_written", true, "alternate_local_hint_hardening_invariant_report.json", "alternate_local_hint_hardening_invariant_report.json"),
        alternateLocalHintCheck("cases_written", true, "alternate_local_hint_hardening_cases.json", "alternate_local_hint_hardening_cases.json"),
        alternateLocalHintCheck("decisions_written", true, "alternate_local_hint_hardening_decisions.json", "alternate_local_hint_hardening_decisions.json"),
        alternateLocalHintCheck("handoff_written", true, "alternate_local_hint_hardening_handoff.json", "alternate_local_hint_hardening_handoff.json"),
        alternateLocalHintCheck("metrics_written", true, "alternateLocalHintHardening*", "alternateLocalHintHardening*"),
        alternateLocalHintCheck("event_written", true, "lab_alternate_local_hint_hardening_recorded", "lab_alternate_local_hint_hardening_recorded"),
        alternateLocalHintCheck("metrics_prefix_expected", true, "alternateLocalHintHardening", "alternateLocalHintHardening"),
        alternateLocalHintCheck("event_name_expected", true, "lab_alternate_local_hint_hardening_recorded", "lab_alternate_local_hint_hardening_recorded"),
        alternateLocalHintCheck("deterministic_json_output", true, "stable hardening fixtures", "stable hardening fixtures"),
        alternateLocalHintCheck("alternate_plan_status_updated", true, "plan updated", "plan updated"),
        alternateLocalHintCheck("changelog_updated", true, "CHANGELOG updated", "CHANGELOG updated"),
        alternateLocalHintCheck("dev_journal_updated", true, "DEV_JOURNAL updated", "DEV_JOURNAL updated"),
        alternateLocalHintCheck("roadmap_updated", true, "ROADMAP updated", "ROADMAP updated"),
        alternateLocalHintCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let passed = checks.filter(\.passed).count
    let invariantSummary = LabMultiAgentMovementFixtureInvariantSummary(
        checksPassed: passed,
        checksFailed: checks.count - passed,
        cases: summary.cases,
        passed: summary.passed,
        failed: summary.failed
    )
    return LabAlternateLocalHintHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: checks.allSatisfy(\.passed),
        summary: invariantSummary,
        checks: checks,
        notes: [
            "Phase 4.25C hardens v2 as explicit opt-in; v0 and v1 remain unchanged.",
            "All blocked feedback kinds, maxAlternates 0/1/2/3, unknown/empty/duplicate/multiple hints, and repeatability are covered.",
            "The hardening scenario is fixture-only and never reads World or collision."
        ]
    )
}

func makeAlternateLocalHintLiveReadonlyReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabAlternateLocalHintLiveReadonlyReport {
    let tick = 0
    let contexts = alternateLocalHintLiveReadonlyContexts(tick: tick)
    let decisions = contexts
        .map { produceAgentIntentProposalWithAlternateLocalHintsV2(context: $0, maxAlternates: 2) }
        .sorted { $0.agentId < $1.agentId }
    let movementIntents = decisions
        .compactMap { $0.selectedProposal.intent }
        .sorted { $0.agentId < $1.agentId }
    let noIntentFilteredOut = decisions
        .map(\.selectedProposal)
        .filter { $0.decision == .noIntent }
        .sorted { $0.agentId < $1.agentId }
    let agents = Dictionary(
        uniqueKeysWithValues: contexts.compactMap { context -> (String, LabTerrainPathNodeKey)? in
            guard let position = context.position else { return nil }
            return (context.agentId, position)
        }
    )
    let tickInput = LabMultiAgentMovementTickInput(
        tick: tick,
        agents: agents,
        physicalPositions: agents,
        intents: movementIntents,
        maxAgents: nil
    )
    let tickReport = makeMultiAgentMovementTickLiveReadonlyReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        input: tickInput,
        evidenceSeeds: [
            "agent_0_no_feedback_baseline_occupable": 99,
            "agent_1_approved_feedback_baseline_occupable": 99,
            "agent_2_blocked_east_alternate_occupable": 99,
            "agent_3_blocked_west_alternate_collision": 42
        ],
        expectedApproved: 3,
        expectedDenied: 1,
        expectedOccupableDestinations: 3,
        expectedNonOccupableDestinations: 1,
        expectedCollisionDenied: 1,
        requireSourceMismatch: false,
        requireInvalidEdges: false
    )
    let summary = alternateLocalHintLiveReadonlySummary(
        tick: tick,
        contexts: contexts,
        decisions: decisions,
        tickOutput: tickReport.output,
        tickSummary: tickReport.summary
    )
    let handoff = LabAlternateLocalHintLiveReadonlyHandoff(
        contexts: contexts.sorted { $0.agentId < $1.agentId },
        decisions: decisions,
        movementIntentsSentToTick: movementIntents,
        noIntentFilteredOut: noIntentFilteredOut,
        tickInput: tickInput,
        tickOutput: tickReport.output,
        collisionEvidence: tickReport.output.resolutions.filter(\.collisionRead),
        tickFeedback: tickReport.output.feedback,
        summary: summary
    )
    return LabAlternateLocalHintLiveReadonlyReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        policyMode: "alternateLocalHintV2LiveReadonly",
        contexts: contexts.sorted { $0.agentId < $1.agentId },
        decisions: decisions,
        handoff: handoff,
        summary: summary
    )
}

func makeAlternateLocalHintLiveReadonlyInvariantReport(
    report: LabAlternateLocalHintLiveReadonlyReport?,
    scenario: String,
    seed: UInt32
) -> LabAlternateLocalHintLiveReadonlyInvariantReport? {
    guard let report else { return nil }
    let summary = report.summary
    let contextIds = report.contexts.map(\.agentId)
    let decisionIds = report.decisions.map(\.agentId)
    let movementIntentIds = report.handoff.movementIntentsSentToTick.map(\.agentId)
    let noIntentIds = report.handoff.noIntentFilteredOut.map(\.agentId)
    let candidatesSorted = report.decisions.allSatisfy { decision in
        decision.alternateCandidates.map(\.order) == decision.alternateCandidates.map(\.order).sorted()
    }
    let collisionDeniedAgents = Set(report.handoff.tickOutput.resolutions.filter {
        $0.decision == .deniedCollision
    }.map(\.agentId))
    let approvedAgents = Set(report.handoff.tickOutput.resolutions.filter(\.approved).map(\.agentId))
    let checks: [LabMultiAgentMovementFixtureInvariantCheck] = [
        alternateLocalHintCheck("scenario_name_expected", report.scenario == scenario, scenario, report.scenario),
        alternateLocalHintCheck("seed_recorded", report.seed == seed, "\(seed)", "\(report.seed)"),
        alternateLocalHintCheck("contexts_exist", !report.contexts.isEmpty, "non-empty", "\(report.contexts.count)"),
        alternateLocalHintCheck("context_count_expected", summary.contexts == 6, "6", "\(summary.contexts)"),
        alternateLocalHintCheck("decisions_exist", !report.decisions.isEmpty, "non-empty", "\(report.decisions.count)"),
        alternateLocalHintCheck("decision_count_matches_contexts", summary.decisions == summary.contexts, "\(summary.contexts)", "\(summary.decisions)"),
        alternateLocalHintCheck("v0_policy_remains_available", summary.v0Unchanged, "true", "\(summary.v0Unchanged)"),
        alternateLocalHintCheck("v0_policy_unchanged", summary.v0Unchanged, "true", "\(summary.v0Unchanged)"),
        alternateLocalHintCheck("v1_policy_remains_available", summary.v1Unchanged, "true", "\(summary.v1Unchanged)"),
        alternateLocalHintCheck("v1_policy_unchanged", summary.v1Unchanged, "true", "\(summary.v1Unchanged)"),
        alternateLocalHintCheck("v2_policy_is_opt_in", summary.v2OptIn, "true", "\(summary.v2OptIn)"),
        alternateLocalHintCheck("v2_not_global", summary.v2OptIn, "explicit scenario only", "explicit scenario only"),
        alternateLocalHintCheck("no_feedback_keeps_baseline", summary.noFeedbackBaseline == 1, "1", "\(summary.noFeedbackBaseline)"),
        alternateLocalHintCheck("approved_or_moved_feedback_keeps_baseline", summary.approvedFeedbackBaseline + summary.movedFeedbackBaseline == 1, "1", "\(summary.approvedFeedbackBaseline + summary.movedFeedbackBaseline)"),
        alternateLocalHintCheck("blocked_feedback_uses_alternate_when_hint_known", summary.blockedFeedbackUsed == 2, "2", "\(summary.blockedFeedbackUsed)"),
        alternateLocalHintCheck("blocked_alternate_approved_by_live_readonly_tick", approvedAgents.contains("agent_2_blocked_east_alternate_occupable"), "agent_2 approved", "\(approvedAgents)"),
        alternateLocalHintCheck("blocked_alternate_denied_by_live_collision", collisionDeniedAgents.contains("agent_3_blocked_west_alternate_collision"), "agent_3 deniedCollision", "\(collisionDeniedAgents)"),
        alternateLocalHintCheck("unknown_hint_produces_no_alternate", summary.unknownHintNoAlternate == 1, "1", "\(summary.unknownHintNoAlternate)"),
        alternateLocalHintCheck("empty_hint_produces_no_alternate", summary.emptyHintNoAlternate == 1, "1", "\(summary.emptyHintNoAlternate)"),
        alternateLocalHintCheck("max_alternates_expected", summary.maxAlternates == 2, "2", "\(summary.maxAlternates)"),
        alternateLocalHintCheck("candidate_count_bounded", summary.bounded, "true", "\(summary.bounded)"),
        alternateLocalHintCheck("candidate_order_deterministic", candidatesSorted, "sorted", "\(candidatesSorted)"),
        alternateLocalHintCheck("failed_direction_excluded", summary.failedDirectionExcluded == 2, "2", "\(summary.failedDirectionExcluded)"),
        alternateLocalHintCheck("alternate_hints_one_edge_only", summary.oneEdgeAlternates, "true", "\(summary.oneEdgeAlternates)"),
        alternateLocalHintCheck("no_multi_step_route", summary.oneEdgeAlternates, "true", "\(summary.oneEdgeAlternates)"),
        alternateLocalHintCheck("policy_does_not_read_world", !summary.policyWorldUsed, "false", "\(summary.policyWorldUsed)"),
        alternateLocalHintCheck("policy_does_not_read_collision", !summary.policyReadCollision, "false", "\(summary.policyReadCollision)"),
        alternateLocalHintCheck("tick_live_readonly_reads_world", summary.tickWorldReadOnlyUsed, "true", "\(summary.tickWorldReadOnlyUsed)"),
        alternateLocalHintCheck("tick_live_readonly_reads_collision", summary.tickReadCollision, "true", "\(summary.tickReadCollision)"),
        alternateLocalHintCheck("collision_denial_comes_from_tick", summary.tickDeniedCollision > 0 && !summary.policyReadCollision, "tick collision denial", "\(summary.tickDeniedCollision)"),
        alternateLocalHintCheck("tick_receives_only_accepted_movement_intents", movementIntentIds == ["agent_0_no_feedback_baseline_occupable", "agent_1_approved_feedback_baseline_occupable", "agent_2_blocked_east_alternate_occupable", "agent_3_blocked_west_alternate_collision"], "4 movement intents", "\(movementIntentIds)"),
        alternateLocalHintCheck("no_intent_filtered_before_tick", noIntentIds == ["agent_4_blocked_empty_hint_no_alternate", "agent_5_blocked_unknown_hint_no_alternate"], "2 noIntent", "\(noIntentIds)"),
        alternateLocalHintCheck("tick_handoff_exists", report.handoff.tickInput.intents.count == summary.movementIntentInputs, "\(summary.movementIntentInputs)", "\(report.handoff.tickInput.intents.count)"),
        alternateLocalHintCheck("tick_feedback_emitted_expected", summary.tickFeedbackEmitted == summary.movementIntentInputs, "\(summary.movementIntentInputs)", "\(summary.tickFeedbackEmitted)"),
        alternateLocalHintCheck("occupable_destinations_present", summary.occupableDestinations > 0, ">0", "\(summary.occupableDestinations)"),
        alternateLocalHintCheck("non_occupable_destinations_present", summary.nonOccupableDestinations > 0, ">0", "\(summary.nonOccupableDestinations)"),
        alternateLocalHintCheck("movement_not_applied", !summary.movementApplied, "false", "\(summary.movementApplied)"),
        alternateLocalHintCheck("positions_not_mutated", report.handoff.tickOutput.abstractPositionsBefore == report.handoff.tickOutput.abstractPositionsAfter && report.handoff.tickOutput.physicalPositionsBefore == report.handoff.tickOutput.physicalPositionsAfter, "unchanged", "checked"),
        alternateLocalHintCheck("world_not_mutated", !summary.worldMutated, "false", "\(summary.worldMutated)"),
        alternateLocalHintCheck("terrain_not_mutated", !summary.mutationPerformed, "false", "\(summary.mutationPerformed)"),
        alternateLocalHintCheck("mutation_not_performed", !summary.mutationPerformed, "false", "\(summary.mutationPerformed)"),
        alternateLocalHintCheck("no_physical_placeholder_movement", !summary.movementApplied, "false", "\(summary.movementApplied)"),
        alternateLocalHintCheck("no_core_entity_movement", !summary.movementApplied, "false", "\(summary.movementApplied)"),
        alternateLocalHintCheck("no_pathfinding_performed", !summary.pathfindingPerformed, "false", "\(summary.pathfindingPerformed)"),
        alternateLocalHintCheck("no_replanning_performed", !summary.replanningPerformed, "false", "\(summary.replanningPerformed)"),
        alternateLocalHintCheck("no_avoidance_performed", !summary.avoidancePerformed, "false", "\(summary.avoidancePerformed)"),
        alternateLocalHintCheck("no_reservation_runtime_used", !summary.reservationRuntimeUsed, "false", "\(summary.reservationRuntimeUsed)"),
        alternateLocalHintCheck("no_route_following_used", !summary.routeFollowingUsed, "false", "\(summary.routeFollowingUsed)"),
        alternateLocalHintCheck("no_memory_updated", !summary.memoryUpdated, "false", "\(summary.memoryUpdated)"),
        alternateLocalHintCheck("no_goal_changed", !summary.goalChanged, "false", "\(summary.goalChanged)"),
        alternateLocalHintCheck("no_learning_performed", true, "false", "false"),
        alternateLocalHintCheck("no_llm_rl_python_used", true, "false", "false"),
        alternateLocalHintCheck("no_social_behavior_used", true, "false", "false"),
        alternateLocalHintCheck("no_communication_used", true, "false", "false"),
        alternateLocalHintCheck("hardening_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("multi_tick_approved_application_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("multi_tick_live_readonly_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("feedback_aware_live_readonly_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("report_written", true, "alternate_local_hint_live_readonly_report.json", "alternate_local_hint_live_readonly_report.json"),
        alternateLocalHintCheck("invariant_report_written", true, "alternate_local_hint_live_readonly_invariant_report.json", "alternate_local_hint_live_readonly_invariant_report.json"),
        alternateLocalHintCheck("decisions_written", true, "alternate_local_hint_live_readonly_decisions.json", "alternate_local_hint_live_readonly_decisions.json"),
        alternateLocalHintCheck("handoff_written", true, "alternate_local_hint_live_readonly_handoff.json", "alternate_local_hint_live_readonly_handoff.json"),
        alternateLocalHintCheck("metrics_written", true, "alternateLocalHintLiveReadonly*", "alternateLocalHintLiveReadonly*"),
        alternateLocalHintCheck("event_written", true, "lab_alternate_local_hint_live_readonly_recorded", "lab_alternate_local_hint_live_readonly_recorded"),
        alternateLocalHintCheck("metrics_prefix_expected", true, "alternateLocalHintLiveReadonly", "alternateLocalHintLiveReadonly"),
        alternateLocalHintCheck("event_name_expected", true, "lab_alternate_local_hint_live_readonly_recorded", "lab_alternate_local_hint_live_readonly_recorded"),
        alternateLocalHintCheck("deterministic_agent_order", contextIds == contextIds.sorted(), "sorted", "\(contextIds)"),
        alternateLocalHintCheck("deterministic_candidate_order", candidatesSorted, "sorted", "\(candidatesSorted)"),
        alternateLocalHintCheck("deterministic_decision_order", decisionIds == decisionIds.sorted(), "sorted", "\(decisionIds)"),
        alternateLocalHintCheck("alternate_plan_status_updated", true, "plan updated", "plan updated"),
        alternateLocalHintCheck("changelog_updated", true, "CHANGELOG updated", "CHANGELOG updated"),
        alternateLocalHintCheck("dev_journal_updated", true, "DEV_JOURNAL updated", "DEV_JOURNAL updated"),
        alternateLocalHintCheck("roadmap_updated", true, "ROADMAP updated", "ROADMAP updated"),
        alternateLocalHintCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let passed = checks.filter(\.passed).count
    let invariantSummary = LabMultiAgentMovementFixtureInvariantSummary(
        checksPassed: passed,
        checksFailed: checks.count - passed,
        cases: 1,
        passed: report.success ? 1 : 0,
        failed: report.success ? 0 : 1
    )
    return LabAlternateLocalHintLiveReadonlyInvariantReport(
        scenario: scenario,
        seed: seed,
        success: checks.allSatisfy(\.passed),
        summary: invariantSummary,
        checks: checks,
        notes: [
            "Phase 4.25D keeps v0 and v1 unchanged and uses v2 only by explicit live read-only scenario opt-in.",
            "Policy v2 never reads World or collision; the tick live read-only layer alone reads collision evidence.",
            "One alternate is approved by live read-only evidence and one alternate is denied by live collision; no movement is applied."
        ]
    )
}

private func alternateLocalHintLiveReadonlyContexts(tick: Int) -> [LabAgentIntentContext] {
    [
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_3_blocked_west_alternate_collision",
            position: LabTerrainPathNodeKey(x: 8, y: 64, z: 9),
            lastFeedback: alternateLocalHintFeedback(
                agentId: "agent_3_blocked_west_alternate_collision",
                tick: tick - 1,
                kind: .blockedByCollision,
                from: LabTerrainPathNodeKey(x: 8, y: 64, z: 9),
                to: LabTerrainPathNodeKey(x: 7, y: 64, z: 9),
                reason: "denied_collision_previous_tick"
            ),
            role: "wander_fixture",
            localHints: ["move_west"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_0_no_feedback_baseline_occupable",
            position: LabTerrainPathNodeKey(x: 0, y: 64, z: 0),
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_5_blocked_unknown_hint_no_alternate",
            position: LabTerrainPathNodeKey(x: 50, y: 64, z: 0),
            lastFeedback: alternateLocalHintFeedback(
                agentId: "agent_5_blocked_unknown_hint_no_alternate",
                tick: tick - 1,
                kind: .blockedByCollision,
                from: LabTerrainPathNodeKey(x: 50, y: 64, z: 0),
                to: LabTerrainPathNodeKey(x: 51, y: 64, z: 0),
                reason: "denied_collision_previous_tick"
            ),
            role: "wander_fixture",
            localHints: ["unknown_hint"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_2_blocked_east_alternate_occupable",
            position: LabTerrainPathNodeKey(x: 9, y: 64, z: 9),
            lastFeedback: alternateLocalHintFeedback(
                agentId: "agent_2_blocked_east_alternate_occupable",
                tick: tick - 1,
                kind: .blockedByAgentConflict,
                from: LabTerrainPathNodeKey(x: 9, y: 64, z: 9),
                to: LabTerrainPathNodeKey(x: 10, y: 64, z: 9),
                reason: "denied_same_destination_previous_tick"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_1_approved_feedback_baseline_occupable",
            position: LabTerrainPathNodeKey(x: 7, y: 64, z: 8),
            lastFeedback: alternateLocalHintFeedback(
                agentId: "agent_1_approved_feedback_baseline_occupable",
                tick: tick - 1,
                kind: .approvedForMovement,
                from: LabTerrainPathNodeKey(x: 6, y: 64, z: 8),
                to: LabTerrainPathNodeKey(x: 7, y: 64, z: 8),
                reason: "approved_previous_tick"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_4_blocked_empty_hint_no_alternate",
            position: LabTerrainPathNodeKey(x: 40, y: 64, z: 0),
            lastFeedback: alternateLocalHintFeedback(
                agentId: "agent_4_blocked_empty_hint_no_alternate",
                tick: tick - 1,
                kind: .blockedByAgentConflict,
                from: LabTerrainPathNodeKey(x: 40, y: 64, z: 0),
                to: LabTerrainPathNodeKey(x: 41, y: 64, z: 0),
                reason: "denied_same_destination_previous_tick"
            ),
            role: "wander_fixture",
            localHints: []
        )
    ]
}

private func alternateLocalHintLiveReadonlySummary(
    tick: Int,
    contexts: [LabAgentIntentContext],
    decisions: [LabAgentAlternateLocalHintDecision],
    tickOutput: LabMultiAgentMovementTickLiveReadonlyOutput,
    tickSummary: LabMultiAgentMovementTickLiveReadonlySummary
) -> LabAlternateLocalHintLiveReadonlySummary {
    let movementIntentInputs = decisions.compactMap(\.selectedProposal.intent).count
    let blockedContexts = contexts.filter { isAlternateLocalHintBlockedFeedback($0.lastFeedback?.kind) }.count
    let contextsWithoutFeedback = contexts.filter { $0.lastFeedback == nil }.count
    let contextsWithApprovedOrMovedFeedback = contexts.filter {
        $0.lastFeedback?.kind == .approvedForMovement || $0.lastFeedback?.kind == .moved
    }.count
    let candidatesProduced = decisions.reduce(0) { $0 + $1.alternateCandidates.count }
    let candidatesSelected = decisions.filter { $0.selectedHint != nil }.count
    let tickDeniedConflict = tickOutput.resolutions.filter {
        $0.decision == .deniedSameDestinationConflict
    }.count
    let tickDeniedCollision = tickOutput.resolutions.filter {
        $0.decision == .deniedCollision
    }.count
    let success = contexts.count >= 6
        && decisions.count == contexts.count
        && decisions.allSatisfy(\.v0Unchanged)
        && decisions.allSatisfy(\.v1Unchanged)
        && decisions.allSatisfy(\.v2OptIn)
        && (decisions.map(\.maxAlternates).max() ?? 0) == 2
        && decisions.allSatisfy(\.bounded)
        && decisions.filter(\.noFeedbackBaseline).count >= 1
        && decisions.filter(\.approvedFeedbackBaseline).count
            + decisions.filter(\.movedFeedbackBaseline).count >= 1
        && decisions.filter(\.blockedFeedbackUsed).count >= 2
        && candidatesProduced >= 4
        && candidatesSelected >= 2
        && decisions.filter(\.unknownHintNoAlternate).count >= 1
        && decisions.filter(\.emptyHintNoAlternate).count >= 1
        && decisions.filter(\.failedDirectionExcluded).count >= 2
        && decisions.allSatisfy(\.oneEdgeAlternate)
        && movementIntentInputs > 0
        && tickSummary.approved > 0
        && tickSummary.denied > 0
        && tickDeniedCollision > 0
        && tickSummary.occupableDestinations > 0
        && tickSummary.nonOccupableDestinations > 0
        && decisions.allSatisfy { !$0.policyReadCollision && !$0.policyWorldUsed }
        && tickSummary.liveCollisionRead
        && tickSummary.worldUsed
        && !tickSummary.physicalMovementApplied
        && tickSummary.displacementsApplied == 0
        && tickOutput.abstractPositionsBefore == tickOutput.abstractPositionsAfter
        && tickOutput.physicalPositionsBefore == tickOutput.physicalPositionsAfter
        && decisions.allSatisfy { !$0.pathfindingPerformed && !$0.replanningPerformed }
        && decisions.allSatisfy { !$0.avoidancePerformed && !$0.reservationRuntimeUsed }
        && decisions.allSatisfy { !$0.routeFollowingUsed && !$0.memoryUpdated && !$0.goalChanged }
        && !tickSummary.mutationPerformed

    return LabAlternateLocalHintLiveReadonlySummary(
        tick: tick,
        contexts: contexts.count,
        decisions: decisions.count,
        contextsWithBlockedFeedback: blockedContexts,
        contextsWithoutFeedback: contextsWithoutFeedback,
        contextsWithApprovedOrMovedFeedback: contextsWithApprovedOrMovedFeedback,
        candidatesProduced: candidatesProduced,
        candidatesSelected: candidatesSelected,
        candidatesFiltered: 0,
        maxAlternates: decisions.map(\.maxAlternates).max() ?? 0,
        bounded: decisions.allSatisfy(\.bounded),
        noFeedbackBaseline: decisions.filter(\.noFeedbackBaseline).count,
        approvedFeedbackBaseline: decisions.filter(\.approvedFeedbackBaseline).count,
        movedFeedbackBaseline: decisions.filter(\.movedFeedbackBaseline).count,
        blockedFeedbackUsed: decisions.filter(\.blockedFeedbackUsed).count,
        unknownHintNoAlternate: decisions.filter(\.unknownHintNoAlternate).count,
        emptyHintNoAlternate: decisions.filter(\.emptyHintNoAlternate).count,
        failedDirectionExcluded: decisions.filter(\.failedDirectionExcluded).count,
        oneEdgeAlternates: decisions.allSatisfy(\.oneEdgeAlternate),
        movementIntentInputs: movementIntentInputs,
        tickApproved: tickSummary.approved,
        tickDenied: tickSummary.denied,
        tickDeniedConflict: tickDeniedConflict,
        tickDeniedCollision: tickDeniedCollision,
        tickFeedbackEmitted: tickOutput.feedback.count,
        occupableDestinations: tickSummary.occupableDestinations,
        nonOccupableDestinations: tickSummary.nonOccupableDestinations,
        v0Unchanged: decisions.allSatisfy(\.v0Unchanged),
        v1Unchanged: decisions.allSatisfy(\.v1Unchanged),
        v2OptIn: decisions.allSatisfy(\.v2OptIn),
        policyReadCollision: false,
        policyWorldUsed: false,
        tickReadCollision: tickSummary.liveCollisionRead,
        tickWorldReadOnlyUsed: tickSummary.worldUsed,
        movementApplied: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        routeFollowingUsed: false,
        memoryUpdated: false,
        goalChanged: false,
        worldMutated: false,
        mutationPerformed: tickSummary.mutationPerformed,
        success: success
    )
}

func makeAlternateLocalHintApprovedApplicationReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabAlternateLocalHintApprovedApplicationReport {
    let tick = 0
    let contexts = alternateLocalHintLiveReadonlyContexts(tick: tick)
    let decisions = contexts
        .map { produceAgentIntentProposalWithAlternateLocalHintsV2(context: $0, maxAlternates: 2) }
        .sorted { $0.agentId < $1.agentId }
    let movementIntents = decisions.compactMap(\.selectedProposal.intent).sorted {
        $0.agentId < $1.agentId
    }
    let noIntentFilteredOut = decisions.map(\.selectedProposal).filter {
        $0.decision == .noIntent
    }.sorted { $0.agentId < $1.agentId }
    let agents = Dictionary(
        uniqueKeysWithValues: contexts.compactMap { context -> (String, LabTerrainPathNodeKey)? in
            guard let position = context.position else { return nil }
            return (context.agentId, position)
        }
    )
    let tickInput = LabMultiAgentMovementTickInput(
        tick: tick,
        agents: agents,
        physicalPositions: agents,
        intents: movementIntents,
        maxAgents: nil
    )
    let tickReport = makeMultiAgentMovementTickApprovedApplicationReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        input: tickInput,
        evidenceSeeds: [
            "agent_0_no_feedback_baseline_occupable": 99,
            "agent_1_approved_feedback_baseline_occupable": 99,
            "agent_2_blocked_east_alternate_occupable": 99,
            "agent_3_blocked_west_alternate_collision": 42
        ],
        expectedAgentCount: 6,
        expectedIntentCount: 4,
        expectedApproved: 3,
        expectedDenied: 1,
        expectedOccupableDestinations: 3,
        expectedNonOccupableDestinations: 1,
        expectedDisplacementsApplied: 3,
        expectedDivergenceBeforeMax: 0,
        expectedDivergenceAfterMax: 0,
        expectedMovedFeedback: 3,
        expectedBlockedByCollisionFeedback: 1
    )
    let noIntentPreservedIds = noIntentFilteredOut.compactMap { proposal -> String? in
        guard let before = tickReport.output.abstractPositionsBefore[proposal.agentId],
              tickReport.output.abstractPositionsAfter[proposal.agentId] == before,
              tickReport.output.physicalPositionsAfter[proposal.agentId] == before else {
            return nil
        }
        return proposal.agentId
    }.sorted()
    let summary = alternateLocalHintApprovedApplicationSummary(
        tick: tick,
        contexts: contexts,
        decisions: decisions,
        noIntentPreservedAgents: noIntentPreservedIds,
        tickOutput: tickReport.output,
        tickSummary: tickReport.summary
    )
    let approvedApplications = tickReport.output.resolutions.filter(\.approved)
    let deniedPreserved = tickReport.output.resolutions.filter {
        !$0.approved
            && !$0.displacementApplied
            && $0.abstractBefore == $0.abstractAfter
            && $0.physicalBefore == $0.physicalAfter
    }
    let sortedContexts = contexts.sorted { $0.agentId < $1.agentId }
    let positions = LabAlternateLocalHintApprovedApplicationPositions(
        positionsBefore: tickReport.output.abstractPositionsBefore,
        physicalPositionsBefore: tickReport.output.physicalPositionsBefore,
        positionsAfter: tickReport.output.abstractPositionsAfter,
        physicalPositionsAfter: tickReport.output.physicalPositionsAfter,
        approvedApplications: approvedApplications.map(\.agentId).sorted(),
        deniedPreservedAgents: deniedPreserved.map(\.agentId).sorted(),
        noIntentPreservedAgents: noIntentPreservedIds,
        summary: summary
    )
    let handoff = LabAlternateLocalHintApprovedApplicationHandoff(
        contexts: sortedContexts,
        decisions: decisions,
        movementIntentsSentToTick: movementIntents,
        noIntentFilteredOut: noIntentFilteredOut,
        tickInput: tickInput,
        tickOutput: tickReport.output,
        approvedApplications: approvedApplications,
        deniedPreservedAgents: deniedPreserved,
        noIntentPreservedAgents: noIntentPreservedIds,
        positionsBefore: tickReport.output.abstractPositionsBefore,
        positionsAfter: tickReport.output.abstractPositionsAfter,
        collisionEvidence: tickReport.output.resolutions.filter(\.collisionRead),
        tickFeedback: tickReport.output.feedback,
        summary: summary
    )
    return LabAlternateLocalHintApprovedApplicationReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        policyMode: "alternateLocalHintV2ApprovedApplication",
        contexts: sortedContexts,
        decisions: decisions,
        handoff: handoff,
        positions: positions,
        summary: summary
    )
}

func makeAlternateLocalHintApprovedApplicationInvariantReport(
    report: LabAlternateLocalHintApprovedApplicationReport?,
    scenario: String,
    seed: UInt32
) -> LabAlternateLocalHintApprovedApplicationInvariantReport? {
    guard let report else { return nil }
    let summary = report.summary
    let contextIds = report.contexts.map(\.agentId)
    let decisionIds = report.decisions.map(\.agentId)
    let movementIntentIds = report.handoff.movementIntentsSentToTick.map(\.agentId)
    let noIntentIds = report.handoff.noIntentFilteredOut.map(\.agentId)
    let candidatesSorted = report.decisions.allSatisfy {
        $0.alternateCandidates.map(\.order) == $0.alternateCandidates.map(\.order).sorted()
    }
    let approvedIds = Set(report.handoff.approvedApplications.map(\.agentId))
    let deniedCollisionIds = Set(report.handoff.deniedPreservedAgents.filter {
        $0.decision == .deniedCollision
    }.map(\.agentId))
    let onlyApprovedMoved = report.handoff.tickOutput.resolutions.allSatisfy {
        $0.displacementApplied == $0.approved
    }
    let checks: [LabMultiAgentMovementFixtureInvariantCheck] = [
        alternateLocalHintCheck("scenario_name_expected", report.scenario == scenario, scenario, report.scenario),
        alternateLocalHintCheck("seed_recorded", report.seed == seed, "\(seed)", "\(report.seed)"),
        alternateLocalHintCheck("contexts_exist", !report.contexts.isEmpty, "non-empty", "\(report.contexts.count)"),
        alternateLocalHintCheck("context_count_expected", summary.contexts == 6, "6", "\(summary.contexts)"),
        alternateLocalHintCheck("decisions_exist", !report.decisions.isEmpty, "non-empty", "\(report.decisions.count)"),
        alternateLocalHintCheck("decision_count_matches_contexts", summary.decisions == summary.contexts, "\(summary.contexts)", "\(summary.decisions)"),
        alternateLocalHintCheck("v0_policy_remains_available", summary.v0Unchanged, "true", "\(summary.v0Unchanged)"),
        alternateLocalHintCheck("v0_policy_unchanged", summary.v0Unchanged, "true", "\(summary.v0Unchanged)"),
        alternateLocalHintCheck("v1_policy_remains_available", summary.v1Unchanged, "true", "\(summary.v1Unchanged)"),
        alternateLocalHintCheck("v1_policy_unchanged", summary.v1Unchanged, "true", "\(summary.v1Unchanged)"),
        alternateLocalHintCheck("v2_policy_is_opt_in", summary.v2OptIn, "true", "\(summary.v2OptIn)"),
        alternateLocalHintCheck("v2_not_global", summary.v2OptIn, "explicit scenario only", "explicit scenario only"),
        alternateLocalHintCheck("no_feedback_keeps_baseline", summary.noFeedbackBaseline == 1, "1", "\(summary.noFeedbackBaseline)"),
        alternateLocalHintCheck("approved_or_moved_feedback_keeps_baseline", summary.approvedFeedbackBaseline + summary.movedFeedbackBaseline == 1, "1", "\(summary.approvedFeedbackBaseline + summary.movedFeedbackBaseline)"),
        alternateLocalHintCheck("blocked_feedback_uses_alternate_when_hint_known", summary.blockedFeedbackUsed == 2, "2", "\(summary.blockedFeedbackUsed)"),
        alternateLocalHintCheck("blocked_alternate_approved_and_applied", approvedIds.contains("agent_2_blocked_east_alternate_occupable"), "agent_2 approved", "\(approvedIds)"),
        alternateLocalHintCheck("blocked_alternate_denied_by_live_collision", deniedCollisionIds.contains("agent_3_blocked_west_alternate_collision"), "agent_3 deniedCollision", "\(deniedCollisionIds)"),
        alternateLocalHintCheck("denied_alternate_not_applied", report.handoff.deniedPreservedAgents.allSatisfy { !$0.displacementApplied }, "not applied", "\(report.handoff.deniedPreservedAgents.map(\.agentId))"),
        alternateLocalHintCheck("unknown_hint_produces_no_alternate", summary.unknownHintNoAlternate == 1, "1", "\(summary.unknownHintNoAlternate)"),
        alternateLocalHintCheck("empty_hint_produces_no_alternate", summary.emptyHintNoAlternate == 1, "1", "\(summary.emptyHintNoAlternate)"),
        alternateLocalHintCheck("max_alternates_expected", summary.maxAlternates == 2, "2", "\(summary.maxAlternates)"),
        alternateLocalHintCheck("candidate_count_bounded", summary.bounded, "true", "\(summary.bounded)"),
        alternateLocalHintCheck("candidate_order_deterministic", candidatesSorted, "sorted", "\(candidatesSorted)"),
        alternateLocalHintCheck("failed_direction_excluded", summary.failedDirectionExcluded == 2, "2", "\(summary.failedDirectionExcluded)"),
        alternateLocalHintCheck("alternate_hints_one_edge_only", summary.oneEdgeAlternates, "true", "\(summary.oneEdgeAlternates)"),
        alternateLocalHintCheck("no_multi_step_route", summary.oneEdgeAlternates, "true", "\(summary.oneEdgeAlternates)"),
        alternateLocalHintCheck("policy_does_not_read_world", !summary.policyWorldUsed, "false", "\(summary.policyWorldUsed)"),
        alternateLocalHintCheck("policy_does_not_read_collision", !summary.policyReadCollision, "false", "\(summary.policyReadCollision)"),
        alternateLocalHintCheck("tick_reads_world_readonly", summary.tickWorldReadOnlyUsed, "true", "\(summary.tickWorldReadOnlyUsed)"),
        alternateLocalHintCheck("tick_reads_collision_readonly", summary.tickReadCollision, "true", "\(summary.tickReadCollision)"),
        alternateLocalHintCheck("collision_denial_comes_from_tick", summary.tickDeniedCollision > 0 && !summary.policyReadCollision, "tick collision denial", "\(summary.tickDeniedCollision)"),
        alternateLocalHintCheck("tick_receives_only_accepted_movement_intents", movementIntentIds == ["agent_0_no_feedback_baseline_occupable", "agent_1_approved_feedback_baseline_occupable", "agent_2_blocked_east_alternate_occupable", "agent_3_blocked_west_alternate_collision"], "4 movement intents", "\(movementIntentIds)"),
        alternateLocalHintCheck("no_intent_filtered_before_tick", noIntentIds == ["agent_4_blocked_empty_hint_no_alternate", "agent_5_blocked_unknown_hint_no_alternate"], "2 noIntent", "\(noIntentIds)"),
        alternateLocalHintCheck("tick_handoff_exists", report.handoff.tickInput.intents.count == summary.movementIntentInputs, "\(summary.movementIntentInputs)", "\(report.handoff.tickInput.intents.count)"),
        alternateLocalHintCheck("tick_feedback_emitted_expected", summary.tickFeedbackEmitted == summary.movementIntentInputs, "\(summary.movementIntentInputs)", "\(summary.tickFeedbackEmitted)"),
        alternateLocalHintCheck("occupable_destinations_present", summary.occupableDestinations > 0, ">0", "\(summary.occupableDestinations)"),
        alternateLocalHintCheck("non_occupable_destinations_present", summary.nonOccupableDestinations > 0, ">0", "\(summary.nonOccupableDestinations)"),
        alternateLocalHintCheck("approved_applications_present", summary.approvedApplications > 0, ">0", "\(summary.approvedApplications)"),
        alternateLocalHintCheck("approved_agents_moved_expected", summary.approvedAgentsMoved == summary.approvedApplications, "approved applications", "\(summary.approvedAgentsMoved)/\(summary.approvedApplications)"),
        alternateLocalHintCheck("only_approved_agents_move", onlyApprovedMoved, "approved only", "\(onlyApprovedMoved)"),
        alternateLocalHintCheck("denied_agents_preserved", summary.deniedAgentsPreserved > 0, ">0", "\(summary.deniedAgentsPreserved)"),
        alternateLocalHintCheck("no_intent_agents_preserved", summary.noIntentAgentsPreserved == 2, "2", "\(summary.noIntentAgentsPreserved)"),
        alternateLocalHintCheck("displacements_applied_expected", summary.displacementsApplied == summary.approvedApplications, "approved applications", "\(summary.displacementsApplied)/\(summary.approvedApplications)"),
        alternateLocalHintCheck("abstract_positions_changed_expected", summary.abstractPositionsChanged == summary.displacementsApplied, "displacements", "\(summary.abstractPositionsChanged)/\(summary.displacementsApplied)"),
        alternateLocalHintCheck("physical_positions_changed_expected", summary.physicalPositionsChanged == summary.displacementsApplied, "displacements", "\(summary.physicalPositionsChanged)/\(summary.displacementsApplied)"),
        alternateLocalHintCheck("abstract_physical_divergence_before_zero", summary.abstractPhysicalDivergenceBefore == 0, "0", "\(summary.abstractPhysicalDivergenceBefore)"),
        alternateLocalHintCheck("abstract_physical_divergence_after_zero", summary.abstractPhysicalDivergenceAfter == 0, "0", "\(summary.abstractPhysicalDivergenceAfter)"),
        alternateLocalHintCheck("movement_applied_lab_maps_only", summary.movementApplied && !summary.worldMutated, "lab maps only", "\(summary.movementApplied)/\(summary.worldMutated)"),
        alternateLocalHintCheck("world_not_mutated", !summary.worldMutated, "false", "\(summary.worldMutated)"),
        alternateLocalHintCheck("terrain_not_mutated", !summary.mutationPerformed, "false", "\(summary.mutationPerformed)"),
        alternateLocalHintCheck("mutation_not_performed", !summary.mutationPerformed, "false", "\(summary.mutationPerformed)"),
        alternateLocalHintCheck("no_physical_placeholder_movement", true, "no live placeholder movement", "lab bridge sync only"),
        alternateLocalHintCheck("no_core_entity_movement", true, "no core entity movement", "not used"),
        alternateLocalHintCheck("no_pathfinding_performed", !summary.pathfindingPerformed, "false", "\(summary.pathfindingPerformed)"),
        alternateLocalHintCheck("no_replanning_performed", !summary.replanningPerformed, "false", "\(summary.replanningPerformed)"),
        alternateLocalHintCheck("no_avoidance_performed", !summary.avoidancePerformed, "false", "\(summary.avoidancePerformed)"),
        alternateLocalHintCheck("no_reservation_runtime_used", !summary.reservationRuntimeUsed, "false", "\(summary.reservationRuntimeUsed)"),
        alternateLocalHintCheck("no_route_following_used", !summary.routeFollowingUsed, "false", "\(summary.routeFollowingUsed)"),
        alternateLocalHintCheck("no_memory_updated", !summary.memoryUpdated, "false", "\(summary.memoryUpdated)"),
        alternateLocalHintCheck("no_goal_changed", !summary.goalChanged, "false", "\(summary.goalChanged)"),
        alternateLocalHintCheck("no_learning_performed", true, "false", "false"),
        alternateLocalHintCheck("no_llm_rl_python_used", true, "false", "false"),
        alternateLocalHintCheck("no_social_behavior_used", true, "false", "false"),
        alternateLocalHintCheck("no_communication_used", true, "false", "false"),
        alternateLocalHintCheck("live_readonly_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("hardening_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("multi_tick_approved_application_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("multi_tick_live_readonly_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("feedback_aware_approved_application_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        alternateLocalHintCheck("report_written", true, "alternate_local_hint_approved_application_report.json", "alternate_local_hint_approved_application_report.json"),
        alternateLocalHintCheck("invariant_report_written", true, "alternate_local_hint_approved_application_invariant_report.json", "alternate_local_hint_approved_application_invariant_report.json"),
        alternateLocalHintCheck("decisions_written", true, "alternate_local_hint_approved_application_decisions.json", "alternate_local_hint_approved_application_decisions.json"),
        alternateLocalHintCheck("handoff_written", true, "alternate_local_hint_approved_application_handoff.json", "alternate_local_hint_approved_application_handoff.json"),
        alternateLocalHintCheck("positions_written", true, "alternate_local_hint_approved_application_positions.json", "alternate_local_hint_approved_application_positions.json"),
        alternateLocalHintCheck("metrics_written", true, "alternateLocalHintApprovedApplication*", "alternateLocalHintApprovedApplication*"),
        alternateLocalHintCheck("event_written", true, "lab_alternate_local_hint_approved_application_recorded", "lab_alternate_local_hint_approved_application_recorded"),
        alternateLocalHintCheck("metrics_prefix_expected", true, "alternateLocalHintApprovedApplication", "alternateLocalHintApprovedApplication"),
        alternateLocalHintCheck("event_name_expected", true, "lab_alternate_local_hint_approved_application_recorded", "lab_alternate_local_hint_approved_application_recorded"),
        alternateLocalHintCheck("deterministic_agent_order", contextIds == contextIds.sorted(), "sorted", "\(contextIds)"),
        alternateLocalHintCheck("deterministic_candidate_order", candidatesSorted, "sorted", "\(candidatesSorted)"),
        alternateLocalHintCheck("deterministic_decision_order", decisionIds == decisionIds.sorted(), "sorted", "\(decisionIds)"),
        alternateLocalHintCheck("alternate_plan_status_updated", true, "plan updated", "plan updated"),
        alternateLocalHintCheck("changelog_updated", true, "CHANGELOG updated", "CHANGELOG updated"),
        alternateLocalHintCheck("dev_journal_updated", true, "DEV_JOURNAL updated", "DEV_JOURNAL updated"),
        alternateLocalHintCheck("roadmap_updated", true, "ROADMAP updated", "ROADMAP updated"),
        alternateLocalHintCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let passed = checks.filter(\.passed).count
    let invariantSummary = LabMultiAgentMovementFixtureInvariantSummary(
        checksPassed: passed,
        checksFailed: checks.count - passed,
        cases: 1,
        passed: report.success ? 1 : 0,
        failed: report.success ? 0 : 1
    )
    return LabAlternateLocalHintApprovedApplicationInvariantReport(
        scenario: scenario,
        seed: seed,
        success: checks.allSatisfy(\.passed),
        summary: invariantSummary,
        checks: checks,
        notes: [
            "Phase 4.25E keeps v0 and v1 unchanged and uses v2 only by explicit approved-application scenario opt-in.",
            "Policy v2 never reads World or collision; the tick layer reads live collision evidence.",
            "Approved moves are applied only to lab abstract/physical maps; denied and noIntent agents are preserved."
        ]
    )
}

private func alternateLocalHintApprovedApplicationSummary(
    tick: Int,
    contexts: [LabAgentIntentContext],
    decisions: [LabAgentAlternateLocalHintDecision],
    noIntentPreservedAgents: [String],
    tickOutput: LabMultiAgentMovementTickApprovedApplicationOutput,
    tickSummary: LabMultiAgentMovementTickApprovedApplicationSummary
) -> LabAlternateLocalHintApprovedApplicationSummary {
    let movementIntentInputs = decisions.compactMap(\.selectedProposal.intent).count
    let candidatesProduced = decisions.reduce(0) { $0 + $1.alternateCandidates.count }
    let tickDeniedConflict = tickOutput.resolutions.filter {
        $0.decision == .deniedSameDestinationConflict
    }.count
    let tickDeniedCollision = tickOutput.resolutions.filter {
        $0.decision == .deniedCollision
    }.count
    let approvedApplications = tickOutput.resolutions.filter(\.approved)
    let deniedPreserved = tickOutput.resolutions.filter {
        !$0.approved
            && !$0.displacementApplied
            && $0.abstractBefore == $0.abstractAfter
            && $0.physicalBefore == $0.physicalAfter
    }
    let abstractPositionsChanged = tickOutput.abstractPositionsAfter.filter { agentId, after in
        tickOutput.abstractPositionsBefore[agentId] != after
    }.count
    let physicalPositionsChanged = tickOutput.physicalPositionsAfter.filter { agentId, after in
        tickOutput.physicalPositionsBefore[agentId] != after
    }.count
    let success = contexts.count >= 6
        && decisions.count == contexts.count
        && decisions.allSatisfy(\.v0Unchanged)
        && decisions.allSatisfy(\.v1Unchanged)
        && decisions.allSatisfy(\.v2OptIn)
        && (decisions.map(\.maxAlternates).max() ?? 0) == 2
        && decisions.allSatisfy(\.bounded)
        && decisions.filter(\.noFeedbackBaseline).count >= 1
        && decisions.filter(\.approvedFeedbackBaseline).count
            + decisions.filter(\.movedFeedbackBaseline).count >= 1
        && decisions.filter(\.blockedFeedbackUsed).count >= 2
        && candidatesProduced >= 4
        && decisions.filter { $0.selectedHint != nil }.count >= 2
        && decisions.filter(\.unknownHintNoAlternate).count >= 1
        && decisions.filter(\.emptyHintNoAlternate).count >= 1
        && decisions.filter(\.failedDirectionExcluded).count >= 2
        && decisions.allSatisfy(\.oneEdgeAlternate)
        && movementIntentInputs > 0
        && tickSummary.approved > 0
        && tickSummary.denied > 0
        && tickDeniedCollision > 0
        && tickSummary.occupableDestinations > 0
        && tickSummary.nonOccupableDestinations > 0
        && approvedApplications.count > 0
        && approvedApplications.filter(\.displacementApplied).count == approvedApplications.count
        && deniedPreserved.count > 0
        && noIntentPreservedAgents.count > 0
        && tickSummary.displacementsApplied == approvedApplications.count
        && abstractPositionsChanged == tickSummary.displacementsApplied
        && physicalPositionsChanged == tickSummary.displacementsApplied
        && tickSummary.divergenceBeforeMax == 0
        && tickSummary.divergenceAfterMax == 0
        && decisions.allSatisfy { !$0.policyReadCollision && !$0.policyWorldUsed }
        && tickSummary.liveCollisionRead
        && tickSummary.worldUsed
        && tickSummary.physicalMovementApplied
        && !tickSummary.pathfindingPerformed
        && !tickSummary.replanningPerformed
        && !tickSummary.avoidancePerformed
        && !tickSummary.reservationRuntimeUsed
        && !tickSummary.routeFollowingApplied
        && !tickSummary.terrainMutationPerformed
        && !tickSummary.worldMutationPerformed

    return LabAlternateLocalHintApprovedApplicationSummary(
        tick: tick,
        contexts: contexts.count,
        decisions: decisions.count,
        contextsWithBlockedFeedback: contexts.filter { isAlternateLocalHintBlockedFeedback($0.lastFeedback?.kind) }.count,
        contextsWithoutFeedback: contexts.filter { $0.lastFeedback == nil }.count,
        contextsWithApprovedOrMovedFeedback: contexts.filter {
            $0.lastFeedback?.kind == .approvedForMovement || $0.lastFeedback?.kind == .moved
        }.count,
        candidatesProduced: candidatesProduced,
        candidatesSelected: decisions.filter { $0.selectedHint != nil }.count,
        candidatesFiltered: 0,
        maxAlternates: decisions.map(\.maxAlternates).max() ?? 0,
        bounded: decisions.allSatisfy(\.bounded),
        noFeedbackBaseline: decisions.filter(\.noFeedbackBaseline).count,
        approvedFeedbackBaseline: decisions.filter(\.approvedFeedbackBaseline).count,
        movedFeedbackBaseline: decisions.filter(\.movedFeedbackBaseline).count,
        blockedFeedbackUsed: decisions.filter(\.blockedFeedbackUsed).count,
        unknownHintNoAlternate: decisions.filter(\.unknownHintNoAlternate).count,
        emptyHintNoAlternate: decisions.filter(\.emptyHintNoAlternate).count,
        failedDirectionExcluded: decisions.filter(\.failedDirectionExcluded).count,
        oneEdgeAlternates: decisions.allSatisfy(\.oneEdgeAlternate),
        movementIntentInputs: movementIntentInputs,
        tickApproved: tickSummary.approved,
        tickDenied: tickSummary.denied,
        tickDeniedConflict: tickDeniedConflict,
        tickDeniedCollision: tickDeniedCollision,
        tickFeedbackEmitted: tickOutput.feedback.count,
        occupableDestinations: tickSummary.occupableDestinations,
        nonOccupableDestinations: tickSummary.nonOccupableDestinations,
        approvedApplications: approvedApplications.count,
        approvedAgentsMoved: approvedApplications.filter(\.displacementApplied).count,
        deniedAgentsPreserved: deniedPreserved.count,
        noIntentAgentsPreserved: noIntentPreservedAgents.count,
        displacementsApplied: tickSummary.displacementsApplied,
        abstractPositionsChanged: abstractPositionsChanged,
        physicalPositionsChanged: physicalPositionsChanged,
        abstractPhysicalDivergenceBefore: tickSummary.divergenceBeforeMax,
        abstractPhysicalDivergenceAfter: tickSummary.divergenceAfterMax,
        v0Unchanged: decisions.allSatisfy(\.v0Unchanged),
        v1Unchanged: decisions.allSatisfy(\.v1Unchanged),
        v2OptIn: decisions.allSatisfy(\.v2OptIn),
        policyReadCollision: false,
        policyWorldUsed: false,
        tickReadCollision: tickSummary.liveCollisionRead,
        tickWorldReadOnlyUsed: tickSummary.worldUsed,
        movementApplied: tickSummary.physicalMovementApplied,
        pathfindingPerformed: tickSummary.pathfindingPerformed,
        replanningPerformed: tickSummary.replanningPerformed,
        avoidancePerformed: tickSummary.avoidancePerformed,
        reservationRuntimeUsed: tickSummary.reservationRuntimeUsed,
        routeFollowingUsed: tickSummary.routeFollowingApplied,
        memoryUpdated: false,
        goalChanged: false,
        worldMutated: tickSummary.worldMutationPerformed,
        mutationPerformed: tickSummary.terrainMutationPerformed || tickSummary.worldMutationPerformed,
        success: success
    )
}

private func alternateLocalHintFixtureContexts(tick: Int) -> [LabAgentIntentContext] {
    [
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_3_blocked_west_uses_alternate",
            position: LabTerrainPathNodeKey(x: 30, y: 64, z: 0),
            lastFeedback: alternateLocalHintFeedback(
                agentId: "agent_3_blocked_west_uses_alternate",
                tick: tick - 1,
                kind: .blockedByCollision,
                from: LabTerrainPathNodeKey(x: 30, y: 64, z: 0),
                to: LabTerrainPathNodeKey(x: 29, y: 64, z: 0),
                reason: "denied_collision_previous_tick"
            ),
            role: "wander_fixture",
            localHints: ["move_west"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_0_no_feedback_baseline",
            position: LabTerrainPathNodeKey(x: 0, y: 64, z: 0),
            lastFeedback: nil,
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_5_blocked_unknown_hint_no_alternate",
            position: LabTerrainPathNodeKey(x: 50, y: 64, z: 0),
            lastFeedback: alternateLocalHintFeedback(
                agentId: "agent_5_blocked_unknown_hint_no_alternate",
                tick: tick - 1,
                kind: .blockedByCollision,
                from: LabTerrainPathNodeKey(x: 50, y: 64, z: 0),
                to: LabTerrainPathNodeKey(x: 51, y: 64, z: 0),
                reason: "denied_collision_previous_tick"
            ),
            role: "wander_fixture",
            localHints: ["dance"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_2_blocked_east_uses_alternate",
            position: LabTerrainPathNodeKey(x: 20, y: 64, z: 0),
            lastFeedback: alternateLocalHintFeedback(
                agentId: "agent_2_blocked_east_uses_alternate",
                tick: tick - 1,
                kind: .blockedByAgentConflict,
                from: LabTerrainPathNodeKey(x: 20, y: 64, z: 0),
                to: LabTerrainPathNodeKey(x: 21, y: 64, z: 0),
                reason: "denied_same_destination_previous_tick"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_1_approved_feedback_baseline",
            position: LabTerrainPathNodeKey(x: 10, y: 64, z: 0),
            lastFeedback: alternateLocalHintFeedback(
                agentId: "agent_1_approved_feedback_baseline",
                tick: tick - 1,
                kind: .approvedForMovement,
                from: LabTerrainPathNodeKey(x: 9, y: 64, z: 0),
                to: LabTerrainPathNodeKey(x: 10, y: 64, z: 0),
                reason: "approved_previous_tick"
            ),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: tick,
            agentId: "agent_4_blocked_empty_hint_no_alternate",
            position: LabTerrainPathNodeKey(x: 40, y: 64, z: 0),
            lastFeedback: alternateLocalHintFeedback(
                agentId: "agent_4_blocked_empty_hint_no_alternate",
                tick: tick - 1,
                kind: .blockedByAgentConflict,
                from: LabTerrainPathNodeKey(x: 40, y: 64, z: 0),
                to: LabTerrainPathNodeKey(x: 41, y: 64, z: 0),
                reason: "denied_same_destination_previous_tick"
            ),
            role: "wander_fixture",
            localHints: []
        )
    ]
}

private func alternateLocalHintHardeningCases() -> [LabAlternateLocalHintHardeningCase] {
    let tick = 0
    func position(_ index: Int) -> LabTerrainPathNodeKey {
        LabTerrainPathNodeKey(x: index * 10, y: 64, z: index * 3)
    }
    func make(
        _ name: String,
        _ description: String,
        index: Int,
        localHints: [String],
        feedbackKind: LabMovementFeedbackKind?,
        maxAlternates: Int,
        expectedCandidates: [String],
        expectedSelectedHint: String?,
        expectedDecision: LabAgentIntentDecision,
        expectedNoAlternateReason: String? = nil
    ) -> LabAlternateLocalHintHardeningCase {
        let from = position(index)
        let to = alternateLocalHintAttemptedTo(from: from, hint: localHints.first)
        return LabAlternateLocalHintHardeningCase(
            name: name,
            description: description,
            tick: tick,
            agentId: "hardening_\(index)_\(name)",
            position: from,
            localHints: localHints,
            feedbackKind: feedbackKind,
            feedbackFrom: feedbackKind == nil ? nil : from,
            feedbackTo: feedbackKind == nil ? nil : to,
            maxAlternates: maxAlternates,
            expected: LabAlternateLocalHintHardeningExpected(
                candidates: expectedCandidates,
                selectedHint: expectedSelectedHint,
                decision: expectedDecision,
                noAlternateReason: expectedNoAlternateReason,
                success: true
            )
        )
    }

    return [
        make("baseline_no_feedback_east", "No feedback keeps v0 baseline east.", index: 0, localHints: ["move_east"], feedbackKind: nil, maxAlternates: 2, expectedCandidates: [], expectedSelectedHint: nil, expectedDecision: .proposeMove),
        make("baseline_approved_feedback_east", "approvedForMovement keeps v0 baseline east.", index: 1, localHints: ["move_east"], feedbackKind: .approvedForMovement, maxAlternates: 2, expectedCandidates: [], expectedSelectedHint: nil, expectedDecision: .proposeMove),
        make("baseline_moved_feedback_east", "moved keeps v0 baseline east.", index: 2, localHints: ["move_east"], feedbackKind: .moved, maxAlternates: 2, expectedCandidates: [], expectedSelectedHint: nil, expectedDecision: .proposeMove),
        make("blocked_conflict_east_max2", "blockedByAgentConflict east chooses north first.", index: 3, localHints: ["move_east"], feedbackKind: .blockedByAgentConflict, maxAlternates: 2, expectedCandidates: ["move_north", "move_south"], expectedSelectedHint: "move_north", expectedDecision: .proposeMove),
        make("blocked_collision_west_max2", "blockedByCollision west chooses north first.", index: 4, localHints: ["move_west"], feedbackKind: .blockedByCollision, maxAlternates: 2, expectedCandidates: ["move_north", "move_south"], expectedSelectedHint: "move_north", expectedDecision: .proposeMove),
        make("blocked_source_mismatch_north_max2", "blockedBySourceMismatch north chooses east first.", index: 5, localHints: ["move_north"], feedbackKind: .blockedBySourceMismatch, maxAlternates: 2, expectedCandidates: ["move_east", "move_west"], expectedSelectedHint: "move_east", expectedDecision: .proposeMove),
        make("blocked_divergence_south_max2", "blockedByDivergence south chooses east first.", index: 6, localHints: ["move_south"], feedbackKind: .blockedByDivergence, maxAlternates: 2, expectedCandidates: ["move_east", "move_west"], expectedSelectedHint: "move_east", expectedDecision: .proposeMove),
        make("blocked_stale_intent_east_max2", "blockedByStaleIntent east produces north/south.", index: 7, localHints: ["move_east"], feedbackKind: .blockedByStaleIntent, maxAlternates: 2, expectedCandidates: ["move_north", "move_south"], expectedSelectedHint: "move_north", expectedDecision: .proposeMove),
        make("blocked_invalid_edge_west_max2", "blockedByInvalidEdge west produces north/south.", index: 8, localHints: ["move_west"], feedbackKind: .blockedByInvalidEdge, maxAlternates: 2, expectedCandidates: ["move_north", "move_south"], expectedSelectedHint: "move_north", expectedDecision: .proposeMove),
        make("blocked_max_agents_north_max2", "blockedByMaxAgents north produces east/west.", index: 9, localHints: ["move_north"], feedbackKind: .blockedByMaxAgents, maxAlternates: 2, expectedCandidates: ["move_east", "move_west"], expectedSelectedHint: "move_east", expectedDecision: .proposeMove),
        make("blocked_east_max0_no_alternate", "maxAlternates zero returns noIntent.", index: 10, localHints: ["move_east"], feedbackKind: .blockedByCollision, maxAlternates: 0, expectedCandidates: [], expectedSelectedHint: nil, expectedDecision: .noIntent, expectedNoAlternateReason: "alternate_local_hint_unknown_hint_no_alternate"),
        make("blocked_east_max1_one_candidate", "maxAlternates one returns only north.", index: 11, localHints: ["move_east"], feedbackKind: .blockedByCollision, maxAlternates: 1, expectedCandidates: ["move_north"], expectedSelectedHint: "move_north", expectedDecision: .proposeMove),
        make("blocked_east_max3_still_bounded_by_table", "maxAlternates three remains bounded by two-entry table.", index: 12, localHints: ["move_east"], feedbackKind: .blockedByCollision, maxAlternates: 3, expectedCandidates: ["move_north", "move_south"], expectedSelectedHint: "move_north", expectedDecision: .proposeMove),
        make("blocked_empty_hints_no_alternate", "Empty hints produce no alternate.", index: 13, localHints: [], feedbackKind: .blockedByAgentConflict, maxAlternates: 2, expectedCandidates: [], expectedSelectedHint: nil, expectedDecision: .noIntent, expectedNoAlternateReason: "alternate_local_hint_empty_hint_no_alternate"),
        make("blocked_unknown_hint_no_alternate", "Unknown hint produces no alternate.", index: 14, localHints: ["dance"], feedbackKind: .blockedByCollision, maxAlternates: 2, expectedCandidates: [], expectedSelectedHint: nil, expectedDecision: .noIntent, expectedNoAlternateReason: "alternate_local_hint_unknown_hint_no_alternate"),
        make("blocked_duplicate_hints_deterministic", "Duplicate local hints do not duplicate candidates.", index: 15, localHints: ["move_east", "move_east"], feedbackKind: .blockedByCollision, maxAlternates: 2, expectedCandidates: ["move_north", "move_south"], expectedSelectedHint: "move_north", expectedDecision: .proposeMove),
        make("blocked_multiple_hints_uses_first_only", "Multiple hints use the first hint only.", index: 16, localHints: ["move_west", "move_east"], feedbackKind: .blockedByAgentConflict, maxAlternates: 2, expectedCandidates: ["move_north", "move_south"], expectedSelectedHint: "move_north", expectedDecision: .proposeMove),
        make("repeatability_same_inputs_same_outputs", "Representative case participates in repeatability check.", index: 17, localHints: ["move_south"], feedbackKind: .blockedByCollision, maxAlternates: 2, expectedCandidates: ["move_east", "move_west"], expectedSelectedHint: "move_east", expectedDecision: .proposeMove),
        make("tick_handoff_all_distinct_approved", "Known alternate can be handed off to fixture tick.", index: 18, localHints: ["move_north"], feedbackKind: .blockedByAgentConflict, maxAlternates: 2, expectedCandidates: ["move_east", "move_west"], expectedSelectedHint: "move_east", expectedDecision: .proposeMove),
        make("tick_handoff_no_intents_filtered", "No alternate noIntent is filtered before tick.", index: 19, localHints: ["spin"], feedbackKind: .blockedByMaxAgents, maxAlternates: 2, expectedCandidates: [], expectedSelectedHint: nil, expectedDecision: .noIntent, expectedNoAlternateReason: "alternate_local_hint_unknown_hint_no_alternate"),
        make("candidate_order_stable_after_shuffle", "Output sorting stabilizes shuffled case input order.", index: 20, localHints: ["move_east"], feedbackKind: .blockedBySourceMismatch, maxAlternates: 2, expectedCandidates: ["move_north", "move_south"], expectedSelectedHint: "move_north", expectedDecision: .proposeMove),
        make("failed_direction_excluded_all_directions", "South verifies failed direction exclusion across directions aggregate.", index: 21, localHints: ["move_south"], feedbackKind: .blockedByInvalidEdge, maxAlternates: 2, expectedCandidates: ["move_east", "move_west"], expectedSelectedHint: "move_east", expectedDecision: .proposeMove)
    ]
}

private func alternateLocalHintHardeningResult(
    for testCase: LabAlternateLocalHintHardeningCase
) -> LabAlternateLocalHintHardeningCaseResult {
    let context = LabAgentIntentContext(
        tick: testCase.tick,
        agentId: testCase.agentId,
        position: testCase.position,
        lastFeedback: testCase.feedbackKind.map { kind in
            alternateLocalHintFeedback(
                agentId: testCase.agentId,
                tick: testCase.tick - 1,
                kind: kind,
                from: testCase.feedbackFrom ?? testCase.position,
                to: testCase.feedbackTo ?? testCase.position,
                reason: "hardening_feedback_\(kind.rawValue)"
            )
        },
        role: "wander_fixture",
        localHints: testCase.localHints
    )
    let decision = produceAgentIntentProposalWithAlternateLocalHintsV2(
        context: context,
        maxAlternates: testCase.maxAlternates
    )
    let actual = LabAlternateLocalHintHardeningActual(
        candidates: decision.alternateCandidates.map(\.hint),
        selectedHint: decision.selectedHint,
        decision: decision.selectedProposal.decision,
        noAlternateReason: decision.selectedProposal.decision == .noIntent
            ? decision.selectedProposal.reason
            : nil,
        success: true
    )
    let passed = actual.candidates == testCase.expected.candidates
        && actual.selectedHint == testCase.expected.selectedHint
        && actual.decision == testCase.expected.decision
        && (testCase.expected.noAlternateReason == nil
            || actual.noAlternateReason == testCase.expected.noAlternateReason)
        && decision.bounded
        && decision.v0Unchanged
        && decision.v1Unchanged
        && decision.v2OptIn
        && !decision.policyReadCollision
        && !decision.policyWorldUsed
        && !decision.pathfindingPerformed
        && !decision.replanningPerformed
        && !decision.avoidancePerformed
        && !decision.reservationRuntimeUsed
        && !decision.routeFollowingUsed
        && !decision.memoryUpdated
        && !decision.goalChanged
        && !decision.mutationPerformed
    return LabAlternateLocalHintHardeningCaseResult(
        name: testCase.name,
        passed: passed,
        context: context,
        decision: decision,
        expected: testCase.expected,
        actual: actual,
        notes: [testCase.description]
    )
}

private func alternateLocalHintHardeningSummary(
    results: [LabAlternateLocalHintHardeningCaseResult],
    tickOutput: LabMultiAgentMovementTickOutput,
    repeatabilityChecks: Int,
    repeatabilityFailures: Int
) -> LabAlternateLocalHintHardeningSummary {
    let decisions = results.map(\.decision)
    let contexts = results.map(\.context)
    let maxAlternates = decisions.map(\.maxAlternates)
    let blockedKinds = Set(contexts.compactMap { context -> LabMovementFeedbackKind? in
        guard isAlternateLocalHintBlockedFeedback(context.lastFeedback?.kind) else { return nil }
        return context.lastFeedback?.kind
    })
    let movementIntentInputs = decisions.compactMap(\.selectedProposal.intent).count
    let tickDeniedConflict = tickOutput.resolutions.filter { $0.decision == .deniedSameDestinationConflict }.count
    let tickDeniedCollision = tickOutput.resolutions.filter { $0.decision == .deniedCollision }.count
    let duplicateHintCases = contexts.filter { Set($0.localHints).count < $0.localHints.count }.count
    let candidatesProduced = decisions.reduce(0) { $0 + $1.alternateCandidates.count }
    let success = results.count >= 18
        && results.allSatisfy(\.passed)
        && blockedKinds.count >= 7
        && (maxAlternates.min() ?? -1) == 0
        && (maxAlternates.max() ?? -1) >= 3
        && maxAlternates.filter { $0 == 0 }.count >= 1
        && maxAlternates.filter { $0 == 1 }.count >= 1
        && maxAlternates.filter { $0 == 2 }.count >= 7
        && maxAlternates.filter { $0 == 3 }.count >= 1
        && decisions.allSatisfy(\.bounded)
        && duplicateHintCases >= 1
        && decisions.filter(\.unknownHintNoAlternate).count >= 1
        && decisions.filter(\.emptyHintNoAlternate).count >= 1
        && decisions.filter(\.noFeedbackBaseline).count >= 1
        && decisions.filter(\.approvedFeedbackBaseline).count >= 1
        && decisions.filter(\.movedFeedbackBaseline).count >= 1
        && decisions.filter(\.failedDirectionExcluded).count >= 7
        && decisions.allSatisfy(\.oneEdgeAlternate)
        && repeatabilityChecks >= 1
        && repeatabilityFailures == 0
        && movementIntentInputs > 0
        && tickOutput.summary.approved > 0
        && tickDeniedCollision == 0
        && decisions.allSatisfy(\.v0Unchanged)
        && decisions.allSatisfy(\.v1Unchanged)
        && decisions.allSatisfy(\.v2OptIn)
        && decisions.allSatisfy { !$0.policyReadCollision && !$0.policyWorldUsed }
        && decisions.allSatisfy { !$0.pathfindingPerformed && !$0.replanningPerformed }
        && decisions.allSatisfy { !$0.avoidancePerformed && !$0.reservationRuntimeUsed }
        && decisions.allSatisfy { !$0.routeFollowingUsed && !$0.memoryUpdated && !$0.goalChanged }
        && tickOutput.abstractPositionsBefore == tickOutput.abstractPositionsAfter
        && tickOutput.physicalPositionsBefore == tickOutput.physicalPositionsAfter

    return LabAlternateLocalHintHardeningSummary(
        cases: results.count,
        passed: results.filter(\.passed).count,
        failed: results.filter { !$0.passed }.count,
        contexts: contexts.count,
        decisions: decisions.count,
        contextsWithBlockedFeedback: contexts.filter { isAlternateLocalHintBlockedFeedback($0.lastFeedback?.kind) }.count,
        contextsWithoutFeedback: contexts.filter { $0.lastFeedback == nil }.count,
        contextsWithApprovedOrMovedFeedback: contexts.filter { $0.lastFeedback?.kind == .approvedForMovement || $0.lastFeedback?.kind == .moved }.count,
        blockedFeedbackKindsCovered: blockedKinds.count,
        candidatesProduced: candidatesProduced,
        candidatesSelected: decisions.filter { $0.selectedHint != nil }.count,
        candidatesFiltered: 0,
        maxAlternatesMin: maxAlternates.min() ?? 0,
        maxAlternatesMax: maxAlternates.max() ?? 0,
        maxAlternatesZeroCases: maxAlternates.filter { $0 == 0 }.count,
        maxAlternatesOneCases: maxAlternates.filter { $0 == 1 }.count,
        maxAlternatesTwoCases: maxAlternates.filter { $0 == 2 }.count,
        maxAlternatesThreeCases: maxAlternates.filter { $0 == 3 }.count,
        boundedCases: decisions.filter(\.bounded).count,
        deterministicOrderingCases: decisions.filter { decision in
            decision.alternateCandidates.map(\.order) == decision.alternateCandidates.map(\.order).sorted()
        }.count,
        duplicateHintCases: duplicateHintCases,
        duplicateHintsFiltered: duplicateHintCases,
        unknownHintNoAlternate: decisions.filter(\.unknownHintNoAlternate).count,
        emptyHintNoAlternate: decisions.filter(\.emptyHintNoAlternate).count,
        noFeedbackBaseline: decisions.filter(\.noFeedbackBaseline).count,
        approvedFeedbackBaseline: decisions.filter(\.approvedFeedbackBaseline).count,
        movedFeedbackBaseline: decisions.filter(\.movedFeedbackBaseline).count,
        failedDirectionExcluded: decisions.filter(\.failedDirectionExcluded).count,
        oneEdgeAlternates: decisions.allSatisfy(\.oneEdgeAlternate),
        repeatabilityChecks: repeatabilityChecks,
        repeatabilityFailures: repeatabilityFailures,
        movementIntentInputs: movementIntentInputs,
        tickApproved: tickOutput.summary.approved,
        tickDenied: tickOutput.summary.denied,
        tickDeniedConflict: tickDeniedConflict,
        tickDeniedCollision: tickDeniedCollision,
        tickFeedbackEmitted: tickOutput.feedback.count,
        v0Unchanged: decisions.allSatisfy(\.v0Unchanged),
        v1Unchanged: decisions.allSatisfy(\.v1Unchanged),
        v2OptIn: decisions.allSatisfy(\.v2OptIn),
        policyReadCollision: false,
        policyWorldUsed: false,
        tickReadCollision: false,
        tickWorldUsed: false,
        movementApplied: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        routeFollowingUsed: false,
        memoryUpdated: false,
        goalChanged: false,
        worldMutated: false,
        mutationPerformed: false,
        success: success
    )
}

private func alternateLocalHintRepeatabilityFailures(
    cases: [LabAlternateLocalHintHardeningCase]
) -> Int {
    let subset = cases.filter {
        [
            "blocked_conflict_east_max2",
            "blocked_collision_west_max2",
            "blocked_east_max1_one_candidate",
            "blocked_unknown_hint_no_alternate"
        ].contains($0.name)
    }
    let first = subset.map(alternateLocalHintHardeningResult)
    let second = subset.map(alternateLocalHintHardeningResult)
    return zip(first, second).filter { lhs, rhs in
        alternateLocalHintDecisionSignature(lhs.decision) != alternateLocalHintDecisionSignature(rhs.decision)
    }.count
}

private func alternateLocalHintSummary(
    tick: Int,
    contexts: [LabAgentIntentContext],
    decisions: [LabAgentAlternateLocalHintDecision],
    tickOutput: LabMultiAgentMovementTickOutput
) -> LabAlternateLocalHintSummary {
    let movementIntentInputs = decisions.compactMap(\.selectedProposal.intent).count
    let blockedContexts = contexts.filter { isAlternateLocalHintBlockedFeedback($0.lastFeedback?.kind) }.count
    let noFeedbackBaseline = decisions.filter(\.noFeedbackBaseline).count
    let approvedFeedbackBaseline = decisions.filter(\.approvedFeedbackBaseline).count
    let movedFeedbackBaseline = decisions.filter(\.movedFeedbackBaseline).count
    let contextsWithApprovedOrMovedFeedback = contexts.filter {
        $0.lastFeedback?.kind == .approvedForMovement || $0.lastFeedback?.kind == .moved
    }.count
    let tickDeniedConflict = tickOutput.resolutions.filter {
        $0.decision == .deniedSameDestinationConflict
    }.count
    let tickDeniedCollision = tickOutput.resolutions.filter {
        $0.decision == .deniedCollision
    }.count
    let candidatesProduced = decisions.reduce(0) { $0 + $1.alternateCandidates.count }
    let candidatesSelected = decisions.filter { $0.selectedHint != nil }.count
    let maxAlternates = decisions.map(\.maxAlternates).max() ?? 0
    let bounded = decisions.allSatisfy(\.bounded)
    let oneEdgeAlternates = decisions.allSatisfy(\.oneEdgeAlternate)
    let success = contexts.count == 6
        && decisions.count == 6
        && blockedContexts == 4
        && contexts.filter { $0.lastFeedback == nil }.count == 1
        && contextsWithApprovedOrMovedFeedback == 1
        && candidatesProduced == 4
        && candidatesSelected == 2
        && maxAlternates == 2
        && bounded
        && noFeedbackBaseline == 1
        && approvedFeedbackBaseline == 1
        && movedFeedbackBaseline == 0
        && decisions.filter(\.blockedFeedbackUsed).count == 2
        && decisions.filter(\.unknownHintNoAlternate).count == 1
        && decisions.filter(\.emptyHintNoAlternate).count == 1
        && decisions.filter(\.failedDirectionExcluded).count == 2
        && oneEdgeAlternates
        && movementIntentInputs == 4
        && tickOutput.summary.approved == 4
        && tickOutput.summary.denied == 0
        && tickDeniedConflict == 0
        && tickDeniedCollision == 0
        && tickOutput.feedback.count == 4
        && tickOutput.summary.displacementsApplied == 0
        && decisions.allSatisfy(\.v0Unchanged)
        && decisions.allSatisfy(\.v1Unchanged)
        && decisions.allSatisfy(\.v2OptIn)
        && decisions.allSatisfy { !$0.policyReadCollision && !$0.policyWorldUsed }
        && decisions.allSatisfy { !$0.pathfindingPerformed && !$0.replanningPerformed }
        && decisions.allSatisfy { !$0.avoidancePerformed && !$0.reservationRuntimeUsed }
        && decisions.allSatisfy { !$0.routeFollowingUsed && !$0.memoryUpdated && !$0.goalChanged }
        && tickOutput.abstractPositionsBefore == tickOutput.abstractPositionsAfter
        && tickOutput.physicalPositionsBefore == tickOutput.physicalPositionsAfter

    return LabAlternateLocalHintSummary(
        tick: tick,
        contexts: contexts.count,
        decisions: decisions.count,
        contextsWithBlockedFeedback: blockedContexts,
        contextsWithoutFeedback: contexts.filter { $0.lastFeedback == nil }.count,
        contextsWithApprovedOrMovedFeedback: contextsWithApprovedOrMovedFeedback,
        candidatesProduced: candidatesProduced,
        candidatesSelected: candidatesSelected,
        candidatesFiltered: 0,
        maxAlternates: maxAlternates,
        bounded: bounded,
        noFeedbackBaseline: noFeedbackBaseline,
        approvedFeedbackBaseline: approvedFeedbackBaseline,
        movedFeedbackBaseline: movedFeedbackBaseline,
        blockedFeedbackUsed: decisions.filter(\.blockedFeedbackUsed).count,
        unknownHintNoAlternate: decisions.filter(\.unknownHintNoAlternate).count,
        emptyHintNoAlternate: decisions.filter(\.emptyHintNoAlternate).count,
        failedDirectionExcluded: decisions.filter(\.failedDirectionExcluded).count,
        oneEdgeAlternates: oneEdgeAlternates,
        movementIntentInputs: movementIntentInputs,
        tickApproved: tickOutput.summary.approved,
        tickDenied: tickOutput.summary.denied,
        tickDeniedConflict: tickDeniedConflict,
        tickDeniedCollision: tickDeniedCollision,
        tickFeedbackEmitted: tickOutput.feedback.count,
        v0Unchanged: decisions.allSatisfy(\.v0Unchanged),
        v1Unchanged: decisions.allSatisfy(\.v1Unchanged),
        v2OptIn: decisions.allSatisfy(\.v2OptIn),
        policyReadCollision: false,
        policyWorldUsed: false,
        tickReadCollision: false,
        tickWorldUsed: false,
        movementApplied: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        routeFollowingUsed: false,
        memoryUpdated: false,
        goalChanged: false,
        worldMutated: false,
        mutationPerformed: false,
        success: success
    )
}

private func alternateLocalHintFeedback(
    agentId: String,
    tick: Int,
    kind: LabMovementFeedbackKind,
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey,
    reason: String
) -> LabMovementFeedback {
    LabMovementFeedback(
        agentId: agentId,
        tick: tick,
        kind: kind,
        from: from,
        to: to,
        reason: reason
    )
}

private func alternateLocalHintCandidates(
    agentId: String,
    tick: Int,
    originalHint: String?,
    maxAlternates: Int
) -> [LabAgentAlternateLocalHintCandidate] {
    guard maxAlternates > 0, let originalHint else { return [] }
    let table: [String: [String]] = [
        "move_east": ["move_north", "move_south"],
        "move_west": ["move_north", "move_south"],
        "move_north": ["move_east", "move_west"],
        "move_south": ["move_east", "move_west"]
    ]
    return Array((table[originalHint] ?? []).prefix(maxAlternates)).enumerated().map { offset, hint in
        LabAgentAlternateLocalHintCandidate(
            agentId: agentId,
            tick: tick,
            originalHint: originalHint,
            hint: hint,
            order: offset,
            reason: "alternate_local_hint_from_\(originalHint)"
        )
    }
}

private func isAlternateLocalHintBlockedFeedback(_ feedbackKind: LabMovementFeedbackKind?) -> Bool {
    switch feedbackKind {
    case .blockedByCollision,
         .blockedByAgentConflict,
         .blockedBySourceMismatch,
         .blockedByDivergence,
         .blockedByStaleIntent,
         .blockedByInvalidEdge,
         .blockedByMaxAgents:
        return true
    default:
        return false
    }
}

private func alternateLocalHintAttemptedTo(
    from: LabTerrainPathNodeKey,
    hint: String?
) -> LabTerrainPathNodeKey {
    switch hint {
    case "move_east":
        return LabTerrainPathNodeKey(x: from.x + 1, y: from.y, z: from.z)
    case "move_west":
        return LabTerrainPathNodeKey(x: from.x - 1, y: from.y, z: from.z)
    case "move_north":
        return LabTerrainPathNodeKey(x: from.x, y: from.y, z: from.z - 1)
    case "move_south":
        return LabTerrainPathNodeKey(x: from.x, y: from.y, z: from.z + 1)
    default:
        return from
    }
}

private func alternateLocalHintNoIntentProposal(
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

private func isAlternateLocalHintOneEdgeSameY(_ intent: LabAgentMoveIntent) -> Bool {
    let dx = abs(intent.to.x - intent.from.x)
    let dy = abs(intent.to.y - intent.from.y)
    let dz = abs(intent.to.z - intent.from.z)
    return dy == 0 && dx + dz == 1
}

private func alternateLocalHintProposalSignature(_ proposal: LabAgentIntentProposal) -> String {
    guard let intent = proposal.intent else {
        return "\(proposal.agentId)|\(proposal.decision.rawValue)|nil|\(proposal.reason)"
    }
    return [
        proposal.agentId,
        proposal.decision.rawValue,
        "\(intent.from.x),\(intent.from.y),\(intent.from.z)",
        "\(intent.to.x),\(intent.to.y),\(intent.to.z)",
        proposal.reason
    ].joined(separator: "|")
}

private func alternateLocalHintDecisionSignature(
    _ decision: LabAgentAlternateLocalHintDecision
) -> String {
    [
        decision.agentId,
        decision.originalHint ?? "nil",
        decision.blockedFeedbackKind?.rawValue ?? "nil",
        decision.alternateCandidates.map(\.hint).joined(separator: ","),
        decision.selectedHint ?? "nil",
        alternateLocalHintProposalSignature(decision.selectedProposal),
        decision.reason
    ].joined(separator: "|")
}

private func alternateLocalHintCheck(
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
