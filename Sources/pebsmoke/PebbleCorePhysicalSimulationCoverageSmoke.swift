import Dispatch
import PebbleCore

private func coverageReadyChunk(
    _ world: World,
    _ cx: Int,
    _ cz: Int,
    randomTickBlock: UInt16? = nil
) -> Chunk {
    let chunk = Chunk(
        cx: cx,
        cz: cz,
        minY: world.info.minY,
        height: world.info.height
    )
    chunk.status = .lit
    if let randomTickBlock {
        for y in world.info.minY..<(world.info.minY + SECTION_H) {
            for z in 0..<CHUNK_W {
                for x in 0..<CHUNK_W {
                    chunk.set(x, y, z, randomTickBlock)
                }
            }
        }
    }
    world.setChunk(chunk)
    return chunk
}

private func coverageRoots(_ coordinates: [(Int, Int)])
    -> [PhysicalSimulationCoverageRoot] {
    coordinates.enumerated().map { index, coordinate in
        PhysicalSimulationCoverageRoot(
            id: "physical_\(index)",
            chunkX: coordinate.0,
            chunkZ: coordinate.1
        )
    }
}

private func coverageAgentRandomDigest(
    cameraPath: [(Int, Int)]
) -> (digest: String, eventCount: Int, snapshot: PhysicalSimulationCoverageSnapshot) {
    let world = World(dim: .nether, seed: 46)
    world.simDistance = 0
    world.randomTickSpeed = 3
    let root = PhysicalSimulationCoverageRoot(
        id: "physical_agent_0",
        chunkX: 0,
        chunkZ: 0
    )
    for z in -1...1 {
        for x in -1...1 {
            _ = coverageReadyChunk(
                world,
                x,
                z,
                randomTickBlock: x == 0 && z == 0
                    ? cell(B.wheat)
                    : nil
            )
        }
    }
    for position in Set(cameraPath.map {
        PhysicalSimulationChunk(x: $0.0, z: $0.1)
    }) where world.getChunk(position.x, position.z) == nil {
        _ = coverageReadyChunk(
            world,
            position.x,
            position.z,
            randomTickBlock: cell(B.wheat)
        )
    }
    world.applyPhysicalSimulationCoverage(.active([root]))

    let blockID = Int(B.wheat)
    let previousHandler = randomTickHandlers[blockID]
    var relevantEvents: [String] = []
    randomTickHandlers[blockID] = { _, x, y, z, _ in
        let draw = gameRng.next()
        if floorDiv(x, CHUNK_W) == 0 && floorDiv(z, CHUNK_W) == 0 {
            relevantEvents.append("\(x):\(y):\(z):\(draw)")
        }
    }
    defer { randomTickHandlers[blockID] = previousHandler }

    for center in cameraPath {
        world.simCenterX = center.0
        world.simCenterZ = center.1
        world.tick()
    }
    var digest: UInt64 = 1469598103934665603
    for byte in relevantEvents.joined(separator: "|").utf8 {
        digest ^= UInt64(byte)
        digest &*= 1099511628211
    }
    return (
        String(format: "%016llx", digest),
        relevantEvents.count,
        world.physicalSimulationCoverage
    )
}

private func coveragePathWorld(
    seed: UInt32 = 46,
    missingChunk: PhysicalSimulationChunk? = nil
) -> World {
    let world = World(dim: .overworld, seed: seed)
    for chunkZ in -1...1 {
        for chunkX in -1...1 {
            if missingChunk == PhysicalSimulationChunk(x: chunkX, z: chunkZ) {
                continue
            }
            _ = coverageReadyChunk(world, chunkX, chunkZ)
            for localZ in 0..<CHUNK_W {
                for localX in 0..<CHUNK_W {
                    world.setBlock(
                        chunkX * CHUNK_W + localX,
                        63,
                        chunkZ * CHUNK_W + localZ,
                        Int(cell(B.stone)),
                        SET_SILENT
                    )
                }
            }
        }
    }
    world.applyPhysicalSimulationCoverage(.active([
        PhysicalSimulationCoverageRoot(
            id: "physical_path_agent",
            chunkX: 0,
            chunkZ: 0
        )
    ]))
    return world
}

private func coveragePath(
    _ result: PhysicalPathSearchResult
) -> [PathNode]? {
    guard case .path(let path) = result else { return nil }
    return path
}

private func boundedCoveragePath(
    world: World,
    fromX: Double,
    fromY: Double = 64,
    fromZ: Double,
    toX: Double,
    toY: Double = 64,
    toZ: Double,
    maxNodes: Int = 600
) -> PhysicalPathSearchResult {
    findPath(
        world,
        fromX, fromY, fromZ,
        toX, toY, toZ,
        maxNodes,
        true,
        within: PhysicalPathSearchDomain(
            coverage: world.physicalSimulationCoverage
        )
    )
}

private func runBoundedCoveragePathProofs() {
    let same = coveragePathWorld()
    check(
        "bounded path accepts start and target in the same ready cell",
        boundedCoveragePath(
            world: same,
            fromX: 0.5, fromZ: 0.5,
            toX: 0.5, toZ: 0.5
        ) == .path([])
    )

    let corner = coveragePathWorld()
    let simple = boundedCoveragePath(
        world: corner,
        fromX: 15.5, fromZ: 15.5,
        toX: 23.5, toZ: 15.5
    )
    check(
        "radius-eight path from a root-chunk corner stays in the 3x3 halo",
        coveragePath(simple)?.last.map {
            $0.x == 23 && $0.y == 64 && $0.z == 15
        } == true
    )

    let obstacle = coveragePathWorld()
    obstacle.setBlock(1, 64, 0, Int(cell(B.stone)), SET_SILENT)
    obstacle.setBlock(1, 65, 0, Int(cell(B.stone)), SET_SILENT)
    let detour = boundedCoveragePath(
        world: obstacle,
        fromX: 0.5, fromZ: 0.5,
        toX: 4.5, toZ: 0.5
    )
    check(
        "bounded path finds an in-coverage obstacle detour",
        coveragePath(detour)?.last.map {
            $0.x == 4 && $0.y == 64 && $0.z == 0
        } == true
            && coveragePath(detour)?.contains(where: {
                $0.x == 1 && $0.y == 64 && $0.z == 0
            }) == false
    )

    let outsideDetour = coveragePathWorld()
    for z in -16...31 {
        outsideDetour.setBlock(16, 64, z, Int(cell(B.stone)), SET_SILENT)
        outsideDetour.setBlock(16, 65, z, Int(cell(B.stone)), SET_SILENT)
    }
    check(
        "detour requiring state outside coverage is coverage-limited",
        boundedCoveragePath(
            world: outsideDetour,
            fromX: 15.5, fromZ: 0.5,
            toX: 17.5, toZ: 0.5,
            maxNodes: 10_000
        ) == .coverageLimited
    )

    let unavailable = coveragePathWorld(
        missingChunk: PhysicalSimulationChunk(x: 1, z: 1)
    )
    check(
        "bounded path reports unavailable required chunk explicitly",
        unavailable.physicalSimulationCoverage.status == .pending
            && boundedCoveragePath(
                world: unavailable,
                fromX: 0.5, fromZ: 0.5,
                toX: 4.5, toZ: 0.5
            ) == .coverageUnavailable
    )

    let budget = coveragePathWorld()
    check(
        "bounded path distinguishes node-budget exhaustion",
        boundedCoveragePath(
            world: budget,
            fromX: 0.5, fromZ: 0.5,
            toX: 8.5, toZ: 0.5,
            maxNodes: 1
        ) == .nodeBudgetExhausted
    )

    let blocked = coveragePathWorld()
    for dz in -1...1 {
        for dx in -1...1 where dx != 0 || dz != 0 {
            blocked.setBlock(dx, 64, dz, Int(cell(B.stone)), SET_SILENT)
            blocked.setBlock(dx, 65, dz, Int(cell(B.stone)), SET_SILENT)
        }
    }
    check(
        "fully explored ready domain reports genuine bounded no-path",
        boundedCoveragePath(
            world: blocked,
            fromX: 0.5, fromZ: 0.5,
            toX: 4.5, toZ: 0.5
        ) == .noPath
    )

    let legacy = coveragePathWorld()
    let legacyBudgetResult = findPath(
        legacy,
        0.5, 64, 0.5,
        8.5, 64, 0.5,
        1,
        true
    )
    check(
        "default Core path caller retains legacy best-effort budget behavior",
        legacyBudgetResult == []
            && boundedCoveragePath(
                world: legacy,
                fromX: 0.5, fromZ: 0.5,
                toX: 8.5, toZ: 0.5,
                maxNodes: 1
            ) == .nodeBudgetExhausted
    )

    let camera = coveragePathWorld()
    camera.simCenterX = 0
    camera.simCenterZ = 0
    let near = boundedCoveragePath(
        world: camera,
        fromX: 0.5, fromZ: 0.5,
        toX: 8.5, toZ: 0.5
    )
    camera.simCenterX = 100
    camera.simCenterZ = -100
    let far = boundedCoveragePath(
        world: camera,
        fromX: 0.5, fromZ: 0.5,
        toX: 8.5, toZ: 0.5
    )
    camera.simCenterX = 0
    camera.simCenterZ = 0
    let returned = boundedCoveragePath(
        world: camera,
        fromX: 0.5, fromZ: 0.5,
        toX: 8.5, toZ: 0.5
    )
    check(
        "bounded path is camera-near/far/return equivalent",
        near == far && far == returned
    )
}

private func coverageWeatherWorld(cameraChunkX: Int) -> World {
    let world = World(dim: .overworld, seed: 887)
    world.simDistance = 0
    world.randomTickSpeed = 3
    world.weatherTimer = 2
    for z in -1...1 {
        for x in -1...1 {
            _ = coverageReadyChunk(world, x, z)
        }
    }
    if world.getChunk(cameraChunkX, 0) == nil {
        _ = coverageReadyChunk(world, cameraChunkX, 0)
    }
    world.applyPhysicalSimulationCoverage(.active(coverageRoots([(0, 0)])))
    world.simCenterX = cameraChunkX
    world.simCenterZ = 0
    return world
}

private func runCoverageWeatherProofs() {
    do {
        let world = World(dim: .overworld, seed: 887)
        world.randomTickSpeed = 0
        world.weatherTimer = 1
        var expectedRNG = world.rng
        let expectedThunder = expectedRNG.chance(0.3)
        let expectedTimer = 12_000 + expectedRNG.nextInt(12_000)
        world.applyPhysicalSimulationCoverage(.inactive)
        world.tick()
        check(
            "empty coverage preserves exact legacy weather RNG",
            world.raining
                && world.thundering == expectedThunder
                && world.weatherTimer == expectedTimer
                && world.rng == expectedRNG
        )
    }

    let near = coverageWeatherWorld(cameraChunkX: 0)
    let far = coverageWeatherWorld(cameraChunkX: 100)
    near.tick()
    far.tick()
    let playerRandomStreamsDiverged = near.rng != far.rng
    near.tick()
    far.tick()
    check(
        "active coverage weather is isolated from camera-only RNG consumption",
        playerRandomStreamsDiverged
            && near.raining == far.raining
            && near.thundering == far.thundering
            && near.weatherTimer == far.weatherTimer
            && near.rainLevel == far.rainLevel
            && near.thunderLevel == far.thunderLevel
    )
}

private func coverageScheduledDigest(
    cameraPath: [(Int, Int)],
    roots: [PhysicalSimulationCoverageRoot]
) -> (events: [UInt32], status: PhysicalSimulationCoverageStatus) {
    let world = World(dim: .nether, seed: 46)
    world.simDistance = 0
    world.randomTickSpeed = 3
    for z in -1...1 {
        for x in -1...2 { _ = coverageReadyChunk(world, x, z) }
    }
    for position in Set(cameraPath.map {
        PhysicalSimulationChunk(x: $0.0, z: $0.1)
    }) where world.getChunk(position.x, position.z) == nil {
        _ = coverageReadyChunk(world, position.x, position.z)
    }
    world.setBlock(0, 64, 0, Int(cell(B.stone)), SET_SILENT)
    world.applyPhysicalSimulationCoverage(.active(roots))

    let blockID = Int(B.stone)
    let previous = blockTickHandlers[blockID]
    var events: [UInt32] = []
    blockTickHandlers[blockID] = { _, x, y, z, _ in
        if x == 0 && y == 64 && z == 0 { events.append(gameRng.next()) }
    }
    defer { blockTickHandlers[blockID] = previous }
    for camera in cameraPath {
        world.simCenterX = camera.0
        world.simCenterZ = camera.1
        world.scheduleTick(0, 64, 0, blockID, 1)
        world.tick()
    }
    return (events, world.physicalSimulationCoverage.status)
}

private func runCoverageScheduledTickProofs() {
    let one = coverageRoots([(0, 0)])
    let near = coverageScheduledDigest(
        cameraPath: [(0, 0), (0, 0), (0, 0)],
        roots: one
    )
    let far = coverageScheduledDigest(
        cameraPath: [(100, 100), (100, 100), (100, 100)],
        roots: one
    )
    let moved = coverageScheduledDigest(
        cameraPath: [(0, 0), (100, 100), (0, 0)],
        roots: one
    )
    check(
        "covered scheduled ticks preserve due work across camera paths",
        near.status == .ready
            && near.events.count == 3
            && near.events == far.events
            && far.events == moved.events
    )

    let overlap = coverageScheduledDigest(
        cameraPath: [(100, 100)],
        roots: coverageRoots([(0, 0), (1, 0)])
    )
    check(
        "overlapping roots do not duplicate scheduled work",
        overlap.events.count == 1
    )

    let world = World(dim: .nether, seed: 46)
    world.randomTickSpeed = 0
    for z in -1...1 {
        for x in -1...1 where x != 1 || z != 1 {
            _ = coverageReadyChunk(world, x, z)
        }
    }
    world.setBlock(0, 64, 0, Int(cell(B.stone)), SET_SILENT)
    let roots = coverageRoots([(0, 0)])
    world.applyPhysicalSimulationCoverage(.active(roots))
    let blockID = Int(B.stone)
    let previous = blockTickHandlers[blockID]
    var count = 0
    blockTickHandlers[blockID] = { _, _, _, _, _ in count += 1 }
    defer { blockTickHandlers[blockID] = previous }
    world.scheduleTick(0, 64, 0, blockID, 1)
    world.tick()
    _ = coverageReadyChunk(world, 1, 1)
    world.applyPhysicalSimulationCoverage(.active(roots))
    world.tick()
    check(
        "covered scheduled work waits rather than disappearing while pending",
        count == 1 && world.physicalSimulationCoverage.status == .ready
    )
}

private func coverageBlockEntityDigest(
    includePlayerOnly: Bool,
    roots: [PhysicalSimulationCoverageRoot]
) -> (events: [UInt32], totalTicks: Int) {
    let world = World(dim: .nether, seed: 887)
    world.randomTickSpeed = 0
    for z in -1...1 {
        for x in -1...2 { _ = coverageReadyChunk(world, x, z) }
    }
    if includePlayerOnly { _ = coverageReadyChunk(world, 100, 0) }
    world.applyPhysicalSimulationCoverage(.active(roots))
    let type = "ps01_increment03_tick_probe"
    let previous = beTickHandlers[type]
    var events: [UInt32] = []
    var totalTicks = 0
    beTickHandlers[type] = { _, blockEntity in
        totalTicks += 1
        if blockEntity.x == 0 { events.append(gameRng.next()) }
        else { _ = gameRng.next() }
    }
    defer { beTickHandlers[type] = previous }
    if includePlayerOnly {
        world.setBlockEntity(BlockEntityData(
            type: type, x: 1_600, y: 64, z: 0
        ))
    }
    world.setBlockEntity(BlockEntityData(type: type, x: 0, y: 64, z: 0))
    world.tick()
    return (events, totalTicks)
}

private func runCoverageBlockEntityProofs() {
    let roots = coverageRoots([(0, 0)])
    let coveredOnly = coverageBlockEntityDigest(
        includePlayerOnly: false,
        roots: roots
    )
    let withPlayerOnly = coverageBlockEntityDigest(
        includePlayerOnly: true,
        roots: roots
    )
    check(
        "covered block-entity result ignores camera-only residency",
        coveredOnly.events.count == 1
            && coveredOnly.events == withPlayerOnly.events
            && withPlayerOnly.totalTicks == 2
    )

    let overlap = coverageBlockEntityDigest(
        includePlayerOnly: false,
        roots: coverageRoots([(0, 0), (1, 0)])
    )
    check(
        "overlapping roots do not duplicate block-entity ticks",
        overlap.events.count == 1 && overlap.totalTicks == 1
    )

    let world = World(dim: .nether, seed: 887)
    world.randomTickSpeed = 0
    for z in -1...1 {
        for x in -1...1 where x != 1 || z != 1 {
            _ = coverageReadyChunk(world, x, z)
        }
    }
    let type = "ps01_increment03_pending_be"
    let previous = beTickHandlers[type]
    var count = 0
    beTickHandlers[type] = { _, _ in count += 1 }
    defer { beTickHandlers[type] = previous }
    world.setBlockEntity(BlockEntityData(type: type, x: 0, y: 64, z: 0))
    world.applyPhysicalSimulationCoverage(.active(coverageRoots([(0, 0)])))
    world.tick()
    check(
        "covered block entity does not tick through incomplete coverage",
        world.physicalSimulationCoverage.status == .pending && count == 0
    )
}

private final class CoverageCountingEntity: Entity {
    override var type: String { "ps01_ordinary_entity" }
    override var shouldSaveToChunk: Bool { false }
    var draws: [UInt32] = []

    override func tick() {
        age += 1
        draws.append(gameRng.next())
    }
}

private func coverageGameRecord(_ id: String, seed: Int32 = 46) -> WorldRecord {
    var record = WorldRecord(
        id: id,
        name: "PS01 Increment 03 entity proof",
        seed: seed,
        gameMode: GameMode.creative,
        difficulty: 0
    )
    record.spawnX = 0
    record.spawnY = 65
    record.spawnZ = 0
    record.nextEntityId = 1
    return record
}

private func coverageEntityDigest(
    id: String,
    cameraChunks: [Int],
    overlappingRoots: Bool = false,
    removeCoverageAfterPath: Bool = false
) -> (draws: [UInt32], countAfterRemoval: Int, status: PhysicalSimulationCoverageStatus) {
    let game = GameCore()
    game.db.deleteWorld(id)
    guard game.db.putWorld(coverageGameRecord(id)) else {
        return ([], -1, .refused)
    }
    game.loadWorld(id)
    let world = game.world
    world.randomTickSpeed = 0
    world.gameRules["doMobSpawning"] = 0
    world.gameRules["doWeatherCycle"] = 0
    world.simDistance = 1
    let roots = overlappingRoots
        ? coverageRoots([(0, 0), (1, 0)])
        : coverageRoots([(0, 0)])
    if overlappingRoots {
        for z in -1...1 where world.getChunk(2, z) == nil {
            _ = coverageReadyChunk(world, 2, z)
        }
    }
    var request = PhysicalSimulationCoverageRequest.active(roots)
    game.physicalSimulationCoverageProvider = { _ in request }
    let entity = CoverageCountingEntity(world: world)
    entity.setPos(0.5, 64, 0.5)
    world.addEntity(entity)
    for cameraChunk in cameraChunks {
        game.player.setPos(Double(cameraChunk * CHUNK_W) + 0.5, 64, 0.5)
        _ = game.frame(dtMs: TICK_MS)
    }
    let beforeRemoval = entity.draws.count
    if removeCoverageAfterPath {
        request = .inactive
        game.player.setPos(1_600.5, 64, 0.5)
        _ = game.frame(dtMs: TICK_MS)
    }
    let result = (
        entity.draws,
        removeCoverageAfterPath ? entity.draws.count : beforeRemoval,
        world.physicalSimulationCoverage.status
    )
    _ = game.exitToTitle()
    game.db.deleteWorld(id)
    return result
}

private func runCoverageEntityProofs() {
    let near = coverageEntityDigest(
        id: "ps01-i03-entity-near",
        cameraChunks: [0, 0, 0]
    )
    let far = coverageEntityDigest(
        id: "ps01-i03-entity-far",
        cameraChunks: [100, 100, 100]
    )
    let moved = coverageEntityDigest(
        id: "ps01-i03-entity-moved",
        cameraChunks: [0, 100, 0]
    )
    check(
        "ordinary covered entity progression is camera equivalent",
        near.draws.count == 3
            && near.draws == far.draws
            && far.draws == moved.draws
    )

    let overlap = coverageEntityDigest(
        id: "ps01-i03-entity-overlap",
        cameraChunks: [100, 100, 100],
        overlappingRoots: true
    )
    check(
        "overlapping roots do not duplicate ordinary entity ticks",
        overlap.draws.count == 3
    )

    let removed = coverageEntityDigest(
        id: "ps01-i03-entity-removal",
        cameraChunks: [100],
        removeCoverageAfterPath: true
    )
    check(
        "removing the last root stops remote ordinary entity ticking",
        removed.draws.count == 1
            && removed.countAfterRemoval == 1
            && removed.status == .inactive
    )
}

private func runCoverageGenerationFairnessProofs() {
    let worldID = "ps01-i03-generation-fairness"
    let game = GameCore()
    game.db.deleteWorld(worldID)
    guard game.db.putWorld(coverageGameRecord(worldID)) else {
        check("coverage generation fairness fixture installs", false)
        return
    }
    game.loadWorld(worldID)
    game.settings.renderDistance = 2
    game.world.randomTickSpeed = 0
    let separated = (0..<PhysicalSimulationCoverageContract.maximumRoots).map {
        PhysicalSimulationCoverageRoot(
            id: "generation_\($0)",
            chunkX: 100 + $0 * 3,
            chunkZ: 100
        )
    }
    game.physicalSimulationCoverageProvider = { _ in .active(separated) }
    _ = game.frame(dtMs: TICK_MS)
    let diagnostics = game.physicalSimulationCoverageRuntimeDiagnostics(
        for: game.world
    )
    check(
        "agent generation occupancy leaves six player queue slots",
        game.world.physicalSimulationCoverage.status == .pending
            && game.world.physicalSimulationCoverage.deduplicatedChunkCount == 270
            && game.world.physicalSimulationCoverage.generationRequestsThisTick == 18
            && diagnostics.totalGenerationJobsInFlight == 24
            && diagnostics.agentGenerationJobsInFlight == 18
            && diagnostics.playerGenerationJobsInFlight == 6
    )

    var generated = Set<PhysicalSimulationChunk>()
    var convergence = PhysicalSimulationCoveragePlanner.makeSnapshot(
        request: .active(separated),
        isChunkReady: { generated.contains(PhysicalSimulationChunk(x: $0, z: $1)) }
    )
    var successfulGenerationWaves = 0
    while convergence.status == .pending {
        for position in convergence.unavailableChunks.prefix(
            PhysicalSimulationCoverageContract
                .maximumAgentGenerationJobsInFlight
        ) {
            generated.insert(position)
        }
        successfulGenerationWaves += 1
        convergence = PhysicalSimulationCoveragePlanner.makeSnapshot(
            request: .active(separated),
            isChunkReady: {
                generated.contains(PhysicalSimulationChunk(x: $0, z: $1))
            }
        )
    }
    check(
        "static maximum coverage converges in bounded successful generation waves",
        convergence.status == .ready
            && convergence.readyChunks.count == 270
            && successfulGenerationWaves == 15
    )

    let refusalID = "ps01-i03-generation-refusal"
    let refusal = GameCore()
    refusal.db.deleteWorld(refusalID)
    guard refusal.db.putWorld(coverageGameRecord(refusalID)) else {
        check("coverage generation refusal fixture installs", false)
        return
    }
    refusal.loadWorld(refusalID)
    refusal.world.randomTickSpeed = 0
    refusal.physicalSimulationCoverageProvider = { _ in
        .active([PhysicalSimulationCoverageRoot(
            id: "refused_root", chunkX: 100, chunkZ: 100
        )])
    }
    refusal.testingPhysicalSimulationCoverageRequestRefusal = { _, _, _ in true }
    _ = refusal.frame(dtMs: TICK_MS)
    check(
        "generation refusal is explicit and fail-closed",
        refusal.world.physicalSimulationCoverage.status == .refused
            && refusal.world.physicalSimulationCoverage.refusedChunks.count == 9
            && refusal.world.physicalSimulationCoverage.reason
                == "coverage generation request refused"
    )
}

private func coveragePerformanceRoots(
    count: Int,
    separated: Bool
) -> [PhysicalSimulationCoverageRoot] {
    (0..<count).map { index in
        PhysicalSimulationCoverageRoot(
            id: String(format: "physical_%02d", index),
            chunkX: separated ? index * 3 : 0,
            chunkZ: 0
        )
    }
}

private func coveragePerformanceCase(
    count: Int,
    seed: UInt32,
    separated: Bool
) -> (snapshot: PhysicalSimulationCoverageSnapshot, averageMs: Double) {
    let world = World(dim: .overworld, seed: seed)
    world.randomTickSpeed = 3
    world.gameRules["doMobSpawning"] = 0
    let roots = coveragePerformanceRoots(count: count, separated: separated)
    let plan = PhysicalSimulationCoveragePlanner.makeSnapshot(
        request: .active(roots),
        isChunkReady: { _, _ in true }
    )
    for chunk in plan.coveredChunks {
        _ = coverageReadyChunk(world, chunk.x, chunk.z)
    }
    world.applyPhysicalSimulationCoverage(.active(roots))
    let start = DispatchTime.now().uptimeNanoseconds
    let tickCount = 8
    for _ in 0..<tickCount { world.tick() }
    let elapsed = DispatchTime.now().uptimeNanoseconds - start
    return (
        world.physicalSimulationCoverage,
        Double(elapsed) / 1_000_000 / Double(tickCount)
    )
}

func runPebbleCorePhysicalSimulationCoveragePerformanceSmoke() {
    section("PS01 Increment 03 bounded performance")
    for seed: UInt32 in [46, 887] {
        for count in [20, 24, 30] {
            let clustered = coveragePerformanceCase(
                count: count, seed: seed, separated: false
            )
            let separated = coveragePerformanceCase(
                count: count, seed: seed, separated: true
            )
            let valid = clustered.snapshot.status == .ready
                && clustered.snapshot.deduplicatedChunkCount == 9
                && separated.snapshot.status == .ready
                && separated.snapshot.deduplicatedChunkCount == count * 9
                && separated.snapshot.deduplicatedChunkCount
                    <= PhysicalSimulationCoverageContract.maximumCoveredChunks
            check(
                "bounded coverage performance \(count) founders seed \(seed)",
                valid
            )
            print(String(
                format: "PS01_I03_PERF seed=%u founders=%d "
                    + "clusteredChunks=%d clusteredDedup=%.5f clusteredTickMs=%.3f "
                    + "separatedChunks=%d separatedDedup=%.5f separatedTickMs=%.3f",
                seed,
                count,
                clustered.snapshot.deduplicatedChunkCount,
                clustered.snapshot.deduplicationRatio,
                clustered.averageMs,
                separated.snapshot.deduplicatedChunkCount,
                separated.snapshot.deduplicationRatio,
                separated.averageMs
            ))
        }
    }
}

private func runCoverageRandomTickDedupProofs() {
    let single = coverageAgentRandomDigest(
        cameraPath: [(100, 100), (100, 100)]
    )
    let world = World(dim: .nether, seed: 46)
    world.simDistance = 0
    world.randomTickSpeed = 3
    for z in -1...1 {
        for x in -1...2 {
            _ = coverageReadyChunk(
                world,
                x,
                z,
                randomTickBlock: x == 0 && z == 0 ? cell(B.wheat) : nil
            )
        }
    }
    _ = coverageReadyChunk(world, 100, 100, randomTickBlock: cell(B.wheat))
    world.applyPhysicalSimulationCoverage(
        .active(coverageRoots([(0, 0), (1, 0)]))
    )
    let blockID = Int(B.wheat)
    let previous = randomTickHandlers[blockID]
    var relevantEvents = 0
    randomTickHandlers[blockID] = { _, x, _, z, _ in
        if floorDiv(x, CHUNK_W) == 0 && floorDiv(z, CHUNK_W) == 0 {
            relevantEvents += 1
        }
    }
    defer { randomTickHandlers[blockID] = previous }
    for _ in 0..<2 {
        world.simCenterX = 100
        world.simCenterZ = 100
        world.tick()
    }
    check(
        "overlapping roots do not double-random-tick covered targets",
        relevantEvents == single.eventCount
    )
}

func runPebbleCorePhysicalSimulationCoverageFullSmoke() {
    runPebbleCorePhysicalSimulationCoverageCheckpointSmoke()
    section("PS01 Increment 03 physical scheduling and lifecycle")
    runCoverageRandomTickDedupProofs()
    runCoverageScheduledTickProofs()
    runCoverageBlockEntityProofs()
    runCoverageEntityProofs()
    runCoverageGenerationFairnessProofs()
}

func runPebbleCorePhysicalSimulationCoverageCheckpointSmoke() {
    section("PS01 Increment 03 physical coverage checkpoint")

    do {
        let world = World(dim: .nether, seed: 887)
        world.simDistance = 0
        world.randomTickSpeed = 3
        let chunk = coverageReadyChunk(world, 0, 0)
        var expectedRNG = world.rng
        for _ in 0..<(chunk.sections * world.randomTickSpeed * 3) {
            _ = expectedRNG.next()
        }
        world.applyPhysicalSimulationCoverage(.inactive)
        world.tick()
        check(
            "empty-agent coverage preserves exact legacy RNG path",
            world.physicalSimulationCoverage == .inactive
                && world.rng == expectedRNG
                && world.time == 1
        )
    }

    let near = coverageAgentRandomDigest(
        cameraPath: [(0, 0), (0, 0), (0, 0), (0, 0)]
    )
    check(
        "one agent near player has ready bounded opportunity",
        near.snapshot.status == .ready
            && near.snapshot.roots.count == 1
            && near.snapshot.deduplicatedChunkCount == 9
            && near.eventCount == 12
    )

    let far = coverageAgentRandomDigest(
        cameraPath: [(100, 100), (100, 100), (100, 100), (100, 100)]
    )
    check(
        "one agent continues with player outside simulation distance",
        far.snapshot.status == .ready
            && far.eventCount == near.eventCount
            && far.digest == near.digest,
        "near=\(near.digest) far=\(far.digest)"
    )

    let movedCamera = coverageAgentRandomDigest(
        cameraPath: [(0, 0), (100, 100), (-100, 100), (0, 0)]
    )
    check(
        "different camera path preserves covered result",
        movedCamera.eventCount == near.eventCount
            && movedCamera.digest == near.digest,
        "near=\(near.digest) moved=\(movedCamera.digest)"
    )

    let overlap = PhysicalSimulationCoveragePlanner.makeSnapshot(
        request: .active(coverageRoots([(0, 0), (1, 0)])),
        isChunkReady: { _, _ in true }
    )
    check(
        "overlapping roots union to one physical chunk set",
        overlap.status == .ready
            && overlap.rootChunkClaims == 18
            && overlap.deduplicatedChunkCount == 12
            && overlap.overlapSavings == 6
    )

    let orderedRoots = coverageRoots([(7, -3), (0, 0), (-4, 11)])
    let forward = PhysicalSimulationCoveragePlanner.makeSnapshot(
        request: .active(orderedRoots),
        isChunkReady: { _, _ in true }
    )
    let reversed = PhysicalSimulationCoveragePlanner.makeSnapshot(
        request: .active(orderedRoots.reversed()),
        isChunkReady: { _, _ in true }
    )
    check(
        "root enumeration reversal preserves set order and digest",
        forward == reversed && forward.stableDigest == reversed.stableDigest
    )

    let originalRoot = PhysicalSimulationCoveragePlanner.makeSnapshot(
        request: .active(coverageRoots([(0, 0)])),
        isChunkReady: { _, _ in true }
    )
    let movedRoot = PhysicalSimulationCoveragePlanner.makeSnapshot(
        request: .active(coverageRoots([(3, -2)])),
        isChunkReady: { _, _ in true }
    )
    check(
        "moving a root across chunks replaces old technical coverage",
        originalRoot.status == .ready
            && movedRoot.status == .ready
            && originalRoot.covers(chunkX: 0, chunkZ: 0)
            && !originalRoot.covers(chunkX: 3, chunkZ: -2)
            && movedRoot.covers(chunkX: 3, chunkZ: -2)
            && !movedRoot.covers(chunkX: 0, chunkZ: 0)
    )

    let duplicateRoot = PhysicalSimulationCoverageRoot(
        id: "duplicate_physical_identity",
        chunkX: 0,
        chunkZ: 0
    )
    let duplicate = PhysicalSimulationCoveragePlanner.makeSnapshot(
        request: .active([duplicateRoot, duplicateRoot]),
        isChunkReady: { _, _ in true }
    )
    check(
        "duplicate physical root identity is refused fail-closed",
        duplicate.status == .refused
            && duplicate.roots.isEmpty
            && duplicate.reason == "duplicate coverage root identity"
    )

    let pending = PhysicalSimulationCoveragePlanner.makeSnapshot(
        request: .active(coverageRoots([(0, 0)])),
        isChunkReady: { x, z in x == 0 && z == 0 }
    )
    check(
        "incomplete coverage is unavailable rather than absent",
        pending.status == .pending
            && pending.readyChunks.count == 1
            && pending.unavailableChunks.count == 8
            && pending.covers(chunkX: 1, chunkZ: 1)
            && pending.reason == "required coverage unavailable"
    )

    do {
        let world = World(dim: .nether, seed: 887)
        world.simDistance = 0
        world.randomTickSpeed = 3
        var center: Chunk?
        for z in -1...1 {
            for x in -1...1 {
                let chunk = coverageReadyChunk(world, x, z)
                if x == 0 && z == 0 { center = chunk }
            }
        }
        world.applyPhysicalSimulationCoverage(
            .active(coverageRoots([(0, 0)]))
        )
        world.applyPhysicalSimulationCoverage(.inactive)
        var expectedRNG = world.rng
        for _ in 0..<((center?.sections ?? 0) * world.randomTickSpeed * 3) {
            _ = expectedRNG.next()
        }
        world.tick()
        check(
            "removing last root returns World to exact legacy mode",
            world.physicalSimulationCoverage == .inactive
                && world.rng == expectedRNG
        )
    }

    runBoundedCoveragePathProofs()
    runCoverageWeatherProofs()

    print(
        "  coverage-checkpoint digest near=\(near.digest) "
            + "far=\(far.digest) moved=\(movedCamera.digest)"
    )
}
