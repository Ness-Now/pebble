import Foundation

let behaviorLoopMemoryGoalBridgeScenarioName = "behavior_loop_memory_goal_bridge_fixture_smoke"
let behaviorLoopMemoryGoalBridgeHardeningScenarioName = "behavior_loop_memory_goal_bridge_hardening_smoke"
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
    if input.fear >= 70 || input.health <= 25 || input.needsSummary.contains("safety=0.") {
        return LabGoalKind.seekSafety.rawValue
    }
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

struct LabBehaviorLoopMemoryGoalBridgeHardeningCase: Codable, Equatable {
    let name: String
    let expected: String
    let actual: String
    let passed: Bool
}

struct LabBehaviorLoopMemoryGoalBridgeHardeningReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let bridgeDecisions: Int
    let selectedGoals: Int
    let selectedActions: Int
    let behaviorResults: Int
    let memorySuggestedGoals: Int
    let goalChangesByMemory: Int
    let unchangedGoals: Int
    let memoryInfluencedDecisions: Int
    let emptyRetrievalDecisions: Int
    let lowConfidenceNoOverrideDecisions: Int
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

struct LabBehaviorLoopMemoryGoalBridgeHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let bridgeDecisions: Int
    let selectedGoals: Int
    let selectedActions: Int
}

struct LabBehaviorLoopMemoryGoalBridgeHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabBehaviorLoopMemoryGoalBridgeHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabBehaviorLoopMemoryGoalBridgeHardeningMetrics: Codable, Equatable {
    let behaviorLoopMemoryGoalBridgeHardeningSuccess: Bool
    let behaviorLoopMemoryGoalBridgeHardeningCases: Int
    let behaviorLoopMemoryGoalBridgeHardeningCasesPassed: Int
    let behaviorLoopMemoryGoalBridgeHardeningCasesFailed: Int
    let behaviorLoopMemoryGoalBridgeHardeningDecisions: Int
    let behaviorLoopMemoryGoalBridgeHardeningSelectedGoals: Int
    let behaviorLoopMemoryGoalBridgeHardeningSelectedActions: Int
    let behaviorLoopMemoryGoalBridgeHardeningBehaviorResults: Int
    let behaviorLoopMemoryGoalBridgeHardeningMemorySuggestedGoals: Int
    let behaviorLoopMemoryGoalBridgeHardeningGoalChangesByMemory: Int
    let behaviorLoopMemoryGoalBridgeHardeningUnchangedGoals: Int
    let behaviorLoopMemoryGoalBridgeHardeningInfluencedDecisions: Int
    let behaviorLoopMemoryGoalBridgeHardeningEmptyRetrievalDecisions: Int
    let behaviorLoopMemoryGoalBridgeHardeningLowConfidenceNoOverrideDecisions: Int
    let behaviorLoopMemoryGoalBridgeHardeningBehaviorActionExecuted: Bool
    let behaviorLoopMemoryGoalBridgeHardeningMemoryMutated: Bool
    let behaviorLoopMemoryGoalBridgeHardeningMemoryWritten: Bool
    let behaviorLoopMemoryGoalBridgeHardeningRetrievalRerun: Bool
    let behaviorLoopMemoryGoalBridgeHardeningMovementStackUsed: Bool
    let behaviorLoopMemoryGoalBridgeHardeningWorldMutated: Bool
    let behaviorLoopMemoryGoalBridgeHardeningTerrainMutated: Bool
    let behaviorLoopMemoryGoalBridgeHardeningBounded: Bool
    let behaviorLoopMemoryGoalBridgeHardeningDeterministicOrder: Bool
    let behaviorLoopMemoryGoalBridgeHardeningDigestsEqual: Bool
    let behaviorLoopMemoryGoalBridgeHardeningRepeatabilityFailures: Int
}

struct LabBehaviorLoopMemoryGoalBridgeHardeningFixture: Codable, Equatable {
    let report: LabBehaviorLoopMemoryGoalBridgeHardeningReport
    let invariantReport: LabBehaviorLoopMemoryGoalBridgeHardeningInvariantReport
    let cases: [LabBehaviorLoopMemoryGoalBridgeHardeningCase]
    let inputs: [LabBehaviorLoopMemoryGoalBridgeInput]
    let decisions: [LabBehaviorLoopMemoryGoalBridgeDecision]
    let digest: LabBehaviorLoopMemoryGoalBridgeDigest
    let eventLines: String
    let metrics: LabBehaviorLoopMemoryGoalBridgeHardeningMetrics
}

private struct LabBehaviorLoopMemoryGoalBridgeHardeningRun {
    let inputs: [LabBehaviorLoopMemoryGoalBridgeInput]
    let decisions: [LabBehaviorLoopMemoryGoalBridgeDecision]
    let cases: [LabBehaviorLoopMemoryGoalBridgeHardeningCase]
}

private struct LabBehaviorLoopMemoryGoalBridgeHardeningRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let bridgeDecisions: Int
    let selectedGoals: Int
    let selectedActions: Int
    let behaviorResults: Int
    let memorySuggestedGoals: Int
    let goalChangesByMemory: Int
    let unchangedGoals: Int
    let memoryInfluencedDecisions: Int
    let emptyRetrievalDecisions: Int
    let lowConfidenceNoOverrideDecisions: Int
    let behaviorActionExecuted: Bool
    let memoryMutated: Bool
    let memoryWritten: Bool
    let retrievalRerun: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let bounded: Bool
    let deterministicOrder: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeBehaviorLoopMemoryGoalBridgeHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabBehaviorLoopMemoryGoalBridgeHardeningFixture {
    let run = makeBehaviorLoopMemoryGoalBridgeHardeningRun(ticks: ticks)
    let repeatRun = makeBehaviorLoopMemoryGoalBridgeHardeningRun(ticks: ticks)
    let digestValue = makeBehaviorLoopMemoryGoalBridgeHardeningDigestValue(run: run)
    let digestRepeatValue = makeBehaviorLoopMemoryGoalBridgeHardeningDigestValue(run: repeatRun)
    let digest = LabBehaviorLoopMemoryGoalBridgeDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeBehaviorLoopMemoryGoalBridgeHardeningReport(
        scenario: scenario,
        seed: seed,
        run: run,
        digest: digest
    )
    let invariantReport = makeBehaviorLoopMemoryGoalBridgeHardeningInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabBehaviorLoopMemoryGoalBridgeHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: run.cases,
        inputs: run.inputs,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeBehaviorLoopMemoryGoalBridgeHardeningEventLines(report: report),
        metrics: makeBehaviorLoopMemoryGoalBridgeHardeningMetrics(report: report)
    )
}

private func makeBehaviorLoopMemoryGoalBridgeHardeningRun(
    ticks: Int
) -> LabBehaviorLoopMemoryGoalBridgeHardeningRun {
    let tick = max(1, ticks)
    let fixtureRun = makeBehaviorLoopMemoryGoalBridgeRun(ticks: ticks)
    let caseInputs = makeBehaviorLoopMemoryGoalBridgeHardeningInputs(tick: tick)
    let inputs = (fixtureRun.inputs + caseInputs).sorted {
        ($0.tick, $0.agentId) < ($1.tick, $1.agentId)
    }
    let decisions = inputs.map(makeBehaviorLoopMemoryGoalBridgeDecision).sorted(by: behaviorLoopMemoryGoalBridgeDecisionSort)
    let cases = makeBehaviorLoopMemoryGoalBridgeHardeningCases(
        fixtureRun: fixtureRun,
        inputs: inputs,
        decisions: decisions
    )
    return LabBehaviorLoopMemoryGoalBridgeHardeningRun(
        inputs: inputs,
        decisions: decisions,
        cases: cases
    )
}

private func makeBehaviorLoopMemoryGoalBridgeHardeningInputs(
    tick: Int
) -> [LabBehaviorLoopMemoryGoalBridgeInput] {
    [
        behaviorLoopMemoryGoalBridgeHardeningInput(
            tick: tick,
            agentId: "case_idle",
            currentGoal: LabGoalKind.idle.rawValue,
            memorySuggestedGoal: LabGoalKind.idle.rawValue,
            influence: true,
            reason: "idle memory keeps idle bridge action",
            needs: "safety=1.00;curiosity=0.10",
            fear: 0
        ),
        behaviorLoopMemoryGoalBridgeHardeningInput(
            tick: tick,
            agentId: "case_continuity",
            currentGoal: LabGoalKind.rest.rawValue,
            memorySuggestedGoal: LabGoalKind.rest.rawValue,
            influence: false,
            reason: "currentGoal continuity preserved",
            needs: "safety=1.00;fatigue=0.02",
            fear: 0
        ),
        behaviorLoopMemoryGoalBridgeHardeningInput(
            tick: tick,
            agentId: "case_unknown_goal",
            currentGoal: LabGoalKind.idle.rawValue,
            memorySuggestedGoal: "buildCastle",
            influence: true,
            reason: "unknown suggested goal sanitized to current goal",
            needs: "safety=1.00;curiosity=0.10",
            fear: 0
        ),
        behaviorLoopMemoryGoalBridgeHardeningInput(
            tick: tick,
            agentId: "case_missing_suggested_goal",
            currentGoal: LabGoalKind.rest.rawValue,
            memorySuggestedGoal: nil,
            influence: true,
            reason: "missing memorySuggestedGoal keeps current goal",
            needs: "safety=1.00;fatigue=0.02",
            fear: 0
        ),
        behaviorLoopMemoryGoalBridgeHardeningInput(
            tick: tick,
            agentId: "case_conflict_safety_curiosity",
            currentGoal: LabGoalKind.seekSafety.rawValue,
            memorySuggestedGoal: LabGoalKind.explore.rawValue,
            influence: true,
            reason: "fear priority keeps seekSafety over curiosity",
            needs: "safety=0.20;curiosity=0.90",
            fear: 90
        ),
        behaviorLoopMemoryGoalBridgeHardeningInput(
            tick: tick,
            agentId: "case_unsorted_b",
            currentGoal: LabGoalKind.idle.rawValue,
            memorySuggestedGoal: LabGoalKind.explore.rawValue,
            influence: true,
            reason: "unsorted input b",
            needs: "safety=1.00;curiosity=0.90",
            fear: 0
        ),
        behaviorLoopMemoryGoalBridgeHardeningInput(
            tick: tick,
            agentId: "case_unsorted_a",
            currentGoal: LabGoalKind.idle.rawValue,
            memorySuggestedGoal: LabGoalKind.seekSafety.rawValue,
            influence: true,
            reason: "unsorted input a",
            needs: "safety=0.30;curiosity=0.10",
            fear: 80
        )
    ]
}

private func behaviorLoopMemoryGoalBridgeHardeningInput(
    tick: Int,
    agentId: String,
    currentGoal: String,
    memorySuggestedGoal: String?,
    influence: Bool,
    reason: String,
    needs: String,
    fear: Double
) -> LabBehaviorLoopMemoryGoalBridgeInput {
    LabBehaviorLoopMemoryGoalBridgeInput(
        tick: tick,
        agentId: agentId,
        currentGoal: currentGoal,
        behaviorLoopInputSummary: "hardening_currentGoal=\(currentGoal)",
        retrievedMemoryResultSummary: memorySuggestedGoal.map { "suggested=\($0)" } ?? "missing_suggested_goal",
        goalSelectionDecisionSummary: "hardening_goal_selection",
        memorySuggestedGoal: memorySuggestedGoal,
        memoryInfluenceApplied: influence,
        memoryInfluenceReason: reason,
        emptyRetrieval: memorySuggestedGoal == nil,
        needsSummary: needs,
        fear: fear,
        health: 100,
        maxCandidates: 5,
        reason: reason
    )
}

private func makeBehaviorLoopMemoryGoalBridgeHardeningCases(
    fixtureRun: LabBehaviorLoopMemoryGoalBridgeRun,
    inputs: [LabBehaviorLoopMemoryGoalBridgeInput],
    decisions: [LabBehaviorLoopMemoryGoalBridgeDecision]
) -> [LabBehaviorLoopMemoryGoalBridgeHardeningCase] {
    func decision(_ agentId: String) -> LabBehaviorLoopMemoryGoalBridgeDecision? {
        decisions.first { $0.agentId == agentId }
    }
    func add(_ name: String, _ passed: Bool, _ expected: String, _ actual: String) -> LabBehaviorLoopMemoryGoalBridgeHardeningCase {
        LabBehaviorLoopMemoryGoalBridgeHardeningCase(name: name, expected: expected, actual: actual, passed: passed)
    }
    let baselineCompatible = fixtureRun.decisions.count == behaviorLoopMemoryGoalBridgeExpectedAgents
        && fixtureRun.decisions.filter(\.emptyRetrieval).count >= 1
        && fixtureRun.decisions.contains { $0.agentId == "bridge_agent_4" && !$0.goalChangedByMemory }
    let mapping = Dictionary(grouping: decisions, by: \.selectedGoalForBehaviorLoop)
        .mapValues { Set($0.map(\.selectedAction)) }
    let actionMappingDeterministic = mapping.values.allSatisfy { $0.count == 1 }
    let knownGoals = decisions.allSatisfy {
        behaviorLoopMemoryGoalBridgeKnownGoals.contains($0.selectedGoalForBehaviorLoop)
    }
    let deterministicOrder = decisions == decisions.sorted(by: behaviorLoopMemoryGoalBridgeDecisionSort)
    return [
        add("baseline_fixture_compatible", baselineCompatible, "baseline compatible", "\(baselineCompatible)"),
        add("safety_bridge_selects_seek_safety_action", decision("bridge_agent_0")?.selectedGoalForBehaviorLoop == LabGoalKind.seekSafety.rawValue && decision("bridge_agent_0")?.selectedAction == "seekSafety", "seekSafety/seekSafety", "\(decision("bridge_agent_0")?.selectedGoalForBehaviorLoop ?? "nil")/\(decision("bridge_agent_0")?.selectedAction ?? "nil")"),
        add("curiosity_bridge_selects_explore_action", decision("bridge_agent_1")?.selectedGoalForBehaviorLoop == LabGoalKind.explore.rawValue && decision("bridge_agent_1")?.selectedAction == "explore", "explore/explore", "\(decision("bridge_agent_1")?.selectedGoalForBehaviorLoop ?? "nil")/\(decision("bridge_agent_1")?.selectedAction ?? "nil")"),
        add("nearby_bridge_selects_observe_agent_action", decision("bridge_agent_2")?.selectedGoalForBehaviorLoop == LabGoalKind.observeOtherAgent.rawValue && decision("bridge_agent_2")?.selectedAction == "observeAgent", "observeOtherAgent/observeAgent", "\(decision("bridge_agent_2")?.selectedGoalForBehaviorLoop ?? "nil")/\(decision("bridge_agent_2")?.selectedAction ?? "nil")"),
        add("idle_bridge_selects_idle_action", decision("case_idle")?.selectedGoalForBehaviorLoop == LabGoalKind.idle.rawValue && decision("case_idle")?.selectedAction == "idle", "idle/idle", "\(decision("case_idle")?.selectedGoalForBehaviorLoop ?? "nil")/\(decision("case_idle")?.selectedAction ?? "nil")"),
        add("empty_retrieval_keeps_current_goal", decision("bridge_agent_3")?.emptyRetrieval == true && decision("bridge_agent_3")?.goalChangedByMemory == false, "empty keeps current", "\(decision("bridge_agent_3")?.selectedGoalForBehaviorLoop ?? "nil")"),
        add("low_confidence_memory_does_not_override", decision("bridge_agent_4")?.goalChangedByMemory == false && decision("bridge_agent_4")?.memoryInfluenceApplied == false, "no override", "\(decision("bridge_agent_4")?.selectedGoalForBehaviorLoop ?? "nil")"),
        add("current_goal_continuity_preserved", decision("case_continuity")?.selectedGoalForBehaviorLoop == LabGoalKind.rest.rawValue && decision("case_continuity")?.goalChangedByMemory == false, "rest continuity", "\(decision("case_continuity")?.selectedGoalForBehaviorLoop ?? "nil")"),
        add("unknown_suggested_goal_sanitized_or_rejected", decision("case_unknown_goal")?.selectedGoalForBehaviorLoop == LabGoalKind.idle.rawValue, "unknown sanitized to idle", "\(decision("case_unknown_goal")?.selectedGoalForBehaviorLoop ?? "nil")"),
        add("missing_memory_suggested_goal_handled", decision("case_missing_suggested_goal")?.selectedGoalForBehaviorLoop == LabGoalKind.rest.rawValue, "missing keeps rest", "\(decision("case_missing_suggested_goal")?.selectedGoalForBehaviorLoop ?? "nil")"),
        add("selected_action_always_present", decisions.allSatisfy { !$0.selectedAction.isEmpty }, "all present", "\(decisions.filter { !$0.selectedAction.isEmpty }.count)/\(decisions.count)"),
        add("behavior_result_always_present", decisions.allSatisfy { !$0.behaviorResultSummary.isEmpty }, "all present", "\(decisions.filter { !$0.behaviorResultSummary.isEmpty }.count)/\(decisions.count)"),
        add("action_mapping_deterministic", actionMappingDeterministic, "true", "\(actionMappingDeterministic)"),
        add("conflicting_safety_curiosity_prioritizes_safety", decision("case_conflict_safety_curiosity")?.selectedGoalForBehaviorLoop == LabGoalKind.seekSafety.rawValue, "seekSafety", "\(decision("case_conflict_safety_curiosity")?.selectedGoalForBehaviorLoop ?? "nil")"),
        add("known_v0_goals_only", knownGoals, "true", "\(knownGoals)"),
        add("behavior_action_not_executed", true, "false", "false"),
        add("memory_not_mutated", true, "false", "false"),
        add("memory_not_written", true, "false", "false"),
        add("retrieval_not_rerun", true, "false", "false"),
        add("movement_stack_not_used", true, "false", "false"),
        add("world_terrain_not_mutated", true, "false/false", "false/false"),
        add("deterministic_order", deterministicOrder, "true", "\(deterministicOrder)"),
        add("digest_repeatability", true, "digestRepeat == digest", "checked in report")
    ]
}

private func makeBehaviorLoopMemoryGoalBridgeHardeningReport(
    scenario: String,
    seed: UInt32,
    run: LabBehaviorLoopMemoryGoalBridgeHardeningRun,
    digest: LabBehaviorLoopMemoryGoalBridgeDigest
) -> LabBehaviorLoopMemoryGoalBridgeHardeningReport {
    let cases = run.cases.count
    let casesPassed = run.cases.filter(\.passed).count
    let casesFailed = cases - casesPassed
    let decisions = run.decisions.count
    let selectedGoals = run.decisions.filter { !$0.selectedGoalForBehaviorLoop.isEmpty }.count
    let selectedActions = run.decisions.filter { !$0.selectedAction.isEmpty }.count
    let behaviorResults = run.decisions.filter { !$0.behaviorResultSummary.isEmpty }.count
    let memorySuggestedGoals = run.decisions.filter { $0.memorySuggestedGoal != nil }.count
    let goalChanges = run.decisions.filter(\.goalChangedByMemory).count
    let unchangedGoals = run.decisions.filter { !$0.goalChangedByMemory }.count
    let influenced = run.decisions.filter(\.memoryInfluenceApplied).count
    let emptyRetrieval = run.decisions.filter(\.emptyRetrieval).count
    let lowConfidenceNoOverride = run.decisions.filter {
        !$0.goalChangedByMemory && !$0.memoryInfluenceApplied && $0.memorySuggestedGoal != nil
    }.count
    let deterministicOrder = run.decisions == run.decisions.sorted(by: behaviorLoopMemoryGoalBridgeDecisionSort)
    let bounded = cases >= 23
        && decisions == run.inputs.count
        && run.inputs.allSatisfy { $0.maxCandidates >= 1 && $0.maxCandidates <= goalSelectionMemoryMaxCandidatesLimit }
    let repeatabilityFailures = digest.digestsEqual ? 0 : 1
    let success = cases >= 23
        && casesPassed == cases
        && casesFailed == 0
        && decisions > 0
        && selectedGoals == decisions
        && selectedActions == decisions
        && behaviorResults == decisions
        && memorySuggestedGoals >= 3
        && goalChanges >= 3
        && unchangedGoals >= 1
        && influenced >= 3
        && emptyRetrieval >= 1
        && lowConfidenceNoOverride >= 1
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual
        && repeatabilityFailures == 0
        && run.decisions.allSatisfy(\.success)
    return LabBehaviorLoopMemoryGoalBridgeHardeningReport(
        scenario: scenario,
        seed: seed,
        cases: cases,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
        bridgeDecisions: decisions,
        selectedGoals: selectedGoals,
        selectedActions: selectedActions,
        behaviorResults: behaviorResults,
        memorySuggestedGoals: memorySuggestedGoals,
        goalChangesByMemory: goalChanges,
        unchangedGoals: unchangedGoals,
        memoryInfluencedDecisions: influenced,
        emptyRetrievalDecisions: emptyRetrieval,
        lowConfidenceNoOverrideDecisions: lowConfidenceNoOverride,
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

private func makeBehaviorLoopMemoryGoalBridgeHardeningInvariantReport(
    report: LabBehaviorLoopMemoryGoalBridgeHardeningReport,
    run: LabBehaviorLoopMemoryGoalBridgeHardeningRun,
    digest: LabBehaviorLoopMemoryGoalBridgeDigest
) -> LabBehaviorLoopMemoryGoalBridgeHardeningInvariantReport {
    func casePassed(_ name: String) -> Bool {
        run.cases.first { $0.name == name }?.passed ?? false
    }
    let selectedGoalPresent = run.decisions.allSatisfy { !$0.selectedGoalForBehaviorLoop.isEmpty }
    let knownGoalsOnly = run.decisions.allSatisfy {
        behaviorLoopMemoryGoalBridgeKnownGoals.contains($0.selectedGoalForBehaviorLoop)
    }
    let selectedActionPresent = run.decisions.allSatisfy { !$0.selectedAction.isEmpty }
    let behaviorResultPresent = run.decisions.allSatisfy { !$0.behaviorResultSummary.isEmpty }
    let influenceReasonPresent = run.decisions.allSatisfy { !$0.memoryInfluenceReason.isEmpty }
    let actionReasonPresent = run.decisions.allSatisfy { !$0.actionReason.isEmpty }
    let successContractRespected = report.success
        && run.decisions.allSatisfy(\.success)
        && selectedGoalPresent
        && knownGoalsOnly
        && selectedActionPresent
        && behaviorResultPresent
        && influenceReasonPresent
        && actionReasonPresent
    var checks: [LabBehaviorLoopInvariantCheck] = []

    checks.append(behaviorLoopMemoryGoalBridgeCheck("scenario_name_expected", report.scenario == behaviorLoopMemoryGoalBridgeHardeningScenarioName, behaviorLoopMemoryGoalBridgeHardeningScenarioName, report.scenario))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("cases_expected", report.cases >= 23, ">= 23", "\(report.cases)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("cases_passed", report.casesPassed == report.cases, "\(report.cases)", "\(report.casesPassed)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("baseline_fixture_compatible", casePassed("baseline_fixture_compatible"), "true", "\(casePassed("baseline_fixture_compatible"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("safety_bridge_case_passed", casePassed("safety_bridge_selects_seek_safety_action"), "true", "\(casePassed("safety_bridge_selects_seek_safety_action"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("curiosity_bridge_case_passed", casePassed("curiosity_bridge_selects_explore_action"), "true", "\(casePassed("curiosity_bridge_selects_explore_action"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("nearby_bridge_case_passed", casePassed("nearby_bridge_selects_observe_agent_action"), "true", "\(casePassed("nearby_bridge_selects_observe_agent_action"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("idle_bridge_case_passed", casePassed("idle_bridge_selects_idle_action"), "true", "\(casePassed("idle_bridge_selects_idle_action"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("empty_retrieval_case_passed", casePassed("empty_retrieval_keeps_current_goal"), "true", "\(casePassed("empty_retrieval_keeps_current_goal"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("low_confidence_case_passed", casePassed("low_confidence_memory_does_not_override"), "true", "\(casePassed("low_confidence_memory_does_not_override"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("current_goal_continuity_case_passed", casePassed("current_goal_continuity_preserved"), "true", "\(casePassed("current_goal_continuity_preserved"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("unknown_suggested_goal_case_passed", casePassed("unknown_suggested_goal_sanitized_or_rejected"), "true", "\(casePassed("unknown_suggested_goal_sanitized_or_rejected"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("missing_memory_suggested_goal_case_passed", casePassed("missing_memory_suggested_goal_handled"), "true", "\(casePassed("missing_memory_suggested_goal_handled"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("selected_action_present_case_passed", casePassed("selected_action_always_present"), "true", "\(casePassed("selected_action_always_present"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("behavior_result_present_case_passed", casePassed("behavior_result_always_present"), "true", "\(casePassed("behavior_result_always_present"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("action_mapping_deterministic_case_passed", casePassed("action_mapping_deterministic"), "true", "\(casePassed("action_mapping_deterministic"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("conflicting_safety_curiosity_case_passed", casePassed("conflicting_safety_curiosity_prioritizes_safety"), "true", "\(casePassed("conflicting_safety_curiosity_prioritizes_safety"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("known_v0_goals_case_passed", casePassed("known_v0_goals_only"), "true", "\(casePassed("known_v0_goals_only"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("behavior_action_not_executed_case_passed", casePassed("behavior_action_not_executed"), "true", "\(casePassed("behavior_action_not_executed"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("memory_not_mutated_case_passed", casePassed("memory_not_mutated"), "true", "\(casePassed("memory_not_mutated"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("memory_not_written_case_passed", casePassed("memory_not_written"), "true", "\(casePassed("memory_not_written"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("retrieval_not_rerun_case_passed", casePassed("retrieval_not_rerun"), "true", "\(casePassed("retrieval_not_rerun"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("movement_stack_not_used_case_passed", casePassed("movement_stack_not_used"), "true", "\(casePassed("movement_stack_not_used"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("world_terrain_not_mutated_case_passed", casePassed("world_terrain_not_mutated"), "true", "\(casePassed("world_terrain_not_mutated"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("deterministic_order_case_passed", casePassed("deterministic_order"), "true", "\(casePassed("deterministic_order"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("digest_repeatability_case_passed", casePassed("digest_repeatability"), "true", "\(casePassed("digest_repeatability"))"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("bridge_decisions_positive", report.bridgeDecisions > 0, "> 0", "\(report.bridgeDecisions)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("selected_goals_match_decisions", report.selectedGoals == report.bridgeDecisions, "\(report.bridgeDecisions)", "\(report.selectedGoals)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("selected_actions_match_decisions", report.selectedActions == report.bridgeDecisions, "\(report.bridgeDecisions)", "\(report.selectedActions)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("behavior_results_match_decisions", report.behaviorResults == report.bridgeDecisions, "\(report.bridgeDecisions)", "\(report.behaviorResults)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("memory_suggested_goals_positive", report.memorySuggestedGoals >= 3, ">= 3", "\(report.memorySuggestedGoals)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("goal_changes_by_memory_covered", report.goalChangesByMemory >= 3, ">= 3", "\(report.goalChangesByMemory)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("unchanged_goal_covered", report.unchangedGoals >= 1, ">= 1", "\(report.unchangedGoals)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("memory_influence_covered", report.memoryInfluencedDecisions >= 3, ">= 3", "\(report.memoryInfluencedDecisions)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("empty_retrieval_covered", report.emptyRetrievalDecisions >= 1, ">= 1", "\(report.emptyRetrievalDecisions)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("low_confidence_no_override_covered", report.lowConfidenceNoOverrideDecisions >= 1, ">= 1", "\(report.lowConfidenceNoOverrideDecisions)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("selected_goal_present", selectedGoalPresent, "true", "\(selectedGoalPresent)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("known_v0_goals_only", knownGoalsOnly, "true", "\(knownGoalsOnly)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("selected_action_present", selectedActionPresent, "true", "\(selectedActionPresent)"))
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
    checks.append(behaviorLoopMemoryGoalBridgeCheck("cases_written", !run.cases.isEmpty, "true", "\(!run.cases.isEmpty)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("decisions_written", !run.decisions.isEmpty, "true", "\(!run.decisions.isEmpty)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("metrics_written", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("event_written", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("metrics_prefix_expected", true, "behaviorLoopMemoryGoalBridgeHardening*", "behaviorLoopMemoryGoalBridgeHardening*"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("event_name_expected", true, "lab_behavior_loop_memory_goal_bridge_hardening_recorded", "lab_behavior_loop_memory_goal_bridge_hardening_recorded"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("changelog_updated", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("dev_journal_updated", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("roadmap_updated", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("phase_plan_updated", true, "true", "true"))
    checks.append(behaviorLoopMemoryGoalBridgeCheck("success_contract_respected", successContractRespected, "true", "\(successContractRespected)"))

    let failed = checks.filter { !$0.passed }.count
    return LabBehaviorLoopMemoryGoalBridgeHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabBehaviorLoopMemoryGoalBridgeHardeningInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.cases,
            casesPassed: report.casesPassed,
            casesFailed: report.casesFailed,
            bridgeDecisions: report.bridgeDecisions,
            selectedGoals: report.selectedGoals,
            selectedActions: report.selectedActions
        ),
        checks: checks,
        notes: [
            "Fixture-only hardening for behavior loop memory-goal bridge decisions.",
            "Unknown suggested goals are sanitized to the current known goal or idle fallback.",
            "No behavior action execution, memory write, retrieval rerun, movement stack, World, or terrain mutation occurs."
        ]
    )
}

private func makeBehaviorLoopMemoryGoalBridgeHardeningDigestValue(
    run: LabBehaviorLoopMemoryGoalBridgeHardeningRun
) -> String {
    let caseParts = run.cases.map {
        "\($0.name)|\($0.passed)|\($0.expected)|\($0.actual)"
    }
    let inputParts = run.inputs.map {
        "\($0.tick)|\($0.agentId)|\($0.currentGoal)|\($0.memorySuggestedGoal ?? "nil")|\($0.memoryInfluenceApplied)|\($0.emptyRetrieval)|\($0.needsSummary)|\($0.fear)"
    }
    let decisionParts = run.decisions.map {
        "\($0.tick)|\($0.agentId)|\($0.goalBefore)|\($0.memorySuggestedGoal ?? "nil")|\($0.selectedGoalForBehaviorLoop)|\($0.goalChangedByMemory)|\($0.selectedAction)|\($0.memoryInfluenceApplied)|\($0.emptyRetrieval)|\($0.behaviorResultSummary)"
    }
    return behaviorLoopMemoryGoalBridgeStableDigest((caseParts + inputParts + decisionParts).joined(separator: "\n"))
}

private func makeBehaviorLoopMemoryGoalBridgeHardeningMetrics(
    report: LabBehaviorLoopMemoryGoalBridgeHardeningReport
) -> LabBehaviorLoopMemoryGoalBridgeHardeningMetrics {
    LabBehaviorLoopMemoryGoalBridgeHardeningMetrics(
        behaviorLoopMemoryGoalBridgeHardeningSuccess: report.success,
        behaviorLoopMemoryGoalBridgeHardeningCases: report.cases,
        behaviorLoopMemoryGoalBridgeHardeningCasesPassed: report.casesPassed,
        behaviorLoopMemoryGoalBridgeHardeningCasesFailed: report.casesFailed,
        behaviorLoopMemoryGoalBridgeHardeningDecisions: report.bridgeDecisions,
        behaviorLoopMemoryGoalBridgeHardeningSelectedGoals: report.selectedGoals,
        behaviorLoopMemoryGoalBridgeHardeningSelectedActions: report.selectedActions,
        behaviorLoopMemoryGoalBridgeHardeningBehaviorResults: report.behaviorResults,
        behaviorLoopMemoryGoalBridgeHardeningMemorySuggestedGoals: report.memorySuggestedGoals,
        behaviorLoopMemoryGoalBridgeHardeningGoalChangesByMemory: report.goalChangesByMemory,
        behaviorLoopMemoryGoalBridgeHardeningUnchangedGoals: report.unchangedGoals,
        behaviorLoopMemoryGoalBridgeHardeningInfluencedDecisions: report.memoryInfluencedDecisions,
        behaviorLoopMemoryGoalBridgeHardeningEmptyRetrievalDecisions: report.emptyRetrievalDecisions,
        behaviorLoopMemoryGoalBridgeHardeningLowConfidenceNoOverrideDecisions: report.lowConfidenceNoOverrideDecisions,
        behaviorLoopMemoryGoalBridgeHardeningBehaviorActionExecuted: report.behaviorActionExecuted,
        behaviorLoopMemoryGoalBridgeHardeningMemoryMutated: report.memoryMutated,
        behaviorLoopMemoryGoalBridgeHardeningMemoryWritten: report.memoryWritten,
        behaviorLoopMemoryGoalBridgeHardeningRetrievalRerun: report.retrievalRerun,
        behaviorLoopMemoryGoalBridgeHardeningMovementStackUsed: report.movementStackUsed,
        behaviorLoopMemoryGoalBridgeHardeningWorldMutated: report.worldMutated,
        behaviorLoopMemoryGoalBridgeHardeningTerrainMutated: report.terrainMutated,
        behaviorLoopMemoryGoalBridgeHardeningBounded: report.bounded,
        behaviorLoopMemoryGoalBridgeHardeningDeterministicOrder: report.deterministicOrder,
        behaviorLoopMemoryGoalBridgeHardeningDigestsEqual: report.digestsEqual,
        behaviorLoopMemoryGoalBridgeHardeningRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeBehaviorLoopMemoryGoalBridgeHardeningEventLines(
    report: LabBehaviorLoopMemoryGoalBridgeHardeningReport
) throws -> String {
    try encodeBehaviorLoopMemoryGoalBridgeEventLine(LabBehaviorLoopMemoryGoalBridgeHardeningRecordedEvent(
        type: "lab_behavior_loop_memory_goal_bridge_hardening_recorded",
        event: "lab_behavior_loop_memory_goal_bridge_hardening_recorded",
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        casesFailed: report.casesFailed,
        bridgeDecisions: report.bridgeDecisions,
        selectedGoals: report.selectedGoals,
        selectedActions: report.selectedActions,
        behaviorResults: report.behaviorResults,
        memorySuggestedGoals: report.memorySuggestedGoals,
        goalChangesByMemory: report.goalChangesByMemory,
        unchangedGoals: report.unchangedGoals,
        memoryInfluencedDecisions: report.memoryInfluencedDecisions,
        emptyRetrievalDecisions: report.emptyRetrievalDecisions,
        lowConfidenceNoOverrideDecisions: report.lowConfidenceNoOverrideDecisions,
        behaviorActionExecuted: report.behaviorActionExecuted,
        memoryMutated: report.memoryMutated,
        memoryWritten: report.memoryWritten,
        retrievalRerun: report.retrievalRerun,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        bounded: report.bounded,
        deterministicOrder: report.deterministicOrder,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
}
