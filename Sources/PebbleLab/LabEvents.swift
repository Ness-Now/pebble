import Foundation

struct RunEvent: Encodable {
    let type: String
    let event: String?
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
    let agentId: String?
    let otherAgentId: String?
    let agentType: String?
    let x: Int?
    let y: Int?
    let z: Int?
    let fromX: Int?
    let fromY: Int?
    let fromZ: Int?
    let toX: Int?
    let toY: Int?
    let toZ: Int?
    let state: String?
    let hunger: Double?
    let fatigue: Double?
    let curiosity: Double?
    let safety: Double?
    let agents: Int?
    let chunkReady: Bool?
    let surfaceY: Int?
    let height: Int?
    let blockBelow: Int?
    let blockAtFeet: Int?
    let action: String?
    let reason: String?
    let item: String?
    let delta: Int?
    let count: Int?
    let memoryType: String?
    let importance: Double?
    let summary: String?
    let effect: String?
    let hungerBefore: Double?
    let hungerAfter: Double?
    let fatigueBefore: Double?
    let fatigueAfter: Double?
    let curiosityBefore: Double?
    let curiosityAfter: Double?
    let safetyBefore: Double?
    let safetyAfter: Double?
    let fearBefore: Int?
    let fearAfter: Int?
    let stateBefore: String?
    let stateAfter: String?
    let dx: Int?
    let dy: Int?
    let dz: Int?
    let distanceManhattan: Int?
    let fromGoal: String?
    let toGoal: String?
    let goal: String?
    let urgency: Int?
    let fromValue: Int?
    let toValue: Int?
    let homeX: Int?
    let homeY: Int?
    let homeZ: Int?
    let distanceFromHomeBefore: Int?
    let distanceFromHomeAfter: Int?
    let distanceReducedTowardHome: Int?

    init(
        type: String,
        tick: Int,
        event: String? = nil,
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
        path: String? = nil,
        agentId: String? = nil,
        otherAgentId: String? = nil,
        agentType: String? = nil,
        x: Int? = nil,
        y: Int? = nil,
        z: Int? = nil,
        fromX: Int? = nil,
        fromY: Int? = nil,
        fromZ: Int? = nil,
        toX: Int? = nil,
        toY: Int? = nil,
        toZ: Int? = nil,
        state: String? = nil,
        hunger: Double? = nil,
        fatigue: Double? = nil,
        curiosity: Double? = nil,
        safety: Double? = nil,
        agents: Int? = nil,
        chunkReady: Bool? = nil,
        surfaceY: Int? = nil,
        height: Int? = nil,
        blockBelow: Int? = nil,
        blockAtFeet: Int? = nil,
        action: String? = nil,
        reason: String? = nil,
        item: String? = nil,
        delta: Int? = nil,
        count: Int? = nil,
        memoryType: String? = nil,
        importance: Double? = nil,
        summary: String? = nil,
        effect: String? = nil,
        hungerBefore: Double? = nil,
        hungerAfter: Double? = nil,
        fatigueBefore: Double? = nil,
        fatigueAfter: Double? = nil,
        curiosityBefore: Double? = nil,
        curiosityAfter: Double? = nil,
        safetyBefore: Double? = nil,
        safetyAfter: Double? = nil,
        fearBefore: Int? = nil,
        fearAfter: Int? = nil,
        stateBefore: String? = nil,
        stateAfter: String? = nil,
        dx: Int? = nil,
        dy: Int? = nil,
        dz: Int? = nil,
        distanceManhattan: Int? = nil,
        fromGoal: String? = nil,
        toGoal: String? = nil,
        goal: String? = nil,
        urgency: Int? = nil,
        fromValue: Int? = nil,
        toValue: Int? = nil,
        homeX: Int? = nil,
        homeY: Int? = nil,
        homeZ: Int? = nil,
        distanceFromHomeBefore: Int? = nil,
        distanceFromHomeAfter: Int? = nil,
        distanceReducedTowardHome: Int? = nil
    ) {
        self.type = type
        self.event = event
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
        self.agentId = agentId
        self.otherAgentId = otherAgentId
        self.agentType = agentType
        self.x = x
        self.y = y
        self.z = z
        self.fromX = fromX
        self.fromY = fromY
        self.fromZ = fromZ
        self.toX = toX
        self.toY = toY
        self.toZ = toZ
        self.state = state
        self.hunger = hunger
        self.fatigue = fatigue
        self.curiosity = curiosity
        self.safety = safety
        self.agents = agents
        self.chunkReady = chunkReady
        self.surfaceY = surfaceY
        self.height = height
        self.blockBelow = blockBelow
        self.blockAtFeet = blockAtFeet
        self.action = action
        self.reason = reason
        self.item = item
        self.delta = delta
        self.count = count
        self.memoryType = memoryType
        self.importance = importance
        self.summary = summary
        self.effect = effect
        self.hungerBefore = hungerBefore
        self.hungerAfter = hungerAfter
        self.fatigueBefore = fatigueBefore
        self.fatigueAfter = fatigueAfter
        self.curiosityBefore = curiosityBefore
        self.curiosityAfter = curiosityAfter
        self.safetyBefore = safetyBefore
        self.safetyAfter = safetyAfter
        self.fearBefore = fearBefore
        self.fearAfter = fearAfter
        self.stateBefore = stateBefore
        self.stateAfter = stateAfter
        self.dx = dx
        self.dy = dy
        self.dz = dz
        self.distanceManhattan = distanceManhattan
        self.fromGoal = fromGoal
        self.toGoal = toGoal
        self.goal = goal
        self.urgency = urgency
        self.fromValue = fromValue
        self.toValue = toValue
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.distanceFromHomeBefore = distanceFromHomeBefore
        self.distanceFromHomeAfter = distanceFromHomeAfter
        self.distanceReducedTowardHome = distanceReducedTowardHome
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
