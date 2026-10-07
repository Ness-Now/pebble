import Foundation
import PebbleCore
import SQLite3

private let numericSwelling = Double(bitPattern: 0x3f4bda1bd51d42c8)
private let numericVelocity = Double(bitPattern: 0x3fb64bc177620800)
private func numericBits(_ value: Double) -> String { String(format: "%016llx", value.bitPattern) }

private func numericChunkTail(_ world: String) throws -> Data {
    var connection: OpaquePointer?
    let path = vcSupportDir().appendingPathComponent("pebble.db").path
    guard sqlite3_open_v2(path, &connection, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
        throw NSError(domain: "numeric-sqlite-open", code: 1)
    }
    defer { sqlite3_close(connection) }
    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(connection, "SELECT data FROM chunks WHERE world=? ORDER BY dim,cx,cz LIMIT 1", -1, &statement, nil) == SQLITE_OK else {
        throw NSError(domain: "numeric-sqlite-select", code: 1)
    }
    defer { sqlite3_finalize(statement) }
    world.withCString { _ = sqlite3_bind_text(statement, 1, $0, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)) }
    guard sqlite3_step(statement) == SQLITE_ROW, let pointer = sqlite3_column_blob(statement, 0) else {
        throw NSError(domain: "numeric-sqlite-row", code: 1)
    }
    let blob = Data(bytes: pointer, count: Int(sqlite3_column_bytes(statement, 0)))
    guard blob.prefix(4) == Data("VCK1".utf8), blob.count >= 9 else {
        throw NSError(domain: "numeric-vck", code: 1)
    }
    var offset = 5
    func count() -> Int {
        let result = (0..<4).reduce(0) { $0 | Int(blob[offset + $1]) << (8 * $1) }
        offset += 4
        return result
    }
    if blob[4] & 1 != 0 { let blocks = count(); offset += blocks * 2; let biomes = count(); offset += biomes }
    let length = count()
    return blob.subdata(in: offset..<offset + length)
}

private struct NumericTail: Decodable {
    struct Record: Decodable {
        struct Bag: Decodable { let swelling: Double?; let open: Double?; let swimTarget: [Double]? }
        let vx: Double
        let data: Bag
    }
    let entities: [Record]
    let blockEntities: [BlockEntityData]?
}

private func numericRegister() {
    registerAllBlocks(); registerAllItems(); registerAllBiomes(); registerAllRecipes()
    registerAllLootTables(); registerAllEntities(); registerAllSystems()
}

private func numericRoundtrip(_ values: [Double], label: String, allFields: Bool) throws -> Int {
    let db = SaveDB(), world = World(dim: .overworld, seed: 5)
    let id = "ps01-numeric-\(label)"
    let saved = values.map { value -> [String: Any] in
        let entity = Entity(world: world)
        entity.vx = value; entity.data.swelling = value
        if allFields { entity.data.open = value; entity.data.swimTarget = [value, -value] }
        return entity.save()
    }
    let be = makeFurnaceBE(0, 70, 0, "furnace")
    be.xpBank = values.first; be.progress = values.last
    guard db.putChunks([ChunkRecord(key: "0|0|0", worldId: id, dim: 0, cx: 0, cz: 0,
                                   blockEntities: [be], entities: saved)]),
          let loaded = db.getChunk(id, 0, 0, 0) else {
        throw NSError(domain: "numeric-production-roundtrip", code: 1)
    }
    let bytes = try numericChunkTail(id)
    let direct = try JSONDecoder().decode(NumericTail.self, from: bytes)
    var mismatches = 0
    for (index, value) in values.enumerated() {
        let owner = Entity(world: world); owner.load(loaded.entities[index])
        let correct = owner.vx.bitPattern == value.bitPattern
            && owner.data.swelling?.bitPattern == value.bitPattern
            && direct.entities[index].vx.bitPattern == value.bitPattern
            && direct.entities[index].data.swelling?.bitPattern == value.bitPattern
            && (!allFields || (owner.data.open?.bitPattern == value.bitPattern
                && owner.data.swimTarget?.map(\.bitPattern) == [value.bitPattern, (-value).bitPattern]
                && direct.entities[index].data.open?.bitPattern == value.bitPattern
                && direct.entities[index].data.swimTarget?.map(\.bitPattern) == [value.bitPattern, (-value).bitPattern]))
        if !correct {
            mismatches += 1
            if mismatches <= 8 { print("NUMERIC mismatch \(label)[\(index)] input=\(numericBits(value)) owner=\(numericBits(owner.vx)) nested=\(owner.data.swelling.map(numericBits) ?? "nil")") }
        }
    }
    if loaded.blockEntities?.first?.xpBank?.bitPattern != values.first?.bitPattern
        || loaded.blockEntities?.first?.progress?.bitPattern != values.last?.bitPattern
        || direct.blockEntities?.first?.xpBank?.bitPattern != values.first?.bitPattern
        || direct.blockEntities?.first?.progress?.bitPattern != values.last?.bitPattern { mismatches += 1 }
    db.deleteWorld(id)
    return mismatches
}

func runPebbleCoreJSONNumericCorpus() {
    section("Core end-to-end finite Binary64 corpus")
    numericRegister()
    var state: UInt64 = 0x5053303142494e36
    var finite = 0, excluded = 0, mismatches = 0, batch: [Double] = [], batchIndex = 0
    func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var value = state
        value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
        value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
        return value ^ (value >> 31)
    }
    do {
        for _ in 0..<100_000 {
            let value = Double(bitPattern: next())
            if !value.isFinite { excluded += 1; continue }
            finite += 1; batch.append(value)
            if batch.count == 256 {
                mismatches += try numericRoundtrip(batch, label: "corpus-\(batchIndex)", allFields: false)
                batch.removeAll(keepingCapacity: true); batchIndex += 1
            }
        }
        if !batch.isEmpty { mismatches += try numericRoundtrip(batch, label: "corpus-\(batchIndex)", allFields: false) }
        print("NUMERIC_CORPUS raw=100000 seed=5053303142494e36 finite=\(finite) excluded=\(excluded) exactMismatches=\(mismatches)")
        check("numeric corpus: deterministic finite/excluded counts", finite == 99_952 && excluded == 48)
        check("numeric corpus: production write / SQLite VCK1 / independent decoder / production read exact", mismatches == 0)
    } catch { check("numeric corpus: production durability", false, "\(error)") }
}

func runPebbleCoreJSONNumericFidelitySmoke() {
    section("Core JSON numeric fidelity")
    numericRegister()
    let edges: [Double] = [numericSwelling, numericSwelling.nextDown, numericSwelling.nextUp,
        numericVelocity, numericVelocity.nextDown, numericVelocity.nextUp,
        Double(bitPattern: 0xbfb6dd9adda2435d), Double(bitPattern: 0xbf81c198cd9559d2),
        0.1, -0.1, 1.0 / 3, .pi, 0.0, -0.0, .leastNonzeroMagnitude,
        -.leastNonzeroMagnitude, Double(bitPattern: 2), Double(bitPattern: 0x0008000000000000),
        Double(bitPattern: 0x000fffffffffffff), .leastNormalMagnitude,
        -.leastNormalMagnitude, .greatestFiniteMagnitude, -.greatestFiniteMagnitude, 1e100, -1e-100]
    do {
        check("numeric edges: exact native and all typed fields through SQLite VCK1", try numericRoundtrip(edges, label: "edges", allFields: true) == 0)
    } catch { check("numeric edges: production durability", false, "\(error)") }

    let world = World(dim: .overworld, seed: 5), db = SaveDB()
    for (index, value) in edges.enumerated() {
        do {
            check("numeric BlockEntity xpBank/progress edge \(numericBits(value))", try numericRoundtrip([value], label: "be-edge-\(index)", allFields: false) == 0)
        } catch { check("numeric BlockEntity edge durability", false, "\(error)") }
        var record = WorldRecord(id: "ps01-numeric-typed-world", name: "PebbleLab-Disposable-Numeric", seed: 5, gameMode: 1, difficulty: 2)
        record.lastPlayed = value; record.gameRules = ["numeric": value]
        check("numeric typed World finite write \(numericBits(value))", db.putWorld(record))
        let loaded = db.getWorld(record.id)
        check("numeric typed World exact \(numericBits(value))", loaded?.lastPlayed.bitPattern == value.bitPattern && loaded?.gameRules["numeric"]?.bitPattern == value.bitPattern)
    }
    for token in ["0.087093440672134648", "0.0008499751950044815"] {
        let raw = try! JSONSerialization.jsonObject(with: Data("{\"health\":\(token),\"speed\":\(token),\"jumpStrength\":\(token)}".utf8)) as! [String: Any]
        let expected = try! JSONDecoder().decode(Double.self, from: Data(token.utf8)).bitPattern
        let horse = Horse(world: world); horse.load(raw)
        check("numeric Horse/Mob decimal bridge exact \(token)", [horse.health, horse.speed, horse.jumpStrength].allSatisfy { $0.bitPattern == expected })
        check("numeric Horse/Mob durable write", db.putChunks([ChunkRecord(key: "0|0|0", worldId: "ps01-numeric-horse", dim: 0, cx: 0, cz: 0, entities: [horse.save()])]))
        let loaded = Horse(world: world); loaded.load(db.getChunk("ps01-numeric-horse", 0, 0, 0)!.entities[0])
        check("numeric Horse/Mob durable exact", [loaded.health, loaded.speed, loaded.jumpStrength].allSatisfy { $0.bitPattern == expected })
    }
    // Historical literals are immutable canonical durable tokens, not guessed
    // pre-save values. The last token already lost its pre-save c8 bits.
    for (token, expected) in [("0.087093440672134648", UInt64(0x3fb64bc177620800)),
                              ("-0.089318923101257622", 0xbfb6dd9adda2435d),
                              ("-0.0086700380076480156", 0xbf81c198cd9559d2),
                              ("0.00084997519500448131", 0x3f4bda1bd51d42c6)] {
        let bytes = Data("{\"vx\":\(token),\"data\":{\"swelling\":\(token)}}".utf8)
        let raw = try! JSONSerialization.jsonObject(with: bytes) as! [String: Any]
        let owner = Entity(world: world); owner.load(raw)
        check("numeric historical token \(token): faithfully represented bits", owner.vx.bitPattern == expected && owner.data.swelling?.bitPattern == expected)
    }
    for bad: Any in [true, false, NSNumber(value: true), NSNull(), "0.1", [0.1], ["n": 0.1]] {
        let entity = Entity(world: world); entity.load(["vx": bad])
        let player = Player(world: world); player.load(["health": bad, "saturation": bad, "xpProgress": bad, "stats": ["n": bad]])
        let horse = Horse(world: world); horse.load(["health": bad, "speed": bad, "jumpStrength": bad])
        check("numeric nonnumber \(type(of: bad)): owner fallbacks", entity.vx == 0 && player.health == 20 && player.saturation == 5 && player.xpProgress == 0 && player.stats.isEmpty && horse.health == horse.maxHealth && horse.speed == 0.2 && horse.jumpStrength == 0.7)
    }
    for value in edges {
        let player = Player(world: world)
        player.health = value; player.saturation = value; player.xpProgress = value; player.stats = ["test": value]
        let id = "ps01-numeric-player"
        check("numeric Player write \(numericBits(value))", db.putPlayer(id, player.save()))
        let restored = Player(world: world); restored.load(db.getPlayer(id)!)
        check("numeric Player exact \(numericBits(value))", [restored.health, restored.saturation, restored.xpProgress, restored.stats["test"]!].allSatisfy { $0.bitPattern == value.bitPattern })
    }
    for integer in [Int(Int32.min), -30_000_000, -1, 0, 1, 65535, 30_000_000, Int(Int32.max)] {
        let entity = Entity(world: world); entity.age = integer; entity.fireTicks = integer; entity.data.variant = integer
        let stack = ItemStack(iid("diamond_pickaxe"), 1, damage: 137, ench: [EnchInstance("unbreaking", 3)])
        stack.data.priorWork = integer; stack.data.lodestone = [integer, 70, -integer, 0]
        let player = Player(world: world); player.inventory[0] = stack; player.xpLevel = integer
        check("numeric integer write \(integer)", db.putPlayer("ps01-numeric-integers", player.save()))
        let restored = Player(world: world); restored.load(db.getPlayer("ps01-numeric-integers")!)
        check("numeric integer owner/nested inventory \(integer)", restored.xpLevel == integer && restored.inventory[0] == stack)
        check("numeric integer entity chunk write", db.putChunks([ChunkRecord(key: "0|0|0", worldId: "ps01-numeric-integers", dim: 0, cx: 0, cz: 0, entities: [entity.save()])]))
        let loaded = Entity(world: world); loaded.load(db.getChunk("ps01-numeric-integers", 0, 0, 0)!.entities[0])
        check("numeric integer entity counters/typed variant \(integer)", loaded.age == integer && loaded.fireTicks == integer && loaded.data.variant == integer)
    }
    for invalid in [Double.nan, .infinity, -.infinity] {
        check("numeric nonfinite recursive write", db.putPlayer("ps01-numeric-invalid", ["vx": invalid, "nested": ["array": [invalid, 0.1]], "boolean": true]))
        let raw = db.getPlayer("ps01-numeric-invalid")!
        let nested = (raw["nested"] as! [String: Any])["array"] as! [NSNumber]
        check("numeric nonfinite scrub and finite sibling/Boolean retained", (raw["vx"] as! NSNumber).doubleValue == 0 && nested[0].doubleValue == 0 && nested[1].doubleValue.bitPattern == Double(0.1).bitPattern && raw["boolean"] as? Bool == true)
        let entity = Entity(world: world); entity.vx = numericVelocity; entity.data.swelling = invalid
        check("numeric nonfinite typed bag retains existing omission policy", entity.save()["data"] == nil)
        let be = makeFurnaceBE(0, 70, 0, "furnace"); be.xpBank = invalid
        check("numeric nonfinite typed BE safe save", db.putChunks([ChunkRecord(key: "0|0|0", worldId: "ps01-numeric-invalid", dim: 0, cx: 0, cz: 0, blockEntities: [be], entities: [entity.save()])]))
        let loaded = db.getChunk("ps01-numeric-invalid", 0, 0, 0)!
        check("numeric nonfinite typed BE omission does not poison finite entity", loaded.blockEntities == nil && (loaded.entities[0]["vx"] as! NSNumber).doubleValue.bitPattern == numericVelocity.bitPattern)
        var record = WorldRecord(id: "ps01-numeric-invalid-world", name: "PebbleLab-Disposable-Numeric", seed: 5, gameMode: 1, difficulty: 2)
        record.gameRules = ["invalid": invalid]
        check("numeric nonfinite typed World retains rejected-write policy", !db.putWorld(record) && db.getWorld(record.id) == nil)
    }
    let legacy = Entity(world: world)
    legacy.load(["data": ["swelling": NSNumber(value: 0.1), "charged": NSNumber(value: 0)]])
    check("numeric legacy Boolean compatibility conserves exact numeric sibling", legacy.data.swelling?.bitPattern == Double(0.1).bitPattern && legacy.data.charged == false)
    let current = Entity(world: world); current.data.swelling = numericSwelling; current.data.charged = false
    check("numeric type-safe common writer: current typed Boolean and Double save", db.putChunks([ChunkRecord(key: "0|0|0", worldId: "ps01-numeric-current", dim: 0, cx: 0, cz: 0, entities: [current.save()])]))
    let currentRestored = Entity(world: world); currentRestored.load(db.getChunk("ps01-numeric-current", 0, 0, 0)!.entities[0])
    check("numeric current shared primitive boundary", currentRestored.data.swelling?.bitPattern == numericSwelling.bitPattern && currentRestored.data.charged == false)
    for id in ["ps01-numeric-player", "ps01-numeric-integers", "ps01-numeric-invalid", "ps01-numeric-current", "ps01-numeric-typed-world", "ps01-numeric-horse"] { db.deleteWorld(id) }
}
