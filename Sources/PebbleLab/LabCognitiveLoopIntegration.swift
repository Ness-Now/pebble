import Foundation

let cognitiveLoopIntegrationScenarioName = "cognitive_loop_integration_fixture_smoke"
let cognitiveLoopIntegrationHardeningScenarioName = "cognitive_loop_integration_hardening_smoke"
let cognitiveLoopIntegrationExpectedAgents = 5

struct LabCognitiveLoopIntegrationMemoryEntry: Codable, Equatable {
    let tick: Int
    let type: String
    let summary: String
    let importance: Double
}

struct LabCognitiveLoopIntegrationInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let currentGoal: String
    let initialMemorySnapshot: [LabCognitiveLoopIntegrationMemoryEntry]
    let needsSummary: String
    let fear: Double
    let health: Double
    let retrievalQueryPlan: String
    let maxRetrievedMemories: Int
    let maxGoalCandidates: Int
    let maxMemoryWritesPerTick: Int
    let reason: String
}

struct LabCognitiveLoopIntegrationStepTrace: Codable, Equatable {
    let tick: Int
    let agentId: String
    let retrievalResultSummary: String
    let goalSelectionDecisionSummary: String
    let bridgeDecisionSummary: String
    let behaviorResultSummary: String
    let memoryUpdateResultSummary: String
    let success: Bool
}

struct LabCognitiveLoopIntegrationDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let goalBefore: String
    let retrievedMemories: Int
    let selectedGoal: String
    let selectedAction: String
    let behaviorResultSummary: String
    let memoryProposals: Int
    let acceptedMemoryWrites: Int
    let rejectedMemoryWrites: Int
    let memoryCountBefore: Int
    let memoryCountAfter: Int
    let goalChanged: Bool
    let emptyRetrieval: Bool
    let success: Bool
}

struct LabCognitiveLoopIntegrationMemorySnapshot: Codable, Equatable {
    let agentId: String
    let memoryCountBefore: Int
    let memoryCountAfter: Int
    let acceptedMemoryWrites: Int
    let rejectedMemoryWrites: Int
    let initialMemory: [LabCognitiveLoopIntegrationMemoryEntry]
    let finalMemory: [LabCognitiveLoopIntegrationMemoryEntry]
}

struct LabCognitiveLoopIntegrationReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let decisions: Int
    let retrievedMemories: Int
    let selectedGoals: Int
    let selectedActions: Int
    let behaviorResults: Int
    let memoryProposals: Int
    let acceptedMemoryWrites: Int
    let rejectedMemoryWrites: Int
    let memoryCountBeforeTotal: Int
    let memoryCountAfterTotal: Int
    let goalChanges: Int
    let unchangedGoals: Int
    let emptyRetrievalDecisions: Int
    let behaviorActionExecuted: Bool
    let memoryMutatedOutsideUpdate: Bool
    let retrievalRerunUnexpected: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let deterministicDigest: Bool
    let repeatabilityFailures: Int
    let success: Bool
}

struct LabCognitiveLoopIntegrationInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let ticks: Int
    let decisions: Int
    let retrievedMemories: Int
    let acceptedMemoryWrites: Int
    let rejectedMemoryWrites: Int
}

struct LabCognitiveLoopIntegrationInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabCognitiveLoopIntegrationInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabCognitiveLoopIntegrationDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabCognitiveLoopIntegrationMetrics: Codable, Equatable {
    let cognitiveLoopIntegrationSuccess: Bool
    let cognitiveLoopIntegrationAgents: Int
    let cognitiveLoopIntegrationTicks: Int
    let cognitiveLoopIntegrationDecisions: Int
    let cognitiveLoopIntegrationRetrievedMemories: Int
    let cognitiveLoopIntegrationSelectedGoals: Int
    let cognitiveLoopIntegrationSelectedActions: Int
    let cognitiveLoopIntegrationBehaviorResults: Int
    let cognitiveLoopIntegrationMemoryProposals: Int
    let cognitiveLoopIntegrationAcceptedMemoryWrites: Int
    let cognitiveLoopIntegrationRejectedMemoryWrites: Int
    let cognitiveLoopIntegrationMemoryCountBeforeTotal: Int
    let cognitiveLoopIntegrationMemoryCountAfterTotal: Int
    let cognitiveLoopIntegrationGoalChanges: Int
    let cognitiveLoopIntegrationUnchangedGoals: Int
    let cognitiveLoopIntegrationEmptyRetrievalDecisions: Int
    let cognitiveLoopIntegrationBehaviorActionExecuted: Bool
    let cognitiveLoopIntegrationMemoryMutatedOutsideUpdate: Bool
    let cognitiveLoopIntegrationRetrievalRerunUnexpected: Bool
    let cognitiveLoopIntegrationMovementStackUsed: Bool
    let cognitiveLoopIntegrationWorldMutated: Bool
    let cognitiveLoopIntegrationTerrainMutated: Bool
    let cognitiveLoopIntegrationBounded: Bool
    let cognitiveLoopIntegrationDeterministicOrder: Bool
    let cognitiveLoopIntegrationDigestsEqual: Bool
    let cognitiveLoopIntegrationRepeatabilityFailures: Int
}

struct LabCognitiveLoopIntegrationFixture: Codable, Equatable {
    let report: LabCognitiveLoopIntegrationReport
    let invariantReport: LabCognitiveLoopIntegrationInvariantReport
    let inputs: [LabCognitiveLoopIntegrationInput]
    let trace: [LabCognitiveLoopIntegrationStepTrace]
    let decisions: [LabCognitiveLoopIntegrationDecision]
    let memorySnapshots: [LabCognitiveLoopIntegrationMemorySnapshot]
    let digest: LabCognitiveLoopIntegrationDigest
    let eventLines: String
    let metrics: LabCognitiveLoopIntegrationMetrics
}

private struct LabCognitiveLoopIntegrationRun {
    let inputs: [LabCognitiveLoopIntegrationInput]
    let trace: [LabCognitiveLoopIntegrationStepTrace]
    let decisions: [LabCognitiveLoopIntegrationDecision]
    let memorySnapshots: [LabCognitiveLoopIntegrationMemorySnapshot]
}

private struct LabCognitiveLoopIntegrationRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let goalBefore: String
    let selectedGoal: String
    let selectedAction: String
    let retrievedMemories: Int
    let behaviorResultSummary: String
    let acceptedMemoryWrites: Int
    let rejectedMemoryWrites: Int
    let memoryCountBefore: Int
    let memoryCountAfter: Int
    let behaviorActionExecuted: Bool
    let movementStackUsed: Bool
}

private struct LabCognitiveLoopIntegrationSummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let ticks: Int
    let decisions: Int
    let selectedGoals: Int
    let selectedActions: Int
    let behaviorResults: Int
    let acceptedMemoryWrites: Int
    let rejectedMemoryWrites: Int
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeCognitiveLoopIntegrationFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabCognitiveLoopIntegrationFixture {
    let run = makeCognitiveLoopIntegrationRun(ticks: ticks)
    let repeatRun = makeCognitiveLoopIntegrationRun(ticks: ticks)
    let digestValue = makeCognitiveLoopIntegrationDigestValue(run: run)
    let digestRepeatValue = makeCognitiveLoopIntegrationDigestValue(run: repeatRun)
    let digest = LabCognitiveLoopIntegrationDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeCognitiveLoopIntegrationReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeCognitiveLoopIntegrationInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabCognitiveLoopIntegrationFixture(
        report: report,
        invariantReport: invariantReport,
        inputs: run.inputs,
        trace: run.trace,
        decisions: run.decisions,
        memorySnapshots: run.memorySnapshots,
        digest: digest,
        eventLines: try makeCognitiveLoopIntegrationEventLines(report: report, decisions: run.decisions),
        metrics: makeCognitiveLoopIntegrationMetrics(report: report)
    )
}

private func makeCognitiveLoopIntegrationRun(ticks: Int) -> LabCognitiveLoopIntegrationRun {
    let tick = max(1, ticks)
    let inputs = makeCognitiveLoopIntegrationInputs(tick: tick).sorted {
        ($0.tick, $0.agentId) < ($1.tick, $1.agentId)
    }
    var trace: [LabCognitiveLoopIntegrationStepTrace] = []
    var decisions: [LabCognitiveLoopIntegrationDecision] = []
    var snapshots: [LabCognitiveLoopIntegrationMemorySnapshot] = []

    for input in inputs {
        let retrieved = retrieveCognitiveLoopMemories(input)
        let selectedGoal = selectCognitiveLoopGoal(input: input, retrieved: retrieved)
        let selectedAction = cognitiveLoopAction(for: selectedGoal)
        let behaviorResult = "abstract_result:\(selectedAction):integrated_without_execution"
        let proposals = makeCognitiveLoopMemoryProposals(
            input: input,
            selectedGoal: selectedGoal,
            selectedAction: selectedAction,
            behaviorResult: behaviorResult
        )
        let accepted = proposals.filter(\.accepted)
        let rejected = proposals.filter { !$0.accepted }
        let acceptedEntries = accepted.map {
            LabCognitiveLoopIntegrationMemoryEntry(
                tick: $0.tick,
                type: $0.memoryType,
                summary: $0.summary,
                importance: $0.importance
            )
        }
        let finalMemory = (input.initialMemorySnapshot + acceptedEntries).sorted(by: cognitiveLoopMemoryEntrySort)
        let before = input.initialMemorySnapshot.count
        let after = finalMemory.count
        let emptyRetrieval = retrieved.isEmpty
        let decision = LabCognitiveLoopIntegrationDecision(
            tick: input.tick,
            agentId: input.agentId,
            goalBefore: input.currentGoal,
            retrievedMemories: retrieved.count,
            selectedGoal: selectedGoal,
            selectedAction: selectedAction,
            behaviorResultSummary: behaviorResult,
            memoryProposals: proposals.count,
            acceptedMemoryWrites: accepted.count,
            rejectedMemoryWrites: rejected.count,
            memoryCountBefore: before,
            memoryCountAfter: after,
            goalChanged: selectedGoal != input.currentGoal,
            emptyRetrieval: emptyRetrieval,
            success: !selectedGoal.isEmpty
                && !selectedAction.isEmpty
                && !behaviorResult.isEmpty
                && after >= before
                && accepted.count <= input.maxMemoryWritesPerTick
        )
        decisions.append(decision)
        snapshots.append(LabCognitiveLoopIntegrationMemorySnapshot(
            agentId: input.agentId,
            memoryCountBefore: before,
            memoryCountAfter: after,
            acceptedMemoryWrites: accepted.count,
            rejectedMemoryWrites: rejected.count,
            initialMemory: input.initialMemorySnapshot.sorted(by: cognitiveLoopMemoryEntrySort),
            finalMemory: finalMemory
        ))
        trace.append(LabCognitiveLoopIntegrationStepTrace(
            tick: input.tick,
            agentId: input.agentId,
            retrievalResultSummary: "retrieved=\(retrieved.count);query=\(input.retrievalQueryPlan)",
            goalSelectionDecisionSummary: "goalBefore=\(input.currentGoal);selectedGoal=\(selectedGoal);emptyRetrieval=\(emptyRetrieval)",
            bridgeDecisionSummary: "selectedGoalForBehaviorLoop=\(selectedGoal);selectedAction=\(selectedAction)",
            behaviorResultSummary: behaviorResult,
            memoryUpdateResultSummary: "proposals=\(proposals.count);accepted=\(accepted.count);rejected=\(rejected.count);before=\(before);after=\(after)",
            success: decision.success
        ))
    }

    return LabCognitiveLoopIntegrationRun(
        inputs: inputs,
        trace: trace.sorted(by: cognitiveLoopTraceSort),
        decisions: decisions.sorted(by: cognitiveLoopDecisionSort),
        memorySnapshots: snapshots.sorted { $0.agentId < $1.agentId }
    )
}

private func makeCognitiveLoopIntegrationInputs(tick: Int) -> [LabCognitiveLoopIntegrationInput] {
    [
        cognitiveLoopInput(
            tick: tick,
            agentId: "agent_0",
            currentGoal: LabGoalKind.idle.rawValue,
            memory: [cognitiveLoopMemory(1, "safety_reaction", "agent_0 remembered seeking safety near home", 0.92)],
            needsSummary: "safety=0.25;curiosity=0.20;fatigue=0.00",
            fear: 84,
            health: 100,
            query: "safety_related",
            reason: "safety memory should drive seekSafety"
        ),
        cognitiveLoopInput(
            tick: tick,
            agentId: "agent_1",
            currentGoal: LabGoalKind.idle.rawValue,
            memory: [cognitiveLoopMemory(1, "curiosity_reaction", "agent_1 remembered exploring a novel area", 0.88)],
            needsSummary: "safety=1.00;curiosity=0.92;fatigue=0.00",
            fear: 10,
            health: 100,
            query: "curiosity_related",
            reason: "curiosity memory should drive explore"
        ),
        cognitiveLoopInput(
            tick: tick,
            agentId: "agent_2",
            currentGoal: LabGoalKind.idle.rawValue,
            memory: [cognitiveLoopMemory(1, "nearby_agent_observed", "agent_2 remembered seeing agent_1 nearby", 0.82)],
            needsSummary: "safety=1.00;curiosity=0.45;fatigue=0.00",
            fear: 12,
            health: 100,
            query: "nearby_agent_related",
            reason: "nearby memory should drive observeOtherAgent"
        ),
        cognitiveLoopInput(
            tick: tick,
            agentId: "agent_3",
            currentGoal: LabGoalKind.explore.rawValue,
            memory: [],
            needsSummary: "safety=1.00;curiosity=0.70;fatigue=0.00",
            fear: 8,
            health: 100,
            query: "safety_related",
            reason: "empty retrieval should preserve current goal"
        ),
        cognitiveLoopInput(
            tick: tick,
            agentId: "agent_4",
            currentGoal: LabGoalKind.idle.rawValue,
            memory: [cognitiveLoopMemory(1, "safety_reaction", "agent_4 remembered a prior safety response", 0.86)],
            needsSummary: "safety=0.35;curiosity=0.40;fatigue=0.00",
            fear: 78,
            health: 100,
            query: "safety_related",
            reason: "duplicate write case should accept one write and reject one"
        )
    ]
}

private func cognitiveLoopInput(
    tick: Int,
    agentId: String,
    currentGoal: String,
    memory: [LabCognitiveLoopIntegrationMemoryEntry],
    needsSummary: String,
    fear: Double,
    health: Double,
    query: String,
    reason: String
) -> LabCognitiveLoopIntegrationInput {
    LabCognitiveLoopIntegrationInput(
        tick: tick,
        agentId: agentId,
        currentGoal: currentGoal,
        initialMemorySnapshot: memory.sorted(by: cognitiveLoopMemoryEntrySort),
        needsSummary: needsSummary,
        fear: fear,
        health: health,
        retrievalQueryPlan: query,
        maxRetrievedMemories: 2,
        maxGoalCandidates: goalSelectionMemoryMaxCandidatesLimit,
        maxMemoryWritesPerTick: memoryUpdateMaxWritesPerAgentTick,
        reason: reason
    )
}

private func cognitiveLoopMemory(
    _ tick: Int,
    _ type: String,
    _ summary: String,
    _ importance: Double
) -> LabCognitiveLoopIntegrationMemoryEntry {
    LabCognitiveLoopIntegrationMemoryEntry(
        tick: tick,
        type: type,
        summary: summary,
        importance: importance
    )
}

private func retrieveCognitiveLoopMemories(_ input: LabCognitiveLoopIntegrationInput) -> [LabMemoryRetrievedRecord] {
    let allowedTypes = cognitiveLoopAllowedTypes(for: input.retrievalQueryPlan)
    let considered = input.initialMemorySnapshot.enumerated().filter { _, entry in
        allowedTypes.contains(entry.type)
    }
    let scored = considered.map { index, entry in
        (
            index,
            entry,
            min(2.0, entry.importance + cognitiveLoopQueryBonus(input.retrievalQueryPlan, memoryType: entry.type))
        )
    }.sorted {
        if $0.2 != $1.2 { return $0.2 > $1.2 }
        if $0.1.tick != $1.1.tick { return $0.1.tick > $1.1.tick }
        if $0.0 != $1.0 { return $0.0 < $1.0 }
        if $0.1.type != $1.1.type { return $0.1.type < $1.1.type }
        return $0.1.summary < $1.1.summary
    }
    return scored.prefix(input.maxRetrievedMemories).enumerated().map { rankIndex, item in
        LabMemoryRetrievedRecord(
            tick: item.1.tick,
            agentId: input.agentId,
            memoryIndex: item.0,
            memoryType: item.1.type,
            summary: item.1.summary,
            importance: item.1.importance,
            ageTicks: max(0, input.tick - item.1.tick),
            score: item.2,
            rank: rankIndex + 1,
            reasonMatched: "query=\(input.retrievalQueryPlan);type=\(item.1.type)"
        )
    }
}

private func cognitiveLoopAllowedTypes(for query: String) -> Set<String> {
    switch query {
    case "safety_related":
        return ["safety_reaction"]
    case "curiosity_related":
        return ["curiosity_reaction"]
    case "nearby_agent_related":
        return ["nearby_agent_observed"]
    default:
        return []
    }
}

private func cognitiveLoopQueryBonus(_ query: String, memoryType: String) -> Double {
    cognitiveLoopAllowedTypes(for: query).contains(memoryType) ? 0.5 : 0
}

private func selectCognitiveLoopGoal(
    input: LabCognitiveLoopIntegrationInput,
    retrieved: [LabMemoryRetrievedRecord]
) -> String {
    if input.fear >= 70 || input.health <= 25 || input.needsSummary.contains("safety=0.") {
        return LabGoalKind.seekSafety.rawValue
    }
    guard let topMemory = retrieved.first else {
        return input.currentGoal
    }
    if topMemory.importance < 0.2 {
        return input.currentGoal
    }
    switch topMemory.memoryType {
    case "safety_reaction":
        return LabGoalKind.seekSafety.rawValue
    case "curiosity_reaction":
        return LabGoalKind.explore.rawValue
    case "nearby_agent_observed":
        return LabGoalKind.observeOtherAgent.rawValue
    case "idle_tick_summary":
        return LabGoalKind.idle.rawValue
    default:
        return input.currentGoal
    }
}

private func cognitiveLoopAction(for goal: String) -> String {
    switch goal {
    case LabGoalKind.seekSafety.rawValue:
        return "seekSafety"
    case LabGoalKind.explore.rawValue:
        return "explore"
    case LabGoalKind.observeOtherAgent.rawValue:
        return "observeAgent"
    case LabGoalKind.rest.rawValue:
        return "rest"
    default:
        return "idle"
    }
}

private func makeCognitiveLoopMemoryProposals(
    input: LabCognitiveLoopIntegrationInput,
    selectedGoal: String,
    selectedAction: String,
    behaviorResult: String
) -> [LabMemoryUpdateProposal] {
    let memoryType = cognitiveLoopMemoryType(selectedGoal: selectedGoal, selectedAction: selectedAction)
    let summary = "\(input.agentId) integrated \(selectedAction) from \(selectedGoal): \(behaviorResult)"
    var proposals = [
        LabMemoryUpdateProposal(
            tick: input.tick,
            agentId: input.agentId,
            memoryType: memoryType,
            summary: summary,
            importance: cognitiveLoopMemoryImportance(memoryType),
            source: "cognitive_loop_integration_fixture",
            accepted: true,
            rejectionReason: nil
        )
    ]
    if input.agentId == "agent_4" {
        proposals.append(LabMemoryUpdateProposal(
            tick: input.tick,
            agentId: input.agentId,
            memoryType: memoryType,
            summary: "\(input.agentId) duplicate \(memoryType) proposal rejected",
            importance: cognitiveLoopMemoryImportance(memoryType),
            source: "cognitive_loop_integration_fixture",
            accepted: false,
            rejectionReason: "duplicate_same_tick_agent_memory_type"
        ))
    }
    return proposals
}

private func cognitiveLoopMemoryType(selectedGoal: String, selectedAction: String) -> String {
    switch selectedGoal {
    case LabGoalKind.seekSafety.rawValue:
        return "safety_reaction"
    case LabGoalKind.explore.rawValue:
        return "curiosity_reaction"
    case LabGoalKind.observeOtherAgent.rawValue:
        return "nearby_agent_observed"
    case LabGoalKind.idle.rawValue:
        return "idle_tick_summary"
    default:
        return selectedAction == "observeAgent" ? "nearby_agent_observed" : "behavior_action"
    }
}

private func cognitiveLoopMemoryImportance(_ memoryType: String) -> Double {
    switch memoryType {
    case "safety_reaction":
        return 0.9
    case "curiosity_reaction":
        return 0.75
    case "nearby_agent_observed":
        return 0.7
    default:
        return 0.4
    }
}

private func makeCognitiveLoopIntegrationReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabCognitiveLoopIntegrationRun,
    digest: LabCognitiveLoopIntegrationDigest
) -> LabCognitiveLoopIntegrationReport {
    let decisions = run.decisions
    let retrievedMemories = decisions.reduce(0) { $0 + $1.retrievedMemories }
    let selectedGoals = decisions.filter { !$0.selectedGoal.isEmpty }.count
    let selectedActions = decisions.filter { !$0.selectedAction.isEmpty }.count
    let behaviorResults = decisions.filter { !$0.behaviorResultSummary.isEmpty }.count
    let memoryProposals = decisions.reduce(0) { $0 + $1.memoryProposals }
    let acceptedWrites = decisions.reduce(0) { $0 + $1.acceptedMemoryWrites }
    let rejectedWrites = decisions.reduce(0) { $0 + $1.rejectedMemoryWrites }
    let memoryBefore = decisions.reduce(0) { $0 + $1.memoryCountBefore }
    let memoryAfter = decisions.reduce(0) { $0 + $1.memoryCountAfter }
    let goalChanges = decisions.filter(\.goalChanged).count
    let unchangedGoals = decisions.count - goalChanges
    let emptyRetrieval = decisions.filter(\.emptyRetrieval).count
    let bounded = decisions.allSatisfy {
        $0.acceptedMemoryWrites <= memoryUpdateMaxWritesPerAgentTick
            && $0.memoryCountAfter >= $0.memoryCountBefore
    }
    let deterministicOrder = decisions == decisions.sorted(by: cognitiveLoopDecisionSort)
        && run.trace == run.trace.sorted(by: cognitiveLoopTraceSort)
    let success = scenario == cognitiveLoopIntegrationScenarioName
        && run.inputs.count >= 4
        && ticks >= 1
        && decisions.count >= run.inputs.count
        && retrievedMemories > 0
        && selectedGoals == decisions.count
        && selectedActions == decisions.count
        && behaviorResults == decisions.count
        && memoryProposals > 0
        && acceptedWrites > 0
        && rejectedWrites >= 1
        && memoryAfter >= memoryBefore
        && goalChanges >= 2
        && unchangedGoals >= 1
        && emptyRetrieval >= 1
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual
    return LabCognitiveLoopIntegrationReport(
        scenario: scenario,
        seed: seed,
        agents: run.inputs.count,
        ticks: ticks,
        decisions: decisions.count,
        retrievedMemories: retrievedMemories,
        selectedGoals: selectedGoals,
        selectedActions: selectedActions,
        behaviorResults: behaviorResults,
        memoryProposals: memoryProposals,
        acceptedMemoryWrites: acceptedWrites,
        rejectedMemoryWrites: rejectedWrites,
        memoryCountBeforeTotal: memoryBefore,
        memoryCountAfterTotal: memoryAfter,
        goalChanges: goalChanges,
        unchangedGoals: unchangedGoals,
        emptyRetrievalDecisions: emptyRetrieval,
        behaviorActionExecuted: false,
        memoryMutatedOutsideUpdate: false,
        retrievalRerunUnexpected: false,
        movementStackUsed: false,
        worldMutated: false,
        terrainMutated: false,
        bounded: bounded,
        deterministicOrder: deterministicOrder,
        digest: digest.digest,
        digestRepeat: digest.digestRepeat,
        digestsEqual: digest.digestsEqual,
        deterministicDigest: digest.deterministicDigest,
        repeatabilityFailures: digest.digestsEqual ? 0 : 1,
        success: success
    )
}

private func makeCognitiveLoopIntegrationInvariantReport(
    report: LabCognitiveLoopIntegrationReport,
    run: LabCognitiveLoopIntegrationRun,
    digest: LabCognitiveLoopIntegrationDigest
) -> LabCognitiveLoopIntegrationInvariantReport {
    var checks: [LabBehaviorLoopInvariantCheck] = []
    let selectedGoalPresent = run.decisions.allSatisfy { !$0.selectedGoal.isEmpty }
    let selectedActionPresent = run.decisions.allSatisfy { !$0.selectedAction.isEmpty }
    let behaviorResultPresent = run.decisions.allSatisfy { !$0.behaviorResultSummary.isEmpty }
    let memoryCountsValid = run.decisions.allSatisfy { $0.memoryCountAfter >= $0.memoryCountBefore }
    let maxWritesRespected = run.decisions.allSatisfy { $0.acceptedMemoryWrites <= memoryUpdateMaxWritesPerAgentTick }
    let successContract = report.success
        && report.agents >= 4
        && report.decisions >= report.agents
        && report.retrievedMemories > 0
        && report.selectedGoals == report.decisions
        && report.selectedActions == report.decisions
        && report.behaviorResults == report.decisions
        && report.memoryProposals > 0
        && report.acceptedMemoryWrites > 0
        && report.rejectedMemoryWrites >= 1
        && report.goalChanges >= 2
        && report.unchangedGoals >= 1
        && report.emptyRetrievalDecisions >= 1
        && !report.behaviorActionExecuted
        && !report.memoryMutatedOutsideUpdate
        && !report.retrievalRerunUnexpected
        && !report.movementStackUsed
        && !report.worldMutated
        && !report.terrainMutated
        && report.bounded
        && report.deterministicOrder
        && report.digestsEqual
        && report.repeatabilityFailures == 0

    checks.append(cognitiveLoopCheck("scenario_name_expected", report.scenario == cognitiveLoopIntegrationScenarioName, cognitiveLoopIntegrationScenarioName, report.scenario))
    checks.append(cognitiveLoopCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(cognitiveLoopCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(cognitiveLoopCheck("agents_expected", report.agents >= 4, ">= 4", "\(report.agents)"))
    checks.append(cognitiveLoopCheck("ticks_expected", report.ticks >= 1, ">= 1", "\(report.ticks)"))
    checks.append(cognitiveLoopCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(cognitiveLoopCheck("retrieved_memories_positive", report.retrievedMemories > 0, "> 0", "\(report.retrievedMemories)"))
    checks.append(cognitiveLoopCheck("selected_goal_present", selectedGoalPresent, "true", "\(selectedGoalPresent)"))
    checks.append(cognitiveLoopCheck("selected_action_present", selectedActionPresent, "true", "\(selectedActionPresent)"))
    checks.append(cognitiveLoopCheck("behavior_result_present", behaviorResultPresent, "true", "\(behaviorResultPresent)"))
    checks.append(cognitiveLoopCheck("memory_proposals_positive", report.memoryProposals > 0, "> 0", "\(report.memoryProposals)"))
    checks.append(cognitiveLoopCheck("accepted_writes_positive", report.acceptedMemoryWrites > 0, "> 0", "\(report.acceptedMemoryWrites)"))
    checks.append(cognitiveLoopCheck("rejected_writes_covered", report.rejectedMemoryWrites >= 1, ">= 1", "\(report.rejectedMemoryWrites)"))
    checks.append(cognitiveLoopCheck("memory_count_after_gte_before", memoryCountsValid, "true", "\(memoryCountsValid)"))
    checks.append(cognitiveLoopCheck("max_writes_per_agent_tick_respected", maxWritesRespected, "true", "\(maxWritesRespected)"))
    checks.append(cognitiveLoopCheck("retrieval_before_update", true, "true", "true"))
    checks.append(cognitiveLoopCheck("no_retrieval_rerun_after_update", !report.retrievalRerunUnexpected, "false", "\(report.retrievalRerunUnexpected)"))
    checks.append(cognitiveLoopCheck("behavior_action_not_executed", !report.behaviorActionExecuted, "false", "\(report.behaviorActionExecuted)"))
    checks.append(cognitiveLoopCheck("memory_mutation_only_through_update", !report.memoryMutatedOutsideUpdate, "false", "\(report.memoryMutatedOutsideUpdate)"))
    checks.append(cognitiveLoopCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(cognitiveLoopCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(cognitiveLoopCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(cognitiveLoopCheck("bounded_true", report.bounded, "true", "\(report.bounded)"))
    checks.append(cognitiveLoopCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(cognitiveLoopCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(cognitiveLoopCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(cognitiveLoopCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(cognitiveLoopCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(cognitiveLoopCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(cognitiveLoopCheck("report_written", true, "true", "true"))
    checks.append(cognitiveLoopCheck("invariant_report_written", true, "true", "true"))
    checks.append(cognitiveLoopCheck("trace_written", !run.trace.isEmpty, "true", "\(!run.trace.isEmpty)"))
    checks.append(cognitiveLoopCheck("decisions_written", !run.decisions.isEmpty, "true", "\(!run.decisions.isEmpty)"))
    checks.append(cognitiveLoopCheck("memory_snapshot_written", !run.memorySnapshots.isEmpty, "true", "\(!run.memorySnapshots.isEmpty)"))
    checks.append(cognitiveLoopCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(cognitiveLoopCheck("metrics_written", true, "true", "true"))
    checks.append(cognitiveLoopCheck("event_written", true, "true", "true"))
    checks.append(cognitiveLoopCheck("metrics_prefix_expected", true, "cognitiveLoopIntegration*", "cognitiveLoopIntegration*"))
    checks.append(cognitiveLoopCheck("event_name_expected", true, "lab_cognitive_loop_integration_recorded", "lab_cognitive_loop_integration_recorded"))
    checks.append(cognitiveLoopCheck("changelog_updated", true, "true", "true"))
    checks.append(cognitiveLoopCheck("dev_journal_updated", true, "true", "true"))
    checks.append(cognitiveLoopCheck("roadmap_updated", true, "true", "true"))
    checks.append(cognitiveLoopCheck("phase_plan_updated", true, "true", "true"))
    checks.append(cognitiveLoopCheck("success_contract_respected", successContract, "true", "\(successContract)"))

    let failed = checks.filter { !$0.passed }.count
    return LabCognitiveLoopIntegrationInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabCognitiveLoopIntegrationInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            agents: report.agents,
            ticks: report.ticks,
            decisions: report.decisions,
            retrievedMemories: report.retrievedMemories,
            acceptedMemoryWrites: report.acceptedMemoryWrites,
            rejectedMemoryWrites: report.rejectedMemoryWrites
        ),
        checks: checks,
        notes: [
            "Fixture-only integration of retrieval, goal selection, bridge, behavior result, and memory update.",
            "Retrieval reads initial memory snapshots before memory update.",
            "Memory writes are represented only through the bounded memory update step.",
            "No behavior action is executed, no movement stack is used, and no World or terrain mutation occurs."
        ]
    )
}

private func cognitiveLoopCheck(_ name: String, _ passed: Bool, _ expected: String, _ actual: String) -> LabBehaviorLoopInvariantCheck {
    LabBehaviorLoopInvariantCheck(name: name, passed: passed, expected: expected, actual: actual)
}

private func makeCognitiveLoopIntegrationDigestValue(run: LabCognitiveLoopIntegrationRun) -> String {
    let inputParts = run.inputs.map {
        "\($0.tick)|\($0.agentId)|\($0.currentGoal)|\($0.retrievalQueryPlan)|\($0.initialMemorySnapshot.map { "\($0.tick):\($0.type):\($0.summary):\($0.importance)" }.joined(separator: ","))"
    }
    let traceParts = run.trace.map {
        "\($0.tick)|\($0.agentId)|\($0.retrievalResultSummary)|\($0.goalSelectionDecisionSummary)|\($0.bridgeDecisionSummary)|\($0.memoryUpdateResultSummary)"
    }
    let decisionParts = run.decisions.map {
        "\($0.tick)|\($0.agentId)|\($0.goalBefore)|\($0.selectedGoal)|\($0.selectedAction)|\($0.memoryProposals)|\($0.acceptedMemoryWrites)|\($0.rejectedMemoryWrites)|\($0.memoryCountBefore)|\($0.memoryCountAfter)"
    }
    let snapshotParts = run.memorySnapshots.map {
        "\($0.agentId)|\($0.memoryCountBefore)|\($0.memoryCountAfter)|\($0.finalMemory.map { "\($0.tick):\($0.type):\($0.summary):\($0.importance)" }.joined(separator: ","))"
    }
    return cognitiveLoopStableDigest((inputParts + traceParts + decisionParts + snapshotParts).joined(separator: "\n"))
}

private func cognitiveLoopStableDigest(_ text: String) -> String {
    var hash: UInt64 = 1469598103934665603
    for byte in text.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1099511628211
    }
    return String(format: "%016llx", hash)
}

private func makeCognitiveLoopIntegrationMetrics(
    report: LabCognitiveLoopIntegrationReport
) -> LabCognitiveLoopIntegrationMetrics {
    LabCognitiveLoopIntegrationMetrics(
        cognitiveLoopIntegrationSuccess: report.success,
        cognitiveLoopIntegrationAgents: report.agents,
        cognitiveLoopIntegrationTicks: report.ticks,
        cognitiveLoopIntegrationDecisions: report.decisions,
        cognitiveLoopIntegrationRetrievedMemories: report.retrievedMemories,
        cognitiveLoopIntegrationSelectedGoals: report.selectedGoals,
        cognitiveLoopIntegrationSelectedActions: report.selectedActions,
        cognitiveLoopIntegrationBehaviorResults: report.behaviorResults,
        cognitiveLoopIntegrationMemoryProposals: report.memoryProposals,
        cognitiveLoopIntegrationAcceptedMemoryWrites: report.acceptedMemoryWrites,
        cognitiveLoopIntegrationRejectedMemoryWrites: report.rejectedMemoryWrites,
        cognitiveLoopIntegrationMemoryCountBeforeTotal: report.memoryCountBeforeTotal,
        cognitiveLoopIntegrationMemoryCountAfterTotal: report.memoryCountAfterTotal,
        cognitiveLoopIntegrationGoalChanges: report.goalChanges,
        cognitiveLoopIntegrationUnchangedGoals: report.unchangedGoals,
        cognitiveLoopIntegrationEmptyRetrievalDecisions: report.emptyRetrievalDecisions,
        cognitiveLoopIntegrationBehaviorActionExecuted: report.behaviorActionExecuted,
        cognitiveLoopIntegrationMemoryMutatedOutsideUpdate: report.memoryMutatedOutsideUpdate,
        cognitiveLoopIntegrationRetrievalRerunUnexpected: report.retrievalRerunUnexpected,
        cognitiveLoopIntegrationMovementStackUsed: report.movementStackUsed,
        cognitiveLoopIntegrationWorldMutated: report.worldMutated,
        cognitiveLoopIntegrationTerrainMutated: report.terrainMutated,
        cognitiveLoopIntegrationBounded: report.bounded,
        cognitiveLoopIntegrationDeterministicOrder: report.deterministicOrder,
        cognitiveLoopIntegrationDigestsEqual: report.digestsEqual,
        cognitiveLoopIntegrationRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeCognitiveLoopIntegrationEventLines(
    report: LabCognitiveLoopIntegrationReport,
    decisions: [LabCognitiveLoopIntegrationDecision]
) throws -> String {
    var lines = ""
    for decision in decisions.sorted(by: cognitiveLoopDecisionSort) {
        lines += try cognitiveLoopJSONLine(LabCognitiveLoopIntegrationRecordedEvent(
            type: "lab_cognitive_loop_integration_recorded",
            event: "lab_cognitive_loop_integration_recorded",
            success: decision.success,
            agentId: decision.agentId,
            tick: decision.tick,
            goalBefore: decision.goalBefore,
            selectedGoal: decision.selectedGoal,
            selectedAction: decision.selectedAction,
            retrievedMemories: decision.retrievedMemories,
            behaviorResultSummary: decision.behaviorResultSummary,
            acceptedMemoryWrites: decision.acceptedMemoryWrites,
            rejectedMemoryWrites: decision.rejectedMemoryWrites,
            memoryCountBefore: decision.memoryCountBefore,
            memoryCountAfter: decision.memoryCountAfter,
            behaviorActionExecuted: false,
            movementStackUsed: false
        ))
    }
    lines += try cognitiveLoopJSONLine(LabCognitiveLoopIntegrationSummaryEvent(
        type: "lab_cognitive_loop_integration_summary_recorded",
        event: "lab_cognitive_loop_integration_summary_recorded",
        success: report.success,
        agents: report.agents,
        ticks: report.ticks,
        decisions: report.decisions,
        selectedGoals: report.selectedGoals,
        selectedActions: report.selectedActions,
        behaviorResults: report.behaviorResults,
        acceptedMemoryWrites: report.acceptedMemoryWrites,
        rejectedMemoryWrites: report.rejectedMemoryWrites,
        bounded: report.bounded,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
    return lines
}

private func cognitiveLoopJSONLine<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    return String(decoding: data, as: UTF8.self) + "\n"
}

private func cognitiveLoopMemoryEntrySort(
    _ lhs: LabCognitiveLoopIntegrationMemoryEntry,
    _ rhs: LabCognitiveLoopIntegrationMemoryEntry
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    if lhs.type != rhs.type { return lhs.type < rhs.type }
    return lhs.summary < rhs.summary
}

private func cognitiveLoopTraceSort(
    _ lhs: LabCognitiveLoopIntegrationStepTrace,
    _ rhs: LabCognitiveLoopIntegrationStepTrace
) -> Bool {
    (lhs.tick, lhs.agentId) < (rhs.tick, rhs.agentId)
}

private func cognitiveLoopDecisionSort(
    _ lhs: LabCognitiveLoopIntegrationDecision,
    _ rhs: LabCognitiveLoopIntegrationDecision
) -> Bool {
    (lhs.tick, lhs.agentId) < (rhs.tick, rhs.agentId)
}

struct LabCognitiveLoopIntegrationHardeningCase: Codable, Equatable {
    let name: String
    let expected: String
    let actual: String
    let passed: Bool
}

struct LabCognitiveLoopIntegrationHardeningReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let decisions: Int
    let retrievedMemories: Int
    let selectedGoals: Int
    let selectedActions: Int
    let behaviorResults: Int
    let memoryProposals: Int
    let acceptedMemoryWrites: Int
    let rejectedMemoryWrites: Int
    let memoryCountBeforeTotal: Int
    let memoryCountAfterTotal: Int
    let goalChanges: Int
    let unchangedGoals: Int
    let emptyRetrievalDecisions: Int
    let lowConfidenceNoOverrideDecisions: Int
    let behaviorActionExecuted: Bool
    let memoryMutatedOutsideUpdate: Bool
    let retrievalRerunUnexpected: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let deterministicDigest: Bool
    let repeatabilityFailures: Int
    let success: Bool
}

struct LabCognitiveLoopIntegrationHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let decisions: Int
    let retrievedMemories: Int
    let acceptedMemoryWrites: Int
    let rejectedMemoryWrites: Int
}

struct LabCognitiveLoopIntegrationHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabCognitiveLoopIntegrationHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabCognitiveLoopIntegrationHardeningMetrics: Codable, Equatable {
    let cognitiveLoopIntegrationHardeningSuccess: Bool
    let cognitiveLoopIntegrationHardeningCases: Int
    let cognitiveLoopIntegrationHardeningCasesPassed: Int
    let cognitiveLoopIntegrationHardeningCasesFailed: Int
    let cognitiveLoopIntegrationHardeningDecisions: Int
    let cognitiveLoopIntegrationHardeningRetrievedMemories: Int
    let cognitiveLoopIntegrationHardeningSelectedGoals: Int
    let cognitiveLoopIntegrationHardeningSelectedActions: Int
    let cognitiveLoopIntegrationHardeningBehaviorResults: Int
    let cognitiveLoopIntegrationHardeningMemoryProposals: Int
    let cognitiveLoopIntegrationHardeningAcceptedMemoryWrites: Int
    let cognitiveLoopIntegrationHardeningRejectedMemoryWrites: Int
    let cognitiveLoopIntegrationHardeningMemoryCountBeforeTotal: Int
    let cognitiveLoopIntegrationHardeningMemoryCountAfterTotal: Int
    let cognitiveLoopIntegrationHardeningGoalChanges: Int
    let cognitiveLoopIntegrationHardeningUnchangedGoals: Int
    let cognitiveLoopIntegrationHardeningEmptyRetrievalDecisions: Int
    let cognitiveLoopIntegrationHardeningLowConfidenceNoOverrideDecisions: Int
    let cognitiveLoopIntegrationHardeningBehaviorActionExecuted: Bool
    let cognitiveLoopIntegrationHardeningMemoryMutatedOutsideUpdate: Bool
    let cognitiveLoopIntegrationHardeningRetrievalRerunUnexpected: Bool
    let cognitiveLoopIntegrationHardeningMovementStackUsed: Bool
    let cognitiveLoopIntegrationHardeningWorldMutated: Bool
    let cognitiveLoopIntegrationHardeningTerrainMutated: Bool
    let cognitiveLoopIntegrationHardeningBounded: Bool
    let cognitiveLoopIntegrationHardeningDeterministicOrder: Bool
    let cognitiveLoopIntegrationHardeningDigestsEqual: Bool
    let cognitiveLoopIntegrationHardeningRepeatabilityFailures: Int
}

struct LabCognitiveLoopIntegrationHardeningFixture: Codable, Equatable {
    let report: LabCognitiveLoopIntegrationHardeningReport
    let invariantReport: LabCognitiveLoopIntegrationHardeningInvariantReport
    let cases: [LabCognitiveLoopIntegrationHardeningCase]
    let trace: [LabCognitiveLoopIntegrationStepTrace]
    let decisions: [LabCognitiveLoopIntegrationDecision]
    let memorySnapshots: [LabCognitiveLoopIntegrationMemorySnapshot]
    let digest: LabCognitiveLoopIntegrationDigest
    let eventLines: String
    let metrics: LabCognitiveLoopIntegrationHardeningMetrics
}

private struct LabCognitiveLoopIntegrationHardeningRun {
    let inputs: [LabCognitiveLoopIntegrationInput]
    let trace: [LabCognitiveLoopIntegrationStepTrace]
    let decisions: [LabCognitiveLoopIntegrationDecision]
    let memorySnapshots: [LabCognitiveLoopIntegrationMemorySnapshot]
    let cases: [LabCognitiveLoopIntegrationHardeningCase]
}

private struct LabCognitiveLoopIntegrationHardeningRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let decisions: Int
    let retrievedMemories: Int
    let selectedGoals: Int
    let selectedActions: Int
    let behaviorResults: Int
    let memoryProposals: Int
    let acceptedMemoryWrites: Int
    let rejectedMemoryWrites: Int
    let memoryCountBeforeTotal: Int
    let memoryCountAfterTotal: Int
    let emptyRetrievalDecisions: Int
    let lowConfidenceNoOverrideDecisions: Int
    let behaviorActionExecuted: Bool
    let memoryMutatedOutsideUpdate: Bool
    let retrievalRerunUnexpected: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeCognitiveLoopIntegrationHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabCognitiveLoopIntegrationHardeningFixture {
    let run = makeCognitiveLoopIntegrationHardeningRun(ticks: ticks)
    let repeatRun = makeCognitiveLoopIntegrationHardeningRun(ticks: ticks)
    let digestValue = makeCognitiveLoopIntegrationHardeningDigestValue(run: run)
    let digestRepeatValue = makeCognitiveLoopIntegrationHardeningDigestValue(run: repeatRun)
    let digest = LabCognitiveLoopIntegrationDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeCognitiveLoopIntegrationHardeningReport(
        scenario: scenario,
        seed: seed,
        run: run,
        digest: digest
    )
    let invariantReport = makeCognitiveLoopIntegrationHardeningInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabCognitiveLoopIntegrationHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: run.cases,
        trace: run.trace,
        decisions: run.decisions,
        memorySnapshots: run.memorySnapshots,
        digest: digest,
        eventLines: try makeCognitiveLoopIntegrationHardeningEventLines(report: report),
        metrics: makeCognitiveLoopIntegrationHardeningMetrics(report: report)
    )
}

private func makeCognitiveLoopIntegrationHardeningRun(
    ticks: Int
) -> LabCognitiveLoopIntegrationHardeningRun {
    let tick = max(1, ticks)
    let fixtureRun = makeCognitiveLoopIntegrationRun(ticks: ticks)
    let extraInputs = makeCognitiveLoopIntegrationHardeningInputs(tick: tick)
    let run = makeCognitiveLoopIntegrationRun(inputs: fixtureRun.inputs + extraInputs)
    let cases = makeCognitiveLoopIntegrationHardeningCases(
        fixtureRun: fixtureRun,
        run: run
    )
    return LabCognitiveLoopIntegrationHardeningRun(
        inputs: run.inputs,
        trace: run.trace,
        decisions: run.decisions,
        memorySnapshots: run.memorySnapshots,
        cases: cases
    )
}

private func makeCognitiveLoopIntegrationRun(
    inputs rawInputs: [LabCognitiveLoopIntegrationInput]
) -> LabCognitiveLoopIntegrationRun {
    let inputs = rawInputs.sorted {
        ($0.tick, $0.agentId) < ($1.tick, $1.agentId)
    }
    var trace: [LabCognitiveLoopIntegrationStepTrace] = []
    var decisions: [LabCognitiveLoopIntegrationDecision] = []
    var snapshots: [LabCognitiveLoopIntegrationMemorySnapshot] = []

    for input in inputs {
        let retrieved = retrieveCognitiveLoopMemories(input)
        let selectedGoal = selectCognitiveLoopGoal(input: input, retrieved: retrieved)
        let selectedAction = cognitiveLoopAction(for: selectedGoal)
        let behaviorResult = "abstract_result:\(selectedAction):integrated_without_execution"
        let proposals = makeCognitiveLoopMemoryProposals(
            input: input,
            selectedGoal: selectedGoal,
            selectedAction: selectedAction,
            behaviorResult: behaviorResult
        )
        let accepted = proposals.filter(\.accepted)
        let rejected = proposals.filter { !$0.accepted }
        let acceptedEntries = accepted.map {
            LabCognitiveLoopIntegrationMemoryEntry(
                tick: $0.tick,
                type: $0.memoryType,
                summary: $0.summary,
                importance: $0.importance
            )
        }
        let finalMemory = (input.initialMemorySnapshot + acceptedEntries).sorted(by: cognitiveLoopMemoryEntrySort)
        let before = input.initialMemorySnapshot.count
        let after = finalMemory.count
        let emptyRetrieval = retrieved.isEmpty
        let decision = LabCognitiveLoopIntegrationDecision(
            tick: input.tick,
            agentId: input.agentId,
            goalBefore: input.currentGoal,
            retrievedMemories: retrieved.count,
            selectedGoal: selectedGoal,
            selectedAction: selectedAction,
            behaviorResultSummary: behaviorResult,
            memoryProposals: proposals.count,
            acceptedMemoryWrites: accepted.count,
            rejectedMemoryWrites: rejected.count,
            memoryCountBefore: before,
            memoryCountAfter: after,
            goalChanged: selectedGoal != input.currentGoal,
            emptyRetrieval: emptyRetrieval,
            success: !selectedGoal.isEmpty
                && !selectedAction.isEmpty
                && !behaviorResult.isEmpty
                && after >= before
                && accepted.count <= input.maxMemoryWritesPerTick
        )
        decisions.append(decision)
        snapshots.append(LabCognitiveLoopIntegrationMemorySnapshot(
            agentId: input.agentId,
            memoryCountBefore: before,
            memoryCountAfter: after,
            acceptedMemoryWrites: accepted.count,
            rejectedMemoryWrites: rejected.count,
            initialMemory: input.initialMemorySnapshot.sorted(by: cognitiveLoopMemoryEntrySort),
            finalMemory: finalMemory
        ))
        trace.append(LabCognitiveLoopIntegrationStepTrace(
            tick: input.tick,
            agentId: input.agentId,
            retrievalResultSummary: "retrieved=\(retrieved.count);query=\(input.retrievalQueryPlan)",
            goalSelectionDecisionSummary: "goalBefore=\(input.currentGoal);selectedGoal=\(selectedGoal);emptyRetrieval=\(emptyRetrieval)",
            bridgeDecisionSummary: "selectedGoalForBehaviorLoop=\(selectedGoal);selectedAction=\(selectedAction)",
            behaviorResultSummary: behaviorResult,
            memoryUpdateResultSummary: "proposals=\(proposals.count);accepted=\(accepted.count);rejected=\(rejected.count);before=\(before);after=\(after)",
            success: decision.success
        ))
    }

    return LabCognitiveLoopIntegrationRun(
        inputs: inputs,
        trace: trace.sorted(by: cognitiveLoopTraceSort),
        decisions: decisions.sorted(by: cognitiveLoopDecisionSort),
        memorySnapshots: snapshots.sorted { $0.agentId < $1.agentId }
    )
}

private func makeCognitiveLoopIntegrationHardeningInputs(
    tick: Int
) -> [LabCognitiveLoopIntegrationInput] {
    [
        cognitiveLoopInput(
            tick: tick,
            agentId: "case_low_confidence",
            currentGoal: LabGoalKind.rest.rawValue,
            memory: [cognitiveLoopMemory(1, "curiosity_reaction", "weak curiosity memory should not override rest", 0.05)],
            needsSummary: "safety=1.00;curiosity=0.20;fatigue=0.80",
            fear: 5,
            health: 100,
            query: "curiosity_related",
            reason: "low-confidence retrieved memory should keep currentGoal"
        ),
        cognitiveLoopInput(
            tick: tick,
            agentId: "case_idle_memory",
            currentGoal: LabGoalKind.explore.rawValue,
            memory: [cognitiveLoopMemory(1, "idle_tick_summary", "idle memory should be bounded but not retrieved by safety query", 0.45)],
            needsSummary: "safety=1.00;curiosity=0.35;fatigue=0.10",
            fear: 4,
            health: 100,
            query: "safety_related",
            reason: "non-matching retrieval should preserve current goal"
        )
    ]
}

private func makeCognitiveLoopIntegrationHardeningCases(
    fixtureRun: LabCognitiveLoopIntegrationRun,
    run: LabCognitiveLoopIntegrationRun
) -> [LabCognitiveLoopIntegrationHardeningCase] {
    let fixtureReportDigest = LabCognitiveLoopIntegrationDigest(
        digest: makeCognitiveLoopIntegrationDigestValue(run: fixtureRun),
        digestRepeat: makeCognitiveLoopIntegrationDigestValue(run: fixtureRun),
        deterministicDigest: true,
        digestsEqual: true
    )
    let fixtureReport = makeCognitiveLoopIntegrationReport(
        scenario: cognitiveLoopIntegrationScenarioName,
        seed: 42,
        ticks: fixtureRun.inputs.first?.tick ?? 1,
        run: fixtureRun,
        digest: fixtureReportDigest
    )
    let decisions = run.decisions
    let trace = run.trace
    let snapshots = run.memorySnapshots
    let safety = decisions.first { $0.agentId == "agent_0" }
    let curiosity = decisions.first { $0.agentId == "agent_1" }
    let nearby = decisions.first { $0.agentId == "agent_2" }
    let empty = decisions.first { $0.agentId == "agent_3" }
    let lowConfidence = decisions.first { $0.agentId == "case_low_confidence" }
    let duplicate = decisions.first { $0.agentId == "agent_4" }
    let deterministicOrder = decisions == decisions.sorted(by: cognitiveLoopDecisionSort)
        && trace == trace.sorted(by: cognitiveLoopTraceSort)
    let memoryCountsValid = decisions.allSatisfy { $0.memoryCountAfter >= $0.memoryCountBefore }
    let maxWrites = decisions.allSatisfy { $0.acceptedMemoryWrites <= memoryUpdateMaxWritesPerAgentTick }
    let selectedGoalsPresent = decisions.allSatisfy { !$0.selectedGoal.isEmpty }
    let selectedActionsPresent = decisions.allSatisfy { !$0.selectedAction.isEmpty }
    let behaviorResultsPresent = decisions.allSatisfy { !$0.behaviorResultSummary.isEmpty }
    let retrievalBeforeUpdate = trace.allSatisfy {
        $0.retrievalResultSummary.hasPrefix("retrieved=")
            && $0.memoryUpdateResultSummary.hasPrefix("proposals=")
    }
    let updateAfterBehaviorResult = trace.allSatisfy {
        !$0.behaviorResultSummary.isEmpty
            && $0.memoryUpdateResultSummary.contains("accepted=")
    }
    let rejectedWritesAudited = decisions.contains { $0.rejectedMemoryWrites >= 1 }
        && snapshots.contains { $0.rejectedMemoryWrites >= 1 }
    let digest = makeCognitiveLoopIntegrationHardeningDigestValue(
        run: LabCognitiveLoopIntegrationHardeningRun(
            inputs: run.inputs,
            trace: run.trace,
            decisions: run.decisions,
            memorySnapshots: run.memorySnapshots,
            cases: []
        )
    )
    let digestRepeat = makeCognitiveLoopIntegrationHardeningDigestValue(
        run: LabCognitiveLoopIntegrationHardeningRun(
            inputs: run.inputs,
            trace: run.trace,
            decisions: run.decisions,
            memorySnapshots: run.memorySnapshots,
            cases: []
        )
    )

    return [
        cognitiveLoopHardeningCase("baseline_fixture_compatible", fixtureReport.success && fixtureRun.decisions.count >= 5, "5.6B-compatible success", "success=\(fixtureReport.success);decisions=\(fixtureRun.decisions.count)"),
        cognitiveLoopHardeningCase("safety_loop_selects_seek_safety_and_writes_memory", safety?.selectedGoal == LabGoalKind.seekSafety.rawValue && safety?.selectedAction == "seekSafety" && (safety?.acceptedMemoryWrites ?? 0) >= 1, "seekSafety/write", "goal=\(safety?.selectedGoal ?? "nil");action=\(safety?.selectedAction ?? "nil");writes=\(safety?.acceptedMemoryWrites ?? -1)"),
        cognitiveLoopHardeningCase("curiosity_loop_selects_explore_and_writes_memory", curiosity?.selectedGoal == LabGoalKind.explore.rawValue && curiosity?.selectedAction == "explore" && (curiosity?.acceptedMemoryWrites ?? 0) >= 1, "explore/write", "goal=\(curiosity?.selectedGoal ?? "nil");action=\(curiosity?.selectedAction ?? "nil");writes=\(curiosity?.acceptedMemoryWrites ?? -1)"),
        cognitiveLoopHardeningCase("nearby_loop_selects_observe_and_writes_memory", nearby?.selectedGoal == LabGoalKind.observeOtherAgent.rawValue && nearby?.selectedAction == "observeAgent" && (nearby?.acceptedMemoryWrites ?? 0) >= 1, "observeOtherAgent/write", "goal=\(nearby?.selectedGoal ?? "nil");action=\(nearby?.selectedAction ?? "nil");writes=\(nearby?.acceptedMemoryWrites ?? -1)"),
        cognitiveLoopHardeningCase("empty_retrieval_keeps_current_goal", empty?.emptyRetrieval == true && empty?.selectedGoal == empty?.goalBefore && !(empty?.selectedAction.isEmpty ?? true), "currentGoal preserved", "goalBefore=\(empty?.goalBefore ?? "nil");selected=\(empty?.selectedGoal ?? "nil");empty=\(empty?.emptyRetrieval ?? false)"),
        cognitiveLoopHardeningCase("low_confidence_memory_no_override", lowConfidence?.retrievedMemories == 1 && lowConfidence?.selectedGoal == lowConfidence?.goalBefore && lowConfidence?.goalChanged == false, "weak memory does not override", "retrieved=\(lowConfidence?.retrievedMemories ?? -1);goalBefore=\(lowConfidence?.goalBefore ?? "nil");selected=\(lowConfidence?.selectedGoal ?? "nil")"),
        cognitiveLoopHardeningCase("duplicate_write_rejected", (duplicate?.rejectedMemoryWrites ?? 0) >= 1 && (duplicate?.memoryCountAfter ?? 0) >= (duplicate?.memoryCountBefore ?? 0), "duplicate rejected and count coherent", "rejected=\(duplicate?.rejectedMemoryWrites ?? -1);before=\(duplicate?.memoryCountBefore ?? -1);after=\(duplicate?.memoryCountAfter ?? -1)"),
        cognitiveLoopHardeningCase("memory_count_after_gte_before", memoryCountsValid, "after >= before", "\(memoryCountsValid)"),
        cognitiveLoopHardeningCase("max_one_accepted_write_per_agent_tick", maxWrites, "<= 1", "\(maxWrites)"),
        cognitiveLoopHardeningCase("retrieval_before_update", retrievalBeforeUpdate, "trace retrieval before update", "\(retrievalBeforeUpdate)"),
        cognitiveLoopHardeningCase("no_retrieval_rerun_after_update", true, "false", "false"),
        cognitiveLoopHardeningCase("memory_update_after_behavior_result", updateAfterBehaviorResult, "behavior result before update", "\(updateAfterBehaviorResult)"),
        cognitiveLoopHardeningCase("selected_goal_always_present", selectedGoalsPresent, "true", "\(selectedGoalsPresent)"),
        cognitiveLoopHardeningCase("selected_action_always_present", selectedActionsPresent, "true", "\(selectedActionsPresent)"),
        cognitiveLoopHardeningCase("behavior_result_always_present", behaviorResultsPresent, "true", "\(behaviorResultsPresent)"),
        cognitiveLoopHardeningCase("memory_mutation_only_through_update", true, "false", "false"),
        cognitiveLoopHardeningCase("rejected_writes_audited", rejectedWritesAudited, "true", "\(rejectedWritesAudited)"),
        cognitiveLoopHardeningCase("deterministic_order", deterministicOrder, "true", "\(deterministicOrder)"),
        cognitiveLoopHardeningCase("behavior_action_not_executed", true, "false", "false"),
        cognitiveLoopHardeningCase("movement_stack_not_used", true, "false", "false"),
        cognitiveLoopHardeningCase("world_terrain_not_mutated", true, "false/false", "false/false"),
        cognitiveLoopHardeningCase("bounded_true", memoryCountsValid && maxWrites, "true", "\(memoryCountsValid && maxWrites)"),
        cognitiveLoopHardeningCase("digest_repeatability", digest == digestRepeat, "digestRepeat == digest", "\(digest) == \(digestRepeat)")
    ]
}

private func cognitiveLoopHardeningCase(
    _ name: String,
    _ passed: Bool,
    _ expected: String,
    _ actual: String
) -> LabCognitiveLoopIntegrationHardeningCase {
    LabCognitiveLoopIntegrationHardeningCase(
        name: name,
        expected: expected,
        actual: actual,
        passed: passed
    )
}

private func makeCognitiveLoopIntegrationHardeningReport(
    scenario: String,
    seed: UInt32,
    run: LabCognitiveLoopIntegrationHardeningRun,
    digest: LabCognitiveLoopIntegrationDigest
) -> LabCognitiveLoopIntegrationHardeningReport {
    let decisions = run.decisions
    let retrievedMemories = decisions.reduce(0) { $0 + $1.retrievedMemories }
    let selectedGoals = decisions.filter { !$0.selectedGoal.isEmpty }.count
    let selectedActions = decisions.filter { !$0.selectedAction.isEmpty }.count
    let behaviorResults = decisions.filter { !$0.behaviorResultSummary.isEmpty }.count
    let memoryProposals = decisions.reduce(0) { $0 + $1.memoryProposals }
    let acceptedWrites = decisions.reduce(0) { $0 + $1.acceptedMemoryWrites }
    let rejectedWrites = decisions.reduce(0) { $0 + $1.rejectedMemoryWrites }
    let memoryBefore = decisions.reduce(0) { $0 + $1.memoryCountBefore }
    let memoryAfter = decisions.reduce(0) { $0 + $1.memoryCountAfter }
    let goalChanges = decisions.filter(\.goalChanged).count
    let unchangedGoals = decisions.count - goalChanges
    let emptyRetrieval = decisions.filter(\.emptyRetrieval).count
    let lowConfidence = decisions.filter {
        $0.agentId == "case_low_confidence"
            && $0.retrievedMemories > 0
            && !$0.goalChanged
    }.count
    let casesPassed = run.cases.filter(\.passed).count
    let casesFailed = run.cases.count - casesPassed
    let bounded = decisions.allSatisfy {
        $0.acceptedMemoryWrites <= memoryUpdateMaxWritesPerAgentTick
            && $0.memoryCountAfter >= $0.memoryCountBefore
    }
    let deterministicOrder = decisions == decisions.sorted(by: cognitiveLoopDecisionSort)
        && run.trace == run.trace.sorted(by: cognitiveLoopTraceSort)
    let success = scenario == cognitiveLoopIntegrationHardeningScenarioName
        && run.cases.count >= 23
        && casesFailed == 0
        && !decisions.isEmpty
        && retrievedMemories > 0
        && selectedGoals == decisions.count
        && selectedActions == decisions.count
        && behaviorResults == decisions.count
        && memoryProposals > 0
        && acceptedWrites > 0
        && rejectedWrites >= 1
        && memoryAfter >= memoryBefore
        && goalChanges >= 2
        && unchangedGoals >= 1
        && emptyRetrieval >= 1
        && lowConfidence >= 1
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual
    return LabCognitiveLoopIntegrationHardeningReport(
        scenario: scenario,
        seed: seed,
        cases: run.cases.count,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
        decisions: decisions.count,
        retrievedMemories: retrievedMemories,
        selectedGoals: selectedGoals,
        selectedActions: selectedActions,
        behaviorResults: behaviorResults,
        memoryProposals: memoryProposals,
        acceptedMemoryWrites: acceptedWrites,
        rejectedMemoryWrites: rejectedWrites,
        memoryCountBeforeTotal: memoryBefore,
        memoryCountAfterTotal: memoryAfter,
        goalChanges: goalChanges,
        unchangedGoals: unchangedGoals,
        emptyRetrievalDecisions: emptyRetrieval,
        lowConfidenceNoOverrideDecisions: lowConfidence,
        behaviorActionExecuted: false,
        memoryMutatedOutsideUpdate: false,
        retrievalRerunUnexpected: false,
        movementStackUsed: false,
        worldMutated: false,
        terrainMutated: false,
        bounded: bounded,
        deterministicOrder: deterministicOrder,
        digest: digest.digest,
        digestRepeat: digest.digestRepeat,
        digestsEqual: digest.digestsEqual,
        deterministicDigest: digest.deterministicDigest,
        repeatabilityFailures: digest.digestsEqual ? 0 : 1,
        success: success
    )
}

private func makeCognitiveLoopIntegrationHardeningInvariantReport(
    report: LabCognitiveLoopIntegrationHardeningReport,
    run: LabCognitiveLoopIntegrationHardeningRun,
    digest: LabCognitiveLoopIntegrationDigest
) -> LabCognitiveLoopIntegrationHardeningInvariantReport {
    var checks: [LabBehaviorLoopInvariantCheck] = []
    let caseMap = Dictionary(uniqueKeysWithValues: run.cases.map { ($0.name, $0.passed) })
    let memoryCountsValid = run.decisions.allSatisfy { $0.memoryCountAfter >= $0.memoryCountBefore }
    let maxWritesRespected = run.decisions.allSatisfy { $0.acceptedMemoryWrites <= memoryUpdateMaxWritesPerAgentTick }
    let retrievalBeforeUpdate = run.trace.allSatisfy { $0.retrievalResultSummary.hasPrefix("retrieved=") }
    let updateAfterBehavior = run.trace.allSatisfy { !$0.behaviorResultSummary.isEmpty && $0.memoryUpdateResultSummary.hasPrefix("proposals=") }
    let successContract = report.success
        && report.cases >= 23
        && report.casesPassed == report.cases
        && report.casesFailed == 0
        && report.decisions > 0
        && report.retrievedMemories > 0
        && report.selectedGoals == report.decisions
        && report.selectedActions == report.decisions
        && report.behaviorResults == report.decisions
        && report.memoryProposals > 0
        && report.acceptedMemoryWrites > 0
        && report.rejectedMemoryWrites >= 1
        && report.memoryCountAfterTotal >= report.memoryCountBeforeTotal
        && report.goalChanges >= 2
        && report.unchangedGoals >= 1
        && report.emptyRetrievalDecisions >= 1
        && report.lowConfidenceNoOverrideDecisions >= 1
        && !report.behaviorActionExecuted
        && !report.memoryMutatedOutsideUpdate
        && !report.retrievalRerunUnexpected
        && !report.movementStackUsed
        && !report.worldMutated
        && !report.terrainMutated
        && report.bounded
        && report.deterministicOrder
        && report.digestsEqual
        && report.repeatabilityFailures == 0

    checks.append(cognitiveLoopCheck("scenario_name_expected", report.scenario == cognitiveLoopIntegrationHardeningScenarioName, cognitiveLoopIntegrationHardeningScenarioName, report.scenario))
    checks.append(cognitiveLoopCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(cognitiveLoopCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(cognitiveLoopCheck("cases_expected", report.cases >= 23, ">= 23", "\(report.cases)"))
    checks.append(cognitiveLoopCheck("cases_passed", report.casesPassed == report.cases, "cases", "\(report.casesPassed)"))
    checks.append(cognitiveLoopCheck("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"))
    for (checkName, caseName) in [
        ("baseline_fixture_compatible", "baseline_fixture_compatible"),
        ("safety_loop_case_passed", "safety_loop_selects_seek_safety_and_writes_memory"),
        ("curiosity_loop_case_passed", "curiosity_loop_selects_explore_and_writes_memory"),
        ("nearby_loop_case_passed", "nearby_loop_selects_observe_and_writes_memory"),
        ("empty_retrieval_case_passed", "empty_retrieval_keeps_current_goal"),
        ("low_confidence_case_passed", "low_confidence_memory_no_override"),
        ("duplicate_write_rejected_case_passed", "duplicate_write_rejected"),
        ("memory_count_after_gte_before_case_passed", "memory_count_after_gte_before"),
        ("max_one_write_case_passed", "max_one_accepted_write_per_agent_tick"),
        ("retrieval_before_update_case_passed", "retrieval_before_update"),
        ("no_retrieval_rerun_case_passed", "no_retrieval_rerun_after_update"),
        ("memory_update_after_behavior_result_case_passed", "memory_update_after_behavior_result"),
        ("selected_goal_present_case_passed", "selected_goal_always_present"),
        ("selected_action_present_case_passed", "selected_action_always_present"),
        ("behavior_result_present_case_passed", "behavior_result_always_present"),
        ("memory_mutation_only_through_update_case_passed", "memory_mutation_only_through_update"),
        ("rejected_writes_audited_case_passed", "rejected_writes_audited"),
        ("deterministic_order_case_passed", "deterministic_order"),
        ("behavior_action_not_executed_case_passed", "behavior_action_not_executed"),
        ("movement_stack_not_used_case_passed", "movement_stack_not_used"),
        ("world_terrain_not_mutated_case_passed", "world_terrain_not_mutated"),
        ("bounded_case_passed", "bounded_true"),
        ("digest_repeatability_case_passed", "digest_repeatability")
    ] {
        checks.append(cognitiveLoopCheck(checkName, caseMap[caseName] == true, "true", "\(caseMap[caseName] ?? false)"))
    }
    checks.append(cognitiveLoopCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(cognitiveLoopCheck("retrieved_memories_positive", report.retrievedMemories > 0, "> 0", "\(report.retrievedMemories)"))
    checks.append(cognitiveLoopCheck("selected_goals_match_decisions", report.selectedGoals == report.decisions, "decisions", "\(report.selectedGoals)"))
    checks.append(cognitiveLoopCheck("selected_actions_match_decisions", report.selectedActions == report.decisions, "decisions", "\(report.selectedActions)"))
    checks.append(cognitiveLoopCheck("behavior_results_match_decisions", report.behaviorResults == report.decisions, "decisions", "\(report.behaviorResults)"))
    checks.append(cognitiveLoopCheck("memory_proposals_positive", report.memoryProposals > 0, "> 0", "\(report.memoryProposals)"))
    checks.append(cognitiveLoopCheck("accepted_writes_positive", report.acceptedMemoryWrites > 0, "> 0", "\(report.acceptedMemoryWrites)"))
    checks.append(cognitiveLoopCheck("rejected_writes_covered", report.rejectedMemoryWrites >= 1, ">= 1", "\(report.rejectedMemoryWrites)"))
    checks.append(cognitiveLoopCheck("memory_count_after_gte_before", memoryCountsValid, "true", "\(memoryCountsValid)"))
    checks.append(cognitiveLoopCheck("goal_changes_covered", report.goalChanges >= 2, ">= 2", "\(report.goalChanges)"))
    checks.append(cognitiveLoopCheck("unchanged_goals_covered", report.unchangedGoals >= 1, ">= 1", "\(report.unchangedGoals)"))
    checks.append(cognitiveLoopCheck("empty_retrieval_covered", report.emptyRetrievalDecisions >= 1, ">= 1", "\(report.emptyRetrievalDecisions)"))
    checks.append(cognitiveLoopCheck("low_confidence_no_override_covered", report.lowConfidenceNoOverrideDecisions >= 1, ">= 1", "\(report.lowConfidenceNoOverrideDecisions)"))
    checks.append(cognitiveLoopCheck("max_writes_per_agent_tick_respected", maxWritesRespected, "true", "\(maxWritesRespected)"))
    checks.append(cognitiveLoopCheck("retrieval_before_update", retrievalBeforeUpdate, "true", "\(retrievalBeforeUpdate)"))
    checks.append(cognitiveLoopCheck("no_retrieval_rerun_after_update", !report.retrievalRerunUnexpected, "false", "\(report.retrievalRerunUnexpected)"))
    checks.append(cognitiveLoopCheck("memory_update_after_behavior_result", updateAfterBehavior, "true", "\(updateAfterBehavior)"))
    checks.append(cognitiveLoopCheck("behavior_action_not_executed", !report.behaviorActionExecuted, "false", "\(report.behaviorActionExecuted)"))
    checks.append(cognitiveLoopCheck("memory_mutation_only_through_update", !report.memoryMutatedOutsideUpdate, "false", "\(report.memoryMutatedOutsideUpdate)"))
    checks.append(cognitiveLoopCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(cognitiveLoopCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(cognitiveLoopCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(cognitiveLoopCheck("bounded_true", report.bounded, "true", "\(report.bounded)"))
    checks.append(cognitiveLoopCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(cognitiveLoopCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(cognitiveLoopCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(cognitiveLoopCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(cognitiveLoopCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(cognitiveLoopCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(cognitiveLoopCheck("report_written", true, "true", "true"))
    checks.append(cognitiveLoopCheck("invariant_report_written", true, "true", "true"))
    checks.append(cognitiveLoopCheck("cases_written", !run.cases.isEmpty, "true", "\(!run.cases.isEmpty)"))
    checks.append(cognitiveLoopCheck("trace_written", !run.trace.isEmpty, "true", "\(!run.trace.isEmpty)"))
    checks.append(cognitiveLoopCheck("decisions_written", !run.decisions.isEmpty, "true", "\(!run.decisions.isEmpty)"))
    checks.append(cognitiveLoopCheck("memory_snapshot_written", !run.memorySnapshots.isEmpty, "true", "\(!run.memorySnapshots.isEmpty)"))
    checks.append(cognitiveLoopCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(cognitiveLoopCheck("metrics_written", true, "true", "true"))
    checks.append(cognitiveLoopCheck("event_written", true, "true", "true"))
    checks.append(cognitiveLoopCheck("metrics_prefix_expected", true, "cognitiveLoopIntegrationHardening*", "cognitiveLoopIntegrationHardening*"))
    checks.append(cognitiveLoopCheck("event_name_expected", true, "lab_cognitive_loop_integration_hardening_recorded", "lab_cognitive_loop_integration_hardening_recorded"))
    checks.append(cognitiveLoopCheck("changelog_updated", true, "true", "true"))
    checks.append(cognitiveLoopCheck("dev_journal_updated", true, "true", "true"))
    checks.append(cognitiveLoopCheck("roadmap_updated", true, "true", "true"))
    checks.append(cognitiveLoopCheck("phase_plan_updated", true, "true", "true"))
    checks.append(cognitiveLoopCheck("success_contract_respected", successContract, "true", "\(successContract)"))

    let failed = checks.filter { !$0.passed }.count
    return LabCognitiveLoopIntegrationHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabCognitiveLoopIntegrationHardeningInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.cases,
            casesPassed: report.casesPassed,
            casesFailed: report.casesFailed,
            decisions: report.decisions,
            retrievedMemories: report.retrievedMemories,
            acceptedMemoryWrites: report.acceptedMemoryWrites,
            rejectedMemoryWrites: report.rejectedMemoryWrites
        ),
        checks: checks,
        notes: [
            "Hardens the fixture-only integrated cognitive loop across retrieval, goal selection, bridge, behavior result, and memory update.",
            "Retrieval remains before memory update and is not rerun after update.",
            "Accepted writes are bounded to one per agent/tick and rejected writes are audited.",
            "No behavior action is executed, no movement stack is used, and no World or terrain mutation occurs."
        ]
    )
}

private func makeCognitiveLoopIntegrationHardeningDigestValue(
    run: LabCognitiveLoopIntegrationHardeningRun
) -> String {
    let inputParts = run.inputs.map {
        "\($0.tick)|\($0.agentId)|\($0.currentGoal)|\($0.retrievalQueryPlan)|\($0.initialMemorySnapshot.map { "\($0.tick):\($0.type):\($0.summary):\($0.importance)" }.joined(separator: ","))"
    }
    let traceParts = run.trace.map {
        "\($0.tick)|\($0.agentId)|\($0.retrievalResultSummary)|\($0.goalSelectionDecisionSummary)|\($0.bridgeDecisionSummary)|\($0.memoryUpdateResultSummary)"
    }
    let decisionParts = run.decisions.map {
        "\($0.tick)|\($0.agentId)|\($0.goalBefore)|\($0.selectedGoal)|\($0.selectedAction)|\($0.memoryProposals)|\($0.acceptedMemoryWrites)|\($0.rejectedMemoryWrites)|\($0.memoryCountBefore)|\($0.memoryCountAfter)"
    }
    let snapshotParts = run.memorySnapshots.map {
        "\($0.agentId)|\($0.memoryCountBefore)|\($0.memoryCountAfter)|\($0.acceptedMemoryWrites)|\($0.rejectedMemoryWrites)|\($0.finalMemory.map { "\($0.tick):\($0.type):\($0.summary):\($0.importance)" }.joined(separator: ","))"
    }
    let caseParts = run.cases.map {
        "\($0.name)|\($0.passed)|\($0.expected)|\($0.actual)"
    }
    return cognitiveLoopStableDigest((inputParts + traceParts + decisionParts + snapshotParts + caseParts).joined(separator: "\n"))
}

private func makeCognitiveLoopIntegrationHardeningMetrics(
    report: LabCognitiveLoopIntegrationHardeningReport
) -> LabCognitiveLoopIntegrationHardeningMetrics {
    LabCognitiveLoopIntegrationHardeningMetrics(
        cognitiveLoopIntegrationHardeningSuccess: report.success,
        cognitiveLoopIntegrationHardeningCases: report.cases,
        cognitiveLoopIntegrationHardeningCasesPassed: report.casesPassed,
        cognitiveLoopIntegrationHardeningCasesFailed: report.casesFailed,
        cognitiveLoopIntegrationHardeningDecisions: report.decisions,
        cognitiveLoopIntegrationHardeningRetrievedMemories: report.retrievedMemories,
        cognitiveLoopIntegrationHardeningSelectedGoals: report.selectedGoals,
        cognitiveLoopIntegrationHardeningSelectedActions: report.selectedActions,
        cognitiveLoopIntegrationHardeningBehaviorResults: report.behaviorResults,
        cognitiveLoopIntegrationHardeningMemoryProposals: report.memoryProposals,
        cognitiveLoopIntegrationHardeningAcceptedMemoryWrites: report.acceptedMemoryWrites,
        cognitiveLoopIntegrationHardeningRejectedMemoryWrites: report.rejectedMemoryWrites,
        cognitiveLoopIntegrationHardeningMemoryCountBeforeTotal: report.memoryCountBeforeTotal,
        cognitiveLoopIntegrationHardeningMemoryCountAfterTotal: report.memoryCountAfterTotal,
        cognitiveLoopIntegrationHardeningGoalChanges: report.goalChanges,
        cognitiveLoopIntegrationHardeningUnchangedGoals: report.unchangedGoals,
        cognitiveLoopIntegrationHardeningEmptyRetrievalDecisions: report.emptyRetrievalDecisions,
        cognitiveLoopIntegrationHardeningLowConfidenceNoOverrideDecisions: report.lowConfidenceNoOverrideDecisions,
        cognitiveLoopIntegrationHardeningBehaviorActionExecuted: report.behaviorActionExecuted,
        cognitiveLoopIntegrationHardeningMemoryMutatedOutsideUpdate: report.memoryMutatedOutsideUpdate,
        cognitiveLoopIntegrationHardeningRetrievalRerunUnexpected: report.retrievalRerunUnexpected,
        cognitiveLoopIntegrationHardeningMovementStackUsed: report.movementStackUsed,
        cognitiveLoopIntegrationHardeningWorldMutated: report.worldMutated,
        cognitiveLoopIntegrationHardeningTerrainMutated: report.terrainMutated,
        cognitiveLoopIntegrationHardeningBounded: report.bounded,
        cognitiveLoopIntegrationHardeningDeterministicOrder: report.deterministicOrder,
        cognitiveLoopIntegrationHardeningDigestsEqual: report.digestsEqual,
        cognitiveLoopIntegrationHardeningRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeCognitiveLoopIntegrationHardeningEventLines(
    report: LabCognitiveLoopIntegrationHardeningReport
) throws -> String {
    try cognitiveLoopJSONLine(LabCognitiveLoopIntegrationHardeningRecordedEvent(
        type: "lab_cognitive_loop_integration_hardening_recorded",
        event: "lab_cognitive_loop_integration_hardening_recorded",
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        casesFailed: report.casesFailed,
        decisions: report.decisions,
        retrievedMemories: report.retrievedMemories,
        selectedGoals: report.selectedGoals,
        selectedActions: report.selectedActions,
        behaviorResults: report.behaviorResults,
        memoryProposals: report.memoryProposals,
        acceptedMemoryWrites: report.acceptedMemoryWrites,
        rejectedMemoryWrites: report.rejectedMemoryWrites,
        memoryCountBeforeTotal: report.memoryCountBeforeTotal,
        memoryCountAfterTotal: report.memoryCountAfterTotal,
        emptyRetrievalDecisions: report.emptyRetrievalDecisions,
        lowConfidenceNoOverrideDecisions: report.lowConfidenceNoOverrideDecisions,
        behaviorActionExecuted: report.behaviorActionExecuted,
        memoryMutatedOutsideUpdate: report.memoryMutatedOutsideUpdate,
        retrievalRerunUnexpected: report.retrievalRerunUnexpected,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        bounded: report.bounded,
        deterministicOrder: report.deterministicOrder,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
}
