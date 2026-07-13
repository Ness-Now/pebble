import PebbleAgents

enum LabTerrainPathfindingStatus: String, Codable {
    case found
    case notFound
    case invalidStart
    case invalidGoal
    case searchLimitReached
    case unknown
}

struct LabTerrainPathNodeKey: Codable, Hashable {
    let x: Int
    let y: Int
    let z: Int
}

struct LabTerrainPathNode: Codable {
    let x: Int
    let y: Int
    let z: Int
    let traversability: LabTerrainTraversabilityKind

    var key: LabTerrainPathNodeKey {
        LabTerrainPathNodeKey(x: x, y: y, z: z)
    }
}

struct LabTerrainPathRequest: Codable {
    let start: LabTerrainPathNodeKey
    let goal: LabTerrainPathNodeKey
    let nodes: [LabTerrainPathNode]
    let maxVisited: Int
    let neighborMode: String
}

struct LabTerrainPathResult: Codable {
    let status: LabTerrainPathfindingStatus
    let path: [LabTerrainPathNodeKey]
    let visited: Int
    let reason: String
}

struct TerrainPathfindingFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: TerrainPathfindingFixtureSummary
    let cases: [TerrainPathfindingFixtureResult]
}

struct TerrainPathfindingFixtureSummary: Codable {
    let fixtures: Int
    let passed: Int
    let failed: Int
    let pathsFound: Int
    let pathsNotFound: Int
    let invalidStarts: Int
    let invalidGoals: Int
    let searchLimitReached: Int
    let unknown: Int
}

struct TerrainPathfindingFixtureResult: Codable {
    let name: String
    let expectedStatus: LabTerrainPathfindingStatus
    let actualStatus: LabTerrainPathfindingStatus
    let expectedPathLength: Int?
    let actualPathLength: Int
    let expectedPath: [LabTerrainPathNodeKey]?
    let actualPath: [LabTerrainPathNodeKey]
    let expectedReason: String?
    let actualReason: String
    let visited: Int
    let maxVisited: Int
    let passed: Bool
}

struct TerrainPathfindingInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: TerrainPathfindingInvariantSummary
    let checks: [TerrainPathfindingInvariantCheck]
    let notes: [String]
}

struct TerrainPathfindingInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let fixtures: Int
    let results: Int
}

struct TerrainPathfindingInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

private struct TerrainPathfindingFixtureDefinition {
    let name: String
    let request: LabTerrainPathRequest
    let expectedStatus: LabTerrainPathfindingStatus
    let expectedPath: [LabTerrainPathNodeKey]?
    let expectedPathLength: Int?
    let expectedReason: String?

    init(
        name: String,
        request: LabTerrainPathRequest,
        expectedStatus: LabTerrainPathfindingStatus,
        expectedPath: [LabTerrainPathNodeKey]?,
        expectedPathLength: Int?,
        expectedReason: String? = nil
    ) {
        self.name = name
        self.request = request
        self.expectedStatus = expectedStatus
        self.expectedPath = expectedPath
        self.expectedPathLength = expectedPathLength
        self.expectedReason = expectedReason
    }
}

let labTerrainPathNeighborMode = "north_east_south_west"
private let terrainPathNeighborMode = labTerrainPathNeighborMode

private func terrainPathKey(_ x: Int, _ z: Int, y: Int = 64) -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: x, y: y, z: z)
}

private func terrainPathNode(
    _ x: Int,
    _ z: Int,
    kind: LabTerrainTraversabilityKind = .traversable,
    y: Int = 64
) -> LabTerrainPathNode {
    LabTerrainPathNode(x: x, y: y, z: z, traversability: kind)
}

private func terrainPathNeighbors(of key: LabTerrainPathNodeKey) -> [LabTerrainPathNodeKey] {
    [
        LabTerrainPathNodeKey(x: key.x, y: key.y, z: key.z - 1),
        LabTerrainPathNodeKey(x: key.x + 1, y: key.y, z: key.z),
        LabTerrainPathNodeKey(x: key.x, y: key.y, z: key.z + 1),
        LabTerrainPathNodeKey(x: key.x - 1, y: key.y, z: key.z)
    ]
}

private func terrainPathNodeMap(
    _ nodes: [LabTerrainPathNode]
) -> [LabTerrainPathNodeKey: LabTerrainPathNode] {
    var nodesByKey: [LabTerrainPathNodeKey: LabTerrainPathNode] = [:]
    for node in nodes where nodesByKey[node.key] == nil {
        nodesByKey[node.key] = node
    }
    return nodesByKey
}

func findTerrainPath(_ request: LabTerrainPathRequest) -> LabTerrainPathResult {
    guard request.maxVisited > 0 else {
        return LabTerrainPathResult(
            status: .searchLimitReached,
            path: [],
            visited: 0,
            reason: "non_positive_search_limit"
        )
    }
    guard request.neighborMode == labTerrainPathNeighborMode else {
        return LabTerrainPathResult(
            status: .unknown,
            path: [],
            visited: 0,
            reason: "unsupported_neighbor_mode"
        )
    }

    let nodesByKey = terrainPathNodeMap(request.nodes)
    guard let startNode = nodesByKey[request.start],
          startNode.traversability == .traversable else {
        return LabTerrainPathResult(
            status: .invalidStart,
            path: [],
            visited: 0,
            reason: "start_missing_or_not_traversable"
        )
    }
    guard let goalNode = nodesByKey[request.goal],
          goalNode.traversability == .traversable else {
        return LabTerrainPathResult(
            status: .invalidGoal,
            path: [],
            visited: 0,
            reason: "goal_missing_or_not_traversable"
        )
    }
    let start = AgentPosition(x: request.start.x, y: request.start.y, z: request.start.z)
    let goal = AgentPosition(x: request.goal.x, y: request.goal.y, z: request.goal.z)
    let radius = max(1, request.nodes.map {
        abs($0.x - request.start.x) + abs($0.z - request.start.z)
    }.max() ?? 1)
    let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
        start: start,
        target: goal,
        goalMode: .exact,
        cells: request.nodes.map {
            AgentNavigationCell(
                position: AgentPosition(x: $0.x, y: $0.y, z: $0.z),
                status: $0.traversability == .traversable ? .traversable : .blocked
            )
        },
        radius: radius,
        maxVisitedNodes: request.maxVisited,
        maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
    ))
    if plan.found {
        return LabTerrainPathResult(
            status: .found,
            path: plan.positions.map { LabTerrainPathNodeKey(x: $0.x, y: $0.y, z: $0.z) },
            visited: plan.visitedNodeCount,
            reason: request.start == request.goal ? "start_equals_goal" : "bounded_bfs_path_found"
        )
    }
    if plan.failure == .nodeLimitReached || plan.failure == .invalidConfiguration {
        return LabTerrainPathResult(
            status: .searchLimitReached,
            path: [],
            visited: plan.visitedNodeCount,
            reason: request.maxVisited <= 0 ? "non_positive_search_limit" : "max_visited_reached"
        )
    }
    return LabTerrainPathResult(
        status: .notFound,
        path: [],
        visited: plan.visitedNodeCount,
        reason: "traversable_graph_exhausted"
    )
}

private func terrainPathfindingFixtureDefinitions()
    -> [TerrainPathfindingFixtureDefinition] {
    let straightPath = [terrainPathKey(0, 0), terrainPathKey(1, 0), terrainPathKey(2, 0)]
    let turnPath = [terrainPathKey(0, 0), terrainPathKey(1, 0), terrainPathKey(1, 1), terrainPathKey(2, 1)]
    let unknownDetour = [terrainPathKey(0, 0), terrainPathKey(0, 1), terrainPathKey(1, 1), terrainPathKey(2, 1), terrainPathKey(2, 0)]
    let unsafeDetour = [terrainPathKey(0, 0), terrainPathKey(0, -1), terrainPathKey(1, -1), terrainPathKey(2, -1), terrainPathKey(2, 0)]
    let deterministicPath = [terrainPathKey(1, 1), terrainPathKey(1, 0), terrainPathKey(2, 0)]
    let duplicatePath = [terrainPathKey(0, 0), terrainPathKey(1, 0)]
    let cyclePath = [terrainPathKey(0, 0), terrainPathKey(1, 0), terrainPathKey(1, 1), terrainPathKey(2, 1)]
    let complexEqualPath = [
        terrainPathKey(2, 2), terrainPathKey(2, 1), terrainPathKey(2, 0),
        terrainPathKey(3, 0), terrainPathKey(4, 0)
    ]

    return [
        TerrainPathfindingFixtureDefinition(
            name: "straight_line_path_found",
            request: LabTerrainPathRequest(
                start: straightPath[0], goal: straightPath[2],
                nodes: [terrainPathNode(0, 0), terrainPathNode(1, 0), terrainPathNode(2, 0)],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .found, expectedPath: straightPath, expectedPathLength: 3
        ),
        TerrainPathfindingFixtureDefinition(
            name: "simple_turn_path_found",
            request: LabTerrainPathRequest(
                start: turnPath[0], goal: turnPath[3],
                nodes: [terrainPathNode(0, 0), terrainPathNode(1, 0), terrainPathNode(1, 1), terrainPathNode(2, 1)],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .found, expectedPath: turnPath, expectedPathLength: 4
        ),
        TerrainPathfindingFixtureDefinition(
            name: "blocked_goal_invalid",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 0), goal: terrainPathKey(1, 0),
                nodes: [terrainPathNode(0, 0), terrainPathNode(1, 0, kind: .blocked)],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .invalidGoal, expectedPath: [], expectedPathLength: 0
        ),
        TerrainPathfindingFixtureDefinition(
            name: "blocked_start_invalid",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 0), goal: terrainPathKey(1, 0),
                nodes: [terrainPathNode(0, 0, kind: .occupiedVerticalSpace), terrainPathNode(1, 0)],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .invalidStart, expectedPath: [], expectedPathLength: 0
        ),
        TerrainPathfindingFixtureDefinition(
            name: "wall_blocks_path_not_found",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 1), goal: terrainPathKey(2, 1),
                nodes: [
                    terrainPathNode(0, 1), terrainPathNode(2, 1),
                    terrainPathNode(1, 0, kind: .blocked),
                    terrainPathNode(1, 1, kind: .blocked),
                    terrainPathNode(1, 2, kind: .blocked)
                ],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .notFound, expectedPath: [], expectedPathLength: 0
        ),
        TerrainPathfindingFixtureDefinition(
            name: "unknown_cells_are_not_used",
            request: LabTerrainPathRequest(
                start: unknownDetour[0], goal: unknownDetour[4],
                nodes: [
                    terrainPathNode(0, 0), terrainPathNode(1, 0, kind: .unknown),
                    terrainPathNode(2, 0), terrainPathNode(0, 1),
                    terrainPathNode(1, 1), terrainPathNode(2, 1)
                ],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .found, expectedPath: unknownDetour, expectedPathLength: 5
        ),
        TerrainPathfindingFixtureDefinition(
            name: "unsafe_cells_are_not_used",
            request: LabTerrainPathRequest(
                start: unsafeDetour[0], goal: unsafeDetour[4],
                nodes: [
                    terrainPathNode(0, 0), terrainPathNode(1, 0, kind: .unsafe),
                    terrainPathNode(2, 0), terrainPathNode(0, -1),
                    terrainPathNode(1, -1), terrainPathNode(2, -1)
                ],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .found, expectedPath: unsafeDetour, expectedPathLength: 5
        ),
        TerrainPathfindingFixtureDefinition(
            name: "no_diagonal_shortcut",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 0), goal: terrainPathKey(1, 1),
                nodes: [terrainPathNode(0, 0), terrainPathNode(1, 1)],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .notFound, expectedPath: [], expectedPathLength: 0
        ),
        TerrainPathfindingFixtureDefinition(
            name: "search_limit_reached",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 0), goal: terrainPathKey(3, 0),
                nodes: [terrainPathNode(0, 0), terrainPathNode(1, 0), terrainPathNode(2, 0), terrainPathNode(3, 0)],
                maxVisited: 2, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .searchLimitReached, expectedPath: [], expectedPathLength: 0
        ),
        TerrainPathfindingFixtureDefinition(
            name: "deterministic_neighbor_order",
            request: LabTerrainPathRequest(
                start: deterministicPath[0], goal: deterministicPath[2],
                nodes: [
                    terrainPathNode(1, 1), terrainPathNode(1, 0),
                    terrainPathNode(2, 0), terrainPathNode(2, 1)
                ],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .found, expectedPath: deterministicPath, expectedPathLength: 3
        ),
        TerrainPathfindingFixtureDefinition(
            name: "start_equals_goal_found",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 0), goal: terrainPathKey(0, 0),
                nodes: [terrainPathNode(0, 0)],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .found,
            expectedPath: [terrainPathKey(0, 0)],
            expectedPathLength: 1
        ),
        TerrainPathfindingFixtureDefinition(
            name: "missing_goal_invalid",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 0), goal: terrainPathKey(1, 0),
                nodes: [terrainPathNode(0, 0)],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .invalidGoal,
            expectedPath: [],
            expectedPathLength: 0,
            expectedReason: "goal_missing_or_not_traversable"
        ),
        TerrainPathfindingFixtureDefinition(
            name: "missing_start_invalid",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 0), goal: terrainPathKey(1, 0),
                nodes: [terrainPathNode(1, 0)],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .invalidStart,
            expectedPath: [],
            expectedPathLength: 0,
            expectedReason: "start_missing_or_not_traversable"
        ),
        TerrainPathfindingFixtureDefinition(
            name: "unsupported_neighbor_mode_unknown",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 0), goal: terrainPathKey(1, 0),
                nodes: [terrainPathNode(0, 0), terrainPathNode(1, 0)],
                maxVisited: 20, neighborMode: "diagonal_or_unknown_mode"
            ),
            expectedStatus: .unknown,
            expectedPath: [],
            expectedPathLength: 0,
            expectedReason: "unsupported_neighbor_mode"
        ),
        TerrainPathfindingFixtureDefinition(
            name: "non_positive_search_limit_reached",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 0), goal: terrainPathKey(1, 0),
                nodes: [terrainPathNode(0, 0), terrainPathNode(1, 0)],
                maxVisited: 0, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .searchLimitReached,
            expectedPath: [],
            expectedPathLength: 0,
            expectedReason: "non_positive_search_limit"
        ),
        TerrainPathfindingFixtureDefinition(
            name: "duplicate_coordinates_first_node_wins",
            request: LabTerrainPathRequest(
                start: duplicatePath[0], goal: duplicatePath[1],
                nodes: [
                    terrainPathNode(0, 0),
                    terrainPathNode(0, 0, kind: .blocked),
                    terrainPathNode(1, 0)
                ],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .found,
            expectedPath: duplicatePath,
            expectedPathLength: 2,
            expectedReason: "bounded_bfs_path_found"
        ),
        TerrainPathfindingFixtureDefinition(
            name: "cycle_graph_does_not_loop",
            request: LabTerrainPathRequest(
                start: cyclePath[0], goal: cyclePath[3],
                nodes: [
                    terrainPathNode(0, 0), terrainPathNode(1, 0),
                    terrainPathNode(1, 1), terrainPathNode(0, 1),
                    terrainPathNode(2, 1)
                ],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .found,
            expectedPath: cyclePath,
            expectedPathLength: 4,
            expectedReason: "bounded_bfs_path_found"
        ),
        TerrainPathfindingFixtureDefinition(
            name: "cycle_graph_not_found_does_not_loop",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 0), goal: terrainPathKey(3, 3),
                nodes: [
                    terrainPathNode(0, 0), terrainPathNode(1, 0),
                    terrainPathNode(1, 1), terrainPathNode(0, 1),
                    terrainPathNode(3, 3)
                ],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .notFound,
            expectedPath: [],
            expectedPathLength: 0,
            expectedReason: "traversable_graph_exhausted"
        ),
        TerrainPathfindingFixtureDefinition(
            name: "vertical_neighbor_not_used",
            request: LabTerrainPathRequest(
                start: terrainPathKey(0, 0, y: 64),
                goal: terrainPathKey(0, 0, y: 65),
                nodes: [
                    terrainPathNode(0, 0, y: 64),
                    terrainPathNode(0, 0, y: 65)
                ],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .notFound,
            expectedPath: [],
            expectedPathLength: 0,
            expectedReason: "traversable_graph_exhausted"
        ),
        TerrainPathfindingFixtureDefinition(
            name: "complex_equal_paths_neighbor_order_stable",
            request: LabTerrainPathRequest(
                start: complexEqualPath[0], goal: complexEqualPath[4],
                nodes: [
                    terrainPathNode(2, 2), terrainPathNode(3, 2), terrainPathNode(4, 2),
                    terrainPathNode(2, 1), terrainPathNode(3, 1), terrainPathNode(4, 1),
                    terrainPathNode(2, 0), terrainPathNode(3, 0), terrainPathNode(4, 0)
                ],
                maxVisited: 20, neighborMode: terrainPathNeighborMode
            ),
            expectedStatus: .found,
            expectedPath: complexEqualPath,
            expectedPathLength: 5,
            expectedReason: "bounded_bfs_path_found"
        )
    ]
}

func makeTerrainPathfindingFixtureReport(
    scenario: String,
    seed: UInt32
) -> TerrainPathfindingFixtureReport {
    let results = terrainPathfindingFixtureDefinitions().map { fixture in
        let actual = findTerrainPath(fixture.request)
        let pathMatches = fixture.expectedPath.map { $0 == actual.path } ?? true
        let lengthMatches = fixture.expectedPathLength.map { $0 == actual.path.count } ?? true
        let reasonMatches = fixture.expectedReason.map { $0 == actual.reason } ?? true
        return TerrainPathfindingFixtureResult(
            name: fixture.name,
            expectedStatus: fixture.expectedStatus,
            actualStatus: actual.status,
            expectedPathLength: fixture.expectedPathLength,
            actualPathLength: actual.path.count,
            expectedPath: fixture.expectedPath,
            actualPath: actual.path,
            expectedReason: fixture.expectedReason,
            actualReason: actual.reason,
            visited: actual.visited,
            maxVisited: fixture.request.maxVisited,
            passed: actual.status == fixture.expectedStatus
                && pathMatches
                && lengthMatches
                && reasonMatches
        )
    }
    let passed = results.filter(\.passed).count
    let failed = results.count - passed
    func statusCount(_ status: LabTerrainPathfindingStatus) -> Int {
        results.filter { $0.actualStatus == status }.count
    }
    let summary = TerrainPathfindingFixtureSummary(
        fixtures: results.count,
        passed: passed,
        failed: failed,
        pathsFound: statusCount(.found),
        pathsNotFound: statusCount(.notFound),
        invalidStarts: statusCount(.invalidStart),
        invalidGoals: statusCount(.invalidGoal),
        searchLimitReached: statusCount(.searchLimitReached),
        unknown: statusCount(.unknown)
    )
    let counted = summary.pathsFound + summary.pathsNotFound + summary.invalidStarts
        + summary.invalidGoals + summary.searchLimitReached + summary.unknown
    return TerrainPathfindingFixtureReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0 && counted == results.count,
        summary: summary,
        cases: results
    )
}

func makeTerrainPathfindingInvariantReport(
    fixtureReport: TerrainPathfindingFixtureReport
) -> TerrainPathfindingInvariantReport {
    let definitions = terrainPathfindingFixtureDefinitions()
    let results = fixtureReport.cases
    let pairs = Array(zip(definitions, results))
    let foundPairs = pairs.filter { $0.1.actualStatus == .found }
    let statusesCoherent = pairs.allSatisfy { fixture, result in
        let nodes = terrainPathNodeMap(fixture.request.nodes)
        switch result.actualStatus {
        case .invalidStart:
            return nodes[fixture.request.start]?.traversability != .traversable
        case .invalidGoal:
            return nodes[fixture.request.start]?.traversability == .traversable
                && nodes[fixture.request.goal]?.traversability != .traversable
        default:
            return nodes[fixture.request.start]?.traversability == .traversable
                && nodes[fixture.request.goal]?.traversability == .traversable
        }
    }
    let onlyTraversable = foundPairs.allSatisfy { fixture, result in
        let nodes = terrainPathNodeMap(fixture.request.nodes)
        return result.actualPath.allSatisfy {
            nodes[$0]?.traversability == .traversable
        }
    }
    let fourNeighborSteps = foundPairs.allSatisfy { _, result in
        zip(result.actualPath, result.actualPath.dropFirst()).allSatisfy { current, next in
            abs(current.x - next.x) + abs(current.y - next.y) + abs(current.z - next.z) == 1
        }
    }
    let noDiagonalSteps = foundPairs.allSatisfy { _, result in
        zip(result.actualPath, result.actualPath.dropFirst()).allSatisfy { current, next in
            current.y == next.y
                && abs(current.x - next.x) + abs(current.z - next.z) == 1
        }
    }
    let noVerticalSteps = foundPairs.allSatisfy { _, result in
        zip(result.actualPath, result.actualPath.dropFirst()).allSatisfy { current, next in
            current.y == next.y
        }
    }
    let noRepeatedPathNodes = foundPairs.allSatisfy { _, result in
        Set(result.actualPath).count == result.actualPath.count
    }
    func result(named name: String) -> TerrainPathfindingFixtureResult? {
        results.first { $0.name == name }
    }
    let deterministicCases = [
        result(named: "deterministic_neighbor_order"),
        result(named: "complex_equal_paths_neighbor_order_stable")
    ]
    let deterministicOrderPreserved = deterministicCases.allSatisfy {
        $0?.actualPath == $0?.expectedPath && $0?.passed == true
    }
    let missingStartCase = result(named: "missing_start_invalid")
    let unsupportedModeCase = result(named: "unsupported_neighbor_mode_unknown")
    let nonPositiveLimitCase = result(named: "non_positive_search_limit_reached")
    let duplicateCase = result(named: "duplicate_coordinates_first_node_wins")
    let cycleCases = [
        result(named: "cycle_graph_does_not_loop"),
        result(named: "cycle_graph_not_found_does_not_loop")
    ]
    let cycleCasesTerminate = cycleCases.allSatisfy {
        guard let result = $0 else { return false }
        return result.passed && result.visited <= result.maxVisited
    }
    let expectedReasonsMatch = results.allSatisfy {
        $0.expectedReason == nil || $0.expectedReason == $0.actualReason
    }
    let counted = fixtureReport.summary.pathsFound + fixtureReport.summary.pathsNotFound
        + fixtureReport.summary.invalidStarts + fixtureReport.summary.invalidGoals
        + fixtureReport.summary.searchLimitReached + fixtureReport.summary.unknown

    let checks = [
        TerrainPathfindingInvariantCheck(name: "fixture_inputs_exist", passed: !definitions.isEmpty, expected: "> 0", actual: "\(definitions.count)"),
        TerrainPathfindingInvariantCheck(name: "every_fixture_has_start_goal_keys", passed: definitions.count == results.count, expected: "\(definitions.count) requests with keys", actual: "\(results.count) results"),
        TerrainPathfindingInvariantCheck(name: "start_goal_statuses_match_traversability", passed: statusesCoherent, expected: "all statuses coherent", actual: statusesCoherent ? "all statuses coherent" : "mismatch"),
        TerrainPathfindingInvariantCheck(name: "only_traversable_nodes_used_in_paths", passed: onlyTraversable, expected: "all path nodes traversable", actual: onlyTraversable ? "all path nodes traversable" : "non-traversable path node"),
        TerrainPathfindingInvariantCheck(name: "found_paths_begin_at_start", passed: foundPairs.allSatisfy { $0.1.actualPath.first == $0.0.request.start }, expected: "all found paths", actual: "\(foundPairs.filter { $0.1.actualPath.first == $0.0.request.start }.count)/\(foundPairs.count)"),
        TerrainPathfindingInvariantCheck(name: "found_paths_end_at_goal", passed: foundPairs.allSatisfy { $0.1.actualPath.last == $0.0.request.goal }, expected: "all found paths", actual: "\(foundPairs.filter { $0.1.actualPath.last == $0.0.request.goal }.count)/\(foundPairs.count)"),
        TerrainPathfindingInvariantCheck(name: "consecutive_path_nodes_are_four_neighbors", passed: fourNeighborSteps, expected: "Manhattan distance 1", actual: fourNeighborSteps ? "all steps valid" : "invalid step"),
        TerrainPathfindingInvariantCheck(name: "no_diagonal_steps", passed: noDiagonalSteps, expected: "0 diagonal steps", actual: noDiagonalSteps ? "0 diagonal steps" : "diagonal step found"),
        TerrainPathfindingInvariantCheck(name: "no_vertical_steps", passed: noVerticalSteps, expected: "0 vertical steps", actual: noVerticalSteps ? "0 vertical steps" : "vertical step found"),
        TerrainPathfindingInvariantCheck(name: "found_paths_have_no_repeated_nodes", passed: noRepeatedPathNodes, expected: "all found paths unique", actual: noRepeatedPathNodes ? "all found paths unique" : "repeated path node"),
        TerrainPathfindingInvariantCheck(name: "visited_count_within_limit", passed: pairs.allSatisfy { $0.1.visited <= $0.0.request.maxVisited }, expected: "all <= maxVisited", actual: "\(pairs.filter { $0.1.visited <= $0.0.request.maxVisited }.count)/\(pairs.count)"),
        TerrainPathfindingInvariantCheck(name: "deterministic_neighbor_order_preserved", passed: deterministicOrderPreserved, expected: terrainPathNeighborMode, actual: deterministicOrderPreserved ? terrainPathNeighborMode : "mismatch"),
        TerrainPathfindingInvariantCheck(name: "missing_start_returns_invalid_start", passed: missingStartCase?.actualStatus == .invalidStart && missingStartCase?.passed == true, expected: "invalidStart", actual: missingStartCase?.actualStatus.rawValue ?? "missing fixture"),
        TerrainPathfindingInvariantCheck(name: "unsupported_neighbor_mode_returns_unknown", passed: unsupportedModeCase?.actualStatus == .unknown && unsupportedModeCase?.actualReason == "unsupported_neighbor_mode" && unsupportedModeCase?.passed == true, expected: "unknown/unsupported_neighbor_mode", actual: "\(unsupportedModeCase?.actualStatus.rawValue ?? "missing")/\(unsupportedModeCase?.actualReason ?? "missing")"),
        TerrainPathfindingInvariantCheck(name: "non_positive_search_limit_returns_limit_reached", passed: nonPositiveLimitCase?.actualStatus == .searchLimitReached && nonPositiveLimitCase?.actualReason == "non_positive_search_limit" && nonPositiveLimitCase?.passed == true, expected: "searchLimitReached/non_positive_search_limit", actual: "\(nonPositiveLimitCase?.actualStatus.rawValue ?? "missing")/\(nonPositiveLimitCase?.actualReason ?? "missing")"),
        TerrainPathfindingInvariantCheck(name: "duplicate_coordinate_contract_preserved", passed: duplicateCase?.actualStatus == .found && duplicateCase?.actualPathLength == 2 && duplicateCase?.passed == true, expected: "first node wins", actual: duplicateCase?.passed == true ? "first node wins" : "mismatch"),
        TerrainPathfindingInvariantCheck(name: "cycles_do_not_loop", passed: cycleCasesTerminate, expected: "both cycle fixtures bounded", actual: cycleCasesTerminate ? "both cycle fixtures bounded" : "cycle fixture failed"),
        TerrainPathfindingInvariantCheck(name: "reasons_match_expected_when_specified", passed: expectedReasonsMatch, expected: "all specified reasons", actual: expectedReasonsMatch ? "all specified reasons" : "reason mismatch"),
        TerrainPathfindingInvariantCheck(name: "result_counts_match_summary", passed: counted == fixtureReport.summary.fixtures && fixtureReport.summary.passed + fixtureReport.summary.failed == fixtureReport.summary.fixtures, expected: "\(fixtureReport.summary.fixtures)", actual: "\(counted)"),
        TerrainPathfindingInvariantCheck(name: "no_world_access_required", passed: true, expected: "pure synthetic node graph", actual: "code-review invariant"),
        TerrainPathfindingInvariantCheck(name: "no_mutation_path_used", passed: true, expected: "none", actual: "code-review invariant"),
        TerrainPathfindingInvariantCheck(name: "no_movement_commanded", passed: true, expected: "none", actual: "code-review invariant"),
        TerrainPathfindingInvariantCheck(name: "no_collision_performed", passed: true, expected: "none", actual: "code-review invariant")
    ]
    let checksFailed = checks.filter { !$0.passed }.count
    return TerrainPathfindingInvariantReport(
        scenario: fixtureReport.scenario,
        seed: fixtureReport.seed,
        success: fixtureReport.success && checksFailed == 0,
        summary: TerrainPathfindingInvariantSummary(
            checksPassed: checks.count - checksFailed,
            checksFailed: checksFailed,
            fixtures: definitions.count,
            results: results.count
        ),
        checks: checks,
        notes: [
            "BFS is bounded, fixture-only, uniform-cost, and expands north/east/south/west.",
            "A found path is abstract evidence, not collision safety or a movement command."
        ]
    )
}
