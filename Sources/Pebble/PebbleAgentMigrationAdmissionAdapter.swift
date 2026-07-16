import PebbleAgents
import PebbleCore

struct PebbleAgentMigrationAdmissionResult {
    let observation: AgentMigrationWorldObservation
    let candidatesConsidered: Int
    let validCandidateCount: Int
}

struct PebbleAgentMigrationAdmissionAdapter {
    static let maximumCandidateCount = 16

    private struct AdmissionCandidate {
        let observation: AgentMigrationWorldObservation
        let routeLength: Int
        let distance: Int
        let direction: Int
    }

    private let receptionOffsets: [(x: Int, z: Int)] = [
        (4, -3), (3, -3), (4, -2), (3, -2),
        (5, -3), (4, -4), (2, -3), (3, -4),
        (5, -2), (2, -2), (5, -4), (2, -4),
        (4, -1), (3, -1), (5, -1), (2, -1),
    ]

    private let entryOffsets: [(x: Int, z: Int, direction: Int)] = [
        (0, -4, 0), (4, 0, 1), (0, 4, 2), (-4, 0, 3),
        (-1, -4, 0), (1, -4, 0), (4, -1, 1), (4, 1, 1),
        (-1, 4, 2), (1, 4, 2), (-4, -1, 3), (-4, 1, 3),
        (-2, -4, 0), (2, -4, 0), (4, -2, 1), (4, 2, 1),
    ]

    func selectReception(
        world: World,
        settlementAnchor: AgentPosition,
        occupiedPositions: Set<AgentPosition>
    ) -> AgentPosition? {
        receptionOffsets.prefix(Self.maximumCandidateCount).compactMap { offset in
            footPosition(
                world: world,
                x: settlementAnchor.x + offset.x,
                z: settlementAnchor.z + offset.z
            )
        }.first {
            safe(world: world, position: $0, occupiedPositions: occupiedPositions)
                && !admissionCandidates(
                    world: world,
                    receptionPosition: $0,
                    occupiedPositions: occupiedPositions
                ).isEmpty
        }
    }

    func observeAdmission(
        world: World,
        settlement: AgentPopulationSettlement,
        occupiedPositions: Set<AgentPosition>
    ) throws -> PebbleAgentMigrationAdmissionResult {
        guard safe(
            world: world,
            position: settlement.receptionPosition,
            occupiedPositions: occupiedPositions
        ) else {
            throw AgentPopulationError.admission(.receptionUnavailable)
        }
        let candidates = admissionCandidates(
            world: world,
            receptionPosition: settlement.receptionPosition,
            occupiedPositions: occupiedPositions
        )
        let considered = Self.maximumCandidateCount
        let ordered = candidates.sorted { lhs, rhs in
            if lhs.routeLength != rhs.routeLength { return lhs.routeLength < rhs.routeLength }
            if lhs.distance != rhs.distance { return lhs.distance < rhs.distance }
            if lhs.direction != rhs.direction { return lhs.direction < rhs.direction }
            let lp = lhs.observation.entryPosition
            let rp = rhs.observation.entryPosition
            if lp.x != rp.x { return lp.x < rp.x }
            if lp.z != rp.z { return lp.z < rp.z }
            if lp.y != rp.y { return lp.y < rp.y }
            return lhs.observation.candidateIndex < rhs.observation.candidateIndex
        }
        guard let selected = ordered.first else {
            throw AgentPopulationError.admission(.noValidEntry)
        }
        return PebbleAgentMigrationAdmissionResult(
            observation: selected.observation,
            candidatesConsidered: considered,
            validCandidateCount: ordered.count
        )
    }

    private func admissionCandidates(
        world: World,
        receptionPosition: AgentPosition,
        occupiedPositions: Set<AgentPosition>
    ) -> [AdmissionCandidate] {
        var candidates: [AdmissionCandidate] = []
        for (index, offset) in entryOffsets.prefix(Self.maximumCandidateCount).enumerated() {
            guard let entry = footPosition(
                world: world,
                x: receptionPosition.x + offset.x,
                z: receptionPosition.z + offset.z
            ), safe(
                world: world,
                position: entry,
                occupiedPositions: occupiedPositions
            ) else { continue }
            let distance = horizontalDistance(entry, receptionPosition)
            guard distance <= AgentPopulationConfiguration.live.maximumMigrationDistance else {
                continue
            }
            let cells = navigationCells(
                world: world,
                origin: entry,
                target: receptionPosition,
                occupiedPositions: occupiedPositions
            )
            let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                start: entry,
                target: receptionPosition,
                goalMode: .exact,
                cells: cells,
                radius: AgentNavigationObservation.maximumRadius,
                maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
            ))
            guard plan.found,
                  plan.positions.count >= 2,
                  plan.positions.count - 1
                    <= AgentPopulationConfiguration.live.maximumRouteLength,
                  routePreservesMigrationEligibility(
                      world: world,
                      route: plan.positions
            ) else {
                continue
            }
            candidates.append(AdmissionCandidate(
                observation: AgentMigrationWorldObservation(
                    worldTick: world.time,
                    candidateIndex: index,
                    entryPosition: entry,
                    receptionPosition: receptionPosition,
                    route: plan.positions
                ),
                routeLength: plan.positions.count,
                distance: distance,
                direction: offset.direction
            ))
        }
        return candidates
    }

    private func navigationCells(
        world: World,
        origin: AgentPosition,
        target: AgentPosition,
        occupiedPositions: Set<AgentPosition>
    ) -> [AgentNavigationCell] {
        let radius = AgentNavigationObservation.maximumRadius
        var cells: [AgentNavigationCell] = []
        for dx in -radius...radius {
            let remaining = radius - abs(dx)
            for dz in -remaining...remaining {
                let x = origin.x + dx
                let z = origin.z + dz
                guard let position = footPosition(world: world, x: x, z: z) else {
                    cells.append(AgentNavigationCell(
                        position: AgentPosition(x: x, y: origin.y, z: z),
                        status: .unavailable
                    ))
                    continue
                }
                let occupied = occupiedPositions.contains(position)
                    && position != origin && position != target
                let status: AgentNavigationCellStatus
                if occupied {
                    status = .blocked
                } else if safe(
                    world: world,
                    position: position,
                    occupiedPositions: position == target ? [] : occupiedPositions
                ) {
                    status = .traversable
                } else {
                    status = .blocked
                }
                cells.append(AgentNavigationCell(position: position, status: status))
            }
        }
        return cells
    }

    private func footPosition(world: World, x: Int, z: Int) -> AgentPosition? {
        guard world.isChunkReady(x >> 4, z >> 4) else { return nil }
        return AgentPosition(x: x, y: world.surfaceY(x, z), z: z)
    }

    private func safe(
        world: World,
        position: AgentPosition,
        occupiedPositions: Set<AgentPosition>
    ) -> Bool {
        guard world.isChunkReady(position.x >> 4, position.z >> 4),
              !occupiedPositions.contains(position) else { return false }
        let below = world.getBlock(position.x, position.y - 1, position.z)
        let feet = world.getBlock(position.x, position.y, position.z)
        let head = world.getBlock(position.x, position.y + 1, position.z)
        let belowID = below >> 4
        let feetID = feet >> 4
        let headID = head >> 4
        return blockDefs[belowID].solid
            && isAir(UInt16(truncatingIfNeeded: feet))
            && isAir(UInt16(truncatingIfNeeded: head))
            && belowID != Int(B.water) && belowID != Int(B.lava)
            && feetID != Int(B.water) && feetID != Int(B.lava)
            && headID != Int(B.water) && headID != Int(B.lava)
    }

    private func horizontalDistance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.z - rhs.z)
    }

    private func routePreservesMigrationEligibility(
        world: World,
        route: [AgentPosition]
    ) -> Bool {
        route.enumerated().allSatisfy { index, position in
            let next = index + 1 < route.count ? route[index + 1] : nil
            var traversable = 0
            var dangerousDrops = 0
            for direction in AgentCardinalDirection.allCases {
                let x = position.x + direction.dx
                let z = position.z + direction.dz
                let plannedY = next.flatMap {
                    $0.x == x && $0.z == z ? $0.y : nil
                }
                let movementY = plannedY ?? world.surfaceY(x, z)
                let candidate = AgentPosition(x: x, y: movementY, z: z)
                if safe(world: world, position: candidate, occupiedPositions: []) {
                    let delta = movementY - position.y
                    if (-1...1).contains(delta) {
                        traversable += 1
                    } else if delta <= -2 {
                        dangerousDrops += 1
                    }
                } else if world.isChunkReady(x >> 4, z >> 4) {
                    let below = world.getBlock(x, movementY - 1, z)
                    if isAir(UInt16(truncatingIfNeeded: below))
                        || movementY - position.y <= -2 {
                        dangerousDrops += 1
                    }
                }
            }
            return traversable > 0 && dangerousDrops < 2
        }
    }
}
