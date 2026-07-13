import PebbleAgents
import PebbleCore

struct PebbleAgentNavigationAdapter {
    static let radius = AgentNavigationObservation.maximumRadius

    func observe(
        world: World,
        agent: AgentSnapshot,
        target: AgentPosition,
        occupiedAgentPositions: [AgentPosition]
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
                if position == target || occupiedAgentPositions.contains(position) {
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
}
