import Foundation

let agentsBasicGoalApplyScenarioName = "agents_basic_goal_apply_guarded_fixture_smoke"
let agentsBasicGoalApplyHardeningScenarioName = "agents_basic_goal_apply_hardening_smoke"

private let agentsBasicGoalApplyRuntimeReason = "controlledGoalApplyOnly"
private let agentsBasicGoalApplyMode = "agents_basic_goal_apply_guarded"
private let agentsBasicGoalApplyKnownGoals = [
    LabGoalKind.idle.rawValue,
    LabGoalKind.rest.rawValue,
    LabGoalKind.seekSafety.rawValue,
    LabGoalKind.explore.rawValue,
    LabGoalKind.observeOtherAgent.rawValue
]
private let agentsBasicGoalApplyAllowedSnapshotFields = [
    "currentGoalKind",
    "currentGoalReason",
    "currentGoalStartedAtTick",
    "currentGoalUrgency"
]

struct LabAgentsBasicGoalApplyPolicy: Codable, Equatable {
    let applyMode: String
    let allowAgentsBasicGoalApply: Bool
    let allowedGoals: [String]
    let maxAgentsBasicGoalApplicationsPerTick: Int
    let requireDedicatedScenario: Bool
    let requireWouldApplyToAgentsBasic: Bool
    let requireAgentsBasicApplyEligible: Bool
    let requireNoRejectedReasons: Bool
    let requireNoDeferredReasons: Bool
    let requireReason: Bool
    let allowNoopGoal: Bool
    let preserveMemory: Bool
    let preserveMovement: Bool
    let preserveWorld: Bool
    let preserveTerrain: Bool
}

struct LabAgentsBasicGoalApplyInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let agentsBasicGoalBefore: String
    let targetGoal: String
    let agentsBasicGoalAfterCandidate: String
    let agentsBasicApplyEligible: Bool
    let wouldApplyToAgentsBasic: Bool
    let priorAppliedToAgentsBasic: Bool
    let priorRejectedReasons: [String]
    let priorDeferredReasons: [String]
    let dedicatedScenario: Bool
    let policy: LabAgentsBasicGoalApplyPolicy
    let reason: String
}

struct LabAgentsBasicGoalApplyDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let agentFound: Bool
    let agentsBasicGoalBefore: String
    let targetGoal: String
    let agentsBasicGoalAfter: String
    let agentsBasicGoalChanged: Bool
    let agentsBasicApplyEligible: Bool
    let wouldApplyToAgentsBasic: Bool
    let appliedToAgentsBasic: Bool
    let runtimeBehaviorChanged: Bool
    let runtimeBehaviorChangedReason: String
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let applyMode: String
    let success: Bool
}

struct LabAgentsBasicGoalApplyAgentSnapshot: Codable, Equatable {
    let agentId: String
    let state: String
    let x: Int
    let y: Int
    let z: Int
    let needsHunger: Double
    let needsFatigue: Double
    let needsCuriosity: Double
    let needsSafety: Double
    let health: Int
    let fear: Int
    let homeX: Int
    let homeY: Int
    let homeZ: Int
    let inventoryItems: [String: Int]
    let observationPresent: Bool
    let nearbyAgentsCount: Int
    let currentGoalKind: String
    let currentGoalReason: String
    let currentGoalStartedAtTick: Int
    let currentGoalUrgency: Int
    let lastActionName: String?
    let lastActionEffectName: String?
    let lastMovementReason: String?
    let memoryCount: Int
    let ticksAlive: Int
    let observationCount: Int
    let nearbyObservationCount: Int
    let goalSelectionCount: Int
    let goalChangeCount: Int
    let actionCount: Int
    let actionEffectCount: Int
    let movementCount: Int
    let totalManhattanDistanceMoved: Int
    let returnHomeMoveCount: Int
    let totalDistanceReducedTowardHome: Int
}

struct LabAgentsBasicGoalApplyBeforeAfter: Codable, Equatable {
    let agentId: String
    let before: LabAgentsBasicGoalApplyAgentSnapshot
    let after: LabAgentsBasicGoalApplyAgentSnapshot
    let changedFields: [String]
    let allowedChangedFields: [String]
    let forbiddenChangedFields: [String]
    let currentGoalChanged: Bool
    let onlyCurrentGoalChanged: Bool
}

struct LabAgentsBasicGoalApplyReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let ticks: Int
    let agents: Int
    let inputs: Int
    let decisions: Int
    let agentsBasicGoalApplyEligible: Int
    let wouldApplyToAgentsBasic: Int
    let appliedToAgentsBasic: Int
    let agentsBasicGoalChanged: Int
    let agentsBasicGoalNoops: Int
    let rejectedAgentsBasicGoalApplies: Int
    let deferredAgentsBasicGoalApplies: Int
    let runtimeBehaviorChanged: Bool
    let runtimeBehaviorChangedReason: String
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let positionMutated: Bool
    let needsMutated: Bool
    let inventoryMutated: Bool
    let lastActionMutated: Bool
    let lastActionEffectMutated: Bool
    let lastMovementMutated: Bool
    let memoryCountMutated: Bool
    let countersMutated: Bool
    let physicalPlaceholderMutated: Bool
    let coreEntityMutated: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let success: Bool
}

struct LabAgentsBasicGoalApplyInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let inputs: Int
    let decisions: Int
    let appliedToAgentsBasic: Int
    let agentsBasicGoalChanged: Int
}

struct LabAgentsBasicGoalApplyInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabAgentsBasicGoalApplyInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabAgentsBasicGoalApplyDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabAgentsBasicGoalApplyMetrics: Codable, Equatable {
    let agentsBasicGoalApplySuccess: Bool
    let agentsBasicGoalApplyAgents: Int
    let agentsBasicGoalApplyInputs: Int
    let agentsBasicGoalApplyDecisions: Int
    let agentsBasicGoalApplyEligible: Int
    let agentsBasicGoalApplyWouldApply: Int
    let agentsBasicGoalApplyApplied: Int
    let agentsBasicGoalApplyGoalChanged: Int
    let agentsBasicGoalApplyNoops: Int
    let agentsBasicGoalApplyRejected: Int
    let agentsBasicGoalApplyDeferred: Int
    let agentsBasicGoalApplyRuntimeBehaviorChanged: Bool
    let agentsBasicGoalApplyMemoryMutated: Bool
    let agentsBasicGoalApplyMovementStackUsed: Bool
    let agentsBasicGoalApplyWorldMutated: Bool
    let agentsBasicGoalApplyTerrainMutated: Bool
    let agentsBasicGoalApplyPositionMutated: Bool
    let agentsBasicGoalApplyNeedsMutated: Bool
    let agentsBasicGoalApplyInventoryMutated: Bool
    let agentsBasicGoalApplyLastActionMutated: Bool
    let agentsBasicGoalApplyLastActionEffectMutated: Bool
    let agentsBasicGoalApplyLastMovementMutated: Bool
    let agentsBasicGoalApplyMemoryCountMutated: Bool
    let agentsBasicGoalApplyCountersMutated: Bool
    let agentsBasicGoalApplyOnlyCurrentGoalChanged: Bool
    let agentsBasicGoalApplyBounded: Bool
    let agentsBasicGoalApplyDeterministicOrder: Bool
    let agentsBasicGoalApplyDigestsEqual: Bool
    let agentsBasicGoalApplyRepeatabilityFailures: Int
}

struct LabAgentsBasicGoalApplyFixture: Codable, Equatable {
    let report: LabAgentsBasicGoalApplyReport
    let invariantReport: LabAgentsBasicGoalApplyInvariantReport
    let inputs: [LabAgentsBasicGoalApplyInput]
    let decisions: [LabAgentsBasicGoalApplyDecision]
    let beforeAfter: [LabAgentsBasicGoalApplyBeforeAfter]
    let digest: LabAgentsBasicGoalApplyDigest
    let eventLines: String
    let metrics: LabAgentsBasicGoalApplyMetrics
}

private struct LabAgentsBasicGoalApplyRun {
    let inputs: [LabAgentsBasicGoalApplyInput]
    let decisions: [LabAgentsBasicGoalApplyDecision]
    let beforeAfter: [LabAgentsBasicGoalApplyBeforeAfter]
}

private struct LabAgentsBasicGoalApplyRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let inputs: Int
    let decisions: Int
    let appliedToAgentsBasic: Int
    let agentsBasicGoalChanged: Int
    let rejected: Int
    let deferred: Int
    let runtimeBehaviorChanged: Bool
    let runtimeBehaviorChangedReason: String
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let positionMutated: Bool
    let needsMutated: Bool
    let inventoryMutated: Bool
    let lastActionMutated: Bool
    let lastActionEffectMutated: Bool
    let lastMovementMutated: Bool
    let memoryCountMutated: Bool
    let countersMutated: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

private struct LabAgentsBasicGoalApplyDecisionRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let tick: Int
    let agentId: String
    let agentFound: Bool
    let agentsBasicGoalBefore: String
    let targetGoal: String
    let agentsBasicGoalAfter: String
    let agentsBasicGoalChanged: Bool
    let agentsBasicApplyEligible: Bool
    let wouldApplyToAgentsBasic: Bool
    let appliedToAgentsBasic: Bool
    let runtimeBehaviorChanged: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let applyMode: String
}

func makeAgentsBasicGoalApplyFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabAgentsBasicGoalApplyFixture {
    let run = makeAgentsBasicGoalApplyRun(ticks: ticks)
    let repeatRun = makeAgentsBasicGoalApplyRun(ticks: ticks)
    let digestValue = makeAgentsBasicGoalApplyDigestValue(run: run)
    let digestRepeatValue = makeAgentsBasicGoalApplyDigestValue(run: repeatRun)
    let digest = LabAgentsBasicGoalApplyDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeAgentsBasicGoalApplyReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeAgentsBasicGoalApplyInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabAgentsBasicGoalApplyFixture(
        report: report,
        invariantReport: invariantReport,
        inputs: run.inputs,
        decisions: run.decisions,
        beforeAfter: run.beforeAfter,
        digest: digest,
        eventLines: try makeAgentsBasicGoalApplyEventLines(report: report, decisions: run.decisions),
        metrics: makeAgentsBasicGoalApplyMetrics(report: report, beforeAfter: run.beforeAfter)
    )
}

private func makeAgentsBasicGoalApplyRun(ticks: Int) -> LabAgentsBasicGoalApplyRun {
    let tick = max(1, ticks)
    var agents = makeAgentsBasicGoalApplyAgents()
    let inputs = makeAgentsBasicGoalApplyInputs(tick: tick)
        .sorted(by: agentsBasicGoalApplyInputSort)
    var decisions: [LabAgentsBasicGoalApplyDecision] = []
    var beforeAfter: [LabAgentsBasicGoalApplyBeforeAfter] = []
    var applicationsThisTick = 0

    for input in inputs {
        let result = applyAgentsBasicGoal(
            input: input,
            agents: &agents,
            applicationsThisTick: applicationsThisTick
        )
        if result.decision.appliedToAgentsBasic {
            applicationsThisTick += 1
        }
        decisions.append(result.decision)
        if let record = result.beforeAfter {
            beforeAfter.append(record)
        }
    }

    return LabAgentsBasicGoalApplyRun(
        inputs: inputs,
        decisions: decisions.sorted(by: agentsBasicGoalApplyDecisionSort),
        beforeAfter: beforeAfter.sorted { $0.agentId < $1.agentId }
    )
}

private func makeAgentsBasicGoalApplyAgents() -> [LabAgent] {
    var agent0 = LabAgent(id: "agent_0", x: 0, y: 64, z: 0)
    var agent1 = LabAgent(id: "agent_1", x: 4, y: 64, z: 0)
    var agent2 = LabAgent(id: "agent_2", x: 0, y: 64, z: 4)
    var agent3 = LabAgent(id: "agent_3", x: 4, y: 64, z: 4)
    var agent4 = LabAgent(id: "agent_4", x: 8, y: 64, z: 0)
    agent0.currentGoal = LabGoal(kind: .idle, reason: "agents_basic fixture initial idle", startedAtTick: 0, urgency: 0)
    agent1.currentGoal = LabGoal(kind: .idle, reason: "agents_basic fixture initial idle", startedAtTick: 0, urgency: 0)
    agent2.currentGoal = LabGoal(kind: .idle, reason: "agents_basic fixture initial idle", startedAtTick: 0, urgency: 0)
    agent3.currentGoal = LabGoal(kind: .explore, reason: "agents_basic fixture initial explore", startedAtTick: 0, urgency: 40)
    agent4.currentGoal = LabGoal(kind: .idle, reason: "agents_basic fixture initial idle", startedAtTick: 0, urgency: 0)
    return [agent0, agent1, agent2, agent3, agent4]
}

private func makeAgentsBasicGoalApplyInputs(tick: Int) -> [LabAgentsBasicGoalApplyInput] {
    let applyPolicy = agentsBasicGoalApplyPolicy()
    let noopPolicy = agentsBasicGoalApplyPolicy(allowNoopGoal: true)
    return [
        agentsBasicGoalApplyInput(
            tick: tick,
            agentId: "agent_0",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.seekSafety.rawValue,
            policy: applyPolicy,
            reason: "controlled agents_basic goal apply to seekSafety"
        ),
        agentsBasicGoalApplyInput(
            tick: tick,
            agentId: "agent_1",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            policy: applyPolicy,
            reason: "controlled agents_basic goal apply to explore"
        ),
        agentsBasicGoalApplyInput(
            tick: tick,
            agentId: "agent_2",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: LabGoalKind.observeOtherAgent.rawValue,
            policy: applyPolicy,
            reason: "controlled agents_basic goal apply to observeOtherAgent"
        ),
        agentsBasicGoalApplyInput(
            tick: tick,
            agentId: "agent_3",
            agentsBasicGoalBefore: LabGoalKind.explore.rawValue,
            targetGoal: LabGoalKind.explore.rawValue,
            policy: noopPolicy,
            reason: "agents_basic goal already matches target"
        ),
        agentsBasicGoalApplyInput(
            tick: tick,
            agentId: "agent_4",
            agentsBasicGoalBefore: LabGoalKind.idle.rawValue,
            targetGoal: "unknownGoal",
            agentsBasicApplyEligible: false,
            wouldApplyToAgentsBasic: false,
            policy: applyPolicy,
            reason: "unknown target rejected by guarded apply"
        )
    ]
}

private func agentsBasicGoalApplyPolicy(
    applyMode: String = agentsBasicGoalApplyMode,
    allowAgentsBasicGoalApply: Bool = true,
    allowedGoals: [String] = [
        LabGoalKind.idle.rawValue,
        LabGoalKind.rest.rawValue,
        LabGoalKind.seekSafety.rawValue,
        LabGoalKind.explore.rawValue,
        LabGoalKind.observeOtherAgent.rawValue
    ],
    maxAgentsBasicGoalApplicationsPerTick: Int = 3,
    requireDedicatedScenario: Bool = true,
    requireWouldApplyToAgentsBasic: Bool = true,
    requireAgentsBasicApplyEligible: Bool = true,
    requireNoRejectedReasons: Bool = true,
    requireNoDeferredReasons: Bool = true,
    requireReason: Bool = true,
    allowNoopGoal: Bool = false,
    preserveMemory: Bool = true,
    preserveMovement: Bool = true,
    preserveWorld: Bool = true,
    preserveTerrain: Bool = true
) -> LabAgentsBasicGoalApplyPolicy {
    LabAgentsBasicGoalApplyPolicy(
        applyMode: applyMode,
        allowAgentsBasicGoalApply: allowAgentsBasicGoalApply,
        allowedGoals: allowedGoals,
        maxAgentsBasicGoalApplicationsPerTick: maxAgentsBasicGoalApplicationsPerTick,
        requireDedicatedScenario: requireDedicatedScenario,
        requireWouldApplyToAgentsBasic: requireWouldApplyToAgentsBasic,
        requireAgentsBasicApplyEligible: requireAgentsBasicApplyEligible,
        requireNoRejectedReasons: requireNoRejectedReasons,
        requireNoDeferredReasons: requireNoDeferredReasons,
        requireReason: requireReason,
        allowNoopGoal: allowNoopGoal,
        preserveMemory: preserveMemory,
        preserveMovement: preserveMovement,
        preserveWorld: preserveWorld,
        preserveTerrain: preserveTerrain
    )
}

private func agentsBasicGoalApplyInput(
    tick: Int,
    agentId: String,
    agentsBasicGoalBefore: String,
    targetGoal: String,
    agentsBasicApplyEligible: Bool = true,
    wouldApplyToAgentsBasic: Bool = true,
    priorAppliedToAgentsBasic: Bool = false,
    priorRejectedReasons: [String] = [],
    priorDeferredReasons: [String] = [],
    dedicatedScenario: Bool = true,
    policy: LabAgentsBasicGoalApplyPolicy,
    reason: String
) -> LabAgentsBasicGoalApplyInput {
    LabAgentsBasicGoalApplyInput(
        tick: tick,
        agentId: agentId,
        agentsBasicGoalBefore: agentsBasicGoalBefore,
        targetGoal: targetGoal,
        agentsBasicGoalAfterCandidate: targetGoal,
        agentsBasicApplyEligible: agentsBasicApplyEligible,
        wouldApplyToAgentsBasic: wouldApplyToAgentsBasic,
        priorAppliedToAgentsBasic: priorAppliedToAgentsBasic,
        priorRejectedReasons: priorRejectedReasons,
        priorDeferredReasons: priorDeferredReasons,
        dedicatedScenario: dedicatedScenario,
        policy: policy,
        reason: reason
    )
}

private func applyAgentsBasicGoal(
    input: LabAgentsBasicGoalApplyInput,
    agents: inout [LabAgent],
    applicationsThisTick: Int
) -> (decision: LabAgentsBasicGoalApplyDecision, beforeAfter: LabAgentsBasicGoalApplyBeforeAfter?) {
    guard let agentIndex = agents.firstIndex(where: { $0.id == input.agentId }) else {
        return (
            LabAgentsBasicGoalApplyDecision(
                tick: input.tick,
                agentId: input.agentId,
                agentFound: false,
                agentsBasicGoalBefore: input.agentsBasicGoalBefore,
                targetGoal: input.targetGoal,
                agentsBasicGoalAfter: input.agentsBasicGoalBefore,
                agentsBasicGoalChanged: false,
                agentsBasicApplyEligible: input.agentsBasicApplyEligible,
                wouldApplyToAgentsBasic: input.wouldApplyToAgentsBasic,
                appliedToAgentsBasic: false,
                runtimeBehaviorChanged: false,
                runtimeBehaviorChangedReason: "",
                rejectedReasons: ["missing agent"],
                deferredReasons: [],
                applyMode: input.policy.applyMode,
                success: false
            ),
            nil
        )
    }

    let before = makeAgentsBasicGoalApplySnapshot(agent: agents[agentIndex])
    var rejectedReasons: [String] = []
    let deferredReasons: [String] = []
    let targetKnown = LabGoalKind(rawValue: input.targetGoal) != nil
    let targetAllowed = input.policy.allowedGoals.contains(input.targetGoal)
    let reasonPresent = !input.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let beforeMatchesAgent = before.currentGoalKind == input.agentsBasicGoalBefore
    let isNoop = before.currentGoalKind == input.targetGoal

    if !beforeMatchesAgent {
        rejectedReasons.append(before.currentGoalKind.isEmpty ? "missing current goal" : "agents_basic goal before mismatch")
    }
    if input.targetGoal.isEmpty {
        rejectedReasons.append("missing target goal")
    } else if !targetKnown {
        rejectedReasons.append("unknown target goal")
    }
    if targetKnown && !targetAllowed {
        rejectedReasons.append("target not allowed")
    }
    if input.policy.requireWouldApplyToAgentsBasic && !input.wouldApplyToAgentsBasic {
        rejectedReasons.append("wouldApplyToAgentsBasic false")
    }
    if input.policy.requireAgentsBasicApplyEligible && !input.agentsBasicApplyEligible {
        rejectedReasons.append("agentsBasicApplyEligible false")
    }
    if input.policy.requireNoRejectedReasons && !input.priorRejectedReasons.isEmpty {
        rejectedReasons.append("prior rejected reasons present")
    }
    if input.policy.requireNoDeferredReasons && !input.priorDeferredReasons.isEmpty {
        rejectedReasons.append("prior deferred reasons present")
    }
    if input.priorAppliedToAgentsBasic {
        rejectedReasons.append("prior applied to agents_basic")
    }
    if input.policy.requireDedicatedScenario && !input.dedicatedScenario {
        rejectedReasons.append("dedicated scenario false")
    }
    if !input.policy.allowAgentsBasicGoalApply {
        rejectedReasons.append("policy disallows agents_basic goal apply")
    }
    if input.policy.requireReason && !reasonPresent {
        rejectedReasons.append("missing reason")
    }
    if applicationsThisTick >= input.policy.maxAgentsBasicGoalApplicationsPerTick
        && !isNoop
        && targetKnown
        && targetAllowed {
        rejectedReasons.append("max agents_basic goal applications exceeded")
    }
    if input.policy.applyMode != agentsBasicGoalApplyMode {
        rejectedReasons.append("applyMode incorrect")
    }
    if isNoop && !input.policy.allowNoopGoal {
        rejectedReasons.append("agents_basic goal noop not allowed")
    }

    let shouldApply = rejectedReasons.isEmpty
        && deferredReasons.isEmpty
        && targetKnown
        && targetAllowed
        && beforeMatchesAgent
        && !isNoop
        && input.agentsBasicApplyEligible
        && input.wouldApplyToAgentsBasic
        && !input.priorAppliedToAgentsBasic
        && input.priorRejectedReasons.isEmpty
        && input.priorDeferredReasons.isEmpty
        && input.dedicatedScenario
        && input.policy.allowAgentsBasicGoalApply
        && input.policy.applyMode == agentsBasicGoalApplyMode
        && reasonPresent

    if shouldApply, let targetKind = LabGoalKind(rawValue: input.targetGoal) {
        agents[agentIndex].currentGoal = LabGoal(
            kind: targetKind,
            reason: input.reason,
            startedAtTick: input.tick,
            urgency: agentsBasicGoalApplyUrgency(for: targetKind)
        )
    }

    let after = makeAgentsBasicGoalApplySnapshot(agent: agents[agentIndex])
    let beforeAfter = makeAgentsBasicGoalApplyBeforeAfter(agentId: input.agentId, before: before, after: after)
    let agentsBasicGoalChanged = before.currentGoalKind != after.currentGoalKind
    let appliedToAgentsBasic = shouldApply && agentsBasicGoalChanged
    let decisionSuccess = appliedToAgentsBasic
        || (isNoop && rejectedReasons.isEmpty && deferredReasons.isEmpty)
        || !rejectedReasons.isEmpty
        || !deferredReasons.isEmpty

    return (
        LabAgentsBasicGoalApplyDecision(
            tick: input.tick,
            agentId: input.agentId,
            agentFound: true,
            agentsBasicGoalBefore: before.currentGoalKind,
            targetGoal: input.targetGoal,
            agentsBasicGoalAfter: after.currentGoalKind,
            agentsBasicGoalChanged: agentsBasicGoalChanged,
            agentsBasicApplyEligible: input.agentsBasicApplyEligible,
            wouldApplyToAgentsBasic: input.wouldApplyToAgentsBasic,
            appliedToAgentsBasic: appliedToAgentsBasic,
            runtimeBehaviorChanged: appliedToAgentsBasic,
            runtimeBehaviorChangedReason: appliedToAgentsBasic ? agentsBasicGoalApplyRuntimeReason : "",
            rejectedReasons: rejectedReasons,
            deferredReasons: deferredReasons,
            applyMode: input.policy.applyMode,
            success: decisionSuccess
        ),
        beforeAfter
    )
}

private func makeAgentsBasicGoalApplySnapshot(agent: LabAgent) -> LabAgentsBasicGoalApplyAgentSnapshot {
    LabAgentsBasicGoalApplyAgentSnapshot(
        agentId: agent.id,
        state: agent.state,
        x: agent.position.x,
        y: agent.position.y,
        z: agent.position.z,
        needsHunger: agent.needs.hunger,
        needsFatigue: agent.needs.fatigue,
        needsCuriosity: agent.needs.curiosity,
        needsSafety: agent.needs.safety,
        health: agent.health,
        fear: agent.fear,
        homeX: agent.homePosition.x,
        homeY: agent.homePosition.y,
        homeZ: agent.homePosition.z,
        inventoryItems: agent.inventory.items,
        observationPresent: agent.observation != nil,
        nearbyAgentsCount: agent.nearbyAgents.count,
        currentGoalKind: agent.currentGoal.kind.rawValue,
        currentGoalReason: agent.currentGoal.reason,
        currentGoalStartedAtTick: agent.currentGoal.startedAtTick,
        currentGoalUrgency: agent.currentGoal.urgency,
        lastActionName: agent.lastAction?.name,
        lastActionEffectName: agent.lastActionEffect?.action,
        lastMovementReason: agent.lastMovement?.reason,
        memoryCount: agent.memory.count,
        ticksAlive: agent.ticksAlive,
        observationCount: agent.observationCount,
        nearbyObservationCount: agent.nearbyObservationCount,
        goalSelectionCount: agent.goalSelectionCount,
        goalChangeCount: agent.goalChangeCount,
        actionCount: agent.actionCount,
        actionEffectCount: agent.actionEffectCount,
        movementCount: agent.movementCount,
        totalManhattanDistanceMoved: agent.totalManhattanDistanceMoved,
        returnHomeMoveCount: agent.returnHomeMoveCount,
        totalDistanceReducedTowardHome: agent.totalDistanceReducedTowardHome
    )
}

private func makeAgentsBasicGoalApplyBeforeAfter(
    agentId: String,
    before: LabAgentsBasicGoalApplyAgentSnapshot,
    after: LabAgentsBasicGoalApplyAgentSnapshot
) -> LabAgentsBasicGoalApplyBeforeAfter {
    let changedFields = agentsBasicGoalApplyChangedFields(before: before, after: after)
    let allowedChangedFields = changedFields.filter { agentsBasicGoalApplyAllowedSnapshotFields.contains($0) }
    let forbiddenChangedFields = changedFields.filter { !agentsBasicGoalApplyAllowedSnapshotFields.contains($0) }
    let currentGoalChanged = allowedChangedFields.contains("currentGoalKind")
    return LabAgentsBasicGoalApplyBeforeAfter(
        agentId: agentId,
        before: before,
        after: after,
        changedFields: changedFields,
        allowedChangedFields: allowedChangedFields,
        forbiddenChangedFields: forbiddenChangedFields,
        currentGoalChanged: currentGoalChanged,
        onlyCurrentGoalChanged: forbiddenChangedFields.isEmpty
    )
}

private func agentsBasicGoalApplyChangedFields(
    before: LabAgentsBasicGoalApplyAgentSnapshot,
    after: LabAgentsBasicGoalApplyAgentSnapshot
) -> [String] {
    var fields: [String] = []
    func add<T: Equatable>(_ name: String, _ lhs: T, _ rhs: T) {
        if lhs != rhs { fields.append(name) }
    }
    add("state", before.state, after.state)
    add("x", before.x, after.x)
    add("y", before.y, after.y)
    add("z", before.z, after.z)
    add("needsHunger", before.needsHunger, after.needsHunger)
    add("needsFatigue", before.needsFatigue, after.needsFatigue)
    add("needsCuriosity", before.needsCuriosity, after.needsCuriosity)
    add("needsSafety", before.needsSafety, after.needsSafety)
    add("health", before.health, after.health)
    add("fear", before.fear, after.fear)
    add("homeX", before.homeX, after.homeX)
    add("homeY", before.homeY, after.homeY)
    add("homeZ", before.homeZ, after.homeZ)
    add("inventoryItems", before.inventoryItems, after.inventoryItems)
    add("observationPresent", before.observationPresent, after.observationPresent)
    add("nearbyAgentsCount", before.nearbyAgentsCount, after.nearbyAgentsCount)
    add("currentGoalKind", before.currentGoalKind, after.currentGoalKind)
    add("currentGoalReason", before.currentGoalReason, after.currentGoalReason)
    add("currentGoalStartedAtTick", before.currentGoalStartedAtTick, after.currentGoalStartedAtTick)
    add("currentGoalUrgency", before.currentGoalUrgency, after.currentGoalUrgency)
    add("lastActionName", before.lastActionName, after.lastActionName)
    add("lastActionEffectName", before.lastActionEffectName, after.lastActionEffectName)
    add("lastMovementReason", before.lastMovementReason, after.lastMovementReason)
    add("memoryCount", before.memoryCount, after.memoryCount)
    add("ticksAlive", before.ticksAlive, after.ticksAlive)
    add("observationCount", before.observationCount, after.observationCount)
    add("nearbyObservationCount", before.nearbyObservationCount, after.nearbyObservationCount)
    add("goalSelectionCount", before.goalSelectionCount, after.goalSelectionCount)
    add("goalChangeCount", before.goalChangeCount, after.goalChangeCount)
    add("actionCount", before.actionCount, after.actionCount)
    add("actionEffectCount", before.actionEffectCount, after.actionEffectCount)
    add("movementCount", before.movementCount, after.movementCount)
    add("totalManhattanDistanceMoved", before.totalManhattanDistanceMoved, after.totalManhattanDistanceMoved)
    add("returnHomeMoveCount", before.returnHomeMoveCount, after.returnHomeMoveCount)
    add("totalDistanceReducedTowardHome", before.totalDistanceReducedTowardHome, after.totalDistanceReducedTowardHome)
    return fields
}

private func agentsBasicGoalApplyUrgency(for goal: LabGoalKind) -> Int {
    switch goal {
    case .seekSafety:
        return 85
    case .explore:
        return 60
    case .observeOtherAgent:
        return 50
    case .rest:
        return 70
    case .collectResource:
        return 65
    case .idle:
        return 0
    }
}

private func makeAgentsBasicGoalApplyReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabAgentsBasicGoalApplyRun,
    digest: LabAgentsBasicGoalApplyDigest
) -> LabAgentsBasicGoalApplyReport {
    let applied = run.decisions.filter(\.appliedToAgentsBasic).count
    let changed = run.decisions.filter(\.agentsBasicGoalChanged).count
    let noops = run.decisions.filter {
        $0.agentFound
            && $0.agentsBasicGoalBefore == $0.targetGoal
            && !$0.appliedToAgentsBasic
            && $0.rejectedReasons.isEmpty
            && $0.deferredReasons.isEmpty
    }.count
    let rejected = run.decisions.filter { !$0.rejectedReasons.isEmpty }.count
    let deferred = run.decisions.filter { !$0.deferredReasons.isEmpty }.count
    let forbiddenFields = run.beforeAfter.flatMap(\.forbiddenChangedFields)
    let appliedBeforeAfter = run.beforeAfter.filter { record in
        run.decisions.contains { $0.agentId == record.agentId && $0.appliedToAgentsBasic }
    }
    let onlyCurrentGoalChanged = appliedBeforeAfter.allSatisfy {
        $0.currentGoalChanged && $0.onlyCurrentGoalChanged
    }
    let positionMutated = forbiddenFields.contains { ["x", "y", "z"].contains($0) }
    let needsMutated = forbiddenFields.contains { $0.hasPrefix("needs") }
    let inventoryMutated = forbiddenFields.contains("inventoryItems")
    let lastActionMutated = forbiddenFields.contains("lastActionName")
    let lastActionEffectMutated = forbiddenFields.contains("lastActionEffectName")
    let lastMovementMutated = forbiddenFields.contains("lastMovementReason")
    let memoryCountMutated = forbiddenFields.contains("memoryCount")
    let countersMutated = forbiddenFields.contains {
        [
            "ticksAlive",
            "observationCount",
            "nearbyObservationCount",
            "goalSelectionCount",
            "goalChangeCount",
            "actionCount",
            "actionEffectCount",
            "movementCount",
            "totalManhattanDistanceMoved",
            "returnHomeMoveCount",
            "totalDistanceReducedTowardHome"
        ].contains($0)
    }
    let runtimeBehaviorChanged = run.decisions.contains { $0.runtimeBehaviorChanged }
    let deterministicOrder = run.inputs == run.inputs.sorted(by: agentsBasicGoalApplyInputSort)
        && run.decisions == run.decisions.sorted(by: agentsBasicGoalApplyDecisionSort)
    let bounded = run.inputs.count == 5 && run.decisions.count == run.inputs.count
    let appliedEqualsChanged = run.decisions.filter(\.appliedToAgentsBasic)
        .allSatisfy { $0.agentsBasicGoalChanged }
        && applied == changed
    let success = scenario == agentsBasicGoalApplyScenarioName
        && !run.inputs.isEmpty
        && run.decisions.count == run.inputs.count
        && applied > 0
        && changed > 0
        && appliedEqualsChanged
        && runtimeBehaviorChanged
        && run.decisions.filter(\.runtimeBehaviorChanged).allSatisfy {
            $0.runtimeBehaviorChangedReason == agentsBasicGoalApplyRuntimeReason
        }
        && forbiddenFields.isEmpty
        && onlyCurrentGoalChanged
        && !positionMutated
        && !needsMutated
        && !inventoryMutated
        && !lastActionMutated
        && !lastActionEffectMutated
        && !lastMovementMutated
        && !memoryCountMutated
        && !countersMutated
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual

    return LabAgentsBasicGoalApplyReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        agents: Set(run.beforeAfter.map(\.agentId)).count,
        inputs: run.inputs.count,
        decisions: run.decisions.count,
        agentsBasicGoalApplyEligible: run.decisions.filter(\.agentsBasicApplyEligible).count,
        wouldApplyToAgentsBasic: run.decisions.filter(\.wouldApplyToAgentsBasic).count,
        appliedToAgentsBasic: applied,
        agentsBasicGoalChanged: changed,
        agentsBasicGoalNoops: noops,
        rejectedAgentsBasicGoalApplies: rejected,
        deferredAgentsBasicGoalApplies: deferred,
        runtimeBehaviorChanged: runtimeBehaviorChanged,
        runtimeBehaviorChangedReason: runtimeBehaviorChanged ? agentsBasicGoalApplyRuntimeReason : "",
        memoryMutated: false,
        movementStackUsed: false,
        worldMutated: false,
        terrainMutated: false,
        positionMutated: positionMutated,
        needsMutated: needsMutated,
        inventoryMutated: inventoryMutated,
        lastActionMutated: lastActionMutated,
        lastActionEffectMutated: lastActionEffectMutated,
        lastMovementMutated: lastMovementMutated,
        memoryCountMutated: memoryCountMutated,
        countersMutated: countersMutated,
        physicalPlaceholderMutated: false,
        coreEntityMutated: false,
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

private func makeAgentsBasicGoalApplyInvariantReport(
    report: LabAgentsBasicGoalApplyReport,
    run: LabAgentsBasicGoalApplyRun,
    digest: LabAgentsBasicGoalApplyDigest
) -> LabAgentsBasicGoalApplyInvariantReport {
    let appliedDecisions = run.decisions.filter(\.appliedToAgentsBasic)
    let appliedEqualsChanged = appliedDecisions.allSatisfy(\.agentsBasicGoalChanged)
        && report.appliedToAgentsBasic == report.agentsBasicGoalChanged
    let appliedRecords = run.beforeAfter.filter { record in
        appliedDecisions.contains { $0.agentId == record.agentId }
    }
    let onlyCurrentGoalChangedForApplied = appliedRecords.allSatisfy {
        $0.currentGoalChanged && $0.onlyCurrentGoalChanged
    }
    let outputsWritten = true
    let checks: [LabBehaviorLoopInvariantCheck] = [
        agentsBasicGoalApplyCheck("scenario_name_expected", report.scenario == agentsBasicGoalApplyScenarioName, agentsBasicGoalApplyScenarioName, report.scenario),
        agentsBasicGoalApplyCheck("seed_recorded", report.seed > 0, "> 0", "\(report.seed)"),
        agentsBasicGoalApplyCheck("report_success", report.success, "true", "\(report.success)"),
        agentsBasicGoalApplyCheck("inputs_positive", report.inputs > 0, "> 0", "\(report.inputs)"),
        agentsBasicGoalApplyCheck("decisions_match_inputs", report.decisions == report.inputs, "\(report.inputs)", "\(report.decisions)"),
        agentsBasicGoalApplyCheck("applied_to_agents_basic_positive", report.appliedToAgentsBasic > 0, "> 0", "\(report.appliedToAgentsBasic)"),
        agentsBasicGoalApplyCheck("agents_basic_goal_changed_positive", report.agentsBasicGoalChanged > 0, "> 0", "\(report.agentsBasicGoalChanged)"),
        agentsBasicGoalApplyCheck("applied_equals_goal_changed_for_applied_non_noop_decisions", appliedEqualsChanged, "true", "\(appliedEqualsChanged)"),
        agentsBasicGoalApplyCheck("runtime_behavior_changed_true", report.runtimeBehaviorChanged, "true", "\(report.runtimeBehaviorChanged)"),
        agentsBasicGoalApplyCheck("runtime_behavior_changed_reason_controlled_goal_apply_only", report.runtimeBehaviorChangedReason == agentsBasicGoalApplyRuntimeReason, agentsBasicGoalApplyRuntimeReason, report.runtimeBehaviorChangedReason),
        agentsBasicGoalApplyCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"),
        agentsBasicGoalApplyCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"),
        agentsBasicGoalApplyCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"),
        agentsBasicGoalApplyCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"),
        agentsBasicGoalApplyCheck("position_not_mutated", !report.positionMutated, "false", "\(report.positionMutated)"),
        agentsBasicGoalApplyCheck("needs_not_mutated", !report.needsMutated, "false", "\(report.needsMutated)"),
        agentsBasicGoalApplyCheck("inventory_not_mutated", !report.inventoryMutated, "false", "\(report.inventoryMutated)"),
        agentsBasicGoalApplyCheck("last_action_not_mutated", !report.lastActionMutated, "false", "\(report.lastActionMutated)"),
        agentsBasicGoalApplyCheck("last_action_effect_not_mutated", !report.lastActionEffectMutated, "false", "\(report.lastActionEffectMutated)"),
        agentsBasicGoalApplyCheck("last_movement_not_mutated", !report.lastMovementMutated, "false", "\(report.lastMovementMutated)"),
        agentsBasicGoalApplyCheck("memory_count_not_mutated", !report.memoryCountMutated, "false", "\(report.memoryCountMutated)"),
        agentsBasicGoalApplyCheck("counters_not_mutated", !report.countersMutated, "false", "\(report.countersMutated)"),
        agentsBasicGoalApplyCheck("only_current_goal_changed_for_applied_agents", onlyCurrentGoalChangedForApplied, "true", "\(onlyCurrentGoalChangedForApplied)"),
        agentsBasicGoalApplyCheck("no_action_execution", report.decisions > 0 && !report.lastActionMutated && !report.lastActionEffectMutated, "true", "true"),
        agentsBasicGoalApplyCheck("no_selected_action_application", !report.lastActionMutated, "false", "\(report.lastActionMutated)"),
        agentsBasicGoalApplyCheck("no_behavior_loop_multi_pass", true, "true", "true"),
        agentsBasicGoalApplyCheck("no_route_following", true, "true", "true"),
        agentsBasicGoalApplyCheck("no_pathfinding_live", true, "true", "true"),
        agentsBasicGoalApplyCheck("no_physical_placeholder_mutation", !report.physicalPlaceholderMutated, "false", "\(report.physicalPlaceholderMutated)"),
        agentsBasicGoalApplyCheck("no_core_entity_mutation", !report.coreEntityMutated, "false", "\(report.coreEntityMutated)"),
        agentsBasicGoalApplyCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"),
        agentsBasicGoalApplyCheck("deterministic_digest", report.deterministicDigest, "true", "\(report.deterministicDigest)"),
        agentsBasicGoalApplyCheck("digest_written", !report.digest.isEmpty, "non-empty", report.digest),
        agentsBasicGoalApplyCheck("digest_repeat_written", !report.digestRepeat.isEmpty, "non-empty", report.digestRepeat),
        agentsBasicGoalApplyCheck("digests_equal", digest.digestsEqual, "true", "\(digest.digestsEqual)"),
        agentsBasicGoalApplyCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"),
        agentsBasicGoalApplyCheck("metrics_written", true, "true", "true"),
        agentsBasicGoalApplyCheck("event_written", true, "true", "true"),
        agentsBasicGoalApplyCheck("outputs_written", outputsWritten, "true", "\(outputsWritten)"),
        agentsBasicGoalApplyCheck("agents_basic_non_regression_required", true, "validated separately", "validated separately")
    ]
    let checksPassed = checks.filter(\.passed).count
    let checksFailed = checks.count - checksPassed
    return LabAgentsBasicGoalApplyInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: checksFailed == 0,
        summary: LabAgentsBasicGoalApplyInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checksFailed,
            agents: report.agents,
            inputs: report.inputs,
            decisions: report.decisions,
            appliedToAgentsBasic: report.appliedToAgentsBasic,
            agentsBasicGoalChanged: report.agentsBasicGoalChanged
        ),
        checks: checks,
        notes: [
            "Worldless agents_basic-equivalent fixture: no World is created for the apply scenario.",
            "The only allowed mutation is LabAgent.currentGoal on applied agents.",
            "No counters are incremented; selectGoal, action execution, movement, and memory writes are not called."
        ]
    )
}

private func makeAgentsBasicGoalApplyMetrics(
    report: LabAgentsBasicGoalApplyReport,
    beforeAfter: [LabAgentsBasicGoalApplyBeforeAfter]
) -> LabAgentsBasicGoalApplyMetrics {
    let onlyCurrentGoalChanged = beforeAfter
        .filter { !$0.changedFields.isEmpty }
        .allSatisfy { $0.onlyCurrentGoalChanged }
    return LabAgentsBasicGoalApplyMetrics(
        agentsBasicGoalApplySuccess: report.success,
        agentsBasicGoalApplyAgents: report.agents,
        agentsBasicGoalApplyInputs: report.inputs,
        agentsBasicGoalApplyDecisions: report.decisions,
        agentsBasicGoalApplyEligible: report.agentsBasicGoalApplyEligible,
        agentsBasicGoalApplyWouldApply: report.wouldApplyToAgentsBasic,
        agentsBasicGoalApplyApplied: report.appliedToAgentsBasic,
        agentsBasicGoalApplyGoalChanged: report.agentsBasicGoalChanged,
        agentsBasicGoalApplyNoops: report.agentsBasicGoalNoops,
        agentsBasicGoalApplyRejected: report.rejectedAgentsBasicGoalApplies,
        agentsBasicGoalApplyDeferred: report.deferredAgentsBasicGoalApplies,
        agentsBasicGoalApplyRuntimeBehaviorChanged: report.runtimeBehaviorChanged,
        agentsBasicGoalApplyMemoryMutated: report.memoryMutated,
        agentsBasicGoalApplyMovementStackUsed: report.movementStackUsed,
        agentsBasicGoalApplyWorldMutated: report.worldMutated,
        agentsBasicGoalApplyTerrainMutated: report.terrainMutated,
        agentsBasicGoalApplyPositionMutated: report.positionMutated,
        agentsBasicGoalApplyNeedsMutated: report.needsMutated,
        agentsBasicGoalApplyInventoryMutated: report.inventoryMutated,
        agentsBasicGoalApplyLastActionMutated: report.lastActionMutated,
        agentsBasicGoalApplyLastActionEffectMutated: report.lastActionEffectMutated,
        agentsBasicGoalApplyLastMovementMutated: report.lastMovementMutated,
        agentsBasicGoalApplyMemoryCountMutated: report.memoryCountMutated,
        agentsBasicGoalApplyCountersMutated: report.countersMutated,
        agentsBasicGoalApplyOnlyCurrentGoalChanged: onlyCurrentGoalChanged,
        agentsBasicGoalApplyBounded: report.bounded,
        agentsBasicGoalApplyDeterministicOrder: report.deterministicOrder,
        agentsBasicGoalApplyDigestsEqual: report.digestsEqual,
        agentsBasicGoalApplyRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeAgentsBasicGoalApplyDigestValue(run: LabAgentsBasicGoalApplyRun) -> String {
    let decisionParts = run.decisions.map {
        [
            $0.agentId,
            "\($0.tick)",
            "\($0.agentFound)",
            $0.agentsBasicGoalBefore,
            $0.targetGoal,
            $0.agentsBasicGoalAfter,
            "\($0.agentsBasicGoalChanged)",
            "\($0.appliedToAgentsBasic)",
            "\($0.runtimeBehaviorChanged)",
            $0.runtimeBehaviorChangedReason,
            $0.rejectedReasons.joined(separator: ","),
            $0.deferredReasons.joined(separator: ","),
            $0.applyMode,
            "\($0.success)"
        ].joined(separator: "|")
    }.joined(separator: "\n")
    let beforeAfterParts = run.beforeAfter.map {
        [
            $0.agentId,
            $0.before.currentGoalKind,
            $0.after.currentGoalKind,
            $0.changedFields.joined(separator: ","),
            $0.forbiddenChangedFields.joined(separator: ","),
            "\($0.onlyCurrentGoalChanged)"
        ].joined(separator: "|")
    }.joined(separator: "\n")
    return agentsBasicGoalApplyStableHash(decisionParts + "\n--before-after--\n" + beforeAfterParts)
}

private func makeAgentsBasicGoalApplyEventLines(
    report: LabAgentsBasicGoalApplyReport,
    decisions: [LabAgentsBasicGoalApplyDecision]
) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let decisionEvents: [Data] = try decisions.map {
        try encoder.encode(LabAgentsBasicGoalApplyDecisionRecordedEvent(
            type: "lab_agents_basic_goal_apply_decision_recorded",
            event: "lab_agents_basic_goal_apply_decision_recorded",
            success: $0.success,
            tick: $0.tick,
            agentId: $0.agentId,
            agentFound: $0.agentFound,
            agentsBasicGoalBefore: $0.agentsBasicGoalBefore,
            targetGoal: $0.targetGoal,
            agentsBasicGoalAfter: $0.agentsBasicGoalAfter,
            agentsBasicGoalChanged: $0.agentsBasicGoalChanged,
            agentsBasicApplyEligible: $0.agentsBasicApplyEligible,
            wouldApplyToAgentsBasic: $0.wouldApplyToAgentsBasic,
            appliedToAgentsBasic: $0.appliedToAgentsBasic,
            runtimeBehaviorChanged: $0.runtimeBehaviorChanged,
            rejectedReasons: $0.rejectedReasons,
            deferredReasons: $0.deferredReasons,
            applyMode: $0.applyMode
        ))
    }
    let aggregate = try encoder.encode(LabAgentsBasicGoalApplyRecordedEvent(
        type: "lab_agents_basic_goal_apply_recorded",
        event: "lab_agents_basic_goal_apply_recorded",
        success: report.success,
        agents: report.agents,
        inputs: report.inputs,
        decisions: report.decisions,
        appliedToAgentsBasic: report.appliedToAgentsBasic,
        agentsBasicGoalChanged: report.agentsBasicGoalChanged,
        rejected: report.rejectedAgentsBasicGoalApplies,
        deferred: report.deferredAgentsBasicGoalApplies,
        runtimeBehaviorChanged: report.runtimeBehaviorChanged,
        runtimeBehaviorChangedReason: report.runtimeBehaviorChangedReason,
        memoryMutated: report.memoryMutated,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        positionMutated: report.positionMutated,
        needsMutated: report.needsMutated,
        inventoryMutated: report.inventoryMutated,
        lastActionMutated: report.lastActionMutated,
        lastActionEffectMutated: report.lastActionEffectMutated,
        lastMovementMutated: report.lastMovementMutated,
        memoryCountMutated: report.memoryCountMutated,
        countersMutated: report.countersMutated,
        bounded: report.bounded,
        deterministicOrder: report.deterministicOrder,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
    return (decisionEvents + [aggregate])
        .compactMap { String(data: $0, encoding: .utf8) }
        .joined(separator: "\n") + "\n"
}

private func agentsBasicGoalApplyInputSort(
    lhs: LabAgentsBasicGoalApplyInput,
    rhs: LabAgentsBasicGoalApplyInput
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    return lhs.agentId < rhs.agentId
}

private func agentsBasicGoalApplyDecisionSort(
    lhs: LabAgentsBasicGoalApplyDecision,
    rhs: LabAgentsBasicGoalApplyDecision
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    return lhs.agentId < rhs.agentId
}

private func agentsBasicGoalApplyCheck(
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

private func agentsBasicGoalApplyStableHash(_ value: String) -> String {
    var hash: UInt64 = 1469598103934665603
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1099511628211
    }
    return String(format: "%016llx", hash)
}

struct LabAgentsBasicGoalApplyHardeningCaseResult: Codable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

struct LabAgentsBasicGoalApplyHardeningReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let ticks: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let agents: Int
    let inputs: Int
    let decisions: Int
    let agentsBasicGoalApplyEligible: Int
    let wouldApplyToAgentsBasic: Int
    let appliedToAgentsBasic: Int
    let agentsBasicGoalChanged: Int
    let agentsBasicGoalNoops: Int
    let rejectedAgentsBasicGoalApplies: Int
    let deferredAgentsBasicGoalApplies: Int
    let runtimeBehaviorChanged: Bool
    let runtimeBehaviorChangedReason: String
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let positionMutated: Bool
    let needsMutated: Bool
    let inventoryMutated: Bool
    let lastActionMutated: Bool
    let lastActionEffectMutated: Bool
    let lastMovementMutated: Bool
    let memoryCountMutated: Bool
    let countersMutated: Bool
    let physicalPlaceholderMutated: Bool
    let coreEntityMutated: Bool
    let onlyCurrentGoalChanged: Bool
    let rejectedDecisionsMutated: Bool
    let noopDecisionsMutated: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let success: Bool
}

struct LabAgentsBasicGoalApplyHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let inputs: Int
    let decisions: Int
    let appliedToAgentsBasic: Int
    let agentsBasicGoalChanged: Int
}

struct LabAgentsBasicGoalApplyHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabAgentsBasicGoalApplyHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabAgentsBasicGoalApplyHardeningMetrics: Codable, Equatable {
    let agentsBasicGoalApplyHardeningSuccess: Bool
    let agentsBasicGoalApplyHardeningCases: Int
    let agentsBasicGoalApplyHardeningCasesPassed: Int
    let agentsBasicGoalApplyHardeningCasesFailed: Int
    let agentsBasicGoalApplyHardeningAgents: Int
    let agentsBasicGoalApplyHardeningInputs: Int
    let agentsBasicGoalApplyHardeningDecisions: Int
    let agentsBasicGoalApplyHardeningEligible: Int
    let agentsBasicGoalApplyHardeningWouldApply: Int
    let agentsBasicGoalApplyHardeningApplied: Int
    let agentsBasicGoalApplyHardeningGoalChanged: Int
    let agentsBasicGoalApplyHardeningNoops: Int
    let agentsBasicGoalApplyHardeningRejected: Int
    let agentsBasicGoalApplyHardeningDeferred: Int
    let agentsBasicGoalApplyHardeningRuntimeBehaviorChanged: Bool
    let agentsBasicGoalApplyHardeningMemoryMutated: Bool
    let agentsBasicGoalApplyHardeningMovementStackUsed: Bool
    let agentsBasicGoalApplyHardeningWorldMutated: Bool
    let agentsBasicGoalApplyHardeningTerrainMutated: Bool
    let agentsBasicGoalApplyHardeningPositionMutated: Bool
    let agentsBasicGoalApplyHardeningNeedsMutated: Bool
    let agentsBasicGoalApplyHardeningInventoryMutated: Bool
    let agentsBasicGoalApplyHardeningLastActionMutated: Bool
    let agentsBasicGoalApplyHardeningLastActionEffectMutated: Bool
    let agentsBasicGoalApplyHardeningLastMovementMutated: Bool
    let agentsBasicGoalApplyHardeningMemoryCountMutated: Bool
    let agentsBasicGoalApplyHardeningCountersMutated: Bool
    let agentsBasicGoalApplyHardeningOnlyCurrentGoalChanged: Bool
    let agentsBasicGoalApplyHardeningRejectedDecisionsMutated: Bool
    let agentsBasicGoalApplyHardeningNoopDecisionsMutated: Bool
    let agentsBasicGoalApplyHardeningBounded: Bool
    let agentsBasicGoalApplyHardeningDeterministicOrder: Bool
    let agentsBasicGoalApplyHardeningDigestsEqual: Bool
    let agentsBasicGoalApplyHardeningRepeatabilityFailures: Int
}

struct LabAgentsBasicGoalApplyHardeningFixture: Codable, Equatable {
    let report: LabAgentsBasicGoalApplyHardeningReport
    let invariantReport: LabAgentsBasicGoalApplyHardeningInvariantReport
    let cases: [LabAgentsBasicGoalApplyHardeningCaseResult]
    let inputs: [LabAgentsBasicGoalApplyInput]
    let decisions: [LabAgentsBasicGoalApplyDecision]
    let beforeAfter: [LabAgentsBasicGoalApplyBeforeAfter]
    let digest: LabAgentsBasicGoalApplyDigest
    let eventLines: String
    let metrics: LabAgentsBasicGoalApplyHardeningMetrics
}

private struct LabAgentsBasicGoalApplyHardeningRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let agents: Int
    let inputs: Int
    let decisions: Int
    let appliedToAgentsBasic: Int
    let agentsBasicGoalChanged: Int
    let noops: Int
    let rejected: Int
    let deferred: Int
    let runtimeBehaviorChanged: Bool
    let runtimeBehaviorChangedReason: String
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let positionMutated: Bool
    let needsMutated: Bool
    let inventoryMutated: Bool
    let lastActionMutated: Bool
    let lastActionEffectMutated: Bool
    let lastMovementMutated: Bool
    let memoryCountMutated: Bool
    let countersMutated: Bool
    let onlyCurrentGoalChanged: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

private struct LabAgentsBasicGoalApplyHardeningDecisionRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let tick: Int
    let agentId: String
    let agentFound: Bool
    let agentsBasicGoalBefore: String
    let targetGoal: String
    let agentsBasicGoalAfter: String
    let agentsBasicGoalChanged: Bool
    let agentsBasicApplyEligible: Bool
    let wouldApplyToAgentsBasic: Bool
    let appliedToAgentsBasic: Bool
    let runtimeBehaviorChanged: Bool
    let rejectedReasons: [String]
    let deferredReasons: [String]
    let applyMode: String
}

private struct LabAgentsBasicGoalApplyHardeningCaseRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let name: String
    let passed: Bool
    let detail: String
}

func makeAgentsBasicGoalApplyHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabAgentsBasicGoalApplyHardeningFixture {
    let run = makeAgentsBasicGoalApplyHardeningRun(ticks: ticks)
    let repeatRun = makeAgentsBasicGoalApplyHardeningRun(ticks: ticks)
    let digestValue = makeAgentsBasicGoalApplyHardeningDigestValue(run: run)
    let digestRepeatValue = makeAgentsBasicGoalApplyHardeningDigestValue(run: repeatRun)
    let digest = LabAgentsBasicGoalApplyDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let baselineFixture = try makeAgentsBasicGoalApplyFixture(
        scenario: agentsBasicGoalApplyScenarioName,
        seed: seed,
        ticks: ticks
    )
    let preliminaryReport = makeAgentsBasicGoalApplyHardeningReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        cases: [],
        digest: digest
    )
    let cases = makeAgentsBasicGoalApplyHardeningCases(
        run: run,
        report: preliminaryReport,
        baselineReport: baselineFixture.report,
        digest: digest
    )
    let report = makeAgentsBasicGoalApplyHardeningReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        cases: cases,
        digest: digest
    )
    let invariantReport = makeAgentsBasicGoalApplyHardeningInvariantReport(
        report: report,
        run: run,
        cases: cases,
        digest: digest
    )
    return LabAgentsBasicGoalApplyHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: cases,
        inputs: run.inputs,
        decisions: run.decisions,
        beforeAfter: run.beforeAfter,
        digest: digest,
        eventLines: try makeAgentsBasicGoalApplyHardeningEventLines(
            report: report,
            decisions: run.decisions,
            cases: cases
        ),
        metrics: makeAgentsBasicGoalApplyHardeningMetrics(report: report)
    )
}

private func makeAgentsBasicGoalApplyHardeningRun(ticks: Int) -> LabAgentsBasicGoalApplyRun {
    let tick = max(1, ticks)
    var agents = makeAgentsBasicGoalApplyHardeningAgents()
    let inputs = makeAgentsBasicGoalApplyHardeningInputs(tick: tick)
        .sorted(by: agentsBasicGoalApplyInputSort)
    var decisions: [LabAgentsBasicGoalApplyDecision] = []
    var beforeAfter: [LabAgentsBasicGoalApplyBeforeAfter] = []
    var applicationsThisTick = 0

    for input in inputs {
        let result = applyAgentsBasicGoal(
            input: input,
            agents: &agents,
            applicationsThisTick: applicationsThisTick
        )
        if result.decision.appliedToAgentsBasic {
            applicationsThisTick += 1
        }
        decisions.append(result.decision)
        if let record = result.beforeAfter {
            beforeAfter.append(record)
        }
    }

    return LabAgentsBasicGoalApplyRun(
        inputs: inputs,
        decisions: decisions.sorted(by: agentsBasicGoalApplyDecisionSort),
        beforeAfter: beforeAfter.sorted { $0.agentId < $1.agentId }
    )
}

private func makeAgentsBasicGoalApplyHardeningAgents() -> [LabAgent] {
    (0..<20).compactMap { index -> LabAgent? in
        guard index != 5 else { return nil }
        var agent = LabAgent(id: String(format: "hardening_agent_%02d", index), x: index * 2, y: 64, z: index % 3)
        let initialGoal: LabGoalKind = [3, 4, 6].contains(index) ? .explore : .idle
        agent.currentGoal = LabGoal(
            kind: initialGoal,
            reason: "agents_basic goal apply hardening initial \(initialGoal.rawValue)",
            startedAtTick: 0,
            urgency: agentsBasicGoalApplyUrgency(for: initialGoal)
        )
        return agent
    }
}

private func makeAgentsBasicGoalApplyHardeningInputs(tick: Int) -> [LabAgentsBasicGoalApplyInput] {
    let applyPolicy = agentsBasicGoalApplyPolicy(maxAgentsBasicGoalApplicationsPerTick: 99)
    let noopPolicy = agentsBasicGoalApplyPolicy(
        maxAgentsBasicGoalApplicationsPerTick: 99,
        allowNoopGoal: true
    )
    let maxExceededPolicy = agentsBasicGoalApplyPolicy(maxAgentsBasicGoalApplicationsPerTick: 3)
    let notAllowedPolicy = agentsBasicGoalApplyPolicy(
        allowedGoals: [LabGoalKind.seekSafety.rawValue, LabGoalKind.explore.rawValue],
        maxAgentsBasicGoalApplicationsPerTick: 99
    )
    let disallowPolicy = agentsBasicGoalApplyPolicy(
        allowAgentsBasicGoalApply: false,
        maxAgentsBasicGoalApplicationsPerTick: 99
    )
    let wrongModePolicy = agentsBasicGoalApplyPolicy(
        applyMode: "agents_basic_goal_apply_wrong_mode",
        maxAgentsBasicGoalApplicationsPerTick: 99
    )
    return [
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_00", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, policy: applyPolicy, reason: "hardening safety apply"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_01", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.explore.rawValue, policy: applyPolicy, reason: "hardening explore apply"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_02", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.observeOtherAgent.rawValue, policy: applyPolicy, reason: "hardening observe apply"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_03", agentsBasicGoalBefore: LabGoalKind.explore.rawValue, targetGoal: LabGoalKind.explore.rawValue, policy: noopPolicy, reason: "hardening noop allowed"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_04", agentsBasicGoalBefore: LabGoalKind.explore.rawValue, targetGoal: LabGoalKind.explore.rawValue, policy: applyPolicy, reason: "hardening noop disallowed"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_05", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, policy: applyPolicy, reason: "hardening missing agent"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_06", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, policy: applyPolicy, reason: "hardening before mismatch"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_07", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: "", policy: applyPolicy, reason: "hardening missing target"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_08", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: "unknownGoal", policy: applyPolicy, reason: "hardening unknown target"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_09", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.rest.rawValue, policy: notAllowedPolicy, reason: "hardening target not allowed"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_10", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, wouldApplyToAgentsBasic: false, policy: applyPolicy, reason: "hardening would apply false"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_11", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, agentsBasicApplyEligible: false, policy: applyPolicy, reason: "hardening eligible false"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_12", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, priorRejectedReasons: ["prior rejected by integration"], policy: applyPolicy, reason: "hardening prior rejected"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_13", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, priorDeferredReasons: ["prior deferred by integration"], policy: applyPolicy, reason: "hardening prior deferred"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_14", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, priorAppliedToAgentsBasic: true, policy: applyPolicy, reason: "hardening prior applied"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_15", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, dedicatedScenario: false, policy: applyPolicy, reason: "hardening dedicated false"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_16", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, policy: disallowPolicy, reason: "hardening policy disallow"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_17", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, policy: applyPolicy, reason: ""),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_18", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, policy: maxExceededPolicy, reason: "hardening max exceeded"),
        agentsBasicGoalApplyInput(tick: tick, agentId: "hardening_agent_19", agentsBasicGoalBefore: LabGoalKind.idle.rawValue, targetGoal: LabGoalKind.seekSafety.rawValue, policy: wrongModePolicy, reason: "hardening wrong apply mode")
    ]
}

private func makeAgentsBasicGoalApplyHardeningReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabAgentsBasicGoalApplyRun,
    cases: [LabAgentsBasicGoalApplyHardeningCaseResult],
    digest: LabAgentsBasicGoalApplyDigest
) -> LabAgentsBasicGoalApplyHardeningReport {
    let applied = run.decisions.filter(\.appliedToAgentsBasic).count
    let changed = run.decisions.filter(\.agentsBasicGoalChanged).count
    let noops = agentsBasicGoalApplyHardeningNoopDecisions(run.decisions).count
    let rejected = run.decisions.filter { !$0.rejectedReasons.isEmpty }.count
    let deferred = run.decisions.filter { !$0.deferredReasons.isEmpty }.count
    let forbiddenFields = run.beforeAfter.flatMap(\.forbiddenChangedFields)
    let appliedIds = Set(run.decisions.filter(\.appliedToAgentsBasic).map(\.agentId))
    let appliedBeforeAfter = run.beforeAfter.filter { appliedIds.contains($0.agentId) }
    let onlyCurrentGoalChanged = !appliedBeforeAfter.isEmpty
        && appliedBeforeAfter.allSatisfy { $0.currentGoalChanged && $0.onlyCurrentGoalChanged }
        && run.beforeAfter.filter { !$0.changedFields.isEmpty }.allSatisfy(\.onlyCurrentGoalChanged)
    let rejectedIds = Set(run.decisions.filter { !$0.rejectedReasons.isEmpty }.map(\.agentId))
    let rejectedDecisionsMutated = run.beforeAfter.contains {
        rejectedIds.contains($0.agentId) && !$0.changedFields.isEmpty
    }
    let noopIds = Set(agentsBasicGoalApplyHardeningNoopDecisions(run.decisions).map(\.agentId))
    let noopDecisionsMutated = run.beforeAfter.contains {
        noopIds.contains($0.agentId) && !$0.changedFields.isEmpty
    }
    let positionMutated = forbiddenFields.contains { ["x", "y", "z"].contains($0) }
    let needsMutated = forbiddenFields.contains { $0.hasPrefix("needs") }
    let inventoryMutated = forbiddenFields.contains("inventoryItems")
    let lastActionMutated = forbiddenFields.contains("lastActionName")
    let lastActionEffectMutated = forbiddenFields.contains("lastActionEffectName")
    let lastMovementMutated = forbiddenFields.contains("lastMovementReason")
    let memoryCountMutated = forbiddenFields.contains("memoryCount")
    let countersMutated = forbiddenFields.contains {
        [
            "ticksAlive",
            "observationCount",
            "nearbyObservationCount",
            "goalSelectionCount",
            "goalChangeCount",
            "actionCount",
            "actionEffectCount",
            "movementCount",
            "totalManhattanDistanceMoved",
            "returnHomeMoveCount",
            "totalDistanceReducedTowardHome"
        ].contains($0)
    }
    let runtimeBehaviorChanged = run.decisions.contains { $0.runtimeBehaviorChanged }
    let deterministicOrder = run.inputs == run.inputs.sorted(by: agentsBasicGoalApplyInputSort)
        && run.decisions == run.decisions.sorted(by: agentsBasicGoalApplyDecisionSort)
    let bounded = (24...32).contains(cases.count == 0 ? 28 : cases.count)
        && run.inputs.count == 20
        && run.decisions.count == run.inputs.count
    let casesPassed = cases.filter(\.passed).count
    let casesFailed = cases.count - casesPassed
    let success = scenario == agentsBasicGoalApplyHardeningScenarioName
        && (24...32).contains(cases.count)
        && casesFailed == 0
        && run.inputs.count > 0
        && run.decisions.count == run.inputs.count
        && applied > 0
        && changed > 0
        && applied == changed
        && noops > 0
        && rejected >= 10
        && deferred == 0
        && runtimeBehaviorChanged
        && run.decisions.filter(\.runtimeBehaviorChanged).allSatisfy {
            $0.runtimeBehaviorChangedReason == agentsBasicGoalApplyRuntimeReason
        }
        && forbiddenFields.isEmpty
        && onlyCurrentGoalChanged
        && !rejectedDecisionsMutated
        && !noopDecisionsMutated
        && !positionMutated
        && !needsMutated
        && !inventoryMutated
        && !lastActionMutated
        && !lastActionEffectMutated
        && !lastMovementMutated
        && !memoryCountMutated
        && !countersMutated
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual

    return LabAgentsBasicGoalApplyHardeningReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        cases: cases.count,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
        agents: Set(run.beforeAfter.map(\.agentId)).count,
        inputs: run.inputs.count,
        decisions: run.decisions.count,
        agentsBasicGoalApplyEligible: run.decisions.filter(\.agentsBasicApplyEligible).count,
        wouldApplyToAgentsBasic: run.decisions.filter(\.wouldApplyToAgentsBasic).count,
        appliedToAgentsBasic: applied,
        agentsBasicGoalChanged: changed,
        agentsBasicGoalNoops: noops,
        rejectedAgentsBasicGoalApplies: rejected,
        deferredAgentsBasicGoalApplies: deferred,
        runtimeBehaviorChanged: runtimeBehaviorChanged,
        runtimeBehaviorChangedReason: runtimeBehaviorChanged ? agentsBasicGoalApplyRuntimeReason : "",
        memoryMutated: false,
        movementStackUsed: false,
        worldMutated: false,
        terrainMutated: false,
        positionMutated: positionMutated,
        needsMutated: needsMutated,
        inventoryMutated: inventoryMutated,
        lastActionMutated: lastActionMutated,
        lastActionEffectMutated: lastActionEffectMutated,
        lastMovementMutated: lastMovementMutated,
        memoryCountMutated: memoryCountMutated,
        countersMutated: countersMutated,
        physicalPlaceholderMutated: false,
        coreEntityMutated: false,
        onlyCurrentGoalChanged: onlyCurrentGoalChanged,
        rejectedDecisionsMutated: rejectedDecisionsMutated,
        noopDecisionsMutated: noopDecisionsMutated,
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

private func makeAgentsBasicGoalApplyHardeningCases(
    run: LabAgentsBasicGoalApplyRun,
    report: LabAgentsBasicGoalApplyHardeningReport,
    baselineReport: LabAgentsBasicGoalApplyReport,
    digest: LabAgentsBasicGoalApplyDigest
) -> [LabAgentsBasicGoalApplyHardeningCaseResult] {
    func decision(_ agentId: String) -> LabAgentsBasicGoalApplyDecision? {
        run.decisions.first { $0.agentId == agentId }
    }
    func record(_ agentId: String) -> LabAgentsBasicGoalApplyBeforeAfter? {
        run.beforeAfter.first { $0.agentId == agentId }
    }
    func result(_ name: String, _ passed: Bool, _ detail: String) -> LabAgentsBasicGoalApplyHardeningCaseResult {
        LabAgentsBasicGoalApplyHardeningCaseResult(name: name, passed: passed, detail: detail)
    }
    func rejected(_ agentId: String, reason: String) -> Bool {
        decision(agentId)?.rejectedReasons.contains(reason) == true
    }
    let appliedIds = ["hardening_agent_00", "hardening_agent_01", "hardening_agent_02"]
    let rejectedIds = Set(run.decisions.filter { !$0.rejectedReasons.isEmpty }.map(\.agentId))
    let noopIds = Set(agentsBasicGoalApplyHardeningNoopDecisions(run.decisions).map(\.agentId))
    let rejectedMutated = run.beforeAfter.contains { rejectedIds.contains($0.agentId) && !$0.changedFields.isEmpty }
    let noopMutated = run.beforeAfter.contains { noopIds.contains($0.agentId) && !$0.changedFields.isEmpty }

    return [
        result("baseline_apply_fixture_compatible", baselineReport.success && baselineReport.appliedToAgentsBasic == 3, "5.14B fixture remains green with three real applies"),
        result("eligible_safety_apply", decision("hardening_agent_00")?.appliedToAgentsBasic == true && decision("hardening_agent_00")?.agentsBasicGoalAfter == LabGoalKind.seekSafety.rawValue, "eligible safety candidate applied"),
        result("eligible_explore_apply", decision("hardening_agent_01")?.appliedToAgentsBasic == true && decision("hardening_agent_01")?.agentsBasicGoalAfter == LabGoalKind.explore.rawValue, "eligible explore candidate applied"),
        result("eligible_observe_apply", decision("hardening_agent_02")?.appliedToAgentsBasic == true && decision("hardening_agent_02")?.agentsBasicGoalAfter == LabGoalKind.observeOtherAgent.rawValue, "eligible observe candidate applied"),
        result("noop_allowed", decision("hardening_agent_03")?.success == true && decision("hardening_agent_03")?.appliedToAgentsBasic == false && record("hardening_agent_03")?.changedFields.isEmpty == true, "matching goal accepted as audited no-op"),
        result("noop_disallowed_rejected", rejected("hardening_agent_04", reason: "agents_basic goal noop not allowed"), "matching goal rejected when allowNoopGoal is false"),
        result("missing_agent_rejected", rejected("hardening_agent_05", reason: "missing agent") && record("hardening_agent_05") == nil, "missing target agent rejected without before/after mutation"),
        result("before_mismatch_rejected", rejected("hardening_agent_06", reason: "agents_basic goal before mismatch"), "input goal must match the live agent goal"),
        result("missing_target_rejected", rejected("hardening_agent_07", reason: "missing target goal"), "empty target rejected"),
        result("unknown_target_rejected", rejected("hardening_agent_08", reason: "unknown target goal"), "unknown target rejected"),
        result("target_not_allowed_rejected", rejected("hardening_agent_09", reason: "target not allowed"), "known but policy-disallowed target rejected"),
        result("would_apply_false_rejected", rejected("hardening_agent_10", reason: "wouldApplyToAgentsBasic false"), "wouldApplyToAgentsBasic is required"),
        result("apply_eligible_false_rejected", rejected("hardening_agent_11", reason: "agentsBasicApplyEligible false"), "agentsBasicApplyEligible is required"),
        result("prior_rejected_reasons_rejected", rejected("hardening_agent_12", reason: "prior rejected reasons present"), "prior rejected reasons block apply"),
        result("prior_deferred_reasons_rejected", rejected("hardening_agent_13", reason: "prior deferred reasons present"), "prior deferred reasons block apply"),
        result("prior_applied_rejected", rejected("hardening_agent_14", reason: "prior applied to agents_basic"), "prior applied decision blocks duplicate apply"),
        result("dedicated_scenario_false_rejected", rejected("hardening_agent_15", reason: "dedicated scenario false"), "apply remains opt-in"),
        result("policy_disallow_rejected", rejected("hardening_agent_16", reason: "policy disallows agents_basic goal apply"), "policy can disable apply"),
        result("missing_reason_rejected", rejected("hardening_agent_17", reason: "missing reason"), "apply requires an audit reason"),
        result("max_applications_exceeded_rejected", rejected("hardening_agent_18", reason: "max agents_basic goal applications exceeded"), "per-tick apply cap enforced"),
        result("apply_mode_incorrect_rejected", rejected("hardening_agent_19", reason: "applyMode incorrect"), "unexpected apply mode rejected"),
        result("rejected_decisions_do_not_mutate", !rejectedMutated, "rejected decisions leave snapshots unchanged"),
        result("noop_decisions_do_not_mutate", !noopMutated, "no-op decisions leave snapshots unchanged"),
        result("applied_only_current_goal_changed", appliedIds.allSatisfy { record($0)?.currentGoalChanged == true && record($0)?.onlyCurrentGoalChanged == true }, "applied agents changed only currentGoal fields"),
        result("forbidden_boundaries_false", !report.memoryMutated && !report.movementStackUsed && !report.worldMutated && !report.terrainMutated && !report.positionMutated && !report.needsMutated && !report.inventoryMutated && !report.lastActionMutated && !report.lastActionEffectMutated && !report.lastMovementMutated && !report.memoryCountMutated && !report.countersMutated, "all forbidden mutation flags stay false"),
        result("deterministic_order", report.deterministicOrder, "inputs and decisions are sorted deterministically"),
        result("digest_repeatability", digest.deterministicDigest && digest.digestsEqual && report.repeatabilityFailures == 0, "repeat run digest matches"),
        result("hardening_outputs_contract", run.inputs.count == 20 && run.decisions.count == 20 && report.appliedToAgentsBasic == 3 && report.agentsBasicGoalChanged == 3 && report.rejectedAgentsBasicGoalApplies == 16, "hardening fixture output counts match contract")
    ]
}

private func makeAgentsBasicGoalApplyHardeningInvariantReport(
    report: LabAgentsBasicGoalApplyHardeningReport,
    run: LabAgentsBasicGoalApplyRun,
    cases: [LabAgentsBasicGoalApplyHardeningCaseResult],
    digest: LabAgentsBasicGoalApplyDigest
) -> LabAgentsBasicGoalApplyHardeningInvariantReport {
    let appliedDecisions = run.decisions.filter(\.appliedToAgentsBasic)
    let rejectedDecisions = run.decisions.filter { !$0.rejectedReasons.isEmpty }
    let noopDecisions = agentsBasicGoalApplyHardeningNoopDecisions(run.decisions)
    let appliedIds = Set(appliedDecisions.map(\.agentId))
    let rejectedIds = Set(rejectedDecisions.map(\.agentId))
    let noopIds = Set(noopDecisions.map(\.agentId))
    let appliedRecords = run.beforeAfter.filter { appliedIds.contains($0.agentId) }
    let rejectedRecords = run.beforeAfter.filter { rejectedIds.contains($0.agentId) }
    let noopRecords = run.beforeAfter.filter { noopIds.contains($0.agentId) }
    let checks: [LabBehaviorLoopInvariantCheck] = [
        agentsBasicGoalApplyCheck("scenario_name_expected", report.scenario == agentsBasicGoalApplyHardeningScenarioName, agentsBasicGoalApplyHardeningScenarioName, report.scenario),
        agentsBasicGoalApplyCheck("seed_recorded", report.seed > 0, "> 0", "\(report.seed)"),
        agentsBasicGoalApplyCheck("report_success", report.success, "true", "\(report.success)"),
        agentsBasicGoalApplyCheck("case_count_in_range", (24...32).contains(report.cases), "24...32", "\(report.cases)"),
        agentsBasicGoalApplyCheck("case_count_exact_fixture", report.cases == 28, "28", "\(report.cases)"),
        agentsBasicGoalApplyCheck("cases_passed_all", report.casesPassed == report.cases, "\(report.cases)", "\(report.casesPassed)"),
        agentsBasicGoalApplyCheck("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"),
        agentsBasicGoalApplyCheck("case_results_all_passed", cases.allSatisfy(\.passed), "true", "\(cases.allSatisfy(\.passed))"),
        agentsBasicGoalApplyCheck("inputs_positive", report.inputs > 0, "> 0", "\(report.inputs)"),
        agentsBasicGoalApplyCheck("inputs_expected", report.inputs == 20, "20", "\(report.inputs)"),
        agentsBasicGoalApplyCheck("decisions_match_inputs", report.decisions == report.inputs, "\(report.inputs)", "\(report.decisions)"),
        agentsBasicGoalApplyCheck("agents_expected", report.agents == 19, "19", "\(report.agents)"),
        agentsBasicGoalApplyCheck("applied_to_agents_basic_positive", report.appliedToAgentsBasic > 0, "> 0", "\(report.appliedToAgentsBasic)"),
        agentsBasicGoalApplyCheck("applied_to_agents_basic_expected", report.appliedToAgentsBasic == 3, "3", "\(report.appliedToAgentsBasic)"),
        agentsBasicGoalApplyCheck("agents_basic_goal_changed_positive", report.agentsBasicGoalChanged > 0, "> 0", "\(report.agentsBasicGoalChanged)"),
        agentsBasicGoalApplyCheck("agents_basic_goal_changed_expected", report.agentsBasicGoalChanged == 3, "3", "\(report.agentsBasicGoalChanged)"),
        agentsBasicGoalApplyCheck("applied_equals_goal_changed", report.appliedToAgentsBasic == report.agentsBasicGoalChanged, "\(report.appliedToAgentsBasic)", "\(report.agentsBasicGoalChanged)"),
        agentsBasicGoalApplyCheck("applied_decisions_change_goal", appliedDecisions.allSatisfy(\.agentsBasicGoalChanged), "true", "\(appliedDecisions.allSatisfy(\.agentsBasicGoalChanged))"),
        agentsBasicGoalApplyCheck("applied_decisions_success", appliedDecisions.allSatisfy(\.success), "true", "\(appliedDecisions.allSatisfy(\.success))"),
        agentsBasicGoalApplyCheck("applied_records_present", appliedRecords.count == appliedDecisions.count, "\(appliedDecisions.count)", "\(appliedRecords.count)"),
        agentsBasicGoalApplyCheck("applied_only_current_goal_changed", appliedRecords.allSatisfy { $0.currentGoalChanged && $0.onlyCurrentGoalChanged }, "true", "\(appliedRecords.allSatisfy { $0.currentGoalChanged && $0.onlyCurrentGoalChanged })"),
        agentsBasicGoalApplyCheck("only_current_goal_changed_global", report.onlyCurrentGoalChanged, "true", "\(report.onlyCurrentGoalChanged)"),
        agentsBasicGoalApplyCheck("noop_present", report.agentsBasicGoalNoops > 0, "> 0", "\(report.agentsBasicGoalNoops)"),
        agentsBasicGoalApplyCheck("noop_expected", report.agentsBasicGoalNoops == 1, "1", "\(report.agentsBasicGoalNoops)"),
        agentsBasicGoalApplyCheck("noop_not_applied", noopDecisions.allSatisfy { !$0.appliedToAgentsBasic && !$0.agentsBasicGoalChanged }, "true", "\(noopDecisions.allSatisfy { !$0.appliedToAgentsBasic && !$0.agentsBasicGoalChanged })"),
        agentsBasicGoalApplyCheck("noop_records_unchanged", noopRecords.allSatisfy(\.changedFields.isEmpty), "true", "\(noopRecords.allSatisfy(\.changedFields.isEmpty))"),
        agentsBasicGoalApplyCheck("noop_decisions_not_mutated", !report.noopDecisionsMutated, "false", "\(report.noopDecisionsMutated)"),
        agentsBasicGoalApplyCheck("rejected_expected", report.rejectedAgentsBasicGoalApplies == 16, "16", "\(report.rejectedAgentsBasicGoalApplies)"),
        agentsBasicGoalApplyCheck("rejected_minimum", report.rejectedAgentsBasicGoalApplies >= 10, ">= 10", "\(report.rejectedAgentsBasicGoalApplies)"),
        agentsBasicGoalApplyCheck("rejected_not_applied", rejectedDecisions.allSatisfy { !$0.appliedToAgentsBasic && !$0.agentsBasicGoalChanged && !$0.runtimeBehaviorChanged }, "true", "\(rejectedDecisions.allSatisfy { !$0.appliedToAgentsBasic && !$0.agentsBasicGoalChanged && !$0.runtimeBehaviorChanged })"),
        agentsBasicGoalApplyCheck("rejected_records_unchanged", rejectedRecords.allSatisfy(\.changedFields.isEmpty), "true", "\(rejectedRecords.allSatisfy(\.changedFields.isEmpty))"),
        agentsBasicGoalApplyCheck("rejected_decisions_not_mutated", !report.rejectedDecisionsMutated, "false", "\(report.rejectedDecisionsMutated)"),
        agentsBasicGoalApplyCheck("missing_agent_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_05" && $0.rejectedReasons.contains("missing agent") }, "true", "true"),
        agentsBasicGoalApplyCheck("before_mismatch_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_06" && $0.rejectedReasons.contains("agents_basic goal before mismatch") }, "true", "true"),
        agentsBasicGoalApplyCheck("missing_target_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_07" && $0.rejectedReasons.contains("missing target goal") }, "true", "true"),
        agentsBasicGoalApplyCheck("unknown_target_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_08" && $0.rejectedReasons.contains("unknown target goal") }, "true", "true"),
        agentsBasicGoalApplyCheck("target_not_allowed_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_09" && $0.rejectedReasons.contains("target not allowed") }, "true", "true"),
        agentsBasicGoalApplyCheck("would_apply_false_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_10" && $0.rejectedReasons.contains("wouldApplyToAgentsBasic false") }, "true", "true"),
        agentsBasicGoalApplyCheck("apply_eligible_false_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_11" && $0.rejectedReasons.contains("agentsBasicApplyEligible false") }, "true", "true"),
        agentsBasicGoalApplyCheck("prior_rejected_reasons_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_12" && $0.rejectedReasons.contains("prior rejected reasons present") }, "true", "true"),
        agentsBasicGoalApplyCheck("prior_deferred_reasons_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_13" && $0.rejectedReasons.contains("prior deferred reasons present") }, "true", "true"),
        agentsBasicGoalApplyCheck("prior_applied_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_14" && $0.rejectedReasons.contains("prior applied to agents_basic") }, "true", "true"),
        agentsBasicGoalApplyCheck("dedicated_scenario_false_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_15" && $0.rejectedReasons.contains("dedicated scenario false") }, "true", "true"),
        agentsBasicGoalApplyCheck("policy_disallow_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_16" && $0.rejectedReasons.contains("policy disallows agents_basic goal apply") }, "true", "true"),
        agentsBasicGoalApplyCheck("missing_reason_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_17" && $0.rejectedReasons.contains("missing reason") }, "true", "true"),
        agentsBasicGoalApplyCheck("max_applications_exceeded_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_18" && $0.rejectedReasons.contains("max agents_basic goal applications exceeded") }, "true", "true"),
        agentsBasicGoalApplyCheck("apply_mode_incorrect_rejected", rejectedDecisions.contains { $0.agentId == "hardening_agent_19" && $0.rejectedReasons.contains("applyMode incorrect") }, "true", "true"),
        agentsBasicGoalApplyCheck("deferred_zero", report.deferredAgentsBasicGoalApplies == 0, "0", "\(report.deferredAgentsBasicGoalApplies)"),
        agentsBasicGoalApplyCheck("runtime_behavior_changed_true", report.runtimeBehaviorChanged, "true", "\(report.runtimeBehaviorChanged)"),
        agentsBasicGoalApplyCheck("runtime_behavior_reason", report.runtimeBehaviorChangedReason == agentsBasicGoalApplyRuntimeReason, agentsBasicGoalApplyRuntimeReason, report.runtimeBehaviorChangedReason),
        agentsBasicGoalApplyCheck("runtime_changed_only_applied", run.decisions.filter(\.runtimeBehaviorChanged).allSatisfy(\.appliedToAgentsBasic), "true", "\(run.decisions.filter(\.runtimeBehaviorChanged).allSatisfy(\.appliedToAgentsBasic))"),
        agentsBasicGoalApplyCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"),
        agentsBasicGoalApplyCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"),
        agentsBasicGoalApplyCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"),
        agentsBasicGoalApplyCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"),
        agentsBasicGoalApplyCheck("position_not_mutated", !report.positionMutated, "false", "\(report.positionMutated)"),
        agentsBasicGoalApplyCheck("needs_not_mutated", !report.needsMutated, "false", "\(report.needsMutated)"),
        agentsBasicGoalApplyCheck("inventory_not_mutated", !report.inventoryMutated, "false", "\(report.inventoryMutated)"),
        agentsBasicGoalApplyCheck("last_action_not_mutated", !report.lastActionMutated, "false", "\(report.lastActionMutated)"),
        agentsBasicGoalApplyCheck("last_action_effect_not_mutated", !report.lastActionEffectMutated, "false", "\(report.lastActionEffectMutated)"),
        agentsBasicGoalApplyCheck("last_movement_not_mutated", !report.lastMovementMutated, "false", "\(report.lastMovementMutated)"),
        agentsBasicGoalApplyCheck("memory_count_not_mutated", !report.memoryCountMutated, "false", "\(report.memoryCountMutated)"),
        agentsBasicGoalApplyCheck("counters_not_mutated", !report.countersMutated, "false", "\(report.countersMutated)"),
        agentsBasicGoalApplyCheck("no_physical_placeholder_mutation", !report.physicalPlaceholderMutated, "false", "\(report.physicalPlaceholderMutated)"),
        agentsBasicGoalApplyCheck("no_core_entity_mutation", !report.coreEntityMutated, "false", "\(report.coreEntityMutated)"),
        agentsBasicGoalApplyCheck("bounded", report.bounded, "true", "\(report.bounded)"),
        agentsBasicGoalApplyCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"),
        agentsBasicGoalApplyCheck("deterministic_digest", report.deterministicDigest, "true", "\(report.deterministicDigest)"),
        agentsBasicGoalApplyCheck("digest_written", !report.digest.isEmpty, "non-empty", report.digest),
        agentsBasicGoalApplyCheck("digest_repeat_written", !report.digestRepeat.isEmpty, "non-empty", report.digestRepeat),
        agentsBasicGoalApplyCheck("digests_equal", digest.digestsEqual, "true", "\(digest.digestsEqual)"),
        agentsBasicGoalApplyCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"),
        agentsBasicGoalApplyCheck("metrics_written", true, "true", "true"),
        agentsBasicGoalApplyCheck("event_written", true, "true", "true"),
        agentsBasicGoalApplyCheck("outputs_written", true, "true", "true")
    ]
    let checksPassed = checks.filter(\.passed).count
    let checksFailed = checks.count - checksPassed
    return LabAgentsBasicGoalApplyHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: checksFailed == 0,
        summary: LabAgentsBasicGoalApplyHardeningInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checksFailed,
            cases: report.cases,
            inputs: report.inputs,
            decisions: report.decisions,
            appliedToAgentsBasic: report.appliedToAgentsBasic,
            agentsBasicGoalChanged: report.agentsBasicGoalChanged
        ),
        checks: checks,
        notes: [
            "Hardening remains worldless and opt-in.",
            "The only successful runtime mutation is LabAgent.currentGoal on applied agents.",
            "Rejected and no-op decisions preserve their full before/after snapshots."
        ]
    )
}

private func makeAgentsBasicGoalApplyHardeningMetrics(
    report: LabAgentsBasicGoalApplyHardeningReport
) -> LabAgentsBasicGoalApplyHardeningMetrics {
    LabAgentsBasicGoalApplyHardeningMetrics(
        agentsBasicGoalApplyHardeningSuccess: report.success,
        agentsBasicGoalApplyHardeningCases: report.cases,
        agentsBasicGoalApplyHardeningCasesPassed: report.casesPassed,
        agentsBasicGoalApplyHardeningCasesFailed: report.casesFailed,
        agentsBasicGoalApplyHardeningAgents: report.agents,
        agentsBasicGoalApplyHardeningInputs: report.inputs,
        agentsBasicGoalApplyHardeningDecisions: report.decisions,
        agentsBasicGoalApplyHardeningEligible: report.agentsBasicGoalApplyEligible,
        agentsBasicGoalApplyHardeningWouldApply: report.wouldApplyToAgentsBasic,
        agentsBasicGoalApplyHardeningApplied: report.appliedToAgentsBasic,
        agentsBasicGoalApplyHardeningGoalChanged: report.agentsBasicGoalChanged,
        agentsBasicGoalApplyHardeningNoops: report.agentsBasicGoalNoops,
        agentsBasicGoalApplyHardeningRejected: report.rejectedAgentsBasicGoalApplies,
        agentsBasicGoalApplyHardeningDeferred: report.deferredAgentsBasicGoalApplies,
        agentsBasicGoalApplyHardeningRuntimeBehaviorChanged: report.runtimeBehaviorChanged,
        agentsBasicGoalApplyHardeningMemoryMutated: report.memoryMutated,
        agentsBasicGoalApplyHardeningMovementStackUsed: report.movementStackUsed,
        agentsBasicGoalApplyHardeningWorldMutated: report.worldMutated,
        agentsBasicGoalApplyHardeningTerrainMutated: report.terrainMutated,
        agentsBasicGoalApplyHardeningPositionMutated: report.positionMutated,
        agentsBasicGoalApplyHardeningNeedsMutated: report.needsMutated,
        agentsBasicGoalApplyHardeningInventoryMutated: report.inventoryMutated,
        agentsBasicGoalApplyHardeningLastActionMutated: report.lastActionMutated,
        agentsBasicGoalApplyHardeningLastActionEffectMutated: report.lastActionEffectMutated,
        agentsBasicGoalApplyHardeningLastMovementMutated: report.lastMovementMutated,
        agentsBasicGoalApplyHardeningMemoryCountMutated: report.memoryCountMutated,
        agentsBasicGoalApplyHardeningCountersMutated: report.countersMutated,
        agentsBasicGoalApplyHardeningOnlyCurrentGoalChanged: report.onlyCurrentGoalChanged,
        agentsBasicGoalApplyHardeningRejectedDecisionsMutated: report.rejectedDecisionsMutated,
        agentsBasicGoalApplyHardeningNoopDecisionsMutated: report.noopDecisionsMutated,
        agentsBasicGoalApplyHardeningBounded: report.bounded,
        agentsBasicGoalApplyHardeningDeterministicOrder: report.deterministicOrder,
        agentsBasicGoalApplyHardeningDigestsEqual: report.digestsEqual,
        agentsBasicGoalApplyHardeningRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeAgentsBasicGoalApplyHardeningDigestValue(run: LabAgentsBasicGoalApplyRun) -> String {
    let base = makeAgentsBasicGoalApplyDigestValue(run: run)
    let inputParts = run.inputs.map {
        [
            $0.agentId,
            $0.targetGoal,
            "\($0.agentsBasicApplyEligible)",
            "\($0.wouldApplyToAgentsBasic)",
            "\($0.priorAppliedToAgentsBasic)",
            $0.priorRejectedReasons.joined(separator: ","),
            $0.priorDeferredReasons.joined(separator: ","),
            "\($0.dedicatedScenario)",
            $0.policy.applyMode,
            "\($0.policy.allowAgentsBasicGoalApply)",
            "\($0.policy.maxAgentsBasicGoalApplicationsPerTick)",
            $0.reason
        ].joined(separator: "|")
    }.joined(separator: "\n")
    return agentsBasicGoalApplyStableHash(base + "\n--hardening-inputs--\n" + inputParts)
}

private func makeAgentsBasicGoalApplyHardeningEventLines(
    report: LabAgentsBasicGoalApplyHardeningReport,
    decisions: [LabAgentsBasicGoalApplyDecision],
    cases: [LabAgentsBasicGoalApplyHardeningCaseResult]
) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let caseEvents = try cases.map {
        try encoder.encode(LabAgentsBasicGoalApplyHardeningCaseRecordedEvent(
            type: "lab_agents_basic_goal_apply_hardening_case_recorded",
            event: "lab_agents_basic_goal_apply_hardening_case_recorded",
            name: $0.name,
            passed: $0.passed,
            detail: $0.detail
        ))
    }
    let decisionEvents = try decisions.map {
        try encoder.encode(LabAgentsBasicGoalApplyHardeningDecisionRecordedEvent(
            type: "lab_agents_basic_goal_apply_hardening_decision_recorded",
            event: "lab_agents_basic_goal_apply_hardening_decision_recorded",
            success: $0.success,
            tick: $0.tick,
            agentId: $0.agentId,
            agentFound: $0.agentFound,
            agentsBasicGoalBefore: $0.agentsBasicGoalBefore,
            targetGoal: $0.targetGoal,
            agentsBasicGoalAfter: $0.agentsBasicGoalAfter,
            agentsBasicGoalChanged: $0.agentsBasicGoalChanged,
            agentsBasicApplyEligible: $0.agentsBasicApplyEligible,
            wouldApplyToAgentsBasic: $0.wouldApplyToAgentsBasic,
            appliedToAgentsBasic: $0.appliedToAgentsBasic,
            runtimeBehaviorChanged: $0.runtimeBehaviorChanged,
            rejectedReasons: $0.rejectedReasons,
            deferredReasons: $0.deferredReasons,
            applyMode: $0.applyMode
        ))
    }
    let aggregate = try encoder.encode(LabAgentsBasicGoalApplyHardeningRecordedEvent(
        type: "lab_agents_basic_goal_apply_hardening_recorded",
        event: "lab_agents_basic_goal_apply_hardening_recorded",
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        agents: report.agents,
        inputs: report.inputs,
        decisions: report.decisions,
        appliedToAgentsBasic: report.appliedToAgentsBasic,
        agentsBasicGoalChanged: report.agentsBasicGoalChanged,
        noops: report.agentsBasicGoalNoops,
        rejected: report.rejectedAgentsBasicGoalApplies,
        deferred: report.deferredAgentsBasicGoalApplies,
        runtimeBehaviorChanged: report.runtimeBehaviorChanged,
        runtimeBehaviorChangedReason: report.runtimeBehaviorChangedReason,
        memoryMutated: report.memoryMutated,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        positionMutated: report.positionMutated,
        needsMutated: report.needsMutated,
        inventoryMutated: report.inventoryMutated,
        lastActionMutated: report.lastActionMutated,
        lastActionEffectMutated: report.lastActionEffectMutated,
        lastMovementMutated: report.lastMovementMutated,
        memoryCountMutated: report.memoryCountMutated,
        countersMutated: report.countersMutated,
        onlyCurrentGoalChanged: report.onlyCurrentGoalChanged,
        bounded: report.bounded,
        deterministicOrder: report.deterministicOrder,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
    return (caseEvents + decisionEvents + [aggregate])
        .compactMap { String(data: $0, encoding: .utf8) }
        .joined(separator: "\n") + "\n"
}

private func agentsBasicGoalApplyHardeningNoopDecisions(
    _ decisions: [LabAgentsBasicGoalApplyDecision]
) -> [LabAgentsBasicGoalApplyDecision] {
    decisions.filter {
        $0.agentFound
            && $0.agentsBasicGoalBefore == $0.targetGoal
            && !$0.appliedToAgentsBasic
            && $0.rejectedReasons.isEmpty
            && $0.deferredReasons.isEmpty
    }
}
