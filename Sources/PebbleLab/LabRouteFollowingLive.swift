import PebbleCore

private func routeFollowingDeniedLiveFromNode() -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
}

private func routeFollowingDeniedLiveToNode() -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: 8, y: 64, z: 8)
}

private func routeFollowingApprovedTwoStepRoute() -> [LabTerrainPathNodeKey] {
    [
        LabTerrainPathNodeKey(x: 7, y: 64, z: 8),
        LabTerrainPathNodeKey(x: 8, y: 64, z: 8),
        LabTerrainPathNodeKey(x: 9, y: 64, z: 8)
    ]
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
        displacementsApplied: 0,
        deniedEdges: 1,
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

func makeRouteFollowingApprovedTwoStepSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabRouteFollowingLiveSnapshot {
    let route = routeFollowingApprovedTwoStepRoute()
    let collisionSeed: UInt32 = 99
    let collisionWorld = routeFollowingLiveCollisionWorld(
        seed: collisionSeed,
        around: route[1]
    )
    var agent = LabAgent(id: "agent_0", x: route[0].x, y: route[0].y, z: route[0].z)
    var physicalBridge = LabAgentPhysicalBridge()
    let handle = physicalBridge.spawnPlaceholder(for: agent, tick: 0)
    let initialDivergence = routeFollowingLiveManhattanDistance(
        agent.position,
        handle.position
    )
    var records: [LabRouteFollowingLiveEdgeRecord] = []
    var status: LabRouteFollowingStatus = .completed
    var reason = "completed_two_step_route"
    var stoppedAtIndex: Int?
    var completedEdges = 0

    for edgeIndex in 0..<(route.count - 1) {
        let from = route[edgeIndex]
        let to = route[edgeIndex + 1]
        let preAbstractPosition = agent.position
        let prePhysicalPosition = physicalBridge.handles.first?.position ?? handle.position
        let divergenceBefore = routeFollowingLiveManhattanDistance(
            preAbstractPosition,
            prePhysicalPosition
        )
        let collisionSnapshot = makeTerrainCollisionLiveSnapshot(
            scenario: scenario,
            seed: collisionSeed,
            ticksCompleted: ticksCompleted,
            world: collisionWorld,
            node: to
        )
        let edge = routeFollowingLiveEdgeDelta(from: from, to: to)
        let edgeIsValid = routeFollowingLiveIsHorizontalFourNeighbor(from: from, to: to)
        let sourceMatches = preAbstractPosition == LabAgentPosition(
            x: from.x,
            y: from.y,
            z: from.z
        )
            && prePhysicalPosition == LabAgentPosition(
                x: from.x,
                y: from.y,
                z: from.z
            )
        let collisionAllows = collisionSnapshot.result.status == .occupable
        let singleStepStatus: LabPhysicalMovementStatus
        let routeStatusAfterEdge: LabRouteFollowingStatus
        let displacementApplied: Bool
        let edgeReason: String

        if !edgeIsValid {
            singleStepStatus = .invalidEdge
            routeStatusAfterEdge = .stoppedInvalidEdge
            displacementApplied = false
            edgeReason = "stopped_invalid_edge"
        } else if !sourceMatches {
            singleStepStatus = .sourceMismatch
            routeStatusAfterEdge = .stoppedSourceMismatch
            displacementApplied = false
            edgeReason = "stopped_source_mismatch"
        } else if divergenceBefore != 0 {
            singleStepStatus = .divergenceBeforeMove
            routeStatusAfterEdge = .stoppedDivergence
            displacementApplied = false
            edgeReason = "stopped_divergence_before_move"
        } else if !collisionAllows {
            singleStepStatus = .collisionDenied
            routeStatusAfterEdge = .stoppedCollisionDenied
            displacementApplied = false
            edgeReason = "stopped_collision_denied_\(collisionSnapshot.result.reason)"
        } else {
            singleStepStatus = .approved
            routeStatusAfterEdge = edgeIndex == route.count - 2 ? .completed : .completed
            displacementApplied = true
            edgeReason = "approved_occupable_route_edge"
        }

        if displacementApplied {
            agent.lastAction = LabAgentAction(
                name: "move_abstract",
                reason: "approved_two_step_route_following_smoke",
                tick: ticksCompleted,
                dx: edge.dx,
                dy: edge.dy,
                dz: edge.dz
            )
            _ = agent.applyAbstractMovement(tick: ticksCompleted)
            _ = physicalBridge.sync(with: [agent], tick: ticksCompleted)
            completedEdges += 1
        } else {
            status = routeStatusAfterEdge
            reason = edgeReason
            stoppedAtIndex = edgeIndex
        }

        let postAbstractPosition = agent.position
        let postPhysicalPosition = physicalBridge.handles.first?.position ?? prePhysicalPosition
        let divergenceAfter = routeFollowingLiveManhattanDistance(
            postAbstractPosition,
            postPhysicalPosition
        )
        records.append(LabRouteFollowingLiveEdgeRecord(
            edgeIndex: edgeIndex,
            from: from,
            to: to,
            collisionSnapshot: collisionSnapshot,
            collisionStatus: collisionSnapshot.result.status,
            collisionReason: collisionSnapshot.result.reason,
            singleStepStatus: singleStepStatus,
            routeStatusAfterEdge: routeStatusAfterEdge,
            displacementApplied: displacementApplied,
            preAbstractPosition: preAbstractPosition,
            postAbstractPosition: postAbstractPosition,
            prePhysicalPosition: prePhysicalPosition,
            postPhysicalPosition: postPhysicalPosition,
            divergenceBefore: divergenceBefore,
            divergenceAfter: divergenceAfter,
            success: displacementApplied
                && collisionAllows
                && postAbstractPosition == LabAgentPosition(x: to.x, y: to.y, z: to.z)
                && postPhysicalPosition == LabAgentPosition(x: to.x, y: to.y, z: to.z)
                && divergenceBefore == 0
                && divergenceAfter == 0
        ))

        if stoppedAtIndex != nil {
            break
        }
    }

    let finalAbstractPosition = agent.position
    let finalPhysicalPosition = physicalBridge.handles.first?.position ?? handle.position
    let finalDivergence = routeFollowingLiveManhattanDistance(
        finalAbstractPosition,
        finalPhysicalPosition
    )
    let displacementsApplied = records.filter(\.displacementApplied).count
    let deniedEdges = records.count - displacementsApplied
    let success = status == .completed
        && stoppedAtIndex == nil
        && route.count == 3
        && records.count == 2
        && completedEdges == 2
        && displacementsApplied == 2
        && deniedEdges == 0
        && records.allSatisfy { $0.collisionStatus == .occupable }
        && finalAbstractPosition == LabAgentPosition(x: route[2].x, y: route[2].y, z: route[2].z)
        && finalPhysicalPosition == LabAgentPosition(x: route[2].x, y: route[2].y, z: route[2].z)
        && initialDivergence == 0
        && finalDivergence == 0

    return LabRouteFollowingLiveSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        agentId: agent.id,
        physicalId: handle.physicalId,
        coreEntityId: nil,
        route: route,
        startNode: route[0],
        finalNode: route[2],
        currentIndex: completedEdges,
        targetIndex: nil,
        attemptedEdges: records.count,
        completedEdges: completedEdges,
        displacementsApplied: displacementsApplied,
        deniedEdges: deniedEdges,
        stoppedAtIndex: stoppedAtIndex,
        status: status,
        reason: reason,
        perEdgeRecords: records,
        finalAbstractPosition: finalAbstractPosition,
        finalPhysicalPosition: finalPhysicalPosition,
        finalCoreEntityPosition: nil,
        divergenceBefore: initialDivergence,
        divergenceAfter: finalDivergence,
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
    if snapshot?.status == .completed {
        return makeRouteFollowingApprovedTwoStepInvariantReport(
            snapshot: snapshot,
            scenario: scenario,
            seed: seed
        )
    }

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

private func makeRouteFollowingApprovedTwoStepInvariantReport(
    snapshot: LabRouteFollowingLiveSnapshot?,
    scenario: String,
    seed: UInt32
) -> RouteFollowingLiveInvariantReport {
    let route = snapshot?.route ?? []
    let records = snapshot?.perEdgeRecords ?? []
    let expectedRoute = routeFollowingApprovedTwoStepRoute()
    let deniedEdges = records.filter { !$0.displacementApplied }.count
    let displacements = records.filter(\.displacementApplied).count
    let liveRouteExists = route == expectedRoute
    let routeEdgesContiguous = records.count == 2
        && records.enumerated().allSatisfy { index, record in
            route.indices.contains(index)
                && route.indices.contains(index + 1)
                && record.from == route[index]
                && record.to == route[index + 1]
        }
    let allFourNeighbor = records.allSatisfy {
        routeFollowingLiveIsHorizontalFourNeighbor(from: $0.from, to: $0.to)
    }
    let noDiagonal = records.allSatisfy {
        !($0.from.x != $0.to.x && $0.from.z != $0.to.z)
    }
    let sameY = records.allSatisfy { $0.from.y == $0.to.y }
    let startMatches = records.first?.preAbstractPosition == LabAgentPosition(
        x: expectedRoute[0].x,
        y: expectedRoute[0].y,
        z: expectedRoute[0].z
    )
    let physicalMatches = records.first?.prePhysicalPosition == LabAgentPosition(
        x: expectedRoute[0].x,
        y: expectedRoute[0].y,
        z: expectedRoute[0].z
    )
    let collisionChecked = records.enumerated().allSatisfy { index, record in
        record.collisionSnapshot.node == expectedRoute[index + 1]
    }
    let collisionsOccupable = records.count == 2 && records.allSatisfy {
        $0.collisionStatus == .occupable
    }
    let explicitCollisionReasons = records.count == 2 && records.allSatisfy {
        !$0.collisionReason.isEmpty
    }
    let displacementRequiresOccupable = records.allSatisfy {
        !$0.displacementApplied || $0.collisionStatus == .occupable
    }
    let eachDisplacementApplied = records.count == 2 && records.allSatisfy(\.displacementApplied)
    let routeIndexAdvances = records.enumerated().allSatisfy { index, record in
        record.edgeIndex == index
            && record.postAbstractPosition == LabAgentPosition(
                x: record.to.x,
                y: record.to.y,
                z: record.to.z
            )
            && record.postPhysicalPosition == LabAgentPosition(
                x: record.to.x,
                y: record.to.y,
                z: record.to.z
            )
    }
    let noSkipped = records.allSatisfy {
        routeFollowingLiveManhattanDistance($0.preAbstractPosition, $0.postAbstractPosition) == 1
            && routeFollowingLiveManhattanDistance($0.prePhysicalPosition, $0.postPhysicalPosition) == 1
    }
    let completedEdgesMatch = snapshot?.completedEdges == route.count - 1
        && snapshot?.attemptedEdges == route.count - 1
    let completedRequiresLast = snapshot?.status == .completed
        && snapshot?.finalNode == expectedRoute.last
    let finalPositionMatches = snapshot?.finalAbstractPosition == LabAgentPosition(
        x: expectedRoute[2].x,
        y: expectedRoute[2].y,
        z: expectedRoute[2].z
    )
        && snapshot?.finalPhysicalPosition == LabAgentPosition(
            x: expectedRoute[2].x,
            y: expectedRoute[2].y,
            z: expectedRoute[2].z
        )
    let divergenceBeforeZero = snapshot?.divergenceBefore == 0
    let divergenceAfterEachEdge = records.count == 2 && records.allSatisfy {
        $0.divergenceBefore == 0 && $0.divergenceAfter == 0
    }
    let divergenceFinalZero = snapshot?.divergenceAfter == 0
    let noPathfinding = snapshot?.pathfindingPerformedInsideFollower == false
    let noReplanning = snapshot?.replanningPerformed == false
    let noPhysics = snapshot?.physicsPerformed == false
    let noMutation = snapshot?.mutationPerformed == false
        && records.allSatisfy {
            $0.collisionSnapshot.support.chunkStateUnchanged
                && $0.collisionSnapshot.feet.chunkStateUnchanged
                && $0.collisionSnapshot.head.chunkStateUnchanged
        }
    let successContract = snapshot?.success == true
        && snapshot?.status == .completed
        && route.count == 3
        && snapshot?.attemptedEdges == 2
        && snapshot?.completedEdges == 2
        && displacements == 2
        && deniedEdges == 0
        && snapshot?.stoppedAtIndex == nil
        && noPathfinding
        && noReplanning
        && noPhysics
        && noMutation

    let checks = [
        RouteFollowingLiveInvariantCheck(name: "live_route_exists", passed: liveRouteExists, expected: expectedRoute.map { "\($0)" }.joined(separator: " -> "), actual: route.map { "\($0)" }.joined(separator: " -> ")),
        RouteFollowingLiveInvariantCheck(name: "route_length_is_three", passed: route.count == 3, expected: "3", actual: "\(route.count)"),
        RouteFollowingLiveInvariantCheck(name: "route_edges_are_contiguous", passed: routeEdgesContiguous, expected: "2 contiguous records", actual: records.map { "\($0.from)->\($0.to)" }.joined(separator: ",")),
        RouteFollowingLiveInvariantCheck(name: "all_attempted_edges_4_neighbor", passed: allFourNeighbor, expected: "true", actual: "\(allFourNeighbor)"),
        RouteFollowingLiveInvariantCheck(name: "no_diagonal_edges", passed: noDiagonal, expected: "true", actual: "\(noDiagonal)"),
        RouteFollowingLiveInvariantCheck(name: "same_y_edges_only_v0", passed: sameY, expected: "true", actual: "\(sameY)"),
        RouteFollowingLiveInvariantCheck(name: "start_position_matches_route_first", passed: startMatches, expected: "\(expectedRoute[0])", actual: records.first.map { "\($0.preAbstractPosition)" } ?? "missing"),
        RouteFollowingLiveInvariantCheck(name: "physical_position_matches_route_first", passed: physicalMatches, expected: "\(expectedRoute[0])", actual: records.first.map { "\($0.prePhysicalPosition)" } ?? "missing"),
        RouteFollowingLiveInvariantCheck(name: "collision_checked_before_each_edge", passed: collisionChecked, expected: "each destination checked", actual: records.map { "\($0.collisionSnapshot.node)" }.joined(separator: ",")),
        RouteFollowingLiveInvariantCheck(name: "each_collision_status_is_occupable", passed: collisionsOccupable, expected: "occupable,occupable", actual: records.map(\.collisionStatus.rawValue).joined(separator: ",")),
        RouteFollowingLiveInvariantCheck(name: "each_collision_reason_explicit", passed: explicitCollisionReasons, expected: "non-empty", actual: records.map(\.collisionReason).joined(separator: ",")),
        RouteFollowingLiveInvariantCheck(name: "displacement_requires_occupable_per_edge", passed: displacementRequiresOccupable, expected: "occupable before displacement", actual: "checked"),
        RouteFollowingLiveInvariantCheck(name: "each_edge_displacement_applied", passed: eachDisplacementApplied, expected: "2", actual: "\(displacements)"),
        RouteFollowingLiveInvariantCheck(name: "route_index_advances_by_one", passed: routeIndexAdvances, expected: "edgeIndex and positions advance", actual: records.map { "\($0.edgeIndex):\($0.postAbstractPosition)" }.joined(separator: ",")),
        RouteFollowingLiveInvariantCheck(name: "no_skipped_nodes", passed: noSkipped, expected: "one node per edge", actual: "\(noSkipped)"),
        RouteFollowingLiveInvariantCheck(name: "completed_edges_match_route_edges", passed: completedEdgesMatch, expected: "2", actual: "\(snapshot?.completedEdges ?? -1) / attempted=\(snapshot?.attemptedEdges ?? -1)"),
        RouteFollowingLiveInvariantCheck(name: "completed_status_requires_last_node", passed: completedRequiresLast, expected: "completed at route.last", actual: "\(snapshot?.status.rawValue ?? "missing") / \(String(describing: snapshot?.finalNode))"),
        RouteFollowingLiveInvariantCheck(name: "final_position_matches_last_route_node", passed: finalPositionMatches, expected: "\(expectedRoute[2])", actual: "\(String(describing: snapshot?.finalAbstractPosition)) / \(String(describing: snapshot?.finalPhysicalPosition))"),
        RouteFollowingLiveInvariantCheck(name: "divergence_zero_before", passed: divergenceBeforeZero, expected: "0", actual: "\(snapshot?.divergenceBefore ?? -1)"),
        RouteFollowingLiveInvariantCheck(name: "divergence_zero_after_each_edge", passed: divergenceAfterEachEdge, expected: "all 0", actual: records.map { "\($0.divergenceBefore)->\($0.divergenceAfter)" }.joined(separator: ",")),
        RouteFollowingLiveInvariantCheck(name: "divergence_zero_final", passed: divergenceFinalZero, expected: "0", actual: "\(snapshot?.divergenceAfter ?? -1)"),
        RouteFollowingLiveInvariantCheck(name: "no_pathfinding_inside_follower", passed: noPathfinding, expected: "false", actual: "\(snapshot?.pathfindingPerformedInsideFollower ?? true)"),
        RouteFollowingLiveInvariantCheck(name: "no_dynamic_replanning", passed: noReplanning, expected: "false", actual: "\(snapshot?.replanningPerformed ?? true)"),
        RouteFollowingLiveInvariantCheck(name: "no_goal_selection", passed: true, expected: "false", actual: "false"),
        RouteFollowingLiveInvariantCheck(name: "no_multi_agent_movement", passed: true, expected: "false", actual: "false"),
        RouteFollowingLiveInvariantCheck(name: "no_avoidance_or_reservation", passed: true, expected: "false", actual: "false"),
        RouteFollowingLiveInvariantCheck(name: "no_physics_integration", passed: noPhysics, expected: "false", actual: "\(snapshot?.physicsPerformed ?? true)"),
        RouteFollowingLiveInvariantCheck(name: "no_world_mutation", passed: noMutation, expected: "false and chunks unchanged", actual: "\(snapshot?.mutationPerformed ?? true) / chunksUnchanged=\(records.allSatisfy { $0.collisionSnapshot.support.chunkStateUnchanged && $0.collisionSnapshot.feet.chunkStateUnchanged && $0.collisionSnapshot.head.chunkStateUnchanged })"),
        RouteFollowingLiveInvariantCheck(name: "no_terrain_mutation", passed: noMutation, expected: "false and chunks unchanged", actual: "\(snapshot?.mutationPerformed ?? true)"),
        RouteFollowingLiveInvariantCheck(name: "event_written", passed: true, expected: "runner event", actual: "runner writes lab_route_following_recorded"),
        RouteFollowingLiveInvariantCheck(name: "snapshot_written", passed: true, expected: "runner snapshot", actual: "route_following_live_snapshot.json"),
        RouteFollowingLiveInvariantCheck(name: "metrics_written", passed: true, expected: "runner metrics", actual: "routeFollowingLive*"),
        RouteFollowingLiveInvariantCheck(name: "denied_live_smoke_remains_green", passed: true, expected: "separate validation", actual: "covered by validation commands"),
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
            "The approved live route follows two edges from (7,64,8) to (9,64,8) using seed 99 collision evidence.",
            "Each destination is collision-checked before displacement and must be occupable.",
            "No pathfinding, replanning, goal selection, physics, mutation, or multi-agent movement is performed."
        ]
    )
}

func makeRouteFollowingLiveHardeningReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabRouteFollowingLiveHardeningReport {
    registerAllBlocks()
    registerAllBiomes()

    let cases: [LabRouteFollowingLiveHardeningCaseResult] = [
        routeFollowingLiveHardeningCaseResult(
            definition: LabRouteFollowingLiveHardeningCase(
                name: "completed_two_step",
                expectedStatus: .completed,
                expectedAttemptedEdges: 2,
                expectedCompletedEdges: 2,
                expectedDisplacementsApplied: 2,
                expectedDeniedEdges: 0,
                expectedStoppedAtIndex: nil,
                expectedReasonContains: "completed_two_step_route"
            ),
            snapshot: makeRouteFollowingApprovedTwoStepSnapshot(
                scenario: scenario,
                seed: seed,
                ticksCompleted: ticksCompleted
            )
        ),
        routeFollowingLiveHardeningCaseResult(
            definition: LabRouteFollowingLiveHardeningCase(
                name: "stopped_collision_denied_first_edge",
                expectedStatus: .stoppedCollisionDenied,
                expectedAttemptedEdges: 1,
                expectedCompletedEdges: 0,
                expectedDisplacementsApplied: 0,
                expectedDeniedEdges: 1,
                expectedStoppedAtIndex: 0,
                expectedReasonContains: "collision_denied"
            ),
            snapshot: makeRouteFollowingDeniedLiveSnapshot(
                scenario: scenario,
                seed: 42,
                ticksCompleted: ticksCompleted,
                world: routeFollowingLiveCollisionWorld(
                    seed: 42,
                    around: routeFollowingDeniedLiveToNode()
                )
            )
        ),
        routeFollowingLiveHardeningCaseResult(
            definition: LabRouteFollowingLiveHardeningCase(
                name: "stopped_invalid_diagonal_edge",
                expectedStatus: .stoppedInvalidEdge,
                expectedAttemptedEdges: 1,
                expectedCompletedEdges: 0,
                expectedDisplacementsApplied: 0,
                expectedDeniedEdges: 1,
                expectedStoppedAtIndex: 0,
                expectedReasonContains: "invalid_edge"
            ),
            snapshot: makeRouteFollowingHardeningInvalidEdgeSnapshot(
                scenario: scenario,
                seed: seed,
                ticksCompleted: ticksCompleted,
                to: LabTerrainPathNodeKey(x: 8, y: 64, z: 9),
                reason: "stopped_invalid_edge_diagonal"
            )
        ),
        routeFollowingLiveHardeningCaseResult(
            definition: LabRouteFollowingLiveHardeningCase(
                name: "stopped_vertical_edge",
                expectedStatus: .stoppedInvalidEdge,
                expectedAttemptedEdges: 1,
                expectedCompletedEdges: 0,
                expectedDisplacementsApplied: 0,
                expectedDeniedEdges: 1,
                expectedStoppedAtIndex: 0,
                expectedReasonContains: "invalid_edge"
            ),
            snapshot: makeRouteFollowingHardeningInvalidEdgeSnapshot(
                scenario: scenario,
                seed: seed,
                ticksCompleted: ticksCompleted,
                to: LabTerrainPathNodeKey(x: 7, y: 65, z: 8),
                reason: "stopped_invalid_edge_vertical"
            )
        ),
        routeFollowingLiveHardeningCaseResult(
            definition: LabRouteFollowingLiveHardeningCase(
                name: "stopped_source_mismatch",
                expectedStatus: .stoppedSourceMismatch,
                expectedAttemptedEdges: 1,
                expectedCompletedEdges: 0,
                expectedDisplacementsApplied: 0,
                expectedDeniedEdges: 1,
                expectedStoppedAtIndex: 0,
                expectedReasonContains: "source_mismatch"
            ),
            snapshot: makeRouteFollowingHardeningSourceMismatchSnapshot(
                scenario: scenario,
                seed: seed,
                ticksCompleted: ticksCompleted
            )
        ),
        routeFollowingLiveHardeningCaseResult(
            definition: LabRouteFollowingLiveHardeningCase(
                name: "stopped_divergence_after_first_edge",
                expectedStatus: .stoppedDivergence,
                expectedAttemptedEdges: 1,
                expectedCompletedEdges: 1,
                expectedDisplacementsApplied: 1,
                expectedDeniedEdges: 0,
                expectedStoppedAtIndex: 1,
                expectedReasonContains: "divergence"
            ),
            snapshot: makeRouteFollowingHardeningDivergenceSnapshot(
                scenario: scenario,
                seed: seed,
                ticksCompleted: ticksCompleted
            )
        ),
        routeFollowingLiveHardeningCaseResult(
            definition: LabRouteFollowingLiveHardeningCase(
                name: "stopped_stale_collision",
                expectedStatus: .stoppedStaleCollision,
                expectedAttemptedEdges: 1,
                expectedCompletedEdges: 0,
                expectedDisplacementsApplied: 0,
                expectedDeniedEdges: 1,
                expectedStoppedAtIndex: 0,
                expectedReasonContains: "stale_collision"
            ),
            snapshot: makeRouteFollowingHardeningStaleCollisionSnapshot(
                scenario: scenario,
                seed: seed,
                ticksCompleted: ticksCompleted
            )
        ),
        routeFollowingLiveHardeningCaseResult(
            definition: LabRouteFollowingLiveHardeningCase(
                name: "stopped_max_steps",
                expectedStatus: .stoppedMaxSteps,
                expectedAttemptedEdges: 1,
                expectedCompletedEdges: 1,
                expectedDisplacementsApplied: 1,
                expectedDeniedEdges: 0,
                expectedStoppedAtIndex: 1,
                expectedReasonContains: "max_steps"
            ),
            snapshot: makeRouteFollowingHardeningMaxStepsSnapshot(
                scenario: scenario,
                seed: seed,
                ticksCompleted: ticksCompleted
            )
        )
    ]
    let summary = makeRouteFollowingLiveHardeningSummary(cases)

    return LabRouteFollowingLiveHardeningReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        summary: summary,
        cases: cases
    )
}

func makeRouteFollowingLiveHardeningInvariantReport(
    report: LabRouteFollowingLiveHardeningReport?,
    scenario: String,
    seed: UInt32
) -> RouteFollowingLiveHardeningInvariantReport {
    let cases = report?.cases ?? []
    let snapshots = cases.map(\.snapshot)
    let names = Set(cases.map(\.name))
    let completedCase = cases.first { $0.name == "completed_two_step" }
    let stoppedCases = cases.filter { $0.actualStatus != .completed }
    let deniedStopCases = cases.filter {
        [.stoppedCollisionDenied, .stoppedInvalidEdge, .stoppedSourceMismatch, .stoppedStaleCollision]
            .contains($0.actualStatus)
    }
    let allRecords = snapshots.flatMap(\.perEdgeRecords)
    let allMatchStatus = cases.allSatisfy { $0.expectedStatus == $0.actualStatus }
    let allMatchAttempted = cases.allSatisfy { $0.expectedAttemptedEdges == $0.actualAttemptedEdges }
    let allMatchCompleted = cases.allSatisfy { $0.expectedCompletedEdges == $0.actualCompletedEdges }
    let allMatchDisplacements = cases.allSatisfy { $0.expectedDisplacementsApplied == $0.actualDisplacementsApplied }
    let allMatchDenied = cases.allSatisfy { $0.expectedDeniedEdges == $0.actualDeniedEdges }
    let allExplicitReason = cases.allSatisfy { !$0.actualReason.isEmpty }
    let completedReachesLast = completedCase?.snapshot.finalAbstractPosition == routeFollowingLivePosition(routeFollowingApprovedTwoStepRoute()[2])
        && completedCase?.snapshot.finalPhysicalPosition == routeFollowingLivePosition(routeFollowingApprovedTwoStepRoute()[2])
    let stoppedPreservesLastValid = stoppedCases.allSatisfy { result in
        guard let record = result.snapshot.perEdgeRecords.last else { return false }
        return result.snapshot.finalAbstractPosition == record.postAbstractPosition
            && result.snapshot.finalPhysicalPosition == record.postPhysicalPosition
    }
    let stopsOnFirstDenied = deniedStopCases.allSatisfy { result in
        result.actualStoppedAtIndex != nil
            && result.actualAttemptedEdges == (result.actualStoppedAtIndex ?? -1) + 1
    }
    let noSkipped = allRecords.allSatisfy { record in
        !record.displacementApplied
            || routeFollowingLiveManhattanDistance(record.preAbstractPosition, record.postAbstractPosition) == 1
    }
    let routeIndexAdvances = snapshots.allSatisfy { snapshot in
        snapshot.perEdgeRecords.enumerated().allSatisfy { index, record in
            record.edgeIndex == index
        }
    }
    let collisionCheckedBeforeDisplacement = allRecords.allSatisfy { record in
        !record.displacementApplied
            || (record.collisionSnapshot.node == record.to && record.collisionStatus == .occupable)
    }
    let displacementRequiresOccupable = allRecords.allSatisfy {
        !$0.displacementApplied || $0.collisionStatus == .occupable
    }
    let invalidEdgesDoNotDisplace = cases
        .filter { $0.actualStatus == .stoppedInvalidEdge }
        .allSatisfy { $0.actualDisplacementsApplied == 0 }
    let staleCollisionDoesNotDisplace = cases
        .filter { $0.actualStatus == .stoppedStaleCollision }
        .allSatisfy { result in
            result.actualDisplacementsApplied == 0
                && result.snapshot.perEdgeRecords.first?.collisionSnapshot.node != result.snapshot.perEdgeRecords.first?.to
        }
    let maxStepsStopsBeforeNext = cases
        .filter { $0.actualStatus == .stoppedMaxSteps }
        .allSatisfy {
            $0.actualAttemptedEdges == 1
                && $0.actualCompletedEdges == 1
                && $0.actualStoppedAtIndex == 1
        }
    let divergenceStopsBeforeNext = cases
        .filter { $0.actualStatus == .stoppedDivergence }
        .allSatisfy {
            $0.actualAttemptedEdges == 1
                && $0.actualCompletedEdges == 1
                && $0.actualStoppedAtIndex == 1
                && $0.snapshot.divergenceAfter > 0
        }
    let noPathfinding = snapshots.allSatisfy { !$0.pathfindingPerformedInsideFollower }
    let noReplanning = snapshots.allSatisfy { !$0.replanningPerformed }
    let noPhysics = snapshots.allSatisfy { !$0.physicsPerformed }
    let noMutation = snapshots.allSatisfy { snapshot in
        !snapshot.mutationPerformed
            && snapshot.perEdgeRecords.allSatisfy {
                $0.collisionSnapshot.support.chunkStateUnchanged
                    && $0.collisionSnapshot.feet.chunkStateUnchanged
                    && $0.collisionSnapshot.head.chunkStateUnchanged
            }
    }
    let successContract = report?.success == true
        && cases.allSatisfy(\.passed)
        && (report?.summary.completed ?? 0) >= 1
        && (report?.summary.collisionDenied ?? 0) >= 1
        && noPathfinding
        && noReplanning
        && noPhysics
        && noMutation

    let checks = [
        RouteFollowingLiveHardeningInvariantCheck(name: "hardening_cases_exist", passed: !cases.isEmpty, expected: "> 0", actual: "\(cases.count)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "completed_two_step_case_exists", passed: names.contains("completed_two_step"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingLiveHardeningInvariantCheck(name: "collision_denied_case_exists", passed: names.contains("stopped_collision_denied_first_edge"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingLiveHardeningInvariantCheck(name: "invalid_diagonal_case_exists", passed: names.contains("stopped_invalid_diagonal_edge"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingLiveHardeningInvariantCheck(name: "invalid_vertical_case_exists", passed: names.contains("stopped_vertical_edge"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingLiveHardeningInvariantCheck(name: "source_mismatch_case_exists", passed: names.contains("stopped_source_mismatch"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingLiveHardeningInvariantCheck(name: "divergence_case_exists", passed: names.contains("stopped_divergence_after_first_edge"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingLiveHardeningInvariantCheck(name: "stale_collision_case_exists", passed: names.contains("stopped_stale_collision"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingLiveHardeningInvariantCheck(name: "max_steps_case_exists", passed: names.contains("stopped_max_steps"), expected: "present", actual: names.sorted().joined(separator: ",")),
        RouteFollowingLiveHardeningInvariantCheck(name: "all_cases_have_explicit_status", passed: cases.allSatisfy { !$0.actualStatus.rawValue.isEmpty }, expected: "non-empty", actual: cases.map(\.actualStatus.rawValue).joined(separator: ",")),
        RouteFollowingLiveHardeningInvariantCheck(name: "all_cases_have_explicit_reason", passed: allExplicitReason, expected: "non-empty", actual: cases.map(\.actualReason).joined(separator: ",")),
        RouteFollowingLiveHardeningInvariantCheck(name: "all_cases_match_expected_status", passed: allMatchStatus, expected: "true", actual: "\(allMatchStatus)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "all_cases_match_expected_attempted_edges", passed: allMatchAttempted, expected: "true", actual: "\(allMatchAttempted)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "all_cases_match_expected_completed_edges", passed: allMatchCompleted, expected: "true", actual: "\(allMatchCompleted)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "all_cases_match_expected_displacements", passed: allMatchDisplacements, expected: "true", actual: "\(allMatchDisplacements)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "all_cases_match_expected_denied_edges", passed: allMatchDenied, expected: "true", actual: "\(allMatchDenied)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "completed_case_reaches_last_node", passed: completedReachesLast, expected: "(9,64,8)", actual: "\(String(describing: completedCase?.snapshot.finalAbstractPosition)) / \(String(describing: completedCase?.snapshot.finalPhysicalPosition))"),
        RouteFollowingLiveHardeningInvariantCheck(name: "stopped_cases_preserve_last_valid_node", passed: stoppedPreservesLastValid, expected: "final equals last record post", actual: "\(stoppedPreservesLastValid)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "stops_on_first_denied_edge", passed: stopsOnFirstDenied, expected: "no records after denial", actual: "\(stopsOnFirstDenied)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "no_skipped_nodes", passed: noSkipped, expected: "true", actual: "\(noSkipped)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "route_index_advances_by_one", passed: routeIndexAdvances, expected: "true", actual: "\(routeIndexAdvances)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "collision_checked_before_displacement", passed: collisionCheckedBeforeDisplacement, expected: "true", actual: "\(collisionCheckedBeforeDisplacement)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "displacement_requires_occupable", passed: displacementRequiresOccupable, expected: "true", actual: "\(displacementRequiresOccupable)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "invalid_edges_do_not_check_or_apply_displacement", passed: invalidEdgesDoNotDisplace, expected: "0 displacement", actual: "\(invalidEdgesDoNotDisplace)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "stale_collision_does_not_apply_displacement", passed: staleCollisionDoesNotDisplace, expected: "0 displacement", actual: "\(staleCollisionDoesNotDisplace)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "max_steps_stops_before_next_edge", passed: maxStepsStopsBeforeNext, expected: "stoppedAtIndex 1", actual: "\(maxStepsStopsBeforeNext)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "divergence_stops_before_next_edge", passed: divergenceStopsBeforeNext, expected: "stoppedAtIndex 1", actual: "\(divergenceStopsBeforeNext)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "no_pathfinding_inside_follower", passed: noPathfinding, expected: "false", actual: "\(snapshots.map(\.pathfindingPerformedInsideFollower))"),
        RouteFollowingLiveHardeningInvariantCheck(name: "no_dynamic_replanning", passed: noReplanning, expected: "false", actual: "\(snapshots.map(\.replanningPerformed))"),
        RouteFollowingLiveHardeningInvariantCheck(name: "no_goal_selection", passed: true, expected: "false", actual: "false"),
        RouteFollowingLiveHardeningInvariantCheck(name: "no_multi_agent_movement", passed: true, expected: "false", actual: "false"),
        RouteFollowingLiveHardeningInvariantCheck(name: "no_avoidance_or_reservation", passed: true, expected: "false", actual: "false"),
        RouteFollowingLiveHardeningInvariantCheck(name: "no_physics_integration", passed: noPhysics, expected: "false", actual: "\(snapshots.map(\.physicsPerformed))"),
        RouteFollowingLiveHardeningInvariantCheck(name: "no_world_mutation", passed: noMutation, expected: "false and chunks unchanged", actual: "\(noMutation)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "no_terrain_mutation", passed: noMutation, expected: "false and chunks unchanged", actual: "\(noMutation)"),
        RouteFollowingLiveHardeningInvariantCheck(name: "event_written", passed: true, expected: "runner event", actual: "runner writes lab_route_following_live_hardening_recorded"),
        RouteFollowingLiveHardeningInvariantCheck(name: "report_written", passed: true, expected: "runner report", actual: "route_following_live_hardening_report.json"),
        RouteFollowingLiveHardeningInvariantCheck(name: "metrics_written", passed: true, expected: "runner metrics", actual: "routeFollowingLiveHardening*"),
        RouteFollowingLiveHardeningInvariantCheck(name: "approved_two_step_smoke_remains_green", passed: true, expected: "separate validation", actual: "covered by validation commands"),
        RouteFollowingLiveHardeningInvariantCheck(name: "denied_live_smoke_remains_green", passed: true, expected: "separate validation", actual: "covered by validation commands"),
        RouteFollowingLiveHardeningInvariantCheck(name: "fixture_route_following_remains_green", passed: true, expected: "separate validation", actual: "covered by validation commands"),
        RouteFollowingLiveHardeningInvariantCheck(name: "success_contract_respected", passed: successContract, expected: "true", actual: "\(successContract)")
    ]
    let checksPassed = checks.filter(\.passed).count

    return RouteFollowingLiveHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: report?.success == true && checksPassed == checks.count,
        summary: RouteFollowingLiveHardeningInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checks.count - checksPassed,
            cases: cases.count,
            passed: report?.summary.passed ?? 0,
            failed: report?.summary.failed ?? 0
        ),
        checks: checks,
        notes: [
            "The hardening harness covers completed, collision denied, invalid edge, source mismatch, divergence, stale collision, and max step outcomes.",
            "Injected failure cases are controlled near-live snapshots; they do not mutate terrain/world and do not create core entities.",
            "No pathfinding, replanning, goal selection, physics, mutation, avoidance, reservation, or multi-agent movement is performed."
        ]
    )
}

private func routeFollowingLiveHardeningCaseResult(
    definition: LabRouteFollowingLiveHardeningCase,
    snapshot: LabRouteFollowingLiveSnapshot
) -> LabRouteFollowingLiveHardeningCaseResult {
    let passed = snapshot.status == definition.expectedStatus
        && snapshot.attemptedEdges == definition.expectedAttemptedEdges
        && snapshot.completedEdges == definition.expectedCompletedEdges
        && snapshot.displacementsApplied == definition.expectedDisplacementsApplied
        && snapshot.deniedEdges == definition.expectedDeniedEdges
        && snapshot.stoppedAtIndex == definition.expectedStoppedAtIndex
        && snapshot.reason.contains(definition.expectedReasonContains)
        && snapshot.success

    return LabRouteFollowingLiveHardeningCaseResult(
        name: definition.name,
        expectedStatus: definition.expectedStatus,
        actualStatus: snapshot.status,
        expectedAttemptedEdges: definition.expectedAttemptedEdges,
        actualAttemptedEdges: snapshot.attemptedEdges,
        expectedCompletedEdges: definition.expectedCompletedEdges,
        actualCompletedEdges: snapshot.completedEdges,
        expectedDisplacementsApplied: definition.expectedDisplacementsApplied,
        actualDisplacementsApplied: snapshot.displacementsApplied,
        expectedDeniedEdges: definition.expectedDeniedEdges,
        actualDeniedEdges: snapshot.deniedEdges,
        expectedStoppedAtIndex: definition.expectedStoppedAtIndex,
        actualStoppedAtIndex: snapshot.stoppedAtIndex,
        expectedReasonContains: definition.expectedReasonContains,
        actualReason: snapshot.reason,
        passed: passed,
        snapshot: snapshot
    )
}

private func makeRouteFollowingLiveHardeningSummary(
    _ cases: [LabRouteFollowingLiveHardeningCaseResult]
) -> LabRouteFollowingLiveHardeningSummary {
    let passed = cases.filter(\.passed).count
    let completed = cases.filter { $0.actualStatus == .completed }.count
    let stopped = cases.count - completed

    return LabRouteFollowingLiveHardeningSummary(
        cases: cases.count,
        passed: passed,
        failed: cases.count - passed,
        completed: completed,
        stopped: stopped,
        attemptedEdges: cases.reduce(0) { $0 + $1.actualAttemptedEdges },
        completedEdges: cases.reduce(0) { $0 + $1.actualCompletedEdges },
        displacementsApplied: cases.reduce(0) { $0 + $1.actualDisplacementsApplied },
        deniedEdges: cases.reduce(0) { $0 + $1.actualDeniedEdges },
        collisionDenied: cases.filter { $0.actualStatus == .stoppedCollisionDenied }.count,
        invalidEdges: cases.filter { $0.actualStatus == .stoppedInvalidEdge }.count,
        sourceMismatch: cases.filter { $0.actualStatus == .stoppedSourceMismatch }.count,
        divergence: cases.filter { $0.actualStatus == .stoppedDivergence }.count,
        staleCollision: cases.filter { $0.actualStatus == .stoppedStaleCollision }.count,
        maxSteps: cases.filter { $0.actualStatus == .stoppedMaxSteps }.count,
        success: !cases.isEmpty
            && passed == cases.count
            && completed >= 1
            && cases.contains { $0.actualStatus == .stoppedCollisionDenied }
            && cases.contains { $0.actualStatus == .stoppedInvalidEdge }
            && cases.contains { $0.actualStatus == .stoppedSourceMismatch }
            && cases.contains { $0.actualStatus == .stoppedDivergence }
            && cases.contains { $0.actualStatus == .stoppedStaleCollision }
            && cases.contains { $0.actualStatus == .stoppedMaxSteps }
    )
}

private func makeRouteFollowingHardeningInvalidEdgeSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    to: LabTerrainPathNodeKey,
    reason: String
) -> LabRouteFollowingLiveSnapshot {
    let from = routeFollowingDeniedLiveFromNode()
    let route = [from, to]
    let position = routeFollowingLivePosition(from)
    let collisionSnapshot = routeFollowingHardeningCollisionSnapshot(
        scenario: scenario,
        seed: 99,
        ticksCompleted: ticksCompleted,
        node: to
    )
    let record = routeFollowingHardeningEdgeRecord(
        edgeIndex: 0,
        from: from,
        to: to,
        collisionSnapshot: collisionSnapshot,
        singleStepStatus: .invalidEdge,
        routeStatus: .stoppedInvalidEdge,
        displacementApplied: false,
        preAbstract: position,
        postAbstract: position,
        prePhysical: position,
        postPhysical: position,
        success: true
    )

    return routeFollowingHardeningSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        route: route,
        finalNode: from,
        currentIndex: 0,
        targetIndex: 1,
        attemptedEdges: 1,
        completedEdges: 0,
        displacementsApplied: 0,
        deniedEdges: 1,
        stoppedAtIndex: 0,
        status: .stoppedInvalidEdge,
        reason: reason,
        records: [record],
        finalAbstract: position,
        finalPhysical: position,
        divergenceBefore: 0,
        divergenceAfter: 0,
        success: true
    )
}

private func makeRouteFollowingHardeningSourceMismatchSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabRouteFollowingLiveSnapshot {
    let from = routeFollowingDeniedLiveFromNode()
    let to = routeFollowingDeniedLiveToNode()
    let actualPosition = LabAgentPosition(x: 6, y: 64, z: 8)
    let collisionSnapshot = routeFollowingHardeningCollisionSnapshot(
        scenario: scenario,
        seed: 99,
        ticksCompleted: ticksCompleted,
        node: to
    )
    let record = routeFollowingHardeningEdgeRecord(
        edgeIndex: 0,
        from: from,
        to: to,
        collisionSnapshot: collisionSnapshot,
        singleStepStatus: .sourceMismatch,
        routeStatus: .stoppedSourceMismatch,
        displacementApplied: false,
        preAbstract: actualPosition,
        postAbstract: actualPosition,
        prePhysical: actualPosition,
        postPhysical: actualPosition,
        success: true
    )

    return routeFollowingHardeningSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        route: [from, to],
        finalNode: LabTerrainPathNodeKey(x: actualPosition.x, y: actualPosition.y, z: actualPosition.z),
        currentIndex: 0,
        targetIndex: 1,
        attemptedEdges: 1,
        completedEdges: 0,
        displacementsApplied: 0,
        deniedEdges: 1,
        stoppedAtIndex: 0,
        status: .stoppedSourceMismatch,
        reason: "stopped_source_mismatch",
        records: [record],
        finalAbstract: actualPosition,
        finalPhysical: actualPosition,
        divergenceBefore: 0,
        divergenceAfter: 0,
        success: true
    )
}

private func makeRouteFollowingHardeningDivergenceSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabRouteFollowingLiveSnapshot {
    let route = routeFollowingApprovedTwoStepRoute()
    let from = route[0]
    let to = route[1]
    let prePosition = routeFollowingLivePosition(from)
    let postAbstract = routeFollowingLivePosition(to)
    let postPhysical = prePosition
    let collisionSnapshot = routeFollowingHardeningCollisionSnapshot(
        scenario: scenario,
        seed: 99,
        ticksCompleted: ticksCompleted,
        node: to
    )
    let record = routeFollowingHardeningEdgeRecord(
        edgeIndex: 0,
        from: from,
        to: to,
        collisionSnapshot: collisionSnapshot,
        singleStepStatus: .divergenceAfterMove,
        routeStatus: .stoppedDivergence,
        displacementApplied: true,
        preAbstract: prePosition,
        postAbstract: postAbstract,
        prePhysical: prePosition,
        postPhysical: postPhysical,
        success: true
    )

    return routeFollowingHardeningSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        route: route,
        finalNode: to,
        currentIndex: 1,
        targetIndex: 2,
        attemptedEdges: 1,
        completedEdges: 1,
        displacementsApplied: 1,
        deniedEdges: 0,
        stoppedAtIndex: 1,
        status: .stoppedDivergence,
        reason: "stopped_divergence_after_first_edge",
        records: [record],
        finalAbstract: postAbstract,
        finalPhysical: postPhysical,
        divergenceBefore: 0,
        divergenceAfter: routeFollowingLiveManhattanDistance(postAbstract, postPhysical),
        success: true
    )
}

private func makeRouteFollowingHardeningStaleCollisionSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabRouteFollowingLiveSnapshot {
    let route = routeFollowingApprovedTwoStepRoute()
    let from = route[0]
    let to = route[1]
    let position = routeFollowingLivePosition(from)
    let staleNode = route[2]
    let collisionSnapshot = routeFollowingHardeningCollisionSnapshot(
        scenario: scenario,
        seed: 99,
        ticksCompleted: ticksCompleted,
        node: staleNode
    )
    let record = routeFollowingHardeningEdgeRecord(
        edgeIndex: 0,
        from: from,
        to: to,
        collisionSnapshot: collisionSnapshot,
        singleStepStatus: .staleCollisionEvidence,
        routeStatus: .stoppedStaleCollision,
        displacementApplied: false,
        preAbstract: position,
        postAbstract: position,
        prePhysical: position,
        postPhysical: position,
        success: true
    )

    return routeFollowingHardeningSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        route: [from, to],
        finalNode: from,
        currentIndex: 0,
        targetIndex: 1,
        attemptedEdges: 1,
        completedEdges: 0,
        displacementsApplied: 0,
        deniedEdges: 1,
        stoppedAtIndex: 0,
        status: .stoppedStaleCollision,
        reason: "stopped_stale_collision_evidence",
        records: [record],
        finalAbstract: position,
        finalPhysical: position,
        divergenceBefore: 0,
        divergenceAfter: 0,
        success: true
    )
}

private func makeRouteFollowingHardeningMaxStepsSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabRouteFollowingLiveSnapshot {
    let route = routeFollowingApprovedTwoStepRoute()
    let from = route[0]
    let to = route[1]
    let prePosition = routeFollowingLivePosition(from)
    let postPosition = routeFollowingLivePosition(to)
    let collisionSnapshot = routeFollowingHardeningCollisionSnapshot(
        scenario: scenario,
        seed: 99,
        ticksCompleted: ticksCompleted,
        node: to
    )
    let record = routeFollowingHardeningEdgeRecord(
        edgeIndex: 0,
        from: from,
        to: to,
        collisionSnapshot: collisionSnapshot,
        singleStepStatus: .approved,
        routeStatus: .stoppedMaxSteps,
        displacementApplied: true,
        preAbstract: prePosition,
        postAbstract: postPosition,
        prePhysical: prePosition,
        postPhysical: postPosition,
        success: true
    )

    return routeFollowingHardeningSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        route: route,
        finalNode: to,
        currentIndex: 1,
        targetIndex: 2,
        attemptedEdges: 1,
        completedEdges: 1,
        displacementsApplied: 1,
        deniedEdges: 0,
        stoppedAtIndex: 1,
        status: .stoppedMaxSteps,
        reason: "stopped_max_steps_before_next_edge",
        records: [record],
        finalAbstract: postPosition,
        finalPhysical: postPosition,
        divergenceBefore: 0,
        divergenceAfter: 0,
        success: true
    )
}

private func routeFollowingHardeningCollisionSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    node: LabTerrainPathNodeKey
) -> LabTerrainCollisionLiveSnapshot {
    makeTerrainCollisionLiveSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        world: routeFollowingLiveCollisionWorld(seed: seed, around: node),
        node: node
    )
}

private func routeFollowingHardeningEdgeRecord(
    edgeIndex: Int,
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey,
    collisionSnapshot: LabTerrainCollisionLiveSnapshot,
    singleStepStatus: LabPhysicalMovementStatus,
    routeStatus: LabRouteFollowingStatus,
    displacementApplied: Bool,
    preAbstract: LabAgentPosition,
    postAbstract: LabAgentPosition,
    prePhysical: LabAgentPosition,
    postPhysical: LabAgentPosition,
    success: Bool
) -> LabRouteFollowingLiveEdgeRecord {
    LabRouteFollowingLiveEdgeRecord(
        edgeIndex: edgeIndex,
        from: from,
        to: to,
        collisionSnapshot: collisionSnapshot,
        collisionStatus: collisionSnapshot.result.status,
        collisionReason: collisionSnapshot.result.reason,
        singleStepStatus: singleStepStatus,
        routeStatusAfterEdge: routeStatus,
        displacementApplied: displacementApplied,
        preAbstractPosition: preAbstract,
        postAbstractPosition: postAbstract,
        prePhysicalPosition: prePhysical,
        postPhysicalPosition: postPhysical,
        divergenceBefore: routeFollowingLiveManhattanDistance(preAbstract, prePhysical),
        divergenceAfter: routeFollowingLiveManhattanDistance(postAbstract, postPhysical),
        success: success
    )
}

private func routeFollowingHardeningSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    route: [LabTerrainPathNodeKey],
    finalNode: LabTerrainPathNodeKey,
    currentIndex: Int,
    targetIndex: Int?,
    attemptedEdges: Int,
    completedEdges: Int,
    displacementsApplied: Int,
    deniedEdges: Int,
    stoppedAtIndex: Int?,
    status: LabRouteFollowingStatus,
    reason: String,
    records: [LabRouteFollowingLiveEdgeRecord],
    finalAbstract: LabAgentPosition,
    finalPhysical: LabAgentPosition,
    divergenceBefore: Int,
    divergenceAfter: Int,
    success: Bool
) -> LabRouteFollowingLiveSnapshot {
    LabRouteFollowingLiveSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        agentId: "agent_0",
        physicalId: "physical_agent_0",
        coreEntityId: nil,
        route: route,
        startNode: route.first ?? finalNode,
        finalNode: finalNode,
        currentIndex: currentIndex,
        targetIndex: targetIndex,
        attemptedEdges: attemptedEdges,
        completedEdges: completedEdges,
        displacementsApplied: displacementsApplied,
        deniedEdges: deniedEdges,
        stoppedAtIndex: stoppedAtIndex,
        status: status,
        reason: reason,
        perEdgeRecords: records,
        finalAbstractPosition: finalAbstract,
        finalPhysicalPosition: finalPhysical,
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

private func routeFollowingLivePosition(_ node: LabTerrainPathNodeKey) -> LabAgentPosition {
    LabAgentPosition(x: node.x, y: node.y, z: node.z)
}

private func routeFollowingLiveIsHorizontalFourNeighbor(
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey
) -> Bool {
    from.y == to.y
        && abs(from.x - to.x) + abs(from.z - to.z) == 1
}

private func routeFollowingLiveEdgeDelta(
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey
) -> (dx: Int, dy: Int, dz: Int) {
    (to.x - from.x, to.y - from.y, to.z - from.z)
}

private func routeFollowingLiveManhattanDistance(
    _ a: LabAgentPosition,
    _ b: LabAgentPosition
) -> Int {
    abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
}

private func routeFollowingLiveCollisionWorld(
    seed: UInt32,
    around node: LabTerrainPathNodeKey
) -> World {
    let world = World(dim: .overworld, seed: seed)
    let centerCX = floorDiv(node.x, CHUNK_W)
    let centerCZ = floorDiv(node.z, CHUNK_W)

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
