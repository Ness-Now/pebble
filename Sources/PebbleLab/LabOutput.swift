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
    let terrainCollisionFixtureCases: Int?
    let terrainCollisionFixturePassed: Int?
    let terrainCollisionFixtureFailed: Int?
    let terrainCollisionOccupable: Int?
    let terrainCollisionBlocked: Int?
    let terrainCollisionUnsupported: Int?
    let terrainCollisionVerticalSpaceOccupied: Int?
    let terrainCollisionLiquidUnsupported: Int?
    let terrainCollisionUnknown: Int?
    let terrainCollisionOutOfBounds: Int?
    let terrainCollisionNotLoaded: Int?
    let terrainCollisionNotReady: Int?
    let terrainCollisionFixtureSuccess: Bool?
    let terrainCollisionLiveSamples: Int?
    let terrainCollisionLiveLoadedSamples: Int?
    let terrainCollisionLiveReadySamples: Int?
    let terrainCollisionLiveStatus: String?
    let terrainCollisionLiveOccupable: Bool?
    let terrainCollisionLiveBlocked: Bool?
    let terrainCollisionLiveUnsupported: Bool?
    let terrainCollisionLiveVerticalSpaceOccupied: Bool?
    let terrainCollisionLiveLiquidUnsupported: Bool?
    let terrainCollisionLiveUnknown: Bool?
    let terrainCollisionLiveOutOfBounds: Bool?
    let terrainCollisionLiveNotLoaded: Bool?
    let terrainCollisionLiveNotReady: Bool?
    let terrainCollisionLiveMovementPerformed: Bool?
    let terrainCollisionLivePathfindingPerformed: Bool?
    let terrainCollisionLiveMutationPerformed: Bool?
    let terrainCollisionLiveSuccess: Bool?
    let physicalMovementAttempted: Bool?
    let physicalMovementApproved: Bool?
    let physicalMovementDenied: Bool?
    let physicalMovementStatus: String?
    let physicalMovementReason: String?
    let physicalMovementFromX: Int?
    let physicalMovementFromY: Int?
    let physicalMovementFromZ: Int?
    let physicalMovementToX: Int?
    let physicalMovementToY: Int?
    let physicalMovementToZ: Int?
    let physicalMovementCollisionStatus: String?
    let physicalMovementDisplacementApplied: Bool?
    let physicalMovementPathfindingPerformed: Bool?
    let physicalMovementRouteFollowingPerformed: Bool?
    let physicalMovementPhysicsPerformed: Bool?
    let physicalMovementMutationPerformed: Bool?
    let physicalMovementDivergenceBefore: Int?
    let physicalMovementDivergenceAfter: Int?
    let physicalMovementSuccess: Bool?
    let physicalMovementOccupableSearchCandidates: Int?
    let physicalMovementOccupableSearchFound: Bool?
    let physicalMovementOccupableSearchSelectedIndex: Int?
    let physicalMovementOccupableSearchSelectedX: Int?
    let physicalMovementOccupableSearchSelectedY: Int?
    let physicalMovementOccupableSearchSelectedZ: Int?
    let physicalMovementOccupableSearchSelectedStatus: String?
    let physicalMovementOccupableSearchMovementPerformed: Bool?
    let physicalMovementOccupableSearchPathfindingPerformed: Bool?
    let physicalMovementOccupableSearchRouteFollowingPerformed: Bool?
    let physicalMovementOccupableSearchPhysicsPerformed: Bool?
    let physicalMovementOccupableSearchMutationPerformed: Bool?
    let physicalMovementOccupableSearchSuccess: Bool?
    let physicalMovementHardeningCases: Int?
    let physicalMovementHardeningPassed: Int?
    let physicalMovementHardeningFailed: Int?
    let physicalMovementHardeningApproved: Int?
    let physicalMovementHardeningDenied: Int?
    let physicalMovementHardeningCollisionDenied: Int?
    let physicalMovementHardeningSourceMismatch: Int?
    let physicalMovementHardeningMissingPhysicalHandle: Int?
    let physicalMovementHardeningDivergenceBeforeMove: Int?
    let physicalMovementHardeningDisplacementApplied: Int?
    let physicalMovementHardeningDisplacementRefused: Int?
    let physicalMovementHardeningSuccess: Bool?
    let multiAgentMovementFixtureCases: Int?
    let multiAgentMovementFixturePassed: Int?
    let multiAgentMovementFixtureFailed: Int?
    let multiAgentMovementFixtureAgentCount: Int?
    let multiAgentMovementFixtureIntentCount: Int?
    let multiAgentMovementFixtureApproved: Int?
    let multiAgentMovementFixtureDenied: Int?
    let multiAgentMovementFixtureSameDestinationConflicts: Int?
    let multiAgentMovementFixtureOccupiedDestinationConflicts: Int?
    let multiAgentMovementFixtureSwapConflicts: Int?
    let multiAgentMovementFixtureSourceMismatch: Int?
    let multiAgentMovementFixtureStaleIntent: Int?
    let multiAgentMovementFixtureMissingAgent: Int?
    let multiAgentMovementFixtureInvalidEdges: Int?
    let multiAgentMovementFixturePathfindingPerformed: Bool?
    let multiAgentMovementFixtureReplanningPerformed: Bool?
    let multiAgentMovementFixturePhysicsPerformed: Bool?
    let multiAgentMovementFixtureMutationPerformed: Bool?
    let multiAgentMovementFixtureSuccess: Bool?
    let multiAgentMovementFixtureHardeningCases: Int?
    let multiAgentMovementFixtureHardeningPassed: Int?
    let multiAgentMovementFixtureHardeningFailed: Int?
    let multiAgentMovementFixtureHardeningApproved: Int?
    let multiAgentMovementFixtureHardeningDenied: Int?
    let multiAgentMovementFixtureHardeningDuplicateIntent: Int?
    let multiAgentMovementFixtureHardeningCycleConflicts: Int?
    let multiAgentMovementFixtureHardeningChainDependencies: Int?
    let multiAgentMovementFixtureHardeningMovingAwayDestination: Int?
    let multiAgentMovementFixtureHardeningVerticalInvalidEdges: Int?
    let multiAgentMovementFixtureHardeningZeroLengthEdges: Int?
    let multiAgentMovementFixtureHardeningAllDeniedCases: Int?
    let multiAgentMovementFixtureHardeningEmptyIntentCases: Int?
    let multiAgentMovementFixtureHardeningMaxAgentsExceeded: Int?
    let multiAgentMovementFixtureHardeningWorldUsed: Bool?
    let multiAgentMovementFixtureHardeningPathfindingPerformed: Bool?
    let multiAgentMovementFixtureHardeningReplanningPerformed: Bool?
    let multiAgentMovementFixtureHardeningPhysicsPerformed: Bool?
    let multiAgentMovementFixtureHardeningMutationPerformed: Bool?
    let multiAgentMovementFixtureHardeningSuccess: Bool?
    let multiAgentLiveCollisionIntentCases: Int?
    let multiAgentLiveCollisionIntentPassed: Int?
    let multiAgentLiveCollisionIntentFailed: Int?
    let multiAgentLiveCollisionIntentAgentCount: Int?
    let multiAgentLiveCollisionIntentIntentCount: Int?
    let multiAgentLiveCollisionIntentApproved: Int?
    let multiAgentLiveCollisionIntentDenied: Int?
    let multiAgentLiveCollisionIntentOccupableDestinations: Int?
    let multiAgentLiveCollisionIntentNonOccupableDestinations: Int?
    let multiAgentLiveCollisionIntentCollisionDenied: Int?
    let multiAgentLiveCollisionIntentSameDestinationConflicts: Int?
    let multiAgentLiveCollisionIntentSourceMismatch: Int?
    let multiAgentLiveCollisionIntentInvalidEdges: Int?
    let multiAgentLiveCollisionIntentStaleIntent: Int?
    let multiAgentLiveCollisionIntentWorldUsed: Bool?
    let multiAgentLiveCollisionIntentLiveCollisionRead: Bool?
    let multiAgentLiveCollisionIntentDisplacementApplied: Bool?
    let multiAgentLiveCollisionIntentPhysicalMovementApplied: Bool?
    let multiAgentLiveCollisionIntentRouteFollowingApplied: Bool?
    let multiAgentLiveCollisionIntentPathfindingPerformed: Bool?
    let multiAgentLiveCollisionIntentReplanningPerformed: Bool?
    let multiAgentLiveCollisionIntentPhysicsPerformed: Bool?
    let multiAgentLiveCollisionIntentMutationPerformed: Bool?
    let multiAgentLiveCollisionIntentSuccess: Bool?
    let multiAgentApprovedPhysicalMovementCases: Int?
    let multiAgentApprovedPhysicalMovementPassed: Int?
    let multiAgentApprovedPhysicalMovementFailed: Int?
    let multiAgentApprovedPhysicalMovementAgentCount: Int?
    let multiAgentApprovedPhysicalMovementIntentCount: Int?
    let multiAgentApprovedPhysicalMovementApproved: Int?
    let multiAgentApprovedPhysicalMovementDenied: Int?
    let multiAgentApprovedPhysicalMovementDisplacementsApplied: Int?
    let multiAgentApprovedPhysicalMovementOccupableDestinations: Int?
    let multiAgentApprovedPhysicalMovementNonOccupableDestinations: Int?
    let multiAgentApprovedPhysicalMovementDivergenceBeforeMax: Int?
    let multiAgentApprovedPhysicalMovementDivergenceAfterMax: Int?
    let multiAgentApprovedPhysicalMovementWorldUsed: Bool?
    let multiAgentApprovedPhysicalMovementLiveCollisionRead: Bool?
    let multiAgentApprovedPhysicalMovementPhysicalMovementApplied: Bool?
    let multiAgentApprovedPhysicalMovementRouteFollowingApplied: Bool?
    let multiAgentApprovedPhysicalMovementPathfindingPerformed: Bool?
    let multiAgentApprovedPhysicalMovementReplanningPerformed: Bool?
    let multiAgentApprovedPhysicalMovementPhysicsPerformed: Bool?
    let multiAgentApprovedPhysicalMovementTerrainMutationPerformed: Bool?
    let multiAgentApprovedPhysicalMovementWorldMutationPerformed: Bool?
    let multiAgentApprovedPhysicalMovementSuccess: Bool?
    let multiAgentMovementHardeningCases: Int?
    let multiAgentMovementHardeningPassed: Int?
    let multiAgentMovementHardeningFailed: Int?
    let multiAgentMovementHardeningAgentCount: Int?
    let multiAgentMovementHardeningIntentCount: Int?
    let multiAgentMovementHardeningApproved: Int?
    let multiAgentMovementHardeningDenied: Int?
    let multiAgentMovementHardeningDisplacementsApplied: Int?
    let multiAgentMovementHardeningOccupableDestinations: Int?
    let multiAgentMovementHardeningNonOccupableDestinations: Int?
    let multiAgentMovementHardeningCollisionDenied: Int?
    let multiAgentMovementHardeningSameDestinationConflicts: Int?
    let multiAgentMovementHardeningSwapConflicts: Int?
    let multiAgentMovementHardeningSourceMismatch: Int?
    let multiAgentMovementHardeningStaleIntent: Int?
    let multiAgentMovementHardeningInvalidEdges: Int?
    let multiAgentMovementHardeningDivergenceDenied: Int?
    let multiAgentMovementHardeningStaleCollision: Int?
    let multiAgentMovementHardeningPartialApprovalCases: Int?
    let multiAgentMovementHardeningAllDeniedCases: Int?
    let multiAgentMovementHardeningMaxAgentsExceeded: Int?
    let multiAgentMovementHardeningDivergenceBeforeMax: Int?
    let multiAgentMovementHardeningDivergenceAfterMax: Int?
    let multiAgentMovementHardeningWorldUsed: Bool?
    let multiAgentMovementHardeningLiveCollisionRead: Bool?
    let multiAgentMovementHardeningPhysicalMovementApplied: Bool?
    let multiAgentMovementHardeningRouteFollowingApplied: Bool?
    let multiAgentMovementHardeningPathfindingPerformed: Bool?
    let multiAgentMovementHardeningReplanningPerformed: Bool?
    let multiAgentMovementHardeningPhysicsPerformed: Bool?
    let multiAgentMovementHardeningTerrainMutationPerformed: Bool?
    let multiAgentMovementHardeningWorldMutationPerformed: Bool?
    let multiAgentMovementHardeningSuccess: Bool?
    let multiAgentMovementTickFixtureInputs: Int?
    let multiAgentMovementTickFixtureAgents: Int?
    let multiAgentMovementTickFixturePhysicalPositions: Int?
    let multiAgentMovementTickFixtureIntents: Int?
    let multiAgentMovementTickFixtureResolutions: Int?
    let multiAgentMovementTickFixtureFeedback: Int?
    let multiAgentMovementTickFixtureApproved: Int?
    let multiAgentMovementTickFixtureDenied: Int?
    let multiAgentMovementTickFixtureDisplacementsApplied: Int?
    let multiAgentMovementTickFixtureSameDestinationConflicts: Int?
    let multiAgentMovementTickFixtureInvalidEdges: Int?
    let multiAgentMovementTickFixtureWorldUsed: Bool?
    let multiAgentMovementTickFixtureLiveCollisionRead: Bool?
    let multiAgentMovementTickFixturePhysicalMovementApplied: Bool?
    let multiAgentMovementTickFixtureRouteFollowingApplied: Bool?
    let multiAgentMovementTickFixturePathfindingPerformed: Bool?
    let multiAgentMovementTickFixtureReplanningPerformed: Bool?
    let multiAgentMovementTickFixtureAvoidancePerformed: Bool?
    let multiAgentMovementTickFixtureReservationRuntimeUsed: Bool?
    let multiAgentMovementTickFixturePhysicsPerformed: Bool?
    let multiAgentMovementTickFixtureMutationPerformed: Bool?
    let multiAgentMovementTickFixtureSuccess: Bool?
    let multiAgentMovementTickLiveReadonlyInputs: Int?
    let multiAgentMovementTickLiveReadonlyAgents: Int?
    let multiAgentMovementTickLiveReadonlyPhysicalPositions: Int?
    let multiAgentMovementTickLiveReadonlyIntents: Int?
    let multiAgentMovementTickLiveReadonlyResolutions: Int?
    let multiAgentMovementTickLiveReadonlyFeedback: Int?
    let multiAgentMovementTickLiveReadonlyApproved: Int?
    let multiAgentMovementTickLiveReadonlyDenied: Int?
    let multiAgentMovementTickLiveReadonlyOccupableDestinations: Int?
    let multiAgentMovementTickLiveReadonlyNonOccupableDestinations: Int?
    let multiAgentMovementTickLiveReadonlyCollisionDenied: Int?
    let multiAgentMovementTickLiveReadonlySourceMismatch: Int?
    let multiAgentMovementTickLiveReadonlyInvalidEdges: Int?
    let multiAgentMovementTickLiveReadonlyStaleIntent: Int?
    let multiAgentMovementTickLiveReadonlyDisplacementsApplied: Int?
    let multiAgentMovementTickLiveReadonlyWorldUsed: Bool?
    let multiAgentMovementTickLiveReadonlyLiveCollisionRead: Bool?
    let multiAgentMovementTickLiveReadonlyPhysicalMovementApplied: Bool?
    let multiAgentMovementTickLiveReadonlyRouteFollowingApplied: Bool?
    let multiAgentMovementTickLiveReadonlyPathfindingPerformed: Bool?
    let multiAgentMovementTickLiveReadonlyReplanningPerformed: Bool?
    let multiAgentMovementTickLiveReadonlyAvoidancePerformed: Bool?
    let multiAgentMovementTickLiveReadonlyReservationRuntimeUsed: Bool?
    let multiAgentMovementTickLiveReadonlyPhysicsPerformed: Bool?
    let multiAgentMovementTickLiveReadonlyMutationPerformed: Bool?
    let multiAgentMovementTickLiveReadonlySuccess: Bool?
    let multiAgentMovementTickApprovedApplicationInputs: Int?
    let multiAgentMovementTickApprovedApplicationAgents: Int?
    let multiAgentMovementTickApprovedApplicationPhysicalPositions: Int?
    let multiAgentMovementTickApprovedApplicationIntents: Int?
    let multiAgentMovementTickApprovedApplicationResolutions: Int?
    let multiAgentMovementTickApprovedApplicationFeedback: Int?
    let multiAgentMovementTickApprovedApplicationApproved: Int?
    let multiAgentMovementTickApprovedApplicationDenied: Int?
    let multiAgentMovementTickApprovedApplicationOccupableDestinations: Int?
    let multiAgentMovementTickApprovedApplicationNonOccupableDestinations: Int?
    let multiAgentMovementTickApprovedApplicationDisplacementsApplied: Int?
    let multiAgentMovementTickApprovedApplicationDivergenceBeforeMax: Int?
    let multiAgentMovementTickApprovedApplicationDivergenceAfterMax: Int?
    let multiAgentMovementTickApprovedApplicationWorldUsed: Bool?
    let multiAgentMovementTickApprovedApplicationLiveCollisionRead: Bool?
    let multiAgentMovementTickApprovedApplicationPhysicalMovementApplied: Bool?
    let multiAgentMovementTickApprovedApplicationRouteFollowingApplied: Bool?
    let multiAgentMovementTickApprovedApplicationPathfindingPerformed: Bool?
    let multiAgentMovementTickApprovedApplicationReplanningPerformed: Bool?
    let multiAgentMovementTickApprovedApplicationAvoidancePerformed: Bool?
    let multiAgentMovementTickApprovedApplicationReservationRuntimeUsed: Bool?
    let multiAgentMovementTickApprovedApplicationPhysicsPerformed: Bool?
    let multiAgentMovementTickApprovedApplicationTerrainMutationPerformed: Bool?
    let multiAgentMovementTickApprovedApplicationWorldMutationPerformed: Bool?
    let multiAgentMovementTickApprovedApplicationSuccess: Bool?
    let multiAgentMovementTickHardeningCases: Int?
    let multiAgentMovementTickHardeningPassed: Int?
    let multiAgentMovementTickHardeningFailed: Int?
    let multiAgentMovementTickHardeningTicks: Int?
    let multiAgentMovementTickHardeningAgents: Int?
    let multiAgentMovementTickHardeningIntents: Int?
    let multiAgentMovementTickHardeningResolutions: Int?
    let multiAgentMovementTickHardeningFeedback: Int?
    let multiAgentMovementTickHardeningApproved: Int?
    let multiAgentMovementTickHardeningDenied: Int?
    let multiAgentMovementTickHardeningDisplacementsApplied: Int?
    let multiAgentMovementTickHardeningOccupableDestinations: Int?
    let multiAgentMovementTickHardeningNonOccupableDestinations: Int?
    let multiAgentMovementTickHardeningCollisionDenied: Int?
    let multiAgentMovementTickHardeningSameDestinationConflicts: Int?
    let multiAgentMovementTickHardeningSwapConflicts: Int?
    let multiAgentMovementTickHardeningSourceMismatch: Int?
    let multiAgentMovementTickHardeningStaleIntent: Int?
    let multiAgentMovementTickHardeningInvalidEdges: Int?
    let multiAgentMovementTickHardeningDivergenceDenied: Int?
    let multiAgentMovementTickHardeningStaleCollision: Int?
    let multiAgentMovementTickHardeningPartialApprovalCases: Int?
    let multiAgentMovementTickHardeningAllDeniedCases: Int?
    let multiAgentMovementTickHardeningMaxAgentsExceeded: Int?
    let multiAgentMovementTickHardeningMovedFeedback: Int?
    let multiAgentMovementTickHardeningApprovedForMovementFeedback: Int?
    let multiAgentMovementTickHardeningBlockedByCollisionFeedback: Int?
    let multiAgentMovementTickHardeningBlockedByAgentConflictFeedback: Int?
    let multiAgentMovementTickHardeningBlockedBySourceMismatchFeedback: Int?
    let multiAgentMovementTickHardeningBlockedByDivergenceFeedback: Int?
    let multiAgentMovementTickHardeningBlockedByStaleIntentFeedback: Int?
    let multiAgentMovementTickHardeningBlockedByInvalidEdgeFeedback: Int?
    let multiAgentMovementTickHardeningBlockedByMaxAgentsFeedback: Int?
    let multiAgentMovementTickHardeningDivergenceBeforeMax: Int?
    let multiAgentMovementTickHardeningDivergenceAfterMax: Int?
    let multiAgentMovementTickHardeningWorldUsed: Bool?
    let multiAgentMovementTickHardeningLiveCollisionRead: Bool?
    let multiAgentMovementTickHardeningPhysicalMovementApplied: Bool?
    let multiAgentMovementTickHardeningRouteFollowingApplied: Bool?
    let multiAgentMovementTickHardeningPathfindingPerformed: Bool?
    let multiAgentMovementTickHardeningReplanningPerformed: Bool?
    let multiAgentMovementTickHardeningAvoidancePerformed: Bool?
    let multiAgentMovementTickHardeningReservationRuntimeUsed: Bool?
    let multiAgentMovementTickHardeningPhysicsPerformed: Bool?
    let multiAgentMovementTickHardeningTerrainMutationPerformed: Bool?
    let multiAgentMovementTickHardeningWorldMutationPerformed: Bool?
    let multiAgentMovementTickHardeningSuccess: Bool?
    let agentIntentProductionFixtureAgentsObserved: Int?
    let agentIntentProductionFixtureContexts: Int?
    let agentIntentProductionFixtureProposals: Int?
    let agentIntentProductionFixtureAcceptedIntents: Int?
    let agentIntentProductionFixtureRejectedProposals: Int?
    let agentIntentProductionFixtureNoIntent: Int?
    let agentIntentProductionFixtureInvalidContext: Int?
    let agentIntentProductionFixtureDuplicateAgentContexts: Int?
    let agentIntentProductionFixtureInvalidOneEdgeProposals: Int?
    let agentIntentProductionFixtureAcceptedMoveEast: Int?
    let agentIntentProductionFixtureAcceptedMoveWest: Int?
    let agentIntentProductionFixtureAcceptedMoveNorth: Int?
    let agentIntentProductionFixtureAcceptedMoveSouth: Int?
    let agentIntentProductionFixtureWorldUsed: Bool?
    let agentIntentProductionFixtureCollisionRead: Bool?
    let agentIntentProductionFixtureMovementApplied: Bool?
    let agentIntentProductionFixtureFeedbackConsumed: Bool?
    let agentIntentProductionFixtureMemoryUpdated: Bool?
    let agentIntentProductionFixtureGoalChanged: Bool?
    let agentIntentProductionFixturePathfindingPerformed: Bool?
    let agentIntentProductionFixtureReplanningPerformed: Bool?
    let agentIntentProductionFixtureAvoidancePerformed: Bool?
    let agentIntentProductionFixtureReservationRuntimeUsed: Bool?
    let agentIntentProductionFixtureMutationPerformed: Bool?
    let agentIntentProductionFixtureSuccess: Bool?
    let agentIntentProductionHardeningCases: Int?
    let agentIntentProductionHardeningPassed: Int?
    let agentIntentProductionHardeningFailed: Int?
    let agentIntentProductionHardeningContexts: Int?
    let agentIntentProductionHardeningProposals: Int?
    let agentIntentProductionHardeningAcceptedIntents: Int?
    let agentIntentProductionHardeningRejectedProposals: Int?
    let agentIntentProductionHardeningNoIntent: Int?
    let agentIntentProductionHardeningInvalidContext: Int?
    let agentIntentProductionHardeningDuplicateAgentContexts: Int?
    let agentIntentProductionHardeningDuplicateProposals: Int?
    let agentIntentProductionHardeningInvalidOneEdgeProposals: Int?
    let agentIntentProductionHardeningStaleProposals: Int?
    let agentIntentProductionHardeningWrongSourceProposals: Int?
    let agentIntentProductionHardeningMaxProposalsExceeded: Int?
    let agentIntentProductionHardeningAcceptedMoveEast: Int?
    let agentIntentProductionHardeningAcceptedMoveWest: Int?
    let agentIntentProductionHardeningAcceptedMoveNorth: Int?
    let agentIntentProductionHardeningAcceptedMoveSouth: Int?
    let agentIntentProductionHardeningWorldUsed: Bool?
    let agentIntentProductionHardeningCollisionRead: Bool?
    let agentIntentProductionHardeningMovementApplied: Bool?
    let agentIntentProductionHardeningFeedbackConsumed: Bool?
    let agentIntentProductionHardeningMemoryUpdated: Bool?
    let agentIntentProductionHardeningGoalChanged: Bool?
    let agentIntentProductionHardeningPathfindingPerformed: Bool?
    let agentIntentProductionHardeningReplanningPerformed: Bool?
    let agentIntentProductionHardeningAvoidancePerformed: Bool?
    let agentIntentProductionHardeningReservationRuntimeUsed: Bool?
    let agentIntentProductionHardeningPhysicsPerformed: Bool?
    let agentIntentProductionHardeningMutationPerformed: Bool?
    let agentIntentProductionHardeningSuccess: Bool?
    let agentIntentToTickFixtureContexts: Int?
    let agentIntentToTickFixtureProposals: Int?
    let agentIntentToTickFixtureAcceptedIntents: Int?
    let agentIntentToTickFixtureRejectedProposals: Int?
    let agentIntentToTickFixtureNoIntent: Int?
    let agentIntentToTickFixtureInvalidOneEdgeProposals: Int?
    let agentIntentToTickFixtureTickAgents: Int?
    let agentIntentToTickFixtureTickIntents: Int?
    let agentIntentToTickFixtureTickResolutions: Int?
    let agentIntentToTickFixtureTickFeedback: Int?
    let agentIntentToTickFixtureTickApproved: Int?
    let agentIntentToTickFixtureTickDenied: Int?
    let agentIntentToTickFixtureSameDestinationConflicts: Int?
    let agentIntentToTickFixtureDisplacementsApplied: Int?
    let agentIntentToTickFixtureProductionAcceptedSameDestination: Bool?
    let agentIntentToTickFixtureTickResolvedSameDestination: Bool?
    let agentIntentToTickFixtureWorldUsed: Bool?
    let agentIntentToTickFixtureCollisionRead: Bool?
    let agentIntentToTickFixtureMovementApplied: Bool?
    let agentIntentToTickFixtureFeedbackConsumed: Bool?
    let agentIntentToTickFixtureMemoryUpdated: Bool?
    let agentIntentToTickFixtureGoalChanged: Bool?
    let agentIntentToTickFixturePathfindingPerformed: Bool?
    let agentIntentToTickFixtureReplanningPerformed: Bool?
    let agentIntentToTickFixtureAvoidancePerformed: Bool?
    let agentIntentToTickFixtureReservationRuntimeUsed: Bool?
    let agentIntentToTickFixturePhysicsPerformed: Bool?
    let agentIntentToTickFixtureMutationPerformed: Bool?
    let agentIntentToTickFixtureSuccess: Bool?
    let agentIntentToTickLiveReadonlyContexts: Int?
    let agentIntentToTickLiveReadonlyProposals: Int?
    let agentIntentToTickLiveReadonlyAcceptedIntents: Int?
    let agentIntentToTickLiveReadonlyRejectedProposals: Int?
    let agentIntentToTickLiveReadonlyNoIntent: Int?
    let agentIntentToTickLiveReadonlyInvalidOneEdgeProposals: Int?
    let agentIntentToTickLiveReadonlyTickAgents: Int?
    let agentIntentToTickLiveReadonlyTickIntents: Int?
    let agentIntentToTickLiveReadonlyTickResolutions: Int?
    let agentIntentToTickLiveReadonlyTickFeedback: Int?
    let agentIntentToTickLiveReadonlyTickApproved: Int?
    let agentIntentToTickLiveReadonlyTickDenied: Int?
    let agentIntentToTickLiveReadonlyOccupableDestinations: Int?
    let agentIntentToTickLiveReadonlyNonOccupableDestinations: Int?
    let agentIntentToTickLiveReadonlyCollisionDenied: Int?
    let agentIntentToTickLiveReadonlyDisplacementsApplied: Int?
    let agentIntentToTickLiveReadonlyProductionReadCollision: Bool?
    let agentIntentToTickLiveReadonlyTickReadCollision: Bool?
    let agentIntentToTickLiveReadonlyWorldUsed: Bool?
    let agentIntentToTickLiveReadonlyCollisionRead: Bool?
    let agentIntentToTickLiveReadonlyMovementApplied: Bool?
    let agentIntentToTickLiveReadonlyFeedbackConsumed: Bool?
    let agentIntentToTickLiveReadonlyMemoryUpdated: Bool?
    let agentIntentToTickLiveReadonlyGoalChanged: Bool?
    let agentIntentToTickLiveReadonlyPathfindingPerformed: Bool?
    let agentIntentToTickLiveReadonlyReplanningPerformed: Bool?
    let agentIntentToTickLiveReadonlyAvoidancePerformed: Bool?
    let agentIntentToTickLiveReadonlyReservationRuntimeUsed: Bool?
    let agentIntentToTickLiveReadonlyPhysicsPerformed: Bool?
    let agentIntentToTickLiveReadonlyMutationPerformed: Bool?
    let agentIntentToTickLiveReadonlySuccess: Bool?
    let routeFollowingFixtureCases: Int?
    let routeFollowingFixturePassed: Int?
    let routeFollowingFixtureFailed: Int?
    let routeFollowingFixtureCompleted: Int?
    let routeFollowingFixtureStopped: Int?
    let routeFollowingFixtureAttemptedEdges: Int?
    let routeFollowingFixtureCompletedEdges: Int?
    let routeFollowingFixtureDisplacementsApplied: Int?
    let routeFollowingFixtureDeniedEdges: Int?
    let routeFollowingFixtureCollisionDenied: Int?
    let routeFollowingFixtureInvalidEdges: Int?
    let routeFollowingFixtureSourceMismatch: Int?
    let routeFollowingFixtureDivergence: Int?
    let routeFollowingFixtureMaxSteps: Int?
    let routeFollowingFixtureSuccess: Bool?
    let routeFollowingLiveAttempted: Bool?
    let routeFollowingLiveCompleted: Bool?
    let routeFollowingLiveStopped: Bool?
    let routeFollowingLiveStatus: String?
    let routeFollowingLiveReason: String?
    let routeFollowingLiveRouteLength: Int?
    let routeFollowingLiveAttemptedEdges: Int?
    let routeFollowingLiveCompletedEdges: Int?
    let routeFollowingLiveStoppedAtIndex: Int?
    let routeFollowingLiveDisplacementsApplied: Int?
    let routeFollowingLiveDeniedEdges: Int?
    let routeFollowingLiveCollisionDenied: Int?
    let routeFollowingLiveInvalidEdges: Int?
    let routeFollowingLiveSourceMismatch: Int?
    let routeFollowingLiveDivergence: Int?
    let routeFollowingLivePathfindingInsideFollower: Bool?
    let routeFollowingLiveReplanningPerformed: Bool?
    let routeFollowingLivePhysicsPerformed: Bool?
    let routeFollowingLiveMutationPerformed: Bool?
    let routeFollowingLiveSuccess: Bool?
    let routeFollowingLiveHardeningCases: Int?
    let routeFollowingLiveHardeningPassed: Int?
    let routeFollowingLiveHardeningFailed: Int?
    let routeFollowingLiveHardeningCompleted: Int?
    let routeFollowingLiveHardeningStopped: Int?
    let routeFollowingLiveHardeningAttemptedEdges: Int?
    let routeFollowingLiveHardeningCompletedEdges: Int?
    let routeFollowingLiveHardeningDisplacementsApplied: Int?
    let routeFollowingLiveHardeningDeniedEdges: Int?
    let routeFollowingLiveHardeningCollisionDenied: Int?
    let routeFollowingLiveHardeningInvalidEdges: Int?
    let routeFollowingLiveHardeningSourceMismatch: Int?
    let routeFollowingLiveHardeningDivergence: Int?
    let routeFollowingLiveHardeningStaleCollision: Int?
    let routeFollowingLiveHardeningMaxSteps: Int?
    let routeFollowingLiveHardeningSuccess: Bool?
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
        terrainCollisionFixtureCases: Int? = nil,
        terrainCollisionFixturePassed: Int? = nil,
        terrainCollisionFixtureFailed: Int? = nil,
        terrainCollisionOccupable: Int? = nil,
        terrainCollisionBlocked: Int? = nil,
        terrainCollisionUnsupported: Int? = nil,
        terrainCollisionVerticalSpaceOccupied: Int? = nil,
        terrainCollisionLiquidUnsupported: Int? = nil,
        terrainCollisionUnknown: Int? = nil,
        terrainCollisionOutOfBounds: Int? = nil,
        terrainCollisionNotLoaded: Int? = nil,
        terrainCollisionNotReady: Int? = nil,
        terrainCollisionFixtureSuccess: Bool? = nil,
        terrainCollisionLiveSamples: Int? = nil,
        terrainCollisionLiveLoadedSamples: Int? = nil,
        terrainCollisionLiveReadySamples: Int? = nil,
        terrainCollisionLiveStatus: String? = nil,
        terrainCollisionLiveOccupable: Bool? = nil,
        terrainCollisionLiveBlocked: Bool? = nil,
        terrainCollisionLiveUnsupported: Bool? = nil,
        terrainCollisionLiveVerticalSpaceOccupied: Bool? = nil,
        terrainCollisionLiveLiquidUnsupported: Bool? = nil,
        terrainCollisionLiveUnknown: Bool? = nil,
        terrainCollisionLiveOutOfBounds: Bool? = nil,
        terrainCollisionLiveNotLoaded: Bool? = nil,
        terrainCollisionLiveNotReady: Bool? = nil,
        terrainCollisionLiveMovementPerformed: Bool? = nil,
        terrainCollisionLivePathfindingPerformed: Bool? = nil,
        terrainCollisionLiveMutationPerformed: Bool? = nil,
        terrainCollisionLiveSuccess: Bool? = nil,
        physicalMovementAttempted: Bool? = nil,
        physicalMovementApproved: Bool? = nil,
        physicalMovementDenied: Bool? = nil,
        physicalMovementStatus: String? = nil,
        physicalMovementReason: String? = nil,
        physicalMovementFromX: Int? = nil,
        physicalMovementFromY: Int? = nil,
        physicalMovementFromZ: Int? = nil,
        physicalMovementToX: Int? = nil,
        physicalMovementToY: Int? = nil,
        physicalMovementToZ: Int? = nil,
        physicalMovementCollisionStatus: String? = nil,
        physicalMovementDisplacementApplied: Bool? = nil,
        physicalMovementPathfindingPerformed: Bool? = nil,
        physicalMovementRouteFollowingPerformed: Bool? = nil,
        physicalMovementPhysicsPerformed: Bool? = nil,
        physicalMovementMutationPerformed: Bool? = nil,
        physicalMovementDivergenceBefore: Int? = nil,
        physicalMovementDivergenceAfter: Int? = nil,
        physicalMovementSuccess: Bool? = nil,
        physicalMovementOccupableSearchCandidates: Int? = nil,
        physicalMovementOccupableSearchFound: Bool? = nil,
        physicalMovementOccupableSearchSelectedIndex: Int? = nil,
        physicalMovementOccupableSearchSelectedX: Int? = nil,
        physicalMovementOccupableSearchSelectedY: Int? = nil,
        physicalMovementOccupableSearchSelectedZ: Int? = nil,
        physicalMovementOccupableSearchSelectedStatus: String? = nil,
        physicalMovementOccupableSearchMovementPerformed: Bool? = nil,
        physicalMovementOccupableSearchPathfindingPerformed: Bool? = nil,
        physicalMovementOccupableSearchRouteFollowingPerformed: Bool? = nil,
        physicalMovementOccupableSearchPhysicsPerformed: Bool? = nil,
        physicalMovementOccupableSearchMutationPerformed: Bool? = nil,
        physicalMovementOccupableSearchSuccess: Bool? = nil,
        physicalMovementHardeningCases: Int? = nil,
        physicalMovementHardeningPassed: Int? = nil,
        physicalMovementHardeningFailed: Int? = nil,
        physicalMovementHardeningApproved: Int? = nil,
        physicalMovementHardeningDenied: Int? = nil,
        physicalMovementHardeningCollisionDenied: Int? = nil,
        physicalMovementHardeningSourceMismatch: Int? = nil,
        physicalMovementHardeningMissingPhysicalHandle: Int? = nil,
        physicalMovementHardeningDivergenceBeforeMove: Int? = nil,
        physicalMovementHardeningDisplacementApplied: Int? = nil,
        physicalMovementHardeningDisplacementRefused: Int? = nil,
        physicalMovementHardeningSuccess: Bool? = nil,
        multiAgentMovementFixtureCases: Int? = nil,
        multiAgentMovementFixturePassed: Int? = nil,
        multiAgentMovementFixtureFailed: Int? = nil,
        multiAgentMovementFixtureAgentCount: Int? = nil,
        multiAgentMovementFixtureIntentCount: Int? = nil,
        multiAgentMovementFixtureApproved: Int? = nil,
        multiAgentMovementFixtureDenied: Int? = nil,
        multiAgentMovementFixtureSameDestinationConflicts: Int? = nil,
        multiAgentMovementFixtureOccupiedDestinationConflicts: Int? = nil,
        multiAgentMovementFixtureSwapConflicts: Int? = nil,
        multiAgentMovementFixtureSourceMismatch: Int? = nil,
        multiAgentMovementFixtureStaleIntent: Int? = nil,
        multiAgentMovementFixtureMissingAgent: Int? = nil,
        multiAgentMovementFixtureInvalidEdges: Int? = nil,
        multiAgentMovementFixturePathfindingPerformed: Bool? = nil,
        multiAgentMovementFixtureReplanningPerformed: Bool? = nil,
        multiAgentMovementFixturePhysicsPerformed: Bool? = nil,
        multiAgentMovementFixtureMutationPerformed: Bool? = nil,
        multiAgentMovementFixtureSuccess: Bool? = nil,
        multiAgentMovementFixtureHardeningCases: Int? = nil,
        multiAgentMovementFixtureHardeningPassed: Int? = nil,
        multiAgentMovementFixtureHardeningFailed: Int? = nil,
        multiAgentMovementFixtureHardeningApproved: Int? = nil,
        multiAgentMovementFixtureHardeningDenied: Int? = nil,
        multiAgentMovementFixtureHardeningDuplicateIntent: Int? = nil,
        multiAgentMovementFixtureHardeningCycleConflicts: Int? = nil,
        multiAgentMovementFixtureHardeningChainDependencies: Int? = nil,
        multiAgentMovementFixtureHardeningMovingAwayDestination: Int? = nil,
        multiAgentMovementFixtureHardeningVerticalInvalidEdges: Int? = nil,
        multiAgentMovementFixtureHardeningZeroLengthEdges: Int? = nil,
        multiAgentMovementFixtureHardeningAllDeniedCases: Int? = nil,
        multiAgentMovementFixtureHardeningEmptyIntentCases: Int? = nil,
        multiAgentMovementFixtureHardeningMaxAgentsExceeded: Int? = nil,
        multiAgentMovementFixtureHardeningWorldUsed: Bool? = nil,
        multiAgentMovementFixtureHardeningPathfindingPerformed: Bool? = nil,
        multiAgentMovementFixtureHardeningReplanningPerformed: Bool? = nil,
        multiAgentMovementFixtureHardeningPhysicsPerformed: Bool? = nil,
        multiAgentMovementFixtureHardeningMutationPerformed: Bool? = nil,
        multiAgentMovementFixtureHardeningSuccess: Bool? = nil,
        multiAgentLiveCollisionIntentCases: Int? = nil,
        multiAgentLiveCollisionIntentPassed: Int? = nil,
        multiAgentLiveCollisionIntentFailed: Int? = nil,
        multiAgentLiveCollisionIntentAgentCount: Int? = nil,
        multiAgentLiveCollisionIntentIntentCount: Int? = nil,
        multiAgentLiveCollisionIntentApproved: Int? = nil,
        multiAgentLiveCollisionIntentDenied: Int? = nil,
        multiAgentLiveCollisionIntentOccupableDestinations: Int? = nil,
        multiAgentLiveCollisionIntentNonOccupableDestinations: Int? = nil,
        multiAgentLiveCollisionIntentCollisionDenied: Int? = nil,
        multiAgentLiveCollisionIntentSameDestinationConflicts: Int? = nil,
        multiAgentLiveCollisionIntentSourceMismatch: Int? = nil,
        multiAgentLiveCollisionIntentInvalidEdges: Int? = nil,
        multiAgentLiveCollisionIntentStaleIntent: Int? = nil,
        multiAgentLiveCollisionIntentWorldUsed: Bool? = nil,
        multiAgentLiveCollisionIntentLiveCollisionRead: Bool? = nil,
        multiAgentLiveCollisionIntentDisplacementApplied: Bool? = nil,
        multiAgentLiveCollisionIntentPhysicalMovementApplied: Bool? = nil,
        multiAgentLiveCollisionIntentRouteFollowingApplied: Bool? = nil,
        multiAgentLiveCollisionIntentPathfindingPerformed: Bool? = nil,
        multiAgentLiveCollisionIntentReplanningPerformed: Bool? = nil,
        multiAgentLiveCollisionIntentPhysicsPerformed: Bool? = nil,
        multiAgentLiveCollisionIntentMutationPerformed: Bool? = nil,
        multiAgentLiveCollisionIntentSuccess: Bool? = nil,
        multiAgentApprovedPhysicalMovementCases: Int? = nil,
        multiAgentApprovedPhysicalMovementPassed: Int? = nil,
        multiAgentApprovedPhysicalMovementFailed: Int? = nil,
        multiAgentApprovedPhysicalMovementAgentCount: Int? = nil,
        multiAgentApprovedPhysicalMovementIntentCount: Int? = nil,
        multiAgentApprovedPhysicalMovementApproved: Int? = nil,
        multiAgentApprovedPhysicalMovementDenied: Int? = nil,
        multiAgentApprovedPhysicalMovementDisplacementsApplied: Int? = nil,
        multiAgentApprovedPhysicalMovementOccupableDestinations: Int? = nil,
        multiAgentApprovedPhysicalMovementNonOccupableDestinations: Int? = nil,
        multiAgentApprovedPhysicalMovementDivergenceBeforeMax: Int? = nil,
        multiAgentApprovedPhysicalMovementDivergenceAfterMax: Int? = nil,
        multiAgentApprovedPhysicalMovementWorldUsed: Bool? = nil,
        multiAgentApprovedPhysicalMovementLiveCollisionRead: Bool? = nil,
        multiAgentApprovedPhysicalMovementPhysicalMovementApplied: Bool? = nil,
        multiAgentApprovedPhysicalMovementRouteFollowingApplied: Bool? = nil,
        multiAgentApprovedPhysicalMovementPathfindingPerformed: Bool? = nil,
        multiAgentApprovedPhysicalMovementReplanningPerformed: Bool? = nil,
        multiAgentApprovedPhysicalMovementPhysicsPerformed: Bool? = nil,
        multiAgentApprovedPhysicalMovementTerrainMutationPerformed: Bool? = nil,
        multiAgentApprovedPhysicalMovementWorldMutationPerformed: Bool? = nil,
        multiAgentApprovedPhysicalMovementSuccess: Bool? = nil,
        multiAgentMovementHardeningCases: Int? = nil,
        multiAgentMovementHardeningPassed: Int? = nil,
        multiAgentMovementHardeningFailed: Int? = nil,
        multiAgentMovementHardeningAgentCount: Int? = nil,
        multiAgentMovementHardeningIntentCount: Int? = nil,
        multiAgentMovementHardeningApproved: Int? = nil,
        multiAgentMovementHardeningDenied: Int? = nil,
        multiAgentMovementHardeningDisplacementsApplied: Int? = nil,
        multiAgentMovementHardeningOccupableDestinations: Int? = nil,
        multiAgentMovementHardeningNonOccupableDestinations: Int? = nil,
        multiAgentMovementHardeningCollisionDenied: Int? = nil,
        multiAgentMovementHardeningSameDestinationConflicts: Int? = nil,
        multiAgentMovementHardeningSwapConflicts: Int? = nil,
        multiAgentMovementHardeningSourceMismatch: Int? = nil,
        multiAgentMovementHardeningStaleIntent: Int? = nil,
        multiAgentMovementHardeningInvalidEdges: Int? = nil,
        multiAgentMovementHardeningDivergenceDenied: Int? = nil,
        multiAgentMovementHardeningStaleCollision: Int? = nil,
        multiAgentMovementHardeningPartialApprovalCases: Int? = nil,
        multiAgentMovementHardeningAllDeniedCases: Int? = nil,
        multiAgentMovementHardeningMaxAgentsExceeded: Int? = nil,
        multiAgentMovementHardeningDivergenceBeforeMax: Int? = nil,
        multiAgentMovementHardeningDivergenceAfterMax: Int? = nil,
        multiAgentMovementHardeningWorldUsed: Bool? = nil,
        multiAgentMovementHardeningLiveCollisionRead: Bool? = nil,
        multiAgentMovementHardeningPhysicalMovementApplied: Bool? = nil,
        multiAgentMovementHardeningRouteFollowingApplied: Bool? = nil,
        multiAgentMovementHardeningPathfindingPerformed: Bool? = nil,
        multiAgentMovementHardeningReplanningPerformed: Bool? = nil,
        multiAgentMovementHardeningPhysicsPerformed: Bool? = nil,
        multiAgentMovementHardeningTerrainMutationPerformed: Bool? = nil,
        multiAgentMovementHardeningWorldMutationPerformed: Bool? = nil,
        multiAgentMovementHardeningSuccess: Bool? = nil,
        multiAgentMovementTickFixtureInputs: Int? = nil,
        multiAgentMovementTickFixtureAgents: Int? = nil,
        multiAgentMovementTickFixturePhysicalPositions: Int? = nil,
        multiAgentMovementTickFixtureIntents: Int? = nil,
        multiAgentMovementTickFixtureResolutions: Int? = nil,
        multiAgentMovementTickFixtureFeedback: Int? = nil,
        multiAgentMovementTickFixtureApproved: Int? = nil,
        multiAgentMovementTickFixtureDenied: Int? = nil,
        multiAgentMovementTickFixtureDisplacementsApplied: Int? = nil,
        multiAgentMovementTickFixtureSameDestinationConflicts: Int? = nil,
        multiAgentMovementTickFixtureInvalidEdges: Int? = nil,
        multiAgentMovementTickFixtureWorldUsed: Bool? = nil,
        multiAgentMovementTickFixtureLiveCollisionRead: Bool? = nil,
        multiAgentMovementTickFixturePhysicalMovementApplied: Bool? = nil,
        multiAgentMovementTickFixtureRouteFollowingApplied: Bool? = nil,
        multiAgentMovementTickFixturePathfindingPerformed: Bool? = nil,
        multiAgentMovementTickFixtureReplanningPerformed: Bool? = nil,
        multiAgentMovementTickFixtureAvoidancePerformed: Bool? = nil,
        multiAgentMovementTickFixtureReservationRuntimeUsed: Bool? = nil,
        multiAgentMovementTickFixturePhysicsPerformed: Bool? = nil,
        multiAgentMovementTickFixtureMutationPerformed: Bool? = nil,
        multiAgentMovementTickFixtureSuccess: Bool? = nil,
        multiAgentMovementTickLiveReadonlyInputs: Int? = nil,
        multiAgentMovementTickLiveReadonlyAgents: Int? = nil,
        multiAgentMovementTickLiveReadonlyPhysicalPositions: Int? = nil,
        multiAgentMovementTickLiveReadonlyIntents: Int? = nil,
        multiAgentMovementTickLiveReadonlyResolutions: Int? = nil,
        multiAgentMovementTickLiveReadonlyFeedback: Int? = nil,
        multiAgentMovementTickLiveReadonlyApproved: Int? = nil,
        multiAgentMovementTickLiveReadonlyDenied: Int? = nil,
        multiAgentMovementTickLiveReadonlyOccupableDestinations: Int? = nil,
        multiAgentMovementTickLiveReadonlyNonOccupableDestinations: Int? = nil,
        multiAgentMovementTickLiveReadonlyCollisionDenied: Int? = nil,
        multiAgentMovementTickLiveReadonlySourceMismatch: Int? = nil,
        multiAgentMovementTickLiveReadonlyInvalidEdges: Int? = nil,
        multiAgentMovementTickLiveReadonlyStaleIntent: Int? = nil,
        multiAgentMovementTickLiveReadonlyDisplacementsApplied: Int? = nil,
        multiAgentMovementTickLiveReadonlyWorldUsed: Bool? = nil,
        multiAgentMovementTickLiveReadonlyLiveCollisionRead: Bool? = nil,
        multiAgentMovementTickLiveReadonlyPhysicalMovementApplied: Bool? = nil,
        multiAgentMovementTickLiveReadonlyRouteFollowingApplied: Bool? = nil,
        multiAgentMovementTickLiveReadonlyPathfindingPerformed: Bool? = nil,
        multiAgentMovementTickLiveReadonlyReplanningPerformed: Bool? = nil,
        multiAgentMovementTickLiveReadonlyAvoidancePerformed: Bool? = nil,
        multiAgentMovementTickLiveReadonlyReservationRuntimeUsed: Bool? = nil,
        multiAgentMovementTickLiveReadonlyPhysicsPerformed: Bool? = nil,
        multiAgentMovementTickLiveReadonlyMutationPerformed: Bool? = nil,
        multiAgentMovementTickLiveReadonlySuccess: Bool? = nil,
        multiAgentMovementTickApprovedApplicationInputs: Int? = nil,
        multiAgentMovementTickApprovedApplicationAgents: Int? = nil,
        multiAgentMovementTickApprovedApplicationPhysicalPositions: Int? = nil,
        multiAgentMovementTickApprovedApplicationIntents: Int? = nil,
        multiAgentMovementTickApprovedApplicationResolutions: Int? = nil,
        multiAgentMovementTickApprovedApplicationFeedback: Int? = nil,
        multiAgentMovementTickApprovedApplicationApproved: Int? = nil,
        multiAgentMovementTickApprovedApplicationDenied: Int? = nil,
        multiAgentMovementTickApprovedApplicationOccupableDestinations: Int? = nil,
        multiAgentMovementTickApprovedApplicationNonOccupableDestinations: Int? = nil,
        multiAgentMovementTickApprovedApplicationDisplacementsApplied: Int? = nil,
        multiAgentMovementTickApprovedApplicationDivergenceBeforeMax: Int? = nil,
        multiAgentMovementTickApprovedApplicationDivergenceAfterMax: Int? = nil,
        multiAgentMovementTickApprovedApplicationWorldUsed: Bool? = nil,
        multiAgentMovementTickApprovedApplicationLiveCollisionRead: Bool? = nil,
        multiAgentMovementTickApprovedApplicationPhysicalMovementApplied: Bool? = nil,
        multiAgentMovementTickApprovedApplicationRouteFollowingApplied: Bool? = nil,
        multiAgentMovementTickApprovedApplicationPathfindingPerformed: Bool? = nil,
        multiAgentMovementTickApprovedApplicationReplanningPerformed: Bool? = nil,
        multiAgentMovementTickApprovedApplicationAvoidancePerformed: Bool? = nil,
        multiAgentMovementTickApprovedApplicationReservationRuntimeUsed: Bool? = nil,
        multiAgentMovementTickApprovedApplicationPhysicsPerformed: Bool? = nil,
        multiAgentMovementTickApprovedApplicationTerrainMutationPerformed: Bool? = nil,
        multiAgentMovementTickApprovedApplicationWorldMutationPerformed: Bool? = nil,
        multiAgentMovementTickApprovedApplicationSuccess: Bool? = nil,
        multiAgentMovementTickHardeningCases: Int? = nil,
        multiAgentMovementTickHardeningPassed: Int? = nil,
        multiAgentMovementTickHardeningFailed: Int? = nil,
        multiAgentMovementTickHardeningTicks: Int? = nil,
        multiAgentMovementTickHardeningAgents: Int? = nil,
        multiAgentMovementTickHardeningIntents: Int? = nil,
        multiAgentMovementTickHardeningResolutions: Int? = nil,
        multiAgentMovementTickHardeningFeedback: Int? = nil,
        multiAgentMovementTickHardeningApproved: Int? = nil,
        multiAgentMovementTickHardeningDenied: Int? = nil,
        multiAgentMovementTickHardeningDisplacementsApplied: Int? = nil,
        multiAgentMovementTickHardeningOccupableDestinations: Int? = nil,
        multiAgentMovementTickHardeningNonOccupableDestinations: Int? = nil,
        multiAgentMovementTickHardeningCollisionDenied: Int? = nil,
        multiAgentMovementTickHardeningSameDestinationConflicts: Int? = nil,
        multiAgentMovementTickHardeningSwapConflicts: Int? = nil,
        multiAgentMovementTickHardeningSourceMismatch: Int? = nil,
        multiAgentMovementTickHardeningStaleIntent: Int? = nil,
        multiAgentMovementTickHardeningInvalidEdges: Int? = nil,
        multiAgentMovementTickHardeningDivergenceDenied: Int? = nil,
        multiAgentMovementTickHardeningStaleCollision: Int? = nil,
        multiAgentMovementTickHardeningPartialApprovalCases: Int? = nil,
        multiAgentMovementTickHardeningAllDeniedCases: Int? = nil,
        multiAgentMovementTickHardeningMaxAgentsExceeded: Int? = nil,
        multiAgentMovementTickHardeningMovedFeedback: Int? = nil,
        multiAgentMovementTickHardeningApprovedForMovementFeedback: Int? = nil,
        multiAgentMovementTickHardeningBlockedByCollisionFeedback: Int? = nil,
        multiAgentMovementTickHardeningBlockedByAgentConflictFeedback: Int? = nil,
        multiAgentMovementTickHardeningBlockedBySourceMismatchFeedback: Int? = nil,
        multiAgentMovementTickHardeningBlockedByDivergenceFeedback: Int? = nil,
        multiAgentMovementTickHardeningBlockedByStaleIntentFeedback: Int? = nil,
        multiAgentMovementTickHardeningBlockedByInvalidEdgeFeedback: Int? = nil,
        multiAgentMovementTickHardeningBlockedByMaxAgentsFeedback: Int? = nil,
        multiAgentMovementTickHardeningDivergenceBeforeMax: Int? = nil,
        multiAgentMovementTickHardeningDivergenceAfterMax: Int? = nil,
        multiAgentMovementTickHardeningWorldUsed: Bool? = nil,
        multiAgentMovementTickHardeningLiveCollisionRead: Bool? = nil,
        multiAgentMovementTickHardeningPhysicalMovementApplied: Bool? = nil,
        multiAgentMovementTickHardeningRouteFollowingApplied: Bool? = nil,
        multiAgentMovementTickHardeningPathfindingPerformed: Bool? = nil,
        multiAgentMovementTickHardeningReplanningPerformed: Bool? = nil,
        multiAgentMovementTickHardeningAvoidancePerformed: Bool? = nil,
        multiAgentMovementTickHardeningReservationRuntimeUsed: Bool? = nil,
        multiAgentMovementTickHardeningPhysicsPerformed: Bool? = nil,
        multiAgentMovementTickHardeningTerrainMutationPerformed: Bool? = nil,
        multiAgentMovementTickHardeningWorldMutationPerformed: Bool? = nil,
        multiAgentMovementTickHardeningSuccess: Bool? = nil,
        agentIntentProductionFixtureAgentsObserved: Int? = nil,
        agentIntentProductionFixtureContexts: Int? = nil,
        agentIntentProductionFixtureProposals: Int? = nil,
        agentIntentProductionFixtureAcceptedIntents: Int? = nil,
        agentIntentProductionFixtureRejectedProposals: Int? = nil,
        agentIntentProductionFixtureNoIntent: Int? = nil,
        agentIntentProductionFixtureInvalidContext: Int? = nil,
        agentIntentProductionFixtureDuplicateAgentContexts: Int? = nil,
        agentIntentProductionFixtureInvalidOneEdgeProposals: Int? = nil,
        agentIntentProductionFixtureAcceptedMoveEast: Int? = nil,
        agentIntentProductionFixtureAcceptedMoveWest: Int? = nil,
        agentIntentProductionFixtureAcceptedMoveNorth: Int? = nil,
        agentIntentProductionFixtureAcceptedMoveSouth: Int? = nil,
        agentIntentProductionFixtureWorldUsed: Bool? = nil,
        agentIntentProductionFixtureCollisionRead: Bool? = nil,
        agentIntentProductionFixtureMovementApplied: Bool? = nil,
        agentIntentProductionFixtureFeedbackConsumed: Bool? = nil,
        agentIntentProductionFixtureMemoryUpdated: Bool? = nil,
        agentIntentProductionFixtureGoalChanged: Bool? = nil,
        agentIntentProductionFixturePathfindingPerformed: Bool? = nil,
        agentIntentProductionFixtureReplanningPerformed: Bool? = nil,
        agentIntentProductionFixtureAvoidancePerformed: Bool? = nil,
        agentIntentProductionFixtureReservationRuntimeUsed: Bool? = nil,
        agentIntentProductionFixtureMutationPerformed: Bool? = nil,
        agentIntentProductionFixtureSuccess: Bool? = nil,
        agentIntentProductionHardeningCases: Int? = nil,
        agentIntentProductionHardeningPassed: Int? = nil,
        agentIntentProductionHardeningFailed: Int? = nil,
        agentIntentProductionHardeningContexts: Int? = nil,
        agentIntentProductionHardeningProposals: Int? = nil,
        agentIntentProductionHardeningAcceptedIntents: Int? = nil,
        agentIntentProductionHardeningRejectedProposals: Int? = nil,
        agentIntentProductionHardeningNoIntent: Int? = nil,
        agentIntentProductionHardeningInvalidContext: Int? = nil,
        agentIntentProductionHardeningDuplicateAgentContexts: Int? = nil,
        agentIntentProductionHardeningDuplicateProposals: Int? = nil,
        agentIntentProductionHardeningInvalidOneEdgeProposals: Int? = nil,
        agentIntentProductionHardeningStaleProposals: Int? = nil,
        agentIntentProductionHardeningWrongSourceProposals: Int? = nil,
        agentIntentProductionHardeningMaxProposalsExceeded: Int? = nil,
        agentIntentProductionHardeningAcceptedMoveEast: Int? = nil,
        agentIntentProductionHardeningAcceptedMoveWest: Int? = nil,
        agentIntentProductionHardeningAcceptedMoveNorth: Int? = nil,
        agentIntentProductionHardeningAcceptedMoveSouth: Int? = nil,
        agentIntentProductionHardeningWorldUsed: Bool? = nil,
        agentIntentProductionHardeningCollisionRead: Bool? = nil,
        agentIntentProductionHardeningMovementApplied: Bool? = nil,
        agentIntentProductionHardeningFeedbackConsumed: Bool? = nil,
        agentIntentProductionHardeningMemoryUpdated: Bool? = nil,
        agentIntentProductionHardeningGoalChanged: Bool? = nil,
        agentIntentProductionHardeningPathfindingPerformed: Bool? = nil,
        agentIntentProductionHardeningReplanningPerformed: Bool? = nil,
        agentIntentProductionHardeningAvoidancePerformed: Bool? = nil,
        agentIntentProductionHardeningReservationRuntimeUsed: Bool? = nil,
        agentIntentProductionHardeningPhysicsPerformed: Bool? = nil,
        agentIntentProductionHardeningMutationPerformed: Bool? = nil,
        agentIntentProductionHardeningSuccess: Bool? = nil,
        agentIntentToTickFixtureContexts: Int? = nil,
        agentIntentToTickFixtureProposals: Int? = nil,
        agentIntentToTickFixtureAcceptedIntents: Int? = nil,
        agentIntentToTickFixtureRejectedProposals: Int? = nil,
        agentIntentToTickFixtureNoIntent: Int? = nil,
        agentIntentToTickFixtureInvalidOneEdgeProposals: Int? = nil,
        agentIntentToTickFixtureTickAgents: Int? = nil,
        agentIntentToTickFixtureTickIntents: Int? = nil,
        agentIntentToTickFixtureTickResolutions: Int? = nil,
        agentIntentToTickFixtureTickFeedback: Int? = nil,
        agentIntentToTickFixtureTickApproved: Int? = nil,
        agentIntentToTickFixtureTickDenied: Int? = nil,
        agentIntentToTickFixtureSameDestinationConflicts: Int? = nil,
        agentIntentToTickFixtureDisplacementsApplied: Int? = nil,
        agentIntentToTickFixtureProductionAcceptedSameDestination: Bool? = nil,
        agentIntentToTickFixtureTickResolvedSameDestination: Bool? = nil,
        agentIntentToTickFixtureWorldUsed: Bool? = nil,
        agentIntentToTickFixtureCollisionRead: Bool? = nil,
        agentIntentToTickFixtureMovementApplied: Bool? = nil,
        agentIntentToTickFixtureFeedbackConsumed: Bool? = nil,
        agentIntentToTickFixtureMemoryUpdated: Bool? = nil,
        agentIntentToTickFixtureGoalChanged: Bool? = nil,
        agentIntentToTickFixturePathfindingPerformed: Bool? = nil,
        agentIntentToTickFixtureReplanningPerformed: Bool? = nil,
        agentIntentToTickFixtureAvoidancePerformed: Bool? = nil,
        agentIntentToTickFixtureReservationRuntimeUsed: Bool? = nil,
        agentIntentToTickFixturePhysicsPerformed: Bool? = nil,
        agentIntentToTickFixtureMutationPerformed: Bool? = nil,
        agentIntentToTickFixtureSuccess: Bool? = nil,
        agentIntentToTickLiveReadonlyContexts: Int? = nil,
        agentIntentToTickLiveReadonlyProposals: Int? = nil,
        agentIntentToTickLiveReadonlyAcceptedIntents: Int? = nil,
        agentIntentToTickLiveReadonlyRejectedProposals: Int? = nil,
        agentIntentToTickLiveReadonlyNoIntent: Int? = nil,
        agentIntentToTickLiveReadonlyInvalidOneEdgeProposals: Int? = nil,
        agentIntentToTickLiveReadonlyTickAgents: Int? = nil,
        agentIntentToTickLiveReadonlyTickIntents: Int? = nil,
        agentIntentToTickLiveReadonlyTickResolutions: Int? = nil,
        agentIntentToTickLiveReadonlyTickFeedback: Int? = nil,
        agentIntentToTickLiveReadonlyTickApproved: Int? = nil,
        agentIntentToTickLiveReadonlyTickDenied: Int? = nil,
        agentIntentToTickLiveReadonlyOccupableDestinations: Int? = nil,
        agentIntentToTickLiveReadonlyNonOccupableDestinations: Int? = nil,
        agentIntentToTickLiveReadonlyCollisionDenied: Int? = nil,
        agentIntentToTickLiveReadonlyDisplacementsApplied: Int? = nil,
        agentIntentToTickLiveReadonlyProductionReadCollision: Bool? = nil,
        agentIntentToTickLiveReadonlyTickReadCollision: Bool? = nil,
        agentIntentToTickLiveReadonlyWorldUsed: Bool? = nil,
        agentIntentToTickLiveReadonlyCollisionRead: Bool? = nil,
        agentIntentToTickLiveReadonlyMovementApplied: Bool? = nil,
        agentIntentToTickLiveReadonlyFeedbackConsumed: Bool? = nil,
        agentIntentToTickLiveReadonlyMemoryUpdated: Bool? = nil,
        agentIntentToTickLiveReadonlyGoalChanged: Bool? = nil,
        agentIntentToTickLiveReadonlyPathfindingPerformed: Bool? = nil,
        agentIntentToTickLiveReadonlyReplanningPerformed: Bool? = nil,
        agentIntentToTickLiveReadonlyAvoidancePerformed: Bool? = nil,
        agentIntentToTickLiveReadonlyReservationRuntimeUsed: Bool? = nil,
        agentIntentToTickLiveReadonlyPhysicsPerformed: Bool? = nil,
        agentIntentToTickLiveReadonlyMutationPerformed: Bool? = nil,
        agentIntentToTickLiveReadonlySuccess: Bool? = nil,
        routeFollowingFixtureCases: Int? = nil,
        routeFollowingFixturePassed: Int? = nil,
        routeFollowingFixtureFailed: Int? = nil,
        routeFollowingFixtureCompleted: Int? = nil,
        routeFollowingFixtureStopped: Int? = nil,
        routeFollowingFixtureAttemptedEdges: Int? = nil,
        routeFollowingFixtureCompletedEdges: Int? = nil,
        routeFollowingFixtureDisplacementsApplied: Int? = nil,
        routeFollowingFixtureDeniedEdges: Int? = nil,
        routeFollowingFixtureCollisionDenied: Int? = nil,
        routeFollowingFixtureInvalidEdges: Int? = nil,
        routeFollowingFixtureSourceMismatch: Int? = nil,
        routeFollowingFixtureDivergence: Int? = nil,
        routeFollowingFixtureMaxSteps: Int? = nil,
        routeFollowingFixtureSuccess: Bool? = nil,
        routeFollowingLiveAttempted: Bool? = nil,
        routeFollowingLiveCompleted: Bool? = nil,
        routeFollowingLiveStopped: Bool? = nil,
        routeFollowingLiveStatus: String? = nil,
        routeFollowingLiveReason: String? = nil,
        routeFollowingLiveRouteLength: Int? = nil,
        routeFollowingLiveAttemptedEdges: Int? = nil,
        routeFollowingLiveCompletedEdges: Int? = nil,
        routeFollowingLiveStoppedAtIndex: Int? = nil,
        routeFollowingLiveDisplacementsApplied: Int? = nil,
        routeFollowingLiveDeniedEdges: Int? = nil,
        routeFollowingLiveCollisionDenied: Int? = nil,
        routeFollowingLiveInvalidEdges: Int? = nil,
        routeFollowingLiveSourceMismatch: Int? = nil,
        routeFollowingLiveDivergence: Int? = nil,
        routeFollowingLivePathfindingInsideFollower: Bool? = nil,
        routeFollowingLiveReplanningPerformed: Bool? = nil,
        routeFollowingLivePhysicsPerformed: Bool? = nil,
        routeFollowingLiveMutationPerformed: Bool? = nil,
        routeFollowingLiveSuccess: Bool? = nil,
        routeFollowingLiveHardeningCases: Int? = nil,
        routeFollowingLiveHardeningPassed: Int? = nil,
        routeFollowingLiveHardeningFailed: Int? = nil,
        routeFollowingLiveHardeningCompleted: Int? = nil,
        routeFollowingLiveHardeningStopped: Int? = nil,
        routeFollowingLiveHardeningAttemptedEdges: Int? = nil,
        routeFollowingLiveHardeningCompletedEdges: Int? = nil,
        routeFollowingLiveHardeningDisplacementsApplied: Int? = nil,
        routeFollowingLiveHardeningDeniedEdges: Int? = nil,
        routeFollowingLiveHardeningCollisionDenied: Int? = nil,
        routeFollowingLiveHardeningInvalidEdges: Int? = nil,
        routeFollowingLiveHardeningSourceMismatch: Int? = nil,
        routeFollowingLiveHardeningDivergence: Int? = nil,
        routeFollowingLiveHardeningStaleCollision: Int? = nil,
        routeFollowingLiveHardeningMaxSteps: Int? = nil,
        routeFollowingLiveHardeningSuccess: Bool? = nil,
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
        self.terrainCollisionFixtureCases = terrainCollisionFixtureCases
        self.terrainCollisionFixturePassed = terrainCollisionFixturePassed
        self.terrainCollisionFixtureFailed = terrainCollisionFixtureFailed
        self.terrainCollisionOccupable = terrainCollisionOccupable
        self.terrainCollisionBlocked = terrainCollisionBlocked
        self.terrainCollisionUnsupported = terrainCollisionUnsupported
        self.terrainCollisionVerticalSpaceOccupied = terrainCollisionVerticalSpaceOccupied
        self.terrainCollisionLiquidUnsupported = terrainCollisionLiquidUnsupported
        self.terrainCollisionUnknown = terrainCollisionUnknown
        self.terrainCollisionOutOfBounds = terrainCollisionOutOfBounds
        self.terrainCollisionNotLoaded = terrainCollisionNotLoaded
        self.terrainCollisionNotReady = terrainCollisionNotReady
        self.terrainCollisionFixtureSuccess = terrainCollisionFixtureSuccess
        self.terrainCollisionLiveSamples = terrainCollisionLiveSamples
        self.terrainCollisionLiveLoadedSamples = terrainCollisionLiveLoadedSamples
        self.terrainCollisionLiveReadySamples = terrainCollisionLiveReadySamples
        self.terrainCollisionLiveStatus = terrainCollisionLiveStatus
        self.terrainCollisionLiveOccupable = terrainCollisionLiveOccupable
        self.terrainCollisionLiveBlocked = terrainCollisionLiveBlocked
        self.terrainCollisionLiveUnsupported = terrainCollisionLiveUnsupported
        self.terrainCollisionLiveVerticalSpaceOccupied = terrainCollisionLiveVerticalSpaceOccupied
        self.terrainCollisionLiveLiquidUnsupported = terrainCollisionLiveLiquidUnsupported
        self.terrainCollisionLiveUnknown = terrainCollisionLiveUnknown
        self.terrainCollisionLiveOutOfBounds = terrainCollisionLiveOutOfBounds
        self.terrainCollisionLiveNotLoaded = terrainCollisionLiveNotLoaded
        self.terrainCollisionLiveNotReady = terrainCollisionLiveNotReady
        self.terrainCollisionLiveMovementPerformed = terrainCollisionLiveMovementPerformed
        self.terrainCollisionLivePathfindingPerformed = terrainCollisionLivePathfindingPerformed
        self.terrainCollisionLiveMutationPerformed = terrainCollisionLiveMutationPerformed
        self.terrainCollisionLiveSuccess = terrainCollisionLiveSuccess
        self.physicalMovementAttempted = physicalMovementAttempted
        self.physicalMovementApproved = physicalMovementApproved
        self.physicalMovementDenied = physicalMovementDenied
        self.physicalMovementStatus = physicalMovementStatus
        self.physicalMovementReason = physicalMovementReason
        self.physicalMovementFromX = physicalMovementFromX
        self.physicalMovementFromY = physicalMovementFromY
        self.physicalMovementFromZ = physicalMovementFromZ
        self.physicalMovementToX = physicalMovementToX
        self.physicalMovementToY = physicalMovementToY
        self.physicalMovementToZ = physicalMovementToZ
        self.physicalMovementCollisionStatus = physicalMovementCollisionStatus
        self.physicalMovementDisplacementApplied = physicalMovementDisplacementApplied
        self.physicalMovementPathfindingPerformed = physicalMovementPathfindingPerformed
        self.physicalMovementRouteFollowingPerformed = physicalMovementRouteFollowingPerformed
        self.physicalMovementPhysicsPerformed = physicalMovementPhysicsPerformed
        self.physicalMovementMutationPerformed = physicalMovementMutationPerformed
        self.physicalMovementDivergenceBefore = physicalMovementDivergenceBefore
        self.physicalMovementDivergenceAfter = physicalMovementDivergenceAfter
        self.physicalMovementSuccess = physicalMovementSuccess
        self.physicalMovementOccupableSearchCandidates = physicalMovementOccupableSearchCandidates
        self.physicalMovementOccupableSearchFound = physicalMovementOccupableSearchFound
        self.physicalMovementOccupableSearchSelectedIndex = physicalMovementOccupableSearchSelectedIndex
        self.physicalMovementOccupableSearchSelectedX = physicalMovementOccupableSearchSelectedX
        self.physicalMovementOccupableSearchSelectedY = physicalMovementOccupableSearchSelectedY
        self.physicalMovementOccupableSearchSelectedZ = physicalMovementOccupableSearchSelectedZ
        self.physicalMovementOccupableSearchSelectedStatus = physicalMovementOccupableSearchSelectedStatus
        self.physicalMovementOccupableSearchMovementPerformed = physicalMovementOccupableSearchMovementPerformed
        self.physicalMovementOccupableSearchPathfindingPerformed = physicalMovementOccupableSearchPathfindingPerformed
        self.physicalMovementOccupableSearchRouteFollowingPerformed = physicalMovementOccupableSearchRouteFollowingPerformed
        self.physicalMovementOccupableSearchPhysicsPerformed = physicalMovementOccupableSearchPhysicsPerformed
        self.physicalMovementOccupableSearchMutationPerformed = physicalMovementOccupableSearchMutationPerformed
        self.physicalMovementOccupableSearchSuccess = physicalMovementOccupableSearchSuccess
        self.physicalMovementHardeningCases = physicalMovementHardeningCases
        self.physicalMovementHardeningPassed = physicalMovementHardeningPassed
        self.physicalMovementHardeningFailed = physicalMovementHardeningFailed
        self.physicalMovementHardeningApproved = physicalMovementHardeningApproved
        self.physicalMovementHardeningDenied = physicalMovementHardeningDenied
        self.physicalMovementHardeningCollisionDenied = physicalMovementHardeningCollisionDenied
        self.physicalMovementHardeningSourceMismatch = physicalMovementHardeningSourceMismatch
        self.physicalMovementHardeningMissingPhysicalHandle = physicalMovementHardeningMissingPhysicalHandle
        self.physicalMovementHardeningDivergenceBeforeMove = physicalMovementHardeningDivergenceBeforeMove
        self.physicalMovementHardeningDisplacementApplied = physicalMovementHardeningDisplacementApplied
        self.physicalMovementHardeningDisplacementRefused = physicalMovementHardeningDisplacementRefused
        self.physicalMovementHardeningSuccess = physicalMovementHardeningSuccess
        self.multiAgentMovementFixtureCases = multiAgentMovementFixtureCases
        self.multiAgentMovementFixturePassed = multiAgentMovementFixturePassed
        self.multiAgentMovementFixtureFailed = multiAgentMovementFixtureFailed
        self.multiAgentMovementFixtureAgentCount = multiAgentMovementFixtureAgentCount
        self.multiAgentMovementFixtureIntentCount = multiAgentMovementFixtureIntentCount
        self.multiAgentMovementFixtureApproved = multiAgentMovementFixtureApproved
        self.multiAgentMovementFixtureDenied = multiAgentMovementFixtureDenied
        self.multiAgentMovementFixtureSameDestinationConflicts = multiAgentMovementFixtureSameDestinationConflicts
        self.multiAgentMovementFixtureOccupiedDestinationConflicts = multiAgentMovementFixtureOccupiedDestinationConflicts
        self.multiAgentMovementFixtureSwapConflicts = multiAgentMovementFixtureSwapConflicts
        self.multiAgentMovementFixtureSourceMismatch = multiAgentMovementFixtureSourceMismatch
        self.multiAgentMovementFixtureStaleIntent = multiAgentMovementFixtureStaleIntent
        self.multiAgentMovementFixtureMissingAgent = multiAgentMovementFixtureMissingAgent
        self.multiAgentMovementFixtureInvalidEdges = multiAgentMovementFixtureInvalidEdges
        self.multiAgentMovementFixturePathfindingPerformed = multiAgentMovementFixturePathfindingPerformed
        self.multiAgentMovementFixtureReplanningPerformed = multiAgentMovementFixtureReplanningPerformed
        self.multiAgentMovementFixturePhysicsPerformed = multiAgentMovementFixturePhysicsPerformed
        self.multiAgentMovementFixtureMutationPerformed = multiAgentMovementFixtureMutationPerformed
        self.multiAgentMovementFixtureSuccess = multiAgentMovementFixtureSuccess
        self.multiAgentMovementFixtureHardeningCases = multiAgentMovementFixtureHardeningCases
        self.multiAgentMovementFixtureHardeningPassed = multiAgentMovementFixtureHardeningPassed
        self.multiAgentMovementFixtureHardeningFailed = multiAgentMovementFixtureHardeningFailed
        self.multiAgentMovementFixtureHardeningApproved = multiAgentMovementFixtureHardeningApproved
        self.multiAgentMovementFixtureHardeningDenied = multiAgentMovementFixtureHardeningDenied
        self.multiAgentMovementFixtureHardeningDuplicateIntent = multiAgentMovementFixtureHardeningDuplicateIntent
        self.multiAgentMovementFixtureHardeningCycleConflicts = multiAgentMovementFixtureHardeningCycleConflicts
        self.multiAgentMovementFixtureHardeningChainDependencies = multiAgentMovementFixtureHardeningChainDependencies
        self.multiAgentMovementFixtureHardeningMovingAwayDestination = multiAgentMovementFixtureHardeningMovingAwayDestination
        self.multiAgentMovementFixtureHardeningVerticalInvalidEdges = multiAgentMovementFixtureHardeningVerticalInvalidEdges
        self.multiAgentMovementFixtureHardeningZeroLengthEdges = multiAgentMovementFixtureHardeningZeroLengthEdges
        self.multiAgentMovementFixtureHardeningAllDeniedCases = multiAgentMovementFixtureHardeningAllDeniedCases
        self.multiAgentMovementFixtureHardeningEmptyIntentCases = multiAgentMovementFixtureHardeningEmptyIntentCases
        self.multiAgentMovementFixtureHardeningMaxAgentsExceeded = multiAgentMovementFixtureHardeningMaxAgentsExceeded
        self.multiAgentMovementFixtureHardeningWorldUsed = multiAgentMovementFixtureHardeningWorldUsed
        self.multiAgentMovementFixtureHardeningPathfindingPerformed = multiAgentMovementFixtureHardeningPathfindingPerformed
        self.multiAgentMovementFixtureHardeningReplanningPerformed = multiAgentMovementFixtureHardeningReplanningPerformed
        self.multiAgentMovementFixtureHardeningPhysicsPerformed = multiAgentMovementFixtureHardeningPhysicsPerformed
        self.multiAgentMovementFixtureHardeningMutationPerformed = multiAgentMovementFixtureHardeningMutationPerformed
        self.multiAgentMovementFixtureHardeningSuccess = multiAgentMovementFixtureHardeningSuccess
        self.multiAgentLiveCollisionIntentCases = multiAgentLiveCollisionIntentCases
        self.multiAgentLiveCollisionIntentPassed = multiAgentLiveCollisionIntentPassed
        self.multiAgentLiveCollisionIntentFailed = multiAgentLiveCollisionIntentFailed
        self.multiAgentLiveCollisionIntentAgentCount = multiAgentLiveCollisionIntentAgentCount
        self.multiAgentLiveCollisionIntentIntentCount = multiAgentLiveCollisionIntentIntentCount
        self.multiAgentLiveCollisionIntentApproved = multiAgentLiveCollisionIntentApproved
        self.multiAgentLiveCollisionIntentDenied = multiAgentLiveCollisionIntentDenied
        self.multiAgentLiveCollisionIntentOccupableDestinations = multiAgentLiveCollisionIntentOccupableDestinations
        self.multiAgentLiveCollisionIntentNonOccupableDestinations = multiAgentLiveCollisionIntentNonOccupableDestinations
        self.multiAgentLiveCollisionIntentCollisionDenied = multiAgentLiveCollisionIntentCollisionDenied
        self.multiAgentLiveCollisionIntentSameDestinationConflicts = multiAgentLiveCollisionIntentSameDestinationConflicts
        self.multiAgentLiveCollisionIntentSourceMismatch = multiAgentLiveCollisionIntentSourceMismatch
        self.multiAgentLiveCollisionIntentInvalidEdges = multiAgentLiveCollisionIntentInvalidEdges
        self.multiAgentLiveCollisionIntentStaleIntent = multiAgentLiveCollisionIntentStaleIntent
        self.multiAgentLiveCollisionIntentWorldUsed = multiAgentLiveCollisionIntentWorldUsed
        self.multiAgentLiveCollisionIntentLiveCollisionRead = multiAgentLiveCollisionIntentLiveCollisionRead
        self.multiAgentLiveCollisionIntentDisplacementApplied = multiAgentLiveCollisionIntentDisplacementApplied
        self.multiAgentLiveCollisionIntentPhysicalMovementApplied = multiAgentLiveCollisionIntentPhysicalMovementApplied
        self.multiAgentLiveCollisionIntentRouteFollowingApplied = multiAgentLiveCollisionIntentRouteFollowingApplied
        self.multiAgentLiveCollisionIntentPathfindingPerformed = multiAgentLiveCollisionIntentPathfindingPerformed
        self.multiAgentLiveCollisionIntentReplanningPerformed = multiAgentLiveCollisionIntentReplanningPerformed
        self.multiAgentLiveCollisionIntentPhysicsPerformed = multiAgentLiveCollisionIntentPhysicsPerformed
        self.multiAgentLiveCollisionIntentMutationPerformed = multiAgentLiveCollisionIntentMutationPerformed
        self.multiAgentLiveCollisionIntentSuccess = multiAgentLiveCollisionIntentSuccess
        self.multiAgentApprovedPhysicalMovementCases = multiAgentApprovedPhysicalMovementCases
        self.multiAgentApprovedPhysicalMovementPassed = multiAgentApprovedPhysicalMovementPassed
        self.multiAgentApprovedPhysicalMovementFailed = multiAgentApprovedPhysicalMovementFailed
        self.multiAgentApprovedPhysicalMovementAgentCount = multiAgentApprovedPhysicalMovementAgentCount
        self.multiAgentApprovedPhysicalMovementIntentCount = multiAgentApprovedPhysicalMovementIntentCount
        self.multiAgentApprovedPhysicalMovementApproved = multiAgentApprovedPhysicalMovementApproved
        self.multiAgentApprovedPhysicalMovementDenied = multiAgentApprovedPhysicalMovementDenied
        self.multiAgentApprovedPhysicalMovementDisplacementsApplied = multiAgentApprovedPhysicalMovementDisplacementsApplied
        self.multiAgentApprovedPhysicalMovementOccupableDestinations = multiAgentApprovedPhysicalMovementOccupableDestinations
        self.multiAgentApprovedPhysicalMovementNonOccupableDestinations = multiAgentApprovedPhysicalMovementNonOccupableDestinations
        self.multiAgentApprovedPhysicalMovementDivergenceBeforeMax = multiAgentApprovedPhysicalMovementDivergenceBeforeMax
        self.multiAgentApprovedPhysicalMovementDivergenceAfterMax = multiAgentApprovedPhysicalMovementDivergenceAfterMax
        self.multiAgentApprovedPhysicalMovementWorldUsed = multiAgentApprovedPhysicalMovementWorldUsed
        self.multiAgentApprovedPhysicalMovementLiveCollisionRead = multiAgentApprovedPhysicalMovementLiveCollisionRead
        self.multiAgentApprovedPhysicalMovementPhysicalMovementApplied = multiAgentApprovedPhysicalMovementPhysicalMovementApplied
        self.multiAgentApprovedPhysicalMovementRouteFollowingApplied = multiAgentApprovedPhysicalMovementRouteFollowingApplied
        self.multiAgentApprovedPhysicalMovementPathfindingPerformed = multiAgentApprovedPhysicalMovementPathfindingPerformed
        self.multiAgentApprovedPhysicalMovementReplanningPerformed = multiAgentApprovedPhysicalMovementReplanningPerformed
        self.multiAgentApprovedPhysicalMovementPhysicsPerformed = multiAgentApprovedPhysicalMovementPhysicsPerformed
        self.multiAgentApprovedPhysicalMovementTerrainMutationPerformed = multiAgentApprovedPhysicalMovementTerrainMutationPerformed
        self.multiAgentApprovedPhysicalMovementWorldMutationPerformed = multiAgentApprovedPhysicalMovementWorldMutationPerformed
        self.multiAgentApprovedPhysicalMovementSuccess = multiAgentApprovedPhysicalMovementSuccess
        self.multiAgentMovementHardeningCases = multiAgentMovementHardeningCases
        self.multiAgentMovementHardeningPassed = multiAgentMovementHardeningPassed
        self.multiAgentMovementHardeningFailed = multiAgentMovementHardeningFailed
        self.multiAgentMovementHardeningAgentCount = multiAgentMovementHardeningAgentCount
        self.multiAgentMovementHardeningIntentCount = multiAgentMovementHardeningIntentCount
        self.multiAgentMovementHardeningApproved = multiAgentMovementHardeningApproved
        self.multiAgentMovementHardeningDenied = multiAgentMovementHardeningDenied
        self.multiAgentMovementHardeningDisplacementsApplied = multiAgentMovementHardeningDisplacementsApplied
        self.multiAgentMovementHardeningOccupableDestinations = multiAgentMovementHardeningOccupableDestinations
        self.multiAgentMovementHardeningNonOccupableDestinations = multiAgentMovementHardeningNonOccupableDestinations
        self.multiAgentMovementHardeningCollisionDenied = multiAgentMovementHardeningCollisionDenied
        self.multiAgentMovementHardeningSameDestinationConflicts = multiAgentMovementHardeningSameDestinationConflicts
        self.multiAgentMovementHardeningSwapConflicts = multiAgentMovementHardeningSwapConflicts
        self.multiAgentMovementHardeningSourceMismatch = multiAgentMovementHardeningSourceMismatch
        self.multiAgentMovementHardeningStaleIntent = multiAgentMovementHardeningStaleIntent
        self.multiAgentMovementHardeningInvalidEdges = multiAgentMovementHardeningInvalidEdges
        self.multiAgentMovementHardeningDivergenceDenied = multiAgentMovementHardeningDivergenceDenied
        self.multiAgentMovementHardeningStaleCollision = multiAgentMovementHardeningStaleCollision
        self.multiAgentMovementHardeningPartialApprovalCases = multiAgentMovementHardeningPartialApprovalCases
        self.multiAgentMovementHardeningAllDeniedCases = multiAgentMovementHardeningAllDeniedCases
        self.multiAgentMovementHardeningMaxAgentsExceeded = multiAgentMovementHardeningMaxAgentsExceeded
        self.multiAgentMovementHardeningDivergenceBeforeMax = multiAgentMovementHardeningDivergenceBeforeMax
        self.multiAgentMovementHardeningDivergenceAfterMax = multiAgentMovementHardeningDivergenceAfterMax
        self.multiAgentMovementHardeningWorldUsed = multiAgentMovementHardeningWorldUsed
        self.multiAgentMovementHardeningLiveCollisionRead = multiAgentMovementHardeningLiveCollisionRead
        self.multiAgentMovementHardeningPhysicalMovementApplied = multiAgentMovementHardeningPhysicalMovementApplied
        self.multiAgentMovementHardeningRouteFollowingApplied = multiAgentMovementHardeningRouteFollowingApplied
        self.multiAgentMovementHardeningPathfindingPerformed = multiAgentMovementHardeningPathfindingPerformed
        self.multiAgentMovementHardeningReplanningPerformed = multiAgentMovementHardeningReplanningPerformed
        self.multiAgentMovementHardeningPhysicsPerformed = multiAgentMovementHardeningPhysicsPerformed
        self.multiAgentMovementHardeningTerrainMutationPerformed = multiAgentMovementHardeningTerrainMutationPerformed
        self.multiAgentMovementHardeningWorldMutationPerformed = multiAgentMovementHardeningWorldMutationPerformed
        self.multiAgentMovementHardeningSuccess = multiAgentMovementHardeningSuccess
        self.multiAgentMovementTickFixtureInputs = multiAgentMovementTickFixtureInputs
        self.multiAgentMovementTickFixtureAgents = multiAgentMovementTickFixtureAgents
        self.multiAgentMovementTickFixturePhysicalPositions = multiAgentMovementTickFixturePhysicalPositions
        self.multiAgentMovementTickFixtureIntents = multiAgentMovementTickFixtureIntents
        self.multiAgentMovementTickFixtureResolutions = multiAgentMovementTickFixtureResolutions
        self.multiAgentMovementTickFixtureFeedback = multiAgentMovementTickFixtureFeedback
        self.multiAgentMovementTickFixtureApproved = multiAgentMovementTickFixtureApproved
        self.multiAgentMovementTickFixtureDenied = multiAgentMovementTickFixtureDenied
        self.multiAgentMovementTickFixtureDisplacementsApplied = multiAgentMovementTickFixtureDisplacementsApplied
        self.multiAgentMovementTickFixtureSameDestinationConflicts = multiAgentMovementTickFixtureSameDestinationConflicts
        self.multiAgentMovementTickFixtureInvalidEdges = multiAgentMovementTickFixtureInvalidEdges
        self.multiAgentMovementTickFixtureWorldUsed = multiAgentMovementTickFixtureWorldUsed
        self.multiAgentMovementTickFixtureLiveCollisionRead = multiAgentMovementTickFixtureLiveCollisionRead
        self.multiAgentMovementTickFixturePhysicalMovementApplied = multiAgentMovementTickFixturePhysicalMovementApplied
        self.multiAgentMovementTickFixtureRouteFollowingApplied = multiAgentMovementTickFixtureRouteFollowingApplied
        self.multiAgentMovementTickFixturePathfindingPerformed = multiAgentMovementTickFixturePathfindingPerformed
        self.multiAgentMovementTickFixtureReplanningPerformed = multiAgentMovementTickFixtureReplanningPerformed
        self.multiAgentMovementTickFixtureAvoidancePerformed = multiAgentMovementTickFixtureAvoidancePerformed
        self.multiAgentMovementTickFixtureReservationRuntimeUsed = multiAgentMovementTickFixtureReservationRuntimeUsed
        self.multiAgentMovementTickFixturePhysicsPerformed = multiAgentMovementTickFixturePhysicsPerformed
        self.multiAgentMovementTickFixtureMutationPerformed = multiAgentMovementTickFixtureMutationPerformed
        self.multiAgentMovementTickFixtureSuccess = multiAgentMovementTickFixtureSuccess
        self.multiAgentMovementTickLiveReadonlyInputs = multiAgentMovementTickLiveReadonlyInputs
        self.multiAgentMovementTickLiveReadonlyAgents = multiAgentMovementTickLiveReadonlyAgents
        self.multiAgentMovementTickLiveReadonlyPhysicalPositions = multiAgentMovementTickLiveReadonlyPhysicalPositions
        self.multiAgentMovementTickLiveReadonlyIntents = multiAgentMovementTickLiveReadonlyIntents
        self.multiAgentMovementTickLiveReadonlyResolutions = multiAgentMovementTickLiveReadonlyResolutions
        self.multiAgentMovementTickLiveReadonlyFeedback = multiAgentMovementTickLiveReadonlyFeedback
        self.multiAgentMovementTickLiveReadonlyApproved = multiAgentMovementTickLiveReadonlyApproved
        self.multiAgentMovementTickLiveReadonlyDenied = multiAgentMovementTickLiveReadonlyDenied
        self.multiAgentMovementTickLiveReadonlyOccupableDestinations = multiAgentMovementTickLiveReadonlyOccupableDestinations
        self.multiAgentMovementTickLiveReadonlyNonOccupableDestinations = multiAgentMovementTickLiveReadonlyNonOccupableDestinations
        self.multiAgentMovementTickLiveReadonlyCollisionDenied = multiAgentMovementTickLiveReadonlyCollisionDenied
        self.multiAgentMovementTickLiveReadonlySourceMismatch = multiAgentMovementTickLiveReadonlySourceMismatch
        self.multiAgentMovementTickLiveReadonlyInvalidEdges = multiAgentMovementTickLiveReadonlyInvalidEdges
        self.multiAgentMovementTickLiveReadonlyStaleIntent = multiAgentMovementTickLiveReadonlyStaleIntent
        self.multiAgentMovementTickLiveReadonlyDisplacementsApplied = multiAgentMovementTickLiveReadonlyDisplacementsApplied
        self.multiAgentMovementTickLiveReadonlyWorldUsed = multiAgentMovementTickLiveReadonlyWorldUsed
        self.multiAgentMovementTickLiveReadonlyLiveCollisionRead = multiAgentMovementTickLiveReadonlyLiveCollisionRead
        self.multiAgentMovementTickLiveReadonlyPhysicalMovementApplied = multiAgentMovementTickLiveReadonlyPhysicalMovementApplied
        self.multiAgentMovementTickLiveReadonlyRouteFollowingApplied = multiAgentMovementTickLiveReadonlyRouteFollowingApplied
        self.multiAgentMovementTickLiveReadonlyPathfindingPerformed = multiAgentMovementTickLiveReadonlyPathfindingPerformed
        self.multiAgentMovementTickLiveReadonlyReplanningPerformed = multiAgentMovementTickLiveReadonlyReplanningPerformed
        self.multiAgentMovementTickLiveReadonlyAvoidancePerformed = multiAgentMovementTickLiveReadonlyAvoidancePerformed
        self.multiAgentMovementTickLiveReadonlyReservationRuntimeUsed = multiAgentMovementTickLiveReadonlyReservationRuntimeUsed
        self.multiAgentMovementTickLiveReadonlyPhysicsPerformed = multiAgentMovementTickLiveReadonlyPhysicsPerformed
        self.multiAgentMovementTickLiveReadonlyMutationPerformed = multiAgentMovementTickLiveReadonlyMutationPerformed
        self.multiAgentMovementTickLiveReadonlySuccess = multiAgentMovementTickLiveReadonlySuccess
        self.multiAgentMovementTickApprovedApplicationInputs = multiAgentMovementTickApprovedApplicationInputs
        self.multiAgentMovementTickApprovedApplicationAgents = multiAgentMovementTickApprovedApplicationAgents
        self.multiAgentMovementTickApprovedApplicationPhysicalPositions = multiAgentMovementTickApprovedApplicationPhysicalPositions
        self.multiAgentMovementTickApprovedApplicationIntents = multiAgentMovementTickApprovedApplicationIntents
        self.multiAgentMovementTickApprovedApplicationResolutions = multiAgentMovementTickApprovedApplicationResolutions
        self.multiAgentMovementTickApprovedApplicationFeedback = multiAgentMovementTickApprovedApplicationFeedback
        self.multiAgentMovementTickApprovedApplicationApproved = multiAgentMovementTickApprovedApplicationApproved
        self.multiAgentMovementTickApprovedApplicationDenied = multiAgentMovementTickApprovedApplicationDenied
        self.multiAgentMovementTickApprovedApplicationOccupableDestinations = multiAgentMovementTickApprovedApplicationOccupableDestinations
        self.multiAgentMovementTickApprovedApplicationNonOccupableDestinations = multiAgentMovementTickApprovedApplicationNonOccupableDestinations
        self.multiAgentMovementTickApprovedApplicationDisplacementsApplied = multiAgentMovementTickApprovedApplicationDisplacementsApplied
        self.multiAgentMovementTickApprovedApplicationDivergenceBeforeMax = multiAgentMovementTickApprovedApplicationDivergenceBeforeMax
        self.multiAgentMovementTickApprovedApplicationDivergenceAfterMax = multiAgentMovementTickApprovedApplicationDivergenceAfterMax
        self.multiAgentMovementTickApprovedApplicationWorldUsed = multiAgentMovementTickApprovedApplicationWorldUsed
        self.multiAgentMovementTickApprovedApplicationLiveCollisionRead = multiAgentMovementTickApprovedApplicationLiveCollisionRead
        self.multiAgentMovementTickApprovedApplicationPhysicalMovementApplied = multiAgentMovementTickApprovedApplicationPhysicalMovementApplied
        self.multiAgentMovementTickApprovedApplicationRouteFollowingApplied = multiAgentMovementTickApprovedApplicationRouteFollowingApplied
        self.multiAgentMovementTickApprovedApplicationPathfindingPerformed = multiAgentMovementTickApprovedApplicationPathfindingPerformed
        self.multiAgentMovementTickApprovedApplicationReplanningPerformed = multiAgentMovementTickApprovedApplicationReplanningPerformed
        self.multiAgentMovementTickApprovedApplicationAvoidancePerformed = multiAgentMovementTickApprovedApplicationAvoidancePerformed
        self.multiAgentMovementTickApprovedApplicationReservationRuntimeUsed = multiAgentMovementTickApprovedApplicationReservationRuntimeUsed
        self.multiAgentMovementTickApprovedApplicationPhysicsPerformed = multiAgentMovementTickApprovedApplicationPhysicsPerformed
        self.multiAgentMovementTickApprovedApplicationTerrainMutationPerformed = multiAgentMovementTickApprovedApplicationTerrainMutationPerformed
        self.multiAgentMovementTickApprovedApplicationWorldMutationPerformed = multiAgentMovementTickApprovedApplicationWorldMutationPerformed
        self.multiAgentMovementTickApprovedApplicationSuccess = multiAgentMovementTickApprovedApplicationSuccess
        self.multiAgentMovementTickHardeningCases = multiAgentMovementTickHardeningCases
        self.multiAgentMovementTickHardeningPassed = multiAgentMovementTickHardeningPassed
        self.multiAgentMovementTickHardeningFailed = multiAgentMovementTickHardeningFailed
        self.multiAgentMovementTickHardeningTicks = multiAgentMovementTickHardeningTicks
        self.multiAgentMovementTickHardeningAgents = multiAgentMovementTickHardeningAgents
        self.multiAgentMovementTickHardeningIntents = multiAgentMovementTickHardeningIntents
        self.multiAgentMovementTickHardeningResolutions = multiAgentMovementTickHardeningResolutions
        self.multiAgentMovementTickHardeningFeedback = multiAgentMovementTickHardeningFeedback
        self.multiAgentMovementTickHardeningApproved = multiAgentMovementTickHardeningApproved
        self.multiAgentMovementTickHardeningDenied = multiAgentMovementTickHardeningDenied
        self.multiAgentMovementTickHardeningDisplacementsApplied = multiAgentMovementTickHardeningDisplacementsApplied
        self.multiAgentMovementTickHardeningOccupableDestinations = multiAgentMovementTickHardeningOccupableDestinations
        self.multiAgentMovementTickHardeningNonOccupableDestinations = multiAgentMovementTickHardeningNonOccupableDestinations
        self.multiAgentMovementTickHardeningCollisionDenied = multiAgentMovementTickHardeningCollisionDenied
        self.multiAgentMovementTickHardeningSameDestinationConflicts = multiAgentMovementTickHardeningSameDestinationConflicts
        self.multiAgentMovementTickHardeningSwapConflicts = multiAgentMovementTickHardeningSwapConflicts
        self.multiAgentMovementTickHardeningSourceMismatch = multiAgentMovementTickHardeningSourceMismatch
        self.multiAgentMovementTickHardeningStaleIntent = multiAgentMovementTickHardeningStaleIntent
        self.multiAgentMovementTickHardeningInvalidEdges = multiAgentMovementTickHardeningInvalidEdges
        self.multiAgentMovementTickHardeningDivergenceDenied = multiAgentMovementTickHardeningDivergenceDenied
        self.multiAgentMovementTickHardeningStaleCollision = multiAgentMovementTickHardeningStaleCollision
        self.multiAgentMovementTickHardeningPartialApprovalCases = multiAgentMovementTickHardeningPartialApprovalCases
        self.multiAgentMovementTickHardeningAllDeniedCases = multiAgentMovementTickHardeningAllDeniedCases
        self.multiAgentMovementTickHardeningMaxAgentsExceeded = multiAgentMovementTickHardeningMaxAgentsExceeded
        self.multiAgentMovementTickHardeningMovedFeedback = multiAgentMovementTickHardeningMovedFeedback
        self.multiAgentMovementTickHardeningApprovedForMovementFeedback = multiAgentMovementTickHardeningApprovedForMovementFeedback
        self.multiAgentMovementTickHardeningBlockedByCollisionFeedback = multiAgentMovementTickHardeningBlockedByCollisionFeedback
        self.multiAgentMovementTickHardeningBlockedByAgentConflictFeedback = multiAgentMovementTickHardeningBlockedByAgentConflictFeedback
        self.multiAgentMovementTickHardeningBlockedBySourceMismatchFeedback = multiAgentMovementTickHardeningBlockedBySourceMismatchFeedback
        self.multiAgentMovementTickHardeningBlockedByDivergenceFeedback = multiAgentMovementTickHardeningBlockedByDivergenceFeedback
        self.multiAgentMovementTickHardeningBlockedByStaleIntentFeedback = multiAgentMovementTickHardeningBlockedByStaleIntentFeedback
        self.multiAgentMovementTickHardeningBlockedByInvalidEdgeFeedback = multiAgentMovementTickHardeningBlockedByInvalidEdgeFeedback
        self.multiAgentMovementTickHardeningBlockedByMaxAgentsFeedback = multiAgentMovementTickHardeningBlockedByMaxAgentsFeedback
        self.multiAgentMovementTickHardeningDivergenceBeforeMax = multiAgentMovementTickHardeningDivergenceBeforeMax
        self.multiAgentMovementTickHardeningDivergenceAfterMax = multiAgentMovementTickHardeningDivergenceAfterMax
        self.multiAgentMovementTickHardeningWorldUsed = multiAgentMovementTickHardeningWorldUsed
        self.multiAgentMovementTickHardeningLiveCollisionRead = multiAgentMovementTickHardeningLiveCollisionRead
        self.multiAgentMovementTickHardeningPhysicalMovementApplied = multiAgentMovementTickHardeningPhysicalMovementApplied
        self.multiAgentMovementTickHardeningRouteFollowingApplied = multiAgentMovementTickHardeningRouteFollowingApplied
        self.multiAgentMovementTickHardeningPathfindingPerformed = multiAgentMovementTickHardeningPathfindingPerformed
        self.multiAgentMovementTickHardeningReplanningPerformed = multiAgentMovementTickHardeningReplanningPerformed
        self.multiAgentMovementTickHardeningAvoidancePerformed = multiAgentMovementTickHardeningAvoidancePerformed
        self.multiAgentMovementTickHardeningReservationRuntimeUsed = multiAgentMovementTickHardeningReservationRuntimeUsed
        self.multiAgentMovementTickHardeningPhysicsPerformed = multiAgentMovementTickHardeningPhysicsPerformed
        self.multiAgentMovementTickHardeningTerrainMutationPerformed = multiAgentMovementTickHardeningTerrainMutationPerformed
        self.multiAgentMovementTickHardeningWorldMutationPerformed = multiAgentMovementTickHardeningWorldMutationPerformed
        self.multiAgentMovementTickHardeningSuccess = multiAgentMovementTickHardeningSuccess
        self.agentIntentProductionFixtureAgentsObserved = agentIntentProductionFixtureAgentsObserved
        self.agentIntentProductionFixtureContexts = agentIntentProductionFixtureContexts
        self.agentIntentProductionFixtureProposals = agentIntentProductionFixtureProposals
        self.agentIntentProductionFixtureAcceptedIntents = agentIntentProductionFixtureAcceptedIntents
        self.agentIntentProductionFixtureRejectedProposals = agentIntentProductionFixtureRejectedProposals
        self.agentIntentProductionFixtureNoIntent = agentIntentProductionFixtureNoIntent
        self.agentIntentProductionFixtureInvalidContext = agentIntentProductionFixtureInvalidContext
        self.agentIntentProductionFixtureDuplicateAgentContexts = agentIntentProductionFixtureDuplicateAgentContexts
        self.agentIntentProductionFixtureInvalidOneEdgeProposals = agentIntentProductionFixtureInvalidOneEdgeProposals
        self.agentIntentProductionFixtureAcceptedMoveEast = agentIntentProductionFixtureAcceptedMoveEast
        self.agentIntentProductionFixtureAcceptedMoveWest = agentIntentProductionFixtureAcceptedMoveWest
        self.agentIntentProductionFixtureAcceptedMoveNorth = agentIntentProductionFixtureAcceptedMoveNorth
        self.agentIntentProductionFixtureAcceptedMoveSouth = agentIntentProductionFixtureAcceptedMoveSouth
        self.agentIntentProductionFixtureWorldUsed = agentIntentProductionFixtureWorldUsed
        self.agentIntentProductionFixtureCollisionRead = agentIntentProductionFixtureCollisionRead
        self.agentIntentProductionFixtureMovementApplied = agentIntentProductionFixtureMovementApplied
        self.agentIntentProductionFixtureFeedbackConsumed = agentIntentProductionFixtureFeedbackConsumed
        self.agentIntentProductionFixtureMemoryUpdated = agentIntentProductionFixtureMemoryUpdated
        self.agentIntentProductionFixtureGoalChanged = agentIntentProductionFixtureGoalChanged
        self.agentIntentProductionFixturePathfindingPerformed = agentIntentProductionFixturePathfindingPerformed
        self.agentIntentProductionFixtureReplanningPerformed = agentIntentProductionFixtureReplanningPerformed
        self.agentIntentProductionFixtureAvoidancePerformed = agentIntentProductionFixtureAvoidancePerformed
        self.agentIntentProductionFixtureReservationRuntimeUsed = agentIntentProductionFixtureReservationRuntimeUsed
        self.agentIntentProductionFixtureMutationPerformed = agentIntentProductionFixtureMutationPerformed
        self.agentIntentProductionFixtureSuccess = agentIntentProductionFixtureSuccess
        self.agentIntentProductionHardeningCases = agentIntentProductionHardeningCases
        self.agentIntentProductionHardeningPassed = agentIntentProductionHardeningPassed
        self.agentIntentProductionHardeningFailed = agentIntentProductionHardeningFailed
        self.agentIntentProductionHardeningContexts = agentIntentProductionHardeningContexts
        self.agentIntentProductionHardeningProposals = agentIntentProductionHardeningProposals
        self.agentIntentProductionHardeningAcceptedIntents = agentIntentProductionHardeningAcceptedIntents
        self.agentIntentProductionHardeningRejectedProposals = agentIntentProductionHardeningRejectedProposals
        self.agentIntentProductionHardeningNoIntent = agentIntentProductionHardeningNoIntent
        self.agentIntentProductionHardeningInvalidContext = agentIntentProductionHardeningInvalidContext
        self.agentIntentProductionHardeningDuplicateAgentContexts = agentIntentProductionHardeningDuplicateAgentContexts
        self.agentIntentProductionHardeningDuplicateProposals = agentIntentProductionHardeningDuplicateProposals
        self.agentIntentProductionHardeningInvalidOneEdgeProposals = agentIntentProductionHardeningInvalidOneEdgeProposals
        self.agentIntentProductionHardeningStaleProposals = agentIntentProductionHardeningStaleProposals
        self.agentIntentProductionHardeningWrongSourceProposals = agentIntentProductionHardeningWrongSourceProposals
        self.agentIntentProductionHardeningMaxProposalsExceeded = agentIntentProductionHardeningMaxProposalsExceeded
        self.agentIntentProductionHardeningAcceptedMoveEast = agentIntentProductionHardeningAcceptedMoveEast
        self.agentIntentProductionHardeningAcceptedMoveWest = agentIntentProductionHardeningAcceptedMoveWest
        self.agentIntentProductionHardeningAcceptedMoveNorth = agentIntentProductionHardeningAcceptedMoveNorth
        self.agentIntentProductionHardeningAcceptedMoveSouth = agentIntentProductionHardeningAcceptedMoveSouth
        self.agentIntentProductionHardeningWorldUsed = agentIntentProductionHardeningWorldUsed
        self.agentIntentProductionHardeningCollisionRead = agentIntentProductionHardeningCollisionRead
        self.agentIntentProductionHardeningMovementApplied = agentIntentProductionHardeningMovementApplied
        self.agentIntentProductionHardeningFeedbackConsumed = agentIntentProductionHardeningFeedbackConsumed
        self.agentIntentProductionHardeningMemoryUpdated = agentIntentProductionHardeningMemoryUpdated
        self.agentIntentProductionHardeningGoalChanged = agentIntentProductionHardeningGoalChanged
        self.agentIntentProductionHardeningPathfindingPerformed = agentIntentProductionHardeningPathfindingPerformed
        self.agentIntentProductionHardeningReplanningPerformed = agentIntentProductionHardeningReplanningPerformed
        self.agentIntentProductionHardeningAvoidancePerformed = agentIntentProductionHardeningAvoidancePerformed
        self.agentIntentProductionHardeningReservationRuntimeUsed = agentIntentProductionHardeningReservationRuntimeUsed
        self.agentIntentProductionHardeningPhysicsPerformed = agentIntentProductionHardeningPhysicsPerformed
        self.agentIntentProductionHardeningMutationPerformed = agentIntentProductionHardeningMutationPerformed
        self.agentIntentProductionHardeningSuccess = agentIntentProductionHardeningSuccess
        self.agentIntentToTickFixtureContexts = agentIntentToTickFixtureContexts
        self.agentIntentToTickFixtureProposals = agentIntentToTickFixtureProposals
        self.agentIntentToTickFixtureAcceptedIntents = agentIntentToTickFixtureAcceptedIntents
        self.agentIntentToTickFixtureRejectedProposals = agentIntentToTickFixtureRejectedProposals
        self.agentIntentToTickFixtureNoIntent = agentIntentToTickFixtureNoIntent
        self.agentIntentToTickFixtureInvalidOneEdgeProposals = agentIntentToTickFixtureInvalidOneEdgeProposals
        self.agentIntentToTickFixtureTickAgents = agentIntentToTickFixtureTickAgents
        self.agentIntentToTickFixtureTickIntents = agentIntentToTickFixtureTickIntents
        self.agentIntentToTickFixtureTickResolutions = agentIntentToTickFixtureTickResolutions
        self.agentIntentToTickFixtureTickFeedback = agentIntentToTickFixtureTickFeedback
        self.agentIntentToTickFixtureTickApproved = agentIntentToTickFixtureTickApproved
        self.agentIntentToTickFixtureTickDenied = agentIntentToTickFixtureTickDenied
        self.agentIntentToTickFixtureSameDestinationConflicts = agentIntentToTickFixtureSameDestinationConflicts
        self.agentIntentToTickFixtureDisplacementsApplied = agentIntentToTickFixtureDisplacementsApplied
        self.agentIntentToTickFixtureProductionAcceptedSameDestination = agentIntentToTickFixtureProductionAcceptedSameDestination
        self.agentIntentToTickFixtureTickResolvedSameDestination = agentIntentToTickFixtureTickResolvedSameDestination
        self.agentIntentToTickFixtureWorldUsed = agentIntentToTickFixtureWorldUsed
        self.agentIntentToTickFixtureCollisionRead = agentIntentToTickFixtureCollisionRead
        self.agentIntentToTickFixtureMovementApplied = agentIntentToTickFixtureMovementApplied
        self.agentIntentToTickFixtureFeedbackConsumed = agentIntentToTickFixtureFeedbackConsumed
        self.agentIntentToTickFixtureMemoryUpdated = agentIntentToTickFixtureMemoryUpdated
        self.agentIntentToTickFixtureGoalChanged = agentIntentToTickFixtureGoalChanged
        self.agentIntentToTickFixturePathfindingPerformed = agentIntentToTickFixturePathfindingPerformed
        self.agentIntentToTickFixtureReplanningPerformed = agentIntentToTickFixtureReplanningPerformed
        self.agentIntentToTickFixtureAvoidancePerformed = agentIntentToTickFixtureAvoidancePerformed
        self.agentIntentToTickFixtureReservationRuntimeUsed = agentIntentToTickFixtureReservationRuntimeUsed
        self.agentIntentToTickFixturePhysicsPerformed = agentIntentToTickFixturePhysicsPerformed
        self.agentIntentToTickFixtureMutationPerformed = agentIntentToTickFixtureMutationPerformed
        self.agentIntentToTickFixtureSuccess = agentIntentToTickFixtureSuccess
        self.agentIntentToTickLiveReadonlyContexts = agentIntentToTickLiveReadonlyContexts
        self.agentIntentToTickLiveReadonlyProposals = agentIntentToTickLiveReadonlyProposals
        self.agentIntentToTickLiveReadonlyAcceptedIntents = agentIntentToTickLiveReadonlyAcceptedIntents
        self.agentIntentToTickLiveReadonlyRejectedProposals = agentIntentToTickLiveReadonlyRejectedProposals
        self.agentIntentToTickLiveReadonlyNoIntent = agentIntentToTickLiveReadonlyNoIntent
        self.agentIntentToTickLiveReadonlyInvalidOneEdgeProposals = agentIntentToTickLiveReadonlyInvalidOneEdgeProposals
        self.agentIntentToTickLiveReadonlyTickAgents = agentIntentToTickLiveReadonlyTickAgents
        self.agentIntentToTickLiveReadonlyTickIntents = agentIntentToTickLiveReadonlyTickIntents
        self.agentIntentToTickLiveReadonlyTickResolutions = agentIntentToTickLiveReadonlyTickResolutions
        self.agentIntentToTickLiveReadonlyTickFeedback = agentIntentToTickLiveReadonlyTickFeedback
        self.agentIntentToTickLiveReadonlyTickApproved = agentIntentToTickLiveReadonlyTickApproved
        self.agentIntentToTickLiveReadonlyTickDenied = agentIntentToTickLiveReadonlyTickDenied
        self.agentIntentToTickLiveReadonlyOccupableDestinations = agentIntentToTickLiveReadonlyOccupableDestinations
        self.agentIntentToTickLiveReadonlyNonOccupableDestinations = agentIntentToTickLiveReadonlyNonOccupableDestinations
        self.agentIntentToTickLiveReadonlyCollisionDenied = agentIntentToTickLiveReadonlyCollisionDenied
        self.agentIntentToTickLiveReadonlyDisplacementsApplied = agentIntentToTickLiveReadonlyDisplacementsApplied
        self.agentIntentToTickLiveReadonlyProductionReadCollision = agentIntentToTickLiveReadonlyProductionReadCollision
        self.agentIntentToTickLiveReadonlyTickReadCollision = agentIntentToTickLiveReadonlyTickReadCollision
        self.agentIntentToTickLiveReadonlyWorldUsed = agentIntentToTickLiveReadonlyWorldUsed
        self.agentIntentToTickLiveReadonlyCollisionRead = agentIntentToTickLiveReadonlyCollisionRead
        self.agentIntentToTickLiveReadonlyMovementApplied = agentIntentToTickLiveReadonlyMovementApplied
        self.agentIntentToTickLiveReadonlyFeedbackConsumed = agentIntentToTickLiveReadonlyFeedbackConsumed
        self.agentIntentToTickLiveReadonlyMemoryUpdated = agentIntentToTickLiveReadonlyMemoryUpdated
        self.agentIntentToTickLiveReadonlyGoalChanged = agentIntentToTickLiveReadonlyGoalChanged
        self.agentIntentToTickLiveReadonlyPathfindingPerformed = agentIntentToTickLiveReadonlyPathfindingPerformed
        self.agentIntentToTickLiveReadonlyReplanningPerformed = agentIntentToTickLiveReadonlyReplanningPerformed
        self.agentIntentToTickLiveReadonlyAvoidancePerformed = agentIntentToTickLiveReadonlyAvoidancePerformed
        self.agentIntentToTickLiveReadonlyReservationRuntimeUsed = agentIntentToTickLiveReadonlyReservationRuntimeUsed
        self.agentIntentToTickLiveReadonlyPhysicsPerformed = agentIntentToTickLiveReadonlyPhysicsPerformed
        self.agentIntentToTickLiveReadonlyMutationPerformed = agentIntentToTickLiveReadonlyMutationPerformed
        self.agentIntentToTickLiveReadonlySuccess = agentIntentToTickLiveReadonlySuccess
        self.routeFollowingFixtureCases = routeFollowingFixtureCases
        self.routeFollowingFixturePassed = routeFollowingFixturePassed
        self.routeFollowingFixtureFailed = routeFollowingFixtureFailed
        self.routeFollowingFixtureCompleted = routeFollowingFixtureCompleted
        self.routeFollowingFixtureStopped = routeFollowingFixtureStopped
        self.routeFollowingFixtureAttemptedEdges = routeFollowingFixtureAttemptedEdges
        self.routeFollowingFixtureCompletedEdges = routeFollowingFixtureCompletedEdges
        self.routeFollowingFixtureDisplacementsApplied = routeFollowingFixtureDisplacementsApplied
        self.routeFollowingFixtureDeniedEdges = routeFollowingFixtureDeniedEdges
        self.routeFollowingFixtureCollisionDenied = routeFollowingFixtureCollisionDenied
        self.routeFollowingFixtureInvalidEdges = routeFollowingFixtureInvalidEdges
        self.routeFollowingFixtureSourceMismatch = routeFollowingFixtureSourceMismatch
        self.routeFollowingFixtureDivergence = routeFollowingFixtureDivergence
        self.routeFollowingFixtureMaxSteps = routeFollowingFixtureMaxSteps
        self.routeFollowingFixtureSuccess = routeFollowingFixtureSuccess
        self.routeFollowingLiveAttempted = routeFollowingLiveAttempted
        self.routeFollowingLiveCompleted = routeFollowingLiveCompleted
        self.routeFollowingLiveStopped = routeFollowingLiveStopped
        self.routeFollowingLiveStatus = routeFollowingLiveStatus
        self.routeFollowingLiveReason = routeFollowingLiveReason
        self.routeFollowingLiveRouteLength = routeFollowingLiveRouteLength
        self.routeFollowingLiveAttemptedEdges = routeFollowingLiveAttemptedEdges
        self.routeFollowingLiveCompletedEdges = routeFollowingLiveCompletedEdges
        self.routeFollowingLiveStoppedAtIndex = routeFollowingLiveStoppedAtIndex
        self.routeFollowingLiveDisplacementsApplied = routeFollowingLiveDisplacementsApplied
        self.routeFollowingLiveDeniedEdges = routeFollowingLiveDeniedEdges
        self.routeFollowingLiveCollisionDenied = routeFollowingLiveCollisionDenied
        self.routeFollowingLiveInvalidEdges = routeFollowingLiveInvalidEdges
        self.routeFollowingLiveSourceMismatch = routeFollowingLiveSourceMismatch
        self.routeFollowingLiveDivergence = routeFollowingLiveDivergence
        self.routeFollowingLivePathfindingInsideFollower = routeFollowingLivePathfindingInsideFollower
        self.routeFollowingLiveReplanningPerformed = routeFollowingLiveReplanningPerformed
        self.routeFollowingLivePhysicsPerformed = routeFollowingLivePhysicsPerformed
        self.routeFollowingLiveMutationPerformed = routeFollowingLiveMutationPerformed
        self.routeFollowingLiveSuccess = routeFollowingLiveSuccess
        self.routeFollowingLiveHardeningCases = routeFollowingLiveHardeningCases
        self.routeFollowingLiveHardeningPassed = routeFollowingLiveHardeningPassed
        self.routeFollowingLiveHardeningFailed = routeFollowingLiveHardeningFailed
        self.routeFollowingLiveHardeningCompleted = routeFollowingLiveHardeningCompleted
        self.routeFollowingLiveHardeningStopped = routeFollowingLiveHardeningStopped
        self.routeFollowingLiveHardeningAttemptedEdges = routeFollowingLiveHardeningAttemptedEdges
        self.routeFollowingLiveHardeningCompletedEdges = routeFollowingLiveHardeningCompletedEdges
        self.routeFollowingLiveHardeningDisplacementsApplied = routeFollowingLiveHardeningDisplacementsApplied
        self.routeFollowingLiveHardeningDeniedEdges = routeFollowingLiveHardeningDeniedEdges
        self.routeFollowingLiveHardeningCollisionDenied = routeFollowingLiveHardeningCollisionDenied
        self.routeFollowingLiveHardeningInvalidEdges = routeFollowingLiveHardeningInvalidEdges
        self.routeFollowingLiveHardeningSourceMismatch = routeFollowingLiveHardeningSourceMismatch
        self.routeFollowingLiveHardeningDivergence = routeFollowingLiveHardeningDivergence
        self.routeFollowingLiveHardeningStaleCollision = routeFollowingLiveHardeningStaleCollision
        self.routeFollowingLiveHardeningMaxSteps = routeFollowingLiveHardeningMaxSteps
        self.routeFollowingLiveHardeningSuccess = routeFollowingLiveHardeningSuccess
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
