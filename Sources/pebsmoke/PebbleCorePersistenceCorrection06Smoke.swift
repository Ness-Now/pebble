import Foundation
import PebbleCore

private let c06DurableLines = ["durable", "old", "state", "A"]
private let c06CurrentLines = ["current", "new", "state", "B"]

private func c06WorldRecord(_ id: String) -> WorldRecord {
    var record = WorldRecord(
        id: id,
        name: "CIV-45 Correction 06",
        seed: 46,
        gameMode: 1,
        difficulty: 1
    )
    record.spawnX = 1
    record.spawnY = 65
    record.spawnZ = 1
    record.nextEntityId = 1
    return record
}

private func c06ChunkRecord(database: SaveDB, worldID: String, lines: [String]) -> ChunkRecord {
    let chunk = Chunk(cx: 0, cz: 0, minY: GEN_MIN_Y, height: WORLD_H)
    chunk.set(1, 63, 1, UInt16(bid("stone")) << 4)
    chunk.set(1, 64, 1, UInt16(bid("oak_sign")) << 4)
    let sign = makeSignBE(1, 64, 1)
    sign.lines = lines
    return ChunkRecord(
        key: database.chunkKey(worldID, 0, 0, 0),
        worldId: worldID,
        dim: 0,
        cx: 0,
        cz: 0,
        blocks: chunk.blocks,
        biomes: chunk.biomes,
        blockEntities: [sign]
    )
}

private func c06Lines(_ record: ChunkRecord?) -> [String]? {
    record?.blockEntities?.first(where: { $0.x == 1 && $0.y == 64 && $0.z == 1 })?.lines
}

private func c06Wait(_ condition: () -> Bool) -> Bool {
    let deadline = Date(timeIntervalSinceNow: 5)
    while Date() < deadline {
        if condition() { return true }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
    }
    return condition()
}

private func c06RunReturnBeforeResolution(expectHistoricalRewind: Bool) {
    let game = GameCore()
    let record = c06WorldRecord("civ45-c06-return-before-resolution")
    game.db.deleteWorld(record.id)
    game.db.putWorld(record)
    guard game.db.putChunks([
        c06ChunkRecord(database: game.db, worldID: record.id, lines: c06DurableLines)
    ]) else {
        check("C06 durable A fixture persists", false)
        return
    }
    game.loadWorld(record.id)
    guard let sign = game.world.getBlockEntity(1, 64, 1),
          let chunk = game.world.getChunk(0, 0) else {
        check("C06 durable A fixture loads", false)
        return
    }

    sign.lines = c06CurrentLines
    chunk.modified = true
    game.player.setPos(10_000.5, 80, 10_000.5)
    guard game.testingUnloadChunkForPersistenceFreshness(game.world, cx: 0, cz: 0) else {
        check("C06 legitimate unload executes production path", false)
        return
    }
    let key = game.db.chunkKey(record.id, 0, 0, 0)
    let captureB = game.testingPendingChunkSaveSequence(key: key)
    check("C06 legitimate unload captures newer B", captureB != nil
        && c06Lines(game.testingPendingChunkSaveRecord(key: key)) == c06CurrentLines)

    let prepared = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    let failed = DispatchSemaphore(value: 0)
    let recovered = DispatchSemaphore(value: 0)
    let lock = NSLock()
    var failFirst = true
    game.db.testingSignInscriptionPersistenceHook = { phase in
        lock.lock()
        let fail = failFirst
        lock.unlock()
        if fail && phase == .prepared {
            prepared.signal()
            _ = release.wait(timeout: .now() + 5)
            return false
        }
        if fail && phase == .failed { failed.signal() }
        return true
    }
    game.testingSignInscriptionSaveRecoveryHook = { _ in recovered.signal() }

    game.saveAndFlush(synchronous: false)
    guard prepared.wait(timeout: .now() + 5) == .success else {
        check("C06 B becomes in-flight", false)
        return
    }
    check("C06 pending map is empty while B is unresolved",
          game.testingPendingChunkSaveRecord(key: key) == nil
            && game.testingLatestChunkSaveSequence(key: key) == captureB)

    game.player.setPos(1.5, 65, 1.5)
    game.testingRequestChunkForPersistenceFreshness(game.world, cx: 0, cz: 0)
    guard c06Wait({ game.world.getChunk(0, 0) != nil }) else {
        check("C06 return streams target chunk before B resolves", false)
        release.signal()
        return
    }
    let residentBeforeFailure = game.world.getBlockEntity(1, 64, 1)?.lines
    let expectedResident = expectHistoricalRewind ? c06DurableLines : c06CurrentLines
    check("C06 return cannot adopt stale durable A", residentBeforeFailure == expectedResident,
          "resident=\(residentBeforeFailure ?? []) expected=\(expectedResident)")

    release.signal()
    guard failed.wait(timeout: .now() + 5) == .success,
          c06Wait({ recovered.wait(timeout: .now()) == .success }) else {
        check("C06 in-flight B failure recovers after return", false)
        return
    }
    lock.lock()
    failFirst = false
    lock.unlock()
    game.db.testingSignInscriptionPersistenceHook = nil
    game.testingSignInscriptionSaveRecoveryHook = nil

    _ = game.saveAndFlush(synchronous: true)
    let durable = c06Lines(game.db.getChunk(record.id, 0, 0, 0))
    let restarted = GameCore()
    restarted.loadWorld(record.id)
    let restart = c06Lines(restarted.db.getChunk(record.id, 0, 0, 0))
    let expectedFinal = expectHistoricalRewind ? c06DurableLines : c06CurrentLines
    check("C06 retry durability keeps causal winner", durable == expectedFinal)
    check("C06 restart keeps causal winner", restart == expectedFinal)
    let status = expectHistoricalRewind ? "REPRODUCED" : "PASS"
    print("CIV45_C06_RETURN pendingEmpty=YES inFlight=B resident="
        + (residentBeforeFailure == c06CurrentLines ? "B" : "A")
        + " durable=" + (durable == c06CurrentLines ? "B" : "A")
        + " restart=" + (restart == c06CurrentLines ? "B" : "A")
        + " status=\(status)")
}

private func c06LoadedLines(_ game: GameCore) -> [String]? {
    game.world.getBlockEntity(1, 64, 1)?.lines
}

private func c06Install(
    _ game: GameCore,
    worldID: String,
    durableLines: [String]
) -> Bool {
    game.db.deleteWorld(worldID)
    let record = c06WorldRecord(worldID)
    game.db.putWorld(record)
    guard game.db.putChunks([
        c06ChunkRecord(database: game.db, worldID: worldID, lines: durableLines)
    ]) else { return false }
    game.loadWorld(worldID)
    return game.hasWorld() && c06LoadedLines(game) == durableLines
}

private func c06RunSuccessAfterReturn() {
    let game = GameCore()
    let worldID = "civ45-c06-success-after-return"
    guard c06Install(game, worldID: worldID, durableLines: c06DurableLines),
          let sign = game.world.getBlockEntity(1, 64, 1),
          let chunk = game.world.getChunk(0, 0) else {
        check("C06 success fixture loads", false)
        return
    }
    sign.lines = c06CurrentLines
    chunk.modified = true
    game.player.setPos(10_000.5, 80, 10_000.5)
    guard game.testingUnloadChunkForPersistenceFreshness(game.world, cx: 0, cz: 0) else {
        check("C06 success unload", false)
        return
    }
    let key = game.db.chunkKey(worldID, 0, 0, 0)
    let sequenceB = game.testingPendingChunkSaveSequence(key: key)
    let prepared = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    let committed = DispatchSemaphore(value: 0)
    game.db.testingSignInscriptionPersistenceHook = { phase in
        if phase == .prepared {
            prepared.signal()
            _ = release.wait(timeout: .now() + 5)
        }
        if phase == .authorityAdvanced { committed.signal() }
        return true
    }
    _ = game.saveAndFlush(synchronous: false)
    guard prepared.wait(timeout: .now() + 5) == .success else {
        check("C06 success B reaches worker", false)
        return
    }
    game.player.setPos(1.5, 65, 1.5)
    game.testingRequestChunkForPersistenceFreshness(game.world, cx: 0, cz: 0)
    let returnedB = c06Wait { c06LoadedLines(game) == c06CurrentLines }
    check("C06 successful in-flight B is resident before commit", returnedB
        && game.testingPendingChunkSaveRecord(key: key) == nil
        && game.testingUnresolvedChunkSaveSequence(key: key) == sequenceB)
    release.signal()
    let didCommit = committed.wait(timeout: .now() + 5) == .success
        && c06Wait { game.testingUnresolvedChunkSaveRecord(key: key) == nil }
    game.db.testingSignInscriptionPersistenceHook = nil
    check("C06 successful B commit converges resident and SQLite", didCommit
        && c06LoadedLines(game) == c06CurrentLines
        && c06Lines(game.db.getChunk(worldID, 0, 0, 0)) == c06CurrentLines)
    let restarted = GameCore()
    restarted.loadWorld(worldID)
    restarted.player.setPos(1.5, 65, 1.5)
    restarted.testingRequestChunkForPersistenceFreshness(restarted.world, cx: 0, cz: 0)
    _ = c06Wait { restarted.world.getChunk(0, 0) != nil }
    let restartedLines = c06LoadedLines(restarted)
    check("C06 successful B survives fresh GameCore", restartedLines == c06CurrentLines,
          "resident=\(restartedLines ?? []) durable=\(c06Lines(restarted.db.getChunk(worldID, 0, 0, 0)) ?? [])")
    print("CIV45_C06_SUCCESS pendingEmpty=YES residentBeforeCommit=B durable=B restart=B status=PASS")
}

private func c06RunDeletionOrEdit(delete: Bool) {
    let label = delete ? "DELETE" : "EDIT"
    let worldID = "civ45-c06-" + label.lowercased()
    let editedLines = ["external", "newer", "edit", "B"]
    let game = GameCore()
    guard c06Install(game, worldID: worldID, durableLines: c06DurableLines),
          let chunk = game.world.getChunk(0, 0) else {
        check("C06 \(label) fixture loads", false)
        return
    }
    if delete {
        _ = game.world.setBlock(1, 64, 1, 0)
    } else {
        game.world.getBlockEntity(1, 64, 1)?.lines = editedLines
        chunk.modified = true
    }
    game.player.setPos(10_000.5, 80, 10_000.5)
    guard game.testingUnloadChunkForPersistenceFreshness(game.world, cx: 0, cz: 0) else {
        check("C06 \(label) unload", false)
        return
    }
    let key = game.db.chunkKey(worldID, 0, 0, 0)
    let prepared = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    let failed = DispatchSemaphore(value: 0)
    game.db.testingSignInscriptionPersistenceHook = { phase in
        if phase == .prepared {
            prepared.signal()
            _ = release.wait(timeout: .now() + 5)
            return false
        }
        if phase == .failed { failed.signal() }
        return true
    }
    _ = game.saveAndFlush(synchronous: false)
    guard prepared.wait(timeout: .now() + 5) == .success else {
        check("C06 \(label) B reaches worker", false)
        return
    }
    game.player.setPos(1.5, 65, 1.5)
    game.testingRequestChunkForPersistenceFreshness(game.world, cx: 0, cz: 0)
    let returned = c06Wait {
        guard game.world.getChunk(0, 0) != nil else { return false }
        return delete
            ? game.world.getBlockEntity(1, 64, 1) == nil
            : c06LoadedLines(game) == editedLines
    }
    check("C06 \(label) return cannot resurrect A", returned
        && game.testingPendingChunkSaveRecord(key: key) == nil
        && game.testingUnresolvedChunkSaveRecord(key: key) != nil)
    release.signal()
    guard failed.wait(timeout: .now() + 5) == .success else {
        check("C06 \(label) injected failure observed", false)
        return
    }
    game.db.testingSignInscriptionPersistenceHook = nil
    let retried = game.saveAndFlush(synchronous: true)
    let durable = game.db.getChunk(worldID, 0, 0, 0)
    let durableWins = delete
        ? durable?.blockEntities?.first(where: { $0.x == 1 && $0.y == 64 && $0.z == 1 }) == nil
        : c06Lines(durable) == editedLines
    let restarted = GameCore()
    restarted.loadWorld(worldID)
    let restartWins = delete
        ? restarted.world.getBlockEntity(1, 64, 1) == nil
        : c06LoadedLines(restarted) == editedLines
    check("C06 \(label) failure retry keeps B durable", retried && durableWins)
    check("C06 \(label) restart keeps B", restartWins)
    print("CIV45_C06_\(label) pendingEmpty=YES resident=B retry=B restart=B status=PASS")
}

private func c06RunMultipleGenerations() {
    let worldID = "civ45-c06-generations"
    let linesB = ["newer", "state", "generation", "B"]
    let linesC = ["newest", "state", "generation", "C"]
    let game = GameCore()
    guard c06Install(game, worldID: worldID, durableLines: c06DurableLines),
          let chunkA = game.world.getChunk(0, 0) else {
        check("C06 generations fixture loads", false)
        return
    }
    game.world.getBlockEntity(1, 64, 1)?.lines = linesB
    chunkA.modified = true
    game.player.setPos(10_000.5, 80, 10_000.5)
    _ = game.testingUnloadChunkForPersistenceFreshness(game.world, cx: 0, cz: 0)
    let key = game.db.chunkKey(worldID, 0, 0, 0)
    let sequenceB = game.testingPendingChunkSaveSequence(key: key)
    let prepared = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    let failed = DispatchSemaphore(value: 0)
    game.db.testingSignInscriptionPersistenceHook = { phase in
        if phase == .prepared {
            prepared.signal()
            _ = release.wait(timeout: .now() + 5)
            return false
        }
        if phase == .failed { failed.signal() }
        return true
    }
    _ = game.saveAndFlush(synchronous: false)
    guard prepared.wait(timeout: .now() + 5) == .success else {
        check("C06 generations B reaches worker", false)
        return
    }
    game.player.setPos(1.5, 65, 1.5)
    game.testingRequestChunkForPersistenceFreshness(game.world, cx: 0, cz: 0)
    guard c06Wait({ c06LoadedLines(game) == linesB }),
          let chunkB = game.world.getChunk(0, 0) else {
        check("C06 generations streams B", false)
        return
    }
    game.world.getBlockEntity(1, 64, 1)?.lines = linesC
    chunkB.modified = true
    game.player.setPos(10_000.5, 80, 10_000.5)
    _ = game.testingUnloadChunkForPersistenceFreshness(game.world, cx: 0, cz: 0)
    let sequenceC = game.testingPendingChunkSaveSequence(key: key)
    game.player.setPos(1.5, 65, 1.5)
    game.testingRequestChunkForPersistenceFreshness(game.world, cx: 0, cz: 0)
    let residentC = c06Wait { c06LoadedLines(game) == linesC }
    check("C06 maximum unresolved generation C wins streaming", residentC
        && sequenceB != nil && sequenceC != nil && sequenceB! < sequenceC!
        && game.testingUnresolvedChunkSaveSequence(key: key) == sequenceC)
    // Preserve C's original causal age for the retry assertion.
    game.world.getChunk(0, 0)?.modified = false
    release.signal()
    guard failed.wait(timeout: .now() + 5) == .success else {
        check("C06 generations older B failure observed", false)
        return
    }
    game.db.testingSignInscriptionPersistenceHook = nil
    let retried = game.saveAndFlush(synchronous: true)
    check("C06 older B failure cannot regress pending C", retried
        && c06Lines(game.db.getChunk(worldID, 0, 0, 0)) == linesC)
    let restarted = GameCore()
    restarted.loadWorld(worldID)
    check("C06 generation C survives restart", c06LoadedLines(restarted) == linesC)
    print("CIV45_C06_GENERATIONS A=durable B=unresolved C=max resident=C durable=C restart=C status=PASS")
}

private func c06RunExitLifecycle() {
    let worldID = "civ45-c06-exit-lifecycle"
    let game = GameCore()
    guard c06Install(game, worldID: worldID, durableLines: c06DurableLines),
          let chunk = game.world.getChunk(0, 0) else {
        check("C06 exit fixture loads", false)
        return
    }
    game.world.getBlockEntity(1, 64, 1)?.lines = c06CurrentLines
    chunk.modified = true
    game.db.testingSignInscriptionPersistenceHook = { phase in phase != .prepared }
    let refused = !game.exitToTitle()
    let key = game.db.chunkKey(worldID, 0, 0, 0)
    check("C06 exitToTitle refuses persistent failure", refused
        && game.hasWorld()
        && game.worldRec?.id == worldID
        && game.testingUnresolvedChunkSaveRecord(key: key) != nil)
    game.db.testingSignInscriptionPersistenceHook = nil
    let exited = game.exitToTitle()
    check("C06 exitToTitle retries before World destruction", exited
        && !game.hasWorld()
        && c06Lines(game.db.getChunk(worldID, 0, 0, 0)) == c06CurrentLines)
    print("CIV45_C06_EXIT failure=retained firstExit=REFUSED retry=COMMITTED destruction=SAFE status=PASS")
}

private func c06RunTerminationLifecycle() {
    let worldID = "civ45-c06-termination-lifecycle"
    let game = GameCore()
    guard c06Install(game, worldID: worldID, durableLines: c06DurableLines),
          let chunk = game.world.getChunk(0, 0) else {
        check("C06 termination fixture loads", false)
        return
    }
    game.world.getBlockEntity(1, 64, 1)?.lines = c06CurrentLines
    chunk.modified = true
    game.db.testingSignInscriptionPersistenceHook = { phase in phase != .prepared }
    let ready = game.prepareForTermination()
    let key = game.db.chunkKey(worldID, 0, 0, 0)
    check("C06 termination preparation reports failure synchronously", !ready
        && game.hasWorld()
        && game.testingUnresolvedChunkSaveRecord(key: key) != nil)
    game.db.testingSignInscriptionPersistenceHook = nil
    let retried = game.prepareForTermination()
    check("C06 termination preparation becomes safe only after commit", retried
        && game.testingUnresolvedChunkSaveRecord(key: key) == nil
        && c06Lines(game.db.getChunk(worldID, 0, 0, 0)) == c06CurrentLines)
    print("CIV45_C06_TERMINATION firstReply=CANCEL retryReply=NOW unresolved=ZERO status=PASS")
}

private func c06RunWorldSwitchLifecycle() {
    let oldWorldID = "civ45-c06-world-switch-old"
    let newWorldID = "civ45-c06-world-switch-new"
    let newLines = ["separate", "world", "state", "two"]
    let game = GameCore()
    guard c06Install(game, worldID: oldWorldID, durableLines: c06DurableLines),
          let oldChunk = game.world.getChunk(0, 0) else {
        check("C06 World switch old fixture loads", false)
        return
    }
    game.db.deleteWorld(newWorldID)
    game.db.putWorld(c06WorldRecord(newWorldID))
    _ = game.db.putChunks([
        c06ChunkRecord(database: game.db, worldID: newWorldID, lines: newLines)
    ])
    game.world.getBlockEntity(1, 64, 1)?.lines = c06CurrentLines
    oldChunk.modified = true
    game.db.testingSignInscriptionPersistenceHook = { phase in phase != .prepared }
    game.loadWorld(newWorldID)
    let oldKey = game.db.chunkKey(oldWorldID, 0, 0, 0)
    check("C06 World switch refuses unresolved failure", game.worldRec?.id == oldWorldID
        && game.testingUnresolvedChunkSaveRecord(key: oldKey) != nil)
    game.db.testingSignInscriptionPersistenceHook = nil
    game.loadWorld(newWorldID)
    check("C06 World switch commits old World before replacement", game.worldRec?.id == newWorldID
        && c06LoadedLines(game) == newLines
        && game.testingLatestChunkSaveSequence(key: oldKey) == nil)

    // A recovery callback queued by an old World cannot dirty or mutate the new one.
    let callbackOldID = "civ45-c06-world-switch-callback-old"
    let callbackNewID = "civ45-c06-world-switch-callback-new"
    let callbackGame = GameCore()
    guard c06Install(callbackGame, worldID: callbackOldID, durableLines: c06DurableLines),
          let callbackChunk = callbackGame.world.getChunk(0, 0) else {
        check("C06 callback World fixture loads", false)
        return
    }
    callbackGame.db.deleteWorld(callbackNewID)
    callbackGame.db.putWorld(c06WorldRecord(callbackNewID))
    _ = callbackGame.db.putChunks([
        c06ChunkRecord(database: callbackGame.db, worldID: callbackNewID, lines: newLines)
    ])
    callbackGame.world.getBlockEntity(1, 64, 1)?.lines = c06CurrentLines
    callbackChunk.modified = true
    callbackGame.player.setPos(10_000.5, 80, 10_000.5)
    _ = callbackGame.testingUnloadChunkForPersistenceFreshness(callbackGame.world, cx: 0, cz: 0)
    let failed = DispatchSemaphore(value: 0)
    callbackGame.db.testingSignInscriptionPersistenceHook = { phase in
        if phase == .failed { failed.signal() }
        return phase != .prepared
    }
    _ = callbackGame.saveAndFlush(synchronous: false)
    guard failed.wait(timeout: .now() + 5) == .success else {
        check("C06 old World failure callback queues", false)
        return
    }
    let eventLock = NSLock()
    var residentRecoveryEvents = 0
    callbackGame.testingChunkSaveFreshnessHook = { event in
        if event.phase == .residentRecoveryMarkedDirty {
            eventLock.lock()
            residentRecoveryEvents += 1
            eventLock.unlock()
        }
    }
    callbackGame.db.testingSignInscriptionPersistenceHook = nil
    callbackGame.loadWorld(callbackNewID)
    _ = c06Wait { callbackGame.worldRec?.id == callbackNewID }
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
    eventLock.lock()
    let oldCallbackTouchedNewWorld = residentRecoveryEvents != 0
    eventLock.unlock()
    check("C06 old World callback cannot touch new World", !oldCallbackTouchedNewWorld
        && callbackGame.worldRec?.id == callbackNewID
        && c06LoadedLines(callbackGame) == newLines)
    print("CIV45_C06_WORLD_ISOLATION switchFailure=REFUSED oldCommitted=YES callbackCrossWorld=NO status=PASS")
}

func runPebbleCorePersistenceCorrection06Smoke() {
    section("CIV-45 Correction 06 streaming and lifecycle freshness")
    c06RunReturnBeforeResolution(
        expectHistoricalRewind: ProcessInfo.processInfo.environment[
            "PEBBLELAB_CIV45_C06_EXPECT_HISTORICAL_REWIND"
        ] == "1"
    )
    if ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV45_C06_EXPECT_HISTORICAL_REWIND"
    ] != "1" {
        c06RunSuccessAfterReturn()
        c06RunDeletionOrEdit(delete: true)
        c06RunDeletionOrEdit(delete: false)
        c06RunMultipleGenerations()
        c06RunExitLifecycle()
        c06RunTerminationLifecycle()
        c06RunWorldSwitchLifecycle()
    }
}
