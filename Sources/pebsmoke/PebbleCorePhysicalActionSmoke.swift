import Foundation
import PebbleCore

private func physicalActionWorld(seed: UInt32 = 15) -> World {
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
    return world
}

private func physicalActionHit(
    _ world: World,
    x: Int = 0,
    y: Int = 63,
    z: Int = 0,
    face: Int = 1
) -> RaycastHit {
    RaycastHit(
        x: x,
        y: y,
        z: z,
        face: face,
        cell: world.getBlock(x, y, z),
        t: 0,
        px: Double(x) + 0.5,
        py: Double(y) + (face == 1 ? 1 : 0.5),
        pz: Double(z) + 0.5
    )
}

private struct PhysicalBreakDigest: Equatable {
    let result: BlockBreakRuleResult
    let toolDamage: Int
    let drops: [(id: Int, count: Int, vx: Double, vy: Double, vz: Double)]

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.result == rhs.result
            && lhs.toolDamage == rhs.toolDamage
            && lhs.drops.elementsEqual(rhs.drops) { left, right in
                left.id == right.id
                    && left.count == right.count
                    && left.vx == right.vx
                    && left.vy == right.vy
                    && left.vz == right.vz
            }
    }
}

private func deterministicPhysicalBreak(seed: UInt32) -> PhysicalBreakDigest {
    resetGameRng(seed)
    let world = physicalActionWorld(seed: seed)
    world.setBlock(0, 64, 0, Int(cell(B.stone)), SET_SILENT)
    let tool = ItemStack(iid("iron_pickaxe"))
    let result = executeBlockBreak(
        BlockBreakRuleContext(
            world: world,
            heldItem: tool,
            isCreative: false,
            damageTool: { tool.damage += $0 }
        ),
        0,
        64,
        0
    )
    let drops = world.entities.compactMap { entity -> (Int, Int, Double, Double, Double)? in
        guard let item = entity as? ItemEntity else { return nil }
        return (item.stack.id, item.stack.count, item.vx, item.vy, item.vz)
    }
    return PhysicalBreakDigest(result: result, toolDamage: tool.damage, drops: drops)
}

func runPebbleCorePhysicalActionSmoke() {
    section("PebbleCore actor-neutral physical actions")

    let placementWorld = physicalActionWorld()
    placementWorld.setBlock(0, 63, 0, Int(cell(B.stone)), SET_SILENT)
    let probe = LabCoreAgentEntity(
        world: placementWorld,
        labAgentId: "physical_action_probe",
        physicalId: "physical_action_probe"
    )
    probe.setPos(8.5, 64, 8.5)
    placementWorld.addEntity(probe)
    let placementStack = ItemStack(iid("oak_stairs"), 2)
    var placementCount = placementStack.count
    var placementRecords = 0
    let placement = executeBlockPlacement(
        BlockPlacementRuleContext(
            world: placementWorld,
            orientation: BlockPlacementOrientation(yaw: 0, pitch: 0),
            vibrationSource: probe,
            consumeHeld: { placementCount -= $0 },
            recordPlacement: { placementRecords += 1 }
        ),
        physicalActionHit(placementWorld),
        Int(itemDef(placementStack.id).block!),
        placementStack
    )
    check("actor-neutral placement succeeds without Player", placement.succeeded)
    check("placement reports the exact target", placement.target == PhysicalBlockPosition(x: 0, y: 64, z: 0))
    check("placement reports one direct world mutation", placement.mutations.count == 1)
    check("placement preserves the requested block and metadata", placement.finalCell == placementWorld.getBlock(0, 64, 0) && (placement.finalCell! >> 4) == Int(B.oak_stairs))
    check("placement delegates custody exactly once", placementCount == 1 && placementRecords == 1)

    let repeatPlacement = executeBlockPlacement(
        BlockPlacementRuleContext(
            world: placementWorld,
            orientation: BlockPlacementOrientation(yaw: 0, pitch: 0),
            vibrationSource: probe,
            consumeHeld: { placementCount -= $0 },
            recordPlacement: { placementRecords += 1 }
        ),
        physicalActionHit(placementWorld),
        Int(itemDef(placementStack.id).block!),
        placementStack
    )
    check("repeated placement is refused", !repeatPlacement.succeeded && repeatPlacement.mutations.isEmpty)
    check("refused placement changes no custody", placementCount == 1 && placementRecords == 1)

    let playerWorld = physicalActionWorld()
    playerWorld.setBlock(0, 63, 0, Int(cell(B.stone)), SET_SILENT)
    let player = Player(world: playerWorld)
    player.setPos(8.5, 64, 8.5)
    player.yaw = 0
    player.pitch = 0
    player.inventory[player.selectedSlot] = ItemStack(iid("oak_stairs"), 2)
    playerWorld.addEntity(player)
    let playerPlaced = placeBlock(
        InteractCtx(world: playerWorld, player: player),
        physicalActionHit(playerWorld),
        Int(itemDef(player.mainHand!.id).block!),
        player.mainHand!
    )
    check("Player compatibility wrapper still succeeds", playerPlaced)
    check("Player wrapper uses identical physical authority", playerWorld.getBlock(0, 64, 0) == placementWorld.getBlock(0, 64, 0))
    check("Player wrapper preserves inventory and stat effects", player.mainHand?.count == 1 && player.stats["blocksPlaced"] == 1)

    let invalidWorld = physicalActionWorld()
    invalidWorld.setBlock(0, 63, 0, Int(cell(B.stone)), SET_SILENT)
    invalidWorld.setBlock(0, 64, 0, Int(cell(B.stone)), SET_SILENT)
    var invalidConsumed = 0
    let invalidStack = ItemStack(iid("oak_log"))
    let invalid = executeBlockPlacement(
        BlockPlacementRuleContext(
            world: invalidWorld,
            orientation: BlockPlacementOrientation(yaw: 0, pitch: 0),
            consumeHeld: { invalidConsumed += $0 }
        ),
        physicalActionHit(invalidWorld),
        Int(itemDef(invalidStack.id).block!),
        invalidStack
    )
    check("invalid occupied placement is refused", !invalid.succeeded)
    check("invalid placement has no mutation or consumption", invalid.mutations.isEmpty && invalidConsumed == 0 && invalidWorld.getBlock(0, 64, 0) == Int(cell(B.stone)))

    let collisionWorld = physicalActionWorld()
    collisionWorld.setBlock(0, 63, 0, Int(cell(B.stone)), SET_SILENT)
    let obstruction = spawnMob(
        collisionWorld,
        "cow",
        0.5,
        64,
        0.5,
        SpawnOpts()
    )!
    obstruction.setPos(0.5, 64, 0.5)
    var collisionConsumed = 0
    let collisionStack = ItemStack(iid("oak_log"))
    let collision = executeBlockPlacement(
        BlockPlacementRuleContext(
            world: collisionWorld,
            orientation: BlockPlacementOrientation(yaw: 0, pitch: 0),
            consumeHeld: { collisionConsumed += $0 }
        ),
        physicalActionHit(collisionWorld),
        Int(itemDef(collisionStack.id).block!),
        collisionStack
    )
    check("actor-neutral placement preserves LivingEntity collision", !collision.succeeded && collision.mutations.isEmpty)
    check("collision refusal consumes nothing", collisionConsumed == 0 && collisionWorld.getBlock(0, 64, 0) == 0)

    let tillWorld = physicalActionWorld()
    tillWorld.setBlock(0, 63, 0, Int(cell(B.dirt)), SET_SILENT)
    let hoe = ItemStack(iid("iron_hoe"))
    var tillDamage = 0
    let tilled = executeBlockTilling(
        BlockTillingRuleContext(
            world: tillWorld, heldItem: hoe,
            damageTool: { tillDamage += $0 }
        ),
        0, 63, 0
    )
    check("actor-neutral tilling succeeds without Player",
          tilled.status == .succeeded
            && tilled.finalCell == Int(cell(B.farmland, 0)))
    check("tilling reports one exact direct mutation",
          tilled.mutations == [PhysicalBlockMutation(
            position: PhysicalBlockPosition(x: 0, y: 63, z: 0),
            before: Int(cell(B.dirt)), after: Int(cell(B.farmland, 0))
          )])
    check("tilling delegates hoe durability exactly once", tillDamage == 1)
    let repeatedTill = executeBlockTilling(
        BlockTillingRuleContext(
            world: tillWorld, heldItem: hoe,
            damageTool: { tillDamage += $0 }
        ),
        0, 63, 0
    )
    check("repeated tilling is refused without durability",
          repeatedTill.status == .refused && repeatedTill.mutations.isEmpty
            && tillDamage == 1)

    let invalidTillWorld = physicalActionWorld()
    invalidTillWorld.setBlock(0, 63, 0, Int(cell(B.stone)), SET_SILENT)
    let invalidTill = executeBlockTilling(
        BlockTillingRuleContext(
            world: invalidTillWorld, heldItem: hoe,
            damageTool: { tillDamage += $0 }
        ),
        0, 63, 0
    )
    check("invalid soil tilling is an exact refusal",
          invalidTill.status == .refused
            && invalidTillWorld.getBlock(0, 63, 0) == Int(cell(B.stone))
            && tillDamage == 1)

    let playerTillWorld = physicalActionWorld()
    playerTillWorld.setBlock(0, 63, 0, Int(cell(B.dirt)), SET_SILENT)
    let tillPlayer = Player(world: playerTillWorld)
    tillPlayer.inventory[tillPlayer.selectedSlot] = ItemStack(iid("iron_hoe"))
    playerTillWorld.addEntity(tillPlayer)
    let playerTilled = useItem(
        InteractCtx(world: playerTillWorld, player: tillPlayer),
        physicalActionHit(playerTillWorld, y: 63)
    )
    check("Player tilling compatibility wrapper still succeeds", playerTilled)
    check("Player and actor-neutral tilling share Core authority",
          playerTillWorld.getBlock(0, 63, 0) == tilled.finalCell
            && tillPlayer.mainHand?.damage == 1)

    let breakingHoeWorld = physicalActionWorld()
    breakingHoeWorld.setBlock(0, 63, 0, Int(cell(B.dirt)), SET_SILENT)
    let breakingHoePlayer = Player(world: breakingHoeWorld)
    let breakingHoe = ItemStack(iid("iron_hoe"))
    breakingHoe.damage = maxDamageOf(breakingHoe) - 1
    breakingHoePlayer.inventory[breakingHoePlayer.selectedSlot] = breakingHoe
    breakingHoeWorld.addEntity(breakingHoePlayer)
    let tilledWithBreakingHoe = useItem(
        InteractCtx(world: breakingHoeWorld, player: breakingHoePlayer),
        physicalActionHit(breakingHoeWorld, y: 63)
    )
    check("Player tilling preserves canonical tool break semantics",
          tilledWithBreakingHoe
            && breakingHoeWorld.getBlock(0, 63, 0) == Int(cell(B.farmland, 0))
            && breakingHoePlayer.mainHand == nil)

    resetGameRng(15)
    let breakWorld = physicalActionWorld()
    breakWorld.setBlock(0, 64, 0, Int(cell(B.stone)), SET_SILENT)
    let breakProbe = LabCoreAgentEntity(
        world: breakWorld,
        labAgentId: "physical_break_probe",
        physicalId: "physical_break_probe"
    )
    breakProbe.setPos(8.5, 64, 8.5)
    breakWorld.addEntity(breakProbe)
    let pickaxe = ItemStack(iid("iron_pickaxe"))
    var minedRecords = 0
    var exhaustion = 0.0
    let broken = executeBlockBreak(
        BlockBreakRuleContext(
            world: breakWorld,
            heldItem: pickaxe,
            isCreative: false,
            vibrationSource: breakProbe,
            damageTool: { pickaxe.damage += $0 },
            recordMinedBlock: { minedRecords += 1 },
            addExhaustion: { exhaustion += $0 }
        ),
        0,
        64,
        0
    )
    let breakDrops = breakWorld.entities.compactMap { $0 as? ItemEntity }
    check("actor-neutral break succeeds without Player", broken.status == .succeeded && broken.finalCell == 0)
    check("break reports the direct mutation", broken.mutations == [PhysicalBlockMutation(position: PhysicalBlockPosition(x: 0, y: 64, z: 0), before: Int(cell(B.stone)), after: 0)])
    check("break reuses harvest and drop rules", breakDrops.count == 1 && breakDrops[0].stack.id == iid("cobblestone") && breakDrops[0].stack.count == 1)
    check("break reports exact drop entity provenance",
          broken.spawnedItemEntityIDs == breakDrops.map(\.id))
    check("break delegates tool, stat, and exhaustion effects", pickaxe.damage == 1 && minedRecords == 1 && exhaustion == 0.005)
    let dropCountBeforeRepeat = breakDrops.count
    let repeatedBreak = executeBlockBreak(
        BlockBreakRuleContext(world: breakWorld, heldItem: pickaxe, isCreative: false),
        0,
        64,
        0
    )
    check("repeated break reports no target", repeatedBreak.status == .noTarget && repeatedBreak.mutations.isEmpty)
    check("repeated break creates no duplicate drop", breakWorld.entities.compactMap { $0 as? ItemEntity }.count == dropCountBeforeRepeat)
    check("repeated break reports no drop provenance",
          repeatedBreak.spawnedItemEntityIDs.isEmpty)

    let wrongToolWorld = physicalActionWorld()
    wrongToolWorld.setBlock(0, 64, 0, Int(cell(B.stone)), SET_SILENT)
    let wrongTool = executeBlockBreak(
        BlockBreakRuleContext(world: wrongToolWorld, heldItem: nil, isCreative: false),
        0,
        64,
        0
    )
    check("wrong-tool break still mutates physical truth", wrongTool.status == .succeeded && wrongTool.finalCell == 0)
    check("wrong-tool break produces no conserved item", wrongToolWorld.entities.compactMap { $0 as? ItemEntity }.isEmpty)
    check("wrong-tool break reports no drop provenance",
          wrongTool.spawnedItemEntityIDs.isEmpty)

    resetGameRng(0xB15)
    let sharedBreakWorld = physicalActionWorld()
    sharedBreakWorld.setBlock(0, 64, 0, Int(cell(B.stone)), SET_SILENT)
    let sharedPickaxe = ItemStack(iid("iron_pickaxe"))
    let sharedBreak = executeBlockBreak(
        BlockBreakRuleContext(
            world: sharedBreakWorld,
            heldItem: sharedPickaxe,
            isCreative: false,
            damageTool: { sharedPickaxe.damage += $0 }
        ),
        0,
        64,
        0
    )
    let sharedDrop = sharedBreakWorld.entities.compactMap { $0 as? ItemEntity }.first
    resetGameRng(0xB15)
    let playerBreakWorld = physicalActionWorld()
    playerBreakWorld.setBlock(0, 64, 0, Int(cell(B.stone)), SET_SILENT)
    let breakingPlayer = Player(world: playerBreakWorld)
    breakingPlayer.setPos(8.5, 64, 8.5)
    breakingPlayer.inventory[breakingPlayer.selectedSlot] = ItemStack(iid("iron_pickaxe"))
    playerBreakWorld.addEntity(breakingPlayer)
    finishBreaking(
        InteractCtx(world: playerBreakWorld, player: breakingPlayer),
        0,
        64,
        0
    )
    let playerDrop = playerBreakWorld.entities.compactMap { $0 as? ItemEntity }.first
    check("Player break wrapper uses identical block and drop authority", sharedBreak.status == .succeeded && sharedBreakWorld.getBlock(0, 64, 0) == playerBreakWorld.getBlock(0, 64, 0) && sharedDrop?.stack == playerDrop?.stack)
    check("Player break wrapper preserves durability, stats, and exhaustion", sharedPickaxe.damage == breakingPlayer.mainHand?.damage && breakingPlayer.stats["blocksMined"] == 1 && breakingPlayer.exhaustion == 0.005)

    resetGameRng(0xC17)
    let sharedLogWorld = physicalActionWorld()
    sharedLogWorld.setBlock(0, 64, 0, Int(cell(B.oak_log)), SET_SILENT)
    let sharedAxe = ItemStack(iid("iron_axe"))
    let sharedLogBreak = executeBlockBreak(
        BlockBreakRuleContext(
            world: sharedLogWorld,
            heldItem: sharedAxe,
            isCreative: false,
            damageTool: { sharedAxe.damage += $0 }
        ),
        0,
        64,
        0
    )
    let sharedLogDrop = sharedLogWorld.entities.compactMap { $0 as? ItemEntity }.first
    resetGameRng(0xC17)
    let playerLogWorld = physicalActionWorld()
    playerLogWorld.setBlock(0, 64, 0, Int(cell(B.oak_log)), SET_SILENT)
    let logPlayer = Player(world: playerLogWorld)
    logPlayer.setPos(8.5, 64, 8.5)
    logPlayer.inventory[logPlayer.selectedSlot] = ItemStack(iid("iron_axe"))
    playerLogWorld.addEntity(logPlayer)
    finishBreaking(
        InteractCtx(world: playerLogWorld, player: logPlayer),
        0,
        64,
        0
    )
    let playerLogDrop = playerLogWorld.entities.compactMap { $0 as? ItemEntity }.first
    check("Player and actor-neutral log break share canonical drop authority",
          sharedLogBreak.status == .succeeded
            && sharedLogDrop?.stack == playerLogDrop?.stack
            && sharedLogDrop?.stack.id == iid("oak_log"))
    check("Player and actor-neutral log break share tool durability",
          sharedAxe.damage == 1 && sharedAxe.damage == logPlayer.mainHand?.damage)

    let deterministicA = deterministicPhysicalBreak(seed: 0xC15)
    let deterministicB = deterministicPhysicalBreak(seed: 0xC15)
    check("actor-neutral break is deterministic for fixed state and RNG", deterministicA == deterministicB)
}
