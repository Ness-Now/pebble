import Foundation
import PebbleAgents
import PebbleCore

private struct PebbleAgentHarvestProofFixture {
    let target: PhysicalBlockPosition
    let originals: [(position: PhysicalBlockPosition, cell: Int)]
}

private struct PebbleAgentHarvestProofRun {
    let digest: String
    let logDrop: String
    let stoneDrop: String
    let axeDamage: Int
    let pickaxeDamage: Int
    let practiceDelta: Int
}

extension PebbleAgentController {
    func handleHarvestConvergence(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        guard arguments == ["proof"] else {
            return failure("Usage: /lab harvest proof")
        }
        let gates = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_INTERACT=1", interactionFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_NATURAL=1", naturalFeatureEnabled),
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
                "Harvest convergence proof refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard let published = session, activeWorld === world,
              published.skillsEnabled else {
            return failure(
                "Harvest convergence proof requires an active skill-enabled session."
            )
        }
        guard isPaused, !movementEnabled, !autoInteractionEnabled,
              !economyAutoEnabled else {
            return failure(
                "Harvest convergence proof requires pause, movement off, and auto modes off."
            )
        }
        let actorID = focusedAgentId ?? published.snapshot().agents.first?.id
        guard let actorID, let actor = probesByAgentId[actorID], !actor.dead else {
            return failure("Harvest convergence proof requires a live focused probe.")
        }
        guard let fixture = harvestProofFixture(
            world: world,
            actor: actor,
            player: player
        ) else {
            return failure("Harvest convergence proof found no bounded adjacent cell.")
        }

        let originalCustody = copyItemInventory(actor.carriedItems)
        let originalEntityIDs = world.entities.map(\.id).sorted()
        let originalExecutor = naturalResourceExecutor
        do {
            let sessionBytes = try published.durableStateBytes()
            let first = try runHarvestProof(
                baseSession: published,
                actorID: actorID,
                actor: actor,
                fixture: fixture,
                world: world,
                player: player,
                originalCustody: originalCustody,
                originalEntityIDs: originalEntityIDs
            )
            let firstCleanup = restoreHarvestProof(
                fixture,
                world: world,
                actor: actor,
                custody: originalCustody,
                entityIDs: originalEntityIDs
            )
            guard firstCleanup else {
                throw ControllerError.interactionBoundary(
                    "harvest proof first-run cleanup failed"
                )
            }
            let second = try runHarvestProof(
                baseSession: published,
                actorID: actorID,
                actor: actor,
                fixture: fixture,
                world: world,
                player: player,
                originalCustody: originalCustody,
                originalEntityIDs: originalEntityIDs
            )
            let finalCleanup = restoreHarvestProof(
                fixture,
                world: world,
                actor: actor,
                custody: originalCustody,
                entityIDs: originalEntityIDs
            )
            materialCustodyGateway.reset()
            naturalResourceExecutor = originalExecutor
            let sessionUnchanged = try session?.durableStateBytes() == sessionBytes
            guard finalCleanup, sessionUnchanged, first.digest == second.digest else {
                throw ControllerError.interactionBoundary(
                    "harvest proof determinism or cleanup mismatch"
                )
            }
            trace(
                "harvest proof actor=\(actorID) log=\(first.logDrop) "
                    + "stone=\(first.stoneDrop) axeDamage=\(first.axeDamage) "
                    + "pickaxeDamage=\(first.pickaxeDamage) custody=real "
                    + "unrelated=preserved capacityRollback=exact lateRollback=exact "
                    + "wrongToolRollback=exact stale=refused duplicate=refused "
                    + "abstractCredit=0 campStockCredit=0 causal=2 "
                    + "practiceDelta=\(first.practiceDelta) session=unchanged "
                    + "cleanup=exact runs=2 digest=\(first.digest)"
            )
            return success(
                "Harvest convergence proof passed twice: canonical log/stone drops, "
                    + "real custody/tools, exact failures, no ghost credit; "
                    + "digest=\(first.digest)."
            )
        } catch {
            let restored = restoreHarvestProof(
                fixture,
                world: world,
                actor: actor,
                custody: originalCustody,
                entityIDs: originalEntityIDs
            )
            materialCustodyGateway.reset()
            naturalResourceExecutor = originalExecutor
            return failure(
                "Harvest convergence proof failed: \(error); cleanup="
                    + (restored ? "exact" : "failed")
            )
        }
    }

    private func runHarvestProof(
        baseSession: AgentSimulationSession,
        actorID: String,
        actor: LabCoreAgentEntity,
        fixture: PebbleAgentHarvestProofFixture,
        world: World,
        player: Player,
        originalCustody: [ItemStack?],
        originalEntityIDs: [Int]
    ) throws -> PebbleAgentHarvestProofRun {
        materialCustodyGateway.reset()
        resetGameRng(0xC117)
        guard prepareHarvestFixture(fixture, world: world, targetCell: Int(cell(B.oak_log))) else {
            throw ControllerError.interactionBoundary("log fixture preparation failed")
        }
        actor.carriedItems = Array(
            repeating: nil,
            count: LabCoreAgentEntity.carriedItemSlotCount
        )
        actor.carriedItems[0] = ItemStack(iid("iron_axe"), 1)
        actor.carriedItems[1] = ItemStack(iid("iron_pickaxe"), 1)
        let unrelated = spawnItem(
            world,
            Double(fixture.target.x) + 0.5,
            Double(fixture.target.y) + 0.3,
            Double(fixture.target.z) + 0.5,
            ItemStack(iid("dirt"), 7)
        )
        let unrelatedBefore = unrelated.stack.copy()

        var candidate = baseSession
        candidate.setEconomyEnabled(true)
        candidate.setNaturalResourcesEnabled(true)
        let sessionBefore = candidate.snapshot()
        let actorAgentID = AgentID(rawValue: actorID)!
        let practiceBefore = candidate.practiceUnits(
            agentID: actorAgentID,
            domain: .foraging
        )
        let causalBefore = candidate.causalLedgerSnapshot().events.filter {
            $0.kind == .interaction
        }.count
        var recorder: AgentReplayRecorder?

        let logIdentity = try lockHarvestTarget(
            session: &candidate,
            actorID: actorID,
            target: fixture.target,
            resource: .wood,
            fingerprint: Int(cell(B.oak_log))
        )
        let logActor = candidate.snapshot().agents.first { $0.id == actorID }!
        let logOutcome = try performNaturalHarvestTransaction(
            world: world,
            player: player,
            actor: logActor,
            identity: logIdentity,
            interactionPrefix: "civ17-log",
            session: &candidate,
            recorder: &recorder
        )
        guard logOutcome.status == .succeeded,
              world.getBlock(
                fixture.target.x,
                fixture.target.y,
                fixture.target.z
              ) == 0,
              actor.carriedItems[0]?.damage == 1,
              actor.carriedItems.contains(where: {
                $0.map { itemDef($0.id).name == "oak_log" && $0.count == 1 } ?? false
              }),
              world.entities.contains(where: { $0 === unrelated }),
              unrelated.stack == unrelatedBefore else {
            throw ControllerError.interactionBoundary("canonical log harvest mismatch")
        }

        guard prepareHarvestFixture(
            fixture,
            world: world,
            targetCell: Int(cell(B.stone))
        ) else {
            throw ControllerError.interactionBoundary("stone fixture preparation failed")
        }
        let stoneIdentity = try lockHarvestTarget(
            session: &candidate,
            actorID: actorID,
            target: fixture.target,
            resource: .stone,
            fingerprint: Int(cell(B.stone))
        )
        let stoneActor = candidate.snapshot().agents.first { $0.id == actorID }!
        let stoneOutcome = try performNaturalHarvestTransaction(
            world: world,
            player: player,
            actor: stoneActor,
            identity: stoneIdentity,
            interactionPrefix: "civ17-stone",
            session: &candidate,
            recorder: &recorder
        )
        let custody = try materialCustodyGateway.inspect(
            .liveAgent(actor, in: world)
        )
        guard stoneOutcome.status == .succeeded,
              actor.carriedItems[1]?.damage == 1,
              custody.slots.compactMap({ $0 }).contains(where: {
                $0.identity.itemKey == "cobblestone" && $0.count == 1
              }),
              world.entities.contains(where: { $0 === unrelated }),
              unrelated.stack == unrelatedBefore else {
            throw ControllerError.interactionBoundary("canonical stone harvest mismatch")
        }

        let afterSuccess = candidate.snapshot()
        let successInteractions = candidate.causalLedgerSnapshot().events.filter {
            $0.kind == .interaction
        }.count - causalBefore
        let practiceDelta = candidate.practiceUnits(
            agentID: actorAgentID,
            domain: .foraging
        ) - practiceBefore
        guard afterSuccess.agents.first(where: { $0.id == actorID })?.resourceInventory
                == sessionBefore.agents.first(where: { $0.id == actorID })?.resourceInventory,
              afterSuccess.campStock == sessionBefore.campStock,
              afterSuccess.conservation == sessionBefore.conservation,
              successInteractions == 2,
              practiceDelta == 2 else {
            throw ControllerError.interactionBoundary("ghost credit or publication mismatch")
        }

        let successCustody = copyItemInventory(actor.carriedItems)
        let successSessionBytes = try candidate.durableStateBytes()
        let failureEntityIDs = world.entities.map(\.id).sorted()
        let stale = physicalActionGateway.breakBlock(
            world: world,
            actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: actorID,
                target: fixture.target,
                expectedCell: Int(cell(B.stone)),
                heldItem: actor.carriedItems[1]?.copy(),
                isCreative: false
            ),
            occupiedPositions: []
        )
        guard stale.status == .staleTarget,
              exactHarvestSlots(actor.carriedItems, successCustody),
              world.entities.map(\.id).sorted() == failureEntityIDs else {
            throw ControllerError.interactionBoundary("duplicate presentation mutated state")
        }

        guard prepareHarvestFixture(
            fixture,
            world: world,
            targetCell: Int(cell(B.stone))
        ) else { throw ControllerError.interactionBoundary("failure fixture failed") }
        let staleFingerprint = physicalActionGateway.breakBlock(
            world: world,
            actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: actorID,
                target: fixture.target,
                expectedCell: Int(cell(B.oak_log)),
                heldItem: actor.carriedItems[0]?.copy(),
                isCreative: false
            ),
            occupiedPositions: []
        )
        guard staleFingerprint.status == .staleTarget,
              world.getBlock(
                fixture.target.x,
                fixture.target.y,
                fixture.target.z
              ) == Int(cell(B.stone)) else {
            throw ControllerError.interactionBoundary("stale fingerprint was not refused")
        }

        let invalidTarget = PhysicalBlockPosition(
            x: fixture.target.x + (fixture.target.x >= Int(actor.x.rounded(.down)) ? 1 : -1),
            y: fixture.target.y,
            z: fixture.target.z
        )
        let invalidOriginal = world.getBlock(
            invalidTarget.x,
            invalidTarget.y,
            invalidTarget.z
        )
        _ = world.setBlock(
            invalidTarget.x,
            invalidTarget.y,
            invalidTarget.z,
            Int(cell(B.stone)),
            SET_SILENT
        )
        let invalid = physicalActionGateway.breakBlock(
            world: world,
            actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: actorID,
                target: invalidTarget,
                expectedCell: Int(cell(B.stone)),
                heldItem: actor.carriedItems[1]?.copy(),
                isCreative: false
            ),
            occupiedPositions: []
        )
        _ = world.setBlock(
            invalidTarget.x,
            invalidTarget.y,
            invalidTarget.z,
            invalidOriginal,
            SET_SILENT
        )
        guard invalid.status == .refused, invalid.failure == .outOfReach else {
            throw ControllerError.interactionBoundary("invalid target was not refused")
        }

        actor.carriedItems = Array(
            repeating: nil,
            count: LabCoreAgentEntity.carriedItemSlotCount
        )
        let noToolBefore = copyItemInventory(actor.carriedItems)
        let beforeWrongEntities = world.entities.map(\.id).sorted()
        let wrongTool = physicalActionGateway.breakBlock(
            world: world,
            actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: actorID,
                target: fixture.target,
                expectedCell: Int(cell(B.stone)),
                heldItem: nil,
                isCreative: false
            ),
            occupiedPositions: [],
            acquireDrops: { !$0.isEmpty }
        )
        guard wrongTool.status == .verificationFailure,
              wrongTool.committedEffectCount == 0,
              world.getBlock(
                fixture.target.x,
                fixture.target.y,
                fixture.target.z
              ) == Int(cell(B.stone)),
              exactHarvestSlots(actor.carriedItems, noToolBefore),
              world.entities.map(\.id).sorted() == beforeWrongEntities else {
            throw ControllerError.interactionBoundary("wrong-tool rollback mismatch")
        }

        actor.carriedItems[0] = ItemStack(iid("iron_pickaxe"), 1)
        for slot in 1..<LabCoreAgentEntity.carriedItemSlotCount {
            actor.carriedItems[slot] = ItemStack(iid("dirt"), 64)
        }
        let capacityBefore = copyItemInventory(actor.carriedItems)
        let capacityEntities = world.entities.map(\.id).sorted()
        let capacityBinding = materialCustodyGateway.harvestToolBinding(
            actor: actor,
            targetCell: Int(cell(B.stone)),
            world: world
        )!
        var capacityAcquisition: PebbleAgentItemEntityAcquisitionOutcome?
        let capacity = physicalActionGateway.breakBlock(
            world: world,
            actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: actorID,
                target: fixture.target,
                expectedCell: Int(cell(B.stone)),
                heldItem: capacityBinding.heldItem,
                isCreative: false
            ),
            toolState: capacityBinding.toolState,
            occupiedPositions: [],
            acquireDrops: { ids in
                guard let source = PebbleAgentItemEntityCustodyEndpoint(
                    spawnedItemEntityIDs: ids,
                    world: world
                ) else { return false }
                let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
                let result = materialCustodyGateway.acquireItemEntities(
                    PebbleAgentItemEntityAcquisitionRequest(
                        transactionID: "civ17-capacity",
                        spawnedItemEntityIDs: ids,
                        expectedDestinationFingerprint: try! materialCustodyGateway.fingerprint(destination)
                    ),
                    from: source,
                    to: destination
                )
                capacityAcquisition = result
                return result.succeeded
            }
        )
        guard capacity.status == .verificationFailure,
              capacityAcquisition?.status == .destinationFull,
              capacity.committedEffectCount == 0,
              exactHarvestSlots(actor.carriedItems, capacityBefore),
              world.entities.map(\.id).sorted() == capacityEntities,
              world.getBlock(
                fixture.target.x,
                fixture.target.y,
                fixture.target.z
              ) == Int(cell(B.stone)) else {
            throw ControllerError.interactionBoundary("capacity rollback mismatch")
        }

        actor.carriedItems = Array(
            repeating: nil,
            count: LabCoreAgentEntity.carriedItemSlotCount
        )
        actor.carriedItems[0] = ItemStack(iid("iron_pickaxe"), 1)
        let lateBefore = copyItemInventory(actor.carriedItems)
        let lateEntities = world.entities.map(\.id).sorted()
        let lateBinding = materialCustodyGateway.harvestToolBinding(
            actor: actor,
            targetCell: Int(cell(B.stone)),
            world: world
        )!
        var lateAcquisition: PebbleAgentItemEntityAcquisitionOutcome?
        let late = physicalActionGateway.breakBlock(
            world: world,
            actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: actorID,
                target: fixture.target,
                expectedCell: Int(cell(B.stone)),
                heldItem: lateBinding.heldItem,
                isCreative: false
            ),
            toolState: lateBinding.toolState,
            occupiedPositions: [],
            acquireDrops: { ids in
                guard let source = PebbleAgentItemEntityCustodyEndpoint(
                    spawnedItemEntityIDs: ids,
                    world: world
                ) else { return false }
                let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
                let result = materialCustodyGateway.acquireItemEntities(
                    PebbleAgentItemEntityAcquisitionRequest(
                        transactionID: "civ17-late",
                        spawnedItemEntityIDs: ids,
                        expectedDestinationFingerprint: try! materialCustodyGateway.fingerprint(destination)
                    ),
                    from: source,
                    to: destination,
                    verifyAfterMutation: { _ in false }
                )
                lateAcquisition = result
                return result.succeeded
            }
        )
        guard late.status == .verificationFailure,
              lateAcquisition?.status == .verificationFailure,
              late.committedEffectCount == 0,
              exactHarvestSlots(actor.carriedItems, lateBefore),
              world.entities.map(\.id).sorted() == lateEntities,
              world.getBlock(
                fixture.target.x,
                fixture.target.y,
                fixture.target.z
              ) == Int(cell(B.stone)),
              try candidate.durableStateBytes() == successSessionBytes,
              world.entities.contains(where: { $0 === unrelated }),
              unrelated.stack == unrelatedBefore else {
            throw ControllerError.interactionBoundary("late rollback mismatch")
        }

        actor.carriedItems = copyItemInventory(successCustody)
        let custodyFingerprint = try materialCustodyGateway.fingerprint(
            .liveAgent(actor, in: world)
        )
        let sessionDigest = AgentCheckpointDigest.sha256(successSessionBytes).rawValue
        let digest = String(hashString([
            "seed=0xC117",
            "log=oak_logx1",
            "stone=cobblestonex1",
            "axe=1",
            "pickaxe=1",
            "practice=\(practiceDelta)",
            "causal=\(successInteractions)",
            "custody=\(custodyFingerprint)",
            "session=\(sessionDigest)",
        ].joined(separator: "|")), radix: 16)
        guard restoreHarvestProof(
            fixture,
            world: world,
            actor: actor,
            custody: originalCustody,
            entityIDs: originalEntityIDs
        ) else {
            throw ControllerError.interactionBoundary("run cleanup mismatch")
        }
        return PebbleAgentHarvestProofRun(
            digest: digest,
            logDrop: "oak_logx1",
            stoneDrop: "cobblestonex1",
            axeDamage: 1,
            pickaxeDamage: 1,
            practiceDelta: practiceDelta
        )
    }

    private func lockHarvestTarget(
        session: inout AgentSimulationSession,
        actorID: String,
        target: PhysicalBlockPosition,
        resource: AgentResourceKind,
        fingerprint: Int
    ) throws -> AgentResourceIdentity {
        let actor = session.snapshot().agents.first { $0.id == actorID }!
        let position = AgentPosition(x: target.x, y: target.y, z: target.z)
        let direction = AgentResourcePerception.direction(
            observerPosition: actor.position,
            target: position
        )!
        _ = try session.advanceTick(perceptions: [AgentPerceptionInput(
            agentId: actorID,
            resourceObservations: [AgentResourceObservation(
                resource: resource,
                target: position,
                direction: direction,
                distanceManhattan: 1,
                quantityAvailable: 1,
                source: .naturalWorld,
                expectedBlockFingerprint: fingerprint
            )]
        )])
        guard let locked = session.snapshot().agents.first(where: {
            $0.id == actorID
        })?.activeResourceTarget?.identity,
              locked.position == position,
              locked.resource == resource,
              locked.expectedBlockFingerprint == fingerprint else {
            throw ControllerError.interactionBoundary("NaturalResource target lock failed")
        }
        return locked
    }

    private func harvestProofFixture(
        world: World,
        actor: LabCoreAgentEntity,
        player: Player
    ) -> PebbleAgentHarvestProofFixture? {
        let origin = PhysicalBlockPosition(
            x: Int(actor.x.rounded(.down)),
            y: Int(actor.y.rounded(.down)),
            z: Int(actor.z.rounded(.down))
        )
        let occupied = Set(probesByAgentId.values.map {
            PhysicalBlockPosition(
                x: Int($0.x.rounded(.down)),
                y: Int($0.y.rounded(.down)),
                z: Int($0.z.rounded(.down))
            )
        } + [PhysicalBlockPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )])
        for (dx, dz) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
            let target = PhysicalBlockPosition(
                x: origin.x + dx,
                y: origin.y,
                z: origin.z + dz
            )
            let boundary = [target] + (0..<6).map { index in
                PhysicalBlockPosition(
                    x: target.x + DIR_X[index],
                    y: target.y + DIR_Y[index],
                    z: target.z + DIR_Z[index]
                )
            }
            guard !occupied.contains(target),
                  boundary.allSatisfy({ position in
                    world.isChunkReady(position.x >> 4, position.z >> 4)
                        && world.getBlockEntity(position.x, position.y, position.z) == nil
                  }) else { continue }
            return PebbleAgentHarvestProofFixture(
                target: target,
                originals: boundary.map {
                    ($0, world.getBlock($0.x, $0.y, $0.z))
                }
            )
        }
        return nil
    }

    private func prepareHarvestFixture(
        _ fixture: PebbleAgentHarvestProofFixture,
        world: World,
        targetCell: Int
    ) -> Bool {
        for original in fixture.originals {
            let isTarget = original.position == fixture.target
            let isSupport = original.position == PhysicalBlockPosition(
                x: fixture.target.x,
                y: fixture.target.y - 1,
                z: fixture.target.z
            )
            _ = world.setBlock(
                original.position.x,
                original.position.y,
                original.position.z,
                isTarget ? targetCell : isSupport ? Int(cell(B.stone)) : 0,
                SET_SILENT
            )
        }
        return fixture.originals.allSatisfy { original in
            let expected: Int
            if original.position == fixture.target {
                expected = targetCell
            } else if original.position == PhysicalBlockPosition(
                x: fixture.target.x,
                y: fixture.target.y - 1,
                z: fixture.target.z
            ) {
                expected = Int(cell(B.stone))
            } else {
                expected = 0
            }
            return world.getBlock(
                original.position.x,
                original.position.y,
                original.position.z
            ) == expected
        }
    }

    private func restoreHarvestProof(
        _ fixture: PebbleAgentHarvestProofFixture,
        world: World,
        actor: LabCoreAgentEntity,
        custody: [ItemStack?],
        entityIDs: [Int]
    ) -> Bool {
        let retained = Set(entityIDs)
        let created = world.entities.filter { !retained.contains($0.id) }
        for entity in created {
            world.removeEntity(entity)
        }
        for original in fixture.originals.reversed() {
            _ = world.setBlock(
                original.position.x,
                original.position.y,
                original.position.z,
                original.cell,
                SET_SILENT
            )
        }
        actor.carriedItems = copyItemInventory(custody)
        return world.entities.map(\.id).sorted() == entityIDs
            && fixture.originals.allSatisfy {
                world.getBlock($0.position.x, $0.position.y, $0.position.z)
                    == $0.cell
            }
            && exactHarvestSlots(actor.carriedItems, custody)
    }

    private func exactHarvestSlots(
        _ lhs: [ItemStack?],
        _ rhs: [ItemStack?]
    ) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { left, right in
            switch (left, right) {
            case (nil, nil): return true
            case let (left?, right?): return left == right
            default: return false
            }
        }
    }
}
