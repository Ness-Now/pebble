import Foundation

struct RunEvent: Encodable {
    let type: String
    let tick: Int
    let scenario: String?
    let seed: UInt32?
    let ticksRequested: Int?
    let worldTime: Int?
    let success: Bool?
    let chunksTouched: Int?
    let chunkRadius: Int?
    let chunkX: Int?
    let chunkZ: Int?
    let originChunkReady: Bool?
    let centerHeight: Int?
    let centerSurfaceY: Int?
    let nonAirBlocks: Int?
    let expectedChunks: Int?
    let readyChunks: Int?
    let nonAirBlocksTotal: Int?
    let chunks: Int?
    let path: String?

    init(
        type: String,
        tick: Int,
        scenario: String? = nil,
        seed: UInt32? = nil,
        ticksRequested: Int? = nil,
        worldTime: Int? = nil,
        success: Bool? = nil,
        chunksTouched: Int? = nil,
        chunkRadius: Int? = nil,
        chunkX: Int? = nil,
        chunkZ: Int? = nil,
        originChunkReady: Bool? = nil,
        centerHeight: Int? = nil,
        centerSurfaceY: Int? = nil,
        nonAirBlocks: Int? = nil,
        expectedChunks: Int? = nil,
        readyChunks: Int? = nil,
        nonAirBlocksTotal: Int? = nil,
        chunks: Int? = nil,
        path: String? = nil
    ) {
        self.type = type
        self.tick = tick
        self.scenario = scenario
        self.seed = seed
        self.ticksRequested = ticksRequested
        self.worldTime = worldTime
        self.success = success
        self.chunksTouched = chunksTouched
        self.chunkRadius = chunkRadius
        self.chunkX = chunkX
        self.chunkZ = chunkZ
        self.originChunkReady = originChunkReady
        self.centerHeight = centerHeight
        self.centerSurfaceY = centerSurfaceY
        self.nonAirBlocks = nonAirBlocks
        self.expectedChunks = expectedChunks
        self.readyChunks = readyChunks
        self.nonAirBlocksTotal = nonAirBlocksTotal
        self.chunks = chunks
        self.path = path
    }
}

func encodeEventLine(_ event: RunEvent) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(event)
    guard let line = String(data: data, encoding: .utf8) else {
        throw CocoaError(.fileWriteInapplicableStringEncoding)
    }
    return line + "\n"
}
