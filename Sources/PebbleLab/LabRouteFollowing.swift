enum LabRouteFollowingStatus: String, Codable {
    case completed
    case stoppedCollisionDenied
    case stoppedInvalidEdge
    case stoppedSourceMismatch
    case stoppedDivergence
    case stoppedMissingPhysicalHandle
    case stoppedStalePath
    case stoppedStaleCollision
    case stoppedMaxSteps
    case stoppedUnexpectedMutation
}

struct LabRouteFollowingFixtureEdge: Codable {
    let from: LabTerrainPathNodeKey
    let to: LabTerrainPathNodeKey
    let collisionStatus: LabTerrainOccupancyStatus
    let singleStepStatus: LabPhysicalMovementStatus
    let displacementApplied: Bool
    let reason: String
}

struct LabRouteFollowingEdgeRecord: Codable {
    let edgeIndex: Int
    let from: LabTerrainPathNodeKey
    let to: LabTerrainPathNodeKey
    let collisionStatus: LabTerrainOccupancyStatus
    let collisionReason: String
    let singleStepStatus: LabPhysicalMovementStatus
    let routeStatusAfterEdge: LabRouteFollowingStatus
    let displacementApplied: Bool
    let preNode: LabTerrainPathNodeKey
    let postNode: LabTerrainPathNodeKey
    let divergenceBefore: Int
    let divergenceAfter: Int
    let success: Bool
}

struct LabRouteFollowingFixtureCase: Codable {
    let name: String
    let initialNode: LabTerrainPathNodeKey
    let route: [LabTerrainPathNodeKey]
    let edges: [LabRouteFollowingFixtureEdge]
    let maxSteps: Int
    let expectedStatus: LabRouteFollowingStatus
    let expectedCompletedEdges: Int
    let expectedStoppedAtIndex: Int?
    let expectedReasonContains: String
}

struct LabRouteFollowingFixtureCaseResult: Codable {
    let name: String
    let expectedStatus: LabRouteFollowingStatus
    let actualStatus: LabRouteFollowingStatus
    let expectedCompletedEdges: Int
    let actualCompletedEdges: Int
    let expectedStoppedAtIndex: Int?
    let actualStoppedAtIndex: Int?
    let expectedReasonContains: String
    let actualReason: String
    let finalNode: LabTerrainPathNodeKey
    let passed: Bool
    let records: [LabRouteFollowingEdgeRecord]
}

struct LabRouteFollowingFixtureSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let completed: Int
    let stopped: Int
    let attemptedEdges: Int
    let completedEdges: Int
    let displacementsApplied: Int
    let deniedEdges: Int
    let collisionDenied: Int
    let invalidEdges: Int
    let sourceMismatch: Int
    let divergence: Int
    let maxSteps: Int
    let success: Bool
}

struct LabRouteFollowingFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: LabRouteFollowingFixtureSummary
    let cases: [LabRouteFollowingFixtureCaseResult]
}

struct RouteFollowingFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: RouteFollowingFixtureInvariantSummary
    let checks: [RouteFollowingFixtureInvariantCheck]
    let notes: [String]
}

struct RouteFollowingFixtureInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let passed: Int
    let failed: Int
}

struct RouteFollowingFixtureInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

struct LabRouteFollowingLiveEdgeRecord: Codable {
    let edgeIndex: Int
    let from: LabTerrainPathNodeKey
    let to: LabTerrainPathNodeKey
    let collisionSnapshot: LabTerrainCollisionLiveSnapshot
    let collisionStatus: LabTerrainOccupancyStatus
    let collisionReason: String
    let singleStepStatus: LabPhysicalMovementStatus
    let routeStatusAfterEdge: LabRouteFollowingStatus
    let displacementApplied: Bool
    let preAbstractPosition: LabAgentPosition
    let postAbstractPosition: LabAgentPosition
    let prePhysicalPosition: LabAgentPosition
    let postPhysicalPosition: LabAgentPosition
    let divergenceBefore: Int
    let divergenceAfter: Int
    let success: Bool
}

struct LabRouteFollowingLiveSnapshot: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let agentId: String?
    let physicalId: String?
    let coreEntityId: Int?
    let route: [LabTerrainPathNodeKey]
    let startNode: LabTerrainPathNodeKey
    let finalNode: LabTerrainPathNodeKey
    let currentIndex: Int
    let targetIndex: Int?
    let attemptedEdges: Int
    let completedEdges: Int
    let displacementsApplied: Int
    let deniedEdges: Int
    let stoppedAtIndex: Int?
    let status: LabRouteFollowingStatus
    let reason: String
    let perEdgeRecords: [LabRouteFollowingLiveEdgeRecord]
    let finalAbstractPosition: LabAgentPosition
    let finalPhysicalPosition: LabAgentPosition
    let finalCoreEntityPosition: LabAgentPosition?
    let divergenceBefore: Int
    let divergenceAfter: Int
    let pathfindingPerformedInsideFollower: Bool
    let replanningPerformed: Bool
    let routeFollowingPerformed: Bool
    let physicsPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct RouteFollowingLiveInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: RouteFollowingLiveInvariantSummary
    let checks: [RouteFollowingLiveInvariantCheck]
    let notes: [String]
}

struct RouteFollowingLiveInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let attemptedEdges: Int
    let completedEdges: Int
    let deniedEdges: Int
}

struct RouteFollowingLiveInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

struct LabRouteFollowingLiveHardeningCase: Codable {
    let name: String
    let expectedStatus: LabRouteFollowingStatus
    let expectedAttemptedEdges: Int
    let expectedCompletedEdges: Int
    let expectedDisplacementsApplied: Int
    let expectedDeniedEdges: Int
    let expectedStoppedAtIndex: Int?
    let expectedReasonContains: String
}

struct LabRouteFollowingLiveHardeningCaseResult: Codable {
    let name: String
    let expectedStatus: LabRouteFollowingStatus
    let actualStatus: LabRouteFollowingStatus
    let expectedAttemptedEdges: Int
    let actualAttemptedEdges: Int
    let expectedCompletedEdges: Int
    let actualCompletedEdges: Int
    let expectedDisplacementsApplied: Int
    let actualDisplacementsApplied: Int
    let expectedDeniedEdges: Int
    let actualDeniedEdges: Int
    let expectedStoppedAtIndex: Int?
    let actualStoppedAtIndex: Int?
    let expectedReasonContains: String
    let actualReason: String
    let passed: Bool
    let snapshot: LabRouteFollowingLiveSnapshot
}

struct LabRouteFollowingLiveHardeningSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let completed: Int
    let stopped: Int
    let attemptedEdges: Int
    let completedEdges: Int
    let displacementsApplied: Int
    let deniedEdges: Int
    let collisionDenied: Int
    let invalidEdges: Int
    let sourceMismatch: Int
    let divergence: Int
    let staleCollision: Int
    let maxSteps: Int
    let success: Bool
}

struct LabRouteFollowingLiveHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: LabRouteFollowingLiveHardeningSummary
    let cases: [LabRouteFollowingLiveHardeningCaseResult]
}

struct RouteFollowingLiveHardeningInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: RouteFollowingLiveHardeningInvariantSummary
    let checks: [RouteFollowingLiveHardeningInvariantCheck]
    let notes: [String]
}

struct RouteFollowingLiveHardeningInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let passed: Int
    let failed: Int
}

struct RouteFollowingLiveHardeningInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}
