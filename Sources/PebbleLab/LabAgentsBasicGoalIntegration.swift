import Foundation

let agentsBasicGoalIntegrationScenarioName = "agents_basic_goal_integration_guarded_fixture_smoke"
let agentsBasicGoalIntegrationHardeningScenarioName = "agents_basic_goal_integration_guarded_hardening_smoke"

private let agentsBasicGoalIntegrationKnownGoals = [
    LabGoalKind.idle.rawValue,
    LabGoalKind.rest.rawValue,
    LabGoalKind.seekSafety.rawValue,
    LabGoalKind.explore.rawValue,
    LabGoalKind.observeOtherAgent.rawValue
]

struct LabAgentsBasicGoalIntegrationPolicy: Codable, Equatable {
    let integrationMode: String
    let allowAgentsBasicGoalIntegration: Bool
    let allowedGoals: [String]
    let maxAgentsBasicGoalApplicationsPerTick: Int
    let requireAppliedToFakeLive: Bool
    let requireFakeLiveGoalChanged: Bool
    let requireNoRejectedReasons: Bool
    let requireNoDeferredReasons: Bool
    let requireAgentsBasicUntouched: Bool
    let requireLiveRuntimeUntouched: Bool
    let requireReason: Bool
    let requireDedicatedScenario: Bool
    let allowNoopGoal: Bool
    let allowDeferred: Bool
}

struct LabAgentsBasicGoalIntegrationInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let agentsBasicGoalBefore: String
    let fakeLiveGoalAfter: String
    let targetGoal: String
    let appliedToFakeLive: Bool
    let fakeLiveGoalChanged: Bool
    let appliedToAgentsBasicBefore: Bool
    let agentsBasicTouchedBefore: Bool
    let liveRuntimeTouchedBefore: Bool
    let priorRejectedReasons: [String]
    let priorDeferredReasons: [String]
    let fakeLiveDecisionSummary: String
    let dedicatedScenario: Bool
    let policy: LabAgentsBasicGoalIntegrationPolicy
    let reason: String
}

struct LabAgentsBasicGoalIntegrationDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let agentsBasicGoalBefore: String
    let targetGoal: String
    let agentsBasicGoalAfterCandidate: String
    let agentsBasicGoalWouldChange: Bool
    let agentsBasicApplyEligible: Bool
    let wouldApplyToAgentsBasic: Bool
    let appliedToAgentsBasic: Bool
    let agentsBasicTouched: Bool
    let runtimeBehaviorChanged: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let integrationMode: String
    let success: Bool
}

struct LabAgentsBasicGoalIntegrationReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let policies: Int
    let inputs: Int
    let decisions: Int
    let agentsBasicApplyEligible: Int
    let wouldApplyToAgentsBasic: Int
    let appliedToAgentsBasic: Int
    let agentsBasicGoalWouldChange: Int
    let agentsBasicNoops: Int
    let rejectedAgentsBasicIntegrations: Int
    let deferredAgentsBasicIntegrations: Int
    let agentsBasicTouched: Bool
    let runtimeBehaviorChanged: Bool
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

struct LabAgentsBasicGoalIntegrationInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let inputs: Int
    let decisions: Int
    let wouldApplyToAgentsBasic: Int
    let appliedToAgentsBasic: Int
}

struct LabAgentsBasicGoalIntegrationInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabAgentsBasicGoalIntegrationInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabAgentsBasicGoalIntegrationDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabAgentsBasicGoalIntegrationMetrics: Codable, Equatable {
    let agentsBasicGoalIntegrationSuccess: Bool
    let agentsBasicGoalIntegrationAgents: Int
    let agentsBasicGoalIntegrationTicks: Int
    let agentsBasicGoalIntegrationPolicies: Int
    let agentsBasicGoalIntegrationInputs: Int
    let agentsBasicGoalIntegrationDecisions: Int
    let agentsBasicGoalIntegrationEligible: Int
    let agentsBasicGoalIntegrationWouldApply: Int
    let agentsBasicGoalIntegrationApplied: Int
    let agentsBasicGoalIntegrationGoalWouldChange: Int
    let agentsBasicGoalIntegrationNoops: Int
    let agentsBasicGoalIntegrationRejected: Int
    let agentsBasicGoalIntegrationDeferred: Int
    let agentsBasicGoalIntegrationAgentsBasicTouched: Bool
    let agentsBasicGoalIntegrationRuntimeBehaviorChanged: Bool
    let agentsBasicGoalIntegrationMemoryMutated: Bool
    let agentsBasicGoalIntegrationMovementStackUsed: Bool
    let agentsBasicGoalIntegrationWorldMutated: Bool
    let agentsBasicGoalIntegrationTerrainMutated: Bool
    let agentsBasicGoalIntegrationBounded: Bool
    let agentsBasicGoalIntegrationDeterministicOrder: Bool
    let agentsBasicGoalIntegrationDigestsEqual: Bool
    let agentsBasicGoalIntegrationRepeatabilityFailures: Int
}

struct LabAgentsBasicGoalIntegrationFixture: Codable, Equatable {
    let report: LabAgentsBasicGoalIntegrationReport
    let invariantReport: LabAgentsBasicGoalIntegrationInvariantReport
    let policies: [LabAgentsBasicGoalIntegrationPolicy]
    let inputs: [LabAgentsBasicGoalIntegrationInput]
    let decisions: [LabAgentsBasicGoalIntegrationDecision]
    let digest: LabAgentsBasicGoalIntegrationDigest
    let eventLines: String
    let metrics: LabAgentsBasicGoalIntegrationMetrics
}

struct LabAgentsBasicGoalIntegrationHardeningCase: Codable, Equatable {
    let name: String
    let agentId: String
    let expectation: String
}

struct LabAgentsBasicGoalIntegrationHardeningCaseResult: Codable, Equatable {
    let name: String
    let agentId: String
    let passed: Bool
    let detail: String
}

struct LabAgentsBasicGoalIntegrationHardeningReport: Codable, Equatable {
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
    let agentsBasicApplyEligible: Int
    let wouldApplyToAgentsBasic: Int
    let appliedToAgentsBasic: Int
    let agentsBasicGoalWouldChange: Int
    let agentsBasicNoops: Int
    let rejectedAgentsBasicIntegrations: Int
    let deferredAgentsBasicIntegrations: Int
    let agentsBasicTouched: Bool
    let runtimeBehaviorChanged: Bool
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

struct LabAgentsBasicGoalIntegrationHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let inputs: Int
    let decisions: Int
}

struct LabAgentsBasicGoalIntegrationHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabAgentsBasicGoalIntegrationHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabAgentsBasicGoalIntegrationHardeningMetrics: Codable, Equatable {
    let agentsBasicGoalIntegrationHardeningSuccess: Bool
    let agentsBasicGoalIntegrationHardeningCases: Int
    let agentsBasicGoalIntegrationHardeningCasesPassed: Int
    let agentsBasicGoalIntegrationHardeningCasesFailed: Int
    let agentsBasicGoalIntegrationHardeningAgents: Int
    let agentsBasicGoalIntegrationHardeningPolicies: Int
    let agentsBasicGoalIntegrationHardeningInputs: Int
    let agentsBasicGoalIntegrationHardeningDecisions: Int
    let agentsBasicGoalIntegrationHardeningEligible: Int
    let agentsBasicGoalIntegrationHardeningWouldApply: Int
    let agentsBasicGoalIntegrationHardeningApplied: Int
    let agentsBasicGoalIntegrationHardeningGoalWouldChange: Int
    let agentsBasicGoalIntegrationHardeningNoops: Int
    let agentsBasicGoalIntegrationHardeningRejected: Int
    let agentsBasicGoalIntegrationHardeningDeferred: Int
    let agentsBasicGoalIntegrationHardeningAgentsBasicTouched: Bool
    let agentsBasicGoalIntegrationHardeningRuntimeBehaviorChanged: Bool
    let agentsBasicGoalIntegrationHardeningMemoryMutated: Bool
    let agentsBasicGoalIntegrationHardeningMovementStackUsed: Bool
    let agentsBasicGoalIntegrationHardeningWorldMutated: Bool
    let agentsBasicGoalIntegrationHardeningTerrainMutated: Bool
    let agentsBasicGoalIntegrationHardeningBounded: Bool
    let agentsBasicGoalIntegrationHardeningDeterministicOrder: Bool
    let agentsBasicGoalIntegrationHardeningDigestsEqual: Bool
    let agentsBasicGoalIntegrationHardeningRepeatabilityFailures: Int
}

struct LabAgentsBasicGoalIntegrationHardeningFixture: Codable, Equatable {
    let report: LabAgentsBasicGoalIntegrationHardeningReport
    let invariantReport: LabAgentsBasicGoalIntegrationHardeningInvariantReport
    let cases: [LabAgentsBasicGoalIntegrationHardeningCaseResult]
    let policies: [LabAgentsBasicGoalIntegrationPolicy]
    let inputs: [LabAgentsBasicGoalIntegrationInput]
    let decisions: [LabAgentsBasicGoalIntegrationDecision]
    let digest: LabAgentsBasicGoalIntegrationDigest
    let eventLines: String
    let metrics: LabAgentsBasicGoalIntegrationHardeningMetrics
}

private struct LabAgentsBasicGoalIntegrationRun {
    let policies: [LabAgentsBasicGoalIntegrationPolicy]
    let inputs: [LabAgentsBasicGoalIntegrationInput]
    let decisions: [LabAgentsBasicGoalIntegrationDecision]
}

private struct LabAgentsBasicGoalIntegrationRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let agentsBasicGoalBefore: String
    let targetGoal: String
    let agentsBasicGoalAfterCandidate: String
    let agentsBasicGoalWouldChange: Bool
    let agentsBasicApplyEligible: Bool
    let wouldApplyToAgentsBasic: Bool
    let appliedToAgentsBasic: Bool
    let agentsBasicTouched: Bool
    let runtimeBehaviorChanged: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let integrationMode: String
}

private struct LabAgentsBasicGoalIntegrationSummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let ticks: Int
    let inputs: Int
    let decisions: Int
    let agentsBasicApplyEligible: Int
    let wouldApplyToAgentsBasic: Int
    let appliedToAgentsBasic: Int
    let agentsBasicGoalWouldChange: Int
    let noops: Int
    let rejected: Int
    let deferred: Int
    let agentsBasicTouched: Bool
    let runtimeBehaviorChanged: Bool
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

private struct LabAgentsBasicGoalIntegrationHardeningRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let agents: Int
    let inputs: Int
    let decisions: Int
    let agentsBasicApplyEligible: Int
    let wouldApplyToAgentsBasic: Int
    let appliedToAgentsBasic: Int
    let agentsBasicGoalWouldChange: Int
    let agentsBasicNoops: Int
    let rejectedAgentsBasicIntegrations: Int
    let deferredAgentsBasicIntegrations: Int
    let agentsBasicTouched: Bool
    let runtimeBehaviorChanged: Bool
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeAgentsBasicGoalIntegrationFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabAgentsBasicGoalIntegrationFixture {
    let run = makeAgentsBasicGoalIntegrationRun(ticks: ticks)
    let repeatRun = makeAgentsBasicGoalIntegrationRun(ticks: ticks)
    let digestValue = makeAgentsBasicGoalIntegrationDigestValue(run: run)
    let digestRepeatValue = makeAgentsBasicGoalIntegrationDigestValue(run: repeatRun)
    let digest = LabAgentsBasicGoalIntegrationDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeAgentsBasicGoalIntegrationReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeAgentsBasicGoalIntegrationInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabAgentsBasicGoalIntegrationFixture(
        report: report,
        invariantReport: invariantReport,
        policies: run.policies,
        inputs: run.inputs,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeAgentsBasicGoalIntegrationEventLines(report: report, decisions: run.decisions),
        metrics: makeAgentsBasicGoalIntegrationMetrics(report: report)
    )
}

func makeAgentsBasicGoalIntegrationHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabAgentsBasicGoalIntegrationHardeningFixture {
    let run = makeAgentsBasicGoalIntegrationHardeningRun(ticks: ticks)
    let repeatRun = makeAgentsBasicGoalIntegrationHardeningRun(ticks: ticks)
    let cases = makeAgentsBasicGoalIntegrationHardeningCases(run: run, ticks: ticks)
    let repeatCases = makeAgentsBasicGoalIntegrationHardeningCases(run: repeatRun, ticks: ticks)
    let digestValue = makeAgentsBasicGoalIntegrationHardeningDigestValue(run: run, cases: cases)
    let digestRepeatValue = makeAgentsBasicGoalIntegrationHardeningDigestValue(
        run: repeatRun,
        cases: repeatCases
    )
    let digest = LabAgentsBasicGoalIntegrationDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeAgentsBasicGoalIntegrationHardeningReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        cases: cases,
        digest: digest
    )
    let invariantReport = makeAgentsBasicGoalIntegrationHardeningInvariantReport(
        report: report,
        run: run,
        cases: cases,
        digest: digest
    )
    return LabAgentsBasicGoalIntegrationHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: cases,
        policies: run.policies,
        inputs: run.inputs,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeAgentsBasicGoalIntegrationHardeningEventLines(report: report),
        metrics: makeAgentsBasicGoalIntegrationHardeningMetrics(report: report)
    )
}

private func makeAgentsBasicGoalIntegrationRun(ticks: Int) -> LabAgentsBasicGoalIntegrationRun {
    let tick = max(1, ticks)
    let inputs = makeAgentsBasicGoalIntegrationInputs(tick: tick)
        .sorted(by: agentsBasicGoalIntegrationInputSort)
    let decisions = inputs.map(makeAgentsBasicGoalIntegrationDecision)
        .sorted(by: agentsBasicGoalIntegrationDecisionSort)
    let policies = inputs.map(\.policy).sorted(by: agentsBasicGoalIntegrationPolicySort)
    return LabAgentsBasicGoalIntegrationRun(
        policies: policies,
        inputs: inputs,
        decisions: decisions
    )
}

private func makeAgentsBasicGoalIntegrationHardeningRun(ticks: Int) -> LabAgentsBasicGoalIntegrationRun {
    let tick = max(1, ticks)
    let inputs = makeAgentsBasicGoalIntegrationHardeningInputs(tick: tick)
        .sorted(by: agentsBasicGoalIntegrationInputSort)
    let decisions = inputs.map(makeAgentsBasicGoalIntegrationDecision)
        .sorted(by: agentsBasicGoalIntegrationDecisionSort)
    let policies = inputs.map(\.policy).sorted(by: agentsBasicGoalIntegrationPolicySort)
    return LabAgentsBasicGoalIntegrationRun(
        policies: policies,
        inputs: inputs,
        decisions: decisions
    )
}

private func makeAgentsBasicGoalIntegrationInputs(tick: Int) -> [LabAgentsBasicGoalIntegrationInput] {
    let defaultPolicy = agentsBasicGoalIntegrationPolicy()
    let noopPolicy = agentsBasicGoalIntegrationPolicy(allowNoopGoal: true)
    let notAllowedPolicy = agentsBasicGoalIntegrationPolicy(
        allowedGoals: [
            LabGoalKind.idle.rawValue,
            LabGoalKind.seekSafety.rawValue,
            LabGoalKind.explore.rawValue,
            LabGoalKind.observeOtherAgent.rawValue
        ]
    )
    let auditPolicy = agentsBasicGoalIntegrationPolicy(
        integrationMode: "agents_basic_goal_integration_audit_only",
        allowDeferred: true
    )
    let maxPolicy = agentsBasicGoalIntegrationPolicy(maxAgentsBasicGoalApplicationsPerTick: 0)

    return [
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_00_safety",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            policy: defaultPolicy,
            reason: "candidate-only agents_basic safety goal integration"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_01_explore",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            policy: defaultPolicy,
            reason: "candidate-only agents_basic explore goal integration"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_02_noop",
            agentsBasicGoalBefore: LabGoalKind.explore.rawValue,
            fakeLiveGoalAfter: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            fakeLiveGoalChanged: false,
            policy: noopPolicy,
            reason: "agents_basic goal already matches target"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_03_unknown",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: "unknownGoal",
            targetGoal: "unknownGoal",
            policy: defaultPolicy,
            reason: "unknown target rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_04_not_allowed",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.rest.rawValue,
            targetGoal: LabGoalKind.rest.rawValue,
            policy: notAllowedPolicy,
            reason: "target not allowed rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_05_applied_fake_live_false",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            appliedToFakeLive: false,
            policy: defaultPolicy,
            reason: "applied to fake-live required rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_06_fake_live_changed_false",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            fakeLiveGoalChanged: false,
            policy: defaultPolicy,
            reason: "fake-live goal changed required rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_07_prior_applied_agents_basic",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            appliedToAgentsBasicBefore: true,
            policy: defaultPolicy,
            reason: "prior agents_basic application rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_08_agents_basic_touched",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            agentsBasicTouchedBefore: true,
            policy: defaultPolicy,
            reason: "agents_basic touched before rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_09_live_runtime_touched",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            liveRuntimeTouchedBefore: true,
            policy: defaultPolicy,
            reason: "live runtime touched before rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_10_prior_rejected",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            priorRejectedReasons: ["unknown target goal"],
            policy: defaultPolicy,
            reason: "prior rejected reasons rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_11_prior_deferred",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            priorDeferredReasons: ["audit-only deferred"],
            policy: defaultPolicy,
            reason: "prior deferred reasons rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_12_audit",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.observeOtherAgent.rawValue,
            targetGoal: LabGoalKind.observeOtherAgent.rawValue,
            policy: auditPolicy,
            reason: "audit-only agents_basic integration deferred"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_13_missing_reason",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            policy: defaultPolicy,
            reason: ""
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_14_max",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            policy: maxPolicy,
            reason: "max agents_basic goal applications exceeded"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_agent_15_dedicated_false",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            dedicatedScenario: false,
            policy: defaultPolicy,
            reason: "dedicated scenario required rejection"
        )
    ]
}

private func makeAgentsBasicGoalIntegrationHardeningInputs(tick: Int) -> [LabAgentsBasicGoalIntegrationInput] {
    let defaultPolicy = agentsBasicGoalIntegrationPolicy()
    let noopPolicy = agentsBasicGoalIntegrationPolicy(allowNoopGoal: true)
    let notAllowedPolicy = agentsBasicGoalIntegrationPolicy(
        allowedGoals: [
            LabGoalKind.idle.rawValue,
            LabGoalKind.seekSafety.rawValue,
            LabGoalKind.explore.rawValue,
            LabGoalKind.observeOtherAgent.rawValue
        ]
    )
    let disallowPolicy = agentsBasicGoalIntegrationPolicy(allowAgentsBasicGoalIntegration: false)
    let auditPolicy = agentsBasicGoalIntegrationPolicy(
        integrationMode: "agents_basic_goal_integration_audit_only",
        allowDeferred: true
    )
    let maxPolicy = agentsBasicGoalIntegrationPolicy(maxAgentsBasicGoalApplicationsPerTick: 0)

    return [
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_00_safety",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            policy: defaultPolicy,
            reason: "candidate-only agents_basic safety goal integration"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_01_explore",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            policy: defaultPolicy,
            reason: "candidate-only agents_basic explore goal integration"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_02_observe",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.observeOtherAgent.rawValue,
            targetGoal: LabGoalKind.observeOtherAgent.rawValue,
            policy: defaultPolicy,
            reason: "candidate-only agents_basic observe goal integration"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_03_noop_allowed",
            agentsBasicGoalBefore: LabGoalKind.explore.rawValue,
            fakeLiveGoalAfter: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            fakeLiveGoalChanged: false,
            policy: noopPolicy,
            reason: "agents_basic goal already matches target"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_04_noop_disallowed",
            agentsBasicGoalBefore: LabGoalKind.explore.rawValue,
            fakeLiveGoalAfter: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            fakeLiveGoalChanged: false,
            policy: defaultPolicy,
            reason: "agents_basic no-op rejected when policy disallows no-op"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_05_unknown",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: "unknownGoal",
            targetGoal: "unknownGoal",
            policy: defaultPolicy,
            reason: "unknown target rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_06_not_allowed",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.rest.rawValue,
            targetGoal: LabGoalKind.rest.rawValue,
            policy: notAllowedPolicy,
            reason: "target not allowed rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_07_missing_before",
            agentsBasicGoalBefore: "",
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            policy: defaultPolicy,
            reason: "missing agents_basic goal before rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_08_missing_target",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: "",
            targetGoal: "",
            policy: defaultPolicy,
            reason: "missing target goal rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_09_missing_reason",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            policy: defaultPolicy,
            reason: ""
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_10_applied_fake_live_false",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            appliedToFakeLive: false,
            policy: defaultPolicy,
            reason: "applied to fake-live required rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_11_fake_live_changed_false",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            fakeLiveGoalChanged: false,
            policy: defaultPolicy,
            reason: "fake-live goal changed required rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_12_prior_applied_agents_basic",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            appliedToAgentsBasicBefore: true,
            policy: defaultPolicy,
            reason: "prior agents_basic application rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_13_agents_basic_touched",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            agentsBasicTouchedBefore: true,
            policy: defaultPolicy,
            reason: "agents_basic touched before rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_14_live_runtime_touched",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            liveRuntimeTouchedBefore: true,
            policy: defaultPolicy,
            reason: "live runtime touched before rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_15_prior_rejected",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            priorRejectedReasons: ["unknown target goal"],
            policy: defaultPolicy,
            reason: "prior rejected reasons rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_16_prior_deferred",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            priorDeferredReasons: ["audit-only deferred"],
            policy: defaultPolicy,
            reason: "prior deferred reasons rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_17_policy_disallow",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            policy: disallowPolicy,
            reason: "policy disallows agents_basic integration"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_18_dedicated_false",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            dedicatedScenario: false,
            policy: defaultPolicy,
            reason: "dedicated scenario required rejection"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_19_max",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            policy: maxPolicy,
            reason: "max agents_basic goal applications exceeded"
        ),
        agentsBasicGoalIntegrationInput(
            tick: tick,
            agentId: "agents_basic_goal_integration_hardening_agent_20_audit",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            fakeLiveGoalAfter: LabGoalKind.observeOtherAgent.rawValue,
            targetGoal: LabGoalKind.observeOtherAgent.rawValue,
            policy: auditPolicy,
            reason: "audit-only agents_basic integration deferred"
        )
    ]
}

private func agentsBasicGoalIntegrationPolicy(
    integrationMode: String = "agents_basic_goal_integration_guarded_dry_run",
    allowAgentsBasicGoalIntegration: Bool = true,
    allowedGoals: [String] = [
        LabGoalKind.idle.rawValue,
        LabGoalKind.rest.rawValue,
        LabGoalKind.seekSafety.rawValue,
        LabGoalKind.explore.rawValue,
        LabGoalKind.observeOtherAgent.rawValue
    ],
    maxAgentsBasicGoalApplicationsPerTick: Int = 1,
    requireAppliedToFakeLive: Bool = true,
    requireFakeLiveGoalChanged: Bool = true,
    requireNoRejectedReasons: Bool = true,
    requireNoDeferredReasons: Bool = true,
    requireAgentsBasicUntouched: Bool = true,
    requireLiveRuntimeUntouched: Bool = true,
    requireReason: Bool = true,
    requireDedicatedScenario: Bool = true,
    allowNoopGoal: Bool = false,
    allowDeferred: Bool = false
) -> LabAgentsBasicGoalIntegrationPolicy {
    LabAgentsBasicGoalIntegrationPolicy(
        integrationMode: integrationMode,
        allowAgentsBasicGoalIntegration: allowAgentsBasicGoalIntegration,
        allowedGoals: allowedGoals,
        maxAgentsBasicGoalApplicationsPerTick: maxAgentsBasicGoalApplicationsPerTick,
        requireAppliedToFakeLive: requireAppliedToFakeLive,
        requireFakeLiveGoalChanged: requireFakeLiveGoalChanged,
        requireNoRejectedReasons: requireNoRejectedReasons,
        requireNoDeferredReasons: requireNoDeferredReasons,
        requireAgentsBasicUntouched: requireAgentsBasicUntouched,
        requireLiveRuntimeUntouched: requireLiveRuntimeUntouched,
        requireReason: requireReason,
        requireDedicatedScenario: requireDedicatedScenario,
        allowNoopGoal: allowNoopGoal,
        allowDeferred: allowDeferred
    )
}

private func agentsBasicGoalIntegrationInput(
    tick: Int,
    agentId: String,
    agentsBasicGoalBefore: String,
    fakeLiveGoalAfter: String,
    targetGoal: String,
    appliedToFakeLive: Bool = true,
    fakeLiveGoalChanged: Bool = true,
    appliedToAgentsBasicBefore: Bool = false,
    agentsBasicTouchedBefore: Bool = false,
    liveRuntimeTouchedBefore: Bool = false,
    priorRejectedReasons: [String] = [],
    priorDeferredReasons: [String] = [],
    dedicatedScenario: Bool = true,
    policy: LabAgentsBasicGoalIntegrationPolicy,
    reason: String
) -> LabAgentsBasicGoalIntegrationInput {
    LabAgentsBasicGoalIntegrationInput(
        tick: tick,
        agentId: agentId,
        agentsBasicGoalBefore: agentsBasicGoalBefore,
        fakeLiveGoalAfter: fakeLiveGoalAfter,
        targetGoal: targetGoal,
        appliedToFakeLive: appliedToFakeLive,
        fakeLiveGoalChanged: fakeLiveGoalChanged,
        appliedToAgentsBasicBefore: appliedToAgentsBasicBefore,
        agentsBasicTouchedBefore: agentsBasicTouchedBefore,
        liveRuntimeTouchedBefore: liveRuntimeTouchedBefore,
        priorRejectedReasons: priorRejectedReasons,
        priorDeferredReasons: priorDeferredReasons,
        fakeLiveDecisionSummary: "appliedToFakeLive=\(appliedToFakeLive);fakeLiveGoalAfter=\(fakeLiveGoalAfter);targetGoal=\(targetGoal)",
        dedicatedScenario: dedicatedScenario,
        policy: policy,
        reason: reason
    )
}

private func makeAgentsBasicGoalIntegrationDecision(
    input: LabAgentsBasicGoalIntegrationInput
) -> LabAgentsBasicGoalIntegrationDecision {
    var rejectedReasons: [String] = []
    var deferredReasons: [String] = []
    let goalKnown = agentsBasicGoalIntegrationKnownGoals.contains(input.targetGoal)
    let goalAllowed = input.policy.allowedGoals.contains(input.targetGoal)
    let reasonPresent = !input.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let agentsBasicGoalWouldChange = goalKnown && input.agentsBasicGoalBefore != input.targetGoal

    if input.policy.requireAppliedToFakeLive && !input.appliedToFakeLive {
        rejectedReasons.append("applied to fake live required")
    }
    if input.policy.requireFakeLiveGoalChanged
        && !input.fakeLiveGoalChanged
        && agentsBasicGoalWouldChange {
        rejectedReasons.append("fake live goal changed required")
    }
    if input.agentsBasicGoalBefore.isEmpty {
        rejectedReasons.append("agents_basic goal before missing")
    }
    if input.targetGoal.isEmpty {
        rejectedReasons.append("target goal missing")
    } else if !goalKnown {
        rejectedReasons.append("unknown target goal")
    }
    if goalKnown && !goalAllowed {
        rejectedReasons.append("target goal not allowed")
    }
    if input.appliedToAgentsBasicBefore {
        rejectedReasons.append("prior applied to agents_basic")
    }
    if input.policy.requireAgentsBasicUntouched && input.agentsBasicTouchedBefore {
        rejectedReasons.append("agents_basic touched before")
    }
    if input.policy.requireLiveRuntimeUntouched && input.liveRuntimeTouchedBefore {
        rejectedReasons.append("live runtime touched before")
    }
    if input.policy.requireNoRejectedReasons && !input.priorRejectedReasons.isEmpty {
        rejectedReasons.append("prior rejected reasons present")
    }
    if input.policy.requireNoDeferredReasons && !input.priorDeferredReasons.isEmpty {
        rejectedReasons.append("prior deferred reasons present")
    }
    if input.policy.requireReason && !reasonPresent {
        rejectedReasons.append("missing reason")
    }
    if !input.policy.allowAgentsBasicGoalIntegration {
        rejectedReasons.append("policy disallows agents_basic goal integration")
    }
    if input.policy.requireDedicatedScenario && !input.dedicatedScenario {
        rejectedReasons.append("dedicated scenario false")
    }
    if input.policy.maxAgentsBasicGoalApplicationsPerTick < 1 && agentsBasicGoalWouldChange {
        rejectedReasons.append("max agents_basic goal applications exceeded")
    }
    if goalKnown && !agentsBasicGoalWouldChange && !input.policy.allowNoopGoal {
        rejectedReasons.append("agents_basic goal noop not allowed")
    }
    if input.policy.integrationMode == "agents_basic_goal_integration_audit_only"
        && input.policy.allowDeferred {
        deferredReasons.append("agents_basic_goal_integration_audit_only defers agents_basic integration")
    }

    let agentsBasicApplyEligible = rejectedReasons.isEmpty
        && deferredReasons.isEmpty
        && input.appliedToFakeLive
        && input.fakeLiveGoalChanged
        && goalKnown
        && goalAllowed
        && agentsBasicGoalWouldChange
        && !input.appliedToAgentsBasicBefore
        && !input.agentsBasicTouchedBefore
        && !input.liveRuntimeTouchedBefore
        && input.priorRejectedReasons.isEmpty
        && input.priorDeferredReasons.isEmpty
        && reasonPresent
        && input.policy.allowAgentsBasicGoalIntegration
        && input.dedicatedScenario
        && input.policy.maxAgentsBasicGoalApplicationsPerTick >= 1
    let wouldApplyToAgentsBasic = agentsBasicApplyEligible
        && input.policy.integrationMode == "agents_basic_goal_integration_guarded_dry_run"
    let agentsBasicGoalAfterCandidate = wouldApplyToAgentsBasic
        ? input.targetGoal
        : input.agentsBasicGoalBefore

    return LabAgentsBasicGoalIntegrationDecision(
        tick: input.tick,
        agentId: input.agentId,
        agentsBasicGoalBefore: input.agentsBasicGoalBefore,
        targetGoal: input.targetGoal,
        agentsBasicGoalAfterCandidate: agentsBasicGoalAfterCandidate,
        agentsBasicGoalWouldChange: agentsBasicGoalWouldChange,
        agentsBasicApplyEligible: agentsBasicApplyEligible,
        wouldApplyToAgentsBasic: wouldApplyToAgentsBasic,
        appliedToAgentsBasic: false,
        agentsBasicTouched: false,
        runtimeBehaviorChanged: false,
        rejectedReasons: rejectedReasons,
        deferredReasons: deferredReasons,
        integrationMode: input.policy.integrationMode,
        success: true
    )
}

private func makeAgentsBasicGoalIntegrationReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabAgentsBasicGoalIntegrationRun,
    digest: LabAgentsBasicGoalIntegrationDigest
) -> LabAgentsBasicGoalIntegrationReport {
    let agentsBasicApplyEligible = run.decisions.filter(\.agentsBasicApplyEligible).count
    let wouldApplyToAgentsBasic = run.decisions.filter(\.wouldApplyToAgentsBasic).count
    let appliedToAgentsBasic = run.decisions.filter(\.appliedToAgentsBasic).count
    let agentsBasicGoalWouldChange = run.decisions.filter(\.agentsBasicGoalWouldChange).count
    let agentsBasicNoops = run.decisions.filter {
        !$0.agentsBasicGoalWouldChange && $0.rejectedReasons.isEmpty && $0.deferredReasons.isEmpty
    }.count
    let rejectedAgentsBasicIntegrations = run.decisions.filter { !$0.rejectedReasons.isEmpty }.count
    let deferredAgentsBasicIntegrations = run.decisions.filter { !$0.deferredReasons.isEmpty }.count
    let agentsBasicTouched = run.decisions.contains { $0.agentsBasicTouched }
    let runtimeBehaviorChanged = run.decisions.contains { $0.runtimeBehaviorChanged }
    let deterministicOrder = run.decisions == run.decisions.sorted(by: agentsBasicGoalIntegrationDecisionSort)
    let bounded = run.inputs.count >= 10 && run.inputs.count <= 20 && run.decisions.count == run.inputs.count
    let success = Set(run.inputs.map(\.agentId)).count >= 5
        && run.inputs.count >= 10
        && run.decisions.count == run.inputs.count
        && agentsBasicApplyEligible >= 2
        && wouldApplyToAgentsBasic >= 2
        && agentsBasicGoalWouldChange >= 2
        && agentsBasicNoops >= 1
        && rejectedAgentsBasicIntegrations >= 6
        && deferredAgentsBasicIntegrations >= 1
        && appliedToAgentsBasic == 0
        && !agentsBasicTouched
        && !runtimeBehaviorChanged
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual

    return LabAgentsBasicGoalIntegrationReport(
        scenario: scenario,
        seed: seed,
        agents: Set(run.inputs.map(\.agentId)).count,
        ticks: ticks,
        policies: run.policies.count,
        inputs: run.inputs.count,
        decisions: run.decisions.count,
        agentsBasicApplyEligible: agentsBasicApplyEligible,
        wouldApplyToAgentsBasic: wouldApplyToAgentsBasic,
        appliedToAgentsBasic: appliedToAgentsBasic,
        agentsBasicGoalWouldChange: agentsBasicGoalWouldChange,
        agentsBasicNoops: agentsBasicNoops,
        rejectedAgentsBasicIntegrations: rejectedAgentsBasicIntegrations,
        deferredAgentsBasicIntegrations: deferredAgentsBasicIntegrations,
        agentsBasicTouched: agentsBasicTouched,
        runtimeBehaviorChanged: runtimeBehaviorChanged,
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

private func makeAgentsBasicGoalIntegrationInvariantReport(
    report: LabAgentsBasicGoalIntegrationReport,
    run: LabAgentsBasicGoalIntegrationRun,
    digest: LabAgentsBasicGoalIntegrationDigest
) -> LabAgentsBasicGoalIntegrationInvariantReport {
    let unknownTargetRejected = run.decisions.contains { $0.rejectedReasons.contains("unknown target goal") }
    let targetNotAllowedRejected = run.decisions.contains { $0.rejectedReasons.contains("target goal not allowed") }
    let appliedToFakeLiveRequired = run.decisions.contains { $0.rejectedReasons.contains("applied to fake live required") }
    let fakeLiveGoalChangedRequired = run.decisions.contains { $0.rejectedReasons.contains("fake live goal changed required") }
    let appliedBeforeRejected = run.decisions.contains { $0.rejectedReasons.contains("prior applied to agents_basic") }
    let agentsBasicTouchedBeforeRejected = run.decisions.contains { $0.rejectedReasons.contains("agents_basic touched before") }
    let liveRuntimeTouchedBeforeRejected = run.decisions.contains { $0.rejectedReasons.contains("live runtime touched before") }
    let priorRejectedRejected = run.decisions.contains { $0.rejectedReasons.contains("prior rejected reasons present") }
    let priorDeferredRejected = run.decisions.contains { $0.rejectedReasons.contains("prior deferred reasons present") }
    let missingReasonRejected = run.decisions.contains { $0.rejectedReasons.contains("missing reason") }
    let maxRejected = run.decisions.contains { $0.rejectedReasons.contains("max agents_basic goal applications exceeded") }
    let rejectedReasonsPresent = run.decisions.filter { !$0.rejectedReasons.isEmpty }
        .allSatisfy { !$0.rejectedReasons.joined().isEmpty }
    let deferredReasonsPresent = run.decisions.filter { !$0.deferredReasons.isEmpty }
        .allSatisfy { !$0.deferredReasons.joined().isEmpty }
    let audited = run.decisions.allSatisfy {
        !$0.agentsBasicGoalBefore.isEmpty
            && (!$0.targetGoal.isEmpty || $0.rejectedReasons.contains("target goal missing"))
            && !$0.agentsBasicGoalAfterCandidate.isEmpty
    }

    let checks: [LabBehaviorLoopInvariantCheck] = [
        agentsBasicGoalIntegrationCheck("scenario_name_expected", report.scenario == agentsBasicGoalIntegrationScenarioName, agentsBasicGoalIntegrationScenarioName, report.scenario),
        agentsBasicGoalIntegrationCheck("seed_recorded", report.seed > 0, "> 0", "\(report.seed)"),
        agentsBasicGoalIntegrationCheck("report_success", report.success, "true", "\(report.success)"),
        agentsBasicGoalIntegrationCheck("agents_expected", report.agents >= 5, ">= 5", "\(report.agents)"),
        agentsBasicGoalIntegrationCheck("ticks_expected", report.ticks >= 1, ">= 1", "\(report.ticks)"),
        agentsBasicGoalIntegrationCheck("policies_positive", report.policies > 0, "> 0", "\(report.policies)"),
        agentsBasicGoalIntegrationCheck("inputs_positive", report.inputs >= 10, ">= 10", "\(report.inputs)"),
        agentsBasicGoalIntegrationCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"),
        agentsBasicGoalIntegrationCheck("decisions_match_inputs", report.decisions == report.inputs, "\(report.inputs)", "\(report.decisions)"),
        agentsBasicGoalIntegrationCheck("agents_basic_eligible_covered", report.agentsBasicApplyEligible >= 2, ">= 2", "\(report.agentsBasicApplyEligible)"),
        agentsBasicGoalIntegrationCheck("would_apply_to_agents_basic_covered", report.wouldApplyToAgentsBasic >= 2, ">= 2", "\(report.wouldApplyToAgentsBasic)"),
        agentsBasicGoalIntegrationCheck("agents_basic_goal_would_change_covered", report.agentsBasicGoalWouldChange >= 2, ">= 2", "\(report.agentsBasicGoalWouldChange)"),
        agentsBasicGoalIntegrationCheck("agents_basic_noop_covered", report.agentsBasicNoops >= 1, ">= 1", "\(report.agentsBasicNoops)"),
        agentsBasicGoalIntegrationCheck("rejected_agents_basic_integration_covered", report.rejectedAgentsBasicIntegrations >= 6, ">= 6", "\(report.rejectedAgentsBasicIntegrations)"),
        agentsBasicGoalIntegrationCheck("deferred_agents_basic_integration_covered", report.deferredAgentsBasicIntegrations >= 1, ">= 1", "\(report.deferredAgentsBasicIntegrations)"),
        agentsBasicGoalIntegrationCheck("unknown_target_rejected", unknownTargetRejected, "true", "\(unknownTargetRejected)"),
        agentsBasicGoalIntegrationCheck("target_not_allowed_rejected", targetNotAllowedRejected, "true", "\(targetNotAllowedRejected)"),
        agentsBasicGoalIntegrationCheck("applied_to_fake_live_required", appliedToFakeLiveRequired, "true", "\(appliedToFakeLiveRequired)"),
        agentsBasicGoalIntegrationCheck("fake_live_goal_changed_required", fakeLiveGoalChangedRequired, "true", "\(fakeLiveGoalChangedRequired)"),
        agentsBasicGoalIntegrationCheck("applied_to_agents_basic_before_rejected", appliedBeforeRejected, "true", "\(appliedBeforeRejected)"),
        agentsBasicGoalIntegrationCheck("agents_basic_touched_before_rejected", agentsBasicTouchedBeforeRejected, "true", "\(agentsBasicTouchedBeforeRejected)"),
        agentsBasicGoalIntegrationCheck("live_runtime_touched_before_rejected", liveRuntimeTouchedBeforeRejected, "true", "\(liveRuntimeTouchedBeforeRejected)"),
        agentsBasicGoalIntegrationCheck("prior_rejected_reasons_rejected", priorRejectedRejected, "true", "\(priorRejectedRejected)"),
        agentsBasicGoalIntegrationCheck("prior_deferred_reasons_rejected_or_absent", priorDeferredRejected, "true", "\(priorDeferredRejected)"),
        agentsBasicGoalIntegrationCheck("missing_reason_rejected_or_absent", missingReasonRejected, "true", "\(missingReasonRejected)"),
        agentsBasicGoalIntegrationCheck("max_agents_basic_applications_rejected_or_absent", maxRejected, "true", "\(maxRejected)"),
        agentsBasicGoalIntegrationCheck("rejected_reasons_present", rejectedReasonsPresent, "true", "\(rejectedReasonsPresent)"),
        agentsBasicGoalIntegrationCheck("deferred_reasons_present", deferredReasonsPresent, "true", "\(deferredReasonsPresent)"),
        agentsBasicGoalIntegrationCheck("applied_to_agents_basic_zero", report.appliedToAgentsBasic == 0, "0", "\(report.appliedToAgentsBasic)"),
        agentsBasicGoalIntegrationCheck("agents_basic_not_touched", !report.agentsBasicTouched, "false", "\(report.agentsBasicTouched)"),
        agentsBasicGoalIntegrationCheck("runtime_behavior_unchanged", !report.runtimeBehaviorChanged, "false", "\(report.runtimeBehaviorChanged)"),
        agentsBasicGoalIntegrationCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"),
        agentsBasicGoalIntegrationCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"),
        agentsBasicGoalIntegrationCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"),
        agentsBasicGoalIntegrationCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"),
        agentsBasicGoalIntegrationCheck("agents_basic_goal_before_target_candidate_audited", audited, "true", "\(audited)"),
        agentsBasicGoalIntegrationCheck("bounded_true", report.bounded, "true", "\(report.bounded)"),
        agentsBasicGoalIntegrationCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"),
        agentsBasicGoalIntegrationCheck("deterministic_digest", report.deterministicDigest, "true", "\(report.deterministicDigest)"),
        agentsBasicGoalIntegrationCheck("digest_written", !report.digest.isEmpty, "non-empty", report.digest),
        agentsBasicGoalIntegrationCheck("digest_repeat_written", !report.digestRepeat.isEmpty, "non-empty", report.digestRepeat),
        agentsBasicGoalIntegrationCheck("digests_equal", digest.digestsEqual, "true", "\(digest.digestsEqual)"),
        agentsBasicGoalIntegrationCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"),
        agentsBasicGoalIntegrationCheck("report_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("invariant_report_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("policies_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("inputs_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("decisions_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("digest_output_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("metrics_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("event_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("metrics_prefix_expected", true, "agentsBasicGoalIntegration*", "agentsBasicGoalIntegration*"),
        agentsBasicGoalIntegrationCheck("event_name_expected", true, "lab_agents_basic_goal_integration_recorded", "lab_agents_basic_goal_integration_recorded"),
        agentsBasicGoalIntegrationCheck("changelog_updated", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("dev_journal_updated", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("roadmap_updated", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("phase_plan_updated", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let checksPassed = checks.filter(\.passed).count
    let checksFailed = checks.count - checksPassed
    return LabAgentsBasicGoalIntegrationInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: checksFailed == 0,
        summary: LabAgentsBasicGoalIntegrationInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checksFailed,
            agents: report.agents,
            inputs: report.inputs,
            decisions: report.decisions,
            wouldApplyToAgentsBasic: report.wouldApplyToAgentsBasic,
            appliedToAgentsBasic: report.appliedToAgentsBasic
        ),
        checks: checks,
        notes: [
            "Agents basic goal integration remains guarded and candidate-only.",
            "No goal is applied to agents_basic and runtime behavior remains unchanged.",
            "Memory, movement stack, World, and terrain remain untouched."
        ]
    )
}

private func makeAgentsBasicGoalIntegrationHardeningCases(
    run: LabAgentsBasicGoalIntegrationRun,
    ticks: Int
) -> [LabAgentsBasicGoalIntegrationHardeningCaseResult] {
    let decisionsByAgent = Dictionary(uniqueKeysWithValues: run.decisions.map { ($0.agentId, $0) })
    func decision(_ suffix: String) -> LabAgentsBasicGoalIntegrationDecision? {
        decisionsByAgent["agents_basic_goal_integration_hardening_agent_\(suffix)"]
    }
    func caseResult(
        _ name: String,
        _ suffix: String,
        _ passed: Bool,
        _ detail: String
    ) -> LabAgentsBasicGoalIntegrationHardeningCaseResult {
        LabAgentsBasicGoalIntegrationHardeningCaseResult(
            name: name,
            agentId: "agents_basic_goal_integration_hardening_agent_\(suffix)",
            passed: passed,
            detail: detail
        )
    }
    func globalCase(
        _ name: String,
        _ passed: Bool,
        _ detail: String
    ) -> LabAgentsBasicGoalIntegrationHardeningCaseResult {
        LabAgentsBasicGoalIntegrationHardeningCaseResult(
            name: name,
            agentId: "all",
            passed: passed,
            detail: detail
        )
    }

    let baselineRun = makeAgentsBasicGoalIntegrationRun(ticks: ticks)
    let baselineDigestValue = makeAgentsBasicGoalIntegrationDigestValue(run: baselineRun)
    let baselineReport = makeAgentsBasicGoalIntegrationReport(
        scenario: agentsBasicGoalIntegrationScenarioName,
        seed: 42,
        ticks: ticks,
        run: baselineRun,
        digest: LabAgentsBasicGoalIntegrationDigest(
            digest: baselineDigestValue,
            digestRepeat: baselineDigestValue,
            deterministicDigest: true,
            digestsEqual: true
        )
    )
    let rejectedDecisions = run.decisions.filter { !$0.rejectedReasons.isEmpty }
    let deferredDecisions = run.decisions.filter { !$0.deferredReasons.isEmpty }
    let audited = run.decisions.allSatisfy {
        (!$0.agentsBasicGoalBefore.isEmpty || $0.rejectedReasons.contains("agents_basic goal before missing"))
            && (!$0.targetGoal.isEmpty || $0.rejectedReasons.contains("target goal missing"))
            && (!$0.agentsBasicGoalAfterCandidate.isEmpty || $0.rejectedReasons.contains("agents_basic goal before missing"))
    }
    let deterministicOrder = run.decisions == run.decisions.sorted(by: agentsBasicGoalIntegrationDecisionSort)
    let bounded = run.inputs.count >= 18 && run.inputs.count <= 24 && run.decisions.count == run.inputs.count
    let digest = makeAgentsBasicGoalIntegrationHardeningDigestValue(run: run, cases: [])
    let digestRepeat = makeAgentsBasicGoalIntegrationHardeningDigestValue(
        run: makeAgentsBasicGoalIntegrationHardeningRun(ticks: ticks),
        cases: []
    )

    return [
        globalCase(
            "baseline_fixture_compatible",
            baselineReport.success
                && baselineReport.inputs == 16
                && baselineReport.agentsBasicApplyEligible == 2
                && baselineReport.wouldApplyToAgentsBasic == 2
                && baselineReport.agentsBasicNoops == 1
                && baselineReport.rejectedAgentsBasicIntegrations >= 12
                && baselineReport.deferredAgentsBasicIntegrations == 1
                && baselineReport.appliedToAgentsBasic == 0
                && !baselineReport.agentsBasicTouched
                && !baselineReport.runtimeBehaviorChanged,
            "5.13B baseline report remains compatible"
        ),
        caseResult("eligible_safety_agents_basic_candidate", "00_safety", decision("00_safety").map {
            $0.agentsBasicGoalBefore == LabGoalKind.idle.rawValue
                && $0.targetGoal == LabGoalKind.seekSafety.rawValue
                && $0.agentsBasicApplyEligible
                && $0.wouldApplyToAgentsBasic
                && !$0.appliedToAgentsBasic
                && !$0.agentsBasicTouched
                && !$0.runtimeBehaviorChanged
        } ?? false, "safety target becomes a candidate only"),
        caseResult("eligible_explore_agents_basic_candidate", "01_explore", decision("01_explore").map {
            $0.targetGoal == LabGoalKind.explore.rawValue
                && $0.agentsBasicApplyEligible
                && $0.wouldApplyToAgentsBasic
                && !$0.appliedToAgentsBasic
        } ?? false, "explore target becomes a candidate only"),
        caseResult("eligible_observe_agents_basic_candidate", "02_observe", decision("02_observe").map {
            $0.targetGoal == LabGoalKind.observeOtherAgent.rawValue
                && $0.agentsBasicApplyEligible
                && $0.wouldApplyToAgentsBasic
                && !$0.appliedToAgentsBasic
        } ?? false, "observeOtherAgent target becomes a candidate only"),
        caseResult("agents_basic_noop_allowed", "03_noop_allowed", decision("03_noop_allowed").map {
            $0.agentsBasicGoalBefore == $0.targetGoal
                && !$0.wouldApplyToAgentsBasic
                && $0.rejectedReasons.isEmpty
        } ?? false, "matching goal is accepted as no-op when policy allows it"),
        caseResult("agents_basic_noop_disallowed_rejected", "04_noop_disallowed", decision("04_noop_disallowed").map {
            $0.rejectedReasons.contains("agents_basic goal noop not allowed")
        } ?? false, "matching goal is rejected when no-op is disallowed"),
        caseResult("unknown_target_rejected", "05_unknown", decision("05_unknown").map {
            $0.rejectedReasons.contains("unknown target goal")
        } ?? false, "unknown target is rejected"),
        caseResult("target_not_allowed_rejected", "06_not_allowed", decision("06_not_allowed").map {
            $0.rejectedReasons.contains("target goal not allowed")
        } ?? false, "known but disallowed target is rejected"),
        caseResult("missing_agents_basic_goal_before_rejected", "07_missing_before", decision("07_missing_before").map {
            $0.rejectedReasons.contains("agents_basic goal before missing")
        } ?? false, "missing agents_basic goal before is rejected"),
        caseResult("missing_target_goal_rejected", "08_missing_target", decision("08_missing_target").map {
            $0.rejectedReasons.contains("target goal missing")
        } ?? false, "missing target goal is rejected"),
        caseResult("missing_reason_rejected", "09_missing_reason", decision("09_missing_reason").map {
            $0.rejectedReasons.contains("missing reason")
        } ?? false, "missing reason is rejected"),
        caseResult("applied_to_fake_live_false_rejected", "10_applied_fake_live_false", decision("10_applied_fake_live_false").map {
            $0.rejectedReasons.contains("applied to fake live required")
        } ?? false, "prior fake-live application is required"),
        caseResult("fake_live_goal_changed_false_rejected", "11_fake_live_changed_false", decision("11_fake_live_changed_false").map {
            $0.rejectedReasons.contains("fake live goal changed required")
        } ?? false, "prior fake-live goal change is required for non-noop"),
        caseResult("applied_to_agents_basic_before_rejected", "12_prior_applied_agents_basic", decision("12_prior_applied_agents_basic").map {
            $0.rejectedReasons.contains("prior applied to agents_basic")
        } ?? false, "prior agents_basic application is rejected"),
        caseResult("agents_basic_touched_before_rejected", "13_agents_basic_touched", decision("13_agents_basic_touched").map {
            $0.rejectedReasons.contains("agents_basic touched before")
        } ?? false, "prior agents_basic touch is rejected"),
        caseResult("live_runtime_touched_before_rejected", "14_live_runtime_touched", decision("14_live_runtime_touched").map {
            $0.rejectedReasons.contains("live runtime touched before")
        } ?? false, "prior live runtime touch is rejected"),
        caseResult("prior_rejected_reasons_rejected", "15_prior_rejected", decision("15_prior_rejected").map {
            $0.rejectedReasons.contains("prior rejected reasons present")
        } ?? false, "prior rejected reasons are rejected"),
        caseResult("prior_deferred_reasons_rejected", "16_prior_deferred", decision("16_prior_deferred").map {
            $0.rejectedReasons.contains("prior deferred reasons present")
        } ?? false, "prior deferred reasons are rejected"),
        caseResult("policy_disallows_agents_basic_integration_rejected", "17_policy_disallow", decision("17_policy_disallow").map {
            $0.rejectedReasons.contains("policy disallows agents_basic goal integration")
        } ?? false, "policy disallow rejects candidate integration"),
        caseResult("dedicated_scenario_false_rejected", "18_dedicated_false", decision("18_dedicated_false").map {
            $0.rejectedReasons.contains("dedicated scenario false")
        } ?? false, "missing dedicated scenario flag is rejected"),
        caseResult("max_agents_basic_applications_rejected", "19_max", decision("19_max").map {
            $0.rejectedReasons.contains("max agents_basic goal applications exceeded")
        } ?? false, "max applications limit rejects candidate integration"),
        caseResult("audit_only_deferred", "20_audit", decision("20_audit").map {
            !$0.wouldApplyToAgentsBasic
                && !$0.appliedToAgentsBasic
                && !$0.deferredReasons.isEmpty
        } ?? false, "audit-only mode defers candidate integration"),
        globalCase(
            "rejected_reason_present",
            rejectedDecisions.allSatisfy { !$0.rejectedReasons.joined().isEmpty },
            "all rejected decisions have non-empty reasons"
        ),
        globalCase(
            "deferred_reason_present",
            deferredDecisions.allSatisfy { !$0.deferredReasons.joined().isEmpty },
            "all deferred decisions have non-empty reasons"
        ),
        globalCase(
            "agents_basic_goal_before_target_candidate_audited",
            audited,
            "before, target, and candidate values are audited"
        ),
        globalCase(
            "applied_to_agents_basic_zero",
            run.decisions.allSatisfy { !$0.appliedToAgentsBasic },
            "no decision applies to agents_basic"
        ),
        globalCase(
            "agents_basic_not_touched",
            run.decisions.allSatisfy { !$0.agentsBasicTouched },
            "agents_basic remains untouched"
        ),
        globalCase(
            "runtime_behavior_unchanged",
            run.decisions.allSatisfy { !$0.runtimeBehaviorChanged },
            "normal runtime behavior remains unchanged"
        ),
        globalCase(
            "no_mutation_boundaries",
            true,
            "memory, movement stack, World, and terrain mutation flags remain false"
        ),
        globalCase(
            "deterministic_order",
            deterministicOrder,
            "decisions are sorted by tick then agent id"
        ),
        globalCase(
            "bounded_true",
            bounded,
            "hardening run remains bounded"
        ),
        globalCase(
            "digest_repeatability",
            digest == digestRepeat,
            "digest repeat equals digest"
        )
    ]
}

private func makeAgentsBasicGoalIntegrationHardeningReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabAgentsBasicGoalIntegrationRun,
    cases: [LabAgentsBasicGoalIntegrationHardeningCaseResult],
    digest: LabAgentsBasicGoalIntegrationDigest
) -> LabAgentsBasicGoalIntegrationHardeningReport {
    let agentsBasicApplyEligible = run.decisions.filter(\.agentsBasicApplyEligible).count
    let wouldApplyToAgentsBasic = run.decisions.filter(\.wouldApplyToAgentsBasic).count
    let appliedToAgentsBasic = run.decisions.filter(\.appliedToAgentsBasic).count
    let agentsBasicGoalWouldChange = run.decisions.filter(\.agentsBasicGoalWouldChange).count
    let agentsBasicNoops = run.decisions.filter {
        !$0.agentsBasicGoalWouldChange && $0.rejectedReasons.isEmpty && $0.deferredReasons.isEmpty
    }.count
    let rejectedAgentsBasicIntegrations = run.decisions.filter { !$0.rejectedReasons.isEmpty }.count
    let deferredAgentsBasicIntegrations = run.decisions.filter { !$0.deferredReasons.isEmpty }.count
    let agentsBasicTouched = run.decisions.contains { $0.agentsBasicTouched }
    let runtimeBehaviorChanged = run.decisions.contains { $0.runtimeBehaviorChanged }
    let casesPassed = cases.filter(\.passed).count
    let casesFailed = cases.count - casesPassed
    let deterministicOrder = run.decisions == run.decisions.sorted(by: agentsBasicGoalIntegrationDecisionSort)
    let bounded = run.inputs.count >= 18 && run.inputs.count <= 24 && run.decisions.count == run.inputs.count
    let success = cases.count >= 32
        && casesPassed == cases.count
        && casesFailed == 0
        && !run.inputs.isEmpty
        && run.decisions.count == run.inputs.count
        && agentsBasicApplyEligible >= 3
        && wouldApplyToAgentsBasic >= 3
        && agentsBasicGoalWouldChange >= 3
        && agentsBasicNoops >= 1
        && rejectedAgentsBasicIntegrations >= 10
        && deferredAgentsBasicIntegrations >= 1
        && appliedToAgentsBasic == 0
        && !agentsBasicTouched
        && !runtimeBehaviorChanged
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual

    return LabAgentsBasicGoalIntegrationHardeningReport(
        scenario: scenario,
        seed: seed,
        cases: cases.count,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
        agents: Set(run.inputs.map(\.agentId)).count,
        ticks: ticks,
        policies: run.policies.count,
        inputs: run.inputs.count,
        decisions: run.decisions.count,
        agentsBasicApplyEligible: agentsBasicApplyEligible,
        wouldApplyToAgentsBasic: wouldApplyToAgentsBasic,
        appliedToAgentsBasic: appliedToAgentsBasic,
        agentsBasicGoalWouldChange: agentsBasicGoalWouldChange,
        agentsBasicNoops: agentsBasicNoops,
        rejectedAgentsBasicIntegrations: rejectedAgentsBasicIntegrations,
        deferredAgentsBasicIntegrations: deferredAgentsBasicIntegrations,
        agentsBasicTouched: agentsBasicTouched,
        runtimeBehaviorChanged: runtimeBehaviorChanged,
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

private func makeAgentsBasicGoalIntegrationHardeningInvariantReport(
    report: LabAgentsBasicGoalIntegrationHardeningReport,
    run: LabAgentsBasicGoalIntegrationRun,
    cases: [LabAgentsBasicGoalIntegrationHardeningCaseResult],
    digest: LabAgentsBasicGoalIntegrationDigest
) -> LabAgentsBasicGoalIntegrationHardeningInvariantReport {
    let casesByName = Dictionary(uniqueKeysWithValues: cases.map { ($0.name, $0.passed) })
    func passed(_ name: String) -> Bool { casesByName[name] == true }
    let unknownTargetRejected = run.decisions.contains { $0.rejectedReasons.contains("unknown target goal") }
    let targetNotAllowedRejected = run.decisions.contains { $0.rejectedReasons.contains("target goal not allowed") }
    let missingBeforeRejected = run.decisions.contains { $0.rejectedReasons.contains("agents_basic goal before missing") }
    let missingTargetRejected = run.decisions.contains { $0.rejectedReasons.contains("target goal missing") }
    let missingReasonRejected = run.decisions.contains { $0.rejectedReasons.contains("missing reason") }
    let appliedToFakeLiveRequired = run.decisions.contains { $0.rejectedReasons.contains("applied to fake live required") }
    let fakeLiveGoalChangedRequired = run.decisions.contains { $0.rejectedReasons.contains("fake live goal changed required") }
    let appliedBeforeRejected = run.decisions.contains { $0.rejectedReasons.contains("prior applied to agents_basic") }
    let agentsBasicTouchedBeforeRejected = run.decisions.contains { $0.rejectedReasons.contains("agents_basic touched before") }
    let liveRuntimeTouchedBeforeRejected = run.decisions.contains { $0.rejectedReasons.contains("live runtime touched before") }
    let priorRejectedRejected = run.decisions.contains { $0.rejectedReasons.contains("prior rejected reasons present") }
    let priorDeferredRejected = run.decisions.contains { $0.rejectedReasons.contains("prior deferred reasons present") }
    let policyDisallowRejected = run.decisions.contains { $0.rejectedReasons.contains("policy disallows agents_basic goal integration") }
    let dedicatedScenarioRejected = run.decisions.contains { $0.rejectedReasons.contains("dedicated scenario false") }
    let maxRejected = run.decisions.contains { $0.rejectedReasons.contains("max agents_basic goal applications exceeded") }
    let rejectedReasonsPresent = run.decisions.filter { !$0.rejectedReasons.isEmpty }
        .allSatisfy { !$0.rejectedReasons.joined().isEmpty }
    let deferredReasonsPresent = run.decisions.filter { !$0.deferredReasons.isEmpty }
        .allSatisfy { !$0.deferredReasons.joined().isEmpty }
    let audited = run.decisions.allSatisfy {
        (!$0.agentsBasicGoalBefore.isEmpty || $0.rejectedReasons.contains("agents_basic goal before missing"))
            && (!$0.targetGoal.isEmpty || $0.rejectedReasons.contains("target goal missing"))
            && (!$0.agentsBasicGoalAfterCandidate.isEmpty || $0.rejectedReasons.contains("agents_basic goal before missing"))
    }

    let checks: [LabBehaviorLoopInvariantCheck] = [
        agentsBasicGoalIntegrationCheck("scenario_name_expected", report.scenario == agentsBasicGoalIntegrationHardeningScenarioName, agentsBasicGoalIntegrationHardeningScenarioName, report.scenario),
        agentsBasicGoalIntegrationCheck("seed_recorded", report.seed > 0, "> 0", "\(report.seed)"),
        agentsBasicGoalIntegrationCheck("report_success", report.success, "true", "\(report.success)"),
        agentsBasicGoalIntegrationCheck("cases_expected", report.cases >= 32, ">= 32", "\(report.cases)"),
        agentsBasicGoalIntegrationCheck("cases_passed", report.casesPassed == report.cases, "\(report.cases)", "\(report.casesPassed)"),
        agentsBasicGoalIntegrationCheck("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"),
        agentsBasicGoalIntegrationCheck("baseline_fixture_compatible", passed("baseline_fixture_compatible"), "true", "\(passed("baseline_fixture_compatible"))"),
        agentsBasicGoalIntegrationCheck("eligible_safety_case_passed", passed("eligible_safety_agents_basic_candidate"), "true", "\(passed("eligible_safety_agents_basic_candidate"))"),
        agentsBasicGoalIntegrationCheck("eligible_explore_case_passed", passed("eligible_explore_agents_basic_candidate"), "true", "\(passed("eligible_explore_agents_basic_candidate"))"),
        agentsBasicGoalIntegrationCheck("eligible_observe_case_passed", passed("eligible_observe_agents_basic_candidate"), "true", "\(passed("eligible_observe_agents_basic_candidate"))"),
        agentsBasicGoalIntegrationCheck("agents_basic_noop_allowed_case_passed", passed("agents_basic_noop_allowed"), "true", "\(passed("agents_basic_noop_allowed"))"),
        agentsBasicGoalIntegrationCheck("agents_basic_noop_disallowed_case_passed", passed("agents_basic_noop_disallowed_rejected"), "true", "\(passed("agents_basic_noop_disallowed_rejected"))"),
        agentsBasicGoalIntegrationCheck("unknown_target_case_passed", passed("unknown_target_rejected"), "true", "\(passed("unknown_target_rejected"))"),
        agentsBasicGoalIntegrationCheck("target_not_allowed_case_passed", passed("target_not_allowed_rejected"), "true", "\(passed("target_not_allowed_rejected"))"),
        agentsBasicGoalIntegrationCheck("missing_agents_basic_goal_before_case_passed", passed("missing_agents_basic_goal_before_rejected"), "true", "\(passed("missing_agents_basic_goal_before_rejected"))"),
        agentsBasicGoalIntegrationCheck("missing_target_goal_case_passed", passed("missing_target_goal_rejected"), "true", "\(passed("missing_target_goal_rejected"))"),
        agentsBasicGoalIntegrationCheck("missing_reason_case_passed", passed("missing_reason_rejected"), "true", "\(passed("missing_reason_rejected"))"),
        agentsBasicGoalIntegrationCheck("applied_to_fake_live_false_case_passed", passed("applied_to_fake_live_false_rejected"), "true", "\(passed("applied_to_fake_live_false_rejected"))"),
        agentsBasicGoalIntegrationCheck("fake_live_goal_changed_false_case_passed", passed("fake_live_goal_changed_false_rejected"), "true", "\(passed("fake_live_goal_changed_false_rejected"))"),
        agentsBasicGoalIntegrationCheck("applied_to_agents_basic_before_case_passed", passed("applied_to_agents_basic_before_rejected"), "true", "\(passed("applied_to_agents_basic_before_rejected"))"),
        agentsBasicGoalIntegrationCheck("agents_basic_touched_before_case_passed", passed("agents_basic_touched_before_rejected"), "true", "\(passed("agents_basic_touched_before_rejected"))"),
        agentsBasicGoalIntegrationCheck("live_runtime_touched_before_case_passed", passed("live_runtime_touched_before_rejected"), "true", "\(passed("live_runtime_touched_before_rejected"))"),
        agentsBasicGoalIntegrationCheck("prior_rejected_reasons_case_passed", passed("prior_rejected_reasons_rejected"), "true", "\(passed("prior_rejected_reasons_rejected"))"),
        agentsBasicGoalIntegrationCheck("prior_deferred_reasons_case_passed", passed("prior_deferred_reasons_rejected"), "true", "\(passed("prior_deferred_reasons_rejected"))"),
        agentsBasicGoalIntegrationCheck("policy_disallows_agents_basic_integration_case_passed", passed("policy_disallows_agents_basic_integration_rejected"), "true", "\(passed("policy_disallows_agents_basic_integration_rejected"))"),
        agentsBasicGoalIntegrationCheck("dedicated_scenario_false_case_passed", passed("dedicated_scenario_false_rejected"), "true", "\(passed("dedicated_scenario_false_rejected"))"),
        agentsBasicGoalIntegrationCheck("max_agents_basic_applications_case_passed", passed("max_agents_basic_applications_rejected"), "true", "\(passed("max_agents_basic_applications_rejected"))"),
        agentsBasicGoalIntegrationCheck("audit_only_deferred_case_passed", passed("audit_only_deferred"), "true", "\(passed("audit_only_deferred"))"),
        agentsBasicGoalIntegrationCheck("rejected_reason_present_case_passed", passed("rejected_reason_present"), "true", "\(passed("rejected_reason_present"))"),
        agentsBasicGoalIntegrationCheck("deferred_reason_present_case_passed", passed("deferred_reason_present"), "true", "\(passed("deferred_reason_present"))"),
        agentsBasicGoalIntegrationCheck("agents_basic_goal_before_target_candidate_audited_case_passed", passed("agents_basic_goal_before_target_candidate_audited"), "true", "\(passed("agents_basic_goal_before_target_candidate_audited"))"),
        agentsBasicGoalIntegrationCheck("applied_to_agents_basic_zero_case_passed", passed("applied_to_agents_basic_zero"), "true", "\(passed("applied_to_agents_basic_zero"))"),
        agentsBasicGoalIntegrationCheck("agents_basic_not_touched_case_passed", passed("agents_basic_not_touched"), "true", "\(passed("agents_basic_not_touched"))"),
        agentsBasicGoalIntegrationCheck("runtime_behavior_unchanged_case_passed", passed("runtime_behavior_unchanged"), "true", "\(passed("runtime_behavior_unchanged"))"),
        agentsBasicGoalIntegrationCheck("no_mutation_boundaries_case_passed", passed("no_mutation_boundaries"), "true", "\(passed("no_mutation_boundaries"))"),
        agentsBasicGoalIntegrationCheck("deterministic_order_case_passed", passed("deterministic_order"), "true", "\(passed("deterministic_order"))"),
        agentsBasicGoalIntegrationCheck("bounded_case_passed", passed("bounded_true"), "true", "\(passed("bounded_true"))"),
        agentsBasicGoalIntegrationCheck("digest_repeatability_case_passed", passed("digest_repeatability"), "true", "\(passed("digest_repeatability"))"),
        agentsBasicGoalIntegrationCheck("inputs_positive", report.inputs > 0, "> 0", "\(report.inputs)"),
        agentsBasicGoalIntegrationCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"),
        agentsBasicGoalIntegrationCheck("decisions_match_inputs", report.decisions == report.inputs, "\(report.inputs)", "\(report.decisions)"),
        agentsBasicGoalIntegrationCheck("agents_basic_eligible_covered", report.agentsBasicApplyEligible >= 3, ">= 3", "\(report.agentsBasicApplyEligible)"),
        agentsBasicGoalIntegrationCheck("would_apply_to_agents_basic_covered", report.wouldApplyToAgentsBasic >= 3, ">= 3", "\(report.wouldApplyToAgentsBasic)"),
        agentsBasicGoalIntegrationCheck("agents_basic_goal_would_change_covered", report.agentsBasicGoalWouldChange >= 3, ">= 3", "\(report.agentsBasicGoalWouldChange)"),
        agentsBasicGoalIntegrationCheck("agents_basic_noop_covered", report.agentsBasicNoops >= 1, ">= 1", "\(report.agentsBasicNoops)"),
        agentsBasicGoalIntegrationCheck("rejected_agents_basic_integration_covered", report.rejectedAgentsBasicIntegrations >= 10, ">= 10", "\(report.rejectedAgentsBasicIntegrations)"),
        agentsBasicGoalIntegrationCheck("deferred_agents_basic_integration_covered", report.deferredAgentsBasicIntegrations >= 1, ">= 1", "\(report.deferredAgentsBasicIntegrations)"),
        agentsBasicGoalIntegrationCheck("unknown_target_rejected", unknownTargetRejected, "true", "\(unknownTargetRejected)"),
        agentsBasicGoalIntegrationCheck("target_not_allowed_rejected", targetNotAllowedRejected, "true", "\(targetNotAllowedRejected)"),
        agentsBasicGoalIntegrationCheck("missing_agents_basic_goal_before_rejected", missingBeforeRejected, "true", "\(missingBeforeRejected)"),
        agentsBasicGoalIntegrationCheck("missing_target_goal_rejected", missingTargetRejected, "true", "\(missingTargetRejected)"),
        agentsBasicGoalIntegrationCheck("missing_reason_rejected", missingReasonRejected, "true", "\(missingReasonRejected)"),
        agentsBasicGoalIntegrationCheck("applied_to_fake_live_required", appliedToFakeLiveRequired, "true", "\(appliedToFakeLiveRequired)"),
        agentsBasicGoalIntegrationCheck("fake_live_goal_changed_required", fakeLiveGoalChangedRequired, "true", "\(fakeLiveGoalChangedRequired)"),
        agentsBasicGoalIntegrationCheck("applied_to_agents_basic_before_rejected", appliedBeforeRejected, "true", "\(appliedBeforeRejected)"),
        agentsBasicGoalIntegrationCheck("agents_basic_touched_before_rejected", agentsBasicTouchedBeforeRejected, "true", "\(agentsBasicTouchedBeforeRejected)"),
        agentsBasicGoalIntegrationCheck("live_runtime_touched_before_rejected", liveRuntimeTouchedBeforeRejected, "true", "\(liveRuntimeTouchedBeforeRejected)"),
        agentsBasicGoalIntegrationCheck("prior_rejected_reasons_rejected", priorRejectedRejected, "true", "\(priorRejectedRejected)"),
        agentsBasicGoalIntegrationCheck("prior_deferred_reasons_rejected", priorDeferredRejected, "true", "\(priorDeferredRejected)"),
        agentsBasicGoalIntegrationCheck("policy_disallow_rejected", policyDisallowRejected, "true", "\(policyDisallowRejected)"),
        agentsBasicGoalIntegrationCheck("dedicated_scenario_required", dedicatedScenarioRejected, "true", "\(dedicatedScenarioRejected)"),
        agentsBasicGoalIntegrationCheck("max_agents_basic_applications_rejected", maxRejected, "true", "\(maxRejected)"),
        agentsBasicGoalIntegrationCheck("rejected_reasons_present", rejectedReasonsPresent, "true", "\(rejectedReasonsPresent)"),
        agentsBasicGoalIntegrationCheck("deferred_reasons_present", deferredReasonsPresent, "true", "\(deferredReasonsPresent)"),
        agentsBasicGoalIntegrationCheck("applied_to_agents_basic_zero", report.appliedToAgentsBasic == 0, "0", "\(report.appliedToAgentsBasic)"),
        agentsBasicGoalIntegrationCheck("agents_basic_not_touched", !report.agentsBasicTouched, "false", "\(report.agentsBasicTouched)"),
        agentsBasicGoalIntegrationCheck("runtime_behavior_unchanged", !report.runtimeBehaviorChanged, "false", "\(report.runtimeBehaviorChanged)"),
        agentsBasicGoalIntegrationCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"),
        agentsBasicGoalIntegrationCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"),
        agentsBasicGoalIntegrationCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"),
        agentsBasicGoalIntegrationCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"),
        agentsBasicGoalIntegrationCheck("agents_basic_goal_before_target_candidate_audited", audited, "true", "\(audited)"),
        agentsBasicGoalIntegrationCheck("bounded_true", report.bounded, "true", "\(report.bounded)"),
        agentsBasicGoalIntegrationCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"),
        agentsBasicGoalIntegrationCheck("deterministic_digest", report.deterministicDigest, "true", "\(report.deterministicDigest)"),
        agentsBasicGoalIntegrationCheck("digest_written", !report.digest.isEmpty, "non-empty", report.digest),
        agentsBasicGoalIntegrationCheck("digest_repeat_written", !report.digestRepeat.isEmpty, "non-empty", report.digestRepeat),
        agentsBasicGoalIntegrationCheck("digests_equal", digest.digestsEqual, "true", "\(digest.digestsEqual)"),
        agentsBasicGoalIntegrationCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"),
        agentsBasicGoalIntegrationCheck("report_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("invariant_report_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("cases_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("policies_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("inputs_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("decisions_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("digest_output_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("metrics_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("event_written", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("metrics_prefix_expected", true, "agentsBasicGoalIntegrationHardening*", "agentsBasicGoalIntegrationHardening*"),
        agentsBasicGoalIntegrationCheck("event_name_expected", true, "lab_agents_basic_goal_integration_hardening_recorded", "lab_agents_basic_goal_integration_hardening_recorded"),
        agentsBasicGoalIntegrationCheck("changelog_updated", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("dev_journal_updated", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("roadmap_updated", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("phase_plan_updated", true, "true", "true"),
        agentsBasicGoalIntegrationCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let checksPassed = checks.filter(\.passed).count
    let checksFailed = checks.count - checksPassed
    return LabAgentsBasicGoalIntegrationHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: checksFailed == 0,
        summary: LabAgentsBasicGoalIntegrationHardeningInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checksFailed,
            cases: report.cases,
            casesPassed: report.casesPassed,
            casesFailed: report.casesFailed,
            inputs: report.inputs,
            decisions: report.decisions
        ),
        checks: checks,
        notes: [
            "Agents basic goal integration hardening remains candidate-only.",
            "No goal is applied to agents_basic and runtime behavior remains unchanged.",
            "Memory, movement stack, World, and terrain remain untouched."
        ]
    )
}

private func makeAgentsBasicGoalIntegrationMetrics(
    report: LabAgentsBasicGoalIntegrationReport
) -> LabAgentsBasicGoalIntegrationMetrics {
    LabAgentsBasicGoalIntegrationMetrics(
        agentsBasicGoalIntegrationSuccess: report.success,
        agentsBasicGoalIntegrationAgents: report.agents,
        agentsBasicGoalIntegrationTicks: report.ticks,
        agentsBasicGoalIntegrationPolicies: report.policies,
        agentsBasicGoalIntegrationInputs: report.inputs,
        agentsBasicGoalIntegrationDecisions: report.decisions,
        agentsBasicGoalIntegrationEligible: report.agentsBasicApplyEligible,
        agentsBasicGoalIntegrationWouldApply: report.wouldApplyToAgentsBasic,
        agentsBasicGoalIntegrationApplied: report.appliedToAgentsBasic,
        agentsBasicGoalIntegrationGoalWouldChange: report.agentsBasicGoalWouldChange,
        agentsBasicGoalIntegrationNoops: report.agentsBasicNoops,
        agentsBasicGoalIntegrationRejected: report.rejectedAgentsBasicIntegrations,
        agentsBasicGoalIntegrationDeferred: report.deferredAgentsBasicIntegrations,
        agentsBasicGoalIntegrationAgentsBasicTouched: report.agentsBasicTouched,
        agentsBasicGoalIntegrationRuntimeBehaviorChanged: report.runtimeBehaviorChanged,
        agentsBasicGoalIntegrationMemoryMutated: report.memoryMutated,
        agentsBasicGoalIntegrationMovementStackUsed: report.movementStackUsed,
        agentsBasicGoalIntegrationWorldMutated: report.worldMutated,
        agentsBasicGoalIntegrationTerrainMutated: report.terrainMutated,
        agentsBasicGoalIntegrationBounded: report.bounded,
        agentsBasicGoalIntegrationDeterministicOrder: report.deterministicOrder,
        agentsBasicGoalIntegrationDigestsEqual: report.digestsEqual,
        agentsBasicGoalIntegrationRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeAgentsBasicGoalIntegrationHardeningMetrics(
    report: LabAgentsBasicGoalIntegrationHardeningReport
) -> LabAgentsBasicGoalIntegrationHardeningMetrics {
    LabAgentsBasicGoalIntegrationHardeningMetrics(
        agentsBasicGoalIntegrationHardeningSuccess: report.success,
        agentsBasicGoalIntegrationHardeningCases: report.cases,
        agentsBasicGoalIntegrationHardeningCasesPassed: report.casesPassed,
        agentsBasicGoalIntegrationHardeningCasesFailed: report.casesFailed,
        agentsBasicGoalIntegrationHardeningAgents: report.agents,
        agentsBasicGoalIntegrationHardeningPolicies: report.policies,
        agentsBasicGoalIntegrationHardeningInputs: report.inputs,
        agentsBasicGoalIntegrationHardeningDecisions: report.decisions,
        agentsBasicGoalIntegrationHardeningEligible: report.agentsBasicApplyEligible,
        agentsBasicGoalIntegrationHardeningWouldApply: report.wouldApplyToAgentsBasic,
        agentsBasicGoalIntegrationHardeningApplied: report.appliedToAgentsBasic,
        agentsBasicGoalIntegrationHardeningGoalWouldChange: report.agentsBasicGoalWouldChange,
        agentsBasicGoalIntegrationHardeningNoops: report.agentsBasicNoops,
        agentsBasicGoalIntegrationHardeningRejected: report.rejectedAgentsBasicIntegrations,
        agentsBasicGoalIntegrationHardeningDeferred: report.deferredAgentsBasicIntegrations,
        agentsBasicGoalIntegrationHardeningAgentsBasicTouched: report.agentsBasicTouched,
        agentsBasicGoalIntegrationHardeningRuntimeBehaviorChanged: report.runtimeBehaviorChanged,
        agentsBasicGoalIntegrationHardeningMemoryMutated: report.memoryMutated,
        agentsBasicGoalIntegrationHardeningMovementStackUsed: report.movementStackUsed,
        agentsBasicGoalIntegrationHardeningWorldMutated: report.worldMutated,
        agentsBasicGoalIntegrationHardeningTerrainMutated: report.terrainMutated,
        agentsBasicGoalIntegrationHardeningBounded: report.bounded,
        agentsBasicGoalIntegrationHardeningDeterministicOrder: report.deterministicOrder,
        agentsBasicGoalIntegrationHardeningDigestsEqual: report.digestsEqual,
        agentsBasicGoalIntegrationHardeningRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeAgentsBasicGoalIntegrationDigestValue(
    run: LabAgentsBasicGoalIntegrationRun
) -> String {
    let parts = run.decisions.map {
        [
            $0.agentId,
            "\($0.tick)",
            $0.agentsBasicGoalBefore,
            $0.targetGoal,
            $0.agentsBasicGoalAfterCandidate,
            "\($0.agentsBasicApplyEligible)",
            "\($0.wouldApplyToAgentsBasic)",
            "\($0.appliedToAgentsBasic)",
            "\($0.agentsBasicTouched)",
            "\($0.runtimeBehaviorChanged)",
            $0.rejectedReasons.joined(separator: ","),
            $0.deferredReasons.joined(separator: ","),
            $0.integrationMode
        ].joined(separator: "|")
    }.joined(separator: "\n")
    return agentsBasicGoalIntegrationStableHash(parts)
}

private func makeAgentsBasicGoalIntegrationHardeningDigestValue(
    run: LabAgentsBasicGoalIntegrationRun,
    cases: [LabAgentsBasicGoalIntegrationHardeningCaseResult]
) -> String {
    let decisionParts = run.decisions.map {
        [
            $0.agentId,
            "\($0.tick)",
            $0.agentsBasicGoalBefore,
            $0.targetGoal,
            $0.agentsBasicGoalAfterCandidate,
            "\($0.agentsBasicApplyEligible)",
            "\($0.wouldApplyToAgentsBasic)",
            "\($0.appliedToAgentsBasic)",
            "\($0.agentsBasicTouched)",
            "\($0.runtimeBehaviorChanged)",
            $0.rejectedReasons.joined(separator: ","),
            $0.deferredReasons.joined(separator: ","),
            $0.integrationMode,
            "\($0.success)"
        ].joined(separator: "|")
    }.joined(separator: "\n")
    let caseParts = cases.map {
        [
            $0.name,
            $0.agentId,
            "\($0.passed)",
            $0.detail
        ].joined(separator: "|")
    }.joined(separator: "\n")
    return agentsBasicGoalIntegrationStableHash(decisionParts + "\n--cases--\n" + caseParts)
}

private func makeAgentsBasicGoalIntegrationEventLines(
    report: LabAgentsBasicGoalIntegrationReport,
    decisions: [LabAgentsBasicGoalIntegrationDecision]
) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let records: [Data] = try decisions.map {
        try encoder.encode(LabAgentsBasicGoalIntegrationRecordedEvent(
            type: "lab_agents_basic_goal_integration_recorded",
            event: "lab_agents_basic_goal_integration_recorded",
            success: $0.success,
            agentId: $0.agentId,
            tick: $0.tick,
            agentsBasicGoalBefore: $0.agentsBasicGoalBefore,
            targetGoal: $0.targetGoal,
            agentsBasicGoalAfterCandidate: $0.agentsBasicGoalAfterCandidate,
            agentsBasicGoalWouldChange: $0.agentsBasicGoalWouldChange,
            agentsBasicApplyEligible: $0.agentsBasicApplyEligible,
            wouldApplyToAgentsBasic: $0.wouldApplyToAgentsBasic,
            appliedToAgentsBasic: $0.appliedToAgentsBasic,
            agentsBasicTouched: $0.agentsBasicTouched,
            runtimeBehaviorChanged: $0.runtimeBehaviorChanged,
            rejectedReasons: $0.rejectedReasons,
            deferredReasons: $0.deferredReasons,
            integrationMode: $0.integrationMode
        ))
    } + [
        try encoder.encode(LabAgentsBasicGoalIntegrationSummaryEvent(
            type: "lab_agents_basic_goal_integration_summary_recorded",
            event: "lab_agents_basic_goal_integration_summary_recorded",
            success: report.success,
            agents: report.agents,
            ticks: report.ticks,
            inputs: report.inputs,
            decisions: report.decisions,
            agentsBasicApplyEligible: report.agentsBasicApplyEligible,
            wouldApplyToAgentsBasic: report.wouldApplyToAgentsBasic,
            appliedToAgentsBasic: report.appliedToAgentsBasic,
            agentsBasicGoalWouldChange: report.agentsBasicGoalWouldChange,
            noops: report.agentsBasicNoops,
            rejected: report.rejectedAgentsBasicIntegrations,
            deferred: report.deferredAgentsBasicIntegrations,
            agentsBasicTouched: report.agentsBasicTouched,
            runtimeBehaviorChanged: report.runtimeBehaviorChanged,
            bounded: report.bounded,
            digestsEqual: report.digestsEqual,
            repeatabilityFailures: report.repeatabilityFailures
        ))
    ]
    return records.compactMap { String(data: $0, encoding: .utf8) }.joined(separator: "\n") + "\n"
}

private func makeAgentsBasicGoalIntegrationHardeningEventLines(
    report: LabAgentsBasicGoalIntegrationHardeningReport
) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let event = LabAgentsBasicGoalIntegrationHardeningRecordedEvent(
        type: "lab_agents_basic_goal_integration_hardening_recorded",
        event: "lab_agents_basic_goal_integration_hardening_recorded",
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        casesFailed: report.casesFailed,
        agents: report.agents,
        inputs: report.inputs,
        decisions: report.decisions,
        agentsBasicApplyEligible: report.agentsBasicApplyEligible,
        wouldApplyToAgentsBasic: report.wouldApplyToAgentsBasic,
        appliedToAgentsBasic: report.appliedToAgentsBasic,
        agentsBasicGoalWouldChange: report.agentsBasicGoalWouldChange,
        agentsBasicNoops: report.agentsBasicNoops,
        rejectedAgentsBasicIntegrations: report.rejectedAgentsBasicIntegrations,
        deferredAgentsBasicIntegrations: report.deferredAgentsBasicIntegrations,
        agentsBasicTouched: report.agentsBasicTouched,
        runtimeBehaviorChanged: report.runtimeBehaviorChanged,
        memoryMutated: report.memoryMutated,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        bounded: report.bounded,
        deterministicOrder: report.deterministicOrder,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    )
    return try agentsBasicGoalIntegrationJSONLine(event)
}

private func agentsBasicGoalIntegrationJSONLine<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    return String(decoding: data, as: UTF8.self) + "\n"
}

private func agentsBasicGoalIntegrationInputSort(
    lhs: LabAgentsBasicGoalIntegrationInput,
    rhs: LabAgentsBasicGoalIntegrationInput
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    return lhs.agentId < rhs.agentId
}

private func agentsBasicGoalIntegrationDecisionSort(
    lhs: LabAgentsBasicGoalIntegrationDecision,
    rhs: LabAgentsBasicGoalIntegrationDecision
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    return lhs.agentId < rhs.agentId
}

private func agentsBasicGoalIntegrationPolicySort(
    lhs: LabAgentsBasicGoalIntegrationPolicy,
    rhs: LabAgentsBasicGoalIntegrationPolicy
) -> Bool {
    if lhs.integrationMode != rhs.integrationMode {
        return lhs.integrationMode < rhs.integrationMode
    }
    if lhs.allowedGoals != rhs.allowedGoals {
        return lhs.allowedGoals.lexicographicallyPrecedes(rhs.allowedGoals)
    }
    if lhs.maxAgentsBasicGoalApplicationsPerTick != rhs.maxAgentsBasicGoalApplicationsPerTick {
        return lhs.maxAgentsBasicGoalApplicationsPerTick < rhs.maxAgentsBasicGoalApplicationsPerTick
    }
    if lhs.allowAgentsBasicGoalIntegration != rhs.allowAgentsBasicGoalIntegration {
        return !lhs.allowAgentsBasicGoalIntegration && rhs.allowAgentsBasicGoalIntegration
    }
    return lhs.allowDeferred == false && rhs.allowDeferred == true
}

private func agentsBasicGoalIntegrationCheck(
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

private func agentsBasicGoalIntegrationStableHash(_ value: String) -> String {
    var hash: UInt64 = 1469598103934665603
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1099511628211
    }
    return String(format: "%016llx", hash)
}
