import PebbleAgents
import PebbleCore

struct PebbleAgentWorldSensor {
    func observe(world: World, agent: AgentSnapshot) throws -> AgentWorldObservation {
        let position = agent.position
        let center = observeColumn(world: world, position: position)
        let neighbors = AgentCardinalDirection.allCases.map { direction in
            let neighborPosition = AgentPosition(
                x: position.x + direction.dx,
                y: position.y,
                z: position.z + direction.dz
            )
            let fixedColumn = observeColumn(world: world, position: neighborPosition)
            let column: AgentWorldColumnObservation
            let movementFootY: Int?
            if fixedColumn.groundPresent && fixedColumn.feetClear && fixedColumn.headClear {
                column = fixedColumn
                movementFootY = position.y
            } else if let surfaceY = fixedColumn.surfaceY {
                let plannedY = agent.navigationProgress.nextStep.flatMap { next in
                    next.x == neighborPosition.x && next.z == neighborPosition.z
                        ? next.y
                        : nil
                }
                let movementY = plannedY ?? surfaceY
                let surfaceColumn = observeColumn(
                    world: world,
                    position: AgentPosition(
                        x: neighborPosition.x,
                        y: movementY,
                        z: neighborPosition.z
                    )
                )
                column = AgentWorldColumnObservation(
                    position: neighborPosition,
                    chunkReady: surfaceColumn.chunkReady,
                    surfaceY: surfaceColumn.surfaceY,
                    height: surfaceColumn.height,
                    blockBelow: surfaceColumn.blockBelow,
                    blockAtFeet: surfaceColumn.blockAtFeet,
                    blockAtHead: surfaceColumn.blockAtHead,
                    groundPresent: surfaceColumn.groundPresent,
                    feetClear: surfaceColumn.feetClear,
                    headClear: surfaceColumn.headClear
                )
                movementFootY = movementY
            } else {
                column = fixedColumn
                movementFootY = nil
            }
            let stepDelta: Int?
            if column.groundPresent && column.feetClear && column.headClear,
               let movementFootY {
                stepDelta = movementFootY - position.y
            } else {
                stepDelta = nil
            }
            let traversable = center.chunkReady
                && column.chunkReady
                && column.groundPresent
                && column.feetClear
                && column.headClear
                && stepDelta.map { (-1...1).contains($0) } == true
            let dangerousDrop = column.chunkReady
                && (!column.groundPresent || stepDelta.map { $0 <= -2 } == true)
            return AgentWorldNeighborObservation(
                direction: direction,
                column: column,
                stepDelta: stepDelta,
                traversable: traversable,
                dangerousDrop: dangerousDrop
            )
        }

        let biomeId: Int?
        let biomeName: String?
        let combinedLight: Int?
        let skyLight: Int?
        let blockLight: Int?
        if center.chunkReady {
            let id = world.biomeAt(position.x, position.y, position.z)
            biomeId = id
            biomeName = id >= 0 && id < BIOMES.count ? BIOMES[id]?.name : nil
            combinedLight = Int(world.lightAt(position.x, position.y, position.z))
            skyLight = world.getSkyLight(position.x, position.y, position.z)
            blockLight = world.getBlockLight(position.x, position.y, position.z)
        } else {
            biomeId = nil
            biomeName = nil
            combinedLight = nil
            skyLight = nil
            blockLight = nil
        }

        return try AgentWorldObservation(
            worldTick: world.time,
            position: position,
            center: center,
            neighbors: neighbors,
            biomeId: biomeId,
            biomeName: biomeName,
            combinedLight: combinedLight,
            skyLight: skyLight,
            blockLight: blockLight,
            dayTime: world.dayTime,
            raining: world.raining,
            thundering: world.thundering
        )
    }

    private func observeColumn(world: World, position: AgentPosition) -> AgentWorldColumnObservation {
        let ready = world.isChunkReady(position.x >> 4, position.z >> 4)
        guard ready else {
            return AgentWorldColumnObservation(
                position: position,
                chunkReady: false,
                surfaceY: nil,
                height: nil,
                blockBelow: nil,
                blockAtFeet: nil,
                blockAtHead: nil,
                groundPresent: false,
                feetClear: false,
                headClear: false
            )
        }

        let below = world.getBlock(position.x, position.y - 1, position.z)
        let feet = world.getBlock(position.x, position.y, position.z)
        let head = world.getBlock(position.x, position.y + 1, position.z)
        return AgentWorldColumnObservation(
            position: position,
            chunkReady: true,
            surfaceY: world.surfaceY(position.x, position.z),
            height: world.heightAt(position.x, position.z),
            blockBelow: below,
            blockAtFeet: feet,
            blockAtHead: head,
            groundPresent: !isAir(UInt16(truncatingIfNeeded: below)),
            feetClear: isAir(UInt16(truncatingIfNeeded: feet)),
            headClear: isAir(UInt16(truncatingIfNeeded: head))
        )
    }
}
