import PebbleAgents
import PebbleCore

struct PebbleAgentNavigationAdapter {
    static let radius = AgentNavigationObservation.maximumRadius

    func observe(
        world: World,
        agent: AgentSnapshot,
        target: AgentPosition,
        occupiedAgentPositions: [AgentPosition],
        goalMode: AgentNavigationGoalMode = .cardinalAdjacent
    ) -> AgentNavigationObservation {
        var cells: [AgentNavigationCell] = []
        for dx in -Self.radius...Self.radius {
            let remaining = Self.radius - abs(dx)
            for dz in -remaining...remaining {
                let x = agent.position.x + dx
                let z = agent.position.z + dz
                guard world.isChunkReady(x >> 4, z >> 4) else {
                    cells.append(AgentNavigationCell(
                        position: AgentPosition(x: x, y: agent.position.y, z: z),
                        status: .unavailable
                    ))
                    continue
                }

                let fixedY = agent.position.y
                let fixedBelow = world.getBlock(x, fixedY - 1, z)
                let fixedFeet = world.getBlock(x, fixedY, z)
                let fixedHead = world.getBlock(x, fixedY + 1, z)
                let fixedLevelTraversable = blockDefs[fixedBelow >> 4].solid
                    && isAir(UInt16(truncatingIfNeeded: fixedFeet))
                    && isAir(UInt16(truncatingIfNeeded: fixedHead))
                let footY = fixedLevelTraversable ? fixedY : world.surfaceY(x, z)
                let position = AgentPosition(x: x, y: footY, z: z)
                let below = world.getBlock(x, footY - 1, z)
                let feet = world.getBlock(x, footY, z)
                let head = world.getBlock(x, footY + 1, z)
                let status: AgentNavigationCellStatus
                if (goalMode == .cardinalAdjacent && position == target)
                    || occupiedAgentPositions.contains(position) {
                    status = .blocked
                } else if !blockDefs[below >> 4].solid {
                    status = .dangerousDrop
                } else if !isAir(UInt16(truncatingIfNeeded: feet))
                            || !isAir(UInt16(truncatingIfNeeded: head)) {
                    status = .blocked
                } else {
                    status = .traversable
                }
                cells.append(AgentNavigationCell(position: position, status: status))
            }
        }
        return AgentNavigationObservation(
            worldTick: world.time,
            origin: agent.position,
            target: target,
            radius: Self.radius,
            cells: cells
        )
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
