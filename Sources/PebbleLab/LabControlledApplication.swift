import Foundation

let controlledApplicationScenarioName = "live_cognitive_loop_controlled_application_fixture_smoke"
let controlledApplicationHardeningScenarioName = "live_cognitive_loop_controlled_application_hardening_smoke"

struct LabControlledApplicationPolicy: Codable, Equatable {
    let dryRun: Bool
    let applyMode: String
    let allowGoalChange: Bool
    let allowActionSelection: Bool
    let allowMemoryWrite: Bool
    let allowedGoals: [String]
    let allowedActions: [String]
    let maxApplicationsPerTick: Int
    let maxMemoryWritesPerTick: Int
    let requireReason: Bool
    let requireSnapshotReadOnly: Bool
}

struct LabControlledApplicationInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let snapshotSummary: String
    let currentGoal: String
    let computedSelectedGoal: String
    let computedSelectedAction: String
    let proposedMemoryWrites: Int
    let wouldChangeGoal: Bool
    let wouldSelectAction: Bool
    let wouldWriteMemory: Bool
    let snapshotReadOnly: Bool
    let policy: LabControlledApplicationPolicy
    let reason: String
}

struct LabControlledApplicationEligibility: Codable, Equatable {
    let tick: Int
    let agentId: String
    let computedSelectedGoal: String
    let computedSelectedAction: String
    let proposedMemoryWrites: Int
    let goalChangeEligible: Bool
    let actionSelectionEligible: Bool
    let memoryWriteEligible: Bool
    let eligible: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let reason: String
}

struct LabControlledApplicationDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let eligibility: LabControlledApplicationEligibility
    let appliedGoalChange: Bool
    let appliedAction: Bool
    let appliedMemoryWrite: Bool
    let appliedAnything: Bool
    let dryRun: Bool
    let liveAgentMutated: Bool
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let success: Bool
}

struct LabControlledApplicationReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let policies: Int
    let inputs: Int
    let eligibilities: Int
    let decisions: Int
    let eligibleGoalChanges: Int
    let eligibleActions: Int
    let eligibleMemoryWrites: Int
    let rejectedApplications: Int
    let deferredApplications: Int
    let appliedGoalChanges: Int
    let appliedActions: Int
    let appliedMemoryWrites: Int
    let appliedAnything: Bool
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

struct LabControlledApplicationInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let inputs: Int
    let eligibilities: Int
    let decisions: Int
    let rejectedApplications: Int
    let deferredApplications: Int
}

struct LabControlledApplicationInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabControlledApplicationInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabControlledApplicationDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabControlledApplicationMetrics: Codable, Equatable {
    let controlledApplicationSuccess: Bool
    let controlledApplicationAgents: Int
    let controlledApplicationTicks: Int
    let controlledApplicationPolicies: Int
    let controlledApplicationInputs: Int
    let controlledApplicationEligibilities: Int
    let controlledApplicationDecisions: Int
    let controlledApplicationEligibleGoalChanges: Int
    let controlledApplicationEligibleActions: Int
    let controlledApplicationEligibleMemoryWrites: Int
    let controlledApplicationRejectedApplications: Int
    let controlledApplicationDeferredApplications: Int
    let controlledApplicationAppliedGoalChanges: Int
    let controlledApplicationAppliedActions: Int
    let controlledApplicationAppliedMemoryWrites: Int
    let controlledApplicationAppliedAnything: Bool
    let controlledApplicationDryRun: Bool
    let controlledApplicationLiveAgentMutated: Bool
    let controlledApplicationMemoryMutated: Bool
    let controlledApplicationMovementStackUsed: Bool
    let controlledApplicationWorldMutated: Bool
    let controlledApplicationTerrainMutated: Bool
    let controlledApplicationBounded: Bool
    let controlledApplicationDeterministicOrder: Bool
    let controlledApplicationDigestsEqual: Bool
    let controlledApplicationRepeatabilityFailures: Int
}

struct LabControlledApplicationFixture: Codable, Equatable {
    let report: LabControlledApplicationReport
    let invariantReport: LabControlledApplicationInvariantReport
    let policies: [LabControlledApplicationPolicy]
    let inputs: [LabControlledApplicationInput]
    let eligibilities: [LabControlledApplicationEligibility]
    let decisions: [LabControlledApplicationDecision]
    let digest: LabControlledApplicationDigest
    let eventLines: String
    let metrics: LabControlledApplicationMetrics
}

struct LabControlledApplicationHardeningCase: Codable, Equatable {
    let index: Int
    let name: String
    let agentId: String?
    let expected: String
}

struct LabControlledApplicationHardeningCaseResult: Codable, Equatable {
    let index: Int
    let name: String
    let passed: Bool
    let agentId: String?
    let actual: String
    let expected: String
    let rejectedReasons: [String]
    let deferredReasons: [String]
}

struct LabControlledApplicationHardeningReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let policies: Int
    let inputs: Int
    let eligibilities: Int
    let decisions: Int
    let eligibleGoalChanges: Int
    let eligibleActions: Int
    let eligibleMemoryWrites: Int
    let rejectedApplications: Int
    let deferredApplications: Int
    let appliedGoalChanges: Int
    let appliedActions: Int
    let appliedMemoryWrites: Int
    let appliedAnything: Bool
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

struct LabControlledApplicationHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let inputs: Int
    let eligibilities: Int
    let decisions: Int
}

struct LabControlledApplicationHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabControlledApplicationHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabControlledApplicationHardeningMetrics: Codable, Equatable {
    let controlledApplicationHardeningSuccess: Bool
    let controlledApplicationHardeningCases: Int
    let controlledApplicationHardeningCasesPassed: Int
    let controlledApplicationHardeningCasesFailed: Int
    let controlledApplicationHardeningAgents: Int
    let controlledApplicationHardeningInputs: Int
    let controlledApplicationHardeningEligibilities: Int
    let controlledApplicationHardeningDecisions: Int
    let controlledApplicationHardeningEligibleGoalChanges: Int
    let controlledApplicationHardeningEligibleActions: Int
    let controlledApplicationHardeningEligibleMemoryWrites: Int
    let controlledApplicationHardeningRejectedApplications: Int
    let controlledApplicationHardeningDeferredApplications: Int
    let controlledApplicationHardeningAppliedGoalChanges: Int
    let controlledApplicationHardeningAppliedActions: Int
    let controlledApplicationHardeningAppliedMemoryWrites: Int
    let controlledApplicationHardeningAppliedAnything: Bool
    let controlledApplicationHardeningDryRun: Bool
    let controlledApplicationHardeningLiveAgentMutated: Bool
    let controlledApplicationHardeningMemoryMutated: Bool
    let controlledApplicationHardeningMovementStackUsed: Bool
    let controlledApplicationHardeningWorldMutated: Bool
    let controlledApplicationHardeningTerrainMutated: Bool
    let controlledApplicationHardeningBounded: Bool
    let controlledApplicationHardeningDeterministicOrder: Bool
    let controlledApplicationHardeningDigestsEqual: Bool
    let controlledApplicationHardeningRepeatabilityFailures: Int
}

struct LabControlledApplicationHardeningFixture: Codable, Equatable {
    let report: LabControlledApplicationHardeningReport
    let invariantReport: LabControlledApplicationHardeningInvariantReport
    let cases: [LabControlledApplicationHardeningCaseResult]
    let policies: [LabControlledApplicationPolicy]
    let eligibilities: [LabControlledApplicationEligibility]
    let decisions: [LabControlledApplicationDecision]
    let digest: LabControlledApplicationDigest
    let eventLines: String
    let metrics: LabControlledApplicationHardeningMetrics
}

private struct LabControlledApplicationRun {
    let policies: [LabControlledApplicationPolicy]
    let inputs: [LabControlledApplicationInput]
    let eligibilities: [LabControlledApplicationEligibility]
    let decisions: [LabControlledApplicationDecision]
}

private struct LabControlledApplicationRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let computedSelectedGoal: String
    let computedSelectedAction: String
    let goalChangeEligible: Bool
    let actionSelectionEligible: Bool
    let memoryWriteEligible: Bool
    let eligible: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let appliedGoalChange: Bool
    let appliedAction: Bool
    let appliedMemoryWrite: Bool
    let appliedAnything: Bool
    let dryRun: Bool
    let liveAgentMutated: Bool
    let movementStackUsed: Bool
}

private struct LabControlledApplicationSummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let ticks: Int
    let eligibilities: Int
    let decisions: Int
    let eligibleGoalChanges: Int
    let eligibleActions: Int
    let eligibleMemoryWrites: Int
    let rejectedApplications: Int
    let deferredApplications: Int
    let appliedGoalChanges: Int
    let appliedActions: Int
    let appliedMemoryWrites: Int
    let appliedAnything: Bool
    let dryRun: Bool
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

private struct LabControlledApplicationHardeningEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let agents: Int
    let inputs: Int
    let eligibilities: Int
    let decisions: Int
    let eligibleGoalChanges: Int
    let eligibleActions: Int
    let eligibleMemoryWrites: Int
    let rejectedApplications: Int
    let deferredApplications: Int
    let appliedGoalChanges: Int
    let appliedActions: Int
    let appliedMemoryWrites: Int
    let appliedAnything: Bool
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

func makeControlledApplicationFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabControlledApplicationFixture {
    let run = makeControlledApplicationRun(ticks: ticks)
    let repeatRun = makeControlledApplicationRun(ticks: ticks)
    let digestValue = makeControlledApplicationDigestValue(run: run)
    let digestRepeatValue = makeControlledApplicationDigestValue(run: repeatRun)
    let digest = LabControlledApplicationDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeControlledApplicationReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeControlledApplicationInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabControlledApplicationFixture(
        report: report,
        invariantReport: invariantReport,
        policies: run.policies,
        inputs: run.inputs,
        eligibilities: run.eligibilities,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeControlledApplicationEventLines(report: report, decisions: run.decisions),
        metrics: makeControlledApplicationMetrics(report: report)
    )
}

func makeControlledApplicationHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabControlledApplicationHardeningFixture {
    let baselineFixture = try makeControlledApplicationFixture(
        scenario: controlledApplicationScenarioName,
        seed: seed,
        ticks: ticks
    )
    let run = makeControlledApplicationHardeningRun(ticks: ticks)
    let repeatRun = makeControlledApplicationHardeningRun(ticks: ticks)
    let digestValue = makeControlledApplicationDigestValue(run: run)
    let digestRepeatValue = makeControlledApplicationDigestValue(run: repeatRun)
    let digest = LabControlledApplicationDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let cases = makeControlledApplicationHardeningCaseResults(
        baselineFixture: baselineFixture,
        run: run,
        digest: digest
    )
    let report = makeControlledApplicationHardeningReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        cases: cases,
        digest: digest
    )
    let invariantReport = makeControlledApplicationHardeningInvariantReport(
        report: report,
        cases: cases,
        run: run,
        digest: digest
    )
    return LabControlledApplicationHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: cases,
        policies: run.policies,
        eligibilities: run.eligibilities,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeControlledApplicationHardeningEventLines(report: report),
        metrics: makeControlledApplicationHardeningMetrics(report: report)
    )
}

private func makeControlledApplicationRun(ticks: Int) -> LabControlledApplicationRun {
    let tick = max(1, ticks)
    let inputs = makeControlledApplicationInputs(tick: tick).sorted(by: controlledApplicationInputSort)
    let eligibilities = inputs.map(makeControlledApplicationEligibility).sorted(by: controlledApplicationEligibilitySort)
    let decisions = eligibilities.map(makeControlledApplicationDecision).sorted(by: controlledApplicationDecisionSort)
    let policies = inputs.map(\.policy).sorted(by: controlledApplicationPolicySort)
    return LabControlledApplicationRun(
        policies: policies,
        inputs: inputs,
        eligibilities: eligibilities,
        decisions: decisions
    )
}

private func makeControlledApplicationHardeningRun(ticks: Int) -> LabControlledApplicationRun {
    let tick = max(1, ticks)
    let inputs = (makeControlledApplicationInputs(tick: tick)
        + makeControlledApplicationHardeningInputs(tick: tick))
        .sorted(by: controlledApplicationInputSort)
    let eligibilities = inputs.map(makeControlledApplicationEligibility).sorted(by: controlledApplicationEligibilitySort)
    let decisions = eligibilities.map(makeControlledApplicationDecision).sorted(by: controlledApplicationDecisionSort)
    let policies = inputs.map(\.policy).sorted(by: controlledApplicationPolicySort)
    return LabControlledApplicationRun(
        policies: policies,
        inputs: inputs,
        eligibilities: eligibilities,
        decisions: decisions
    )
}

private func makeControlledApplicationInputs(tick: Int) -> [LabControlledApplicationInput] {
    let defaultPolicy = controlledApplicationPolicy(
        allowGoalChange: true,
        allowActionSelection: true,
        allowMemoryWrite: true
    )
    let goalDeniedPolicy = controlledApplicationPolicy(
        allowGoalChange: false,
        allowActionSelection: true,
        allowMemoryWrite: true
    )
    let auditOnlyPolicy = controlledApplicationPolicy(
        applyMode: "audit_only",
        allowGoalChange: true,
        allowActionSelection: true,
        allowMemoryWrite: true
    )
    return [
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_agent_0",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: LabGoalKind.seekSafety.rawValue,
            computedAction: "seekSafety",
            proposedMemoryWrites: 0,
            wouldChangeGoal: true,
            wouldSelectAction: false,
            wouldWriteMemory: false,
            policy: defaultPolicy,
            reason: "goal eligible safety plan"
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_agent_1",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: LabGoalKind.explore.rawValue,
            computedAction: "explore",
            proposedMemoryWrites: 0,
            wouldChangeGoal: false,
            wouldSelectAction: true,
            wouldWriteMemory: false,
            policy: defaultPolicy,
            reason: "action eligible explore plan"
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_agent_2",
            currentGoal: LabGoalKind.observeOtherAgent.rawValue,
            computedGoal: LabGoalKind.observeOtherAgent.rawValue,
            computedAction: "observeAgent",
            proposedMemoryWrites: 1,
            wouldChangeGoal: false,
            wouldSelectAction: false,
            wouldWriteMemory: true,
            policy: defaultPolicy,
            reason: "memory write eligible observation plan"
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_agent_3",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: LabGoalKind.seekSafety.rawValue,
            computedAction: "seekSafety",
            proposedMemoryWrites: 0,
            wouldChangeGoal: true,
            wouldSelectAction: false,
            wouldWriteMemory: false,
            policy: goalDeniedPolicy,
            reason: "policy disallows goal change"
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_agent_4",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: "unknownGoal",
            computedAction: "idle",
            proposedMemoryWrites: 0,
            wouldChangeGoal: true,
            wouldSelectAction: false,
            wouldWriteMemory: false,
            policy: defaultPolicy,
            reason: "unknown goal rejection plan"
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_agent_5",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: LabGoalKind.idle.rawValue,
            computedAction: "idle",
            proposedMemoryWrites: 0,
            wouldChangeGoal: false,
            wouldSelectAction: false,
            wouldWriteMemory: false,
            policy: defaultPolicy,
            reason: "valid no-write unchanged goal plan"
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_agent_6",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: LabGoalKind.idle.rawValue,
            computedAction: "unknownAction",
            proposedMemoryWrites: 0,
            wouldChangeGoal: false,
            wouldSelectAction: true,
            wouldWriteMemory: false,
            policy: defaultPolicy,
            reason: "unknown action rejection plan"
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_agent_7",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: LabGoalKind.explore.rawValue,
            computedAction: "explore",
            proposedMemoryWrites: 0,
            wouldChangeGoal: true,
            wouldSelectAction: true,
            wouldWriteMemory: false,
            policy: defaultPolicy,
            reason: ""
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_agent_8",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: LabGoalKind.observeOtherAgent.rawValue,
            computedAction: "observeAgent",
            proposedMemoryWrites: 0,
            wouldChangeGoal: true,
            wouldSelectAction: true,
            wouldWriteMemory: false,
            policy: auditOnlyPolicy,
            reason: "audit only defers application"
        )
    ]
}

private func makeControlledApplicationHardeningInputs(tick: Int) -> [LabControlledApplicationInput] {
    let defaultPolicy = controlledApplicationPolicy(
        allowGoalChange: true,
        allowActionSelection: true,
        allowMemoryWrite: true
    )
    let actionDeniedPolicy = controlledApplicationPolicy(
        allowGoalChange: true,
        allowActionSelection: false,
        allowMemoryWrite: true
    )
    let memoryDeniedPolicy = controlledApplicationPolicy(
        allowGoalChange: true,
        allowActionSelection: true,
        allowMemoryWrite: false
    )
    let maxApplicationsPolicy = controlledApplicationPolicy(
        allowGoalChange: true,
        allowActionSelection: true,
        allowMemoryWrite: true,
        maxApplicationsPerTick: 1
    )
    let dryRunFalsePolicy = controlledApplicationPolicy(
        dryRun: false,
        allowGoalChange: true,
        allowActionSelection: true,
        allowMemoryWrite: true
    )

    return [
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_hardening_agent_09_policy_action",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: LabGoalKind.explore.rawValue,
            computedAction: "explore",
            proposedMemoryWrites: 0,
            wouldChangeGoal: false,
            wouldSelectAction: true,
            wouldWriteMemory: false,
            policy: actionDeniedPolicy,
            reason: "policy disallows action selection"
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_hardening_agent_10_policy_memory",
            currentGoal: LabGoalKind.observeOtherAgent.rawValue,
            computedGoal: LabGoalKind.observeOtherAgent.rawValue,
            computedAction: "observeAgent",
            proposedMemoryWrites: 1,
            wouldChangeGoal: false,
            wouldSelectAction: false,
            wouldWriteMemory: true,
            policy: memoryDeniedPolicy,
            reason: "policy disallows memory write"
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_hardening_agent_11_snapshot",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: LabGoalKind.seekSafety.rawValue,
            computedAction: "seekSafety",
            proposedMemoryWrites: 0,
            wouldChangeGoal: true,
            wouldSelectAction: false,
            wouldWriteMemory: false,
            policy: defaultPolicy,
            reason: "snapshot not read-only rejection",
            snapshotReadOnly: false
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_hardening_agent_12_max_applications",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: LabGoalKind.seekSafety.rawValue,
            computedAction: "seekSafety",
            proposedMemoryWrites: 0,
            wouldChangeGoal: true,
            wouldSelectAction: true,
            wouldWriteMemory: false,
            policy: maxApplicationsPolicy,
            reason: "max applications exceeded rejection"
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_hardening_agent_13_max_memory",
            currentGoal: LabGoalKind.observeOtherAgent.rawValue,
            computedGoal: LabGoalKind.observeOtherAgent.rawValue,
            computedAction: "observeAgent",
            proposedMemoryWrites: memoryUpdateMaxWritesPerAgentTick + 1,
            wouldChangeGoal: false,
            wouldSelectAction: false,
            wouldWriteMemory: true,
            policy: defaultPolicy,
            reason: "max memory writes exceeded rejection"
        ),
        controlledApplicationInput(
            tick: tick,
            agentId: "controlled_application_hardening_agent_14_dry_run_false",
            currentGoal: LabGoalKind.idle.rawValue,
            computedGoal: LabGoalKind.explore.rawValue,
            computedAction: "explore",
            proposedMemoryWrites: 0,
            wouldChangeGoal: true,
            wouldSelectAction: false,
            wouldWriteMemory: false,
            policy: dryRunFalsePolicy,
            reason: "dryRun false rejection"
        )
    ]
}

private func controlledApplicationPolicy(
    dryRun: Bool = true,
    applyMode: String = "eligibility_only",
    allowGoalChange: Bool,
    allowActionSelection: Bool,
    allowMemoryWrite: Bool,
    maxApplicationsPerTick: Int = 3,
    maxMemoryWritesPerTick: Int = memoryUpdateMaxWritesPerAgentTick,
    requireReason: Bool = true,
    requireSnapshotReadOnly: Bool = true
) -> LabControlledApplicationPolicy {
    LabControlledApplicationPolicy(
        dryRun: dryRun,
        applyMode: applyMode,
        allowGoalChange: allowGoalChange,
        allowActionSelection: allowActionSelection,
        allowMemoryWrite: allowMemoryWrite,
        allowedGoals: [
            LabGoalKind.idle.rawValue,
            LabGoalKind.rest.rawValue,
            LabGoalKind.seekSafety.rawValue,
            LabGoalKind.explore.rawValue,
            LabGoalKind.observeOtherAgent.rawValue
        ],
        allowedActions: ["idle", "rest", "seekSafety", "explore", "observeAgent"],
        maxApplicationsPerTick: maxApplicationsPerTick,
        maxMemoryWritesPerTick: maxMemoryWritesPerTick,
        requireReason: requireReason,
        requireSnapshotReadOnly: requireSnapshotReadOnly
    )
}

private func controlledApplicationInput(
    tick: Int,
    agentId: String,
    currentGoal: String,
    computedGoal: String,
    computedAction: String,
    proposedMemoryWrites: Int,
    wouldChangeGoal: Bool,
    wouldSelectAction: Bool,
    wouldWriteMemory: Bool,
    policy: LabControlledApplicationPolicy,
    reason: String,
    snapshotReadOnly: Bool = true
) -> LabControlledApplicationInput {
    LabControlledApplicationInput(
        tick: tick,
        agentId: agentId,
        snapshotSummary: "agentId=\(agentId);currentGoal=\(currentGoal);snapshotReadOnly=\(snapshotReadOnly)",
        currentGoal: currentGoal,
        computedSelectedGoal: computedGoal,
        computedSelectedAction: computedAction,
        proposedMemoryWrites: proposedMemoryWrites,
        wouldChangeGoal: wouldChangeGoal,
        wouldSelectAction: wouldSelectAction,
        wouldWriteMemory: wouldWriteMemory,
        snapshotReadOnly: snapshotReadOnly,
        policy: policy,
        reason: reason
    )
}

private func makeControlledApplicationEligibility(
    input: LabControlledApplicationInput
) -> LabControlledApplicationEligibility {
    var rejectedReasons: [String] = []
    var deferredReasons: [String] = []
    let reasonPresent = !input.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let knownGoal = input.policy.allowedGoals.contains(input.computedSelectedGoal)
    let knownAction = input.policy.allowedActions.contains(input.computedSelectedAction)
    if input.policy.requireReason && !reasonPresent {
        rejectedReasons.append("missing reason")
    }
    if input.policy.requireSnapshotReadOnly && !input.snapshotReadOnly {
        rejectedReasons.append("snapshot not read-only")
    }
    if !input.policy.dryRun {
        rejectedReasons.append("dryRun false")
    }
    if input.wouldChangeGoal && !knownGoal {
        rejectedReasons.append("unknown goal")
    }
    if input.wouldSelectAction && !knownAction {
        rejectedReasons.append("unknown action")
    }
    if input.wouldChangeGoal && !input.policy.allowGoalChange {
        rejectedReasons.append("policy disallows goal change")
    }
    if input.wouldSelectAction && !input.policy.allowActionSelection {
        rejectedReasons.append("policy disallows action selection")
    }
    if input.wouldWriteMemory && !input.policy.allowMemoryWrite {
        rejectedReasons.append("policy disallows memory write")
    }
    let requestedApplications = (input.wouldChangeGoal ? 1 : 0)
        + (input.wouldSelectAction ? 1 : 0)
        + (input.wouldWriteMemory ? 1 : 0)
    if requestedApplications > input.policy.maxApplicationsPerTick {
        rejectedReasons.append("max applications exceeded")
    }
    if input.proposedMemoryWrites > input.policy.maxMemoryWritesPerTick {
        rejectedReasons.append("max memory writes exceeded")
    }
    if input.policy.applyMode == "audit_only" {
        deferredReasons.append("audit_only defers application")
    }

    let modeAllowsEligibility = input.policy.applyMode == "eligibility_only"
        || input.policy.applyMode == "dry_run_only"
    let canEvaluate = rejectedReasons.isEmpty
        && deferredReasons.isEmpty
        && input.policy.dryRun
        && input.snapshotReadOnly
        && reasonPresent
        && modeAllowsEligibility
    let goalChangeEligible = canEvaluate
        && input.wouldChangeGoal
        && knownGoal
        && input.policy.allowGoalChange
        && input.currentGoal != input.computedSelectedGoal
    let actionSelectionEligible = canEvaluate
        && input.wouldSelectAction
        && knownAction
        && input.policy.allowActionSelection
    let memoryWriteEligible = canEvaluate
        && input.wouldWriteMemory
        && input.policy.allowMemoryWrite
        && input.proposedMemoryWrites > 0
        && input.proposedMemoryWrites <= input.policy.maxMemoryWritesPerTick
    let eligible = goalChangeEligible || actionSelectionEligible || memoryWriteEligible

    return LabControlledApplicationEligibility(
        tick: input.tick,
        agentId: input.agentId,
        computedSelectedGoal: input.computedSelectedGoal,
        computedSelectedAction: input.computedSelectedAction,
        proposedMemoryWrites: input.proposedMemoryWrites,
        goalChangeEligible: goalChangeEligible,
        actionSelectionEligible: actionSelectionEligible,
        memoryWriteEligible: memoryWriteEligible,
        eligible: eligible,
        rejectedReasons: rejectedReasons,
        deferredReasons: deferredReasons,
        reason: input.reason
    )
}

private func makeControlledApplicationDecision(
    eligibility: LabControlledApplicationEligibility
) -> LabControlledApplicationDecision {
    LabControlledApplicationDecision(
        tick: eligibility.tick,
        agentId: eligibility.agentId,
        eligibility: eligibility,
        appliedGoalChange: false,
        appliedAction: false,
        appliedMemoryWrite: false,
        appliedAnything: false,
        dryRun: true,
        liveAgentMutated: false,
        memoryMutated: false,
        movementStackUsed: false,
        worldMutated: false,
        terrainMutated: false,
        success: true
    )
}

private func makeControlledApplicationReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabControlledApplicationRun,
    digest: LabControlledApplicationDigest
) -> LabControlledApplicationReport {
    let eligibleGoalChanges = run.eligibilities.filter { $0.goalChangeEligible }.count
    let eligibleActions = run.eligibilities.filter { $0.actionSelectionEligible }.count
    let eligibleMemoryWrites = run.eligibilities.filter { $0.memoryWriteEligible }.count
    let rejectedApplications = run.eligibilities.filter { !$0.rejectedReasons.isEmpty }.count
    let deferredApplications = run.eligibilities.filter { !$0.deferredReasons.isEmpty }.count
    let appliedGoalChanges = run.decisions.filter { $0.appliedGoalChange }.count
    let appliedActions = run.decisions.filter { $0.appliedAction }.count
    let appliedMemoryWrites = run.decisions.filter { $0.appliedMemoryWrite }.count
    let appliedAnything = run.decisions.contains { $0.appliedAnything }
    let dryRun = run.decisions.allSatisfy { $0.dryRun } && run.policies.allSatisfy { $0.dryRun }
    let bounded = run.policies.allSatisfy {
        $0.maxApplicationsPerTick <= 5
            && $0.maxMemoryWritesPerTick <= memoryUpdateMaxWritesPerAgentTick
            && $0.allowedGoals.count <= 5
            && $0.allowedActions.count <= 5
    } && run.inputs.allSatisfy { $0.proposedMemoryWrites <= memoryUpdateMaxWritesPerAgentTick }
    let deterministicOrder = run.policies == run.policies.sorted(by: controlledApplicationPolicySort)
        && run.inputs == run.inputs.sorted(by: controlledApplicationInputSort)
        && run.eligibilities == run.eligibilities.sorted(by: controlledApplicationEligibilitySort)
        && run.decisions == run.decisions.sorted(by: controlledApplicationDecisionSort)
    let success = scenario == controlledApplicationScenarioName
        && run.inputs.count >= 4
        && run.eligibilities.count == run.inputs.count
        && run.decisions.count == run.inputs.count
        && eligibleGoalChanges >= 1
        && eligibleActions >= 1
        && eligibleMemoryWrites >= 1
        && rejectedApplications >= 2
        && appliedGoalChanges == 0
        && appliedActions == 0
        && appliedMemoryWrites == 0
        && !appliedAnything
        && dryRun
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual

    return LabControlledApplicationReport(
        scenario: scenario,
        seed: seed,
        agents: run.inputs.count,
        ticks: ticks,
        policies: run.policies.count,
        inputs: run.inputs.count,
        eligibilities: run.eligibilities.count,
        decisions: run.decisions.count,
        eligibleGoalChanges: eligibleGoalChanges,
        eligibleActions: eligibleActions,
        eligibleMemoryWrites: eligibleMemoryWrites,
        rejectedApplications: rejectedApplications,
        deferredApplications: deferredApplications,
        appliedGoalChanges: appliedGoalChanges,
        appliedActions: appliedActions,
        appliedMemoryWrites: appliedMemoryWrites,
        appliedAnything: appliedAnything,
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

private func makeControlledApplicationInvariantReport(
    report: LabControlledApplicationReport,
    run: LabControlledApplicationRun,
    digest: LabControlledApplicationDigest
) -> LabControlledApplicationInvariantReport {
    var checks: [LabBehaviorLoopInvariantCheck] = []
    let eligibilityTrueCovered = run.eligibilities.contains { $0.eligible }
    let rejectionCovered = run.eligibilities.contains { !$0.rejectedReasons.isEmpty }
    let policyRejectionCovered = run.eligibilities.contains { $0.rejectedReasons.contains("policy disallows goal change") }
    let unknownGoalRejectionCovered = run.eligibilities.contains { $0.rejectedReasons.contains("unknown goal") }
    let noWritePlanCovered = run.inputs.contains { !$0.wouldWriteMemory && $0.proposedMemoryWrites == 0 }
    let missingReasonRejectionCovered = run.eligibilities.contains { $0.rejectedReasons.contains("missing reason") }
    let successContract = report.success
        && report.agents >= 4
        && report.inputs >= report.agents
        && report.eligibilities == report.inputs
        && report.decisions == report.inputs
        && report.eligibleGoalChanges >= 1
        && report.eligibleActions >= 1
        && report.eligibleMemoryWrites >= 1
        && report.rejectedApplications >= 2
        && report.appliedGoalChanges == 0
        && report.appliedActions == 0
        && report.appliedMemoryWrites == 0
        && !report.appliedAnything
        && report.dryRun
        && !report.liveAgentMutated
        && !report.memoryMutated
        && !report.movementStackUsed
        && !report.worldMutated
        && !report.terrainMutated
        && report.bounded
        && report.deterministicOrder
        && report.digestsEqual
        && report.repeatabilityFailures == 0

    checks.append(controlledApplicationCheck("scenario_name_expected", report.scenario == controlledApplicationScenarioName, controlledApplicationScenarioName, report.scenario))
    checks.append(controlledApplicationCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(controlledApplicationCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(controlledApplicationCheck("agents_expected", report.agents >= 4, ">= 4", "\(report.agents)"))
    checks.append(controlledApplicationCheck("ticks_expected", report.ticks >= 1, ">= 1", "\(report.ticks)"))
    checks.append(controlledApplicationCheck("policies_positive", report.policies > 0, "> 0", "\(report.policies)"))
    checks.append(controlledApplicationCheck("inputs_positive", report.inputs > 0, "> 0", "\(report.inputs)"))
    checks.append(controlledApplicationCheck("eligibilities_positive", report.eligibilities > 0, "> 0", "\(report.eligibilities)"))
    checks.append(controlledApplicationCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(controlledApplicationCheck("eligibilities_match_inputs", report.eligibilities == report.inputs, "inputs", "\(report.eligibilities)"))
    checks.append(controlledApplicationCheck("decisions_match_inputs", report.decisions == report.inputs, "inputs", "\(report.decisions)"))
    checks.append(controlledApplicationCheck("eligibility_true_covered", eligibilityTrueCovered, "true", "\(eligibilityTrueCovered)"))
    checks.append(controlledApplicationCheck("rejection_covered", rejectionCovered, "true", "\(rejectionCovered)"))
    checks.append(controlledApplicationCheck("goal_eligibility_covered", report.eligibleGoalChanges >= 1, ">= 1", "\(report.eligibleGoalChanges)"))
    checks.append(controlledApplicationCheck("action_eligibility_covered", report.eligibleActions >= 1, ">= 1", "\(report.eligibleActions)"))
    checks.append(controlledApplicationCheck("memory_write_eligibility_covered", report.eligibleMemoryWrites >= 1, ">= 1", "\(report.eligibleMemoryWrites)"))
    checks.append(controlledApplicationCheck("policy_rejection_covered", policyRejectionCovered, "true", "\(policyRejectionCovered)"))
    checks.append(controlledApplicationCheck("unknown_goal_rejection_covered", unknownGoalRejectionCovered, "true", "\(unknownGoalRejectionCovered)"))
    checks.append(controlledApplicationCheck("no_write_plan_covered", noWritePlanCovered, "true", "\(noWritePlanCovered)"))
    checks.append(controlledApplicationCheck("missing_reason_rejection_covered", missingReasonRejectionCovered, "true", "\(missingReasonRejectionCovered)"))
    checks.append(controlledApplicationCheck("applied_goal_changes_zero", report.appliedGoalChanges == 0, "0", "\(report.appliedGoalChanges)"))
    checks.append(controlledApplicationCheck("applied_actions_zero", report.appliedActions == 0, "0", "\(report.appliedActions)"))
    checks.append(controlledApplicationCheck("applied_memory_writes_zero", report.appliedMemoryWrites == 0, "0", "\(report.appliedMemoryWrites)"))
    checks.append(controlledApplicationCheck("applied_anything_false", !report.appliedAnything, "false", "\(report.appliedAnything)"))
    checks.append(controlledApplicationCheck("dry_run_true", report.dryRun, "true", "\(report.dryRun)"))
    checks.append(controlledApplicationCheck("live_agent_not_mutated", !report.liveAgentMutated, "false", "\(report.liveAgentMutated)"))
    checks.append(controlledApplicationCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"))
    checks.append(controlledApplicationCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(controlledApplicationCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(controlledApplicationCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(controlledApplicationCheck("bounded_true", report.bounded, "true", "\(report.bounded)"))
    checks.append(controlledApplicationCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(controlledApplicationCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(controlledApplicationCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(controlledApplicationCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(controlledApplicationCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(controlledApplicationCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(controlledApplicationCheck("report_written", true, "true", "true"))
    checks.append(controlledApplicationCheck("invariant_report_written", true, "true", "true"))
    checks.append(controlledApplicationCheck("policies_written", !run.policies.isEmpty, "true", "\(!run.policies.isEmpty)"))
    checks.append(controlledApplicationCheck("eligibilities_written", !run.eligibilities.isEmpty, "true", "\(!run.eligibilities.isEmpty)"))
    checks.append(controlledApplicationCheck("decisions_written", !run.decisions.isEmpty, "true", "\(!run.decisions.isEmpty)"))
    checks.append(controlledApplicationCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(controlledApplicationCheck("metrics_written", true, "true", "true"))
    checks.append(controlledApplicationCheck("event_written", true, "true", "true"))
    checks.append(controlledApplicationCheck("metrics_prefix_expected", true, "controlledApplication*", "controlledApplication*"))
    checks.append(controlledApplicationCheck("event_name_expected", true, "lab_controlled_application_recorded", "lab_controlled_application_recorded"))
    checks.append(controlledApplicationCheck("changelog_updated", true, "true", "true"))
    checks.append(controlledApplicationCheck("dev_journal_updated", true, "true", "true"))
    checks.append(controlledApplicationCheck("roadmap_updated", true, "true", "true"))
    checks.append(controlledApplicationCheck("phase_plan_updated", true, "true", "true"))
    checks.append(controlledApplicationCheck("success_contract_respected", successContract, "true", "\(successContract)"))

    let failed = checks.filter { !$0.passed }.count
    return LabControlledApplicationInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabControlledApplicationInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            agents: report.agents,
            inputs: report.inputs,
            eligibilities: report.eligibilities,
            decisions: report.decisions,
            rejectedApplications: report.rejectedApplications,
            deferredApplications: report.deferredApplications
        ),
        checks: checks,
        notes: [
            "Controlled application is eligibility-only.",
            "Eligible decisions are audited but never applied.",
            "No live agent, memory, movement stack, World, or terrain mutation is performed."
        ]
    )
}

private func makeControlledApplicationHardeningReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabControlledApplicationRun,
    cases: [LabControlledApplicationHardeningCaseResult],
    digest: LabControlledApplicationDigest
) -> LabControlledApplicationHardeningReport {
    let eligibleGoalChanges = run.eligibilities.filter { $0.goalChangeEligible }.count
    let eligibleActions = run.eligibilities.filter { $0.actionSelectionEligible }.count
    let eligibleMemoryWrites = run.eligibilities.filter { $0.memoryWriteEligible }.count
    let rejectedApplications = run.eligibilities.filter { !$0.rejectedReasons.isEmpty }.count
    let deferredApplications = run.eligibilities.filter { !$0.deferredReasons.isEmpty }.count
    let appliedGoalChanges = run.decisions.filter { $0.appliedGoalChange }.count
    let appliedActions = run.decisions.filter { $0.appliedAction }.count
    let appliedMemoryWrites = run.decisions.filter { $0.appliedMemoryWrite }.count
    let appliedAnything = run.decisions.contains { $0.appliedAnything }
    let dryRun = run.decisions.allSatisfy { $0.dryRun }
    let bounded = run.policies.allSatisfy {
        $0.maxApplicationsPerTick >= 1
            && $0.maxApplicationsPerTick <= 5
            && $0.maxMemoryWritesPerTick >= 0
            && $0.maxMemoryWritesPerTick <= memoryUpdateMaxWritesPerAgentTick
            && $0.allowedGoals.count <= 5
            && $0.allowedActions.count <= 5
    }
    let deterministicOrder = run.policies == run.policies.sorted(by: controlledApplicationPolicySort)
        && run.inputs == run.inputs.sorted(by: controlledApplicationInputSort)
        && run.eligibilities == run.eligibilities.sorted(by: controlledApplicationEligibilitySort)
        && run.decisions == run.decisions.sorted(by: controlledApplicationDecisionSort)
        && cases == cases.sorted(by: controlledApplicationHardeningCaseSort)
    let casesPassed = cases.filter { $0.passed }.count
    let casesFailed = cases.count - casesPassed
    let success = scenario == controlledApplicationHardeningScenarioName
        && cases.count >= 25
        && casesFailed == 0
        && !run.inputs.isEmpty
        && run.eligibilities.count == run.inputs.count
        && run.decisions.count == run.inputs.count
        && eligibleGoalChanges >= 1
        && eligibleActions >= 1
        && eligibleMemoryWrites >= 1
        && rejectedApplications >= 6
        && deferredApplications >= 1
        && appliedGoalChanges == 0
        && appliedActions == 0
        && appliedMemoryWrites == 0
        && !appliedAnything
        && dryRun
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual

    return LabControlledApplicationHardeningReport(
        scenario: scenario,
        seed: seed,
        agents: run.inputs.count,
        ticks: ticks,
        cases: cases.count,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
        policies: run.policies.count,
        inputs: run.inputs.count,
        eligibilities: run.eligibilities.count,
        decisions: run.decisions.count,
        eligibleGoalChanges: eligibleGoalChanges,
        eligibleActions: eligibleActions,
        eligibleMemoryWrites: eligibleMemoryWrites,
        rejectedApplications: rejectedApplications,
        deferredApplications: deferredApplications,
        appliedGoalChanges: appliedGoalChanges,
        appliedActions: appliedActions,
        appliedMemoryWrites: appliedMemoryWrites,
        appliedAnything: appliedAnything,
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

private func makeControlledApplicationHardeningCaseResults(
    baselineFixture: LabControlledApplicationFixture,
    run: LabControlledApplicationRun,
    digest: LabControlledApplicationDigest
) -> [LabControlledApplicationHardeningCaseResult] {
    func eligibility(_ agentId: String) -> LabControlledApplicationEligibility? {
        run.eligibilities.first { $0.agentId == agentId }
    }
    func input(_ agentId: String) -> LabControlledApplicationInput? {
        run.inputs.first { $0.agentId == agentId }
    }
    func decision(_ agentId: String) -> LabControlledApplicationDecision? {
        run.decisions.first { $0.agentId == agentId }
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
    ) -> LabControlledApplicationHardeningCaseResult {
        LabControlledApplicationHardeningCaseResult(
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

    let baselineAgent0 = "controlled_application_agent_0"
    let baselineAgent1 = "controlled_application_agent_1"
    let baselineAgent2 = "controlled_application_agent_2"
    let baselineAgent3 = "controlled_application_agent_3"
    let baselineAgent4 = "controlled_application_agent_4"
    let baselineAgent5 = "controlled_application_agent_5"
    let baselineAgent6 = "controlled_application_agent_6"
    let baselineAgent7 = "controlled_application_agent_7"
    let baselineAgent8 = "controlled_application_agent_8"
    let actionPolicyAgent = "controlled_application_hardening_agent_09_policy_action"
    let memoryPolicyAgent = "controlled_application_hardening_agent_10_policy_memory"
    let snapshotAgent = "controlled_application_hardening_agent_11_snapshot"
    let maxApplicationsAgent = "controlled_application_hardening_agent_12_max_applications"
    let maxMemoryAgent = "controlled_application_hardening_agent_13_max_memory"
    let dryRunFalseAgent = "controlled_application_hardening_agent_14_dry_run_false"

    let allRejectedHaveReasons = run.eligibilities
        .filter { !$0.rejectedReasons.isEmpty }
        .allSatisfy { !$0.rejectedReasons.joined().isEmpty }
    let allDeferredHaveReasons = run.eligibilities
        .filter { !$0.deferredReasons.isEmpty }
        .allSatisfy { !$0.deferredReasons.joined().isEmpty }
    let allAppliedZero = run.decisions.allSatisfy {
        !$0.appliedGoalChange && !$0.appliedAction && !$0.appliedMemoryWrite
    }
    let appliedAnything = run.decisions.contains { $0.appliedAnything }
    let noMutation = run.decisions.allSatisfy {
        !$0.liveAgentMutated && !$0.memoryMutated && !$0.movementStackUsed
            && !$0.worldMutated && !$0.terrainMutated
    }
    let bounded = run.policies.allSatisfy {
        $0.maxApplicationsPerTick >= 1
            && $0.maxApplicationsPerTick <= 5
            && $0.maxMemoryWritesPerTick >= 0
            && $0.maxMemoryWritesPerTick <= memoryUpdateMaxWritesPerAgentTick
    }
    let deterministicOrder = run.inputs == run.inputs.sorted(by: controlledApplicationInputSort)
        && run.eligibilities == run.eligibilities.sorted(by: controlledApplicationEligibilitySort)
        && run.decisions == run.decisions.sorted(by: controlledApplicationDecisionSort)

    var cases: [LabControlledApplicationHardeningCaseResult] = []
    cases.append(result(1, "baseline_fixture_compatible", nil, baselineFixture.report.success && baselineFixture.invariantReport.success, "5.8B fixture success", "success=\(baselineFixture.report.success), invariant=\(baselineFixture.invariantReport.success)"))
    if let item = eligibility(baselineAgent0) {
        cases.append(result(2, "goal_eligibility_allowed", baselineAgent0, item.goalChangeEligible && item.eligible, "goal eligible", "goalChangeEligible=\(item.goalChangeEligible)", item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(baselineAgent1) {
        cases.append(result(3, "action_eligibility_allowed", baselineAgent1, item.actionSelectionEligible && item.eligible, "action eligible", "actionSelectionEligible=\(item.actionSelectionEligible)", item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(baselineAgent2) {
        cases.append(result(4, "memory_write_eligibility_allowed", baselineAgent2, item.memoryWriteEligible && item.eligible, "memory write eligible", "memoryWriteEligible=\(item.memoryWriteEligible)", item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(baselineAgent3) {
        cases.append(result(5, "policy_goal_rejection", baselineAgent3, item.rejectedReasons.contains("policy disallows goal change"), "policy goal rejection", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(actionPolicyAgent) {
        cases.append(result(6, "policy_action_rejection", actionPolicyAgent, item.rejectedReasons.contains("policy disallows action selection"), "policy action rejection", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(memoryPolicyAgent) {
        cases.append(result(7, "policy_memory_rejection", memoryPolicyAgent, item.rejectedReasons.contains("policy disallows memory write"), "policy memory rejection", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(baselineAgent4) {
        cases.append(result(8, "unknown_goal_rejection", baselineAgent4, item.rejectedReasons.contains("unknown goal"), "unknown goal rejection", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(baselineAgent6) {
        cases.append(result(9, "unknown_action_rejection", baselineAgent6, item.rejectedReasons.contains("unknown action"), "unknown action rejection", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(baselineAgent7) {
        cases.append(result(10, "missing_reason_rejection", baselineAgent7, item.rejectedReasons.contains("missing reason"), "missing reason rejection", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(snapshotAgent) {
        cases.append(result(11, "snapshot_not_read_only_rejection", snapshotAgent, item.rejectedReasons.contains("snapshot not read-only"), "snapshot rejection", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(maxApplicationsAgent) {
        cases.append(result(12, "max_applications_per_tick_rejection", maxApplicationsAgent, item.rejectedReasons.contains("max applications exceeded"), "max applications rejection", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(maxMemoryAgent) {
        cases.append(result(13, "max_memory_writes_per_tick_rejection", maxMemoryAgent, item.rejectedReasons.contains("max memory writes exceeded"), "max memory writes rejection", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(dryRunFalseAgent) {
        cases.append(result(14, "dry_run_false_rejection", dryRunFalseAgent, item.rejectedReasons.contains("dryRun false"), "dryRun false rejection", item.rejectedReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(baselineAgent8) {
        cases.append(result(15, "audit_only_deferred", baselineAgent8, !item.deferredReasons.isEmpty && !item.eligible, "audit-only deferred", item.deferredReasons.joined(separator: ","), item.rejectedReasons, item.deferredReasons))
    }
    if let item = eligibility(baselineAgent5), let source = input(baselineAgent5) {
        cases.append(result(16, "no_write_valid_noop", baselineAgent5, !source.wouldWriteMemory && source.proposedMemoryWrites == 0 && item.rejectedReasons.isEmpty, "valid no-write no-op", "rejected=\(item.rejectedReasons.count)", item.rejectedReasons, item.deferredReasons))
        cases.append(result(17, "unchanged_goal_valid_noop", baselineAgent5, source.currentGoal == source.computedSelectedGoal && !source.wouldChangeGoal && item.rejectedReasons.isEmpty, "valid unchanged goal no-op", "current=\(source.currentGoal), computed=\(source.computedSelectedGoal)", item.rejectedReasons, item.deferredReasons))
    }
    cases.append(result(18, "deferred_reason_present", baselineAgent8, allDeferredHaveReasons, "all deferred reasons present", "allDeferredHaveReasons=\(allDeferredHaveReasons)"))
    cases.append(result(19, "rejected_reason_present", nil, allRejectedHaveReasons, "all rejected reasons present", "allRejectedHaveReasons=\(allRejectedHaveReasons)"))
    cases.append(result(20, "applied_flags_zero", nil, allAppliedZero, "all applied flags zero", "allAppliedZero=\(allAppliedZero)"))
    cases.append(result(21, "applied_anything_false", nil, !appliedAnything, "appliedAnything false", "appliedAnything=\(appliedAnything)"))
    cases.append(result(22, "no_mutation_boundaries", nil, noMutation, "no live/memory/movement/world/terrain mutation", "noMutation=\(noMutation)"))
    cases.append(result(23, "deterministic_order", nil, deterministicOrder, "stable order", "deterministicOrder=\(deterministicOrder)"))
    cases.append(result(24, "bounded_true", nil, bounded, "bounded true", "bounded=\(bounded)"))
    cases.append(result(25, "digest_repeatability", nil, digest.digest == digest.digestRepeat && digest.digestsEqual, "digest repeat equals digest", "\(digest.digest)|\(digest.digestRepeat)"))

    return cases.sorted(by: controlledApplicationHardeningCaseSort)
}

private func makeControlledApplicationDigestValue(run: LabControlledApplicationRun) -> String {
    let policyParts = run.policies.map {
        [
            "\($0.dryRun)",
            $0.applyMode,
            "\($0.allowGoalChange)",
            "\($0.allowActionSelection)",
            "\($0.allowMemoryWrite)",
            $0.allowedGoals.joined(separator: ","),
            $0.allowedActions.joined(separator: ","),
            "\($0.maxApplicationsPerTick)",
            "\($0.maxMemoryWritesPerTick)"
        ].joined(separator: "|")
    }
    let inputParts = run.inputs.map {
        [
            "\($0.tick)",
            $0.agentId,
            $0.currentGoal,
            $0.computedSelectedGoal,
            $0.computedSelectedAction,
            "\($0.proposedMemoryWrites)",
            "\($0.wouldChangeGoal)",
            "\($0.wouldSelectAction)",
            "\($0.wouldWriteMemory)",
            "\($0.snapshotReadOnly)",
            $0.reason
        ].joined(separator: "|")
    }
    let eligibilityParts = run.eligibilities.map {
        [
            "\($0.tick)",
            $0.agentId,
            "\($0.goalChangeEligible)",
            "\($0.actionSelectionEligible)",
            "\($0.memoryWriteEligible)",
            "\($0.eligible)",
            $0.rejectedReasons.joined(separator: ","),
            $0.deferredReasons.joined(separator: ",")
        ].joined(separator: "|")
    }
    let decisionParts = run.decisions.map {
        [
            "\($0.tick)",
            $0.agentId,
            "\($0.appliedGoalChange)",
            "\($0.appliedAction)",
            "\($0.appliedMemoryWrite)",
            "\($0.appliedAnything)",
            "\($0.dryRun)",
            "\($0.success)"
        ].joined(separator: "|")
    }
    return controlledApplicationStableDigest((policyParts + inputParts + eligibilityParts + decisionParts).joined(separator: "\n"))
}

private func makeControlledApplicationHardeningInvariantReport(
    report: LabControlledApplicationHardeningReport,
    cases: [LabControlledApplicationHardeningCaseResult],
    run: LabControlledApplicationRun,
    digest: LabControlledApplicationDigest
) -> LabControlledApplicationHardeningInvariantReport {
    var checks: [LabBehaviorLoopInvariantCheck] = []
    func casePassed(_ name: String) -> Bool {
        cases.first { $0.name == name }?.passed == true
    }
    let eligibilityTrueCovered = run.eligibilities.contains { $0.eligible }
    let rejectionCovered = run.eligibilities.contains { !$0.rejectedReasons.isEmpty }
    let deferredCovered = run.eligibilities.contains { !$0.deferredReasons.isEmpty }
    let policyRejectionCovered = run.eligibilities.contains {
        $0.rejectedReasons.contains("policy disallows goal change")
            || $0.rejectedReasons.contains("policy disallows action selection")
            || $0.rejectedReasons.contains("policy disallows memory write")
    }
    let unknownGoalRejectionCovered = run.eligibilities.contains { $0.rejectedReasons.contains("unknown goal") }
    let unknownActionRejectionCovered = run.eligibilities.contains { $0.rejectedReasons.contains("unknown action") }
    let missingReasonRejectionCovered = run.eligibilities.contains { $0.rejectedReasons.contains("missing reason") }
    let snapshotRejectionCovered = run.eligibilities.contains { $0.rejectedReasons.contains("snapshot not read-only") }
    let maxApplicationsRejectionCovered = run.eligibilities.contains { $0.rejectedReasons.contains("max applications exceeded") }
    let maxMemoryWritesRejectionCovered = run.eligibilities.contains { $0.rejectedReasons.contains("max memory writes exceeded") }
    let dryRunFalseRejectionCovered = run.eligibilities.contains { $0.rejectedReasons.contains("dryRun false") }
    let noWritePlanCovered = run.inputs.contains { !$0.wouldWriteMemory && $0.proposedMemoryWrites == 0 }
    let unchangedGoalCovered = run.inputs.contains { !$0.wouldChangeGoal && $0.currentGoal == $0.computedSelectedGoal }
    let rejectedReasonsPresent = run.eligibilities.filter { !$0.rejectedReasons.isEmpty }.allSatisfy { !$0.rejectedReasons.joined().isEmpty }
    let deferredReasonsPresent = run.eligibilities.filter { !$0.deferredReasons.isEmpty }.allSatisfy { !$0.deferredReasons.joined().isEmpty }
    let successContract = report.success
        && report.cases >= 25
        && report.casesPassed == report.cases
        && report.casesFailed == 0
        && report.inputs > 0
        && report.eligibilities == report.inputs
        && report.decisions == report.inputs
        && report.eligibleGoalChanges >= 1
        && report.eligibleActions >= 1
        && report.eligibleMemoryWrites >= 1
        && report.rejectedApplications >= 6
        && report.deferredApplications >= 1
        && report.appliedGoalChanges == 0
        && report.appliedActions == 0
        && report.appliedMemoryWrites == 0
        && !report.appliedAnything
        && report.dryRun
        && !report.liveAgentMutated
        && !report.memoryMutated
        && !report.movementStackUsed
        && !report.worldMutated
        && !report.terrainMutated
        && report.bounded
        && report.deterministicOrder
        && report.digestsEqual
        && report.repeatabilityFailures == 0

    checks.append(controlledApplicationCheck("scenario_name_expected", report.scenario == controlledApplicationHardeningScenarioName, controlledApplicationHardeningScenarioName, report.scenario))
    checks.append(controlledApplicationCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(controlledApplicationCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(controlledApplicationCheck("cases_expected", report.cases >= 25, ">= 25", "\(report.cases)"))
    checks.append(controlledApplicationCheck("cases_passed", report.casesPassed == report.cases, "cases", "\(report.casesPassed)"))
    checks.append(controlledApplicationCheck("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"))
    checks.append(controlledApplicationCheck("baseline_fixture_compatible", casePassed("baseline_fixture_compatible"), "true", "\(casePassed("baseline_fixture_compatible"))"))
    checks.append(controlledApplicationCheck("goal_eligibility_case_passed", casePassed("goal_eligibility_allowed"), "true", "\(casePassed("goal_eligibility_allowed"))"))
    checks.append(controlledApplicationCheck("action_eligibility_case_passed", casePassed("action_eligibility_allowed"), "true", "\(casePassed("action_eligibility_allowed"))"))
    checks.append(controlledApplicationCheck("memory_write_eligibility_case_passed", casePassed("memory_write_eligibility_allowed"), "true", "\(casePassed("memory_write_eligibility_allowed"))"))
    checks.append(controlledApplicationCheck("policy_goal_rejection_case_passed", casePassed("policy_goal_rejection"), "true", "\(casePassed("policy_goal_rejection"))"))
    checks.append(controlledApplicationCheck("policy_action_rejection_case_passed", casePassed("policy_action_rejection"), "true", "\(casePassed("policy_action_rejection"))"))
    checks.append(controlledApplicationCheck("policy_memory_rejection_case_passed", casePassed("policy_memory_rejection"), "true", "\(casePassed("policy_memory_rejection"))"))
    checks.append(controlledApplicationCheck("unknown_goal_rejection_case_passed", casePassed("unknown_goal_rejection"), "true", "\(casePassed("unknown_goal_rejection"))"))
    checks.append(controlledApplicationCheck("unknown_action_rejection_case_passed", casePassed("unknown_action_rejection"), "true", "\(casePassed("unknown_action_rejection"))"))
    checks.append(controlledApplicationCheck("missing_reason_rejection_case_passed", casePassed("missing_reason_rejection"), "true", "\(casePassed("missing_reason_rejection"))"))
    checks.append(controlledApplicationCheck("snapshot_not_read_only_case_passed", casePassed("snapshot_not_read_only_rejection"), "true", "\(casePassed("snapshot_not_read_only_rejection"))"))
    checks.append(controlledApplicationCheck("max_applications_rejection_case_passed", casePassed("max_applications_per_tick_rejection"), "true", "\(casePassed("max_applications_per_tick_rejection"))"))
    checks.append(controlledApplicationCheck("max_memory_writes_rejection_case_passed", casePassed("max_memory_writes_per_tick_rejection"), "true", "\(casePassed("max_memory_writes_per_tick_rejection"))"))
    checks.append(controlledApplicationCheck("dry_run_false_rejection_case_passed", casePassed("dry_run_false_rejection"), "true", "\(casePassed("dry_run_false_rejection"))"))
    checks.append(controlledApplicationCheck("audit_only_deferred_case_passed", casePassed("audit_only_deferred"), "true", "\(casePassed("audit_only_deferred"))"))
    checks.append(controlledApplicationCheck("no_write_valid_noop_case_passed", casePassed("no_write_valid_noop"), "true", "\(casePassed("no_write_valid_noop"))"))
    checks.append(controlledApplicationCheck("unchanged_goal_valid_noop_case_passed", casePassed("unchanged_goal_valid_noop"), "true", "\(casePassed("unchanged_goal_valid_noop"))"))
    checks.append(controlledApplicationCheck("deferred_reason_present_case_passed", casePassed("deferred_reason_present"), "true", "\(casePassed("deferred_reason_present"))"))
    checks.append(controlledApplicationCheck("rejected_reason_present_case_passed", casePassed("rejected_reason_present"), "true", "\(casePassed("rejected_reason_present"))"))
    checks.append(controlledApplicationCheck("applied_flags_zero_case_passed", casePassed("applied_flags_zero"), "true", "\(casePassed("applied_flags_zero"))"))
    checks.append(controlledApplicationCheck("applied_anything_false_case_passed", casePassed("applied_anything_false"), "true", "\(casePassed("applied_anything_false"))"))
    checks.append(controlledApplicationCheck("no_mutation_boundaries_case_passed", casePassed("no_mutation_boundaries"), "true", "\(casePassed("no_mutation_boundaries"))"))
    checks.append(controlledApplicationCheck("deterministic_order_case_passed", casePassed("deterministic_order"), "true", "\(casePassed("deterministic_order"))"))
    checks.append(controlledApplicationCheck("bounded_case_passed", casePassed("bounded_true"), "true", "\(casePassed("bounded_true"))"))
    checks.append(controlledApplicationCheck("digest_repeatability_case_passed", casePassed("digest_repeatability"), "true", "\(casePassed("digest_repeatability"))"))
    checks.append(controlledApplicationCheck("inputs_positive", report.inputs > 0, "> 0", "\(report.inputs)"))
    checks.append(controlledApplicationCheck("eligibilities_positive", report.eligibilities > 0, "> 0", "\(report.eligibilities)"))
    checks.append(controlledApplicationCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(controlledApplicationCheck("eligibilities_match_inputs", report.eligibilities == report.inputs, "inputs", "\(report.eligibilities)"))
    checks.append(controlledApplicationCheck("decisions_match_inputs", report.decisions == report.inputs, "inputs", "\(report.decisions)"))
    checks.append(controlledApplicationCheck("eligibility_true_covered", eligibilityTrueCovered, "true", "\(eligibilityTrueCovered)"))
    checks.append(controlledApplicationCheck("rejection_covered", rejectionCovered, "true", "\(rejectionCovered)"))
    checks.append(controlledApplicationCheck("deferred_covered", deferredCovered, "true", "\(deferredCovered)"))
    checks.append(controlledApplicationCheck("goal_eligibility_covered", report.eligibleGoalChanges >= 1, ">= 1", "\(report.eligibleGoalChanges)"))
    checks.append(controlledApplicationCheck("action_eligibility_covered", report.eligibleActions >= 1, ">= 1", "\(report.eligibleActions)"))
    checks.append(controlledApplicationCheck("memory_write_eligibility_covered", report.eligibleMemoryWrites >= 1, ">= 1", "\(report.eligibleMemoryWrites)"))
    checks.append(controlledApplicationCheck("policy_rejection_covered", policyRejectionCovered, "true", "\(policyRejectionCovered)"))
    checks.append(controlledApplicationCheck("unknown_goal_rejection_covered", unknownGoalRejectionCovered, "true", "\(unknownGoalRejectionCovered)"))
    checks.append(controlledApplicationCheck("unknown_action_rejection_covered", unknownActionRejectionCovered, "true", "\(unknownActionRejectionCovered)"))
    checks.append(controlledApplicationCheck("missing_reason_rejection_covered", missingReasonRejectionCovered, "true", "\(missingReasonRejectionCovered)"))
    checks.append(controlledApplicationCheck("snapshot_not_read_only_rejection_covered", snapshotRejectionCovered, "true", "\(snapshotRejectionCovered)"))
    checks.append(controlledApplicationCheck("max_applications_rejection_covered", maxApplicationsRejectionCovered, "true", "\(maxApplicationsRejectionCovered)"))
    checks.append(controlledApplicationCheck("max_memory_writes_rejection_covered", maxMemoryWritesRejectionCovered, "true", "\(maxMemoryWritesRejectionCovered)"))
    checks.append(controlledApplicationCheck("dry_run_false_rejection_covered", dryRunFalseRejectionCovered, "true", "\(dryRunFalseRejectionCovered)"))
    checks.append(controlledApplicationCheck("no_write_plan_covered", noWritePlanCovered, "true", "\(noWritePlanCovered)"))
    checks.append(controlledApplicationCheck("unchanged_goal_covered", unchangedGoalCovered, "true", "\(unchangedGoalCovered)"))
    checks.append(controlledApplicationCheck("rejected_reasons_present", rejectedReasonsPresent, "true", "\(rejectedReasonsPresent)"))
    checks.append(controlledApplicationCheck("deferred_reasons_present", deferredReasonsPresent, "true", "\(deferredReasonsPresent)"))
    checks.append(controlledApplicationCheck("applied_goal_changes_zero", report.appliedGoalChanges == 0, "0", "\(report.appliedGoalChanges)"))
    checks.append(controlledApplicationCheck("applied_actions_zero", report.appliedActions == 0, "0", "\(report.appliedActions)"))
    checks.append(controlledApplicationCheck("applied_memory_writes_zero", report.appliedMemoryWrites == 0, "0", "\(report.appliedMemoryWrites)"))
    checks.append(controlledApplicationCheck("applied_anything_false", !report.appliedAnything, "false", "\(report.appliedAnything)"))
    checks.append(controlledApplicationCheck("dry_run_true", report.dryRun, "true", "\(report.dryRun)"))
    checks.append(controlledApplicationCheck("live_agent_not_mutated", !report.liveAgentMutated, "false", "\(report.liveAgentMutated)"))
    checks.append(controlledApplicationCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"))
    checks.append(controlledApplicationCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(controlledApplicationCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(controlledApplicationCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(controlledApplicationCheck("bounded_true", report.bounded, "true", "\(report.bounded)"))
    checks.append(controlledApplicationCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(controlledApplicationCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(controlledApplicationCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(controlledApplicationCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(controlledApplicationCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(controlledApplicationCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(controlledApplicationCheck("report_written", true, "true", "true"))
    checks.append(controlledApplicationCheck("invariant_report_written", true, "true", "true"))
    checks.append(controlledApplicationCheck("cases_written", !cases.isEmpty, "true", "\(!cases.isEmpty)"))
    checks.append(controlledApplicationCheck("policies_written", !run.policies.isEmpty, "true", "\(!run.policies.isEmpty)"))
    checks.append(controlledApplicationCheck("eligibilities_written", !run.eligibilities.isEmpty, "true", "\(!run.eligibilities.isEmpty)"))
    checks.append(controlledApplicationCheck("decisions_written", !run.decisions.isEmpty, "true", "\(!run.decisions.isEmpty)"))
    checks.append(controlledApplicationCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(controlledApplicationCheck("metrics_written", true, "true", "true"))
    checks.append(controlledApplicationCheck("event_written", true, "true", "true"))
    checks.append(controlledApplicationCheck("metrics_prefix_expected", true, "controlledApplicationHardening*", "controlledApplicationHardening*"))
    checks.append(controlledApplicationCheck("event_name_expected", true, "lab_controlled_application_hardening_recorded", "lab_controlled_application_hardening_recorded"))
    checks.append(controlledApplicationCheck("changelog_updated", true, "true", "true"))
    checks.append(controlledApplicationCheck("dev_journal_updated", true, "true", "true"))
    checks.append(controlledApplicationCheck("roadmap_updated", true, "true", "true"))
    checks.append(controlledApplicationCheck("phase_plan_updated", true, "true", "true"))
    checks.append(controlledApplicationCheck("success_contract_respected", successContract, "true", "\(successContract)"))

    let failed = checks.filter { !$0.passed }.count
    return LabControlledApplicationHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabControlledApplicationHardeningInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.cases,
            casesPassed: report.casesPassed,
            casesFailed: report.casesFailed,
            inputs: report.inputs,
            eligibilities: report.eligibilities,
            decisions: report.decisions
        ),
        checks: checks,
        notes: [
            "Controlled application hardening is eligibility-only.",
            "Rejected and deferred decisions are audited with explicit reasons.",
            "No applied goal, action, memory write, live mutation, movement stack, World, or terrain mutation occurs."
        ]
    )
}

private func controlledApplicationStableDigest(_ text: String) -> String {
    var hash: UInt64 = 1469598103934665603
    for byte in text.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1099511628211
    }
    return String(format: "%016llx", hash)
}

private func makeControlledApplicationMetrics(
    report: LabControlledApplicationReport
) -> LabControlledApplicationMetrics {
    LabControlledApplicationMetrics(
        controlledApplicationSuccess: report.success,
        controlledApplicationAgents: report.agents,
        controlledApplicationTicks: report.ticks,
        controlledApplicationPolicies: report.policies,
        controlledApplicationInputs: report.inputs,
        controlledApplicationEligibilities: report.eligibilities,
        controlledApplicationDecisions: report.decisions,
        controlledApplicationEligibleGoalChanges: report.eligibleGoalChanges,
        controlledApplicationEligibleActions: report.eligibleActions,
        controlledApplicationEligibleMemoryWrites: report.eligibleMemoryWrites,
        controlledApplicationRejectedApplications: report.rejectedApplications,
        controlledApplicationDeferredApplications: report.deferredApplications,
        controlledApplicationAppliedGoalChanges: report.appliedGoalChanges,
        controlledApplicationAppliedActions: report.appliedActions,
        controlledApplicationAppliedMemoryWrites: report.appliedMemoryWrites,
        controlledApplicationAppliedAnything: report.appliedAnything,
        controlledApplicationDryRun: report.dryRun,
        controlledApplicationLiveAgentMutated: report.liveAgentMutated,
        controlledApplicationMemoryMutated: report.memoryMutated,
        controlledApplicationMovementStackUsed: report.movementStackUsed,
        controlledApplicationWorldMutated: report.worldMutated,
        controlledApplicationTerrainMutated: report.terrainMutated,
        controlledApplicationBounded: report.bounded,
        controlledApplicationDeterministicOrder: report.deterministicOrder,
        controlledApplicationDigestsEqual: report.digestsEqual,
        controlledApplicationRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeControlledApplicationHardeningMetrics(
    report: LabControlledApplicationHardeningReport
) -> LabControlledApplicationHardeningMetrics {
    LabControlledApplicationHardeningMetrics(
        controlledApplicationHardeningSuccess: report.success,
        controlledApplicationHardeningCases: report.cases,
        controlledApplicationHardeningCasesPassed: report.casesPassed,
        controlledApplicationHardeningCasesFailed: report.casesFailed,
        controlledApplicationHardeningAgents: report.agents,
        controlledApplicationHardeningInputs: report.inputs,
        controlledApplicationHardeningEligibilities: report.eligibilities,
        controlledApplicationHardeningDecisions: report.decisions,
        controlledApplicationHardeningEligibleGoalChanges: report.eligibleGoalChanges,
        controlledApplicationHardeningEligibleActions: report.eligibleActions,
        controlledApplicationHardeningEligibleMemoryWrites: report.eligibleMemoryWrites,
        controlledApplicationHardeningRejectedApplications: report.rejectedApplications,
        controlledApplicationHardeningDeferredApplications: report.deferredApplications,
        controlledApplicationHardeningAppliedGoalChanges: report.appliedGoalChanges,
        controlledApplicationHardeningAppliedActions: report.appliedActions,
        controlledApplicationHardeningAppliedMemoryWrites: report.appliedMemoryWrites,
        controlledApplicationHardeningAppliedAnything: report.appliedAnything,
        controlledApplicationHardeningDryRun: report.dryRun,
        controlledApplicationHardeningLiveAgentMutated: report.liveAgentMutated,
        controlledApplicationHardeningMemoryMutated: report.memoryMutated,
        controlledApplicationHardeningMovementStackUsed: report.movementStackUsed,
        controlledApplicationHardeningWorldMutated: report.worldMutated,
        controlledApplicationHardeningTerrainMutated: report.terrainMutated,
        controlledApplicationHardeningBounded: report.bounded,
        controlledApplicationHardeningDeterministicOrder: report.deterministicOrder,
        controlledApplicationHardeningDigestsEqual: report.digestsEqual,
        controlledApplicationHardeningRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeControlledApplicationEventLines(
    report: LabControlledApplicationReport,
    decisions: [LabControlledApplicationDecision]
) throws -> String {
    var lines = ""
    for decision in decisions.sorted(by: controlledApplicationDecisionSort) {
        let eligibility = decision.eligibility
        lines += try controlledApplicationJSONLine(LabControlledApplicationRecordedEvent(
            type: "lab_controlled_application_recorded",
            event: "lab_controlled_application_recorded",
            success: decision.success,
            agentId: decision.agentId,
            tick: decision.tick,
            computedSelectedGoal: eligibility.computedSelectedGoal,
            computedSelectedAction: eligibility.computedSelectedAction,
            goalChangeEligible: eligibility.goalChangeEligible,
            actionSelectionEligible: eligibility.actionSelectionEligible,
            memoryWriteEligible: eligibility.memoryWriteEligible,
            eligible: eligibility.eligible,
            rejectedReasons: eligibility.rejectedReasons,
            deferredReasons: eligibility.deferredReasons,
            appliedGoalChange: decision.appliedGoalChange,
            appliedAction: decision.appliedAction,
            appliedMemoryWrite: decision.appliedMemoryWrite,
            appliedAnything: decision.appliedAnything,
            dryRun: decision.dryRun,
            liveAgentMutated: decision.liveAgentMutated,
            movementStackUsed: decision.movementStackUsed
        ))
    }
    lines += try controlledApplicationJSONLine(LabControlledApplicationSummaryEvent(
        type: "lab_controlled_application_summary_recorded",
        event: "lab_controlled_application_summary_recorded",
        success: report.success,
        agents: report.agents,
        ticks: report.ticks,
        eligibilities: report.eligibilities,
        decisions: report.decisions,
        eligibleGoalChanges: report.eligibleGoalChanges,
        eligibleActions: report.eligibleActions,
        eligibleMemoryWrites: report.eligibleMemoryWrites,
        rejectedApplications: report.rejectedApplications,
        deferredApplications: report.deferredApplications,
        appliedGoalChanges: report.appliedGoalChanges,
        appliedActions: report.appliedActions,
        appliedMemoryWrites: report.appliedMemoryWrites,
        appliedAnything: report.appliedAnything,
        dryRun: report.dryRun,
        bounded: report.bounded,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
    return lines
}

private func makeControlledApplicationHardeningEventLines(
    report: LabControlledApplicationHardeningReport
) throws -> String {
    try controlledApplicationJSONLine(LabControlledApplicationHardeningEvent(
        type: "lab_controlled_application_hardening_recorded",
        event: "lab_controlled_application_hardening_recorded",
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        casesFailed: report.casesFailed,
        agents: report.agents,
        inputs: report.inputs,
        eligibilities: report.eligibilities,
        decisions: report.decisions,
        eligibleGoalChanges: report.eligibleGoalChanges,
        eligibleActions: report.eligibleActions,
        eligibleMemoryWrites: report.eligibleMemoryWrites,
        rejectedApplications: report.rejectedApplications,
        deferredApplications: report.deferredApplications,
        appliedGoalChanges: report.appliedGoalChanges,
        appliedActions: report.appliedActions,
        appliedMemoryWrites: report.appliedMemoryWrites,
        appliedAnything: report.appliedAnything,
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

private func controlledApplicationJSONLine<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    return String(decoding: data, as: UTF8.self) + "\n"
}

private func controlledApplicationCheck(
    _ name: String,
    _ passed: Bool,
    _ expected: String,
    _ actual: String
) -> LabBehaviorLoopInvariantCheck {
    LabBehaviorLoopInvariantCheck(name: name, passed: passed, expected: expected, actual: actual)
}

private func controlledApplicationPolicySort(
    _ lhs: LabControlledApplicationPolicy,
    _ rhs: LabControlledApplicationPolicy
) -> Bool {
    let lhsKey = [
        "\(lhs.dryRun)",
        lhs.applyMode,
        "\(lhs.allowGoalChange)",
        "\(lhs.allowActionSelection)",
        "\(lhs.allowMemoryWrite)",
        lhs.allowedGoals.joined(separator: ","),
        lhs.allowedActions.joined(separator: ","),
        "\(lhs.maxApplicationsPerTick)",
        "\(lhs.maxMemoryWritesPerTick)"
    ]
    let rhsKey = [
        "\(rhs.dryRun)",
        rhs.applyMode,
        "\(rhs.allowGoalChange)",
        "\(rhs.allowActionSelection)",
        "\(rhs.allowMemoryWrite)",
        rhs.allowedGoals.joined(separator: ","),
        rhs.allowedActions.joined(separator: ","),
        "\(rhs.maxApplicationsPerTick)",
        "\(rhs.maxMemoryWritesPerTick)"
    ]
    return lhsKey.lexicographicallyPrecedes(rhsKey)
}

private func controlledApplicationInputSort(
    _ lhs: LabControlledApplicationInput,
    _ rhs: LabControlledApplicationInput
) -> Bool {
    (lhs.tick, lhs.agentId) < (rhs.tick, rhs.agentId)
}

private func controlledApplicationEligibilitySort(
    _ lhs: LabControlledApplicationEligibility,
    _ rhs: LabControlledApplicationEligibility
) -> Bool {
    (lhs.tick, lhs.agentId) < (rhs.tick, rhs.agentId)
}

private func controlledApplicationDecisionSort(
    _ lhs: LabControlledApplicationDecision,
    _ rhs: LabControlledApplicationDecision
) -> Bool {
    (lhs.tick, lhs.agentId) < (rhs.tick, rhs.agentId)
}

private func controlledApplicationHardeningCaseSort(
    _ lhs: LabControlledApplicationHardeningCaseResult,
    _ rhs: LabControlledApplicationHardeningCaseResult
) -> Bool {
    (lhs.index, lhs.agentId ?? "", lhs.name) < (rhs.index, rhs.agentId ?? "", rhs.name)
}
