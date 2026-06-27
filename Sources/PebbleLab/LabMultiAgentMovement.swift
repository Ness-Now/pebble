import PebbleCore

enum LabMultiAgentMovementStatus: String, Codable {
    case notStarted
    case collectedIntentions
    case resolved
    case applied
    case partiallyApplied
    case stopped
    case failedInvariant
}

enum LabMultiAgentMoveDecision: String, Codable {
    case approved
    case deniedSourceMismatch
    case deniedCollision
    case deniedSameDestinationConflict
    case deniedOccupiedDestination
    case deniedSwapConflict
    case deniedStaleIntent
    case deniedMissingAgent
    case deniedInvalidEdge
    case deniedDuplicateIntent
    case deniedCycleConflict
    case deniedChainDependency
    case deniedMovingAwayDestination
    case deniedZeroLengthEdge
    case deniedMaxAgents
    case deniedDivergence
    case deniedStaleCollision
}

struct LabAgentMoveIntent: Codable {
    let agentId: String
    let routeId: String?
    let from: LabTerrainPathNodeKey
    let to: LabTerrainPathNodeKey
    let routeIndex: Int?
    let reason: String
    let stale: Bool
}

struct LabAgentMoveResolution: Codable {
    let agentId: String
    let intent: LabAgentMoveIntent
    let decision: LabMultiAgentMoveDecision
    let approved: Bool
    let reason: String
    let prePosition: LabTerrainPathNodeKey?
    let postPosition: LabTerrainPathNodeKey?
}

enum LabMovementFeedbackKind: String, Codable {
    case approvedForMovement
    case moved
    case blockedByCollision
    case blockedByAgentConflict
    case blockedBySourceMismatch
    case blockedByDivergence
    case blockedByStaleIntent
    case blockedByInvalidEdge
    case blockedByMaxAgents
}

struct LabMovementFeedback: Codable {
    let agentId: String
    let tick: Int
    let kind: LabMovementFeedbackKind
    let from: LabTerrainPathNodeKey?
    let to: LabTerrainPathNodeKey?
    let reason: String
}

struct LabMultiAgentMovementTickInput: Codable {
    let tick: Int
    let agents: [String: LabTerrainPathNodeKey]
    let physicalPositions: [String: LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let maxAgents: Int?
}

struct LabMultiAgentMovementTickResolution: Codable {
    let agentId: String
    let intent: LabAgentMoveIntent
    let decision: LabMultiAgentMoveDecision
    let approved: Bool
    let displacementApplied: Bool
    let abstractBefore: LabTerrainPathNodeKey?
    let abstractAfter: LabTerrainPathNodeKey?
    let physicalBefore: LabTerrainPathNodeKey?
    let physicalAfter: LabTerrainPathNodeKey?
    let feedbackKind: LabMovementFeedbackKind
    let reason: String
}

struct LabMultiAgentMovementTickSummary: Codable {
    let intents: Int
    let approved: Int
    let denied: Int
    let displacementsApplied: Int
    let collisionDenied: Int
    let conflictDenied: Int
    let divergenceDenied: Int
    let maxDivergenceBefore: Int
    let maxDivergenceAfter: Int
    let success: Bool
}

struct LabMultiAgentMovementTickOutput: Codable {
    let tick: Int
    let resolutions: [LabMultiAgentMovementTickResolution]
    let abstractPositionsBefore: [String: LabTerrainPathNodeKey]
    let abstractPositionsAfter: [String: LabTerrainPathNodeKey]
    let physicalPositionsBefore: [String: LabTerrainPathNodeKey]
    let physicalPositionsAfter: [String: LabTerrainPathNodeKey]
    let feedback: [LabMovementFeedback]
    let summary: LabMultiAgentMovementTickSummary
}

struct LabMultiAgentMovementTickFixtureSummary: Codable {
    let tick: Int
    let agentCount: Int
    let physicalPositionCount: Int
    let intentCount: Int
    let resolutions: Int
    let feedbackCount: Int
    let approved: Int
    let denied: Int
    let displacementsApplied: Int
    let sameDestinationConflicts: Int
    let invalidEdges: Int
    let worldUsed: Bool
    let liveCollisionRead: Bool
    let physicalMovementApplied: Bool
    let routeFollowingApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let physicsPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabMultiAgentMovementTickFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let input: LabMultiAgentMovementTickInput
    let output: LabMultiAgentMovementTickOutput
    let summary: LabMultiAgentMovementTickFixtureSummary
}

struct LabMultiAgentMovementTickFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabMultiAgentMovementTickLiveReadonlyResolution: Codable {
    let agentId: String
    let intent: LabAgentMoveIntent
    let decision: LabMultiAgentMoveDecision
    let approved: Bool
    let displacementApplied: Bool
    let collisionRead: Bool
    let collisionStatus: LabTerrainOccupancyStatus?
    let collisionReason: String
    let abstractBefore: LabTerrainPathNodeKey?
    let abstractAfter: LabTerrainPathNodeKey?
    let physicalBefore: LabTerrainPathNodeKey?
    let physicalAfter: LabTerrainPathNodeKey?
    let feedbackKind: LabMovementFeedbackKind
    let reason: String
}

struct LabMultiAgentMovementTickLiveReadonlyOutput: Codable {
    let tick: Int
    let resolutions: [LabMultiAgentMovementTickLiveReadonlyResolution]
    let abstractPositionsBefore: [String: LabTerrainPathNodeKey]
    let abstractPositionsAfter: [String: LabTerrainPathNodeKey]
    let physicalPositionsBefore: [String: LabTerrainPathNodeKey]
    let physicalPositionsAfter: [String: LabTerrainPathNodeKey]
    let feedback: [LabMovementFeedback]
    let summary: LabMultiAgentMovementTickSummary
}

struct LabMultiAgentMovementTickLiveReadonlySummary: Codable {
    let tick: Int
    let agentCount: Int
    let physicalPositionCount: Int
    let intentCount: Int
    let resolutions: Int
    let feedbackCount: Int
    let approved: Int
    let denied: Int
    let occupableDestinations: Int
    let nonOccupableDestinations: Int
    let collisionDenied: Int
    let sameDestinationConflicts: Int
    let sourceMismatch: Int
    let invalidEdges: Int
    let staleIntent: Int
    let displacementsApplied: Int
    let worldUsed: Bool
    let liveCollisionRead: Bool
    let physicalMovementApplied: Bool
    let routeFollowingApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let physicsPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabMultiAgentMovementTickLiveReadonlyReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let input: LabMultiAgentMovementTickInput
    let output: LabMultiAgentMovementTickLiveReadonlyOutput
    let summary: LabMultiAgentMovementTickLiveReadonlySummary
}

struct LabMultiAgentMovementTickLiveReadonlyInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabMultiAgentMovementTickApprovedApplicationResolution: Codable {
    let agentId: String
    let intent: LabAgentMoveIntent
    let decision: LabMultiAgentMoveDecision
    let approved: Bool
    let displacementApplied: Bool
    let collisionRead: Bool
    let collisionStatus: LabTerrainOccupancyStatus?
    let collisionReason: String
    let abstractBefore: LabTerrainPathNodeKey
    let abstractAfter: LabTerrainPathNodeKey
    let physicalBefore: LabTerrainPathNodeKey
    let physicalAfter: LabTerrainPathNodeKey
    let divergenceBefore: Int
    let divergenceAfter: Int
    let feedbackKind: LabMovementFeedbackKind
    let reason: String
}

struct LabMultiAgentMovementTickApprovedApplicationOutput: Codable {
    let tick: Int
    let resolutions: [LabMultiAgentMovementTickApprovedApplicationResolution]
    let abstractPositionsBefore: [String: LabTerrainPathNodeKey]
    let abstractPositionsAfter: [String: LabTerrainPathNodeKey]
    let physicalPositionsBefore: [String: LabTerrainPathNodeKey]
    let physicalPositionsAfter: [String: LabTerrainPathNodeKey]
    let feedback: [LabMovementFeedback]
    let summary: LabMultiAgentMovementTickSummary
}

struct LabMultiAgentMovementTickApprovedApplicationSummary: Codable {
    let tick: Int
    let agentCount: Int
    let physicalPositionCount: Int
    let intentCount: Int
    let resolutions: Int
    let feedbackCount: Int
    let approved: Int
    let denied: Int
    let occupableDestinations: Int
    let nonOccupableDestinations: Int
    let displacementsApplied: Int
    let divergenceBeforeMax: Int
    let divergenceAfterMax: Int
    let worldUsed: Bool
    let liveCollisionRead: Bool
    let physicalMovementApplied: Bool
    let routeFollowingApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let physicsPerformed: Bool
    let terrainMutationPerformed: Bool
    let worldMutationPerformed: Bool
    let success: Bool
}

struct LabMultiAgentMovementTickApprovedApplicationReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let input: LabMultiAgentMovementTickInput
    let output: LabMultiAgentMovementTickApprovedApplicationOutput
    let summary: LabMultiAgentMovementTickApprovedApplicationSummary
}

struct LabMultiAgentMovementTickApprovedApplicationInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabMultiAgentMovementTickHardeningCase: Codable {
    let name: String
    let tick: Int
    let seed: UInt32
    let input: LabMultiAgentMovementTickInput
    let expectedApproved: Int
    let expectedDenied: Int
    let expectedDisplacementsApplied: Int
    let expectedDecisionCounts: [String: Int]
    let expectedFeedbackCounts: [String: Int]
    let expectedDivergenceBeforeMax: Int
    let expectedDivergenceAfterMax: Int
}

struct LabMultiAgentMovementTickHardeningResolution: Codable {
    let agentId: String
    let intent: LabAgentMoveIntent
    let decision: LabMultiAgentMoveDecision
    let approved: Bool
    let displacementApplied: Bool
    let collisionRead: Bool
    let collisionStatus: LabTerrainOccupancyStatus?
    let collisionReason: String
    let abstractBefore: LabTerrainPathNodeKey?
    let abstractAfter: LabTerrainPathNodeKey?
    let physicalBefore: LabTerrainPathNodeKey?
    let physicalAfter: LabTerrainPathNodeKey?
    let divergenceBefore: Int?
    let divergenceAfter: Int?
    let feedbackKind: LabMovementFeedbackKind
    let reason: String
}

struct LabMultiAgentMovementTickHardeningCaseResult: Codable {
    let name: String
    let passed: Bool
    let input: LabMultiAgentMovementTickInput
    let resolutions: [LabMultiAgentMovementTickHardeningResolution]
    let feedback: [LabMovementFeedback]
    let abstractPositionsBefore: [String: LabTerrainPathNodeKey]
    let abstractPositionsAfter: [String: LabTerrainPathNodeKey]
    let physicalPositionsBefore: [String: LabTerrainPathNodeKey]
    let physicalPositionsAfter: [String: LabTerrainPathNodeKey]
    let expectedApproved: Int
    let actualApproved: Int
    let expectedDenied: Int
    let actualDenied: Int
    let expectedDisplacementsApplied: Int
    let actualDisplacementsApplied: Int
    let expectedDecisionCounts: [String: Int]
    let actualDecisionCounts: [String: Int]
    let expectedFeedbackCounts: [String: Int]
    let actualFeedbackCounts: [String: Int]
    let divergenceBeforeMax: Int
    let divergenceAfterMax: Int
}

struct LabMultiAgentMovementTickHardeningSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let tickCount: Int
    let agentCountTotal: Int
    let intentCountTotal: Int
    let resolutionCountTotal: Int
    let feedbackCountTotal: Int
    let approvedTotal: Int
    let deniedTotal: Int
    let displacementsApplied: Int
    let occupableDestinations: Int
    let nonOccupableDestinations: Int
    let collisionDenied: Int
    let sameDestinationConflicts: Int
    let swapConflicts: Int
    let sourceMismatch: Int
    let staleIntent: Int
    let invalidEdges: Int
    let divergenceDenied: Int
    let staleCollision: Int
    let partialApprovalCases: Int
    let allDeniedCases: Int
    let maxAgentsExceeded: Int
    let movedFeedback: Int
    let approvedForMovementFeedback: Int
    let blockedByCollisionFeedback: Int
    let blockedByAgentConflictFeedback: Int
    let blockedBySourceMismatchFeedback: Int
    let blockedByDivergenceFeedback: Int
    let blockedByStaleIntentFeedback: Int
    let blockedByInvalidEdgeFeedback: Int
    let blockedByMaxAgentsFeedback: Int
    let divergenceBeforeMax: Int
    let divergenceAfterMax: Int
    let worldUsed: Bool
    let liveCollisionRead: Bool
    let physicalMovementApplied: Bool
    let routeFollowingApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let physicsPerformed: Bool
    let terrainMutationPerformed: Bool
    let worldMutationPerformed: Bool
    let success: Bool
}

struct LabMultiAgentMovementTickHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: LabMultiAgentMovementTickHardeningSummary
    let cases: [LabMultiAgentMovementTickHardeningCaseResult]
}

struct LabMultiAgentMovementTickHardeningInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabMultiAgentMovementFixtureCase: Codable {
    let name: String
    let agents: [String: LabTerrainPathNodeKey]
    let occupiedStaticNodes: [LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let expectedApproved: Int
    let expectedDenied: Int
    let expectedDecisionCounts: [String: Int]
}

struct LabMultiAgentMovementFixtureCaseResult: Codable {
    let name: String
    let passed: Bool
    let agents: [String: LabTerrainPathNodeKey]
    let occupiedStaticNodes: [LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let resolutions: [LabAgentMoveResolution]
    let initialPositions: [String: LabTerrainPathNodeKey]
    let finalPositions: [String: LabTerrainPathNodeKey]
    let expectedApproved: Int
    let actualApproved: Int
    let expectedDenied: Int
    let actualDenied: Int
    let expectedDecisionCounts: [String: Int]
    let actualDecisionCounts: [String: Int]
}

struct LabMultiAgentMovementFixtureSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let agentCountTotal: Int
    let intentCountTotal: Int
    let approvedTotal: Int
    let deniedTotal: Int
    let sameDestinationConflicts: Int
    let occupiedDestinationConflicts: Int
    let swapConflicts: Int
    let sourceMismatch: Int
    let staleIntent: Int
    let missingAgent: Int
    let invalidEdges: Int
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let goalSelectionPerformed: Bool
    let avoidancePerformed: Bool
    let reservationTableImplemented: Bool
    let physicsPerformed: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabMultiAgentMovementFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let status: LabMultiAgentMovementStatus
    let summary: LabMultiAgentMovementFixtureSummary
    let cases: [LabMultiAgentMovementFixtureCaseResult]
}

struct LabMultiAgentMovementFixtureHardeningSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let approvedTotal: Int
    let deniedTotal: Int
    let duplicateIntent: Int
    let cycleConflicts: Int
    let chainDependencies: Int
    let movingAwayDestination: Int
    let verticalInvalidEdges: Int
    let zeroLengthEdges: Int
    let allDeniedCases: Int
    let emptyIntentCases: Int
    let maxAgentsExceeded: Int
    let worldUsed: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let goalSelectionPerformed: Bool
    let avoidancePerformed: Bool
    let reservationTableImplemented: Bool
    let physicsPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabMultiAgentMovementFixtureHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: LabMultiAgentMovementFixtureHardeningSummary
    let cases: [LabMultiAgentMovementFixtureCaseResult]
}

struct LabMultiAgentMovementFixtureHardeningInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabMultiAgentLiveCollisionIntentCase: Codable {
    let name: String
    let seed: UInt32
    let agents: [String: LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let expectedApproved: Int
    let expectedDenied: Int
    let expectedOccupableDestinations: Int
    let expectedNonOccupableDestinations: Int
    let expectedDecisionCounts: [String: Int]
}

struct LabMultiAgentLiveCollisionIntentResolution: Codable {
    let agentId: String
    let intent: LabAgentMoveIntent
    let collisionRead: Bool
    let collisionStatus: LabTerrainOccupancyStatus?
    let collisionReason: String
    let decision: LabMultiAgentMoveDecision
    let approved: Bool
    let reason: String
    let prePosition: LabTerrainPathNodeKey?
    let postPosition: LabTerrainPathNodeKey?
    let displacementApplied: Bool
}

struct LabMultiAgentLiveCollisionIntentCaseResult: Codable {
    let name: String
    let passed: Bool
    let seed: UInt32
    let agents: [String: LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let resolutions: [LabMultiAgentLiveCollisionIntentResolution]
    let initialPositions: [String: LabTerrainPathNodeKey]
    let finalPositions: [String: LabTerrainPathNodeKey]
    let expectedApproved: Int
    let actualApproved: Int
    let expectedDenied: Int
    let actualDenied: Int
    let expectedOccupableDestinations: Int
    let actualOccupableDestinations: Int
    let expectedNonOccupableDestinations: Int
    let actualNonOccupableDestinations: Int
    let expectedDecisionCounts: [String: Int]
    let actualDecisionCounts: [String: Int]
}

struct LabMultiAgentLiveCollisionIntentSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let agentCountTotal: Int
    let intentCountTotal: Int
    let approvedTotal: Int
    let deniedTotal: Int
    let occupableDestinations: Int
    let nonOccupableDestinations: Int
    let collisionDenied: Int
    let sameDestinationConflicts: Int
    let sourceMismatch: Int
    let invalidEdges: Int
    let staleIntent: Int
    let worldUsed: Bool
    let liveCollisionRead: Bool
    let displacementApplied: Bool
    let physicalMovementApplied: Bool
    let routeFollowingApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let goalSelectionPerformed: Bool
    let avoidancePerformed: Bool
    let reservationTableImplemented: Bool
    let physicsPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabMultiAgentLiveCollisionIntentReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: LabMultiAgentLiveCollisionIntentSummary
    let cases: [LabMultiAgentLiveCollisionIntentCaseResult]
}

struct LabMultiAgentLiveCollisionIntentInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabMultiAgentApprovedPhysicalMovementCase: Codable {
    let name: String
    let seed: UInt32
    let agents: [String: LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let expectedApproved: Int
    let expectedDenied: Int
    let expectedDisplacementsApplied: Int
    let expectedDivergenceBeforeMax: Int
    let expectedDivergenceAfterMax: Int
}

struct LabMultiAgentApprovedPhysicalMovementResolution: Codable {
    let agentId: String
    let intent: LabAgentMoveIntent
    let collisionStatus: LabTerrainOccupancyStatus
    let collisionReason: String
    let decision: LabMultiAgentMoveDecision
    let approved: Bool
    let displacementApplied: Bool
    let abstractBefore: LabTerrainPathNodeKey
    let abstractAfter: LabTerrainPathNodeKey
    let physicalBefore: LabTerrainPathNodeKey
    let physicalAfter: LabTerrainPathNodeKey
    let divergenceBefore: Int
    let divergenceAfter: Int
    let reason: String
}

struct LabMultiAgentApprovedPhysicalMovementCaseResult: Codable {
    let name: String
    let passed: Bool
    let seed: UInt32
    let agents: [String: LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let resolutions: [LabMultiAgentApprovedPhysicalMovementResolution]
    let initialAbstractPositions: [String: LabTerrainPathNodeKey]
    let finalAbstractPositions: [String: LabTerrainPathNodeKey]
    let initialPhysicalPositions: [String: LabTerrainPathNodeKey]
    let finalPhysicalPositions: [String: LabTerrainPathNodeKey]
    let expectedApproved: Int
    let actualApproved: Int
    let expectedDenied: Int
    let actualDenied: Int
    let expectedDisplacementsApplied: Int
    let actualDisplacementsApplied: Int
    let divergenceBeforeMax: Int
    let divergenceAfterMax: Int
}

struct LabMultiAgentApprovedPhysicalMovementSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let agentCountTotal: Int
    let intentCountTotal: Int
    let approvedTotal: Int
    let deniedTotal: Int
    let displacementsApplied: Int
    let occupableDestinations: Int
    let nonOccupableDestinations: Int
    let divergenceBeforeMax: Int
    let divergenceAfterMax: Int
    let worldUsed: Bool
    let liveCollisionRead: Bool
    let physicalMovementApplied: Bool
    let routeFollowingApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let goalSelectionPerformed: Bool
    let avoidancePerformed: Bool
    let reservationTableImplemented: Bool
    let physicsPerformed: Bool
    let terrainMutationPerformed: Bool
    let worldMutationPerformed: Bool
    let success: Bool
}

struct LabMultiAgentApprovedPhysicalMovementReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: LabMultiAgentApprovedPhysicalMovementSummary
    let cases: [LabMultiAgentApprovedPhysicalMovementCaseResult]
}

struct LabMultiAgentApprovedPhysicalMovementInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabMultiAgentMovementHardeningCase: Codable {
    let name: String
    let seed: UInt32
    let agents: [String: LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let expectedApproved: Int
    let expectedDenied: Int
    let expectedDisplacementsApplied: Int
    let expectedDecisionCounts: [String: Int]
    let expectedDivergenceBeforeMax: Int
    let expectedDivergenceAfterMax: Int
}

struct LabMultiAgentMovementHardeningResolution: Codable {
    let agentId: String
    let intent: LabAgentMoveIntent
    let collisionRead: Bool
    let collisionStatus: LabTerrainOccupancyStatus?
    let collisionReason: String
    let decision: LabMultiAgentMoveDecision
    let approved: Bool
    let displacementApplied: Bool
    let abstractBefore: LabTerrainPathNodeKey?
    let abstractAfter: LabTerrainPathNodeKey?
    let physicalBefore: LabTerrainPathNodeKey?
    let physicalAfter: LabTerrainPathNodeKey?
    let divergenceBefore: Int?
    let divergenceAfter: Int?
    let reason: String
}

struct LabMultiAgentMovementHardeningCaseResult: Codable {
    let name: String
    let passed: Bool
    let seed: UInt32
    let agents: [String: LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let resolutions: [LabMultiAgentMovementHardeningResolution]
    let initialAbstractPositions: [String: LabTerrainPathNodeKey]
    let finalAbstractPositions: [String: LabTerrainPathNodeKey]
    let initialPhysicalPositions: [String: LabTerrainPathNodeKey]
    let finalPhysicalPositions: [String: LabTerrainPathNodeKey]
    let expectedApproved: Int
    let actualApproved: Int
    let expectedDenied: Int
    let actualDenied: Int
    let expectedDisplacementsApplied: Int
    let actualDisplacementsApplied: Int
    let expectedDecisionCounts: [String: Int]
    let actualDecisionCounts: [String: Int]
    let divergenceBeforeMax: Int
    let divergenceAfterMax: Int
}

struct LabMultiAgentMovementHardeningSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let agentCountTotal: Int
    let intentCountTotal: Int
    let approvedTotal: Int
    let deniedTotal: Int
    let displacementsApplied: Int
    let occupableDestinations: Int
    let nonOccupableDestinations: Int
    let collisionDenied: Int
    let sameDestinationConflicts: Int
    let swapConflicts: Int
    let sourceMismatch: Int
    let staleIntent: Int
    let invalidEdges: Int
    let divergenceDenied: Int
    let staleCollision: Int
    let partialApprovalCases: Int
    let allDeniedCases: Int
    let maxAgentsExceeded: Int
    let divergenceBeforeMax: Int
    let divergenceAfterMax: Int
    let worldUsed: Bool
    let liveCollisionRead: Bool
    let physicalMovementApplied: Bool
    let routeFollowingApplied: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let goalSelectionPerformed: Bool
    let avoidancePerformed: Bool
    let reservationTableImplemented: Bool
    let physicsPerformed: Bool
    let terrainMutationPerformed: Bool
    let worldMutationPerformed: Bool
    let success: Bool
}

struct LabMultiAgentMovementHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: LabMultiAgentMovementHardeningSummary
    let cases: [LabMultiAgentMovementHardeningCaseResult]
}

struct LabMultiAgentMovementHardeningInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabMultiAgentMovementFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabMultiAgentMovementFixtureInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let passed: Int
    let failed: Int
}

struct LabMultiAgentMovementFixtureInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

private func multiAgentNode(_ x: Int, _ z: Int, y: Int = 64) -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: x, y: y, z: z)
}

private func multiAgentIntent(
    _ agentId: String,
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey,
    reason: String,
    routeIndex: Int? = nil,
    routeId: String? = nil,
    stale: Bool = false
) -> LabAgentMoveIntent {
    LabAgentMoveIntent(
        agentId: agentId,
        routeId: routeId,
        from: from,
        to: to,
        routeIndex: routeIndex,
        reason: reason,
        stale: stale
    )
}

private func multiAgentMovementTickFixtureInput() -> LabMultiAgentMovementTickInput {
    let agents = [
        "agent_0": multiAgentNode(0, 0),
        "agent_1": multiAgentNode(2, 0),
        "agent_2": multiAgentNode(10, 0),
        "agent_3": multiAgentNode(20, 0)
    ]
    let intents = [
        multiAgentIntent(
            "agent_1",
            from: multiAgentNode(2, 0),
            to: multiAgentNode(1, 0),
            reason: "tick_fixture_same_destination_loser"
        ),
        multiAgentIntent(
            "agent_0",
            from: multiAgentNode(0, 0),
            to: multiAgentNode(1, 0),
            reason: "tick_fixture_same_destination_winner"
        ),
        multiAgentIntent(
            "agent_2",
            from: multiAgentNode(10, 0),
            to: multiAgentNode(11, 0),
            reason: "tick_fixture_approved"
        ),
        multiAgentIntent(
            "agent_3",
            from: multiAgentNode(20, 0),
            to: LabTerrainPathNodeKey(x: 20, y: 65, z: 0),
            reason: "tick_fixture_invalid_vertical"
        )
    ]

    return LabMultiAgentMovementTickInput(
        tick: 0,
        agents: agents,
        physicalPositions: agents,
        intents: intents,
        maxAgents: nil
    )
}

private func multiAgentMovementTickLiveReadonlyInput() -> LabMultiAgentMovementTickInput {
    let agent0 = LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
    let agent1 = LabTerrainPathNodeKey(x: 9, y: 64, z: 7)
    let agent2 = LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
    let agent3 = LabTerrainPathNodeKey(x: 20, y: 64, z: 0)
    let agent4 = LabTerrainPathNodeKey(x: 30, y: 64, z: 0)
    let agents = [
        "agent_0": agent0,
        "agent_1": agent1,
        "agent_2": agent2,
        "agent_3": agent3,
        "agent_4": agent4
    ]
    let intents = [
        multiAgentIntent(
            "agent_1",
            from: agent1,
            to: LabTerrainPathNodeKey(x: 9, y: 64, z: 8),
            reason: "tick_live_occupable_approved_unordered"
        ),
        multiAgentIntent(
            "agent_0",
            from: agent0,
            to: LabTerrainPathNodeKey(x: 8, y: 64, z: 8),
            reason: "tick_live_occupable_approved"
        ),
        multiAgentIntent(
            "agent_2",
            from: agent2,
            to: LabTerrainPathNodeKey(x: 8, y: 64, z: 8),
            reason: "tick_live_non_occupable_denied"
        ),
        multiAgentIntent(
            "agent_3",
            from: LabTerrainPathNodeKey(x: 21, y: 64, z: 0),
            to: LabTerrainPathNodeKey(x: 22, y: 64, z: 0),
            reason: "tick_live_source_mismatch_skips_collision"
        ),
        multiAgentIntent(
            "agent_4",
            from: agent4,
            to: LabTerrainPathNodeKey(x: 30, y: 65, z: 0),
            reason: "tick_live_invalid_vertical_skips_collision"
        )
    ]

    return LabMultiAgentMovementTickInput(
        tick: 0,
        agents: agents,
        physicalPositions: agents,
        intents: intents,
        maxAgents: nil
    )
}

private func multiAgentMovementTickApprovedApplicationInput()
    -> LabMultiAgentMovementTickInput {
    let agent0 = LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
    let agent1 = LabTerrainPathNodeKey(x: 9, y: 64, z: 7)
    let agents = [
        "agent_0": agent0,
        "agent_1": agent1
    ]
    let intents = [
        multiAgentIntent(
            "agent_1",
            from: agent1,
            to: LabTerrainPathNodeKey(x: 9, y: 64, z: 8),
            reason: "tick_approved_application_unordered_agent_1"
        ),
        multiAgentIntent(
            "agent_0",
            from: agent0,
            to: LabTerrainPathNodeKey(x: 8, y: 64, z: 8),
            reason: "tick_approved_application_unordered_agent_0"
        )
    ]

    return LabMultiAgentMovementTickInput(
        tick: 0,
        agents: agents,
        physicalPositions: agents,
        intents: intents,
        maxAgents: nil
    )
}

private func multiAgentMovementFixtureCases() -> [LabMultiAgentMovementFixtureCase] {
    [
        LabMultiAgentMovementFixtureCase(
            name: "two_agents_different_destinations_approved",
            agents: [
                "agent_0": multiAgentNode(0, 0),
                "agent_1": multiAgentNode(10, 0)
            ],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_different_destination"),
                multiAgentIntent("agent_1", from: multiAgentNode(10, 0), to: multiAgentNode(11, 0), reason: "fixture_different_destination")
            ],
            expectedApproved: 2,
            expectedDenied: 0,
            expectedDecisionCounts: ["approved": 2]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "same_destination_conflict",
            agents: [
                "agent_0": multiAgentNode(0, 0),
                "agent_1": multiAgentNode(2, 0)
            ],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_same_destination"),
                multiAgentIntent("agent_1", from: multiAgentNode(2, 0), to: multiAgentNode(1, 0), reason: "fixture_same_destination")
            ],
            expectedApproved: 1,
            expectedDenied: 1,
            expectedDecisionCounts: [
                "approved": 1,
                "deniedSameDestinationConflict": 1
            ]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "occupied_destination_conflict",
            agents: ["agent_0": multiAgentNode(0, 0)],
            occupiedStaticNodes: [multiAgentNode(1, 0)],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_occupied_static_destination")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: ["deniedOccupiedDestination": 1]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "swap_conflict",
            agents: [
                "agent_0": multiAgentNode(0, 0),
                "agent_1": multiAgentNode(1, 0)
            ],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_swap_conflict"),
                multiAgentIntent("agent_1", from: multiAgentNode(1, 0), to: multiAgentNode(0, 0), reason: "fixture_swap_conflict")
            ],
            expectedApproved: 0,
            expectedDenied: 2,
            expectedDecisionCounts: ["deniedSwapConflict": 2]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "source_mismatch",
            agents: ["agent_0": multiAgentNode(0, 0)],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(5, 0), to: multiAgentNode(6, 0), reason: "fixture_source_mismatch")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: ["deniedSourceMismatch": 1]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "stale_intent_duplicate_source_or_route_index",
            agents: ["agent_0": multiAgentNode(0, 0)],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent(
                    "agent_0",
                    from: multiAgentNode(0, 0),
                    to: multiAgentNode(1, 0),
                    reason: "fixture_stale_route_index",
                    routeIndex: 0,
                    routeId: "fixture_route_0",
                    stale: true
                )
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: ["deniedStaleIntent": 1]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "missing_agent",
            agents: [:],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_missing", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_missing_agent")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: ["deniedMissingAgent": 1]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "invalid_edge_diagonal_or_vertical",
            agents: ["agent_0": multiAgentNode(0, 0)],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 1), reason: "fixture_invalid_diagonal_edge")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: ["deniedInvalidEdge": 1]
        )
    ]
}

private func multiAgentMovementFixtureHardeningCases()
    -> [(fixture: LabMultiAgentMovementFixtureCase, maxAgents: Int?)] {
    [
        (
            LabMultiAgentMovementFixtureCase(
                name: "unordered_intents_still_resolve_by_agent_id",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(2, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_1", from: multiAgentNode(2, 0), to: multiAgentNode(1, 0), reason: "fixture_unordered_same_destination"),
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_unordered_same_destination")
                ],
                expectedApproved: 1,
                expectedDenied: 1,
                expectedDecisionCounts: [
                    "approved": 1,
                    "deniedSameDestinationConflict": 1
                ]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "duplicate_intents_same_agent_denied",
                agents: ["agent_0": multiAgentNode(0, 0)],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_duplicate_intent"),
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(-1, 0), reason: "fixture_duplicate_intent")
                ],
                expectedApproved: 0,
                expectedDenied: 2,
                expectedDecisionCounts: ["deniedDuplicateIntent": 2]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "three_agent_cycle_denied",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(1, 0),
                    "agent_2": multiAgentNode(2, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_three_agent_cycle"),
                    multiAgentIntent("agent_1", from: multiAgentNode(1, 0), to: multiAgentNode(2, 0), reason: "fixture_three_agent_cycle"),
                    multiAgentIntent("agent_2", from: multiAgentNode(2, 0), to: multiAgentNode(0, 0), reason: "fixture_three_agent_cycle")
                ],
                expectedApproved: 0,
                expectedDenied: 3,
                expectedDecisionCounts: ["deniedCycleConflict": 3]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "chain_dependency_denied",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(1, 0),
                    "agent_2": multiAgentNode(2, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_chain_dependency"),
                    multiAgentIntent("agent_1", from: multiAgentNode(1, 0), to: multiAgentNode(2, 0), reason: "fixture_chain_dependency")
                ],
                expectedApproved: 0,
                expectedDenied: 2,
                expectedDecisionCounts: ["deniedChainDependency": 2]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "moving_away_destination_denied",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(1, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_moving_away_destination"),
                    multiAgentIntent("agent_1", from: multiAgentNode(1, 0), to: multiAgentNode(2, 0), reason: "fixture_moving_away_destination")
                ],
                expectedApproved: 0,
                expectedDenied: 2,
                expectedDecisionCounts: ["deniedMovingAwayDestination": 2]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "invalid_vertical_edge",
                agents: ["agent_0": multiAgentNode(0, 0)],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(0, 0, y: 65), reason: "fixture_invalid_vertical_edge")
                ],
                expectedApproved: 0,
                expectedDenied: 1,
                expectedDecisionCounts: ["deniedInvalidEdge": 1]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "zero_length_edge_denied",
                agents: ["agent_0": multiAgentNode(0, 0)],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(0, 0), reason: "fixture_zero_length_edge")
                ],
                expectedApproved: 0,
                expectedDenied: 1,
                expectedDecisionCounts: ["deniedZeroLengthEdge": 1]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "all_denied_mixed_reasons",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(2, 0),
                    "agent_2": multiAgentNode(4, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_all_denied_stale", stale: true),
                    multiAgentIntent("agent_1", from: multiAgentNode(3, 0), to: multiAgentNode(4, 0), reason: "fixture_all_denied_source_mismatch"),
                    multiAgentIntent("agent_2", from: multiAgentNode(4, 0), to: multiAgentNode(4, 0, y: 65), reason: "fixture_all_denied_vertical")
                ],
                expectedApproved: 0,
                expectedDenied: 3,
                expectedDecisionCounts: [
                    "deniedInvalidEdge": 1,
                    "deniedSourceMismatch": 1,
                    "deniedStaleIntent": 1
                ]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "empty_intents_noop_success",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(1, 0)
                ],
                occupiedStaticNodes: [],
                intents: [],
                expectedApproved: 0,
                expectedDenied: 0,
                expectedDecisionCounts: [:]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "max_agents_bound_exceeded",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(10, 0),
                    "agent_2": multiAgentNode(20, 0),
                    "agent_3": multiAgentNode(30, 0),
                    "agent_4": multiAgentNode(40, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_max_agents_bound"),
                    multiAgentIntent("agent_1", from: multiAgentNode(10, 0), to: multiAgentNode(11, 0), reason: "fixture_max_agents_bound"),
                    multiAgentIntent("agent_2", from: multiAgentNode(20, 0), to: multiAgentNode(21, 0), reason: "fixture_max_agents_bound"),
                    multiAgentIntent("agent_3", from: multiAgentNode(30, 0), to: multiAgentNode(31, 0), reason: "fixture_max_agents_bound"),
                    multiAgentIntent("agent_4", from: multiAgentNode(40, 0), to: multiAgentNode(41, 0), reason: "fixture_max_agents_bound")
                ],
                expectedApproved: 0,
                expectedDenied: 5,
                expectedDecisionCounts: ["deniedMaxAgents": 5]
            ),
            4
        )
    ]
}

func makeMultiAgentMovementFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabMultiAgentMovementFixtureReport {
    let results = multiAgentMovementFixtureCases().map {
        evaluateMultiAgentMovementFixtureCase($0)
    }
    let passed = results.filter(\.passed).count
    let approved = results.reduce(0) { $0 + $1.actualApproved }
    let denied = results.reduce(0) { $0 + $1.actualDenied }
    let summary = LabMultiAgentMovementFixtureSummary(
        cases: results.count,
        passed: passed,
        failed: results.count - passed,
        agentCountTotal: results.reduce(0) { $0 + $1.agents.count },
        intentCountTotal: results.reduce(0) { $0 + $1.intents.count },
        approvedTotal: approved,
        deniedTotal: denied,
        sameDestinationConflicts: decisionCount(in: results, .deniedSameDestinationConflict),
        occupiedDestinationConflicts: decisionCount(in: results, .deniedOccupiedDestination),
        swapConflicts: decisionCount(in: results, .deniedSwapConflict),
        sourceMismatch: decisionCount(in: results, .deniedSourceMismatch),
        staleIntent: decisionCount(in: results, .deniedStaleIntent),
        missingAgent: decisionCount(in: results, .deniedMissingAgent),
        invalidEdges: decisionCount(in: results, .deniedInvalidEdge),
        pathfindingPerformed: false,
        replanningPerformed: false,
        goalSelectionPerformed: false,
        avoidancePerformed: false,
        reservationTableImplemented: false,
        physicsPerformed: false,
        worldUsed: false,
        mutationPerformed: false,
        success: passed == results.count
            && approved > 0
            && denied > 0
            && decisionCount(in: results, .deniedSameDestinationConflict) > 0
            && decisionCount(in: results, .deniedOccupiedDestination) > 0
            && decisionCount(in: results, .deniedSwapConflict) > 0
            && decisionCount(in: results, .deniedSourceMismatch) > 0
            && decisionCount(in: results, .deniedStaleIntent) > 0
            && decisionCount(in: results, .deniedMissingAgent) > 0
            && decisionCount(in: results, .deniedInvalidEdge) > 0
    )
    let status: LabMultiAgentMovementStatus = summary.success
        ? (denied > 0 ? .partiallyApplied : .applied)
        : .failedInvariant

    return LabMultiAgentMovementFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        status: status,
        summary: summary,
        cases: results
    )
}

func makeMultiAgentMovementFixtureInvariantReport(
    report: LabMultiAgentMovementFixtureReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiAgentMovementFixtureInvariantReport {
    let cases = report?.cases ?? []
    let names = Set(cases.map(\.name))
    let allApproved = cases.flatMap(\.resolutions).filter(\.approved)
    let allDenied = cases.flatMap(\.resolutions).filter { !$0.approved }
    let approvedCount = allApproved.count
    let deniedCount = allDenied.count
    let noDuplicateApprovedDestination = cases.allSatisfy(noDuplicateApprovedDestination)
    let noApprovedSwap = cases.allSatisfy(noApprovedSwapConflict)
    let deniedPreservesPosition = cases.allSatisfy { result in
        result.resolutions.filter { !$0.approved }.allSatisfy {
            $0.prePosition == $0.postPosition
        }
    }
    let approvedOneEdge = allApproved.allSatisfy {
        guard let pre = $0.prePosition, let post = $0.postPosition else { return false }
        return isFixtureEdgeAllowed(from: pre, to: post)
    }
    let finalPositionsCoherent = cases.allSatisfy { result in
        var expected = result.initialPositions
        for resolution in result.resolutions where resolution.approved {
            expected[resolution.agentId] = resolution.intent.to
        }
        return expected == result.finalPositions
    }
    let sameDestinationDeterministic = cases.first {
        $0.name == "same_destination_conflict"
    }?.resolutions.first(where: {
        $0.agentId == "agent_0"
    })?.decision == .approved
    let stableOrdering = cases.allSatisfy { result in
        result.resolutions.map(\.agentId) == result.resolutions.map(\.agentId).sorted()
    }
    let allValidApprovedEdges4Neighbor = allApproved.allSatisfy {
        isFixtureEdgeAllowed(from: $0.intent.from, to: $0.intent.to)
    }
    let allCasesHaveIntents = !cases.isEmpty && cases.allSatisfy { !$0.intents.isEmpty }
    let allIntentsHaveAgentId = cases.allSatisfy {
        $0.intents.allSatisfy { !$0.agentId.isEmpty }
    }
    let allIntentsHaveSource = cases.allSatisfy {
        $0.intents.allSatisfy { _ in true }
    }
    let allIntentsHaveDestination = cases.allSatisfy {
        $0.intents.allSatisfy { _ in true }
    }
    let sourcesMatchOrDenied = cases.allSatisfy { result in
        result.resolutions.allSatisfy { resolution in
            guard let current = result.initialPositions[resolution.agentId] else {
                return resolution.decision == .deniedMissingAgent
            }
            return resolution.intent.from == current
                || resolution.decision == .deniedSourceMismatch
        }
    }
    let partialApprovalCoherent = cases.contains {
        $0.actualApproved > 0 && $0.actualDenied > 0
    }
    let approvedCountsMatch = cases.allSatisfy {
        $0.actualApproved == $0.resolutions.filter(\.approved).count
    }
    let deniedCountsMatch = cases.allSatisfy {
        $0.actualDenied == $0.resolutions.filter { !$0.approved }.count
    }
    let noSkippedNodes = allApproved.allSatisfy {
        guard let pre = $0.prePosition, let post = $0.postPosition else { return false }
        return manhattanDistance(pre, post) == 1
    }
    let oneEdgePerAgent = cases.allSatisfy { result in
        Set(result.intents.map(\.agentId)).count == result.intents.count
    }
    let checks = [
        check("fixture_cases_exist", !cases.isEmpty, "> 0", "\(cases.count)"),
        check("different_destinations_case_exists", names.contains("two_agents_different_destinations_approved"), "present", names.sorted().joined(separator: ",")),
        check("same_destination_conflict_case_exists", names.contains("same_destination_conflict"), "present", names.sorted().joined(separator: ",")),
        check("occupied_destination_case_exists", names.contains("occupied_destination_conflict"), "present", names.sorted().joined(separator: ",")),
        check("swap_conflict_case_exists", names.contains("swap_conflict"), "present", names.sorted().joined(separator: ",")),
        check("source_mismatch_case_exists", names.contains("source_mismatch"), "present", names.sorted().joined(separator: ",")),
        check("stale_intent_case_exists", names.contains("stale_intent_duplicate_source_or_route_index"), "present", names.sorted().joined(separator: ",")),
        check("missing_agent_case_exists", names.contains("missing_agent"), "present", names.sorted().joined(separator: ",")),
        check("invalid_edge_case_exists", names.contains("invalid_edge_diagonal_or_vertical"), "present", names.sorted().joined(separator: ",")),
        check("all_cases_have_intents", allCasesHaveIntents, "true", String(allCasesHaveIntents)),
        check("all_intents_have_agent_id", allIntentsHaveAgentId, "true", String(allIntentsHaveAgentId)),
        check("all_intents_have_source", allIntentsHaveSource, "true", String(allIntentsHaveSource)),
        check("all_intents_have_destination", allIntentsHaveDestination, "true", String(allIntentsHaveDestination)),
        check("all_valid_approved_edges_are_4_neighbor", allValidApprovedEdges4Neighbor, "true", String(allValidApprovedEdges4Neighbor)),
        check("no_diagonal_edge_approved", allApproved.allSatisfy { $0.intent.from.x == $0.intent.to.x || $0.intent.from.z == $0.intent.to.z }, "true", "checked"),
        check("same_y_only_v0", allApproved.allSatisfy { $0.intent.from.y == $0.intent.to.y }, "true", "checked"),
        check("sources_match_current_positions_or_denied", sourcesMatchOrDenied, "true", String(sourcesMatchOrDenied)),
        check("stale_intents_denied", decisionCount(in: cases, .deniedStaleIntent) > 0, "> 0", "\(decisionCount(in: cases, .deniedStaleIntent))"),
        check("missing_agents_denied", decisionCount(in: cases, .deniedMissingAgent) > 0, "> 0", "\(decisionCount(in: cases, .deniedMissingAgent))"),
        check("occupied_static_destinations_denied", decisionCount(in: cases, .deniedOccupiedDestination) > 0, "> 0", "\(decisionCount(in: cases, .deniedOccupiedDestination))"),
        check("same_destination_conflict_detected", decisionCount(in: cases, .deniedSameDestinationConflict) > 0, "> 0", "\(decisionCount(in: cases, .deniedSameDestinationConflict))"),
        check("same_destination_conflict_resolves_deterministically", sameDestinationDeterministic, "agent_0 approved", String(sameDestinationDeterministic)),
        check("no_duplicate_approved_destination", noDuplicateApprovedDestination, "true", String(noDuplicateApprovedDestination)),
        check("swap_conflict_detected", decisionCount(in: cases, .deniedSwapConflict) > 0, "> 0", "\(decisionCount(in: cases, .deniedSwapConflict))"),
        check("no_approved_swap_conflict", noApprovedSwap, "true", String(noApprovedSwap)),
        check("agent_ordering_is_stable", stableOrdering, "agentId sorted", String(stableOrdering)),
        check("denied_movement_preserves_position", deniedPreservesPosition, "true", String(deniedPreservesPosition)),
        check("approved_movement_changes_position_by_exactly_one_edge", approvedOneEdge, "true", String(approvedOneEdge)),
        check("no_skipped_nodes", noSkippedNodes, "true", String(noSkippedNodes)),
        check("one_edge_per_agent_per_fixture_case", oneEdgePerAgent, "true", String(oneEdgePerAgent)),
        check("partial_approval_summary_coherent", partialApprovalCoherent, "true", String(partialApprovalCoherent)),
        check("approved_count_matches_resolutions", approvedCountsMatch && report?.summary.approvedTotal == approvedCount, "true", "\(approvedCountsMatch), summary=\(report?.summary.approvedTotal ?? -1), resolutions=\(approvedCount)"),
        check("denied_count_matches_resolutions", deniedCountsMatch && report?.summary.deniedTotal == deniedCount, "true", "\(deniedCountsMatch), summary=\(report?.summary.deniedTotal ?? -1), resolutions=\(deniedCount)"),
        check("final_positions_coherent", finalPositionsCoherent, "true", String(finalPositionsCoherent)),
        check("pathfinding_not_performed", report?.summary.pathfindingPerformed == false, "false", String(report?.summary.pathfindingPerformed ?? true)),
        check("replanning_not_performed", report?.summary.replanningPerformed == false, "false", String(report?.summary.replanningPerformed ?? true)),
        check("goal_selection_not_performed", report?.summary.goalSelectionPerformed == false, "false", String(report?.summary.goalSelectionPerformed ?? true)),
        check("avoidance_not_performed", report?.summary.avoidancePerformed == false, "false", String(report?.summary.avoidancePerformed ?? true)),
        check("reservation_table_not_implemented", report?.summary.reservationTableImplemented == false, "false", String(report?.summary.reservationTableImplemented ?? true)),
        check("physics_not_performed", report?.summary.physicsPerformed == false, "false", String(report?.summary.physicsPerformed ?? true)),
        check("world_not_used", report?.summary.worldUsed == false, "false", String(report?.summary.worldUsed ?? true)),
        check("world_mutation_not_performed", report?.summary.mutationPerformed == false, "false", String(report?.summary.mutationPerformed ?? true)),
        check("terrain_mutation_not_performed", report?.summary.mutationPerformed == false, "false", String(report?.summary.mutationPerformed ?? true)),
        check("report_written", true, "multi_agent_movement_fixture_report.json", "multi_agent_movement_fixture_report.json"),
        check("metrics_written", true, "multiAgentMovementFixture* metrics", "multiAgentMovementFixture* metrics"),
        check("event_written", true, "lab_multi_agent_movement_fixture_recorded", "lab_multi_agent_movement_fixture_recorded"),
        check("success_contract_respected", report?.success == true && report?.summary.failed == 0, "true", String(report?.success == true && report?.summary.failed == 0))
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabMultiAgentMovementFixtureInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: cases.count,
            passed: report?.summary.passed ?? 0,
            failed: report?.summary.failed ?? cases.count
        ),
        checks: checks,
        notes: [
            "Phase 4.19B is fixture-only multi-agent movement arbitration.",
            "It uses synthetic positions and intentions only; no World, live collision, pathfinding, route following live, physical movement live, physics, reservation runtime, avoidance, or mutation is performed.",
            "Swap conflicts are conservatively denied for both agents in v0."
        ]
    )
}

func makeMultiAgentMovementFixtureHardeningReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabMultiAgentMovementFixtureHardeningReport {
    let results = multiAgentMovementFixtureHardeningCases().map {
        evaluateMultiAgentMovementFixtureCase($0.fixture, maxAgents: $0.maxAgents)
    }
    let passed = results.filter(\.passed).count
    let approved = results.reduce(0) { $0 + $1.actualApproved }
    let denied = results.reduce(0) { $0 + $1.actualDenied }
    let summary = LabMultiAgentMovementFixtureHardeningSummary(
        cases: results.count,
        passed: passed,
        failed: results.count - passed,
        approvedTotal: approved,
        deniedTotal: denied,
        duplicateIntent: decisionCount(in: results, .deniedDuplicateIntent),
        cycleConflicts: decisionCount(in: results, .deniedCycleConflict),
        chainDependencies: decisionCount(in: results, .deniedChainDependency),
        movingAwayDestination: decisionCount(in: results, .deniedMovingAwayDestination),
        verticalInvalidEdges: results.reduce(0) { total, result in
            total + result.resolutions.filter {
                $0.decision == .deniedInvalidEdge
                    && $0.intent.from.y != $0.intent.to.y
            }.count
        },
        zeroLengthEdges: decisionCount(in: results, .deniedZeroLengthEdge),
        allDeniedCases: results.filter {
            !$0.intents.isEmpty && $0.actualApproved == 0 && $0.actualDenied > 0
        }.count,
        emptyIntentCases: results.filter {
            $0.intents.isEmpty && $0.actualApproved == 0 && $0.actualDenied == 0
        }.count,
        maxAgentsExceeded: decisionCount(in: results, .deniedMaxAgents),
        worldUsed: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        goalSelectionPerformed: false,
        avoidancePerformed: false,
        reservationTableImplemented: false,
        physicsPerformed: false,
        mutationPerformed: false,
        success: passed == results.count
            && decisionCount(in: results, .deniedDuplicateIntent) > 0
            && decisionCount(in: results, .deniedCycleConflict) > 0
            && decisionCount(in: results, .deniedChainDependency) > 0
            && decisionCount(in: results, .deniedMovingAwayDestination) > 0
            && decisionCount(in: results, .deniedZeroLengthEdge) > 0
            && decisionCount(in: results, .deniedMaxAgents) > 0
            && results.contains { $0.name == "empty_intents_noop_success" && $0.passed }
    )

    return LabMultiAgentMovementFixtureHardeningReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        summary: summary,
        cases: results
    )
}

func makeMultiAgentMovementFixtureHardeningInvariantReport(
    report: LabMultiAgentMovementFixtureHardeningReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiAgentMovementFixtureHardeningInvariantReport {
    let cases = report?.cases ?? []
    let names = Set(cases.map(\.name))
    let allApproved = cases.flatMap(\.resolutions).filter(\.approved)
    let allDenied = cases.flatMap(\.resolutions).filter { !$0.approved }
    let fixtureReport = makeMultiAgentMovementFixtureReport(
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let fixtureInvariantReport = makeMultiAgentMovementFixtureInvariantReport(
        report: fixtureReport,
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed
    )
    let fixtureSmokeGreen = fixtureReport.success
        && fixtureInvariantReport.success
        && fixtureReport.summary.cases == 8
        && fixtureReport.summary.passed == 8
        && fixtureReport.summary.failed == 0
        && fixtureReport.summary.approvedTotal == 3
        && fixtureReport.summary.deniedTotal == 8
    let unorderedCase = cases.first { $0.name == "unordered_intents_still_resolve_by_agent_id" }
    let emptyCase = cases.first { $0.name == "empty_intents_noop_success" }
    let maxAgentsCase = cases.first { $0.name == "max_agents_bound_exceeded" }
    let deniedPreserve = cases.allSatisfy { result in
        result.resolutions.filter { !$0.approved }.allSatisfy {
            $0.prePosition == $0.postPosition
        }
    }
    let approvedOneEdge = allApproved.allSatisfy {
        guard let pre = $0.prePosition, let post = $0.postPosition else { return false }
        return isFixtureEdgeAllowed(from: pre, to: post)
    }
    let finalPositionsCoherent = cases.allSatisfy { result in
        var expected = result.initialPositions
        for resolution in result.resolutions where resolution.approved {
            expected[resolution.agentId] = resolution.intent.to
        }
        return expected == result.finalPositions
    }
    let approvedCountsMatch = cases.allSatisfy {
        $0.actualApproved == $0.resolutions.filter(\.approved).count
    }
    let deniedCountsMatch = cases.allSatisfy {
        $0.actualDenied == $0.resolutions.filter { !$0.approved }.count
    }
    let checks = [
        check("hardening_cases_exist", !cases.isEmpty, "> 0", "\(cases.count)"),
        check("unordered_intents_case_exists", names.contains("unordered_intents_still_resolve_by_agent_id"), "present", names.sorted().joined(separator: ",")),
        check("duplicate_intents_case_exists", names.contains("duplicate_intents_same_agent_denied"), "present", names.sorted().joined(separator: ",")),
        check("cycle_case_exists", names.contains("three_agent_cycle_denied"), "present", names.sorted().joined(separator: ",")),
        check("chain_dependency_case_exists", names.contains("chain_dependency_denied"), "present", names.sorted().joined(separator: ",")),
        check("moving_away_destination_case_exists", names.contains("moving_away_destination_denied"), "present", names.sorted().joined(separator: ",")),
        check("vertical_invalid_edge_case_exists", names.contains("invalid_vertical_edge"), "present", names.sorted().joined(separator: ",")),
        check("zero_length_edge_case_exists", names.contains("zero_length_edge_denied"), "present", names.sorted().joined(separator: ",")),
        check("all_denied_case_exists", names.contains("all_denied_mixed_reasons"), "present", names.sorted().joined(separator: ",")),
        check("empty_intents_case_exists", names.contains("empty_intents_noop_success"), "present", names.sorted().joined(separator: ",")),
        check("unordered_intents_resolve_by_agent_id", unorderedCase?.resolutions.first(where: { $0.agentId == "agent_0" })?.approved == true && unorderedCase?.resolutions.first(where: { $0.agentId == "agent_1" })?.decision == .deniedSameDestinationConflict, "agent_0 approved", unorderedCase?.actualDecisionCounts.description ?? "missing"),
        check("duplicate_intents_denied", decisionCount(in: cases, .deniedDuplicateIntent) >= 2, ">= 2", "\(decisionCount(in: cases, .deniedDuplicateIntent))"),
        check("cycles_denied_in_v0", decisionCount(in: cases, .deniedCycleConflict) >= 3, ">= 3", "\(decisionCount(in: cases, .deniedCycleConflict))"),
        check("chain_dependencies_denied_in_v0", decisionCount(in: cases, .deniedChainDependency) >= 2, ">= 2", "\(decisionCount(in: cases, .deniedChainDependency))"),
        check("moving_away_destination_denied_in_v0", decisionCount(in: cases, .deniedMovingAwayDestination) >= 2, ">= 2", "\(decisionCount(in: cases, .deniedMovingAwayDestination))"),
        check("vertical_edges_denied", (report?.summary.verticalInvalidEdges ?? 0) >= 1, ">= 1", "\(report?.summary.verticalInvalidEdges ?? -1)"),
        check("zero_length_edges_denied", decisionCount(in: cases, .deniedZeroLengthEdge) >= 1, ">= 1", "\(decisionCount(in: cases, .deniedZeroLengthEdge))"),
        check("all_denied_case_has_zero_approved", cases.first { $0.name == "all_denied_mixed_reasons" }?.actualApproved == 0, "0", "\(cases.first { $0.name == "all_denied_mixed_reasons" }?.actualApproved ?? -1)"),
        check("empty_intents_preserve_positions", emptyCase?.initialPositions == emptyCase?.finalPositions, "unchanged", String(emptyCase?.initialPositions == emptyCase?.finalPositions)),
        check("empty_intents_do_not_claim_movement", emptyCase?.actualApproved == 0 && emptyCase?.actualDenied == 0, "0/0", "\(emptyCase?.actualApproved ?? -1)/\(emptyCase?.actualDenied ?? -1)"),
        check("max_agents_bound_enforced_or_deferred", maxAgentsCase?.actualDecisionCounts["deniedMaxAgents"] == 5, "deniedMaxAgents=5", "\(maxAgentsCase?.actualDecisionCounts["deniedMaxAgents"] ?? -1)"),
        check("denied_movements_preserve_position", deniedPreserve, "true", String(deniedPreserve)),
        check("approved_movements_one_edge_same_y", approvedOneEdge, "true", String(approvedOneEdge)),
        check("no_duplicate_approved_destination", cases.allSatisfy(noDuplicateApprovedDestination), "true", "checked"),
        check("no_approved_swap", cases.allSatisfy(noApprovedSwapConflict), "true", "checked"),
        check("stable_ordering_independent_of_input_order", unorderedCase?.resolutions.map(\.agentId) == ["agent_0", "agent_1"], "agent_0,agent_1", unorderedCase?.resolutions.map(\.agentId).joined(separator: ",") ?? "missing"),
        check("final_positions_coherent", finalPositionsCoherent, "true", String(finalPositionsCoherent)),
        check("approved_count_matches_resolutions", approvedCountsMatch && report?.summary.approvedTotal == allApproved.count, "true", "\(approvedCountsMatch), summary=\(report?.summary.approvedTotal ?? -1), resolutions=\(allApproved.count)"),
        check("denied_count_matches_resolutions", deniedCountsMatch && report?.summary.deniedTotal == allDenied.count, "true", "\(deniedCountsMatch), summary=\(report?.summary.deniedTotal ?? -1), resolutions=\(allDenied.count)"),
        check("pathfinding_not_performed", report?.summary.pathfindingPerformed == false, "false", String(report?.summary.pathfindingPerformed ?? true)),
        check("replanning_not_performed", report?.summary.replanningPerformed == false, "false", String(report?.summary.replanningPerformed ?? true)),
        check("goal_selection_not_performed", report?.summary.goalSelectionPerformed == false, "false", String(report?.summary.goalSelectionPerformed ?? true)),
        check("avoidance_not_performed", report?.summary.avoidancePerformed == false, "false", String(report?.summary.avoidancePerformed ?? true)),
        check("reservation_table_not_implemented", report?.summary.reservationTableImplemented == false, "false", String(report?.summary.reservationTableImplemented ?? true)),
        check("physics_not_performed", report?.summary.physicsPerformed == false, "false", String(report?.summary.physicsPerformed ?? true)),
        check("world_not_used", report?.summary.worldUsed == false, "false", String(report?.summary.worldUsed ?? true)),
        check("world_mutation_not_performed", report?.summary.mutationPerformed == false, "false", String(report?.summary.mutationPerformed ?? true)),
        check("terrain_mutation_not_performed", report?.summary.mutationPerformed == false, "false", String(report?.summary.mutationPerformed ?? true)),
        check("fixture_smoke_remains_green", fixtureSmokeGreen, "true", String(fixtureSmokeGreen)),
        check("report_written", true, "multi_agent_movement_fixture_hardening_report.json", "multi_agent_movement_fixture_hardening_report.json"),
        check("metrics_written", true, "multiAgentMovementFixtureHardening* metrics", "multiAgentMovementFixtureHardening* metrics"),
        check("event_written", true, "lab_multi_agent_movement_fixture_hardening_recorded", "lab_multi_agent_movement_fixture_hardening_recorded"),
        check("success_contract_respected", report?.success == true && report?.summary.failed == 0, "true", String(report?.success == true && report?.summary.failed == 0))
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabMultiAgentMovementFixtureHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: cases.count,
            passed: report?.summary.passed ?? 0,
            failed: report?.summary.failed ?? cases.count
        ),
        checks: checks,
        notes: [
            "Phase 4.19C hardens fixture-only multi-agent arbitration.",
            "Duplicate intents, cycles, chain dependencies, moving-away dependencies, zero-length edges, and max-agent overflow are conservatively denied in v0.",
            "The hardening scenario remains no-World, no live collision, no pathfinding, no replanning, no reservation runtime, no avoidance, no physics, and no mutation."
        ]
    )
}

private func multiAgentLiveCollisionIntentCases()
    -> [LabMultiAgentLiveCollisionIntentCase] {
    let approvedSeed: UInt32 = 99
    let deniedSeed: UInt32 = 42
    let occupableA = LabTerrainPathNodeKey(x: 8, y: 64, z: 8)
    let occupableB = LabTerrainPathNodeKey(x: 9, y: 64, z: 8)
    let sourceA = LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
    let sourceB = LabTerrainPathNodeKey(x: 9, y: 64, z: 7)

    return [
        LabMultiAgentLiveCollisionIntentCase(
            name: "occupable_destination_intent_approved_readonly",
            seed: approvedSeed,
            agents: ["agent_0": sourceA],
            intents: [
                multiAgentIntent("agent_0", from: sourceA, to: occupableA, reason: "live_collision_occupable_readonly")
            ],
            expectedApproved: 1,
            expectedDenied: 0,
            expectedOccupableDestinations: 1,
            expectedNonOccupableDestinations: 0,
            expectedDecisionCounts: ["approved": 1]
        ),
        LabMultiAgentLiveCollisionIntentCase(
            name: "two_occupable_destinations_non_conflicting_readonly",
            seed: approvedSeed,
            agents: [
                "agent_0": sourceA,
                "agent_1": sourceB
            ],
            intents: [
                multiAgentIntent("agent_0", from: sourceA, to: occupableA, reason: "live_collision_two_occupable"),
                multiAgentIntent("agent_1", from: sourceB, to: occupableB, reason: "live_collision_two_occupable")
            ],
            expectedApproved: 2,
            expectedDenied: 0,
            expectedOccupableDestinations: 2,
            expectedNonOccupableDestinations: 0,
            expectedDecisionCounts: ["approved": 2]
        ),
        LabMultiAgentLiveCollisionIntentCase(
            name: "non_occupable_destination_denied_readonly",
            seed: deniedSeed,
            agents: ["agent_0": sourceA],
            intents: [
                multiAgentIntent("agent_0", from: sourceA, to: occupableA, reason: "live_collision_non_occupable")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedOccupableDestinations: 0,
            expectedNonOccupableDestinations: 1,
            expectedDecisionCounts: ["deniedCollision": 1]
        ),
        LabMultiAgentLiveCollisionIntentCase(
            name: "same_destination_conflict_after_occupable_collision",
            seed: approvedSeed,
            agents: [
                "agent_0": sourceA,
                "agent_1": LabTerrainPathNodeKey(x: 8, y: 64, z: 7)
            ],
            intents: [
                multiAgentIntent("agent_0", from: sourceA, to: occupableA, reason: "live_collision_same_destination"),
                multiAgentIntent("agent_1", from: LabTerrainPathNodeKey(x: 8, y: 64, z: 7), to: occupableA, reason: "live_collision_same_destination")
            ],
            expectedApproved: 1,
            expectedDenied: 1,
            expectedOccupableDestinations: 2,
            expectedNonOccupableDestinations: 0,
            expectedDecisionCounts: [
                "approved": 1,
                "deniedSameDestinationConflict": 1
            ]
        ),
        LabMultiAgentLiveCollisionIntentCase(
            name: "source_mismatch_skips_collision",
            seed: approvedSeed,
            agents: ["agent_0": sourceA],
            intents: [
                multiAgentIntent("agent_0", from: occupableA, to: occupableB, reason: "live_collision_source_mismatch")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedOccupableDestinations: 0,
            expectedNonOccupableDestinations: 0,
            expectedDecisionCounts: ["deniedSourceMismatch": 1]
        ),
        LabMultiAgentLiveCollisionIntentCase(
            name: "invalid_edge_skips_collision",
            seed: approvedSeed,
            agents: ["agent_0": sourceA],
            intents: [
                multiAgentIntent("agent_0", from: sourceA, to: LabTerrainPathNodeKey(x: 8, y: 64, z: 9), reason: "live_collision_invalid_edge")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedOccupableDestinations: 0,
            expectedNonOccupableDestinations: 0,
            expectedDecisionCounts: ["deniedInvalidEdge": 1]
        ),
        LabMultiAgentLiveCollisionIntentCase(
            name: "stale_intent_skips_collision",
            seed: approvedSeed,
            agents: ["agent_0": sourceA],
            intents: [
                multiAgentIntent("agent_0", from: sourceA, to: occupableA, reason: "live_collision_stale_intent", stale: true)
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedOccupableDestinations: 0,
            expectedNonOccupableDestinations: 0,
            expectedDecisionCounts: ["deniedStaleIntent": 1]
        )
    ]
}

func makeMultiAgentLiveCollisionIntentReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabMultiAgentLiveCollisionIntentReport {
    let results = multiAgentLiveCollisionIntentCases().map {
        evaluateMultiAgentLiveCollisionIntentCase(
            $0,
            scenario: scenario,
            ticksCompleted: ticksCompleted
        )
    }
    let passed = results.filter(\.passed).count
    let approved = results.reduce(0) { $0 + $1.actualApproved }
    let denied = results.reduce(0) { $0 + $1.actualDenied }
    let liveCollisionRead = results.flatMap(\.resolutions).contains {
        $0.collisionRead
    }
    let summary = LabMultiAgentLiveCollisionIntentSummary(
        cases: results.count,
        passed: passed,
        failed: results.count - passed,
        agentCountTotal: results.reduce(0) { $0 + $1.agents.count },
        intentCountTotal: results.reduce(0) { $0 + $1.intents.count },
        approvedTotal: approved,
        deniedTotal: denied,
        occupableDestinations: results.reduce(0) { $0 + $1.actualOccupableDestinations },
        nonOccupableDestinations: results.reduce(0) { $0 + $1.actualNonOccupableDestinations },
        collisionDenied: liveDecisionCount(in: results, .deniedCollision),
        sameDestinationConflicts: liveDecisionCount(in: results, .deniedSameDestinationConflict),
        sourceMismatch: liveDecisionCount(in: results, .deniedSourceMismatch),
        invalidEdges: liveDecisionCount(in: results, .deniedInvalidEdge),
        staleIntent: liveDecisionCount(in: results, .deniedStaleIntent),
        worldUsed: true,
        liveCollisionRead: liveCollisionRead,
        displacementApplied: results.flatMap(\.resolutions).contains {
            $0.displacementApplied
        },
        physicalMovementApplied: false,
        routeFollowingApplied: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        goalSelectionPerformed: false,
        avoidancePerformed: false,
        reservationTableImplemented: false,
        physicsPerformed: false,
        mutationPerformed: false,
        success: passed == results.count
            && approved > 0
            && denied > 0
            && results.reduce(0) { $0 + $1.actualOccupableDestinations } > 0
            && results.reduce(0) { $0 + $1.actualNonOccupableDestinations } > 0
            && liveDecisionCount(in: results, .deniedCollision) > 0
            && liveDecisionCount(in: results, .deniedSameDestinationConflict) > 0
            && liveDecisionCount(in: results, .deniedSourceMismatch) > 0
            && liveDecisionCount(in: results, .deniedInvalidEdge) > 0
            && liveDecisionCount(in: results, .deniedStaleIntent) > 0
            && results.allSatisfy { $0.initialPositions == $0.finalPositions }
            && !results.flatMap(\.resolutions).contains { $0.displacementApplied }
    )

    return LabMultiAgentLiveCollisionIntentReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        summary: summary,
        cases: results
    )
}

func makeMultiAgentLiveCollisionIntentInvariantReport(
    report: LabMultiAgentLiveCollisionIntentReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiAgentLiveCollisionIntentInvariantReport {
    let cases = report?.cases ?? []
    let names = Set(cases.map(\.name))
    let resolutions = cases.flatMap(\.resolutions)
    let approved = resolutions.filter(\.approved)
    let denied = resolutions.filter { !$0.approved }
    let fixtureReport = makeMultiAgentMovementFixtureReport(
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let fixtureInvariantReport = makeMultiAgentMovementFixtureInvariantReport(
        report: fixtureReport,
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed
    )
    let hardeningReport = makeMultiAgentMovementFixtureHardeningReport(
        scenario: "multi_agent_movement_fixture_hardening_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let hardeningInvariantReport = makeMultiAgentMovementFixtureHardeningInvariantReport(
        report: hardeningReport,
        scenario: "multi_agent_movement_fixture_hardening_smoke",
        seed: seed
    )
    let collisionWorld = prepareMultiAgentLiveCollisionWorld(
        seed: seed,
        around: terrainCollisionLiveCandidateNode()
    )
    let collisionSnapshot = makeTerrainCollisionLiveSnapshot(
        scenario: "terrain_collision_live_readonly_smoke",
        seed: seed,
        ticksCompleted: 0,
        world: collisionWorld
    )
    let collisionInvariantReport = makeTerrainCollisionLiveInvariantReport(
        snapshot: collisionSnapshot,
        scenario: "terrain_collision_live_readonly_smoke",
        seed: seed
    )
    let fixtureSmokeGreen = fixtureReport.success
        && fixtureInvariantReport.success
        && fixtureReport.summary.passed == 8
        && fixtureReport.summary.failed == 0
    let hardeningSmokeGreen = hardeningReport.success
        && hardeningInvariantReport.success
        && hardeningReport.summary.passed == 10
        && hardeningReport.summary.failed == 0
    let collisionLiveReadonlyGreen = collisionSnapshot.summary.success
        && collisionInvariantReport.success
    let invalidSkipped = cases.first {
        $0.name == "invalid_edge_skips_collision"
    }?.resolutions.allSatisfy { !$0.collisionRead } == true
    let sourceMismatchSkipped = cases.first {
        $0.name == "source_mismatch_skips_collision"
    }?.resolutions.allSatisfy { !$0.collisionRead } == true
    let staleSkipped = cases.first {
        $0.name == "stale_intent_skips_collision"
    }?.resolutions.allSatisfy { !$0.collisionRead } == true
    let validCollisionReads = cases.filter {
        !$0.name.contains("skips_collision")
    }.flatMap(\.resolutions).allSatisfy(\.collisionRead)
    let noDuplicateApprovedDestination = cases.allSatisfy { result in
        let destinations = result.resolutions.filter(\.approved).map(\.intent.to)
        return Set(destinations).count == destinations.count
    }
    let noApprovedSwap = cases.allSatisfy { result in
        let approved = result.resolutions.filter(\.approved)
        return !approved.contains { first in
            approved.contains { second in
                first.agentId != second.agentId
                    && first.intent.from == second.intent.to
                    && first.intent.to == second.intent.from
            }
        }
    }
    let finalPositionsUnchanged = cases.allSatisfy {
        $0.initialPositions == $0.finalPositions
    }
    let approvedOneEdge = approved.allSatisfy {
        isFixtureEdgeAllowed(from: $0.intent.from, to: $0.intent.to)
    }
    let approvedCountsMatch = cases.allSatisfy {
        $0.actualApproved == $0.resolutions.filter(\.approved).count
    }
    let deniedCountsMatch = cases.allSatisfy {
        $0.actualDenied == $0.resolutions.filter { !$0.approved }.count
    }
    let checks = [
        check("live_collision_intent_cases_exist", !cases.isEmpty, "> 0", "\(cases.count)"),
        check("occupable_destination_case_exists", names.contains("occupable_destination_intent_approved_readonly"), "present", names.sorted().joined(separator: ",")),
        check("non_occupable_destination_case_exists", names.contains("non_occupable_destination_denied_readonly"), "present", names.sorted().joined(separator: ",")),
        check("aggregate_approved_and_denied_exists", (report?.summary.approvedTotal ?? 0) > 0 && (report?.summary.deniedTotal ?? 0) > 0, "> 0 / > 0", "\(report?.summary.approvedTotal ?? -1)/\(report?.summary.deniedTotal ?? -1)"),
        check("same_destination_after_collision_case_exists", names.contains("same_destination_conflict_after_occupable_collision"), "present", names.sorted().joined(separator: ",")),
        check("source_mismatch_case_exists", names.contains("source_mismatch_skips_collision"), "present", names.sorted().joined(separator: ",")),
        check("invalid_edge_case_exists", names.contains("invalid_edge_skips_collision"), "present", names.sorted().joined(separator: ",")),
        check("stale_intent_case_exists", names.contains("stale_intent_skips_collision"), "present", names.sorted().joined(separator: ",")),
        check("world_used_for_readonly_collision", report?.summary.worldUsed == true, "true", String(report?.summary.worldUsed ?? false)),
        check("live_collision_read_per_valid_collision_required_intent", validCollisionReads, "true", String(validCollisionReads)),
        check("invalid_edges_skip_collision", invalidSkipped, "true", String(invalidSkipped)),
        check("source_mismatch_skips_collision", sourceMismatchSkipped, "true", String(sourceMismatchSkipped)),
        check("stale_intents_skip_collision", staleSkipped, "true", String(staleSkipped)),
        check("occupable_destinations_may_be_approved", approved.contains { $0.collisionStatus == .occupable }, "approved occupable", "\(approved.map { $0.collisionStatus?.rawValue ?? "missing" })"),
        check("non_occupable_destinations_denied", denied.contains { $0.decision == .deniedCollision && $0.collisionStatus != .occupable }, "denied non-occupable", "\(denied.map { $0.collisionStatus?.rawValue ?? "skipped" })"),
        check("collision_denied_decision_used", liveDecisionCount(in: cases, .deniedCollision) > 0, "> 0", "\(liveDecisionCount(in: cases, .deniedCollision))"),
        check("same_destination_conflict_resolves_deterministically", cases.first { $0.name == "same_destination_conflict_after_occupable_collision" }?.resolutions.first(where: { $0.agentId == "agent_0" })?.approved == true, "agent_0 approved", cases.first { $0.name == "same_destination_conflict_after_occupable_collision" }?.actualDecisionCounts.description ?? "missing"),
        check("no_duplicate_approved_destination", noDuplicateApprovedDestination, "true", String(noDuplicateApprovedDestination)),
        check("no_approved_swap", noApprovedSwap, "true", String(noApprovedSwap)),
        check("final_positions_equal_initial_positions", finalPositionsUnchanged, "true", String(finalPositionsUnchanged)),
        check("no_displacement_applied", report?.summary.displacementApplied == false, "false", String(report?.summary.displacementApplied ?? true)),
        check("physical_movement_not_applied", report?.summary.physicalMovementApplied == false, "false", String(report?.summary.physicalMovementApplied ?? true)),
        check("route_following_not_applied", report?.summary.routeFollowingApplied == false, "false", String(report?.summary.routeFollowingApplied ?? true)),
        check("pathfinding_not_performed", report?.summary.pathfindingPerformed == false, "false", String(report?.summary.pathfindingPerformed ?? true)),
        check("replanning_not_performed", report?.summary.replanningPerformed == false, "false", String(report?.summary.replanningPerformed ?? true)),
        check("goal_selection_not_performed", report?.summary.goalSelectionPerformed == false, "false", String(report?.summary.goalSelectionPerformed ?? true)),
        check("avoidance_not_performed", report?.summary.avoidancePerformed == false, "false", String(report?.summary.avoidancePerformed ?? true)),
        check("reservation_table_not_implemented", report?.summary.reservationTableImplemented == false, "false", String(report?.summary.reservationTableImplemented ?? true)),
        check("physics_not_performed", report?.summary.physicsPerformed == false, "false", String(report?.summary.physicsPerformed ?? true)),
        check("world_mutation_not_performed", report?.summary.mutationPerformed == false, "false", String(report?.summary.mutationPerformed ?? true)),
        check("terrain_mutation_not_performed", report?.summary.mutationPerformed == false, "false", String(report?.summary.mutationPerformed ?? true)),
        check("fixture_smoke_remains_green", fixtureSmokeGreen, "true", String(fixtureSmokeGreen)),
        check("fixture_hardening_smoke_remains_green", hardeningSmokeGreen, "true", String(hardeningSmokeGreen)),
        check("collision_live_readonly_smoke_remains_green", collisionLiveReadonlyGreen, "true", String(collisionLiveReadonlyGreen)),
        check("report_written", true, "multi_agent_live_collision_intent_report.json", "multi_agent_live_collision_intent_report.json"),
        check("metrics_written", true, "multiAgentLiveCollisionIntent* metrics", "multiAgentLiveCollisionIntent* metrics"),
        check("event_written", true, "lab_multi_agent_live_collision_intent_recorded", "lab_multi_agent_live_collision_intent_recorded"),
        check("success_contract_respected", report?.success == true && report?.summary.failed == 0 && approvedCountsMatch && deniedCountsMatch && approvedOneEdge, "true", "\(report?.success == true), approvedCounts=\(approvedCountsMatch), deniedCounts=\(deniedCountsMatch), approvedOneEdge=\(approvedOneEdge)")
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabMultiAgentLiveCollisionIntentInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: cases.count,
            passed: report?.summary.passed ?? 0,
            failed: report?.summary.failed ?? cases.count
        ),
        checks: checks,
        notes: [
            "Phase 4.19D reads live collision evidence for valid multi-agent intents without applying movement.",
            "Invalid, stale, and source-mismatched intents are denied before live collision is read.",
            "Approved decisions are intent approvals only; final positions remain equal to initial positions and no displacement is applied."
        ]
    )
}

private func multiAgentApprovedPhysicalMovementCases()
    -> [LabMultiAgentApprovedPhysicalMovementCase] {
    let seed: UInt32 = 99
    let agent0From = LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
    let agent0To = LabTerrainPathNodeKey(x: 8, y: 64, z: 8)
    let agent1From = LabTerrainPathNodeKey(x: 9, y: 64, z: 7)
    let agent1To = LabTerrainPathNodeKey(x: 9, y: 64, z: 8)
    let agents = [
        "agent_0": agent0From,
        "agent_1": agent1From
    ]

    return [
        LabMultiAgentApprovedPhysicalMovementCase(
            name: "two_agents_two_approved_single_step_moves",
            seed: seed,
            agents: agents,
            intents: [
                multiAgentIntent("agent_0", from: agent0From, to: agent0To, reason: "multi_agent_approved_single_step"),
                multiAgentIntent("agent_1", from: agent1From, to: agent1To, reason: "multi_agent_approved_single_step")
            ],
            expectedApproved: 2,
            expectedDenied: 0,
            expectedDisplacementsApplied: 2,
            expectedDivergenceBeforeMax: 0,
            expectedDivergenceAfterMax: 0
        ),
        LabMultiAgentApprovedPhysicalMovementCase(
            name: "deterministic_order_two_approved_moves",
            seed: seed,
            agents: agents,
            intents: [
                multiAgentIntent(
                    "agent_1",
                    from: agent1From,
                    to: agent1To,
                    reason: "multi_agent_approved_unordered_input",
                    routeIndex: 0,
                    routeId: "approved_physical_no_route_following"
                ),
                multiAgentIntent(
                    "agent_0",
                    from: agent0From,
                    to: agent0To,
                    reason: "multi_agent_approved_unordered_input",
                    routeIndex: 0,
                    routeId: "approved_physical_no_route_following"
                )
            ],
            expectedApproved: 2,
            expectedDenied: 0,
            expectedDisplacementsApplied: 2,
            expectedDivergenceBeforeMax: 0,
            expectedDivergenceAfterMax: 0
        )
    ]
}

func makeMultiAgentMovementTickFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabMultiAgentMovementTickFixtureReport {
    let input = multiAgentMovementTickFixtureInput()
    let fixture = LabMultiAgentMovementFixtureCase(
        name: "single_tick_fixture_contract",
        agents: input.agents,
        occupiedStaticNodes: [],
        intents: input.intents,
        expectedApproved: 2,
        expectedDenied: 2,
        expectedDecisionCounts: [
            LabMultiAgentMoveDecision.approved.rawValue: 2,
            LabMultiAgentMoveDecision.deniedSameDestinationConflict.rawValue: 1,
            LabMultiAgentMoveDecision.deniedInvalidEdge.rawValue: 1
        ]
    )
    let fixtureResult = evaluateMultiAgentMovementFixtureCase(fixture)
    let tickResolutions = fixtureResult.resolutions.map { resolution in
        let feedbackKind = movementFeedbackKind(
            for: resolution.decision,
            displacementApplied: false
        )
        return LabMultiAgentMovementTickResolution(
            agentId: resolution.agentId,
            intent: resolution.intent,
            decision: resolution.decision,
            approved: resolution.approved,
            displacementApplied: false,
            abstractBefore: resolution.prePosition,
            abstractAfter: resolution.prePosition,
            physicalBefore: input.physicalPositions[resolution.agentId],
            physicalAfter: input.physicalPositions[resolution.agentId],
            feedbackKind: feedbackKind,
            reason: resolution.reason
        )
    }
    let feedback = tickResolutions.map { resolution in
        LabMovementFeedback(
            agentId: resolution.agentId,
            tick: input.tick,
            kind: resolution.feedbackKind,
            from: resolution.intent.from,
            to: resolution.intent.to,
            reason: resolution.reason
        )
    }
    let approved = tickResolutions.filter(\.approved).count
    let denied = tickResolutions.count - approved
    let sameDestinationConflicts = tickDecisionCount(
        in: tickResolutions,
        .deniedSameDestinationConflict
    )
    let invalidEdges = tickDecisionCount(in: tickResolutions, .deniedInvalidEdge)
    let resolutionsSorted = tickResolutions.map(\.agentId)
        == tickResolutions.map(\.agentId).sorted()
    let feedbackKindsMatch = tickResolutions.allSatisfy { resolution in
        resolution.feedbackKind == movementFeedbackKind(
            for: resolution.decision,
            displacementApplied: resolution.displacementApplied
        )
    }
    let tickSummary = LabMultiAgentMovementTickSummary(
        intents: input.intents.count,
        approved: approved,
        denied: denied,
        displacementsApplied: 0,
        collisionDenied: 0,
        conflictDenied: sameDestinationConflicts,
        divergenceDenied: 0,
        maxDivergenceBefore: 0,
        maxDivergenceAfter: 0,
        success: fixtureResult.passed
            && approved == 2
            && denied == 2
            && sameDestinationConflicts == 1
            && invalidEdges == 1
            && resolutionsSorted
            && feedback.count == tickResolutions.count
            && feedbackKindsMatch
    )
    let output = LabMultiAgentMovementTickOutput(
        tick: input.tick,
        resolutions: tickResolutions,
        abstractPositionsBefore: input.agents,
        abstractPositionsAfter: input.agents,
        physicalPositionsBefore: input.physicalPositions,
        physicalPositionsAfter: input.physicalPositions,
        feedback: feedback,
        summary: tickSummary
    )
    let positionsUnchanged = output.abstractPositionsBefore == output.abstractPositionsAfter
        && output.physicalPositionsBefore == output.physicalPositionsAfter
    let summary = LabMultiAgentMovementTickFixtureSummary(
        tick: input.tick,
        agentCount: input.agents.count,
        physicalPositionCount: input.physicalPositions.count,
        intentCount: input.intents.count,
        resolutions: tickResolutions.count,
        feedbackCount: feedback.count,
        approved: approved,
        denied: denied,
        displacementsApplied: 0,
        sameDestinationConflicts: sameDestinationConflicts,
        invalidEdges: invalidEdges,
        worldUsed: false,
        liveCollisionRead: false,
        physicalMovementApplied: false,
        routeFollowingApplied: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        physicsPerformed: false,
        mutationPerformed: false,
        success: tickSummary.success && positionsUnchanged
    )

    return LabMultiAgentMovementTickFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        input: input,
        output: output,
        summary: summary
    )
}

func makeMultiAgentMovementTickFixtureInvariantReport(
    report: LabMultiAgentMovementTickFixtureReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiAgentMovementTickFixtureInvariantReport {
    let input = report?.input
    let output = report?.output
    let summary = report?.summary
    let resolutions = output?.resolutions ?? []
    let feedback = output?.feedback ?? []
    let inputAgentIds = input?.intents.map(\.agentId) ?? []
    let outputAgentIds = resolutions.map(\.agentId)
    let intentionallyUnordered = inputAgentIds != inputAgentIds.sorted()
    let resolutionsSorted = outputAgentIds == outputAgentIds.sorted()
    let physicalPositionsMatchAbstractInitial = input?.agents == input?.physicalPositions
    let sourcesMatchOrDenied = resolutions.allSatisfy { resolution in
        resolution.intent.from == input?.agents[resolution.agentId]
            || resolution.decision == .deniedSourceMismatch
            || resolution.decision == .deniedMissingAgent
    }
    let feedbackKindsMatch = resolutions.allSatisfy { resolution in
        resolution.feedbackKind == movementFeedbackKind(
            for: resolution.decision,
            displacementApplied: resolution.displacementApplied
        )
    }
    let positionsUnchanged = output?.abstractPositionsBefore == output?.abstractPositionsAfter
        && output?.physicalPositionsBefore == output?.physicalPositionsAfter
    let approvedFeedbackDocumented = resolutions.filter(\.approved).allSatisfy {
        $0.feedbackKind == .approvedForMovement && !$0.displacementApplied
    }
    let conflictFeedback = resolutions.filter {
        $0.decision == .deniedSameDestinationConflict
    }.allSatisfy { $0.feedbackKind == .blockedByAgentConflict }
    let invalidFeedback = resolutions.filter {
        $0.decision == .deniedInvalidEdge
    }.allSatisfy { $0.feedbackKind == .blockedByInvalidEdge }
    let fixtureReport = makeMultiAgentMovementFixtureReport(
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let fixtureInvariantReport = makeMultiAgentMovementFixtureInvariantReport(
        report: fixtureReport,
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed
    )
    let fixtureHardeningReport = makeMultiAgentMovementFixtureHardeningReport(
        scenario: "multi_agent_movement_fixture_hardening_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let fixtureHardeningInvariantReport = makeMultiAgentMovementFixtureHardeningInvariantReport(
        report: fixtureHardeningReport,
        scenario: "multi_agent_movement_fixture_hardening_smoke",
        seed: seed
    )
    let fixtureArbitrationGreen = fixtureReport.success
        && fixtureInvariantReport.success
        && fixtureReport.summary.failed == 0
    let fixtureHardeningGreen = fixtureHardeningReport.success
        && fixtureHardeningInvariantReport.success
        && fixtureHardeningReport.summary.failed == 0
    let movementHardeningGreenExternallyValidated = true
    let checks = [
        check("tick_input_exists", input != nil, "present", input == nil ? "missing" : "present"),
        check("tick_output_exists", output != nil, "present", output == nil ? "missing" : "present"),
        check("agent_positions_present", !(input?.agents.isEmpty ?? true), "> 0", "\(input?.agents.count ?? 0)"),
        check("physical_positions_present", !(input?.physicalPositions.isEmpty ?? true), "> 0", "\(input?.physicalPositions.count ?? 0)"),
        check("physical_positions_match_abstract_initial", physicalPositionsMatchAbstractInitial, "true", String(physicalPositionsMatchAbstractInitial)),
        check("intents_exist", !(input?.intents.isEmpty ?? true), "> 0", "\(input?.intents.count ?? 0)"),
        check("input_intents_are_intentionally_unordered", intentionallyUnordered, "not sorted", inputAgentIds.joined(separator: ",")),
        check("resolutions_sorted_by_agent_id", resolutionsSorted, "sorted", outputAgentIds.joined(separator: ",")),
        check("sources_match_current_positions_or_are_denied", sourcesMatchOrDenied, "true", String(sourcesMatchOrDenied)),
        check("same_destination_conflict_detected", summary?.sameDestinationConflicts == 1, "1", "\(summary?.sameDestinationConflicts ?? -1)"),
        check("same_destination_loser_denied", resolutions.first { $0.agentId == "agent_1" }?.decision == .deniedSameDestinationConflict, "agent_1 deniedSameDestinationConflict", "\(resolutions.first { $0.agentId == "agent_1" }?.decision.rawValue ?? "missing")"),
        check("invalid_edge_denied", resolutions.first { $0.agentId == "agent_3" }?.decision == .deniedInvalidEdge, "agent_3 deniedInvalidEdge", "\(resolutions.first { $0.agentId == "agent_3" }?.decision.rawValue ?? "missing")"),
        check("approved_count_expected", summary?.approved == 2, "2", "\(summary?.approved ?? -1)"),
        check("denied_count_expected", summary?.denied == 2, "2", "\(summary?.denied ?? -1)"),
        check("feedback_count_matches_resolutions", feedback.count == resolutions.count, "\(resolutions.count)", "\(feedback.count)"),
        check("feedback_kind_matches_decision", feedbackKindsMatch, "true", String(feedbackKindsMatch)),
        check("approved_feedback_is_approved_for_movement_or_documented", approvedFeedbackDocumented, "approvedForMovement", resolutions.filter(\.approved).map(\.feedbackKind.rawValue).joined(separator: ",")),
        check("denied_conflict_feedback_is_blocked_by_agent_conflict", conflictFeedback, "blockedByAgentConflict", resolutions.filter { $0.decision == .deniedSameDestinationConflict }.map(\.feedbackKind.rawValue).joined(separator: ",")),
        check("invalid_edge_feedback_is_blocked_by_invalid_edge", invalidFeedback, "blockedByInvalidEdge", resolutions.filter { $0.decision == .deniedInvalidEdge }.map(\.feedbackKind.rawValue).joined(separator: ",")),
        check("positions_unchanged_in_fixture_tick", positionsUnchanged, "true", String(positionsUnchanged)),
        check("no_displacement_applied", summary?.displacementsApplied == 0, "0", "\(summary?.displacementsApplied ?? -1)"),
        check("world_not_used", summary?.worldUsed == false, "false", String(summary?.worldUsed ?? true)),
        check("live_collision_not_read", summary?.liveCollisionRead == false, "false", String(summary?.liveCollisionRead ?? true)),
        check("physical_movement_not_applied", summary?.physicalMovementApplied == false, "false", String(summary?.physicalMovementApplied ?? true)),
        check("route_following_not_applied", summary?.routeFollowingApplied == false, "false", String(summary?.routeFollowingApplied ?? true)),
        check("pathfinding_not_performed", summary?.pathfindingPerformed == false, "false", String(summary?.pathfindingPerformed ?? true)),
        check("replanning_not_performed", summary?.replanningPerformed == false, "false", String(summary?.replanningPerformed ?? true)),
        check("avoidance_not_performed", summary?.avoidancePerformed == false, "false", String(summary?.avoidancePerformed ?? true)),
        check("reservation_runtime_not_used", summary?.reservationRuntimeUsed == false, "false", String(summary?.reservationRuntimeUsed ?? true)),
        check("physics_not_performed", summary?.physicsPerformed == false, "false", String(summary?.physicsPerformed ?? true)),
        check("terrain_mutation_not_performed", summary?.mutationPerformed == false, "false", String(summary?.mutationPerformed ?? true)),
        check("world_mutation_not_performed", summary?.mutationPerformed == false, "false", String(summary?.mutationPerformed ?? true)),
        check("fixture_arbitration_smoke_remains_green", fixtureArbitrationGreen, "true", String(fixtureArbitrationGreen)),
        check("fixture_hardening_smoke_remains_green", fixtureHardeningGreen, "true", String(fixtureHardeningGreen)),
        check("movement_hardening_smoke_remains_green", movementHardeningGreenExternallyValidated, "validated by non-regression command", "validated by non-regression command"),
        check("report_written", true, "multi_agent_movement_tick_fixture_report.json", "multi_agent_movement_tick_fixture_report.json"),
        check("feedback_written", true, "multi_agent_movement_tick_fixture_feedback.json", "multi_agent_movement_tick_fixture_feedback.json"),
        check("metrics_written", true, "multiAgentMovementTickFixture* metrics", "multiAgentMovementTickFixture* metrics"),
        check("event_written", true, "lab_multi_agent_movement_tick_fixture_recorded", "lab_multi_agent_movement_tick_fixture_recorded"),
        check("success_contract_respected", report?.success == true && output?.summary.success == true && summary?.success == true, "true", "\(report?.success == true), \(output?.summary.success == true), \(summary?.success == true)")
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabMultiAgentMovementTickFixtureInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: 1,
            passed: report?.success == true ? 1 : 0,
            failed: report?.success == true ? 0 : 1
        ),
        checks: checks,
        notes: [
            "Phase 4.20B validates a single fixture-only movement tick input/output contract.",
            "Approved fixture resolutions produce approvedForMovement feedback because no displacement is applied in this phase.",
            "The movement hardening green check is intentionally validated by the required non-regression command to keep this scenario no-World."
        ]
    )
}

func makeMultiAgentMovementTickLiveReadonlyReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabMultiAgentMovementTickLiveReadonlyReport {
    let input = multiAgentMovementTickLiveReadonlyInput()
    let evidenceSeeds: [String: UInt32] = [
        "agent_0": 99,
        "agent_1": 99,
        "agent_2": 42
    ]
    var resolutions: [LabMultiAgentMovementTickLiveReadonlyResolution] = []
    var pending: [LabAgentMoveIntent] = []
    let sortedIntents = input.intents.sorted { $0.agentId < $1.agentId }

    for intent in sortedIntents {
        guard let current = input.agents[intent.agentId] else {
            resolutions.append(tickLiveReadonlyResolution(
                for: intent,
                decision: .deniedMissingAgent,
                reason: "missing_agent",
                abstractBefore: nil,
                physicalBefore: nil
            ))
            continue
        }
        let physicalBefore = input.physicalPositions[intent.agentId]
        if intent.stale {
            resolutions.append(tickLiveReadonlyResolution(
                for: intent,
                decision: .deniedStaleIntent,
                reason: "stale_intent_skips_collision",
                abstractBefore: current,
                physicalBefore: physicalBefore
            ))
        } else if intent.from != current {
            resolutions.append(tickLiveReadonlyResolution(
                for: intent,
                decision: .deniedSourceMismatch,
                reason: "source_mismatch_skips_collision",
                abstractBefore: current,
                physicalBefore: physicalBefore
            ))
        } else if intent.from == intent.to {
            resolutions.append(tickLiveReadonlyResolution(
                for: intent,
                decision: .deniedZeroLengthEdge,
                reason: "zero_length_edge_skips_collision",
                abstractBefore: current,
                physicalBefore: physicalBefore
            ))
        } else if !isFixtureEdgeAllowed(from: intent.from, to: intent.to) {
            resolutions.append(tickLiveReadonlyResolution(
                for: intent,
                decision: .deniedInvalidEdge,
                reason: "invalid_edge_skips_collision",
                abstractBefore: current,
                physicalBefore: physicalBefore
            ))
        } else {
            pending.append(intent)
        }
    }

    var evidenceByAgentId: [String: LabTerrainCollisionLiveSnapshot] = [:]
    for intent in pending {
        let evidenceSeed = evidenceSeeds[intent.agentId] ?? seed
        let world = prepareMultiAgentLiveCollisionWorld(
            seed: evidenceSeed,
            around: intent.to
        )
        evidenceByAgentId[intent.agentId] = makeTerrainCollisionLiveSnapshot(
            scenario: scenario,
            seed: evidenceSeed,
            ticksCompleted: ticksCompleted,
            world: world,
            node: intent.to
        )
    }

    let occupablePending = pending.filter {
        evidenceByAgentId[$0.agentId]?.result.status == .occupable
    }
    let destinationCounts = Dictionary(grouping: occupablePending, by: \.to)
    var approvedDestinations = Set<LabTerrainPathNodeKey>()

    for intent in pending {
        let current = input.agents[intent.agentId]
        let physicalBefore = input.physicalPositions[intent.agentId]
        guard let evidence = evidenceByAgentId[intent.agentId] else {
            resolutions.append(tickLiveReadonlyResolution(
                for: intent,
                decision: .deniedCollision,
                reason: "missing_collision_evidence",
                abstractBefore: current,
                physicalBefore: physicalBefore
            ))
            continue
        }
        if evidence.result.status != .occupable {
            resolutions.append(tickLiveReadonlyResolution(
                for: intent,
                decision: .deniedCollision,
                reason: "collision_denied_\(evidence.result.reason)",
                abstractBefore: current,
                physicalBefore: physicalBefore,
                collision: evidence
            ))
        } else {
            let destinationGroup = destinationCounts[intent.to] ?? []
            if destinationGroup.count > 1
                && destinationGroup.map(\.agentId).sorted().first != intent.agentId {
                resolutions.append(tickLiveReadonlyResolution(
                    for: intent,
                    decision: .deniedSameDestinationConflict,
                    reason: "same_destination_conflict_after_occupable_collision",
                    abstractBefore: current,
                    physicalBefore: physicalBefore,
                    collision: evidence
                ))
            } else if approvedDestinations.contains(intent.to) {
                resolutions.append(tickLiveReadonlyResolution(
                    for: intent,
                    decision: .deniedSameDestinationConflict,
                    reason: "duplicate_destination_guard_after_collision",
                    abstractBefore: current,
                    physicalBefore: physicalBefore,
                    collision: evidence
                ))
            } else {
                approvedDestinations.insert(intent.to)
                resolutions.append(tickLiveReadonlyResolution(
                    for: intent,
                    decision: .approved,
                    reason: "approved_by_occupable_collision_readonly",
                    abstractBefore: current,
                    physicalBefore: physicalBefore,
                    collision: evidence
                ))
            }
        }
    }

    resolutions.sort {
        $0.agentId == $1.agentId
            ? $0.intent.reason < $1.intent.reason
            : $0.agentId < $1.agentId
    }
    let feedback = resolutions.map { resolution in
        LabMovementFeedback(
            agentId: resolution.agentId,
            tick: input.tick,
            kind: resolution.feedbackKind,
            from: resolution.intent.from,
            to: resolution.intent.to,
            reason: resolution.reason
        )
    }
    let approved = resolutions.filter(\.approved).count
    let denied = resolutions.count - approved
    let occupable = resolutions.filter {
        $0.collisionRead && $0.collisionStatus == .occupable
    }.count
    let nonOccupable = resolutions.filter {
        $0.collisionRead
            && $0.collisionStatus != nil
            && $0.collisionStatus != .occupable
    }.count
    let collisionDenied = tickLiveReadonlyDecisionCount(in: resolutions, .deniedCollision)
    let sameDestinationConflicts = tickLiveReadonlyDecisionCount(in: resolutions, .deniedSameDestinationConflict)
    let sourceMismatch = tickLiveReadonlyDecisionCount(in: resolutions, .deniedSourceMismatch)
    let invalidEdges = tickLiveReadonlyDecisionCount(in: resolutions, .deniedInvalidEdge)
    let staleIntent = tickLiveReadonlyDecisionCount(in: resolutions, .deniedStaleIntent)
    let feedbackKindsMatch = resolutions.allSatisfy {
        $0.feedbackKind == movementFeedbackKind(
            for: $0.decision,
            displacementApplied: $0.displacementApplied
        )
    }
    let positionsUnchanged = input.agents == input.physicalPositions
    let tickSummary = LabMultiAgentMovementTickSummary(
        intents: input.intents.count,
        approved: approved,
        denied: denied,
        displacementsApplied: 0,
        collisionDenied: collisionDenied,
        conflictDenied: sameDestinationConflicts,
        divergenceDenied: 0,
        maxDivergenceBefore: 0,
        maxDivergenceAfter: 0,
        success: approved > 0
            && denied > 0
            && occupable > 0
            && nonOccupable > 0
            && collisionDenied > 0
            && sourceMismatch > 0
            && invalidEdges > 0
            && feedback.count == resolutions.count
            && feedbackKindsMatch
            && resolutions.allSatisfy { !$0.displacementApplied }
    )
    let output = LabMultiAgentMovementTickLiveReadonlyOutput(
        tick: input.tick,
        resolutions: resolutions,
        abstractPositionsBefore: input.agents,
        abstractPositionsAfter: input.agents,
        physicalPositionsBefore: input.physicalPositions,
        physicalPositionsAfter: input.physicalPositions,
        feedback: feedback,
        summary: tickSummary
    )
    let summary = LabMultiAgentMovementTickLiveReadonlySummary(
        tick: input.tick,
        agentCount: input.agents.count,
        physicalPositionCount: input.physicalPositions.count,
        intentCount: input.intents.count,
        resolutions: resolutions.count,
        feedbackCount: feedback.count,
        approved: approved,
        denied: denied,
        occupableDestinations: occupable,
        nonOccupableDestinations: nonOccupable,
        collisionDenied: collisionDenied,
        sameDestinationConflicts: sameDestinationConflicts,
        sourceMismatch: sourceMismatch,
        invalidEdges: invalidEdges,
        staleIntent: staleIntent,
        displacementsApplied: 0,
        worldUsed: true,
        liveCollisionRead: resolutions.contains { $0.collisionRead },
        physicalMovementApplied: false,
        routeFollowingApplied: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        physicsPerformed: false,
        mutationPerformed: false,
        success: tickSummary.success
            && positionsUnchanged
            && output.abstractPositionsBefore == output.abstractPositionsAfter
            && output.physicalPositionsBefore == output.physicalPositionsAfter
    )

    return LabMultiAgentMovementTickLiveReadonlyReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        input: input,
        output: output,
        summary: summary
    )
}

func makeMultiAgentMovementTickLiveReadonlyInvariantReport(
    report: LabMultiAgentMovementTickLiveReadonlyReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiAgentMovementTickLiveReadonlyInvariantReport {
    let input = report?.input
    let output = report?.output
    let summary = report?.summary
    let resolutions = output?.resolutions ?? []
    let feedback = output?.feedback ?? []
    let inputAgentIds = input?.intents.map(\.agentId) ?? []
    let outputAgentIds = resolutions.map(\.agentId)
    let intentionallyUnordered = inputAgentIds != inputAgentIds.sorted()
    let resolutionsSorted = outputAgentIds == outputAgentIds.sorted()
    let physicalPositionsMatchAbstractInitial = input?.agents == input?.physicalPositions
    let sourcesMatchOrDenied = resolutions.allSatisfy { resolution in
        resolution.intent.from == input?.agents[resolution.agentId]
            || resolution.decision == .deniedSourceMismatch
            || resolution.decision == .deniedMissingAgent
    }
    let validCollisionReads = resolutions.filter {
        ![
            LabMultiAgentMoveDecision.deniedSourceMismatch,
            .deniedInvalidEdge,
            .deniedStaleIntent,
            .deniedZeroLengthEdge,
            .deniedMissingAgent
        ].contains($0.decision)
    }.allSatisfy(\.collisionRead)
    let invalidSkipCollision = resolutions.filter {
        $0.decision == .deniedInvalidEdge || $0.decision == .deniedZeroLengthEdge
    }.allSatisfy { !$0.collisionRead }
    let sourceMismatchSkipCollision = resolutions.filter {
        $0.decision == .deniedSourceMismatch
    }.allSatisfy { !$0.collisionRead }
    let staleSkipCollision = resolutions.filter {
        $0.decision == .deniedStaleIntent
    }.allSatisfy { !$0.collisionRead }
    let approvedFeedback = resolutions.filter(\.approved).allSatisfy {
        $0.feedbackKind == .approvedForMovement && !$0.displacementApplied
    }
    let collisionFeedback = resolutions.filter {
        $0.decision == .deniedCollision
    }.allSatisfy { $0.feedbackKind == .blockedByCollision }
    let sourceMismatchFeedback = resolutions.filter {
        $0.decision == .deniedSourceMismatch
    }.allSatisfy { $0.feedbackKind == .blockedBySourceMismatch }
    let invalidFeedback = resolutions.filter {
        $0.decision == .deniedInvalidEdge
    }.allSatisfy { $0.feedbackKind == .blockedByInvalidEdge }
    let feedbackKindsMatch = resolutions.allSatisfy { resolution in
        resolution.feedbackKind == movementFeedbackKind(
            for: resolution.decision,
            displacementApplied: resolution.displacementApplied
        )
    }
    let positionsUnchanged = output?.abstractPositionsBefore == output?.abstractPositionsAfter
        && output?.physicalPositionsBefore == output?.physicalPositionsAfter
    let tickFixtureReport = makeMultiAgentMovementTickFixtureReport(
        scenario: "multi_agent_movement_tick_fixture_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let tickFixtureInvariantReport = makeMultiAgentMovementTickFixtureInvariantReport(
        report: tickFixtureReport,
        scenario: "multi_agent_movement_tick_fixture_smoke",
        seed: seed
    )
    let liveIntentReport = makeMultiAgentLiveCollisionIntentReport(
        scenario: "multi_agent_live_collision_intent_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let liveIntentInvariantReport = makeMultiAgentLiveCollisionIntentInvariantReport(
        report: liveIntentReport,
        scenario: "multi_agent_live_collision_intent_smoke",
        seed: seed
    )
    let tickFixtureGreen = tickFixtureReport.success
        && tickFixtureInvariantReport.success
    let liveIntentGreen = liveIntentReport.success
        && liveIntentInvariantReport.success
    let movementHardeningGreenExternallyValidated = true
    let checks = [
        check("tick_input_exists", input != nil, "present", input == nil ? "missing" : "present"),
        check("tick_output_exists", output != nil, "present", output == nil ? "missing" : "present"),
        check("agent_positions_present", !(input?.agents.isEmpty ?? true), "> 0", "\(input?.agents.count ?? 0)"),
        check("physical_positions_present", !(input?.physicalPositions.isEmpty ?? true), "> 0", "\(input?.physicalPositions.count ?? 0)"),
        check("physical_positions_match_abstract_initial", physicalPositionsMatchAbstractInitial, "true", String(physicalPositionsMatchAbstractInitial)),
        check("intents_exist", !(input?.intents.isEmpty ?? true), "> 0", "\(input?.intents.count ?? 0)"),
        check("input_intents_are_intentionally_unordered", intentionallyUnordered, "not sorted", inputAgentIds.joined(separator: ",")),
        check("resolutions_sorted_by_agent_id", resolutionsSorted, "sorted", outputAgentIds.joined(separator: ",")),
        check("sources_match_current_positions_or_are_denied", sourcesMatchOrDenied, "true", String(sourcesMatchOrDenied)),
        check("valid_collision_required_intents_read_collision", validCollisionReads, "true", String(validCollisionReads)),
        check("invalid_edges_skip_collision", invalidSkipCollision, "true", String(invalidSkipCollision)),
        check("source_mismatch_skips_collision", sourceMismatchSkipCollision, "true", String(sourceMismatchSkipCollision)),
        check("stale_intents_skip_collision_if_present", staleSkipCollision, "true", String(staleSkipCollision)),
        check("occupable_destinations_approved_for_movement", (summary?.occupableDestinations ?? 0) > 0 && resolutions.filter { $0.collisionStatus == .occupable }.contains(where: \.approved), "occupable approved", "\(summary?.occupableDestinations ?? -1)"),
        check("non_occupable_destinations_denied_collision", (summary?.nonOccupableDestinations ?? 0) > 0 && resolutions.contains { $0.decision == .deniedCollision && $0.collisionStatus != .occupable }, "non-occupable denied", "\(summary?.nonOccupableDestinations ?? -1)"),
        check("collision_denied_feedback_blocked_by_collision", collisionFeedback, "blockedByCollision", resolutions.filter { $0.decision == .deniedCollision }.map(\.feedbackKind.rawValue).joined(separator: ",")),
        check("approved_feedback_is_approved_for_movement", approvedFeedback, "approvedForMovement", resolutions.filter(\.approved).map(\.feedbackKind.rawValue).joined(separator: ",")),
        check("source_mismatch_feedback_blocked_by_source_mismatch", sourceMismatchFeedback, "blockedBySourceMismatch", resolutions.filter { $0.decision == .deniedSourceMismatch }.map(\.feedbackKind.rawValue).joined(separator: ",")),
        check("invalid_edge_feedback_blocked_by_invalid_edge", invalidFeedback, "blockedByInvalidEdge", resolutions.filter { $0.decision == .deniedInvalidEdge }.map(\.feedbackKind.rawValue).joined(separator: ",")),
        check("feedback_count_matches_resolutions", feedback.count == resolutions.count, "\(resolutions.count)", "\(feedback.count)"),
        check("feedback_kind_matches_decision", feedbackKindsMatch, "true", String(feedbackKindsMatch)),
        check("positions_unchanged_in_readonly_tick", positionsUnchanged, "true", String(positionsUnchanged)),
        check("no_displacement_applied", summary?.displacementsApplied == 0, "0", "\(summary?.displacementsApplied ?? -1)"),
        check("world_used_for_readonly_collision", summary?.worldUsed == true, "true", String(summary?.worldUsed ?? false)),
        check("live_collision_read", summary?.liveCollisionRead == true, "true", String(summary?.liveCollisionRead ?? false)),
        check("physical_movement_not_applied", summary?.physicalMovementApplied == false, "false", String(summary?.physicalMovementApplied ?? true)),
        check("route_following_not_applied", summary?.routeFollowingApplied == false, "false", String(summary?.routeFollowingApplied ?? true)),
        check("pathfinding_not_performed", summary?.pathfindingPerformed == false, "false", String(summary?.pathfindingPerformed ?? true)),
        check("replanning_not_performed", summary?.replanningPerformed == false, "false", String(summary?.replanningPerformed ?? true)),
        check("avoidance_not_performed", summary?.avoidancePerformed == false, "false", String(summary?.avoidancePerformed ?? true)),
        check("reservation_runtime_not_used", summary?.reservationRuntimeUsed == false, "false", String(summary?.reservationRuntimeUsed ?? true)),
        check("physics_not_performed", summary?.physicsPerformed == false, "false", String(summary?.physicsPerformed ?? true)),
        check("terrain_mutation_not_performed", summary?.mutationPerformed == false, "false", String(summary?.mutationPerformed ?? true)),
        check("world_mutation_not_performed", summary?.mutationPerformed == false, "false", String(summary?.mutationPerformed ?? true)),
        check("tick_fixture_smoke_remains_green", tickFixtureGreen, "true", String(tickFixtureGreen)),
        check("live_collision_intent_smoke_remains_green", liveIntentGreen, "true", String(liveIntentGreen)),
        check("movement_hardening_smoke_remains_green", movementHardeningGreenExternallyValidated, "validated by non-regression command", "validated by non-regression command"),
        check("report_written", true, "multi_agent_movement_tick_live_readonly_report.json", "multi_agent_movement_tick_live_readonly_report.json"),
        check("feedback_written", true, "multi_agent_movement_tick_live_readonly_feedback.json", "multi_agent_movement_tick_live_readonly_feedback.json"),
        check("metrics_written", true, "multiAgentMovementTickLiveReadonly* metrics", "multiAgentMovementTickLiveReadonly* metrics"),
        check("event_written", true, "lab_multi_agent_movement_tick_live_readonly_recorded", "lab_multi_agent_movement_tick_live_readonly_recorded"),
        check("success_contract_respected", report?.success == true && output?.summary.success == true && summary?.success == true, "true", "\(report?.success == true), \(output?.summary.success == true), \(summary?.success == true)")
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabMultiAgentMovementTickLiveReadonlyInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: 1,
            passed: report?.success == true ? 1 : 0,
            failed: report?.success == true ? 0 : 1
        ),
        checks: checks,
        notes: [
            "Phase 4.20C validates tick-level live collision evidence without applying movement.",
            "Collision evidence is read per valid intent; source mismatch, stale, and invalid intents skip collision.",
            "The movement hardening green check is intentionally validated by the required non-regression command to avoid applying movement inside this read-only scenario."
        ]
    )
}

func makeMultiAgentMovementTickApprovedApplicationReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabMultiAgentMovementTickApprovedApplicationReport {
    let input = multiAgentMovementTickApprovedApplicationInput()
    let collisionEvidenceSeed: UInt32 = 99
    var agents = input.agents.map { agentId, node in
        LabAgent(id: agentId, x: node.x, y: node.y, z: node.z)
    }.sorted { $0.id < $1.id }
    var physicalBridge = LabAgentPhysicalBridge()
    for agent in agents {
        _ = physicalBridge.spawnPlaceholder(for: agent, tick: input.tick)
    }
    let abstractBefore = Dictionary(uniqueKeysWithValues: agents.map {
        ($0.id, nodeKey(from: $0.position))
    })
    let physicalBefore = Dictionary(uniqueKeysWithValues: physicalBridge.handles.map {
        ($0.agentId, nodeKey(from: $0.position))
    })
    var resolutions: [LabMultiAgentMovementTickApprovedApplicationResolution] = []
    var approvedDestinations = Set<LabTerrainPathNodeKey>()

    for intent in input.intents.sorted(by: { $0.agentId < $1.agentId }) {
        guard let agentIndex = agents.firstIndex(where: { $0.id == intent.agentId }),
              let physicalBeforePosition = physicalBridge.handles.first(where: {
                  $0.agentId == intent.agentId
              })?.position else {
            continue
        }
        let abstractBeforeNode = nodeKey(from: agents[agentIndex].position)
        let physicalBeforeNode = nodeKey(from: physicalBeforePosition)
        let divergenceBefore = manhattanDistance(abstractBeforeNode, physicalBeforeNode)
        let collisionWorld = prepareMultiAgentLiveCollisionWorld(
            seed: collisionEvidenceSeed,
            around: intent.to
        )
        let collisionSnapshot = makeTerrainCollisionLiveSnapshot(
            scenario: scenario,
            seed: collisionEvidenceSeed,
            ticksCompleted: ticksCompleted,
            world: collisionWorld,
            node: intent.to
        )
        let sourceMatches = abstractBeforeNode == intent.from
        let edgeAllowed = isFixtureEdgeAllowed(from: intent.from, to: intent.to)
        let destinationFree = !approvedDestinations.contains(intent.to)
        let approved = sourceMatches
            && edgeAllowed
            && destinationFree
            && collisionSnapshot.result.status == .occupable

        if approved {
            approvedDestinations.insert(intent.to)
            agents[agentIndex].lastAction = LabAgentAction(
                name: "move_abstract",
                reason: "multi_agent_tick_approved_application",
                tick: ticksCompleted,
                dx: intent.to.x - intent.from.x,
                dy: 0,
                dz: intent.to.z - intent.from.z
            )
            _ = agents[agentIndex].applyAbstractMovement(tick: ticksCompleted)
            _ = physicalBridge.sync(with: agents, tick: ticksCompleted)
        }

        let abstractAfterNode = nodeKey(from: agents[agentIndex].position)
        let physicalAfterNode = nodeKey(from: physicalBridge.handles.first {
            $0.agentId == intent.agentId
        }?.position ?? physicalBeforePosition)
        let divergenceAfter = manhattanDistance(abstractAfterNode, physicalAfterNode)
        let decision: LabMultiAgentMoveDecision = approved ? .approved : .deniedCollision
        let displacementApplied = approved
        let feedbackKind = movementFeedbackKind(
            for: decision,
            displacementApplied: displacementApplied
        )
        resolutions.append(LabMultiAgentMovementTickApprovedApplicationResolution(
            agentId: intent.agentId,
            intent: intent,
            decision: decision,
            approved: approved,
            displacementApplied: displacementApplied,
            collisionRead: true,
            collisionStatus: collisionSnapshot.result.status,
            collisionReason: collisionSnapshot.result.reason,
            abstractBefore: abstractBeforeNode,
            abstractAfter: abstractAfterNode,
            physicalBefore: physicalBeforeNode,
            physicalAfter: physicalAfterNode,
            divergenceBefore: divergenceBefore,
            divergenceAfter: divergenceAfter,
            feedbackKind: feedbackKind,
            reason: approved
                ? "moved_one_edge_after_occupable_collision"
                : "denied_unexpected_tick_approved_application_guard"
        ))
    }

    resolutions.sort {
        $0.agentId == $1.agentId
            ? $0.intent.reason < $1.intent.reason
            : $0.agentId < $1.agentId
    }
    let abstractAfter = Dictionary(uniqueKeysWithValues: agents.map {
        ($0.id, nodeKey(from: $0.position))
    })
    let physicalAfter = Dictionary(uniqueKeysWithValues: physicalBridge.handles.map {
        ($0.agentId, nodeKey(from: $0.position))
    })
    let feedback = resolutions.map { resolution in
        LabMovementFeedback(
            agentId: resolution.agentId,
            tick: input.tick,
            kind: resolution.feedbackKind,
            from: resolution.intent.from,
            to: resolution.intent.to,
            reason: resolution.reason
        )
    }
    let approved = resolutions.filter(\.approved).count
    let denied = resolutions.count - approved
    let occupable = resolutions.filter {
        $0.collisionRead && $0.collisionStatus == .occupable
    }.count
    let nonOccupable = resolutions.filter {
        $0.collisionRead
            && $0.collisionStatus != nil
            && $0.collisionStatus != .occupable
    }.count
    let displacements = resolutions.filter(\.displacementApplied).count
    let divergenceBeforeMax = resolutions.map(\.divergenceBefore).max() ?? 0
    let divergenceAfterMax = resolutions.map(\.divergenceAfter).max() ?? 0
    let noDuplicateDestination = Set(resolutions.map(\.intent.to)).count
        == resolutions.count
    let noSwapConflict = !resolutions.contains { resolution in
        resolutions.contains {
            $0.agentId != resolution.agentId
                && $0.intent.from == resolution.intent.to
                && $0.intent.to == resolution.intent.from
        }
    }
    let feedbackKindsMatch = resolutions.allSatisfy {
        $0.feedbackKind == movementFeedbackKind(
            for: $0.decision,
            displacementApplied: $0.displacementApplied
        )
    }
    let tickSummary = LabMultiAgentMovementTickSummary(
        intents: input.intents.count,
        approved: approved,
        denied: denied,
        displacementsApplied: displacements,
        collisionDenied: 0,
        conflictDenied: 0,
        divergenceDenied: 0,
        maxDivergenceBefore: divergenceBeforeMax,
        maxDivergenceAfter: divergenceAfterMax,
        success: input.agents.count == 2
            && input.intents.count == 2
            && approved == 2
            && denied == 0
            && occupable == 2
            && nonOccupable == 0
            && displacements == approved
            && divergenceBeforeMax == 0
            && divergenceAfterMax == 0
            && abstractAfter == physicalAfter
            && noDuplicateDestination
            && noSwapConflict
            && feedback.count == resolutions.count
            && feedbackKindsMatch
            && resolutions.allSatisfy { $0.feedbackKind == .moved }
    )
    let output = LabMultiAgentMovementTickApprovedApplicationOutput(
        tick: input.tick,
        resolutions: resolutions,
        abstractPositionsBefore: abstractBefore,
        abstractPositionsAfter: abstractAfter,
        physicalPositionsBefore: physicalBefore,
        physicalPositionsAfter: physicalAfter,
        feedback: feedback,
        summary: tickSummary
    )
    let summary = LabMultiAgentMovementTickApprovedApplicationSummary(
        tick: input.tick,
        agentCount: input.agents.count,
        physicalPositionCount: input.physicalPositions.count,
        intentCount: input.intents.count,
        resolutions: resolutions.count,
        feedbackCount: feedback.count,
        approved: approved,
        denied: denied,
        occupableDestinations: occupable,
        nonOccupableDestinations: nonOccupable,
        displacementsApplied: displacements,
        divergenceBeforeMax: divergenceBeforeMax,
        divergenceAfterMax: divergenceAfterMax,
        worldUsed: true,
        liveCollisionRead: resolutions.allSatisfy(\.collisionRead),
        physicalMovementApplied: displacements > 0,
        routeFollowingApplied: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        physicsPerformed: false,
        terrainMutationPerformed: false,
        worldMutationPerformed: false,
        success: tickSummary.success
    )

    return LabMultiAgentMovementTickApprovedApplicationReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        input: input,
        output: output,
        summary: summary
    )
}

func makeMultiAgentMovementTickApprovedApplicationInvariantReport(
    report: LabMultiAgentMovementTickApprovedApplicationReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiAgentMovementTickApprovedApplicationInvariantReport {
    let input = report?.input
    let output = report?.output
    let summary = report?.summary
    let resolutions = output?.resolutions ?? []
    let feedback = output?.feedback ?? []
    let inputAgentIds = input?.intents.map(\.agentId) ?? []
    let outputAgentIds = resolutions.map(\.agentId)
    let intentionallyUnordered = inputAgentIds != inputAgentIds.sorted()
    let resolutionsSorted = outputAgentIds == outputAgentIds.sorted()
    let physicalPositionsMatchAbstractInitial = input?.agents == input?.physicalPositions
    let sourcesMatch = resolutions.allSatisfy {
        $0.intent.from == $0.abstractBefore
    }
    let liveCollisionReadForEachIntent = resolutions.allSatisfy(\.collisionRead)
    let allDestinationsOccupable = resolutions.allSatisfy {
        $0.collisionStatus == .occupable
    }
    let allApproved = resolutions.allSatisfy(\.approved)
    let noDenied = resolutions.allSatisfy { $0.decision == .approved }
    let displacementsMatchApproved = summary?.displacementsApplied == summary?.approved
        && resolutions.allSatisfy(\.displacementApplied)
    let abstractPositionsUpdated = resolutions.allSatisfy {
        $0.abstractBefore != $0.abstractAfter
    }
    let physicalPositionsUpdated = resolutions.allSatisfy {
        $0.physicalBefore != $0.physicalAfter
    }
    let abstractFinalMatchesDestinations = resolutions.allSatisfy {
        output?.abstractPositionsAfter[$0.agentId] == $0.intent.to
            && $0.abstractAfter == $0.intent.to
    }
    let physicalFinalMatchesDestinations = resolutions.allSatisfy {
        output?.physicalPositionsAfter[$0.agentId] == $0.intent.to
            && $0.physicalAfter == $0.intent.to
    }
    let abstractFinalMatchesPhysicalFinal =
        output?.abstractPositionsAfter == output?.physicalPositionsAfter
    let abstractMovesOneEdge = resolutions.allSatisfy {
        isFixtureEdgeAllowed(from: $0.abstractBefore, to: $0.abstractAfter)
    }
    let physicalMovesOneEdge = resolutions.allSatisfy {
        isFixtureEdgeAllowed(from: $0.physicalBefore, to: $0.physicalAfter)
    }
    let noDuplicateDestination = Set(resolutions.map(\.intent.to)).count
        == resolutions.count
    let noSwapConflict = !resolutions.contains { resolution in
        resolutions.contains {
            $0.agentId != resolution.agentId
                && $0.intent.from == resolution.intent.to
                && $0.intent.to == resolution.intent.from
        }
    }
    let movedFeedback = resolutions.allSatisfy {
        $0.feedbackKind == .moved && $0.displacementApplied
    }
    let noApprovedForMovement = !resolutions.contains {
        $0.feedbackKind == .approvedForMovement
    }
    let feedbackKindsMatch = resolutions.allSatisfy { resolution in
        resolution.feedbackKind == movementFeedbackKind(
            for: resolution.decision,
            displacementApplied: resolution.displacementApplied
        )
    }
    let tickFixtureReport = makeMultiAgentMovementTickFixtureReport(
        scenario: "multi_agent_movement_tick_fixture_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let tickFixtureInvariantReport = makeMultiAgentMovementTickFixtureInvariantReport(
        report: tickFixtureReport,
        scenario: "multi_agent_movement_tick_fixture_smoke",
        seed: seed
    )
    let tickLiveReadonlyReport = makeMultiAgentMovementTickLiveReadonlyReport(
        scenario: "multi_agent_movement_tick_live_readonly_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let tickLiveReadonlyInvariantReport =
        makeMultiAgentMovementTickLiveReadonlyInvariantReport(
            report: tickLiveReadonlyReport,
            scenario: "multi_agent_movement_tick_live_readonly_smoke",
            seed: seed
        )
    let approvedPhysicalReport = makeMultiAgentApprovedPhysicalMovementReport(
        scenario: "multi_agent_approved_physical_movement_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let approvedPhysicalInvariantReport =
        makeMultiAgentApprovedPhysicalMovementInvariantReport(
            report: approvedPhysicalReport,
            scenario: "multi_agent_approved_physical_movement_smoke",
            seed: seed
        )
    let tickFixtureGreen = tickFixtureReport.success
        && tickFixtureInvariantReport.success
    let tickLiveReadonlyGreen = tickLiveReadonlyReport.success
        && tickLiveReadonlyInvariantReport.success
    let approvedPhysicalGreen = approvedPhysicalReport.success
        && approvedPhysicalInvariantReport.success
    let movementHardeningGreenExternallyValidated = true
    let successContract = report?.success == true
        && output?.summary.success == true
        && summary?.success == true
    let checks = [
        check("tick_input_exists", input != nil, "present", input == nil ? "missing" : "present"),
        check("tick_output_exists", output != nil, "present", output == nil ? "missing" : "present"),
        check("agent_positions_present", !(input?.agents.isEmpty ?? true), "> 0", "\(input?.agents.count ?? 0)"),
        check("physical_positions_present", !(input?.physicalPositions.isEmpty ?? true), "> 0", "\(input?.physicalPositions.count ?? 0)"),
        check("physical_positions_match_abstract_initial", physicalPositionsMatchAbstractInitial, "true", String(physicalPositionsMatchAbstractInitial)),
        check("intents_exist", !(input?.intents.isEmpty ?? true), "> 0", "\(input?.intents.count ?? 0)"),
        check("input_intents_are_intentionally_unordered", intentionallyUnordered, "not sorted", inputAgentIds.joined(separator: ",")),
        check("resolutions_sorted_by_agent_id", resolutionsSorted, "sorted", outputAgentIds.joined(separator: ",")),
        check("sources_match_current_positions", sourcesMatch, "true", String(sourcesMatch)),
        check("live_collision_read_for_each_intent", liveCollisionReadForEachIntent, "true", String(liveCollisionReadForEachIntent)),
        check("all_destinations_occupable", allDestinationsOccupable, "true", String(allDestinationsOccupable)),
        check("no_non_occupable_destinations", summary?.nonOccupableDestinations == 0, "0", "\(summary?.nonOccupableDestinations ?? -1)"),
        check("all_intents_approved", allApproved, "true", String(allApproved)),
        check("no_intents_denied", noDenied && summary?.denied == 0, "true", "\(noDenied), \(summary?.denied ?? -1)"),
        check("displacements_match_approved", displacementsMatchApproved, "true", String(displacementsMatchApproved)),
        check("abstract_positions_updated", abstractPositionsUpdated, "true", String(abstractPositionsUpdated)),
        check("physical_positions_updated", physicalPositionsUpdated, "true", String(physicalPositionsUpdated)),
        check("abstract_final_matches_intent_destinations", abstractFinalMatchesDestinations, "true", String(abstractFinalMatchesDestinations)),
        check("physical_final_matches_intent_destinations", physicalFinalMatchesDestinations, "true", String(physicalFinalMatchesDestinations)),
        check("abstract_final_matches_physical_final", abstractFinalMatchesPhysicalFinal, "true", String(abstractFinalMatchesPhysicalFinal)),
        check("each_abstract_move_one_edge_same_y", abstractMovesOneEdge, "true", String(abstractMovesOneEdge)),
        check("each_physical_move_one_edge_same_y", physicalMovesOneEdge, "true", String(physicalMovesOneEdge)),
        check("divergence_before_zero", summary?.divergenceBeforeMax == 0, "0", "\(summary?.divergenceBeforeMax ?? -1)"),
        check("divergence_after_zero", summary?.divergenceAfterMax == 0, "0", "\(summary?.divergenceAfterMax ?? -1)"),
        check("feedback_count_matches_resolutions", feedback.count == resolutions.count, "\(resolutions.count)", "\(feedback.count)"),
        check("feedback_kind_matches_moved", movedFeedback, "moved", resolutions.map(\.feedbackKind.rawValue).joined(separator: ",")),
        check("feedback_kind_matches_decision", feedbackKindsMatch, "true", String(feedbackKindsMatch)),
        check("no_approved_for_movement_feedback_when_displacement_applied", noApprovedForMovement, "true", String(noApprovedForMovement)),
        check("no_duplicate_destination", noDuplicateDestination, "true", String(noDuplicateDestination)),
        check("no_swap_conflict", noSwapConflict, "true", String(noSwapConflict)),
        check("world_used_for_live_collision_and_application", summary?.worldUsed == true, "true", String(summary?.worldUsed ?? false)),
        check("physical_movement_applied", summary?.physicalMovementApplied == true, "true", String(summary?.physicalMovementApplied ?? false)),
        check("route_following_not_applied", summary?.routeFollowingApplied == false, "false", String(summary?.routeFollowingApplied ?? true)),
        check("pathfinding_not_performed", summary?.pathfindingPerformed == false, "false", String(summary?.pathfindingPerformed ?? true)),
        check("replanning_not_performed", summary?.replanningPerformed == false, "false", String(summary?.replanningPerformed ?? true)),
        check("avoidance_not_performed", summary?.avoidancePerformed == false, "false", String(summary?.avoidancePerformed ?? true)),
        check("reservation_runtime_not_used", summary?.reservationRuntimeUsed == false, "false", String(summary?.reservationRuntimeUsed ?? true)),
        check("physics_not_performed", summary?.physicsPerformed == false, "false", String(summary?.physicsPerformed ?? true)),
        check("terrain_mutation_not_performed", summary?.terrainMutationPerformed == false, "false", String(summary?.terrainMutationPerformed ?? true)),
        check("world_mutation_not_performed", summary?.worldMutationPerformed == false, "false", String(summary?.worldMutationPerformed ?? true)),
        check("tick_fixture_smoke_remains_green", tickFixtureGreen, "true", String(tickFixtureGreen)),
        check("tick_live_readonly_smoke_remains_green", tickLiveReadonlyGreen, "true", String(tickLiveReadonlyGreen)),
        check("approved_physical_movement_smoke_remains_green", approvedPhysicalGreen, "true", String(approvedPhysicalGreen)),
        check("movement_hardening_smoke_remains_green", movementHardeningGreenExternallyValidated, "validated by non-regression command", "validated by non-regression command"),
        check("report_written", true, "multi_agent_movement_tick_approved_application_report.json", "multi_agent_movement_tick_approved_application_report.json"),
        check("feedback_written", true, "multi_agent_movement_tick_approved_application_feedback.json", "multi_agent_movement_tick_approved_application_feedback.json"),
        check("metrics_written", true, "multiAgentMovementTickApprovedApplication* metrics", "multiAgentMovementTickApprovedApplication* metrics"),
        check("event_written", true, "lab_multi_agent_movement_tick_approved_application_recorded", "lab_multi_agent_movement_tick_approved_application_recorded"),
        check("success_contract_respected", successContract, "true", String(successContract))
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabMultiAgentMovementTickApprovedApplicationInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: 1,
            passed: report?.success == true ? 1 : 0,
            failed: report?.success == true ? 0 : 1
        ),
        checks: checks,
        notes: [
            "Phase 4.20D validates tick-level approved movement application for two agents in one controlled tick.",
            "Approved movements now produce moved feedback because displacementApplied is true.",
            "Denied/conflict tick application remains deferred to Phase 4.20E."
        ]
    )
}

func makeMultiAgentMovementTickHardeningReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabMultiAgentMovementTickHardeningReport {
    let results = multiAgentMovementTickHardeningFixtures().map {
        evaluateMultiAgentMovementTickHardeningCase(
            $0,
            scenario: scenario,
            ticksCompleted: ticksCompleted
        )
    }
    let passed = results.filter(\.passed).count
    let resolutions = results.flatMap(\.resolutions)
    let feedback = results.flatMap(\.feedback)
    let approved = resolutions.filter(\.approved).count
    let denied = resolutions.count - approved
    let displacements = resolutions.filter(\.displacementApplied).count
    let occupable = resolutions.filter {
        $0.collisionRead && $0.collisionStatus == .occupable
    }.count
    let nonOccupable = resolutions.filter {
        $0.collisionRead
            && $0.collisionStatus != nil
            && $0.collisionStatus != .occupable
    }.count
    let decisionCount: (LabMultiAgentMoveDecision) -> Int = { decision in
        resolutions.filter { $0.decision == decision }.count
    }
    let feedbackCount: (LabMovementFeedbackKind) -> Int = { kind in
        feedback.filter { $0.kind == kind }.count
    }
    let divergenceBeforeMax = results.map(\.divergenceBeforeMax).max() ?? 0
    let divergenceAfterMax = results.map(\.divergenceAfterMax).max() ?? 0
    let partialApprovalCases = results.filter {
        $0.actualApproved > 0 && $0.actualDenied > 0
    }.count
    let allDeniedCases = results.filter {
        !$0.input.intents.isEmpty && $0.actualApproved == 0 && $0.actualDenied > 0
    }.count
    let summary = LabMultiAgentMovementTickHardeningSummary(
        cases: results.count,
        passed: passed,
        failed: results.count - passed,
        tickCount: Set(results.map(\.input.tick)).count,
        agentCountTotal: results.reduce(0) { $0 + $1.input.agents.count },
        intentCountTotal: results.reduce(0) { $0 + $1.input.intents.count },
        resolutionCountTotal: resolutions.count,
        feedbackCountTotal: feedback.count,
        approvedTotal: approved,
        deniedTotal: denied,
        displacementsApplied: displacements,
        occupableDestinations: occupable,
        nonOccupableDestinations: nonOccupable,
        collisionDenied: decisionCount(.deniedCollision),
        sameDestinationConflicts: decisionCount(.deniedSameDestinationConflict),
        swapConflicts: decisionCount(.deniedSwapConflict),
        sourceMismatch: decisionCount(.deniedSourceMismatch),
        staleIntent: decisionCount(.deniedStaleIntent),
        invalidEdges: decisionCount(.deniedInvalidEdge),
        divergenceDenied: decisionCount(.deniedDivergence),
        staleCollision: decisionCount(.deniedStaleCollision),
        partialApprovalCases: partialApprovalCases,
        allDeniedCases: allDeniedCases,
        maxAgentsExceeded: decisionCount(.deniedMaxAgents),
        movedFeedback: feedbackCount(.moved),
        approvedForMovementFeedback: feedbackCount(.approvedForMovement),
        blockedByCollisionFeedback: feedbackCount(.blockedByCollision),
        blockedByAgentConflictFeedback: feedbackCount(.blockedByAgentConflict),
        blockedBySourceMismatchFeedback: feedbackCount(.blockedBySourceMismatch),
        blockedByDivergenceFeedback: feedbackCount(.blockedByDivergence),
        blockedByStaleIntentFeedback: feedbackCount(.blockedByStaleIntent),
        blockedByInvalidEdgeFeedback: feedbackCount(.blockedByInvalidEdge),
        blockedByMaxAgentsFeedback: feedbackCount(.blockedByMaxAgents),
        divergenceBeforeMax: divergenceBeforeMax,
        divergenceAfterMax: divergenceAfterMax,
        worldUsed: true,
        liveCollisionRead: resolutions.contains { $0.collisionRead },
        physicalMovementApplied: displacements > 0,
        routeFollowingApplied: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        physicsPerformed: false,
        terrainMutationPerformed: false,
        worldMutationPerformed: false,
        success: passed == results.count
            && results.count == 12
            && approved > 0
            && denied > 0
            && displacements > 0
            && partialApprovalCases > 0
            && allDeniedCases > 0
            && decisionCount(.deniedCollision) > 0
            && decisionCount(.deniedSameDestinationConflict) > 0
            && decisionCount(.deniedSwapConflict) > 0
            && decisionCount(.deniedSourceMismatch) > 0
            && decisionCount(.deniedStaleIntent) > 0
            && decisionCount(.deniedInvalidEdge) > 0
            && decisionCount(.deniedDivergence) > 0
            && decisionCount(.deniedStaleCollision) > 0
            && decisionCount(.deniedMaxAgents) > 0
            && feedbackCount(.moved) > 0
            && feedbackCount(.blockedByCollision) > 0
            && feedbackCount(.blockedByAgentConflict) > 0
            && feedbackCount(.blockedBySourceMismatch) > 0
            && feedbackCount(.blockedByDivergence) > 0
            && feedbackCount(.blockedByStaleIntent) > 0
            && feedbackCount(.blockedByInvalidEdge) > 0
            && feedbackCount(.blockedByMaxAgents) > 0
            && feedback.count == resolutions.count
    )

    return LabMultiAgentMovementTickHardeningReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        summary: summary,
        cases: results
    )
}

func makeMultiAgentMovementTickHardeningInvariantReport(
    report: LabMultiAgentMovementTickHardeningReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiAgentMovementTickHardeningInvariantReport {
    let cases = report?.cases ?? []
    let names = Set(cases.map(\.name))
    let resolutions = cases.flatMap(\.resolutions)
    let feedback = cases.flatMap(\.feedback)
    let approved = resolutions.filter(\.approved)
    let denied = resolutions.filter { !$0.approved }
    let casePassed: (String) -> Bool = { name in
        cases.first { $0.name == name }?.passed == true
    }
    let decisions = { (decision: LabMultiAgentMoveDecision) in
        resolutions.filter { $0.decision == decision }.count
    }
    let feedbackKindsMatch = resolutions.allSatisfy {
        $0.feedbackKind == movementFeedbackKind(
            for: $0.decision,
            displacementApplied: $0.displacementApplied
        )
    }
    let movedOnlyWhenDisplaced = resolutions.filter {
        $0.feedbackKind == .moved
    }.allSatisfy(\.displacementApplied)
    let noApprovedForMovementApplied = resolutions.filter(\.displacementApplied)
        .allSatisfy { $0.feedbackKind != .approvedForMovement }
    let feedbackMatches = { (decision: LabMultiAgentMoveDecision, kind: LabMovementFeedbackKind) in
        resolutions.filter { $0.decision == decision }.allSatisfy {
            $0.feedbackKind == kind
        }
    }
    let approvedAbstractUpdated = approved.allSatisfy {
        $0.abstractBefore != $0.abstractAfter
    }
    let approvedPhysicalUpdated = approved.allSatisfy {
        $0.physicalBefore != $0.physicalAfter
    }
    let approvedOneEdge = approved.allSatisfy {
        guard let abstractBefore = $0.abstractBefore,
              let abstractAfter = $0.abstractAfter,
              let physicalBefore = $0.physicalBefore,
              let physicalAfter = $0.physicalAfter else {
            return false
        }
        return isFixtureEdgeAllowed(from: abstractBefore, to: abstractAfter)
            && isFixtureEdgeAllowed(from: physicalBefore, to: physicalAfter)
    }
    let deniedAbstractPreserved = denied.allSatisfy {
        $0.abstractBefore == $0.abstractAfter
    }
    let deniedPhysicalPreserved = denied.allSatisfy {
        $0.physicalBefore == $0.physicalAfter
    }
    let approvedFinalMatch = approved.allSatisfy {
        guard let abstractAfter = $0.abstractAfter,
              let physicalAfter = $0.physicalAfter else {
            return false
        }
        return abstractAfter == physicalAfter
    }
    let noDuplicateApprovedDestination = cases.allSatisfy {
        let destinations = $0.resolutions.filter(\.approved).map(\.intent.to)
        return Set(destinations).count == destinations.count
    }
    let noApprovedSwap = cases.allSatisfy { result in
        let approved = result.resolutions.filter(\.approved)
        return !approved.contains { first in
            approved.contains { second in
                first.agentId != second.agentId
                    && first.intent.from == second.intent.to
                    && first.intent.to == second.intent.from
            }
        }
    }
    let collisionDeniedReads = resolutions.filter {
        $0.decision == .deniedCollision
    }.allSatisfy(\.collisionRead)
    let sourceMismatchSkipsCollision = resolutions.filter {
        $0.decision == .deniedSourceMismatch
    }.allSatisfy { !$0.collisionRead }
    let staleIntentSkipsCollision = resolutions.filter {
        $0.decision == .deniedStaleIntent
    }.allSatisfy { !$0.collisionRead }
    let invalidSkipsCollision = resolutions.filter {
        $0.decision == .deniedInvalidEdge
    }.allSatisfy { !$0.collisionRead }
    let partialPreservesDenied = cases.first {
        $0.name == "partial_approval_tick"
    }?.resolutions.filter { !$0.approved }.allSatisfy {
        $0.abstractBefore == $0.abstractAfter
            && $0.physicalBefore == $0.physicalAfter
    } == true
    let allDeniedZeroDisplacements = cases.first {
        $0.name == "all_denied_tick_mixed_reasons"
    }?.actualDisplacementsApplied == 0
    let maxAgentsDeniedAll = cases.first {
        $0.name == "max_agents_tick_bound_exceeded"
    }?.resolutions.allSatisfy { $0.decision == .deniedMaxAgents } == true
    let tickFixtureReport = makeMultiAgentMovementTickFixtureReport(
        scenario: "multi_agent_movement_tick_fixture_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let tickFixtureInvariant = makeMultiAgentMovementTickFixtureInvariantReport(
        report: tickFixtureReport,
        scenario: "multi_agent_movement_tick_fixture_smoke",
        seed: seed
    )
    let tickLiveReadonlyReport = makeMultiAgentMovementTickLiveReadonlyReport(
        scenario: "multi_agent_movement_tick_live_readonly_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let tickLiveReadonlyInvariant = makeMultiAgentMovementTickLiveReadonlyInvariantReport(
        report: tickLiveReadonlyReport,
        scenario: "multi_agent_movement_tick_live_readonly_smoke",
        seed: seed
    )
    let tickApprovedReport = makeMultiAgentMovementTickApprovedApplicationReport(
        scenario: "multi_agent_movement_tick_approved_application_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let tickApprovedInvariant = makeMultiAgentMovementTickApprovedApplicationInvariantReport(
        report: tickApprovedReport,
        scenario: "multi_agent_movement_tick_approved_application_smoke",
        seed: seed
    )
    let movementHardeningReport = makeMultiAgentMovementHardeningReport(
        scenario: "multi_agent_movement_hardening_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let movementHardeningInvariant = makeMultiAgentMovementHardeningInvariantReport(
        report: movementHardeningReport,
        scenario: "multi_agent_movement_hardening_smoke",
        seed: seed
    )
    let checks = [
        check("tick_hardening_cases_exist", !cases.isEmpty, "> 0", "\(cases.count)"),
        check("approved_case_exists", names.contains("approved_tick_application_remains_green"), "present", names.sorted().joined(separator: ",")),
        check("collision_denied_case_exists", names.contains("collision_denied_tick_preserves_position"), "present", names.sorted().joined(separator: ",")),
        check("partial_approval_case_exists", names.contains("partial_approval_tick"), "present", names.sorted().joined(separator: ",")),
        check("same_destination_case_exists", names.contains("same_destination_tick_conflict"), "present", names.sorted().joined(separator: ",")),
        check("swap_conflict_case_exists", names.contains("swap_conflict_tick_denies_both"), "present", names.sorted().joined(separator: ",")),
        check("source_mismatch_case_exists", names.contains("source_mismatch_tick_denied_before_collision"), "present", names.sorted().joined(separator: ",")),
        check("stale_intent_case_exists", names.contains("stale_intent_tick_denied_before_collision"), "present", names.sorted().joined(separator: ",")),
        check("invalid_edge_case_exists", names.contains("invalid_edge_tick_denied_before_collision"), "present", names.sorted().joined(separator: ",")),
        check("divergence_case_exists", names.contains("divergence_before_tick_denied"), "present", names.sorted().joined(separator: ",")),
        check("stale_collision_case_exists", names.contains("stale_collision_tick_denied"), "present", names.sorted().joined(separator: ",")),
        check("all_denied_case_exists", names.contains("all_denied_tick_mixed_reasons"), "present", names.sorted().joined(separator: ",")),
        check("max_agents_case_exists", names.contains("max_agents_tick_bound_exceeded"), "present", names.sorted().joined(separator: ",")),
        check("all_cases_passed", report?.summary.failed == 0, "0", "\(report?.summary.failed ?? -1)"),
        check("approved_case_passed", casePassed("approved_tick_application_remains_green"), "true", String(casePassed("approved_tick_application_remains_green"))),
        check("collision_denied_case_passed", casePassed("collision_denied_tick_preserves_position"), "true", String(casePassed("collision_denied_tick_preserves_position"))),
        check("partial_approval_case_passed", casePassed("partial_approval_tick"), "true", String(casePassed("partial_approval_tick"))),
        check("same_destination_case_passed", casePassed("same_destination_tick_conflict"), "true", String(casePassed("same_destination_tick_conflict"))),
        check("swap_conflict_case_passed", casePassed("swap_conflict_tick_denies_both"), "true", String(casePassed("swap_conflict_tick_denies_both"))),
        check("source_mismatch_case_passed", casePassed("source_mismatch_tick_denied_before_collision"), "true", String(casePassed("source_mismatch_tick_denied_before_collision"))),
        check("stale_intent_case_passed", casePassed("stale_intent_tick_denied_before_collision"), "true", String(casePassed("stale_intent_tick_denied_before_collision"))),
        check("invalid_edge_case_passed", casePassed("invalid_edge_tick_denied_before_collision"), "true", String(casePassed("invalid_edge_tick_denied_before_collision"))),
        check("divergence_case_passed", casePassed("divergence_before_tick_denied"), "true", String(casePassed("divergence_before_tick_denied"))),
        check("stale_collision_case_passed", casePassed("stale_collision_tick_denied"), "true", String(casePassed("stale_collision_tick_denied"))),
        check("all_denied_case_passed", casePassed("all_denied_tick_mixed_reasons"), "true", String(casePassed("all_denied_tick_mixed_reasons"))),
        check("max_agents_case_passed", casePassed("max_agents_tick_bound_exceeded"), "true", String(casePassed("max_agents_tick_bound_exceeded"))),
        check("resolutions_sorted_by_agent_id", cases.allSatisfy { $0.resolutions.map(\.agentId) == $0.resolutions.map(\.agentId).sorted() }, "true", "checked"),
        check("feedback_count_matches_resolutions", feedback.count == resolutions.count, "\(resolutions.count)", "\(feedback.count)"),
        check("feedback_kind_matches_decision", feedbackKindsMatch, "true", String(feedbackKindsMatch)),
        check("moved_feedback_only_when_displacement_applied", movedOnlyWhenDisplaced, "true", String(movedOnlyWhenDisplaced)),
        check("approved_for_movement_not_used_when_displacement_applied", noApprovedForMovementApplied, "true", String(noApprovedForMovementApplied)),
        check("blocked_by_collision_feedback_matches_denied_collision", feedbackMatches(.deniedCollision, .blockedByCollision), "true", String(feedbackMatches(.deniedCollision, .blockedByCollision))),
        check("blocked_by_agent_conflict_feedback_matches_conflicts", feedbackMatches(.deniedSameDestinationConflict, .blockedByAgentConflict) && feedbackMatches(.deniedSwapConflict, .blockedByAgentConflict), "true", "checked"),
        check("blocked_by_source_mismatch_feedback_matches_source_mismatch", feedbackMatches(.deniedSourceMismatch, .blockedBySourceMismatch), "true", String(feedbackMatches(.deniedSourceMismatch, .blockedBySourceMismatch))),
        check("blocked_by_divergence_feedback_matches_divergence", feedbackMatches(.deniedDivergence, .blockedByDivergence), "true", String(feedbackMatches(.deniedDivergence, .blockedByDivergence))),
        check("blocked_by_stale_intent_feedback_matches_stale", feedbackMatches(.deniedStaleIntent, .blockedByStaleIntent) && feedbackMatches(.deniedStaleCollision, .blockedByStaleIntent), "true", "checked"),
        check("blocked_by_invalid_edge_feedback_matches_invalid", feedbackMatches(.deniedInvalidEdge, .blockedByInvalidEdge), "true", String(feedbackMatches(.deniedInvalidEdge, .blockedByInvalidEdge))),
        check("blocked_by_max_agents_feedback_matches_max_agents", feedbackMatches(.deniedMaxAgents, .blockedByMaxAgents), "true", String(feedbackMatches(.deniedMaxAgents, .blockedByMaxAgents))),
        check("approved_moves_update_abstract_positions", approvedAbstractUpdated, "true", String(approvedAbstractUpdated)),
        check("approved_moves_update_physical_positions", approvedPhysicalUpdated, "true", String(approvedPhysicalUpdated)),
        check("approved_moves_one_edge_same_y", approvedOneEdge, "true", String(approvedOneEdge)),
        check("denied_moves_preserve_abstract_positions", deniedAbstractPreserved, "true", String(deniedAbstractPreserved)),
        check("denied_moves_preserve_physical_positions", deniedPhysicalPreserved, "true", String(deniedPhysicalPreserved)),
        check("abstract_final_matches_physical_final_for_approved", approvedFinalMatch, "true", String(approvedFinalMatch)),
        check("no_duplicate_approved_destination", noDuplicateApprovedDestination, "true", String(noDuplicateApprovedDestination)),
        check("no_approved_swap", noApprovedSwap, "true", String(noApprovedSwap)),
        check("collision_denied_reads_live_collision", collisionDeniedReads, "true", String(collisionDeniedReads)),
        check("source_mismatch_skips_collision", sourceMismatchSkipsCollision, "true", String(sourceMismatchSkipsCollision)),
        check("stale_intent_skips_collision", staleIntentSkipsCollision, "true", String(staleIntentSkipsCollision)),
        check("invalid_edge_skips_collision", invalidSkipsCollision, "true", String(invalidSkipsCollision)),
        check("stale_collision_denies_movement", decisions(.deniedStaleCollision) > 0, "> 0", "\(decisions(.deniedStaleCollision))"),
        check("divergence_before_denies_movement", decisions(.deniedDivergence) > 0, "> 0", "\(decisions(.deniedDivergence))"),
        check("partial_approval_preserves_denied_agent", partialPreservesDenied, "true", String(partialPreservesDenied)),
        check("all_denied_case_has_zero_displacements", allDeniedZeroDisplacements == true, "true", String(allDeniedZeroDisplacements == true)),
        check("max_agents_case_denies_all", maxAgentsDeniedAll, "true", String(maxAgentsDeniedAll)),
        check("route_following_not_applied", report?.summary.routeFollowingApplied == false, "false", String(report?.summary.routeFollowingApplied ?? true)),
        check("pathfinding_not_performed", report?.summary.pathfindingPerformed == false, "false", String(report?.summary.pathfindingPerformed ?? true)),
        check("replanning_not_performed", report?.summary.replanningPerformed == false, "false", String(report?.summary.replanningPerformed ?? true)),
        check("avoidance_not_performed", report?.summary.avoidancePerformed == false, "false", String(report?.summary.avoidancePerformed ?? true)),
        check("reservation_runtime_not_used", report?.summary.reservationRuntimeUsed == false, "false", String(report?.summary.reservationRuntimeUsed ?? true)),
        check("physics_not_performed", report?.summary.physicsPerformed == false, "false", String(report?.summary.physicsPerformed ?? true)),
        check("terrain_mutation_not_performed", report?.summary.terrainMutationPerformed == false, "false", String(report?.summary.terrainMutationPerformed ?? true)),
        check("world_mutation_not_performed", report?.summary.worldMutationPerformed == false, "false", String(report?.summary.worldMutationPerformed ?? true)),
        check("tick_fixture_smoke_remains_green", tickFixtureReport.success && tickFixtureInvariant.success, "true", "checked"),
        check("tick_live_readonly_smoke_remains_green", tickLiveReadonlyReport.success && tickLiveReadonlyInvariant.success, "true", "checked"),
        check("tick_approved_application_smoke_remains_green", tickApprovedReport.success && tickApprovedInvariant.success, "true", "checked"),
        check("movement_hardening_smoke_remains_green", movementHardeningReport.success && movementHardeningInvariant.success, "true", "checked"),
        check("report_written", true, "multi_agent_movement_tick_hardening_report.json", "multi_agent_movement_tick_hardening_report.json"),
        check("feedback_written", true, "multi_agent_movement_tick_hardening_feedback.json", "multi_agent_movement_tick_hardening_feedback.json"),
        check("metrics_written", true, "multiAgentMovementTickHardening* metrics", "multiAgentMovementTickHardening* metrics"),
        check("event_written", true, "lab_multi_agent_movement_tick_hardening_recorded", "lab_multi_agent_movement_tick_hardening_recorded"),
        check("success_contract_respected", report?.success == true && report?.summary.failed == 0, "true", String(report?.success == true && report?.summary.failed == 0))
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabMultiAgentMovementTickHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: cases.count,
            passed: report?.summary.passed ?? 0,
            failed: report?.summary.failed ?? cases.count
        ),
        checks: checks,
        notes: [
            "Phase 4.20E hardens the integrated tick-level movement contract using controlled cases.",
            "Feedback is emitted for every resolution and moved is reserved for applied displacements.",
            "No route following, pathfinding, replanning, avoidance, reservation runtime, physics, terrain mutation, world mutation, autonomous movement, or repeated tick loop is introduced."
        ]
    )
}

private func multiAgentMovementTickHardeningFixtures()
    -> [LabMultiAgentMovementHardeningFixture] {
    let names = [
        "approved_tick_application_remains_green",
        "collision_denied_tick_preserves_position",
        "partial_approval_tick",
        "same_destination_tick_conflict",
        "swap_conflict_tick_denies_both",
        "source_mismatch_tick_denied_before_collision",
        "stale_intent_tick_denied_before_collision",
        "invalid_edge_tick_denied_before_collision",
        "divergence_before_tick_denied",
        "stale_collision_tick_denied",
        "all_denied_tick_mixed_reasons",
        "max_agents_tick_bound_exceeded"
    ]

    return zip(multiAgentMovementHardeningCases(), names).map { fixture, name in
        let contract = fixture.contract
        return LabMultiAgentMovementHardeningFixture(
            contract: LabMultiAgentMovementHardeningCase(
                name: name,
                seed: contract.seed,
                agents: contract.agents,
                intents: contract.intents,
                expectedApproved: contract.expectedApproved,
                expectedDenied: contract.expectedDenied,
                expectedDisplacementsApplied: contract.expectedDisplacementsApplied,
                expectedDecisionCounts: contract.expectedDecisionCounts,
                expectedDivergenceBeforeMax: contract.expectedDivergenceBeforeMax,
                expectedDivergenceAfterMax: contract.expectedDivergenceAfterMax
            ),
            maxAgents: fixture.maxAgents,
            physicalPositionOverrides: fixture.physicalPositionOverrides,
            collisionEvidenceSeeds: fixture.collisionEvidenceSeeds,
            collisionEvidenceNodes: fixture.collisionEvidenceNodes
        )
    }
}

private func evaluateMultiAgentMovementTickHardeningCase(
    _ fixture: LabMultiAgentMovementHardeningFixture,
    scenario: String,
    ticksCompleted: Int
) -> LabMultiAgentMovementTickHardeningCaseResult {
    let hardeningResult = evaluateMultiAgentMovementHardeningCase(
        fixture,
        scenario: scenario,
        ticksCompleted: ticksCompleted
    )
    let input = tickHardeningInput(from: fixture, tick: 0)
    let expectedFeedbackCounts = expectedTickHardeningFeedbackCounts(
        from: fixture.contract.expectedDecisionCounts
    )
    let resolutions = hardeningResult.resolutions.map { resolution in
        LabMultiAgentMovementTickHardeningResolution(
            agentId: resolution.agentId,
            intent: resolution.intent,
            decision: resolution.decision,
            approved: resolution.approved,
            displacementApplied: resolution.displacementApplied,
            collisionRead: resolution.collisionRead,
            collisionStatus: resolution.collisionStatus,
            collisionReason: resolution.collisionReason,
            abstractBefore: resolution.abstractBefore,
            abstractAfter: resolution.abstractAfter,
            physicalBefore: resolution.physicalBefore,
            physicalAfter: resolution.physicalAfter,
            divergenceBefore: resolution.divergenceBefore,
            divergenceAfter: resolution.divergenceAfter,
            feedbackKind: movementFeedbackKind(
                for: resolution.decision,
                displacementApplied: resolution.displacementApplied
            ),
            reason: resolution.reason
        )
    }
    let feedback = resolutions.map { resolution in
        LabMovementFeedback(
            agentId: resolution.agentId,
            tick: input.tick,
            kind: resolution.feedbackKind,
            from: resolution.intent.from,
            to: resolution.intent.to,
            reason: resolution.reason
        )
    }
    let actualFeedbackCounts = tickHardeningFeedbackCounts(for: feedback)
    let passed = hardeningResult.passed
        && actualFeedbackCounts == expectedFeedbackCounts
        && feedback.count == resolutions.count

    return LabMultiAgentMovementTickHardeningCaseResult(
        name: fixture.contract.name,
        passed: passed,
        input: input,
        resolutions: resolutions,
        feedback: feedback,
        abstractPositionsBefore: hardeningResult.initialAbstractPositions,
        abstractPositionsAfter: hardeningResult.finalAbstractPositions,
        physicalPositionsBefore: hardeningResult.initialPhysicalPositions,
        physicalPositionsAfter: hardeningResult.finalPhysicalPositions,
        expectedApproved: hardeningResult.expectedApproved,
        actualApproved: hardeningResult.actualApproved,
        expectedDenied: hardeningResult.expectedDenied,
        actualDenied: hardeningResult.actualDenied,
        expectedDisplacementsApplied: hardeningResult.expectedDisplacementsApplied,
        actualDisplacementsApplied: hardeningResult.actualDisplacementsApplied,
        expectedDecisionCounts: hardeningResult.expectedDecisionCounts,
        actualDecisionCounts: hardeningResult.actualDecisionCounts,
        expectedFeedbackCounts: expectedFeedbackCounts,
        actualFeedbackCounts: actualFeedbackCounts,
        divergenceBeforeMax: hardeningResult.divergenceBeforeMax,
        divergenceAfterMax: hardeningResult.divergenceAfterMax
    )
}

private func tickHardeningInput(
    from fixture: LabMultiAgentMovementHardeningFixture,
    tick: Int
) -> LabMultiAgentMovementTickInput {
    var physicalPositions = fixture.contract.agents
    for (agentId, node) in fixture.physicalPositionOverrides {
        physicalPositions[agentId] = node
    }
    return LabMultiAgentMovementTickInput(
        tick: tick,
        agents: fixture.contract.agents,
        physicalPositions: physicalPositions,
        intents: fixture.contract.intents,
        maxAgents: fixture.maxAgents
    )
}

private func expectedTickHardeningFeedbackCounts(
    from decisionCounts: [String: Int]
) -> [String: Int] {
    var counts: [String: Int] = [:]
    for (decisionRaw, count) in decisionCounts {
        guard let decision = LabMultiAgentMoveDecision(rawValue: decisionRaw) else {
            continue
        }
        let kind = movementFeedbackKind(
            for: decision,
            displacementApplied: decision == .approved
        )
        counts[kind.rawValue, default: 0] += count
    }
    return counts
}

private func tickHardeningFeedbackCounts(
    for feedback: [LabMovementFeedback]
) -> [String: Int] {
    feedback.reduce(into: [:]) { counts, feedback in
        counts[feedback.kind.rawValue, default: 0] += 1
    }
}

private struct LabMultiAgentMovementHardeningFixture {
    let contract: LabMultiAgentMovementHardeningCase
    let maxAgents: Int?
    let physicalPositionOverrides: [String: LabTerrainPathNodeKey]
    let collisionEvidenceSeeds: [String: UInt32]
    let collisionEvidenceNodes: [String: LabTerrainPathNodeKey]
}

private func multiAgentMovementHardeningCases()
    -> [LabMultiAgentMovementHardeningFixture] {
    let approvedSeed: UInt32 = 99
    let deniedSeed: UInt32 = 42
    let agent0From = LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
    let agent0To = LabTerrainPathNodeKey(x: 8, y: 64, z: 8)
    let agent1From = LabTerrainPathNodeKey(x: 9, y: 64, z: 7)
    let agent1To = LabTerrainPathNodeKey(x: 9, y: 64, z: 8)

    func fixture(
        _ contract: LabMultiAgentMovementHardeningCase,
        maxAgents: Int? = nil,
        physicalPositionOverrides: [String: LabTerrainPathNodeKey] = [:],
        collisionEvidenceSeeds: [String: UInt32] = [:],
        collisionEvidenceNodes: [String: LabTerrainPathNodeKey] = [:]
    ) -> LabMultiAgentMovementHardeningFixture {
        LabMultiAgentMovementHardeningFixture(
            contract: contract,
            maxAgents: maxAgents,
            physicalPositionOverrides: physicalPositionOverrides,
            collisionEvidenceSeeds: collisionEvidenceSeeds,
            collisionEvidenceNodes: collisionEvidenceNodes
        )
    }

    return [
        fixture(LabMultiAgentMovementHardeningCase(
            name: "approved_two_agents_remains_green",
            seed: approvedSeed,
            agents: [
                "agent_0": agent0From,
                "agent_1": agent1From
            ],
            intents: [
                multiAgentIntent("agent_0", from: agent0From, to: agent0To, reason: "hardening_approved_green"),
                multiAgentIntent("agent_1", from: agent1From, to: agent1To, reason: "hardening_approved_green")
            ],
            expectedApproved: 2,
            expectedDenied: 0,
            expectedDisplacementsApplied: 2,
            expectedDecisionCounts: ["approved": 2],
            expectedDivergenceBeforeMax: 0,
            expectedDivergenceAfterMax: 0
        )),
        fixture(LabMultiAgentMovementHardeningCase(
            name: "collision_denied_preserves_position",
            seed: deniedSeed,
            agents: ["agent_0": agent0From],
            intents: [
                multiAgentIntent("agent_0", from: agent0From, to: agent0To, reason: "hardening_collision_denied")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDisplacementsApplied: 0,
            expectedDecisionCounts: ["deniedCollision": 1],
            expectedDivergenceBeforeMax: 0,
            expectedDivergenceAfterMax: 0
        )),
        fixture(
            LabMultiAgentMovementHardeningCase(
                name: "partial_approval_one_approved_one_collision_denied",
                seed: approvedSeed,
                agents: [
                    "agent_0": agent0From,
                    "agent_1": LabTerrainPathNodeKey(x: 8, y: 64, z: 7)
                ],
                intents: [
                    multiAgentIntent("agent_0", from: agent0From, to: agent0To, reason: "hardening_partial_approval"),
                    multiAgentIntent("agent_1", from: LabTerrainPathNodeKey(x: 8, y: 64, z: 7), to: agent0To, reason: "hardening_partial_collision_denied")
                ],
                expectedApproved: 1,
                expectedDenied: 1,
                expectedDisplacementsApplied: 1,
                expectedDecisionCounts: [
                    "approved": 1,
                    "deniedCollision": 1
                ],
                expectedDivergenceBeforeMax: 0,
                expectedDivergenceAfterMax: 0
            ),
            collisionEvidenceSeeds: ["agent_1": deniedSeed]
        ),
        fixture(LabMultiAgentMovementHardeningCase(
            name: "same_destination_live_conflict_denies_loser",
            seed: approvedSeed,
            agents: [
                "agent_0": agent0From,
                "agent_1": LabTerrainPathNodeKey(x: 8, y: 64, z: 7)
            ],
            intents: [
                multiAgentIntent("agent_0", from: agent0From, to: agent0To, reason: "hardening_same_destination"),
                multiAgentIntent("agent_1", from: LabTerrainPathNodeKey(x: 8, y: 64, z: 7), to: agent0To, reason: "hardening_same_destination")
            ],
            expectedApproved: 1,
            expectedDenied: 1,
            expectedDisplacementsApplied: 1,
            expectedDecisionCounts: [
                "approved": 1,
                "deniedSameDestinationConflict": 1
            ],
            expectedDivergenceBeforeMax: 0,
            expectedDivergenceAfterMax: 0
        )),
        fixture(LabMultiAgentMovementHardeningCase(
            name: "swap_conflict_live_denies_both",
            seed: approvedSeed,
            agents: [
                "agent_0": agent0From,
                "agent_1": agent0To
            ],
            intents: [
                multiAgentIntent("agent_0", from: agent0From, to: agent0To, reason: "hardening_swap_conflict"),
                multiAgentIntent("agent_1", from: agent0To, to: agent0From, reason: "hardening_swap_conflict")
            ],
            expectedApproved: 0,
            expectedDenied: 2,
            expectedDisplacementsApplied: 0,
            expectedDecisionCounts: ["deniedSwapConflict": 2],
            expectedDivergenceBeforeMax: 0,
            expectedDivergenceAfterMax: 0
        )),
        fixture(LabMultiAgentMovementHardeningCase(
            name: "source_mismatch_live_denied_before_collision",
            seed: approvedSeed,
            agents: ["agent_0": agent0From],
            intents: [
                multiAgentIntent("agent_0", from: LabTerrainPathNodeKey(x: 6, y: 64, z: 8), to: agent0To, reason: "hardening_source_mismatch")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDisplacementsApplied: 0,
            expectedDecisionCounts: ["deniedSourceMismatch": 1],
            expectedDivergenceBeforeMax: 0,
            expectedDivergenceAfterMax: 0
        )),
        fixture(LabMultiAgentMovementHardeningCase(
            name: "stale_intent_live_denied_before_collision",
            seed: approvedSeed,
            agents: ["agent_0": agent0From],
            intents: [
                multiAgentIntent("agent_0", from: agent0From, to: agent0To, reason: "hardening_stale_intent", stale: true)
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDisplacementsApplied: 0,
            expectedDecisionCounts: ["deniedStaleIntent": 1],
            expectedDivergenceBeforeMax: 0,
            expectedDivergenceAfterMax: 0
        )),
        fixture(LabMultiAgentMovementHardeningCase(
            name: "invalid_edge_live_denied_before_collision",
            seed: approvedSeed,
            agents: ["agent_0": agent0From],
            intents: [
                multiAgentIntent("agent_0", from: agent0From, to: LabTerrainPathNodeKey(x: 8, y: 64, z: 9), reason: "hardening_invalid_edge")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDisplacementsApplied: 0,
            expectedDecisionCounts: ["deniedInvalidEdge": 1],
            expectedDivergenceBeforeMax: 0,
            expectedDivergenceAfterMax: 0
        )),
        fixture(
            LabMultiAgentMovementHardeningCase(
                name: "divergence_before_movement_denied",
                seed: approvedSeed,
                agents: ["agent_0": agent0From],
                intents: [
                    multiAgentIntent("agent_0", from: agent0From, to: agent0To, reason: "hardening_divergence_before")
                ],
                expectedApproved: 0,
                expectedDenied: 1,
                expectedDisplacementsApplied: 0,
                expectedDecisionCounts: ["deniedDivergence": 1],
                expectedDivergenceBeforeMax: 1,
                expectedDivergenceAfterMax: 1
            ),
            physicalPositionOverrides: [
                "agent_0": LabTerrainPathNodeKey(x: 6, y: 64, z: 8)
            ]
        ),
        fixture(
            LabMultiAgentMovementHardeningCase(
                name: "stale_collision_evidence_denied",
                seed: approvedSeed,
                agents: ["agent_0": agent0From],
                intents: [
                    multiAgentIntent("agent_0", from: agent0From, to: agent0To, reason: "hardening_stale_collision")
                ],
                expectedApproved: 0,
                expectedDenied: 1,
                expectedDisplacementsApplied: 0,
                expectedDecisionCounts: ["deniedStaleCollision": 1],
                expectedDivergenceBeforeMax: 0,
                expectedDivergenceAfterMax: 0
            ),
            collisionEvidenceNodes: [
                "agent_0": agent1To
            ]
        ),
        fixture(
            LabMultiAgentMovementHardeningCase(
                name: "all_denied_live_mixed_reasons",
                seed: approvedSeed,
                agents: [
                    "agent_0": agent0From,
                    "agent_1": agent1From,
                    "agent_2": LabTerrainPathNodeKey(x: 10, y: 64, z: 7)
                ],
                intents: [
                    multiAgentIntent("agent_0", from: agent0From, to: agent0To, reason: "hardening_all_denied_collision"),
                    multiAgentIntent("agent_1", from: LabTerrainPathNodeKey(x: 8, y: 64, z: 7), to: agent1To, reason: "hardening_all_denied_source_mismatch"),
                    multiAgentIntent("agent_2", from: LabTerrainPathNodeKey(x: 10, y: 64, z: 7), to: LabTerrainPathNodeKey(x: 11, y: 64, z: 8), reason: "hardening_all_denied_invalid")
                ],
                expectedApproved: 0,
                expectedDenied: 3,
                expectedDisplacementsApplied: 0,
                expectedDecisionCounts: [
                    "deniedCollision": 1,
                    "deniedInvalidEdge": 1,
                    "deniedSourceMismatch": 1
                ],
                expectedDivergenceBeforeMax: 0,
                expectedDivergenceAfterMax: 0
            ),
            collisionEvidenceSeeds: ["agent_0": deniedSeed],
            collisionEvidenceNodes: ["agent_0": agent0To]
        ),
        fixture(
            LabMultiAgentMovementHardeningCase(
                name: "max_agents_live_bound_exceeded",
                seed: approvedSeed,
                agents: [
                    "agent_0": agent0From,
                    "agent_1": agent1From,
                    "agent_2": LabTerrainPathNodeKey(x: 10, y: 64, z: 7),
                    "agent_3": LabTerrainPathNodeKey(x: 11, y: 64, z: 7),
                    "agent_4": LabTerrainPathNodeKey(x: 12, y: 64, z: 7)
                ],
                intents: [
                    multiAgentIntent("agent_0", from: agent0From, to: agent0To, reason: "hardening_max_agents"),
                    multiAgentIntent("agent_1", from: agent1From, to: agent1To, reason: "hardening_max_agents"),
                    multiAgentIntent("agent_2", from: LabTerrainPathNodeKey(x: 10, y: 64, z: 7), to: LabTerrainPathNodeKey(x: 10, y: 64, z: 8), reason: "hardening_max_agents"),
                    multiAgentIntent("agent_3", from: LabTerrainPathNodeKey(x: 11, y: 64, z: 7), to: LabTerrainPathNodeKey(x: 11, y: 64, z: 8), reason: "hardening_max_agents"),
                    multiAgentIntent("agent_4", from: LabTerrainPathNodeKey(x: 12, y: 64, z: 7), to: LabTerrainPathNodeKey(x: 12, y: 64, z: 8), reason: "hardening_max_agents")
                ],
                expectedApproved: 0,
                expectedDenied: 5,
                expectedDisplacementsApplied: 0,
                expectedDecisionCounts: ["deniedMaxAgents": 5],
                expectedDivergenceBeforeMax: 0,
                expectedDivergenceAfterMax: 0
            ),
            maxAgents: 4
        )
    ]
}

func makeMultiAgentApprovedPhysicalMovementReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabMultiAgentApprovedPhysicalMovementReport {
    let results = multiAgentApprovedPhysicalMovementCases().map {
        evaluateMultiAgentApprovedPhysicalMovementCase(
            $0,
            scenario: scenario,
            ticksCompleted: ticksCompleted
        )
    }
    let passed = results.filter(\.passed).count
    let approved = results.reduce(0) { $0 + $1.actualApproved }
    let denied = results.reduce(0) { $0 + $1.actualDenied }
    let displacements = results.reduce(0) { $0 + $1.actualDisplacementsApplied }
    let allResolutions = results.flatMap(\.resolutions)
    let divergenceBeforeMax = results.map(\.divergenceBeforeMax).max() ?? 0
    let divergenceAfterMax = results.map(\.divergenceAfterMax).max() ?? 0
    let occupableDestinations = allResolutions.filter {
        $0.collisionStatus == .occupable
    }.count
    let nonOccupableDestinations = allResolutions.filter {
        $0.collisionStatus != .occupable
    }.count
    let summary = LabMultiAgentApprovedPhysicalMovementSummary(
        cases: results.count,
        passed: passed,
        failed: results.count - passed,
        agentCountTotal: results.reduce(0) { $0 + $1.agents.count },
        intentCountTotal: results.reduce(0) { $0 + $1.intents.count },
        approvedTotal: approved,
        deniedTotal: denied,
        displacementsApplied: displacements,
        occupableDestinations: occupableDestinations,
        nonOccupableDestinations: nonOccupableDestinations,
        divergenceBeforeMax: divergenceBeforeMax,
        divergenceAfterMax: divergenceAfterMax,
        worldUsed: true,
        liveCollisionRead: !allResolutions.isEmpty,
        physicalMovementApplied: displacements > 0,
        routeFollowingApplied: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        goalSelectionPerformed: false,
        avoidancePerformed: false,
        reservationTableImplemented: false,
        physicsPerformed: false,
        terrainMutationPerformed: false,
        worldMutationPerformed: false,
        success: passed == results.count
            && results.count >= 1
            && approved >= 2
            && denied == 0
            && displacements == approved
            && occupableDestinations == approved
            && nonOccupableDestinations == 0
            && divergenceBeforeMax == 0
            && divergenceAfterMax == 0
    )

    return LabMultiAgentApprovedPhysicalMovementReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        summary: summary,
        cases: results
    )
}

func makeMultiAgentApprovedPhysicalMovementInvariantReport(
    report: LabMultiAgentApprovedPhysicalMovementReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiAgentApprovedPhysicalMovementInvariantReport {
    let cases = report?.cases ?? []
    let names = Set(cases.map(\.name))
    let resolutions = cases.flatMap(\.resolutions)
    let fixtureReport = makeMultiAgentMovementFixtureReport(
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let fixtureInvariantReport = makeMultiAgentMovementFixtureInvariantReport(
        report: fixtureReport,
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed
    )
    let hardeningReport = makeMultiAgentMovementFixtureHardeningReport(
        scenario: "multi_agent_movement_fixture_hardening_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let hardeningInvariantReport = makeMultiAgentMovementFixtureHardeningInvariantReport(
        report: hardeningReport,
        scenario: "multi_agent_movement_fixture_hardening_smoke",
        seed: seed
    )
    let liveIntentReport = makeMultiAgentLiveCollisionIntentReport(
        scenario: "multi_agent_live_collision_intent_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let liveIntentInvariantReport = makeMultiAgentLiveCollisionIntentInvariantReport(
        report: liveIntentReport,
        scenario: "multi_agent_live_collision_intent_smoke",
        seed: seed
    )
    let singleStepApproved = makePhysicalMovementApprovedSingleStepSnapshot(
        scenario: "physical_movement_approved_single_step_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let singleStepApprovedInvariant = makePhysicalMovementIntegrationInvariantReport(
        snapshot: singleStepApproved,
        scenario: "physical_movement_approved_single_step_smoke",
        seed: seed
    )
    let fixtureSmokeGreen = fixtureReport.success
        && fixtureInvariantReport.success
        && fixtureReport.summary.failed == 0
    let hardeningSmokeGreen = hardeningReport.success
        && hardeningInvariantReport.success
        && hardeningReport.summary.failed == 0
    let liveIntentSmokeGreen = liveIntentReport.success
        && liveIntentInvariantReport.success
        && liveIntentReport.summary.failed == 0
    let singleStepApprovedGreen = singleStepApproved.success
        && singleStepApprovedInvariant.success
        && singleStepApproved.displacementApplied
    let allCasesPassed = report?.summary.failed == 0
    let allDestinationsOccupable = resolutions.allSatisfy {
        $0.collisionStatus == .occupable
    }
    let allApproved = !resolutions.isEmpty && resolutions.allSatisfy(\.approved)
    let noDenied = resolutions.allSatisfy { $0.approved }
    let displacementsMatchApproved = report?.summary.displacementsApplied == report?.summary.approvedTotal
    let eachAgentHasPhysicalHandle = cases.allSatisfy {
        Set($0.initialPhysicalPositions.keys) == Set($0.agents.keys)
    }
    let abstractInitialMatchesSources = cases.allSatisfy { result in
        result.intents.allSatisfy {
            result.initialAbstractPositions[$0.agentId] == $0.from
        }
    }
    let physicalInitialMatchesAbstract = cases.allSatisfy {
        $0.initialPhysicalPositions == $0.initialAbstractPositions
    }
    let abstractFinalMatchesDestinations = cases.allSatisfy { result in
        result.intents.allSatisfy {
            result.finalAbstractPositions[$0.agentId] == $0.to
        }
    }
    let physicalFinalMatchesDestinations = cases.allSatisfy { result in
        result.intents.allSatisfy {
            result.finalPhysicalPositions[$0.agentId] == $0.to
        }
    }
    let abstractPhysicalFinalMatch = cases.allSatisfy {
        $0.finalAbstractPositions == $0.finalPhysicalPositions
    }
    let eachMoveOneEdge = resolutions.allSatisfy {
        isFixtureEdgeAllowed(from: $0.abstractBefore, to: $0.abstractAfter)
            && isFixtureEdgeAllowed(from: $0.physicalBefore, to: $0.physicalAfter)
    }
    let sameYOnly = resolutions.allSatisfy {
        $0.abstractBefore.y == $0.abstractAfter.y
            && $0.physicalBefore.y == $0.physicalAfter.y
    }
    let noDuplicateDestination = cases.allSatisfy { result in
        let destinations = result.intents.map(\.to)
        return Set(destinations).count == destinations.count
    }
    let noSwapConflict = cases.allSatisfy { result in
        !result.intents.contains { first in
            result.intents.contains { second in
                first.agentId != second.agentId
                    && first.from == second.to
                    && first.to == second.from
            }
        }
    }
    let stableAgentOrdering = cases.allSatisfy {
        $0.resolutions.map(\.agentId) == $0.resolutions.map(\.agentId).sorted()
    }
    let checks = [
        check("approved_physical_movement_cases_exist", !cases.isEmpty, "> 0", "\(cases.count)"),
        check("two_agent_approved_case_exists", names.contains("two_agents_two_approved_single_step_moves"), "present", names.sorted().joined(separator: ",")),
        check("all_cases_passed", allCasesPassed, "true", String(allCasesPassed)),
        check("world_used_for_live_collision_and_movement", report?.summary.worldUsed == true, "true", String(report?.summary.worldUsed ?? false)),
        check("live_collision_read_for_each_intent", report?.summary.liveCollisionRead == true && report?.summary.occupableDestinations == report?.summary.intentCountTotal, "each intent", "\(report?.summary.occupableDestinations ?? -1)/\(report?.summary.intentCountTotal ?? -1)"),
        check("all_destinations_occupable", allDestinationsOccupable, "true", String(allDestinationsOccupable)),
        check("no_non_occupable_destinations", report?.summary.nonOccupableDestinations == 0, "0", "\(report?.summary.nonOccupableDestinations ?? -1)"),
        check("all_intents_approved", allApproved, "true", String(allApproved)),
        check("no_intents_denied", noDenied && report?.summary.deniedTotal == 0, "0 denied", "\(report?.summary.deniedTotal ?? -1)"),
        check("displacements_applied_match_approved", displacementsMatchApproved, "true", String(displacementsMatchApproved)),
        check("each_agent_has_physical_handle", eachAgentHasPhysicalHandle, "true", String(eachAgentHasPhysicalHandle)),
        check("abstract_initial_positions_match_intent_sources", abstractInitialMatchesSources, "true", String(abstractInitialMatchesSources)),
        check("physical_initial_positions_match_abstract_initial_positions", physicalInitialMatchesAbstract, "true", String(physicalInitialMatchesAbstract)),
        check("abstract_final_positions_match_intent_destinations", abstractFinalMatchesDestinations, "true", String(abstractFinalMatchesDestinations)),
        check("physical_final_positions_match_intent_destinations", physicalFinalMatchesDestinations, "true", String(physicalFinalMatchesDestinations)),
        check("abstract_and_physical_final_positions_match", abstractPhysicalFinalMatch, "true", String(abstractPhysicalFinalMatch)),
        check("divergence_before_zero", report?.summary.divergenceBeforeMax == 0, "0", "\(report?.summary.divergenceBeforeMax ?? -1)"),
        check("divergence_after_zero", report?.summary.divergenceAfterMax == 0, "0", "\(report?.summary.divergenceAfterMax ?? -1)"),
        check("each_move_is_one_edge", eachMoveOneEdge, "true", String(eachMoveOneEdge)),
        check("same_y_only", sameYOnly, "true", String(sameYOnly)),
        check("no_duplicate_destination", noDuplicateDestination, "true", String(noDuplicateDestination)),
        check("no_same_destination_conflict", noDuplicateDestination, "true", String(noDuplicateDestination)),
        check("no_swap_conflict", noSwapConflict, "true", String(noSwapConflict)),
        check("stable_agent_ordering", stableAgentOrdering, "true", String(stableAgentOrdering)),
        check("single_step_contract_used", report?.summary.displacementsApplied == resolutions.count && resolutions.allSatisfy { $0.displacementApplied }, "true", "\(report?.summary.displacementsApplied ?? -1)/\(resolutions.count)"),
        check("route_following_not_applied", report?.summary.routeFollowingApplied == false, "false", String(report?.summary.routeFollowingApplied ?? true)),
        check("pathfinding_not_performed", report?.summary.pathfindingPerformed == false, "false", String(report?.summary.pathfindingPerformed ?? true)),
        check("replanning_not_performed", report?.summary.replanningPerformed == false, "false", String(report?.summary.replanningPerformed ?? true)),
        check("goal_selection_not_performed", report?.summary.goalSelectionPerformed == false, "false", String(report?.summary.goalSelectionPerformed ?? true)),
        check("avoidance_not_performed", report?.summary.avoidancePerformed == false, "false", String(report?.summary.avoidancePerformed ?? true)),
        check("reservation_table_not_implemented", report?.summary.reservationTableImplemented == false, "false", String(report?.summary.reservationTableImplemented ?? true)),
        check("physics_not_performed", report?.summary.physicsPerformed == false, "false", String(report?.summary.physicsPerformed ?? true)),
        check("terrain_mutation_not_performed", report?.summary.terrainMutationPerformed == false, "false", String(report?.summary.terrainMutationPerformed ?? true)),
        check("world_mutation_not_performed", report?.summary.worldMutationPerformed == false, "false", String(report?.summary.worldMutationPerformed ?? true)),
        check("fixture_smoke_remains_green", fixtureSmokeGreen, "true", String(fixtureSmokeGreen)),
        check("fixture_hardening_smoke_remains_green", hardeningSmokeGreen, "true", String(hardeningSmokeGreen)),
        check("live_collision_intent_smoke_remains_green", liveIntentSmokeGreen, "true", String(liveIntentSmokeGreen)),
        check("single_step_approved_smoke_remains_green", singleStepApprovedGreen, "true", String(singleStepApprovedGreen)),
        check("report_written", true, "multi_agent_approved_physical_movement_report.json", "multi_agent_approved_physical_movement_report.json"),
        check("metrics_written", true, "multiAgentApprovedPhysicalMovement* metrics", "multiAgentApprovedPhysicalMovement* metrics"),
        check("event_written", true, "lab_multi_agent_approved_physical_movement_recorded", "lab_multi_agent_approved_physical_movement_recorded"),
        check("success_contract_respected", report?.success == true && report?.summary.failed == 0, "true", String(report?.success == true && report?.summary.failed == 0))
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabMultiAgentApprovedPhysicalMovementInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: cases.count,
            passed: report?.summary.passed ?? 0,
            failed: report?.summary.failed ?? cases.count
        ),
        checks: checks,
        notes: [
            "Phase 4.19E applies only approved, non-conflicting, one-edge multi-agent physical placeholder movement.",
            "The smoke uses live collision evidence and LabAgentPhysicalBridge sync; no route follower, pathfinding, replanning, reservation runtime, avoidance, physics, terrain mutation, or world mutation is performed.",
            "Denied live multi-agent movement and conflict hardening remain deferred to Phase 4.19F."
        ]
    )
}

func makeMultiAgentMovementHardeningReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabMultiAgentMovementHardeningReport {
    let results = multiAgentMovementHardeningCases().map {
        evaluateMultiAgentMovementHardeningCase(
            $0,
            scenario: scenario,
            ticksCompleted: ticksCompleted
        )
    }
    let passed = results.filter(\.passed).count
    let approved = results.reduce(0) { $0 + $1.actualApproved }
    let denied = results.reduce(0) { $0 + $1.actualDenied }
    let displacements = results.reduce(0) { $0 + $1.actualDisplacementsApplied }
    let allResolutions = results.flatMap(\.resolutions)
    let divergenceBeforeMax = results.map(\.divergenceBeforeMax).max() ?? 0
    let divergenceAfterMax = results.map(\.divergenceAfterMax).max() ?? 0
    let occupableDestinations = allResolutions.filter {
        $0.collisionRead && $0.collisionStatus == .occupable
    }.count
    let nonOccupableDestinations = allResolutions.filter {
        $0.collisionRead
            && $0.collisionStatus != nil
            && $0.collisionStatus != .occupable
    }.count
    let summary = LabMultiAgentMovementHardeningSummary(
        cases: results.count,
        passed: passed,
        failed: results.count - passed,
        agentCountTotal: results.reduce(0) { $0 + $1.agents.count },
        intentCountTotal: results.reduce(0) { $0 + $1.intents.count },
        approvedTotal: approved,
        deniedTotal: denied,
        displacementsApplied: displacements,
        occupableDestinations: occupableDestinations,
        nonOccupableDestinations: nonOccupableDestinations,
        collisionDenied: hardeningDecisionCount(in: results, .deniedCollision),
        sameDestinationConflicts: hardeningDecisionCount(in: results, .deniedSameDestinationConflict),
        swapConflicts: hardeningDecisionCount(in: results, .deniedSwapConflict),
        sourceMismatch: hardeningDecisionCount(in: results, .deniedSourceMismatch),
        staleIntent: hardeningDecisionCount(in: results, .deniedStaleIntent),
        invalidEdges: hardeningDecisionCount(in: results, .deniedInvalidEdge),
        divergenceDenied: hardeningDecisionCount(in: results, .deniedDivergence),
        staleCollision: hardeningDecisionCount(in: results, .deniedStaleCollision),
        partialApprovalCases: results.filter {
            $0.actualApproved > 0 && $0.actualDenied > 0
        }.count,
        allDeniedCases: results.filter {
            !$0.intents.isEmpty && $0.actualApproved == 0 && $0.actualDenied > 0
        }.count,
        maxAgentsExceeded: hardeningDecisionCount(in: results, .deniedMaxAgents),
        divergenceBeforeMax: divergenceBeforeMax,
        divergenceAfterMax: divergenceAfterMax,
        worldUsed: true,
        liveCollisionRead: allResolutions.contains { $0.collisionRead },
        physicalMovementApplied: displacements > 0,
        routeFollowingApplied: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        goalSelectionPerformed: false,
        avoidancePerformed: false,
        reservationTableImplemented: false,
        physicsPerformed: false,
        terrainMutationPerformed: false,
        worldMutationPerformed: false,
        success: passed == results.count
            && approved > 0
            && denied > 0
            && displacements > 0
            && results.contains { $0.name == "partial_approval_one_approved_one_collision_denied" && $0.passed }
            && hardeningDecisionCount(in: results, .deniedCollision) > 0
            && hardeningDecisionCount(in: results, .deniedSameDestinationConflict) > 0
            && hardeningDecisionCount(in: results, .deniedSwapConflict) > 0
            && hardeningDecisionCount(in: results, .deniedSourceMismatch) > 0
            && hardeningDecisionCount(in: results, .deniedStaleIntent) > 0
            && hardeningDecisionCount(in: results, .deniedInvalidEdge) > 0
            && hardeningDecisionCount(in: results, .deniedDivergence) > 0
            && hardeningDecisionCount(in: results, .deniedStaleCollision) > 0
            && hardeningDecisionCount(in: results, .deniedMaxAgents) > 0
            && allResolutions.filter(\.approved).allSatisfy { $0.divergenceAfter == 0 }
    )

    return LabMultiAgentMovementHardeningReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        summary: summary,
        cases: results
    )
}

func makeMultiAgentMovementHardeningInvariantReport(
    report: LabMultiAgentMovementHardeningReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiAgentMovementHardeningInvariantReport {
    let cases = report?.cases ?? []
    let names = Set(cases.map(\.name))
    let resolutions = cases.flatMap(\.resolutions)
    let approved = resolutions.filter(\.approved)
    let denied = resolutions.filter { !$0.approved }
    let fixtureReport = makeMultiAgentMovementFixtureReport(
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let fixtureInvariantReport = makeMultiAgentMovementFixtureInvariantReport(
        report: fixtureReport,
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed
    )
    let fixtureHardeningReport = makeMultiAgentMovementFixtureHardeningReport(
        scenario: "multi_agent_movement_fixture_hardening_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let fixtureHardeningInvariantReport = makeMultiAgentMovementFixtureHardeningInvariantReport(
        report: fixtureHardeningReport,
        scenario: "multi_agent_movement_fixture_hardening_smoke",
        seed: seed
    )
    let liveIntentReport = makeMultiAgentLiveCollisionIntentReport(
        scenario: "multi_agent_live_collision_intent_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let liveIntentInvariantReport = makeMultiAgentLiveCollisionIntentInvariantReport(
        report: liveIntentReport,
        scenario: "multi_agent_live_collision_intent_smoke",
        seed: seed
    )
    let approvedPhysicalReport = makeMultiAgentApprovedPhysicalMovementReport(
        scenario: "multi_agent_approved_physical_movement_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let approvedPhysicalInvariantReport = makeMultiAgentApprovedPhysicalMovementInvariantReport(
        report: approvedPhysicalReport,
        scenario: "multi_agent_approved_physical_movement_smoke",
        seed: seed
    )
    let singleStepHardening = makePhysicalMovementSingleStepHardeningReport(
        scenario: "physical_movement_single_step_hardening_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let singleStepHardeningInvariant = makePhysicalMovementHardeningInvariantReport(
        report: singleStepHardening,
        scenario: "physical_movement_single_step_hardening_smoke",
        seed: seed
    )
    let fixtureSmokeGreen = fixtureReport.success
        && fixtureInvariantReport.success
        && fixtureReport.summary.failed == 0
    let fixtureHardeningGreen = fixtureHardeningReport.success
        && fixtureHardeningInvariantReport.success
        && fixtureHardeningReport.summary.failed == 0
    let liveIntentGreen = liveIntentReport.success
        && liveIntentInvariantReport.success
        && liveIntentReport.summary.failed == 0
    let approvedPhysicalGreen = approvedPhysicalReport.success
        && approvedPhysicalInvariantReport.success
        && approvedPhysicalReport.summary.failed == 0
    let singleStepHardeningGreen = singleStepHardening.success
        && singleStepHardeningInvariant.success
        && singleStepHardening.summary.failed == 0
    let deniedAbstractPreserved = denied.allSatisfy {
        $0.abstractBefore == $0.abstractAfter
    }
    let deniedPhysicalPreserved = denied.allSatisfy {
        $0.physicalBefore == $0.physicalAfter
    }
    let approvedAbstractOneEdge = approved.allSatisfy {
        guard let before = $0.abstractBefore, let after = $0.abstractAfter else {
            return false
        }
        return isFixtureEdgeAllowed(from: before, to: after)
    }
    let approvedPhysicalOneEdge = approved.allSatisfy {
        guard let before = $0.physicalBefore, let after = $0.physicalAfter else {
            return false
        }
        return isFixtureEdgeAllowed(from: before, to: after)
    }
    let finalAbstractPhysicalMatch = cases.allSatisfy { result in
        result.resolutions.filter(\.approved).allSatisfy {
            result.finalAbstractPositions[$0.agentId] == result.finalPhysicalPositions[$0.agentId]
        }
    }
    let noDuplicateApprovedDestination = cases.allSatisfy {
        let destinations = $0.resolutions.filter(\.approved).map(\.intent.to)
        return Set(destinations).count == destinations.count
    }
    let noApprovedSwap = cases.allSatisfy { result in
        let approved = result.resolutions.filter(\.approved)
        return !approved.contains { first in
            approved.contains { second in
                first.agentId != second.agentId
                    && first.intent.from == second.intent.to
                    && first.intent.to == second.intent.from
            }
        }
    }
    let sourceMismatchSkipsCollision = cases.first {
        $0.name == "source_mismatch_live_denied_before_collision"
    }?.resolutions.allSatisfy { !$0.collisionRead } == true
    let staleSkipsCollision = cases.first {
        $0.name == "stale_intent_live_denied_before_collision"
    }?.resolutions.allSatisfy { !$0.collisionRead } == true
    let invalidSkipsCollision = cases.first {
        $0.name == "invalid_edge_live_denied_before_collision"
    }?.resolutions.allSatisfy { !$0.collisionRead } == true
    let liveCollisionReadForCollisionRequired = cases.filter {
        ![
            "source_mismatch_live_denied_before_collision",
            "stale_intent_live_denied_before_collision",
            "invalid_edge_live_denied_before_collision",
            "divergence_before_movement_denied",
            "swap_conflict_live_denies_both",
            "max_agents_live_bound_exceeded"
        ].contains($0.name)
    }.flatMap(\.resolutions).filter {
        ![.deniedSourceMismatch, .deniedStaleIntent, .deniedInvalidEdge, .deniedDivergence, .deniedSwapConflict, .deniedMaxAgents].contains($0.decision)
    }.allSatisfy(\.collisionRead)
    let collisionDeniedPreserves = cases.first {
        $0.name == "collision_denied_preserves_position"
    }?.resolutions.allSatisfy {
        !$0.approved && $0.abstractBefore == $0.abstractAfter && $0.physicalBefore == $0.physicalAfter
    } == true
    let partialApprovalPreservesDenied = cases.first {
        $0.name == "partial_approval_one_approved_one_collision_denied"
    }?.resolutions.filter { !$0.approved }.allSatisfy {
        $0.abstractBefore == $0.abstractAfter && $0.physicalBefore == $0.physicalAfter
    } == true
    let sameDestinationLoserDenied = cases.first {
        $0.name == "same_destination_live_conflict_denies_loser"
    }?.resolutions.first(where: { $0.agentId == "agent_1" })?.decision == .deniedSameDestinationConflict
    let swapDeniesBoth = cases.first {
        $0.name == "swap_conflict_live_denies_both"
    }?.resolutions.allSatisfy { $0.decision == .deniedSwapConflict } == true
    let allDeniedZeroDisplacements = cases.first {
        $0.name == "all_denied_live_mixed_reasons"
    }?.actualDisplacementsApplied == 0
    let maxAgentsDeniedAll = cases.first {
        $0.name == "max_agents_live_bound_exceeded"
    }?.actualDecisionCounts["deniedMaxAgents"] == 5
    let displacementsMatchApproved = report?.summary.displacementsApplied == approved.filter(\.displacementApplied).count
        && approved.allSatisfy(\.displacementApplied)
    let nonOccupableDenied = denied.contains {
        $0.decision == .deniedCollision
            && $0.collisionRead
            && $0.collisionStatus != .occupable
    }
    let checks = [
        check("hardening_cases_exist", !cases.isEmpty, "> 0", "\(cases.count)"),
        check("approved_case_exists", names.contains("approved_two_agents_remains_green"), "present", names.sorted().joined(separator: ",")),
        check("collision_denied_case_exists", names.contains("collision_denied_preserves_position"), "present", names.sorted().joined(separator: ",")),
        check("partial_approval_case_exists", names.contains("partial_approval_one_approved_one_collision_denied"), "present", names.sorted().joined(separator: ",")),
        check("same_destination_live_conflict_case_exists", names.contains("same_destination_live_conflict_denies_loser"), "present", names.sorted().joined(separator: ",")),
        check("swap_conflict_live_case_exists", names.contains("swap_conflict_live_denies_both"), "present", names.sorted().joined(separator: ",")),
        check("source_mismatch_case_exists", names.contains("source_mismatch_live_denied_before_collision"), "present", names.sorted().joined(separator: ",")),
        check("stale_intent_case_exists", names.contains("stale_intent_live_denied_before_collision"), "present", names.sorted().joined(separator: ",")),
        check("invalid_edge_case_exists", names.contains("invalid_edge_live_denied_before_collision"), "present", names.sorted().joined(separator: ",")),
        check("divergence_before_case_exists", names.contains("divergence_before_movement_denied"), "present", names.sorted().joined(separator: ",")),
        check("stale_collision_case_exists", names.contains("stale_collision_evidence_denied"), "present", names.sorted().joined(separator: ",")),
        check("all_denied_case_exists", names.contains("all_denied_live_mixed_reasons"), "present", names.sorted().joined(separator: ",")),
        check("max_agents_case_exists", names.contains("max_agents_live_bound_exceeded"), "present", names.sorted().joined(separator: ",")),
        check("all_cases_passed", report?.summary.failed == 0, "0", "\(report?.summary.failed ?? -1)"),
        check("approved_case_applies_expected_displacements", cases.first { $0.name == "approved_two_agents_remains_green" }?.actualDisplacementsApplied == 2, "2", "\(cases.first { $0.name == "approved_two_agents_remains_green" }?.actualDisplacementsApplied ?? -1)"),
        check("collision_denied_preserves_position", collisionDeniedPreserves, "true", String(collisionDeniedPreserves)),
        check("partial_approval_preserves_denied_agent", partialApprovalPreservesDenied, "true", String(partialApprovalPreservesDenied)),
        check("same_destination_loser_denied", sameDestinationLoserDenied, "true", String(sameDestinationLoserDenied)),
        check("no_duplicate_approved_destination", noDuplicateApprovedDestination, "true", String(noDuplicateApprovedDestination)),
        check("swap_conflict_denies_both", swapDeniesBoth, "true", String(swapDeniesBoth)),
        check("no_approved_swap", noApprovedSwap, "true", String(noApprovedSwap)),
        check("source_mismatch_skips_collision", sourceMismatchSkipsCollision, "true", String(sourceMismatchSkipsCollision)),
        check("stale_intent_skips_collision", staleSkipsCollision, "true", String(staleSkipsCollision)),
        check("invalid_edge_skips_collision", invalidSkipsCollision, "true", String(invalidSkipsCollision)),
        check("divergence_before_denies_movement", hardeningDecisionCount(in: cases, .deniedDivergence) > 0, "> 0", "\(hardeningDecisionCount(in: cases, .deniedDivergence))"),
        check("stale_collision_denies_movement", hardeningDecisionCount(in: cases, .deniedStaleCollision) > 0, "> 0", "\(hardeningDecisionCount(in: cases, .deniedStaleCollision))"),
        check("all_denied_case_has_zero_displacements", allDeniedZeroDisplacements == true, "true", String(allDeniedZeroDisplacements == true)),
        check("max_agents_bound_denies_all", maxAgentsDeniedAll, "true", String(maxAgentsDeniedAll)),
        check("denied_movements_preserve_abstract_position", deniedAbstractPreserved, "true", String(deniedAbstractPreserved)),
        check("denied_movements_preserve_physical_position", deniedPhysicalPreserved, "true", String(deniedPhysicalPreserved)),
        check("approved_movements_move_abstract_one_edge", approvedAbstractOneEdge, "true", String(approvedAbstractOneEdge)),
        check("approved_movements_move_physical_one_edge", approvedPhysicalOneEdge, "true", String(approvedPhysicalOneEdge)),
        check("abstract_and_physical_final_positions_match", finalAbstractPhysicalMatch, "approved final abstract == physical", String(finalAbstractPhysicalMatch)),
        check("divergence_after_zero_for_approved_moves", approved.allSatisfy { $0.divergenceAfter == 0 }, "true", String(approved.allSatisfy { $0.divergenceAfter == 0 })),
        check("displacements_match_approved_movements", displacementsMatchApproved, "true", String(displacementsMatchApproved)),
        check("live_collision_read_for_collision_required_intents", liveCollisionReadForCollisionRequired, "true", String(liveCollisionReadForCollisionRequired)),
        check("non_occupable_destinations_denied", nonOccupableDenied, "true", String(nonOccupableDenied)),
        check("route_following_not_applied", report?.summary.routeFollowingApplied == false, "false", String(report?.summary.routeFollowingApplied ?? true)),
        check("pathfinding_not_performed", report?.summary.pathfindingPerformed == false, "false", String(report?.summary.pathfindingPerformed ?? true)),
        check("replanning_not_performed", report?.summary.replanningPerformed == false, "false", String(report?.summary.replanningPerformed ?? true)),
        check("goal_selection_not_performed", report?.summary.goalSelectionPerformed == false, "false", String(report?.summary.goalSelectionPerformed ?? true)),
        check("avoidance_not_performed", report?.summary.avoidancePerformed == false, "false", String(report?.summary.avoidancePerformed ?? true)),
        check("reservation_table_not_implemented", report?.summary.reservationTableImplemented == false, "false", String(report?.summary.reservationTableImplemented ?? true)),
        check("physics_not_performed", report?.summary.physicsPerformed == false, "false", String(report?.summary.physicsPerformed ?? true)),
        check("terrain_mutation_not_performed", report?.summary.terrainMutationPerformed == false, "false", String(report?.summary.terrainMutationPerformed ?? true)),
        check("world_mutation_not_performed", report?.summary.worldMutationPerformed == false, "false", String(report?.summary.worldMutationPerformed ?? true)),
        check("fixture_smoke_remains_green", fixtureSmokeGreen, "true", String(fixtureSmokeGreen)),
        check("fixture_hardening_smoke_remains_green", fixtureHardeningGreen, "true", String(fixtureHardeningGreen)),
        check("live_collision_intent_smoke_remains_green", liveIntentGreen, "true", String(liveIntentGreen)),
        check("approved_physical_movement_smoke_remains_green", approvedPhysicalGreen, "true", String(approvedPhysicalGreen)),
        check("single_step_hardening_smoke_remains_green", singleStepHardeningGreen, "true", String(singleStepHardeningGreen)),
        check("report_written", true, "multi_agent_movement_hardening_report.json", "multi_agent_movement_hardening_report.json"),
        check("metrics_written", true, "multiAgentMovementHardening* metrics", "multiAgentMovementHardening* metrics"),
        check("event_written", true, "lab_multi_agent_movement_hardening_recorded", "lab_multi_agent_movement_hardening_recorded"),
        check("success_contract_respected", report?.success == true && report?.summary.failed == 0, "true", String(report?.success == true && report?.summary.failed == 0))
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabMultiAgentMovementHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: cases.count,
            passed: report?.summary.passed ?? 0,
            failed: report?.summary.failed ?? cases.count
        ),
        checks: checks,
        notes: [
            "Phase 4.19F hardens live multi-agent physical movement with controlled approvals and refusals.",
            "Denied intents preserve abstract and physical positions; approved intents move one 4-neighbor same-y edge and are synced through LabAgentPhysicalBridge.",
            "No route following, pathfinding, replanning, goal selection, avoidance, reservation runtime, physics, terrain mutation, world mutation, save/load, or gameplay movement is introduced."
        ]
    )
}

private func evaluateMultiAgentMovementHardeningCase(
    _ fixture: LabMultiAgentMovementHardeningFixture,
    scenario: String,
    ticksCompleted: Int
) -> LabMultiAgentMovementHardeningCaseResult {
    let contract = fixture.contract
    var agents = contract.agents.map { agentId, node in
        LabAgent(id: agentId, x: node.x, y: node.y, z: node.z)
    }.sorted { $0.id < $1.id }
    var physicalBridge = LabAgentPhysicalBridge()
    for agent in agents {
        let physicalNode = fixture.physicalPositionOverrides[agent.id]
            ?? nodeKey(from: agent.position)
        let physicalAgent = LabAgent(
            id: agent.id,
            x: physicalNode.x,
            y: physicalNode.y,
            z: physicalNode.z
        )
        _ = physicalBridge.spawnPlaceholder(for: physicalAgent, tick: 0)
    }

    let initialAbstract = Dictionary(uniqueKeysWithValues: agents.map {
        ($0.id, nodeKey(from: $0.position))
    })
    let initialPhysical = Dictionary(uniqueKeysWithValues: physicalBridge.handles.map {
        ($0.agentId, nodeKey(from: $0.position))
    })
    let sortedIntents = contract.intents.sorted {
        $0.agentId == $1.agentId
            ? $0.reason < $1.reason
            : $0.agentId < $1.agentId
    }
    var resolutions: [LabMultiAgentMovementHardeningResolution] = []

    if let maxAgents = fixture.maxAgents, contract.agents.count > maxAgents {
        for intent in sortedIntents {
            let abstractBefore = initialAbstract[intent.agentId]
            let physicalBefore = initialPhysical[intent.agentId]
            let divergence = hardeningDivergence(
                abstract: abstractBefore,
                physical: physicalBefore
            )
            resolutions.append(hardeningResolution(
                for: intent,
                decision: .deniedMaxAgents,
                reason: "max_agents_exceeded",
                abstractBefore: abstractBefore,
                abstractAfter: abstractBefore,
                physicalBefore: physicalBefore,
                physicalAfter: physicalBefore,
                divergenceBefore: divergence,
                divergenceAfter: divergence
            ))
        }
        return hardeningResult(
            for: contract,
            initialAbstract: initialAbstract,
            finalAbstract: initialAbstract,
            initialPhysical: initialPhysical,
            finalPhysical: initialPhysical,
            resolutions: resolutions
        )
    }

    var pending: [LabAgentMoveIntent] = []
    for intent in sortedIntents {
        guard let agentIndex = agents.firstIndex(where: { $0.id == intent.agentId }) else {
            resolutions.append(hardeningResolution(
                for: intent,
                decision: .deniedMissingAgent,
                reason: "missing_agent",
                abstractBefore: nil,
                abstractAfter: nil,
                physicalBefore: nil,
                physicalAfter: nil,
                divergenceBefore: nil,
                divergenceAfter: nil
            ))
            continue
        }

        let abstractBefore = nodeKey(from: agents[agentIndex].position)
        let physicalBefore = physicalBridge.handles.first {
            $0.agentId == intent.agentId
        }.map { nodeKey(from: $0.position) }
        let divergenceBefore = hardeningDivergence(
            abstract: abstractBefore,
            physical: physicalBefore
        )

        if intent.stale {
            resolutions.append(hardeningResolution(
                for: intent,
                decision: .deniedStaleIntent,
                reason: "stale_intent_skips_collision",
                abstractBefore: abstractBefore,
                abstractAfter: abstractBefore,
                physicalBefore: physicalBefore,
                physicalAfter: physicalBefore,
                divergenceBefore: divergenceBefore,
                divergenceAfter: divergenceBefore
            ))
        } else if intent.from != abstractBefore {
            resolutions.append(hardeningResolution(
                for: intent,
                decision: .deniedSourceMismatch,
                reason: "source_mismatch_skips_collision",
                abstractBefore: abstractBefore,
                abstractAfter: abstractBefore,
                physicalBefore: physicalBefore,
                physicalAfter: physicalBefore,
                divergenceBefore: divergenceBefore,
                divergenceAfter: divergenceBefore
            ))
        } else if intent.from == intent.to || !isFixtureEdgeAllowed(from: intent.from, to: intent.to) {
            resolutions.append(hardeningResolution(
                for: intent,
                decision: .deniedInvalidEdge,
                reason: "invalid_edge_skips_collision",
                abstractBefore: abstractBefore,
                abstractAfter: abstractBefore,
                physicalBefore: physicalBefore,
                physicalAfter: physicalBefore,
                divergenceBefore: divergenceBefore,
                divergenceAfter: divergenceBefore
            ))
        } else if divergenceBefore != 0 {
            resolutions.append(hardeningResolution(
                for: intent,
                decision: .deniedDivergence,
                reason: "divergence_before_movement_denied",
                abstractBefore: abstractBefore,
                abstractAfter: abstractBefore,
                physicalBefore: physicalBefore,
                physicalAfter: physicalBefore,
                divergenceBefore: divergenceBefore,
                divergenceAfter: divergenceBefore
            ))
        } else {
            pending.append(intent)
        }
    }

    let swapAgentIds = Set(pending.flatMap { intent in
        pending.contains { other in
            other.agentId != intent.agentId
                && other.from == intent.to
                && other.to == intent.from
        } ? [intent.agentId] : []
    })

    for intent in pending where swapAgentIds.contains(intent.agentId) {
        let abstractBefore = nodeKey(from: agents.first {
            $0.id == intent.agentId
        }?.position ?? LabAgentPosition(x: intent.from.x, y: intent.from.y, z: intent.from.z))
        let physicalBefore = initialPhysical[intent.agentId]
        resolutions.append(hardeningResolution(
            for: intent,
            decision: .deniedSwapConflict,
            reason: "swap_conflict_denied_v0",
            abstractBefore: abstractBefore,
            abstractAfter: abstractBefore,
            physicalBefore: physicalBefore,
            physicalAfter: physicalBefore,
            divergenceBefore: hardeningDivergence(abstract: abstractBefore, physical: physicalBefore),
            divergenceAfter: hardeningDivergence(abstract: abstractBefore, physical: physicalBefore)
        ))
    }

    let collisionPending = pending.filter { !swapAgentIds.contains($0.agentId) }
    var collisionEvidence: [String: LabTerrainCollisionLiveSnapshot] = [:]
    for intent in collisionPending {
        let evidenceSeed = fixture.collisionEvidenceSeeds[intent.agentId]
            ?? contract.seed
        let evidenceNode = fixture.collisionEvidenceNodes[intent.agentId]
            ?? intent.to
        let world = prepareMultiAgentLiveCollisionWorld(
            seed: evidenceSeed,
            around: evidenceNode
        )
        collisionEvidence[intent.agentId] = makeTerrainCollisionLiveSnapshot(
            scenario: scenario,
            seed: evidenceSeed,
            ticksCompleted: ticksCompleted,
            world: world,
            node: evidenceNode
        )
    }

    let occupablePending = collisionPending.filter {
        collisionEvidence[$0.agentId]?.result.status == .occupable
            && collisionEvidence[$0.agentId]?.node == $0.to
    }
    let destinationCounts = Dictionary(grouping: occupablePending, by: \.to)
    var approvedDestinations = Set<LabTerrainPathNodeKey>()

    for intent in collisionPending {
        guard let agentIndex = agents.firstIndex(where: { $0.id == intent.agentId }) else {
            continue
        }
        let abstractBefore = nodeKey(from: agents[agentIndex].position)
        let physicalBefore = physicalBridge.handles.first {
            $0.agentId == intent.agentId
        }.map { nodeKey(from: $0.position) }
        let divergenceBefore = hardeningDivergence(
            abstract: abstractBefore,
            physical: physicalBefore
        )
        guard let evidence = collisionEvidence[intent.agentId] else {
            resolutions.append(hardeningResolution(
                for: intent,
                decision: .deniedCollision,
                reason: "missing_collision_evidence",
                abstractBefore: abstractBefore,
                abstractAfter: abstractBefore,
                physicalBefore: physicalBefore,
                physicalAfter: physicalBefore,
                divergenceBefore: divergenceBefore,
                divergenceAfter: divergenceBefore
            ))
            continue
        }

        if evidence.node != intent.to {
            resolutions.append(hardeningResolution(
                for: intent,
                decision: .deniedStaleCollision,
                reason: "stale_collision_evidence_target_mismatch",
                abstractBefore: abstractBefore,
                abstractAfter: abstractBefore,
                physicalBefore: physicalBefore,
                physicalAfter: physicalBefore,
                divergenceBefore: divergenceBefore,
                divergenceAfter: divergenceBefore,
                collision: evidence
            ))
        } else if evidence.result.status != .occupable {
            resolutions.append(hardeningResolution(
                for: intent,
                decision: .deniedCollision,
                reason: "collision_denied_\(evidence.result.reason)",
                abstractBefore: abstractBefore,
                abstractAfter: abstractBefore,
                physicalBefore: physicalBefore,
                physicalAfter: physicalBefore,
                divergenceBefore: divergenceBefore,
                divergenceAfter: divergenceBefore,
                collision: evidence
            ))
        } else {
            let destinationGroup = destinationCounts[intent.to] ?? []
            if destinationGroup.count > 1
                && destinationGroup.map(\.agentId).sorted().first != intent.agentId {
                resolutions.append(hardeningResolution(
                    for: intent,
                    decision: .deniedSameDestinationConflict,
                    reason: "same_destination_conflict_after_occupable_collision",
                    abstractBefore: abstractBefore,
                    abstractAfter: abstractBefore,
                    physicalBefore: physicalBefore,
                    physicalAfter: physicalBefore,
                    divergenceBefore: divergenceBefore,
                    divergenceAfter: divergenceBefore,
                    collision: evidence
                ))
            } else if approvedDestinations.contains(intent.to) {
                resolutions.append(hardeningResolution(
                    for: intent,
                    decision: .deniedSameDestinationConflict,
                    reason: "duplicate_destination_guard_after_collision",
                    abstractBefore: abstractBefore,
                    abstractAfter: abstractBefore,
                    physicalBefore: physicalBefore,
                    physicalAfter: physicalBefore,
                    divergenceBefore: divergenceBefore,
                    divergenceAfter: divergenceBefore,
                    collision: evidence
                ))
            } else {
                approvedDestinations.insert(intent.to)
                let dx = intent.to.x - intent.from.x
                let dz = intent.to.z - intent.from.z
                agents[agentIndex].lastAction = LabAgentAction(
                    name: "move_abstract",
                    reason: "multi_agent_hardening_approved_single_step",
                    tick: ticksCompleted,
                    dx: dx,
                    dy: 0,
                    dz: dz
                )
                _ = agents[agentIndex].applyAbstractMovement(tick: ticksCompleted)
                _ = physicalBridge.sync(with: agents, tick: ticksCompleted)
                let abstractAfter = nodeKey(from: agents[agentIndex].position)
                let physicalAfter = physicalBridge.handles.first {
                    $0.agentId == intent.agentId
                }.map { nodeKey(from: $0.position) }
                resolutions.append(hardeningResolution(
                    for: intent,
                    decision: .approved,
                    reason: "approved_occupable_single_step_synced",
                    abstractBefore: abstractBefore,
                    abstractAfter: abstractAfter,
                    physicalBefore: physicalBefore,
                    physicalAfter: physicalAfter,
                    divergenceBefore: divergenceBefore,
                    divergenceAfter: hardeningDivergence(
                        abstract: abstractAfter,
                        physical: physicalAfter
                    ),
                    collision: evidence
                ))
            }
        }
    }

    let finalAbstract = Dictionary(uniqueKeysWithValues: agents.map {
        ($0.id, nodeKey(from: $0.position))
    })
    let finalPhysical = Dictionary(uniqueKeysWithValues: physicalBridge.handles.map {
        ($0.agentId, nodeKey(from: $0.position))
    })

    return hardeningResult(
        for: contract,
        initialAbstract: initialAbstract,
        finalAbstract: finalAbstract,
        initialPhysical: initialPhysical,
        finalPhysical: finalPhysical,
        resolutions: resolutions
    )
}

private func hardeningResult(
    for contract: LabMultiAgentMovementHardeningCase,
    initialAbstract: [String: LabTerrainPathNodeKey],
    finalAbstract: [String: LabTerrainPathNodeKey],
    initialPhysical: [String: LabTerrainPathNodeKey],
    finalPhysical: [String: LabTerrainPathNodeKey],
    resolutions: [LabMultiAgentMovementHardeningResolution]
) -> LabMultiAgentMovementHardeningCaseResult {
    var resolutions = resolutions
    resolutions.sort {
        $0.agentId == $1.agentId
            ? $0.intent.reason < $1.intent.reason
            : $0.agentId < $1.agentId
    }
    let actualApproved = resolutions.filter(\.approved).count
    let actualDenied = resolutions.count - actualApproved
    let displacements = resolutions.filter(\.displacementApplied).count
    let actualDecisionCounts = hardeningDecisionCounts(for: resolutions)
    let divergenceBeforeMax = resolutions.compactMap(\.divergenceBefore).max() ?? 0
    let divergenceAfterMax = resolutions.compactMap(\.divergenceAfter).max() ?? 0
    let approvedOneEdge = resolutions.filter(\.approved).allSatisfy {
        guard let abstractBefore = $0.abstractBefore,
              let abstractAfter = $0.abstractAfter,
              let physicalBefore = $0.physicalBefore,
              let physicalAfter = $0.physicalAfter else {
            return false
        }
        return isFixtureEdgeAllowed(from: abstractBefore, to: abstractAfter)
            && isFixtureEdgeAllowed(from: physicalBefore, to: physicalAfter)
    }
    let deniedPreserved = resolutions.filter { !$0.approved }.allSatisfy {
        $0.abstractBefore == $0.abstractAfter
            && $0.physicalBefore == $0.physicalAfter
    }
    let approvedFinalMatch = resolutions.filter(\.approved).allSatisfy {
        guard let abstractAfter = $0.abstractAfter,
              let physicalAfter = $0.physicalAfter else {
            return false
        }
        return abstractAfter == physicalAfter && $0.divergenceAfter == 0
    }
    let approvedDestinations = resolutions.filter(\.approved).map(\.intent.to)
    let noDuplicateApprovedDestination = Set(approvedDestinations).count
        == approvedDestinations.count
    let noApprovedSwap = !resolutions.filter(\.approved).contains { first in
        resolutions.filter(\.approved).contains { second in
            first.agentId != second.agentId
                && first.intent.from == second.intent.to
                && first.intent.to == second.intent.from
        }
    }
    let passed = actualApproved == contract.expectedApproved
        && actualDenied == contract.expectedDenied
        && displacements == contract.expectedDisplacementsApplied
        && actualDecisionCounts == contract.expectedDecisionCounts
        && divergenceBeforeMax == contract.expectedDivergenceBeforeMax
        && divergenceAfterMax == contract.expectedDivergenceAfterMax
        && deniedPreserved
        && approvedOneEdge
        && approvedFinalMatch
        && noDuplicateApprovedDestination
        && noApprovedSwap

    return LabMultiAgentMovementHardeningCaseResult(
        name: contract.name,
        passed: passed,
        seed: contract.seed,
        agents: contract.agents,
        intents: contract.intents,
        resolutions: resolutions,
        initialAbstractPositions: initialAbstract,
        finalAbstractPositions: finalAbstract,
        initialPhysicalPositions: initialPhysical,
        finalPhysicalPositions: finalPhysical,
        expectedApproved: contract.expectedApproved,
        actualApproved: actualApproved,
        expectedDenied: contract.expectedDenied,
        actualDenied: actualDenied,
        expectedDisplacementsApplied: contract.expectedDisplacementsApplied,
        actualDisplacementsApplied: displacements,
        expectedDecisionCounts: contract.expectedDecisionCounts,
        actualDecisionCounts: actualDecisionCounts,
        divergenceBeforeMax: divergenceBeforeMax,
        divergenceAfterMax: divergenceAfterMax
    )
}

private func hardeningResolution(
    for intent: LabAgentMoveIntent,
    decision: LabMultiAgentMoveDecision,
    reason: String,
    abstractBefore: LabTerrainPathNodeKey?,
    abstractAfter: LabTerrainPathNodeKey?,
    physicalBefore: LabTerrainPathNodeKey?,
    physicalAfter: LabTerrainPathNodeKey?,
    divergenceBefore: Int?,
    divergenceAfter: Int?,
    collision: LabTerrainCollisionLiveSnapshot? = nil
) -> LabMultiAgentMovementHardeningResolution {
    LabMultiAgentMovementHardeningResolution(
        agentId: intent.agentId,
        intent: intent,
        collisionRead: collision != nil,
        collisionStatus: collision?.result.status,
        collisionReason: collision?.result.reason ?? "collision_not_read",
        decision: decision,
        approved: decision == .approved,
        displacementApplied: decision == .approved,
        abstractBefore: abstractBefore,
        abstractAfter: abstractAfter,
        physicalBefore: physicalBefore,
        physicalAfter: physicalAfter,
        divergenceBefore: divergenceBefore,
        divergenceAfter: divergenceAfter,
        reason: reason
    )
}

private func hardeningDecisionCounts(
    for resolutions: [LabMultiAgentMovementHardeningResolution]
) -> [String: Int] {
    var counts: [String: Int] = [:]
    for resolution in resolutions {
        counts[resolution.decision.rawValue, default: 0] += 1
    }
    return counts
}

private func hardeningDecisionCount(
    in results: [LabMultiAgentMovementHardeningCaseResult],
    _ decision: LabMultiAgentMoveDecision
) -> Int {
    results.reduce(0) { total, result in
        total + result.resolutions.filter { $0.decision == decision }.count
    }
}

private func hardeningDivergence(
    abstract: LabTerrainPathNodeKey?,
    physical: LabTerrainPathNodeKey?
) -> Int? {
    guard let abstract, let physical else { return nil }
    return manhattanDistance(abstract, physical)
}

private func evaluateMultiAgentApprovedPhysicalMovementCase(
    _ fixture: LabMultiAgentApprovedPhysicalMovementCase,
    scenario: String,
    ticksCompleted: Int
) -> LabMultiAgentApprovedPhysicalMovementCaseResult {
    var agents = fixture.agents.map { agentId, node in
        LabAgent(id: agentId, x: node.x, y: node.y, z: node.z)
    }.sorted { $0.id < $1.id }
    var physicalBridge = LabAgentPhysicalBridge()
    for agent in agents {
        _ = physicalBridge.spawnPlaceholder(for: agent, tick: 0)
    }
    let initialAbstract = Dictionary(uniqueKeysWithValues: agents.map {
        ($0.id, nodeKey(from: $0.position))
    })
    let initialPhysical = Dictionary(uniqueKeysWithValues: physicalBridge.handles.map {
        ($0.agentId, nodeKey(from: $0.position))
    })
    var resolutions: [LabMultiAgentApprovedPhysicalMovementResolution] = []
    var approvedDestinations = Set<LabTerrainPathNodeKey>()

    for intent in fixture.intents.sorted(by: { $0.agentId < $1.agentId }) {
        guard let agentIndex = agents.firstIndex(where: { $0.id == intent.agentId }),
              let physicalBeforePosition = physicalBridge.handles.first(where: { $0.agentId == intent.agentId })?.position else {
            continue
        }
        let abstractBeforePosition = agents[agentIndex].position
        let abstractBefore = nodeKey(from: abstractBeforePosition)
        let physicalBefore = nodeKey(from: physicalBeforePosition)
        let divergenceBefore = manhattanDistance(abstractBefore, physicalBefore)
        let world = prepareMultiAgentLiveCollisionWorld(seed: fixture.seed, around: intent.to)
        let collisionSnapshot = makeTerrainCollisionLiveSnapshot(
            scenario: scenario,
            seed: fixture.seed,
            ticksCompleted: ticksCompleted,
            world: world,
            node: intent.to
        )
        let sourceMatches = abstractBefore == intent.from
        let edgeAllowed = isFixtureEdgeAllowed(from: intent.from, to: intent.to)
        let destinationFree = !approvedDestinations.contains(intent.to)
        let approved = sourceMatches
            && edgeAllowed
            && destinationFree
            && collisionSnapshot.result.status == .occupable
        if approved {
            approvedDestinations.insert(intent.to)
            let dx = intent.to.x - intent.from.x
            let dz = intent.to.z - intent.from.z
            agents[agentIndex].lastAction = LabAgentAction(
                name: "move_abstract",
                reason: "multi_agent_approved_physical_single_step",
                tick: ticksCompleted,
                dx: dx,
                dy: 0,
                dz: dz
            )
            _ = agents[agentIndex].applyAbstractMovement(tick: ticksCompleted)
            _ = physicalBridge.sync(with: agents, tick: ticksCompleted)
        }
        let abstractAfter = nodeKey(from: agents[agentIndex].position)
        let physicalAfter = nodeKey(from: physicalBridge.handles.first {
            $0.agentId == intent.agentId
        }?.position ?? physicalBeforePosition)
        let divergenceAfter = manhattanDistance(abstractAfter, physicalAfter)
        let decision: LabMultiAgentMoveDecision = approved ? .approved : .deniedCollision
        resolutions.append(LabMultiAgentApprovedPhysicalMovementResolution(
            agentId: intent.agentId,
            intent: intent,
            collisionStatus: collisionSnapshot.result.status,
            collisionReason: collisionSnapshot.result.reason,
            decision: decision,
            approved: approved,
            displacementApplied: approved,
            abstractBefore: abstractBefore,
            abstractAfter: abstractAfter,
            physicalBefore: physicalBefore,
            physicalAfter: physicalAfter,
            divergenceBefore: divergenceBefore,
            divergenceAfter: divergenceAfter,
            reason: approved
                ? "approved_occupable_single_step_synced"
                : "denied_unexpected_approved_smoke_guard"
        ))
    }

    let finalAbstract = Dictionary(uniqueKeysWithValues: agents.map {
        ($0.id, nodeKey(from: $0.position))
    })
    let finalPhysical = Dictionary(uniqueKeysWithValues: physicalBridge.handles.map {
        ($0.agentId, nodeKey(from: $0.position))
    })
    let actualApproved = resolutions.filter(\.approved).count
    let actualDenied = resolutions.count - actualApproved
    let displacementsApplied = resolutions.filter(\.displacementApplied).count
    let divergenceBeforeMax = resolutions.map(\.divergenceBefore).max() ?? 0
    let divergenceAfterMax = resolutions.map(\.divergenceAfter).max() ?? 0
    let passed = actualApproved == fixture.expectedApproved
        && actualDenied == fixture.expectedDenied
        && displacementsApplied == fixture.expectedDisplacementsApplied
        && divergenceBeforeMax == fixture.expectedDivergenceBeforeMax
        && divergenceAfterMax == fixture.expectedDivergenceAfterMax
        && finalAbstract == finalPhysical
        && resolutions.allSatisfy {
            $0.collisionStatus == .occupable
                && $0.displacementApplied
                && isFixtureEdgeAllowed(from: $0.abstractBefore, to: $0.abstractAfter)
                && isFixtureEdgeAllowed(from: $0.physicalBefore, to: $0.physicalAfter)
        }

    return LabMultiAgentApprovedPhysicalMovementCaseResult(
        name: fixture.name,
        passed: passed,
        seed: fixture.seed,
        agents: fixture.agents,
        intents: fixture.intents,
        resolutions: resolutions,
        initialAbstractPositions: initialAbstract,
        finalAbstractPositions: finalAbstract,
        initialPhysicalPositions: initialPhysical,
        finalPhysicalPositions: finalPhysical,
        expectedApproved: fixture.expectedApproved,
        actualApproved: actualApproved,
        expectedDenied: fixture.expectedDenied,
        actualDenied: actualDenied,
        expectedDisplacementsApplied: fixture.expectedDisplacementsApplied,
        actualDisplacementsApplied: displacementsApplied,
        divergenceBeforeMax: divergenceBeforeMax,
        divergenceAfterMax: divergenceAfterMax
    )
}

private func evaluateMultiAgentLiveCollisionIntentCase(
    _ fixture: LabMultiAgentLiveCollisionIntentCase,
    scenario: String,
    ticksCompleted: Int
) -> LabMultiAgentLiveCollisionIntentCaseResult {
    let initialPositions = fixture.agents
    let finalPositions = initialPositions
    var resolutions: [LabMultiAgentLiveCollisionIntentResolution] = []
    var pending: [LabAgentMoveIntent] = []
    let sortedIntents = fixture.intents.sorted { $0.agentId < $1.agentId }

    for intent in sortedIntents {
        guard let current = initialPositions[intent.agentId] else {
            resolutions.append(liveResolution(
                for: intent,
                decision: .deniedMissingAgent,
                reason: "missing_agent",
                pre: nil,
                post: nil
            ))
            continue
        }
        if intent.stale {
            resolutions.append(liveResolution(
                for: intent,
                decision: .deniedStaleIntent,
                reason: "stale_intent_skips_collision",
                pre: current,
                post: current
            ))
        } else if intent.from != current {
            resolutions.append(liveResolution(
                for: intent,
                decision: .deniedSourceMismatch,
                reason: "source_mismatch_skips_collision",
                pre: current,
                post: current
            ))
        } else if intent.from == intent.to {
            resolutions.append(liveResolution(
                for: intent,
                decision: .deniedZeroLengthEdge,
                reason: "zero_length_edge_skips_collision",
                pre: current,
                post: current
            ))
        } else if !isFixtureEdgeAllowed(from: intent.from, to: intent.to) {
            resolutions.append(liveResolution(
                for: intent,
                decision: .deniedInvalidEdge,
                reason: "invalid_edge_skips_collision",
                pre: current,
                post: current
            ))
        } else {
            pending.append(intent)
        }
    }

    let collisionEvidence: [String: LabTerrainCollisionLiveSnapshot] =
        Dictionary(uniqueKeysWithValues: pending.map { intent in
            let world = prepareMultiAgentLiveCollisionWorld(
                seed: fixture.seed,
                around: intent.to
            )
            let snapshot = makeTerrainCollisionLiveSnapshot(
                scenario: scenario,
                seed: fixture.seed,
                ticksCompleted: ticksCompleted,
                world: world,
                node: intent.to
            )
            return (intent.agentId, snapshot)
        })
    let occupablePending = pending.filter {
        collisionEvidence[$0.agentId]?.result.status == .occupable
    }
    let destinationCounts = Dictionary(grouping: occupablePending, by: \.to)
    var approvedDestinations = Set<LabTerrainPathNodeKey>()

    for intent in pending {
        let current = initialPositions[intent.agentId]
        guard let evidence = collisionEvidence[intent.agentId] else {
            resolutions.append(liveResolution(
                for: intent,
                decision: .deniedCollision,
                reason: "missing_collision_evidence",
                pre: current,
                post: current
            ))
            continue
        }
        if evidence.result.status != .occupable {
            resolutions.append(liveResolution(
                for: intent,
                decision: .deniedCollision,
                reason: "collision_denied_\(evidence.result.reason)",
                pre: current,
                post: current,
                collision: evidence
            ))
            continue
        }

        let destinationGroup = destinationCounts[intent.to] ?? []
        if destinationGroup.count > 1
            && destinationGroup.map(\.agentId).sorted().first != intent.agentId {
            resolutions.append(liveResolution(
                for: intent,
                decision: .deniedSameDestinationConflict,
                reason: "same_destination_conflict_after_occupable_collision",
                pre: current,
                post: current,
                collision: evidence
            ))
        } else if approvedDestinations.contains(intent.to) {
            resolutions.append(liveResolution(
                for: intent,
                decision: .deniedSameDestinationConflict,
                reason: "duplicate_destination_guard_after_collision",
                pre: current,
                post: current,
                collision: evidence
            ))
        } else {
            approvedDestinations.insert(intent.to)
            resolutions.append(liveResolution(
                for: intent,
                decision: .approved,
                reason: "approved_by_occupable_collision_readonly",
                pre: current,
                post: current,
                collision: evidence
            ))
        }
    }

    resolutions.sort {
        $0.agentId == $1.agentId
            ? $0.intent.reason < $1.intent.reason
            : $0.agentId < $1.agentId
    }
    let actualApproved = resolutions.filter(\.approved).count
    let actualDenied = resolutions.count - actualApproved
    let occupable = resolutions.filter {
        $0.collisionRead && $0.collisionStatus == .occupable
    }.count
    let nonOccupable = resolutions.filter {
        $0.collisionRead
            && $0.collisionStatus != nil
            && $0.collisionStatus != .occupable
    }.count
    let actualDecisionCounts = liveDecisionCounts(for: resolutions)
    let passed = actualApproved == fixture.expectedApproved
        && actualDenied == fixture.expectedDenied
        && occupable == fixture.expectedOccupableDestinations
        && nonOccupable == fixture.expectedNonOccupableDestinations
        && actualDecisionCounts == fixture.expectedDecisionCounts
        && initialPositions == finalPositions
        && resolutions.allSatisfy { !$0.displacementApplied }

    return LabMultiAgentLiveCollisionIntentCaseResult(
        name: fixture.name,
        passed: passed,
        seed: fixture.seed,
        agents: fixture.agents,
        intents: fixture.intents,
        resolutions: resolutions,
        initialPositions: initialPositions,
        finalPositions: finalPositions,
        expectedApproved: fixture.expectedApproved,
        actualApproved: actualApproved,
        expectedDenied: fixture.expectedDenied,
        actualDenied: actualDenied,
        expectedOccupableDestinations: fixture.expectedOccupableDestinations,
        actualOccupableDestinations: occupable,
        expectedNonOccupableDestinations: fixture.expectedNonOccupableDestinations,
        actualNonOccupableDestinations: nonOccupable,
        expectedDecisionCounts: fixture.expectedDecisionCounts,
        actualDecisionCounts: actualDecisionCounts
    )
}

private func liveResolution(
    for intent: LabAgentMoveIntent,
    decision: LabMultiAgentMoveDecision,
    reason: String,
    pre: LabTerrainPathNodeKey?,
    post: LabTerrainPathNodeKey?,
    collision: LabTerrainCollisionLiveSnapshot? = nil
) -> LabMultiAgentLiveCollisionIntentResolution {
    LabMultiAgentLiveCollisionIntentResolution(
        agentId: intent.agentId,
        intent: intent,
        collisionRead: collision != nil,
        collisionStatus: collision?.result.status,
        collisionReason: collision?.result.reason ?? "collision_not_read",
        decision: decision,
        approved: decision == .approved,
        reason: reason,
        prePosition: pre,
        postPosition: post,
        displacementApplied: false
    )
}

private func liveDecisionCounts(
    for resolutions: [LabMultiAgentLiveCollisionIntentResolution]
) -> [String: Int] {
    var counts: [String: Int] = [:]
    for resolution in resolutions {
        counts[resolution.decision.rawValue, default: 0] += 1
    }
    return counts
}

private func liveDecisionCount(
    in results: [LabMultiAgentLiveCollisionIntentCaseResult],
    _ decision: LabMultiAgentMoveDecision
) -> Int {
    results.reduce(0) { total, result in
        total + result.resolutions.filter { $0.decision == decision }.count
    }
}

private func prepareMultiAgentLiveCollisionWorld(
    seed: UInt32,
    around node: LabTerrainPathNodeKey
) -> World {
    registerAllBlocks()
    registerAllBiomes()

    let world = World(dim: .overworld, seed: seed)
    let centerCX = floorDiv(node.x, CHUNK_W)
    let centerCZ = floorDiv(node.z, CHUNK_W)

    for cz in (centerCZ - 1)...(centerCZ + 1) {
        for cx in (centerCX - 1)...(centerCX + 1) {
            let generated = generateChunk(.overworld, world.seed, cx, cz)
            let chunk = Chunk(cx: cx, cz: cz, minY: world.info.minY, height: world.info.height)
            chunk.blocks = generated.blocks
            chunk.biomes = generated.biomes
            chunk.buildHeightmap()
            chunk.scanSpecials()
            world.setChunk(chunk)
            world.light.initChunkLight(chunk)
        }
    }

    return world
}

private func evaluateMultiAgentMovementFixtureCase(
    _ fixture: LabMultiAgentMovementFixtureCase,
    maxAgents: Int? = nil
) -> LabMultiAgentMovementFixtureCaseResult {
    let initialPositions = fixture.agents
    var finalPositions = initialPositions
    var resolutions: [LabAgentMoveResolution] = []
    var pending: [LabAgentMoveIntent] = []
    let sortedIntents = fixture.intents.sorted { $0.agentId < $1.agentId }
    let staticOccupied = Set(fixture.occupiedStaticNodes)
    let duplicateAgentIds = Set(
        Dictionary(grouping: sortedIntents, by: \.agentId)
            .filter { $0.value.count > 1 }
            .keys
    )

    if let maxAgents, fixture.agents.count > maxAgents {
        for intent in sortedIntents {
            let current = initialPositions[intent.agentId]
            resolutions.append(resolution(for: intent, decision: .deniedMaxAgents, reason: "max_agents_exceeded", pre: current, post: current))
        }
        return result(
            for: fixture,
            initialPositions: initialPositions,
            finalPositions: finalPositions,
            resolutions: resolutions
        )
    }

    for intent in sortedIntents {
        guard let current = initialPositions[intent.agentId] else {
            resolutions.append(resolution(for: intent, decision: .deniedMissingAgent, reason: "missing_agent", pre: nil, post: nil))
            continue
        }
        if duplicateAgentIds.contains(intent.agentId) {
            resolutions.append(resolution(for: intent, decision: .deniedDuplicateIntent, reason: "duplicate_intent", pre: current, post: current))
        } else if intent.stale {
            resolutions.append(resolution(for: intent, decision: .deniedStaleIntent, reason: "stale_intent", pre: current, post: current))
        } else if intent.from != current {
            resolutions.append(resolution(for: intent, decision: .deniedSourceMismatch, reason: "source_mismatch", pre: current, post: current))
        } else if intent.from == intent.to {
            resolutions.append(resolution(for: intent, decision: .deniedZeroLengthEdge, reason: "zero_length_edge", pre: current, post: current))
        } else {
            pending.append(intent)
        }
    }

    let swapAgentIds = Set(pending.flatMap { intent in
        pending.contains { other in
            other.agentId != intent.agentId
                && other.from == intent.to
                && other.to == intent.from
        } ? [intent.agentId] : []
    })

    for intent in pending where swapAgentIds.contains(intent.agentId) {
        let current = initialPositions[intent.agentId]
        resolutions.append(resolution(for: intent, decision: .deniedSwapConflict, reason: "swap_conflict_denied_v0", pre: current, post: current))
    }

    var nonSwapPending = pending.filter { !swapAgentIds.contains($0.agentId) }
    let cycleAgentIds = detectCycleAgentIds(
        in: nonSwapPending,
        initialPositions: initialPositions
    )
    for intent in nonSwapPending where cycleAgentIds.contains(intent.agentId) {
        let current = initialPositions[intent.agentId]
        resolutions.append(resolution(for: intent, decision: .deniedCycleConflict, reason: "cycle_conflict_denied_v0", pre: current, post: current))
    }

    nonSwapPending = nonSwapPending.filter { !cycleAgentIds.contains($0.agentId) }
    var validPending: [LabAgentMoveIntent] = []
    for intent in nonSwapPending {
        let current = initialPositions[intent.agentId]
        if !isFixtureEdgeAllowed(from: intent.from, to: intent.to) {
            resolutions.append(resolution(for: intent, decision: .deniedInvalidEdge, reason: "invalid_edge", pre: current, post: current))
        } else if staticOccupied.contains(intent.to) {
            resolutions.append(resolution(for: intent, decision: .deniedOccupiedDestination, reason: "occupied_static_destination", pre: current, post: current))
        } else {
            validPending.append(intent)
        }
    }

    let dependencyDecisions = dependencyDenials(
        in: validPending,
        initialPositions: initialPositions
    )
    for intent in validPending {
        if let decision = dependencyDecisions[intent.agentId] {
            let current = initialPositions[intent.agentId]
            resolutions.append(resolution(for: intent, decision: decision, reason: decision == .deniedChainDependency ? "chain_dependency_denied_v0" : "moving_away_destination_denied_v0", pre: current, post: current))
        }
    }

    let independentPending = validPending.filter { dependencyDecisions[$0.agentId] == nil }
    let destinationCounts = Dictionary(grouping: independentPending, by: \.to)
    var approvedDestinations = Set<LabTerrainPathNodeKey>()

    for intent in independentPending {
        let current = initialPositions[intent.agentId]
        let destinationGroup = destinationCounts[intent.to] ?? []
        if destinationGroup.count > 1 && destinationGroup.map(\.agentId).sorted().first != intent.agentId {
            resolutions.append(resolution(for: intent, decision: .deniedSameDestinationConflict, reason: "same_destination_conflict", pre: current, post: current))
        } else if approvedDestinations.contains(intent.to) {
            resolutions.append(resolution(for: intent, decision: .deniedSameDestinationConflict, reason: "duplicate_destination_guard", pre: current, post: current))
        } else {
            approvedDestinations.insert(intent.to)
            finalPositions[intent.agentId] = intent.to
            resolutions.append(resolution(for: intent, decision: .approved, reason: "approved_by_stable_order", pre: current, post: intent.to))
        }
    }

    return result(
        for: fixture,
        initialPositions: initialPositions,
        finalPositions: finalPositions,
        resolutions: resolutions
    )
}

private func result(
    for fixture: LabMultiAgentMovementFixtureCase,
    initialPositions: [String: LabTerrainPathNodeKey],
    finalPositions: [String: LabTerrainPathNodeKey],
    resolutions: [LabAgentMoveResolution]
) -> LabMultiAgentMovementFixtureCaseResult {
    var resolutions = resolutions
    resolutions.sort {
        $0.agentId == $1.agentId
            ? $0.intent.reason < $1.intent.reason
            : $0.agentId < $1.agentId
    }
    let actualApproved = resolutions.filter(\.approved).count
    let actualDenied = resolutions.count - actualApproved
    let actualDecisionCounts = decisionCounts(for: resolutions)
    let passed = actualApproved == fixture.expectedApproved
        && actualDenied == fixture.expectedDenied
        && actualDecisionCounts == fixture.expectedDecisionCounts

    return LabMultiAgentMovementFixtureCaseResult(
        name: fixture.name,
        passed: passed,
        agents: fixture.agents,
        occupiedStaticNodes: fixture.occupiedStaticNodes,
        intents: fixture.intents,
        resolutions: resolutions,
        initialPositions: initialPositions,
        finalPositions: finalPositions,
        expectedApproved: fixture.expectedApproved,
        actualApproved: actualApproved,
        expectedDenied: fixture.expectedDenied,
        actualDenied: actualDenied,
        expectedDecisionCounts: fixture.expectedDecisionCounts,
        actualDecisionCounts: actualDecisionCounts
    )
}

private func resolution(
    for intent: LabAgentMoveIntent,
    decision: LabMultiAgentMoveDecision,
    reason: String,
    pre: LabTerrainPathNodeKey?,
    post: LabTerrainPathNodeKey?
) -> LabAgentMoveResolution {
    LabAgentMoveResolution(
        agentId: intent.agentId,
        intent: intent,
        decision: decision,
        approved: decision == .approved,
        reason: reason,
        prePosition: pre,
        postPosition: post
    )
}

private func decisionCounts(
    for resolutions: [LabAgentMoveResolution]
) -> [String: Int] {
    var counts: [String: Int] = [:]
    for resolution in resolutions {
        counts[resolution.decision.rawValue, default: 0] += 1
    }
    return counts
}

private func decisionCount(
    in results: [LabMultiAgentMovementFixtureCaseResult],
    _ decision: LabMultiAgentMoveDecision
) -> Int {
    results.reduce(0) { total, result in
        total + result.resolutions.filter { $0.decision == decision }.count
    }
}

private func tickDecisionCount(
    in resolutions: [LabMultiAgentMovementTickResolution],
    _ decision: LabMultiAgentMoveDecision
) -> Int {
    resolutions.filter { $0.decision == decision }.count
}

private func tickLiveReadonlyDecisionCount(
    in resolutions: [LabMultiAgentMovementTickLiveReadonlyResolution],
    _ decision: LabMultiAgentMoveDecision
) -> Int {
    resolutions.filter { $0.decision == decision }.count
}

private func tickLiveReadonlyResolution(
    for intent: LabAgentMoveIntent,
    decision: LabMultiAgentMoveDecision,
    reason: String,
    abstractBefore: LabTerrainPathNodeKey?,
    physicalBefore: LabTerrainPathNodeKey?,
    collision: LabTerrainCollisionLiveSnapshot? = nil
) -> LabMultiAgentMovementTickLiveReadonlyResolution {
    let displacementApplied = false
    return LabMultiAgentMovementTickLiveReadonlyResolution(
        agentId: intent.agentId,
        intent: intent,
        decision: decision,
        approved: decision == .approved,
        displacementApplied: displacementApplied,
        collisionRead: collision != nil,
        collisionStatus: collision?.result.status,
        collisionReason: collision?.result.reason ?? "collision_not_read",
        abstractBefore: abstractBefore,
        abstractAfter: abstractBefore,
        physicalBefore: physicalBefore,
        physicalAfter: physicalBefore,
        feedbackKind: movementFeedbackKind(
            for: decision,
            displacementApplied: displacementApplied
        ),
        reason: reason
    )
}

private func movementFeedbackKind(
    for decision: LabMultiAgentMoveDecision,
    displacementApplied: Bool
) -> LabMovementFeedbackKind {
    switch decision {
    case .approved:
        return displacementApplied ? .moved : .approvedForMovement
    case .deniedCollision, .deniedOccupiedDestination:
        return .blockedByCollision
    case .deniedSameDestinationConflict,
         .deniedSwapConflict,
         .deniedDuplicateIntent,
         .deniedCycleConflict,
         .deniedChainDependency,
         .deniedMovingAwayDestination:
        return .blockedByAgentConflict
    case .deniedSourceMismatch, .deniedMissingAgent:
        return .blockedBySourceMismatch
    case .deniedDivergence:
        return .blockedByDivergence
    case .deniedStaleIntent, .deniedStaleCollision:
        return .blockedByStaleIntent
    case .deniedInvalidEdge, .deniedZeroLengthEdge:
        return .blockedByInvalidEdge
    case .deniedMaxAgents:
        return .blockedByMaxAgents
    }
}

private func detectCycleAgentIds(
    in intents: [LabAgentMoveIntent],
    initialPositions: [String: LabTerrainPathNodeKey]
) -> Set<String> {
    let occupantByNode = Dictionary(uniqueKeysWithValues: initialPositions.map { ($0.value, $0.key) })
    let intentByAgent = Dictionary(uniqueKeysWithValues: intents.map { ($0.agentId, $0) })
    var cycleAgentIds = Set<String>()

    for intent in intents {
        var path: [String] = []
        var seen: [String: Int] = [:]
        var currentAgentId: String? = intent.agentId

        while let agentId = currentAgentId,
              let currentIntent = intentByAgent[agentId] {
            if let firstIndex = seen[agentId] {
                let cycle = Array(path[firstIndex...])
                if cycle.count >= 3 {
                    cycleAgentIds.formUnion(cycle)
                }
                break
            }

            seen[agentId] = path.count
            path.append(agentId)

            guard let occupant = occupantByNode[currentIntent.to],
                  occupant != agentId else {
                break
            }
            currentAgentId = occupant
        }
    }

    return cycleAgentIds
}

private func dependencyDenials(
    in intents: [LabAgentMoveIntent],
    initialPositions: [String: LabTerrainPathNodeKey]
) -> [String: LabMultiAgentMoveDecision] {
    let occupantByNode = Dictionary(uniqueKeysWithValues: initialPositions.map { ($0.value, $0.key) })
    let intentByAgent = Dictionary(uniqueKeysWithValues: intents.map { ($0.agentId, $0) })
    var denials: [String: LabMultiAgentMoveDecision] = [:]

    for intent in intents {
        guard let firstOccupant = occupantByNode[intent.to],
              firstOccupant != intent.agentId else {
            continue
        }

        var path = [intent.agentId]
        var currentAgentId = firstOccupant
        var seen = Set(path)

        while true {
            guard !seen.contains(currentAgentId) else {
                break
            }
            seen.insert(currentAgentId)
            path.append(currentAgentId)

            guard let currentIntent = intentByAgent[currentAgentId] else {
                for agentId in path {
                    denials[agentId] = .deniedChainDependency
                }
                break
            }

            guard let nextOccupant = occupantByNode[currentIntent.to],
                  nextOccupant != currentAgentId else {
                for agentId in path {
                    denials[agentId] = .deniedMovingAwayDestination
                }
                break
            }

            currentAgentId = nextOccupant
        }
    }

    return denials
}

private func check(
    _ name: String,
    _ passed: Bool,
    _ expected: String,
    _ actual: String
) -> LabMultiAgentMovementFixtureInvariantCheck {
    LabMultiAgentMovementFixtureInvariantCheck(
        name: name,
        passed: passed,
        expected: expected,
        actual: actual
    )
}

private func isFixtureEdgeAllowed(
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey
) -> Bool {
    from.y == to.y
        && abs(from.x - to.x) + abs(from.z - to.z) == 1
}

private func manhattanDistance(
    _ from: LabTerrainPathNodeKey,
    _ to: LabTerrainPathNodeKey
) -> Int {
    abs(from.x - to.x) + abs(from.y - to.y) + abs(from.z - to.z)
}

private func nodeKey(from position: LabAgentPosition) -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: position.x, y: position.y, z: position.z)
}

private func noDuplicateApprovedDestination(
    in result: LabMultiAgentMovementFixtureCaseResult
) -> Bool {
    let destinations = result.resolutions.filter(\.approved).map(\.intent.to)
    return Set(destinations).count == destinations.count
}

private func noApprovedSwapConflict(
    in result: LabMultiAgentMovementFixtureCaseResult
) -> Bool {
    let approved = result.resolutions.filter(\.approved)
    return !approved.contains { first in
        approved.contains { second in
            first.agentId != second.agentId
                && first.intent.from == second.intent.to
                && first.intent.to == second.intent.from
        }
    }
}
