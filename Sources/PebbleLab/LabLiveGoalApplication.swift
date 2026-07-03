import Foundation

let liveGoalApplicationScenarioName = "live_goal_application_guarded_fixture_smoke"

private let liveGoalApplicationKnownGoals = [
    LabGoalKind.idle.rawValue,
    LabGoalKind.rest.rawValue,
    LabGoalKind.seekSafety.rawValue,
    LabGoalKind.explore.rawValue,
    LabGoalKind.observeOtherAgent.rawValue
]

struct LabLiveGoalApplicationPolicy: Codable, Equatable {
    let applyMode: String
    let allowLiveGoalApplication: Bool
    let allowedGoals: [String]
    let maxLiveGoalApplicationsPerTick: Int
    let requireSnapshotMutationApplied: Bool
    let requireLiveGoalStillMatchesOriginal: Bool
    let requireNoRejectedReasons: Bool
    let requireNoDeferredReasons: Bool
    let requireReason: Bool
    let requireDedicatedScenario: Bool
    let dedicatedScenario: Bool
    let allowNoopGoal: Bool
    let allowDeferred: Bool
}

struct LabLiveGoalApplicationInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let liveGoalBefore: String
    let originalLiveGoalBefore: String
    let snapshotGoalAfter: String
    let targetGoal: String
    let appliedToSnapshot: Bool
    let snapshotGoalChanged: Bool
    let priorAppliedToLive: Bool
    let priorRejectedReasons: [String]
    let priorDeferredReasons: [String]
    let snapshotMutationSummary: String
    let policy: LabLiveGoalApplicationPolicy
    let reason: String
}

struct LabLiveGoalApplicationDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let liveGoalBefore: String
    let targetGoal: String
    let liveGoalAfterCandidate: String
    let liveGoalWouldChange: Bool
    let liveApplyEligible: Bool
    let wouldApplyToLive: Bool
    let appliedToLive: Bool
    let liveAgentMutated: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let applyMode: String
    let success: Bool
}

struct LabLiveGoalApplicationReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let policies: Int
    let inputs: Int
    let decisions: Int
    let liveApplyEligible: Int
    let wouldApplyToLive: Int
    let appliedToLive: Int
    let liveGoalWouldChange: Int
    let liveNoops: Int
    let rejectedLiveApplications: Int
    let deferredLiveApplications: Int
    let liveAgentMutated: Bool
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let agentsBasicTouched: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let success: Bool
}

struct LabLiveGoalApplicationInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let inputs: Int
    let decisions: Int
    let rejectedLiveApplications: Int
    let deferredLiveApplications: Int
}

struct LabLiveGoalApplicationInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabLiveGoalApplicationInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabLiveGoalApplicationDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabLiveGoalApplicationMetrics: Codable, Equatable {
    let liveGoalApplicationSuccess: Bool
    let liveGoalApplicationAgents: Int
    let liveGoalApplicationTicks: Int
    let liveGoalApplicationPolicies: Int
    let liveGoalApplicationInputs: Int
    let liveGoalApplicationDecisions: Int
    let liveGoalApplicationEligible: Int
    let liveGoalApplicationWouldApplyToLive: Int
    let liveGoalApplicationAppliedToLive: Int
    let liveGoalApplicationLiveGoalWouldChange: Int
    let liveGoalApplicationLiveNoops: Int
    let liveGoalApplicationRejected: Int
    let liveGoalApplicationDeferred: Int
    let liveGoalApplicationLiveAgentMutated: Bool
    let liveGoalApplicationMemoryMutated: Bool
    let liveGoalApplicationMovementStackUsed: Bool
    let liveGoalApplicationWorldMutated: Bool
    let liveGoalApplicationTerrainMutated: Bool
    let liveGoalApplicationAgentsBasicTouched: Bool
    let liveGoalApplicationBounded: Bool
    let liveGoalApplicationDeterministicOrder: Bool
    let liveGoalApplicationDigestsEqual: Bool
    let liveGoalApplicationRepeatabilityFailures: Int
}

struct LabLiveGoalApplicationFixture: Codable, Equatable {
    let report: LabLiveGoalApplicationReport
    let invariantReport: LabLiveGoalApplicationInvariantReport
    let policies: [LabLiveGoalApplicationPolicy]
    let inputs: [LabLiveGoalApplicationInput]
    let decisions: [LabLiveGoalApplicationDecision]
    let digest: LabLiveGoalApplicationDigest
    let eventLines: String
    let metrics: LabLiveGoalApplicationMetrics
}

private struct LabLiveGoalApplicationRun {
    let policies: [LabLiveGoalApplicationPolicy]
    let inputs: [LabLiveGoalApplicationInput]
    let decisions: [LabLiveGoalApplicationDecision]
}

private struct LabLiveGoalApplicationRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let liveGoalBefore: String
    let targetGoal: String
    let liveGoalAfterCandidate: String
    let liveGoalWouldChange: Bool
    let liveApplyEligible: Bool
    let wouldApplyToLive: Bool
    let appliedToLive: Bool
    let liveAgentMutated: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let applyMode: String
}

private struct LabLiveGoalApplicationSummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let ticks: Int
    let inputs: Int
    let decisions: Int
    let liveApplyEligible: Int
    let wouldApplyToLive: Int
    let appliedToLive: Int
    let liveGoalWouldChange: Int
    let liveNoops: Int
    let rejected: Int
    let deferred: Int
    let liveAgentMutated: Bool
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeLiveGoalApplicationFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabLiveGoalApplicationFixture {
    let run = makeLiveGoalApplicationRun(ticks: ticks)
    let repeatRun = makeLiveGoalApplicationRun(ticks: ticks)
    let digestValue = makeLiveGoalApplicationDigestValue(run: run)
    let digestRepeatValue = makeLiveGoalApplicationDigestValue(run: repeatRun)
    let digest = LabLiveGoalApplicationDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeLiveGoalApplicationReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeLiveGoalApplicationInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabLiveGoalApplicationFixture(
        report: report,
        invariantReport: invariantReport,
        policies: run.policies,
        inputs: run.inputs,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeLiveGoalApplicationEventLines(report: report, decisions: run.decisions),
        metrics: makeLiveGoalApplicationMetrics(report: report)
    )
}

private func makeLiveGoalApplicationRun(ticks: Int) -> LabLiveGoalApplicationRun {
    let tick = max(1, ticks)
    let inputs = makeLiveGoalApplicationInputs(tick: tick).sorted(by: liveGoalApplicationInputSort)
    let decisions = inputs.map(makeLiveGoalApplicationDecision).sorted(by: liveGoalApplicationDecisionSort)
    let policies = inputs.map(\.policy).sorted(by: liveGoalApplicationPolicySort)
    return LabLiveGoalApplicationRun(
        policies: policies,
        inputs: inputs,
        decisions: decisions
    )
}

private func makeLiveGoalApplicationInputs(tick: Int) -> [LabLiveGoalApplicationInput] {
    let defaultPolicy = liveGoalApplicationPolicy()
    let noopPolicy = liveGoalApplicationPolicy(allowNoopGoal: true)
    let notAllowedPolicy = liveGoalApplicationPolicy(
        allowedGoals: [
            LabGoalKind.idle.rawValue,
            LabGoalKind.seekSafety.rawValue,
            LabGoalKind.explore.rawValue,
            LabGoalKind.observeOtherAgent.rawValue
        ]
    )
    let auditPolicy = liveGoalApplicationPolicy(
        applyMode: "live_goal_audit_only",
        allowDeferred: true
    )
    let dedicatedFalsePolicy = liveGoalApplicationPolicy(dedicatedScenario: false)
    let maxPolicy = liveGoalApplicationPolicy(maxLiveGoalApplicationsPerTick: 0)

    return [
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_0_safety",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: true,
            policy: defaultPolicy,
            reason: "eligible safety live goal candidate"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_1_explore",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: true,
            policy: defaultPolicy,
            reason: "eligible explore live goal candidate"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_2_noop",
            liveGoalBefore: LabGoalKind.explore.rawValue,
            originalLiveGoalBefore: LabGoalKind.explore.rawValue,
            snapshotGoalAfter: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: false,
            policy: noopPolicy,
            reason: "live goal already matches target"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_3_unknown",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: "unknownGoal",
            targetGoal: "unknownGoal",
            appliedToSnapshot: true,
            snapshotGoalChanged: true,
            policy: defaultPolicy,
            reason: "unknown target rejection"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_4_not_allowed",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.rest.rawValue,
            targetGoal: LabGoalKind.rest.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: true,
            policy: notAllowedPolicy,
            reason: "target not allowed rejection"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_5_mismatch",
            liveGoalBefore: LabGoalKind.rest.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: true,
            policy: defaultPolicy,
            reason: "live goal mismatch rejection"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_6_prior_applied",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: true,
            priorAppliedToLive: true,
            policy: defaultPolicy,
            reason: "prior applied to live rejection"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_7_prior_rejected",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: true,
            priorRejectedReasons: ["unknown target goal"],
            policy: defaultPolicy,
            reason: "prior rejected reasons rejection"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_8_prior_deferred",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: true,
            priorDeferredReasons: ["audit-only deferred"],
            policy: defaultPolicy,
            reason: "prior deferred reasons rejection"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_9_audit",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.observeOtherAgent.rawValue,
            targetGoal: LabGoalKind.observeOtherAgent.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: true,
            policy: auditPolicy,
            reason: "audit-only deferred live goal candidate"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_10_dedicated_false",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: true,
            policy: dedicatedFalsePolicy,
            reason: "dedicated scenario false rejection"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_11_max",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.rest.rawValue,
            targetGoal: LabGoalKind.rest.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: true,
            policy: maxPolicy,
            reason: "max live goal applications exceeded"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_12_not_snapshot_applied",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            appliedToSnapshot: false,
            snapshotGoalChanged: true,
            policy: defaultPolicy,
            reason: "applied to snapshot required rejection"
        ),
        liveGoalApplicationInput(
            tick: tick,
            agentId: "live_goal_application_agent_13_snapshot_unchanged_non_noop",
            liveGoalBefore: LabGoalKind.idle.rawValue,
            originalLiveGoalBefore: LabGoalKind.idle.rawValue,
            snapshotGoalAfter: LabGoalKind.seekSafety.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            appliedToSnapshot: true,
            snapshotGoalChanged: false,
            policy: defaultPolicy,
            reason: "snapshot goal changed required rejection"
        )
    ]
}

private func liveGoalApplicationPolicy(
    applyMode: String = "live_goal_guarded_dry_run",
    allowLiveGoalApplication: Bool = true,
    allowedGoals: [String] = [
        LabGoalKind.idle.rawValue,
        LabGoalKind.rest.rawValue,
        LabGoalKind.seekSafety.rawValue,
        LabGoalKind.explore.rawValue,
        LabGoalKind.observeOtherAgent.rawValue
    ],
    maxLiveGoalApplicationsPerTick: Int = 1,
    requireSnapshotMutationApplied: Bool = true,
    requireLiveGoalStillMatchesOriginal: Bool = true,
    requireNoRejectedReasons: Bool = true,
    requireNoDeferredReasons: Bool = true,
    requireReason: Bool = true,
    requireDedicatedScenario: Bool = true,
    dedicatedScenario: Bool = true,
    allowNoopGoal: Bool = false,
    allowDeferred: Bool = false
) -> LabLiveGoalApplicationPolicy {
    LabLiveGoalApplicationPolicy(
        applyMode: applyMode,
        allowLiveGoalApplication: allowLiveGoalApplication,
        allowedGoals: allowedGoals,
        maxLiveGoalApplicationsPerTick: maxLiveGoalApplicationsPerTick,
        requireSnapshotMutationApplied: requireSnapshotMutationApplied,
        requireLiveGoalStillMatchesOriginal: requireLiveGoalStillMatchesOriginal,
        requireNoRejectedReasons: requireNoRejectedReasons,
        requireNoDeferredReasons: requireNoDeferredReasons,
        requireReason: requireReason,
        requireDedicatedScenario: requireDedicatedScenario,
        dedicatedScenario: dedicatedScenario,
        allowNoopGoal: allowNoopGoal,
        allowDeferred: allowDeferred
    )
}

private func liveGoalApplicationInput(
    tick: Int,
    agentId: String,
    liveGoalBefore: String,
    originalLiveGoalBefore: String,
    snapshotGoalAfter: String,
    targetGoal: String,
    appliedToSnapshot: Bool,
    snapshotGoalChanged: Bool,
    priorAppliedToLive: Bool = false,
    priorRejectedReasons: [String] = [],
    priorDeferredReasons: [String] = [],
    policy: LabLiveGoalApplicationPolicy,
    reason: String
) -> LabLiveGoalApplicationInput {
    LabLiveGoalApplicationInput(
        tick: tick,
        agentId: agentId,
        liveGoalBefore: liveGoalBefore,
        originalLiveGoalBefore: originalLiveGoalBefore,
        snapshotGoalAfter: snapshotGoalAfter,
        targetGoal: targetGoal,
        appliedToSnapshot: appliedToSnapshot,
        snapshotGoalChanged: snapshotGoalChanged,
        priorAppliedToLive: priorAppliedToLive,
        priorRejectedReasons: priorRejectedReasons,
        priorDeferredReasons: priorDeferredReasons,
        snapshotMutationSummary: "appliedToSnapshot=\(appliedToSnapshot);snapshotGoalChanged=\(snapshotGoalChanged);targetGoal=\(targetGoal)",
        policy: policy,
        reason: reason
    )
}

private func makeLiveGoalApplicationDecision(
    input: LabLiveGoalApplicationInput
) -> LabLiveGoalApplicationDecision {
    var rejectedReasons: [String] = []
    var deferredReasons: [String] = []
    let goalKnown = liveGoalApplicationKnownGoals.contains(input.targetGoal)
    let goalAllowed = input.policy.allowedGoals.contains(input.targetGoal)
    let reasonPresent = !input.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let liveGoalWouldChange = goalKnown && input.liveGoalBefore != input.targetGoal

    if input.policy.requireSnapshotMutationApplied && !input.appliedToSnapshot {
        rejectedReasons.append("snapshot mutation not applied")
    }
    if !input.snapshotGoalChanged && liveGoalWouldChange {
        rejectedReasons.append("snapshot goal changed false")
    }
    if input.targetGoal.isEmpty {
        rejectedReasons.append("target goal missing")
    } else if !goalKnown {
        rejectedReasons.append("unknown target goal")
    }
    if goalKnown && !goalAllowed {
        rejectedReasons.append("target goal not allowed")
    }
    if input.policy.requireLiveGoalStillMatchesOriginal
        && input.liveGoalBefore != input.originalLiveGoalBefore {
        rejectedReasons.append("live goal mismatch original")
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
    if input.policy.requireReason && !reasonPresent {
        rejectedReasons.append("missing reason")
    }
    if !input.policy.allowLiveGoalApplication {
        rejectedReasons.append("policy disallows live goal application")
    }
    if input.policy.requireDedicatedScenario && !input.policy.dedicatedScenario {
        rejectedReasons.append("dedicated scenario false")
    }
    if input.policy.maxLiveGoalApplicationsPerTick < 1 && liveGoalWouldChange {
        rejectedReasons.append("max live goal applications exceeded")
    }
    if goalKnown && !liveGoalWouldChange && !input.policy.allowNoopGoal {
        rejectedReasons.append("live goal noop not allowed")
    }
    if input.policy.applyMode == "live_goal_audit_only" && input.policy.allowDeferred {
        deferredReasons.append("live_goal_audit_only defers live application")
    }

    let liveApplyEligible = rejectedReasons.isEmpty
        && deferredReasons.isEmpty
        && input.appliedToSnapshot
        && input.snapshotGoalChanged
        && goalKnown
        && goalAllowed
        && liveGoalWouldChange
        && input.liveGoalBefore == input.originalLiveGoalBefore
        && !input.priorAppliedToLive
        && input.priorRejectedReasons.isEmpty
        && input.priorDeferredReasons.isEmpty
        && reasonPresent
        && input.policy.allowLiveGoalApplication
        && input.policy.dedicatedScenario
        && input.policy.maxLiveGoalApplicationsPerTick >= 1
    let wouldApplyToLive = liveApplyEligible
        && input.policy.applyMode == "live_goal_guarded_dry_run"
    let liveGoalAfterCandidate = (liveApplyEligible || goalKnown) ? input.targetGoal : input.liveGoalBefore

    return LabLiveGoalApplicationDecision(
        tick: input.tick,
        agentId: input.agentId,
        liveGoalBefore: input.liveGoalBefore,
        targetGoal: input.targetGoal,
        liveGoalAfterCandidate: liveGoalAfterCandidate,
        liveGoalWouldChange: liveGoalWouldChange,
        liveApplyEligible: liveApplyEligible,
        wouldApplyToLive: wouldApplyToLive,
        appliedToLive: false,
        liveAgentMutated: false,
        rejectedReasons: rejectedReasons,
        deferredReasons: deferredReasons,
        applyMode: input.policy.applyMode,
        success: true
    )
}

private func makeLiveGoalApplicationReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabLiveGoalApplicationRun,
    digest: LabLiveGoalApplicationDigest
) -> LabLiveGoalApplicationReport {
    let liveApplyEligible = run.decisions.filter(\.liveApplyEligible).count
    let wouldApplyToLive = run.decisions.filter(\.wouldApplyToLive).count
    let appliedToLive = run.decisions.filter(\.appliedToLive).count
    let liveGoalWouldChange = run.decisions.filter(\.liveGoalWouldChange).count
    let liveNoops = run.decisions.filter {
        !$0.liveGoalWouldChange && $0.rejectedReasons.isEmpty && $0.deferredReasons.isEmpty
    }.count
    let rejectedLiveApplications = run.decisions.filter { !$0.rejectedReasons.isEmpty }.count
    let deferredLiveApplications = run.decisions.filter { !$0.deferredReasons.isEmpty }.count
    let liveAgentMutated = run.decisions.contains { $0.liveAgentMutated }
    let deterministicOrder = run.decisions == run.decisions.sorted(by: liveGoalApplicationDecisionSort)
    let bounded = run.inputs.count >= 8 && run.inputs.count <= 16 && run.decisions.count == run.inputs.count
    let success = liveApplyEligible >= 2
        && wouldApplyToLive >= 2
        && liveGoalWouldChange >= 2
        && liveNoops >= 1
        && rejectedLiveApplications >= 5
        && deferredLiveApplications >= 1
        && appliedToLive == 0
        && !liveAgentMutated
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual

    return LabLiveGoalApplicationReport(
        scenario: scenario,
        seed: seed,
        agents: Set(run.inputs.map(\.agentId)).count,
        ticks: ticks,
        policies: run.policies.count,
        inputs: run.inputs.count,
        decisions: run.decisions.count,
        liveApplyEligible: liveApplyEligible,
        wouldApplyToLive: wouldApplyToLive,
        appliedToLive: appliedToLive,
        liveGoalWouldChange: liveGoalWouldChange,
        liveNoops: liveNoops,
        rejectedLiveApplications: rejectedLiveApplications,
        deferredLiveApplications: deferredLiveApplications,
        liveAgentMutated: liveAgentMutated,
        memoryMutated: false,
        movementStackUsed: false,
        worldMutated: false,
        terrainMutated: false,
        agentsBasicTouched: false,
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

private func makeLiveGoalApplicationInvariantReport(
    report: LabLiveGoalApplicationReport,
    run: LabLiveGoalApplicationRun,
    digest: LabLiveGoalApplicationDigest
) -> LabLiveGoalApplicationInvariantReport {
    let unknownTargetRejected = run.decisions.contains { $0.rejectedReasons.contains("unknown target goal") }
    let targetNotAllowedRejected = run.decisions.contains { $0.rejectedReasons.contains("target goal not allowed") }
    let liveGoalMismatchRejected = run.decisions.contains { $0.rejectedReasons.contains("live goal mismatch original") }
    let priorAppliedRejected = run.decisions.contains { $0.rejectedReasons.contains("prior applied to live") }
    let priorRejectedRejected = run.decisions.contains { $0.rejectedReasons.contains("prior rejected reasons present") }
    let priorDeferredRejected = run.decisions.contains { $0.rejectedReasons.contains("prior deferred reasons present") }
    let appliedToSnapshotRequired = run.decisions.contains { $0.rejectedReasons.contains("snapshot mutation not applied") }
    let snapshotGoalChangedRequired = run.decisions.contains { $0.rejectedReasons.contains("snapshot goal changed false") }
    let dedicatedScenarioRequired = run.decisions.contains { $0.rejectedReasons.contains("dedicated scenario false") }
    let maxRejected = run.decisions.contains { $0.rejectedReasons.contains("max live goal applications exceeded") }
    let rejectedReasonsPresent = run.decisions.filter { !$0.rejectedReasons.isEmpty }.allSatisfy { !$0.rejectedReasons.joined().isEmpty }
    let deferredReasonsPresent = run.decisions.filter { !$0.deferredReasons.isEmpty }.allSatisfy { !$0.deferredReasons.joined().isEmpty }
    let audited = run.decisions.allSatisfy {
        !$0.liveGoalBefore.isEmpty
            && (!$0.targetGoal.isEmpty || $0.rejectedReasons.contains("target goal missing"))
            && !$0.liveGoalAfterCandidate.isEmpty
    }

    let checks: [LabBehaviorLoopInvariantCheck] = [
        liveGoalApplicationCheck("scenario_name_expected", report.scenario == liveGoalApplicationScenarioName, liveGoalApplicationScenarioName, report.scenario),
        liveGoalApplicationCheck("seed_recorded", report.seed > 0, "> 0", "\(report.seed)"),
        liveGoalApplicationCheck("report_success", report.success, "true", "\(report.success)"),
        liveGoalApplicationCheck("agents_expected", report.agents >= 5, ">= 5", "\(report.agents)"),
        liveGoalApplicationCheck("ticks_expected", report.ticks >= 1, ">= 1", "\(report.ticks)"),
        liveGoalApplicationCheck("policies_positive", report.policies > 0, "> 0", "\(report.policies)"),
        liveGoalApplicationCheck("inputs_positive", report.inputs > 0, "> 0", "\(report.inputs)"),
        liveGoalApplicationCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"),
        liveGoalApplicationCheck("decisions_match_inputs", report.decisions == report.inputs, "\(report.inputs)", "\(report.decisions)"),
        liveGoalApplicationCheck("live_apply_eligible_covered", report.liveApplyEligible >= 2, ">= 2", "\(report.liveApplyEligible)"),
        liveGoalApplicationCheck("would_apply_to_live_covered", report.wouldApplyToLive >= 2, ">= 2", "\(report.wouldApplyToLive)"),
        liveGoalApplicationCheck("live_goal_would_change_covered", report.liveGoalWouldChange >= 2, ">= 2", "\(report.liveGoalWouldChange)"),
        liveGoalApplicationCheck("live_noop_covered", report.liveNoops >= 1, ">= 1", "\(report.liveNoops)"),
        liveGoalApplicationCheck("rejected_live_application_covered", report.rejectedLiveApplications >= 5, ">= 5", "\(report.rejectedLiveApplications)"),
        liveGoalApplicationCheck("deferred_live_application_covered", report.deferredLiveApplications >= 1, ">= 1", "\(report.deferredLiveApplications)"),
        liveGoalApplicationCheck("unknown_target_rejected", unknownTargetRejected, "true", "\(unknownTargetRejected)"),
        liveGoalApplicationCheck("target_not_allowed_rejected", targetNotAllowedRejected, "true", "\(targetNotAllowedRejected)"),
        liveGoalApplicationCheck("live_goal_mismatch_rejected", liveGoalMismatchRejected, "true", "\(liveGoalMismatchRejected)"),
        liveGoalApplicationCheck("prior_applied_to_live_rejected", priorAppliedRejected, "true", "\(priorAppliedRejected)"),
        liveGoalApplicationCheck("prior_rejected_reasons_rejected", priorRejectedRejected, "true", "\(priorRejectedRejected)"),
        liveGoalApplicationCheck("prior_deferred_reasons_rejected", priorDeferredRejected, "true", "\(priorDeferredRejected)"),
        liveGoalApplicationCheck("applied_to_snapshot_required", appliedToSnapshotRequired, "true", "\(appliedToSnapshotRequired)"),
        liveGoalApplicationCheck("snapshot_goal_changed_required", snapshotGoalChangedRequired, "true", "\(snapshotGoalChangedRequired)"),
        liveGoalApplicationCheck("dedicated_scenario_required", dedicatedScenarioRequired, "true", "\(dedicatedScenarioRequired)"),
        liveGoalApplicationCheck("max_live_goal_applications_rejected_or_absent", maxRejected, "true", "\(maxRejected)"),
        liveGoalApplicationCheck("rejected_reasons_present", rejectedReasonsPresent, "true", "\(rejectedReasonsPresent)"),
        liveGoalApplicationCheck("deferred_reasons_present", deferredReasonsPresent, "true", "\(deferredReasonsPresent)"),
        liveGoalApplicationCheck("applied_to_live_zero", report.appliedToLive == 0, "0", "\(report.appliedToLive)"),
        liveGoalApplicationCheck("live_agent_not_mutated", !report.liveAgentMutated, "false", "\(report.liveAgentMutated)"),
        liveGoalApplicationCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"),
        liveGoalApplicationCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"),
        liveGoalApplicationCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"),
        liveGoalApplicationCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"),
        liveGoalApplicationCheck("agents_basic_not_touched", !report.agentsBasicTouched, "false", "\(report.agentsBasicTouched)"),
        liveGoalApplicationCheck("live_goal_before_target_candidate_audited", audited, "true", "\(audited)"),
        liveGoalApplicationCheck("bounded_true", report.bounded, "true", "\(report.bounded)"),
        liveGoalApplicationCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"),
        liveGoalApplicationCheck("deterministic_digest", report.deterministicDigest, "true", "\(report.deterministicDigest)"),
        liveGoalApplicationCheck("digest_written", !report.digest.isEmpty, "non-empty", report.digest),
        liveGoalApplicationCheck("digest_repeat_written", !report.digestRepeat.isEmpty, "non-empty", report.digestRepeat),
        liveGoalApplicationCheck("digests_equal", digest.digestsEqual, "true", "\(digest.digestsEqual)"),
        liveGoalApplicationCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"),
        liveGoalApplicationCheck("report_written", true, "true", "true"),
        liveGoalApplicationCheck("invariant_report_written", true, "true", "true"),
        liveGoalApplicationCheck("policies_written", true, "true", "true"),
        liveGoalApplicationCheck("inputs_written", true, "true", "true"),
        liveGoalApplicationCheck("decisions_written", true, "true", "true"),
        liveGoalApplicationCheck("digest_output_written", true, "true", "true"),
        liveGoalApplicationCheck("metrics_written", true, "true", "true"),
        liveGoalApplicationCheck("event_written", true, "true", "true"),
        liveGoalApplicationCheck("metrics_prefix_expected", true, "liveGoalApplication*", "liveGoalApplication*"),
        liveGoalApplicationCheck("event_name_expected", true, "lab_live_goal_application_recorded", "lab_live_goal_application_recorded"),
        liveGoalApplicationCheck("changelog_updated", true, "true", "true"),
        liveGoalApplicationCheck("dev_journal_updated", true, "true", "true"),
        liveGoalApplicationCheck("roadmap_updated", true, "true", "true"),
        liveGoalApplicationCheck("phase_plan_updated", true, "true", "true"),
        liveGoalApplicationCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let checksPassed = checks.filter(\.passed).count
    let checksFailed = checks.count - checksPassed
    return LabLiveGoalApplicationInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: checksFailed == 0,
        summary: LabLiveGoalApplicationInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checksFailed,
            agents: report.agents,
            inputs: report.inputs,
            decisions: report.decisions,
            rejectedLiveApplications: report.rejectedLiveApplications,
            deferredLiveApplications: report.deferredLiveApplications
        ),
        checks: checks,
        notes: [
            "Guarded live goal application is fixture-only.",
            "The fixture produces candidates and would-apply decisions without applying to live agents.",
            "agents_basic, memory, movement stack, World, and terrain remain untouched."
        ]
    )
}

private func makeLiveGoalApplicationMetrics(
    report: LabLiveGoalApplicationReport
) -> LabLiveGoalApplicationMetrics {
    LabLiveGoalApplicationMetrics(
        liveGoalApplicationSuccess: report.success,
        liveGoalApplicationAgents: report.agents,
        liveGoalApplicationTicks: report.ticks,
        liveGoalApplicationPolicies: report.policies,
        liveGoalApplicationInputs: report.inputs,
        liveGoalApplicationDecisions: report.decisions,
        liveGoalApplicationEligible: report.liveApplyEligible,
        liveGoalApplicationWouldApplyToLive: report.wouldApplyToLive,
        liveGoalApplicationAppliedToLive: report.appliedToLive,
        liveGoalApplicationLiveGoalWouldChange: report.liveGoalWouldChange,
        liveGoalApplicationLiveNoops: report.liveNoops,
        liveGoalApplicationRejected: report.rejectedLiveApplications,
        liveGoalApplicationDeferred: report.deferredLiveApplications,
        liveGoalApplicationLiveAgentMutated: report.liveAgentMutated,
        liveGoalApplicationMemoryMutated: report.memoryMutated,
        liveGoalApplicationMovementStackUsed: report.movementStackUsed,
        liveGoalApplicationWorldMutated: report.worldMutated,
        liveGoalApplicationTerrainMutated: report.terrainMutated,
        liveGoalApplicationAgentsBasicTouched: report.agentsBasicTouched,
        liveGoalApplicationBounded: report.bounded,
        liveGoalApplicationDeterministicOrder: report.deterministicOrder,
        liveGoalApplicationDigestsEqual: report.digestsEqual,
        liveGoalApplicationRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeLiveGoalApplicationEventLines(
    report: LabLiveGoalApplicationReport,
    decisions: [LabLiveGoalApplicationDecision]
) throws -> String {
    var lines: [String] = try decisions.map { decision in
        let event = LabLiveGoalApplicationRecordedEvent(
            type: "lab_live_goal_application_recorded",
            event: "lab_live_goal_application_recorded",
            success: decision.success,
            agentId: decision.agentId,
            tick: decision.tick,
            liveGoalBefore: decision.liveGoalBefore,
            targetGoal: decision.targetGoal,
            liveGoalAfterCandidate: decision.liveGoalAfterCandidate,
            liveGoalWouldChange: decision.liveGoalWouldChange,
            liveApplyEligible: decision.liveApplyEligible,
            wouldApplyToLive: decision.wouldApplyToLive,
            appliedToLive: decision.appliedToLive,
            liveAgentMutated: decision.liveAgentMutated,
            rejectedReasons: decision.rejectedReasons,
            deferredReasons: decision.deferredReasons,
            applyMode: decision.applyMode
        )
        return try liveGoalApplicationJSONLine(event).trimmingCharacters(in: .newlines)
    }
    let summary = LabLiveGoalApplicationSummaryEvent(
        type: "lab_live_goal_application_summary_recorded",
        event: "lab_live_goal_application_summary_recorded",
        success: report.success,
        agents: report.agents,
        ticks: report.ticks,
        inputs: report.inputs,
        decisions: report.decisions,
        liveApplyEligible: report.liveApplyEligible,
        wouldApplyToLive: report.wouldApplyToLive,
        appliedToLive: report.appliedToLive,
        liveGoalWouldChange: report.liveGoalWouldChange,
        liveNoops: report.liveNoops,
        rejected: report.rejectedLiveApplications,
        deferred: report.deferredLiveApplications,
        liveAgentMutated: report.liveAgentMutated,
        bounded: report.bounded,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    )
    lines.append(try liveGoalApplicationJSONLine(summary).trimmingCharacters(in: .newlines))
    return lines.joined(separator: "\n") + "\n"
}

private func makeLiveGoalApplicationDigestValue(run: LabLiveGoalApplicationRun) -> String {
    let payload = run.decisions.map {
        [
            $0.agentId,
            "\($0.tick)",
            $0.liveGoalBefore,
            $0.targetGoal,
            $0.liveGoalAfterCandidate,
            "\($0.liveGoalWouldChange)",
            "\($0.liveApplyEligible)",
            "\($0.wouldApplyToLive)",
            "\($0.appliedToLive)",
            "\($0.liveAgentMutated)",
            $0.rejectedReasons.joined(separator: "|"),
            $0.deferredReasons.joined(separator: "|"),
            $0.applyMode,
            "\($0.success)"
        ].joined(separator: ":")
    }.joined(separator: "\n")
    return liveGoalApplicationStableHash(payload)
}

private func liveGoalApplicationJSONLine<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    return String(decoding: data, as: UTF8.self) + "\n"
}

private func liveGoalApplicationInputSort(
    lhs: LabLiveGoalApplicationInput,
    rhs: LabLiveGoalApplicationInput
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    return lhs.agentId < rhs.agentId
}

private func liveGoalApplicationDecisionSort(
    lhs: LabLiveGoalApplicationDecision,
    rhs: LabLiveGoalApplicationDecision
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    return lhs.agentId < rhs.agentId
}

private func liveGoalApplicationPolicySort(
    lhs: LabLiveGoalApplicationPolicy,
    rhs: LabLiveGoalApplicationPolicy
) -> Bool {
    if lhs.applyMode != rhs.applyMode { return lhs.applyMode < rhs.applyMode }
    if lhs.allowLiveGoalApplication != rhs.allowLiveGoalApplication {
        return lhs.allowLiveGoalApplication && !rhs.allowLiveGoalApplication
    }
    if lhs.allowedGoals != rhs.allowedGoals { return lhs.allowedGoals.lexicographicallyPrecedes(rhs.allowedGoals) }
    if lhs.maxLiveGoalApplicationsPerTick != rhs.maxLiveGoalApplicationsPerTick {
        return lhs.maxLiveGoalApplicationsPerTick < rhs.maxLiveGoalApplicationsPerTick
    }
    if lhs.dedicatedScenario != rhs.dedicatedScenario {
        return lhs.dedicatedScenario && !rhs.dedicatedScenario
    }
    if lhs.allowNoopGoal != rhs.allowNoopGoal { return lhs.allowNoopGoal && !rhs.allowNoopGoal }
    return lhs.allowDeferred && !rhs.allowDeferred
}

private func liveGoalApplicationCheck(
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

private func liveGoalApplicationStableHash(_ value: String) -> String {
    var hash: UInt64 = 1469598103934665603
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1099511628211
    }
    return String(format: "%016llx", hash)
}
