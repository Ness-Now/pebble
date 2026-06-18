import Foundation

struct RunConfig: Encodable {
    let scenario: String
    let seed: UInt32
    let ticks: Int
    let eventRate: Int
    let logWorldTicks: Bool
    let outPath: String?
}

struct RunSuccessCriteria: Encodable {
    let ticksCompleted: Bool
    let agentsSpawned: Bool
    let agentTicksRecorded: Bool
}

struct RegressionReport: Encodable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: RegressionSummary
    let checks: [RegressionCheck]
    let keyMetrics: RegressionKeyMetrics
    let notes: [String]
}

struct RegressionSummary: Encodable {
    let ticksRequested: Int
    let ticksCompleted: Int
    let expectedAgents: Int
    let actualAgents: Int
    let checksPassed: Int
    let checksFailed: Int
}

struct RegressionCheck: Encodable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

struct RegressionKeyMetrics: Encodable {
    let worldTime: Int
    let agentTicks: Int?
    let agentsAlive: Int?
    let agentMoves: Int?
    let nearbyAgentObservations: Int?
    let agentGoalChanges: Int?
    let eventsWritten: Int?
    let eventsSuppressed: Int?
}

struct RunMetrics: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksRequested: Int
    let ticksCompleted: Int
    let worldTime: Int
    let success: Bool
    let chunksTouched: Int?
    let chunkRadius: Int?

    let originChunkReady: Bool?
    let centerHeight: Int?
    let centerSurfaceY: Int?
    let nonAirBlocks: Int?
    let expectedChunks: Int?
    let readyChunks: Int?
    let nonAirBlocksTotal: Int?
    let agentCount: Int?
    let agentsSpawned: Int?
    let agentTicks: Int?
    let agentObservations: Int?
    let agentCurrentChunkReady: Bool?
    let agentSurfaceY: Int?
    let agentHeight: Int?
    let agentActions: Int?
    let agentLastAction: String?
    let agentMemoryEntries: Int?
    let agentLastMemoryType: String?
    let agentActionEffects: Int?
    let agentLastActionEffect: String?
    let nearbyAgentObservations: Int?
    let agentsWithNearbyAgents: Int?
    let agentGoalSelections: Int?
    let agentGoalChanges: Int?
    let goalsByKind: [String: Int]?
    let agentsAlive: Int?
    let averageHealth: Double?
    let averageFear: Double?
    let agentsWithHome: Int?
    let minHealth: Int?
    let maxFear: Int?
    let agentsWithInventory: Int?
    let totalInventoryItems: Int?
    let inventoryItemsByKind: [String: Int]?
    let agentMoves: Int?
    let agentsMoved: Int?
    let totalManhattanDistanceMoved: Int?
    let maxDistanceFromHome: Int?
    let averageDistanceFromHome: Double?
    let agentReturnHomeMoves: Int?
    let agentsMovedTowardHome: Int?
    let totalDistanceReducedTowardHome: Int?
    let agentsAtHome: Int?
    let agentsNearHome: Int?
    let eventsWritten: Int?
    let eventsSuppressed: Int?
    let eventRate: Int?
    let worldTickEventsWritten: Int?
    let worldTickEventsSuppressed: Int?
    let nearbyAgentEventsWritten: Int?
    let nearbyAgentEventsSuppressed: Int?
    let physicalAgentsSpawned: Int?
    let physicalAgentsTicked: Int?
    let agentsWithPhysicalPlaceholder: Int?
    let physicalBridgeLinks: Int?
    let physicalAgentsSynced: Int?
    let physicalSyncEvents: Int?
    let physicalSyncDistance: Int?
    let abstractPhysicalDivergence: Int?
    let maxAbstractPhysicalDivergence: Int?
    let coreEntitiesSpawned: Int?
    let coreEntitiesTicked: Int?
    let coreEntityLinks: Int?
    let coreEntitiesSynced: Int?
    let coreEntitySyncEvents: Int?
    let coreEntitySyncDistance: Int?
    let abstractCoreEntityDivergence: Int?
    let maxAbstractCoreEntityDivergence: Int?
    let worldEntitiesCount: Int?
    let physicalBehaviorTicks: Int?
    let physicalBehaviorMoves: Int?
    let physicalBehaviorCoreSyncs: Int?
    let physicalBehaviorTotalDistance: Int?
    let physicalBehaviorFinalDivergence: Int?
    let physicalBehaviorSuccess: Bool?
    let successCriteria: RunSuccessCriteria?

    init(
        scenario: String,
        seed: UInt32,
        ticksRequested: Int,
        ticksCompleted: Int,
        worldTime: Int,
        success: Bool,
        chunksTouched: Int? = nil,
        chunkRadius: Int? = nil,
        originChunkReady: Bool? = nil,
        centerHeight: Int? = nil,
        centerSurfaceY: Int? = nil,
        nonAirBlocks: Int? = nil,
        expectedChunks: Int? = nil,
        readyChunks: Int? = nil,
        nonAirBlocksTotal: Int? = nil,
        agentCount: Int? = nil,
        agentsSpawned: Int? = nil,
        agentTicks: Int? = nil,
        agentObservations: Int? = nil,
        agentCurrentChunkReady: Bool? = nil,
        agentSurfaceY: Int? = nil,
        agentHeight: Int? = nil,
        agentActions: Int? = nil,
        agentLastAction: String? = nil,
        agentMemoryEntries: Int? = nil,
        agentLastMemoryType: String? = nil,
        agentActionEffects: Int? = nil,
        agentLastActionEffect: String? = nil,
        nearbyAgentObservations: Int? = nil,
        agentsWithNearbyAgents: Int? = nil,
        agentGoalSelections: Int? = nil,
        agentGoalChanges: Int? = nil,
        goalsByKind: [String: Int]? = nil,
        agentsAlive: Int? = nil,
        averageHealth: Double? = nil,
        averageFear: Double? = nil,
        agentsWithHome: Int? = nil,
        minHealth: Int? = nil,
        maxFear: Int? = nil,
        agentsWithInventory: Int? = nil,
        totalInventoryItems: Int? = nil,
        inventoryItemsByKind: [String: Int]? = nil,
        agentMoves: Int? = nil,
        agentsMoved: Int? = nil,
        totalManhattanDistanceMoved: Int? = nil,
        maxDistanceFromHome: Int? = nil,
        averageDistanceFromHome: Double? = nil,
        agentReturnHomeMoves: Int? = nil,
        agentsMovedTowardHome: Int? = nil,
        totalDistanceReducedTowardHome: Int? = nil,
        agentsAtHome: Int? = nil,
        agentsNearHome: Int? = nil,
        eventsWritten: Int? = nil,
        eventsSuppressed: Int? = nil,
        eventRate: Int? = nil,
        worldTickEventsWritten: Int? = nil,
        worldTickEventsSuppressed: Int? = nil,
        nearbyAgentEventsWritten: Int? = nil,
        nearbyAgentEventsSuppressed: Int? = nil,
        physicalAgentsSpawned: Int? = nil,
        physicalAgentsTicked: Int? = nil,
        agentsWithPhysicalPlaceholder: Int? = nil,
        physicalBridgeLinks: Int? = nil,
        physicalAgentsSynced: Int? = nil,
        physicalSyncEvents: Int? = nil,
        physicalSyncDistance: Int? = nil,
        abstractPhysicalDivergence: Int? = nil,
        maxAbstractPhysicalDivergence: Int? = nil,
        coreEntitiesSpawned: Int? = nil,
        coreEntitiesTicked: Int? = nil,
        coreEntityLinks: Int? = nil,
        coreEntitiesSynced: Int? = nil,
        coreEntitySyncEvents: Int? = nil,
        coreEntitySyncDistance: Int? = nil,
        abstractCoreEntityDivergence: Int? = nil,
        maxAbstractCoreEntityDivergence: Int? = nil,
        worldEntitiesCount: Int? = nil,
        physicalBehaviorTicks: Int? = nil,
        physicalBehaviorMoves: Int? = nil,
        physicalBehaviorCoreSyncs: Int? = nil,
        physicalBehaviorTotalDistance: Int? = nil,
        physicalBehaviorFinalDivergence: Int? = nil,
        physicalBehaviorSuccess: Bool? = nil,
        successCriteria: RunSuccessCriteria? = nil
    ) {
        self.scenario = scenario
        self.seed = seed
        self.ticksRequested = ticksRequested
        self.ticksCompleted = ticksCompleted
        self.worldTime = worldTime
        self.success = success
        self.chunksTouched = chunksTouched
        self.chunkRadius = chunkRadius
        self.originChunkReady = originChunkReady
        self.centerHeight = centerHeight
        self.centerSurfaceY = centerSurfaceY
        self.nonAirBlocks = nonAirBlocks
        self.expectedChunks = expectedChunks
        self.readyChunks = readyChunks
        self.nonAirBlocksTotal = nonAirBlocksTotal
        self.agentCount = agentCount
        self.agentsSpawned = agentsSpawned
        self.agentTicks = agentTicks
        self.agentObservations = agentObservations
        self.agentCurrentChunkReady = agentCurrentChunkReady
        self.agentSurfaceY = agentSurfaceY
        self.agentHeight = agentHeight
        self.agentActions = agentActions
        self.agentLastAction = agentLastAction
        self.agentMemoryEntries = agentMemoryEntries
        self.agentLastMemoryType = agentLastMemoryType
        self.agentActionEffects = agentActionEffects
        self.agentLastActionEffect = agentLastActionEffect
        self.nearbyAgentObservations = nearbyAgentObservations
        self.agentsWithNearbyAgents = agentsWithNearbyAgents
        self.agentGoalSelections = agentGoalSelections
        self.agentGoalChanges = agentGoalChanges
        self.goalsByKind = goalsByKind
        self.agentsAlive = agentsAlive
        self.averageHealth = averageHealth
        self.averageFear = averageFear
        self.agentsWithHome = agentsWithHome
        self.minHealth = minHealth
        self.maxFear = maxFear
        self.agentsWithInventory = agentsWithInventory
        self.totalInventoryItems = totalInventoryItems
        self.inventoryItemsByKind = inventoryItemsByKind
        self.agentMoves = agentMoves
        self.agentsMoved = agentsMoved
        self.totalManhattanDistanceMoved = totalManhattanDistanceMoved
        self.maxDistanceFromHome = maxDistanceFromHome
        self.averageDistanceFromHome = averageDistanceFromHome
        self.agentReturnHomeMoves = agentReturnHomeMoves
        self.agentsMovedTowardHome = agentsMovedTowardHome
        self.totalDistanceReducedTowardHome = totalDistanceReducedTowardHome
        self.agentsAtHome = agentsAtHome
        self.agentsNearHome = agentsNearHome
        self.eventsWritten = eventsWritten
        self.eventsSuppressed = eventsSuppressed
        self.eventRate = eventRate
        self.worldTickEventsWritten = worldTickEventsWritten
        self.worldTickEventsSuppressed = worldTickEventsSuppressed
        self.nearbyAgentEventsWritten = nearbyAgentEventsWritten
        self.nearbyAgentEventsSuppressed = nearbyAgentEventsSuppressed
        self.physicalAgentsSpawned = physicalAgentsSpawned
        self.physicalAgentsTicked = physicalAgentsTicked
        self.agentsWithPhysicalPlaceholder = agentsWithPhysicalPlaceholder
        self.physicalBridgeLinks = physicalBridgeLinks
        self.physicalAgentsSynced = physicalAgentsSynced
        self.physicalSyncEvents = physicalSyncEvents
        self.physicalSyncDistance = physicalSyncDistance
        self.abstractPhysicalDivergence = abstractPhysicalDivergence
        self.maxAbstractPhysicalDivergence = maxAbstractPhysicalDivergence
        self.coreEntitiesSpawned = coreEntitiesSpawned
        self.coreEntitiesTicked = coreEntitiesTicked
        self.coreEntityLinks = coreEntityLinks
        self.coreEntitiesSynced = coreEntitiesSynced
        self.coreEntitySyncEvents = coreEntitySyncEvents
        self.coreEntitySyncDistance = coreEntitySyncDistance
        self.abstractCoreEntityDivergence = abstractCoreEntityDivergence
        self.maxAbstractCoreEntityDivergence = maxAbstractCoreEntityDivergence
        self.worldEntitiesCount = worldEntitiesCount
        self.physicalBehaviorTicks = physicalBehaviorTicks
        self.physicalBehaviorMoves = physicalBehaviorMoves
        self.physicalBehaviorCoreSyncs = physicalBehaviorCoreSyncs
        self.physicalBehaviorTotalDistance = physicalBehaviorTotalDistance
        self.physicalBehaviorFinalDivergence = physicalBehaviorFinalDivergence
        self.physicalBehaviorSuccess = physicalBehaviorSuccess
        self.successCriteria = successCriteria
    }
}

struct WorldSnapshot: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let worldTime: Int
    let chunkRadius: Int
    let expectedChunks: Int
    let readyChunks: Int
    let originChunkReady: Bool
    let center: SnapshotCenter
    let chunks: [SnapshotChunk]
}

struct SnapshotCenter: Encodable {
    let x: Int
    let z: Int
    let height: Int
    let surfaceY: Int
}

struct SnapshotChunk: Encodable {
    let cx: Int
    let cz: Int
    let ready: Bool
    let centerHeight: Int
    let centerSurfaceY: Int
    let nonAirBlocks: Int?
}

struct AgentSnapshot: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let agents: [LabAgent]
}

func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    try data.write(to: url, options: .atomic)
}
