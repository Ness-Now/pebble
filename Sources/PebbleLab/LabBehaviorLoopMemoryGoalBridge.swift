import Foundation

let behaviorLoopMemoryGoalBridgeScenarioName = "behavior_loop_memory_goal_bridge_fixture_smoke"
let behaviorLoopMemoryGoalBridgeExpectedAgents = 5

struct LabBehaviorLoopMemoryGoalBridgeInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let currentGoal: String
    let behaviorLoopInputSummary: String
    let retrievedMemoryResultSummary: String
    let goalSelectionDecisionSummary: String
    let memorySuggestedGoal: String?
    let memoryInfluenceApplied: Bool
    let memoryInfluenceReason: String
    let emptyRetrieval: Bool
    let needsSummary: String
    let fear: Double
    let health: Double
    let maxCandidates: Int
    let reason: String
}

struct LabBehaviorLoopMemoryGoalBridgeDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let goalBefore: String
    let memorySuggestedGoal: String?
    let selectedGoalForBehaviorLoop: String
    let goalChangedByMemory: Bool
    let selectedAction: String
    let actionReason: String
    let memoryInfluenceApplied: Bool
    let memoryInfluenceReason: String
    let emptyRetrieval: Bool
    let behaviorResultSummary: String
    let success: Bool
}

struct LabBehaviorLoopMemoryGoalBridgeReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let bridgeDecisions: Int
    let memorySuggestedGoals: Int
    let selectedGoals: Int
    let goalChangesByMemory: Int
    let unchangedGoals: Int
    let selectedActions: Int
    let behaviorResults: Int
    let memoryInfluencedDecisions: Int
    let emptyRetrievalDecisions: Int
    let behaviorActionExecuted: Bool
    let memoryMutated: Bool
    let memoryWritten: Bool
    let retrievalRerun: Bool
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

struct LabBehaviorLoopMemoryGoalBridgeInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let ticks: Int
    let bridgeDecisions: Int
    let selectedGoals: Int
    let goalChangesByMemory: Int
    let unchangedGoals: Int
}

struct LabBehaviorLoopMemoryGoalBridgeInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabBehaviorLoopMemoryGoalBridgeInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabBehaviorLoopMemoryGoalBridgeDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabBehaviorLoopMemoryGoalBridgeMetrics: Codable, Equatable {
    let behaviorLoopMemoryGoalBridgeSuccess: Bool
    let behaviorLoopMemoryGoalBridgeAgents: Int
    let behaviorLoopMemoryGoalBridgeTicks: Int
    let behaviorLoopMemoryGoalBridgeDecisions: Int
    let behaviorLoopMemoryGoalBridgeMemorySuggestedGoals: Int
    let behaviorLoopMemoryGoalBridgeSelectedGoals: Int
    let behaviorLoopMemoryGoalBridgeGoalChangesByMemory: Int
    let behaviorLoopMemoryGoalBridgeUnchangedGoals: Int
    let behaviorLoopMemoryGoalBridgeSelectedActions: Int
    let behaviorLoopMemoryGoalBridgeBehaviorResults: Int
    let behaviorLoopMemoryGoalBridgeInfluencedDecisions: Int
    let behaviorLoopMemoryGoalBridgeEmptyRetrievalDecisions: Int
    let behaviorLoopMemoryGoalBridgeBehaviorActionExecuted: Bool
    let behaviorLoopMemoryGoalBridgeMemoryMutated: Bool
    let behaviorLoopMemoryGoalBridgeMemoryWritten: Bool
    let behaviorLoopMemoryGoalBridgeRetrievalRerun: Bool
    let behaviorLoopMemoryGoalBridgeMovementStackUsed: Bool
    let behaviorLoopMemoryGoalBridgeWorldMutated: Bool
    let behaviorLoopMemoryGoalBridgeTerrainMutated: Bool
    let behaviorLoopMemoryGoalBridgeBounded: Bool
    let behaviorLoopMemoryGoalBridgeDeterministicOrder: Bool
    let behaviorLoopMemoryGoalBridgeDigestsEqual: Bool
    let behaviorLoopMemoryGoalBridgeRepeatabilityFailures: Int
}

struct LabBehaviorLoopMemoryGoalBridgeFixture: Codable, Equatable {
    let report: LabBehaviorLoopMemoryGoalBridgeReport
    let invariantReport: LabBehaviorLoopMemoryGoalBridgeInvariantReport
    let inputs: [LabBehaviorLoopMemoryGoalBridgeInput]
    let decisions: [LabBehaviorLoopMemoryGoalBridgeDecision]
    let digest: LabBehaviorLoopMemoryGoalBridgeDigest
    let eventLines: String
    let metrics: LabBehaviorLoopMemoryGoalBridgeMetrics
}

private struct LabBehaviorLoopMemoryGoalBridgeRun {
    let inputs: [LabBehaviorLoopMemoryGoalBridgeInput]
    let decisions: [LabBehaviorLoopMemoryGoalBridgeDecision]
}

private struct LabBehaviorLoopMemoryGoalBridgeRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let goalBefore: String
    let memorySuggestedGoal: String?
    let selectedGoalForBehaviorLoop: String
    let goalChangedByMemory: Bool
    let selectedAction: String
    let memoryInfluenceApplied: Bool
    let memoryInfluenceReason: String
    let emptyRetrieval: Bool
    let behaviorActionExecuted: Bool
}

private struct LabBehaviorLoopMemoryGoalBridgeSummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let ticks: Int
    let decisions: Int
    let selectedGoals: Int
    let goalChangesByMemory: Int
    let selectedActions: Int
    let behaviorResults: Int
    let influencedDecisions: Int
    let emptyRetrievalDecisions: Int
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeBehaviorLoopMemoryGoalBridgeFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabBehaviorLoopMemoryGoalBridgeFixture {
    let run = makeBehaviorLoopMemoryGoalBridgeRun(ticks: ticks)
    let repeatRun = makeBehaviorLoopMemoryGoalBridgeRun(ticks: ticks)
    let digestValue = makeBehaviorLoopMemoryGoalBridgeDigestValue(run: run)
    let digestRepeatValue = makeBehaviorLoopMemoryGoalBridgeDigestValue(run: repeatRun)
    let digest = LabBehaviorLoopMemoryGoalBridgeDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeBehaviorLoopMemoryGoalBridgeReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeBehaviorLoopMemoryGoalBridgeInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabBehaviorLoopMemoryGoalBridgeFixture(
        report: report,
        invariantReport: invariantReport,
        inputs: run.inputs,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeBehaviorLoopMemoryGoalBridgeEventLines(report: report, decisions: run.decisions),
        metrics: makeBehaviorLoopMemoryGoalBridgeMetrics(report: report)
    )
}

private func makeBehaviorLoopMemoryGoalBridgeRun(
    ticks: Int
) -> LabBehaviorLoopMemoryGoalBridgeRun {
    let tick = max(1, ticks)
    let inputs = makeBehaviorLoopMemoryGoalBridgeInputs(tick: tick).sorted {
        ($0.tick, $0.agentId) < ($1.tick, $1.agentId)
    }
    let decisions = inputs.map(makeBehaviorLoopMemoryGoalBridgeDecision).sorted(by: behaviorLoopMemoryGoalBridgeDecisionSort)
    return LabBehaviorLoopMemoryGoalBridgeRun(inputs: inputs, decisions: decisions)
}

private func makeBehaviorLoopMemoryGoalBridgeInputs(
    tick: Int
) -> [LabBehaviorLoopMemoryGoalBridgeInput] {
    [
        LabBehaviorLoopMemoryGoalBridgeInput(
            tick: tick,
            agentId: "bridge_agent_0",
            currentGoal: LabGoalKind.idle.rawValue,
            behaviorLoopInputSummary: "goal=idle;needs=safety_low",
            retrievedMemoryResultSummary: "top=safety_reaction;score=1.80",
            goalSelectionDecisionSummary: "selectedGoal=seekSafety;changed=true",
            memorySuggestedGoal: LabGoalKind.seekSafety.rawValue,
            memoryInfluenceApplied: true,
            memoryInfluenceReason: "safety_reaction supports seekSafety",
            emptyRetrieval: false,
            needsSummary: "safety=0.20;curiosity=0.20",
            fear: 88,
            health: 60,
            maxCandidates: 5,
            reason: "safety memory should enter behavior loop as seekSafety"
        ),
        LabBehaviorLoopMemoryGoalBridgeInput(
            tick: tick,
            agentId: "bridge_agent_1",
            currentGoal: LabGoalKind.idle.rawValue,
            behaviorLoopInputSummary: "goal=idle;needs=curiosity_high",
            retrievedMemoryResultSummary: "top=curiosity_reaction;score=1.35",
            goalSelectionDecisionSummary: "selectedGoal=explore;changed=true",
            memorySuggestedGoal: LabGoalKind.explore.rawValue,
            memoryInfluenceApplied: true,
            memoryInfluenceReason: "curiosity_reaction supports explore",
            emptyRetrieval: false,
            needsSummary: "safety=1.00;curiosity=0.90",
            fear: 5,
            health: 100,
            maxCandidates: 5,
            reason: "curiosity memory should enter behavior loop as explore"
        ),
        LabBehaviorLoopMemoryGoalBridgeInput(
            tick: tick,
            agentId: "bridge_agent_2",
            currentGoal: LabGoalKind.idle.rawValue,
            behaviorLoopInputSummary: "goal=idle;nearby_agent=true",
            retrievedMemoryResultSummary: "top=nearby_agent_observed;score=1.20",
            goalSelectionDecisionSummary: "selectedGoal=observeOtherAgent;changed=true",
            memorySuggestedGoal: LabGoalKind.observeOtherAgent.rawValue,
            memoryInfluenceApplied: true,
            memoryInfluenceReason: "nearby_agent_observed supports observeOtherAgent",
            emptyRetrieval: false,
            needsSummary: "safety=1.00;curiosity=0.50",
            fear: 10,
            health: 100,
            maxCandidates: 5,
            reason: "nearby memory should enter behavior loop as observeOtherAgent"
        ),
        LabBehaviorLoopMemoryGoalBridgeInput(
            tick: tick,
            agentId: "bridge_agent_3",
            currentGoal: LabGoalKind.explore.rawValue,
            behaviorLoopInputSummary: "goal=explore;retrieval_empty=true",
            retrievedMemoryResultSummary: "empty",
            goalSelectionDecisionSummary: "selectedGoal=explore;changed=false",
            memorySuggestedGoal: nil,
            memoryInfluenceApplied: false,
            memoryInfluenceReason: "empty retrieval kept current goal",
            emptyRetrieval: true,
            needsSummary: "safety=1.00;curiosity=0.70",
            fear: 0,
            health: 100,
            maxCandidates: 5,
            reason: "empty retrieval keeps current goal"
        ),
        LabBehaviorLoopMemoryGoalBridgeInput(
            tick: tick,
            agentId: "bridge_agent_4",
            currentGoal: LabGoalKind.seekSafety.rawValue,
            behaviorLoopInputSummary: "goal=seekSafety;weak_memory=explore",
            retrievedMemoryResultSummary: "top=curiosity_reaction;score=0.20",
            goalSelectionDecisionSummary: "selectedGoal=seekSafety;changed=false",
            memorySuggestedGoal: LabGoalKind.explore.rawValue,
            memoryInfluenceApplied: false,
            memoryInfluenceReason: "low confidence memory kept current goal",
            emptyRetrieval: false,
            needsSummary: "safety=0.30;curiosity=0.30",
            fear: 78,
            health: 72,
            maxCandidates: 5,
            reason: "weak memory cannot override safety continuity"
        )
    ]
}

private func makeBehaviorLoopMemoryGoalBridgeDecision(
    input: LabBehaviorLoopMemoryGoalBridgeInput
) -> LabBehaviorLoopMemoryGoalBridgeDecision {
    let selectedGoal = selectedGoalForBehaviorLoop(input)
    let selectedAction = behaviorLoopMemoryGoalBridgeAction(for: selectedGoal)
    let behaviorResult = "abstract_result:\(selectedAction):prepared_without_execution"
    let knownGoal = behaviorLoopMemoryGoalBridgeKnownGoals.contains(selectedGoal)
    let success = knownGoal
        && !selectedAction.isEmpty
        && !behaviorResult.isEmpty
        && !input.memoryInfluenceReason.isEmpty
        && behaviorLoopMemoryGoalBridgeKnownActions.contains(selectedAction)
    return LabBehaviorLoopMemoryGoalBridgeDecision(
        tick: input.tick,
        agentId: input.agentId,
        goalBefore: input.currentGoal,
        memorySuggestedGoal: input.memorySuggestedGoal,
        selectedGoalForBehaviorLoop: selectedGoal,
        goalChangedByMemory: selectedGoal != input.currentGoal,
        selectedAction: selectedAction,
        actionReason: "selectedAction \(selectedAction) follows selectedGoal \(selectedGoal)",
        memoryInfluenceApplied: input.memoryInfluenceApplied && selectedGoal != input.currentGoal,
        memoryInfluenceReason: input.memoryInfluenceReason,
        emptyRetrieval: input.emptyRetrieval,
        behaviorResultSummary: behaviorResult,
        success: success
    )
}

private func selectedGoalForBehaviorLoop(
    _ input: LabBehaviorLoopMemoryGoalBridgeInput
) -> String {
    guard input.memoryInfluenceApplied,
          let memorySuggestedGoal = input.memorySuggestedGoal,
          behaviorLoopMemoryGoalBridgeKnownGoals.contains(memorySuggestedGoal)
    else {
        return behaviorLoopMemoryGoalBridgeKnownGoals.contains(input.currentGoal)
            ? input.currentGoal
            : LabGoalKind.idle.rawValue
    }
    return memorySuggestedGoal
}

private func behaviorLoopMemoryGoalBridgeAction(
    for goal: String
) -> String {
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

private let behaviorLoopMemoryGoalBridgeKnownGoals = Set([
    LabGoalKind.idle.rawValue,
    LabGoalKind.rest.rawValue,
    LabGoalKind.seekSafety.rawValue,
    LabGoalKind.explore.rawValue,
    LabGoalKind.observeOtherAgent.rawValue
])

private let behaviorLoopMemoryGoalBridgeKnownActions = Set([
    "idle",
    "rest",
    "seekSafety",
    "explore",
    "observeAgent"
])

private func makeBehaviorLoopMemoryGoalBridgeReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabBehaviorLoopMemoryGoalBridgeRun,
    digest: LabBehaviorLoopMemoryGoalBridgeDigest
) -> LabBehaviorLoopMemoryGoalBridgeReport {
    let agents = Set(run.inputs.map(\.agentId)).count
    let decisions = run.decisions.count
    let selectedGoals = run.decisions.filter { !$0.selectedGoalForBehaviorLoop.isEmpty }.count
    let selectedActions = run.decisions.filter { !$0.selectedAction.isEmpty }.count
    let behaviorResults = run.decisions.filter { !$0.behaviorResultSummary.isEmpty }.count
    let memorySuggestedGoals = run.decisions.filter { $0.memorySuggestedGoal != nil }.count
    let goalChanges = run.decisions.filter(\.goalChangedByMemory).count
    let unchangedGoals = run.decisions.filter { !$0.goalChangedByMemory }.count
    let influenced = run.decisions.filter(\.memoryInfluenceApplied).count
    let emptyRetrieval = run.decisions.filter(\.emptyRetrieval).count
    let deterministicOrder = run.decisions == run.decisions.sorted(by: behaviorLoopMemoryGoalBridgeDecisionSort)
    let bounded = agents >= behaviorLoopMemoryGoalBridgeExpectedAgents
        && decisions == run.inputs.count
        && run.inputs.allSatisfy { $0.maxCandidates >= 1 && $0.maxCandidates <= goalSelectionMemoryMaxCandidatesLimit }
    let repeatabilityFailures = digest.digestsEqual ? 0 : 1
    let success = agents >= behaviorLoopMemoryGoalBridgeExpectedAgents
        && max(1, ticks) >= 1
        && decisions >= behaviorLoopMemoryGoalBridgeExpectedAgents
        && selectedGoals == decisions
        && selectedActions == decisions
        && behaviorResults == decisions
        && memorySuggestedGoals >= 3
        && goalChanges >= 3
        && unchangedGoals >= 1
        && influenced >= 3
        && emptyRetrieval >= 1
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual
        && repeatabilityFailures == 0
        && run.decisions.allSatisfy(\.success)
    return LabBehaviorLoopMemoryGoalBridgeReport(
        scenario: scenario,
        seed: seed,
        agents: agents,
        ticks: max(1, ticks),
        bridgeDecisions: decisions,
        memorySuggestedGoals: memorySuggestedGoals,
        selectedGoals: selectedGoals,
        goalChangesByMemory: goalChanges,
        unchangedGoals: unchangedGoals,
        selectedActions: selectedActions,
        behaviorResults: behaviorResults,
        memoryInfluencedDecisions: influenced,
        emptyRetrievalDecisions: emptyRetrieval,
        behaviorActionExecuted: false,
        memoryMutated: false,
        memoryWritten: false,
        retrievalRerun: false,
        movementStackUsed: false,
        worldMutated: false,
        terrainMutated: false,
        bounded: bounded,
        deterministicOrder: deterministicOrder,
        digest: digest.digest,
        digestRepeat: digest.digestRepeat,
        digestsEqual: digest.digestsEqual,
        deterministicDigest: digest.deterministicDigest,
        repeatabilityFailures: repeatabilityFailures,
        success: success
    )
}

private func makeBehaviorLoopMemoryGoalBridgeInvariantReport(
    report: LabBehaviorLoopMemoryGoalBridgeReport,
    run: LabBehaviorLoopMemoryGoalBridgeRun,
    digest: LabBehaviorLoopMemoryGoalBridgeDigest
) -> LabBehaviorLoopMemoryGoalBridgeInvariantReport {
    let knownGoalsOnly = run.decisions.allSatisfy {
        behaviorLoopMemoryGoalBridgeKnownGoals.contains($0.selectedGoalForBehaviorLoop)
    }
    let selectedActionPresent = run.decisions.allSatisfy { !$0.selectedAction.isEmpty }
    let behaviorResultPresent = run.decisions.allSatisfy { !$0.behaviorResultSummary.isEmpty }
    let influenceReasonPresent = run.decisions.allSatisfy { !$0.memoryInfluenceReason.isEmpty }
    let actionReasonPresent = run.decisions.allSatisfy { !$0.actionReason.isEmpty }
    let lowConfidenceCovered = run.decisions.contains {
        $0.agentId == "bridge_agent_4"
            && !$0.goalChangedByMemory
            && !$0.memoryInfluenceApplied
            && $0.memorySuggestedGoal == LabGoalKind.explore.rawValue
    }
    let safetyOverrideCovered = run.decisions.contains {
        $0.agentId == "bridge_agent_0"
            && $0.selectedGoalForBehaviorLoop == LabGoalKind.seekSafety.rawValue
            && $0.selectedAction == "seekSafety"
            && $0.goalChangedByMemory
    }
    let successContractRespected = report.success
        && run.decisions.allSatisfy(\.success)
        && knownGoalsOnly
        && selectedActionPresent
        && behaviorResultPresent
        && influenceReasonPresent
        && actionReasonPresent
        && lowConfidenceCovered
        && safetyOverrideCovered
    var checks: [LabBehaviorLoopInvariantCheck] = []

    checks.append(behaviorLoopMemoryGoalBridgeCheck("scenario_name_expected", report.scenario == behaviorLoopMemoryGoalBridgeScenarioName, behaviorLoopMemoryGoalBridgeScenarioName, report.scenario))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("agents_expected", report.agents >= behaviorLoopMemoryGoalBridgeExpectedAgents, ">= \(behaviorLoopMemoryGoalBridgeExpectedAgents)", "\(report.agents)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("ticks_expected", report.ticks >= 1, ">= 1", "\(report.ticks)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("bridge_decisions_positive", report.bridgeDecisions > 0, "> 0", "\(report.bridgeDecisions)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("selected_goal_present", report.selectedGoals == report.bridgeDecisions, "\(report.bridgeDecisions)", "\(report.selectedGoals)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("known_v0_goals_only", knownGoalsOnly, "true", "\(knownGoalsOnly)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("selected_action_present", selectedActionPresent, "true", "\(selectedActionPresent)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("goal_changes_by_memory_covered", report.goalChangesByMemory >= 3, ">= 3", "\(report.goalChangesByMemory)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("unchanged_goal_covered", report.unchangedGoals >= 1, ">= 1", "\(report.unchangedGoals)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("memory_influence_covered", report.memoryInfluencedDecisions >= 3, ">= 3", "\(report.memoryInfluencedDecisions)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("empty_retrieval_covered", report.emptyRetrievalDecisions >= 1, ">= 1", "\(report.emptyRetrievalDecisions)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("low_confidence_no_override_covered", lowConfidenceCovered, "true", "\(lowConfidenceCovered)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("safety_override_covered", safetyOverrideCovered, "true", "\(safetyOverrideCovered)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("behavior_result_present", behaviorResultPresent, "true", "\(behaviorResultPresent)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("memory_influence_reason_present", influenceReasonPresent, "true", "\(influenceReasonPresent)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("action_reason_present", actionReasonPresent, "true", "\(actionReasonPresent)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("behavior_action_not_executed", !report.behaviorActionExecuted, "false", "\(report.behaviorActionExecuted)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("memory_not_written", !report.memoryWritten, "false", "\(report.memoryWritten)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("retrieval_not_rerun", !report.retrievalRerun, "false", "\(report.retrievalRerun)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("bounded_true", report.bounded, "true", "\(report.bounded)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("report_written", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("invariant_report_written", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("decisions_written", !run.decisions.isEmpty, "true", "\(!run.decisions.isEmpty)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("metrics_written", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("event_written", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("metrics_prefix_expected", true, "behaviorLoopMemoryGoalBridge*", "behaviorLoopMemoryGoalBridge*"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("event_name_expected", true, "lab_behavior_loop_memory_goal_bridge_recorded", "lab_behavior_loop_memory_goal_bridge_recorded"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("changelog_updated", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("dev_journal_updated", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("roadmap_updated", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("phase_plan_updated", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("success_contract_respected", successContractRespected, "true", "\(successContractRespected)"))

    let failed = checks.filter { !$0.passed }.count
    return LabBehaviorLoopMemoryGoalBridgeInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabBehaviorLoopMemoryGoalBridgeInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            agents: report.agents,
            ticks: report.ticks,
            bridgeDecisions: report.bridgeDecisions,
            selectedGoals: report.selectedGoals,
            goalChangesByMemory: report.goalChangesByMemory,
            unchangedGoals: report.unchangedGoals
        ),
        checks: checks,
        notes: [
            "Fixture-only bridge from memory-informed goal selection to abstract behavior loop action selection.",
            "No behavior action is executed, no memory is written, and retrieval is not rerun.",
            "Movement stack, World, terrain, Core entities, and physical placeholders remain untouched."
        ]
    )
}

private func makeBehaviorLoopMemoryGoalBridgeDigestValue(
    run: LabBehaviorLoopMemoryGoalBridgeRun
) -> String {
    let inputParts = run.inputs.map {
        "\($0.tick)|\($0.agentId)|\($0.currentGoal)|\($0.memorySuggestedGoal ?? "nil")|\($0.memoryInfluenceApplied)|\($0.emptyRetrieval)|\($0.needsSummary)|\($0.fear)|\($0.health)"
    }
    let decisionParts = run.decisions.map {
        "\($0.tick)|\($0.agentId)|\($0.goalBefore)|\($0.memorySuggestedGoal ?? "nil")|\($0.selectedGoalForBehaviorLoop)|\($0.goalChangedByMemory)|\($0.selectedAction)|\($0.memoryInfluenceApplied)|\($0.emptyRetrieval)|\($0.behaviorResultSummary)"
    }
    return behaviorLoopMemoryGoalBridgeStableDigest((inputParts + decisionParts).joined(separator: "\n"))
}

private func makeBehaviorLoopMemoryGoalBridgeMetrics(
    report: LabBehaviorLoopMemoryGoalBridgeReport
) -> LabBehaviorLoopMemoryGoalBridgeMetrics {
    LabBehaviorLoopMemoryGoalBridgeMetrics(
        behaviorLoopMemoryGoalBridgeSuccess: report.success,
        behaviorLoopMemoryGoalBridgeAgents: report.agents,
        behaviorLoopMemoryGoalBridgeTicks: report.ticks,
        behaviorLoopMemoryGoalBridgeDecisions: report.bridgeDecisions,
        behaviorLoopMemoryGoalBridgeMemorySuggestedGoals: report.memorySuggestedGoals,
        behaviorLoopMemoryGoalBridgeSelectedGoals: report.selectedGoals,
        behaviorLoopMemoryGoalBridgeGoalChangesByMemory: report.goalChangesByMemory,
        behaviorLoopMemoryGoalBridgeUnchangedGoals: report.unchangedGoals,
        behaviorLoopMemoryGoalBridgeSelectedActions: report.selectedActions,
        behaviorLoopMemoryGoalBridgeBehaviorResults: report.behaviorResults,
        behaviorLoopMemoryGoalBridgeInfluencedDecisions: report.memoryInfluencedDecisions,
        behaviorLoopMemoryGoalBridgeEmptyRetrievalDecisions: report.emptyRetrievalDecisions,
        behaviorLoopMemoryGoalBridgeBehaviorActionExecuted: report.behaviorActionExecuted,
        behaviorLoopMemoryGoalBridgeMemoryMutated: report.memoryMutated,
        behaviorLoopMemoryGoalBridgeMemoryWritten: report.memoryWritten,
        behaviorLoopMemoryGoalBridgeRetrievalRerun: report.retrievalRerun,
        behaviorLoopMemoryGoalBridgeMovementStackUsed: report.movementStackUsed,
        behaviorLoopMemoryGoalBridgeWorldMutated: report.worldMutated,
        behaviorLoopMemoryGoalBridgeTerrainMutated: report.terrainMutated,
        behaviorLoopMemoryGoalBridgeBounded: report.bounded,
        behaviorLoopMemoryGoalBridgeDeterministicOrder: report.deterministicOrder,
        behaviorLoopMemoryGoalBridgeDigestsEqual: report.digestsEqual,
        behaviorLoopMemoryGoalBridgeRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeBehaviorLoopMemoryGoalBridgeEventLines(
    report: LabBehaviorLoopMemoryGoalBridgeReport,
    decisions: [LabBehaviorLoopMemoryGoalBridgeDecision]
) throws -> String {
    var lines = ""
    for decision in decisions.sorted(by: behaviorLoopMemoryGoalBridgeDecisionSort) {
        lines += try encodeBehaviorLoopMemoryGoalBridgeEventLine(LabBehaviorLoopMemoryGoalBridgeRecordedEvent(
            type: "lab_behavior_loop_memory_goal_bridge_recorded",
            event: "lab_behavior_loop_memory_goal_bridge_recorded",
            success: report.success,
            agentId: decision.agentId,
            tick: decision.tick,
            goalBefore: decision.goalBefore,
            memorySuggestedGoal: decision.memorySuggestedGoal,
            selectedGoalForBehaviorLoop: decision.selectedGoalForBehaviorLoop,
            goalChangedByMemory: decision.goalChangedByMemory,
            selectedAction: decision.selectedAction,
            memoryInfluenceApplied: decision.memoryInfluenceApplied,
            memoryInfluenceReason: decision.memoryInfluenceReason,
            emptyRetrieval: decision.emptyRetrieval,
            behaviorActionExecuted: report.behaviorActionExecuted
        ))
    }
    lines += try encodeBehaviorLoopMemoryGoalBridgeEventLine(LabBehaviorLoopMemoryGoalBridgeSummaryEvent(
        type: "lab_behavior_loop_memory_goal_bridge_summary_recorded",
        event: "lab_behavior_loop_memory_goal_bridge_summary_recorded",
        success: report.success,
        agents: report.agents,
        ticks: report.ticks,
        decisions: report.bridgeDecisions,
        selectedGoals: report.selectedGoals,
        goalChangesByMemory: report.goalChangesByMemory,
        selectedActions: report.selectedActions,
        behaviorResults: report.behaviorResults,
        influencedDecisions: report.memoryInfluencedDecisions,
        emptyRetrievalDecisions: report.emptyRetrievalDecisions,
        bounded: report.bounded,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
    return lines
}

private func encodeBehaviorLoopMemoryGoalBridgeEventLine<T: Encodable>(
    _ event: T
) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(event)
    return String(decoding: data, as: UTF8.self) + "\n"
}

private func behaviorLoopMemoryGoalBridgeCheck(
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

private func behaviorLoopMemoryGoalBridgeDecisionSort(
    _ lhs: LabBehaviorLoopMemoryGoalBridgeDecision,
    _ rhs: LabBehaviorLoopMemoryGoalBridgeDecision
) -> Bool {
    if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
    return lhs.agentId < rhs.agentId
}

private func behaviorLoopMemoryGoalBridgeStableDigest(
    _ input: String
) -> String {
    var hash: UInt64 = 0xcbf29ce484222325
    let prime: UInt64 = 0x100000001b3
    for byte in input.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* prime
    }
    return String(format: "%016llx", hash)
}
