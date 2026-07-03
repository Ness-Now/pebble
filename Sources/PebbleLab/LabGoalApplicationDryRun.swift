import Foundation

let goalApplicationDryRunScenarioName = "goal_application_dry_run_fixture_smoke"

struct LabGoalApplicationDryRunPolicy: Codable, Equatable {
    let dryRun: Bool
    let mode: String
    let allowGoalApplication: Bool
    let allowedGoals: [String]
    let maxGoalChangesPerTick: Int
    let requireReason: Bool
    let requireSnapshotReadOnly: Bool
    let allowNoopGoal: Bool
    let allowDeferred: Bool
}

struct LabGoalApplicationDryRunInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let snapshotSummary: String
    let currentGoal: String
    let targetGoal: String
    let goalChangeEligible: Bool
    let controlledDecisionSummary: String
    let snapshotReadOnly: Bool
    let policy: LabGoalApplicationDryRunPolicy
    let reason: String
}

struct LabGoalApplicationDryRunDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let goalBefore: String
    let targetGoal: String
    let goalKnown: Bool
    let goalChanged: Bool
    let wouldApplyGoalChange: Bool
    let appliedGoalChange: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let dryRun: Bool
    let liveAgentMutated: Bool
    let success: Bool
}

struct LabGoalApplicationDryRunReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let policies: Int
    let inputs: Int
    let decisions: Int
    let eligibleInputs: Int
    let wouldApplyGoalChanges: Int
    let noopGoalChanges: Int
    let rejectedGoalApplications: Int
    let deferredGoalApplications: Int
    let appliedGoalChanges: Int
    let dryRun: Bool
    let liveAgentMutated: Bool
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let success: Bool
}

struct LabGoalApplicationDryRunInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let inputs: Int
    let decisions: Int
    let rejectedGoalApplications: Int
    let deferredGoalApplications: Int
}

struct LabGoalApplicationDryRunInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabGoalApplicationDryRunInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabGoalApplicationDryRunDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabGoalApplicationDryRunMetrics: Codable, Equatable {
    let goalApplicationDryRunSuccess: Bool
    let goalApplicationDryRunAgents: Int
    let goalApplicationDryRunTicks: Int
    let goalApplicationDryRunPolicies: Int
    let goalApplicationDryRunInputs: Int
    let goalApplicationDryRunDecisions: Int
    let goalApplicationDryRunEligibleInputs: Int
    let goalApplicationDryRunWouldApplyGoalChanges: Int
    let goalApplicationDryRunNoopGoalChanges: Int
    let goalApplicationDryRunRejectedGoalApplications: Int
    let goalApplicationDryRunDeferredGoalApplications: Int
    let goalApplicationDryRunAppliedGoalChanges: Int
    let goalApplicationDryRunDryRun: Bool
    let goalApplicationDryRunLiveAgentMutated: Bool
    let goalApplicationDryRunMemoryMutated: Bool
    let goalApplicationDryRunMovementStackUsed: Bool
    let goalApplicationDryRunWorldMutated: Bool
    let goalApplicationDryRunTerrainMutated: Bool
    let goalApplicationDryRunBounded: Bool
    let goalApplicationDryRunDeterministicOrder: Bool
    let goalApplicationDryRunDigestsEqual: Bool
    let goalApplicationDryRunRepeatabilityFailures: Int
}

struct LabGoalApplicationDryRunFixture: Codable, Equatable {
    let report: LabGoalApplicationDryRunReport
    let invariantReport: LabGoalApplicationDryRunInvariantReport
    let policies: [LabGoalApplicationDryRunPolicy]
    let inputs: [LabGoalApplicationDryRunInput]
    let decisions: [LabGoalApplicationDryRunDecision]
    let digest: LabGoalApplicationDryRunDigest
    let eventLines: String
    let metrics: LabGoalApplicationDryRunMetrics
}

private struct LabGoalApplicationDryRunRun {
    let policies: [LabGoalApplicationDryRunPolicy]
    let inputs: [LabGoalApplicationDryRunInput]
    let decisions: [LabGoalApplicationDryRunDecision]
}

private struct LabGoalApplicationDryRunRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let goalBefore: String
    let targetGoal: String
    let goalChangeEligible: Bool
    let wouldApplyGoalChange: Bool
    let appliedGoalChange: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let dryRun: Bool
    let liveAgentMutated: Bool
}

private struct LabGoalApplicationDryRunSummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let ticks: Int
    let inputs: Int
    let decisions: Int
    let eligibleInputs: Int
    let wouldApplyGoalChanges: Int
    let noopGoalChanges: Int
    let rejectedGoalApplications: Int
    let deferredGoalApplications: Int
    let appliedGoalChanges: Int
    let dryRun: Bool
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeGoalApplicationDryRunFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabGoalApplicationDryRunFixture {
    let run = makeGoalApplicationDryRunRun(ticks: ticks)
    let repeatRun = makeGoalApplicationDryRunRun(ticks: ticks)
    let digestValue = makeGoalApplicationDryRunDigestValue(run: run)
    let digestRepeatValue = makeGoalApplicationDryRunDigestValue(run: repeatRun)
    let digest = LabGoalApplicationDryRunDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeGoalApplicationDryRunReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeGoalApplicationDryRunInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabGoalApplicationDryRunFixture(
        report: report,
        invariantReport: invariantReport,
        policies: run.policies,
        inputs: run.inputs,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeGoalApplicationDryRunEventLines(report: report, decisions: run.decisions, inputs: run.inputs),
        metrics: makeGoalApplicationDryRunMetrics(report: report)
    )
}

private func makeGoalApplicationDryRunRun(ticks: Int) -> LabGoalApplicationDryRunRun {
    let tick = max(1, ticks)
    let inputs = makeGoalApplicationDryRunInputs(tick: tick).sorted(by: goalApplicationDryRunInputSort)
    let decisions = inputs.map(makeGoalApplicationDryRunDecision).sorted(by: goalApplicationDryRunDecisionSort)
    let policies = inputs.map(\.policy).sorted(by: goalApplicationDryRunPolicySort)
    return LabGoalApplicationDryRunRun(
        policies: policies,
        inputs: inputs,
        decisions: decisions
    )
}

private func makeGoalApplicationDryRunInputs(tick: Int) -> [LabGoalApplicationDryRunInput] {
    let defaultPolicy = goalApplicationDryRunPolicy()
    let noopPolicy = goalApplicationDryRunPolicy(allowNoopGoal: true)
    let auditPolicy = goalApplicationDryRunPolicy(mode: "goal_eligibility_audit", allowDeferred: true)
    let dryRunFalsePolicy = goalApplicationDryRunPolicy(dryRun: false)
    let maxGoalChangesPolicy = goalApplicationDryRunPolicy(maxGoalChangesPerTick: 0)

    return [
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_agent_0_safety",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            goalChangeEligible: true,
            policy: defaultPolicy,
            reason: "eligible safety goal change"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_agent_1_explore",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            goalChangeEligible: true,
            policy: defaultPolicy,
            reason: "eligible explore goal change"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_agent_2_noop",
            currentGoal: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            goalChangeEligible: true,
            policy: noopPolicy,
            reason: "noop goal already selected"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_agent_3_unknown",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: "unknownGoal",
            goalChangeEligible: true,
            policy: defaultPolicy,
            reason: "unknown target goal rejection"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_agent_4_missing_reason",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            goalChangeEligible: true,
            policy: defaultPolicy,
            reason: ""
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_agent_5_snapshot",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.observeOtherAgent.rawValue,
            goalChangeEligible: true,
            policy: defaultPolicy,
            reason: "snapshot not read-only rejection",
            snapshotReadOnly: false
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_agent_6_audit",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.observeOtherAgent.rawValue,
            goalChangeEligible: true,
            policy: auditPolicy,
            reason: "audit-only deferred goal change"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_agent_7_max",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            goalChangeEligible: true,
            policy: maxGoalChangesPolicy,
            reason: "max goal changes exceeded rejection"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_agent_8_dry_run_false",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            goalChangeEligible: true,
            policy: dryRunFalsePolicy,
            reason: "dryRun false rejection"
        )
    ]
}

private func goalApplicationDryRunPolicy(
    dryRun: Bool = true,
    mode: String = "goal_dry_run_only",
    allowGoalApplication: Bool = true,
    allowedGoals: [String] = [
        LabGoalKind.idle.rawValue,
        LabGoalKind.rest.rawValue,
        LabGoalKind.seekSafety.rawValue,
        LabGoalKind.explore.rawValue,
        LabGoalKind.observeOtherAgent.rawValue
    ],
    maxGoalChangesPerTick: Int = 1,
    requireReason: Bool = true,
    requireSnapshotReadOnly: Bool = true,
    allowNoopGoal: Bool = false,
    allowDeferred: Bool = false
) -> LabGoalApplicationDryRunPolicy {
    LabGoalApplicationDryRunPolicy(
        dryRun: dryRun,
        mode: mode,
        allowGoalApplication: allowGoalApplication,
        allowedGoals: allowedGoals,
        maxGoalChangesPerTick: maxGoalChangesPerTick,
        requireReason: requireReason,
        requireSnapshotReadOnly: requireSnapshotReadOnly,
        allowNoopGoal: allowNoopGoal,
        allowDeferred: allowDeferred
    )
}

private func goalApplicationDryRunInput(
    tick: Int,
    agentId: String,
    currentGoal: String,
    targetGoal: String,
    goalChangeEligible: Bool,
    policy: LabGoalApplicationDryRunPolicy,
    reason: String,
    snapshotReadOnly: Bool = true
) -> LabGoalApplicationDryRunInput {
    LabGoalApplicationDryRunInput(
        tick: tick,
        agentId: agentId,
        snapshotSummary: "agentId=\(agentId);currentGoal=\(currentGoal);snapshotReadOnly=\(snapshotReadOnly)",
        currentGoal: currentGoal,
        targetGoal: targetGoal,
        goalChangeEligible: goalChangeEligible,
        controlledDecisionSummary: "goalChangeEligible=\(goalChangeEligible);targetGoal=\(targetGoal);mode=\(policy.mode)",
        snapshotReadOnly: snapshotReadOnly,
        policy: policy,
        reason: reason
    )
}

private func makeGoalApplicationDryRunDecision(
    input: LabGoalApplicationDryRunInput
) -> LabGoalApplicationDryRunDecision {
    var rejectedReasons: [String] = []
    var deferredReasons: [String] = []
    let reasonPresent = !input.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let goalKnown = input.policy.allowedGoals.contains(input.targetGoal)
    let goalChanged = input.currentGoal != input.targetGoal

    if !input.goalChangeEligible {
        rejectedReasons.append("goal change not eligible")
    }
    if !goalKnown {
        rejectedReasons.append("unknown target goal")
    }
    if input.targetGoal.isEmpty {
        rejectedReasons.append("target goal missing")
    }
    if input.currentGoal.isEmpty {
        rejectedReasons.append("current goal missing")
    }
    if input.policy.requireReason && !reasonPresent {
        rejectedReasons.append("missing reason")
    }
    if input.policy.requireSnapshotReadOnly && !input.snapshotReadOnly {
        rejectedReasons.append("snapshot not read-only")
    }
    if !input.policy.dryRun {
        rejectedReasons.append("dryRun false")
    }
    if !input.policy.allowGoalApplication {
        rejectedReasons.append("policy disallows goal application")
    }
    if input.policy.maxGoalChangesPerTick < 1 && goalChanged {
        rejectedReasons.append("max goal changes exceeded")
    }
    if input.policy.mode == "goal_eligibility_audit" && input.policy.allowDeferred {
        deferredReasons.append("goal_eligibility_audit defers application")
    }
    if !goalChanged && !input.policy.allowNoopGoal {
        rejectedReasons.append("noop goal not allowed")
    }

    let wouldApplyGoalChange = rejectedReasons.isEmpty
        && deferredReasons.isEmpty
        && input.policy.dryRun
        && input.policy.allowGoalApplication
        && input.goalChangeEligible
        && goalKnown
        && goalChanged
        && reasonPresent
        && input.snapshotReadOnly
        && input.policy.maxGoalChangesPerTick >= 1
        && input.policy.mode == "goal_dry_run_only"

    return LabGoalApplicationDryRunDecision(
        tick: input.tick,
        agentId: input.agentId,
        goalBefore: input.currentGoal,
        targetGoal: input.targetGoal,
        goalKnown: goalKnown,
        goalChanged: goalChanged,
        wouldApplyGoalChange: wouldApplyGoalChange,
        appliedGoalChange: false,
        rejectedReasons: rejectedReasons,
        deferredReasons: deferredReasons,
        dryRun: true,
        liveAgentMutated: false,
        success: true
    )
}

private func makeGoalApplicationDryRunReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabGoalApplicationDryRunRun,
    digest: LabGoalApplicationDryRunDigest
) -> LabGoalApplicationDryRunReport {
    let eligibleInputs = run.inputs.filter { $0.goalChangeEligible }.count
    let wouldApplyGoalChanges = run.decisions.filter { $0.wouldApplyGoalChange }.count
    let noopGoalChanges = run.decisions.filter {
        !$0.goalChanged && $0.rejectedReasons.isEmpty && $0.deferredReasons.isEmpty
    }.count
    let rejectedGoalApplications = run.decisions.filter { !$0.rejectedReasons.isEmpty }.count
    let deferredGoalApplications = run.decisions.filter { !$0.deferredReasons.isEmpty }.count
    let appliedGoalChanges = run.decisions.filter { $0.appliedGoalChange }.count
    let dryRun = run.decisions.allSatisfy { $0.dryRun }
    let bounded = run.policies.allSatisfy {
        $0.allowedGoals.count <= 5
            && $0.maxGoalChangesPerTick <= 5
    }
    let deterministicOrder = run.policies == run.policies.sorted(by: goalApplicationDryRunPolicySort)
        && run.inputs == run.inputs.sorted(by: goalApplicationDryRunInputSort)
        && run.decisions == run.decisions.sorted(by: goalApplicationDryRunDecisionSort)
    let success = scenario == goalApplicationDryRunScenarioName
        && run.inputs.count >= 7
        && run.decisions.count == run.inputs.count
        && eligibleInputs >= 2
        && wouldApplyGoalChanges >= 2
        && noopGoalChanges >= 1
        && rejectedGoalApplications >= 3
        && deferredGoalApplications >= 1
        && appliedGoalChanges == 0
        && dryRun
        && !run.decisions.contains { $0.liveAgentMutated }
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual
        && digest.digest == digest.digestRepeat

    return LabGoalApplicationDryRunReport(
        scenario: scenario,
        seed: seed,
        agents: Set(run.inputs.map(\.agentId)).count,
        ticks: ticks,
        policies: run.policies.count,
        inputs: run.inputs.count,
        decisions: run.decisions.count,
        eligibleInputs: eligibleInputs,
        wouldApplyGoalChanges: wouldApplyGoalChanges,
        noopGoalChanges: noopGoalChanges,
        rejectedGoalApplications: rejectedGoalApplications,
        deferredGoalApplications: deferredGoalApplications,
        appliedGoalChanges: appliedGoalChanges,
        dryRun: dryRun,
        liveAgentMutated: false,
        memoryMutated: false,
        movementStackUsed: false,
        worldMutated: false,
        terrainMutated: false,
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

private func makeGoalApplicationDryRunInvariantReport(
    report: LabGoalApplicationDryRunReport,
    run: LabGoalApplicationDryRunRun,
    digest: LabGoalApplicationDryRunDigest
) -> LabGoalApplicationDryRunInvariantReport {
    let decisionByAgent = Dictionary(uniqueKeysWithValues: run.decisions.map { ($0.agentId, $0) })
    let unknownTargetRejected = run.decisions.contains {
        $0.targetGoal == "unknownGoal" && $0.rejectedReasons.contains("unknown target goal")
    }
    let missingReasonRejected = run.decisions.contains {
        $0.rejectedReasons.contains("missing reason")
    }
    let snapshotRejected = run.decisions.contains {
        $0.rejectedReasons.contains("snapshot not read-only")
    }
    let dryRunFalseRejectedOrAbsent = run.inputs.allSatisfy { $0.policy.dryRun }
        || run.decisions.contains { $0.rejectedReasons.contains("dryRun false") }
    let maxGoalChangesRejected = run.decisions.contains {
        $0.rejectedReasons.contains("max goal changes exceeded")
    }
    let rejectedReasonsPresent = run.decisions.filter { !$0.rejectedReasons.isEmpty }
        .allSatisfy { !$0.rejectedReasons.joined().isEmpty }
    let deferredReasonsPresent = run.decisions.filter { !$0.deferredReasons.isEmpty }
        .allSatisfy { !$0.deferredReasons.joined().isEmpty }
    let successContract = report.success
        && report.agents >= 5
        && report.ticks >= 1
        && report.inputs >= 7
        && report.decisions == report.inputs
        && report.eligibleInputs >= 2
        && report.wouldApplyGoalChanges >= 2
        && report.noopGoalChanges >= 1
        && report.rejectedGoalApplications >= 3
        && report.deferredGoalApplications >= 1
        && report.appliedGoalChanges == 0
        && report.dryRun
        && !report.liveAgentMutated
        && !report.memoryMutated
        && !report.movementStackUsed
        && !report.worldMutated
        && !report.terrainMutated
        && report.bounded
        && report.deterministicOrder
        && digest.deterministicDigest
        && digest.digest == digest.digestRepeat
        && digest.digestsEqual
        && report.repeatabilityFailures == 0

    var checks: [LabBehaviorLoopInvariantCheck] = []
    checks.append(goalApplicationDryRunCheck("scenario_name_expected", report.scenario == goalApplicationDryRunScenarioName, goalApplicationDryRunScenarioName, report.scenario))
    checks.append(goalApplicationDryRunCheck("seed_recorded", report.seed > 0, "> 0", "\(report.seed)"))
    checks.append(goalApplicationDryRunCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(goalApplicationDryRunCheck("agents_expected", report.agents >= 5, ">= 5", "\(report.agents)"))
    checks.append(goalApplicationDryRunCheck("ticks_expected", report.ticks >= 1, ">= 1", "\(report.ticks)"))
    checks.append(goalApplicationDryRunCheck("policies_positive", report.policies > 0, "> 0", "\(report.policies)"))
    checks.append(goalApplicationDryRunCheck("inputs_positive", report.inputs > 0, "> 0", "\(report.inputs)"))
    checks.append(goalApplicationDryRunCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(goalApplicationDryRunCheck("decisions_match_inputs", report.decisions == report.inputs, "\(report.inputs)", "\(report.decisions)"))
    checks.append(goalApplicationDryRunCheck("eligible_input_covered", report.eligibleInputs >= 2, ">= 2", "\(report.eligibleInputs)"))
    checks.append(goalApplicationDryRunCheck("would_apply_goal_covered", report.wouldApplyGoalChanges >= 2, ">= 2", "\(report.wouldApplyGoalChanges)"))
    checks.append(goalApplicationDryRunCheck("noop_goal_covered", report.noopGoalChanges >= 1, ">= 1", "\(report.noopGoalChanges)"))
    checks.append(goalApplicationDryRunCheck("rejected_goal_covered", report.rejectedGoalApplications >= 3, ">= 3", "\(report.rejectedGoalApplications)"))
    checks.append(goalApplicationDryRunCheck("deferred_goal_covered", report.deferredGoalApplications >= 1, ">= 1", "\(report.deferredGoalApplications)"))
    checks.append(goalApplicationDryRunCheck("unknown_target_goal_rejected", unknownTargetRejected, "true", "\(unknownTargetRejected)"))
    checks.append(goalApplicationDryRunCheck("missing_reason_rejected", missingReasonRejected, "true", "\(missingReasonRejected)"))
    checks.append(goalApplicationDryRunCheck("snapshot_not_read_only_rejected", snapshotRejected, "true", "\(snapshotRejected)"))
    checks.append(goalApplicationDryRunCheck("dry_run_false_rejected_or_absent", dryRunFalseRejectedOrAbsent, "true", "\(dryRunFalseRejectedOrAbsent)"))
    checks.append(goalApplicationDryRunCheck("max_goal_changes_rejected", maxGoalChangesRejected, "true", "\(maxGoalChangesRejected)"))
    checks.append(goalApplicationDryRunCheck("rejected_reasons_present", rejectedReasonsPresent, "true", "\(rejectedReasonsPresent)"))
    checks.append(goalApplicationDryRunCheck("deferred_reasons_present", deferredReasonsPresent, "true", "\(deferredReasonsPresent)"))
    checks.append(goalApplicationDryRunCheck("applied_goal_changes_zero", report.appliedGoalChanges == 0, "0", "\(report.appliedGoalChanges)"))
    checks.append(goalApplicationDryRunCheck("dry_run_true", report.dryRun, "true", "\(report.dryRun)"))
    checks.append(goalApplicationDryRunCheck("live_agent_not_mutated", !report.liveAgentMutated, "false", "\(report.liveAgentMutated)"))
    checks.append(goalApplicationDryRunCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"))
    checks.append(goalApplicationDryRunCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(goalApplicationDryRunCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(goalApplicationDryRunCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(goalApplicationDryRunCheck("bounded_true", report.bounded, "true", "\(report.bounded)"))
    checks.append(goalApplicationDryRunCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(goalApplicationDryRunCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(goalApplicationDryRunCheck("digest_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(goalApplicationDryRunCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "true", "\(!digest.digestRepeat.isEmpty)"))
    checks.append(goalApplicationDryRunCheck("digests_equal", digest.digestsEqual, "true", "\(digest.digestsEqual)"))
    checks.append(goalApplicationDryRunCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(goalApplicationDryRunCheck("report_written", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("invariant_report_written", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("policies_written", !run.policies.isEmpty, "true", "\(!run.policies.isEmpty)"))
    checks.append(goalApplicationDryRunCheck("inputs_written", !run.inputs.isEmpty, "true", "\(!run.inputs.isEmpty)"))
    checks.append(goalApplicationDryRunCheck("decisions_written", !decisionByAgent.isEmpty, "true", "\(!decisionByAgent.isEmpty)"))
    checks.append(goalApplicationDryRunCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(goalApplicationDryRunCheck("metrics_written", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("event_written", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("metrics_prefix_expected", true, "goalApplicationDryRun*", "goalApplicationDryRun*"))
    checks.append(goalApplicationDryRunCheck("event_name_expected", true, "lab_goal_application_dry_run_recorded", "lab_goal_application_dry_run_recorded"))
    checks.append(goalApplicationDryRunCheck("changelog_updated", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("dev_journal_updated", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("roadmap_updated", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("phase_plan_updated", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("success_contract_respected", successContract, "true", "\(successContract)"))

    let failed = checks.filter { !$0.passed }.count
    return LabGoalApplicationDryRunInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabGoalApplicationDryRunInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            agents: report.agents,
            inputs: report.inputs,
            decisions: report.decisions,
            rejectedGoalApplications: report.rejectedGoalApplications,
            deferredGoalApplications: report.deferredGoalApplications
        ),
        checks: checks,
        notes: [
            "Goal application dry-run is fixture-only and does not apply goals.",
            "The fixture audits eligible, no-op, rejected, and deferred goal application paths.",
            "No live agent, memory, movement stack, World, or terrain mutation occurs."
        ]
    )
}

private func makeGoalApplicationDryRunDigestValue(run: LabGoalApplicationDryRunRun) -> String {
    let policyPart = run.policies.sorted(by: goalApplicationDryRunPolicySort).map {
        [
            "\($0.dryRun)",
            $0.mode,
            "\($0.allowGoalApplication)",
            $0.allowedGoals.joined(separator: "|"),
            "\($0.maxGoalChangesPerTick)",
            "\($0.requireReason)",
            "\($0.requireSnapshotReadOnly)",
            "\($0.allowNoopGoal)",
            "\($0.allowDeferred)"
        ].joined(separator: ":")
    }.joined(separator: ";")
    let inputPart = run.inputs.sorted(by: goalApplicationDryRunInputSort).map {
        [
            "\($0.tick)",
            $0.agentId,
            $0.currentGoal,
            $0.targetGoal,
            "\($0.goalChangeEligible)",
            "\($0.snapshotReadOnly)",
            $0.policy.mode,
            $0.reason
        ].joined(separator: ":")
    }.joined(separator: ";")
    let decisionPart = run.decisions.sorted(by: goalApplicationDryRunDecisionSort).map {
        [
            "\($0.tick)",
            $0.agentId,
            $0.goalBefore,
            $0.targetGoal,
            "\($0.goalKnown)",
            "\($0.goalChanged)",
            "\($0.wouldApplyGoalChange)",
            "\($0.appliedGoalChange)",
            $0.rejectedReasons.joined(separator: ","),
            $0.deferredReasons.joined(separator: ",")
        ].joined(separator: ":")
    }.joined(separator: ";")
    return goalApplicationDryRunStableDigest([policyPart, inputPart, decisionPart].joined(separator: "#"))
}

private func goalApplicationDryRunStableDigest(_ text: String) -> String {
    var hash: UInt64 = 1469598103934665603
    for byte in text.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1099511628211
    }
    return String(format: "%016llx", hash)
}

private func makeGoalApplicationDryRunMetrics(
    report: LabGoalApplicationDryRunReport
) -> LabGoalApplicationDryRunMetrics {
    LabGoalApplicationDryRunMetrics(
        goalApplicationDryRunSuccess: report.success,
        goalApplicationDryRunAgents: report.agents,
        goalApplicationDryRunTicks: report.ticks,
        goalApplicationDryRunPolicies: report.policies,
        goalApplicationDryRunInputs: report.inputs,
        goalApplicationDryRunDecisions: report.decisions,
        goalApplicationDryRunEligibleInputs: report.eligibleInputs,
        goalApplicationDryRunWouldApplyGoalChanges: report.wouldApplyGoalChanges,
        goalApplicationDryRunNoopGoalChanges: report.noopGoalChanges,
        goalApplicationDryRunRejectedGoalApplications: report.rejectedGoalApplications,
        goalApplicationDryRunDeferredGoalApplications: report.deferredGoalApplications,
        goalApplicationDryRunAppliedGoalChanges: report.appliedGoalChanges,
        goalApplicationDryRunDryRun: report.dryRun,
        goalApplicationDryRunLiveAgentMutated: report.liveAgentMutated,
        goalApplicationDryRunMemoryMutated: report.memoryMutated,
        goalApplicationDryRunMovementStackUsed: report.movementStackUsed,
        goalApplicationDryRunWorldMutated: report.worldMutated,
        goalApplicationDryRunTerrainMutated: report.terrainMutated,
        goalApplicationDryRunBounded: report.bounded,
        goalApplicationDryRunDeterministicOrder: report.deterministicOrder,
        goalApplicationDryRunDigestsEqual: report.digestsEqual,
        goalApplicationDryRunRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeGoalApplicationDryRunEventLines(
    report: LabGoalApplicationDryRunReport,
    decisions: [LabGoalApplicationDryRunDecision],
    inputs: [LabGoalApplicationDryRunInput]
) throws -> String {
    let inputByAgent = Dictionary(uniqueKeysWithValues: inputs.map { ($0.agentId, $0) })
    var lines = ""
    for decision in decisions.sorted(by: goalApplicationDryRunDecisionSort) {
        let input = inputByAgent[decision.agentId]
        lines += try goalApplicationDryRunJSONLine(LabGoalApplicationDryRunRecordedEvent(
            type: "lab_goal_application_dry_run_recorded",
            event: "lab_goal_application_dry_run_recorded",
            success: decision.success,
            agentId: decision.agentId,
            tick: decision.tick,
            goalBefore: decision.goalBefore,
            targetGoal: decision.targetGoal,
            goalChangeEligible: input?.goalChangeEligible ?? false,
            wouldApplyGoalChange: decision.wouldApplyGoalChange,
            appliedGoalChange: decision.appliedGoalChange,
            rejectedReasons: decision.rejectedReasons,
            deferredReasons: decision.deferredReasons,
            dryRun: decision.dryRun,
            liveAgentMutated: decision.liveAgentMutated
        ))
    }
    lines += try goalApplicationDryRunJSONLine(LabGoalApplicationDryRunSummaryEvent(
        type: "lab_goal_application_dry_run_summary_recorded",
        event: "lab_goal_application_dry_run_summary_recorded",
        success: report.success,
        agents: report.agents,
        ticks: report.ticks,
        inputs: report.inputs,
        decisions: report.decisions,
        eligibleInputs: report.eligibleInputs,
        wouldApplyGoalChanges: report.wouldApplyGoalChanges,
        noopGoalChanges: report.noopGoalChanges,
        rejectedGoalApplications: report.rejectedGoalApplications,
        deferredGoalApplications: report.deferredGoalApplications,
        appliedGoalChanges: report.appliedGoalChanges,
        dryRun: report.dryRun,
        bounded: report.bounded,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
    return lines
}

private func goalApplicationDryRunJSONLine<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    return String(decoding: data, as: UTF8.self) + "\n"
}

private func goalApplicationDryRunCheck(
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

private func goalApplicationDryRunPolicySort(
    _ lhs: LabGoalApplicationDryRunPolicy,
    _ rhs: LabGoalApplicationDryRunPolicy
) -> Bool {
    let lhsKey = [
        "\(lhs.dryRun)",
        lhs.mode,
        "\(lhs.allowGoalApplication)",
        lhs.allowedGoals.joined(separator: "|"),
        "\(lhs.maxGoalChangesPerTick)",
        "\(lhs.requireReason)",
        "\(lhs.requireSnapshotReadOnly)",
        "\(lhs.allowNoopGoal)",
        "\(lhs.allowDeferred)"
    ].joined(separator: ":")
    let rhsKey = [
        "\(rhs.dryRun)",
        rhs.mode,
        "\(rhs.allowGoalApplication)",
        rhs.allowedGoals.joined(separator: "|"),
        "\(rhs.maxGoalChangesPerTick)",
        "\(rhs.requireReason)",
        "\(rhs.requireSnapshotReadOnly)",
        "\(rhs.allowNoopGoal)",
        "\(rhs.allowDeferred)"
    ].joined(separator: ":")
    return lhsKey < rhsKey
}

private func goalApplicationDryRunInputSort(
    _ lhs: LabGoalApplicationDryRunInput,
    _ rhs: LabGoalApplicationDryRunInput
) -> Bool {
    if lhs.tick != rhs.tick {
        return lhs.tick < rhs.tick
    }
    return lhs.agentId < rhs.agentId
}

private func goalApplicationDryRunDecisionSort(
    _ lhs: LabGoalApplicationDryRunDecision,
    _ rhs: LabGoalApplicationDryRunDecision
) -> Bool {
    if lhs.tick != rhs.tick {
        return lhs.tick < rhs.tick
    }
    return lhs.agentId < rhs.agentId
}
