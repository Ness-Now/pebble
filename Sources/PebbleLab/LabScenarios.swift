import PebbleCore

struct ScenarioResult {
    var chunksTouched: Int?
    var chunkRadius: Int?
    var originChunkReady: Bool?
    var centerHeight: Int?
    var centerSurfaceY: Int?
    var nonAirBlocks: Int?
    var expectedChunks: Int?
    var readyChunks: Int?
    var nonAirBlocksTotal: Int?
    var adoptedChunks: [AdoptedChunk] = []
    var agents: [LabAgent] = []
}

struct AdoptedChunk {
    let x: Int
    let z: Int
    let chunksTouched: Int
    let originChunkReady: Bool
    let ready: Bool
    let centerHeight: Int
    let centerSurfaceY: Int
    let nonAirBlocks: Int
}

let supportedScenarios = ["empty", "chunk_smoke", "agent_smoke"]

func validateScenario(_ scenario: String) {
    guard supportedScenarios.contains(scenario) else {
        fail("unsupported scenario: \(scenario). Currently supported: empty, chunk_smoke, agent_smoke")
    }
}

func prepareScenario(_ options: Options, world: World) -> ScenarioResult {
    let scenario = options.scenario

    switch scenario {
    case "chunk_smoke", "agent_smoke":
        registerAllBlocks()
        registerAllBiomes()

        let chunkRadius = scenario == "agent_smoke" && !options.chunkRadiusProvided ? 1 : options.chunkRadius
        var adoptedChunks: [AdoptedChunk] = []
        var nonAirBlocksTotal = 0

        for cz in -chunkRadius...chunkRadius {
            for cx in -chunkRadius...chunkRadius {
                let generated = generateChunk(.overworld, world.seed, cx, cz)
                let chunk = Chunk(cx: cx, cz: cz, minY: world.info.minY, height: world.info.height)

                chunk.blocks = generated.blocks
                chunk.biomes = generated.biomes
                chunk.buildHeightmap()
                chunk.scanSpecials()

                world.setChunk(chunk)
                world.light.initChunkLight(chunk)

                let nonAirBlocks = chunk.blocks.reduce(0) { count, cell in
                    count + (cell == 0 ? 0 : 1)
                }
                nonAirBlocksTotal += nonAirBlocks
                let centerX = cx * 16 + 8
                let centerZ = cz * 16 + 8
                adoptedChunks.append(AdoptedChunk(
                    x: cx,
                    z: cz,
                    chunksTouched: world.chunks.count,
                    originChunkReady: world.isChunkReady(0, 0),
                    ready: world.isChunkReady(cx, cz),
                    centerHeight: world.heightAt(centerX, centerZ),
                    centerSurfaceY: world.surfaceY(centerX, centerZ),
                    nonAirBlocks: nonAirBlocks
                ))
            }
        }

        let expectedChunks = (chunkRadius * 2 + 1) * (chunkRadius * 2 + 1)
        var readyChunks = 0
        for cz in -chunkRadius...chunkRadius {
            for cx in -chunkRadius...chunkRadius where world.isChunkReady(cx, cz) {
                readyChunks += 1
            }
        }

        var result = ScenarioResult(
            chunksTouched: world.chunks.count,
            chunkRadius: chunkRadius,
            originChunkReady: world.isChunkReady(0, 0),
            centerHeight: world.heightAt(8, 8),
            centerSurfaceY: world.surfaceY(8, 8),
            nonAirBlocks: world.getChunk(0, 0)?.blocks.reduce(0) { count, cell in
                count + (cell == 0 ? 0 : 1)
            },
            expectedChunks: expectedChunks,
            readyChunks: readyChunks,
            nonAirBlocksTotal: nonAirBlocksTotal,
            adoptedChunks: adoptedChunks
        )
        if scenario == "agent_smoke" {
            result.agents = [
                makeLabAgent(id: "agent_0", x: 8, z: 8, world: world),
                makeLabAgent(id: "agent_1", x: 12, z: 8, world: world)
            ]
        }
        return result
    default:
        return ScenarioResult()
    }
}

func makeLabAgent(id: String, x: Int, z: Int, world: World) -> LabAgent {
    var spawnY = world.heightAt(x, z) + 1
    while world.getBlock(x, spawnY, z) != 0 && spawnY < world.info.minY + world.info.height {
        spawnY += 1
    }
    return LabAgent(id: id, x: x, y: spawnY, z: z)
}

func makeWorldSnapshot(
    options: Options,
    world: World,
    result: ScenarioResult,
    ticksCompleted: Int
) -> WorldSnapshot? {
    guard (options.scenario == "chunk_smoke" || options.scenario == "agent_smoke"),
          let chunkRadius = result.chunkRadius,
          let expectedChunks = result.expectedChunks,
          let readyChunks = result.readyChunks,
          let originChunkReady = result.originChunkReady,
          let centerHeight = result.centerHeight,
          let centerSurfaceY = result.centerSurfaceY
    else { return nil }

    let chunks = result.adoptedChunks
        .sorted {
            if $0.x != $1.x { return $0.x < $1.x }
            return $0.z < $1.z
        }
        .map {
            SnapshotChunk(
                cx: $0.x,
                cz: $0.z,
                ready: $0.ready,
                centerHeight: $0.centerHeight,
                centerSurfaceY: $0.centerSurfaceY,
                nonAirBlocks: $0.nonAirBlocks
            )
        }

    return WorldSnapshot(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        worldTime: world.time,
        chunkRadius: chunkRadius,
        expectedChunks: expectedChunks,
        readyChunks: readyChunks,
        originChunkReady: originChunkReady,
        center: SnapshotCenter(x: 8, z: 8, height: centerHeight, surfaceY: centerSurfaceY),
        chunks: chunks
    )
}
