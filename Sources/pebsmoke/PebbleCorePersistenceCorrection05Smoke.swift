import Foundation
import PebbleCore

private let c05OldLines = ["old-A", "captured", "before", "failure"]
private let c05NewLines = ["new-B", "pending", "after", "unload"]

private func c05WorldRecord(_ id: String) -> WorldRecord {
    var record = WorldRecord(
        id: id,
        name: "CIV-45 Correction 05",
        seed: 45,
        gameMode: 1,
        difficulty: 1
    )
    record.spawnX = 1
    record.spawnY = 65
    record.spawnZ = 1
    record.nextEntityId = 1
    return record
}

private func c05ChunkRecord(database: SaveDB, worldID: String) -> ChunkRecord {
    let chunk = Chunk(cx: 0, cz: 0, minY: GEN_MIN_Y, height: WORLD_H)
    chunk.set(1, 63, 1, UInt16(bid("stone")) << 4)
    chunk.set(1, 64, 1, UInt16(bid("oak_sign")) << 4)
    let sign = makeSignBE(1, 64, 1)
    sign.lines = ["baseline", "blank", "durable", "state"]
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

private func c05Lines(_ record: ChunkRecord?) -> [String]? {
    record?.blockEntities?.first(where: { $0.x == 1 && $0.y == 64 && $0.z == 1 })?.lines
}

private func c05WaitForMainQueue(_ semaphore: DispatchSemaphore) -> Bool {
    let deadline = Date(timeIntervalSinceNow: 5)
    while Date() < deadline {
        if semaphore.wait(timeout: .now()) == .success { return true }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
    }
    return false
}

private func c05Stamp(worldID: String, materialID: Int) throws -> SignInscription {
    let suffix = String(materialID, radix: 16)
    return try SignInscription(
        artifactID: "inscription-" + String(repeating: "0", count: 64 - suffix.count) + suffix,
        materialID: materialID,
        contentDigest: String(repeating: "c", count: 64),
        worldID: worldID,
        dimension: 0,
        x: 1,
        y: 64,
        z: 1,
        lines: c05OldLines
    )
}

private func c05RunInscriptionReplacementRace(
    worldID: String,
    replacementLines: [String],
    label: String
) {
    let game = GameCore()
    let record = c05WorldRecord(worldID)
    game.db.putWorld(record)
    var baseline = c05ChunkRecord(database: game.db, worldID: record.id)
    baseline.blockEntities = [makeSignBE(1, 64, 1)]
    guard game.db.putChunks([baseline]) else {
        check("\(label) baseline persists", false)
        return
    }
    game.loadWorld(record.id)
    guard let chunk = game.world.getChunk(0, 0) else {
        check("\(label) fixture loads", false)
        return
    }
    let materialID = peekNextEntityId()
    guard let stamp = try? c05Stamp(worldID: worldID, materialID: materialID),
          (try? game.world.withCandidateSignInscriptionAuthority(stamp) { _ in () }) != nil else {
        check("\(label) old inscription A is created", false)
        return
    }

    let prepared = DispatchSemaphore(value: 0)
    let releaseFailure = DispatchSemaphore(value: 0)
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
            _ = releaseFailure.wait(timeout: .now() + 5)
            return false
        }
        if fail && phase == .failed { failed.signal() }
        return true
    }
    game.testingSignInscriptionSaveRecoveryHook = { _ in recovered.signal() }
    game.saveAndFlush(synchronous: false)
    guard prepared.wait(timeout: .now() + 5) == .success else {
        check("\(label) old A reaches prepared boundary", false)
        return
    }

    let replacement = makeSignBE(1, 64, 1)
    replacement.lines = replacementLines
    game.world.setBlockEntity(replacement)
    chunk.modified = true
    game.world.time = 1
    game.player.setPos(10_000.5, 80, 10_000.5)
    _ = game.frame(dtMs: 50)
    let key = game.db.chunkKey(record.id, 0, 0, 0)
    let pendingSequence = game.testingPendingChunkSaveSequence(key: key)
    let catalog = game.world.signInscriptionIdentityCatalog!
    let generationBeforeRecovery = catalog.generation

    releaseFailure.signal()
    guard failed.wait(timeout: .now() + 5) == .success,
          c05WaitForMainQueue(recovered) else {
        check("\(label) old A recovery completes", false)
        return
    }
    lock.lock()
    failFirst = false
    lock.unlock()
    game.db.testingSignInscriptionPersistenceHook = nil
    game.testingSignInscriptionSaveRecoveryHook = nil

    let pending = game.testingPendingChunkSaveRecord(key: key)
    check("\(label) stale A cannot replace pending B",
          c05Lines(pending) == replacementLines
            && pending?.blockEntities?.first?.signInscription == nil
            && game.testingPendingChunkSaveSequence(key: key) == pendingSequence)
    check("\(label) rejected recovery leaves staged catalogue current",
          catalog.generation == generationBeforeRecovery)

    game.saveAndFlush(synchronous: true)
    let durable = game.db.getChunk(record.id, 0, 0, 0)
    let restarted = GameCore()
    restarted.loadWorld(record.id)
    let restart = restarted.db.getChunk(record.id, 0, 0, 0)
    check("\(label) retry and restart preserve B",
          c05Lines(durable) == replacementLines
            && durable?.blockEntities?.first?.signInscription == nil
            && c05Lines(restart) == replacementLines
            && restart?.blockEntities?.first?.signInscription == nil)
    check("\(label) identity and compact index remain coherent",
          (restarted.worldRec?.nextEntityId ?? 0) > materialID
            && restarted.db.lastSignInscriptionIndexLoadMetrics.migratedChunkPayloads == 0
            && restarted.db.lastSignInscriptionIndexLoadMetrics.decodedVoxelCells == 0,
          "worldNext=\(restarted.worldRec?.nextEntityId ?? -1) material=\(materialID) "
            + "indexed=\(restarted.db.lastSignInscriptionIndexLoadMetrics.indexedChunkRows)")
}

private func c05RunMultipleGenerationRace() {
    let game = GameCore()
    let record = c05WorldRecord("civ45-c05-three-generations")
    game.db.putWorld(record)
    guard game.db.putChunks([c05ChunkRecord(database: game.db, worldID: record.id)]) else {
        check("three-generation baseline persists", false)
        return
    }
    game.loadWorld(record.id)
    guard let sign = game.world.getBlockEntity(1, 64, 1),
          let chunk = game.world.getChunk(0, 0) else {
        check("three-generation fixture loads", false)
        return
    }
    let key = game.db.chunkKey(record.id, 0, 0, 0)
    let aPrepared = DispatchSemaphore(value: 0)
    let bPrepared = DispatchSemaphore(value: 0)
    let releaseA = DispatchSemaphore(value: 0)
    let releaseB = DispatchSemaphore(value: 0)
    let aFailed = DispatchSemaphore(value: 0)
    let bFailed = DispatchSemaphore(value: 0)
    let recovered = DispatchSemaphore(value: 0)
    let lock = NSLock()
    var preparedOrdinal = 0
    var failedOrdinal = 0
    var events: [ChunkSaveFreshnessEvent] = []
    game.testingChunkSaveFreshnessHook = { event in
        guard event.key == key else { return }
        lock.lock()
        events.append(event)
        lock.unlock()
    }
    game.db.testingSignInscriptionPersistenceHook = { phase in
        if phase == .prepared {
            lock.lock()
            preparedOrdinal += 1
            let ordinal = preparedOrdinal
            lock.unlock()
            if ordinal == 1 {
                aPrepared.signal()
                _ = releaseA.wait(timeout: .now() + 5)
                return false
            }
            if ordinal == 2 {
                bPrepared.signal()
                _ = releaseB.wait(timeout: .now() + 5)
                return false
            }
        }
        if phase == .failed {
            lock.lock()
            failedOrdinal += 1
            let ordinal = failedOrdinal
            lock.unlock()
            (ordinal == 1 ? aFailed : bFailed).signal()
        }
        return true
    }
    game.testingSignInscriptionSaveRecoveryHook = { _ in recovered.signal() }

    sign.lines = ["A", "sequence", "one", "old"]
    chunk.modified = true
    game.saveAndFlush(synchronous: false)
    guard aPrepared.wait(timeout: .now() + 5) == .success else {
        check("generation A reaches prepared", false)
        return
    }
    sign.lines = ["B", "sequence", "two", "middle"]
    chunk.modified = true
    game.saveAndFlush(synchronous: false)
    sign.lines = ["C", "sequence", "three", "winner"]
    chunk.modified = true
    game.world.time = 1
    game.player.setPos(10_000.5, 80, 10_000.5)
    _ = game.frame(dtMs: 50)
    let cSequence = game.testingPendingChunkSaveSequence(key: key)

    releaseA.signal()
    guard aFailed.wait(timeout: .now() + 5) == .success,
          bPrepared.wait(timeout: .now() + 5) == .success,
          c05WaitForMainQueue(recovered) else {
        check("generation A fails and recovers while B is blocked", false)
        return
    }
    releaseB.signal()
    guard bFailed.wait(timeout: .now() + 5) == .success,
          c05WaitForMainQueue(recovered) else {
        check("generation B fails and recovers after A", false)
        return
    }
    game.db.testingSignInscriptionPersistenceHook = nil
    game.testingSignInscriptionSaveRecoveryHook = nil
    game.testingChunkSaveFreshnessHook = nil

    lock.lock()
    let capturedEvents = events
    lock.unlock()
    let sequences = capturedEvents.filter { $0.phase == .captured }.map(\.sequence)
    let rejected = capturedEvents.filter { $0.phase == .recoveryRejectedStale }
    check("A/B/C captures have strict monotone sequence",
          sequences.count == 3 && sequences[0] < sequences[1]
            && sequences[1] < sequences[2] && cSequence == sequences[2])
    check("late A and B recoveries both reject against C",
          rejected.map(\.sequence) == Array(sequences.prefix(2))
            && rejected.allSatisfy { $0.latestSequence == sequences[2] })
    check("pending map never regresses below generation C",
          c05Lines(game.testingPendingChunkSaveRecord(key: key))
            == ["C", "sequence", "three", "winner"]
            && game.testingPendingChunkSaveSequence(key: key) == cSequence)
    game.saveAndFlush(synchronous: true)
    let restarted = GameCore()
    restarted.loadWorld(record.id)
    check("generation C alone wins retry and restart",
          c05Lines(restarted.db.getChunk(record.id, 0, 0, 0))
            == ["C", "sequence", "three", "winner"])
}

private func c05RunResidentFreshnessRace() {
    let game = GameCore()
    let record = c05WorldRecord("civ45-c05-resident-newer")
    game.db.putWorld(record)
    guard game.db.putChunks([c05ChunkRecord(database: game.db, worldID: record.id)]) else {
        check("resident baseline persists", false)
        return
    }
    game.loadWorld(record.id)
    guard let sign = game.world.getBlockEntity(1, 64, 1),
          let chunk = game.world.getChunk(0, 0) else {
        check("resident fixture loads", false)
        return
    }
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
    sign.lines = c05OldLines
    chunk.modified = true
    game.saveAndFlush(synchronous: false)
    guard prepared.wait(timeout: .now() + 5) == .success else {
        check("resident old A reaches prepared", false)
        return
    }
    sign.lines = c05NewLines
    chunk.modified = true
    release.signal()
    guard failed.wait(timeout: .now() + 5) == .success,
          c05WaitForMainQueue(recovered) else {
        check("resident old A recovery completes", false)
        return
    }
    lock.lock()
    failFirst = false
    lock.unlock()
    game.db.testingSignInscriptionPersistenceHook = nil
    game.testingSignInscriptionSaveRecoveryHook = nil
    check("resident recovery preserves current B and dirty retry",
          sign.lines == c05NewLines && chunk.modified)
    game.saveAndFlush(synchronous: true)
    let restarted = GameCore()
    restarted.loadWorld(record.id)
    check("resident B wins durable retry and restart",
          c05Lines(restarted.db.getChunk(record.id, 0, 0, 0)) == c05NewLines)
}

private func c05RunPendingFlushRace(synchronousFirstCapture: Bool) {
    let mode = synchronousFirstCapture ? "sync" : "async"
    let game = GameCore()
    let record = c05WorldRecord("civ45-c05-\(mode)-pending-flush")
    game.db.putWorld(record)
    guard game.db.putChunks([c05ChunkRecord(database: game.db, worldID: record.id)]) else {
        check("\(mode) pending-flush baseline persists", false)
        return
    }
    game.loadWorld(record.id)
    guard let sign = game.world.getBlockEntity(1, 64, 1),
          let chunk = game.world.getChunk(0, 0) else {
        check("\(mode) pending-flush fixture loads", false)
        return
    }
    let prepared = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    let failed = DispatchSemaphore(value: 0)
    let recovered = DispatchSemaphore(value: 0)
    let newerCommitted = DispatchSemaphore(value: 0)
    let synchronousReturned = DispatchSemaphore(value: 0)
    let lock = NSLock()
    var preparedOrdinal = 0
    game.db.testingSignInscriptionPersistenceHook = { phase in
        if phase == .prepared {
            lock.lock()
            preparedOrdinal += 1
            let ordinal = preparedOrdinal
            lock.unlock()
            if ordinal == 1 {
                prepared.signal()
                _ = release.wait(timeout: .now() + 5)
                return false
            }
        }
        if phase == .failed { failed.signal() }
        if phase == .authorityAdvanced {
            lock.lock()
            let newer = preparedOrdinal >= 2
            lock.unlock()
            if newer { newerCommitted.signal() }
        }
        return true
    }
    game.testingSignInscriptionSaveRecoveryHook = { _ in recovered.signal() }
    sign.lines = c05OldLines
    chunk.modified = true
    if synchronousFirstCapture {
        DispatchQueue.global().async {
            game.saveAndFlush(synchronous: true)
            synchronousReturned.signal()
        }
    } else {
        game.saveAndFlush(synchronous: false)
    }
    guard prepared.wait(timeout: .now() + 5) == .success else {
        check("\(mode) old A reaches prepared", false)
        return
    }
    sign.lines = c05NewLines
    chunk.modified = true
    game.world.time = 19
    game.player.setPos(10_000.5, 80, 10_000.5)
    _ = game.frame(dtMs: 50)
    release.signal()
    guard failed.wait(timeout: .now() + 5) == .success,
          c05WaitForMainQueue(recovered),
          newerCommitted.wait(timeout: .now() + 5) == .success else {
        check("\(mode) failure and pending flush complete", false)
        return
    }
    if synchronousFirstCapture {
        check("synchronous failed save returns after worker outcome",
              synchronousReturned.wait(timeout: .now() + 5) == .success)
    }
    game.db.testingSignInscriptionPersistenceHook = nil
    game.testingSignInscriptionSaveRecoveryHook = nil
    let restarted = GameCore()
    restarted.loadWorld(record.id)
    check("\(mode) pending unloaded flush keeps newer B durable",
          c05Lines(restarted.db.getChunk(record.id, 0, 0, 0)) == c05NewLines)
}

func runPebbleCorePersistenceCorrection05Smoke() {
    section("CIV-45 Correction 05 stale failed-snapshot recovery")
    let expectHistoricalRewind = ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV45_C05_EXPECT_HISTORICAL_REWIND"
    ] == "1"
    let game = GameCore()
    let record = c05WorldRecord("civ45-c05-old-a-new-b")
    game.db.putWorld(record)
    let baseline = c05ChunkRecord(database: game.db, worldID: record.id)
    guard game.db.putChunks([baseline]) else {
        check("Correction 05 baseline persists", false)
        return
    }
    game.loadWorld(record.id)
    guard let sign = game.world.getBlockEntity(1, 64, 1),
          let chunk = game.world.getChunk(0, 0) else {
        check("Correction 05 fixture loads", false)
        return
    }

    let oldPrepared = DispatchSemaphore(value: 0)
    let releaseOldFailure = DispatchSemaphore(value: 0)
    let oldFailed = DispatchSemaphore(value: 0)
    let recoveryFinished = DispatchSemaphore(value: 0)
    let hookLock = NSLock()
    var shouldFailOld = true
    let key = game.db.chunkKey(record.id, 0, 0, 0)
    var freshnessEvents: [ChunkSaveFreshnessEvent] = []
    game.testingChunkSaveFreshnessHook = { event in
        guard event.key == key else { return }
        hookLock.lock()
        freshnessEvents.append(event)
        hookLock.unlock()
    }
    game.db.testingSignInscriptionPersistenceHook = { phase in
        hookLock.lock()
        let failThisBatch = shouldFailOld
        hookLock.unlock()
        if failThisBatch && phase == .prepared {
            oldPrepared.signal()
            _ = releaseOldFailure.wait(timeout: .now() + 5)
            return false
        }
        if failThisBatch && phase == .failed { oldFailed.signal() }
        return true
    }
    game.testingSignInscriptionSaveRecoveryHook = { _ in recoveryFinished.signal() }

    sign.lines = c05OldLines
    chunk.modified = true
    game.saveAndFlush(synchronous: false)
    guard oldPrepared.wait(timeout: .now() + 5) == .success else {
        check("old A reaches prepared boundary", false)
        return
    }

    sign.lines = c05NewLines
    chunk.modified = true
    game.world.time = 1
    game.player.setPos(10_000.5, 80, 10_000.5)
    _ = game.frame(dtMs: 50)
    let pendingBefore = c05Lines(game.testingPendingChunkSaveRecord(key: key))
    let pendingBeforeSequence = game.testingPendingChunkSaveSequence(key: key)
    check("newer B is pending before old A fails", pendingBefore == c05NewLines)

    releaseOldFailure.signal()
    guard oldFailed.wait(timeout: .now() + 5) == .success,
          c05WaitForMainQueue(recoveryFinished) else {
        check("old A failure recovery completes deterministically", false)
        return
    }
    hookLock.lock()
    shouldFailOld = false
    hookLock.unlock()
    game.db.testingSignInscriptionPersistenceHook = nil
    game.testingSignInscriptionSaveRecoveryHook = nil
    game.testingChunkSaveFreshnessHook = nil

    let pendingAfter = c05Lines(game.testingPendingChunkSaveRecord(key: key))
    let pendingAfterSequence = game.testingPendingChunkSaveSequence(key: key)
    let expectedAfter = expectHistoricalRewind ? c05OldLines : c05NewLines
    check("failed old A cannot replace pending newer B", pendingAfter == expectedAfter,
          "pending=\(pendingAfter ?? []) expected=\(expectedAfter)")
    if !expectHistoricalRewind {
        hookLock.lock()
        let events = freshnessEvents
        hookLock.unlock()
        let captures = events.filter { $0.phase == .captured }.map(\.sequence)
        let rejection = events.first { $0.phase == .recoveryRejectedStale }
        check("capture sequence orders A before B",
              captures.count == 2 && captures[0] < captures[1]
                && pendingBeforeSequence == captures[1])
        check("stale recovery observes and rejects older sequence",
              rejection?.sequence == captures.first
                && rejection?.latestSequence == captures.last
                && pendingAfterSequence == captures.last)
    }

    game.saveAndFlush(synchronous: true)
    let durable = c05Lines(game.db.getChunk(record.id, 0, 0, 0))
    let restarted = GameCore()
    restarted.loadWorld(record.id)
    let restart = c05Lines(restarted.db.getChunk(record.id, 0, 0, 0))
    check("retry durability follows causal winner", durable == expectedAfter)
    check("fresh GameCore restart follows causal winner", restart == expectedAfter)
    let pendingBeforeName = pendingBefore == c05NewLines ? "B" : "unexpected"
    let pendingAfterName = pendingAfter == c05NewLines ? "B" : "A"
    let durableName = durable == c05NewLines ? "B" : "A"
    let restartName = restart == c05NewLines ? "B" : "A"
    let status = expectHistoricalRewind ? "REPRODUCED" : "PASS"
    print("CIV45_C05 old=A pendingBefore=\(pendingBeforeName) "
        + "pendingAfter=\(pendingAfterName) durable=\(durableName) "
        + "restart=\(restartName) status=\(status)")
    if !expectHistoricalRewind {
        c05RunInscriptionReplacementRace(
            worldID: "civ45-c05-inscription-deletion",
            replacementLines: ["", "", "", ""],
            label: "inscription A / deletion B"
        )
        c05RunInscriptionReplacementRace(
            worldID: "civ45-c05-inscription-external-edit",
            replacementLines: c05NewLines,
            label: "inscription A / external edit B"
        )
        c05RunMultipleGenerationRace()
        c05RunResidentFreshnessRace()
        c05RunPendingFlushRace(synchronousFirstCapture: false)
        c05RunPendingFlushRace(synchronousFirstCapture: true)
    }
}
