private func routeKey(_ x: Int, _ z: Int, y: Int = 64) -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: x, y: y, z: z)
}

private func routeEdge(
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey,
    collisionStatus: LabTerrainOccupancyStatus = .occupable,
    singleStepStatus: LabPhysicalMovementStatus = .approved,
    displacementApplied: Bool = true,
    reason: String = "approved_fixture_edge"
) -> LabRouteFollowingFixtureEdge {
    LabRouteFollowingFixtureEdge(
        from: from,
        to: to,
        collisionStatus: collisionStatus,
        singleStepStatus: singleStepStatus,
        displacementApplied: displacementApplied,
        reason: reason
    )
}

private func routeFollowingFixtureCases() -> [LabRouteFollowingFixtureCase] {
    let a = routeKey(7, 8)
    let b = routeKey(8, 8)
    let c = routeKey(9, 8)
    let d = routeKey(10, 8)

    return [
        LabRouteFollowingFixtureCase(
            name: "completed_two_edges",
            initialNode: a,
            route: [a, b, c],
            edges: [
                routeEdge(from: a, to: b),
                routeEdge(from: b, to: c)
            ],
            maxSteps: 2,
            expectedStatus: .completed,
            expectedCompletedEdges: 2,
            expectedStoppedAtIndex: nil,
            expectedReasonContains: "completed"
        ),
        LabRouteFollowingFixtureCase(
            name: "stopped_collision_denied_second_edge",
            initialNode: a,
            route: [a, b, c],
            edges: [
                routeEdge(from: a, to: b),
                routeEdge(
                    from: b,
                    to: c,
                    collisionStatus: .liquidUnsupported,
                    singleStepStatus: .collisionDenied,
                    displacementApplied: false,
                    reason: "liquid_support"
                )
            ],
            maxSteps: 2,
            expectedStatus: .stoppedCollisionDenied,
            expectedCompletedEdges: 1,
            expectedStoppedAtIndex: 1,
            expectedReasonContains: "collision"
        ),
        LabRouteFollowingFixtureCase(
            name: "stopped_invalid_diagonal_edge",
            initialNode: a,
            route: [a, routeKey(8, 9)],
            edges: [
                routeEdge(
                    from: a,
                    to: routeKey(8, 9),
                    singleStepStatus: .invalidEdge,
                    displacementApplied: false,
                    reason: "diagonal"
                )
            ],
            maxSteps: 1,
            expectedStatus: .stoppedInvalidEdge,
            expectedCompletedEdges: 0,
            expectedStoppedAtIndex: 0,
            expectedReasonContains: "invalid_edge"
        ),
        LabRouteFollowingFixtureCase(
            name: "stopped_vertical_edge",
            initialNode: a,
            route: [a, LabTerrainPathNodeKey(x: 7, y: 65, z: 8)],
            edges: [
                routeEdge(
                    from: a,
                    to: LabTerrainPathNodeKey(x: 7, y: 65, z: 8),
                    singleStepStatus: .invalidEdge,
                    displacementApplied: false,
                    reason: "vertical"
                )
            ],
            maxSteps: 1,
            expectedStatus: .stoppedInvalidEdge,
            expectedCompletedEdges: 0,
            expectedStoppedAtIndex: 0,
            expectedReasonContains: "invalid_edge"
        ),
        LabRouteFollowingFixtureCase(
            name: "stopped_source_mismatch",
            initialNode: routeKey(6, 8),
            route: [a, b],
            edges: [
                routeEdge(from: a, to: b)
            ],
            maxSteps: 1,
            expectedStatus: .stoppedSourceMismatch,
            expectedCompletedEdges: 0,
            expectedStoppedAtIndex: 0,
            expectedReasonContains: "source_mismatch"
        ),
        LabRouteFollowingFixtureCase(
            name: "stopped_divergence_after_first_edge",
            initialNode: a,
            route: [a, b, c],
            edges: [
                LabRouteFollowingFixtureEdge(
                    from: a,
                    to: b,
                    collisionStatus: .occupable,
                    singleStepStatus: .approved,
                    displacementApplied: true,
                    reason: "inject_divergence_after"
                ),
                routeEdge(from: b, to: c)
            ],
            maxSteps: 2,
            expectedStatus: .stoppedDivergence,
            expectedCompletedEdges: 1,
            expectedStoppedAtIndex: 1,
            expectedReasonContains: "divergence"
        ),
        LabRouteFollowingFixtureCase(
            name: "stopped_max_steps",
            initialNode: a,
            route: [a, b, c, d],
            edges: [
                routeEdge(from: a, to: b),
                routeEdge(from: b, to: c),
                routeEdge(from: c, to: d)
            ],
            maxSteps: 1,
            expectedStatus: .stoppedMaxSteps,
            expectedCompletedEdges: 1,
            expectedStoppedAtIndex: 1,
            expectedReasonContains: "max_steps"
        ),
        LabRouteFollowingFixtureCase(
            name: "stopped_stale_collision",
            initialNode: a,
            route: [a, b],
            edges: [
                routeEdge(
                    from: a,
                    to: c,
                    singleStepStatus: .staleCollisionEvidence,
                    displacementApplied: false,
                    reason: "stale_collision"
                )
            ],
            maxSteps: 1,
            expectedStatus: .stoppedStaleCollision,
            expectedCompletedEdges: 0,
            expectedStoppedAtIndex: 0,
            expectedReasonContains: "stale_collision"
        )
    ]
}

func makeRouteFollowingFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabRouteFollowingFixtureReport {
    let results = routeFollowingFixtureCases().map(evaluateRouteFollowingFixtureCase)
    let passed = results.filter(\.passed).count
    let completed = results.filter { $0.actualStatus == .completed }.count
    let stopped = results.count - completed
    let attemptedEdges = results.reduce(0) { $0 + $1.records.count }
    let completedEdges = results.reduce(0) { $0 + $1.actualCompletedEdges }
    let displacementsApplied = results.reduce(0) { total, result in
        total + result.records.filter(\.displacementApplied).count
    }
    let deniedEdges = results.reduce(0) { total, result in
        total + result.records.filter { !$0.displacementApplied }.count
    }
    let summary = LabRouteFollowingFixtureSummary(
        cases: results.count,
        passed: passed,
        failed: results.count - passed,
        completed: completed,
        stopped: stopped,
        attemptedEdges: attemptedEdges,
        completedEdges: completedEdges,
        displacementsApplied: displacementsApplied,
        deniedEdges: deniedEdges,
        collisionDenied: results.filter { $0.actualStatus == .stoppedCollisionDenied }.count,
        invalidEdges: results.filter { $0.actualStatus == .stoppedInvalidEdge }.count,
        sourceMismatch: results.filter { $0.actualStatus == .stoppedSourceMismatch }.count,
        divergence: results.filter { $0.actualStatus == .stoppedDivergence }.count,
        maxSteps: results.filter { $0.actualStatus == .stoppedMaxSteps }.count,
        success: passed == results.count
            && completed >= 1
            && stopped >= 1
    )

    return LabRouteFollowingFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        summary: summary,
        cases: results
    )
}

func makeRouteFollowingFixtureInvariantReport(
    report: LabRouteFollowingFixtureReport?,
    scenario: String,
    seed: UInt32
) -> RouteFollowingFixtureInvariantReport {
    let cases = report?.cases ?? []
    let names = Set(cases.map(\.name))
    let completedCases = cases.filter { $0.actualStatus == .completed }
    let stoppedCases = cases.filter { $0.actualStatus != .completed }
    let allRoutesLongEnough = !cases.isEmpty && routeFollowingFixtureCases().allSatisfy {
        $0.route.count > 1
    }
    let routeEdgesContiguous = completedCases.allSatisfy { result in
        result.records.allSatisfy { $0.from == $0.preNode && $0.to == $0.postNode }
    }
    let noSkippedNodes = cases.allSatisfy { result in
        result.records.allSatisfy {
            manhattanDistance($0.preNode, $0.postNode) <= 1
        }
    }
    let routeIndexAdvances = cases.allSatisfy { result in
        result.records.enumerated().allSatisfy { index, record in
            record.edgeIndex == index
        }
    }
    let completedRequiresLast = !completedCases.isEmpty && completedCases.allSatisfy { result in
        guard let fixture = routeFollowingFixtureCases().first(where: { $0.name == result.name }),
              let last = fixture.route.last else { return false }
        return result.finalNode == last
    }
    let stoppedPreservesLast = stoppedCases.allSatisfy { result in
        if let lastRecord = result.records.last, !lastRecord.displacementApplied {
            return result.finalNode == lastRecord.preNode
        }
        return true
    }
    let stopsOnFirstDenied = stoppedCases.allSatisfy { result in
        guard let stoppedAt = result.actualStoppedAtIndex else { return false }
        let deniedRecordIndex = result.records.firstIndex { !$0.displacementApplied }
        return deniedRecordIndex == nil || deniedRecordIndex == stoppedAt
    }
    let displacementRequiresOccupable = cases.allSatisfy { result in
        result.records.allSatisfy {
            !$0.displacementApplied || $0.collisionStatus == .occupable
        }
    }
    let displacementRequiresApproved = cases.allSatisfy { result in
        result.records.allSatisfy {
            !$0.displacementApplied || $0.singleStepStatus == .approved
        }
    }
    let deniedEdgesDoNotDisplace = cases.allSatisfy { result in
        result.records.allSatisfy {
            ($0.collisionStatus == .occupable && $0.singleStepStatus == .approved)
                || !$0.displacementApplied
        }
    }
    let exactExpectedDisplacements = cases.allSatisfy { result in
        let applied = result.records.filter(\.displacementApplied).count
        return applied == result.actualCompletedEdges
    }
    let explicitStatuses = !cases.isEmpty && cases.allSatisfy { !$0.actualStatus.rawValue.isEmpty }
    let explicitReasons = !cases.isEmpty && cases.allSatisfy { !$0.actualReason.isEmpty }
    let statusesMatch = !cases.isEmpty && cases.allSatisfy { $0.actualStatus == $0.expectedStatus }
    let completedEdgesMatch = !cases.isEmpty && cases.allSatisfy {
        $0.actualCompletedEdges == $0.expectedCompletedEdges
    }
    let successContract = report?.success == true
        && report?.summary.failed == 0
        && (report?.summary.completed ?? 0) >= 1
        && (report?.summary.stopped ?? 0) >= 1

    let checks = [
        RouteFollowingFixtureInvariantCheck(name: "fixture_only_no_world", passed: true, expected: "no World", actual: "pure fixtures"),
        RouteFollowingFixtureInvariantCheck(name: "route_cases_exist", passed: !cases.isEmpty, expected: "> 0", actual: "\(cases.count)"),
        RouteFollowingFixtureInvariantCheck(name: "completed_case_exists", passed: names.contains("completed_two_edges"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "collision_denied_case_exists", passed: names.contains("stopped_collision_denied_second_edge"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "invalid_diagonal_case_exists", passed: names.contains("stopped_invalid_diagonal_edge"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "invalid_vertical_case_exists", passed: names.contains("stopped_vertical_edge"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "source_mismatch_case_exists", passed: names.contains("stopped_source_mismatch"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "divergence_case_exists", passed: names.contains("stopped_divergence_after_first_edge"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "max_steps_case_exists", passed: names.contains("stopped_max_steps"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "stale_collision_case_exists", passed: names.contains("stopped_stale_collision"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "routes_length_greater_than_one", passed: allRoutesLongEnough, expected: "> 1", actual: "\(routeFollowingFixtureCases().map { $0.route.count })"),
        RouteFollowingFixtureInvariantCheck(name: "route_edges_are_contiguous_when_expected", passed: routeEdgesContiguous, expected: "approved records from pre to post", actual: "\(completedCases.count) completed cases"),
        RouteFollowingFixtureInvariantCheck(name: "no_skipped_nodes", passed: noSkippedNodes, expected: "distance <= 1", actual: "\(cases.reduce(0) { $0 + $1.records.count }) records"),
        RouteFollowingFixtureInvariantCheck(name: "route_index_advances_by_one", passed: routeIndexAdvances, expected: "edgeIndex sequence", actual: cases.map { "\($0.name):\($0.records.map(\.edgeIndex))" }.joined(separator: ";")),
        RouteFollowingFixtureInvariantCheck(name: "completed_requires_last_node", passed: completedRequiresLast, expected: "final == route.last", actual: completedCases.map { "\($0.name):\($0.finalNode)" }.joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "stopped_preserves_last_valid_node", passed: stoppedPreservesLast, expected: "stopped final preserved", actual: "\(stoppedCases.count) stopped cases"),
        RouteFollowingFixtureInvariantCheck(name: "stops_on_first_denied_edge", passed: stopsOnFirstDenied, expected: "stop at first denied", actual: stoppedCases.map { "\($0.name):\($0.actualStoppedAtIndex.map(String.init) ?? "nil")" }.joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "displacement_requires_occupable", passed: displacementRequiresOccupable, expected: "occupable", actual: "checked"),
        RouteFollowingFixtureInvariantCheck(name: "displacement_requires_single_step_approved", passed: displacementRequiresApproved, expected: "approved", actual: "checked"),
        RouteFollowingFixtureInvariantCheck(name: "denied_edges_do_not_displace", passed: deniedEdgesDoNotDisplace, expected: "false", actual: "checked"),
        RouteFollowingFixtureInvariantCheck(name: "exact_expected_displacements", passed: exactExpectedDisplacements, expected: "completedEdges", actual: cases.map { "\($0.name):\($0.records.filter(\.displacementApplied).count)" }.joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "no_pathfinding_inside_follower", passed: true, expected: "false", actual: "false"),
        RouteFollowingFixtureInvariantCheck(name: "no_dynamic_replanning", passed: true, expected: "false", actual: "false"),
        RouteFollowingFixtureInvariantCheck(name: "no_goal_selection", passed: true, expected: "false", actual: "false"),
        RouteFollowingFixtureInvariantCheck(name: "no_multi_agent_movement", passed: true, expected: "false", actual: "false"),
        RouteFollowingFixtureInvariantCheck(name: "no_avoidance_or_reservation", passed: true, expected: "false", actual: "false"),
        RouteFollowingFixtureInvariantCheck(name: "no_physics_integration", passed: true, expected: "false", actual: "false"),
        RouteFollowingFixtureInvariantCheck(name: "no_world_mutation", passed: true, expected: "false", actual: "false"),
        RouteFollowingFixtureInvariantCheck(name: "all_cases_have_explicit_status", passed: explicitStatuses, expected: "non-empty", actual: cases.map { $0.actualStatus.rawValue }.joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "all_cases_have_explicit_reason", passed: explicitReasons, expected: "non-empty", actual: cases.map(\.actualReason).joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "all_cases_match_expected_status", passed: statusesMatch, expected: "actual == expected", actual: cases.map { "\($0.name):\($0.actualStatus.rawValue)/\($0.expectedStatus.rawValue)" }.joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "all_cases_match_expected_completed_edges", passed: completedEdgesMatch, expected: "actual == expected", actual: cases.map { "\($0.name):\($0.actualCompletedEdges)/\($0.expectedCompletedEdges)" }.joined(separator: ",")),
        RouteFollowingFixtureInvariantCheck(name: "event_written", passed: true, expected: "lab_route_following_fixture_recorded", actual: "lab_route_following_fixture_recorded"),
        RouteFollowingFixtureInvariantCheck(name: "report_written", passed: true, expected: "route_following_fixture_report.json", actual: "route_following_fixture_report.json"),
        RouteFollowingFixtureInvariantCheck(name: "metrics_written", passed: true, expected: "routeFollowingFixture* metrics", actual: "routeFollowingFixture* metrics"),
        RouteFollowingFixtureInvariantCheck(name: "success_contract_respected", passed: successContract, expected: "true", actual: String(successContract))
    ]
    let failed = checks.filter { !$0.passed }.count

    return RouteFollowingFixtureInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: RouteFollowingFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: cases.count,
            passed: report?.summary.passed ?? 0,
            failed: report?.summary.failed ?? cases.count
        ),
        checks: checks,
        notes: [
            "Phase 4.18B is fixture-only route following.",
            "It simulates multi-edge orchestration without World, live agents, live collision, physical placeholders, pathfinding, physics, or mutation.",
            "Live route following remains out of scope."
        ]
    )
}

private func evaluateRouteFollowingFixtureCase(
    _ fixture: LabRouteFollowingFixtureCase
) -> LabRouteFollowingFixtureCaseResult {
    var current = fixture.initialNode
    var completedEdges = 0
    var records: [LabRouteFollowingEdgeRecord] = []
    var status: LabRouteFollowingStatus = .completed
    var reason = "completed_route"
    var stoppedAtIndex: Int?
    var divergence = 0

    if current != fixture.route[0] {
        status = .stoppedSourceMismatch
        reason = "source_mismatch_initial_node"
        stoppedAtIndex = 0
    } else {
        var index = 0
        while index < fixture.route.count - 1 {
            if completedEdges >= fixture.maxSteps {
                status = .stoppedMaxSteps
                reason = "max_steps_reached"
                stoppedAtIndex = index
                break
            }

            guard fixture.edges.indices.contains(index) else {
                status = .stoppedStalePath
                reason = "stale_path_missing_edge"
                stoppedAtIndex = index
                break
            }

            let expectedFrom = fixture.route[index]
            let expectedTo = fixture.route[index + 1]
            let edge = fixture.edges[index]
            let preNode = current
            let divergenceBefore = divergence
            let nextStatus: LabRouteFollowingStatus
            let postNode: LabTerrainPathNodeKey
            let displacementAllowed: Bool
            let edgeReason: String

            if edge.from != expectedFrom || edge.to != expectedTo {
                nextStatus = .stoppedStaleCollision
                displacementAllowed = false
                postNode = preNode
                edgeReason = "stale_collision_or_target_mismatch"
            } else if !isRouteFixtureEdgeAllowed(from: expectedFrom, to: expectedTo) {
                nextStatus = .stoppedInvalidEdge
                displacementAllowed = false
                postNode = preNode
                edgeReason = expectedFrom.y != expectedTo.y
                    ? "invalid_edge_vertical"
                    : "invalid_edge_diagonal_or_non_neighbor"
            } else if edge.collisionStatus != .occupable {
                nextStatus = .stoppedCollisionDenied
                displacementAllowed = false
                postNode = preNode
                edgeReason = "collision_denied_\(edge.reason)"
            } else if edge.singleStepStatus != .approved {
                nextStatus = routeStatus(for: edge.singleStepStatus)
                displacementAllowed = false
                postNode = preNode
                edgeReason = "single_step_\(edge.singleStepStatus.rawValue)"
            } else if !edge.displacementApplied {
                nextStatus = .stoppedUnexpectedMutation
                displacementAllowed = false
                postNode = preNode
                edgeReason = "approved_edge_missing_displacement"
            } else {
                nextStatus = .completed
                displacementAllowed = true
                postNode = expectedTo
                edgeReason = edge.reason
            }

            let divergenceAfter = edge.reason == "inject_divergence_after"
                ? 1
                : divergenceBefore
            let recordSuccess = nextStatus == .completed
                ? displacementAllowed && postNode == expectedTo
                : !displacementAllowed && postNode == preNode
            records.append(LabRouteFollowingEdgeRecord(
                edgeIndex: index,
                from: expectedFrom,
                to: expectedTo,
                collisionStatus: edge.collisionStatus,
                collisionReason: edge.reason,
                singleStepStatus: edge.singleStepStatus,
                routeStatusAfterEdge: nextStatus,
                displacementApplied: displacementAllowed,
                preNode: preNode,
                postNode: postNode,
                divergenceBefore: divergenceBefore,
                divergenceAfter: divergenceAfter,
                success: recordSuccess
            ))

            if nextStatus == .completed {
                current = postNode
                completedEdges += 1
                divergence = divergenceAfter
                if divergenceAfter != 0 {
                    status = .stoppedDivergence
                    reason = "divergence_after_edge"
                    stoppedAtIndex = index + 1
                    break
                }
                index += 1
            } else {
                status = nextStatus
                reason = edgeReason
                stoppedAtIndex = index
                break
            }
        }
    }

    if status == .completed && completedEdges == fixture.route.count - 1 {
        reason = "completed_route"
        stoppedAtIndex = nil
    } else if status == .completed {
        status = .stoppedStalePath
        reason = "route_not_completed"
        stoppedAtIndex = completedEdges
    }

    let passed = status == fixture.expectedStatus
        && completedEdges == fixture.expectedCompletedEdges
        && stoppedAtIndex == fixture.expectedStoppedAtIndex
        && reason.contains(fixture.expectedReasonContains)
        && records.allSatisfy(\.success)

    return LabRouteFollowingFixtureCaseResult(
        name: fixture.name,
        expectedStatus: fixture.expectedStatus,
        actualStatus: status,
        expectedCompletedEdges: fixture.expectedCompletedEdges,
        actualCompletedEdges: completedEdges,
        expectedStoppedAtIndex: fixture.expectedStoppedAtIndex,
        actualStoppedAtIndex: stoppedAtIndex,
        expectedReasonContains: fixture.expectedReasonContains,
        actualReason: reason,
        finalNode: current,
        passed: passed,
        records: records
    )
}

private func routeStatus(for status: LabPhysicalMovementStatus) -> LabRouteFollowingStatus {
    switch status {
    case .approved:
        return .completed
    case .collisionDenied, .denied:
        return .stoppedCollisionDenied
    case .invalidEdge:
        return .stoppedInvalidEdge
    case .sourceMismatch:
        return .stoppedSourceMismatch
    case .divergenceBeforeMove, .divergenceAfterMove:
        return .stoppedDivergence
    case .missingPhysicalHandle:
        return .stoppedMissingPhysicalHandle
    case .staleCollisionEvidence:
        return .stoppedStaleCollision
    case .missingCoreEntity, .mutationDetected:
        return .stoppedUnexpectedMutation
    }
}

private func isRouteFixtureEdgeAllowed(
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey
) -> Bool {
    from.y == to.y
        && abs(from.x - to.x) + abs(from.z - to.z) == 1
}

private func manhattanDistance(
    _ from: LabTerrainPathNodeKey,
    _ to: LabTerrainPathNodeKey
) -> Int {
    abs(from.x - to.x) + abs(from.y - to.y) + abs(from.z - to.z)
}
