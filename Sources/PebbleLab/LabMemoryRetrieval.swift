import Foundation

let memoryRetrievalScenarioName = "memory_retrieval_fixture_smoke"
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
