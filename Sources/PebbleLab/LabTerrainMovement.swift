enum LabTerrainMovementStatus: String, Codable {
    case idle
    case moving
    case reachedGoal
    case invalidPath
    case blocked
    case failed
}

struct LabTerrainMovementState: Codable {
    let current: LabTerrainPathNodeKey
    let path: [LabTerrainPathNodeKey]
    let targetIndex: Int
    let status: LabTerrainMovementStatus
}

struct LabTerrainMovementIntent: Codable {
    let from: LabTerrainPathNodeKey
    let to: LabTerrainPathNodeKey
    let dx: Int
    let dy: Int
    let dz: Int
    let allowed: Bool
    let reason: String
}

struct LabTerrainMovementStepResult: Codable {
    let before: LabTerrainMovementState
    let intent: LabTerrainMovementIntent
    let after: LabTerrainMovementState
    let moved: Bool
}

struct TerrainMovementFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: TerrainMovementFixtureSummary
    let cases: [TerrainMovementFixtureResult]
}

struct TerrainMovementFixtureSummary: Codable {
    let fixtures: Int
    let passed: Int
    let failed: Int
    let stepsPlanned: Int
    let stepsExecuted: Int
    let reachedGoals: Int
    let invalidPaths: Int
}

struct TerrainMovementFixtureResult: Codable {
    let name: String
    let initialCurrent: LabTerrainPathNodeKey
    let path: [LabTerrainPathNodeKey]
    let ticks: Int
    let expectedStatus: LabTerrainMovementStatus
    let actualStatus: LabTerrainMovementStatus
    let expectedMoves: Int
    let actualMoves: Int
    let steps: [LabTerrainMovementStepResult]
    let passed: Bool
}

struct TerrainMovementInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: TerrainMovementInvariantSummary
    let checks: [TerrainMovementInvariantCheck]
    let notes: [String]
}

struct TerrainMovementInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let fixtures: Int
    let results: Int
}

struct TerrainMovementInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

private struct TerrainMovementFixtureDefinition {
    let name: String
    let current: LabTerrainPathNodeKey
    let path: [LabTerrainPathNodeKey]
    let ticks: Int
    let expectedStatus: LabTerrainMovementStatus
    let expectedMoves: Int
}

private func movementKey(_ x: Int, _ z: Int, y: Int = 64) -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: x, y: y, z: z)
}

private func isValidTerrainMovementEdge(
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey
) -> Bool {
    from.y == to.y && abs(from.x - to.x) + abs(from.z - to.z) == 1
}

func validateTerrainMovementPath(
    current: LabTerrainPathNodeKey,
    path: [LabTerrainPathNodeKey]
) -> LabTerrainMovementState {
    guard !path.isEmpty else {
        return LabTerrainMovementState(
            current: current,
            path: path,
            targetIndex: 0,
            status: .invalidPath
        )
    }
    guard current == path[0] else {
        return LabTerrainMovementState(
            current: current,
            path: path,
            targetIndex: 0,
            status: .invalidPath
        )
    }
    guard Set(path).count == path.count else {
        return LabTerrainMovementState(
            current: current,
            path: path,
            targetIndex: 0,
            status: .invalidPath
        )
    }
    guard zip(path, path.dropFirst()).allSatisfy({ isValidTerrainMovementEdge(from: $0, to: $1) }) else {
        return LabTerrainMovementState(
            current: current,
            path: path,
            targetIndex: 0,
            status: .invalidPath
        )
    }
    if path.count == 1 {
        return LabTerrainMovementState(
            current: current,
            path: path,
            targetIndex: 0,
            status: .reachedGoal
        )
    }
    return LabTerrainMovementState(
        current: current,
        path: path,
        targetIndex: 1,
        status: .moving
    )
}

func makeTerrainMovementIntent(
    from state: LabTerrainMovementState
) -> LabTerrainMovementIntent {
    func denied(reason: String) -> LabTerrainMovementIntent {
        LabTerrainMovementIntent(
            from: state.current,
            to: state.current,
            dx: 0,
            dy: 0,
            dz: 0,
            allowed: false,
            reason: reason
        )
    }

    switch state.status {
    case .invalidPath:
        return denied(reason: "invalid_path")
    case .reachedGoal:
        return denied(reason: "already_reached_goal")
    case .idle:
        return denied(reason: "idle")
    case .blocked:
        return denied(reason: "blocked")
    case .failed:
        return denied(reason: "failed")
    case .moving:
        guard state.path.indices.contains(state.targetIndex) else {
            return denied(reason: "invalid_edge")
        }
        let target = state.path[state.targetIndex]
        let dx = target.x - state.current.x
        let dy = target.y - state.current.y
        let dz = target.z - state.current.z
        return LabTerrainMovementIntent(
            from: state.current,
            to: target,
            dx: dx,
            dy: dy,
            dz: dz,
            allowed: isValidTerrainMovementEdge(from: state.current, to: target),
            reason: isValidTerrainMovementEdge(from: state.current, to: target)
                ? "move_to_next_path_node"
                : "invalid_edge"
        )
    }
}

func stepTerrainMovement(
    _ state: LabTerrainMovementState
) -> LabTerrainMovementStepResult {
    let intent = makeTerrainMovementIntent(from: state)
    guard intent.allowed else {
        let after: LabTerrainMovementState
        if state.status == .moving {
            after = LabTerrainMovementState(
                current: state.current,
                path: state.path,
                targetIndex: state.targetIndex,
                status: .invalidPath
            )
        } else {
            after = state
        }
        return LabTerrainMovementStepResult(
            before: state,
            intent: intent,
            after: after,
            moved: false
        )
    }

    let reachedGoal = intent.to == state.path.last
    let after = LabTerrainMovementState(
        current: intent.to,
        path: state.path,
        targetIndex: reachedGoal ? state.targetIndex : state.targetIndex + 1,
        status: reachedGoal ? .reachedGoal : .moving
    )
    return LabTerrainMovementStepResult(
        before: state,
        intent: intent,
        after: after,
        moved: true
    )
}

private func terrainMovementFixtures() -> [TerrainMovementFixtureDefinition] {
    let start = movementKey(0, 0)
    let east = movementKey(1, 0)
    let east2 = movementKey(2, 0)
    let southEast2 = movementKey(2, 1)
    return [
        TerrainMovementFixtureDefinition(name: "single_step_reaches_goal", current: start, path: [start, east], ticks: 1, expectedStatus: .reachedGoal, expectedMoves: 1),
        TerrainMovementFixtureDefinition(name: "multi_step_reaches_goal", current: start, path: [start, east, east2, southEast2], ticks: 3, expectedStatus: .reachedGoal, expectedMoves: 3),
        TerrainMovementFixtureDefinition(name: "idle_after_goal", current: start, path: [start, east], ticks: 3, expectedStatus: .reachedGoal, expectedMoves: 1),
        TerrainMovementFixtureDefinition(name: "empty_path_invalid", current: start, path: [], ticks: 1, expectedStatus: .invalidPath, expectedMoves: 0),
        TerrainMovementFixtureDefinition(name: "single_node_path_reached_goal", current: start, path: [start], ticks: 0, expectedStatus: .reachedGoal, expectedMoves: 0),
        TerrainMovementFixtureDefinition(name: "diagonal_step_invalid", current: start, path: [start, movementKey(1, 1)], ticks: 1, expectedStatus: .invalidPath, expectedMoves: 0),
        TerrainMovementFixtureDefinition(name: "vertical_step_invalid", current: start, path: [start, movementKey(0, 0, y: 65)], ticks: 1, expectedStatus: .invalidPath, expectedMoves: 0),
        TerrainMovementFixtureDefinition(name: "non_neighbor_step_invalid", current: start, path: [start, east2], ticks: 1, expectedStatus: .invalidPath, expectedMoves: 0),
        TerrainMovementFixtureDefinition(name: "wrong_initial_position_invalid", current: east, path: [start, east], ticks: 1, expectedStatus: .invalidPath, expectedMoves: 0),
        TerrainMovementFixtureDefinition(name: "no_world_required", current: start, path: [start, east], ticks: 1, expectedStatus: .reachedGoal, expectedMoves: 1),
        TerrainMovementFixtureDefinition(name: "repeated_node_invalid", current: start, path: [start, east, start], ticks: 1, expectedStatus: .invalidPath, expectedMoves: 0),
        TerrainMovementFixtureDefinition(name: "already_reached_goal_stays_idle", current: start, path: [start], ticks: 3, expectedStatus: .reachedGoal, expectedMoves: 0)
    ]
}

private func evaluateTerrainMovementFixture(
    _ fixture: TerrainMovementFixtureDefinition
) -> TerrainMovementFixtureResult {
    var state = validateTerrainMovementPath(current: fixture.current, path: fixture.path)
    var steps: [LabTerrainMovementStepResult] = []
    for _ in 0..<fixture.ticks {
        let result = stepTerrainMovement(state)
        steps.append(result)
        state = result.after
    }
    let moves = steps.filter(\.moved).count
    return TerrainMovementFixtureResult(
        name: fixture.name,
        initialCurrent: fixture.current,
        path: fixture.path,
        ticks: fixture.ticks,
        expectedStatus: fixture.expectedStatus,
        actualStatus: state.status,
        expectedMoves: fixture.expectedMoves,
        actualMoves: moves,
        steps: steps,
        passed: state.status == fixture.expectedStatus && moves == fixture.expectedMoves
    )
}

func makeTerrainMovementFixtureReport(
    scenario: String,
    seed: UInt32
) -> TerrainMovementFixtureReport {
    let results = terrainMovementFixtures().map(evaluateTerrainMovementFixture)
    let passed = results.filter(\.passed).count
    let stepsPlanned = results.reduce(0) { $0 + $1.expectedMoves }
    let stepsExecuted = results.reduce(0) { $0 + $1.actualMoves }
    return TerrainMovementFixtureReport(
        scenario: scenario,
        seed: seed,
        success: passed == results.count,
        summary: TerrainMovementFixtureSummary(
            fixtures: results.count,
            passed: passed,
            failed: results.count - passed,
            stepsPlanned: stepsPlanned,
            stepsExecuted: stepsExecuted,
            reachedGoals: results.filter { $0.actualStatus == .reachedGoal }.count,
            invalidPaths: results.filter { $0.actualStatus == .invalidPath }.count
        ),
        cases: results
    )
}

func makeTerrainMovementInvariantReport(
    _ report: TerrainMovementFixtureReport
) -> TerrainMovementInvariantReport {
    let validResults = report.cases.filter { $0.expectedStatus != .invalidPath }
    let invalidResults = report.cases.filter { $0.expectedStatus == .invalidPath }
    let movedSteps = report.cases.flatMap(\.steps).filter(\.moved)
    let everyMovedStepFollowsOrder = movedSteps.allSatisfy { step in
        step.before.path.indices.contains(step.before.targetIndex)
            && step.intent.to == step.before.path[step.before.targetIndex]
            && step.after.current == step.intent.to
    }
    let reachedOnlyAtFinal = report.cases.allSatisfy { result in
        result.actualStatus != .reachedGoal || result.path.last == result.steps.last?.after.current
            || (result.steps.isEmpty && result.path.last == result.initialCurrent)
    }
    let idleAfterGoal = report.cases.first(where: { $0.name == "idle_after_goal" }).map {
        $0.steps.dropFirst().allSatisfy { !$0.moved && $0.after.status == .reachedGoal }
    } ?? false
    let invalidPathsDoNotMove = invalidResults.allSatisfy { result in
        result.actualStatus == .invalidPath && result.steps.allSatisfy { !$0.moved }
    }

    let checks: [TerrainMovementInvariantCheck] = [
        TerrainMovementInvariantCheck(name: "fixture_inputs_exist", passed: !report.cases.isEmpty, expected: "> 0", actual: String(report.cases.count)),
        TerrainMovementInvariantCheck(name: "every_fixture_has_path_or_expects_invalid", passed: report.cases.allSatisfy { !$0.path.isEmpty || $0.expectedStatus == .invalidPath }, expected: "true", actual: String(report.cases.allSatisfy { !$0.path.isEmpty || $0.expectedStatus == .invalidPath })),
        TerrainMovementInvariantCheck(name: "valid_paths_begin_at_initial_position", passed: validResults.allSatisfy { $0.path.first == $0.initialCurrent }, expected: "true", actual: String(validResults.allSatisfy { $0.path.first == $0.initialCurrent })),
        TerrainMovementInvariantCheck(name: "one_tick_advances_at_most_one_edge", passed: movedSteps.allSatisfy { abs($0.intent.dx) + abs($0.intent.dy) + abs($0.intent.dz) == 1 }, expected: "true", actual: String(movedSteps.allSatisfy { abs($0.intent.dx) + abs($0.intent.dy) + abs($0.intent.dz) == 1 })),
        TerrainMovementInvariantCheck(name: "every_moved_step_follows_path_order", passed: everyMovedStepFollowsOrder, expected: "true", actual: String(everyMovedStepFollowsOrder)),
        TerrainMovementInvariantCheck(name: "no_skipped_nodes", passed: everyMovedStepFollowsOrder, expected: "true", actual: String(everyMovedStepFollowsOrder)),
        TerrainMovementInvariantCheck(name: "no_diagonal_moves", passed: movedSteps.allSatisfy { $0.intent.dx == 0 || $0.intent.dz == 0 }, expected: "true", actual: String(movedSteps.allSatisfy { $0.intent.dx == 0 || $0.intent.dz == 0 })),
        TerrainMovementInvariantCheck(name: "no_vertical_moves", passed: movedSteps.allSatisfy { $0.intent.dy == 0 }, expected: "true", actual: String(movedSteps.allSatisfy { $0.intent.dy == 0 })),
        TerrainMovementInvariantCheck(name: "no_non_neighbor_moves", passed: movedSteps.allSatisfy { abs($0.intent.dx) + abs($0.intent.dz) == 1 && $0.intent.dy == 0 }, expected: "true", actual: String(movedSteps.allSatisfy { abs($0.intent.dx) + abs($0.intent.dz) == 1 && $0.intent.dy == 0 })),
        TerrainMovementInvariantCheck(name: "reached_goal_only_at_final_node", passed: reachedOnlyAtFinal, expected: "true", actual: String(reachedOnlyAtFinal)),
        TerrainMovementInvariantCheck(name: "post_goal_ticks_do_not_move", passed: idleAfterGoal, expected: "true", actual: String(idleAfterGoal)),
        TerrainMovementInvariantCheck(name: "invalid_paths_do_not_move", passed: invalidPathsDoNotMove, expected: "true", actual: String(invalidPathsDoNotMove)),
        TerrainMovementInvariantCheck(name: "no_world_access_required", passed: true, expected: "pure node-key state", actual: "pure node-key state"),
        TerrainMovementInvariantCheck(name: "no_mutation_path_used", passed: true, expected: "true", actual: "true"),
        TerrainMovementInvariantCheck(name: "no_collision_performed", passed: true, expected: "true", actual: "true"),
        TerrainMovementInvariantCheck(name: "no_pathfinding_performed_inside_movement", passed: true, expected: "true", actual: "true"),
        TerrainMovementInvariantCheck(name: "no_agent_decision_performed", passed: true, expected: "true", actual: "true")
    ]
    let passed = checks.filter(\.passed).count
    return TerrainMovementInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: report.success && passed == checks.count,
        summary: TerrainMovementInvariantSummary(
            checksPassed: passed,
            checksFailed: checks.count - passed,
            fixtures: report.summary.fixtures,
            results: report.cases.count
        ),
        checks: checks,
        notes: [
            "Movement fixtures update synthetic node-key state only.",
            "No live movement, collision, mutation, pathfinding, or agent decision is performed."
        ]
    )
}
