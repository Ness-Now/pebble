import PebbleCore

struct ScenarioResult {
    var chunksTouched: Int?
    var chunkRadius: Int?
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
        let chunkRadius = 0
        let chunksTouched = world.getChunk(0, 0) == nil ? 0 : 1
        _ = world.getChunkAt(0, 0)
        return ScenarioResult(chunksTouched: chunksTouched, chunkRadius: chunkRadius)
    default:
        return ScenarioResult()
    }
}
