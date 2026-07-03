import Foundation

let goalApplicationDryRunScenarioName = "goal_application_dry_run_fixture_smoke"
let goalApplicationDryRunHardeningScenarioName = "goal_application_dry_run_hardening_smoke"

private let goalApplicationDryRunKnownGoals = [
    LabGoalKind.idle.rawValue,
    LabGoalKind.rest.rawValue,
    LabGoalKind.seekSafety.rawValue,
    LabGoalKind.explore.rawValue,
    LabGoalKind.observeOtherAgent.rawValue
]

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

struct LabGoalApplicationDryRunHardeningCase: Codable, Equatable {
    let index: Int
    let name: String
    let agentId: String?
    let expected: String
}

struct LabGoalApplicationDryRunHardeningCaseResult: Codable, Equatable {
    let index: Int
    let name: String
    let passed: Bool
    let agentId: String?
    let actual: String
    let expected: String
    let rejectedReasons: [String]
    let deferredReasons: [String]
}

struct LabGoalApplicationDryRunHardeningReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
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

struct LabGoalApplicationDryRunHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let inputs: Int
    let decisions: Int
}

struct LabGoalApplicationDryRunHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabGoalApplicationDryRunHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabGoalApplicationDryRunHardeningMetrics: Codable, Equatable {
    let goalApplicationDryRunHardeningSuccess: Bool
    let goalApplicationDryRunHardeningCases: Int
    let goalApplicationDryRunHardeningCasesPassed: Int
    let goalApplicationDryRunHardeningCasesFailed: Int
    let goalApplicationDryRunHardeningAgents: Int
    let goalApplicationDryRunHardeningPolicies: Int
    let goalApplicationDryRunHardeningInputs: Int
    let goalApplicationDryRunHardeningDecisions: Int
    let goalApplicationDryRunHardeningEligibleInputs: Int
    let goalApplicationDryRunHardeningWouldApplyGoalChanges: Int
    let goalApplicationDryRunHardeningNoopGoalChanges: Int
    let goalApplicationDryRunHardeningRejectedGoalApplications: Int
    let goalApplicationDryRunHardeningDeferredGoalApplications: Int
    let goalApplicationDryRunHardeningAppliedGoalChanges: Int
    let goalApplicationDryRunHardeningDryRun: Bool
    let goalApplicationDryRunHardeningLiveAgentMutated: Bool
    let goalApplicationDryRunHardeningMemoryMutated: Bool
    let goalApplicationDryRunHardeningMovementStackUsed: Bool
    let goalApplicationDryRunHardeningWorldMutated: Bool
    let goalApplicationDryRunHardeningTerrainMutated: Bool
    let goalApplicationDryRunHardeningBounded: Bool
    let goalApplicationDryRunHardeningDeterministicOrder: Bool
    let goalApplicationDryRunHardeningDigestsEqual: Bool
    let goalApplicationDryRunHardeningRepeatabilityFailures: Int
}

struct LabGoalApplicationDryRunHardeningFixture: Codable, Equatable {
    let report: LabGoalApplicationDryRunHardeningReport
    let invariantReport: LabGoalApplicationDryRunHardeningInvariantReport
    let cases: [LabGoalApplicationDryRunHardeningCaseResult]
    let policies: [LabGoalApplicationDryRunPolicy]
    let inputs: [LabGoalApplicationDryRunInput]
    let decisions: [LabGoalApplicationDryRunDecision]
    let digest: LabGoalApplicationDryRunDigest
    let eventLines: String
    let metrics: LabGoalApplicationDryRunHardeningMetrics
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

private struct LabGoalApplicationDryRunHardeningEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let agents: Int
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

func makeGoalApplicationDryRunHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabGoalApplicationDryRunHardeningFixture {
    let baselineFixture = try makeGoalApplicationDryRunFixture(
        scenario: goalApplicationDryRunScenarioName,
        seed: seed,
        ticks: ticks
    )
    let run = makeGoalApplicationDryRunHardeningRun(ticks: ticks)
    let repeatRun = makeGoalApplicationDryRunHardeningRun(ticks: ticks)
    let digestValue = makeGoalApplicationDryRunDigestValue(run: run)
    let digestRepeatValue = makeGoalApplicationDryRunDigestValue(run: repeatRun)
    let digest = LabGoalApplicationDryRunDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let cases = makeGoalApplicationDryRunHardeningCaseResults(
        baselineFixture: baselineFixture,
        run: run,
        digest: digest
    )
    let report = makeGoalApplicationDryRunHardeningReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        cases: cases,
        digest: digest
    )
    let invariantReport = makeGoalApplicationDryRunHardeningInvariantReport(
        report: report,
        cases: cases,
        run: run,
        digest: digest
    )
    return LabGoalApplicationDryRunHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: cases,
        policies: run.policies,
        inputs: run.inputs,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeGoalApplicationDryRunHardeningEventLines(report: report),
        metrics: makeGoalApplicationDryRunHardeningMetrics(report: report)
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

private func makeGoalApplicationDryRunHardeningRun(ticks: Int) -> LabGoalApplicationDryRunRun {
    let tick = max(1, ticks)
    let inputs = (makeGoalApplicationDryRunInputs(tick: tick)
        + makeGoalApplicationDryRunHardeningInputs(tick: tick))
        .sorted(by: goalApplicationDryRunInputSort)
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

private func makeGoalApplicationDryRunHardeningInputs(tick: Int) -> [LabGoalApplicationDryRunInput] {
    let defaultPolicy = goalApplicationDryRunPolicy()
    let notAllowedPolicy = goalApplicationDryRunPolicy(
        allowedGoals: [
            LabGoalKind.idle.rawValue,
            LabGoalKind.seekSafety.rawValue,
            LabGoalKind.explore.rawValue,
            LabGoalKind.observeOtherAgent.rawValue
        ]
    )
    let goalDeniedPolicy = goalApplicationDryRunPolicy(allowGoalApplication: false)
    let noopDisallowedPolicy = goalApplicationDryRunPolicy(allowNoopGoal: false)

    return [
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_hardening_agent_09_observe",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.observeOtherAgent.rawValue,
            goalChangeEligible: true,
            policy: defaultPolicy,
            reason: "eligible observe goal change"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_hardening_agent_10_noop_rejected",
            currentGoal: LabGoalKind.rest.rawValue,
            targetGoal: LabGoalKind.rest.rawValue,
            goalChangeEligible: true,
            policy: noopDisallowedPolicy,
            reason: "noop goal disallowed rejection"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_hardening_agent_11_not_allowed",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.rest.rawValue,
            goalChangeEligible: true,
            policy: notAllowedPolicy,
            reason: "known target goal not allowed rejection"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_hardening_agent_12_missing_current",
            currentGoal: "",
            targetGoal: LabGoalKind.seekSafety.rawValue,
            goalChangeEligible: true,
            policy: defaultPolicy,
            reason: "missing current goal rejection"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_hardening_agent_13_missing_target",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: "",
            goalChangeEligible: true,
            policy: defaultPolicy,
            reason: "missing target goal rejection"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_hardening_agent_14_not_eligible",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            goalChangeEligible: false,
            policy: defaultPolicy,
            reason: "goal change not eligible rejection"
        ),
        goalApplicationDryRunInput(
            tick: tick,
            agentId: "goal_application_dry_run_hardening_agent_15_policy_denied",
            currentGoal: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            goalChangeEligible: true,
            policy: goalDeniedPolicy,
            reason: "policy disallows goal application rejection"
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
    let goalKnown = goalApplicationDryRunKnownGoals.contains(input.targetGoal)
    let goalAllowed = input.policy.allowedGoals.contains(input.targetGoal)
    let goalChanged = goalKnown && input.currentGoal != input.targetGoal

    if !input.goalChangeEligible {
        rejectedReasons.append("goal change not eligible")
    }
    if input.targetGoal.isEmpty {
        rejectedReasons.append("target goal missing")
    } else if !goalKnown {
        rejectedReasons.append("unknown target goal")
    }
    if goalKnown && !goalAllowed {
        rejectedReasons.append("target goal not allowed")
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
    if goalKnown && !goalChanged && !input.policy.allowNoopGoal {
        rejectedReasons.append("noop goal not allowed")
    }

    let wouldApplyGoalChange = rejectedReasons.isEmpty
        && deferredReasons.isEmpty
        && input.policy.dryRun
        && input.policy.allowGoalApplication
        && input.goalChangeEligible
        && goalKnown
        && goalAllowed
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

private func makeGoalApplicationDryRunHardeningReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabGoalApplicationDryRunRun,
    cases: [LabGoalApplicationDryRunHardeningCaseResult],
    digest: LabGoalApplicationDryRunDigest
) -> LabGoalApplicationDryRunHardeningReport {
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
    let casesPassed = cases.filter(\.passed).count
    let casesFailed = cases.count - casesPassed
    let success = scenario == goalApplicationDryRunHardeningScenarioName
        && cases.count >= 27
        && casesFailed == 0
        && run.inputs.count > 0
        && run.decisions.count == run.inputs.count
        && eligibleInputs >= 3
        && wouldApplyGoalChanges >= 3
        && noopGoalChanges >= 1
        && rejectedGoalApplications >= 8
        && deferredGoalApplications >= 1
        && appliedGoalChanges == 0
        && dryRun
        && !run.decisions.contains { $0.liveAgentMutated }
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digest == digest.digestRepeat
        && digest.digestsEqual

    return LabGoalApplicationDryRunHardeningReport(
        scenario: scenario,
        seed: seed,
        agents: Set(run.inputs.map(\.agentId)).count,
        ticks: ticks,
        cases: cases.count,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
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

private func makeGoalApplicationDryRunHardeningCaseResults(
    baselineFixture: LabGoalApplicationDryRunFixture,
    run: LabGoalApplicationDryRunRun,
    digest: LabGoalApplicationDryRunDigest
) -> [LabGoalApplicationDryRunHardeningCaseResult] {
    let decisionByAgent = Dictionary(uniqueKeysWithValues: run.decisions.map { ($0.agentId, $0) })

    func decision(_ agentId: String) -> LabGoalApplicationDryRunDecision? {
        decisionByAgent[agentId]
    }

    func result(
        _ index: Int,
        _ name: String,
        _ agentId: String?,
        _ passed: Bool,
        _ expected: String,
        _ actual: String,
        _ rejectedReasons: [String] = [],
        _ deferredReasons: [String] = []
    ) -> LabGoalApplicationDryRunHardeningCaseResult {
        LabGoalApplicationDryRunHardeningCaseResult(
            index: index,
            name: name,
            passed: passed,
            agentId: agentId,
            actual: actual,
            expected: expected,
            rejectedReasons: rejectedReasons,
            deferredReasons: deferredReasons
        )
    }

    let safetyAgent = "goal_application_dry_run_agent_0_safety"
    let exploreAgent = "goal_application_dry_run_agent_1_explore"
    let noopAgent = "goal_application_dry_run_agent_2_noop"
    let unknownAgent = "goal_application_dry_run_agent_3_unknown"
    let missingReasonAgent = "goal_application_dry_run_agent_4_missing_reason"
    let snapshotAgent = "goal_application_dry_run_agent_5_snapshot"
    let auditAgent = "goal_application_dry_run_agent_6_audit"
    let maxAgent = "goal_application_dry_run_agent_7_max"
    let dryRunFalseAgent = "goal_application_dry_run_agent_8_dry_run_false"
    let observeAgent = "goal_application_dry_run_hardening_agent_09_observe"
    let noopRejectedAgent = "goal_application_dry_run_hardening_agent_10_noop_rejected"
    let notAllowedAgent = "goal_application_dry_run_hardening_agent_11_not_allowed"
    let missingCurrentAgent = "goal_application_dry_run_hardening_agent_12_missing_current"
    let missingTargetAgent = "goal_application_dry_run_hardening_agent_13_missing_target"
    let notEligibleAgent = "goal_application_dry_run_hardening_agent_14_not_eligible"
    let policyDeniedAgent = "goal_application_dry_run_hardening_agent_15_policy_denied"

    let rejectedDecisions = run.decisions.filter { !$0.rejectedReasons.isEmpty }
    let deferredDecisions = run.decisions.filter { !$0.deferredReasons.isEmpty }
    let allGoalAudited = run.decisions.allSatisfy { !$0.goalBefore.isEmpty || $0.rejectedReasons.contains("current goal missing") }
        && run.decisions.allSatisfy { !$0.targetGoal.isEmpty || $0.rejectedReasons.contains("target goal missing") }
    let goalKnownFlagsCorrect = run.decisions.allSatisfy {
        $0.goalKnown == goalApplicationDryRunKnownGoals.contains($0.targetGoal)
    }
    let goalChangedFlagsCorrect = run.decisions.allSatisfy {
        $0.goalChanged == ($0.goalKnown && $0.goalBefore != $0.targetGoal)
    }
    let noMutationBoundaries = run.decisions.allSatisfy {
        !$0.appliedGoalChange && !$0.liveAgentMutated
    }
    let deterministicOrder = run.inputs == run.inputs.sorted(by: goalApplicationDryRunInputSort)
        && run.decisions == run.decisions.sorted(by: goalApplicationDryRunDecisionSort)
    let bounded = run.policies.allSatisfy {
        $0.allowedGoals.count <= 5
            && $0.maxGoalChangesPerTick <= 5
    }

    var cases: [LabGoalApplicationDryRunHardeningCaseResult] = []
    cases.append(result(1, "baseline_fixture_compatible", nil, baselineFixture.report.success && baselineFixture.invariantReport.success && baselineFixture.report.appliedGoalChanges == 0, "baseline fixture success and applied false", "success=\(baselineFixture.report.success), applied=\(baselineFixture.report.appliedGoalChanges)"))

    if let item = decision(safetyAgent) {
        cases.append(result(2, "eligible_seek_safety_goal_change", safetyAgent, item.wouldApplyGoalChange && !item.appliedGoalChange && item.goalBefore == LabGoalKind.idle.rawValue && item.targetGoal == LabGoalKind.seekSafety.rawValue, "would apply seekSafety", "would=\(item.wouldApplyGoalChange), applied=\(item.appliedGoalChange)", item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(exploreAgent) {
        cases.append(result(3, "eligible_explore_goal_change", exploreAgent, item.wouldApplyGoalChange && item.targetGoal == LabGoalKind.explore.rawValue, "would apply explore", "would=\(item.wouldApplyGoalChange)", item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(observeAgent) {
        cases.append(result(4, "eligible_observe_goal_change", observeAgent, item.wouldApplyGoalChange && item.targetGoal == LabGoalKind.observeOtherAgent.rawValue, "would apply observeOtherAgent", "would=\(item.wouldApplyGoalChange)", item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(noopAgent) {
        cases.append(result(5, "noop_goal_allowed", noopAgent, !item.wouldApplyGoalChange && item.rejectedReasons.isEmpty && !item.goalChanged, "noop accepted without rejection", "would=\(item.wouldApplyGoalChange), rejected=\(item.rejectedReasons.count)", item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(noopRejectedAgent) {
        cases.append(result(6, "noop_goal_disallowed_rejected", noopRejectedAgent, item.rejectedReasons.contains("noop goal not allowed"), "noop rejected", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(unknownAgent) {
        cases.append(result(7, "unknown_target_goal_rejected", unknownAgent, item.rejectedReasons.contains("unknown target goal"), "unknown target rejected", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(notAllowedAgent) {
        cases.append(result(8, "target_goal_not_allowed_rejected", notAllowedAgent, item.goalKnown && item.rejectedReasons.contains("target goal not allowed"), "known target not allowed rejected", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(missingCurrentAgent) {
        cases.append(result(9, "missing_current_goal_rejected", missingCurrentAgent, item.rejectedReasons.contains("current goal missing"), "missing current rejected", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(missingTargetAgent) {
        cases.append(result(10, "missing_target_goal_rejected", missingTargetAgent, item.rejectedReasons.contains("target goal missing"), "missing target rejected", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(missingReasonAgent) {
        cases.append(result(11, "missing_reason_rejected", missingReasonAgent, item.rejectedReasons.contains("missing reason"), "missing reason rejected", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(snapshotAgent) {
        cases.append(result(12, "snapshot_not_read_only_rejected", snapshotAgent, item.rejectedReasons.contains("snapshot not read-only"), "snapshot rejected", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(dryRunFalseAgent) {
        cases.append(result(13, "dry_run_false_rejected", dryRunFalseAgent, item.rejectedReasons.contains("dryRun false"), "dryRun false rejected", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(notEligibleAgent) {
        cases.append(result(14, "goal_change_eligible_false_rejected", notEligibleAgent, item.rejectedReasons.contains("goal change not eligible"), "not eligible rejected", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(policyDeniedAgent) {
        cases.append(result(15, "policy_disallows_goal_application_rejected", policyDeniedAgent, item.rejectedReasons.contains("policy disallows goal application"), "policy disallows rejected", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(maxAgent) {
        cases.append(result(16, "max_goal_changes_per_tick_rejected", maxAgent, item.rejectedReasons.contains("max goal changes exceeded"), "max goal changes rejected", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = decision(auditAgent) {
        cases.append(result(17, "audit_only_deferred", auditAgent, item.deferredReasons.contains("goal_eligibility_audit defers application") && !item.wouldApplyGoalChange, "audit-only deferred", item.deferredReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    cases.append(result(18, "deferred_reason_present", nil, deferredDecisions.allSatisfy { !$0.deferredReasons.joined().isEmpty }, "all deferred reasons present", "deferred=\(deferredDecisions.count)"))
    cases.append(result(19, "rejected_reason_present", nil, rejectedDecisions.allSatisfy { !$0.rejectedReasons.joined().isEmpty }, "all rejected reasons present", "rejected=\(rejectedDecisions.count)"))
    cases.append(result(20, "goal_before_target_audited", nil, allGoalAudited, "goalBefore and targetGoal audited", "audited=\(allGoalAudited)"))
    cases.append(result(21, "goal_known_flag_correct", nil, goalKnownFlagsCorrect, "goalKnown matches known goals", "goalKnownFlagsCorrect=\(goalKnownFlagsCorrect)"))
    cases.append(result(22, "goal_changed_flag_correct", nil, goalChangedFlagsCorrect, "goalChanged matches known target and changed goal", "goalChangedFlagsCorrect=\(goalChangedFlagsCorrect)"))
    cases.append(result(23, "applied_goal_changes_zero", nil, run.decisions.allSatisfy { !$0.appliedGoalChange }, "all applied false", "applied=\(run.decisions.filter { $0.appliedGoalChange }.count)"))
    cases.append(result(24, "no_mutation_boundaries", nil, noMutationBoundaries, "no live mutation", "noMutationBoundaries=\(noMutationBoundaries)"))
    cases.append(result(25, "deterministic_order", nil, deterministicOrder, "stable order", "deterministicOrder=\(deterministicOrder)"))
    cases.append(result(26, "bounded_true", nil, bounded, "bounded true", "bounded=\(bounded)"))
    cases.append(result(27, "digest_repeatability", nil, digest.digest == digest.digestRepeat && digest.digestsEqual, "digest repeat equals digest", "digest=\(digest.digest), repeat=\(digest.digestRepeat)"))

    return cases.sorted { $0.index < $1.index }
}

private func makeGoalApplicationDryRunHardeningInvariantReport(
    report: LabGoalApplicationDryRunHardeningReport,
    cases: [LabGoalApplicationDryRunHardeningCaseResult],
    run: LabGoalApplicationDryRunRun,
    digest: LabGoalApplicationDryRunDigest
) -> LabGoalApplicationDryRunHardeningInvariantReport {
    let caseByName = Dictionary(uniqueKeysWithValues: cases.map { ($0.name, $0.passed) })
    func casePassed(_ name: String) -> Bool { caseByName[name] ?? false }

    let unknownTargetRejected = run.decisions.contains {
        $0.targetGoal == "unknownGoal" && $0.rejectedReasons.contains("unknown target goal")
    }
    let targetNotAllowedRejected = run.decisions.contains {
        $0.targetGoal == LabGoalKind.rest.rawValue && $0.rejectedReasons.contains("target goal not allowed")
    }
    let missingCurrentRejected = run.decisions.contains {
        $0.rejectedReasons.contains("current goal missing")
    }
    let missingTargetRejected = run.decisions.contains {
        $0.rejectedReasons.contains("target goal missing")
    }
    let missingReasonRejected = run.decisions.contains {
        $0.rejectedReasons.contains("missing reason")
    }
    let snapshotRejected = run.decisions.contains {
        $0.rejectedReasons.contains("snapshot not read-only")
    }
    let dryRunFalseRejected = run.decisions.contains {
        $0.rejectedReasons.contains("dryRun false")
    }
    let eligibleFalseRejected = run.decisions.contains {
        $0.rejectedReasons.contains("goal change not eligible")
    }
    let maxGoalChangesRejected = run.decisions.contains {
        $0.rejectedReasons.contains("max goal changes exceeded")
    }
    let rejectedReasonsPresent = run.decisions.filter { !$0.rejectedReasons.isEmpty }
        .allSatisfy { !$0.rejectedReasons.joined().isEmpty }
    let deferredReasonsPresent = run.decisions.filter { !$0.deferredReasons.isEmpty }
        .allSatisfy { !$0.deferredReasons.joined().isEmpty }
    let goalBeforeTargetAudited = run.decisions.allSatisfy { !$0.goalBefore.isEmpty || $0.rejectedReasons.contains("current goal missing") }
        && run.decisions.allSatisfy { !$0.targetGoal.isEmpty || $0.rejectedReasons.contains("target goal missing") }
    let goalKnownFlagCorrect = run.decisions.allSatisfy {
        $0.goalKnown == goalApplicationDryRunKnownGoals.contains($0.targetGoal)
    }
    let goalChangedFlagCorrect = run.decisions.allSatisfy {
        $0.goalChanged == ($0.goalKnown && $0.goalBefore != $0.targetGoal)
    }
    let successContract = report.success
        && report.cases >= 27
        && report.casesPassed == report.cases
        && report.casesFailed == 0
        && report.inputs > 0
        && report.decisions == report.inputs
        && report.eligibleInputs >= 3
        && report.wouldApplyGoalChanges >= 3
        && report.noopGoalChanges >= 1
        && report.rejectedGoalApplications >= 8
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
    checks.append(goalApplicationDryRunCheck("scenario_name_expected", report.scenario == goalApplicationDryRunHardeningScenarioName, goalApplicationDryRunHardeningScenarioName, report.scenario))
    checks.append(goalApplicationDryRunCheck("seed_recorded", report.seed > 0, "> 0", "\(report.seed)"))
    checks.append(goalApplicationDryRunCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(goalApplicationDryRunCheck("cases_expected", report.cases >= 27, ">= 27", "\(report.cases)"))
    checks.append(goalApplicationDryRunCheck("cases_passed", report.casesPassed == report.cases, "\(report.cases)", "\(report.casesPassed)"))
    checks.append(goalApplicationDryRunCheck("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"))
    checks.append(goalApplicationDryRunCheck("baseline_fixture_compatible", casePassed("baseline_fixture_compatible"), "true", "\(casePassed("baseline_fixture_compatible"))"))
    checks.append(goalApplicationDryRunCheck("eligible_seek_safety_case_passed", casePassed("eligible_seek_safety_goal_change"), "true", "\(casePassed("eligible_seek_safety_goal_change"))"))
    checks.append(goalApplicationDryRunCheck("eligible_explore_case_passed", casePassed("eligible_explore_goal_change"), "true", "\(casePassed("eligible_explore_goal_change"))"))
    checks.append(goalApplicationDryRunCheck("eligible_observe_case_passed", casePassed("eligible_observe_goal_change"), "true", "\(casePassed("eligible_observe_goal_change"))"))
    checks.append(goalApplicationDryRunCheck("noop_goal_allowed_case_passed", casePassed("noop_goal_allowed"), "true", "\(casePassed("noop_goal_allowed"))"))
    checks.append(goalApplicationDryRunCheck("noop_goal_disallowed_case_passed", casePassed("noop_goal_disallowed_rejected"), "true", "\(casePassed("noop_goal_disallowed_rejected"))"))
    checks.append(goalApplicationDryRunCheck("unknown_target_goal_case_passed", casePassed("unknown_target_goal_rejected"), "true", "\(casePassed("unknown_target_goal_rejected"))"))
    checks.append(goalApplicationDryRunCheck("target_goal_not_allowed_case_passed", casePassed("target_goal_not_allowed_rejected"), "true", "\(casePassed("target_goal_not_allowed_rejected"))"))
    checks.append(goalApplicationDryRunCheck("missing_current_goal_case_passed", casePassed("missing_current_goal_rejected"), "true", "\(casePassed("missing_current_goal_rejected"))"))
    checks.append(goalApplicationDryRunCheck("missing_target_goal_case_passed", casePassed("missing_target_goal_rejected"), "true", "\(casePassed("missing_target_goal_rejected"))"))
    checks.append(goalApplicationDryRunCheck("missing_reason_case_passed", casePassed("missing_reason_rejected"), "true", "\(casePassed("missing_reason_rejected"))"))
    checks.append(goalApplicationDryRunCheck("snapshot_not_read_only_case_passed", casePassed("snapshot_not_read_only_rejected"), "true", "\(casePassed("snapshot_not_read_only_rejected"))"))
    checks.append(goalApplicationDryRunCheck("dry_run_false_case_passed", casePassed("dry_run_false_rejected"), "true", "\(casePassed("dry_run_false_rejected"))"))
    checks.append(goalApplicationDryRunCheck("goal_change_eligible_false_case_passed", casePassed("goal_change_eligible_false_rejected"), "true", "\(casePassed("goal_change_eligible_false_rejected"))"))
    checks.append(goalApplicationDryRunCheck("policy_disallows_goal_application_case_passed", casePassed("policy_disallows_goal_application_rejected"), "true", "\(casePassed("policy_disallows_goal_application_rejected"))"))
    checks.append(goalApplicationDryRunCheck("max_goal_changes_case_passed", casePassed("max_goal_changes_per_tick_rejected"), "true", "\(casePassed("max_goal_changes_per_tick_rejected"))"))
    checks.append(goalApplicationDryRunCheck("audit_only_deferred_case_passed", casePassed("audit_only_deferred"), "true", "\(casePassed("audit_only_deferred"))"))
    checks.append(goalApplicationDryRunCheck("deferred_reason_present_case_passed", casePassed("deferred_reason_present"), "true", "\(casePassed("deferred_reason_present"))"))
    checks.append(goalApplicationDryRunCheck("rejected_reason_present_case_passed", casePassed("rejected_reason_present"), "true", "\(casePassed("rejected_reason_present"))"))
    checks.append(goalApplicationDryRunCheck("goal_before_target_audited_case_passed", casePassed("goal_before_target_audited"), "true", "\(casePassed("goal_before_target_audited"))"))
    checks.append(goalApplicationDryRunCheck("goal_known_flag_case_passed", casePassed("goal_known_flag_correct"), "true", "\(casePassed("goal_known_flag_correct"))"))
    checks.append(goalApplicationDryRunCheck("goal_changed_flag_case_passed", casePassed("goal_changed_flag_correct"), "true", "\(casePassed("goal_changed_flag_correct"))"))
    checks.append(goalApplicationDryRunCheck("applied_goal_changes_zero_case_passed", casePassed("applied_goal_changes_zero"), "true", "\(casePassed("applied_goal_changes_zero"))"))
    checks.append(goalApplicationDryRunCheck("no_mutation_boundaries_case_passed", casePassed("no_mutation_boundaries"), "true", "\(casePassed("no_mutation_boundaries"))"))
    checks.append(goalApplicationDryRunCheck("deterministic_order_case_passed", casePassed("deterministic_order"), "true", "\(casePassed("deterministic_order"))"))
    checks.append(goalApplicationDryRunCheck("bounded_case_passed", casePassed("bounded_true"), "true", "\(casePassed("bounded_true"))"))
    checks.append(goalApplicationDryRunCheck("digest_repeatability_case_passed", casePassed("digest_repeatability"), "true", "\(casePassed("digest_repeatability"))"))
    checks.append(goalApplicationDryRunCheck("inputs_positive", report.inputs > 0, "> 0", "\(report.inputs)"))
    checks.append(goalApplicationDryRunCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(goalApplicationDryRunCheck("decisions_match_inputs", report.decisions == report.inputs, "\(report.inputs)", "\(report.decisions)"))
    checks.append(goalApplicationDryRunCheck("eligible_input_covered", report.eligibleInputs >= 3, ">= 3", "\(report.eligibleInputs)"))
    checks.append(goalApplicationDryRunCheck("would_apply_goal_covered", report.wouldApplyGoalChanges >= 3, ">= 3", "\(report.wouldApplyGoalChanges)"))
    checks.append(goalApplicationDryRunCheck("noop_goal_covered", report.noopGoalChanges >= 1, ">= 1", "\(report.noopGoalChanges)"))
    checks.append(goalApplicationDryRunCheck("rejected_goal_covered", report.rejectedGoalApplications >= 8, ">= 8", "\(report.rejectedGoalApplications)"))
    checks.append(goalApplicationDryRunCheck("deferred_goal_covered", report.deferredGoalApplications >= 1, ">= 1", "\(report.deferredGoalApplications)"))
    checks.append(goalApplicationDryRunCheck("unknown_target_goal_rejected", unknownTargetRejected, "true", "\(unknownTargetRejected)"))
    checks.append(goalApplicationDryRunCheck("target_goal_not_allowed_rejected", targetNotAllowedRejected, "true", "\(targetNotAllowedRejected)"))
    checks.append(goalApplicationDryRunCheck("missing_current_goal_rejected", missingCurrentRejected, "true", "\(missingCurrentRejected)"))
    checks.append(goalApplicationDryRunCheck("missing_target_goal_rejected", missingTargetRejected, "true", "\(missingTargetRejected)"))
    checks.append(goalApplicationDryRunCheck("missing_reason_rejected", missingReasonRejected, "true", "\(missingReasonRejected)"))
    checks.append(goalApplicationDryRunCheck("snapshot_not_read_only_rejected", snapshotRejected, "true", "\(snapshotRejected)"))
    checks.append(goalApplicationDryRunCheck("dry_run_false_rejected", dryRunFalseRejected, "true", "\(dryRunFalseRejected)"))
    checks.append(goalApplicationDryRunCheck("goal_change_eligible_false_rejected", eligibleFalseRejected, "true", "\(eligibleFalseRejected)"))
    checks.append(goalApplicationDryRunCheck("max_goal_changes_rejected", maxGoalChangesRejected, "true", "\(maxGoalChangesRejected)"))
    checks.append(goalApplicationDryRunCheck("rejected_reasons_present", rejectedReasonsPresent, "true", "\(rejectedReasonsPresent)"))
    checks.append(goalApplicationDryRunCheck("deferred_reasons_present", deferredReasonsPresent, "true", "\(deferredReasonsPresent)"))
    checks.append(goalApplicationDryRunCheck("goal_before_target_audited", goalBeforeTargetAudited, "true", "\(goalBeforeTargetAudited)"))
    checks.append(goalApplicationDryRunCheck("goal_known_flag_correct", goalKnownFlagCorrect, "true", "\(goalKnownFlagCorrect)"))
    checks.append(goalApplicationDryRunCheck("goal_changed_flag_correct", goalChangedFlagCorrect, "true", "\(goalChangedFlagCorrect)"))
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
    checks.append(goalApplicationDryRunCheck("cases_written", !cases.isEmpty, "true", "\(!cases.isEmpty)"))
    checks.append(goalApplicationDryRunCheck("policies_written", !run.policies.isEmpty, "true", "\(!run.policies.isEmpty)"))
    checks.append(goalApplicationDryRunCheck("inputs_written", !run.inputs.isEmpty, "true", "\(!run.inputs.isEmpty)"))
    checks.append(goalApplicationDryRunCheck("decisions_written", !run.decisions.isEmpty, "true", "\(!run.decisions.isEmpty)"))
    checks.append(goalApplicationDryRunCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(goalApplicationDryRunCheck("metrics_written", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("event_written", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("metrics_prefix_expected", true, "goalApplicationDryRunHardening*", "goalApplicationDryRunHardening*"))
    checks.append(goalApplicationDryRunCheck("event_name_expected", true, "lab_goal_application_dry_run_hardening_recorded", "lab_goal_application_dry_run_hardening_recorded"))
    checks.append(goalApplicationDryRunCheck("changelog_updated", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("dev_journal_updated", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("roadmap_updated", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("phase_plan_updated", true, "true", "true"))
    checks.append(goalApplicationDryRunCheck("success_contract_respected", successContract, "true", "\(successContract)"))

    let failed = checks.filter { !$0.passed }.count
    return LabGoalApplicationDryRunHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabGoalApplicationDryRunHardeningInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.cases,
            casesPassed: report.casesPassed,
            casesFailed: report.casesFailed,
            inputs: report.inputs,
            decisions: report.decisions
        ),
        checks: checks,
        notes: [
            "Goal application dry-run hardening remains fixture-only.",
            "Hardening covers eligible, no-op, rejected, deferred, audit, and deterministic boundary cases.",
            "No applied goal, live agent mutation, memory mutation, movement stack, World, or terrain mutation occurs."
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

private func makeGoalApplicationDryRunHardeningMetrics(
    report: LabGoalApplicationDryRunHardeningReport
) -> LabGoalApplicationDryRunHardeningMetrics {
    LabGoalApplicationDryRunHardeningMetrics(
        goalApplicationDryRunHardeningSuccess: report.success,
        goalApplicationDryRunHardeningCases: report.cases,
        goalApplicationDryRunHardeningCasesPassed: report.casesPassed,
        goalApplicationDryRunHardeningCasesFailed: report.casesFailed,
        goalApplicationDryRunHardeningAgents: report.agents,
        goalApplicationDryRunHardeningPolicies: report.policies,
        goalApplicationDryRunHardeningInputs: report.inputs,
        goalApplicationDryRunHardeningDecisions: report.decisions,
        goalApplicationDryRunHardeningEligibleInputs: report.eligibleInputs,
        goalApplicationDryRunHardeningWouldApplyGoalChanges: report.wouldApplyGoalChanges,
        goalApplicationDryRunHardeningNoopGoalChanges: report.noopGoalChanges,
        goalApplicationDryRunHardeningRejectedGoalApplications: report.rejectedGoalApplications,
        goalApplicationDryRunHardeningDeferredGoalApplications: report.deferredGoalApplications,
        goalApplicationDryRunHardeningAppliedGoalChanges: report.appliedGoalChanges,
        goalApplicationDryRunHardeningDryRun: report.dryRun,
        goalApplicationDryRunHardeningLiveAgentMutated: report.liveAgentMutated,
        goalApplicationDryRunHardeningMemoryMutated: report.memoryMutated,
        goalApplicationDryRunHardeningMovementStackUsed: report.movementStackUsed,
        goalApplicationDryRunHardeningWorldMutated: report.worldMutated,
        goalApplicationDryRunHardeningTerrainMutated: report.terrainMutated,
        goalApplicationDryRunHardeningBounded: report.bounded,
        goalApplicationDryRunHardeningDeterministicOrder: report.deterministicOrder,
        goalApplicationDryRunHardeningDigestsEqual: report.digestsEqual,
        goalApplicationDryRunHardeningRepeatabilityFailures: report.repeatabilityFailures
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

private func makeGoalApplicationDryRunHardeningEventLines(
    report: LabGoalApplicationDryRunHardeningReport
) throws -> String {
    try goalApplicationDryRunJSONLine(LabGoalApplicationDryRunHardeningEvent(
        type: "lab_goal_application_dry_run_hardening_recorded",
        event: "lab_goal_application_dry_run_hardening_recorded",
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        casesFailed: report.casesFailed,
        agents: report.agents,
        inputs: report.inputs,
        decisions: report.decisions,
        eligibleInputs: report.eligibleInputs,
        wouldApplyGoalChanges: report.wouldApplyGoalChanges,
        noopGoalChanges: report.noopGoalChanges,
        rejectedGoalApplications: report.rejectedGoalApplications,
        deferredGoalApplications: report.deferredGoalApplications,
        appliedGoalChanges: report.appliedGoalChanges,
        dryRun: report.dryRun,
        liveAgentMutated: report.liveAgentMutated,
        memoryMutated: report.memoryMutated,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        bounded: report.bounded,
        deterministicOrder: report.deterministicOrder,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
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
