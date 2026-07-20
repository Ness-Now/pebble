import Foundation
import PebbleAgents
import PebbleCore

private struct PebbleAgentConstructionProofFixture {
    let origin: AgentPosition
    let originals: [(position: PhysicalBlockPosition, cell: Int)]
}

private struct PebbleAgentConstructionProofRun {
    let digest: String
    let placedFingerprints: [Int]
    let causalCount: Int
    let practiceDelta: Int
    let rollbackCount: Int
}

private enum PebbleAgentConstructionProofError: Error {
    case failed(String)
}

extension PebbleAgentController {
    func handleConstructionConvergence(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        guard arguments == ["proof"] else {
            return failure("Usage: /lab construction proof")
        }
        let gates = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_BUILD=1", buildFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_MATERIAL=1", materialFeatureEnabled),
            ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
            ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
            ("PEBBLELAB_APP_AGENTS_TRACE=1", traceEnabled),
            (
                "PEBBLELAB_DISPOSABLE_WORLD_PROOF=1",
                environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1"
            ),
        ]
        let missing = gates.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure(
                "Construction convergence proof refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard let published = session, activeWorld === world,
              published.skillsEnabled,
              published.constructionProject == nil else {
            return failure(
                "Construction convergence proof requires an active skill-enabled session without a project."
            )
        }
        guard isPaused, !movementEnabled, !autoInteractionEnabled,
              !economyAutoEnabled else {
            return failure(
                "Construction convergence proof requires pause, movement off, and auto modes off."
            )
        }
        let actorID = focusedAgentId ?? published.snapshot().agents.first?.id
        guard let actorID, let actor = probesByAgentId[actorID], !actor.dead,
              let actorSnapshot = published.snapshot().agents.first(where: {
                  $0.id == actorID
              }),
              let fixture = constructionProofFixture(
                  world: world,
                  actor: actor,
                  player: player
              ) else {
            return failure("Construction convergence proof found no safe bounded fixture.")
        }

        let originalCustody = copyItemInventory(actor.carriedItems)
        let originalPosition = (
            actor.x, actor.y, actor.z, actor.prevX, actor.prevY, actor.prevZ,
            actor.yaw, actor.pitch
        )
        let originalEntities = world.entities.map(\.id).sorted()
        do {
            let publishedBytes = try published.durableStateBytes()
            let first = try runConstructionProof(
                baseSession: published,
                builder: actorSnapshot,
                actor: actor,
                fixture: fixture,
                world: world,
                player: player
            )
            try requireConstructionProof(
                restoreConstructionProof(
                    fixture,
                    world: world,
                    actor: actor,
                    custody: originalCustody,
                    position: originalPosition,
                    entityIDs: originalEntities
                ),
                "first cleanup"
            )
            let second = try runConstructionProof(
                baseSession: published,
                builder: actorSnapshot,
                actor: actor,
                fixture: fixture,
                world: world,
                player: player
            )
            let cleanup = restoreConstructionProof(
                fixture,
                world: world,
                actor: actor,
                custody: originalCustody,
                position: originalPosition,
                entityIDs: originalEntities
            )
            let sessionUnchanged = try session?.durableStateBytes() == publishedBytes
            try requireConstructionProof(
                first.digest == second.digest
                    && first.placedFingerprints == second.placedFingerprints
                    && first.causalCount == 9 && second.causalCount == 9
                    && first.practiceDelta == 9 && second.practiceDelta == 9
                    && first.rollbackCount >= 2 && second.rollbackCount >= 2
                    && sessionUnchanged && cleanup,
                "deterministic repeat or cleanup"
            )
            trace(
                "construction proof actor=\(actorID) blueprint=fixedLeanToV1 cells=9 "
                    + "materials=stone:3,oak_log:6 custody=real slotOrder=stable "
                    + "wrongMaterial=refused missingMaterial=refused stale=refused "
                    + "nonreplaceable=refused occupied=refused wrongOrder=refused "
                    + "priorTamper=refused duplicate=refused supportRollback=exact "
                    + "publicationRollback=exact finalCellRollback=exact "
                    + "installed=9 consumed=9 ghostStock=0 causal=9 practice=9 "
                    + "playerParity=executeBlockPlacement session=unchanged cleanup=exact "
                    + "runs=2 digest=\(first.digest)"
            )
            return success(
                "Construction convergence proof passed: real custody, ordered PebbleCore placement, "
                    + "fault rollback, exact causality/practice, deterministic digest=\(first.digest)."
            )
        } catch {
            let cleanup = restoreConstructionProof(
                fixture,
                world: world,
                actor: actor,
                custody: originalCustody,
                position: originalPosition,
                entityIDs: originalEntities
            )
            return failure(
                "Construction convergence proof failed: \(error); cleanup verified=\(cleanup)."
            )
        }
    }

    private func runConstructionProof(
        baseSession: AgentSimulationSession,
        builder: AgentSnapshot,
        actor: LabCoreAgentEntity,
        fixture: PebbleAgentConstructionProofFixture,
        world: World,
        player: Player
    ) throws -> PebbleAgentConstructionProofRun {
        try prepareConstructionProof(fixture, world: world)
        actor.carriedItems = Array(
            repeating: nil,
            count: LabCoreAgentEntity.carriedItemSlotCount
        )
        let blueprint = AgentBlueprint.fixedLeanToV1
        let project = try AgentConstructionProject(
            projectId: "civ18-proof:\(builder.id):\(baseSession.tick)",
            blueprint: blueprint,
            builderAgentId: builder.id,
            origin: fixture.origin,
            createdAtTick: baseSession.tick,
            previousHomePosition: builder.homePosition,
            originalFingerprints: blueprint.cells.map {
                AgentConstructionCellFingerprint(
                    cellIndex: $0.index,
                    originalFingerprint: 0
                )
            },
            materialAuthority: .physicalCustody
        )
        var proofSession = baseSession
        try proofSession.createConstructionProject(project)
        try proofSession.setBuildAutoEnabled(true)
        var executor = PebbleAgentConstructionExecutor()
        try executor.begin(project: project)
        let abstractBefore = proofSession.snapshot()
        let practiceBefore = proofSession.practiceUnits(
            agentID: AgentID(rawValue: builder.id)!,
            domain: .construction
        )
        let occupied = probesByAgentId.values.filter { $0 !== actor }.map {
            AgentPosition(
                x: Int($0.x.rounded(.down)),
                y: Int($0.y.rounded(.down)),
                z: Int($0.z.rounded(.down))
            )
        }
        let playerPosition = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )

        try alignConstructionProofActor(
            session: &proofSession,
            actor: actor,
            position: project.nextWorkPosition!
        )
        let firstIntent = constructionProofIntent(project: project, tick: proofSession.tick)
        let initialBytes = try proofSession.durableStateBytes()
        let initialBlock = world.getBlock(
            firstIntent.target.x, firstIntent.target.y, firstIntent.target.z
        )

        var wrongOrder = firstIntent
        wrongOrder = AgentPlacementIntent(
            placementId: "civ18-wrong-order",
            projectId: wrongOrder.projectId,
            builderAgentId: wrongOrder.builderAgentId,
            tick: wrongOrder.tick,
            cellIndex: 1,
            target: wrongOrder.target,
            workPosition: wrongOrder.workPosition,
            resource: wrongOrder.resource
        )
        try expectConstructionFailure(.invalidCell) {
            try executeConstructionProofPlacement(
                session: &proofSession,
                executor: &executor,
                actor: actor,
                intent: wrongOrder,
                world: world,
                occupied: occupied,
                playerPosition: playerPosition
            )
        }
        try requireConstructionProof(
            try proofSession.durableStateBytes() == initialBytes,
            "wrong-order session mutation"
        )

        try expectConstructionFailure(.missingMaterial) {
            try executeConstructionProofPlacement(
                session: &proofSession,
                executor: &executor,
                actor: actor,
                intent: firstIntent,
                world: world,
                occupied: occupied,
                playerPosition: playerPosition
            )
        }
        actor.carriedItems[0] = ItemStack(iid("oak_log"), 1)
        let wrongCustody = copyItemInventory(actor.carriedItems)
        try expectConstructionFailure(.wrongMaterial) {
            try executeConstructionProofPlacement(
                session: &proofSession,
                executor: &executor,
                actor: actor,
                intent: firstIntent,
                world: world,
                occupied: occupied,
                playerPosition: playerPosition
            )
        }
        try requireConstructionProof(
            constructionProofSlotsEqual(actor.carriedItems, wrongCustody),
            "wrong material custody changed"
        )
        actor.carriedItems[0] = ItemStack(iid("stone"), 1)
        actor.carriedItems[2] = ItemStack(iid("stone"), 1)
        try requireConstructionProof(
            materialCustodyGateway.placementBinding(
                actor: actor,
                requiredBlockID: Int(B.stone)
            )?.slot == 0,
            "deterministic compatible slot order"
        )
        actor.carriedItems[0] = ItemStack(iid("stone"), 3)
        actor.carriedItems[1] = ItemStack(iid("oak_log"), 6)
        actor.carriedItems[2] = nil
        let fullCustody = copyItemInventory(actor.carriedItems)

        _ = world.setBlock(
            firstIntent.target.x, firstIntent.target.y, firstIntent.target.z,
            Int(cell(B.cobblestone)), SET_SILENT
        )
        try expectConstructionFailure(.staleFingerprint) {
            try executeConstructionProofPlacement(
                session: &proofSession,
                executor: &executor,
                actor: actor,
                intent: firstIntent,
                world: world,
                occupied: occupied,
                playerPosition: playerPosition
            )
        }
        _ = world.setBlock(
            firstIntent.target.x, firstIntent.target.y, firstIntent.target.z,
            initialBlock, SET_SILENT
        )
        try requireConstructionProof(
            constructionProofSlotsEqual(actor.carriedItems, fullCustody),
            "stale target consumed custody"
        )

        try expectConstructionFailure(.occupied) {
            try executeConstructionProofPlacement(
                session: &proofSession,
                executor: &executor,
                actor: actor,
                intent: firstIntent,
                world: world,
                occupied: occupied + [firstIntent.target],
                playerPosition: playerPosition
            )
        }
        try requireConstructionProof(
            world.getBlock(firstIntent.target.x, firstIntent.target.y, firstIntent.target.z)
                == initialBlock
                && constructionProofSlotsEqual(actor.carriedItems, fullCustody),
            "occupied target changed state"
        )

        _ = world.setBlock(
            firstIntent.target.x, firstIntent.target.y, firstIntent.target.z,
            Int(cell(B.stone)), SET_SILENT
        )
        let nonreplaceableBinding = materialCustodyGateway.placementBinding(
            actor: actor,
            requiredBlockID: Int(B.stone)
        )!
        let nonreplaceable = physicalActionGateway.placeBlock(
            world: world,
            actor: actor,
            request: PebbleAgentBlockPlacementRequest(
                actorID: builder.id,
                hit: RaycastHit(
                    x: firstIntent.target.x, y: firstIntent.target.y,
                    z: firstIntent.target.z, face: Dir.east,
                    cell: Int(cell(B.stone)), t: 0,
                    px: Double(firstIntent.target.x) + 0.5,
                    py: Double(firstIntent.target.y) + 0.5,
                    pz: Double(firstIntent.target.z) + 0.5
                ),
                target: PhysicalBlockPosition(
                    x: firstIntent.target.x,
                    y: firstIntent.target.y,
                    z: firstIntent.target.z
                ),
                expectedCell: Int(cell(B.stone)),
                blockID: Int(B.stone),
                heldItem: nonreplaceableBinding.heldItem,
                orientation: BlockPlacementOrientation(yaw: actor.yaw, pitch: actor.pitch)
            ),
            custody: nonreplaceableBinding.custody,
            occupiedPositions: []
        )
        try requireConstructionProof(
            !nonreplaceable.succeeded
                && nonreplaceable.committedEffectCount == 0
                && constructionProofSlotsEqual(actor.carriedItems, fullCustody),
            "nonreplaceable target not atomically refused"
        )
        _ = world.setBlock(
            firstIntent.target.x, firstIntent.target.y, firstIntent.target.z,
            initialBlock, SET_SILENT
        )

        try executeConstructionProofPlacement(
            session: &proofSession,
            executor: &executor,
            actor: actor,
            intent: firstIntent,
            world: world,
            occupied: occupied,
            playerPosition: playerPosition
        )
        try requireConstructionProof(
            actor.carriedItems[0]?.count == 2
                && proofSession.constructionProject?.placedCellIndices == [0],
            "first real placement"
        )
        let afterFirstBytes = try proofSession.durableStateBytes()
        let afterFirstCustody = copyItemInventory(actor.carriedItems)
        try expectConstructionFailure(.invalidCell) {
            try executeConstructionProofPlacement(
                session: &proofSession,
                executor: &executor,
                actor: actor,
                intent: firstIntent,
                world: world,
                occupied: occupied,
                playerPosition: playerPosition
            )
        }
        try requireConstructionProof(
            try proofSession.durableStateBytes() == afterFirstBytes
                && constructionProofSlotsEqual(actor.carriedItems, afterFirstCustody),
            "duplicate placement changed state"
        )

        let firstPlaced = world.getBlock(
            firstIntent.target.x, firstIntent.target.y, firstIntent.target.z
        )
        _ = world.setBlock(
            firstIntent.target.x, firstIntent.target.y, firstIntent.target.z,
            0, SET_SILENT
        )
        let secondProject = proofSession.constructionProject!
        try alignConstructionProofActor(
            session: &proofSession,
            actor: actor,
            position: secondProject.nextWorkPosition!
        )
        let secondIntent = constructionProofIntent(
            project: secondProject,
            tick: proofSession.tick
        )
        try expectConstructionFailure(.previousCellChanged) {
            try executeConstructionProofPlacement(
                session: &proofSession,
                executor: &executor,
                actor: actor,
                intent: secondIntent,
                world: world,
                occupied: occupied,
                playerPosition: playerPosition
            )
        }
        _ = world.setBlock(
            firstIntent.target.x, firstIntent.target.y, firstIntent.target.z,
            firstPlaced, SET_SILENT
        )
        _ = try proofSession.advanceTick()

        while proofSession.constructionProject!.nextCellIndex < 8 {
            let active = proofSession.constructionProject!
            try alignConstructionProofActor(
                session: &proofSession,
                actor: actor,
                position: active.nextWorkPosition!
            )
            if active.nextCellIndex == 3 {
                let woodBefore = copyItemInventory(actor.carriedItems)
                actor.carriedItems[0] = ItemStack(iid("stone"), 1)
                actor.carriedItems[1] = nil
                try expectConstructionFailure(.wrongMaterial) {
                    try executeConstructionProofPlacement(
                        session: &proofSession,
                        executor: &executor,
                        actor: actor,
                        intent: constructionProofIntent(
                            project: active,
                            tick: proofSession.tick
                        ),
                        world: world,
                        occupied: occupied,
                        playerPosition: playerPosition
                    )
                }
                actor.carriedItems = woodBefore
            }
            try executeConstructionProofPlacement(
                session: &proofSession,
                executor: &executor,
                actor: actor,
                intent: constructionProofIntent(project: active, tick: proofSession.tick),
                world: world,
                occupied: occupied,
                playerPosition: playerPosition
            )
            if active.nextCellIndex == 1 {
                try requireConstructionProof(
                    actor.carriedItems[0]?.count == 1,
                    "second stone placement stack count"
                )
            } else if active.nextCellIndex == 2 {
                try requireConstructionProof(
                    actor.carriedItems[0] == nil,
                    "third stone placement slot normalization"
                )
            }
            _ = try proofSession.advanceTick()
        }

        let finalProject = proofSession.constructionProject!
        try alignConstructionProofActor(
            session: &proofSession,
            actor: actor,
            position: finalProject.nextWorkPosition!
        )
        let finalIntent = constructionProofIntent(
            project: finalProject,
            tick: proofSession.tick
        )
        let restFloor = PhysicalBlockPosition(
            x: finalProject.restPosition.x,
            y: finalProject.restPosition.y - 1,
            z: finalProject.restPosition.z
        )
        let finalBeforeBytes = try proofSession.durableStateBytes()
        let finalBeforeCustody = copyItemInventory(actor.carriedItems)
        _ = world.setBlock(restFloor.x, restFloor.y, restFloor.z, 0, SET_SILENT)
        try expectConstructionFailure(.structureValidationFailed) {
            try executeConstructionProofPlacement(
                session: &proofSession,
                executor: &executor,
                actor: actor,
                intent: finalIntent,
                world: world,
                occupied: occupied,
                playerPosition: playerPosition,
                complete: true
            )
        }
        try requireConstructionProof(
            world.getBlock(finalIntent.target.x, finalIntent.target.y, finalIntent.target.z) == 0
                && constructionProofSlotsEqual(actor.carriedItems, finalBeforeCustody)
                && (try proofSession.durableStateBytes()) == finalBeforeBytes
                && executor.state.lastCommittedEffectCount == 0,
            "support/final structure rollback"
        )
        _ = world.setBlock(
            restFloor.x, restFloor.y, restFloor.z, Int(cell(B.stone)), SET_SILENT
        )
        do {
            try executeConstructionProofPlacement(
                session: &proofSession,
                executor: &executor,
                actor: actor,
                intent: finalIntent,
                world: world,
                occupied: occupied,
                playerPosition: playerPosition,
                failPublication: true,
                complete: true
            )
            throw PebbleAgentConstructionProofError.failed("late publication accepted")
        } catch PebbleAgentConstructionProofError.failed(let label)
            where label == "injected publication failure" {}
        try requireConstructionProof(
            world.getBlock(finalIntent.target.x, finalIntent.target.y, finalIntent.target.z) == 0
                && constructionProofSlotsEqual(actor.carriedItems, finalBeforeCustody)
                && (try proofSession.durableStateBytes()) == finalBeforeBytes
                && proofSession.constructionProject?.nextCellIndex == 8
                && executor.state.lastCommittedEffectCount == 0,
            "late final-cell rollback"
        )
        try executeConstructionProofPlacement(
            session: &proofSession,
            executor: &executor,
            actor: actor,
            intent: finalIntent,
            world: world,
            occupied: occupied,
            playerPosition: playerPosition,
            complete: true
        )

        let placedFingerprints = blueprint.cells.map { cell -> Int in
            let target = project.worldPosition(for: cell)
            return world.getBlock(target.x, target.y, target.z)
        }
        let constructionEvents = proofSession.causalLedgerSnapshot().events.filter {
            $0.kind == .constructionPlacement
                && $0.operationID?.rawValue.hasPrefix("civ18-proof-cell:") == true
        }
        let practiceAfter = proofSession.practiceUnits(
            agentID: AgentID(rawValue: builder.id)!,
            domain: .construction
        )
        let finalSnapshot = proofSession.snapshot()
        let abstractExact = finalSnapshot.campStock == abstractBefore.campStock
            && finalSnapshot.agents.first { $0.id == builder.id }?.resourceInventory
                == abstractBefore.agents.first { $0.id == builder.id }?.resourceInventory
            && finalSnapshot.conservation == abstractBefore.conservation
        try requireConstructionProof(
            finalSnapshot.constructionProject?.status == .completed
                && finalSnapshot.constructionProject?.placedCellIndices
                    == blueprint.cells.map(\.index)
                && finalSnapshot.constructionProject?.installedMaterialTotals.amounts
                    == blueprint.materialRequirements
                && placedFingerprints.allSatisfy { $0 != 0 }
                && actor.carriedItems[0] == nil && actor.carriedItems[1] == nil
                && constructionEvents.count == 9
                && practiceAfter - practiceBefore == 9
                && abstractExact && finalSnapshot.conservation.balanced,
            "completed structure or conservation"
        )
        let digestInput = [
            project.projectId,
            placedFingerprints.map(String.init).joined(separator: ","),
            "custody=0,0",
            "progress=\(finalSnapshot.constructionProject?.nextCellIndex ?? -1)",
            "causal=\(constructionEvents.count)",
            "practice=\(practiceAfter - practiceBefore)",
            "rollbacks=\(executor.state.rollbackCount)",
        ].joined(separator: "|")
        let digest = String(hashString(digestInput), radix: 16)
        try requireConstructionProof(executor.cleanup(world: world), "executor cleanup")
        return PebbleAgentConstructionProofRun(
            digest: digest,
            placedFingerprints: placedFingerprints,
            causalCount: constructionEvents.count,
            practiceDelta: practiceAfter - practiceBefore,
            rollbackCount: executor.state.rollbackCount
        )
    }

    private func executeConstructionProofPlacement(
        session: inout AgentSimulationSession,
        executor: inout PebbleAgentConstructionExecutor,
        actor: LabCoreAgentEntity,
        intent: AgentPlacementIntent,
        world: World,
        occupied: [AgentPosition],
        playerPosition: AgentPosition,
        failPublication: Bool = false,
        complete: Bool = false
    ) throws {
        guard let project = session.constructionProject,
              let actorSnapshot = session.snapshot().agents.first(where: {
                  $0.id == intent.builderAgentId
              }) else {
            throw PebbleAgentConstructionProofError.failed("proof project missing")
        }
        var candidate = session
        try executor.place(
            world: world,
            actor: actorSnapshot,
            physicalActor: actor,
            project: project,
            intent: intent,
            occupiedAgentPositions: occupied,
            playerPosition: playerPosition,
            buildGateEnabled: true,
            buildAutoEnabled: session.buildAutoEnabled,
            materialGateway: materialCustodyGateway,
            physicalGateway: physicalActionGateway,
            prevalidate: { try session.prevalidatePlacement(intent) },
            publishAndVerify: { finalCell, actualFingerprint in
                let outcome = AgentPlacementOutcome(
                    placementId: intent.placementId,
                    projectId: intent.projectId,
                    builderAgentId: intent.builderAgentId,
                    tick: intent.tick,
                    cellIndex: intent.cellIndex,
                    target: intent.target,
                    resource: intent.resource,
                    status: .succeeded,
                    reason: "pebble-placement:\(actualFingerprint)"
                )
                try candidate.applyPlacementOutcome(outcome)
                if complete && finalCell {
                    try candidate.completeConstructionProject(
                        projectId: intent.projectId,
                        completionTick: candidate.tick
                    )
                }
                if failPublication {
                    throw PebbleAgentConstructionProofError.failed(
                        "injected publication failure"
                    )
                }
                guard candidate.constructionProject?.placedCellIndices.contains(
                    intent.cellIndex
                ) == true else {
                    throw PebbleAgentConstructionProofError.failed(
                        "candidate progress missing"
                    )
                }
            }
        )
        session = candidate
    }

    private func constructionProofIntent(
        project: AgentConstructionProject,
        tick: Int
    ) -> AgentPlacementIntent {
        let cell = project.nextCell!
        return AgentPlacementIntent(
            placementId: "civ18-proof-cell:\(cell.index)",
            projectId: project.projectId,
            builderAgentId: project.builderAgentId,
            tick: tick,
            cellIndex: cell.index,
            target: project.nextTarget!,
            workPosition: project.nextWorkPosition!,
            resource: cell.resource
        )
    }

    private func alignConstructionProofActor(
        session: inout AgentSimulationSession,
        actor: LabCoreAgentEntity,
        position: AgentPosition
    ) throws {
        try session.applyExternalUpdate(AgentExternalUpdate(
            agentId: actor.labAgentId,
            position: position
        ))
        actor.setPos(
            Double(position.x) + 0.5,
            Double(position.y),
            Double(position.z) + 0.5
        )
        actor.prevX = actor.x
        actor.prevY = actor.y
        actor.prevZ = actor.z
    }

    private func expectConstructionFailure(
        _ expected: PebbleAgentConstructionExecutor.ExecutionError,
        operation: () throws -> Void
    ) throws {
        do {
            try operation()
            throw PebbleAgentConstructionProofError.failed(
                "expected \(expected) was accepted"
            )
        } catch let actual as PebbleAgentConstructionExecutor.ExecutionError {
            guard String(describing: actual) == String(describing: expected) else {
                throw PebbleAgentConstructionProofError.failed(
                    "expected \(expected), got \(actual)"
                )
            }
        }
    }

    private func constructionProofFixture(
        world: World,
        actor: LabCoreAgentEntity,
        player: Player
    ) -> PebbleAgentConstructionProofFixture? {
        let actorPosition = AgentPosition(
            x: Int(actor.x.rounded(.down)),
            y: Int(actor.y.rounded(.down)),
            z: Int(actor.z.rounded(.down))
        )
        let occupied = Set(probesByAgentId.values.map {
            AgentPosition(
                x: Int($0.x.rounded(.down)),
                y: Int($0.y.rounded(.down)),
                z: Int($0.z.rounded(.down))
            )
        } + [AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )])
        let offsets = [
            (8, 0), (-8, 0), (0, 8), (0, -8),
            (8, 8), (-8, 8), (8, -8), (-8, -8),
        ]
        for (dx, dz) in offsets {
            let origin = AgentPosition(
                x: actorPosition.x + dx,
                y: actorPosition.y,
                z: actorPosition.z + dz
            )
            let positions = constructionProofPositions(origin: origin)
            let relevantAgents = AgentBlueprint.fixedLeanToV1.cells.flatMap { cell in
                let target = AgentPosition(
                    x: origin.x + cell.relativePosition.x,
                    y: origin.y + cell.relativePosition.y,
                    z: origin.z + cell.relativePosition.z
                )
                let work = AgentPosition(
                    x: origin.x + cell.workOffset.x,
                    y: origin.y + cell.workOffset.y,
                    z: origin.z + cell.workOffset.z
                )
                return [target, work]
            }
            guard occupied.isDisjoint(with: relevantAgents),
                  positions.allSatisfy({
                      world.isChunkReady($0.x >> 4, $0.z >> 4)
                        && world.getBlockEntity($0.x, $0.y, $0.z) == nil
                  }) else { continue }
            return PebbleAgentConstructionProofFixture(
                origin: origin,
                originals: positions.map {
                    ($0, world.getBlock($0.x, $0.y, $0.z))
                }
            )
        }
        return nil
    }

    private func constructionProofPositions(
        origin: AgentPosition
    ) -> [PhysicalBlockPosition] {
        let blueprint = AgentBlueprint.fixedLeanToV1
        var positions: [PhysicalBlockPosition] = []
        func append(_ position: AgentPosition) {
            let physical = PhysicalBlockPosition(
                x: position.x, y: position.y, z: position.z
            )
            if !positions.contains(physical) { positions.append(physical) }
        }
        for x in 0..<blueprint.footprintWidth {
            for z in 0..<blueprint.footprintDepth {
                append(AgentPosition(x: origin.x + x, y: origin.y - 1, z: origin.z + z))
            }
        }
        for cell in blueprint.cells {
            let target = AgentPosition(
                x: origin.x + cell.relativePosition.x,
                y: origin.y + cell.relativePosition.y,
                z: origin.z + cell.relativePosition.z
            )
            let work = AgentPosition(
                x: origin.x + cell.workOffset.x,
                y: origin.y + cell.workOffset.y,
                z: origin.z + cell.workOffset.z
            )
            append(target)
            append(work)
            append(AgentPosition(x: work.x, y: work.y + 1, z: work.z))
            append(AgentPosition(x: work.x, y: work.y - 1, z: work.z))
        }
        let entrance = AgentPosition(
            x: origin.x + blueprint.entranceOffset.x,
            y: origin.y + blueprint.entranceOffset.y,
            z: origin.z + blueprint.entranceOffset.z
        )
        let rest = AgentPosition(
            x: origin.x + blueprint.restOffset.x,
            y: origin.y + blueprint.restOffset.y,
            z: origin.z + blueprint.restOffset.z
        )
        for position in [entrance, rest] {
            append(position)
            append(AgentPosition(x: position.x, y: position.y + 1, z: position.z))
            append(AgentPosition(x: position.x, y: position.y - 1, z: position.z))
        }
        return positions
    }

    private func prepareConstructionProof(
        _ fixture: PebbleAgentConstructionProofFixture,
        world: World
    ) throws {
        let blueprint = AgentBlueprint.fixedLeanToV1
        for original in fixture.originals {
            let isFloor = original.position.y == fixture.origin.y - 1
            _ = world.setBlock(
                original.position.x,
                original.position.y,
                original.position.z,
                isFloor ? Int(cell(B.stone)) : 0,
                SET_SILENT
            )
        }
        let valid = blueprint.cells.allSatisfy { cell in
            let target = AgentPosition(
                x: fixture.origin.x + cell.relativePosition.x,
                y: fixture.origin.y + cell.relativePosition.y,
                z: fixture.origin.z + cell.relativePosition.z
            )
            return world.getBlock(target.x, target.y, target.z) == 0
        } && (0..<blueprint.footprintWidth).allSatisfy { x in
            (0..<blueprint.footprintDepth).allSatisfy { z in
                world.getBlock(
                    fixture.origin.x + x,
                    fixture.origin.y - 1,
                    fixture.origin.z + z
                ) == Int(cell(B.stone))
            }
        }
        try requireConstructionProof(valid, "fixture preparation")
    }

    private func restoreConstructionProof(
        _ fixture: PebbleAgentConstructionProofFixture,
        world: World,
        actor: LabCoreAgentEntity,
        custody: [ItemStack?],
        position: (
            Double, Double, Double, Double, Double, Double, Double, Double
        ),
        entityIDs: [Int]
    ) -> Bool {
        for original in fixture.originals.reversed() {
            _ = world.setBlock(
                original.position.x,
                original.position.y,
                original.position.z,
                original.cell,
                SET_SILENT
            )
        }
        for entity in world.entities where !entityIDs.contains(entity.id) {
            world.removeEntity(entity)
        }
        actor.carriedItems = copyItemInventory(custody)
        actor.setPos(position.0, position.1, position.2)
        actor.prevX = position.3
        actor.prevY = position.4
        actor.prevZ = position.5
        actor.yaw = position.6
        actor.pitch = position.7
        return fixture.originals.allSatisfy {
            world.getBlock($0.position.x, $0.position.y, $0.position.z) == $0.cell
                && world.getBlockEntity($0.position.x, $0.position.y, $0.position.z) == nil
        } && constructionProofSlotsEqual(actor.carriedItems, custody)
            && world.entities.map(\.id).sorted() == entityIDs
    }

    private func constructionProofSlotsEqual(
        _ lhs: [ItemStack?],
        _ rhs: [ItemStack?]
    ) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy { left, right in
            switch (left, right) {
            case (nil, nil): return true
            case let (left?, right?): return left == right
            default: return false
            }
        }
    }

    private func requireConstructionProof(
        _ condition: @autoclosure () throws -> Bool,
        _ label: String
    ) throws {
        guard try condition() else {
            throw PebbleAgentConstructionProofError.failed(label)
        }
    }
}
