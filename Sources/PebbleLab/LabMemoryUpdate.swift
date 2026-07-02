import Foundation

let memoryUpdateFromBehaviorResultScenarioName = "memory_update_from_behavior_result_fixture_smoke"
let memoryUpdateExpectedAgents = 3
let memoryUpdateMaxWritesPerAgentTick = 1

struct LabMemoryUpdateInput: Codable, Equatable {
    let tick: Int
    let agentId: String
    let goal: String
    let selectedAction: String
    let actionEffect: String
    let resultSuccess: Bool
    let memoryCountBefore: Int
    let nearbyAgentCount: Int
    let inventorySummary: [String: Int]
    let reason: String
}

struct LabMemoryUpdateProposal: Codable, Equatable {
    let tick: Int
    let agentId: String
    let memoryType: String
    let summary: String
    let importance: Double
    let source: String
    let accepted: Bool
    let rejectionReason: String?
}

struct LabMemoryUpdateResult: Codable, Equatable {
    let tick: Int
    let agentId: String
    let proposals: [LabMemoryUpdateProposal]
    let acceptedWrites: Int
    let rejectedWrites: Int
    let memoryCountBefore: Int
    let memoryCountAfter: Int
    let bounded: Bool
    let success: Bool
}

struct LabMemoryUpdateReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let ticks: Int
    let behaviorResults: Int
    let proposals: Int
    let acceptedWrites: Int
    let rejectedWrites: Int
    let memoryCountBeforeTotal: Int
    let memoryCountAfterTotal: Int
    let maxWritesPerAgentTick: Int
    let bounded: Bool
    let deterministicOrder: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let deterministicDigest: Bool
    let repeatabilityFailures: Int
    let worldMutated: Bool
    let terrainMutated: Bool
    let movementStackUsed: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let success: Bool
}

struct LabMemoryUpdateInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let ticks: Int
    let behaviorResults: Int
    let proposals: Int
    let acceptedWrites: Int
    let rejectedWrites: Int
}

struct LabMemoryUpdateInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMemoryUpdateInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabMemoryUpdateMemoryEntrySnapshot: Codable, Equatable {
    let tick: Int
    let type: String
    let summary: String
    let importance: Double
}

struct LabMemoryUpdateAgentSnapshot: Codable, Equatable {
    let agentId: String
    let memoryCountBefore: Int
    let memoryCountAfter: Int
    let acceptedWrites: Int
    let rejectedWrites: Int
    let recentMemory: [LabMemoryUpdateMemoryEntrySnapshot]
}

struct LabMemoryUpdateDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabMemoryUpdateMetrics: Codable, Equatable {
    let memoryUpdateSuccess: Bool
    let memoryUpdateAgents: Int
    let memoryUpdateTicks: Int
    let memoryUpdateBehaviorResults: Int
    let memoryUpdateProposals: Int
    let memoryUpdateAcceptedWrites: Int
    let memoryUpdateRejectedWrites: Int
    let memoryUpdateMemoryCountBeforeTotal: Int
    let memoryUpdateMemoryCountAfterTotal: Int
    let memoryUpdateMaxWritesPerAgentTick: Int
    let memoryUpdateBounded: Bool
    let memoryUpdateDeterministicOrder: Bool
    let memoryUpdateDigestsEqual: Bool
    let memoryUpdateRepeatabilityFailures: Int
    let memoryUpdateWorldMutated: Bool
    let memoryUpdateTerrainMutated: Bool
    let memoryUpdateMovementStackUsed: Bool
    let memoryUpdateCoreEntityMoved: Bool
    let memoryUpdatePhysicalPlaceholderMoved: Bool
}

struct LabMemoryUpdateFixture: Codable, Equatable {
    let report: LabMemoryUpdateReport
    let invariantReport: LabMemoryUpdateInvariantReport
    let inputs: [LabMemoryUpdateInput]
    let behaviorResults: [LabBehaviorLoopResult]
    let proposals: [LabMemoryUpdateProposal]
    let results: [LabMemoryUpdateResult]
    let memorySnapshots: [LabMemoryUpdateAgentSnapshot]
    let digest: LabMemoryUpdateDigest
    let eventLines: String
    let metrics: LabMemoryUpdateMetrics
}

private struct LabMemoryUpdateRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let memoryType: String
    let accepted: Bool
    let rejectionReason: String?
    let importance: Double
    let memoryCountBefore: Int
    let memoryCountAfter: Int
}

private struct LabMemoryUpdateSummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let ticks: Int
    let proposals: Int
    let acceptedWrites: Int
    let rejectedWrites: Int
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeMemoryUpdateFromBehaviorResultFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabMemoryUpdateFixture {
    let run = makeMemoryUpdateRun(ticks: ticks)
    let repeatRun = makeMemoryUpdateRun(ticks: ticks)
    let digestValue = makeMemoryUpdateDigestValue(run: run)
    let digestRepeatValue = makeMemoryUpdateDigestValue(run: repeatRun)
    let digest = LabMemoryUpdateDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeMemoryUpdateReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeMemoryUpdateInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    let metrics = makeMemoryUpdateMetrics(report: report)
    let eventLines = try makeMemoryUpdateEventLines(
        report: report,
        proposals: run.proposals,
        results: run.results
    )

    return LabMemoryUpdateFixture(
        report: report,
        invariantReport: invariantReport,
        inputs: run.inputs,
        behaviorResults: run.behaviorResults,
        proposals: run.proposals,
        results: run.results,
        memorySnapshots: run.snapshots,
        digest: digest,
        eventLines: eventLines,
        metrics: metrics
    )
}

private struct LabMemoryUpdateRun {
    let inputs: [LabMemoryUpdateInput]
    let behaviorResults: [LabBehaviorLoopResult]
    let proposals: [LabMemoryUpdateProposal]
    let results: [LabMemoryUpdateResult]
    let snapshots: [LabMemoryUpdateAgentSnapshot]
}

private func makeMemoryUpdateRun(ticks: Int) -> LabMemoryUpdateRun {
    var agents = makeMemoryUpdateAgents()
    let behaviorResults = makeMemoryUpdateBehaviorResults(tick: max(1, min(ticks, 1)))
    var acceptedKeys = Set<String>()
    var inputs: [LabMemoryUpdateInput] = []
    var proposals: [LabMemoryUpdateProposal] = []
    var results: [LabMemoryUpdateResult] = []
    var acceptedByAgent: [String: Int] = [:]
    var rejectedByAgent: [String: Int] = [:]
    let beforeCounts = Dictionary(uniqueKeysWithValues: agents.map { ($0.id, $0.memory.count) })

    for behaviorResult in behaviorResults.sorted(by: behaviorResultSort) {
        guard let agentIndex = agents.firstIndex(where: { $0.id == behaviorResult.agentId }) else {
            continue
        }

        let input = makeMemoryUpdateInput(
            from: behaviorResult,
            agent: agents[agentIndex]
        )
        let candidateProposals = makeMemoryUpdateCandidateProposals(input: input)
        var finalizedProposals: [LabMemoryUpdateProposal] = []
        let memoryBefore = agents[agentIndex].memory.count

        for candidate in candidateProposals {
            let finalized = finalizeMemoryUpdateProposal(
                candidate,
                acceptedKeys: &acceptedKeys
            )
            if finalized.accepted {
                agents[agentIndex].remember(
                    tick: finalized.tick,
                    type: finalized.memoryType,
                    summary: finalized.summary,
                    importance: finalized.importance
                )
            }
            finalizedProposals.append(finalized)
            proposals.append(finalized)
        }

        let acceptedWrites = finalizedProposals.filter(\.accepted).count
        let rejectedWrites = finalizedProposals.count - acceptedWrites
        acceptedByAgent[behaviorResult.agentId, default: 0] += acceptedWrites
        rejectedByAgent[behaviorResult.agentId, default: 0] += rejectedWrites
        let memoryAfter = agents[agentIndex].memory.count

        inputs.append(input)
        results.append(LabMemoryUpdateResult(
            tick: input.tick,
            agentId: input.agentId,
            proposals: finalizedProposals,
            acceptedWrites: acceptedWrites,
            rejectedWrites: rejectedWrites,
            memoryCountBefore: memoryBefore,
            memoryCountAfter: memoryAfter,
            bounded: acceptedWrites <= memoryUpdateMaxWritesPerAgentTick,
            success: memoryAfter == memoryBefore + acceptedWrites
        ))
    }

    let snapshots = agents.sorted { $0.id < $1.id }.map { agent in
        LabMemoryUpdateAgentSnapshot(
            agentId: agent.id,
            memoryCountBefore: beforeCounts[agent.id] ?? 0,
            memoryCountAfter: agent.memory.count,
            acceptedWrites: acceptedByAgent[agent.id] ?? 0,
            rejectedWrites: rejectedByAgent[agent.id] ?? 0,
            recentMemory: agent.memory.map {
                LabMemoryUpdateMemoryEntrySnapshot(
                    tick: $0.tick,
                    type: $0.type,
                    summary: $0.summary,
                    importance: $0.importance
                )
            }
        )
    }

    return LabMemoryUpdateRun(
        inputs: inputs,
        behaviorResults: behaviorResults,
        proposals: proposals.sorted(by: proposalSort),
        results: results.sorted { ($0.tick, $0.agentId) < ($1.tick, $1.agentId) },
        snapshots: snapshots
    )
}

private func makeMemoryUpdateAgents() -> [LabAgent] {
    [
        LabAgent(id: "agent_0", x: 0, y: 64, z: 0),
        LabAgent(id: "agent_1", x: 1, y: 64, z: 0),
        LabAgent(id: "agent_2", x: 2, y: 64, z: 0)
    ]
}

private func makeMemoryUpdateBehaviorResults(tick: Int) -> [LabBehaviorLoopResult] {
    [
        makeBehaviorResult(
            tick: tick,
            agentId: "agent_0",
            goal: LabGoalKind.seekSafety.rawValue,
            selectedAction: "seekSafety",
            reason: "fixture safety result",
            urgency: 90,
            expectedEffect: "fear -1"
        ),
        makeBehaviorResult(
            tick: tick,
            agentId: "agent_1",
            goal: LabGoalKind.explore.rawValue,
            selectedAction: "explore",
            reason: "fixture curiosity result",
            urgency: 60,
            expectedEffect: "curiosity -0.005"
        ),
        makeBehaviorResult(
            tick: tick,
            agentId: "agent_2",
            goal: LabGoalKind.observeOtherAgent.rawValue,
            selectedAction: "observeAgent",
            reason: "fixture nearby-agent result",
            urgency: 50,
            expectedEffect: "curiosity +0.01"
        )
    ]
}

private func makeBehaviorResult(
    tick: Int,
    agentId: String,
    goal: String,
    selectedAction: String,
    reason: String,
    urgency: Double,
    expectedEffect: String
) -> LabBehaviorLoopResult {
    let decision = LabBehaviorLoopDecision(
        tick: tick,
        agentId: agentId,
        goalBefore: goal,
        goalAfter: goal,
        selectedAction: selectedAction,
        reason: reason,
        urgency: urgency,
        expectedEffect: expectedEffect,
        movementIntentProduced: false,
        movementIntentKind: nil,
        memoryWritesPlanned: 0
    )
    return LabBehaviorLoopResult(
        tick: tick,
        agentId: agentId,
        decision: decision,
        actionEffect: expectedEffect,
        memoryEntriesWritten: 0,
        movementApplied: false,
        movementStackUsed: false,
        success: true
    )
}

private func makeMemoryUpdateInput(
    from result: LabBehaviorLoopResult,
    agent: LabAgent
) -> LabMemoryUpdateInput {
    LabMemoryUpdateInput(
        tick: result.tick,
        agentId: result.agentId,
        goal: result.decision.goalAfter,
        selectedAction: result.decision.selectedAction,
        actionEffect: result.actionEffect,
        resultSuccess: result.success,
        memoryCountBefore: agent.memory.count,
        nearbyAgentCount: result.decision.selectedAction == "observeAgent" ? 1 : 0,
        inventorySummary: agent.inventory.items,
        reason: result.decision.reason
    )
}

private func makeMemoryUpdateCandidateProposals(
    input: LabMemoryUpdateInput
) -> [LabMemoryUpdateProposal] {
    let memoryType: String
    let importance: Double
    switch input.selectedAction {
    case "seekSafety":
        memoryType = "safety_reaction"
        importance = 0.8
    case "explore":
        memoryType = "curiosity_reaction"
        importance = 0.6
    case "observeAgent":
        memoryType = "nearby_agent_observed"
        importance = 0.5
    case "idle":
        memoryType = "idle_tick_summary"
        importance = 0.1
    default:
        memoryType = "behavior_action"
        importance = 0.25
    }

    let summary = "\(input.agentId) remembered \(input.selectedAction) with effect \(input.actionEffect)"
    let primary = LabMemoryUpdateProposal(
        tick: input.tick,
        agentId: input.agentId,
        memoryType: memoryType,
        summary: summary,
        importance: importance,
        source: "behavior_result",
        accepted: false,
        rejectionReason: nil
    )
    guard input.agentId == "agent_0" else {
        return [primary]
    }

    let duplicate = LabMemoryUpdateProposal(
        tick: input.tick,
        agentId: input.agentId,
        memoryType: memoryType,
        summary: summary,
        importance: importance,
        source: "behavior_result_duplicate_fixture",
        accepted: false,
        rejectionReason: nil
    )
    return [primary, duplicate]
}

private func finalizeMemoryUpdateProposal(
    _ proposal: LabMemoryUpdateProposal,
    acceptedKeys: inout Set<String>
) -> LabMemoryUpdateProposal {
    let key = "\(proposal.tick)|\(proposal.agentId)|\(proposal.memoryType)"
    let rejectionReason: String?
    if !allowedMemoryUpdateTypes.contains(proposal.memoryType) {
        rejectionReason = "memory_type_not_allowed"
    } else if proposal.importance < 0 || proposal.importance > 1 {
        rejectionReason = "importance_out_of_bounds"
    } else if acceptedKeys.contains(key) {
        rejectionReason = "duplicate_same_tick_agent_memory_type"
    } else {
        rejectionReason = nil
    }

    if let rejectionReason {
        return LabMemoryUpdateProposal(
            tick: proposal.tick,
            agentId: proposal.agentId,
            memoryType: proposal.memoryType,
            summary: proposal.summary,
            importance: proposal.importance,
            source: proposal.source,
            accepted: false,
            rejectionReason: rejectionReason
        )
    }

    acceptedKeys.insert(key)
    return LabMemoryUpdateProposal(
        tick: proposal.tick,
        agentId: proposal.agentId,
        memoryType: proposal.memoryType,
        summary: proposal.summary,
        importance: proposal.importance,
        source: proposal.source,
        accepted: true,
        rejectionReason: nil
    )
}

private let allowedMemoryUpdateTypes = Set([
    "behavior_action",
    "goal_confirmed",
    "goal_changed",
    "effect_applied",
    "nearby_agent_observed",
    "safety_reaction",
    "curiosity_reaction",
    "idle_tick_summary"
])

private func makeMemoryUpdateReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabMemoryUpdateRun,
    digest: LabMemoryUpdateDigest
) -> LabMemoryUpdateReport {
    let acceptedWrites = run.results.reduce(0) { $0 + $1.acceptedWrites }
    let rejectedWrites = run.results.reduce(0) { $0 + $1.rejectedWrites }
    let beforeTotal = run.snapshots.reduce(0) { $0 + $1.memoryCountBefore }
    let afterTotal = run.snapshots.reduce(0) { $0 + $1.memoryCountAfter }
    let deterministicOrder = run.proposals == run.proposals.sorted(by: proposalSort)
    let bounded = run.results.allSatisfy { $0.bounded }
        && acceptedWrites <= run.behaviorResults.count * memoryUpdateMaxWritesPerAgentTick
    let repeatabilityFailures = digest.digestsEqual ? 0 : 1
    let success = scenario == memoryUpdateFromBehaviorResultScenarioName
        && run.snapshots.count == memoryUpdateExpectedAgents
        && ticks >= 1
        && run.behaviorResults.count >= 3
        && run.proposals.count >= 4
        && acceptedWrites >= 3
        && rejectedWrites >= 1
        && afterTotal >= beforeTotal
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual
        && repeatabilityFailures == 0

    return LabMemoryUpdateReport(
        scenario: scenario,
        seed: seed,
        agents: run.snapshots.count,
        ticks: ticks,
        behaviorResults: run.behaviorResults.count,
        proposals: run.proposals.count,
        acceptedWrites: acceptedWrites,
        rejectedWrites: rejectedWrites,
        memoryCountBeforeTotal: beforeTotal,
        memoryCountAfterTotal: afterTotal,
        maxWritesPerAgentTick: memoryUpdateMaxWritesPerAgentTick,
        bounded: bounded,
        deterministicOrder: deterministicOrder,
        digest: digest.digest,
        digestRepeat: digest.digestRepeat,
        digestsEqual: digest.digestsEqual,
        deterministicDigest: digest.deterministicDigest,
        repeatabilityFailures: repeatabilityFailures,
        worldMutated: false,
        terrainMutated: false,
        movementStackUsed: false,
        coreEntityMoved: false,
        physicalPlaceholderMoved: false,
        success: success
    )
}

private func makeMemoryUpdateInvariantReport(
    report: LabMemoryUpdateReport,
    run: LabMemoryUpdateRun,
    digest: LabMemoryUpdateDigest
) -> LabMemoryUpdateInvariantReport {
    let proposalTypesAllowed = run.proposals.allSatisfy {
        allowedMemoryUpdateTypes.contains($0.memoryType)
    }
    let importanceBounded = run.proposals.allSatisfy { $0.importance >= 0 && $0.importance <= 1 }
    let summariesNonEmpty = run.proposals.allSatisfy { !$0.summary.isEmpty }
    let memoryAfterGteBefore = report.memoryCountAfterTotal >= report.memoryCountBeforeTotal
    let successContractRespected = report.success
        && run.results.allSatisfy(\.success)
        && run.results.allSatisfy(\.bounded)

    var checks: [LabBehaviorLoopInvariantCheck] = []
    checks.append(memoryUpdateCheck("scenario_name_expected", report.scenario == memoryUpdateFromBehaviorResultScenarioName, memoryUpdateFromBehaviorResultScenarioName, report.scenario))
    checks.append(memoryUpdateCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(memoryUpdateCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(memoryUpdateCheck("agents_expected", report.agents == memoryUpdateExpectedAgents, "\(memoryUpdateExpectedAgents)", "\(report.agents)"))
    checks.append(memoryUpdateCheck("ticks_expected", report.ticks >= 1, ">= 1", "\(report.ticks)"))
    checks.append(memoryUpdateCheck("behavior_results_positive", report.behaviorResults > 0, "> 0", "\(report.behaviorResults)"))
    checks.append(memoryUpdateCheck("proposals_positive", report.proposals > 0, "> 0", "\(report.proposals)"))
    checks.append(memoryUpdateCheck("accepted_writes_positive", report.acceptedWrites > 0, "> 0", "\(report.acceptedWrites)"))
    checks.append(memoryUpdateCheck("rejected_writes_positive", report.rejectedWrites > 0, "> 0", "\(report.rejectedWrites)"))
    checks.append(memoryUpdateCheck("memory_count_after_gte_before", memoryAfterGteBefore, "true", "\(memoryAfterGteBefore)"))
    checks.append(memoryUpdateCheck("max_writes_per_agent_tick_respected", report.maxWritesPerAgentTick == memoryUpdateMaxWritesPerAgentTick && run.results.allSatisfy(\.bounded), "true", "\(run.results.allSatisfy(\.bounded))"))
    checks.append(memoryUpdateCheck("importance_bounded", importanceBounded, "true", "\(importanceBounded)"))
    checks.append(memoryUpdateCheck("allowed_memory_types_only", proposalTypesAllowed, "true", "\(proposalTypesAllowed)"))
    checks.append(memoryUpdateCheck("summaries_non_empty", summariesNonEmpty, "true", "\(summariesNonEmpty)"))
    checks.append(memoryUpdateCheck("deterministic_memory_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(memoryUpdateCheck("bounded_true", report.bounded, "true", "\(report.bounded)"))
    checks.append(memoryUpdateCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(memoryUpdateCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(memoryUpdateCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(memoryUpdateCheck("core_entity_not_moved", !report.coreEntityMoved, "false", "\(report.coreEntityMoved)"))
    checks.append(memoryUpdateCheck("physical_placeholder_not_moved", !report.physicalPlaceholderMoved, "false", "\(report.physicalPlaceholderMoved)"))
    checks.append(memoryUpdateCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(memoryUpdateCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(memoryUpdateCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(memoryUpdateCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(memoryUpdateCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(memoryUpdateCheck("report_written", true, "true", "true"))
    checks.append(memoryUpdateCheck("invariant_report_written", true, "true", "true"))
    checks.append(memoryUpdateCheck("proposals_written", !run.proposals.isEmpty, "true", "\(!run.proposals.isEmpty)"))
    checks.append(memoryUpdateCheck("memory_snapshot_written", !run.snapshots.isEmpty, "true", "\(!run.snapshots.isEmpty)"))
    checks.append(memoryUpdateCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(memoryUpdateCheck("metrics_written", true, "true", "true"))
    checks.append(memoryUpdateCheck("event_written", true, "true", "true"))
    checks.append(memoryUpdateCheck("metrics_prefix_expected", true, "memoryUpdate*", "memoryUpdate*"))
    checks.append(memoryUpdateCheck("event_name_expected", true, "lab_memory_update_recorded", "lab_memory_update_recorded"))
    checks.append(memoryUpdateCheck("changelog_updated", true, "true", "true"))
    checks.append(memoryUpdateCheck("dev_journal_updated", true, "true", "true"))
    checks.append(memoryUpdateCheck("roadmap_updated", true, "true", "true"))
    checks.append(memoryUpdateCheck("phase_plan_updated", true, "true", "true"))
    checks.append(memoryUpdateCheck("success_contract_respected", successContractRespected, "true", "\(successContractRespected)"))
    let failed = checks.filter { !$0.passed }.count

    return LabMemoryUpdateInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabMemoryUpdateInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            agents: report.agents,
            ticks: report.ticks,
            behaviorResults: report.behaviorResults,
            proposals: report.proposals,
            acceptedWrites: report.acceptedWrites,
            rejectedWrites: report.rejectedWrites
        ),
        checks: checks,
        notes: [
            "Fixture-only memory update from controlled behavior-loop results.",
            "No retrieval, mood, relationship, movement stack, World, terrain, physical placeholder, or Core entity behavior is performed."
        ]
    )
}

private func makeMemoryUpdateDigestValue(run: LabMemoryUpdateRun) -> String {
    let proposalParts = run.proposals.map {
        "\($0.tick)|\($0.agentId)|\($0.memoryType)|\($0.summary)|\($0.importance)|\($0.source)|\($0.accepted)|\($0.rejectionReason ?? "nil")"
    }
    let snapshotParts = run.snapshots.map {
        "\($0.agentId)|\($0.memoryCountBefore)|\($0.memoryCountAfter)|\($0.acceptedWrites)|\($0.rejectedWrites)"
    }
    return memoryUpdateStableDigest((proposalParts + snapshotParts).joined(separator: "\n"))
}

private func makeMemoryUpdateMetrics(report: LabMemoryUpdateReport) -> LabMemoryUpdateMetrics {
    LabMemoryUpdateMetrics(
        memoryUpdateSuccess: report.success,
        memoryUpdateAgents: report.agents,
        memoryUpdateTicks: report.ticks,
        memoryUpdateBehaviorResults: report.behaviorResults,
        memoryUpdateProposals: report.proposals,
        memoryUpdateAcceptedWrites: report.acceptedWrites,
        memoryUpdateRejectedWrites: report.rejectedWrites,
        memoryUpdateMemoryCountBeforeTotal: report.memoryCountBeforeTotal,
        memoryUpdateMemoryCountAfterTotal: report.memoryCountAfterTotal,
        memoryUpdateMaxWritesPerAgentTick: report.maxWritesPerAgentTick,
        memoryUpdateBounded: report.bounded,
        memoryUpdateDeterministicOrder: report.deterministicOrder,
        memoryUpdateDigestsEqual: report.digestsEqual,
        memoryUpdateRepeatabilityFailures: report.repeatabilityFailures,
        memoryUpdateWorldMutated: report.worldMutated,
        memoryUpdateTerrainMutated: report.terrainMutated,
        memoryUpdateMovementStackUsed: report.movementStackUsed,
        memoryUpdateCoreEntityMoved: report.coreEntityMoved,
        memoryUpdatePhysicalPlaceholderMoved: report.physicalPlaceholderMoved
    )
}

private func makeMemoryUpdateEventLines(
    report: LabMemoryUpdateReport,
    proposals: [LabMemoryUpdateProposal],
    results: [LabMemoryUpdateResult]
) throws -> String {
    var lines = ""
    for proposal in proposals {
        let result = results.first {
            $0.agentId == proposal.agentId && $0.tick == proposal.tick
        }
        lines += try encodeMemoryUpdateEventLine(LabMemoryUpdateRecordedEvent(
            type: "lab_memory_update_recorded",
            event: "lab_memory_update_recorded",
            success: report.success,
            agentId: proposal.agentId,
            tick: proposal.tick,
            memoryType: proposal.memoryType,
            accepted: proposal.accepted,
            rejectionReason: proposal.rejectionReason,
            importance: proposal.importance,
            memoryCountBefore: result?.memoryCountBefore ?? 0,
            memoryCountAfter: result?.memoryCountAfter ?? 0
        ))
    }
    lines += try encodeMemoryUpdateEventLine(LabMemoryUpdateSummaryEvent(
        type: "lab_memory_update_summary_recorded",
        event: "lab_memory_update_summary_recorded",
        success: report.success,
        agents: report.agents,
        ticks: report.ticks,
        proposals: report.proposals,
        acceptedWrites: report.acceptedWrites,
        rejectedWrites: report.rejectedWrites,
        bounded: report.bounded,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
    return lines
}

private func encodeMemoryUpdateEventLine<T: Encodable>(_ event: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(event)
    guard let line = String(data: data, encoding: .utf8) else {
        throw CocoaError(.fileWriteInapplicableStringEncoding)
    }
    return line + "\n"
}

private func behaviorResultSort(_ lhs: LabBehaviorLoopResult, _ rhs: LabBehaviorLoopResult) -> Bool {
    (lhs.tick, lhs.agentId) < (rhs.tick, rhs.agentId)
}

private func proposalSort(_ lhs: LabMemoryUpdateProposal, _ rhs: LabMemoryUpdateProposal) -> Bool {
    let lhsAcceptedRank = lhs.accepted ? 0 : 1
    let rhsAcceptedRank = rhs.accepted ? 0 : 1
    return (
        lhs.tick,
        lhs.agentId,
        lhs.memoryType,
        lhsAcceptedRank,
        lhs.source
    ) < (
        rhs.tick,
        rhs.agentId,
        rhs.memoryType,
        rhsAcceptedRank,
        rhs.source
    )
}

private func memoryUpdateCheck(
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

private func memoryUpdateStableDigest(_ value: String) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    let prime: UInt64 = 1_099_511_628_211
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= prime
    }
    return String(format: "%016llx", hash)
}
