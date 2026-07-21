import Foundation
import PebbleCore

private func wildCoreWorld(seed: UInt32 = 46) -> World {
    let world = World(dim: .overworld, seed: seed)
    for cz in -2...2 {
        for cx in -2...2 {
            let chunk = Chunk(cx: cx, cz: cz, minY: world.info.minY, height: world.info.height)
            chunk.buildHeightmap()
            chunk.status = .lit
            world.setChunk(chunk)
        }
    }
    return world
}

private func wildProbe(_ world: World, _ id: String, x: Double = 0.5, z: Double = 0.5) -> LabCoreAgentEntity {
    let probe = LabCoreAgentEntity(world: world, labAgentId: id, physicalId: id)
    probe.setPos(x, 64, z)
    world.addEntity(probe)
    return probe
}

private func prepareFishingWater(_ world: World) {
    for z in -12...12 {
        for x in -12...12 {
            world.setBlock(x, 63, z, Int(cell(B.water)), SET_SILENT)
            world.setBlock(x, 64, z, Int(cell(B.water)), SET_SILENT)
        }
    }
}

func runPebbleCoreWildSubsistenceSmoke() {
    section("PebbleCore real fishing, hunting, and wild gathering")

    resetGameRng(46)
    let missWorld = wildCoreWorld()
    prepareFishingWater(missWorld)
    let missActor = wildProbe(missWorld, "fishing-miss")
    let missRod = ItemStack(iid("fishing_rod"))
    let missedBobber = castFishingBobber(
        world: missWorld, owner: missActor, rod: missRod,
        originX: 0.5, originY: 64.25, originZ: 0.5, pitch: 0, yaw: 0
    )
    let missed = missedBobber.retrieve()
    check("real cast creates an actor-owned FishingBobber",
          missedBobber.ownerActor === missActor && missedBobber.fishingRod === missRod)
    check("retrieve outside bite window creates zero loot",
          missed.kind == .missed && missed.spawnedItemEntityIDs.isEmpty
            && missWorld.entities.compactMap { $0 as? ItemEntity }.isEmpty)
    check("retrieve removes the exact bobber", missedBobber.dead)

    resetGameRng(46)
    let fishWorld = wildCoreWorld()
    prepareFishingWater(fishWorld)
    let fisher = wildProbe(fishWorld, "fisher")
    let rod = ItemStack(iid("fishing_rod"))
    let bobber = castFishingBobber(
        world: fishWorld, owner: fisher, rod: rod,
        originX: 0.5, originY: 64.25, originZ: 0.5, pitch: 0, yaw: 0
    )
    bobber.vx = 0; bobber.vy = 0; bobber.vz = 0
    var waited = 0
    var sawNibble = false
    while bobber.biteTime == 0 && waited < 25_000 {
        bobber.tick()
        if bobber.nibbling > 0 { sawNibble = true }
        waited += 1
    }
    let caught = bobber.retrieve()
    let caughtByID = Dictionary(uniqueKeysWithValues: fishWorld.entities.compactMap {
        ($0 as? ItemEntity).map { ($0.id, $0) }
    })
    check("real water ticks preserve nibble then bite timing",
          sawNibble && waited > 20 && waited < 25_000)
    check("bite retrieve uses real Core loot and exact ItemEntity IDs",
          caught.kind == .caughtLoot && !caught.spawnedItemEntityIDs.isEmpty
            && caught.spawnedItemEntityIDs.allSatisfy { caughtByID[$0] != nil }
            && caught.spawnedItemEntityIDs.count == Set(caught.spawnedItemEntityIDs).count)
    check("fishing retrieve creates canonical XP", (1...6).contains(caught.experienceAmount))
    let rodResult = damageItemStack(rod, amount: 1, random: { gameRng.nextFloat() })
    check("real rod uses canonical durability primitive",
          rodResult == .damaged && rod.damage == 1)

    resetGameRng(46)
    let trajectoryWorld = wildCoreWorld()
    for z in -2...2 {
        for x in 3...7 {
            trajectoryWorld.setBlock(x, 64, z, Int(cell(B.water)), SET_SILENT)
        }
    }
    let trajectoryActor = wildProbe(trajectoryWorld, "trajectory-fisher", x: 1.5)
    let trajectoryRod = ItemStack(iid("fishing_rod"))
    let trajectoryYaw = detAtan2(-(3.5 - trajectoryActor.x), 0.5 - trajectoryActor.z)
    let trajectoryBobber = castFishingBobber(
        world: trajectoryWorld, owner: trajectoryActor, rod: trajectoryRod,
        originX: trajectoryActor.x, originY: trajectoryActor.y + 0.8,
        originZ: trajectoryActor.z, pitch: degToRad(22), yaw: trajectoryYaw
    )
    var enteredTargetWater = false
    for _ in 0..<20 where !trajectoryBobber.dead && !enteredTargetWater {
        trajectoryBobber.tick()
        enteredTargetWater = (trajectoryWorld.getBlock(
            Int(floor(trajectoryBobber.x)), Int(floor(trajectoryBobber.y)),
            Int(floor(trajectoryBobber.z))
        ) >> 4) == Int(B.water)
    }
    check("real local cast trajectory enters physically revalidated water", enteredTargetWater)
    _ = trajectoryBobber.retrieve()

    resetGameRng(23)
    let huntWorld = wildCoreWorld(seed: 23)
    let hunter = wildProbe(huntWorld, "hunter")
    let chicken = Chicken(world: huntWorld)
    chicken.rng = RandomX(23)
    chicken.setPos(1.5, 64, 0.5)
    huntWorld.addEntity(chicken)
    let sword = ItemStack(iid("iron_sword"))
    let kill = executeActorMeleeAttack(
        attacker: hunter, heldItem: sword, target: chicken, random: { 1 }
    )
    let deathDrops = huntWorld.entities.compactMap { $0 as? ItemEntity }
    check("actor-neutral attack applies real health and death",
          kill.succeeded && kill.healthBefore == 4 && kill.healthAfter == 0 && kill.killed)
    check("hunter is the real final damaging actor",
          kill.attributedToAttacker && chicken.lastAttacker === hunter)
    check("chicken death exposes exact canonical drop IDs",
          !kill.spawnedItemEntityIDs.isEmpty
            && kill.spawnedItemEntityIDs == chicken.lastDeathDropItemEntityIDs
            && kill.spawnedItemEntityIDs.allSatisfy { id in deathDrops.contains { $0.id == id } }
            && deathDrops.contains { itemDef($0.stack.id).name == "chicken" })
    check("real weapon durability changes once", sword.damage == 1)
    let dropCount = deathDrops.count
    let duplicateKill = executeActorMeleeAttack(attacker: hunter, heldItem: sword, target: chicken)
    check("dead prey cannot produce a duplicate kill or drops",
          duplicateKill.status == .invalidActorOrTarget
            && huntWorld.entities.compactMap { $0 as? ItemEntity }.count == dropCount
            && sword.damage == 1)

    let conflictWorld = wildCoreWorld(seed: 24)
    let firstHunter = wildProbe(conflictWorld, "hunter-a", x: 0.5)
    let finalHunter = wildProbe(conflictWorld, "hunter-b", x: 1.0)
    let sharedChicken = Chicken(world: conflictWorld)
    sharedChicken.rng = RandomX(24)
    sharedChicken.setPos(1.5, 64, 0.5)
    conflictWorld.addEntity(sharedChicken)
    let firstHit = executeActorMeleeAttack(attacker: firstHunter, heldItem: nil, target: sharedChicken)
    sharedChicken.invulnTicks = 0
    let finalSword = ItemStack(iid("iron_sword"))
    let finalHit = executeActorMeleeAttack(attacker: finalHunter, heldItem: finalSword, target: sharedChicken)
    check("multi-agent hunt has one physical death and final-hit attribution",
          firstHit.succeeded && !firstHit.killed && finalHit.killed
            && finalHit.attributedToAttacker && sharedChicken.lastAttacker === finalHunter)
    check("multi-agent hunt exposes one bounded death-drop set",
          Set(finalHit.spawnedItemEntityIDs).count == finalHit.spawnedItemEntityIDs.count
            && executeActorMeleeAttack(
                attacker: firstHunter, heldItem: nil, target: sharedChicken
            ).spawnedItemEntityIDs.isEmpty)

    let staleWorld = wildCoreWorld(seed: 25)
    let staleHunter = wildProbe(staleWorld, "stale-hunter")
    let farChicken = Chicken(world: staleWorld)
    farChicken.setPos(20.5, 64, 0.5)
    staleWorld.addEntity(farChicken)
    let stale = executeActorMeleeAttack(attacker: staleHunter, heldItem: nil, target: farChicken)
    check("moved prey is revalidated at real reach", stale.status == .outOfReach && farChicken.health == 4)
    let unrelated = Chicken(world: staleWorld)
    unrelated.rng = RandomX(25)
    unrelated.setPos(1.5, 64, 0.5)
    staleWorld.addEntity(unrelated)
    _ = unrelated.hurt(10, "magic", nil)
    check("unrelated death has no hunter attribution", unrelated.deathTime > 0 && unrelated.lastAttacker == nil)

    let parityWorld = wildCoreWorld(seed: 26)
    let player = Player(world: parityWorld)
    player.setPos(0.5, 64, 0.5)
    player.onGround = false
    player.attackStrengthTicker = 100
    let playerSword = ItemStack(iid("iron_sword"))
    player.inventory[player.selectedSlot] = playerSword
    parityWorld.addEntity(player)
    let playerTarget = Chicken(world: parityWorld)
    playerTarget.rng = RandomX(260)
    playerTarget.setPos(1.5, 64, 0.5)
    parityWorld.addEntity(playerTarget)
    playerAttack(player, playerTarget)
    let agent = wildProbe(parityWorld, "parity-agent", x: 0.5, z: 2.5)
    let agentTarget = Chicken(world: parityWorld)
    agentTarget.rng = RandomX(260)
    agentTarget.setPos(1.5, 64, 2.5)
    parityWorld.addEntity(agentTarget)
    let agentSword = ItemStack(iid("iron_sword"))
    let actorParity = executeActorMeleeAttack(
        attacker: agent, heldItem: agentSword, target: agentTarget, random: { 1 }
    )
    check("Player base damage/death parity is preserved",
          playerTarget.health == actorParity.healthAfter && playerTarget.deathTime == agentTarget.deathTime)
    check("Player durability and cooldown semantics remain canonical",
          playerSword.damage == agentSword.damage && player.attackStrengthTicker == 0)

    resetGameRng(46)
    let gatherWorld = wildCoreWorld()
    gatherWorld.setBlock(0, 64, 0, Int(cell(B.sweet_berry_bush, 3)), SET_SILENT)
    let gathered = executeBlockBreak(
        BlockBreakRuleContext(world: gatherWorld, heldItem: nil, isCreative: false),
        0, 64, 0
    )
    let berryDrops = gatherWorld.entities.compactMap { $0 as? ItemEntity }
    check("mature wild berry bush uses canonical break and real food drops",
          gathered.status == .succeeded && gathered.spawnedItemEntityIDs == berryDrops.map(\.id)
            && berryDrops.contains {
                itemDef($0.stack.id).name == "sweet_berries" && itemDef($0.stack.id).food != nil
            })
    check("wild gather physically depletes the source", gatherWorld.getBlock(0, 64, 0) == 0)

    let growthWorld = wildCoreWorld()
    growthWorld.setBlock(0, 64, 0, Int(cell(B.sweet_berry_bush, 0)), SET_SILENT)
    growthWorld.getChunk(0, 0)!.setSky(0, 64, 0, 15)
    var growth = [0]
    for _ in 0..<2_000 where (growthWorld.getBlock(0, 64, 0) & 15) < 3 {
        randomTickHandlers[Int(B.sweet_berry_bush)]?(
            growthWorld, 0, 64, 0, growthWorld.getBlock(0, 64, 0)
        )
        let stage = growthWorld.getBlock(0, 64, 0) & 15
        if growth.last != stage { growth.append(stage) }
    }
    check("berry renewability is exclusively Core random-tick growth", growth == [0, 1, 2, 3])
}
