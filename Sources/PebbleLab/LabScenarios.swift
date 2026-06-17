import PebbleCore

struct ScenarioResult {
    var chunksTouched: Int?
    var chunkRadius: Int?
    var originChunkReady: Bool?
    var centerHeight: Int?
    var centerSurfaceY: Int?
    var nonAirBlocks: Int?
}

let supportedScenarios = ["empty", "chunk_smoke"]

func validateScenario(_ scenario: String) {
    guard supportedScenarios.contains(scenario) else {
        fail("unsupported scenario: \(scenario). Currently supported: empty, chunk_smoke")
    }
}

func prepareScenario(_ scenario: String, world: World) -> ScenarioResult {
    switch scenario {
    case "chunk_smoke":
        registerAllBlocks()
        registerAllBiomes()

        let chunkRadius = 0
        let cx = 0
        let cz = 0
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

        return ScenarioResult(
            chunksTouched: world.chunks.count,
            chunkRadius: chunkRadius,
            originChunkReady: world.isChunkReady(cx, cz),
            centerHeight: world.heightAt(8, 8),
            centerSurfaceY: world.surfaceY(8, 8),
            nonAirBlocks: nonAirBlocks
        )
    default:
        return ScenarioResult()
    }
}
