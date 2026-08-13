import Foundation
import PebbleAgents
import PebbleCore

private struct PebbleAgentGatewayProofFixture {
    let target: PhysicalBlockPosition
    let support: PhysicalBlockPosition
    let originalCells: [(position: PhysicalBlockPosition, cell: Int)]
}

extension PebbleAgentController {
    func handlePhysicalActionGateway(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        if arguments.count == 2,
           arguments[0].lowercased() == "proof",
           environment["PEBBLELAB_GATE_D_BLOCKER_10"] == "1" {
            switch arguments[1].lowercased() {
            case "support-safety":
                return proveBlocker10SupportSafety(world: world)
            case "safe-break":
                return proveBlocker10SafeBreak(world: world)
            case "mutation-family-audit":
                return proveBlocker10MutationFamilyAudit(world: world)
            case "evaluation11-mutation-family-audit"
                    where environment["PEBBLELAB_GATE_D_EVALUATION_11"] == "1":
                return proveEvaluation11MutationFamilyComposition(world: world)
            default:
                break
            }
        }
        guard arguments == ["proof"] else {
            return failure(
                "Usage: /lab gateway proof"
                    + " [support-safety|safe-break]"
            )
        }
        let gates = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_INTERACT=1", interactionFeatureEnabled),
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
            return failure("Physical action gateway proof refused; missing gates: \(missing.joined(separator: ", "))")
        }
        guard let session, activeWorld === world else {
            return failure("Physical action gateway proof requires an active session in this World.")
        }
        guard isPaused, !movementEnabled, !autoInteractionEnabled else {
            return failure("Physical action gateway proof requires pause, movement off, and interaction auto off.")
        }
        let actorID = focusedAgentId ?? session.snapshot().agents.first?.id
        guard let actorID, let actor = probesByAgentId[actorID], !actor.dead else {
            return failure("Physical action gateway proof requires a live focused probe.")
        }
        guard let fixture = gatewayProofFixture(
            world: world,
            actor: actor,
            player: player
        ) else {
            return failure("Physical action gateway proof found no bounded adjacent disposable cell.")
        }

        do {
            let sessionBytesBefore = try session.durableStateBytes()
            let entityIDsBefore = world.entities.map(\.id).sorted()
            for original in fixture.originalCells {
                let preparedCell = original.position == fixture.support
                    ? Int(cell(B.stone))
                    : 0
                _ = world.setBlock(
                    original.position.x,
                    original.position.y,
                    original.position.z,
                    preparedCell,
                    SET_SILENT
                )
            }
            guard fixture.originalCells.allSatisfy({ original in
                let expected = original.position == fixture.support
                    ? Int(cell(B.stone))
                    : 0
                return currentGatewayCell(world, original.position) == expected
            }) else {
                _ = restoreGatewayProofFixture(fixture, world: world)
                return failure("Physical action gateway proof fixture preparation failed.")
            }
            let gateway = PebbleAgentPhysicalActionGateway()
            let hit = RaycastHit(
                x: fixture.target.x,
                y: fixture.target.y - 1,
                z: fixture.target.z,
                face: 1,
                cell: Int(cell(B.stone)),
                t: 0,
                px: Double(fixture.target.x) + 0.5,
                py: Double(fixture.target.y),
                pz: Double(fixture.target.z) + 0.5
            )
            let occupied = probesByAgentId.values.map {
                PhysicalBlockPosition(
                    x: Int($0.x.rounded(.down)),
                    y: Int($0.y.rounded(.down)),
                    z: Int($0.z.rounded(.down))
                )
            } + [PhysicalBlockPosition(
                x: Int(player.x.rounded(.down)),
                y: Int(player.y.rounded(.down)),
                z: Int(player.z.rounded(.down))
            )]
            let held = ItemStack(iid("stone"), 1)
            let placementRequest = PebbleAgentBlockPlacementRequest(
                actorID: actorID,
                hit: hit,
                target: fixture.target,
                expectedCell: 0,
                blockID: Int(B.stone),
                heldItem: held,
                orientation: BlockPlacementOrientation(yaw: actor.yaw, pitch: actor.pitch)
            )

            var invalidCustodyCalls = 0
            let invalidRequest = PebbleAgentBlockPlacementRequest(
                actorID: actorID,
                hit: hit,
                target: PhysicalBlockPosition(
                    x: fixture.target.x + 2,
                    y: fixture.target.y,
                    z: fixture.target.z
                ),
                expectedCell: 0,
                blockID: Int(B.stone),
                heldItem: held,
                orientation: BlockPlacementOrientation(yaw: actor.yaw, pitch: actor.pitch)
            )
            let invalid = gateway.placeBlock(
                world: world,
                actor: actor,
                request: invalidRequest,
                custody: PebbleAgentBlockPlacementCustody(
                    consume: { invalidCustodyCalls += $0 },
                    verify: { false },
                    rollback: { false }
                ),
                occupiedPositions: occupied
            )
            let invalidRefusalVerified = invalid.status == .refused
                && invalid.failure == .invalidRequest
                && invalid.mutations.isEmpty
                && invalid.committedEffectCount == 0
                && invalidCustodyCalls == 0
                && currentGatewayCell(world, fixture.target) == 0

            var lateCustodyCount = 1
            let late = gateway.placeBlock(
                world: world,
                actor: actor,
                request: placementRequest,
                custody: PebbleAgentBlockPlacementCustody(
                    consume: { lateCustodyCount -= $0 },
                    verify: { lateCustodyCount == 0 },
                    rollback: {
                        lateCustodyCount = 1
                        return lateCustodyCount == 1
                    }
                ),
                occupiedPositions: occupied,
                verifyAfterMutation: { false }
            )
            let lateRollbackVerified = late.status == .verificationFailure
                && late.failure == .postMutationRejected
                && late.committedEffectCount == 0
                && currentGatewayCell(world, fixture.target) == 0
                && lateCustodyCount == 1
                && world.entities.map(\.id).sorted() == entityIDsBefore

            var liveCustodyCount = 1
            let placed = gateway.placeBlock(
                world: world,
                actor: actor,
                request: placementRequest,
                custody: PebbleAgentBlockPlacementCustody(
                    consume: { liveCustodyCount -= $0 },
                    verify: { liveCustodyCount == 0 },
                    rollback: {
                        liveCustodyCount = 1
                        return liveCustodyCount == 1
                    }
                ),
                occupiedPositions: occupied
            )
            var staleCustodyCalls = 0
            let stalePlacement = gateway.placeBlock(
                world: world,
                actor: actor,
                request: placementRequest,
                custody: PebbleAgentBlockPlacementCustody(
                    consume: { staleCustodyCalls += $0 },
                    verify: { false },
                    rollback: { false }
                ),
                occupiedPositions: occupied
            )
            let breakRequest = PebbleAgentBlockBreakRequest(
                actorID: actorID,
                target: fixture.target,
                expectedCell: Int(cell(B.stone)),
                heldItem: nil,
                isCreative: false
            )
            let broken = gateway.breakBlock(
                world: world,
                actor: actor,
                request: breakRequest,
                occupiedPositions: occupied
            )
            let repeatedBreak = gateway.breakBlock(
                world: world,
                actor: actor,
                request: breakRequest,
                occupiedPositions: occupied
            )

            let actionProofPassed = invalidRefusalVerified
                && lateRollbackVerified
                && placed.status == .succeeded
                && placed.after == Int(cell(B.stone))
                && placed.committedEffectCount == 2
                && liveCustodyCount == 0
                && stalePlacement.status == .staleTarget
                && stalePlacement.committedEffectCount == 0
                && staleCustodyCalls == 0
                && broken.status == .succeeded
                && broken.after == 0
                && broken.committedEffectCount == 3
                && repeatedBreak.status == .staleTarget
                && repeatedBreak.committedEffectCount == 0
            let fixtureRestored = restoreGatewayProofFixture(fixture, world: world)
            let newEntities = world.entities.filter { !entityIDsBefore.contains($0.id) }
            for entity in newEntities {
                world.removeEntity(entity)
            }
            let worldRestored = fixtureRestored
                && world.entities.map(\.id).sorted() == entityIDsBefore
            let sessionUnchanged = try self.session?.durableStateBytes() == sessionBytesBefore
            let proofPassed = actionProofPassed && worldRestored && sessionUnchanged
            let digestInput = [
                actorID,
                "\(fixture.target.x),\(fixture.target.y),\(fixture.target.z)",
                invalid.status.rawValue,
                late.status.rawValue,
                placed.status.rawValue,
                stalePlacement.status.rawValue,
                broken.status.rawValue,
                repeatedBreak.status.rawValue,
                worldRestored ? "world-restored" : "world-dirty",
                sessionUnchanged ? "session-unchanged" : "session-changed",
            ].joined(separator: "|")
            let digest = String(hashString(digestInput), radix: 16)
            trace("gateway proof actor=\(actorID) target=\(fixture.target.x),\(fixture.target.y),\(fixture.target.z) invalid=\(invalid.status.rawValue) late=\(late.status.rawValue) rollback=\(lateRollbackVerified ? "verified" : "failed") effects=\(invalid.committedEffectCount),\(late.committedEffectCount),\(placed.committedEffectCount),\(stalePlacement.committedEffectCount),\(broken.committedEffectCount),\(repeatedBreak.committedEffectCount) place=\(placed.status.rawValue) placeStale=\(stalePlacement.status.rawValue) break=\(broken.status.rawValue) breakRepeat=\(repeatedBreak.status.rawValue) session=\(sessionUnchanged ? "unchanged" : "changed") world=\(worldRestored ? "restored" : "dirty") entities=\(world.entities.map(\.id).sorted() == entityIDsBefore ? "unchanged" : "changed") digest=\(digest)")
            guard proofPassed else {
                return failure("Physical action gateway proof failed; cleanup attempted and verified=\(worldRestored).")
            }
            return success("Physical action gateway proof passed: actor-neutral place/break, stale refusal, late rollback, no Civilization publication, cleanup verified; digest=\(digest).")
        } catch {
            guard restoreGatewayProofFixture(fixture, world: world) else {
                return failure("Physical action gateway proof failed and cleanup could not be verified: \(error)")
            }
            return failure("Physical action gateway proof failed before completion: \(error)")
        }
    }

    private func gatewayProofFixture(
        world: World,
        actor: LabCoreAgentEntity,
        player: Player
    ) -> PebbleAgentGatewayProofFixture? {
        let actorPosition = PhysicalBlockPosition(
            x: Int(actor.x.rounded(.down)),
            y: Int(actor.y.rounded(.down)),
            z: Int(actor.z.rounded(.down))
        )
        let occupied = probesByAgentId.values.map {
            PhysicalBlockPosition(
                x: Int($0.x.rounded(.down)),
                y: Int($0.y.rounded(.down)),
                z: Int($0.z.rounded(.down))
            )
        } + [PhysicalBlockPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )]
        let offsets = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        for (dx, dz) in offsets {
            let target = PhysicalBlockPosition(
                x: actorPosition.x + dx,
                y: actorPosition.y,
                z: actorPosition.z + dz
            )
            let support = PhysicalBlockPosition(
                x: target.x,
                y: target.y - 1,
                z: target.z
            )
            let boundary = [target] + (0..<6).map { index in
                PhysicalBlockPosition(
                    x: target.x + DIR_X[index],
                    y: target.y + DIR_Y[index],
                    z: target.z + DIR_Z[index]
                )
            }
            guard world.isChunkReady(target.x >> 4, target.z >> 4),
                  currentGatewayCell(world, target) == 0,
                  boundary.allSatisfy({ position in
                      world.isChunkReady(position.x >> 4, position.z >> 4)
                          && world.getBlockEntity(position.x, position.y, position.z) == nil
                  }),
                  !occupied.contains(target) else {
                continue
            }
            return PebbleAgentGatewayProofFixture(
                target: target,
                support: support,
                originalCells: boundary.map {
                    ($0, currentGatewayCell(world, $0))
                }
            )
        }
        return nil
    }

    private func restoreGatewayProofFixture(
        _ fixture: PebbleAgentGatewayProofFixture,
        world: World
    ) -> Bool {
        for original in fixture.originalCells.reversed() {
            _ = world.setBlock(
                original.position.x,
                original.position.y,
                original.position.z,
                original.cell,
                SET_SILENT
            )
        }
        return fixture.originalCells.allSatisfy {
            currentGatewayCell(world, $0.position) == $0.cell
        }
    }

    private func currentGatewayCell(
        _ world: World,
        _ position: PhysicalBlockPosition
    ) -> Int {
        world.getBlock(position.x, position.y, position.z)
    }

    /// Disposable Blocker 10 proof fixture. This invokes the same gateway as
    /// live autonomous execution and deliberately targets the exact support
    /// beneath another currently valid probe. It publishes no Civilization
    /// operation; the following checkpoint command independently judges the
    /// resulting physical boundary.
    private func proveBlocker10SupportSafety(
        world: World
    ) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              let published = session, activeWorld === world,
              isPaused, !movementEnabled, !autoInteractionEnabled else {
            return failure("Blocker 10 support proof boundary refused.")
        }
        let probes = probesByAgentId.values.filter {
            $0.world === world && !$0.dead
        }.sorted {
            if $0.labAgentId != $1.labAgentId {
                return $0.labAgentId < $1.labAgentId
            }
            return $0.id < $1.id
        }
        let ignored = Set(probes.map(\.id))
        let pairs = probes.flatMap { actor in
            probes.compactMap { protected -> (
                LabCoreAgentEntity, LabCoreAgentEntity,
                PhysicalBlockPosition, EntityPlacementAssessment
            )? in
                guard actor !== protected else { return nil }
                let actorPosition = PebbleAgentEmbodiment(probe: actor).position
                let protectedPosition = PebbleAgentEmbodiment(
                    probe: protected
                ).position
                let horizontal = abs(actorPosition.x - protectedPosition.x)
                    + abs(actorPosition.z - protectedPosition.z)
                guard horizontal == 1,
                      actorPosition.y == protectedPosition.y else { return nil }
                let placement = assessEntityPlacement(
                    in: world,
                    at: EntityPlacementPosition(
                        x: protectedPosition.x,
                        y: protectedPosition.y,
                        z: protectedPosition.z
                    ),
                    bodyWidth: protected.width,
                    bodyHeight: protected.height,
                    ignoringEntityIDs: ignored
                )
                guard placement.isValid else { return nil }
                return (
                    actor,
                    protected,
                    PhysicalBlockPosition(
                        x: protectedPosition.x,
                        y: protectedPosition.y - 1,
                        z: protectedPosition.z
                    ),
                    placement
                )
            }
        }
        guard let (actor, protected, target, beforePlacement) = pairs.first,
              world.isChunkReady(target.x >> 4, target.z >> 4),
              world.getBlockEntity(target.x, target.y, target.z) == nil else {
            return failure("Blocker 10 proof found no valid adjacent pair.")
        }
        let originalTarget = world.getBlock(target.x, target.y, target.z)
        _ = world.setBlock(
            target.x, target.y, target.z, Int(cell(B.stone)), SET_SILENT
        )
        guard world.getBlock(target.x, target.y, target.z)
                == Int(cell(B.stone)) else {
            return failure("Blocker 10 support fixture preparation failed.")
        }
        if actor.carriedItems.allSatisfy({ $0 == nil }) {
            actor.carriedItems[0] = ItemStack(iid("iron_pickaxe"), 1)
        }
        guard let toolSlot = actor.carriedItems.indices.first(where: {
            actor.carriedItems[$0]?.id == iid("iron_pickaxe")
        }), let binding = materialCustodyGateway.toolBinding(
            actor: actor, slot: toolSlot, world: world
        ) else {
            _ = world.setBlock(
                target.x, target.y, target.z, originalTarget, SET_SILENT
            )
            return failure("Blocker 10 support proof requires a pickaxe.")
        }
        do {
            let sessionBefore = try published.durableStateBytes()
            let rightsBefore = published.materialRightsSnapshot()
            let estatesBefore = published.estateSnapshot()
            let recorderBefore = replayRecorder?.records.count ?? 0
            let inventoryBefore = copyItemInventory(actor.carriedItems)
            let entitiesBefore = Set(world.entities.map(\.id))
            let damageBefore = binding.heldItem.damage
            let outcome = physicalActionGateway.breakBlock(
                world: world,
                actor: actor,
                request: PebbleAgentBlockBreakRequest(
                    actorID: actor.labAgentId,
                    target: target,
                    expectedCell: Int(cell(B.stone)),
                    heldItem: binding.heldItem,
                    isCreative: false
                ),
                toolState: binding.toolState,
                occupiedPositions: probes.map {
                    let position = PebbleAgentEmbodiment(probe: $0).position
                    return PhysicalBlockPosition(
                        x: position.x, y: position.y, z: position.z
                    )
                }
            )
            let afterPlacement = assessEntityPlacement(
                in: world,
                at: beforePlacement.position,
                bodyWidth: protected.width,
                bodyHeight: protected.height,
                ignoringEntityIDs: ignored
            )
            let damageAfter = actor.carriedItems[toolSlot]?.damage ?? -1
            let newEntities = world.entities.filter {
                !entitiesBefore.contains($0.id)
            }
            let itemDrops = newEntities.compactMap { $0 as? ItemEntity }
            let sessionUnchanged = try self.session?.durableStateBytes()
                == sessionBefore
            let rightsUnchanged = self.session?.materialRightsSnapshot()
                == rightsBefore
            let estatesUnchanged = self.session?.estateSnapshot()
                == estatesBefore
            let recorderUnchanged = (replayRecorder?.records.count ?? 0)
                == recorderBefore
            let custodyUnchanged = inventoryEqual(
                actor.carriedItems, inventoryBefore
            )
            let worldCommitted = world.getBlock(
                target.x, target.y, target.z
            ) == 0
            let placementBeforeText = beforePlacement.isValid
                ? "valid" : "invalid"
            let placementAfterText = afterPlacement.isValid
                ? "valid"
                : afterPlacement.rejections.map(\.rawValue)
                    .joined(separator: ",")
            let outcomeText = "outcome=\(outcome.status.rawValue) "
                + "failure=\(outcome.failure?.rawValue ?? "none")"
            let worldText = "world=\(Int(cell(B.stone)))>"
                + "\(world.getBlock(target.x, target.y, target.z)) "
                + "worldMutation=\(worldCommitted ? 1 : 0)"
            let actorText = "toolDamage=\(damageBefore)>\(damageAfter) "
                + "drops=\(itemDrops.count) "
                + "custody=\(custodyUnchanged ? "unchanged" : "changed")"
            let publicationText = "materialRights="
                + (rightsUnchanged ? "unchanged" : "changed")
                + " estate=" + (estatesUnchanged ? "unchanged" : "changed")
                + " session=" + (sessionUnchanged ? "unchanged" : "changed")
                + " recorder="
                + (recorderUnchanged ? "unchanged" : "changed")
            let message = "blocker10 support destructive request "
                + "actor=\(actor.labAgentId) protected=\(protected.labAgentId) "
                + "target=\(target.x),\(target.y),\(target.z) "
                + "beforePlacement=\(placementBeforeText) "
                + outcomeText + " " + worldText + " " + actorText + " "
                + publicationText
                + " protectedPlacementAfter=\(placementAfterText) "
                + "physicalReceipts=0"
            trace(message)
            return success(message)
        } catch {
            return failure("Blocker 10 support proof failed: \(error)")
        }
    }

    /// Positive control for the same gateway: one real nearby block is broken,
    /// tool wear and drop acquisition are physical, and every active probe
    /// remains valid under the canonical PebbleCore placement assessment.
    private func proveBlocker10SafeBreak(
        world: World
    ) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              let published = session, activeWorld === world,
              isPaused, !movementEnabled, !autoInteractionEnabled,
              let actor = probesByAgentId.values.filter({
                  $0.world === world && !$0.dead
                      && $0.carriedItems.contains(where: {
                          $0?.id == iid("iron_pickaxe")
                      })
              }).sorted(by: { $0.labAgentId < $1.labAgentId }).first else {
            return failure("Blocker 10 safe-break proof boundary refused.")
        }
        let probes = probesByAgentId.values.filter {
            $0.world === world && !$0.dead
        }
        let positions = probes.map {
            PebbleAgentEmbodiment(probe: $0).position
        }
        let actorPosition = PebbleAgentEmbodiment(probe: actor).position
        let candidates = [(1, 0), (0, 1), (-1, 0), (0, -1)].map {
            PhysicalBlockPosition(
                x: actorPosition.x + $0.0,
                y: actorPosition.y,
                z: actorPosition.z + $0.1
            )
        }
        guard let target = candidates.first(where: { candidate in
            world.isChunkReady(candidate.x >> 4, candidate.z >> 4)
                && world.getBlockEntity(
                    candidate.x, candidate.y, candidate.z
                ) == nil
                && !positions.contains(where: {
                    ($0.x == candidate.x && $0.y == candidate.y
                        && $0.z == candidate.z)
                        || ($0.x == candidate.x && $0.y - 1 == candidate.y
                            && $0.z == candidate.z)
                })
        }) else {
            return failure("Blocker 10 safe-break found no bounded target.")
        }
        _ = world.setBlock(
            target.x, target.y, target.z, Int(cell(B.stone)), SET_SILENT
        )
        guard let slot = actor.carriedItems.indices.first(where: {
            actor.carriedItems[$0]?.id == iid("iron_pickaxe")
        }), let binding = materialCustodyGateway.toolBinding(
            actor: actor, slot: slot, world: world
        ) else {
            return failure("Blocker 10 safe-break lost its pickaxe.")
        }
        let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            actor, in: world
        )
        do {
            let sessionBefore = try published.durableStateBytes()
            let recorderBefore = replayRecorder?.records.count ?? 0
            let damageBefore = binding.heldItem.damage
            var acquiredQuantity = 0
            let outcome = physicalActionGateway.breakBlock(
                world: world,
                actor: actor,
                request: PebbleAgentBlockBreakRequest(
                    actorID: actor.labAgentId, target: target,
                    expectedCell: Int(cell(B.stone)),
                    heldItem: binding.heldItem, isCreative: false
                ),
                toolState: binding.toolState,
                occupiedPositions: positions.map {
                    PhysicalBlockPosition(x: $0.x, y: $0.y, z: $0.z)
                },
                acquireDrops: { ids in
                    guard let source = PebbleAgentItemEntityCustodyEndpoint(
                        spawnedItemEntityIDs: ids, world: world
                    ), let fingerprint = try? self.materialCustodyGateway
                        .fingerprint(endpoint) else { return false }
                    let result = self.materialCustodyGateway.acquireItemEntities(
                        PebbleAgentItemEntityAcquisitionRequest(
                            transactionID: "gate-d-blocker10-safe-break",
                            spawnedItemEntityIDs: ids,
                            expectedDestinationFingerprint: fingerprint
                        ),
                        from: source, to: endpoint
                    )
                    acquiredQuantity = result.quantityMoved
                    return result.succeeded
                }
            )
            let ignored = Set(probes.map(\.id))
            let placementValid = probes.allSatisfy { probe in
                let position = PebbleAgentEmbodiment(probe: probe).position
                return assessEntityPlacement(
                    in: world,
                    at: EntityPlacementPosition(
                        x: position.x, y: position.y, z: position.z
                    ),
                    bodyWidth: probe.width,
                    bodyHeight: probe.height,
                    ignoringEntityIDs: ignored
                ).isValid
            }
            let damageAfter = actor.carriedItems[slot]?.damage ?? -1
            let sessionUnchanged = try self.session?.durableStateBytes()
                == sessionBefore
            let recorderUnchanged = (replayRecorder?.records.count ?? 0)
                == recorderBefore
            let message = "blocker10 safe physical break "
                + "actor=\(actor.labAgentId) target="
                + "\(target.x),\(target.y),\(target.z) "
                + "outcome=\(outcome.status.rawValue) "
                + "world=\(Int(cell(B.stone)))>"
                + "\(world.getBlock(target.x, target.y, target.z)) "
                + "toolDamage=\(damageBefore)>\(damageAfter) "
                + "dropsAcquired=\(acquiredQuantity) "
                + "activePlacement=\(placementValid ? "valid" : "invalid") "
                + "session=\(sessionUnchanged ? "unchanged" : "changed") "
                + "recorder=\(recorderUnchanged ? "unchanged" : "changed")"
            trace(message)
            guard outcome.succeeded, world.getBlock(
                target.x, target.y, target.z
            ) == 0, damageAfter == damageBefore + 1,
                  acquiredQuantity > 0, placementValid,
                  sessionUnchanged, recorderUnchanged else {
                return failure("Blocker 10 safe-break verification failed.")
            }
            return success(message)
        } catch {
            return failure("Blocker 10 safe-break proof failed: \(error)")
        }
    }

    private func inventoryEqual(
        _ lhs: [ItemStack?],
        _ rhs: [ItemStack?]
    ) -> Bool {
        lhs.elementsEqual(rhs) { left, right in
            switch (left, right) {
            case (nil, nil): return true
            case let (left?, right?): return stacksEqual(left, right)
            default: return false
            }
        }
    }

    /// Audits the sibling mutation families against the same active-probe
    /// boundary. Tilling the support and placing into the upper body are both
    /// real Core mutations before candidate verification, then must compensate
    /// exactly. Direct foot-cell occupancy remains an earlier refusal.
    private func proveBlocker10MutationFamilyAudit(
        world: World
    ) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              let published = session, activeWorld === world,
              isPaused, !movementEnabled, !autoInteractionEnabled else {
            return failure("Blocker 10 mutation-family audit refused.")
        }
        let probes = probesByAgentId.values.filter {
            $0.world === world && !$0.dead
        }.sorted { $0.labAgentId < $1.labAgentId }
        let positions = probes.map {
            PebbleAgentEmbodiment(probe: $0).position
        }
        let pair = probes.flatMap { actor in
            probes.compactMap { protected -> (
                LabCoreAgentEntity, LabCoreAgentEntity
            )? in
                guard actor !== protected else { return nil }
                let a = PebbleAgentEmbodiment(probe: actor).position
                let p = PebbleAgentEmbodiment(probe: protected).position
                return abs(a.x - p.x) + abs(a.z - p.z) == 1
                    && a.y == p.y ? (actor, protected) : nil
            }
        }.first
        guard let (actor, protected) = pair else {
            return failure("Blocker 10 family audit has no adjacent pair.")
        }
        let protectedPosition = PebbleAgentEmbodiment(
            probe: protected
        ).position
        let support = PhysicalBlockPosition(
            x: protectedPosition.x,
            y: protectedPosition.y - 1,
            z: protectedPosition.z
        )
        let upperBody = PhysicalBlockPosition(
            x: protectedPosition.x,
            y: protectedPosition.y + 1,
            z: protectedPosition.z
        )
        let foot = PhysicalBlockPosition(
            x: protectedPosition.x,
            y: protectedPosition.y,
            z: protectedPosition.z
        )
        _ = world.setBlock(
            support.x, support.y, support.z, Int(cell(B.dirt)), SET_SILENT
        )
        _ = world.setBlock(
            upperBody.x, upperBody.y, upperBody.z, 0, SET_SILENT
        )
        _ = world.setBlock(foot.x, foot.y, foot.z, 0, SET_SILENT)
        let pickaxeSlot = actor.carriedItems.indices.first(where: {
            actor.carriedItems[$0]?.id == iid("iron_pickaxe")
        }) ?? 0
        if actor.carriedItems[pickaxeSlot] == nil {
            actor.carriedItems[pickaxeSlot] = ItemStack(
                iid("iron_pickaxe"), 1
            )
        }
        guard let hoeSlot = actor.carriedItems.indices.first(where: {
            actor.carriedItems[$0] == nil
        }) else {
            return failure("Blocker 10 family audit has no hoe slot.")
        }
        actor.carriedItems[hoeSlot] = ItemStack(iid("iron_hoe"), 1)
        guard let blockSlot = actor.carriedItems.indices.first(where: {
            actor.carriedItems[$0] == nil
        }) else {
            return failure("Blocker 10 family audit has no block slot.")
        }
        actor.carriedItems[blockSlot] = ItemStack(iid("stone"), 1)
        let inventoryBefore = copyItemInventory(actor.carriedItems)
        guard let hoe = materialCustodyGateway.toolBinding(
            actor: actor, slot: hoeSlot, world: world
        ), let placement = materialCustodyGateway.placementBinding(
            actor: actor, slot: blockSlot
        ) else {
            return failure("Blocker 10 family bindings are unavailable.")
        }
        let occupied = positions.map {
            PhysicalBlockPosition(x: $0.x, y: $0.y, z: $0.z)
        }
        do {
            let sessionBefore = try published.durableStateBytes()
            let recorderBefore = replayRecorder?.records.count ?? 0
            let entitiesBefore = Set(world.entities.map(\.id))
            let till = physicalActionGateway.tillBlock(
                world: world,
                actor: PebbleAgentEmbodiment(probe: actor),
                request: PebbleAgentBlockTillingRequest(
                    actorID: actor.labAgentId,
                    target: support,
                    expectedCell: Int(cell(B.dirt)),
                    heldItem: hoe.heldItem
                ),
                toolState: hoe.toolState,
                occupiedPositions: occupied
            )
            let hit = RaycastHit(
                x: upperBody.x, y: upperBody.y, z: upperBody.z,
                face: 1, cell: 0, t: 0,
                px: Double(upperBody.x) + 0.5,
                py: Double(upperBody.y) + 0.5,
                pz: Double(upperBody.z) + 0.5
            )
            let placed = physicalActionGateway.placeBlock(
                world: world,
                actor: actor,
                request: PebbleAgentBlockPlacementRequest(
                    actorID: actor.labAgentId,
                    hit: hit,
                    target: upperBody,
                    expectedCell: 0,
                    blockID: Int(B.stone),
                    heldItem: placement.heldItem,
                    orientation: BlockPlacementOrientation(
                        yaw: actor.yaw, pitch: actor.pitch
                    )
                ),
                custody: placement.custody,
                occupiedPositions: occupied
            )
            let occupiedHit = RaycastHit(
                x: foot.x, y: foot.y, z: foot.z,
                face: 1, cell: 0, t: 0,
                px: Double(foot.x) + 0.5,
                py: Double(foot.y) + 0.5,
                pz: Double(foot.z) + 0.5
            )
            let occupiedPlacement = materialCustodyGateway.placementBinding(
                actor: actor, slot: blockSlot
            )
            guard let occupiedPlacement else {
                return failure("Blocker 10 occupied binding disappeared.")
            }
            let direct = physicalActionGateway.placeBlock(
                world: world,
                actor: actor,
                request: PebbleAgentBlockPlacementRequest(
                    actorID: actor.labAgentId,
                    hit: occupiedHit,
                    target: foot,
                    expectedCell: 0,
                    blockID: Int(B.stone),
                    heldItem: occupiedPlacement.heldItem,
                    orientation: BlockPlacementOrientation(
                        yaw: actor.yaw, pitch: actor.pitch
                    )
                ),
                custody: occupiedPlacement.custody,
                occupiedPositions: Array(occupied.reversed())
            )
            let ignored = Set(probes.map(\.id))
            let finalPlacement = assessEntityPlacement(
                in: world,
                at: EntityPlacementPosition(
                    x: protectedPosition.x,
                    y: protectedPosition.y,
                    z: protectedPosition.z
                ),
                bodyWidth: protected.width,
                bodyHeight: protected.height,
                ignoringEntityIDs: ignored
            )
            let sessionAfter = try self.session?.durableStateBytes()
            let exact = till.status == .verificationFailure
                && till.failure == .activeProbePlacementInvalid
                && placed.status == .verificationFailure
                && placed.failure == .activeProbePlacementInvalid
                && direct.status == .refused
                && direct.failure == .occupiedTarget
                && world.getBlock(support.x, support.y, support.z)
                    == Int(cell(B.dirt))
                && world.getBlock(
                    upperBody.x, upperBody.y, upperBody.z
                ) == 0
                && world.getBlock(foot.x, foot.y, foot.z) == 0
                && inventoryEqual(actor.carriedItems, inventoryBefore)
                && Set(world.entities.map(\.id)) == entitiesBefore
                && finalPlacement.isValid
                && sessionAfter == sessionBefore
                && (replayRecorder?.records.count ?? 0) == recorderBefore
            let message = "blocker10 mutation family audit "
                + "till=\(till.status.rawValue):"
                + "\(till.failure?.rawValue ?? "none") "
                + "place=\(placed.status.rawValue):"
                + "\(placed.failure?.rawValue ?? "none") "
                + "directOccupied=\(direct.status.rawValue):"
                + "\(direct.failure?.rawValue ?? "none") "
                + "support=unchanged body=clear tool=unchanged "
                + "custody=unchanged drops=0 placement="
                + (finalPlacement.isValid ? "valid" : "invalid")
                + " enumerationOrder=independent exact=\(exact ? 1 : 0)"
            trace(message)
            guard exact else {
                return failure("Blocker 10 mutation-family audit failed.")
            }
            return success(message)
        } catch {
            return failure("Blocker 10 mutation-family audit failed: \(error)")
        }
    }

    /// Evaluation 11 composes the published adversarial mutation-family audit
    /// with ordinary safe till/place controls, then removes every fixture item
    /// and restores every fixture cell so the main civilization conservation
    /// boundary sees no synthetic material.
    private func proveEvaluation11MutationFamilyComposition(
        world: World
    ) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              environment["PEBBLELAB_GATE_D_EVALUATION_11"] == "1",
              let published = session, activeWorld === world,
              isPaused, !movementEnabled, !autoInteractionEnabled else {
            return failure("Evaluation 11 mutation-family boundary refused.")
        }
        let probes = probesByAgentId.values.filter {
            $0.world === world && !$0.dead
        }.sorted { $0.labAgentId < $1.labAgentId }
        let pair = probes.flatMap { actor in
            probes.compactMap { protected -> (
                LabCoreAgentEntity, LabCoreAgentEntity
            )? in
                guard actor !== protected else { return nil }
                let a = PebbleAgentEmbodiment(probe: actor).position
                let p = PebbleAgentEmbodiment(probe: protected).position
                return abs(a.x - p.x) + abs(a.z - p.z) == 1
                    && a.y == p.y ? (actor, protected) : nil
            }
        }.first
        guard let (actor, protected) = pair else {
            return failure("Evaluation 11 mutation-family has no adjacent pair.")
        }
        let protectedPosition = PebbleAgentEmbodiment(
            probe: protected
        ).position
        let adversarialPositions = [
            PhysicalBlockPosition(
                x: protectedPosition.x,
                y: protectedPosition.y - 1,
                z: protectedPosition.z
            ),
            PhysicalBlockPosition(
                x: protectedPosition.x,
                y: protectedPosition.y + 1,
                z: protectedPosition.z
            ),
            PhysicalBlockPosition(
                x: protectedPosition.x,
                y: protectedPosition.y,
                z: protectedPosition.z
            ),
        ]
        let originalCells = adversarialPositions.map {
            ($0, currentGatewayCell(world, $0))
        }
        let inventoryBefore = copyItemInventory(actor.carriedItems)
        let entitiesBefore = Set(world.entities.map(\.id))
        let recorderBefore = replayRecorder?.records.count ?? 0
        let sessionBefore: Data
        do {
            sessionBefore = try published.durableStateBytes()
        } catch {
            return failure(
                "Evaluation 11 mutation-family session snapshot failed: \(error)"
            )
        }
        let adversarial = proveBlocker10MutationFamilyAudit(world: world)
        actor.carriedItems = copyItemInventory(inventoryBefore)
        for (position, cellValue) in originalCells {
            _ = world.setBlock(
                position.x, position.y, position.z,
                cellValue, SET_SILENT
            )
        }
        for entity in world.entities where !entitiesBefore.contains(entity.id) {
            world.removeEntity(entity)
        }
        let adversarialCleanupExact = adversarial.succeeded
            && inventoryEqual(actor.carriedItems, inventoryBefore)
            && originalCells.allSatisfy {
                currentGatewayCell(world, $0.0) == $0.1
            }
            && Set(world.entities.map(\.id)) == entitiesBefore
        guard adversarialCleanupExact else {
            return failure(
                "Evaluation 11 mutation-family adversarial cleanup failed."
            )
        }

        let actorPosition = PebbleAgentEmbodiment(probe: actor).position
        let occupied = probes.map {
            let position = PebbleAgentEmbodiment(probe: $0).position
            return PhysicalBlockPosition(
                x: position.x, y: position.y, z: position.z
            )
        }
        let occupiedSet = Set(occupied)
        let supports = Set(occupied.map {
            PhysicalBlockPosition(x: $0.x, y: $0.y - 1, z: $0.z)
        })
        let offsets = [
            (1, 0), (0, 1), (-1, 0), (0, -1),
            (2, 0), (0, 2), (-2, 0), (0, -2),
        ]
        guard let safeTillTarget = offsets.map({ dx, dz in
            PhysicalBlockPosition(
                x: actorPosition.x + dx,
                y: actorPosition.y - 1,
                z: actorPosition.z + dz
            )
        }).first(where: { target in
            world.isChunkReady(target.x >> 4, target.z >> 4)
                && world.getBlockEntity(
                    target.x, target.y, target.z
                ) == nil
                && world.getBlockEntity(
                    target.x, target.y + 1, target.z
                ) == nil
                && !supports.contains(target)
                && !occupiedSet.contains(PhysicalBlockPosition(
                    x: target.x, y: target.y + 1, z: target.z
                ))
        }) else {
            return failure("Evaluation 11 has no bounded safe till target.")
        }
        let safeTillAbove = PhysicalBlockPosition(
            x: safeTillTarget.x,
            y: safeTillTarget.y + 1,
            z: safeTillTarget.z
        )
        let tillOriginal = [
            (safeTillTarget, currentGatewayCell(world, safeTillTarget)),
            (safeTillAbove, currentGatewayCell(world, safeTillAbove)),
        ]
        _ = world.setBlock(
            safeTillTarget.x, safeTillTarget.y, safeTillTarget.z,
            Int(cell(B.dirt)), SET_SILENT
        )
        _ = world.setBlock(
            safeTillAbove.x, safeTillAbove.y, safeTillAbove.z,
            0, SET_SILENT
        )
        guard let hoeSlot = actor.carriedItems.indices.first(where: {
            actor.carriedItems[$0] == nil
        }) else {
            return failure("Evaluation 11 has no temporary hoe slot.")
        }
        actor.carriedItems[hoeSlot] = ItemStack(iid("iron_hoe"), 1)
        guard let hoe = materialCustodyGateway.toolBinding(
            actor: actor, slot: hoeSlot, world: world
        ) else {
            actor.carriedItems = copyItemInventory(inventoryBefore)
            for (position, cellValue) in tillOriginal {
                _ = world.setBlock(
                    position.x, position.y, position.z,
                    cellValue, SET_SILENT
                )
            }
            return failure("Evaluation 11 safe till binding unavailable.")
        }
        let safeTill = physicalActionGateway.tillBlock(
            world: world,
            actor: PebbleAgentEmbodiment(probe: actor),
            request: PebbleAgentBlockTillingRequest(
                actorID: actor.labAgentId,
                target: safeTillTarget,
                expectedCell: Int(cell(B.dirt)),
                heldItem: hoe.heldItem
            ),
            toolState: hoe.toolState,
            occupiedPositions: occupied
        )
        let safeTillMutated = safeTill.succeeded
            && safeTill.after >> 4 == Int(B.farmland)
        actor.carriedItems = copyItemInventory(inventoryBefore)
        for (position, cellValue) in tillOriginal {
            _ = world.setBlock(
                position.x, position.y, position.z,
                cellValue, SET_SILENT
            )
        }

        guard let safePlaceTarget = offsets.map({ dx, dz in
            PhysicalBlockPosition(
                x: actorPosition.x + dx,
                y: actorPosition.y,
                z: actorPosition.z + dz
            )
        }).first(where: { target in
            let support = PhysicalBlockPosition(
                x: target.x, y: target.y - 1, z: target.z
            )
            return target != safeTillAbove
                && world.isChunkReady(target.x >> 4, target.z >> 4)
                && world.getBlockEntity(
                    target.x, target.y, target.z
                ) == nil
                && world.getBlockEntity(
                    support.x, support.y, support.z
                ) == nil
                && !occupiedSet.contains(target)
                && !supports.contains(target)
                && !supports.contains(support)
        }) else {
            return failure("Evaluation 11 has no bounded safe place target.")
        }
        let safePlaceSupport = PhysicalBlockPosition(
            x: safePlaceTarget.x,
            y: safePlaceTarget.y - 1,
            z: safePlaceTarget.z
        )
        let placeOriginal = [
            (safePlaceTarget, currentGatewayCell(world, safePlaceTarget)),
            (safePlaceSupport, currentGatewayCell(world, safePlaceSupport)),
        ]
        _ = world.setBlock(
            safePlaceSupport.x, safePlaceSupport.y, safePlaceSupport.z,
            Int(cell(B.stone)), SET_SILENT
        )
        _ = world.setBlock(
            safePlaceTarget.x, safePlaceTarget.y, safePlaceTarget.z,
            0, SET_SILENT
        )
        guard let blockSlot = actor.carriedItems.indices.first(where: {
            actor.carriedItems[$0] == nil
        }) else {
            return failure("Evaluation 11 has no temporary block slot.")
        }
        actor.carriedItems[blockSlot] = ItemStack(iid("stone"), 1)
        guard let placement = materialCustodyGateway.placementBinding(
            actor: actor, slot: blockSlot
        ) else {
            return failure("Evaluation 11 safe placement binding unavailable.")
        }
        let hit = RaycastHit(
            x: safePlaceTarget.x,
            y: safePlaceSupport.y,
            z: safePlaceTarget.z,
            face: 1,
            cell: Int(cell(B.stone)),
            t: 0,
            px: Double(safePlaceTarget.x) + 0.5,
            py: Double(safePlaceTarget.y),
            pz: Double(safePlaceTarget.z) + 0.5
        )
        let safePlace = physicalActionGateway.placeBlock(
            world: world,
            actor: actor,
            request: PebbleAgentBlockPlacementRequest(
                actorID: actor.labAgentId,
                hit: hit,
                target: safePlaceTarget,
                expectedCell: 0,
                blockID: Int(B.stone),
                heldItem: placement.heldItem,
                orientation: BlockPlacementOrientation(
                    yaw: actor.yaw, pitch: actor.pitch
                )
            ),
            custody: placement.custody,
            occupiedPositions: Array(occupied.reversed())
        )
        let safePlaceMutated = safePlace.succeeded
            && safePlace.after >> 4 == Int(B.stone)
        actor.carriedItems = copyItemInventory(inventoryBefore)
        for (position, cellValue) in placeOriginal {
            _ = world.setBlock(
                position.x, position.y, position.z,
                cellValue, SET_SILENT
            )
        }
        for entity in world.entities where !entitiesBefore.contains(entity.id) {
            world.removeEntity(entity)
        }
        let finalPlacement = probes.allSatisfy { probe in
            let position = PebbleAgentEmbodiment(probe: probe).position
            return assessEntityPlacement(
                in: world,
                at: EntityPlacementPosition(
                    x: position.x, y: position.y, z: position.z
                ),
                bodyWidth: probe.width,
                bodyHeight: probe.height,
                ignoringEntityIDs: Set(probes.map(\.id))
            ).isValid
        }
        let sessionExact: Bool
        do {
            sessionExact = try self.session?.durableStateBytes()
                == sessionBefore
        } catch {
            return failure(
                "Evaluation 11 mutation-family final snapshot failed: \(error)"
            )
        }
        let safeCleanupExact = inventoryEqual(
            actor.carriedItems, inventoryBefore
        )
            && tillOriginal.allSatisfy {
                currentGatewayCell(world, $0.0) == $0.1
            }
            && placeOriginal.allSatisfy {
                currentGatewayCell(world, $0.0) == $0.1
            }
            && Set(world.entities.map(\.id)) == entitiesBefore
            && sessionExact
            && (replayRecorder?.records.count ?? 0) == recorderBefore
            && finalPlacement
        let exact = adversarialCleanupExact
            && safeTillMutated
            && safePlaceMutated
            && safeCleanupExact
        let message = "evaluation11 blocker10 mutation family composition "
            + "adversarialTill=verificationFailure:activeProbePlacementInvalid "
            + "adversarialPlace=verificationFailure:activeProbePlacementInvalid "
            + "directOccupied=refused:occupiedTarget "
            + "safeTill=\(safeTill.status.rawValue) "
            + "safePlace=\(safePlace.status.rawValue) "
            + "enumerationOrder=independent adversarialCleanup="
            + (adversarialCleanupExact ? "exact" : "failed")
            + " safeCleanup=" + (safeCleanupExact ? "exact" : "failed")
            + " activePlacement=" + (finalPlacement ? "valid" : "invalid")
            + " syntheticMaterial=0 exact=\(exact ? 1 : 0)"
        trace(message)
        guard exact else {
            return failure("Evaluation 11 mutation-family composition failed.")
        }
        return success(message)
    }
}
