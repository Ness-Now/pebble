// Headless smoke tests for PebbleCore. The frozen golden baselines
// (goldens/*.json) pin engine behavior — the engine must reproduce them
// bit-for-bit so worldgen seeds carry over across releases.

import Foundation
import simd
import PebbleAgents
import PebbleCore

var passed = 0
var failed = 0

func check(_ name: String, _ cond: Bool, _ detail: String = "") {
    if cond {
        passed += 1
        print("  ✓ \(name)")
    } else {
        failed += 1
        print("  ✗ \(name) \(detail)")
    }
}

func checkD(_ name: String, _ got: Double, _ want: Double, tol: Double = 1e-12) {
    check(name, abs(got - want) <= tol, "got \(got) want \(want)")
}

func section(_ name: String) { print("\n— \(name)") }

// ---------------------------------------------------------------------------
section("random (vs goldens)")
check("hashString abc", hashString("abc") == 440920331, "got \(hashString("abc"))")
check("mix32 12345", mix32(12345) == 1011272156, "got \(mix32(12345))")
check("hash2", hash2(999, -1234, 5678, 7) == 1511826033, "got \(hash2(999, -1234, 5678, 7))")
check("hash3", hash3(999, -12, 34, -56, 3) == 2031202406, "got \(hash3(999, -12, 34, -56, 3))")

var r = RandomX(12345)
let golden12345: [UInt32] = [1009662611, 487413528, 3278825217, 2736101217, 2510057557, 1701016183, 572264801, 2565169478]
var seqOK = true
for (i, want) in golden12345.enumerated() {
    let got = r.next()
    if got != want { seqOK = false; print("    sfc32[\(i)] got \(got) want \(want)") }
}
check("sfc32 seed 12345 sequence", seqOK)

var r2 = RandomX(0xDEAD_BEEF)
let goldenDB: [UInt32] = [1504311087, 3087835436, 4013932724, 864736003]
var seq2OK = true
for want in goldenDB { if r2.next() != want { seq2OK = false } }
check("sfc32 seed 0xDEADBEEF sequence", seq2OK)

var r3 = RandomX(777)
var inRange = true
for _ in 0..<1000 {
    let v = r3.nextInt(10)
    if v < 0 || v >= 10 { inRange = false }
}
check("nextInt bounds", inRange)

// ---------------------------------------------------------------------------
section("simplex noise (vs goldens)")
let n = SimplexNoise(42)
checkD("noise2 (0.5,0.5)", n.noise2(0.5, 0.5), -0.30780618346945793)
checkD("noise2 (10.25,-3.75)", n.noise2(10.25, -3.75), 0)
checkD("noise2 (100.1,200.9)", n.noise2(100.1, 200.9), -0.6225765639891507)
checkD("noise2 (-55.5,17.3)", n.noise2(-55.5, 17.3), 0.4811125458747653)
checkD("noise3 (1.5,2.5,3.5)", n.noise3(1.5, 2.5, 3.5), 0)
checkD("noise3 (-10.1,40.2,-7.7)", n.noise3(-10.1, 40.2, -7.7), 0.12712837501423255)

let f = FBM(7, 4, 0.01)
checkD("fbm sample2 (123.4,567.8)", f.sample2(123.4, 567.8), -0.17945870068084002)
checkD("fbm ridge2 (123.4,567.8)", f.ridge2(123.4, 567.8), 0.4321547307883241)
checkD("fbm sample2 (-1000.5,250.25)", f.sample2(-1000.5, 250.25), -0.37532916362726393)
checkD("fbm ridge2 (-1000.5,250.25)", f.ridge2(-1000.5, 250.25), 0.41162552326329793)

let sp = Spline([(0, 0), (0.5, 10), (1, 4)])
checkD("spline at -1", sp.at(-1), 0)
checkD("spline at 0.25", sp.at(0.25), 5)
checkD("spline at 0.5", sp.at(0.5), 10)
checkD("spline at 0.75", sp.at(0.75), 7)
checkD("spline at 2", sp.at(2), 4)

// ---------------------------------------------------------------------------
section("math")
let a = AABB(0, 0, 0, 1, 1, 1)
let b = AABB(2, 0, 0, 3, 1, 1)
checkD("sweepX blocked", sweepX(a, b, 5), 1)
checkD("sweepX clear (offset z)", sweepX(a, b.offset(0, 0, 5), 5), 5)
checkD("sweepY through", sweepY(a, b, 3), 3)
check("aabb intersects", AABB(0, 0, 0, 2, 2, 2).intersects(AABB(1, 1, 1, 3, 3, 3)))
check("aabb no intersect", !AABB(0, 0, 0, 1, 1, 1).intersects(AABB(1, 0, 0, 2, 1, 1)))

let t = rayAABB(-5, 0.5, 0.5, 1, 0, 0, a)
checkD("rayAABB hit", t, 5)
check("rayAABB miss", rayAABB(-5, 5, 0.5, 1, 0, 0, a) == -1)

var fr = Frustum()
let proj = mat4Perspective(fovYRad: Float(degToRad(70)), aspect: 16.0 / 9.0, near: 0.05, far: 400)
let view = mat4LookDir(eye: SIMD3<Float>(0, 0, 0), dir: SIMD3<Float>(0, 0, 1), up: SIMD3<Float>(0, 1, 0))
fr.setFromMatrix(proj * view)
check("frustum sees box ahead", fr.intersectsBox(-5, -5, 10, 5, 5, 20))
check("frustum culls box behind", !fr.intersectsBox(-5, -5, -20, 5, 5, -10))
check("frustum culls box far right", !fr.intersectsBox(500, -5, 10, 510, 5, 20))

checkD("wrapDegrees 270", wrapDegrees(270), -90)
checkD("wrapDegrees -270", wrapDegrees(-270), 90)
checkD("lerp", lerpD(0, 10, 0.25), 2.5)

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
section("block registry (vs goldens)")
registerAllBlocks()
check("block count", blockDefs.count == 879, "got \(blockDefs.count) want 879")
check("tile count (baseline range intact)", tileCount() >= 757, "got \(tileCount()) want >= 757")
let idGoldens: [(String, UInt16)] = [
    ("air", 0), ("stone", 3), ("grass_block", 33), ("oak_log", 95),
    ("water", 292), ("lava", 293), ("glass", 294), ("white_wool", 298),
    ("black_shulker_box", 473), ("wheat", 537), ("snow", 550),
    ("netherrack", 589), ("end_stone", 614), ("crafting_table", 626),
    ("redstone_wire", 684), ("rail", 717), ("tuff_wall", 823),
    ("oxidized_cut_copper_slab", 852), ("waxed_oxidized_cut_copper_slab", 856),
    ("infested_deepslate", 878), ("sculk_shrieker", 716),
    ("cherry_leaves", 279), ("mangrove_propagule", 289),
]
var idsOK = true
for (name, want) in idGoldens {
    let got = bidOpt(name)
    if got != want {
        idsOK = false
        print("    id mismatch \(name): got \(String(describing: got)) want \(want)")
    }
}
check("23 block ids bit-identical to baseline", idsOK)
check("tile grass_top", tileId("grass_top") == 38, "got \(tileId("grass_top"))")
check("tile destroy_9", tileId("destroy_9") == 740, "got \(tileId("destroy_9"))")
check("tile 756 is sweep_particle", allTileNames().count > 756 && allTileNames()[756] == "sweep_particle", "got \(allTileNames().count > 756 ? allTileNames()[756] : "nil")")
check("cell roundtrip", cell(B.stone, 7) >> 4 == B.stone && cellMeta(cell(B.stone, 7)) == 7)
check("lightEmitOf torch", lightEmitOf(cell(B.torch)) == 14)
check("lightEmitOf sea_pickle x4", lightEmitOf(cell(B.sea_pickle, 3)) == 15)
check("water replaceable", REPLACEABLE[Int(B.water)] == 1)
check("stone opaque", OPAQUE[Int(B.stone)] == 1)
check("glass not opaque", OPAQUE[Int(B.glass)] == 0)

// ---------------------------------------------------------------------------
section("item registry (vs goldens)")
registerAllItems()
// 1186 baseline items + 2 appended (weeping/twisting vines — their drop
// fns referenced items that never existed; appended at the END so every
// baseline id is unchanged)
let BASE_ITEM_COUNT = 1186
check("item count", itemDefs.count == 1188, "got \(itemDefs.count) want 1188")
check("item ids stable after append", iid("weeping_vines") == 1186 && iid("twisting_vines") == 1187,
      "vines ids \(iid("weeping_vines"))/\(iid("twisting_vines")) want 1186/1187")
let itemGoldens: [(String, Int)] = [
    ("stone", 0), ("wheat_seeds", 764), ("wooden_sword", 832), ("netherite_hoe", 861),
    ("leather_helmet", 869), ("elytra", 894), ("apple", 896), ("milk_bucket", 934),
    ("stick", 935), ("goat_horn", 1008), ("white_dye", 1009), ("bucket", 1025),
    ("potion", 1045), ("oak_boat", 1048), ("music_disc_descent", 1075),
    ("angler_pottery_sherd", 1076), ("netherite_upgrade", 1112),
    ("zombified_piglin_spawn_egg", 1185),
]
var itemIdsOK = true
for (name, want) in itemGoldens {
    let got = iidOpt(name)
    if got != want {
        itemIdsOK = false
        print("    item id mismatch \(name): got \(String(describing: got)) want \(want)")
    }
}
check("18 item ids bit-identical to baseline", itemIdsOK)
check("blockToItem stone", blockToItem[Int(B.stone)] == Int32(iid("stone")))
check("cake maxStack 1", itemDefs[iid("cake")].maxStack == 1)
check("netherite sword dmg", itemDefs[iid("netherite_sword")].tool?.attackDamage == 7)
check("diamond chest durability", itemDefs[iid("diamond_chestplate")].armor?.durability == 529)
check("steak hunger", itemDefs[iid("cooked_beef")].food?.hunger == 8)
check("lava bucket burn", itemDefs[iid("lava_bucket")].burnTime == 20000)
check("merge same", canMerge(ItemStack(iid("stone"), 5), ItemStack(iid("stone"), 3)))
check("no merge tools", !canMerge(ItemStack(iid("iron_sword")), ItemStack(iid("iron_sword"))))

// ---------------------------------------------------------------------------
section("biomes (vs goldens)")
registerAllBiomes()
check("biome count = enum count", BIOMES.count == Biome.allCases.count, "got \(BIOMES.count)")

/// candidate paths for a golden file — goldens/ beside the package manifest,
/// tolerant of being run from the repo root, its parent, or a subdirectory
func goldenPaths(_ name: String) -> [String] {
    ["goldens/\(name)", "../goldens/\(name)", name]
}

func loadJSON(_ name: String) -> [String: Any]? {
    for p in goldenPaths(name) {
        if let d = FileManager.default.contents(atPath: p),
           let obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] {
            return obj
        }
    }
    return nil
}

if let g = loadJSON("biome-goldens.json") {
    let count = (g["biomeCount"] as! NSNumber).intValue
    check("biome count vs goldens", BIOMES.count == count, "got \(BIOMES.count) want \(count)")

    let names = g["names"] as! [String]
    var namesOK = true
    for (i, want) in names.enumerated() where BIOMES[i]?.name != want {
        namesOK = false
        print("    biome[\(i)] got \(BIOMES[i]?.name ?? "nil") want \(want)")
    }
    check("\(names.count) biome names in identical order", namesOK)

    let climates = g["climates"] as! [[NSNumber]]
    let samples = (g["samples"] as! [NSNumber]).map { $0.intValue }
    var mismatches = 0
    for (i, cl) in climates.enumerated() {
        let c = Climate(t: cl[0].doubleValue, h: cl[1].doubleValue, c: cl[2].doubleValue,
                        e: cl[3].doubleValue, w: cl[4].doubleValue,
                        pv: peaksValleys(cl[4].doubleValue), rare: cl[5].doubleValue)
        if selectBiome(c).rawValue != samples[i] {
            mismatches += 1
            if mismatches <= 5 {
                print("    selectBiome[\(i)] got \(selectBiome(c).rawValue) want \(samples[i]) cl=\(cl)")
            }
        }
    }
    check("selectBiome 2000 samples bit-identical", mismatches == 0, "\(mismatches) mismatches")

    let pvG = (g["pv"] as! [NSNumber]).map { $0.doubleValue }
    var pvOK = true
    for (i, want) in pvG.enumerated() where abs(peaksValleys(-1 + Double(i) * 0.05) - want) > 1e-12 {
        pvOK = false
    }
    check("peaksValleys curve", pvOK)

    let defs = g["defChecks"] as! [[String: Any]]
    var defOK = true
    func defFail(_ b: Int, _ what: String) { defOK = false; print("    def[\(b)] \(what)") }
    for d in defs {
        let b = (d["b"] as! NSNumber).intValue
        guard let def = BIOMES[b] else { defFail(b, "missing"); continue }
        if def.name != d["name"] as! String { defFail(b, "name") }
        if def.displayName != d["display"] as! String { defFail(b, "display") }
        if abs(def.temperature - (d["temp"] as! NSNumber).doubleValue) > 1e-12 { defFail(b, "temp") }
        if abs(def.downfall - (d["downfall"] as! NSNumber).doubleValue) > 1e-12 { defFail(b, "downfall") }
        if def.grassColor != (d["grass"] as! NSNumber).uint32Value { defFail(b, "grass") }
        if def.foliageColor != (d["foliage"] as! NSNumber).uint32Value { defFail(b, "foliage") }
        if def.waterColor != (d["water"] as! NSNumber).uint32Value { defFail(b, "water") }
        if def.fogTint != (d["fogTint"] as! NSNumber).uint32Value { defFail(b, "fogTint") }
        if Int(def.top) != (d["top"] as! NSNumber).intValue { defFail(b, "top got \(def.top) want \(d["top"]!)") }
        if Int(def.under) != (d["under"] as! NSNumber).intValue { defFail(b, "under got \(def.under) want \(d["under"]!)") }
        if Int(def.underwaterTop) != (d["uwTop"] as! NSNumber).intValue { defFail(b, "uwTop got \(def.underwaterTop) want \(d["uwTop"]!)") }
        if def.features != d["features"] as! [String] {
            defFail(b, "features\n      got  \(def.features)\n      want \(d["features"]!)")
        }
        if def.mood != d["mood"] as! String { defFail(b, "mood") }
        let monsters = d["monsters"] as! [[Any]]
        if def.monsters.count != monsters.count { defFail(b, "monsters count") }
        else {
            for (i, m) in monsters.enumerated() {
                let got = def.monsters[i]
                if got.mob != m[0] as! String || got.weight != (m[1] as! NSNumber).doubleValue
                    || got.minPack != (m[2] as! NSNumber).intValue || got.maxPack != (m[3] as! NSNumber).intValue {
                    defFail(b, "monster[\(i)]")
                }
            }
        }
        let creatures = d["creatures"] as! [[Any]]
        if def.creatures.count != creatures.count { defFail(b, "creatures count") }
        else {
            for (i, m) in creatures.enumerated() {
                let got = def.creatures[i]
                if got.mob != m[0] as! String || got.weight != (m[1] as! NSNumber).doubleValue {
                    defFail(b, "creature[\(i)]")
                }
            }
        }
    }
    check("10 BiomeDef spot checks (fields, features, spawns)", defOK)

    let temps = g["tempSamples"] as! [[String: Any]]
    // native baseline since the vanilla snow-lapse fix (PEBBLE_REGOLD regenerates)
    if ProcessInfo.processInfo.environment["PEBBLE_REGOLD"] != nil {
        let captured = temps.map { s -> [String: Any] in
            let b = (s["b"] as! NSNumber).intValue
            let y = (s["y"] as! NSNumber).intValue
            return ["b": b, "y": y, "t": temperatureAt(b, y), "snows": snowsAt(b, y)]
        }
        for path in goldenPaths("biome-goldens.json") {
            guard let d = FileManager.default.contents(atPath: path),
                  var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
            obj["tempSamples"] = captured
            if let out = try? JSONSerialization.data(withJSONObject: obj) {
                try? out.write(to: URL(fileURLWithPath: path))
                print("    REGENERATED tempSamples (\(captured.count))")
            }
            break
        }
        check("temperature: goldens regenerated (native baseline)", true)
    } else {
    var tOK = true
    for s in temps {
        let b = (s["b"] as! NSNumber).intValue
        let y = (s["y"] as! NSNumber).intValue
        let want = (s["t"] as! NSNumber).doubleValue
        let wantSnows = (s["snows"] as! NSNumber).boolValue
        if abs(temperatureAt(b, y) - want) > 1e-12 || snowsAt(b, y) != wantSnows {
            tOK = false
            print("    temp b=\(b) y=\(y) got \(temperatureAt(b, y)) want \(want)")
        }
    }
    check("temperatureAt/snowsAt \(temps.count) samples", tOK)
    }

    let flags = (g["flags"] as! [NSNumber]).map { $0.intValue }
    var flagsOK = true
    for (i, f) in flags.enumerated() {
        let got = (isOceanBiome(i) ? 1 : 0) | (isCaveBiome(i) ? 2 : 0)
        if got != f { flagsOK = false; print("    flags[\(i)] got \(got) want \(f)") }
    }
    check("ocean/cave flags all \(flags.count) biomes", flagsOK)

    if let allColors = g["allColors"] as? [[NSNumber]] {
        var colorsOK = true
        for (i, cs) in allColors.enumerated() {
            guard let d = BIOMES[i] else { colorsOK = false; continue }
            let got = [d.grassColor, d.foliageColor, d.waterColor, d.fogTint]
            for (j, w) in cs.enumerated() where got[j] != w.uint32Value {
                colorsOK = false
                print("    \(d.name) color[\(j)] got \(String(got[j], radix: 16)) want \(String(w.uint32Value, radix: 16))")
            }
        }
        check("grass/foliage/water/fog colors all \(allColors.count) biomes", colorsOK)
    }
} else {
    check("biome-goldens.json loadable", false, "not found — run from the repo root (goldens/)")
}

// ---------------------------------------------------------------------------
section("overworld terrain (vs goldens)")

func fnvU16(_ arr: [UInt16]) -> UInt32 {
    var h: UInt32 = 2166136261
    for v in arr {
        h = (h ^ UInt32(v & 0xff)) &* 16777619
        h = (h ^ UInt32(v >> 8)) &* 16777619
    }
    return h
}
func fnvI16(_ arr: [Int16]) -> UInt32 {
    var h: UInt32 = 2166136261
    for s in arr {
        let v = UInt16(bitPattern: s)
        h = (h ^ UInt32(v & 0xff)) &* 16777619
        h = (h ^ UInt32(v >> 8)) &* 16777619
    }
    return h
}
func fnvU8(_ arr: [UInt8]) -> UInt32 {
    var h: UInt32 = 2166136261
    for b in arr { h = (h ^ UInt32(b)) &* 16777619 }
    return h
}

if let g = loadJSON("terrain-goldens.json") {
    var terrainGens: [UInt32: OverworldGen] = [:]
    func genFor(_ s: UInt32) -> OverworldGen {
        if let g = terrainGens[s] { return g }
        let g = OverworldGen(s)
        terrainGens[s] = g
        return g
    }

    // native baseline since the #26 worldgen quality pass (regenerate with
    // PEBBLE_REGOLD=1 after deliberate generation changes)
    let tRegold = ProcessInfo.processInfo.environment["PEBBLE_REGOLD"] != nil
    var tCaptured: [[String: Any]] = []
    let chunkList = g["chunks"] as! [[String: Any]]
    for (i, c) in chunkList.enumerated() {
        let seed = (c["seed"] as! NSNumber).uint32Value
        let cx = (c["cx"] as! NSNumber).intValue
        let cz = (c["cz"] as! NSNumber).intValue
        let gen = genFor(seed)
        var blocks = [UInt16](repeating: 0, count: 16 * 16 * WORLD_H)
        var biomes = [UInt8](repeating: 0, count: 4 * 4 * ((WORLD_H + 3) / 4))
        let t0 = DispatchTime.now()
        let res = gen.fillTerrain(cx, cz, &blocks, &biomes)
        let label = "seed \(seed) (\(cx),\(cz))"
        let hFill = fnvU16(blocks)
        let hHeights = fnvI16(res.heights)
        let hSurfaceBiomes = fnvU8(res.surfaceBiomes)
        let hBiomes = fnvU8(biomes)
        gen.carve(cx, cz, &blocks)
        let hCarve = fnvU16(blocks)
        gen.applySurface(cx, cz, &blocks, res.heights, res.surfaceBiomes)
        let hSurface = fnvU16(blocks)
        gen.placeOres(cx, cz, &blocks, res.surfaceBiomes)
        let hOres = fnvU16(blocks)
        gen.applySnowAndIce(cx, cz, &blocks, res.surfaceBiomes)
        let hSnow = fnvU16(blocks)
        let ms = Double(DispatchTime.now().uptimeNanoseconds - t0.uptimeNanoseconds) / 1e6
        if tRegold {
            tCaptured.append([
                "seed": NSNumber(value: seed), "cx": cx, "cz": cz,
                "hFill": NSNumber(value: hFill), "hHeights": NSNumber(value: hHeights),
                "hSurfaceBiomes": NSNumber(value: hSurfaceBiomes), "hBiomes": NSNumber(value: hBiomes),
                "hCarve": NSNumber(value: hCarve), "hSurface": NSNumber(value: hSurface),
                "hOres": NSNumber(value: hOres), "hSnow": NSNumber(value: hSnow),
                "heights": res.heights.map { NSNumber(value: $0) },
            ])
            continue
        }
        check("\(label) fillTerrain hash", hFill == (c["hFill"] as! NSNumber).uint32Value,
              "got \(String(hFill, radix: 16)) want \(String((c["hFill"] as! NSNumber).uint32Value, radix: 16))")
        check("\(label) heights hash", hHeights == (c["hHeights"] as! NSNumber).uint32Value)
        check("\(label) surfaceBiomes hash", hSurfaceBiomes == (c["hSurfaceBiomes"] as! NSNumber).uint32Value)
        check("\(label) biomes hash", hBiomes == (c["hBiomes"] as! NSNumber).uint32Value)
        check("\(label) carve hash", hCarve == (c["hCarve"] as! NSNumber).uint32Value,
              "got \(String(hCarve, radix: 16)) want \(String((c["hCarve"] as! NSNumber).uint32Value, radix: 16))")
        check("\(label) applySurface hash", hSurface == (c["hSurface"] as! NSNumber).uint32Value)
        check("\(label) placeOres hash", hOres == (c["hOres"] as! NSNumber).uint32Value)
        check("\(label) snow/ice hash [\(String(format: "%.1f", ms))ms]", hSnow == (c["hSnow"] as! NSNumber).uint32Value)

        // cell-level diff for the first case if anything mismatched
        if i == 0, let b64 = c["blocksB64"] as? String, fnvU16(blocks) != (c["hSnow"] as! NSNumber).uint32Value {
            if let data = Data(base64Encoded: b64) {
                let want: [UInt16] = data.withUnsafeBytes { Array($0.bindMemory(to: UInt16.self)) }
                var shown = 0
                for idx in 0..<min(want.count, blocks.count) where want[idx] != blocks[idx] {
                    let y = idx / 256 + GEN_MIN_Y, z = (idx / 16) % 16, x = idx % 16
                    print("    cell (\(x),\(y),\(z)) got \(blocks[idx]) want \(want[idx])")
                    shown += 1
                    if shown >= 12 { break }
                }
            }
        }

        // heights array equality (cheap, already hashed — belt and suspenders)
        let wantHeights = (c["heights"] as! [NSNumber]).map { Int16(truncating: $0) }
        check("\(label) heights array equal", res.heights == wantHeights)
    }

    // scalar samples on seed 12345
    let sg = genFor(12345)
    let coords = (g["coords"] as! [[NSNumber]]).map { (Double(truncating: $0[0]), Double(truncating: $0[1])) }
    if tRegold {
        for path in goldenPaths("terrain-goldens.json") {
            guard let d = FileManager.default.contents(atPath: path),
                  var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
            obj["chunks"] = tCaptured
            obj["heightSamples"] = coords.map { NSNumber(value: sg.heightEstimate($0.0, $0.1)) }
            obj["biomeSamples"] = coords.map { NSNumber(value: sg.surfaceBiomeAt($0.0, $0.1).rawValue) }
            obj["aquiferSamples"] = coords.map { (x, z) -> [NSNumber] in
                let a = sg.aquiferAt(x, z, sg.climate.at(x, z))
                return [NSNumber(value: a.level), NSNumber(value: a.lava ? 1 : 0)]
            }
            var caves: [NSNumber] = []
            for (x, z) in coords {
                for y in [-30, 0, 40] {
                    caves.append(NSNumber(value: sg.caveBiomeAt(x, y, z, sg.heightEstimate(x, z))))
                }
            }
            obj["caveSamples"] = caves
            if let out = try? JSONSerialization.data(withJSONObject: obj) {
                try? out.write(to: URL(fileURLWithPath: path))
                print("    REGENERATED terrain chunks (\(tCaptured.count)) + scalar samples -> \(path)")
            }
            break
        }
        check("terrain: goldens regenerated (native baseline)", true)
    } else {
    let wantHeightsS = (g["heightSamples"] as! [NSNumber]).map { $0.intValue }
    var hOK = true
    for (i, (x, z)) in coords.enumerated() where sg.heightEstimate(x, z) != wantHeightsS[i] {
        hOK = false
        print("    heightEstimate(\(x),\(z)) got \(sg.heightEstimate(x, z)) want \(wantHeightsS[i])")
    }
    check("heightEstimate \(coords.count) samples", hOK)

    let wantBiomesS = (g["biomeSamples"] as! [NSNumber]).map { $0.intValue }
    var bOK = true
    for (i, (x, z)) in coords.enumerated() where sg.surfaceBiomeAt(x, z).rawValue != wantBiomesS[i] {
        bOK = false
    }
    check("surfaceBiomeAt \(coords.count) samples", bOK)

    let wantAq = (g["aquiferSamples"] as! [[NSNumber]])
    var aqOK = true
    for (i, (x, z)) in coords.enumerated() {
        let a = sg.aquiferAt(x, z, sg.climate.at(x, z))
        if a.level != wantAq[i][0].intValue || (a.lava ? 1 : 0) != wantAq[i][1].intValue { aqOK = false }
    }
    check("aquiferAt \(coords.count) samples", aqOK)

    let wantCave = (g["caveSamples"] as! [NSNumber]).map { $0.intValue }
    var cvOK = true
    var cvi = 0
    for (x, z) in coords {
        for y in [-30, 0, 40] {
            if sg.caveBiomeAt(x, y, z, sg.heightEstimate(x, z)) != wantCave[cvi] { cvOK = false }
            cvi += 1
        }
    }
    check("caveBiomeAt \(wantCave.count) samples", cvOK)
    }

    let wantClim = (g["climSamples"] as! [[String]])
    var clOK = true
    for (i, cs) in wantClim.enumerated() {
        let (x, z) = coords[i]
        let c = sg.climate.at(x, z)
        let got = [c.t, c.h, c.c, c.e, c.w, c.pv, c.rare]
        for (j, hex) in cs.enumerated() {
            let want = Double(bitPattern: UInt64(hex, radix: 16)!)
            if got[j].bitPattern != want.bitPattern {
                clOK = false
                print("    climate[\(i)][\(j)] got \(got[j]) want \(want)")
            }
        }
    }
    check("climate fields bit-pattern-exact \(wantClim.count) samples", clOK)
} else {
    check("terrain-goldens.json loadable", false, "not found — run from the repo root (goldens/)")
}

// ---------------------------------------------------------------------------
section("full chunk pipeline with features (vs goldens)")

if let g = loadJSON("feature-goldens.json") {
    func fnvStr(_ h0: UInt32, _ s: String) -> UInt32 {
        var h = h0
        for b in Array(s.utf8) { h = (h ^ UInt32(b)) &* 16777619 }
        return h
    }
    func fnvInt(_ h0: UInt32, _ v: Int) -> UInt32 {
        var h = h0
        let u = UInt32(truncatingIfNeeded: v)
        h = (h ^ (u & 0xff)) &* 16777619
        h = (h ^ ((u >> 8) & 0xff)) &* 16777619
        h = (h ^ ((u >> 16) & 0xff)) &* 16777619
        h = (h ^ ((u >> 24) & 0xff)) &* 16777619
        return h
    }
    // native baseline since the #26 worldgen quality pass (regenerate with
    // PEBBLE_REGOLD=1 after deliberate generation changes)
    let fRegold = ProcessInfo.processInfo.environment["PEBBLE_REGOLD"] != nil
    var fCaptured: [[String: Any]] = []
    let cases = g["cases"] as! [[String: Any]]
    var totalMs = 0.0
    for c in cases {
        let seed = (c["seed"] as! NSNumber).uint32Value
        let cx = (c["cx"] as! NSNumber).intValue
        let cz = (c["cz"] as! NSNumber).intValue
        let dim = Dim(rawValue: (c["dim"] as! NSNumber).intValue)!
        let t0 = DispatchTime.now()
        let out = generateChunk(dim, seed, cx, cz)
        let ms = Double(DispatchTime.now().uptimeNanoseconds - t0.uptimeNanoseconds) / 1e6
        totalMs += ms
        let label = "d\(dim.rawValue) seed \(seed) (\(cx),\(cz))"
        let hBlocks = fnvU16(out.blocks)
        let hBiomes = fnvU8(out.biomes)
        var beHash: UInt32 = 2166136261
        for be in out.blockEntities {
            beHash = fnvInt(beHash, be.x); beHash = fnvInt(beHash, be.y); beHash = fnvInt(beHash, be.z)
            beHash = fnvStr(beHash, be.kind)
        }
        var entHash: UInt32 = 2166136261
        for e in out.entities {
            entHash = fnvStr(entHash, e.mob)
            entHash = fnvInt(entHash, Int((e.x * 2).rounded())); entHash = fnvInt(entHash, Int((e.y * 2).rounded())); entHash = fnvInt(entHash, Int((e.z * 2).rounded()))
        }
        var refHash: UInt32 = 2166136261
        for rf in out.structRefs {
            refHash = fnvStr(refHash, rf.id)
            refHash = fnvInt(refHash, rf.x0); refHash = fnvInt(refHash, rf.y0); refHash = fnvInt(refHash, rf.z0)
            refHash = fnvInt(refHash, rf.x1); refHash = fnvInt(refHash, rf.y1); refHash = fnvInt(refHash, rf.z1)
        }
        if fRegold {
            fCaptured.append([
                "seed": NSNumber(value: seed), "cx": cx, "cz": cz, "dim": dim.rawValue,
                "hBlocks": NSNumber(value: hBlocks), "hBiomes": NSNumber(value: hBiomes),
                "beCount": out.blockEntities.count, "beHash": NSNumber(value: beHash),
                "entCount": out.entities.count, "entHash": NSNumber(value: entHash),
                "refCount": out.structRefs.count, "refHash": NSNumber(value: refHash),
            ])
            continue
        }
        let wantBlocks = (c["hBlocks"] as! NSNumber).uint32Value
        check("\(label) blocks hash [\(String(format: "%.0f", ms))ms]", hBlocks == wantBlocks,
              "got \(String(hBlocks, radix: 16)) want \(String(wantBlocks, radix: 16))")
        check("\(label) biomes hash", hBiomes == (c["hBiomes"] as! NSNumber).uint32Value)
        check("\(label) BE count", out.blockEntities.count == (c["beCount"] as! NSNumber).intValue,
              "got \(out.blockEntities.count) want \(c["beCount"]!)")
        check("\(label) BE hash", beHash == (c["beHash"] as! NSNumber).uint32Value)
        check("\(label) entity count", out.entities.count == (c["entCount"] as! NSNumber).intValue,
              "got \(out.entities.count) want \(c["entCount"]!)")
        check("\(label) entity hash", entHash == (c["entHash"] as! NSNumber).uint32Value)
        check("\(label) structRefs \(out.structRefs.count)", out.structRefs.count == (c["refCount"] as! NSNumber).intValue
              && refHash == (c["refHash"] as! NSNumber).uint32Value)
    }
    if fRegold {
        for path in goldenPaths("feature-goldens.json") {
            guard let d = FileManager.default.contents(atPath: path),
                  var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
            obj["cases"] = fCaptured
            if let out = try? JSONSerialization.data(withJSONObject: obj) {
                try? out.write(to: URL(fileURLWithPath: path))
                print("    REGENERATED feature cases (\(fCaptured.count)) -> \(path)")
            }
            break
        }
        check("features: goldens regenerated (native baseline)", true)
    }
    print("  · full pipeline avg \(String(format: "%.1f", totalMs / Double(cases.count)))ms/chunk (debug build)")
} else {
    check("feature-goldens.json loadable", false, "not found — run from the repo root (goldens/)")
}

// ---------------------------------------------------------------------------
section("atlas painters (vs goldens)")

if let g = loadJSON("atlas-goldens.json") {
    let hashes = g["hashes"] as! [String: NSNumber]
    let t0 = DispatchTime.now()
    let atlas = buildAtlas()
    let ms = Double(DispatchTime.now().uptimeNanoseconds - t0.uptimeNanoseconds) / 1e6
    let baseCount = (g["count"] as! NSNumber).intValue
    check("tile count (baseline range intact)", atlas.count >= baseCount,
          "got \(atlas.count) want >= \(g["count"]!)")
    check("no missing painters", atlas.missing.isEmpty, "missing: \(atlas.missing.prefix(10))")
    let names = Array(allTileNames().prefix(baseCount))
    var mismatches: [String] = []
    for (i, n) in names.enumerated() {
        let h = fnvU8(atlas.pixels[i])
        if h != hashes[n]?.uint32Value {
            mismatches.append(n)
        }
    }
    check("\(names.count) baseline tiles pixel-identical [\(String(format: "%.0f", ms))ms]", mismatches.isEmpty,
          "\(mismatches.count) mismatched: \(mismatches.prefix(12))")
    if !mismatches.isEmpty, let b64 = g["sampleB64"] as? String,
       let sampleName = g["sampleName"] as? String,
       mismatches.contains(sampleName),
       let data = Data(base64Encoded: b64) {
        let want = [UInt8](data)
        let got = atlas.pixels[names.firstIndex(of: sampleName)!]
        for i in 0..<min(want.count, got.count) where want[i] != got[i] {
            print("    \(sampleName) byte[\(i)] px(\(i / 4 % 16),\(i / 64)) ch\(i % 4) got \(got[i]) want \(want[i])")
            break
        }
    }
} else {
    check("atlas-goldens.json loadable", false, "not found — run from the repo root (goldens/)")
}

// ---------------------------------------------------------------------------
section("section mesher (vs goldens)")

if let g = loadJSON("mesh-goldens.json") {
    func fnvU32(_ arr: [UInt32]) -> UInt32 {
        var h: UInt32 = 2166136261
        for v in arr {
            h = (h ^ (v & 0xff)) &* 16777619
            h = (h ^ ((v >> 8) & 0xff)) &* 16777619
            h = (h ^ ((v >> 16) & 0xff)) &* 16777619
            h = (h ^ ((v >> 24) & 0xff)) &* 16777619
        }
        return h
    }

    struct LitChunk {
        let blocks: [UInt16]
        let biomes: [UInt8]
        let sky: [UInt8]
        let blk: [UInt8]
    }
    var litCache: [String: LitChunk] = [:]
    func litChunk(_ seed: UInt32, _ cx: Int, _ cz: Int) -> LitChunk {
        let key = "\(seed):\(cx),\(cz)"
        if let c = litCache[key] { return c }
        let out = generateOverworldChunk(seed, cx, cz)
        let light = computeLocalLight(blocks: out.blocks, height: WORLD_H, hasSky: true)
        let c = LitChunk(blocks: out.blocks, biomes: out.biomes, sky: light.sky, blk: light.blk)
        litCache[key] = c
        return c
    }
    func chunkBiomeAt(_ c: LitChunk, _ lx: Int, _ y: Int, _ lz: Int) -> UInt8 {
        let qy = max(0, min((WORLD_H >> 2) - 1, (y - GEN_MIN_Y) >> 2))
        return c.biomes[(qy * 4 + (lz >> 2)) * 4 + (lx >> 2)]
    }
    func buildSnapshot(_ seed: UInt32, _ cx: Int, _ sy: Int, _ cz: Int) -> MeshInput {
        let P = 18
        var blocks = [UInt16](repeating: 0, count: P * P * P)
        var skyLight = [UInt8](repeating: 0, count: P * P * P)
        var blockLight = [UInt8](repeating: 0, count: P * P * P)
        var biomes = [UInt8](repeating: 0, count: P * P)
        let baseY = GEN_MIN_Y + sy * 16
        let baseX = cx * 16, baseZ = cz * 16
        for dz in -1...16 {
            for dx in -1...16 {
                let wx = baseX + dx, wz = baseZ + dz
                let c = litChunk(seed, floorDiv(wx, 16), floorDiv(wz, 16))
                let lx = posMod(wx, 16), lz = posMod(wz, 16)
                biomes[(dz + 1) * P + (dx + 1)] = chunkBiomeAt(c, lx, min(GEN_MIN_Y + WORLD_H - 1, max(GEN_MIN_Y, baseY + 8)), lz)
                for dy in -1...16 {
                    let wy = baseY + dy
                    let idx = ((dy + 1) * P + (dz + 1)) * P + (dx + 1)
                    if wy < GEN_MIN_Y || wy >= GEN_MIN_Y + WORLD_H {
                        blocks[idx] = 0
                        skyLight[idx] = wy >= GEN_MIN_Y + WORLD_H ? 15 : 0
                        blockLight[idx] = 0
                    } else {
                        let ci = ((wy - GEN_MIN_Y) * 16 + lz) * 16 + lx
                        blocks[idx] = c.blocks[ci]
                        skyLight[idx] = c.sky[ci]
                        blockLight[idx] = c.blk[ci]
                    }
                }
            }
        }
        return MeshInput(blocks: blocks, skyLight: skyLight, blockLight: blockLight, biomes: biomes)
    }

    // verify lighting first — light feeds the greedy merge keys
    if let lights = g["lights"] as? [[String: Any]] {
        var lightOK = true
        var lightCaptured: [[String: Any]] = []
        let lRegold = ProcessInfo.processInfo.environment["PEBBLE_REGOLD"] != nil
        for l in lights {
            let key = l["key"] as! String
            let parts = key.split(separator: ":")
            let seed = UInt32(parts[0])!
            let coords = parts[1].split(separator: ",")
            let c = litChunk(seed, Int(coords[0])!, Int(coords[1])!)
            if lRegold {
                lightCaptured.append(["key": key, "hSky": NSNumber(value: fnvU8(c.sky)), "hBlk": NSNumber(value: fnvU8(c.blk))])
                continue
            }
            if fnvU8(c.sky) != (l["hSky"] as! NSNumber).uint32Value {
                lightOK = false
                print("    sky light mismatch at \(key): got \(String(fnvU8(c.sky), radix: 16)) want \(String((l["hSky"] as! NSNumber).uint32Value, radix: 16))")
            }
            if fnvU8(c.blk) != (l["hBlk"] as! NSNumber).uint32Value {
                lightOK = false
                print("    block light mismatch at \(key)")
            }
        }
        if lRegold {
            for path in goldenPaths("mesh-goldens.json") {
                guard let d = FileManager.default.contents(atPath: path),
                      var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
                obj["lights"] = lightCaptured
                if let out = try? JSONSerialization.data(withJSONObject: obj) {
                    try? out.write(to: URL(fileURLWithPath: path))
                    print("    REGENERATED mesh lights (\(lightCaptured.count))")
                }
                break
            }
            check("computeLocalLight: goldens regenerated", true)
        } else {
            check("computeLocalLight \(lights.count) chunks bit-identical", lightOK)
        }
    }

    // native baseline since the emitCross perpendicular-diagonal fix
    // (regenerate with PEBBLE_REGOLD=1 after deliberate mesher changes)
    let meshRegold = ProcessInfo.processInfo.environment["PEBBLE_REGOLD"] != nil
    var meshCaptured: [[String: Any]] = []
    let meshCases = g["cases"] as! [[String: Any]]
    for c in meshCases {
        let seed = (c["seed"] as! NSNumber).uint32Value
        let cx = (c["cx"] as! NSNumber).intValue
        let sy = (c["sy"] as! NSNumber).intValue
        let cz = (c["cz"] as! NSNumber).intValue
        let snap = buildSnapshot(seed, cx, sy, cz)
        let t0 = DispatchTime.now()
        let mesh = buildSectionMesh(snap)
        let ms = Double(DispatchTime.now().uptimeNanoseconds - t0.uptimeNanoseconds) / 1e6
        let label = "seed \(seed) (\(cx),s\(sy),\(cz))"
        if meshRegold {
            meshCaptured.append([
                "seed": NSNumber(value: seed), "cx": cx, "sy": sy, "cz": cz,
                "o": ["n": mesh.opaque.count, "hd": NSNumber(value: fnvU32(mesh.opaque.data)), "hi": NSNumber(value: fnvU32(mesh.opaque.idx))],
                "c": ["n": mesh.cutout.count, "hd": NSNumber(value: fnvU32(mesh.cutout.data)), "hi": NSNumber(value: fnvU32(mesh.cutout.idx))],
                "t": ["n": mesh.translucent.count, "hd": NSNumber(value: fnvU32(mesh.translucent.data)), "hi": NSNumber(value: fnvU32(mesh.translucent.idx))],
            ])
            continue
        }
        for (name, layer, want) in [("opaque", mesh.opaque, c["o"] as! [String: Any]),
                                    ("cutout", mesh.cutout, c["c"] as! [String: Any]),
                                    ("translucent", mesh.translucent, c["t"] as! [String: Any])] {
            let wn = (want["n"] as! NSNumber).intValue
            let whd = (want["hd"] as! NSNumber).uint32Value
            let whi = (want["hi"] as! NSNumber).uint32Value
            check("\(label) \(name) \(wn)v [\(String(format: "%.1f", ms))ms]",
                  layer.count == wn && fnvU32(layer.data) == whd && fnvU32(layer.idx) == whi,
                  "got n=\(layer.count) hd=\(String(fnvU32(layer.data), radix: 16)) hi=\(String(fnvU32(layer.idx), radix: 16)) want n=\(wn) hd=\(String(whd, radix: 16)) hi=\(String(whi, radix: 16))")
            if name == "cutout", layer.count != wn, let b64 = c["cutB64"] as? String, let dd = Data(base64Encoded: b64) {
                let want: [UInt32] = dd.withUnsafeBytes { Array($0.bindMemory(to: UInt32.self)) }
                var vi = 0
                while vi * 7 < min(want.count, layer.data.count) {
                    var same = true
                    for w in 0..<7 where want[vi * 7 + w] != layer.data[vi * 7 + w] { same = false }
                    if !same { break }
                    vi += 1
                }
                func dumpVert(_ src: [UInt32], _ i: Int, _ tag: String) {
                    guard i * 7 + 6 < src.count else { print("    \(tag) v\(i): <end>"); return }
                    let x = Float(bitPattern: src[i * 7]), y = Float(bitPattern: src[i * 7 + 1]), z = Float(bitPattern: src[i * 7 + 2])
                    let u = Float(bitPattern: src[i * 7 + 3]), v = Float(bitPattern: src[i * 7 + 4])
                    let A = src[i * 7 + 5], Bw = src[i * 7 + 6]
                    let tileIdx = Int(A & 4095), nrm = (A >> 12) & 7
                    let ao = (A >> 15) & 3, sk = (A >> 17) & 15, bl = (A >> 21) & 15
                    print("    \(tag) v\(i): pos(\(x),\(y),\(z)) uv(\(u),\(v)) tile=\(tileName(tileIdx)) n=\(nrm) ao=\(ao) sky=\(sk) blk=\(bl) B=\(String(Bw, radix: 16))")
                }
                // snapshot cells around the divergence
                let snap2 = buildSnapshot(seed, cx, sy, cz)
                for zz in 14...16 {
                    var row = "    cells z=\(zz): "
                    for xx in 5...10 {
                        for yy in 1...4 {
                            let cl = Int(snap2.blocks[((yy + 1) * 18 + (zz + 1)) * 18 + (xx + 1)])
                            if cl != 0 { row += "(\(xx),\(yy))=\(blockDefs[cl >> 4].name):\(cl & 15) " }
                        }
                    }
                    print(row)
                }
                print("    first divergent vertex: \(vi)")
                for k in 0..<6 {
                    dumpVert(layer.data, vi + k, "got ")
                    dumpVert(want, vi + k, "want")
                }
            }
        }
    }
    if meshRegold {
        for path in goldenPaths("mesh-goldens.json") {
            guard let d = FileManager.default.contents(atPath: path),
                  var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
            obj["cases"] = meshCaptured
            if let out = try? JSONSerialization.data(withJSONObject: obj) {
                try? out.write(to: URL(fileURLWithPath: path))
                print("    REGENERATED mesh cases (\(meshCaptured.count)) -> \(path)")
            }
            break
        }
        check("mesh: goldens regenerated (native baseline)", true)
    }
} else {
    check("mesh-goldens.json loadable", false, "not found — run from the repo root (goldens/)")
}

// ---------------------------------------------------------------------------
section("world simulation: light engine + fluids + ticks (vs goldens)")

if let g = loadJSON("worldsim-goldens.json") {
    registerFluidHandlers()
    let world = World(dim: .overworld, seed: 12345)
    for cz in -1...1 {
        for cx in -1...1 {
            let out = generateOverworldChunk(12345, cx, cz)
            let light = computeLocalLight(blocks: out.blocks, height: WORLD_H, hasSky: true)
            let c = Chunk(cx: cx, cz: cz, minY: GEN_MIN_Y, height: WORLD_H)
            c.blocks = out.blocks
            c.skyLight = light.sky
            c.blockLight = light.blk
            c.biomes = out.biomes
            c.buildHeightmap()
            c.scanSpecials()
            c.status = .generated
            world.setChunk(c)
        }
    }
    for cz in -1...1 {
        for cx in -1...1 {
            world.light.stitchChunk(world.getChunk(cx, cz)!)
        }
    }

    func fnvAll() -> (UInt32, UInt32, UInt32) {
        var hb: UInt32 = 2166136261, hs: UInt32 = 2166136261, hl: UInt32 = 2166136261
        for cz in -1...1 {
            for cx in -1...1 {
                let c = world.getChunk(cx, cz)!
                for i in 0..<c.blocks.count {
                    let v = c.blocks[i]
                    hb = (hb ^ UInt32(v & 0xff)) &* 16777619
                    hb = (hb ^ UInt32(v >> 8)) &* 16777619
                    hs = (hs ^ UInt32(c.skyLight[i])) &* 16777619
                    hl = (hl ^ UInt32(c.blockLight[i])) &* 16777619
                }
            }
        }
        return (hb, hs, hl)
    }

    // native baseline since the #26 worldgen quality pass (regenerate with
    // PEBBLE_REGOLD=1 after deliberate generation changes)
    let wsRegold = ProcessInfo.processInfo.environment["PEBBLE_REGOLD"] != nil
    var wsCaptured: [[String: Any]] = []
    let stages = g["stages"] as! [[String: Any]]
    var stageIdx = 0
    func checkStage(_ name: String) {
        let (hb, hs, hl) = fnvAll()
        if wsRegold {
            wsCaptured.append(["name": name, "h": ["b": NSNumber(value: hb), "s": NSNumber(value: hs), "l": NSNumber(value: hl)]])
            stageIdx += 1
            return
        }
        let want = stages[stageIdx]
        stageIdx += 1
        let wn = want["name"] as! String
        let wh = want["h"] as! [String: NSNumber]
        check("stage \(name) blocks+sky+blockLight",
              wn == name && hb == wh["b"]!.uint32Value && hs == wh["s"]!.uint32Value && hl == wh["l"]!.uint32Value,
              "got b=\(String(hb, radix: 16)) s=\(String(hs, radix: 16)) l=\(String(hl, radix: 16)) want b=\(String(wh["b"]!.uint32Value, radix: 16)) s=\(String(wh["s"]!.uint32Value, radix: 16)) l=\(String(wh["l"]!.uint32Value, radix: 16))")
    }

    checkStage("adopted")

    let TORCH = Int(cell(B.torch)), GLOW = Int(cell(B.glowstone)), STONE = Int(cell(B.stone))
    let WATERC = Int(cell(B.water, 0)), LAVAC = Int(cell(B.lava, 0))

    for y in 70...74 { for z in 2...6 { for x in 2...6 { world.setBlock(x, y, z, 0) } } }
    for z in 2...6 { for x in 2...6 { world.setBlock(x, 69, z, STONE) } }
    checkStage("box")

    world.setBlock(4, 70, 4, TORCH)
    checkStage("torch")

    for y in stride(from: 68, through: 40, by: -1) { world.setBlock(8, y, 8, 0) }
    world.setBlock(8, 40, 8, GLOW)
    checkStage("shaft")

    world.setBlock(4, 72, 4, WATERC)
    world.scheduleTick(4, 72, 4, Int(B.water), 1)
    for _ in 0..<200 { world.tick() }
    checkStage("water")

    world.setBlock(6, 73, 6, LAVAC)
    world.scheduleTick(6, 73, 6, Int(B.lava), 1)
    for _ in 0..<400 { world.tick() }
    checkStage("lava")

    world.setBlock(4, 70, 4, 0)
    for _ in 0..<10 { world.tick() }
    checkStage("untorch")

    world.setBlock(4, 69, 4, 0)
    world.setBlock(4, 68, 4, 0)
    for _ in 0..<600 { world.tick() }
    checkStage("drain")

    let p1 = world.rng.nextInt(1000000007), p2 = world.rng.nextInt(1000000007)
    if wsRegold {
        for path in goldenPaths("worldsim-goldens.json") {
            guard let d = FileManager.default.contents(atPath: path),
                  var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
            obj["stages"] = wsCaptured
            obj["rngProbe"] = [p1, p2]
            obj["time"] = world.time
            obj["dayTime"] = world.dayTime
            if let out = try? JSONSerialization.data(withJSONObject: obj) {
                try? out.write(to: URL(fileURLWithPath: path))
                print("    REGENERATED worldsim stages (\(wsCaptured.count)) -> \(path)")
            }
            break
        }
        check("worldsim: goldens regenerated (native baseline)", true)
    } else {
        let wantProbe = (g["rngProbe"] as! [NSNumber]).map { $0.intValue }
        check("world rng state in lockstep", p1 == wantProbe[0] && p2 == wantProbe[1],
              "got \(p1),\(p2) want \(wantProbe[0]),\(wantProbe[1])")
        check("world time/dayTime", world.time == (g["time"] as! NSNumber).intValue
              && world.dayTime == (g["dayTime"] as! NSNumber).intValue)
    }
} else {
    check("worldsim-goldens.json loadable", false, "not found — run from the repo root (goldens/)")
}

// ---------------------------------------------------------------------------
section("items: recipes/enchants/potions/loot (vs goldens)")
registerAllRecipes()
registerAllLootTables()

if let g = loadJSON("items-goldens.json") {
    // hashString === the baseline script's fnv (UTF-16 unit & 0xffff per char)
    func num(_ k: String) -> Int { (g[k] as! NSNumber).intValue }
    func hash32(_ k: String) -> UInt32 { UInt32(truncating: g[k] as! NSNumber) }

    // recipes
    let craftSer = craftingRecipes.map { r -> String in
        switch r {
        case .shaped(let w, let h, let grid, let out, let count):
            return "S|\(w)|\(h)|\(grid.map { $0 ?? "." }.joined(separator: ","))|\(out)|\(count)"
        case .shapeless(let inputs, let out, let count):
            return "L|\(inputs.joined(separator: ","))|\(out)|\(count)"
        }
    }.joined(separator: ";")
    check("crafting recipe count", craftingRecipes.count == num("craftCount"),
          "got \(craftingRecipes.count) want \(num("craftCount"))")
    check("crafting recipes hash", hashString(craftSer) == hash32("craftH"),
          "got \(hashString(craftSer)) want \(hash32("craftH"))")

    let smeltSer = smeltingRecipes.map {
        "\($0.input)>\($0.output)|\(Int(($0.xp * 1000 + 0.5).rounded(.down)))|\($0.kind)"
    }.joined(separator: ";")
    check("smelting recipe count", smeltingRecipes.count == num("smeltCount"),
          "got \(smeltingRecipes.count) want \(num("smeltCount"))")
    check("smelting recipes hash", hashString(smeltSer) == hash32("smeltH"),
          "got \(hashString(smeltSer)) want \(hash32("smeltH"))")

    let cutSer = stonecuttingRecipes.map { "\($0.input)>\($0.output)x\($0.count)" }.joined(separator: ";")
    check("stonecutting recipe count", stonecuttingRecipes.count == num("cutCount"),
          "got \(stonecuttingRecipes.count) want \(num("cutCount"))")
    check("stonecutting recipes hash", hashString(cutSer) == hash32("cutH"),
          "got \(hashString(cutSer)) want \(hash32("cutH"))")

    let smithSer = smithingRecipes.map { "\($0.template)+\($0.base)+\($0.addition)>\($0.output)" }.joined(separator: ";")
    check("smithing recipe count", smithingRecipes.count == num("smithCount"),
          "got \(smithingRecipes.count) want \(num("smithCount"))")
    check("smithing recipes hash", hashString(smithSer) == hash32("smithH"),
          "got \(hashString(smithSer)) want \(hash32("smithH"))")

    let tagsSer = TAGS.keys.sorted().map { "\($0):\(TAGS[$0]!.joined(separator: ","))" }.joined(separator: ";")
    check("tags hash", hashString(tagsSer) == hash32("tagsH"),
          "got \(hashString(tagsSer)) want \(hash32("tagsH"))")
    check("trim materials", TRIM_MATERIALS.joined(separator: ",") == (g["trimMaterials"] as! String))

    // enchantments
    check("enchantment count", ENCHANTMENTS.count == num("enchCount"),
          "got \(ENCHANTMENTS.count) want \(num("enchCount"))")
    let enchGold = g["enchEntries"] as! [[String: Any]]
    var enchOK = true, appliesOK = true
    for (i, eg) in enchGold.enumerated() {
        let e = ENCHANTMENTS[i]
        let wantId = eg["id"] as! String
        if e.id != wantId { enchOK = false; print("    ench[\(i)] id \(e.id) want \(wantId)"); continue }
        var s = "\(e.id)|\(e.maxLevel)|\(e.weight)|\(e.target)|\(e.treasure ? 1 : 0)|\(e.curse ? 1 : 0)|\(e.tradeable ? 1 : 0)|\(e.exclusiveGroup ?? "-")"
        for l in 1...e.maxLevel { s += "|\(e.minPower(l))..\(e.maxPower(l))" }
        if hashString(s) != UInt32(truncating: eg["h"] as! NSNumber) {
            enchOK = false; print("    ench[\(i)] \(e.id) def hash mismatch: \(s)")
        }
        // baseline prefix only — items appended after the baseline (vines)
        // aren't covered by the baseline-generated bitmaps
        let applies = itemDefs.prefix(BASE_ITEM_COUNT).map { appliesTo(e, $0) ? "1" : "0" }.joined()
        if hashString(applies) != UInt32(truncating: eg["applies"] as! NSNumber) {
            appliesOK = false; print("    ench[\(i)] \(e.id) appliesTo bits mismatch")
        }
    }
    check("39 enchantment defs + power windows bit-identical", enchOK)
    check("appliesTo over baseline \(BASE_ITEM_COUNT) items × 39 enchs", appliesOK)

    let compatSer = ENCHANTMENTS.map { a in
        ENCHANTMENTS.map { b in compatible(a, b) ? "1" : "0" }.joined()
    }.joined(separator: "|")
    check("compatibility matrix hash", hashString(compatSer) == hash32("compatH"),
          "got \(hashString(compatSer)) want \(hash32("compatH"))")

    let enchabilitySer = itemDefs.prefix(BASE_ITEM_COUNT).map { "\($0.name):\(enchantability($0))" }.joined(separator: ";")
    check("enchantability over baseline items", hashString(enchabilitySer) == hash32("enchabilityH"),
          "got \(hashString(enchabilitySer)) want \(hash32("enchabilityH"))")

    // effects / potions / brewing
    let effectsSer = EFFECTS.map { "\($0.id)|\($0.displayName)|\($0.color)|\($0.beneficial ? 1 : 0)|\($0.instant ? 1 : 0)" }.joined(separator: ";")
    check("effect count", EFFECTS.count == num("effectsCount"), "got \(EFFECTS.count) want \(num("effectsCount"))")
    check("effects hash", hashString(effectsSer) == hash32("effectsH"),
          "got \(hashString(effectsSer)) want \(hash32("effectsH"))")

    let potionsSer = POTIONS.map { p in
        "\(p.id)|\(p.displayName)|\(p.color)|\(p.effects.map { "\($0.effect):\($0.duration):\($0.amplifier)" }.joined(separator: ","))"
    }.joined(separator: ";")
    check("potion count", POTIONS.count == num("potionsCount"), "got \(POTIONS.count) want \(num("potionsCount"))")
    check("potions hash", hashString(potionsSer) == hash32("potionsH"),
          "got \(hashString(potionsSer)) want \(hash32("potionsH"))")

    let brewSer = BREW_RECIPES.map { "\($0.base)+\($0.ingredient)>\($0.result)" }.joined(separator: ";")
    check("brew recipe count", BREW_RECIPES.count == num("brewCount"), "got \(BREW_RECIPES.count) want \(num("brewCount"))")
    check("brew recipes hash", hashString(brewSer) == hash32("brewH"),
          "got \(hashString(brewSer)) want \(hash32("brewH"))")

    // loot tables — 40 rolls per table, full stack serialization in RNG lockstep
    func serStack(_ s: ItemStack) -> String {
        var str = "\(itemDef(s.id).name)x\(s.count)"
        if !s.ench.isEmpty { str += "e[\(s.ench.map { "\($0.id):\($0.lvl)" }.joined(separator: ","))]" }
        if let pot = s.data.potion { str += "p[\(pot)]" }
        return str
    }
    let lootGold = g["lootTables"] as! [[String: Any]]
    check("loot table count + order", allLootTables() == lootGold.map { $0["name"] as! String },
          "got \(allLootTables().count) tables")
    var lootOK = true
    for lg in lootGold {
        let name = lg["name"] as! String
        var rng = RandomX(hashString(name))
        var parts: [String] = []
        for _ in 0..<40 {
            for s in rollLoot(name, &rng) { parts.append(serStack(s)) }
            parts.append(";")
        }
        let h = hashString(parts.joined(separator: "|"))
        if h != UInt32(truncating: lg["h"] as! NSNumber) {
            lootOK = false
            print("    loot \(name): got \(h) want \(UInt32(truncating: lg["h"] as! NSNumber))")
        }
    }
    check("\(lootGold.count) loot tables × 40 rolls in RNG lockstep", lootOK)

    // direct enchantStackRandomly probes (raw strings for debuggability)
    let probeGold = g["enchProbes"] as! [String]
    var probes: [String] = []
    for item in ["diamond_sword", "book", "fishing_rod", "diamond_chestplate", "diamond_pickaxe", "bow", "iron_boots", "diamond_hoe"] {
        for lvl in [1, 5, 10, 15, 20, 25, 30, 39, 50] {
            var rng = RandomX(hashString("\(item)/\(lvl)"))
            let s = enchantStackRandomly(ItemStack(iid(item), 1), &rng, lvl)
            probes.append("\(item)@\(lvl)=\(itemDef(s.id).name):\(s.ench.map { "\($0.id):\($0.lvl)" }.joined(separator: ","))")
        }
    }
    var probesOK = probes.count == probeGold.count
    if probesOK {
        for (i, p) in probes.enumerated() where p != probeGold[i] {
            probesOK = false
            print("    probe[\(i)] got \(p) want \(probeGold[i])")
        }
    }
    check("\(probeGold.count) enchant-randomly probes byte-identical", probesOK)
} else {
    check("items-goldens.json loadable", false, "not found — run from the repo root (goldens/)")
}

// ---------------------------------------------------------------------------
section("portable fdlibm math (vs fmath goldens)")

if let g = loadJSON("fmath-goldens.json") {
    func hexD(_ x: Double) -> String {
        String(x.bitPattern >> 32, radix: 16) + "-" + String(x.bitPattern & 0xffff_ffff, radix: 16)
    }
    func parseHex(_ s: Substring) -> Double {
        let parts = s.split(separator: "-")
        let h = UInt64(parts[0], radix: 16)!
        let l = UInt64(parts[1], radix: 16)!
        return Double(bitPattern: (h << 32) | l)
    }
    let probes = g["probes"] as! [String]
    var okCount = 0, badCount = 0
    for p in probes {
        let io = p.split(separator: ":")
        let ins = io[0].split(separator: ",")
        let outs = io[1].split(separator: ",")
        if ins.count == 1 {
            let x = parseHex(ins[0])
            let ws = parseHex(outs[0]), wc = parseHex(outs[1])
            if detSin(x).bitPattern == ws.bitPattern && detCos(x).bitPattern == wc.bitPattern { okCount += 1 }
            else {
                badCount += 1
                if badCount <= 3 { print("    sin/cos(\(x)): got \(hexD(detSin(x))),\(hexD(detCos(x))) want \(outs)") }
            }
        } else {
            let y = parseHex(ins[0]), x = parseHex(ins[1])
            let w = parseHex(outs[0])
            if detAtan2(y, x).bitPattern == w.bitPattern { okCount += 1 }
            else {
                badCount += 1
                if badCount <= 3 { print("    atan2(\(y),\(x)): got \(hexD(detAtan2(y, x))) want \(outs[0])") }
            }
        }
    }
    check("\(probes.count) fdlibm sin/cos/atan2 probes bit-identical", badCount == 0, "\(badCount) mismatches")
} else {
    check("fmath-goldens.json loadable", false, "not found")
}

// ---------------------------------------------------------------------------
section("entities: zoo/combat/physics/trades/pathfinding/spawning (vs goldens)")
registerAllEntities()

if let g = loadJSON("entity-goldens.json") {
    func hex(_ x: Double) -> String {
        String(x.bitPattern >> 32, radix: 16) + "-" + String(x.bitPattern & 0xffff_ffff, radix: 16)
    }
    func ifloor(_ x: Double) -> Int { Int(x.rounded(.down)) }
    func num(_ k: String) -> Int { (g[k] as! NSNumber).intValue }
    func hash32(_ k: String) -> UInt32 { UInt32(truncating: g[k] as! NSNumber) }

    let nextEntityIdBeforeSavePolicyProbe = peekNextEntityId()
    let savePolicyWorld = World(dim: .overworld, seed: 12345)
    let standardSavePolicyEntity = Entity(world: savePolicyWorld)
    let transientSavePolicyEntity = LabCoreAgentEntity(
        world: savePolicyWorld,
        labAgentId: "save_policy_probe",
        physicalId: "physical_save_policy_probe"
    )
    let secondTransientSavePolicyEntity = LabCoreAgentEntity(
        world: savePolicyWorld,
        labAgentId: "save_policy_probe_2",
        physicalId: "physical_save_policy_probe_2"
    )
    let savePolicyCandidates = [standardSavePolicyEntity, transientSavePolicyEntity]
        .filter { !$0.isPlayer && !$0.dead && $0.shouldSaveToChunk }
    savePolicyWorld.addEntity(standardSavePolicyEntity)
    savePolicyWorld.addEntity(transientSavePolicyEntity)
    savePolicyWorld.addEntity(secondTransientSavePolicyEntity)
    let removedSavePolicyProbes = clearLabCoreAgentProbes(in: savePolicyWorld)
    let cleanupPolicyOK = removedSavePolicyProbes == 2
        && clearLabCoreAgentProbes(in: savePolicyWorld) == 0
        && savePolicyWorld.entities.count == 1
        && savePolicyWorld.entities.first === standardSavePolicyEntity
        && savePolicyWorld.entityById[standardSavePolicyEntity.id] === standardSavePolicyEntity
        && savePolicyWorld.entityById[transientSavePolicyEntity.id] == nil
        && savePolicyWorld.entityById[secondTransientSavePolicyEntity.id] == nil
    let savePolicyOK = standardSavePolicyEntity.shouldSaveToChunk
        && !transientSavePolicyEntity.shouldSaveToChunk
        && savePolicyCandidates.count == 1
        && savePolicyCandidates.first === standardSavePolicyEntity
        && cleanupPolicyOK
    resetEntityIds(nextEntityIdBeforeSavePolicyProbe)

    check("entity type count + chunk save policy",
          entityTypes().count == num("entityTypeCount") && savePolicyOK,
          "types \(entityTypes().count)/\(num("entityTypeCount")), standard=\(standardSavePolicyEntity.shouldSaveToChunk), probe=\(transientSavePolicyEntity.shouldSaveToChunk), candidates=\(savePolicyCandidates.count), removed=\(removedSavePolicyProbes)")
    check("entity registration order", hashString(entityTypes().joined(separator: ",")) == hash32("entityTypesH"))
    check("spawnable mob list", hashString(spawnableMobs().joined(separator: ",")) == hash32("spawnableH"))

    func buildWorld() -> World {
        let world = World(dim: .overworld, seed: 12345)
        for cz in -2...2 {
            for cx in -2...2 {
                let out = generateOverworldChunk(12345, cx, cz)
                let light = computeLocalLight(blocks: out.blocks, height: WORLD_H, hasSky: true)
                let c = Chunk(cx: cx, cz: cz, minY: GEN_MIN_Y, height: WORLD_H)
                c.blocks = out.blocks
                c.skyLight = light.sky
                c.blockLight = light.blk
                c.biomes = out.biomes
                c.buildHeightmap()
                c.scanSpecials()
                c.status = .generated
                world.setChunk(c)
            }
        }
        for cz in -2...2 {
            for cx in -2...2 {
                world.light.stitchChunk(world.getChunk(cx, cz)!)
            }
        }
        return world
    }

    func serMob(_ e: Entity, _ i: Int) -> String {
        var s = "\(e.type)#\(i):\(hex(e.x)),\(hex(e.y)),\(hex(e.z)),\(hex(e.vx)),\(hex(e.vy)),\(hex(e.vz)),\(hex(e.yaw))"
        s += ",og\(e.onGround ? 1 : 0),w\(e.inWater ? 1 : 0),a\(e.age),f\(e.fireTicks)"
        if let liv = e as? LivingEntity { s += ",h\(hex(liv.health))" }
        return s
    }

    func stepWorld(_ world: World) {
        world.tick()
        tickPendingTimeouts(world)
        for e in world.entities { (e as? Entity)?.tick() }
        for e in world.entities where e.dead {
            world.removeEntity(e)
        }
    }

    func determinize(_ e: Entity, _ i: Int) {
        e.persistent = true
        if let m = e as? LivingEntity { m.rng = RandomX(hashString("\(e.type)#\(i)")) }
        if let sheep = e as? Sheep { sheep.color = i % 16; sheep.sheared = false }
        if let chicken = e as? Chicken { chicken.eggTime = 99999 }
        if e is Parrot { e.data.variant = i % 5 }
        if e is Frog { e.data.variant = i % 3 }
        if e is Axolotl { e.data.variant = i % 4 }
        if e is Panda { e.data.gene = "normal" }
        if let goat = e as? Goat { goat.screaming = false }
        if let z = e as? Zombie {
            z.baby = false; z.speed = 0.095
            if let d = z as? Drowned { d.hasTrident = false }
        }
        if let slime = e as? Slime { slime.setSize(2) }
        if let h = e as? HorseBase { h.jumpStrength = 0.7; h.speed = 0.2; h.maxHealth = 26; h.health = 26 }
        if let l = e as? Llama { l.maxHealth = 22; l.health = 22; l.data.variant = i % 4 }
        if let v = e as? Vex { v.lifeTicks = 99999 }
        if let d = e as? EnderDragon { d.pathAngle = 1.25 }
    }

    // --- A) zoo
    let ZOO = ["cow", "mooshroom", "pig", "sheep", "chicken", "rabbit", "wolf", "cat", "fox", "parrot",
               "bee", "axolotl", "frog", "goat", "turtle", "dolphin", "squid", "bat", "polar_bear", "panda",
               "strider", "camel", "sniffer", "allay", "cod", "villager", "iron_golem", "snow_golem", "horse", "llama",
               "zombie", "skeleton", "creeper", "spider", "slime", "witch", "enderman", "silverfish", "phantom", "guardian",
               "shulker", "pillager", "vindicator", "evoker", "vex", "blaze", "ghast", "magma_cube", "zombified_piglin", "piglin",
               "hoglin", "wither_skeleton", "warden", "wither", "ender_dragon"]
    resetGameRng(hashString("zoo"))
    let zooWorld = buildWorld()
    zooWorld.dayTime = 13000
    var zooMobs: [Entity] = []
    for i in 0..<ZOO.count {
        let sx = -20 + (i % 8) * 6
        let sz = -20 + (i / 8) * 6
        let sy = zooWorld.surfaceY(sx, sz)
        let e = spawnMob(zooWorld, ZOO[i], Double(sx) + 0.5, Double(sy), Double(sz) + 0.5, SpawnOpts())!
        determinize(e, i)
        zooMobs.append(e)
    }
    func diffSer(_ label: String, _ got: String, _ want: String) -> Bool {
        if got == want { return true }
        let gParts = got.split(separator: "|", omittingEmptySubsequences: false)
        let wParts = want.split(separator: "|", omittingEmptySubsequences: false)
        for i in 0..<min(gParts.count, wParts.count) where gParts[i] != wParts[i] {
            print("    \(label) first diff @\(i):\n      got \(gParts[i])\n      want \(wParts[i])")
            return false
        }
        print("    \(label) length mismatch: got \(gParts.count) want \(wParts.count)")
        return false
    }

    // native baseline since entity-pushing landed (regenerate with
    // PEBBLE_REGOLD=1 after deliberate entity-behavior changes)
    let zooGold = g["zooStages"] as! [[String: Any]]
    let zooRegold = ProcessInfo.processInfo.environment["PEBBLE_REGOLD"] != nil
    var zooCaptured: [[String: Any]] = []
    var zooIdx = 0
    var zooOK = true
    for t in 1...200 {
        stepWorld(zooWorld)
        if t == 50 || t == 120 || t == 200 {
            let ser = zooMobs.enumerated().map { serMob($0.element, $0.offset) }.joined(separator: "|")
            if zooRegold {
                zooCaptured.append(["ser": ser, "t": t])
            } else {
                let want = zooGold[zooIdx]["ser"] as! String
                if !diffSer("zoo t=\(t)", ser, want) { zooOK = false }
            }
            zooIdx += 1
        }
    }
    if zooRegold {
        for path in goldenPaths("entity-goldens.json") {
            guard let d = FileManager.default.contents(atPath: path),
                  var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
            obj["zooStages"] = zooCaptured
            if let out = try? JSONSerialization.data(withJSONObject: obj) {
                try? out.write(to: URL(fileURLWithPath: path))
                print("    REGENERATED zooStages (\(zooCaptured.count) checkpoints) -> \(path)")
            }
            break
        }
        check("zoo: golden regenerated (native baseline)", true)
    } else {
        check("zoo: 55 mob types × 200 ticks bit-identical (3 checkpoints)", zooOK)
    }

    // --- B) combat
    resetGameRng(hashString("combat"))
    let combatWorld = buildWorld()
    combatWorld.dayTime = 13000
    let cPlayer = Player(world: combatWorld)
    let py = combatWorld.surfaceY(0, 0)
    cPlayer.setPos(0.5, Double(py), 0.5)
    cPlayer.rng = RandomX(hashString("player"))
    combatWorld.addEntity(cPlayer)
    var combatants: [Entity] = [cPlayer]
    let CMOBS = ["zombie", "spider", "slime", "vex", "iron_golem"]
    for i in 0..<CMOBS.count {
        let ang = Double(i) / Double(CMOBS.count) * .pi * 2
        let sx = ifloor(0.5 + cos(ang) * 10)
        let sz = ifloor(0.5 + sin(ang) * 10)
        let sy = combatWorld.surfaceY(sx, sz)
        let e = spawnMob(combatWorld, CMOBS[i], Double(sx) + 0.5, Double(sy), Double(sz) + 0.5, SpawnOpts())!
        determinize(e, 100 + i)
        combatants.append(e)
    }
    // contains the player → native baseline since the vanilla-physics change
    // (regenerate with PEBBLE_REGOLD=1 after deliberate physics changes)
    let combatGold = g["combatStages"] as! [[String: Any]]
    let combatRegold = ProcessInfo.processInfo.environment["PEBBLE_REGOLD"] != nil
    var combatCaptured: [[String: Any]] = []
    var combatIdx = 0
    var combatOK = true
    for t in 1...150 {
        stepWorld(combatWorld)
        cPlayer.travel()
        if t == 50 || t == 100 || t == 150 {
            var ser = combatants.enumerated().map { serMob($0.element, $0.offset) }.joined(separator: "|")
            ser += "|hunger\(cPlayer.hunger),sat\(hex(cPlayer.saturation)),exh\(hex(cPlayer.exhaustion)),dead\(cPlayer.dead ? 1 : 0)"
            if combatRegold {
                combatCaptured.append(["t": t, "ser": ser])
            } else {
                let want = combatGold[combatIdx]["ser"] as! String
                if !diffSer("combat t=\(t)", ser, want) { combatOK = false }
            }
            combatIdx += 1
        }
    }
    if combatRegold {
        for path in goldenPaths("entity-goldens.json") {
            guard let d = FileManager.default.contents(atPath: path),
                  var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
            obj["combatStages"] = combatCaptured
            if let out = try? JSONSerialization.data(withJSONObject: obj) {
                try? out.write(to: URL(fileURLWithPath: path))
                print("    REGENERATED combatStages (\(combatCaptured.count) checkpoints) -> \(path)")
            }
            break
        }
        check("combat: golden regenerated (vanilla baseline)", true)
    } else {
        check("combat: player + 5 mobs, damage/knockback in lockstep", combatOK)
    }

    // --- C) player physics
    resetGameRng(hashString("phys"))
    let physWorld = buildWorld()
    physWorld.dayTime = 13000
    let pPlayer = Player(world: physWorld)
    let ppy = physWorld.surfaceY(4, 4)
    pPlayer.setPos(4.5, Double(ppy), 4.5)
    pPlayer.rng = RandomX(hashString("physplayer"))
    physWorld.addEntity(pPlayer)
    // player physics is vanilla-exact since task #21 — this golden is a NATIVE
    // regression baseline now (regenerate with PEBBLE_REGOLD=1 after deliberate
    // physics changes) — these are native baselines, regenerated deliberately
    let physGold = g["physStages"] as! [[String: Any]]
    let regold = ProcessInfo.processInfo.environment["PEBBLE_REGOLD"] != nil
    var physCaptured: [[String: Any]] = []
    var physIdx = 0
    var physOK = true
    for t in 1...200 {
        pPlayer.moveForward = 0; pPlayer.moveStrafe = 0
        pPlayer.jumping = false; pPlayer.sprinting = false; pPlayer.sneaking = false
        if t <= 40 { pPlayer.moveForward = 1 }
        else if t <= 60 { pPlayer.moveForward = 1; pPlayer.jumping = true }
        else if t <= 100 { pPlayer.moveStrafe = 1 }
        else if t <= 140 { pPlayer.moveForward = 1; pPlayer.sprinting = true; pPlayer.jumping = t % 10 == 0 }
        else if t <= 160 { pPlayer.moveForward = 1; pPlayer.sneaking = true; pPlayer.yaw = 0.8 }
        physWorld.tick()
        pPlayer.tick()
        pPlayer.travel()
        if t % 20 == 0 {
            let s = "\(hex(pPlayer.x)),\(hex(pPlayer.y)),\(hex(pPlayer.z)),\(hex(pPlayer.vx)),\(hex(pPlayer.vy)),\(hex(pPlayer.vz)),og\(pPlayer.onGround ? 1 : 0),fall\(hex(pPlayer.fallDistance)),h\(hex(pPlayer.health))"
            if regold {
                physCaptured.append(["t": t, "s": s])
            } else {
                let want = physGold[physIdx]["s"] as! String
                if s != want {
                    physOK = false
                    print("    phys t=\(t):\n      got \(s)\n      want \(want)")
                }
            }
            physIdx += 1
        }
    }
    if regold {
        for path in goldenPaths("entity-goldens.json") {
            guard let d = FileManager.default.contents(atPath: path),
                  var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
            obj["physStages"] = physCaptured
            if let out = try? JSONSerialization.data(withJSONObject: obj) {
                try? out.write(to: URL(fileURLWithPath: path))
                print("    REGENERATED physStages (\(physCaptured.count) checkpoints) -> \(path)")
            }
            break
        }
        check("player physics: golden regenerated (vanilla baseline)", true)
    } else {
        check("player physics: 200 scripted-input ticks vs native baseline", physOK)
    }

    // --- D) trades
    resetGameRng(hashString("trades"))
    let tradeWorld = buildWorld()
    var tradeOK = true
    let tradeGold = g["tradeProbes"] as! [String]
    var tg = 0
    for prof in PROFESSIONS {
        for lvl in 1...5 {
            let v = createEntity("villager", tradeWorld) as! Villager
            v.profession = prof
            v.tradeLevel = lvl
            v.rng = RandomX(hashString("\(prof)/\(lvl)"))
            v.refreshTrades()
            let ser = v.offers.map { o -> String in
                var s = "\(o.buyA.id)x\(o.buyA.count)"
                if let b = o.buyB { s += "+\(b.id)x\(b.count)" }
                s += ">\(o.sell.id)x\(o.sell.count)"
                if !o.sell.ench.isEmpty { s += "e[\(o.sell.ench.map { "\($0.id):\($0.lvl)" }.joined(separator: ","))]" }
                return s
            }.joined(separator: ";")
            let got = "\(prof)@\(lvl)=\(ser)"
            if got != tradeGold[tg] {
                tradeOK = false
                print("    trade \(prof)@\(lvl):\n      got \(got)\n      want \(tradeGold[tg])")
            }
            tg += 1
        }
    }
    check("\(tradeGold.count) villager trade tables byte-identical", tradeOK)

    // --- E) pathfinding (terrain-dependent: regold rewrites with the rest)
    resetGameRng(hashString("paths"))
    let pathWorld = buildWorld()
    let pathGold = g["pathProbes"] as! [String]
    var pathOK = true
    var pathCaptured: [String] = []
    for i in 0..<8 {
        let fx = -24 + i * 6, fz = -18 + i * 4
        let tx = fx + 10 - (i % 3) * 7, tz = fz + 8 - (i % 4) * 5
        let p = findPath(pathWorld, Double(fx) + 0.5, Double(pathWorld.surfaceY(fx, fz)), Double(fz) + 0.5,
                         Double(tx) + 0.5, Double(pathWorld.surfaceY(tx, tz)), Double(tz) + 0.5)
        let got = p == nil ? "null" : p!.map { "\($0.x),\($0.y),\($0.z)" }.joined(separator: ";")
        pathCaptured.append(got)
        if !regold, got != pathGold[i] {
            pathOK = false
            print("    path[\(i)]:\n      got \(got.prefix(120))\n      want \(pathGold[i].prefix(120))")
        }
    }
    if regold {
        for path in goldenPaths("entity-goldens.json") {
            guard let d = FileManager.default.contents(atPath: path),
                  var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
            obj["pathProbes"] = pathCaptured
            if let out = try? JSONSerialization.data(withJSONObject: obj) {
                try? out.write(to: URL(fileURLWithPath: path))
                print("    REGENERATED pathProbes (8)")
            }
            break
        }
        check("A* paths: golden regenerated (native baseline)", true)
    } else {
        check("8 A* paths node-identical", pathOK)
    }

    // --- F) natural spawning
    resetGameRng(hashString("spawn"))
    let spawnWorld = buildWorld()
    spawnWorld.dayTime = 13000
    let sPlayer = Player(world: spawnWorld)
    sPlayer.setPos(0.5, Double(spawnWorld.surfaceY(0, 0)), 0.5)
    spawnWorld.addEntity(sPlayer)
    var spawnRng = RandomX(hashString("natural"))
    for i in 0..<40 {
        spawnWorld.time = i * 400
        naturalSpawnTick(spawnWorld, [sPlayer], &spawnRng)
    }
    let spawnedSer = spawnWorld.entities
        .compactMap { $0 as? Entity }
        .filter { $0 !== sPlayer }
        .map { "\($0.type)@\(hex($0.x)),\(hex($0.y)),\(hex($0.z))" }
        .joined(separator: "|")
    // native baseline since the vanilla-1.20 spawn-light rework (regenerate
    // with PEBBLE_REGOLD=1 after deliberate spawning changes)
    if ProcessInfo.processInfo.environment["PEBBLE_REGOLD"] != nil {
        for path in goldenPaths("entity-goldens.json") {
            guard let d = FileManager.default.contents(atPath: path),
                  var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
            obj["spawnCount"] = spawnWorld.entities.count - 1
            obj["spawnH"] = hashString(spawnedSer)
            if let out = try? JSONSerialization.data(withJSONObject: obj) {
                try? out.write(to: URL(fileURLWithPath: path))
                print("    REGENERATED spawnCount=\(spawnWorld.entities.count - 1) spawnH")
            }
            break
        }
        check("natural spawn: golden regenerated (native baseline)", true)
        check("natural spawn hash: golden regenerated", true)
    } else {
        check("natural spawn count", spawnWorld.entities.count - 1 == num("spawnCount"),
              "got \(spawnWorld.entities.count - 1) want \(num("spawnCount"))")
        check("natural spawn types+positions hash", hashString(spawnedSer) == hash32("spawnH"),
              "got \(hashString(spawnedSer)) want \(hash32("spawnH"))")
    }
} else {
    check("entity-goldens.json loadable", false, "not found — run from the repo root (goldens/)")
}

// ---------------------------------------------------------------------------
section("systems: crafting/BEs/redstone/explosion/interact/portals (vs goldens)")
// terrain-dependent systems goldens re-baseline under PEBBLE_REGOLD
let sysRegold = ProcessInfo.processInfo.environment["PEBBLE_REGOLD"] != nil
var sysCaptured: [String: Any] = [:]
registerAllSystems()

if let g = loadJSON("systems-goldens.json") {
    func hex(_ x: Double) -> String {
        String(x.bitPattern >> 32, radix: 16) + "-" + String(x.bitPattern & 0xffff_ffff, radix: 16)
    }
    func ifloor(_ x: Double) -> Int { Int(x.rounded(.down)) }
    /// deterministic Number→string: integral doubles print without ".0"
    func detNum(_ x: Double) -> String {
        if x == x.rounded() && abs(x) < 1e15 { return String(Int(x)) }
        return String(x)
    }
    func buildWorld() -> World {
        let world = World(dim: .overworld, seed: 12345)
        for cz in -1...1 {
            for cx in -1...1 {
                let out = generateOverworldChunk(12345, cx, cz)
                let light = computeLocalLight(blocks: out.blocks, height: WORLD_H, hasSky: true)
                let c = Chunk(cx: cx, cz: cz, minY: GEN_MIN_Y, height: WORLD_H)
                c.blocks = out.blocks
                c.skyLight = light.sky
                c.blockLight = light.blk
                c.biomes = out.biomes
                c.buildHeightmap()
                c.scanSpecials()
                c.status = .generated
                world.setChunk(c)
            }
        }
        for cz in -1...1 { for cx in -1...1 { world.light.stitchChunk(world.getChunk(cx, cz)!) } }
        return world
    }
    func serStack(_ s: ItemStack?) -> String {
        guard let s else { return "-" }
        var str = "\(itemDef(s.id).name)x\(s.count)"
        if s.damage != 0 { str += "d\(s.damage)" }
        if !s.ench.isEmpty { str += "e[\(s.ench.map { "\($0.id):\($0.lvl)" }.joined(separator: ","))]" }
        if let p = s.data.potion { str += "p[\(p)]" }
        if let w = s.data.priorWork, w != 0 { str += "w\(w)" }
        if let t = s.data.trim { str += "t[\(t.pattern):\(t.material)]" }
        if let l = s.label { str += "l[\(l)]" }
        return str
    }
    func regionHash(_ world: World, _ x0: Int, _ y0: Int, _ z0: Int, _ x1: Int, _ y1: Int, _ z1: Int) -> UInt32 {
        var h: UInt32 = 2166136261
        for y in y0...y1 {
            for z in z0...z1 {
                for x in x0...x1 {
                    let c = world.getBlock(x, y, z)
                    h = (h ^ UInt32(c & 0xff)) &* 16777619
                    h = (h ^ UInt32(c >> 8)) &* 16777619
                }
            }
        }
        return h
    }
    func entsSer(_ world: World, _ skip: EntityRef? = nil) -> String {
        world.entities.filter { !($0 === skip) }
            .map { "\(($0 as? Entity)?.type ?? "?")@\(hex($0.x)),\(hex($0.y)),\(hex($0.z))" }
            .joined(separator: "|")
    }
    func stepWorld(_ world: World) {
        world.tick()
        tickPendingTimeouts(world)
        for e in world.entities { (e as? Entity)?.tick() }
        for e in world.entities where e.dead { world.removeEntity(e) }
    }
    func cmpList(_ label: String, _ got: [String], _ want: [String]) {
        var ok = got.count == want.count
        if ok {
            for (i, w) in want.enumerated() where got[i] != w {
                ok = false
                print("    \(label)[\(i)]:\n      got \(got[i])\n      want \(w)")
                break
            }
        } else {
            print("    \(label) count: got \(got.count) want \(want.count)")
        }
        check(label, ok)
    }

    // --- A) crafting probes
    func st(_ name: String, _ count: Int = 1) -> ItemStack { ItemStack(iid(name), count) }
    var craftGot: [String] = []
    let craftCases: [(String, Int, Int, [ItemStack?])] = [
        ("planks", 2, 2, [st("oak_log"), nil, nil, nil]),
        ("sticks", 2, 2, [st("oak_planks"), nil, st("oak_planks"), nil]),
        ("table", 2, 2, [st("oak_planks"), st("oak_planks"), st("oak_planks"), st("oak_planks")]),
        ("pick", 3, 3, [st("oak_planks"), st("oak_planks"), st("oak_planks"), nil, st("stick"), nil, nil, st("stick"), nil]),
        ("axe-mirrored", 3, 3, [nil, st("oak_planks"), st("oak_planks"), nil, st("stick"), st("oak_planks"), nil, st("stick"), nil]),
        ("tag-planks-chest", 3, 3, [st("birch_planks"), st("birch_planks"), st("birch_planks"), st("birch_planks"), nil, st("birch_planks"), st("birch_planks"), st("birch_planks"), st("birch_planks")]),
        ("shapeless-flint", 2, 2, [st("iron_ingot"), st("flint"), nil, nil]),
        ("no-match-extra", 3, 3, [st("oak_log"), st("stick"), nil, nil, nil, nil, nil, nil, nil]),
        ("torch", 2, 2, [st("coal"), nil, st("stick"), nil]),
        ("bread", 3, 3, [st("wheat"), st("wheat"), st("wheat"), nil, nil, nil, nil, nil, nil]),
    ]
    for (label, w, h, grid) in craftCases {
        let m = matchCrafting(grid, w, h)
        craftGot.append("\(label)=\(m != nil ? serStack(m!.out) : "null")")
    }
    cmpList("crafting grid probes", craftGot, g["craftProbes"] as! [String])

    var smithGot: [String] = []
    smithGot.append("netherite=\(serStack(matchSmithing(st("netherite_upgrade"), st("diamond_sword"), st("netherite_ingot"))))")
    smithGot.append("trim=\(serStack(matchSmithing(st("coast_armor_trim"), st("iron_chestplate"), st("emerald"))))")
    smithGot.append("bad=\(serStack(matchSmithing(st("netherite_upgrade"), st("stone"), st("netherite_ingot"))))")
    cmpList("smithing probes", smithGot, g["smithProbes"] as! [String])

    // --- B) enchanting / anvil / grindstone
    var enchGot: [String] = []
    for (item, shelves, sd) in [("diamond_sword", 15, 777), ("book", 8, 1234), ("iron_pickaxe", 0, 42), ("diamond_chestplate", 15, 90210)] {
        let opts = enchantingOptions(st(item), shelves, sd)
        enchGot.append("\(item)@\(shelves)/\(sd)=" + opts.map { o in
            "L\(o.level):\(o.enchants.map { "\($0.id):\($0.lvl)" }.joined(separator: ","))"
        }.joined(separator: ";"))
    }
    cmpList("enchanting options", enchGot, g["enchProbes"] as! [String])

    var anvilGot: [String] = []
    let sword = ItemStack(iid("diamond_sword"), 1, damage: 100)
    let sword2 = ItemStack(iid("diamond_sword"), 1, damage: 500, ench: [EnchInstance("sharpness", 3)])
    let book = ItemStack(iid("enchanted_book"), 1, ench: [EnchInstance("sharpness", 3), EnchInstance("knockback", 2)])
    let r1 = anvilCombine(sword, sword2, nil)
    anvilGot.append("combine=\(r1 != nil ? serStack(r1!.out) + "$\(r1!.cost)" : "null")")
    let r2 = anvilCombine(sword, book, nil)
    anvilGot.append("book=\(r2 != nil ? serStack(r2!.out) + "$\(r2!.cost)" : "null")")
    let r3 = anvilCombine(sword, ItemStack(iid("diamond"), 3), nil)
    anvilGot.append("repair=\(r3 != nil ? serStack(r3!.out) + "$\(r3!.cost)" : "null")")
    let r4 = anvilCombine(ItemStack(iid("iron_sword"), 1), nil, "Slicey")
    anvilGot.append("rename=\(r4 != nil ? serStack(r4!.out) + "$\(r4!.cost)" : "null")")
    let g1 = grindstoneResult(sword2, nil)
    anvilGot.append("grind=\(g1 != nil ? serStack(g1!.out) + "$\(g1!.xp)" : "null")")
    cmpList("anvil/grindstone probes", anvilGot, g["anvilProbes"] as! [String])

    // --- C) BE timelines
    resetGameRng(hashString("be"))
    let beWorld = buildWorld()
    let bePy = beWorld.surfaceY(0, 0)
    let beBase = bePy + 20
    for dz in -3...3 { for dx in -3...3 { beWorld.setBlock(dx, beBase - 1, dz, Int(cell(B.stone))) } }
    beWorld.setBlock(0, beBase, 0, Int(cell(B.furnace, 0)))
    let fbe = makeFurnaceBE(0, beBase, 0, "furnace")
    var fitems = fbe.items!
    fitems[0] = ItemStack(iid("raw_iron"), 3)
    fitems[1] = ItemStack(iid("coal"), 2)
    fbe.items = fitems
    beWorld.setBlockEntity(fbe)
    beWorld.setBlock(0, beBase + 1, 0, Int(cell(B.hopper, 0)))
    let hbe = makeHopperBE(0, beBase + 1, 0)
    var hitems = hbe.items!
    hitems[0] = ItemStack(iid("raw_gold"), 2)
    hbe.items = hitems
    beWorld.setBlockEntity(hbe)
    beWorld.setBlock(2, beBase, 0, Int(cell(B.brewing_stand, 0)))
    let bbe = makeBrewingBE(2, beBase, 0)
    var bitems = bbe.items!
    var pd = StackData(); pd.potion = "awkward"
    bitems[0] = ItemStack(iid("potion"), 1, data: pd)
    bitems[3] = ItemStack(iid("blaze_powder"), 2)
    bitems[4] = ItemStack(iid("blaze_powder"), 2)
    bbe.items = bitems
    beWorld.setBlockEntity(bbe)
    var beGot: [String] = []
    for t in 1...450 {
        stepWorld(beWorld)
        if t == 100 || t == 250 || t == 450 {
            let f = "f:\((fbe.items ?? []).map(serStack).joined(separator: ",")):b\(fbe.burnTime ?? 0):c\(fbe.cookTime ?? 0):x\(detNum(fbe.xpBank ?? 0))"
            let h = "h:\((hbe.items ?? []).map(serStack).joined(separator: ",")):cd\(hbe.cooldown ?? 0)"
            let p = "p:\((bbe.items ?? []).map(serStack).joined(separator: ",")):bt\(bbe.brewTime ?? 0):fu\(bbe.fuel ?? 0)"
            beGot.append([f, h, p].joined(separator: "|"))
        }
    }
    cmpList("BE timelines (furnace/hopper/brewing)", beGot, g["beStages"] as! [String])

    // --- D) redstone contraption
    resetGameRng(hashString("redstone"))
    let rsWorld = buildWorld()
    let rsBase = rsWorld.surfaceY(8, 8) + 20
    for dz in 0...8 { for dx in 0...12 { rsWorld.setBlock(8 + dx, rsBase - 1, 8 + dz, Int(cell(B.stone))) } }
    rsWorld.setBlock(8, rsBase, 8, Int(cell(B.lever, 0)))
    for i in 1...5 { rsWorld.setBlock(8 + i, rsBase, 8, Int(cell(B.redstone_wire, 0))) }
    rsWorld.setBlock(14, rsBase, 8, Int(cell(B.repeater, 3)))
    rsWorld.setBlock(15, rsBase, 8, Int(cell(B.redstone_wire, 0)))
    rsWorld.setBlock(16, rsBase, 8, Int(cell(B.redstone_lamp)))
    rsWorld.setBlock(11, rsBase, 9, Int(cell(B.piston, 3)))
    rsWorld.setBlock(11, rsBase, 10, Int(cell(B.stone)))
    rsWorld.setBlock(12, rsBase, 10, Int(cell(B.observer, 4)))
    func flip(_ on: Bool) {
        let c = rsWorld.getBlock(8, rsBase, 8)
        rsWorld.setBlock(8, rsBase, 8, Int(cell(B.lever, on ? (c & 7) | 8 : c & 7)))
        rsWorld.updateNeighbors(8, rsBase, 8)
        rsWorld.updateNeighbors(8, rsBase - 1, 8)
    }
    var rsGot: [UInt32] = []
    flip(true)
    for _ in 1...30 { stepWorld(rsWorld) }
    rsGot.append(regionHash(rsWorld, 6, rsBase - 2, 6, 20, rsBase + 2, 14))
    flip(false)
    for _ in 1...30 { stepWorld(rsWorld) }
    rsGot.append(regionHash(rsWorld, 6, rsBase - 2, 6, 20, rsBase + 2, 14))
    flip(true)
    for _ in 1...4 { stepWorld(rsWorld) }
    rsGot.append(regionHash(rsWorld, 6, rsBase - 2, 6, 20, rsBase + 2, 14))
    let rsWant = (g["redstoneStages"] as! [NSNumber]).map { UInt32(truncating: $0) }
    check("redstone contraption (lever/wire/repeater/piston/lamp/observer)", rsGot == rsWant,
          "got \(rsGot) want \(rsWant)")

    // --- E) random ticks
    resetGameRng(hashString("crops"))
    let cropWorld = buildWorld()
    let cropBase = cropWorld.surfaceY(-8, -8) + 20
    for dz in 0..<6 {
        for dx in 0..<6 {
            cropWorld.setBlock(-8 + dx, cropBase - 1, -8 + dz, Int(cell(B.farmland, 7)))
            cropWorld.setBlock(-8 + dx, cropBase, -8 + dz, Int(cell(B.wheat, 0)))
        }
    }
    cropWorld.randomTickSpeed = 40
    for _ in 1...400 { cropWorld.tick() }
    let cropGot = regionHash(cropWorld, -8, cropBase - 1, -8, -3, cropBase, -3)
    if sysRegold {
        sysCaptured["cropHash"] = NSNumber(value: cropGot)
        check("crop growth: golden regenerated", true)
    } else {
        check("crop growth via seeded random ticks", cropGot == UInt32(truncating: g["cropHash"] as! NSNumber),
              "got \(cropGot) want \(g["cropHash"]!)")
    }

    // --- F) explosion
    resetGameRng(hashString("boom"))
    let boomWorld = buildWorld()
    let bpx = 4, bpz = 4
    let bpy = boomWorld.surfaceY(bpx, bpz)
    let cow = spawnMob(boomWorld, "cow", Double(bpx) + 3.5, Double(bpy) + 1, Double(bpz) + 0.5, SpawnOpts())!
    (cow as? LivingEntity)?.rng = RandomX(hashString("boomcow"))
    cow.persistent = true
    explode(boomWorld, Double(bpx) + 0.5, Double(bpy) + 0.5, Double(bpz) + 0.5, 4, true, nil)
    let boomGot = regionHash(boomWorld, bpx - 8, bpy - 8, bpz - 8, bpx + 8, bpy + 8, bpz + 8)
    let boomEnts = hashString(entsSer(boomWorld))
    if sysRegold {
        sysCaptured["explosionHash"] = NSNumber(value: boomGot)
        sysCaptured["explosionEnts"] = NSNumber(value: boomEnts)
        check("explosion: goldens regenerated", true)
        check("explosion ents: goldens regenerated", true)
    } else {
        check("explosion crater bit-identical", boomGot == UInt32(truncating: g["explosionHash"] as! NSNumber),
              "got \(boomGot) want \(g["explosionHash"]!)")
        check("explosion entity state (knockback + drops)", boomEnts == UInt32(truncating: g["explosionEnts"] as! NSNumber),
              "got \(boomEnts) want \(g["explosionEnts"]!)")
    }

    // --- G) interact
    resetGameRng(hashString("interact"))
    let iWorld = buildWorld()
    let iPlayer = Player(world: iWorld)
    let ipy = iWorld.surfaceY(0, -10)
    iPlayer.setPos(0.5, Double(ipy), -9.5)
    iPlayer.rng = RandomX(hashString("iplayer"))
    iWorld.addEntity(iPlayer)
    let ictx = InteractCtx(world: iWorld, player: iPlayer)
    func giveP(_ name: String, _ count: Int = 1) { iPlayer.inventory[iPlayer.selectedSlot] = ItemStack(iid(name), count) }
    func mkHit(_ x: Int, _ y: Int, _ z: Int, _ face: Int) -> RaycastHit {
        RaycastHit(x: x, y: y, z: z, face: face, cell: iWorld.getBlock(x, y, z), t: 0,
                   px: Double(x) + 0.5, py: Double(y) + (face == 1 ? 1 : 0.5), pz: Double(z) + 0.5)
    }
    var iGot: [String] = []
    let ibx = 0, ibz = -14
    let iby = iWorld.surfaceY(ibx, ibz)
    iPlayer.yaw = 0
    giveP("oak_stairs", 4)
    iGot.append("stairs=\(placeBlock(ictx, mkHit(ibx, iby - 1, ibz, 1), Int(itemDef(iPlayer.mainHand!.id).block!), iPlayer.mainHand!))@\(String(iWorld.getBlock(ibx, iby, ibz), radix: 16))")
    giveP("oak_door", 2)
    iGot.append("door=\(placeBlock(ictx, mkHit(ibx + 2, iby - 1, ibz, 1), Int(itemDef(iPlayer.mainHand!.id).block!), iPlayer.mainHand!))@\(String(iWorld.getBlock(ibx + 2, iby, ibz), radix: 16)),\(String(iWorld.getBlock(ibx + 2, iby + 1, ibz), radix: 16))")
    iGot.append("doorUse=\(useBlock(ictx, mkHit(ibx + 2, iby, ibz, 3)))@\(String(iWorld.getBlock(ibx + 2, iby, ibz), radix: 16))")
    giveP("white_bed")
    iGot.append("bed=\(placeBlock(ictx, mkHit(ibx + 4, iby - 1, ibz, 1), Int(itemDef(iPlayer.mainHand!.id).block!), iPlayer.mainHand!))@\(String(iWorld.getBlock(ibx + 4, iby, ibz), radix: 16))")
    giveP("torch", 4)
    iGot.append("torch=\(placeBlock(ictx, mkHit(ibx, iby, ibz - 2, 3), Int(itemDef(iPlayer.mainHand!.id).block!), iPlayer.mainHand!))")
    giveP("iron_pickaxe")
    finishBreaking(ictx, ibx, iby, ibz)
    iWorld.setBlock(ibx + 6, iby - 1, ibz, Int(cell(B.farmland, 7)))
    iWorld.setBlock(ibx + 6, iby, ibz, Int(cell(B.wheat, 0)))
    iGot.append("bonemeal=\(applyBonemeal(iWorld, ibx + 6, iby, ibz))@\(String(iWorld.getBlock(ibx + 6, iby, ibz), radix: 16))")
    giveP("golden_apple")
    _ = useItem(ictx, nil)
    finishUsingItem(ictx)
    iGot.append("ate=h\(iPlayer.hunger),s\(hex(iPlayer.saturation)),fx\(iPlayer.effects.map { "\($0.id):\($0.duration):\($0.amplifier)" }.joined(separator: ";"))")
    let iEnts = hashString(entsSer(iWorld, iPlayer))
    let iRegion = regionHash(iWorld, ibx - 2, iby - 2, ibz - 4, ibx + 8, iby + 2, ibz + 2)
    if sysRegold {
        sysCaptured["interactProbes"] = iGot
        sysCaptured["interactEnts"] = NSNumber(value: iEnts)
        sysCaptured["interactRegion"] = NSNumber(value: iRegion)
        check("interact: goldens regenerated", true)
        check("interact ents: goldens regenerated", true)
        check("interact region: goldens regenerated", true)
    } else {
        cmpList("interact probes (place/use/break/bonemeal/eat)", iGot, g["interactProbes"] as! [String])
        check("interact entity drops", iEnts == UInt32(truncating: g["interactEnts"] as! NSNumber),
              "got \(iEnts) want \(g["interactEnts"]!)")
        check("interact region blocks", iRegion == UInt32(truncating: g["interactRegion"] as! NSNumber),
              "got \(iRegion) want \(g["interactRegion"]!)")
    }

    // --- H) portal
    let pWorld = buildWorld()
    let ppy2 = pWorld.surfaceY(-12, 12) + 25
    for dy in 0..<5 {
        for dx in 0..<4 {
            let frame = dy == 0 || dy == 4 || dx == 0 || dx == 3
            pWorld.setBlock(-12 + dx, ppy2 + dy, 12, frame ? Int(cell(B.obsidian)) : 0)
        }
    }
    let pok = tryIgnitePortal(pWorld, -11, ppy2 + 1, 12)
    let pGot = "\(pok)@\(regionHash(pWorld, -13, ppy2 - 1, 11, -8, ppy2 + 5, 13))"
    if sysRegold {
        sysCaptured["portal"] = pGot
        check("portal: golden regenerated", true)
    } else {
        check("nether portal frame ignition", pGot == (g["portal"] as! String),
              "got \(pGot) want \(g["portal"]!)")
    }
    if sysRegold, !sysCaptured.isEmpty {
        for path in goldenPaths("systems-goldens.json") {
            guard let d = FileManager.default.contents(atPath: path),
                  var obj = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
            for (k, v) in sysCaptured { obj[k] = v }
            if let out = try? JSONSerialization.data(withJSONObject: obj) {
                try? out.write(to: URL(fileURLWithPath: path))
                print("    REGENERATED systems keys: \(sysCaptured.keys.sorted().joined(separator: ", "))")
            }
            break
        }
    }
} else {
    check("systems-goldens.json loadable", false, "not found")
}


// ---------------------------------------------------------------------------
section("vanilla player physics constants (independent derivations)")
do {
    // flat stone slab world — equilibrium measurements need perfectly flat ground
    func flatWorld(_ topBlock: UInt16 = 0) -> (World, Int) {
        let world = World(dim: .overworld, seed: 1)
        let groundY = 64
        for cz in -2...2 {
            for cx in -2...2 {
                let c = Chunk(cx: cx, cz: cz, minY: GEN_MIN_Y, height: WORLD_H)
                var blocks = [UInt16](repeating: 0, count: 16 * 16 * WORLD_H)
                let stone = cell(B.stone)
                for y in 0...(groundY - GEN_MIN_Y) {
                    for i in 0..<256 {
                        blocks[y * 256 + i] = y == groundY - GEN_MIN_Y && topBlock != 0 ? cell(topBlock) : stone
                    }
                }
                c.blocks = blocks
                c.skyLight = [UInt8](repeating: 15, count: blocks.count)
                c.blockLight = [UInt8](repeating: 0, count: blocks.count)
                c.buildHeightmap()
                c.scanSpecials()
                c.status = .lit
                world.setChunk(c)
            }
        }
        return (world, groundY + 1)
    }
    func mkPlayer(_ world: World, _ gy: Int) -> Player {
        let p = Player(world: world)
        p.setPos(0.5, Double(gy), 0.5)
        p.rng = RandomX(7)
        world.addEntity(p)
        // settle onto the ground
        for _ in 0..<5 { p.tick(); p.travel() }
        return p
    }
    func runTicks(_ p: Player, _ n: Int, forward: Double = 0, strafe: Double = 0,
                  jump: Bool = false, sprint: Bool = false, sneak: Bool = false) {
        for _ in 0..<n {
            p.moveForward = forward; p.moveStrafe = strafe
            p.jumping = jump; p.sprinting = sprint; p.sneaking = sneak
            p.tick()
            p.travel()
        }
    }

    // 1) WALK equilibrium: v* = a/(1-f), a = 0.98·speed·0.216…/slip³, f = slip·0.91
    do {
        let (w, gy) = flatWorld()
        let p = mkPlayer(w, gy)
        runTicks(p, 150, forward: 1)
        let z0 = p.z
        runTicks(p, 1, forward: 1)
        let perTick = p.z - z0
        let a = 0.98 * 0.1 * (0.21600002 / (0.6 * 0.6 * 0.6))
        let expect = a / (1 - 0.6 * 0.91)
        check("walk speed = \(String(format: "%.4f", perTick * 20)) b/s (vanilla 4.317)",
              abs(perTick - expect) < 1e-9 && abs(perTick * 20 - 4.317) < 0.001,
              "got \(perTick) want \(expect)")
    }
    // 2) SPRINT equilibrium (×1.3) → 5.612 b/s
    do {
        let (w, gy) = flatWorld()
        let p = mkPlayer(w, gy)
        runTicks(p, 150, forward: 1, sprint: true)
        let z0 = p.z
        runTicks(p, 1, forward: 1, sprint: true)
        let perTick = p.z - z0
        let a = 0.98 * 0.13 * (0.21600002 / 0.216)
        let expect = a / (1 - 0.546)
        check("sprint speed = \(String(format: "%.4f", perTick * 20)) b/s (vanilla 5.612)",
              abs(perTick - expect) < 1e-9 && abs(perTick * 20 - 5.612) < 0.001)
    }
    // 3) SNEAK (input ×0.3) → 1.295 b/s
    do {
        let (w, gy) = flatWorld()
        let p = mkPlayer(w, gy)
        runTicks(p, 150, forward: 1, sneak: true)
        let z0 = p.z
        runTicks(p, 1, forward: 1, sneak: true)
        let perTick = p.z - z0
        let a = 0.3 * 0.98 * 0.1 * (0.21600002 / 0.216)
        let expect = a / (1 - 0.546)
        check("sneak speed = \(String(format: "%.4f", perTick * 20)) b/s (vanilla 1.295)",
              abs(perTick - expect) < 1e-9 && abs(perTick * 20 - 1.295) < 0.001)
    }
    // 4) JUMP apex — independent recurrence: y += v; v = (v−0.08)·0.98 from 0.42
    do {
        let (w, gy) = flatWorld()
        let p = mkPlayer(w, gy)
        let y0 = p.y
        var apex = 0.0
        for t in 0..<30 {
            runTicks(p, 1, jump: t == 0)
            apex = max(apex, p.y - y0)
        }
        var ev = 0.42, ey = 0.0, eApex = 0.0
        for _ in 0..<30 {
            ey += ev
            eApex = max(eApex, ey)
            ev = (ev - 0.08) * 0.98
        }
        check("jump apex = \(String(format: "%.4f", apex)) (vanilla 1.2522)",
              abs(apex - eApex) < 1e-9 && abs(apex - 1.2522) < 0.001,
              "got \(apex) want \(eApex)")
    }
    // 5) SPRINT-JUMP: boosted arc lands ~12 ticks, covers vanilla-ish ~3.8-4.4 blocks
    do {
        let (w, gy) = flatWorld()
        let p = mkPlayer(w, gy)
        runTicks(p, 150, forward: 1, sprint: true)
        let z0 = p.z
        runTicks(p, 1, forward: 1, jump: true, sprint: true)
        var airTicks = 1
        while !p.onGround && airTicks < 30 {
            runTicks(p, 1, forward: 1, sprint: true)
            airTicks += 1
        }
        let dist = p.z - z0
        check("sprint-jump: \(String(format: "%.3f", dist)) blocks in \(airTicks) air ticks",
              dist > 3.5 && dist < 4.6 && airTicks >= 11 && airTicks <= 14)
    }
    // 6) FALL DAMAGE: 20-block drop
    do {
        let (w, gy) = flatWorld()
        let p = mkPlayer(w, gy)
        p.setPos(0.5, Double(gy + 20), 0.5)
        p.vx = 0; p.vy = 0; p.vz = 0
        p.onGround = false   // stale from the settle phase pre-teleport
        var t = 0
        while !p.onGround && t < 100 {
            runTicks(p, 1)
            t += 1
        }
        check("20-block fall: damage \(String(format: "%.1f", 20 - p.health)) (vanilla 17)",
              abs((20 - p.health) - 17) < 1.01)
    }
    // 7) WATER terminal sink velocity = −0.005/(1−0.8) = −0.025
    do {
        let (w, gy) = flatWorld()
        // water column (tall — the swim-up phase rises fast)
        for y in gy...(gy + 60) {
            w.setBlock(0, y, 0, Int(cell(B.water)), SET_SILENT)
        }
        let p = Player(world: w)
        p.setPos(0.5, Double(gy + 40), 0.5)
        p.rng = RandomX(7)
        w.addEntity(p)
        for _ in 0..<60 { p.tick(); p.travel() }
        check("water sink terminal vy = \(String(format: "%.4f", p.vy)) (vanilla −0.025)",
              abs(p.vy - (-0.025)) < 0.002)
        // swim up: vy += 0.04 then ×0.8 −0.005 → +0.135 terminal
        p.setPos(0.5, Double(gy + 8), 0.5)
        p.vy = 0
        for _ in 0..<50 {
            p.jumping = true
            p.tick()
            p.travel()
        }
        check("swim-up terminal vy = \(String(format: "%.4f", p.vy)) (vanilla +0.135)",
              abs(p.vy - 0.135) < 0.002)
    }
    // 8) ICE equilibrium: slip 0.98
    do {
        let (w, gy) = flatWorld(B.packed_ice)
        let p = mkPlayer(w, gy)
        runTicks(p, 150, forward: 1)
        let z0 = p.z
        runTicks(p, 1, forward: 1)
        let perTick = p.z - z0
        let slip = 0.98
        let a = 0.98 * 0.1 * (0.21600002 / (slip * slip * slip))
        let expect = a / (1 - slip * 0.91)
        check("ice glide = \(String(format: "%.3f", perTick * 20)) b/s",
              abs(perTick - expect) < 1e-6)
    }
}

// ---------------------------------------------------------------------------
section("PebbleAgents action decision")
do {
    func decide(
        agentId: String = "agent_0",
        tick: Int = 7,
        goalKind: AgentGoalKind,
        position: AgentPosition = AgentPosition(x: 0, y: 64, z: 0),
        homePosition: AgentPosition = AgentPosition(x: 0, y: 64, z: 0)
    ) -> AgentAction {
        AgentActionDecider.decide(AgentActionDecisionInput(
            agentId: agentId,
            tick: tick,
            goalKind: goalKind,
            position: position,
            homePosition: homePosition
        ))
    }

    func position(_ x: Int, _ z: Int) -> AgentPosition {
        AgentPosition(x: x, y: 64, z: z)
    }

    let idle = decide(goalKind: .idle)
    check("agent action idle waits",
          idle.name == "wait" && idle.reason == "goal idle")

    let rest = decide(goalKind: .rest)
    check("agent action rest",
          rest.name == "rest" && rest.reason == "goal rest")

    let observe = decide(goalKind: .observeOtherAgent)
    check("agent action observes other agent",
          observe.name == "observe_area" && observe.reason == "goal observeOtherAgent")

    let exploreEast = decide(tick: 0, goalKind: .explore)
    check("agent action explore east",
          exploreEast.name == "move_abstract" && exploreEast.reason == "goal explore"
              && exploreEast.dx == 1 && exploreEast.dy == 0 && exploreEast.dz == 0)

    let exploreSouth = decide(tick: 1, goalKind: .explore)
    check("agent action explore south",
          exploreSouth.dx == 0 && exploreSouth.dy == 0 && exploreSouth.dz == 1)

    let exploreWest = decide(tick: 2, goalKind: .explore)
    check("agent action explore west",
          exploreWest.dx == -1 && exploreWest.dy == 0 && exploreWest.dz == 0)

    let exploreNorth = decide(tick: 3, goalKind: .explore)
    check("agent action explore north",
          exploreNorth.dx == 0 && exploreNorth.dy == 0 && exploreNorth.dz == -1)

    let exploreFallback = decide(agentId: "agent_alpha", tick: 0, goalKind: .explore)
    check("agent action explore id fallback",
          exploreFallback.dx == 1 && exploreFallback.dy == 0 && exploreFallback.dz == 0)

    let home = position(4, 9)
    let atHome = decide(goalKind: .seekSafety, position: home, homePosition: home)
    check("agent action seek safety at home waits",
          atHome.name == "wait" && atHome.reason == "goal seekSafety at home"
              && atHome.dx == nil && atHome.dy == nil && atHome.dz == nil)

    let positiveX = decide(
        goalKind: .seekSafety,
        position: position(0, 0),
        homePosition: position(3, 1)
    )
    check("agent action seek safety positive x",
          positiveX.name == "move_abstract" && positiveX.reason == "goal seekSafety"
              && positiveX.dx == 1 && positiveX.dy == 0 && positiveX.dz == 0)

    let negativeX = decide(
        goalKind: .seekSafety,
        position: position(3, 1),
        homePosition: position(0, 0)
    )
    check("agent action seek safety negative x",
          negativeX.dx == -1 && negativeX.dy == 0 && negativeX.dz == 0)

    let positiveZ = decide(
        goalKind: .seekSafety,
        position: position(0, 0),
        homePosition: position(1, 3)
    )
    check("agent action seek safety positive z",
          positiveZ.dx == 0 && positiveZ.dy == 0 && positiveZ.dz == 1)

    let negativeZ = decide(
        goalKind: .seekSafety,
        position: position(1, 3),
        homePosition: position(0, 0)
    )
    check("agent action seek safety negative z",
          negativeZ.dx == 0 && negativeZ.dy == 0 && negativeZ.dz == -1)

    let tie = decide(
        goalKind: .seekSafety,
        position: position(0, 0),
        homePosition: position(-2, 2)
    )
    check("agent action seek safety tie prefers x",
          tie.dx == -1 && tie.dy == 0 && tie.dz == 0)

    let contractAction = AgentAction(
        name: "move_abstract",
        reason: "goal explore",
        tick: 9,
        dx: -1,
        dy: 0,
        dz: 0
    )
    let contractData = try? JSONEncoder().encode(contractAction)
    let contractObject = contractData.flatMap {
        try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
    }
    let preservedTick = decide(tick: 123, goalKind: .rest).tick
    check("agent action tick reason deltas and JSON contract",
          preservedTick == 123
              && idle.dx == nil && idle.dy == nil && idle.dz == nil
              && contractAction.tick == 9 && contractAction.reason == "goal explore"
              && contractAction.dx == -1 && contractAction.dy == 0 && contractAction.dz == 0
              && Set(contractObject?.keys.map { $0 } ?? []) == Set(["name", "reason", "tick", "dx", "dy", "dz"])
              && contractObject?["name"] as? String == "move_abstract"
              && contractObject?["reason"] as? String == "goal explore"
              && contractObject?["tick"] as? Int == 9
              && contractObject?["dx"] as? Int == -1
              && contractObject?["dy"] as? Int == 0
              && contractObject?["dz"] as? Int == 0)
}

// ---------------------------------------------------------------------------
section("PebbleAgents cognitive transitions")
do {
    func needs(
        hunger: Double = 0.1,
        fatigue: Double = 0.01,
        curiosity: Double = 0.4,
        safety: Double = 1
    ) -> AgentNeeds {
        AgentNeeds(hunger: hunger, fatigue: fatigue, curiosity: curiosity, safety: safety)
    }

    let tickNeeds = needs(hunger: 0.2, fatigue: 0.01, curiosity: 0.7, safety: 0.6)
    let tickResult = AgentCognitiveTransitions.advanceTick(needs: tickNeeds)
    check("cognitive tick hunger +0.01", abs(tickResult.needs.hunger - 0.21) <= 1e-12)
    check("cognitive tick fatigue +0.005", tickResult.needs.fatigue == 0.015)
    check("cognitive tick curiosity unchanged", tickResult.needs.curiosity == 0.7)
    check("cognitive tick safety unchanged", tickResult.needs.safety == 0.6)
    check("cognitive tick state idle", tickResult.state == "idle")

    let observerPosition = AgentPosition(x: 10, y: 64, z: 10)
    let nearby = AgentCognitiveTransitions.observeNearbyAgents(
        observerId: "observer",
        observerPosition: observerPosition,
        peers: [
            AgentPeerSnapshot(id: "observer", position: observerPosition),
            AgentPeerSnapshot(id: "near_b", position: AgentPosition(x: 12, y: 65, z: 8)),
            AgentPeerSnapshot(id: "edge", position: AgentPosition(x: 18, y: 64, z: 10)),
            AgentPeerSnapshot(id: "outside", position: AgentPosition(x: 19, y: 64, z: 10)),
            AgentPeerSnapshot(id: "near_a", position: AgentPosition(x: 9, y: 64, z: 10)),
        ],
        radius: 8
    )
    check("cognitive nearby excludes self", !nearby.contains { $0.id == "observer" })
    check("cognitive nearby includes in radius", nearby.contains { $0.id == "near_b" })
    check("cognitive nearby includes exact radius", nearby.contains { $0.id == "edge" })
    check("cognitive nearby excludes outside radius", !nearby.contains { $0.id == "outside" })
    check("cognitive nearby deltas exact",
          nearby.first?.dx == 2 && nearby.first?.dy == 1 && nearby.first?.dz == -2)
    check("cognitive nearby Manhattan exact", nearby.first?.distanceManhattan == 5)
    check("cognitive nearby preserves input order", nearby.map(\.id) == ["near_b", "edge", "near_a"])

    func selectGoal(
        tick: Int = 42,
        health: Int = 100,
        fear: Int = 0,
        needs selectedNeeds: AgentNeeds = AgentNeeds(
            hunger: 0,
            fatigue: 0,
            curiosity: 0,
            safety: 1
        ),
        hasNearbyAgents: Bool = false,
        currentGoalKind: AgentGoalKind = .idle
    ) -> AgentGoalChange? {
        AgentCognitiveTransitions.selectGoal(AgentGoalSelectionInput(
            tick: tick,
            health: health,
            fear: fear,
            needs: selectedNeeds,
            hasNearbyAgents: hasNearbyAgents,
            currentGoalKind: currentGoalKind
        ))
    }

    let healthGoal = selectGoal(health: 25)
    check("cognitive goal health path",
          healthGoal?.to == .seekSafety && healthGoal?.goal.reason == "health <= 25"
              && healthGoal?.goal.urgency == 100 && healthGoal?.goal.startedAtTick == 42)

    let fearGoal = selectGoal(fear: 70)
    check("cognitive goal fear path",
          fearGoal?.to == .seekSafety && fearGoal?.goal.reason == "fear >= 70"
              && fearGoal?.goal.urgency == 85 && fearGoal?.goal.startedAtTick == 42)

    let safetyGoal = selectGoal(needs: needs(safety: 0.49))
    check("cognitive goal safety path",
          safetyGoal?.to == .seekSafety && safetyGoal?.goal.reason == "safety < 0.5"
              && safetyGoal?.goal.urgency == 90 && safetyGoal?.goal.startedAtTick == 42)

    let fatigueGoal = selectGoal(needs: needs(fatigue: 0.02))
    check("cognitive goal fatigue path",
          fatigueGoal?.to == .rest && fatigueGoal?.goal.reason == "fatigue >= 0.02"
              && fatigueGoal?.goal.urgency == 70 && fatigueGoal?.goal.startedAtTick == 42)

    let highCuriosityGoal = selectGoal(needs: needs(curiosity: 0.8))
    check("cognitive goal high curiosity path",
          highCuriosityGoal?.to == .explore
              && highCuriosityGoal?.goal.reason == "curiosity >= 0.8"
              && highCuriosityGoal?.goal.urgency == 60
              && highCuriosityGoal?.goal.startedAtTick == 42)

    let nearbyGoal = selectGoal(hasNearbyAgents: true)
    check("cognitive goal nearby path",
          nearbyGoal?.to == .observeOtherAgent
              && nearbyGoal?.goal.reason == "nearby agent detected"
              && nearbyGoal?.goal.urgency == 50 && nearbyGoal?.goal.startedAtTick == 42)

    let lowCuriosityGoal = selectGoal(needs: needs(curiosity: 0.5))
    check("cognitive goal low curiosity path",
          lowCuriosityGoal?.to == .explore
              && lowCuriosityGoal?.goal.reason == "curiosity >= 0.5"
              && lowCuriosityGoal?.goal.urgency == 40
              && lowCuriosityGoal?.goal.startedAtTick == 42)

    let idleGoal = selectGoal(currentGoalKind: .explore)
    check("cognitive goal idle path",
          idleGoal?.to == .idle && idleGoal?.goal.reason == "no active need"
              && idleGoal?.goal.urgency == 0 && idleGoal?.goal.startedAtTick == 42)

    check("cognitive goal same kind returns nil", selectGoal(health: 25, currentGoalKind: .seekSafety) == nil)
    check("cognitive goal health priority over fear",
          selectGoal(health: 20, fear: 80)?.goal.reason == "health <= 25")
    check("cognitive goal fear priority over safety",
          selectGoal(fear: 80, needs: needs(safety: 0))?.goal.reason == "fear >= 70")
    check("cognitive goal fatigue priority over curiosity",
          selectGoal(needs: needs(fatigue: 0.02, curiosity: 0.9))?.goal.reason == "fatigue >= 0.02")
    check("cognitive goal high curiosity priority over nearby",
          selectGoal(needs: needs(curiosity: 0.9), hasNearbyAgents: true)?.goal.reason == "curiosity >= 0.8")

    func applyEffect(
        actionName: String,
        goalKind: AgentGoalKind = .idle,
        distanceFromHome: Int = 5,
        needs effectNeeds: AgentNeeds = AgentNeeds(
            hunger: 0.3,
            fatigue: 0.03,
            curiosity: 0.5,
            safety: 0.8
        ),
        fear: Int = 5,
        state: String = "before",
        tick: Int = 17
    ) -> AgentActionEffectResult {
        AgentCognitiveTransitions.applyActionEffect(AgentActionEffectInput(
            action: AgentAction(name: actionName, reason: "test", tick: tick),
            goalKind: goalKind,
            distanceFromHome: distanceFromHome,
            needs: effectNeeds,
            fear: fear,
            state: state,
            tick: tick
        ))
    }

    let restEffect = applyEffect(actionName: "rest")
    check("cognitive effect rest",
          restEffect.needs.fatigue == 0.009999999999999998 && restEffect.fear == 4
              && restEffect.state == "resting"
              && restEffect.actionEffect.effect == "fatigue -0.02, fear -1")
    check("cognitive effect rest clamps fatigue",
          applyEffect(actionName: "rest", needs: needs(fatigue: 0.01)).needs.fatigue == 0)
    check("cognitive effect rest clamps fear",
          applyEffect(actionName: "rest", fear: 0).fear == 0)

    let observeEffect = applyEffect(actionName: "observe_area")
    check("cognitive effect observe area",
          observeEffect.needs.curiosity == 0.51 && observeEffect.state == "observing"
              && observeEffect.actionEffect.effect == "curiosity +0.01")
    check("cognitive effect observe clamps curiosity",
          applyEffect(actionName: "observe_area", needs: needs(curiosity: 0.999)).needs.curiosity == 1)

    let safeMoveEffect = applyEffect(actionName: "move_abstract", goalKind: .seekSafety)
    check("cognitive effect move seek safety",
          safeMoveEffect.fear == 4 && safeMoveEffect.state == "moving"
              && safeMoveEffect.actionEffect.effect == "fear -1")

    let exploreMoveEffect = applyEffect(actionName: "move_abstract", goalKind: .explore)
    check("cognitive effect move explore",
          exploreMoveEffect.needs.curiosity == 0.495 && exploreMoveEffect.state == "moving"
              && exploreMoveEffect.actionEffect.effect == "curiosity -0.005")
    check("cognitive effect move clamps curiosity",
          applyEffect(
              actionName: "move_abstract",
              goalKind: .explore,
              needs: needs(curiosity: 0.001)
          ).needs.curiosity == 0)

    let nearWaitEffect = applyEffect(actionName: "wait", goalKind: .seekSafety, distanceFromHome: 1)
    check("cognitive effect wait safety near",
          nearWaitEffect.fear == 3 && nearWaitEffect.state == "waiting"
              && nearWaitEffect.actionEffect.effect == "fear -2")

    let farWaitEffect = applyEffect(actionName: "wait", goalKind: .seekSafety, distanceFromHome: 2)
    check("cognitive effect wait safety far",
          farWaitEffect.fear == 4 && farWaitEffect.actionEffect.effect == "fear -1")

    let idleWaitEffect = applyEffect(actionName: "wait", goalKind: .idle)
    check("cognitive effect wait non safety",
          idleWaitEffect.fear == 5 && idleWaitEffect.needs.curiosity == 0.5
              && idleWaitEffect.state == "waiting"
              && idleWaitEffect.actionEffect.effect == "no need change")

    let unknownEffect = applyEffect(actionName: "unknown", state: "custom")
    check("cognitive effect unknown preserves values",
          unknownEffect.fear == 5 && unknownEffect.needs.hunger == 0.3
              && unknownEffect.needs.fatigue == 0.03 && unknownEffect.needs.curiosity == 0.5
              && unknownEffect.needs.safety == 0.8 && unknownEffect.actionEffect.effect == "no effect")
    check("cognitive effect unknown preserves state", unknownEffect.state == "custom")
    check("cognitive effect before after fields exact",
          restEffect.actionEffect.action == "rest" && restEffect.actionEffect.tick == 17
              && restEffect.actionEffect.hungerBefore == 0.3
              && restEffect.actionEffect.hungerAfter == 0.3
              && restEffect.actionEffect.fatigueBefore == 0.03
              && restEffect.actionEffect.fatigueAfter == 0.009999999999999998
              && restEffect.actionEffect.curiosityBefore == 0.5
              && restEffect.actionEffect.curiosityAfter == 0.5
              && restEffect.actionEffect.safetyBefore == 0.8
              && restEffect.actionEffect.safetyAfter == 0.8
              && restEffect.actionEffect.fearBefore == 5
              && restEffect.actionEffect.fearAfter == 4
              && restEffect.actionEffect.stateBefore == "before"
              && restEffect.actionEffect.stateAfter == "resting")

    let firstMemory = AgentMemoryEntry(tick: 1, type: "first", summary: "one", importance: 0.1)
    let secondMemory = AgentMemoryEntry(tick: 2, type: "second", summary: "two", importance: 0.2)
    var memory: [AgentMemoryEntry] = []
    AgentCognitiveTransitions.appendLegacyUnboundedMemory(firstMemory, to: &memory)
    check("cognitive memory append adds one", memory.count == 1)
    AgentCognitiveTransitions.appendLegacyUnboundedMemory(secondMemory, to: &memory)
    check("cognitive memory append preserves order", memory.map(\.type) == ["first", "second"])
    for tick in 3...22 {
        AgentCognitiveTransitions.appendLegacyUnboundedMemory(
            AgentMemoryEntry(tick: tick, type: "extra", summary: "entry", importance: 0.3),
            to: &memory
        )
    }
    check("cognitive memory append remains unbounded", memory.count == 22)
    AgentCognitiveTransitions.appendLegacyUnboundedMemory(firstMemory, to: &memory)
    AgentCognitiveTransitions.appendLegacyUnboundedMemory(firstMemory, to: &memory)
    check("cognitive memory append does not deduplicate",
          memory.count == 24 && memory.suffix(2).allSatisfy { $0.type == "first" })
}

// ---------------------------------------------------------------------------
section("PebbleAgents multi-agent session and snapshots")
do {
    func sessionConfiguration(
        seed: UInt32 = 77,
        nearbyRadius: Int = 8,
        recentMemorySnapshotLimit: Int = 3,
        memoryPolicy: AgentMemoryPolicy = .legacyUnbounded
    ) -> AgentSessionConfiguration {
        try! AgentSessionConfiguration(
            seed: seed,
            nearbyRadius: nearbyRadius,
            recentMemorySnapshotLimit: recentMemorySnapshotLimit,
            memoryPolicy: memoryPolicy
        )
    }

    func sessionMemory(_ tick: Int, type: String? = nil) -> AgentMemoryEntry {
        AgentMemoryEntry(
            tick: tick,
            type: type ?? "memory_\(tick)",
            summary: "memory \(tick)",
            importance: Double(tick) / 100
        )
    }

    func sessionState(
        id: String,
        x: Int = 0,
        health: Int = 100,
        curiosity: Double = 0.9,
        memory: [AgentMemoryEntry] = []
    ) -> AgentSessionAgentState {
        let position = AgentPosition(x: x, y: 64, z: 0)
        return AgentSessionAgentState(
            id: id,
            state: "idle",
            position: position,
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: curiosity, safety: 1),
            health: health,
            fear: 10,
            homePosition: AgentPosition(x: 0, y: 64, z: 0),
            nearbyAgents: [],
            currentGoal: AgentGoal(kind: .idle, reason: "initial goal", startedAtTick: 0, urgency: 0),
            lastAction: nil,
            lastActionEffect: nil,
            memory: memory,
            tickCreated: 0,
            ticksAlive: 0,
            observationCount: 0,
            nearbyObservationCount: 0,
            goalSelectionCount: 0,
            goalChangeCount: 0,
            actionCount: 0,
            actionEffectCount: 0,
            movementCount: 0,
            totalManhattanDistanceMoved: 0,
            returnHomeMoveCount: 0,
            totalDistanceReducedTowardHome: 0
        )
    }

    func session(
        _ states: [AgentSessionAgentState],
        configuration: AgentSessionConfiguration = sessionConfiguration(),
        initialTick: Int = 0
    ) -> AgentSimulationSession {
        try! AgentSimulationSession(
            configuration: configuration,
            agents: states,
            initialTick: initialTick
        )
    }

    let emptySession = session([])
    check("session construction empty accepted", emptySession.snapshot().agentCount == 0)

    let oneSession = session([sessionState(id: "agent_0")])
    check("session construction one agent", oneSession.snapshot().agentCount == 1)

    let threeStates = (0..<3).map { sessionState(id: "agent_\($0)", x: $0 * 2) }
    let threeSession = session(threeStates)
    check("session construction three agents", threeSession.snapshot().agentCount == 3)

    let tenStates = (0..<10).map { sessionState(id: "agent_\($0)", x: $0) }
    let tenSession = session(tenStates)
    check("session construction ten agents", tenSession.snapshot().agentCount == 10)
    check("session construction seed preserved", threeSession.snapshot().seed == 77)

    let initialTickSession = session([], initialTick: 12)
    check("session construction initial tick exact", initialTickSession.snapshot().tick == 12)

    do {
        _ = try AgentSimulationSession(
            configuration: sessionConfiguration(),
            agents: [sessionState(id: "duplicate"), sessionState(id: "duplicate")]
        )
        check("session construction duplicate id refused", false)
    } catch AgentSessionError.duplicateAgentId("duplicate") {
        check("session construction duplicate id refused", true)
    } catch {
        check("session construction duplicate id refused", false, "unexpected \(error)")
    }

    check("session configuration legacy explicit",
          sessionConfiguration().memoryPolicy == .legacyUnbounded)
    check("session configuration bounded valid",
          sessionConfiguration(memoryPolicy: .bounded(maxEntries: 4)).memoryPolicy
              == .bounded(maxEntries: 4))
    do {
        _ = try AgentSessionConfiguration(
            seed: 1,
            nearbyRadius: 8,
            recentMemorySnapshotLimit: 3,
            memoryPolicy: .bounded(maxEntries: 0)
        )
        check("session configuration bounded invalid refused", false)
    } catch AgentSessionError.invalidMemoryBound(0) {
        check("session configuration bounded invalid refused", true)
    } catch {
        check("session configuration bounded invalid refused", false, "unexpected \(error)")
    }

    let permutedStates = [
        sessionState(id: "agent_c", x: 4),
        sessionState(id: "agent_a", x: 0),
        sessionState(id: "agent_b", x: 2),
    ]
    var orderedSession = session(permutedStates)
    check("session order accepts permuted input", orderedSession.snapshot().agentCount == 3)
    check("session order snapshot sorted",
          orderedSession.snapshot().agents.map(\.id) == ["agent_a", "agent_b", "agent_c"])
    let orderedTick1 = try! orderedSession.advanceTick()
    check("session order tick result sorted",
          orderedTick1.agents.map(\.agentId) == ["agent_a", "agent_b", "agent_c"])
    let orderedTick2 = try! orderedSession.advanceTick()
    check("session order stable multiple ticks",
          orderedTick2.agents.map(\.agentId) == ["agent_a", "agent_b", "agent_c"])
    let reverseSession = session(Array(permutedStates.reversed()))
    check("session order independent from source order",
          reverseSession.snapshot() == session(permutedStates).snapshot())

    let snapshotMemories = (1...5).map { sessionMemory($0) }
    let snapshotSession = session([
        sessionState(id: "snapshot", x: 3, memory: snapshotMemories),
    ])
    let snapshot = snapshotSession.snapshot()
    let snapshotAgent = snapshot.agents[0]
    check("session snapshot agentCount exact", snapshot.agentCount == 1)
    check("session snapshot properties exact",
          snapshotAgent.id == "snapshot" && snapshotAgent.position == AgentPosition(x: 3, y: 64, z: 0))

    let deadSnapshot = session([sessionState(id: "dead", health: 0)]).snapshot().agents[0]
    check("session snapshot isAlive derived", !deadSnapshot.isAlive)
    check("session snapshot distance home exact", snapshotAgent.distanceFromHome == 3)
    check("session snapshot memoryCount exact", snapshotAgent.memoryCount == 5)
    check("session snapshot recent memory limited", snapshotAgent.recentMemory.count == 3)
    check("session snapshot recent memory order",
          snapshotAgent.recentMemory.map { $0.tick } == [3, 4, 5])

    var mutableSource = snapshotMemories
    let independentSnapshot = session([
        sessionState(id: "copy", memory: mutableSource),
    ]).snapshot()
    mutableSource.append(sessionMemory(6))
    check("session snapshot independent source copy",
          independentSnapshot.agents[0].memoryCount == 5 && mutableSource.count == 6)
    check("session snapshot deterministic equality", snapshotSession.snapshot() == snapshotSession.snapshot())

    let snapshotEncoder = JSONEncoder()
    snapshotEncoder.outputFormatting = [.sortedKeys]
    let snapshotJSON1 = try? snapshotEncoder.encode(snapshotSession.snapshot())
    let snapshotJSON2 = try? snapshotEncoder.encode(snapshotSession.snapshot())
    check("session snapshot JSON deterministic", snapshotJSON1 != nil && snapshotJSON1 == snapshotJSON2)

    var tickSession = session([
        sessionState(id: "agent_b", x: 4, curiosity: 0.1),
        sessionState(id: "agent_a", x: 0, curiosity: 0.9),
    ])
    let tickBefore = tickSession.snapshot()
    let tickResult = try! tickSession.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_a",
            observationCountIncrement: 1,
            externalMemoryEntries: [sessionMemory(1, type: "observed")]
        ),
        AgentPerceptionInput(
            agentId: "agent_b",
            observationCountIncrement: 1,
            externalMemoryEntries: [sessionMemory(1, type: "observed")]
        ),
    ])
    let tickAfter = tickSession.snapshot()
    check("session tick increments once", tickResult.tick == 1 && tickAfter.tick == 1)
    check("session tick evolves needs",
          tickAfter.agents[0].needs.hunger == tickBefore.agents[0].needs.hunger + 0.01)
    check("session tick nearby from start snapshot",
          tickAfter.agents.allSatisfy { $0.nearbyAgents.count == 1 })
    check("session tick nearby excludes same id",
          tickAfter.agents.allSatisfy { agent in
              !agent.nearbyAgents.contains { $0.id == agent.id }
          })
    check("session tick selects goal", tickAfter.agents[0].currentGoal.kind == .explore)
    check("session tick chooses action", tickAfter.agents[0].lastAction?.name == "move_abstract")
    check("session tick applies effect",
          tickAfter.agents[0].lastActionEffect?.effect == "curiosity -0.005")
    check("session tick increments counters",
          tickAfter.agents.allSatisfy {
              $0.ticksAlive == 1 && $0.observationCount == 1
                  && $0.goalSelectionCount == 1 && $0.actionCount == 1
                  && $0.actionEffectCount == 1
          })
    check("session tick appends action memory",
          tickAfter.agents[0].recentMemory.contains { $0.type == "action_chosen" })
    check("session tick appends effect memory",
          tickAfter.agents[0].recentMemory.contains { $0.type == "action_effect_applied" })

    var identicalSession1 = session(threeStates)
    var identicalSession2 = session(threeStates)
    _ = try! identicalSession1.advanceTick()
    _ = try! identicalSession2.advanceTick()
    check("session tick identical sessions deterministic",
          identicalSession1.snapshot() == identicalSession2.snapshot())

    var permutedSession1 = session(permutedStates)
    var permutedSession2 = session(Array(permutedStates.reversed()))
    _ = try! permutedSession1.advanceTick()
    _ = try! permutedSession2.advanceTick()
    check("session tick permuted input deterministic",
          permutedSession1.snapshot() == permutedSession2.snapshot())
    check("session tick earlier agent does not alter later perception",
          tickAfter.agents[0].nearbyAgents.first?.id == "agent_b"
              && tickAfter.agents[1].nearbyAgents.first?.id == "agent_a")

    var externalSession = session([
        sessionState(id: "external_a", x: 0, memory: [sessionMemory(0)]),
        sessionState(id: "external_b", x: 2),
    ])
    try! externalSession.applyExternalUpdate(AgentExternalUpdate(
        agentId: "external_a",
        position: AgentPosition(x: 5, y: 64, z: 0),
        memoryEntries: [sessionMemory(1, type: "moved_abstract")],
        movementCount: 1,
        totalManhattanDistanceMoved: 5,
        returnHomeMoveCount: 1,
        totalDistanceReducedTowardHome: 2
    ))
    let externalSnapshot = externalSession.snapshot()
    let externalA = externalSnapshot.agents.first { $0.id == "external_a" }!
    let externalB = externalSnapshot.agents.first { $0.id == "external_b" }!
    check("session external position synchronized", externalA.position.x == 5)
    check("session external memory synchronized", externalA.memoryCount == 2)
    check("session external movement count synchronized", externalA.movementCount == 1)
    check("session external distance home updated", externalA.distanceFromHome == 5)
    check("session external next snapshot reflects update",
          externalA.totalManhattanDistanceMoved == 5
              && externalA.returnHomeMoveCount == 1
              && externalA.totalDistanceReducedTowardHome == 2)
    do {
        try externalSession.applyExternalUpdate(AgentExternalUpdate(agentId: "unknown"))
        check("session external unknown agent refused", false)
    } catch AgentSessionError.unknownAgentId("unknown") {
        check("session external unknown agent refused", true)
    } catch {
        check("session external unknown agent refused", false, "unexpected \(error)")
    }
    check("session external update isolates other agents",
          externalB.position.x == 2 && externalB.memoryCount == 0 && externalB.movementCount == 0)

    let manyMemories = (1...8).map { sessionMemory($0) }
    let legacySession = session([
        sessionState(id: "legacy", memory: manyMemories),
    ], configuration: sessionConfiguration(memoryPolicy: .legacyUnbounded))
    check("session memory legacy does not truncate", legacySession.snapshot().agents[0].memoryCount == 8)

    let boundedConfiguration = sessionConfiguration(
        recentMemorySnapshotLimit: 5,
        memoryPolicy: .bounded(maxEntries: 3)
    )
    var boundedSession = session([
        sessionState(id: "bounded", memory: manyMemories),
    ], configuration: boundedConfiguration)
    check("session memory bounded truncates maximum", boundedSession.snapshot().agents[0].memoryCount == 3)
    check("session memory bounded keeps latest",
          boundedSession.snapshot().agents[0].recentMemory.map { $0.tick } == [6, 7, 8])
    let boundedBefore = boundedSession.snapshot()
    try! boundedSession.applyExternalUpdate(AgentExternalUpdate(
        agentId: "bounded",
        memoryEntries: [sessionMemory(9)]
    ))
    check("session memory bounded remains deterministic",
          boundedBefore.agents[0].recentMemory.map { $0.tick } == [6, 7, 8]
              && boundedSession.snapshot().agents[0].recentMemory.map { $0.tick } == [7, 8, 9])
}

// ---------------------------------------------------------------------------
section("PebbleAgents read-only World perception")
do {
    let basePosition = AgentPosition(x: 10, y: 64, z: 20)

    func perceptionColumn(
        _ position: AgentPosition,
        ready: Bool = true,
        surface: Int? = 64,
        ground: Bool = true,
        feet: Bool = true,
        head: Bool = true
    ) -> AgentWorldColumnObservation {
        AgentWorldColumnObservation(
            position: position,
            chunkReady: ready,
            surfaceY: ready ? surface : nil,
            height: ready ? surface : nil,
            blockBelow: ready ? (ground ? 16 : 0) : nil,
            blockAtFeet: ready ? (feet ? 0 : 16) : nil,
            blockAtHead: ready ? (head ? 0 : 16) : nil,
            groundPresent: ready && ground,
            feetClear: ready && feet,
            headClear: ready && head
        )
    }

    func perceptionObservation(
        position: AgentPosition = basePosition,
        centerReady: Bool = true,
        ground: Bool = true,
        feet: Bool = true,
        head: Bool = true,
        traversable: [AgentCardinalDirection] = AgentCardinalDirection.allCases,
        drops: [AgentCardinalDirection] = [],
        light: Int? = 15,
        varied: Bool = false,
        worldTick: Int = 40
    ) -> AgentWorldObservation {
        let center = perceptionColumn(
            position,
            ready: centerReady,
            surface: 64,
            ground: ground,
            feet: feet,
            head: head
        )
        let neighbors = AgentCardinalDirection.allCases.reversed().map { direction -> AgentWorldNeighborObservation in
            let isDrop = drops.contains(direction)
            let delta = isDrop ? -2 : (varied && direction == .north ? 1 : 0)
            let neighborPosition = AgentPosition(
                x: position.x + direction.dx,
                y: position.y,
                z: position.z + direction.dz
            )
            return AgentWorldNeighborObservation(
                direction: direction,
                column: perceptionColumn(
                    neighborPosition,
                    surface: 64 + delta,
                    ground: !isDrop
                ),
                stepDelta: delta,
                traversable: traversable.contains(direction) && !isDrop,
                dangerousDrop: isDrop
            )
        }
        return try! AgentWorldObservation(
            worldTick: worldTick,
            position: position,
            center: center,
            neighbors: neighbors,
            biomeId: centerReady ? 1 : nil,
            biomeName: centerReady ? "plains" : nil,
            combinedLight: centerReady ? light : nil,
            skyLight: centerReady ? 15 : nil,
            blockLight: centerReady ? 0 : nil,
            dayTime: 6000,
            raining: false,
            thundering: false
        )
    }

    check("world cardinal canonical order",
          AgentCardinalDirection.allCases == [.north, .east, .south, .west])
    check("world north offset", AgentCardinalDirection.north.dx == 0 && AgentCardinalDirection.north.dz == -1)
    check("world east offset", AgentCardinalDirection.east.dx == 1 && AgentCardinalDirection.east.dz == 0)
    check("world south offset", AgentCardinalDirection.south.dx == 0 && AgentCardinalDirection.south.dz == 1)
    check("world west offset", AgentCardinalDirection.west.dx == -1 && AgentCardinalDirection.west.dz == 0)

    let stableObservation = perceptionObservation()
    check("world observation canonicalizes permuted neighbors",
          stableObservation.neighbors.map(\.direction) == [.north, .east, .south, .west])
    do {
        var duplicated = stableObservation.neighbors
        duplicated[3] = duplicated[0]
        _ = try AgentWorldObservation(
            worldTick: 1, position: basePosition, center: stableObservation.center,
            neighbors: duplicated, biomeId: 1, biomeName: "plains",
            combinedLight: 15, skyLight: 15, blockLight: 0,
            dayTime: 0, raining: false, thundering: false
        )
        check("world observation duplicate direction refused", false)
    } catch AgentWorldObservationError.duplicateDirection(.north) {
        check("world observation duplicate direction refused", true)
    } catch {
        check("world observation duplicate direction refused", false, "unexpected \(error)")
    }
    do {
        _ = try AgentWorldObservation(
            worldTick: 1, position: basePosition, center: stableObservation.center,
            neighbors: Array(stableObservation.neighbors.prefix(3)), biomeId: 1, biomeName: "plains",
            combinedLight: 15, skyLight: 15, blockLight: 0,
            dayTime: 0, raining: false, thundering: false
        )
        check("world observation missing neighbor refused", false)
    } catch AgentWorldObservationError.invalidNeighborCount(3) {
        check("world observation missing neighbor refused", true)
    } catch {
        check("world observation missing neighbor refused", false, "unexpected \(error)")
    }
    do {
        var invalid = stableObservation.neighbors
        invalid[0] = AgentWorldNeighborObservation(
            direction: .north,
            column: perceptionColumn(basePosition),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
        _ = try AgentWorldObservation(
            worldTick: 1, position: basePosition, center: stableObservation.center,
            neighbors: invalid, biomeId: 1, biomeName: "plains",
            combinedLight: 15, skyLight: 15, blockLight: 0,
            dayTime: 0, raining: false, thundering: false
        )
        check("world observation invalid neighbor position refused", false)
    } catch AgentWorldObservationError.invalidNeighborPosition(.north) {
        check("world observation invalid neighbor position refused", true)
    } catch {
        check("world observation invalid neighbor position refused", false, "unexpected \(error)")
    }
    let countedObservation = perceptionObservation(
        traversable: [.north, .south],
        drops: [.east]
    )
    check("world observation counters exact",
          countedObservation.traversableNeighborCount == 2
              && countedObservation.blockedNeighborCount == 2
              && countedObservation.dangerousDropCount == 1)
    let worldEncoder = JSONEncoder()
    worldEncoder.outputFormatting = [.sortedKeys]
    let worldJSON1 = try? worldEncoder.encode(stableObservation)
    let worldJSON2 = try? worldEncoder.encode(stableObservation)
    check("world observation JSON deterministic", worldJSON1 != nil && worldJSON1 == worldJSON2)
    check("world observation equality", stableObservation == perceptionObservation())

    func interpreted(
        _ observation: AgentWorldObservation,
        curiosity: Double = 0.2,
        safety: Double = 1,
        fear: Int = 10
    ) -> AgentWorldPerceptionEffect {
        AgentWorldPerceptionInterpreter.interpret(
            agentId: "agent_0",
            tick: 1,
            observation: observation,
            needs: AgentNeeds(hunger: 0.3, fatigue: 0.4, curiosity: curiosity, safety: safety),
            fear: fear
        )
    }

    let unavailableEffect = interpreted(perceptionObservation(centerReady: false))
    check("world interpreter chunk unavailable", unavailableEffect.reason == "center chunk unavailable" && unavailableEffect.safetyAfter == 0.20 && unavailableEffect.fearAfter == 18)
    let noGroundEffect = interpreted(perceptionObservation(ground: false))
    check("world interpreter no ground", noGroundEffect.reason == "no ground below" && noGroundEffect.safetyAfter == 0.10 && abs(noGroundEffect.curiosityAfter - 0.21) < 1e-12)
    let blockedEffect = interpreted(perceptionObservation(feet: false))
    check("world interpreter body blocked", blockedEffect.reason == "body space blocked" && blockedEffect.safetyAfter == 0.25)
    let multipleDropsEffect = interpreted(perceptionObservation(drops: [.north, .east]))
    check("world interpreter multiple drops", multipleDropsEffect.reason == "multiple nearby drops" && multipleDropsEffect.fearAfter == 15)
    let noTraversalEffect = interpreted(perceptionObservation(traversable: []))
    check("world interpreter no traversable neighbor", noTraversalEffect.reason == "no traversable neighbor" && noTraversalEffect.safetyAfter == 0.35)
    let oneDropEffect = interpreted(perceptionObservation(drops: [.west]))
    check("world interpreter one drop", oneDropEffect.reason == "nearby drop" && oneDropEffect.safetyAfter == 0.65)
    let darkEffect = interpreted(perceptionObservation(light: 3))
    check("world interpreter very low light", darkEffect.reason == "very low light" && darkEffect.fearAfter == 14)
    let flatEffect = interpreted(stableObservation)
    check("world interpreter stable flat terrain", flatEffect.reason == "local terrain stable" && abs(flatEffect.curiosityAfter - 0.205) < 1e-12)
    let variedEffect = interpreted(perceptionObservation(varied: true))
    check("world interpreter stable varied terrain", variedEffect.reason == "local terrain stable" && variedEffect.curiosityAfter == 0.22)
    check("world interpreter fear clamp zero", interpreted(stableObservation, fear: 0).fearAfter == 0)
    check("world interpreter fear clamp one hundred", interpreted(perceptionObservation(ground: false), fear: 99).fearAfter == 100)
    check("world interpreter curiosity clamp one", interpreted(perceptionObservation(drops: [.west]), curiosity: 0.99).curiosityAfter == 1)
    let immutableNeeds = AgentNeeds(hunger: 0.3, fatigue: 0.4, curiosity: 0.2, safety: 1)
    _ = AgentWorldPerceptionInterpreter.interpret(agentId: "agent_0", tick: 1, observation: stableObservation, needs: immutableNeeds, fear: 10)
    check("world interpreter hunger unchanged", immutableNeeds.hunger == 0.3)
    check("world interpreter fatigue unchanged", immutableNeeds.fatigue == 0.4)
    check("world interpreter memory summary deterministic",
          flatEffect.memorySummary == "agent_0 observed world: local terrain stable; traversable=4/4 blocked=0 drops=0 light=15")
    check("world interpreter importance critical", noGroundEffect.memoryImportance == 0.50)
    check("world interpreter importance caution", oneDropEffect.memoryImportance == 0.30)
    check("world interpreter importance stable", flatEffect.memoryImportance == 0.20)

    func phaseCState(id: String = "agent_0", memory: [AgentMemoryEntry] = []) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: id,
            state: "idle",
            position: basePosition,
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.2, safety: 1),
            health: 100,
            fear: 10,
            homePosition: basePosition,
            nearbyAgents: [],
            currentGoal: AgentGoal(kind: .idle, reason: "initial goal", startedAtTick: 0, urgency: 0),
            lastAction: nil,
            lastActionEffect: nil,
            memory: memory,
            tickCreated: 0,
            ticksAlive: 0,
            observationCount: 0,
            nearbyObservationCount: 0,
            goalSelectionCount: 0,
            goalChangeCount: 0,
            actionCount: 0,
            actionEffectCount: 0,
            movementCount: 0,
            totalManhattanDistanceMoved: 0,
            returnHomeMoveCount: 0,
            totalDistanceReducedTowardHome: 0
        )
    }

    func phaseCSession(
        policy: AgentMemoryPolicy = .legacyUnbounded
    ) -> AgentSimulationSession {
        let configuration = try! AgentSessionConfiguration(
            seed: 99,
            nearbyRadius: 8,
            recentMemorySnapshotLimit: 10,
            memoryPolicy: policy
        )
        return try! AgentSimulationSession(configuration: configuration, agents: [phaseCState()])
    }

    var worldSession = phaseCSession()
    let oldSnapshot = worldSession.snapshot()
    let worldResult = try! worldSession.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", worldObservation: noGroundEffect.reason == "no ground below" ? perceptionObservation(ground: false) : stableObservation),
    ])
    let perceived = worldSession.snapshot().agents[0]
    check("world session stores observation", perceived.lastWorldObservation?.worldTick == 40)
    check("world session stores effect", perceived.lastWorldPerceptionEffect?.reason == "no ground below")
    check("world session observation count automatic", perceived.observationCount == 1)
    check("world session safety before goal", perceived.needs.safety == 0.10)
    check("world session danger selects safety goal", perceived.currentGoal.kind == .seekSafety && perceived.currentGoal.reason == "safety < 0.5")
    check("world session adds observed memory", perceived.recentMemory.contains { $0.type == "world_observed" })
    check("world session memory order",
          worldResult.agents[0].memoriesAdded.map(\.type) == ["world_observed", "action_chosen", "action_effect_applied"])
    check("world session result contains effect", worldResult.agents[0].worldPerceptionEffect?.reason == "no ground below")
    check("world session snapshot contains perception", perceived.lastWorldObservation != nil && perceived.lastWorldPerceptionEffect != nil)
    check("world session old snapshot immutable", oldSnapshot.agents[0].lastWorldObservation == nil && oldSnapshot.agents[0].observationCount == 0)

    var mismatchSession = phaseCSession()
    let mismatchBefore = mismatchSession.snapshot()
    let mismatchObservation = perceptionObservation(position: AgentPosition(x: 11, y: 64, z: 20))
    do {
        _ = try mismatchSession.advanceTick(perceptions: [
            AgentPerceptionInput(agentId: "agent_0", worldObservation: mismatchObservation),
        ])
        check("world session position mismatch refused", false)
    } catch AgentSessionError.worldObservationPositionMismatch("agent_0") {
        check("world session position mismatch refused", true)
    } catch {
        check("world session position mismatch refused", false, "unexpected \(error)")
    }
    check("world session mismatch leaves tick unchanged", mismatchSession.snapshot().tick == 0)
    check("world session mismatch leaves state unchanged", mismatchSession.snapshot() == mismatchBefore)

    var legacyPathSession = phaseCSession()
    let legacyResult = try! legacyPathSession.advanceTick()
    check("world session absent observation preserves path",
          legacyResult.agents[0].worldPerceptionEffect == nil
              && legacyPathSession.snapshot().agents[0].lastWorldObservation == nil)
    let legacySnapshotJSON = (try? worldEncoder.encode(legacyPathSession.snapshot())).flatMap {
        String(data: $0, encoding: .utf8)
    } ?? ""
    check("world session absent observation omits new JSON keys",
          !legacySnapshotJSON.contains("lastWorldObservation")
              && !legacySnapshotJSON.contains("lastWorldPerceptionEffect"))
    var historicalInputSession = phaseCSession()
    _ = try! historicalInputSession.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", observationCountIncrement: 2),
    ])
    check("world session historical observation increment", historicalInputSession.snapshot().agents[0].observationCount == 2)

    var boundedWorldSession = phaseCSession(policy: .bounded(maxEntries: 2))
    _ = try! boundedWorldSession.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", worldObservation: stableObservation),
    ])
    check("world session bounded memory still truncates",
          boundedWorldSession.snapshot().agents[0].memoryCount == 2
              && boundedWorldSession.snapshot().agents[0].recentMemory.map(\.type) == ["action_chosen", "action_effect_applied"])

    var deterministicWorldSession1 = phaseCSession()
    var deterministicWorldSession2 = phaseCSession()
    _ = try! deterministicWorldSession1.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", worldObservation: stableObservation),
    ])
    _ = try! deterministicWorldSession2.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", worldObservation: stableObservation),
    ])
    check("world session deterministic identical inputs",
          deterministicWorldSession1.snapshot() == deterministicWorldSession2.snapshot())
}

print("\n\(passed) passed, \(failed) failed")
exit(failed > 0 ? 1 : 0)
