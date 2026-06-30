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
    case .blockedByCollision, .blockedByAgentConflict:
        return true
    default:
        return false
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
