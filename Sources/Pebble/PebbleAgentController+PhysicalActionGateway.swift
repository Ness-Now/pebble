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
        guard arguments == ["proof"] else {
            return failure("Usage: /lab gateway proof")
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
                && liveCustodyCount == 0
                && stalePlacement.status == .staleTarget
                && staleCustodyCalls == 0
                && broken.status == .succeeded
                && broken.after == 0
                && repeatedBreak.status == .staleTarget
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
            trace("gateway proof actor=\(actorID) target=\(fixture.target.x),\(fixture.target.y),\(fixture.target.z) invalid=\(invalid.status.rawValue) late=\(late.status.rawValue) rollback=\(lateRollbackVerified ? "verified" : "failed") place=\(placed.status.rawValue) placeStale=\(stalePlacement.status.rawValue) break=\(broken.status.rawValue) breakRepeat=\(repeatedBreak.status.rawValue) session=\(sessionUnchanged ? "unchanged" : "changed") world=\(worldRestored ? "restored" : "dirty") entities=\(world.entities.map(\.id).sorted() == entityIDsBefore ? "unchanged" : "changed") digest=\(digest)")
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
}
