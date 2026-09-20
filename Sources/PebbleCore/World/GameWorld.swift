// The World — Chunk map, block access with
// light/remesh propagation, scheduled + random ticks, block entities, entity
// lists, raycasting, weather and time. Handler registries are module-global
// dictionaries filled by the systems layer at init, deterministically.

import Foundation

/// structural view of an entity — the real Entity class satisfies this
public protocol EntityRef: AnyObject {
    var id: Int { get }
    var x: Double { get }
    var y: Double { get }
    var z: Double { get }
    var dead: Bool { get }
    func bb() -> AABB
}

public let SET_SILENT = 0           // worldgen: no updates at all
public let SET_DEFAULT = 1 | 2 | 4  // neighbors + light + remesh
public let SET_NO_NEIGHBORS = 2 | 4

public typealias BlockTickFn = (World, Int, Int, Int, Int) -> Void
public typealias NeighborFn = (World, Int, Int, Int, Int, Int, Int, Int) -> Void
public typealias BETickFn = (World, BlockEntityData) -> Void

// shared handler registries (filled by systems at module init)
public var blockTickHandlers: [Int: BlockTickFn] = [:]
public var randomTickHandlers: [Int: BlockTickFn] = [:]
public var neighborHandlers: [Int: NeighborFn] = [:]
public var beTickHandlers: [String: BETickFn] = [:]
public var onPlacedHandlers: [Int: BlockTickFn] = [:]

public struct ScheduledTick {
    var time: Int
    var x: Int, y: Int, z: Int
    var id: Int
    var priority: Int
    var order: Int
}

public struct RaycastHit {
    public let x: Int, y: Int, z: Int
    public let face: Int          // Dir
    public let cell: Int
    public let t: Double
    public let px: Double, py: Double, pz: Double

    public init(x: Int, y: Int, z: Int, face: Int, cell: Int, t: Double, px: Double, py: Double, pz: Double) {
        self.x = x; self.y = y; self.z = z
        self.face = face; self.cell = cell; self.t = t
        self.px = px; self.py = py; self.pz = pz
    }
}

public struct WorldHooks {
    public var onSectionDirty: (Int, Int, Int) -> Void = { _, _, _ in }
    public var playSound: (String, Double, Double, Double, Double, Double) -> Void = { _, _, _, _, _, _ in }
    public var addParticles: (String, Double, Double, Double, Int, Double, Int) -> Void = { _, _, _, _, _, _, _ in }
    public var onVibration: ((Double, Double, Double, Int, EntityRef?) -> Void)?
    public var requestChunk: ((Int, Int) -> Void)?

    public init() {}
}

public let DAY_LENGTH = 24000

private var tickOrderCounter = 0

/// position key for transient redstone state on doors/trapdoors/gates
public struct OpenablePos: Hashable {
    public let x: Int, y: Int, z: Int
    public init(_ x: Int, _ y: Int, _ z: Int) { self.x = x; self.y = y; self.z = z }
}

private struct TickKey: Hashable {
    let x: Int, y: Int, z: Int, id: Int
}

public final class World {
    public let dim: Dim
    public let seed: UInt32
    public let signInscriptionIdentityCatalog: SignInscriptionIdentityCatalog?
    public var chunks: [Int64: Chunk] = [:]
    public var entities: [EntityRef] = []
    public var entityById: [Int: EntityRef] = [:]
    public let info: DimInfo
    public var time = 0            // total ticks elapsed (world age)
    public var dayTime = 1000      // 0..23999
    public var raining = false
    public var thundering = false
    public var rainLevel = 0.0
    public var thunderLevel = 0.0
    public var weatherTimer = 12000
    public var rng: RandomX
    public var spawnX = 0.0, spawnY = 80.0, spawnZ = 0.0
    public private(set) var light: LightEngine!
    public var difficulty = 2
    public var hooks = WorldHooks()
    private var tickQueue: [ScheduledTick] = []
    private var scheduledSet = Set<TickKey>()
    /// block entities needing per-tick updates — insertion-ordered array like
    /// the golden baselines an insertion-ordered map (a Dictionary ticked hoppers/furnaces in
    /// hash-seeded order, different every run); the Set is the dedupe index
    public var tickingBE = Set<ObjectIdentifier>()
    public var tickingBEList: [BlockEntityData] = []
    func trackTickingBE(_ be: BlockEntityData) {
        if tickingBE.insert(ObjectIdentifier(be)).inserted { tickingBEList.append(be) }
    }
    func untrackTickingBE(_ be: BlockEntityData) {
        if tickingBE.remove(ObjectIdentifier(be)) != nil { tickingBEList.removeAll { $0 === be } }
    }
    /// openables (doors/trapdoors/gates) that were powered on their last
    /// neighbor update — lets redstone handlers act on power TRANSITIONS only,
    /// so a manual open isn't slammed shut by the next unrelated update.
    /// transient: after a reload the first power-on re-fires as a transition.
    public var poweredOpenables = Set<OpenablePos>()
    public var simCenterX = 0, simCenterZ = 0
    public var simDistance = 6
    public var randomTickSpeed = 3
    public private(set) var physicalSimulationCoverage =
        PhysicalSimulationCoverageSnapshot.inactive
    private var physicalSimulationCoverageGenerationRequests = 0
    public var gameRules: [String: Double] = [
        "doDaylightCycle": 1, "doWeatherCycle": 1, "doMobSpawning": 1, "doFireTick": 1,
        "mobGriefing": 1, "keepInventory": 0, "doMobLoot": 1, "doTileDrops": 1,
        "naturalRegeneration": 1, "fallDamage": 1, "drowningDamage": 1, "fireDamage": 1,
    ]

    public init(
        dim: Dim,
        seed: UInt32,
        signInscriptionIdentityCatalog: SignInscriptionIdentityCatalog? = nil
    ) {
        self.dim = dim
        self.seed = seed
        self.signInscriptionIdentityCatalog = signInscriptionIdentityCatalog
        info = DIMS[dim.rawValue]
        rng = RandomX(UInt32(bitPattern: Int32(bitPattern: seed) ^ Int32(dim.rawValue * 7919)))
        light = LightEngine(self)
        signInscriptionIdentityCatalog?.register(self)
    }

    @inline(__always) public func rule(_ name: String) -> Bool { (gameRules[name] ?? 0) != 0 }

    /// Installs derived scheduling state for this tick. The request is
    /// revalidated against current chunk readiness every time and is never
    /// serialized with World or Civilization state.
    public func applyPhysicalSimulationCoverage(
        _ request: PhysicalSimulationCoverageRequest,
        refusedChunks: Set<PhysicalSimulationChunk> = [],
        generationRequestsThisTick: Int = 0
    ) {
        if case .inactive = request {
            physicalSimulationCoverageGenerationRequests = 0
        } else {
            physicalSimulationCoverageGenerationRequests +=
                max(0, generationRequestsThisTick)
        }
        physicalSimulationCoverage =
            PhysicalSimulationCoveragePlanner.makeSnapshot(
                request: request,
                isChunkReady: { [weak self] cx, cz in
                    self?.isChunkReady(cx, cz) == true
                },
                refusedChunks: refusedChunks,
                generationRequestsThisTick: max(0, generationRequestsThisTick),
                cumulativeGenerationRequests:
                    physicalSimulationCoverageGenerationRequests
            )
        if physicalSimulationCoverage.status == .refused,
           physicalSimulationCoverage.roots.isEmpty {
            physicalSimulationCoverageGenerationRequests = 0
        }
    }

    public func hasAgentSimulationCoverage(
        chunkX: Int,
        chunkZ: Int
    ) -> Bool {
        physicalSimulationCoverage.covers(
            chunkX: chunkX,
            chunkZ: chunkZ
        )
    }

    public func hasReadyAgentSimulationCoverage(
        chunkX: Int,
        chunkZ: Int
    ) -> Bool {
        hasAgentSimulationCoverage(chunkX: chunkX, chunkZ: chunkZ)
            && isChunkReady(chunkX, chunkZ)
    }

    // MARK: - chunk access
    public func getChunk(_ cx: Int, _ cz: Int) -> Chunk? {
        chunks[chunkKey(cx, cz)]
    }
    public func getChunkAt(_ x: Int, _ z: Int) -> Chunk? {
        chunks[chunkKey(floorDiv(x, CHUNK_W), floorDiv(z, CHUNK_W))]
    }
    public func setChunk(_ c: Chunk) {
        chunks[chunkKey(c.cx, c.cz)] = c
    }
    public func removeChunk(_ cx: Int, _ cz: Int) {
        chunks.removeValue(forKey: chunkKey(cx, cz))
    }
    public func isChunkReady(_ cx: Int, _ cz: Int) -> Bool {
        guard let c = getChunk(cx, cz) else { return false }
        return c.status != .empty
    }
    public func neighborsReady(_ cx: Int, _ cz: Int) -> Bool {
        for dz in -1...1 {
            for dx in -1...1 where !isChunkReady(cx + dx, cz + dz) { return false }
        }
        return true
    }

    // MARK: - block access
    public func getBlock(_ x: Int, _ y: Int, _ z: Int) -> Int {
        guard let c = chunks[chunkKey(floorDiv(x, CHUNK_W), floorDiv(z, CHUNK_W))] else { return 0 }
        return Int(c.get(posMod(x, CHUNK_W), y, posMod(z, CHUNK_W)))
    }
    public func getBlockId(_ x: Int, _ y: Int, _ z: Int) -> Int {
        getBlock(x, y, z) >> 4
    }
    public func getMeta(_ x: Int, _ y: Int, _ z: Int) -> Int {
        getBlock(x, y, z) & 15
    }
    public func isLoadedAt(_ x: Int, _ z: Int) -> Bool {
        getChunkAt(x, z) != nil
    }

    @discardableResult
    public func setBlock(_ x: Int, _ y: Int, _ z: Int, _ cellV: Int, _ flags: Int = SET_DEFAULT) -> Int {
        let cx = floorDiv(x, CHUNK_W), cz = floorDiv(z, CHUNK_W)
        guard let c = chunks[chunkKey(cx, cz)], c.inYRange(y) else { return 0 }
        let lx = posMod(x, CHUNK_W), lz = posMod(z, CHUNK_W)
        let old = Int(c.get(lx, y, lz))
        if old == cellV { return old }
        c.set(lx, y, lz, UInt16(cellV))
        c.modified = true
        c.trackSpecial(lx, y, lz, UInt16(cellV >> 4))

        let oldId = old >> 4, newId = cellV >> 4
        if oldId != newId && (blockDefs[oldId].shape != blockDefs[newId].shape || !blockDefs[newId].solid) {
            // block entity invalidation when the block type changes
            if let be = c.getBlockEntity(lx, y, lz) {
                untrackTickingBE(be)
                c.removeBlockEntity(lx, y, lz)
            }
        }

        // heightmap
        let hPrev = c.heightAt(lx, lz)
        if y >= hPrev || OPAQUE[newId] == 1 || LIGHT_OPACITY[newId] > 0 { c.updateHeight(lx, lz) }

        if flags & 2 != 0 { light.onBlockChanged(x, y, z, old, cellV) }

        if flags & 4 != 0 {
            c.markDirtyAt(y)
            hooks.onSectionDirty(cx, cz, (y - info.minY) >> 4)
            // border remesh
            let sy = (y - info.minY) & 15
            if lx == 0 { dirtyNeighbor(cx - 1, cz, y) }
            if lx == 15 { dirtyNeighbor(cx + 1, cz, y) }
            if lz == 0 { dirtyNeighbor(cx, cz - 1, y) }
            if lz == 15 { dirtyNeighbor(cx, cz + 1, y) }
            if sy == 0 { hooks.onSectionDirty(cx, cz, (y - 1 - info.minY) >> 4) }
            if sy == 15 { hooks.onSectionDirty(cx, cz, (y + 1 - info.minY) >> 4) }
        }

        if flags & 1 != 0 {
            updateNeighbors(x, y, z)
            notifyBlock(x, y, z, x, y, z) // self update (rails, wire reshape)
        }
        return old
    }
    private func dirtyNeighbor(_ cx: Int, _ cz: Int, _ y: Int) {
        if let n = getChunk(cx, cz) {
            n.markDirtyAt(y)
            hooks.onSectionDirty(cx, cz, (y - info.minY) >> 4)
        }
    }

    /// notify the 6 neighbors that (x,y,z) changed
    public func updateNeighbors(_ x: Int, _ y: Int, _ z: Int) {
        notifyBlock(x - 1, y, z, x, y, z)
        notifyBlock(x + 1, y, z, x, y, z)
        notifyBlock(x, y - 1, z, x, y, z)
        notifyBlock(x, y + 1, z, x, y, z)
        notifyBlock(x, y, z - 1, x, y, z)
        notifyBlock(x, y, z + 1, x, y, z)
    }
    public func notifyBlock(_ x: Int, _ y: Int, _ z: Int, _ fromX: Int, _ fromY: Int, _ fromZ: Int) {
        let cell = getBlock(x, y, z)
        if let h = neighborHandlers[cell >> 4] {
            h(self, x, y, z, cell, fromX, fromY, fromZ)
        }
        // gravity blocks fall when support vanishes
        if HAS_GRAVITY[cell >> 4] == 1 && fromY == y - 1 {
            scheduleTick(x, y, z, cell >> 4, 2)
        }
    }

    public func breakBlockNaturally(_ x: Int, _ y: Int, _ z: Int) {
        // used by pistons/explosions for Destroy-behavior blocks
        let cell = getBlock(x, y, z)
        if cell == 0 { return }
        setBlock(x, y, z, 0)
        hooks.addParticles("block", Double(x) + 0.5, Double(y) + 0.5, Double(z) + 0.5, 12, 0.4, cell)
    }

    // MARK: - scheduled ticks
    public func scheduleTick(_ x: Int, _ y: Int, _ z: Int, _ id: Int, _ delay: Int, _ priority: Int = 0) {
        let key = TickKey(x: x, y: y, z: z, id: id)
        if scheduledSet.contains(key) { return }
        scheduledSet.insert(key)
        let t = ScheduledTick(time: time + delay, x: x, y: y, z: z, id: id, priority: priority, order: tickOrderCounter)
        tickOrderCounter += 1
        // sift up in place — a local copy forced a full CoW clone per insert
        tickQueue.append(t)
        var i = tickQueue.count - 1
        while i > 0 {
            let p = (i - 1) >> 1
            if compareTicks(tickQueue[p], tickQueue[i]) <= 0 { break }
            tickQueue.swapAt(p, i)
            i = p
        }
    }
    public func hasScheduledTick(_ x: Int, _ y: Int, _ z: Int, _ id: Int) -> Bool {
        scheduledSet.contains(TickKey(x: x, y: y, z: z, id: id))
    }
    private func popDueTicks(_ out: inout [ScheduledTick]) {
        while !tickQueue.isEmpty && tickQueue[0].time <= time {
            let top = tickQueue[0]
            let last = tickQueue.removeLast()
            if !tickQueue.isEmpty {
                tickQueue[0] = last
                var i = 0
                while true {
                    let l = 2 * i + 1, r = l + 1
                    var m = i
                    if l < tickQueue.count && compareTicks(tickQueue[l], tickQueue[m]) < 0 { m = l }
                    if r < tickQueue.count && compareTicks(tickQueue[r], tickQueue[m]) < 0 { m = r }
                    if m == i { break }
                    tickQueue.swapAt(m, i)
                    i = m
                }
            }
            scheduledSet.remove(TickKey(x: top.x, y: top.y, z: top.z, id: top.id))
            out.append(top)
        }
    }

    private var dueScratch: [ScheduledTick] = []

    @inline(__always)
    private func physicalSimulationSeed(
        operationDomain: UInt32,
        x: Int,
        y: Int,
        z: Int,
        ordinal: Int = 0
    ) -> UInt32 {
        let dimensionSalt = UInt32(truncatingIfNeeded: dim.rawValue) &* 0x9e37_79b9
        let timeSalt = UInt32(truncatingIfNeeded: time) &* 0x85eb_ca6b
        let ordinalSalt = UInt32(truncatingIfNeeded: ordinal) &* 0xc2b2_ae35
        var mixed = mix32(seed ^ 0x51a7_e001)
        mixed = mix32(mixed ^ dimensionSalt)
        mixed = mix32(mixed ^ timeSalt)
        mixed = mix32(mixed ^ operationDomain)
        mixed = mix32(mixed ^ ordinalSalt)
        return hash3(mixed, x, y, z, 0x0c0e_3a01)
    }

    /// Covered work receives a deterministic World-owned substream keyed by
    /// its physical target and World tick. Camera-only work can therefore use
    /// the legacy global streams without advancing the stream seen by a
    /// covered target. The previous streams are restored even when a handler
    /// schedules or spawns more physical work.
    func withPhysicalSimulationRandomness(
        operationDomain: UInt32,
        x: Int,
        y: Int,
        z: Int,
        ordinal: Int = 0,
        _ body: () -> Void
    ) {
        let previousGameRNG = gameRng
        let previousFarmingRNG = farmingRng
        let scoped = physicalSimulationSeed(
            operationDomain: operationDomain,
            x: x,
            y: y,
            z: z,
            ordinal: ordinal
        )
        gameRng = RandomX(scoped ^ 0x6a57_4f31)
        farmingRng = RandomX(scoped ^ 0x0000_fa01)
        defer {
            gameRng = previousGameRNG
            farmingRng = previousFarmingRNG
        }
        body()
    }

    /// Direct physical actions use a target- and attempt-keyed World-owned
    /// substream. This keeps their drop and ItemEntity randomness independent
    /// of camera/render activity while preserving the legacy global streams
    /// before and after the action.
    public func withDirectPhysicalActionRandomness<T>(
        operationDomain: UInt32,
        x: Int,
        y: Int,
        z: Int,
        stableAttemptID: String,
        _ body: () -> T
    ) -> T {
        var identity: UInt32 = 2_166_136_261
        for byte in stableAttemptID.utf8 {
            identity ^= UInt32(byte)
            identity &*= 16_777_619
        }
        let previousGameRNG = gameRng
        let scoped = physicalSimulationSeed(
            operationDomain: operationDomain,
            x: x,
            y: y,
            z: z,
            ordinal: Int(identity)
        )
        gameRng = RandomX(scoped ^ identity ^ 0x6a57_4f31)
        defer {
            gameRng = previousGameRNG
        }
        return body()
    }

    public func tick() {
        time += 1
        if rule("doDaylightCycle") && info.hasSky {
            dayTime = (dayTime + 1) % DAY_LENGTH
        }
        tickWeather()

        // scheduled block ticks — fluids run under a per-tick budget; a save
        // full of worldgen water can otherwise dump thousands of flow ticks
        // (each with a 4-deep drop-seek) into a single tick and melt the frame
        dueScratch.removeAll(keepingCapacity: true)
        popDueTicks(&dueScratch)
        let fluidA = Int(B.water), fluidB = Int(B.lava)
        var fluidBudget = 512
        func runScheduledTick(_ t: ScheduledTick) {
            if t.id == fluidA || t.id == fluidB {
                if fluidBudget <= 0 {
                    scheduleTick(t.x, t.y, t.z, t.id, 1)
                    return
                }
                fluidBudget -= 1
            }
            let cell = getBlock(t.x, t.y, t.z)
            if (cell >> 4) != t.id { return }
            if let h = blockTickHandlers[t.id] {
                h(self, t.x, t.y, t.z, cell)
            }
        }
        for tick in dueScratch {
            let covered = hasAgentSimulationCoverage(
                chunkX: floorDiv(tick.x, CHUNK_W),
                chunkZ: floorDiv(tick.z, CHUNK_W)
            )
            if covered {
                guard physicalSimulationCoverage.isReady,
                      isChunkReady(
                        floorDiv(tick.x, CHUNK_W),
                        floorDiv(tick.z, CHUNK_W)
                      ) else {
                    // Required coverage is explicit and pending; do not consume
                    // a due physical opportunity as an absent block.
                    scheduleTick(
                        tick.x, tick.y, tick.z, tick.id, 1, tick.priority
                    )
                    continue
                }
                withPhysicalSimulationRandomness(
                    operationDomain: 0x5c4e_d001,
                    x: tick.x,
                    y: tick.y,
                    z: tick.z,
                    ordinal: tick.id
                ) {
                    runScheduledTick(tick)
                }
            } else {
                runScheduledTick(tick)
            }
        }

        // random ticks in sim-range chunks
        if randomTickSpeed > 0 {
            let sd = simDistance
            if physicalSimulationCoverage.isRequested {
                // Covered chunks are one deterministic set, independent of
                // root enumeration and observer position.
                if physicalSimulationCoverage.isReady {
                    for position in physicalSimulationCoverage.coveredChunks {
                        guard let c = getChunk(position.x, position.z),
                              c.status != .empty else { continue }
                        for section in 0..<c.sections {
                            var coordinateRNG = RandomX(physicalSimulationSeed(
                                operationDomain: 0x7a11_c001,
                                x: c.cx,
                                y: section,
                                z: c.cz
                            ))
                            for sample in 0..<randomTickSpeed {
                                let rx = coordinateRNG.nextInt(CHUNK_W)
                                let rz = coordinateRNG.nextInt(CHUNK_W)
                                let ry = info.minY + section * CHUNK_W
                                    + coordinateRNG.nextInt(CHUNK_W)
                                let cell = Int(c.get(rx, ry, rz))
                                let id = cell >> 4
                                if id != 0 && RANDOM_TICKS[id] == 1,
                                   let handler = randomTickHandlers[id] {
                                    let worldX = c.cx * CHUNK_W + rx
                                    let worldZ = c.cz * CHUNK_W + rz
                                    withPhysicalSimulationRandomness(
                                        operationDomain: 0x7a11_d001,
                                        x: worldX,
                                        y: ry,
                                        z: worldZ,
                                        ordinal: sample
                                    ) {
                                        handler(self, worldX, ry, worldZ, cell)
                                    }
                                }
                            }
                        }
                    }
                }
                // Player-only chunks retain their baseline nested order and
                // shared World/farming RNG behavior. Overlap is skipped so no
                // target can receive two random-tick passes.
                for dz in -sd...sd {
                    for dx in -sd...sd {
                        let cx = simCenterX + dx
                        let cz = simCenterZ + dz
                        if hasAgentSimulationCoverage(chunkX: cx, chunkZ: cz) {
                            continue
                        }
                        guard let c = getChunk(cx, cz),
                              c.status != .empty else { continue }
                        for section in 0..<c.sections {
                            for _ in 0..<randomTickSpeed {
                                let rx = rng.nextInt(CHUNK_W)
                                let rz = rng.nextInt(CHUNK_W)
                                let ry = info.minY + section * CHUNK_W
                                    + rng.nextInt(CHUNK_W)
                                let cell = Int(c.get(rx, ry, rz))
                                let id = cell >> 4
                                if id != 0 && RANDOM_TICKS[id] == 1,
                                   let handler = randomTickHandlers[id] {
                                    handler(
                                        self,
                                        c.cx * CHUNK_W + rx,
                                        ry,
                                        c.cz * CHUNK_W + rz,
                                        cell
                                    )
                                }
                            }
                        }
                    }
                }
            } else {
                // Frozen legacy path for Worlds without agent coverage.
                for dz in -sd...sd {
                    for dx in -sd...sd {
                        guard let c = getChunk(simCenterX + dx, simCenterZ + dz), c.status != .empty else { continue }
                        for s in 0..<c.sections {
                            for _ in 0..<randomTickSpeed {
                                let rx = rng.nextInt(16), rz = rng.nextInt(16), ry = info.minY + s * 16 + rng.nextInt(16)
                                let cell = Int(c.get(rx, ry, rz))
                                let id = cell >> 4
                                if id != 0 && RANDOM_TICKS[id] == 1 {
                                    if let h = randomTickHandlers[id] {
                                        h(self, c.cx * 16 + rx, ry, c.cz * 16 + rz, cell)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ticking block entities (array is CoW — the loop iterates a snapshot,
        // so handlers may add/remove BEs safely)
        if physicalSimulationCoverage.isRequested {
            let covered = tickingBEList.filter {
                hasAgentSimulationCoverage(
                    chunkX: floorDiv($0.x, CHUNK_W),
                    chunkZ: floorDiv($0.z, CHUNK_W)
                )
            }.sorted {
                if $0.z != $1.z { return $0.z < $1.z }
                if $0.x != $1.x { return $0.x < $1.x }
                if $0.y != $1.y { return $0.y < $1.y }
                return $0.type < $1.type
            }
            let coveredIDs = Set(covered.map(ObjectIdentifier.init))
            if physicalSimulationCoverage.isReady {
                for be in covered {
                    if let handler = beTickHandlers[be.type] {
                        withPhysicalSimulationRandomness(
                            operationDomain: 0xbe00_0001,
                            x: be.x,
                            y: be.y,
                            z: be.z,
                            ordinal: Int(hashString(be.type))
                        ) {
                            handler(self, be)
                        }
                    }
                }
            }
            for be in tickingBEList
                where !coveredIDs.contains(ObjectIdentifier(be)) {
                if let handler = beTickHandlers[be.type] {
                    handler(self, be)
                }
            }
        } else {
            for be in tickingBEList {
                if let h = beTickHandlers[be.type] {
                    h(self, be)
                }
            }
        }

        light.flush()
    }

    private func tickWeather() {
        if dim != .overworld { return }
        if rule("doWeatherCycle") {
            weatherTimer -= 1
            if weatherTimer <= 0 {
                if physicalSimulationCoverage.isRequested {
                    var weatherRNG = RandomX(physicalSimulationSeed(
                        operationDomain: 0x7ea7_4e01,
                        x: raining ? 1 : 0,
                        y: thundering ? 1 : 0,
                        z: 0
                    ))
                    if raining {
                        raining = false
                        thundering = false
                        weatherTimer = 12000 + weatherRNG.nextInt(156000)
                    } else {
                        raining = true
                        thundering = weatherRNG.chance(0.3)
                        weatherTimer = 12000 + weatherRNG.nextInt(12000)
                    }
                } else {
                    if raining {
                        raining = false
                        thundering = false
                        weatherTimer = 12000 + rng.nextInt(156000)
                    } else {
                        raining = true
                        thundering = rng.chance(0.3)
                        weatherTimer = 12000 + rng.nextInt(12000)
                    }
                }
            }
        }
        rainLevel += raining ? 0.01 : -0.01
        rainLevel = max(0, min(1, rainLevel))
        thunderLevel += thundering ? 0.01 : -0.01
        thunderLevel = max(0, min(1, thunderLevel))
    }

    /// celestial angle 0..1 (0.0 = noon-ish vanilla curve)
    public func sunAngle() -> Double {
        let f = (Double(dayTime) / Double(DAY_LENGTH)) - 0.25
        let frac = f < 0 ? f + 1 : f
        let a = 1 - (detCos(frac * .pi) + 1) / 2
        return frac + (a - frac) / 3
    }
    /// sky darkness factor 0..11 subtracted from skylight 15
    public func skyDarken() -> Double {
        let angle = sunAngle()
        var f = 1 - (detCos(angle * .pi * 2) * 2 + 0.5)
        f = max(0, min(1, f))
        f = 1 - f
        f *= 1 - rainLevel * 5 / 16
        f *= 1 - thunderLevel * 5 / 16
        return (1 - f) * 11
    }
    public func isDay() -> Bool { skyDarken() < 4 }

    // MARK: - light
    public func getSkyLight(_ x: Int, _ y: Int, _ z: Int) -> Int {
        guard let c = getChunkAt(x, z) else { return 15 }
        return c.getSky(posMod(x, CHUNK_W), y, posMod(z, CHUNK_W))
    }
    public func getBlockLight(_ x: Int, _ y: Int, _ z: Int) -> Int {
        guard let c = getChunkAt(x, z) else { return 0 }
        return c.getBlockLight(posMod(x, CHUNK_W), y, posMod(z, CHUNK_W))
    }
    /// effective light for mob spawning / rendering decisions
    public func lightAt(_ x: Int, _ y: Int, _ z: Int) -> Double {
        let sky = max(0, Double(getSkyLight(x, y, z)) - skyDarken())
        return max(Double(info.ambientLight), max(sky, Double(getBlockLight(x, y, z))))
    }

    public func heightAt(_ x: Int, _ z: Int) -> Int {
        guard let c = getChunkAt(x, z) else { return info.minY }
        return c.heightAt(posMod(x, CHUNK_W), posMod(z, CHUNK_W))
    }
    /// highest motion-blocking block + 1 (where an entity can stand)
    public func surfaceY(_ x: Int, _ z: Int) -> Int {
        let top = info.minY + info.height - 1
        var y = top
        while y > info.minY {
            let cell = getBlock(x, y, z)
            let id = cell >> 4
            if id != 0 && blockDefs[id].solid { return y + 1 }
            y -= 1
        }
        return info.minY + 1
    }
    public func canSeeSky(_ x: Int, _ y: Int, _ z: Int) -> Bool {
        y >= heightAt(x, z) && info.hasSky
    }
    public func biomeAt(_ x: Int, _ y: Int, _ z: Int) -> Int {
        guard let c = getChunkAt(x, z) else { return 0 }
        return c.biomeAt(posMod(x, CHUNK_W), y, posMod(z, CHUNK_W))
    }

    // MARK: - block entities
    public func getBlockEntity(_ x: Int, _ y: Int, _ z: Int) -> BlockEntityData? {
        getChunkAt(x, z)?.getBlockEntity(posMod(x, CHUNK_W), y, posMod(z, CHUNK_W))
    }
    public func setBlockEntity(_ be: BlockEntityData) {
        guard let c = getChunkAt(be.x, be.z) else { return }
        c.setBlockEntity(posMod(be.x, CHUNK_W), be.y, posMod(be.z, CHUNK_W), be)
        if beTickHandlers[be.type] != nil {
            trackTickingBE(be)
        }
    }
    /// rebuild ticking set after chunk load — sorted by cell index so the tick
    /// order is reproducible (Dictionary.values order is hash-seeded)
    public func adoptChunkBlockEntities(_ c: Chunk) {
        for (_, be) in c.blockEntities.sorted(by: { $0.key < $1.key }) where beTickHandlers[be.type] != nil {
            trackTickingBE(be)
        }
    }
    public func releaseChunkBlockEntities(_ c: Chunk) {
        for be in c.blockEntities.values {
            untrackTickingBE(be)
        }
    }

    // MARK: - entities
    public func addEntity(_ e: EntityRef) {
        entities.append(e)
        entityById[e.id] = e
    }
    public func removeEntity(_ e: EntityRef) {
        if let i = entities.firstIndex(where: { $0 === e }) {
            entities.remove(at: i)
        }
        entityById.removeValue(forKey: e.id)
    }
    public func getEntitiesInBox(_ box: AABB, except: EntityRef? = nil, filter: ((EntityRef) -> Bool)? = nil) -> [EntityRef] {
        var out: [EntityRef] = []
        for e in entities {
            if e === except || e.dead { continue }
            if let f = filter, !f(e) { continue }
            if e.bb().intersects(box) { out.append(e) }
        }
        return out
    }
    public func getEntitiesNear(_ x: Double, _ y: Double, _ z: Double, _ radius: Double, filter: ((EntityRef) -> Bool)? = nil) -> [EntityRef] {
        let r2 = radius * radius
        var out: [EntityRef] = []
        for e in entities {
            if e.dead { continue }
            let dx = e.x - x, dy = e.y - y, dz = e.z - z
            if dx * dx + dy * dy + dz * dz <= r2 && (filter?(e) ?? true) { out.append(e) }
        }
        return out
    }

    // MARK: - vibrations (sculk)
    public func emitVibration(_ x: Double, _ y: Double, _ z: Double, _ freq: Int, _ src: EntityRef?) {
        hooks.onVibration?(x, y, z, freq, src)
    }

    // MARK: - portals
    public func findPortalNear(_ x: Int, _ y: Int, _ z: Int, _ radiusChunks: Int, _ portalId: Int) -> (Int, Int, Int)? {
        let cx = floorDiv(x, CHUNK_W), cz = floorDiv(z, CHUNK_W)
        var best: (Int, Int, Int)?
        var bestD = Double.infinity
        for dz in -radiusChunks...radiusChunks {
            for dx in -radiusChunks...radiusChunks {
                guard let c = getChunk(cx + dx, cz + dz) else { continue }
                // sorted: Set order is hash-seeded, and equidistant candidates
                // must tie-break the same way every run
                for idx in c.portalBlocks.sorted() {
                    let (wx, wy, wz) = c.idxToWorld(idx)
                    if Int(c.blocks[idx] >> 4) != portalId { continue }
                    let d = Double((wx - x) * (wx - x) + (wy - y) * (wy - y) + (wz - z) * (wz - z))
                    if d < bestD { bestD = d; best = (wx, wy, wz) }
                }
            }
        }
        return best
    }

    // MARK: - collision / raycast
    public func forEachCollisionBox(_ box: AABB, _ cb: (AABB) -> Void) {
        let x0 = Int((box.x0 - 1).rounded(.down)), x1 = Int((box.x1 + 1).rounded(.down))
        let y0 = Int((box.y0 - 1).rounded(.down)), y1 = Int((box.y1 + 1).rounded(.down))
        let z0 = Int((box.z0 - 1).rounded(.down)), z1 = Int((box.z1 + 1).rounded(.down))
        var scratch: [AABB] = []
        for y in y0...y1 {
            for z in z0...z1 {
                for x in x0...x1 {
                    let cell = getBlock(x, y, z)
                    if cell == 0 { continue }
                    let id = cell >> 4
                    if !blockDefs[id].solid { continue }
                    scratch.removeAll(keepingCapacity: true)
                    shapeBoxes(cell, { dx, dy, dz in self.getBlock(x + dx, y + dy, z + dz) }, &scratch, true)
                    for b in scratch {
                        cb(aabb(b.x0 + Double(x), b.y0 + Double(y), b.z0 + Double(z),
                                b.x1 + Double(x), b.y1 + Double(y), b.z1 + Double(z)))
                    }
                }
            }
        }
    }

    public func raycast(_ ox: Double, _ oy: Double, _ oz: Double, _ dx: Double, _ dy: Double, _ dz: Double, _ maxDist: Double, fluid: Bool = false) -> RaycastHit? {
        var x = Int(ox.rounded(.down)), y = Int(oy.rounded(.down)), z = Int(oz.rounded(.down))
        let stepX = dx > 0 ? 1 : dx < 0 ? -1 : 0
        let stepY = dy > 0 ? 1 : dy < 0 ? -1 : 0
        let stepZ = dz > 0 ? 1 : dz < 0 ? -1 : 0
        let tDeltaX = stepX != 0 ? abs(1 / dx) : Double.infinity
        let tDeltaY = stepY != 0 ? abs(1 / dy) : Double.infinity
        let tDeltaZ = stepZ != 0 ? abs(1 / dz) : Double.infinity
        var tMaxX = stepX > 0 ? (Double(x) + 1 - ox) * tDeltaX : stepX < 0 ? (ox - Double(x)) * tDeltaX : Double.infinity
        var tMaxY = stepY > 0 ? (Double(y) + 1 - oy) * tDeltaY : stepY < 0 ? (oy - Double(y)) * tDeltaY : Double.infinity
        var tMaxZ = stepZ > 0 ? (Double(z) + 1 - oz) * tDeltaZ : stepZ < 0 ? (oz - Double(z)) * tDeltaZ : Double.infinity
        var face = 0
        var scratch: [AABB] = []
        for _ in 0..<512 {
            let cell = getBlock(x, y, z)
            let id = cell >> 4
            if id != 0 {
                let isFluid = id == Int(B.water) || id == Int(B.lava)
                if (isFluid && fluid) || (!isFluid && blockDefs[id].hardness != 100) {
                    scratch.removeAll(keepingCapacity: true)
                    if isFluid {
                        scratch.append(aabb(0, 0, 0, 1, 14.0 / 16, 1))
                    } else {
                        shapeBoxes(cell, { ddx, ddy, ddz in self.getBlock(x + ddx, y + ddy, z + ddz) }, &scratch, false)
                    }
                    var bestT = Double.infinity
                    var bestFace = face
                    for b in scratch {
                        let wb = aabb(b.x0 + Double(x), b.y0 + Double(y), b.z0 + Double(z),
                                      b.x1 + Double(x), b.y1 + Double(y), b.z1 + Double(z))
                        let t = rayAABB(ox, oy, oz, dx, dy, dz, wb)
                        if t >= 0 && t < bestT && t <= maxDist {
                            bestT = t
                            // recompute hit face from hit point
                            let hx = ox + dx * t, hy = oy + dy * t, hz = oz + dz * t
                            let ex = min(abs(hx - wb.x0), abs(hx - wb.x1))
                            let ey = min(abs(hy - wb.y0), abs(hy - wb.y1))
                            let ez = min(abs(hz - wb.z0), abs(hz - wb.z1))
                            if ey <= ex && ey <= ez { bestFace = abs(hy - wb.y0) < abs(hy - wb.y1) ? 0 : 1 }
                            else if ex <= ez { bestFace = abs(hx - wb.x0) < abs(hx - wb.x1) ? 4 : 5 }
                            else { bestFace = abs(hz - wb.z0) < abs(hz - wb.z1) ? 2 : 3 }
                        }
                    }
                    if bestT != Double.infinity {
                        return RaycastHit(x: x, y: y, z: z, face: bestFace, cell: cell, t: bestT,
                                          px: ox + dx * bestT, py: oy + dy * bestT, pz: oz + dz * bestT)
                    }
                }
            }
            // advance
            if tMaxX < tMaxY && tMaxX < tMaxZ {
                if tMaxX > maxDist { return nil }
                x += stepX; tMaxX += tDeltaX; face = stepX > 0 ? 4 : 5
            } else if tMaxY < tMaxZ {
                if tMaxY > maxDist { return nil }
                y += stepY; tMaxY += tDeltaY; face = stepY > 0 ? 0 : 1
            } else {
                if tMaxZ > maxDist { return nil }
                z += stepZ; tMaxZ += tDeltaZ; face = stepZ > 0 ? 2 : 3
            }
        }
        return nil
    }

    // MARK: - fluid helpers
    public func isWaterAt(_ x: Int, _ y: Int, _ z: Int) -> Bool {
        isWaterlogged(UInt16(getBlock(x, y, z)))
    }
    public func isLavaAt(_ x: Int, _ y: Int, _ z: Int) -> Bool {
        (getBlock(x, y, z) >> 4) == Int(B.lava)
    }
    public func fluidHeight(_ x: Int, _ y: Int, _ z: Int) -> Double {
        let cell = getBlock(x, y, z)
        let id = cell >> 4
        if id != Int(B.water) && id != Int(B.lava) { return isWaterlogged(UInt16(cell)) ? 14.0 / 16 : 0 }
        let level = cell & 7
        if (cell & 8) != 0 { return 1 } // falling
        if level == 0 {
            // source: full if fluid above
            let above = getBlock(x, y + 1, z) >> 4
            return above == id ? 1 : 14.0 / 16
        }
        return max(2.0 / 16, Double(8 - level) / 8 * 14 / 16)
    }

    public func isRainingAt(_ x: Int, _ y: Int, _ z: Int) -> Bool {
        if rainLevel <= 0.2 || !info.hasSky { return false }
        if !canSeeSky(x, y, z) { return false }
        return true
    }
}

private func compareTicks(_ a: ScheduledTick, _ b: ScheduledTick) -> Int {
    if a.time != b.time { return a.time - b.time }
    if a.priority != b.priority { return a.priority - b.priority }
    return a.order - b.order
}
