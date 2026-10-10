import PebbleAgents
import PebbleCore

struct PebbleAgentNavigationAdapter {
    static let radius = AgentNavigationObservation.maximumRadius
    static let maximumSurveyCandidateCount = 32

    /// Select only among already observed, Core-placeable standing sites.
    /// This is at most four columns by four harvesting heights, using the
    /// unchanged bounded planner. Session still owns actual route publication
    /// and the movement executor independently verifies every physical step.
    func observeFoodApproach(
        world: World,
        agent: AgentSnapshot,
        source: AgentPosition,
        preferredPosition: AgentPosition?,
        occupiedAgentPositions: [AgentPosition]
    ) -> AgentPosition? {
        let observation = observe(
            world: world, agent: agent, target: source,
            occupiedAgentPositions: occupiedAgentPositions, goalMode: .exact
        )
        return Self.selectFoodApproach(
            observation: observation, source: source, preferredPosition: preferredPosition
        )
    }

    static func selectFoodApproach(
        observation: AgentNavigationObservation,
        source: AgentPosition,
        preferredPosition: AgentPosition?
    ) -> AgentPosition? {
        let physicalSource = PhysicalBlockPosition(x: source.x, y: source.y, z: source.z)
        let sites = observation.cells.filter { cell in
            cell.status == .traversable
                && PebbleAgentPhysicalActionGateway.isWithinBoundedReach(
                    actorPosition: PhysicalBlockPosition(
                        x: cell.position.x, y: cell.position.y, z: cell.position.z
                    ), target: physicalSource
                )
        }.sorted { lhs, rhs in
            if (lhs.position == preferredPosition) != (rhs.position == preferredPosition) {
                return lhs.position == preferredPosition
            }
            func distance(_ position: AgentPosition) -> Int {
                abs(position.x - observation.origin.x) + abs(position.y - observation.origin.y)
                    + abs(position.z - observation.origin.z)
            }
            let left = distance(lhs.position), right = distance(rhs.position)
            if left != right { return left < right }
            if lhs.position.x != rhs.position.x { return lhs.position.x < rhs.position.x }
            if lhs.position.z != rhs.position.z { return lhs.position.z < rhs.position.z }
            return lhs.position.y < rhs.position.y
        }.prefix(16)
        for site in sites {
            let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                start: observation.origin, target: site.position, goalMode: .exact,
                cells: observation.cells, radius: observation.radius,
                maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
            ))
            if plan.found { return site.position }
        }
        return nil
    }

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
            goalMode: goalMode,
            ignoringEntityIDs: Self.observerEntityIDs(world: world, agentID: agent.id)
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
        goalMode: AgentNavigationGoalMode = .cardinalAdjacent,
        ignoringEntityIDs: Set<Int> = []
    ) -> AgentNavigationObservation {
        var cells: [AgentNavigationCell] = []
        // Ignore only the observing body. All other live occupancy is checked
        // by Core, alongside the caller's deterministic agent projection.
        let ignoredEntityIDs = ignoringEntityIDs
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

    /// One Core-owned terrain contract shared by coarse navigation and local
    /// movement sensing. Other live occupancy uses the same assessment; Core
    /// placement at the selected actual node verifies all live bodies.
    static func terrainAssessment(world: World, position: AgentPosition,
                                  ignoringEntityIDs: Set<Int> = []) -> EntityPlacementAssessment {
        assessEntityPlacement(
            in: world,
            at: EntityPlacementPosition(x: position.x, y: position.y, z: position.z),
            bodyWidth: 0.6, bodyHeight: 1.8,
            ignoringEntityIDs: ignoringEntityIDs
        )
    }

    static func observerEntityIDs(world: World, agentID: String) -> Set<Int> {
        Set(world.entities.compactMap {
            guard let body = $0 as? LabCoreAgentEntity, body.labAgentId == agentID else { return nil }
            return body.id
        })
    }

    private func physicalTerrainStatus(
        world: World,
        position: AgentPosition,
        ignoredEntityIDs: Set<Int>
    ) -> AgentNavigationCellStatus {
        let assessment = Self.terrainAssessment(world: world, position: position, ignoringEntityIDs: ignoredEntityIDs)
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
