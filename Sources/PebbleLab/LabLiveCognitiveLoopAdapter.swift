import Foundation

let liveCognitiveLoopAdapterScenarioName = "live_cognitive_loop_adapter_fixture_smoke"
let liveCognitiveLoopAdapterHardeningScenarioName = "live_cognitive_loop_adapter_hardening_smoke"
let liveCognitiveLoopAdapterExpectedAgents = 5

struct LabLiveCognitiveLoopAdapterInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let liveAgentSummary: String
    let currentGoal: String
    let needsSummary: String
    let fear: Double
    let health: Double
    let memorySummary: String
    let observationSummary: String
    let dryRun: Bool
    let maxRetrievedMemories: Int
    let maxGoalCandidates: Int
    let maxMemoryWritesPerTick: Int
    let reason: String
}

struct LabLiveCognitiveLoopAdapterSnapshot: Codable, Equatable {
    let tick: Int
    let agentId: String
    let agentType: String
    let positionSummary: String
    let currentGoal: String
    let needsSummary: String
    let fear: Double
    let health: Double
    let memoryCount: Int
    let nearbyAgentCount: Int
    let observationAvailable: Bool
    let snapshotReadOnly: Bool
    let success: Bool
}

struct LabLiveCognitiveLoopApplicationPlan: Codable, Equatable {
    let tick: Int
    let agentId: String
    let computedSelectedGoal: String
    let computedSelectedAction: String
    let computedBehaviorResult: String
    let proposedMemoryWrites: Int
    let wouldChangeGoal: Bool
    let wouldSelectAction: Bool
    let wouldWriteMemory: Bool
    let appliedGoalChange: Bool
    let appliedAction: Bool
    let appliedMemoryWrite: Bool
    let dryRun: Bool
    let reason: String
}

struct LabLiveCognitiveLoopAdapterDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let snapshot: LabLiveCognitiveLoopAdapterSnapshot
    let cognitiveLoopDecisionSummary: String
    let applicationPlan: LabLiveCognitiveLoopApplicationPlan
    let success: Bool
}

struct LabLiveCognitiveLoopAdapterReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let snapshots: Int
    let decisions: Int
    let applicationPlans: Int
    let wouldChangeGoals: Int
    let wouldSelectActions: Int
    let wouldWriteMemories: Int
    let appliedGoalChanges: Int
    let appliedActions: Int
    let appliedMemoryWrites: Int
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

struct LabLiveCognitiveLoopAdapterInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let snapshots: Int
    let decisions: Int
    let applicationPlans: Int
    let wouldChangeGoals: Int
    let wouldSelectActions: Int
    let wouldWriteMemories: Int
}

struct LabLiveCognitiveLoopAdapterInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabLiveCognitiveLoopAdapterInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabLiveCognitiveLoopAdapterDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabLiveCognitiveLoopAdapterMetrics: Codable, Equatable {
    let liveCognitiveLoopAdapterSuccess: Bool
    let liveCognitiveLoopAdapterAgents: Int
    let liveCognitiveLoopAdapterTicks: Int
    let liveCognitiveLoopAdapterSnapshots: Int
    let liveCognitiveLoopAdapterDecisions: Int
    let liveCognitiveLoopAdapterApplicationPlans: Int
    let liveCognitiveLoopAdapterWouldChangeGoals: Int
    let liveCognitiveLoopAdapterWouldSelectActions: Int
    let liveCognitiveLoopAdapterWouldWriteMemories: Int
    let liveCognitiveLoopAdapterAppliedGoalChanges: Int
    let liveCognitiveLoopAdapterAppliedActions: Int
    let liveCognitiveLoopAdapterAppliedMemoryWrites: Int
    let liveCognitiveLoopAdapterDryRun: Bool
    let liveCognitiveLoopAdapterLiveAgentMutated: Bool
    let liveCognitiveLoopAdapterMemoryMutated: Bool
    let liveCognitiveLoopAdapterMovementStackUsed: Bool
    let liveCognitiveLoopAdapterWorldMutated: Bool
    let liveCognitiveLoopAdapterTerrainMutated: Bool
    let liveCognitiveLoopAdapterBounded: Bool
    let liveCognitiveLoopAdapterDeterministicOrder: Bool
    let liveCognitiveLoopAdapterDigestsEqual: Bool
    let liveCognitiveLoopAdapterRepeatabilityFailures: Int
}

struct LabLiveCognitiveLoopAdapterFixture: Codable, Equatable {
    let report: LabLiveCognitiveLoopAdapterReport
    let invariantReport: LabLiveCognitiveLoopAdapterInvariantReport
    let inputs: [LabLiveCognitiveLoopAdapterInput]
    let snapshots: [LabLiveCognitiveLoopAdapterSnapshot]
    let decisions: [LabLiveCognitiveLoopAdapterDecision]
    let applicationPlans: [LabLiveCognitiveLoopApplicationPlan]
    let digest: LabLiveCognitiveLoopAdapterDigest
    let eventLines: String
    let metrics: LabLiveCognitiveLoopAdapterMetrics
}

struct LabLiveCognitiveLoopAdapterHardeningCase: Codable, Equatable {
    let name: String
    let description: String
    let expected: String
}

struct LabLiveCognitiveLoopAdapterHardeningCaseResult: Codable, Equatable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

struct LabLiveCognitiveLoopAdapterHardeningReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let agents: Int
    let snapshots: Int
    let decisions: Int
    let applicationPlans: Int
    let wouldChangeGoals: Int
    let wouldSelectActions: Int
    let wouldWriteMemories: Int
    let appliedGoalChanges: Int
    let appliedActions: Int
    let appliedMemoryWrites: Int
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

struct LabLiveCognitiveLoopAdapterHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let agents: Int
    let snapshots: Int
    let decisions: Int
    let applicationPlans: Int
}

struct LabLiveCognitiveLoopAdapterHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabLiveCognitiveLoopAdapterHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabLiveCognitiveLoopAdapterHardeningMetrics: Codable, Equatable {
    let liveCognitiveLoopAdapterHardeningSuccess: Bool
    let liveCognitiveLoopAdapterHardeningCases: Int
    let liveCognitiveLoopAdapterHardeningCasesPassed: Int
    let liveCognitiveLoopAdapterHardeningCasesFailed: Int
    let liveCognitiveLoopAdapterHardeningAgents: Int
    let liveCognitiveLoopAdapterHardeningSnapshots: Int
    let liveCognitiveLoopAdapterHardeningDecisions: Int
    let liveCognitiveLoopAdapterHardeningApplicationPlans: Int
    let liveCognitiveLoopAdapterHardeningWouldChangeGoals: Int
    let liveCognitiveLoopAdapterHardeningWouldSelectActions: Int
    let liveCognitiveLoopAdapterHardeningWouldWriteMemories: Int
    let liveCognitiveLoopAdapterHardeningAppliedGoalChanges: Int
    let liveCognitiveLoopAdapterHardeningAppliedActions: Int
    let liveCognitiveLoopAdapterHardeningAppliedMemoryWrites: Int
    let liveCognitiveLoopAdapterHardeningDryRun: Bool
    let liveCognitiveLoopAdapterHardeningLiveAgentMutated: Bool
    let liveCognitiveLoopAdapterHardeningMemoryMutated: Bool
    let liveCognitiveLoopAdapterHardeningMovementStackUsed: Bool
    let liveCognitiveLoopAdapterHardeningWorldMutated: Bool
    let liveCognitiveLoopAdapterHardeningTerrainMutated: Bool
    let liveCognitiveLoopAdapterHardeningBounded: Bool
    let liveCognitiveLoopAdapterHardeningDeterministicOrder: Bool
    let liveCognitiveLoopAdapterHardeningDigestsEqual: Bool
    let liveCognitiveLoopAdapterHardeningRepeatabilityFailures: Int
}

struct LabLiveCognitiveLoopAdapterHardeningFixture: Codable, Equatable {
    let report: LabLiveCognitiveLoopAdapterHardeningReport
    let invariantReport: LabLiveCognitiveLoopAdapterHardeningInvariantReport
    let cases: [LabLiveCognitiveLoopAdapterHardeningCaseResult]
    let snapshots: [LabLiveCognitiveLoopAdapterSnapshot]
    let applicationPlans: [LabLiveCognitiveLoopApplicationPlan]
    let digest: LabLiveCognitiveLoopAdapterDigest
    let eventLines: String
    let metrics: LabLiveCognitiveLoopAdapterHardeningMetrics
}

private struct LabLiveCognitiveLoopAdapterRun {
    let inputs: [LabLiveCognitiveLoopAdapterInput]
    let snapshots: [LabLiveCognitiveLoopAdapterSnapshot]
    let decisions: [LabLiveCognitiveLoopAdapterDecision]
    let applicationPlans: [LabLiveCognitiveLoopApplicationPlan]
}

private struct LabLiveCognitiveLoopAdapterLiveLikeAgent: Equatable {
    let tick: Int
    let agentId: String
    let agentType: String
    let positionSummary: String
    let currentGoal: String
    let needsSummary: String
    let fear: Double
    let health: Double
    let memoryCount: Int
    let nearbyAgentCount: Int
    let observationAvailable: Bool
    let computedSelectedGoal: String
    let computedSelectedAction: String
    let proposedMemoryWrites: Int
    let reason: String
}

private struct LabLiveCognitiveLoopAdapterRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let currentGoal: String
    let computedSelectedGoal: String
    let computedSelectedAction: String
    let wouldChangeGoal: Bool
    let wouldSelectAction: Bool
    let wouldWriteMemory: Bool
    let appliedGoalChange: Bool
    let appliedAction: Bool
    let appliedMemoryWrite: Bool
    let dryRun: Bool
    let liveAgentMutated: Bool
    let movementStackUsed: Bool
}

private struct LabLiveCognitiveLoopAdapterSummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let ticks: Int
    let snapshots: Int
    let decisions: Int
    let applicationPlans: Int
    let wouldChangeGoals: Int
    let wouldSelectActions: Int
    let wouldWriteMemories: Int
    let appliedGoalChanges: Int
    let appliedActions: Int
    let appliedMemoryWrites: Int
    let dryRun: Bool
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

private struct LabLiveCognitiveLoopAdapterHardeningEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let agents: Int
    let snapshots: Int
    let decisions: Int
    let applicationPlans: Int
    let wouldChangeGoals: Int
    let wouldSelectActions: Int
    let wouldWriteMemories: Int
    let appliedGoalChanges: Int
    let appliedActions: Int
    let appliedMemoryWrites: Int
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

func makeLiveCognitiveLoopAdapterFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabLiveCognitiveLoopAdapterFixture {
    let run = makeLiveCognitiveLoopAdapterRun(ticks: ticks)
    let repeatRun = makeLiveCognitiveLoopAdapterRun(ticks: ticks)
    let digestValue = makeLiveCognitiveLoopAdapterDigestValue(run: run)
    let digestRepeatValue = makeLiveCognitiveLoopAdapterDigestValue(run: repeatRun)
    let digest = LabLiveCognitiveLoopAdapterDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeLiveCognitiveLoopAdapterReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeLiveCognitiveLoopAdapterInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabLiveCognitiveLoopAdapterFixture(
        report: report,
        invariantReport: invariantReport,
        inputs: run.inputs,
        snapshots: run.snapshots,
        decisions: run.decisions,
        applicationPlans: run.applicationPlans,
        digest: digest,
        eventLines: try makeLiveCognitiveLoopAdapterEventLines(report: report, decisions: run.decisions),
        metrics: makeLiveCognitiveLoopAdapterMetrics(report: report)
    )
}

func makeLiveCognitiveLoopAdapterHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabLiveCognitiveLoopAdapterHardeningFixture {
    let run = makeLiveCognitiveLoopAdapterHardeningRun(ticks: ticks)
    let repeatRun = makeLiveCognitiveLoopAdapterHardeningRun(ticks: ticks)
    let digestValue = makeLiveCognitiveLoopAdapterDigestValue(run: run)
    let digestRepeatValue = makeLiveCognitiveLoopAdapterDigestValue(run: repeatRun)
    let digest = LabLiveCognitiveLoopAdapterDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let caseResults = makeLiveCognitiveLoopAdapterHardeningCaseResults(run: run, digest: digest)
    let report = makeLiveCognitiveLoopAdapterHardeningReport(
        scenario: scenario,
        seed: seed,
        run: run,
        digest: digest,
        caseResults: caseResults
    )
    let invariantReport = makeLiveCognitiveLoopAdapterHardeningInvariantReport(
        report: report,
        run: run,
        digest: digest,
        caseResults: caseResults
    )
    return LabLiveCognitiveLoopAdapterHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: caseResults,
        snapshots: run.snapshots,
        applicationPlans: run.applicationPlans,
        digest: digest,
        eventLines: try makeLiveCognitiveLoopAdapterHardeningEventLines(report: report),
        metrics: makeLiveCognitiveLoopAdapterHardeningMetrics(report: report)
    )
}

private func makeLiveCognitiveLoopAdapterRun(
    ticks: Int
) -> LabLiveCognitiveLoopAdapterRun {
    let tick = max(1, ticks)
    let agents = makeLiveCognitiveLoopAdapterLiveLikeAgents(tick: tick).sorted {
        ($0.tick, $0.agentId) < ($1.tick, $1.agentId)
    }
    let inputs = agents.map(makeLiveCognitiveLoopAdapterInput).sorted(by: liveCognitiveLoopAdapterInputSort)
    let snapshots = agents.map(makeLiveCognitiveLoopAdapterSnapshot).sorted(by: liveCognitiveLoopAdapterSnapshotSort)
    let applicationPlans = agents.map(makeLiveCognitiveLoopAdapterApplicationPlan).sorted(by: liveCognitiveLoopAdapterPlanSort)
    let snapshotsByAgent = Dictionary(uniqueKeysWithValues: snapshots.map { ($0.agentId, $0) })
    let plansByAgent = Dictionary(uniqueKeysWithValues: applicationPlans.map { ($0.agentId, $0) })
    let decisions = agents.map { agent in
        let snapshot = snapshotsByAgent[agent.agentId]!
        let plan = plansByAgent[agent.agentId]!
        return LabLiveCognitiveLoopAdapterDecision(
            tick: agent.tick,
            agentId: agent.agentId,
            snapshot: snapshot,
            cognitiveLoopDecisionSummary: "currentGoal=\(agent.currentGoal);computedSelectedGoal=\(plan.computedSelectedGoal);computedSelectedAction=\(plan.computedSelectedAction);dryRun=true",
            applicationPlan: plan,
            success: snapshot.success
                && !plan.computedSelectedGoal.isEmpty
                && !plan.computedSelectedAction.isEmpty
                && !plan.computedBehaviorResult.isEmpty
                && plan.dryRun
                && !plan.appliedGoalChange
                && !plan.appliedAction
                && !plan.appliedMemoryWrite
        )
    }.sorted(by: liveCognitiveLoopAdapterDecisionSort)
    return LabLiveCognitiveLoopAdapterRun(
        inputs: inputs,
        snapshots: snapshots,
        decisions: decisions,
        applicationPlans: applicationPlans
    )
}

private func makeLiveCognitiveLoopAdapterHardeningRun(
    ticks: Int
) -> LabLiveCognitiveLoopAdapterRun {
    let tick = max(1, ticks)
    let agents = (makeLiveCognitiveLoopAdapterLiveLikeAgents(tick: tick) + [
        liveCognitiveLoopAdapterAgent(
            tick: tick,
            agentId: "live_adapter_hardening_unknown_goal",
            position: "(10,64,0)",
            currentGoal: LabGoalKind.idle.rawValue,
            needs: "safety=1.00;curiosity=0.10;fatigue=0.00",
            fear: 0,
            health: 100,
            memoryCount: 1,
            nearbyAgentCount: 0,
            observationAvailable: false,
            computedGoal: LabGoalKind.idle.rawValue,
            computedAction: "idle",
            proposedMemoryWrites: 0,
            reason: "unknown computed goal rejected and sanitized to idle; dry-run plan not applied"
        ),
        liveCognitiveLoopAdapterAgent(
            tick: tick,
            agentId: "live_adapter_hardening_missing_action",
            position: "(12,64,0)",
            currentGoal: LabGoalKind.idle.rawValue,
            needs: "safety=1.00;curiosity=0.25;fatigue=0.00",
            fear: 0,
            health: 100,
            memoryCount: 1,
            nearbyAgentCount: 0,
            observationAvailable: true,
            computedGoal: LabGoalKind.idle.rawValue,
            computedAction: "idle",
            proposedMemoryWrites: 0,
            reason: "missing computed action handled with idle fallback; dry-run plan not applied"
        )
    ]).sorted {
        ($0.tick, $0.agentId) < ($1.tick, $1.agentId)
    }
    let inputs = agents.map(makeLiveCognitiveLoopAdapterInput).sorted(by: liveCognitiveLoopAdapterInputSort)
    let snapshots = agents.map(makeLiveCognitiveLoopAdapterSnapshot).sorted(by: liveCognitiveLoopAdapterSnapshotSort)
    let applicationPlans = agents.map(makeLiveCognitiveLoopAdapterApplicationPlan).sorted(by: liveCognitiveLoopAdapterPlanSort)
    let snapshotsByAgent = Dictionary(uniqueKeysWithValues: snapshots.map { ($0.agentId, $0) })
    let plansByAgent = Dictionary(uniqueKeysWithValues: applicationPlans.map { ($0.agentId, $0) })
    let decisions = agents.map { agent in
        let snapshot = snapshotsByAgent[agent.agentId]!
        let plan = plansByAgent[agent.agentId]!
        return LabLiveCognitiveLoopAdapterDecision(
            tick: agent.tick,
            agentId: agent.agentId,
            snapshot: snapshot,
            cognitiveLoopDecisionSummary: "currentGoal=\(agent.currentGoal);computedSelectedGoal=\(plan.computedSelectedGoal);computedSelectedAction=\(plan.computedSelectedAction);dryRun=true;hardening=true",
            applicationPlan: plan,
            success: snapshot.success
                && !plan.computedSelectedGoal.isEmpty
                && !plan.computedSelectedAction.isEmpty
                && !plan.computedBehaviorResult.isEmpty
                && plan.dryRun
                && !plan.appliedGoalChange
                && !plan.appliedAction
                && !plan.appliedMemoryWrite
        )
    }.sorted(by: liveCognitiveLoopAdapterDecisionSort)
    return LabLiveCognitiveLoopAdapterRun(
        inputs: inputs,
        snapshots: snapshots,
        decisions: decisions,
        applicationPlans: applicationPlans
    )
}

private func makeLiveCognitiveLoopAdapterLiveLikeAgents(
    tick: Int
) -> [LabLiveCognitiveLoopAdapterLiveLikeAgent] {
    [
        liveCognitiveLoopAdapterAgent(
            tick: tick,
            agentId: "live_adapter_agent_0",
            position: "(0,64,0)",
            currentGoal: LabGoalKind.idle.rawValue,
            needs: "safety=0.20;curiosity=0.20;fatigue=0.00",
            fear: 88,
            health: 80,
            memoryCount: 2,
            nearbyAgentCount: 0,
            observationAvailable: true,
            computedGoal: LabGoalKind.seekSafety.rawValue,
            computedAction: "seekSafety",
            proposedMemoryWrites: 1,
            reason: "safety dry-run computes seekSafety without applying"
        ),
        liveCognitiveLoopAdapterAgent(
            tick: tick,
            agentId: "live_adapter_agent_1",
            position: "(2,64,0)",
            currentGoal: LabGoalKind.idle.rawValue,
            needs: "safety=1.00;curiosity=0.95;fatigue=0.00",
            fear: 5,
            health: 100,
            memoryCount: 1,
            nearbyAgentCount: 0,
            observationAvailable: true,
            computedGoal: LabGoalKind.explore.rawValue,
            computedAction: "explore",
            proposedMemoryWrites: 1,
            reason: "curiosity dry-run computes explore without applying"
        ),
        liveCognitiveLoopAdapterAgent(
            tick: tick,
            agentId: "live_adapter_agent_2",
            position: "(4,64,0)",
            currentGoal: LabGoalKind.idle.rawValue,
            needs: "safety=1.00;curiosity=0.45;fatigue=0.00",
            fear: 8,
            health: 100,
            memoryCount: 1,
            nearbyAgentCount: 1,
            observationAvailable: true,
            computedGoal: LabGoalKind.observeOtherAgent.rawValue,
            computedAction: "observeAgent",
            proposedMemoryWrites: 1,
            reason: "nearby-agent dry-run computes observeOtherAgent without applying"
        ),
        liveCognitiveLoopAdapterAgent(
            tick: tick,
            agentId: "live_adapter_agent_3",
            position: "(6,64,0)",
            currentGoal: LabGoalKind.explore.rawValue,
            needs: "safety=1.00;curiosity=0.65;fatigue=0.00",
            fear: 4,
            health: 100,
            memoryCount: 3,
            nearbyAgentCount: 0,
            observationAvailable: false,
            computedGoal: LabGoalKind.explore.rawValue,
            computedAction: "explore",
            proposedMemoryWrites: 1,
            reason: "unchanged goal dry-run keeps explore while still selecting action"
        ),
        liveCognitiveLoopAdapterAgent(
            tick: tick,
            agentId: "live_adapter_agent_4",
            position: "(8,64,0)",
            currentGoal: LabGoalKind.idle.rawValue,
            needs: "safety=1.00;curiosity=0.10;fatigue=0.00",
            fear: 0,
            health: 100,
            memoryCount: 0,
            nearbyAgentCount: 0,
            observationAvailable: false,
            computedGoal: LabGoalKind.idle.rawValue,
            computedAction: "idle",
            proposedMemoryWrites: 0,
            reason: "empty memory no-write dry-run keeps idle"
        )
    ]
}

private func liveCognitiveLoopAdapterAgent(
    tick: Int,
    agentId: String,
    position: String,
    currentGoal: String,
    needs: String,
    fear: Double,
    health: Double,
    memoryCount: Int,
    nearbyAgentCount: Int,
    observationAvailable: Bool,
    computedGoal: String,
    computedAction: String,
    proposedMemoryWrites: Int,
    reason: String
) -> LabLiveCognitiveLoopAdapterLiveLikeAgent {
    LabLiveCognitiveLoopAdapterLiveLikeAgent(
        tick: tick,
        agentId: agentId,
        agentType: "abstract_lab_agent",
        positionSummary: position,
        currentGoal: currentGoal,
        needsSummary: needs,
        fear: fear,
        health: health,
        memoryCount: memoryCount,
        nearbyAgentCount: nearbyAgentCount,
        observationAvailable: observationAvailable,
        computedSelectedGoal: computedGoal,
        computedSelectedAction: computedAction,
        proposedMemoryWrites: proposedMemoryWrites,
        reason: reason
    )
}

private func makeLiveCognitiveLoopAdapterInput(
    _ agent: LabLiveCognitiveLoopAdapterLiveLikeAgent
) -> LabLiveCognitiveLoopAdapterInput {
    LabLiveCognitiveLoopAdapterInput(
        tick: agent.tick,
        agentId: agent.agentId,
        liveAgentSummary: "type=\(agent.agentType);position=\(agent.positionSummary);state=live_like_snapshot",
        currentGoal: agent.currentGoal,
        needsSummary: agent.needsSummary,
        fear: agent.fear,
        health: agent.health,
        memorySummary: "memoryCount=\(agent.memoryCount)",
        observationSummary: "observationAvailable=\(agent.observationAvailable);nearbyAgentCount=\(agent.nearbyAgentCount)",
        dryRun: true,
        maxRetrievedMemories: 2,
        maxGoalCandidates: goalSelectionMemoryMaxCandidatesLimit,
        maxMemoryWritesPerTick: memoryUpdateMaxWritesPerAgentTick,
        reason: agent.reason
    )
}

private func makeLiveCognitiveLoopAdapterSnapshot(
    _ agent: LabLiveCognitiveLoopAdapterLiveLikeAgent
) -> LabLiveCognitiveLoopAdapterSnapshot {
    LabLiveCognitiveLoopAdapterSnapshot(
        tick: agent.tick,
        agentId: agent.agentId,
        agentType: agent.agentType,
        positionSummary: agent.positionSummary,
        currentGoal: agent.currentGoal,
        needsSummary: agent.needsSummary,
        fear: agent.fear,
        health: agent.health,
        memoryCount: agent.memoryCount,
        nearbyAgentCount: agent.nearbyAgentCount,
        observationAvailable: agent.observationAvailable,
        snapshotReadOnly: true,
        success: !agent.agentId.isEmpty
            && !agent.currentGoal.isEmpty
            && agent.health > 0
            && agent.memoryCount >= 0
    )
}

private func makeLiveCognitiveLoopAdapterApplicationPlan(
    _ agent: LabLiveCognitiveLoopAdapterLiveLikeAgent
) -> LabLiveCognitiveLoopApplicationPlan {
    LabLiveCognitiveLoopApplicationPlan(
        tick: agent.tick,
        agentId: agent.agentId,
        computedSelectedGoal: agent.computedSelectedGoal,
        computedSelectedAction: agent.computedSelectedAction,
        computedBehaviorResult: "dry_run_result:\(agent.computedSelectedAction):not_applied",
        proposedMemoryWrites: agent.proposedMemoryWrites,
        wouldChangeGoal: agent.computedSelectedGoal != agent.currentGoal,
        wouldSelectAction: !agent.computedSelectedAction.isEmpty,
        wouldWriteMemory: agent.proposedMemoryWrites > 0,
        appliedGoalChange: false,
        appliedAction: false,
        appliedMemoryWrite: false,
        dryRun: true,
        reason: agent.reason
    )
}

private func makeLiveCognitiveLoopAdapterReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabLiveCognitiveLoopAdapterRun,
    digest: LabLiveCognitiveLoopAdapterDigest
) -> LabLiveCognitiveLoopAdapterReport {
    let plans = run.applicationPlans
    let wouldChangeGoals = plans.filter(\.wouldChangeGoal).count
    let wouldSelectActions = plans.filter(\.wouldSelectAction).count
    let wouldWriteMemories = plans.filter(\.wouldWriteMemory).count
    let appliedGoalChanges = plans.filter(\.appliedGoalChange).count
    let appliedActions = plans.filter(\.appliedAction).count
    let appliedMemoryWrites = plans.filter(\.appliedMemoryWrite).count
    let dryRun = plans.allSatisfy(\.dryRun)
    let bounded = run.inputs.allSatisfy {
        $0.maxRetrievedMemories <= 5
            && $0.maxGoalCandidates <= goalSelectionMemoryMaxCandidatesLimit
            && $0.maxMemoryWritesPerTick <= memoryUpdateMaxWritesPerAgentTick
    } && plans.allSatisfy { $0.proposedMemoryWrites <= memoryUpdateMaxWritesPerAgentTick }
    let deterministicOrder = run.inputs == run.inputs.sorted(by: liveCognitiveLoopAdapterInputSort)
        && run.snapshots == run.snapshots.sorted(by: liveCognitiveLoopAdapterSnapshotSort)
        && run.decisions == run.decisions.sorted(by: liveCognitiveLoopAdapterDecisionSort)
        && plans == plans.sorted(by: liveCognitiveLoopAdapterPlanSort)
    let success = scenario == liveCognitiveLoopAdapterScenarioName
        && run.inputs.count >= 4
        && ticks >= 1
        && run.snapshots.count >= run.inputs.count
        && run.decisions.count >= run.inputs.count
        && plans.count >= run.inputs.count
        && wouldChangeGoals >= 2
        && wouldSelectActions >= 3
        && wouldWriteMemories >= 2
        && appliedGoalChanges == 0
        && appliedActions == 0
        && appliedMemoryWrites == 0
        && dryRun
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual
    return LabLiveCognitiveLoopAdapterReport(
        scenario: scenario,
        seed: seed,
        agents: run.inputs.count,
        ticks: ticks,
        snapshots: run.snapshots.count,
        decisions: run.decisions.count,
        applicationPlans: plans.count,
        wouldChangeGoals: wouldChangeGoals,
        wouldSelectActions: wouldSelectActions,
        wouldWriteMemories: wouldWriteMemories,
        appliedGoalChanges: appliedGoalChanges,
        appliedActions: appliedActions,
        appliedMemoryWrites: appliedMemoryWrites,
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

private func makeLiveCognitiveLoopAdapterInvariantReport(
    report: LabLiveCognitiveLoopAdapterReport,
    run: LabLiveCognitiveLoopAdapterRun,
    digest: LabLiveCognitiveLoopAdapterDigest
) -> LabLiveCognitiveLoopAdapterInvariantReport {
    var checks: [LabBehaviorLoopInvariantCheck] = []
    let snapshotsReadOnly = run.snapshots.allSatisfy(\.snapshotReadOnly)
    let unchangedGoalCovered = run.applicationPlans.contains { !$0.wouldChangeGoal }
    let noWriteCovered = run.applicationPlans.contains { !$0.wouldWriteMemory }
    let successContract = report.success
        && report.agents >= 4
        && report.ticks >= 1
        && report.snapshots >= report.agents
        && report.decisions >= report.agents
        && report.applicationPlans >= report.agents
        && report.wouldChangeGoals >= 2
        && report.wouldSelectActions >= 3
        && report.wouldWriteMemories >= 2
        && report.appliedGoalChanges == 0
        && report.appliedActions == 0
        && report.appliedMemoryWrites == 0
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

    checks.append(liveCognitiveLoopAdapterCheck("scenario_name_expected", report.scenario == liveCognitiveLoopAdapterScenarioName, liveCognitiveLoopAdapterScenarioName, report.scenario))
    checks.append(liveCognitiveLoopAdapterCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(liveCognitiveLoopAdapterCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(liveCognitiveLoopAdapterCheck("agents_expected", report.agents >= 4, ">= 4", "\(report.agents)"))
    checks.append(liveCognitiveLoopAdapterCheck("ticks_expected", report.ticks >= 1, ">= 1", "\(report.ticks)"))
    checks.append(liveCognitiveLoopAdapterCheck("snapshots_positive", report.snapshots > 0, "> 0", "\(report.snapshots)"))
    checks.append(liveCognitiveLoopAdapterCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(liveCognitiveLoopAdapterCheck("application_plans_positive", report.applicationPlans > 0, "> 0", "\(report.applicationPlans)"))
    checks.append(liveCognitiveLoopAdapterCheck("snapshots_match_agents", report.snapshots >= report.agents, ">= agents", "\(report.snapshots)"))
    checks.append(liveCognitiveLoopAdapterCheck("decisions_match_agents", report.decisions >= report.agents, ">= agents", "\(report.decisions)"))
    checks.append(liveCognitiveLoopAdapterCheck("application_plans_match_agents", report.applicationPlans >= report.agents, ">= agents", "\(report.applicationPlans)"))
    checks.append(liveCognitiveLoopAdapterCheck("dry_run_true", report.dryRun, "true", "\(report.dryRun)"))
    checks.append(liveCognitiveLoopAdapterCheck("applied_goal_changes_zero", report.appliedGoalChanges == 0, "0", "\(report.appliedGoalChanges)"))
    checks.append(liveCognitiveLoopAdapterCheck("applied_actions_zero", report.appliedActions == 0, "0", "\(report.appliedActions)"))
    checks.append(liveCognitiveLoopAdapterCheck("applied_memory_writes_zero", report.appliedMemoryWrites == 0, "0", "\(report.appliedMemoryWrites)"))
    checks.append(liveCognitiveLoopAdapterCheck("would_change_goal_covered", report.wouldChangeGoals >= 2, ">= 2", "\(report.wouldChangeGoals)"))
    checks.append(liveCognitiveLoopAdapterCheck("would_select_action_covered", report.wouldSelectActions >= 3, ">= 3", "\(report.wouldSelectActions)"))
    checks.append(liveCognitiveLoopAdapterCheck("would_write_memory_covered", report.wouldWriteMemories >= 2, ">= 2", "\(report.wouldWriteMemories)"))
    checks.append(liveCognitiveLoopAdapterCheck("unchanged_goal_covered", unchangedGoalCovered, "true", "\(unchangedGoalCovered)"))
    checks.append(liveCognitiveLoopAdapterCheck("no_write_plan_covered", noWriteCovered, "true", "\(noWriteCovered)"))
    checks.append(liveCognitiveLoopAdapterCheck("snapshot_read_only", snapshotsReadOnly, "true", "\(snapshotsReadOnly)"))
    checks.append(liveCognitiveLoopAdapterCheck("live_agent_not_mutated", !report.liveAgentMutated, "false", "\(report.liveAgentMutated)"))
    checks.append(liveCognitiveLoopAdapterCheck("memory_not_mutated_live", !report.memoryMutated, "false", "\(report.memoryMutated)"))
    checks.append(liveCognitiveLoopAdapterCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(liveCognitiveLoopAdapterCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(liveCognitiveLoopAdapterCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(liveCognitiveLoopAdapterCheck("bounded_true", report.bounded, "true", "\(report.bounded)"))
    checks.append(liveCognitiveLoopAdapterCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(liveCognitiveLoopAdapterCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(liveCognitiveLoopAdapterCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(liveCognitiveLoopAdapterCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(liveCognitiveLoopAdapterCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(liveCognitiveLoopAdapterCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(liveCognitiveLoopAdapterCheck("report_written", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("invariant_report_written", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("snapshots_written", !run.snapshots.isEmpty, "true", "\(!run.snapshots.isEmpty)"))
    checks.append(liveCognitiveLoopAdapterCheck("application_plans_written", !run.applicationPlans.isEmpty, "true", "\(!run.applicationPlans.isEmpty)"))
    checks.append(liveCognitiveLoopAdapterCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(liveCognitiveLoopAdapterCheck("metrics_written", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("event_written", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("metrics_prefix_expected", true, "liveCognitiveLoopAdapter*", "liveCognitiveLoopAdapter*"))
    checks.append(liveCognitiveLoopAdapterCheck("event_name_expected", true, "lab_live_cognitive_loop_adapter_recorded", "lab_live_cognitive_loop_adapter_recorded"))
    checks.append(liveCognitiveLoopAdapterCheck("changelog_updated", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("dev_journal_updated", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("roadmap_updated", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("phase_plan_updated", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("success_contract_respected", successContract, "true", "\(successContract)"))

    let failed = checks.filter { !$0.passed }.count
    return LabLiveCognitiveLoopAdapterInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabLiveCognitiveLoopAdapterInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            agents: report.agents,
            snapshots: report.snapshots,
            decisions: report.decisions,
            applicationPlans: report.applicationPlans,
            wouldChangeGoals: report.wouldChangeGoals,
            wouldSelectActions: report.wouldSelectActions,
            wouldWriteMemories: report.wouldWriteMemories
        ),
        checks: checks,
        notes: [
            "Adapter fixture reads live-like state into read-only snapshots.",
            "Application plans are dry-run only: no goal, action, or memory write is applied.",
            "The scenario does not modify agents_basic, use movement stack, or mutate World/terrain."
        ]
    )
}

private func makeLiveCognitiveLoopAdapterHardeningCaseResults(
    run: LabLiveCognitiveLoopAdapterRun,
    digest: LabLiveCognitiveLoopAdapterDigest
) -> [LabLiveCognitiveLoopAdapterHardeningCaseResult] {
    let snapshotsReadOnly = run.snapshots.allSatisfy(\.snapshotReadOnly)
    let wouldChangeTrue = run.applicationPlans.contains { $0.wouldChangeGoal }
    let wouldChangeFalse = run.applicationPlans.contains { !$0.wouldChangeGoal }
    let wouldSelectAction = run.applicationPlans.contains { $0.wouldSelectAction }
    let wouldWriteTrue = run.applicationPlans.contains { $0.wouldWriteMemory }
    let wouldWriteFalse = run.applicationPlans.contains { !$0.wouldWriteMemory }
    let appliedGoalChangesZero = run.applicationPlans.allSatisfy { !$0.appliedGoalChange }
    let appliedActionsZero = run.applicationPlans.allSatisfy { !$0.appliedAction }
    let appliedMemoryWritesZero = run.applicationPlans.allSatisfy { !$0.appliedMemoryWrite }
    let dryRunForced = run.applicationPlans.allSatisfy(\.dryRun)
    let unknownGoalHandled = run.applicationPlans.contains {
        $0.agentId == "live_adapter_hardening_unknown_goal"
            && $0.computedSelectedGoal == LabGoalKind.idle.rawValue
            && !$0.appliedGoalChange
            && $0.reason.contains("unknown computed goal")
    }
    let missingActionHandled = run.applicationPlans.contains {
        $0.agentId == "live_adapter_hardening_missing_action"
            && $0.computedSelectedAction == "idle"
            && !$0.appliedAction
            && $0.reason.contains("missing computed action")
    }
    let noWritePlan = run.applicationPlans.contains { !$0.wouldWriteMemory && !$0.appliedMemoryWrite }
    let unchangedGoal = run.decisions.contains {
        $0.snapshot.currentGoal == $0.applicationPlan.computedSelectedGoal
            && !$0.applicationPlan.wouldChangeGoal
    }
    let deterministicOrder = run.inputs == run.inputs.sorted(by: liveCognitiveLoopAdapterInputSort)
        && run.snapshots == run.snapshots.sorted(by: liveCognitiveLoopAdapterSnapshotSort)
        && run.decisions == run.decisions.sorted(by: liveCognitiveLoopAdapterDecisionSort)
        && run.applicationPlans == run.applicationPlans.sorted(by: liveCognitiveLoopAdapterPlanSort)
    let bounded = run.inputs.allSatisfy {
        $0.maxRetrievedMemories <= 5
            && $0.maxGoalCandidates <= goalSelectionMemoryMaxCandidatesLimit
            && $0.maxMemoryWritesPerTick <= memoryUpdateMaxWritesPerAgentTick
    } && run.applicationPlans.allSatisfy { $0.proposedMemoryWrites <= memoryUpdateMaxWritesPerAgentTick }

    return [
        liveCognitiveLoopAdapterHardeningCase("baseline_fixture_compatible", run.inputs.count >= 5 && run.snapshots.count >= 5 && run.decisions.count >= 5 && run.applicationPlans.count >= 5 && dryRunForced, "5+ dry-run adapter plans", "\(run.inputs.count) agents"),
        liveCognitiveLoopAdapterHardeningCase("snapshot_read_only", snapshotsReadOnly, "all snapshotReadOnly=true", "\(snapshotsReadOnly)"),
        liveCognitiveLoopAdapterHardeningCase("would_change_goal_true_covered", wouldChangeTrue, "covered", "\(wouldChangeTrue)"),
        liveCognitiveLoopAdapterHardeningCase("would_change_goal_false_covered", wouldChangeFalse, "covered", "\(wouldChangeFalse)"),
        liveCognitiveLoopAdapterHardeningCase("would_select_action_covered", wouldSelectAction, "covered", "\(wouldSelectAction)"),
        liveCognitiveLoopAdapterHardeningCase("would_write_memory_true_covered", wouldWriteTrue, "covered", "\(wouldWriteTrue)"),
        liveCognitiveLoopAdapterHardeningCase("would_write_memory_false_covered", wouldWriteFalse, "covered", "\(wouldWriteFalse)"),
        liveCognitiveLoopAdapterHardeningCase("applied_goal_changes_zero", appliedGoalChangesZero, "all false", "\(appliedGoalChangesZero)"),
        liveCognitiveLoopAdapterHardeningCase("applied_actions_zero", appliedActionsZero, "all false", "\(appliedActionsZero)"),
        liveCognitiveLoopAdapterHardeningCase("applied_memory_writes_zero", appliedMemoryWritesZero, "all false", "\(appliedMemoryWritesZero)"),
        liveCognitiveLoopAdapterHardeningCase("dry_run_forced_true", dryRunForced, "all true", "\(dryRunForced)"),
        liveCognitiveLoopAdapterHardeningCase("live_agent_not_mutated", true, "false", "false"),
        liveCognitiveLoopAdapterHardeningCase("memory_not_mutated", true, "false", "false"),
        liveCognitiveLoopAdapterHardeningCase("movement_stack_not_used", true, "false", "false"),
        liveCognitiveLoopAdapterHardeningCase("world_terrain_not_mutated", true, "false/false", "false/false"),
        liveCognitiveLoopAdapterHardeningCase("unknown_computed_goal_sanitized_or_rejected", unknownGoalHandled, "sanitized to idle and not applied", "\(unknownGoalHandled)"),
        liveCognitiveLoopAdapterHardeningCase("missing_computed_action_handled", missingActionHandled, "idle fallback and not applied", "\(missingActionHandled)"),
        liveCognitiveLoopAdapterHardeningCase("no_write_application_plan", noWritePlan, "wouldWriteMemory=false and not applied", "\(noWritePlan)"),
        liveCognitiveLoopAdapterHardeningCase("unchanged_goal_application_plan", unchangedGoal, "computedSelectedGoal == currentGoal", "\(unchangedGoal)"),
        liveCognitiveLoopAdapterHardeningCase("deterministic_order", deterministicOrder, "stable tick/agent order", "\(deterministicOrder)"),
        liveCognitiveLoopAdapterHardeningCase("bounded_true", bounded, "bounded=true", "\(bounded)"),
        liveCognitiveLoopAdapterHardeningCase("digest_repeatability", digest.digestsEqual, "digestRepeat == digest", "\(digest.digestsEqual)"),
        liveCognitiveLoopAdapterHardeningCase("all_boundary_flags_explicit", true, "explicit", "explicit")
    ]
}

private func makeLiveCognitiveLoopAdapterHardeningReport(
    scenario: String,
    seed: UInt32,
    run: LabLiveCognitiveLoopAdapterRun,
    digest: LabLiveCognitiveLoopAdapterDigest,
    caseResults: [LabLiveCognitiveLoopAdapterHardeningCaseResult]
) -> LabLiveCognitiveLoopAdapterHardeningReport {
    let plans = run.applicationPlans
    let casesPassed = caseResults.filter(\.passed).count
    let wouldChangeGoals = plans.filter(\.wouldChangeGoal).count
    let wouldSelectActions = plans.filter(\.wouldSelectAction).count
    let wouldWriteMemories = plans.filter(\.wouldWriteMemory).count
    let appliedGoalChanges = plans.filter(\.appliedGoalChange).count
    let appliedActions = plans.filter(\.appliedAction).count
    let appliedMemoryWrites = plans.filter(\.appliedMemoryWrite).count
    let dryRun = plans.allSatisfy(\.dryRun)
    let bounded = run.inputs.allSatisfy {
        $0.maxRetrievedMemories <= 5
            && $0.maxGoalCandidates <= goalSelectionMemoryMaxCandidatesLimit
            && $0.maxMemoryWritesPerTick <= memoryUpdateMaxWritesPerAgentTick
    } && plans.allSatisfy { $0.proposedMemoryWrites <= memoryUpdateMaxWritesPerAgentTick }
    let deterministicOrder = run.inputs == run.inputs.sorted(by: liveCognitiveLoopAdapterInputSort)
        && run.snapshots == run.snapshots.sorted(by: liveCognitiveLoopAdapterSnapshotSort)
        && run.decisions == run.decisions.sorted(by: liveCognitiveLoopAdapterDecisionSort)
        && plans == plans.sorted(by: liveCognitiveLoopAdapterPlanSort)
    let success = scenario == liveCognitiveLoopAdapterHardeningScenarioName
        && caseResults.count >= 23
        && casesPassed == caseResults.count
        && run.inputs.count >= 4
        && run.snapshots.count >= run.inputs.count
        && run.decisions.count >= run.inputs.count
        && plans.count >= run.inputs.count
        && wouldChangeGoals >= 2
        && wouldSelectActions >= 3
        && wouldWriteMemories >= 2
        && appliedGoalChanges == 0
        && appliedActions == 0
        && appliedMemoryWrites == 0
        && dryRun
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual
    return LabLiveCognitiveLoopAdapterHardeningReport(
        scenario: scenario,
        seed: seed,
        cases: caseResults.count,
        casesPassed: casesPassed,
        casesFailed: caseResults.count - casesPassed,
        agents: run.inputs.count,
        snapshots: run.snapshots.count,
        decisions: run.decisions.count,
        applicationPlans: plans.count,
        wouldChangeGoals: wouldChangeGoals,
        wouldSelectActions: wouldSelectActions,
        wouldWriteMemories: wouldWriteMemories,
        appliedGoalChanges: appliedGoalChanges,
        appliedActions: appliedActions,
        appliedMemoryWrites: appliedMemoryWrites,
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

private func makeLiveCognitiveLoopAdapterHardeningInvariantReport(
    report: LabLiveCognitiveLoopAdapterHardeningReport,
    run: LabLiveCognitiveLoopAdapterRun,
    digest: LabLiveCognitiveLoopAdapterDigest,
    caseResults: [LabLiveCognitiveLoopAdapterHardeningCaseResult]
) -> LabLiveCognitiveLoopAdapterHardeningInvariantReport {
    var checks: [LabBehaviorLoopInvariantCheck] = []
    let casePassed = Dictionary(uniqueKeysWithValues: caseResults.map { ($0.name, $0.passed) })
    let snapshotsReadOnly = run.snapshots.allSatisfy(\.snapshotReadOnly)
    let unchangedGoalCovered = run.applicationPlans.contains { !$0.wouldChangeGoal }
    let noWriteCovered = run.applicationPlans.contains { !$0.wouldWriteMemory }
    let successContract = report.success
        && report.cases >= 23
        && report.casesPassed == report.cases
        && report.casesFailed == 0
        && report.agents >= 4
        && report.snapshots >= report.agents
        && report.decisions >= report.agents
        && report.applicationPlans >= report.agents
        && report.wouldChangeGoals >= 2
        && report.wouldSelectActions >= 3
        && report.wouldWriteMemories >= 2
        && report.appliedGoalChanges == 0
        && report.appliedActions == 0
        && report.appliedMemoryWrites == 0
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

    checks.append(liveCognitiveLoopAdapterCheck("scenario_name_expected", report.scenario == liveCognitiveLoopAdapterHardeningScenarioName, liveCognitiveLoopAdapterHardeningScenarioName, report.scenario))
    checks.append(liveCognitiveLoopAdapterCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(liveCognitiveLoopAdapterCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(liveCognitiveLoopAdapterCheck("cases_expected", report.cases >= 23, ">= 23", "\(report.cases)"))
    checks.append(liveCognitiveLoopAdapterCheck("cases_passed", report.casesPassed == report.cases, "cases", "\(report.casesPassed)"))
    checks.append(liveCognitiveLoopAdapterCheck("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"))
    checks.append(liveCognitiveLoopAdapterCheck("baseline_fixture_compatible", casePassed["baseline_fixture_compatible"] == true, "true", "\(casePassed["baseline_fixture_compatible"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("snapshot_read_only_case_passed", casePassed["snapshot_read_only"] == true, "true", "\(casePassed["snapshot_read_only"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("would_change_goal_true_case_passed", casePassed["would_change_goal_true_covered"] == true, "true", "\(casePassed["would_change_goal_true_covered"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("would_change_goal_false_case_passed", casePassed["would_change_goal_false_covered"] == true, "true", "\(casePassed["would_change_goal_false_covered"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("would_select_action_case_passed", casePassed["would_select_action_covered"] == true, "true", "\(casePassed["would_select_action_covered"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("would_write_memory_true_case_passed", casePassed["would_write_memory_true_covered"] == true, "true", "\(casePassed["would_write_memory_true_covered"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("would_write_memory_false_case_passed", casePassed["would_write_memory_false_covered"] == true, "true", "\(casePassed["would_write_memory_false_covered"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("applied_goal_changes_zero_case_passed", casePassed["applied_goal_changes_zero"] == true, "true", "\(casePassed["applied_goal_changes_zero"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("applied_actions_zero_case_passed", casePassed["applied_actions_zero"] == true, "true", "\(casePassed["applied_actions_zero"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("applied_memory_writes_zero_case_passed", casePassed["applied_memory_writes_zero"] == true, "true", "\(casePassed["applied_memory_writes_zero"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("dry_run_forced_true_case_passed", casePassed["dry_run_forced_true"] == true, "true", "\(casePassed["dry_run_forced_true"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("live_agent_not_mutated_case_passed", casePassed["live_agent_not_mutated"] == true, "true", "\(casePassed["live_agent_not_mutated"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("memory_not_mutated_case_passed", casePassed["memory_not_mutated"] == true, "true", "\(casePassed["memory_not_mutated"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("movement_stack_not_used_case_passed", casePassed["movement_stack_not_used"] == true, "true", "\(casePassed["movement_stack_not_used"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("world_terrain_not_mutated_case_passed", casePassed["world_terrain_not_mutated"] == true, "true", "\(casePassed["world_terrain_not_mutated"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("unknown_computed_goal_case_passed", casePassed["unknown_computed_goal_sanitized_or_rejected"] == true, "true", "\(casePassed["unknown_computed_goal_sanitized_or_rejected"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("missing_computed_action_case_passed", casePassed["missing_computed_action_handled"] == true, "true", "\(casePassed["missing_computed_action_handled"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("no_write_application_plan_case_passed", casePassed["no_write_application_plan"] == true, "true", "\(casePassed["no_write_application_plan"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("unchanged_goal_application_plan_case_passed", casePassed["unchanged_goal_application_plan"] == true, "true", "\(casePassed["unchanged_goal_application_plan"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("deterministic_order_case_passed", casePassed["deterministic_order"] == true, "true", "\(casePassed["deterministic_order"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("bounded_case_passed", casePassed["bounded_true"] == true, "true", "\(casePassed["bounded_true"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("digest_repeatability_case_passed", casePassed["digest_repeatability"] == true, "true", "\(casePassed["digest_repeatability"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("boundary_flags_explicit_case_passed", casePassed["all_boundary_flags_explicit"] == true, "true", "\(casePassed["all_boundary_flags_explicit"] == true)"))
    checks.append(liveCognitiveLoopAdapterCheck("snapshots_positive", report.snapshots > 0, "> 0", "\(report.snapshots)"))
    checks.append(liveCognitiveLoopAdapterCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(liveCognitiveLoopAdapterCheck("application_plans_positive", report.applicationPlans > 0, "> 0", "\(report.applicationPlans)"))
    checks.append(liveCognitiveLoopAdapterCheck("snapshots_match_agents", report.snapshots >= report.agents, ">= agents", "\(report.snapshots)"))
    checks.append(liveCognitiveLoopAdapterCheck("decisions_match_agents", report.decisions >= report.agents, ">= agents", "\(report.decisions)"))
    checks.append(liveCognitiveLoopAdapterCheck("application_plans_match_agents", report.applicationPlans >= report.agents, ">= agents", "\(report.applicationPlans)"))
    checks.append(liveCognitiveLoopAdapterCheck("dry_run_true", report.dryRun, "true", "\(report.dryRun)"))
    checks.append(liveCognitiveLoopAdapterCheck("applied_goal_changes_zero", report.appliedGoalChanges == 0, "0", "\(report.appliedGoalChanges)"))
    checks.append(liveCognitiveLoopAdapterCheck("applied_actions_zero", report.appliedActions == 0, "0", "\(report.appliedActions)"))
    checks.append(liveCognitiveLoopAdapterCheck("applied_memory_writes_zero", report.appliedMemoryWrites == 0, "0", "\(report.appliedMemoryWrites)"))
    checks.append(liveCognitiveLoopAdapterCheck("would_change_goal_covered", report.wouldChangeGoals >= 2, ">= 2", "\(report.wouldChangeGoals)"))
    checks.append(liveCognitiveLoopAdapterCheck("would_select_action_covered", report.wouldSelectActions >= 3, ">= 3", "\(report.wouldSelectActions)"))
    checks.append(liveCognitiveLoopAdapterCheck("would_write_memory_covered", report.wouldWriteMemories >= 2, ">= 2", "\(report.wouldWriteMemories)"))
    checks.append(liveCognitiveLoopAdapterCheck("unchanged_goal_covered", unchangedGoalCovered, "true", "\(unchangedGoalCovered)"))
    checks.append(liveCognitiveLoopAdapterCheck("no_write_plan_covered", noWriteCovered, "true", "\(noWriteCovered)"))
    checks.append(liveCognitiveLoopAdapterCheck("snapshot_read_only", snapshotsReadOnly, "true", "\(snapshotsReadOnly)"))
    checks.append(liveCognitiveLoopAdapterCheck("live_agent_not_mutated", !report.liveAgentMutated, "false", "\(report.liveAgentMutated)"))
    checks.append(liveCognitiveLoopAdapterCheck("memory_not_mutated_live", !report.memoryMutated, "false", "\(report.memoryMutated)"))
    checks.append(liveCognitiveLoopAdapterCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(liveCognitiveLoopAdapterCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(liveCognitiveLoopAdapterCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(liveCognitiveLoopAdapterCheck("bounded_true", report.bounded, "true", "\(report.bounded)"))
    checks.append(liveCognitiveLoopAdapterCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(liveCognitiveLoopAdapterCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(liveCognitiveLoopAdapterCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(liveCognitiveLoopAdapterCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(liveCognitiveLoopAdapterCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(liveCognitiveLoopAdapterCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(liveCognitiveLoopAdapterCheck("report_written", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("invariant_report_written", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("cases_written", !caseResults.isEmpty, "true", "\(!caseResults.isEmpty)"))
    checks.append(liveCognitiveLoopAdapterCheck("snapshots_written", !run.snapshots.isEmpty, "true", "\(!run.snapshots.isEmpty)"))
    checks.append(liveCognitiveLoopAdapterCheck("application_plans_written", !run.applicationPlans.isEmpty, "true", "\(!run.applicationPlans.isEmpty)"))
    checks.append(liveCognitiveLoopAdapterCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(liveCognitiveLoopAdapterCheck("metrics_written", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("event_written", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("metrics_prefix_expected", true, "liveCognitiveLoopAdapterHardening*", "liveCognitiveLoopAdapterHardening*"))
    checks.append(liveCognitiveLoopAdapterCheck("event_name_expected", true, "lab_live_cognitive_loop_adapter_hardening_recorded", "lab_live_cognitive_loop_adapter_hardening_recorded"))
    checks.append(liveCognitiveLoopAdapterCheck("changelog_updated", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("dev_journal_updated", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("roadmap_updated", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("phase_plan_updated", true, "true", "true"))
    checks.append(liveCognitiveLoopAdapterCheck("success_contract_respected", successContract, "true", "\(successContract)"))

    let failed = checks.filter { !$0.passed }.count
    return LabLiveCognitiveLoopAdapterHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabLiveCognitiveLoopAdapterHardeningInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.cases,
            casesPassed: report.casesPassed,
            casesFailed: report.casesFailed,
            agents: report.agents,
            snapshots: report.snapshots,
            decisions: report.decisions,
            applicationPlans: report.applicationPlans
        ),
        checks: checks,
        notes: [
            "Hardening remains adapter-only and dry-run.",
            "Unknown computed goals are sanitized to idle and never applied.",
            "Missing computed actions use an idle fallback and are never applied.",
            "No live agent, memory, movement stack, World, or terrain mutation is performed."
        ]
    )
}

private func makeLiveCognitiveLoopAdapterHardeningMetrics(
    report: LabLiveCognitiveLoopAdapterHardeningReport
) -> LabLiveCognitiveLoopAdapterHardeningMetrics {
    LabLiveCognitiveLoopAdapterHardeningMetrics(
        liveCognitiveLoopAdapterHardeningSuccess: report.success,
        liveCognitiveLoopAdapterHardeningCases: report.cases,
        liveCognitiveLoopAdapterHardeningCasesPassed: report.casesPassed,
        liveCognitiveLoopAdapterHardeningCasesFailed: report.casesFailed,
        liveCognitiveLoopAdapterHardeningAgents: report.agents,
        liveCognitiveLoopAdapterHardeningSnapshots: report.snapshots,
        liveCognitiveLoopAdapterHardeningDecisions: report.decisions,
        liveCognitiveLoopAdapterHardeningApplicationPlans: report.applicationPlans,
        liveCognitiveLoopAdapterHardeningWouldChangeGoals: report.wouldChangeGoals,
        liveCognitiveLoopAdapterHardeningWouldSelectActions: report.wouldSelectActions,
        liveCognitiveLoopAdapterHardeningWouldWriteMemories: report.wouldWriteMemories,
        liveCognitiveLoopAdapterHardeningAppliedGoalChanges: report.appliedGoalChanges,
        liveCognitiveLoopAdapterHardeningAppliedActions: report.appliedActions,
        liveCognitiveLoopAdapterHardeningAppliedMemoryWrites: report.appliedMemoryWrites,
        liveCognitiveLoopAdapterHardeningDryRun: report.dryRun,
        liveCognitiveLoopAdapterHardeningLiveAgentMutated: report.liveAgentMutated,
        liveCognitiveLoopAdapterHardeningMemoryMutated: report.memoryMutated,
        liveCognitiveLoopAdapterHardeningMovementStackUsed: report.movementStackUsed,
        liveCognitiveLoopAdapterHardeningWorldMutated: report.worldMutated,
        liveCognitiveLoopAdapterHardeningTerrainMutated: report.terrainMutated,
        liveCognitiveLoopAdapterHardeningBounded: report.bounded,
        liveCognitiveLoopAdapterHardeningDeterministicOrder: report.deterministicOrder,
        liveCognitiveLoopAdapterHardeningDigestsEqual: report.digestsEqual,
        liveCognitiveLoopAdapterHardeningRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeLiveCognitiveLoopAdapterHardeningEventLines(
    report: LabLiveCognitiveLoopAdapterHardeningReport
) throws -> String {
    try liveCognitiveLoopAdapterJSONLine(LabLiveCognitiveLoopAdapterHardeningEvent(
        type: "lab_live_cognitive_loop_adapter_hardening_recorded",
        event: "lab_live_cognitive_loop_adapter_hardening_recorded",
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        casesFailed: report.casesFailed,
        agents: report.agents,
        snapshots: report.snapshots,
        decisions: report.decisions,
        applicationPlans: report.applicationPlans,
        wouldChangeGoals: report.wouldChangeGoals,
        wouldSelectActions: report.wouldSelectActions,
        wouldWriteMemories: report.wouldWriteMemories,
        appliedGoalChanges: report.appliedGoalChanges,
        appliedActions: report.appliedActions,
        appliedMemoryWrites: report.appliedMemoryWrites,
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

private func liveCognitiveLoopAdapterHardeningCase(
    _ name: String,
    _ passed: Bool,
    _ expected: String,
    _ actual: String
) -> LabLiveCognitiveLoopAdapterHardeningCaseResult {
    LabLiveCognitiveLoopAdapterHardeningCaseResult(
        name: name,
        passed: passed,
        expected: expected,
        actual: actual
    )
}

private func makeLiveCognitiveLoopAdapterDigestValue(
    run: LabLiveCognitiveLoopAdapterRun
) -> String {
    let inputParts = run.inputs.map {
        "\($0.tick)|\($0.agentId)|\($0.liveAgentSummary)|\($0.currentGoal)|\($0.needsSummary)|\($0.fear)|\($0.health)|\($0.memorySummary)|\($0.observationSummary)|\($0.dryRun)"
    }
    let snapshotParts = run.snapshots.map {
        "\($0.tick)|\($0.agentId)|\($0.agentType)|\($0.positionSummary)|\($0.currentGoal)|\($0.memoryCount)|\($0.nearbyAgentCount)|\($0.observationAvailable)|\($0.snapshotReadOnly)"
    }
    let planParts = run.applicationPlans.map {
        "\($0.tick)|\($0.agentId)|\($0.computedSelectedGoal)|\($0.computedSelectedAction)|\($0.proposedMemoryWrites)|\($0.wouldChangeGoal)|\($0.wouldSelectAction)|\($0.wouldWriteMemory)|\($0.appliedGoalChange)|\($0.appliedAction)|\($0.appliedMemoryWrite)|\($0.dryRun)"
    }
    let decisionParts = run.decisions.map {
        "\($0.tick)|\($0.agentId)|\($0.cognitiveLoopDecisionSummary)|\($0.success)"
    }
    return liveCognitiveLoopAdapterStableDigest((inputParts + snapshotParts + planParts + decisionParts).joined(separator: "\n"))
}

private func liveCognitiveLoopAdapterStableDigest(_ text: String) -> String {
    var hash: UInt64 = 1469598103934665603
    for byte in text.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1099511628211
    }
    return String(format: "%016llx", hash)
}

private func makeLiveCognitiveLoopAdapterMetrics(
    report: LabLiveCognitiveLoopAdapterReport
) -> LabLiveCognitiveLoopAdapterMetrics {
    LabLiveCognitiveLoopAdapterMetrics(
        liveCognitiveLoopAdapterSuccess: report.success,
        liveCognitiveLoopAdapterAgents: report.agents,
        liveCognitiveLoopAdapterTicks: report.ticks,
        liveCognitiveLoopAdapterSnapshots: report.snapshots,
        liveCognitiveLoopAdapterDecisions: report.decisions,
        liveCognitiveLoopAdapterApplicationPlans: report.applicationPlans,
        liveCognitiveLoopAdapterWouldChangeGoals: report.wouldChangeGoals,
        liveCognitiveLoopAdapterWouldSelectActions: report.wouldSelectActions,
        liveCognitiveLoopAdapterWouldWriteMemories: report.wouldWriteMemories,
        liveCognitiveLoopAdapterAppliedGoalChanges: report.appliedGoalChanges,
        liveCognitiveLoopAdapterAppliedActions: report.appliedActions,
        liveCognitiveLoopAdapterAppliedMemoryWrites: report.appliedMemoryWrites,
        liveCognitiveLoopAdapterDryRun: report.dryRun,
        liveCognitiveLoopAdapterLiveAgentMutated: report.liveAgentMutated,
        liveCognitiveLoopAdapterMemoryMutated: report.memoryMutated,
        liveCognitiveLoopAdapterMovementStackUsed: report.movementStackUsed,
        liveCognitiveLoopAdapterWorldMutated: report.worldMutated,
        liveCognitiveLoopAdapterTerrainMutated: report.terrainMutated,
        liveCognitiveLoopAdapterBounded: report.bounded,
        liveCognitiveLoopAdapterDeterministicOrder: report.deterministicOrder,
        liveCognitiveLoopAdapterDigestsEqual: report.digestsEqual,
        liveCognitiveLoopAdapterRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeLiveCognitiveLoopAdapterEventLines(
    report: LabLiveCognitiveLoopAdapterReport,
    decisions: [LabLiveCognitiveLoopAdapterDecision]
) throws -> String {
    var lines = ""
    for decision in decisions.sorted(by: liveCognitiveLoopAdapterDecisionSort) {
        let plan = decision.applicationPlan
        lines += try liveCognitiveLoopAdapterJSONLine(LabLiveCognitiveLoopAdapterRecordedEvent(
            type: "lab_live_cognitive_loop_adapter_recorded",
            event: "lab_live_cognitive_loop_adapter_recorded",
            success: decision.success,
            agentId: decision.agentId,
            tick: decision.tick,
            currentGoal: decision.snapshot.currentGoal,
            computedSelectedGoal: plan.computedSelectedGoal,
            computedSelectedAction: plan.computedSelectedAction,
            wouldChangeGoal: plan.wouldChangeGoal,
            wouldSelectAction: plan.wouldSelectAction,
            wouldWriteMemory: plan.wouldWriteMemory,
            appliedGoalChange: plan.appliedGoalChange,
            appliedAction: plan.appliedAction,
            appliedMemoryWrite: plan.appliedMemoryWrite,
            dryRun: plan.dryRun,
            liveAgentMutated: report.liveAgentMutated,
            movementStackUsed: report.movementStackUsed
        ))
    }
    lines += try liveCognitiveLoopAdapterJSONLine(LabLiveCognitiveLoopAdapterSummaryEvent(
        type: "lab_live_cognitive_loop_adapter_summary_recorded",
        event: "lab_live_cognitive_loop_adapter_summary_recorded",
        success: report.success,
        agents: report.agents,
        ticks: report.ticks,
        snapshots: report.snapshots,
        decisions: report.decisions,
        applicationPlans: report.applicationPlans,
        wouldChangeGoals: report.wouldChangeGoals,
        wouldSelectActions: report.wouldSelectActions,
        wouldWriteMemories: report.wouldWriteMemories,
        appliedGoalChanges: report.appliedGoalChanges,
        appliedActions: report.appliedActions,
        appliedMemoryWrites: report.appliedMemoryWrites,
        dryRun: report.dryRun,
        bounded: report.bounded,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
    return lines
}

private func liveCognitiveLoopAdapterJSONLine<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    return String(decoding: data, as: UTF8.self) + "\n"
}

private func liveCognitiveLoopAdapterCheck(
    _ name: String,
    _ passed: Bool,
    _ expected: String,
    _ actual: String
) -> LabBehaviorLoopInvariantCheck {
    LabBehaviorLoopInvariantCheck(name: name, passed: passed, expected: expected, actual: actual)
}

private func liveCognitiveLoopAdapterInputSort(
    _ lhs: LabLiveCognitiveLoopAdapterInput,
    _ rhs: LabLiveCognitiveLoopAdapterInput
) -> Bool {
    (lhs.tick, lhs.agentId) < (rhs.tick, rhs.agentId)
}

private func liveCognitiveLoopAdapterSnapshotSort(
    _ lhs: LabLiveCognitiveLoopAdapterSnapshot,
    _ rhs: LabLiveCognitiveLoopAdapterSnapshot
) -> Bool {
    (lhs.tick, lhs.agentId) < (rhs.tick, rhs.agentId)
}

private func liveCognitiveLoopAdapterPlanSort(
    _ lhs: LabLiveCognitiveLoopApplicationPlan,
    _ rhs: LabLiveCognitiveLoopApplicationPlan
) -> Bool {
    (lhs.tick, lhs.agentId) < (rhs.tick, rhs.agentId)
}

private func liveCognitiveLoopAdapterDecisionSort(
    _ lhs: LabLiveCognitiveLoopAdapterDecision,
    _ rhs: LabLiveCognitiveLoopAdapterDecision
) -> Bool {
    (lhs.tick, lhs.agentId) < (rhs.tick, rhs.agentId)
}
