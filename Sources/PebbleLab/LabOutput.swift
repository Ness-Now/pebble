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
    let physicalBehaviorAgents: Int?
    let physicalBehaviorAgentsMoved: Int?
    let physicalBehaviorMoves: Int?
    let physicalBehaviorCoreSyncs: Int?
    let physicalBehaviorTotalDistance: Int?
    let physicalBehaviorFinalDivergence: Int?
    let physicalBehaviorMaxDivergence: Int?
    let physicalBehaviorSuccess: Bool?
    let worldInteractionAgents: Int?
    let worldInteractionObservations: Int?
    let worldInteractionLoadedObservations: Int?
    let worldInteractionReadyObservations: Int?
    let worldInteractionUniqueChunks: Int?
    let worldInteractionDistinctBlockIds: Int?
    let worldInteractionBlockId: Int?
    let worldInteractionMeta: Int?
    let worldInteractionSuccess: Bool?
    let terrainScanAgents: Int?
    let terrainScanRadius: Int?
    let terrainScanCellsPlanned: Int?
    let terrainScanCellsObserved: Int?
    let terrainScanLoadedCells: Int?
    let terrainScanReadyCells: Int?
    let terrainScanDistinctBlockIds: Int?
    let terrainScanUniqueChunks: Int?
    let terrainScanSuccess: Bool?
    let terrainSemanticCells: Int?
    let terrainSemanticUnknownCells: Int?
    let terrainSemanticAirCells: Int?
    let terrainSemanticSolidCells: Int?
    let terrainSemanticLiquidCells: Int?
    let terrainSemanticPlantLikeCells: Int?
    let terrainSemanticOtherCells: Int?
    let terrainSemanticSuccess: Bool?
    let terrainSemanticFixtureCases: Int?
    let terrainSemanticFixturePassed: Int?
    let terrainSemanticFixtureFailed: Int?
    let terrainSemanticFixtureUnknownCases: Int?
    let terrainSemanticFixtureAirCases: Int?
    let terrainSemanticFixtureSolidCases: Int?
    let terrainSemanticFixtureLiquidCases: Int?
    let terrainSemanticFixturePlantLikeCases: Int?
    let terrainSemanticFixtureOtherCases: Int?
    let terrainSemanticFixtureSuccess: Bool?
    let terrainTraversabilityCells: Int?
    let terrainTraversabilityTraversableCells: Int?
    let terrainTraversabilityBlockedCells: Int?
    let terrainTraversabilityUnknownCells: Int?
    let terrainTraversabilityUnsupportedCells: Int?
    let terrainTraversabilityUnsafeCells: Int?
    let terrainTraversabilityOccupiedVerticalSpaceCells: Int?
    let terrainTraversabilityOtherCells: Int?
    let terrainTraversabilitySuccess: Bool?
    let terrainTraversabilityFixtureCases: Int?
    let terrainTraversabilityFixturePassed: Int?
    let terrainTraversabilityFixtureFailed: Int?
    let terrainColumnScanColumns: Int?
    let terrainColumnScanColumnsObserved: Int?
    let terrainColumnScanCellsPlanned: Int?
    let terrainColumnScanCellsObserved: Int?
    let terrainColumnScanLoadedCells: Int?
    let terrainColumnScanReadyCells: Int?
    let terrainColumnScanUniqueChunks: Int?
    let terrainColumnScanSuccess: Bool?
    let terrainColumnSemanticCells: Int?
    let terrainColumnTraversabilityCells: Int?
    let terrainColumnTraversableCells: Int?
    let terrainColumnUnsafeCells: Int?
    let terrainColumnUnknownCells: Int?
    let terrainColumnUnsupportedCells: Int?
    let terrainColumnOccupiedVerticalSpaceCells: Int?
    let terrainColumnTraversabilitySuccess: Bool?
    let terrainPathfindingFixtureCases: Int?
    let terrainPathfindingFixturePassed: Int?
    let terrainPathfindingFixtureFailed: Int?
    let terrainPathfindingPathsFound: Int?
    let terrainPathfindingPathsNotFound: Int?
    let terrainPathfindingInvalidStarts: Int?
    let terrainPathfindingInvalidGoals: Int?
    let terrainPathfindingSearchLimitReached: Int?
    let terrainPathfindingUnknown: Int?
    let terrainPathfindingSuccess: Bool?
    let terrainPathfindingColumnNodes: Int?
    let terrainPathfindingColumnTraversableNodes: Int?
    let terrainPathfindingColumnUnsafeNodes: Int?
    let terrainPathfindingColumnUnknownNodes: Int?
    let terrainPathfindingColumnPathFound: Bool?
    let terrainPathfindingColumnPathLength: Int?
    let terrainPathfindingColumnVisited: Int?
    let terrainPathfindingColumnSuccess: Bool?
    let terrainPathfindingColumnPositiveCandidates: Int?
    let terrainPathfindingColumnPositiveCandidateIndex: Int?
    let terrainPathfindingColumnPositiveFound: Bool?
    let terrainPathfindingColumnPositivePathLength: Int?
    let terrainPathfindingColumnPositiveVisited: Int?
    let terrainPathfindingColumnPositiveSuccess: Bool?
    let terrainMovementFixtureCases: Int?
    let terrainMovementFixturePassed: Int?
    let terrainMovementFixtureFailed: Int?
    let terrainMovementStepsPlanned: Int?
    let terrainMovementStepsExecuted: Int?
    let terrainMovementReachedGoals: Int?
    let terrainMovementInvalidPaths: Int?
    let terrainMovementSuccess: Bool?
    let terrainLiveMovementPathLength: Int?
    let terrainLiveMovementStepsExecuted: Int?
    let terrainLiveMovementReachedGoal: Bool?
    let terrainLiveMovementFinalStatus: String?
    let terrainLiveMovementLiveAgentDisplaced: Bool?
    let terrainLiveMovementCollisionPerformed: Bool?
    let terrainLiveMovementMutationPerformed: Bool?
    let terrainLiveMovementSuccess: Bool?
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
        physicalBehaviorAgents: Int? = nil,
        physicalBehaviorAgentsMoved: Int? = nil,
        physicalBehaviorMoves: Int? = nil,
        physicalBehaviorCoreSyncs: Int? = nil,
        physicalBehaviorTotalDistance: Int? = nil,
        physicalBehaviorFinalDivergence: Int? = nil,
        physicalBehaviorMaxDivergence: Int? = nil,
        physicalBehaviorSuccess: Bool? = nil,
        worldInteractionAgents: Int? = nil,
        worldInteractionObservations: Int? = nil,
        worldInteractionLoadedObservations: Int? = nil,
        worldInteractionReadyObservations: Int? = nil,
        worldInteractionUniqueChunks: Int? = nil,
        worldInteractionDistinctBlockIds: Int? = nil,
        worldInteractionBlockId: Int? = nil,
        worldInteractionMeta: Int? = nil,
        worldInteractionSuccess: Bool? = nil,
        terrainScanAgents: Int? = nil,
        terrainScanRadius: Int? = nil,
        terrainScanCellsPlanned: Int? = nil,
        terrainScanCellsObserved: Int? = nil,
        terrainScanLoadedCells: Int? = nil,
        terrainScanReadyCells: Int? = nil,
        terrainScanDistinctBlockIds: Int? = nil,
        terrainScanUniqueChunks: Int? = nil,
        terrainScanSuccess: Bool? = nil,
        terrainSemanticCells: Int? = nil,
        terrainSemanticUnknownCells: Int? = nil,
        terrainSemanticAirCells: Int? = nil,
        terrainSemanticSolidCells: Int? = nil,
        terrainSemanticLiquidCells: Int? = nil,
        terrainSemanticPlantLikeCells: Int? = nil,
        terrainSemanticOtherCells: Int? = nil,
        terrainSemanticSuccess: Bool? = nil,
        terrainSemanticFixtureCases: Int? = nil,
        terrainSemanticFixturePassed: Int? = nil,
        terrainSemanticFixtureFailed: Int? = nil,
        terrainSemanticFixtureUnknownCases: Int? = nil,
        terrainSemanticFixtureAirCases: Int? = nil,
        terrainSemanticFixtureSolidCases: Int? = nil,
        terrainSemanticFixtureLiquidCases: Int? = nil,
        terrainSemanticFixturePlantLikeCases: Int? = nil,
        terrainSemanticFixtureOtherCases: Int? = nil,
        terrainSemanticFixtureSuccess: Bool? = nil,
        terrainTraversabilityCells: Int? = nil,
        terrainTraversabilityTraversableCells: Int? = nil,
        terrainTraversabilityBlockedCells: Int? = nil,
        terrainTraversabilityUnknownCells: Int? = nil,
        terrainTraversabilityUnsupportedCells: Int? = nil,
        terrainTraversabilityUnsafeCells: Int? = nil,
        terrainTraversabilityOccupiedVerticalSpaceCells: Int? = nil,
        terrainTraversabilityOtherCells: Int? = nil,
        terrainTraversabilitySuccess: Bool? = nil,
        terrainTraversabilityFixtureCases: Int? = nil,
        terrainTraversabilityFixturePassed: Int? = nil,
        terrainTraversabilityFixtureFailed: Int? = nil,
        terrainColumnScanColumns: Int? = nil,
        terrainColumnScanColumnsObserved: Int? = nil,
        terrainColumnScanCellsPlanned: Int? = nil,
        terrainColumnScanCellsObserved: Int? = nil,
        terrainColumnScanLoadedCells: Int? = nil,
        terrainColumnScanReadyCells: Int? = nil,
        terrainColumnScanUniqueChunks: Int? = nil,
        terrainColumnScanSuccess: Bool? = nil,
        terrainColumnSemanticCells: Int? = nil,
        terrainColumnTraversabilityCells: Int? = nil,
        terrainColumnTraversableCells: Int? = nil,
        terrainColumnUnsafeCells: Int? = nil,
        terrainColumnUnknownCells: Int? = nil,
        terrainColumnUnsupportedCells: Int? = nil,
        terrainColumnOccupiedVerticalSpaceCells: Int? = nil,
        terrainColumnTraversabilitySuccess: Bool? = nil,
        terrainPathfindingFixtureCases: Int? = nil,
        terrainPathfindingFixturePassed: Int? = nil,
        terrainPathfindingFixtureFailed: Int? = nil,
        terrainPathfindingPathsFound: Int? = nil,
        terrainPathfindingPathsNotFound: Int? = nil,
        terrainPathfindingInvalidStarts: Int? = nil,
        terrainPathfindingInvalidGoals: Int? = nil,
        terrainPathfindingSearchLimitReached: Int? = nil,
        terrainPathfindingUnknown: Int? = nil,
        terrainPathfindingSuccess: Bool? = nil,
        terrainPathfindingColumnNodes: Int? = nil,
        terrainPathfindingColumnTraversableNodes: Int? = nil,
        terrainPathfindingColumnUnsafeNodes: Int? = nil,
        terrainPathfindingColumnUnknownNodes: Int? = nil,
        terrainPathfindingColumnPathFound: Bool? = nil,
        terrainPathfindingColumnPathLength: Int? = nil,
        terrainPathfindingColumnVisited: Int? = nil,
        terrainPathfindingColumnSuccess: Bool? = nil,
        terrainPathfindingColumnPositiveCandidates: Int? = nil,
        terrainPathfindingColumnPositiveCandidateIndex: Int? = nil,
        terrainPathfindingColumnPositiveFound: Bool? = nil,
        terrainPathfindingColumnPositivePathLength: Int? = nil,
        terrainPathfindingColumnPositiveVisited: Int? = nil,
        terrainPathfindingColumnPositiveSuccess: Bool? = nil,
        terrainMovementFixtureCases: Int? = nil,
        terrainMovementFixturePassed: Int? = nil,
        terrainMovementFixtureFailed: Int? = nil,
        terrainMovementStepsPlanned: Int? = nil,
        terrainMovementStepsExecuted: Int? = nil,
        terrainMovementReachedGoals: Int? = nil,
        terrainMovementInvalidPaths: Int? = nil,
        terrainMovementSuccess: Bool? = nil,
        terrainLiveMovementPathLength: Int? = nil,
        terrainLiveMovementStepsExecuted: Int? = nil,
        terrainLiveMovementReachedGoal: Bool? = nil,
        terrainLiveMovementFinalStatus: String? = nil,
        terrainLiveMovementLiveAgentDisplaced: Bool? = nil,
        terrainLiveMovementCollisionPerformed: Bool? = nil,
        terrainLiveMovementMutationPerformed: Bool? = nil,
        terrainLiveMovementSuccess: Bool? = nil,
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
        self.physicalBehaviorAgents = physicalBehaviorAgents
        self.physicalBehaviorAgentsMoved = physicalBehaviorAgentsMoved
        self.physicalBehaviorMoves = physicalBehaviorMoves
        self.physicalBehaviorCoreSyncs = physicalBehaviorCoreSyncs
        self.physicalBehaviorTotalDistance = physicalBehaviorTotalDistance
        self.physicalBehaviorFinalDivergence = physicalBehaviorFinalDivergence
        self.physicalBehaviorMaxDivergence = physicalBehaviorMaxDivergence
        self.physicalBehaviorSuccess = physicalBehaviorSuccess
        self.worldInteractionAgents = worldInteractionAgents
        self.worldInteractionObservations = worldInteractionObservations
        self.worldInteractionLoadedObservations = worldInteractionLoadedObservations
        self.worldInteractionReadyObservations = worldInteractionReadyObservations
        self.worldInteractionUniqueChunks = worldInteractionUniqueChunks
        self.worldInteractionDistinctBlockIds = worldInteractionDistinctBlockIds
        self.worldInteractionBlockId = worldInteractionBlockId
        self.worldInteractionMeta = worldInteractionMeta
        self.worldInteractionSuccess = worldInteractionSuccess
        self.terrainScanAgents = terrainScanAgents
        self.terrainScanRadius = terrainScanRadius
        self.terrainScanCellsPlanned = terrainScanCellsPlanned
        self.terrainScanCellsObserved = terrainScanCellsObserved
        self.terrainScanLoadedCells = terrainScanLoadedCells
        self.terrainScanReadyCells = terrainScanReadyCells
        self.terrainScanDistinctBlockIds = terrainScanDistinctBlockIds
        self.terrainScanUniqueChunks = terrainScanUniqueChunks
        self.terrainScanSuccess = terrainScanSuccess
        self.terrainSemanticCells = terrainSemanticCells
        self.terrainSemanticUnknownCells = terrainSemanticUnknownCells
        self.terrainSemanticAirCells = terrainSemanticAirCells
        self.terrainSemanticSolidCells = terrainSemanticSolidCells
        self.terrainSemanticLiquidCells = terrainSemanticLiquidCells
        self.terrainSemanticPlantLikeCells = terrainSemanticPlantLikeCells
        self.terrainSemanticOtherCells = terrainSemanticOtherCells
        self.terrainSemanticSuccess = terrainSemanticSuccess
        self.terrainSemanticFixtureCases = terrainSemanticFixtureCases
        self.terrainSemanticFixturePassed = terrainSemanticFixturePassed
        self.terrainSemanticFixtureFailed = terrainSemanticFixtureFailed
        self.terrainSemanticFixtureUnknownCases = terrainSemanticFixtureUnknownCases
        self.terrainSemanticFixtureAirCases = terrainSemanticFixtureAirCases
        self.terrainSemanticFixtureSolidCases = terrainSemanticFixtureSolidCases
        self.terrainSemanticFixtureLiquidCases = terrainSemanticFixtureLiquidCases
        self.terrainSemanticFixturePlantLikeCases = terrainSemanticFixturePlantLikeCases
        self.terrainSemanticFixtureOtherCases = terrainSemanticFixtureOtherCases
        self.terrainSemanticFixtureSuccess = terrainSemanticFixtureSuccess
        self.terrainTraversabilityCells = terrainTraversabilityCells
        self.terrainTraversabilityTraversableCells = terrainTraversabilityTraversableCells
        self.terrainTraversabilityBlockedCells = terrainTraversabilityBlockedCells
        self.terrainTraversabilityUnknownCells = terrainTraversabilityUnknownCells
        self.terrainTraversabilityUnsupportedCells = terrainTraversabilityUnsupportedCells
        self.terrainTraversabilityUnsafeCells = terrainTraversabilityUnsafeCells
        self.terrainTraversabilityOccupiedVerticalSpaceCells = terrainTraversabilityOccupiedVerticalSpaceCells
        self.terrainTraversabilityOtherCells = terrainTraversabilityOtherCells
        self.terrainTraversabilitySuccess = terrainTraversabilitySuccess
        self.terrainTraversabilityFixtureCases = terrainTraversabilityFixtureCases
        self.terrainTraversabilityFixturePassed = terrainTraversabilityFixturePassed
        self.terrainTraversabilityFixtureFailed = terrainTraversabilityFixtureFailed
        self.terrainColumnScanColumns = terrainColumnScanColumns
        self.terrainColumnScanColumnsObserved = terrainColumnScanColumnsObserved
        self.terrainColumnScanCellsPlanned = terrainColumnScanCellsPlanned
        self.terrainColumnScanCellsObserved = terrainColumnScanCellsObserved
        self.terrainColumnScanLoadedCells = terrainColumnScanLoadedCells
        self.terrainColumnScanReadyCells = terrainColumnScanReadyCells
        self.terrainColumnScanUniqueChunks = terrainColumnScanUniqueChunks
        self.terrainColumnScanSuccess = terrainColumnScanSuccess
        self.terrainColumnSemanticCells = terrainColumnSemanticCells
        self.terrainColumnTraversabilityCells = terrainColumnTraversabilityCells
        self.terrainColumnTraversableCells = terrainColumnTraversableCells
        self.terrainColumnUnsafeCells = terrainColumnUnsafeCells
        self.terrainColumnUnknownCells = terrainColumnUnknownCells
        self.terrainColumnUnsupportedCells = terrainColumnUnsupportedCells
        self.terrainColumnOccupiedVerticalSpaceCells = terrainColumnOccupiedVerticalSpaceCells
        self.terrainColumnTraversabilitySuccess = terrainColumnTraversabilitySuccess
        self.terrainPathfindingFixtureCases = terrainPathfindingFixtureCases
        self.terrainPathfindingFixturePassed = terrainPathfindingFixturePassed
        self.terrainPathfindingFixtureFailed = terrainPathfindingFixtureFailed
        self.terrainPathfindingPathsFound = terrainPathfindingPathsFound
        self.terrainPathfindingPathsNotFound = terrainPathfindingPathsNotFound
        self.terrainPathfindingInvalidStarts = terrainPathfindingInvalidStarts
        self.terrainPathfindingInvalidGoals = terrainPathfindingInvalidGoals
        self.terrainPathfindingSearchLimitReached = terrainPathfindingSearchLimitReached
        self.terrainPathfindingUnknown = terrainPathfindingUnknown
        self.terrainPathfindingSuccess = terrainPathfindingSuccess
        self.terrainPathfindingColumnNodes = terrainPathfindingColumnNodes
        self.terrainPathfindingColumnTraversableNodes = terrainPathfindingColumnTraversableNodes
        self.terrainPathfindingColumnUnsafeNodes = terrainPathfindingColumnUnsafeNodes
        self.terrainPathfindingColumnUnknownNodes = terrainPathfindingColumnUnknownNodes
        self.terrainPathfindingColumnPathFound = terrainPathfindingColumnPathFound
        self.terrainPathfindingColumnPathLength = terrainPathfindingColumnPathLength
        self.terrainPathfindingColumnVisited = terrainPathfindingColumnVisited
        self.terrainPathfindingColumnSuccess = terrainPathfindingColumnSuccess
        self.terrainPathfindingColumnPositiveCandidates = terrainPathfindingColumnPositiveCandidates
        self.terrainPathfindingColumnPositiveCandidateIndex = terrainPathfindingColumnPositiveCandidateIndex
        self.terrainPathfindingColumnPositiveFound = terrainPathfindingColumnPositiveFound
        self.terrainPathfindingColumnPositivePathLength = terrainPathfindingColumnPositivePathLength
        self.terrainPathfindingColumnPositiveVisited = terrainPathfindingColumnPositiveVisited
        self.terrainPathfindingColumnPositiveSuccess = terrainPathfindingColumnPositiveSuccess
        self.terrainMovementFixtureCases = terrainMovementFixtureCases
        self.terrainMovementFixturePassed = terrainMovementFixturePassed
        self.terrainMovementFixtureFailed = terrainMovementFixtureFailed
        self.terrainMovementStepsPlanned = terrainMovementStepsPlanned
        self.terrainMovementStepsExecuted = terrainMovementStepsExecuted
        self.terrainMovementReachedGoals = terrainMovementReachedGoals
        self.terrainMovementInvalidPaths = terrainMovementInvalidPaths
        self.terrainMovementSuccess = terrainMovementSuccess
        self.terrainLiveMovementPathLength = terrainLiveMovementPathLength
        self.terrainLiveMovementStepsExecuted = terrainLiveMovementStepsExecuted
        self.terrainLiveMovementReachedGoal = terrainLiveMovementReachedGoal
        self.terrainLiveMovementFinalStatus = terrainLiveMovementFinalStatus
        self.terrainLiveMovementLiveAgentDisplaced = terrainLiveMovementLiveAgentDisplaced
        self.terrainLiveMovementCollisionPerformed = terrainLiveMovementCollisionPerformed
        self.terrainLiveMovementMutationPerformed = terrainLiveMovementMutationPerformed
        self.terrainLiveMovementSuccess = terrainLiveMovementSuccess
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
