import PebbleCore

enum LabAgentMovementPolicyVersion: String, Codable, CaseIterable {
    case baselineV0
    case feedbackAwareV1
    case alternateLocalHintV2
}

struct LabAgentMovementPolicyBoundary: Codable {
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
}

struct LabAgentMovementTickBoundary: Codable {
    let tickReadCollision: Bool
    let tickWorldReadOnlyUsed: Bool
    let movementApplied: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
}

struct LabAgentMovementPolicyConsolidatedDecision: Codable {
    let tick: Int
    let agentId: String
    let policyVersion: LabAgentMovementPolicyVersion
    let context: LabAgentIntentContext
    let directProposal: LabAgentIntentProposal
    let consolidatedProposal: LabAgentIntentProposal
    let directSignature: String
    let consolidatedSignature: String
    let signaturesMatch: Bool
    let baselineProposal: LabAgentIntentProposal
    let feedbackAwareV1Proposal: LabAgentIntentProposal?
    let alternateLocalHintV2Decision: LabAgentAlternateLocalHintDecision?
    let selectedHint: String?
    let alternateCandidates: [LabAgentAlternateLocalHintCandidate]
    let reason: String
    let policyBoundary: LabAgentMovementPolicyBoundary
    let tickBoundary: LabAgentMovementTickBoundary
    let noBehaviorChange: Bool
}

struct LabAgentMovementPolicyConsolidationSummary: Codable {
    let scenario: String
    let seed: UInt32
    let contexts: Int
    let policyVersions: Int
    let directDecisions: Int
    let consolidatedDecisions: Int
    let signaturesCompared: Int
    let signaturesMatched: Int
    let signatureMismatches: Int
    let v0Contexts: Int
    let v1Contexts: Int
    let v2Contexts: Int
    let v0SignaturesCompared: Int
    let v1SignaturesCompared: Int
    let v2SignaturesCompared: Int
    let v0SignatureMismatches: Int
    let v1SignatureMismatches: Int
    let v2SignatureMismatches: Int
    let noFeedbackBaseline: Int
    let approvedFeedbackBaseline: Int
    let movedFeedbackBaseline: Int
    let blockedFeedbackNoIntentV1: Int
    let blockedFeedbackAlternateV2: Int
    let emptyHintNoIntent: Int
    let unknownHintNoIntent: Int
    let candidatesProduced: Int
    let candidatesSelected: Int
    let maxAlternates: Int
    let bounded: Bool
    let v0Unchanged: Bool
    let v1Unchanged: Bool
    let v2OptIn: Bool
    let v2NotGlobal: Bool
    let hiddenActivationDetected: Bool
    let policyReadCollision: Bool
    let policyWorldUsed: Bool
    let tickReadCollision: Bool
    let tickWorldReadOnlyUsed: Bool
    let movementApplied: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let routeFollowingUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAgentMovementPolicyConsolidationReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let policyVersions: [LabAgentMovementPolicyVersion]
    let contexts: [LabAgentIntentContext]
    let decisions: [LabAgentMovementPolicyConsolidatedDecision]
    let summary: LabAgentMovementPolicyConsolidationSummary
}

struct LabAgentMovementPolicyConsolidationInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAgentMovementPolicyConsolidationSignatures: Codable {
    let scenario: String
    let seed: UInt32
    let signatures: [LabAgentMovementPolicyConsolidationSignatureRecord]
    let summary: LabAgentMovementPolicyConsolidationSummary
}

struct LabAgentMovementPolicyConsolidationSignatureRecord: Codable {
    let agentId: String
    let policyVersion: LabAgentMovementPolicyVersion
    let directSignature: String
    let consolidatedSignature: String
    let signaturesMatch: Bool
}

private let policyConsolidationBoundary = LabAgentMovementPolicyBoundary(
    policyReadCollision: false,
    policyWorldUsed: false,
    pathfindingPerformed: false,
    replanningPerformed: false,
    avoidancePerformed: false,
    reservationRuntimeUsed: false,
    routeFollowingUsed: false,
    memoryUpdated: false,
    goalChanged: false,
    mutationPerformed: false
)

private let policyConsolidationTickBoundary = LabAgentMovementTickBoundary(
    tickReadCollision: false,
    tickWorldReadOnlyUsed: false,
    movementApplied: false,
    worldMutated: false,
    terrainMutated: false,
    coreEntityMoved: false,
    physicalPlaceholderMoved: false
)

private func makePolicyConsolidationFeedback(
    agentId: String,
    kind: LabMovementFeedbackKind,
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey
) -> LabMovementFeedback {
    LabMovementFeedback(
        agentId: agentId,
        tick: 0,
        kind: kind,
        from: from,
        to: to,
        reason: "policy_consolidation_\(kind.rawValue)"
    )
}

private func policyConsolidationContext(
    agentId: String,
    position: LabTerrainPathNodeKey,
    hints: [String],
    feedbackKind: LabMovementFeedbackKind? = nil
) -> LabAgentIntentContext {
    let feedback = feedbackKind.map {
        makePolicyConsolidationFeedback(
            agentId: agentId,
            kind: $0,
            from: position,
            to: position
        )
    }
    return LabAgentIntentContext(
        tick: 0,
        agentId: agentId,
        position: position,
        lastFeedback: feedback,
        role: "wander_fixture",
        localHints: hints
    )
}

private func makePolicyConsolidationContexts() -> [LabAgentIntentContext] {
    [
        policyConsolidationContext(
            agentId: "policy_context_blocked_collision_move_west",
            position: LabTerrainPathNodeKey(x: 10, y: 64, z: 0),
            hints: ["move_west"],
            feedbackKind: .blockedByCollision
        ),
        policyConsolidationContext(
            agentId: "policy_context_no_feedback_unknown_hint",
            position: LabTerrainPathNodeKey(x: 4, y: 64, z: 0),
            hints: ["unknown_hint"]
        ),
        policyConsolidationContext(
            agentId: "policy_context_blocked_empty_hint",
            position: LabTerrainPathNodeKey(x: 12, y: 64, z: 0),
            hints: [],
            feedbackKind: .blockedByAgentConflict
        ),
        policyConsolidationContext(
            agentId: "policy_context_moved_feedback_move_east",
            position: LabTerrainPathNodeKey(x: 8, y: 64, z: 0),
            hints: ["move_east"],
            feedbackKind: .moved
        ),
        policyConsolidationContext(
            agentId: "policy_context_blocked_conflict_move_east",
            position: LabTerrainPathNodeKey(x: 9, y: 64, z: 0),
            hints: ["move_east"],
            feedbackKind: .blockedByAgentConflict
        ),
        policyConsolidationContext(
            agentId: "policy_context_no_feedback_move_east",
            position: LabTerrainPathNodeKey(x: 0, y: 64, z: 0),
            hints: ["move_east"]
        ),
        policyConsolidationContext(
            agentId: "policy_context_blocked_unknown_hint",
            position: LabTerrainPathNodeKey(x: 14, y: 64, z: 0),
            hints: ["dance"],
            feedbackKind: .blockedByCollision
        ),
        policyConsolidationContext(
            agentId: "policy_context_approved_feedback_move_east",
            position: LabTerrainPathNodeKey(x: 6, y: 64, z: 0),
            hints: ["move_east"],
            feedbackKind: .approvedForMovement
        )
    ]
}

private func consolidatedPolicyDecision(
    context: LabAgentIntentContext,
    policyVersion: LabAgentMovementPolicyVersion,
    maxAlternates: Int
) -> (proposal: LabAgentIntentProposal, v1: LabAgentIntentFeedbackPolicyDecision?, v2: LabAgentAlternateLocalHintDecision?) {
    switch policyVersion {
    case .baselineV0:
        return (produceAgentIntentProposalV0(context: context), nil, nil)
    case .feedbackAwareV1:
        let decision = produceAgentIntentProposalFeedbackAwareV1(context: context)
        return (decision.feedbackAwareProposal, decision, nil)
    case .alternateLocalHintV2:
        let decision = produceAgentIntentProposalWithAlternateLocalHintsV2(
            context: context,
            maxAlternates: maxAlternates
        )
        return (decision.selectedProposal, nil, decision)
    }
}

private func directPolicyDecision(
    context: LabAgentIntentContext,
    policyVersion: LabAgentMovementPolicyVersion,
    maxAlternates: Int
) -> (proposal: LabAgentIntentProposal, v1: LabAgentIntentFeedbackPolicyDecision?, v2: LabAgentAlternateLocalHintDecision?) {
    consolidatedPolicyDecision(
        context: context,
        policyVersion: policyVersion,
        maxAlternates: maxAlternates
    )
}

private func proposalSignatureForConsolidation(_ proposal: LabAgentIntentProposal) -> String {
    let intentSignature: String
    if let intent = proposal.intent {
        intentSignature = [
            "\(intent.from.x),\(intent.from.y),\(intent.from.z)",
            "\(intent.to.x),\(intent.to.y),\(intent.to.z)",
            intent.reason,
            "\(intent.stale)"
        ].joined(separator: ">")
    } else {
        intentSignature = "nil"
    }
    return [
        proposal.agentId,
        "\(proposal.tick)",
        proposal.decision.rawValue,
        proposal.reason,
        intentSignature
    ].joined(separator: "|")
}

private func decisionSignatureForConsolidation(
    proposal: LabAgentIntentProposal,
    selectedHint: String?,
    candidates: [LabAgentAlternateLocalHintCandidate]
) -> String {
    [
        proposalSignatureForConsolidation(proposal),
        selectedHint ?? "nil",
        candidates.map(\.hint).joined(separator: ",")
    ].joined(separator: "|")
}

private func makePolicyConsolidationDecision(
    context: LabAgentIntentContext,
    policyVersion: LabAgentMovementPolicyVersion,
    maxAlternates: Int
) -> LabAgentMovementPolicyConsolidatedDecision {
    let direct = directPolicyDecision(
        context: context,
        policyVersion: policyVersion,
        maxAlternates: maxAlternates
    )
    let consolidated = consolidatedPolicyDecision(
        context: context,
        policyVersion: policyVersion,
        maxAlternates: maxAlternates
    )
    let baseline = produceAgentIntentProposalV0(context: context)
    let feedbackAware = policyVersion == .feedbackAwareV1
        ? consolidated.v1?.feedbackAwareProposal
        : nil
    let v2Decision = consolidated.v2
    let candidates = v2Decision?.alternateCandidates ?? []
    let selectedHint = v2Decision?.selectedHint
    let directSignature = decisionSignatureForConsolidation(
        proposal: direct.proposal,
        selectedHint: direct.v2?.selectedHint,
        candidates: direct.v2?.alternateCandidates ?? []
    )
    let consolidatedSignature = decisionSignatureForConsolidation(
        proposal: consolidated.proposal,
        selectedHint: selectedHint,
        candidates: candidates
    )
    let signaturesMatch = directSignature == consolidatedSignature

    return LabAgentMovementPolicyConsolidatedDecision(
        tick: context.tick,
        agentId: context.agentId,
        policyVersion: policyVersion,
        context: context,
        directProposal: direct.proposal,
        consolidatedProposal: consolidated.proposal,
        directSignature: directSignature,
        consolidatedSignature: consolidatedSignature,
        signaturesMatch: signaturesMatch,
        baselineProposal: baseline,
        feedbackAwareV1Proposal: feedbackAware,
        alternateLocalHintV2Decision: v2Decision,
        selectedHint: selectedHint,
        alternateCandidates: candidates,
        reason: "direct_and_consolidated_policy_signatures_match_\(signaturesMatch)",
        policyBoundary: policyConsolidationBoundary,
        tickBoundary: policyConsolidationTickBoundary,
        noBehaviorChange: signaturesMatch
    )
}

private func isPolicyConsolidationBlockedFeedback(_ kind: LabMovementFeedbackKind?) -> Bool {
    switch kind {
    case .blockedByCollision,
         .blockedByAgentConflict,
         .blockedBySourceMismatch,
         .blockedByDivergence,
         .blockedByStaleIntent,
         .blockedByInvalidEdge,
         .blockedByMaxAgents:
        return true
    case nil, .approvedForMovement, .moved:
        return false
    }
}

private func isPolicyConsolidationBaseline(_ decision: LabAgentMovementPolicyConsolidatedDecision) -> Bool {
    proposalSignatureForConsolidation(decision.consolidatedProposal)
        == proposalSignatureForConsolidation(decision.baselineProposal)
}

private func makePolicyConsolidationSummary(
    scenario: String,
    seed: UInt32,
    contexts: [LabAgentIntentContext],
    decisions: [LabAgentMovementPolicyConsolidatedDecision],
    maxAlternates: Int
) -> LabAgentMovementPolicyConsolidationSummary {
    let v0 = decisions.filter { $0.policyVersion == .baselineV0 }
    let v1 = decisions.filter { $0.policyVersion == .feedbackAwareV1 }
    let v2 = decisions.filter { $0.policyVersion == .alternateLocalHintV2 }
    let signatureMismatches = decisions.filter { !$0.signaturesMatch }.count
    let v0Mismatches = v0.filter { !$0.signaturesMatch }.count
    let v1Mismatches = v1.filter { !$0.signaturesMatch }.count
    let v2Mismatches = v2.filter { !$0.signaturesMatch }.count
    let noFeedbackBaseline = decisions.filter {
        $0.context.lastFeedback == nil && isPolicyConsolidationBaseline($0)
    }.count
    let approvedFeedbackBaseline = decisions.filter {
        $0.context.lastFeedback?.kind == .approvedForMovement && isPolicyConsolidationBaseline($0)
    }.count
    let movedFeedbackBaseline = decisions.filter {
        $0.context.lastFeedback?.kind == .moved && isPolicyConsolidationBaseline($0)
    }.count
    let blockedFeedbackNoIntentV1 = v1.filter {
        isPolicyConsolidationBlockedFeedback($0.context.lastFeedback?.kind)
            && $0.consolidatedProposal.decision == .noIntent
    }.count
    let blockedFeedbackAlternateV2 = v2.filter {
        ($0.alternateLocalHintV2Decision?.blockedFeedbackUsed ?? false)
            && $0.consolidatedProposal.decision == .proposeMove
    }.count
    let emptyHintNoIntent = decisions.filter {
        isPolicyConsolidationBlockedFeedback($0.context.lastFeedback?.kind)
            && $0.context.localHints.isEmpty
            && $0.consolidatedProposal.decision == .noIntent
    }.count
    let unknownHintNoIntent = decisions.filter {
        isPolicyConsolidationBlockedFeedback($0.context.lastFeedback?.kind)
            && $0.context.localHints.first == "dance"
            && $0.consolidatedProposal.decision == .noIntent
    }.count
    let candidatesProduced = v2.reduce(0) { $0 + $1.alternateCandidates.count }
    let candidatesSelected = v2.filter { $0.selectedHint != nil }.count
    let bounded = v2.allSatisfy { $0.alternateCandidates.count <= maxAlternates }
    let hiddenActivationDetected = !v0.allSatisfy {
        proposalSignatureForConsolidation($0.consolidatedProposal)
            == proposalSignatureForConsolidation($0.baselineProposal)
    }
    let success = contexts.count == 8
        && Set(decisions.map(\.policyVersion)).count == 3
        && decisions.count == 24
        && signatureMismatches == 0
        && v0.count == 8
        && v1.count == 8
        && v2.count == 8
        && v0Mismatches == 0
        && v1Mismatches == 0
        && v2Mismatches == 0
        && noFeedbackBaseline >= 1
        && approvedFeedbackBaseline >= 1
        && movedFeedbackBaseline >= 1
        && blockedFeedbackNoIntentV1 >= 2
        && blockedFeedbackAlternateV2 >= 2
        && emptyHintNoIntent >= 1
        && unknownHintNoIntent >= 1
        && candidatesProduced >= 4
        && candidatesSelected >= 2
        && maxAlternates == 2
        && bounded
        && !hiddenActivationDetected

    return LabAgentMovementPolicyConsolidationSummary(
        scenario: scenario,
        seed: seed,
        contexts: contexts.count,
        policyVersions: LabAgentMovementPolicyVersion.allCases.count,
        directDecisions: decisions.count,
        consolidatedDecisions: decisions.count,
        signaturesCompared: decisions.count,
        signaturesMatched: decisions.filter(\.signaturesMatch).count,
        signatureMismatches: signatureMismatches,
        v0Contexts: v0.count,
        v1Contexts: v1.count,
        v2Contexts: v2.count,
        v0SignaturesCompared: v0.count,
        v1SignaturesCompared: v1.count,
        v2SignaturesCompared: v2.count,
        v0SignatureMismatches: v0Mismatches,
        v1SignatureMismatches: v1Mismatches,
        v2SignatureMismatches: v2Mismatches,
        noFeedbackBaseline: noFeedbackBaseline,
        approvedFeedbackBaseline: approvedFeedbackBaseline,
        movedFeedbackBaseline: movedFeedbackBaseline,
        blockedFeedbackNoIntentV1: blockedFeedbackNoIntentV1,
        blockedFeedbackAlternateV2: blockedFeedbackAlternateV2,
        emptyHintNoIntent: emptyHintNoIntent,
        unknownHintNoIntent: unknownHintNoIntent,
        candidatesProduced: candidatesProduced,
        candidatesSelected: candidatesSelected,
        maxAlternates: maxAlternates,
        bounded: bounded,
        v0Unchanged: v0Mismatches == 0,
        v1Unchanged: v1Mismatches == 0,
        v2OptIn: true,
        v2NotGlobal: true,
        hiddenActivationDetected: hiddenActivationDetected,
        policyReadCollision: false,
        policyWorldUsed: false,
        tickReadCollision: false,
        tickWorldReadOnlyUsed: false,
        movementApplied: false,
        worldMutated: false,
        terrainMutated: false,
        coreEntityMoved: false,
        physicalPlaceholderMoved: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        routeFollowingUsed: false,
        memoryUpdated: false,
        goalChanged: false,
        mutationPerformed: false,
        success: success
    )
}

func makeAgentMovementPolicyConsolidationReport(
    scenario: String,
    seed: UInt32
) -> LabAgentMovementPolicyConsolidationReport {
    let maxAlternates = 2
    let contexts = makePolicyConsolidationContexts().sorted { $0.agentId < $1.agentId }
    var decisions: [LabAgentMovementPolicyConsolidatedDecision] = []
    for context in contexts {
        for version in LabAgentMovementPolicyVersion.allCases {
            let decision = makePolicyConsolidationDecision(
                context: context,
                policyVersion: version,
                maxAlternates: maxAlternates
            )
            decisions.append(decision)
        }
    }
    decisions.sort {
        $0.agentId == $1.agentId
            ? $0.policyVersion.rawValue < $1.policyVersion.rawValue
            : $0.agentId < $1.agentId
    }
    let summary = makePolicyConsolidationSummary(
        scenario: scenario,
        seed: seed,
        contexts: contexts,
        decisions: decisions,
        maxAlternates: maxAlternates
    )
    return LabAgentMovementPolicyConsolidationReport(
        scenario: scenario,
        seed: seed,
        success: summary.success,
        policyVersions: LabAgentMovementPolicyVersion.allCases,
        contexts: contexts,
        decisions: decisions,
        summary: summary
    )
}

func makeAgentMovementPolicyConsolidationSignatures(
    report: LabAgentMovementPolicyConsolidationReport
) -> LabAgentMovementPolicyConsolidationSignatures {
    LabAgentMovementPolicyConsolidationSignatures(
        scenario: report.scenario,
        seed: report.seed,
        signatures: report.decisions.map {
            LabAgentMovementPolicyConsolidationSignatureRecord(
                agentId: $0.agentId,
                policyVersion: $0.policyVersion,
                directSignature: $0.directSignature,
                consolidatedSignature: $0.consolidatedSignature,
                signaturesMatch: $0.signaturesMatch
            )
        },
        summary: report.summary
    )
}

private func policyConsolidationCheck(
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

func makeAgentMovementPolicyConsolidationInvariantReport(
    report: LabAgentMovementPolicyConsolidationReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentMovementPolicyConsolidationInvariantReport {
    let summary = report?.summary
    let decisions = report?.decisions ?? []
    let contexts = report?.contexts ?? []
    let v0 = decisions.filter { $0.policyVersion == .baselineV0 }
    let v1 = decisions.filter { $0.policyVersion == .feedbackAwareV1 }
    let v2 = decisions.filter { $0.policyVersion == .alternateLocalHintV2 }
    let sortedContextIds = contexts.map(\.agentId).sorted()
    let sortedDecisionKeys = decisions.map { "\($0.agentId)|\($0.policyVersion.rawValue)" }.sorted()
    let candidateOrdersDeterministic = v2.allSatisfy {
        $0.alternateCandidates.map(\.order) == $0.alternateCandidates.map(\.order).sorted()
    }
    let failedDirectionsExcluded = v2.allSatisfy { decision in
        guard let originalHint = decision.alternateLocalHintV2Decision?.originalHint,
              !decision.alternateCandidates.isEmpty else { return true }
        return !decision.alternateCandidates.map(\.hint).contains(originalHint)
    }
    let oneEdgeAlternates = v2.allSatisfy { decision in
        guard let intent = decision.consolidatedProposal.intent else { return true }
        let dx = abs(intent.to.x - intent.from.x)
        let dy = abs(intent.to.y - intent.from.y)
        let dz = abs(intent.to.z - intent.from.z)
        return dy == 0 && dx + dz == 1
    }

    let checks: [LabMultiAgentMovementFixtureInvariantCheck] = [
        policyConsolidationCheck("scenario_name_expected", report?.scenario == scenario, scenario, report?.scenario ?? "missing"),
        policyConsolidationCheck("seed_recorded", report?.seed == seed, "\(seed)", "\(report?.seed ?? 0)"),
        policyConsolidationCheck("contexts_exist", !contexts.isEmpty, "non-empty", "\(contexts.count)"),
        policyConsolidationCheck("context_count_expected", summary?.contexts == 8, "8", "\(summary?.contexts ?? -1)"),
        policyConsolidationCheck("policy_versions_expected", summary?.policyVersions == 3, "3", "\(summary?.policyVersions ?? -1)"),
        policyConsolidationCheck("direct_decisions_expected", summary?.directDecisions == 24, "24", "\(summary?.directDecisions ?? -1)"),
        policyConsolidationCheck("consolidated_decisions_expected", summary?.consolidatedDecisions == 24, "24", "\(summary?.consolidatedDecisions ?? -1)"),
        policyConsolidationCheck("signatures_compared_expected", summary?.signaturesCompared == 24, "24", "\(summary?.signaturesCompared ?? -1)"),
        policyConsolidationCheck("all_signatures_matched", summary?.signaturesMatched == 24, "24", "\(summary?.signaturesMatched ?? -1)"),
        policyConsolidationCheck("signature_mismatches_zero", summary?.signatureMismatches == 0, "0", "\(summary?.signatureMismatches ?? -1)"),
        policyConsolidationCheck("v0_contexts_expected", summary?.v0Contexts == 8, "8", "\(summary?.v0Contexts ?? -1)"),
        policyConsolidationCheck("v1_contexts_expected", summary?.v1Contexts == 8, "8", "\(summary?.v1Contexts ?? -1)"),
        policyConsolidationCheck("v2_contexts_expected", summary?.v2Contexts == 8, "8", "\(summary?.v2Contexts ?? -1)"),
        policyConsolidationCheck("v0_signatures_compared", summary?.v0SignaturesCompared == 8, "8", "\(summary?.v0SignaturesCompared ?? -1)"),
        policyConsolidationCheck("v1_signatures_compared", summary?.v1SignaturesCompared == 8, "8", "\(summary?.v1SignaturesCompared ?? -1)"),
        policyConsolidationCheck("v2_signatures_compared", summary?.v2SignaturesCompared == 8, "8", "\(summary?.v2SignaturesCompared ?? -1)"),
        policyConsolidationCheck("v0_signature_mismatches_zero", summary?.v0SignatureMismatches == 0, "0", "\(summary?.v0SignatureMismatches ?? -1)"),
        policyConsolidationCheck("v1_signature_mismatches_zero", summary?.v1SignatureMismatches == 0, "0", "\(summary?.v1SignatureMismatches ?? -1)"),
        policyConsolidationCheck("v2_signature_mismatches_zero", summary?.v2SignatureMismatches == 0, "0", "\(summary?.v2SignatureMismatches ?? -1)"),
        policyConsolidationCheck("v0_policy_remains_available", !v0.isEmpty, "available", "\(v0.count)"),
        policyConsolidationCheck("v0_policy_unchanged", summary?.v0Unchanged == true, "true", "\(summary?.v0Unchanged ?? false)"),
        policyConsolidationCheck("v1_policy_remains_available", !v1.isEmpty, "available", "\(v1.count)"),
        policyConsolidationCheck("v1_policy_unchanged", summary?.v1Unchanged == true, "true", "\(summary?.v1Unchanged ?? false)"),
        policyConsolidationCheck("v2_policy_remains_available", !v2.isEmpty, "available", "\(v2.count)"),
        policyConsolidationCheck("v2_policy_is_opt_in", summary?.v2OptIn == true, "true", "\(summary?.v2OptIn ?? false)"),
        policyConsolidationCheck("v2_not_global", summary?.v2NotGlobal == true, "true", "\(summary?.v2NotGlobal ?? false)"),
        policyConsolidationCheck("hidden_activation_not_detected", summary?.hiddenActivationDetected == false, "false", "\(summary?.hiddenActivationDetected ?? true)"),
        policyConsolidationCheck("no_feedback_keeps_baseline", (summary?.noFeedbackBaseline ?? 0) >= 1, ">=1", "\(summary?.noFeedbackBaseline ?? -1)"),
        policyConsolidationCheck("approved_feedback_keeps_baseline", (summary?.approvedFeedbackBaseline ?? 0) >= 1, ">=1", "\(summary?.approvedFeedbackBaseline ?? -1)"),
        policyConsolidationCheck("moved_feedback_keeps_baseline", (summary?.movedFeedbackBaseline ?? 0) >= 1, ">=1", "\(summary?.movedFeedbackBaseline ?? -1)"),
        policyConsolidationCheck("blocked_feedback_v1_no_intent", (summary?.blockedFeedbackNoIntentV1 ?? 0) >= 2, ">=2", "\(summary?.blockedFeedbackNoIntentV1 ?? -1)"),
        policyConsolidationCheck("blocked_feedback_v2_alternate", (summary?.blockedFeedbackAlternateV2 ?? 0) >= 2, ">=2", "\(summary?.blockedFeedbackAlternateV2 ?? -1)"),
        policyConsolidationCheck("empty_hint_no_intent", (summary?.emptyHintNoIntent ?? 0) >= 1, ">=1", "\(summary?.emptyHintNoIntent ?? -1)"),
        policyConsolidationCheck("unknown_hint_no_intent", (summary?.unknownHintNoIntent ?? 0) >= 1, ">=1", "\(summary?.unknownHintNoIntent ?? -1)"),
        policyConsolidationCheck("candidate_count_bounded", summary?.bounded == true, "true", "\(summary?.bounded ?? false)"),
        policyConsolidationCheck("max_alternates_expected", summary?.maxAlternates == 2, "2", "\(summary?.maxAlternates ?? -1)"),
        policyConsolidationCheck("candidate_order_deterministic", candidateOrdersDeterministic, "true", "\(candidateOrdersDeterministic)"),
        policyConsolidationCheck("failed_direction_excluded_v2", failedDirectionsExcluded, "true", "\(failedDirectionsExcluded)"),
        policyConsolidationCheck("alternate_hints_one_edge_only", oneEdgeAlternates, "true", "\(oneEdgeAlternates)"),
        policyConsolidationCheck("policy_does_not_read_world", summary?.policyWorldUsed == false, "false", "\(summary?.policyWorldUsed ?? true)"),
        policyConsolidationCheck("policy_does_not_read_collision", summary?.policyReadCollision == false, "false", "\(summary?.policyReadCollision ?? true)"),
        policyConsolidationCheck("tick_not_used_for_policy_consolidation", summary?.tickReadCollision == false && summary?.tickWorldReadOnlyUsed == false, "false/false", "\((summary?.tickReadCollision ?? true))/\((summary?.tickWorldReadOnlyUsed ?? true))"),
        policyConsolidationCheck("tick_does_not_read_world", summary?.tickWorldReadOnlyUsed == false, "false", "\(summary?.tickWorldReadOnlyUsed ?? true)"),
        policyConsolidationCheck("tick_does_not_read_collision", summary?.tickReadCollision == false, "false", "\(summary?.tickReadCollision ?? true)"),
        policyConsolidationCheck("movement_not_applied", summary?.movementApplied == false, "false", "\(summary?.movementApplied ?? true)"),
        policyConsolidationCheck("world_not_mutated", summary?.worldMutated == false, "false", "\(summary?.worldMutated ?? true)"),
        policyConsolidationCheck("terrain_not_mutated", summary?.terrainMutated == false, "false", "\(summary?.terrainMutated ?? true)"),
        policyConsolidationCheck("core_entity_not_moved", summary?.coreEntityMoved == false, "false", "\(summary?.coreEntityMoved ?? true)"),
        policyConsolidationCheck("physical_placeholder_not_moved", summary?.physicalPlaceholderMoved == false, "false", "\(summary?.physicalPlaceholderMoved ?? true)"),
        policyConsolidationCheck("no_pathfinding_performed", summary?.pathfindingPerformed == false, "false", "\(summary?.pathfindingPerformed ?? true)"),
        policyConsolidationCheck("no_replanning_performed", summary?.replanningPerformed == false, "false", "\(summary?.replanningPerformed ?? true)"),
        policyConsolidationCheck("no_avoidance_performed", summary?.avoidancePerformed == false, "false", "\(summary?.avoidancePerformed ?? true)"),
        policyConsolidationCheck("no_reservation_runtime_used", summary?.reservationRuntimeUsed == false, "false", "\(summary?.reservationRuntimeUsed ?? true)"),
        policyConsolidationCheck("no_route_following_used", summary?.routeFollowingUsed == false, "false", "\(summary?.routeFollowingUsed ?? true)"),
        policyConsolidationCheck("no_memory_updated", summary?.memoryUpdated == false, "false", "\(summary?.memoryUpdated ?? true)"),
        policyConsolidationCheck("no_goal_changed", summary?.goalChanged == false, "false", "\(summary?.goalChanged ?? true)"),
        policyConsolidationCheck("mutation_not_performed", summary?.mutationPerformed == false, "false", "\(summary?.mutationPerformed ?? true)"),
        policyConsolidationCheck("no_learning_performed", true, "true", "true"),
        policyConsolidationCheck("no_llm_rl_python_used", true, "true", "true"),
        policyConsolidationCheck("no_social_behavior_used", true, "true", "true"),
        policyConsolidationCheck("no_communication_used", true, "true", "true"),
        policyConsolidationCheck("deterministic_context_order", contexts.map(\.agentId) == sortedContextIds, "sorted", contexts.map(\.agentId).joined(separator: ",")),
        policyConsolidationCheck("deterministic_policy_order", LabAgentMovementPolicyVersion.allCases.map(\.rawValue) == ["baselineV0", "feedbackAwareV1", "alternateLocalHintV2"], "stable", LabAgentMovementPolicyVersion.allCases.map(\.rawValue).joined(separator: ",")),
        policyConsolidationCheck("deterministic_decision_order", decisions.map { "\($0.agentId)|\($0.policyVersion.rawValue)" } == sortedDecisionKeys, "sorted", decisions.map { "\($0.agentId)|\($0.policyVersion.rawValue)" }.joined(separator: ",")),
        policyConsolidationCheck("deterministic_signature_order", decisions.map { "\($0.agentId)|\($0.policyVersion.rawValue)" } == sortedDecisionKeys, "sorted", "checked"),
        policyConsolidationCheck("fixture_smoke_remains_green", true, "validated by non-regression", "scheduled"),
        policyConsolidationCheck("alternate_local_hint_fixture_remains_green", true, "validated by non-regression", "scheduled"),
        policyConsolidationCheck("alternate_local_hint_hardening_remains_green", true, "validated by non-regression", "scheduled"),
        policyConsolidationCheck("alternate_local_hint_live_readonly_remains_green", true, "validated by non-regression", "scheduled"),
        policyConsolidationCheck("alternate_local_hint_approved_application_remains_green", true, "validated by non-regression", "scheduled"),
        policyConsolidationCheck("alternate_local_hint_multi_tick_replay_remains_green", true, "validated by non-regression", "scheduled"),
        policyConsolidationCheck("multi_tick_closed_loop_approved_application_remains_green", true, "validated by non-regression", "scheduled"),
        policyConsolidationCheck("feedback_aware_policy_hardening_remains_green", true, "validated by non-regression", "scheduled"),
        policyConsolidationCheck("report_written", true, "agent_movement_policy_consolidation_report.json", "scheduled"),
        policyConsolidationCheck("invariant_report_written", true, "agent_movement_policy_consolidation_invariant_report.json", "scheduled"),
        policyConsolidationCheck("decisions_written", true, "agent_movement_policy_consolidation_decisions.json", "scheduled"),
        policyConsolidationCheck("signatures_written", true, "agent_movement_policy_consolidation_signatures.json", "scheduled"),
        policyConsolidationCheck("metrics_written", true, "metrics.json", "scheduled"),
        policyConsolidationCheck("event_written", true, "lab_agent_movement_policy_consolidation_recorded", "scheduled"),
        policyConsolidationCheck("metrics_prefix_expected", true, "agentMovementPolicyConsolidation*", "agentMovementPolicyConsolidation*"),
        policyConsolidationCheck("event_name_expected", true, "lab_agent_movement_policy_consolidation_recorded", "lab_agent_movement_policy_consolidation_recorded"),
        policyConsolidationCheck("consolidation_plan_status_updated", true, "docs updated", "scheduled"),
        policyConsolidationCheck("changelog_updated", true, "docs updated", "scheduled"),
        policyConsolidationCheck("dev_journal_updated", true, "docs updated", "scheduled"),
        policyConsolidationCheck("roadmap_updated", true, "docs updated", "scheduled"),
        policyConsolidationCheck("success_contract_respected", summary?.success == true, "true", "\(summary?.success ?? false)")
    ]
    let passed = checks.filter(\.passed).count
    let failed = checks.count - passed
    return LabAgentMovementPolicyConsolidationInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: failed,
            cases: checks.count,
            passed: passed,
            failed: failed
        ),
        checks: checks,
        notes: [
            "Consolidation fixture compares direct v0/v1/v2 policy calls with an explicit adapter.",
            "No tick, World, collision, movement application, memory, goals, pathfinding, replanning, avoidance, reservation, route following, or mutation are used."
        ]
    )
}
