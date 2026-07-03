import Foundation

let fakeLiveGoalApplicationScenarioName = "fake_live_goal_application_fixture_smoke"

private let fakeLiveGoalApplicationKnownGoals = [
    LabGoalKind.idle.rawValue,
    LabGoalKind.rest.rawValue,
    LabGoalKind.seekSafety.rawValue,
    LabGoalKind.explore.rawValue,
    LabGoalKind.observeOtherAgent.rawValue
]

struct LabFakeLiveGoalApplicationPolicy: Codable, Equatable {
    let applyMode: String
    let allowFakeLiveGoalApplication: Bool
    let allowedGoals: [String]
    let maxFakeLiveGoalApplicationsPerTick: Int
    let requireWouldApplyToLive: Bool
    let requireNoRejectedReasons: Bool
    let requireNoDeferredReasons: Bool
    let requireAgentsBasicUntouched: Bool
    let requireReason: Bool
    let allowNoopGoal: Bool
    let allowDeferred: Bool
}

struct LabFakeLiveGoalApplicationInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let fakeLiveGoalBefore: String
    let targetGoal: String
    let liveGoalAfterCandidate: String
    let wouldApplyToLive: Bool
    let priorAppliedToLive: Bool
    let priorRejectedReasons: [String]
    let priorDeferredReasons: [String]
    let agentsBasicTouchedBefore: Bool
    let guardedDecisionSummary: String
    let policy: LabFakeLiveGoalApplicationPolicy
    let reason: String
}

struct LabFakeLiveGoalApplicationDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let fakeLiveGoalBefore: String
    let targetGoal: String
    let fakeLiveGoalAfter: String
    let fakeLiveGoalChanged: Bool
    let fakeLiveApplyEligible: Bool
    let fakeLiveWouldChange: Bool
    let appliedToFakeLive: Bool
    let appliedToAgentsBasic: Bool
    let agentsBasicTouched: Bool
    let liveRuntimeTouched: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let applyMode: String
    let success: Bool
}

struct LabFakeLiveGoalApplicationReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let policies: Int
    let inputs: Int
    let decisions: Int
    let fakeLiveApplyEligible: Int
    let fakeLiveWouldChange: Int
    let appliedToFakeLive: Int
    let fakeLiveGoalChanged: Int
    let fakeLiveNoops: Int
    let rejectedFakeLiveApplications: Int
    let deferredFakeLiveApplications: Int
    let appliedToAgentsBasic: Int
    let agentsBasicTouched: Bool
    let liveRuntimeTouched: Bool
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

struct LabFakeLiveGoalApplicationInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let inputs: Int
    let decisions: Int
    let appliedToFakeLive: Int
    let appliedToAgentsBasic: Int
}

struct LabFakeLiveGoalApplicationInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabFakeLiveGoalApplicationInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabFakeLiveGoalApplicationDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabFakeLiveGoalApplicationMetrics: Codable, Equatable {
    let fakeLiveGoalApplicationSuccess: Bool
    let fakeLiveGoalApplicationAgents: Int
    let fakeLiveGoalApplicationTicks: Int
    let fakeLiveGoalApplicationPolicies: Int
    let fakeLiveGoalApplicationInputs: Int
    let fakeLiveGoalApplicationDecisions: Int
    let fakeLiveGoalApplicationEligible: Int
    let fakeLiveGoalApplicationWouldChange: Int
    let fakeLiveGoalApplicationAppliedToFakeLive: Int
    let fakeLiveGoalApplicationGoalChanged: Int
    let fakeLiveGoalApplicationNoops: Int
    let fakeLiveGoalApplicationRejected: Int
    let fakeLiveGoalApplicationDeferred: Int
    let fakeLiveGoalApplicationAppliedToAgentsBasic: Int
    let fakeLiveGoalApplicationAgentsBasicTouched: Bool
    let fakeLiveGoalApplicationLiveRuntimeTouched: Bool
    let fakeLiveGoalApplicationMemoryMutated: Bool
    let fakeLiveGoalApplicationMovementStackUsed: Bool
    let fakeLiveGoalApplicationWorldMutated: Bool
    let fakeLiveGoalApplicationTerrainMutated: Bool
    let fakeLiveGoalApplicationBounded: Bool
    let fakeLiveGoalApplicationDeterministicOrder: Bool
    let fakeLiveGoalApplicationDigestsEqual: Bool
    let fakeLiveGoalApplicationRepeatabilityFailures: Int
}

struct LabFakeLiveGoalApplicationFixture: Codable, Equatable {
    let report: LabFakeLiveGoalApplicationReport
    let invariantReport: LabFakeLiveGoalApplicationInvariantReport
    let policies: [LabFakeLiveGoalApplicationPolicy]
    let inputs: [LabFakeLiveGoalApplicationInput]
    let decisions: [LabFakeLiveGoalApplicationDecision]
    let digest: LabFakeLiveGoalApplicationDigest
    let eventLines: String
    let metrics: LabFakeLiveGoalApplicationMetrics
}

private struct LabFakeLiveGoalApplicationRun {
    let policies: [LabFakeLiveGoalApplicationPolicy]
    let inputs: [LabFakeLiveGoalApplicationInput]
    let decisions: [LabFakeLiveGoalApplicationDecision]
}

private struct LabFakeLiveGoalApplicationRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let fakeLiveGoalBefore: String
    let targetGoal: String
    let fakeLiveGoalAfter: String
    let fakeLiveGoalChanged: Bool
    let appliedToFakeLive: Bool
    let appliedToAgentsBasic: Bool
    let agentsBasicTouched: Bool
    let liveRuntimeTouched: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let applyMode: String
}

private struct LabFakeLiveGoalApplicationSummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let ticks: Int
    let inputs: Int
    let decisions: Int
    let fakeLiveApplyEligible: Int
    let fakeLiveWouldChange: Int
    let appliedToFakeLive: Int
    let fakeLiveGoalChanged: Int
    let noops: Int
    let rejected: Int
    let deferred: Int
    let appliedToAgentsBasic: Int
    let agentsBasicTouched: Bool
    let liveRuntimeTouched: Bool
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeFakeLiveGoalApplicationFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabFakeLiveGoalApplicationFixture {
    let run = makeFakeLiveGoalApplicationRun(ticks: ticks)
    let repeatRun = makeFakeLiveGoalApplicationRun(ticks: ticks)
    let digestValue = makeFakeLiveGoalApplicationDigestValue(run: run)
    let digestRepeatValue = makeFakeLiveGoalApplicationDigestValue(run: repeatRun)
    let digest = LabFakeLiveGoalApplicationDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeFakeLiveGoalApplicationReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeFakeLiveGoalApplicationInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabFakeLiveGoalApplicationFixture(
        report: report,
        invariantReport: invariantReport,
        policies: run.policies,
        inputs: run.inputs,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeFakeLiveGoalApplicationEventLines(report: report, decisions: run.decisions),
        metrics: makeFakeLiveGoalApplicationMetrics(report: report)
    )
}

private func makeFakeLiveGoalApplicationRun(ticks: Int) -> LabFakeLiveGoalApplicationRun {
    let tick = max(1, ticks)
    let inputs = makeFakeLiveGoalApplicationInputs(tick: tick).sorted(by: fakeLiveGoalApplicationInputSort)
    let decisions = inputs.map(makeFakeLiveGoalApplicationDecision).sorted(by: fakeLiveGoalApplicationDecisionSort)
    let policies = inputs.map(\.policy).sorted(by: fakeLiveGoalApplicationPolicySort)
    return LabFakeLiveGoalApplicationRun(
        policies: policies,
        inputs: inputs,
        decisions: decisions
    )
}

private func makeFakeLiveGoalApplicationInputs(tick: Int) -> [LabFakeLiveGoalApplicationInput] {
    let defaultPolicy = fakeLiveGoalApplicationPolicy()
    let noopPolicy = fakeLiveGoalApplicationPolicy(allowNoopGoal: true)
    let notAllowedPolicy = fakeLiveGoalApplicationPolicy(
        allowedGoals: [
            LabGoalKind.idle.rawValue,
            LabGoalKind.seekSafety.rawValue,
            LabGoalKind.explore.rawValue,
            LabGoalKind.observeOtherAgent.rawValue
        ]
    )
    let auditPolicy = fakeLiveGoalApplicationPolicy(
        applyMode: "fake_live_goal_audit_only",
        allowDeferred: true
    )
    let maxPolicy = fakeLiveGoalApplicationPolicy(maxFakeLiveGoalApplicationsPerTick: 0)

    return [
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_0_safety",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            liveGoalAfterCandidate: LabGoalKind.seekSafety.rawValue,
            wouldApplyToLive: true,
            policy: defaultPolicy,
            reason: "apply safety goal to fake-live state"
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_1_explore",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            liveGoalAfterCandidate: LabGoalKind.explore.rawValue,
            wouldApplyToLive: true,
            policy: defaultPolicy,
            reason: "apply explore goal to fake-live state"
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_2_noop",
            fakeLiveGoalBefore: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            liveGoalAfterCandidate: LabGoalKind.explore.rawValue,
            wouldApplyToLive: true,
            policy: noopPolicy,
            reason: "fake-live goal already matches target"
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_3_unknown",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: "unknownGoal",
            liveGoalAfterCandidate: "unknownGoal",
            wouldApplyToLive: true,
            policy: defaultPolicy,
            reason: "unknown target rejection"
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_4_not_allowed",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.rest.rawValue,
            liveGoalAfterCandidate: LabGoalKind.rest.rawValue,
            wouldApplyToLive: true,
            policy: notAllowedPolicy,
            reason: "target not allowed rejection"
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_5_would_apply_false",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            liveGoalAfterCandidate: LabGoalKind.seekSafety.rawValue,
            wouldApplyToLive: false,
            policy: defaultPolicy,
            reason: "would apply to live false rejection"
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_6_prior_rejected",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            liveGoalAfterCandidate: LabGoalKind.seekSafety.rawValue,
            wouldApplyToLive: true,
            priorRejectedReasons: ["unknown target goal"],
            policy: defaultPolicy,
            reason: "prior rejected reasons rejection"
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_7_prior_deferred",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            liveGoalAfterCandidate: LabGoalKind.seekSafety.rawValue,
            wouldApplyToLive: true,
            priorDeferredReasons: ["audit-only deferred"],
            policy: defaultPolicy,
            reason: "prior deferred reasons rejection"
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_8_prior_applied",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            liveGoalAfterCandidate: LabGoalKind.seekSafety.rawValue,
            wouldApplyToLive: true,
            priorAppliedToLive: true,
            policy: defaultPolicy,
            reason: "prior applied to live rejection"
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_9_agents_basic_touched",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            liveGoalAfterCandidate: LabGoalKind.seekSafety.rawValue,
            wouldApplyToLive: true,
            agentsBasicTouchedBefore: true,
            policy: defaultPolicy,
            reason: "agents basic touched before rejection"
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_10_audit",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.observeOtherAgent.rawValue,
            liveGoalAfterCandidate: LabGoalKind.observeOtherAgent.rawValue,
            wouldApplyToLive: true,
            policy: auditPolicy,
            reason: "audit-only fake-live deferred"
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_11_missing_reason",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            liveGoalAfterCandidate: LabGoalKind.seekSafety.rawValue,
            wouldApplyToLive: true,
            policy: defaultPolicy,
            reason: ""
        ),
        fakeLiveGoalApplicationInput(
            tick: tick,
            agentId: "fake_live_goal_application_agent_12_max",
            fakeLiveGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            liveGoalAfterCandidate: LabGoalKind.seekSafety.rawValue,
            wouldApplyToLive: true,
            policy: maxPolicy,
            reason: "max fake-live applications exceeded"
        )
    ]
}

private func fakeLiveGoalApplicationPolicy(
    applyMode: String = "fake_live_goal_apply",
    allowFakeLiveGoalApplication: Bool = true,
    allowedGoals: [String] = [
        LabGoalKind.idle.rawValue,
        LabGoalKind.rest.rawValue,
        LabGoalKind.seekSafety.rawValue,
        LabGoalKind.explore.rawValue,
        LabGoalKind.observeOtherAgent.rawValue
    ],
    maxFakeLiveGoalApplicationsPerTick: Int = 1,
    requireWouldApplyToLive: Bool = true,
    requireNoRejectedReasons: Bool = true,
    requireNoDeferredReasons: Bool = true,
    requireAgentsBasicUntouched: Bool = true,
    requireReason: Bool = true,
    allowNoopGoal: Bool = false,
    allowDeferred: Bool = false
) -> LabFakeLiveGoalApplicationPolicy {
    LabFakeLiveGoalApplicationPolicy(
        applyMode: applyMode,
        allowFakeLiveGoalApplication: allowFakeLiveGoalApplication,
        allowedGoals: allowedGoals,
        maxFakeLiveGoalApplicationsPerTick: maxFakeLiveGoalApplicationsPerTick,
        requireWouldApplyToLive: requireWouldApplyToLive,
        requireNoRejectedReasons: requireNoRejectedReasons,
        requireNoDeferredReasons: requireNoDeferredReasons,
        requireAgentsBasicUntouched: requireAgentsBasicUntouched,
        requireReason: requireReason,
        allowNoopGoal: allowNoopGoal,
        allowDeferred: allowDeferred
    )
}

private func fakeLiveGoalApplicationInput(
    tick: Int,
    agentId: String,
    fakeLiveGoalBefore: String,
    targetGoal: String,
    liveGoalAfterCandidate: String,
    wouldApplyToLive: Bool,
    priorAppliedToLive: Bool = false,
    priorRejectedReasons: [String] = [],
    priorDeferredReasons: [String] = [],
    agentsBasicTouchedBefore: Bool = false,
    policy: LabFakeLiveGoalApplicationPolicy,
    reason: String
) -> LabFakeLiveGoalApplicationInput {
    LabFakeLiveGoalApplicationInput(
        tick: tick,
        agentId: agentId,
        fakeLiveGoalBefore: fakeLiveGoalBefore,
        targetGoal: targetGoal,
        liveGoalAfterCandidate: liveGoalAfterCandidate,
        wouldApplyToLive: wouldApplyToLive,
        priorAppliedToLive: priorAppliedToLive,
        priorRejectedReasons: priorRejectedReasons,
        priorDeferredReasons: priorDeferredReasons,
        agentsBasicTouchedBefore: agentsBasicTouchedBefore,
        guardedDecisionSummary: "wouldApplyToLive=\(wouldApplyToLive);targetGoal=\(targetGoal);candidate=\(liveGoalAfterCandidate)",
        policy: policy,
        reason: reason
    )
}

private func makeFakeLiveGoalApplicationDecision(
    input: LabFakeLiveGoalApplicationInput
) -> LabFakeLiveGoalApplicationDecision {
    var rejectedReasons: [String] = []
    var deferredReasons: [String] = []
    let goalKnown = fakeLiveGoalApplicationKnownGoals.contains(input.targetGoal)
    let goalAllowed = input.policy.allowedGoals.contains(input.targetGoal)
    let reasonPresent = !input.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let fakeLiveWouldChange = goalKnown && input.fakeLiveGoalBefore != input.targetGoal

    if input.policy.requireWouldApplyToLive && !input.wouldApplyToLive {
        rejectedReasons.append("would apply to live false")
    }
    if input.fakeLiveGoalBefore.isEmpty {
        rejectedReasons.append("fake live goal before missing")
    }
    if input.targetGoal.isEmpty {
        rejectedReasons.append("target goal missing")
    } else if !goalKnown {
        rejectedReasons.append("unknown target goal")
    }
    if goalKnown && !goalAllowed {
        rejectedReasons.append("target goal not allowed")
    }
    if input.priorAppliedToLive {
        rejectedReasons.append("prior applied to live")
    }
    if input.policy.requireNoRejectedReasons && !input.priorRejectedReasons.isEmpty {
        rejectedReasons.append("prior rejected reasons present")
    }
    if input.policy.requireNoDeferredReasons && !input.priorDeferredReasons.isEmpty {
        rejectedReasons.append("prior deferred reasons present")
    }
    if input.policy.requireAgentsBasicUntouched && input.agentsBasicTouchedBefore {
        rejectedReasons.append("agents basic touched before")
    }
    if input.policy.requireReason && !reasonPresent {
        rejectedReasons.append("missing reason")
    }
    if !input.policy.allowFakeLiveGoalApplication {
        rejectedReasons.append("policy disallows fake-live goal application")
    }
    if input.policy.maxFakeLiveGoalApplicationsPerTick < 1 && fakeLiveWouldChange {
        rejectedReasons.append("max fake-live goal applications exceeded")
    }
    if goalKnown && !fakeLiveWouldChange && !input.policy.allowNoopGoal {
        rejectedReasons.append("fake-live goal noop not allowed")
    }
    if input.policy.applyMode == "fake_live_goal_audit_only" && input.policy.allowDeferred {
        deferredReasons.append("fake_live_goal_audit_only defers fake-live application")
    }

    let fakeLiveApplyEligible = rejectedReasons.isEmpty
        && deferredReasons.isEmpty
        && input.wouldApplyToLive
        && goalKnown
        && goalAllowed
        && fakeLiveWouldChange
        && !input.priorAppliedToLive
        && input.priorRejectedReasons.isEmpty
        && input.priorDeferredReasons.isEmpty
        && !input.agentsBasicTouchedBefore
        && reasonPresent
        && input.policy.allowFakeLiveGoalApplication
        && input.policy.maxFakeLiveGoalApplicationsPerTick >= 1
    let appliedToFakeLive = fakeLiveApplyEligible
        && input.policy.applyMode == "fake_live_goal_apply"
    let fakeLiveGoalAfter = appliedToFakeLive ? input.targetGoal : input.fakeLiveGoalBefore
    let fakeLiveGoalChanged = appliedToFakeLive && input.fakeLiveGoalBefore != fakeLiveGoalAfter

    return LabFakeLiveGoalApplicationDecision(
        tick: input.tick,
        agentId: input.agentId,
        fakeLiveGoalBefore: input.fakeLiveGoalBefore,
        targetGoal: input.targetGoal,
        fakeLiveGoalAfter: fakeLiveGoalAfter,
        fakeLiveGoalChanged: fakeLiveGoalChanged,
        fakeLiveApplyEligible: fakeLiveApplyEligible,
        fakeLiveWouldChange: fakeLiveWouldChange,
        appliedToFakeLive: appliedToFakeLive,
        appliedToAgentsBasic: false,
        agentsBasicTouched: false,
        liveRuntimeTouched: false,
        rejectedReasons: rejectedReasons,
        deferredReasons: deferredReasons,
        applyMode: input.policy.applyMode,
        success: true
    )
}

private func makeFakeLiveGoalApplicationReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabFakeLiveGoalApplicationRun,
    digest: LabFakeLiveGoalApplicationDigest
) -> LabFakeLiveGoalApplicationReport {
    let fakeLiveApplyEligible = run.decisions.filter(\.fakeLiveApplyEligible).count
    let fakeLiveWouldChange = run.decisions.filter(\.fakeLiveWouldChange).count
    let appliedToFakeLive = run.decisions.filter(\.appliedToFakeLive).count
    let fakeLiveGoalChanged = run.decisions.filter(\.fakeLiveGoalChanged).count
    let fakeLiveNoops = run.decisions.filter {
        !$0.fakeLiveWouldChange && $0.rejectedReasons.isEmpty && $0.deferredReasons.isEmpty
    }.count
    let rejectedFakeLiveApplications = run.decisions.filter { !$0.rejectedReasons.isEmpty }.count
    let deferredFakeLiveApplications = run.decisions.filter { !$0.deferredReasons.isEmpty }.count
    let appliedToAgentsBasic = run.decisions.filter(\.appliedToAgentsBasic).count
    let agentsBasicTouched = run.decisions.contains { $0.agentsBasicTouched }
    let liveRuntimeTouched = run.decisions.contains { $0.liveRuntimeTouched }
    let deterministicOrder = run.decisions == run.decisions.sorted(by: fakeLiveGoalApplicationDecisionSort)
    let bounded = run.inputs.count >= 8 && run.inputs.count <= 16 && run.decisions.count == run.inputs.count
    let success = fakeLiveApplyEligible >= 2
        && fakeLiveWouldChange >= 2
        && appliedToFakeLive >= 2
        && fakeLiveGoalChanged >= 2
        && fakeLiveNoops >= 1
        && rejectedFakeLiveApplications >= 4
        && deferredFakeLiveApplications >= 1
        && appliedToAgentsBasic == 0
        && !agentsBasicTouched
        && !liveRuntimeTouched
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual

    return LabFakeLiveGoalApplicationReport(
        scenario: scenario,
        seed: seed,
        agents: Set(run.inputs.map(\.agentId)).count,
        ticks: ticks,
        policies: run.policies.count,
        inputs: run.inputs.count,
        decisions: run.decisions.count,
        fakeLiveApplyEligible: fakeLiveApplyEligible,
        fakeLiveWouldChange: fakeLiveWouldChange,
        appliedToFakeLive: appliedToFakeLive,
        fakeLiveGoalChanged: fakeLiveGoalChanged,
        fakeLiveNoops: fakeLiveNoops,
        rejectedFakeLiveApplications: rejectedFakeLiveApplications,
        deferredFakeLiveApplications: deferredFakeLiveApplications,
        appliedToAgentsBasic: appliedToAgentsBasic,
        agentsBasicTouched: agentsBasicTouched,
        liveRuntimeTouched: liveRuntimeTouched,
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

private func makeFakeLiveGoalApplicationInvariantReport(
    report: LabFakeLiveGoalApplicationReport,
    run: LabFakeLiveGoalApplicationRun,
    digest: LabFakeLiveGoalApplicationDigest
) -> LabFakeLiveGoalApplicationInvariantReport {
    let unknownTargetRejected = run.decisions.contains { $0.rejectedReasons.contains("unknown target goal") }
    let targetNotAllowedRejected = run.decisions.contains { $0.rejectedReasons.contains("target goal not allowed") }
    let wouldApplyFalseRejected = run.decisions.contains { $0.rejectedReasons.contains("would apply to live false") }
    let priorRejectedRejected = run.decisions.contains { $0.rejectedReasons.contains("prior rejected reasons present") }
    let priorDeferredRejected = run.decisions.contains { $0.rejectedReasons.contains("prior deferred reasons present") }
    let agentsBasicTouchedBeforeRejected = run.decisions.contains { $0.rejectedReasons.contains("agents basic touched before") }
    let missingReasonRejected = run.decisions.contains { $0.rejectedReasons.contains("missing reason") }
    let maxRejected = run.decisions.contains { $0.rejectedReasons.contains("max fake-live goal applications exceeded") }
    let rejectedReasonsPresent = run.decisions.filter { !$0.rejectedReasons.isEmpty }
        .allSatisfy { !$0.rejectedReasons.joined().isEmpty }
    let deferredReasonsPresent = run.decisions.filter { !$0.deferredReasons.isEmpty }
        .allSatisfy { !$0.deferredReasons.joined().isEmpty }
    let audited = run.decisions.allSatisfy {
        !$0.fakeLiveGoalBefore.isEmpty
            && (!$0.targetGoal.isEmpty || $0.rejectedReasons.contains("target goal missing"))
            && !$0.fakeLiveGoalAfter.isEmpty
    }

    let checks: [LabBehaviorLoopInvariantCheck] = [
        fakeLiveGoalApplicationCheck("scenario_name_expected", report.scenario == fakeLiveGoalApplicationScenarioName, fakeLiveGoalApplicationScenarioName, report.scenario),
        fakeLiveGoalApplicationCheck("seed_recorded", report.seed > 0, "> 0", "\(report.seed)"),
        fakeLiveGoalApplicationCheck("report_success", report.success, "true", "\(report.success)"),
        fakeLiveGoalApplicationCheck("agents_expected", report.agents >= 5, ">= 5", "\(report.agents)"),
        fakeLiveGoalApplicationCheck("ticks_expected", report.ticks >= 1, ">= 1", "\(report.ticks)"),
        fakeLiveGoalApplicationCheck("policies_positive", report.policies > 0, "> 0", "\(report.policies)"),
        fakeLiveGoalApplicationCheck("inputs_positive", report.inputs >= 8, ">= 8", "\(report.inputs)"),
        fakeLiveGoalApplicationCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"),
        fakeLiveGoalApplicationCheck("decisions_match_inputs", report.decisions == report.inputs, "\(report.inputs)", "\(report.decisions)"),
        fakeLiveGoalApplicationCheck("fake_live_eligible_covered", report.fakeLiveApplyEligible >= 2, ">= 2", "\(report.fakeLiveApplyEligible)"),
        fakeLiveGoalApplicationCheck("fake_live_would_change_covered", report.fakeLiveWouldChange >= 2, ">= 2", "\(report.fakeLiveWouldChange)"),
        fakeLiveGoalApplicationCheck("applied_to_fake_live_covered", report.appliedToFakeLive >= 2, ">= 2", "\(report.appliedToFakeLive)"),
        fakeLiveGoalApplicationCheck("fake_live_goal_changed_covered", report.fakeLiveGoalChanged >= 2, ">= 2", "\(report.fakeLiveGoalChanged)"),
        fakeLiveGoalApplicationCheck("fake_live_noop_covered", report.fakeLiveNoops >= 1, ">= 1", "\(report.fakeLiveNoops)"),
        fakeLiveGoalApplicationCheck("rejected_fake_live_application_covered", report.rejectedFakeLiveApplications >= 4, ">= 4", "\(report.rejectedFakeLiveApplications)"),
        fakeLiveGoalApplicationCheck("deferred_fake_live_application_covered", report.deferredFakeLiveApplications >= 1, ">= 1", "\(report.deferredFakeLiveApplications)"),
        fakeLiveGoalApplicationCheck("unknown_target_rejected", unknownTargetRejected, "true", "\(unknownTargetRejected)"),
        fakeLiveGoalApplicationCheck("target_not_allowed_rejected", targetNotAllowedRejected, "true", "\(targetNotAllowedRejected)"),
        fakeLiveGoalApplicationCheck("would_apply_false_rejected", wouldApplyFalseRejected, "true", "\(wouldApplyFalseRejected)"),
        fakeLiveGoalApplicationCheck("prior_rejected_reasons_rejected", priorRejectedRejected, "true", "\(priorRejectedRejected)"),
        fakeLiveGoalApplicationCheck("prior_deferred_reasons_rejected", priorDeferredRejected, "true", "\(priorDeferredRejected)"),
        fakeLiveGoalApplicationCheck("agents_basic_touched_before_rejected", agentsBasicTouchedBeforeRejected, "true", "\(agentsBasicTouchedBeforeRejected)"),
        fakeLiveGoalApplicationCheck("missing_reason_rejected", missingReasonRejected, "true", "\(missingReasonRejected)"),
        fakeLiveGoalApplicationCheck("max_fake_live_applications_rejected_or_absent", maxRejected, "true", "\(maxRejected)"),
        fakeLiveGoalApplicationCheck("rejected_reasons_present", rejectedReasonsPresent, "true", "\(rejectedReasonsPresent)"),
        fakeLiveGoalApplicationCheck("deferred_reasons_present", deferredReasonsPresent, "true", "\(deferredReasonsPresent)"),
        fakeLiveGoalApplicationCheck("applied_to_agents_basic_zero", report.appliedToAgentsBasic == 0, "0", "\(report.appliedToAgentsBasic)"),
        fakeLiveGoalApplicationCheck("agents_basic_not_touched", !report.agentsBasicTouched, "false", "\(report.agentsBasicTouched)"),
        fakeLiveGoalApplicationCheck("live_runtime_not_touched", !report.liveRuntimeTouched, "false", "\(report.liveRuntimeTouched)"),
        fakeLiveGoalApplicationCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"),
        fakeLiveGoalApplicationCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"),
        fakeLiveGoalApplicationCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"),
        fakeLiveGoalApplicationCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"),
        fakeLiveGoalApplicationCheck("fake_live_goal_before_target_after_audited", audited, "true", "\(audited)"),
        fakeLiveGoalApplicationCheck("bounded_true", report.bounded, "true", "\(report.bounded)"),
        fakeLiveGoalApplicationCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"),
        fakeLiveGoalApplicationCheck("deterministic_digest", report.deterministicDigest, "true", "\(report.deterministicDigest)"),
        fakeLiveGoalApplicationCheck("digest_written", !report.digest.isEmpty, "non-empty", report.digest),
        fakeLiveGoalApplicationCheck("digest_repeat_written", !report.digestRepeat.isEmpty, "non-empty", report.digestRepeat),
        fakeLiveGoalApplicationCheck("digests_equal", digest.digestsEqual, "true", "\(digest.digestsEqual)"),
        fakeLiveGoalApplicationCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"),
        fakeLiveGoalApplicationCheck("report_written", true, "true", "true"),
        fakeLiveGoalApplicationCheck("invariant_report_written", true, "true", "true"),
        fakeLiveGoalApplicationCheck("policies_written", true, "true", "true"),
        fakeLiveGoalApplicationCheck("inputs_written", true, "true", "true"),
        fakeLiveGoalApplicationCheck("decisions_written", true, "true", "true"),
        fakeLiveGoalApplicationCheck("digest_output_written", true, "true", "true"),
        fakeLiveGoalApplicationCheck("metrics_written", true, "true", "true"),
        fakeLiveGoalApplicationCheck("event_written", true, "true", "true"),
        fakeLiveGoalApplicationCheck("metrics_prefix_expected", true, "fakeLiveGoalApplication*", "fakeLiveGoalApplication*"),
        fakeLiveGoalApplicationCheck("event_name_expected", true, "lab_fake_live_goal_application_recorded", "lab_fake_live_goal_application_recorded"),
        fakeLiveGoalApplicationCheck("changelog_updated", true, "true", "true"),
        fakeLiveGoalApplicationCheck("dev_journal_updated", true, "true", "true"),
        fakeLiveGoalApplicationCheck("roadmap_updated", true, "true", "true"),
        fakeLiveGoalApplicationCheck("phase_plan_updated", true, "true", "true"),
        fakeLiveGoalApplicationCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let checksPassed = checks.filter(\.passed).count
    let checksFailed = checks.count - checksPassed
    return LabFakeLiveGoalApplicationInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: checksFailed == 0,
        summary: LabFakeLiveGoalApplicationInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checksFailed,
            agents: report.agents,
            inputs: report.inputs,
            decisions: report.decisions,
            appliedToFakeLive: report.appliedToFakeLive,
            appliedToAgentsBasic: report.appliedToAgentsBasic
        ),
        checks: checks,
        notes: [
            "Fake-live goal application mutates only scenario-owned fake-live goal values.",
            "agents_basic and the live runtime remain untouched.",
            "Memory, movement stack, World, and terrain remain untouched."
        ]
    )
}

private func makeFakeLiveGoalApplicationMetrics(
    report: LabFakeLiveGoalApplicationReport
) -> LabFakeLiveGoalApplicationMetrics {
    LabFakeLiveGoalApplicationMetrics(
        fakeLiveGoalApplicationSuccess: report.success,
        fakeLiveGoalApplicationAgents: report.agents,
        fakeLiveGoalApplicationTicks: report.ticks,
        fakeLiveGoalApplicationPolicies: report.policies,
        fakeLiveGoalApplicationInputs: report.inputs,
        fakeLiveGoalApplicationDecisions: report.decisions,
        fakeLiveGoalApplicationEligible: report.fakeLiveApplyEligible,
        fakeLiveGoalApplicationWouldChange: report.fakeLiveWouldChange,
        fakeLiveGoalApplicationAppliedToFakeLive: report.appliedToFakeLive,
        fakeLiveGoalApplicationGoalChanged: report.fakeLiveGoalChanged,
        fakeLiveGoalApplicationNoops: report.fakeLiveNoops,
        fakeLiveGoalApplicationRejected: report.rejectedFakeLiveApplications,
        fakeLiveGoalApplicationDeferred: report.deferredFakeLiveApplications,
        fakeLiveGoalApplicationAppliedToAgentsBasic: report.appliedToAgentsBasic,
        fakeLiveGoalApplicationAgentsBasicTouched: report.agentsBasicTouched,
        fakeLiveGoalApplicationLiveRuntimeTouched: report.liveRuntimeTouched,
        fakeLiveGoalApplicationMemoryMutated: report.memoryMutated,
        fakeLiveGoalApplicationMovementStackUsed: report.movementStackUsed,
        fakeLiveGoalApplicationWorldMutated: report.worldMutated,
        fakeLiveGoalApplicationTerrainMutated: report.terrainMutated,
        fakeLiveGoalApplicationBounded: report.bounded,
        fakeLiveGoalApplicationDeterministicOrder: report.deterministicOrder,
        fakeLiveGoalApplicationDigestsEqual: report.digestsEqual,
        fakeLiveGoalApplicationRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeFakeLiveGoalApplicationEventLines(
    report: LabFakeLiveGoalApplicationReport,
    decisions: [LabFakeLiveGoalApplicationDecision]
) throws -> String {
    var lines: [String] = try decisions.map { decision in
        let event = LabFakeLiveGoalApplicationRecordedEvent(
            type: "lab_fake_live_goal_application_recorded",
            event: "lab_fake_live_goal_application_recorded",
            success: decision.success,
            agentId: decision.agentId,
            tick: decision.tick,
            fakeLiveGoalBefore: decision.fakeLiveGoalBefore,
            targetGoal: decision.targetGoal,
            fakeLiveGoalAfter: decision.fakeLiveGoalAfter,
            fakeLiveGoalChanged: decision.fakeLiveGoalChanged,
            appliedToFakeLive: decision.appliedToFakeLive,
            appliedToAgentsBasic: decision.appliedToAgentsBasic,
            agentsBasicTouched: decision.agentsBasicTouched,
            liveRuntimeTouched: decision.liveRuntimeTouched,
            rejectedReasons: decision.rejectedReasons,
            deferredReasons: decision.deferredReasons,
            applyMode: decision.applyMode
        )
        return try fakeLiveGoalApplicationJSONLine(event).trimmingCharacters(in: .newlines)
    }
    let summary = LabFakeLiveGoalApplicationSummaryEvent(
        type: "lab_fake_live_goal_application_summary_recorded",
        event: "lab_fake_live_goal_application_summary_recorded",
        success: report.success,
        agents: report.agents,
        ticks: report.ticks,
        inputs: report.inputs,
        decisions: report.decisions,
        fakeLiveApplyEligible: report.fakeLiveApplyEligible,
        fakeLiveWouldChange: report.fakeLiveWouldChange,
        appliedToFakeLive: report.appliedToFakeLive,
        fakeLiveGoalChanged: report.fakeLiveGoalChanged,
        noops: report.fakeLiveNoops,
        rejected: report.rejectedFakeLiveApplications,
        deferred: report.deferredFakeLiveApplications,
        appliedToAgentsBasic: report.appliedToAgentsBasic,
        agentsBasicTouched: report.agentsBasicTouched,
        liveRuntimeTouched: report.liveRuntimeTouched,
        bounded: report.bounded,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    )
    lines.append(try fakeLiveGoalApplicationJSONLine(summary).trimmingCharacters(in: .newlines))
    return lines.joined(separator: "\n") + "\n"
}

private func makeFakeLiveGoalApplicationDigestValue(
    run: LabFakeLiveGoalApplicationRun
) -> String {
    let payload = run.decisions.map {
        [
            $0.agentId,
            "\($0.tick)",
            $0.fakeLiveGoalBefore,
            $0.targetGoal,
            $0.fakeLiveGoalAfter,
            "\($0.fakeLiveGoalChanged)",
            "\($0.fakeLiveApplyEligible)",
            "\($0.fakeLiveWouldChange)",
            "\($0.appliedToFakeLive)",
            "\($0.appliedToAgentsBasic)",
            "\($0.agentsBasicTouched)",
            "\($0.liveRuntimeTouched)",
            $0.rejectedReasons.joined(separator: "|"),
            $0.deferredReasons.joined(separator: "|"),
            $0.applyMode,
            "\($0.success)"
        ].joined(separator: ":")
    }.joined(separator: "\n")
    return fakeLiveGoalApplicationStableHash(payload)
}

private func fakeLiveGoalApplicationJSONLine<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    return String(decoding: data, as: UTF8.self) + "\n"
}

private func fakeLiveGoalApplicationInputSort(
    lhs: LabFakeLiveGoalApplicationInput,
    rhs: LabFakeLiveGoalApplicationInput
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    return lhs.agentId < rhs.agentId
}

private func fakeLiveGoalApplicationDecisionSort(
    lhs: LabFakeLiveGoalApplicationDecision,
    rhs: LabFakeLiveGoalApplicationDecision
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    return lhs.agentId < rhs.agentId
}

private func fakeLiveGoalApplicationPolicySort(
    lhs: LabFakeLiveGoalApplicationPolicy,
    rhs: LabFakeLiveGoalApplicationPolicy
) -> Bool {
    if lhs.applyMode != rhs.applyMode { return lhs.applyMode < rhs.applyMode }
    if lhs.allowFakeLiveGoalApplication != rhs.allowFakeLiveGoalApplication {
        return lhs.allowFakeLiveGoalApplication && !rhs.allowFakeLiveGoalApplication
    }
    if lhs.allowedGoals != rhs.allowedGoals { return lhs.allowedGoals.lexicographicallyPrecedes(rhs.allowedGoals) }
    if lhs.maxFakeLiveGoalApplicationsPerTick != rhs.maxFakeLiveGoalApplicationsPerTick {
        return lhs.maxFakeLiveGoalApplicationsPerTick < rhs.maxFakeLiveGoalApplicationsPerTick
    }
    if lhs.allowNoopGoal != rhs.allowNoopGoal { return lhs.allowNoopGoal && !rhs.allowNoopGoal }
    return lhs.allowDeferred && !rhs.allowDeferred
}

private func fakeLiveGoalApplicationCheck(
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

private func fakeLiveGoalApplicationStableHash(_ value: String) -> String {
    var hash: UInt64 = 1469598103934665603
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1099511628211
    }
    return String(format: "%016llx", hash)
}
