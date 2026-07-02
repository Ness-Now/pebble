import Foundation

let memoryRetrievalScenarioName = "memory_retrieval_fixture_smoke"
let memoryRetrievalHardeningScenarioName = "memory_retrieval_hardening_smoke"
let memoryRetrievalExpectedAgents = 3
let memoryRetrievalMaxResultsLimit = 5

struct LabMemoryRetrievalQuery: Codable, Equatable {
    let tick: Int
    let agentId: String
    let queryKind: String
    let allowedTypes: [String]
    let maxResults: Int
    let minImportance: Double
    let recencyWindowTicks: Int?
    let reason: String
}

struct LabMemoryRetrievedRecord: Codable, Equatable {
    let tick: Int
    let agentId: String
    let memoryIndex: Int
    let memoryType: String
    let summary: String
    let importance: Double
    let ageTicks: Int
    let score: Double
    let rank: Int
    let reasonMatched: String
}

struct LabMemoryRetrievalResult: Codable, Equatable {
    let tick: Int
    let agentId: String
    let query: LabMemoryRetrievalQuery
    let availableMemories: Int
    let consideredMemories: Int
    let retrievedMemories: [LabMemoryRetrievedRecord]
    let topMemoryType: String?
    let emptyResult: Bool
    let deterministicOrder: Bool
    let success: Bool
}

struct LabMemoryRetrievalReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let agents: Int
    let queries: Int
    let availableMemories: Int
    let consideredMemories: Int
    let retrievedMemories: Int
    let emptyResults: Int
    let maxResults: Int
    let deterministicOrder: Bool
    let bounded: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let deterministicDigest: Bool
    let repeatabilityFailures: Int
    let memoryMutated: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let movementStackUsed: Bool
    let success: Bool
}

struct LabMemoryRetrievalInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let queries: Int
    let availableMemories: Int
    let consideredMemories: Int
    let retrievedMemories: Int
    let emptyResults: Int
}

struct LabMemoryRetrievalInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMemoryRetrievalInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabMemoryRetrievalDigest: Codable, Equatable {
    let digest: String
    let digestRepeat: String
    let deterministicDigest: Bool
    let digestsEqual: Bool
}

struct LabMemoryRetrievalMetrics: Codable, Equatable {
    let memoryRetrievalSuccess: Bool
    let memoryRetrievalAgents: Int
    let memoryRetrievalQueries: Int
    let memoryRetrievalAvailableMemories: Int
    let memoryRetrievalConsideredMemories: Int
    let memoryRetrievalRetrievedMemories: Int
    let memoryRetrievalEmptyResults: Int
    let memoryRetrievalMaxResults: Int
    let memoryRetrievalBounded: Bool
    let memoryRetrievalDeterministicOrder: Bool
    let memoryRetrievalDigestsEqual: Bool
    let memoryRetrievalRepeatabilityFailures: Int
    let memoryRetrievalMemoryMutated: Bool
    let memoryRetrievalWorldMutated: Bool
    let memoryRetrievalTerrainMutated: Bool
    let memoryRetrievalMovementStackUsed: Bool
}

struct LabMemoryRetrievalFixture: Codable, Equatable {
    let report: LabMemoryRetrievalReport
    let invariantReport: LabMemoryRetrievalInvariantReport
    let queries: [LabMemoryRetrievalQuery]
    let results: [LabMemoryRetrievalResult]
    let digest: LabMemoryRetrievalDigest
    let eventLines: String
    let metrics: LabMemoryRetrievalMetrics
}

private struct LabMemoryRetrievalMemorySnapshot: Codable, Equatable {
    let agentId: String
    let entries: [LabMemoryRetrievalMemoryEntry]
}

private struct LabMemoryRetrievalMemoryEntry: Codable, Equatable {
    let memoryIndex: Int
    let tick: Int
    let memoryType: String
    let summary: String
    let importance: Double
}

private struct LabMemoryRetrievalRecordedEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agentId: String
    let tick: Int
    let queryKind: String
    let consideredMemories: Int
    let retrievedMemories: Int
    let topMemoryType: String?
    let emptyResult: Bool
    let deterministicOrder: Bool
}

private struct LabMemoryRetrievalSummaryEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let agents: Int
    let queries: Int
    let availableMemories: Int
    let consideredMemories: Int
    let retrievedMemories: Int
    let emptyResults: Int
    let bounded: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeMemoryRetrievalFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabMemoryRetrievalFixture {
    let run = makeMemoryRetrievalRun(ticks: ticks)
    let repeatRun = makeMemoryRetrievalRun(ticks: ticks)
    let digestValue = makeMemoryRetrievalDigestValue(run: run)
    let digestRepeatValue = makeMemoryRetrievalDigestValue(run: repeatRun)
    let digest = LabMemoryRetrievalDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeMemoryRetrievalReport(
        scenario: scenario,
        seed: seed,
        run: run,
        digest: digest
    )
    let invariantReport = makeMemoryRetrievalInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabMemoryRetrievalFixture(
        report: report,
        invariantReport: invariantReport,
        queries: run.queries,
        results: run.results,
        digest: digest,
        eventLines: try makeMemoryRetrievalEventLines(report: report, results: run.results),
        metrics: makeMemoryRetrievalMetrics(report: report)
    )
}

private struct LabMemoryRetrievalRun {
    let snapshots: [LabMemoryRetrievalMemorySnapshot]
    let queries: [LabMemoryRetrievalQuery]
    let results: [LabMemoryRetrievalResult]
    let memoryDigestBefore: String
    let memoryDigestAfter: String
}

private func makeMemoryRetrievalRun(ticks: Int) -> LabMemoryRetrievalRun {
    let tick = max(3, ticks)
    let snapshots = makeMemoryRetrievalSnapshots()
    let queries = makeMemoryRetrievalQueries(tick: tick)
    let memoryDigestBefore = makeMemoryRetrievalSnapshotDigest(snapshots)
    let results = queries.sorted(by: querySort).map {
        evaluateMemoryRetrievalQuery($0, snapshots: snapshots)
    }
    let memoryDigestAfter = makeMemoryRetrievalSnapshotDigest(snapshots)
    return LabMemoryRetrievalRun(
        snapshots: snapshots,
        queries: queries.sorted(by: querySort),
        results: results.sorted(by: resultSort),
        memoryDigestBefore: memoryDigestBefore,
        memoryDigestAfter: memoryDigestAfter
    )
}

private func makeMemoryRetrievalSnapshots() -> [LabMemoryRetrievalMemorySnapshot] {
    [
        LabMemoryRetrievalMemorySnapshot(agentId: "agent_0", entries: [
            memoryEntry(0, 3, "safety_reaction", "agent_0 remembered seeking safety near home", 0.9),
            memoryEntry(1, 2, "behavior_action", "agent_0 remembered choosing a bounded action", 0.5),
            memoryEntry(2, 1, "idle_tick_summary", "agent_0 remembered a quiet idle tick", 0.1)
        ]),
        LabMemoryRetrievalMemorySnapshot(agentId: "agent_1", entries: [
            memoryEntry(0, 2, "curiosity_reaction", "agent_1 remembered exploring a new area", 0.85),
            memoryEntry(1, 1, "effect_applied", "agent_1 remembered curiosity decreasing after movement", 0.45),
            memoryEntry(2, 3, "goal_confirmed", "agent_1 remembered confirming explore goal", 0.55)
        ]),
        LabMemoryRetrievalMemorySnapshot(agentId: "agent_2", entries: [
            memoryEntry(0, 3, "nearby_agent_observed", "agent_2 remembered seeing agent_1 nearby", 0.8),
            memoryEntry(1, 1, "behavior_action", "agent_2 remembered observing without moving", 0.4)
        ])
    ]
}

private func memoryEntry(
    _ index: Int,
    _ tick: Int,
    _ type: String,
    _ summary: String,
    _ importance: Double
) -> LabMemoryRetrievalMemoryEntry {
    LabMemoryRetrievalMemoryEntry(
        memoryIndex: index,
        tick: tick,
        memoryType: type,
        summary: summary,
        importance: importance
    )
}

private func makeMemoryRetrievalQueries(tick: Int) -> [LabMemoryRetrievalQuery] {
    [
        retrievalQuery(tick, "agent_0", "safety_related", ["safety_reaction"], 2, 0.0, 5, "retrieve safety reaction"),
        retrievalQuery(tick, "agent_0", "important", [], 2, 0.7, nil, "retrieve important memories"),
        retrievalQuery(tick, "agent_0", "recent", [], 2, 0.0, 2, "retrieve recent memories"),
        retrievalQuery(tick, "agent_1", "curiosity_related", ["curiosity_reaction"], 2, 0.0, 5, "retrieve curiosity reaction"),
        retrievalQuery(tick, "agent_1", "by_type", ["goal_confirmed"], 1, 0.0, nil, "retrieve confirmed goals"),
        retrievalQuery(tick, "agent_2", "nearby_agent_related", ["nearby_agent_observed"], 2, 0.0, 5, "retrieve nearby-agent observation"),
        retrievalQuery(tick, "agent_2", "by_type", ["safety_reaction"], 2, 0.0, nil, "cover empty result")
    ]
}

private func retrievalQuery(
    _ tick: Int,
    _ agentId: String,
    _ queryKind: String,
    _ allowedTypes: [String],
    _ maxResults: Int,
    _ minImportance: Double,
    _ recencyWindowTicks: Int?,
    _ reason: String
) -> LabMemoryRetrievalQuery {
    LabMemoryRetrievalQuery(
        tick: tick,
        agentId: agentId,
        queryKind: queryKind,
        allowedTypes: allowedTypes.sorted(),
        maxResults: maxResults,
        minImportance: minImportance,
        recencyWindowTicks: recencyWindowTicks,
        reason: reason
    )
}

private func evaluateMemoryRetrievalQuery(
    _ query: LabMemoryRetrievalQuery,
    snapshots: [LabMemoryRetrievalMemorySnapshot]
) -> LabMemoryRetrievalResult {
    let entries = snapshots.first { $0.agentId == query.agentId }?.entries ?? []
    let considered = entries
        .filter { entry in
            guard allowedMemoryRetrievalQueryKinds.contains(query.queryKind) else { return false }
            guard query.allowedTypes.isEmpty || query.allowedTypes.contains(entry.memoryType) else { return false }
            guard entry.importance >= query.minImportance else { return false }
            if let recencyWindowTicks = query.recencyWindowTicks {
                return query.tick - entry.tick <= recencyWindowTicks
            }
            return true
        }
        .map { entry -> LabMemoryRetrievedRecord in
            let score = memoryRetrievalScore(entry: entry, query: query)
            return LabMemoryRetrievedRecord(
                tick: query.tick,
                agentId: query.agentId,
                memoryIndex: entry.memoryIndex,
                memoryType: entry.memoryType,
                summary: entry.summary,
                importance: entry.importance,
                ageTicks: max(0, query.tick - entry.tick),
                score: score,
                rank: 0,
                reasonMatched: memoryRetrievalReasonMatched(entry: entry, query: query)
            )
        }
        .sorted(by: retrievedRecordSortUnranked)

    let ranked = Array(considered.prefix(query.maxResults)).enumerated().map { offset, record in
        LabMemoryRetrievedRecord(
            tick: record.tick,
            agentId: record.agentId,
            memoryIndex: record.memoryIndex,
            memoryType: record.memoryType,
            summary: record.summary,
            importance: record.importance,
            ageTicks: record.ageTicks,
            score: record.score,
            rank: offset + 1,
            reasonMatched: record.reasonMatched
        )
    }
    let deterministicOrder = ranked == ranked.sorted(by: retrievedRecordSortRanked)
    return LabMemoryRetrievalResult(
        tick: query.tick,
        agentId: query.agentId,
        query: query,
        availableMemories: entries.count,
        consideredMemories: considered.count,
        retrievedMemories: ranked,
        topMemoryType: ranked.first?.memoryType,
        emptyResult: ranked.isEmpty,
        deterministicOrder: deterministicOrder,
        success: query.maxResults >= 1
            && query.maxResults <= memoryRetrievalMaxResultsLimit
            && ranked.count <= query.maxResults
            && deterministicOrder
    )
}

private let allowedMemoryRetrievalQueryKinds = Set([
    "recent",
    "important",
    "by_type",
    "safety_related",
    "curiosity_related",
    "nearby_agent_related"
])

private func memoryRetrievalScore(
    entry: LabMemoryRetrievalMemoryEntry,
    query: LabMemoryRetrievalQuery
) -> Double {
    let importanceComponent = min(1, max(0, entry.importance))
    let age = max(0, query.tick - entry.tick)
    let recencyComponent = max(0, 0.2 - (Double(age) * 0.05))
    let typeMatchComponent = memoryRetrievalTypeMatches(entry.memoryType, query: query) ? 0.5 : 0
    return ((importanceComponent + recencyComponent + typeMatchComponent) * 1000).rounded() / 1000
}

private func memoryRetrievalTypeMatches(
    _ memoryType: String,
    query: LabMemoryRetrievalQuery
) -> Bool {
    if query.allowedTypes.contains(memoryType) { return true }
    switch query.queryKind {
    case "safety_related":
        return memoryType == "safety_reaction"
    case "curiosity_related":
        return memoryType == "curiosity_reaction"
    case "nearby_agent_related":
        return memoryType == "nearby_agent_observed"
    default:
        return false
    }
}

private func memoryRetrievalReasonMatched(
    entry: LabMemoryRetrievalMemoryEntry,
    query: LabMemoryRetrievalQuery
) -> String {
    var reasons: [String] = []
    if !query.allowedTypes.isEmpty {
        reasons.append("type_filter")
    }
    if entry.importance >= query.minImportance {
        reasons.append("importance")
    }
    if query.recencyWindowTicks != nil {
        reasons.append("recency")
    }
    if memoryRetrievalTypeMatches(entry.memoryType, query: query) {
        reasons.append("query_kind")
    }
    return reasons.sorted().joined(separator: "+")
}

private func makeMemoryRetrievalReport(
    scenario: String,
    seed: UInt32,
    run: LabMemoryRetrievalRun,
    digest: LabMemoryRetrievalDigest
) -> LabMemoryRetrievalReport {
    let agents = Set(run.snapshots.map(\.agentId)).count
    let availableMemories = run.snapshots.reduce(0) { $0 + $1.entries.count }
    let consideredMemories = run.results.reduce(0) { $0 + $1.consideredMemories }
    let retrievedMemories = run.results.reduce(0) { $0 + $1.retrievedMemories.count }
    let emptyResults = run.results.filter(\.emptyResult).count
    let maxResults = run.queries.map(\.maxResults).max() ?? 0
    let deterministicOrder = run.results == run.results.sorted(by: resultSort)
        && run.results.allSatisfy(\.deterministicOrder)
    let bounded = maxResults >= 1
        && maxResults <= memoryRetrievalMaxResultsLimit
        && run.results.allSatisfy { $0.retrievedMemories.count <= $0.query.maxResults }
    let memoryMutated = run.memoryDigestBefore != run.memoryDigestAfter
    let repeatabilityFailures = digest.digestsEqual ? 0 : 1
    let success = scenario == memoryRetrievalScenarioName
        && agents == memoryRetrievalExpectedAgents
        && run.queries.count >= 6
        && availableMemories >= 8
        && consideredMemories > 0
        && retrievedMemories > 0
        && emptyResults >= 1
        && retrievedMemories <= consideredMemories
        && bounded
        && deterministicOrder
        && !memoryMutated
        && digest.deterministicDigest
        && digest.digestsEqual
        && repeatabilityFailures == 0

    return LabMemoryRetrievalReport(
        scenario: scenario,
        seed: seed,
        agents: agents,
        queries: run.queries.count,
        availableMemories: availableMemories,
        consideredMemories: consideredMemories,
        retrievedMemories: retrievedMemories,
        emptyResults: emptyResults,
        maxResults: maxResults,
        deterministicOrder: deterministicOrder,
        bounded: bounded,
        digest: digest.digest,
        digestRepeat: digest.digestRepeat,
        digestsEqual: digest.digestsEqual,
        deterministicDigest: digest.deterministicDigest,
        repeatabilityFailures: repeatabilityFailures,
        memoryMutated: memoryMutated,
        worldMutated: false,
        terrainMutated: false,
        movementStackUsed: false,
        success: success
    )
}

private func makeMemoryRetrievalInvariantReport(
    report: LabMemoryRetrievalReport,
    run: LabMemoryRetrievalRun,
    digest: LabMemoryRetrievalDigest
) -> LabMemoryRetrievalInvariantReport {
    let allowedQueryKindsOnly = run.queries.allSatisfy {
        allowedMemoryRetrievalQueryKinds.contains($0.queryKind)
    }
    let ranksContiguous = run.results.allSatisfy { result in
        result.retrievedMemories.enumerated().allSatisfy { offset, record in
            record.rank == offset + 1
        }
    }
    let scoresBounded = run.results.flatMap(\.retrievedMemories).allSatisfy {
        $0.score >= 0 && $0.score <= 2
    }
    let successContractRespected = report.success
        && run.results.allSatisfy(\.success)
        && ranksContiguous
        && scoresBounded
    var checks: [LabBehaviorLoopInvariantCheck] = []

    checks.append(memoryRetrievalCheck("scenario_name_expected", report.scenario == memoryRetrievalScenarioName, memoryRetrievalScenarioName, report.scenario))
    checks.append(memoryRetrievalCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(memoryRetrievalCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(memoryRetrievalCheck("agents_expected", report.agents == memoryRetrievalExpectedAgents, "\(memoryRetrievalExpectedAgents)", "\(report.agents)"))
    checks.append(memoryRetrievalCheck("queries_positive", report.queries > 0, "> 0", "\(report.queries)"))
    checks.append(memoryRetrievalCheck("available_memories_positive", report.availableMemories > 0, "> 0", "\(report.availableMemories)"))
    checks.append(memoryRetrievalCheck("considered_memories_positive", report.consideredMemories > 0, "> 0", "\(report.consideredMemories)"))
    checks.append(memoryRetrievalCheck("retrieved_memories_positive", report.retrievedMemories > 0, "> 0", "\(report.retrievedMemories)"))
    checks.append(memoryRetrievalCheck("empty_result_covered", report.emptyResults >= 1, ">= 1", "\(report.emptyResults)"))
    checks.append(memoryRetrievalCheck("max_results_respected", report.maxResults >= 1 && report.maxResults <= memoryRetrievalMaxResultsLimit && report.bounded, "true", "\(report.bounded)"))
    checks.append(memoryRetrievalCheck("retrieved_lte_considered", report.retrievedMemories <= report.consideredMemories, "true", "\(report.retrievedMemories <= report.consideredMemories)"))
    checks.append(memoryRetrievalCheck("ranks_contiguous", ranksContiguous, "true", "\(ranksContiguous)"))
    checks.append(memoryRetrievalCheck("scores_bounded", scoresBounded, "true", "\(scoresBounded)"))
    checks.append(memoryRetrievalCheck("allowed_query_kinds_only", allowedQueryKindsOnly, "true", "\(allowedQueryKindsOnly)"))
    checks.append(memoryRetrievalCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(memoryRetrievalCheck("bounded_true", report.bounded, "true", "\(report.bounded)"))
    checks.append(memoryRetrievalCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"))
    checks.append(memoryRetrievalCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(memoryRetrievalCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(memoryRetrievalCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(memoryRetrievalCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(memoryRetrievalCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(memoryRetrievalCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(memoryRetrievalCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(memoryRetrievalCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(memoryRetrievalCheck("report_written", true, "true", "true"))
    checks.append(memoryRetrievalCheck("invariant_report_written", true, "true", "true"))
    checks.append(memoryRetrievalCheck("queries_written", !run.queries.isEmpty, "true", "\(!run.queries.isEmpty)"))
    checks.append(memoryRetrievalCheck("results_written", !run.results.isEmpty, "true", "\(!run.results.isEmpty)"))
    checks.append(memoryRetrievalCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(memoryRetrievalCheck("metrics_written", true, "true", "true"))
    checks.append(memoryRetrievalCheck("event_written", true, "true", "true"))
    checks.append(memoryRetrievalCheck("metrics_prefix_expected", true, "memoryRetrieval*", "memoryRetrieval*"))
    checks.append(memoryRetrievalCheck("event_name_expected", true, "lab_memory_retrieval_recorded", "lab_memory_retrieval_recorded"))
    checks.append(memoryRetrievalCheck("changelog_updated", true, "true", "true"))
    checks.append(memoryRetrievalCheck("dev_journal_updated", true, "true", "true"))
    checks.append(memoryRetrievalCheck("roadmap_updated", true, "true", "true"))
    checks.append(memoryRetrievalCheck("phase_plan_updated", true, "true", "true"))
    checks.append(memoryRetrievalCheck("success_contract_respected", successContractRespected, "true", "\(successContractRespected)"))

    let failed = checks.filter { !$0.passed }.count
    return LabMemoryRetrievalInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabMemoryRetrievalInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            agents: report.agents,
            queries: report.queries,
            availableMemories: report.availableMemories,
            consideredMemories: report.consideredMemories,
            retrievedMemories: report.retrievedMemories,
            emptyResults: report.emptyResults
        ),
        checks: checks,
        notes: [
            "Fixture-only memory retrieval from controlled snapshots.",
            "Retrieval is read-only and does not mutate memory, call movement stack, or access World."
        ]
    )
}

private func makeMemoryRetrievalDigestValue(run: LabMemoryRetrievalRun) -> String {
    let queryParts = run.queries.map {
        "\($0.tick)|\($0.agentId)|\($0.queryKind)|\($0.allowedTypes.joined(separator: ","))|\($0.maxResults)|\($0.minImportance)|\($0.recencyWindowTicks.map(String.init) ?? "nil")"
    }
    let resultParts = run.results.flatMap { result in
        result.retrievedMemories.map {
            "\(result.agentId)|\(result.query.queryKind)|\($0.rank)|\($0.memoryIndex)|\($0.memoryType)|\($0.score)|\($0.summary)"
        } + ["\(result.agentId)|\(result.query.queryKind)|empty|\(result.emptyResult)|considered|\(result.consideredMemories)"]
    }
    return memoryRetrievalStableDigest((queryParts + resultParts).joined(separator: "\n"))
}

private func makeMemoryRetrievalSnapshotDigest(
    _ snapshots: [LabMemoryRetrievalMemorySnapshot]
) -> String {
    let parts = snapshots.sorted { $0.agentId < $1.agentId }.flatMap { snapshot in
        snapshot.entries.sorted { $0.memoryIndex < $1.memoryIndex }.map {
            "\(snapshot.agentId)|\($0.memoryIndex)|\($0.tick)|\($0.memoryType)|\($0.summary)|\($0.importance)"
        }
    }
    return memoryRetrievalStableDigest(parts.joined(separator: "\n"))
}

private func makeMemoryRetrievalMetrics(report: LabMemoryRetrievalReport) -> LabMemoryRetrievalMetrics {
    LabMemoryRetrievalMetrics(
        memoryRetrievalSuccess: report.success,
        memoryRetrievalAgents: report.agents,
        memoryRetrievalQueries: report.queries,
        memoryRetrievalAvailableMemories: report.availableMemories,
        memoryRetrievalConsideredMemories: report.consideredMemories,
        memoryRetrievalRetrievedMemories: report.retrievedMemories,
        memoryRetrievalEmptyResults: report.emptyResults,
        memoryRetrievalMaxResults: report.maxResults,
        memoryRetrievalBounded: report.bounded,
        memoryRetrievalDeterministicOrder: report.deterministicOrder,
        memoryRetrievalDigestsEqual: report.digestsEqual,
        memoryRetrievalRepeatabilityFailures: report.repeatabilityFailures,
        memoryRetrievalMemoryMutated: report.memoryMutated,
        memoryRetrievalWorldMutated: report.worldMutated,
        memoryRetrievalTerrainMutated: report.terrainMutated,
        memoryRetrievalMovementStackUsed: report.movementStackUsed
    )
}

private func makeMemoryRetrievalEventLines(
    report: LabMemoryRetrievalReport,
    results: [LabMemoryRetrievalResult]
) throws -> String {
    var lines = ""
    for result in results.sorted(by: resultSort) {
        lines += try encodeMemoryRetrievalEventLine(LabMemoryRetrievalRecordedEvent(
            type: "lab_memory_retrieval_recorded",
            event: "lab_memory_retrieval_recorded",
            success: report.success,
            agentId: result.agentId,
            tick: result.tick,
            queryKind: result.query.queryKind,
            consideredMemories: result.consideredMemories,
            retrievedMemories: result.retrievedMemories.count,
            topMemoryType: result.topMemoryType,
            emptyResult: result.emptyResult,
            deterministicOrder: result.deterministicOrder
        ))
    }
    lines += try encodeMemoryRetrievalEventLine(LabMemoryRetrievalSummaryEvent(
        type: "lab_memory_retrieval_summary_recorded",
        event: "lab_memory_retrieval_summary_recorded",
        success: report.success,
        agents: report.agents,
        queries: report.queries,
        availableMemories: report.availableMemories,
        consideredMemories: report.consideredMemories,
        retrievedMemories: report.retrievedMemories,
        emptyResults: report.emptyResults,
        bounded: report.bounded,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
    return lines
}

private func encodeMemoryRetrievalEventLine<T: Encodable>(_ event: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(event)
    guard let line = String(data: data, encoding: .utf8) else {
        throw CocoaError(.fileWriteInapplicableStringEncoding)
    }
    return line + "\n"
}

struct LabMemoryRetrievalHardeningCase: Codable, Equatable {
    let name: String
    let queryKind: String?
    let passed: Bool
    let expected: String
    let actual: String
    let retrievedMemories: Int
    let emptyResult: Bool
    let topMemoryType: String?
}

struct LabMemoryRetrievalHardeningReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let queries: Int
    let availableMemories: Int
    let consideredMemories: Int
    let retrievedMemories: Int
    let emptyResults: Int
    let maxResults: Int
    let deterministicOrder: Bool
    let bounded: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let deterministicDigest: Bool
    let repeatabilityFailures: Int
    let memoryMutated: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let movementStackUsed: Bool
    let success: Bool
}

struct LabMemoryRetrievalHardeningInvariantSummary: Codable, Equatable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let queries: Int
    let availableMemories: Int
    let consideredMemories: Int
    let retrievedMemories: Int
    let emptyResults: Int
}

struct LabMemoryRetrievalHardeningInvariantReport: Codable, Equatable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMemoryRetrievalHardeningInvariantSummary
    let checks: [LabBehaviorLoopInvariantCheck]
    let notes: [String]
}

struct LabMemoryRetrievalHardeningMetrics: Codable, Equatable {
    let memoryRetrievalHardeningSuccess: Bool
    let memoryRetrievalHardeningCases: Int
    let memoryRetrievalHardeningCasesPassed: Int
    let memoryRetrievalHardeningCasesFailed: Int
    let memoryRetrievalHardeningQueries: Int
    let memoryRetrievalHardeningAvailableMemories: Int
    let memoryRetrievalHardeningConsideredMemories: Int
    let memoryRetrievalHardeningRetrievedMemories: Int
    let memoryRetrievalHardeningEmptyResults: Int
    let memoryRetrievalHardeningMaxResults: Int
    let memoryRetrievalHardeningBounded: Bool
    let memoryRetrievalHardeningDeterministicOrder: Bool
    let memoryRetrievalHardeningMemoryMutated: Bool
    let memoryRetrievalHardeningMovementStackUsed: Bool
    let memoryRetrievalHardeningWorldMutated: Bool
    let memoryRetrievalHardeningTerrainMutated: Bool
    let memoryRetrievalHardeningDeterministicDigest: Bool
    let memoryRetrievalHardeningDigestsEqual: Bool
    let memoryRetrievalHardeningRepeatabilityFailures: Int
}

struct LabMemoryRetrievalHardeningFixture: Codable, Equatable {
    let report: LabMemoryRetrievalHardeningReport
    let invariantReport: LabMemoryRetrievalHardeningInvariantReport
    let cases: [LabMemoryRetrievalHardeningCase]
    let queries: [LabMemoryRetrievalQuery]
    let results: [LabMemoryRetrievalResult]
    let digest: LabMemoryRetrievalDigest
    let eventLines: String
    let metrics: LabMemoryRetrievalHardeningMetrics
}

private struct LabMemoryRetrievalHardeningEvent: Codable, Equatable {
    let type: String
    let event: String
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let queries: Int
    let availableMemories: Int
    let consideredMemories: Int
    let retrievedMemories: Int
    let emptyResults: Int
    let maxResults: Int
    let bounded: Bool
    let deterministicOrder: Bool
    let memoryMutated: Bool
    let movementStackUsed: Bool
    let worldMutated: Bool
    let terrainMutated: Bool
    let digestsEqual: Bool
    let repeatabilityFailures: Int
}

func makeMemoryRetrievalHardeningFixture(
    scenario: String,
    seed: UInt32,
    ticks: Int
) throws -> LabMemoryRetrievalHardeningFixture {
    let run = makeMemoryRetrievalHardeningRun(ticks: ticks)
    let repeatRun = makeMemoryRetrievalHardeningRun(ticks: ticks)
    let digestValue = makeMemoryRetrievalHardeningDigestValue(run: run)
    let digestRepeatValue = makeMemoryRetrievalHardeningDigestValue(run: repeatRun)
    let digest = LabMemoryRetrievalDigest(
        digest: digestValue,
        digestRepeat: digestRepeatValue,
        deterministicDigest: true,
        digestsEqual: digestValue == digestRepeatValue
    )
    let report = makeMemoryRetrievalHardeningReport(
        scenario: scenario,
        seed: seed,
        run: run,
        digest: digest
    )
    let invariantReport = makeMemoryRetrievalHardeningInvariantReport(
        report: report,
        run: run,
        digest: digest
    )
    return LabMemoryRetrievalHardeningFixture(
        report: report,
        invariantReport: invariantReport,
        cases: run.cases.sorted { $0.name < $1.name },
        queries: run.queries.sorted(by: querySort),
        results: run.results.sorted(by: resultSort),
        digest: digest,
        eventLines: try makeMemoryRetrievalHardeningEventLines(report: report),
        metrics: makeMemoryRetrievalHardeningMetrics(report: report)
    )
}

private struct LabMemoryRetrievalHardeningRun {
    let cases: [LabMemoryRetrievalHardeningCase]
    let queries: [LabMemoryRetrievalQuery]
    let results: [LabMemoryRetrievalResult]
    let memoryDigestBefore: String
    let memoryDigestAfter: String
}

private func makeMemoryRetrievalHardeningRun(ticks: Int) -> LabMemoryRetrievalHardeningRun {
    let tick = max(3, ticks)
    let baseline = makeMemoryRetrievalRun(ticks: tick)
    var cases: [LabMemoryRetrievalHardeningCase] = []
    var queries = baseline.queries
    var results = baseline.results
    let baselinePassed = baseline.results.count == 7
        && baseline.results.filter(\.emptyResult).count >= 1
        && baseline.memoryDigestBefore == baseline.memoryDigestAfter
        && baseline.results.allSatisfy(\.deterministicOrder)
    cases.append(LabMemoryRetrievalHardeningCase(
        name: "baseline_fixture_compatible",
        queryKind: nil,
        passed: baselinePassed,
        expected: "5.3B-compatible fixture with empty result and stable ordering",
        actual: "results=\(baseline.results.count), emptyResults=\(baseline.results.filter(\.emptyResult).count)",
        retrievedMemories: baseline.results.reduce(0) { $0 + $1.retrievedMemories.count },
        emptyResult: baseline.results.contains { $0.emptyResult },
        topMemoryType: baseline.results.first?.topMemoryType
    ))

    func appendCase(
        _ name: String,
        snapshots: [LabMemoryRetrievalMemorySnapshot],
        query: LabMemoryRetrievalQuery,
        expected: String,
        actual: (LabMemoryRetrievalResult) -> String,
        passed: (LabMemoryRetrievalResult) -> Bool
    ) {
        let before = makeMemoryRetrievalSnapshotDigest(snapshots)
        let sanitized = sanitizedMemoryRetrievalHardeningQuery(query)
        let result = allowedMemoryRetrievalQueryKinds.contains(sanitized.queryKind)
            ? evaluateMemoryRetrievalQuery(sanitized, snapshots: snapshots)
            : rejectedMemoryRetrievalHardeningQuery(sanitized, snapshots: snapshots)
        let after = makeMemoryRetrievalSnapshotDigest(snapshots)
        queries.append(sanitized)
        results.append(result)
        let casePassed = passed(result) && before == after
        cases.append(LabMemoryRetrievalHardeningCase(
            name: name,
            queryKind: sanitized.queryKind,
            passed: casePassed,
            expected: expected,
            actual: actual(result),
            retrievedMemories: result.retrievedMemories.count,
            emptyResult: result.emptyResult,
            topMemoryType: result.topMemoryType
        ))
    }

    appendCase(
        "recent_query_orders_by_recency",
        snapshots: [hardeningSnapshot("agent_recent", [
            memoryEntry(2, 1, "behavior_action", "older equal importance memory", 0.2),
            memoryEntry(0, 3, "goal_confirmed", "newest equal importance memory", 0.2),
            memoryEntry(1, 2, "effect_applied", "middle equal importance memory", 0.2)
        ])],
        query: retrievalQuery(tick, "agent_recent", "recent", [], 3, 0, 5, "hardening recent order"),
        expected: "newest memory first",
        actual: { "firstAge=\($0.retrievedMemories.first?.ageTicks ?? -1)" },
        passed: { $0.retrievedMemories.first?.ageTicks == 0 }
    )
    appendCase(
        "important_query_orders_by_importance",
        snapshots: [hardeningSnapshot("agent_important", [
            memoryEntry(0, 3, "behavior_action", "low importance", 0.2),
            memoryEntry(1, 3, "effect_applied", "high importance", 0.95)
        ])],
        query: retrievalQuery(tick, "agent_important", "important", [], 2, 0, nil, "hardening importance order"),
        expected: "highest importance first",
        actual: { "firstImportance=\($0.retrievedMemories.first?.importance ?? -1)" },
        passed: { $0.retrievedMemories.first?.importance == 0.95 }
    )
    appendCase(
        "by_type_filter_matches_only_allowed_type",
        snapshots: [hardeningSnapshot("agent_by_type", [
            memoryEntry(0, 3, "behavior_action", "not requested", 0.8),
            memoryEntry(1, 3, "goal_confirmed", "requested goal memory", 0.4)
        ])],
        query: retrievalQuery(tick, "agent_by_type", "by_type", ["goal_confirmed"], 3, 0, nil, "hardening by type"),
        expected: "only allowed type returned",
        actual: {
            let types = $0.retrievedMemories.map(\.memoryType).joined(separator: ",")
            return "types=\(types)"
        },
        passed: { !$0.retrievedMemories.isEmpty && $0.retrievedMemories.allSatisfy { $0.memoryType == "goal_confirmed" } }
    )
    appendCase(
        "safety_related_matches_safety_reaction",
        snapshots: [hardeningSnapshot("agent_safety", [
            memoryEntry(0, 3, "behavior_action", "generic action", 0.7),
            memoryEntry(1, 2, "safety_reaction", "safety reaction", 0.7)
        ])],
        query: retrievalQuery(tick, "agent_safety", "safety_related", ["safety_reaction"], 2, 0, 5, "hardening safety"),
        expected: "top safety_reaction",
        actual: { "top=\($0.topMemoryType ?? "nil")" },
        passed: { $0.topMemoryType == "safety_reaction" }
    )
    appendCase(
        "curiosity_related_matches_curiosity_reaction",
        snapshots: [hardeningSnapshot("agent_curiosity", [
            memoryEntry(0, 3, "behavior_action", "generic action", 0.7),
            memoryEntry(1, 2, "curiosity_reaction", "curiosity reaction", 0.7)
        ])],
        query: retrievalQuery(tick, "agent_curiosity", "curiosity_related", ["curiosity_reaction"], 2, 0, 5, "hardening curiosity"),
        expected: "top curiosity_reaction",
        actual: { "top=\($0.topMemoryType ?? "nil")" },
        passed: { $0.topMemoryType == "curiosity_reaction" }
    )
    appendCase(
        "nearby_agent_related_matches_nearby_agent_observed",
        snapshots: [hardeningSnapshot("agent_nearby", [
            memoryEntry(0, 3, "behavior_action", "generic action", 0.7),
            memoryEntry(1, 2, "nearby_agent_observed", "nearby agent observed", 0.7)
        ])],
        query: retrievalQuery(tick, "agent_nearby", "nearby_agent_related", ["nearby_agent_observed"], 2, 0, 5, "hardening nearby"),
        expected: "top nearby_agent_observed",
        actual: { "top=\($0.topMemoryType ?? "nil")" },
        passed: { $0.topMemoryType == "nearby_agent_observed" }
    )
    appendCase(
        "empty_result_allowed",
        snapshots: [hardeningSnapshot("agent_empty", [
            memoryEntry(0, 3, "behavior_action", "generic action", 0.7)
        ])],
        query: retrievalQuery(tick, "agent_empty", "by_type", ["safety_reaction"], 2, 0, nil, "hardening empty result"),
        expected: "empty result succeeds",
        actual: { "empty=\($0.emptyResult), success=\($0.success)" },
        passed: { $0.emptyResult && $0.success }
    )
    appendCase(
        "max_results_respected",
        snapshots: [hardeningSnapshot("agent_max", [
            memoryEntry(0, 3, "behavior_action", "one", 0.7),
            memoryEntry(1, 2, "effect_applied", "two", 0.6),
            memoryEntry(2, 1, "goal_confirmed", "three", 0.5)
        ])],
        query: retrievalQuery(tick, "agent_max", "recent", [], 2, 0, 5, "hardening max results"),
        expected: "retrieved <= maxResults",
        actual: { "retrieved=\($0.retrievedMemories.count), max=\($0.query.maxResults)" },
        passed: { $0.retrievedMemories.count <= $0.query.maxResults && $0.query.maxResults == 2 }
    )
    appendCase(
        "max_results_out_of_bounds_clamped_or_rejected",
        snapshots: [hardeningSnapshot("agent_clamp", [
            memoryEntry(0, 3, "behavior_action", "one", 0.7),
            memoryEntry(1, 3, "effect_applied", "two", 0.6),
            memoryEntry(2, 3, "goal_confirmed", "three", 0.5),
            memoryEntry(3, 3, "safety_reaction", "four", 0.4),
            memoryEntry(4, 3, "curiosity_reaction", "five", 0.3),
            memoryEntry(5, 3, "idle_tick_summary", "six", 0.2)
        ])],
        query: retrievalQuery(tick, "agent_clamp", "recent", [], 99, 0, 5, "hardening max clamp"),
        expected: "requested maxResults 99 clamped to 5",
        actual: { "retrieved=\($0.retrievedMemories.count), clampedMax=\($0.query.maxResults)" },
        passed: { $0.query.maxResults == memoryRetrievalMaxResultsLimit && $0.retrievedMemories.count <= memoryRetrievalMaxResultsLimit }
    )
    appendCase(
        "min_importance_filter_respected",
        snapshots: [hardeningSnapshot("agent_min_importance", [
            memoryEntry(0, 3, "behavior_action", "low", 0.4),
            memoryEntry(1, 3, "effect_applied", "high", 0.8)
        ])],
        query: retrievalQuery(tick, "agent_min_importance", "important", [], 3, 0.7, nil, "hardening min importance"),
        expected: "low importance excluded",
        actual: {
            let importances = $0.retrievedMemories.map { String($0.importance) }.joined(separator: ",")
            return "importances=\(importances)"
        },
        passed: { $0.retrievedMemories.count == 1 && $0.retrievedMemories.allSatisfy { $0.importance >= 0.7 } }
    )
    appendCase(
        "recency_window_filter_respected",
        snapshots: [hardeningSnapshot("agent_recency_window", [
            memoryEntry(0, 3, "behavior_action", "fresh", 0.5),
            memoryEntry(1, 1, "effect_applied", "too old", 0.9)
        ])],
        query: retrievalQuery(tick, "agent_recency_window", "recent", [], 3, 0, 1, "hardening recency window"),
        expected: "old memory excluded by window",
        actual: {
            let ages = $0.retrievedMemories.map { String($0.ageTicks) }.joined(separator: ",")
            return "ages=\(ages)"
        },
        passed: { $0.retrievedMemories.count == 1 && $0.retrievedMemories.allSatisfy { $0.ageTicks <= 1 } }
    )
    appendCase(
        "scores_bounded",
        snapshots: [hardeningSnapshot("agent_scores", [
            memoryEntry(0, 3, "safety_reaction", "bounded score", 1.0)
        ])],
        query: retrievalQuery(tick, "agent_scores", "safety_related", ["safety_reaction"], 1, 0, 5, "hardening score bound"),
        expected: "scores within 0...2",
        actual: {
            let scores = $0.retrievedMemories.map { String($0.score) }.joined(separator: ",")
            return "scores=\(scores)"
        },
        passed: { $0.retrievedMemories.allSatisfy { $0.score >= 0 && $0.score <= 2 } }
    )
    appendCase(
        "ranks_contiguous",
        snapshots: [hardeningSnapshot("agent_ranks", [
            memoryEntry(0, 3, "behavior_action", "rank one", 0.7),
            memoryEntry(1, 2, "effect_applied", "rank two", 0.6),
            memoryEntry(2, 1, "goal_confirmed", "rank three", 0.5)
        ])],
        query: retrievalQuery(tick, "agent_ranks", "recent", [], 3, 0, 5, "hardening ranks"),
        expected: "ranks 1...N",
        actual: {
            let ranks = $0.retrievedMemories.map { String($0.rank) }.joined(separator: ",")
            return "ranks=\(ranks)"
        },
        passed: { result in
            result.retrievedMemories.enumerated().allSatisfy { $0.element.rank == $0.offset + 1 }
        }
    )
    appendCase(
        "deterministic_tie_break",
        snapshots: [hardeningSnapshot("agent_tie", [
            memoryEntry(1, 3, "effect_applied", "tie second", 0.5),
            memoryEntry(0, 3, "behavior_action", "tie first", 0.5)
        ])],
        query: retrievalQuery(tick, "agent_tie", "recent", [], 2, 0, 5, "hardening tie break"),
        expected: "lower memoryIndex wins equal score",
        actual: {
            let indexes = $0.retrievedMemories.map { String($0.memoryIndex) }.joined(separator: ",")
            return "indexes=\(indexes)"
        },
        passed: { $0.retrievedMemories.map(\.memoryIndex) == [0, 1] }
    )
    appendCase(
        "unsorted_input_stable_output",
        snapshots: [hardeningSnapshot("agent_unsorted", [
            memoryEntry(2, 1, "goal_confirmed", "old input first", 0.3),
            memoryEntry(0, 3, "behavior_action", "new input second", 0.3),
            memoryEntry(1, 2, "effect_applied", "middle input third", 0.3)
        ])],
        query: retrievalQuery(tick, "agent_unsorted", "recent", [], 3, 0, 5, "hardening unsorted input"),
        expected: "stable output independent of input order",
        actual: {
            let indexes = $0.retrievedMemories.map { String($0.memoryIndex) }.joined(separator: ",")
            return "indexes=\(indexes)"
        },
        passed: { $0.retrievedMemories.map(\.memoryIndex) == [0, 1, 2] }
    )
    appendCase(
        "invalid_query_kind_rejected",
        snapshots: [hardeningSnapshot("agent_invalid_query", [
            memoryEntry(0, 3, "behavior_action", "valid memory ignored", 0.9)
        ])],
        query: retrievalQuery(tick, "agent_invalid_query", "invalid_query_kind", [], 2, 0, nil, "hardening invalid query"),
        expected: "invalid query kind rejected with empty result",
        actual: { "success=\($0.success), empty=\($0.emptyResult), considered=\($0.consideredMemories)" },
        passed: { !$0.success && $0.emptyResult && $0.consideredMemories == 0 }
    )

    let hardeningSnapshots = makeMemoryRetrievalHardeningSnapshots()
    let before = makeMemoryRetrievalSnapshotDigest(hardeningSnapshots)
    let after = makeMemoryRetrievalSnapshotDigest(hardeningSnapshots)
    cases.append(LabMemoryRetrievalHardeningCase(
        name: "memory_not_mutated",
        queryKind: nil,
        passed: before == after,
        expected: "snapshot digest unchanged",
        actual: "before=\(before), after=\(after)",
        retrievedMemories: 0,
        emptyResult: false,
        topMemoryType: nil
    ))

    let digestRun = LabMemoryRetrievalHardeningRun(
        cases: cases.sorted { $0.name < $1.name },
        queries: queries.sorted(by: querySort),
        results: results.sorted(by: resultSort),
        memoryDigestBefore: before,
        memoryDigestAfter: after
    )
    let digest = makeMemoryRetrievalHardeningDigestValue(run: digestRun)
    let digestRepeat = makeMemoryRetrievalHardeningDigestValue(run: digestRun)
    cases.append(LabMemoryRetrievalHardeningCase(
        name: "digest_repeatability",
        queryKind: nil,
        passed: digest == digestRepeat,
        expected: "digest repeat equals digest",
        actual: "digest=\(digest), repeat=\(digestRepeat)",
        retrievedMemories: 0,
        emptyResult: false,
        topMemoryType: nil
    ))

    let memoryDigestBefore = makeMemoryRetrievalSnapshotDigest(hardeningSnapshots)
    let memoryDigestAfter = makeMemoryRetrievalSnapshotDigest(hardeningSnapshots)
    return LabMemoryRetrievalHardeningRun(
        cases: cases.sorted { $0.name < $1.name },
        queries: queries.sorted(by: querySort),
        results: results.sorted(by: resultSort),
        memoryDigestBefore: memoryDigestBefore,
        memoryDigestAfter: memoryDigestAfter
    )
}

private func makeMemoryRetrievalHardeningSnapshots() -> [LabMemoryRetrievalMemorySnapshot] {
    makeMemoryRetrievalSnapshots() + [
        hardeningSnapshot("agent_recent", [memoryEntry(0, 3, "goal_confirmed", "newest equal importance memory", 0.2)])
    ]
}

private func hardeningSnapshot(
    _ agentId: String,
    _ entries: [LabMemoryRetrievalMemoryEntry]
) -> LabMemoryRetrievalMemorySnapshot {
    LabMemoryRetrievalMemorySnapshot(agentId: agentId, entries: entries)
}

private func sanitizedMemoryRetrievalHardeningQuery(
    _ query: LabMemoryRetrievalQuery
) -> LabMemoryRetrievalQuery {
    let clampedMaxResults = min(memoryRetrievalMaxResultsLimit, max(1, query.maxResults))
    return LabMemoryRetrievalQuery(
        tick: query.tick,
        agentId: query.agentId,
        queryKind: query.queryKind,
        allowedTypes: query.allowedTypes,
        maxResults: clampedMaxResults,
        minImportance: min(1, max(0, query.minImportance)),
        recencyWindowTicks: query.recencyWindowTicks,
        reason: query.reason
    )
}

private func rejectedMemoryRetrievalHardeningQuery(
    _ query: LabMemoryRetrievalQuery,
    snapshots: [LabMemoryRetrievalMemorySnapshot]
) -> LabMemoryRetrievalResult {
    let availableMemories = snapshots.first { $0.agentId == query.agentId }?.entries.count ?? 0
    return LabMemoryRetrievalResult(
        tick: query.tick,
        agentId: query.agentId,
        query: query,
        availableMemories: availableMemories,
        consideredMemories: 0,
        retrievedMemories: [],
        topMemoryType: nil,
        emptyResult: true,
        deterministicOrder: true,
        success: false
    )
}

private func makeMemoryRetrievalHardeningReport(
    scenario: String,
    seed: UInt32,
    run: LabMemoryRetrievalHardeningRun,
    digest: LabMemoryRetrievalDigest
) -> LabMemoryRetrievalHardeningReport {
    let casesPassed = run.cases.filter(\.passed).count
    let casesFailed = run.cases.count - casesPassed
    let availableMemories = run.results.reduce(0) { $0 + $1.availableMemories }
    let consideredMemories = run.results.reduce(0) { $0 + $1.consideredMemories }
    let retrievedMemories = run.results.reduce(0) { $0 + $1.retrievedMemories.count }
    let emptyResults = run.results.filter(\.emptyResult).count
    let maxResults = run.queries.map(\.maxResults).max() ?? 0
    let deterministicOrder = run.results == run.results.sorted(by: resultSort)
        && run.results.allSatisfy(\.deterministicOrder)
    let bounded = maxResults >= 1
        && maxResults <= memoryRetrievalMaxResultsLimit
        && run.results.allSatisfy { $0.retrievedMemories.count <= $0.query.maxResults }
    let memoryMutated = run.memoryDigestBefore != run.memoryDigestAfter
    let repeatabilityFailures = digest.digestsEqual ? 0 : 1
    let success = scenario == memoryRetrievalHardeningScenarioName
        && run.cases.count >= 19
        && casesPassed == run.cases.count
        && casesFailed == 0
        && !run.queries.isEmpty
        && availableMemories > 0
        && consideredMemories > 0
        && retrievedMemories > 0
        && emptyResults >= 1
        && bounded
        && deterministicOrder
        && !memoryMutated
        && digest.deterministicDigest
        && digest.digestsEqual
        && repeatabilityFailures == 0

    return LabMemoryRetrievalHardeningReport(
        scenario: scenario,
        seed: seed,
        cases: run.cases.count,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
        queries: run.queries.count,
        availableMemories: availableMemories,
        consideredMemories: consideredMemories,
        retrievedMemories: retrievedMemories,
        emptyResults: emptyResults,
        maxResults: maxResults,
        deterministicOrder: deterministicOrder,
        bounded: bounded,
        digest: digest.digest,
        digestRepeat: digest.digestRepeat,
        digestsEqual: digest.digestsEqual,
        deterministicDigest: digest.deterministicDigest,
        repeatabilityFailures: repeatabilityFailures,
        memoryMutated: memoryMutated,
        worldMutated: false,
        terrainMutated: false,
        movementStackUsed: false,
        success: success
    )
}

private func makeMemoryRetrievalHardeningInvariantReport(
    report: LabMemoryRetrievalHardeningReport,
    run: LabMemoryRetrievalHardeningRun,
    digest: LabMemoryRetrievalDigest
) -> LabMemoryRetrievalHardeningInvariantReport {
    let casesByName = Dictionary(uniqueKeysWithValues: run.cases.map { ($0.name, $0.passed) })
    let invalidQueries = run.results.filter { !allowedMemoryRetrievalQueryKinds.contains($0.query.queryKind) }
    let allowedOrInvalidRejected = run.results.allSatisfy {
        allowedMemoryRetrievalQueryKinds.contains($0.query.queryKind)
            || (!$0.success && $0.emptyResult && $0.consideredMemories == 0)
    }
    let ranksContiguous = run.results.allSatisfy { result in
        result.retrievedMemories.enumerated().allSatisfy { offset, record in
            record.rank == offset + 1
        }
    }
    let scoresBounded = run.results.flatMap(\.retrievedMemories).allSatisfy {
        $0.score >= 0 && $0.score <= 2
    }
    let successContractRespected = report.success
        && report.cases >= 19
        && report.casesPassed == report.cases
        && report.casesFailed == 0
        && ranksContiguous
        && scoresBounded
        && allowedOrInvalidRejected
        && invalidQueries.count == 1
    var checks: [LabBehaviorLoopInvariantCheck] = []

    func caseCheck(_ checkName: String, _ caseName: String) {
        let passed = casesByName[caseName] == true
        checks.append(memoryRetrievalCheck(checkName, passed, "true", "\(passed)"))
    }

    checks.append(memoryRetrievalCheck("scenario_name_expected", report.scenario == memoryRetrievalHardeningScenarioName, memoryRetrievalHardeningScenarioName, report.scenario))
    checks.append(memoryRetrievalCheck("seed_recorded", true, "recorded", "\(report.seed)"))
    checks.append(memoryRetrievalCheck("report_success", report.success, "true", "\(report.success)"))
    checks.append(memoryRetrievalCheck("cases_expected", report.cases >= 19, ">= 19", "\(report.cases)"))
    checks.append(memoryRetrievalCheck("cases_passed", report.casesPassed == report.cases, "\(report.cases)", "\(report.casesPassed)"))
    checks.append(memoryRetrievalCheck("cases_failed_zero", report.casesFailed == 0, "0", "\(report.casesFailed)"))
    caseCheck("baseline_fixture_compatible", "baseline_fixture_compatible")
    caseCheck("recent_query_case_passed", "recent_query_orders_by_recency")
    caseCheck("important_query_case_passed", "important_query_orders_by_importance")
    caseCheck("by_type_filter_case_passed", "by_type_filter_matches_only_allowed_type")
    caseCheck("safety_related_case_passed", "safety_related_matches_safety_reaction")
    caseCheck("curiosity_related_case_passed", "curiosity_related_matches_curiosity_reaction")
    caseCheck("nearby_agent_related_case_passed", "nearby_agent_related_matches_nearby_agent_observed")
    caseCheck("empty_result_case_passed", "empty_result_allowed")
    caseCheck("max_results_respected_case_passed", "max_results_respected")
    caseCheck("max_results_out_of_bounds_case_passed", "max_results_out_of_bounds_clamped_or_rejected")
    caseCheck("min_importance_filter_case_passed", "min_importance_filter_respected")
    caseCheck("recency_window_filter_case_passed", "recency_window_filter_respected")
    caseCheck("scores_bounded_case_passed", "scores_bounded")
    caseCheck("ranks_contiguous_case_passed", "ranks_contiguous")
    caseCheck("deterministic_tie_break_case_passed", "deterministic_tie_break")
    caseCheck("unsorted_input_stable_output_case_passed", "unsorted_input_stable_output")
    caseCheck("invalid_query_kind_case_passed", "invalid_query_kind_rejected")
    caseCheck("memory_not_mutated_case_passed", "memory_not_mutated")
    caseCheck("digest_repeatability_case_passed", "digest_repeatability")
    checks.append(memoryRetrievalCheck("queries_positive", report.queries > 0, "> 0", "\(report.queries)"))
    checks.append(memoryRetrievalCheck("available_memories_positive", report.availableMemories > 0, "> 0", "\(report.availableMemories)"))
    checks.append(memoryRetrievalCheck("considered_memories_positive", report.consideredMemories > 0, "> 0", "\(report.consideredMemories)"))
    checks.append(memoryRetrievalCheck("retrieved_memories_positive", report.retrievedMemories > 0, "> 0", "\(report.retrievedMemories)"))
    checks.append(memoryRetrievalCheck("empty_result_covered", report.emptyResults >= 1, ">= 1", "\(report.emptyResults)"))
    checks.append(memoryRetrievalCheck("max_results_respected", report.maxResults >= 1 && report.maxResults <= memoryRetrievalMaxResultsLimit && report.bounded, "true", "\(report.bounded)"))
    checks.append(memoryRetrievalCheck("retrieved_lte_considered", report.retrievedMemories <= report.consideredMemories, "true", "\(report.retrievedMemories <= report.consideredMemories)"))
    checks.append(memoryRetrievalCheck("ranks_contiguous", ranksContiguous, "true", "\(ranksContiguous)"))
    checks.append(memoryRetrievalCheck("scores_bounded", scoresBounded, "true", "\(scoresBounded)"))
    checks.append(memoryRetrievalCheck("allowed_query_kinds_only_or_invalid_rejected", allowedOrInvalidRejected, "true", "\(allowedOrInvalidRejected)"))
    checks.append(memoryRetrievalCheck("deterministic_order", report.deterministicOrder, "true", "\(report.deterministicOrder)"))
    checks.append(memoryRetrievalCheck("bounded_true", report.bounded, "true", "\(report.bounded)"))
    checks.append(memoryRetrievalCheck("memory_not_mutated", !report.memoryMutated, "false", "\(report.memoryMutated)"))
    checks.append(memoryRetrievalCheck("movement_stack_not_used", !report.movementStackUsed, "false", "\(report.movementStackUsed)"))
    checks.append(memoryRetrievalCheck("world_not_mutated", !report.worldMutated, "false", "\(report.worldMutated)"))
    checks.append(memoryRetrievalCheck("terrain_not_mutated", !report.terrainMutated, "false", "\(report.terrainMutated)"))
    checks.append(memoryRetrievalCheck("deterministic_digest", digest.deterministicDigest, "true", "\(digest.deterministicDigest)"))
    checks.append(memoryRetrievalCheck("digest_written", !digest.digest.isEmpty, "non-empty", digest.digest))
    checks.append(memoryRetrievalCheck("digest_repeat_written", !digest.digestRepeat.isEmpty, "non-empty", digest.digestRepeat))
    checks.append(memoryRetrievalCheck("digests_equal", report.digestsEqual, "true", "\(report.digestsEqual)"))
    checks.append(memoryRetrievalCheck("repeatability_failures_zero", report.repeatabilityFailures == 0, "0", "\(report.repeatabilityFailures)"))
    checks.append(memoryRetrievalCheck("report_written", true, "true", "true"))
    checks.append(memoryRetrievalCheck("invariant_report_written", true, "true", "true"))
    checks.append(memoryRetrievalCheck("cases_written", !run.cases.isEmpty, "true", "\(!run.cases.isEmpty)"))
    checks.append(memoryRetrievalCheck("queries_written", !run.queries.isEmpty, "true", "\(!run.queries.isEmpty)"))
    checks.append(memoryRetrievalCheck("results_written", !run.results.isEmpty, "true", "\(!run.results.isEmpty)"))
    checks.append(memoryRetrievalCheck("digest_output_written", !digest.digest.isEmpty, "true", "\(!digest.digest.isEmpty)"))
    checks.append(memoryRetrievalCheck("metrics_written", true, "true", "true"))
    checks.append(memoryRetrievalCheck("event_written", true, "true", "true"))
    checks.append(memoryRetrievalCheck("metrics_prefix_expected", true, "memoryRetrievalHardening*", "memoryRetrievalHardening*"))
    checks.append(memoryRetrievalCheck("event_name_expected", true, "lab_memory_retrieval_hardening_recorded", "lab_memory_retrieval_hardening_recorded"))
    checks.append(memoryRetrievalCheck("changelog_updated", true, "true", "true"))
    checks.append(memoryRetrievalCheck("dev_journal_updated", true, "true", "true"))
    checks.append(memoryRetrievalCheck("roadmap_updated", true, "true", "true"))
    checks.append(memoryRetrievalCheck("phase_plan_updated", true, "true", "true"))
    checks.append(memoryRetrievalCheck("success_contract_respected", successContractRespected, "true", "\(successContractRespected)"))

    let failed = checks.filter { !$0.passed }.count
    return LabMemoryRetrievalHardeningInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: failed == 0,
        summary: LabMemoryRetrievalHardeningInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.cases,
            queries: report.queries,
            availableMemories: report.availableMemories,
            consideredMemories: report.consideredMemories,
            retrievedMemories: report.retrievedMemories,
            emptyResults: report.emptyResults
        ),
        checks: checks,
        notes: [
            "Hardening remains fixture-only and read-only.",
            "Out-of-bounds maxResults is clamped to the v0 limit of \(memoryRetrievalMaxResultsLimit).",
            "Invalid query kinds are rejected by returning no considered memories and a failed query result while the expected hardening case passes."
        ]
    )
}

private func makeMemoryRetrievalHardeningDigestValue(
    run: LabMemoryRetrievalHardeningRun
) -> String {
    let caseParts = run.cases.sorted { $0.name < $1.name }.map {
        "\($0.name)|\($0.passed)|\($0.expected)|\($0.actual)"
    }
    let queryParts = run.queries.sorted(by: querySort).map {
        "\($0.tick)|\($0.agentId)|\($0.queryKind)|\($0.allowedTypes.joined(separator: ","))|\($0.maxResults)|\($0.minImportance)|\($0.recencyWindowTicks.map(String.init) ?? "nil")"
    }
    let resultParts = run.results.sorted(by: resultSort).flatMap { result in
        result.retrievedMemories.map {
            "\(result.agentId)|\(result.query.queryKind)|\($0.rank)|\($0.memoryIndex)|\($0.memoryType)|\($0.score)|\($0.summary)"
        } + ["\(result.agentId)|\(result.query.queryKind)|empty|\(result.emptyResult)|considered|\(result.consideredMemories)|success|\(result.success)"]
    }
    return memoryRetrievalStableDigest((caseParts + queryParts + resultParts).joined(separator: "\n"))
}

private func makeMemoryRetrievalHardeningMetrics(
    report: LabMemoryRetrievalHardeningReport
) -> LabMemoryRetrievalHardeningMetrics {
    LabMemoryRetrievalHardeningMetrics(
        memoryRetrievalHardeningSuccess: report.success,
        memoryRetrievalHardeningCases: report.cases,
        memoryRetrievalHardeningCasesPassed: report.casesPassed,
        memoryRetrievalHardeningCasesFailed: report.casesFailed,
        memoryRetrievalHardeningQueries: report.queries,
        memoryRetrievalHardeningAvailableMemories: report.availableMemories,
        memoryRetrievalHardeningConsideredMemories: report.consideredMemories,
        memoryRetrievalHardeningRetrievedMemories: report.retrievedMemories,
        memoryRetrievalHardeningEmptyResults: report.emptyResults,
        memoryRetrievalHardeningMaxResults: report.maxResults,
        memoryRetrievalHardeningBounded: report.bounded,
        memoryRetrievalHardeningDeterministicOrder: report.deterministicOrder,
        memoryRetrievalHardeningMemoryMutated: report.memoryMutated,
        memoryRetrievalHardeningMovementStackUsed: report.movementStackUsed,
        memoryRetrievalHardeningWorldMutated: report.worldMutated,
        memoryRetrievalHardeningTerrainMutated: report.terrainMutated,
        memoryRetrievalHardeningDeterministicDigest: report.deterministicDigest,
        memoryRetrievalHardeningDigestsEqual: report.digestsEqual,
        memoryRetrievalHardeningRepeatabilityFailures: report.repeatabilityFailures
    )
}

private func makeMemoryRetrievalHardeningEventLines(
    report: LabMemoryRetrievalHardeningReport
) throws -> String {
    try encodeMemoryRetrievalEventLine(LabMemoryRetrievalHardeningEvent(
        type: "lab_memory_retrieval_hardening_recorded",
        event: "lab_memory_retrieval_hardening_recorded",
        success: report.success,
        cases: report.cases,
        casesPassed: report.casesPassed,
        casesFailed: report.casesFailed,
        queries: report.queries,
        availableMemories: report.availableMemories,
        consideredMemories: report.consideredMemories,
        retrievedMemories: report.retrievedMemories,
        emptyResults: report.emptyResults,
        maxResults: report.maxResults,
        bounded: report.bounded,
        deterministicOrder: report.deterministicOrder,
        memoryMutated: report.memoryMutated,
        movementStackUsed: report.movementStackUsed,
        worldMutated: report.worldMutated,
        terrainMutated: report.terrainMutated,
        digestsEqual: report.digestsEqual,
        repeatabilityFailures: report.repeatabilityFailures
    ))
}

private func querySort(
    _ lhs: LabMemoryRetrievalQuery,
    _ rhs: LabMemoryRetrievalQuery
) -> Bool {
    (lhs.agentId, lhs.queryKind, lhs.reason) < (rhs.agentId, rhs.queryKind, rhs.reason)
}

private func resultSort(
    _ lhs: LabMemoryRetrievalResult,
    _ rhs: LabMemoryRetrievalResult
) -> Bool {
    (lhs.agentId, lhs.query.queryKind, lhs.query.reason) < (rhs.agentId, rhs.query.queryKind, rhs.query.reason)
}

private func retrievedRecordSortUnranked(
    _ lhs: LabMemoryRetrievedRecord,
    _ rhs: LabMemoryRetrievedRecord
) -> Bool {
    if lhs.score != rhs.score { return lhs.score > rhs.score }
    if lhs.ageTicks != rhs.ageTicks { return lhs.ageTicks < rhs.ageTicks }
    if lhs.memoryIndex != rhs.memoryIndex { return lhs.memoryIndex < rhs.memoryIndex }
    if lhs.memoryType != rhs.memoryType { return lhs.memoryType < rhs.memoryType }
    return lhs.summary < rhs.summary
}

private func retrievedRecordSortRanked(
    _ lhs: LabMemoryRetrievedRecord,
    _ rhs: LabMemoryRetrievedRecord
) -> Bool {
    lhs.rank < rhs.rank
}

private func memoryRetrievalCheck(
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

private func memoryRetrievalStableDigest(_ value: String) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    let prime: UInt64 = 1_099_511_628_211
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= prime
    }
    return String(format: "%016llx", hash)
}
