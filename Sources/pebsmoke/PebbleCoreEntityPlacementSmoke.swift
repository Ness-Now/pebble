import Foundation
import PebbleCore

private func safePlacementWorld(seed: UInt32 = 57) -> World {
    let world = World(dim: .overworld, seed: seed)
    for cz in -1...1 {
        for cx in -1...1 {
            let chunk = Chunk(
                cx: cx,
                cz: cz,
                minY: world.info.minY,
                height: world.info.height
            )
            chunk.buildHeightmap()
            chunk.status = .lit
            world.setChunk(chunk)
        }
    }
    for z in -14...14 {
        for x in -14...14 {
            world.setBlock(x, 63, z, Int(cell(B.stone)), SET_SILENT)
        }
    }
    return world
}

private let safePlacementConfiguration =
    BoundedEntityPlacementSearchConfiguration(
        requiredCount: 3,
        horizontalRadius: 6,
        verticalRadius: 2,
        maximumCandidateEvaluations: 500,
        bodyWidth: 0.6,
        bodyHeight: 1.8,
        minimumSelectedHorizontalDistance: 1,
        minimumReservedHorizontalDistance: 2,
        minimumEgressCount: 1,
        maximumSafeDrop: 1
    )

private func placementDigest(
    _ result: BoundedEntityPlacementSearchResult
) -> String {
    let positions = result.positions
        .map { "\($0.x),\($0.y),\($0.z)" }
        .joined(separator: ";")
    let rejections = result.rejectionCounts.keys
        .sorted { $0.rawValue < $1.rawValue }
        .map { "\($0.rawValue)=\(result.rejectionCounts[$0] ?? 0)" }
        .joined(separator: ";")
    return "\(positions)|\(result.candidatesEvaluated)|\(rejections)"
}

func runPebbleCoreEntityPlacementSmoke() {
    section("post-Gate-B safe entity placement")

    let openWorld = safePlacementWorld()
    let valid = assessEntityPlacement(
        in: openWorld,
        at: EntityPlacementPosition(x: 4, y: 64, z: 2),
        bodyWidth: 0.6,
        bodyHeight: 1.8
    )
    check("safe placement accepts loaded supported free body", valid.isValid)

    let obstructedWorld = safePlacementWorld()
    obstructedWorld.setBlock(4, 64, 2, Int(cell(B.stone)), SET_SILENT)
    let obstructed = assessEntityPlacement(
        in: obstructedWorld,
        at: EntityPlacementPosition(x: 4, y: 64, z: 2),
        bodyWidth: 0.6,
        bodyHeight: 1.8
    )
    check("safe placement rejects body obstruction",
          obstructed.rejections.contains(.bodyObstructed))

    let fluidWorld = safePlacementWorld()
    fluidWorld.setBlock(4, 64, 2, Int(cell(B.water)), SET_SILENT)
    let fluid = assessEntityPlacement(
        in: fluidWorld,
        at: EntityPlacementPosition(x: 4, y: 64, z: 2),
        bodyWidth: 0.6,
        bodyHeight: 1.8
    )
    check("safe placement rejects incompatible body fluid",
          fluid.rejections.contains(.incompatibleFluid))

    let unloadedWorld = World(dim: .overworld, seed: 57)
    let unloaded = assessEntityPlacement(
        in: unloadedWorld,
        at: EntityPlacementPosition(x: 4, y: 64, z: 2),
        bodyWidth: 0.6,
        bodyHeight: 1.8
    )
    check("safe placement rejects unavailable chunks",
          unloaded.rejections == [.chunkUnavailable])

    let collisionWorld = safePlacementWorld()
    let player = Player(world: collisionWorld)
    player.setPos(4.5, 64, 2.5)
    collisionWorld.addEntity(player)
    let collision = assessEntityPlacement(
        in: collisionWorld,
        at: EntityPlacementPosition(x: 4, y: 64, z: 2),
        bodyWidth: 0.6,
        bodyHeight: 1.8
    )
    check("safe placement rejects live entity collision",
          collision.rejections.contains(.entityCollision))

    let adjacentTargets = [
        EntityPlacementPosition(x: 4, y: 64, z: 2),
        EntityPlacementPosition(x: 5, y: 64, z: 2),
        EntityPlacementPosition(x: 6, y: 64, z: 2),
    ]
    let adjacentSet = assessEntityPlacementSet(
        in: openWorld,
        at: adjacentTargets,
        bodyWidth: 0.6,
        bodyHeight: 1.8
    )
    let adjacentSetReversed = assessEntityPlacementSet(
        in: openWorld,
        at: Array(adjacentTargets.reversed()),
        bodyWidth: 0.6,
        bodyHeight: 1.8
    )
    check("collective placement accepts adjacent non-overlapping targets",
          adjacentSet.isValid && adjacentSet.overlaps.isEmpty)
    check("collective placement is target-order independent",
          adjacentSetReversed.isValid
              && Set(adjacentSet.assessments.map(\.position))
                  == Set(adjacentSetReversed.assessments.map(\.position))
              && adjacentSet.overlaps == adjacentSetReversed.overlaps)

    let overlappingTargets = [
        EntityPlacementPosition(x: 4, y: 64, z: 2),
        EntityPlacementPosition(x: 4, y: 64, z: 2),
    ]
    let overlappingSet = assessEntityPlacementSet(
        in: openWorld,
        at: overlappingTargets,
        bodyWidth: 0.6,
        bodyHeight: 1.8
    )
    check("collective placement rejects actual target overlap",
          !overlappingSet.isValid && overlappingSet.overlaps.count == 1)

    let foreignCollisionSet = assessEntityPlacementSet(
        in: collisionWorld,
        at: adjacentTargets,
        bodyWidth: 0.6,
        bodyHeight: 1.8
    )
    check("collective placement keeps foreign World collisions fail closed",
          !foreignCollisionSet.isValid
              && foreignCollisionSet.assessments.first?.rejections
                  .contains(.entityCollision) == true)

    let preferred = [
        EntityPlacementPosition(x: 4, y: 64, z: 2),
        EntityPlacementPosition(x: 5, y: 64, z: 2),
        EntityPlacementPosition(x: 6, y: 64, z: 2),
    ]
    let first = findSafeEntityPlacements(
        in: openWorld,
        anchor: EntityPlacementPosition(x: 0, y: 64, z: 0),
        preferredPositions: preferred,
        reservedPoints: [EntityPlacementReservedPoint(x: 0.5, y: 64, z: 0.5)],
        configuration: safePlacementConfiguration
    )
    let second = findSafeEntityPlacements(
        in: openWorld,
        anchor: EntityPlacementPosition(x: 0, y: 64, z: 0),
        preferredPositions: preferred,
        reservedPoints: [EntityPlacementReservedPoint(x: 0.5, y: 64, z: 0.5)],
        configuration: safePlacementConfiguration
    )
    check("safe placement preserves valid preferred cells",
          first.isComplete && first.positions == preferred)
    check("safe placement search is deterministic",
          placementDigest(first) == placementDigest(second))
    check("safe placement result respects actor separation",
          Set(first.positions).count == 3
              && zip(first.positions, first.positions.dropFirst()).allSatisfy {
                  lhs, rhs in
                  hypot(Double(lhs.x - rhs.x), Double(lhs.z - rhs.z)) >= 1
              })

    let fallbackWorld = safePlacementWorld()
    fallbackWorld.setBlock(4, 64, 2, Int(cell(B.stone)), SET_SILENT)
    let fallback = findSafeEntityPlacements(
        in: fallbackWorld,
        anchor: EntityPlacementPosition(x: 0, y: 64, z: 0),
        preferredPositions: preferred,
        reservedPoints: [EntityPlacementReservedPoint(x: 0.01, y: 64, z: 0.01)],
        configuration: safePlacementConfiguration
    )
    check("safe placement finds deterministic fallback around invalid preference",
          fallback.isComplete
              && !fallback.positions.contains(preferred[0])
              && fallback.rejectionCounts[.bodyObstructed, default: 0] > 0)
    let exactReservedSeparation = fallback.positions.allSatisfy { position in
        let dx = Double(position.x) + 0.5 - 0.01
        let dz = Double(position.z) + 0.5 - 0.01
        return hypot(dx, dz) >= 2
    }
    check("safe placement uses exact reserved World position",
          exactReservedSeparation)

    let cliffWorld = World(dim: .overworld, seed: 57)
    for cz in -1...1 {
        for cx in -1...1 {
            let chunk = Chunk(
                cx: cx,
                cz: cz,
                minY: cliffWorld.info.minY,
                height: cliffWorld.info.height
            )
            chunk.buildHeightmap()
            chunk.status = .lit
            cliffWorld.setChunk(chunk)
        }
    }
    cliffWorld.setBlock(4, 63, 2, Int(cell(B.stone)), SET_SILENT)
    let cliff = findSafeEntityPlacements(
        in: cliffWorld,
        anchor: EntityPlacementPosition(x: 4, y: 64, z: 2),
        preferredPositions: [EntityPlacementPosition(x: 4, y: 64, z: 2)],
        reservedPoints: [],
        configuration: BoundedEntityPlacementSearchConfiguration(
            requiredCount: 1,
            horizontalRadius: 0,
            verticalRadius: 0,
            maximumCandidateEvaluations: 1,
            bodyWidth: 0.6,
            bodyHeight: 1.8,
            minimumSelectedHorizontalDistance: 1,
            minimumReservedHorizontalDistance: 0,
            minimumEgressCount: 1,
            maximumSafeDrop: 1
        )
    )
    check("safe placement rejects isolated dangerous pillar",
          !cliff.isComplete
              && cliff.rejectionCounts[.dangerousAdjacentDrop] == 1)

    let bounded = findSafeEntityPlacements(
        in: unloadedWorld,
        anchor: EntityPlacementPosition(x: 0, y: 64, z: 0),
        preferredPositions: preferred,
        reservedPoints: [],
        configuration: BoundedEntityPlacementSearchConfiguration(
            requiredCount: 3,
            horizontalRadius: 12,
            verticalRadius: 8,
            maximumCandidateEvaluations: 5,
            bodyWidth: 0.6,
            bodyHeight: 1.8,
            minimumSelectedHorizontalDistance: 1,
            minimumReservedHorizontalDistance: 2,
            minimumEgressCount: 1,
            maximumSafeDrop: 1
        )
    )
    check("safe placement refusal obeys explicit candidate budget",
          !bounded.isComplete
              && bounded.positions.isEmpty
              && bounded.candidatesEvaluated == 5
              && bounded.maximumCandidateEvaluations == 5)
    check("safe placement refusal retains diagnostics",
          bounded.rejectionCounts[.chunkUnavailable] == 5)

    let entityCountBefore = openWorld.entityById.count
    let supportBefore = openWorld.getBlock(4, 63, 2)
    _ = findSafeEntityPlacements(
        in: openWorld,
        anchor: EntityPlacementPosition(x: 0, y: 64, z: 0),
        preferredPositions: preferred,
        reservedPoints: [],
        configuration: safePlacementConfiguration
    )
    check("safe placement search is read-only",
          openWorld.entityById.count == entityCountBefore
              && openWorld.getBlock(4, 63, 2) == supportBefore)
}
