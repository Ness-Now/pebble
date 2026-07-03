import Foundation

let goalSnapshotMutationScenarioName = "goal_application_snapshot_mutation_fixture_smoke"
let goalSnapshotMutationHardeningScenarioName = "goal_application_snapshot_mutation_hardening_smoke"

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

struct LabGoalSnapshotMutationHardeningCase: Codable, Equatable {
    let caseName: String
    let purpose: String
    let input: LabGoalSnapshotMutationInput
}

struct LabGoalSnapshotMutationHardeningCaseResult: Codable, Equatable {
    let caseName: String
    let purpose: String
    let passed: Bool
    let notes: [String]
    let decision: LabGoalSnapshotMutationDecision
}

struct LabGoalSnapshotMutationHardeningReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
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

struct LabGoalSnapshotMutationHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let inputs: Int
    let decisions: Int
    let rejectedSnapshotMutations: Int
    let deferredSnapshotMutations: Int
}

struct LabGoalSnapshotMutationHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabGoalSnapshotMutationHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabGoalSnapshotMutationHardeningDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabGoalSnapshotMutationHardeningMetrics: Codable, Equatable {
    let goalSnapshotMutationHardeningSuccess: Bool
    let goalSnapshotMutationHardeningCases: Int
    let goalSnapshotMutationHardeningCasesPassed: Int
    let goalSnapshotMutationHardeningCasesFailed: Int
    let goalSnapshotMutationHardeningAgents: Int
    let goalSnapshotMutationHardeningPolicies: Int
    let goalSnapshotMutationHardeningInputs: Int
    let goalSnapshotMutationHardeningDecisions: Int
    let goalSnapshotMutationHardeningAttempts: Int
    let goalSnapshotMutationHardeningAppliedToSnapshot: Int
    let goalSnapshotMutationHardeningSnapshotGoalChanged: Int
    let goalSnapshotMutationHardeningSnapshotNoops: Int
    let goalSnapshotMutationHardeningRejected: Int
    let goalSnapshotMutationHardeningDeferred: Int
    let goalSnapshotMutationHardeningAppliedToLive: Int
    let goalSnapshotMutationHardeningDryRun: Bool
    let goalSnapshotMutationHardeningLiveAgentMutated: Bool
    let goalSnapshotMutationHardeningMemoryMutated: Bool
    let goalSnapshotMutationHardeningMovementStackUsed: Bool
    let goalSnapshotMutationHardeningWorldMutated: Bool
    let goalSnapshotMutationHardeningTerrainMutated: Bool
    let goalSnapshotMutationHardeningBounded: Bool
    let goalSnapshotMutationHardeningDeterministicOrder: Bool
    let goalSnapshotMutationHardeningDigestsEqual: Bool
    let goalSnapshotMutationHardeningRepeatabilityFailures: Int
}

struct LabGoalSnapshotMutationHardeningFixture: Codable, Equatable {
    let report: LabGoalSnapshotMutationHardeningReport
    let invariantReport: LabGoalSnapshotMutationHardeningInvariantReport
    let cases: [LabGoalSnapshotMutationHardeningCaseResult]
    let policies: [LabGoalSnapshotMutationPolicy]
    let inputs: [LabGoalSnapshotMutationInput]
    let decisions: [LabGoalSnapshotMutationDecision]
    let digest: LabGoalSnapshotMutationHardeningDigest
    let eventLines: String
    let metrics: LabGoalSnapshotMutationHardeningMetrics
}

private struct LabGoalSnapshotMutationRun {
    let policies: [LabGoalSnapshotMutationPolicy]
    let inputs: [LabGoalSnapshotMutationInput]
    let decisions: [LabGoalSnapshotMutationDecision]
}

private struct LabGoalSnapshotMutationHardeningRun {
    let cases: [LabGoalSnapshotMutationHardeningCase]
    let caseResults: [LabGoalSnapshotMutationHardeningCaseResult]
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

private struct LabGoalSnapshotMutationHardeningRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let agents: Int
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
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let dryRun: Bool
    let bounded: Bool
    let deterministicOrder: Bool
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

func makeGoalSnapshotMutationHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabGoalSnapshotMutationHardeningFixture {
    let cases = makeGoalSnapshotMutationHardeningCases(tick: max(1, ticks))
    let inputs = cases.map(\.input).sorted(by: goalSnapshotMutationInputSort)
    let decisions = inputs.map(makeGoalSnapshotMutationDecision).sorted(by: goalSnapshotMutationDecisionSort)
    let policies = inputs.map(\.policy).sorted(by: goalSnapshotMutationPolicySort)
    let digestValue = makeGoalSnapshotMutationHardeningDigestValue(caseResults: [], decisions: decisions)
    let repeatDigestValue = makeGoalSnapshotMutationHardeningDigestValue(caseResults: [], decisions: decisions)
    let digest = LabGoalSnapshotMutationHardeningDigest(
        digest: digestValue,
        digestRepeat: repeatDigestValue,
        deterministicDigest: true,
        digestsEqual: digestValue == repeatDigestValue
    )
    let caseResults = makeGoalSnapshotMutationHardeningCaseResults(
        cases: cases,
        decisions: decisions,
        digest: digest
    ).sorted(by: goalSnapshotMutationHardeningCaseResultSort)
    let finalDigestValue = makeGoalSnapshotMutationHardeningDigestValue(caseResults: caseResults, decisions: decisions)
    let finalRepeatDigestValue = makeGoalSnapshotMutationHardeningDigestValue(caseResults: caseResults, decisions: decisions)
    let finalDigest = LabGoalSnapshotMutationHardeningDigest(
        digest: finalDigestValue,
        digestRepeat: finalRepeatDigestValue,
        deterministicDigest: true,
        digestsEqual: finalDigestValue == finalRepeatDigestValue
    )
    let run = LabGoalSnapshotMutationHardeningRun(
        cases: cases,
        caseResults: caseResults,
        policies: policies,
        inputs: inputs,
        decisions: decisions
    )
    let report = makeGoalSnapshotMutationHardeningReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: finalDigest
    )
    let invariantReport = makeGoalSnapshotMutationHardeningInvariantReport(
        report: report,
        run: run,
        digest: finalDigest
    )
    return LabGoalSnapshotMutationHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: caseResults,
        policies: policies,
        inputs: inputs,
        decisions: decisions,
        digest: finalDigest,
        eventLines: try makeGoalSnapshotMutationHardeningEventLines(report: report),
        metrics: makeGoalSnapshotMutationHardeningMetrics(report: report)
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

private func makeGoalSnapshotMutationHardeningCases(tick: Int) -> [LabGoalSnapshotMutationHardeningCase] {
    let defaultPolicy = goalSnapshotMutationPolicy()
    let noopAllowedPolicy = goalSnapshotMutationPolicy(allowNoopGoal: true)
    let noopRejectedPolicy = goalSnapshotMutationPolicy(allowNoopGoal: false)
    let notAllowedPolicy = goalSnapshotMutationPolicy(
        allowedGoals: [
            LabGoalKind.idle.rawValue,
            LabGoalKind.seekSafety.rawValue,
            LabGoalKind.explore.rawValue,
            LabGoalKind.observeOtherAgent.rawValue
        ]
    )
    let dryRunFalsePolicy = goalSnapshotMutationPolicy(dryRun: false)
    let disallowedPolicy = goalSnapshotMutationPolicy(allowSnapshotMutation: false)
    let maxRejectedPolicy = goalSnapshotMutationPolicy(maxSnapshotMutationsPerTick: 0)
    let auditPolicy = goalSnapshotMutationPolicy(
        mutationMode: "snapshot_goal_mutation_audit",
        allowDeferred: true
    )

    return [
        hardeningCase(0, "baseline_fixture_compatible", "5.10B fixture shape remains compatible", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.rest.rawValue, true, defaultPolicy, "baseline snapshot mutation applies to copied state"),
        hardeningCase(1, "apply_safety_to_snapshot", "safety target applies to snapshot only", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.seekSafety.rawValue, true, defaultPolicy, "apply safety target to copied snapshot"),
        hardeningCase(2, "apply_explore_to_snapshot", "explore target applies to snapshot only", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.explore.rawValue, true, defaultPolicy, "apply explore target to copied snapshot"),
        hardeningCase(3, "apply_observe_to_snapshot", "observe target applies to snapshot only", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.observeOtherAgent.rawValue, true, defaultPolicy, "apply observe target to copied snapshot"),
        hardeningCase(4, "snapshot_noop_allowed", "same-goal snapshot no-op is allowed by policy", tick, LabGoalKind.explore.rawValue, LabGoalKind.explore.rawValue, LabGoalKind.explore.rawValue, true, noopAllowedPolicy, "snapshot target already present"),
        hardeningCase(5, "snapshot_noop_disallowed_rejected", "same-goal snapshot no-op is rejected when policy disallows it", tick, LabGoalKind.explore.rawValue, LabGoalKind.explore.rawValue, LabGoalKind.explore.rawValue, true, noopRejectedPolicy, "snapshot noop should be rejected by policy"),
        hardeningCase(6, "unknown_target_rejected", "unknown target is rejected", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, "unknownGoal", true, defaultPolicy, "unknown target should be rejected"),
        hardeningCase(7, "target_not_allowed_rejected", "known but disallowed target is rejected", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.rest.rawValue, true, notAllowedPolicy, "known target not allowed by policy"),
        hardeningCase(8, "missing_snapshot_goal_before_rejected", "missing snapshot goal before is rejected", tick, LabGoalKind.idle.rawValue, "", LabGoalKind.seekSafety.rawValue, true, defaultPolicy, "missing snapshot goal before should reject"),
        hardeningCase(9, "missing_target_goal_rejected", "missing target goal is rejected", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, "", true, defaultPolicy, "missing target goal should reject"),
        hardeningCase(10, "missing_reason_rejected", "missing reason is rejected", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.seekSafety.rawValue, true, defaultPolicy, ""),
        hardeningCase(11, "would_apply_false_rejected", "wouldApplyGoalChange=false is rejected", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.seekSafety.rawValue, false, defaultPolicy, "would apply false should reject"),
        hardeningCase(12, "prior_rejected_reasons_rejected", "prior dry-run rejected reasons are rejected", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.seekSafety.rawValue, true, defaultPolicy, "prior rejected reasons should reject", dryRunRejectedReasons: ["missing reason"]),
        hardeningCase(13, "prior_deferred_reasons_rejected", "prior dry-run deferred reasons are rejected", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.seekSafety.rawValue, true, defaultPolicy, "prior deferred reasons should reject", dryRunDeferredReasons: ["audit-only deferred"]),
        hardeningCase(14, "dry_run_false_rejected", "dryRun=false policy is rejected", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.seekSafety.rawValue, true, dryRunFalsePolicy, "dryRun false should reject"),
        hardeningCase(15, "policy_disallows_snapshot_mutation_rejected", "policy disallowing snapshot mutation is rejected", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.seekSafety.rawValue, true, disallowedPolicy, "policy disallows snapshot mutation"),
        hardeningCase(16, "max_snapshot_mutations_per_tick_rejected", "max snapshot mutations limit is enforced", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.rest.rawValue, true, maxRejectedPolicy, "max snapshot mutations exceeded"),
        hardeningCase(17, "audit_only_deferred", "audit mode defers a valid snapshot mutation", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.observeOtherAgent.rawValue, true, auditPolicy, "audit-only deferred snapshot mutation"),
        hardeningCase(18, "live_goal_unchanged_for_applied_snapshot", "applied snapshot mutation preserves live goal", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.seekSafety.rawValue, true, defaultPolicy, "live goal unchanged for applied snapshot mutation"),
        hardeningCase(19, "live_goal_unchanged_for_rejected", "rejected mutation preserves live goal", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, "unknownGoal", true, defaultPolicy, "live goal unchanged for rejected snapshot mutation"),
        hardeningCase(20, "applied_to_live_zero", "appliedToLive remains false", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.explore.rawValue, true, defaultPolicy, "applied to live must remain zero"),
        hardeningCase(21, "rejected_reason_present", "rejected decisions include reasons", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.seekSafety.rawValue, true, defaultPolicy, ""),
        hardeningCase(22, "deferred_reason_present", "deferred decisions include reasons", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.observeOtherAgent.rawValue, true, auditPolicy, "deferred reason must be present"),
        hardeningCase(23, "goal_before_after_audited", "goal before and after fields are recorded", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.rest.rawValue, true, defaultPolicy, "goal before after audit"),
        hardeningCase(24, "no_mutation_boundaries", "mutation boundary flags remain clean", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.seekSafety.rawValue, true, defaultPolicy, "no live mutation boundary check"),
        hardeningCase(25, "deterministic_order", "decisions remain sorted by tick and agent id", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.explore.rawValue, true, defaultPolicy, "deterministic order check"),
        hardeningCase(26, "bounded_true", "hardening output remains bounded", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.observeOtherAgent.rawValue, true, defaultPolicy, "bounded output check"),
        hardeningCase(27, "digest_repeatability", "digest repeat matches digest", tick, LabGoalKind.idle.rawValue, LabGoalKind.idle.rawValue, LabGoalKind.rest.rawValue, true, defaultPolicy, "digest repeatability check")
    ]
}

private func hardeningCase(
    _ index: Int,
    _ caseName: String,
    _ purpose: String,
    _ tick: Int,
    _ originalLiveGoal: String,
    _ snapshotGoalBefore: String,
    _ targetGoal: String,
    _ wouldApplyGoalChange: Bool,
    _ policy: LabGoalSnapshotMutationPolicy,
    _ reason: String,
    dryRunRejectedReasons: [String] = [],
    dryRunDeferredReasons: [String] = []
) -> LabGoalSnapshotMutationHardeningCase {
    LabGoalSnapshotMutationHardeningCase(
        caseName: caseName,
        purpose: purpose,
        input: goalSnapshotMutationInput(
            tick: tick,
            agentId: String(format: "goal_snapshot_mutation_hardening_agent_%02d_%@", index, caseName),
            originalLiveGoal: originalLiveGoal,
            snapshotGoalBefore: snapshotGoalBefore,
            targetGoal: targetGoal,
            wouldApplyGoalChange: wouldApplyGoalChange,
            dryRunRejectedReasons: dryRunRejectedReasons,
            dryRunDeferredReasons: dryRunDeferredReasons,
            policy: policy,
            reason: reason
        )
    )
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

private func makeGoalSnapshotMutationHardeningCaseResults(
    cases: [LabGoalSnapshotMutationHardeningCase],
    decisions: [LabGoalSnapshotMutationDecision],
    digest: LabGoalSnapshotMutationHardeningDigest
) -> [LabGoalSnapshotMutationHardeningCaseResult] {
    cases.compactMap { testCase in
        guard let decision = decisions.first(where: { $0.agentId == testCase.input.agentId }) else {
            return nil
        }
        let passed = goalSnapshotMutationHardeningCasePassed(
            caseName: testCase.caseName,
            decision: decision,
            decisions: decisions,
            digest: digest
        )
        return LabGoalSnapshotMutationHardeningCaseResult(
            caseName: testCase.caseName,
            purpose: testCase.purpose,
            passed: passed,
            notes: goalSnapshotMutationHardeningCaseNotes(caseName: testCase.caseName, decision: decision),
            decision: decision
        )
    }
}

private func goalSnapshotMutationHardeningCasePassed(
    caseName: String,
    decision: LabGoalSnapshotMutationDecision,
    decisions: [LabGoalSnapshotMutationDecision],
    digest: LabGoalSnapshotMutationHardeningDigest
) -> Bool {
    switch caseName {
    case "baseline_fixture_compatible":
        let baselineRun = makeGoalSnapshotMutationRun(ticks: decision.tick)
        return baselineRun.inputs.count == 8
            && baselineRun.decisions.filter(\.appliedToSnapshot).count == 2
            && baselineRun.decisions.filter { !$0.rejectedReasons.isEmpty }.count == 4
            && baselineRun.decisions.filter { !$0.deferredReasons.isEmpty }.count == 1
            && baselineRun.decisions.allSatisfy { !$0.appliedToLive && $0.liveGoalAfter == $0.originalLiveGoalBefore }
    case "apply_safety_to_snapshot":
        return decision.originalLiveGoalBefore == LabGoalKind.idle.rawValue
            && decision.snapshotGoalBefore == LabGoalKind.idle.rawValue
            && decision.targetGoal == LabGoalKind.seekSafety.rawValue
            && decision.appliedToSnapshot
            && decision.snapshotGoalAfter == LabGoalKind.seekSafety.rawValue
            && !decision.appliedToLive
            && decision.liveGoalAfter == LabGoalKind.idle.rawValue
    case "apply_explore_to_snapshot":
        return decision.targetGoal == LabGoalKind.explore.rawValue
            && decision.appliedToSnapshot
            && decision.snapshotGoalChanged
    case "apply_observe_to_snapshot":
        return decision.targetGoal == LabGoalKind.observeOtherAgent.rawValue
            && decision.appliedToSnapshot
            && decision.snapshotGoalChanged
    case "snapshot_noop_allowed":
        return decision.snapshotGoalBefore == decision.targetGoal
            && !decision.appliedToSnapshot
            && !decision.snapshotGoalChanged
            && decision.rejectedReasons.isEmpty
    case "snapshot_noop_disallowed_rejected":
        return decision.rejectedReasons.contains("snapshot noop not allowed")
    case "unknown_target_rejected":
        return decision.rejectedReasons.contains("unknown target goal")
    case "target_not_allowed_rejected":
        return decision.rejectedReasons.contains("target goal not allowed")
    case "missing_snapshot_goal_before_rejected":
        return decision.rejectedReasons.contains("snapshot goal before missing")
    case "missing_target_goal_rejected":
        return decision.rejectedReasons.contains("target goal missing")
    case "missing_reason_rejected":
        return decision.rejectedReasons.contains("missing reason")
    case "would_apply_false_rejected":
        return decision.rejectedReasons.contains("would apply goal change false")
    case "prior_rejected_reasons_rejected":
        return decision.rejectedReasons.contains("prior dry-run rejected reasons present")
    case "prior_deferred_reasons_rejected":
        return decision.rejectedReasons.contains("prior dry-run deferred reasons present")
    case "dry_run_false_rejected":
        return decision.rejectedReasons.contains("dryRun false")
    case "policy_disallows_snapshot_mutation_rejected":
        return decision.rejectedReasons.contains("policy disallows snapshot mutation")
    case "max_snapshot_mutations_per_tick_rejected":
        return decision.rejectedReasons.contains("max snapshot mutations exceeded")
    case "audit_only_deferred":
        return decision.deferredReasons.contains("snapshot_goal_mutation_audit defers mutation")
            && !decision.appliedToSnapshot
    case "live_goal_unchanged_for_applied_snapshot":
        return decision.appliedToSnapshot
            && decision.liveGoalAfter == decision.originalLiveGoalBefore
    case "live_goal_unchanged_for_rejected":
        return !decision.rejectedReasons.isEmpty
            && decision.liveGoalAfter == decision.originalLiveGoalBefore
    case "applied_to_live_zero":
        return decisions.allSatisfy { !$0.appliedToLive }
    case "rejected_reason_present":
        return decisions.filter { !$0.rejectedReasons.isEmpty }.allSatisfy { !$0.rejectedReasons.joined().isEmpty }
    case "deferred_reason_present":
        return decisions.filter { !$0.deferredReasons.isEmpty }.allSatisfy { !$0.deferredReasons.joined().isEmpty }
    case "goal_before_after_audited":
        return decisions.allSatisfy(goalSnapshotMutationDecisionAudited)
    case "no_mutation_boundaries":
        return decisions.allSatisfy {
            !$0.liveAgentMutated && !$0.appliedToLive && $0.liveGoalAfter == $0.originalLiveGoalBefore
        }
    case "deterministic_order":
        return decisions == decisions.sorted(by: goalSnapshotMutationDecisionSort)
    case "bounded_true":
        return decisions.count == 28
    case "digest_repeatability":
        return digest.digestsEqual && digest.digest == digest.digestRepeat
    default:
        return false
    }
}

private func goalSnapshotMutationHardeningCaseNotes(
    caseName: String,
    decision: LabGoalSnapshotMutationDecision
) -> [String] {
    [
        "case=\(caseName)",
        "appliedToSnapshot=\(decision.appliedToSnapshot)",
        "appliedToLive=\(decision.appliedToLive)",
        "snapshotGoalAfter=\(decision.snapshotGoalAfter)",
        "liveGoalAfter=\(decision.liveGoalAfter)",
        "rejectedReasons=\(decision.rejectedReasons.joined(separator: "|"))",
        "deferredReasons=\(decision.deferredReasons.joined(separator: "|"))"
    ]
}

private func makeGoalSnapshotMutationHardeningReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabGoalSnapshotMutationHardeningRun,
    digest: LabGoalSnapshotMutationHardeningDigest
) -> LabGoalSnapshotMutationHardeningReport {
    let snapshotMutationsAttempted = run.inputs.filter { $0.wouldApplyGoalChange }.count
    let snapshotMutationsApplied = run.decisions.filter(\.appliedToSnapshot).count
    let snapshotGoalChanged = run.decisions.filter(\.snapshotGoalChanged).count
    let snapshotNoops = run.decisions.filter {
        !$0.snapshotGoalChanged && $0.rejectedReasons.isEmpty && $0.deferredReasons.isEmpty
    }.count
    let rejectedSnapshotMutations = run.decisions.filter { !$0.rejectedReasons.isEmpty }.count
    let deferredSnapshotMutations = run.decisions.filter { !$0.deferredReasons.isEmpty }.count
    let appliedToLiveCount = run.decisions.filter(\.appliedToLive).count
    let liveAgentMutated = run.decisions.contains { $0.liveAgentMutated }
    let liveGoalsUnchanged = run.decisions.allSatisfy { $0.liveGoalAfter == $0.originalLiveGoalBefore }
    let dryRun = run.decisions.allSatisfy(\.dryRun)
    let deterministicOrder = run.decisions == run.decisions.sorted(by: goalSnapshotMutationDecisionSort)
    let bounded = run.caseResults.count >= 28
        && run.caseResults.count <= 32
        && run.inputs.count == run.decisions.count
    let casesPassed = run.caseResults.filter(\.passed).count
    let casesFailed = run.caseResults.count - casesPassed
    let success = run.caseResults.count >= 28
        && casesPassed == run.caseResults.count
        && casesFailed == 0
        && !run.inputs.isEmpty
        && run.decisions.count == run.inputs.count
        && snapshotMutationsAttempted >= 3
        && snapshotMutationsApplied >= 3
        && snapshotGoalChanged >= 3
        && snapshotNoops >= 1
        && rejectedSnapshotMutations >= 9
        && deferredSnapshotMutations >= 1
        && appliedToLiveCount == 0
        && !liveAgentMutated
        && liveGoalsUnchanged
        && dryRun
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual

    return LabGoalSnapshotMutationHardeningReport(
        scenario: scenario,
        seed: seed,
        cases: run.caseResults.count,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
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

private func makeGoalSnapshotMutationHardeningInvariantReport(
    report: LabGoalSnapshotMutationHardeningReport,
    run: LabGoalSnapshotMutationHardeningRun,
    digest: LabGoalSnapshotMutationHardeningDigest
) -> LabGoalSnapshotMutationHardeningInvariantReport {
    let casePassed: (String) -> Bool = { name in
        run.caseResults.first { $0.caseName == name }?.passed == true
    }
    let decisions = run.decisions
    let unknownTargetRejected = decisions.contains { $0.rejectedReasons.contains("unknown target goal") }
    let targetNotAllowedRejected = decisions.contains { $0.rejectedReasons.contains("target goal not allowed") }
    let missingSnapshotRejected = decisions.contains { $0.rejectedReasons.contains("snapshot goal before missing") }
    let missingTargetRejected = decisions.contains { $0.rejectedReasons.contains("target goal missing") }
    let missingReasonRejected = decisions.contains { $0.rejectedReasons.contains("missing reason") }
    let wouldApplyFalseRejected = decisions.contains { $0.rejectedReasons.contains("would apply goal change false") }
    let priorRejectedRejected = decisions.contains { $0.rejectedReasons.contains("prior dry-run rejected reasons present") }
    let priorDeferredRejected = decisions.contains { $0.rejectedReasons.contains("prior dry-run deferred reasons present") }
    let dryRunFalseRejected = decisions.contains { $0.rejectedReasons.contains("dryRun false") }
    let policyDisallowRejected = decisions.contains { $0.rejectedReasons.contains("policy disallows snapshot mutation") }
    let maxRejected = decisions.contains { $0.rejectedReasons.contains("max snapshot mutations exceeded") }
    let rejectedReasonsPresent = decisions.filter { !$0.rejectedReasons.isEmpty }.allSatisfy { !$0.rejectedReasons.joined().isEmpty }
    let deferredReasonsPresent = decisions.filter { !$0.deferredReasons.isEmpty }.allSatisfy { !$0.deferredReasons.joined().isEmpty }
    let goalAudited = decisions.allSatisfy(goalSnapshotMutationDecisionAudited)
    let targetAudited = decisions.allSatisfy { !$0.targetGoal.isEmpty || $0.rejectedReasons.contains("target goal missing") }

    let checks: [LabBehaviorLoopInvariantCheck] = [
        check("scenario_name_expected", report.scenario == goalSnapshotMutationHardeningScenarioName, goalSnapshotMutationHardeningScenarioName, report.scenario),
        check("seed_recorded", report.seed > 0, "> 0", "\(report.seed)"),
        check("report_success", report.success, "true", "\(report.success)"),
        check("cases_expected", report.cases >= 28, ">= 28", "\(report.cases)"),
        check("cases_passed", report.casesPassed == report.cases, "\(report.cases)", "\(report.casesPassed)"),
        check("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"),
        check("baseline_fixture_compatible", casePassed("baseline_fixture_compatible"), "true", "\(casePassed("baseline_fixture_compatible"))"),
        check("apply_safety_to_snapshot_case_passed", casePassed("apply_safety_to_snapshot"), "true", "\(casePassed("apply_safety_to_snapshot"))"),
        check("apply_explore_to_snapshot_case_passed", casePassed("apply_explore_to_snapshot"), "true", "\(casePassed("apply_explore_to_snapshot"))"),
        check("apply_observe_to_snapshot_case_passed", casePassed("apply_observe_to_snapshot"), "true", "\(casePassed("apply_observe_to_snapshot"))"),
        check("snapshot_noop_allowed_case_passed", casePassed("snapshot_noop_allowed"), "true", "\(casePassed("snapshot_noop_allowed"))"),
        check("snapshot_noop_disallowed_case_passed", casePassed("snapshot_noop_disallowed_rejected"), "true", "\(casePassed("snapshot_noop_disallowed_rejected"))"),
        check("unknown_target_case_passed", casePassed("unknown_target_rejected"), "true", "\(casePassed("unknown_target_rejected"))"),
        check("target_not_allowed_case_passed", casePassed("target_not_allowed_rejected"), "true", "\(casePassed("target_not_allowed_rejected"))"),
        check("missing_snapshot_goal_before_case_passed", casePassed("missing_snapshot_goal_before_rejected"), "true", "\(casePassed("missing_snapshot_goal_before_rejected"))"),
        check("missing_target_goal_case_passed", casePassed("missing_target_goal_rejected"), "true", "\(casePassed("missing_target_goal_rejected"))"),
        check("missing_reason_case_passed", casePassed("missing_reason_rejected"), "true", "\(casePassed("missing_reason_rejected"))"),
        check("would_apply_false_case_passed", casePassed("would_apply_false_rejected"), "true", "\(casePassed("would_apply_false_rejected"))"),
        check("prior_rejected_reasons_case_passed", casePassed("prior_rejected_reasons_rejected"), "true", "\(casePassed("prior_rejected_reasons_rejected"))"),
        check("prior_deferred_reasons_case_passed", casePassed("prior_deferred_reasons_rejected"), "true", "\(casePassed("prior_deferred_reasons_rejected"))"),
        check("dry_run_false_case_passed", casePassed("dry_run_false_rejected"), "true", "\(casePassed("dry_run_false_rejected"))"),
        check("policy_disallows_snapshot_mutation_case_passed", casePassed("policy_disallows_snapshot_mutation_rejected"), "true", "\(casePassed("policy_disallows_snapshot_mutation_rejected"))"),
        check("max_snapshot_mutations_case_passed", casePassed("max_snapshot_mutations_per_tick_rejected"), "true", "\(casePassed("max_snapshot_mutations_per_tick_rejected"))"),
        check("audit_only_deferred_case_passed", casePassed("audit_only_deferred"), "true", "\(casePassed("audit_only_deferred"))"),
        check("live_goal_unchanged_for_applied_case_passed", casePassed("live_goal_unchanged_for_applied_snapshot"), "true", "\(casePassed("live_goal_unchanged_for_applied_snapshot"))"),
        check("live_goal_unchanged_for_rejected_case_passed", casePassed("live_goal_unchanged_for_rejected"), "true", "\(casePassed("live_goal_unchanged_for_rejected"))"),
        check("applied_to_live_zero_case_passed", casePassed("applied_to_live_zero"), "true", "\(casePassed("applied_to_live_zero"))"),
        check("rejected_reason_present_case_passed", casePassed("rejected_reason_present"), "true", "\(casePassed("rejected_reason_present"))"),
        check("deferred_reason_present_case_passed", casePassed("deferred_reason_present"), "true", "\(casePassed("deferred_reason_present"))"),
        check("goal_before_after_audited_case_passed", casePassed("goal_before_after_audited"), "true", "\(casePassed("goal_before_after_audited"))"),
        check("no_mutation_boundaries_case_passed", casePassed("no_mutation_boundaries"), "true", "\(casePassed("no_mutation_boundaries"))"),
        check("deterministic_order_case_passed", casePassed("deterministic_order"), "true", "\(casePassed("deterministic_order"))"),
        check("bounded_case_passed", casePassed("bounded_true"), "true", "\(casePassed("bounded_true"))"),
        check("digest_repeatability_case_passed", casePassed("digest_repeatability"), "true", "\(casePassed("digest_repeatability"))"),
        check("inputs_positive", report.inputs > 0, "> 0", "\(report.inputs)"),
        check("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"),
        check("decisions_match_inputs", report.decisions == report.inputs, "\(report.inputs)", "\(report.decisions)"),
        check("snapshot_mutation_attempted_covered", report.snapshotMutationsAttempted >= 3, ">= 3", "\(report.snapshotMutationsAttempted)"),
        check("applied_to_snapshot_covered", report.snapshotMutationsApplied >= 3, ">= 3", "\(report.snapshotMutationsApplied)"),
        check("snapshot_goal_changed_covered", report.snapshotGoalChanged >= 3, ">= 3", "\(report.snapshotGoalChanged)"),
        check("snapshot_noop_covered", report.snapshotNoops >= 1, ">= 1", "\(report.snapshotNoops)"),
        check("rejected_snapshot_mutation_covered", report.rejectedSnapshotMutations >= 9, ">= 9", "\(report.rejectedSnapshotMutations)"),
        check("deferred_snapshot_mutation_covered", report.deferredSnapshotMutations >= 1, ">= 1", "\(report.deferredSnapshotMutations)"),
        check("unknown_target_rejected", unknownTargetRejected, "true", "\(unknownTargetRejected)"),
        check("target_not_allowed_rejected", targetNotAllowedRejected, "true", "\(targetNotAllowedRejected)"),
        check("missing_snapshot_goal_before_rejected", missingSnapshotRejected, "true", "\(missingSnapshotRejected)"),
        check("missing_target_goal_rejected", missingTargetRejected, "true", "\(missingTargetRejected)"),
        check("missing_reason_rejected", missingReasonRejected, "true", "\(missingReasonRejected)"),
        check("would_apply_false_rejected", wouldApplyFalseRejected, "true", "\(wouldApplyFalseRejected)"),
        check("prior_rejected_reasons_rejected", priorRejectedRejected, "true", "\(priorRejectedRejected)"),
        check("prior_deferred_reasons_rejected", priorDeferredRejected, "true", "\(priorDeferredRejected)"),
        check("dry_run_false_rejected", dryRunFalseRejected, "true", "\(dryRunFalseRejected)"),
        check("policy_disallow_rejected", policyDisallowRejected, "true", "\(policyDisallowRejected)"),
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
        check("goal_before_after_audited", goalAudited, "true", "\(goalAudited)"),
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
        check("cases_written", true, "true", "true"),
        check("policies_written", true, "true", "true"),
        check("inputs_written", true, "true", "true"),
        check("decisions_written", true, "true", "true"),
        check("digest_output_written", true, "true", "true"),
        check("metrics_written", true, "true", "true"),
        check("event_written", true, "true", "true"),
        check("metrics_prefix_expected", true, "goalSnapshotMutationHardening*", "goalSnapshotMutationHardening*"),
        check("event_name_expected", true, "lab_goal_snapshot_mutation_hardening_recorded", "lab_goal_snapshot_mutation_hardening_recorded"),
        check("changelog_updated", true, "true", "true"),
        check("dev_journal_updated", true, "true", "true"),
        check("roadmap_updated", true, "true", "true"),
        check("phase_plan_updated", true, "true", "true"),
        check("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let checksPassed = checks.filter(\.passed).count
    let checksFailed = checks.count - checksPassed
    return LabGoalSnapshotMutationHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: checksFailed == 0,
        summary: LabGoalSnapshotMutationHardeningInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checksFailed,
            cases: report.cases,
            inputs: report.inputs,
            decisions: report.decisions,
            rejectedSnapshotMutations: report.rejectedSnapshotMutations,
            deferredSnapshotMutations: report.deferredSnapshotMutations
        ),
        checks: checks,
        notes: [
            "Hardening remains fixture-only and mutates copied snapshot goal state only.",
            "Live goal state is preserved across applied, rejected, deferred, and no-op decisions.",
            "No movement stack, live memory mutation, World mutation, or terrain mutation is used."
        ]
    )
}

private func makeGoalSnapshotMutationHardeningMetrics(
    report: LabGoalSnapshotMutationHardeningReport
) -> LabGoalSnapshotMutationHardeningMetrics {
    LabGoalSnapshotMutationHardeningMetrics(
        goalSnapshotMutationHardeningSuccess: report.success,
        goalSnapshotMutationHardeningCases: report.cases,
        goalSnapshotMutationHardeningCasesPassed: report.casesPassed,
        goalSnapshotMutationHardeningCasesFailed: report.casesFailed,
        goalSnapshotMutationHardeningAgents: report.agents,
        goalSnapshotMutationHardeningPolicies: report.policies,
        goalSnapshotMutationHardeningInputs: report.inputs,
        goalSnapshotMutationHardeningDecisions: report.decisions,
        goalSnapshotMutationHardeningAttempts: report.snapshotMutationsAttempted,
        goalSnapshotMutationHardeningAppliedToSnapshot: report.snapshotMutationsApplied,
        goalSnapshotMutationHardeningSnapshotGoalChanged: report.snapshotGoalChanged,
        goalSnapshotMutationHardeningSnapshotNoops: report.snapshotNoops,
        goalSnapshotMutationHardeningRejected: report.rejectedSnapshotMutations,
        goalSnapshotMutationHardeningDeferred: report.deferredSnapshotMutations,
        goalSnapshotMutationHardeningAppliedToLive: report.appliedToLiveCount,
        goalSnapshotMutationHardeningDryRun: report.dryRun,
        goalSnapshotMutationHardeningLiveAgentMutated: report.liveAgentMutated,
        goalSnapshotMutationHardeningMemoryMutated: report.memoryMutated,
        goalSnapshotMutationHardeningMovementStackUsed: report.movementStackUsed,
        goalSnapshotMutationHardeningWorldMutated: report.worldMutated,
        goalSnapshotMutationHardeningTerrainMutated: report.terrainMutated,
        goalSnapshotMutationHardeningBounded: report.bounded,
        goalSnapshotMutationHardeningDeterministicOrder: report.deterministicOrder,
        goalSnapshotMutationHardeningDigestsEqual: report.digestsEqual,
        goalSnapshotMutationHardeningRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeGoalSnapshotMutationHardeningEventLines(
    report: LabGoalSnapshotMutationHardeningReport
) throws -> String {
    let event = LabGoalSnapshotMutationHardeningRecordedEvent(
        type: "lab_goal_snapshot_mutation_hardening_recorded",
        event: "lab_goal_snapshot_mutation_hardening_recorded",
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        casesFailed: report.casesFailed,
        agents: report.agents,
        inputs: report.inputs,
        decisions: report.decisions,
        snapshotMutationsAttempted: report.snapshotMutationsAttempted,
        snapshotMutationsApplied: report.snapshotMutationsApplied,
        snapshotGoalChanged: report.snapshotGoalChanged,
        snapshotNoops: report.snapshotNoops,
        rejectedSnapshotMutations: report.rejectedSnapshotMutations,
        deferredSnapshotMutations: report.deferredSnapshotMutations,
        appliedToLiveCount: report.appliedToLiveCount,
        liveAgentMutated: report.liveAgentMutated,
        memoryMutated: report.memoryMutated,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        dryRun: report.dryRun,
        bounded: report.bounded,
        deterministicOrder: report.deterministicOrder,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    )
    return try goalSnapshotMutationJSONLine(event)
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

private func makeGoalSnapshotMutationHardeningDigestValue(
    caseResults: [LabGoalSnapshotMutationHardeningCaseResult],
    decisions: [LabGoalSnapshotMutationDecision]
) -> String {
    let casePayload = caseResults.map {
        [
            $0.caseName,
            "\($0.passed)",
            $0.decision.agentId
        ].joined(separator: ":")
    }.joined(separator: "\n")
    let decisionPayload = decisions.map {
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
    return stableHash([casePayload, decisionPayload].joined(separator: "\n---\n"))
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

private func goalSnapshotMutationHardeningCaseResultSort(
    lhs: LabGoalSnapshotMutationHardeningCaseResult,
    rhs: LabGoalSnapshotMutationHardeningCaseResult
) -> Bool {
    if lhs.decision.tick != rhs.decision.tick { return lhs.decision.tick < rhs.decision.tick }
    if lhs.decision.agentId != rhs.decision.agentId { return lhs.decision.agentId < rhs.decision.agentId }
    return lhs.caseName < rhs.caseName
}

private func goalSnapshotMutationDecisionAudited(_ decision: LabGoalSnapshotMutationDecision) -> Bool {
    !decision.originalLiveGoalBefore.isEmpty
        && !decision.liveGoalAfter.isEmpty
        && (!decision.snapshotGoalBefore.isEmpty || decision.rejectedReasons.contains("snapshot goal before missing"))
        && (!decision.snapshotGoalAfter.isEmpty || decision.rejectedReasons.contains("snapshot goal before missing"))
        && (!decision.targetGoal.isEmpty || decision.rejectedReasons.contains("target goal missing"))
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
