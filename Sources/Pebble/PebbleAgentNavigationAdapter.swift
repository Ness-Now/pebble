import PebbleAgents
import PebbleCore

struct PebbleAgentNavigationAdapter {
    static let radius = AgentNavigationObservation.maximumRadius
    static let maximumSurveyCandidateCount = 32

    func observeSurvey(
        world: World,
        agent: AgentSnapshot,
        desiredTarget: AgentPosition,
        occupiedAgentPositions: [AgentPosition]
    ) -> AgentNavigationObservation? {
        let observation = observe(
            world: world,
            agent: agent,
            target: desiredTarget,
            occupiedAgentPositions: occupiedAgentPositions,
            goalMode: .exact
        )
        let surveyCells = observation.cells.map { cell -> AgentNavigationCell in
            guard cell.position != agent.position,
                  cell.status == .traversable,
                  hasCardinalDrop(world: world, position: cell.position) else { return cell }
            return AgentNavigationCell(position: cell.position, status: .blocked)
        }
        let candidates = surveyCells
            .filter { $0.status == .traversable }
            .sorted { lhs, rhs in
                let lhsDistance = abs(lhs.position.x - desiredTarget.x)
                    + abs(lhs.position.z - desiredTarget.z)
                let rhsDistance = abs(rhs.position.x - desiredTarget.x)
                    + abs(rhs.position.z - desiredTarget.z)
                if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
                if lhs.position.x != rhs.position.x { return lhs.position.x < rhs.position.x }
                if lhs.position.z != rhs.position.z { return lhs.position.z < rhs.position.z }
                return lhs.position.y < rhs.position.y
            }
            .prefix(Self.maximumSurveyCandidateCount)
        for candidate in candidates {
            let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                start: agent.position,
                target: candidate.position,
                goalMode: .exact,
                cells: surveyCells,
                radius: observation.radius,
                maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
            ))
            if plan.found {
                return AgentNavigationObservation(
                    worldTick: observation.worldTick,
                    origin: observation.origin,
                    target: candidate.position,
                    radius: observation.radius,
                    cells: surveyCells
                )
            }
        }
        return nil
    }

    func observeBoundedTravel(
        world: World,
        agent: AgentSnapshot,
        destination: AgentPosition,
        occupiedAgentPositions: [AgentPosition]
    ) -> AgentNavigationObservation? {
        let desired = AgentBoundedTravel.desiredWaypoint(
            from: agent.position,
            toward: destination
        )
        let observation = observe(
            world: world,
            agent: agent,
            target: desired,
            occupiedAgentPositions: occupiedAgentPositions,
            goalMode: .exact
        )
        let candidates = observation.cells
            .filter {
                $0.status == .traversable
                    && $0.position != agent.position
                    && AgentBoundedTravel.permitsNormalizedWaypoint(
                        $0.position,
                        desiredWaypoint: desired,
                        current: agent.position,
                        destination: destination
                    )
            }
            .sorted { lhs, rhs in
                let lhsDesired = abs(lhs.position.x - desired.x) + abs(lhs.position.z - desired.z)
                let rhsDesired = abs(rhs.position.x - desired.x) + abs(rhs.position.z - desired.z)
                if lhsDesired != rhsDesired { return lhsDesired < rhsDesired }
                let lhsRemaining = abs(lhs.position.x - destination.x)
                    + abs(lhs.position.z - destination.z)
                let rhsRemaining = abs(rhs.position.x - destination.x)
                    + abs(rhs.position.z - destination.z)
                if lhsRemaining != rhsRemaining { return lhsRemaining < rhsRemaining }
                if lhs.position.x != rhs.position.x { return lhs.position.x < rhs.position.x }
                if lhs.position.z != rhs.position.z { return lhs.position.z < rhs.position.z }
                return lhs.position.y < rhs.position.y
            }
            .prefix(Self.maximumSurveyCandidateCount)
        for candidate in candidates {
            let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                start: agent.position,
                target: candidate.position,
                goalMode: .exact,
                cells: observation.cells,
                radius: observation.radius,
                maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
            ))
            if plan.found {
                return AgentNavigationObservation(
                    worldTick: observation.worldTick,
                    origin: observation.origin,
                    target: candidate.position,
                    radius: observation.radius,
                    cells: observation.cells
                )
            }
        }
        return nil
    }

    private func hasCardinalDrop(world: World, position: AgentPosition) -> Bool {
        AgentCardinalDirection.allCases.contains { direction in
            let neighbor = AgentPosition(
                x: position.x + direction.dx,
                y: position.y,
                z: position.z + direction.dz
            )
            guard world.isChunkReady(neighbor.x >> 4, neighbor.z >> 4) else { return true }
            return isAir(UInt16(truncatingIfNeeded: world.getBlock(
                neighbor.x,
                neighbor.y - 1,
                neighbor.z
            )))
        }
    }

    func observe(
        world: World,
        agent: AgentSnapshot,
        target: AgentPosition,
        occupiedAgentPositions: [AgentPosition],
        goalMode: AgentNavigationGoalMode = .cardinalAdjacent
    ) -> AgentNavigationObservation {
        observe(
            world: world,
            origin: agent.position,
            target: target,
            occupiedAgentPositions: occupiedAgentPositions,
            goalMode: goalMode
        )
    }

    /// Shared live-World navigation observation from one physical origin.
    ///
    /// The origin overload keeps focused adapter proofs on the same production
    /// classification path without manufacturing an `AgentSnapshot`. Physical
    /// truth remains entirely in PebbleCore's placement assessment.
    func observe(
        world: World,
        origin: AgentPosition,
        target: AgentPosition,
        occupiedAgentPositions: [AgentPosition],
        goalMode: AgentNavigationGoalMode = .cardinalAdjacent
    ) -> AgentNavigationObservation {
        var cells: [AgentNavigationCell] = []
        // Entity occupancy remains the caller's explicit deterministic agent
        // projection below. Ignore every current entity only for Core's terrain
        // assessment so this does not silently change historical target/entity
        // collision semantics or reject the observing actor as its own blocker.
        let ignoredEntityIDs = Set(world.entities.map(\.id))
        for dx in -Self.radius...Self.radius {
            let remaining = Self.radius - abs(dx)
            for dz in -remaining...remaining {
                let x = origin.x + dx
                let z = origin.z + dz
                guard world.isChunkReady(x >> 4, z >> 4) else {
                    cells.append(AgentNavigationCell(
                        position: AgentPosition(x: x, y: origin.y, z: z),
                        status: .unavailable
                    ))
                    continue
                }

                let fixedY = origin.y
                let fixedPosition = AgentPosition(x: x, y: fixedY, z: z)
                let fixedLevelTraversable = physicalTerrainStatus(
                    world: world,
                    position: fixedPosition,
                    ignoredEntityIDs: ignoredEntityIDs
                ) == .traversable
                let surfaceY = world.surfaceY(x, z)
                var footLevels: [Int] = fixedLevelTraversable ? [fixedY] : []
                if !footLevels.contains(surfaceY) { footLevels.append(surfaceY) }
                if !footLevels.contains(target.y) { footLevels.append(target.y) }
                for footY in footLevels {
                    let position = AgentPosition(x: x, y: footY, z: z)
                    let status: AgentNavigationCellStatus
                    if (goalMode == .cardinalAdjacent && position == target)
                        || occupiedAgentPositions.contains(position) {
                        status = .blocked
                    } else {
                        status = physicalTerrainStatus(
                            world: world,
                            position: position,
                            ignoredEntityIDs: ignoredEntityIDs
                        )
                    }
                    cells.append(AgentNavigationCell(position: position, status: status))
                }
            }
        }
        return AgentNavigationObservation(
            worldTick: world.time,
            origin: origin,
            target: target,
            radius: Self.radius,
            cells: cells
        )
    }

    private func physicalTerrainStatus(
        world: World,
        position: AgentPosition,
        ignoredEntityIDs: Set<Int>
    ) -> AgentNavigationCellStatus {
        let assessment = assessEntityPlacement(
            in: world,
            at: EntityPlacementPosition(
                x: position.x,
                y: position.y,
                z: position.z
            ),
            bodyWidth: 0.6,
            bodyHeight: 1.8,
            ignoringEntityIDs: ignoredEntityIDs
        )
        if assessment.isValid { return .traversable }
        if assessment.rejections.contains(.chunkUnavailable) {
            return .unavailable
        }
        if assessment.rejections.contains(.incompatibleSupport) {
            return .dangerousDrop
        }
        return .blocked
    }

    func hasCardinalApproach(
        world: World,
        target: AgentPosition,
        occupiedAgentPositions: [AgentPosition]
    ) -> (available: Bool, blockReads: Int) {
        var blockReads = 0
        for direction in AgentCardinalDirection.allCases {
            let position = AgentPosition(
                x: target.x + direction.dx,
                y: target.y,
                z: target.z + direction.dz
            )
            guard !occupiedAgentPositions.contains(position),
                  world.isChunkReady(position.x >> 4, position.z >> 4) else { continue }
            blockReads += 3
            let below = world.getBlock(position.x, position.y - 1, position.z)
            let feet = world.getBlock(position.x, position.y, position.z)
            let head = world.getBlock(position.x, position.y + 1, position.z)
            if blockDefs[below >> 4].solid,
               isAir(UInt16(truncatingIfNeeded: feet)),
               isAir(UInt16(truncatingIfNeeded: head)) {
                return (true, blockReads)
            }
        }
        return (false, blockReads)
    }
}
