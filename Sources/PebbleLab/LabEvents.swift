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
    let physicalId: String?
    let coreEntityId: Int?
    let kind: String?
    let moves: Int?
    let totalDistance: Int?
    let finalDivergence: Int?
    let agentsMoved: Int?
    let maxDivergence: Int?
    let relation: String?
    let loaded: Bool?
    let ready: Bool?
    let blockId: Int?
    let meta: Int?
    let blockName: String?
    let observations: Int?
    let loadedObservations: Int?
    let readyObservations: Int?
    let uniqueChunks: Int?
    let distinctBlockIds: Int?
    let radius: Int?
    let cellsPlanned: Int?
    let cellsObserved: Int?
    let loadedCells: Int?
    let readyCells: Int?
    let cellsClassified: Int?
    let unknownCells: Int?
    let airCells: Int?
    let solidCells: Int?
    let liquidCells: Int?
    let plantLikeCells: Int?
    let otherCells: Int?
    let fixtures: Int?
    let passed: Int?
    let failed: Int?
    let unknownCases: Int?
    let airCases: Int?
    let solidCases: Int?
    let liquidCases: Int?
    let plantLikeCases: Int?
    let otherCases: Int?
    let cellsEvaluated: Int?
    let traversableCells: Int?
    let blockedCells: Int?
    let unsupportedCells: Int?
    let unsafeCells: Int?
    let occupiedVerticalSpaceCells: Int?
    let columns: Int?
    let pathsFound: Int?
    let pathsNotFound: Int?
    let invalidStarts: Int?
    let invalidGoals: Int?
    let searchLimitReached: Int?
    let unknown: Int?
    let nodes: Int?
    let traversableNodes: Int?
    let unsafeNodes: Int?
    let unknownNodes: Int?
    let startStatus: String?
    let goalStatus: String?
    let pathStatus: String?
    let pathLength: Int?
    let visited: Int?
    let candidates: Int?
    let selectedCandidateIndex: Int?
    let selectedSeed: UInt32?
    let agentX: Int?
    let agentZ: Int?
    let stepsPlanned: Int?
    let stepsExecuted: Int?
    let reachedGoals: Int?
    let invalidPaths: Int?
    let reachedGoal: Bool?
    let finalStatus: String?
    let liveAgentDisplaced: Bool?
    let collisionPerformed: Bool?
    let mutationPerformed: Bool?

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
        distanceReducedTowardHome: Int? = nil,
        physicalId: String? = nil,
        coreEntityId: Int? = nil,
        kind: String? = nil,
        moves: Int? = nil,
        totalDistance: Int? = nil,
        finalDivergence: Int? = nil,
        agentsMoved: Int? = nil,
        maxDivergence: Int? = nil,
        relation: String? = nil,
        loaded: Bool? = nil,
        ready: Bool? = nil,
        blockId: Int? = nil,
        meta: Int? = nil,
        blockName: String? = nil,
        observations: Int? = nil,
        loadedObservations: Int? = nil,
        readyObservations: Int? = nil,
        uniqueChunks: Int? = nil,
        distinctBlockIds: Int? = nil,
        radius: Int? = nil,
        cellsPlanned: Int? = nil,
        cellsObserved: Int? = nil,
        loadedCells: Int? = nil,
        readyCells: Int? = nil,
        cellsClassified: Int? = nil,
        unknownCells: Int? = nil,
        airCells: Int? = nil,
        solidCells: Int? = nil,
        liquidCells: Int? = nil,
        plantLikeCells: Int? = nil,
        otherCells: Int? = nil,
        fixtures: Int? = nil,
        passed: Int? = nil,
        failed: Int? = nil,
        unknownCases: Int? = nil,
        airCases: Int? = nil,
        solidCases: Int? = nil,
        liquidCases: Int? = nil,
        plantLikeCases: Int? = nil,
        otherCases: Int? = nil,
        cellsEvaluated: Int? = nil,
        traversableCells: Int? = nil,
        blockedCells: Int? = nil,
        unsupportedCells: Int? = nil,
        unsafeCells: Int? = nil,
        occupiedVerticalSpaceCells: Int? = nil,
        columns: Int? = nil,
        pathsFound: Int? = nil,
        pathsNotFound: Int? = nil,
        invalidStarts: Int? = nil,
        invalidGoals: Int? = nil,
        searchLimitReached: Int? = nil,
        unknown: Int? = nil,
        nodes: Int? = nil,
        traversableNodes: Int? = nil,
        unsafeNodes: Int? = nil,
        unknownNodes: Int? = nil,
        startStatus: String? = nil,
        goalStatus: String? = nil,
        pathStatus: String? = nil,
        pathLength: Int? = nil,
        visited: Int? = nil,
        candidates: Int? = nil,
        selectedCandidateIndex: Int? = nil,
        selectedSeed: UInt32? = nil,
        agentX: Int? = nil,
        agentZ: Int? = nil,
        stepsPlanned: Int? = nil,
        stepsExecuted: Int? = nil,
        reachedGoals: Int? = nil,
        invalidPaths: Int? = nil,
        reachedGoal: Bool? = nil,
        finalStatus: String? = nil,
        liveAgentDisplaced: Bool? = nil,
        collisionPerformed: Bool? = nil,
        mutationPerformed: Bool? = nil
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
        self.physicalId = physicalId
        self.coreEntityId = coreEntityId
        self.kind = kind
        self.moves = moves
        self.totalDistance = totalDistance
        self.finalDivergence = finalDivergence
        self.agentsMoved = agentsMoved
        self.maxDivergence = maxDivergence
        self.relation = relation
        self.loaded = loaded
        self.ready = ready
        self.blockId = blockId
        self.meta = meta
        self.blockName = blockName
        self.observations = observations
        self.loadedObservations = loadedObservations
        self.readyObservations = readyObservations
        self.uniqueChunks = uniqueChunks
        self.distinctBlockIds = distinctBlockIds
        self.radius = radius
        self.cellsPlanned = cellsPlanned
        self.cellsObserved = cellsObserved
        self.loadedCells = loadedCells
        self.readyCells = readyCells
        self.cellsClassified = cellsClassified
        self.unknownCells = unknownCells
        self.airCells = airCells
        self.solidCells = solidCells
        self.liquidCells = liquidCells
        self.plantLikeCells = plantLikeCells
        self.otherCells = otherCells
        self.fixtures = fixtures
        self.passed = passed
        self.failed = failed
        self.unknownCases = unknownCases
        self.airCases = airCases
        self.solidCases = solidCases
        self.liquidCases = liquidCases
        self.plantLikeCases = plantLikeCases
        self.otherCases = otherCases
        self.cellsEvaluated = cellsEvaluated
        self.traversableCells = traversableCells
        self.blockedCells = blockedCells
        self.unsupportedCells = unsupportedCells
        self.unsafeCells = unsafeCells
        self.occupiedVerticalSpaceCells = occupiedVerticalSpaceCells
        self.columns = columns
        self.pathsFound = pathsFound
        self.pathsNotFound = pathsNotFound
        self.invalidStarts = invalidStarts
        self.invalidGoals = invalidGoals
        self.searchLimitReached = searchLimitReached
        self.unknown = unknown
        self.nodes = nodes
        self.traversableNodes = traversableNodes
        self.unsafeNodes = unsafeNodes
        self.unknownNodes = unknownNodes
        self.startStatus = startStatus
        self.goalStatus = goalStatus
        self.pathStatus = pathStatus
        self.pathLength = pathLength
        self.visited = visited
        self.candidates = candidates
        self.selectedCandidateIndex = selectedCandidateIndex
        self.selectedSeed = selectedSeed
        self.agentX = agentX
        self.agentZ = agentZ
        self.stepsPlanned = stepsPlanned
        self.stepsExecuted = stepsExecuted
        self.reachedGoals = reachedGoals
        self.invalidPaths = invalidPaths
        self.reachedGoal = reachedGoal
        self.finalStatus = finalStatus
        self.liveAgentDisplaced = liveAgentDisplaced
        self.collisionPerformed = collisionPerformed
        self.mutationPerformed = mutationPerformed
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
