import PebbleCore

private func livestockCoreWorld() -> World {
    let world = World(dim: .overworld, seed: 46)
    let chunk = Chunk(cx: 0, cz: 0, minY: world.info.minY, height: world.info.height)
    chunk.buildHeightmap()
    chunk.status = .lit
    world.setChunk(chunk)
    return world
}

func runPebbleCoreLivestockSmoke() {
    section("PebbleCore Livestock reuse authority")
    resetGameRng(46)
    let world = livestockCoreWorld()
    let first = spawnMob(world, "sheep", 2.5, 64, 2.5, SpawnOpts()) as! Sheep
    let second = spawnMob(world, "sheep", 3.0, 64, 2.5, SpawnOpts()) as! Sheep
    let wheat = ItemStack(iid("wheat"), 1)
    let carrot = ItemStack(iid("carrot"), 1)

    let loveBefore = first.loveTicks
    check("wrong feed is rejected without animal mutation",
          !first.tryFeed(carrot, actorEntityID: 700) && first.loveTicks == loveBefore
            && carrot.count == 1)
    let unfedBreed = BreedGoal(first, 0) { a, b in first.spawnBaby(a, b) }
    check("Core breeding refuses unfed parents without offspring",
          !unfedBreed.canUse()
            && world.entities.compactMap { $0 as? Sheep }.allSatisfy { !$0.baby })
    check("real sheep feed enters Core breeding readiness",
          first.tryFeed(wheat, actorEntityID: 700) && first.loveTicks == 600
            && second.tryFeed(wheat, actorEntityID: 701))

    let entityCountBeforeBirth = world.entities.count
    let breed = BreedGoal(first, 0) { a, b in first.spawnBaby(a, b) }
    let eligible = breed.canUse()
    breed.start()
    for _ in 0..<60 { breed.tick() }
    let babies = world.entities.compactMap { $0 as? Sheep }.filter(\.baby)
    check("Core BreedGoal creates one real juvenile after proximity time",
          eligible && babies.count == 1 && world.entities.count > entityCountBeforeBirth)
    check("Core parents receive canonical breeding cooldown",
          first.breedCooldown == 6000 && second.breedCooldown == 6000)

    let baby = babies[0]
    let growthBefore = baby.growUpAge
    check("feeding juvenile accelerates only Core growth clock",
          baby.tryFeed(wheat, actorEntityID: 700)
            && baby.growUpAge == max(0, growthBefore - 1200))

    let player = Player(world: world)
    world.addEntity(player)
    let playerSheep = spawnMob(world, "sheep", 6.5, 64, 2.5, SpawnOpts()) as! Sheep
    player.mainHand = ItemStack(iid("wheat"), 2)
    check("existing Player feeding path delegates to actor-neutral Core primitive",
          playerSheep.interact(player, player.mainHand)
            && player.mainHand?.count == 1
            && playerSheep.data.loveCause == player.id)

    first.breedCooldown = 0
    first.loveTicks = 0
    first.sheared = false
    let shear = first.shearForLivestock()
    let emitted = shear?.spawnedItemEntityIDs.compactMap { world.entityById[$0] as? ItemEntity } ?? []
    check("real sheep shearing emits exact World ItemEntity provenance",
          shear != nil && shear!.quantity == emitted.reduce(0) { $0 + $1.stack.count }
            && emitted.allSatisfy { itemDef($0.stack.id).name.hasSuffix("_wool") })
    check("duplicate product collection is physically refused", first.shearForLivestock() == nil)

    let holder = LabCoreAgentEntity(
        world: world, labAgentId: "livestock-holder", physicalId: "holder-1"
    )
    holder.setPos(2.5, 64, 2.5)
    world.addEntity(holder)
    first.setPos(2.5, 64, 2.5)
    let attached = first.attachLivestockLeash(to: holder)
    holder.setPos(8.5, 64, 2.5)
    let xBefore = first.x
    first.mobTick()
    check("livestock herding delegates to existing leash physics without teleport",
          attached && first.x != holder.x && first.x >= xBefore)
    check("leash release is explicit and idempotent",
          first.releaseLivestockLeash() && !first.releaseLivestockLeash())
    let positionBeforeMissingHolder = (first.x, first.y, first.z)
    world.removeEntity(holder)
    check("missing livestock leash target is refused without movement",
          !first.attachLivestockLeash(to: holder)
            && first.x == positionBeforeMissingHolder.0
            && first.y == positionBeforeMissingHolder.1
            && first.z == positionBeforeMissingHolder.2)
}
