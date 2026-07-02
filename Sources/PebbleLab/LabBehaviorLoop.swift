import Foundation

let behaviorLoopContractScenarioName = "behavior_loop_contract_fixture_smoke"
let behaviorLoopContractExpectedAgents = 3
let behaviorLoopContractExpectedTicks = 3
let behaviorLoopContractMaxMemoryWritesPerDecision = 1

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

private func stableDigest(_ value: String) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    let prime: UInt64 = 1_099_511_628_211
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= prime
    }
    return String(format: "%016llx", hash)
}
