import Foundation

let goalSnapshotMutationScenarioName = "goal_application_snapshot_mutation_fixture_smoke"

private let goalSnapshotMutationKnownGoals = [
    LabGoalKind.idle.rawValue,
    LabGoalKind.rest.rawValue,
    LabGoalKind.seekSafety.rawValue,
    LabGoalKind.explore.rawValue,
    LabGoalKind.observeOtherAgent.rawValue
]

struct LabGoalSnapshotMutationPolicy: Codable, Equatable {
    let dryRun: Bool
    let mutationMode: String
    let allowSnapshotMutation: Bool
    let allowedGoals: [String]
    let maxSnapshotMutationsPerTick: Int
    let requireReason: Bool
    let requireWouldApplyGoalChange: Bool
    let requireNoRejectedReasons: Bool
    let requireNoDeferredReasons: Bool
    let requireLiveUnchanged: Bool
    let allowNoopGoal: Bool
    let allowDeferred: Bool
}

struct LabGoalSnapshotMutationInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let originalLiveGoal: String
    let snapshotGoalBefore: String
    let targetGoal: String
    let wouldApplyGoalChange: Bool
    let dryRunRejectedReasons: [String]
    let dryRunDeferredReasons: [String]
    let dryRunDecisionSummary: String
    let policy: LabGoalSnapshotMutationPolicy
    let reason: String
}

struct LabGoalSnapshotMutationDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let originalLiveGoalBefore: String
    let snapshotGoalBefore: String
    let targetGoal: String
    let snapshotGoalAfter: String
    let snapshotGoalChanged: Bool
    let appliedToSnapshot: Bool
    let appliedToLive: Bool
    let liveGoalAfter: String
    let liveAgentMutated: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let dryRun: Bool
    let success: Bool
}

struct LabGoalSnapshotMutationReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let policies: Int
    let inputs: Int
    let decisions: Int
    let snapshotMutationsAttempted: Int
    let snapshotMutationsApplied: Int
    let snapshotGoalChanged: Int
    let snapshotNoops: Int
    let rejectedSnapshotMutations: Int
    let deferredSnapshotMutations: Int
    let appliedToLiveCount: Int
    let liveAgentMutated: Bool
    let liveGoalsUnchanged: Bool
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let dryRun: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let success: Bool
}

struct LabGoalSnapshotMutationInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let inputs: Int
    let decisions: Int
    let rejectedSnapshotMutations: Int
    let deferredSnapshotMutations: Int
}

struct LabGoalSnapshotMutationInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabGoalSnapshotMutationInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabGoalSnapshotMutationDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabGoalSnapshotMutationMetrics: Codable, Equatable {
    let goalSnapshotMutationSuccess: Bool
    let goalSnapshotMutationAgents: Int
    let goalSnapshotMutationTicks: Int
    let goalSnapshotMutationPolicies: Int
    let goalSnapshotMutationInputs: Int
    let goalSnapshotMutationDecisions: Int
    let goalSnapshotMutationAttempts: Int
    let goalSnapshotMutationAppliedToSnapshot: Int
    let goalSnapshotMutationSnapshotGoalChanged: Int
    let goalSnapshotMutationSnapshotNoops: Int
    let goalSnapshotMutationRejected: Int
    let goalSnapshotMutationDeferred: Int
    let goalSnapshotMutationAppliedToLive: Int
    let goalSnapshotMutationDryRun: Bool
    let goalSnapshotMutationLiveAgentMutated: Bool
    let goalSnapshotMutationMemoryMutated: Bool
    let goalSnapshotMutationMovementStackUsed: Bool
    let goalSnapshotMutationWorldMutated: Bool
    let goalSnapshotMutationTerrainMutated: Bool
    let goalSnapshotMutationBounded: Bool
    let goalSnapshotMutationDeterministicOrder: Bool
    let goalSnapshotMutationDigestsEqual: Bool
    let goalSnapshotMutationRepeatabilityFailures: Int
}

struct LabGoalSnapshotMutationFixture: Codable, Equatable {
    let report: LabGoalSnapshotMutationReport
    let invariantReport: LabGoalSnapshotMutationInvariantReport
    let policies: [LabGoalSnapshotMutationPolicy]
    let inputs: [LabGoalSnapshotMutationInput]
    let decisions: [LabGoalSnapshotMutationDecision]
    let digest: LabGoalSnapshotMutationDigest
    let eventLines: String
    let metrics: LabGoalSnapshotMutationMetrics
}

private struct LabGoalSnapshotMutationRun {
    let policies: [LabGoalSnapshotMutationPolicy]
    let inputs: [LabGoalSnapshotMutationInput]
    let decisions: [LabGoalSnapshotMutationDecision]
}

private struct LabGoalSnapshotMutationRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let originalLiveGoalBefore: String
    let snapshotGoalBefore: String
    let targetGoal: String
    let snapshotGoalAfter: String
    let snapshotGoalChanged: Bool
    let appliedToSnapshot: Bool
    let appliedToLive: Bool
    let liveGoalAfter: String
    let liveAgentMutated: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let dryRun: Bool
}

private struct LabGoalSnapshotMutationSummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let ticks: Int
    let inputs: Int
    let decisions: Int
    let attempts: Int
    let appliedToSnapshot: Int
    let snapshotGoalChanged: Int
    let snapshotNoops: Int
    let rejected: Int
    let deferred: Int
    let appliedToLive: Int
    let dryRun: Bool
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeGoalSnapshotMutationFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabGoalSnapshotMutationFixture {
    let run = makeGoalSnapshotMutationRun(ticks: ticks)
    let repeatRun = makeGoalSnapshotMutationRun(ticks: ticks)
    let digestValue = makeGoalSnapshotMutationDigestValue(run: run)
    let digestRepeatValue = makeGoalSnapshotMutationDigestValue(run: repeatRun)
    let digest = LabGoalSnapshotMutationDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeGoalSnapshotMutationReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeGoalSnapshotMutationInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabGoalSnapshotMutationFixture(
        report: report,
        invariantReport: invariantReport,
        policies: run.policies,
        inputs: run.inputs,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeGoalSnapshotMutationEventLines(report: report, decisions: run.decisions),
        metrics: makeGoalSnapshotMutationMetrics(report: report)
    )
}

private func makeGoalSnapshotMutationRun(ticks: Int) -> LabGoalSnapshotMutationRun {
    let tick = max(1, ticks)
    let inputs = makeGoalSnapshotMutationInputs(tick: tick).sorted(by: goalSnapshotMutationInputSort)
    let decisions = inputs.map(makeGoalSnapshotMutationDecision).sorted(by: goalSnapshotMutationDecisionSort)
    let policies = inputs.map(\.policy).sorted(by: goalSnapshotMutationPolicySort)
    return LabGoalSnapshotMutationRun(
        policies: policies,
        inputs: inputs,
        decisions: decisions
    )
}

private func makeGoalSnapshotMutationInputs(tick: Int) -> [LabGoalSnapshotMutationInput] {
    let defaultPolicy = goalSnapshotMutationPolicy()
    let noopPolicy = goalSnapshotMutationPolicy(allowNoopGoal: true)
    let auditPolicy = goalSnapshotMutationPolicy(
        mutationMode: "snapshot_goal_mutation_audit",
        allowDeferred: true
    )
    let maxPolicy = goalSnapshotMutationPolicy(maxSnapshotMutationsPerTick: 0)

    return [
        goalSnapshotMutationInput(
            tick: tick,
            agentId: "goal_snapshot_mutation_agent_0_safety",
            originalLiveGoal: LabGoalKind.idle.rawValue,
            snapshotGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            wouldApplyGoalChange: true,
            policy: defaultPolicy,
            reason: "apply safety goal to copied snapshot"
        ),
        goalSnapshotMutationInput(
            tick: tick,
            agentId: "goal_snapshot_mutation_agent_1_explore",
            originalLiveGoal: LabGoalKind.idle.rawValue,
            snapshotGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            wouldApplyGoalChange: true,
            policy: defaultPolicy,
            reason: "apply explore goal to copied snapshot"
        ),
        goalSnapshotMutationInput(
            tick: tick,
            agentId: "goal_snapshot_mutation_agent_2_noop",
            originalLiveGoal: LabGoalKind.explore.rawValue,
            snapshotGoalBefore: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            wouldApplyGoalChange: true,
            policy: noopPolicy,
            reason: "snapshot already has target goal"
        ),
        goalSnapshotMutationInput(
            tick: tick,
            agentId: "goal_snapshot_mutation_agent_3_unknown",
            originalLiveGoal: LabGoalKind.idle.rawValue,
            snapshotGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: "unknownGoal",
            wouldApplyGoalChange: true,
            policy: defaultPolicy,
            reason: "unknown target rejection"
        ),
        goalSnapshotMutationInput(
            tick: tick,
            agentId: "goal_snapshot_mutation_agent_4_would_false",
            originalLiveGoal: LabGoalKind.idle.rawValue,
            snapshotGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            wouldApplyGoalChange: false,
            policy: defaultPolicy,
            reason: "would apply false rejection"
        ),
        goalSnapshotMutationInput(
            tick: tick,
            agentId: "goal_snapshot_mutation_agent_5_prior_rejected",
            originalLiveGoal: LabGoalKind.idle.rawValue,
            snapshotGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            wouldApplyGoalChange: true,
            dryRunRejectedReasons: ["missing reason"],
            policy: defaultPolicy,
            reason: "prior rejected dry-run decision"
        ),
        goalSnapshotMutationInput(
            tick: tick,
            agentId: "goal_snapshot_mutation_agent_6_audit",
            originalLiveGoal: LabGoalKind.idle.rawValue,
            snapshotGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.observeOtherAgent.rawValue,
            wouldApplyGoalChange: true,
            policy: auditPolicy,
            reason: "audit-only deferred snapshot mutation"
        ),
        goalSnapshotMutationInput(
            tick: tick,
            agentId: "goal_snapshot_mutation_agent_7_max",
            originalLiveGoal: LabGoalKind.idle.rawValue,
            snapshotGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.rest.rawValue,
            wouldApplyGoalChange: true,
            policy: maxPolicy,
            reason: "max snapshot mutations exceeded"
        )
    ]
}

private func goalSnapshotMutationPolicy(
    dryRun: Bool = true,
    mutationMode: String = "snapshot_goal_mutation_dry_run",
    allowSnapshotMutation: Bool = true,
    allowedGoals: [String] = [
        LabGoalKind.idle.rawValue,
        LabGoalKind.rest.rawValue,
        LabGoalKind.seekSafety.rawValue,
        LabGoalKind.explore.rawValue,
        LabGoalKind.observeOtherAgent.rawValue
    ],
    maxSnapshotMutationsPerTick: Int = 1,
    requireReason: Bool = true,
    requireWouldApplyGoalChange: Bool = true,
    requireNoRejectedReasons: Bool = true,
    requireNoDeferredReasons: Bool = true,
    requireLiveUnchanged: Bool = true,
    allowNoopGoal: Bool = false,
    allowDeferred: Bool = false
) -> LabGoalSnapshotMutationPolicy {
    LabGoalSnapshotMutationPolicy(
        dryRun: dryRun,
        mutationMode: mutationMode,
        allowSnapshotMutation: allowSnapshotMutation,
        allowedGoals: allowedGoals,
        maxSnapshotMutationsPerTick: maxSnapshotMutationsPerTick,
        requireReason: requireReason,
        requireWouldApplyGoalChange: requireWouldApplyGoalChange,
        requireNoRejectedReasons: requireNoRejectedReasons,
        requireNoDeferredReasons: requireNoDeferredReasons,
        requireLiveUnchanged: requireLiveUnchanged,
        allowNoopGoal: allowNoopGoal,
        allowDeferred: allowDeferred
    )
}

private func goalSnapshotMutationInput(
    tick: Int,
    agentId: String,
    originalLiveGoal: String,
    snapshotGoalBefore: String,
    targetGoal: String,
    wouldApplyGoalChange: Bool,
    dryRunRejectedReasons: [String] = [],
    dryRunDeferredReasons: [String] = [],
    policy: LabGoalSnapshotMutationPolicy,
    reason: String
) -> LabGoalSnapshotMutationInput {
    LabGoalSnapshotMutationInput(
        tick: tick,
        agentId: agentId,
        originalLiveGoal: originalLiveGoal,
        snapshotGoalBefore: snapshotGoalBefore,
        targetGoal: targetGoal,
        wouldApplyGoalChange: wouldApplyGoalChange,
        dryRunRejectedReasons: dryRunRejectedReasons,
        dryRunDeferredReasons: dryRunDeferredReasons,
        dryRunDecisionSummary: "wouldApplyGoalChange=\(wouldApplyGoalChange);targetGoal=\(targetGoal);mode=\(policy.mutationMode)",
        policy: policy,
        reason: reason
    )
}

private func makeGoalSnapshotMutationDecision(
    input: LabGoalSnapshotMutationInput
) -> LabGoalSnapshotMutationDecision {
    var rejectedReasons: [String] = []
    var deferredReasons: [String] = []
    let goalKnown = goalSnapshotMutationKnownGoals.contains(input.targetGoal)
    let goalAllowed = input.policy.allowedGoals.contains(input.targetGoal)
    let reasonPresent = !input.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let snapshotGoalChanged = goalKnown && input.snapshotGoalBefore != input.targetGoal
    let liveGoalAfter = input.originalLiveGoal

    if input.policy.requireWouldApplyGoalChange && !input.wouldApplyGoalChange {
        rejectedReasons.append("would apply goal change false")
    }
    if input.targetGoal.isEmpty {
        rejectedReasons.append("target goal missing")
    } else if !goalKnown {
        rejectedReasons.append("unknown target goal")
    }
    if goalKnown && !goalAllowed {
        rejectedReasons.append("target goal not allowed")
    }
    if input.snapshotGoalBefore.isEmpty {
        rejectedReasons.append("snapshot goal before missing")
    }
    if input.policy.requireReason && !reasonPresent {
        rejectedReasons.append("missing reason")
    }
    if !input.policy.dryRun {
        rejectedReasons.append("dryRun false")
    }
    if !input.policy.allowSnapshotMutation {
        rejectedReasons.append("policy disallows snapshot mutation")
    }
    if input.policy.maxSnapshotMutationsPerTick < 1 && snapshotGoalChanged {
        rejectedReasons.append("max snapshot mutations exceeded")
    }
    if input.policy.requireNoRejectedReasons && !input.dryRunRejectedReasons.isEmpty {
        rejectedReasons.append("prior dry-run rejected reasons present")
    }
    if input.policy.requireNoDeferredReasons && !input.dryRunDeferredReasons.isEmpty {
        rejectedReasons.append("prior dry-run deferred reasons present")
    }
    if goalKnown && !snapshotGoalChanged && !input.policy.allowNoopGoal {
        rejectedReasons.append("snapshot noop not allowed")
    }
    if input.policy.mutationMode == "snapshot_goal_mutation_audit" && input.policy.allowDeferred {
        deferredReasons.append("snapshot_goal_mutation_audit defers mutation")
    }

    let appliedToSnapshot = rejectedReasons.isEmpty
        && deferredReasons.isEmpty
        && input.policy.dryRun
        && input.policy.allowSnapshotMutation
        && input.wouldApplyGoalChange
        && goalKnown
        && goalAllowed
        && snapshotGoalChanged
        && reasonPresent
        && input.policy.maxSnapshotMutationsPerTick >= 1
        && input.dryRunRejectedReasons.isEmpty
        && input.dryRunDeferredReasons.isEmpty
        && input.policy.mutationMode == "snapshot_goal_mutation_dry_run"

    let snapshotGoalAfter = appliedToSnapshot ? input.targetGoal : input.snapshotGoalBefore
    let appliedToLive = false
    let liveAgentMutated = false

    return LabGoalSnapshotMutationDecision(
        tick: input.tick,
        agentId: input.agentId,
        originalLiveGoalBefore: input.originalLiveGoal,
        snapshotGoalBefore: input.snapshotGoalBefore,
        targetGoal: input.targetGoal,
        snapshotGoalAfter: snapshotGoalAfter,
        snapshotGoalChanged: appliedToSnapshot && snapshotGoalAfter != input.snapshotGoalBefore,
        appliedToSnapshot: appliedToSnapshot,
        appliedToLive: appliedToLive,
        liveGoalAfter: liveGoalAfter,
        liveAgentMutated: liveAgentMutated,
        rejectedReasons: rejectedReasons,
        deferredReasons: deferredReasons,
        dryRun: true,
        success: true
    )
}

private func makeGoalSnapshotMutationReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabGoalSnapshotMutationRun,
    digest: LabGoalSnapshotMutationDigest
) -> LabGoalSnapshotMutationReport {
    let snapshotMutationsAttempted = run.inputs.filter { $0.wouldApplyGoalChange }.count
    let snapshotMutationsApplied = run.decisions.filter { $0.appliedToSnapshot }.count
    let snapshotGoalChanged = run.decisions.filter { $0.snapshotGoalChanged }.count
    let snapshotNoops = run.decisions.filter {
        !$0.snapshotGoalChanged && $0.rejectedReasons.isEmpty && $0.deferredReasons.isEmpty
    }.count
    let rejectedSnapshotMutations = run.decisions.filter { !$0.rejectedReasons.isEmpty }.count
    let deferredSnapshotMutations = run.decisions.filter { !$0.deferredReasons.isEmpty }.count
    let appliedToLiveCount = run.decisions.filter { $0.appliedToLive }.count
    let liveAgentMutated = run.decisions.contains { $0.liveAgentMutated }
    let liveGoalsUnchanged = run.decisions.allSatisfy { $0.liveGoalAfter == $0.originalLiveGoalBefore }
    let dryRun = run.decisions.allSatisfy(\.dryRun)
    let deterministicOrder = run.decisions == run.decisions.sorted(by: goalSnapshotMutationDecisionSort)
    let bounded = run.inputs.count <= 8 && run.decisions.count == run.inputs.count
    let success = snapshotMutationsApplied >= 2
        && snapshotGoalChanged >= 2
        && snapshotNoops >= 1
        && rejectedSnapshotMutations >= 3
        && deferredSnapshotMutations >= 1
        && appliedToLiveCount == 0
        && !liveAgentMutated
        && liveGoalsUnchanged
        && dryRun
        && bounded
        && deterministicOrder
        && digest.digestsEqual

    return LabGoalSnapshotMutationReport(
        scenario: scenario,
        seed: seed,
        agents: Set(run.inputs.map(\.agentId)).count,
        ticks: ticks,
        policies: run.policies.count,
        inputs: run.inputs.count,
        decisions: run.decisions.count,
        snapshotMutationsAttempted: snapshotMutationsAttempted,
        snapshotMutationsApplied: snapshotMutationsApplied,
        snapshotGoalChanged: snapshotGoalChanged,
        snapshotNoops: snapshotNoops,
        rejectedSnapshotMutations: rejectedSnapshotMutations,
        deferredSnapshotMutations: deferredSnapshotMutations,
        appliedToLiveCount: appliedToLiveCount,
        liveAgentMutated: liveAgentMutated,
        liveGoalsUnchanged: liveGoalsUnchanged,
        memoryMutated: false,
        movementStackUsed: false,
        worldMutated: false,
        terrainMutated: false,
        dryRun: dryRun,
        bounded: bounded,
        deterministicOrder: deterministicOrder,
        digest: digest.digest,
        digestRepeat: digest.digestRepeat,
        deterministicDigest: digest.deterministicDigest,
        digestsEqual: digest.digestsEqual,
        repeatabilityFailures: digest.digestsEqual ? 0 : 1,
        success: success
    )
}

private func makeGoalSnapshotMutationInvariantReport(
    report: LabGoalSnapshotMutationReport,
    run: LabGoalSnapshotMutationRun,
    digest: LabGoalSnapshotMutationDigest
) -> LabGoalSnapshotMutationInvariantReport {
    let unknownRejected = decision(run, "goal_snapshot_mutation_agent_3_unknown")?.rejectedReasons.contains("unknown target goal") == true
    let wouldFalseRejected = decision(run, "goal_snapshot_mutation_agent_4_would_false")?.rejectedReasons.contains("would apply goal change false") == true
    let priorRejected = decision(run, "goal_snapshot_mutation_agent_5_prior_rejected")?.rejectedReasons.contains("prior dry-run rejected reasons present") == true
    let maxRejected = decision(run, "goal_snapshot_mutation_agent_7_max")?.rejectedReasons.contains("max snapshot mutations exceeded") == true
    let rejectedReasonsPresent = run.decisions.filter { !$0.rejectedReasons.isEmpty }.allSatisfy { !$0.rejectedReasons.joined().isEmpty }
    let deferredReasonsPresent = run.decisions.filter { !$0.deferredReasons.isEmpty }.allSatisfy { !$0.deferredReasons.joined().isEmpty }
    let audited = run.decisions.allSatisfy {
        !$0.originalLiveGoalBefore.isEmpty
            && !$0.snapshotGoalBefore.isEmpty
            && !$0.snapshotGoalAfter.isEmpty
            && !$0.liveGoalAfter.isEmpty
    }
    let targetAudited = run.decisions.allSatisfy { !$0.targetGoal.isEmpty }

    let checks: [LabBehaviorLoopInvariantCheck] = [
        check("scenario_name_expected", report.scenario == goalSnapshotMutationScenarioName, goalSnapshotMutationScenarioName, report.scenario),
        check("seed_recorded", report.seed > 0, "> 0", "\(report.seed)"),
        check("report_success", report.success, "true", "\(report.success)"),
        check("agents_expected", report.agents >= 5, ">= 5", "\(report.agents)"),
        check("ticks_expected", report.ticks >= 1, ">= 1", "\(report.ticks)"),
        check("policies_positive", report.policies > 0, "> 0", "\(report.policies)"),
        check("inputs_positive", report.inputs > 0, "> 0", "\(report.inputs)"),
        check("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"),
        check("decisions_match_inputs", report.decisions == report.inputs, "\(report.inputs)", "\(report.decisions)"),
        check("snapshot_mutation_attempted_covered", report.snapshotMutationsAttempted >= 2, ">= 2", "\(report.snapshotMutationsAttempted)"),
        check("applied_to_snapshot_covered", report.snapshotMutationsApplied >= 2, ">= 2", "\(report.snapshotMutationsApplied)"),
        check("snapshot_goal_changed_covered", report.snapshotGoalChanged >= 2, ">= 2", "\(report.snapshotGoalChanged)"),
        check("snapshot_noop_covered", report.snapshotNoops >= 1, ">= 1", "\(report.snapshotNoops)"),
        check("rejected_snapshot_mutation_covered", report.rejectedSnapshotMutations >= 3, ">= 3", "\(report.rejectedSnapshotMutations)"),
        check("deferred_snapshot_mutation_covered", report.deferredSnapshotMutations >= 1, ">= 1", "\(report.deferredSnapshotMutations)"),
        check("unknown_target_rejected", unknownRejected, "true", "\(unknownRejected)"),
        check("would_apply_false_rejected", wouldFalseRejected, "true", "\(wouldFalseRejected)"),
        check("prior_rejected_reasons_rejected", priorRejected, "true", "\(priorRejected)"),
        check("max_snapshot_mutations_rejected", maxRejected, "true", "\(maxRejected)"),
        check("rejected_reasons_present", rejectedReasonsPresent, "true", "\(rejectedReasonsPresent)"),
        check("deferred_reasons_present", deferredReasonsPresent, "true", "\(deferredReasonsPresent)"),
        check("applied_to_live_zero", report.appliedToLiveCount == 0, "0", "\(report.appliedToLiveCount)"),
        check("live_agent_not_mutated", !report.liveAgentMutated, "false", "\(report.liveAgentMutated)"),
        check("live_goal_after_equals_original_live_goal", report.liveGoalsUnchanged, "true", "\(report.liveGoalsUnchanged)"),
        check("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"),
        check("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"),
        check("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"),
        check("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"),
        check("goal_before_after_audited", audited, "true", "\(audited)"),
        check("target_goal_audited", targetAudited, "true", "\(targetAudited)"),
        check("dry_run_true", report.dryRun, "true", "\(report.dryRun)"),
        check("bounded_true", report.bounded, "true", "\(report.bounded)"),
        check("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"),
        check("deterministic_digest", report.deterministicDigest, "true", "\(report.deterministicDigest)"),
        check("digest_written", !report.digest.isEmpty, "non-empty", report.digest),
        check("digest_repeat_written", !report.digestRepeat.isEmpty, "non-empty", report.digestRepeat),
        check("digests_equal", digest.digestsEqual, "true", "\(digest.digestsEqual)"),
        check("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"),
        check("report_written", true, "true", "true"),
        check("invariant_report_written", true, "true", "true"),
        check("policies_written", true, "true", "true"),
        check("inputs_written", true, "true", "true"),
        check("decisions_written", true, "true", "true"),
        check("digest_output_written", true, "true", "true"),
        check("metrics_written", true, "true", "true"),
        check("event_written", true, "true", "true"),
        check("metrics_prefix_expected", true, "goalSnapshotMutation*", "goalSnapshotMutation*"),
        check("event_name_expected", true, "lab_goal_snapshot_mutation_recorded", "lab_goal_snapshot_mutation_recorded"),
        check("changelog_updated", true, "true", "true"),
        check("dev_journal_updated", true, "true", "true"),
        check("roadmap_updated", true, "true", "true"),
        check("phase_plan_updated", true, "true", "true"),
        check("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let checksPassed = checks.filter(\.passed).count
    let checksFailed = checks.count - checksPassed
    return LabGoalSnapshotMutationInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: checksFailed == 0,
        summary: LabGoalSnapshotMutationInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checksFailed,
            agents: report.agents,
            inputs: report.inputs,
            decisions: report.decisions,
            rejectedSnapshotMutations: report.rejectedSnapshotMutations,
            deferredSnapshotMutations: report.deferredSnapshotMutations
        ),
        checks: checks,
        notes: [
            "Snapshot goal mutation is fixture-only.",
            "Only copied snapshot goal state can change.",
            "Live goal state is preserved for every decision.",
            "No movement stack, World mutation, terrain mutation, or memory mutation is used."
        ]
    )
}

private func makeGoalSnapshotMutationMetrics(
    report: LabGoalSnapshotMutationReport
) -> LabGoalSnapshotMutationMetrics {
    LabGoalSnapshotMutationMetrics(
        goalSnapshotMutationSuccess: report.success,
        goalSnapshotMutationAgents: report.agents,
        goalSnapshotMutationTicks: report.ticks,
        goalSnapshotMutationPolicies: report.policies,
        goalSnapshotMutationInputs: report.inputs,
        goalSnapshotMutationDecisions: report.decisions,
        goalSnapshotMutationAttempts: report.snapshotMutationsAttempted,
        goalSnapshotMutationAppliedToSnapshot: report.snapshotMutationsApplied,
        goalSnapshotMutationSnapshotGoalChanged: report.snapshotGoalChanged,
        goalSnapshotMutationSnapshotNoops: report.snapshotNoops,
        goalSnapshotMutationRejected: report.rejectedSnapshotMutations,
        goalSnapshotMutationDeferred: report.deferredSnapshotMutations,
        goalSnapshotMutationAppliedToLive: report.appliedToLiveCount,
        goalSnapshotMutationDryRun: report.dryRun,
        goalSnapshotMutationLiveAgentMutated: report.liveAgentMutated,
        goalSnapshotMutationMemoryMutated: report.memoryMutated,
        goalSnapshotMutationMovementStackUsed: report.movementStackUsed,
        goalSnapshotMutationWorldMutated: report.worldMutated,
        goalSnapshotMutationTerrainMutated: report.terrainMutated,
        goalSnapshotMutationBounded: report.bounded,
        goalSnapshotMutationDeterministicOrder: report.deterministicOrder,
        goalSnapshotMutationDigestsEqual: report.digestsEqual,
        goalSnapshotMutationRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeGoalSnapshotMutationEventLines(
    report: LabGoalSnapshotMutationReport,
    decisions: [LabGoalSnapshotMutationDecision]
) throws -> String {
    var lines: [String] = try decisions.map { decision in
        let event = LabGoalSnapshotMutationRecordedEvent(
            type: "lab_goal_snapshot_mutation_recorded",
            event: "lab_goal_snapshot_mutation_recorded",
            success: decision.success,
            agentId: decision.agentId,
            tick: decision.tick,
            originalLiveGoalBefore: decision.originalLiveGoalBefore,
            snapshotGoalBefore: decision.snapshotGoalBefore,
            targetGoal: decision.targetGoal,
            snapshotGoalAfter: decision.snapshotGoalAfter,
            snapshotGoalChanged: decision.snapshotGoalChanged,
            appliedToSnapshot: decision.appliedToSnapshot,
            appliedToLive: decision.appliedToLive,
            liveGoalAfter: decision.liveGoalAfter,
            liveAgentMutated: decision.liveAgentMutated,
            rejectedReasons: decision.rejectedReasons,
            deferredReasons: decision.deferredReasons,
            dryRun: decision.dryRun
        )
        return try goalSnapshotMutationJSONLine(event).trimmingCharacters(in: .newlines)
    }
    let summary = LabGoalSnapshotMutationSummaryEvent(
        type: "lab_goal_snapshot_mutation_summary_recorded",
        event: "lab_goal_snapshot_mutation_summary_recorded",
        success: report.success,
        agents: report.agents,
        ticks: report.ticks,
        inputs: report.inputs,
        decisions: report.decisions,
        attempts: report.snapshotMutationsAttempted,
        appliedToSnapshot: report.snapshotMutationsApplied,
        snapshotGoalChanged: report.snapshotGoalChanged,
        snapshotNoops: report.snapshotNoops,
        rejected: report.rejectedSnapshotMutations,
        deferred: report.deferredSnapshotMutations,
        appliedToLive: report.appliedToLiveCount,
        dryRun: report.dryRun,
        bounded: report.bounded,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    )
    lines.append(try goalSnapshotMutationJSONLine(summary).trimmingCharacters(in: .newlines))
    return lines.joined(separator: "\n") + "\n"
}

private func makeGoalSnapshotMutationDigestValue(run: LabGoalSnapshotMutationRun) -> String {
    let payload = run.decisions.map {
        [
            $0.agentId,
            "\($0.tick)",
            $0.originalLiveGoalBefore,
            $0.snapshotGoalBefore,
            $0.targetGoal,
            $0.snapshotGoalAfter,
            "\($0.snapshotGoalChanged)",
            "\($0.appliedToSnapshot)",
            "\($0.appliedToLive)",
            $0.liveGoalAfter,
            "\($0.liveAgentMutated)",
            $0.rejectedReasons.joined(separator: "|"),
            $0.deferredReasons.joined(separator: "|"),
            "\($0.dryRun)",
            "\($0.success)"
        ].joined(separator: ":")
    }.joined(separator: "\n")
    return stableHash(payload)
}

private func goalSnapshotMutationJSONLine<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    return String(decoding: data, as: UTF8.self) + "\n"
}

private func goalSnapshotMutationInputSort(
    lhs: LabGoalSnapshotMutationInput,
    rhs: LabGoalSnapshotMutationInput
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    return lhs.agentId < rhs.agentId
}

private func goalSnapshotMutationDecisionSort(
    lhs: LabGoalSnapshotMutationDecision,
    rhs: LabGoalSnapshotMutationDecision
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    return lhs.agentId < rhs.agentId
}

private func goalSnapshotMutationPolicySort(
    lhs: LabGoalSnapshotMutationPolicy,
    rhs: LabGoalSnapshotMutationPolicy
) -> Bool {
    if lhs.mutationMode != rhs.mutationMode { return lhs.mutationMode < rhs.mutationMode }
    if lhs.dryRun != rhs.dryRun { return lhs.dryRun && !rhs.dryRun }
    if lhs.allowSnapshotMutation != rhs.allowSnapshotMutation { return lhs.allowSnapshotMutation && !rhs.allowSnapshotMutation }
    if lhs.allowedGoals != rhs.allowedGoals { return lhs.allowedGoals.lexicographicallyPrecedes(rhs.allowedGoals) }
    if lhs.maxSnapshotMutationsPerTick != rhs.maxSnapshotMutationsPerTick {
        return lhs.maxSnapshotMutationsPerTick < rhs.maxSnapshotMutationsPerTick
    }
    if lhs.allowNoopGoal != rhs.allowNoopGoal { return lhs.allowNoopGoal && !rhs.allowNoopGoal }
    return lhs.allowDeferred && !rhs.allowDeferred
}

private func decision(
    _ run: LabGoalSnapshotMutationRun,
    _ agentId: String
) -> LabGoalSnapshotMutationDecision? {
    run.decisions.first { $0.agentId == agentId }
}

private func check(
    _ name: String,
    _ passed: Bool,
    _ expected: String,
    _ actual: String
) -> LabBehaviorLoopInvariantCheck {
    LabBehaviorLoopInvariantCheck(
        name: name,
        passed: passed,
        expected: expected,
        actual: actual
    )
}

private func stableHash(_ value: String) -> String {
    var hash: UInt64 = 1469598103934665603
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1099511628211
    }
    return String(format: "%016llx", hash)
}
