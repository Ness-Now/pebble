import PebbleCore

enum PebbleAgentPhysicalActionFamily: String {
    case breakBlock
    case placeBlock
}

enum PebbleAgentPhysicalActionStatus: String {
    case succeeded
    case refused
    case staleTarget
    case physicalExecutionFailure
    case verificationFailure
    case rollbackFailure
}

enum PebbleAgentPhysicalActionFailure: String {
    case invalidActor
    case invalidRequest
    case outOfReach
    case chunkUnavailable
    case occupiedTarget
    case blockEntityUnsupported
    case unboundedSideEffects
    case targetChanged
    case coreRefused
    case outcomeMismatch
    case actorStateMismatch
    case postMutationRejected
    case rollbackMismatch
}

struct PebbleAgentPhysicalActionOutcome {
    let family: PebbleAgentPhysicalActionFamily
    let actorID: String
    let status: PebbleAgentPhysicalActionStatus
    let target: PhysicalBlockPosition
    let before: Int
    let after: Int
    let mutations: [PhysicalBlockMutation]
    let spawnedItemEntityIDs: [Int]
    let committedEffectCount: Int
    let failure: PebbleAgentPhysicalActionFailure?

    var succeeded: Bool { status == .succeeded }
}

private enum PebbleAgentBufferedPhysicalEffect {
    case sound(String, Double, Double, Double, Double, Double)
    case particles(String, Double, Double, Double, Int, Double, Int)
    case vibration(Double, Double, Double, Int, EntityRef?)
}

struct PebbleAgentBlockPlacementRequest {
    let actorID: String
    let hit: RaycastHit
    let target: PhysicalBlockPosition
    let expectedCell: Int
    let blockID: Int
    let heldItem: ItemStack
    let orientation: BlockPlacementOrientation
}

struct PebbleAgentBlockBreakRequest {
    let actorID: String
    let target: PhysicalBlockPosition
    let expectedCell: Int
    let heldItem: ItemStack?
    let isCreative: Bool
}

struct PebbleAgentBlockPlacementCustody {
    let consume: (Int) -> Void
    let verify: () -> Bool
    let rollback: () -> Bool
}

struct PebbleAgentBlockBreakToolState {
    let damage: (Int) -> Void
    let verify: () -> Bool
    let rollback: () -> Bool

    static let none = PebbleAgentBlockBreakToolState(
        damage: { _ in },
        verify: { true },
        rollback: { true }
    )
}

/// Thin actor/World boundary for agent physical actions.
///
/// It owns no cognition, inventory, drops, placement rules, or pathfinding. The
/// action rules remain in PebbleCore; callers may publish Civilization state
/// only after receiving a verified `.succeeded` outcome.
struct PebbleAgentPhysicalActionGateway {
    /// Compatibility entry point for existing bounded proof fixtures. It
    /// immediately narrows the raw probe to the same embodiment boundary used
    /// by live execution.
    func placeBlock(
        world: World,
        actor: LabCoreAgentEntity,
        request: PebbleAgentBlockPlacementRequest,
        custody: PebbleAgentBlockPlacementCustody,
        occupiedPositions: [PhysicalBlockPosition],
        verifyAfterMutation: () -> Bool = { true }
    ) -> PebbleAgentPhysicalActionOutcome {
        placeBlock(
            world: world,
            actor: PebbleAgentEmbodiment(probe: actor),
            request: request,
            custody: custody,
            occupiedPositions: occupiedPositions,
            verifyAfterMutation: verifyAfterMutation
        )
    }

    func placeBlock(
        world: World,
        actor: PebbleAgentEmbodiment,
        request: PebbleAgentBlockPlacementRequest,
        custody: PebbleAgentBlockPlacementCustody,
        occupiedPositions: [PhysicalBlockPosition],
        verifyAfterMutation: () -> Bool = { true }
    ) -> PebbleAgentPhysicalActionOutcome {
        let family = PebbleAgentPhysicalActionFamily.placeBlock
        guard actor.agentID == request.actorID, actor.isValid(in: world) else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                request.expectedCell,
                currentCell(world, request.target),
                [],
                .invalidActor
            )
        }
        guard request.blockID > 0,
              request.blockID < blockDefs.count,
              request.heldItem.id >= 0,
              request.heldItem.id < itemDefs.count,
              request.heldItem.count > 0,
              (0..<6).contains(request.hit.face),
              itemDef(request.heldItem.id).block.map(Int.init) == request.blockID,
              resolvedPlacementTarget(world: world, hit: request.hit) == request.target else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                request.expectedCell,
                currentCell(world, request.target),
                [],
                .invalidRequest
            )
        }
        guard isWithinBoundedReach(actor: actor, target: request.target) else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                request.expectedCell,
                currentCell(world, request.target),
                [],
                .outOfReach
            )
        }
        guard world.isChunkReady(request.target.x >> 4, request.target.z >> 4) else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                request.expectedCell,
                currentCell(world, request.target),
                [],
                .chunkUnavailable
            )
        }
        let before = currentCell(world, request.target)
        guard before == request.expectedCell else {
            return outcome(
                family: family,
                request.actorID,
                .staleTarget,
                request.target,
                request.expectedCell,
                before,
                [],
                .targetChanged
            )
        }
        guard !occupiedPositions.contains(request.target) else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                before,
                before,
                [],
                .occupiedTarget
            )
        }
        guard world.getBlockEntity(request.target.x, request.target.y, request.target.z) == nil else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                before,
                before,
                [],
                .blockEntityUnsupported
            )
        }
        let placementShape = blockDefs[request.blockID].shape
        guard placementShape != .door,
              placementShape != .bed,
              placementShape != .tallCross,
              onPlacedHandlers[request.blockID] == nil,
              !hasUntrackedNeighborSideEffects(world: world, target: request.target) else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                before,
                before,
                [],
                .unboundedSideEffects
            )
        }

        let entityIDsBefore = Set(world.entities.map(\.id))
        let (physical, bufferedEffects) = bufferPhysicalEffects(world: world) {
            executeBlockPlacement(
                BlockPlacementRuleContext(
                    world: world,
                    orientation: request.orientation,
                    vibrationSource: actor.entity,
                    consumeHeld: custody.consume
                ),
                request.hit,
                request.blockID,
                request.heldItem
            )
        }
        guard physical.succeeded else {
            if physical.mutations.isEmpty {
                return outcome(
                    family: family,
                    request.actorID,
                    .physicalExecutionFailure,
                    request.target,
                    before,
                    currentCell(world, request.target),
                    physical.mutations,
                    .coreRefused
                )
            }
            return rolledBackFailure(
                family: family,
                actorID: request.actorID,
                target: request.target,
                before: before,
                world: world,
                mutations: physical.mutations,
                entityIDsBefore: entityIDsBefore,
                rollbackActorState: custody.rollback,
                statusAfterRollback: .physicalExecutionFailure,
                failureAfterRollback: .coreRefused
            )
        }

        let physicalOutcomeMatches = physical.target == request.target
            && physical.finalCell == currentCell(world, request.target)
            && physical.finalCell.map { ($0 >> 4) == request.blockID } == true
            && !physical.mutations.isEmpty
            && mutationsConform(world: world, mutations: physical.mutations)
            && physical.mutations.allSatisfy {
                world.getBlockEntity($0.position.x, $0.position.y, $0.position.z) == nil
            }
        let custodyMatches = custody.verify()
        let acceptedAfterMutation = verifyAfterMutation()
        guard physicalOutcomeMatches, custodyMatches, acceptedAfterMutation else {
            let failure: PebbleAgentPhysicalActionFailure = !physicalOutcomeMatches
                ? .outcomeMismatch
                : !custodyMatches ? .actorStateMismatch : .postMutationRejected
            return rolledBackFailure(
                family: family,
                actorID: request.actorID,
                target: request.target,
                before: before,
                world: world,
                mutations: physical.mutations,
                entityIDsBefore: entityIDsBefore,
                rollbackActorState: custody.rollback,
                statusAfterRollback: .verificationFailure,
                failureAfterRollback: failure
            )
        }
        commitPhysicalEffects(bufferedEffects, world: world)
        return outcome(
            family: family,
            request.actorID,
            .succeeded,
            request.target,
            before,
            currentCell(world, request.target),
            physical.mutations,
            nil,
            committedEffectCount: bufferedEffects.count
        )
    }

    func breakBlock(
        world: World,
        actor: LabCoreAgentEntity,
        request: PebbleAgentBlockBreakRequest,
        toolState: PebbleAgentBlockBreakToolState = .none,
        occupiedPositions: [PhysicalBlockPosition],
        acquireDrops: ([Int]) -> Bool = { _ in true },
        verifyAfterMutation: () -> Bool = { true }
    ) -> PebbleAgentPhysicalActionOutcome {
        breakBlock(
            world: world,
            actor: PebbleAgentEmbodiment(probe: actor),
            request: request,
            toolState: toolState,
            occupiedPositions: occupiedPositions,
            acquireDrops: acquireDrops,
            verifyAfterMutation: verifyAfterMutation
        )
    }

    func breakBlock(
        world: World,
        actor: PebbleAgentEmbodiment,
        request: PebbleAgentBlockBreakRequest,
        toolState: PebbleAgentBlockBreakToolState = .none,
        occupiedPositions: [PhysicalBlockPosition],
        acquireDrops: ([Int]) -> Bool = { _ in true },
        verifyAfterMutation: () -> Bool = { true }
    ) -> PebbleAgentPhysicalActionOutcome {
        let family = PebbleAgentPhysicalActionFamily.breakBlock
        guard actor.agentID == request.actorID, actor.isValid(in: world) else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                request.expectedCell,
                currentCell(world, request.target),
                [],
                .invalidActor
            )
        }
        guard request.expectedCell != 0,
              request.heldItem.map({ $0.id >= 0 && $0.id < itemDefs.count }) ?? true else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                request.expectedCell,
                currentCell(world, request.target),
                [],
                .invalidRequest
            )
        }
        guard isWithinBoundedReach(actor: actor, target: request.target) else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                request.expectedCell,
                currentCell(world, request.target),
                [],
                .outOfReach
            )
        }
        guard world.isChunkReady(request.target.x >> 4, request.target.z >> 4) else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                request.expectedCell,
                currentCell(world, request.target),
                [],
                .chunkUnavailable
            )
        }
        let before = currentCell(world, request.target)
        guard before == request.expectedCell else {
            return outcome(
                family: family,
                request.actorID,
                .staleTarget,
                request.target,
                request.expectedCell,
                before,
                [],
                .targetChanged
            )
        }
        guard !occupiedPositions.contains(request.target) else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                before,
                before,
                [],
                .occupiedTarget
            )
        }
        guard world.getBlockEntity(request.target.x, request.target.y, request.target.z) == nil else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                before,
                before,
                [],
                .blockEntityUnsupported
            )
        }
        let breakShape = blockDefs[before >> 4].shape
        guard breakShape != .door,
              breakShape != .bed,
              breakShape != .tallCross,
              !hasUntrackedNeighborSideEffects(world: world, target: request.target) else {
            return outcome(
                family: family,
                request.actorID,
                .refused,
                request.target,
                before,
                before,
                [],
                .unboundedSideEffects
            )
        }

        let entityIDsBefore = Set(world.entities.map(\.id))
        let (physical, bufferedEffects) = bufferPhysicalEffects(world: world) {
            executeBlockBreak(
                BlockBreakRuleContext(
                    world: world,
                    heldItem: request.heldItem,
                    isCreative: request.isCreative,
                    vibrationSource: actor.entity,
                    damageTool: toolState.damage
                ),
                request.target.x,
                request.target.y,
                request.target.z
            )
        }
        guard physical.status == .succeeded else {
            return outcome(
                family: family,
                request.actorID,
                .physicalExecutionFailure,
                request.target,
                before,
                currentCell(world, request.target),
                physical.mutations,
                .coreRefused
            )
        }
        let physicalOutcomeMatches = physical.target == request.target
            && physical.originalCell == before
            && physical.finalCell == currentCell(world, request.target)
            && !physical.mutations.isEmpty
            && mutationsConform(world: world, mutations: physical.mutations)
            && physical.spawnedItemEntityIDs.count
                == Set(physical.spawnedItemEntityIDs).count
            && physical.spawnedItemEntityIDs.allSatisfy { id in
                world.entities.contains { entity in
                    entity.id == id && entity is ItemEntity
                }
            }
        let toolMatches = toolState.verify()
        let dropsAcquired = physicalOutcomeMatches && toolMatches
            ? acquireDrops(physical.spawnedItemEntityIDs)
            : false
        let acceptedAfterMutation = dropsAcquired && verifyAfterMutation()
        guard physicalOutcomeMatches, toolMatches, dropsAcquired, acceptedAfterMutation else {
            let failure: PebbleAgentPhysicalActionFailure = !physicalOutcomeMatches
                ? .outcomeMismatch
                : !toolMatches ? .actorStateMismatch : .postMutationRejected
            return rolledBackFailure(
                family: family,
                actorID: request.actorID,
                target: request.target,
                before: before,
                world: world,
                mutations: physical.mutations,
                entityIDsBefore: entityIDsBefore,
                rollbackActorState: toolState.rollback,
                statusAfterRollback: .verificationFailure,
                failureAfterRollback: failure
            )
        }
        commitPhysicalEffects(bufferedEffects, world: world)
        return outcome(
            family: family,
            request.actorID,
            .succeeded,
            request.target,
            before,
            currentCell(world, request.target),
            physical.mutations,
            nil,
            spawnedItemEntityIDs: physical.spawnedItemEntityIDs,
            committedEffectCount: bufferedEffects.count
        )
    }

    private func resolvedPlacementTarget(
        world: World,
        hit: RaycastHit
    ) -> PhysicalBlockPosition {
        var x = hit.x
        var y = hit.y
        var z = hit.z
        let hitCell = world.getBlock(hit.x, hit.y, hit.z)
        if REPLACEABLE[hitCell >> 4] == 0 {
            x += DIR_X[hit.face]
            y += DIR_Y[hit.face]
            z += DIR_Z[hit.face]
        }
        return PhysicalBlockPosition(x: x, y: y, z: z)
    }

    private func isWithinBoundedReach(
        actor: PebbleAgentEmbodiment,
        target: PhysicalBlockPosition
    ) -> Bool {
        let actorX = Int(actor.x.rounded(.down))
        let actorY = Int(actor.y.rounded(.down))
        let actorZ = Int(actor.z.rounded(.down))
        let horizontal = abs(target.x - actorX) + abs(target.z - actorZ)
        let vertical = target.y - actorY
        return horizontal == 1 && (-1...2).contains(vertical)
    }

    private func currentCell(_ world: World, _ position: PhysicalBlockPosition) -> Int {
        world.getBlock(position.x, position.y, position.z)
    }

    private func mutationsConform(
        world: World,
        mutations: [PhysicalBlockMutation]
    ) -> Bool {
        mutations.allSatisfy {
            currentCell(world, $0.position) == $0.after
        }
    }

    private func hasUntrackedNeighborSideEffects(
        world: World,
        target: PhysicalBlockPosition
    ) -> Bool {
        for index in 0..<6 {
            let neighbor = world.getBlock(
                target.x + DIR_X[index],
                target.y + DIR_Y[index],
                target.z + DIR_Z[index]
            )
            let neighborID = neighbor >> 4
            if neighborHandlers[neighborID] != nil || HAS_GRAVITY[neighborID] == 1 {
                return true
            }
        }
        return false
    }

    private func bufferPhysicalEffects<Result>(
        world: World,
        operation: () -> Result
    ) -> (Result, [PebbleAgentBufferedPhysicalEffect]) {
        let originalHooks = world.hooks
        var buffered: [PebbleAgentBufferedPhysicalEffect] = []
        var transactionalHooks = originalHooks
        transactionalHooks.playSound = { name, x, y, z, volume, pitch in
            buffered.append(.sound(name, x, y, z, volume, pitch))
        }
        transactionalHooks.addParticles = { name, x, y, z, count, spread, data in
            buffered.append(.particles(name, x, y, z, count, spread, data))
        }
        transactionalHooks.onVibration = { x, y, z, radius, source in
            buffered.append(.vibration(x, y, z, radius, source))
        }
        world.hooks = transactionalHooks
        let result = operation()
        world.hooks = originalHooks
        return (result, buffered)
    }

    private func commitPhysicalEffects(
        _ effects: [PebbleAgentBufferedPhysicalEffect],
        world: World
    ) {
        for effect in effects {
            switch effect {
            case let .sound(name, x, y, z, volume, pitch):
                world.hooks.playSound(name, x, y, z, volume, pitch)
            case let .particles(name, x, y, z, count, spread, data):
                world.hooks.addParticles(name, x, y, z, count, spread, data)
            case let .vibration(x, y, z, radius, source):
                world.hooks.onVibration?(x, y, z, radius, source)
            }
        }
    }

    private func rolledBackFailure(
        family: PebbleAgentPhysicalActionFamily,
        actorID: String,
        target: PhysicalBlockPosition,
        before: Int,
        world: World,
        mutations: [PhysicalBlockMutation],
        entityIDsBefore: Set<Int>,
        rollbackActorState: () -> Bool,
        statusAfterRollback: PebbleAgentPhysicalActionStatus,
        failureAfterRollback: PebbleAgentPhysicalActionFailure
    ) -> PebbleAgentPhysicalActionOutcome {
        let rollbackVerified = rollback(
            world: world,
            mutations: mutations,
            entityIDsBefore: entityIDsBefore,
            rollbackActorState: rollbackActorState
        )
        return outcome(
            family: family,
            actorID,
            rollbackVerified ? statusAfterRollback : .rollbackFailure,
            target,
            before,
            currentCell(world, target),
            mutations,
            rollbackVerified ? failureAfterRollback : .rollbackMismatch
        )
    }

    private func rollback(
        world: World,
        mutations: [PhysicalBlockMutation],
        entityIDsBefore: Set<Int>,
        rollbackActorState: () -> Bool
    ) -> Bool {
        var originalCells: [(PhysicalBlockPosition, Int)] = []
        for mutation in mutations where !originalCells.contains(where: { $0.0 == mutation.position }) {
            originalCells.append((mutation.position, mutation.before))
        }
        for mutation in mutations.reversed() {
            guard currentCell(world, mutation.position) == mutation.after else { return false }
            _ = world.setBlock(
                mutation.position.x,
                mutation.position.y,
                mutation.position.z,
                mutation.before
            )
        }
        let newEntities = world.entities.filter { !entityIDsBefore.contains($0.id) }
        for entity in newEntities {
            world.removeEntity(entity)
        }
        guard rollbackActorState() else { return false }
        return originalCells.allSatisfy { currentCell(world, $0.0) == $0.1 }
            && Set(world.entities.map(\.id)) == entityIDsBefore
    }

    private func outcome(
        family: PebbleAgentPhysicalActionFamily,
        _ actorID: String,
        _ status: PebbleAgentPhysicalActionStatus,
        _ target: PhysicalBlockPosition,
        _ before: Int,
        _ after: Int,
        _ mutations: [PhysicalBlockMutation],
        _ failure: PebbleAgentPhysicalActionFailure?,
        spawnedItemEntityIDs: [Int] = [],
        committedEffectCount: Int = 0
    ) -> PebbleAgentPhysicalActionOutcome {
        PebbleAgentPhysicalActionOutcome(
            family: family,
            actorID: actorID,
            status: status,
            target: target,
            before: before,
            after: after,
            mutations: mutations,
            spawnedItemEntityIDs: spawnedItemEntityIDs,
            committedEffectCount: committedEffectCount,
            failure: failure
        )
    }
}
