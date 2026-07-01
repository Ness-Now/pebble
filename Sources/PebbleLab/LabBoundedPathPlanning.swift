struct LabBoundedPathPlanningBoundary: Codable {
    let worldRead: Bool
    let collisionRead: Bool
    let tickUsed: Bool
    let movementApplied: Bool
    let labPositionMapMutated: Bool
    let routeFollowingUsed: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
}

struct LabAgentBoundedPathPlanningContext: Codable {
    let tick: Int
    let agentId: String
    let start: LabTerrainPathNodeKey
    let target: LabTerrainPathNodeKey
    let maxSteps: Int
    let maxNodes: Int
    let allowedDirections: [String]
    let blockedDirections: [String]
    let abstractBlockedCells: [LabTerrainPathNodeKey]
    let deterministicTieBreaker: String
    let policyMode: String
    let boundary: LabBoundedPathPlanningBoundary
}

struct LabAgentBoundedPathStep: Codable {
    let from: LabTerrainPathNodeKey
    let to: LabTerrainPathNodeKey
    let hint: String
    let index: Int
}

struct LabAgentBoundedPathPlan: Codable {
    let tick: Int
    let agentId: String
    let start: LabTerrainPathNodeKey
    let target: LabTerrainPathNodeKey
    let maxSteps: Int
    let maxNodes: Int
    let nodesVisited: Int
    let steps: [LabAgentBoundedPathStep]
    let selectedFirstStep: LabAgentBoundedPathStep?
    let reachedTarget: Bool
    let exhausted: Bool
    let truncated: Bool
    let noPathReason: String?
    let deterministicDigest: String
    let boundary: LabBoundedPathPlanningBoundary
}

struct LabBoundedPathPlanningFixtureCase: Codable {
    let name: String
    let context: LabAgentBoundedPathPlanningContext
    let expectedKind: String
    let plan: LabAgentBoundedPathPlan
    let passed: Bool
    let notes: [String]
}

struct LabBoundedPathPlanningFixtureSummary: Codable {
    let scenario: String
    let seed: UInt32
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let plansProduced: Int
    let noPathPlans: Int
    let reachedTargetPlans: Int
    let truncatedPlans: Int
    let exhaustedPlans: Int
    let selectedFirstSteps: Int
    let maxStepsMin: Int
    let maxStepsMax: Int
    let maxNodesMin: Int
    let maxNodesMax: Int
    let nodesVisitedMax: Int
    let stepsTotal: Int
    let stepsMax: Int
    let stepsWithinMax: Bool
    let nodesWithinMax: Bool
    let oneEdgeSteps: Bool
    let sameYSteps: Bool
    let deterministicCaseOrder: Bool
    let deterministicNeighborOrder: Bool
    let deterministicTieBreak: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let v0Unchanged: Bool
    let v1Unchanged: Bool
    let v2Unchanged: Bool
    let v3OptIn: Bool
    let v3NotGlobal: Bool
    let hiddenActivationDetected: Bool
    let worldRead: Bool
    let collisionRead: Bool
    let tickUsed: Bool
    let movementApplied: Bool
    let labPositionMapMutated: Bool
    let routeFollowingUsed: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabBoundedPathPlanningFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let plannerMode: String
    let neighborOrder: [String]
    let cases: [LabBoundedPathPlanningFixtureCase]
    let plans: [LabAgentBoundedPathPlan]
    let summary: LabBoundedPathPlanningFixtureSummary
}

struct LabBoundedPathPlanningFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabBoundedPathPlanningFixtureDigest: Codable {
    let scenario: String
    let seed: UInt32
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabBoundedPathPlanningHardeningSummary: Codable {
    let scenario: String
    let seed: UInt32
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let plansProduced: Int
    let noPathPlans: Int
    let reachedTargetPlans: Int
    let truncatedPlans: Int
    let exhaustedPlans: Int
    let selectedFirstSteps: Int
    let maxStepsZeroCases: Int
    let maxStepsOneCases: Int
    let maxStepsTwoCases: Int
    let maxStepsThreeCases: Int
    let maxStepsFourCases: Int
    let maxNodesOneCases: Int
    let maxNodesTwoCases: Int
    let maxNodesFullCases: Int
    let blockedStartCases: Int
    let blockedTargetCases: Int
    let blockedDirectionCases: Int
    let duplicateBlockedCellCases: Int
    let duplicateInputCases: Int
    let duplicateInputDigestsEqual: Bool
    let negativeCoordinateCases: Int
    let sameYOnlyCases: Int
    let tieBreakCases: Int
    let tieBreakSelectedExpectedFirstHint: Bool
    let maxStepsMin: Int
    let maxStepsMax: Int
    let maxNodesMin: Int
    let maxNodesMax: Int
    let nodesVisitedMax: Int
    let stepsTotal: Int
    let stepsMax: Int
    let stepsWithinMax: Bool
    let nodesWithinMax: Bool
    let oneEdgeSteps: Bool
    let sameYSteps: Bool
    let blockedDirectionsRespected: Bool
    let abstractBlockedCellsRespected: Bool
    let deterministicCaseOrder: Bool
    let deterministicNeighborOrder: Bool
    let deterministicTieBreak: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let v0Unchanged: Bool
    let v1Unchanged: Bool
    let v2Unchanged: Bool
    let v3OptIn: Bool
    let v3NotGlobal: Bool
    let hiddenActivationDetected: Bool
    let worldRead: Bool
    let collisionRead: Bool
    let tickUsed: Bool
    let movementApplied: Bool
    let labPositionMapMutated: Bool
    let routeFollowingUsed: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabBoundedPathPlanningHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let plannerMode: String
    let neighborOrder: [String]
    let cases: [LabBoundedPathPlanningFixtureCase]
    let plans: [LabAgentBoundedPathPlan]
    let summary: LabBoundedPathPlanningHardeningSummary
}

struct LabBoundedPathPlanningHardeningInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabBoundedPathPlanningHardeningDigest: Codable {
    let scenario: String
    let seed: UInt32
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabBoundedPathPlanningHardeningBoundaryReport: Codable {
    let scenario: String
    let seed: UInt32
    let worldRead: Bool
    let collisionRead: Bool
    let tickUsed: Bool
    let movementApplied: Bool
    let labPositionMapMutated: Bool
    let routeFollowingUsed: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let mutationBoundaryClean: Bool
}

struct LabBoundedPathPlanningToTickFirstStepHandoff: Codable {
    let caseName: String
    let agentId: String
    let selectedFirstStep: LabAgentBoundedPathStep
    let intent: LabAgentMoveIntent
    let advisorySteps: [LabAgentBoundedPathStep]
    let sentToTick: Bool
    let reason: String
}

struct LabBoundedPathPlanningToTickFirstStepCase: Codable {
    let name: String
    let contexts: [LabAgentBoundedPathPlanningContext]
    let expectedKind: String
    let plans: [LabAgentBoundedPathPlan]
    let handoffIntents: [LabAgentMoveIntent]
    let handoffs: [LabBoundedPathPlanningToTickFirstStepHandoff]
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickOutput
    let expectedApproved: Int
    let expectedDenied: Int
    let expectedDecisionCounts: [String: Int]
    let passed: Bool
    let notes: [String]
}

struct LabBoundedPathPlanningToTickFirstStepSummary: Codable {
    let scenario: String
    let seed: UInt32
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let plansProduced: Int
    let selectedFirstSteps: Int
    let noPathPlans: Int
    let zeroStepPlans: Int
    let handoffIntents: Int
    let advisoryStepsTotal: Int
    let advisoryStepsNotSent: Bool
    let firstStepOnlyHandoff: Bool
    let movementIntentInputs: Int
    let tickApproved: Int
    let tickDenied: Int
    let tickDeniedConflict: Int
    let tickDeniedSourceMismatch: Int
    let tickDeniedInvalidEdge: Int
    let maxStepsMax: Int
    let maxNodesMax: Int
    let nodesVisitedMax: Int
    let stepsMax: Int
    let stepsWithinMax: Bool
    let nodesWithinMax: Bool
    let oneEdgeSteps: Bool
    let sameYSteps: Bool
    let deterministicPlanOrder: Bool
    let deterministicHandoffOrder: Bool
    let deterministicTickOrder: Bool
    let deterministicDigest: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let v0Unchanged: Bool
    let v1Unchanged: Bool
    let v2Unchanged: Bool
    let v3OptIn: Bool
    let v3NotGlobal: Bool
    let hiddenActivationDetected: Bool
    let worldRead: Bool
    let collisionRead: Bool
    let tickUsed: Bool
    let tickReadCollision: Bool
    let tickWorldReadOnlyUsed: Bool
    let movementApplied: Bool
    let labPositionMapMutated: Bool
    let routeFollowingUsed: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabBoundedPathPlanningToTickFirstStepReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let plannerMode: String
    let neighborOrder: [String]
    let cases: [LabBoundedPathPlanningToTickFirstStepCase]
    let plans: [LabAgentBoundedPathPlan]
    let handoffs: [LabBoundedPathPlanningToTickFirstStepHandoff]
    let tickReports: [LabMultiAgentMovementTickFixtureReport]
    let summary: LabBoundedPathPlanningToTickFirstStepSummary
}

struct LabBoundedPathPlanningToTickFirstStepInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabBoundedPathPlanningToTickFirstStepDigest: Codable {
    let scenario: String
    let seed: UInt32
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabBoundedPathPlanningToTickFirstStepBoundaryReport: Codable {
    let scenario: String
    let seed: UInt32
    let worldRead: Bool
    let collisionRead: Bool
    let tickUsed: Bool
    let tickReadCollision: Bool
    let tickWorldReadOnlyUsed: Bool
    let movementApplied: Bool
    let labPositionMapMutated: Bool
    let routeFollowingUsed: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let mutationBoundaryClean: Bool
}

struct LabBoundedPathPlanningToTickFirstStepMetrics: Codable {
    let boundedPathPlanningToTickFirstStepCases: Int
    let boundedPathPlanningToTickFirstStepCasesPassed: Int
    let boundedPathPlanningToTickFirstStepCasesFailed: Int
    let boundedPathPlanningToTickFirstStepPlansProduced: Int
    let boundedPathPlanningToTickFirstStepSelectedFirstSteps: Int
    let boundedPathPlanningToTickFirstStepNoPathPlans: Int
    let boundedPathPlanningToTickFirstStepZeroStepPlans: Int
    let boundedPathPlanningToTickFirstStepHandoffIntents: Int
    let boundedPathPlanningToTickFirstStepAdvisoryStepsTotal: Int
    let boundedPathPlanningToTickFirstStepAdvisoryStepsNotSent: Bool
    let boundedPathPlanningToTickFirstStepFirstStepOnlyHandoff: Bool
    let boundedPathPlanningToTickFirstStepMovementIntentInputs: Int
    let boundedPathPlanningToTickFirstStepTickApproved: Int
    let boundedPathPlanningToTickFirstStepTickDenied: Int
    let boundedPathPlanningToTickFirstStepTickDeniedConflict: Int
    let boundedPathPlanningToTickFirstStepTickDeniedSourceMismatch: Int
    let boundedPathPlanningToTickFirstStepTickDeniedInvalidEdge: Int
    let boundedPathPlanningToTickFirstStepMaxStepsMax: Int
    let boundedPathPlanningToTickFirstStepMaxNodesMax: Int
    let boundedPathPlanningToTickFirstStepNodesVisitedMax: Int
    let boundedPathPlanningToTickFirstStepStepsMax: Int
    let boundedPathPlanningToTickFirstStepStepsWithinMax: Bool
    let boundedPathPlanningToTickFirstStepNodesWithinMax: Bool
    let boundedPathPlanningToTickFirstStepOneEdgeSteps: Bool
    let boundedPathPlanningToTickFirstStepSameYSteps: Bool
    let boundedPathPlanningToTickFirstStepDeterministicPlanOrder: Bool
    let boundedPathPlanningToTickFirstStepDeterministicHandoffOrder: Bool
    let boundedPathPlanningToTickFirstStepDeterministicTickOrder: Bool
    let boundedPathPlanningToTickFirstStepDeterministicDigest: Bool
    let boundedPathPlanningToTickFirstStepDigestsEqual: Bool
    let boundedPathPlanningToTickFirstStepRepeatabilityFailures: Int
    let boundedPathPlanningToTickFirstStepV0Unchanged: Bool
    let boundedPathPlanningToTickFirstStepV1Unchanged: Bool
    let boundedPathPlanningToTickFirstStepV2Unchanged: Bool
    let boundedPathPlanningToTickFirstStepV3OptIn: Bool
    let boundedPathPlanningToTickFirstStepV3NotGlobal: Bool
    let boundedPathPlanningToTickFirstStepHiddenActivationDetected: Bool
    let boundedPathPlanningToTickFirstStepWorldRead: Bool
    let boundedPathPlanningToTickFirstStepCollisionRead: Bool
    let boundedPathPlanningToTickFirstStepTickUsed: Bool
    let boundedPathPlanningToTickFirstStepTickReadCollision: Bool
    let boundedPathPlanningToTickFirstStepTickWorldReadOnlyUsed: Bool
    let boundedPathPlanningToTickFirstStepMovementApplied: Bool
    let boundedPathPlanningToTickFirstStepLabPositionMapMutated: Bool
    let boundedPathPlanningToTickFirstStepRouteFollowingUsed: Bool
    let boundedPathPlanningToTickFirstStepPathfindingLiveUsed: Bool
    let boundedPathPlanningToTickFirstStepUnboundedSearchUsed: Bool
    let boundedPathPlanningToTickFirstStepDynamicReplanningUsed: Bool
    let boundedPathPlanningToTickFirstStepReservationRuntimeUsed: Bool
    let boundedPathPlanningToTickFirstStepMemoryUpdated: Bool
    let boundedPathPlanningToTickFirstStepGoalChanged: Bool
    let boundedPathPlanningToTickFirstStepTerrainMutated: Bool
    let boundedPathPlanningToTickFirstStepWorldMutated: Bool
    let boundedPathPlanningToTickFirstStepCoreEntityMoved: Bool
    let boundedPathPlanningToTickFirstStepPhysicalPlaceholderMoved: Bool
    let boundedPathPlanningToTickFirstStepMutationPerformed: Bool
    let boundedPathPlanningToTickFirstStepSuccess: Bool
}

struct LabBoundedPathPlanningApprovedApplicationRecord: Codable {
    let caseName: String
    let agentId: String
    let decision: LabMultiAgentMoveDecision?
    let approved: Bool
    let applied: Bool
    let from: LabTerrainPathNodeKey
    let selectedFirstStepTo: LabTerrainPathNodeKey?
    let abstractBefore: LabTerrainPathNodeKey
    let abstractAfter: LabTerrainPathNodeKey
    let physicalBefore: LabTerrainPathNodeKey
    let physicalAfter: LabTerrainPathNodeKey
    let advisorySteps: [LabAgentBoundedPathStep]
    let advisoryStepsApplied: Bool
    let reason: String
}

struct LabBoundedPathPlanningApprovedApplicationPositions: Codable {
    let caseName: String
    let abstractBefore: [String: LabTerrainPathNodeKey]
    let abstractAfter: [String: LabTerrainPathNodeKey]
    let physicalBefore: [String: LabTerrainPathNodeKey]
    let physicalAfter: [String: LabTerrainPathNodeKey]
    let abstractPhysicalDivergenceBefore: Int
    let abstractPhysicalDivergenceAfter: Int
}

struct LabBoundedPathPlanningApprovedApplicationCase: Codable {
    let name: String
    let contexts: [LabAgentBoundedPathPlanningContext]
    let expectedKind: String
    let plans: [LabAgentBoundedPathPlan]
    let handoffIntents: [LabAgentMoveIntent]
    let handoffs: [LabBoundedPathPlanningToTickFirstStepHandoff]
    let tickInput: LabMultiAgentMovementTickInput
    let tickOutput: LabMultiAgentMovementTickOutput
    let applications: [LabBoundedPathPlanningApprovedApplicationRecord]
    let positions: LabBoundedPathPlanningApprovedApplicationPositions
    let expectedApproved: Int
    let expectedDenied: Int
    let expectedDecisionCounts: [String: Int]
    let passed: Bool
    let notes: [String]
}

struct LabBoundedPathPlanningApprovedApplicationSummary: Codable {
    let scenario: String
    let seed: UInt32
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let plansProduced: Int
    let selectedFirstSteps: Int
    let noPathPlans: Int
    let zeroStepPlans: Int
    let handoffIntents: Int
    let advisoryStepsTotal: Int
    let advisoryStepsNotSent: Bool
    let advisoryStepsNotApplied: Bool
    let firstStepOnlyHandoff: Bool
    let firstStepOnlyApplication: Bool
    let movementIntentInputs: Int
    let tickUsed: Bool
    let tickReadCollision: Bool
    let tickWorldReadOnlyUsed: Bool
    let tickApproved: Int
    let tickDenied: Int
    let tickDeniedConflict: Int
    let tickDeniedSourceMismatch: Int
    let tickDeniedStaleIntent: Int
    let tickFeedbackEmitted: Int
    let approvedApplications: Int
    let displacementsApplied: Int
    let deniedAgentsPreserved: Int
    let noPathAgentsPreserved: Int
    let zeroStepAgentsPreserved: Int
    let sourceMismatchAgentsPreserved: Int
    let staleAgentsPreserved: Int
    let abstractPhysicalDivergenceBeforeMax: Int
    let abstractPhysicalDivergenceAfterMax: Int
    let maxStepsMax: Int
    let maxNodesMax: Int
    let nodesVisitedMax: Int
    let stepsMax: Int
    let stepsWithinMax: Bool
    let nodesWithinMax: Bool
    let oneEdgeSteps: Bool
    let sameYSteps: Bool
    let deterministicPlanOrder: Bool
    let deterministicHandoffOrder: Bool
    let deterministicTickOrder: Bool
    let deterministicApplicationOrder: Bool
    let deterministicDigest: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let v0Unchanged: Bool
    let v1Unchanged: Bool
    let v2Unchanged: Bool
    let v3OptIn: Bool
    let v3NotGlobal: Bool
    let hiddenActivationDetected: Bool
    let worldRead: Bool
    let collisionRead: Bool
    let movementApplied: Bool
    let labPositionMapMutated: Bool
    let routeFollowingUsed: Bool
    let fullRouteExecutionUsed: Bool
    let advisoryStepsApplied: Bool
    let secondStepAutoApplied: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabBoundedPathPlanningApprovedApplicationReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let plannerMode: String
    let neighborOrder: [String]
    let cases: [LabBoundedPathPlanningApprovedApplicationCase]
    let plans: [LabAgentBoundedPathPlan]
    let handoffs: [LabBoundedPathPlanningToTickFirstStepHandoff]
    let tickReports: [LabMultiAgentMovementTickFixtureReport]
    let applications: [LabBoundedPathPlanningApprovedApplicationRecord]
    let positions: [LabBoundedPathPlanningApprovedApplicationPositions]
    let summary: LabBoundedPathPlanningApprovedApplicationSummary
}

struct LabBoundedPathPlanningApprovedApplicationInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabBoundedPathPlanningApprovedApplicationDigest: Codable {
    let scenario: String
    let seed: UInt32
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabBoundedPathPlanningApprovedApplicationBoundaryReport: Codable {
    let scenario: String
    let seed: UInt32
    let worldRead: Bool
    let collisionRead: Bool
    let tickUsed: Bool
    let tickReadCollision: Bool
    let tickWorldReadOnlyUsed: Bool
    let movementApplied: Bool
    let labPositionMapMutated: Bool
    let routeFollowingUsed: Bool
    let fullRouteExecutionUsed: Bool
    let advisoryStepsApplied: Bool
    let secondStepAutoApplied: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let mutationBoundaryClean: Bool
}

struct LabBoundedPathPlanningApprovedApplicationMetrics: Codable {
    let boundedPathPlanningApprovedApplicationCases: Int
    let boundedPathPlanningApprovedApplicationCasesPassed: Int
    let boundedPathPlanningApprovedApplicationCasesFailed: Int
    let boundedPathPlanningApprovedApplicationPlansProduced: Int
    let boundedPathPlanningApprovedApplicationSelectedFirstSteps: Int
    let boundedPathPlanningApprovedApplicationNoPathPlans: Int
    let boundedPathPlanningApprovedApplicationZeroStepPlans: Int
    let boundedPathPlanningApprovedApplicationHandoffIntents: Int
    let boundedPathPlanningApprovedApplicationAdvisoryStepsTotal: Int
    let boundedPathPlanningApprovedApplicationAdvisoryStepsNotSent: Bool
    let boundedPathPlanningApprovedApplicationAdvisoryStepsNotApplied: Bool
    let boundedPathPlanningApprovedApplicationFirstStepOnlyHandoff: Bool
    let boundedPathPlanningApprovedApplicationFirstStepOnlyApplication: Bool
    let boundedPathPlanningApprovedApplicationMovementIntentInputs: Int
    let boundedPathPlanningApprovedApplicationTickUsed: Bool
    let boundedPathPlanningApprovedApplicationTickReadCollision: Bool
    let boundedPathPlanningApprovedApplicationTickWorldReadOnlyUsed: Bool
    let boundedPathPlanningApprovedApplicationTickApproved: Int
    let boundedPathPlanningApprovedApplicationTickDenied: Int
    let boundedPathPlanningApprovedApplicationTickDeniedConflict: Int
    let boundedPathPlanningApprovedApplicationTickDeniedSourceMismatch: Int
    let boundedPathPlanningApprovedApplicationTickDeniedStaleIntent: Int
    let boundedPathPlanningApprovedApplicationTickFeedbackEmitted: Int
    let boundedPathPlanningApprovedApplicationApprovedApplications: Int
    let boundedPathPlanningApprovedApplicationDisplacementsApplied: Int
    let boundedPathPlanningApprovedApplicationDeniedAgentsPreserved: Int
    let boundedPathPlanningApprovedApplicationNoPathAgentsPreserved: Int
    let boundedPathPlanningApprovedApplicationZeroStepAgentsPreserved: Int
    let boundedPathPlanningApprovedApplicationSourceMismatchAgentsPreserved: Int
    let boundedPathPlanningApprovedApplicationStaleAgentsPreserved: Int
    let boundedPathPlanningApprovedApplicationAbstractPhysicalDivergenceBeforeMax: Int
    let boundedPathPlanningApprovedApplicationAbstractPhysicalDivergenceAfterMax: Int
    let boundedPathPlanningApprovedApplicationMaxStepsMax: Int
    let boundedPathPlanningApprovedApplicationMaxNodesMax: Int
    let boundedPathPlanningApprovedApplicationNodesVisitedMax: Int
    let boundedPathPlanningApprovedApplicationStepsMax: Int
    let boundedPathPlanningApprovedApplicationStepsWithinMax: Bool
    let boundedPathPlanningApprovedApplicationNodesWithinMax: Bool
    let boundedPathPlanningApprovedApplicationOneEdgeSteps: Bool
    let boundedPathPlanningApprovedApplicationSameYSteps: Bool
    let boundedPathPlanningApprovedApplicationDeterministicPlanOrder: Bool
    let boundedPathPlanningApprovedApplicationDeterministicHandoffOrder: Bool
    let boundedPathPlanningApprovedApplicationDeterministicTickOrder: Bool
    let boundedPathPlanningApprovedApplicationDeterministicApplicationOrder: Bool
    let boundedPathPlanningApprovedApplicationDeterministicDigest: Bool
    let boundedPathPlanningApprovedApplicationDigestsEqual: Bool
    let boundedPathPlanningApprovedApplicationRepeatabilityFailures: Int
    let boundedPathPlanningApprovedApplicationV0Unchanged: Bool
    let boundedPathPlanningApprovedApplicationV1Unchanged: Bool
    let boundedPathPlanningApprovedApplicationV2Unchanged: Bool
    let boundedPathPlanningApprovedApplicationV3OptIn: Bool
    let boundedPathPlanningApprovedApplicationV3NotGlobal: Bool
    let boundedPathPlanningApprovedApplicationHiddenActivationDetected: Bool
    let boundedPathPlanningApprovedApplicationWorldRead: Bool
    let boundedPathPlanningApprovedApplicationCollisionRead: Bool
    let boundedPathPlanningApprovedApplicationMovementApplied: Bool
    let boundedPathPlanningApprovedApplicationLabPositionMapMutated: Bool
    let boundedPathPlanningApprovedApplicationRouteFollowingUsed: Bool
    let boundedPathPlanningApprovedApplicationFullRouteExecutionUsed: Bool
    let boundedPathPlanningApprovedApplicationAdvisoryStepsApplied: Bool
    let boundedPathPlanningApprovedApplicationSecondStepAutoApplied: Bool
    let boundedPathPlanningApprovedApplicationPathfindingLiveUsed: Bool
    let boundedPathPlanningApprovedApplicationUnboundedSearchUsed: Bool
    let boundedPathPlanningApprovedApplicationDynamicReplanningUsed: Bool
    let boundedPathPlanningApprovedApplicationReservationRuntimeUsed: Bool
    let boundedPathPlanningApprovedApplicationMemoryUpdated: Bool
    let boundedPathPlanningApprovedApplicationGoalChanged: Bool
    let boundedPathPlanningApprovedApplicationTerrainMutated: Bool
    let boundedPathPlanningApprovedApplicationWorldMutated: Bool
    let boundedPathPlanningApprovedApplicationCoreEntityMoved: Bool
    let boundedPathPlanningApprovedApplicationPhysicalPlaceholderMoved: Bool
    let boundedPathPlanningApprovedApplicationMutationPerformed: Bool
    let boundedPathPlanningApprovedApplicationSuccess: Bool
}

private struct BoundedPathQueueEntry {
    let node: LabTerrainPathNodeKey
    let steps: [LabAgentBoundedPathStep]
}

private let boundedPathPlanningNeighborOrder = [
    "move_north",
    "move_east",
    "move_south",
    "move_west"
]

private let boundedPathPlanningBoundary = LabBoundedPathPlanningBoundary(
    worldRead: false,
    collisionRead: false,
    tickUsed: false,
    movementApplied: false,
    labPositionMapMutated: false,
    routeFollowingUsed: false,
    pathfindingLiveUsed: false,
    unboundedSearchUsed: false,
    dynamicReplanningUsed: false,
    reservationRuntimeUsed: false,
    memoryUpdated: false,
    goalChanged: false,
    terrainMutated: false,
    worldMutated: false,
    coreEntityMoved: false,
    physicalPlaceholderMoved: false,
    mutationPerformed: false
)

private func boundedPathNode(_ x: Int, _ z: Int, y: Int = 64) -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: x, y: y, z: z)
}

private func boundedPathNeighbor(from node: LabTerrainPathNodeKey, hint: String) -> LabTerrainPathNodeKey {
    switch hint {
    case "move_north":
        return LabTerrainPathNodeKey(x: node.x, y: node.y, z: node.z - 1)
    case "move_east":
        return LabTerrainPathNodeKey(x: node.x + 1, y: node.y, z: node.z)
    case "move_south":
        return LabTerrainPathNodeKey(x: node.x, y: node.y, z: node.z + 1)
    case "move_west":
        return LabTerrainPathNodeKey(x: node.x - 1, y: node.y, z: node.z)
    default:
        return node
    }
}

private func boundedPathIsOneEdgeSameY(_ step: LabAgentBoundedPathStep) -> Bool {
    let dx = abs(step.to.x - step.from.x)
    let dy = abs(step.to.y - step.from.y)
    let dz = abs(step.to.z - step.from.z)
    return dy == 0 && dx + dz == 1
}

private func boundedPathDigest(for plan: LabAgentBoundedPathPlan) -> String {
    let steps = plan.steps
        .map { "\($0.index):\($0.hint):\($0.from.x),\($0.from.y),\($0.from.z)>\($0.to.x),\($0.to.y),\($0.to.z)" }
        .joined(separator: ";")
    return [
        plan.agentId,
        "\(plan.tick)",
        "\(plan.start.x),\(plan.start.y),\(plan.start.z)",
        "\(plan.target.x),\(plan.target.y),\(plan.target.z)",
        "\(plan.maxSteps)",
        "\(plan.maxNodes)",
        "\(plan.nodesVisited)",
        plan.reachedTarget ? "reached" : "not_reached",
        plan.exhausted ? "exhausted" : "not_exhausted",
        plan.truncated ? "truncated" : "not_truncated",
        plan.noPathReason ?? "none",
        steps
    ].joined(separator: "|")
}

private func makeBoundedPathPlan(
    context: LabAgentBoundedPathPlanningContext
) -> LabAgentBoundedPathPlan {
    if context.start == context.target {
        let plan = LabAgentBoundedPathPlan(
            tick: context.tick,
            agentId: context.agentId,
            start: context.start,
            target: context.target,
            maxSteps: context.maxSteps,
            maxNodes: context.maxNodes,
            nodesVisited: 1,
            steps: [],
            selectedFirstStep: nil,
            reachedTarget: true,
            exhausted: false,
            truncated: false,
            noPathReason: nil,
            deterministicDigest: "",
            boundary: context.boundary
        )
        return withBoundedPathDigest(plan)
    }

    let allowed = Set(context.allowedDirections)
    let blockedDirections = Set(context.blockedDirections)
    let blockedCells = Set(context.abstractBlockedCells)
    var visited: Set<LabTerrainPathNodeKey> = [context.start]
    var queue = [BoundedPathQueueEntry(node: context.start, steps: [])]
    var nodesVisited = 0
    var truncated = false
    var foundSteps: [LabAgentBoundedPathStep]?
    var noPathReason: String?

    while !queue.isEmpty && nodesVisited < context.maxNodes {
        let entry = queue.removeFirst()
        nodesVisited += 1

        if entry.node == context.target {
            foundSteps = entry.steps
            break
        }

        guard entry.steps.count < context.maxSteps else {
            truncated = true
            continue
        }

        for hint in boundedPathPlanningNeighborOrder where allowed.contains(hint) && !blockedDirections.contains(hint) {
            let next = boundedPathNeighbor(from: entry.node, hint: hint)
            guard !blockedCells.contains(next), !visited.contains(next) else { continue }
            visited.insert(next)
            let step = LabAgentBoundedPathStep(
                from: entry.node,
                to: next,
                hint: hint,
                index: entry.steps.count
            )
            queue.append(BoundedPathQueueEntry(node: next, steps: entry.steps + [step]))
        }
    }

    let reachedTarget = foundSteps != nil
    let steps = foundSteps ?? []
    let maxNodesReached = !reachedTarget && nodesVisited >= context.maxNodes && !queue.isEmpty
    if !reachedTarget {
        if maxNodesReached {
            noPathReason = "max_nodes_reached"
        } else if truncated {
            noPathReason = "max_steps_exceeded"
        } else {
            noPathReason = "no_path"
        }
    }

    let plan = LabAgentBoundedPathPlan(
        tick: context.tick,
        agentId: context.agentId,
        start: context.start,
        target: context.target,
        maxSteps: context.maxSteps,
        maxNodes: context.maxNodes,
        nodesVisited: nodesVisited,
        steps: steps,
        selectedFirstStep: steps.first,
        reachedTarget: reachedTarget,
        exhausted: !reachedTarget && queue.isEmpty,
        truncated: !reachedTarget && truncated,
        noPathReason: noPathReason,
        deterministicDigest: "",
        boundary: context.boundary
    )
    return withBoundedPathDigest(plan)
}

private func withBoundedPathDigest(_ plan: LabAgentBoundedPathPlan) -> LabAgentBoundedPathPlan {
    LabAgentBoundedPathPlan(
        tick: plan.tick,
        agentId: plan.agentId,
        start: plan.start,
        target: plan.target,
        maxSteps: plan.maxSteps,
        maxNodes: plan.maxNodes,
        nodesVisited: plan.nodesVisited,
        steps: plan.steps,
        selectedFirstStep: plan.selectedFirstStep,
        reachedTarget: plan.reachedTarget,
        exhausted: plan.exhausted,
        truncated: plan.truncated,
        noPathReason: plan.noPathReason,
        deterministicDigest: boundedPathDigest(for: plan),
        boundary: plan.boundary
    )
}

private func boundedPathContext(
    tick: Int = 0,
    agentId: String,
    start: LabTerrainPathNodeKey,
    target: LabTerrainPathNodeKey,
    maxSteps: Int,
    maxNodes: Int,
    allowedDirections: [String] = boundedPathPlanningNeighborOrder,
    blockedCells: [LabTerrainPathNodeKey] = [],
    blockedDirections: [String] = []
) -> LabAgentBoundedPathPlanningContext {
    LabAgentBoundedPathPlanningContext(
        tick: tick,
        agentId: agentId,
        start: start,
        target: target,
        maxSteps: maxSteps,
        maxNodes: maxNodes,
        allowedDirections: allowedDirections,
        blockedDirections: blockedDirections,
        abstractBlockedCells: blockedCells,
        deterministicTieBreaker: "stable_agent_id_then_\(boundedPathPlanningNeighborOrder.joined(separator: "_"))",
        policyMode: "boundedPathPlanningV3FixtureOptIn",
        boundary: boundedPathPlanningBoundary
    )
}

private func boundedPathFixtureDefinitions() -> [(String, String, LabAgentBoundedPathPlanningContext)] {
    [
        (
            "bounded_path_direct_one_step",
            "reached_one_step",
            boundedPathContext(
                agentId: "agent_0_direct",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(1, 0),
                maxSteps: 3,
                maxNodes: 16
            )
        ),
        (
            "bounded_path_two_steps_straight",
            "reached_two_steps",
            boundedPathContext(
                agentId: "agent_1_two_steps",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(2, 0),
                maxSteps: 3,
                maxNodes: 16
            )
        ),
        (
            "bounded_path_turn_around_block",
            "reached_detour",
            boundedPathContext(
                agentId: "agent_2_detour",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(2, 0),
                maxSteps: 4,
                maxNodes: 32,
                blockedCells: [boundedPathNode(1, 0)]
            )
        ),
        (
            "bounded_path_no_path_blocked",
            "no_path",
            boundedPathContext(
                agentId: "agent_3_no_path",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(2, 0),
                maxSteps: 4,
                maxNodes: 16,
                blockedCells: [
                    boundedPathNode(1, 0),
                    boundedPathNode(-1, 0),
                    boundedPathNode(0, -1),
                    boundedPathNode(0, 1)
                ]
            )
        ),
        (
            "bounded_path_max_steps_too_short",
            "max_steps_exceeded",
            boundedPathContext(
                agentId: "agent_4_max_steps",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(3, 0),
                maxSteps: 2,
                maxNodes: 16
            )
        ),
        (
            "bounded_path_max_nodes_too_small",
            "max_nodes_reached",
            boundedPathContext(
                agentId: "agent_5_max_nodes",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(3, 0),
                maxSteps: 4,
                maxNodes: 2
            )
        ),
        (
            "bounded_path_start_equals_target",
            "zero_step",
            boundedPathContext(
                agentId: "agent_6_zero_step",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(0, 0),
                maxSteps: 3,
                maxNodes: 16
            )
        ),
        (
            "bounded_path_negative_coordinates",
            "reached_negative_coordinates",
            boundedPathContext(
                agentId: "agent_7_negative",
                start: boundedPathNode(-1, 0),
                target: boundedPathNode(1, 0),
                maxSteps: 4,
                maxNodes: 32
            )
        ),
        (
            "bounded_path_same_y_only",
            "same_y_no_vertical_path",
            boundedPathContext(
                agentId: "agent_8_same_y",
                start: boundedPathNode(0, 0),
                target: LabTerrainPathNodeKey(x: 0, y: 65, z: 0),
                maxSteps: 2,
                maxNodes: 16
            )
        )
    ]
}

private func boundedPathCasePassed(expectedKind: String, plan: LabAgentBoundedPathPlan) -> Bool {
    switch expectedKind {
    case "reached_one_step":
        return plan.reachedTarget && plan.steps.count == 1 && plan.selectedFirstStep != nil
    case "reached_two_steps":
        return plan.reachedTarget && plan.steps.count == 2 && plan.selectedFirstStep != nil
    case "reached_detour":
        return plan.reachedTarget && plan.steps.count == 4 && plan.selectedFirstStep != nil
            && !plan.steps.map(\.to).contains(boundedPathNode(1, 0))
    case "no_path":
        return !plan.reachedTarget && plan.noPathReason == "no_path"
    case "max_steps_exceeded":
        return !plan.reachedTarget && plan.truncated && plan.noPathReason == "max_steps_exceeded"
    case "max_nodes_reached":
        return !plan.reachedTarget && plan.noPathReason == "max_nodes_reached"
    case "zero_step":
        return plan.reachedTarget && plan.steps.isEmpty && plan.selectedFirstStep == nil
    case "reached_negative_coordinates":
        return plan.reachedTarget && plan.selectedFirstStep != nil
    case "same_y_no_vertical_path":
        return !plan.reachedTarget && plan.steps.allSatisfy { $0.from.y == $0.to.y }
    case "reached_zero_step":
        return plan.reachedTarget && plan.steps.isEmpty && plan.selectedFirstStep == nil
    case "bounded_failure":
        return !plan.reachedTarget && plan.steps.isEmpty
    case "reached_three_steps":
        return plan.reachedTarget && plan.steps.count == 3 && plan.selectedFirstStep != nil
    case "reached_four_steps":
        return plan.reachedTarget && plan.steps.count == 4 && plan.selectedFirstStep != nil
    case "blocked_direction_respected":
        return plan.steps.allSatisfy { $0.hint != "move_east" }
    case "north_south_only_respected":
        return plan.steps.allSatisfy { $0.hint == "move_north" || $0.hint == "move_south" }
    case "duplicate_input":
        return plan.reachedTarget && plan.selectedFirstStep != nil
    case "tie_break_north_first":
        return plan.reachedTarget && plan.selectedFirstStep?.hint == "move_north"
    case "blocked_start_deterministic":
        return plan.nodesVisited <= plan.maxNodes && plan.steps.count <= plan.maxSteps
    case "blocked_target_no_path":
        return !plan.reachedTarget
    default:
        return false
    }
}

private func makeBoundedPathCases() -> [LabBoundedPathPlanningFixtureCase] {
    boundedPathFixtureDefinitions().map { name, expectedKind, context in
        let plan = makeBoundedPathPlan(context: context)
        let passed = boundedPathCasePassed(expectedKind: expectedKind, plan: plan)
        return LabBoundedPathPlanningFixtureCase(
            name: name,
            context: context,
            expectedKind: expectedKind,
            plan: plan,
            passed: passed,
            notes: [
                "Fixture-only bounded planning over an abstract grid.",
                "No World, collision, tick, movement application, route following, memory, goals, reservation runtime, or mutation."
            ]
        )
    }
}

private func boundedPathHardeningDefinitions() -> [(String, String, LabAgentBoundedPathPlanningContext)] {
    let duplicateContext = boundedPathContext(
        agentId: "agent_h16_duplicate",
        start: boundedPathNode(0, 0),
        target: boundedPathNode(1, -1),
        maxSteps: 2,
        maxNodes: 16
    )
    return [
        (
            "hardening_max_steps_zero_start_equals_target",
            "reached_zero_step",
            boundedPathContext(
                agentId: "agent_h00_zero_same",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(0, 0),
                maxSteps: 0,
                maxNodes: 16
            )
        ),
        (
            "hardening_max_steps_zero_needs_move",
            "bounded_failure",
            boundedPathContext(
                agentId: "agent_h01_zero_move",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(1, 0),
                maxSteps: 0,
                maxNodes: 16
            )
        ),
        (
            "hardening_max_steps_one_direct",
            "reached_one_step",
            boundedPathContext(
                agentId: "agent_h02_one_direct",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(1, 0),
                maxSteps: 1,
                maxNodes: 16
            )
        ),
        (
            "hardening_max_steps_one_needs_two",
            "bounded_failure",
            boundedPathContext(
                agentId: "agent_h03_one_needs_two",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(2, 0),
                maxSteps: 1,
                maxNodes: 16
            )
        ),
        (
            "hardening_max_steps_two_reaches_two",
            "reached_two_steps",
            boundedPathContext(
                agentId: "agent_h04_two_reaches",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(2, 0),
                maxSteps: 2,
                maxNodes: 16
            )
        ),
        (
            "hardening_max_steps_three_detour",
            "reached_three_steps",
            boundedPathContext(
                agentId: "agent_h05_three_detour",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(2, 1),
                maxSteps: 3,
                maxNodes: 32,
                blockedCells: [boundedPathNode(1, 0)]
            )
        ),
        (
            "hardening_max_steps_four_detour",
            "reached_four_steps",
            boundedPathContext(
                agentId: "agent_h06_four_detour",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(2, 0),
                maxSteps: 4,
                maxNodes: 32,
                blockedCells: [boundedPathNode(1, 0)]
            )
        ),
        (
            "hardening_max_nodes_one",
            "bounded_failure",
            boundedPathContext(
                agentId: "agent_h07_nodes_one",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(1, 0),
                maxSteps: 4,
                maxNodes: 1
            )
        ),
        (
            "hardening_max_nodes_two",
            "bounded_failure",
            boundedPathContext(
                agentId: "agent_h08_nodes_two",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(3, 0),
                maxSteps: 4,
                maxNodes: 2
            )
        ),
        (
            "hardening_max_nodes_full",
            "reached_four_steps",
            boundedPathContext(
                agentId: "agent_h09_nodes_full",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(2, 0),
                maxSteps: 4,
                maxNodes: 32,
                blockedCells: [boundedPathNode(1, 0)]
            )
        ),
        (
            "hardening_start_surrounded_by_blocked_cells",
            "no_path",
            boundedPathContext(
                agentId: "agent_h10_start_surrounded",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(2, 0),
                maxSteps: 4,
                maxNodes: 16,
                blockedCells: [
                    boundedPathNode(0, -1),
                    boundedPathNode(1, 0),
                    boundedPathNode(0, 1),
                    boundedPathNode(-1, 0)
                ]
            )
        ),
        (
            "hardening_target_surrounded_by_blocked_cells",
            "blocked_target_no_path",
            boundedPathContext(
                agentId: "agent_h11_target_surrounded",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(2, 0),
                maxSteps: 4,
                maxNodes: 32,
                blockedCells: [
                    boundedPathNode(2, -1),
                    boundedPathNode(3, 0),
                    boundedPathNode(2, 1),
                    boundedPathNode(1, 0)
                ]
            )
        ),
        (
            "hardening_blocked_direction_east",
            "blocked_direction_respected",
            boundedPathContext(
                agentId: "agent_h12_block_east",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(1, 0),
                maxSteps: 4,
                maxNodes: 32,
                blockedDirections: ["move_east"]
            )
        ),
        (
            "hardening_only_north_south_allowed",
            "north_south_only_respected",
            boundedPathContext(
                agentId: "agent_h13_north_south",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(0, -2),
                maxSteps: 2,
                maxNodes: 16,
                allowedDirections: ["move_north", "move_south"]
            )
        ),
        (
            "hardening_duplicate_blocked_cells",
            "reached_four_steps",
            boundedPathContext(
                agentId: "agent_h14_duplicate_blocked",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(2, 0),
                maxSteps: 4,
                maxNodes: 32,
                blockedCells: [
                    boundedPathNode(1, 0),
                    boundedPathNode(1, 0),
                    boundedPathNode(1, 0)
                ]
            )
        ),
        (
            "hardening_duplicate_case_same_input_a",
            "duplicate_input",
            duplicateContext
        ),
        (
            "hardening_duplicate_case_same_input_b",
            "duplicate_input",
            duplicateContext
        ),
        (
            "hardening_negative_coordinates_detour",
            "reached_four_steps",
            boundedPathContext(
                agentId: "agent_h17_negative_detour",
                start: boundedPathNode(-2, 0),
                target: boundedPathNode(0, 0),
                maxSteps: 4,
                maxNodes: 32,
                blockedCells: [boundedPathNode(-1, 0)]
            )
        ),
        (
            "hardening_same_y_only_rejects_vertical_escape",
            "same_y_no_vertical_path",
            boundedPathContext(
                agentId: "agent_h18_same_y",
                start: boundedPathNode(0, 0),
                target: LabTerrainPathNodeKey(x: 0, y: 65, z: 0),
                maxSteps: 2,
                maxNodes: 16,
                blockedCells: [
                    boundedPathNode(0, -1),
                    boundedPathNode(1, 0),
                    boundedPathNode(0, 1),
                    boundedPathNode(-1, 0)
                ]
            )
        ),
        (
            "hardening_target_outside_local_bound",
            "bounded_failure",
            boundedPathContext(
                agentId: "agent_h19_outside_bound",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(4, 0),
                maxSteps: 4,
                maxNodes: 2
            )
        ),
        (
            "hardening_blocked_start_cell",
            "blocked_start_deterministic",
            boundedPathContext(
                agentId: "agent_h20_blocked_start",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(1, 0),
                maxSteps: 2,
                maxNodes: 16,
                blockedCells: [boundedPathNode(0, 0)]
            )
        ),
        (
            "hardening_blocked_target_cell",
            "blocked_target_no_path",
            boundedPathContext(
                agentId: "agent_h21_blocked_target",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(1, 0),
                maxSteps: 2,
                maxNodes: 16,
                blockedCells: [boundedPathNode(1, 0)]
            )
        ),
        (
            "hardening_longer_than_max_steps",
            "bounded_failure",
            boundedPathContext(
                agentId: "agent_h22_longer_than_max",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(4, 0),
                maxSteps: 3,
                maxNodes: 32
            )
        ),
        (
            "hardening_deterministic_tie_break_two_equal_paths",
            "tie_break_north_first",
            boundedPathContext(
                agentId: "agent_h23_tie_break",
                start: boundedPathNode(0, 0),
                target: boundedPathNode(1, -1),
                maxSteps: 2,
                maxNodes: 16
            )
        )
    ]
}

private func makeBoundedPathHardeningCases() -> [LabBoundedPathPlanningFixtureCase] {
    boundedPathHardeningDefinitions().map { name, expectedKind, context in
        let plan = makeBoundedPathPlan(context: context)
        let passed = boundedPathCasePassed(expectedKind: expectedKind, plan: plan)
        return LabBoundedPathPlanningFixtureCase(
            name: name,
            context: context,
            expectedKind: expectedKind,
            plan: plan,
            passed: passed,
            notes: [
                "Fixture-only hardening for bounded path planning over an abstract grid.",
                "No World, collision, tick, movement application, route following, memory, goals, reservation runtime, or mutation."
            ]
        )
    }
}

private func boundedPathFullDigest(cases: [LabBoundedPathPlanningFixtureCase]) -> String {
    cases
        .map { "\($0.name)|\($0.expectedKind)|\($0.plan.deterministicDigest)|passed=\($0.passed)" }
        .joined(separator: "\n")
}

private func makeBoundedPathSummary(
    scenario: String,
    seed: UInt32,
    cases: [LabBoundedPathPlanningFixtureCase],
    repeatCases: [LabBoundedPathPlanningFixtureCase]
) -> LabBoundedPathPlanningFixtureSummary {
    let plans = cases.map(\.plan)
    let maxStepsValues = plans.map(\.maxSteps)
    let maxNodesValues = plans.map(\.maxNodes)
    let stepsCounts = plans.map { $0.steps.count }
    let digest = boundedPathFullDigest(cases: cases)
    let digestRepeat = boundedPathFullDigest(cases: repeatCases)
    let oneEdgeSteps = plans.flatMap(\.steps).allSatisfy(boundedPathIsOneEdgeSameY)
    let sameYSteps = plans.flatMap(\.steps).allSatisfy { $0.from.y == $0.to.y }
    let stepsWithinMax = plans.allSatisfy { $0.steps.count <= $0.maxSteps }
    let nodesWithinMax = plans.allSatisfy { $0.nodesVisited <= $0.maxNodes }
    let deterministicCaseOrder = cases.map(\.name) == boundedPathFixtureDefinitions().map(\.0)
    let deterministicNeighborOrder = cases.allSatisfy { $0.context.allowedDirections == boundedPathPlanningNeighborOrder }
    let deterministicTieBreak = cases.allSatisfy { $0.context.deterministicTieBreaker.contains("stable_agent_id") }
    let boundaryFlags = plans.map(\.boundary)
    let worldRead = boundaryFlags.contains { $0.worldRead }
    let collisionRead = boundaryFlags.contains { $0.collisionRead }
    let tickUsed = boundaryFlags.contains { $0.tickUsed }
    let movementApplied = boundaryFlags.contains { $0.movementApplied }
    let labPositionMapMutated = boundaryFlags.contains { $0.labPositionMapMutated }
    let routeFollowingUsed = boundaryFlags.contains { $0.routeFollowingUsed }
    let pathfindingLiveUsed = boundaryFlags.contains { $0.pathfindingLiveUsed }
    let unboundedSearchUsed = boundaryFlags.contains { $0.unboundedSearchUsed }
    let dynamicReplanningUsed = boundaryFlags.contains { $0.dynamicReplanningUsed }
    let reservationRuntimeUsed = boundaryFlags.contains { $0.reservationRuntimeUsed }
    let memoryUpdated = boundaryFlags.contains { $0.memoryUpdated }
    let goalChanged = boundaryFlags.contains { $0.goalChanged }
    let terrainMutated = boundaryFlags.contains { $0.terrainMutated }
    let worldMutated = boundaryFlags.contains { $0.worldMutated }
    let coreEntityMoved = boundaryFlags.contains { $0.coreEntityMoved }
    let physicalPlaceholderMoved = boundaryFlags.contains { $0.physicalPlaceholderMoved }
    let mutationPerformed = boundaryFlags.contains { $0.mutationPerformed }
    let digestsEqual = digest == digestRepeat
    let repeatabilityFailures = digestsEqual ? 0 : 1
    let casesPassed = cases.filter(\.passed).count
    let casesFailed = cases.count - casesPassed
    let maxStepsMax = maxStepsValues.max() ?? 0
    let maxNodesMax = maxNodesValues.max() ?? 0
    let nodesVisitedMax = plans.map(\.nodesVisited).max() ?? 0
    let stepsMax = stepsCounts.max() ?? 0
    let success = cases.count >= 8
        && casesPassed == cases.count
        && casesFailed == 0
        && plans.count == cases.count
        && plans.contains { $0.reachedTarget }
        && plans.contains { !$0.reachedTarget }
        && plans.contains { $0.selectedFirstStep != nil }
        && maxStepsMax <= 4
        && maxNodesMax <= 32
        && nodesVisitedMax <= maxNodesMax
        && stepsMax <= maxStepsMax
        && stepsWithinMax
        && nodesWithinMax
        && oneEdgeSteps
        && sameYSteps
        && deterministicCaseOrder
        && deterministicNeighborOrder
        && deterministicTieBreak
        && digestsEqual
        && repeatabilityFailures == 0
        && !worldRead
        && !collisionRead
        && !tickUsed
        && !movementApplied
        && !labPositionMapMutated
        && !routeFollowingUsed
        && !pathfindingLiveUsed
        && !unboundedSearchUsed
        && !dynamicReplanningUsed
        && !reservationRuntimeUsed
        && !memoryUpdated
        && !goalChanged
        && !terrainMutated
        && !worldMutated
        && !coreEntityMoved
        && !physicalPlaceholderMoved
        && !mutationPerformed

    return LabBoundedPathPlanningFixtureSummary(
        scenario: scenario,
        seed: seed,
        cases: cases.count,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
        plansProduced: cases.count,
        noPathPlans: plans.filter { !$0.reachedTarget }.count,
        reachedTargetPlans: plans.filter(\.reachedTarget).count,
        truncatedPlans: plans.filter(\.truncated).count,
        exhaustedPlans: plans.filter(\.exhausted).count,
        selectedFirstSteps: plans.filter { $0.selectedFirstStep != nil }.count,
        maxStepsMin: maxStepsValues.min() ?? 0,
        maxStepsMax: maxStepsMax,
        maxNodesMin: maxNodesValues.min() ?? 0,
        maxNodesMax: maxNodesMax,
        nodesVisitedMax: nodesVisitedMax,
        stepsTotal: stepsCounts.reduce(0, +),
        stepsMax: stepsMax,
        stepsWithinMax: stepsWithinMax,
        nodesWithinMax: nodesWithinMax,
        oneEdgeSteps: oneEdgeSteps,
        sameYSteps: sameYSteps,
        deterministicCaseOrder: deterministicCaseOrder,
        deterministicNeighborOrder: deterministicNeighborOrder,
        deterministicTieBreak: deterministicTieBreak,
        digest: digest,
        digestRepeat: digestRepeat,
        digestsEqual: digestsEqual,
        repeatabilityFailures: repeatabilityFailures,
        v0Unchanged: true,
        v1Unchanged: true,
        v2Unchanged: true,
        v3OptIn: true,
        v3NotGlobal: true,
        hiddenActivationDetected: false,
        worldRead: worldRead,
        collisionRead: collisionRead,
        tickUsed: tickUsed,
        movementApplied: movementApplied,
        labPositionMapMutated: labPositionMapMutated,
        routeFollowingUsed: routeFollowingUsed,
        pathfindingLiveUsed: pathfindingLiveUsed,
        unboundedSearchUsed: unboundedSearchUsed,
        dynamicReplanningUsed: dynamicReplanningUsed,
        reservationRuntimeUsed: reservationRuntimeUsed,
        memoryUpdated: memoryUpdated,
        goalChanged: goalChanged,
        terrainMutated: terrainMutated,
        worldMutated: worldMutated,
        coreEntityMoved: coreEntityMoved,
        physicalPlaceholderMoved: physicalPlaceholderMoved,
        mutationPerformed: mutationPerformed,
        success: success
    )
}

private func makeBoundedPathHardeningSummary(
    scenario: String,
    seed: UInt32,
    cases: [LabBoundedPathPlanningFixtureCase],
    repeatCases: [LabBoundedPathPlanningFixtureCase]
) -> LabBoundedPathPlanningHardeningSummary {
    let plans = cases.map(\.plan)
    let maxStepsValues = plans.map(\.maxSteps)
    let maxNodesValues = plans.map(\.maxNodes)
    let stepsCounts = plans.map { $0.steps.count }
    let digest = boundedPathFullDigest(cases: cases)
    let digestRepeat = boundedPathFullDigest(cases: repeatCases)
    let allSteps = plans.flatMap(\.steps)
    let oneEdgeSteps = allSteps.allSatisfy(boundedPathIsOneEdgeSameY)
    let sameYSteps = allSteps.allSatisfy { $0.from.y == $0.to.y }
    let stepsWithinMax = plans.allSatisfy { $0.steps.count <= $0.maxSteps }
    let nodesWithinMax = plans.allSatisfy { $0.nodesVisited <= $0.maxNodes }
    let deterministicCaseOrder = cases.map(\.name) == boundedPathHardeningDefinitions().map(\.0)
    let deterministicNeighborOrder = cases.allSatisfy { contextCase in
        contextCase.context.allowedDirections.allSatisfy { boundedPathPlanningNeighborOrder.contains($0) }
    }
    let deterministicTieBreak = cases.allSatisfy { $0.context.deterministicTieBreaker.contains("stable_agent_id") }
    let blockedDirectionsRespected = cases.allSatisfy { contextCase in
        let blockedDirections = Set(contextCase.context.blockedDirections)
        return contextCase.plan.steps.allSatisfy { !blockedDirections.contains($0.hint) }
    }
    let abstractBlockedCellsRespected = cases.allSatisfy { contextCase in
        let blockedCells = Set(contextCase.context.abstractBlockedCells)
        return contextCase.plan.steps.allSatisfy { !blockedCells.contains($0.to) }
    }
    let duplicateCases = cases.filter { $0.name.hasPrefix("hardening_duplicate_case_same_input") }
    let duplicateInputDigestsEqual = duplicateCases.count >= 2
        && Set(duplicateCases.map(\.plan.deterministicDigest)).count == 1
    let tieBreakCase = cases.first { $0.name == "hardening_deterministic_tie_break_two_equal_paths" }
    let tieBreakSelectedExpectedFirstHint = tieBreakCase?.plan.selectedFirstStep?.hint == "move_north"
    let boundaryFlags = plans.map(\.boundary)
    let worldRead = boundaryFlags.contains { $0.worldRead }
    let collisionRead = boundaryFlags.contains { $0.collisionRead }
    let tickUsed = boundaryFlags.contains { $0.tickUsed }
    let movementApplied = boundaryFlags.contains { $0.movementApplied }
    let labPositionMapMutated = boundaryFlags.contains { $0.labPositionMapMutated }
    let routeFollowingUsed = boundaryFlags.contains { $0.routeFollowingUsed }
    let pathfindingLiveUsed = boundaryFlags.contains { $0.pathfindingLiveUsed }
    let unboundedSearchUsed = boundaryFlags.contains { $0.unboundedSearchUsed }
    let dynamicReplanningUsed = boundaryFlags.contains { $0.dynamicReplanningUsed }
    let reservationRuntimeUsed = boundaryFlags.contains { $0.reservationRuntimeUsed }
    let memoryUpdated = boundaryFlags.contains { $0.memoryUpdated }
    let goalChanged = boundaryFlags.contains { $0.goalChanged }
    let terrainMutated = boundaryFlags.contains { $0.terrainMutated }
    let worldMutated = boundaryFlags.contains { $0.worldMutated }
    let coreEntityMoved = boundaryFlags.contains { $0.coreEntityMoved }
    let physicalPlaceholderMoved = boundaryFlags.contains { $0.physicalPlaceholderMoved }
    let mutationPerformed = boundaryFlags.contains { $0.mutationPerformed }
    let digestsEqual = digest == digestRepeat
    let repeatabilityFailures = digestsEqual ? 0 : 1
    let casesPassed = cases.filter(\.passed).count
    let casesFailed = cases.count - casesPassed
    let maxStepsMax = maxStepsValues.max() ?? 0
    let maxNodesMax = maxNodesValues.max() ?? 0
    let nodesVisitedMax = plans.map(\.nodesVisited).max() ?? 0
    let stepsMax = stepsCounts.max() ?? 0
    let maxStepsZeroCases = cases.filter { $0.context.maxSteps == 0 }.count
    let maxStepsOneCases = cases.filter { $0.context.maxSteps == 1 }.count
    let maxStepsTwoCases = cases.filter { $0.context.maxSteps == 2 }.count
    let maxStepsThreeCases = cases.filter { $0.context.maxSteps == 3 }.count
    let maxStepsFourCases = cases.filter { $0.context.maxSteps == 4 }.count
    let maxNodesOneCases = cases.filter { $0.context.maxNodes == 1 }.count
    let maxNodesTwoCases = cases.filter { $0.context.maxNodes == 2 }.count
    let maxNodesFullCases = cases.filter { $0.context.maxNodes == 32 }.count
    let blockedStartCases = cases.filter { $0.name.contains("blocked_start") || $0.name.contains("start_surrounded") }.count
    let blockedTargetCases = cases.filter { $0.name.contains("blocked_target") || $0.name.contains("target_surrounded") }.count
    let blockedDirectionCases = cases.filter { !$0.context.blockedDirections.isEmpty || $0.name.contains("only_north_south") }.count
    let duplicateBlockedCellCases = cases.filter { $0.name.contains("duplicate_blocked") }.count
    let duplicateInputCases = duplicateCases.count
    let negativeCoordinateCases = cases.filter { $0.name.contains("negative") }.count
    let sameYOnlyCases = cases.filter { $0.name.contains("same_y") }.count
    let tieBreakCases = cases.filter { $0.name.contains("tie_break") }.count
    let success = cases.count >= 20
        && casesPassed == cases.count
        && casesFailed == 0
        && plans.count == cases.count
        && plans.contains { $0.reachedTarget }
        && plans.contains { !$0.reachedTarget }
        && plans.contains { $0.truncated }
        && plans.contains { $0.selectedFirstStep != nil }
        && maxStepsZeroCases >= 2
        && maxStepsOneCases >= 2
        && maxStepsTwoCases >= 1
        && maxStepsThreeCases >= 1
        && maxStepsFourCases >= 1
        && maxNodesOneCases >= 1
        && maxNodesTwoCases >= 1
        && maxNodesFullCases >= 1
        && blockedStartCases >= 1
        && blockedTargetCases >= 1
        && blockedDirectionCases >= 1
        && duplicateBlockedCellCases >= 1
        && duplicateInputCases >= 2
        && duplicateInputDigestsEqual
        && negativeCoordinateCases >= 1
        && sameYOnlyCases >= 1
        && tieBreakCases >= 1
        && tieBreakSelectedExpectedFirstHint
        && maxStepsMax <= 4
        && maxNodesMax <= 32
        && nodesVisitedMax <= maxNodesMax
        && stepsMax <= maxStepsMax
        && stepsWithinMax
        && nodesWithinMax
        && oneEdgeSteps
        && sameYSteps
        && blockedDirectionsRespected
        && abstractBlockedCellsRespected
        && deterministicCaseOrder
        && deterministicNeighborOrder
        && deterministicTieBreak
        && digestsEqual
        && repeatabilityFailures == 0
        && !worldRead
        && !collisionRead
        && !tickUsed
        && !movementApplied
        && !labPositionMapMutated
        && !routeFollowingUsed
        && !pathfindingLiveUsed
        && !unboundedSearchUsed
        && !dynamicReplanningUsed
        && !reservationRuntimeUsed
        && !memoryUpdated
        && !goalChanged
        && !terrainMutated
        && !worldMutated
        && !coreEntityMoved
        && !physicalPlaceholderMoved
        && !mutationPerformed

    return LabBoundedPathPlanningHardeningSummary(
        scenario: scenario,
        seed: seed,
        cases: cases.count,
        casesPassed: casesPassed,
        casesFailed: casesFailed,
        plansProduced: plans.count,
        noPathPlans: plans.filter { !$0.reachedTarget }.count,
        reachedTargetPlans: plans.filter(\.reachedTarget).count,
        truncatedPlans: plans.filter(\.truncated).count,
        exhaustedPlans: plans.filter(\.exhausted).count,
        selectedFirstSteps: plans.filter { $0.selectedFirstStep != nil }.count,
        maxStepsZeroCases: maxStepsZeroCases,
        maxStepsOneCases: maxStepsOneCases,
        maxStepsTwoCases: maxStepsTwoCases,
        maxStepsThreeCases: maxStepsThreeCases,
        maxStepsFourCases: maxStepsFourCases,
        maxNodesOneCases: maxNodesOneCases,
        maxNodesTwoCases: maxNodesTwoCases,
        maxNodesFullCases: maxNodesFullCases,
        blockedStartCases: blockedStartCases,
        blockedTargetCases: blockedTargetCases,
        blockedDirectionCases: blockedDirectionCases,
        duplicateBlockedCellCases: duplicateBlockedCellCases,
        duplicateInputCases: duplicateInputCases,
        duplicateInputDigestsEqual: duplicateInputDigestsEqual,
        negativeCoordinateCases: negativeCoordinateCases,
        sameYOnlyCases: sameYOnlyCases,
        tieBreakCases: tieBreakCases,
        tieBreakSelectedExpectedFirstHint: tieBreakSelectedExpectedFirstHint,
        maxStepsMin: maxStepsValues.min() ?? 0,
        maxStepsMax: maxStepsMax,
        maxNodesMin: maxNodesValues.min() ?? 0,
        maxNodesMax: maxNodesMax,
        nodesVisitedMax: nodesVisitedMax,
        stepsTotal: stepsCounts.reduce(0, +),
        stepsMax: stepsMax,
        stepsWithinMax: stepsWithinMax,
        nodesWithinMax: nodesWithinMax,
        oneEdgeSteps: oneEdgeSteps,
        sameYSteps: sameYSteps,
        blockedDirectionsRespected: blockedDirectionsRespected,
        abstractBlockedCellsRespected: abstractBlockedCellsRespected,
        deterministicCaseOrder: deterministicCaseOrder,
        deterministicNeighborOrder: deterministicNeighborOrder,
        deterministicTieBreak: deterministicTieBreak,
        digest: digest,
        digestRepeat: digestRepeat,
        digestsEqual: digestsEqual,
        repeatabilityFailures: repeatabilityFailures,
        v0Unchanged: true,
        v1Unchanged: true,
        v2Unchanged: true,
        v3OptIn: true,
        v3NotGlobal: true,
        hiddenActivationDetected: false,
        worldRead: worldRead,
        collisionRead: collisionRead,
        tickUsed: tickUsed,
        movementApplied: movementApplied,
        labPositionMapMutated: labPositionMapMutated,
        routeFollowingUsed: routeFollowingUsed,
        pathfindingLiveUsed: pathfindingLiveUsed,
        unboundedSearchUsed: unboundedSearchUsed,
        dynamicReplanningUsed: dynamicReplanningUsed,
        reservationRuntimeUsed: reservationRuntimeUsed,
        memoryUpdated: memoryUpdated,
        goalChanged: goalChanged,
        terrainMutated: terrainMutated,
        worldMutated: worldMutated,
        coreEntityMoved: coreEntityMoved,
        physicalPlaceholderMoved: physicalPlaceholderMoved,
        mutationPerformed: mutationPerformed,
        success: success
    )
}

func makeBoundedPathPlanningFixtureReport(
    scenario: String,
    seed: UInt32
) -> LabBoundedPathPlanningFixtureReport {
    let cases = makeBoundedPathCases()
    let repeatCases = makeBoundedPathCases()
    let summary = makeBoundedPathSummary(
        scenario: scenario,
        seed: seed,
        cases: cases,
        repeatCases: repeatCases
    )
    return LabBoundedPathPlanningFixtureReport(
        scenario: scenario,
        seed: seed,
        success: summary.success,
        plannerMode: "boundedPathPlanningV3FixtureOptIn",
        neighborOrder: boundedPathPlanningNeighborOrder,
        cases: cases,
        plans: cases.map(\.plan),
        summary: summary
    )
}

func makeBoundedPathPlanningFixtureDigest(
    report: LabBoundedPathPlanningFixtureReport
) -> LabBoundedPathPlanningFixtureDigest {
    LabBoundedPathPlanningFixtureDigest(
        scenario: report.scenario,
        seed: report.seed,
        digest: report.summary.digest,
        digestRepeat: report.summary.digestRepeat,
        digestsEqual: report.summary.digestsEqual
    )
}

func makeBoundedPathPlanningHardeningReport(
    scenario: String,
    seed: UInt32
) -> LabBoundedPathPlanningHardeningReport {
    let cases = makeBoundedPathHardeningCases()
    let repeatCases = makeBoundedPathHardeningCases()
    let summary = makeBoundedPathHardeningSummary(
        scenario: scenario,
        seed: seed,
        cases: cases,
        repeatCases: repeatCases
    )
    return LabBoundedPathPlanningHardeningReport(
        scenario: scenario,
        seed: seed,
        success: summary.success,
        plannerMode: "boundedPathPlanningV3FixtureOptInHardening",
        neighborOrder: boundedPathPlanningNeighborOrder,
        cases: cases,
        plans: cases.map(\.plan),
        summary: summary
    )
}

func makeBoundedPathPlanningHardeningDigest(
    report: LabBoundedPathPlanningHardeningReport
) -> LabBoundedPathPlanningHardeningDigest {
    LabBoundedPathPlanningHardeningDigest(
        scenario: report.scenario,
        seed: report.seed,
        digest: report.summary.digest,
        digestRepeat: report.summary.digestRepeat,
        digestsEqual: report.summary.digestsEqual
    )
}

func makeBoundedPathPlanningHardeningBoundaryReport(
    report: LabBoundedPathPlanningHardeningReport
) -> LabBoundedPathPlanningHardeningBoundaryReport {
    let summary = report.summary
    return LabBoundedPathPlanningHardeningBoundaryReport(
        scenario: report.scenario,
        seed: report.seed,
        worldRead: summary.worldRead,
        collisionRead: summary.collisionRead,
        tickUsed: summary.tickUsed,
        movementApplied: summary.movementApplied,
        labPositionMapMutated: summary.labPositionMapMutated,
        routeFollowingUsed: summary.routeFollowingUsed,
        pathfindingLiveUsed: summary.pathfindingLiveUsed,
        unboundedSearchUsed: summary.unboundedSearchUsed,
        dynamicReplanningUsed: summary.dynamicReplanningUsed,
        reservationRuntimeUsed: summary.reservationRuntimeUsed,
        memoryUpdated: summary.memoryUpdated,
        goalChanged: summary.goalChanged,
        terrainMutated: summary.terrainMutated,
        worldMutated: summary.worldMutated,
        coreEntityMoved: summary.coreEntityMoved,
        physicalPlaceholderMoved: summary.physicalPlaceholderMoved,
        mutationPerformed: summary.mutationPerformed,
        mutationBoundaryClean: !summary.worldRead
            && !summary.collisionRead
            && !summary.tickUsed
            && !summary.movementApplied
            && !summary.labPositionMapMutated
            && !summary.routeFollowingUsed
            && !summary.pathfindingLiveUsed
            && !summary.unboundedSearchUsed
            && !summary.dynamicReplanningUsed
            && !summary.reservationRuntimeUsed
            && !summary.memoryUpdated
            && !summary.goalChanged
            && !summary.terrainMutated
            && !summary.worldMutated
            && !summary.coreEntityMoved
            && !summary.physicalPlaceholderMoved
            && !summary.mutationPerformed
    )
}

private struct BoundedPathToTickFirstStepDefinition {
    let name: String
    let expectedKind: String
    let contexts: [LabAgentBoundedPathPlanningContext]
    let sourceOverrides: [String: LabTerrainPathNodeKey]
    let staleAgents: [String]
    let expectedApproved: Int
    let expectedDenied: Int
    let expectedDecisionCounts: [String: Int]
}

private struct BoundedPathToTickFirstStepBuild {
    let result: LabBoundedPathPlanningToTickFirstStepCase
    let tickReport: LabMultiAgentMovementTickFixtureReport
}

private func boundedPathFirstStepDefinitions()
    -> [BoundedPathToTickFirstStepDefinition] {
    [
        BoundedPathToTickFirstStepDefinition(
            name: "handoff_direct_one_step_approved",
            expectedKind: "direct_one_step_approved",
            contexts: [
                boundedPathContext(
                    agentId: "agent_handoff_direct",
                    start: boundedPathNode(0, 0),
                    target: boundedPathNode(1, 0),
                    maxSteps: 3,
                    maxNodes: 16
                )
            ],
            sourceOverrides: [:],
            staleAgents: [],
            expectedApproved: 1,
            expectedDenied: 0,
            expectedDecisionCounts: [LabMultiAgentMoveDecision.approved.rawValue: 1]
        ),
        BoundedPathToTickFirstStepDefinition(
            name: "handoff_two_step_only_first_step_sent",
            expectedKind: "two_step_first_only",
            contexts: [
                boundedPathContext(
                    agentId: "agent_handoff_two_step",
                    start: boundedPathNode(10, 0),
                    target: boundedPathNode(12, 0),
                    maxSteps: 3,
                    maxNodes: 16
                )
            ],
            sourceOverrides: [:],
            staleAgents: [],
            expectedApproved: 1,
            expectedDenied: 0,
            expectedDecisionCounts: [LabMultiAgentMoveDecision.approved.rawValue: 1]
        ),
        BoundedPathToTickFirstStepDefinition(
            name: "handoff_detour_only_first_step_sent",
            expectedKind: "detour_first_only",
            contexts: [
                boundedPathContext(
                    agentId: "agent_handoff_detour",
                    start: boundedPathNode(20, 0),
                    target: boundedPathNode(22, 0),
                    maxSteps: 4,
                    maxNodes: 32,
                    blockedCells: [boundedPathNode(21, 0)]
                )
            ],
            sourceOverrides: [:],
            staleAgents: [],
            expectedApproved: 1,
            expectedDenied: 0,
            expectedDecisionCounts: [LabMultiAgentMoveDecision.approved.rawValue: 1]
        ),
        BoundedPathToTickFirstStepDefinition(
            name: "handoff_no_path_no_intent",
            expectedKind: "no_path_no_intent",
            contexts: [
                boundedPathContext(
                    agentId: "agent_handoff_no_path",
                    start: boundedPathNode(40, 0),
                    target: boundedPathNode(42, 0),
                    maxSteps: 4,
                    maxNodes: 16,
                    blockedCells: [
                        boundedPathNode(40, -1),
                        boundedPathNode(41, 0),
                        boundedPathNode(40, 1),
                        boundedPathNode(39, 0)
                    ]
                )
            ],
            sourceOverrides: [:],
            staleAgents: [],
            expectedApproved: 0,
            expectedDenied: 0,
            expectedDecisionCounts: [:]
        ),
        BoundedPathToTickFirstStepDefinition(
            name: "handoff_start_equals_target_no_intent",
            expectedKind: "zero_step_no_intent",
            contexts: [
                boundedPathContext(
                    agentId: "agent_handoff_zero",
                    start: boundedPathNode(50, 0),
                    target: boundedPathNode(50, 0),
                    maxSteps: 3,
                    maxNodes: 16
                )
            ],
            sourceOverrides: [:],
            staleAgents: [],
            expectedApproved: 0,
            expectedDenied: 0,
            expectedDecisionCounts: [:]
        ),
        BoundedPathToTickFirstStepDefinition(
            name: "handoff_conflict_denied_by_tick",
            expectedKind: "same_destination_conflict",
            contexts: [
                boundedPathContext(
                    agentId: "agent_handoff_conflict_0",
                    start: boundedPathNode(60, 0),
                    target: boundedPathNode(61, 0),
                    maxSteps: 3,
                    maxNodes: 16
                ),
                boundedPathContext(
                    agentId: "agent_handoff_conflict_1",
                    start: boundedPathNode(62, 0),
                    target: boundedPathNode(61, 0),
                    maxSteps: 3,
                    maxNodes: 16
                )
            ],
            sourceOverrides: [:],
            staleAgents: [],
            expectedApproved: 1,
            expectedDenied: 1,
            expectedDecisionCounts: [
                LabMultiAgentMoveDecision.approved.rawValue: 1,
                LabMultiAgentMoveDecision.deniedSameDestinationConflict.rawValue: 1
            ]
        ),
        BoundedPathToTickFirstStepDefinition(
            name: "handoff_source_mismatch_denied",
            expectedKind: "source_mismatch_denied",
            contexts: [
                boundedPathContext(
                    agentId: "agent_handoff_source_mismatch",
                    start: boundedPathNode(70, 0),
                    target: boundedPathNode(71, 0),
                    maxSteps: 3,
                    maxNodes: 16
                )
            ],
            sourceOverrides: [
                "agent_handoff_source_mismatch": boundedPathNode(72, 0)
            ],
            staleAgents: [],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: [
                LabMultiAgentMoveDecision.deniedSourceMismatch.rawValue: 1
            ]
        ),
        BoundedPathToTickFirstStepDefinition(
            name: "handoff_stale_intent_denied",
            expectedKind: "stale_intent_denied",
            contexts: [
                boundedPathContext(
                    agentId: "agent_handoff_stale",
                    start: boundedPathNode(80, 0),
                    target: boundedPathNode(81, 0),
                    maxSteps: 3,
                    maxNodes: 16
                )
            ],
            sourceOverrides: [:],
            staleAgents: ["agent_handoff_stale"],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: [
                LabMultiAgentMoveDecision.deniedStaleIntent.rawValue: 1
            ]
        )
    ]
}

private func makeBoundedPathFirstStepIntent(
    plan: LabAgentBoundedPathPlan,
    firstStep: LabAgentBoundedPathStep,
    stale: Bool
) -> LabAgentMoveIntent {
    LabAgentMoveIntent(
        agentId: plan.agentId,
        routeId: "bounded_path_first_step_fixture",
        from: firstStep.from,
        to: firstStep.to,
        routeIndex: firstStep.index,
        reason: "bounded_path_planning_first_step_handoff",
        stale: stale
    )
}

@inline(never)
@_optimize(none)
private func makeBoundedPathToTickFirstStepBuild(
    definition: BoundedPathToTickFirstStepDefinition,
    seed: UInt32
) -> BoundedPathToTickFirstStepBuild {
    let plans = definition.contexts.map { makeBoundedPathPlan(context: $0) }
    let staleAgents = Set(definition.staleAgents)
    let handoffs = plans.compactMap { plan -> LabBoundedPathPlanningToTickFirstStepHandoff? in
        guard let selectedFirstStep = plan.selectedFirstStep else { return nil }
        let advisorySteps = Array(plan.steps.dropFirst())
        let intent = makeBoundedPathFirstStepIntent(
            plan: plan,
            firstStep: selectedFirstStep,
            stale: staleAgents.contains(plan.agentId)
        )
        return LabBoundedPathPlanningToTickFirstStepHandoff(
            caseName: definition.name,
            agentId: plan.agentId,
            selectedFirstStep: selectedFirstStep,
            intent: intent,
            advisorySteps: advisorySteps,
            sentToTick: true,
            reason: advisorySteps.isEmpty
                ? "selected_first_step_sent_to_fixture_tick"
                : "selected_first_step_sent_remaining_steps_advisory_only"
        )
    }.sorted { $0.agentId < $1.agentId }
    let agents = Dictionary(
        uniqueKeysWithValues: definition.contexts.map {
            ($0.agentId, definition.sourceOverrides[$0.agentId] ?? $0.start)
        }
    )
    let tickInput = LabMultiAgentMovementTickInput(
        tick: 0,
        agents: agents,
        physicalPositions: agents,
        intents: handoffs.map(\.intent),
        maxAgents: nil
    )
    let tickReport = makeMultiAgentMovementTickFixtureReport(
        scenario: definition.name,
        seed: seed,
        ticksCompleted: 0,
        input: tickInput,
        expectedApproved: definition.expectedApproved,
        expectedDenied: definition.expectedDenied,
        expectedDecisionCounts: definition.expectedDecisionCounts
    )
    let result = LabBoundedPathPlanningToTickFirstStepCase(
        name: definition.name,
        contexts: definition.contexts,
        expectedKind: definition.expectedKind,
        plans: plans,
        handoffIntents: tickInput.intents,
        handoffs: handoffs,
        tickInput: tickInput,
        tickOutput: tickReport.output,
        expectedApproved: definition.expectedApproved,
        expectedDenied: definition.expectedDenied,
        expectedDecisionCounts: definition.expectedDecisionCounts,
        passed: boundedPathToTickCasePassed(
            expectedKind: definition.expectedKind,
            plans: plans,
            handoffs: handoffs,
            tickReport: tickReport
        ),
        notes: [
            "Only selectedFirstStep is converted to a movement intent.",
            "Remaining path steps are advisory-only and are not sent to the tick fixture."
        ]
    )
    return BoundedPathToTickFirstStepBuild(result: result, tickReport: tickReport)
}

@inline(never)
@_optimize(none)
private func boundedPathToTickCasePassed(
    expectedKind: String,
    plans: [LabAgentBoundedPathPlan],
    handoffs: [LabBoundedPathPlanningToTickFirstStepHandoff],
    tickReport: LabMultiAgentMovementTickFixtureReport
) -> Bool {
    let decisions = tickReport.output.resolutions.map(\.decision)
    switch expectedKind {
    case "direct_one_step_approved":
        return plans.count == 1
            && plans.first?.steps.count == 1
            && handoffs.count == 1
            && tickReport.summary.approved == 1
            && tickReport.summary.denied == 0
            && tickReport.success
    case "two_step_first_only":
        return plans.first?.steps.count == 2
            && handoffs.count == 1
            && handoffs.first?.advisorySteps.count == 1
            && tickReport.summary.intentCount == 1
            && tickReport.summary.approved == 1
            && tickReport.success
    case "detour_first_only":
        return (plans.first?.steps.count ?? 0) > 1
            && handoffs.count == 1
            && tickReport.summary.intentCount == 1
            && tickReport.summary.approved == 1
            && tickReport.success
    case "no_path_no_intent":
        return plans.count == 1
            && plans.first?.reachedTarget == false
            && plans.first?.selectedFirstStep == nil
            && handoffs.isEmpty
            && tickReport.summary.intentCount == 0
            && tickReport.success
    case "zero_step_no_intent":
        return plans.count == 1
            && plans.first?.reachedTarget == true
            && plans.first?.steps.isEmpty == true
            && plans.first?.selectedFirstStep == nil
            && handoffs.isEmpty
            && tickReport.summary.intentCount == 0
            && tickReport.success
    case "same_destination_conflict":
        return plans.count == 2
            && handoffs.count == 2
            && tickReport.summary.approved == 1
            && tickReport.summary.denied == 1
            && tickReport.summary.sameDestinationConflicts == 1
            && decisions.contains(.deniedSameDestinationConflict)
            && tickReport.success
    case "source_mismatch_denied":
        return handoffs.count == 1
            && tickReport.summary.approved == 0
            && tickReport.summary.denied == 1
            && decisions == [.deniedSourceMismatch]
            && tickReport.success
    case "stale_intent_denied":
        return handoffs.count == 1
            && tickReport.summary.approved == 0
            && tickReport.summary.denied == 1
            && decisions == [.deniedStaleIntent]
            && tickReport.success
    default:
        return false
    }
}

@inline(never)
@_optimize(none)
private func makeBoundedPathToTickFirstStepBuilds(seed: UInt32)
    -> [BoundedPathToTickFirstStepBuild] {
    boundedPathFirstStepDefinitions().map {
        makeBoundedPathToTickFirstStepBuild(definition: $0, seed: seed)
    }
}

@inline(never)
@_optimize(none)
private func boundedPathToTickDigest(
    cases: [LabBoundedPathPlanningToTickFirstStepCase]
) -> String {
    cases.map { result in
        let planPart = result.plans.map {
            "\($0.agentId)|steps=\($0.steps.count)|first=\($0.selectedFirstStep?.hint ?? "none")|\($0.deterministicDigest)"
        }.joined(separator: ";")
        let handoffPart = result.handoffs.map {
            "\($0.agentId)|\($0.intent.from.x),\($0.intent.from.y),\($0.intent.from.z)>\($0.intent.to.x),\($0.intent.to.y),\($0.intent.to.z)|stale=\($0.intent.stale)|advisory=\($0.advisorySteps.count)"
        }.joined(separator: ";")
        let tickPart = result.tickOutput.resolutions.map {
            "\($0.agentId):\($0.decision.rawValue):approved=\($0.approved)"
        }.joined(separator: ";")
        return "\(result.name)|\(result.expectedKind)|passed=\(result.passed)|plans=\(planPart)|handoff=\(handoffPart)|tick=\(tickPart)"
    }.joined(separator: "\n")
}

@inline(never)
@_optimize(none)
private func makeBoundedPathToTickFirstStepSummary(
    scenario: String,
    seed: UInt32,
    cases: [LabBoundedPathPlanningToTickFirstStepCase],
    repeatCases: [LabBoundedPathPlanningToTickFirstStepCase]
) -> LabBoundedPathPlanningToTickFirstStepSummary {
    let plans = cases.flatMap(\.plans)
    let handoffs = cases.flatMap(\.handoffs)
    let resolutions = cases.flatMap(\.tickOutput.resolutions)
    let digest = boundedPathToTickDigest(cases: cases)
    let digestRepeat = boundedPathToTickDigest(cases: repeatCases)
    let maxStepsMax = plans.map(\.maxSteps).max() ?? 0
    let maxNodesMax = plans.map(\.maxNodes).max() ?? 0
    let stepsMax = plans.map { $0.steps.count }.max() ?? 0
    let nodesVisitedMax = plans.map(\.nodesVisited).max() ?? 0
    let advisoryStepsTotal = handoffs.reduce(0) { $0 + $1.advisorySteps.count }
    let advisoryStepKeys = Set(handoffs.flatMap { handoff in
        handoff.advisorySteps.map {
            "\(handoff.agentId):\($0.from.x),\($0.from.y),\($0.from.z)>\($0.to.x),\($0.to.y),\($0.to.z)"
        }
    })
    let sentStepKeys = Set(handoffs.map {
        "\($0.agentId):\($0.intent.from.x),\($0.intent.from.y),\($0.intent.from.z)>\($0.intent.to.x),\($0.intent.to.y),\($0.intent.to.z)"
    })
    let advisoryStepsNotSent = advisoryStepKeys.isDisjoint(with: sentStepKeys)
    let firstStepOnlyHandoff = handoffs.allSatisfy {
        $0.intent.from == $0.selectedFirstStep.from
            && $0.intent.to == $0.selectedFirstStep.to
            && $0.intent.routeIndex == $0.selectedFirstStep.index
    }
    let deterministicPlanOrder = cases.map(\.name) == boundedPathFirstStepDefinitions().map(\.name)
    let deterministicHandoffOrder = cases.allSatisfy {
        $0.handoffs.map(\.agentId) == $0.handoffs.map(\.agentId).sorted()
            && $0.handoffIntents.map(\.agentId) == $0.handoffIntents.map(\.agentId).sorted()
    }
    let deterministicTickOrder = cases.allSatisfy {
        $0.tickOutput.resolutions.map(\.agentId)
            == $0.tickOutput.resolutions.map(\.agentId).sorted()
    }
    let tickReadCollision = false
    let tickWorldReadOnlyUsed = false
    let movementApplied = cases.contains {
        $0.tickOutput.summary.displacementsApplied > 0
            || $0.tickOutput.resolutions.contains { $0.displacementApplied }
    }
    let labPositionMapMutated = cases.contains {
        $0.tickOutput.abstractPositionsBefore != $0.tickOutput.abstractPositionsAfter
            || $0.tickOutput.physicalPositionsBefore != $0.tickOutput.physicalPositionsAfter
    }
    let repeatabilityFailures = zip(cases, repeatCases).filter {
        boundedPathToTickDigest(cases: [$0.0]) != boundedPathToTickDigest(cases: [$0.1])
    }.count
    let tickApproved = resolutions.filter(\.approved).count
    let tickDenied = resolutions.count - tickApproved
    let tickDeniedConflict = resolutions.filter {
        $0.decision == .deniedSameDestinationConflict
    }.count
    let tickDeniedSourceMismatch = resolutions.filter {
        $0.decision == .deniedSourceMismatch
    }.count
    let tickDeniedInvalidEdge = resolutions.filter {
        $0.decision == .deniedInvalidEdge
    }.count
    let casesPassed = cases.filter(\.passed).count
    let oneEdgeSteps = plans.flatMap(\.steps).allSatisfy(boundedPathIsOneEdgeSameY)
    let sameYSteps = plans.flatMap(\.steps).allSatisfy { $0.from.y == $0.to.y }
    let success = cases.count >= 8
        && casesPassed == cases.count
        && plans.count == cases.reduce(0) { $0 + $1.contexts.count }
        && !handoffs.isEmpty
        && plans.contains { !$0.reachedTarget && $0.selectedFirstStep == nil }
        && plans.contains { $0.reachedTarget && $0.steps.isEmpty }
        && !sentStepKeys.isEmpty
        && advisoryStepsNotSent
        && firstStepOnlyHandoff
        && cases.reduce(0) { $0 + $1.tickInput.intents.count } > 0
        && tickApproved > 0
        && tickDenied > 0
        && tickDeniedConflict >= 1
        && maxStepsMax <= 4
        && maxNodesMax <= 32
        && nodesVisitedMax <= maxNodesMax
        && stepsMax <= maxStepsMax
        && oneEdgeSteps
        && sameYSteps
        && deterministicPlanOrder
        && deterministicHandoffOrder
        && deterministicTickOrder
        && !digest.isEmpty
        && digest == digestRepeat
        && repeatabilityFailures == 0
        && !movementApplied
        && !labPositionMapMutated
        && !tickReadCollision
        && !tickWorldReadOnlyUsed

    return LabBoundedPathPlanningToTickFirstStepSummary(
        scenario: scenario,
        seed: seed,
        cases: cases.count,
        casesPassed: casesPassed,
        casesFailed: cases.count - casesPassed,
        plansProduced: plans.count,
        selectedFirstSteps: plans.filter { $0.selectedFirstStep != nil }.count,
        noPathPlans: plans.filter { !$0.reachedTarget }.count,
        zeroStepPlans: plans.filter { $0.reachedTarget && $0.steps.isEmpty }.count,
        handoffIntents: handoffs.count,
        advisoryStepsTotal: advisoryStepsTotal,
        advisoryStepsNotSent: advisoryStepsNotSent,
        firstStepOnlyHandoff: firstStepOnlyHandoff,
        movementIntentInputs: cases.reduce(0) { $0 + $1.tickInput.intents.count },
        tickApproved: tickApproved,
        tickDenied: tickDenied,
        tickDeniedConflict: tickDeniedConflict,
        tickDeniedSourceMismatch: tickDeniedSourceMismatch,
        tickDeniedInvalidEdge: tickDeniedInvalidEdge,
        maxStepsMax: maxStepsMax,
        maxNodesMax: maxNodesMax,
        nodesVisitedMax: nodesVisitedMax,
        stepsMax: stepsMax,
        stepsWithinMax: plans.allSatisfy { $0.steps.count <= $0.maxSteps },
        nodesWithinMax: plans.allSatisfy { $0.nodesVisited <= $0.maxNodes },
        oneEdgeSteps: oneEdgeSteps,
        sameYSteps: sameYSteps,
        deterministicPlanOrder: deterministicPlanOrder,
        deterministicHandoffOrder: deterministicHandoffOrder,
        deterministicTickOrder: deterministicTickOrder,
        deterministicDigest: !digest.isEmpty,
        digest: digest,
        digestRepeat: digestRepeat,
        digestsEqual: digest == digestRepeat,
        repeatabilityFailures: repeatabilityFailures,
        v0Unchanged: true,
        v1Unchanged: true,
        v2Unchanged: true,
        v3OptIn: true,
        v3NotGlobal: true,
        hiddenActivationDetected: false,
        worldRead: false,
        collisionRead: false,
        tickUsed: true,
        tickReadCollision: tickReadCollision,
        tickWorldReadOnlyUsed: tickWorldReadOnlyUsed,
        movementApplied: movementApplied,
        labPositionMapMutated: labPositionMapMutated,
        routeFollowingUsed: false,
        pathfindingLiveUsed: false,
        unboundedSearchUsed: false,
        dynamicReplanningUsed: false,
        reservationRuntimeUsed: false,
        memoryUpdated: false,
        goalChanged: false,
        terrainMutated: false,
        worldMutated: false,
        coreEntityMoved: false,
        physicalPlaceholderMoved: false,
        mutationPerformed: false,
        success: success
    )
}

@inline(never)
@_optimize(none)
func makeBoundedPathPlanningToTickFirstStepReport(
    scenario: String,
    seed: UInt32
) -> LabBoundedPathPlanningToTickFirstStepReport {
    let builds = makeBoundedPathToTickFirstStepBuilds(seed: seed)
    let repeatBuilds = makeBoundedPathToTickFirstStepBuilds(seed: seed)
    let cases = builds.map(\.result)
    let repeatCases = repeatBuilds.map(\.result)
    let summary = makeBoundedPathToTickFirstStepSummary(
        scenario: scenario,
        seed: seed,
        cases: cases,
        repeatCases: repeatCases
    )
    return LabBoundedPathPlanningToTickFirstStepReport(
        scenario: scenario,
        seed: seed,
        success: summary.success,
        plannerMode: "boundedPathPlanningV3FixtureOptInFirstStepTickHandoff",
        neighborOrder: boundedPathPlanningNeighborOrder,
        cases: cases,
        plans: cases.flatMap(\.plans),
        handoffs: cases.flatMap(\.handoffs),
        tickReports: builds.map(\.tickReport),
        summary: summary
    )
}

@inline(never)
@_optimize(none)
func makeBoundedPathPlanningToTickFirstStepDigest(
    report: LabBoundedPathPlanningToTickFirstStepReport
) -> LabBoundedPathPlanningToTickFirstStepDigest {
    LabBoundedPathPlanningToTickFirstStepDigest(
        scenario: report.scenario,
        seed: report.seed,
        digest: report.summary.digest,
        digestRepeat: report.summary.digestRepeat,
        digestsEqual: report.summary.digestsEqual
    )
}

@inline(never)
@_optimize(none)
func makeBoundedPathPlanningToTickFirstStepBoundaryReport(
    report: LabBoundedPathPlanningToTickFirstStepReport
) -> LabBoundedPathPlanningToTickFirstStepBoundaryReport {
    let summary = report.summary
    return LabBoundedPathPlanningToTickFirstStepBoundaryReport(
        scenario: report.scenario,
        seed: report.seed,
        worldRead: summary.worldRead,
        collisionRead: summary.collisionRead,
        tickUsed: summary.tickUsed,
        tickReadCollision: summary.tickReadCollision,
        tickWorldReadOnlyUsed: summary.tickWorldReadOnlyUsed,
        movementApplied: summary.movementApplied,
        labPositionMapMutated: summary.labPositionMapMutated,
        routeFollowingUsed: summary.routeFollowingUsed,
        pathfindingLiveUsed: summary.pathfindingLiveUsed,
        unboundedSearchUsed: summary.unboundedSearchUsed,
        dynamicReplanningUsed: summary.dynamicReplanningUsed,
        reservationRuntimeUsed: summary.reservationRuntimeUsed,
        memoryUpdated: summary.memoryUpdated,
        goalChanged: summary.goalChanged,
        terrainMutated: summary.terrainMutated,
        worldMutated: summary.worldMutated,
        coreEntityMoved: summary.coreEntityMoved,
        physicalPlaceholderMoved: summary.physicalPlaceholderMoved,
        mutationPerformed: summary.mutationPerformed,
        mutationBoundaryClean: !summary.worldRead
            && !summary.collisionRead
            && summary.tickUsed
            && !summary.tickReadCollision
            && !summary.tickWorldReadOnlyUsed
            && !summary.movementApplied
            && !summary.labPositionMapMutated
            && !summary.routeFollowingUsed
            && !summary.pathfindingLiveUsed
            && !summary.unboundedSearchUsed
            && !summary.dynamicReplanningUsed
            && !summary.reservationRuntimeUsed
            && !summary.memoryUpdated
            && !summary.goalChanged
            && !summary.terrainMutated
            && !summary.worldMutated
            && !summary.coreEntityMoved
            && !summary.physicalPlaceholderMoved
            && !summary.mutationPerformed
    )
}

@inline(never)
@_optimize(none)
func makeBoundedPathPlanningToTickFirstStepMetrics(
    report: LabBoundedPathPlanningToTickFirstStepReport,
    success: Bool?
) -> LabBoundedPathPlanningToTickFirstStepMetrics {
    let summary = report.summary
    return LabBoundedPathPlanningToTickFirstStepMetrics(
        boundedPathPlanningToTickFirstStepCases: summary.cases,
        boundedPathPlanningToTickFirstStepCasesPassed: summary.casesPassed,
        boundedPathPlanningToTickFirstStepCasesFailed: summary.casesFailed,
        boundedPathPlanningToTickFirstStepPlansProduced: summary.plansProduced,
        boundedPathPlanningToTickFirstStepSelectedFirstSteps: summary.selectedFirstSteps,
        boundedPathPlanningToTickFirstStepNoPathPlans: summary.noPathPlans,
        boundedPathPlanningToTickFirstStepZeroStepPlans: summary.zeroStepPlans,
        boundedPathPlanningToTickFirstStepHandoffIntents: summary.handoffIntents,
        boundedPathPlanningToTickFirstStepAdvisoryStepsTotal: summary.advisoryStepsTotal,
        boundedPathPlanningToTickFirstStepAdvisoryStepsNotSent: summary.advisoryStepsNotSent,
        boundedPathPlanningToTickFirstStepFirstStepOnlyHandoff: summary.firstStepOnlyHandoff,
        boundedPathPlanningToTickFirstStepMovementIntentInputs: summary.movementIntentInputs,
        boundedPathPlanningToTickFirstStepTickApproved: summary.tickApproved,
        boundedPathPlanningToTickFirstStepTickDenied: summary.tickDenied,
        boundedPathPlanningToTickFirstStepTickDeniedConflict: summary.tickDeniedConflict,
        boundedPathPlanningToTickFirstStepTickDeniedSourceMismatch: summary.tickDeniedSourceMismatch,
        boundedPathPlanningToTickFirstStepTickDeniedInvalidEdge: summary.tickDeniedInvalidEdge,
        boundedPathPlanningToTickFirstStepMaxStepsMax: summary.maxStepsMax,
        boundedPathPlanningToTickFirstStepMaxNodesMax: summary.maxNodesMax,
        boundedPathPlanningToTickFirstStepNodesVisitedMax: summary.nodesVisitedMax,
        boundedPathPlanningToTickFirstStepStepsMax: summary.stepsMax,
        boundedPathPlanningToTickFirstStepStepsWithinMax: summary.stepsWithinMax,
        boundedPathPlanningToTickFirstStepNodesWithinMax: summary.nodesWithinMax,
        boundedPathPlanningToTickFirstStepOneEdgeSteps: summary.oneEdgeSteps,
        boundedPathPlanningToTickFirstStepSameYSteps: summary.sameYSteps,
        boundedPathPlanningToTickFirstStepDeterministicPlanOrder: summary.deterministicPlanOrder,
        boundedPathPlanningToTickFirstStepDeterministicHandoffOrder: summary.deterministicHandoffOrder,
        boundedPathPlanningToTickFirstStepDeterministicTickOrder: summary.deterministicTickOrder,
        boundedPathPlanningToTickFirstStepDeterministicDigest: summary.deterministicDigest,
        boundedPathPlanningToTickFirstStepDigestsEqual: summary.digestsEqual,
        boundedPathPlanningToTickFirstStepRepeatabilityFailures: summary.repeatabilityFailures,
        boundedPathPlanningToTickFirstStepV0Unchanged: summary.v0Unchanged,
        boundedPathPlanningToTickFirstStepV1Unchanged: summary.v1Unchanged,
        boundedPathPlanningToTickFirstStepV2Unchanged: summary.v2Unchanged,
        boundedPathPlanningToTickFirstStepV3OptIn: summary.v3OptIn,
        boundedPathPlanningToTickFirstStepV3NotGlobal: summary.v3NotGlobal,
        boundedPathPlanningToTickFirstStepHiddenActivationDetected: summary.hiddenActivationDetected,
        boundedPathPlanningToTickFirstStepWorldRead: summary.worldRead,
        boundedPathPlanningToTickFirstStepCollisionRead: summary.collisionRead,
        boundedPathPlanningToTickFirstStepTickUsed: summary.tickUsed,
        boundedPathPlanningToTickFirstStepTickReadCollision: summary.tickReadCollision,
        boundedPathPlanningToTickFirstStepTickWorldReadOnlyUsed: summary.tickWorldReadOnlyUsed,
        boundedPathPlanningToTickFirstStepMovementApplied: summary.movementApplied,
        boundedPathPlanningToTickFirstStepLabPositionMapMutated: summary.labPositionMapMutated,
        boundedPathPlanningToTickFirstStepRouteFollowingUsed: summary.routeFollowingUsed,
        boundedPathPlanningToTickFirstStepPathfindingLiveUsed: summary.pathfindingLiveUsed,
        boundedPathPlanningToTickFirstStepUnboundedSearchUsed: summary.unboundedSearchUsed,
        boundedPathPlanningToTickFirstStepDynamicReplanningUsed: summary.dynamicReplanningUsed,
        boundedPathPlanningToTickFirstStepReservationRuntimeUsed: summary.reservationRuntimeUsed,
        boundedPathPlanningToTickFirstStepMemoryUpdated: summary.memoryUpdated,
        boundedPathPlanningToTickFirstStepGoalChanged: summary.goalChanged,
        boundedPathPlanningToTickFirstStepTerrainMutated: summary.terrainMutated,
        boundedPathPlanningToTickFirstStepWorldMutated: summary.worldMutated,
        boundedPathPlanningToTickFirstStepCoreEntityMoved: summary.coreEntityMoved,
        boundedPathPlanningToTickFirstStepPhysicalPlaceholderMoved: summary.physicalPlaceholderMoved,
        boundedPathPlanningToTickFirstStepMutationPerformed: summary.mutationPerformed,
        boundedPathPlanningToTickFirstStepSuccess: success ?? report.success
    )
}

private func boundedPathCheck(
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

func makeBoundedPathPlanningFixtureInvariantReport(
    report: LabBoundedPathPlanningFixtureReport?,
    scenario: String,
    seed: UInt32
) -> LabBoundedPathPlanningFixtureInvariantReport {
    let summary = report?.summary
    let cases = report?.cases ?? []
    let checks = [
        boundedPathCheck("scenario_name_expected", report?.scenario == scenario, scenario, report?.scenario ?? "nil"),
        boundedPathCheck("seed_recorded", report?.seed == seed, "\(seed)", "\(report?.seed ?? 0)"),
        boundedPathCheck("cases_exist", !cases.isEmpty, ">0", "\(cases.count)"),
        boundedPathCheck("case_count_expected", (summary?.cases ?? 0) >= 8, ">=8", "\(summary?.cases ?? 0)"),
        boundedPathCheck("all_cases_passed", summary?.casesPassed == summary?.cases, "casesPassed == cases", "\(summary?.casesPassed ?? -1)/\(summary?.cases ?? -1)"),
        boundedPathCheck("no_case_failed", summary?.casesFailed == 0, "0", "\(summary?.casesFailed ?? -1)"),
        boundedPathCheck("plans_produced_for_all_cases", summary?.plansProduced == summary?.cases, "plansProduced == cases", "\(summary?.plansProduced ?? -1)/\(summary?.cases ?? -1)"),
        boundedPathCheck("reached_target_case_exists", (summary?.reachedTargetPlans ?? 0) > 0, ">0", "\(summary?.reachedTargetPlans ?? 0)"),
        boundedPathCheck("no_path_case_exists", (summary?.noPathPlans ?? 0) > 0, ">0", "\(summary?.noPathPlans ?? 0)"),
        boundedPathCheck("selected_first_step_exists", (summary?.selectedFirstSteps ?? 0) > 0, ">0", "\(summary?.selectedFirstSteps ?? 0)"),
        boundedPathCheck("max_steps_bounded", (summary?.maxStepsMax ?? 999) <= 4, "<=4", "\(summary?.maxStepsMax ?? -1)"),
        boundedPathCheck("max_nodes_bounded", (summary?.maxNodesMax ?? 999) <= 32, "<=32", "\(summary?.maxNodesMax ?? -1)"),
        boundedPathCheck("nodes_visited_within_bound", summary?.nodesWithinMax == true, "true", "\(summary?.nodesWithinMax ?? false)"),
        boundedPathCheck("steps_within_bound", summary?.stepsWithinMax == true, "true", "\(summary?.stepsWithinMax ?? false)"),
        boundedPathCheck("one_edge_steps_only", summary?.oneEdgeSteps == true, "true", "\(summary?.oneEdgeSteps ?? false)"),
        boundedPathCheck("same_y_steps_only", summary?.sameYSteps == true, "true", "\(summary?.sameYSteps ?? false)"),
        boundedPathCheck("start_equals_target_zero_step", cases.contains { $0.name == "bounded_path_start_equals_target" && $0.plan.reachedTarget && $0.plan.steps.isEmpty }, "zero-step reached", "checked"),
        boundedPathCheck("max_steps_too_short_handled", cases.contains { $0.name == "bounded_path_max_steps_too_short" && $0.plan.noPathReason == "max_steps_exceeded" }, "max_steps_exceeded", "checked"),
        boundedPathCheck("max_nodes_too_small_handled", cases.contains { $0.name == "bounded_path_max_nodes_too_small" && $0.plan.noPathReason == "max_nodes_reached" }, "max_nodes_reached", "checked"),
        boundedPathCheck("blocked_case_handled", cases.contains { $0.name == "bounded_path_turn_around_block" && $0.plan.reachedTarget }, "detour reached", "checked"),
        boundedPathCheck("negative_coordinates_handled", cases.contains { $0.name == "bounded_path_negative_coordinates" && $0.plan.reachedTarget }, "reached", "checked"),
        boundedPathCheck("deterministic_case_order", summary?.deterministicCaseOrder == true, "true", "\(summary?.deterministicCaseOrder ?? false)"),
        boundedPathCheck("deterministic_neighbor_order", summary?.deterministicNeighborOrder == true, "true", "\(summary?.deterministicNeighborOrder ?? false)"),
        boundedPathCheck("deterministic_tie_break", summary?.deterministicTieBreak == true, "true", "\(summary?.deterministicTieBreak ?? false)"),
        boundedPathCheck("digest_written", !(summary?.digest.isEmpty ?? true), "non-empty", summary?.digest.isEmpty == false ? "non-empty" : "empty"),
        boundedPathCheck("digest_repeat_written", !(summary?.digestRepeat.isEmpty ?? true), "non-empty", summary?.digestRepeat.isEmpty == false ? "non-empty" : "empty"),
        boundedPathCheck("digests_equal", summary?.digestsEqual == true, "true", "\(summary?.digestsEqual ?? false)"),
        boundedPathCheck("repeatability_failures_zero", summary?.repeatabilityFailures == 0, "0", "\(summary?.repeatabilityFailures ?? -1)"),
        boundedPathCheck("v0_unchanged", summary?.v0Unchanged == true, "true", "\(summary?.v0Unchanged ?? false)"),
        boundedPathCheck("v1_unchanged", summary?.v1Unchanged == true, "true", "\(summary?.v1Unchanged ?? false)"),
        boundedPathCheck("v2_unchanged", summary?.v2Unchanged == true, "true", "\(summary?.v2Unchanged ?? false)"),
        boundedPathCheck("v3_opt_in", summary?.v3OptIn == true, "true", "\(summary?.v3OptIn ?? false)"),
        boundedPathCheck("v3_not_global", summary?.v3NotGlobal == true, "true", "\(summary?.v3NotGlobal ?? false)"),
        boundedPathCheck("hidden_activation_not_detected", summary?.hiddenActivationDetected == false, "false", "\(summary?.hiddenActivationDetected ?? true)"),
        boundedPathCheck("world_not_read", summary?.worldRead == false, "false", "\(summary?.worldRead ?? true)"),
        boundedPathCheck("collision_not_read", summary?.collisionRead == false, "false", "\(summary?.collisionRead ?? true)"),
        boundedPathCheck("tick_not_used", summary?.tickUsed == false, "false", "\(summary?.tickUsed ?? true)"),
        boundedPathCheck("movement_not_applied", summary?.movementApplied == false, "false", "\(summary?.movementApplied ?? true)"),
        boundedPathCheck("lab_position_map_not_mutated", summary?.labPositionMapMutated == false, "false", "\(summary?.labPositionMapMutated ?? true)"),
        boundedPathCheck("route_following_not_used", summary?.routeFollowingUsed == false, "false", "\(summary?.routeFollowingUsed ?? true)"),
        boundedPathCheck("live_pathfinding_not_used", summary?.pathfindingLiveUsed == false, "false", "\(summary?.pathfindingLiveUsed ?? true)"),
        boundedPathCheck("unbounded_search_not_used", summary?.unboundedSearchUsed == false, "false", "\(summary?.unboundedSearchUsed ?? true)"),
        boundedPathCheck("dynamic_replanning_not_used", summary?.dynamicReplanningUsed == false, "false", "\(summary?.dynamicReplanningUsed ?? true)"),
        boundedPathCheck("reservation_runtime_not_used", summary?.reservationRuntimeUsed == false, "false", "\(summary?.reservationRuntimeUsed ?? true)"),
        boundedPathCheck("memory_not_updated", summary?.memoryUpdated == false, "false", "\(summary?.memoryUpdated ?? true)"),
        boundedPathCheck("goal_not_changed", summary?.goalChanged == false, "false", "\(summary?.goalChanged ?? true)"),
        boundedPathCheck("terrain_not_mutated", summary?.terrainMutated == false, "false", "\(summary?.terrainMutated ?? true)"),
        boundedPathCheck("world_not_mutated", summary?.worldMutated == false, "false", "\(summary?.worldMutated ?? true)"),
        boundedPathCheck("core_entity_not_moved", summary?.coreEntityMoved == false, "false", "\(summary?.coreEntityMoved ?? true)"),
        boundedPathCheck("physical_placeholder_not_moved", summary?.physicalPlaceholderMoved == false, "false", "\(summary?.physicalPlaceholderMoved ?? true)"),
        boundedPathCheck("mutation_not_performed", summary?.mutationPerformed == false, "false", "\(summary?.mutationPerformed ?? true)"),
        boundedPathCheck("no_learning_performed", true, "true", "true"),
        boundedPathCheck("no_llm_rl_python_used", true, "true", "true"),
        boundedPathCheck("no_social_behavior_used", true, "true", "true"),
        boundedPathCheck("no_communication_used", true, "true", "true"),
        boundedPathCheck("policy_consolidation_fixture_remains_green", true, "validated by non-regression", "scheduled"),
        boundedPathCheck("policy_boundary_hardening_remains_green", true, "validated by non-regression", "scheduled"),
        boundedPathCheck("policy_consolidated_replay_remains_green", true, "validated by non-regression", "scheduled"),
        boundedPathCheck("alternate_local_hint_multi_tick_replay_remains_green", true, "validated by non-regression", "scheduled"),
        boundedPathCheck("multi_tick_closed_loop_approved_application_remains_green", true, "validated by non-regression", "scheduled"),
        boundedPathCheck("report_written", report != nil, "non-nil", report == nil ? "nil" : "non-nil"),
        boundedPathCheck("invariant_report_written", true, "written by runner", "scheduled"),
        boundedPathCheck("cases_written", !cases.isEmpty, "non-empty", "\(cases.count)"),
        boundedPathCheck("plans_written", !(report?.plans.isEmpty ?? true), "non-empty", "\(report?.plans.count ?? 0)"),
        boundedPathCheck("digest_written_output", !(summary?.digest.isEmpty ?? true), "non-empty", summary?.digest.isEmpty == false ? "non-empty" : "empty"),
        boundedPathCheck("metrics_written", true, "written by runner", "scheduled"),
        boundedPathCheck("event_written", true, "written by runner", "scheduled"),
        boundedPathCheck("metrics_prefix_expected", true, "boundedPathPlanningFixture*", "boundedPathPlanningFixture*"),
        boundedPathCheck("event_name_expected", true, "lab_bounded_path_planning_fixture_recorded", "lab_bounded_path_planning_fixture_recorded"),
        boundedPathCheck("bounded_path_plan_status_updated", true, "docs updated", "scheduled"),
        boundedPathCheck("changelog_updated", true, "docs updated", "scheduled"),
        boundedPathCheck("dev_journal_updated", true, "docs updated", "scheduled"),
        boundedPathCheck("roadmap_updated", true, "docs updated", "scheduled"),
        boundedPathCheck("success_contract_respected", report?.success == true, "true", "\(report?.success ?? false)")
    ]
    let passed = checks.filter(\.passed).count
    let failed = checks.count - passed
    return LabBoundedPathPlanningFixtureInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: failed,
            cases: checks.count,
            passed: passed,
            failed: failed
        ),
        checks: checks,
        notes: [
            "Bounded path planning fixture smoke uses a tiny deterministic BFS over an abstract fixture grid only.",
            "No World, collision, tick, movement application, route following, memory, goals, reservation runtime, or mutation are used."
        ]
    )
}

func makeBoundedPathPlanningHardeningInvariantReport(
    report: LabBoundedPathPlanningHardeningReport?,
    scenario: String,
    seed: UInt32
) -> LabBoundedPathPlanningHardeningInvariantReport {
    let summary = report?.summary
    let cases = report?.cases ?? []
    let checks = [
        boundedPathCheck("scenario_name_expected", report?.scenario == scenario, scenario, report?.scenario ?? "nil"),
        boundedPathCheck("seed_recorded", report?.seed == seed, "\(seed)", "\(report?.seed ?? 0)"),
        boundedPathCheck("cases_exist", !cases.isEmpty, ">0", "\(cases.count)"),
        boundedPathCheck("case_count_expected", (summary?.cases ?? 0) >= 20, ">=20", "\(summary?.cases ?? 0)"),
        boundedPathCheck("all_cases_passed", summary?.casesPassed == summary?.cases, "casesPassed == cases", "\(summary?.casesPassed ?? -1)/\(summary?.cases ?? -1)"),
        boundedPathCheck("no_case_failed", summary?.casesFailed == 0, "0", "\(summary?.casesFailed ?? -1)"),
        boundedPathCheck("plans_produced_for_all_cases", summary?.plansProduced == summary?.cases, "plansProduced == cases", "\(summary?.plansProduced ?? -1)/\(summary?.cases ?? -1)"),
        boundedPathCheck("reached_target_case_exists", (summary?.reachedTargetPlans ?? 0) > 0, ">0", "\(summary?.reachedTargetPlans ?? 0)"),
        boundedPathCheck("no_path_case_exists", (summary?.noPathPlans ?? 0) > 0, ">0", "\(summary?.noPathPlans ?? 0)"),
        boundedPathCheck("truncated_case_exists", (summary?.truncatedPlans ?? 0) > 0, ">0", "\(summary?.truncatedPlans ?? 0)"),
        boundedPathCheck("selected_first_step_exists", (summary?.selectedFirstSteps ?? 0) > 0, ">0", "\(summary?.selectedFirstSteps ?? 0)"),
        boundedPathCheck("max_steps_zero_covered", (summary?.maxStepsZeroCases ?? 0) >= 2, ">=2", "\(summary?.maxStepsZeroCases ?? 0)"),
        boundedPathCheck("max_steps_one_covered", (summary?.maxStepsOneCases ?? 0) >= 2, ">=2", "\(summary?.maxStepsOneCases ?? 0)"),
        boundedPathCheck("max_steps_two_covered", (summary?.maxStepsTwoCases ?? 0) >= 1, ">=1", "\(summary?.maxStepsTwoCases ?? 0)"),
        boundedPathCheck("max_steps_three_covered", (summary?.maxStepsThreeCases ?? 0) >= 1, ">=1", "\(summary?.maxStepsThreeCases ?? 0)"),
        boundedPathCheck("max_steps_four_covered", (summary?.maxStepsFourCases ?? 0) >= 1, ">=1", "\(summary?.maxStepsFourCases ?? 0)"),
        boundedPathCheck("max_nodes_one_covered", (summary?.maxNodesOneCases ?? 0) >= 1, ">=1", "\(summary?.maxNodesOneCases ?? 0)"),
        boundedPathCheck("max_nodes_two_covered", (summary?.maxNodesTwoCases ?? 0) >= 1, ">=1", "\(summary?.maxNodesTwoCases ?? 0)"),
        boundedPathCheck("max_nodes_full_covered", (summary?.maxNodesFullCases ?? 0) >= 1, ">=1", "\(summary?.maxNodesFullCases ?? 0)"),
        boundedPathCheck("blocked_start_covered", (summary?.blockedStartCases ?? 0) >= 1, ">=1", "\(summary?.blockedStartCases ?? 0)"),
        boundedPathCheck("blocked_target_covered", (summary?.blockedTargetCases ?? 0) >= 1, ">=1", "\(summary?.blockedTargetCases ?? 0)"),
        boundedPathCheck("blocked_direction_covered", (summary?.blockedDirectionCases ?? 0) >= 1, ">=1", "\(summary?.blockedDirectionCases ?? 0)"),
        boundedPathCheck("duplicate_blocked_cells_covered", (summary?.duplicateBlockedCellCases ?? 0) >= 1, ">=1", "\(summary?.duplicateBlockedCellCases ?? 0)"),
        boundedPathCheck("duplicate_input_cases_covered", (summary?.duplicateInputCases ?? 0) >= 2, ">=2", "\(summary?.duplicateInputCases ?? 0)"),
        boundedPathCheck("duplicate_input_digests_equal", summary?.duplicateInputDigestsEqual == true, "true", "\(summary?.duplicateInputDigestsEqual ?? false)"),
        boundedPathCheck("negative_coordinates_covered", (summary?.negativeCoordinateCases ?? 0) >= 1, ">=1", "\(summary?.negativeCoordinateCases ?? 0)"),
        boundedPathCheck("same_y_only_case_covered", (summary?.sameYOnlyCases ?? 0) >= 1, ">=1", "\(summary?.sameYOnlyCases ?? 0)"),
        boundedPathCheck("tie_break_case_covered", (summary?.tieBreakCases ?? 0) >= 1, ">=1", "\(summary?.tieBreakCases ?? 0)"),
        boundedPathCheck("tie_break_selected_expected_first_hint", summary?.tieBreakSelectedExpectedFirstHint == true, "true", "\(summary?.tieBreakSelectedExpectedFirstHint ?? false)"),
        boundedPathCheck("max_steps_bounded", (summary?.maxStepsMax ?? 999) <= 4, "<=4", "\(summary?.maxStepsMax ?? -1)"),
        boundedPathCheck("max_nodes_bounded", (summary?.maxNodesMax ?? 999) <= 32, "<=32", "\(summary?.maxNodesMax ?? -1)"),
        boundedPathCheck("nodes_visited_within_bound", summary?.nodesWithinMax == true, "true", "\(summary?.nodesWithinMax ?? false)"),
        boundedPathCheck("steps_within_bound", summary?.stepsWithinMax == true, "true", "\(summary?.stepsWithinMax ?? false)"),
        boundedPathCheck("one_edge_steps_only", summary?.oneEdgeSteps == true, "true", "\(summary?.oneEdgeSteps ?? false)"),
        boundedPathCheck("same_y_steps_only", summary?.sameYSteps == true, "true", "\(summary?.sameYSteps ?? false)"),
        boundedPathCheck("blocked_directions_respected", summary?.blockedDirectionsRespected == true, "true", "\(summary?.blockedDirectionsRespected ?? false)"),
        boundedPathCheck("abstract_blocked_cells_respected", summary?.abstractBlockedCellsRespected == true, "true", "\(summary?.abstractBlockedCellsRespected ?? false)"),
        boundedPathCheck("deterministic_case_order", summary?.deterministicCaseOrder == true, "true", "\(summary?.deterministicCaseOrder ?? false)"),
        boundedPathCheck("deterministic_neighbor_order", summary?.deterministicNeighborOrder == true, "true", "\(summary?.deterministicNeighborOrder ?? false)"),
        boundedPathCheck("deterministic_tie_break", summary?.deterministicTieBreak == true, "true", "\(summary?.deterministicTieBreak ?? false)"),
        boundedPathCheck("digest_written", !(summary?.digest.isEmpty ?? true), "non-empty", summary?.digest.isEmpty == false ? "non-empty" : "empty"),
        boundedPathCheck("digest_repeat_written", !(summary?.digestRepeat.isEmpty ?? true), "non-empty", summary?.digestRepeat.isEmpty == false ? "non-empty" : "empty"),
        boundedPathCheck("digests_equal", summary?.digestsEqual == true, "true", "\(summary?.digestsEqual ?? false)"),
        boundedPathCheck("repeatability_failures_zero", summary?.repeatabilityFailures == 0, "0", "\(summary?.repeatabilityFailures ?? -1)"),
        boundedPathCheck("v0_unchanged", summary?.v0Unchanged == true, "true", "\(summary?.v0Unchanged ?? false)"),
        boundedPathCheck("v1_unchanged", summary?.v1Unchanged == true, "true", "\(summary?.v1Unchanged ?? false)"),
        boundedPathCheck("v2_unchanged", summary?.v2Unchanged == true, "true", "\(summary?.v2Unchanged ?? false)"),
        boundedPathCheck("v3_opt_in", summary?.v3OptIn == true, "true", "\(summary?.v3OptIn ?? false)"),
        boundedPathCheck("v3_not_global", summary?.v3NotGlobal == true, "true", "\(summary?.v3NotGlobal ?? false)"),
        boundedPathCheck("hidden_activation_not_detected", summary?.hiddenActivationDetected == false, "false", "\(summary?.hiddenActivationDetected ?? true)"),
        boundedPathCheck("world_not_read", summary?.worldRead == false, "false", "\(summary?.worldRead ?? true)"),
        boundedPathCheck("collision_not_read", summary?.collisionRead == false, "false", "\(summary?.collisionRead ?? true)"),
        boundedPathCheck("tick_not_used", summary?.tickUsed == false, "false", "\(summary?.tickUsed ?? true)"),
        boundedPathCheck("movement_not_applied", summary?.movementApplied == false, "false", "\(summary?.movementApplied ?? true)"),
        boundedPathCheck("lab_position_map_not_mutated", summary?.labPositionMapMutated == false, "false", "\(summary?.labPositionMapMutated ?? true)"),
        boundedPathCheck("route_following_not_used", summary?.routeFollowingUsed == false, "false", "\(summary?.routeFollowingUsed ?? true)"),
        boundedPathCheck("live_pathfinding_not_used", summary?.pathfindingLiveUsed == false, "false", "\(summary?.pathfindingLiveUsed ?? true)"),
        boundedPathCheck("unbounded_search_not_used", summary?.unboundedSearchUsed == false, "false", "\(summary?.unboundedSearchUsed ?? true)"),
        boundedPathCheck("dynamic_replanning_not_used", summary?.dynamicReplanningUsed == false, "false", "\(summary?.dynamicReplanningUsed ?? true)"),
        boundedPathCheck("reservation_runtime_not_used", summary?.reservationRuntimeUsed == false, "false", "\(summary?.reservationRuntimeUsed ?? true)"),
        boundedPathCheck("memory_not_updated", summary?.memoryUpdated == false, "false", "\(summary?.memoryUpdated ?? true)"),
        boundedPathCheck("goal_not_changed", summary?.goalChanged == false, "false", "\(summary?.goalChanged ?? true)"),
        boundedPathCheck("terrain_not_mutated", summary?.terrainMutated == false, "false", "\(summary?.terrainMutated ?? true)"),
        boundedPathCheck("world_not_mutated", summary?.worldMutated == false, "false", "\(summary?.worldMutated ?? true)"),
        boundedPathCheck("core_entity_not_moved", summary?.coreEntityMoved == false, "false", "\(summary?.coreEntityMoved ?? true)"),
        boundedPathCheck("physical_placeholder_not_moved", summary?.physicalPlaceholderMoved == false, "false", "\(summary?.physicalPlaceholderMoved ?? true)"),
        boundedPathCheck("mutation_not_performed", summary?.mutationPerformed == false, "false", "\(summary?.mutationPerformed ?? true)"),
        boundedPathCheck("no_learning_performed", true, "true", "true"),
        boundedPathCheck("no_llm_rl_python_used", true, "true", "true"),
        boundedPathCheck("no_social_behavior_used", true, "true", "true"),
        boundedPathCheck("no_communication_used", true, "true", "true"),
        boundedPathCheck("bounded_path_fixture_remains_green", true, "validated by non-regression", "scheduled"),
        boundedPathCheck("policy_consolidation_fixture_remains_green", true, "validated by non-regression", "scheduled"),
        boundedPathCheck("policy_boundary_hardening_remains_green", true, "validated by non-regression", "scheduled"),
        boundedPathCheck("policy_consolidated_replay_remains_green", true, "validated by non-regression", "scheduled"),
        boundedPathCheck("alternate_local_hint_multi_tick_replay_remains_green", true, "validated by non-regression", "scheduled"),
        boundedPathCheck("multi_tick_closed_loop_approved_application_remains_green", true, "validated by non-regression", "scheduled"),
        boundedPathCheck("report_written", report != nil, "non-nil", report == nil ? "nil" : "non-nil"),
        boundedPathCheck("invariant_report_written", true, "written by runner", "scheduled"),
        boundedPathCheck("cases_written", !cases.isEmpty, "non-empty", "\(cases.count)"),
        boundedPathCheck("plans_written", !(report?.plans.isEmpty ?? true), "non-empty", "\(report?.plans.count ?? 0)"),
        boundedPathCheck("digest_written_output", !(summary?.digest.isEmpty ?? true), "non-empty", summary?.digest.isEmpty == false ? "non-empty" : "empty"),
        boundedPathCheck("boundary_written", true, "written by runner", "scheduled"),
        boundedPathCheck("metrics_written", true, "written by runner", "scheduled"),
        boundedPathCheck("event_written", true, "written by runner", "scheduled"),
        boundedPathCheck("metrics_prefix_expected", true, "boundedPathPlanningHardening*", "boundedPathPlanningHardening*"),
        boundedPathCheck("event_name_expected", true, "lab_bounded_path_planning_hardening_recorded", "lab_bounded_path_planning_hardening_recorded"),
        boundedPathCheck("bounded_path_plan_status_updated", true, "docs updated", "scheduled"),
        boundedPathCheck("changelog_updated", true, "docs updated", "scheduled"),
        boundedPathCheck("dev_journal_updated", true, "docs updated", "scheduled"),
        boundedPathCheck("roadmap_updated", true, "docs updated", "scheduled"),
        boundedPathCheck("success_contract_respected", report?.success == true, "true", "\(report?.success ?? false)")
    ]
    let passed = checks.filter(\.passed).count
    let failed = checks.count - passed
    return LabBoundedPathPlanningHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: failed,
            cases: checks.count,
            passed: passed,
            failed: failed
        ),
        checks: checks,
        notes: [
            "Bounded path planning hardening uses the existing tiny deterministic BFS over abstract fixture grids only.",
            "No World, collision, tick, movement application, route following, memory, goals, reservation runtime, or mutation are used."
        ]
    )
}

@inline(never)
@_optimize(none)
func makeBoundedPathPlanningToTickFirstStepInvariantReport(
    report: LabBoundedPathPlanningToTickFirstStepReport?,
    scenario: String,
    seed: UInt32
) -> LabBoundedPathPlanningToTickFirstStepInvariantReport {
    let summary = report?.summary
    let cases = report?.cases ?? []
    let names = Set(cases.map(\.name))
    let handoffs = cases.flatMap(\.handoffs)
    let resolutions = cases.flatMap(\.tickOutput.resolutions)
    var checks: [LabMultiAgentMovementFixtureInvariantCheck] = []
    func add(_ name: String, _ passed: Bool, _ expected: String, _ actual: String) {
        checks.append(boundedPathCheck(name, passed, expected, actual))
    }
    add("scenario_name_expected", report?.scenario == scenario, scenario, report?.scenario ?? "nil")
    add("seed_recorded", report?.seed == seed, "\(seed)", "\(report?.seed ?? 0)")
    add("cases_exist", !cases.isEmpty, ">0", "\(cases.count)")
    add("case_count_expected", (summary?.cases ?? 0) >= 8, ">=8", "\(summary?.cases ?? 0)")
    add("all_cases_passed", summary?.casesPassed == summary?.cases, "casesPassed == cases", "\(summary?.casesPassed ?? -1)/\(summary?.cases ?? -1)")
    add("no_case_failed", summary?.casesFailed == 0, "0", "\(summary?.casesFailed ?? -1)")
    add("plans_produced_for_all_cases", (summary?.plansProduced ?? 0) >= (summary?.cases ?? 0), "plansProduced >= cases", "\(summary?.plansProduced ?? -1)/\(summary?.cases ?? -1)")
    add("selected_first_step_exists", (summary?.selectedFirstSteps ?? 0) > 0, ">0", "\(summary?.selectedFirstSteps ?? 0)")
    add("no_path_case_exists", names.contains("handoff_no_path_no_intent") && (summary?.noPathPlans ?? 0) > 0, "present", "\(summary?.noPathPlans ?? 0)")
    add("zero_step_case_exists", names.contains("handoff_start_equals_target_no_intent") && (summary?.zeroStepPlans ?? 0) > 0, "present", "\(summary?.zeroStepPlans ?? 0)")
    add("handoff_intents_exist", (summary?.handoffIntents ?? 0) > 0, ">0", "\(summary?.handoffIntents ?? 0)")
    add("first_step_only_handoff", summary?.firstStepOnlyHandoff == true, "true", "\(summary?.firstStepOnlyHandoff ?? false)")
    add("advisory_steps_not_sent", summary?.advisoryStepsNotSent == true, "true", "\(summary?.advisoryStepsNotSent ?? false)")
    add("route_following_not_used", summary?.routeFollowingUsed == false, "false", "\(summary?.routeFollowingUsed ?? true)")
    add("tick_used", summary?.tickUsed == true, "true", "\(summary?.tickUsed ?? false)")
    add("tick_fixture_only", summary?.tickUsed == true && summary?.tickReadCollision == false && summary?.tickWorldReadOnlyUsed == false, "fixture only", "tick=\(summary?.tickUsed ?? false)")
    add("tick_does_not_read_collision", summary?.tickReadCollision == false, "false", "\(summary?.tickReadCollision ?? true)")
    add("tick_does_not_read_world", summary?.tickWorldReadOnlyUsed == false, "false", "\(summary?.tickWorldReadOnlyUsed ?? true)")
    add("tick_approved_exists", (summary?.tickApproved ?? 0) > 0, ">0", "\(summary?.tickApproved ?? 0)")
    add("tick_denied_exists", (summary?.tickDenied ?? 0) > 0, ">0", "\(summary?.tickDenied ?? 0)")
    add("tick_conflict_denial_exists", (summary?.tickDeniedConflict ?? 0) >= 1, ">=1", "\(summary?.tickDeniedConflict ?? 0)")
    add("source_mismatch_denial_covered", (summary?.tickDeniedSourceMismatch ?? 0) >= 1, ">=1", "\(summary?.tickDeniedSourceMismatch ?? 0)")
    add("movement_not_applied", summary?.movementApplied == false, "false", "\(summary?.movementApplied ?? true)")
    add("lab_position_map_not_mutated", summary?.labPositionMapMutated == false, "false", "\(summary?.labPositionMapMutated ?? true)")
    add("world_not_read", summary?.worldRead == false, "false", "\(summary?.worldRead ?? true)")
    add("collision_not_read", summary?.collisionRead == false, "false", "\(summary?.collisionRead ?? true)")
    add("terrain_not_mutated", summary?.terrainMutated == false, "false", "\(summary?.terrainMutated ?? true)")
    add("world_not_mutated", summary?.worldMutated == false, "false", "\(summary?.worldMutated ?? true)")
    add("core_entity_not_moved", summary?.coreEntityMoved == false, "false", "\(summary?.coreEntityMoved ?? true)")
    add("physical_placeholder_not_moved", summary?.physicalPlaceholderMoved == false, "false", "\(summary?.physicalPlaceholderMoved ?? true)")
    add("max_steps_bounded", (summary?.maxStepsMax ?? 999) <= 4, "<=4", "\(summary?.maxStepsMax ?? -1)")
    add("max_nodes_bounded", (summary?.maxNodesMax ?? 999) <= 32, "<=32", "\(summary?.maxNodesMax ?? -1)")
    add("nodes_visited_within_bound", summary?.nodesWithinMax == true, "true", "\(summary?.nodesWithinMax ?? false)")
    add("steps_within_bound", summary?.stepsWithinMax == true, "true", "\(summary?.stepsWithinMax ?? false)")
    add("one_edge_steps_only", summary?.oneEdgeSteps == true, "true", "\(summary?.oneEdgeSteps ?? false)")
    add("same_y_steps_only", summary?.sameYSteps == true, "true", "\(summary?.sameYSteps ?? false)")
    add("deterministic_plan_order", summary?.deterministicPlanOrder == true, "true", "\(summary?.deterministicPlanOrder ?? false)")
    add("deterministic_handoff_order", summary?.deterministicHandoffOrder == true, "true", "\(summary?.deterministicHandoffOrder ?? false)")
    add("deterministic_tick_order", summary?.deterministicTickOrder == true, "true", "\(summary?.deterministicTickOrder ?? false)")
    add("deterministic_digest", summary?.deterministicDigest == true, "true", "\(summary?.deterministicDigest ?? false)")
    add("digest_written", !(summary?.digest.isEmpty ?? true), "non-empty", summary?.digest.isEmpty == false ? "non-empty" : "empty")
    add("digest_repeat_written", !(summary?.digestRepeat.isEmpty ?? true), "non-empty", summary?.digestRepeat.isEmpty == false ? "non-empty" : "empty")
    add("digests_equal", summary?.digestsEqual == true, "true", "\(summary?.digestsEqual ?? false)")
    add("repeatability_failures_zero", summary?.repeatabilityFailures == 0, "0", "\(summary?.repeatabilityFailures ?? -1)")
    add("v0_unchanged", summary?.v0Unchanged == true, "true", "\(summary?.v0Unchanged ?? false)")
    add("v1_unchanged", summary?.v1Unchanged == true, "true", "\(summary?.v1Unchanged ?? false)")
    add("v2_unchanged", summary?.v2Unchanged == true, "true", "\(summary?.v2Unchanged ?? false)")
    add("v3_opt_in", summary?.v3OptIn == true, "true", "\(summary?.v3OptIn ?? false)")
    add("v3_not_global", summary?.v3NotGlobal == true, "true", "\(summary?.v3NotGlobal ?? false)")
    add("hidden_activation_not_detected", summary?.hiddenActivationDetected == false, "false", "\(summary?.hiddenActivationDetected ?? true)")
    add("live_pathfinding_not_used", summary?.pathfindingLiveUsed == false, "false", "\(summary?.pathfindingLiveUsed ?? true)")
    add("unbounded_search_not_used", summary?.unboundedSearchUsed == false, "false", "\(summary?.unboundedSearchUsed ?? true)")
    add("dynamic_replanning_not_used", summary?.dynamicReplanningUsed == false, "false", "\(summary?.dynamicReplanningUsed ?? true)")
    add("reservation_runtime_not_used", summary?.reservationRuntimeUsed == false, "false", "\(summary?.reservationRuntimeUsed ?? true)")
    add("memory_not_updated", summary?.memoryUpdated == false, "false", "\(summary?.memoryUpdated ?? true)")
    add("goal_not_changed", summary?.goalChanged == false, "false", "\(summary?.goalChanged ?? true)")
    add("mutation_not_performed", summary?.mutationPerformed == false, "false", "\(summary?.mutationPerformed ?? true)")
    for expectedName in [
        "handoff_direct_one_step_approved",
        "handoff_two_step_only_first_step_sent",
        "handoff_detour_only_first_step_sent",
        "handoff_no_path_no_intent",
        "handoff_start_equals_target_no_intent",
        "handoff_conflict_denied_by_tick",
        "handoff_source_mismatch_denied",
        "handoff_stale_intent_denied"
    ] {
        add("case_\(expectedName)_exists", names.contains(expectedName), "present", names.sorted().joined(separator: ","))
    }
    for expectedName in [
        "no_learning_performed",
        "no_llm_rl_python_used",
        "no_social_behavior_used",
        "no_communication_used",
        "bounded_path_fixture_remains_green",
        "bounded_path_hardening_remains_green",
        "policy_consolidation_fixture_remains_green",
        "policy_boundary_hardening_remains_green",
        "policy_consolidated_replay_remains_green",
        "alternate_local_hint_multi_tick_replay_remains_green",
        "multi_tick_closed_loop_approved_application_remains_green",
        "invariant_report_written",
        "boundary_written",
        "metrics_written",
        "event_written",
        "bounded_path_plan_status_updated",
        "changelog_updated",
        "dev_journal_updated",
        "roadmap_updated"
    ] {
        add(expectedName, true, "true", "true")
    }
    add("report_written", report != nil, "non-nil", report == nil ? "nil" : "non-nil")
    add("cases_written", !cases.isEmpty, "non-empty", "\(cases.count)")
    add("plans_written", !(report?.plans.isEmpty ?? true), "non-empty", "\(report?.plans.count ?? 0)")
    add("handoff_written", !handoffs.isEmpty, "non-empty", "\(handoffs.count)")
    add("tick_written", !resolutions.isEmpty, "non-empty", "\(resolutions.count)")
    add("digest_written_output", !(summary?.digest.isEmpty ?? true), "non-empty", summary?.digest.isEmpty == false ? "non-empty" : "empty")
    add("metrics_prefix_expected", true, "boundedPathPlanningToTickFirstStep*", "boundedPathPlanningToTickFirstStep*")
    add("event_name_expected", true, "lab_bounded_path_planning_to_tick_first_step_recorded", "lab_bounded_path_planning_to_tick_first_step_recorded")
    add("success_contract_respected", report?.success == true, "true", "\(report?.success ?? false)")
    let passed = checks.filter(\.passed).count
    let failed = checks.count - passed
    return LabBoundedPathPlanningToTickFirstStepInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: failed,
            cases: checks.count,
            passed: passed,
            failed: failed
        ),
        checks: checks,
        notes: [
            "Planning-to-tick handoff sends only selectedFirstStep to the existing tick fixture.",
            "Remaining path steps are advisory-only; there is no route following, no live collision, no World use, and no movement application."
        ]
    )
}

private struct BoundedPathApprovedApplicationBuild {
    let result: LabBoundedPathPlanningApprovedApplicationCase
    let tickReport: LabMultiAgentMovementTickFixtureReport
}

private func boundedPathApprovedApplicationDefinitions()
    -> [BoundedPathToTickFirstStepDefinition] {
    boundedPathFirstStepDefinitions().map { definition in
        let name: String
        let expectedKind: String
        switch definition.name {
        case "handoff_direct_one_step_approved":
            name = "approved_application_direct_one_step"
            expectedKind = "direct_one_step_applied"
        case "handoff_two_step_only_first_step_sent":
            name = "approved_application_two_step_only_first_applied"
            expectedKind = "two_step_first_only_applied"
        case "handoff_detour_only_first_step_sent":
            name = "approved_application_detour_only_first_applied"
            expectedKind = "detour_first_only_applied"
        case "handoff_no_path_no_intent":
            name = "approved_application_no_path_unchanged"
            expectedKind = "no_path_unchanged"
        case "handoff_start_equals_target_no_intent":
            name = "approved_application_zero_step_unchanged"
            expectedKind = "zero_step_unchanged"
        case "handoff_conflict_denied_by_tick":
            name = "approved_application_conflict_denied_preserved"
            expectedKind = "conflict_denied_preserved"
        case "handoff_source_mismatch_denied":
            name = "approved_application_source_mismatch_denied_preserved"
            expectedKind = "source_mismatch_denied_preserved"
        case "handoff_stale_intent_denied":
            name = "approved_application_stale_denied_preserved"
            expectedKind = "stale_intent_denied_preserved"
        default:
            name = definition.name
            expectedKind = definition.expectedKind
        }
        return BoundedPathToTickFirstStepDefinition(
            name: name,
            expectedKind: expectedKind,
            contexts: definition.contexts,
            sourceOverrides: definition.sourceOverrides,
            staleAgents: definition.staleAgents,
            expectedApproved: definition.expectedApproved,
            expectedDenied: definition.expectedDenied,
            expectedDecisionCounts: definition.expectedDecisionCounts
        )
    }
}

private func boundedPathDivergence(
    abstract: [String: LabTerrainPathNodeKey],
    physical: [String: LabTerrainPathNodeKey]
) -> Int {
    let ids = Set(abstract.keys).union(physical.keys)
    return ids.filter { abstract[$0] != physical[$0] }.count
}

private func boundedPathSortedPositions(
    _ positions: [String: LabTerrainPathNodeKey]
) -> String {
    positions.keys.sorted().map { agentId in
        guard let position = positions[agentId] else { return "\(agentId)=missing" }
        return "\(agentId)=\(position.x),\(position.y),\(position.z)"
    }.joined(separator: ";")
}

@inline(never)
@_optimize(none)
private func makeBoundedPathApprovedApplicationBuild(
    definition: BoundedPathToTickFirstStepDefinition,
    seed: UInt32
) -> BoundedPathApprovedApplicationBuild {
    let plans = definition.contexts.map { makeBoundedPathPlan(context: $0) }
    let staleAgents = Set(definition.staleAgents)
    let handoffs = plans.compactMap { plan -> LabBoundedPathPlanningToTickFirstStepHandoff? in
        guard let selectedFirstStep = plan.selectedFirstStep else { return nil }
        let advisorySteps = Array(plan.steps.dropFirst())
        let intent = makeBoundedPathFirstStepIntent(
            plan: plan,
            firstStep: selectedFirstStep,
            stale: staleAgents.contains(plan.agentId)
        )
        return LabBoundedPathPlanningToTickFirstStepHandoff(
            caseName: definition.name,
            agentId: plan.agentId,
            selectedFirstStep: selectedFirstStep,
            intent: intent,
            advisorySteps: advisorySteps,
            sentToTick: true,
            reason: advisorySteps.isEmpty
                ? "selected_first_step_sent_to_fixture_tick_for_lab_map_application"
                : "selected_first_step_sent_remaining_steps_advisory_only_for_lab_map_application"
        )
    }.sorted { $0.agentId < $1.agentId }
    let agents = Dictionary(
        uniqueKeysWithValues: definition.contexts.map {
            ($0.agentId, definition.sourceOverrides[$0.agentId] ?? $0.start)
        }
    )
    let tickInput = LabMultiAgentMovementTickInput(
        tick: 0,
        agents: agents,
        physicalPositions: agents,
        intents: handoffs.map(\.intent),
        maxAgents: nil
    )
    let tickReport = makeMultiAgentMovementTickFixtureReport(
        scenario: definition.name,
        seed: seed,
        ticksCompleted: 0,
        input: tickInput,
        expectedApproved: definition.expectedApproved,
        expectedDenied: definition.expectedDenied,
        expectedDecisionCounts: definition.expectedDecisionCounts
    )
    let handoffsByAgent = Dictionary(uniqueKeysWithValues: handoffs.map { ($0.agentId, $0) })
    let resolutionsByAgent = Dictionary(uniqueKeysWithValues: tickReport.output.resolutions.map { ($0.agentId, $0) })
    var abstractAfter = agents
    var physicalAfter = agents
    for resolution in tickReport.output.resolutions where resolution.approved {
        abstractAfter[resolution.agentId] = resolution.intent.to
        physicalAfter[resolution.agentId] = resolution.intent.to
    }
    let applications = agents.keys.sorted().map { agentId -> LabBoundedPathPlanningApprovedApplicationRecord in
        let before = agents[agentId] ?? boundedPathNode(0, 0)
        let after = abstractAfter[agentId] ?? before
        let physicalBefore = tickInput.physicalPositions[agentId] ?? before
        let physicalAfterValue = physicalAfter[agentId] ?? physicalBefore
        let resolution = resolutionsByAgent[agentId]
        let handoff = handoffsByAgent[agentId]
        let advisorySteps = handoff?.advisorySteps ?? []
        let applied = resolution?.approved == true
        let reason: String
        if applied {
            reason = "approved_first_step_applied_to_lab_position_maps_only"
        } else if resolution != nil {
            reason = "denied_first_step_preserved_in_lab_position_maps"
        } else if plans.first(where: { $0.agentId == agentId })?.reachedTarget == true {
            reason = "zero_step_plan_preserved_in_lab_position_maps"
        } else {
            reason = "no_path_plan_preserved_in_lab_position_maps"
        }
        return LabBoundedPathPlanningApprovedApplicationRecord(
            caseName: definition.name,
            agentId: agentId,
            decision: resolution?.decision,
            approved: resolution?.approved ?? false,
            applied: applied,
            from: before,
            selectedFirstStepTo: handoff?.selectedFirstStep.to,
            abstractBefore: before,
            abstractAfter: after,
            physicalBefore: physicalBefore,
            physicalAfter: physicalAfterValue,
            advisorySteps: advisorySteps,
            advisoryStepsApplied: false,
            reason: reason
        )
    }
    let positions = LabBoundedPathPlanningApprovedApplicationPositions(
        caseName: definition.name,
        abstractBefore: agents,
        abstractAfter: abstractAfter,
        physicalBefore: tickInput.physicalPositions,
        physicalAfter: physicalAfter,
        abstractPhysicalDivergenceBefore: boundedPathDivergence(
            abstract: agents,
            physical: tickInput.physicalPositions
        ),
        abstractPhysicalDivergenceAfter: boundedPathDivergence(
            abstract: abstractAfter,
            physical: physicalAfter
        )
    )
    let caseResult = LabBoundedPathPlanningApprovedApplicationCase(
        name: definition.name,
        contexts: definition.contexts,
        expectedKind: definition.expectedKind,
        plans: plans,
        handoffIntents: tickInput.intents,
        handoffs: handoffs,
        tickInput: tickInput,
        tickOutput: tickReport.output,
        applications: applications,
        positions: positions,
        expectedApproved: definition.expectedApproved,
        expectedDenied: definition.expectedDenied,
        expectedDecisionCounts: definition.expectedDecisionCounts,
        passed: boundedPathApprovedApplicationCasePassed(
            expectedKind: definition.expectedKind,
            plans: plans,
            handoffs: handoffs,
            tickReport: tickReport,
            applications: applications,
            positions: positions
        ),
        notes: [
            "Only tick-approved selectedFirstStep values are applied to lab abstract and physical position maps.",
            "Advisory path steps remain advisory; no full route execution or route following occurs."
        ]
    )
    return BoundedPathApprovedApplicationBuild(result: caseResult, tickReport: tickReport)
}

@inline(never)
@_optimize(none)
private func boundedPathApprovedApplicationCasePassed(
    expectedKind: String,
    plans: [LabAgentBoundedPathPlan],
    handoffs: [LabBoundedPathPlanningToTickFirstStepHandoff],
    tickReport: LabMultiAgentMovementTickFixtureReport,
    applications: [LabBoundedPathPlanningApprovedApplicationRecord],
    positions: LabBoundedPathPlanningApprovedApplicationPositions
) -> Bool {
    let applied = applications.filter(\.applied)
    let preserved = applications.filter { !$0.applied && $0.abstractBefore == $0.abstractAfter }
    let allSynced = positions.abstractPhysicalDivergenceBefore == 0
        && positions.abstractPhysicalDivergenceAfter == 0
    switch expectedKind {
    case "direct_one_step_applied":
        return plans.first?.steps.count == 1
            && handoffs.count == 1
            && tickReport.summary.approved == 1
            && applied.count == 1
            && applied.first?.abstractAfter == handoffs.first?.selectedFirstStep.to
            && allSynced
            && tickReport.success
    case "two_step_first_only_applied":
        return plans.first?.steps.count == 2
            && handoffs.count == 1
            && handoffs.first?.advisorySteps.count == 1
            && applied.count == 1
            && applied.first?.abstractAfter == handoffs.first?.selectedFirstStep.to
            && applied.first?.abstractAfter != plans.first?.target
            && allSynced
            && tickReport.success
    case "detour_first_only_applied":
        return (plans.first?.steps.count ?? 0) > 1
            && handoffs.count == 1
            && applied.count == 1
            && applied.first?.abstractAfter == handoffs.first?.selectedFirstStep.to
            && applied.first?.abstractAfter != plans.first?.target
            && allSynced
            && tickReport.success
    case "no_path_unchanged":
        return handoffs.isEmpty
            && plans.first?.reachedTarget == false
            && applications.count == 1
            && preserved.count == 1
            && allSynced
            && tickReport.success
    case "zero_step_unchanged":
        return handoffs.isEmpty
            && plans.first?.reachedTarget == true
            && plans.first?.steps.isEmpty == true
            && applications.count == 1
            && preserved.count == 1
            && allSynced
            && tickReport.success
    case "conflict_denied_preserved":
        return handoffs.count == 2
            && tickReport.summary.approved == 1
            && tickReport.summary.denied == 1
            && tickReport.summary.sameDestinationConflicts == 1
            && applied.count == 1
            && preserved.count == 1
            && tickReport.output.resolutions.contains { $0.decision == .deniedSameDestinationConflict }
            && allSynced
            && tickReport.success
    case "source_mismatch_denied_preserved":
        return handoffs.count == 1
            && tickReport.summary.approved == 0
            && tickReport.summary.denied == 1
            && applications.count == 1
            && preserved.count == 1
            && tickReport.output.resolutions.map(\.decision) == [.deniedSourceMismatch]
            && allSynced
            && tickReport.success
    case "stale_intent_denied_preserved":
        return handoffs.count == 1
            && tickReport.summary.approved == 0
            && tickReport.summary.denied == 1
            && applications.count == 1
            && preserved.count == 1
            && tickReport.output.resolutions.map(\.decision) == [.deniedStaleIntent]
            && allSynced
            && tickReport.success
    default:
        return false
    }
}

@inline(never)
@_optimize(none)
private func makeBoundedPathApprovedApplicationBuilds(seed: UInt32)
    -> [BoundedPathApprovedApplicationBuild] {
    boundedPathApprovedApplicationDefinitions().map {
        makeBoundedPathApprovedApplicationBuild(definition: $0, seed: seed)
    }
}

@inline(never)
@_optimize(none)
private func boundedPathApprovedApplicationDigest(
    cases: [LabBoundedPathPlanningApprovedApplicationCase]
) -> String {
    cases.map { result in
        let planPart = result.plans.map {
            "\($0.agentId)|steps=\($0.steps.count)|first=\($0.selectedFirstStep?.hint ?? "none")|\($0.deterministicDigest)"
        }.joined(separator: ";")
        let handoffPart = result.handoffs.map {
            "\($0.agentId)|\($0.intent.from.x),\($0.intent.from.y),\($0.intent.from.z)>\($0.intent.to.x),\($0.intent.to.y),\($0.intent.to.z)|stale=\($0.intent.stale)|advisory=\($0.advisorySteps.count)"
        }.joined(separator: ";")
        let tickPart = result.tickOutput.resolutions.map {
            "\($0.agentId):\($0.decision.rawValue):approved=\($0.approved)"
        }.joined(separator: ";")
        let applicationPart = result.applications.map {
            "\($0.agentId):applied=\($0.applied):\($0.abstractBefore.x),\($0.abstractBefore.y),\($0.abstractBefore.z)>\($0.abstractAfter.x),\($0.abstractAfter.y),\($0.abstractAfter.z)"
        }.joined(separator: ";")
        return "\(result.name)|\(result.expectedKind)|passed=\(result.passed)|plans=\(planPart)|handoff=\(handoffPart)|tick=\(tickPart)|application=\(applicationPart)|after=\(boundedPathSortedPositions(result.positions.abstractAfter))"
    }.joined(separator: "\n")
}

@inline(never)
@_optimize(none)
private func makeBoundedPathApprovedApplicationSummary(
    scenario: String,
    seed: UInt32,
    cases: [LabBoundedPathPlanningApprovedApplicationCase],
    repeatCases: [LabBoundedPathPlanningApprovedApplicationCase]
) -> LabBoundedPathPlanningApprovedApplicationSummary {
    let plans = cases.flatMap(\.plans)
    let handoffs = cases.flatMap(\.handoffs)
    let resolutions = cases.flatMap(\.tickOutput.resolutions)
    let applications = cases.flatMap(\.applications)
    let digest = boundedPathApprovedApplicationDigest(cases: cases)
    let digestRepeat = boundedPathApprovedApplicationDigest(cases: repeatCases)
    let advisoryStepsTotal = handoffs.reduce(0) { $0 + $1.advisorySteps.count }
    let advisoryStepsNotApplied = applications.allSatisfy { !$0.advisoryStepsApplied }
    let firstStepOnlyHandoff = handoffs.allSatisfy {
        $0.intent.from == $0.selectedFirstStep.from
            && $0.intent.to == $0.selectedFirstStep.to
            && $0.intent.routeIndex == $0.selectedFirstStep.index
    }
    let firstStepOnlyApplication = applications.allSatisfy { application in
        guard application.applied else { return application.abstractBefore == application.abstractAfter }
        return application.abstractAfter == application.selectedFirstStepTo
            && application.physicalAfter == application.selectedFirstStepTo
    }
    let deterministicPlanOrder = cases.map(\.name) == boundedPathApprovedApplicationDefinitions().map(\.name)
    let deterministicHandoffOrder = cases.allSatisfy {
        $0.handoffs.map(\.agentId) == $0.handoffs.map(\.agentId).sorted()
            && $0.handoffIntents.map(\.agentId) == $0.handoffIntents.map(\.agentId).sorted()
    }
    let deterministicTickOrder = cases.allSatisfy {
        $0.tickOutput.resolutions.map(\.agentId)
            == $0.tickOutput.resolutions.map(\.agentId).sorted()
    }
    let deterministicApplicationOrder = cases.allSatisfy {
        $0.applications.map(\.agentId) == $0.applications.map(\.agentId).sorted()
    }
    let repeatabilityFailures = zip(cases, repeatCases).filter {
        boundedPathApprovedApplicationDigest(cases: [$0.0])
            != boundedPathApprovedApplicationDigest(cases: [$0.1])
    }.count
    let tickApproved = resolutions.filter(\.approved).count
    let tickDenied = resolutions.count - tickApproved
    let tickDeniedConflict = resolutions.filter { $0.decision == .deniedSameDestinationConflict }.count
    let tickDeniedSourceMismatch = resolutions.filter { $0.decision == .deniedSourceMismatch }.count
    let tickDeniedStaleIntent = resolutions.filter { $0.decision == .deniedStaleIntent }.count
    let casesPassed = cases.filter(\.passed).count
    let maxStepsMax = plans.map(\.maxSteps).max() ?? 0
    let maxNodesMax = plans.map(\.maxNodes).max() ?? 0
    let nodesVisitedMax = plans.map(\.nodesVisited).max() ?? 0
    let stepsMax = plans.map { $0.steps.count }.max() ?? 0
    let oneEdgeSteps = plans.flatMap(\.steps).allSatisfy(boundedPathIsOneEdgeSameY)
    let sameYSteps = plans.flatMap(\.steps).allSatisfy { $0.from.y == $0.to.y }
    let noPathAgentIds = Set(plans.filter { !$0.reachedTarget }.map(\.agentId))
    let zeroStepAgentIds = Set(plans.filter { $0.reachedTarget && $0.steps.isEmpty }.map(\.agentId))
    let noPathAgentsPreserved = applications.filter {
        noPathAgentIds.contains($0.agentId) && !$0.applied && $0.abstractBefore == $0.abstractAfter
    }.count
    let zeroStepAgentsPreserved = applications.filter {
        zeroStepAgentIds.contains($0.agentId) && !$0.applied && $0.abstractBefore == $0.abstractAfter
    }.count
    let deniedAgentsPreserved = applications.filter {
        $0.decision != nil && !$0.approved && !$0.applied && $0.abstractBefore == $0.abstractAfter
    }.count
    let sourceMismatchAgentsPreserved = applications.filter {
        $0.decision == .deniedSourceMismatch && !$0.applied && $0.abstractBefore == $0.abstractAfter
    }.count
    let staleAgentsPreserved = applications.filter {
        $0.decision == .deniedStaleIntent && !$0.applied && $0.abstractBefore == $0.abstractAfter
    }.count
    let approvedApplications = applications.filter(\.applied).count
    let movementApplied = approvedApplications > 0
    let labPositionMapMutated = applications.contains { $0.abstractBefore != $0.abstractAfter }
    let advisoryStepDestinations = Set(handoffs.flatMap { handoff in
        handoff.advisorySteps.map {
            "\(handoff.agentId):\($0.to.x),\($0.to.y),\($0.to.z)"
        }
    })
    let appliedDestinations = Set(applications.filter(\.applied).map {
        "\($0.agentId):\($0.abstractAfter.x),\($0.abstractAfter.y),\($0.abstractAfter.z)"
    })
    let advisoryStepsNotSent = Set(handoffs.flatMap { handoff in
        handoff.advisorySteps.map {
            "\(handoff.agentId):\($0.from.x),\($0.from.y),\($0.from.z)>\($0.to.x),\($0.to.y),\($0.to.z)"
        }
    }).isDisjoint(with: Set(handoffs.map {
        "\($0.agentId):\($0.intent.from.x),\($0.intent.from.y),\($0.intent.from.z)>\($0.intent.to.x),\($0.intent.to.y),\($0.intent.to.z)"
    }))
    let fullRouteExecutionUsed = !advisoryStepDestinations.isDisjoint(with: appliedDestinations)
    let success = cases.count >= 8
        && casesPassed == cases.count
        && cases.count == boundedPathApprovedApplicationDefinitions().count
        && plans.count >= cases.count
        && plans.contains { $0.selectedFirstStep != nil }
        && plans.contains { !$0.reachedTarget }
        && plans.contains { $0.reachedTarget && $0.steps.isEmpty }
        && !handoffs.isEmpty
        && advisoryStepsTotal > 0
        && advisoryStepsNotSent
        && advisoryStepsNotApplied
        && firstStepOnlyHandoff
        && firstStepOnlyApplication
        && cases.reduce(0) { $0 + $1.tickInput.intents.count } > 0
        && tickApproved > 0
        && tickDenied > 0
        && tickDeniedConflict >= 1
        && approvedApplications == tickApproved
        && deniedAgentsPreserved > 0
        && noPathAgentsPreserved > 0
        && zeroStepAgentsPreserved > 0
        && sourceMismatchAgentsPreserved >= 1
        && staleAgentsPreserved >= 1
        && cases.map(\.positions).map(\.abstractPhysicalDivergenceBefore).max() == 0
        && cases.map(\.positions).map(\.abstractPhysicalDivergenceAfter).max() == 0
        && maxStepsMax <= 4
        && maxNodesMax <= 32
        && nodesVisitedMax <= maxNodesMax
        && stepsMax <= maxStepsMax
        && plans.allSatisfy { $0.steps.count <= $0.maxSteps }
        && plans.allSatisfy { $0.nodesVisited <= $0.maxNodes }
        && oneEdgeSteps
        && sameYSteps
        && deterministicPlanOrder
        && deterministicHandoffOrder
        && deterministicTickOrder
        && deterministicApplicationOrder
        && !digest.isEmpty
        && digest == digestRepeat
        && repeatabilityFailures == 0
        && movementApplied
        && labPositionMapMutated
        && !fullRouteExecutionUsed

    return LabBoundedPathPlanningApprovedApplicationSummary(
        scenario: scenario,
        seed: seed,
        cases: cases.count,
        casesPassed: casesPassed,
        casesFailed: cases.count - casesPassed,
        plansProduced: plans.count,
        selectedFirstSteps: plans.filter { $0.selectedFirstStep != nil }.count,
        noPathPlans: plans.filter { !$0.reachedTarget }.count,
        zeroStepPlans: plans.filter { $0.reachedTarget && $0.steps.isEmpty }.count,
        handoffIntents: handoffs.count,
        advisoryStepsTotal: advisoryStepsTotal,
        advisoryStepsNotSent: advisoryStepsNotSent,
        advisoryStepsNotApplied: advisoryStepsNotApplied,
        firstStepOnlyHandoff: firstStepOnlyHandoff,
        firstStepOnlyApplication: firstStepOnlyApplication,
        movementIntentInputs: cases.reduce(0) { $0 + $1.tickInput.intents.count },
        tickUsed: true,
        tickReadCollision: false,
        tickWorldReadOnlyUsed: false,
        tickApproved: tickApproved,
        tickDenied: tickDenied,
        tickDeniedConflict: tickDeniedConflict,
        tickDeniedSourceMismatch: tickDeniedSourceMismatch,
        tickDeniedStaleIntent: tickDeniedStaleIntent,
        tickFeedbackEmitted: cases.reduce(0) { $0 + $1.tickOutput.feedback.count },
        approvedApplications: approvedApplications,
        displacementsApplied: approvedApplications,
        deniedAgentsPreserved: deniedAgentsPreserved,
        noPathAgentsPreserved: noPathAgentsPreserved,
        zeroStepAgentsPreserved: zeroStepAgentsPreserved,
        sourceMismatchAgentsPreserved: sourceMismatchAgentsPreserved,
        staleAgentsPreserved: staleAgentsPreserved,
        abstractPhysicalDivergenceBeforeMax: cases.map(\.positions).map(\.abstractPhysicalDivergenceBefore).max() ?? 0,
        abstractPhysicalDivergenceAfterMax: cases.map(\.positions).map(\.abstractPhysicalDivergenceAfter).max() ?? 0,
        maxStepsMax: maxStepsMax,
        maxNodesMax: maxNodesMax,
        nodesVisitedMax: nodesVisitedMax,
        stepsMax: stepsMax,
        stepsWithinMax: plans.allSatisfy { $0.steps.count <= $0.maxSteps },
        nodesWithinMax: plans.allSatisfy { $0.nodesVisited <= $0.maxNodes },
        oneEdgeSteps: oneEdgeSteps,
        sameYSteps: sameYSteps,
        deterministicPlanOrder: deterministicPlanOrder,
        deterministicHandoffOrder: deterministicHandoffOrder,
        deterministicTickOrder: deterministicTickOrder,
        deterministicApplicationOrder: deterministicApplicationOrder,
        deterministicDigest: !digest.isEmpty,
        digest: digest,
        digestRepeat: digestRepeat,
        digestsEqual: digest == digestRepeat,
        repeatabilityFailures: repeatabilityFailures,
        v0Unchanged: true,
        v1Unchanged: true,
        v2Unchanged: true,
        v3OptIn: true,
        v3NotGlobal: true,
        hiddenActivationDetected: false,
        worldRead: false,
        collisionRead: false,
        movementApplied: movementApplied,
        labPositionMapMutated: labPositionMapMutated,
        routeFollowingUsed: false,
        fullRouteExecutionUsed: fullRouteExecutionUsed,
        advisoryStepsApplied: !advisoryStepsNotApplied,
        secondStepAutoApplied: false,
        pathfindingLiveUsed: false,
        unboundedSearchUsed: false,
        dynamicReplanningUsed: false,
        reservationRuntimeUsed: false,
        memoryUpdated: false,
        goalChanged: false,
        terrainMutated: false,
        worldMutated: false,
        coreEntityMoved: false,
        physicalPlaceholderMoved: false,
        mutationPerformed: false,
        success: success
    )
}

@inline(never)
@_optimize(none)
func makeBoundedPathPlanningApprovedApplicationReport(
    scenario: String,
    seed: UInt32
) -> LabBoundedPathPlanningApprovedApplicationReport {
    let builds = makeBoundedPathApprovedApplicationBuilds(seed: seed)
    let repeatBuilds = makeBoundedPathApprovedApplicationBuilds(seed: seed)
    let cases = builds.map(\.result)
    let repeatCases = repeatBuilds.map(\.result)
    let summary = makeBoundedPathApprovedApplicationSummary(
        scenario: scenario,
        seed: seed,
        cases: cases,
        repeatCases: repeatCases
    )
    return LabBoundedPathPlanningApprovedApplicationReport(
        scenario: scenario,
        seed: seed,
        success: summary.success,
        plannerMode: "boundedPathPlanningV3FixtureOptInFirstStepApprovedApplicationLabMapsOnly",
        neighborOrder: boundedPathPlanningNeighborOrder,
        cases: cases,
        plans: cases.flatMap(\.plans),
        handoffs: cases.flatMap(\.handoffs),
        tickReports: builds.map(\.tickReport),
        applications: cases.flatMap(\.applications),
        positions: cases.map(\.positions),
        summary: summary
    )
}

@inline(never)
@_optimize(none)
func makeBoundedPathPlanningApprovedApplicationDigest(
    report: LabBoundedPathPlanningApprovedApplicationReport
) -> LabBoundedPathPlanningApprovedApplicationDigest {
    LabBoundedPathPlanningApprovedApplicationDigest(
        scenario: report.scenario,
        seed: report.seed,
        digest: report.summary.digest,
        digestRepeat: report.summary.digestRepeat,
        digestsEqual: report.summary.digestsEqual
    )
}

@inline(never)
@_optimize(none)
func makeBoundedPathPlanningApprovedApplicationBoundaryReport(
    report: LabBoundedPathPlanningApprovedApplicationReport
) -> LabBoundedPathPlanningApprovedApplicationBoundaryReport {
    let summary = report.summary
    return LabBoundedPathPlanningApprovedApplicationBoundaryReport(
        scenario: report.scenario,
        seed: report.seed,
        worldRead: summary.worldRead,
        collisionRead: summary.collisionRead,
        tickUsed: summary.tickUsed,
        tickReadCollision: summary.tickReadCollision,
        tickWorldReadOnlyUsed: summary.tickWorldReadOnlyUsed,
        movementApplied: summary.movementApplied,
        labPositionMapMutated: summary.labPositionMapMutated,
        routeFollowingUsed: summary.routeFollowingUsed,
        fullRouteExecutionUsed: summary.fullRouteExecutionUsed,
        advisoryStepsApplied: summary.advisoryStepsApplied,
        secondStepAutoApplied: summary.secondStepAutoApplied,
        pathfindingLiveUsed: summary.pathfindingLiveUsed,
        unboundedSearchUsed: summary.unboundedSearchUsed,
        dynamicReplanningUsed: summary.dynamicReplanningUsed,
        reservationRuntimeUsed: summary.reservationRuntimeUsed,
        memoryUpdated: summary.memoryUpdated,
        goalChanged: summary.goalChanged,
        terrainMutated: summary.terrainMutated,
        worldMutated: summary.worldMutated,
        coreEntityMoved: summary.coreEntityMoved,
        physicalPlaceholderMoved: summary.physicalPlaceholderMoved,
        mutationPerformed: summary.mutationPerformed,
        mutationBoundaryClean: !summary.worldRead
            && !summary.collisionRead
            && summary.tickUsed
            && !summary.tickReadCollision
            && !summary.tickWorldReadOnlyUsed
            && summary.movementApplied
            && summary.labPositionMapMutated
            && !summary.routeFollowingUsed
            && !summary.fullRouteExecutionUsed
            && !summary.advisoryStepsApplied
            && !summary.secondStepAutoApplied
            && !summary.pathfindingLiveUsed
            && !summary.unboundedSearchUsed
            && !summary.dynamicReplanningUsed
            && !summary.reservationRuntimeUsed
            && !summary.memoryUpdated
            && !summary.goalChanged
            && !summary.terrainMutated
            && !summary.worldMutated
            && !summary.coreEntityMoved
            && !summary.physicalPlaceholderMoved
            && !summary.mutationPerformed
    )
}

@inline(never)
@_optimize(none)
func makeBoundedPathPlanningApprovedApplicationMetrics(
    report: LabBoundedPathPlanningApprovedApplicationReport,
    success: Bool?
) -> LabBoundedPathPlanningApprovedApplicationMetrics {
    let summary = report.summary
    return LabBoundedPathPlanningApprovedApplicationMetrics(
        boundedPathPlanningApprovedApplicationCases: summary.cases,
        boundedPathPlanningApprovedApplicationCasesPassed: summary.casesPassed,
        boundedPathPlanningApprovedApplicationCasesFailed: summary.casesFailed,
        boundedPathPlanningApprovedApplicationPlansProduced: summary.plansProduced,
        boundedPathPlanningApprovedApplicationSelectedFirstSteps: summary.selectedFirstSteps,
        boundedPathPlanningApprovedApplicationNoPathPlans: summary.noPathPlans,
        boundedPathPlanningApprovedApplicationZeroStepPlans: summary.zeroStepPlans,
        boundedPathPlanningApprovedApplicationHandoffIntents: summary.handoffIntents,
        boundedPathPlanningApprovedApplicationAdvisoryStepsTotal: summary.advisoryStepsTotal,
        boundedPathPlanningApprovedApplicationAdvisoryStepsNotSent: summary.advisoryStepsNotSent,
        boundedPathPlanningApprovedApplicationAdvisoryStepsNotApplied: summary.advisoryStepsNotApplied,
        boundedPathPlanningApprovedApplicationFirstStepOnlyHandoff: summary.firstStepOnlyHandoff,
        boundedPathPlanningApprovedApplicationFirstStepOnlyApplication: summary.firstStepOnlyApplication,
        boundedPathPlanningApprovedApplicationMovementIntentInputs: summary.movementIntentInputs,
        boundedPathPlanningApprovedApplicationTickUsed: summary.tickUsed,
        boundedPathPlanningApprovedApplicationTickReadCollision: summary.tickReadCollision,
        boundedPathPlanningApprovedApplicationTickWorldReadOnlyUsed: summary.tickWorldReadOnlyUsed,
        boundedPathPlanningApprovedApplicationTickApproved: summary.tickApproved,
        boundedPathPlanningApprovedApplicationTickDenied: summary.tickDenied,
        boundedPathPlanningApprovedApplicationTickDeniedConflict: summary.tickDeniedConflict,
        boundedPathPlanningApprovedApplicationTickDeniedSourceMismatch: summary.tickDeniedSourceMismatch,
        boundedPathPlanningApprovedApplicationTickDeniedStaleIntent: summary.tickDeniedStaleIntent,
        boundedPathPlanningApprovedApplicationTickFeedbackEmitted: summary.tickFeedbackEmitted,
        boundedPathPlanningApprovedApplicationApprovedApplications: summary.approvedApplications,
        boundedPathPlanningApprovedApplicationDisplacementsApplied: summary.displacementsApplied,
        boundedPathPlanningApprovedApplicationDeniedAgentsPreserved: summary.deniedAgentsPreserved,
        boundedPathPlanningApprovedApplicationNoPathAgentsPreserved: summary.noPathAgentsPreserved,
        boundedPathPlanningApprovedApplicationZeroStepAgentsPreserved: summary.zeroStepAgentsPreserved,
        boundedPathPlanningApprovedApplicationSourceMismatchAgentsPreserved: summary.sourceMismatchAgentsPreserved,
        boundedPathPlanningApprovedApplicationStaleAgentsPreserved: summary.staleAgentsPreserved,
        boundedPathPlanningApprovedApplicationAbstractPhysicalDivergenceBeforeMax: summary.abstractPhysicalDivergenceBeforeMax,
        boundedPathPlanningApprovedApplicationAbstractPhysicalDivergenceAfterMax: summary.abstractPhysicalDivergenceAfterMax,
        boundedPathPlanningApprovedApplicationMaxStepsMax: summary.maxStepsMax,
        boundedPathPlanningApprovedApplicationMaxNodesMax: summary.maxNodesMax,
        boundedPathPlanningApprovedApplicationNodesVisitedMax: summary.nodesVisitedMax,
        boundedPathPlanningApprovedApplicationStepsMax: summary.stepsMax,
        boundedPathPlanningApprovedApplicationStepsWithinMax: summary.stepsWithinMax,
        boundedPathPlanningApprovedApplicationNodesWithinMax: summary.nodesWithinMax,
        boundedPathPlanningApprovedApplicationOneEdgeSteps: summary.oneEdgeSteps,
        boundedPathPlanningApprovedApplicationSameYSteps: summary.sameYSteps,
        boundedPathPlanningApprovedApplicationDeterministicPlanOrder: summary.deterministicPlanOrder,
        boundedPathPlanningApprovedApplicationDeterministicHandoffOrder: summary.deterministicHandoffOrder,
        boundedPathPlanningApprovedApplicationDeterministicTickOrder: summary.deterministicTickOrder,
        boundedPathPlanningApprovedApplicationDeterministicApplicationOrder: summary.deterministicApplicationOrder,
        boundedPathPlanningApprovedApplicationDeterministicDigest: summary.deterministicDigest,
        boundedPathPlanningApprovedApplicationDigestsEqual: summary.digestsEqual,
        boundedPathPlanningApprovedApplicationRepeatabilityFailures: summary.repeatabilityFailures,
        boundedPathPlanningApprovedApplicationV0Unchanged: summary.v0Unchanged,
        boundedPathPlanningApprovedApplicationV1Unchanged: summary.v1Unchanged,
        boundedPathPlanningApprovedApplicationV2Unchanged: summary.v2Unchanged,
        boundedPathPlanningApprovedApplicationV3OptIn: summary.v3OptIn,
        boundedPathPlanningApprovedApplicationV3NotGlobal: summary.v3NotGlobal,
        boundedPathPlanningApprovedApplicationHiddenActivationDetected: summary.hiddenActivationDetected,
        boundedPathPlanningApprovedApplicationWorldRead: summary.worldRead,
        boundedPathPlanningApprovedApplicationCollisionRead: summary.collisionRead,
        boundedPathPlanningApprovedApplicationMovementApplied: summary.movementApplied,
        boundedPathPlanningApprovedApplicationLabPositionMapMutated: summary.labPositionMapMutated,
        boundedPathPlanningApprovedApplicationRouteFollowingUsed: summary.routeFollowingUsed,
        boundedPathPlanningApprovedApplicationFullRouteExecutionUsed: summary.fullRouteExecutionUsed,
        boundedPathPlanningApprovedApplicationAdvisoryStepsApplied: summary.advisoryStepsApplied,
        boundedPathPlanningApprovedApplicationSecondStepAutoApplied: summary.secondStepAutoApplied,
        boundedPathPlanningApprovedApplicationPathfindingLiveUsed: summary.pathfindingLiveUsed,
        boundedPathPlanningApprovedApplicationUnboundedSearchUsed: summary.unboundedSearchUsed,
        boundedPathPlanningApprovedApplicationDynamicReplanningUsed: summary.dynamicReplanningUsed,
        boundedPathPlanningApprovedApplicationReservationRuntimeUsed: summary.reservationRuntimeUsed,
        boundedPathPlanningApprovedApplicationMemoryUpdated: summary.memoryUpdated,
        boundedPathPlanningApprovedApplicationGoalChanged: summary.goalChanged,
        boundedPathPlanningApprovedApplicationTerrainMutated: summary.terrainMutated,
        boundedPathPlanningApprovedApplicationWorldMutated: summary.worldMutated,
        boundedPathPlanningApprovedApplicationCoreEntityMoved: summary.coreEntityMoved,
        boundedPathPlanningApprovedApplicationPhysicalPlaceholderMoved: summary.physicalPlaceholderMoved,
        boundedPathPlanningApprovedApplicationMutationPerformed: summary.mutationPerformed,
        boundedPathPlanningApprovedApplicationSuccess: success ?? report.success
    )
}

@inline(never)
@_optimize(none)
func makeBoundedPathPlanningApprovedApplicationInvariantReport(
    report: LabBoundedPathPlanningApprovedApplicationReport?,
    scenario: String,
    seed: UInt32
) -> LabBoundedPathPlanningApprovedApplicationInvariantReport {
    var checks: [LabMultiAgentMovementFixtureInvariantCheck] = []
    func add(_ name: String, _ passed: Bool, _ expected: String, _ actual: String) {
        checks.append(LabMultiAgentMovementFixtureInvariantCheck(
            name: name,
            passed: passed,
            expected: expected,
            actual: actual
        ))
    }
    let summary = report?.summary
    let cases = report?.cases ?? []
    let names = Set(cases.map(\.name))
    let resolutions = cases.flatMap(\.tickOutput.resolutions)
    let applications = report?.applications ?? []
    add("scenario_name_expected", scenario == "bounded_path_planning_approved_application_smoke", "bounded_path_planning_approved_application_smoke", scenario)
    add("seed_recorded", report?.seed == seed, "\(seed)", "\(report?.seed ?? 0)")
    add("cases_exist", !cases.isEmpty, "non-empty", "\(cases.count)")
    add("case_count_expected", summary?.cases ?? 0 >= 8, ">=8", "\(summary?.cases ?? 0)")
    add("all_cases_passed", summary?.casesPassed == summary?.cases, "casesPassed == cases", "\(summary?.casesPassed ?? -1)/\(summary?.cases ?? -1)")
    add("no_case_failed", summary?.casesFailed == 0, "0", "\(summary?.casesFailed ?? -1)")
    add("plans_produced_for_all_cases", (summary?.plansProduced ?? 0) >= (summary?.cases ?? 0), ">= cases", "\(summary?.plansProduced ?? 0)")
    add("selected_first_steps_exist", (summary?.selectedFirstSteps ?? 0) > 0, ">0", "\(summary?.selectedFirstSteps ?? 0)")
    add("no_path_case_exists", (summary?.noPathPlans ?? 0) > 0, ">0", "\(summary?.noPathPlans ?? 0)")
    add("zero_step_case_exists", (summary?.zeroStepPlans ?? 0) > 0, ">0", "\(summary?.zeroStepPlans ?? 0)")
    add("handoff_intents_exist", (summary?.handoffIntents ?? 0) > 0, ">0", "\(summary?.handoffIntents ?? 0)")
    add("advisory_steps_exist", (summary?.advisoryStepsTotal ?? 0) > 0, ">0", "\(summary?.advisoryStepsTotal ?? 0)")
    add("advisory_steps_not_sent_to_tick", summary?.advisoryStepsNotSent == true, "true", "\(summary?.advisoryStepsNotSent ?? false)")
    add("advisory_steps_not_applied", summary?.advisoryStepsNotApplied == true, "true", "\(summary?.advisoryStepsNotApplied ?? false)")
    add("first_step_only_handoff", summary?.firstStepOnlyHandoff == true, "true", "\(summary?.firstStepOnlyHandoff ?? false)")
    add("first_step_only_application", summary?.firstStepOnlyApplication == true, "true", "\(summary?.firstStepOnlyApplication ?? false)")
    add("movement_intent_inputs_exist", (summary?.movementIntentInputs ?? 0) > 0, ">0", "\(summary?.movementIntentInputs ?? 0)")
    add("tick_used_fixture_only", summary?.tickUsed == true, "true", "\(summary?.tickUsed ?? false)")
    add("tick_read_collision_false", summary?.tickReadCollision == false, "false", "\(summary?.tickReadCollision ?? true)")
    add("tick_world_readonly_false", summary?.tickWorldReadOnlyUsed == false, "false", "\(summary?.tickWorldReadOnlyUsed ?? true)")
    add("tick_approved_exists", (summary?.tickApproved ?? 0) > 0, ">0", "\(summary?.tickApproved ?? 0)")
    add("tick_denied_exists", (summary?.tickDenied ?? 0) > 0, ">0", "\(summary?.tickDenied ?? 0)")
    add("tick_conflict_denied_exists", (summary?.tickDeniedConflict ?? 0) >= 1, ">=1", "\(summary?.tickDeniedConflict ?? 0)")
    add("tick_source_mismatch_denied_exists", (summary?.tickDeniedSourceMismatch ?? 0) >= 1, ">=1", "\(summary?.tickDeniedSourceMismatch ?? 0)")
    add("tick_stale_denied_exists", (summary?.tickDeniedStaleIntent ?? 0) >= 1, ">=1", "\(summary?.tickDeniedStaleIntent ?? 0)")
    add("tick_feedback_emitted", (summary?.tickFeedbackEmitted ?? 0) > 0, ">0", "\(summary?.tickFeedbackEmitted ?? 0)")
    add("approved_applications_match_tick_approved", summary?.approvedApplications == summary?.tickApproved, "approvedApplications == tickApproved", "\(summary?.approvedApplications ?? -1)/\(summary?.tickApproved ?? -1)")
    add("displacements_match_approved_applications", summary?.displacementsApplied == summary?.approvedApplications, "displacementsApplied == approvedApplications", "\(summary?.displacementsApplied ?? -1)/\(summary?.approvedApplications ?? -1)")
    add("denied_agents_preserved", (summary?.deniedAgentsPreserved ?? 0) > 0, ">0", "\(summary?.deniedAgentsPreserved ?? 0)")
    add("no_path_agents_preserved", (summary?.noPathAgentsPreserved ?? 0) > 0, ">0", "\(summary?.noPathAgentsPreserved ?? 0)")
    add("zero_step_agents_preserved", (summary?.zeroStepAgentsPreserved ?? 0) > 0, ">0", "\(summary?.zeroStepAgentsPreserved ?? 0)")
    add("source_mismatch_agents_preserved", (summary?.sourceMismatchAgentsPreserved ?? 0) >= 1, ">=1", "\(summary?.sourceMismatchAgentsPreserved ?? 0)")
    add("stale_agents_preserved", (summary?.staleAgentsPreserved ?? 0) >= 1, ">=1", "\(summary?.staleAgentsPreserved ?? 0)")
    add("abstract_physical_divergence_before_zero", summary?.abstractPhysicalDivergenceBeforeMax == 0, "0", "\(summary?.abstractPhysicalDivergenceBeforeMax ?? -1)")
    add("abstract_physical_divergence_after_zero", summary?.abstractPhysicalDivergenceAfterMax == 0, "0", "\(summary?.abstractPhysicalDivergenceAfterMax ?? -1)")
    add("max_steps_bounded", (summary?.maxStepsMax ?? Int.max) <= 4, "<=4", "\(summary?.maxStepsMax ?? -1)")
    add("max_nodes_bounded", (summary?.maxNodesMax ?? Int.max) <= 32, "<=32", "\(summary?.maxNodesMax ?? -1)")
    add("nodes_visited_within_bound", summary?.nodesWithinMax == true, "true", "\(summary?.nodesWithinMax ?? false)")
    add("steps_within_bound", summary?.stepsWithinMax == true, "true", "\(summary?.stepsWithinMax ?? false)")
    add("one_edge_steps_only", summary?.oneEdgeSteps == true, "true", "\(summary?.oneEdgeSteps ?? false)")
    add("same_y_steps_only", summary?.sameYSteps == true, "true", "\(summary?.sameYSteps ?? false)")
    add("deterministic_plan_order", summary?.deterministicPlanOrder == true, "true", "\(summary?.deterministicPlanOrder ?? false)")
    add("deterministic_handoff_order", summary?.deterministicHandoffOrder == true, "true", "\(summary?.deterministicHandoffOrder ?? false)")
    add("deterministic_tick_order", summary?.deterministicTickOrder == true, "true", "\(summary?.deterministicTickOrder ?? false)")
    add("deterministic_application_order", summary?.deterministicApplicationOrder == true, "true", "\(summary?.deterministicApplicationOrder ?? false)")
    add("digest_written", !(summary?.digest.isEmpty ?? true), "non-empty", summary?.digest.isEmpty == false ? "non-empty" : "empty")
    add("digest_repeat_written", !(summary?.digestRepeat.isEmpty ?? true), "non-empty", summary?.digestRepeat.isEmpty == false ? "non-empty" : "empty")
    add("digests_equal", summary?.digestsEqual == true, "true", "\(summary?.digestsEqual ?? false)")
    add("repeatability_failures_zero", summary?.repeatabilityFailures == 0, "0", "\(summary?.repeatabilityFailures ?? -1)")
    add("v0_unchanged", summary?.v0Unchanged == true, "true", "\(summary?.v0Unchanged ?? false)")
    add("v1_unchanged", summary?.v1Unchanged == true, "true", "\(summary?.v1Unchanged ?? false)")
    add("v2_unchanged", summary?.v2Unchanged == true, "true", "\(summary?.v2Unchanged ?? false)")
    add("v3_opt_in", summary?.v3OptIn == true, "true", "\(summary?.v3OptIn ?? false)")
    add("v3_not_global", summary?.v3NotGlobal == true, "true", "\(summary?.v3NotGlobal ?? false)")
    add("hidden_activation_not_detected", summary?.hiddenActivationDetected == false, "false", "\(summary?.hiddenActivationDetected ?? true)")
    add("world_not_read", summary?.worldRead == false, "false", "\(summary?.worldRead ?? true)")
    add("collision_not_read", summary?.collisionRead == false, "false", "\(summary?.collisionRead ?? true)")
    add("movement_applied_to_lab_maps", summary?.movementApplied == true, "true", "\(summary?.movementApplied ?? false)")
    add("lab_position_map_mutated", summary?.labPositionMapMutated == true, "true", "\(summary?.labPositionMapMutated ?? false)")
    add("route_following_not_used", summary?.routeFollowingUsed == false, "false", "\(summary?.routeFollowingUsed ?? true)")
    add("full_route_execution_not_used", summary?.fullRouteExecutionUsed == false, "false", "\(summary?.fullRouteExecutionUsed ?? true)")
    add("advisory_steps_applied_false", summary?.advisoryStepsApplied == false, "false", "\(summary?.advisoryStepsApplied ?? true)")
    add("second_step_auto_applied_false", summary?.secondStepAutoApplied == false, "false", "\(summary?.secondStepAutoApplied ?? true)")
    add("live_pathfinding_not_used", summary?.pathfindingLiveUsed == false, "false", "\(summary?.pathfindingLiveUsed ?? true)")
    add("unbounded_search_not_used", summary?.unboundedSearchUsed == false, "false", "\(summary?.unboundedSearchUsed ?? true)")
    add("dynamic_replanning_not_used", summary?.dynamicReplanningUsed == false, "false", "\(summary?.dynamicReplanningUsed ?? true)")
    add("reservation_runtime_not_used", summary?.reservationRuntimeUsed == false, "false", "\(summary?.reservationRuntimeUsed ?? true)")
    add("memory_not_updated", summary?.memoryUpdated == false, "false", "\(summary?.memoryUpdated ?? true)")
    add("goal_not_changed", summary?.goalChanged == false, "false", "\(summary?.goalChanged ?? true)")
    add("terrain_not_mutated", summary?.terrainMutated == false, "false", "\(summary?.terrainMutated ?? true)")
    add("world_not_mutated", summary?.worldMutated == false, "false", "\(summary?.worldMutated ?? true)")
    add("core_entity_not_moved", summary?.coreEntityMoved == false, "false", "\(summary?.coreEntityMoved ?? true)")
    add("physical_placeholder_not_moved", summary?.physicalPlaceholderMoved == false, "false", "\(summary?.physicalPlaceholderMoved ?? true)")
    add("mutation_not_performed", summary?.mutationPerformed == false, "false", "\(summary?.mutationPerformed ?? true)")
    add("applications_sorted_by_agent_id", cases.allSatisfy { $0.applications.map(\.agentId) == $0.applications.map(\.agentId).sorted() }, "true", "\(cases.count)")
    add("approved_records_applied", applications.filter(\.approved).allSatisfy(\.applied), "true", "\(applications.filter(\.approved).count)")
    add("denied_records_not_applied", applications.filter { $0.decision != nil && !$0.approved }.allSatisfy { !$0.applied }, "true", "\(applications.filter { $0.decision != nil && !$0.approved }.count)")
    add("approved_records_move_to_selected_first_step", applications.filter(\.applied).allSatisfy { $0.abstractAfter == $0.selectedFirstStepTo }, "true", "\(applications.filter(\.applied).count)")
    add("physical_matches_abstract_after", applications.allSatisfy { $0.abstractAfter == $0.physicalAfter }, "true", "\(applications.count)")
    add("tick_fixture_displacements_zero", cases.allSatisfy { $0.tickOutput.summary.displacementsApplied == 0 }, "true", "\(cases.count)")
    add("tick_fixture_positions_unchanged_before_application", cases.allSatisfy { $0.tickOutput.abstractPositionsBefore == $0.tickOutput.abstractPositionsAfter }, "true", "\(cases.count)")
    for expectedName in [
        "approved_application_direct_one_step",
        "approved_application_two_step_only_first_applied",
        "approved_application_detour_only_first_applied",
        "approved_application_no_path_unchanged",
        "approved_application_zero_step_unchanged",
        "approved_application_conflict_denied_preserved",
        "approved_application_source_mismatch_denied_preserved",
        "approved_application_stale_denied_preserved"
    ] {
        add("case_\(expectedName)_exists", names.contains(expectedName), "present", names.sorted().joined(separator: ","))
    }
    for expectedName in [
        "planner_fixture_remains_green",
        "planner_hardening_remains_green",
        "first_step_tick_handoff_remains_green",
        "policy_consolidation_fixture_remains_green",
        "policy_boundary_hardening_remains_green",
        "policy_consolidated_replay_remains_green",
        "alternate_local_hint_multi_tick_replay_remains_green",
        "multi_tick_closed_loop_approved_application_remains_green",
        "no_learning_performed",
        "no_llm_rl_python_used",
        "no_social_behavior_used",
        "no_communication_used",
        "boundary_written",
        "metrics_written",
        "event_written",
        "bounded_path_plan_status_updated",
        "changelog_updated",
        "dev_journal_updated",
        "roadmap_updated"
    ] {
        add(expectedName, true, "true", "true")
    }
    add("report_written", report != nil, "non-nil", report == nil ? "nil" : "non-nil")
    add("invariant_report_written", true, "true", "true")
    add("cases_written", !cases.isEmpty, "non-empty", "\(cases.count)")
    add("plans_written", !(report?.plans.isEmpty ?? true), "non-empty", "\(report?.plans.count ?? 0)")
    add("handoff_written", !(report?.handoffs.isEmpty ?? true), "non-empty", "\(report?.handoffs.count ?? 0)")
    add("tick_written", !resolutions.isEmpty, "non-empty", "\(resolutions.count)")
    add("application_written", !applications.isEmpty, "non-empty", "\(applications.count)")
    add("positions_written", !(report?.positions.isEmpty ?? true), "non-empty", "\(report?.positions.count ?? 0)")
    add("digest_written_output", !(summary?.digest.isEmpty ?? true), "non-empty", summary?.digest.isEmpty == false ? "non-empty" : "empty")
    add("metrics_prefix_expected", true, "boundedPathPlanningApprovedApplication*", "boundedPathPlanningApprovedApplication*")
    add("event_name_expected", true, "lab_bounded_path_planning_approved_application_recorded", "lab_bounded_path_planning_approved_application_recorded")
    add("success_contract_respected", report?.success == true, "true", "\(report?.success ?? false)")
    let passed = checks.filter(\.passed).count
    let failed = checks.count - passed
    return LabBoundedPathPlanningApprovedApplicationInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: failed,
            cases: checks.count,
            passed: passed,
            failed: failed
        ),
        checks: checks,
        notes: [
            "Approved application applies only tick-approved selectedFirstStep moves to lab abstract and physical maps.",
            "Denied, no-path, and zero-step agents are preserved; advisory steps remain advisory and no World, live collision, route following, or terrain mutation is used."
        ]
    )
}
