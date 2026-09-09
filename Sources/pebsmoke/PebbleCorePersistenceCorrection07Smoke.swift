import Foundation
import PebbleCore

private func c07WorldRecord(_ id: String, name: String = "CIV-45 Correction 07") -> WorldRecord {
    var record = WorldRecord(
        id: id,
        name: name,
        seed: 73,
        gameMode: GameMode.creative,
        difficulty: 1
    )
    record.spawnX = 1
    record.spawnY = 65
    record.spawnZ = 1
    record.nextEntityId = 1
    return record
}

private func c07Install(_ game: GameCore, worldID: String) -> Bool {
    game.db.deleteWorld(worldID)
    game.db.putWorld(c07WorldRecord(worldID))
    game.loadWorld(worldID)
    return game.hasWorld() && game.worldRec?.id == worldID
}

private func c07ItemCount(_ world: World, named name: String) -> Int {
    world.entities.compactMap { $0 as? ItemEntity }.reduce(0) { total, item in
        total + (itemDef(item.stack.id).name == name ? item.stack.count : 0)
    }
}

private func c07ClearResidentDirtyState(_ game: GameCore) {
    for world in game.worlds.values {
        for chunk in world.chunks.values { chunk.modified = false }
    }
}

private func c07AddCarryingProbe(
    _ game: GameCore,
    agentID: String,
    item: String,
    count: Int
) -> LabCoreAgentEntity {
    let probe = LabCoreAgentEntity(
        world: game.world,
        labAgentId: agentID,
        physicalId: "probe_\(agentID)"
    )
    probe.setPos(game.player.x, game.player.y, game.player.z)
    probe.carriedItems[0] = ItemStack(iid(item), count)
    game.world.addEntity(probe)
    return probe
}

private func c07RunExitCleanupDurability() {
    let worldID = "civ45-c07-exit-cleanup"
    let game = GameCore()
    guard c07Install(game, worldID: worldID) else {
        check("C07 exit cleanup fixture installs", false)
        return
    }
    c07ClearResidentDirtyState(game)
    let oldWorld = game.world
    let probe = c07AddCarryingProbe(
        game, agentID: "agent_exit", item: "cobblestone", count: 3
    )
    let exited = game.exitToTitle()
    let finalPhysicalState = exited
        && !oldWorld.entities.contains(where: { $0 === probe })
        && c07ItemCount(oldWorld, named: "cobblestone") == 3
    let restarted = GameCore()
    restarted.loadWorld(worldID)
    let restartCount = c07ItemCount(restarted.world, named: "cobblestone")
    check("C07 exit cleanup is inside final durable barrier",
          finalPhysicalState && restartCount == 3)
    print("CIV45_C07_EXIT cleanupBeforeBarrier=YES spillDurable=\(restartCount == 3 ? "YES" : "NO") status=\(finalPhysicalState && restartCount == 3 ? "PASS" : "FAIL")")
}

private func c07RunRepeatedExitAttempts() {
    let worldID = "civ45-c07-repeated-exit"
    let game = GameCore()
    guard c07Install(game, worldID: worldID) else {
        check("C07 repeated exit fixture installs", false)
        return
    }
    c07ClearResidentDirtyState(game)
    let probe = c07AddCarryingProbe(
        game, agentID: "agent_retry", item: "cobblestone", count: 4
    )
    game.db.testingSignInscriptionPersistenceHook = { phase in phase != .prepared }
    let first = game.exitToTitle()
    let firstCoherent = !first && game.hasWorld()
        && game.world.entities.contains(where: { $0 === probe })
        && probe.carriedItems.allSatisfy { $0 == nil }
        && c07ItemCount(game.world, named: "cobblestone") == 4
    let second = game.exitToTitle()
    let secondCoherent = !second && game.hasWorld()
        && game.world.entities.contains(where: { $0 === probe })
        && c07ItemCount(game.world, named: "cobblestone") == 4
    game.db.testingSignInscriptionPersistenceHook = nil
    let third = game.exitToTitle()
    let restarted = GameCore()
    restarted.loadWorld(worldID)
    let restartCount = c07ItemCount(restarted.world, named: "cobblestone")
    check("C07 repeated exit attempts do not duplicate custody spill",
          firstCoherent && secondCoherent && third && restartCount == 4)
    print("CIV45_C07_EXIT_RETRY first=REFUSED second=REFUSED third=PASS "
        + "liveSpillAfterFirst=4 liveSpillAfterSecond="
        + "\(secondCoherent ? 4 : -1) restartSpill=\(restartCount) duplicateSpill=NO "
        + "status=\(firstCoherent && secondCoherent && third && restartCount == 4 ? "PASS" : "FAIL")")
}

private func c07RunWorldReplacementCleanup() {
    let oldWorldID = "civ45-c07-replacement-old"
    let newWorldID = "civ45-c07-replacement-new"
    let game = GameCore()
    guard c07Install(game, worldID: oldWorldID) else {
        check("C07 replacement fixture installs", false)
        return
    }
    game.db.deleteWorld(newWorldID)
    game.db.putWorld(c07WorldRecord(newWorldID, name: "C07 replacement target"))
    c07ClearResidentDirtyState(game)
    let oldWorld = game.world
    let probe = c07AddCarryingProbe(
        game, agentID: "agent_replace", item: "cobblestone", count: 5
    )
    game.db.testingSignInscriptionPersistenceHook = { phase in phase != .prepared }
    game.loadWorld(newWorldID)
    let refused = game.worldRec?.id == oldWorldID
        && oldWorld.entities.contains(where: { $0 === probe })
        && probe.carriedItems.allSatisfy { $0 == nil }
        && c07ItemCount(oldWorld, named: "cobblestone") == 5
    game.db.testingSignInscriptionPersistenceHook = nil
    game.loadWorld(newWorldID)
    let replaced = game.worldRec?.id == newWorldID
        && !oldWorld.entities.contains(where: { $0 === probe })
    let restartedOld = GameCore()
    restartedOld.loadWorld(oldWorldID)
    let oldRestartCount = c07ItemCount(restartedOld.world, named: "cobblestone")
    check("C07 World load replacement retains then durably closes old World",
          refused && replaced && oldRestartCount == 5)

    let createOldID = "civ45-c07-create-old"
    let createGame = GameCore()
    guard c07Install(createGame, worldID: createOldID) else {
        check("C07 create replacement fixture installs", false)
        return
    }
    c07ClearResidentDirtyState(createGame)
    let createOldWorld = createGame.world
    _ = c07AddCarryingProbe(
        createGame, agentID: "agent_create", item: "cobblestone", count: 6
    )
    createGame.createWorld(
        name: "C07 created target", seedText: "73",
        mode: GameMode.creative, difficulty: 1
    )
    let created = createGame.worldRec?.id != createOldID
        && c07ItemCount(createOldWorld, named: "cobblestone") == 6
    let restartedCreateOld = GameCore()
    restartedCreateOld.loadWorld(createOldID)
    let createRestartCount = c07ItemCount(
        restartedCreateOld.world, named: "cobblestone"
    )
    check("C07 World creation replacement persists old final physical state",
          created && createRestartCount == 6)
    print("CIV45_C07_REPLACEMENT failedSwitch=REFUSED oldWorldRetained=YES "
        + "loadRetry=PASS loadRestartSpill=\(oldRestartCount) create=PASS "
        + "createRestartSpill=\(createRestartCount) status="
        + "\(refused && replaced && oldRestartCount == 5 && created && createRestartCount == 6 ? "PASS" : "FAIL")")
}

private func c07StoredPlayerXP(_ game: GameCore, worldID: String) -> Int? {
    guard let outer = game.db.getPlayer(worldID),
          let data = outer["data"] as? [String: Any] else { return nil }
    return (data["xpLevel"] as? NSNumber)?.intValue
}

private func c07RunRequiredWriteFailure(_ failedWrite: RequiredPersistenceWrite) {
    let worldID = "civ45-c07-required-\(failedWrite.rawValue)"
    let game = GameCore()
    guard c07Install(game, worldID: worldID), game.saveAndFlush(synchronous: true) else {
        check("C07 \(failedWrite.rawValue) failure fixture installs", false)
        return
    }
    c07ClearResidentDirtyState(game)
    let durableTime = game.db.getWorld(worldID)?.dims["0"]?.time ?? 0
    let durableXP = c07StoredPlayerXP(game, worldID: worldID) ?? 0
    game.world.time = durableTime + 100 + failedWrite.rawValue.count
    game.player.xpLevel = durableXP + 7
    _ = game.advancements.grant("root")
    var failedCalls = 0
    game.db.testingRequiredPersistenceWriteHook = { write in
        if write == failedWrite {
            failedCalls += 1
            return false
        }
        return true
    }
    let first = game.prepareForTermination()
    let retained = game.hasWorld()
    let zeroChunks = game.testingLastSubmittedChunkRecordCount == 0
    game.db.testingRequiredPersistenceWriteHook = nil
    let retry = game.prepareForTermination()
    let completed = retry && game.completePreparedLifecycle()
    let restarted = GameCore()
    restarted.loadWorld(worldID)
    let converged = restarted.world.time == game.world.time
        && restarted.player.xpLevel == game.player.xpLevel
        && restarted.advancements.has("root")
    let passed = !first && retained && zeroChunks && failedCalls == 1
        && completed && converged
    check("C07 \(failedWrite.rawValue) failure propagates and retry converges", passed)
    print("CIV45_C07_REQUIRED write=\(failedWrite.rawValue) chunkRecords=0 "
        + "first=FAIL WorldRetained=\(retained ? "YES" : "NO") retry=PASS "
        + "restart=EXACT status=\(passed ? "PASS" : "FAIL")")
}

private func c07RunMixedRequiredWriteFailure() {
    let worldID = "civ45-c07-required-mixed"
    let game = GameCore()
    guard c07Install(game, worldID: worldID), game.saveAndFlush(synchronous: true) else {
        check("C07 mixed failure fixture installs", false)
        return
    }
    c07ClearResidentDirtyState(game)
    let newTime = game.world.time + 333
    game.world.time = newTime
    game.player.xpLevel = 12
    _ = game.advancements.grant("root")
    var calls: [RequiredPersistenceWrite] = []
    game.db.testingRequiredPersistenceWriteHook = { write in
        calls.append(write)
        return write != .player
    }
    let barrier = game.prepareForTermination()
    let partialIsExplicit = game.db.getWorld(worldID)?.dims["0"]?.time == newTime
        && c07StoredPlayerXP(game, worldID: worldID) != 12
        && game.db.getAdvancements(worldID)?.contains("root") == true
        && game.testingLastSubmittedChunkRecordCount == 0
    game.db.testingRequiredPersistenceWriteHook = nil
    let retry = game.prepareForTermination()
    let completed = retry && game.completePreparedLifecycle()
    let restarted = GameCore()
    restarted.loadWorld(worldID)
    let converged = restarted.world.time == newTime
        && restarted.player.xpLevel == 12
        && restarted.advancements.has("root")
    let allWritesAttempted = calls == [.world, .player, .advancements]
    let passed = !barrier && game.hasWorld() && partialIsExplicit
        && allWritesAttempted && completed && converged
    check("C07 mixed partial required-write failure is fail-closed", passed)
    print("CIV45_C07_MIXED world=SUCCESS player=FAIL advancements=SUCCESS "
        + "chunks=EMPTY barrier=FAIL retry=PASS restart=EXACT status="
        + "\(passed ? "PASS" : "FAIL")")
}

func runPebbleCorePersistenceCorrection07Smoke() {
    section("CIV-45 Correction 07 lifecycle persistence boundaries")
    c07RunExitCleanupDurability()
    c07RunRepeatedExitAttempts()
    c07RunWorldReplacementCleanup()
    c07RunRequiredWriteFailure(.world)
    c07RunRequiredWriteFailure(.player)
    c07RunRequiredWriteFailure(.advancements)
    c07RunMixedRequiredWriteFailure()
}
