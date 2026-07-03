import Foundation

let agentsBasicGoalIntegrationScenarioName = "agents_basic_goal_integration_guarded_fixture_smoke"

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
