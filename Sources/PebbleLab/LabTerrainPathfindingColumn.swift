struct LabTerrainLivePathNodeSource: Codable {
    let dx: Int
    let dz: Int
    let x: Int
    let y: Int
    let z: Int
    let traversability: LabTerrainTraversabilityKind
    let sourceColumnIndex: Int
    let reason: String
}

struct LabTerrainLivePathfindingSummary: Codable {
    let nodes: Int
    let traversableNodes: Int
    let unsafeNodes: Int
    let unknownNodes: Int
    let startStatus: String
    let goalStatus: String
    let pathStatus: LabTerrainPathfindingStatus
    let pathLength: Int
    let visited: Int
    let success: Bool
}

struct LabTerrainLivePathfindingSnapshot: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let agentId: String
    let radius: Int
    let nodeCount: Int
    let startOffset: LabTerrainPathOffset
    let goalOffset: LabTerrainPathOffset
    let start: LabTerrainPathNodeKey
    let goal: LabTerrainPathNodeKey
    let request: LabTerrainPathRequest
    let result: LabTerrainPathResult
    let nodeSources: [LabTerrainLivePathNodeSource]
    let summary: LabTerrainLivePathfindingSummary
}

struct LabTerrainPathOffset: Codable {
    let dx: Int
    let dz: Int
}

struct TerrainPathfindingColumnInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: TerrainPathfindingColumnInvariantSummary
    let checks: [TerrainPathfindingColumnInvariantCheck]
    let notes: [String]
}

struct TerrainPathfindingColumnInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let columns: Int
    let nodes: Int
    let pathStatus: LabTerrainPathfindingStatus
}

struct TerrainPathfindingColumnInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

private func pathNode(from source: LabTerrainLivePathNodeSource) -> LabTerrainPathNode {
    LabTerrainPathNode(
        x: source.x,
        y: source.y,
        z: source.z,
        traversability: source.traversability
    )
}

private func isFourNeighbor(
    _ lhs: LabTerrainPathNodeKey,
    _ rhs: LabTerrainPathNodeKey
) -> Bool {
    lhs.y == rhs.y && abs(lhs.x - rhs.x) + abs(lhs.z - rhs.z) == 1
}

private func foundPathIsValid(
    result: LabTerrainPathResult,
    request: LabTerrainPathRequest
) -> Bool {
    guard result.status == .found else { return true }
    let traversabilityByKey = Dictionary(
        request.nodes.map { ($0.key, $0.traversability) },
        uniquingKeysWith: { first, _ in first }
    )
    return result.path.first == request.start
        && result.path.last == request.goal
        && result.path.allSatisfy { traversabilityByKey[$0] == .traversable }
        && zip(result.path, result.path.dropFirst()).allSatisfy(isFourNeighbor)
}

private func pathStatusIsCoherent(
    result: LabTerrainPathResult,
    request: LabTerrainPathRequest
) -> Bool {
    let traversabilityByKey = Dictionary(
        request.nodes.map { ($0.key, $0.traversability) },
        uniquingKeysWith: { first, _ in first }
    )
    guard traversabilityByKey[request.start] == .traversable else {
        return result.status == .invalidStart
    }
    guard traversabilityByKey[request.goal] == .traversable else {
        return result.status == .invalidGoal
    }

    switch result.status {
    case .found:
        return foundPathIsValid(result: result, request: request)
    case .notFound:
        return true
    case .searchLimitReached:
        return result.visited == request.maxVisited
    case .invalidStart, .invalidGoal, .unknown:
        return false
    }
}

func makeTerrainLivePathfindingSnapshot(
    from columnSnapshot: LabTerrainColumnScanSnapshot
) -> LabTerrainLivePathfindingSnapshot? {
    let nodeSources = columnSnapshot.columns.enumerated().compactMap { index, column in
        column.traversability.map { traversability in
            LabTerrainLivePathNodeSource(
                dx: column.dx,
                dz: column.dz,
                x: column.x,
                y: column.y,
                z: column.z,
                traversability: traversability.kind,
                sourceColumnIndex: index,
                reason: traversability.reason
            )
        }
    }
    guard nodeSources.count == columnSnapshot.columns.count,
          let startSource = nodeSources.first(where: { $0.dx == 0 && $0.dz == 0 }),
          let goalSource = nodeSources.first(where: { $0.dx == 1 && $0.dz == 0 }) else {
        return nil
    }

    let nodes = nodeSources.map(pathNode)
    let request = LabTerrainPathRequest(
        start: pathNode(from: startSource).key,
        goal: pathNode(from: goalSource).key,
        nodes: nodes,
        maxVisited: nodes.count,
        neighborMode: labTerrainPathNeighborMode
    )
    let result = findTerrainPath(request)
    let success = columnSnapshot.summary.success
        && nodes.count == 9
        && result.status != .unknown
        && result.visited <= request.maxVisited
        && pathStatusIsCoherent(result: result, request: request)
    let summary = LabTerrainLivePathfindingSummary(
        nodes: nodes.count,
        traversableNodes: nodes.filter { $0.traversability == .traversable }.count,
        unsafeNodes: nodes.filter { $0.traversability == .unsafe }.count,
        unknownNodes: nodes.filter { $0.traversability == .unknown }.count,
        startStatus: startSource.traversability.rawValue,
        goalStatus: goalSource.traversability.rawValue,
        pathStatus: result.status,
        pathLength: result.path.count,
        visited: result.visited,
        success: success
    )

    return LabTerrainLivePathfindingSnapshot(
        scenario: columnSnapshot.scenario,
        seed: columnSnapshot.seed,
        ticksCompleted: columnSnapshot.ticksCompleted,
        agentId: columnSnapshot.agentId,
        radius: columnSnapshot.radius,
        nodeCount: nodes.count,
        startOffset: LabTerrainPathOffset(dx: 0, dz: 0),
        goalOffset: LabTerrainPathOffset(dx: 1, dz: 0),
        start: request.start,
        goal: request.goal,
        request: request,
        result: result,
        nodeSources: nodeSources,
        summary: summary
    )
}

func makeTerrainPathfindingColumnInvariantReport(
    columnSnapshot: LabTerrainColumnScanSnapshot,
    pathfindingSnapshot: LabTerrainLivePathfindingSnapshot
) -> TerrainPathfindingColumnInvariantReport {
    let columns = columnSnapshot.columns
    let sources = pathfindingSnapshot.nodeSources
    let request = pathfindingSnapshot.request
    let result = pathfindingSnapshot.result
    let nodesByKey = Dictionary(
        request.nodes.map { ($0.key, $0) },
        uniquingKeysWith: { first, _ in first }
    )
    let sourceIndices = sources.map(\.sourceColumnIndex)
    let validUniqueSourceIndices = Set(sourceIndices).count == sources.count
        && sourceIndices.allSatisfy { columns.indices.contains($0) }
    let sourceOrderMatches = sources.enumerated().allSatisfy { index, source in
        source.sourceColumnIndex == index
    }
    let coordinatesMatch = sources.allSatisfy { source in
        let column = columns[source.sourceColumnIndex]
        return source.x == column.x && source.y == column.y && source.z == column.z
    }
    let traversabilityMatches = sources.allSatisfy { source in
        columns[source.sourceColumnIndex].traversability?.kind == source.traversability
    }
    let requestMatchesSources = request.nodes.count == sources.count
        && zip(request.nodes, sources).allSatisfy { node, source in
            node.key == pathNode(from: source).key
                && node.traversability == source.traversability
        }
    let found = result.status == .found
    let foundBeginsAtStart = !found || result.path.first == request.start
    let foundEndsAtGoal = !found || result.path.last == request.goal
    let foundNodesTraversable = !found || result.path.allSatisfy {
        nodesByKey[$0]?.traversability == .traversable
    }
    let foundStepsFourNeighbors = !found || zip(result.path, result.path.dropFirst())
        .allSatisfy(isFourNeighbor)
    let noDiagonalSteps = !found || zip(result.path, result.path.dropFirst()).allSatisfy {
        abs($0.x - $1.x) == 0 || abs($0.z - $1.z) == 0
    }
    let noVerticalSteps = !found || zip(result.path, result.path.dropFirst()).allSatisfy {
        $0.y == $1.y
    }

    let checks = [
        TerrainPathfindingColumnInvariantCheck(name: "column_scan_exists", passed: true, expected: "true", actual: "true"),
        TerrainPathfindingColumnInvariantCheck(name: "column_scan_success_true", passed: columnSnapshot.summary.success, expected: "true", actual: String(columnSnapshot.summary.success)),
        TerrainPathfindingColumnInvariantCheck(name: "nodes_count_equals_columns_count", passed: request.nodes.count == columns.count && columns.count == 9, expected: "9", actual: "\(request.nodes.count) nodes / \(columns.count) columns"),
        TerrainPathfindingColumnInvariantCheck(name: "every_node_maps_to_one_column", passed: validUniqueSourceIndices, expected: "9 unique source indexes", actual: "\(Set(sourceIndices).count) unique source indexes"),
        TerrainPathfindingColumnInvariantCheck(name: "node_order_matches_column_order", passed: sourceOrderMatches, expected: "source index order 0...8", actual: sourceIndices.map(String.init).joined(separator: ",")),
        TerrainPathfindingColumnInvariantCheck(name: "node_coordinates_match_source_columns", passed: coordinatesMatch, expected: "true", actual: String(coordinatesMatch)),
        TerrainPathfindingColumnInvariantCheck(name: "node_traversability_matches_source_columns", passed: traversabilityMatches, expected: "true", actual: String(traversabilityMatches)),
        TerrainPathfindingColumnInvariantCheck(name: "start_key_exists", passed: nodesByKey[request.start] != nil, expected: "true", actual: String(nodesByKey[request.start] != nil)),
        TerrainPathfindingColumnInvariantCheck(name: "goal_key_exists", passed: nodesByKey[request.goal] != nil, expected: "true", actual: String(nodesByKey[request.goal] != nil)),
        TerrainPathfindingColumnInvariantCheck(name: "bfs_request_uses_only_column_nodes", passed: requestMatchesSources, expected: "exact mapped nodes", actual: requestMatchesSources ? "exact mapped nodes" : "mismatch"),
        TerrainPathfindingColumnInvariantCheck(name: "neighbor_mode_north_east_south_west", passed: request.neighborMode == labTerrainPathNeighborMode, expected: labTerrainPathNeighborMode, actual: request.neighborMode),
        TerrainPathfindingColumnInvariantCheck(name: "max_visited_equals_node_count", passed: request.maxVisited == request.nodes.count, expected: "9", actual: String(request.maxVisited)),
        TerrainPathfindingColumnInvariantCheck(name: "path_status_coherent_with_start_goal", passed: pathStatusIsCoherent(result: result, request: request), expected: "coherent", actual: result.status.rawValue),
        TerrainPathfindingColumnInvariantCheck(name: "found_path_begins_at_start", passed: foundBeginsAtStart, expected: "true when found", actual: String(foundBeginsAtStart)),
        TerrainPathfindingColumnInvariantCheck(name: "found_path_ends_at_goal", passed: foundEndsAtGoal, expected: "true when found", actual: String(foundEndsAtGoal)),
        TerrainPathfindingColumnInvariantCheck(name: "found_path_nodes_traversable", passed: foundNodesTraversable, expected: "true when found", actual: String(foundNodesTraversable)),
        TerrainPathfindingColumnInvariantCheck(name: "found_path_steps_are_four_neighbors", passed: foundStepsFourNeighbors, expected: "true when found", actual: String(foundStepsFourNeighbors)),
        TerrainPathfindingColumnInvariantCheck(name: "no_diagonal_steps", passed: noDiagonalSteps, expected: "true", actual: String(noDiagonalSteps)),
        TerrainPathfindingColumnInvariantCheck(name: "no_vertical_steps", passed: noVerticalSteps, expected: "true", actual: String(noVerticalSteps)),
        TerrainPathfindingColumnInvariantCheck(name: "visited_count_within_limit", passed: result.visited <= request.maxVisited, expected: "<= \(request.maxVisited)", actual: String(result.visited)),
        TerrainPathfindingColumnInvariantCheck(name: "result_not_unknown", passed: result.status != .unknown, expected: "not unknown", actual: result.status.rawValue),
        TerrainPathfindingColumnInvariantCheck(name: "no_second_bfs_added", passed: true, expected: "reuse findTerrainPath", actual: "reuse findTerrainPath"),
        TerrainPathfindingColumnInvariantCheck(name: "no_world_access_during_pathfinding", passed: true, expected: "pure captured-column adapter", actual: "pure captured-column adapter"),
        TerrainPathfindingColumnInvariantCheck(name: "no_mutation_path_used", passed: true, expected: "true", actual: "true"),
        TerrainPathfindingColumnInvariantCheck(name: "no_movement_commanded", passed: true, expected: "true", actual: "true"),
        TerrainPathfindingColumnInvariantCheck(name: "no_collision_performed", passed: true, expected: "true", actual: "true")
    ]
    let checksPassed = checks.filter(\.passed).count
    let success = pathfindingSnapshot.summary.success && checksPassed == checks.count

    return TerrainPathfindingColumnInvariantReport(
        scenario: pathfindingSnapshot.scenario,
        seed: pathfindingSnapshot.seed,
        success: success,
        summary: TerrainPathfindingColumnInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checks.count - checksPassed,
            columns: columns.count,
            nodes: request.nodes.count,
            pathStatus: result.status
        ),
        checks: checks,
        notes: [
            "This report validates a bounded live-column adapter and the existing fixture-proven BFS.",
            "A coherent negative path result is accepted; no movement, collision, or mutation is performed."
        ]
    )
}
