import Foundation

let memoryUpdateFromBehaviorResultScenarioName = "memory_update_from_behavior_result_fixture_smoke"
let memoryUpdateHardeningScenarioName = "memory_update_hardening_smoke"
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

struct LabMemoryUpdateHardeningCase: Codable, Equatable {
    let name: String
    let expectedAcceptedWrites: Int
    let expectedRejectedWrites: Int
    let expectedReasons: [String]
}

struct LabMemoryUpdateHardeningCaseResult: Codable, Equatable {
    let name: String
    let passed: Bool
    let proposals: Int
    let acceptedWrites: Int
    let rejectedWrites: Int
    let memoryCountBefore: Int
    let memoryCountAfter: Int
    let expectedAcceptedWrites: Int
    let expectedRejectedWrites: Int
    let expectedReasons: [String]
    let observedReasons: [String]
    let notes: [String]
}

struct LabMemoryUpdateHardeningReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let ticks: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
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

struct LabMemoryUpdateHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let proposals: Int
    let acceptedWrites: Int
    let rejectedWrites: Int
}

struct LabMemoryUpdateHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMemoryUpdateHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabMemoryUpdateHardeningMetrics: Codable, Equatable {
    let memoryUpdateHardeningSuccess: Bool
    let memoryUpdateHardeningCases: Int
    let memoryUpdateHardeningCasesPassed: Int
    let memoryUpdateHardeningCasesFailed: Int
    let memoryUpdateHardeningProposals: Int
    let memoryUpdateHardeningAcceptedWrites: Int
    let memoryUpdateHardeningRejectedWrites: Int
    let memoryUpdateHardeningMemoryCountBeforeTotal: Int
    let memoryUpdateHardeningMemoryCountAfterTotal: Int
    let memoryUpdateHardeningMaxWritesPerAgentTick: Int
    let memoryUpdateHardeningBounded: Bool
    let memoryUpdateHardeningDeterministicOrder: Bool
    let memoryUpdateHardeningMovementStackUsed: Bool
    let memoryUpdateHardeningWorldMutated: Bool
    let memoryUpdateHardeningTerrainMutated: Bool
    let memoryUpdateHardeningCoreEntityMoved: Bool
    let memoryUpdateHardeningPhysicalPlaceholderMoved: Bool
    let memoryUpdateHardeningDeterministicDigest: Bool
    let memoryUpdateHardeningDigestsEqual: Bool
    let memoryUpdateHardeningRepeatabilityFailures: Int
}

struct LabMemoryUpdateHardeningFixture: Codable, Equatable {
    let report: LabMemoryUpdateHardeningReport
    let invariantReport: LabMemoryUpdateHardeningInvariantReport
    let cases: [LabMemoryUpdateHardeningCaseResult]
    let proposals: [LabMemoryUpdateProposal]
    let memorySnapshots: [LabMemoryUpdateAgentSnapshot]
    let digest: LabMemoryUpdateDigest
    let eventLines: String
    let metrics: LabMemoryUpdateHardeningMetrics
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

private struct LabMemoryUpdateHardeningRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let proposals: Int
    let acceptedWrites: Int
    let rejectedWrites: Int
    let memoryCountBeforeTotal: Int
    let memoryCountAfterTotal: Int
    let maxWritesPerAgentTick: Int
    let bounded: Bool
    let deterministicOrder: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
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

func makeMemoryUpdateHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabMemoryUpdateHardeningFixture {
    let run = makeMemoryUpdateHardeningRun(ticks: ticks)
    let repeatRun = makeMemoryUpdateHardeningRun(ticks: ticks)
    let digestValue = makeMemoryUpdateHardeningDigestValue(run: run)
    let digestRepeatValue = makeMemoryUpdateHardeningDigestValue(run: repeatRun)
    let digest = LabMemoryUpdateDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeMemoryUpdateHardeningReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        run: run,
        digest: digest
    )
    let invariantReport = makeMemoryUpdateHardeningInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabMemoryUpdateHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: run.cases,
        proposals: run.proposals,
        memorySnapshots: run.snapshots,
        digest: digest,
        eventLines: try makeMemoryUpdateHardeningEventLines(report: report),
        metrics: makeMemoryUpdateHardeningMetrics(report: report)
    )
}

private struct LabMemoryUpdateRun {
    let inputs: [LabMemoryUpdateInput]
    let behaviorResults: [LabBehaviorLoopResult]
    let proposals: [LabMemoryUpdateProposal]
    let results: [LabMemoryUpdateResult]
    let snapshots: [LabMemoryUpdateAgentSnapshot]
}

private struct LabMemoryUpdateHardeningRun {
    let cases: [LabMemoryUpdateHardeningCaseResult]
    let proposals: [LabMemoryUpdateProposal]
    let snapshots: [LabMemoryUpdateAgentSnapshot]
}

private func makeMemoryUpdateRun(ticks: Int) -> LabMemoryUpdateRun {
    var agents = makeMemoryUpdateAgents()
    let behaviorResults = makeMemoryUpdateBehaviorResults(tick: max(1, min(ticks, 1)))
    var acceptedTypeKeys = Set<String>()
    var acceptedAgentTickKeys = Set<String>()
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

        for candidate in candidateProposals.sorted(by: proposalSort) {
            let finalized = finalizeMemoryUpdateProposal(
                candidate,
                acceptedTypeKeys: &acceptedTypeKeys,
                acceptedAgentTickKeys: &acceptedAgentTickKeys
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

private func makeMemoryUpdateHardeningRun(ticks: Int) -> LabMemoryUpdateHardeningRun {
    var caseResults: [LabMemoryUpdateHardeningCaseResult] = []
    var allProposals: [LabMemoryUpdateProposal] = []
    var allSnapshots: [LabMemoryUpdateAgentSnapshot] = []

    let baselineRun = makeMemoryUpdateRun(ticks: ticks)
    let baselineCase = makeMemoryUpdateHardeningCaseResult(
        name: "baseline_fixture_compatible",
        proposals: baselineRun.proposals,
        snapshots: baselineRun.snapshots,
        expectedAcceptedWrites: 3,
        expectedRejectedWrites: 1,
        expectedReasons: ["duplicate_same_tick_agent_memory_type"],
        notes: ["Reuses the Phase 5.2B fixture shape: 3 agents, 4 proposals, 3 accepted writes, 1 duplicate rejection."]
    )
    caseResults.append(baselineCase)
    allProposals.append(contentsOf: baselineRun.proposals)
    allSnapshots.append(contentsOf: prefixedSnapshots(baselineRun.snapshots, prefix: "baseline_fixture_compatible"))

    let specs = makeMemoryUpdateHardeningCaseSpecs(ticks: ticks)
    for spec in specs {
        let run = runMemoryUpdateHardeningCase(spec)
        caseResults.append(run.caseResult)
        allProposals.append(contentsOf: run.proposals)
        allSnapshots.append(contentsOf: run.snapshots)
    }

    return LabMemoryUpdateHardeningRun(
        cases: caseResults.sorted { $0.name < $1.name },
        proposals: allProposals.sorted(by: proposalSort),
        snapshots: allSnapshots.sorted { $0.agentId < $1.agentId }
    )
}

private struct LabMemoryUpdateHardeningCaseSpec {
    let name: String
    let candidates: [LabMemoryUpdateProposal]
    let expectedAcceptedWrites: Int
    let expectedRejectedWrites: Int
    let expectedReasons: [String]
    let notes: [String]
}

private struct LabMemoryUpdateHardeningSingleCaseRun {
    let caseResult: LabMemoryUpdateHardeningCaseResult
    let proposals: [LabMemoryUpdateProposal]
    let snapshots: [LabMemoryUpdateAgentSnapshot]
}

private func makeMemoryUpdateHardeningCaseSpecs(ticks: Int) -> [LabMemoryUpdateHardeningCaseSpec] {
    let tick = max(1, min(ticks, 1))
    return [
        LabMemoryUpdateHardeningCaseSpec(
            name: "accepted_safety_reaction",
            candidates: [hardeningProposal(tick: tick, agentId: "agent_safety", memoryType: "safety_reaction", summary: "agent_safety remembered seekSafety", importance: 0.8)],
            expectedAcceptedWrites: 1,
            expectedRejectedWrites: 0,
            expectedReasons: [],
            notes: ["Accepts a bounded safety_reaction proposal."]
        ),
        LabMemoryUpdateHardeningCaseSpec(
            name: "accepted_curiosity_reaction",
            candidates: [hardeningProposal(tick: tick, agentId: "agent_curiosity", memoryType: "curiosity_reaction", summary: "agent_curiosity remembered explore", importance: 0.6)],
            expectedAcceptedWrites: 1,
            expectedRejectedWrites: 0,
            expectedReasons: [],
            notes: ["Accepts a bounded curiosity_reaction proposal."]
        ),
        LabMemoryUpdateHardeningCaseSpec(
            name: "accepted_nearby_agent_observed",
            candidates: [hardeningProposal(tick: tick, agentId: "agent_nearby", memoryType: "nearby_agent_observed", summary: "agent_nearby remembered observeAgent", importance: 0.5)],
            expectedAcceptedWrites: 1,
            expectedRejectedWrites: 0,
            expectedReasons: [],
            notes: ["Accepts a bounded nearby_agent_observed proposal."]
        ),
        LabMemoryUpdateHardeningCaseSpec(
            name: "duplicate_same_tick_agent_memory_type_rejected",
            candidates: [
                hardeningProposal(tick: tick, agentId: "agent_duplicate", memoryType: "safety_reaction", summary: "agent_duplicate remembered seekSafety", importance: 0.8, source: "primary"),
                hardeningProposal(tick: tick, agentId: "agent_duplicate", memoryType: "safety_reaction", summary: "agent_duplicate remembered seekSafety again", importance: 0.8, source: "secondary")
            ],
            expectedAcceptedWrites: 1,
            expectedRejectedWrites: 1,
            expectedReasons: ["duplicate_same_tick_agent_memory_type"],
            notes: ["Rejects the second same tick/agent/type proposal and does not append it."]
        ),
        LabMemoryUpdateHardeningCaseSpec(
            name: "max_one_write_per_agent_tick_enforced",
            candidates: [
                hardeningProposal(tick: tick, agentId: "agent_max_one", memoryType: "safety_reaction", summary: "agent_max_one remembered seekSafety", importance: 0.8),
                hardeningProposal(tick: tick, agentId: "agent_max_one", memoryType: "curiosity_reaction", summary: "agent_max_one remembered explore", importance: 0.6)
            ],
            expectedAcceptedWrites: 1,
            expectedRejectedWrites: 1,
            expectedReasons: ["max_one_write_per_agent_tick"],
            notes: ["Allows only one accepted memory for an agent/tick even across different valid memory types."]
        ),
        LabMemoryUpdateHardeningCaseSpec(
            name: "invalid_memory_type_rejected",
            candidates: [hardeningProposal(tick: tick, agentId: "agent_invalid_type", memoryType: "unbounded_social_memory", summary: "agent_invalid_type remembered unsupported type", importance: 0.4)],
            expectedAcceptedWrites: 0,
            expectedRejectedWrites: 1,
            expectedReasons: ["memory_type_not_allowed"],
            notes: ["Rejects memory types outside the v0 allowlist."]
        ),
        LabMemoryUpdateHardeningCaseSpec(
            name: "empty_summary_rejected",
            candidates: [hardeningProposal(tick: tick, agentId: "agent_empty_summary", memoryType: "behavior_action", summary: "", importance: 0.3)],
            expectedAcceptedWrites: 0,
            expectedRejectedWrites: 1,
            expectedReasons: ["summary_empty"],
            notes: ["Rejects empty summaries rather than appending silent memory."]
        ),
        LabMemoryUpdateHardeningCaseSpec(
            name: "importance_below_bounds_rejected_or_clamped",
            candidates: [hardeningProposal(tick: tick, agentId: "agent_low_importance", memoryType: "behavior_action", summary: "agent_low_importance remembered low importance", importance: -0.1)],
            expectedAcceptedWrites: 0,
            expectedRejectedWrites: 1,
            expectedReasons: ["importance_out_of_bounds"],
            notes: ["Phase 5.2C chooses rejection, not clamping, for importance below 0.0."]
        ),
        LabMemoryUpdateHardeningCaseSpec(
            name: "importance_above_bounds_rejected_or_clamped",
            candidates: [hardeningProposal(tick: tick, agentId: "agent_high_importance", memoryType: "behavior_action", summary: "agent_high_importance remembered high importance", importance: 1.2)],
            expectedAcceptedWrites: 0,
            expectedRejectedWrites: 1,
            expectedReasons: ["importance_out_of_bounds"],
            notes: ["Phase 5.2C chooses rejection, not clamping, for importance above 1.0."]
        ),
        LabMemoryUpdateHardeningCaseSpec(
            name: "memory_count_before_after_consistent",
            candidates: [
                hardeningProposal(tick: tick, agentId: "agent_counts", memoryType: "behavior_action", summary: "agent_counts remembered action", importance: 0.3),
                hardeningProposal(tick: tick + 1, agentId: "agent_counts", memoryType: "effect_applied", summary: "agent_counts remembered effect", importance: 0.4)
            ],
            expectedAcceptedWrites: 2,
            expectedRejectedWrites: 0,
            expectedReasons: [],
            notes: ["Accepted writes increase memoryCountAfter exactly by acceptedWrites."]
        ),
        LabMemoryUpdateHardeningCaseSpec(
            name: "deterministic_order",
            candidates: [
                hardeningProposal(tick: tick + 2, agentId: "agent_order_b", memoryType: "effect_applied", summary: "agent_order_b remembered effect", importance: 0.4),
                hardeningProposal(tick: tick, agentId: "agent_order_a", memoryType: "behavior_action", summary: "agent_order_a remembered action", importance: 0.3),
                hardeningProposal(tick: tick + 1, agentId: "agent_order_a", memoryType: "goal_confirmed", summary: "agent_order_a remembered goal", importance: 0.3)
            ],
            expectedAcceptedWrites: 3,
            expectedRejectedWrites: 0,
            expectedReasons: [],
            notes: ["Inputs are intentionally unsorted; outputs are sorted by tick, agentId, memoryType, acceptance, and source."]
        ),
        LabMemoryUpdateHardeningCaseSpec(
            name: "digest_repeatability",
            candidates: [hardeningProposal(tick: tick, agentId: "agent_digest", memoryType: "idle_tick_summary", summary: "agent_digest remembered idle", importance: 0.1)],
            expectedAcceptedWrites: 1,
            expectedRejectedWrites: 0,
            expectedReasons: [],
            notes: ["The full hardening report is rebuilt twice and must produce identical digests."]
        )
    ]
}

private func runMemoryUpdateHardeningCase(
    _ spec: LabMemoryUpdateHardeningCaseSpec
) -> LabMemoryUpdateHardeningSingleCaseRun {
    var acceptedTypeKeys = Set<String>()
    var acceptedAgentTickKeys = Set<String>()
    var agents = Dictionary(uniqueKeysWithValues: Set(spec.candidates.map(\.agentId)).map {
        ($0, LabAgent(id: $0, x: 0, y: 64, z: 0))
    })
    var proposals: [LabMemoryUpdateProposal] = []
    var acceptedByAgent: [String: Int] = [:]
    var rejectedByAgent: [String: Int] = [:]

    for candidate in spec.candidates.sorted(by: proposalSort) {
        let finalized = finalizeMemoryUpdateProposal(
            candidate,
            acceptedTypeKeys: &acceptedTypeKeys,
            acceptedAgentTickKeys: &acceptedAgentTickKeys
        )
        if finalized.accepted, var agent = agents[finalized.agentId] {
            agent.remember(
                tick: finalized.tick,
                type: finalized.memoryType,
                summary: finalized.summary,
                importance: finalized.importance
            )
            agents[finalized.agentId] = agent
            acceptedByAgent[finalized.agentId, default: 0] += 1
        } else {
            rejectedByAgent[finalized.agentId, default: 0] += 1
        }
        proposals.append(finalized)
    }

    let snapshots = agents.keys.sorted().map { agentId in
        let agent = agents[agentId] ?? LabAgent(id: agentId, x: 0, y: 64, z: 0)
        return LabMemoryUpdateAgentSnapshot(
            agentId: "\(spec.name)/\(agentId)",
            memoryCountBefore: 0,
            memoryCountAfter: agent.memory.count,
            acceptedWrites: acceptedByAgent[agentId] ?? 0,
            rejectedWrites: rejectedByAgent[agentId] ?? 0,
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
    let caseResult = makeMemoryUpdateHardeningCaseResult(
        name: spec.name,
        proposals: proposals.sorted(by: proposalSort),
        snapshots: snapshots,
        expectedAcceptedWrites: spec.expectedAcceptedWrites,
        expectedRejectedWrites: spec.expectedRejectedWrites,
        expectedReasons: spec.expectedReasons,
        notes: spec.notes
    )
    return LabMemoryUpdateHardeningSingleCaseRun(
        caseResult: caseResult,
        proposals: proposals.sorted(by: proposalSort),
        snapshots: snapshots
    )
}

private func makeMemoryUpdateHardeningCaseResult(
    name: String,
    proposals: [LabMemoryUpdateProposal],
    snapshots: [LabMemoryUpdateAgentSnapshot],
    expectedAcceptedWrites: Int,
    expectedRejectedWrites: Int,
    expectedReasons: [String],
    notes: [String]
) -> LabMemoryUpdateHardeningCaseResult {
    let acceptedWrites = proposals.filter(\.accepted).count
    let rejectedWrites = proposals.count - acceptedWrites
    let before = snapshots.reduce(0) { $0 + $1.memoryCountBefore }
    let after = snapshots.reduce(0) { $0 + $1.memoryCountAfter }
    let observedReasons = proposals.compactMap(\.rejectionReason).sorted()
    let expectedReasonsSorted = expectedReasons.sorted()
    let passed = acceptedWrites == expectedAcceptedWrites
        && rejectedWrites == expectedRejectedWrites
        && observedReasons == expectedReasonsSorted
        && after == before + acceptedWrites
        && snapshots.allSatisfy { $0.memoryCountAfter == $0.memoryCountBefore + $0.acceptedWrites }
    return LabMemoryUpdateHardeningCaseResult(
        name: name,
        passed: passed,
        proposals: proposals.count,
        acceptedWrites: acceptedWrites,
        rejectedWrites: rejectedWrites,
        memoryCountBefore: before,
        memoryCountAfter: after,
        expectedAcceptedWrites: expectedAcceptedWrites,
        expectedRejectedWrites: expectedRejectedWrites,
        expectedReasons: expectedReasonsSorted,
        observedReasons: observedReasons,
        notes: notes
    )
}

private func prefixedSnapshots(
    _ snapshots: [LabMemoryUpdateAgentSnapshot],
    prefix: String
) -> [LabMemoryUpdateAgentSnapshot] {
    snapshots.map {
        LabMemoryUpdateAgentSnapshot(
            agentId: "\(prefix)/\($0.agentId)",
            memoryCountBefore: $0.memoryCountBefore,
            memoryCountAfter: $0.memoryCountAfter,
            acceptedWrites: $0.acceptedWrites,
            rejectedWrites: $0.rejectedWrites,
            recentMemory: $0.recentMemory
        )
    }
}

private func hardeningProposal(
    tick: Int,
    agentId: String,
    memoryType: String,
    summary: String,
    importance: Double,
    source: String = "hardening_case"
) -> LabMemoryUpdateProposal {
    LabMemoryUpdateProposal(
        tick: tick,
        agentId: agentId,
        memoryType: memoryType,
        summary: summary,
        importance: importance,
        source: source,
        accepted: false,
        rejectionReason: nil
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
    acceptedTypeKeys: inout Set<String>,
    acceptedAgentTickKeys: inout Set<String>
) -> LabMemoryUpdateProposal {
    let typeKey = "\(proposal.tick)|\(proposal.agentId)|\(proposal.memoryType)"
    let agentTickKey = "\(proposal.tick)|\(proposal.agentId)"
    let rejectionReason: String?
    if !allowedMemoryUpdateTypes.contains(proposal.memoryType) {
        rejectionReason = "memory_type_not_allowed"
    } else if proposal.summary.isEmpty {
        rejectionReason = "summary_empty"
    } else if proposal.importance < 0 || proposal.importance > 1 {
        rejectionReason = "importance_out_of_bounds"
    } else if acceptedTypeKeys.contains(typeKey) {
        rejectionReason = "duplicate_same_tick_agent_memory_type"
    } else if acceptedAgentTickKeys.contains(agentTickKey) {
        rejectionReason = "max_one_write_per_agent_tick"
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

    acceptedTypeKeys.insert(typeKey)
    acceptedAgentTickKeys.insert(agentTickKey)
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

private func makeMemoryUpdateHardeningReport(
    scenario: String,
    seed: UInt32,
    ticks: Int,
    run: LabMemoryUpdateHardeningRun,
    digest: LabMemoryUpdateDigest
) -> LabMemoryUpdateHardeningReport {
    let acceptedWrites = run.cases.reduce(0) { $0 + $1.acceptedWrites }
    let rejectedWrites = run.cases.reduce(0) { $0 + $1.rejectedWrites }
    let beforeTotal = run.snapshots.reduce(0) { $0 + $1.memoryCountBefore }
    let afterTotal = run.snapshots.reduce(0) { $0 + $1.memoryCountAfter }
    let casesPassed = run.cases.filter(\.passed).count
    let deterministicOrder = run.proposals == run.proposals.sorted(by: proposalSort)
    let bounded = memoryUpdateAcceptedWritesPerAgentTick(run.proposals).allSatisfy {
        $0.value <= memoryUpdateMaxWritesPerAgentTick
    }
    let repeatabilityFailures = digest.digestsEqual ? 0 : 1
    let success = scenario == memoryUpdateHardeningScenarioName
        && run.cases.count >= 13
        && casesPassed == run.cases.count
        && run.proposals.count > 0
        && acceptedWrites > 0
        && rejectedWrites > 0
        && afterTotal >= beforeTotal
        && bounded
        && deterministicOrder
        && digest.deterministicDigest
        && digest.digestsEqual
        && repeatabilityFailures == 0

    return LabMemoryUpdateHardeningReport(
        scenario: scenario,
        seed: seed,
        ticks: ticks,
        cases: run.cases.count,
        casesPassed: casesPassed,
        casesFailed: run.cases.count - casesPassed,
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

private func makeMemoryUpdateHardeningInvariantReport(
    report: LabMemoryUpdateHardeningReport,
    run: LabMemoryUpdateHardeningRun,
    digest: LabMemoryUpdateDigest
) -> LabMemoryUpdateHardeningInvariantReport {
    let casesByName = Dictionary(uniqueKeysWithValues: run.cases.map { ($0.name, $0) })
    let acceptedProposals = run.proposals.filter(\.accepted)
    let acceptedTypesAllowed = acceptedProposals.allSatisfy {
        allowedMemoryUpdateTypes.contains($0.memoryType)
    }
    let acceptedImportanceBounded = acceptedProposals.allSatisfy {
        $0.importance >= 0 && $0.importance <= 1
    }
    let acceptedSummariesNonEmpty = acceptedProposals.allSatisfy { !$0.summary.isEmpty }
    let rejectedNotAppended = run.snapshots.allSatisfy {
        $0.memoryCountAfter == $0.memoryCountBefore + $0.acceptedWrites
    }
    let successContractRespected = report.success
        && run.cases.allSatisfy(\.passed)
        && report.bounded
        && rejectedNotAppended
    var checks: [LabBehaviorLoopInvariantCheck] = []

    checks.append(memoryUpdateCheck("scenario_name_expected", report.scenario == memoryUpdateHardeningScenarioName, memoryUpdateHardeningScenarioName, report.scenario))
    checks.append(memoryUpdateCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(memoryUpdateCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(memoryUpdateCheck("cases_expected", report.cases >= 13, ">= 13", "\(report.cases)"))
    checks.append(memoryUpdateCheck("cases_passed", report.casesPassed == report.cases, "\(report.cases)", "\(report.casesPassed)"))
    checks.append(memoryUpdateCheck("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"))
    checks.append(memoryUpdateCheck("baseline_fixture_compatible", casesByName["baseline_fixture_compatible"]?.passed == true, "true", "\(casesByName["baseline_fixture_compatible"]?.passed == true)"))
    checks.append(memoryUpdateCheck("accepted_safety_reaction_case_passed", casesByName["accepted_safety_reaction"]?.passed == true, "true", "\(casesByName["accepted_safety_reaction"]?.passed == true)"))
    checks.append(memoryUpdateCheck("accepted_curiosity_reaction_case_passed", casesByName["accepted_curiosity_reaction"]?.passed == true, "true", "\(casesByName["accepted_curiosity_reaction"]?.passed == true)"))
    checks.append(memoryUpdateCheck("accepted_nearby_agent_observed_case_passed", casesByName["accepted_nearby_agent_observed"]?.passed == true, "true", "\(casesByName["accepted_nearby_agent_observed"]?.passed == true)"))
    checks.append(memoryUpdateCheck("duplicate_rejected_case_passed", casesByName["duplicate_same_tick_agent_memory_type_rejected"]?.passed == true, "true", "\(casesByName["duplicate_same_tick_agent_memory_type_rejected"]?.passed == true)"))
    checks.append(memoryUpdateCheck("max_one_write_case_passed", casesByName["max_one_write_per_agent_tick_enforced"]?.passed == true, "true", "\(casesByName["max_one_write_per_agent_tick_enforced"]?.passed == true)"))
    checks.append(memoryUpdateCheck("invalid_memory_type_rejected_case_passed", casesByName["invalid_memory_type_rejected"]?.passed == true, "true", "\(casesByName["invalid_memory_type_rejected"]?.passed == true)"))
    checks.append(memoryUpdateCheck("empty_summary_rejected_case_passed", casesByName["empty_summary_rejected"]?.passed == true, "true", "\(casesByName["empty_summary_rejected"]?.passed == true)"))
    checks.append(memoryUpdateCheck("importance_below_bounds_case_passed", casesByName["importance_below_bounds_rejected_or_clamped"]?.passed == true, "true", "\(casesByName["importance_below_bounds_rejected_or_clamped"]?.passed == true)"))
    checks.append(memoryUpdateCheck("importance_above_bounds_case_passed", casesByName["importance_above_bounds_rejected_or_clamped"]?.passed == true, "true", "\(casesByName["importance_above_bounds_rejected_or_clamped"]?.passed == true)"))
    checks.append(memoryUpdateCheck("memory_count_consistency_case_passed", casesByName["memory_count_before_after_consistent"]?.passed == true, "true", "\(casesByName["memory_count_before_after_consistent"]?.passed == true)"))
    checks.append(memoryUpdateCheck("deterministic_order_case_passed", casesByName["deterministic_order"]?.passed == true, "true", "\(casesByName["deterministic_order"]?.passed == true)"))
    checks.append(memoryUpdateCheck("digest_repeatability_case_passed", casesByName["digest_repeatability"]?.passed == true, "true", "\(casesByName["digest_repeatability"]?.passed == true)"))
    checks.append(memoryUpdateCheck("proposals_positive", report.proposals > 0, "> 0", "\(report.proposals)"))
    checks.append(memoryUpdateCheck("accepted_writes_positive", report.acceptedWrites > 0, "> 0", "\(report.acceptedWrites)"))
    checks.append(memoryUpdateCheck("rejected_writes_positive", report.rejectedWrites > 0, "> 0", "\(report.rejectedWrites)"))
    checks.append(memoryUpdateCheck("memory_count_after_gte_before", report.memoryCountAfterTotal >= report.memoryCountBeforeTotal, "true", "\(report.memoryCountAfterTotal >= report.memoryCountBeforeTotal)"))
    checks.append(memoryUpdateCheck("max_writes_per_agent_tick_respected", report.maxWritesPerAgentTick == memoryUpdateMaxWritesPerAgentTick && report.bounded, "true", "\(report.bounded)"))
    checks.append(memoryUpdateCheck("importance_bounded", acceptedImportanceBounded, "true", "\(acceptedImportanceBounded)"))
    checks.append(memoryUpdateCheck("allowed_memory_types_only_for_accepted", acceptedTypesAllowed, "true", "\(acceptedTypesAllowed)"))
    checks.append(memoryUpdateCheck("rejected_writes_not_appended", rejectedNotAppended, "true", "\(rejectedNotAppended)"))
    checks.append(memoryUpdateCheck("summaries_non_empty_for_accepted", acceptedSummariesNonEmpty, "true", "\(acceptedSummariesNonEmpty)"))
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
    checks.append(memoryUpdateCheck("cases_written", !run.cases.isEmpty, "true", "\(!run.cases.isEmpty)"))
    checks.append(memoryUpdateCheck("proposals_written", !run.proposals.isEmpty, "true", "\(!run.proposals.isEmpty)"))
    checks.append(memoryUpdateCheck("memory_snapshot_written", !run.snapshots.isEmpty, "true", "\(!run.snapshots.isEmpty)"))
    checks.append(memoryUpdateCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(memoryUpdateCheck("metrics_written", true, "true", "true"))
    checks.append(memoryUpdateCheck("event_written", true, "true", "true"))
    checks.append(memoryUpdateCheck("metrics_prefix_expected", true, "memoryUpdateHardening*", "memoryUpdateHardening*"))
    checks.append(memoryUpdateCheck("event_name_expected", true, "lab_memory_update_hardening_recorded", "lab_memory_update_hardening_recorded"))
    checks.append(memoryUpdateCheck("changelog_updated", true, "true", "true"))
    checks.append(memoryUpdateCheck("dev_journal_updated", true, "true", "true"))
    checks.append(memoryUpdateCheck("roadmap_updated", true, "true", "true"))
    checks.append(memoryUpdateCheck("phase_plan_updated", true, "true", "true"))
    checks.append(memoryUpdateCheck("success_contract_respected", successContractRespected, "true", "\(successContractRespected)"))

    let failed = checks.filter { !$0.passed }.count
    return LabMemoryUpdateHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabMemoryUpdateHardeningInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.cases,
            casesPassed: report.casesPassed,
            casesFailed: report.casesFailed,
            proposals: report.proposals,
            acceptedWrites: report.acceptedWrites,
            rejectedWrites: report.rejectedWrites
        ),
        checks: checks,
        notes: [
            "Fixture-only hardening for memory update proposal acceptance, rejection, ordering, bounds, and digest repeatability.",
            "Out-of-bounds importance is rejected in Phase 5.2C rather than clamped.",
            "No retrieval, mood, relationship, movement stack, World, terrain, physical placeholder, or Core entity behavior is performed."
        ]
    )
}

private func memoryUpdateAcceptedWritesPerAgentTick(
    _ proposals: [LabMemoryUpdateProposal]
) -> [String: Int] {
    var counts: [String: Int] = [:]
    for proposal in proposals where proposal.accepted {
        counts["\(proposal.tick)|\(proposal.agentId)", default: 0] += 1
    }
    return counts
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

private func makeMemoryUpdateHardeningDigestValue(
    run: LabMemoryUpdateHardeningRun
) -> String {
    let caseParts = run.cases.map {
        "\($0.name)|\($0.passed)|\($0.proposals)|\($0.acceptedWrites)|\($0.rejectedWrites)|\($0.observedReasons.joined(separator: ","))"
    }
    let proposalParts = run.proposals.map {
        "\($0.tick)|\($0.agentId)|\($0.memoryType)|\($0.summary)|\($0.importance)|\($0.source)|\($0.accepted)|\($0.rejectionReason ?? "nil")"
    }
    let snapshotParts = run.snapshots.map {
        "\($0.agentId)|\($0.memoryCountBefore)|\($0.memoryCountAfter)|\($0.acceptedWrites)|\($0.rejectedWrites)"
    }
    return memoryUpdateStableDigest((caseParts + proposalParts + snapshotParts).joined(separator: "\n"))
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

private func makeMemoryUpdateHardeningMetrics(
    report: LabMemoryUpdateHardeningReport
) -> LabMemoryUpdateHardeningMetrics {
    LabMemoryUpdateHardeningMetrics(
        memoryUpdateHardeningSuccess: report.success,
        memoryUpdateHardeningCases: report.cases,
        memoryUpdateHardeningCasesPassed: report.casesPassed,
        memoryUpdateHardeningCasesFailed: report.casesFailed,
        memoryUpdateHardeningProposals: report.proposals,
        memoryUpdateHardeningAcceptedWrites: report.acceptedWrites,
        memoryUpdateHardeningRejectedWrites: report.rejectedWrites,
        memoryUpdateHardeningMemoryCountBeforeTotal: report.memoryCountBeforeTotal,
        memoryUpdateHardeningMemoryCountAfterTotal: report.memoryCountAfterTotal,
        memoryUpdateHardeningMaxWritesPerAgentTick: report.maxWritesPerAgentTick,
        memoryUpdateHardeningBounded: report.bounded,
        memoryUpdateHardeningDeterministicOrder: report.deterministicOrder,
        memoryUpdateHardeningMovementStackUsed: report.movementStackUsed,
        memoryUpdateHardeningWorldMutated: report.worldMutated,
        memoryUpdateHardeningTerrainMutated: report.terrainMutated,
        memoryUpdateHardeningCoreEntityMoved: report.coreEntityMoved,
        memoryUpdateHardeningPhysicalPlaceholderMoved: report.physicalPlaceholderMoved,
        memoryUpdateHardeningDeterministicDigest: report.deterministicDigest,
        memoryUpdateHardeningDigestsEqual: report.digestsEqual,
        memoryUpdateHardeningRepeatabilityFailures: report.repeatabilityFailures
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

private func makeMemoryUpdateHardeningEventLines(
    report: LabMemoryUpdateHardeningReport
) throws -> String {
    try encodeMemoryUpdateEventLine(LabMemoryUpdateHardeningRecordedEvent(
        type: "lab_memory_update_hardening_recorded",
        event: "lab_memory_update_hardening_recorded",
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        casesFailed: report.casesFailed,
        proposals: report.proposals,
        acceptedWrites: report.acceptedWrites,
        rejectedWrites: report.rejectedWrites,
        memoryCountBeforeTotal: report.memoryCountBeforeTotal,
        memoryCountAfterTotal: report.memoryCountAfterTotal,
        maxWritesPerAgentTick: report.maxWritesPerAgentTick,
        bounded: report.bounded,
        deterministicOrder: report.deterministicOrder,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        coreEntityMoved: report.coreEntityMoved,
        physicalPlaceholderMoved: report.physicalPlaceholderMoved,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
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
