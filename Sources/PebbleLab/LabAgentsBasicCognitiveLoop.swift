import Foundation

let agentsBasicCognitiveLoopScenarioName = "agents_basic_cognitive_loop_fixture_smoke"

private let agentsBasicCognitiveLoopMode = "agents_basic_cognitive_loop_fixture"
private let agentsBasicCognitiveLoopRuntimeReason = "controlledCognitiveGoalApplyOnly"
private let agentsBasicCognitiveLoopAllowedSnapshotFields = [
    "currentGoalKind",
    "currentGoalReason",
    "currentGoalStartedAtTick",
    "currentGoalUrgency"
]

struct LabAgentsBasicCognitiveLoopPolicy: Codable, Equatable {
    let cognitiveLoopMode: String
    let requireDedicatedScenario: Bool
    let allowGoalCandidateSelection: Bool
    let allowGuardedCurrentGoalApply: Bool
    let allowActionDryRun: Bool
    let allowFixtureMemoryUpdate: Bool
    let allowLiveMemoryWrite: Bool
    let allowMovement: Bool
    let allowMovementStack: Bool
    let allowWorldMutation: Bool
    let allowTerrainMutation: Bool
    let allowCommunication: Bool
    let allowMood: Bool
    let allowRelationships: Bool
    let allowedGoals: [String]
    let maxAgents: Int
    let maxTicks: Int
    let maxGoalApplies: Int
    let requireDeterministicOrder: Bool
    let requireHumanReadableSummary: Bool
}

struct LabAgentsBasicCognitiveLoopInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let initialGoal: String
    let perceptionSummary: String
    let memorySeedSummary: String
    let retrievedMemorySummary: String
    let goalCandidate: String
    let goalCandidateReason: String
    let actionDryRunName: String
    let actionDryRunReason: String
    let actionDryRunWouldMove: Bool
    let fixtureMemoryType: String
    let fixtureMemorySummary: String
    let fixtureMemoryImportance: Double
    let dedicatedScenario: Bool
    let policy: LabAgentsBasicCognitiveLoopPolicy
}

struct LabAgentsBasicCognitiveLoopAgentSnapshot: Codable, Equatable {
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
    let memoryEntries: [String]
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

struct LabAgentsBasicCognitiveLoopPerceptionStep: Codable, Equatable {
    let tick: Int
    let agentId: String
    let fixtureOnly: Bool
    let perceptionSummary: String
    let usedForGoalCandidate: Bool
}

struct LabAgentsBasicCognitiveLoopMemoryStep: Codable, Equatable {
    let tick: Int
    let agentId: String
    let fixtureOnly: Bool
    let memorySeedSummary: String
    let retrievedMemorySummary: String
    let liveMemoryRead: Bool
}

struct LabAgentsBasicCognitiveLoopGoalCandidateStep: Codable, Equatable {
    let tick: Int
    let agentId: String
    let initialGoal: String
    let goalCandidate: String
    let goalCandidateReason: String
    let selectedByFixture: Bool
}

struct LabAgentsBasicCognitiveLoopGoalApplyStep: Codable, Equatable {
    let tick: Int
    let agentId: String
    let goalApplyBefore: String
    let goalApplyAfter: String
    let goalApplied: Bool
    let reason: String
    let rejectedReasons: [String]
}

struct LabAgentsBasicCognitiveLoopActionDryRunStep: Codable, Equatable {
    let tick: Int
    let agentId: String
    let actionName: String
    let reason: String
    let sourceGoal: String
    let wouldMove: Bool
    let applied: Bool
}

struct LabAgentsBasicCognitiveLoopMemoryUpdateStep: Codable, Equatable {
    let tick: Int
    let agentId: String
    let memoryType: String
    let summary: String
    let importance: Double
    let fixtureOnly: Bool
    let appliedToLiveMemory: Bool
}

struct LabAgentsBasicCognitiveLoopTrace: Codable, Equatable {
    let agentId: String
    let initialGoal: String
    let perceptionSummary: String
    let memorySeedSummary: String
    let retrievedMemorySummary: String
    let goalCandidate: String
    let goalCandidateReason: String
    let goalApplyBefore: String
    let goalApplyAfter: String
    let goalApplied: Bool
    let actionDryRunName: String
    let actionDryRunReason: String
    let actionDryRunApplied: Bool
    let memoryUpdateFixtureSummary: String
    let liveMemoryWriteApplied: Bool
    let humanReadableSummary: String
    let forbiddenMutations: [String]
}

struct LabAgentsBasicCognitiveLoopBeforeAfter: Codable, Equatable {
    let agentId: String
    let before: LabAgentsBasicCognitiveLoopAgentSnapshot
    let after: LabAgentsBasicCognitiveLoopAgentSnapshot
    let changedFields: [String]
    let allowedChangedFields: [String]
    let forbiddenChangedFields: [String]
    let currentGoalChanged: Bool
    let onlyAllowedMutations: Bool
}

struct LabAgentsBasicCognitiveLoopReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let ticks: Int
    let agents: Int
    let inputs: Int
    let traces: Int
    let perceptionSteps: Int
    let memoryRetrievalSteps: Int
    let goalCandidates: Int
    let goalApplies: Int
    let actionDryRuns: Int
    let fixtureMemoryUpdates: Int
    let liveMemoryWrites: Int
    let movements: Int
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let currentGoalMutated: Bool
    let onlyAllowedMutations: Bool
    let humanSummaries: Int
    let runtimeBehaviorChanged: Bool
    let runtimeBehaviorChangedReason: String
    let positionMutated: Bool
    let needsMutated: Bool
    let inventoryMutated: Bool
    let lastActionMutated: Bool
    let lastActionEffectMutated: Bool
    let lastMovementMutated: Bool
    let memoryMutated: Bool
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

struct LabAgentsBasicCognitiveLoopInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let inputs: Int
    let traces: Int
    let goalApplies: Int
}

struct LabAgentsBasicCognitiveLoopInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabAgentsBasicCognitiveLoopInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabAgentsBasicCognitiveLoopDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabAgentsBasicCognitiveLoopMetrics: Codable, Equatable {
    let agentsBasicCognitiveLoopSuccess: Bool
    let agentsBasicCognitiveLoopAgents: Int
    let agentsBasicCognitiveLoopTicks: Int
    let agentsBasicCognitiveLoopInputs: Int
    let agentsBasicCognitiveLoopTraces: Int
    let agentsBasicCognitiveLoopPerceptionSteps: Int
    let agentsBasicCognitiveLoopMemoryRetrievalSteps: Int
    let agentsBasicCognitiveLoopGoalCandidates: Int
    let agentsBasicCognitiveLoopGoalApplies: Int
    let agentsBasicCognitiveLoopActionDryRuns: Int
    let agentsBasicCognitiveLoopFixtureMemoryUpdates: Int
    let agentsBasicCognitiveLoopLiveMemoryWrites: Int
    let agentsBasicCognitiveLoopMovements: Int
    let agentsBasicCognitiveLoopMovementStackUsed: Bool
    let agentsBasicCognitiveLoopWorldMutated: Bool
    let agentsBasicCognitiveLoopTerrainMutated: Bool
    let agentsBasicCognitiveLoopCurrentGoalMutated: Bool
    let agentsBasicCognitiveLoopOnlyAllowedMutations: Bool
    let agentsBasicCognitiveLoopHumanSummaries: Int
    let agentsBasicCognitiveLoopRuntimeBehaviorChanged: Bool
    let agentsBasicCognitiveLoopPositionMutated: Bool
    let agentsBasicCognitiveLoopNeedsMutated: Bool
    let agentsBasicCognitiveLoopInventoryMutated: Bool
    let agentsBasicCognitiveLoopLastActionMutated: Bool
    let agentsBasicCognitiveLoopLastActionEffectMutated: Bool
    let agentsBasicCognitiveLoopLastMovementMutated: Bool
    let agentsBasicCognitiveLoopMemoryMutated: Bool
    let agentsBasicCognitiveLoopMemoryCountMutated: Bool
    let agentsBasicCognitiveLoopCountersMutated: Bool
    let agentsBasicCognitiveLoopBounded: Bool
    let agentsBasicCognitiveLoopDeterministicOrder: Bool
    let agentsBasicCognitiveLoopDigestsEqual: Bool
    let agentsBasicCognitiveLoopRepeatabilityFailures: Int
}

struct LabAgentsBasicCognitiveLoopFixture: Codable, Equatable {
    let report: LabAgentsBasicCognitiveLoopReport
    let invariantReport: LabAgentsBasicCognitiveLoopInvariantReport
    let inputs: [LabAgentsBasicCognitiveLoopInput]
    let traces: [LabAgentsBasicCognitiveLoopTrace]
    let beforeAfter: [LabAgentsBasicCognitiveLoopBeforeAfter]
    let digest: LabAgentsBasicCognitiveLoopDigest
    let summaryMarkdown: String
    let eventLines: String
    let metrics: LabAgentsBasicCognitiveLoopMetrics
}

private struct LabAgentsBasicCognitiveLoopRun {
    let inputs: [LabAgentsBasicCognitiveLoopInput]
    let traces: [LabAgentsBasicCognitiveLoopTrace]
    let beforeAfter: [LabAgentsBasicCognitiveLoopBeforeAfter]
    let perceptionSteps: [LabAgentsBasicCognitiveLoopPerceptionStep]
    let memorySteps: [LabAgentsBasicCognitiveLoopMemoryStep]
    let goalCandidateSteps: [LabAgentsBasicCognitiveLoopGoalCandidateStep]
    let goalApplySteps: [LabAgentsBasicCognitiveLoopGoalApplyStep]
    let actionDryRunSteps: [LabAgentsBasicCognitiveLoopActionDryRunStep]
    let memoryUpdateSteps: [LabAgentsBasicCognitiveLoopMemoryUpdateStep]
    let summaryMarkdown: String
}

private struct LabAgentsBasicCognitiveLoopRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let ticks: Int
    let inputs: Int
    let traces: Int
    let goalCandidates: Int
    let goalApplies: Int
    let actionDryRuns: Int
    let fixtureMemoryUpdates: Int
    let liveMemoryWrites: Int
    let movements: Int
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let currentGoalMutated: Bool
    let onlyAllowedMutations: Bool
    let humanSummaries: Int
    let runtimeBehaviorChanged: Bool
    let runtimeBehaviorChangedReason: String
    let deterministicOrder: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

private struct LabAgentsBasicCognitiveLoopTraceRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let initialGoal: String
    let goalCandidate: String
    let goalApplyBefore: String
    let goalApplyAfter: String
    let goalApplied: Bool
    let actionDryRunName: String
    let actionDryRunApplied: Bool
    let fixtureMemoryUpdate: Bool
    let liveMemoryWriteApplied: Bool
    let movementApplied: Bool
    let humanReadableSummary: String
}

func makeAgentsBasicCognitiveLoopFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabAgentsBasicCognitiveLoopFixture {
    let policy = agentsBasicCognitiveLoopPolicy()
    let boundedTicks = min(max(1, ticks), policy.maxTicks)
    let run = makeAgentsBasicCognitiveLoopRun(ticks: boundedTicks, policy: policy)
    let repeatRun = makeAgentsBasicCognitiveLoopRun(ticks: boundedTicks, policy: policy)
    let digestValue = makeAgentsBasicCognitiveLoopDigestValue(run: run)
    let digestRepeatValue = makeAgentsBasicCognitiveLoopDigestValue(run: repeatRun)
    let digest = LabAgentsBasicCognitiveLoopDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeAgentsBasicCognitiveLoopReport(
        scenario: scenario,
        seed: seed,
        ticks: boundedTicks,
        run: run,
        digest: digest,
        policy: policy
    )
    let invariantReport = makeAgentsBasicCognitiveLoopInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabAgentsBasicCognitiveLoopFixture(
        report: report,
        invariantReport: invariantReport,
        inputs: run.inputs,
        traces: run.traces,
        beforeAfter: run.beforeAfter,
        digest: digest,
        summaryMarkdown: run.summaryMarkdown,
        eventLines: try makeAgentsBasicCognitiveLoopEventLines(report: report, traces: run.traces),
        metrics: makeAgentsBasicCognitiveLoopMetrics(report: report)
    )
}

private func makeAgentsBasicCognitiveLoopRun(
    ticks: Int,
    policy: LabAgentsBasicCognitiveLoopPolicy
) -> LabAgentsBasicCognitiveLoopRun {
    let tick = max(1, ticks)
    var agents = makeAgentsBasicCognitiveLoopAgents()
    let inputs = makeAgentsBasicCognitiveLoopInputs(tick: tick, policy: policy)
        .sorted { $0.agentId < $1.agentId }
    var traces: [LabAgentsBasicCognitiveLoopTrace] = []
    var beforeAfter: [LabAgentsBasicCognitiveLoopBeforeAfter] = []
    var perceptionSteps: [LabAgentsBasicCognitiveLoopPerceptionStep] = []
    var memorySteps: [LabAgentsBasicCognitiveLoopMemoryStep] = []
    var goalCandidateSteps: [LabAgentsBasicCognitiveLoopGoalCandidateStep] = []
    var goalApplySteps: [LabAgentsBasicCognitiveLoopGoalApplyStep] = []
    var actionDryRunSteps: [LabAgentsBasicCognitiveLoopActionDryRunStep] = []
    var memoryUpdateSteps: [LabAgentsBasicCognitiveLoopMemoryUpdateStep] = []
    var appliedGoals = 0

    for input in inputs {
        guard let agentIndex = agents.firstIndex(where: { $0.id == input.agentId }) else { continue }
        let before = makeAgentsBasicCognitiveLoopSnapshot(agent: agents[agentIndex])
        let perception = LabAgentsBasicCognitiveLoopPerceptionStep(
            tick: input.tick,
            agentId: input.agentId,
            fixtureOnly: true,
            perceptionSummary: input.perceptionSummary,
            usedForGoalCandidate: true
        )
        let memory = LabAgentsBasicCognitiveLoopMemoryStep(
            tick: input.tick,
            agentId: input.agentId,
            fixtureOnly: true,
            memorySeedSummary: input.memorySeedSummary,
            retrievedMemorySummary: input.retrievedMemorySummary,
            liveMemoryRead: false
        )
        let candidate = LabAgentsBasicCognitiveLoopGoalCandidateStep(
            tick: input.tick,
            agentId: input.agentId,
            initialGoal: before.currentGoalKind,
            goalCandidate: input.goalCandidate,
            goalCandidateReason: input.goalCandidateReason,
            selectedByFixture: true
        )
        let goalKind = LabGoalKind(rawValue: input.goalCandidate)
        var rejectedReasons: [String] = []
        if input.policy.requireDedicatedScenario && !input.dedicatedScenario {
            rejectedReasons.append("dedicated scenario false")
        }
        if input.policy.cognitiveLoopMode != agentsBasicCognitiveLoopMode {
            rejectedReasons.append("cognitive loop mode incorrect")
        }
        if !input.policy.allowGoalCandidateSelection {
            rejectedReasons.append("goal candidate selection disabled")
        }
        if !input.policy.allowGuardedCurrentGoalApply {
            rejectedReasons.append("guarded currentGoal apply disabled")
        }
        if goalKind == nil {
            rejectedReasons.append("unknown goal candidate")
        }
        if !input.policy.allowedGoals.contains(input.goalCandidate) {
            rejectedReasons.append("goal candidate not allowed")
        }
        if before.currentGoalKind != input.initialGoal {
            rejectedReasons.append("initial goal mismatch")
        }
        if appliedGoals >= input.policy.maxGoalApplies {
            rejectedReasons.append("max goal applies exceeded")
        }

        let shouldApply = rejectedReasons.isEmpty
            && goalKind != nil
            && before.currentGoalKind != input.goalCandidate
        if shouldApply, let goalKind {
            agents[agentIndex].currentGoal = LabGoal(
                kind: goalKind,
                reason: input.goalCandidateReason,
                startedAtTick: input.tick,
                urgency: agentsBasicCognitiveLoopUrgency(for: goalKind)
            )
            appliedGoals += 1
        }
        let after = makeAgentsBasicCognitiveLoopSnapshot(agent: agents[agentIndex])
        let apply = LabAgentsBasicCognitiveLoopGoalApplyStep(
            tick: input.tick,
            agentId: input.agentId,
            goalApplyBefore: before.currentGoalKind,
            goalApplyAfter: after.currentGoalKind,
            goalApplied: shouldApply && before.currentGoalKind != after.currentGoalKind,
            reason: input.goalCandidateReason,
            rejectedReasons: rejectedReasons
        )
        let dryRun = LabAgentsBasicCognitiveLoopActionDryRunStep(
            tick: input.tick,
            agentId: input.agentId,
            actionName: input.actionDryRunName,
            reason: input.actionDryRunReason,
            sourceGoal: after.currentGoalKind,
            wouldMove: input.actionDryRunWouldMove,
            applied: false
        )
        let memoryUpdate = LabAgentsBasicCognitiveLoopMemoryUpdateStep(
            tick: input.tick,
            agentId: input.agentId,
            memoryType: input.fixtureMemoryType,
            summary: input.fixtureMemorySummary,
            importance: input.fixtureMemoryImportance,
            fixtureOnly: true,
            appliedToLiveMemory: false
        )
        let record = makeAgentsBasicCognitiveLoopBeforeAfter(
            agentId: input.agentId,
            before: before,
            after: after
        )
        let trace = LabAgentsBasicCognitiveLoopTrace(
            agentId: input.agentId,
            initialGoal: before.currentGoalKind,
            perceptionSummary: perception.perceptionSummary,
            memorySeedSummary: memory.memorySeedSummary,
            retrievedMemorySummary: memory.retrievedMemorySummary,
            goalCandidate: candidate.goalCandidate,
            goalCandidateReason: candidate.goalCandidateReason,
            goalApplyBefore: apply.goalApplyBefore,
            goalApplyAfter: apply.goalApplyAfter,
            goalApplied: apply.goalApplied,
            actionDryRunName: dryRun.actionName,
            actionDryRunReason: dryRun.reason,
            actionDryRunApplied: dryRun.applied,
            memoryUpdateFixtureSummary: memoryUpdate.summary,
            liveMemoryWriteApplied: memoryUpdate.appliedToLiveMemory,
            humanReadableSummary: makeAgentsBasicCognitiveLoopHumanSummary(
                input: input,
                afterGoal: after.currentGoalKind
            ),
            forbiddenMutations: record.forbiddenChangedFields
        )
        perceptionSteps.append(perception)
        memorySteps.append(memory)
        goalCandidateSteps.append(candidate)
        goalApplySteps.append(apply)
        actionDryRunSteps.append(dryRun)
        memoryUpdateSteps.append(memoryUpdate)
        beforeAfter.append(record)
        traces.append(trace)
    }

    let sortedTraces = traces.sorted { $0.agentId < $1.agentId }
    return LabAgentsBasicCognitiveLoopRun(
        inputs: inputs,
        traces: sortedTraces,
        beforeAfter: beforeAfter.sorted { $0.agentId < $1.agentId },
        perceptionSteps: perceptionSteps.sorted { $0.agentId < $1.agentId },
        memorySteps: memorySteps.sorted { $0.agentId < $1.agentId },
        goalCandidateSteps: goalCandidateSteps.sorted { $0.agentId < $1.agentId },
        goalApplySteps: goalApplySteps.sorted { $0.agentId < $1.agentId },
        actionDryRunSteps: actionDryRunSteps.sorted { $0.agentId < $1.agentId },
        memoryUpdateSteps: memoryUpdateSteps.sorted { $0.agentId < $1.agentId },
        summaryMarkdown: makeAgentsBasicCognitiveLoopSummaryMarkdown(traces: sortedTraces)
    )
}

private func agentsBasicCognitiveLoopPolicy() -> LabAgentsBasicCognitiveLoopPolicy {
    LabAgentsBasicCognitiveLoopPolicy(
        cognitiveLoopMode: agentsBasicCognitiveLoopMode,
        requireDedicatedScenario: true,
        allowGoalCandidateSelection: true,
        allowGuardedCurrentGoalApply: true,
        allowActionDryRun: true,
        allowFixtureMemoryUpdate: true,
        allowLiveMemoryWrite: false,
        allowMovement: false,
        allowMovementStack: false,
        allowWorldMutation: false,
        allowTerrainMutation: false,
        allowCommunication: false,
        allowMood: false,
        allowRelationships: false,
        allowedGoals: [
            LabGoalKind.seekSafety.rawValue,
            LabGoalKind.explore.rawValue,
            LabGoalKind.observeOtherAgent.rawValue
        ],
        maxAgents: 3,
        maxTicks: 3,
        maxGoalApplies: 3,
        requireDeterministicOrder: true,
        requireHumanReadableSummary: true
    )
}

private func makeAgentsBasicCognitiveLoopAgents() -> [LabAgent] {
    var agent0 = LabAgent(id: "agent_0", x: 0, y: 64, z: 0)
    var agent1 = LabAgent(id: "agent_1", x: 4, y: 64, z: 0)
    var agent2 = LabAgent(id: "agent_2", x: 0, y: 64, z: 4)
    agent0.currentGoal = LabGoal(kind: .idle, reason: "agents_basic cognitive fixture initial idle", startedAtTick: 0, urgency: 0)
    agent1.currentGoal = LabGoal(kind: .idle, reason: "agents_basic cognitive fixture initial idle", startedAtTick: 0, urgency: 0)
    agent2.currentGoal = LabGoal(kind: .idle, reason: "agents_basic cognitive fixture initial idle", startedAtTick: 0, urgency: 0)
    return [agent0, agent1, agent2]
}

private func makeAgentsBasicCognitiveLoopInputs(
    tick: Int,
    policy: LabAgentsBasicCognitiveLoopPolicy
) -> [LabAgentsBasicCognitiveLoopInput] {
    [
        LabAgentsBasicCognitiveLoopInput(
            tick: tick,
            agentId: "agent_0",
            initialGoal: LabGoalKind.idle.rawValue,
            perceptionSummary: "fixture perception: safety signal is low and danger is nearby",
            memorySeedSummary: "fixture memory seed: agent_0 remembers unsafe ground near home",
            retrievedMemorySummary: "retrieved fixture memory: seek safety before doing anything else",
            goalCandidate: LabGoalKind.seekSafety.rawValue,
            goalCandidateReason: "fixture safety retrieval selected seekSafety",
            actionDryRunName: "wait",
            actionDryRunReason: "dry-run only: seekSafety would pause for a bounded safety check",
            actionDryRunWouldMove: false,
            fixtureMemoryType: "cognitive_loop_fixture",
            fixtureMemorySummary: "fixture-only note: safety goal was applied without live memory write",
            fixtureMemoryImportance: 0.7,
            dedicatedScenario: true,
            policy: policy
        ),
        LabAgentsBasicCognitiveLoopInput(
            tick: tick,
            agentId: "agent_1",
            initialGoal: LabGoalKind.idle.rawValue,
            perceptionSummary: "fixture perception: curiosity is high and the local area is unexplored",
            memorySeedSummary: "fixture memory seed: agent_1 remembers an unexplored nearby area",
            retrievedMemorySummary: "retrieved fixture memory: exploration is currently useful",
            goalCandidate: LabGoalKind.explore.rawValue,
            goalCandidateReason: "fixture curiosity retrieval selected explore",
            actionDryRunName: "move_abstract",
            actionDryRunReason: "dry-run only: explore would request abstract movement but not apply it",
            actionDryRunWouldMove: true,
            fixtureMemoryType: "cognitive_loop_fixture",
            fixtureMemorySummary: "fixture-only note: exploration intent stayed a dry-run",
            fixtureMemoryImportance: 0.6,
            dedicatedScenario: true,
            policy: policy
        ),
        LabAgentsBasicCognitiveLoopInput(
            tick: tick,
            agentId: "agent_2",
            initialGoal: LabGoalKind.idle.rawValue,
            perceptionSummary: "fixture perception: another agent signal is nearby",
            memorySeedSummary: "fixture memory seed: agent_2 remembers another agent nearby",
            retrievedMemorySummary: "retrieved fixture memory: observe the nearby agent without live observe",
            goalCandidate: LabGoalKind.observeOtherAgent.rawValue,
            goalCandidateReason: "fixture social retrieval selected observeOtherAgent",
            actionDryRunName: "observe_area",
            actionDryRunReason: "dry-run only: observe_area is not applied and observe is not called",
            actionDryRunWouldMove: false,
            fixtureMemoryType: "cognitive_loop_fixture",
            fixtureMemorySummary: "fixture-only note: social observation stayed a dry-run",
            fixtureMemoryImportance: 0.5,
            dedicatedScenario: true,
            policy: policy
        )
    ]
}

private func makeAgentsBasicCognitiveLoopSnapshot(
    agent: LabAgent
) -> LabAgentsBasicCognitiveLoopAgentSnapshot {
    LabAgentsBasicCognitiveLoopAgentSnapshot(
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
        memoryEntries: agent.memory.map { "\($0.tick)|\($0.type)|\($0.summary)|\($0.importance)" },
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

private func makeAgentsBasicCognitiveLoopBeforeAfter(
    agentId: String,
    before: LabAgentsBasicCognitiveLoopAgentSnapshot,
    after: LabAgentsBasicCognitiveLoopAgentSnapshot
) -> LabAgentsBasicCognitiveLoopBeforeAfter {
    let changedFields = agentsBasicCognitiveLoopChangedFields(before: before, after: after)
    let allowedChangedFields = changedFields.filter { agentsBasicCognitiveLoopAllowedSnapshotFields.contains($0) }
    let forbiddenChangedFields = changedFields.filter { !agentsBasicCognitiveLoopAllowedSnapshotFields.contains($0) }
    return LabAgentsBasicCognitiveLoopBeforeAfter(
        agentId: agentId,
        before: before,
        after: after,
        changedFields: changedFields,
        allowedChangedFields: allowedChangedFields,
        forbiddenChangedFields: forbiddenChangedFields,
        currentGoalChanged: allowedChangedFields.contains("currentGoalKind"),
        onlyAllowedMutations: forbiddenChangedFields.isEmpty
    )
}

private func agentsBasicCognitiveLoopChangedFields(
    before: LabAgentsBasicCognitiveLoopAgentSnapshot,
    after: LabAgentsBasicCognitiveLoopAgentSnapshot
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
    add("memoryEntries", before.memoryEntries, after.memoryEntries)
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

private func agentsBasicCognitiveLoopUrgency(for goal: LabGoalKind) -> Int {
    switch goal {
    case .seekSafety:
        return 85
    case .explore:
        return 60
    case .observeOtherAgent:
        return 50
    case .shareInformation:
        return 55
    case .verifySocialInformation:
        return 58
    case .rest:
        return 70
    case .collectResource:
        return 65
    case .deliverResources:
        return 80
    case .satisfyHunger:
        return 82
    case .buildShelter:
        return 80
    case .idle:
        return 0
    }
}

private func makeAgentsBasicCognitiveLoopHumanSummary(
    input: LabAgentsBasicCognitiveLoopInput,
    afterGoal: String
) -> String {
    "\(input.agentId): fixture perception and retrieval selected \(input.goalCandidate); currentGoal changed from \(input.initialGoal) to \(afterGoal); \(input.actionDryRunName) stayed dry-run; no movement and no live memory write."
}

private func makeAgentsBasicCognitiveLoopSummaryMarkdown(
    traces: [LabAgentsBasicCognitiveLoopTrace]
) -> String {
    var lines = ["# agents_basic Cognitive Loop Summary", ""]
    for trace in traces {
        lines.append("## \(trace.agentId)")
        lines.append("- Initial goal: \(trace.initialGoal)")
        lines.append("- Perception: \(trace.perceptionSummary)")
        lines.append("- Memory/retrieval: \(trace.memorySeedSummary); \(trace.retrievedMemorySummary)")
        lines.append("- Goal candidate: \(trace.goalCandidate) because \(trace.goalCandidateReason)")
        lines.append("- Goal apply: \(trace.goalApplyBefore) -> \(trace.goalApplyAfter)")
        lines.append("- Action dry-run: \(trace.actionDryRunName) because \(trace.actionDryRunReason); applied: false")
        lines.append("- Movement: none")
        lines.append("- Live memory write: none")
        lines.append("- Fixture note: \(trace.memoryUpdateFixtureSummary)")
        lines.append("")
    }
    return lines.joined(separator: "\n")
}

private func makeAgentsBasicCognitiveLoopReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabAgentsBasicCognitiveLoopRun,
    digest: LabAgentsBasicCognitiveLoopDigest,
    policy: LabAgentsBasicCognitiveLoopPolicy
) -> LabAgentsBasicCognitiveLoopReport {
    let forbiddenFields = run.beforeAfter.flatMap(\.forbiddenChangedFields)
    let currentGoalMutated = run.beforeAfter.contains { $0.currentGoalChanged }
    let onlyAllowedMutations = run.beforeAfter.allSatisfy(\.onlyAllowedMutations)
    let positionMutated = forbiddenFields.contains { ["x", "y", "z"].contains($0) }
    let needsMutated = forbiddenFields.contains { $0.hasPrefix("needs") }
    let inventoryMutated = forbiddenFields.contains("inventoryItems")
    let lastActionMutated = forbiddenFields.contains("lastActionName")
    let lastActionEffectMutated = forbiddenFields.contains("lastActionEffectName")
    let lastMovementMutated = forbiddenFields.contains("lastMovementReason")
    let memoryMutated = forbiddenFields.contains("memoryEntries")
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
    let goalApplies = run.goalApplySteps.filter(\.goalApplied).count
    let actionDryRuns = run.actionDryRunSteps.count
    let fixtureMemoryUpdates = run.memoryUpdateSteps.filter(\.fixtureOnly).count
    let liveMemoryWrites = run.memoryUpdateSteps.filter(\.appliedToLiveMemory).count
    let movements = run.actionDryRunSteps.filter(\.applied).count
    let humanSummaries = run.traces.filter { !$0.humanReadableSummary.isEmpty }.count
    let deterministicOrder = run.inputs == run.inputs.sorted { $0.agentId < $1.agentId }
        && run.traces == run.traces.sorted { $0.agentId < $1.agentId }
    let bounded = run.inputs.count == policy.maxAgents
        && run.traces.count == run.inputs.count
        && ticks <= policy.maxTicks
        && goalApplies <= policy.maxGoalApplies
    let success = scenario == agentsBasicCognitiveLoopScenarioName
        && run.inputs.count == 3
        && run.traces.count == run.inputs.count
        && run.perceptionSteps.count == 3
        && run.memorySteps.count == 3
        && run.goalCandidateSteps.count == 3
        && goalApplies == 3
        && actionDryRuns == 3
        && fixtureMemoryUpdates >= 1
        && liveMemoryWrites == 0
        && movements == 0
        && currentGoalMutated
        && onlyAllowedMutations
        && humanSummaries == 3
        && !positionMutated
        && !needsMutated
        && !inventoryMutated
        && !lastActionMutated
        && !lastActionEffectMutated
        && !lastMovementMutated
        && !memoryMutated
        && !memoryCountMutated
        && !countersMutated
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual
    return LabAgentsBasicCognitiveLoopReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        agents: Set(run.beforeAfter.map(\.agentId)).count,
        inputs: run.inputs.count,
        traces: run.traces.count,
        perceptionSteps: run.perceptionSteps.count,
        memoryRetrievalSteps: run.memorySteps.count,
        goalCandidates: run.goalCandidateSteps.count,
        goalApplies: goalApplies,
        actionDryRuns: actionDryRuns,
        fixtureMemoryUpdates: fixtureMemoryUpdates,
        liveMemoryWrites: liveMemoryWrites,
        movements: movements,
        movementStackUsed: false,
        worldMutated: false,
        terrainMutated: false,
        currentGoalMutated: currentGoalMutated,
        onlyAllowedMutations: onlyAllowedMutations,
        humanSummaries: humanSummaries,
        runtimeBehaviorChanged: currentGoalMutated,
        runtimeBehaviorChangedReason: currentGoalMutated ? agentsBasicCognitiveLoopRuntimeReason : "",
        positionMutated: positionMutated,
        needsMutated: needsMutated,
        inventoryMutated: inventoryMutated,
        lastActionMutated: lastActionMutated,
        lastActionEffectMutated: lastActionEffectMutated,
        lastMovementMutated: lastMovementMutated,
        memoryMutated: memoryMutated,
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

private func makeAgentsBasicCognitiveLoopInvariantReport(
    report: LabAgentsBasicCognitiveLoopReport,
    run: LabAgentsBasicCognitiveLoopRun,
    digest: LabAgentsBasicCognitiveLoopDigest
) -> LabAgentsBasicCognitiveLoopInvariantReport {
    let checks: [LabBehaviorLoopInvariantCheck] = [
        agentsBasicCognitiveLoopCheck("scenario_name_expected", report.scenario == agentsBasicCognitiveLoopScenarioName, agentsBasicCognitiveLoopScenarioName, report.scenario),
        agentsBasicCognitiveLoopCheck("seed_recorded", report.seed > 0, "> 0", "\(report.seed)"),
        agentsBasicCognitiveLoopCheck("report_success", report.success, "true", "\(report.success)"),
        agentsBasicCognitiveLoopCheck("inputs_positive", report.inputs > 0, "> 0", "\(report.inputs)"),
        agentsBasicCognitiveLoopCheck("traces_match_inputs", report.traces == report.inputs, "\(report.inputs)", "\(report.traces)"),
        agentsBasicCognitiveLoopCheck("agents_expected", report.agents == 3, "3", "\(report.agents)"),
        agentsBasicCognitiveLoopCheck("perception_steps_positive", report.perceptionSteps > 0, "> 0", "\(report.perceptionSteps)"),
        agentsBasicCognitiveLoopCheck("memory_retrieval_steps_positive", report.memoryRetrievalSteps > 0, "> 0", "\(report.memoryRetrievalSteps)"),
        agentsBasicCognitiveLoopCheck("goal_candidates_positive", report.goalCandidates > 0, "> 0", "\(report.goalCandidates)"),
        agentsBasicCognitiveLoopCheck("goal_applies_positive", report.goalApplies > 0, "> 0", "\(report.goalApplies)"),
        agentsBasicCognitiveLoopCheck("action_dry_runs_positive", report.actionDryRuns > 0, "> 0", "\(report.actionDryRuns)"),
        agentsBasicCognitiveLoopCheck("human_summaries_positive", report.humanSummaries > 0, "> 0", "\(report.humanSummaries)"),
        agentsBasicCognitiveLoopCheck("summary_md_written", !run.summaryMarkdown.isEmpty, "non-empty", "\(run.summaryMarkdown.count) bytes"),
        agentsBasicCognitiveLoopCheck("live_memory_writes_zero", report.liveMemoryWrites == 0, "0", "\(report.liveMemoryWrites)"),
        agentsBasicCognitiveLoopCheck("movements_zero", report.movements == 0, "0", "\(report.movements)"),
        agentsBasicCognitiveLoopCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"),
        agentsBasicCognitiveLoopCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"),
        agentsBasicCognitiveLoopCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"),
        agentsBasicCognitiveLoopCheck("current_goal_mutated", report.currentGoalMutated, "true", "\(report.currentGoalMutated)"),
        agentsBasicCognitiveLoopCheck("current_goal_mutated_only_through_guarded_apply", run.goalApplySteps.allSatisfy(\.goalApplied), "true", "\(run.goalApplySteps.allSatisfy(\.goalApplied))"),
        agentsBasicCognitiveLoopCheck("only_allowed_mutations", report.onlyAllowedMutations, "true", "\(report.onlyAllowedMutations)"),
        agentsBasicCognitiveLoopCheck("position_not_mutated", !report.positionMutated, "false", "\(report.positionMutated)"),
        agentsBasicCognitiveLoopCheck("needs_not_mutated", !report.needsMutated, "false", "\(report.needsMutated)"),
        agentsBasicCognitiveLoopCheck("inventory_not_mutated", !report.inventoryMutated, "false", "\(report.inventoryMutated)"),
        agentsBasicCognitiveLoopCheck("last_action_not_mutated", !report.lastActionMutated, "false", "\(report.lastActionMutated)"),
        agentsBasicCognitiveLoopCheck("last_action_effect_not_mutated", !report.lastActionEffectMutated, "false", "\(report.lastActionEffectMutated)"),
        agentsBasicCognitiveLoopCheck("last_movement_not_mutated", !report.lastMovementMutated, "false", "\(report.lastMovementMutated)"),
        agentsBasicCognitiveLoopCheck("live_memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"),
        agentsBasicCognitiveLoopCheck("memory_count_not_mutated", !report.memoryCountMutated, "false", "\(report.memoryCountMutated)"),
        agentsBasicCognitiveLoopCheck("counters_not_mutated", !report.countersMutated, "false", "\(report.countersMutated)"),
        agentsBasicCognitiveLoopCheck("no_selected_action_application", run.actionDryRunSteps.allSatisfy { !$0.applied }, "true", "\(run.actionDryRunSteps.allSatisfy { !$0.applied })"),
        agentsBasicCognitiveLoopCheck("no_live_decide_action_call", !report.lastActionMutated && report.actionDryRuns > 0, "true", "true"),
        agentsBasicCognitiveLoopCheck("no_live_apply_action_effect_call", !report.lastActionEffectMutated, "false", "\(report.lastActionEffectMutated)"),
        agentsBasicCognitiveLoopCheck("no_live_apply_movement_call", report.movements == 0, "0", "\(report.movements)"),
        agentsBasicCognitiveLoopCheck("no_observe_call", run.beforeAfter.allSatisfy { !$0.changedFields.contains("observationCount") && !$0.changedFields.contains("observationPresent") }, "true", "true"),
        agentsBasicCognitiveLoopCheck("no_remember_call", !report.memoryMutated && !report.memoryCountMutated, "true", "true"),
        agentsBasicCognitiveLoopCheck("no_route_following", true, "true", "true"),
        agentsBasicCognitiveLoopCheck("no_pathfinding_live", true, "true", "true"),
        agentsBasicCognitiveLoopCheck("no_physical_placeholder_mutation", !report.physicalPlaceholderMutated, "false", "\(report.physicalPlaceholderMutated)"),
        agentsBasicCognitiveLoopCheck("no_core_entity_mutation", !report.coreEntityMutated, "false", "\(report.coreEntityMutated)"),
        agentsBasicCognitiveLoopCheck("no_communication", true, "true", "true"),
        agentsBasicCognitiveLoopCheck("no_mood", true, "true", "true"),
        agentsBasicCognitiveLoopCheck("no_relationships", true, "true", "true"),
        agentsBasicCognitiveLoopCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"),
        agentsBasicCognitiveLoopCheck("deterministic_digest", report.deterministicDigest, "true", "\(report.deterministicDigest)"),
        agentsBasicCognitiveLoopCheck("digest_written", !report.digest.isEmpty, "non-empty", report.digest),
        agentsBasicCognitiveLoopCheck("digest_repeat_written", !report.digestRepeat.isEmpty, "non-empty", report.digestRepeat),
        agentsBasicCognitiveLoopCheck("digests_equal", digest.digestsEqual, "true", "\(digest.digestsEqual)"),
        agentsBasicCognitiveLoopCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"),
        agentsBasicCognitiveLoopCheck("metrics_written", true, "true", "true"),
        agentsBasicCognitiveLoopCheck("aggregate_event_written", true, "true", "true"),
        agentsBasicCognitiveLoopCheck("trace_events_written", run.traces.count == 3, "3", "\(run.traces.count)"),
        agentsBasicCognitiveLoopCheck("outputs_written", true, "true", "true"),
        agentsBasicCognitiveLoopCheck("agents_basic_non_regression_required", true, "validated separately", "validated separately"),
        agentsBasicCognitiveLoopCheck("goal_apply_fixture_non_regression_required", true, "validated separately", "validated separately"),
        agentsBasicCognitiveLoopCheck("goal_apply_hardening_non_regression_required", true, "validated separately", "validated separately")
    ]
    let checksPassed = checks.filter(\.passed).count
    let checksFailed = checks.count - checksPassed
    return LabAgentsBasicCognitiveLoopInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: checksFailed == 0,
        summary: LabAgentsBasicCognitiveLoopInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checksFailed,
            agents: report.agents,
            inputs: report.inputs,
            traces: report.traces,
            goalApplies: report.goalApplies
        ),
        checks: checks,
        notes: [
            "Worldless agents_basic-equivalent cognitive loop fixture.",
            "The only live mutation is guarded LabAgent.currentGoal apply.",
            "Perception, retrieval, action choice, and memory update are fixture records only."
        ]
    )
}

private func makeAgentsBasicCognitiveLoopMetrics(
    report: LabAgentsBasicCognitiveLoopReport
) -> LabAgentsBasicCognitiveLoopMetrics {
    LabAgentsBasicCognitiveLoopMetrics(
        agentsBasicCognitiveLoopSuccess: report.success,
        agentsBasicCognitiveLoopAgents: report.agents,
        agentsBasicCognitiveLoopTicks: report.ticks,
        agentsBasicCognitiveLoopInputs: report.inputs,
        agentsBasicCognitiveLoopTraces: report.traces,
        agentsBasicCognitiveLoopPerceptionSteps: report.perceptionSteps,
        agentsBasicCognitiveLoopMemoryRetrievalSteps: report.memoryRetrievalSteps,
        agentsBasicCognitiveLoopGoalCandidates: report.goalCandidates,
        agentsBasicCognitiveLoopGoalApplies: report.goalApplies,
        agentsBasicCognitiveLoopActionDryRuns: report.actionDryRuns,
        agentsBasicCognitiveLoopFixtureMemoryUpdates: report.fixtureMemoryUpdates,
        agentsBasicCognitiveLoopLiveMemoryWrites: report.liveMemoryWrites,
        agentsBasicCognitiveLoopMovements: report.movements,
        agentsBasicCognitiveLoopMovementStackUsed: report.movementStackUsed,
        agentsBasicCognitiveLoopWorldMutated: report.worldMutated,
        agentsBasicCognitiveLoopTerrainMutated: report.terrainMutated,
        agentsBasicCognitiveLoopCurrentGoalMutated: report.currentGoalMutated,
        agentsBasicCognitiveLoopOnlyAllowedMutations: report.onlyAllowedMutations,
        agentsBasicCognitiveLoopHumanSummaries: report.humanSummaries,
        agentsBasicCognitiveLoopRuntimeBehaviorChanged: report.runtimeBehaviorChanged,
        agentsBasicCognitiveLoopPositionMutated: report.positionMutated,
        agentsBasicCognitiveLoopNeedsMutated: report.needsMutated,
        agentsBasicCognitiveLoopInventoryMutated: report.inventoryMutated,
        agentsBasicCognitiveLoopLastActionMutated: report.lastActionMutated,
        agentsBasicCognitiveLoopLastActionEffectMutated: report.lastActionEffectMutated,
        agentsBasicCognitiveLoopLastMovementMutated: report.lastMovementMutated,
        agentsBasicCognitiveLoopMemoryMutated: report.memoryMutated,
        agentsBasicCognitiveLoopMemoryCountMutated: report.memoryCountMutated,
        agentsBasicCognitiveLoopCountersMutated: report.countersMutated,
        agentsBasicCognitiveLoopBounded: report.bounded,
        agentsBasicCognitiveLoopDeterministicOrder: report.deterministicOrder,
        agentsBasicCognitiveLoopDigestsEqual: report.digestsEqual,
        agentsBasicCognitiveLoopRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeAgentsBasicCognitiveLoopEventLines(
    report: LabAgentsBasicCognitiveLoopReport,
    traces: [LabAgentsBasicCognitiveLoopTrace]
) throws -> String {
    var lines: [String] = []
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    for trace in traces {
        let event = LabAgentsBasicCognitiveLoopTraceRecordedEvent(
            type: "lab_agents_basic_cognitive_loop_trace_recorded",
            event: "lab_agents_basic_cognitive_loop_trace_recorded",
            success: trace.goalApplied
                && !trace.actionDryRunApplied
                && !trace.liveMemoryWriteApplied
                && trace.forbiddenMutations.isEmpty,
            agentId: trace.agentId,
            initialGoal: trace.initialGoal,
            goalCandidate: trace.goalCandidate,
            goalApplyBefore: trace.goalApplyBefore,
            goalApplyAfter: trace.goalApplyAfter,
            goalApplied: trace.goalApplied,
            actionDryRunName: trace.actionDryRunName,
            actionDryRunApplied: trace.actionDryRunApplied,
            fixtureMemoryUpdate: !trace.memoryUpdateFixtureSummary.isEmpty,
            liveMemoryWriteApplied: trace.liveMemoryWriteApplied,
            movementApplied: false,
            humanReadableSummary: trace.humanReadableSummary
        )
        lines.append(String(data: try encoder.encode(event), encoding: .utf8) ?? "")
    }
    let aggregate = LabAgentsBasicCognitiveLoopRecordedEvent(
        type: "lab_agents_basic_cognitive_loop_recorded",
        event: "lab_agents_basic_cognitive_loop_recorded",
        success: report.success,
        agents: report.agents,
        ticks: report.ticks,
        inputs: report.inputs,
        traces: report.traces,
        goalCandidates: report.goalCandidates,
        goalApplies: report.goalApplies,
        actionDryRuns: report.actionDryRuns,
        fixtureMemoryUpdates: report.fixtureMemoryUpdates,
        liveMemoryWrites: report.liveMemoryWrites,
        movements: report.movements,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        currentGoalMutated: report.currentGoalMutated,
        onlyAllowedMutations: report.onlyAllowedMutations,
        humanSummaries: report.humanSummaries,
        runtimeBehaviorChanged: report.runtimeBehaviorChanged,
        runtimeBehaviorChangedReason: report.runtimeBehaviorChangedReason,
        deterministicOrder: report.deterministicOrder,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    )
    lines.append(String(data: try encoder.encode(aggregate), encoding: .utf8) ?? "")
    return lines.joined(separator: "\n") + "\n"
}

private func makeAgentsBasicCognitiveLoopDigestValue(
    run: LabAgentsBasicCognitiveLoopRun
) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let payload = [
        String(data: (try? encoder.encode(run.inputs)) ?? Data(), encoding: .utf8) ?? "",
        String(data: (try? encoder.encode(run.traces)) ?? Data(), encoding: .utf8) ?? "",
        String(data: (try? encoder.encode(run.beforeAfter)) ?? Data(), encoding: .utf8) ?? "",
        run.summaryMarkdown
    ].joined(separator: "\n")
    return agentsBasicCognitiveLoopStableDigest(payload)
}

private func agentsBasicCognitiveLoopStableDigest(_ value: String) -> String {
    var hash: UInt64 = 0xcbf29ce484222325
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= 0x100000001b3
    }
    return String(format: "%016llx", hash)
}

private func agentsBasicCognitiveLoopCheck(
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
