import Foundation
import PebbleCore

private func residentJSON(_ value: Any) -> String {
    String(data: try! JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]), encoding: .utf8)!
}

private func residentRecords(_ entities: [Entity]) -> [String] {
    entities.map { residentJSON($0.save()) }.sorted()
}

private func residentBlockHash(_ blocks: [UInt16]) -> String {
    var hash: UInt64 = 14695981039346656037
    for block in blocks {
        hash = (hash ^ UInt64(block & 255)) &* 1099511628211
        hash = (hash ^ UInt64(block >> 8)) &* 1099511628211
    }
    return String(hash, radix: 16)
}

private func residentEligible(_ world: World, _ cx: Int, _ cz: Int) -> [Entity] {
    world.entities.compactMap { $0 as? Entity }.filter {
        !$0.isPlayer && !$0.dead && $0.shouldSaveToChunk
            && Int(floor($0.x / 16)) == cx && Int(floor($0.z / 16)) == cz
            && (!(($0.type == "item" || $0.type == "xp_orb") && $0.age > 4000)
                || ($0 as? ItemEntity)?.custodyProvenance != nil)
    }
}

private func residentGame(_ label: String) -> GameCore {
    let game = GameCore()
    let id = "ps01-core-resident-test-\(label)"
    game.db.deleteWorld(id)
    var record = WorldRecord(id: id, name: "PebbleLab-Disposable-CoreResident-5", seed: 5, gameMode: 1, difficulty: 2)
    record.spawnX = 8; record.spawnY = 76; record.spawnZ = -112
    precondition(game.db.putWorld(record))
    game.loadWorld(id)
    precondition(game.world.getChunk(0, -7) != nil)
    return game
}

private func residentSpider(_ game: GameCore, x: Double = 10.5, z: Double = -109.5) -> Spider {
    let spider = spawnMob(game.world, "spider", x, Double(game.world.surfaceY(Int(floor(x)), Int(floor(z)))), z) as! Spider
    spider.health = 13; spider.age = 17
    return spider
}

private func residentWait(_ condition: () -> Bool) -> Bool {
    let deadline = Date(timeIntervalSinceNow: 10)
    while Date() < deadline {
        if condition() { return true }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
    }
    return condition()
}

/// Exact current semantic state is recorded BEFORE capture. Readers run in an
/// independent OS process; numeric incarnation IDs are deliberately absent.
private func residentExpectation(_ game: GameCore, _ coordinates: [(Int, Int)]) -> [String: Any] {
    ["world": game.worldRec!.id, "player": residentJSON(game.player.save()),
     "chunks": coordinates.map { cx, cz in
        ["cx": cx, "cz": cz,
         "entities": residentRecords(residentEligible(game.world, cx, cz)),
         "blocks": residentBlockHash(game.world.getChunk(cx, cz)!.blocks)] as [String: Any]
     }]
}

private func residentFreshProcess(_ expected: [String: Any], label: String) {
    let path = FileManager.default.temporaryDirectory.appendingPathComponent("ps01-core-resident-\(label)-\(ProcessInfo.processInfo.processIdentifier).json")
    try! residentJSON(expected).write(to: path, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: path) }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
    var environment = ProcessInfo.processInfo.environment
    environment["PEBBLELAB_SMOKE_ONLY"] = "core-resident-entity-reader"
    environment["PEBBLELAB_CORE_RESIDENT_EXPECTED"] = path.path
    process.environment = environment
    do {
        try process.run()
        process.waitUntilExit()
        check("resident \(label): independent fresh-process state", process.terminationStatus == 0)
    } catch {
        check("resident \(label): independent fresh-process launch", false, "\(error)")
    }
}

func runPebbleCoreResidentEntityPersistenceReader() {
    let path = ProcessInfo.processInfo.environment["PEBBLELAB_CORE_RESIDENT_EXPECTED"]!
    let expected = try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as! [String: Any]
    let game = GameCore()
    let id = expected["world"] as! String
    let frontier = game.db.getWorld(id)!.nextEntityId
    game.loadWorld(id)
    for chunk in expected["chunks"] as! [[String: Any]] {
        let cx = (chunk["cx"] as! NSNumber).intValue, cz = (chunk["cz"] as! NSNumber).intValue
        game.testingEnsureChunkLoadedForPersistenceFreshness(game.world, cx: cx, cz: cz)
        check("fresh \(id) \(cx),\(cz): exact semantic entity multiset",
              residentRecords(residentEligible(game.world, cx, cz)) == chunk["entities"] as! [String])
        check("fresh \(id) \(cx),\(cz): terrain conserved",
              residentBlockHash(game.world.getChunk(cx, cz)!.blocks) == chunk["blocks"] as! String)
    }
    let entities = game.world.entities.compactMap { $0 as? Entity }
    let ids = entities.map(\.id)
    check("fresh \(id): unique runtime incarnations and allocation frontier",
          Set(ids).count == ids.count && ids.allSatisfy { $0 >= frontier && $0 < peekNextEntityId() }
            && entities.allSatisfy { game.world.entityById[$0.id] === $0 })
    check("fresh \(id): single Player owner with exact state",
          entities.filter(\.isPlayer).count == 1 && residentJSON(game.player.save()) == expected["player"] as! String)
}

private func residentCreationAndUpdate() {
    let game = residentGame("creation-update")
    let id = game.worldRec!.id
    let chunk = game.world.getChunk(0, -7)!
    check("resident A: genuinely generated clean chunk", !chunk.modified && game.db.getChunk(id, 0, 0, -7) == nil)
    let spider = residentSpider(game)
    let first = residentExpectation(game, [(0, -7)])
    check("resident A: spawn does not dirty blocks", !chunk.modified)
    check("resident A: synchronous barrier succeeds", game.saveAndFlush(synchronous: true))
    let record = game.db.getChunk(id, 0, 0, -7)
    check("resident A/J: exactly one entity-only Spider", record?.blocks == nil
        && record?.entities.map(residentJSON).sorted() == first["chunks"].flatMap { ($0 as? [[String: Any]])?.first?["entities"] as? [String] })
    residentFreshProcess(first, label: "creation")
    spider.setPos(11.25, spider.y + 0.5, -108.75)
    spider.vx = 0.125; spider.vy = -0.25; spider.vz = 0.375
    spider.yaw = 0.75; spider.pitch = -0.125; spider.age = 215; spider.fireTicks = 3
    spider.health = 7; spider.persistent = true; spider.data.variant = 2
    let second = residentExpectation(game, [(0, -7)])
    check("resident B: state update leaves blocks clean", !chunk.modified)
    check("resident B: general asynchronous submission accepted", game.saveAndFlush())
    check("resident B: synchronous barrier resolves current state", game.saveAndFlush(synchronous: true))
    check("resident B: latest durable snapshot", game.db.getChunk(id, 0, 0, -7)?.entities.map(residentJSON).sorted() == residentRecords([spider]))
    residentFreshProcess(second, label: "state-update")
}

private func residentRemovalAndTransfer() {
    for removal in ["remove", "death", "despawn"] {
        let game = residentGame(removal)
        let spider = residentSpider(game)
        check("resident C \(removal): initial barrier", game.saveAndFlush(synchronous: true))
        if removal == "remove" { spider.remove(); game.world.removeEntity(spider) }
        else if removal == "death" {
            game.setGameRule("doMobLoot", 0)
            spider.die("generic")
            for _ in 0..<25 { spider.tick() }
        } else {
            game.player.setPos(250, 80, -109.5)
            spider.tick()
        }
        check("resident C \(removal): legitimate removal, blocks clean", spider.dead && !game.world.getChunk(0, -7)!.modified)
        let expected = residentExpectation(game, [(0, -7)])
        check("resident C \(removal): Save/Exit barrier", game.exitToTitle())
        check("resident C \(removal): empty durable snapshot", game.db.getChunk(expected["world"] as! String, 0, 0, -7)?.entities.isEmpty == true)
        residentFreshProcess(expected, label: removal)
    }
    let game = residentGame("transfer")
    let spider = residentSpider(game, x: 15.75)
    let runtimeID = spider.id
    check("resident D: initial A barrier", game.saveAndFlush(synchronous: true))
    // Existing Core movement crosses the border in natural loaded terrain.
    spider.move(1, 0, 0)
    check("resident D: ordinary movement crosses A to B with same runtime ID", spider.x >= 16 && spider.id == runtimeID)
    let expected = residentExpectation(game, [(0, -7), (1, -7)])
    check("resident D: both blocks remain clean", !game.world.getChunk(0, -7)!.modified && !game.world.getChunk(1, -7)!.modified)
    check("resident D: transfer barrier", game.saveAndFlush(synchronous: true))
    let id = game.worldRec!.id
    check("resident D: no stale A and exactly one B", game.db.getChunk(id, 0, 0, -7)?.entities.isEmpty == true
        && game.db.getChunk(id, 0, 1, -7)?.entities.map(residentJSON) == residentRecords([spider]))
    residentFreshProcess(expected, label: "transfer")
}

private func residentMultipleAndPolicy() {
    let game = residentGame("multiple-policy")
    let a = residentSpider(game); let b = residentSpider(game)
    // Two equivalent records deliberately test multiset cardinality.
    let c = residentSpider(game, x: 20.5); c.health = 6; c.data.variant = 1
    let cow = spawnMob(game.world, "cow", 21.5, c.y, c.z)!
    cow.age = 201; cow.persistent = true
    let probe = LabCoreAgentEntity(world: game.world, labAgentId: "resident_probe", physicalId: "resident_probe_body")
    probe.setPos(a.x, a.y, a.z); game.world.addEntity(probe)
    let dead = residentSpider(game); dead.remove()
    let youngItem = ItemEntity(world: game.world); youngItem.setPos(a.x, a.y, a.z); youngItem.age = 4000
    youngItem.stack = ItemStack(iid("dirt"), 2); game.world.addEntity(youngItem)
    let oldItem = ItemEntity(world: game.world); oldItem.setPos(a.x, a.y, a.z); oldItem.age = 4001
    game.world.addEntity(oldItem)
    let oldXP = XPOrb(world: game.world); oldXP.setPos(a.x, a.y, a.z); oldXP.age = 4001; game.world.addEntity(oldXP)
    let youngXP = XPOrb(world: game.world); youngXP.setPos(a.x, a.y, a.z); youngXP.age = 4000; youngXP.amount = 7
    game.world.addEntity(youngXP)
    let protected = ItemEntity(world: game.world); protected.setPos(c.x, c.y, c.z); protected.age = 9000
    protected.stack = ItemStack(iid("stone"), 3); protected.custodyProvenance = "resident-custody-proof"
    protected.pickupDelay = Int.max; game.world.addEntity(protected)
    game.player.inventory[0] = ItemStack(iid("diamond"), 2); game.player.xpLevel = 9
    let expected = residentExpectation(game, [(0, -7), (1, -7)])
    let liveIDs = game.world.entities.map(\.id)
    check("resident E: unique live incarnation IDs", Set(liveIDs).count == liveIDs.count && a.id != b.id)
    check("resident E/H: save barrier", game.saveAndFlush(synchronous: true))
    let id = game.worldRec!.id
    let records = [game.db.getChunk(id, 0, 0, -7)!, game.db.getChunk(id, 0, 1, -7)!]
    let serialized = records.flatMap(\.entities)
    check("resident E: exact multiple entity cardinality", serialized.count == 7)
    check("resident F/G: no Player or transient probe records", serialized.allSatisfy { $0["type"] as? String != "player" && $0["type"] as? String != probe.type })
    check("resident H: exact policy boundary and provenance exemption", serialized.filter { $0["type"] as? String == "item" }.count == 2
        && serialized.filter { $0["type"] as? String == "xp_orb" }.count == 1
        && serialized.filter { $0["type"] as? String == "spider" }.count == 3)
    check("resident E: no duplicate ownership across chunks", records[0].entities.count == 4 && records[1].entities.count == 3)
    residentFreshProcess(expected, label: "multiple-policy")
}

private func residentFullAndSeedSnapshots() {
    let game = residentGame("full")
    let id = game.worldRec!.id
    let chunk = game.world.getChunk(0, -7)!
    game.world.setBlock(10, 130, -110, Int(B.diamond_block) << 4)
    let spider = residentSpider(game)
    check("resident I: edited full barrier", game.saveAndFlush(synchronous: true))
    let full = game.db.getChunk(id, 0, 0, -7)!
    spider.health = 5
    let expected = residentExpectation(game, [(0, -7)])
    check("resident I: clean full refresh barrier", !chunk.modified && game.saveAndFlush(synchronous: true))
    let refreshed = game.db.getChunk(id, 0, 0, -7)!
    check("resident I: full blocks/biomes preserved", refreshed.blocks == full.blocks && refreshed.biomes == full.biomes && refreshed.blocks != nil)
    residentFreshProcess(expected, label: "full")
    // Historical VCK1 full record without blockEntities must remain full after synchronous adoption.
    let legacy = residentGame("legacy-full")
    let legacyID = legacy.worldRec!.id
    let initial = legacy.world.getChunk(0, -7)!
    let legacyRecord = ChunkRecord(key: legacy.db.chunkKey(legacyID, 0, 0, -7), worldId: legacyID, dim: 0, cx: 0, cz: -7,
                                  blocks: initial.blocks, biomes: initial.biomes, entities: [residentSpider(legacy).save()])
    precondition(legacy.db.putChunks([legacyRecord]))
    let loader = GameCore(); loader.loadWorld(legacyID)
    check("resident I legacy: loaded without block dirty marking", !loader.world.getChunk(0, -7)!.modified)
    check("resident I legacy: refresh preserves full authority", loader.saveAndFlush(synchronous: true)
        && loader.db.getChunk(legacyID, 0, 0, -7)?.blocks == legacyRecord.blocks)
    residentFreshProcess(residentExpectation(loader, [(0, -7)]), label: "legacy-full")

    let seed = residentGame("seed-empty")
    var selected: (Int, Int)?
    // Bounded seeded search only identifies an existing natural entity snapshot.
    for cx in -10...10 {
        let out = generateOverworldChunk(5, cx, -7)
        if !out.entities.isEmpty && out.blockEntities.isEmpty { selected = (cx, -7); break }
    }
    guard let (cx, cz) = selected else { check("resident seed: bounded natural fixture found", false); return }
    seed.testingEnsureChunkLoadedForPersistenceFreshness(seed.world, cx: cx, cz: cz)
    let generated = residentEligible(seed.world, cx, cz)
    check("resident seed: genuinely generated entity snapshot", !generated.isEmpty && !seed.world.getChunk(cx, cz)!.modified)
    for entity in generated { entity.remove(); seed.world.removeEntity(entity) }
    let empty = residentExpectation(seed, [(cx, cz)])
    check("resident seed: empty first barrier suppresses regeneration", seed.saveAndFlush(synchronous: true)
        && seed.db.getChunk(seed.worldRec!.id, 0, cx, cz)?.entities.isEmpty == true)
    residentFreshProcess(empty, label: "seed-empty")
}

private func residentFailureFreshness() {
    let game = residentGame("failure")
    let spider = residentSpider(game)
    let id = game.worldRec!.id, key = game.db.chunkKey(id, 0, 0, -7)
    game.db.testingSignInscriptionPersistenceHook = { $0 != .prepared }
    check("resident retry: repeated write failure refuses barrier", !game.saveAndFlush(synchronous: true))
    check("resident retry: failed capture retained", game.testingPendingChunkSaveRecord(key: key) != nil
        && game.testingUnresolvedChunkSaveRecord(key: key) != nil && game.db.getChunk(id, 0, 0, -7) == nil)
    _ = residentWait { !game.world.getChunk(0, -7)!.modified }
    // Execute main recovery callbacks before asserting entity-only terrain stays clean.
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
    check("resident retry: entity failure leaves block state clean", !game.world.getChunk(0, -7)!.modified)
    spider.health = 4; spider.age = 120
    let expected = residentExpectation(game, [(0, -7)])
    game.db.testingSignInscriptionPersistenceHook = nil
    check("resident retry: latest clean state retries durably", game.saveAndFlush(synchronous: true)
        && game.testingUnresolvedChunkSaveRecord(key: key) == nil
        && game.db.getChunk(id, 0, 0, -7)?.blocks == nil
        && game.db.getChunk(id, 0, 0, -7)?.entities.map(residentJSON) == residentRecords([spider]))
    residentFreshProcess(expected, label: "failure-retry")

    let periodic = residentGame("periodic-retry")
    periodic.settings.renderDistance = 2
    periodic.world.randomTickSpeed = 0
    periodic.setGameRule("doMobSpawning", 0)
    let moving = residentSpider(periodic); moving.persistent = true
    let periodicID = periodic.worldRec!.id, periodicKey = periodic.db.chunkKey(periodicID, 0, 0, -7)
    periodic.db.testingSignInscriptionPersistenceHook = { $0 != .prepared }
    check("resident periodic retry: initial write refusal", !periodic.saveAndFlush(synchronous: true))
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
    let olderSequence = periodic.testingPendingChunkSaveSequence(key: periodicKey)!
    moving.health = 2; moving.age = 500; moving.noGravity = true
    moving.setPos(moving.x, 130, moving.z)
    periodic.db.testingSignInscriptionPersistenceHook = nil
    for _ in 0..<300 {
        if periodic.world.time >= 20 { break }
        _ = periodic.frame(dtMs: 50)
    }
    check("resident periodic retry: production 20-tick batch progresses", periodic.world.time == 20)
    var periodicExpected = residentExpectation(periodic, [(0, -7)])
    // The unload-retry batch owns chunks only; Player remains at its last general save.
    periodicExpected["player"] = residentJSON(periodic.db.getPlayer(periodicID)!["data"]!)
    check("resident periodic retry: current clean entity state recaptured",
          (periodic.testingLatestChunkSaveSequence(key: periodicKey) ?? 0) > olderSequence)
    check("resident periodic retry: batch completes without another save call", residentWait {
        periodic.testingUnresolvedChunkSaveRecord(key: periodicKey) == nil
    })
    check("resident periodic retry: latest semantic state is durable",
          periodic.db.getChunk(periodicID, 0, 0, -7)?.entities.map(residentJSON).sorted()
            == residentRecords(residentEligible(periodic.world, 0, -7)))
    residentFreshProcess(periodicExpected, label: "periodic-retry")

    let sequenceBeforeAutosave = periodic.testingLatestChunkSaveSequence(key: periodicKey)!
    for _ in 0..<2000 {
        if periodic.world.time >= 1200 { break }
        _ = periodic.frame(dtMs: 50)
    }
    check("resident autosave: ordinary 1200-tick boundary reached", periodic.world.time == 1200)
    let autosaveExpected = residentExpectation(periodic, [(0, -7)])
    check("resident autosave: resident entity selected without manual save",
          (periodic.testingLatestChunkSaveSequence(key: periodicKey) ?? 0) > sequenceBeforeAutosave)
    check("resident autosave: asynchronous required chunk write completes", residentWait {
        periodic.testingUnresolvedChunkSaveRecord(key: periodicKey) == nil
    })
    check("resident autosave: latest entity multiset durable",
          periodic.db.getChunk(periodicID, 0, 0, -7)?.entities.map(residentJSON).sorted()
            == residentRecords(residentEligible(periodic.world, 0, -7)))
    residentFreshProcess(autosaveExpected, label: "autosave")

    // Hold old A in flight, capture B, then fail A. Delayed recovery must not
    // replace B, even though neither live entity update modifies blocks.
    let concurrent = residentGame("async-freshness")
    let s = residentSpider(concurrent)
    let prepared = DispatchSemaphore(value: 0), release = DispatchSemaphore(value: 0)
    let lock = NSLock(); var calls = 0
    concurrent.db.testingSignInscriptionPersistenceHook = { phase in
        if phase == .prepared {
            lock.lock(); calls += 1; let first = calls == 1; lock.unlock()
            if first { prepared.signal(); _ = release.wait(timeout: .now() + 10); return false }
        }
        return true
    }
    check("resident async: A submitted", concurrent.saveAndFlush())
    guard prepared.wait(timeout: .now() + 10) == .success else { check("resident async: A in flight", false); release.signal(); return }
    s.health = 3; s.age = 240
    let current = residentExpectation(concurrent, [(0, -7)])
    check("resident async: B submitted while A in flight", concurrent.saveAndFlush())
    release.signal()
    check("resident async: final barrier succeeds with B", concurrent.saveAndFlush(synchronous: true))
    concurrent.db.testingSignInscriptionPersistenceHook = nil
    check("resident async: old failure cannot overwrite B", concurrent.db.getChunk(concurrent.worldRec!.id, 0, 0, -7)?.entities.map(residentJSON) == residentRecords([s]))
    residentFreshProcess(current, label: "async-freshness")
}

func runPebbleCoreResidentEntityPersistenceSmoke() {
    section("Core resident entity persistence conservation")
    residentCreationAndUpdate()
    residentRemovalAndTransfer()
    residentMultipleAndPolicy()
    residentFullAndSeedSnapshots()
    residentFailureFreshness()
}

func runPebbleCoreResidentEntityPersistencePerformance() {
    section("Core resident save selection cost")
    for count in [9, 81, 270] {
        for full in [false, true] {
            let game = residentGame("performance-\(count)-\(full)")
            // Controlled storage-cost fixture, not an arbitrary-world gameplay claim.
            for entity in Array(game.world.entities) where !(entity as? Entity)!.isPlayer { game.world.removeEntity(entity) }
            for c in Array(game.world.chunks.values) { game.world.removeChunk(c.cx, c.cz) }
            for i in 0..<count {
                let c = Chunk(cx: i, cz: 0, minY: GEN_MIN_Y, height: WORLD_H)
                c.status = .generated; game.world.setChunk(c)
                if full { c.modified = true }
                _ = residentSpider(game, x: Double(i * 16) + 8.5, z: 8.5)
            }
            let before = game.world.chunks.values.filter(\.modified).count
            let start = Date()
            check("resident performance \(count) \(full): initial barrier", game.saveAndFlush(synchronous: true))
            let initialMs = Date().timeIntervalSince(start) * 1000
            for entity in Array(game.world.entities) where !(entity as? Entity)!.isPlayer { game.world.removeEntity(entity) }
            var timings: [Double] = []
            for _ in 0..<3 {
                let begin = Date()
                check("resident performance \(count) \(full): empty stable barrier", game.saveAndFlush(synchronous: true))
                timings.append(Date().timeIntervalSince(begin) * 1000)
            }
            let rows = (0..<count).compactMap { game.db.getChunk(game.worldRec!.id, 0, $0, 0) }
            let fullCount = rows.filter { $0.blocks != nil }.count
            let bytes = rows.reduce(0) { total, r in
                let blockBytes = (r.blocks?.count ?? 0) * 2 + (r.biomes?.count ?? 0)
                let tail: [String: Any] = r.blockEntities == nil ? ["entities": r.entities] : ["entities": r.entities, "blockEntities": []]
                return total + 9 + (r.blocks == nil ? 0 : 8) + blockBytes + residentJSON(tail).utf8.count
            }
            print("CORE_RESIDENT_PERFORMANCE " + residentJSON(["resident": count, "beforeSelected": before,
                "afterSelected": game.testingLastSubmittedChunkRecordCount, "full": fullCount,
                "entityOnly": rows.count - fullCount, "emptyPayloadBytes": bytes, "initialMs": initialMs, "stableMs": timings]))
        }
    }
}
