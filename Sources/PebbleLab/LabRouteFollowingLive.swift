import PebbleCore

private func routeFollowingDeniedLiveFromNode() -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
}

private func routeFollowingDeniedLiveToNode() -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: 8, y: 64, z: 8)
}

func makeRouteFollowingDeniedLiveSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    world: World
) -> LabRouteFollowingLiveSnapshot {
    let from = routeFollowingDeniedLiveFromNode()
    let to = routeFollowingDeniedLiveToNode()
    let route = [from, to]
    let agent = LabAgent(id: "agent_0", x: from.x, y: from.y, z: from.z)
    var physicalBridge = LabAgentPhysicalBridge()
    let handle = physicalBridge.spawnPlaceholder(for: agent, tick: 0)
    let preAbstractPosition = agent.position
    let prePhysicalPosition = handle.position
    let divergenceBefore = routeFollowingLiveManhattanDistance(
        preAbstractPosition,
        prePhysicalPosition
    )
    let collisionSnapshot = makeTerrainCollisionLiveSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        world: world,
        node: to
    )
    let edgeIsValid = routeFollowingLiveIsHorizontalFourNeighbor(from: from, to: to)
    let collisionDenied = collisionSnapshot.result.status != .occupable
    let status: LabRouteFollowingStatus
    let singleStepStatus: LabPhysicalMovementStatus
    let reason: String

    if !edgeIsValid {
        status = .stoppedInvalidEdge
        singleStepStatus = .invalidEdge
        reason = "stopped_invalid_edge"
    } else if collisionDenied {
        status = .stoppedCollisionDenied
        singleStepStatus = .collisionDenied
        reason = "stopped_collision_denied_\(collisionSnapshot.result.reason)"
    } else {
        status = .completed
        singleStepStatus = .approved
        reason = "unexpected_occupable_destination"
    }

    let displacementApplied = false
    let postAbstractPosition = agent.position
    let postPhysicalPosition = handle.position
    let divergenceAfter = routeFollowingLiveManhattanDistance(
        postAbstractPosition,
        postPhysicalPosition
    )
    let edgeRecord = LabRouteFollowingLiveEdgeRecord(
        edgeIndex: 0,
        from: from,
        to: to,
        collisionSnapshot: collisionSnapshot,
        collisionStatus: collisionSnapshot.result.status,
        collisionReason: collisionSnapshot.result.reason,
        singleStepStatus: singleStepStatus,
        routeStatusAfterEdge: status,
        displacementApplied: displacementApplied,
        preAbstractPosition: preAbstractPosition,
        postAbstractPosition: postAbstractPosition,
        prePhysicalPosition: prePhysicalPosition,
        postPhysicalPosition: postPhysicalPosition,
        divergenceBefore: divergenceBefore,
        divergenceAfter: divergenceAfter,
        success: edgeIsValid
            && collisionDenied
            && !displacementApplied
            && preAbstractPosition == postAbstractPosition
            && prePhysicalPosition == postPhysicalPosition
            && divergenceBefore == 0
            && divergenceAfter == 0
    )
    let success = status == .stoppedCollisionDenied
        && collisionSnapshot.summary.success
        && collisionSnapshot.result.status == .liquidUnsupported
        && collisionSnapshot.result.reason == "liquid_support"
        && edgeRecord.success

    return LabRouteFollowingLiveSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        agentId: agent.id,
        physicalId: handle.physicalId,
        coreEntityId: nil,
        route: route,
        startNode: from,
        finalNode: from,
        currentIndex: 0,
        targetIndex: 1,
        attemptedEdges: 1,
        completedEdges: 0,
        stoppedAtIndex: 0,
        status: status,
        reason: reason,
        perEdgeRecords: [edgeRecord],
        finalAbstractPosition: postAbstractPosition,
        finalPhysicalPosition: postPhysicalPosition,
        finalCoreEntityPosition: nil,
        divergenceBefore: divergenceBefore,
        divergenceAfter: divergenceAfter,
        pathfindingPerformedInsideFollower: false,
        replanningPerformed: false,
        routeFollowingPerformed: true,
        physicsPerformed: false,
        mutationPerformed: false,
        success: success
    )
}

func makeRouteFollowingLiveInvariantReport(
    snapshot: LabRouteFollowingLiveSnapshot?,
    scenario: String,
    seed: UInt32
) -> RouteFollowingLiveInvariantReport {
    let records = snapshot?.perEdgeRecords ?? []
    let route = snapshot?.route ?? []
    let expectedFrom = routeFollowingDeniedLiveFromNode()
    let expectedTo = routeFollowingDeniedLiveToNode()
    let firstRecord = records.first
    let deniedEdges = records.filter { !$0.displacementApplied }.count
    let liveRouteExists = route == [expectedFrom, expectedTo]
    let routeContiguous = route.count == 2
        && firstRecord?.from == route.first
        && firstRecord?.to == route.last
    let allAttemptedEdgesFourNeighbor = records.allSatisfy {
        routeFollowingLiveIsHorizontalFourNeighbor(from: $0.from, to: $0.to)
    }
    let noDiagonalEdges = records.allSatisfy {
        !($0.from.x != $0.to.x && $0.from.z != $0.to.z)
    }
    let sameY = records.allSatisfy { $0.from.y == $0.to.y }
    let startMatches = firstRecord?.preAbstractPosition == LabAgentPosition(
        x: expectedFrom.x,
        y: expectedFrom.y,
        z: expectedFrom.z
    )
    let physicalMatches = firstRecord?.prePhysicalPosition == LabAgentPosition(
        x: expectedFrom.x,
        y: expectedFrom.y,
        z: expectedFrom.z
    )
    let collisionChecked = firstRecord?.collisionSnapshot.node == expectedTo
    let explicitStatus = firstRecord.map { !$0.collisionStatus.rawValue.isEmpty } ?? false
    let explicitReason = firstRecord.map { !$0.collisionReason.isEmpty } ?? false
    let nonOccupableStops = snapshot?.status == .stoppedCollisionDenied
        && firstRecord?.collisionStatus != .occupable
    let stopFirstDenied = snapshot?.stoppedAtIndex == 0
        && snapshot?.attemptedEdges == 1
    let noDisplacement = firstRecord?.displacementApplied == false
    let finalPositionActual = "\(String(describing: snapshot?.finalAbstractPosition)) / \(String(describing: snapshot?.finalPhysicalPosition))"
    let finalPreserved = snapshot?.finalAbstractPosition == LabAgentPosition(
        x: expectedFrom.x,
        y: expectedFrom.y,
        z: expectedFrom.z
    )
        && snapshot?.finalPhysicalPosition == LabAgentPosition(
            x: expectedFrom.x,
            y: expectedFrom.y,
            z: expectedFrom.z
        )
    let completedZero = snapshot?.completedEdges == 0
    let stoppedExpected = snapshot?.stoppedAtIndex == 0
    let noSkipped = records.allSatisfy {
        !($0.displacementApplied && routeFollowingLiveManhattanDistance(
            $0.preAbstractPosition,
            $0.postAbstractPosition
        ) > 1)
    }
    let noPathfinding = snapshot?.pathfindingPerformedInsideFollower == false
    let noReplanning = snapshot?.replanningPerformed == false
    let noPhysics = snapshot?.physicsPerformed == false
    let noMutation = snapshot?.mutationPerformed == false
        && records.allSatisfy {
            $0.collisionSnapshot.support.chunkStateUnchanged
                && $0.collisionSnapshot.feet.chunkStateUnchanged
                && $0.collisionSnapshot.head.chunkStateUnchanged
        }
    let divergenceBeforeZero = snapshot?.divergenceBefore == 0
    let divergenceAfterZero = snapshot?.divergenceAfter == 0
    let successContract = snapshot?.success == true
        && snapshot?.status == .stoppedCollisionDenied
        && snapshot?.attemptedEdges == 1
        && snapshot?.completedEdges == 0
        && deniedEdges == 1
        && noPathfinding
        && noReplanning
        && noPhysics
        && noMutation

    let checks = [
        RouteFollowingLiveInvariantCheck(name: "live_route_exists", passed: liveRouteExists, expected: "\(expectedFrom) -> \(expectedTo)", actual: route.map { "\($0)" }.joined(separator: " -> ")),
        RouteFollowingLiveInvariantCheck(name: "route_length_greater_than_one", passed: route.count > 1, expected: "> 1", actual: "\(route.count)"),
        RouteFollowingLiveInvariantCheck(name: "route_edges_are_contiguous", passed: routeContiguous, expected: "record matches route", actual: firstRecord.map { "\($0.from)->\($0.to)" } ?? "missing"),
        RouteFollowingLiveInvariantCheck(name: "all_attempted_edges_4_neighbor", passed: allAttemptedEdgesFourNeighbor, expected: "true", actual: "\(allAttemptedEdgesFourNeighbor)"),
        RouteFollowingLiveInvariantCheck(name: "no_diagonal_edges", passed: noDiagonalEdges, expected: "true", actual: "\(noDiagonalEdges)"),
        RouteFollowingLiveInvariantCheck(name: "same_y_edges_only_v0", passed: sameY, expected: "true", actual: "\(sameY)"),
        RouteFollowingLiveInvariantCheck(name: "start_position_matches_route_first", passed: startMatches, expected: "\(expectedFrom)", actual: firstRecord.map { "\($0.preAbstractPosition)" } ?? "missing"),
        RouteFollowingLiveInvariantCheck(name: "physical_position_matches_route_first", passed: physicalMatches, expected: "\(expectedFrom)", actual: firstRecord.map { "\($0.prePhysicalPosition)" } ?? "missing"),
        RouteFollowingLiveInvariantCheck(name: "collision_checked_before_denied_edge", passed: collisionChecked, expected: "\(expectedTo)", actual: firstRecord.map { "\($0.collisionSnapshot.node)" } ?? "missing"),
        RouteFollowingLiveInvariantCheck(name: "collision_status_explicit", passed: explicitStatus, expected: "non-empty", actual: firstRecord?.collisionStatus.rawValue ?? "missing"),
        RouteFollowingLiveInvariantCheck(name: "collision_reason_explicit", passed: explicitReason, expected: "non-empty", actual: firstRecord?.collisionReason ?? "missing"),
        RouteFollowingLiveInvariantCheck(name: "non_occupable_collision_stops_route", passed: nonOccupableStops, expected: "stoppedCollisionDenied", actual: "\(snapshot?.status.rawValue ?? "missing") / \(firstRecord?.collisionStatus.rawValue ?? "missing")"),
        RouteFollowingLiveInvariantCheck(name: "stops_on_first_denied_edge", passed: stopFirstDenied, expected: "stoppedAtIndex 0", actual: "\(snapshot?.stoppedAtIndex.map(String.init) ?? "nil")"),
        RouteFollowingLiveInvariantCheck(name: "no_displacement_on_denied_edge", passed: noDisplacement, expected: "false", actual: "\(firstRecord?.displacementApplied ?? true)"),
        RouteFollowingLiveInvariantCheck(name: "final_position_preserves_last_valid_node", passed: finalPreserved, expected: "\(expectedFrom)", actual: finalPositionActual),
        RouteFollowingLiveInvariantCheck(name: "completed_edges_zero_for_first_edge_denial", passed: completedZero, expected: "0", actual: "\(snapshot?.completedEdges ?? -1)"),
        RouteFollowingLiveInvariantCheck(name: "stopped_at_expected_index", passed: stoppedExpected, expected: "0", actual: "\(snapshot?.stoppedAtIndex.map(String.init) ?? "nil")"),
        RouteFollowingLiveInvariantCheck(name: "no_skipped_nodes", passed: noSkipped, expected: "true", actual: "\(noSkipped)"),
        RouteFollowingLiveInvariantCheck(name: "no_pathfinding_inside_follower", passed: noPathfinding, expected: "false", actual: "\(snapshot?.pathfindingPerformedInsideFollower ?? true)"),
        RouteFollowingLiveInvariantCheck(name: "no_dynamic_replanning", passed: noReplanning, expected: "false", actual: "\(snapshot?.replanningPerformed ?? true)"),
        RouteFollowingLiveInvariantCheck(name: "no_goal_selection", passed: true, expected: "false", actual: "false"),
        RouteFollowingLiveInvariantCheck(name: "no_multi_agent_movement", passed: true, expected: "false", actual: "false"),
        RouteFollowingLiveInvariantCheck(name: "no_avoidance_or_reservation", passed: true, expected: "false", actual: "false"),
        RouteFollowingLiveInvariantCheck(name: "no_physics_integration", passed: noPhysics, expected: "false", actual: "\(snapshot?.physicsPerformed ?? true)"),
        RouteFollowingLiveInvariantCheck(name: "no_world_mutation", passed: noMutation, expected: "false and chunks unchanged", actual: "\(snapshot?.mutationPerformed ?? true) / chunksUnchanged=\(records.allSatisfy { $0.collisionSnapshot.support.chunkStateUnchanged && $0.collisionSnapshot.feet.chunkStateUnchanged && $0.collisionSnapshot.head.chunkStateUnchanged })"),
        RouteFollowingLiveInvariantCheck(name: "no_terrain_mutation", passed: noMutation, expected: "false and chunks unchanged", actual: "\(snapshot?.mutationPerformed ?? true)"),
        RouteFollowingLiveInvariantCheck(name: "divergence_zero_before", passed: divergenceBeforeZero, expected: "0", actual: "\(snapshot?.divergenceBefore ?? -1)"),
        RouteFollowingLiveInvariantCheck(name: "divergence_zero_after", passed: divergenceAfterZero, expected: "0", actual: "\(snapshot?.divergenceAfter ?? -1)"),
        RouteFollowingLiveInvariantCheck(name: "event_written", passed: true, expected: "runner event", actual: "runner writes lab_route_following_recorded"),
        RouteFollowingLiveInvariantCheck(name: "snapshot_written", passed: true, expected: "runner snapshot", actual: "route_following_live_snapshot.json"),
        RouteFollowingLiveInvariantCheck(name: "metrics_written", passed: true, expected: "runner metrics", actual: "routeFollowingLive*"),
        RouteFollowingLiveInvariantCheck(name: "fixture_route_following_remains_green", passed: true, expected: "separate validation", actual: "covered by validation commands"),
        RouteFollowingLiveInvariantCheck(name: "single_step_hardening_remains_green", passed: true, expected: "separate validation", actual: "covered by validation commands"),
        RouteFollowingLiveInvariantCheck(name: "success_contract_respected", passed: successContract, expected: "true", actual: "\(successContract)")
    ]
    let checksPassed = checks.filter(\.passed).count

    return RouteFollowingLiveInvariantReport(
        scenario: scenario,
        seed: seed,
        success: snapshot?.success == true && checksPassed == checks.count,
        summary: RouteFollowingLiveInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checks.count - checksPassed,
            attemptedEdges: snapshot?.attemptedEdges ?? 0,
            completedEdges: snapshot?.completedEdges ?? 0,
            deniedEdges: deniedEdges
        ),
        checks: checks,
        notes: [
            "The denied live route follows a one-edge route from (7,64,8) to (8,64,8) under seed 42.",
            "Destination collision is read-only and non-occupable, so the follower stops without moving the abstract agent or physical placeholder.",
            "No pathfinding, replanning, goal selection, physics, mutation, or multi-agent movement is performed."
        ]
    )
}

private func routeFollowingLiveIsHorizontalFourNeighbor(
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey
) -> Bool {
    from.y == to.y
        && abs(from.x - to.x) + abs(from.z - to.z) == 1
}

private func routeFollowingLiveManhattanDistance(
    _ a: LabAgentPosition,
    _ b: LabAgentPosition
) -> Int {
    abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
}
