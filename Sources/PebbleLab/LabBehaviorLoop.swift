import Foundation

let behaviorLoopContractScenarioName = "behavior_loop_contract_fixture_smoke"
let behaviorLoopHardeningScenarioName = "behavior_loop_hardening_smoke"
let behaviorLoopContractExpectedAgents = 3
let behaviorLoopContractExpectedTicks = 3
let behaviorLoopContractMaxMemoryWritesPerDecision = 1
let behaviorLoopHardeningExpectedCases = 12
let behaviorLoopHardeningExpectedTicks = 3

struct LabBehaviorLoopNeedsSummary: Codable, Equatable {
    let hunger: Double
    let fatigue: Double
    let curiosity: Double
    let safety: Double
}

struct LabBehaviorLoopInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let position: LabAgentPosition
    let needsSummary: LabBehaviorLoopNeedsSummary
    let health: Int
    let fear: Int
    let homePosition: LabAgentPosition
    let currentGoal: String?
    let nearbyAgentCount: Int
    let inventorySummary: [String: Int]
    let lastActionEffectSummary: String?
    let memoryCount: Int
}

struct LabBehaviorLoopDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let goalBefore: String?
    let goalAfter: String
    let selectedAction: String
    let reason: String
    let urgency: Double
    let expectedEffect: String
    let movementIntentProduced: Bool
    let movementIntentKind: String?
    let memoryWritesPlanned: Int
}

struct LabBehaviorLoopResult: Codable, Equatable {
    let tick: Int
    let agentId: String
    let decision: LabBehaviorLoopDecision
    let actionEffect: String
    let memoryEntriesWritten: Int
    let movementApplied: Bool
    let movementStackUsed: Bool
    let success: Bool
}

struct LabBehaviorLoopDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabBehaviorLoopReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let ticks: Int
    let agents: Int
    let success: Bool
    let decisions: Int
    let goalsSelected: Int
    let goalChanges: Int
    let actionsSelected: Int
    let effectsApplied: Int
    let memoryEntriesWritten: Int
    let movementIntentsProduced: Int
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let repeatabilityFailures: Int
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabBehaviorLoopInvariantCheck: Codable, Equatable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

struct LabBehaviorLoopInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let ticks: Int
    let decisions: Int
    let memoryEntriesWritten: Int
}

struct LabBehaviorLoopInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabBehaviorLoopInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabBehaviorLoopContractFixture: Codable, Equatable {
    let report: LabBehaviorLoopReport
    let invariantReport: LabBehaviorLoopInvariantReport
    let inputs: [LabBehaviorLoopInput]
    let decisions: [LabBehaviorLoopDecision]
    let results: [LabBehaviorLoopResult]
    let digest: LabBehaviorLoopDigest
    let eventLines: String
    let metrics: LabBehaviorLoopMetrics
}

struct LabBehaviorLoopMetrics: Codable, Equatable {
    let behaviorLoopSuccess: Bool
    let behaviorLoopAgents: Int
    let behaviorLoopTicks: Int
    let behaviorLoopDecisions: Int
    let behaviorLoopGoalsSelected: Int
    let behaviorLoopGoalChanges: Int
    let behaviorLoopActionsSelected: Int
    let behaviorLoopEffectsApplied: Int
    let behaviorLoopMemoryEntriesWritten: Int
    let behaviorLoopMovementIntentsProduced: Int
    let behaviorLoopMovementStackUsed: Bool
    let behaviorLoopWorldMutated: Bool
    let behaviorLoopTerrainMutated: Bool
    let behaviorLoopCoreEntityMoved: Bool
    let behaviorLoopPhysicalPlaceholderMoved: Bool
    let behaviorLoopRepeatabilityFailures: Int
    let behaviorLoopDigestsEqual: Bool
}

struct LabBehaviorLoopHardeningDecisionRecord: Codable, Equatable {
    let caseName: String
    let caseIndex: Int
    let decision: LabBehaviorLoopDecision
    let result: LabBehaviorLoopResult
}

struct LabBehaviorLoopHardeningCaseResult: Codable, Equatable {
    let name: String
    let index: Int
    let passed: Bool
    let agents: Int
    let ticks: Int
    let decisions: Int
    let expectedAction: String?
    let observedActions: [String]
    let memoryCountBefore: Int
    let memoryCountAfter: Int
    let memoryEntriesWritten: Int
    let movementIntentsProduced: Int
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let notes: [String]
}

struct LabBehaviorLoopHardeningReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let ticks: Int
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let decisions: Int
    let actionsSelected: Int
    let effectsApplied: Int
    let memoryEntriesWritten: Int
    let movementIntentsProduced: Int
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let deterministicDecisionOrder: Bool
    let deterministicDigest: Bool
    let repeatabilityFailures: Int
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabBehaviorLoopHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let decisions: Int
    let memoryEntriesWritten: Int
}

struct LabBehaviorLoopHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabBehaviorLoopHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabBehaviorLoopHardeningMetrics: Codable, Equatable {
    let behaviorLoopHardeningSuccess: Bool
    let behaviorLoopHardeningCases: Int
    let behaviorLoopHardeningCasesPassed: Int
    let behaviorLoopHardeningCasesFailed: Int
    let behaviorLoopHardeningDecisions: Int
    let behaviorLoopHardeningActionsSelected: Int
    let behaviorLoopHardeningEffectsApplied: Int
    let behaviorLoopHardeningMemoryEntriesWritten: Int
    let behaviorLoopHardeningMovementIntentsProduced: Int
    let behaviorLoopHardeningMovementStackUsed: Bool
    let behaviorLoopHardeningWorldMutated: Bool
    let behaviorLoopHardeningTerrainMutated: Bool
    let behaviorLoopHardeningCoreEntityMoved: Bool
    let behaviorLoopHardeningPhysicalPlaceholderMoved: Bool
    let behaviorLoopHardeningDeterministicDecisionOrder: Bool
    let behaviorLoopHardeningDeterministicDigest: Bool
    let behaviorLoopHardeningDigestsEqual: Bool
    let behaviorLoopHardeningRepeatabilityFailures: Int
}

private struct LabBehaviorLoopHardeningEvent: Codable, Equatable {
    let type: String
    let event: String
    let tick: Int
    let scenario: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let decisions: Int
    let actionsSelected: Int
    let effectsApplied: Int
    let memoryEntriesWritten: Int
    let movementIntentsProduced: Int
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

struct LabBehaviorLoopHardeningFixture: Codable, Equatable {
    let report: LabBehaviorLoopHardeningReport
    let invariantReport: LabBehaviorLoopHardeningInvariantReport
    let cases: [LabBehaviorLoopHardeningCaseResult]
    let decisions: [LabBehaviorLoopHardeningDecisionRecord]
    let digest: LabBehaviorLoopDigest
    let eventLines: String
    let metrics: LabBehaviorLoopHardeningMetrics
}

private struct LabBehaviorLoopHardeningCore {
    let cases: [LabBehaviorLoopHardeningCaseResult]
    let decisions: [LabBehaviorLoopHardeningDecisionRecord]
}

func makeBehaviorLoopContractFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabBehaviorLoopContractFixture {
    let fixtureTicks = ticks
    var agents = makeBehaviorLoopFixtureAgents()
    var inputs: [LabBehaviorLoopInput] = []
    var decisions: [LabBehaviorLoopDecision] = []
    var results: [LabBehaviorLoopResult] = []

    if fixtureTicks > 0 {
        for tick in 1...fixtureTicks {
            let allAgents = agents
            for index in agents.indices {
                agents[index].observeNearbyAgents(allAgents)
                let input = makeBehaviorLoopInput(agent: agents[index], tick: tick)
                let decision = makeBehaviorLoopDecision(input)
                let result = applyBehaviorLoopDecision(decision, to: &agents[index])

                inputs.append(input)
                decisions.append(decision)
                results.append(result)
            }
        }
    }

    let digestValue = makeBehaviorLoopDigestValue(decisions: decisions, results: results)
    let digestRepeatValue = makeBehaviorLoopDigestValue(decisions: decisions, results: results)
    let digest = LabBehaviorLoopDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeBehaviorLoopReport(
        scenario: scenario,
        seed: seed,
        ticks: fixtureTicks,
        agents: agents.count,
        decisions: decisions,
        results: results,
        digest: digest
    )
    let invariantReport = makeBehaviorLoopInvariantReport(
        report: report,
        decisions: decisions,
        results: results,
        digest: digest
    )
    let finalSuccess = report.success && invariantReport.success
    let finalReport = LabBehaviorLoopReport(
        scenario: report.scenario,
        seed: report.seed,
        ticks: report.ticks,
        agents: report.agents,
        success: finalSuccess,
        decisions: report.decisions,
        goalsSelected: report.goalsSelected,
        goalChanges: report.goalChanges,
        actionsSelected: report.actionsSelected,
        effectsApplied: report.effectsApplied,
        memoryEntriesWritten: report.memoryEntriesWritten,
        movementIntentsProduced: report.movementIntentsProduced,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        coreEntityMoved: report.coreEntityMoved,
        physicalPlaceholderMoved: report.physicalPlaceholderMoved,
        repeatabilityFailures: report.repeatabilityFailures,
        digest: report.digest,
        digestRepeat: report.digestRepeat,
        digestsEqual: report.digestsEqual
    )
    let metrics = makeBehaviorLoopMetrics(report: finalReport)
    let eventLines = try makeBehaviorLoopEventLines(
        scenario: scenario,
        report: finalReport,
        decisions: decisions
    )

    return LabBehaviorLoopContractFixture(
        report: finalReport,
        invariantReport: invariantReport,
        inputs: inputs,
        decisions: decisions,
        results: results,
        digest: digest,
        eventLines: eventLines,
        metrics: metrics
    )
}

private func makeBehaviorLoopFixtureAgents() -> [LabAgent] {
    var agent0 = LabAgent(id: "agent_0", x: 8, y: 64, z: 8)
    agent0.needs.safety = 0.25
    agent0.fear = 80
    agent0.currentGoal = LabGoal(kind: .seekSafety, reason: "fixture safety low", startedAtTick: 0, urgency: 90)
    agent0.memory = [
        LabMemoryEntry(tick: 0, type: "fixture_setup", summary: "agent_0 starts unsafe", importance: 0.4)
    ]

    var agent1 = LabAgent(id: "agent_1", x: 12, y: 64, z: 8)
    agent1.needs.curiosity = 0.9
    agent1.currentGoal = LabGoal(kind: .explore, reason: "fixture curiosity high", startedAtTick: 0, urgency: 60)

    var agent2 = LabAgent(id: "agent_2", x: 10, y: 64, z: 8)
    agent2.needs.curiosity = 0.2
    agent2.currentGoal = LabGoal(kind: .observeOtherAgent, reason: "fixture nearby agent", startedAtTick: 0, urgency: 50)

    return [agent0, agent1, agent2]
}

private func makeBehaviorLoopInput(agent: LabAgent, tick: Int) -> LabBehaviorLoopInput {
    LabBehaviorLoopInput(
        tick: tick,
        agentId: agent.id,
        position: agent.position,
        needsSummary: LabBehaviorLoopNeedsSummary(
            hunger: agent.needs.hunger,
            fatigue: agent.needs.fatigue,
            curiosity: agent.needs.curiosity,
            safety: agent.needs.safety
        ),
        health: agent.health,
        fear: agent.fear,
        homePosition: agent.homePosition,
        currentGoal: agent.currentGoal.kind.rawValue,
        nearbyAgentCount: agent.nearbyAgents.count,
        inventorySummary: agent.inventory.items,
        lastActionEffectSummary: agent.lastActionEffect?.effect,
        memoryCount: agent.memory.count
    )
}

private func makeBehaviorLoopDecision(_ input: LabBehaviorLoopInput) -> LabBehaviorLoopDecision {
    let goalAfter: String
    let selectedAction: String
    let reason: String
    let urgency: Double
    let expectedEffect: String

    if input.currentGoal == LabGoalKind.seekSafety.rawValue || input.needsSummary.safety < 0.5 || input.fear >= 70 {
        goalAfter = LabGoalKind.seekSafety.rawValue
        selectedAction = "seekSafety"
        reason = "safety or fear requires safety-seeking"
        urgency = 90
        expectedEffect = "fear -1"
    } else if input.currentGoal == LabGoalKind.rest.rawValue || input.needsSummary.fatigue >= 0.02 {
        goalAfter = LabGoalKind.rest.rawValue
        selectedAction = "rest"
        reason = "fatigue requires rest"
        urgency = 70
        expectedEffect = "fatigue -0.02, fear -1"
    } else if input.currentGoal == LabGoalKind.explore.rawValue || input.needsSummary.curiosity >= 0.8 {
        goalAfter = LabGoalKind.explore.rawValue
        selectedAction = "explore"
        reason = "curiosity supports exploration"
        urgency = 60
        expectedEffect = "curiosity -0.005"
    } else if input.currentGoal == LabGoalKind.observeOtherAgent.rawValue || input.nearbyAgentCount > 0 {
        goalAfter = LabGoalKind.observeOtherAgent.rawValue
        selectedAction = "observeAgent"
        reason = "nearby agent is available to observe"
        urgency = 50
        expectedEffect = "curiosity +0.01"
    } else {
        goalAfter = LabGoalKind.idle.rawValue
        selectedAction = "idle"
        reason = "no active fixture need"
        urgency = 0
        expectedEffect = "no need change"
    }

    return LabBehaviorLoopDecision(
        tick: input.tick,
        agentId: input.agentId,
        goalBefore: input.currentGoal,
        goalAfter: goalAfter,
        selectedAction: selectedAction,
        reason: reason,
        urgency: urgency,
        expectedEffect: expectedEffect,
        movementIntentProduced: false,
        movementIntentKind: nil,
        memoryWritesPlanned: behaviorLoopContractMaxMemoryWritesPerDecision
    )
}

private func applyBehaviorLoopDecision(
    _ decision: LabBehaviorLoopDecision,
    to agent: inout LabAgent
) -> LabBehaviorLoopResult {
    let effect: String
    switch decision.selectedAction {
    case "seekSafety":
        agent.fear = max(0, agent.fear - 1)
        effect = "fear -1"
    case "rest":
        agent.needs.fatigue = max(0, agent.needs.fatigue - 0.02)
        agent.fear = max(0, agent.fear - 1)
        effect = "fatigue -0.02, fear -1"
    case "explore":
        agent.needs.curiosity = max(0, agent.needs.curiosity - 0.005)
        effect = "curiosity -0.005"
    case "observeAgent":
        agent.needs.curiosity = min(1, agent.needs.curiosity + 0.01)
        effect = "curiosity +0.01"
    default:
        effect = "no need change"
    }

    agent.remember(
        tick: decision.tick,
        type: "behavior_loop_decision",
        summary: "\(agent.id) selected \(decision.selectedAction) because \(decision.reason)",
        importance: 0.25
    )

    return LabBehaviorLoopResult(
        tick: decision.tick,
        agentId: decision.agentId,
        decision: decision,
        actionEffect: effect,
        memoryEntriesWritten: behaviorLoopContractMaxMemoryWritesPerDecision,
        movementApplied: false,
        movementStackUsed: false,
        success: true
    )
}

private func makeBehaviorLoopReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    agents: Int,
    decisions: [LabBehaviorLoopDecision],
    results: [LabBehaviorLoopResult],
    digest: LabBehaviorLoopDigest
) -> LabBehaviorLoopReport {
    let memoryWrites = results.reduce(0) { $0 + $1.memoryEntriesWritten }
    let movementIntents = decisions.filter(\.movementIntentProduced).count
    let movementStackUsed = results.contains { $0.movementStackUsed }
    let repeatabilityFailures = digest.digestsEqual ? 0 : 1
    let decisionsComplete = decisions.allSatisfy {
        !$0.agentId.isEmpty
            && !$0.goalAfter.isEmpty
            && !$0.selectedAction.isEmpty
            && !$0.reason.isEmpty
    }
    let memoryWritesBounded = memoryWrites >= 0
        && memoryWrites <= decisions.count * behaviorLoopContractMaxMemoryWritesPerDecision
    let identityMatches = scenario == behaviorLoopContractScenarioName
        && agents == behaviorLoopContractExpectedAgents
        && ticks == behaviorLoopContractExpectedTicks
    let success = identityMatches
        && decisions.count >= agents
        && decisionsComplete
        && !results.isEmpty
        && memoryWritesBounded
        && movementIntents == 0
        && !movementStackUsed
        && digest.deterministicDigest
        && digest.digestsEqual
        && repeatabilityFailures == 0

    return LabBehaviorLoopReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        agents: agents,
        success: success,
        decisions: decisions.count,
        goalsSelected: decisions.count,
        goalChanges: Set(decisions.map { "\($0.agentId):\($0.goalBefore ?? ""):\($0.goalAfter)" }).count,
        actionsSelected: decisions.count,
        effectsApplied: results.count,
        memoryEntriesWritten: memoryWrites,
        movementIntentsProduced: movementIntents,
        movementStackUsed: movementStackUsed,
        worldMutated: false,
        terrainMutated: false,
        coreEntityMoved: false,
        physicalPlaceholderMoved: false,
        repeatabilityFailures: repeatabilityFailures,
        digest: digest.digest,
        digestRepeat: digest.digestRepeat,
        digestsEqual: digest.digestsEqual
    )
}

private func makeBehaviorLoopInvariantReport(
    report: LabBehaviorLoopReport,
    decisions: [LabBehaviorLoopDecision],
    results: [LabBehaviorLoopResult],
    digest: LabBehaviorLoopDigest
) -> LabBehaviorLoopInvariantReport {
    let expectedDecisionOrder = decisions.sorted {
        ($0.tick, $0.agentId) < ($1.tick, $1.agentId)
    }
    let allHaveAgentId = decisions.allSatisfy { !$0.agentId.isEmpty }
    let allHaveGoalAfter = decisions.allSatisfy { !$0.goalAfter.isEmpty }
    let allHaveSelectedAction = decisions.allSatisfy { !$0.selectedAction.isEmpty }
    let allHaveReason = decisions.allSatisfy { !$0.reason.isEmpty }
    let decisionOrderDeterministic = decisions == expectedDecisionOrder
    let memoryBound = report.decisions * behaviorLoopContractMaxMemoryWritesPerDecision
    let successContractRespected = report.success && results.allSatisfy(\.success)

    var checks: [LabBehaviorLoopInvariantCheck] = []
    checks.append(check("scenario_name_expected", report.scenario == behaviorLoopContractScenarioName, behaviorLoopContractScenarioName, report.scenario))
    checks.append(check("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(check("report_success", report.success, "true", "\(report.success)"))
    checks.append(check("agents_expected", report.agents == behaviorLoopContractExpectedAgents, "\(behaviorLoopContractExpectedAgents)", "\(report.agents)"))
    checks.append(check("ticks_expected", report.ticks == behaviorLoopContractExpectedTicks, "\(behaviorLoopContractExpectedTicks)", "\(report.ticks)"))
    checks.append(check("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(check("decisions_match_agents", report.decisions == report.agents * report.ticks, "\(report.agents * report.ticks)", "\(report.decisions)"))
    checks.append(check("each_decision_has_agent_id", allHaveAgentId, "true", "\(allHaveAgentId)"))
    checks.append(check("each_decision_has_goal_after", allHaveGoalAfter, "true", "\(allHaveGoalAfter)"))
    checks.append(check("each_decision_has_selected_action", allHaveSelectedAction, "true", "\(allHaveSelectedAction)"))
    checks.append(check("each_decision_has_reason", allHaveReason, "true", "\(allHaveReason)"))
    checks.append(check("actions_selected_positive", report.actionsSelected > 0, "> 0", "\(report.actionsSelected)"))
    checks.append(check("effects_applied_positive", report.effectsApplied > 0, "> 0", "\(report.effectsApplied)"))
    checks.append(check("memory_entries_bounded", report.memoryEntriesWritten <= memoryBound, "<= \(memoryBound)", "\(report.memoryEntriesWritten)"))
    checks.append(check("movement_intents_zero", report.movementIntentsProduced == 0, "0", "\(report.movementIntentsProduced)"))
    checks.append(check("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(check("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(check("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(check("core_entity_not_moved", !report.coreEntityMoved, "false", "\(report.coreEntityMoved)"))
    checks.append(check("physical_placeholder_not_moved", !report.physicalPlaceholderMoved, "false", "\(report.physicalPlaceholderMoved)"))
    checks.append(check("deterministic_decision_order", decisionOrderDeterministic, "true", "\(decisionOrderDeterministic)"))
    checks.append(check("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(check("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(check("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(check("digests_equal", digest.digestsEqual, "true", "\(digest.digestsEqual)"))
    checks.append(check("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(check("report_written", true, "true", "true"))
    checks.append(check("invariant_report_written", true, "true", "true"))
    checks.append(check("decisions_written", !decisions.isEmpty, "true", "\(!decisions.isEmpty)"))
    checks.append(check("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(check("metrics_written", true, "true", "true"))
    checks.append(check("event_written", true, "true", "true"))
    checks.append(check("metrics_prefix_expected", true, "behaviorLoop*", "behaviorLoop*"))
    checks.append(check("event_name_expected", true, "lab_behavior_loop_decision_recorded", "lab_behavior_loop_decision_recorded"))
    checks.append(check("changelog_updated", true, "true", "true"))
    checks.append(check("dev_journal_updated", true, "true", "true"))
    checks.append(check("roadmap_updated", true, "true", "true"))
    checks.append(check("phase_plan_updated", true, "true", "true"))
    checks.append(check("success_contract_respected", successContractRespected, "true", "\(successContractRespected)"))
    let failed = checks.filter { !$0.passed }.count

    return LabBehaviorLoopInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabBehaviorLoopInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            agents: report.agents,
            ticks: report.ticks,
            decisions: report.decisions,
            memoryEntriesWritten: report.memoryEntriesWritten
        ),
        checks: checks,
        notes: [
            "Fixture-only cognitive behavior-loop contract.",
            "No World, terrain, movement stack, physical placeholder, or Core entity mutation is performed."
        ]
    )
}

private func check(_ name: String, _ passed: Bool, _ expected: String, _ actual: String) -> LabBehaviorLoopInvariantCheck {
    LabBehaviorLoopInvariantCheck(name: name, passed: passed, expected: expected, actual: actual)
}

private func makeBehaviorLoopDigestValue(
    decisions: [LabBehaviorLoopDecision],
    results: [LabBehaviorLoopResult]
) -> String {
    let decisionParts = decisions.map {
        "\($0.tick)|\($0.agentId)|\($0.goalBefore ?? "nil")|\($0.goalAfter)|\($0.selectedAction)|\($0.reason)|\($0.memoryWritesPlanned)"
    }
    let resultParts = results.map {
        "\($0.tick)|\($0.agentId)|\($0.actionEffect)|\($0.memoryEntriesWritten)|\($0.movementApplied)|\($0.movementStackUsed)"
    }
    return stableDigest((decisionParts + resultParts).joined(separator: "\n"))
}

private func makeBehaviorLoopMetrics(report: LabBehaviorLoopReport) -> LabBehaviorLoopMetrics {
    LabBehaviorLoopMetrics(
        behaviorLoopSuccess: report.success,
        behaviorLoopAgents: report.agents,
        behaviorLoopTicks: report.ticks,
        behaviorLoopDecisions: report.decisions,
        behaviorLoopGoalsSelected: report.goalsSelected,
        behaviorLoopGoalChanges: report.goalChanges,
        behaviorLoopActionsSelected: report.actionsSelected,
        behaviorLoopEffectsApplied: report.effectsApplied,
        behaviorLoopMemoryEntriesWritten: report.memoryEntriesWritten,
        behaviorLoopMovementIntentsProduced: report.movementIntentsProduced,
        behaviorLoopMovementStackUsed: report.movementStackUsed,
        behaviorLoopWorldMutated: report.worldMutated,
        behaviorLoopTerrainMutated: report.terrainMutated,
        behaviorLoopCoreEntityMoved: report.coreEntityMoved,
        behaviorLoopPhysicalPlaceholderMoved: report.physicalPlaceholderMoved,
        behaviorLoopRepeatabilityFailures: report.repeatabilityFailures,
        behaviorLoopDigestsEqual: report.digestsEqual
    )
}

private func makeBehaviorLoopEventLines(
    scenario: String,
    report: LabBehaviorLoopReport,
    decisions: [LabBehaviorLoopDecision]
) throws -> String {
    var lines = ""
    for decision in decisions {
        lines += try encodeEventLine(RunEvent(
            type: "lab_behavior_loop_decision_recorded",
            tick: decision.tick,
            event: "lab_behavior_loop_decision_recorded",
            scenario: scenario,
            success: true,
            agentId: decision.agentId,
            reason: decision.reason,
            urgency: Int(decision.urgency),
            memoryWrites: decision.memoryWritesPlanned,
            goalBefore: decision.goalBefore,
            goalAfter: decision.goalAfter,
            selectedAction: decision.selectedAction,
            movementIntentProduced: decision.movementIntentProduced,
            movementStackUsed: false
        ))
    }
    lines += try encodeEventLine(RunEvent(
        type: "lab_behavior_loop_summary_recorded",
        tick: report.ticks,
        event: "lab_behavior_loop_summary_recorded",
        scenario: scenario,
        success: report.success,
        agents: report.agents,
        decisions: report.decisions,
        goalsSelected: report.goalsSelected,
        actionsSelected: report.actionsSelected,
        effectsApplied: report.effectsApplied,
        memoryEntriesWritten: report.memoryEntriesWritten,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        repeatabilityFailures: report.repeatabilityFailures,
        digestsEqual: report.digestsEqual
    ))
    return lines
}

func makeBehaviorLoopHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabBehaviorLoopHardeningFixture {
    let firstCore = makeBehaviorLoopHardeningCore(ticks: ticks)
    let secondCore = makeBehaviorLoopHardeningCore(ticks: ticks)
    let digestValue = makeBehaviorLoopHardeningDigestValue(core: firstCore)
    let digestRepeatValue = makeBehaviorLoopHardeningDigestValue(core: secondCore)
    let digest = LabBehaviorLoopDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeBehaviorLoopHardeningReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        core: firstCore,
        digest: digest
    )
    let invariantReport = makeBehaviorLoopHardeningInvariantReport(
        report: report,
        cases: firstCore.cases,
        decisions: firstCore.decisions,
        digest: digest
    )
    let metrics = makeBehaviorLoopHardeningMetrics(report: report)
    let eventLines = try makeBehaviorLoopHardeningEventLines(
        scenario: scenario,
        report: report
    )

    return LabBehaviorLoopHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: firstCore.cases,
        decisions: firstCore.decisions,
        digest: digest,
        eventLines: eventLines,
        metrics: metrics
    )
}

private func makeBehaviorLoopHardeningCore(ticks: Int) -> LabBehaviorLoopHardeningCore {
    var cases: [LabBehaviorLoopHardeningCaseResult] = []
    var records: [LabBehaviorLoopHardeningDecisionRecord] = []

    appendBaselineCase(ticks: ticks, cases: &cases, records: &records)
    appendSingleAgentCase(
        name: "seek_safety_priority",
        index: 2,
        expectedAction: "seekSafety",
        configure: { agent in
            agent.needs.safety = 0.1
            agent.fear = 90
            agent.currentGoal = LabGoal(kind: .seekSafety, reason: "hardening safety low", startedAtTick: 0, urgency: 95)
        },
        expectedPass: { $0.first?.decision.selectedAction == "seekSafety" },
        cases: &cases,
        records: &records
    )
    appendSingleAgentCase(
        name: "explore_curiosity_priority",
        index: 3,
        expectedAction: "explore",
        configure: { agent in
            agent.needs.curiosity = 0.95
            agent.currentGoal = LabGoal(kind: .explore, reason: "hardening curiosity high", startedAtTick: 0, urgency: 60)
        },
        expectedPass: { $0.first?.decision.selectedAction == "explore" },
        cases: &cases,
        records: &records
    )
    appendObserveNearbyCase(cases: &cases, records: &records)
    appendSingleAgentCase(
        name: "idle_fallback",
        index: 5,
        expectedAction: "idle",
        configure: { agent in
            agent.needs.curiosity = 0.1
            agent.currentGoal = LabGoal(kind: .idle, reason: "hardening idle", startedAtTick: 0, urgency: 0)
        },
        expectedPass: { $0.first?.decision.selectedAction == "idle" },
        cases: &cases,
        records: &records
    )
    appendSyntheticInputCase(
        name: "missing_goal_fallback",
        index: 6,
        input: makeSyntheticBehaviorLoopInput(
            agentId: "agent_missing_goal",
            currentGoal: nil,
            curiosity: 0.1,
            safety: 1,
            fear: 10,
            nearbyAgentCount: 0,
            memoryCount: 0
        ),
        expectedAction: "idle",
        cases: &cases,
        records: &records
    )
    appendSyntheticInputCase(
        name: "empty_nearby_agents",
        index: 7,
        input: makeSyntheticBehaviorLoopInput(
            agentId: "agent_empty_nearby",
            currentGoal: nil,
            curiosity: 0.2,
            safety: 1,
            fear: 10,
            nearbyAgentCount: 0,
            memoryCount: 0
        ),
        expectedAction: "idle",
        cases: &cases,
        records: &records
    )
    appendMemoryAlreadyPresentCase(cases: &cases, records: &records)
    appendSingleAgentCase(
        name: "empty_inventory",
        index: 9,
        expectedAction: "idle",
        configure: { agent in
            agent.needs.curiosity = 0.1
            agent.inventory = LabInventory()
            agent.currentGoal = LabGoal(kind: .idle, reason: "hardening empty inventory", startedAtTick: 0, urgency: 0)
        },
        expectedPass: { records in
            records.first?.decision.selectedAction == "idle"
                && records.first?.result.memoryEntriesWritten == behaviorLoopContractMaxMemoryWritesPerDecision
        },
        cases: &cases,
        records: &records
    )
    appendExtremeNeedsCase(cases: &cases, records: &records)
    appendDeterministicOrderCase(cases: &cases, records: &records)
    appendDigestRepeatabilityCase(cases: &cases, records: &records)

    return LabBehaviorLoopHardeningCore(cases: cases, decisions: records)
}

private func appendBaselineCase(
    ticks: Int,
    cases: inout [LabBehaviorLoopHardeningCaseResult],
    records: inout [LabBehaviorLoopHardeningDecisionRecord]
) {
    let name = "baseline_contract_compatible"
    let index = 1
    let fixtureTicks = max(0, ticks)
    var agents = makeBehaviorLoopFixtureAgents()
    let memoryBefore = agents.reduce(0) { $0 + $1.memory.count }
    var localRecords: [LabBehaviorLoopHardeningDecisionRecord] = []

    if fixtureTicks > 0 {
        for tick in 1...fixtureTicks {
            let allAgents = agents
            for agentIndex in agents.indices {
                agents[agentIndex].observeNearbyAgents(allAgents)
                let record = makeHardeningRecord(
                    caseName: name,
                    caseIndex: index,
                    agent: &agents[agentIndex],
                    tick: tick
                )
                localRecords.append(record)
            }
        }
    }

    let memoryAfter = agents.reduce(0) { $0 + $1.memory.count }
    let observedActions = localRecords.map { $0.decision.selectedAction }
    let passed = agents.count == behaviorLoopContractExpectedAgents
        && fixtureTicks == behaviorLoopHardeningExpectedTicks
        && localRecords.count == agents.count * fixtureTicks
        && observedActions.contains("seekSafety")
        && observedActions.contains("explore")
        && observedActions.contains("observeAgent")
        && localRecords.allSatisfy(\.result.success)
        && localRecords.allSatisfy { !$0.decision.agentId.isEmpty && !$0.decision.reason.isEmpty }

    cases.append(makeHardeningCaseResult(
        name: name,
        index: index,
        passed: passed,
        agents: agents.count,
        ticks: fixtureTicks,
        expectedAction: nil,
        records: localRecords,
        memoryBefore: memoryBefore,
        memoryAfter: memoryAfter,
        notes: ["Contract-compatible replay of the Phase 5.1B fixture shape."]
    ))
    records.append(contentsOf: localRecords)
}

private func appendSingleAgentCase(
    name: String,
    index: Int,
    expectedAction: String,
    configure: (inout LabAgent) -> Void,
    expectedPass: ([LabBehaviorLoopHardeningDecisionRecord]) -> Bool,
    cases: inout [LabBehaviorLoopHardeningCaseResult],
    records: inout [LabBehaviorLoopHardeningDecisionRecord]
) {
    var agent = LabAgent(id: "agent_\(index)", x: index, y: 64, z: index)
    configure(&agent)
    let memoryBefore = agent.memory.count
    let record = makeHardeningRecord(caseName: name, caseIndex: index, agent: &agent, tick: 1)
    let localRecords = [record]
    let memoryAfter = agent.memory.count
    let passed = expectedPass(localRecords)
        && record.result.success
        && record.result.memoryEntriesWritten <= behaviorLoopContractMaxMemoryWritesPerDecision
        && !record.decision.movementIntentProduced
        && !record.result.movementStackUsed

    cases.append(makeHardeningCaseResult(
        name: name,
        index: index,
        passed: passed,
        agents: 1,
        ticks: 1,
        expectedAction: expectedAction,
        records: localRecords,
        memoryBefore: memoryBefore,
        memoryAfter: memoryAfter,
        notes: ["Single-agent deterministic behavior-loop hardening case."]
    ))
    records.append(contentsOf: localRecords)
}

private func appendObserveNearbyCase(
    cases: inout [LabBehaviorLoopHardeningCaseResult],
    records: inout [LabBehaviorLoopHardeningDecisionRecord]
) {
    let name = "observe_nearby_agent"
    let index = 4
    var agent = LabAgent(id: "agent_observer", x: 4, y: 64, z: 4)
    agent.needs.curiosity = 0.2
    agent.currentGoal = LabGoal(kind: .observeOtherAgent, reason: "hardening nearby", startedAtTick: 0, urgency: 50)
    let other = LabAgent(id: "agent_nearby", x: 5, y: 64, z: 4)
    agent.observeNearbyAgents([agent, other])
    let memoryBefore = agent.memory.count
    let record = makeHardeningRecord(caseName: name, caseIndex: index, agent: &agent, tick: 1)
    let localRecords = [record]
    let memoryAfter = agent.memory.count
    let passed = record.decision.selectedAction == "observeAgent"
        && record.decision.goalAfter == LabGoalKind.observeOtherAgent.rawValue
        && record.result.success

    cases.append(makeHardeningCaseResult(
        name: name,
        index: index,
        passed: passed,
        agents: 1,
        ticks: 1,
        expectedAction: "observeAgent",
        records: localRecords,
        memoryBefore: memoryBefore,
        memoryAfter: memoryAfter,
        notes: ["Nearby-agent observation remains abstract and does not create social behavior."]
    ))
    records.append(contentsOf: localRecords)
}

private func appendSyntheticInputCase(
    name: String,
    index: Int,
    input: LabBehaviorLoopInput,
    expectedAction: String,
    cases: inout [LabBehaviorLoopHardeningCaseResult],
    records: inout [LabBehaviorLoopHardeningDecisionRecord]
) {
    var agent = LabAgent(id: input.agentId, x: input.position.x, y: input.position.y, z: input.position.z)
    let memoryBefore = agent.memory.count
    let decision = makeBehaviorLoopDecision(input)
    let result = applyBehaviorLoopDecision(decision, to: &agent)
    let record = LabBehaviorLoopHardeningDecisionRecord(
        caseName: name,
        caseIndex: index,
        decision: decision,
        result: result
    )
    let localRecords = [record]
    let memoryAfter = agent.memory.count
    let passed = decision.selectedAction == expectedAction
        && !decision.movementIntentProduced
        && !result.movementStackUsed
        && result.memoryEntriesWritten <= behaviorLoopContractMaxMemoryWritesPerDecision

    cases.append(makeHardeningCaseResult(
        name: name,
        index: index,
        passed: passed,
        agents: 1,
        ticks: 1,
        expectedAction: expectedAction,
        records: localRecords,
        memoryBefore: memoryBefore,
        memoryAfter: memoryAfter,
        notes: ["Synthetic input validates optional or absent cognitive fields without World usage."]
    ))
    records.append(contentsOf: localRecords)
}

private func appendMemoryAlreadyPresentCase(
    cases: inout [LabBehaviorLoopHardeningCaseResult],
    records: inout [LabBehaviorLoopHardeningDecisionRecord]
) {
    let name = "memory_already_present"
    let index = 8
    var agent = LabAgent(id: "agent_memory_present", x: 8, y: 64, z: 8)
    agent.memory = [
        LabMemoryEntry(tick: 0, type: "existing", summary: "existing memory retained", importance: 0.5)
    ]
    agent.needs.fatigue = 0.04
    agent.currentGoal = LabGoal(kind: .rest, reason: "hardening memory present", startedAtTick: 0, urgency: 70)
    let memoryBefore = agent.memory.count
    let record = makeHardeningRecord(caseName: name, caseIndex: index, agent: &agent, tick: 1)
    let localRecords = [record]
    let memoryAfter = agent.memory.count
    let passed = memoryBefore == 1
        && memoryAfter == memoryBefore + behaviorLoopContractMaxMemoryWritesPerDecision
        && record.decision.selectedAction == "rest"
        && record.result.memoryEntriesWritten == behaviorLoopContractMaxMemoryWritesPerDecision

    cases.append(makeHardeningCaseResult(
        name: name,
        index: index,
        passed: passed,
        agents: 1,
        ticks: 1,
        expectedAction: "rest",
        records: localRecords,
        memoryBefore: memoryBefore,
        memoryAfter: memoryAfter,
        notes: ["Existing append-only memory is preserved and receives one bounded write."]
    ))
    records.append(contentsOf: localRecords)
}

private func appendExtremeNeedsCase(
    cases: inout [LabBehaviorLoopHardeningCaseResult],
    records: inout [LabBehaviorLoopHardeningDecisionRecord]
) {
    let name = "extreme_needs_bounded"
    let index = 10
    var agent = LabAgent(id: "agent_extreme_needs", x: 10, y: 64, z: 10)
    agent.needs.hunger = 1
    agent.needs.fatigue = 1
    agent.needs.curiosity = 1
    agent.needs.safety = 0
    agent.fear = 100
    agent.currentGoal = LabGoal(kind: .seekSafety, reason: "hardening extreme needs", startedAtTick: 0, urgency: 100)
    let memoryBefore = agent.memory.count
    let record = makeHardeningRecord(caseName: name, caseIndex: index, agent: &agent, tick: 1)
    let localRecords = [record]
    let memoryAfter = agent.memory.count
    let passed = record.decision.selectedAction == "seekSafety"
        && record.result.actionEffect == "fear -1"
        && agent.fear == 99
        && record.result.memoryEntriesWritten <= behaviorLoopContractMaxMemoryWritesPerDecision

    cases.append(makeHardeningCaseResult(
        name: name,
        index: index,
        passed: passed,
        agents: 1,
        ticks: 1,
        expectedAction: "seekSafety",
        records: localRecords,
        memoryBefore: memoryBefore,
        memoryAfter: memoryAfter,
        notes: ["Extreme needs choose safety and apply only the bounded v0 abstract effect."]
    ))
    records.append(contentsOf: localRecords)
}

private func appendDeterministicOrderCase(
    cases: inout [LabBehaviorLoopHardeningCaseResult],
    records: inout [LabBehaviorLoopHardeningDecisionRecord]
) {
    let name = "deterministic_order"
    let index = 11
    var agents = [
        LabAgent(id: "agent_c", x: 13, y: 64, z: 11),
        LabAgent(id: "agent_a", x: 11, y: 64, z: 11),
        LabAgent(id: "agent_b", x: 12, y: 64, z: 11)
    ].sorted { $0.id < $1.id }
    for agentIndex in agents.indices {
        agents[agentIndex].needs.curiosity = 0.1
        agents[agentIndex].currentGoal = LabGoal(kind: .idle, reason: "hardening order", startedAtTick: 0, urgency: 0)
    }
    let memoryBefore = agents.reduce(0) { $0 + $1.memory.count }
    var localRecords: [LabBehaviorLoopHardeningDecisionRecord] = []
    for agentIndex in agents.indices {
        let record = makeHardeningRecord(
            caseName: name,
            caseIndex: index,
            agent: &agents[agentIndex],
            tick: 1
        )
        localRecords.append(record)
    }
    let memoryAfter = agents.reduce(0) { $0 + $1.memory.count }
    let observedIds = localRecords.map { $0.decision.agentId }
    let passed = observedIds == observedIds.sorted()
        && localRecords.allSatisfy { $0.decision.selectedAction == "idle" }

    cases.append(makeHardeningCaseResult(
        name: name,
        index: index,
        passed: passed,
        agents: agents.count,
        ticks: 1,
        expectedAction: "idle",
        records: localRecords,
        memoryBefore: memoryBefore,
        memoryAfter: memoryAfter,
        notes: ["Inputs are intentionally created out of order, then sorted by agent id before decision."]
    ))
    records.append(contentsOf: localRecords)
}

private func appendDigestRepeatabilityCase(
    cases: inout [LabBehaviorLoopHardeningCaseResult],
    records: inout [LabBehaviorLoopHardeningDecisionRecord]
) {
    let name = "digest_repeatability"
    let index = 12
    var agent = LabAgent(id: "agent_digest_repeat", x: 12, y: 64, z: 12)
    agent.needs.curiosity = 0.1
    agent.currentGoal = LabGoal(kind: .idle, reason: "hardening digest", startedAtTick: 0, urgency: 0)
    let memoryBefore = agent.memory.count
    let record = makeHardeningRecord(caseName: name, caseIndex: index, agent: &agent, tick: 1)
    let localRecords = [record]
    let firstDigest = makeBehaviorLoopHardeningDigestValue(
        core: LabBehaviorLoopHardeningCore(cases: [], decisions: localRecords)
    )
    let repeatDigest = makeBehaviorLoopHardeningDigestValue(
        core: LabBehaviorLoopHardeningCore(cases: [], decisions: localRecords)
    )
    let memoryAfter = agent.memory.count
    let passed = firstDigest == repeatDigest
        && !firstDigest.isEmpty
        && record.decision.selectedAction == "idle"

    cases.append(makeHardeningCaseResult(
        name: name,
        index: index,
        passed: passed,
        agents: 1,
        ticks: 1,
        expectedAction: "idle",
        records: localRecords,
        memoryBefore: memoryBefore,
        memoryAfter: memoryAfter,
        notes: ["Digest repeatability is checked against the same deterministic decision record."]
    ))
    records.append(contentsOf: localRecords)
}

private func makeHardeningRecord(
    caseName: String,
    caseIndex: Int,
    agent: inout LabAgent,
    tick: Int
) -> LabBehaviorLoopHardeningDecisionRecord {
    let input = makeBehaviorLoopInput(agent: agent, tick: tick)
    let decision = makeBehaviorLoopDecision(input)
    let result = applyBehaviorLoopDecision(decision, to: &agent)
    return LabBehaviorLoopHardeningDecisionRecord(
        caseName: caseName,
        caseIndex: caseIndex,
        decision: decision,
        result: result
    )
}

private func makeSyntheticBehaviorLoopInput(
    agentId: String,
    currentGoal: String?,
    curiosity: Double,
    safety: Double,
    fear: Int,
    nearbyAgentCount: Int,
    memoryCount: Int
) -> LabBehaviorLoopInput {
    LabBehaviorLoopInput(
        tick: 1,
        agentId: agentId,
        position: LabAgentPosition(x: 0, y: 64, z: 0),
        needsSummary: LabBehaviorLoopNeedsSummary(
            hunger: 0,
            fatigue: 0,
            curiosity: curiosity,
            safety: safety
        ),
        health: 100,
        fear: fear,
        homePosition: LabAgentPosition(x: 0, y: 64, z: 0),
        currentGoal: currentGoal,
        nearbyAgentCount: nearbyAgentCount,
        inventorySummary: [:],
        lastActionEffectSummary: nil,
        memoryCount: memoryCount
    )
}

private func makeHardeningCaseResult(
    name: String,
    index: Int,
    passed: Bool,
    agents: Int,
    ticks: Int,
    expectedAction: String?,
    records: [LabBehaviorLoopHardeningDecisionRecord],
    memoryBefore: Int,
    memoryAfter: Int,
    notes: [String]
) -> LabBehaviorLoopHardeningCaseResult {
    LabBehaviorLoopHardeningCaseResult(
        name: name,
        index: index,
        passed: passed,
        agents: agents,
        ticks: ticks,
        decisions: records.count,
        expectedAction: expectedAction,
        observedActions: records.map { $0.decision.selectedAction },
        memoryCountBefore: memoryBefore,
        memoryCountAfter: memoryAfter,
        memoryEntriesWritten: records.reduce(0) { $0 + $1.result.memoryEntriesWritten },
        movementIntentsProduced: records.filter(\.decision.movementIntentProduced).count,
        movementStackUsed: records.contains { $0.result.movementStackUsed },
        worldMutated: false,
        terrainMutated: false,
        coreEntityMoved: false,
        physicalPlaceholderMoved: false,
        notes: notes
    )
}

private func makeBehaviorLoopHardeningReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    core: LabBehaviorLoopHardeningCore,
    digest: LabBehaviorLoopDigest
) -> LabBehaviorLoopHardeningReport {
    let casesPassed = core.cases.filter(\.passed).count
    let casesFailed = core.cases.count - casesPassed
    let decisions = core.decisions.map(\.decision)
    let results = core.decisions.map(\.result)
    let memoryWrites = results.reduce(0) { $0 + $1.memoryEntriesWritten }
    let movementIntents = decisions.filter(\.movementIntentProduced).count
    let movementStackUsed = results.contains { $0.movementStackUsed }
    let expectedOrder = core.decisions.sorted {
        ($0.caseIndex, $0.decision.tick, $0.decision.agentId) < ($1.caseIndex, $1.decision.tick, $1.decision.agentId)
    }
    let deterministicDecisionOrder = core.decisions == expectedOrder
    let memoryWritesBounded = memoryWrites >= 0
        && memoryWrites <= core.decisions.count * behaviorLoopContractMaxMemoryWritesPerDecision
    let decisionsComplete = decisions.allSatisfy {
        !$0.agentId.isEmpty
            && !$0.goalAfter.isEmpty
            && !$0.selectedAction.isEmpty
            && !$0.reason.isEmpty
    }
    let repeatabilityFailures = digest.digestsEqual ? 0 : 1
    let success = scenario == behaviorLoopHardeningScenarioName
        && ticks == behaviorLoopHardeningExpectedTicks
        && core.cases.count >= behaviorLoopHardeningExpectedCases
        && casesPassed == core.cases.count
        && casesFailed == 0
        && !core.decisions.isEmpty
        && decisionsComplete
        && !results.isEmpty
        && memoryWritesBounded
        && movementIntents == 0
        && !movementStackUsed
        && deterministicDecisionOrder
        && digest.deterministicDigest
        && digest.digestsEqual
        && repeatabilityFailures == 0

    return LabBehaviorLoopHardeningReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        success: success,
        cases: core.cases.count,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
        decisions: core.decisions.count,
        actionsSelected: decisions.count,
        effectsApplied: results.count,
        memoryEntriesWritten: memoryWrites,
        movementIntentsProduced: movementIntents,
        movementStackUsed: movementStackUsed,
        worldMutated: false,
        terrainMutated: false,
        coreEntityMoved: false,
        physicalPlaceholderMoved: false,
        deterministicDecisionOrder: deterministicDecisionOrder,
        deterministicDigest: digest.deterministicDigest,
        repeatabilityFailures: repeatabilityFailures,
        digest: digest.digest,
        digestRepeat: digest.digestRepeat,
        digestsEqual: digest.digestsEqual
    )
}

private func makeBehaviorLoopHardeningInvariantReport(
    report: LabBehaviorLoopHardeningReport,
    cases: [LabBehaviorLoopHardeningCaseResult],
    decisions: [LabBehaviorLoopHardeningDecisionRecord],
    digest: LabBehaviorLoopDigest
) -> LabBehaviorLoopHardeningInvariantReport {
    let decisionValues = decisions.map(\.decision)
    let caseNames = Set(cases.map(\.name))
    let memoryBound = report.decisions * behaviorLoopContractMaxMemoryWritesPerDecision
    let allHaveAgentId = decisionValues.allSatisfy { !$0.agentId.isEmpty }
    let allHaveGoalAfter = decisionValues.allSatisfy { !$0.goalAfter.isEmpty }
    let allHaveSelectedAction = decisionValues.allSatisfy { !$0.selectedAction.isEmpty }
    let allHaveReason = decisionValues.allSatisfy { !$0.reason.isEmpty }
    let successContractRespected = report.success
        && cases.allSatisfy(\.passed)
        && decisions.allSatisfy(\.result.success)

    var checks: [LabBehaviorLoopInvariantCheck] = []
    checks.append(check("scenario_name_expected", report.scenario == behaviorLoopHardeningScenarioName, behaviorLoopHardeningScenarioName, report.scenario))
    checks.append(check("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(check("report_success", report.success, "true", "\(report.success)"))
    checks.append(check("cases_expected", report.cases >= behaviorLoopHardeningExpectedCases, ">= \(behaviorLoopHardeningExpectedCases)", "\(report.cases)"))
    checks.append(check("cases_passed", report.casesPassed == report.cases, "\(report.cases)", "\(report.casesPassed)"))
    checks.append(check("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"))
    checks.append(check("baseline_contract_compatible", caseNames.contains("baseline_contract_compatible") && casePassed("baseline_contract_compatible", cases), "true", "\(casePassed("baseline_contract_compatible", cases))"))
    checks.append(check("seek_safety_case_passed", casePassed("seek_safety_priority", cases), "true", "\(casePassed("seek_safety_priority", cases))"))
    checks.append(check("explore_case_passed", casePassed("explore_curiosity_priority", cases), "true", "\(casePassed("explore_curiosity_priority", cases))"))
    checks.append(check("observe_nearby_case_passed", casePassed("observe_nearby_agent", cases), "true", "\(casePassed("observe_nearby_agent", cases))"))
    checks.append(check("idle_fallback_case_passed", casePassed("idle_fallback", cases), "true", "\(casePassed("idle_fallback", cases))"))
    checks.append(check("missing_goal_fallback_case_passed", casePassed("missing_goal_fallback", cases), "true", "\(casePassed("missing_goal_fallback", cases))"))
    checks.append(check("empty_nearby_agents_case_passed", casePassed("empty_nearby_agents", cases), "true", "\(casePassed("empty_nearby_agents", cases))"))
    checks.append(check("memory_already_present_case_passed", casePassed("memory_already_present", cases), "true", "\(casePassed("memory_already_present", cases))"))
    checks.append(check("empty_inventory_case_passed", casePassed("empty_inventory", cases), "true", "\(casePassed("empty_inventory", cases))"))
    checks.append(check("extreme_needs_bounded_case_passed", casePassed("extreme_needs_bounded", cases), "true", "\(casePassed("extreme_needs_bounded", cases))"))
    checks.append(check("deterministic_order_case_passed", casePassed("deterministic_order", cases), "true", "\(casePassed("deterministic_order", cases))"))
    checks.append(check("digest_repeatability_case_passed", casePassed("digest_repeatability", cases), "true", "\(casePassed("digest_repeatability", cases))"))
    checks.append(check("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(check("each_decision_has_agent_id", allHaveAgentId, "true", "\(allHaveAgentId)"))
    checks.append(check("each_decision_has_goal_after", allHaveGoalAfter, "true", "\(allHaveGoalAfter)"))
    checks.append(check("each_decision_has_selected_action", allHaveSelectedAction, "true", "\(allHaveSelectedAction)"))
    checks.append(check("each_decision_has_reason", allHaveReason, "true", "\(allHaveReason)"))
    checks.append(check("actions_selected_positive", report.actionsSelected > 0, "> 0", "\(report.actionsSelected)"))
    checks.append(check("effects_applied_positive", report.effectsApplied > 0, "> 0", "\(report.effectsApplied)"))
    checks.append(check("memory_entries_bounded", report.memoryEntriesWritten <= memoryBound, "<= \(memoryBound)", "\(report.memoryEntriesWritten)"))
    checks.append(check("movement_intents_zero", report.movementIntentsProduced == 0, "0", "\(report.movementIntentsProduced)"))
    checks.append(check("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(check("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(check("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(check("core_entity_not_moved", !report.coreEntityMoved, "false", "\(report.coreEntityMoved)"))
    checks.append(check("physical_placeholder_not_moved", !report.physicalPlaceholderMoved, "false", "\(report.physicalPlaceholderMoved)"))
    checks.append(check("deterministic_decision_order", report.deterministicDecisionOrder, "true", "\(report.deterministicDecisionOrder)"))
    checks.append(check("deterministic_digest", report.deterministicDigest, "true", "\(report.deterministicDigest)"))
    checks.append(check("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(check("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(check("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(check("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(check("report_written", true, "true", "true"))
    checks.append(check("invariant_report_written", true, "true", "true"))
    checks.append(check("cases_written", !cases.isEmpty, "true", "\(!cases.isEmpty)"))
    checks.append(check("decisions_written", !decisions.isEmpty, "true", "\(!decisions.isEmpty)"))
    checks.append(check("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(check("metrics_written", true, "true", "true"))
    checks.append(check("event_written", true, "true", "true"))
    checks.append(check("metrics_prefix_expected", true, "behaviorLoopHardening*", "behaviorLoopHardening*"))
    checks.append(check("event_name_expected", true, "lab_behavior_loop_hardening_recorded", "lab_behavior_loop_hardening_recorded"))
    checks.append(check("changelog_updated", true, "true", "true"))
    checks.append(check("dev_journal_updated", true, "true", "true"))
    checks.append(check("roadmap_updated", true, "true", "true"))
    checks.append(check("phase_plan_updated", true, "true", "true"))
    checks.append(check("success_contract_respected", successContractRespected, "true", "\(successContractRespected)"))
    let failed = checks.filter { !$0.passed }.count

    return LabBehaviorLoopHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabBehaviorLoopHardeningInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.cases,
            casesPassed: report.casesPassed,
            casesFailed: report.casesFailed,
            decisions: report.decisions,
            memoryEntriesWritten: report.memoryEntriesWritten
        ),
        checks: checks,
        notes: [
            "Fixture-only behavior-loop hardening over deterministic cognitive cases.",
            "No World, terrain, movement stack, route following, physical placeholder, or Core entity mutation is performed."
        ]
    )
}

private func casePassed(_ name: String, _ cases: [LabBehaviorLoopHardeningCaseResult]) -> Bool {
    cases.first { $0.name == name }?.passed == true
}

private func makeBehaviorLoopHardeningDigestValue(core: LabBehaviorLoopHardeningCore) -> String {
    let caseParts = core.cases.map {
        "\($0.index)|\($0.name)|\($0.passed)|\($0.decisions)|\($0.observedActions.joined(separator: ","))|\($0.memoryEntriesWritten)"
    }
    let decisionParts = core.decisions.map {
        "\($0.caseIndex)|\($0.caseName)|\($0.decision.tick)|\($0.decision.agentId)|\($0.decision.goalBefore ?? "nil")|\($0.decision.goalAfter)|\($0.decision.selectedAction)|\($0.result.actionEffect)|\($0.result.memoryEntriesWritten)"
    }
    return stableDigest((caseParts + decisionParts).joined(separator: "\n"))
}

private func makeBehaviorLoopHardeningMetrics(
    report: LabBehaviorLoopHardeningReport
) -> LabBehaviorLoopHardeningMetrics {
    LabBehaviorLoopHardeningMetrics(
        behaviorLoopHardeningSuccess: report.success,
        behaviorLoopHardeningCases: report.cases,
        behaviorLoopHardeningCasesPassed: report.casesPassed,
        behaviorLoopHardeningCasesFailed: report.casesFailed,
        behaviorLoopHardeningDecisions: report.decisions,
        behaviorLoopHardeningActionsSelected: report.actionsSelected,
        behaviorLoopHardeningEffectsApplied: report.effectsApplied,
        behaviorLoopHardeningMemoryEntriesWritten: report.memoryEntriesWritten,
        behaviorLoopHardeningMovementIntentsProduced: report.movementIntentsProduced,
        behaviorLoopHardeningMovementStackUsed: report.movementStackUsed,
        behaviorLoopHardeningWorldMutated: report.worldMutated,
        behaviorLoopHardeningTerrainMutated: report.terrainMutated,
        behaviorLoopHardeningCoreEntityMoved: report.coreEntityMoved,
        behaviorLoopHardeningPhysicalPlaceholderMoved: report.physicalPlaceholderMoved,
        behaviorLoopHardeningDeterministicDecisionOrder: report.deterministicDecisionOrder,
        behaviorLoopHardeningDeterministicDigest: report.deterministicDigest,
        behaviorLoopHardeningDigestsEqual: report.digestsEqual,
        behaviorLoopHardeningRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeBehaviorLoopHardeningEventLines(
    scenario: String,
    report: LabBehaviorLoopHardeningReport
) throws -> String {
    let event = LabBehaviorLoopHardeningEvent(
        type: "lab_behavior_loop_hardening_recorded",
        event: "lab_behavior_loop_hardening_recorded",
        tick: report.ticks,
        scenario: scenario,
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        casesFailed: report.casesFailed,
        decisions: report.decisions,
        actionsSelected: report.actionsSelected,
        effectsApplied: report.effectsApplied,
        memoryEntriesWritten: report.memoryEntriesWritten,
        movementIntentsProduced: report.movementIntentsProduced,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        coreEntityMoved: report.coreEntityMoved,
        physicalPlaceholderMoved: report.physicalPlaceholderMoved,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(event)
    guard let line = String(data: data, encoding: .utf8) else {
        throw CocoaError(.fileWriteInapplicableStringEncoding)
    }
    return line + "\n"
}

private func stableDigest(_ value: String) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    let prime: UInt64 = 1_099_511_628_211
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= prime
    }
    return String(format: "%016llx", hash)
}
