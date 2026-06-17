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
}

struct AdoptedChunk {
    let x: Int
    let z: Int
    let chunksTouched: Int
    let originChunkReady: Bool
    let nonAirBlocks: Int
}

let supportedScenarios = ["empty", "chunk_smoke"]

func validateScenario(_ scenario: String) {
    guard supportedScenarios.contains(scenario) else {
        fail("unsupported scenario: \(scenario). Currently supported: empty, chunk_smoke")
    }
}

func prepareScenario(_ options: Options, world: World) -> ScenarioResult {
    let scenario = options.scenario

    switch scenario {
    case "chunk_smoke":
        registerAllBlocks()
        registerAllBiomes()

        let chunkRadius = options.chunkRadius
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
                adoptedChunks.append(AdoptedChunk(
                    x: cx,
                    z: cz,
                    chunksTouched: world.chunks.count,
                    originChunkReady: world.isChunkReady(0, 0),
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

        return ScenarioResult(
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
    default:
        return ScenarioResult()
    }
}
