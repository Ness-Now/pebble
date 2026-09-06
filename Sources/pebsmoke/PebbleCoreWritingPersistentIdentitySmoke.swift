import Foundation
import PebbleCore

private let persistentWritingDuplicateWorldID = "civ45-p0-world"
private let persistentWritingLines = ["pierre", "presence", "bois", "source"]

private func persistentWritingStamp(
    worldID: String,
    materialID: Int,
    x: Int
) throws -> SignInscription {
    let identity = String(materialID, radix: 16)
    return try SignInscription(
        artifactID: "inscription-"
            + String(repeating: "0", count: 64 - identity.count)
            + identity,
        materialID: materialID,
        contentDigest: String(repeating: "a", count: 64),
        worldID: worldID,
        dimension: Dim.overworld.rawValue,
        x: x,
        y: 64,
        z: 1,
        lines: persistentWritingLines
    )
}

private func persistentWritingBlockEntity(
    worldID: String,
    materialID: Int,
    x: Int,
    mutateStamp: ((inout [String: Any]) -> Void)? = nil
) throws -> BlockEntityData {
    let blockEntity = makeSignBE(x, 64, 1)
    blockEntity.lines = persistentWritingLines
    var object = try JSONSerialization.jsonObject(
        with: JSONEncoder().encode(blockEntity)
    ) as! [String: Any]
    var stamp = try JSONSerialization.jsonObject(
        with: JSONEncoder().encode(try persistentWritingStamp(
            worldID: worldID,
            materialID: materialID,
            x: x
        ))
    ) as! [String: Any]
    mutateStamp?(&stamp)
    object["signInscription"] = stamp
    return try JSONDecoder().decode(
        BlockEntityData.self,
        from: JSONSerialization.data(withJSONObject: object)
    )
}

private func persistentWritingChunkRecord(
    database: SaveDB,
    worldID: String,
    materialID: Int,
    cx: Int,
    x: Int,
    mutateStamp: ((inout [String: Any]) -> Void)? = nil
) throws -> ChunkRecord {
    let chunk = Chunk(cx: cx, cz: 0, minY: GEN_MIN_Y, height: WORLD_H)
    let localX = posMod(x, CHUNK_W)
    chunk.set(localX, 63, 1, UInt16(bid("stone")) << 4)
    chunk.set(localX, 64, 1, UInt16(bid("oak_sign")) << 4)
    return ChunkRecord(
        key: database.chunkKey(worldID, Dim.overworld.rawValue, cx, 0),
        worldId: worldID,
        dim: Dim.overworld.rawValue,
        cx: cx,
        cz: 0,
        blocks: chunk.blocks,
        biomes: chunk.biomes,
        blockEntities: [try persistentWritingBlockEntity(
            worldID: worldID,
            materialID: materialID,
            x: x,
            mutateStamp: mutateStamp
        )]
    )
}

private func persistentWritingChunkRecord(
    database: SaveDB,
    worldID: String,
    world: World,
    cx: Int
) -> ChunkRecord {
    let chunk = world.getChunk(cx, 0)!
    return ChunkRecord(
        key: database.chunkKey(worldID, Dim.overworld.rawValue, cx, 0),
        worldId: worldID,
        dim: Dim.overworld.rawValue,
        cx: cx,
        cz: 0,
        blocks: chunk.blocks,
        biomes: chunk.biomes,
        blockEntities: Array(chunk.blockEntities.values)
    )
}

private func persistentWritingAdopt(record: ChunkRecord, into world: World) {
    let chunk = Chunk(cx: record.cx, cz: record.cz, minY: GEN_MIN_Y, height: WORLD_H)
    chunk.blocks = record.blocks!
    chunk.biomes = record.biomes!
    world.setChunk(chunk)
    for blockEntity in record.blockEntities ?? [] {
        world.setBlockEntity(blockEntity)
    }
}

private func persistentWritingWorld(
    record: ChunkRecord,
    catalog: SignInscriptionIdentityCatalog
) -> World {
    let world = World(
        dim: .overworld,
        seed: 45,
        signInscriptionIdentityCatalog: catalog
    )
    persistentWritingAdopt(record: record, into: world)
    return world
}

private func persistentWritingCatalog(
    database: SaveDB,
    world: WorldRecord
) -> SignInscriptionIdentityCatalog {
    database.loadSignInscriptionIdentityCatalog(
        worldID: world.id,
        nextPhysicalIdentity: world.nextEntityId
    )
}

private func persistentWritingRecord(
    id: String,
    nextEntityID: Int
) -> WorldRecord {
    var record = WorldRecord(
        id: id,
        name: "CIV-45 persistent identity",
        seed: 45,
        gameMode: 1,
        difficulty: 1
    )
    record.nextEntityId = nextEntityID
    return record
}

private func persistentWritingBytes(_ blockEntities: [BlockEntityData]) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(blockEntities)
}

func runPebbleCoreWritingPersistentIdentitySmoke() {
    section("CIV-45 persistent World-global material identity P0")
    let originalPhysicalCounter = peekNextEntityId()
    defer { resetEntityIds(originalPhysicalCounter) }
    do {
        let database = SaveDB()
        let duplicate = persistentWritingRecord(
            id: persistentWritingDuplicateWorldID,
            nextEntityID: 401
        )
        database.putWorld(duplicate)
        let chunkA = try persistentWritingChunkRecord(
            database: database,
            worldID: duplicate.id,
            materialID: 400,
            cx: 0,
            x: 1
        )
        let chunkB = try persistentWritingChunkRecord(
            database: database,
            worldID: duplicate.id,
            materialID: 400,
            cx: 20,
            x: 321
        )
        check("two real persistent chunks written", database.putChunks([chunkA, chunkB]))
        guard let persistedA = database.getChunk(duplicate.id, 0, 0, 0),
              let persistedB = database.getChunk(duplicate.id, 0, 20, 0) else {
            check("two real persistent chunks decode", false)
            return
        }
        check("two real persistent chunks decode", persistedA.blockEntities?.count == 1
            && persistedB.blockEntities?.count == 1)
        let persistedABytes = try persistentWritingBytes(persistedA.blockEntities!)
        resetEntityIds(duplicate.nextEntityId)

        let aFirst = persistentWritingWorld(
            record: persistedA,
            catalog: persistentWritingCatalog(database: database, world: duplicate)
        )
        check("A-only refuses duplicate persisted in unloaded B",
            (try? aFirst.inspectSignInscription(at: 1, 64, 1)) == nil)
        check("A-only refusal consumes no physical identity",
            peekNextEntityId() == duplicate.nextEntityId)

        resetEntityIds(duplicate.nextEntityId)
        let bAfterRestart = persistentWritingWorld(
            record: persistedB,
            catalog: persistentWritingCatalog(database: database, world: duplicate)
        )
        check("restart B-only refuses duplicate persisted in unloaded A",
            (try? bAfterRestart.inspectSignInscription(at: 321, 64, 1)) == nil)

        resetEntityIds(duplicate.nextEntityId)
        let bFirst = persistentWritingWorld(
            record: persistedB,
            catalog: persistentWritingCatalog(database: database, world: duplicate)
        )
        check("reverse order B-only refuses duplicate persisted in unloaded A",
            (try? bFirst.inspectSignInscription(at: 321, 64, 1)) == nil)

        resetEntityIds(duplicate.nextEntityId)
        let aAfterRestart = persistentWritingWorld(
            record: persistedA,
            catalog: persistentWritingCatalog(database: database, world: duplicate)
        )
        check("reverse restart A-only refuses duplicate persisted in unloaded B",
            (try? aAfterRestart.inspectSignInscription(at: 1, 64, 1)) == nil)

        aAfterRestart.removeChunk(0, 0)
        persistentWritingAdopt(record: persistedB, into: aAfterRestart)
        check("unload A then reload B keeps global duplicate refusal",
            (try? aAfterRestart.inspectSignInscription(at: 321, 64, 1)) == nil)

        let simultaneous = World(
            dim: .overworld,
            seed: 45,
            signInscriptionIdentityCatalog: persistentWritingCatalog(
                database: database,
                world: duplicate
            )
        )
        persistentWritingAdopt(record: persistedA, into: simultaneous)
        persistentWritingAdopt(record: persistedB, into: simultaneous)
        check("simultaneously resident persisted duplicates both refuse",
            (try? simultaneous.inspectSignInscription(at: 1, 64, 1)) == nil
                && (try? simultaneous.inspectSignInscription(at: 321, 64, 1)) == nil)

        check("save after refusal writes unchanged chunk", database.putChunks([persistedA]))
        let savedAfterRefusal = database.getChunk(duplicate.id, 0, 0, 0)!
        check("save after refusal preserves exact physical stamp",
            try persistentWritingBytes(savedAfterRefusal.blockEntities!) == persistedABytes)
        let refusedAfterSave = persistentWritingWorld(
            record: savedAfterRefusal,
            catalog: persistentWritingCatalog(database: database, world: duplicate)
        )
        check("save after refusal cannot promote either duplicate",
            (try? refusedAfterSave.inspectSignInscription(at: 1, 64, 1)) == nil)

        let valid = persistentWritingRecord(id: "civ45-valid-world", nextEntityID: 502)
        database.putWorld(valid)
        let validA = try persistentWritingChunkRecord(
            database: database,
            worldID: valid.id,
            materialID: 500,
            cx: 0,
            x: 1
        )
        let validB = try persistentWritingChunkRecord(
            database: database,
            worldID: valid.id,
            materialID: 501,
            cx: 20,
            x: 321
        )
        check("distinct identities in multiple chunks persist", database.putChunks([validA, validB]))
        resetEntityIds(valid.nextEntityId)
        let validAOnly = persistentWritingWorld(
            record: database.getChunk(valid.id, 0, 0, 0)!,
            catalog: persistentWritingCatalog(database: database, world: valid)
        )
        check("valid World A-only retains unique authority",
            (try? validAOnly.inspectSignInscription(at: 1, 64, 1))?.materialID == 500)
        resetEntityIds(valid.nextEntityId)
        let validBAfterRestart = persistentWritingWorld(
            record: database.getChunk(valid.id, 0, 20, 0)!,
            catalog: persistentWritingCatalog(database: database, world: valid)
        )
        check("valid World restart B-only retains distinct authority",
            (try? validBAfterRestart.inspectSignInscription(at: 321, 64, 1))?.materialID == 501)

        let edited = validAOnly.getBlockEntity(1, 64, 1)!
        edited.lines = ["changed", "presence", "bois", "source"]
        check("normal sign editing still invalidates inscription",
            edited.signInscription == nil
                && (try? validAOnly.inspectSignInscription(at: 1, 64, 1)) == nil)
        validAOnly.setBlock(1, 64, 1, 0, SET_SILENT)
        validAOnly.setBlock(1, 64, 1, Int(bid("oak_sign")) << 4, SET_SILENT)
        validAOnly.setBlockEntity(makeSignBE(1, 64, 1))
        let replacement = try persistentWritingStamp(
            worldID: valid.id,
            materialID: 502,
            x: 1
        )
        try validAOnly.inscribeSign(replacement)
        check("replacement allocates a fresh identity exactly once",
            peekNextEntityId() == 503
                && (try? validAOnly.inspectSignInscription(at: 1, 64, 1)) == replacement)
        var validAfterReplacement = valid
        validAfterReplacement.nextEntityId = peekNextEntityId()
        database.putWorld(validAfterReplacement)
        let replacedChunk = persistentWritingChunkRecord(
            database: database,
            worldID: valid.id,
            world: validAOnly,
            cx: 0
        )
        check("replacement chunk persists", database.putChunks([replacedChunk]))
        resetEntityIds(validAfterReplacement.nextEntityId)
        let replacementRestart = persistentWritingWorld(
            record: database.getChunk(valid.id, 0, 0, 0)!,
            catalog: persistentWritingCatalog(database: database, world: validAfterReplacement)
        )
        check("fresh replacement identity survives restart",
            (try? replacementRestart.inspectSignInscription(at: 1, 64, 1)) == replacement)

        let legacy = persistentWritingRecord(id: "civ45-legacy-world", nextEntityID: 1)
        database.putWorld(legacy)
        let legacyChunk = Chunk(cx: 0, cz: 0, minY: GEN_MIN_Y, height: WORLD_H)
        legacyChunk.set(1, 63, 1, UInt16(bid("stone")) << 4)
        legacyChunk.set(1, 64, 1, UInt16(bid("oak_sign")) << 4)
        let legacySign = makeSignBE(1, 64, 1)
        legacySign.lines = ["old", "world", "sign", "text"]
        let legacyRecord = ChunkRecord(
            key: database.chunkKey(legacy.id, 0, 0, 0),
            worldId: legacy.id,
            dim: 0,
            cx: 0,
            cz: 0,
            blocks: legacyChunk.blocks,
            biomes: legacyChunk.biomes,
            blockEntities: [legacySign]
        )
        check("pre-CIV-45 World persists without migration", database.putChunks([legacyRecord]))
        resetEntityIds(legacy.nextEntityId)
        let legacyWorld = persistentWritingWorld(
            record: database.getChunk(legacy.id, 0, 0, 0)!,
            catalog: persistentWritingCatalog(database: database, world: legacy)
        )
        check("pre-CIV-45 sign remains non-authoritative",
            (try? legacyWorld.inspectSignInscription(at: 1, 64, 1)) == nil)
        legacyWorld.setBlockEntity(makeSignBE(1, 64, 1))
        let firstLegacyInscription = try persistentWritingStamp(
            worldID: legacy.id,
            materialID: 1,
            x: 1
        )
        try legacyWorld.inscribeSign(firstLegacyInscription)
        check("pre-CIV-45 World can allocate its first inscription",
            peekNextEntityId() == 2
                && (try? legacyWorld.inspectSignInscription(at: 1, 64, 1)) == firstLegacyInscription)

        let corrupt = persistentWritingRecord(id: "civ45-corrupt-world", nextEntityID: 602)
        database.putWorld(corrupt)
        let soundChunk = try persistentWritingChunkRecord(
            database: database,
            worldID: corrupt.id,
            materialID: 600,
            cx: 0,
            x: 1
        )
        let malformedChunk = try persistentWritingChunkRecord(
            database: database,
            worldID: corrupt.id,
            materialID: 601,
            cx: 20,
            x: 321,
            mutateStamp: { $0["contentDigest"] = "invalid" }
        )
        check("decodable malformed identity mechanism persists",
            database.putChunks([soundChunk, malformedChunk]))
        resetEntityIds(corrupt.nextEntityId)
        let corruptWorld = persistentWritingWorld(
            record: database.getChunk(corrupt.id, 0, 0, 0)!,
            catalog: persistentWritingCatalog(database: database, world: corrupt)
        )
        check("malformed unloaded identity fails closed before access",
            (try? corruptWorld.inspectSignInscription(at: 1, 64, 1)) == nil)
        corruptWorld.setBlock(2, 63, 1, Int(bid("stone")) << 4, SET_SILENT)
        corruptWorld.setBlock(2, 64, 1, Int(bid("oak_sign")) << 4, SET_SILENT)
        corruptWorld.setBlockEntity(makeSignBE(2, 64, 1))
        let counterBeforeCorruptAdmission = peekNextEntityId()
        do {
            try corruptWorld.inscribeSign(try persistentWritingStamp(
                worldID: corrupt.id,
                materialID: counterBeforeCorruptAdmission,
                x: 2
            ))
            check("corrupt catalog refuses new authority", false)
        } catch {
            check("corrupt catalog refuses new authority", true)
        }
        check("corrupt admission refusal is allocation-atomic",
            peekNextEntityId() == counterBeforeCorruptAdmission
                && corruptWorld.getBlockEntity(2, 64, 1)?.signInscription == nil)
    } catch {
        check("persistent identity correction regression completes", false, "\(error)")
    }
}
