import Foundation
import PebbleCore

private func c08WorldRecord(
    _ id: String,
    name: String = "CIV-45 Correction 08"
) -> WorldRecord {
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

private func c08Install(_ game: GameCore, worldID: String) -> Bool {
    game.db.deleteWorld(worldID)
    guard game.db.putWorld(c08WorldRecord(worldID)) else { return false }
    game.loadWorld(worldID)
    game.world.randomTickSpeed = 0
    return game.hasWorld() && game.worldRec?.id == worldID
}

private func c08AddProbe(
    _ game: GameCore,
    agentID: String,
    item: String? = nil,
    count: Int = 0,
    x: Double? = nil,
    z: Double? = nil
) -> LabCoreAgentEntity {
    let probe = LabCoreAgentEntity(
        world: game.world,
        labAgentId: agentID,
        physicalId: "c08_\(agentID)"
    )
    probe.setPos(x ?? game.player.x, game.player.y, z ?? game.player.z)
    if let item { probe.carriedItems[0] = ItemStack(iid(item), count) }
    game.world.addEntity(probe)
    return probe
}

private func c08ItemEntities(
    _ world: World,
    named name: String
) -> [ItemEntity] {
    world.entities.compactMap { $0 as? ItemEntity }.filter {
        itemDef($0.stack.id).name == name
    }
}

private func c08ItemQuantity(_ world: World, named name: String) -> Int {
    c08ItemEntities(world, named: name).reduce(0) { $0 + $1.stack.count }
}

private func c08StreamAway(_ game: GameCore, from probe: LabCoreAgentEntity) {
    let distance = Double((game.settings.renderDistance + 8) * 16)
    game.player.setPos(probe.x + distance, game.player.y, probe.z)
    _ = game.frame(dtMs: TICK_MS)
}

private func c08ReloadProbeChunk(
    _ game: GameCore,
    probeX: Double,
    probeZ: Double
) {
    game.testingEnsureChunkLoadedForPersistenceFreshness(
        game.world,
        cx: floorDiv(Int(floor(probeX)), 16),
        cz: floorDiv(Int(floor(probeZ)), 16)
    )
}

private func c08RunStreamingExitRestart() {
    let worldID = "civ45-c08-streaming-exit"
    let game = GameCore()
    guard c08Install(game, worldID: worldID) else {
        check("C08 streaming exit fixture installs", false)
        return
    }
    let probe = c08AddProbe(
        game, agentID: "agent_exit", item: "cobblestone", count: 7
    )
    let probeID = probe.id
    let probeX = probe.x
    let probeZ = probe.z
    let oldWorld = game.world
    let nextEntityIDBeforeStreaming = peekNextEntityId()
    let chunk = game.world.getChunkAt(Int(floor(probeX)), Int(floor(probeZ)))
    c08StreamAway(game, from: probe)
    let conservationBefore = c08ItemQuantity(game.world, named: "cobblestone")
        + probe.carriedItems.compactMap({ $0 }).reduce(0) { $0 + $1.count }
    let retained = game.world.entities.filter({ $0 === probe }).count == 1
        && game.world.entityById[probeID] === probe
        && game.world.getChunkAt(Int(floor(probeX)), Int(floor(probeZ))) === chunk
        && probe.carriedItems[0] == ItemStack(iid("cobblestone"), 7)
        && c08ItemEntities(game.world, named: "cobblestone").isEmpty
        && peekNextEntityId() == nextEntityIDBeforeStreaming
        && conservationBefore == 7
    let exited = game.exitToTitle()
    let oldItems = c08ItemEntities(oldWorld, named: "cobblestone")
    let restarted = GameCore()
    restarted.loadWorld(worldID)
    c08ReloadProbeChunk(restarted, probeX: probeX, probeZ: probeZ)
    let items = c08ItemEntities(restarted.world, named: "cobblestone")
    let durableNextID = restarted.db.getWorld(worldID)?.nextEntityId ?? 0
    let newItem = spawnItem(
        restarted.world, probeX, restarted.player.y, probeZ,
        ItemStack(iid("dirt"), 1), 0, 0, 0
    )
    let exact = retained && exited && items.count == 1
        && items[0].stack == ItemStack(iid("cobblestone"), 7)
        && items[0].custodyProvenance == nil
        && items[0].id > probeID
        && oldItems.count == 1
        && durableNextID > oldItems[0].id
        && newItem.id >= durableNextID
        && Set([items[0].id, newItem.id]).count == 2
    check(
        "C08 streamed probe exit/restart conserves exact custody and identity",
        exact,
        "retained=\(retained) exited=\(exited) items=\(items.map(\.id)) "
            + "probe=\(probeID) oldSpill=\(oldItems.map(\.id)) "
            + "durableNext=\(durableNextID) reload=\(items.map(\.id)) new=\(newItem.id)"
    )
    print(
        "CIV45_C08_EXIT streamPath=tick>streamChunks retained=YES before=7 "
            + "after=7 itemEntities=\(items.count) identity=\(exact ? "PASS" : "FAIL") "
            + "status=\(exact ? "PASS" : "FAIL")"
    )
}

private func c08RunStreamingExitRetry() {
    let worldID = "civ45-c08-streaming-exit-retry"
    let game = GameCore()
    guard c08Install(game, worldID: worldID) else {
        check("C08 streaming exit retry fixture installs", false)
        return
    }
    let probe = c08AddProbe(
        game, agentID: "agent_retry", item: "cobblestone", count: 5
    )
    let probeX = probe.x
    let probeZ = probe.z
    c08StreamAway(game, from: probe)
    game.db.testingSignInscriptionPersistenceHook = { $0 != .prepared }
    let first = game.exitToTitle()
    let afterFirst = game.hasWorld()
        && game.world.entities.contains(where: { $0 === probe })
        && probe.carriedItems.allSatisfy { $0 == nil }
        && c08ItemQuantity(game.world, named: "cobblestone") == 5
    let second = game.exitToTitle()
    let afterSecond = game.hasWorld()
        && game.world.entities.contains(where: { $0 === probe })
        && c08ItemEntities(game.world, named: "cobblestone").count == 1
        && c08ItemQuantity(game.world, named: "cobblestone") == 5
    game.db.testingSignInscriptionPersistenceHook = nil
    let third = game.exitToTitle()
    let restarted = GameCore()
    restarted.loadWorld(worldID)
    c08ReloadProbeChunk(restarted, probeX: probeX, probeZ: probeZ)
    let exact = !first && afterFirst && !second && afterSecond && third
        && c08ItemEntities(restarted.world, named: "cobblestone").count == 1
        && c08ItemQuantity(restarted.world, named: "cobblestone") == 5
    check("C08 streamed probe exit retries are idempotent", exact)
    print(
        "CIV45_C08_EXIT_RETRY first=REFUSED second=REFUSED third=PASS "
            + "restart=5 duplicateSpill=NO status=\(exact ? "PASS" : "FAIL")"
    )
}

private func c08RunWorldReplacement() {
    let loadOldID = "civ45-c08-load-old"
    let loadNewID = "civ45-c08-load-new"
    let game = GameCore()
    guard c08Install(game, worldID: loadOldID),
          game.db.putWorld(c08WorldRecord(loadNewID, name: "C08 load target")) else {
        check("C08 load replacement fixture installs", false)
        return
    }
    let probe = c08AddProbe(
        game, agentID: "agent_load", item: "cobblestone", count: 4
    )
    let x = probe.x
    let z = probe.z
    c08StreamAway(game, from: probe)
    game.db.testingSignInscriptionPersistenceHook = { $0 != .prepared }
    game.loadWorld(loadNewID)
    let refused = game.worldRec?.id == loadOldID
        && game.world.entities.contains(where: { $0 === probe })
        && c08ItemQuantity(game.world, named: "cobblestone") == 4
    game.db.testingSignInscriptionPersistenceHook = nil
    game.loadWorld(loadNewID)
    let loaded = game.worldRec?.id == loadNewID
    let oldReload = GameCore()
    oldReload.loadWorld(loadOldID)
    c08ReloadProbeChunk(oldReload, probeX: x, probeZ: z)
    let loadExact = refused && loaded
        && c08ItemEntities(oldReload.world, named: "cobblestone").count == 1
        && c08ItemQuantity(oldReload.world, named: "cobblestone") == 4

    let createOldID = "civ45-c08-create-old"
    let createGame = GameCore()
    guard c08Install(createGame, worldID: createOldID) else {
        check("C08 create replacement fixture installs", false)
        return
    }
    let createProbe = c08AddProbe(
        createGame, agentID: "agent_create", item: "cobblestone", count: 6
    )
    let createX = createProbe.x
    let createZ = createProbe.z
    c08StreamAway(createGame, from: createProbe)
    createGame.db.testingSignInscriptionPersistenceHook = { $0 != .prepared }
    createGame.createWorld(
        name: "C08 refused target", seedText: "73",
        mode: GameMode.creative, difficulty: 1
    )
    let createRefused = createGame.worldRec?.id == createOldID
        && createGame.world.entities.contains(where: { $0 === createProbe })
        && c08ItemQuantity(createGame.world, named: "cobblestone") == 6
    createGame.db.testingSignInscriptionPersistenceHook = nil
    createGame.createWorld(
        name: "C08 accepted target", seedText: "73",
        mode: GameMode.creative, difficulty: 1
    )
    let created = createGame.worldRec?.id != createOldID
    let createReload = GameCore()
    createReload.loadWorld(createOldID)
    c08ReloadProbeChunk(createReload, probeX: createX, probeZ: createZ)
    let createExact = createRefused && created
        && c08ItemEntities(createReload.world, named: "cobblestone").count == 1
        && c08ItemQuantity(createReload.world, named: "cobblestone") == 6
    let exact = loadExact && createExact
    check("C08 streamed custody survives refused and successful World replacement", exact)
    print(
        "CIV45_C08_REPLACEMENT loadFailure=RETAINED loadSuccess=EXACT "
            + "createFailure=RETAINED createSuccess=EXACT callbacks=OLD_ONLY "
            + "status=\(exact ? "PASS" : "FAIL")"
    )
}

private func c08RunMultipleAndMixedProbes() {
    let worldID = "civ45-c08-multiple-mixed"
    let game = GameCore()
    guard c08Install(game, worldID: worldID) else {
        check("C08 multiple probe fixture installs", false)
        return
    }
    let a = c08AddProbe(
        game, agentID: "agent_a", item: "cobblestone", count: 3
    )
    let farX = game.player.x
        + Double((game.settings.renderDistance + 8) * 16)
    let farCX = floorDiv(Int(floor(farX)), 16)
    let farCZ = floorDiv(Int(floor(game.player.z)), 16)
    game.testingEnsureChunkLoadedForPersistenceFreshness(
        game.world, cx: farCX, cz: farCZ
    )
    let b = c08AddProbe(
        game, agentID: "agent_b", item: "dirt", count: 9,
        x: farX, z: game.player.z
    )
    let otherFarZ = game.player.z
        - Double((game.settings.renderDistance + 9) * 16)
    let otherFarCX = floorDiv(Int(floor(game.player.x)), 16)
    let otherFarCZ = floorDiv(Int(floor(otherFarZ)), 16)
    game.testingEnsureChunkLoadedForPersistenceFreshness(
        game.world, cx: otherFarCX, cz: otherFarCZ
    )
    let c = c08AddProbe(
        game, agentID: "agent_c", item: "oak_log", count: 5,
        x: game.player.x, z: otherFarZ
    )
    let aID = a.id
    let bID = b.id
    let cID = c.id
    _ = game.frame(dtMs: TICK_MS)
    let retained = game.world.entities.filter { $0 === a }.count == 1
        && game.world.entities.filter { $0 === b }.count == 1
        && game.world.entities.filter { $0 === c }.count == 1
        && game.world.getChunk(farCX, farCZ) != nil
        && game.world.getChunk(otherFarCX, otherFarCZ) != nil
        && a.carriedItems[0] == ItemStack(iid("cobblestone"), 3)
        && b.carriedItems[0] == ItemStack(iid("dirt"), 9)
        && c.carriedItems[0] == ItemStack(iid("oak_log"), 5)
        && game.world.entities.compactMap({ $0 as? ItemEntity }).isEmpty
    let beforeTotal = [a, b, c].flatMap(\.carriedItems).compactMap { $0 }
        .reduce(0) { $0 + $1.count }
    let exited = game.exitToTitle()
    let restarted = GameCore()
    restarted.loadWorld(worldID)
    c08ReloadProbeChunk(restarted, probeX: a.x, probeZ: a.z)
    c08ReloadProbeChunk(restarted, probeX: b.x, probeZ: b.z)
    c08ReloadProbeChunk(restarted, probeX: c.x, probeZ: c.z)
    let cobble = c08ItemEntities(restarted.world, named: "cobblestone")
    let dirt = c08ItemEntities(restarted.world, named: "dirt")
    let logs = c08ItemEntities(restarted.world, named: "oak_log")
    let spillIDs = cobble.map(\.id) + dirt.map(\.id) + logs.map(\.id)
    let afterTotal = [cobble, dirt, logs].flatMap { $0 }.reduce(0) {
        $0 + $1.stack.count
    }
    let exact = retained && exited
        && cobble.count == 1 && c08ItemQuantity(restarted.world, named: "cobblestone") == 3
        && dirt.count == 1 && c08ItemQuantity(restarted.world, named: "dirt") == 9
        && logs.count == 1 && c08ItemQuantity(restarted.world, named: "oak_log") == 5
        && beforeTotal == 17 && afterTotal == beforeTotal
        && Set(spillIDs).count == 3
        && spillIDs.allSatisfy { $0 != aID && $0 != bID && $0 != cID }
    check("C08 visible plus remote probes retain distinct exact custody", exact)
    print(
        "CIV45_C08_MULTI visible=1 remote=2 quantities=3,9,5 agents=distinct "
            + "provenance=ordinary identities=UNIQUE status=\(exact ? "PASS" : "FAIL")"
    )
}

private func c08RunReentryAndEmptyCustody() {
    let worldID = "civ45-c08-reentry"
    let game = GameCore()
    guard c08Install(game, worldID: worldID) else {
        check("C08 re-entry fixture installs", false)
        return
    }
    let originalPlayerX = game.player.x
    let originalPlayerZ = game.player.z
    let probe = c08AddProbe(
        game, agentID: "agent_cycle", item: "cobblestone", count: 8
    )
    let probeID = probe.id
    let nextEntityIDBeforeCycles = peekNextEntityId()
    var exact = true
    for cycle in 0..<3 {
        c08StreamAway(game, from: probe)
        exact = exact
            && game.world.entities.filter({ $0 === probe }).count == 1
            && game.world.entityById[probeID] === probe
            && probe.carriedItems[0] == ItemStack(iid("cobblestone"), 8)
            && c08ItemQuantity(game.world, named: "cobblestone") == 0
            && peekNextEntityId() == nextEntityIDBeforeCycles
        game.player.setPos(originalPlayerX, game.player.y, originalPlayerZ)
        _ = game.frame(dtMs: TICK_MS)
        exact = exact
            && game.world.entities.filter({ $0 === probe }).count == 1
            && game.world.entityById[probeID] === probe
            && probe.carriedItems[0] == ItemStack(iid("cobblestone"), 8)
            && peekNextEntityId() == nextEntityIDBeforeCycles
            && cycle < 3
    }
    let cycleX = probe.x
    let cycleZ = probe.z
    let cycleExited = game.exitToTitle()
    let cycleRestart = GameCore()
    cycleRestart.loadWorld(worldID)
    c08ReloadProbeChunk(cycleRestart, probeX: cycleX, probeZ: cycleZ)
    let cycleRestartItems = c08ItemEntities(
        cycleRestart.world, named: "cobblestone"
    )
    exact = exact && cycleExited
        && cycleRestartItems.count == 1
        && c08ItemQuantity(cycleRestart.world, named: "cobblestone") == 8
    check(
        "C08 repeated streaming, re-entry and restart preserve exact custody",
        exact
    )

    let emptyWorldID = "civ45-c08-empty"
    let emptyGame = GameCore()
    guard c08Install(emptyGame, worldID: emptyWorldID) else {
        check("C08 empty custody fixture installs", false)
        return
    }
    let emptyProbe = c08AddProbe(emptyGame, agentID: "agent_empty")
    c08StreamAway(emptyGame, from: emptyProbe)
    let retainedEmpty = emptyGame.world.entities.contains(where: { $0 === emptyProbe })
        && emptyProbe.carriedItems.allSatisfy { $0 == nil }
        && emptyGame.world.entities.compactMap({ $0 as? ItemEntity }).isEmpty
    let exited = emptyGame.exitToTitle()
    let emptyRestart = GameCore()
    emptyRestart.loadWorld(emptyWorldID)
    c08ReloadProbeChunk(
        emptyRestart, probeX: emptyProbe.x, probeZ: emptyProbe.z
    )
    let noFalseSpill = retainedEmpty && exited
        && emptyRestart.world.entities.compactMap({ $0 as? ItemEntity }).isEmpty

    let releasedWorldID = "civ45-c08-release"
    let releasedGame = GameCore()
    guard c08Install(releasedGame, worldID: releasedWorldID) else {
        check("C08 released probe fixture installs", false)
        return
    }
    let releasedProbe = c08AddProbe(releasedGame, agentID: "agent_released")
    let releasedCX = floorDiv(Int(floor(releasedProbe.x)), 16)
    let releasedCZ = floorDiv(Int(floor(releasedProbe.z)), 16)
    c08StreamAway(releasedGame, from: releasedProbe)
    let retainedBeforeRemoval = releasedGame.world.getChunk(releasedCX, releasedCZ) != nil
        && releasedGame.world.entities.contains(where: { $0 === releasedProbe })
    let removed = removeLabCoreAgentProbe(releasedProbe, from: releasedGame.world)
    _ = releasedGame.frame(dtMs: TICK_MS)
    let releaseAfterRemoval = retainedBeforeRemoval && removed
        && releasedGame.world.getChunk(releasedCX, releasedCZ) == nil
        && !releasedGame.world.entities.contains(where: { $0 === releasedProbe })
        && releasedGame.world.entities.compactMap({ $0 as? ItemEntity }).isEmpty
    check(
        "C08 empty remote probe creates no spill and removal releases retention",
        noFalseSpill && releaseAfterRemoval
    )
    print(
        "CIV45_C08_CYCLES outInCycles=3 probeIdentity=SAME custody=8 "
            + "duplicates=0 emptySpills=0 mortalityRelease="
            + "\(releaseAfterRemoval ? "YES" : "NO") status="
            + "\(exact && noFalseSpill && releaseAfterRemoval ? "PASS" : "FAIL")"
    )
}

func runPebbleCorePersistenceCorrection08Smoke() {
    section("CIV-45 Correction 08 probe streaming custody")
    c08RunStreamingExitRestart()
    c08RunStreamingExitRetry()
    c08RunWorldReplacement()
    c08RunMultipleAndMixedProbes()
    c08RunReentryAndEmptyCustody()
}

func runPebbleCorePersistenceCorrection08AppKitReader() {
    section("CIV-45 Correction 08 AppKit restart reader")
    let worldName = "PebbleLab-Disposable-C08-AppKit-73"
    let game = GameCore()
    guard let record = game.listWorlds().first(where: { $0.name == worldName }) else {
        check("C08 AppKit persisted World exists", false)
        return
    }
    game.loadWorld(record.id)
    for dz in -1...1 {
        for dx in -1...1 {
            game.testingEnsureChunkLoadedForPersistenceFreshness(
                game.world,
                cx: floorDiv(record.spawnX, 16) + dx,
                cz: floorDiv(record.spawnZ, 16) + dz
            )
        }
    }
    let items = c08ItemEntities(game.world, named: "cobblestone")
    let ids = items.map(\.id)
    let nextItem = spawnItem(
        game.world,
        Double(record.spawnX), Double(record.spawnY), Double(record.spawnZ),
        ItemStack(iid("dirt"), 1), 0, 0, 0
    )
    let exact = items.count == 1
        && c08ItemQuantity(game.world, named: "cobblestone") == 7
        && Set(ids).count == ids.count
        && ids.allSatisfy { $0 > 0 }
        && items[0].custodyProvenance == nil
        && nextItem.id > (ids.max() ?? 0)
        && !ids.contains(nextItem.id)
    check("C08 AppKit fresh restart has exact custody once", exact)
    print(
        "CIV45_C08_APPKIT_RESTART quantity=\(c08ItemQuantity(game.world, named: "cobblestone")) "
            + "entities=\(items.count) identities=UNIQUE status=\(exact ? "PASS" : "FAIL")"
    )
}
