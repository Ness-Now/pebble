import Foundation
import SQLite3
import PebbleCore

private let c02Lines = ["pierre", "presence", "bois", "source"]
private let c02SQLiteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private func c02WorldRecord(_ id: String, next: Int) -> WorldRecord {
    var record = WorldRecord(id: id, name: "CIV-45 Correction 02", seed: 45,
                             gameMode: 1, difficulty: 1)
    record.spawnX = 1
    record.spawnY = 65
    record.spawnZ = 1
    record.nextEntityId = next
    return record
}

private func c02Stamp(
    worldID: String,
    materialID: Int,
    dimension: Int = 0,
    x: Int,
    y: Int = 64,
    z: Int = 1
) throws -> SignInscription {
    let suffix = String(materialID, radix: 16)
    return try SignInscription(
        artifactID: "inscription-" + String(repeating: "0", count: 64 - suffix.count) + suffix,
        materialID: materialID,
        contentDigest: String(repeating: "b", count: 64),
        worldID: worldID,
        dimension: dimension,
        x: x,
        y: y,
        z: z,
        lines: c02Lines
    )
}

private func c02StampedBE(
    worldID: String,
    materialID: Int,
    dimension: Int = 0,
    x: Int,
    y: Int = 64,
    z: Int = 1
) throws -> BlockEntityData {
    let blockEntity = makeSignBE(x, y, z)
    blockEntity.lines = c02Lines
    var object = try JSONSerialization.jsonObject(
        with: JSONEncoder().encode(blockEntity)
    ) as! [String: Any]
    object["signInscription"] = try JSONSerialization.jsonObject(
        with: JSONEncoder().encode(try c02Stamp(
            worldID: worldID,
            materialID: materialID,
            dimension: dimension,
            x: x,
            y: y,
            z: z
        ))
    )
    return try JSONDecoder().decode(
        BlockEntityData.self,
        from: JSONSerialization.data(withJSONObject: object)
    )
}

private func c02ChunkRecord(
    database: SaveDB,
    worldID: String,
    dimension: Int = 0,
    cx: Int,
    x: Int,
    materialID: Int? = nil
) throws -> ChunkRecord {
    let dim = Dim(rawValue: dimension)!
    let info = DIMS[dim.rawValue]
    let chunk = Chunk(cx: cx, cz: 0, minY: info.minY, height: info.height)
    let localX = posMod(x, CHUNK_W)
    chunk.set(localX, 63, 1, UInt16(bid("stone")) << 4)
    chunk.set(localX, 64, 1, UInt16(bid("oak_sign")) << 4)
    let blockEntities: [BlockEntityData]
    if let materialID {
        blockEntities = [try c02StampedBE(
            worldID: worldID,
            materialID: materialID,
            dimension: dimension,
            x: x
        )]
    } else {
        blockEntities = [makeSignBE(x, 64, 1)]
    }
    return ChunkRecord(
        key: database.chunkKey(worldID, dimension, cx, 0),
        worldId: worldID,
        dim: dimension,
        cx: cx,
        cz: 0,
        blocks: chunk.blocks,
        biomes: chunk.biomes,
        blockEntities: blockEntities
    )
}

private func c02Record(database: SaveDB, worldID: String, world: World, cx: Int) -> ChunkRecord {
    let chunk = world.getChunk(cx, 0)!
    return ChunkRecord(
        key: database.chunkKey(worldID, world.dim.rawValue, cx, 0),
        worldId: worldID,
        dim: world.dim.rawValue,
        cx: cx,
        cz: 0,
        blocks: chunk.blocks,
        biomes: chunk.biomes,
        blockEntities: Array(chunk.blockEntities.values)
    )
}

private func c02Adopt(_ record: ChunkRecord, into world: World) {
    let chunk = Chunk(cx: record.cx, cz: record.cz,
                      minY: DIMS[record.dim].minY, height: DIMS[record.dim].height)
    chunk.blocks = record.blocks!
    chunk.biomes = record.biomes!
    world.setChunk(chunk)
    for blockEntity in record.blockEntities ?? [] { world.setBlockEntity(blockEntity) }
}

private func c02World(
    dimension: Int = 0,
    catalog: SignInscriptionIdentityCatalog,
    records: [ChunkRecord]
) -> World {
    let world = World(dim: Dim(rawValue: dimension)!, seed: 45,
                      signInscriptionIdentityCatalog: catalog)
    for record in records { c02Adopt(record, into: world) }
    return world
}

private func c02Refuses(_ world: World, x: Int) -> Bool {
    (try? world.inspectSignInscription(at: x, 64, 1)) == nil
}

private func c02SQL(_ sql: String) -> Bool {
    var connection: OpaquePointer?
    let path = vcSupportDir().appendingPathComponent("pebble.db").path
    guard sqlite3_open_v2(path, &connection, SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil)
            == SQLITE_OK else { return false }
    defer { sqlite3_close(connection) }
    return sqlite3_exec(connection, sql, nil, nil, nil) == SQLITE_OK
}

private func c02RawVCK(blocks: [UInt16], biomes: [UInt8], tail: [String: Any]) throws -> Data {
    var data = Data("VCK1".utf8)
    data.append(1)
    func appendU32(_ value: Int) {
        var little = UInt32(value).littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    appendU32(blocks.count)
    blocks.withUnsafeBufferPointer { buffer in
        buffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: blocks.count * 2) {
            data.append($0, count: blocks.count * 2)
        }
    }
    appendU32(biomes.count)
    data.append(contentsOf: biomes)
    let json = try JSONSerialization.data(withJSONObject: tail, options: [.sortedKeys])
    appendU32(json.count)
    data.append(json)
    return data
}

private func c02InsertLegacyRow(
    worldID: String,
    dimension: Int,
    cx: Int,
    data: Data
) -> Bool {
    var connection: OpaquePointer?
    let path = vcSupportDir().appendingPathComponent("pebble.db").path
    guard sqlite3_open_v2(path, &connection, SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil)
            == SQLITE_OK, let connection else { return false }
    defer { sqlite3_close(connection) }
    var statement: OpaquePointer?
    let sql = """
        INSERT OR REPLACE INTO chunks(
          world,dim,cx,cz,data,inscriptionIndexVersion,inscriptionIndexDigest
        ) VALUES(?,?,?,?,?,0,'')
        """
    guard sqlite3_prepare_v2(connection, sql, -1, &statement, nil) == SQLITE_OK,
          let statement else { return false }
    defer { sqlite3_finalize(statement) }
    sqlite3_bind_text(statement, 1, worldID, -1, c02SQLiteTransient)
    sqlite3_bind_int(statement, 2, Int32(dimension))
    sqlite3_bind_int(statement, 3, Int32(cx))
    sqlite3_bind_int(statement, 4, 0)
    data.withUnsafeBytes {
        _ = sqlite3_bind_blob(statement, 5, $0.baseAddress, Int32($0.count), c02SQLiteTransient)
    }
    return sqlite3_step(statement) == SQLITE_DONE
}

func runPebbleCoreWritingIdentityCorrection02Smoke() {
    section("CIV-45 Correction 02 current/durable identity authority")
    let originalCounter = peekNextEntityId()
    defer { resetEntityIds(originalCounter) }
    do {
        // Resident absence supersedes the stale durable claim.
        let database = SaveDB()
        let removal = c02WorldRecord("civ45-c02-removal", next: 1002)
        database.putWorld(removal)
        let removalA = try c02ChunkRecord(database: database, worldID: removal.id,
                                          cx: 0, x: 1, materialID: 1000)
        let removalB = try c02ChunkRecord(database: database, worldID: removal.id,
                                          cx: 20, x: 321, materialID: 1000)
        check("dirty removal fixture persists", database.putChunks([removalA, removalB]))
        resetEntityIds(removal.nextEntityId)
        let removalCatalog = database.loadSignInscriptionIdentityCatalog(
            worldID: removal.id, nextPhysicalIdentity: removal.nextEntityId)
        let removalWorld = c02World(catalog: removalCatalog, records: [removalA, removalB])
        removalWorld.getBlockEntity(1, 64, 1)!.lines = ["changed", "presence", "bois", "source"]
        removalWorld.getChunk(0, 0)!.modified = true
        check("resident dirty removal supersedes persisted A:X",
              (try? removalWorld.inspectSignInscription(at: 321, 64, 1))?.materialID == 1000)
        let removalCurrent = c02Record(database: database, worldID: removal.id,
                                       world: removalWorld, cx: 0)
        check("dirty removal commits with authority", database.putChunks(
            [removalCurrent], nextPhysicalIdentity: removal.nextEntityId,
            inscriptionCatalog: removalCatalog))
        check("autosave does not change removal validity",
              (try? removalWorld.inspectSignInscription(at: 321, 64, 1))?.materialID == 1000)
        let removalRestart = c02World(
            catalog: database.loadSignInscriptionIdentityCatalog(
                worldID: removal.id, nextPhysicalIdentity: removal.nextEntityId),
            records: [removalB]
        )
        check("dirty removal restart preserves B authority",
              (try? removalRestart.inspectSignInscription(at: 321, 64, 1))?.materialID == 1000)

        // Replacement gives A a fresh identity while B keeps X.
        let replacement = c02WorldRecord("civ45-c02-replacement", next: 1102)
        database.putWorld(replacement)
        let replacementA = try c02ChunkRecord(database: database, worldID: replacement.id,
                                              cx: 0, x: 1, materialID: 1100)
        let replacementB = try c02ChunkRecord(database: database, worldID: replacement.id,
                                              cx: 20, x: 321, materialID: 1100)
        check("dirty replacement fixture persists", database.putChunks([replacementA, replacementB]))
        resetEntityIds(1101)
        let replacementCatalog = database.loadSignInscriptionIdentityCatalog(
            worldID: replacement.id, nextPhysicalIdentity: replacement.nextEntityId)
        let replacementWorld = c02World(catalog: replacementCatalog,
                                        records: [replacementA, replacementB])
        replacementWorld.setBlockEntity(makeSignBE(1, 64, 1))
        let fresh = try c02Stamp(worldID: replacement.id, materialID: 1101, x: 1)
        try replacementWorld.inscribeSign(fresh)
        check("resident dirty replacement A:Y is authoritative",
              (try? replacementWorld.inspectSignInscription(at: 1, 64, 1)) == fresh)
        check("resident dirty replacement leaves B:X authoritative",
              (try? replacementWorld.inspectSignInscription(at: 321, 64, 1))?.materialID == 1100)
        let replacementCurrent = c02Record(database: database, worldID: replacement.id,
                                           world: replacementWorld, cx: 0)
        check("dirty replacement commits", database.putChunks(
            [replacementCurrent], nextPhysicalIdentity: peekNextEntityId(),
            inscriptionCatalog: replacementCatalog))
        check("autosave does not change replacement authority",
              (try? replacementWorld.inspectSignInscription(at: 1, 64, 1)) == fresh
                && (try? replacementWorld.inspectSignInscription(at: 321, 64, 1))?.materialID == 1100)

        // A newly introduced dirty duplicate refuses before and after commit.
        let addition = c02WorldRecord("civ45-c02-addition", next: 1202)
        database.putWorld(addition)
        let additionA = try c02ChunkRecord(database: database, worldID: addition.id,
                                           cx: 0, x: 1)
        let additionB = try c02ChunkRecord(database: database, worldID: addition.id,
                                           cx: 20, x: 321, materialID: 1200)
        check("dirty addition fixture persists", database.putChunks([additionA, additionB]))
        resetEntityIds(addition.nextEntityId)
        let additionCatalog = database.loadSignInscriptionIdentityCatalog(
            worldID: addition.id, nextPhysicalIdentity: addition.nextEntityId)
        let additionWorld = c02World(catalog: additionCatalog, records: [additionA, additionB])
        additionWorld.setBlockEntity(try c02StampedBE(
            worldID: addition.id, materialID: 1200, x: 1))
        check("new resident dirty duplicate refuses both copies",
              c02Refuses(additionWorld, x: 1) && c02Refuses(additionWorld, x: 321))
        let additionCurrent = c02Record(database: database, worldID: addition.id,
                                        world: additionWorld, cx: 0)
        check("dirty duplicate persists fail-closed", database.putChunks(
            [additionCurrent], nextPhysicalIdentity: addition.nextEntityId,
            inscriptionCatalog: additionCatalog))
        check("autosave cannot promote a dirty duplicate",
              c02Refuses(additionWorld, x: 1) && c02Refuses(additionWorld, x: 321))

        // One namespace spans dimensions, while separate Worlds remain isolated.
        let dimensions = c02WorldRecord("civ45-c02-dimensions", next: 1302)
        database.putWorld(dimensions)
        let overworldRecord = try c02ChunkRecord(database: database, worldID: dimensions.id,
                                                 dimension: 0, cx: 0, x: 1, materialID: 1300)
        let netherRecord = try c02ChunkRecord(database: database, worldID: dimensions.id,
                                             dimension: 1, cx: 20, x: 321, materialID: 1300)
        check("cross-dimension duplicate persists", database.putChunks([overworldRecord, netherRecord]))
        resetEntityIds(dimensions.nextEntityId)
        let dimensionCatalog = database.loadSignInscriptionIdentityCatalog(
            worldID: dimensions.id, nextPhysicalIdentity: dimensions.nextEntityId)
        let overworld = c02World(dimension: 0, catalog: dimensionCatalog, records: [overworldRecord])
        let nether = c02World(dimension: 1, catalog: dimensionCatalog, records: [netherRecord])
        check("cross-dimension duplicate refuses from overworld", c02Refuses(overworld, x: 1))
        check("cross-dimension duplicate refuses from nether", c02Refuses(nether, x: 321))

        for id in ["civ45-c02-world-a", "civ45-c02-world-b"] {
            let record = c02WorldRecord(id, next: 1402)
            database.putWorld(record)
            let chunk = try c02ChunkRecord(database: database, worldID: id,
                                           cx: 0, x: 1, materialID: 1400)
            check("isolated \(id) persists", database.putChunks([chunk]))
            resetEntityIds(record.nextEntityId)
            let world = c02World(catalog: database.loadSignInscriptionIdentityCatalog(
                worldID: id, nextPhysicalIdentity: record.nextEntityId), records: [chunk])
            check("isolated \(id) accepts reused number",
                  (try? world.inspectSignInscription(at: 1, 64, 1))?.materialID == 1400)
        }

        // Known unrelated BE corruption no longer denies an indexed sound sign.
        let unrelated = c02WorldRecord("civ45-c02-unrelated-corruption", next: 1502)
        database.putWorld(unrelated)
        let sound = try c02ChunkRecord(database: database, worldID: unrelated.id,
                                       cx: 0, x: 1, materialID: 1500)
        check("sound corruption-control sign persists", database.putChunks([sound]))
        let malformedBase = try c02ChunkRecord(database: database, worldID: unrelated.id,
                                               cx: 20, x: 321)
        let unrelatedRaw = try c02RawVCK(
            blocks: malformedBase.blocks!, biomes: malformedBase.biomes!,
            tail: ["entities": [], "blockEntities": [["x": 321, "y": 64, "z": 1]]]
        )
        check("unrelated malformed legacy BE row inserted", c02InsertLegacyRow(
            worldID: unrelated.id, dimension: 0, cx: 20, data: unrelatedRaw))
        resetEntityIds(unrelated.nextEntityId)
        let unrelatedCatalog = database.loadSignInscriptionIdentityCatalog(
            worldID: unrelated.id, nextPhysicalIdentity: unrelated.nextEntityId)
        let unrelatedWorld = c02World(catalog: unrelatedCatalog, records: [sound])
        check("unrelated malformed BE does not disable CIV-45",
              (try? unrelatedWorld.inspectSignInscription(at: 1, 64, 1))?.materialID == 1500)

        let relevant = c02WorldRecord("civ45-c02-relevant-corruption", next: 1602)
        database.putWorld(relevant)
        let relevantSound = try c02ChunkRecord(database: database, worldID: relevant.id,
                                               cx: 0, x: 1, materialID: 1600)
        check("relevant corruption-control sign persists", database.putChunks([relevantSound]))
        let relevantBase = try c02ChunkRecord(database: database, worldID: relevant.id,
                                              cx: 20, x: 321)
        let relevantRaw = try c02RawVCK(
            blocks: relevantBase.blocks!, biomes: relevantBase.biomes!,
            tail: ["entities": [], "blockEntities": [[
                "type": "sign", "x": 321, "y": 64, "z": 1,
                "signInscription": ["materialID": 1601]
            ]]]
        )
        check("relevant malformed legacy inscription inserted", c02InsertLegacyRow(
            worldID: relevant.id, dimension: 0, cx: 20, data: relevantRaw))
        resetEntityIds(relevant.nextEntityId)
        let relevantCatalog = database.loadSignInscriptionIdentityCatalog(
            worldID: relevant.id, nextPhysicalIdentity: relevant.nextEntityId)
        let relevantWorld = c02World(catalog: relevantCatalog, records: [relevantSound])
        check("malformed inscription payload still fails closed", c02Refuses(relevantWorld, x: 1))

        // Index corruption is detected without falling back to a voxel scan.
        let corruptIndex = c02WorldRecord("civ45-c02-index-corruption", next: 1702)
        database.putWorld(corruptIndex)
        let corruptIndexChunk = try c02ChunkRecord(database: database, worldID: corruptIndex.id,
                                                   cx: 0, x: 1, materialID: 1700)
        check("index corruption fixture persists", database.putChunks([corruptIndexChunk]))
        check("compact index bytes corrupted", c02SQL(
            "UPDATE sign_inscription_chunks SET data=x'00' WHERE world='\(corruptIndex.id)'"))
        resetEntityIds(corruptIndex.nextEntityId)
        let corruptIndexCatalog = database.loadSignInscriptionIdentityCatalog(
            worldID: corruptIndex.id, nextPhysicalIdentity: corruptIndex.nextEntityId)
        let corruptIndexWorld = c02World(catalog: corruptIndexCatalog, records: [corruptIndexChunk])
        check("corrupt compact index fails closed", c02Refuses(corruptIndexWorld, x: 1))
        check("corrupt compact index does not trigger voxel fallback",
              database.lastSignInscriptionIndexLoadMetrics.decodedVoxelCells == 0)

        // Legacy sign text is presentation data, never a CIV-45 identity.
        let legacyText = c02WorldRecord("civ45-c02-legacy-text", next: 1752)
        database.putWorld(legacyText)
        let legacyTextChunk = try c02ChunkRecord(
            database: database, worldID: legacyText.id, cx: 0, x: 1
        )
        legacyTextChunk.blockEntities![0].lines = ["ancien", "texte", "sans", "identite"]
        check("legacy text-only sign fixture persists", database.putChunks([legacyTextChunk]))
        check("legacy text-only sign is marked for one-shot migration", c02SQL(
            "UPDATE chunks SET inscriptionIndexVersion=0,inscriptionIndexDigest='' "
                + "WHERE world='\(legacyText.id)';"
                + "DELETE FROM sign_inscription_chunks WHERE world='\(legacyText.id)'"))
        resetEntityIds(legacyText.nextEntityId)
        let legacyTextCatalog = database.loadSignInscriptionIdentityCatalog(
            worldID: legacyText.id, nextPhysicalIdentity: legacyText.nextEntityId
        )
        check("legacy text-only migration decodes its payload once",
              database.lastSignInscriptionIndexLoadMetrics.migratedChunkPayloads == 1)
        let legacyTextWorld = c02World(catalog: legacyTextCatalog, records: [legacyTextChunk])
        check("legacy text-only migration fabricates no material authority",
              (try? legacyTextWorld.inspectSignInscription(at: 1, 64, 1)) == nil)

        // Objective cost proof: one legacy migration, zero steady-state voxels.
        let scale = c02WorldRecord("civ45-c02-scale", next: 1802)
        database.putWorld(scale)
        var scaleRows: [ChunkRecord] = []
        for cx in 0..<24 {
            scaleRows.append(try c02ChunkRecord(database: database, worldID: scale.id,
                                               cx: cx, x: cx * CHUNK_W + 1))
        }
        check("scale fixture persists with transactional indexes", database.putChunks(scaleRows))
        _ = database.loadSignInscriptionIdentityCatalog(
            worldID: scale.id, nextPhysicalIdentity: scale.nextEntityId)
        let indexedMetrics = database.lastSignInscriptionIndexLoadMetrics
        check("indexed steady-state opens without voxel decode",
              indexedMetrics.indexedChunkRows == 24
                && indexedMetrics.migratedChunkPayloads == 0
                && indexedMetrics.decodedVoxelCells == 0)
        check("Correction 01 rows downgraded for one-shot migration", c02SQL(
            "UPDATE chunks SET inscriptionIndexVersion=0,inscriptionIndexDigest='' WHERE world='\(scale.id)';"
                + "DELETE FROM sign_inscription_chunks WHERE world='\(scale.id)'"))
        _ = database.loadSignInscriptionIdentityCatalog(
            worldID: scale.id, nextPhysicalIdentity: scale.nextEntityId)
        let migrationMetrics = database.lastSignInscriptionIndexLoadMetrics
        check("legacy migration decodes each payload exactly once",
              migrationMetrics.migratedChunkPayloads == 24
                && migrationMetrics.decodedVoxelCells == 24 * CHUNK_W * CHUNK_W * WORLD_H)
        _ = database.loadSignInscriptionIdentityCatalog(
            worldID: scale.id, nextPhysicalIdentity: scale.nextEntityId)
        let reopenedMetrics = database.lastSignInscriptionIndexLoadMetrics
        check("post-migration reopen returns to compact steady state",
              reopenedMetrics.indexedChunkRows == 24
                && reopenedMetrics.migratedChunkPayloads == 0
                && reopenedMetrics.decodedVoxelCells == 0)

        runC02GameCoreConcurrencyChecks()
        runC02GameCoreStagedUnloadChecks()
    } catch {
        check("Correction 02 identity regression completes", false, "\(error)")
    }
}

private func runC02GameCoreConcurrencyChecks() {
    let game = GameCore()
    let record = c02WorldRecord("civ45-c02-gamecore-concurrency", next: 1902)
    game.db.putWorld(record)
    do {
        let a = try c02ChunkRecord(database: game.db, worldID: record.id,
                                   cx: 0, x: 1, materialID: 1900)
        let b = try c02ChunkRecord(database: game.db, worldID: record.id,
                                   cx: 20, x: 321, materialID: 1900)
        check("GameCore concurrency fixture persists", game.db.putChunks([a, b]))
        game.loadWorld(record.id)
        guard let liveA = game.world.getBlockEntity(1, 64, 1) else {
            check("GameCore loads resident A", false)
            return
        }
        c02Adopt(b, into: game.world)
        liveA.lines = ["removed", "presence", "bois", "source"]
        game.world.getChunk(0, 0)!.modified = true
        game.world.getChunk(20, 0)!.modified = true
        check("GameCore pre-transaction inspection sees current B",
              (try? game.world.inspectSignInscription(at: 321, 64, 1))?.materialID == 1900)
        let catalog = game.world.signInscriptionIdentityCatalog!
        let generationBefore = catalog.generation
        let readerValidated = DispatchSemaphore(value: 0)
        let releaseReader = DispatchSemaphore(value: 0)
        let captureAttempted = DispatchSemaphore(value: 0)
        let transactionBegan = DispatchSemaphore(value: 0)
        let committed = DispatchSemaphore(value: 0)
        let releaseCommit = DispatchSemaphore(value: 0)
        let authorityAdvanced = DispatchSemaphore(value: 0)
        catalog.testingReadCriticalSectionHook = {
            readerValidated.signal()
            _ = releaseReader.wait(timeout: .now() + 5)
        }
        game.testingSignInscriptionPersistenceCaptureHook = {
            captureAttempted.signal()
        }
        game.db.testingSignInscriptionPersistenceHook = { phase in
            if phase == .transactionBegan { transactionBegan.signal() }
            if phase == .committedBeforeAuthority {
                committed.signal()
                return releaseCommit.wait(timeout: .now() + 5) == .success
            }
            if phase == .authorityAdvanced { authorityAdvanced.signal() }
            return true
        }
        let firstReaderDone = DispatchSemaphore(value: 0)
        var firstReaderAccepted = false
        DispatchQueue.global().async {
            firstReaderAccepted =
                (try? game.world.inspectSignInscription(at: 321, 64, 1))?.materialID == 1900
            firstReaderDone.signal()
        }
        guard readerValidated.wait(timeout: .now() + 5) == .success else {
            check("reader reaches validated pre-finalization seam", false)
            catalog.testingReadCriticalSectionHook = nil
            game.testingSignInscriptionPersistenceCaptureHook = nil
            game.db.testingSignInscriptionPersistenceHook = nil
            return
        }
        check("reader reaches validated pre-finalization seam", true)
        DispatchQueue.global().async {
            game.saveAndFlush(synchronous: false)
        }
        guard captureAttempted.wait(timeout: .now() + 5) == .success else {
            check("save reaches capture authority seam", false)
            catalog.testingReadCriticalSectionHook = nil
            game.testingSignInscriptionPersistenceCaptureHook = nil
            game.db.testingSignInscriptionPersistenceHook = nil
            return
        }
        check("save transaction cannot begin inside reader authority view",
              transactionBegan.wait(timeout: .now() + 0.1) == .timedOut)
        releaseReader.signal()
        check("pre-save reader finalizes before authority mutation",
              firstReaderDone.wait(timeout: .now() + 5) == .success && firstReaderAccepted)
        catalog.testingReadCriticalSectionHook = nil
        game.testingSignInscriptionPersistenceCaptureHook = nil
        check("save transaction begins after reader finalizes",
              transactionBegan.wait(timeout: .now() + 5) == .success)
        guard committed.wait(timeout: .now() + 5) == .success else {
            check("GameCore reaches post-commit/pre-advancement seam", false)
            game.db.testingSignInscriptionPersistenceHook = nil
            return
        }
        check("GameCore reaches post-commit/pre-advancement seam", true)
        let readerDone = DispatchSemaphore(value: 0)
        var readerAccepted = false
        DispatchQueue.global().async {
            readerAccepted = (try? game.world.inspectSignInscription(at: 321, 64, 1))?.materialID == 1900
            readerDone.signal()
        }
        check("reader cannot cross committed-but-unadvanced window",
              readerDone.wait(timeout: .now() + 0.1) == .timedOut)
        releaseCommit.signal()
        check("multi-chunk authority advances after commit",
              authorityAdvanced.wait(timeout: .now() + 5) == .success)
        check("blocked reader completes against advanced authority",
              readerDone.wait(timeout: .now() + 5) == .success && readerAccepted)
        check("pre-commit generation token becomes stale",
              !catalog.isCurrentGeneration(generationBefore))
        game.db.testingSignInscriptionPersistenceHook = nil
        let restartCatalog = game.db.loadSignInscriptionIdentityCatalog(
            worldID: record.id, nextPhysicalIdentity: record.nextEntityId)
        let restartWorld = c02World(catalog: restartCatalog, records: [
            game.db.getChunk(record.id, 0, 20, 0)!
        ])
        check("GameCore multi-chunk commit restarts atomically",
              (try? restartWorld.inspectSignInscription(at: 321, 64, 1))?.materialID == 1900)
    } catch {
        check("GameCore commit/read concurrency completes", false, "\(error)")
    }
}

private func runC02GameCoreStagedUnloadChecks() {
    let game = GameCore()
    let record = c02WorldRecord("civ45-c02-gamecore-unload", next: 2002)
    game.db.putWorld(record)
    do {
        let a = try c02ChunkRecord(database: game.db, worldID: record.id,
                                   cx: 0, x: 1, materialID: 2000)
        let b = try c02ChunkRecord(database: game.db, worldID: record.id,
                                   cx: 20, x: 321, materialID: 2000)
        check("GameCore unload fixture persists", game.db.putChunks([a, b]))
        game.loadWorld(record.id)
        let liveA = game.world.getBlockEntity(1, 64, 1)!
        liveA.lines = ["removed", "presence", "bois", "source"]
        game.world.getChunk(0, 0)!.modified = true
        game.player.setPos(10_000.5, 80, 10_000.5)
        _ = game.frame(dtMs: 50)
        check("normal GameCore streaming unloads dirty A", game.world.getChunk(0, 0) == nil)
        c02Adopt(b, into: game.world)
        check("staged dirty unloaded A supersedes durable A:X",
              (try? game.world.inspectSignInscription(at: 321, 64, 1))?.materialID == 2000)
        game.saveAndFlush(synchronous: true)
        check("staged unload commit preserves current authority",
              (try? game.world.inspectSignInscription(at: 321, 64, 1))?.materialID == 2000)
    } catch {
        check("GameCore staged unload regression completes", false, "\(error)")
    }
}

func runPebbleCoreWritingIdentityCorrection02CrashWriter() {
    let mode = ProcessInfo.processInfo.environment["PEBBLELAB_CIV45_C02_CRASH_PHASE"] ?? ""
    let game = GameCore()
    let record = c02WorldRecord("civ45-c02-crash-world", next: 1)
    game.db.putWorld(record)
    do {
        let blankA = try c02ChunkRecord(
            database: game.db, worldID: record.id, cx: 0, x: 1
        )
        let blankB = try c02ChunkRecord(
            database: game.db, worldID: record.id, cx: 20, x: 321
        )
        guard game.db.putChunks([blankA, blankB]) else {
            throw SignInscriptionError.unavailable
        }
    } catch {
        print("CIV45_C02_CRASH_WRITER baseline-failed=\(error)")
        fflush(stdout)
        exit(2)
    }
    game.loadWorld(record.id)
    do {
        guard let persistedB = game.db.getChunk(record.id, 0, 20, 0) else {
            throw SignInscriptionError.unavailable
        }
        c02Adopt(persistedB, into: game.world)
        let materialA = peekNextEntityId()
        try game.world.inscribeSign(c02Stamp(
            worldID: record.id,
            materialID: materialA,
            x: 1
        ))
        let materialB = peekNextEntityId()
        try game.world.inscribeSign(c02Stamp(
            worldID: record.id,
            materialID: materialB,
            x: 321
        ))
    } catch {
        print("CIV45_C02_CRASH_WRITER setup-failed=\(error)")
        fflush(stdout)
        exit(2)
    }

    let target: SignInscriptionPersistencePhase?
    switch mode {
    case "before-transaction": target = .prepared
    case "during-transaction": target = .beforeCommit
    case "after-commit-before-return": target = .committedBeforeAuthority
    case "after-return": target = nil
    default:
        print("CIV45_C02_CRASH_WRITER unsupported=\(mode)")
        fflush(stdout)
        exit(2)
    }
    if let target {
        game.db.testingSignInscriptionPersistenceHook = { phase in
            if phase == target {
                print("CIV45_C02_CRASH_WRITER phase=\(mode) boundary=\(phase.rawValue) next=\(peekNextEntityId())")
                fflush(stdout)
                exit(77)
            }
            return true
        }
        game.saveAndFlush(synchronous: false)
        dispatchMain()
    } else {
        game.saveAndFlush(synchronous: true)
        print("CIV45_C02_CRASH_WRITER phase=after-return boundary=returned next=\(peekNextEntityId())")
        check("after-return writer completed", true)
    }
}

func runPebbleCoreWritingIdentityCorrection02CrashReader() {
    let expected = ProcessInfo.processInfo.environment["PEBBLELAB_CIV45_C02_EXPECT"] ?? ""
    let game = GameCore()
    game.loadWorld("civ45-c02-crash-world")
    guard game.hasWorld() else {
        check("crash-boundary World reloads", false)
        return
    }
    guard let persistedB = game.db.getChunk("civ45-c02-crash-world", 0, 20, 0) else {
        check("crash-boundary second chunk reloads", false)
        return
    }
    c02Adopt(persistedB, into: game.world)
    let stampA = try? game.world.inspectSignInscription(at: 1, 64, 1)
    let stampB = try? game.world.inspectSignInscription(at: 321, 64, 1)
    if expected == "old" {
        check("pre-commit crash retains both durable blank signs",
              stampA == nil && stampB == nil)
    } else if expected == "new" {
        check("post-commit crash retains atomic two-chunk inscriptions",
              stampA?.materialID == 2 && stampB?.materialID == 3)
    } else {
        check("crash reader expectation is valid", false, expected)
    }
    check("crash boundary never reuses allocated physical identity", peekNextEntityId() == 5)
    check("crash restart uses compact index without voxel migration",
          game.db.lastSignInscriptionIndexLoadMetrics.migratedChunkPayloads == 0
            && game.db.lastSignInscriptionIndexLoadMetrics.decodedVoxelCells == 0)
    let observed = stampA == nil && stampB == nil ? "both-blank" : "both-inscribed"
    print("CIV45_C02_CRASH_READER expected=\(expected) observed=\(observed) next=\(peekNextEntityId())")
}
