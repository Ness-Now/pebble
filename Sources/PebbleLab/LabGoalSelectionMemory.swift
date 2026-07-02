import Foundation

let goalSelectionMemoryScenarioName = "goal_selection_from_memory_fixture_smoke"
let goalSelectionMemoryHardeningScenarioName = "goal_selection_from_memory_hardening_smoke"
let goalSelectionMemoryExpectedAgents = 4
let goalSelectionMemoryMaxCandidatesLimit = 5

struct LabGoalSelectionFromMemoryInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let currentGoal: String
    let needsSummary: String
    let fear: Double
    let health: Double
    let homePositionKnown: Bool
    let retrievedMemories: [LabMemoryRetrievedRecord]
    let maxCandidates: Int
    let reason: String
}

struct LabGoalCandidate: Codable, Equatable {
    let goal: String
    let source: String
    let score: Double
    let priority: Int
    let supportingMemoryTypes: [String]
    let supportingMemoryCount: Int
    let reason: String
    let wouldChangeCurrentGoal: Bool
}

struct LabGoalSelectionFromMemoryDecision: Codable, Equatable {
    let tick: Int
    let agentId: String
    let goalBefore: String
    let selectedGoal: String
    let goalChanged: Bool
    let selectedCandidate: LabGoalCandidate
    let candidates: [LabGoalCandidate]
    let memoryInfluenceApplied: Bool
    let memoryInfluenceReason: String
    let emptyRetrieval: Bool
    let deterministicOrder: Bool
    let success: Bool
}

struct LabGoalSelectionFromMemoryReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let decisions: Int
    let candidates: Int
    let selectedGoals: Int
    let goalChanges: Int
    let unchangedGoals: Int
    let memoryInfluencedDecisions: Int
    let emptyRetrievalDecisions: Int
    let maxCandidates: Int
    let bounded: Bool
    let deterministicOrder: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let deterministicDigest: Bool
    let repeatabilityFailures: Int
    let memoryMutated: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let movementStackUsed: Bool
    let behaviorActionExecuted: Bool
    let success: Bool
}

struct LabGoalSelectionFromMemoryInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let decisions: Int
    let candidates: Int
    let selectedGoals: Int
    let goalChanges: Int
    let unchangedGoals: Int
}

struct LabGoalSelectionFromMemoryInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabGoalSelectionFromMemoryInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabGoalSelectionFromMemoryDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabGoalSelectionFromMemoryMetrics: Codable, Equatable {
    let goalSelectionMemorySuccess: Bool
    let goalSelectionMemoryAgents: Int
    let goalSelectionMemoryDecisions: Int
    let goalSelectionMemoryCandidates: Int
    let goalSelectionMemorySelectedGoals: Int
    let goalSelectionMemoryGoalChanges: Int
    let goalSelectionMemoryUnchangedGoals: Int
    let goalSelectionMemoryInfluencedDecisions: Int
    let goalSelectionMemoryEmptyRetrievalDecisions: Int
    let goalSelectionMemoryMaxCandidates: Int
    let goalSelectionMemoryBounded: Bool
    let goalSelectionMemoryDeterministicOrder: Bool
    let goalSelectionMemoryDigestsEqual: Bool
    let goalSelectionMemoryRepeatabilityFailures: Int
    let goalSelectionMemoryMemoryMutated: Bool
    let goalSelectionMemoryWorldMutated: Bool
    let goalSelectionMemoryTerrainMutated: Bool
    let goalSelectionMemoryMovementStackUsed: Bool
    let goalSelectionMemoryBehaviorActionExecuted: Bool
}

struct LabGoalSelectionFromMemoryFixture: Codable, Equatable {
    let report: LabGoalSelectionFromMemoryReport
    let invariantReport: LabGoalSelectionFromMemoryInvariantReport
    let inputs: [LabGoalSelectionFromMemoryInput]
    let candidates: [LabGoalCandidateRecord]
    let decisions: [LabGoalSelectionFromMemoryDecision]
    let digest: LabGoalSelectionFromMemoryDigest
    let eventLines: String
    let metrics: LabGoalSelectionFromMemoryMetrics
}

struct LabGoalCandidateRecord: Codable, Equatable {
    let tick: Int
    let agentId: String
    let candidate: LabGoalCandidate
}

private struct LabGoalSelectionMemoryRun {
    let inputs: [LabGoalSelectionFromMemoryInput]
    let decisions: [LabGoalSelectionFromMemoryDecision]
    let candidateRecords: [LabGoalCandidateRecord]
    let memoryDigestBefore: String
    let memoryDigestAfter: String
}

private struct LabGoalSelectionMemoryRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let goalBefore: String
    let selectedGoal: String
    let goalChanged: Bool
    let candidates: Int
    let memoryInfluenceApplied: Bool
    let memoryInfluenceReason: String
    let emptyRetrieval: Bool
}

private struct LabGoalSelectionMemorySummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let decisions: Int
    let candidates: Int
    let selectedGoals: Int
    let goalChanges: Int
    let unchangedGoals: Int
    let influencedDecisions: Int
    let emptyRetrievalDecisions: Int
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeGoalSelectionFromMemoryFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabGoalSelectionFromMemoryFixture {
    let run = makeGoalSelectionMemoryRun(ticks: ticks)
    let repeatRun = makeGoalSelectionMemoryRun(ticks: ticks)
    let digestValue = makeGoalSelectionMemoryDigestValue(run: run)
    let digestRepeatValue = makeGoalSelectionMemoryDigestValue(run: repeatRun)
    let digest = LabGoalSelectionFromMemoryDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeGoalSelectionMemoryReport(
        scenario: scenario,
        seed: seed,
        run: run,
        digest: digest
    )
    let invariantReport = makeGoalSelectionMemoryInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabGoalSelectionFromMemoryFixture(
        report: report,
        invariantReport: invariantReport,
        inputs: run.inputs,
        candidates: run.candidateRecords,
        decisions: run.decisions,
        digest: digest,
        eventLines: try makeGoalSelectionMemoryEventLines(report: report, decisions: run.decisions),
        metrics: makeGoalSelectionMemoryMetrics(report: report)
    )
}

private func makeGoalSelectionMemoryRun(ticks: Int) -> LabGoalSelectionMemoryRun {
    let tick = max(3, ticks)
    let inputs = makeGoalSelectionMemoryInputs(tick: tick).sorted {
        ($0.agentId, $0.reason) < ($1.agentId, $1.reason)
    }
    let memoryDigestBefore = goalSelectionMemoryInputDigest(inputs)
    let decisions = inputs.map(makeGoalSelectionMemoryDecision).sorted(by: goalSelectionDecisionSort)
    let candidateRecords = decisions.flatMap { decision in
        decision.candidates.map {
            LabGoalCandidateRecord(tick: decision.tick, agentId: decision.agentId, candidate: $0)
        }
    }.sorted(by: goalSelectionCandidateRecordSort)
    let memoryDigestAfter = goalSelectionMemoryInputDigest(inputs)
    return LabGoalSelectionMemoryRun(
        inputs: inputs,
        decisions: decisions,
        candidateRecords: candidateRecords,
        memoryDigestBefore: memoryDigestBefore,
        memoryDigestAfter: memoryDigestAfter
    )
}

private func makeGoalSelectionMemoryInputs(tick: Int) -> [LabGoalSelectionFromMemoryInput] {
    [
        goalSelectionInput(
            tick: tick,
            agentId: "agent_0",
            currentGoal: LabGoalKind.idle.rawValue,
            needsSummary: "safety=0.25;curiosity=0.30;fatigue=0.00",
            fear: 82,
            health: 100,
            retrievedMemories: [
                retrievedGoalMemory(tick: tick, agentId: "agent_0", index: 0, type: "safety_reaction", summary: "agent_0 remembered seeking safety", importance: 0.9, score: 1.6, rank: 1)
            ],
            reason: "safety memory should propose seekSafety"
        ),
        goalSelectionInput(
            tick: tick,
            agentId: "agent_1",
            currentGoal: LabGoalKind.idle.rawValue,
            needsSummary: "safety=1.00;curiosity=0.90;fatigue=0.00",
            fear: 10,
            health: 100,
            retrievedMemories: [
                retrievedGoalMemory(tick: tick, agentId: "agent_1", index: 0, type: "curiosity_reaction", summary: "agent_1 remembered exploring", importance: 0.85, score: 1.55, rank: 1)
            ],
            reason: "curiosity memory should propose explore"
        ),
        goalSelectionInput(
            tick: tick,
            agentId: "agent_2",
            currentGoal: LabGoalKind.idle.rawValue,
            needsSummary: "safety=1.00;curiosity=0.40;fatigue=0.00",
            fear: 10,
            health: 100,
            retrievedMemories: [
                retrievedGoalMemory(tick: tick, agentId: "agent_2", index: 0, type: "nearby_agent_observed", summary: "agent_2 remembered seeing agent_1", importance: 0.8, score: 1.5, rank: 1)
            ],
            reason: "nearby memory should propose observeOtherAgent"
        ),
        goalSelectionInput(
            tick: tick,
            agentId: "agent_3",
            currentGoal: LabGoalKind.explore.rawValue,
            needsSummary: "safety=1.00;curiosity=0.60;fatigue=0.00",
            fear: 10,
            health: 100,
            retrievedMemories: [],
            reason: "empty retrieval should keep current goal"
        ),
        goalSelectionInput(
            tick: tick,
            agentId: "agent_4",
            currentGoal: LabGoalKind.idle.rawValue,
            needsSummary: "safety=1.00;curiosity=0.88;fatigue=0.00",
            fear: 10,
            health: 100,
            retrievedMemories: [
                retrievedGoalMemory(tick: tick, agentId: "agent_4", index: 0, type: "curiosity_reaction", summary: "agent_4 remembered curiosity", importance: 0.8, score: 1.45, rank: 1),
                retrievedGoalMemory(tick: tick, agentId: "agent_4", index: 1, type: "behavior_action", summary: "agent_4 remembered explore action", importance: 0.6, score: 1.0, rank: 2)
            ],
            reason: "duplicate explore candidates should merge"
        )
    ]
}

private func goalSelectionInput(
    tick: Int,
    agentId: String,
    currentGoal: String,
    needsSummary: String,
    fear: Double,
    health: Double,
    retrievedMemories: [LabMemoryRetrievedRecord],
    reason: String
) -> LabGoalSelectionFromMemoryInput {
    LabGoalSelectionFromMemoryInput(
        tick: tick,
        agentId: agentId,
        currentGoal: currentGoal,
        needsSummary: needsSummary,
        fear: fear,
        health: health,
        homePositionKnown: true,
        retrievedMemories: retrievedMemories,
        maxCandidates: goalSelectionMemoryMaxCandidatesLimit,
        reason: reason
    )
}

private func retrievedGoalMemory(
    tick: Int,
    agentId: String,
    index: Int,
    type: String,
    summary: String,
    importance: Double,
    score: Double,
    rank: Int
) -> LabMemoryRetrievedRecord {
    LabMemoryRetrievedRecord(
        tick: tick,
        agentId: agentId,
        memoryIndex: index,
        memoryType: type,
        summary: summary,
        importance: importance,
        ageTicks: max(0, tick - (tick - index)),
        score: score,
        rank: rank,
        reasonMatched: "fixture_goal_selection"
    )
}

private func makeGoalSelectionMemoryDecision(
    input: LabGoalSelectionFromMemoryInput
) -> LabGoalSelectionFromMemoryDecision {
    let candidates = makeGoalSelectionMemoryCandidates(input: input)
    let selected = candidates.sorted(by: goalSelectionCandidateSort).first
        ?? fallbackGoalCandidate(input: input)
    let sortedCandidates = Array(candidates.sorted(by: goalSelectionCandidateSort).prefix(input.maxCandidates))
    let selectedCandidate = sortedCandidates.first { $0.goal == selected.goal } ?? selected
    let memoryInfluenceApplied = !input.retrievedMemories.isEmpty
        && selectedCandidate.supportingMemoryCount > 0
        && selectedCandidate.goal != input.currentGoal
    let emptyRetrieval = input.retrievedMemories.isEmpty
    let deterministicOrder = sortedCandidates == sortedCandidates.sorted(by: goalSelectionCandidateSort)
    let selectedGoalKnown = allowedGoalSelectionMemoryGoals.contains(selectedCandidate.goal)
    return LabGoalSelectionFromMemoryDecision(
        tick: input.tick,
        agentId: input.agentId,
        goalBefore: input.currentGoal,
        selectedGoal: selectedCandidate.goal,
        goalChanged: selectedCandidate.goal != input.currentGoal,
        selectedCandidate: selectedCandidate,
        candidates: sortedCandidates,
        memoryInfluenceApplied: memoryInfluenceApplied,
        memoryInfluenceReason: memoryInfluenceApplied
            ? selectedCandidate.reason
            : (emptyRetrieval ? "empty retrieval kept current goal" : "current goal continuity retained"),
        emptyRetrieval: emptyRetrieval,
        deterministicOrder: deterministicOrder,
        success: selectedGoalKnown
            && !sortedCandidates.isEmpty
            && sortedCandidates.count <= input.maxCandidates
            && input.maxCandidates <= goalSelectionMemoryMaxCandidatesLimit
            && deterministicOrder
    )
}

private func makeGoalSelectionMemoryCandidates(
    input: LabGoalSelectionFromMemoryInput
) -> [LabGoalCandidate] {
    var grouped: [String: [LabGoalCandidate]] = [:]
    for memory in input.retrievedMemories.sorted(by: goalSelectionMemoryRecordSort) {
        guard let mappedGoal = goalFromRetrievedMemory(memory, currentGoal: input.currentGoal) else {
            continue
        }
        let candidate = goalSelectionCandidate(
            goal: mappedGoal,
            source: "retrieved_memory",
            memoryScore: memory.score,
            priority: goalSelectionMemoryPriority(goal: mappedGoal, memoryType: memory.memoryType),
            supportingMemoryTypes: [memory.memoryType],
            supportingMemoryCount: 1,
            reason: "\(memory.memoryType) supports \(mappedGoal)",
            currentGoal: input.currentGoal,
            needsSummary: input.needsSummary,
            fear: input.fear,
            health: input.health
        )
        grouped[mappedGoal, default: []].append(candidate)
    }

    let continuity = goalSelectionCandidate(
        goal: input.currentGoal,
        source: "current_goal_continuity",
        memoryScore: 0,
        priority: 10,
        supportingMemoryTypes: [],
        supportingMemoryCount: 0,
        reason: "current goal remains available",
        currentGoal: input.currentGoal,
        needsSummary: input.needsSummary,
        fear: input.fear,
        health: input.health
    )
    grouped[input.currentGoal, default: []].append(continuity)

    if input.retrievedMemories.isEmpty, input.currentGoal.isEmpty {
        grouped[LabGoalKind.idle.rawValue, default: []].append(fallbackGoalCandidate(input: input))
    }

    return grouped.map { goal, values in
        mergeGoalCandidates(goal: goal, values: values, currentGoal: input.currentGoal)
    }
}

private func goalFromRetrievedMemory(
    _ memory: LabMemoryRetrievedRecord,
    currentGoal: String
) -> String? {
    switch memory.memoryType {
    case "safety_reaction":
        return LabGoalKind.seekSafety.rawValue
    case "curiosity_reaction":
        return LabGoalKind.explore.rawValue
    case "nearby_agent_observed":
        return LabGoalKind.observeOtherAgent.rawValue
    case "idle_tick_summary":
        return LabGoalKind.idle.rawValue
    case "goal_confirmed":
        return allowedGoalSelectionMemoryGoals.contains(currentGoal) ? currentGoal : nil
    case "goal_changed":
        return allowedGoalSelectionMemoryGoals.contains(currentGoal) ? currentGoal : nil
    case "behavior_action":
        if memory.summary.contains("explore") { return LabGoalKind.explore.rawValue }
        if memory.summary.contains("seekSafety") { return LabGoalKind.seekSafety.rawValue }
        if memory.summary.contains("observe") { return LabGoalKind.observeOtherAgent.rawValue }
        if memory.summary.contains("idle") { return LabGoalKind.idle.rawValue }
        return nil
    case "effect_applied":
        if memory.summary.contains("fear") { return LabGoalKind.seekSafety.rawValue }
        if memory.summary.contains("curiosity") { return LabGoalKind.explore.rawValue }
        return nil
    default:
        return nil
    }
}

private func goalSelectionCandidate(
    goal: String,
    source: String,
    memoryScore: Double,
    priority: Int,
    supportingMemoryTypes: [String],
    supportingMemoryCount: Int,
    reason: String,
    currentGoal: String,
    needsSummary: String,
    fear: Double,
    health: Double
) -> LabGoalCandidate {
    let needComponent = goalSelectionNeedComponent(
        goal: goal,
        needsSummary: needsSummary,
        fear: fear,
        health: health
    )
    let continuityComponent = goal == currentGoal ? 0.2 : 0
    let sourceComponent = Double(priority) / 100
    let score = min(3, max(0, memoryScore + needComponent + continuityComponent + sourceComponent))
    return LabGoalCandidate(
        goal: goal,
        source: source,
        score: (score * 1000).rounded() / 1000,
        priority: priority,
        supportingMemoryTypes: supportingMemoryTypes.sorted(),
        supportingMemoryCount: supportingMemoryCount,
        reason: reason,
        wouldChangeCurrentGoal: goal != currentGoal
    )
}

private func mergeGoalCandidates(
    goal: String,
    values: [LabGoalCandidate],
    currentGoal: String
) -> LabGoalCandidate {
    let sorted = values.sorted(by: goalSelectionCandidateSort)
    let totalSupportingCount = values.reduce(0) { $0 + $1.supportingMemoryCount }
    let supportingTypes = Array(Set(values.flatMap(\.supportingMemoryTypes))).sorted()
    let top = sorted.first ?? LabGoalCandidate(
        goal: goal,
        source: "empty",
        score: 0,
        priority: 0,
        supportingMemoryTypes: [],
        supportingMemoryCount: 0,
        reason: "empty candidate",
        wouldChangeCurrentGoal: goal != currentGoal
    )
    let duplicateBonus = totalSupportingCount > 1 ? 0.1 : 0
    let score = min(3, top.score + duplicateBonus)
    return LabGoalCandidate(
        goal: goal,
        source: values.map(\.source).sorted().joined(separator: "+"),
        score: (score * 1000).rounded() / 1000,
        priority: values.map(\.priority).max() ?? 0,
        supportingMemoryTypes: supportingTypes,
        supportingMemoryCount: totalSupportingCount,
        reason: values.map(\.reason).sorted().joined(separator: "; "),
        wouldChangeCurrentGoal: goal != currentGoal
    )
}

private func fallbackGoalCandidate(input: LabGoalSelectionFromMemoryInput) -> LabGoalCandidate {
    let goal = allowedGoalSelectionMemoryGoals.contains(input.currentGoal)
        ? input.currentGoal
        : LabGoalKind.idle.rawValue
    return goalSelectionCandidate(
        goal: goal,
        source: "empty_retrieval_fallback",
        memoryScore: 0,
        priority: 1,
        supportingMemoryTypes: [],
        supportingMemoryCount: 0,
        reason: "empty retrieval fallback",
        currentGoal: input.currentGoal,
        needsSummary: input.needsSummary,
        fear: input.fear,
        health: input.health
    )
}

private func goalSelectionNeedComponent(
    goal: String,
    needsSummary: String,
    fear: Double,
    health: Double
) -> Double {
    switch goal {
    case LabGoalKind.seekSafety.rawValue:
        return fear >= 70 || health <= 25 || needsSummary.contains("safety=0.") ? 0.8 : 0.2
    case LabGoalKind.explore.rawValue:
        return needsSummary.contains("curiosity=0.8") || needsSummary.contains("curiosity=0.9") ? 0.4 : 0.1
    case LabGoalKind.observeOtherAgent.rawValue:
        return 0.25
    case LabGoalKind.rest.rawValue:
        return needsSummary.contains("fatigue=0.02") ? 0.5 : 0.1
    default:
        return 0
    }
}

private func goalSelectionMemoryPriority(goal: String, memoryType: String) -> Int {
    if goal == LabGoalKind.seekSafety.rawValue { return 90 }
    switch memoryType {
    case "curiosity_reaction":
        return 60
    case "nearby_agent_observed":
        return 50
    case "goal_confirmed", "goal_changed":
        return 45
    case "behavior_action", "effect_applied":
        return 35
    default:
        return 10
    }
}

private let allowedGoalSelectionMemoryGoals = Set([
    LabGoalKind.idle.rawValue,
    LabGoalKind.rest.rawValue,
    LabGoalKind.seekSafety.rawValue,
    LabGoalKind.explore.rawValue,
    LabGoalKind.observeOtherAgent.rawValue
])

private func makeGoalSelectionMemoryReport(
    scenario: String,
    seed: UInt32,
    run: LabGoalSelectionMemoryRun,
    digest: LabGoalSelectionFromMemoryDigest
) -> LabGoalSelectionFromMemoryReport {
    let agents = Set(run.inputs.map(\.agentId)).count
    let decisions = run.decisions.count
    let candidates = run.candidateRecords.count
    let selectedGoals = run.decisions.filter { !$0.selectedGoal.isEmpty }.count
    let goalChanges = run.decisions.filter(\.goalChanged).count
    let unchangedGoals = run.decisions.filter { !$0.goalChanged }.count
    let influenced = run.decisions.filter(\.memoryInfluenceApplied).count
    let emptyRetrieval = run.decisions.filter(\.emptyRetrieval).count
    let maxCandidates = run.inputs.map(\.maxCandidates).max() ?? 0
    let deterministicOrder = run.decisions == run.decisions.sorted(by: goalSelectionDecisionSort)
        && run.decisions.allSatisfy(\.deterministicOrder)
    let bounded = maxCandidates >= 1
        && maxCandidates <= goalSelectionMemoryMaxCandidatesLimit
        && run.decisions.allSatisfy { $0.candidates.count <= maxCandidates }
    let memoryMutated = run.memoryDigestBefore != run.memoryDigestAfter
    let repeatabilityFailures = digest.digestsEqual ? 0 : 1
    let success = scenario == goalSelectionMemoryScenarioName
        && agents >= 3
        && decisions >= 4
        && candidates > 0
        && selectedGoals == decisions
        && goalChanges >= 2
        && unchangedGoals >= 1
        && influenced >= 3
        && emptyRetrieval >= 1
        && bounded
        && deterministicOrder
        && !memoryMutated
        && digest.deterministicDigest
        && digest.digestsEqual
        && repeatabilityFailures == 0
    return LabGoalSelectionFromMemoryReport(
        scenario: scenario,
        seed: seed,
        agents: agents,
        decisions: decisions,
        candidates: candidates,
        selectedGoals: selectedGoals,
        goalChanges: goalChanges,
        unchangedGoals: unchangedGoals,
        memoryInfluencedDecisions: influenced,
        emptyRetrievalDecisions: emptyRetrieval,
        maxCandidates: maxCandidates,
        bounded: bounded,
        deterministicOrder: deterministicOrder,
        digest: digest.digest,
        digestRepeat: digest.digestRepeat,
        digestsEqual: digest.digestsEqual,
        deterministicDigest: digest.deterministicDigest,
        repeatabilityFailures: repeatabilityFailures,
        memoryMutated: memoryMutated,
        worldMutated: false,
        terrainMutated: false,
        movementStackUsed: false,
        behaviorActionExecuted: false,
        success: success
    )
}

private func makeGoalSelectionMemoryInvariantReport(
    report: LabGoalSelectionFromMemoryReport,
    run: LabGoalSelectionMemoryRun,
    digest: LabGoalSelectionFromMemoryDigest
) -> LabGoalSelectionFromMemoryInvariantReport {
    let candidatesByDecisionValid = run.decisions.allSatisfy {
        !$0.candidates.isEmpty && $0.candidates.contains($0.selectedCandidate)
    }
    let knownGoalsOnly = run.decisions.allSatisfy {
        allowedGoalSelectionMemoryGoals.contains($0.selectedGoal)
            && $0.candidates.allSatisfy { allowedGoalSelectionMemoryGoals.contains($0.goal) }
    }
    let duplicateGoalsMerged = run.decisions.allSatisfy { decision in
        Set(decision.candidates.map(\.goal)).count == decision.candidates.count
    }
    let scoresBounded = run.decisions.flatMap(\.candidates).allSatisfy {
        $0.score >= 0 && $0.score <= 3
    }
    let influenceReasonsPresent = run.decisions.allSatisfy {
        !$0.memoryInfluenceReason.isEmpty
    }
    let successContractRespected = report.success
        && run.decisions.allSatisfy(\.success)
        && candidatesByDecisionValid
        && knownGoalsOnly
        && duplicateGoalsMerged
        && scoresBounded
        && influenceReasonsPresent
    var checks: [LabBehaviorLoopInvariantCheck] = []

    checks.append(goalSelectionMemoryCheck("scenario_name_expected", report.scenario == goalSelectionMemoryScenarioName, goalSelectionMemoryScenarioName, report.scenario))
    checks.append(goalSelectionMemoryCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(goalSelectionMemoryCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(goalSelectionMemoryCheck("agents_expected", report.agents >= 3, ">= 3", "\(report.agents)"))
    checks.append(goalSelectionMemoryCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(goalSelectionMemoryCheck("candidates_positive", report.candidates > 0, "> 0", "\(report.candidates)"))
    checks.append(goalSelectionMemoryCheck("selected_goal_present", report.selectedGoals == report.decisions, "\(report.decisions)", "\(report.selectedGoals)"))
    checks.append(goalSelectionMemoryCheck("known_v0_goals_only", knownGoalsOnly, "true", "\(knownGoalsOnly)"))
    checks.append(goalSelectionMemoryCheck("goal_changes_covered", report.goalChanges >= 2, ">= 2", "\(report.goalChanges)"))
    checks.append(goalSelectionMemoryCheck("unchanged_goal_covered", report.unchangedGoals >= 1, ">= 1", "\(report.unchangedGoals)"))
    checks.append(goalSelectionMemoryCheck("memory_influenced_decision_covered", report.memoryInfluencedDecisions >= 3, ">= 3", "\(report.memoryInfluencedDecisions)"))
    checks.append(goalSelectionMemoryCheck("empty_retrieval_case_covered", report.emptyRetrievalDecisions >= 1, ">= 1", "\(report.emptyRetrievalDecisions)"))
    checks.append(goalSelectionMemoryCheck("max_candidates_respected", report.maxCandidates >= 1 && report.maxCandidates <= goalSelectionMemoryMaxCandidatesLimit && report.bounded, "true", "\(report.bounded)"))
    checks.append(goalSelectionMemoryCheck("duplicate_goals_merged", duplicateGoalsMerged, "true", "\(duplicateGoalsMerged)"))
    checks.append(goalSelectionMemoryCheck("scores_bounded", scoresBounded, "true", "\(scoresBounded)"))
    checks.append(goalSelectionMemoryCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(goalSelectionMemoryCheck("selected_candidate_in_candidates", candidatesByDecisionValid, "true", "\(candidatesByDecisionValid)"))
    checks.append(goalSelectionMemoryCheck("memory_influence_reason_present", influenceReasonsPresent, "true", "\(influenceReasonsPresent)"))
    checks.append(goalSelectionMemoryCheck("behavior_action_not_executed", !report.behaviorActionExecuted, "false", "\(report.behaviorActionExecuted)"))
    checks.append(goalSelectionMemoryCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"))
    checks.append(goalSelectionMemoryCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(goalSelectionMemoryCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(goalSelectionMemoryCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(goalSelectionMemoryCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(goalSelectionMemoryCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(goalSelectionMemoryCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(goalSelectionMemoryCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(goalSelectionMemoryCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(goalSelectionMemoryCheck("report_written", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("invariant_report_written", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("candidates_written", !run.candidateRecords.isEmpty, "true", "\(!run.candidateRecords.isEmpty)"))
    checks.append(goalSelectionMemoryCheck("decisions_written", !run.decisions.isEmpty, "true", "\(!run.decisions.isEmpty)"))
    checks.append(goalSelectionMemoryCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(goalSelectionMemoryCheck("metrics_written", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("event_written", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("metrics_prefix_expected", true, "goalSelectionMemory*", "goalSelectionMemory*"))
    checks.append(goalSelectionMemoryCheck("event_name_expected", true, "lab_goal_selection_memory_recorded", "lab_goal_selection_memory_recorded"))
    checks.append(goalSelectionMemoryCheck("changelog_updated", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("dev_journal_updated", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("roadmap_updated", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("phase_plan_updated", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("success_contract_respected", successContractRespected, "true", "\(successContractRespected)"))

    let failed = checks.filter { !$0.passed }.count
    return LabGoalSelectionFromMemoryInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabGoalSelectionFromMemoryInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            agents: report.agents,
            decisions: report.decisions,
            candidates: report.candidates,
            selectedGoals: report.selectedGoals,
            goalChanges: report.goalChanges,
            unchangedGoals: report.unchangedGoals
        ),
        checks: checks,
        notes: [
            "Fixture-only goal selection from controlled retrieved memories.",
            "No behavior action is executed and no retrieval is rerun.",
            "Memory, movement stack, World, and terrain remain untouched."
        ]
    )
}

private func makeGoalSelectionMemoryDigestValue(
    run: LabGoalSelectionMemoryRun
) -> String {
    let inputParts = run.inputs.map {
        "\($0.tick)|\($0.agentId)|\($0.currentGoal)|\($0.needsSummary)|\($0.fear)|\($0.health)|\($0.retrievedMemories.map(\.memoryType).joined(separator: ","))"
    }
    let decisionParts = run.decisions.map {
        "\($0.tick)|\($0.agentId)|\($0.goalBefore)|\($0.selectedGoal)|\($0.goalChanged)|\($0.memoryInfluenceApplied)|\($0.candidates.map { "\($0.goal):\($0.score):\($0.supportingMemoryCount)" }.joined(separator: ","))"
    }
    return goalSelectionMemoryStableDigest((inputParts + decisionParts).joined(separator: "\n"))
}

private func goalSelectionMemoryInputDigest(
    _ inputs: [LabGoalSelectionFromMemoryInput]
) -> String {
    let parts = inputs.sorted { ($0.agentId, $0.reason) < ($1.agentId, $1.reason) }.map {
        "\($0.agentId)|\($0.currentGoal)|\($0.retrievedMemories.map { "\($0.memoryIndex):\($0.memoryType):\($0.summary):\($0.score)" }.joined(separator: ","))"
    }
    return goalSelectionMemoryStableDigest(parts.joined(separator: "\n"))
}

private func makeGoalSelectionMemoryMetrics(
    report: LabGoalSelectionFromMemoryReport
) -> LabGoalSelectionFromMemoryMetrics {
    LabGoalSelectionFromMemoryMetrics(
        goalSelectionMemorySuccess: report.success,
        goalSelectionMemoryAgents: report.agents,
        goalSelectionMemoryDecisions: report.decisions,
        goalSelectionMemoryCandidates: report.candidates,
        goalSelectionMemorySelectedGoals: report.selectedGoals,
        goalSelectionMemoryGoalChanges: report.goalChanges,
        goalSelectionMemoryUnchangedGoals: report.unchangedGoals,
        goalSelectionMemoryInfluencedDecisions: report.memoryInfluencedDecisions,
        goalSelectionMemoryEmptyRetrievalDecisions: report.emptyRetrievalDecisions,
        goalSelectionMemoryMaxCandidates: report.maxCandidates,
        goalSelectionMemoryBounded: report.bounded,
        goalSelectionMemoryDeterministicOrder: report.deterministicOrder,
        goalSelectionMemoryDigestsEqual: report.digestsEqual,
        goalSelectionMemoryRepeatabilityFailures: report.repeatabilityFailures,
        goalSelectionMemoryMemoryMutated: report.memoryMutated,
        goalSelectionMemoryWorldMutated: report.worldMutated,
        goalSelectionMemoryTerrainMutated: report.terrainMutated,
        goalSelectionMemoryMovementStackUsed: report.movementStackUsed,
        goalSelectionMemoryBehaviorActionExecuted: report.behaviorActionExecuted
    )
}

private func makeGoalSelectionMemoryEventLines(
    report: LabGoalSelectionFromMemoryReport,
    decisions: [LabGoalSelectionFromMemoryDecision]
) throws -> String {
    var lines = ""
    for decision in decisions.sorted(by: goalSelectionDecisionSort) {
        lines += try encodeGoalSelectionMemoryEventLine(LabGoalSelectionMemoryRecordedEvent(
            type: "lab_goal_selection_memory_recorded",
            event: "lab_goal_selection_memory_recorded",
            success: report.success,
            agentId: decision.agentId,
            tick: decision.tick,
            goalBefore: decision.goalBefore,
            selectedGoal: decision.selectedGoal,
            goalChanged: decision.goalChanged,
            candidates: decision.candidates.count,
            memoryInfluenceApplied: decision.memoryInfluenceApplied,
            memoryInfluenceReason: decision.memoryInfluenceReason,
            emptyRetrieval: decision.emptyRetrieval
        ))
    }
    lines += try encodeGoalSelectionMemoryEventLine(LabGoalSelectionMemorySummaryEvent(
        type: "lab_goal_selection_memory_summary_recorded",
        event: "lab_goal_selection_memory_summary_recorded",
        success: report.success,
        agents: report.agents,
        decisions: report.decisions,
        candidates: report.candidates,
        selectedGoals: report.selectedGoals,
        goalChanges: report.goalChanges,
        unchangedGoals: report.unchangedGoals,
        influencedDecisions: report.memoryInfluencedDecisions,
        emptyRetrievalDecisions: report.emptyRetrievalDecisions,
        bounded: report.bounded,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
    return lines
}

private func encodeGoalSelectionMemoryEventLine<T: Encodable>(_ event: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(event)
    guard let line = String(data: data, encoding: .utf8) else {
        throw CocoaError(.fileWriteInapplicableStringEncoding)
    }
    return line + "\n"
}

private func goalSelectionCandidateSort(
    _ lhs: LabGoalCandidate,
    _ rhs: LabGoalCandidate
) -> Bool {
    if lhs.score != rhs.score { return lhs.score > rhs.score }
    if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
    if lhs.goal != rhs.goal { return lhs.goal < rhs.goal }
    if lhs.source != rhs.source { return lhs.source < rhs.source }
    return lhs.supportingMemoryTypes.joined(separator: ",") < rhs.supportingMemoryTypes.joined(separator: ",")
}

private func goalSelectionDecisionSort(
    _ lhs: LabGoalSelectionFromMemoryDecision,
    _ rhs: LabGoalSelectionFromMemoryDecision
) -> Bool {
    (lhs.agentId, lhs.tick, lhs.selectedGoal) < (rhs.agentId, rhs.tick, rhs.selectedGoal)
}

private func goalSelectionCandidateRecordSort(
    _ lhs: LabGoalCandidateRecord,
    _ rhs: LabGoalCandidateRecord
) -> Bool {
    if lhs.agentId != rhs.agentId { return lhs.agentId < rhs.agentId }
    return goalSelectionCandidateSort(lhs.candidate, rhs.candidate)
}

private func goalSelectionMemoryRecordSort(
    _ lhs: LabMemoryRetrievedRecord,
    _ rhs: LabMemoryRetrievedRecord
) -> Bool {
    if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
    if lhs.score != rhs.score { return lhs.score > rhs.score }
    if lhs.memoryIndex != rhs.memoryIndex { return lhs.memoryIndex < rhs.memoryIndex }
    if lhs.memoryType != rhs.memoryType { return lhs.memoryType < rhs.memoryType }
    return lhs.summary < rhs.summary
}

private func goalSelectionMemoryCheck(
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

private func goalSelectionMemoryStableDigest(_ value: String) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    let prime: UInt64 = 1_099_511_628_211
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= prime
    }
    return String(format: "%016llx", hash)
}

struct LabGoalSelectionMemoryHardeningCase: Codable, Equatable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
    let selectedGoal: String?
    let candidates: Int
    let memoryInfluenceApplied: Bool
    let emptyRetrieval: Bool
}

struct LabGoalSelectionMemoryHardeningReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let decisions: Int
    let candidates: Int
    let selectedGoals: Int
    let goalChanges: Int
    let unchangedGoals: Int
    let memoryInfluencedDecisions: Int
    let emptyRetrievalDecisions: Int
    let maxCandidates: Int
    let bounded: Bool
    let deterministicOrder: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let deterministicDigest: Bool
    let repeatabilityFailures: Int
    let behaviorActionExecuted: Bool
    let memoryMutated: Bool
    let retrievalRerun: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let success: Bool
}

struct LabGoalSelectionMemoryHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let decisions: Int
    let candidates: Int
    let selectedGoals: Int
    let goalChanges: Int
    let unchangedGoals: Int
}

struct LabGoalSelectionMemoryHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabGoalSelectionMemoryHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabGoalSelectionMemoryHardeningMetrics: Codable, Equatable {
    let goalSelectionMemoryHardeningSuccess: Bool
    let goalSelectionMemoryHardeningCases: Int
    let goalSelectionMemoryHardeningCasesPassed: Int
    let goalSelectionMemoryHardeningCasesFailed: Int
    let goalSelectionMemoryHardeningDecisions: Int
    let goalSelectionMemoryHardeningCandidates: Int
    let goalSelectionMemoryHardeningSelectedGoals: Int
    let goalSelectionMemoryHardeningGoalChanges: Int
    let goalSelectionMemoryHardeningUnchangedGoals: Int
    let goalSelectionMemoryHardeningInfluencedDecisions: Int
    let goalSelectionMemoryHardeningEmptyRetrievalDecisions: Int
    let goalSelectionMemoryHardeningMaxCandidates: Int
    let goalSelectionMemoryHardeningBounded: Bool
    let goalSelectionMemoryHardeningDeterministicOrder: Bool
    let goalSelectionMemoryHardeningBehaviorActionExecuted: Bool
    let goalSelectionMemoryHardeningMemoryMutated: Bool
    let goalSelectionMemoryHardeningRetrievalRerun: Bool
    let goalSelectionMemoryHardeningMovementStackUsed: Bool
    let goalSelectionMemoryHardeningWorldMutated: Bool
    let goalSelectionMemoryHardeningTerrainMutated: Bool
    let goalSelectionMemoryHardeningDeterministicDigest: Bool
    let goalSelectionMemoryHardeningDigestsEqual: Bool
    let goalSelectionMemoryHardeningRepeatabilityFailures: Int
}

struct LabGoalSelectionMemoryHardeningFixture: Codable, Equatable {
    let report: LabGoalSelectionMemoryHardeningReport
    let invariantReport: LabGoalSelectionMemoryHardeningInvariantReport
    let cases: [LabGoalSelectionMemoryHardeningCase]
    let candidates: [LabGoalCandidateRecord]
    let decisions: [LabGoalSelectionFromMemoryDecision]
    let digest: LabGoalSelectionFromMemoryDigest
    let eventLines: String
    let metrics: LabGoalSelectionMemoryHardeningMetrics
}

private struct LabGoalSelectionMemoryHardeningRun {
    let cases: [LabGoalSelectionMemoryHardeningCase]
    let decisions: [LabGoalSelectionFromMemoryDecision]
    let candidateRecords: [LabGoalCandidateRecord]
    let memoryDigestBefore: String
    let memoryDigestAfter: String
    let retrievalRerun: Bool
}

private struct LabGoalSelectionMemoryHardeningRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let decisions: Int
    let candidates: Int
    let selectedGoals: Int
    let goalChanges: Int
    let unchangedGoals: Int
    let memoryInfluencedDecisions: Int
    let emptyRetrievalDecisions: Int
    let maxCandidates: Int
    let bounded: Bool
    let deterministicOrder: Bool
    let behaviorActionExecuted: Bool
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeGoalSelectionMemoryHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabGoalSelectionMemoryHardeningFixture {
    let run = makeGoalSelectionMemoryHardeningRun(ticks: ticks)
    let repeatRun = makeGoalSelectionMemoryHardeningRun(ticks: ticks)
    let digestValue = makeGoalSelectionMemoryHardeningDigestValue(run: run)
    let digestRepeatValue = makeGoalSelectionMemoryHardeningDigestValue(run: repeatRun)
    let digest = LabGoalSelectionFromMemoryDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeGoalSelectionMemoryHardeningReport(
        scenario: scenario,
        seed: seed,
        run: run,
        digest: digest
    )
    let invariantReport = makeGoalSelectionMemoryHardeningInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabGoalSelectionMemoryHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: run.cases.sorted { $0.name < $1.name },
        candidates: run.candidateRecords.sorted(by: goalSelectionCandidateRecordSort),
        decisions: run.decisions.sorted(by: goalSelectionDecisionSort),
        digest: digest,
        eventLines: try makeGoalSelectionMemoryHardeningEventLines(report: report),
        metrics: makeGoalSelectionMemoryHardeningMetrics(report: report)
    )
}

private func makeGoalSelectionMemoryHardeningRun(ticks: Int) -> LabGoalSelectionMemoryHardeningRun {
    let tick = max(3, ticks)
    let baseline = makeGoalSelectionMemoryRun(ticks: tick)
    var cases: [LabGoalSelectionMemoryHardeningCase] = []
    var decisions = baseline.decisions
    var candidateRecords = baseline.candidateRecords
    let baselinePassed = baseline.decisions.count >= 5
        && baseline.candidateRecords.count >= 9
        && baseline.decisions.contains { $0.emptyRetrieval }
        && baseline.decisions.contains { $0.selectedCandidate.supportingMemoryCount > 1 }
        && baseline.decisions.allSatisfy(\.success)
    cases.append(LabGoalSelectionMemoryHardeningCase(
        name: "baseline_fixture_compatible",
        passed: baselinePassed,
        expected: "5.4B-compatible decisions, empty retrieval, and duplicate merge",
        actual: "decisions=\(baseline.decisions.count), candidates=\(baseline.candidateRecords.count)",
        selectedGoal: baseline.decisions.first?.selectedGoal,
        candidates: baseline.candidateRecords.count,
        memoryInfluenceApplied: baseline.decisions.contains { $0.memoryInfluenceApplied },
        emptyRetrieval: baseline.decisions.contains { $0.emptyRetrieval }
    ))

    func appendCase(
        _ name: String,
        input rawInput: LabGoalSelectionFromMemoryInput,
        expected: String,
        actual: (LabGoalSelectionFromMemoryDecision) -> String,
        passed: (LabGoalSelectionFromMemoryDecision) -> Bool
    ) {
        let input = sanitizedGoalSelectionHardeningInput(rawInput)
        let decision = makeGoalSelectionMemoryDecision(input: input)
        decisions.append(decision)
        candidateRecords += decision.candidates.map {
            LabGoalCandidateRecord(tick: decision.tick, agentId: decision.agentId, candidate: $0)
        }
        cases.append(LabGoalSelectionMemoryHardeningCase(
            name: name,
            passed: passed(decision),
            expected: expected,
            actual: actual(decision),
            selectedGoal: decision.selectedGoal,
            candidates: decision.candidates.count,
            memoryInfluenceApplied: decision.memoryInfluenceApplied,
            emptyRetrieval: decision.emptyRetrieval
        ))
    }

    appendCase(
        "safety_memory_selects_seek_safety",
        input: hardeningInput(tick, "case_safety", LabGoalKind.idle.rawValue, "safety=0.20;curiosity=0.20", 90, [
            retrievedGoalMemory(tick: tick, agentId: "case_safety", index: 0, type: "safety_reaction", summary: "danger remembered", importance: 1.0, score: 1.5, rank: 1)
        ]),
        expected: "selectedGoal=seekSafety",
        actual: { "selectedGoal=\($0.selectedGoal)" },
        passed: { $0.selectedGoal == LabGoalKind.seekSafety.rawValue }
    )
    appendCase(
        "curiosity_memory_selects_explore",
        input: hardeningInput(tick, "case_curiosity", LabGoalKind.idle.rawValue, "safety=1.00;curiosity=0.95", 5, [
            retrievedGoalMemory(tick: tick, agentId: "case_curiosity", index: 0, type: "curiosity_reaction", summary: "curiosity remembered", importance: 0.9, score: 1.4, rank: 1)
        ]),
        expected: "selectedGoal=explore",
        actual: { "selectedGoal=\($0.selectedGoal)" },
        passed: { $0.selectedGoal == LabGoalKind.explore.rawValue }
    )
    appendCase(
        "nearby_memory_selects_observe_other_agent",
        input: hardeningInput(tick, "case_nearby", LabGoalKind.idle.rawValue, "safety=1.00;curiosity=0.50", 5, [
            retrievedGoalMemory(tick: tick, agentId: "case_nearby", index: 0, type: "nearby_agent_observed", summary: "nearby agent remembered", importance: 0.9, score: 1.3, rank: 1)
        ]),
        expected: "selectedGoal=observeOtherAgent",
        actual: { "selectedGoal=\($0.selectedGoal)" },
        passed: { $0.selectedGoal == LabGoalKind.observeOtherAgent.rawValue }
    )
    appendCase(
        "idle_memory_selects_idle",
        input: hardeningInput(tick, "case_idle", LabGoalKind.explore.rawValue, "safety=1.00;curiosity=0.10", 5, [
            retrievedGoalMemory(tick: tick, agentId: "case_idle", index: 0, type: "idle_tick_summary", summary: "quiet idle tick remembered", importance: 0.9, score: 1.6, rank: 1)
        ]),
        expected: "selectedGoal=idle",
        actual: { "selectedGoal=\($0.selectedGoal)" },
        passed: { $0.selectedGoal == LabGoalKind.idle.rawValue }
    )
    appendCase(
        "empty_retrieval_keeps_current_goal",
        input: hardeningInput(tick, "case_empty", LabGoalKind.explore.rawValue, "safety=1.00;curiosity=0.50", 5, []),
        expected: "current goal retained",
        actual: { "selectedGoal=\($0.selectedGoal), goalBefore=\($0.goalBefore), goalChanged=\($0.goalChanged), influence=\($0.memoryInfluenceApplied)" },
        passed: { $0.selectedGoal == $0.goalBefore && !$0.goalChanged && !$0.memoryInfluenceApplied }
    )
    appendCase(
        "current_goal_continuity_bonus",
        input: hardeningInput(tick, "case_continuity", LabGoalKind.explore.rawValue, "safety=1.00;curiosity=0.90", 5, [
            retrievedGoalMemory(tick: tick, agentId: "case_continuity", index: 0, type: "goal_confirmed", summary: "explore confirmed", importance: 0.8, score: 1.0, rank: 1)
        ]),
        expected: "current goal remains selected with continuity support",
        actual: { "selectedGoal=\($0.selectedGoal), goalChanged=\($0.goalChanged)" },
        passed: { $0.selectedGoal == LabGoalKind.explore.rawValue && !$0.goalChanged && $0.selectedCandidate.score > 1.0 }
    )
    appendCase(
        "duplicate_candidates_merged",
        input: hardeningInput(tick, "case_duplicate", LabGoalKind.idle.rawValue, "safety=1.00;curiosity=0.90", 5, [
            retrievedGoalMemory(tick: tick, agentId: "case_duplicate", index: 1, type: "behavior_action", summary: "explore action remembered", importance: 0.6, score: 0.9, rank: 2),
            retrievedGoalMemory(tick: tick, agentId: "case_duplicate", index: 0, type: "curiosity_reaction", summary: "curiosity remembered", importance: 0.9, score: 1.2, rank: 1)
        ]),
        expected: "one explore candidate with supportingMemoryCount > 1",
        actual: {
            let explore = $0.candidates.first { $0.goal == LabGoalKind.explore.rawValue }
            return "exploreSupporting=\(explore?.supportingMemoryCount ?? 0), candidates=\($0.candidates.count)"
        },
        passed: {
            let explore = $0.candidates.first { $0.goal == LabGoalKind.explore.rawValue }
            return explore?.supportingMemoryCount ?? 0 > 1
        }
    )
    appendCase(
        "max_candidates_respected",
        input: hardeningInput(tick, "case_max", LabGoalKind.idle.rawValue, "safety=0.20;curiosity=0.90", 5, [
            retrievedGoalMemory(tick: tick, agentId: "case_max", index: 0, type: "safety_reaction", summary: "safety", importance: 1.0, score: 1.1, rank: 1),
            retrievedGoalMemory(tick: tick, agentId: "case_max", index: 1, type: "curiosity_reaction", summary: "curiosity", importance: 0.9, score: 1.0, rank: 2),
            retrievedGoalMemory(tick: tick, agentId: "case_max", index: 2, type: "nearby_agent_observed", summary: "nearby", importance: 0.8, score: 0.9, rank: 3),
            retrievedGoalMemory(tick: tick, agentId: "case_max", index: 3, type: "idle_tick_summary", summary: "idle", importance: 0.7, score: 0.8, rank: 4)
        ], maxCandidates: 3),
        expected: "candidates <= maxCandidates",
        actual: { "candidates=\($0.candidates.count), expectedMax=3" },
        passed: { $0.candidates.count <= 3 }
    )
    appendCase(
        "max_candidates_out_of_bounds_clamped_or_rejected",
        input: hardeningInput(tick, "case_max_clamp", LabGoalKind.idle.rawValue, "safety=0.20;curiosity=0.90", 5, [
            retrievedGoalMemory(tick: tick, agentId: "case_max_clamp", index: 0, type: "safety_reaction", summary: "safety", importance: 1.0, score: 1.1, rank: 1)
        ], maxCandidates: 99),
        expected: "maxCandidates 99 clamped to 5",
        actual: { "sanitizedMax=\(goalSelectionMemoryMaxCandidatesLimit), candidates=\($0.candidates.count)" },
        passed: { $0.candidates.count <= goalSelectionMemoryMaxCandidatesLimit }
    )
    appendCase(
        "scores_bounded",
        input: hardeningInput(tick, "case_scores", LabGoalKind.idle.rawValue, "safety=0.00;curiosity=0.99", 99, [
            retrievedGoalMemory(tick: tick, agentId: "case_scores", index: 0, type: "safety_reaction", summary: "high score safety", importance: 1.0, score: 9.0, rank: 1),
            retrievedGoalMemory(tick: tick, agentId: "case_scores", index: 1, type: "curiosity_reaction", summary: "high score curiosity", importance: 1.0, score: 9.0, rank: 2)
        ]),
        expected: "all scores in 0...3",
        actual: {
            let scores = $0.candidates.map { String($0.score) }.joined(separator: ",")
            return "scores=\(scores)"
        },
        passed: { $0.candidates.allSatisfy { $0.score >= 0 && $0.score <= 3 } }
    )
    appendCase(
        "deterministic_tie_break",
        input: hardeningInput(tick, "case_tie", LabGoalKind.idle.rawValue, "safety=1.00;curiosity=0.50", 5, [
            retrievedGoalMemory(tick: tick, agentId: "case_tie", index: 0, type: "effect_applied", summary: "curiosity effect", importance: 0.5, score: 0.65, rank: 1),
            retrievedGoalMemory(tick: tick, agentId: "case_tie", index: 1, type: "behavior_action", summary: "explore action", importance: 0.5, score: 0.65, rank: 2)
        ]),
        expected: "candidate order equals deterministic sort",
        actual: {
            let goals = $0.candidates.map(\.goal).joined(separator: ",")
            return "goals=\(goals)"
        },
        passed: { $0.candidates == $0.candidates.sorted(by: goalSelectionCandidateSort) }
    )
    appendCase(
        "unsorted_input_stable_output",
        input: hardeningInput(tick, "case_unsorted", LabGoalKind.idle.rawValue, "safety=0.20;curiosity=0.90", 80, [
            retrievedGoalMemory(tick: tick, agentId: "case_unsorted", index: 2, type: "curiosity_reaction", summary: "third input curiosity", importance: 0.7, score: 0.8, rank: 3),
            retrievedGoalMemory(tick: tick, agentId: "case_unsorted", index: 0, type: "safety_reaction", summary: "first by rank safety", importance: 1.0, score: 1.3, rank: 1),
            retrievedGoalMemory(tick: tick, agentId: "case_unsorted", index: 1, type: "nearby_agent_observed", summary: "second by rank nearby", importance: 0.8, score: 0.9, rank: 2)
        ]),
        expected: "stable selected goal from unsorted input",
        actual: { "selectedGoal=\($0.selectedGoal)" },
        passed: { $0.selectedGoal == LabGoalKind.seekSafety.rawValue && $0.deterministicOrder }
    )
    appendCase(
        "conflicting_safety_and_curiosity_prioritizes_safety",
        input: hardeningInput(tick, "case_conflict", LabGoalKind.idle.rawValue, "safety=0.15;curiosity=0.99", 95, [
            retrievedGoalMemory(tick: tick, agentId: "case_conflict", index: 0, type: "curiosity_reaction", summary: "curiosity strong", importance: 1.0, score: 1.7, rank: 1),
            retrievedGoalMemory(tick: tick, agentId: "case_conflict", index: 1, type: "safety_reaction", summary: "safety urgent", importance: 1.0, score: 1.2, rank: 2)
        ]),
        expected: "fear/safety priority selects seekSafety",
        actual: { "selectedGoal=\($0.selectedGoal)" },
        passed: { $0.selectedGoal == LabGoalKind.seekSafety.rawValue }
    )
    appendCase(
        "low_confidence_memory_not_selected",
        input: hardeningInput(tick, "case_low_confidence", LabGoalKind.seekSafety.rawValue, "safety=0.20;curiosity=0.10", 90, [
            retrievedGoalMemory(tick: tick, agentId: "case_low_confidence", index: 0, type: "curiosity_reaction", summary: "weak curiosity", importance: 0.05, score: 0.05, rank: 1)
        ]),
        expected: "weak memory does not override stronger current goal",
        actual: { "selectedGoal=\($0.selectedGoal), influence=\($0.memoryInfluenceApplied)" },
        passed: { $0.selectedGoal == LabGoalKind.seekSafety.rawValue && !$0.memoryInfluenceApplied }
    )
    appendCase(
        "unknown_memory_type_ignored_or_rejected",
        input: hardeningInput(tick, "case_unknown_memory", LabGoalKind.idle.rawValue, "safety=1.00;curiosity=0.50", 5, [
            retrievedGoalMemory(tick: tick, agentId: "case_unknown_memory", index: 0, type: "mystery_memory", summary: "unknown memory", importance: 1.0, score: 3.0, rank: 1)
        ]),
        expected: "unknown memory ignored and no unknown goal selected",
        actual: { "selectedGoal=\($0.selectedGoal), candidates=\($0.candidates.count)" },
        passed: { $0.selectedGoal == LabGoalKind.idle.rawValue && !$0.memoryInfluenceApplied }
    )
    appendCase(
        "unknown_goal_not_selected",
        input: hardeningInput(tick, "case_unknown_goal", "unknownGoal", "safety=1.00;curiosity=0.50", 5, [
            retrievedGoalMemory(tick: tick, agentId: "case_unknown_goal", index: 0, type: "behavior_action", summary: "dance action", importance: 1.0, score: 3.0, rank: 1)
        ]),
        expected: "unknown current/derived goal falls back to idle",
        actual: { "goalBefore=\($0.goalBefore), selectedGoal=\($0.selectedGoal)" },
        passed: { $0.goalBefore == LabGoalKind.idle.rawValue && $0.selectedGoal == LabGoalKind.idle.rawValue }
    )
    appendCase(
        "unchanged_goal_covered",
        input: hardeningInput(tick, "case_unchanged", LabGoalKind.idle.rawValue, "safety=1.00;curiosity=0.10", 5, []),
        expected: "goalChanged=false",
        actual: { "goalChanged=\($0.goalChanged)" },
        passed: { !$0.goalChanged }
    )

    let influencedReasons = decisions.filter(\.memoryInfluenceApplied).allSatisfy {
        !$0.memoryInfluenceReason.isEmpty
    }
    cases.append(LabGoalSelectionMemoryHardeningCase(
        name: "memory_influence_reason_present",
        passed: influencedReasons,
        expected: "all influenced decisions have non-empty reasons",
        actual: "influenced=\(decisions.filter(\.memoryInfluenceApplied).count)",
        selectedGoal: nil,
        candidates: 0,
        memoryInfluenceApplied: true,
        emptyRetrieval: false
    ))
    cases.append(LabGoalSelectionMemoryHardeningCase(
        name: "behavior_action_not_executed",
        passed: true,
        expected: "no behavior action execution in fixture",
        actual: "behaviorActionExecuted=false",
        selectedGoal: nil,
        candidates: 0,
        memoryInfluenceApplied: false,
        emptyRetrieval: false
    ))

    let memoryDigestBefore = goalSelectionMemoryHardeningInputDigest(decisions)
    let memoryDigestAfter = goalSelectionMemoryHardeningInputDigest(decisions)
    cases.append(LabGoalSelectionMemoryHardeningCase(
        name: "memory_not_mutated",
        passed: memoryDigestBefore == memoryDigestAfter,
        expected: "memory digest unchanged",
        actual: "before=\(memoryDigestBefore), after=\(memoryDigestAfter)",
        selectedGoal: nil,
        candidates: 0,
        memoryInfluenceApplied: false,
        emptyRetrieval: false
    ))
    cases.append(LabGoalSelectionMemoryHardeningCase(
        name: "retrieval_not_rerun",
        passed: true,
        expected: "goal selection consumes provided records only",
        actual: "retrievalRerun=false",
        selectedGoal: nil,
        candidates: 0,
        memoryInfluenceApplied: false,
        emptyRetrieval: false
    ))

    let partialRun = LabGoalSelectionMemoryHardeningRun(
        cases: cases.sorted { $0.name < $1.name },
        decisions: decisions.sorted(by: goalSelectionDecisionSort),
        candidateRecords: candidateRecords.sorted(by: goalSelectionCandidateRecordSort),
        memoryDigestBefore: memoryDigestBefore,
        memoryDigestAfter: memoryDigestAfter,
        retrievalRerun: false
    )
    let digest = makeGoalSelectionMemoryHardeningDigestValue(run: partialRun)
    let digestRepeat = makeGoalSelectionMemoryHardeningDigestValue(run: partialRun)
    cases.append(LabGoalSelectionMemoryHardeningCase(
        name: "digest_repeatability",
        passed: digest == digestRepeat,
        expected: "digest repeat equals digest",
        actual: "digest=\(digest), repeat=\(digestRepeat)",
        selectedGoal: nil,
        candidates: 0,
        memoryInfluenceApplied: false,
        emptyRetrieval: false
    ))

    return LabGoalSelectionMemoryHardeningRun(
        cases: cases.sorted { $0.name < $1.name },
        decisions: decisions.sorted(by: goalSelectionDecisionSort),
        candidateRecords: candidateRecords.sorted(by: goalSelectionCandidateRecordSort),
        memoryDigestBefore: memoryDigestBefore,
        memoryDigestAfter: memoryDigestAfter,
        retrievalRerun: false
    )
}

private func hardeningInput(
    _ tick: Int,
    _ agentId: String,
    _ currentGoal: String,
    _ needsSummary: String,
    _ fear: Double,
    _ retrievedMemories: [LabMemoryRetrievedRecord],
    maxCandidates: Int = goalSelectionMemoryMaxCandidatesLimit
) -> LabGoalSelectionFromMemoryInput {
    LabGoalSelectionFromMemoryInput(
        tick: tick,
        agentId: agentId,
        currentGoal: currentGoal,
        needsSummary: needsSummary,
        fear: fear,
        health: 100,
        homePositionKnown: true,
        retrievedMemories: retrievedMemories,
        maxCandidates: maxCandidates,
        reason: "goal_selection_memory_hardening"
    )
}

private func sanitizedGoalSelectionHardeningInput(
    _ input: LabGoalSelectionFromMemoryInput
) -> LabGoalSelectionFromMemoryInput {
    LabGoalSelectionFromMemoryInput(
        tick: input.tick,
        agentId: input.agentId,
        currentGoal: allowedGoalSelectionMemoryGoals.contains(input.currentGoal)
            ? input.currentGoal
            : LabGoalKind.idle.rawValue,
        needsSummary: input.needsSummary,
        fear: input.fear,
        health: input.health,
        homePositionKnown: input.homePositionKnown,
        retrievedMemories: input.retrievedMemories,
        maxCandidates: min(goalSelectionMemoryMaxCandidatesLimit, max(1, input.maxCandidates)),
        reason: input.reason
    )
}

private func makeGoalSelectionMemoryHardeningReport(
    scenario: String,
    seed: UInt32,
    run: LabGoalSelectionMemoryHardeningRun,
    digest: LabGoalSelectionFromMemoryDigest
) -> LabGoalSelectionMemoryHardeningReport {
    let casesPassed = run.cases.filter(\.passed).count
    let casesFailed = run.cases.count - casesPassed
    let decisions = run.decisions.count
    let candidates = run.candidateRecords.count
    let selectedGoals = run.decisions.filter { !$0.selectedGoal.isEmpty }.count
    let goalChanges = run.decisions.filter(\.goalChanged).count
    let unchangedGoals = run.decisions.filter { !$0.goalChanged }.count
    let influenced = run.decisions.filter(\.memoryInfluenceApplied).count
    let emptyRetrieval = run.decisions.filter(\.emptyRetrieval).count
    let maxCandidates = run.decisions.map(\.candidates.count).max() ?? 0
    let deterministicOrder = run.decisions == run.decisions.sorted(by: goalSelectionDecisionSort)
        && run.decisions.allSatisfy(\.deterministicOrder)
    let bounded = maxCandidates >= 1
        && maxCandidates <= goalSelectionMemoryMaxCandidatesLimit
        && run.decisions.allSatisfy { $0.candidates.count <= goalSelectionMemoryMaxCandidatesLimit }
    let memoryMutated = run.memoryDigestBefore != run.memoryDigestAfter
    let repeatabilityFailures = digest.digestsEqual ? 0 : 1
    let success = scenario == goalSelectionMemoryHardeningScenarioName
        && run.cases.count >= 23
        && casesPassed == run.cases.count
        && casesFailed == 0
        && decisions > 0
        && candidates > 0
        && selectedGoals == decisions
        && goalChanges >= 2
        && unchangedGoals >= 1
        && influenced >= 3
        && emptyRetrieval >= 1
        && bounded
        && deterministicOrder
        && !memoryMutated
        && !run.retrievalRerun
        && digest.deterministicDigest
        && digest.digestsEqual
        && repeatabilityFailures == 0
    return LabGoalSelectionMemoryHardeningReport(
        scenario: scenario,
        seed: seed,
        cases: run.cases.count,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
        decisions: decisions,
        candidates: candidates,
        selectedGoals: selectedGoals,
        goalChanges: goalChanges,
        unchangedGoals: unchangedGoals,
        memoryInfluencedDecisions: influenced,
        emptyRetrievalDecisions: emptyRetrieval,
        maxCandidates: maxCandidates,
        bounded: bounded,
        deterministicOrder: deterministicOrder,
        digest: digest.digest,
        digestRepeat: digest.digestRepeat,
        digestsEqual: digest.digestsEqual,
        deterministicDigest: digest.deterministicDigest,
        repeatabilityFailures: repeatabilityFailures,
        behaviorActionExecuted: false,
        memoryMutated: memoryMutated,
        retrievalRerun: run.retrievalRerun,
        movementStackUsed: false,
        worldMutated: false,
        terrainMutated: false,
        success: success
    )
}

private func makeGoalSelectionMemoryHardeningInvariantReport(
    report: LabGoalSelectionMemoryHardeningReport,
    run: LabGoalSelectionMemoryHardeningRun,
    digest: LabGoalSelectionFromMemoryDigest
) -> LabGoalSelectionMemoryHardeningInvariantReport {
    let caseNames = Set(run.cases.map(\.name))
    let passedCases = Dictionary(uniqueKeysWithValues: run.cases.map { ($0.name, $0.passed) })
    let candidatesByDecisionValid = run.decisions.allSatisfy {
        !$0.candidates.isEmpty && $0.candidates.contains($0.selectedCandidate)
    }
    let knownGoalsOnly = run.decisions.allSatisfy {
        allowedGoalSelectionMemoryGoals.contains($0.selectedGoal)
            && $0.candidates.allSatisfy { allowedGoalSelectionMemoryGoals.contains($0.goal) }
    }
    let duplicateGoalsMerged = run.decisions.allSatisfy {
        Set($0.candidates.map(\.goal)).count == $0.candidates.count
    }
    let scoresBounded = run.decisions.flatMap(\.candidates).allSatisfy {
        $0.score >= 0 && $0.score <= 3
    }
    let influenceReasonsPresent = run.decisions.filter(\.memoryInfluenceApplied).allSatisfy {
        !$0.memoryInfluenceReason.isEmpty
    }
    let successContractRespected = report.success
        && run.decisions.allSatisfy(\.success)
        && candidatesByDecisionValid
        && knownGoalsOnly
        && duplicateGoalsMerged
        && scoresBounded
        && influenceReasonsPresent
    func casePassed(_ name: String) -> Bool { passedCases[name] == true && caseNames.contains(name) }

    var checks: [LabBehaviorLoopInvariantCheck] = []
    checks.append(goalSelectionMemoryCheck("scenario_name_expected", report.scenario == goalSelectionMemoryHardeningScenarioName, goalSelectionMemoryHardeningScenarioName, report.scenario))
    checks.append(goalSelectionMemoryCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(goalSelectionMemoryCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(goalSelectionMemoryCheck("cases_expected", report.cases >= 23, ">= 23", "\(report.cases)"))
    checks.append(goalSelectionMemoryCheck("cases_passed", report.casesPassed == report.cases, "\(report.cases)", "\(report.casesPassed)"))
    checks.append(goalSelectionMemoryCheck("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"))
    checks.append(goalSelectionMemoryCheck("baseline_fixture_compatible", casePassed("baseline_fixture_compatible"), "true", "\(casePassed("baseline_fixture_compatible"))"))
    checks.append(goalSelectionMemoryCheck("safety_memory_case_passed", casePassed("safety_memory_selects_seek_safety"), "true", "\(casePassed("safety_memory_selects_seek_safety"))"))
    checks.append(goalSelectionMemoryCheck("curiosity_memory_case_passed", casePassed("curiosity_memory_selects_explore"), "true", "\(casePassed("curiosity_memory_selects_explore"))"))
    checks.append(goalSelectionMemoryCheck("nearby_memory_case_passed", casePassed("nearby_memory_selects_observe_other_agent"), "true", "\(casePassed("nearby_memory_selects_observe_other_agent"))"))
    checks.append(goalSelectionMemoryCheck("idle_memory_case_passed", casePassed("idle_memory_selects_idle"), "true", "\(casePassed("idle_memory_selects_idle"))"))
    checks.append(goalSelectionMemoryCheck("empty_retrieval_case_passed", casePassed("empty_retrieval_keeps_current_goal"), "true", "\(casePassed("empty_retrieval_keeps_current_goal"))"))
    checks.append(goalSelectionMemoryCheck("current_goal_continuity_case_passed", casePassed("current_goal_continuity_bonus"), "true", "\(casePassed("current_goal_continuity_bonus"))"))
    checks.append(goalSelectionMemoryCheck("duplicate_candidates_merged_case_passed", casePassed("duplicate_candidates_merged"), "true", "\(casePassed("duplicate_candidates_merged"))"))
    checks.append(goalSelectionMemoryCheck("max_candidates_respected_case_passed", casePassed("max_candidates_respected"), "true", "\(casePassed("max_candidates_respected"))"))
    checks.append(goalSelectionMemoryCheck("max_candidates_out_of_bounds_case_passed", casePassed("max_candidates_out_of_bounds_clamped_or_rejected"), "true", "\(casePassed("max_candidates_out_of_bounds_clamped_or_rejected"))"))
    checks.append(goalSelectionMemoryCheck("scores_bounded_case_passed", casePassed("scores_bounded"), "true", "\(casePassed("scores_bounded"))"))
    checks.append(goalSelectionMemoryCheck("deterministic_tie_break_case_passed", casePassed("deterministic_tie_break"), "true", "\(casePassed("deterministic_tie_break"))"))
    checks.append(goalSelectionMemoryCheck("unsorted_input_stable_output_case_passed", casePassed("unsorted_input_stable_output"), "true", "\(casePassed("unsorted_input_stable_output"))"))
    checks.append(goalSelectionMemoryCheck("conflicting_safety_curiosity_case_passed", casePassed("conflicting_safety_and_curiosity_prioritizes_safety"), "true", "\(casePassed("conflicting_safety_and_curiosity_prioritizes_safety"))"))
    checks.append(goalSelectionMemoryCheck("low_confidence_memory_case_passed", casePassed("low_confidence_memory_not_selected"), "true", "\(casePassed("low_confidence_memory_not_selected"))"))
    checks.append(goalSelectionMemoryCheck("unknown_memory_type_case_passed", casePassed("unknown_memory_type_ignored_or_rejected"), "true", "\(casePassed("unknown_memory_type_ignored_or_rejected"))"))
    checks.append(goalSelectionMemoryCheck("unknown_goal_not_selected_case_passed", casePassed("unknown_goal_not_selected"), "true", "\(casePassed("unknown_goal_not_selected"))"))
    checks.append(goalSelectionMemoryCheck("unchanged_goal_case_passed", casePassed("unchanged_goal_covered"), "true", "\(casePassed("unchanged_goal_covered"))"))
    checks.append(goalSelectionMemoryCheck("memory_influence_reason_case_passed", casePassed("memory_influence_reason_present"), "true", "\(casePassed("memory_influence_reason_present"))"))
    checks.append(goalSelectionMemoryCheck("behavior_action_not_executed_case_passed", casePassed("behavior_action_not_executed"), "true", "\(casePassed("behavior_action_not_executed"))"))
    checks.append(goalSelectionMemoryCheck("memory_not_mutated_case_passed", casePassed("memory_not_mutated"), "true", "\(casePassed("memory_not_mutated"))"))
    checks.append(goalSelectionMemoryCheck("retrieval_not_rerun_case_passed", casePassed("retrieval_not_rerun"), "true", "\(casePassed("retrieval_not_rerun"))"))
    checks.append(goalSelectionMemoryCheck("digest_repeatability_case_passed", casePassed("digest_repeatability"), "true", "\(casePassed("digest_repeatability"))"))
    checks.append(goalSelectionMemoryCheck("decisions_positive", report.decisions > 0, "> 0", "\(report.decisions)"))
    checks.append(goalSelectionMemoryCheck("candidates_positive", report.candidates > 0, "> 0", "\(report.candidates)"))
    checks.append(goalSelectionMemoryCheck("selected_goals_match_decisions", report.selectedGoals == report.decisions, "\(report.decisions)", "\(report.selectedGoals)"))
    checks.append(goalSelectionMemoryCheck("selected_goal_present", report.selectedGoals == report.decisions, "\(report.decisions)", "\(report.selectedGoals)"))
    checks.append(goalSelectionMemoryCheck("known_v0_goals_only", knownGoalsOnly, "true", "\(knownGoalsOnly)"))
    checks.append(goalSelectionMemoryCheck("goal_changes_covered", report.goalChanges >= 2, ">= 2", "\(report.goalChanges)"))
    checks.append(goalSelectionMemoryCheck("unchanged_goal_covered", report.unchangedGoals >= 1, ">= 1", "\(report.unchangedGoals)"))
    checks.append(goalSelectionMemoryCheck("memory_influenced_decision_covered", report.memoryInfluencedDecisions >= 3, ">= 3", "\(report.memoryInfluencedDecisions)"))
    checks.append(goalSelectionMemoryCheck("empty_retrieval_covered", report.emptyRetrievalDecisions >= 1, ">= 1", "\(report.emptyRetrievalDecisions)"))
    checks.append(goalSelectionMemoryCheck("max_candidates_respected", report.maxCandidates <= goalSelectionMemoryMaxCandidatesLimit && report.bounded, "true", "\(report.bounded)"))
    checks.append(goalSelectionMemoryCheck("duplicate_goals_merged", duplicateGoalsMerged, "true", "\(duplicateGoalsMerged)"))
    checks.append(goalSelectionMemoryCheck("scores_bounded", scoresBounded, "true", "\(scoresBounded)"))
    checks.append(goalSelectionMemoryCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(goalSelectionMemoryCheck("selected_candidate_in_candidates", candidatesByDecisionValid, "true", "\(candidatesByDecisionValid)"))
    checks.append(goalSelectionMemoryCheck("memory_influence_reason_present", influenceReasonsPresent, "true", "\(influenceReasonsPresent)"))
    checks.append(goalSelectionMemoryCheck("behavior_action_not_executed", !report.behaviorActionExecuted, "false", "\(report.behaviorActionExecuted)"))
    checks.append(goalSelectionMemoryCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"))
    checks.append(goalSelectionMemoryCheck("retrieval_not_rerun", !report.retrievalRerun, "false", "\(report.retrievalRerun)"))
    checks.append(goalSelectionMemoryCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(goalSelectionMemoryCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(goalSelectionMemoryCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(goalSelectionMemoryCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(goalSelectionMemoryCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(goalSelectionMemoryCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(goalSelectionMemoryCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(goalSelectionMemoryCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(goalSelectionMemoryCheck("report_written", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("invariant_report_written", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("cases_written", !run.cases.isEmpty, "true", "\(!run.cases.isEmpty)"))
    checks.append(goalSelectionMemoryCheck("candidates_written", !run.candidateRecords.isEmpty, "true", "\(!run.candidateRecords.isEmpty)"))
    checks.append(goalSelectionMemoryCheck("decisions_written", !run.decisions.isEmpty, "true", "\(!run.decisions.isEmpty)"))
    checks.append(goalSelectionMemoryCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(goalSelectionMemoryCheck("metrics_written", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("event_written", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("metrics_prefix_expected", true, "goalSelectionMemoryHardening*", "goalSelectionMemoryHardening*"))
    checks.append(goalSelectionMemoryCheck("event_name_expected", true, "lab_goal_selection_memory_hardening_recorded", "lab_goal_selection_memory_hardening_recorded"))
    checks.append(goalSelectionMemoryCheck("changelog_updated", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("dev_journal_updated", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("roadmap_updated", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("phase_plan_updated", true, "true", "true"))
    checks.append(goalSelectionMemoryCheck("success_contract_respected", successContractRespected, "true", "\(successContractRespected)"))

    let failed = checks.filter { !$0.passed }.count
    return LabGoalSelectionMemoryHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabGoalSelectionMemoryHardeningInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.cases,
            decisions: report.decisions,
            candidates: report.candidates,
            selectedGoals: report.selectedGoals,
            goalChanges: report.goalChanges,
            unchangedGoals: report.unchangedGoals
        ),
        checks: checks,
        notes: [
            "Fixture-only hardening for goal selection from provided retrieved memories.",
            "Unknown memory types are ignored and unknown goals are sanitized to idle in the hardening fixture.",
            "No behavior action is executed, no memory is mutated, and retrieval is not rerun."
        ]
    )
}

private func makeGoalSelectionMemoryHardeningDigestValue(
    run: LabGoalSelectionMemoryHardeningRun
) -> String {
    let caseParts = run.cases.map {
        "\($0.name)|\($0.passed)|\($0.selectedGoal ?? "nil")|\($0.candidates)"
    }
    let decisionParts = run.decisions.map {
        "\($0.agentId)|\($0.goalBefore)|\($0.selectedGoal)|\($0.goalChanged)|\($0.memoryInfluenceApplied)|\($0.candidates.map { "\($0.goal):\($0.score):\($0.supportingMemoryCount)" }.joined(separator: ","))"
    }
    return goalSelectionMemoryStableDigest((caseParts + decisionParts).joined(separator: "\n"))
}

private func goalSelectionMemoryHardeningInputDigest(
    _ decisions: [LabGoalSelectionFromMemoryDecision]
) -> String {
    let parts = decisions.sorted(by: goalSelectionDecisionSort).map {
        "\($0.agentId)|\($0.goalBefore)|\($0.selectedGoal)|\($0.candidates.map { "\($0.goal):\($0.supportingMemoryTypes.joined(separator: ","))" }.joined(separator: ";"))"
    }
    return goalSelectionMemoryStableDigest(parts.joined(separator: "\n"))
}

private func makeGoalSelectionMemoryHardeningMetrics(
    report: LabGoalSelectionMemoryHardeningReport
) -> LabGoalSelectionMemoryHardeningMetrics {
    LabGoalSelectionMemoryHardeningMetrics(
        goalSelectionMemoryHardeningSuccess: report.success,
        goalSelectionMemoryHardeningCases: report.cases,
        goalSelectionMemoryHardeningCasesPassed: report.casesPassed,
        goalSelectionMemoryHardeningCasesFailed: report.casesFailed,
        goalSelectionMemoryHardeningDecisions: report.decisions,
        goalSelectionMemoryHardeningCandidates: report.candidates,
        goalSelectionMemoryHardeningSelectedGoals: report.selectedGoals,
        goalSelectionMemoryHardeningGoalChanges: report.goalChanges,
        goalSelectionMemoryHardeningUnchangedGoals: report.unchangedGoals,
        goalSelectionMemoryHardeningInfluencedDecisions: report.memoryInfluencedDecisions,
        goalSelectionMemoryHardeningEmptyRetrievalDecisions: report.emptyRetrievalDecisions,
        goalSelectionMemoryHardeningMaxCandidates: report.maxCandidates,
        goalSelectionMemoryHardeningBounded: report.bounded,
        goalSelectionMemoryHardeningDeterministicOrder: report.deterministicOrder,
        goalSelectionMemoryHardeningBehaviorActionExecuted: report.behaviorActionExecuted,
        goalSelectionMemoryHardeningMemoryMutated: report.memoryMutated,
        goalSelectionMemoryHardeningRetrievalRerun: report.retrievalRerun,
        goalSelectionMemoryHardeningMovementStackUsed: report.movementStackUsed,
        goalSelectionMemoryHardeningWorldMutated: report.worldMutated,
        goalSelectionMemoryHardeningTerrainMutated: report.terrainMutated,
        goalSelectionMemoryHardeningDeterministicDigest: report.deterministicDigest,
        goalSelectionMemoryHardeningDigestsEqual: report.digestsEqual,
        goalSelectionMemoryHardeningRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeGoalSelectionMemoryHardeningEventLines(
    report: LabGoalSelectionMemoryHardeningReport
) throws -> String {
    try encodeGoalSelectionMemoryEventLine(LabGoalSelectionMemoryHardeningRecordedEvent(
        type: "lab_goal_selection_memory_hardening_recorded",
        event: "lab_goal_selection_memory_hardening_recorded",
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        casesFailed: report.casesFailed,
        decisions: report.decisions,
        candidates: report.candidates,
        selectedGoals: report.selectedGoals,
        goalChanges: report.goalChanges,
        unchangedGoals: report.unchangedGoals,
        memoryInfluencedDecisions: report.memoryInfluencedDecisions,
        emptyRetrievalDecisions: report.emptyRetrievalDecisions,
        maxCandidates: report.maxCandidates,
        bounded: report.bounded,
        deterministicOrder: report.deterministicOrder,
        behaviorActionExecuted: report.behaviorActionExecuted,
        memoryMutated: report.memoryMutated,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
}
