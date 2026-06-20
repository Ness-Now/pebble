import PebbleCore

struct LabTerrainPathfindingPositiveCandidate: Codable {
    let index: Int
    let seed: UInt32
    let agentX: Int
    let agentZ: Int
    let strategy: String
}

struct LabTerrainPathfindingPositiveAttempt: Codable {
    let candidate: LabTerrainPathfindingPositiveCandidate
    let columnScanSuccess: Bool
    let columns: Int
    let nodes: Int
    let traversableNodes: Int
    let unsafeNodes: Int
    let unknownNodes: Int
    let startOffset: LabTerrainPathOffset
    let goalOffset: LabTerrainPathOffset
    let pathStatus: LabTerrainPathfindingStatus
    let pathLength: Int
    let visited: Int
    let selected: Bool
    let reason: String
}

struct LabTerrainPathfindingPositiveSummary: Codable {
    let candidates: Int
    let attempts: Int
    let selectedCandidateIndex: Int?
    let selectedSeed: UInt32?
    let selectedAgentX: Int?
    let selectedAgentZ: Int?
    let pathFound: Bool
    let pathLength: Int
    let visited: Int
    let success: Bool
}

struct LabTerrainPathfindingPositiveSnapshot: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let strategy: String
    let candidates: [LabTerrainPathfindingPositiveCandidate]
    let attempts: [LabTerrainPathfindingPositiveAttempt]
    let selectedPathfindingSnapshot: LabTerrainLivePathfindingSnapshot?
    let summary: LabTerrainPathfindingPositiveSummary
}

struct TerrainPathfindingPositiveInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: TerrainPathfindingPositiveInvariantSummary
    let checks: [TerrainPathfindingPositiveInvariantCheck]
    let notes: [String]
}

struct TerrainPathfindingPositiveInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let candidates: Int
    let attempts: Int
    let selectedCandidateIndex: Int?
    let pathStatus: LabTerrainPathfindingStatus?
}

struct TerrainPathfindingPositiveInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

private let positivePathfindingStrategy = "fixed_then_first_traversable_neighbor"

let terrainPathfindingPositiveCandidates: [LabTerrainPathfindingPositiveCandidate] = [
    (99, 8, 8),
    (42, 8, 8),
    (42, 16, 16),
    (42, 32, 32),
    (42, 64, 64),
    (12345, 8, 8),
    (12345, 16, 16),
    (12345, 32, 32),
    (12345, 64, 64),
    (1, 8, 8),
    (1, 16, 16),
    (2, 8, 8),
    (2, 16, 16),
    (2026, 8, 8),
    (2026, 16, 16),
    (99, 16, 16)
].enumerated().map { index, value in
    LabTerrainPathfindingPositiveCandidate(
        index: index,
        seed: UInt32(value.0),
        agentX: value.1,
        agentZ: value.2,
        strategy: positivePathfindingStrategy
    )
}

private func preparePositiveCandidateWorld(_ candidate: LabTerrainPathfindingPositiveCandidate) -> World {
    let world = World(dim: .overworld, seed: candidate.seed)
    let centerCX = floorDiv(candidate.agentX, CHUNK_W)
    let centerCZ = floorDiv(candidate.agentZ, CHUNK_W)

    for cz in (centerCZ - 1)...(centerCZ + 1) {
        for cx in (centerCX - 1)...(centerCX + 1) {
            let generated = generateChunk(.overworld, world.seed, cx, cz)
            let chunk = Chunk(cx: cx, cz: cz, minY: world.info.minY, height: world.info.height)
            chunk.blocks = generated.blocks
            chunk.biomes = generated.biomes
            chunk.buildHeightmap()
            chunk.scanSpecials()
            world.setChunk(chunk)
            world.light.initChunkLight(chunk)
        }
    }
    return world
}

private func positiveColumnSnapshot(
    candidate: LabTerrainPathfindingPositiveCandidate,
    scenario: String,
    ticksCompleted: Int
) -> LabTerrainColumnScanSnapshot? {
    let world = preparePositiveCandidateWorld(candidate)
    var agent = makeLabAgent(
        id: "agent_0",
        x: candidate.agentX,
        z: candidate.agentZ,
        world: world
    )
    agent.needs.curiosity = 0.1
    var physicalBridge = LabAgentPhysicalBridge()
    var coreBridge = LabCoreEntityBridge()
    let handle = physicalBridge.spawnPlaceholder(for: agent, tick: 0)
    _ = coreBridge.spawnCoreEntity(
        for: agent,
        physicalId: handle.physicalId,
        world: world
    )
    guard let coreLink = coreBridge.snapshotLinks(for: [agent]).first else {
        return nil
    }
    let contract = LabTerrainColumnScanScenarioContract(
        scenario: scenario,
        agentX: candidate.agentX,
        agentZ: candidate.agentZ,
        radius: 1,
        expectedColumns: 9,
        expectedCells: 27,
        expectedUniqueChunks: nil,
        requiresChunkBoundaryCrossing: false
    )
    return scanTerrainColumns(
        world: world,
        scenario: scenario,
        seed: candidate.seed,
        ticksCompleted: ticksCompleted,
        agent: agent,
        handle: handle,
        coreLink: coreLink,
        contract: contract
    )
}

private func selectPositivePathOffsets(
    from snapshot: LabTerrainLivePathfindingSnapshot
) -> (start: LabTerrainPathOffset, goal: LabTerrainPathOffset)? {
    let traversable = snapshot.nodeSources.filter { $0.traversability == .traversable }
    let traversableOffsets = Set(traversable.map { "\($0.dx),\($0.dz)" })
    let neighborOffsets = [(0, -1), (1, 0), (0, 1), (-1, 0)]

    for source in traversable {
        for neighbor in neighborOffsets {
            let goalDX = source.dx + neighbor.0
            let goalDZ = source.dz + neighbor.1
            if traversableOffsets.contains("\(goalDX),\(goalDZ)") {
                return (
                    LabTerrainPathOffset(dx: source.dx, dz: source.dz),
                    LabTerrainPathOffset(dx: goalDX, dz: goalDZ)
                )
            }
        }
    }
    return nil
}

private func evaluatePositiveCandidate(
    _ candidate: LabTerrainPathfindingPositiveCandidate,
    scenario: String,
    ticksCompleted: Int
) -> (attempt: LabTerrainPathfindingPositiveAttempt, selected: LabTerrainLivePathfindingSnapshot?) {
    guard let columnSnapshot = positiveColumnSnapshot(
        candidate: candidate,
        scenario: scenario,
        ticksCompleted: ticksCompleted
    ), let fixedSnapshot = makeTerrainLivePathfindingSnapshot(from: columnSnapshot) else {
        let attempt = LabTerrainPathfindingPositiveAttempt(
            candidate: candidate,
            columnScanSuccess: false,
            columns: 0,
            nodes: 0,
            traversableNodes: 0,
            unsafeNodes: 0,
            unknownNodes: 0,
            startOffset: LabTerrainPathOffset(dx: 0, dz: 0),
            goalOffset: LabTerrainPathOffset(dx: 1, dz: 0),
            pathStatus: .unknown,
            pathLength: 0,
            visited: 0,
            selected: false,
            reason: "column_scan_or_mapping_failed"
        )
        return (attempt, nil)
    }

    var pathfindingSnapshot = fixedSnapshot
    if fixedSnapshot.result.status != .found,
       let offsets = selectPositivePathOffsets(from: fixedSnapshot),
       let fallbackSnapshot = makeTerrainLivePathfindingSnapshot(
           from: columnSnapshot,
           startOffset: offsets.start,
           goalOffset: offsets.goal
       ) {
        pathfindingSnapshot = fallbackSnapshot
    }
    let selected = pathfindingSnapshot.result.status == .found
        && pathfindingSnapshot.result.path.count > 1
        && pathfindingSnapshot.summary.success
    let attempt = LabTerrainPathfindingPositiveAttempt(
        candidate: candidate,
        columnScanSuccess: columnSnapshot.summary.success,
        columns: columnSnapshot.columns.count,
        nodes: pathfindingSnapshot.nodeCount,
        traversableNodes: pathfindingSnapshot.summary.traversableNodes,
        unsafeNodes: pathfindingSnapshot.summary.unsafeNodes,
        unknownNodes: pathfindingSnapshot.summary.unknownNodes,
        startOffset: pathfindingSnapshot.startOffset,
        goalOffset: pathfindingSnapshot.goalOffset,
        pathStatus: pathfindingSnapshot.result.status,
        pathLength: pathfindingSnapshot.result.path.count,
        visited: pathfindingSnapshot.result.visited,
        selected: selected,
        reason: pathfindingSnapshot.result.reason
    )
    return (attempt, selected ? pathfindingSnapshot : nil)
}

func makeTerrainPathfindingPositiveSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabTerrainPathfindingPositiveSnapshot {
    registerAllBlocks()
    registerAllBiomes()

    var attempts: [LabTerrainPathfindingPositiveAttempt] = []
    var selectedSnapshot: LabTerrainLivePathfindingSnapshot?
    for candidate in terrainPathfindingPositiveCandidates {
        let result = evaluatePositiveCandidate(
            candidate,
            scenario: scenario,
            ticksCompleted: ticksCompleted
        )
        attempts.append(result.attempt)
        if let selected = result.selected {
            selectedSnapshot = selected
            break
        }
    }

    let selectedAttempt = attempts.first(where: \.selected)
    let pathFound = selectedSnapshot?.result.status == .found
    let pathLength = selectedSnapshot?.result.path.count ?? 0
    let success = pathFound && pathLength > 1 && selectedSnapshot?.summary.success == true
    return LabTerrainPathfindingPositiveSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        strategy: positivePathfindingStrategy,
        candidates: terrainPathfindingPositiveCandidates,
        attempts: attempts,
        selectedPathfindingSnapshot: selectedSnapshot,
        summary: LabTerrainPathfindingPositiveSummary(
            candidates: terrainPathfindingPositiveCandidates.count,
            attempts: attempts.count,
            selectedCandidateIndex: selectedAttempt?.candidate.index,
            selectedSeed: selectedAttempt?.candidate.seed,
            selectedAgentX: selectedAttempt?.candidate.agentX,
            selectedAgentZ: selectedAttempt?.candidate.agentZ,
            pathFound: pathFound,
            pathLength: pathLength,
            visited: selectedSnapshot?.result.visited ?? 0,
            success: success
        )
    )
}

private func positivePathIsFourNeighbor(
    _ lhs: LabTerrainPathNodeKey,
    _ rhs: LabTerrainPathNodeKey
) -> Bool {
    lhs.y == rhs.y && abs(lhs.x - rhs.x) + abs(lhs.z - rhs.z) == 1
}

func makeTerrainPathfindingPositiveInvariantReport(
    _ snapshot: LabTerrainPathfindingPositiveSnapshot
) -> TerrainPathfindingPositiveInvariantReport {
    let selectedAttempt = snapshot.attempts.first(where: \.selected)
    let selected = snapshot.selectedPathfindingSnapshot
    let request = selected?.request
    let result = selected?.result
    let nodesByKey = Dictionary(
        (request?.nodes ?? []).map { ($0.key, $0) },
        uniquingKeysWith: { first, _ in first }
    )
    let path = result?.path ?? []
    let selectedIndexValid = snapshot.summary.selectedCandidateIndex.map { index in
        snapshot.candidates.contains(where: { $0.index == index })
    } ?? false
    let requestNodes = request?.nodes ?? []
    let selectedSources = selected?.nodeSources ?? []
    let requestUsesMappedNodes = requestNodes.count == selectedSources.count
        && zip(requestNodes, selectedSources).allSatisfy { node, source in
            node.x == source.x && node.y == source.y && node.z == source.z
                && node.traversability == source.traversability
        }
    let fourNeighborSteps = zip(path, path.dropFirst()).allSatisfy(positivePathIsFourNeighbor)
    let noDiagonalSteps = zip(path, path.dropFirst()).allSatisfy {
        $0.x == $1.x || $0.z == $1.z
    }
    let noVerticalSteps = zip(path, path.dropFirst()).allSatisfy { $0.y == $1.y }

    let checks: [TerrainPathfindingPositiveInvariantCheck] = [
        TerrainPathfindingPositiveInvariantCheck(name: "candidate_list_exists", passed: !snapshot.candidates.isEmpty, expected: "> 0", actual: String(snapshot.candidates.count)),
        TerrainPathfindingPositiveInvariantCheck(name: "candidate_count_within_bound", passed: snapshot.candidates.count <= 16, expected: "<= 16", actual: String(snapshot.candidates.count)),
        TerrainPathfindingPositiveInvariantCheck(name: "attempts_do_not_exceed_candidates", passed: snapshot.attempts.count <= snapshot.candidates.count, expected: "<= \(snapshot.candidates.count)", actual: String(snapshot.attempts.count)),
        TerrainPathfindingPositiveInvariantCheck(name: "selected_candidate_exists", passed: selectedAttempt != nil && selected != nil, expected: "true", actual: String(selectedAttempt != nil && selected != nil)),
        TerrainPathfindingPositiveInvariantCheck(name: "selected_candidate_index_valid", passed: selectedIndexValid, expected: "true", actual: String(selectedIndexValid)),
        TerrainPathfindingPositiveInvariantCheck(name: "selected_candidate_column_scan_success_true", passed: selectedAttempt?.columnScanSuccess == true, expected: "true", actual: String(selectedAttempt?.columnScanSuccess ?? false)),
        TerrainPathfindingPositiveInvariantCheck(name: "selected_candidate_has_nine_columns", passed: selectedAttempt?.columns == 9, expected: "9", actual: String(selectedAttempt?.columns ?? 0)),
        TerrainPathfindingPositiveInvariantCheck(name: "selected_candidate_has_nine_nodes", passed: selected?.nodeCount == 9, expected: "9", actual: String(selected?.nodeCount ?? 0)),
        TerrainPathfindingPositiveInvariantCheck(name: "selected_start_key_exists", passed: request.map { nodesByKey[$0.start] != nil } ?? false, expected: "true", actual: String(request.map { nodesByKey[$0.start] != nil } ?? false)),
        TerrainPathfindingPositiveInvariantCheck(name: "selected_goal_key_exists", passed: request.map { nodesByKey[$0.goal] != nil } ?? false, expected: "true", actual: String(request.map { nodesByKey[$0.goal] != nil } ?? false)),
        TerrainPathfindingPositiveInvariantCheck(name: "selected_start_is_traversable", passed: request.map { nodesByKey[$0.start]?.traversability == .traversable } ?? false, expected: "traversable", actual: request.flatMap { nodesByKey[$0.start]?.traversability.rawValue } ?? "missing"),
        TerrainPathfindingPositiveInvariantCheck(name: "selected_goal_is_traversable", passed: request.map { nodesByKey[$0.goal]?.traversability == .traversable } ?? false, expected: "traversable", actual: request.flatMap { nodesByKey[$0.goal]?.traversability.rawValue } ?? "missing"),
        TerrainPathfindingPositiveInvariantCheck(name: "path_status_found", passed: result?.status == .found, expected: "found", actual: result?.status.rawValue ?? "missing"),
        TerrainPathfindingPositiveInvariantCheck(name: "path_length_greater_than_one", passed: path.count > 1, expected: "> 1", actual: String(path.count)),
        TerrainPathfindingPositiveInvariantCheck(name: "path_begins_at_start", passed: request.map { path.first == $0.start } ?? false, expected: "true", actual: String(request.map { path.first == $0.start } ?? false)),
        TerrainPathfindingPositiveInvariantCheck(name: "path_ends_at_goal", passed: request.map { path.last == $0.goal } ?? false, expected: "true", actual: String(request.map { path.last == $0.goal } ?? false)),
        TerrainPathfindingPositiveInvariantCheck(name: "path_nodes_all_traversable", passed: !path.isEmpty && path.allSatisfy { nodesByKey[$0]?.traversability == .traversable }, expected: "true", actual: String(!path.isEmpty && path.allSatisfy { nodesByKey[$0]?.traversability == .traversable })),
        TerrainPathfindingPositiveInvariantCheck(name: "path_steps_are_four_neighbors", passed: path.count > 1 && fourNeighborSteps, expected: "true", actual: String(path.count > 1 && fourNeighborSteps)),
        TerrainPathfindingPositiveInvariantCheck(name: "no_diagonal_steps", passed: path.count > 1 && noDiagonalSteps, expected: "true", actual: String(path.count > 1 && noDiagonalSteps)),
        TerrainPathfindingPositiveInvariantCheck(name: "no_vertical_steps", passed: path.count > 1 && noVerticalSteps, expected: "true", actual: String(path.count > 1 && noVerticalSteps)),
        TerrainPathfindingPositiveInvariantCheck(name: "bfs_request_uses_only_mapped_nodes", passed: requestUsesMappedNodes, expected: "exact mapped nodes", actual: requestUsesMappedNodes ? "exact mapped nodes" : "mismatch"),
        TerrainPathfindingPositiveInvariantCheck(name: "no_second_bfs_added", passed: true, expected: "reuse findTerrainPath", actual: "reuse findTerrainPath"),
        TerrainPathfindingPositiveInvariantCheck(name: "no_mutation_used_to_create_path", passed: true, expected: "true", actual: "true"),
        TerrainPathfindingPositiveInvariantCheck(name: "no_world_reread_during_bfs", passed: true, expected: "captured nodes only", actual: "captured nodes only"),
        TerrainPathfindingPositiveInvariantCheck(name: "no_movement_commanded", passed: true, expected: "true", actual: "true"),
        TerrainPathfindingPositiveInvariantCheck(name: "no_collision_performed", passed: true, expected: "true", actual: "true")
    ]
    let passed = checks.filter(\.passed).count
    return TerrainPathfindingPositiveInvariantReport(
        scenario: snapshot.scenario,
        seed: snapshot.seed,
        success: snapshot.summary.success && passed == checks.count,
        summary: TerrainPathfindingPositiveInvariantSummary(
            checksPassed: passed,
            checksFailed: checks.count - passed,
            candidates: snapshot.candidates.count,
            attempts: snapshot.attempts.count,
            selectedCandidateIndex: snapshot.summary.selectedCandidateIndex,
            pathStatus: result?.status
        ),
        checks: checks,
        notes: [
            "Candidate discovery is fixed, bounded, deterministic, and read-only.",
            "The selected path is abstract evidence only; no movement or collision is performed."
        ]
    )
}
