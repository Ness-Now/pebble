import Foundation
import PebbleAgents
import PebbleCore

private struct PebbleAgentMaterialProofFixture {
    let target: PhysicalBlockPosition
    let support: PhysicalBlockPosition
    let container: PhysicalBlockPosition
    let originalCells: [(position: PhysicalBlockPosition, cell: Int)]
}

private enum PebbleAgentMaterialProofError: Error {
    case failed(String)
}

extension PebbleAgentController {
    func handleMaterialCustody(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        guard arguments == ["proof"] else {
            return failure("Usage: /lab material proof")
        }
        let gates = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_INTERACT=1", interactionFeatureEnabled),
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
            return failure("Material custody proof refused; missing gates: \(missing.joined(separator: ", "))")
        }
        guard let session, activeWorld === world else {
            return failure("Material custody proof requires an active session in this World.")
        }
        guard isPaused, !movementEnabled, !autoInteractionEnabled else {
            return failure("Material custody proof requires pause, movement off, and interaction auto off.")
        }
        let actorID = focusedAgentId ?? session.snapshot().agents.first?.id
        guard let actorID, let actor = probesByAgentId[actorID], !actor.dead,
              actor.carriedItems.allSatisfy({ $0 == nil }) else {
            return failure("Material custody proof requires a live focused probe with empty proof custody.")
        }
        guard let fixture = materialProofFixture(world: world, actor: actor, player: player) else {
            return failure("Material custody proof found no bounded disposable cells.")
        }

        let entityIDsBefore = world.entities.map(\.id).sorted()
        var proofContainer: BlockEntityData?
        var cleanupVerified = false
        do {
            let durableBefore = try session.durableStateBytes()
            let campStockBefore = session.snapshot().campStock
            try prepareMaterialProofFixture(fixture, world: world)
            let container = makeContainerBE(
                fixture.container.x,
                fixture.container.y,
                fixture.container.z,
                27
            )
            world.setBlockEntity(container)
            proofContainer = container
            try requireMaterialProof(
                world.getBlockEntity(
                    fixture.container.x,
                    fixture.container.y,
                    fixture.container.z
                ) === container,
                "real container installation"
            )

            // Explicit proof fixture provenance only. These real stacks are not
            // session state and are cleared before the command returns.
            actor.carriedItems[0] = ItemStack(iid("cobblestone"), 10)
            actor.carriedItems[1] = ItemStack(iid("stone"), 2)
            actor.carriedItems[2] = ItemStack(iid("iron_pickaxe"), 1)
            actor.carriedItems[3] = ItemStack(iid("hay_block"), 3)
            materialCustodyGateway.reset()
            let bridge = PebbleAgentMaterialSnapshotBridge()
            let agentEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
            let containerEndpoint = PebbleAgentMaterialCustodyEndpoint.container(container, in: world)

            let simpleA = try bridge.snapshot(of: ItemStack(iid("cobblestone"), 4))
            let simpleB = try bridge.snapshot(of: ItemStack(iid("cobblestone"), 4))
            var potionData = StackData()
            potionData.potion = "healing"
            potionData.lodestone = [4, 70, -8, 0]
            let richPhysical = ItemStack(
                iid("potion"),
                1,
                ench: [EnchInstance("unbreaking", 1)],
                label: "proof",
                data: potionData
            )
            let richSnapshot = try bridge.snapshot(of: richPhysical)
            let richRoundTrip = try bridge.itemStack(from: richSnapshot)
            let unknown = AgentMaterialStackSnapshot(
                identity: AgentMaterialIdentitySnapshot(
                    itemKey: "pebblelab:unknown",
                    damage: 0,
                    enchantments: [],
                    label: nil,
                    canonicalDataJSON: "{}"
                ),
                count: 1
            )
            let unknownRejected: Bool
            do {
                _ = try bridge.itemStack(from: unknown)
                unknownRejected = false
            } catch PebbleAgentMaterialBridgeError.unknownItemKey {
                unknownRejected = true
            }
            let damagedTool = ItemStack(iid("iron_pickaxe"), 1, damage: 7)
            let damagedToolSnapshot = try bridge.snapshot(of: damagedTool)
            let damagedToolRoundTrip = try bridge.itemStack(from: damagedToolSnapshot)
            var nestedData = StackData()
            nestedData.contents = [ItemStack(iid("stone"), 1)]
            let nestedRejected: Bool
            do {
                _ = try bridge.snapshot(of: ItemStack(iid("shulker_box"), 1, data: nestedData))
                nestedRejected = false
            } catch PebbleAgentMaterialBridgeError.unsupportedNestedInventory {
                nestedRejected = true
            }
            let simpleRoundTrip = try bridge.itemStack(from: simpleA)
            let richBytesA = try bridge.canonicalBytes(of: richSnapshot)
            let richBytesB = try bridge.canonicalBytes(of: richSnapshot)
            let identityProof = simpleA == simpleB
                && simpleRoundTrip == ItemStack(iid("cobblestone"), 4)
                && richRoundTrip == richPhysical
                && damagedToolRoundTrip == damagedTool
                && richBytesA == richBytesB
                && unknownRejected
                && nestedRejected
            try requireMaterialProof(identityProof, "stable identity round trip")

            let initialAgentSnapshot = try materialCustodyGateway.inspect(agentEndpoint)
            let initialProjection = PebbleAgentCoarseMaterialProjection().amounts(
                from: initialAgentSnapshot
            )
            let initialProjectionRepeat = PebbleAgentCoarseMaterialProjection().amounts(
                from: initialAgentSnapshot
            )
            try requireMaterialProof(
                initialProjection == initialProjectionRepeat
                    && initialProjection.contains(AgentResourceAmount(resource: .foodRaw, quantity: 3))
                    && initialProjection.contains(AgentResourceAmount(resource: .stone, quantity: 12)),
                "deterministic coarse projection"
            )

            let depositRequest = PebbleAgentMaterialTransactionRequest(
                transactionID: "civ16-deposit-1",
                material: simpleA,
                expectedSourceFingerprint: try materialCustodyGateway.fingerprint(agentEndpoint),
                expectedDestinationFingerprint: try materialCustodyGateway.fingerprint(containerEndpoint)
            )
            let deposit = materialCustodyGateway.transfer(
                depositRequest,
                from: agentEndpoint,
                to: containerEndpoint
            )
            let duplicateDeposit = materialCustodyGateway.transfer(
                depositRequest,
                from: agentEndpoint,
                to: containerEndpoint
            )
            let staleDeposit = materialCustodyGateway.transfer(
                PebbleAgentMaterialTransactionRequest(
                    transactionID: "civ16-stale-1",
                    material: AgentMaterialStackSnapshot(identity: simpleA.identity, count: 1),
                    expectedSourceFingerprint: depositRequest.expectedSourceFingerprint,
                    expectedDestinationFingerprint: try materialCustodyGateway.fingerprint(containerEndpoint)
                ),
                from: agentEndpoint,
                to: containerEndpoint
            )
            let withdrawRequest = PebbleAgentMaterialTransactionRequest(
                transactionID: "civ16-withdraw-1",
                material: AgentMaterialStackSnapshot(identity: simpleA.identity, count: 2),
                expectedSourceFingerprint: try materialCustodyGateway.fingerprint(containerEndpoint),
                expectedDestinationFingerprint: try materialCustodyGateway.fingerprint(agentEndpoint)
            )
            let withdraw = materialCustodyGateway.transfer(
                withdrawRequest,
                from: containerEndpoint,
                to: agentEndpoint
            )
            let beforeLateSource = try materialCustodyGateway.fingerprint(agentEndpoint)
            let beforeLateDestination = try materialCustodyGateway.fingerprint(containerEndpoint)
            let lateTransfer = materialCustodyGateway.transfer(
                PebbleAgentMaterialTransactionRequest(
                    transactionID: "civ16-late-transfer-1",
                    material: AgentMaterialStackSnapshot(identity: simpleA.identity, count: 1),
                    expectedSourceFingerprint: beforeLateSource,
                    expectedDestinationFingerprint: beforeLateDestination
                ),
                from: agentEndpoint,
                to: containerEndpoint,
                verifyAfterMutation: { false }
            )
            let afterLateSource = try materialCustodyGateway.fingerprint(agentEndpoint)
            let afterLateDestination = try materialCustodyGateway.fingerprint(containerEndpoint)
            let transferProof = deposit.status == .succeeded && deposit.quantityMoved == 4
                && duplicateDeposit.status == .duplicate && duplicateDeposit.quantityMoved == 0
                && staleDeposit.status == .staleSource
                && withdraw.status == .succeeded && withdraw.quantityMoved == 2
                && lateTransfer.status == .verificationFailure
                && afterLateSource == beforeLateSource
                && afterLateDestination == beforeLateDestination
                && actor.carriedItems[0]?.count == 8
                && container.items?[0]?.count == 2
            try requireMaterialProof(transferProof, "transfer/idempotence/rollback")

            let haySnapshot = try bridge.snapshot(of: ItemStack(iid("hay_block"), 1))
            let consume = materialCustodyGateway.consume(
                PebbleAgentMaterialTransactionRequest(
                    transactionID: "civ16-consume-1",
                    material: haySnapshot,
                    expectedSourceFingerprint: try materialCustodyGateway.fingerprint(agentEndpoint),
                    expectedDestinationFingerprint: nil
                ),
                from: agentEndpoint
            )
            let duplicateConsume = materialCustodyGateway.consume(
                PebbleAgentMaterialTransactionRequest(
                    transactionID: "civ16-consume-1",
                    material: haySnapshot,
                    expectedSourceFingerprint: "stale-by-design",
                    expectedDestinationFingerprint: nil
                ),
                from: agentEndpoint
            )
            let beforeLateConsume = try materialCustodyGateway.fingerprint(agentEndpoint)
            let lateConsume = materialCustodyGateway.consume(
                PebbleAgentMaterialTransactionRequest(
                    transactionID: "civ16-late-consume-1",
                    material: haySnapshot,
                    expectedSourceFingerprint: beforeLateConsume,
                    expectedDestinationFingerprint: nil
                ),
                from: agentEndpoint,
                verifyAfterMutation: { false }
            )
            let afterLateConsume = try materialCustodyGateway.fingerprint(agentEndpoint)
            try requireMaterialProof(
                consume.status == .succeeded && consume.quantityMoved == 1
                    && duplicateConsume.status == .duplicate
                    && lateConsume.status == .verificationFailure
                    && afterLateConsume == beforeLateConsume
                    && actor.carriedItems[3]?.count == 2,
                "real material consumption"
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
            let actionGateway = PebbleAgentPhysicalActionGateway()
            let latePlacementBinding = try requireBinding(
                materialCustodyGateway.placementBinding(actor: actor, slot: 1),
                "late placement binding"
            )
            let placementRequest = PebbleAgentBlockPlacementRequest(
                actorID: actorID,
                hit: hit,
                target: fixture.target,
                expectedCell: 0,
                blockID: Int(B.stone),
                heldItem: latePlacementBinding.heldItem,
                orientation: BlockPlacementOrientation(yaw: actor.yaw, pitch: actor.pitch)
            )
            let latePlacement = actionGateway.placeBlock(
                world: world,
                actor: actor,
                request: placementRequest,
                custody: latePlacementBinding.custody,
                occupiedPositions: occupied,
                verifyAfterMutation: { false }
            )
            let latePlacementRestored = actor.carriedItems[1]?.count == 2
            let placementBinding = try requireBinding(
                materialCustodyGateway.placementBinding(actor: actor, slot: 1),
                "placement binding"
            )
            let placed = actionGateway.placeBlock(
                world: world,
                actor: actor,
                request: PebbleAgentBlockPlacementRequest(
                    actorID: actorID,
                    hit: hit,
                    target: fixture.target,
                    expectedCell: 0,
                    blockID: Int(B.stone),
                    heldItem: placementBinding.heldItem,
                    orientation: BlockPlacementOrientation(yaw: actor.yaw, pitch: actor.pitch)
                ),
                custody: placementBinding.custody,
                occupiedPositions: occupied
            )
            let stalePlacementBinding = try requireBinding(
                materialCustodyGateway.placementBinding(actor: actor, slot: 1),
                "stale placement binding"
            )
            let stalePlacement = actionGateway.placeBlock(
                world: world,
                actor: actor,
                request: PebbleAgentBlockPlacementRequest(
                    actorID: actorID,
                    hit: hit,
                    target: fixture.target,
                    expectedCell: 0,
                    blockID: Int(B.stone),
                    heldItem: stalePlacementBinding.heldItem,
                    orientation: BlockPlacementOrientation(yaw: actor.yaw, pitch: actor.pitch)
                ),
                custody: stalePlacementBinding.custody,
                occupiedPositions: occupied
            )
            let stalePlacementPreserved = actor.carriedItems[1]?.count == 1
            let toolBinding = try requireBinding(
                materialCustodyGateway.toolBinding(actor: actor, slot: 2, world: world),
                "tool binding"
            )
            let broken = actionGateway.breakBlock(
                world: world,
                actor: actor,
                request: PebbleAgentBlockBreakRequest(
                    actorID: actorID,
                    target: fixture.target,
                    expectedCell: Int(cell(B.stone)),
                    heldItem: toolBinding.heldItem,
                    isCreative: false
                ),
                toolState: toolBinding.toolState,
                occupiedPositions: occupied
            )
            let secondPlacementBinding = try requireBinding(
                materialCustodyGateway.placementBinding(actor: actor, slot: 1),
                "second placement binding"
            )
            let secondPlaced = actionGateway.placeBlock(
                world: world,
                actor: actor,
                request: PebbleAgentBlockPlacementRequest(
                    actorID: actorID,
                    hit: hit,
                    target: fixture.target,
                    expectedCell: 0,
                    blockID: Int(B.stone),
                    heldItem: secondPlacementBinding.heldItem,
                    orientation: BlockPlacementOrientation(yaw: actor.yaw, pitch: actor.pitch)
                ),
                custody: secondPlacementBinding.custody,
                occupiedPositions: occupied
            )
            let lateToolBefore = actor.carriedItems[2]?.copy()
            let lateToolBinding = try requireBinding(
                materialCustodyGateway.toolBinding(actor: actor, slot: 2, world: world),
                "late tool binding"
            )
            let lateBreak = actionGateway.breakBlock(
                world: world,
                actor: actor,
                request: PebbleAgentBlockBreakRequest(
                    actorID: actorID,
                    target: fixture.target,
                    expectedCell: Int(cell(B.stone)),
                    heldItem: lateToolBinding.heldItem,
                    isCreative: false
                ),
                toolState: lateToolBinding.toolState,
                occupiedPositions: occupied,
                verifyAfterMutation: { false }
            )
            let custodyActionProof = latePlacement.status == .verificationFailure
                && latePlacementRestored
                && placed.status == .succeeded
                && stalePlacement.status == .staleTarget
                && stalePlacementPreserved
                && broken.status == .succeeded
                && actor.carriedItems[2]?.damage == 1
                && secondPlaced.status == .succeeded
                && lateBreak.status == .verificationFailure
                && actor.carriedItems[2] == lateToolBefore
                && world.getBlock(fixture.target.x, fixture.target.y, fixture.target.z) == Int(cell(B.stone))
            try requireMaterialProof(custodyActionProof, "CIV-15 custody/tool seam")

            let durableUnchanged = try session.durableStateBytes() == durableBefore
            let campStockUnchanged = session.snapshot().campStock == campStockBefore
            let transactionDigest = [
                actorID,
                deposit.status.rawValue,
                duplicateDeposit.status.rawValue,
                staleDeposit.status.rawValue,
                withdraw.status.rawValue,
                lateTransfer.status.rawValue,
                consume.status.rawValue,
                duplicateConsume.status.rawValue,
                lateConsume.status.rawValue,
                latePlacement.status.rawValue,
                placed.status.rawValue,
                stalePlacement.status.rawValue,
                broken.status.rawValue,
                secondPlaced.status.rawValue,
                lateBreak.status.rawValue,
                durableUnchanged ? "session-unchanged" : "session-changed",
                campStockUnchanged ? "coarse-unchanged" : "coarse-changed",
            ].joined(separator: "|")
            let digest = String(hashString(transactionDigest), radix: 16)

            actor.carriedItems = Array(
                repeating: nil,
                count: LabCoreAgentEntity.carriedItemSlotCount
            )
            container.items = Array(repeating: nil, count: 27)
            cleanupVerified = restoreMaterialProofFixture(
                fixture,
                container: container,
                entityIDsBefore: entityIDsBefore,
                world: world
            )
            materialCustodyGateway.reset()
            let proofPassed = durableUnchanged && campStockUnchanged && cleanupVerified
            trace(
                "material proof actor=\(actorID) identity=stable transfer=\(deposit.status.rawValue) "
                    + "duplicate=\(duplicateDeposit.status.rawValue) stale=\(staleDeposit.status.rawValue) "
                    + "withdraw=\(withdraw.status.rawValue) lateTransfer=\(lateTransfer.status.rawValue) "
                    + "consume=\(consume.status.rawValue) lateConsume=\(lateConsume.status.rawValue) "
                    + "place=\(placed.status.rawValue) break=\(broken.status.rawValue) "
                    + "lateBreak=\(lateBreak.status.rawValue) session=\(durableUnchanged ? "unchanged" : "changed") "
                    + "campStock=\(campStockUnchanged ? "unchanged" : "changed") "
                    + "cleanup=\(cleanupVerified ? "verified" : "failed") digest=\(digest)"
            )
            guard proofPassed else {
                return failure("Material custody proof failed; cleanup verified=\(cleanupVerified).")
            }
            return success(
                "Material custody proof passed: stable identity, real agent/container transfer, consume, idempotence, rollback, CIV-15 custody/tool bridge, coarse non-authority; digest=\(digest)."
            )
        } catch {
            actor.carriedItems = Array(
                repeating: nil,
                count: LabCoreAgentEntity.carriedItemSlotCount
            )
            proofContainer?.items = Array(repeating: nil, count: 27)
            cleanupVerified = restoreMaterialProofFixture(
                fixture,
                container: proofContainer,
                entityIDsBefore: entityIDsBefore,
                world: world
            )
            materialCustodyGateway.reset()
            return failure(
                "Material custody proof failed before completion: \(error); cleanup verified=\(cleanupVerified)."
            )
        }
    }

    private func materialProofFixture(
        world: World,
        actor: LabCoreAgentEntity,
        player: Player
    ) -> PebbleAgentMaterialProofFixture? {
        let origin = PhysicalBlockPosition(
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
        for (dx, dz) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
            let target = PhysicalBlockPosition(x: origin.x + dx, y: origin.y, z: origin.z + dz)
            let support = PhysicalBlockPosition(x: target.x, y: target.y - 1, z: target.z)
            let container = PhysicalBlockPosition(
                x: origin.x + dx * 3,
                y: origin.y,
                z: origin.z + dz * 3
            )
            let boundary = [target, support, container] + (0..<6).map {
                PhysicalBlockPosition(
                    x: target.x + DIR_X[$0],
                    y: target.y + DIR_Y[$0],
                    z: target.z + DIR_Z[$0]
                )
            }
            var unique: [PhysicalBlockPosition] = []
            for position in boundary where !unique.contains(position) { unique.append(position) }
            guard unique.allSatisfy({
                world.isChunkReady($0.x >> 4, $0.z >> 4)
                    && world.getBlockEntity($0.x, $0.y, $0.z) == nil
            }), !occupied.contains(target), !occupied.contains(container) else { continue }
            return PebbleAgentMaterialProofFixture(
                target: target,
                support: support,
                container: container,
                originalCells: unique.map { ($0, world.getBlock($0.x, $0.y, $0.z)) }
            )
        }
        return nil
    }

    private func prepareMaterialProofFixture(
        _ fixture: PebbleAgentMaterialProofFixture,
        world: World
    ) throws {
        for original in fixture.originalCells {
            let prepared: Int
            if original.position == fixture.support {
                prepared = Int(cell(B.stone))
            } else if original.position == fixture.container {
                prepared = Int(cell(B.chest))
            } else {
                prepared = 0
            }
            _ = world.setBlock(
                original.position.x,
                original.position.y,
                original.position.z,
                prepared,
                SET_SILENT
            )
        }
        try requireMaterialProof(
            world.getBlock(fixture.target.x, fixture.target.y, fixture.target.z) == 0
                && world.getBlock(fixture.support.x, fixture.support.y, fixture.support.z) == Int(cell(B.stone))
                && world.getBlock(fixture.container.x, fixture.container.y, fixture.container.z) == Int(cell(B.chest)),
            "fixture preparation"
        )
    }

    private func restoreMaterialProofFixture(
        _ fixture: PebbleAgentMaterialProofFixture,
        container: BlockEntityData?,
        entityIDsBefore: [Int],
        world: World
    ) -> Bool {
        container?.items = Array(repeating: nil, count: container?.items?.count ?? 27)
        for original in fixture.originalCells.reversed() {
            _ = world.setBlock(
                original.position.x,
                original.position.y,
                original.position.z,
                original.cell,
                SET_SILENT
            )
        }
        for entity in world.entities where !entityIDsBefore.contains(entity.id) {
            world.removeEntity(entity)
        }
        return fixture.originalCells.allSatisfy {
            world.getBlock($0.position.x, $0.position.y, $0.position.z) == $0.cell
                && world.getBlockEntity($0.position.x, $0.position.y, $0.position.z) == nil
        } && world.entities.map(\.id).sorted() == entityIDsBefore
    }

    private func requireMaterialProof(_ condition: @autoclosure () throws -> Bool, _ label: String) throws {
        guard try condition() else { throw PebbleAgentMaterialProofError.failed(label) }
    }

    private func requireBinding<T>(_ value: T?, _ label: String) throws -> T {
        guard let value else { throw PebbleAgentMaterialProofError.failed(label) }
        return value
    }
}
