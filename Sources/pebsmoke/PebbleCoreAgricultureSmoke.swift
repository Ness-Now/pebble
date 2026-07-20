import PebbleCore

private func agricultureCoreWorld() -> World {
    let world = World(dim: .overworld, seed: 46)
    let chunk = Chunk(cx: 0, cz: 0, minY: world.info.minY, height: world.info.height)
    chunk.buildHeightmap()
    chunk.status = .lit
    world.setChunk(chunk)
    return world
}

private func growWheatThroughCanonicalRandomTick() -> (stages: [Int], mature: Bool) {
    let world = agricultureCoreWorld()
    world.setBlock(1, 62, 0, Int(cell(B.water, 0)), SET_SILENT)
    world.setBlock(0, 63, 0, Int(cell(B.farmland, 7)), SET_SILENT)
    world.setBlock(0, 64, 0, Int(cell(B.wheat, 0)), SET_SILENT)
    world.dayTime = 6_000
    world.getChunk(0, 0)!.setSky(0, 64, 0, 15)
    var stages = [0]
    for _ in 0..<512 where (world.getBlock(0, 64, 0) & 15) < 7 {
        randomTickHandlers[Int(B.wheat)]?(
            world, 0, 64, 0, world.getBlock(0, 64, 0)
        )
        let stage = world.getBlock(0, 64, 0) & 15
        if stages.last != stage { stages.append(stage) }
    }
    return (stages, (world.getBlock(0, 64, 0) & 15) == 7)
}

func runPebbleCoreAgricultureSmoke() {
    section("PebbleCore canonical farming authority")

    let growth = growWheatThroughCanonicalRandomTick()
    check("real Core random-tick wheat reaches maturity", growth.mature)
    check("real Core growth advances canonical stages without skips",
          growth.stages == Array(0...7))

    let supportWorld = agricultureCoreWorld()
    supportWorld.setBlock(0, 63, 0, Int(cell(B.dirt)), SET_SILENT)
    let seeds = ItemStack(iid("wheat_seeds"), 2)
    var consumed = 0
    let invalid = executeBlockPlacement(
        BlockPlacementRuleContext(
            world: supportWorld,
            orientation: BlockPlacementOrientation(yaw: 0, pitch: 0),
            consumeHeld: { consumed += $0 }
        ),
        RaycastHit(
            x: 0, y: 64, z: 0, face: 1, cell: 0, t: 0,
            px: 0.5, py: 64.5, pz: 0.5
        ),
        Int(B.wheat), seeds
    )
    check("Core refuses wheat on wrong support without seed debit",
          !invalid.succeeded && consumed == 0 && supportWorld.getBlock(0, 64, 0) == 0)

    supportWorld.setBlock(0, 63, 0, Int(cell(B.farmland, 7)), SET_SILENT)
    let planted = executeBlockPlacement(
        BlockPlacementRuleContext(
            world: supportWorld,
            orientation: BlockPlacementOrientation(yaw: 0, pitch: 0),
            consumeHeld: { consumed += $0 }
        ),
        RaycastHit(
            x: 0, y: 64, z: 0, face: 1, cell: 0, t: 0,
            px: 0.5, py: 64.5, pz: 0.5
        ),
        Int(B.wheat), seeds
    )
    check("Core registry-backed planting consumes exactly one real seed",
          planted.succeeded && consumed == 1
            && supportWorld.getBlock(0, 64, 0) == Int(cell(B.wheat, 0)))

    resetGameRng(46)
    supportWorld.setBlock(0, 64, 0, Int(cell(B.wheat, 7)), SET_SILENT)
    let harvested = executeBlockBreak(
        BlockBreakRuleContext(world: supportWorld, heldItem: nil, isCreative: false),
        0, 64, 0
    )
    let drops = supportWorld.entities.compactMap { $0 as? ItemEntity }
    check("mature wheat harvest uses canonical break and exact provenance",
          harvested.status == .succeeded && harvested.finalCell == 0
            && harvested.spawnedItemEntityIDs == drops.map(\.id)
            && drops.contains(where: { itemDef($0.stack.id).name == "wheat" }))
    check("canonical harvest returns real planting input",
          drops.contains(where: { itemDef($0.stack.id).name == "wheat_seeds" }))
}
