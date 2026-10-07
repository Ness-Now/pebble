import Foundation
import CoreFoundation
import SQLite3
@_spi(Testing) import PebbleCore

private let legacyBoolKeys = ["puffed", "grazing", "baby", "brown", "sheared", "charged", "captain", "cold", "hanging", "aiming", "airborne", "crossed", "leatherBoots", "persistent"]
private let legacyVelocity = Double(bitPattern: 0x3fb64bc177620800)
private let legacySwelling = Double(bitPattern: 0x3f4bda1bd51d42c8)
private func booleanObject<T: Encodable>(_ value: T) -> Any {
    try! JSONSerialization.jsonObject(with: JSONEncoder().encode(value))
}
private func booleanJSON(_ value: Any) -> Data {
    try! JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .fragmentsAllowed])
}
private func isJSONBool(_ value: Any?) -> Bool {
    guard let n = value as? NSNumber else { return false }
    return CFGetTypeID(n) == CFBooleanGetTypeID()
}
private func booleanBag(_ b: Bool) -> EntityData {
    var d = EntityData()
    d.puffed = b; d.grazing = !b; d.baby = b; d.brown = !b; d.sheared = b
    d.charged = !b; d.captain = b; d.cold = !b; d.hanging = b; d.aiming = !b
    d.airborne = b; d.crossed = !b; d.leatherBoots = b; d.persistent = !b
    d.variant = 0; d.color = 1; d.size = 3; d.pattern = 7
    d.stingTimer = 0; d.buckTimer = 1; d.loveCause = 17
    d.swelling = 0.125; d.open = 1; d.swimTarget = [0, 1, -0.25, .leastNonzeroMagnitude]
    d.gene = "sentinel-preserve"; d.deathCause = "sentinel-cause"; d.deathAttacker = "sentinel-attacker"
    return d
}
private func booleanStack(_ b: Bool, depth: Int = 2) -> ItemStack {
    var d = StackData()
    d.charged = b; d.priorWork = 0; d.repairUnits = 1; d.flight = 3
    d.lodestone = [0, 1, -17, 0]; d.potion = "water"
    d.trim = TrimData(pattern: "sentry", material: "gold"); d.sherds = ["brick", "archer"]
    if depth > 0 { d.contents = [booleanStack(!b, depth: depth - 1), nil] }
    return ItemStack(iid("crossbow"), 1, damage: 7, ench: [EnchInstance("unbreaking", 2)], label: "stack-sentinel", data: d)
}
private func booleanPlayer(_ w: World) -> Player {
    let p = Player(world: w); p.data = booleanBag(false)
    p.inventory[0] = booleanStack(false); p.inventory[1] = booleanStack(true)
    p.enderChest[0] = booleanStack(true); p.armor[0] = booleanStack(false); p.offHand = booleanStack(true)
    p.effects = [ActiveEffect(id: "speed", duration: 1200, amplifier: 0, ambient: false, showParticles: true), ActiveEffect(id: "resistance", duration: 2400, amplifier: 1, ambient: true, showParticles: false)]
    p.stats = ["zero": 0, "one": 1, "negative": -17]; p.hunger = 17; p.xpLevel = 7
    return p
}
private func booleanEntities(_ w: World) -> [Entity] {
    let a = Chicken(world: w), b = Chicken(world: w)
    a.data = booleanBag(false); b.data = booleanBag(true)
    let item = ItemEntity(world: w); item.stack = booleanStack(true); item.pickupDelay = 37
    let boat = Boat(world: w); boat.hasChest = true; boat.chestItems[0] = booleanStack(false); boat.chestItems[1] = booleanStack(true)
    let cart = Minecart(world: w); cart.variant = "chest"; cart.chestItems[0] = booleanStack(true); cart.chestItems[1] = booleanStack(false)
    let villager = Villager(world: w)
    villager.offers = try! JSONDecoder().decode([TradeOffer].self, from: booleanJSON([["buyA": booleanObject(booleanStack(false)), "buyB": booleanObject(booleanStack(true)), "sell": booleanObject(booleanStack(false)), "maxUses": 12, "uses": 1, "xp": 7]]))
    let entities: [Entity] = [a, b, item, boat, cart, villager]
    for (i, e) in entities.enumerated() { e.setPos(8 + Double(i), 80, -110); e.age = 17 + i; e.persistent = true }
    return entities
}

private func booleanOwnerMatrix() {
    section("Schema-owned legacy Boolean and malformed matrix")
    let w = World(dim: .overworld, seed: 5)
    let values: [(String, Any, Bool?, Bool)] = [
        ("false", false, false, true), ("true", true, true, true),
        ("0", 0, false, true), ("1", 1, true, true),
        ("0.0", 0.0, false, true), ("1.0", 1.0, true, true),
        ("null", NSNull(), nil, true), ("2", 2, nil, false), ("-1", -1, nil, false),
        ("0.5", 0.5, nil, false), ("string true", "true", nil, false),
        ("string false", "false", nil, false), ("array", [], nil, false),
        ("object", [String: Int](), nil, false), ("near one", 1.0.nextUp, nil, false),
        ("near zero", Double.leastNonzeroMagnitude, nil, false)
    ]
    for key in legacyBoolKeys {
        for (name, rawValue, expected, accepted) in values {
            var raw = booleanObject(booleanBag(false)) as! [String: Any]; raw[key] = rawValue
            let e = Entity(world: w); e.load(["data": raw])
            if accepted {
                var wanted = raw; wanted[key] = expected.map { $0 as Any } ?? NSNull()
                let bag = try! JSONDecoder().decode(EntityData.self, from: booleanJSON(wanted))
                check("EntityData \(key) \(name): complete bag conserved", e.data == bag)
            } else {
                check("EntityData \(key) \(name): prior whole-bag fallback", e.data == EntityData())
            }
        }
        var missing = booleanObject(booleanBag(false)) as! [String: Any]; missing.removeValue(forKey: key)
        let e = Entity(world: w); e.load(["data": missing])
        check("EntityData \(key) missing: optional semantics and siblings", e.data == (try! JSONDecoder().decode(EntityData.self, from: booleanJSON(missing))))
    }
    for (name, rawValue, expected, accepted) in values {
        var raw = booleanObject(booleanStack(false)) as! [String: Any]
        var bag = raw["data"] as! [String: Any]; bag["charged"] = rawValue; raw["data"] = bag
        let item = ItemEntity(world: w); item.load(["stack": raw])
        let wanted = booleanStack(false); wanted.data.charged = expected
        check("ItemEntity StackData charged \(name)", item.stack == (accepted ? wanted : ItemStack(0, 1)))
        for key in ["ambient", "showParticles"] {
            let effect = ActiveEffect(id: "speed", duration: 1200, amplifier: 1, ambient: false, showParticles: true)
            var fx = booleanObject(effect) as! [String: Any]; fx[key] = rawValue
            let p = Player(world: w); p.load(["effects": [fx]])
            var wanted = effect
            if key == "ambient" { wanted.ambient = expected } else { wanted.showParticles = expected }
            check("Player ActiveEffect \(key) \(name)", p.effects == (accepted ? [wanted] : []))
        }
        for key in ["inventory", "enderChest", "armor", "offHand"] {
            let p = Player(world: w); p.load([key: key == "offHand" ? raw : [raw]])
            let got = key == "inventory" ? p.inventory[0] : key == "enderChest" ? p.enderChest[0] : key == "armor" ? p.armor[0] : p.offHand
            check("Player \(key) charged \(name): container conservation/fallback", got == (accepted ? wanted : nil))
        }
        for vehicle in [Boat(world: w) as Entity, Minecart(world: w) as Entity] {
            vehicle.load(["chestItems": [raw]])
            let stacks = (vehicle as? Boat)?.chestItems ?? (vehicle as! Minecart).chestItems
            check("\(vehicle.type) charged \(name)", stacks.first ?? nil == (accepted ? wanted : nil))
        }
        let villager = Villager(world: w)
        let trade: [String: Any] = ["buyA": raw, "sell": raw, "maxUses": 12, "uses": 1, "xp": 7]
        villager.load(["offers": [trade]])
        check("Villager charged \(name)", accepted ? villager.offers.first?.buyA == wanted && villager.offers.first?.sell == wanted : villager.offers.isEmpty)
    }
    let p = Player(world: w); p.load(["effects": [["id": "speed", "duration": 1, "amplifier": 0]]])
    check("ActiveEffect missing optional flags", p.effects.first?.ambient == nil && p.effects.first?.showParticles == nil && p.effects.count == 1)
    let item = ItemEntity(world: w); var stack = booleanObject(booleanStack(false)) as! [String: Any]
    var bag = stack["data"] as! [String: Any]; bag.removeValue(forKey: "charged"); stack["data"] = bag; item.load(["stack": stack])
    let wanted = booleanStack(false); wanted.data.charged = nil
    check("StackData missing optional charged", item.stack == wanted)
    check("ordinary EntityData codec remains strict", (try? JSONDecoder().decode(EntityData.self, from: Data("{\"airborne\":0}".utf8))) == nil)
    check("ordinary StackData codec remains strict", (try? JSONDecoder().decode(StackData.self, from: Data("{\"charged\":1}".utf8))) == nil)
    check("ordinary ActiveEffect codec remains strict", (try? JSONDecoder().decode(ActiveEffect.self, from: Data("{\"id\":\"speed\",\"duration\":1,\"amplifier\":0,\"ambient\":1}".utf8))) == nil)
    let be = makeContainerBE(0, 80, 0, 1); be.items = [booleanStack(true)]
    var rawBE = booleanObject(be) as! [String: Any]
    rawBE["active"] = 1
    check("unexposed BlockEntityData flag remains strict", (try? JSONDecoder().decode(BlockEntityData.self, from: booleanJSON(rawBE))) == nil)
    rawBE.removeValue(forKey: "active")
    var nested = booleanObject(booleanStack(true)) as! [String: Any]
    var nestedBag = nested["data"] as! [String: Any]; nestedBag["charged"] = 1; nested["data"] = nestedBag
    rawBE["items"] = [nested]
    check("unexposed block-container item remains strict", (try? JSONDecoder().decode(BlockEntityData.self, from: booleanJSON(rawBE))) == nil)
    let db = SaveDB()
    check("unexposed block-container current write", db.putChunks([ChunkRecord(key: db.chunkKey("boolean-block", 0, 0, 0), worldId: "boolean-block", dim: 0, cx: 0, cz: 0, blockEntities: [be])]))
    check("unexposed block-container current Bool reads", db.getChunk("boolean-block", 0, 0, 0)?.blockEntities?.first?.items?[0] == booleanStack(true))
    db.deleteWorld("boolean-block")
    let e = Entity(world: w); e.load(["vx": true, "data": ["airborne": 0, "swelling": true, "gene": "sentinel-preserve"]])
    check("mixed corruption does not salvage unrelated invalid Double", e.vx.bitPattern == Double(0).bitPattern && e.data == EntityData())
}

func runPebbleCoreBooleanStorageMode(_ mode: String) {
    let game = GameCore(), w = World(dim: .overworld, seed: 5), id = "ps01-typed-json-legacy"
    print("BOOLEAN_PROCESS mode=\(mode) pid=\(ProcessInfo.processInfo.processIdentifier)")
    if mode == "install" {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/CoreTypedJSON")
        let vck = try! Data(contentsOf: root.appendingPathComponent("canonical-bf804aa.vck"))
        let player = try! String(contentsOf: root.appendingPathComponent("canonical-bf804aa-player.json"), encoding: .utf8)
        var db: OpaquePointer?, stmt: OpaquePointer?
        precondition(sqlite3_open(vcSupportDir().appendingPathComponent("pebble.db").path, &db) == SQLITE_OK)
        defer { sqlite3_close(db) }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_prepare_v2(db, "INSERT OR REPLACE INTO chunks(world,dim,cx,cz,data) VALUES('ps01-typed-json-legacy',0,0,-7,?)", -1, &stmt, nil)
        _ = vck.withUnsafeBytes { sqlite3_bind_blob(stmt, 1, $0.baseAddress, Int32(vck.count), transient) }
        check("immutable historical VCK1 installed", sqlite3_step(stmt) == SQLITE_DONE); sqlite3_finalize(stmt)
        sqlite3_prepare_v2(db, "INSERT OR REPLACE INTO player(world,json) VALUES('ps01-typed-json-legacy',?)", -1, &stmt, nil)
        sqlite3_bind_text(stmt, 1, player, -1, transient)
        check("immutable historical Player installed", sqlite3_step(stmt) == SQLITE_DONE); sqlite3_finalize(stmt)
        return
    }
    let entities = booleanEntities(w), player = booleanPlayer(w)
    let mixed = mode.hasPrefix("mixed")
    if mixed {
        for e in entities { e.vx = legacyVelocity; e.data.swelling = legacySwelling; e.data.open = -0.0 }
        player.saturation = legacySwelling; player.xpProgress = legacyVelocity; player.stats["hard"] = legacyVelocity
    }
    if mode == "write" || mode == "mixed-write" {
        var raw = entities.map { $0.save() }, rawPlayer = player.save()
        if mixed {
            // Synthetic historical representation combined with exact modern
            // Double tokens. Immutable old fixtures are tested independently.
            for i in raw.indices { var d = raw[i]["data"] as! [String: Any]; d["airborne"] = i % 2; raw[i]["data"] = d }
            var d = rawPlayer["data"] as! [String: Any]; d["airborne"] = 0; rawPlayer["data"] = d
        }
        check("Boolean real putChunks", game.db.putChunks([ChunkRecord(key: game.db.chunkKey(id, 0, 0, -7), worldId: id, dim: 0, cx: 0, cz: -7, entities: raw)]))
        check("Boolean real putPlayer", game.db.putPlayer(id, rawPlayer))
        return
    }
    guard let rec = game.db.getChunk(id, 0, 0, -7), let rp = game.db.getPlayer(id) else { check("Boolean durable records present", false); return }
    check("Boolean multi-owner chunk count", rec.entities.count == entities.count)
    for (i, raw) in rec.entities.enumerated() {
        guard i < entities.count, let loaded = loadEntity(w, raw) else { check("Boolean entity reconstruction \(i)", false); continue }
        if mixed { entities[i].data.airborne = i % 2 == 1 }
        check("Boolean entity \(i) complete typed/sibling conservation", booleanJSON(loaded.save()) == booleanJSON(entities[i].save()))
        if mixed {
            check("Boolean entity \(i) exact velocity/swelling/signed zero", loaded.vx.bitPattern == legacyVelocity.bitPattern && loaded.data.swelling?.bitPattern == legacySwelling.bitPattern && loaded.data.open?.bitPattern == Double(-0.0).bitPattern)
        }
        if mode == "read", let bag = raw["data"] as? [String: Any], !bag.isEmpty {
            check("Boolean durable EntityData flags \(i)", legacyBoolKeys.allSatisfy { isJSONBool(bag[$0]) })
            check("Boolean genuine numeric 0/1 remain numbers \(i)", !isJSONBool(bag["variant"]) && !isJSONBool(bag["color"]))
        }
    }
    let restored = Player(world: w); restored.load(rp)
    check("Boolean Player complete typed/sibling conservation", booleanJSON(restored.save()) == booleanJSON(player.save()))
    check("Boolean Player all inventory containers", restored.inventory == player.inventory && restored.armor == player.armor && restored.enderChest == player.enderChest && restored.offHand == player.offHand)
    check("Boolean Player effects and bag", restored.effects == player.effects && restored.data == player.data)
    check("Boolean Player numeric siblings", restored.stats == player.stats && restored.hunger == 17 && restored.xpLevel == 7)
    if mixed { check("Boolean Player exact Double owners", restored.saturation.bitPattern == legacySwelling.bitPattern && restored.xpProgress.bitPattern == legacyVelocity.bitPattern && restored.stats["hard"]?.bitPattern == legacyVelocity.bitPattern) }
}

func runPebbleCoreLegacyBooleanSmoke() {
    _ = GameCore()
    booleanOwnerMatrix()
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("pebble-boolean-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: root) }
    for (mode, dir) in [("write", "current"), ("read", "current"), ("install", "legacy"), ("legacy-read", "legacy"), ("mixed-write", "mixed"), ("mixed-read", "mixed")] {
        let process = Process(); process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        process.environment = ProcessInfo.processInfo.environment.merging(["PEBBLELAB_SMOKE_ONLY": "core-boolean-" + mode, "CFFIXED_USER_HOME": root.appendingPathComponent(dir).path]) { _, new in new }
        do { try process.run(); process.waitUntilExit(); check("Boolean separate OS process \(mode)", process.terminationReason == .exit && process.terminationStatus == 0) }
        catch { check("Boolean process launch \(mode)", false, "\(error)") }
    }
}
